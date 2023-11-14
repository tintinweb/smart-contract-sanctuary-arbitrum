/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ethBalanceMonitor {
    function getWatchList() external view returns (address[] memory);

    function setWatchList(
        address[] calldata addresses,
        uint96[] calldata minBalancesWei,
        uint96[] calldata topUpAmountsWei
    ) external;
}

struct Log {
    uint256 index; // Index of the log in the block
    uint256 timestamp; // Timestamp of the block containing the log
    bytes32 txHash; // Hash of the transaction containing the log
    uint256 blockNumber; // Number of the block containing the log
    bytes32 blockHash; // Hash of the block containing the log
    address source; // Address of the contract that emitted the log
    bytes32[] topics; // Indexed topics of the log
    bytes data; // Data of the log
}

contract WatchlistManager {
    //EthBalanceMonitor private ethBalanceMonitor;

    event AddressAddedToWatchList(address indexed addressToWatch);

    /*
    constructor(address _ethBalanceMonitorAddress) {
        ethBalanceMonitor = EthBalanceMonitor(_ethBalanceMonitorAddress);
    }
    */

    function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        performData = abi.encode(log.data);
    }

    function performUpkeep(bytes calldata performData) external {
        address onRamp = abi.decode(performData, (address));
        emit AddressAddedToWatchList(onRamp);
    }

    function addAddressToWatchlist(address[] calldata addresses)
        external
    {
        /*address[] memory currentWatchlist = ethBalanceMonitor.getWatchList();
        address[] memory updatedWatchlist = new address[](
            currentWatchlist.length + addresses.length
        );

        for (uint256 i = 0; i < currentWatchlist.length; i++) {
            updatedWatchlist[i] = currentWatchlist[i];
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            updatedWatchlist[currentWatchlist.length + i] = addresses[i];
        }

        ethBalanceMonitor.setWatchList(updatedWatchlist);
        */
    }

    function removeAddressFromWatchlist(address removeAddress)
        external
    {
        /*address[] memory currentWatchlist = ethBalanceMonitor.getWatchList();
        address[] memory updatedWatchlist = new address[](
            currentWatchlist.length - 1
        );
        uint256 updatedIndex = 0;

        for (uint256 i = 0; i < currentWatchlist.length; i++) {
            if (currentWatchlist[i] != removeAddress) {
                updatedWatchlist[updatedIndex] = currentWatchlist[i];
                updatedIndex++;
            }
        }

        ethBalanceMonitor.setWatchList(updatedWatchlist);
        */
    }

}