// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import {InitializableInterface, Initializable} from "./Initializable.sol";

abstract contract ERC20H is Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.holographer')) - 1)
   */
  bytes32 constant _holographerSlot = 0x9d18ffc4ec8de69fbcc9e22571d0625b23c1bcde4b3ded4489551c34c1a78cd4;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.owner')) - 1)
   */
  bytes32 constant _ownerSlot = 0x09f0f4aad16401d8d9fa2f59a36c61cf8593c814849bbc8ef7ed5c0c63e0e28f;

  modifier onlyHolographer() {
    require(msg.sender == holographer(), "ERC20: holographer only");
    _;
  }

  modifier onlyOwner() {
    require(msgSender() == _getOwner(), "ERC20: owner only function");
    _;
  }

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external virtual override returns (bytes4) {
    return _init(initPayload);
  }

  function _init(bytes memory /* initPayload*/) internal returns (bytes4) {
    require(!_isInitialized(), "ERC20: already initialized");
    address currentOwner;
    assembly {
      sstore(_holographerSlot, caller())
      currentOwner := sload(_ownerSlot)
    }
    require(currentOwner != address(0), "ERC20: owner not set");
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  /**
   * @dev The Holographer passes original msg.sender via calldata. This function extracts it.
   */
  function msgSender() internal view returns (address sender) {
    assembly {
      switch eq(caller(), sload(_holographerSlot))
      case 0 {
        sender := caller()
      }
      default {
        sender := calldataload(sub(calldatasize(), 0x20))
      }
    }
  }

  /**
   * @dev Address of Holograph ERC20 standards enforcer smart contract.
   */
  function holographer() internal view returns (address _holographer) {
    assembly {
      _holographer := sload(_holographerSlot)
    }
  }

  function supportsInterface(bytes4) external pure virtual returns (bool) {
    return false;
  }

  /**
   * @dev Address of initial creator/owner of the token contract.
   */
  function owner() external view virtual returns (address) {
    return _getOwner();
  }

  function isOwner() external view returns (bool) {
    return (msgSender() == _getOwner());
  }

  function isOwner(address wallet) external view returns (bool) {
    return wallet == _getOwner();
  }

  function _getOwner() internal view returns (address ownerAddress) {
    assembly {
      ownerAddress := sload(_ownerSlot)
    }
  }

  function _setOwner(address ownerAddress) internal {
    assembly {
      sstore(_ownerSlot, ownerAddress)
    }
  }

  function withdraw() external virtual onlyOwner {
    payable(_getOwner()).transfer(address(this).balance);
  }

  receive() external payable virtual {}

  /**
   * @dev Return true for any un-implemented event hooks
   */
  fallback() external payable virtual {
    assembly {
      switch eq(sload(_holographerSlot), caller())
      case 1 {
        mstore(0x80, 0x0000000000000000000000000000000000000000000000000000000000000001)
        return(0x80, 0x20)
      }
      default {
        revert(0x00, 0x00)
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

abstract contract NonReentrant {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.reentrant')) - 1)
   */
  bytes32 constant _reentrantSlot = 0x8f0a4f18077687341390ab92c27af2200503af695de18cbc999e7f3f59cf890b;

  modifier nonReentrant() {
    require(getStatus() != 2, "FRACT10N: reentrant call");
    setStatus(2);
    _;
    setStatus(1);
  }

  constructor() {}

  function getStatus() internal view returns (uint256 status) {
    assembly {
      status := sload(_reentrantSlot)
    }
  }

  function setStatus(uint256 status) internal {
    assembly {
      sstore(_reentrantSlot, status)
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import {HolographedERC20} from "../interface/HolographedERC20.sol";

import {ERC20H} from "./ERC20H.sol";

abstract contract StrictERC20H is ERC20H, HolographedERC20 {
  /**
   * @dev Dummy variable to prevent empty functions from making "switch to pure" warnings.
   */
  bool private _success;

  function bridgeIn(
    uint32 /* _chainId*/,
    address /* _from*/,
    address /* _to*/,
    uint256 /* _amount*/,
    bytes calldata /* _data*/
  ) external virtual onlyHolographer returns (bool) {
    _success = true;
    return true;
  }

  function bridgeOut(
    uint32 /* _chainId*/,
    address /* _from*/,
    address /* _to*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bytes memory _data) {
    /**
     * @dev This is just here to suppress unused parameter warning
     */
    _data = abi.encodePacked(holographer());
    _success = true;
  }

  function afterApprove(
    address /* _owner*/,
    address /* _to*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function beforeApprove(
    address /* _owner*/,
    address /* _to*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function afterOnERC20Received(
    address /* _token*/,
    address /* _from*/,
    address /* _to*/,
    uint256 /* _amount*/,
    bytes calldata /* _data*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function beforeOnERC20Received(
    address /* _token*/,
    address /* _from*/,
    address /* _to*/,
    uint256 /* _amount*/,
    bytes calldata /* _data*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function afterBurn(
    address /* _owner*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function beforeBurn(
    address /* _owner*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function afterMint(
    address /* _owner*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function beforeMint(
    address /* _owner*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function afterSafeTransfer(
    address /* _from*/,
    address /* _to*/,
    uint256 /* _amount*/,
    bytes calldata /* _data*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function beforeSafeTransfer(
    address /* _from*/,
    address /* _to*/,
    uint256 /* _amount*/,
    bytes calldata /* _data*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function afterTransfer(
    address /* _from*/,
    address /* _to*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function beforeTransfer(
    address /* _from*/,
    address /* _to*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = true;
    return _success;
  }

  function onAllowance(
    address /* _owner*/,
    address /* _to*/,
    uint256 /* _amount*/
  ) external virtual onlyHolographer returns (bool success) {
    _success = false;
    return _success;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value) external returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  function approve(address _spender, uint256 _value) external returns (bool success);

  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Burnable {
  function burn(uint256 amount) external;

  function burnFrom(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Metadata {
  function decimals() external view returns (uint8);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity 0.8.13;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface ERC20Permit {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``account``'s tokens,
   * given ``account``'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `account`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``account``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address account,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `account`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``account``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address account) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Receiver {
  function onERC20Received(
    address account,
    address recipient,
    uint256 amount,
    bytes memory data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Safer {
  function safeTransfer(address recipient, uint256 amount) external returns (bool);

  function safeTransfer(address recipient, uint256 amount, bytes memory data) external returns (bool);

  function safeTransferFrom(address account, address recipient, uint256 amount) external returns (bool);

  function safeTransferFrom(
    address account,
    address recipient,
    uint256 amount,
    bytes memory data
  ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface Holographable {
  function bridgeIn(uint32 fromChain, bytes calldata payload) external returns (bytes4);

  function bridgeOut(
    uint32 toChain,
    address sender,
    bytes calldata payload
  ) external returns (bytes4 selector, bytes memory data);
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

/// @title Holograph ERC-20 Fungible Token Standard
/// @dev See https://holograph.network/standard/ERC-20
///  Note: the ERC-165 identifier for this interface is 0xFFFFFFFF.
interface HolographedERC20 {
  // event id = 1
  function bridgeIn(
    uint32 _chainId,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 2
  function bridgeOut(
    uint32 _chainId,
    address _from,
    address _to,
    uint256 _amount
  ) external returns (bytes memory _data);

  // event id = 3
  function afterApprove(address _owner, address _to, uint256 _amount) external returns (bool success);

  // event id = 4
  function beforeApprove(address _owner, address _to, uint256 _amount) external returns (bool success);

  // event id = 5
  function afterOnERC20Received(
    address _token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 6
  function beforeOnERC20Received(
    address _token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 7
  function afterBurn(address _owner, uint256 _amount) external returns (bool success);

  // event id = 8
  function beforeBurn(address _owner, uint256 _amount) external returns (bool success);

  // event id = 9
  function afterMint(address _owner, uint256 _amount) external returns (bool success);

  // event id = 10
  function beforeMint(address _owner, uint256 _amount) external returns (bool success);

  // event id = 11
  function afterSafeTransfer(
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 12
  function beforeSafeTransfer(
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 13
  function afterTransfer(address _from, address _to, uint256 _amount) external returns (bool success);

  // event id = 14
  function beforeTransfer(address _from, address _to, uint256 _amount) external returns (bool success);

  // event id = 15
  function onAllowance(address _owner, address _to, uint256 _amount) external returns (bool success);
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Metadata.sol";
import "./ERC20Permit.sol";
import "./ERC20Receiver.sol";
import "./ERC20Safer.sol";
import "./ERC165.sol";
import "./Holographable.sol";

interface HolographERC20Interface is
  ERC165,
  ERC20,
  ERC20Burnable,
  ERC20Metadata,
  ERC20Receiver,
  ERC20Safer,
  ERC20Permit,
  Holographable
{
  function holographBridgeMint(address to, uint256 amount) external returns (bytes4);

  function sourceBurn(address from, uint256 amount) external;

  function sourceMint(address to, uint256 amount) external;

  function sourceMintBatch(address[] calldata wallets, uint256[] calldata amounts) external;

  function sourceTransfer(address from, address to, uint256 amount) external;

  function sourceTransfer(address payable destination, uint256 amount) external;

  function sourceExternalCall(address target, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface HolographerInterface {
  function getContractType() external view returns (bytes32 contractType);

  function getDeploymentBlock() external view returns (uint256 deploymentBlock);

  function getHolograph() external view returns (address holograph);

  function getHolographEnforcer() external view returns (address);

  function getOriginChain() external view returns (uint32 originChain);

  function getSourceContract() external view returns (address sourceContract);
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

/**
 * @title Holograph Protocol
 * @author https://github.com/holographxyz
 * @notice This is the primary Holograph Protocol smart contract
 * @dev This contract stores a reference to all the primary modules and variables of the protocol
 */
interface HolographInterface {
  /**
   * @notice Get the address of the Holograph Bridge module
   * @dev Used for beaming holographable assets cross-chain
   */
  function getBridge() external view returns (address bridge);

  /**
   * @notice Update the Holograph Bridge module address
   * @param bridge address of the Holograph Bridge smart contract to use
   */
  function setBridge(address bridge) external;

  /**
   * @notice Get the chain ID that the Protocol was deployed on
   * @dev Useful for checking if/when a hard fork occurs
   */
  function getChainId() external view returns (uint256 chainId);

  /**
   * @notice Update the chain ID
   * @dev Useful for updating once a hard fork has been mitigated
   * @param chainId EVM chain ID to use
   */
  function setChainId(uint256 chainId) external;

  /**
   * @notice Get the address of the Holograph Factory module
   * @dev Used for deploying holographable smart contracts
   */
  function getFactory() external view returns (address factory);

  /**
   * @notice Update the Holograph Factory module address
   * @param factory address of the Holograph Factory smart contract to use
   */
  function setFactory(address factory) external;

  /**
   * @notice Get the Holograph chain Id
   * @dev Holograph uses an internal chain id mapping
   */
  function getHolographChainId() external view returns (uint32 holographChainId);

  /**
   * @notice Update the Holograph chain ID
   * @dev Useful for updating once a hard fork was mitigated
   * @param holographChainId Holograph chain ID to use
   */
  function setHolographChainId(uint32 holographChainId) external;

  /**
   * @notice Get the address of the Holograph Interfaces module
   * @dev Holograph uses this contract to store data that needs to be accessed by a large portion of the modules
   */
  function getInterfaces() external view returns (address interfaces);

  /**
   * @notice Update the Holograph Interfaces module address
   * @param interfaces address of the Holograph Interfaces smart contract to use
   */
  function setInterfaces(address interfaces) external;

  /**
   * @notice Get the address of the Holograph Operator module
   * @dev All cross-chain Holograph Bridge beams are handled by the Holograph Operator module
   */
  function getOperator() external view returns (address operator);

  /**
   * @notice Update the Holograph Operator module address
   * @param operator address of the Holograph Operator smart contract to use
   */
  function setOperator(address operator) external;

  /**
   * @notice Get the Holograph Registry module
   * @dev This module stores a reference for all deployed holographable smart contracts
   */
  function getRegistry() external view returns (address registry);

  /**
   * @notice Update the Holograph Registry module address
   * @param registry address of the Holograph Registry smart contract to use
   */
  function setRegistry(address registry) external;

  /**
   * @notice Get the Holograph Treasury module
   * @dev All of the Holograph Protocol assets are stored and managed by this module
   */
  function getTreasury() external view returns (address treasury);

  /**
   * @notice Update the Holograph Treasury module address
   * @param treasury address of the Holograph Treasury smart contract to use
   */
  function setTreasury(address treasury) external;

  /**
   * @notice Get the Holograph Utility Token address
   * @dev This is the official utility token of the Holograph Protocol
   */
  function getUtilityToken() external view returns (address utilityToken);

  /**
   * @notice Update the Holograph Utility Token address
   * @param utilityToken address of the Holograph Utility Token smart contract to use
   */
  function setUtilityToken(address utilityToken) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface InitializableInterface {
  function init(bytes memory initPayload) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import {NonReentrant} from "../abstract/NonReentrant.sol";
import {StrictERC20H} from "../abstract/StrictERC20H.sol";

import {ERC20} from "../interface/ERC20.sol";
import {HolographERC20Interface} from "../interface/HolographERC20Interface.sol";
import {HolographInterface} from "../interface/HolographInterface.sol";
import {HolographerInterface} from "../interface/HolographerInterface.sol";

/**
 * @title Holograph token (aka hToken), used to wrap and bridge native tokens across blockchains.
 * @author Holograph Foundation
 * @notice A smart contract for minting and managing Holograph's Bridgeable ERC20 Tokens.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract FractionToken is NonReentrant, StrictERC20H {
  /**
   * @dev Fee charged on collateral for burning
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.burnFeeBp')) - 1)
   */
  bytes32 constant _burnFeeBpSlot = 0xa4d976174109ff73d791d1f3c56517b800ac914abf17db5851eabd908186e107; // 10000 == 100.00%
  /**
   * @dev Address of ERC20 token that is used as 1:1 token collateral
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.collateral')) - 1)
   */
  bytes32 constant _collateralSlot = 0x7b9af568f431a0130c2ee577a0b1187780519837e50c30c5e304078e39f01572;
  /**
   * @dev Number of decimal places for ERC20 collateral token (computed on insert)
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.collateralDecimals')) - 1)
   */
  bytes32 constant _collateralDecimalsSlot = 0x3bbd0b7b7d73273bdd8a6e80177d56c44be907ef6c71a83994b9a3adba6a25ae;
  /**
   * @dev Mapping (address => bool) of operators approved for token transfer
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.approvedOperators')) - 1)
   */
  bytes32 constant _approvedOperatorsSlot = 0x19f089e7ba2763a1f77aaa09f0e6591050763f6d19e0111fd640641e9cd72c1e;

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external override returns (bytes4) {
    (uint256 burnFeeBp, address fractionTreasury) = abi.decode(initPayload, (uint256, address));
    assembly {
      sstore(_burnFeeBpSlot, burnFeeBp)
      sstore(_ownerSlot, fractionTreasury)
    }
    // run underlying initializer logic
    return _init(initPayload);
  }

  function mint(address recipient, uint256 amount) external nonReentrant {
    ERC20 collateral = _collateral();
    address _holographer = holographer();
    uint256 decimals = _collateralDecimals();
    // adjust decimal to fit collateral
    uint256 collateralAmount = decimals == 18 ? amount : amount / (10 ** (18 - decimals));
    if (decimals != 18) {
      // handle rounding errors by removing any amounts over the collateral decimal places
      amount = collateralAmount * (10 ** (18 - decimals));
    }
    // check collateral allowance for transfer
    require(collateral.allowance(msgSender(), _holographer) >= collateralAmount, "FRACT10N: ERC20 allowance too low");
    // store current balance in memory
    uint256 currentBalance = collateral.balanceOf(_holographer);
    // transfer collateral to token contract
    collateral.transferFrom(msgSender(), _holographer, collateralAmount);
    // check that balance is accurate
    require(
      collateral.balanceOf(_holographer) == (currentBalance + collateralAmount),
      "FRACT10N: ERC20 transfer failed"
    );
    // set recipient to msg sender if empty
    if (recipient == address(0)) {
      recipient = msgSender();
    }
    // mint the token to recipient
    HolographERC20Interface(_holographer).sourceMint(recipient, amount);
  }

  function burn(address collateralRecipient, uint256 amount) public nonReentrant {
    ERC20 collateral = _collateral();
    address _holographer = holographer();
    uint256 decimals = _collateralDecimals();
    address sender = msgSender();
    uint256 burnFee = _burnFeeBp();
    address treasury = _fractionTreasury();
    uint256 treasuryFee = 0;
    // adjust decimal to fit collateral
    uint256 collateralAmount = decimals == 18 ? amount : amount / (10 ** (18 - decimals));
    if (decimals != 18) {
      // handle rounding errors by removing any amounts over the collateral decimal places
      amount = collateralAmount * (10 ** (18 - decimals));
    }
    // store current balance in memory
    uint256 currentBalance = collateral.balanceOf(_holographer);
    // check that enough collateral is in balance
    require(currentBalance >= collateralAmount, "FRACT10N: not enough collateral");
    // burn the token from msg sender
    HolographERC20Interface(_holographer).sourceBurn(sender, amount);
    // check if caller is not Fraction Treasury
    if (sender != treasury && burnFee > 0) {
      // calculate burn fee
      treasuryFee = (collateralAmount * burnFee) / 10000;
      // apply burn fee
      collateralAmount -= treasuryFee;
      // transfer collateral burn fee to Fraction Treasury
      collateral.transferFrom(_holographer, treasury, treasuryFee);
    }
    // set recipient to msg sender if empty
    if (collateralRecipient == address(0)) {
      collateralRecipient = sender;
    }
    // transfer collateral to collateral recipient
    collateral.transferFrom(_holographer, collateralRecipient, collateralAmount);
    // check that balance is accurate
    require(
      collateral.balanceOf(_holographer) == (currentBalance - (collateralAmount + treasuryFee)),
      "FRACT10N: ERC20 transfer failed"
    );
  }

  function bridgeIn(
    uint32 /* _chainId*/,
    address from,
    address to,
    uint256 amount,
    bytes calldata /* _data*/
  ) external override onlyHolographer returns (bool success) {
    address _holographer = holographer();
    // mint the token to original from address
    HolographERC20Interface(_holographer).sourceMint(from, amount);
    if (from != to) {
      // transfer token from address to address only if they are different
      HolographERC20Interface(_holographer).sourceTransfer(from, to, amount);
    }
    success = true;
  }

  function bridgeOut(
    uint32 /* _chainId*/,
    address /* _from*/,
    address /* _to*/,
    uint256 amount
  ) external override onlyHolographer returns (bytes memory _data) {
    ERC20 collateral = _collateral();
    address _holographer = holographer();
    uint256 decimals = _collateralDecimals();
    // adjust decimal to fit collateral
    uint256 collateralAmount = decimals == 18 ? amount : amount / (10 ** (18 - decimals));
    // store current balance in memory
    uint256 currentBalance = collateral.balanceOf(_holographer);
    if (currentBalance < collateralAmount) {
      // adjust collateral amount if less than total balance/supply of token
      collateralAmount = currentBalance;
    }
    collateral.transferFrom(_holographer, _fractionTreasury(), collateralAmount);
    // check that balance is accurate
    require(
      collateral.balanceOf(_holographer) == (currentBalance - collateralAmount),
      "FRACT10N: ERC20 transfer failed"
    );
    _data = "";
  }

  function afterBurn(
    address collateralRecipient,
    uint256 amount
  ) external override onlyHolographer nonReentrant returns (bool success) {
    ERC20 collateral = _collateral();
    address _holographer = holographer();
    uint256 decimals = _collateralDecimals();
    address sender = msgSender();
    uint256 burnFee = _burnFeeBp();
    address treasury = _fractionTreasury();
    uint256 treasuryFee = 0;
    // adjust decimal to fit collateral
    uint256 collateralAmount = decimals == 18 ? amount : amount / (10 ** (18 - decimals));
    if (decimals != 18) {
      // handle rounding errors by removing any amounts over the collateral decimal places
      amount = collateralAmount * (10 ** (18 - decimals));
    }
    // store current balance in memory
    uint256 currentBalance = collateral.balanceOf(_holographer);
    // check that enough collateral is in balance
    require(currentBalance >= collateralAmount, "FRACT10N: not enough collateral");
    // check if caller is not Fraction Treasury
    if (sender != treasury && burnFee > 0) {
      // calculate burn fee
      treasuryFee = (collateralAmount * burnFee) / 10000;
      // apply burn fee
      collateralAmount -= treasuryFee;
      // transfer collateral burn fee to Fraction Treasury
      collateral.transferFrom(_holographer, treasury, treasuryFee);
    }
    // set recipient to msg sender if empty
    if (collateralRecipient == address(0)) {
      collateralRecipient = sender;
    }
    // transfer collateral to collateral recipient
    collateral.transferFrom(_holographer, collateralRecipient, collateralAmount);
    // check that balance is accurate
    require(
      collateral.balanceOf(_holographer) == (currentBalance - (collateralAmount + treasuryFee)),
      "FRACT10N: ERC20 transfer failed"
    );
    success = true;
  }

  function onAllowance(
    address account,
    address operator,
    uint256
  ) external view override onlyHolographer returns (bool success) {
    if (account == _fractionTreasury()) {
      success = false;
    } else {
      success = _approvedOperator(operator);
    }
  }

  function isApprovedOperator(address operator) external view onlyHolographer returns (bool approved) {
    approved = _approvedOperator(operator);
  }

  function getBurnFeeBp() external view returns (uint256 burnFeeBp) {
    burnFeeBp = _burnFeeBp();
  }

  function getCollateral() external view returns (address collateral) {
    collateral = address(_collateral());
  }

  function setApproveOperator(address operator, bool approved) external onlyOwner {
    assembly {
      // load next free memory
      let ptr := mload(0x40)
      // update memory pointer to increment by 64 bytes
      mstore(0x40, add(ptr, 0x40))
      // we are simulating abi.encode
      // add operator in first 32 bytes
      mstore(ptr, operator)
      // add storage slot in next 32 bytes
      mstore(add(ptr, 0x20), _approvedOperatorsSlot)
      // store mapping value to calculated storage slot
      sstore(keccak256(ptr, 0x40), approved)
    }
  }

  function setBurnFeeBp(uint256 burnFeeBp) external onlyOwner {
    require(burnFeeBp < 10001, "FRACT10N: burn fee not bp");
    assembly {
      sstore(_burnFeeBpSlot, burnFeeBp)
    }
  }

  function setCollateral(address collateralAddress) external onlyOwner {
    address collateral;
    assembly {
      collateral := sload(_collateralSlot)
    }
    require(collateral == address(0), "FRACT10N: collateral already set");
    // get collateral address decimals
    uint256 decimals = HolographERC20Interface(collateralAddress).decimals();
    // limit to 18 decimals
    require(decimals < 19, "FRACT10N: maximum 18 decimals");
    assembly {
      sstore(_collateralSlot, collateralAddress)
      sstore(_collateralDecimalsSlot, decimals)
    }
    // use Holographer to enable ERC20 transfers by source
    HolographERC20Interface(holographer()).sourceExternalCall(
      collateralAddress,
      abi.encodeWithSelector(ERC20.approve.selector, address(this), type(uint256).max)
    );
  }

  function _approvedOperator(address operator) internal view returns (bool approved) {
    assembly {
      // load next free memory
      let ptr := mload(0x40)
      // update memory pointer to increment by 64 bytes
      mstore(0x40, add(ptr, 0x40))
      // we are simulating abi.encode
      // add operator in first 32 bytes
      mstore(ptr, operator)
      // add storage slot in next 32 bytes
      mstore(add(ptr, 0x20), _approvedOperatorsSlot)
      // load mapping value from calculated storage slot
      approved := sload(keccak256(ptr, 0x40))
    }
  }

  function _burnFeeBp() internal view returns (uint256 burnFeeBp) {
    assembly {
      burnFeeBp := sload(_burnFeeBpSlot)
    }
  }

  function _collateral() internal view returns (ERC20 collateral) {
    assembly {
      collateral := sload(_collateralSlot)
    }
    require(address(collateral) != address(0), "FRACT10N: collateral not set");
  }

  function _collateralDecimals() internal view returns (uint256 decimals) {
    assembly {
      decimals := sload(_collateralDecimalsSlot)
    }
  }

  function _fractionTreasury() internal view returns (address fractionTreasury) {
    assembly {
      fractionTreasury := sload(0x1136b6b83da8d61ba4fa1d68b5ef128602c708583193e4c55add5660847fff03)
    }
  }
}