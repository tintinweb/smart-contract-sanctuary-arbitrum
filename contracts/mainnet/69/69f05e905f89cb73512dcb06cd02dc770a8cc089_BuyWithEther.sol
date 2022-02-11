// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

pragma abicoder v2;

// import "./console.sol";

import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";

import "./StakingV2.sol";

abstract contract InterfaceImpishDAO {
  function buyNFTPrice(uint256 tokenID) public view virtual returns (uint256);

  function buyNFT(uint256 tokenID) public virtual;

  function deposit() public payable virtual;
}

abstract contract IRWMarket {
  function acceptSellOffer(uint256 offerId) public payable virtual;
}

abstract contract ISpiralMarket {
  struct Listing {
    // What price is it listed for
    uint256 price;
    // The owner that listed it. If the owner has changed, it can't be sold anymore.
    address owner;
  }

  // Listing of all Tokens that are for sale
  mapping(uint256 => Listing) public forSale;

  function buySpiral(uint256 tokenId) external payable virtual;
}

abstract contract IWETH9 {
  function deposit() external payable virtual;

  function withdraw(uint256 amount) external virtual;

  function balanceOf(address owner) external virtual returns (uint256);
}

contract BuyWithEther is IERC721Receiver {
  // Uniswap v3router
  ISwapRouter public immutable swapRouter;

  // Contract addresses deployed on Arbitrum
  address public constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant IMPISH = 0x36F6d831210109719D15abAEe45B327E9b43D6C6;
  address public constant RWNFT = 0x895a6F444BE4ba9d124F61DF736605792B35D66b;
  address public constant MAGIC = 0x539bdE0d7Dbd336b79148AA742883198BBF60342;
  address public constant IMPISHSPIRAL = 0xB6945B73ed554DF8D52ecDf1Ab08F17564386e0f;
  address public constant IMPISHCRYSTAL = 0x2dC9a47124E15619a07934D14AB497A085C2C918;
  address public constant SPIRALBITS = 0x650A9960673688Ba924615a2D28c39A8E015fB19;
  address public constant SPIRALMARKET = 0x75ae378320E1cDe25a496Dfa22972d253Fc2270F;
  address public constant RWMARKET = 0x47eF85Dfb775aCE0934fBa9EEd09D22e6eC0Cc08;
  address payable public constant STAKINGV2 = payable(0x2069cB988d5B17Bab70d73076d6F1a9757A4f963);

  // We will set the pool fee to 1%.
  uint24 public constant POOL_FEE = 10000;

  constructor(ISwapRouter _swapRouter) {
    swapRouter = _swapRouter;

    // Approve the router to spend the WETH9, MAGIC and SPIRALBITS
    TransferHelper.safeApprove(WETH9, address(swapRouter), 2**256 - 1);
    TransferHelper.safeApprove(SPIRALBITS, address(swapRouter), 2**256 - 1);
    TransferHelper.safeApprove(MAGIC, address(swapRouter), 2**256 - 1);

    // Approve the NFTs and tokens for this contract as well.
    IERC721(RWNFT).setApprovalForAll(STAKINGV2, true);
    IERC721(IMPISHSPIRAL).setApprovalForAll(STAKINGV2, true);
    IERC721(IMPISHCRYSTAL).setApprovalForAll(STAKINGV2, true);
    IERC20(SPIRALBITS).approve(STAKINGV2, 2**256 - 1);
    IERC20(IMPISH).approve(STAKINGV2, 2**256 - 1);

    // Allow ImpishCrystals to spend our SPIRALBITS (to grow crystals)
    IERC20(SPIRALBITS).approve(IMPISHCRYSTAL, 2**256 - 1);
  }

  function maybeStakeRW(uint256 tokenId, bool stake) internal {
    if (!stake) {
      // transfer the NFT to the sender
      IERC721(RWNFT).safeTransferFrom(address(this), msg.sender, tokenId);
    } else {
      uint32[] memory tokens = new uint32[](1);
      tokens[0] = uint32(tokenId) + 1_000_000; // ContractId for RWNFT is 1,000,000
      StakingV2(STAKINGV2).stakeNFTsForOwner(tokens, msg.sender);
    }
  }

  // Buy and Stake a RWNFT
  function buyAndStakeRW(uint256 tokenId, bool stake) internal {
    InterfaceImpishDAO(IMPISH).buyNFT(tokenId);
    maybeStakeRW(tokenId, stake);
  }

  function buyRwNFTFromDaoWithEthDirect(uint256 tokenId, bool stake) external payable {
    uint256 nftPriceInIMPISH = InterfaceImpishDAO(IMPISH).buyNFTPrice(tokenId);

    // We add 1 wei, because we've divided by 1000, which will remove the smallest 4 digits
    // and we need to add it back because he actual price has those 4 least significant digits.
    InterfaceImpishDAO(IMPISH).deposit{value: (nftPriceInIMPISH / 1000) + 1}();
    buyAndStakeRW(tokenId, stake);

    // Return any excess
    if (address(this).balance > 0) {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "TransferFailed");
    }
  }

  function buyRwNFTFromDaoWithEth(uint256 tokenId, bool stake) external payable {
    // Get the buyNFT price
    uint256 nftPriceInIMPISH = InterfaceImpishDAO(IMPISH).buyNFTPrice(tokenId);
    swapExactOutputImpishFromEth(nftPriceInIMPISH, msg.value);

    buyAndStakeRW(tokenId, stake);
  }

  function buyRwNFTFromDaoWithSpiralBits(
    uint256 tokenId,
    uint256 maxSpiralBits,
    bool stake
  ) external {
    // Get the buyNFT price
    uint256 nftPriceInIMPISH = InterfaceImpishDAO(IMPISH).buyNFTPrice(tokenId);
    swapExactOutputImpishFromSpiralBits(nftPriceInIMPISH, maxSpiralBits);

    buyAndStakeRW(tokenId, stake);
  }

  function buySpiralFromMarketWithSpiralBits(
    uint256 tokenId,
    uint256 maxSpiralBits,
    bool stake
  ) external {
    // Get the price for this Spiral TokenId
    (uint256 priceInEth, ) = ISpiralMarket(SPIRALMARKET).forSale(tokenId);

    // Swap SPIRALBITS -> WETH9
    swapExactOutputEthFromSpiralBits(priceInEth, maxSpiralBits);

    // WETH9 -> ETH
    IWETH9(WETH9).withdraw(priceInEth);

    // Buy the Spiral
    ISpiralMarket(SPIRALMARKET).buySpiral{value: priceInEth}(tokenId);

    if (!stake) {
      // transfer the NFT to the sender
      IERC721(IMPISHSPIRAL).safeTransferFrom(address(this), msg.sender, tokenId);
    } else {
      uint32[] memory tokens = new uint32[](1);
      tokens[0] = uint32(tokenId) + 2_000_000; // ContractId for Spirals is 2,000,000;
      StakingV2(STAKINGV2).stakeNFTsForOwner(tokens, msg.sender);
    }
  }

  function buyRwNFTFromRWMarket(
    uint256 offerId,
    uint256 tokenId,
    uint256 priceInEth,
    uint256 maxSpiralBits,
    bool stake
  ) external {
    // Swap SPIRALBITS -> WETH9
    swapExactOutputEthFromSpiralBits(priceInEth, maxSpiralBits);

    // WETH9 -> ETH
    IWETH9(WETH9).withdraw(IWETH9(WETH9).balanceOf(address(this)));

    // Buy RW
    IRWMarket(RWMARKET).acceptSellOffer{value: priceInEth}(offerId);

    // Stake or Return to msg.sender
    maybeStakeRW(tokenId, stake);
  }

  function multiMintWithMagic(uint8 count, uint96 value) external {
    magicToEth(uint256(value));

    require(count > 0, "AtLeastOne");
    require(count <= 10, "AtMost10");

    // This function doesn't check if you've sent enough money. If you didn't it will revert
    // because the mintSpiralRandom will fail
    uint8 mintedSoFar;
    uint256 nextTokenId = ImpishSpiral(IMPISHSPIRAL)._tokenIdCounter();

    for (mintedSoFar = 0; mintedSoFar < count; mintedSoFar++) {
      uint256 price = ImpishSpiral(IMPISHSPIRAL).getMintPrice();
      ImpishSpiral(IMPISHSPIRAL).mintSpiralRandom{value: price}();

      ImpishSpiral(IMPISHSPIRAL).safeTransferFrom(address(this), msg.sender, nextTokenId);
      nextTokenId += 1;
    }

    // If there is any excess money left, send it back
    if (address(this).balance > 0) {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }
  }

  function megaMintWithMagic(
    address owner,
    uint32 count,
    uint256 value
  ) external {
    magicToEth(value);

    megaMint(owner, count);
  }

  // A megamint does many things at once:
  // Mint a RWNFT
  // Mint a Companion Spiral
  // Mint a gen0 Crystal
  // Buy SPIRALBITS on Uniswap
  // Grow the crystals to max size
  // Stake all NFTs and IMPISH and SPIRALBITS
  function megaMint(address owner, uint32 count) public payable {
    // The TokenId of the first token minted
    uint256 rwTokenId = IRandomWalkNFT(RWNFT).nextTokenId();

    for (uint256 i = 0; i < count; i++) {
      IRandomWalkNFT(RWNFT).mint{value: IRandomWalkNFT(RWNFT).getMintPrice()}();
    }

    // Spirals
    uint256 spiralTokenId = ImpishSpiral(IMPISHSPIRAL)._tokenIdCounter();
    uint32[] memory spiralTokenIds = new uint32[](count);
    for (uint256 i = 0; i < count; i++) {
      spiralTokenIds[i] = uint32(spiralTokenId + i);
      ImpishSpiral(IMPISHSPIRAL).mintSpiralWithRWNFT{value: ImpishSpiral(IMPISHSPIRAL).getMintPrice()}(rwTokenId + i);
    }

    // Crystals
    uint256 crystalTokenId = ImpishCrystal(IMPISHCRYSTAL)._tokenIdCounter();
    ImpishCrystal(IMPISHCRYSTAL).mintCrystals(spiralTokenIds, 0);

    // Swap all remaining ETH into SPIRALBITS. Note this doesn't refund anything back to the user.
    swapExactInputSpiralBitsFromEthNoRefund(address(this).balance);

    // Grow all the crystals to max size
    for (uint256 i = 0; i < count; i++) {
      // Newly created crystals are size 30, so we need to grow them 70 more.
      ImpishCrystal(IMPISHCRYSTAL).grow(uint32(crystalTokenId + i), 70);
    }

    // Calculate all the contractTokenIDs, needed for staking
    uint32[] memory contractTokenIds = new uint32[](count * 3);
    for (uint256 i = 0; i < count; i++) {
      contractTokenIds[i * 3 + 0] = uint32(rwTokenId + i + 1_000_000);
      contractTokenIds[i * 3 + 1] = uint32(spiralTokenId + i + 2_000_000);

      // Fully grown crystals are contractID 4,000,000
      contractTokenIds[i * 3 + 2] = uint32(crystalTokenId + i + 4_000_000);
    }
    StakingV2(STAKINGV2).stakeNFTsForOwner(contractTokenIds, owner);

    // Stake any remaining SPIRALBITS
    uint256 spiralBitsBalance = IERC20(SPIRALBITS).balanceOf(address(this));
    if (spiralBitsBalance > 0) {
      StakingV2(STAKINGV2).stakeSpiralBitsForOwner(spiralBitsBalance, owner);
    }

    // Stake any remaining IMPISH
    uint256 impishBalance = IERC20(IMPISH).balanceOf(address(this));
    if (impishBalance > 0) {
      StakingV2(STAKINGV2).stakeImpishForOwner(impishBalance, owner);
    }
  }

  /// ------- SWAP Functions
  function magicToEth(uint256 value) internal {
    // Transfer MAGIC in
    TransferHelper.safeTransferFrom(MAGIC, msg.sender, address(this), value);

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: MAGIC,
      tokenOut: WETH9,
      fee: POOL_FEE,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: value,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    });

    // Executes the swap returning the amountOut that was swapped.
    uint256 amountOut = swapRouter.exactInputSingle(params);
    IWETH9(WETH9).withdraw(amountOut);
  }

  function swapExactInputSpiralBitsFromEthNoRefund(uint256 amountIn) internal returns (uint256 amountOut) {
    // Convert to WETH, since thats what Uniswap uses
    IWETH9(WETH9).deposit{value: address(this).balance}();

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: WETH9,
      tokenOut: SPIRALBITS,
      fee: POOL_FEE,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    });

    // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
    amountOut = swapRouter.exactInputSingle(params);
  }

  /// Swap with Uniswap V3 for the exact amountOut, using upto amountInMaximum of ETH
  function swapExactOutputEthFromSpiralBits(uint256 amountOut, uint256 amountInMaximum)
    internal
    returns (uint256 amountIn)
  {
    // Transfer spiralbits in
    TransferHelper.safeTransferFrom(SPIRALBITS, msg.sender, address(this), amountInMaximum);

    ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
      tokenIn: SPIRALBITS,
      tokenOut: WETH9,
      fee: POOL_FEE,
      recipient: address(this),
      deadline: block.timestamp,
      amountOut: amountOut,
      amountInMaximum: amountInMaximum,
      sqrtPriceLimitX96: 0
    });

    // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
    amountIn = swapRouter.exactOutputSingle(params);

    // For exact output swaps, the amountInMaximum may not have all been spent.
    // If the actual amount spent (amountIn) is less than the specified maximum amount,
    // we must refund the msg.sender
    if (amountIn < amountInMaximum) {
      TransferHelper.safeTransfer(SPIRALBITS, msg.sender, amountInMaximum - amountIn);
    }
  }

  /// Swap with Uniswap V3 for the exact amountOut, using upto amountInMaximum of ETH
  function swapExactOutputImpishFromEth(uint256 amountOut, uint256 amountInMaximum)
    internal
    returns (uint256 amountIn)
  {
    // Convert to WETH, since thats what Uniswap uses
    IWETH9(WETH9).deposit{value: address(this).balance}();

    ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
      tokenIn: WETH9,
      tokenOut: IMPISH,
      fee: POOL_FEE,
      recipient: address(this),
      deadline: block.timestamp,
      amountOut: amountOut,
      amountInMaximum: amountInMaximum,
      sqrtPriceLimitX96: 0
    });

    // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
    amountIn = swapRouter.exactOutputSingle(params);

    // For exact output swaps, the amountInMaximum may not have all been spent.
    // If the actual amount spent (amountIn) is less than the specified maximum amount,
    // we must refund the msg.sender
    if (amountIn < amountInMaximum) {
      IWETH9(WETH9).withdraw(IWETH9(WETH9).balanceOf(address(this)));
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "TransferFailed");
    }
  }

  /// Swap with Uniswap V3 for the exact amountOut, using upto amountInMaximum of SPIRALBITS
  function swapExactOutputImpishFromSpiralBits(uint256 amountOut, uint256 amountInMaximum)
    internal
    returns (uint256 amountIn)
  {
    // Transfer spiralbits in
    TransferHelper.safeTransferFrom(SPIRALBITS, msg.sender, address(this), amountInMaximum);

    ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
      path: abi.encodePacked(IMPISH, POOL_FEE, WETH9, POOL_FEE, SPIRALBITS),
      recipient: address(this),
      deadline: block.timestamp,
      amountOut: amountOut,
      amountInMaximum: amountInMaximum
    });

    // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
    amountIn = swapRouter.exactOutput(params);

    // For exact output swaps, the amountInMaximum may not have all been spent.
    // If the actual amount spent (amountIn) is less than the specified maximum amount,
    // we must refund the msg.sender
    if (amountIn < amountInMaximum) {
      TransferHelper.safeTransfer(SPIRALBITS, msg.sender, amountInMaximum - amountIn);
    }
  }

  // Default payable function, so the contract can accept any refunds
  receive() external payable {
    // Do nothing
  }

  // Function that marks this contract can accept incoming NFT transfers
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure returns (bytes4) {
    // Return this value to accept the NFT
    return IERC721Receiver.onERC721Received.selector;
  }
}