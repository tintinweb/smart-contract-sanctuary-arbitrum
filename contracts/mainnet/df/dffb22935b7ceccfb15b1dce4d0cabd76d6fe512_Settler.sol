/**
 *Submitted for verification at Arbiscan on 2022-09-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
    function transfer(address _to, uint _amount) external;
}

contract Settler {
    address public immutable SETTLER;
    error OnlySettler();

    constructor(address _settler) {
        SETTLER = _settler;
    }

    modifier onlySettler() {
        if (msg.sender != SETTLER) {
            revert OnlySettler();
        }
        _;
    }

    function withdraw(
        IERC20 _token,
        address _to,
        uint _amount
    ) external onlySettler {
        _token.transfer(_to, _amount);
    }

    function withdrawEth(address payable _to, uint _amount)
        external
        onlySettler
    {
        _to.transfer(_amount);
    }

    receive() external payable {}
}