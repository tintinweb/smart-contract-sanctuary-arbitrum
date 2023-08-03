// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// OZs
import {Ownable2Step} from "./Ownable2Step.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

// Interfaces
import {INonfungiblePositionManager} from "./INonfungiblePositionManager.sol";

contract UniV3LiquidityFreezer is Ownable2Step, ReentrancyGuard {
  INonfungiblePositionManager public immutable nonfungiblePositionManager;
  mapping(uint256 tokenId => uint256 unlockTimestamp) public unlockOf;

  event Lock(uint256 indexed tokenId, uint256 unlockTimestamp);
  event Unlock(uint256 indexed tokenId);

  constructor(INonfungiblePositionManager _nonfungiblePositionManager) {
    nonfungiblePositionManager = _nonfungiblePositionManager;
  }

  /// @notice Locks the liquidity tokens in the contract until the unlock timestamp
  /// @param _tokenId The token ID of the liquidity tokens to lock
  /// @param _unlockTimestamp The timestamp at which the liquidity tokens can be unlocked
  function lock(uint256 _tokenId, uint256 _unlockTimestamp)
    external
    onlyOwner
    nonReentrant
  {
    // Check
    require(unlockOf[_tokenId] == 0, "locked");
    require(_unlockTimestamp > block.timestamp, "bad _unlockTimestamp");

    // Effect
    unlockOf[_tokenId] = _unlockTimestamp;

    // Interaction
    nonfungiblePositionManager.safeTransferFrom(
      msg.sender, address(this), _tokenId
    );

    // Emit
    emit Lock(_tokenId, _unlockTimestamp);
  }

  /// @notice Unlocks the liquidity tokens if the unlock timestamp has passed
  function unlock(uint256 _tokenId) external onlyOwner nonReentrant {
    // Check
    require(unlockOf[_tokenId] != 0, "!existed");
    require(block.timestamp >= unlockOf[_tokenId], "locked");

    // Effect
    unlockOf[_tokenId] = 0;

    // Interaction
    nonfungiblePositionManager.safeTransferFrom(
      address(this), msg.sender, _tokenId
    );

    // Emit
    emit Unlock(_tokenId);
  }

  /// @notice Function to support safeTransferFrom
  function onERC721Received(
    address,
    address, /* _from */
    uint256, /* _tokenId */
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }
}