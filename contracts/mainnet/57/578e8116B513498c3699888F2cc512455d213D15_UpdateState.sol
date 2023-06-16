// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./UpdateStateStorage.sol";

contract UpdateState is UpdateStateStorage {
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

abstract contract UpdateStateStorage is Admin {

    address public implementation;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, "update: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    uint256 public lastUpdateTimestamp;

    uint256 public lastBatchId;

    uint256 public lastEndTimestamp;

    bool public isFreezed;

    bool public isFreezeStart;

    uint256 public freezeStartTimestamp;

    modifier _notFreezed() {
        require(!isFreezed, "update: freezed");
        _;
    }

    modifier _onlyOperator() {
        require(isOperator[msg.sender], "update: only operator");
        _;
    }

    struct SymbolInfo {
        string symbolName;
        bytes32 symbolId;
        uint256 minVolume;
        uint256 pricePrecision;
        uint256 volumePrecision;
        address marginAsset;
        bool delisted;
    }

    struct SymbolStats {
        int64 indexPrice;
        int64 cumulativeFundingPerVolume;
    }

    struct AccountPosition {
        int64 volume;
        int64 lastCumulativeFundingPerVolume;
        int128 entryCost;
    }

    mapping(address => bool) public isOperator;

    // indexed symbols for looping
    SymbolInfo[] public indexedSymbols;

    // symbolId => symbolInfo
    mapping (bytes32 => SymbolInfo) public symbols;

    // symbolId => symbolStats
    mapping(bytes32 => SymbolStats) public symbolStats;

    // user => asset => balance
    mapping(address => mapping(address => int256)) public balances;

    // account => symbolId => AccountPosition
    mapping(address => mapping(bytes32 => AccountPosition)) public accountPositions;

    // account => hold position #
    mapping(address => int256) public holdPositions;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IAdmin.sol";

abstract contract Admin is IAdmin {
    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, "Admin: only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        require(newAdmin != address(0), "Admin: set to zero address");
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