/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
 interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
contract test {
    constructor() {
    }
      // stake tokens to Farm for ERC20 allocation.
    function safeTransferFrom(address nft,address _to,uint256[] calldata _tokenIDs) public  {
         INFT nft=INFT(nft);
         for (uint i = 0; i < _tokenIDs.length; i++) {
            nft.safeTransferFrom(msg.sender,_to,_tokenIDs[i]);
        }
    }

}