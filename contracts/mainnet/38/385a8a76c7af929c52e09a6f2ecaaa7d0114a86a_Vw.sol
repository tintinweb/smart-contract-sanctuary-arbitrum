/**
 *Submitted for verification at Arbiscan.io on 2024-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IVWManagerStorageV1 {
    function walletOwner(address wallet) external view returns (address);

    function ownerWallet(address user) external view returns (address);

    function domainSeparator(uint256 chainId) external view returns (bytes32);

    function eip1271Info(bytes32 infoHash) external view returns (bytes memory);

    function infoSender(bytes32 infoHash) external view returns (address);

    function volatileService() external returns (address);

    function protocolFeeOpened() external returns (bool);

    function feeVault() external returns (address);

    function feeProportion() external returns (uint256);

    struct SrcChainConfigStorage {
        bool isSupport;
        address verifyingContract;
        uint256 effectiveTime;
    }

    event VWOwnerChanged(
        address indexed wallet,
        address indexed previousOwner,
        address indexed newOwner
    );

    event TxCanceled(uint256 indexed code);

    event ResetterChanged(address indexed reseter);
}

interface IVWManager is IVWManagerStorageV1 {
    struct VWExecuteParam {
        uint256 code;
        uint256 gasTokenPrice;
        uint256 priorityFee;
        uint256 gasLimit;
        address manager;
        address service;
        address gasToken;
        address feeReceiver;
        bool isGateway;
        bytes data;
        bytes serviceSignature;
        bytes32[] proof;
    }

    function createWallet(address owner) external returns (address wallet);

    function execute(address wallet, VWExecuteParam calldata eParam) external returns (uint resCode);

    function verifyEIP1271Signature(
        address wallet,
        bytes32 digest,
        bytes calldata signature
    ) external view returns (bool isValid);

    function storeInfo(
        bytes memory info,
        bool willDelete
    ) external ;

    function deleteInfo(
        bytes32 infoHash
    ) external ;

    event TxExecuted(
        address indexed wallet,
        address indexed owner,
        uint256 indexed code,
        bytes32 rootHash,
        uint256 resCode
    );

    event VWCreated(address indexed wallet, address indexed owner);

    event Initialized(address deployer);

    event SetFee(bool indexed protocolFeeOpened, address indexed feeVault, uint256 indexed feeProportion);

    event DomainSeparatorRequested(uint256 indexed srcChainID, bool indexed isSupport, address indexed verifyContract, uint256 effectiveTime);

    event DomainSeparatorConfiged(uint256 indexed srcChainID, address indexed verifyContract);

    event DomainSeparatorCanceled(uint256 indexed srcChainID);

    event VWReturnData(bytes returnData);

    event InfoStored(bytes32 indexed infoHash, bytes info);

    event InfoDeleted(bytes32 indexed infoHash);
}

contract Vw {

    constructor(){}

    function createWallet(address _VWManager,address[] calldata _eoas) public returns(address[] memory _vws) {
        for (uint32 i = 0; i<_eoas.length; i++) {
            _vws[i] = createWalletIfNotExists(_VWManager, _eoas[i]);
        }
    }

    // Help to create wallet.
    function createWalletIfNotExists(address _VWManager, address _orderOwner)
    internal
    returns (address wallet)
    {
        wallet = IVWManager(_VWManager).ownerWallet(_orderOwner);
        if (wallet == address(0)) {
            wallet = IVWManager(_VWManager).createWallet(_orderOwner);
        }
    }
}