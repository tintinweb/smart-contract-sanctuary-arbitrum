/**
 *Submitted for verification at Arbiscan on 2023-05-11
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IONE {
    function deposit(uint256 _amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ISRG20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract SRGONE_STORAGE is Ownable {
    address private SRG;
    address private SRGONE;

    ISRG20 private srg;
    IONE private srgone;

    address private CONTRACT;

    bool public locked;

    constructor(address srg_, address srgone_) {
        CONTRACT = address(this);
        locked = true;
        
        SRG = srg_;
        SRGONE = srgone_;
        
        srg = ISRG20(srg_);
        srgone = IONE(srgone_);

        srg.approve(CONTRACT, type(uint256).max);
        srgone.approve(CONTRACT, type(uint256).max);
    }

    function depositUNWRAPPEDtoONEWRAP() public {
        uint unwrappedBal = srg.balanceOf(address(this));
        srg.approve(SRGONE, unwrappedBal);
        srgone.deposit(unwrappedBal);
    }

    function recover() public onlyOwner {
        if(!locked) {
            uint256 srg_bal = srg.balanceOf(CONTRACT);
            if(srg_bal > 0)srg.transfer(owner(), srg_bal);

            uint256 srgone_bal = srgone.balanceOf(CONTRACT);
            if(srgone_bal > 0)srgone.transfer(owner(), srgone_bal);
        }
    }

    function setLocked(bool _locked) external onlyOwner {
        locked = _locked;
    }

    function process() external {
        depositUNWRAPPEDtoONEWRAP();
    }

}