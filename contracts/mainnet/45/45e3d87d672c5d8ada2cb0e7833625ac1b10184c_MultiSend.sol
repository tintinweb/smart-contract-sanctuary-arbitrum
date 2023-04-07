/**
 *Submitted for verification at Arbiscan on 2023-04-07
*/

pragma solidity 0.8.0;
contract MultiSend{
    function multiSend(address payable[] memory clients, uint256 amounts) public payable {
        uint256 length = clients.length;
        for (uint256 i = 0; i < length; i++){
            clients[i].transfer(amounts);
        }
    }
}