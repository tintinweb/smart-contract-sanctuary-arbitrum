// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

// This contract is a placeholder until DTRA staking is live.
// Once DTRA staking is live, revenue will be automatically distributed to staking pools.
contract DeTraFeeHandlerV1 is Ownable {

    function withdrawETH(uint256 _amount, address payable _account) external onlyOwner {
        _account.transfer( _amount);
    }

    function withdraw(address _token, uint256 _amount, address _account) external onlyOwner {
        IERC20(_token).transfer(_account, _amount);
    }

    function getBalance(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
}