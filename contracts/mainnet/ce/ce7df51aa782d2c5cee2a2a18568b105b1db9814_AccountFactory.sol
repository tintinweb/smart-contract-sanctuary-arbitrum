// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BeaconProxy} from "../proxy/BeaconProxy.sol";
import {IAccount} from "../interface/core/IAccount.sol";
import {IAccountFactory} from "../interface/core/IAccountFactory.sol";

/**
    @title Account Factory
    @notice Factory that creates Account as a beacon proxy
*/
contract AccountFactory is IAccountFactory {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Address of account beacon
    address public beacon;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract constructor
        @param _beacon address of account beacon
    */
    constructor (address _beacon) {
        beacon = _beacon;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Account creator
        @param accountManager Address of account manager
        @dev Emits AccountCreated(account, accountManager) event
        @return account Address of account created
    */
    function create(address accountManager)
        external
        returns (address account)
    {
        account = address(new BeaconProxy(beacon, accountManager));
        emit AccountCreated(account, accountManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccount {
    function activate() external;
    function deactivate() external;
    function addAsset(address token) external;
    function addBorrow(address token) external;
    function removeAsset(address token) external;
    function sweepTo(address toAddress) external;
    function removeBorrow(address token) external;
    function init(address accountManager) external;
    function hasAsset(address) external returns (bool);
    function assets(uint) external returns (address);
    function hasNoDebt() external view returns (bool);
    function activationBlock() external view returns (uint);
    function accountManager() external view returns (address);
    function getAssets() external view returns (address[] memory);
    function getBorrows() external view returns (address[] memory);
    function exec(
        address target,
        uint amt,
        bytes calldata data
    ) external returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccountFactory {

    event AccountCreated(
        address indexed account,
        address indexed accountManager
    );

    function create(address accountManager) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBeacon {
    function implementation() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {StorageSlot} from "../utils/Storage.sol";

abstract contract BaseProxy {

    bytes32 private constant _ADMIN_SLOT =
        bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);

    event AdminChanged(address previousAdmin, address newAdmin);

    modifier adminOnly() {
        if (msg.sender != getAdmin()) revert Errors.AdminOnly();
        _;
    }

    function changeAdmin(address newAdmin) external adminOnly {
        _setAdmin(newAdmin);
    }

    function getAdmin() public view returns (address) {
        return StorageSlot.getAddressAt(_ADMIN_SLOT);
    }

    function _setAdmin(address admin) internal {
        if (admin == address(0)) revert Errors.ZeroAddress();
        emit AdminChanged(getAdmin(), admin);
        StorageSlot.setAddressAt(_ADMIN_SLOT, admin);
    }

    function getImplementation() public virtual returns (address);

    function _delegate(address impl) internal virtual {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)

            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    fallback() external payable {
        _delegate(getImplementation());
    }

    receive() external payable {
        _delegate(getImplementation());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseProxy} from "./BaseProxy.sol";
import {Errors} from "../utils/Errors.sol";
import {StorageSlot} from "../utils/Storage.sol";
import {IBeacon} from "../interface/proxy/IBeacon.sol";

contract BeaconProxy is BaseProxy {

    bytes32 private constant _BEACON_SLOT =
        bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1);

    event BeaconUpgraded(address indexed beacon);

    constructor(address _beacon, address _admin) {
        _setAdmin(_admin);
        _setBeacon(_beacon);
    }

    function changeBeacon(address beacon) external adminOnly {
        _setBeacon(beacon);
    }

    function getBeacon() public view returns (address) {
        return StorageSlot.getAddressAt(_BEACON_SLOT);
    }

    function getImplementation() public override returns (address) {
        return IBeacon(getBeacon()).implementation();
    }

    function _setBeacon(address beacon) internal {
        if (beacon == address(0)) revert Errors.ZeroAddress();
        StorageSlot.setAddressAt(_BEACON_SLOT, beacon);
        emit BeaconUpgraded(beacon);
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

library StorageSlot {
    function getAddressAt(bytes32 slot) internal view returns (address a) {
        assembly {
            a := sload(slot)
        }
    }

    function setAddressAt(bytes32 slot, address address_) internal {
        assembly {
            sstore(slot, address_)
        }
    }
}