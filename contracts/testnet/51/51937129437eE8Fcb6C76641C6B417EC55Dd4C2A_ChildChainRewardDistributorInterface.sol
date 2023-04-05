// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract ChildChainRewardDistributorInterface {
    address public voter; // ChildChain Voter contract
    address public executor; // Anycall executor 
    address public base; // Solid
    uint256 public active_period; // Store active_period like minter

    event NotifyExec(uint256 indexed period, uint256 _amount);
    event SetAnycall(address oldExec, address newExec);
    event Error();

    modifier onlyAuth() {
        require(executor == msg.sender, "!executor");
        _;
    }

    function initialize(
        address _base,
        address _voter, 
        address _executor
    ) public {}

    function exec(
        address,
        address,
        uint256 amount,
        bytes calldata data
    ) external onlyAuth returns (bool success, bytes memory result) {}
    
    // Allow anycall to notify voter on reciept of bridged Solid.
    function _exec(uint256 _amount, bytes memory _data) public returns (bool success, bytes memory result) {}

     /// Setters /// 
    function setAnycallAddresses(address _executor) external {}
    
    // In case rewards are stuck here should be nothing stored on this contract 
    function recoverTokens(address _token, uint256 _amount, address _to) external {}
}