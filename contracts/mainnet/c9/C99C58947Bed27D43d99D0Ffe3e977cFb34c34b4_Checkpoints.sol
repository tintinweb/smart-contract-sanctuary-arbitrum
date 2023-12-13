// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

library Checkpoints {

    struct Checkpoint {
        uint48 timestamp;
        uint16 votingWeight;
        uint64 paid;
        uint64 par;
        uint64 cleanPaid;
    }

    struct History {
        // checkpoints[0].timestamp : counter
        mapping (uint256 => Checkpoint) checkpoints;
    }

    //##################
    //##  Write I/O  ##
    //##################

    function push(
        History storage self,
        uint weight,
        uint paid,
        uint par,
        uint cleanPaid
    ) public {

        uint256 pos = counterOfPoints(self);

        uint48 timestamp = uint48 (block.timestamp);

        Checkpoint memory point = Checkpoint({
            timestamp: timestamp,
            votingWeight: uint16(weight),
            paid: uint64(paid),
            par: uint64(par),
            cleanPaid: uint64(cleanPaid)
        });

        if (self.checkpoints[pos].timestamp == timestamp) {
            self.checkpoints[pos] = point;
        } else {
            self.checkpoints[pos+1] = point;
            _increaseCounter(self);
        }
    }

    function _increaseCounter(History storage self)
        public
    {
        self.checkpoints[0].timestamp++;
    }

    //################
    //##    Read    ##
    //################

    function counterOfPoints(History storage self)
        public view returns (uint256)
    {
        return self.checkpoints[0].timestamp;
    }

    function latest(History storage self)
        public view returns (Checkpoint memory point)
    {
        point = self.checkpoints[counterOfPoints(self)];
    }

    function _average(uint256 a, uint256 b) private pure returns (uint256) {
        return (a & b) + ((a ^ b) >> 1);
    }

    function getAtDate(History storage self, uint256 timestamp)
        public view returns (Checkpoint memory point)
    {
        require(
            timestamp <= block.timestamp,
            "Checkpoints: block not yet mined"
        );

        uint256 high = counterOfPoints(self) + 1;
        uint256 low = 1;
        while (low < high) {
            uint256 mid = _average(low, high);
            if (self.checkpoints[mid].timestamp > timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        if (high > 1) point = self.checkpoints[high - 1];
    }

    function pointsOfHistory(History storage self)
        public view returns (Checkpoint[] memory) 
    {
        uint256 len = counterOfPoints(self);

        Checkpoint[] memory output = new Checkpoint[](len);

        while (len > 0) {
            output[len-1] = self.checkpoints[len];
            len--;
        }

        return output;
    }
    
}