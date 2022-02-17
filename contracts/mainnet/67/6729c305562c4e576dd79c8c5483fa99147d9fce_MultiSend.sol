/**
 *Submitted for verification at arbiscan.io on 2022-02-17
*/

pragma solidity >=0.7.0 <0.9.0;

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
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        //(bool sent, bytes memory data) = _to.call{value: msg.value}("");
        //require(sent, "Failed to send Ether");
        
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
    
}