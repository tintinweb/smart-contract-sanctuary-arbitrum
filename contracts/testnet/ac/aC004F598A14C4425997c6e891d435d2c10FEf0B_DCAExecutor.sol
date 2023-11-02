// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDCAExecutor.sol";
import "./interfaces/IDCAAccount.sol";
import "./security/onlyAdmin.sol";

contract DCAExecutor is OnlyAdmin, IDCAExecutor {
    //Mapping of all _active strategy for the given interval
    mapping(Interval => Strategy[]) internal _strategies;
    // DCAAccount Address => Account Strat Id => local id
    mapping(address => mapping(uint256 => uint256)) internal _localStratId;
    //Mapping of interval times to the last execution block time
    mapping(Interval => uint256) internal _lastExecution;
    // Mapping of Interval enum to block amounts
    mapping(Interval => uint256) internal IntervalTimings;

    FeeDistribution internal _feeData;

    bool internal _active = true;
    address internal _executionEOAAddress;

    uint256 private _totalActiveStrategies;
    uint256 private _totalIntervalsExecuted;

    modifier is_active() {
        require(_active, "DCA is on pause");
        _;
    }
    modifier inWindow(Interval interval_) {
        require(
            _lastExecution[interval_] + IntervalTimings[interval_] <
                block.timestamp,
            "DCA Interval not met"
        );
        _;
    }

    constructor(
        FeeDistribution memory feeDistrobution_,
        address executionEOA_
    ) onlyAdmins() {
        _feeData = feeDistrobution_;
        _setExecutionAddress(executionEOA_);
        _setIntervalBlockAmounts();
    }

    function Subscribe(
        Strategy calldata strategy_
    ) external override is_active returns (bool sucsess) {
        //Adds the DCA account to the given strategy interval list.
        _subscribeAccount(strategy_);
        _totalActiveStrategies += 1;
        return true;
    }

    function Unsubscribe(
        Strategy calldata strategy_
    ) external override returns (bool sucsess) {
        //Remove the given stragety from the list
        _totalActiveStrategies -= 1;
        _unSubscribeAccount(strategy_);
        return sucsess = true;
    }

    function Execute(
        Interval interval_
    ) external override onlyAdmins is_active inWindow(interval_) {
        _startIntervalExecution(interval_);
        emit ExecutedDCA(interval_);
    }

    function ForceFeeFund() external override onlyAdmins {}

    function GetTotalActiveStrategys() public view returns (uint256) {
        return _totalActiveStrategies;
    }

    function GetIntervalsStrategys(
        Interval interval_
    ) public view returns (Strategy[] memory) {
        return _strategies[interval_];
    }

    function GetSpesificStrategy(
        address dcaAccountAddress_,
        Interval interval_,
        uint256 accountStrategyId_
    ) public view returns (Strategy memory) {
        return
            _strategies[interval_][
                _localStratId[dcaAccountAddress_][accountStrategyId_]
            ];
    }

    function _subscribeAccount(Strategy calldata strategy_) internal {
        uint256 id = _strategies[strategy_.interval].length;
        _strategies[strategy_.interval].push(strategy_);
        _localStratId[strategy_.accountAddress][strategy_.strategyId] = id;
        emit DCAAccontSubscription(strategy_, true);
    }

    function _unSubscribeAccount(Strategy calldata strategy_) private {
        _removeStratageyFromArray(strategy_);
        emit DCAAccontSubscription(strategy_, true);
    }

    function _setExecutionAddress(address newExecutionEOA_) internal {
        _executionEOAAddress = newExecutionEOA_;

        emit ExecutionEOAAddressChange(newExecutionEOA_, msg.sender);
    }

    function _startIntervalExecution(Interval interval_) internal {
        Strategy[] memory intervalStrategies = _strategies[interval_];
        //  Meed to work out a more efficient way of doing this
        for (uint i = 0; i < intervalStrategies.length; i++) {
            if (intervalStrategies[i].active)
                _singleExecution(
                    intervalStrategies[i].accountAddress,
                    intervalStrategies[i].strategyId
                );
        }

        _lastExecution[interval_] = block.timestamp;
        _totalIntervalsExecuted += 1;
    }

    function _singleExecution(
        address accountAddress_,
        uint strategyId_
    ) private {
        IDCAAccount(accountAddress_).Execute(strategyId_, _feeData.feeAmount);
    }

    function _setIntervalBlockAmounts() internal {
        //  Set the interval block amounts
        IntervalTimings[Interval.TestInterval] = 20;
        IntervalTimings[Interval.OneDay] = 5760;
        IntervalTimings[Interval.TwoDays] = 11520;
        IntervalTimings[Interval.OneWeek] = 40320;
        IntervalTimings[Interval.OneMonth] = 172800;
    }

    function _removeStratageyFromArray(Strategy calldata strategy_) private {
        //  Get the index of the strategy to remove from the local store
        //  Get the last element in the array
        uint256 local = _localStratId[strategy_.accountAddress][
            strategy_.strategyId
        ];
        Strategy memory movingStrat = _strategies[strategy_.interval][
            _strategies[strategy_.interval].length - 1
        ];

        //  Check the strategy to remove isnt the last
        if (_strategies[strategy_.interval].length - 1 != local) {
            //  If its not, set as moved strat
            //  Update the moved strat local Id
            _strategies[strategy_.interval][local] = movingStrat;
            _localStratId[movingStrat.accountAddress][
                movingStrat.strategyId
            ] = local;
        }
        //  Remove the last element
        _strategies[strategy_.interval].pop();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "./IDCADataStructures.sol";
import "./IDCAExecutor.sol";

interface IDCAAccount is IDCADataStructures {
    event StratogyExecuted(uint256 indexed strategyId_);
    event DCAExecutorChanged(address newAddress_);
    event StrategySubscribed(uint256 strategyId_, address executor_);
    event StrategyUnsubscribed(uint256 strategyId_);

    function Execute(uint256 strategyId_, uint256 feeAmount_) external;

    function SetupStrategy(
        Strategy calldata newStrategy_,
        uint256 seedFunds_,
        bool subscribeToEcecutor_
    ) external;

    function SubscribeStrategy(
        uint256 strategyId_
    ) external;

    function UnsubscribeStrategy(
        uint256 stratogyId
    ) external;

    function FundAccount(IERC20 token_, uint256 amount_) external;

    function GetBaseBalance(IERC20 token_) external returns (uint256);

    function GetTargetBalance(IERC20 token_) external returns (uint256);

    function UnFundAccount(IERC20 token_, uint256 amount_) external;

    function WithdrawSavings(IERC20 token_, uint256 amount_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDCADataStructures {
    // Define an enum to represent the interval type
    enum Interval {
        TestInterval, //Only for development
        OneDay, // 1 day = 5760 blocks
        TwoDays, // 2 days = 11520 blocks
        OneWeek, // 1 week = 40320 blocks
        OneMonth // 1 month = 172800 blocks
    }

    struct FeeDistribution {
        //These may move to s struct or set of if more call data is needed
        uint16 amountToExecutor; //In percent
        uint16 amountToComputing; //In percent
        uint16 amountToAdmin;
        uint16 feeAmount; //In percent
        address executionAddress;
        address computingAddress; //need to look into how distributed computing payments work
        address adminAddress;
    }

    // Define the Strategy struct
    struct Strategy {
        address accountAddress;
        TokeData baseToken;
        TokeData targetToken;
        Interval interval;
        uint256 amount;
        uint strategyId;
        bool reinvest;
        bool active;
        address revestContract; // should this be call data to execute?
    }

    struct TokeData {
        IERC20 tokenAddress;
        uint8 decimals;
        string ticker;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IDCADataStructures.sol";

interface IDCAExecutor is IDCADataStructures {
    event ExecutionEOAAddressChange(address newExecutionEOA_, address changer_);
    event ExecutedDCA(Interval indexed interval_);
    event DCAAccontSubscription(Strategy interval_, bool active_);

    function Subscribe(
        Strategy calldata strategy_
    ) external returns (bool sucsess);

    function Unsubscribe(
        Strategy calldata strategy_
    ) external returns (bool sucsess);

    function Execute(Interval interval_) external;

    function ForceFeeFund() external;

    
}

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OnlyAdmin is Ownable {
    mapping(address => bool) private _admins;

    modifier onlyAdmins() {
        require(
            _admins[_msgSender()] || (_msgSender() == owner()),
            "Address is not an admin"
        );
        _;
    }

    constructor() Ownable(address(msg.sender)) {}

    function addAdmin(address newAdmin_) public onlyOwner {
        _admins[newAdmin_] = true;
    }

    function removeAdmin(address oldAdmin_) public onlyOwner {
        _admins[oldAdmin_] = false;
    }

    function CheckIfAdmin(address addressToCheck_) public view returns (bool) {
        return _admins[addressToCheck_];
    }
}