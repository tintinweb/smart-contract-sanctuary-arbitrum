/**
 *Submitted for verification at Arbiscan on 2022-08-01
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

interface IBaseFee {
    function basefee_global() external view returns (uint256);
}

contract BaseFeeOracle {
    // Provider to read current block's base fee
    IBaseFee internal constant baseFeeProvider = IBaseFee(0xFf72f7C5f64ec2fd79B57d1A69C3311C1bB3EEF1);

    // Max acceptable base fee for the operation
    uint256 public maxAcceptableBaseFee;

    // Daddy can grant and revoke access to the setter
    address internal constant gov = 0xb6bc033D34733329971B938fEf32faD7e98E56aD;
    
    // SMS is authorized by default
    address internal constant brain = 0x6346282DB8323A54E840c6C772B4399C9c655C0d;
    
    // Addresses that can set the max acceptable base fee
    mapping(address => bool) public authorizedAddresses;
    
    constructor() {
        maxAcceptableBaseFee = 5 gwei;
        authorizedAddresses[brain] = true;
        authorizedAddresses[gov] = true;
    }
    
    function isCurrentBaseFeeAcceptable() public view returns (bool) {
        uint256 baseFee;
        try baseFeeProvider.basefee_global() returns (uint256 currentBaseFee) {
            baseFee = currentBaseFee;
        } catch {
            // Useful for testing until ganache supports london fork
            // Hard-code current base fee to 1000 gwei
            // This should also help keepers that run in a fork without
            // baseFee() to avoid reverting and potentially abandoning the job
            baseFee = 1000 gwei;
        }

        return baseFee <= maxAcceptableBaseFee;
    }
    
    function setMaxAcceptableBaseFee(uint256 _maxAcceptableBaseFee) external {
        _onlyAuthorized();
        maxAcceptableBaseFee = _maxAcceptableBaseFee;
    }
    
    function setAuthorized(address _target) external {
        _onlyGovernance();
        authorizedAddresses[_target] = true;
    }

    function revokeAuthorized(address _target) external {
        _onlyGovernance();
        authorizedAddresses[_target] = false;
    }
    
    function _onlyAuthorized() internal view {
        require(authorizedAddresses[msg.sender] == true, "!authorized");
    }

    function _onlyGovernance() internal view {
        require(msg.sender == gov, "!governance");
    }
    
}