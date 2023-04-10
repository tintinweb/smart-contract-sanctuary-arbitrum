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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/introspection/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

pragma solidity >=0.6.2 <0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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


// File contracts/interfaces/IGNft.sol

pragma solidity ^0.6.12;

interface IGNft {
    /* ========== Event ========== */
    event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);
    event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);


    function underlying() external view returns (address);
    function minterOf(uint256 tokenId) external view returns (address);

    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
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


// File contracts/interfaces/INFTOracle.sol

pragma solidity ^0.6.12;

interface INFTOracle {
    struct NFTPriceData {
        uint256 price;
        uint256 timestamp;
        uint256 roundId;
    }

    struct NFTPriceFeed {
        bool registered;
        NFTPriceData[] nftPriceData;
    }

    /* ========== Event ========== */

    event KeeperUpdated(address indexed newKeeper);
    event AssetAdded(address indexed asset);
    event AssetRemoved(address indexed asset);

    event SetAssetData(address indexed asset, uint256 price, uint256 timestamp, uint256 roundId);
    event SetAssetTwapPrice(address indexed asset, uint256 price, uint256 timestamp);

    function getAssetPrice(address _nftContract) external view returns (uint256);
    function getLatestRoundId(address _nftContract) external view returns (uint256);
    function getUnderlyingPrice(address _gNft) external view returns (uint256);
}


// File contracts/interfaces/INftValidator.sol

pragma solidity ^0.6.12;

interface INftValidator {
    function validateBorrow(
        address user,
        uint256 amount,
        address gNft,
        uint256 loanId
    ) external view;

    function validateRepay(
        uint256 loanId,
        uint256 repayAmount,
        uint256 borrowAmount
    ) external view;

    function validateAuction(
        address gNft,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external view;

    function validateRedeem(
        uint256 loanId,
        uint256 repayAmount,
        uint256 bidFine,
        uint256 borrowAmount
    ) external view returns (uint256);

    function validateLiquidate(
        uint256 loanId,
        uint256 borrowAmount,
        uint256 amount
    ) external view returns (uint256, uint256);
}


// File contracts/library/NftValidator.sol

pragma solidity ^0.6.12;

contract NftValidator is INftValidator, OwnableUpgradeable {
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    /* ========== STATE VARIABLES ========== */

    INFTOracle public nftOracle;
    INftCore public nftCore;
    ILendPoolLoan public lendPoolLoan;

    /* ========== INITIALIZER ========== */

    function initialize(address _nftOracle, address _nftCore, address _lendPoolLoan) external initializer {
        __Ownable_init();

        nftOracle = INFTOracle(_nftOracle);
        nftCore = INftCore(_nftCore);
        lendPoolLoan = ILendPoolLoan(_lendPoolLoan);
    }

    /* ========== VIEWS ========== */

    function validateBorrow(
        address user,
        uint256 amount,
        address gNft,
        uint256 loanId
    ) external view override {
        require(gNft != address(0), "NftValidator: invalid gNft address");
        require(amount > 0, "NftValidator: invalid amount");

        Constant.NftMarketInfo memory marketInfo = nftCore.marketInfoOf(gNft);

        uint256 collateralAmount = lendPoolLoan.getNftCollateralAmount(IGNft(gNft).underlying());
        require(marketInfo.supplyCap == 0 || collateralAmount < marketInfo.supplyCap, "NftValidator: supply cap reached");

        if (marketInfo.borrowCap != 0) {
            uint256 marketBorrows = lendPoolLoan.marketBorrowBalance(gNft);
            uint256 nextMarketBorrows = marketBorrows.add(amount);
            require(nextMarketBorrows < marketInfo.borrowCap, "NftValidator: borrow cap reached");
        }

        if (loanId != 0) {
            Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
            require(loanData.state == Constant.LoanState.Active, "NftValidator: invalid loan state");
            require(user == loanData.borrower, "NftValidator: invalid borrower");
        }

        (uint256 userCollateralBalance, uint256 userBorrowBalance, uint256 healthFactor) = _calculateLoanData(
            gNft,
            loanId,
            marketInfo.liquidationThreshold
        );

        require(userCollateralBalance > 0, "NftValidator: collateral balance is zero");
        require(healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD, "NftValidator: health factor lower than liquidation threshold");

        uint256 amountOfCollateralNeeded = userBorrowBalance.add(amount);
        userCollateralBalance = userCollateralBalance.mul(marketInfo.collateralFactor).div(1e18);

        require(amountOfCollateralNeeded <= userCollateralBalance, "NftValidator: Collateral cannot cover new borrow");
    }

    function validateRepay(
        uint256 loanId,
        uint256 repayAmount,
        uint256 borrowAmount
    ) external view override {
        require(repayAmount > 0, "NftValidator: invalid repay amount");
        require(borrowAmount > 0, "NftValidator: invalid borrow amount");

        Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
        require(loanData.state == Constant.LoanState.Active, "NftValidator: invalid loan state");
    }

    function validateAuction(
        address gNft,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external view override {
        Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
        require(loanData.state == Constant.LoanState.Active || loanData.state == Constant.LoanState.Auction,
                "NftValidator: invalid loan state");

        require(bidPrice > 0, "NftValidator: invalid bid price");
        require(borrowAmount > 0, "NftValidator: invalid borrow amount");

        (uint256 thresholdPrice, uint256 liquidatePrice) = _calculateLoanLiquidatePrice(
            gNft,
            borrowAmount
        );

        if (loanData.state == Constant.LoanState.Active) {
            // Loan accumulated debt must exceed threshold (health factor below 1.0)
            require(borrowAmount > thresholdPrice, "NftValidator: borrow not exceed liquidation threshold");

            // bid price must greater than borrow debt
            require(bidPrice >= borrowAmount, "NftValidator: bid price less than borrow debt");

            // bid price must greater than liquidate price
            require(bidPrice >= liquidatePrice, "NftValidator: bid price less than liquidate price");
        } else {
            // bid price must greater than borrow debt
            require(bidPrice >= borrowAmount, "NftValidator: bid price less than borrow debt");

            uint256 auctionEndTimestamp = loanData.bidStartTimestamp.add(lendPoolLoan.auctionDuration());
            require(block.timestamp <= auctionEndTimestamp, "NftValidator: bid auction duration has ended");

            // bid price must greater than highest bid + delta
            uint256 bidDelta = borrowAmount.mul(1e16).div(1e18); // 1%
            require(bidPrice >= loanData.bidPrice.add(bidDelta), "NftValidator: bid price less than highest price");
        }
    }

    function validateRedeem(
        uint256 loanId,
        uint256 repayAmount,
        uint256 bidFine,
        uint256 borrowAmount
    ) external view override returns (uint256) {
        Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
        require(loanData.state == Constant.LoanState.Auction, "NftValidator: invalid loan state");
        require(loanData.bidderAddress != address(0), "NftValidator: invalid bidder address");

        require(repayAmount > 0, "NftValidator: invalid repay amount");

        uint256 redeemEndTimestamp = loanData.bidStartTimestamp.add(lendPoolLoan.auctionDuration());
        require(block.timestamp <= redeemEndTimestamp, "NftValidator: redeem duration has ended");

        uint256 _bidFine = _calculateLoanBidFine(loanData, borrowAmount);
        require(bidFine >= _bidFine, "NftValidator: invalid bid fine");

        uint256 _minRepayAmount = borrowAmount.mul(lendPoolLoan.redeemThreshold()).div(1e18);
        require(repayAmount >= _minRepayAmount, "NftValidator: repay amount less than redeem threshold");

        uint256 _maxRepayAmount = borrowAmount.mul(9e17).div(1e18);
        require(repayAmount <= _maxRepayAmount, "NftValidator: repay amount greater than max repay");

        return _bidFine;
    }

    function validateLiquidate(
        uint256 loanId,
        uint256 borrowAmount,
        uint256 amount
    ) external view override returns (uint256, uint256) {
        Constant.LoanData memory loanData = lendPoolLoan.getLoan(loanId);
        require(loanData.state == Constant.LoanState.Auction, "NftValidator: invalid loan state");
        require(loanData.bidderAddress != address(0), "NftValidator: invalid bidder address");

        uint256 auctionEndTimestamp = loanData.bidStartTimestamp.add(lendPoolLoan.auctionDuration());
        require(block.timestamp > auctionEndTimestamp, "NftValidator: auction duration not end");

        // Last bid price can not cover borrow amount
        uint256 extraDebtAmount = 0;
        if (loanData.bidPrice < borrowAmount) {
            extraDebtAmount = borrowAmount.sub(loanData.bidPrice);
            require(amount >= extraDebtAmount, "NftValidator: amount less than extra debt amount");
        }

        uint256 remainAmount = 0;
        if (loanData.bidPrice > borrowAmount) {
            remainAmount = loanData.bidPrice.sub(borrowAmount);
        }

        return (extraDebtAmount, remainAmount);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _calculateLoanBidFine(
        Constant.LoanData memory loanData,
        uint256 borrowAmount
    ) internal view returns (uint256) {
        if (loanData.bidPrice == 0) {
            return 0;
        }

        uint256 minBidFine = lendPoolLoan.minBidFine();
        uint256 bidFineAmount = borrowAmount.mul(lendPoolLoan.redeemFineRate()).div(1e18);

        if (bidFineAmount < minBidFine) {
            bidFineAmount = minBidFine;
        }

        return bidFineAmount;
    }

    function _calculateLoanData(
        address gNft,
        uint256 loanId,
        uint256 liquidationThreshold
    ) internal view returns (uint256, uint256, uint256) {
        uint256 totalDebtInETH = 0;

        if (loanId != 0) {
            totalDebtInETH = lendPoolLoan.borrowBalanceOf(loanId);
        }

        uint256 totalCollateralInETH = nftOracle.getUnderlyingPrice(gNft);
        uint256 healthFactor = _calculateHealthFactorFromBalances(totalCollateralInETH, totalDebtInETH, liquidationThreshold);

        return (totalCollateralInETH, totalDebtInETH, healthFactor);
    }

    /*
     * 0                   CR                  LH                  100
     * |___________________|___________________|___________________|
     *  <       Borrowing with Interest        <
     * CR: Callteral Ratio;
     * LH: Liquidate Threshold;
     * Liquidate Trigger: Borrowing with Interest > thresholdPrice;
     * Liquidate Price: (100% - BonusRatio) * NFT Price;
     */
    function _calculateLoanLiquidatePrice(
        address gNft,
        uint256 borrowAmount
    ) internal view returns (uint256, uint256) {
        uint256 liquidationThreshold = nftCore.marketInfoOf(gNft).liquidationThreshold;
        uint256 liquidationBonus = nftCore.marketInfoOf(gNft).liquidationBonus;

        uint256 nftPriceInETH = nftOracle.getUnderlyingPrice(gNft);
        uint256 thresholdPrice = nftPriceInETH.mul(liquidationThreshold).div(1e18);

        uint256 bonusAmount = nftPriceInETH.mul(liquidationBonus).div(1e18);
        uint256 liquidatePrice = nftPriceInETH.sub(bonusAmount);

        if (liquidatePrice < borrowAmount) {
            uint256 bidDelta = borrowAmount.mul(1e16).div(1e18); // 1%
            liquidatePrice = borrowAmount.add(bidDelta);
        }

        return (thresholdPrice, liquidatePrice);
    }

    function _calculateHealthFactorFromBalances(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 liquidationThreshold
    ) public pure returns (uint256) {
        if (totalDebt == 0) {
            return uint256(-1);
        }
        return (totalCollateral.mul(liquidationThreshold).mul(1e18).div(totalDebt).div(1e18));
    }
}