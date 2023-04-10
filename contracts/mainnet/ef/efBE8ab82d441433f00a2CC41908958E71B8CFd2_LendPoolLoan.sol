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


// File @openzeppelin/contracts-upgradeable/math/[email protected]

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
library SafeMathUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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


// File contracts/nftlend/LendPoolLoan.sol

pragma solidity ^0.6.12;

contract LendPoolLoan is ILendPoolLoan, OwnableUpgradeable, IERC721ReceiverUpgradeable {
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 internal constant DUST = 1000;

    /* ========== STATE VARIABLES ========== */

    INftCore public nftCore;
    ICore public core;
    IGToken public borrowMarket;

    CountersUpgradeable.Counter private _loanIdTracker;
    mapping(uint256 => Constant.LoanData) private _loans;
    mapping(address => Constant.BorrowInfo) private _accountBorrows;
    mapping(address => Constant.BorrowInfo) private _marketBorrows;
    mapping(address => mapping(address => Constant.BorrowInfo)) private _marketAccountBorrows;

    uint256 public _totalBorrow;
    uint256 public lastAccruedTime;
    uint256 public override accInterestIndex;
    uint256 public borrowRateMultiplier;

    uint256 public override auctionDuration;
    uint256 public override minBidFine;
    uint256 public override redeemFineRate;
    uint256 public override redeemThreshold;
    uint256 public override auctionFeeRate;

    // nftAsset + nftTokenId => loanId
    mapping(address => mapping(uint256 => uint256)) private _nftToLoanIds;
    mapping(address => uint256) private _nftTotalCollateral;
    mapping(address => mapping(address => uint256)) private _userNftCollateral;

    /* ========== INITIALIZER ========== */

    function initialize(
        INftCore _nftCore,
        ICore _core,
        IGToken _borrowMarket,
        uint256 _auctionDuration,
        uint256 _minBidFine,
        uint256 _redeemFineRate,
        uint256 _redeemThreshold,
        uint256 _borrowRateMultiplier,
        uint256 _auctionFeeRate
    ) external initializer {
        __Ownable_init();

        nftCore = _nftCore;
        core = _core;
        borrowMarket = _borrowMarket;

        auctionDuration = _auctionDuration;
        minBidFine = _minBidFine;
        redeemFineRate = _redeemFineRate;
        redeemThreshold = _redeemThreshold;
        borrowRateMultiplier = _borrowRateMultiplier;

        auctionFeeRate = _auctionFeeRate;

        // Avoid having loanId = 0
        _loanIdTracker.increment();

        lastAccruedTime = block.timestamp;
        accInterestIndex = 1e18;
    }

    /* ========== MODIFIERS ========== */

    modifier accrue() {
        if (block.timestamp > lastAccruedTime && borrowMarket.getRateModel() != address(0)) {
            uint256 borrowRate = getBorrowRate();
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            _totalBorrow = _totalBorrow.add(pendingInterest);
            accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
            lastAccruedTime = block.timestamp;
        }
        _;
    }

    modifier onlyNftCore() {
        require(msg.sender == address(nftCore), "LendPoolLoan: caller should be nft core");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function initNft(address nftAsset, address gNft) external override onlyNftCore {
        IERC721Upgradeable(nftAsset).setApprovalForAll(gNft, true);
    }

    function setAuctionDuration(uint256 _auctionDuration) external onlyOwner {
        require(_auctionDuration <= Constant.AUCTION_DURATION_MAX, "LendPoolLoan: invalid auction duration");
        auctionDuration = _auctionDuration;
        emit AuctionDurationUpdated(_auctionDuration);
    }

    function setMinBidFine(uint256 _minBidFine) external onlyOwner {
        require(_minBidFine <= Constant.MIN_BID_FINE_MAX, "LendPoolLoan: invalid min bid fine");
        minBidFine = _minBidFine;
        emit MinBidFineUpdated(_minBidFine);
    }

    function setRedeemFineRate(uint256 _redeemFineRate) external onlyOwner {
        require(_redeemFineRate <= Constant.REDEEM_FINE_RATE_MAX, "LendPoolLoan: invalid redeem fine ratio");
        redeemFineRate = _redeemFineRate;
        emit RedeemFineRateUpdated(_redeemFineRate);
    }

    function setRedeemThreshold(uint256 _redeemThreshold) external onlyOwner {
        require(_redeemThreshold <= Constant.REDEEM_THRESHOLD_MAX, "LendPoolLoan: invalid redeem threshold");
        redeemThreshold = _redeemThreshold;
        emit RedeemThresholdUpdated(_redeemThreshold);
    }

    function setBorrowRateMultiplier(uint256 _borrowRateMultiplier) external onlyOwner {
        require(_borrowRateMultiplier <= Constant.BORROW_RATE_MULTIPLIER_MAX, "LendPoolLoan: invalid borrow rate multiplier");
        borrowRateMultiplier = _borrowRateMultiplier;
        emit BorrowRateMultiplierUpdated(_borrowRateMultiplier);
    }

    function setAuctionFeeRate(uint256 _auctionFeeRate) external onlyOwner {
        require(_auctionFeeRate <= Constant.AUCTION_FEE_RATE_MAX, "LendPoolLoan: invalid auction fee rate");
        auctionFeeRate = _auctionFeeRate;
        emit AuctionFeeRateUpdated(_auctionFeeRate);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createLoan(
        address to,
        address nftAsset,
        uint256 nftTokenId,
        address gNft,
        uint256 amount
    ) external override onlyNftCore accrue returns (uint256) {
        require(_nftToLoanIds[nftAsset][nftTokenId] == 0, "LendPoolLoan: nft already used as collateral");

        uint256 loanId = _loanIdTracker.current();
        _loanIdTracker.increment();
        _nftToLoanIds[nftAsset][nftTokenId] = loanId;

        IERC721Upgradeable(nftAsset).safeTransferFrom(msg.sender, address(this), nftTokenId);

        IGNft(gNft).mint(to, nftTokenId);

        Constant.LoanData storage loanData = _loans[loanId];
        loanData.loanId = loanId;
        loanData.state = Constant.LoanState.Active;
        loanData.borrower = to;
        loanData.gNft = gNft;
        loanData.nftAsset = nftAsset;
        loanData.nftTokenId = nftTokenId;
        loanData.borrowAmount = amount;
        loanData.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage info = _accountBorrows[to];
        if (info.borrow == 0) {
            info.borrow = amount;
            info.interestIndex = accInterestIndex;
        } else {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).add(amount);
            info.interestIndex = accInterestIndex;
        }

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[gNft];
        if (marketBorrowInfo.borrow == 0) {
            marketBorrowInfo.borrow = amount;
            marketBorrowInfo.interestIndex = accInterestIndex;
        } else {
            marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex).add(amount);
            marketBorrowInfo.interestIndex = accInterestIndex;
        }

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[gNft][to];
        if (marketAccountBorrowInfo.borrow == 0) {
            marketAccountBorrowInfo.borrow = amount;
            marketAccountBorrowInfo.interestIndex = accInterestIndex;
        } else {
            marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex).add(amount);
            marketAccountBorrowInfo.interestIndex = accInterestIndex;
        }

        _totalBorrow = _totalBorrow.add(amount);

        _userNftCollateral[to][nftAsset] = _userNftCollateral[to][nftAsset].add(1);
        _nftTotalCollateral[nftAsset] = _nftTotalCollateral[nftAsset].add(1);

        emit LoanCreated(to, loanId, nftAsset, nftTokenId, gNft, amount);
        return (loanId);
    }

    function updateLoan(
        uint256 loanId,
        uint256 amountAdded,
        uint256 amountTaken
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        require(loan.state == Constant.LoanState.Active, "LendPoolLoan: invalid loan state");

        if (loan.interestIndex == 0) {
            loan.interestIndex = accInterestIndex;
        }

        loan.borrowAmount = loan.borrowAmount.mul(accInterestIndex).div(loan.interestIndex).add(amountAdded).sub(amountTaken);
        loan.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage info = _accountBorrows[loan.borrower];
        info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).add(amountAdded).sub(amountTaken);
        info.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[loan.gNft];
        marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex).add(amountAdded).sub(amountTaken);
        marketBorrowInfo.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[loan.gNft][loan.borrower];
        marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex).add(amountAdded).sub(amountTaken);
        marketAccountBorrowInfo.interestIndex = accInterestIndex;

        _totalBorrow = _totalBorrow.add(amountAdded).sub(amountTaken);

        loan.borrowAmount = (loan.borrowAmount < DUST) ? 0 : loan.borrowAmount;
        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        marketBorrowInfo.borrow = (marketBorrowInfo.borrow < DUST) ? 0 : marketBorrowInfo.borrow;
        marketAccountBorrowInfo.borrow = (marketAccountBorrowInfo.borrow < DUST) ? 0 : marketAccountBorrowInfo.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;

        emit LoanUpdated(loan.borrower, loanId, loan.nftAsset, loan.nftTokenId, amountAdded, amountTaken);
    }

    function repayLoan(
        uint256 loanId,
        address gNft,
        uint256 amount
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        require(loan.state == Constant.LoanState.Active, "LendPoolLoan: invalid loan state");

        loan.state = Constant.LoanState.Repaid;
        loan.borrowAmount = 0;

        Constant.BorrowInfo storage info = _accountBorrows[loan.borrower];
        if (info.borrow.mul(accInterestIndex).div(info.interestIndex) < amount) {
            info.borrow = 0;
        } else {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).sub(amount);
        }
        info.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[loan.gNft][loan.borrower];
        if (marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex) < amount) {
            marketAccountBorrowInfo.borrow = 0;
        } else {
            marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex).sub(amount);
        }
        marketAccountBorrowInfo.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[loan.gNft];
        if (marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex) < amount) {
            marketBorrowInfo.borrow = 0;
        } else {
            marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex).sub(amount);
        }
        marketBorrowInfo.interestIndex = accInterestIndex;

        if (_totalBorrow < amount) {
            _totalBorrow = 0;
        } else {
            _totalBorrow = _totalBorrow.sub(amount);
        }

        loan.borrowAmount = (loan.borrowAmount < DUST) ? 0 : loan.borrowAmount;
        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        marketBorrowInfo.borrow = (marketBorrowInfo.borrow < DUST) ? 0 : marketBorrowInfo.borrow;
        marketAccountBorrowInfo.borrow = (marketAccountBorrowInfo.borrow < DUST) ? 0 : marketAccountBorrowInfo.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;

        _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

        require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, "LendPoolLoan: invalid user nft amount");
        _userNftCollateral[loan.borrower][loan.nftAsset] = _userNftCollateral[loan.borrower][loan.nftAsset].sub(1);

        require(_nftTotalCollateral[loan.nftAsset] >= 1, "LendPoolLoan: invalid nft amount");
        _nftTotalCollateral[loan.nftAsset] = _nftTotalCollateral[loan.nftAsset].sub(1);

        IGNft(gNft).burn(loan.nftTokenId);
        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), msg.sender, loan.nftTokenId);

        emit LoanRepaid(loan.borrower, loanId, loan.nftAsset, loan.nftTokenId, amount);
    }

    function auctionLoan(
        address bidder,
        uint256 loanId,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        address previousBidder = loan.bidderAddress;
        uint256 previousPrice = loan.bidPrice;

        if (loan.bidStartTimestamp == 0) {
            require(loan.state == Constant.LoanState.Active, "LendPoolLoan: invalid loan state");
            loan.state = Constant.LoanState.Auction;
            loan.bidStartTimestamp = block.timestamp;
            loan.firstBidderAddress = bidder;
            loan.floorPrice = INFTOracle(nftCore.getNftOracle()).getUnderlyingPrice(loan.gNft);
        } else {
            require(loan.state == Constant.LoanState.Auction, "LendPoolLoan: invalid loan state");
            require(bidPrice > loan.bidPrice, "LendPoolLoan: bid price less than highest price");
        }

        loan.bidBorrowAmount = borrowAmount;
        loan.bidderAddress = bidder;
        loan.bidPrice = bidPrice;
        loan.bidCount = loan.bidCount.add(1);

        emit LoanAuctioned(
            bidder,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            loan.bidBorrowAmount,
            bidder,
            bidPrice,
            previousBidder,
            previousPrice,
            loan.floorPrice
        );
    }

    function redeemLoan(
        uint256 loanId,
        uint256 amountTaken
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        require(loan.state == Constant.LoanState.Auction, "LendPoolLoan: invalid loan state");
        require(amountTaken > 0, "LendPoolLoan: invalid taken amount");

        loan.borrowAmount = loan.borrowAmount.mul(accInterestIndex).div(loan.interestIndex);
        require(loan.borrowAmount >= amountTaken, "LendPoolLoan: amount underflow");
        loan.borrowAmount = loan.borrowAmount.sub(amountTaken);
        loan.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage info = _accountBorrows[loan.borrower];
        info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex);
        require(info.borrow >= amountTaken, "LendPoolLoan: amount underflow");
        info.borrow = info.borrow.sub(amountTaken);
        info.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[loan.gNft];
        marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex);
        require(marketBorrowInfo.borrow >= amountTaken, "LendPoolLoan: amount underflow");
        marketBorrowInfo.borrow = marketBorrowInfo.borrow.sub(amountTaken);
        marketBorrowInfo.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[loan.gNft][loan.borrower];
        marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex);
        require(marketAccountBorrowInfo.borrow >= amountTaken, "LendPoolLoan: amount underflow");
        marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.sub(amountTaken);
        marketAccountBorrowInfo.interestIndex = accInterestIndex;

        _totalBorrow = _totalBorrow.sub(amountTaken);

        loan.borrowAmount = (loan.borrowAmount < DUST) ? 0 : loan.borrowAmount;
        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        marketBorrowInfo.borrow = (marketBorrowInfo.borrow < DUST) ? 0 : marketBorrowInfo.borrow;
        marketAccountBorrowInfo.borrow = (marketAccountBorrowInfo.borrow < DUST) ? 0 : marketAccountBorrowInfo.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;

        loan.state = Constant.LoanState.Active;
        loan.bidStartTimestamp = 0;
        loan.bidBorrowAmount = 0;
        loan.bidderAddress = address(0);
        loan.bidPrice = 0;
        loan.firstBidderAddress = address(0);
        loan.floorPrice = 0;
        loan.bidCount = 0;

        emit LoanRedeemed(
            loan.borrower,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            amountTaken
        );
    }

    function liquidateLoan(
        address gNft,
        uint256 loanId,
        uint256 borrowAmount
    ) external override onlyNftCore accrue {
        Constant.LoanData storage loan = _loans[loanId];
        require(loan.state == Constant.LoanState.Auction, "LendPoolLoan: invalid loan state");

        loan.state = Constant.LoanState.Defaulted;
        loan.borrowAmount = 0;
        loan.bidBorrowAmount = borrowAmount;

        Constant.BorrowInfo storage info = _accountBorrows[loan.borrower];
        if (info.borrow.mul(accInterestIndex).div(info.interestIndex) < borrowAmount) {
            info.borrow = 0;
        } else {
            info.borrow = info.borrow.mul(accInterestIndex).div(info.interestIndex).sub(borrowAmount);
        }
        info.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketBorrowInfo = _marketBorrows[loan.gNft];
        if (marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex) < borrowAmount) {
            marketBorrowInfo.borrow = 0;
        } else {
            marketBorrowInfo.borrow = marketBorrowInfo.borrow.mul(accInterestIndex).div(marketBorrowInfo.interestIndex).sub(borrowAmount);
        }
        marketBorrowInfo.interestIndex = accInterestIndex;

        Constant.BorrowInfo storage marketAccountBorrowInfo = _marketAccountBorrows[loan.gNft][loan.borrower];
        if (marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex) < borrowAmount) {
            marketAccountBorrowInfo.borrow = 0;
        } else {
            marketAccountBorrowInfo.borrow = marketAccountBorrowInfo.borrow.mul(accInterestIndex).div(marketAccountBorrowInfo.interestIndex).sub(borrowAmount);
        }
        marketAccountBorrowInfo.interestIndex = accInterestIndex;

        if (_totalBorrow < borrowAmount) {
            _totalBorrow = 0;
        } else {
            _totalBorrow = _totalBorrow.sub(borrowAmount);
        }

        info.borrow = (info.borrow < DUST) ? 0 : info.borrow;
        marketBorrowInfo.borrow = (marketBorrowInfo.borrow < DUST) ? 0 : marketBorrowInfo.borrow;
        marketAccountBorrowInfo.borrow = (marketAccountBorrowInfo.borrow < DUST) ? 0 : marketAccountBorrowInfo.borrow;
        _totalBorrow = (_totalBorrow < DUST) ? 0 : _totalBorrow;

        _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

        require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, "LendPoolLoan: invalid user nft amount");
        _userNftCollateral[loan.borrower][loan.nftAsset] = _userNftCollateral[loan.borrower][loan.nftAsset].sub(1);

        require(_nftTotalCollateral[loan.nftAsset] >= 1, "LendPoolLoan: invalid nft amount");
        _nftTotalCollateral[loan.nftAsset] = _nftTotalCollateral[loan.nftAsset].sub(1);

        IGNft(gNft).burn(loan.nftTokenId);
        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), msg.sender, loan.nftTokenId);

        emit LoanLiquidated(
            loan.borrower,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            borrowAmount
        );
    }

    function accrueInterest() external override accrue {}

    /* ========== VIEWS ========== */

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view override returns (uint256) {
        return _nftToLoanIds[nftAsset][nftTokenId];
    }

    function getNftCollateralAmount(address nftAsset) external view override returns (uint256) {
        return _nftTotalCollateral[nftAsset];
    }

    function getUserNftCollateralAmount(address user, address nftAsset) external view override returns (uint256) {
        return _userNftCollateral[user][nftAsset];
    }

    function borrowBalanceOf(uint256 loanId) public view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.LoanData storage loan = _loans[loanId];

        if (loan.borrowAmount == 0) return 0;
        return loan.borrowAmount.mul(snapshot.accInterestIndex).div(loan.interestIndex);
    }

    function totalBorrow() public view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.totalBorrow;
    }

    function userBorrowBalance(address user) external view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.BorrowInfo memory info = _accountBorrows[user];

        if (info.borrow == 0) return 0;
        return info.borrow.mul(snapshot.accInterestIndex).div(info.interestIndex);
    }

    function marketBorrowBalance(address gNft) external view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.BorrowInfo memory marketBorrowInfo = _marketBorrows[gNft];

        if (marketBorrowInfo.borrow == 0) return 0;
        return marketBorrowInfo.borrow.mul(snapshot.accInterestIndex).div(marketBorrowInfo.interestIndex);
    }

    function marketAccountBorrowBalance(address gNft, address user) external view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        Constant.BorrowInfo memory marketAccountBorrowInfo = _marketAccountBorrows[gNft][user];

        if (marketAccountBorrowInfo.borrow == 0) return 0;
        return marketAccountBorrowInfo.borrow.mul(snapshot.accInterestIndex).div(marketAccountBorrowInfo.interestIndex);
    }

    function getLoan(uint256 loanId) external view override returns (Constant.LoanData memory loanData) {
        return _loans[loanId];
    }

    function pendingAccrueSnapshot() internal view returns (Constant.AccrueLoanSnapshot memory) {
        Constant.AccrueLoanSnapshot memory snapshot;
        snapshot.totalBorrow = _totalBorrow;
        snapshot.accInterestIndex = accInterestIndex;

        if (block.timestamp > lastAccruedTime && _totalBorrow > 0) {
            uint256 borrowRate = getBorrowRate();
            uint256 interestFactor = borrowRate.mul(block.timestamp.sub(lastAccruedTime));
            uint256 pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            snapshot.totalBorrow = _totalBorrow.add(pendingInterest);
            snapshot.accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
        }
        return snapshot;
    }

    function getBorrowRate() internal view returns (uint256) {
        uint256 _borrowRate = IRateModel(borrowMarket.getRateModel()).getBorrowRate(
            borrowMarket.getCash(), borrowMarket._totalBorrow(), borrowMarket.totalReserve()
        );
        return _borrowRate.mul(borrowRateMultiplier).div(1e18);
    }

    function currentLoanId() external view override returns (uint256) {
        uint256 _loanId = _loanIdTracker.current();
        return _loanId;
    }

    function getAccInterestIndex() public view override returns (uint256) {
        Constant.AccrueLoanSnapshot memory snapshot = pendingAccrueSnapshot();
        return snapshot.accInterestIndex;
    }

    /* ========== RECEIVER FUNCTIONS ========== */

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}