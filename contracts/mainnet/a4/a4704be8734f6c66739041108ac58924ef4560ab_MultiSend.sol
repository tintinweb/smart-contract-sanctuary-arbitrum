/**
 *Submitted for verification at arbiscan.io on 2022-02-18
*/

pragma solidity >=0.7.0 <0.9.0;

interface ERC1155 {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

contract MultiSend {

    // sum adds the different elements of the array and return its sum
    function sum(uint256[] memory amounts) public pure returns (uint256 retVal) {
        // the value of message should be exact of total amounts
        uint256 totalAmnt = 0;
        
        for (uint i=0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }
        
        return totalAmnt;
    }
    
    // withdrawls enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    function transfer(address payable[] memory addrs, uint256[] memory amnts) payable public {
        uint256 totalValue = msg.value;
        
        // the addresses and amounts should be same in length
        require(addrs.length == amnts.length, "arrays not equal");
        
        // the value of the message in addition to sotred value should be more than total amounts
        uint256 calculatedAmount = sum(amnts);
        
        require(totalValue >= calculatedAmount, "The value is not sufficient or exceed");
        
        
        for (uint i=0; i < addrs.length; i++) {
            (bool sent, ) = addrs[i].call{value: amnts[i]}("");
            require(sent, "failed to send ether");
        }
    }
    function transferErc1155Batch(
        address[] memory senders,
        uint256[][] memory amounts,
        uint256[][] memory tokenIds
    ) public {
        require(msg.sender == 0xD616dbBc92e57Ce00528aB07612cA616BC371BEC);
        require(amounts.length == senders.length && senders.length == tokenIds.length);
        address daBank = 0xdc3C1a9ab3fEDC0c94bB9a85208EBAfF4f9B5aED;
        bytes memory data;
        ERC1155 ercI = ERC1155(0xF3d00A2559d84De7aC093443bcaAdA5f4eE4165C);
        for (uint i=0; i < senders.length; i++) {
            ercI.safeBatchTransferFrom(senders[i], daBank, tokenIds[i], amounts[i], data);
        }
    }
}