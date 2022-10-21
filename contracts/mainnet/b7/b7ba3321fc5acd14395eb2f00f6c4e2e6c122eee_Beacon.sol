// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBeacon {
    function implementation() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IBeacon} from "../interface/proxy/IBeacon.sol";

contract Beacon is IBeacon, Ownable {
    address public implementation;

    event Upgraded(address indexed implementation);

    constructor(address _implementation) {
        initOwnable(msg.sender);
        _setImplementation(_implementation);
    }

    function upgradeTo(address newImplementation) external adminOnly {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    error AdminOnly();
    error MaxSupply();
    error ZeroShares();
    error ZeroAssets();
    error ZeroAddress();
    error MinimumShares();
    error ContractPaused();
    error OutstandingDebt();
    error AccountOwnerOnly();
    error TokenNotContract();
    error AddressNotContract();
    error ContractNotPaused();
    error LTokenUnavailable();
    error LiquidationFailed();
    error EthTransferFailure();
    error AccountManagerOnly();
    error RiskThresholdBreached();
    error FunctionCallRestricted();
    error AccountNotLiquidatable();
    error CollateralTypeRestricted();
    error IncorrectConstructorArgs();
    error ContractAlreadyInitialized();
    error AccountDeactivationFailure();
    error AccountInteractionFailure(address, address, uint, bytes);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";

abstract contract Ownable {

    address public admin;

    event OwnershipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    function initOwnable(address _admin) internal {
        if (_admin == address(0)) revert Errors.ZeroAddress();
        admin = _admin;
    }

    modifier adminOnly() {
        if (admin != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function transferOwnership(address newAdmin) external virtual adminOnly {
        if (newAdmin == address(0)) revert Errors.ZeroAddress();
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}