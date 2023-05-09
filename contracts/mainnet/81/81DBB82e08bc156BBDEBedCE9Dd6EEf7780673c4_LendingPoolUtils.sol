// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../utils/Types.sol";

    
interface IFeesManager {

    enum FeeType{
        NOT_SET,
        FIXED,
        LINEAR_DECAY_WITH_AUCTION
    }


    struct RateData{
        FeeType rateType;
        uint48 startRate;
        uint48 endRate;
        uint48 auctionStartDate;
        uint48 auctionEndDate;
        uint48 poolExpiry;
    }

    error ZeroAddress();
    error NotAPool();
    error NoPermission();
    error InvalidType();
    error InvalidExpiry();
    error InvalidFeeRate();
    error InvalidFeeDates();

    event ChangeFee(address indexed pool, FeeType rateType, uint48 startRate, uint48 endRate, uint48 auctionStartDate, uint48 auctionEndDate);

    function setPoolRates(
        address _lendingPool,
        bytes32 _ratesAndType,
        uint48 _expiry,
        uint48 _protocolFee
    ) external;

    function getCurrentRate(address _pool) external view returns (uint48);
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;
import "../utils/Types.sol";
interface IGenericPool {

    error TransferFailed();

    function getPoolSettings() external view returns (GeneralPoolSettings memory);
    function deposit(
        uint256 _depositAmount
    ) external;
    function version() external pure returns (uint256);
}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

import "../utils/Types.sol";

interface IPoolFactory {
    
    event DeployPool(
        address poolAddress,
        address deployer,
        address implementation,
        FactoryParameters factorySettings,
        GeneralPoolSettings poolSettings
    );

    error InvalidPauseTime();
    error OperationsPaused();
    error LendTokenNotSupported();
    error ColTokenNotSupported();
    error InvalidTokenPair();
    error LendRatio0();
    error InvalidExpiry();
    error ImplementationNotWhitelisted();
    error StrategyNotWhitelisted();
    error TokenNotSupportedWithStrategy();
    error ZeroAddress();
    error InvalidParameters();
    error NotGranted();
    error NotOwner();
    error NotAuthorized();



    function pools(address _pool) external view returns (bool);

    function treasury() external view returns (address);

    function protocolFee() external view returns (uint48);

    function repaymentsPaused() external view returns (bool);

    function isPoolPaused(address _pool, address _lendTokenAddr, address _colTokenAddr) external view returns (bool);

    function allowUpgrade() external view returns (bool);

    function implementations(PoolType _type) external view returns (address);

}

// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;
import "../../interfaces/IGenericPool.sol";

interface ILendingPool is IGenericPool {
    
    /* ========== EVENTS ========== */
    event Borrow(address indexed borrower, uint256 vendorFees, uint256 lenderFees, uint48 borrowRate, uint256 additionalColAmount, uint256 additionalDebt);
    event RollIn(address indexed borrower, address originPool, uint256 originDebt, uint256 lendToRepay, uint256 lenderFeeAmt, uint256 protocolFeeAmt, uint256 colRolled, uint256 colToReimburse);
    event Repay(address indexed borrower, uint256 debtRepaid, uint256 colReturned);
    event Collect(address indexed lender, uint256 lenderLend, uint256 lenderCol);
    event UpdateBorrower(address indexed borrower, bool allowed);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event RolloverPoolSet(address pool, bool enabled);
    event Withdraw(address indexed lender, uint256 amount);
    event Deposit(address indexed lender, uint256 amount);
    event WithdrawStrategyTokens(uint256 sharesAmount);
    event Pause(uint48 timestamp);
    event BalanceChange(address token, address to, bool incoming, uint256 amount);

    /* ========== STRUCTS ========== */
    struct UserReport {
        uint256 debt;           // total borrowed in lend token
        uint256 colAmount;      // total collateral deposited by the borrower
    }

    /* ========== ERRORS ========== */
    error PoolNotWhitelisted();
    error OperationsPaused();
    error NotOwner();
    error ZeroAddress();
    error InvalidParameters();
    error PrivatePool();
    error PoolExpired();
    error FeeTooHigh();
    error BorrowingPaused();
    error NotEnoughLiquidity();
    error FailedStrategyWithdraw();
    error NoDebt();
    error PoolStillActive();
    error NotGranted();
    error UpgradeNotAllowed();
    error ImplementationNotWhitelisted();
    error RolloverPartialAmountNotSupported();
    error NotValidPrice();
    error NotPrivatePool();
    error DebtIsLess();
    error InvalidCollateralReceived();
    
    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint48 _rate
    ) external returns (uint256 assetsBorrowed, uint256 lenderFees, uint256 vendorFees);

    function repayOnBehalfOf(
        address _borrower,
        uint256 _repayAmount
    ) external returns (uint256 lendTokenReceived, uint256 colReturnAmount);

    function debts(address _borrower) external returns (uint256, uint256);
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import "../../interfaces/IPoolFactory.sol";
import "../../interfaces/IFeesManager.sol";
import "../../interfaces/IGenericPool.sol";
import "../../utils/Types.sol";
import "./ILendingPool.sol";

library LendingPoolUtils {
    
    /* ========== ERRORS ========== */ 
    error NotAPool();
    error DifferentLendToken();
    error DifferentColToken();
    error DifferentPoolOwner();
    error InvalidExpiry();
    error PoolTypesDiffer();
    error UnableToChargeFullFee();

    /* ========== CONSTANTS ========== */
    uint256 private constant HUNDRED_PERCENT = 100_0000;

    /* ========== FUNCTIONS ========== */

    /// @notice                     Performs validation checks to ensure that both origin and destination pools are valid for the rollover transaction.
    /// @param originSettings       The pool settings of the origin pool.
    /// @param settings             The pool settings of the pool that is being rolled into. Also known as the destination pool. 
    /// @param _originPool          The address of the origin pool.
    /// @param _factory             The address of the pool factory.
    function validatePoolForRollover(
        GeneralPoolSettings memory originSettings,
        GeneralPoolSettings memory settings,
        address _originPool,
        IPoolFactory _factory
    ) external view {
        if (!_factory.pools(_originPool)) revert NotAPool();
        
        if (originSettings.lendToken != settings.lendToken)
            revert DifferentLendToken();

        if (originSettings.colToken != settings.colToken)
            revert DifferentColToken();

        if (originSettings.owner != settings.owner) revert DifferentPoolOwner();

        if (settings.expiry <= originSettings.expiry) revert InvalidExpiry(); // This also prevents pools to rollover into itself

        if (settings.poolType != originSettings.poolType ) revert PoolTypesDiffer();
    }

    /// @notice                      Computes lend token and collateral token amount differences in origin pool and destination pools.
    /// @param _originSettings       The pool settings of the origin pool.
    /// @param _settings             The pool settings of the pool that is being rolled into. Also known as the destination pool. 
    /// @param _colReturned          The amount of collateral moved xfered from origin pool to destination pool.
    /// @return colToReimburse       The amount of collateral to refund borrower in cases where the destination pool's lend ratio is greater than origin pool's lend ratio.
    /// @return lendToRepay          The amount of lend tokens that the borrower must repay in cases where the destination pool's lend ratio less than the origin pool's lend ratio.
    function computeRolloverDifferences(
        GeneralPoolSettings memory _originSettings,
        GeneralPoolSettings memory _settings,
        uint256 _colReturned
    ) external view returns (uint256 colToReimburse, uint256 lendToRepay){
        if (_settings.lendRatio <= _originSettings.lendRatio) { // Borrower needs to repay
            lendToRepay = _computePayoutAmount(
                _colReturned,
                _originSettings.lendRatio - _settings.lendRatio,
                _settings.colToken,
                _settings.lendToken
            );
        }else{ // We need to send collateral
            colToReimburse = _computeReimbursement(
                _colReturned,
                _originSettings.lendRatio,
                _settings.lendRatio
            );
            _colReturned -= colToReimburse;
        }
    }

    /// @notice                        Computes the amount of lend tokens that the borrower will receive. Also computes lender fee amount.
    /// @param _lendToken              Address of lend token.
    /// @param _colToken               Address of collateral token.
    /// @param _mintRatio              Amount of lend tokens to lend for every one unit of deposited collateral.
    /// @param _colDepositAmount       Actual amount of collateral tokens deposited by borrower.
    /// @param _effectiveRate          Borrow rate of pool.
    /// @return additionalFees         Fee amount owed to the lender.
    /// @return rawPayoutAmount        Lend token amount borrower will receive before lender fees and protocol fees are subtracted.
    function computeDebt(
        IERC20 _lendToken,
        IERC20 _colToken,
        uint256 _mintRatio,
        uint256 _colDepositAmount,
        uint48 _effectiveRate
    ) external view returns (uint256 additionalFees, uint256 rawPayoutAmount){
        
        rawPayoutAmount = _computePayoutAmount(
            _colDepositAmount,
            _mintRatio,
            _colToken,
            _lendToken
        );
        additionalFees = (rawPayoutAmount * _effectiveRate) / HUNDRED_PERCENT;
    }
    
    /// @notice                     Compute the amount of lend tokens to send given collateral deposited
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _lendRatio           LendRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           lend token that is being paid out for collateral
    /// @return                     Lend token amount in lend decimals
    ///
    /// In this function we will need to compute the amount of lend token to send
    /// based on collateral and mint ratio.
    /// Mint Ratio dictates how many lend tokens we send per unit of collateral.
    /// LendRatio must always be passed as 18 decimals.
    /// So:
    ///    lentAmount = lendRatio * colAmount
    /// Given the above information, there are only 2 cases to consider when adjusting decimals:
    ///    lendDecimals > colDecimals + 18 OR lendDecimals <= colDecimals + 18
    /// Based on the situation we will either multiply or divide by 10**x where x is difference between desired decimals
    /// and the decimals we actually have. This way we minimize the number of divisions to at most one and
    /// impact of such division is minimal as it is a division by 10**x and only acts as a mean of reducing decimals count.
    function _computePayoutAmount(
        uint256 _colDepositAmount,
        uint256 _lendRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) private view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals >= lendDecimals) {
            return
                (_colDepositAmount * _lendRatio) /
                (10**(colDecimals + mintDecimals - lendDecimals));
        } else {
            return
                (_colDepositAmount * _lendRatio) *
                (10**(lendDecimals - colDecimals - mintDecimals));
        }
    }

    
    /// @notice                     Compute the amount of collateral to return for lend tokens
    /// @param _repayAmount         Amount of lend token that is being repaid
    /// @param _lendRatio           LendRatio to use when computing the payout
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @return                     Collateral amount returned for the lend token
    /// Amount of collateral to return is always computed as:
    ///                                 lendTokenAmount
    /// amountOfCollateralReturned  =   ---------------
    ///                                    lendRatio
    /// 
    /// We also need to ensure that the correct amount of decimals are used. Output should always be in
    /// collateral token decimals.
    function computeCollateralReturn(
        uint256 _repayAmount,
        uint256 _lendRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) external view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) { // If lend decimals are larger than sum of 18(for mint ratio) and col decimals, we need to divide result by 10**(difference)
            return
                _repayAmount /
                (_lendRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        } else { // Else we multiply
            return
                (_repayAmount *
                    10**(colDecimals + mintDecimals - lendDecimals)) /
                _lendRatio;
        }
    }

    /// @notice                  Compute the amount of collateral that needs to be sent to user when rolling into a pool with higher mint ratio
    /// @param _colAmount        Collateral amount deposited into the original pool
    /// @param _lendRatio        LendRatio of the original pool
    /// @param _newLendRatio     LendRatio of the new pool
    /// @return                  Collateral reimbursement amount.
    function _computeReimbursement(
        uint256 _colAmount,
        uint256 _lendRatio,
        uint256 _newLendRatio
    ) private pure returns (uint256) {
        return (_colAmount * (_newLendRatio - _lendRatio)) / _newLendRatio;
    }
}

// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import {IERC20MetadataUpgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

enum PoolType{
    LENDING_ONE_TO_MANY,
    BORROWING_ONE_TO_MANY
}

/* ========== STRUCTS ========== */
struct DeploymentParameters {
    uint256 lendRatio;
    address colToken;
    address lendToken;
    bytes32 feeRatesAndType;
    PoolType poolType;
    bytes32 strategy;
    address[] allowlist;
    uint256 initialDeposit;
    uint48 expiry;
    uint48 ltv;
    uint48 pauseTime;
}

struct FactoryParameters {
    address feesManager;
    bytes32 strategy;
    address oracle;
    address treasury;
    address posTracker;
}

struct GeneralPoolSettings {
    PoolType poolType;
    address owner;
    uint48 expiry;
    IERC20 colToken;
    uint48 protocolFee;
    IERC20 lendToken;
    uint48 ltv;
    uint48 pauseTime;
    uint256 lendRatio;
    address[] allowlist;
    bytes32 feeRatesAndType;
}