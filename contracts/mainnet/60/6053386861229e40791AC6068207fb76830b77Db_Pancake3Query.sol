// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// https://bscscan.com/address/0x46A15B0b27311cedF172AB29E4f4766fbE7F4364#code#F1#L86
interface IERC721Enumerable {

  function balanceOf(address owner) external view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

}

// https://bscscan.com/address/0x46A15B0b27311cedF172AB29E4f4766fbE7F4364#code#F1#L81
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

// https://bscscan.com/address/0x589a5062e47202bb994cd354913733a14b54e8dc#code#F1#L60
// https://bscscan.com/address/0x589a5062e47202bb994cd354913733a14b54e8dc#code#F1#L21
interface IPancakeV3Pool {

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

contract Pancake3Query {

  struct PositionInfo {
    uint256 id;        //  64 bits ( 8 bytes)
    int24 tickLower;   //  24 bits ( 3 bytes)
    int24 tickUpper;   //  24 bits ( 3 bytes)
    uint128 liquidity; // 128 bits (16 bytes)
    bool isValid;      //   0 bits ( 0 bytes)
  }

  address constant private _positionManagerAddr = 0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;
  address constant private _masterChef3Addr     = 0x556B9306565093C855AEA9AE92A594704c2Cd59e;
  address constant private _magpieHelperAddr    = 0xbeD6d543327e9Bd72034Fc73b1dafCCCc557D7bA;

  function encodePosition(PositionInfo memory _p) private pure returns (uint256) {
    return uint256(bytes32(abi.encodePacked(
      uint16(0), // padding
      uint64(_p.id), _p.tickLower, _p.tickUpper, _p.liquidity)));
  }

  function queryPositions2(
      address pancake3Pool,
      uint24  fee,
      address user
  ) public view returns (uint160 sqrtPriceX96, uint256[] memory validPositions) {

    return queryPositions(
      pancake3Pool,
      _positionManagerAddr,
      _masterChef3Addr,
      _magpieHelperAddr,
      fee,
      user
    );
  }

  function queryPositions(
      address pancake3Pool,
      address positionManager,
      address masterChef3,
      address magpieHelper,
      uint24  fee,
      address user
  ) public view returns (uint160 sqrtPriceX96, uint256[] memory validPositions) {

    address token0 = IPancakeV3Pool(pancake3Pool).token0();
    address token1 = IPancakeV3Pool(pancake3Pool).token1();
    sqrtPriceX96 = getSqrtPriceX96(pancake3Pool);

    uint256[] memory allPositionIds = getAllPositionIds(
        positionManager, masterChef3, magpieHelper, user);

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

  function getSqrtPriceX96(address pancake3Pool) private view returns (uint160 sqrtPriceX96) {
    (
      sqrtPriceX96,
      /*int24 tick*/,
      /*uint16 observationIndex*/,
      /*uint16 observationCardinality*/,
      /*uint16 observationCardinalityNext*/,
      /*uint32 feeProtocol*/,
      /*bool unlocked*/
    ) = IPancakeV3Pool(pancake3Pool).slot0();
  }

  function getAllPositionIds(
      address positionManager,
      address masterChef3,
      address magpieHelper,
      address user
  ) private view returns (uint256[] memory positions) {

    uint256 n1 = IERC721Enumerable(positionManager).balanceOf(user);
    uint256 n2 = IERC721Enumerable(masterChef3).balanceOf(user);
    uint256 n3 = IERC721Enumerable(magpieHelper).balanceOf(user);

    positions = new uint256[](n1 + n2 + n3);
    uint256 j = 0;

    for (uint i = 0; i < n1; i++) {
      positions[j++] = IERC721Enumerable(positionManager).tokenOfOwnerByIndex(user, i);
    }
    for (uint i = 0; i < n2; i++) {
      positions[j++] = IERC721Enumerable(masterChef3).tokenOfOwnerByIndex(user, i);
    }
    for (uint i = 0; i < n3; i++) {
      positions[j++] = IERC721Enumerable(magpieHelper).tokenOfOwnerByIndex(user, i);
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