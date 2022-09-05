/**
 *Submitted for verification at Arbiscan on 2022-09-05
*/

pragma solidity ^0.8.10;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract XDisperse {
    function disperseErc721(IERC721 token, address[] memory recipients, uint256[] memory tokenIds) external {
        require(recipients.length == tokenIds.length, "Disperse: recipients and tokenIds length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }
}