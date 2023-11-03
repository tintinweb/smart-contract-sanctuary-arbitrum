/**
 *Submitted for verification at Arbiscan.io on 2023-11-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-11-01
*/
/**
 *Submitted for verification at Etherscan.io on 2023-10-20
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @title CreateDeploy Contract
 * @notice This contract deploys new contracts using the `CREATE` opcode and is used as part of
 * the `CREATE3` deployment method.
 */
contract CreateDeploy {
    /**
     * @dev Deploys a new contract with the specified bytecode using the `CREATE` opcode.
     * @param bytecode The bytecode of the contract to be deployed
     */
    // slither-disable-next-line locked-ether
    function deploy(bytes memory bytecode) external payable {
        assembly {
            if iszero(create(0, add(bytecode, 32), mload(bytecode))) {
                revert(0, 0)
            }
        }
    }
}
contract Create3Address {
    /// @dev bytecode hash of the CreateDeploy helper contract
    bytes32 internal immutable createDeployBytecodeHash;
    constructor() {
        createDeployBytecodeHash = keccak256(type(CreateDeploy).creationCode);
    }
    /**
     * @notice Compute the deployed address that will result from the `CREATE3` method.
     * @param deploySalt A salt to influence the contract address
     * @return deployed The deterministic contract address if it was deployed
     */
    function _create3Address(bytes32 deploySalt) internal view returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex'ff', address(this), deploySalt, createDeployBytecodeHash))))
        );
        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', deployer, hex'01')))));
    }
}
contract MockTokenManager {
    error FlowLimitExceeded(uint256 flowToAdd, uint256 flowLimit);
    error MissingRole(address account, uint8 role);
    error MissingAllRoles(address account, uint256 roles);
    error MissingAnyOfRoles(address account, uint256 roles);
    error NotService(address caller);
    error ReEntrancy();
    event FlowLimitSet(bytes32 indexed tokenId, address operator, uint256 flowLimit);
    event RolesAdded(address indexed account, uint256 roles);
    event RolesRemoved(address indexed account, uint256 roles);
    uint8 constant private OPERATOR_ROLE = 1;
    uint256 public flowAmount;
    uint256 flowLimit;
    constructor() {}
    function emitFlowLimitExceeded(uint flowToAdd) external  {
        if (flowToAdd > flowLimit) revert FlowLimitExceeded(flowToAdd, flowLimit);
        flowAmount += flowToAdd;
    }
    function setFlowLimit(bytes32 tokenId, address operator, uint256 _flowLimit) external {
        flowLimit = _flowLimit;
        emit FlowLimitSet(tokenId, operator, flowLimit);
    }
    function addRoles(address newOperator, uint256 roles) external {
        emit RolesAdded(newOperator, roles);
    }
    function removeRoles(address newOperator, uint256 roles) external {
        emit RolesRemoved(newOperator, roles);
    }
    function emitMissingRole(address account, uint8 role) external {
        revert MissingRole(account, role);
    }
    function emitMissingAllRoles(address account, uint256 roles) external  {
        revert MissingAllRoles(account, roles);
    }
    function emitNotService() external {
        revert NotService(msg.sender);
    }
    function emitReentrancy() external {
        revert ReEntrancy();
    }
    function emitMissingAnyOfRoles(address account, uint256 roles) external {
        revert MissingAnyOfRoles(account, roles);
    }
}
contract MockITS is Create3Address {
    event TokenManagerDeployed(bytes32 indexed tokenId, address tokenManager, uint8 indexed tokenManagerType, bytes params);
    event TokenSent(bytes32 indexed tokenId, string destinationChain, bytes destinationAddress, uint256 indexed amount);
    event TokenSentWithData(
        bytes32 indexed tokenId,
        string destinationChain,
        bytes destinationAddress,
        uint256 indexed amount,
        address indexed sourceAddress,
        bytes data
    );
    event TokenReceived(bytes32 indexed tokenId, string sourceChain,bytes sourceAddress, address indexed destinationAddress, uint256 indexed amount);
    event TokenReceivedWithData(
        bytes32 indexed tokenId,
        string sourceChain,
        bytes sourceAddress,
        address indexed destinationAddress,
        uint256 indexed amount
    );
    mapping(bytes32 => address) public tokenAddresses;
    function deployTokenManager(bytes32 tokenId, uint8 tokenManagerType, bytes memory params) external {
        CreateDeploy create = new CreateDeploy{ salt: tokenId }();
        bytes memory bytecode = abi.encodePacked(type(MockTokenManager).creationCode);
        if (address(create) == address(0)) revert();
        emit TokenManagerDeployed(tokenId, _create3Address(tokenId), tokenManagerType, params);
        // Deploy using create
        create.deploy(bytecode);
    }
    function getValidTokenManagerAddress(bytes32 tokenId) public view returns (address tokenManagerAddress) {
        tokenManagerAddress = _create3Address(tokenId);
        if (tokenManagerAddress.code.length == 0) revert();
    }
    function getTokenAddress(bytes32 tokenId) external view returns (address tokenAddress) {
        return tokenAddresses[tokenId];
    }
    function addToken(bytes32 tokenId, address token) external {
        tokenAddresses[tokenId] = token;
    }
    function sendToken(bytes32 tokenId, string memory destinationChain, bytes memory destinationAddress, uint256 amount) external {
        emit TokenSent(tokenId, destinationChain, destinationAddress, amount);
    }
    function sendTokenWithData(bytes32 tokenId, string memory destinationChain, bytes memory destinationAddress, uint256 amount, address sourceAddress, bytes memory data) external {
        emit TokenSentWithData(tokenId, destinationChain, destinationAddress, amount, sourceAddress, data);
    }
    function recieveToken(bytes32 tokenId, string memory sourceChain, bytes memory sourceAddress, address destinationAddress, uint256 amount) external {
        emit TokenReceived(tokenId, sourceChain, sourceAddress, destinationAddress, amount);
    }
    function recieveTokenWithData(bytes32 tokenId, string memory sourceChain, bytes memory sourceAddress, address destinationAddress, uint256 amount) external {
        emit TokenReceivedWithData(tokenId, sourceChain, sourceAddress, destinationAddress, amount);
    }
}