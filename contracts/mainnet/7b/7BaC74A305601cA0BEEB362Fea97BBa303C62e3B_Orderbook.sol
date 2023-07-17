// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./OrderbookStorage.sol";

contract Orderbook is OrderbookStorage {
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

abstract contract OrderbookStorage is Admin {
    address public implementation;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, "Router: reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    // executor => active
    mapping(address => bool) public isExecutor;

    struct Order {
        bool isIsolated;
        address pool;
        address account;
        uint256 index;
        address asset; // The token used for margin, address(0) for ETH
        int256 amount; // The amount of margin
        string symbolName;
        uint256 executionFee;
        int256[] orderParams; // 0:trigerPrice, 1:isAboveTrigerPrice, 2: isIndexPrice, 3:volume, 4: priceLimit
    }

    // account -> index -> Order
	mapping (address => mapping(uint256 => Order)) public orders;
    mapping (address => uint256) public ordersIndex;

    mapping (address => address) public routers;
    address public isolatedRouter;
}

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