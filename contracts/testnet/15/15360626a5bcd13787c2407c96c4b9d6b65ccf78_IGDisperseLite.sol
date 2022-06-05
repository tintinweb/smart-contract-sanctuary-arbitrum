// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "../IERC20.sol";
import "../IERC721.sol";
import "../IERC1155.sol";


contract IGDisperseLite {

function DisperseEthereum(address payable[] calldata DestinationAddress, uint256[] calldata Amount) external payable{

for (uint256 a = 0; a < DestinationAddress.length; a=a+1)
{
DestinationAddress[a].transfer(Amount[a]);
}

uint256 Back = address(this).balance;

if (Back > 0)
{
payable(msg.sender).transfer(Back);
}
}

function DisperseERC20(address ERC20ContractAddress, address payable[] calldata DestinationAddress, uint256[] calldata Amount) external {
IERC20 Token = IERC20(ERC20ContractAddress);
uint256 total = 0;
for (uint256 a = 0; a < DestinationAddress.length; a++)
total += Amount[a];
require(Token.transferFrom(msg.sender, address(this), total));
for (uint256 a = 0; a < DestinationAddress.length; a++)
require(Token.transfer(DestinationAddress[a], Amount[a]));
}

function DisperseERC721(address ERC721ContractAddress, address payable[] calldata DestinationAddress, uint256[] calldata ID) external {
IERC721 Token = IERC721(ERC721ContractAddress);
for (uint256 a = 0; a < DestinationAddress.length; a++)
Token.safeTransferFrom(msg.sender, DestinationAddress[a], ID[a]);
}

function DisperseERC1155(address ERC1155ContractAddress, address payable[] calldata DestinationAddress, uint256[] calldata ID, uint256[] calldata Amount) external {
IERC1155 Token = IERC1155(ERC1155ContractAddress);
for (uint256 a = 0; a < DestinationAddress.length; a++)
Token.safeTransferFrom(msg.sender, DestinationAddress[a], ID[a], Amount[a],"");
}

}