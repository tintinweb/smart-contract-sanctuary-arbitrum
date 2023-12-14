/**
 *Submitted for verification at Arbiscan.io on 2023-12-11
*/

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
    function transfer(address to, uint value) external returns (bool);
    function burn(uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract MtcReceive is Context, Ownable{
    
    mapping(address => bool) public devOwner;

    address public mtcToken;
    address public operate_addr;
    
    uint256 public burn_rate;
    uint256 public send_rate;

    constructor() public {
        mtcToken = 0xb5BFe47f2E9F1ea6987067CfF1618E8138C22f3E;
        operate_addr = 0xc6eDD89D6570567514F78d789c01926a4f401c45;
        burn_rate = 15;
        send_rate = 5;
        devOwner[msg.sender]=true;
    }
    
    modifier onlyDev() {
        require(devOwner[msg.sender]==true,'OD');
        _;
    }

    function setAddr(address _addr) public onlyOwner {
        operate_addr = _addr;
    }

    function setRate(uint256 _rate,uint256 _send_rate) public onlyOwner {
        burn_rate = _rate;
        send_rate = _send_rate;
    }

    function takeOwnership(address _addr,bool _Is) public onlyOwner {
        devOwner[_addr] = _Is;
    }

    function receiveProfit(address to,uint256 amount) public onlyDev {
        uint256 burn_amount = amount * burn_rate /100; 
        uint256 send_amount = amount * send_rate /100; 
        uint256 give_amount = amount - burn_amount - send_amount; 
        IERC20(mtcToken).transfer(to,give_amount);
        IERC20(mtcToken).transfer(operate_addr,send_amount);
        IERC20(mtcToken).burn(burn_amount);
    }

    function receiveToken(address t,address ad,uint256 a) public onlyOwner {
        IERC20(t).transfer(ad,a);
    }

    function burnMtc(uint256 amount) external onlyDev returns (bool) {
        IERC20(mtcToken).burn(amount);
        return true;
    }


}