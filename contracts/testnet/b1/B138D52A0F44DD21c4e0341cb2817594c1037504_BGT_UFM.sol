/**
 *Submitted for verification at Arbiscan on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
}

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) return a;
        return b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >=0 && b>=0, "SafeMath: Cannot have negative numbers");
        if (a <= b) return a;
        return b;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface StakingBGT {

    function postSuperAddress(address super_) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
 
    function claimInterest() external;

    function getInterest(address account) external view returns (uint256);
}

struct Fp {
    uint256 fpId;
    uint256 day;
    uint256 annualInterestRate;
    uint256 quantity;
    uint256 quantity_sold;
}

struct Order {
    uint256 orderId;
    uint256 fpId;
    uint256 amount;
    uint256 interest;
    address sender;
    uint time;
    uint status;
}

// address constant finance = 0xf7457cE2628Cb32C1450f742D34f3109E31fc5F3;
address constant finance = 0x194ad74EB7BC6b46b98f0d3cdA9B643eC0c6C0Fc;

contract BGT_UFM {

    address private _owner;
    address private _admin;
    StakingBGT private _staking;
    IERC20 private  _bgt;
    mapping (uint256 => Order) _orders;
    uint256 _autoOrderIds;

    mapping(uint256 => Fp) _fps;
    uint256 public _aufoFpIds;

    event registered_fp(uint256 indexed fpId, uint256 day, uint256 annualInterestRate, uint256 fp_quantity, uint256 fp_quantity_sold);
    event update_fp(uint256 indexed fpId, uint256 fp_quantity, uint256 fp_quantity_sold);
    event Buy(uint256 indexed orderId, uint256 indexed fpId, address indexed sender, uint256 amount);
    event Settlement(uint256 indexed orderId, uint256 indexed fpId, address indexed sender, uint256 amount, uint256 interest);

    constructor (address __bgt, address __staking) {
        _owner = msg.sender;
        _bgt = IERC20(__bgt);
        _staking = StakingBGT(__staking);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(_owner == msg.sender || _admin == msg.sender, "Ownable: caller is not the admin");
        _;
    }

    function setAdmin(address __admin) external onlyOwner {
        _admin = __admin;
    }

    function registeredFp(uint256 day, uint256 __annualInterestRate, uint256 __fp_quantity) external onlyAdmin {
        _aufoFpIds++;
        _fps[_aufoFpIds] = Fp(_aufoFpIds, day, __annualInterestRate, __fp_quantity, 0);
        emit registered_fp(_aufoFpIds, day, __annualInterestRate, __fp_quantity, 0);
    }

    function addAllowance(uint256 __fp_id, uint256 __fp_quantity) external onlyAdmin {
        require(_fps[__fp_id].fpId > 0, "Financial packages do not exist");
        _fps[__fp_id].quantity += __fp_quantity;
        emit update_fp(__fp_id, _fps[__fp_id].quantity, _fps[__fp_id].quantity_sold);
    }

    function decAllowance(uint256 __fp_id, uint256 __fp_quantity) external onlyAdmin {
        require(_fps[__fp_id].fpId > 0, "Financial packages do not exist");
        if (_fps[__fp_id].quantity >= _fps[__fp_id].quantity_sold + __fp_quantity)
        {
            _fps[__fp_id].quantity -= __fp_quantity;
        }
        else
        {
            _fps[__fp_id].quantity = _fps[__fp_id].quantity_sold;
        }
        emit update_fp(__fp_id,  _fps[__fp_id].quantity, _fps[__fp_id].quantity_sold);
    }

    function buy(uint256 __fp_id, uint256 __amount) external {
        require(_fps[__fp_id].quantity >= _fps[__fp_id].quantity_sold + __amount, "Financial package inventory is insufficient");
        _fps[__fp_id].quantity_sold += __amount;

        _bgt.transferFrom(msg.sender, address(this), __amount);
        _bgt.approve(address(_staking), __amount);
        _staking.deposit(__amount);

        _autoOrderIds++;
        _orders[_autoOrderIds] = Order(_autoOrderIds, __fp_id, __amount, 0, msg.sender, block.timestamp, 0);

        emit Buy(_autoOrderIds, __fp_id, msg.sender, __amount);
        emit update_fp(__fp_id, _fps[__fp_id].quantity, _fps[__fp_id].quantity_sold);
    }

    function settlement(uint256 __order_id) external {
        Order storage _order = _orders[__order_id];
        require(_order.status == 0, "order error");
        require(_order.sender == msg.sender, "error");
        uint256 cycle = _fps[_order.fpId].day * (1 days);
        require(_order.time + cycle <= block.timestamp, "Not due yet");

        _staking.claimInterest();
        _bgt.transfer(finance,  _bgt.balanceOf(address(this)));

        _staking.withdraw(_order.amount);
        _bgt.transfer(_order.sender,  _order.amount);

        _order.interest = this.getFpInterest(_order.orderId, _order.sender);
        _bgt.transferFrom(finance, _order.sender,  _order.interest);
        _order.status = 1;

        emit Settlement(__order_id, _order.fpId, _order.sender,  _order.amount, _order.interest);
    }

    function getFpInterest(uint256 __order_id, address sender) external view returns (uint256) {
        Order storage _order = _orders[__order_id];
        require(_order.sender == sender, "No permission");
        Fp storage _fp = _fps[_order.fpId];
        uint256 cycle = _fps[_order.fpId].day * (1 days);
        uint256 elapsedTime = SafeMath.min(block.timestamp - _order.time, cycle);
        uint256 interest = _order.amount * elapsedTime * _fp.annualInterestRate / 100 / (365 days);
        return interest;
    }

    function getInterest() external view returns (uint256) {
        return _staking.getInterest(address(this));
    }

    //---------//
    function __testDayAdvance(uint256 __order_id, uint day) external {
        Order storage _order = _orders[__order_id];
        _order.time -=  day * (1 days);
    }
}