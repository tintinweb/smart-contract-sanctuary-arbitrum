/**
 *Submitted for verification at Arbiscan.io on 2023-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract arbGoodMorningNetWorkProxy {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _implementation() internal view virtual returns (address);

    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable {}
}

contract arbGoodMorningNetWork is arbGoodMorningNetWorkProxy {
    address private _implementationAddress;
    event ImplementationUpdated(address newImplementation);
    event ETHWithdrawn(address recipient, uint256 amount);

    constructor(address _owner, address _logic) arbGoodMorningNetWorkProxy(_owner) {
        _implementationAddress = _logic;
    }

    function _implementation() internal view override returns (address) {
        return _implementationAddress;
    }

    function updateImplementation(address newImplementation) external onlyOwner {
        _implementationAddress = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }

    function withdrawETH(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Not enough ETH in contract");
        recipient.transfer(amount);
        emit ETHWithdrawn(recipient, amount);
    }
}