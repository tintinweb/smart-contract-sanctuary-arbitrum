/**
 *Submitted for verification at Arbiscan.io on 2023-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    }
interface EquivalenceProtocol {
    function externalMint(address _addr, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    }





//********************************************************************************************
//***********************      HERE STARTS THE CODE OF CONTRACT     **************************
//********************************************************************************************

contract EquivalenceTokenWrapper {

// simplified version of ownable (to save gas)
    address private _owner;
    constructor() {_owner = msg.sender;}
    modifier onlyOwner() {require(_owner == msg.sender, "Ownable: caller is not the owner"); _;}

// variables
    EquivalenceProtocol public EQT;
    IERC20 public WEQT;
    bool public EQTaddressLocked = false;
    bool public WEQTaddressLocked = false;
    uint256 public RequiredUnlockTime = 7776000;    // 7776000 = 90 days
    uint256 internal timestamp = 0;
    error Locked();
    error Amount_Too_High();

// onlyOwner functions
    function setEQT(EquivalenceProtocol _addr) external onlyOwner {if (EQTaddressLocked) {revert Locked();} else {EQT = _addr;}}
    function lockEQTaddress(bool confirm) external onlyOwner {if (confirm) {EQTaddressLocked = true;}}
    function setWEQT(IERC20 _addr) external onlyOwner {if (WEQTaddressLocked) {revert Locked();} else {WEQT = _addr;}}
    function lockWEQTaddress(bool confirm) external onlyOwner {if (confirm) {WEQTaddressLocked = true;}}
    function lock() external onlyOwner {timestamp = 0;}
    function unlock() external onlyOwner {timestamp = block.timestamp;}
    function Withdraw_WEQT(uint256 amount) external onlyOwner {
        if ((timestamp == 0) || (timestamp + RequiredUnlockTime >= block.timestamp)) {revert Locked();}
        WEQT.transfer(_owner, amount);
    }

// view functions
    function checkRemainingLockTime() external view returns (string memory status, uint256 time) {
        if (timestamp == 0) {return ("locked", 99999999999);}
        else if ((block.timestamp - timestamp) >= RequiredUnlockTime) {return ("unlocked", 0);}
        else {return ("unlocking", (RequiredUnlockTime - (block.timestamp - timestamp)));}
    }

// wrapping + unwrapping
    function wrapEQT(uint256 amount) external {
        if (amount > WEQT.balanceOf(address(this))) {revert Amount_Too_High();}
        unchecked {
        if (WEQT.balanceOf(address(this)) >= 10**27) {              // 10**27 = 1 billion EQT
            EQT.burnFrom(msg.sender, amount);
            WEQT.transfer(msg.sender, amount);
        } else {
            EQT.burnFrom(msg.sender, amount);
            amount = amount - ((amount * (10**27 - WEQT.balanceOf(address(this)))) / (10**27 + (100 * WEQT.balanceOf(address(this)))));   // fee deduced from the amount when there is "low" supply of WEQT
            WEQT.transfer(msg.sender, amount);
        }}
    }
    function unwrapWEQT(uint256 amount) external { unchecked {
        if (WEQT.balanceOf(address(this)) >= 9*10**26) {            // 9*10**26 = 900 million EQT
            WEQT.transferFrom(msg.sender, address(this), amount);
            EQT.externalMint(msg.sender, amount);
        } else {
            WEQT.transferFrom(msg.sender, address(this), amount);
            amount = amount*1001/1000;                              // gives 0.1% bonus EQT when there is "low" supply of WEQT to incentivize users to bring in more WEQT
            EQT.externalMint(msg.sender, amount);
        }}
    }
}