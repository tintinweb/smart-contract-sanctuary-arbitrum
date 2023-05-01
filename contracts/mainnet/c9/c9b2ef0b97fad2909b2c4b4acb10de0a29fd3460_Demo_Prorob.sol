/**
 *Submitted for verification at Arbiscan on 2023-04-30
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SampleERC20
 * @dev Create a sample ERC20 standard token
 */

contract Demo_Prorob {
    address payable owner;
    address payable admin;
    address WETH;
    address routerAddress;

    bool uniV3Bysuccess = false;
    uint feeIndex = 0;
    bool findFeeIndex = false;

    constructor () {
        
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function boss(string memory dex, address tokenA, address tokenB, uint256 amountIn, uint256 amountOutMin, address[] memory walletAddressList, uint24[] memory uniV3FeeList) public returns (bool) {
        return true;
    }


    function extract(address tokenAddress) public returns (bool) {
        
    }
}