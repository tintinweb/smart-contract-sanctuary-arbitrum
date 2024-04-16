/**
 *Submitted for verification at Arbiscan.io on 2024-04-16
*/

pragma solidity 0.8.6;
// SPDX-License-Identifier: MIT
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}
contract RunesClaim is ReentrancyGuard{

    bool canclaim;
    address owner;
    address runestoken;

    mapping (address => uint) claimquota;
    mapping (address => bool) isclaim;

    constructor (address token){
        owner = msg.sender;
        runestoken = token;
    }

    modifier onlyOwner() { 
        require(msg.sender == owner, "Only Owner"); 
        _; 
    }

    function claimrunes() external nonReentrant{

        require(canclaim,"can not claim now");
        require(!isclaim[msg.sender],"have claimed");
        isclaim[msg.sender] = true;

        uint leftrunes = IERC20(runestoken).balanceOf(address(this));
        uint claimamount = claimquota[msg.sender];
        uint realamount = leftrunes > claimamount ? claimamount : leftrunes;
        
        IERC20(runestoken).transfer(msg.sender,realamount);
    
    }

    function setquotalist(address[]memory userlist,uint[]memory amountlist) external onlyOwner{
        uint length = userlist.length;
        require(length == amountlist.length,"error list");
        for (uint i; i < length; i++) {
            claimquota[userlist[i]] = amountlist[i];
        }
    }

    function setrunestoken(address newtoken) external onlyOwner{
        runestoken = newtoken;
    }

    function setcanclaim(bool _canclaim) external onlyOwner{
        canclaim = _canclaim;
    }

    function ownerclaimtoken(address token) external onlyOwner{
        uint value = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner,value);
    }

    function ownerclaimeth() external onlyOwner{
        uint value = address(this).balance;
        payable(owner).transfer(value);
    }

}