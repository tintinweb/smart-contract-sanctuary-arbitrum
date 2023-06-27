// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

abstract contract Admin {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.admin')) - 1)
   */
  bytes32 constant _adminSlot = 0xce00b027a69a53c861af45595a8cf45803b5ac2b4ac1de9fc600df4275db0c38;

  modifier onlyAdmin() {
    require(msg.sender == getAdmin(), "FRACT10N: admin only function");
    _;
  }

  constructor() {}

  function admin() public view returns (address) {
    return getAdmin();
  }

  function getAdmin() public view returns (address adminAddress) {
    assembly {
      adminAddress := sload(_adminSlot)
    }
  }

  function setAdmin(address adminAddress) public onlyAdmin {
    assembly {
      sstore(_adminSlot, adminAddress)
    }
  }

  function adminCall(address target, bytes calldata data) external payable onlyAdmin {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
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

  function adminDelegateCall(address target, bytes calldata data) external payable onlyAdmin {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := delegatecall(gas(), target, 0, data.length, 0, 0)
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

  function adminStaticCall(address target, bytes calldata data) external view onlyAdmin {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := staticcall(gas(), target, 0, data.length, 0, 0)
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import {InitializableInterface} from "../interface/InitializableInterface.sol";

abstract contract Initializable is InitializableInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.initialized')) - 1)
   */
  bytes32 constant _initializedSlot = 0xea16ca35b2bc1c07977062f4d8e3e28f8f6d9d37576ddf51150bf265f8912f29;

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external virtual returns (bytes4);

  function _isInitialized() internal view returns (bool initialized) {
    assembly {
      initialized := sload(_initializedSlot)
    }
  }

  function _setInitialized() internal {
    assembly {
      sstore(_initializedSlot, 0x0000000000000000000000000000000000000000000000000000000000000001)
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import {Admin} from "../../abstract/Admin.sol";
import {InitializableInterface, Initializable} from "../../abstract/Initializable.sol";

contract Byte3IncOnChainServicesProxy is Admin, Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.BYTE3.onChainServices')) - 1)
   */
  bytes32 constant _byte3IncOnChainServicesSlot = 0xdcf48dd9c7dab193663c81db86bc26830048c7343421ef8042e45fac76aef060;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.BYTE3.fractionToken')) - 1)
   */
  bytes32 constant _fractionTokenSlot = 0xabbde9d588642a8feacb536d35c2f63246a01aeb35d1c74374133210bbc3cd94;

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "BYTE3: already initialized");
    (address adminAddress, address byte3IncOnChainServices, address fractionToken) = abi.decode(
      data,
      (address, address, address)
    );
    assembly {
      sstore(_adminSlot, adminAddress)
      sstore(_byte3IncOnChainServicesSlot, byte3IncOnChainServices)
      sstore(_fractionTokenSlot, fractionToken)
    }
    (bool success, bytes memory returnData) = byte3IncOnChainServices.delegatecall(
      abi.encodeWithSelector(InitializableInterface.init.selector, "")
    );
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == InitializableInterface.init.selector, "initialization failed");
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function getByte3IncOnChainServices() external view returns (address byte3IncOnChainServices) {
    assembly {
      byte3IncOnChainServices := sload(_byte3IncOnChainServicesSlot)
    }
  }

  function setByte3IncOnChainServices(address byte3IncOnChainServices) external onlyAdmin {
    assembly {
      sstore(_byte3IncOnChainServicesSlot, byte3IncOnChainServices)
    }
  }

  function getFractionToken() external view returns (address fractionToken) {
    assembly {
      fractionToken := sload(_fractionTokenSlot)
    }
  }

  function setFractionToken(address fractionToken) external onlyAdmin {
    assembly {
      sstore(_fractionTokenSlot, fractionToken)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let byte3IncOnChainServices := sload(_byte3IncOnChainServicesSlot)
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), byte3IncOnChainServices, 0, calldatasize(), 0, 0)
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface InitializableInterface {
  function init(bytes memory initPayload) external returns (bytes4);
}