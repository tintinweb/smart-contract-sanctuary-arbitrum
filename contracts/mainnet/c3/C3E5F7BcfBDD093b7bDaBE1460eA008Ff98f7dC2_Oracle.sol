// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './OracleStorage.sol';

contract Oracle is OracleStorage {

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

import '../utils/Admin.sol';
import '../utils/Implementation.sol';

abstract contract OracleStorage is Admin, Implementation {

    // oracleId => baseOracle
    mapping (bytes32 => address) public baseOracles;

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