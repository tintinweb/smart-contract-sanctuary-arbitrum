// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IArbSys.sol";


/**
 * @title ArbitrumMultiCall - Aggregate results from multiple read-only function calls
 * @author Michael Elliot <[email protected]>
 * @author Joshua Levine <[email protected]>
 * @author Nick Johnson <[email protected]>
 * @author Corey Caplan <[email protected]>
 */
contract ArbitrumMultiCall {

    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = IArbSys(address(100)).arbBlockNumber();
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            // solium-disable-next-line security/no-low-level-calls
            (bool success, bytes memory result) = calls[i].target.call(calls[i].callData);
            if (!success) {
                if (result.length < 68) {
                    string memory targetString = _addressToString(calls[i].target);
                    revert(string(abi.encodePacked("Multicall::aggregate: revert at <", targetString, ">")));
                } else {
                    // solium-disable-next-line security/no-inline-assembly
                    assembly {
                        result := add(result, 0x04)
                    }
                    string memory targetString = _addressToString(calls[i].target);
                    revert(
                    string(
                        abi.encodePacked(
                            "Multicall::aggregate: revert at <",
                            targetString,
                            "> with reason: ",
                            abi.decode(result, (string))
                        )
                    )
                    );
                }
            }
            returnData[i] = result;
        }
    }

    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(IArbSys(address(100)).arbBlockNumber() - 1);
    }

    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = IArbSys(address(100)).arbBlockNumber();
    }

    function getL1BlockNumber() public view returns (uint256 l1BlockNumber) {
        l1BlockNumber = block.number;
    }

    function _addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}

/*

    Copyright 2020 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;

/**
 * @title IChainlinkAggregator
 * @author Dolomite
 *
 * Gets the latest price from the Chainlink Oracle Network. Amount of decimals depends on the base.
 */
interface IArbSys {
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);
}