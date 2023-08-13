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

import "./Common.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IChannel.sol";
import "./interfaces/IRelayer.sol";
import "./interfaces/IUserConfig.sol";
import "./security/ReentrancyGuard.sol";
import "./security/ExcessivelySafeCall.sol";

/// @title Endpoint
/// @notice An endpoint is a type of network node for cross-chain communication.
/// It is an interface exposed by a communication channel.
/// @dev An endpoint is associated with an immutable channel and user configuration.
contract Endpoint is ReentrancyGuard {
    using ExcessivelySafeCall for address;

    /// msgHash => isFailed
    mapping(bytes32 => bool) public fails;

    /// @dev User config immutable address.
    address public immutable CONFIG;
    /// @dev Channel immutable address.
    address public immutable CHANNEL;

    /// @dev Notifies an observer that the failed message has been cleared.
    /// @param msgHash Hash of the message.
    event ClearFailedMessage(bytes32 indexed msgHash);
    /// @dev Notifies an observer that the failed message has been retried.
    /// @param msgHash Hash of the message.
    /// @param dispatchResult Result of the message dispatch.
    event RetryFailedMessage(bytes32 indexed msgHash, bool dispatchResult);

    /// @dev Init code.
    /// @param config User config immutable address.
    /// @param channel Channel immutable address.
    constructor(address config, address channel) {
        CONFIG = config;
        CHANNEL = channel;
    }

    /// @dev Send a cross-chain message over the endpoint.
    /// @notice follow https://eips.ethereum.org/EIPS/eip-5750
    /// @param toChainId The Message destination chain id.
    /// @param to User application contract address which receive the message.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    function send(uint256 toChainId, address to, bytes calldata encoded, bytes calldata params)
        external
        payable
        sendNonReentrant
        returns (bytes32)
    {
        // user application address.
        address ua = msg.sender;
        // fetch user application's config.
        Config memory uaConfig = IUserConfig(CONFIG).getAppConfig(ua);
        // send message by channel, return the hash of the message as id.
        bytes32 msgHash = IChannel(CHANNEL).sendMessage(ua, toChainId, to, encoded);

        // handle relayer fee
        uint256 relayerFee = _handleRelayer(uaConfig.relayer, msgHash, toChainId, ua, encoded.length, params);
        // handle oracle fee
        uint256 oracleFee = _handleOracle(uaConfig.oracle, msgHash, toChainId, ua);

        //refund
        if (msg.value > relayerFee + oracleFee) {
            uint256 refund = msg.value - (relayerFee + oracleFee);
            (bool success,) = ua.call{value: refund}("");
            require(success, "!refund");
        }

        return msgHash;
    }

    /// @notice Get a quote in source native gas, for the amount that send() requires to pay for message delivery.
    /// @param toChainId The Message destination chain id.
    //  @param to User application contract address which receive the message.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    function fee(uint256 toChainId, address, /*to*/ bytes calldata encoded, bytes calldata params)
        external
        view
        returns (uint256)
    {
        address ua = msg.sender;
        Config memory uaConfig = IUserConfig(CONFIG).getAppConfig(ua);
        uint256 relayerFee = IRelayer(uaConfig.relayer).fee(toChainId, ua, encoded.length, params);
        uint256 oracleFee = IOracle(uaConfig.oracle).fee(toChainId, ua);
        return relayerFee + oracleFee;
    }

    function _handleRelayer(
        address relayer,
        bytes32 msgHash,
        uint256 toChainId,
        address ua,
        uint256 size,
        bytes calldata params
    ) internal returns (uint256) {
        uint256 relayerFee = IRelayer(relayer).fee(toChainId, ua, size, params);
        IRelayer(relayer).assign{value: relayerFee}(msgHash, params);
        return relayerFee;
    }

    function _handleOracle(address oracle, bytes32 msgHash, uint256 toChainId, address ua) internal returns (uint256) {
        uint256 oracleFee = IOracle(oracle).fee(toChainId, ua);
        IOracle(oracle).assign{value: oracleFee}(msgHash);
        return oracleFee;
    }

    /// @dev Recv verified message from Channel and dispatch to destination user application address.
    /// @notice Only channel could call this function.
    /// @param message Verified receive message info.
    /// @param gasLimit The gas limit of message execute.
    /// @return dispatchResult Result of the message dispatch.
    function recv(Message calldata message, uint256 gasLimit) external recvNonReentrant returns (bool dispatchResult) {
        require(msg.sender == CHANNEL, "!auth");
        bytes32 msgHash = hash(message);
        dispatchResult = _dispatch(message, msgHash, gasLimit);
        if (!dispatchResult) {
            fails[msgHash] = true;
        }
    }

    /// @dev Retry failed message.
    /// @param message Failed message info.
    /// @return dispatchResult Result of the message dispatch.
    function retryFailedMessage(Message calldata message) external recvNonReentrant returns (bool dispatchResult) {
        bytes32 msgHash = hash(message);
        require(fails[msgHash] == true, "!failed");
        dispatchResult = _dispatch(message, msgHash, gasleft());
        if (dispatchResult) {
            delete fails[msgHash];
        }
        emit RetryFailedMessage(msgHash, dispatchResult);
    }

    /// @dev Retry failed message.
    /// @notice Only message.to could clear this message.
    /// @param message Failed message info.
    function clearFailedMessage(Message calldata message) external {
        bytes32 msgHash = hash(message);
        require(fails[msgHash] == true, "!failed");
        require(message.to == msg.sender, "!auth");
        delete fails[msgHash];
        emit ClearFailedMessage(msgHash);
    }

    /// @dev Dispatch the cross chain message.
    function _dispatch(Message memory message, bytes32 msgHash, uint256 gasLimit)
        private
        returns (bool dispatchResult)
    {
        // Deliver the message to user application contract address.
        (dispatchResult,) = message.to.excessivelySafeCall(
            gasLimit, 0, abi.encodePacked(message.encoded, msgHash, uint256(message.fromChainId), message.from)
        );
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

interface IOracle {
    /// @notice Fetch oracle price to relay message root to the destination chain.
    /// @param toChainId The destination chain id.
    /// @param ua The user application which send the message.
    /// @return Oracle price in source native gas.
    function fee(uint256 toChainId, address ua) external view returns (uint256);

    /// @notice Assign the relay message root task to oracle maintainer.
    /// @param msgHash Hash of the message.
    function assign(bytes32 msgHash) external payable;

    /// @notice Fetch message root oracle.
    /// @param chainId The destination chain id.
    /// @return Message root in destination chain.
    function merkleRoot(uint256 chainId) external view returns (bytes32);
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

interface IRelayer {
    /// @notice Fetch relayer price to relay message to the destination chain.
    /// @param toChainId The destination chain id.
    /// @param ua The user application which send the message.
    /// @param size The size of message encoded payload.
    /// @param params General extensibility for relayer to custom functionality.
    /// @return Relayer price in source native gas.
    function fee(uint256 toChainId, address ua, uint256 size, bytes calldata params) external view returns (uint256);

    /// @notice Assign the relay message task to relayer maintainer.
    /// @param msgHash Hash of the message.
    /// @param params General extensibility for relayer to custom functionality.
    function assign(bytes32 msgHash, bytes calldata params) external payable;
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

/// @dev User application custom configuration.
/// @param oracle Oracle contract address.
/// @param relayer Relayer contract address.
struct Config {
    address oracle;
    address relayer;
}

interface IUserConfig {
    /// @dev Fetch user application config.
    /// @notice If user application has not configured, then the default config is used.
    /// @param ua User application contract address.
    /// @return user application config.
    function getAppConfig(address ua) external view returns (Config memory);

    /// @notice Set user application config.
    /// @param oracle Oracle which user application choose.
    /// @param relayer Relayer which user application choose.
    function setAppConfig(address oracle, address relayer) external;

    function setDefaultConfig(address oracle, address relayer) external;
    function defaultConfig() external view returns (Config memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract ReentrancyGuard {
    // send and receive nonreentrant lock
    uint8 internal constant _NOT_ENTERED = 1;
    uint8 internal constant _ENTERED = 2;
    uint8 internal _send_state = 1;
    uint8 internal _receive_state = 1;

    modifier sendNonReentrant() {
        require(_send_state == _NOT_ENTERED, "!send-reentrancy");
        _send_state = _ENTERED;
        _;
        _send_state = _NOT_ENTERED;
    }

    modifier recvNonReentrant() {
        require(_receive_state == _NOT_ENTERED, "!recv-reentrancy");
        _receive_state = _ENTERED;
        _;
        _receive_state = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

// Inspired: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/util/ExcessivelySafeCall.sol

library ExcessivelySafeCall {
    uint256 internal constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly ("memory-safe") {
            _success :=
                call(
                    _gas, // gas
                    _target, // recipient
                    0, // ether value
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        view
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly ("memory-safe") {
            _success :=
                staticcall(
                    _gas, // gas
                    _target, // recipient
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Swaps function selectors in encoded contract calls
    /// @dev Allows reuse of encoded calldata for functions with identical
    /// argument types but different names. It simply swaps out the first 4 bytes
    /// for the new selector. This function modifies memory in place, and should
    /// only be used with caution.
    /// @param _newSelector The new 4-byte selector
    /// @param _buf The encoded contract args
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly ("memory-safe") {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}