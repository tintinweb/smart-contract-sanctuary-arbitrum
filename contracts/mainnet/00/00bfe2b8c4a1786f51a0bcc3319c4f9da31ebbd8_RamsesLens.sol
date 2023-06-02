/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPair {
    function balanceOf(address) external view returns (uint256);
}

interface IPairFactory {
    function allPairsLength() external view returns (uint256);
    function allPairs(uint index) external view returns (address);
}
contract RamsesLens {
   
    IPairFactory constant pairFactory = IPairFactory(0xAAA20D08e59F6561f242b08513D36266C5A29415);

    struct PositionPool {
        address id;
        uint256 balanceOf;
    }

    //@notice Returns all LP balances of `accountAddress`.
    function poolsPositionsOf(address accountAddress)
        public
        view
        returns (
            PositionPool[] memory)
    {
        uint256 _poolsLength = pairFactory.allPairsLength();
        PositionPool[]
            memory _poolsPositionsOf = new PositionPool[](
                _poolsLength
            );

        uint256 positionsLength;

        for (uint256 poolIndex; poolIndex < _poolsLength; ++poolIndex) {
            address poolAddress = pairFactory.allPairs(poolIndex);
            uint256 balanceOf = IPair(poolAddress).balanceOf(
                accountAddress
            );
            if (balanceOf > 0) {
                _poolsPositionsOf[positionsLength] = PositionPool({
                    id: poolAddress,
                    balanceOf: balanceOf
                });
                positionsLength++;
            }
        }

        bytes memory encodedPositions = abi.encode(_poolsPositionsOf);
        assembly {
            mstore(add(encodedPositions, 0x40), positionsLength)
        }
        return abi.decode(encodedPositions, (PositionPool[]));
    }
}