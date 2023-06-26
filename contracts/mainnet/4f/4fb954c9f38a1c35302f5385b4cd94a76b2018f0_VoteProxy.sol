/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

pragma solidity ^0.8.19;

interface IVote {
    function Vote(uint64 daySlot, uint8[3] memory prefers) external;
}

contract VoteProxy {
    function Vote(uint64 daySlot, uint8[3] memory prefers) public {
        IVote(0x374df170102434adDE1456289AE0B84f56E372e3).Vote(daySlot, prefers);
    }
}