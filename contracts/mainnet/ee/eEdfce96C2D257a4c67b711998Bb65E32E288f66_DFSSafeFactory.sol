/**
 *Submitted for verification at Arbiscan.io on 2024-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;










interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) external returns (bool success);

    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) external view;

    function checkNSignatures(
        address executor,
        bytes32 dataHash,
        bytes memory /* data */,
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    function approveHash(bytes32 hashToApprove) external;

    function domainSeparator() external view returns (bytes32);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function nonce() external view returns (uint256);

    function setFallbackHandler(address handler) external;

    function getOwners() external view returns (address[] memory);

    function isOwner(address owner) external view returns (bool);

    function getThreshold() external view returns (uint256);

    function enableModule(address module) external;

    function isModuleEnabled(address module) external view returns (bool);

    function disableModule(address prevModule, address module) external;

    function getModulesPaginated(
        address start,
        uint256 pageSize
    ) external view returns (address[] memory array, address next);
}







interface ISafeProxyFactory {
    event ProxyCreation(address indexed proxy, address singleton);
    function createProxyWithNonce(address singleton, bytes memory initializer, uint256 saltNonce) external returns (address proxy);
    function proxyCreationCode() external pure returns (bytes memory);
}









contract DFSSafeFactory {
    error UnsupportedChain(uint256);

    struct SafeCreationData {
        address singleton;
        bytes initializer;
        uint256 saltNonce;
    }

    struct SafeExecutionData {
        address to;
        uint256 value;
        bytes data;
        uint8 operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address payable refundReceiver;
        bytes signatures;
    }

    ISafeProxyFactory public safeFactory;

    constructor(){
        uint256 chainId = block.chainid;

        if (chainId == 1){
            safeFactory = ISafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
        } else if (chainId == 10){
            safeFactory = ISafeProxyFactory(0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC);
        } else if (chainId == 42161){
            safeFactory = ISafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
        } else if (chainId == 8453){
            safeFactory = ISafeProxyFactory(0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC);
        } else {
            revert UnsupportedChain(chainId);
        }
    }

    function createSafeAndExecute(SafeCreationData memory _creationData, SafeExecutionData memory _executionData) public payable {
        ISafe createdSafe = ISafe(safeFactory.createProxyWithNonce(
            _creationData.singleton,
            _creationData.initializer,
            _creationData.saltNonce
        ));
        createdSafe.execTransaction{value: msg.value}(
            _executionData.to,
            _executionData.value,
            _executionData.data,
            ISafe.Operation(_executionData.operation),
            _executionData.safeTxGas,
            _executionData.baseGas,
            _executionData.gasPrice,
            _executionData.gasToken,
            _executionData.refundReceiver,
            _executionData.signatures
        );
    }
}