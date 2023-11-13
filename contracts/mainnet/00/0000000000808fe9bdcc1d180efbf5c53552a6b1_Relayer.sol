// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../interfaces/IORMP.sol";

contract Relayer {
    event Assigned(bytes32 indexed msgHash, uint256 fee, bytes params, bytes32[32] proof);
    event SetDstPrice(uint256 indexed chainId, uint128 dstPriceRatio, uint128 dstGasPriceInWei);
    event SetDstConfig(uint256 indexed chainId, uint64 baseGas, uint64 gasPerByte);
    event SetApproved(address operator, bool approve);

    struct DstPrice {
        uint128 dstPriceRatio; // dstPrice / localPrice * 10^10
        uint128 dstGasPriceInWei;
    }

    struct DstConfig {
        uint64 baseGas;
        uint64 gasPerByte;
    }

    address public immutable PROTOCOL;

    address public owner;
    // chainId => price
    mapping(uint256 => DstPrice) public priceOf;
    mapping(uint256 => DstConfig) public configOf;
    mapping(address => bool) public approvedOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyApproved() {
        require(isApproved(msg.sender), "!approve");
        _;
    }

    constructor(address dao, address ormp) {
        PROTOCOL = ormp;
        owner = dao;
    }

    receive() external payable {}

    function withdraw(address to, uint256 amount) external onlyApproved {
        (bool success,) = to.call{value: amount}("");
        require(success, "!withdraw");
    }

    function isApproved(address operator) public view returns (bool) {
        return approvedOf[operator];
    }

    function changeOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    function setApproved(address operator, bool approve) public onlyOwner {
        approvedOf[operator] = approve;
        emit SetApproved(operator, approve);
    }

    function setDstPrice(uint256 chainId, uint128 dstPriceRatio, uint128 dstGasPriceInWei) external onlyApproved {
        priceOf[chainId] = DstPrice(dstPriceRatio, dstGasPriceInWei);
        emit SetDstPrice(chainId, dstPriceRatio, dstGasPriceInWei);
    }

    function setDstConfig(uint256 chainId, uint64 baseGas, uint64 gasPerByte) external onlyApproved {
        configOf[chainId] = DstConfig(baseGas, gasPerByte);
        emit SetDstConfig(chainId, baseGas, gasPerByte);
    }

    // extraGas = gasLimit
    function fee(
        uint256 toChainId,
        address, /*ua*/
        uint256 gasLimit,
        bytes calldata encoded,
        bytes calldata /*params*/
    ) public view returns (uint256) {
        uint256 size = encoded.length;
        uint256 extraGas = gasLimit;
        DstPrice memory p = priceOf[toChainId];
        DstConfig memory c = configOf[toChainId];

        require(c.baseGas != 0, "!baseGas");
        // remoteToken = dstGasPriceInWei * (baseGas + extraGas)
        uint256 remoteToken = p.dstGasPriceInWei * (c.baseGas + extraGas);
        // dstPriceRatio = dstPrice / localPrice * 10^10
        // sourceToken = RemoteToken * dstPriceRatio
        uint256 sourceToken = remoteToken * p.dstPriceRatio / (10 ** 10);
        uint256 payloadToken = c.gasPerByte * size * p.dstGasPriceInWei * p.dstPriceRatio / (10 ** 10);
        return sourceToken + payloadToken;
    }

    function assign(bytes32 msgHash, bytes calldata params) external payable {
        require(msg.sender == PROTOCOL, "!ormp");
        emit Assigned(msgHash, msg.value, params, IORMP(PROTOCOL).prove());
    }

    function relay(Message calldata message, bytes calldata proof) external onlyApproved {
        IORMP(PROTOCOL).recv(message, proof);
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../Common.sol";

interface IORMP {
    /// @dev Send a cross-chain message over the endpoint.
    /// @notice follow https://eips.ethereum.org/EIPS/eip-5750
    /// @param toChainId The Message destination chain id.
    /// @param to User application contract address which receive the message.
    /// @param gasLimit Gas limit for destination user application used.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param refund Return extra fee to refund address.
    /// @param params General extensibility for relayer to custom functionality.
    /// @return Return the hash of the message as message id.
    function send(
        uint256 toChainId,
        address to,
        uint256 gasLimit,
        bytes calldata encoded,
        address refund,
        bytes calldata params
    ) external payable returns (bytes32);

    /// @notice Get a quote in source native gas, for the amount that send() requires to pay for message delivery.
    /// @param toChainId The Message destination chain id.
    //  @param ua User application contract address which send the message.
    /// @param gasLimit Gas limit for destination user application used.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    function fee(uint256 toChainId, address ua, uint256 gasLimit, bytes calldata encoded, bytes calldata params)
        external
        view
        returns (uint256);

    /// @dev Recv verified message and dispatch to destination user application address.
    /// @param message Verified receive message info.
    /// @param proof Message proof of this message.
    /// @return dispatchResult Result of the message dispatch.
    function recv(Message calldata message, bytes calldata proof) external returns (bool dispatchResult);

    function prove() external view returns (bytes32[32] memory);

    /// @dev Fetch user application config.
    /// @notice If user application has not configured, then the default config is used.
    /// @param ua User application contract address.
    /// @return user application config.
    function getAppConfig(address ua) external view returns (UC memory);

    /// @notice Set user application config.
    /// @param oracle Oracle which user application choose.
    /// @param relayer Relayer which user application choose.
    function setAppConfig(address oracle, address relayer) external;

    function defaultUC() external view returns (UC memory);
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

/// @dev The block of control information and data for comminicate
/// between user applications. Messages are the exchange medium
/// used by channels to send and receive data through cross-chain networks.
/// A message is sent from a source chain to a destination chain.
/// @param index The leaf index lives in channel's incremental mekle tree.
/// @param fromChainId The message source chain id.
/// @param from User application contract address which send the message.
/// @param toChainId The message destination chain id.
/// @param to User application contract address which receive the message.
/// @param gasLimit Gas limit for destination UA used.
/// @param encoded The calldata which encoded by ABI Encoding.
struct Message {
    address channel;
    uint256 index;
    uint256 fromChainId;
    address from;
    uint256 toChainId;
    address to;
    uint256 gasLimit;
    bytes encoded; /*(abi.encodePacked(SELECTOR, PARAMS))*/
}

/// @dev User application custom configuration.
/// @param oracle Oracle contract address.
/// @param relayer Relayer contract address.
struct UC {
    address oracle;
    address relayer;
}

/// @dev Hash of the message.
function hash(Message memory message) pure returns (bytes32) {
    return keccak256(abi.encode(message));
}