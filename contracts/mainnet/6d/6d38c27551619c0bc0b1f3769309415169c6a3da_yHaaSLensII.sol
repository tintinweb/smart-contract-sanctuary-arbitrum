/**
 *Submitted for verification at Arbiscan.io on 2024-06-14
*/

/**
 *Submitted for verification at gnosisscan.io on 2024-03-26
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

/**
@title yearn yHaaS Lens
@author yHaaS
*/

contract yHaaSLensII {

    address public owner;
    address public governance;

    constructor() {
        // Set owner and governance
        owner = msg.sender;
        governance = msg.sender;
    }

    address[] public strategies;
    address[] public strategiesBackup;
    address[] public debtAllocators;
    address[] public debtAllocatorsBackup;
    
    function getStrategies() external view returns (address[] memory) {
        return strategies;
    }

    function getDebtAllocators() external view returns (address[] memory) {
        return debtAllocators;
    }

    function assetsStrategiesAddresses() external view returns (address[] memory) {
        return strategies;
    }

    function backupStrategyList() external onlyAuthorized {
        strategiesBackup = strategies;
    }

    function backupDebtAllocatorsList() external onlyAuthorized {
        debtAllocatorsBackup = debtAllocators;
    }

    function getStrategiesBackup() external view returns (address[] memory) {
        return strategiesBackup;
    }

    function getDebtAllocatorsBackup() external view returns (address[] memory) {
        return debtAllocatorsBackup;
    }

    function addStrategy(address _strategy) external onlyAuthorized {  
        strategies.push(_strategy);
    }

    function addDebtAllocator(address _debtAllocator) external onlyAuthorized {  
        debtAllocators.push(_debtAllocator);
    }

    function replaceStrategyList(address[] calldata _strategyList) external onlyAuthorized {  
        strategies = _strategyList;
    }

    function replaceDebtAllocatorList(address[] calldata _debtAllocatorList) external onlyAuthorized {  
        debtAllocators = _debtAllocatorList;
    }

    function getStrategyIndexFromAddress(address _strategy) external view returns (uint256) {
        uint256 length = strategies.length;
        for (uint256 i; i<length; i++) {
            if (strategies[i] == _strategy) {
                return i;
            }
        }
        return 0;
    }

    function getDebtAllocatorIndexFromAddress(address _debtAllocator) external view returns (uint256) {
        uint256 length = debtAllocators.length;
        for (uint256 i; i<length; i++) {
            if (debtAllocators[i] == _debtAllocator) {
                return i;
            }
        }
        return 0;
    }

    function getStrategyAddressFromIndex(uint256 _index) external view returns (address) {
        return strategies[_index];
    }

    function getDebtAllocatorAddressFromIndex(uint256 _index) external view returns (address) {
        return debtAllocators[_index];
    }

    function removeStrategy(address _strategy) external onlyAuthorized {
        uint256 length = strategies.length;
        for (uint256 i; i<length; i++) {
            if (strategies[i] == _strategy) {
                strategies[i] = strategies[length - 1];
                strategies.pop();
                break;
            }
        }
    }

    function removeDebtAllocator(address _debtAllocator) external onlyAuthorized {
        uint256 length = debtAllocators.length;
        for (uint256 i; i<length; i++) {
            if (debtAllocators[i] == _debtAllocator) {
                debtAllocators[i] = debtAllocators[length - 1];
                debtAllocators.pop();
                break;
            }
        }
    }

    function removeStrategyByIndex(uint256 _index) public onlyAuthorized {
        strategies[_index] = strategies[strategies.length - 1];
        strategies.pop();
    }

    function removeDebtAllocatorByIndex(uint256 _index) public onlyAuthorized {
        debtAllocators[_index] = debtAllocators[debtAllocators.length - 1];
        debtAllocators.pop();
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

    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == governance, "!authorized");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }
}