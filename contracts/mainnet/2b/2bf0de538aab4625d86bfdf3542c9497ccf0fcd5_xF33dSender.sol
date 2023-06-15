// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IxF33dAdapter {
    function getLatestData(
        bytes calldata _feedData
    ) external view returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IxF33dReceiver {
    function init(address lzEndpoint, address srcAddress) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";

import {ILayerZeroEndpoint} from "solidity-examples/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "solidity-examples/interfaces/ILayerZeroReceiver.sol";

import {IxF33dAdapter} from "./interfaces/IxF33dAdapter.sol";
import {IxF33dReceiver} from "./interfaces/IxF33dReceiver.sol";

/**
 * @title xF33dSender
 * @author sarangparikh22
 * @dev This contract allows for the creation and deployment of feeds, as well as the sending of updated rates to those feeds.
 * The contract uses the LayerZero protocol to send messages between chain.
 */
contract xF33dSender is Ownable2Step, ILayerZeroReceiver {
    ILayerZeroEndpoint public lzEndpoint;
    mapping(bytes32 => address) public activatedFeeds;
    mapping(uint16 => address) public remoteSrcAddress;
    mapping(bytes32 => bytes) public protectedFeeds;
    uint16 public chainId;

    constructor(address _endpoint, uint16 _chainId) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
        chainId = _chainId;
    }

    event SentUpdatedRate(
        uint16 _chainId,
        address _feed,
        bytes _feedData,
        bytes _payload
    );
    event FeedDeployed(
        uint16 _chainId,
        address _feed,
        bytes _feedData,
        address receiver
    );
    event FeedActivated(bytes32 _feedId, address _receiver);
    event SetRemoteSrcAddress(uint16 _chainId, address _remoteSrcAddress);
    event SetProtectedFeeds(uint16 _chainId, address _feed);
    event SetLzEndpoint(address _lzEndpoint);

    /**
     * @dev This function sends an updated rate to a feed.
     * @param _chainId The chain ID of the feed.
     * @param _feed The address of the feed.
     * @param _feedData The data for the feed.
     */
    function sendUpdatedRate(
        uint16 _chainId,
        address _feed,
        bytes calldata _feedData
    ) external payable {
        bytes32 _feedId = keccak256(abi.encode(_chainId, _feed, _feedData));
        address _receiver = activatedFeeds[_feedId];
        require(_receiver != address(0), "feed not active");

        // Get the latest data for the feed.
        bytes memory _payload = IxF33dAdapter(_feed).getLatestData(_feedData);

        // Send the updated rate to the feed using the LayerZero protocol.
        lzEndpoint.send{value: msg.value}(
            _chainId,
            abi.encodePacked(_receiver, address(this)),
            _payload,
            payable(msg.sender),
            address(0),
            bytes("")
        );

        emit SentUpdatedRate(_chainId, _feed, _feedData, _payload);
    }

    /**
     * @dev This function deploys a new feed.
     * @param _chainId The chain ID of the feed.
     * @param _feed The address of the feed.
     * @param _feedData The data for the feed.
     * @param _bytecode The bytecode for the feed receiver contract.
     * @return The address of the deployed feed receiver contract.
     */
    function deployFeed(
        uint16 _chainId,
        address _feed,
        bytes calldata _feedData,
        bytes memory _bytecode
    ) external payable returns (address) {
        if (protectedFeeds[keccak256(abi.encode(_chainId, _feed))].length > 0)
            _bytecode = protectedFeeds[keccak256(abi.encode(_chainId, _feed))];

        // Create the feed contract.
        bytes32 salt = keccak256(
            abi.encode(_chainId, _feed, _feedData, _bytecode)
        );

        address receiver;

        assembly {
            receiver := create2(0, add(_bytecode, 0x20), mload(_bytecode), salt)

            if iszero(extcodesize(receiver)) {
                revert(0, 0)
            }
        }
        // Initialize the feed contract.
        IxF33dReceiver(receiver).init(
            address(lzEndpoint),
            remoteSrcAddress[_chainId]
        );

        // Send a message to the remote chain to indicate that the feed has been deployed.
        lzEndpoint.send{value: msg.value}(
            _chainId,
            abi.encodePacked(remoteSrcAddress[_chainId], address(this)),
            abi.encode(
                keccak256(abi.encode(chainId, _feed, _feedData)),
                receiver
            ),
            payable(msg.sender),
            address(0),
            bytes("")
        );

        emit FeedDeployed(_chainId, _feed, _feedData, receiver);

        return receiver;
    }

    /**
     * @dev Receives a message from LayerZero.
     * @param _chainId The ID of the chain that the message came from.
     * @param _srcAddress The address of the sender on the chain that the message came from.
     * @param _payload The message payload.
     */
    function lzReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint64,
        bytes calldata _payload
    ) public virtual override {
        require(msg.sender == address(lzEndpoint));
        address remoteSrc;
        assembly {
            remoteSrc := mload(add(_srcAddress, 20))
        }
        require(remoteSrc == remoteSrcAddress[_chainId]);
        (bytes32 _feedId, address _receiver) = abi.decode(
            _payload,
            (bytes32, address)
        );

        activatedFeeds[_feedId] = _receiver;

        emit FeedActivated(_feedId, _receiver);
    }

    /**
     * @dev Sets the remote source address for the specified chain.
     * @param _chainId The chain ID of the remote chain.
     * @param _remoteSrcAddress The address of the remote source contract.
     */
    function setRemoteSrcAddress(
        uint16 _chainId,
        address _remoteSrcAddress
    ) external onlyOwner {
        remoteSrcAddress[_chainId] = _remoteSrcAddress;
        emit SetRemoteSrcAddress(_chainId, _remoteSrcAddress);
    }

    /**
     * @dev Sets the bytecode for a protected feed.
     * @param _chainId The chain ID of the feed.
     * @param _feed The address of the feed.
     * @param _bytecode The bytecode for the feed receiver contract.
     */
    function setProtectedFeeds(
        uint16 _chainId,
        address _feed,
        bytes calldata _bytecode
    ) external onlyOwner {
        protectedFeeds[keccak256(abi.encode(_chainId, _feed))] = _bytecode;
        emit SetProtectedFeeds(_chainId, _feed);
    }

    /**
     * @dev Sets the LayerZero endpoint for the contract.
     * @param _lzEndpoint The address of the LayerZero endpoint.
     */
    function setLzEndpoint(address _lzEndpoint) external onlyOwner {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        emit SetLzEndpoint(_lzEndpoint);
    }

    /**
     * @dev Returns the estimated fees for updating a rate.
     * @param _chainId The ID of the chain.
     * @param _feed The address of the feed.
     * @param _feedData The data to update the rate with.
     * @return fees The estimated fees for the update.
     */
    function getFeesForRateUpdate(
        uint16 _chainId,
        address _feed,
        bytes calldata _feedData
    ) external view returns (uint256 fees) {
        bytes memory _payload = IxF33dAdapter(_feed).getLatestData(_feedData);
        (fees, ) = lzEndpoint.estimateFees(
            _chainId,
            address(this),
            _payload,
            false,
            bytes("")
        );
    }

    /**
     * @dev Returns the estimated fees for deploying a feed.
     * @param _chainId The ID of the chain.
     * @param _feed The address of the feed.
     * @param _feedData The data to deploy the feed with.
     * @return fees The estimated fees for the deployment.
     */
    function getFeesForDeployFeed(
        uint16 _chainId,
        address _feed,
        bytes calldata _feedData
    ) external view returns (uint256 fees) {
        (fees, ) = lzEndpoint.estimateFees(
            _chainId,
            address(this),
            abi.encode(
                keccak256(abi.encode(chainId, _feed, _feedData)),
                address(0)
            ),
            false,
            bytes("")
        );
    }
}