/**
 *Submitted for verification at Arbiscan on 2022-12-26
*/

// File: Context.sol

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

// File: Governable.sol

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// File: IAccessControl.sol

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: IERC165.sol

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

// File: IERC20.sol

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

// File: InterfacesBinary.sol

interface IOptionRouter {
    struct QueuedTrade {
        uint256 queueId;
        uint256 userQueueIndex;
        address user;
        uint256 totalFee;
        uint256 period;
        bool isAbove;
        address targetContract;
        uint256 expectedStrike;
        uint256 slippage;
        bool allowPartialFill;
        uint256 queuedTime;
        uint256 cancellationTime;
        bool isQueued;
    }
    struct Trade {
        uint256 queueId;
        uint256 price;
    }

    event OpenTrade(uint256 queueId, address user);
    event CancelTrade(uint256 queueId, address user, string reason);
    event InitiateTrade(uint256 queueId, address user);
}

interface IBufferBinaryOptions {
    event Create(
        uint256 indexed id,
        address indexed account,
        uint256 settlementFee,
        uint256 totalFee
    );

    event Exercise(
        uint256 indexed id,
        uint256 profit,
        uint256 priceAtExpiration
    );
    event Expire(
        uint256 indexed id,
        uint256 premium,
        uint256 priceAtExpiration
    );

    function createFromRouter(
        address user,
        uint256 totalFee,
        uint256 period,
        bool isAbove,
        uint256 strike,
        uint256 amount
    ) external returns (uint256 optionID);

    function checkParams(
        uint256 totalFee,
        bool isAbove,
        bool allowPartialFill
    ) external returns (uint256 amount, uint256 revisedFee);

    function runInitialChecks(
        uint256 slippage,
        uint256 period,
        uint256 totalFee
    ) external view;

    function isStrikeValid(
        uint256 slippage,
        uint256 strike,
        uint256 expectedStrike
    ) external view returns (bool);

    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }
    enum OptionType {
        Invalid,
        Put,
        Call
    }
    enum PaymentMethod {
        Usdc,
        TokenX
    }

    struct OptionExpiryData {
        uint256 optionId;
        uint256 priceAtExpiration;
    }

    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        OptionType optionType;
        uint256 totalFee;
        uint256 createdAt;
    }

    struct BinaryOptionType {
        bool isYes;
        bool isAbove;
    }

    struct SlotDetail {
        uint256 strike;
        uint256 expiration;
        OptionType optionType;
        bool isValid;
    }
}

interface IBufferOptionsRead {
    enum State {
        Inactive,
        Active,
        Exercised,
        Expired
    }
    enum OptionType {
        Invalid,
        Put,
        Call
    }

    struct Option {
        State state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        OptionType optionType;
        uint256 totalFee;
        uint256 createdAt;
    }

    struct BinaryOptionType {
        bool isYes;
        bool isAbove;
    }

    function priceProvider() external view returns (address);

    function expiryToRoundID(uint256 timestamp) external view returns (uint256);

    function options(uint256 optionId)
        external
        view
        returns (
            State state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            OptionType optionType,
            uint256 totalFee,
            uint256 createdAt
        );

    function ownerOf(uint256 optionId) external view returns (address owner);

    function nextTokenId() external view returns (uint256 nextToken);

    function binaryOptionType(uint256 optionId)
        external
        view
        returns (bool isYes, bool isAbove);

    function optionPriceAtExpiration(uint256 optionId)
        external
        view
        returns (uint256 priceAtExpiration);

    function config() external view returns (address);

    function userOptionIds(address user, uint256 index)
        external
        view
        returns (uint256 optionId);

    function userOptionCount(address user)
        external
        view
        returns (uint256 count);
}

interface IOptionRouterRead {
    struct QueuedTrade {
        uint256 queueId;
        uint256 userQueueIndex;
        address user;
        uint256 totalFee;
        uint256 period;
        bool isAbove;
        address targetContract;
        uint256 expectedStrike;
        uint256 slippage;
        bool allowPartialFill;
        uint256 queuedTime;
        uint256 cancellationTime;
        bool isQueued;
    }

    function queuedTrades(uint256 queueId)
        external
        view
        returns (QueuedTrade memory);

    function userQueueCount(address user) external view returns (uint256);

    function userQueuedIds(address user, uint256 index)
        external
        view
        returns (uint256);

    function userNextQueueIndexToProcess(address user)
        external
        view
        returns (uint256);

    function nextQueueIdToProcess() external view returns (uint256);

    function nextQueueId() external view returns (uint256);

    function userCancelledQueueCount(address user)
        external
        view
        returns (uint256);

    function userCancelledQueuedIds(address user, uint256 index)
        external
        view
        returns (uint256);
}

interface ILiquidityPool {
    struct LockedLiquidity {
        uint256 amount;
        uint256 premium;
        bool locked;
    }

    event Profit(uint256 indexed id, uint256 amount);
    event Loss(uint256 indexed id, uint256 amount);
    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event Withdraw(
        address indexed account,
        uint256 amount,
        uint256 writeAmount
    );

    function unlock(uint256 id) external;

    // function unlockPremium(uint256 amount) external;
    event UpdateRevertTransfersInLockUpPeriod(
        address indexed account,
        bool value
    );
    event InitiateWithdraw(uint256 tokenXAmount, address account);
    event ProcessWithdrawRequest(uint256 tokenXAmount, address account);
    event UpdatePoolState(bool hasPoolEnded);
    event PoolRollOver(uint256 round);
    event UpdateMaxLiquidity(uint256 indexed maxLiquidity);
    event UpdateExpiry(uint256 expiry);
    event UpdateProjectOwner(address account);

    function totalTokenXBalance() external view returns (uint256 amount);

    function availableBalance() external view returns (uint256 balance);

    function unlockWithoutProfit(uint256 id) external;

    function send(
        uint256 id,
        address account,
        uint256 amount
    ) external;

    function lock(
        uint256 id,
        uint256 tokenXAmount,
        uint256 premium
    ) external;
}

interface IOptionsConfig {
    enum PermittedTradingType {
        All,
        OnlyPut,
        OnlyCall,
        None
    }
    // event UpdateImpliedVolatility(uint256 value);
    event UpdateSettlementFeePercentageForUp(uint256 value);
    event UpdateSettlementFeePercentageForDown(uint256 value);
    event UpdateSettlementFeeRecipient(address account);
    event UpdateStakingFeePercentage(
        uint256 treasuryPercentage,
        uint256 blpStakingPercentage,
        uint256 bfrStakingPercentage,
        uint256 insuranceFundPercentage
    );

    event UpdateOptionCollaterizationRatio(uint256 value);
    event UpdateTradingPermission(PermittedTradingType permissionType);
    event UpdateStrike(uint256 value);
    event UpdateUnits(uint256 value);
    event UpdateMaxPeriod(uint256 value);
    event UpdateOptionSizePerTxnLimitPercent(uint256 value);
    event UpdateSettlementFeeDisbursalContract(address value);
    event UpdatePoolUtilizationLimitPercent(uint256 value);

    enum OptionType {
        Invalid,
        Put,
        Call
    }
}

interface ISettlementFeeDisbursal {
    function distributeSettlementFee(uint256 settlementFee)
        external
        returns (uint256 stakingAmount);
}

// File: SafeMath.sol

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: ERC165.sol

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: IERC20Metadata.sol

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// File: Ownable.sol

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: AccessControl.sol

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: BufferBinaryIBFRPoolBinary.sol

/**
 * @author Heisenberg
 * @title Buffer TokenX Liquidity Pool
 * @notice Accumulates liquidity in TokenX from LPs and distributes P&L in TokenX
 */
contract BufferBinaryIBFRPoolBinary is
    ERC20("Buffer LP Token", "BLP"),
    AccessControl,
    ILiquidityPool,
    Governable
{
    struct LockedAmount {
        uint256 timestamp;
        uint256 amount;
    }
    struct ProvidedLiquidity {
        uint256 unlockedAmount;
        LockedAmount[] lockedAmounts;
        uint256 nextIndexForUnlock;
    }
    uint256 public constant ACCURACY = 1e3;
    uint256 public constant INITIAL_RATE = 1;
    uint256 public lockupPeriod = 10 minutes;
    uint256 public lockedAmount;
    uint256 public lockedPremium;
    uint256 public maxLiquidity;
    address public owner;
    mapping(address => LockedLiquidity[]) public lockedLiquidity;
    mapping(address => bool) public isHandler;
    mapping(address => ProvidedLiquidity) public liquidityPerUser;

    bytes32 public constant OPTION_ISSUER_ROLE =
        keccak256("OPTION_ISSUER_ROLE");

    ERC20 public tokenX;

    constructor(ERC20 _tokenX) {
        tokenX = _tokenX;
        owner = msg.sender;
        maxLiquidity = 5000000 * 10**_tokenX.decimals();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Returns the decimals of the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return tokenX.decimals();
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "Pool: forbidden");
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual override returns (bool) {
        if (isHandler[msg.sender]) {
            _transfer(_sender, _recipient, _amount);
            return true;
        }

        uint256 currentAllowance = allowance(_sender, msg.sender);
        require(
            currentAllowance >= _amount,
            "Pool: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(_sender, msg.sender, currentAllowance - _amount);
        }
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    /**
     * @notice Used for adjusting the max limit of the pool
     * @param _maxLiquidity New limit
     */
    function setMaxLiquidity(uint256 _maxLiquidity)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxLiquidity = _maxLiquidity;
        emit UpdateMaxLiquidity(_maxLiquidity);
    }

    /**
     * @notice A provider supplies tokenX to the pool and receives BLP tokens
     * @param minMint Minimum amount of tokens that should be received by a provider.
                      Calling the provide function will require the minimum amount of tokens to be minted.
                      The actual amount that will be minted could vary but can only be higher (not lower) than the minimum value.
     * @return mint Amount of tokens to be received
     */
    function _provide(
        uint256 tokenXAmount,
        uint256 minMint,
        address account
    ) internal returns (uint256 mint) {
        uint256 supply = totalSupply();
        uint256 balance = totalTokenXBalance();

        require(
            balance + tokenXAmount <= maxLiquidity,
            "Pool has already reached it's max limit"
        );

        if (supply > 0 && balance > 0)
            mint = (tokenXAmount * supply) / (balance);
        else mint = tokenXAmount * INITIAL_RATE;

        require(mint >= minMint, "Pool: Mint limit is too large");
        require(mint > 0, "Pool: Amount is too small");

        bool success = tokenX.transferFrom(
            account,
            address(this),
            tokenXAmount
        );
        require(success, "Pool: The Provide transfer didn't go through");

        _mint(account, mint);

        LockedAmount memory amountLocked = LockedAmount(block.timestamp, mint);
        liquidityPerUser[account].lockedAmounts.push(amountLocked);
        _updateLiquidity(account);

        emit Provide(account, tokenXAmount, mint);
    }

    function provide(uint256 tokenXAmount, uint256 minMint)
        external
        returns (uint256 mint)
    {
        mint = _provide(tokenXAmount, minMint, msg.sender);
    }

    function provideForAccount(
        uint256 tokenXAmount,
        uint256 minMint,
        address account
    ) external returns (uint256 mint) {
        _validateHandler();
        mint = _provide(tokenXAmount, minMint, account);
    }

    function toTokenX(uint256 amount) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 balance = totalTokenXBalance();

        return (amount * balance) / totalSupply;
    }

    function _getUnlockedLiquidity(address account)
        internal
        view
        returns (uint256 unlockedAmount, uint256 nextIndexForUnlock)
    {
        uint256 len = liquidityPerUser[account].lockedAmounts.length;
        unlockedAmount = liquidityPerUser[account].unlockedAmount;
        uint256 index = liquidityPerUser[account].nextIndexForUnlock;
        nextIndexForUnlock = index;
        for (uint256 n = index; n < len; n++) {
            if (
                liquidityPerUser[account].lockedAmounts[n].timestamp +
                    lockupPeriod <=
                block.timestamp
            ) {
                unlockedAmount += liquidityPerUser[account]
                    .lockedAmounts[n]
                    .amount;
                nextIndexForUnlock = n + 1;
            } else {
                break;
            }
        }
    }

    function _updateLiquidity(address account) internal {
        (
            uint256 unlockedAmount,
            uint256 nextIndexForUnlock
        ) = _getUnlockedLiquidity(account);

        liquidityPerUser[account].unlockedAmount = unlockedAmount;
        liquidityPerUser[account].nextIndexForUnlock = nextIndexForUnlock;
    }

    function getUnlockedLiquidity(address account)
        external
        view
        returns (uint256 unlockedAmount)
    {
        (unlockedAmount, ) = _getUnlockedLiquidity(account);
    }

    /**
     * @notice Provider burns BLP and receives X from the pool
     * @param tokenXAmount Amount of X to receive
     * @param account User address for which the withdrawal has to be initiated
     * @return burn Amount of tokens to be burnt
     */
    function _withdraw(uint256 tokenXAmount, address account)
        internal
        returns (uint256 burn)
    {
        require(
            tokenXAmount <= availableBalance(),
            "Pool: Not enough funds on the pool contract. Please lower the amount."
        );
        uint256 totalSupply = totalSupply();
        uint256 balance = totalTokenXBalance();

        uint256 maxUserTokenXWithdrawal = (balanceOf(account) * balance) /
            totalSupply;

        uint256 tokenXAmountToWithdraw = maxUserTokenXWithdrawal < tokenXAmount
            ? maxUserTokenXWithdrawal
            : tokenXAmount;

        burn = divCeil((tokenXAmountToWithdraw * totalSupply), balance);

        _updateLiquidity(account);

        require(
            liquidityPerUser[account].unlockedAmount >= burn,
            "Pool: Withdrawal amount is greater than current unlocked amount"
        );
        require(burn <= balanceOf(account), "Pool: Amount is too large");
        require(burn > 0, "Pool: Amount is too small");

        _burn(account, burn);

        bool success = tokenX.transfer(account, tokenXAmountToWithdraw);
        require(success, "Pool: The Withdrawal didn't go through");

        emit Withdraw(account, tokenXAmountToWithdraw, burn);
    }

    /**
     * @notice withdraw burns BLP and receives X from the pool
     * @param tokenXAmount Amount of X to receive
     */
    function withdraw(uint256 tokenXAmount) external {
        _withdraw(tokenXAmount, msg.sender);
    }

    /**
     * @notice withdraw burns BLP and receives X from the pool to be called by the Handler
     * @param tokenXAmount Amount of X to receive
     * @param account Account to withdraw for
     */
    function withdrawForAccount(uint256 tokenXAmount, address account)
        external
        returns (uint256 burn)
    {
        _validateHandler();
        burn = _withdraw(tokenXAmount, account);
    }

    /**
     * @notice Called by BufferCallOptions to lock the funds
     * @param id optionId
     * @param tokenXAmount Amount of funds that should be locked in an option
     * @param premium Premium paid to liquidity pool to lock the above funds
     */
    function lock(
        uint256 id,
        uint256 tokenXAmount,
        uint256 premium
    ) external override onlyRole(OPTION_ISSUER_ROLE) {
        require(id == lockedLiquidity[msg.sender].length, "Pool: Wrong id");

        require(
            (lockedAmount + tokenXAmount) <= totalTokenXBalance(),
            "Pool: Amount is too large."
        );

        bool success = tokenX.transferFrom(msg.sender, address(this), premium);
        require(success, "Pool: The Premium transfer didn't go through");

        lockedLiquidity[msg.sender].push(
            LockedLiquidity(tokenXAmount, premium, true)
        );
        lockedPremium = lockedPremium + premium;
        lockedAmount = lockedAmount + tokenXAmount;
    }

    /**
     * @notice Called by BufferOptions to unlock the funds
     * @param id Id of LockedLiquidity that should be unlocked
     */
    function _unlock(uint256 id) internal returns (uint256 premium) {
        LockedLiquidity storage ll = lockedLiquidity[msg.sender][id];
        require(ll.locked, "Pool: lockedAmount is already unlocked");
        ll.locked = false;

        lockedPremium = lockedPremium - ll.premium;
        lockedAmount = lockedAmount - ll.amount;
        premium = ll.premium;
    }

    /**
     * @notice Called by BufferOptions to unlock the funds
     * @param id Id of LockedLiquidity that should be unlocked
     */
    function unlock(uint256 id) external override onlyRole(OPTION_ISSUER_ROLE) {
        uint256 premium = _unlock(id);

        emit Profit(id, premium);
    }

    /**
     * @notice Called by BufferOptions to unlock the funds
     * @param id Id of LockedLiquidity that should be unlocked
     */
    function unlockWithoutProfit(uint256 id)
        external
        override
        onlyRole(OPTION_ISSUER_ROLE)
    {
        _unlock(id);
    }

    /**
     * @notice Called by BufferCallOptions to send funds to liquidity providers after an option's expiration
     * @param id Id of LockedLiquidity
     * @param to Provider
     * @param tokenXAmount Funds that should be sent
     */
    function send(
        uint256 id,
        address to,
        uint256 tokenXAmount
    ) external override onlyRole(OPTION_ISSUER_ROLE) {
        LockedLiquidity storage ll = lockedLiquidity[msg.sender][id];
        require(ll.locked, "Pool: lockedAmount is already unlocked");
        require(to != address(0));

        ll.locked = false;
        lockedPremium = lockedPremium - ll.premium;
        lockedAmount = lockedAmount - ll.amount;

        uint256 transferTokenXAmount = tokenXAmount > ll.amount
            ? ll.amount
            : tokenXAmount;

        bool success = tokenX.transfer(to, transferTokenXAmount);
        require(success, "Pool: The Payout transfer didn't go through");

        if (transferTokenXAmount <= ll.premium)
            emit Profit(id, ll.premium - transferTokenXAmount);
        else emit Loss(id, transferTokenXAmount - ll.premium);
    }

    /**
     * @notice Returns provider's share in X
     * @param account Provider's address
     * @return share Provider's share in X
     */
    function shareOf(address account) external view returns (uint256 share) {
        if (totalSupply() > 0)
            share = (totalTokenXBalance() * balanceOf(account)) / totalSupply();
        else share = 0;
    }

    /**
     * @notice Returns the amount of X available for withdrawals
     * @return balance Unlocked amount
     */
    function availableBalance() public view override returns (uint256 balance) {
        return totalTokenXBalance() - lockedAmount;
    }

    /**
     * @notice Returns the total balance of X provided to the pool
     * @return balance Pool balance
     */
    function totalTokenXBalance()
        public
        view
        override
        returns (uint256 balance)
    {
        return tokenX.balanceOf(address(this)) - lockedPremium;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        if (a % b != 0) c = c + 1;
        return c;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (!isHandler[from] && !isHandler[to] && from != address(0)) {
            _updateLiquidity(from);
            require(
                liquidityPerUser[from].unlockedAmount >= value,
                "Pool: Transfer of funds in lock in period is blocked"
            );
            liquidityPerUser[from].unlockedAmount -= value;
            liquidityPerUser[to].unlockedAmount += value;
        }
    }
}

// File: OptionConfigBinaryV2.sol

/**
 * @author Heisenberg
 * @title Buffer BNB Bidirectional (Call and Put) Options
 * @notice Buffer BNB Options Contract
 */
contract OptionConfigBinaryV2 is Ownable, IOptionsConfig {
    uint256 public impliedVolRate;
    uint256 public optionCollateralizationRatio = 100;
    uint256 public settlementFeePercentageForUp = 5e2;
    uint256 public settlementFeePercentageForDown = 5e2;
    uint256 public treasuryPercentage = 3;
    uint256 public blpStakingPercentage = 65;
    uint256 public bfrStakingPercentage = 27;
    uint256 public insuranceFundPercentage = 5;
    uint256 internal constant PRICE_DECIMALS = 1e8;
    uint256 public utilizationRate = 60e8;
    uint256 public maxPeriod = 24 hours;
    uint256 public optionSizePerTxnLimitPercent = 5e2;
    uint256 public poolUtilizationLimitPercent = 64e2;
    BufferBinaryIBFRPoolBinary public pool;
    address public settlementFeeDisbursalContract;
    PermittedTradingType public permittedTradingType;

    constructor(BufferBinaryIBFRPoolBinary _pool) {
        pool = _pool;
    }

    /**
     * @notice Used for adjusting the settlementFeeDisbursalContract
     * @param value New settlementFeeDisbursalContract
     */
    function setSettlementFeeDisbursalContract(address value)
        external
        onlyOwner
    {
        settlementFeeDisbursalContract = value;
        emit UpdateSettlementFeeDisbursalContract(value);
    }

    function setOptionSizePerTxnLimitPercent(uint256 value) external onlyOwner {
        optionSizePerTxnLimitPercent = value;
        emit UpdateOptionSizePerTxnLimitPercent(value);
    }

    /**
     * @notice Used for adjusting the maxPeriod
     * @param value New maxPeriod
     */
    function setMaxPeriod(uint256 value) external onlyOwner {
        require(
            value >= 5 minutes,
            "MaxPeriod needs to be greater than 5 minutes"
        );
        maxPeriod = value;
        emit UpdateMaxPeriod(value);
    }

    /**
     * @notice Used for adjusting the poolUtilizationLimitPercent with a factor of 100
     * @param value New poolUtilizationLimitPercent
     */
    function setPoolUtilizationLimitPercent(uint256 value) external onlyOwner {
        poolUtilizationLimitPercent = value;
        emit UpdatePoolUtilizationLimitPercent(value);
    }

    /**
     * @notice Used for adjusting the settlement fee percentage with a factor of 100
     * @param value New Settlement Fee Percentage
     */
    function setSettlementFeePercentageForDown(uint256 value)
        external
        onlyOwner
    {
        require(value <= 50e2, "SettlementFeePercentageForDown is too high");
        settlementFeePercentageForDown = value;
        emit UpdateSettlementFeePercentageForDown(value);
    }

    /**
     * @notice Used for adjusting the settlement fee percentage with a factor of 100
     * @param value New Settlement Fee Percentage
     */
    function setSettlementFeePercentageForUp(uint256 value) external onlyOwner {
        require(value <= 50e2, "SettlementFeePercentageForUp is too high");
        settlementFeePercentageForUp = value;
        emit UpdateSettlementFeePercentageForUp(value);
    }

    /**
     * @notice Used for adjusting the staking fee percentage
     */
    function setStakingFeePercentages(
        uint256 _treasuryPercentage,
        uint256 _blpStakingPercentage,
        uint256 _bfrStakingPercentage,
        uint256 _insuranceFundPercentage
    ) external onlyOwner {
        require(
            _treasuryPercentage +
                _blpStakingPercentage +
                _bfrStakingPercentage +
                _insuranceFundPercentage ==
                100,
            "Wrong distribution"
        );
        treasuryPercentage = _treasuryPercentage;
        blpStakingPercentage = _blpStakingPercentage;
        bfrStakingPercentage = _bfrStakingPercentage;
        insuranceFundPercentage = _insuranceFundPercentage;

        emit UpdateStakingFeePercentage(
            treasuryPercentage,
            blpStakingPercentage,
            bfrStakingPercentage,
            insuranceFundPercentage
        );
    }

    /**
     * @notice Used for changing option collateralization ratio
     * @param value New optionCollateralizationRatio value
     */
    function setOptionCollaterizationRatio(uint256 value) external onlyOwner {
        require(50 <= value && value <= 100, "wrong value");
        optionCollateralizationRatio = value;
        emit UpdateOptionCollaterizationRatio(value);
    }

    /**
     * @notice Used for updating utilizationRate value
     * @param value New utilizationRate value
     **/
    function setUtilizationRate(uint256 value) external onlyOwner {
        utilizationRate = value;
    }
}