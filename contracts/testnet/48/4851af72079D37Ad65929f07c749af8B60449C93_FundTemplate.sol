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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";

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

    function _initialize(string memory name_, string memory symbol_) internal {
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library StructLibrary {
    struct Fund {
        bool assetType; // true: 开放式, false: 封闭式
        bool isFixedIncome; // true: 固定, false: 浮动
        // bool compound; // 是否复利
        bool isTransferable; // 基金是否可转让
        bool isIssued; // 是否已发行
        bool canWithdraw; // 是否可以提取
        bool isValid; // 基金是否有效
        // 是否可以退款
        bool canRefund;
        string name; // 基金名称
        string symbol; // 基金代号
        uint8 tokenDecimals; // 代币精度
        uint32 issuanceFee; // 发行费率
        uint256 price; // 基金的单价 精度9
        uint256 startTime; // 开始购买时间
        uint256 durationStartTime; //存续期的开始时间   收益的开始时间
        uint256 duration; // 存续期
        uint256 redemptionEndTime; // 赎回结束时间
        uint256 deadline; // 购买截止时间
        uint256 minRedemptionDays; // 最小赎回天数
        uint256 yield; // 固定收益值
        uint256[] yieldArray; // 浮动收益率数组
        uint256 yieldPeriod; // 收益发放周期
        uint256 managementFee; // 管理费
        uint256 minPurchaseAmount; // 最小购买数量
        uint256 fundTotalSupply; // 基金总量
        address issuer; // 发行人的地址
        address issuerPaymentAddress; // 发行人的收款地址
        address tokenType; // 用户购买基金所使用的代币类型
        // 以下为基金合约的地址
        address fundAddress;
        address msftAddress; // MSFT合约地址
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../libs/ERC20.sol";
import "../libs/SafeMath.sol";
import "../libs/StructLibrary.sol";
import "../libs/TransferHelper.sol";
import "../interfaces/IERC20.sol";

//测试FundTemplate 版本
contract FundTemplate is ERC20 {
    using SafeMath for uint256;
    // 存储基金的详细信息
    StructLibrary.Fund public fund;
    // 存储用户购买基金时所使用的代币
    IERC20 public token;
    // 定义费率单位
    uint32 public constant FEE_UNIT = 1000000000;
    //用户地址
    address[] public userAddress;
    // 工厂合约地址
    address public factoryAddress;
    // 当用户购买基金时触发
    event Purchased(address indexed user, uint256 amount);
    // 当用户赎回基金时触发
    event Redeemed(address indexed user, uint256 amount);
    // 当基金的有效性状态发生变化时触发
    event FundValidityChanged(bool isValid);

    // 仅允许投资者调用的修饰器
    modifier onlyInvestor() {
        require(
            balanceOf(msg.sender) > 0,
            "Only investors can call this function"
        );
        _;
    }
    modifier onlyOwner() {
        require(true, "Only the factory can call this function");
        _;
    }

    constructor() ERC20("Template", "TEMP") {}

    function setFactoryAddress(address _factoryAddress) public {
        factoryAddress = _factoryAddress;
    }

    function initialize(StructLibrary.Fund memory _fund) public onlyOwner {
        fund = _fund;
        _initialize(_fund.name, _fund.symbol);
        fund.fundAddress = address(this);
        token = ERC20(_fund.tokenType);
    }

    // 用户购买基金
    function purchase(uint256 _amount) public {
        require(fund.isValid, "Fund is not valid");
        require(
            _amount <= fund.fundTotalSupply - totalSupply(),
            "Insufficient remaining total supply"
        );
        require(
            block.timestamp >= fund.startTime,
            "Purchase not available yet"
        );
        require(
            _amount >= fund.minPurchaseAmount,
            "Amount is below minimum purchase amount"
        );
        if (!fund.assetType) {
            require(
                (block.timestamp <= fund.deadline),
                "Purchase deadline has passed"
            );
        }
        if (balanceOf(msg.sender) <= 0) {
            userAddress.push(msg.sender);
        }
        uint256 fundPrice = calculateFee(_amount);
        TransferHelper.safeTransferFrom(
            fund.tokenType,
            msg.sender,
            address(this),
            fundPrice
        );
        _mint(msg.sender, _amount);
        emit Purchased(msg.sender, _amount);
    }

    function purchaseByMsft(uint256 _amount, uint256 _msftTokenId) public {
        require(fund.isValid, "Fund is not valid");
        require(
            _amount <= fund.fundTotalSupply - totalSupply(),
            "Insufficient remaining total supply"
        );
        require(
            block.timestamp >= fund.startTime,
            "Purchase not available yet"
        );
        require(
            _amount >= fund.minPurchaseAmount,
            "Amount is below minimum purchase amount"
        );
        if (!fund.assetType) {
            require(
                (block.timestamp <= fund.deadline),
                "Purchase deadline has passed"
            );
        }
        if (balanceOf(msg.sender) <= 0) {
            userAddress.push(msg.sender);
        }
        uint256 fundPrice = calculateFee(_amount);
        TransferHelper.safeTransferFrom(
            fund.tokenType,
            msg.sender,
            address(this),
            fundPrice
        );
        _mint(address(this), _amount);
        //slot增加
        //授权SMFT合约
        approve(fund.msftAddress, balanceOf(address(this)));
        emit Purchased(msg.sender, _amount);
    }

    // 用户赎回基金
    function redeem(uint256 _amount) public onlyInvestor {
        require(fund.isValid, "Fund is not valid");
        if (fund.assetType) {
            require(
                block.timestamp >= fund.minRedemptionDays,
                "Redemption not available yet"
            );
        } else {
            require(
                block.timestamp >=
                    fund.duration +
                        fund.durationStartTime +
                        fund.minRedemptionDays,
                "Redemption not available yet"
            );
        }
        require(
            balanceOf(msg.sender) >= _amount,
            "Insufficient balance for redemption"
        );
        uint256 fundPrice = calculateFee(_amount);
        _burn(msg.sender, _amount);
        TransferHelper.safeTransfer(fund.tokenType, msg.sender, fundPrice);
        emit Redeemed(msg.sender, _amount);
    }

    // 用户赎回基金
    function redeemByMsft(uint256 _amount, uint256 _msftTokenId) public {
        require(fund.isValid, "Fund is not valid");
        if (fund.assetType) {
            require(
                block.timestamp >= fund.minRedemptionDays,
                "Redemption not available yet"
            );
        } else {
            require(
                block.timestamp >=
                    fund.duration +
                        fund.durationStartTime +
                        fund.minRedemptionDays,
                "Redemption not available yet"
            );
        }
        uint256 fundPrice = calculateFee(_amount);
        _burn(address(this), _amount);
        TransferHelper.safeTransfer(fund.tokenType, msg.sender, fundPrice);
        emit Redeemed(msg.sender, _amount);
    }

    function transfer(
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        require(
            block.timestamp > fund.durationStartTime,
            "Transfer not available yet"
        );
        require(fund.isTransferable, "Fund is not transferable");
        return super.transfer(_to, _amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        require(
            block.timestamp > fund.durationStartTime,
            "Transfer not available yet"
        );
        require(fund.isTransferable, "Fund is not transferable");
        return super.transferFrom(_from, _to, _amount);
    }

    // 用户直接退款
    function refund(uint256 _msftTokenId) public onlyInvestor {
        require(!fund.isValid, "Fund is not valid");
        require(fund.canRefund, "Refund not available yet");
        uint256 amount = balanceOf(msg.sender);
        if (amount > 0) {
            _burn(msg.sender, amount);
        }
        uint256 fundPrice = calculateFee(amount);
        TransferHelper.safeTransfer(fund.tokenType, msg.sender, fundPrice);
        emit Redeemed(msg.sender, amount);
    }

    // 基金发行人可以管理是否可以退款
    function setCanRefund(bool _canRefund) public {
        require(
            msg.sender == fund.issuer,
            "Only the issuer can call this function"
        );
        fund.canRefund = _canRefund;
    }

    // 基金发行人可以提取资产
    function withdrawByIssuer(uint256 _amount) public {
        require(msg.sender == fund.issuer, "Only the issuer can withdraw");
        require(
            fund.canWithdraw && fund.issuerPaymentAddress != address(0),
            "Can not withdraw"
        );
        TransferHelper.safeTransfer(
            fund.tokenType,
            fund.issuerPaymentAddress,
            _amount
        );
    }

    //管理员根据收益率计算净值
    function setPrice(uint256 _yield) public {
        require(
            msg.sender == fund.issuer || msg.sender == factoryAddress,
            "Only the issuer or owner can call this function"
        );
        require(_yield > 0, "Yield must be greater than 0");
        fund.price = _yield.mul(fund.price).div(FEE_UNIT).add(fund.price);
        fund.yieldArray.push(_yield);
    }

    // 管理员可以设置发行费率
    function setIssuanceFee(uint32 _issuanceFee) public onlyOwner {
        fund.issuanceFee = _issuanceFee;
    }

    // 管理员可以设置基金是否有效
    function setFundValidity(bool _isValid) public onlyOwner {
        fund.isValid = _isValid;
        emit FundValidityChanged(_isValid);
    }

    // 管理员可以设置发行方收款人地址
    function setIssuerPaymentAddress(
        address _newPaymentAddress
    ) public onlyOwner {
        fund.issuerPaymentAddress = _newPaymentAddress;
    }

    // 管理员可以设置发行方是否可以收款
    function setCanWithdraw(bool _canWithdraw) public onlyOwner {
        fund.canWithdraw = _canWithdraw;
    }

    function calculateFee(uint256 _amount) private view returns (uint256) {
        return
            _amount
                .mul(10 ** fund.tokenDecimals)
                .div(10 ** decimals())
                .mul(fund.price)
                .div(FEE_UNIT);
    }

    // 获取用户地址
    function getUserAddress() public view returns (address[] memory) {
        return userAddress;
    }

    // 存储 FundFactory 合约的地址
    // IFundFactory public fundFactory;
    // fundFactory = IFundFactory(msg.sender);
    // 管理员计算用户的基金收益
    // function calculateFundEarnings(uint256 _yield) public {
    //     require(
    //         msg.sender == fund.issuer || msg.sender == owner(),
    //         "Only the issuer or owner can call this function"
    //     );
    //     if (time == 0) {
    //         time = fund.durationStartTime;
    //     }
    //     require(time + fund.yieldPeriod <= block.timestamp, "The time has not arrived");
    //     require(_yield > 0, "Yield must be greater than 0");
    //     require(fund.isValid, "Fund is not valid");
    //     time = block.timestamp;
    //     if (fund.isFixedIncome) {
    //         _yield = fund.yield;
    //     } else {
    //         fund.yieldArray.push(_yield);
    //     }
    //     for (uint256 i = 0; i < userAddress.length; i++) {
    //         StructLibrary.UserInfo storage user = userInfo[userAddress[i]];
    //         if (balanceOf(userAddress[i]) <= 0) {
    //             continue;
    //         }
    //         uint256 purchaseAmount = user.purchaseAmount;
    //         uint256 yieldAmount = 0;
    //         yieldAmount = calculateEarnings(purchaseAmount, _yield, user.yieldAmount);
    //         user.yieldAmount += yieldAmount;
    //         user.purchaseTime = block.timestamp;
    //         _mint(userAddress[i], yieldAmount);
    //     }
    // }

    // //收益计算
    // function calculateEarnings(
    //     uint256 _purchaseAmount,
    //     uint256 _yield,
    //     uint256 _yieldAmount
    // ) private view returns (uint256) {
    //     uint256 yieldAmount = 0;
    //     if (fund.compound) {
    //         yieldAmount = (_yieldAmount.add(_purchaseAmount)).div(FEE_UNIT).mul(_yield);
    //     } else {
    //         yieldAmount = _purchaseAmount.div(FEE_UNIT).mul(fund.yield);
    //     }
    //     return yieldAmount;
    // }

    // struct UserInfo {
    //     bool isExist; // 用户是否存在
    //     uint256 purchaseAmount; // 购买的基金数量
    //     uint256 yieldAmount; // 收益数量
    //     uint256 purchaseTime; //计算收益时间
    // }
    //收益计算
    // StructLibrary.UserInfo storage user = userInfo[msg.sender];
    // user.purchaseAmount += _amount;
    // user.purchaseTime = block.timestamp;
    // if (!user.isExist) {
    //     userAddress.push(msg.sender);
    //     user.isExist = true;
    //     //user.index = userAddress.length - 1;
    // }

    //赎回是本金大于等于购买金额时，清空收益，否则减去赎回金额
    // if (_amount >= user.purchaseAmount) {
    //     fund.fundTotalSupply += user.purchaseAmount;
    //     user.purchaseAmount = balanceOf(msg.sender) - _amount;
    //     user.yieldAmount = 0;
    //     if (user.purchaseAmount == 0) {
    //         user.isExist = false;
    //     }
    // } else {
    //     user.purchaseAmount -= _amount;
    //     fund.fundTotalSupply += _amount;
    // }
    // 管理员提取平台的手续费
    // function withdrawByOwner() public onlyOwner {
    //     uint256 platformFee = tokenTotal.div(FEE_UNIT).mul(fund.issuanceFee).sub(platformEarnings);
    //     require(platformFee > 0, "No income withdrawal for the time being");
    //     require(platformFee <= token.balanceOf(address(this)), "Insufficient balance");
    //     platformEarnings += platformFee;
    //     TransferHelper.safeTransfer(
    //         fund.tokenType,
    //         fundFactory.getPlatformFeeAddress(),
    //         platformFee
    //     );
    // }
}