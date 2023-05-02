/**
 *Submitted for verification at Arbiscan on 2023-05-02
*/

// SPDX-License-Identifier: MIT
///@dev Timelock contract to house the treasury's RAM tokens
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address _from, address _to, uint _amount) external;

    function transfer(address _to, uint _amount) external;

    function balanceOf(address _wallet) external view returns (uint256);
}

contract RamsesTestLocker {
    address public dug;
    event RAM_Withdrawn(uint, address);
    modifier onlyDOG() {
        require(
            msg.sender == dug,
            "Only The Ramses Timelock can call this function!"
        );
        _;
    }

    constructor(address _ramsesTimeLock) {
        dug = _ramsesTimeLock;
    }

    ///@dev only the timelock can call this function
    function withdrawRAM(
        address _RamAddress,
        uint _amount,
        address _to
    ) external onlyDOG {
        IERC20(_RamAddress).transfer(_to, _amount);
        emit RAM_Withdrawn(_amount, _to);
    }

    ///@dev returns the amount of RAM in the contract
    function ramTokensLeft(address _ram) external view returns (uint) {
        return (IERC20(_ram).balanceOf(address(this)));
    }
}