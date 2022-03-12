/**
 *Submitted for verification at Arbiscan on 2022-03-12
*/

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.10;

/// @title The manager contract interface for multiple markets and the pools in them
interface IPoolKeeper {
    function isUpkeepRequiredSinglePool(address pool)
        external
        view
        returns (bool);

    function checkUpkeepMultiplePools(address[] calldata pools)
        external
        view
        returns (bool);

    function performUpkeepSinglePool(address pool) external;

    function performUpkeepMultiplePools(address[] calldata pools) external;
}

contract Contract {
    address private constant ADDRESSES =
        0x7b6FfAd58ce09f2a71c01e61F94b1592Bd641876;
    address private constant POOLKEEPER_ADDRESS =
        0x759E817F0C40B11C775d1071d466B5ff5c6ce28e;

    address private testKeeperAddress;

    /*
    constructor(address keeperAddress) {
        testKeeperAddress = keeperAddress;
    }
    */

    function store() external view returns (address) {
        return testKeeperAddress;
    }

    function upkeep() external {
        address[] memory addy = new address[](1);
        addy[0] = ADDRESSES;
        /*
        assembly {
            let success := call(
                gas(),
                ADDRESSES,
                0,

            )
        }
        */
        IPoolKeeper(testKeeperAddress).performUpkeepMultiplePools(addy);
    }
}