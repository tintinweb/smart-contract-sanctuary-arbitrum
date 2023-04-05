// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./GnosisSafe.sol";
import "./Enums.sol";
import "./Permissions.sol";

contract SafeModule is Ownable {
  string public constant version = "0.2.0";
  uint256 internal constant _MAX_ROLE_PER_MEMBER = 16;

  event ModuleSetup(address owner, address safeProxy);
  event AssignRoles(address member, bytes32[_MAX_ROLE_PER_MEMBER] roleNames);
  event DeprecateRole(bytes32 roleName);

  event ExecTransaction(
    address to,
    uint256 value,
    bytes data,
    Operation operation,
    address sender
  );

  mapping(bytes32 => Role) internal roles;
  mapping(address => bytes32[_MAX_ROLE_PER_MEMBER]) internal members;
  mapping(bytes32 => bool) internal deprecatedRoles;

  address public _safeProxy;

  constructor(address owner, address payable safeProxy) {
    bytes memory initParams = abi.encode(owner, safeProxy);
    setUp(initParams);
  }

  function setUp(bytes memory initParams) public {
    (address owner, address safeProxy) = abi.decode(
      initParams,
      (address, address)
    );

    require(safeProxy != address(0), "Invalid safe proxy");
    require(owner != address(0), "Invalid owner");

    _setupOwner(owner);
    _safeProxy = safeProxy;

    emit ModuleSetup(owner, safeProxy);
  }

  modifier isValidRoleName(bytes32 roleName) {
    require(roleName != 0, "SafeModule: empty role name");
    require(!deprecatedRoles[roleName], "SafeModule: role deprecated");

    _;
  }

  /// @dev Assign roles to a member
  /// @param member address
  /// @param roleNames Id of a roles
  /// @notice Can only be called by owner
  function assignRoles(address member, bytes32[] memory roleNames)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _MAX_ROLE_PER_MEMBER; ++i) {
      bytes32 roleName = i < roleNames.length ? roleNames[i] : bytes32(0);
      require(!deprecatedRoles[roleName], "SafeModule: role deprecated");

      members[member][i] = roleName;
    }

    emit AssignRoles(member, members[member]);
  }

  /// @dev Deprecate a roleName and this roleName can't used anymore
  /// @param roleName Id of a role
  /// @notice Can only be called by owner
  function deprecateRole(bytes32 roleName)
    external
    onlyOwner
    isValidRoleName(roleName)
  {
    deprecatedRoles[roleName] = true;
    emit DeprecateRole(roleName);
  }

  /// @dev Get roles of an address for now
  /// @param member Member address
  function rolesOf(address member)
    public
    view
    returns (bytes32[] memory validRoles)
  {
    validRoles = new bytes32[](_MAX_ROLE_PER_MEMBER);

    for (uint256 i = 0; i < _MAX_ROLE_PER_MEMBER; ++i) {
      bytes32 roleName = members[member][i];

      if (roleName == 0 || deprecatedRoles[roleName]) {
        continue;
      }

      validRoles[i] = roleName;
    }
  }

  function hasRole(address member, bytes32 roleName)
    public
    view
    returns (bool)
  {
    bytes32[] memory validRoles = rolesOf(member);

    for (uint256 i = 0; i < validRoles.length; ++i) {
      if (validRoles[i] == roleName) {
        return true;
      }
    }

    return false;
  }

  /// @dev Allow the specific roleName to call the contract
  /// @param roleName Id of a role
  /// @param theContract Allowed contract
  /// @param operation Defines the operation is call or delegateCall
  /// @notice Can only be called by owner
  function allowContract(
    bytes32 roleName,
    address theContract,
    Operation operation
  ) external onlyOwner isValidRoleName(roleName) {
    Permissions.allowContract(
      roles[roleName],
      roleName,
      theContract,
      operation
    );
  }

  /// @dev Disable the specific roleName to call the contract
  /// @param roleName Id of a role
  /// @param theContract Allowed contract
  /// @notice Can only be called by owner
  function revokeContract(bytes32 roleName, address theContract)
    external
    onlyOwner
    isValidRoleName(roleName)
  {
    Permissions.revokeContract(roles[roleName], roleName, theContract);
  }

  /// @dev Allow the specific roleName to call the function of contract
  /// @param roleName Id of a role
  /// @param theContract Allowed contract
  /// @notice Can only be called by owner
  function scopeContract(bytes32 roleName, address theContract)
    external
    onlyOwner
    isValidRoleName(roleName)
  {
    Permissions.scopeContract(roles[roleName], roleName, theContract);
  }

  /// @dev Allow the specific roleName to call the function
  /// @param roleName Id of a role
  /// @param theContract Allowed contract
  /// @param funcSig Function selector
  /// @param operation Defines the operation is call or delegateCall
  /// @notice Can only be called by owner
  /// @notice Please call 'scopeContract' at the begin before config function
  function allowFunction(
    bytes32 roleName,
    address theContract,
    bytes4 funcSig,
    Operation operation
  ) external onlyOwner isValidRoleName(roleName) {
    Permissions.allowFunction(
      roles[roleName],
      roleName,
      theContract,
      funcSig,
      operation
    );
  }

  /// @dev Disable the specific roleName to call the function
  /// @param roleName Id of a role
  /// @param theContract Allowed contract
  /// @param funcSig Function selector
  /// @notice Can only be called by owner
  function revokeFunction(
    bytes32 roleName,
    address theContract,
    bytes4 funcSig
  ) external onlyOwner isValidRoleName(roleName) {
    Permissions.revokeFunction(roles[roleName], roleName, theContract, funcSig);
  }

  /// @dev Allow the specific roleName to call the function with specific parameters
  /// @param roleName Id of a role
  /// @param theContract Allowed contract
  /// @param funcSig Function selector
  /// @param isScopeds List of parameter scoped config, false for un-scoped, true for scoped
  /// @param parameterTypes List of parameter types, Static, Dynamic or Dynamic32, use Static type if not scoped
  /// @param comparisons List of parameter comparison types, Eq, Gte or Lte, use Eq if not scoped
  /// @param targetValues List of expected values, use '0x' if not scoped
  /// @param operation Defines the operation is call or delegateCall
  /// @notice Can only be called by owner
  /// @notice Please call 'scopeContract' at the begin before config function
  function scopeFunction(
    bytes32 roleName,
    address theContract,
    bytes4 funcSig,
    uint256 ethValueLimit,
    bool[] memory isScopeds,
    ParameterType[] memory parameterTypes,
    Comparison[] memory comparisons,
    bytes[] calldata targetValues,
    Operation operation
  ) external onlyOwner isValidRoleName(roleName) {
    Permissions.scopeFunction(
      roles[roleName],
      roleName,
      theContract,
      funcSig,
      ethValueLimit,
      isScopeds,
      parameterTypes,
      comparisons,
      targetValues,
      operation
    );
  }

  /// @dev Check then exec transaction
  /// @param roleName role to execute this call
  /// @param to To address of the transaction
  /// @param value Ether value of the transaction
  /// @param data Data payload of the transaction
  /// @param operation Operation to execute the transaction, only call or delegateCall
  function execTransactionFromModule(
    bytes32 roleName,
    address to,
    uint256 value,
    bytes calldata data,
    Operation operation
  ) public {
    _execTransaction(roleName, to, value, data, operation);
  }

  struct Exec {
    bytes32 roleName;
    address to;
    uint256 value;
    bytes data;
    Operation operation;
  }

  function execTransactionsFromModule(Exec[] calldata execs) public {
    require(execs.length > 0, "SafeModule: Nothing to call");

    for (uint256 i = 0; i < execs.length; ++i) {
      Exec memory exec = execs[i];

      _execTransaction(
        exec.roleName,
        exec.to,
        exec.value,
        exec.data,
        exec.operation
      );
    }
  }

  function _execTransaction(
    bytes32 roleName,
    address to,
    uint256 value,
    bytes memory data,
    Operation operation
  ) internal isValidRoleName(roleName) {
    require(
      operation == Operation.Call || operation == Operation.DelegateCall,
      "SafeModule: only support call or delegatecall"
    );
    _verifyPermission(roleName, to, value, data, operation);

    require(
      GnosisSafe(payable(_safeProxy)).execTransactionFromModule(
        to,
        value,
        data,
        operation == Operation.DelegateCall
          ? GnosisSafeEnum.Operation.DelegateCall
          : GnosisSafeEnum.Operation.Call
      ),
      "SafeModule: execute fail on gnosis safe"
    );

    emit ExecTransaction(to, value, data, operation, _msgSender());
  }

  function _verifyPermission(
    bytes32 roleName,
    address to,
    uint256 value,
    bytes memory data,
    Operation operation
  ) internal view {
    require(
      hasRole(_msgSender(), roleName),
      "SafeModule: sender doesn't have this role"
    );

    Permissions.verify(roles[roleName], to, value, data, operation);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {
  bool private _setup;
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function _setupOwner(address theOwner) internal virtual {
    require(!_setup, "Ownable: setup already");

    _setup = true;
    _owner = theOwner;
    emit OwnershipTransferred(address(0), theOwner);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeEnum {
  enum Operation {
    Call,
    DelegateCall
  }
}

interface GnosisSafe {
  /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
  /// @param to Destination address of module transaction.
  /// @param value Ether value of module transaction.
  /// @param data Data payload of module transaction.
  /// @param operation Operation type of module transaction.
  function execTransactionFromModule(
    address to,
    uint256 value,
    bytes memory data,
    GnosisSafeEnum.Operation operation
  ) external returns (bool success);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal pure returns (bytes calldata) {
    return msg.data;
  }
}