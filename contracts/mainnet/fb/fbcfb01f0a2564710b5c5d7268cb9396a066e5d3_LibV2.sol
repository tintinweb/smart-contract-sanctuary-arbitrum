/**
 *Submitted for verification at Arbiscan.io on 2024-05-22
*/

/**
 *Submitted for verification at Etherscan.io on 2023-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

contract LibV2 {

    function batchBalanceOf(address[] calldata tokens, address[] calldata wallets) 
     external
        view
        returns (uint256[] memory results)
    {
       require(tokens.length == wallets.length,"invalid input");
       results = new uint256[](wallets.length);
       for (uint256 i = 0; i < tokens.length; i++) {
           address token = tokens[i];
           address wallet = wallets[i];
           if(token == address(0)) {
               results[i] = wallet.balance;
           }
           else {
               results[i] = IERC20(token).balanceOf(wallet);
           }
       }
    }    

    function multiStaticCall(address[] calldata addr, bytes[] calldata data)
        external
        view
        returns (bool[] memory bools,bytes[] memory results)
    {
        require(addr.length==data.length,"invalid input");
        bools = new bool[](data.length);
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(addr[i]).staticcall(
                data[i]
            );
            bools[i] = success;
            if(success) results[i] = result;
        }
    }

    function singleContractMultiStaticCall(address addr, bytes[] calldata data)
        external
        view
        returns (bool[] memory bools,bytes[] memory results)
    {
        bools = new bool[](data.length);
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = addr.staticcall(
                data[i]
            );
            bools[i] = success;
            if(success) results[i] = result;
        }
    }

}