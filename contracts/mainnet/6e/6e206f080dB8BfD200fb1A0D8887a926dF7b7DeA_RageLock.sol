/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract RageLock {
    address private _owner;
    uint256 private _time;
    
    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    function lock(IERC20 token, uint256 amount, uint256 time) public onlyOwner {
        token.transferFrom(_owner, address(this), amount);
        _time = time;
    }
    
    function unlock(IERC20 token, uint256 amount) public onlyOwner {
        require(block.timestamp > _time);
        token.transfer(_owner, amount);
    }
}