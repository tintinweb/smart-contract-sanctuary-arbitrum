/**
 *Submitted for verification at Arbiscan.io on 2023-10-29
*/

// SPDX-License-Identifier: Unlicensed
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    function notifyReward(uint256 reward) external ;
}

interface IRelation {
    function getInviter(address account) external view returns(address);
}

interface ILargePool {
    function grantReward(address account) external;
}

interface IGBXToken {
    function safeMint(address account, uint256 _amount) external ;
}

interface IAirdrop {
    function getWhiteAddress(address account) external view returns(bool);
    function setWhiteList(address account, bool isWhite) external;
}


contract GalaxiusV3 is Ownable {
    using SafeMath for uint256;

    enum GAMELEVEL{
        LV1, LV2, LV3, LV4, LV5, LV6, LV7, LV8, LV9, LV10, LV11, LV12, LV13
    }
    enum REWARDTYPES{GAX, GBX}

    IERC20 public gaxToken;
    IERC20 public gbxToken;
    address public nodeNFTAddress;
    address public relationAddress;
    address public airdropAddress;

    address public fundAddress;
    address public poolAddress;
    address public receivedAddress;
    address public orderRewardReceivedAddress;

    uint256 internal seedId;
    uint256 public minRequiredGaxAmount = 500 * 10 ** 18;
    uint256 public maxRequiredGaxAmount = 50000 * 10 ** 18;
    // uint256 public failFee = 6; 
    uint256 public successFee = 6;

    struct Multiple {
        uint256 _multi;
        uint256 _successRate;
        uint256 _failRate;
    }
    mapping (GAMELEVEL => Multiple) gameLevelMultiple;

    struct AccountGame {
        GAMELEVEL _level;
        uint256 _amount;
        uint256 _probability;
        REWARDTYPES _rewardTypes;
        uint256 _rewardAmount;
        uint256 _rewardTime;
    }
    mapping (address => AccountGame[]) accountGameInfo;
    mapping (address => AccountGame[]) accountGameHistory;
    mapping (address => uint256) public accountAchievement;
    mapping (address => mapping (GAMELEVEL => bool)) accountClearance;

    struct TopNodes{
        address _owner;
        uint256 _tokenId;
        uint256 _achievement;
    }

    uint256 internal poolFee = 1;
    uint256 internal fundFee = 2;
    uint256 internal inviteFee = 2;
    uint256 internal nodesFee = 1;

    uint256 internal recommendFee = 2;

    struct RECOMMENDREWARD {
        uint256 _rewardAmount;
        uint256 _totalPaidReward;
    }
    mapping (address => RECOMMENDREWARD) public recommendationAward;
    uint256 dividentFee = 20; // 20%
    mapping (address => uint256) public nodesDividents;

    uint256 totalOrder = 100;
    uint256 orderRate = 50; // 50%
    uint256 nodeRate = 50; // 50%
    uint256 top10Rate = 200; // 200 /10000
    uint256 top100Rate = 44; // 44/1000
    uint256 top300Rate = 20; //20 /10000

    struct  AccountLog{
        address _winner;
        uint256 _reward;
    }

    AccountLog[] internal accountLogs;

    event ClaimRecommendationAward(address indexed account, uint256 amount);
    event Start(address indexed  account, uint256 amount, GAMELEVEL _level);
    event ClaimNodesDividents(address indexed account, uint256 amount);

    constructor(
        address _gaxTokenAddress,
        address _nodeNFTAddress
    )  {
        seedId = block.number;
        gaxToken = IERC20(_gaxTokenAddress);
        nodeNFTAddress = _nodeNFTAddress;

        gameLevelMultiple[GAMELEVEL.LV1] = Multiple(11, 8546, 1454);
        gameLevelMultiple[GAMELEVEL.LV2] = Multiple(13, 7231, 2769);
        gameLevelMultiple[GAMELEVEL.LV3] = Multiple(15, 6267, 3733);
        gameLevelMultiple[GAMELEVEL.LV4] = Multiple(20, 4700, 5300);
        gameLevelMultiple[GAMELEVEL.LV5] = Multiple(30, 3133, 6867);
        gameLevelMultiple[GAMELEVEL.LV6] = Multiple(50, 1880, 8120);
        gameLevelMultiple[GAMELEVEL.LV7] = Multiple(100, 940, 9060);
        gameLevelMultiple[GAMELEVEL.LV8] = Multiple(300, 313, 9687);
        gameLevelMultiple[GAMELEVEL.LV9] = Multiple(500, 188, 9812);
        gameLevelMultiple[GAMELEVEL.LV10] = Multiple(660, 142, 9858);
        gameLevelMultiple[GAMELEVEL.LV11] = Multiple(770, 122, 9878);
        gameLevelMultiple[GAMELEVEL.LV12] = Multiple(880, 107, 9893);
        gameLevelMultiple[GAMELEVEL.LV13] = Multiple(990, 95, 9905);

    }

    function setGameLevelMultiple(GAMELEVEL _level, uint _multi, uint _bigPro, uint _smallPro) external onlyOwner {
        gameLevelMultiple[_level]= Multiple(_multi, _bigPro, _smallPro);
    }

    function interest(address tokenAddress, address account, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).approve(address(this), amount);
        IERC20(tokenAddress).transferFrom(address(this), account, amount);
    }

    function setFee(uint256 _successFee) external onlyOwner {
        successFee = _successFee;
    }

    function setRecommendFee(uint256 _recommendFee) external onlyOwner {
        recommendFee = _recommendFee;
    }

    function setDividentFee(uint256 _dividentFee) external onlyOwner {
        dividentFee = _dividentFee;
    }

    function setAirdropAddress(address _airdropAddress) external onlyOwner {
        airdropAddress = _airdropAddress;
    }

    function setReceivedAddress(address _receivedAddress) external onlyOwner {
        receivedAddress = _receivedAddress;
    }

    function setConfigAddress(
        address _gaxTokenAddress,
        address _nodeNFTAddress,
        address _relationAddress,
        address _gbxTokenAddress,
        address _fundAddress,
        address _poolAddress,
        address _orderRewardReceivedAddress
    ) external onlyOwner {
        gaxToken = IERC20(_gaxTokenAddress);
        nodeNFTAddress = _nodeNFTAddress;
        relationAddress = _relationAddress;
        gbxToken = IERC20(_gbxTokenAddress);

        fundAddress = _fundAddress;
        poolAddress = _poolAddress;
        receivedAddress = poolAddress;
        orderRewardReceivedAddress = _orderRewardReceivedAddress;
    }

    function start(uint256 amount, GAMELEVEL _level) public {
        require(minRequiredGaxAmount <= amount && amount <= maxRequiredGaxAmount , "Amount error");
        require(accountGameInfo[msg.sender].length <= 0, "Treasure Chest has not been opened");
        if(uint8(_level) > 0) {
            GAMELEVEL preLevel = GAMELEVEL(uint8(_level) - 1);
            require(accountClearance[msg.sender][preLevel], "Must pass the previous level first");
        }
        
        uint256 probability = randProbability();
        REWARDTYPES rewardTypes = getRewardTypes(probability, _level);
        accountGameInfo[msg.sender].push(AccountGame(
            _level,
            amount,
            probability,
            rewardTypes,
            0,
            0
        ));
        seedId++;
        accountAchievement[msg.sender] += amount;
        uint256 totalFee = amount.mul(successFee).div(100);
        gaxToken.transferFrom(msg.sender, address(this), amount);
        calculateFee(msg.sender, totalFee);
        if(airdropAddress != address(0)) {
            bool isWhite = IAirdrop(airdropAddress).getWhiteAddress(msg.sender);
            if(!isWhite) {
                try IAirdrop(airdropAddress).setWhiteList(msg.sender, true) {} catch {}
            }
        }
        emit Start(msg.sender, amount, _level);
    }

    function openTheTreasureChest() public {
        require(accountGameInfo[msg.sender].length > 0, "No Avable Treasure Chest");
        AccountGame storage accountGameItem = accountGameInfo[msg.sender][0];
       
        if(accountGameItem._rewardTypes == REWARDTYPES.GAX) {
            uint256 rewardGAXAmount = accountGameItem._amount.mul(gameLevelMultiple[accountGameItem._level]._multi).div(10);
            accountGameItem._rewardAmount = rewardGAXAmount;
            gaxToken.transfer(msg.sender, accountGameItem._rewardAmount);
            if(!accountClearance[msg.sender][accountGameItem._level]) {
                accountClearance[msg.sender][accountGameItem._level] = true;
            }
            if(uint8(accountGameItem._level) == uint8(12)) { //last
                try ILargePool(poolAddress).grantReward(msg.sender) { }catch {}
                initalLevel(msg.sender);
            }
            accountLogs.push(AccountLog(msg.sender, accountGameItem._rewardAmount));
        } else {
            uint256 rewardGBXAmount = accountGameItem._amount;
            IGBXToken(address(gbxToken)).safeMint(msg.sender, rewardGBXAmount);
        }
        accountGameItem._rewardTime = block.timestamp;
        accountGameHistory[msg.sender].push(accountGameItem);
        accountGameInfo[msg.sender].pop();
       
    }

    function initalLevel(address account) private {
        uint8 total = uint8(13);
        for(uint8 i = 0; i < total; i++) {
           accountClearance[account][GAMELEVEL(i)] = false;
        }
    }

    function calculateFee(address account, uint256 _totalFee) internal {
        uint256 fee = poolFee.add(fundFee).add(inviteFee).add(nodesFee);
        uint256 poolAmount = _totalFee.mul(poolFee).div(fee);
        uint256 fundAmount = _totalFee.mul(fundFee).div(fee);
        uint256 inviteAmount = _totalFee.mul(inviteFee).div(fee);
        address invitor = IRelation(relationAddress).getInviter(account);
        if(invitor != address(0) && accountAchievement[invitor] > 0) {
            grantRecommendReward(invitor, inviteAmount);
        } else {
            gaxToken.transfer(receivedAddress, inviteAmount);
        }
        uint256 nodeAmount = _totalFee.sub(poolAmount.add(fundAmount).add(inviteAmount));
        // nodeRewardDistribute(nodeAmount);
        uint256 remainingAmount = addNodesDivident(account, nodeAmount);
        if(remainingAmount > 0) {
            poolAmount = poolAmount.add(remainingAmount);
        }
        gaxToken.transfer(fundAddress, fundAmount);
        gaxToken.transfer(poolAddress, poolAmount);
    }

    function grantRecommendReward(address invitor, uint256 inviteAmount) private {
        RECOMMENDREWARD storage accRecommendReward = recommendationAward[invitor];
        uint256 shouldReward = accountShouldRecommendReward(invitor);
        if(accRecommendReward._rewardAmount.add(accRecommendReward._totalPaidReward) >= shouldReward) {
            gaxToken.transfer(receivedAddress, inviteAmount);
            return ;
        }
        uint256 realReward = inviteAmount;
        if(accRecommendReward._rewardAmount.add(accRecommendReward._totalPaidReward).add(realReward) > shouldReward) {
            realReward = shouldReward.sub(accRecommendReward._rewardAmount.add(accRecommendReward._totalPaidReward));
        }
        if(inviteAmount.sub(realReward) > 0) {
            gaxToken.transfer(receivedAddress, inviteAmount.sub(realReward));
        }
        accRecommendReward._rewardAmount += realReward;
    }

    function accountShouldRecommendReward(address account) public view returns(uint256) {
         uint256 shouldReward = accountAchievement[account].mul(recommendFee).div(100);
         return shouldReward;
    }

    function addNodesDivident(address account, uint256 amount) internal returns(uint256) {
        uint256 orderReward = amount.div(2);
        if(orderReward > 0) {
            amount = amount.sub(orderReward);
            gaxToken.transfer(orderRewardReceivedAddress, orderReward);
        }
        address inviter = IRelation(relationAddress).getInviter(account);
        while(inviter != address(0)) {
            uint256 accCount = IERC721Enumerable(nodeNFTAddress).balanceOf(inviter);
            if(accCount > 0) {
                nodesDividents[inviter] += amount;
                amount = 0;
                break ;
            }
            inviter = IRelation(relationAddress).getInviter(inviter);
        }
        return amount;
    }

    function claimNodesDivident() public {
        require(nodesDividents[msg.sender] > 0, "No Reward Claim");
        require(gaxToken.balanceOf(address(this)) > nodesDividents[msg.sender], "Insufficient funds");
        uint256 claimReward = nodesDividents[msg.sender];
        uint256 feeAmount = claimReward.mul(dividentFee).div(100);
        address invitor = IRelation(relationAddress).getInviter(msg.sender);
        recommendDividents(invitor, feeAmount);
        claimReward = claimReward.sub(feeAmount);
        nodesDividents[msg.sender] = 0;
        gaxToken.transfer(msg.sender, claimReward);
        emit ClaimNodesDividents(msg.sender, claimReward);
    }

    function recommendDividents(address inviter, uint256 amount) private {
        uint256 inviteReward;
        while(inviter != address(0)) {
           uint256 accCount = IERC721Enumerable(nodeNFTAddress).balanceOf(inviter);
            if(accCount > 0) {
                inviteReward = amount;
                nodesDividents[inviter] += inviteReward;
                break ;
            }
            inviter = IRelation(relationAddress).getInviter(inviter);
        }
        if(inviteReward <= 0) {
            gaxToken.transfer(receivedAddress, amount);
        }
    }

    function getNodesDivident(address account) public view returns(uint256) {
        return nodesDividents[account];
    }

    function claimRecommendationAward() public {
        RECOMMENDREWARD storage accRecommendReward = recommendationAward[msg.sender];
        require(accRecommendReward._rewardAmount > 0, "There are no more rewards to claim");
        uint256 claimAmountHalf = accRecommendReward._rewardAmount.div(2);

        require(gaxToken.balanceOf(address(this)) > claimAmountHalf, "Insufficient funds");
        address invitor = IRelation(relationAddress).getInviter(msg.sender);
        if(invitor != address(0)) {
            RECOMMENDREWARD storage superRecommendReward = recommendationAward[invitor];
            uint256 shouldReward = accountShouldRecommendReward(invitor);
            if(superRecommendReward._rewardAmount.add(superRecommendReward._totalPaidReward) >= shouldReward) {
                gaxToken.transfer(receivedAddress, claimAmountHalf);
            } else {
                uint256 realReward = claimAmountHalf;
                if(superRecommendReward._rewardAmount.add(superRecommendReward._totalPaidReward).add(realReward) > shouldReward) {
                    realReward = shouldReward.sub(superRecommendReward._rewardAmount.add(superRecommendReward._totalPaidReward));
                }
                if(claimAmountHalf.sub(realReward) > 0) {
                    gaxToken.transfer(receivedAddress, claimAmountHalf.sub(realReward));
                }
                superRecommendReward._rewardAmount += realReward;
            }
        } else {
            gaxToken.transfer(receivedAddress, claimAmountHalf);
        }
        accRecommendReward._totalPaidReward = accRecommendReward._totalPaidReward.add(accRecommendReward._rewardAmount);
        accRecommendReward._rewardAmount = 0;
        gaxToken.transfer(msg.sender, claimAmountHalf);
        emit ClaimRecommendationAward(msg.sender, claimAmountHalf);
    }

    function getAccountLogs(uint256 quantity) public view returns(AccountLog[] memory logList) {
        uint256 arrItem  = accountLogs.length > quantity ? quantity : accountLogs.length;
        logList = new AccountLog[](arrItem);
        uint256 floor = accountLogs.length.sub(arrItem);
        uint256 index = 0;
        for(uint256 i = floor; i < accountLogs.length; i++) {
            logList[index] = accountLogs[i];
            index++;
        }
    }

    function getRewardTypes(uint256 _probability, GAMELEVEL _level) internal view returns(REWARDTYPES _types) {
        _types = _probability <= gameLevelMultiple[_level]._successRate ? REWARDTYPES.GAX : REWARDTYPES.GBX;
    }

    function randProbability() public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.prevrandao, msg.sender, block.timestamp, seedId)));
        return random.mod(10000).add(1);
    }

    function getAccountTreasureChest(address account) public view returns (uint256) {
        return accountGameInfo[account].length;
    }

    function getAccountTreasureChestInfo(address account) public view returns(AccountGame memory) {
        return accountGameInfo[account][0];
    }

    struct CLEARANCE {
        GAMELEVEL _level;
        bool _isLock;
    }
    function getAccountClearance(address account) public view returns(CLEARANCE[] memory) {
        uint8 total = 13;
        CLEARANCE[] memory clearanceList = new CLEARANCE[](total);
        for(uint8 i = 0; i < total; i++) {
            clearanceList[i] =CLEARANCE(
                GAMELEVEL(i),
                accountClearance[account][GAMELEVEL(i)]
            );    
        }
        return clearanceList;
    }

}