/**
 *Submitted for verification at Arbiscan.io on 2023-10-31
*/

contract EventEmitter {
    event Test(uint256 indexed _a);

    function trigger() external {
        emit Test(1);
    }
}