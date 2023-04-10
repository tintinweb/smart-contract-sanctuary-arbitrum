/**
 *Submitted for verification at Arbiscan on 2023-04-10
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/ContextUpg[email protected]

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}


// File contracts/library/Constant.sol

pragma solidity ^0.6.12;

library Constant {
    uint256 public constant CLOSE_FACTOR_MIN = 5e16;
    uint256 public constant CLOSE_FACTOR_MAX = 9e17;
    uint256 public constant COLLATERAL_FACTOR_MAX = 9e17;
    uint256 public constant LIQUIDATION_THRESHOLD_MAX = 9e17;
    uint256 public constant LIQUIDATION_BONUS_MAX = 5e17;
    uint256 public constant AUCTION_DURATION_MAX = 7 days;
    uint256 public constant MIN_BID_FINE_MAX = 100 ether;
    uint256 public constant REDEEM_FINE_RATE_MAX = 5e17;
    uint256 public constant REDEEM_THRESHOLD_MAX = 9e17;
    uint256 public constant BORROW_RATE_MULTIPLIER_MAX = 1e19;
    uint256 public constant AUCTION_FEE_RATE_MAX = 5e17;

    enum EcoZone {
        RED,
        ORANGE,
        YELLOW,
        LIGHTGREEN,
        GREEN
    }

    enum EcoScorePreviewOption {
        LOCK,
        CLAIM,
        EXTEND,
        LOCK_MORE
    }

    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        None,
        // The loan data is stored, but not initiated yet.
        Active,
        // The loan is in auction, higest price liquidator will got chance to claim it.
        Auction,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
        Defaulted
    }

    struct LoanData {
        uint256 loanId;
        LoanState state;
        address borrower;
        address gNft;
        address nftAsset;
        uint256 nftTokenId;
        uint256 borrowAmount;
        uint256 interestIndex;

        uint256 bidStartTimestamp;
        address bidderAddress;
        uint256 bidPrice;
        uint256 bidBorrowAmount;
        uint256 floorPrice;
        uint256 bidCount;
        address firstBidderAddress;
    }

    struct MarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
    }

    struct NftMarketInfo {
        bool isListed;
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct BorrowInfo {
        uint256 borrow;
        uint256 interestIndex;
    }

    struct AccountSnapshot {
        uint256 gTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRate;
    }

    struct AccrueSnapshot {
        uint256 totalBorrow;
        uint256 totalReserve;
        uint256 accInterestIndex;
    }

    struct AccrueLoanSnapshot {
        uint256 totalBorrow;
        uint256 accInterestIndex;
    }

    struct DistributionInfo {
        uint256 supplySpeed;
        uint256 borrowSpeed;
        uint256 totalBoostedSupply;
        uint256 totalBoostedBorrow;
        uint256 accPerShareSupply;
        uint256 accPerShareBorrow;
        uint256 accruedAt;
    }

    struct DistributionAccountInfo {
        uint256 accruedGRV; // Unclaimed GRV rewards amount
        uint256 boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint256 boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint256 accPerShareSupply; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint256 accPerShareBorrow; // Last integral value of GRV rewards per share. ∫(GRVRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionAPY {
        uint256 apySupplyGRV;
        uint256 apyBorrowGRV;
        uint256 apyAccountSupplyGRV;
        uint256 apyAccountBorrowGRV;
    }

    struct EcoScoreInfo {
        uint256 claimedGrv;
        uint256 ecoDR;
        EcoZone ecoZone;
        uint256 compoundGrv;
        uint256 changedEcoZoneAt;
    }

    struct BoostConstant {
        uint256 boost_max;
        uint256 boost_portion;
        uint256 ecoBoost_portion;
    }

    struct RebateCheckpoint {
        uint256 timestamp;
        uint256 totalScore;
        uint256 adminFeeRate;
        mapping(address => uint256) amount;
    }

    struct RebateClaimInfo {
        uint256 timestamp;
        address[] markets;
        uint256[] amount;
        uint256[] prices;
        uint256 value;
    }

    struct LockInfo {
        uint256 timestamp;
        uint256 amount;
        uint256 expiry;
    }

    struct EcoPolicyInfo {
        uint256 boostMultiple;
        uint256 maxBoostCap;
        uint256 boostBase;
        uint256 redeemFee;
        uint256 claimTax;
        uint256[] pptTax;
    }

    struct EcoZoneStandard {
        uint256 minExpiryOfGreenZone;
        uint256 minExpiryOfLightGreenZone;
        uint256 minDrOfGreenZone;
        uint256 minDrOfLightGreenZone;
        uint256 minDrOfYellowZone;
        uint256 minDrOfOrangeZone;
    }

    struct PPTPhaseInfo {
        uint256 phase1;
        uint256 phase2;
        uint256 phase3;
        uint256 phase4;
    }
}


// File contracts/interfaces/ICore.sol

pragma solidity ^0.6.12;

interface ICore {
    /* ========== Event ========== */
    event MarketSupply(address user, address gToken, uint256 uAmount);
    event MarketRedeem(address user, address gToken, uint256 uAmount);

    event MarketListed(address gToken);
    event MarketEntered(address gToken, address account);
    event MarketExited(address gToken, address account);

    event CloseFactorUpdated(uint256 newCloseFactor);
    event CollateralFactorUpdated(address gToken, uint256 newCollateralFactor);
    event LiquidationIncentiveUpdated(uint256 newLiquidationIncentive);
    event SupplyCapUpdated(address indexed gToken, uint256 newSupplyCap);
    event BorrowCapUpdated(address indexed gToken, uint256 newBorrowCap);
    event KeeperUpdated(address newKeeper);
    event NftCoreUpdated(address newNftCore);
    event ValidatorUpdated(address newValidator);
    event GRVDistributorUpdated(address newGRVDistributor);
    event RebateDistributorUpdated(address newRebateDistributor);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    function nftCore() external view returns (address);

    function validator() external view returns (address);

    function rebateDistributor() external view returns (address);

    function allMarkets() external view returns (address[] memory);

    function marketListOf(address account) external view returns (address[] memory);

    function marketInfoOf(address gToken) external view returns (Constant.MarketInfo memory);

    function checkMembership(address account, address gToken) external view returns (bool);

    function accountLiquidityOf(
        address account
    ) external view returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD);

    function closeFactor() external view returns (uint256);

    function liquidationIncentive() external view returns (uint256);

    function enterMarkets(address[] memory gTokens) external;

    function exitMarket(address gToken) external;

    function supply(address gToken, uint256 underlyingAmount) external payable returns (uint256);

    function redeemToken(address gToken, uint256 gTokenAmount) external returns (uint256 redeemed);

    function redeemUnderlying(address gToken, uint256 underlyingAmount) external returns (uint256 redeemed);

    function borrow(address gToken, uint256 amount) external;

    function nftBorrow(address gToken, address user, uint256 amount) external;

    function repayBorrow(address gToken, uint256 amount) external payable;

    function nftRepayBorrow(address gToken, address user, uint256 amount) external payable;

    function repayBorrowBehalf(address gToken, address borrower, uint256 amount) external payable;

    function liquidateBorrow(
        address gTokenBorrowed,
        address gTokenCollateral,
        address borrower,
        uint256 amount
    ) external payable;

    function claimGRV() external;

    function claimGRV(address market) external;

    function compoundGRV() external;

    function firstDepositGRV(uint256 expiry) external;

    function transferTokens(address spender, address src, address dst, uint256 amount) external;
}


// File contracts/interfaces/IGToken.sol

pragma solidity ^0.6.12;

interface IGToken {
    function underlying() external view returns (address);

    function totalSupply() external view returns (uint256);

    function accountSnapshot(address account) external view returns (Constant.AccountSnapshot memory);

    function underlyingBalanceOf(address account) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    function _totalBorrow() external view returns (uint256);

    function totalReserve() external view returns (uint256);

    function reserveFactor() external view returns (uint256);

    function lastAccruedTime() external view returns (uint256);

    function accInterestIndex() external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function getCash() external view returns (uint256);

    function getRateModel() external view returns (address);

    function getAccInterestIndex() external view returns (uint256);

    function accruedAccountSnapshot(address account) external returns (Constant.AccountSnapshot memory);

    function accruedBorrowBalanceOf(address account) external returns (uint256);

    function accruedTotalBorrow() external returns (uint256);

    function accruedExchangeRate() external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    function supply(address account, uint256 underlyingAmount) external payable returns (uint256);

    function redeemToken(address account, uint256 gTokenAmount) external returns (uint256);

    function redeemUnderlying(address account, uint256 underlyingAmount) external returns (uint256);

    function borrow(address account, uint256 amount) external returns (uint256);

    function repayBorrow(address account, uint256 amount) external payable returns (uint256);

    function repayBorrowBehalf(address payer, address borrower, uint256 amount) external payable returns (uint256);

    function liquidateBorrow(
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint256 amount
    ) external payable returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount);

    function seize(address liquidator, address borrower, uint256 gTokenAmount) external;

    function withdrawReserves() external;

    function transferTokensInternal(address spender, address src, address dst, uint256 amount) external;
}


// File contracts/interfaces/ILendPoolLoan.sol

pragma solidity ^0.6.12;

interface ILendPoolLoan {
    /* ========== Event ========== */
    event LoanCreated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address gNft,
        uint256 amount
    );

    event LoanUpdated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amountAdded,
        uint256 amountTaken
    );

    event LoanRepaid(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    );

    event LoanAuctioned(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 bidBorrowAmount,
        address bidder,
        uint256 price,
        address previousBidder,
        uint256 previousPrice,
        uint256 floorPrice
    );

    event LoanRedeemed(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 repayAmount
    );

    event LoanLiquidated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    );

    event AuctionDurationUpdated(
        uint256 newAuctionDuration
    );

    event MinBidFineUpdated(
        uint256 newMinBidFine
    );

    event RedeemFineRateUpdated(
        uint256 newRedeemFineRate
    );

    event RedeemThresholdUpdated(
        uint256 newRedeemThreshold
    );

    event BorrowRateMultiplierUpdated(
        uint256 borrowRateMultiplier
    );

    event AuctionFeeRateUpdated(
        uint256 auctionFeeRate
    );

    function createLoan(
        address to,
        address nftAsset,
        uint256 nftTokenId,
        address gNft,
        uint256 amount
    ) external returns (uint256);

    function updateLoan(
        uint256 loanId,
        uint256 amountAdded,
        uint256 amountTaken
    ) external;

    function repayLoan(
        uint256 loanId,
        address gNft,
        uint256 amount
    ) external;

    function auctionLoan(
        address bidder,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external;

    function redeemLoan(
        uint256 loanId,
        uint256 amountTaken
    ) external;

    function liquidateLoan(
        address gNft,
        uint256 loanId,
        uint256 borrowAmount
    ) external;

    function initNft(address nftAsset, address gNft) external;
    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);
    function getNftCollateralAmount(address nftAsset) external view returns (uint256);
    function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);
    function getLoan(uint256 loanId) external view returns (Constant.LoanData memory loanData);

    function borrowBalanceOf(uint256 loanId) external view returns (uint256);
    function userBorrowBalance(address user) external view returns (uint256);
    function marketBorrowBalance(address gNft) external view returns (uint256);
    function marketAccountBorrowBalance(address gNft, address user) external view returns (uint256);
    function accrueInterest() external;
    function totalBorrow() external view returns (uint256);
    function currentLoanId() external view returns (uint256);
    function getAccInterestIndex() external view returns (uint256);

    function auctionDuration() external view returns (uint256);
    function minBidFine() external view returns (uint256);
    function redeemFineRate() external view returns (uint256);
    function redeemThreshold() external view returns (uint256);

    function auctionFeeRate() external view returns (uint256);
    function accInterestIndex() external view returns (uint256);
}


// File contracts/interfaces/INftCore.sol

pragma solidity ^0.6.12;

interface INftCore {
    /* ========== Event ========== */
    event MarketListed(address gNft);
    event MarketEntered(address gNft, address account);
    event MarketExited(address gNft, address account);

    event CollateralFactorUpdated(address gNft, uint256 newCollateralFactor);
    event SupplyCapUpdated(address indexed gNft, uint256 newSupplyCap);
    event BorrowCapUpdated(address indexed gNft, uint256 newBorrowCap);
    event LiquidationThresholdUpdated(address indexed gNft, uint256 newLiquidationThreshold);
    event LiquidationBonusUpdated(address indexed gNft, uint256 newLiquidationBonus);
    event KeeperUpdated(address newKeeper);
    event TreasuryUpdated(address newTreasury);
    event CoreUpdated(address newCore);
    event ValidatorUpdated(address newValidator);
    event NftOracleUpdated(address newNftOracle);
    event BorrowMarketUpdated(address newBorrowMarket);
    event LendPoolLoanUpdated(address newLendPoolLoan);

    event Borrow(
        address user,
        uint256 amount,
        address indexed nftAsset,
        uint256 nftTokenId,
        uint256 loanId,
        uint256 indexed referral
    );

    event Repay(
        address user,
        uint256 amount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    event Auction(
        address user,
        uint256 bidPrice,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    event Redeem(
        address user,
        uint256 borrowAmount,
        uint256 fineAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    event Liquidate(
        address user,
        uint256 repayAmount,
        uint256 remainAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    function allMarkets() external view returns (address[] memory);
    function marketInfoOf(address gNft) external view returns (Constant.NftMarketInfo memory);
    function getLendPoolLoan() external view returns (address);
    function getNftOracle() external view returns (address);

    function borrow(address gNft, uint256 tokenId, uint256 borrowAmount) external;
    function batchBorrow(
        address gNft,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    function repay(address gNft, uint256 tokenId) external payable;
    function batchRepay(address gNft,
        uint256[] calldata tokenIds,
        uint256[] calldata repayAmounts
    ) external payable;

    function auction(address gNft, uint256 tokenId) external payable;
    function redeem(address gNft, uint256 tokenId, uint256 amount, uint256 bidFine) external payable;
    function liquidate(address gNft, uint256 tokenId) external payable;
}


// File @openzeppelin/contracts/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File contracts/interfaces/IWETH.sol

pragma solidity ^0.6.12;

interface IWETH {
    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}


// File contracts/library/SafeToken.sol

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}


// File @openzeppelin/contracts/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File contracts/interfaces/IBEP20.sol

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


// File contracts/interfaces/IRateModel.sol

pragma solidity ^0.6.12;

interface IRateModel {
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) external view returns (uint256);

    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256);
}


// File contracts/interfaces/IRebateDistributor.sol

pragma solidity ^0.6.12;

interface IRebateDistributor {
    event RebateClaimed(address indexed user, address[] markets, uint256[] uAmount, uint256[] gAmount);

    function setKeeper(address _keeper) external;

    function pause() external;

    function unpause() external;

    function updateAdminFeeRate(uint256 newAdminFeeRate) external;

    function approveMarkets() external;

    function checkpoint() external;

    function thisWeekRebatePool() external view returns (uint256[] memory, address[] memory, uint256, uint256);

    function weeklyRebatePool() external view returns (uint256, uint256);

    function weeklyProfitOfVP(uint256 vp) external view returns (uint256);

    function weeklyProfitOf(address account) external view returns (uint256);

    function indicativeYearProfit() external view returns (uint256);

    function accuredRebates(
        address account
    ) external view returns (uint256[] memory, address[] memory, uint256[] memory, uint256);

    function claimRebates() external returns (uint256[] memory, address[] memory, uint256[] memory);

    function claimAdminRebates() external returns (uint256[] memory, address[] memory, uint256[] memory);

    function addRebateAmount(address gToken, uint256 uAmount) external;

    function totalClaimedRebates(
        address account
    ) external view returns (uint256[] memory rebates, address[] memory markets, uint256 value);
}


// File contracts/interfaces/IValidator.sol

pragma solidity ^0.6.12;

interface IValidator {
    function redeemAllowed(address gToken, address redeemer, uint256 redeemAmount) external returns (bool);

    function borrowAllowed(address gToken, address borrower, uint256 borrowAmount) external returns (bool);

    function liquidateAllowed(
        address gTokenBorrowed,
        address borrower,
        uint256 repayAmount,
        uint256 closeFactor
    ) external returns (bool);

    function gTokenAmountToSeize(
        address gTokenBorrowed,
        address gTokenCollateral,
        uint256 actualRepayAmount
    ) external returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount);

    function getAccountLiquidity(
        address account
    ) external view returns (uint256 collateralInUSD, uint256 supplyInUSD, uint256 borrowInUSD);

    function getAccountRedeemFeeRate(address account) external view returns (uint256);
}


// File contracts/markets/Market.sol

pragma solidity ^0.6.12;
abstract contract Market is IGToken, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 internal constant RESERVE_FACTOR_MAX = 1e18;
    uint256 internal constant DUST = 1000;

    address internal constant ETH = 0x0000000000000000000000000000000000000000;

    /* ========== STATE VARIABLES ========== */

    ICore public core;
    IRateModel public rateModel;
    IRebateDistributor public rebateDistributor;
    address public override underlying;

    uint256 public override totalSupply; // Total supply of gToken
    uint256 public override totalReserve;
    uint256 public override _totalBorrow;

    mapping(address => uint256) internal accountBalances;
    mapping(address => Constant.BorrowInfo) internal accountBorrows;

    uint256 public override reserveFactor;
    uint256 public override lastAccruedTime;
    uint256 public override accInterestIndex;

    /* ========== VARIABLE GAP ========== */

    uint256[49] private __gap;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    /// @dev Initialization
    function __GMarket_init() internal initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        lastAccruedTime = block.timestamp;
        accInterestIndex = 1e18;
    }

    /* ========== MODIFIERS ========== */

    /// @dev 아직 처리되지 않은 totalBorrow, totalReserve, accInterestIndex 계산 및 저장
    modifier accrue() {
        if (block.timestamp > lastAccruedTime && address(rateModel) != address(0)) {
            uint256 borrowRate = rateModel.getBorrowRate(getCashPrior(), _totalBorrow, totalReserve);
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            _totalBorrow = _totalBorrow.add(pendingInterest);
            totalReserve = totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
            lastAccruedTime = block.timestamp;
        }
        _;
    }

    modifier nftAccrue() {
        if (block.timestamp > lastAccruedTime && address(rateModel) != address(0)) {
            if (underlying == address(ETH)) {
                ILendPoolLoan(INftCore(core.nftCore()).getLendPoolLoan()).accrueInterest();
            }
        }
        _;
    }

    /// @dev msg.sender 가 core address 인지 검증
    modifier onlyCore() {
        require(msg.sender == address(core), "GToken: only Core Contract");
        _;
    }

    modifier onlyRebateDistributor() {
        require(msg.sender == address(rebateDistributor), "GToken: only RebateDistributor");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice core address 를 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    ///      설정 이후에는 다른 주소로 변경할 수 없음
    /// @param _core core contract address
    function setCore(address _core) public onlyOwner {
        require(_core != address(0), "GMarket: invalid core address");
        require(address(core) == address(0), "GMarket: core already set");
        core = ICore(_core);
    }

    /// @notice underlying asset 의 token 설정
    /// @dev ZERO ADDRESS 로 설정할 수 없음
    ///      설정 이후에는 다른 주소로 변경할 수 없음
    /// @param _underlying Underlying token contract address
    function setUnderlying(address _underlying) public onlyOwner {
        require(_underlying != address(0), "GMarket: invalid underlying address");
        require(underlying == address(0), "GMarket: set underlying already");
        underlying = _underlying;
    }

    /// @notice rateModel 설정
    /// @param _rateModel 새로운 RateModel contract address
    function setRateModel(address _rateModel) public accrue onlyOwner {
        require(_rateModel != address(0), "GMarket: invalid rate model address");
        rateModel = IRateModel(_rateModel);
    }

    /// @notice reserve factor 변경
    /// @dev RESERVE_FACTOR_MAX 를 초과할 수 없음
    /// @param _reserveFactor 새로운 reserveFactor 값
    function setReserveFactor(uint256 _reserveFactor) public accrue onlyOwner {
        require(_reserveFactor <= RESERVE_FACTOR_MAX, "GMarket: invalid reserve factor");
        reserveFactor = _reserveFactor;
    }

    function setRebateDistributor(address _rebateDistributor) public onlyOwner {
        require(_rebateDistributor != address(0), "GMarket: invalid rebate distributor address");
        rebateDistributor = IRebateDistributor(_rebateDistributor);
    }

    /* ========== VIEWS ========== */

    /// @notice account 의 gToken 에 대한 balance 조회
    /// @param account account address
    function balanceOf(address account) external view override returns (uint256) {
        return accountBalances[account];
    }

    /// @notice account 의 AccountSnapshot 조회
    /// @param account account address
    function accountSnapshot(address account) external view override returns (Constant.AccountSnapshot memory) {
        Constant.AccountSnapshot memory snapshot;
        snapshot.gTokenBalance = accountBalances[account];
        snapshot.borrowBalance = borrowBalanceOf(account);
        snapshot.exchangeRate = exchangeRate();
        return snapshot;
    }

    /// @notice account 의 supply 된 underlying token 의 amount 조회
    /// @dev 원금에 붙은 이자를 포함
    /// @param account account address
    function underlyingBalanceOf(address account) external view override returns (uint256) {
        return accountBalances[account].mul(exchangeRate()).div(1e18);
    }

    /// @notice 계정의 borrow amount 조회
    /// @dev 원금에 붙은 이자를 포함
    function borrowBalanceOf(address account) public view override returns (uint256) {
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.BorrowInfo storage info = accountBorrows[account];

        if (info.borrow == 0) return 0;
        return info.borrow.mul(snapshot.accInterestIndex).div(info.interestIndex);
    }

    /// @notice totalBorrow 조회
    function totalBorrow() public view override returns (uint256) {
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.totalBorrow;
    }

    /// @notice gToken 과 underlying token 의 교환비율 조회
    /// @dev Exchange rate = (Total pure supplies / Total gToken supplies)
    function exchangeRate() public view override returns (uint256) {
        if (totalSupply == 0) return 1e18;
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return getCashPrior().add(snapshot.totalBorrow).sub(snapshot.totalReserve).mul(1e18).div(totalSupply);
    }

    /// @notice contract 가 가지고 있는 underlying token amount 조회
    /// @dev underlying token 이 ETH 인 경우 msg.value 값을 빼서 계산함
    function getCash() public view override returns (uint256) {
        return getCashPrior();
    }

    function getRateModel() external view override returns (address) {
        return address(rateModel);
    }

    /// @notice accInterestIndex 조회
    function getAccInterestIndex() public view override returns (uint256) {
        Constant.AccrueSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.accInterestIndex;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice View account snapshot after accure mutation
    function accruedAccountSnapshot(
        address account
    ) external override accrue returns (Constant.AccountSnapshot memory) {
        Constant.AccountSnapshot memory snapshot;
        Constant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex != 0) {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
            info.interestIndex = accInterestIndex;
        }

        snapshot.gTokenBalance = accountBalances[account];
        snapshot.borrowBalance = info.borrow;
        snapshot.exchangeRate = exchangeRate();
        return snapshot;
    }

    /// @notice View borrow balance amount after accure mutation
    function accruedBorrowBalanceOf(address account) external override accrue returns (uint256) {
        Constant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex != 0) {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
            info.interestIndex = accInterestIndex;
        }
        return info.borrow;
    }

    /// @notice View total borrow amount after accrue mutation
    function accruedTotalBorrow() external override accrue returns (uint256) {
        return _totalBorrow;
    }

    /// @notice View underlying token exchange rate after accure mutation
    function accruedExchangeRate() external override accrue returns (uint256) {
        return exchangeRate();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice borrow info 업데이트
    /// @dev account 의 accountBorrows 를 변경하고, totalSupply 를 변경함
    /// @param account borrow 하는 address account
    /// @param addAmount 추가되는 borrow amount
    /// @param subAmount 제거되는 borrow amount
    function updateBorrowInfo(address account, uint256 addAmount, uint256 subAmount) internal {
        Constant.BorrowInfo storage info = accountBorrows[account];
        if (info.interestIndex == 0) {
            info.interestIndex = accInterestIndex;
        }

        info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).add(addAmount).sub(subAmount);
        info.interestIndex = accInterestIndex;
        _totalBorrow = _totalBorrow.add(addAmount).sub(subAmount);

        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;
    }

    /// @notice supply info 업데이트
    /// @dev account 의 accountBalances 를 변경하고, totalSupply 를 변경함
    /// @param account supply 하는 address account
    /// @param addAmount 추가되는 supply amount
    /// @param subAmount 제거되는 supply amount
    function updateSupplyInfo(address account, uint256 addAmount, uint256 subAmount) internal {
        accountBalances[account] = accountBalances[account].add(addAmount).sub(subAmount);
        totalSupply = totalSupply.add(addAmount).sub(subAmount);

        totalSupply = (totalSupply < DUST) ? 0 : totalSupply;
    }

    /// @notice contract 가 가지고 있는 underlying token amount 조회
    /// @dev underlying token 이 ETH 인 경우 msg.value 값을 빼서 계산함
    function getCashPrior() internal view returns (uint256) {
        return
            underlying == address(ETH)
                ? address(this).balance.sub(msg.value)
                : IBEP20(underlying).balanceOf(address(this));
    }

    /// @notice totalBorrow, totlaReserver, accInterestIdx 조회
    /// @dev 아직 계산되지 않은 pending interest 더한 값으로 조회
    ///      상태가 변겅되거나 저장되지는 않는다
    function pendingAccrueSnapshot() internal view returns (Constant.AccrueSnapshot memory) {
        Constant.AccrueSnapshot memory snapshot;
        snapshot.totalBorrow = _totalBorrow;
        snapshot.totalReserve = totalReserve;
        snapshot.accInterestIndex = accInterestIndex;

        if (block.timestamp > lastAccruedTime && _totalBorrow > 0) {
            uint256 borrowRate = rateModel.getBorrowRate(getCashPrior(), _totalBorrow, totalReserve);
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            snapshot.totalBorrow = _totalBorrow.add(pendingInterest);
            snapshot.totalReserve = totalReserve.add(pendingInterest.mul(reserveFactor).div(1e18));
            snapshot.accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
        }
        return snapshot;
    }
}


// File contracts/markets/GToken.sol

pragma solidity ^0.6.12;

contract GToken is Market {
    using SafeMath for uint256;
    using SafeToken for address;

    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => mapping(address => uint256)) private _transferAllowances;

    /* ========== EVENT ========== */

    event Mint(address minter, uint256 mintAmount);
    event Redeem(
        address account,
        uint256 underlyingAmount,
        uint256 gTokenAmount,
        uint256 uAmountToReceive,
        uint256 uAmountRedeemFee
    );

    event Borrow(address account, uint256 ammount, uint256 accountBorrow);
    event RepayBorrow(address payer, address borrower, uint256 amount, uint256 accountBorrow);
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 amount,
        address gTokenCollateral,
        uint256 seizeAmount
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /* ========== INITIALIZER ========== */

    /// @notice Initialization
    /// @param _name name
    /// @param _symbol symbol
    /// @param _decimals decimals
    function initialize(string memory _name, string memory _symbol, uint8 _decimals) external initializer {
        __GMarket_init();

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* ========== VIEWS ========== */

    /// @notice View allowance
    /// @param account Account address
    /// @param spender Spender address
    /// @return Allowance amount
    function allowance(address account, address spender) external view override returns (uint256) {
        return _transferAllowances[account][spender];
    }

    /// @notice Owner address 조회
    function getOwner() external view returns (address) {
        return owner();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function transfer(address dst, uint256 amount) external override accrue nonReentrant returns (bool) {
        core.transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external override accrue nonReentrant returns (bool) {
        core.transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    /// @notice account 의 allowance amount 변경
    /// @param spender spender address
    /// @param amount amount
    function approve(address spender, uint256 amount) external override returns (bool) {
        _transferAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Update supply information
    /// @param account Account address to supply
    /// @param uAmount Underlying token amount to supply
    /// @return gAmount gToken amount to receive
    function supply(address account, uint256 uAmount) external payable override accrue onlyCore returns (uint256) {
        uint256 exchangeRate = exchangeRate();
        uAmount = underlying == address(ETH) ? msg.value : uAmount;
        uAmount = _doTransferIn(account, uAmount);
        uint256 gAmount = uAmount.mul(1e18).div(exchangeRate);
        require(gAmount > 0, "GToken: invalid gAmount");
        updateSupplyInfo(account, gAmount, 0);

        emit Mint(account, gAmount);
        emit Transfer(address(0), account, gAmount);
        return gAmount;
    }

    /// @notice Redeem token by gToken amount
    /// @param redeemer Redeemer account address
    /// @param gAmount gToken amount
    function redeemToken(address redeemer, uint256 gAmount) external override accrue nftAccrue onlyCore returns (uint256) {
        return _redeem(redeemer, gAmount, 0);
    }

    /// @notice Redeem token by underlying token amount
    /// @param redeemer Redeemer account address
    /// @param uAmount Underlying token amount
    function redeemUnderlying(address redeemer, uint256 uAmount) external override accrue nftAccrue onlyCore returns (uint256) {
        return _redeem(redeemer, 0, uAmount);
    }

    /// @notice Update borrow information
    /// @param account Borrower account address
    /// @param amount Borrow amount
    function borrow(address account, uint256 amount) external override accrue nftAccrue onlyCore returns (uint256) {
        require(getCash() >= amount, "GToken: borrow amount exceeds cash");
        updateBorrowInfo(account, amount, 0);
        _doTransferOut(account, amount);

        emit Borrow(account, amount, borrowBalanceOf(account));
        return amount;
    }

    /// @notice Repay own borrowing dept
    /// @dev Called when repay my own debt only
    /// @param account Borrower account address
    /// @param amount Repay amount
    function repayBorrow(address account, uint256 amount) external payable override accrue onlyCore returns (uint256) {
        if (amount == uint256(-1)) {
            amount = borrowBalanceOf(account);
        }
        return _repay(account, account, underlying == address(ETH) ? msg.value : amount);
    }

    /// @notice Repay others' debt behalf
    /// @dev Called when repay others' debt behalf
    /// @param payer Account address who pay for the debt
    /// @param borrower Account address who borrowing debt
    /// @param amount Dept amount to repay
    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint256 amount
    ) external payable override accrue onlyCore returns (uint256) {
        return _repay(payer, borrower, underlying == address(ETH) ? msg.value : amount);
    }

    /// @notice Force to liquidate others debt
    /// @param gTokenCollateral gToken address provided as collateral
    /// @param liquidator Liquidator account address
    /// @param borrower Borrower account address
    /// @param amount Collateral amount
    function liquidateBorrow(
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint256 amount
    )
        external
        payable
        override
        accrue
        onlyCore
        returns (uint256 seizeGAmount, uint256 rebateGAmount, uint256 liquidatorGAmount)
    {
        require(borrower != liquidator, "GToken: cannot liquidate yourself");
        amount = underlying == address(ETH) ? msg.value : amount;
        amount = _repay(liquidator, borrower, amount);
        require(amount > 0 && amount < uint256(-1), "GToken: invalid repay amount");

        (seizeGAmount, rebateGAmount, liquidatorGAmount) = IValidator(core.validator()).gTokenAmountToSeize(
            address(this),
            gTokenCollateral,
            amount
        );

        require(
            IGToken(payable(gTokenCollateral)).balanceOf(borrower) >= seizeGAmount,
            "GToken: too much seize amount"
        );

        emit LiquidateBorrow(liquidator, borrower, amount, gTokenCollateral, seizeGAmount);
    }

    function seize(
        address liquidator,
        address borrower,
        uint256 gAmount
    ) external override accrue onlyCore nonReentrant {
        accountBalances[borrower] = accountBalances[borrower].sub(gAmount);
        accountBalances[liquidator] = accountBalances[liquidator].add(gAmount);

        emit Transfer(borrower, liquidator, gAmount);
    }

    function withdrawReserves() external override accrue onlyRebateDistributor nonReentrant {
        if (getCash() >= totalReserve) {
            uint256 amount = totalReserve;

            if (totalReserve > 0) {
                totalReserve = 0;
                _doTransferOut(address(rebateDistributor), amount);
            }
        }
    }

    /// @notice Transfer interneal
    /// @param spender Spender account address
    /// @param src Source account address
    /// @param dst Destination account address
    /// @param amount Transfer amount
    function transferTokensInternal(
        address spender,
        address src,
        address dst,
        uint256 amount
    ) external override onlyCore {
        require(
            src != dst && IValidator(core.validator()).redeemAllowed(address(this), src, amount),
            "GToken: cannot transfer"
        );
        require(amount != 0, "GToken: zero amount");
        uint256 _allowance = spender == src ? uint256(-1) : _transferAllowances[src][spender];
        uint256 _allowanceNew = _allowance.sub(amount, "GToken: transfer amount exceeds allowance");

        accountBalances[src] = accountBalances[src].sub(amount);
        accountBalances[dst] = accountBalances[dst].add(amount);

        if (_allowance != uint256(-1)) {
            _transferAllowances[src][spender] = _allowanceNew;
        }
        emit Transfer(src, dst, amount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @notice Transfer in underlying token
    /// @param from Transfer from address
    /// @param amount Transfer amount
    /// @return Transfered amount
    function _doTransferIn(address from, uint256 amount) private returns (uint256) {
        if (underlying == address(ETH)) {
            require(msg.value >= amount, "GToken: value mismatch");
            return Math.min(msg.value, amount);
        } else {
            uint256 balanceBefore = IBEP20(underlying).balanceOf(address(this));
            underlying.safeTransferFrom(from, address(this), amount);
            uint256 balanceAfter = IBEP20(underlying).balanceOf(address(this));
            require(balanceAfter.sub(balanceBefore) <= amount);
            return balanceAfter.sub(balanceBefore);
        }
    }

    /// @notice Transfer out underlying token
    /// @param to Transfer target add
    /// @param amount Transfer amount
    function _doTransferOut(address to, uint256 amount) private {
        if (underlying == address(ETH)) {
            SafeToken.safeTransferETH(to, amount);
        } else {
            underlying.safeTransfer(to, amount);
        }
    }

    /// @notice Redeem underlying token
    /// @dev Use only one of the amount params (gAmountIn or uAmountIn)
    ///      Pass unused parameter to 0
    /// @param account Redeemer account
    /// @param gAmountIn Redeem amount calculated by gToken amount
    /// @param uAmountIn Redeem amount
    function _redeem(address account, uint256 gAmountIn, uint256 uAmountIn) private returns (uint256) {
        require(gAmountIn == 0 || uAmountIn == 0, "GToken: one of gAmountIn or uAmountIn must be zero");
        require(totalSupply >= gAmountIn, "GToken: not enough total supply");
        require(getCash() >= uAmountIn || uAmountIn == 0, "GToken: not enough underlying");
        require(
            getCash() >= gAmountIn.mul(exchangeRate()).div(1e18) || gAmountIn == 0,
            "GToken: not enough underlying"
        );

        IValidator validator = IValidator(core.validator());
        uint256 gAmountToRedeem = gAmountIn > 0 ? gAmountIn : uAmountIn.mul(1e18).div(exchangeRate());
        uint256 uAmountToRedeem = gAmountIn > 0 ? gAmountIn.mul(exchangeRate()).div(1e18) : uAmountIn;

        require(validator.redeemAllowed(address(this), account, gAmountToRedeem), "GToken: cannot redeem");

        uint256 redeemFeeRate = validator.getAccountRedeemFeeRate(account);
        uint256 uAmountRedeemFee = uAmountToRedeem.mul(redeemFeeRate).div(1e4);
        uint256 uAmountToReceive = uAmountToRedeem.sub(uAmountRedeemFee);

        updateSupplyInfo(account, 0, gAmountToRedeem);
        _doTransferOut(account, uAmountToReceive);
        _doTransferOut(core.rebateDistributor(), uAmountRedeemFee);

        emit Transfer(account, address(0), gAmountToRedeem);
        emit Redeem(account, uAmountToRedeem, gAmountToRedeem, uAmountToReceive, uAmountRedeemFee);
        return uAmountToRedeem;
    }

    /// @notice Repay borrowing debt and update borrow information
    /// @param payer Payer account address
    /// @param borrower Borrower account address
    function _repay(address payer, address borrower, uint256 amount) private returns (uint256) {
        uint256 borrowBalance = borrowBalanceOf(borrower);
        uint256 repayAmount = Math.min(borrowBalance, amount);
        repayAmount = _doTransferIn(payer, repayAmount);
        updateBorrowInfo(borrower, 0, repayAmount);

        if (underlying == address(ETH)) {
            uint256 refundAmount = amount > repayAmount ? amount.sub(repayAmount) : 0;
            if (refundAmount > 0) {
                _doTransferOut(payer, refundAmount);
            }
        }

        emit RepayBorrow(payer, borrower, repayAmount, borrowBalanceOf(borrower));
        return repayAmount;
    }
}