// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

/**
 * @dev Allows modules to access the implementation slot
 */
contract Implementation {
  /**
   * @notice Updates the Wallet implementation
   * @param _imp New implementation address
   * @dev The wallet implementation is stored on the storage slot
   *   defined by the address of the wallet itself
   *   WARNING updating this value may break the wallet and users
   *   must be confident that the new implementation is safe.
   */
  function _setImplementation(address _imp) internal {
    assembly {
      sstore(address(), _imp)
    }
  }

  /**
   * @notice Returns the Wallet implementation
   * @return _imp The address of the current Wallet implementation
   */
  function _getImplementation() internal view returns (address _imp) {
    assembly {
      _imp := sload(address())
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


library ModuleStorage {
  function writeBytes32(bytes32 _key, bytes32 _val) internal {
    assembly { sstore(_key, _val) }
  }

  function readBytes32(bytes32 _key) internal view returns (bytes32 val) {
    assembly { val := sload(_key) }
  }

  function writeBytes32Map(bytes32 _key, bytes32 _subKey, bytes32 _val) internal {
    bytes32 key = keccak256(abi.encode(_key, _subKey));
    assembly { sstore(key, _val) }
  }

  function readBytes32Map(bytes32 _key, bytes32 _subKey) internal view returns (bytes32 val) {
    bytes32 key = keccak256(abi.encode(_key, _subKey));
    assembly { val := sload(key) }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "../modules/commons/Implementation.sol";
import "../modules/commons/ModuleStorage.sol";


interface SimpleImplementation {
  function imageHash() external view returns (bytes32);
  function externalImageHash() external view returns (bytes32);
}

contract MigratorToDuo is Implementation {
  //                        EXTERNAL_IMAGE_HASH_KEY = keccak256("org.sequence.module.auth.upgradable.image.hash.external");
  bytes32 internal constant EXTERNAL_IMAGE_HASH_KEY = bytes32(0x8c8764b3a50fee69c9bee6e956047501f434fb0e2349c75844a401a7f2a020d2);

  //                        IMAGE_HASH_KEY = keccak256("org.arcadeum.module.auth.upgradable.image.hash");
  bytes32 internal constant IMAGE_HASH_KEY = bytes32(0xea7157fa25e3aa17d0ae2d5280fa4e24d421c61842aa85e45194e1145aa72bf8);

  address public immutable IMPLEMENTATION;
  address public immutable TARGET;
  bytes32 public immutable IMAGE_HASH;
  bytes32 public immutable EXTERNAL_IMAGE_HASH;

  error NotTarget();
  error ImageHashIsZero();
  error ExternalImageHashIsZero();
  error ImplementationNotDeployed();
  error FailedImageHashUpdate();
  error FailedExternalImageHashUpdate();

  event ImageHashUpdated(bytes32 _imageHash);
  event ExternalImageHashUpdated(bytes32 _imageHash);
  event Patched(address indexed _implementation, bytes32 indexed _imageHash, bytes32 indexed _externalImageHash);

  constructor(
    address _mainModuleUpgradableDuo,
    address _target,
    bytes32 _imageHash,
    bytes32 _externalImageHash
  ) {
    if (_imageHash == bytes32(0)) {
      revert ImageHashIsZero();
    }

    if (_externalImageHash == bytes32(0)) {
      revert ExternalImageHashIsZero();
    }

    IMPLEMENTATION = _mainModuleUpgradableDuo;
    TARGET = _target;
    IMAGE_HASH = _imageHash;
    EXTERNAL_IMAGE_HASH = _externalImageHash;
  }

  function migrate() external {
    if (address(this) != TARGET) {
      revert NotTarget();
    }

    if (IMPLEMENTATION.code.length == 0) {
      revert ImplementationNotDeployed();
    }

    _setImplementation(IMPLEMENTATION);

    ModuleStorage.writeBytes32(IMAGE_HASH_KEY, IMAGE_HASH);
    ModuleStorage.writeBytes32(EXTERNAL_IMAGE_HASH_KEY, EXTERNAL_IMAGE_HASH);

    emit ImageHashUpdated(IMAGE_HASH);
    emit ExternalImageHashUpdated(EXTERNAL_IMAGE_HASH);

    if (IMAGE_HASH != SimpleImplementation(address(this)).imageHash()) {
      revert FailedImageHashUpdate();
    }

    if (EXTERNAL_IMAGE_HASH != SimpleImplementation(address(this)).externalImageHash()) {
      revert FailedExternalImageHashUpdate();
    }

    emit Patched(IMPLEMENTATION, IMAGE_HASH, EXTERNAL_IMAGE_HASH);
  }
}