/**
 *Submitted for verification at Arbiscan on 2023-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract BaseSocialAction {
    mapping(address => bool) public isFulfilled;
    address public owner;
    address public campaign;

    modifier onlyCampaign(){
        require(msg.sender == campaign, "BaseSocialAction: check campaign and action");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseSocialAction: caller is not the owner");
        _;
    }

    function initialize(bytes memory _config) external {
        require(owner == address(0), "BaseSocialAction: already initialized");

        (owner) = abi.decode(_config, (address));
    }

    function setCampaign(address _campaign) external onlyOwner {
        campaign = _campaign;
    }

    function setFulfilled(address _account) external onlyOwner {
        isFulfilled[_account] = true;
    }

    function setOwner(address _account) external onlyOwner {
        owner = _account;
    }

    function execute(address _account, bytes calldata ) external view onlyCampaign{
        require(isFulfilled[_account], "BaseSocialAction: Not verified yet");
    }
}