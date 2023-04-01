// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./VaultStorage.sol";

contract Vault is VaultStorage {
    event NewImplementation(address newImplementation);

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    receive() external payable {}

    fallback() external payable {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../utils/Admin.sol";

abstract contract VaultStorage is Admin {
    address public implementation;

    bool internal _mutex;

    bool public _paused;

    modifier _reentryLock_() {
        require(!_mutex, "Vault: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _notPaused_() {
        require(!_paused, "Vault: paused");
        _;
    }

    bytes32 public domainSeparator;

    address[] public indexedAssets;

    mapping(address => bool) public supportedAsset;

    uint256 public signatureThreshold;

    address[] public validSigners;

    mapping(address => bool) isValidSigner;

    mapping(address => uint256) validatorIndex;

    mapping (bytes32 => bool) public usedHash;

    mapping(address => bool) public isOperator;

    struct RequestWithdraw {
        uint256 index;
        string action;
        address account;
        address inToken;
        uint256 inAmount;
        address outToken;
        uint256 expiry;
        uint256 nonce;
        bytes signatures;
        address caller;
        bytes data;
    }

    mapping(uint256 => RequestWithdraw) public requestWithdraws;

    uint256 public withdrawIndex;

    // account => last withdraw timestamp
    mapping(address => uint256) withdrawTimestamp;

}