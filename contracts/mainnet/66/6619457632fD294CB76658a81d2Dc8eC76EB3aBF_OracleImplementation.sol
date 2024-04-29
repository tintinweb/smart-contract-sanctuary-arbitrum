// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/IAdmin.sol';
import '../utils/IImplementation.sol';

interface IOracle is IAdmin, IImplementation {

    struct Signature {
        bytes32 oracleId;
        uint256 timestamp;
        int256  value;
        uint8   v;
        bytes32 r;
        bytes32 s;
    }

    function getValue(bytes32 oracleId) external view returns (int256);

    function getValueCurrentBlock(bytes32 oracleId) external view returns (int256);

    function updateOffchainValue(Signature memory s) external;

    function updateOffchainValues(Signature[] memory ss) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import './OracleStorage.sol';

contract OracleImplementation is OracleStorage {

    function setBaseOracle(string memory symbol, address baseOracle) external _onlyAdmin_ {
        bytes32 oracleId = keccak256(abi.encodePacked(symbol));
        baseOracles[oracleId] = baseOracle;
    }

    // @notice Get oracle value without any checking
    function getValue(bytes32 oracleId) public view returns (int256) {
        return IOracle(baseOracles[oracleId]).getValue(oracleId);
    }

    // @notice Get oracle value of current block
    // @dev When source is offchain, value must be updated in current block, otherwise revert
    function getValueCurrentBlock(bytes32 oracleId) public view returns (int256) {
        return IOracle(baseOracles[oracleId]).getValueCurrentBlock(oracleId);
    }

    function updateOffchainValue(IOracle.Signature memory s) public {
        IOracle(baseOracles[s.oracleId]).updateOffchainValue(s);
    }

    function updateOffchainValues(IOracle.Signature[] memory ss) public {
        for (uint256 i = 0; i < ss.length; i++) {
            updateOffchainValue(ss[i]);
        }
    }

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

interface IAdmin {

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IImplementation {

    function setImplementation(address newImplementation) external;

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