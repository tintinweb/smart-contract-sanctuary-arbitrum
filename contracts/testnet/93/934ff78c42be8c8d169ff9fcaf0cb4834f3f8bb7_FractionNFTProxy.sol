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

abstract contract Owner {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.owner')) - 1)
   */
  bytes32 constant _ownerSlot = 0x09f0f4aad16401d8d9fa2f59a36c61cf8593c814849bbc8ef7ed5c0c63e0e28f;

  modifier onlyOwner() {
    require(msg.sender == getOwner(), "FRACT10N: owner only function");
    _;
  }

  constructor() {}

  function owner() public view returns (address) {
    return getOwner();
  }

  function getOwner() public view returns (address ownerAddress) {
    assembly {
      ownerAddress := sload(_ownerSlot)
    }
  }

  function setOwner(address ownerAddress) public onlyOwner {
    assembly {
      sstore(_ownerSlot, ownerAddress)
    }
  }

  function ownerCall(address target, bytes calldata data) external payable onlyOwner {
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

  function ownerDelegateCall(address target, bytes calldata data) external payable onlyOwner {
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

  function ownerStaticCall(address target, bytes calldata data) external view onlyOwner {
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

interface FractionTreasuryInterface {
  function getFractionToken() external view returns (address fractionToken);

  function getSourceERC20() external view returns (address sourceERC20);

  function getSourceERC721() external view returns (address sourceERC721);

  function setFractionToken(address fractionToken) external;

  function setSourceERC20(address sourceERC20) external;

  function setSourceERC721(address sourceERC721) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface InitializableInterface {
  function init(bytes memory initPayload) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import {FractionTreasuryInterface} from "../interface/FractionTreasuryInterface.sol";

import {Owner} from "../abstract/Owner.sol";
import {InitializableInterface, Initializable} from "../abstract/Initializable.sol";

contract FractionNFTProxy is Owner, Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.treasury')) - 1)
   */
  bytes32 constant _fractionTreasurySlot = 0x1136b6b83da8d61ba4fa1d68b5ef128602c708583193e4c55add5660847fff03;

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "FRACT10N: already initialized");
    (address fractionTreasury, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(_fractionTreasurySlot, fractionTreasury)
      sstore(_ownerSlot, fractionTreasury)
    }
    (bool success, bytes memory returnData) = FractionTreasuryInterface(fractionTreasury)
      .getSourceERC721()
      .delegatecall(abi.encodeWithSelector(InitializableInterface.init.selector, initCode));
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == InitializableInterface.init.selector, "initialization failed");
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function getFractionToken() external view returns (address fractionToken) {
    address fractionTreasury;
    assembly {
      fractionTreasury := sload(_fractionTreasurySlot)
    }
    fractionToken = FractionTreasuryInterface(fractionTreasury).getFractionToken();
  }

  function getFractionTreasury() external view returns (address fractionTreasury) {
    assembly {
      fractionTreasury := sload(_fractionTreasurySlot)
    }
  }

  function setFractionTreasury(address fractionTreasury) external onlyOwner {
    assembly {
      sstore(_fractionTreasurySlot, fractionTreasury)
    }
  }

  receive() external payable {}

  fallback() external payable {
    address fractionTreasury;
    assembly {
      fractionTreasury := sload(_fractionTreasurySlot)
    }
    address fractionNFT = FractionTreasuryInterface(fractionTreasury).getSourceERC721();
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), fractionNFT, 0, calldatasize(), 0, 0)
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