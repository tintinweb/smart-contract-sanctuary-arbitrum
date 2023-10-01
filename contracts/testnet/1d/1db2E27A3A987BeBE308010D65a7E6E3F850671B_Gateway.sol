// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './GatewayStorage.sol';

contract Gateway is GatewayStorage {

    fallback() external payable {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../../utils/Admin.sol';
import '../../utils/Implementation.sol';
import '../../utils/ReentryLock.sol';

abstract contract GatewayStorage is Admin, Implementation, ReentryLock {

    // stateId => value
    mapping(uint8 => bytes32) internal _gatewayStates;

    // bToken => stateId => value
    mapping(address => mapping(uint8 => bytes32)) internal _bTokenStates;

    // dTokenId => stateId => value
    mapping(uint256 => mapping(uint8 => bytes32)) internal _dTokenStates;

    // actionId => executionFee
    mapping(uint256 => uint256) internal _executionFees;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract Admin {

    error OnlyAdmin();

    event NewAdmin(address newAdmin);

    address public admin;

    modifier _onlyAdmin_() {
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    /**
     * @notice Set a new admin for the contract.
     * @dev This function allows the current admin to assign a new admin address without performing any explicit verification.
     *      It's the current admin's responsibility to ensure that the 'newAdmin' address is correct and secure.
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './Admin.sol';

abstract contract Implementation is Admin {

    event NewImplementation(address newImplementation);

    address public implementation;

    // @notice Set a new implementation address for the contract
    function setImplementation(address newImplementation) external _onlyAdmin_ {
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract ReentryLock {

    error Reentry();

    bool internal _mutex;

    // @notice Lock for preventing reentrancy attacks
    modifier _reentryLock_() {
        if (_mutex) {
            revert Reentry();
        }
        _mutex = true;
        _;
        _mutex = false;
    }

}