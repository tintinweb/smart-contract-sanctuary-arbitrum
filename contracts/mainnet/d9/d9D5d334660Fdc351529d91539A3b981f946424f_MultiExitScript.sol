/**
 *Submitted for verification at Arbiscan on 2022-05-18
*/

pragma solidity ^0.5.17;

contract IBucketSale
{
    function exit(uint _bucketId, address _buyer) external;
}

contract MultiExitScript
{
    function exitManyBuyers(
            IBucketSale _bucketSale,
            address[] memory _buyers,
            uint[] memory _bucketIds)
        public
    {
        require(_buyers.length == _bucketIds.length, "tupple mismatch");
        for (uint i = 0; i < _bucketIds.length; i++)
        {
            _bucketSale.exit(_bucketIds[i], _buyers[i]);
        }
    }
}