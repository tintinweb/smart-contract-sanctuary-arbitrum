/**
 *Submitted for verification at Arbiscan.io on 2024-05-11
*/

// Sources flattened with hardhat v2.17.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/breaker/interfaces/IProject.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.17;

interface IProject {
    function setBreakFlag(bool flag) external;
}


// File contracts/breaker/BreakProxy.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.17;

contract BreakProxy {

    struct authorize{
        address breaker;
        address startUp;
    }

    address public owner;
    mapping(address => authorize) public authorizedMap;

    error NotAuthorized();

    event AddAuthorize(address indexed project, address indexed breaker, address indexed startUp);
    event RmAuthorize(address indexed project);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Break(address indexed project);
    event StartUp(address indexed project);
    
    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    modifier onlyBreaker(address projectContract) {
        if (authorizedMap[projectContract].breaker != msg.sender) revert NotAuthorized();
        _;
    }

    modifier onlyStartUp(address projectContract) {
        if (authorizedMap[projectContract].startUp != msg.sender) revert NotAuthorized();
        _;
    }

    constructor(address owner_){
        owner = owner_;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function setAuthorize(address projectContract, address breaker, address startUp) external onlyOwner {
        authorizedMap[projectContract] = authorize(breaker, startUp);
        emit AddAuthorize(projectContract, breaker, startUp);
    }

    function removeAuthorize(address projectContract) external onlyOwner {
        delete authorizedMap[projectContract];
        emit RmAuthorize(projectContract);
    }

    function closeAll(address projectContract) external onlyBreaker(projectContract) {
        IProject(projectContract).setBreakFlag(true);
        emit Break(projectContract);
    }

    function openAll(address projectContract) external onlyStartUp(projectContract) {
        IProject(projectContract).setBreakFlag(false);
        emit StartUp(projectContract);
    }
}