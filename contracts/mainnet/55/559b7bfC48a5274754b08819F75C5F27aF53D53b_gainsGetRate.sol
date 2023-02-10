/**
 *Submitted for verification at Arbiscan on 2023-02-10
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/oracles/getRate.sol

// contracts/getRate.sol

pragma solidity 0.8.11;

interface GDAY {
    function balanceOf(address account) external view returns (uint256);
	function decimals() external view returns (uint256);
    function shareToAssetsPrice() external view returns (uint256);
}

contract gainsGetRate{
    GDAY public underlying;

    constructor(address _underlying) public {
    	underlying  = GDAY(_underlying);
    }

    // to integrate we just need to inherit that same interface the other page uses.
	function getRate() public view
		returns 
			(uint256 answer){
		return underlying.shareToAssetsPrice();
	}
}