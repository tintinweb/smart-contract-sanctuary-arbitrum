/**
 *Submitted for verification at Arbiscan on 2022-05-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-08
*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
} 

contract BatchTransferERC20 {
    
    function batchTransfer(
        address tokenAddress,
        address[] memory tos,
        uint256[] memory amounts
    ) public {
        require(tos.length == amounts.length, "PARAM_LENGTH_INVALID");
        for (uint i = 0; i < tos.length; i++) {
            IERC20(tokenAddress).transferFrom(msg.sender,tos[i],amounts[i]);
        }
    }
}