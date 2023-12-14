// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC2612, IERC20PermitAllowed} from "./interfaces/IERC2612.sol";
import {IERC20MetaTransaction} from "./interfaces/INativeMetaTransaction.sol";
import {SafePermit} from "./lib/SafePermit.sol";
import {Revert} from "./lib/Revert.sol";

contract PermitAndCall {
  using SafePermit for IERC2612;
  using SafePermit for IERC20PermitAllowed;
  using SafePermit for IERC20MetaTransaction;
  using Revert for bytes;

  address payable public constant target =
    payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF);

  function permitAndCall(
    IERC2612 token,
    bytes4 domainSeparatorSelector,
    address owner,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(domainSeparatorSelector, owner, target, amount, deadline, v, r, s);
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }

  function permitAndCall(
    IERC20PermitAllowed token,
    bytes4 domainSeparatorSelector,
    address owner,
    uint256 nonce,
    uint256 deadline,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(
      domainSeparatorSelector, owner, target, nonce, deadline, allowed, v, r, s
    );
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }

  function permitAndCall(
    IERC20MetaTransaction token,
    bytes4 domainSeparatorSelector,
    address owner,
    uint256 amount,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata data
  ) external payable returns (bytes memory) {
    token.safePermit(domainSeparatorSelector, owner, target, amount, v, r, s);
    (bool success, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!success) {
      returndata.revert_();
    }
    return returndata;
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

import {IERC20} from "./IERC20.sol";

interface IERC20PermitCommon is IERC20 {
  function nonces(address owner) external view returns (uint256);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IERC2612 is IERC20PermitCommon {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

interface IERC20PermitAllowed is IERC20PermitCommon {
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.19;

import {IERC20PermitCommon} from "./IERC2612.sol";

interface INativeMetaTransaction {
  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) external payable returns (bytes memory);
}

interface IERC20MetaTransaction is IERC20PermitCommon, INativeMetaTransaction {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {
  IERC20PermitCommon, IERC2612, IERC20PermitAllowed
} from "../interfaces/IERC2612.sol";
import {IERC20MetaTransaction} from "../interfaces/INativeMetaTransaction.sol";
import {Revert} from "./Revert.sol";

library SafePermit {
  using Revert for bytes;

  bytes32 private constant _PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
  );

  bytes32 private constant _PERMIT_ALLOWED_TYPEHASH = keccak256(
    "Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"
  );

  bytes32 private constant _META_TRANSACTION_TYPEHASH =
    keccak256("MetaTransaction(uint256 nonce,address from,bytes functionSignature)");

  function _bubbleRevert(bool success, bytes memory returndata, string memory message)
    internal
    pure
  {
    if (success) {
      revert(message);
    }
    returndata.revert_();
  }

  function _checkEffects(
    IERC20PermitCommon token,
    address owner,
    address spender,
    uint256 amount,
    uint256 nonce,
    bool success,
    bytes memory returndata
  ) internal view {
    if (nonce == 0) {
      _bubbleRevert(success, returndata, "SafePermit: zero nonce");
    }
    if (token.allowance(owner, spender) != amount) {
      _bubbleRevert(success, returndata, "SafePermit: failed");
    }
  }

  function _getDomainSeparator(IERC20PermitCommon token, bytes4 domainSeparatorSelector)
    internal
    view
    returns (bytes32)
  {
    (bool success, bytes memory domainSeparator) =
      address(token).staticcall(bytes.concat(domainSeparatorSelector));
    if (!success || domainSeparator.length != 32) {
      _bubbleRevert(success, domainSeparator, "SafePermit: domain separator");
    }
    return abi.decode(domainSeparator, (bytes32));
  }

  function _checkSignature(
    IERC20PermitCommon token,
    bytes4 domainSeparatorSelector,
    address owner,
    bytes32 structHash,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bool success,
    bytes memory returndata
  ) internal view {
    bytes32 signingHash = keccak256(
      bytes.concat(
        bytes2("\x19\x01"),
        _getDomainSeparator(token, domainSeparatorSelector),
        structHash
      )
    );
    address recovered = ecrecover(signingHash, v, r, s);
    if (recovered == address(0)) {
      _bubbleRevert(success, returndata, "SafePermit: bad signature");
    }
    if (recovered != owner) {
      _bubbleRevert(success, returndata, "SafePermit: wrong signer");
    }
  }

  function safePermit(
    IERC2612 token,
    bytes4 domainSeparatorSelector,
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    // `permit` could succeed vacuously with no returndata if there's a fallback
    // function (e.g. WETH). `permit` could fail spuriously if it was
    // replayed/frontrun. Avoid these by manually verifying the effects and
    // signature. Insufficient gas griefing is defused by checking the effects.
    (bool success, bytes memory returndata) = address(token).call(
      abi.encodeCall(token.permit, (owner, spender, amount, deadline, v, r, s))
    );
    if (success && returndata.length > 0 && abi.decode(returndata, (bool))) {
      return;
    }

    // Check effects and signature
    uint256 nonce = token.nonces(owner);
    if (block.timestamp > deadline) {
      _bubbleRevert(success, returndata, "SafePermit: expired");
    }
    _checkEffects(token, owner, spender, amount, nonce, success, returndata);
    unchecked {
      nonce--;
    }
    bytes32 structHash =
      keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, amount, nonce, deadline));
    _checkSignature(
      token, domainSeparatorSelector, owner, structHash, v, r, s, success, returndata
    );
  }

  function safePermit(
    IERC20PermitAllowed token,
    bytes4 domainSeparatorSelector,
    address owner,
    address spender,
    uint256 nonce,
    uint256 deadline,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    // See comments above
    (bool success, bytes memory returndata) = address(token).call(
      abi.encodeCall(token.permit, (owner, spender, nonce, deadline, allowed, v, r, s))
    );
    if (success && returndata.length > 0 && abi.decode(returndata, (bool))) {
      return;
    }

    // Check effects and signature
    nonce = token.nonces(owner);
    if (block.timestamp > deadline && deadline > 0) {
      _bubbleRevert(success, returndata, "SafePermit: expired");
    }
    _checkEffects(
      token, owner, spender, allowed ? type(uint256).max : 0, nonce, success, returndata
    );
    unchecked {
      nonce--;
    }
    bytes32 structHash = keccak256(
      abi.encode(_PERMIT_ALLOWED_TYPEHASH, owner, spender, nonce, deadline, allowed)
    );
    _checkSignature(
      token, domainSeparatorSelector, owner, structHash, v, r, s, success, returndata
    );
  }

  function safePermit(
    IERC20MetaTransaction token,
    bytes4 domainSeparatorSelector,
    address owner,
    address spender,
    uint256 amount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    // See comments above
    bytes memory functionSignature = abi.encodeCall(token.approve, (spender, amount));
    (bool success, bytes memory returndata) = address(token).call(
      abi.encodeCall(token.executeMetaTransaction, (owner, functionSignature, r, s, v))
    );
    if (
      success && returndata.length > 0
        && abi.decode(abi.decode(returndata, (bytes)), (bool))
    ) {
      return;
    }

    // Check effects and signature
    uint256 nonce = token.nonces(owner);
    _checkEffects(token, owner, spender, amount, nonce, success, returndata);
    unchecked {
      nonce--;
    }
    bytes32 structHash = keccak256(
      abi.encode(_META_TRANSACTION_TYPEHASH, nonce, owner, keccak256(functionSignature))
    );
    _checkSignature(
      token, domainSeparatorSelector, owner, structHash, v, r, s, success, returndata
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library Revert {
  function revert_(bytes memory reason) internal pure {
    assembly ("memory-safe") {
      revert(add(reason, 0x20), mload(reason))
    }
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.19;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value) external returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value)
    external
    returns (bool success);

  function approve(address _spender, uint256 _value) external returns (bool success);

  function allowance(address _owner, address _spender)
    external
    view
    returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface IERC20Meta is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}