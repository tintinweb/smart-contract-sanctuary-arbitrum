// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;
pragma abicoder v2;

import "../interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Multicall } from "../libraries/Multicall.sol";

contract SimpleProxy is Multicall {
    address public owner;
    address public pendingOwner;

    error NotAuthorized();
    error Failed(bytes _returnData);
    event Execute(address indexed _sender, address indexed _target, uint256 _value, bytes _data);

    modifier onlyOwner() {
        if (owner != msg.sender) revert NotAuthorized();
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function setPendingOwner(address _owner) external onlyOwner {
        pendingOwner = _owner;
    }

    function acceptOwner() external onlyOwner {
        owner = pendingOwner;

        pendingOwner = address(0);
    }

    function execute(address _target, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory returnData) = _target.call{ value: msg.value }(_data);

        if (!success) revert Failed(returnData);

        emit Execute(msg.sender, _target, msg.value, _data);

        return returnData;
    }
}