// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// https://etherscan.io/address/0xc36442b4a4522e871399cd717abdd847ab11fe88#code#F24#L22
interface IERC721Enumerable {

  function balanceOf(address owner) external view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

}

// https://etherscan.io/address/0xc36442b4a4522e871399cd717abdd847ab11fe88#code#F6#L61
interface INonfungiblePositionManager {

  function positions(uint256 tokenId)
    external
    view
    returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

}

// https://etherscan.io/address/0xf17616a88191bf62b07aEb140Fc6470C50cFe0aC#code#F24#L13
// https://etherscan.io/address/0xf17616a88191bf62b07aEb140Fc6470C50cFe0aC#code#F25#L21
interface IUniswapV3Pool {

  function token0() external view returns (address);
  function token1() external view returns (address);

  function slot0()
      external
      view
      returns (
          uint160 sqrtPriceX96,
          int24 tick,
          uint16 observationIndex,
          uint16 observationCardinality,
          uint16 observationCardinalityNext,
          uint32 feeProtocol,
          bool unlocked
      );

}

contract Uniswap3Query {

  struct PositionInfo {
    uint256 id;        //  64 bits ( 8 bytes)
    int24 tickLower;   //  24 bits ( 3 bytes)
    int24 tickUpper;   //  24 bits ( 3 bytes)
    uint128 liquidity; // 128 bits (16 bytes)
    bool isValid;      //   0 bits ( 0 bytes)
  }

  address constant private _positionManagerAddr = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

  function encodePosition(PositionInfo memory _p) private pure returns (uint256) {
    return uint256(bytes32(abi.encodePacked(
      uint16(0), // padding
      uint64(_p.id), _p.tickLower, _p.tickUpper, _p.liquidity)));
  }

  function queryUniswapV3Positions2(
      address uniswap3Pool,
      uint24  fee,
      address user
  ) public view returns (uint160 sqrtPriceX96, uint256[] memory validPositions) {

    return queryUniswapV3Positions(
      uniswap3Pool,
      _positionManagerAddr,
      fee,
      user
    );
  }

  function queryUniswapV3Positions(
      address uniswap3Pool,
      address positionManager,
      uint24  fee,
      address user
  ) public view returns (uint160 sqrtPriceX96, uint256[] memory validPositions) {

    address token0 = IUniswapV3Pool(uniswap3Pool).token0();
    address token1 = IUniswapV3Pool(uniswap3Pool).token1();
    sqrtPriceX96 = getSqrtPriceX96(uniswap3Pool);

    uint256[] memory allPositionIds = getAllPositionIds(positionManager, user);

    PositionInfo[] memory allPositions = new PositionInfo[](allPositionIds.length);
    uint256 nValid = 0;
    for (uint256 i = 0; i < allPositionIds.length; i++) {
      uint256 id = allPositionIds[i];
      allPositions[i] = getPositionInfo(positionManager, token0, token1, fee, id);
      if (allPositions[i].isValid) {
        nValid++;
      }
    }

    uint j = 0;
    validPositions = new uint256[](nValid);
    for (uint256 i = 0; i < allPositions.length; i++) {
      if (allPositions[i].isValid) {
        validPositions[j++] = encodePosition(allPositions[i]);
      }
    }
  }

  function getSqrtPriceX96(address uniswap3Pool) private view returns (uint160 sqrtPriceX96) {
    (
      sqrtPriceX96,
      /*int24 tick*/,
      /*uint16 observationIndex*/,
      /*uint16 observationCardinality*/,
      /*uint16 observationCardinalityNext*/,
      /*uint32 feeProtocol*/,
      /*bool unlocked*/
    ) = IUniswapV3Pool(uniswap3Pool).slot0();
  }

  function getAllPositionIds(
      address positionManager,
      address user
  ) private view returns (uint256[] memory positions) {

    uint256 n = IERC721Enumerable(positionManager).balanceOf(user);
    positions = new uint256[](n);

    for (uint i = 0; i < n; i++) {
      positions[i] = IERC721Enumerable(positionManager).tokenOfOwnerByIndex(user, i);
    }
  }

  function getPositionInfo(
      address positionManager,
      address token0,
      address token1,
      uint24  fee,
      uint256 id
  ) private view returns (PositionInfo memory) {

    (
      /*uint96 nonce*/,
      /*address operator*/,
      address _token0,
      address _token1,
      uint24 _fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      /*uint256 feeGrowthInside0LastX128*/,
      /*uint256 feeGrowthInside1LastX128*/,
      /*uint128 tokensOwed0*/,
      /*uint128 tokensOwed1*/
    ) = INonfungiblePositionManager(positionManager).positions(id);

    bool isValid = liquidity > 0
        && _token0 == token0
        && _token1 == token1
        && _fee == fee;

    // console.log('id       :%d', id);
    // console.log('token0   :%s', _token0);
    // console.log('token1   :%s', _token1);
    // console.log('tickLower:%d', uint(uint24(tickLower)));
    // console.log('tickUpper:%d', uint(uint24(tickUpper)));
    // console.log('liquidity:%d', uint(liquidity));
    // console.log('fee      :%d', uint(_fee));
    // console.log('isValid  :%d', isValid ? 1 : 0);
    return PositionInfo(id, tickLower, tickUpper, liquidity, isValid);
  }

}