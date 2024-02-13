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
import "./interfaces/ITypes.sol";

contract FeeManager is Ownable {
    uint256 private _txFeeWorkdayDepositPct;
    uint256 private _txFeeWorkdayWithdrawPct;

    uint256 private _txFeeHolidayDepositPct;
    uint256 private _txFeeHolidayWithdrawPct;

    uint256 private _firstDeposit;
    uint256 private _minDeposit;
    uint256 private _maxDeposit;
    uint256 private _minWithdraw;
    uint256 private _maxWithdraw;
    uint256 private _managementFeeRate;
    uint256 private _maxHolidayDepositPct;
    uint256 private _maxHolidayAggDepositPct;
    uint256 private _minTxsFee = 25 * 10 ** 6;

    event SetTxFeeWorkdayDepositPct(uint256 transactionFee);
    event SetTxFeeWorkdayWithdrawPct(uint256 transactionFee);
    event SetTxFeeHolidayDepositPct(uint256 transactionFee);
    event SetTxFeeHolidayWithdrawPct(uint256 transactionFee);

    event SetFirstDeposit(uint256 firstDeposit);
    event SetMinDeposit(uint256 minDeposit);
    event SetMaxDeposit(uint256 maxDeposit);
    event SetMinWithdraw(uint256 minWithdraw);
    event SetMaxWithdraw(uint256 maxWithdraw);
    event SetManagementFeeRate(uint256 feeRate);
    event SetMaxHolidayDeposit(uint256 percentage);
    event SetMaxHolidayAggDeposit(uint256 percentage);
    event UpdateMinTxsFee(uint256 fee);

    /**
     * @notice Initializes the FeeManager contract with initial values.
     * @dev Constructor for the FeeManager contract.
     * @param txFeeWorkdayDepositPct Fee for transactions on workkdays.
     * @param txFeeWorkdayWithdrawPct Fee for transactions on workdays.
     * @param txFeeHolidayDepositPct Fee for transactions on holidays.
     * @param txFeeHolidayWithdrawPct Fee for transactions on holidays.
     * @param maxHolidayDepositPct Max deposit percentage for holidays.
     * @param maxHolidayAggDepositPct Max aggregated deposit percentage for holidays.
     * @param firstDeposit Initial deposit amount.
     * @param minDeposit Minimum deposit value.
     * @param maxDeposit Maximum deposit value.
     * @param minWithdraw Minimum withdrawal value.
     * @param maxWithdraw Maximum withdrawal value.
     * @param managementFeeRate Rate of the management fee.
     */
    constructor(
        uint256 txFeeWorkdayDepositPct,
        uint256 txFeeWorkdayWithdrawPct,
        uint256 txFeeHolidayDepositPct,
        uint256 txFeeHolidayWithdrawPct,
        uint256 maxHolidayDepositPct,
        uint256 maxHolidayAggDepositPct,
        uint256 firstDeposit,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 minWithdraw,
        uint256 maxWithdraw,
        uint256 managementFeeRate
    ) {
        _txFeeWorkdayDepositPct = txFeeWorkdayDepositPct;
        _txFeeWorkdayWithdrawPct = txFeeWorkdayWithdrawPct;

        _txFeeHolidayDepositPct = txFeeHolidayDepositPct;
        _txFeeHolidayWithdrawPct = txFeeHolidayWithdrawPct;

        _firstDeposit = firstDeposit;
        _managementFeeRate = managementFeeRate;
        _maxHolidayDepositPct = maxHolidayDepositPct;
        _maxHolidayAggDepositPct = maxHolidayAggDepositPct;

        setMaxDeposit(maxDeposit);
        setMinDeposit(minDeposit);
        setMaxWithdraw(maxWithdraw);
        setMinWithdraw(minWithdraw);
    }

    /**
     * @notice Sets the depsoti transaction fee for workdays.
     * @dev Only callable by the contract owner.
     * @param txsFee The transaction fee for workdays.
     */
    function setTxFeeWorkdayDepositPct(uint256 txsFee) external onlyOwner {
        _txFeeWorkdayDepositPct = txsFee;
        emit SetTxFeeWorkdayDepositPct(txsFee);
    }

    /**
     * @notice Sets the withdraw transaction fee for workdays.
     * @dev Only callable by the contract owner.
     * @param txsFee The transaction fee for workdays.
     */
    function setTxFeeWorkdayWithdrawPct(uint256 txsFee) external onlyOwner {
        _txFeeWorkdayWithdrawPct = txsFee;
        emit SetTxFeeWorkdayWithdrawPct(txsFee);
    }

    /**
     * @notice Sets the deposit transaction fee for holidays.
     * @dev Only callable by the contract owner.
     * @param txsFee The transaction fee for holidays.
     */
    function setTxFeeHolidayDepositPct(uint256 txsFee) external onlyOwner {
        _txFeeHolidayDepositPct = txsFee;
        emit SetTxFeeHolidayDepositPct(txsFee);
    }

    /**
     * @notice Sets the withdraw transaction fee for holidays.
     * @dev Only callable by the contract owner.
     * @param txsFee The transaction fee for holidays.
     */
    function setTxFeeHolidayWithdrawPct(uint256 txsFee) external onlyOwner {
        _txFeeHolidayWithdrawPct = txsFee;
        emit SetTxFeeHolidayWithdrawPct(txsFee);
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
     * @notice Sets the maximum aggregated deposit percentage for holidays.
     * @dev Only callable by the contract owner.
     * @param percentage The maximum aggregated deposit percentage.
     */
    function setMaxHolidayAggDepositPct(uint256 percentage) external onlyOwner {
        _maxHolidayAggDepositPct = percentage;
        emit SetMaxHolidayAggDeposit(percentage);
    }

    /**
     * @notice Sets the maximum deposit percentage for holidays.
     * @dev Only callable by the contract owner.
     * @param percentage The maximum deposit percentage for holidays.
     */
    function setMaxHolidayDepositPct(uint256 percentage) external onlyOwner {
        _maxHolidayDepositPct = percentage;
        emit SetMaxHolidayDeposit(percentage);
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
     * @notice Gets the transaction fee
     * @dev View function to get the transaction fee.
     * @return The transaction fee.
     */
    function getTxFeePct(
        ActionType _type,
        bool _isWeekend
    ) external view returns (uint256) {
        if (_type == ActionType.DEPOSIT) {
            return
                _isWeekend ? _txFeeHolidayDepositPct : _txFeeWorkdayDepositPct;
        } else {
            return
                _isWeekend
                    ? _txFeeHolidayWithdrawPct
                    : _txFeeWorkdayWithdrawPct;
        }
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
     * @notice Gets the maximum deposit percentages for holidays.
     * @dev View function to retrieve holidays deposit limits.
     * @return maxDepositPct The maximum single deposit percentage for holidays.
     * @return maxDepositAggregatedPct The maximum aggregated deposit percentage for holidays.
     */
    function getMaxHolidayDepositPct()
        external
        view
        returns (uint256 maxDepositPct, uint256 maxDepositAggregatedPct)
    {
        maxDepositPct = _maxHolidayDepositPct;
        maxDepositAggregatedPct = _maxHolidayAggDepositPct;
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

enum ActionType {
    DEPOSIT,
    REDEEM
}