/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract LiquidityLock {
    address private _owner;
    address private _blackhole = address(0x000000000000000000000000000000000000dEaD); // 黑洞地址
    
    mapping(uint256 => uint256) private _lockTimes;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event LiquidityLocked(uint256 tokenId, uint256 lockTime);
    event LiquidityClaimed(uint256 tokenId, address recipient);
    event LiquidityTransferred(uint256 tokenId, address recipient);
    event LiquiditySentToBlackhole(uint256 tokenId);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function lockLiquidity(uint256 tokenId, uint256 lockDuration) public onlyOwner {
        require(lockDuration > 0, "Lock duration must be greater than zero");
        require(_lockTimes[tokenId] == 0, "Liquidity already locked");

        _lockTimes[tokenId] = block.timestamp + lockDuration;
        emit LiquidityLocked(tokenId, _lockTimes[tokenId]);
    }

    function claimLiquidity(uint256 tokenId) public onlyOwner {
        require(_lockTimes[tokenId] > 0, "Liquidity not locked");
        require(_lockTimes[tokenId] <= block.timestamp, "Lock duration not expired");
        
        address owner = IERC721(msg.sender).ownerOf(tokenId);
        require(owner == address(this), "Liquidity not held by contract");

        IERC721(msg.sender).transferFrom(address(this), msg.sender, tokenId);
        delete _lockTimes[tokenId];

        emit LiquidityClaimed(tokenId, msg.sender);
    }

    function transferLiquidity(uint256 tokenId, address recipient) public onlyOwner {
        require(recipient != address(0), "Invalid recipient address");

        address owner = IERC721(msg.sender).ownerOf(tokenId);
        require(owner == address(this), "Liquidity not held by contract");

        IERC721(msg.sender).transferFrom(address(this), recipient, tokenId);

        emit LiquidityTransferred(tokenId, recipient);
    }

    function sendToBlackhole(uint256 tokenId) public onlyOwner {
        address owner = IERC721(msg.sender).ownerOf(tokenId);
        require(owner == address(this), "Liquidity not held by contract");

        IERC721(msg.sender).transferFrom(address(this), _blackhole, tokenId);
        
        emit LiquiditySentToBlackhole(tokenId);
    }
}