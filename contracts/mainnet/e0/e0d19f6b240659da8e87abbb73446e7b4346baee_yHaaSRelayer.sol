/**
 *Submitted for verification at Arbiscan.io on 2024-06-14
*/

/**
 *Submitted for verification at gnosisscan.io on 2024-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract yHaaSRelayer {
    address public owner;
    address public governance;

    mapping(address => bool) public keepers;

    constructor() {
        owner = msg.sender;
        governance = msg.sender;
    }

    function harvestStrategy(address _strategyAddress) public onlyKeepers returns (uint256 profit, uint256 loss) {
        (profit, loss) = StrategyAPI(_strategyAddress).report();
    }

    function tendStrategy(address _strategyAddress) public onlyKeepers {
        StrategyAPI(_strategyAddress).tend();
    }

    function processReport(address _vaultAddress, address _strategyAddress) public onlyKeepers returns (uint256 gain, uint256 loss) {
        (gain, loss) = VaultAPI(_vaultAddress).process_report(_strategyAddress);
    }

    function forwardCall(address debtAllocatorAddress, bytes memory data) public onlyKeepers returns (bool success) {
        (success, ) = debtAllocatorAddress.call(data);
        require(success, "forwardCall failed");
    }

    function setKeeper(address _address, bool _allowed) external virtual onlyAuthorized {
        keepers[_address] = _allowed;
    }

    /**
    @notice Changes the `owner` address.
    @param _owner The new address to assign as `owner`.
    */
    function setOwner(address _owner) external onlyAuthorized {
        require(_owner != address(0));
        owner = _owner;
    }

    /**
    @notice Changes the `governance` address.
    @param _governance The new address to assign as `governance`.
    */
    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0));
        governance = _governance;
    }

    modifier onlyKeepers() {
        require(msg.sender == owner || keepers[msg.sender] == true || msg.sender == governance, "!keeper yHaaSProxy");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == governance, "!authorized");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }
} 

interface StrategyAPI {
    function tend() external;
    function report() external returns (uint256 _profit, uint256 _loss);
}

interface VaultAPI {
    function process_report(address) external returns (uint256 _gain, uint256 _loss);
}