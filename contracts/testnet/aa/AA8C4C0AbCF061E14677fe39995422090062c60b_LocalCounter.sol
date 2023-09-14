// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IOmniPortal} from "IOmniPortal.sol";

contract LocalCounter {
    uint256 public count;
    uint256 public globalCount;
    uint256 public globalBlockNumber;
    address public global; // counter address on omni

    mapping(string => uint256) public countByChain;

    IOmniPortal public omni;

    event Increment(uint256 count);

    constructor(IOmniPortal _portal, address _global) {
        count = 0;
        globalCount = 0;
        omni = _portal;
        global = _global;
    }

    function increment() public {
        count += 1;

        if (omni.isXChainTx()) {
            countByChain[omni.txSourceChain()] += 1;
        }

        omni.sendOmniTx(
            global,
            abi.encodeWithSignature("increment()")
        );

        emit Increment(count);
    }

    function incrementOnChain(string memory chain, address counter) public {
        omni.sendXChainTx(
            chain,
            counter,
            abi.encodeWithSignature("increment()")
        );
    }

    function syncGlobalCount(uint64 _blockNumber, bytes calldata _storageProof, uint256 _globalCount) public {
        require(_blockNumber > globalBlockNumber, "LocalCounter: block number must be greater than global block number");

        bytes memory storageSlotKey = abi.encodePacked(hex"02", global, bytes32(uint256(0)));
        bytes memory storageSlotValue = abi.encodePacked(bytes32(_globalCount));

        bool verified = omni.verifyOmniState(_blockNumber, _storageProof, storageSlotKey, storageSlotValue);

        require(verified, "LocalCounter: invalid proof");

        globalCount = _globalCount;
        globalBlockNumber = _blockNumber;
    }
}