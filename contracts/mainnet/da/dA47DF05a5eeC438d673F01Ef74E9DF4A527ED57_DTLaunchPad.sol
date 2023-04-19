// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/math/SafeMath.sol";
import "./Ownable.sol";

contract DTLaunchPad is Ownable {
    using SafeMath for uint256;
    uint256 private constant USDC_DECIMAL = 10 ** 18; // target USDC
    uint256 private constant TARGET_USDC = 1000000; // target USDC
    uint256 private constant TOTAL_DISTRIBUTION = 100;
    uint256 private constant A_PERCENTAGE = 50; // 50% Liquidity Pool
    uint256 private constant B_PERCENTAGE = 35; // 35% Liquidity Vault
    uint256 private constant C_PERCENTAGE = 15; // 15% Team Development

    address private constant USDC_ADDRESS =
        0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // USDC token contract address

    address private constant WALLET_A =
        0xeA069B5d627deE8E0881E50600b38eCB9D3c6f9E; // Liquidity Pool address
    address private constant WALLET_B =
        0x99142456720DE2BAd95d7a3FB853b28d1947EB18; // Liquidity Vault address
    address private constant WALLET_C =
        0xA8F6a9717311943ec0cb1634b440D20470057b27; // Team Development address

    uint256 public totalDeposited; // Total deposited USDC

    mapping(address => uint256) public depositedAmounts; // participant's deposited amount
    event depositEvent(
        uint256 amountToA,
        uint256 usdc_amount,
        uint256 A_PERCENTAGE
    );
    event distributeBalanceEvent(uint256 balance, uint256 result);
    event distributeBalanceToWalletEvent(
        uint256 wallet1Amount,
        uint256 A_PERCENTAGE,
        uint256 contractBalanceMulPercentage,
        uint256 result
    );

    function deposit(uint256 amount) external {
        require(amount >= 10, "Amount must be greater than 10");
        IERC20 usdc = IERC20(USDC_ADDRESS);
        uint256 usdc_amount = amount * USDC_DECIMAL;
        require(
            usdc.transferFrom(msg.sender, address(this), usdc_amount),
            "USDCDistribution: Transfer failed"
        );
        totalDeposited = totalDeposited.add(usdc_amount);

        depositedAmounts[msg.sender] = depositedAmounts[msg.sender].add(
            usdc_amount
        );
        uint256 amountToA = (usdc_amount * A_PERCENTAGE) / TOTAL_DISTRIBUTION;
        uint256 amountToB = (usdc_amount * B_PERCENTAGE) / TOTAL_DISTRIBUTION;
        uint256 amountToC = (usdc_amount * C_PERCENTAGE) / TOTAL_DISTRIBUTION;
        emit depositEvent(amountToA, usdc_amount, A_PERCENTAGE);

        require(
            usdc.transfer(WALLET_A, amountToA),
            "USDCDistribution: Transfer to Wallet A failed"
        );
        require(
            usdc.transfer(WALLET_B, amountToB),
            "USDCDistribution: Transfer to Wallet B failed"
        );
        require(
            usdc.transfer(WALLET_C, amountToC),
            "USDCDistribution: Transfer to Wallet C failed"
        );
    }

    function getTotalDeposited() external view returns (uint256) {
        return totalDeposited;
    }

    function getDepositedAmount(address account) public view returns (uint256) {
        return depositedAmounts[account];
    }

    function getContractBalance() public view returns (uint256) {
        return IERC20(USDC_ADDRESS).balanceOf(address(this)) / USDC_DECIMAL;
    }

    function distributeBalance() public onlyOwner {
        IERC20 usdc = IERC20(USDC_ADDRESS);
        uint256 balance = usdc.balanceOf(address(this));
        emit distributeBalanceEvent(balance, balance / USDC_DECIMAL);

        require(balance / USDC_DECIMAL > 0, "Contract balance is zero");
        uint256 contractBalance = balance;
        uint256 wallet1Amount = contractBalance.mul(A_PERCENTAGE) /
            TOTAL_DISTRIBUTION;
        uint256 wallet2Amount = contractBalance.mul(B_PERCENTAGE) /
            TOTAL_DISTRIBUTION;
        uint256 wallet3Amount = contractBalance.mul(C_PERCENTAGE) /
            TOTAL_DISTRIBUTION;
        emit distributeBalanceToWalletEvent(
            wallet1Amount,
            A_PERCENTAGE,
            contractBalance.mul(A_PERCENTAGE),
            contractBalance.mul(A_PERCENTAGE) / TOTAL_DISTRIBUTION
        );
        require(usdc.transfer(WALLET_A, wallet1Amount), "USDC transfer failed");
        require(usdc.transfer(WALLET_B, wallet2Amount), "USDC transfer failed");
        require(usdc.transfer(WALLET_C, wallet3Amount), "USDC transfer failed");
    }

    // incase above function fail
    function withdrawUSDC() public onlyOwner {
        IERC20 usdc = IERC20(USDC_ADDRESS);
        uint256 balance = usdc.balanceOf(address(this));
        require(balance > 0, "No USDC to withdraw");
        require(usdc.transfer(owner(), balance), "USDC withdrawal failed");
    }
}

// SPDX-License-Identifier: MIT

// pragma solidity 0.6.12;
pragma solidity >=0.4.22 <0.9.0;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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