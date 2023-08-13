/**
 *Submitted for verification at Arbiscan on 2023-08-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFactory {
    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

contract PairFor {
    address factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function setFactory(address _factory) external {
        factory = _factory;
    }
     // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SwapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SwapLibrary: ZERO_ADDRESS");
    }
    function pairFor(address tokenA, address tokenB) external view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                abi.encodePacked(IFactory(factory).INIT_CODE_PAIR_HASH(), abi.encode(address(0), address(0), address(0), address(0),false,false)) // init code hash
            )))));
    }
}