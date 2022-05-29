//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import { IGaugeSnapshotReceiver } from "./interfaces/IGaugeSnapshotReceiver.sol";
import { IChainlink } from "./interfaces/IChainlink.sol";

contract GaugeOracle {
    IGaugeSnapshotReceiver gaugeSnapshotReceiver;
    IChainlink chainlinkCRV;

    constructor(address _gaugeSnapshotReceiverAddress, address _chainlinkCRVAddress) {
        gaugeSnapshotReceiver = IGaugeSnapshotReceiver(_gaugeSnapshotReceiverAddress);
        chainlinkCRV = IChainlink(_chainlinkCRVAddress);
    }

    function getRate(uint256 epochStart, uint256 epochEnd, address gauge) public view returns (uint256 rate) {
        IGaugeSnapshotReceiver.Snapshot[] memory snapshots = gaugeSnapshotReceiver.getSnapshots(gauge);

        uint256 inflationRate;
        uint256 workingSupply;
        uint256 virtualPrice;
        uint256 relativeWeight;

        uint256 counter;

        for (uint256 i = 0; i < snapshots.length; ++i) {
            if (epochStart <= snapshots[i].timestamp && snapshots[i].timestamp <= epochEnd) {
                inflationRate += snapshots[i].inflationRate;
                workingSupply += snapshots[i].workingSupply;
                virtualPrice += snapshots[i].virtualPrice;

                ++counter;

                if (snapshots[i].relativeWeight > 0) relativeWeight = snapshots[i].relativeWeight;
            }
        }

        inflationRate /= counter;
        workingSupply /= counter;
        virtualPrice /= counter;

        uint256 crvPrice = chainlinkCRV.latestAnswer();

        uint256 rate = ((crvPrice * inflationRate * relativeWeight * 86400 * 365) / workingSupply) / virtualPrice;

        return rate;
    }
}

pragma solidity ^0.8.6;

interface IGaugeSnapshotReceiver {
    struct Snapshot {
        address gaugeAddress;
        uint256 timestamp;
        uint256 inflationRate;
        uint256 workingSupply;
        uint256 virtualPrice;
        uint256 relativeWeight;
    }

    function snapshots(address, uint256) external view returns(Snapshot memory);

    function getSnapshots(address _address) external view returns (Snapshot[] memory);

    function getSnapshotsLength(address _address) external view returns(uint256);
}

pragma solidity ^0.8.6;

interface IChainlink {
    function latestAnswer() external view returns(uint256);
}