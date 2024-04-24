// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Uniswap3SC{
	function fee() external view returns (uint24);
	function slot0() external view returns (uint160 sqrtPriceX96); //pay atention to be the first param returned, otherwise you get other data.
}

contract Uniswap3PriceData{

	function getPriceData(address pool) external view returns (uint160 sqrtPriceX96, uint24 fee){

		//create SC
        Uniswap3SC poolSC = Uniswap3SC(pool);
		
		sqrtPriceX96 = poolSC.slot0();
		fee = poolSC.fee();
		
	}
	
}