/**
 *Submitted for verification at Arbiscan on 2023-07-28
*/

contract My {
    // mint card bnb
    event test(uint256 value);

    function mintCardETH() public payable {

        payable(msg.sender).transfer(msg.value);
        emit test(msg.value);

    }
}