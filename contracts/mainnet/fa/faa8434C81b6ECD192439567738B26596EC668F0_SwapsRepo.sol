// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

library SwapsRepo {

    enum StateOfSwap {
        Pending,    
        Issued,
        Closed,
        Terminated
    }

    struct Swap {
        uint16 seqOfSwap;
        uint32 seqOfPledge;
        uint64 paidOfPledge;
        uint32 seqOfTarget;
        uint64 paidOfTarget;
        uint32 priceOfDeal;
        bool isPutOpt;
        uint8 state;
    }

    struct Repo {
        // seqOfSwap => Swap
        mapping(uint256 => Swap) swaps;
    }

    // ###############
    // ##  Modifier ##
    // ###############

    modifier swapExist(Repo storage repo, uint seqOfSwap) {
        require (isSwap(repo, seqOfSwap), "SR.swapExist: not");
        _;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    // ==== cofify / parser ====

    function codifySwap(Swap memory swap) public pure returns (bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            swap.seqOfSwap,
                            swap.seqOfPledge,
                            swap.paidOfPledge,
                            swap.seqOfTarget,
                            swap.paidOfTarget,
                            swap.priceOfDeal,
                            swap.isPutOpt,
                            swap.state);
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function regSwap(
        Repo storage repo,
        Swap memory swap
    ) public returns(Swap memory) {

        require(swap.seqOfTarget * swap.paidOfTarget * swap.seqOfPledge > 0,
            "SWR.regSwap: zero para");

        swap.seqOfSwap = _increaseCounter(repo);

        repo.swaps[swap.seqOfSwap] = swap;
        repo.swaps[0].paidOfTarget += swap.paidOfTarget;

        return swap;
    }

    function payOffSwap(
        Repo storage repo,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice
    ) public returns (Swap memory ) {

        Swap storage swap = repo.swaps[seqOfSwap];

        require(swap.state == uint8(StateOfSwap.Issued), 
            "SWR.payOffSwap: wrong state");

        require (uint(swap.paidOfTarget) * uint(swap.priceOfDeal) / 10 ** 4 * 
            centPrice / 100 <= msgValue, "SWR.payOffSwap: insufficient amt");

        swap.state = uint8(StateOfSwap.Closed);

        return swap;
    }

    function terminateSwap(
        Repo storage repo,
        uint seqOfSwap
    ) public returns (Swap memory){

        Swap storage swap = repo.swaps[seqOfSwap];

        require(swap.state == uint8(StateOfSwap.Issued), 
            "SWR.terminateSwap: wrong state");

        swap.state = uint8(StateOfSwap.Terminated);

        return swap;
    }

    // ==== Counter ====

    function _increaseCounter(Repo storage repo) private returns(uint16) {
        repo.swaps[0].seqOfSwap++;
        return repo.swaps[0].seqOfSwap;
    } 

    // ################
    // ##  Read I/O  ##
    // ################

    function counterOfSwaps(Repo storage repo)
        public view returns (uint16)
    {
        return repo.swaps[0].seqOfSwap;
    }

    function sumPaidOfTarget(Repo storage repo)
        public view returns (uint64)
    {
        return repo.swaps[0].paidOfTarget;
    }

    function isSwap(Repo storage repo, uint256 seqOfSwap)
        public view returns (bool)
    {
        return seqOfSwap <= counterOfSwaps(repo);
    }

    function getSwap(Repo storage repo, uint256 seqOfSwap)
        public view swapExist(repo, seqOfSwap) returns (Swap memory)
    {
        return repo.swaps[seqOfSwap];
    }

    function checkValueOfSwap(
        Repo storage repo,
        uint seqOfSwap,
        uint centPrice
    ) public view returns (uint) {
        Swap memory swap = getSwap(repo, seqOfSwap);
        return uint(swap.paidOfTarget) * uint(swap.priceOfDeal) / 10 ** 4 * 
            centPrice / 100;
    }

    function getAllSwaps(Repo storage repo)
        public view returns (Swap[] memory )
    {
        uint256 len = counterOfSwaps(repo);
        Swap[] memory swaps = new Swap[](len);

        while (len > 0) {
            swaps[len-1] = repo.swaps[len];
            len--;
        }
        return swaps;
    }

    function allSwapsClosed(Repo storage repo)
        public view returns (bool)
    {
        uint256 len = counterOfSwaps(repo);
        while (len > 0) {
            if (repo.swaps[len].state < uint8(StateOfSwap.Closed))
                return false;
            len--;
        }

        return true;        
    }
}