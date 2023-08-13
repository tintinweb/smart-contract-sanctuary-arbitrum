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

import "../interfaces/IChannel.sol";

contract Relayer {
    event Assigned(bytes32 indexed msgHash, uint256 fee, bytes parmas);
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

    address public immutable ENDPOINT;
    address public immutable CHANNEL;
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

    constructor(address endpoint, address channel) {
        ENDPOINT = endpoint;
        CHANNEL = channel;
        owner = msg.sender;
        setApproved(msg.sender, true);
    }

    receive() external payable {}

    function changeOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    function isApproved(address operator) public view returns (bool) {
        return approvedOf[operator];
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

    function withdraw(address to, uint256 amount) external onlyApproved {
        (bool success,) = to.call{value: amount}("");
        require(success, "!withdraw");
    }

    // params = [extraGas]
    function fee(uint256 toChainId, address, /*ua*/ uint256 size, bytes calldata params)
        public
        view
        returns (uint256)
    {
        uint256 extraGas = abi.decode(params, (uint256));
        DstPrice memory p = priceOf[toChainId];
        DstConfig memory c = configOf[toChainId];

        // remoteToken = dstGasPriceInWei * (baseGas + extraGas)
        uint256 remoteToken = p.dstGasPriceInWei * (c.baseGas + extraGas);
        // dstPriceRatio = dstPrice / localPrice * 10^10
        // sourceToken = RemoteToken * dstPriceRatio
        uint256 sourceToken = remoteToken * p.dstPriceRatio / (10 ** 10);
        uint256 payloadToken = c.gasPerByte * size * p.dstGasPriceInWei * p.dstPriceRatio / (10 ** 10);
        return sourceToken + payloadToken;
    }

    function assign(bytes32 msgHash, bytes calldata params) external payable {
        require(msg.sender == ENDPOINT, "!enpoint");
        emit Assigned(msgHash, msg.value, params);
    }

    function relay(Message calldata message, bytes calldata proof, uint256 gasLimit) external onlyApproved {
        IChannel(CHANNEL).recvMessage(message, proof, gasLimit);
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

interface IChannel {
    function sendMessage(address from, uint256 toChainId, address to, bytes calldata encoded)
        external
        returns (bytes32);
    function recvMessage(Message calldata message, bytes calldata proof, uint256 gasLimit) external;
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
/// @param toChainId The Message destination chain id.
/// @param to User application contract address which receive the message.
/// @param encoded The calldata which encoded by ABI Encoding.
struct Message {
    address channel;
    uint256 index;
    uint256 fromChainId;
    address from;
    uint256 toChainId;
    address to;
    bytes encoded; /*(abi.encodePacked(SELECTOR, PARAMS))*/
}

/// @dev Hash of the message.
function hash(Message memory message) pure returns (bytes32) {
    return keccak256(abi.encode(message));
}