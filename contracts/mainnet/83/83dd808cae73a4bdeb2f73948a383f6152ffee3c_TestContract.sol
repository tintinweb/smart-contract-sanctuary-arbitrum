// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC165
/// @author Mircea Pasoi
/// @notice Abstract contract for ERC165
/// @dev Based on https://github.com/ethereum/EIPs/pull/881

abstract contract ERC165 {
    /// @dev You must not set element 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev Constructor that adds ERC165 as a supported interface
    constructor() {
        supportedInterfaces[ERC165ID()] = true;
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID];
    }

    /// @dev ID for ERC165 pseudo-introspection
    /// @return ID for ERC165 interface
    // solhint-disable-next-line func-name-mixedcase
    function ERC165ID() public pure returns (bytes4) {
        return this.supportsInterface.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC165
/// @author @fulldecent and @jbaylina
/// @notice A library that detects which interfaces other contracts implement
/// @dev Based on https://github.com/ethereum/EIPs/pull/881

library ERC165Query {
    bytes4 constant internal INVALID_ID = 0xffffffff;
    bytes4 constant internal ERC165_ID = 0x01ffc9a7;

    /// @dev Checks if a given contract address implement a given interface using
    ///  pseudo-introspection (ERC165)
    /// @param _contract Smart contract to check
    /// @param _interfaceId Interface to check
    /// @return `true` if the contract implements both ERC165 and `_interfaceId`
    function doesContractImplementInterface(address _contract, bytes4 _interfaceId)
        internal
        view
        returns (bool)
    {
        bool success;
        bool result;

        (success, result) = noThrowCall(_contract, ERC165_ID);
        if (!success || !result) {
            return false;
        }

        (success, result) = noThrowCall(_contract, INVALID_ID);
        if (!success || result) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if (success && result) {
            return true;
        }
        return false;
    }

    /// @dev `Calls supportsInterface(_interfaceId)` on a contract without throwing an error
    /// @param _contract Smart contract to call
    /// @param _interfaceId Interface to call
    /// @return success `true` if the call was successful
    /// @return result The result of the call
    function noThrowCall(address _contract, bytes4 _interfaceId)
        internal
        view
        returns (bool success, bool result)
    {
        bytes memory payload = abi.encodeWithSelector(ERC165_ID, _interfaceId);
        bytes memory resultData;
        // solhint-disable-next-line avoid-low-level-calls
        (success, resultData) = _contract.staticcall(payload);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(resultData, 0x20))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC165.sol";

/// @title ERC735
/// @author Mircea Pasoi
/// @notice Abstract contract for ERC735

abstract contract ERC735 is ERC165 {
    /// @dev Constructor that adds ERC735 as a supported interface
    constructor() {
        supportedInterfaces[ERC735ID()] = true;
    }

    /// @dev ID for ERC165 pseudo-introspection
    /// @return ID for ERC735 interface
    // solhint-disable-next-line func-name-mixedcase
    function ERC735ID() public pure returns (bytes4) {
        return (
            this.getClaim.selector ^ this.getClaimIdsByType.selector ^
            this.addClaim.selector ^ this.removeClaim.selector ^
            this.changeClaim.selector
        );
    }

    // Topic
    uint256 public constant BIOMETRIC_TOPIC = 1; // you're a person and not a business
    uint256 public constant RESIDENCE_TOPIC = 2; // you have a physical address or reference point
    uint256 public constant REGISTRY_TOPIC = 3;
    uint256 public constant PROFILE_TOPIC = 4; // TODO: social media profiles, blogs, etc.
    uint256 public constant LABEL_TOPIC = 5; // TODO: real name, business name, nick name, brand name, alias, etc.

    // Scheme
    uint256 public constant ECDSA_SCHEME = 1;
    // https://medium.com/@alexberegszaszi/lets-bring-the-70s-to-ethereum-48daa16a4b51
    uint256 public constant RSA_SCHEME = 2;
    // 3 is contract verification, where the data will be call data, and the issuer a contract address to call
    uint256 public constant CONTRACT_SCHEME = 3;

    // Events
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);


    // Functions
    function getClaim(bytes32 _claimId) public view virtual returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);
    function getClaimIdsByType(uint256 _topic) public view virtual returns(bytes32[] memory claimIds);
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes memory _signature, bytes memory _data, string memory _uri) public virtual returns (uint256 claimRequestId);
    function changeClaim(bytes32 _claimId, uint256 _topic, uint256 _scheme, address _issuer, bytes memory _signature, bytes memory _data, string memory _uri) public virtual returns (bool success);
    function removeClaim(bytes32 _claimId) public virtual returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC165Query.sol";
import "./ERC735.sol";

contract TestContract {
    // Implements ERC165
    using ERC165Query for address;
    using ERC165Query for address payable;

    // Events
    event IdentityCalled(bytes data);

    // Counts calls by msg.sender
    mapping (address => uint) public numCalls;

    /// @dev Increments the number of calls from sender
    function callMe() external {
        numCalls[msg.sender] += 1;
    }

    /// @dev Expects to be called by an ERC735 contract and it will emit the label
    ///  of the first LABEL claim in that contract
    function whoCalling()
        external
    {
        // ERC735
        require(msg.sender.doesContractImplementInterface(0xcb1c73dc), "the caller doesn't implement ERC735");
        // Get first LABEL claim
        ERC735 id = ERC735(msg.sender);
        // 5 is LABEL_TOPIC
        bytes32[] memory claimIds = id.getClaimIdsByType(5);
        bytes memory data;
        (, , , , data, ) = id.getClaim(claimIds[0]);
        emit IdentityCalled(data);
    }

    /// @dev Expose method for testing
    function doesContractImplementInterface(address payable _contract, bytes4 _interfaceId)
        external
        view
        returns (bool)
    {
        return _contract.doesContractImplementInterface(_interfaceId);
    }

    /// @dev Always revert
    function supportsInterface(bytes4 _interfaceId)
        external
        pure
        returns (bool)
    {
        require(false, "Don't call me");
        return _interfaceId > 0;
    }

    /// @dev Expose method for testing
    function noThrowCall(address payable _contract, bytes4 _interfaceId)
        external
        view
        returns (bool success, bool result)
    {
        (success, result) = _contract.noThrowCall(_interfaceId);
    }
}