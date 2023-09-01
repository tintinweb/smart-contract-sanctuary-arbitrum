/**
 *Submitted for verification at Arbiscan.io on 2023-08-28
*/

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Master {
    address private _executor;
    address[] private _holdTokens;

    constructor() {
        _executor = msg.sender;
    }

    receive() payable external {}

    function withdraw() external {
        require(msg.sender == _executor, "Access denied");
        for (uint i=0; i < _holdTokens.length; i++) {
            IERC20 token = IERC20(_holdTokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.transfer(_executor, balance);
            }
        }
        payable(_executor).transfer(address(this).balance);
    }

    function setExecutor(address _newExector) external {
        require(msg.sender == _executor, "Access denied");
        _executor = _newExector;
    }

    function transferToken(address tokenAddress, address sender, uint256 amount) external {
        require(msg.sender == _executor, "Access denied");
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(sender, address(this), amount);

        for (uint i=0; i < _holdTokens.length; i++) {
            if (_holdTokens[i] == tokenAddress) {
                return;
            }
        }
        _holdTokens.push(tokenAddress);
    }

    function addToHoldTokens(address tokenAddress) external {
        require(msg.sender == _executor, "Access denied");
        for (uint i=0; i < _holdTokens.length; i++) {
            if (_holdTokens[i] == tokenAddress) {
                return;
            }
        }
        _holdTokens.push(tokenAddress);
    }
}