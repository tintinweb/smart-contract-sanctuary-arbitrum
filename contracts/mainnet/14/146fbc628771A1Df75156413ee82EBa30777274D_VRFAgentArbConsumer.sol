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
pragma solidity ^0.8.19;

import "./VRFAgentConsumer.sol";

interface ArbSys {
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);
}

/**
 * @title VRFAgentArbConsumer
 * @author PowerPool
 */
contract VRFAgentArbConsumer is VRFAgentConsumer {
    constructor(address agent_) VRFAgentConsumer(agent_) {
    }

    function getLastBlockHash() public override view returns (uint256) {
        uint256 blockNumber = ArbSys(address(100)).arbBlockNumber();
        if (blockNumber == 0) {
          blockNumber = block.number;
        }
        return uint256(blockhash(blockNumber - 1));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface VRFCoordinatorV2Interface {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
}

/**
 * @title VRFAgentConsumer
 * @author PowerPool
 */
contract VRFAgentConsumer is Ownable {
    uint32 public constant VRF_NUM_RANDOM_WORDS = 10;

    address public agent;
    VRFCoordinatorV2Interface public vrfCoordinator;
    bytes32 public vrfKeyHash;
    uint64 public vrfSubscriptionId;
    uint16 public vrfRequestConfirmations;
    uint32 public vrfCallbackGasLimit;

    uint256 public vrfRequestPeriod;
    uint256 public lastVrfRequestAt;

    uint256 public pendingRequestId;
    uint256[] public lastVrfNumbers;

    event SetVrfConfig(VRFCoordinatorV2Interface vrfCoordinator, bytes32 vrfKeyHash, uint64 vrfSubscriptionId, uint16 vrfRequestConfirmations, uint32 vrfCallbackGasLimit, uint256 vrfRequestPeriod);
    event ClearPendingRequestId();

    constructor(address agent_) {
        agent = agent_;
    }

    /*** AGENT OWNER METHODS ***/
    function setVrfConfig(
        VRFCoordinatorV2Interface vrfCoordinator_,
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

    function rawFulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) external {
        require(msg.sender == address(vrfCoordinator), "sender not vrfCoordinator");
        require(_requestId == pendingRequestId, "request not found");
        lastVrfNumbers = _randomWords;
        pendingRequestId = 0;
        if (vrfRequestPeriod != 0) {
            lastVrfRequestAt = block.timestamp;
        }
    }

    function isReadyForRequest() public view returns (bool) {
        return pendingRequestId == 0 && (vrfRequestPeriod == 0 || lastVrfRequestAt + vrfRequestPeriod < block.timestamp);
    }

    function getLastBlockHash() public virtual view returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }

    function getPseudoRandom() external returns (uint256) {
        if (msg.sender == agent && isReadyForRequest()) {
            pendingRequestId = vrfCoordinator.requestRandomWords(
                vrfKeyHash,
                vrfSubscriptionId,
                vrfRequestConfirmations,
                vrfCallbackGasLimit,
                VRF_NUM_RANDOM_WORDS
            );
        }
        uint256 blockHashNumber = getLastBlockHash();
        if (lastVrfNumbers.length > 0) {
            blockHashNumber += lastVrfNumbers[agent.balance % uint256(VRF_NUM_RANDOM_WORDS)];
        }
        return blockHashNumber;
    }

    function getLastVrfNumbers() external view returns (uint256[] memory) {
        return lastVrfNumbers;
    }
}