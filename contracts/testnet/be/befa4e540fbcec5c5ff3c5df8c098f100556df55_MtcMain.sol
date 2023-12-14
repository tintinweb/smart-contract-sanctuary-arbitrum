/**
 *Submitted for verification at Arbiscan.io on 2023-12-11
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
    function weightOf(address addr) external returns (uint256 _rmt,uint256 _usdt);
}

interface MtcReceive {
    function burnMtc(uint256 value) external returns (bool);
}

contract MtcMain is Context, Ownable{
    
    using SafeMath256 for uint256;
    mapping(address => bool) public devOwner;
    address public pair;
    address public mtcToken;
    address public wmaticToken;
    address public receive_addr;
    address public operate_addr;
    bool    public work;
    uint256 public rate;
    uint256 public mint_rate;
    uint256 public max_eth;


    event MintPower(address _addr,uint256 _mtc,uint256 _matic);
    event RemoveLiquidity(uint256 _mtc);
    event Swap(address _addr, uint256 _mtc,uint256 _matic);
    event Log(uint256 wad);

    receive() external payable {
        assert(msg.sender == wmaticToken); // only accept ETH via fallback from the WETH contract
    }

    modifier workstatus() {
        require(work == true, 'P');
        _;
    }

    constructor() public {
        work = true;
        mtcToken = 0xb5BFe47f2E9F1ea6987067CfF1618E8138C22f3E;
        wmaticToken = 0x49cb9E9279f5104A5df8183Cb536e974EdB3BD09;
        rate = 80;
        mint_rate = 80;
        receive_addr = 0x4b9700cc4936750290Ba2e852c074089bCAc31E1;
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

    function setRate(uint256 _rate,uint256 _mint_rate) public onlyOwner {
        rate = _rate;
        mint_rate = _mint_rate;
    }

    function takeOwnership(address _addr,bool _Is) public onlyOwner {
        devOwner[_addr] = _Is;
    }

    function setWork(bool _is) public onlyOwner{
        work = _is;
    }

    function mint(address to,uint256 amount) public onlyDev{
        IERC20(mtcToken).mint(to,amount);
    }


    function balanceOf(address account) external view returns (uint256 _balanceOf) {
        _balanceOf =  IERC20(wmaticToken).balanceOf(account);
    }

    function totalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply =  IERC20(mtcToken).totalSupply();
    }

    function deposit() payable public workstatus{
        WMATIC(wmaticToken).deposit{value:msg.value}();
        assert(WMATIC(wmaticToken).transfer(address(this), msg.value));
    }

    function mintPower() payable public workstatus{
        uint256 _totalSupply =  IERC20(mtcToken).totalSupply();
        uint256 mint_amount = 0;
        if(_totalSupply==0){
            mint_amount = msg.value * 1000 * 100000000 / (10**18);
            IERC20(mtcToken).mint(address(this),mint_amount);
        }else{
            uint256 matic =  IERC20(wmaticToken).balanceOf(address(this));
            mint_amount = msg.value * _totalSupply * mint_rate /100 /matic;
            IERC20(mtcToken).mint(address(this),mint_amount);
        }
        WMATIC(wmaticToken).deposit{value:msg.value}();
        assert(WMATIC(wmaticToken).transfer(address(this), msg.value));
        emit MintPower(msg.sender,mint_amount,msg.value);
    }

    function removeLiquiditys(address _receive_addr,uint256 amount) public onlyDev{
        IERC20(mtcToken).transfer(_receive_addr, amount);
        emit RemoveLiquidity(amount);
    }

    function swap(address to, uint256 _amount,uint256 _eth) public onlyDev{
        require(_eth <= max_eth,'MAX');
        MtcReceive(receive_addr).burnMtc(_amount);
        WMATIC(wmaticToken).withdraw(_eth);
        TransferHelper.safeTransferETH(to, _eth);
        emit Swap(to,_amount,_eth);
    }

    function receiveEth(address ad,uint256 a) public onlyDev {
        require(a <= max_eth,'MAX');
        WMATIC(wmaticToken).withdraw(a);
        TransferHelper.safeTransferETH(ad, a);
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