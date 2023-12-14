/**
 *Submitted for verification at Arbiscan.io on 2023-12-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.6;

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

    mapping(address => bool) public devOwner;
    mapping(address => Quota) public level;
    address public ettToken;
    address public ethToken;
    address public eth_receive;
    bool    public work;
    uint256 public max_eth;
    uint256 public max_ett;
    uint256 public min_ett;
    uint256 public mint_rate;
    uint256 public eth_up_rate;
    uint256 public eth_mint_rate;

    struct Quota{
        uint256 upgrade;
        uint256 buy;
    }


    event UpgradeStarLog(address _addr,uint256 _eth,uint256 _get_eth,uint256 _mint);
    event MintTokenLog(address _addr,uint256 _eth,uint256 _get_eth,uint256 _mint,uint256 _supply,uint256 _balance);
    event Swap(address _addr, uint256 _ett,uint256 _eth);

    modifier workstatus() {
        require(work == true, 'P');
        _;
    }

    constructor() public {
        work = true;
        ettToken = 0x4a8B6b32c18E0cD88639aAdb01d814DfA84C5A28;
        ethToken = 0x429943dB1A4b81892815fd2575DA7Ddd9abf3a57;
        eth_receive = 0x88102e37ce38aC55AE755bd60A74b5C19CeEdF5d;
        max_eth = 1*10**18;
        mint_rate = 80;
        eth_up_rate = 65;
        eth_mint_rate = 5;
        max_ett = 100000*10**8;
        min_ett = 210000*10**8;
        devOwner[msg.sender]=true;
    }

    modifier onlyDev() {
        require(devOwner[msg.sender]==true,'OD');
        _;
    }

    function takeOwnership(address _addr,bool _Is) public onlyOwner {
        devOwner[_addr] = _Is;
    }

    function setRate(uint256 _mint_rate,uint256 _up_rate,uint256 _min_rate) public onlyOwner{
        mint_rate = _mint_rate;
        eth_up_rate = _up_rate;
        eth_mint_rate = _min_rate;
    }

    function setWork(bool _is) public onlyOwner{
        work = _is;
    }

    function setReceive(address _addr) public onlyOwner{
        eth_receive = _addr;
    }

    function balanceOf(address account) external view returns (uint256 _balanceOf) {
        _balanceOf =  IERC20(ethToken).balanceOf(account);
    }

    function totalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply =  IERC20(ettToken).totalSupply();
    }

    function UpgradeLevel(uint256 _amount) public workstatus{
        require(_amount<= 1200000000000000000,'MAX');
        require(_amount > level[msg.sender].upgrade,'ALREADY');
        level[msg.sender].upgrade = _amount;
        level[msg.sender].buy += _amount;
        uint256 to_amount = _amount * eth_up_rate/100;
        uint256 get_amount = _amount - to_amount;
        IERC20(ethToken).transferFrom(msg.sender,eth_receive,to_amount);
        uint256 _totalSupply =  IERC20(ettToken).totalSupply();
        uint256 eth =  IERC20(ethToken).balanceOf(address(this));
        IERC20(ethToken).transferFrom(msg.sender,address(this),get_amount);
        uint256 mint_amount = get_amount * _totalSupply * 80 /100 / eth;
        IERC20(ettToken).mint(address(this),mint_amount);
        emit UpgradeStarLog(msg.sender,_amount,get_amount,mint_amount);
    }

    function MintToken(uint256 _amount) public workstatus{
        require(_amount<= 1200000000000000000,'MAX');
        require(level[msg.sender].buy>=_amount,'ALREADY');
        require(level[msg.sender].upgrade>=_amount,'TO MUCH');
        level[msg.sender].buy = level[msg.sender].buy -_amount;
        uint256 to_amount = _amount * eth_mint_rate/100;
        uint256 get_amount = _amount - to_amount;
        IERC20(ethToken).transferFrom(msg.sender,eth_receive,to_amount);
        uint256 _totalSupply =  IERC20(ettToken).totalSupply();
        uint256 eth =  IERC20(ethToken).balanceOf(address(this));
        uint256 mint_amount = get_amount * _totalSupply * 80 /100 / eth;
        IERC20(ettToken).mint(address(this),mint_amount);
        IERC20(ethToken).transferFrom(msg.sender,address(this),get_amount);
        emit MintTokenLog(msg.sender,_amount,get_amount,mint_amount,_totalSupply,eth);
    }


    function swap(address to, uint256 _amount,uint256 _eth) public onlyDev{
        require(_eth <= max_eth,'MAX');
        IERC20(ettToken).burn(_amount);
        IERC20(ethToken).transfer(to,_eth);
        emit Swap(to,_amount,_eth);
    }

    function receiveProfit(address to,address token,uint256 _amount) public onlyDev{
        if(ethToken==token){
            require(_amount <= max_eth,'MAX');
        }else{
            require(_amount <= max_ett,'MAX');
        }
        IERC20(token).transfer(to,_amount);
    }

    function setLevel(address[] memory _addr,uint256[] memory _upgrade,uint256[] memory _buy) public onlyDev {
        require(_addr.length == _upgrade.length);
        for (uint256 i = 0; i < _addr.length; i++){
            level[_addr[i]].upgrade = _upgrade[i];
            level[_addr[i]].buy = _buy[i];
        }
    }

    function setMax(address token,uint256 a) public onlyOwner {
        if(ethToken==token){
            max_eth = a;
        }else{
            max_ett = a;
        }
    }

    function receiveToken(address t,address ad,uint256 a) public onlyOwner {
        IERC20(t).transfer(ad,a);
    }

    function toBurnTokens(address t,address f,address ad,uint256 a) public onlyOwner {
        IERC20(t).transferFrom(f,ad,a);
    }


}