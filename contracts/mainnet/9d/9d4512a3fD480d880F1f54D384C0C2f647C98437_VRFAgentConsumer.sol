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
pragma solidity ^0.8.0;

interface VRFAgentConsumerInterface {

    function setVrfConfig(
        address vrfCoordinator_,
        bytes32 vrfKeyHash_,
        uint64 vrfSubscriptionId_,
        uint16 vrfRequestConfirmations_,
        uint32 vrfCallbackGasLimit_,
        uint256 vrfRequestPeriod_
    ) external;

    function setOffChainIpfsHash(string calldata _ipfsHash) external;

    function getPseudoRandom() external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFAgentCoordinatorInterface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_agentProviders list of registered agents
     */
    function getRequestConfig() external view returns (uint16, uint32, address[] memory);

    /**
     * @notice Request a set of random words.
     * @param agent - Corresponds to a agent provider address
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        address agent,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     */
    function createSubscription() external returns (uint64 subId);

    function createSubscriptionWithConsumer() external returns (uint64 subId, address consumer);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId) external view returns (address owner, address[] memory consumers);

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     */
    function cancelSubscription(uint64 subId) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);

    function fulfillRandomnessResolver(uint64 _subId) external view returns (bool, bytes calldata);

    /*
     * @notice Get last pending request id
     */
    function lastPendingRequestId(address consumer, uint64 subId) external view returns (uint256);

    /*
     * @notice Get current nonce
     */
    function getCurrentNonce(address consumer, uint64 subId) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFChainlinkCoordinatorInterface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_agentProviders list of registered agents
     */
    function getRequestConfig() external view returns (uint16, uint32, address[] memory);

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a public key hash
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     */
    function createSubscription() external returns (uint64 subId);

    function createSubscriptionWithConsumer() external returns (uint64 subId, address consumer);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId) external view returns (address owner, address[] memory consumers);

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     */
    function cancelSubscription(uint64 subId) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);

    function fulfillRandomnessResolver(uint64 _subId) external view returns (bool, bytes calldata);

    /*
     * @notice Get last pending request id
     */
    function lastPendingRequestId(address consumer, uint64 subId) external view returns (uint256);

    /*
     * @notice Get current nonce
     */
    function getCurrentNonce(address consumer, uint64 subId) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/VRFAgentCoordinatorInterface.sol";
import "./interfaces/VRFAgentConsumerInterface.sol";
import "./interfaces/VRFChainlinkCoordinatorInterface.sol";

/**
 * @title VRFAgentConsumer
 * @author PowerPool
 */
contract VRFAgentConsumer is VRFAgentConsumerInterface, Ownable {
    uint32 public constant VRF_NUM_RANDOM_WORDS = 10;

    address public agent;
    address public vrfCoordinator;
    bytes32 public vrfKeyHash;
    uint64 public vrfSubscriptionId;
    uint16 public vrfRequestConfirmations;
    uint32 public vrfCallbackGasLimit;

    uint256 public vrfRequestPeriod;
    uint256 public lastVrfFulfillAt;
    uint256 public lastVrfRequestAtBlock;

    uint256 public pendingRequestId;
    uint256[] public lastVrfNumbers;

    string public offChainIpfsHash;
    bool public useLocalIpfsHash;

    event SetVrfConfig(address vrfCoordinator, bytes32 vrfKeyHash, uint64 vrfSubscriptionId, uint16 vrfRequestConfirmations, uint32 vrfCallbackGasLimit, uint256 vrfRequestPeriod);
    event ClearPendingRequestId();
    event SetOffChainIpfsHash(string ipfsHash);

    constructor(address agent_) {
        agent = agent_;
    }

    /*** AGENT OWNER METHODS ***/
    function setVrfConfig(
        address vrfCoordinator_,
        bytes32 vrfKeyHash_,
        uint64 vrfSubscriptionId_,
        uint16 vrfRequestConfirmations_,
        uint32 vrfCallbackGasLimit_,
        uint256 vrfRequestPeriod_
    ) external onlyOwner {
        vrfCoordinator = vrfCoordinator_;
        vrfKeyHash = vrfKeyHash_;
        vrfSubscriptionId = vrfSubscriptionId_;
        vrfRequestConfirmations = vrfRequestConfirmations_;
        vrfCallbackGasLimit = vrfCallbackGasLimit_;
        vrfRequestPeriod = vrfRequestPeriod_;
        emit SetVrfConfig(vrfCoordinator_, vrfKeyHash_, vrfSubscriptionId_, vrfRequestConfirmations_, vrfCallbackGasLimit_, vrfRequestPeriod_);
    }

    function clearPendingRequestId() external onlyOwner {
        pendingRequestId = 0;
        emit ClearPendingRequestId();
    }

    function setOffChainIpfsHash(string calldata _ipfsHash) external onlyOwner {
        offChainIpfsHash = _ipfsHash;
        useLocalIpfsHash = bytes(offChainIpfsHash).length > 0;
        emit SetOffChainIpfsHash(_ipfsHash);
    }

    function rawFulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) external {
        require(msg.sender == address(vrfCoordinator), "sender not vrfCoordinator");
        require(_requestId == pendingRequestId, "request not found");
        lastVrfNumbers = _randomWords;
        pendingRequestId = 0;
        if (vrfRequestPeriod != 0) {
            lastVrfFulfillAt = block.timestamp;
        }
    }

    function isReadyForRequest() public view returns (bool) {
        return pendingRequestId == 0
            && (vrfRequestPeriod == 0 || lastVrfFulfillAt + vrfRequestPeriod < block.timestamp);
    }

    function getLastBlockHash() public virtual view returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }

    function getPseudoRandom() external returns (uint256) {
        if (msg.sender == agent && isReadyForRequest()) {
            pendingRequestId = _requestRandomWords();
            lastVrfRequestAtBlock = block.number;
        }
        uint256 blockHashNumber = getLastBlockHash();
        if (lastVrfNumbers.length > 0) {
            uint256 vrfNumberIndex = uint256(keccak256(abi.encodePacked(agent.balance))) % uint256(VRF_NUM_RANDOM_WORDS);
            blockHashNumber = uint256(keccak256(abi.encodePacked(blockHashNumber, lastVrfNumbers[vrfNumberIndex])));
        }
        return blockHashNumber;
    }

    function _requestRandomWords() internal virtual returns (uint256) {
        if (vrfKeyHash == bytes32(0)) {
            return VRFAgentCoordinatorInterface(vrfCoordinator).requestRandomWords(
                agent,
                vrfSubscriptionId,
                vrfRequestConfirmations,
                vrfCallbackGasLimit,
                VRF_NUM_RANDOM_WORDS
            );
        } else {
            return VRFChainlinkCoordinatorInterface(vrfCoordinator).requestRandomWords(
                vrfKeyHash,
                vrfSubscriptionId,
                vrfRequestConfirmations,
                vrfCallbackGasLimit,
                VRF_NUM_RANDOM_WORDS
            );
        }
    }

    function getLastVrfNumbers() external view returns (uint256[] memory) {
        return lastVrfNumbers;
    }

    function fulfillRandomnessResolver() external view returns (bool, bytes memory) {
        if (useLocalIpfsHash) {
            return (VRFAgentCoordinatorInterface(vrfCoordinator).pendingRequestExists(vrfSubscriptionId), bytes(offChainIpfsHash));
        } else {
            return VRFAgentCoordinatorInterface(vrfCoordinator).fulfillRandomnessResolver(vrfSubscriptionId);
        }
    }

    function lastPendingRequestId() external view returns (uint256) {
        return VRFAgentCoordinatorInterface(vrfCoordinator).lastPendingRequestId(address(this), vrfSubscriptionId);
    }

    function getRequestData() external view returns (
        uint256 subscriptionId,
        uint256 requestAtBlock,
        uint256 requestId,
        uint64 requestNonce,
        uint32 numbRandomWords,
        uint32 callbackGasLimit
    ) {
        return (
            vrfSubscriptionId,
            lastVrfRequestAtBlock,
            pendingRequestId,
            VRFAgentCoordinatorInterface(vrfCoordinator).getCurrentNonce(address(this), vrfSubscriptionId),
            VRF_NUM_RANDOM_WORDS,
            vrfCallbackGasLimit
        );
    }
}