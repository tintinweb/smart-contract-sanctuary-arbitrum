/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IToken
 * @dev Interface for the Token contract.
 */
interface IToken {
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title ContractCall
 * @dev This contract demonstrates a function for calling another contract and performing a swap.
 * Note: This is just an example code, and in a real production environment, it is necessary to implement permission controls.
 * !!!Do not use this contract for any production activities.!!!
 */
contract ContractCall {
    address public constant OPENOCEAN_EXCHANGE_V2 = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64;

    /**
     * @dev Performs a swap by calling the specified token's `approve` function and then executing the swap on the OpenOcean Exchange v2 contract.
     * @param token The address of the token contract.
     * @param amount The amount of tokens to be approved for swapping.
     * @param inputdata The input data for the swap transaction on the OpenOcean Exchange v2.
     * @param nativeInput The native input (ETH) for the swap transaction on the OpenOcean Exchange v2.
     */
    function swap(address token, uint256 amount, bytes calldata inputdata, uint256 nativeInput) public {
        IToken(token).approve(OPENOCEAN_EXCHANGE_V2, amount);
        (bool result, ) = OPENOCEAN_EXCHANGE_V2.call{value: nativeInput}(inputdata);
        require(result, "failed to swap");
    }
}