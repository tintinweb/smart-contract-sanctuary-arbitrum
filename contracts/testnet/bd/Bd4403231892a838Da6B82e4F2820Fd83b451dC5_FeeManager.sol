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
pragma solidity =0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is Ownable {
    uint256 private _transactionFeeWeekday;
    uint256 private _transactionFeeWeekend;
    uint256 private _firstDeposit;
    uint256 private _minDeposit;
    uint256 private _maxDeposit;
    uint256 private _minWithdraw;
    uint256 private _maxWithdraw;
    uint256 private _managementFeeRate;
    uint256 private _maxWeekendDepositPct;
    uint256 private _maxWeekendAggregatedDepositPct;
    uint256 private _minTxsFee = 25 * 10 ** 6;

    event SetTransactionFeeWeekday(uint256 transactionFee);
    event SetTransactionFeeWeekend(uint256 transactionFee);
    event SetFirstDeposit(uint256 firstDeposit);
    event SetMinDeposit(uint256 minDeposit);
    event SetMaxDeposit(uint256 maxDeposit);
    event SetMinWithdraw(uint256 minWithdraw);
    event SetMaxWithdraw(uint256 maxWithdraw);
    event SetManagementFeeRate(uint256 feeRate);
    event SetMaxWeekendDeposit(uint256 percentage);
    event SetMaxWeekendAggregatedDeposit(uint256 percentage);
    event UpdateMinTxsFee(uint256 fee);

    /**
     * @notice Initializes the FeeManager contract with initial values.
     * @dev Constructor for the FeeManager contract.
     * @param transactionFeeWeekday Fee for transactions on weekdays.
     * @param transactionFeeWeekend Fee for transactions on weekends.
     * @param maxWeekendDepositPct Max deposit percentage for weekends.
     * @param maxWeekendAggregatedDepositPct Max aggregated deposit percentage for weekends.
     * @param firstDeposit Initial deposit amount.
     * @param minDeposit Minimum deposit value.
     * @param maxDeposit Maximum deposit value.
     * @param minWithdraw Minimum withdrawal value.
     * @param maxWithdraw Maximum withdrawal value.
     * @param managementFeeRate Rate of the management fee.
     */
    constructor(
        uint256 transactionFeeWeekday,
        uint256 transactionFeeWeekend,
        uint256 maxWeekendDepositPct,
        uint256 maxWeekendAggregatedDepositPct,
        uint256 firstDeposit,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 minWithdraw,
        uint256 maxWithdraw,
        uint256 managementFeeRate
    ) {
        _transactionFeeWeekday = transactionFeeWeekday;
        _transactionFeeWeekend = transactionFeeWeekend;
        _firstDeposit = firstDeposit;
        _managementFeeRate = managementFeeRate;
        _maxWeekendDepositPct = maxWeekendDepositPct;
        _maxWeekendAggregatedDepositPct = maxWeekendAggregatedDepositPct;

        setMaxDeposit(maxDeposit);
        setMinDeposit(minDeposit);
        setMaxWithdraw(maxWithdraw);
        setMinWithdraw(minWithdraw);
    }

    /**
     * @notice Sets the transaction fee for weekdays.
     * @dev Only callable by the contract owner.
     * @param txsFee The transaction fee for weekdays.
     */
    function setTransactionFeeWeekday(uint256 txsFee) external onlyOwner {
        _transactionFeeWeekday = txsFee;
        emit SetTransactionFeeWeekday(txsFee);
    }

    /**
     * @notice Sets the transaction fee for weekends.
     * @dev Only callable by the contract owner.
     * @param txsFee The transaction fee for weekends.
     */
    function setTransactionFeeWeekend(uint256 txsFee) external onlyOwner {
        _transactionFeeWeekend = txsFee;
        emit SetTransactionFeeWeekend(txsFee);
    }

    /**
     * @notice Sets the initial deposit amount.
     * @dev Only callable by the contract owner.
     * @param firstDeposit The initial deposit amount.
     */
    function setFirstDeposit(uint256 firstDeposit) external onlyOwner {
        _firstDeposit = firstDeposit;
        emit SetFirstDeposit(firstDeposit);
    }

    /**
     * @notice Sets the management fee rate.
     * @dev Only callable by the contract owner.
     * @param feeRate The management fee rate.
     */
    function setManagementFeeRate(uint256 feeRate) external onlyOwner {
        _managementFeeRate = feeRate;
        emit SetManagementFeeRate(feeRate);
    }

    /**
     * @notice Sets the maximum aggregated deposit percentage for weekends.
     * @dev Only callable by the contract owner.
     * @param percentage The maximum aggregated deposit percentage.
     */
    function setMaxWeekendAggregatedDepositPct(
        uint256 percentage
    ) external onlyOwner {
        _maxWeekendAggregatedDepositPct = percentage;
        emit SetMaxWeekendAggregatedDeposit(percentage);
    }

    /**
     * @notice Sets the maximum deposit percentage for weekends.
     * @dev Only callable by the contract owner.
     * @param percentage The maximum deposit percentage for weekends.
     */
    function setMaxWeekendDepositPct(uint256 percentage) external onlyOwner {
        _maxWeekendDepositPct = percentage;
        emit SetMaxWeekendDeposit(percentage);
    }

    /**
     * @notice Sets the minimum transaction fee.
     * @dev Only callable by the contract owner.
     * @param _fee The minimum transaction fee.
     */
    function setMinTxsFee(uint256 _fee) external onlyOwner {
        _minTxsFee = _fee;
        emit UpdateMinTxsFee(_fee);
    }

    /**
     * @notice Gets the transaction fee for weekdays.
     * @dev View function to get the weekday transaction fee.
     * @return The weekday transaction fee.
     */
    function getTxFeeWeekday() external view returns (uint256) {
        return _transactionFeeWeekday;
    }

    /**
     * @notice Gets the transaction fee for weekends.
     * @dev View function to get the weekend transaction fee.
     * @return The weekend transaction fee.
     */
    function getTxFeeWeekend() external view returns (uint256) {
        return _transactionFeeWeekend;
    }

    /**
     * @notice Gets the minimum and maximum deposit values.
     * @dev View function to get deposit limits.
     * @return minDeposit The minimum deposit limit.
     * @return maxDeposit The maximum deposit limit.
     */
    function getMinMaxDeposit()
        external
        view
        returns (uint256 minDeposit, uint256 maxDeposit)
    {
        minDeposit = _minDeposit;
        maxDeposit = _maxDeposit;
    }

    /**
     * @notice Gets the minimum and maximum withdrawal values.
     * @dev View function to get withdrawal limits.
     * @return minWithdraw The minimum withdrawal limit.
     * @return maxWithdraw The maximum withdrawal limit.
     */
    function getMinMaxWithdraw()
        external
        view
        returns (uint256 minWithdraw, uint256 maxWithdraw)
    {
        minWithdraw = _minWithdraw;
        maxWithdraw = _maxWithdraw;
    }

    /**
     * @notice Gets the management fee rate.
     * @dev View function to retrieve the management fee rate.
     * @return feeRate The current management fee rate.
     */
    function getManagementFeeRate() external view returns (uint256 feeRate) {
        feeRate = _managementFeeRate;
    }

    /**
     * @notice Gets the first deposit amount.
     * @dev View function to retrieve the first deposit value.
     * @return firstDeposit The value of the initial deposit.
     */
    function getFirstDeposit() external view returns (uint256 firstDeposit) {
        firstDeposit = _firstDeposit;
    }

    /**
     * @notice Gets the maximum deposit percentages for weekends.
     * @dev View function to retrieve weekend deposit limits.
     * @return maxDepositPct The maximum single deposit percentage for weekends.
     * @return maxDepositAggregatedPct The maximum aggregated deposit percentage for weekends.
     */
    function getMaxWeekendDepositPct()
        external
        view
        returns (uint256 maxDepositPct, uint256 maxDepositAggregatedPct)
    {
        maxDepositPct = _maxWeekendDepositPct;
        maxDepositAggregatedPct = _maxWeekendAggregatedDepositPct;
    }

    /**
     * @notice Gets the minimum transaction fee.
     * @dev View function to retrieve the minimum transaction fee.
     * @return The current minimum transaction fee.
     */
    function getMinTxsFee() external view returns (uint256) {
        return _minTxsFee;
    }

    /**
     * @notice Sets the minimum deposit amount.
     * @dev Only callable by the contract owner.
     * @param minDeposit The new minimum deposit value.
     */
    function setMinDeposit(uint256 minDeposit) public onlyOwner {
        require(minDeposit < _maxDeposit, "deposit min should lt max");
        _minDeposit = minDeposit;
        emit SetMinDeposit(minDeposit);
    }

    /**
     * @notice Sets the maximum deposit amount.
     * @dev Only callable by the contract owner.
     * @param maxDeposit The new maximum deposit value.
     */
    function setMaxDeposit(uint256 maxDeposit) public onlyOwner {
        require(_minDeposit < maxDeposit, "deposit max should gt min");
        _maxDeposit = maxDeposit;
        emit SetMaxDeposit(maxDeposit);
    }

    /**
     * @notice Sets the minimum withdrawal amount.
     * @dev Only callable by the contract owner.
     * @param minWithdraw The new minimum withdrawal value.
     */
    function setMinWithdraw(uint256 minWithdraw) public onlyOwner {
        require(minWithdraw < _maxWithdraw, "withdraw min should lt max");
        _minWithdraw = minWithdraw;
        emit SetMinWithdraw(minWithdraw);
    }

    /**
     * @notice Sets the maximum withdrawal amount.
     * @dev Only callable by the contract owner.
     * @param maxWithdraw The new maximum withdrawal value.
     */
    function setMaxWithdraw(uint256 maxWithdraw) public onlyOwner {
        require(_minWithdraw < maxWithdraw, "withdraw max should gt min");
        _maxWithdraw = maxWithdraw;
        emit SetMaxWithdraw(maxWithdraw);
    }
}