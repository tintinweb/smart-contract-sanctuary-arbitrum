// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {ConfirmedOwner} from "chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {IVerifierProxy} from "./interfaces/IVerifierProxy.sol";
import {IVerifier} from "./interfaces/IVerifier.sol";
import {TypeAndVersionInterface} from "chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import {AccessControllerInterface} from "chainlink/contracts/src/v0.8/interfaces/AccessControllerInterface.sol";
import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";

/**
 * The verifier proxy contract is the gateway for all report verification requests
 * on a chain.  It is responsible for taking in a verification request and routing
 * it to the correct verifier contract.
 */
contract VerifierProxy is
    IVerifierProxy,
    ConfirmedOwner,
    TypeAndVersionInterface
{
    /// @notice This event is emitted whenever a new verifier contract is set
    /// @param oldConfigDigest The config digest that was previously the latest config
    /// digest of the verifier contract at the verifier address.
    /// @param oldConfigDigest The latest config digest of the verifier contract
    /// at the verifier address.
    /// @param verifierAddress The address of the verifier contract that verifies reports for
    /// a given digest
    event VerifierSet(
        bytes32 oldConfigDigest,
        bytes32 newConfigDigest,
        address verifierAddress
    );

    /// @notice This event is emitted whenever a verifier is unset
    /// @param configDigest The config digest that was unset
    /// @param verifierAddress The Verifier contract address unset
    event VerifierUnset(bytes32 configDigest, address verifierAddress);

    /// @notice This event is emitted when a new access controller is set
    /// @param oldAccessController The old access controller address
    /// @param newAccessController The new access controller address
    event AccessControllerSet(
        address oldAccessController,
        address newAccessController
    );

    /// @notice This error is thrown whenever an address tries
    /// to exeecute a transaction that it is not authorized to do so
    error AccessForbidden();

    /// @notice This error is thrown whenever a zero address is passed
    error ZeroAddress();

    /// @notice This error is thrown when trying to set a verifier address
    /// for a digest that has already been initialized
    /// @param configDigest The digest for the verifier that has
    /// already been set
    /// @param verifier The address of the verifier the digest was set for
    error ConfigDigestAlreadySet(bytes32 configDigest, address verifier);

    /// @notice This error is thrown when the verifier at an address does
    /// not conform to the verifier interface
    error VerifierInvalid();

    /// @notice This error is thrown whenever a verifier is not found
    /// @param configDigest The digest for which a verifier is not found
    error VerifierNotFound(bytes32 configDigest);

    /// @notice Mapping between config digests and verifiers
    mapping(bytes32 => address) private s_verifiers;

    /// @notice The contract to control addresses that are allowed to verify reports
    AccessControllerInterface private s_accessController;

    constructor(AccessControllerInterface accessController)
        ConfirmedOwner(msg.sender)
    {
        s_accessController = accessController;
    }

    /**
     * @dev reverts if the caller does not have access by the accessController
     * contract or is the contract itself.
     */
    modifier checkAccess() {
        AccessControllerInterface ac = s_accessController;
        if (address(ac) != address(0) && !ac.hasAccess(msg.sender, msg.data))
            revert AccessForbidden();
        _;
    }

    modifier onlyValidVerifier(address verifierAddress) {
        if (verifierAddress == address(0)) revert ZeroAddress();
        if (
            !IERC165(verifierAddress).supportsInterface(
                IVerifier.verify.selector
            )
        ) revert VerifierInvalid();
        _;
    }

    /// @notice Reverts if the config digest has already been assigned
    /// a verifier
    modifier onlyUnsetConfigDigest(bytes32 configDigest) {
        address configDigestVerifier = s_verifiers[configDigest];
        if (configDigestVerifier != address(0))
            revert ConfigDigestAlreadySet(configDigest, configDigestVerifier);
        _;
    }

    /// @inheritdoc TypeAndVersionInterface
    function typeAndVersion() external pure override returns (string memory) {
        return "VerifierProxy 0.0.1";
    }

    //***************************//
    //       Admin Functions     //
    //***************************//

    /// @notice This function can be called by the contract admin to set
    /// the proxy's access controller contract
    /// @param accessController The new access controller to set
    /// @dev The access controller can be set to the zero address to allow
    /// all addresses to verify reports
    function setAccessController(AccessControllerInterface accessController)
        external
        onlyOwner
    {
        address oldAccessController = address(s_accessController);
        s_accessController = accessController;
        emit AccessControllerSet(
            oldAccessController,
            address(accessController)
        );
    }

    /// @notice Returns the current access controller
    /// @return accessController The current access controller contract
    /// the proxy is using to gate access
    function getAccessController()
        external
        view
        returns (AccessControllerInterface accessController)
    {
        return s_accessController;
    }

    //***************************//
    //  Verification Functions   //
    //***************************//

    /// @inheritdoc IVerifierProxy
    /// @dev Contract skips checking whether or not the current verifier
    /// is valid as it checks this before a new verifier is set.
    function verify(bytes calldata signedReport)
        external
        override
        checkAccess
        returns (bytes memory verifierResponse)
    {
        // First 32 bytes of the signed report is the config digest.
        bytes32 configDigest = bytes32(signedReport);
        address verifierAddress = s_verifiers[configDigest];
        if (verifierAddress == address(0))
            revert VerifierNotFound(configDigest);
        return IVerifier(verifierAddress).verify(signedReport, msg.sender);
    }

    /// @inheritdoc IVerifierProxy
    function initializeVerifier(bytes32 configDigest, address verifierAddress)
        external
        override
        onlyOwner
        onlyValidVerifier(verifierAddress)
        onlyUnsetConfigDigest(configDigest)
    {
        s_verifiers[configDigest] = verifierAddress;
        emit VerifierSet(bytes32(""), configDigest, verifierAddress);
    }

    /// @inheritdoc IVerifierProxy
    function setVerifier(bytes32 currentConfigDigest, bytes32 newConfigDigest)
        external
        override
        onlyUnsetConfigDigest(newConfigDigest)
    {
        if (msg.sender != s_verifiers[currentConfigDigest])
            revert AccessForbidden();
        s_verifiers[newConfigDigest] = msg.sender;
        emit VerifierSet(currentConfigDigest, newConfigDigest, msg.sender);
    }

    /// @inheritdoc IVerifierProxy
    function unsetVerifier(bytes32 configDigest) external override onlyOwner {
        address verifierAddress = s_verifiers[configDigest];
        if (verifierAddress == address(0))
            revert VerifierNotFound(configDigest);
        delete s_verifiers[configDigest];
        emit VerifierUnset(configDigest, verifierAddress);
    }

    /// @inheritdoc IVerifierProxy
    function getVerifier(bytes32 configDigest)
        external
        view
        override
        returns (address)
    {
        return s_verifiers[configDigest];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC165} from "openzeppelin-contracts/interfaces/IERC165.sol";

interface IVerifier is IERC165 {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct verifier.
     * @param signedReport The encoded data to be verified.
     * @param requester The original address that requested to verify the contract.
     * This is only used for logging purposes.
     * @dev Verification is typically only done through the proxy contract so
     * we can't just use msg.sender to log the requester as the msg.sender
     * contract will always be the proxy.
     * @return response The encoded verified response.
     */
    function verify(bytes memory signedReport, address requester)
        external
        returns (bytes memory response);

    /**
     * @notice sets offchain reporting protocol configuration incl. participating oracles
     * @param feedId Feed ID to set config for
     * @param signers addresses with which oracles sign the reports
     * @param offchainTransmitters CSA key for the ith Oracle
     * @param f number of faulty oracles the system can tolerate
     * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
     * @param offchainConfigVersion version number for offchainEncoding schema
     * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
     */
    function setConfig(
        bytes32 feedId,
        address[] memory signers,
        bytes32[] memory offchainTransmitters,
        uint8 f,
        bytes memory onchainConfig,
        uint64 offchainConfigVersion,
        bytes memory offchainConfig
    ) external;

    /**
     * @notice returns the latest config digest and epoch for a feed
     * @param feedId Feed ID to fetch data for
     * @return scanLogs indicates whether to rely on the configDigest and epoch
     * returned or whether to scan logs for the Transmitted event instead.
     * @return configDigest
     * @return epoch
     */
    function latestConfigDigestAndEpoch(bytes32 feedId)
        external
        view
        returns (
            bool scanLogs,
            bytes32 configDigest,
            uint32 epoch
        );

    /**
     * @notice information about current offchain reporting protocol configuration
     * @param feedId Feed ID to fetch data for
     * @return configCount ordinal number of current config, out of all configs applied to this contract so far
     * @return blockNumber block at which this config was set
     * @return configDigest domain-separation tag for current config
     */
    function latestConfigDetails(bytes32 feedId)
        external
        view
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes32 configDigest
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IVerifierProxy {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct verifier.
     * @param signedReport The encoded data to be verified.
     * @return verifierResponse The encoded response from the verifier.
     */
    function verify(bytes memory signedReport)
        external
        returns (bytes memory verifierResponse);

    /**
     * @notice Sets a new verifier for a config digest
     * @param currentConfigDigest The current config digest
     * @param newConfigDigest The config digest to set
     * reports for a given config digest.
     */
    function setVerifier(bytes32 currentConfigDigest, bytes32 newConfigDigest)
        external;

    /**
     * @notice Sets a new verifier for a config digest
     * @param configDigest The config digest to set
     * @param verifierAddr The address of the verifier contract that verifies
     * reports for a given config digest.
     */
    function initializeVerifier(bytes32 configDigest, address verifierAddr)
        external;

    /**
     * @notice Removes a verifier
     * @param configDigest The config digest of the verifier to remove
     */
    function unsetVerifier(bytes32 configDigest) external;

    /**
     * @notice Retrieves the verifier address that verifies reports
     * for a config digest.
     * @param configDigest The config digest to query for
     * @return verifierAddr The address of the verifier contract that verifies
     * reports for a given config digest.
     */
    function getVerifier(bytes32 configDigest)
        external
        view
        returns (address verifierAddr);
}