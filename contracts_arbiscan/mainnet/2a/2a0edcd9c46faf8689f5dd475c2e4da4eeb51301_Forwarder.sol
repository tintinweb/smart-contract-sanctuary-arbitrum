/**
 *Submitted for verification at arbiscan.io on 2022-01-28
*/

pragma solidity ^0.8.0;

contract Forwarder
{
    address public owner;

    constructor(address _owner)
    {
        owner = _owner;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "only owner");
        _;
    }

    event OwnerChanged(address _newOwner);
    function changeOwner(address _newOwner)
        public
        onlyOwner
    {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    event Forwarded(
        address indexed _to,
        bytes _data,
        uint _wei,
        bool _success,
        bytes _resultData);
    function forward(address _to, bytes memory _data, uint _wei)
        public
        onlyOwner
        returns (bool, bytes memory)
    {
        (bool success, bytes memory resultData) = _to.call{ value:_wei }(_data);
        emit Forwarded(_to, _data, _wei, success, resultData);
        return (success, resultData);
    }

    receive ()
        external
        payable
    { }
}