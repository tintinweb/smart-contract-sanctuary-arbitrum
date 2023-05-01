/**
 *Submitted for verification at Arbiscan on 2023-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleWallet {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    constructor() {
        owner = msg.sender;
    }

    enum Operation {
        Call,
        DelegateCall
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external onlyOwner returns (bool success) {
        if (operation == Operation.Call) {
            success = executeCall(to, value, data);
        } else if (operation == Operation.DelegateCall) {
            success = executeDelegateCall(to, data);
        }
        require(success == true, "Transaction failed");
    }

    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    function executeDelegateCall(
        address to,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := delegatecall(
                gas(),
                to,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    function deploy(bytes memory code, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }
}