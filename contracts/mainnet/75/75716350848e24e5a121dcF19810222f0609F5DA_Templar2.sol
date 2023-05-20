/**
 *Submitted for verification at Arbiscan on 2023-05-20
*/

// File: contracts/utils/Owner.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owner {
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);

    constructor(){
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) external onlyOwner {
        require(account != address(0),"zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner,"not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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


pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


pragma solidity ^0.8.0;

interface IRandom {
    function requestRandomness(uint256 tokenId) external;
    function openRand(uint256 tokenId) external returns(bool,uint256);
    function fightRand(uint256 tokenId,uint256 energy) external returns(bool,uint256);
}
interface IDOGSHIT721 is IERC721 {
    function mint(address recipient_) external returns (uint256);
    function getTokens(address owner) external view returns(uint256[] memory);
}


contract Templar2 is Owner {
    using SafeERC20 for IERC20;

    struct TokenInfo {
        uint256 fightAt;            // last fight time
        uint256 energy;             // stamina left
        uint256 levelCode;          // 100、200、300、400、500...、600
        uint256 totalClaim;         // v2
    }
    struct AccountInfo {
        uint256 reward;
        uint256 claimAt;
        uint256 totalClaim;
    }
    struct Mission {
        uint256 winRate;
        uint256 reward;
    }
    struct Level {
        uint256 winRateAdd;         // %
        uint256 rewardAdd;          // %
        uint256 code;
        uint256 levelOffset;        // %
    }

    IERC20      public immutable DOGSHIT20;
    IDOGSHIT721     public immutable DOGSHIT721;
    IRandom     public random;

    bool public contractCallable = false;

    uint256 public claimCD = 1 days;
    uint256 public claimFeeRate = 10;       // %
    address public feeAccount;
    uint256 public chestFee;
    uint256 public chestSupply;

    uint256 public maxEnergy = 2;
    uint256 public energyCD = 12 hours;

    uint256 public totalClaimFee;
    uint256 public totalChestFee;

    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(address => AccountInfo) public accountInfo;
    mapping(uint256 => Mission) public missionInfo;
    mapping(uint256 => Level) public levelInfo;


    event Chest(address indexed account, uint256 fee, uint256 indexed  tokenId);
    event Open(address indexed account, uint256 indexed level, uint256 indexed tokenId,uint256 rand);
    event Fight(address indexed account, bool indexed win, uint256 indexed reward, uint256 boss, uint256 tokenId,uint256 rand);
    event Claim(address indexed account, uint256 indexed amount);

    event ReMint(address indexed account, uint fee, uint256 indexed tokenId);
    event ReOpen(address indexed account, uint256 indexed level, uint256 indexed tokenId);


    constructor(address DOGSHIT20_,address DOGSHIT721_){
        DOGSHIT20 = IERC20(DOGSHIT20_);
        DOGSHIT721 = IDOGSHIT721(DOGSHIT721_);

        feeAccount = msg.sender;

        setMissionInfo(1, 80, 2500000 * 1e18);
        setMissionInfo(2, 60, 2500000 * 1e18);
        setMissionInfo(3, 40, 2500000 * 1e18);
        setMissionInfo(4, 20, 2500000 * 1e18);

        setLevelInfo(1, 0, 0);
        setLevelInfo(2, 5, 0);
        setLevelInfo(3, 6, 50);
        setLevelInfo(4, 8, 250);
        setLevelInfo(5, 15, 1900);
        setLevelInfo(6, 15, 2900);

        setReMintInfo(1,10000000 * 1e18,[uint(50),uint(30),uint(7),uint(3),uint(10)]);
        setReMintInfo(2,10000000 * 1e18,[uint(0),uint(60),uint(20),uint(5),uint(15)]);
        setReMintInfo(3,10000000 * 1e18,[uint(0),uint(0),uint(70),uint(10),uint(20)]);

    }

    function chest() public returns (uint256 tokenId) {

        require(chestSupply >= 1,"no suppluy");
        chestSupply -= 1;

        DOGSHIT20.transferFrom(msg.sender,feeAccount,chestFee);
        tokenId = DOGSHIT721.mint(msg.sender);

        random.requestRandomness(tokenId);
        totalChestFee += chestFee;

        emit Chest(msg.sender, chestFee, tokenId);
        return tokenId;
    }

    function multiChest(uint256 nftAmount) external {
        require(nftAmount > 0,"multiple");
        for (uint256 index = 0; index < nftAmount; index++) {
            chest();
        }
    }

    function open(uint256 tokenId) external returns (uint256 levelCode) {
        //
        require(DOGSHIT721.ownerOf(tokenId) == msg.sender, "not yours");
        require(tokenInfo[tokenId].levelCode == 0 || tokenInfo[tokenId].levelCode == 10,"never retry");

        //
        (bool succ, uint r) = random.openRand(tokenId);
        require(succ,"try later");

        uint level = 0;
        uint offset = 0;
        do {
            level ++;
            offset = levelInfo[level].levelOffset;
            if (r < offset) {
                break;
            }
        }while(offset != 100);

        tokenInfo[tokenId].energy = maxEnergy;
        tokenInfo[tokenId].levelCode = levelInfo[level].code;

        emit Open(msg.sender,levelInfo[level].code,tokenId,r);
        return levelInfo[level].code;
    }

    function fight(uint256 tokenId, uint256 mission) public {

        if (isContract(msg.sender) && !contractCallable){
            require(false,"can not call");
        }

        require(DOGSHIT721.ownerOf(tokenId) == msg.sender, "not yours");

        (uint256 fightAt,uint256 energy, uint256 levelCode)= getTokenInfo(tokenId);
        require(energy > 0, "rest awhile");

        (uint256 winRate, uint256 rewards) = getWRR(mission, levelCode);
        (,uint256 r) = random.fightRand(tokenId,energy * 10);
        r = 100 -r;
        if (winRate > r) {
            accountInfo[msg.sender].reward += rewards;
            accountInfo[msg.sender].totalClaim += rewards;
            tokenInfo[tokenId].totalClaim += rewards;
            emit Fight(msg.sender,true,rewards, mission, tokenId,r);
        }else{
            emit Fight(msg.sender,false,0, mission, tokenId,r);
        }
        tokenInfo[tokenId].energy = energy - 1;
        tokenInfo[tokenId].fightAt = fightAt;
    }

    function multiFight(uint256 tokenId, uint256 mission, uint256 times) external {
        require(times > 0,"multiple");

        for (uint256 index = 0; index < times; index++) {
            fight(tokenId, mission);
        }
    }

    function claim() external returns (uint256 reward) {

        reward = accountInfo[msg.sender].reward;
        uint claimAt = accountInfo[msg.sender].claimAt;
        if (reward > 0) {
            require(claimAt == 0 || block.timestamp - claimAt >= claimCD, "not now");

            uint feePart = reward * claimFeeRate / 100;
            DOGSHIT20.safeTransfer(feeAccount,feePart);
            DOGSHIT20.safeTransfer(msg.sender,reward - feePart);
            totalClaimFee += feePart;

            accountInfo[msg.sender].claimAt = block.timestamp;
            accountInfo[msg.sender].reward = 0;
        }

        emit Claim(msg.sender, reward);
        return reward;
    }

    function getTokenInfo(uint256 tokenId) public view returns(uint256 fightAt, uint256 energy, uint256 levelCode) {

        TokenInfo memory token = tokenInfo[tokenId];
        if (token.energy != maxEnergy) {
            uint256 r = (block.timestamp - token.fightAt) / energyCD;
            if (token.energy + r < maxEnergy) {
                fightAt = token.fightAt + (r * energyCD);
                energy = token.energy + r;
                return (fightAt,energy,token.levelCode);
            }
        }
        return (block.timestamp,maxEnergy,token.levelCode);
    }

    function getWRR(uint256 mission, uint256 levelCode) public view returns(uint256 winRate, uint256 reward) {
        Level memory l = levelInfo[levelCode / 100];
        winRate = missionInfo[mission].winRate + l.winRateAdd;
        if (winRate > 100) {
            winRate = 100;
        }
        reward = missionInfo[mission].reward * (l.rewardAdd + 100) / 100;
        return (winRate,reward);
    }

    function getSupplyInfo() external view returns (uint256 fee, uint256 supply) {
        return (chestFee,chestSupply);
    }

    function setEnergyInfo(uint256 max,uint256 coolDown) external onlyOwner{
        maxEnergy = max;
        energyCD = coolDown;
    }

    function setFeeAccount(address account) external onlyOwner {
        require(account != address(0),"zero address");
        feeAccount = account;
    }
    function setContractCallable(bool enable) external onlyOwner {
        contractCallable = enable;
    }

    function setRandom(address r) public onlyOwner {
        random = IRandom(r);
    }

    function setClaimFeeInfo(uint256 rate, uint256 coolDown) external onlyOwner {
        claimFeeRate = rate;
        claimCD = coolDown;
    }
    function setChestSupply(uint256 supply, uint256 fee,uint256[] memory levelCode,uint256[] memory openRate) external onlyOwner {

        require(levelCode.length == openRate.length, "rewrite it");
        chestSupply = supply;
        chestFee = fee;
        uint levelOffset;
        for (uint256 i=0; i<levelCode.length; i++){

            levelOffset += openRate[i];
            require(levelCode[i] >= 100*(i+1) && levelCode[i] < 100*(i+2));
            levelInfo[i+1].code = levelCode[i];
            levelInfo[i+1].levelOffset = levelOffset;
        }
    }
    function setLevelInfo(uint256 level, uint256 winRateAdd, uint256 rewardAdd) public onlyOwner {
        levelInfo[level].winRateAdd = winRateAdd;
        levelInfo[level].rewardAdd = rewardAdd;
    }
    function setMissionInfo(uint256 mission, uint256 winRate, uint256 reward) public onlyOwner {
        missionInfo[mission].winRate = winRate;
        missionInfo[mission].reward = reward;
    }

    struct ReMintInfo {
        uint fee;
        uint offset1;
        uint offset2;
        uint offset3;
        uint offset4;
        uint offsetChest;
        uint count;
    }
    mapping(uint=>ReMintInfo) public reMintInfo;


    function reMint(uint256 tokenId) external {

        require(DOGSHIT721.ownerOf(tokenId) == msg.sender, "not yours");

        (,uint256 energy, uint256 levelCode)= getTokenInfo(tokenId);
        require(energy == maxEnergy, "rest awhile");
        require(levelCode >= 100,"wrong method");

        uint level = levelCode/100;
        uint reMintFee = reMintInfo[level].fee;
        require(reMintFee >= 0,"not allowed");

        DOGSHIT20.transferFrom(msg.sender,address(this),reMintFee);
        tokenInfo[tokenId].levelCode = level;

        random.requestRandomness(tokenId);
        reMintInfo[level].count += 1;

        emit ReMint(msg.sender,reMintFee,tokenId);
    }

    function reOpen(uint256 tokenId) external {

        uint levelCode = tokenInfo[tokenId].levelCode;

        require(DOGSHIT721.ownerOf(tokenId) == msg.sender, "not yours");
        require(levelCode > 0 && levelCode < 4, "wrong method");

        (bool succ, uint r) = random.openRand(tokenId);
        require(succ,"try later");

        ReMintInfo memory info = reMintInfo[levelCode];

        if (r < info.offset1) {
            levelCode = 100;
        }else if (r < info.offset2) {
            levelCode = 200;
        }else if (r < info.offset3) {
            levelCode = 300;
        }else if (r < info.offset4) {
            levelCode = 400;
        }else if (r <  info.offsetChest) {
            random.requestRandomness(tokenId);
            levelCode = 10;
        }else {
            require(false,"unexpected rand");
        }

        tokenInfo[tokenId].energy = maxEnergy;
        tokenInfo[tokenId].levelCode = levelCode;

        emit ReOpen(msg.sender,levelCode,tokenId);
    }

    function isContract(address account) view public returns(bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function setReMintInfo(uint256 level, uint256 fee,uint[5] memory rate) public onlyOwner {

        require(rate.length == 5, "rewrite it");

        uint offset = rate[0];
        reMintInfo[level].fee = fee;
        reMintInfo[level].offset1 = offset;
        offset += rate[1];
        reMintInfo[level].offset2 = offset;
        offset += rate[2];
        reMintInfo[level].offset3 = offset;
        offset += rate[3];
        reMintInfo[level].offset4 = offset;
        offset += rate[4];
        reMintInfo[level].offsetChest = offset;
    }
}