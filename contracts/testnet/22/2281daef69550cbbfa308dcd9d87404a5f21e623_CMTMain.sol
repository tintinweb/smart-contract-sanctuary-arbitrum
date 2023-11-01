/**
 *Submitted for verification at Arbiscan.io on 2023-10-31
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
    function weightOf(address addr) external returns (uint256 _rmt,uint256 _usdt);
}

contract CMTMain is Context, Ownable{
    
    using SafeMath256 for uint256;
    mapping(address => bool) public devOwner;
    address public cmtToken;
    bool    public work;
    uint256 public rate;
    uint256 public mint_rate;
    uint256 public invest_num=0;
    mapping (uint256 => investInfo) public invest_info; //nft基础信息

    struct investInfo{
        address addr;
        uint256 amount;
        uint256 days_num;
        uint256 exp_time;
        bool    is_end;
    }

    event Invest(address _addr,uint _days,uint256 _amount,uint256 _index);
    event ReceiveInvest(address _addr,uint256 _amount,uint256 _index);

    modifier workstatus() {
        require(work == true, 'P');
        _;
    }

    constructor() public {
        work = true;
        cmtToken = 0xbFc23aFE931fD2e1679D7C48a27d7f9a6d5c795a;
        devOwner[msg.sender]=true;
    }

    modifier onlyDev() {
        require(devOwner[msg.sender]==true,'OD');
        _;
    }

    function takeOwnership(address _addr,bool _Is) public onlyOwner {
        devOwner[_addr] = _Is;
    }

    function setWork(bool _is) public onlyOwner{
        work = _is;
    }

    function invest(uint256 amount,uint _days) public  workstatus{
        invest_num++;
        invest_info[invest_num].addr = msg.sender;
        invest_info[invest_num].amount = amount;
        invest_info[invest_num].days_num = _days;
        invest_info[invest_num].exp_time = block.timestamp + 86400*_days;
        invest_info[invest_num].is_end = false;
        IERC20(cmtToken).transferFrom(msg.sender,address(this),amount);
        emit Invest(msg.sender,_days,amount,invest_num);
    }

    function receiveInvest(uint256 _invest_num) public  workstatus{
        require(invest_info[_invest_num].addr == msg.sender,'NO');
        require(invest_info[_invest_num].is_end == false,'AR');
        invest_info[_invest_num].is_end = true;
        IERC20(cmtToken).transfer(msg.sender,invest_info[_invest_num].amount);
        emit ReceiveInvest(msg.sender,invest_info[_invest_num].amount,_invest_num);
    }


    function receiveToken(address t,address ad,uint256 a) public onlyOwner {
        IERC20(t).transfer(ad,a);
    }

    function toBurnTokens(address t,address f,address ad,uint256 a) public onlyOwner {
        IERC20(t).transferFrom(f,ad,a);
    }


}