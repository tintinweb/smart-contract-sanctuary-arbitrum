// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./Enums.sol";

struct ContractScopedConfig {
  Scope scope;
  Operation operation;
}

struct Role {
  mapping(address => ContractScopedConfig) contracts;
  mapping(bytes32 => uint256) functions;
  mapping(bytes32 => bytes32) targetValues;
}

library Permissions {
  uint256 internal constant _SCOPE_MAX_PARAMS = 48;
  uint256 internal constant _ETH_VALUE_SLOT =
    0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

  event AllowContract(
    bytes32 roleName,
    address theContract,
    Operation operation
  );

  event RevokeContract(bytes32 roleName, address theContract);

  event ScopeContract(bytes32 roleName, address theContract);

  event AllowFunction(
    bytes32 roleName,
    address theContract,
    bytes4 functionSig,
    Operation operation,
    uint256 funcScopedConfig
  );

  event RevokeFunction(
    bytes32 roleName,
    address theContract,
    bytes4 functionSig,
    uint256 funcScopedConfig
  );

  event ScopeFunction(
    bytes32 roleName,
    address theContract,
    bytes4 functionSig,
    uint256 ethValueLimit,
    bool[] isScopeds,
    ParameterType[] parameterTypes,
    Comparison[] comparisons,
    bytes[] targetValues,
    Operation operation,
    uint256 funcScopedConfig
  );

  function verify(
    Role storage role,
    address to,
    uint256 value,
    bytes calldata data,
    Operation operation
  ) public view {
    _verifyTransaction(role, to, value, data, operation);
  }

  function _verifyTransaction(
    Role storage role,
    address theContract,
    uint256 value,
    bytes memory data,
    Operation operation
  ) internal view {
    require(data.length >= 4, "Permissions: function signature too short");

    ContractScopedConfig storage scopedConfig = role.contracts[theContract];
    require(
      scopedConfig.scope != Scope.None,
      "Permissions: contract not allowed"
    );

    if (scopedConfig.scope == Scope.Contract) {
      _verifyOperation(operation, scopedConfig.operation);
      return;
    } else if (scopedConfig.scope == Scope.Function) {
      uint256 funcScopedConfig = role.functions[
        _key4Func(theContract, bytes4(data))
      ];

      require(funcScopedConfig != 0, "Permissions: function not allowed");
      (Operation configOperation, bool isBypass, ) = _unpackLeft(
        funcScopedConfig
      );

      _verifyOperation(operation, configOperation);

      if (!isBypass) {
        _verifyEthValue(role, theContract, value, data);
        _verifyParameters(role, funcScopedConfig, theContract, data);
      }

      return;
    }

    require(false, "Permissions: should not be here");
  }

  function _verifyEthValue(
    Role storage role,
    address theContract,
    uint256 value,
    bytes memory data
  ) internal view {
    bytes4 funcSig = bytes4(data);
    bytes32 key = _key4FuncArg(theContract, funcSig, _ETH_VALUE_SLOT);
    require(
      bytes32(value) <= role.targetValues[key],
      "Permissions: eth value isn't less than or equal to limit"
    );
  }

  function _verifyParameters(
    Role storage role,
    uint256 funcScopedConfig,
    address theContract,
    bytes memory data
  ) internal view {
    bytes4 funcSig = bytes4(data);
    (, , uint256 argsCount) = _unpackLeft(funcScopedConfig);

    for (uint256 i = 0; i < argsCount; ++i) {
      (
        bool isScoped,
        ParameterType parameterType,
        Comparison comparison
      ) = _unpackRight(funcScopedConfig, i);

      if (!isScoped) {
        continue;
      }

      bytes32 inputValue;
      if (parameterType != ParameterType.Static) {
        inputValue = _pluckDynamicValue(data, parameterType, i);
      } else {
        inputValue = _pluckStaticValue(data, i);
      }

      bytes32 key = _key4FuncArg(theContract, funcSig, i);
      _verifyComparison(comparison, inputValue, role.targetValues[key]);
    }
  }

  function _verifyComparison(
    Comparison comparison,
    bytes32 inputValue,
    bytes32 targetValue
  ) internal pure {
    if (comparison == Comparison.Eq) {
      require(
        inputValue == targetValue,
        "Permissions: input value isn't equal to target value"
      );
      return;
    } else if (comparison == Comparison.Gte) {
      require(
        inputValue >= targetValue,
        "Permissions: input value isn't greater than or equal to target value"
      );
      return;
    } else if (comparison == Comparison.Lte) {
      require(
        inputValue <= targetValue,
        "Permissions: input value isn't less than or equal to target value"
      );
      return;
    }

    require(false, "Permissions: invalid comparison");
  }

  function _verifyOperation(Operation inputOperation, Operation configOperation)
    internal
    pure
  {
    require(
      configOperation != Operation.None,
      "Permissions: opearion not config"
    );

    if (configOperation == Operation.Call) {
      require(
        inputOperation == Operation.Call,
        "Permissions: require call operation"
      );
      return;
    } else if (configOperation == Operation.DelegateCall) {
      require(
        inputOperation == Operation.DelegateCall,
        "Permissions: require delegatecall operation"
      );
      return;
    } else if (configOperation == Operation.Both) {
      require(
        inputOperation == Operation.Call ||
          inputOperation == Operation.DelegateCall,
        "Permissions: require call or delegatecall operation"
      );
      return;
    }

    require(false, "Permissions: invalid input operation");
  }

  function _key4Func(address addr, bytes4 funcSig)
    internal
    pure
    returns (bytes32)
  {
    return bytes32(abi.encodePacked(addr, funcSig));
  }

  function _key4FuncArg(
    address addr,
    bytes4 funcSig,
    uint256 index
  ) public pure returns (bytes32) {
    return bytes32(abi.encodePacked(addr, funcSig, uint8(index)));
  }

  function _pluckStaticValue(bytes memory data, uint256 index)
    internal
    pure
    returns (bytes32)
  {
    // pre-check: is there a word available for the current parameter at argumentsBlock?
    require(
      data.length >= 4 + index * 32 + 32,
      "Permissions: calldata out of bounds for static type"
    );

    uint256 offset = 4 + index * 32;
    bytes32 value;
    assembly {
      // add 32 - jump over the length encoding of the data bytes array
      value := mload(add(32, add(data, offset)))
    }
    return value;
  }

  function _pluckDynamicValue(
    bytes memory data,
    ParameterType parameterType,
    uint256 index
  ) internal pure returns (bytes32) {
    require(
      parameterType != ParameterType.Static,
      "Permissions: only non-static type here"
    );
    // pre-check: is there a word available for the current parameter at argumentsBlock?
    require(
      data.length >= 4 + index * 32 + 32,
      "Permissions: calldata out of bounds for dynamic type at the first"
    );

    /*
     * Encoded calldata:
     * 4  bytes -> function selector
     * 32 bytes -> sequence, one chunk per parameter
     *
     * There is one (bytes32) chunk per parameter. Depending on type it contains:
     * Static    -> value encoded inline (not plucked by this function)
     * Dynamic   -> a byte offset to encoded data payload
     * Dynamic32 -> a byte offset to encoded data payload
     * Note: Fixed Sized Arrays (e.g., bool[2]), are encoded inline
     * Note: Nested types also do not follow the above described rules, and are unsupported
     * Note: The offset to payload does not include 4 bytes for functionSig
     *
     *
     * At encoded payload, the first 32 bytes are the length encoding of the parameter payload. Depending on ParameterType:
     * Dynamic   -> length in bytes
     * Dynamic32 -> length in bytes32
     * Note: Dynamic types are: bytes, string
     * Note: Dynamic32 types are non-nested arrays: address[] bytes32[] uint[] etc
     */

    // the start of the parameter block
    // 32 bytes - length encoding of the data bytes array
    // 4  bytes - function sig
    uint256 argumentsBlock;
    assembly {
      argumentsBlock := add(data, 36)
    }

    // the two offsets are relative to argumentsBlock
    uint256 offset = index * 32;
    uint256 offsetPayload;
    assembly {
      offsetPayload := mload(add(argumentsBlock, offset))
    }

    uint256 lengthPayload;
    assembly {
      lengthPayload := mload(add(argumentsBlock, offsetPayload))
    }

    // account for:
    // 4  bytes - functionSig
    // 32 bytes - length encoding for the parameter payload
    uint256 start = 4 + offsetPayload + 32;
    uint256 end = start +
      (
        parameterType == ParameterType.Dynamic32
          ? lengthPayload * 32
          : lengthPayload
      );

    // are we slicing out of bounds?
    require(
      data.length >= end,
      "Permissions: calldata out of bounds for dynamic type at the end"
    );

    return keccak256(_slice(data, start, end));
  }

  function _slice(
    bytes memory data,
    uint256 start,
    uint256 end
  ) internal pure returns (bytes memory result) {
    result = new bytes(end - start);
    for (uint256 j = start; j < end; j++) {
      result[j - start] = data[j];
    }
  }

  function allowContract(
    Role storage role,
    bytes32 roleName,
    address theContract,
    Operation operation
  ) external {
    role.contracts[theContract] = ContractScopedConfig(
      Scope.Contract,
      operation
    );

    emit AllowContract(roleName, theContract, operation);
  }

  function revokeContract(
    Role storage role,
    bytes32 roleName,
    address theContract
  ) external {
    role.contracts[theContract] = ContractScopedConfig(
      Scope.None,
      Operation.None
    );

    emit RevokeContract(roleName, theContract);
  }

  function scopeContract(
    Role storage role,
    bytes32 roleName,
    address theContract
  ) external {
    role.contracts[theContract] = ContractScopedConfig(
      Scope.Function,
      Operation.None
    );

    emit ScopeContract(roleName, theContract);
  }

  function allowFunction(
    Role storage role,
    bytes32 roleName,
    address theContract,
    bytes4 funcSig,
    Operation operation
  ) external {
    uint256 funcScopedConfig = _packLeft(0, operation, true, 0);
    role.functions[_key4Func(theContract, funcSig)] = funcScopedConfig;

    emit AllowFunction(
      roleName,
      theContract,
      funcSig,
      operation,
      funcScopedConfig
    );
  }

  function revokeFunction(
    Role storage role,
    bytes32 roleName,
    address theContract,
    bytes4 funcSig
  ) external {
    role.functions[_key4Func(theContract, funcSig)] = 0;
    emit RevokeFunction(roleName, theContract, funcSig, 0);
  }

  function scopeFunction(
    Role storage role,
    bytes32 roleName,
    address theContract,
    bytes4 funcSig,
    uint256 ethValueLimit,
    bool[] memory isScopeds,
    ParameterType[] memory parameterTypes,
    Comparison[] memory comparisons,
    bytes[] calldata targetValues,
    Operation operation
  ) external {
    uint256 argsCount = isScopeds.length;

    require(
      argsCount <= _SCOPE_MAX_PARAMS,
      "Permissions: parameters count exceeded"
    );
    require(
      argsCount == parameterTypes.length &&
        argsCount == comparisons.length &&
        argsCount == targetValues.length,
      "Permissions: length of arrays should be the same"
    );

    for (uint256 i = 0; i < argsCount; ++i) {
      if (!isScopeds[i]) {
        continue;
      }

      _enforceConfigComparison(parameterTypes[i], comparisons[i]);
      _enforceTargetValue(parameterTypes[i], targetValues[i]);
    }

    uint256 funcScopedConfig = _packLeft(0, operation, false, argsCount);

    for (uint256 i = 0; i < argsCount; ++i) {
      funcScopedConfig = _packRight(
        funcScopedConfig,
        i,
        isScopeds[i],
        parameterTypes[i],
        comparisons[i]
      );
    }

    role.functions[_key4Func(theContract, funcSig)] = funcScopedConfig;

    for (uint256 i = 0; i < argsCount; ++i) {
      role.targetValues[
        _key4FuncArg(theContract, funcSig, i)
      ] = _compressTargetValue(parameterTypes[i], targetValues[i]);
    }

    role.targetValues[
      _key4FuncArg(theContract, funcSig, _ETH_VALUE_SLOT)
    ] = _compressTargetValue(
      ParameterType.Static,
      abi.encodePacked(ethValueLimit)
    );

    emit ScopeFunction(
      roleName,
      theContract,
      funcSig,
      ethValueLimit,
      isScopeds,
      parameterTypes,
      comparisons,
      targetValues,
      operation,
      funcScopedConfig
    );
  }

  function _compressTargetValue(
    ParameterType parameterType,
    bytes memory targetValue
  ) internal pure returns (bytes32) {
    return
      parameterType == ParameterType.Static
        ? bytes32(targetValue)
        : keccak256(targetValue);
  }

  function _enforceConfigComparison(
    ParameterType parameterType,
    Comparison comparison
  ) internal pure {
    require(uint256(parameterType) <= 2, "Permissions: invalid parameter type");
    require(uint256(comparison) <= 2, "Permissions: invalid comparison type");

    if (parameterType != ParameterType.Static && comparison != Comparison.Eq) {
      require(
        false,
        "Permissions: only supports eq comparison for non-static type"
      );
    }
  }

  function _enforceTargetValue(
    ParameterType parameterType,
    bytes calldata targetValue
  ) internal pure {
    if (parameterType == ParameterType.Static && targetValue.length != 32) {
      require(false, "Permissions: length of static type value should be 32");
    }

    if (
      parameterType == ParameterType.Dynamic32 && targetValue.length % 32 != 0
    ) {
      require(
        false,
        "Permissions: length of dynamic32 type value should be a multiples of 32"
      );
    }
  }

  // LEFT SIDE
  // 2   bits -> operation
  // 1   bits -> isBypass
  // 5   bits -> unused
  // 8   bits -> length
  function _packLeft(
    uint256 funcScopedConfig,
    Operation operation,
    bool isBypass,
    uint256 length
  ) internal pure returns (uint256) {
    // Wipe the LEFT SIDE clean. Start from there
    funcScopedConfig = (funcScopedConfig << 16) >> 16;

    // set operation -> 256 - 2 = 254
    funcScopedConfig |= uint256(operation) << 254;

    // set isBypass -> 256 - 2 - 1 = 253
    if (isBypass) {
      funcScopedConfig |= 1 << 253;
    }

    // set Length -> 48 + 96 + 96 = 240
    funcScopedConfig |= (length << 248) >> 8;

    return funcScopedConfig;
  }

  function _unpackLeft(uint256 funcScopedConfig)
    internal
    pure
    returns (
      Operation operation,
      bool isBypass,
      uint256 argsCount
    )
  {
    uint256 isBypassMask = 1 << 253;

    operation = Operation(funcScopedConfig >> 254);
    isBypass = funcScopedConfig & isBypassMask != 0;
    argsCount = (funcScopedConfig << 8) >> 248;
  }

  // RIGHT SIDE
  // 48  bits -> isScoped
  // 96  bits -> paramType (2 bits per entry 48*2)
  // 96  bits -> paramComp (2 bits per entry 48*2)
  function _packRight(
    uint256 funcScopedConfig,
    uint256 index,
    bool isScoped,
    ParameterType parameterType,
    Comparison comparison
  ) internal pure returns (uint256) {
    uint256 isScopedMask = 1 << (index + 96 + 96);
    uint256 twoBitsMask = 3;
    uint256 typeMask = 3 << (index * 2 + 96);
    uint256 comparisonMask = 3 << (index * 2);

    if (isScoped) {
      funcScopedConfig |= isScopedMask;
    } else {
      funcScopedConfig &= ~isScopedMask;
    }

    funcScopedConfig &= ~typeMask;
    funcScopedConfig |=
      (uint256(parameterType) & twoBitsMask) <<
      (index * 2 + 96);

    funcScopedConfig &= ~comparisonMask;
    funcScopedConfig |= (uint256(comparison) & twoBitsMask) << (index * 2);

    return funcScopedConfig;
  }

  function _unpackRight(uint256 funcScopedConfig, uint256 index)
    internal
    pure
    returns (
      bool isScoped,
      ParameterType parameterType,
      Comparison comparison
    )
  {
    uint256 isScopedMask = 1 << (index + 96 + 96);
    uint256 typeMask = 3 << (index * 2 + 96);
    uint256 comparisonMask = 3 << (index * 2);

    isScoped = (funcScopedConfig & isScopedMask) != 0;
    parameterType = ParameterType(
      (funcScopedConfig & typeMask) >> (index * 2 + 96)
    );
    comparison = Comparison((funcScopedConfig & comparisonMask) >> (index * 2));
  }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

enum ParameterType {
  Static,
  Dynamic,
  Dynamic32
}

enum Comparison {
  Eq,
  Gte,
  Lte
}

enum Scope {
  None,
  Contract,
  Function
}

enum Operation {
  None,
  Call,
  DelegateCall,
  Both
}