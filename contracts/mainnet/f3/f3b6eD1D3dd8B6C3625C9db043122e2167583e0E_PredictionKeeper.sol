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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

interface AutomationCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Common} from "../libraries/Common.sol";

interface IFeeManager {
    /**
     * @notice Calculate the applied fee and the reward from a report. If the sender is a subscriber, they will receive a discount.
     * @param subscriber address trying to verify
     * @param report report to calculate the fee for
     * @param quoteAddress address of the quote payment token
     * @return (fee, reward, totalDiscount) fee and the reward data with the discount applied
     */
    function getFeeAndReward(
        address subscriber,
        bytes memory report,
        address quoteAddress
    )
        external
        returns (
            Common.Asset memory,
            Common.Asset memory,
            uint256
        );

    function i_rewardManager() external returns (address);

    function i_nativeAddress() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrediction {
    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        int256 lockPrice;
        int256 closePrice;
        uint256 lockOracleId;
        uint256 closeOracleId;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    function oracleLatestRoundId() external view returns (uint256);

    function oracleUpdateAllowance() external view returns (uint256);

    function rounds(uint256 epoch) external view returns (Round memory);

    function genesisStartOnce() external view returns (bool);

    function genesisLockOnce() external view returns (bool);

    function paused() external view returns (bool);

    function currentEpoch() external view returns (uint256);

    function bufferSeconds() external view returns (uint256);

    function intervalSeconds() external view returns (uint256);

    function genesisStartRound() external;

    function pause() external;

    function unpause() external;

    function genesisLockRound(uint80 currentRoundId, int256 currentPrice) external;

    function executeRound(uint80 currentRoundId, int256 currentPrice) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFeeManager.sol";

interface IVerifierProxy {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct verifier, and bills the user if applicable.
     * @param payload The encoded data to be verified, including the signed
     * report.
     * @param parameterPayload fee metadata for billing. For the current implementation this is just the abi-encoded fee token ERC-20 address
     * @return verifierResponse The encoded report from the verifier.
     */
    function verify(bytes calldata payload, bytes calldata parameterPayload)
        external
        payable
        returns (bytes memory verifierResponse);

    /**
     * @notice Bulk verifies that the data encoded has been signed
     * correctly by routing to the correct verifier, and bills the user if applicable.
     * @param payloads The encoded payloads to be verified, including the signed
     * report.
     * @param parameterPayload fee metadata for billing. For the current implementation this is just the abi-encoded fee token ERC-20 address
     * @return verifiedReports The encoded reports from the verifier.
     */
    function verifyBulk(bytes[] calldata payloads, bytes calldata parameterPayload)
        external
        payable
        returns (bytes[] memory verifiedReports);

    function s_feeManager() external returns (IFeeManager);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface StreamsLookupCompatibleInterface {
    error StreamsLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);

    /**
     * @notice any contract which wants to utilize StreamsLookup feature needs to
     * implement this interface as well as the automation compatible interface.
     * @param values an array of bytes returned from data streams endpoint.
     * @param extraData context data from streams lookup process.
     * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
     */
    function checkCallback(bytes[] memory values, bytes memory extraData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @title Common
 * @author Michael Fletcher
 * @notice Common functions and structs
 */
library Common {
    // @notice The asset struct to hold the address of an asset and amount
    struct Asset {
        address assetAddress;
        uint256 amount;
    }

    // @notice Struct to hold the address and its associated weight
    struct AddressAndWeight {
        address addr;
        uint64 weight;
    }

    /**
     * @notice Checks if an array of AddressAndWeight has duplicate addresses
     * @param recipients The array of AddressAndWeight to check
     * @return bool True if there are duplicates, false otherwise
     */
    function hasDuplicateAddresses(Common.AddressAndWeight[] memory recipients) internal pure returns (bool) {
        for (uint256 i = 0; i < recipients.length; ) {
            for (uint256 j = i + 1; j < recipients.length; ) {
                if (recipients[i].addr == recipients[j].addr) {
                    return true;
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/AutomationCompatibleInterface.sol";
import "./interfaces/StreamsLookupCompatibleInterface.sol";
import "./interfaces/IVerifierProxy.sol";
import "./interfaces/IFeeManager.sol";
import "./interfaces/IPrediction.sol";
import {Common} from "./libraries/Common.sol";

contract PredictionKeeper is AutomationCompatibleInterface, StreamsLookupCompatibleInterface, Ownable, Pausable {
    struct BasicReport {
        bytes32 feedId; // The feed ID the report has data for
        uint32 validFromTimestamp; // Earliest timestamp for which price is applicable
        uint32 observationsTimestamp; // Latest timestamp for which price is applicable
        uint192 nativeFee; // Base cost to validate a transaction using the report, denominated in the chain’s native token (WETH/ETH)
        uint192 linkFee; // Base cost to validate a transaction using the report, denominated in LINK
        uint64 expiresAt; // Latest timestamp where the report can be verified on-chain
        int192 price; // DON consensus median price, carried to 8 decimal places
    }

    address public predictionContract;
    uint256 public maxAheadTime;
    uint256 public aheadTimeForCheckUpkeep;
    uint256 public aheadTimeForPerformUpkeep;
    string public feedID;
    address public forwarder;
    address public verifierProxy;

    event NewPredictionContract(address indexed predictionContract);
    event NewMaxAheadTime(uint256 time);
    event NewAheadTimeForCheckUpkeep(uint256 time);
    event NewAheadTimeForPerformUpkeep(uint256 time);
    event NewFeedID(string feedID);
    event NewForwarder(address indexed forwarder);
    event NewVerifierProxy(address indexed verifierProxy);

    constructor(
        address _predictionContract,
        uint256 _maxAheadTime,
        uint256 _aheadTimeForCheckUpkeep,
        uint256 _aheadTimeForPerformUpkeep,
        string memory _feedID,
        address _forwarder,
        address _verifierProxy
    ) {
        require(_predictionContract != address(0) && _verifierProxy != address(0), "Cannot be zero addresses");
        predictionContract = _predictionContract;
        maxAheadTime = _maxAheadTime;
        aheadTimeForCheckUpkeep = _aheadTimeForCheckUpkeep;
        aheadTimeForPerformUpkeep = _aheadTimeForPerformUpkeep;
        feedID = _feedID;
        forwarder = _forwarder;
        verifierProxy = _verifierProxy;
    }

    modifier onlyForwarder() {
        require(msg.sender == forwarder || forwarder == address(0), "Not forwarder");
        _;
    }

    // The logic is consistent with the following performUpkeep function, in order to make the code logic clearer.
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (!paused()) {
            // encode to send all to performUpkeep (thus on-chain)
            performData = checkData;

            bool genesisStartOnce = IPrediction(predictionContract).genesisStartOnce();
            bool genesisLockOnce = IPrediction(predictionContract).genesisLockOnce();
            bool paused = IPrediction(predictionContract).paused();
            uint256 currentEpoch = IPrediction(predictionContract).currentEpoch();
            uint256 bufferSeconds = IPrediction(predictionContract).bufferSeconds();
            IPrediction.Round memory round = IPrediction(predictionContract).rounds(currentEpoch);
            uint256 lockTimestamp = round.lockTimestamp;

            if (paused) {
                // need to unpause
                upkeepNeeded = true;
            } else {
                if (!genesisStartOnce) {
                    upkeepNeeded = true;
                } else if (!genesisLockOnce) {
                    // Too early for locking of round, skip current job (also means previous lockRound was successful)
                    if (lockTimestamp == 0 || block.timestamp + aheadTimeForCheckUpkeep < lockTimestamp) {} else if (
                        lockTimestamp != 0 && block.timestamp > (lockTimestamp + bufferSeconds)
                    ) {
                        // Too late to lock round, need to pause
                        upkeepNeeded = true;
                    } else {
                        // run genesisLockRound
                        // upkeepNeeded = true;
                        string[] memory feedIDs = new string[](1);
                        feedIDs[0] = feedID;
                        revert StreamsLookup("feedIDs", feedIDs, "timestamp", block.timestamp, checkData);
                    }
                } else {
                    if (block.timestamp + aheadTimeForCheckUpkeep > lockTimestamp) {
                        // Too early for end/lock/start of round, skip current job
                        if (
                            lockTimestamp == 0 || block.timestamp + aheadTimeForCheckUpkeep < lockTimestamp
                        ) {} else if (lockTimestamp != 0 && block.timestamp > (lockTimestamp + bufferSeconds)) {
                            // Too late to end round, need to pause
                            upkeepNeeded = true;
                        } else {
                            // run executeRound
                            // upkeepNeeded = true;
                            string[] memory feedIDs = new string[](1);
                            feedIDs[0] = feedID;
                            revert StreamsLookup("feedIDs", feedIDs, "timestamp", block.timestamp, checkData);
                        }
                    }
                }
            }
        }
    }

    function checkCallback(bytes[] memory values, bytes memory extraData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        return (true, abi.encode(values, extraData));
    }

    function performUpkeep(bytes calldata performData) external override onlyForwarder whenNotPaused {
        bool genesisStartOnce = IPrediction(predictionContract).genesisStartOnce();
        bool genesisLockOnce = IPrediction(predictionContract).genesisLockOnce();
        bool paused = IPrediction(predictionContract).paused();
        uint256 currentEpoch = IPrediction(predictionContract).currentEpoch();
        uint256 bufferSeconds = IPrediction(predictionContract).bufferSeconds();
        IPrediction.Round memory round = IPrediction(predictionContract).rounds(currentEpoch);
        uint256 lockTimestamp = round.lockTimestamp;
        if (paused) {
            // unpause operation
            IPrediction(predictionContract).unpause();
        } else {
            if (!genesisStartOnce) {
                IPrediction(predictionContract).genesisStartRound();
            } else if (!genesisLockOnce) {
                // Too early for locking of round, skip current job (also means previous lockRound was successful)
                if (lockTimestamp == 0 || block.timestamp + aheadTimeForPerformUpkeep < lockTimestamp) {} else if (
                    lockTimestamp != 0 && block.timestamp > (lockTimestamp + bufferSeconds)
                ) {
                    // Too late to lock round, need to pause
                    IPrediction(predictionContract).pause();
                } else {
                    (bytes[] memory prices, uint80 roundId) = abi.decode(performData, (bytes[], uint80));

                    int256 verifiedPrice = verify(prices, roundId);

                    // run genesisLockRound
                    IPrediction(predictionContract).genesisLockRound(roundId, verifiedPrice);
                }
            } else {
                if (block.timestamp + aheadTimeForPerformUpkeep > lockTimestamp) {
                    // Too early for end/lock/start of round, skip current job
                    if (lockTimestamp == 0 || block.timestamp + aheadTimeForPerformUpkeep < lockTimestamp) {} else if (
                        lockTimestamp != 0 && block.timestamp > (lockTimestamp + bufferSeconds)
                    ) {
                        // Too late to end round, need to pause
                        IPrediction(predictionContract).pause();
                    } else {
                        (bytes[] memory prices, uint80 roundId) = abi.decode(performData, (bytes[], uint80));

                        int256 verifiedPrice = verify(prices, roundId);

                        // run executeRound
                        IPrediction(predictionContract).executeRound(roundId, verifiedPrice);
                    }
                }
            }
        }
    }

    function verify(bytes[] memory prices, uint80 roundId) internal returns (int256 verifiedPrice) {
        require(
            uint256(roundId) > IPrediction(predictionContract).oracleLatestRoundId(),
            "Oracle update roundId must be larger than oracleLatestRoundId"
        );

        IFeeManager feeManager = IVerifierProxy(verifierProxy).s_feeManager();
        address rewardManagerAddress = feeManager.i_rewardManager();
        address feeTokenAddress = feeManager.i_nativeAddress();

        (Common.Asset memory fee, , ) = feeManager.getFeeAndReward(address(this), prices[0], feeTokenAddress);

        IERC20(feeTokenAddress).approve(rewardManagerAddress, fee.amount);

        bytes memory verifiedReportData = IVerifierProxy(verifierProxy).verify(prices[0], abi.encode(feeTokenAddress));

        BasicReport memory verifiedReport = abi.decode(verifiedReportData, (BasicReport));

        require(
            verifiedReport.observationsTimestamp >=
                block.timestamp - IPrediction(predictionContract).oracleUpdateAllowance(),
            "Oracle update exceeded max timestamp allowance"
        );

        verifiedPrice = verifiedReport.price;
    }

    function setPredictionContract(address _predictionContract) external onlyOwner {
        require(_predictionContract != address(0), "Cannot be zero address");
        predictionContract = _predictionContract;
        emit NewPredictionContract(_predictionContract);
    }

    function setMaxAheadTime(uint256 _time) external onlyOwner {
        maxAheadTime = _time;
        emit NewMaxAheadTime(_time);
    }

    function setAheadTimeForCheckUpkeep(uint256 _time) external onlyOwner {
        require(_time <= maxAheadTime, "aheadTimeForCheckUpkeep cannot be more than MaxAheadTime");
        aheadTimeForCheckUpkeep = _time;
        emit NewAheadTimeForCheckUpkeep(_time);
    }

    function setAheadTimeForPerformUpkeep(uint256 _time) external onlyOwner {
        require(_time <= maxAheadTime, "aheadTimeForPerformUpkeep cannot be more than MaxAheadTime");
        aheadTimeForPerformUpkeep = _time;
        emit NewAheadTimeForPerformUpkeep(_time);
    }

    function setFeedID(string calldata _feedID) external onlyOwner {
        feedID = _feedID;
        emit NewFeedID(_feedID);
    }

    function setForwarder(address _forwarder) external onlyOwner {
        // When forwarder is address(0), anyone can execute performUpkeep function
        forwarder = _forwarder;
        emit NewForwarder(_forwarder);
    }

    function setVerifierProxy(address _verifierProxy) external onlyOwner {
        require(_verifierProxy != address(0), "Cannot be zero address");
        verifierProxy = _verifierProxy;
        emit NewVerifierProxy(_verifierProxy);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}