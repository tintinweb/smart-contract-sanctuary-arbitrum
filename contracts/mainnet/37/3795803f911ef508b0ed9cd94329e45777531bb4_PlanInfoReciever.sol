/**
 *Submitted for verification at Arbiscan.io on 2023-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDeGuard {
    function tokenToPlan(uint256 tokenId) external view returns (uint, uint, uint);

    function totalSupply() external view returns (uint256);
}

contract PlanInfoReciever {
    IDeGuard public token;
    address private _owner;
    
    constructor(address initialOwner, address tokenAddress) {
        require(initialOwner != address(0), "Zero address");
        require(tokenAddress != address(0), "Zero address");

        token = IDeGuard(tokenAddress);
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function getPlanMatchesByID(uint planId) public view returns (uint planMatches){
        uint tokenLength = token.totalSupply();

        for (uint tokenId = 0; tokenId <= tokenLength; tokenId++){
            (uint tokenPlanId, , ) = token.tokenToPlan(tokenId);

            if (tokenPlanId == planId) {
                planMatches++;
            } 
        }
    }

    function setNewToken(address tokenAddress) public onlyOwner{
        token = IDeGuard(tokenAddress);
    } 

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(_owner == msg.sender, "Only owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }
}