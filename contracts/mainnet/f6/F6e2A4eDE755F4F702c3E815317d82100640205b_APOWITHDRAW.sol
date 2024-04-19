/**
 *Submitted for verification at Arbiscan.io on 2024-04-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract APOFACTORY is Ownable {
    using SafeMath for uint256;

    APOWITHDRAW  _apowithdraw;

    constructor(address withdraw_){
        _apowithdraw = APOWITHDRAW(withdraw_);
    }

    uint256 public mineStartTime = block.timestamp;
    //ARBmain
    // IERC20 private UAPO = IERC20(0xC9F10A33fae73cc6b79fC17Db1A7d21F8c9C74Be);
    // IERC20 private APOS = IERC20(0x075b2F58A3cba918F6410d8c16b8E1b9541D37c3);
    // IERC20 private APOY = IERC20(0x83681399b7f6f4065e28A740Abd40534DC3C5F42);
    // IERC20 private USDT = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    //godemain
    IERC20 private UAPO = IERC20(0xa567E92E17DE15857A5f517494a877C6E35ab94c);
    IERC20 private APOS = IERC20(0x2A4B43c7bD5883A6C9C2b4a8174Df7C397e093e7);
    IERC20 private APOY = IERC20(0x1682CA3B282A5969432B4a5A2675BE6b43221D4c);
    IERC20 private USDT = IERC20(0xA82497eD463Bcf08D17b2c776421fb944ab35C27);

    uint256 private uapo_min = 8000 * (10**18);
    uint256 private apos_min = 8000 * (10**18);
    uint256 private apoy_min = 8000 * (10**18);
    uint256 private usdt_min = 8000 * (10**6);

    uint256 private uapo_amount = 2000 * (10**18);
    uint256 private apos_amount = 2000 * (10**18);
    uint256 private apoy_amount = 2000 * (10**18);
    uint256 private usdt_amount = 2000 * (10**6);

    mapping (address => uint256) public booking;

    receive() external payable {}

    function withdraw(uint256 amount) public {

        if(UAPO.balanceOf(address(_apowithdraw)) < uapo_min && UAPO.balanceOf(address(this)) > 0){
            if(UAPO.balanceOf(address(this)) < uapo_amount){
                UAPO.transfer(address(_apowithdraw), UAPO.balanceOf(address(this)));
            }else{
                UAPO.transfer(address(_apowithdraw), uapo_amount);
            }
        }
        if(APOS.balanceOf(address(_apowithdraw)) < apos_min && APOS.balanceOf(address(this)) > 0){
            if(APOS.balanceOf(address(this)) < apos_amount){
                APOS.transfer(address(_apowithdraw), APOS.balanceOf(address(this)));
            }else{
                APOS.transfer(address(_apowithdraw), apos_amount);
            }
        }
        if(APOY.balanceOf(address(_apowithdraw)) < apoy_min && APOY.balanceOf(address(this)) > 0){
            if(APOY.balanceOf(address(this)) < apoy_amount){
                APOY.transfer(address(_apowithdraw), APOY.balanceOf(address(this)));
            }else{
                APOY.transfer(address(_apowithdraw), apoy_amount);
            }
        }
        if(USDT.balanceOf(address(_apowithdraw)) < usdt_min && USDT.balanceOf(address(this)) > 0){
            if(USDT.balanceOf(address(this)) < usdt_amount){
                USDT.transfer(address(_apowithdraw), USDT.balanceOf(address(this)));
            }else{
                USDT.transfer(address(_apowithdraw), usdt_amount);
            }
        }

        booking[msg.sender] += amount;
    }

    function setUAPO(address wallet)public onlyOwner{
        UAPO = IERC20(wallet);
    }
    function setAPOY(address wallet)public onlyOwner{
        APOY = IERC20(wallet);
    }
    function setAPOS(address wallet)public onlyOwner{
        APOS = IERC20(wallet);
    }
    function setUSDT(address wallet)public onlyOwner{
        USDT = IERC20(wallet);
    }

    function setUapomin(uint256 amount)public onlyOwner{
        uapo_min = amount;
    }
    function setAposmin(uint256 amount)public onlyOwner{
        apos_min = amount;
    }
    function setApoymin(uint256 amount)public onlyOwner{
        apoy_min = amount;
    }
    function setUsdtmin(uint256 amount)public onlyOwner{
        usdt_min = amount;
    }
    
    function setUapoAmount(uint256 amount)public onlyOwner{
        uapo_amount = amount;
    }
    function setAposAmount(uint256 amount)public onlyOwner{
        apos_amount = amount;
    }
    function setApoyAmount(uint256 amount)public onlyOwner{
        apoy_amount = amount;
    }
    function setUsdtAmount(uint256 amount)public onlyOwner{
        usdt_amount = amount;
    }

    function bep20TransferFrom(address tokenContract , address recipient, uint256 amount) public onlyOwner{
        if(tokenContract == address(0)){
          payable(address(recipient)).transfer(amount);
          return;
        }
        IERC20  bep20token = IERC20(tokenContract);
        bep20token.transfer(recipient,amount);
        return;
    }

}

contract APOWITHDRAW{
    address private _owner;
    address private _operator;
    constructor(address owner,address operator){
        _owner = owner;
        _operator = operator;
    }

    function transfer(address token,address recipient, uint256 amount) public {
        require(msg.sender == _operator,"Permission denied");
        IERC20(token).transfer(recipient,amount);

    }
    function setOperator(address wallet)public {
        require(msg.sender == _owner,"Permission denied");
        _operator = wallet;
    }
    function bep20TransferFrom(address tokenContract , address recipient, uint256 amount) public{
        require(msg.sender == _owner,"Permission denied");
        if(tokenContract == address(0)){
          payable(address(recipient)).transfer(amount);
          return;
        }
        IERC20  bep20token = IERC20(tokenContract);
        bep20token.transfer(recipient,amount);
        return;
    }
}