/**
 *Submitted for verification at Arbiscan on 2023-04-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

interface INonfungiblePositionManager {
    function approve(address spender, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IMulticall {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

contract Bv3_Liquidity_Lock {
    address private owner;
    uint256 private lockTimestamp;
    uint256 private unlockTimestamp;
    uint256 private tokenId;
    INonfungiblePositionManager private positionManager;

    constructor(address _nonfungiblePositionManager) {
        owner = msg.sender;
        lockTimestamp = block.timestamp;
        unlockTimestamp = block.timestamp + 3 weeks;
        positionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier isUnlocked() {
        require(block.timestamp >= unlockTimestamp, "Liquidity is still locked.");
        _;
    }

    function timeTill() public view returns (uint256) {
        if ((unlockTimestamp - lockTimestamp) < 0) {
            return 0;
        } else {
            return unlockTimestamp - lockTimestamp;
        }
    }


    // ONLY OWNER FUNCTIONS
    function change_positionManager(address _nonfungiblePositionManager) external onlyOwner {
        positionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
    }

    function change_tokenID(uint256 ID) external onlyOwner {
        tokenId = ID;
    }

    function approve_LiquidityToLocker(uint256 _tokenId) external onlyOwner {
        positionManager.approve(msg.sender, _tokenId);
        tokenId = _tokenId;
    }

    function transferLiquidityToLocker(uint256 _tokenId) external onlyOwner {
        positionManager.transferFrom(msg.sender, address(this), _tokenId);
        tokenId = _tokenId;
    }

    function removeLiquidity() external onlyOwner isUnlocked {
        require(tokenId != 0, "No liquidity position to remove.");
        positionManager.transferFrom(address(this), owner, tokenId);
        tokenId = 0;
    }
}