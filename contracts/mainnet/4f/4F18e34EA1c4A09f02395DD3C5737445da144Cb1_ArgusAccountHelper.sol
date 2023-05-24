// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "IVersion.sol";
import "CoboFactory.sol";
import "ArgusAuthorizerHelper.sol";

contract ArgusAccountHelper is ArgusAuthorizerHelper, IVersion {
    bytes32 public constant NAME = "ArgusAccountHelper";
    uint256 public constant VERSION = 0;

    function initArgus(CoboFactory factory, bytes32 coboSafeAccountSalt) external {
        address safe = address(this);
        // 1. Create and enable CoboSafe.
        CoboSafeAccount coboSafe = CoboSafeAccount(
            payable(factory.create2AndRecord("CoboSafeAccount", coboSafeAccountSalt))
        );
        coboSafe.initialize(safe);
        IGnosisSafe(safe).enableModule(address(coboSafe));
        // 2. Set roleManager.
        FlatRoleManager roleManager = FlatRoleManager(factory.create("FlatRoleManager"));
        roleManager.initialize(safe);
        coboSafe.setRoleManager(address(roleManager));
        // 3. Set authorizer
        BaseAuthorizer authorizer = BaseAuthorizer(factory.create("ArgusRootAuthorizer"));
        authorizer.initialize(safe, address(coboSafe), address(coboSafe));
        coboSafe.setAuthorizer(address(authorizer));
    }

    function grantRoles(address coboSafeAddress, bytes32[] calldata roles, address[] calldata delegates) external {
        // 1. Add delegates to CoboSafe.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        coboSafe.addDelegates(delegates);
        // 2. Grant role/delegate in roleManager.
        FlatRoleManager roleManager = FlatRoleManager(coboSafe.roleManager());
        roleManager.grantRoles(roles, delegates);
    }

    function revokeRoles(address coboSafeAddress, bytes32[] calldata roles, address[] calldata delegates) external {
        // 1. Revoke role/delegate for roleManager.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        FlatRoleManager roleManager = FlatRoleManager(coboSafe.roleManager());
        roleManager.revokeRoles(roles, delegates);
    }

    function createAuthorizer(
        CoboFactory factory,
        address coboSafeAddress,
        bytes32 authorizerName,
        bytes32 tag
    ) public returns (address) {
        address safe = address(this);
        // 1. Get ArgusRootAuthorizer.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        ArgusRootAuthorizer rootAuthorizer = ArgusRootAuthorizer(coboSafe.authorizer());
        // 2. Create authorizer and add to root authorizer set
        BaseAuthorizer authorizer = BaseAuthorizer(factory.create2(authorizerName, tag));
        authorizer.initialize(safe, address(rootAuthorizer));
        authorizer.setTag(tag);
        return address(authorizer);
    }

    function addAuthorizer(
        address coboSafeAddress,
        address authorizerAddress,
        bool isDelegateCall,
        bytes32[] calldata roles
    ) public {
        // 1. Get ArgusRootAuthorizer.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        ArgusRootAuthorizer rootAuthorizer = ArgusRootAuthorizer(coboSafe.authorizer());
        // 2. Add authorizer to root authorizer set
        for (uint256 i = 0; i < roles.length; i++) {
            rootAuthorizer.addAuthorizer(isDelegateCall, roles[i], authorizerAddress);
        }
    }

    function removeAuthorizer(
        address coboSafeAddress,
        address authorizerAddress,
        bool isDelegateCall,
        bytes32[] calldata roles
    ) external {
        // 1. Get ArgusRootAuthorizer.
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        ArgusRootAuthorizer rootAuthorizer = ArgusRootAuthorizer(coboSafe.authorizer());
        // 2. Remove authorizer from root authorizer set
        for (uint256 i = 0; i < roles.length; i++) {
            rootAuthorizer.removeAuthorizer(isDelegateCall, roles[i], authorizerAddress);
        }
    }

    function addFuncAuthorizer(
        CoboFactory factory,
        address coboSafeAddress,
        bool isDelegateCall,
        bytes32[] calldata roles,
        address[] calldata _contracts,
        string[][] calldata funcLists,
        bytes32 tag
    ) external {
        // 1. create FuncAuthorizer
        address authorizerAddress = createAuthorizer(factory, coboSafeAddress, "FuncAuthorizer", tag);
        // 2. Set params
        setFuncAuthorizerParams(authorizerAddress, _contracts, funcLists);
        // 3. Add authorizer to root authorizer set
        addAuthorizer(coboSafeAddress, authorizerAddress, isDelegateCall, roles);
    }

    function addTransferAuthorizer(
        CoboFactory factory,
        address coboSafeAddress,
        bool isDelegateCall,
        bytes32[] calldata roles,
        TransferAuthorizer.TokenReceiver[] calldata tokenReceivers,
        bytes32 tag
    ) external {
        // 1. create TransferAuthorizer
        address authorizerAddress = createAuthorizer(factory, coboSafeAddress, "TransferAuthorizer", tag);
        // 2. Set params
        setTransferAuthorizerParams(authorizerAddress, tokenReceivers);
        // 3. Add authorizer to root authorizer set
        addAuthorizer(coboSafeAddress, authorizerAddress, isDelegateCall, roles);
    }

    function addDexAuthorizer(
        CoboFactory factory,
        address coboSafeAddress,
        bytes32 dexAuthorizerName,
        bool isDelegateCall,
        bytes32[] calldata roles,
        address[] calldata _swapInTokens,
        address[] calldata _swapOutTokens,
        bytes32 tag
    ) external {
        // 1. create DexAuthorizer
        address authorizerAddress = createAuthorizer(factory, coboSafeAddress, dexAuthorizerName, tag);
        // 2. Set params
        setDexAuthorizerParams(authorizerAddress, _swapInTokens, _swapOutTokens);
        // 3. Add authorizer to root authorizer set
        addAuthorizer(coboSafeAddress, authorizerAddress, isDelegateCall, roles);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface IVersion {
    function NAME() external view returns (bytes32 name);

    function VERSION() external view returns (uint256 version);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Clones.sol";

import "BaseOwnable.sol";

/// @title CoboFactory - A contract factory referenced by bytes32 name.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice Mostly used to manage proxy logic contract. But ok to manage non-proxy contracts.
/// @dev Contracts to add should extend IVersion interface, which implement `NAME()` function.
contract CoboFactory is BaseOwnable {
    bytes32 public constant NAME = "CoboFactory";
    uint256 public constant VERSION = 1;

    bytes32[] public names;

    // The last one added.
    mapping(bytes32 => address) public latestImplementations;

    // Name => All added contracts.
    mapping(bytes32 => address[]) public implementations;

    // deployer => name => proxy contract list
    // This is expensive. Query ProxyCreated event in SubGraph is a better solution.
    mapping(address => mapping(bytes32 => address[])) public records;

    event ProxyCreated(address indexed deployer, bytes32 indexed name, address indexed implementation, address proxy);
    event ImplementationAdded(bytes32 indexed name, address indexed implementation);

    constructor(address _owner) BaseOwnable(_owner) {}

    function _getLatestImplStrict(bytes32 name) internal view returns (address impl) {
        impl = getLatestImplementation(name);
        require(impl != address(0), "No implementation");
    }

    /// View functions.
    function getLatestImplementation(bytes32 name) public view returns (address impl) {
        impl = latestImplementations[name];
    }

    function getAllImplementations(bytes32 name) external view returns (address[] memory impls) {
        impls = implementations[name];
    }

    function getAllNames() external view returns (bytes32[] memory _names) {
        _names = names;
    }

    /// @dev For etherscan view.
    function getNameString(uint i) public view returns (string memory _name) {
        _name = string(abi.encodePacked(names[i]));
    }

    function getAllNameStrings() external view returns (string[] memory _names) {
        _names = new string[](names.length);
        for (uint i = 0; i < names.length; ++i) {
            _names[i] = getNameString(i);
        }
    }

    function getLastRecord(address deployer, bytes32 name) external view returns (address proxy) {
        address[] storage record = records[deployer][name];
        if (record.length == 0) return address(0);
        proxy = record[record.length - 1];
    }

    function getRecordSize(address deployer, bytes32 name) external view returns (uint256 size) {
        address[] storage record = records[deployer][name];
        size = record.length;
    }

    function getAllRecord(address deployer, bytes32 name) external view returns (address[] memory proxies) {
        return records[deployer][name];
    }

    function getRecords(
        address deployer,
        bytes32 name,
        uint256 start,
        uint256 end
    ) external view returns (address[] memory proxies) {
        address[] storage record = records[deployer][name];
        uint256 size = record.length;
        if (end > size) end = size;
        require(end > start, "end > start");
        proxies = new address[](end - start);
        for (uint i = start; i < end; ++i) {
            proxies[i - start] = record[i];
        }
    }

    function getCreate2Address(address creator, bytes32 name, bytes32 salt) external view returns (address instance) {
        address implementation = getLatestImplementation(name);
        if (implementation == address(0)) return address(0);
        salt = keccak256(abi.encode(creator, salt));
        return Clones.predictDeterministicAddress(implementation, salt);
    }

    /// External functions.

    /// @dev Create EIP 1167 proxy.
    function create(bytes32 name) public returns (address instance) {
        address implementation = _getLatestImplStrict(name);
        instance = Clones.clone(implementation);
        emit ProxyCreated(msg.sender, name, implementation, instance);
    }

    /// @dev Create EIP 1167 proxy with create2.
    function create2(bytes32 name, bytes32 salt) public returns (address instance) {
        address implementation = _getLatestImplStrict(name);
        salt = keccak256(abi.encode(msg.sender, salt));
        instance = Clones.cloneDeterministic(implementation, salt);
        emit ProxyCreated(msg.sender, name, implementation, instance);
    }

    /// @notice Create and record the creation in contract.
    function createAndRecord(bytes32 name) external returns (address instance) {
        instance = create(name);
        records[msg.sender][name].push(instance);
    }

    function create2AndRecord(bytes32 name, bytes32 salt) public returns (address instance) {
        instance = create2(name, salt);
        records[msg.sender][name].push(instance);
    }

    // Owner functions.
    function addImplementation(address impl) external onlyOwner {
        bytes32 name = IVersion(impl).NAME();

        // If new name found, add to `names`.
        if (latestImplementations[name] == address(0)) {
            names.push(name);
        }

        latestImplementations[name] = impl;
        implementations[name].push(impl);
        emit ImplementationAdded(name, impl);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Errors.sol";
import "BaseVersion.sol";

/// @title BaseOwnable - Provides simple ownership access control.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Can be used in both proxy and non-proxy mode.
abstract contract BaseOwnable is BaseVersion {
    address public owner;
    address public pendingOwner;
    bool private initialized = false;

    event PendingOwnerSet(address indexed to);
    event NewOwnerSet(address indexed owner);

    modifier onlyOwner() {
        require(owner == msg.sender, Errors.CALLER_IS_NOT_OWNER);
        _;
    }

    /// @dev `owner` is set by argument, thus the owner can any address.
    ///      When used in non-proxy mode, `initialize` can not be called
    ///      after deployment.
    constructor(address _owner) {
        initialize(_owner);
    }

    /// @dev When used in proxy mode, `initialize` can be called by anyone
    ///      to claim the ownership.
    ///      This function can be called only once.
    function initialize(address _owner) public {
        require(!initialized, Errors.ALREADY_INITIALIZED);
        _setOwner(_owner);
        initialized = true;
    }

    /// @notice User should ensure the corrent owner address set, or the
    ///         ownership may be transferred to blackhole. It is recommended to
    ///         take a safer way with setPendingOwner() + acceptOwner().
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New Owner is zero");
        _setOwner(newOwner);
    }

    /// @notice The original owner calls `setPendingOwner(newOwner)` and the new
    ///         owner calls `acceptOwner()` to take the ownership.
    function setPendingOwner(address to) external onlyOwner {
        pendingOwner = to;
        emit PendingOwnerSet(pendingOwner);
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        _setOwner(pendingOwner);
    }

    /// @notice Make the contract immutable.
    function renounceOwnership() external onlyOwner {
        _setOwner(address(0));
    }

    // Internal functions

    /// @dev Clear pendingOwner to prevent from reclaiming the ownership.
    function _setOwner(address _owner) internal {
        owner = _owner;
        pendingOwner = address(0);
        emit NewOwnerSet(owner);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

/// @dev Common errors. This helps reducing the contract size.
library Errors {
    // "E1";

    // Call/Static-call failed.
    string constant CALL_FAILED = "E2";

    // Argument's type not supported in View Variant.
    string constant INVALID_VIEW_ARG_SOL_TYPE = "E3";

    // Invalid length for variant raw data.
    string constant INVALID_VARIANT_RAW_DATA = "E4";

    // "E5";

    // Invalid variant type.
    string constant INVALID_VAR_TYPE = "E6";

    // Rule not exists
    string constant RULE_NOT_EXISTS = "E7";

    // Variant name not found.
    string constant VAR_NAME_NOT_FOUND = "E8";

    // Rule: v1/v2 solType mismatch
    string constant SOL_TYPE_MISMATCH = "E9";

    // "E10";

    // Invalid rule OP.
    string constant INVALID_RULE_OP = "E11";

    //  "E12";

    // "E13";

    //  "E14";

    // "E15";

    // "E16";

    // "E17";

    // "E18";

    // "E19";

    // "E20";

    // checkCmpOp: OP not support
    string constant CMP_OP_NOT_SUPPORT = "E21";

    // checkBySolType: Invalid op for bool
    string constant INVALID_BOOL_OP = "E22";

    // checkBySolType: Invalid op
    string constant CHECK_INVALID_OP = "E23";

    // Invalid solidity type.
    string constant INVALID_SOL_TYPE = "E24";

    // computeBySolType: invalid vm op
    string constant INVALID_VM_BOOL_OP = "E25";

    // computeBySolType: invalid vm arith op
    string constant INVALID_VM_ARITH_OP = "E26";

    // onlyCaller: Invalid caller
    string constant INVALID_CALLER = "E27";

    // "E28";

    // Side-effect is not allowed here.
    string constant SIDE_EFFECT_NOT_ALLOWED = "E29";

    // Invalid variant count for the rule op.
    string constant INVALID_VAR_COUNT = "E30";

    // extractCallData: Invalid op.
    string constant INVALID_EXTRACTOR_OP = "E31";

    // extractCallData: Invalid array index.
    string constant INVALID_ARRAY_INDEX = "E32";

    // extractCallData: No extract op.
    string constant NO_EXTRACT_OP = "E33";

    // extractCallData: No extract path.
    string constant NO_EXTRACT_PATH = "E34";

    // BaseOwnable: caller is not owner
    string constant CALLER_IS_NOT_OWNER = "E35";

    // BaseOwnable: Already initialized
    string constant ALREADY_INITIALIZED = "E36";

    // "E37";

    // "E38";

    // BaseACL: ACL check method should not return anything.
    string constant ACL_FUNC_RETURNS_NON_EMPTY = "E39";

    // "E40";

    // BaseAccount: Invalid delegate.
    string constant INVALID_DELEGATE = "E41";

    // RootAuthorizer: delegateCallAuthorizer not set
    string constant DELEGATE_CALL_AUTH_NOT_SET = "E42";

    // RootAuthorizer: callAuthorizer not set.
    string constant CALL_AUTH_NOT_SET = "E43";

    // BaseAccount: Authorizer not set.
    string constant AUTHORIZER_NOT_SET = "E44";

    // BaseAccount: Invalid authorizer flag.
    string constant INVALID_AUTHORIZER_FLAG = "E45";

    // BaseAuthorizer: Authorizer paused.
    string constant AUTHORIZER_PAUSED = "E46";

    // Authorizer set: Invalid hint.
    string constant INVALID_HINT = "E47";

    // Authorizer set: All auth deny.
    string constant ALL_AUTH_FAILED = "E48";

    // BaseACL: Method not allow.
    string constant METHOD_NOT_ALLOW = "E49";

    // AuthorizerUnionSet: Invalid hint collected.
    string constant INVALID_HINT_COLLECTED = "E50";

    // AuthorizerSet: Empty auth set
    string constant EMPTY_AUTH_SET = "E51";

    // AuthorizerSet: hint not implement.
    string constant HINT_NOT_IMPLEMENT = "E52";

    // RoleAuthorizer: Empty role set
    string constant EMPTY_ROLE_SET = "E53";

    // RoleAuthorizer: No auth for the role
    string constant NO_AUTH_FOR_THE_ROLE = "E54";

    // BaseACL: No in contract white list.
    string constant NOT_IN_CONTRACT_LIST = "E55";

    // BaseACL: Same process not allowed to install twice.
    string constant SAME_PROCESS_TWICE = "E56";

    // BaseAuthorizer: Account not set (then can not find roleManger)
    string constant ACCOUNT_NOT_SET = "E57";

    // BaseAuthorizer: roleManger not set
    string constant ROLE_MANAGER_NOT_SET = "E58";
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "IVersion.sol";

/// @title BaseVersion - Provides version information
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev
///    Implement NAME() and VERSION() methods according to IVersion interface.
///
///    Or just:
///      bytes32 public constant NAME = "<Your contract name>";
///      uint256 public constant VERSION = <Your contract version>;
///
///    Change the NAME when writing new kind of contract.
///    Change the VERSION when upgrading existing contract.
abstract contract BaseVersion is IVersion {
    /// @dev Convert to `string` which looks prettier on Etherscan viewer.
    function _NAME() external view virtual returns (string memory) {
        return string(abi.encodePacked(this.NAME()));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "CoboSafeAccount.sol";
import "FlatRoleManager.sol";
import "ArgusRootAuthorizer.sol";
import "FuncAuthorizer.sol";
import "TransferAuthorizer.sol";
import "DEXBaseACL.sol";

abstract contract ArgusAuthorizerHelper {
    function setFuncAuthorizerParams(
        address authorizerAddress,
        address[] calldata _contracts,
        string[][] calldata funcLists
    ) public {
        if (_contracts.length == 0) return;
        require(_contracts.length == funcLists.length, "Length differs");
        FuncAuthorizer authorizer = FuncAuthorizer(authorizerAddress);
        for (uint i = 0; i < _contracts.length; i++) {
            authorizer.addContractFuncs(_contracts[i], funcLists[i]);
        }
    }

    function unsetFuncAuthorizerParams(
        address authorizerAddress,
        address[] calldata _contracts,
        string[][] calldata funcLists
    ) external {
        if (_contracts.length == 0) return;
        require(_contracts.length == funcLists.length, "Length differs");
        FuncAuthorizer authorizer = FuncAuthorizer(authorizerAddress);
        for (uint i = 0; i < _contracts.length; i++) {
            authorizer.removeContractFuncs(_contracts[i], funcLists[i]);
        }
    }

    function setTransferAuthorizerParams(
        address authorizerAddress,
        TransferAuthorizer.TokenReceiver[] calldata tokenReceivers
    ) public {
        if (tokenReceivers.length == 0) return;
        TransferAuthorizer authorizer = TransferAuthorizer(authorizerAddress);
        authorizer.addTokenReceivers(tokenReceivers);
    }

    function unsetTransferAuthorizerParams(
        address authorizerAddress,
        TransferAuthorizer.TokenReceiver[] calldata tokenReceivers
    ) external {
        if (tokenReceivers.length == 0) return;
        TransferAuthorizer authorizer = TransferAuthorizer(authorizerAddress);
        authorizer.removeTokenReceivers(tokenReceivers);
    }

    function setDexAuthorizerParams(
        address authorizerAddress,
        address[] calldata _swapInTokens,
        address[] calldata _swapOutTokens
    ) public {
        DEXBaseACL authorizer = DEXBaseACL(authorizerAddress);
        if (_swapInTokens.length > 0) {
            authorizer.addSwapInTokens(_swapInTokens);
        }
        if (_swapOutTokens.length > 0) {
            authorizer.addSwapOutTokens(_swapOutTokens);
        }
    }

    function unsetDexAuthorizerParams(
        address authorizerAddress,
        address[] calldata _swapInTokens,
        address[] calldata _swapOutTokens
    ) external {
        DEXBaseACL authorizer = DEXBaseACL(authorizerAddress);
        if (_swapInTokens.length > 0) {
            authorizer.removeSwapInTokens(_swapInTokens);
        }
        if (_swapOutTokens.length > 0) {
            authorizer.removeSwapOutTokens(_swapOutTokens);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseAccount.sol";

contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IGnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    function enableModule(address module) external;

    function isModuleEnabled(address module) external view returns (bool);
}

/// @title CoboSafeAccount - A GnosisSafe module that implements customized access control
/// @author Cobo Safe Dev Team https://www.cobo.com/
contract CoboSafeAccount is BaseAccount {
    using TxFlags for uint256;

    bytes32 public constant NAME = "CoboSafeAccount";
    uint256 public constant VERSION = 1;

    constructor(address _owner) BaseAccount(_owner) {}

    /// @notice The safe of the CoboSafeAccount.
    function safe() public view returns (address) {
        return owner;
    }

    /// @dev Execute the transaction from the safe.
    function _executeTransaction(
        TransactionData memory transaction
    ) internal override returns (TransactionResult memory result) {
        // execute the transaction from Gnosis Safe, note this call will bypass
        // safe owners confirmation.
        (result.success, result.data) = IGnosisSafe(payable(safe())).execTransactionFromModuleReturnData(
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.flag.isDelegateCall() ? Enum.Operation.DelegateCall : Enum.Operation.Call
        );
    }

    /// @dev Account address is the safe address.
    function _getAccountAddress() internal view override returns (address account) {
        account = safe();
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "Types.sol";
import "BaseOwnable.sol";
import "IAuthorizer.sol";
import "IRoleManager.sol";
import "IAccount.sol";

/// @title BaseAccount - A basic smart contract wallet with access control supported.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Extend this and implement `_executeTransaction()` and `_getFromAddress()`.
abstract contract BaseAccount is IAccount, BaseOwnable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TxFlags for uint256;
    using AuthFlags for uint256;

    address public roleManager;
    address public authorizer;

    // Simple and basic delegate check.
    EnumerableSet.AddressSet delegates;

    event RoleManagerSet(address indexed roleManager);
    event AuthorizerSet(address indexed authorizer);
    event DelegateAdded(address indexed delegate);
    event DelegateRemoved(address indexed delegate);
    event TransactionExecuted(
        address indexed to,
        bytes4 indexed selector,
        uint256 indexed value,
        TransactionData transaction
    );

    /// @dev RoleManager need BaseAccount to create thus we can not init it in constructor
    /// @param _owner Who owns the wallet.
    constructor(address _owner) BaseOwnable(_owner) {}

    /// @dev Only used in proxy mode. Can be called only once.
    function initialize(address _owner, address _roleManager, address _authorizer) public {
        initialize(_owner);
        _setRoleManager(_roleManager);
        _setAuthorizer(_authorizer);
    }

    /// Modifiers

    /// @dev Only added delegates are allowed to call `execTransaction`. This provides a kind
    ///      of catch-all rule and simple but strong protection from malicious/compromised/buggy
    ///      authorizers which permits any operations.
    modifier onlyDelegate() {
        require(hasDelegate(msg.sender), Errors.INVALID_DELEGATE);
        _;
    }

    // Public/External functions.
    function setRoleManager(address _roleManager) external onlyOwner {
        _setRoleManager(_roleManager);
    }

    function setAuthorizer(address _authorizer) external onlyOwner {
        _setAuthorizer(_authorizer);
    }

    function addDelegate(address _delegate) external onlyOwner {
        _addDelegate(_delegate);
    }

    function addDelegates(address[] calldata _delegates) external onlyOwner {
        for (uint256 i = 0; i < _delegates.length; i++) {
            _addDelegate(_delegates[i]);
        }
    }

    function removeDelegate(address _delegate) external onlyOwner {
        _removeDelegate(_delegate);
    }

    function removeDelegates(address[] calldata _delegates) external onlyOwner {
        for (uint256 i = 0; i < _delegates.length; i++) {
            _removeDelegate(_delegates[i]);
        }
    }

    /// @notice Called by authenticated delegates to execute transaction on behalf of the wallet account.
    /// @param callData A structure contains `to`, `value`, `data`.
    function execTransaction(
        CallData calldata callData
    ) external onlyDelegate returns (TransactionResult memory result) {
        TransactionData memory transaction;
        transaction.from = _getAccountAddress();
        transaction.delegate = msg.sender;
        transaction.flag = callData.flag;
        transaction.to = callData.to;
        transaction.value = callData.value;
        transaction.data = callData.data;
        transaction.hint = callData.hint;
        transaction.extra = callData.extra;

        result = _executeTransactionWithCheck(transaction);
        emit TransactionExecuted(callData.to, bytes4(callData.data), callData.value, transaction);
    }

    /// @notice A Multicall method.
    /// @param callDataList `CallData` array to execute in sequence.
    function execTransactions(
        CallData[] calldata callDataList
    ) external onlyDelegate returns (TransactionResult[] memory resultList) {
        TransactionData memory transaction;
        transaction.from = _getAccountAddress();
        transaction.delegate = msg.sender;

        resultList = new TransactionResult[](callDataList.length);

        for (uint256 i = 0; i < callDataList.length; i++) {
            CallData calldata callData = callDataList[i];
            transaction.to = callData.to;
            transaction.value = callData.value;
            transaction.data = callData.data;
            transaction.flag = callData.flag;
            transaction.hint = callData.hint;
            transaction.extra = callData.extra;

            resultList[i] = _executeTransactionWithCheck(transaction);

            emit TransactionExecuted(callData.to, bytes4(callData.data), callData.value, transaction);
        }
    }

    /// External view functions.

    function hasDelegate(address _delegate) public view returns (bool) {
        return delegates.contains(_delegate);
    }

    function getAllDelegates() external view returns (address[] memory) {
        return delegates.values();
    }

    /// @notice The real address of your smart contract wallet address where
    ///         stores your assets and sends transactions from.
    function getAccountAddress() external view returns (address account) {
        account = _getAccountAddress();
    }

    /// Internal functions.

    function _addDelegate(address _delegate) internal {
        if (delegates.add(_delegate)) {
            emit DelegateAdded(_delegate);
        }
    }

    function _removeDelegate(address _delegate) internal {
        if (delegates.remove(_delegate)) {
            emit DelegateRemoved(_delegate);
        }
    }

    function _setRoleManager(address _roleManager) internal {
        roleManager = _roleManager;
        emit RoleManagerSet(_roleManager);
    }

    function _setAuthorizer(address _authorizer) internal {
        authorizer = _authorizer;
        emit AuthorizerSet(_authorizer);
    }

    /// @dev Override this if we prefer not to revert the entire transaction in
    //       out wallet contract implementation.
    function _preExecCheck(
        TransactionData memory transaction
    ) internal virtual returns (AuthorizerReturnData memory authData) {
        authData = IAuthorizer(authorizer).preExecCheck(transaction);
        require(authData.result == AuthResult.SUCCESS, authData.message);
    }

    function _revertIfTxFails(TransactionResult memory callResult) internal pure {
        bool success = callResult.success;
        bytes memory data = callResult.data;
        if (!success) {
            assembly {
                revert(add(data, 32), data)
            }
        }
    }

    function _postExecCheck(
        TransactionData memory transaction,
        TransactionResult memory callResult,
        AuthorizerReturnData memory predata
    ) internal virtual returns (AuthorizerReturnData memory authData) {
        _revertIfTxFails(callResult);
        authData = IAuthorizer(authorizer).postExecCheck(transaction, callResult, predata);
        require(authData.result == AuthResult.SUCCESS, authData.message);
    }

    function _preExecProcess(TransactionData memory transaction) internal virtual {
        IAuthorizer(authorizer).preExecProcess(transaction);
    }

    function _postExecProcess(
        TransactionData memory transaction,
        TransactionResult memory callResult
    ) internal virtual {
        IAuthorizer(authorizer).postExecProcess(transaction, callResult);
    }

    function _executeTransactionWithCheck(
        TransactionData memory transaction
    ) internal virtual returns (TransactionResult memory result) {
        require(authorizer != address(0), Errors.AUTHORIZER_NOT_SET);
        uint256 flag = IAuthorizer(authorizer).flag();
        bool doCollectHint = transaction.hint.length == 0;

        // Ensures either _preExecCheck or _postExecCheck (or both) will run.
        require(flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);

        // 1. Do pre check, revert the entire txn if failed.
        AuthorizerReturnData memory preData;
        if (doCollectHint || flag.hasPreCheck()) {
            // Always run _preExecCheck When collecting hint.
            // If not collecting hint, only run if the sub authorizer requires.
            preData = _preExecCheck(transaction);
        }

        // 2. Do pre process.
        if (flag.hasPreProcess()) _preExecProcess(transaction);

        // 3. Execute the transaction.
        result = _executeTransaction(transaction);

        // 4. Do post check, revert the entire txn if failed.
        AuthorizerReturnData memory postData;
        if (doCollectHint || flag.hasPostCheck()) {
            postData = _postExecCheck(transaction, result, preData);
        }

        // 5. Do post process.
        if (flag.hasPostProcess()) _postExecProcess(transaction, result);

        // 6. Collect hint if when (1) no hint provided and (2) the authorizer supports hint mode.
        if (doCollectHint && flag.supportHint()) {
            result.hint = IAuthorizerSupportingHint(authorizer).collectHint(preData, postData);
        }
    }

    /// @dev Instance should implement at least two `virtual` function below.

    /// @param transaction Transaction to execute.
    /// @return result `TransactionResult` which contains call status and return/revert data.
    function _executeTransaction(
        TransactionData memory transaction
    ) internal virtual returns (TransactionResult memory result);

    /// @dev The address of wallet which sends the transaction a.k.a `msg.sender`
    function _getAccountAddress() internal view virtual returns (address account);

    // To receive ETH as a wallet.
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

enum AuthResult {
    FAILED,
    SUCCESS
}

struct CallData {
    uint256 flag; // 0x1 delegate call, 0x0 call.
    address to;
    uint256 value;
    bytes data; // calldata
    bytes hint;
    bytes extra; // for future support: signatures etc.
}

struct TransactionData {
    address from; // Sender who performs the transaction a.k.a wallet address.
    address delegate; // Delegate who calls executeTransactions().
    // Same as CallData
    uint256 flag; // 0x1 delegate call, 0x0 call.
    address to;
    uint256 value;
    bytes data; // calldata
    bytes hint;
    bytes extra;
}

struct AuthorizerReturnData {
    AuthResult result;
    string message;
    bytes data; // Authorizer return data. usually used for hint purpose.
}

struct TransactionResult {
    bool success; // Call status.
    bytes data; // Return/Revert data.
    bytes hint;
}

library TxFlags {
    uint256 internal constant DELEGATE_CALL_MASK = 0x1; // 1 for delegatecall, 0 for call

    function isDelegateCall(uint256 flag) internal pure returns (bool) {
        return flag & DELEGATE_CALL_MASK == DELEGATE_CALL_MASK;
    }
}

library VarName {
    bytes5 internal constant TEMP = "temp.";

    function isTemp(bytes32 name) internal pure returns (bool) {
        return bytes5(name) == TEMP;
    }
}

library AuthType {
    bytes32 internal constant FUNC = "FunctionType";
    bytes32 internal constant TRANSFER = "TransferType";
    bytes32 internal constant DEX = "DexType";
    bytes32 internal constant LENDING = "LendingType";
    bytes32 internal constant COMMON = "CommonType";
    bytes32 internal constant SET = "SetType";
    bytes32 internal constant VM = "VM";
}

library AuthFlags {
    uint256 internal constant HAS_PRE_CHECK_MASK = 0x1;
    uint256 internal constant HAS_POST_CHECK_MASK = 0x2;
    uint256 internal constant HAS_PRE_PROC_MASK = 0x4;
    uint256 internal constant HAS_POST_PROC_MASK = 0x8;

    uint256 internal constant SUPPORT_HINT_MASK = 0x40;

    uint256 internal constant FULL_MODE =
        HAS_PRE_CHECK_MASK | HAS_POST_CHECK_MASK | HAS_PRE_PROC_MASK | HAS_POST_PROC_MASK;

    function isValid(uint256 flag) internal pure returns (bool) {
        // At least one check handler is activated.
        return hasPreCheck(flag) || hasPostCheck(flag);
    }

    function hasPreCheck(uint256 flag) internal pure returns (bool) {
        return flag & HAS_PRE_CHECK_MASK == HAS_PRE_CHECK_MASK;
    }

    function hasPostCheck(uint256 flag) internal pure returns (bool) {
        return flag & HAS_POST_CHECK_MASK == HAS_POST_CHECK_MASK;
    }

    function hasPreProcess(uint256 flag) internal pure returns (bool) {
        return flag & HAS_PRE_PROC_MASK == HAS_PRE_PROC_MASK;
    }

    function hasPostProcess(uint256 flag) internal pure returns (bool) {
        return flag & HAS_POST_PROC_MASK == HAS_POST_PROC_MASK;
    }

    function supportHint(uint256 flag) internal pure returns (bool) {
        return flag & SUPPORT_HINT_MASK == SUPPORT_HINT_MASK;
    }
}

// For Rule VM.

// For each VariantType, an extractor should be implement.
enum VariantType {
    INVALID, // Mark for delete.
    EXTRACT_CALLDATA, // extract calldata by path bytes.
    NAME, // name for user-defined variant.
    RAW, // encoded solidity values.
    VIEW, // staticcall view non-side-effect function and get return value.
    CALL, // call state changing function and get returned value.
    RULE, // rule expression.
    ANY
}

// How the data should be decoded.
enum SolidityType {
    _invalid, // Mark for delete.
    _any,
    _bytes,
    _bool,
    ///// START 1
    ///// Generated by gen_rulelib.py (start)
    _address,
    _uint256,
    _int256,
    ///// Generated by gen_rulelib.py (end)
    ///// END 1
    _end
}

// A common operand in rule.
struct Variant {
    VariantType varType;
    SolidityType solType;
    bytes data;
}

// OpCode for rule expression which returns v0.
enum OP {
    INVALID,
    // One opnd.
    VAR, // v1
    NOT, // !v1
    // Two opnds.
    // checkBySolType() which returns boolean.
    EQ, // v1 == v2
    NE, // v1 != v2
    GT, // v1 > v2
    GE, // v1 >= v2
    LT, // v1 < v2
    LE, // v1 <= v2
    IN, // v1 in [...]
    NOTIN, // v1 not in [...]
    // computeBySolType() which returns bytes (with same solType)
    AND, // v1 & v2
    OR, // v1 | v2
    ADD, // v1 + v2
    SUB, // v1 - v2
    MUL, // v1 * v2
    DIV, // v1 / v2
    MOD, // v1 % v2
    // Three opnds.
    IF, // v1? v2: v3
    // Side-effect ones.
    ASSIGN, // v1 := v2
    VM, // rule list bytes.
    NOP // as end.
}

struct Rule {
    OP op;
    Variant[] vars;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Types.sol";

interface IAuthorizer {
    function flag() external view returns (uint256 authFlags);

    function setCaller(address _caller) external;

    function preExecCheck(TransactionData calldata transaction) external returns (AuthorizerReturnData memory authData);

    function postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preAuthData
    ) external returns (AuthorizerReturnData memory authData);

    function preExecProcess(TransactionData calldata transaction) external;

    function postExecProcess(TransactionData calldata transaction, TransactionResult calldata callResult) external;
}

interface IAuthorizerSupportingHint is IAuthorizer {
    // When IAuthorizer(auth).flag().supportHint() == true;
    function collectHint(
        AuthorizerReturnData calldata preAuthData,
        AuthorizerReturnData calldata postAuthData
    ) external view returns (bytes memory hint);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Types.sol";

interface IRoleManager {
    function getRoles(address delegate) external view returns (bytes32[] memory);

    function hasRole(address delegate, bytes32 role) external view returns (bool);
}

interface IFlatRoleManager is IRoleManager {
    function addRoles(bytes32[] calldata roles) external;

    function grantRoles(bytes32[] calldata roles, address[] calldata delegates) external;

    function revokeRoles(bytes32[] calldata roles, address[] calldata delegates) external;

    function getDelegates() external view returns (address[] memory);

    function getAllRoles() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Types.sol";

interface IAccount {
    /// @notice Call Gnosis Safe to execute a transaction
    /// @dev Delegates can call this method to invoke gnosis safe to forward to
    ///      transaction to target contract
    ///      The function can only be called by delegates.
    /// @param callData The callData  to be called by Gnosis Safe
    function execTransaction(CallData calldata callData) external returns (TransactionResult memory result);

    function execTransactions(
        CallData[] calldata callDataList
    ) external returns (TransactionResult[] memory resultList);

    function setAuthorizer(address _authorizer) external;

    function setRoleManager(address _roleManager) external;

    function addDelegate(address _delegate) external;

    function addDelegates(address[] calldata _delegates) external;

    /// @dev Sub instance should override this to set `from` for transaction
    /// @return account The address for the contract wallet, also the
    ///         `msg.sender` address which send the transaction.
    function getAccountAddress() external view returns (address account);

    function roleManager() external view returns (address _roleManager);

    function authorizer() external view returns (address _authorizer);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "IRoleManager.sol";
import "BaseOwnable.sol";

/// @title TransferAuthorizer - Manages delegate-role mapping.
/// @author Cobo Safe Dev Team https://www.cobo.com/
contract FlatRoleManager is IFlatRoleManager, BaseOwnable {
    bytes32 public constant NAME = "FlatRoleManager";
    uint256 public constant VERSION = 1;

    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    event DelegateAdded(address indexed delegate, address indexed sender);
    event DelegateRemoved(address indexed delegate, address indexed sender);
    event RoleAdded(bytes32 indexed role, address indexed sender);
    event RoleGranted(bytes32 indexed role, address indexed delegate, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed delegate, address indexed sender);

    /// @dev delegate set
    EnumerableSet.AddressSet delegates;

    /// @dev role set
    EnumerableSet.Bytes32Set roles;

    /// @dev mapping from `delegate` => `role set`;
    mapping(address => EnumerableSet.Bytes32Set) delegateToRoles;

    constructor(address _owner) BaseOwnable(_owner) {}

    /// @notice Add new roles without delegates assigned.
    function addRoles(bytes32[] calldata _roles) external onlyOwner {
        for (uint256 i = 0; i < _roles.length; i++) {
            if (roles.add(_roles[i])) {
                emit RoleAdded(_roles[i], msg.sender);
            }
        }
    }

    /// @notice Grant roles to a delegates. Roles list and delegates list should 1:1 match.
    function grantRoles(bytes32[] calldata _roles, address[] calldata _delegates) external onlyOwner {
        require(_roles.length > 0 && _roles.length == _delegates.length, "FlatRoleManager: Invalid inputs");

        for (uint256 i = 0; i < _roles.length; i++) {
            if (!delegateToRoles[_delegates[i]].add(_roles[i])) {
                // If already bound skip.
                continue;
            }
            // In case when role not added.
            if (roles.add(_roles[i])) {
                // Only fired when new one added.
                emit RoleAdded(_roles[i], msg.sender);
            }

            // need to emit `DelegateAdded` before `RoleGranted` to allow
            // subgraph event handler to process in sensible order.
            if (delegates.add(_delegates[i])) {
                emit DelegateAdded(_delegates[i], msg.sender);
            }

            emit RoleGranted(_roles[i], _delegates[i], msg.sender);
        }
    }

    /// @notice Revoke roles from delegates. Roles list and delegates list should 1:1 match.
    function revokeRoles(bytes32[] calldata _roles, address[] calldata _delegates) external onlyOwner {
        require(_roles.length > 0 && _roles.length == _delegates.length, "FlatRoleManager: Invalid inputs");

        for (uint256 i = 0; i < _roles.length; i++) {
            if (!delegateToRoles[_delegates[i]].remove(_roles[i])) {
                continue;
            }

            // Ensure `RoleRevoked` is fired before `DelegateRemoved`
            // so that the event handlers in subgraphs are triggered in the
            // right order.
            emit RoleRevoked(_roles[i], _delegates[i], msg.sender);

            if (delegateToRoles[_delegates[i]].length() == 0) {
                delegates.remove(_delegates[i]);
                emit DelegateRemoved(_delegates[i], msg.sender);
            }
        }
    }

    /// @notice Get all the roles owned by the delegate in the sender wallet
    /// @param delegate the roles of delegate to be retrieved
    /// @return list of roles
    function getRoles(address delegate) external view returns (bytes32[] memory) {
        return delegateToRoles[delegate].values();
    }

    /// @notice Check if the delegate has the role.
    function hasRole(address delegate, bytes32 role) external view returns (bool) {
        return delegateToRoles[delegate].contains(role);
    }

    /// @notice Get all delegates in the account
    /// @return the delegates list
    function getDelegates() external view returns (address[] memory) {
        return delegates.values();
    }

    /// @notice Get all the roles defined in the module
    /// @return list of roles
    function getAllRoles() external view returns (bytes32[] memory) {
        return roles.values();
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseAuthorizer.sol";

/// @title ArgusRootAuthorizer - Default root authorizers for Argus platform.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice ArgusRootAuthorizer is a authorizer manager which dispatch the correct
///         sub authorizer according to role of delegate and call type.
///         Hint is supported here so user can get the hint, the correct authorizer
///         in this case,  off-chain (this can be expensive on-chain) and preform
///         on-chain transaction to save gas.
contract ArgusRootAuthorizer is BaseAuthorizer, IAuthorizerSupportingHint {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TxFlags for uint256;
    using AuthFlags for uint256;

    bytes32 public constant NAME = "ArgusRootAuthorizer";
    uint256 public constant VERSION = 1;
    bytes32 public constant override TYPE = AuthType.SET;

    /// @dev This changes when authorizer adds.
    uint256 private _unionFlag;

    // Roles used in the authorizer.
    EnumerableSet.Bytes32Set roles;

    // `isDelegateCall` => `Role` => `Authorizer address set`
    // true for delegatecall, false for call.
    mapping(bool => mapping(bytes32 => EnumerableSet.AddressSet)) internal authorizerSet;

    // Authorizers who implement process handler (with flag `HAS_POST_PROC_MASK` or `HAS_POST_PROC_MASK`)
    // will added into `processSet` and will be invoked unconditionally at each tx.
    mapping(bool => EnumerableSet.AddressSet) internal processSet;

    /// Events.
    event NewAuthorizerAdded(bool indexed isDelegateCall, bytes32 indexed role, address indexed authorizer);
    event NewProcessAdded(bool indexed isDelegateCall, address indexed authorizer);
    event AuthorizerRemoved(bool indexed isDelegateCall, bytes32 indexed role, address indexed authorizer);
    event ProcessRemoved(bool indexed isDelegateCall, address indexed authorizer);

    constructor(address _owner, address _caller, address _account) BaseAuthorizer(_owner, _caller) {
        // We need role manager.
        account = _account;
    }

    /// @dev pack/unpack should match.
    function _packHint(bytes32 role, address auth, bytes memory subHint) internal pure returns (bytes memory hint) {
        return abi.encodePacked(abi.encode(role, auth), subHint);
    }

    function _unpackHint(bytes calldata hint) internal pure returns (bytes32 role, address auth, bytes memory subHint) {
        (role, auth) = abi.decode(hint[0:64], (bytes32, address));
        subHint = hint[64:];
    }

    /// @dev Catch error of sub authorizers to prevent the case when one authorizer fails reverts the entire
    ///      check chain process.
    function _safePreExecCheck(
        address auth,
        TransactionData calldata transaction
    ) internal returns (AuthorizerReturnData memory preData) {
        try IAuthorizer(auth).preExecCheck(transaction) returns (AuthorizerReturnData memory _preData) {
            return _preData;
        } catch Error(string memory reason) {
            preData.result = AuthResult.FAILED;
            preData.message = reason;
        } catch (bytes memory reason) {
            preData.result = AuthResult.FAILED;
            preData.message = string(reason);
        }
    }

    function _safePostExecCheck(
        address auth,
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData memory preData
    ) internal returns (AuthorizerReturnData memory postData) {
        try IAuthorizer(auth).postExecCheck(transaction, callResult, preData) returns (
            AuthorizerReturnData memory _postData
        ) {
            return _postData;
        } catch Error(string memory reason) {
            postData.result = AuthResult.FAILED;
            postData.message = reason;
        } catch (bytes memory reason) {
            postData.result = AuthResult.FAILED;
            postData.message = string(reason);
        }
    }

    function _safeCollectHint(
        address auth,
        AuthorizerReturnData memory preData,
        AuthorizerReturnData memory postData
    ) internal returns (bytes memory subHint) {
        try IAuthorizerSupportingHint(auth).collectHint(preData, postData) returns (bytes memory _subHint) {
            return _subHint;
        } catch {
            return subHint;
        }
    }

    /// @dev preExecCheck and postExecCheck use extractly the same hint thus
    /// the same sub authorizer is called.
    function _preExecCheckWithHint(
        TransactionData calldata transaction
    ) internal returns (AuthorizerReturnData memory authData) {
        (bytes32 role, address auth, bytes memory subHint) = _unpackHint(transaction.hint);
        uint256 _flag = IAuthorizer(auth).flag();

        // The authorizer from hint should have either PreCheck or PostCheck.
        require(_flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);

        if (!_flag.hasPreCheck()) {
            // If pre check handler not exist, default success.
            authData.result = AuthResult.SUCCESS;
            return authData;
        }

        // Important: Validate the hint.
        // (1) The role from hint should be validated.
        require(_hasRole(transaction, role), Errors.INVALID_HINT);

        // (2) The authorizer from hint should have been registered with the role.
        bool isDelegateCall = transaction.flag.isDelegateCall();
        require(authorizerSet[isDelegateCall][role].contains(auth), Errors.INVALID_HINT);

        // Cut the hint to sub hint.
        TransactionData memory txn = transaction;
        txn.hint = subHint;

        // In hint path, this should never revert so `_safePreExecCheck()` is not used here.
        return IAuthorizer(auth).preExecCheck(txn);
    }

    function _postExecCheckWithHint(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal returns (AuthorizerReturnData memory authData) {
        (bytes32 role, address auth, bytes memory subHint) = _unpackHint(transaction.hint);
        uint256 _flag = IAuthorizer(auth).flag();

        require(_flag.isValid(), Errors.INVALID_AUTHORIZER_FLAG);
        if (!_flag.hasPostCheck()) {
            // If post check handler not exist, default success.
            authData.result = AuthResult.SUCCESS;
            return authData;
        }

        // Important: Validate the hint.
        // (1) The role from hint should be validated.
        require(_hasRole(transaction, role), Errors.INVALID_HINT);

        // (2) The authorizer from hint should have been registered with the role.
        bool isDelegateCall = transaction.flag.isDelegateCall();
        require(authorizerSet[isDelegateCall][role].contains(auth), Errors.INVALID_HINT);

        TransactionData memory txn = transaction;
        txn.hint = subHint;
        return IAuthorizer(auth).postExecCheck(txn, callResult, preData);
    }

    struct PreCheckData {
        bytes32 role;
        address authorizer;
        AuthorizerReturnData authData;
    }

    // This is very expensive on-chain.
    // Should only used to collect hint off-chain.
    PreCheckData[] internal preCheckDataCache;

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal override returns (AuthorizerReturnData memory authData) {
        if (transaction.hint.length > 0) {
            return _preExecCheckWithHint(transaction);
        }

        authData.result = AuthResult.FAILED;
        bytes32[] memory txRoles = _authenticate(transaction);
        uint256 roleLength = txRoles.length;
        if (roleLength == 0) {
            authData.message = Errors.EMPTY_ROLE_SET;
            return authData;
        }

        bool isDelegateCall = transaction.flag.isDelegateCall();
        for (uint256 i = 0; i < roleLength; ++i) {
            bytes32 role = txRoles[i];
            EnumerableSet.AddressSet storage authSet = authorizerSet[isDelegateCall][role];

            uint256 length = authSet.length();

            // Run all pre checks and record auth results.
            for (uint256 j = 0; j < length; ++j) {
                address auth = authSet.at(j);
                AuthorizerReturnData memory preData = _safePreExecCheck(auth, transaction);

                if (preData.result == AuthResult.SUCCESS) {
                    authData.result = AuthResult.SUCCESS;

                    // Only save success results.
                    preCheckDataCache.push(PreCheckData(role, auth, preData));
                }
            }
        }

        if (authData.result == AuthResult.SUCCESS) {
            // Temporary data for post checker to collect hint.
            authData.data = abi.encode(preCheckDataCache);
        } else {
            authData.message = Errors.ALL_AUTH_FAILED;
        }

        delete preCheckDataCache; // gas refund.
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal override returns (AuthorizerReturnData memory postData) {
        if (transaction.hint.length > 0) {
            return _postExecCheckWithHint(transaction, callResult, preData);
        }

        // Get pre check results from preData.
        PreCheckData[] memory preResults = abi.decode(preData.data, (PreCheckData[]));
        uint256 length = preResults.length;

        // We should have reverted in preExecCheck. But safer is better.
        require(length > 0, Errors.INVALID_HINT_COLLECTED);

        bool isDelegateCall = transaction.flag.isDelegateCall();

        for (uint256 i = 0; i < length; ++i) {
            bytes32 role = preResults[i].role;
            address authAddress = preResults[i].authorizer;

            require(authorizerSet[isDelegateCall][role].contains(authAddress), Errors.INVALID_HINT_COLLECTED);

            // Run post check.
            AuthorizerReturnData memory preCheckData = preResults[i].authData;
            postData = _safePostExecCheck(authAddress, transaction, callResult, preCheckData);

            // If pre and post both succeeded, we pass.
            if (postData.result == AuthResult.SUCCESS) {
                // Collect hint of sub authorizer if needed.
                bytes memory subHint;
                if (IAuthorizer(authAddress).flag().supportHint()) {
                    subHint = _safeCollectHint(authAddress, preCheckData, postData);
                }
                postData.data = _packHint(role, authAddress, subHint);
                return postData;
            }
        }
        postData.result = AuthResult.FAILED;
        postData.message = Errors.ALL_AUTH_FAILED;
    }

    function collectHint(
        AuthorizerReturnData calldata preAuthData,
        AuthorizerReturnData calldata postAuthData
    ) public view returns (bytes memory hint) {
        // Use post data as hint.
        hint = postAuthData.data;
    }

    /// @dev All sub preExecProcess / postExecProcess handlers are supposed be called.
    function _preExecProcess(TransactionData calldata transaction) internal virtual override {
        if (!_unionFlag.hasPreProcess()) return;

        bool isDelegateCall = transaction.flag.isDelegateCall();

        EnumerableSet.AddressSet storage procSet = processSet[isDelegateCall];
        uint256 length = procSet.length();
        for (uint256 i = 0; i < length; i++) {
            IAuthorizer auth = IAuthorizer(procSet.at(i));
            if (auth.flag().hasPreProcess()) {
                // Ignore reverts.
                try auth.preExecProcess(transaction) {} catch {}
            }
        }
    }

    function _postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) internal virtual override {
        if (!_unionFlag.hasPostProcess()) return;

        bool isDelegateCall = transaction.flag.isDelegateCall();

        EnumerableSet.AddressSet storage procSet = processSet[isDelegateCall];
        uint256 length = procSet.length();
        for (uint256 i = 0; i < length; i++) {
            IAuthorizer auth = IAuthorizer(procSet.at(i));
            if (auth.flag().hasPostProcess()) {
                // Ignore reverts.
                try auth.postExecProcess(transaction, callResult) {} catch {}
            }
        }
    }

    /// External / Public funtions.
    function addAuthorizer(bool isDelegateCall, bytes32 role, address authorizer) external onlyOwner {
        uint256 _flag = IAuthorizer(authorizer).flag();

        if (authorizerSet[isDelegateCall][role].add(authorizer)) {
            emit NewAuthorizerAdded(isDelegateCall, role, authorizer);

            // Collect flag.
            _unionFlag |= _flag;

            if (_flag.hasPreProcess() || _flag.hasPostProcess()) {
                // An authorizer with process handler can NOT be installed twice as this cause
                // confusion when running process handler twice in one transaction.
                require(processSet[isDelegateCall].add(authorizer), Errors.SAME_PROCESS_TWICE);

                emit NewProcessAdded(isDelegateCall, authorizer);
            }
        }
    }

    function removeAuthorizer(bool isDelegateCall, bytes32 role, address authorizer) external onlyOwner {
        uint256 _flag = IAuthorizer(authorizer).flag();

        if (authorizerSet[isDelegateCall][role].remove(authorizer)) {
            emit AuthorizerRemoved(isDelegateCall, role, authorizer);

            if (_flag.hasPreProcess() || _flag.hasPostProcess()) {
                // It is ok to remove here as we has checked duplication in `addAuthorizer()`.
                if (processSet[isDelegateCall].remove(authorizer)) {
                    emit ProcessRemoved(isDelegateCall, authorizer);

                    if (processSet[isDelegateCall].length() == 0 && processSet[!isDelegateCall].length() == 0) {
                        _unionFlag -= (_unionFlag & (AuthFlags.HAS_PRE_PROC_MASK | AuthFlags.HAS_POST_PROC_MASK));
                    }
                }
            }
        }
    }

    /// External view funtions.

    function flag() external view returns (uint256) {
        return _unionFlag | AuthFlags.SUPPORT_HINT_MASK;
    }

    function authorizerSize(bool isDelegateCall, bytes32 role) external view returns (uint256) {
        return authorizerSet[isDelegateCall][role].length();
    }

    function hasAuthorizer(bool isDelegateCall, bytes32 role, address auth) external view returns (bool) {
        return authorizerSet[isDelegateCall][role].contains(auth);
    }

    function getAuthorizer(bool isDelegateCall, bytes32 role, uint256 i) external view returns (address) {
        return authorizerSet[isDelegateCall][role].at(i);
    }

    /// @dev View function allow user to specify the range in case we have very big set
    ///      which can exhaust the gas of block limit when enumerating the entire list.
    function getAuthorizers(
        bool isDelegateCall,
        bytes32 role,
        uint256 start,
        uint256 end
    ) external view returns (address[] memory auths) {
        uint256 authorizerSetSize = authorizerSet[isDelegateCall][role].length();
        if (end > authorizerSetSize) end = authorizerSetSize;
        auths = new address[](end - start);
        for (uint256 i = 0; i < end - start; i++) {
            auths[i] = authorizerSet[isDelegateCall][role].at(start + i);
        }
    }

    function getAllAuthorizers(bool isDelegateCall, bytes32 role) external view returns (address[] memory) {
        return authorizerSet[isDelegateCall][role].values();
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseOwnable.sol";
import "Errors.sol";
import "IAuthorizer.sol";
import "IAccount.sol";
import "IRoleManager.sol";

/// @title BaseAuthorizer - A basic pausable authorizer with caller restriction.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Base contract to extend to implement specific authorizer.
abstract contract BaseAuthorizer is IAuthorizer, BaseOwnable {
    /// @dev Override such constants while extending BaseAuthorizer.

    bool public paused = false;

    // Often used for off-chain system.
    // Each contract instance has its own value.
    bytes32 public tag = "";

    // The caller which is able to call this contract's pre/postExecProcess
    // and pre/postExecCheck having side-effect.
    // It is usually the account or the parent authorizer(set) on higher level.
    address public caller;

    // This is the account this authorizer works for.
    // Currently used to lookup `roleManager`.
    // If not used it is OK to keep it unset.
    address public account;

    event CallerSet(address indexed caller);
    event AccountSet(address indexed account);
    event TagSet(bytes32 indexed tag);
    event PausedSet(bool indexed status);

    constructor(address _owner, address _caller) BaseOwnable(_owner) {
        caller = _caller;
    }

    function initialize(address _owner, address _caller) public {
        initialize(_owner);
        caller = _caller;
    }

    function initialize(address _owner, address _caller, address _account) public {
        initialize(_owner, _caller);
        account = _account;
    }

    modifier onlyCaller() virtual {
        require(msg.sender == caller, Errors.INVALID_CALLER);
        _;
    }

    /// @notice Change the caller.
    /// @param _caller the caller which calls the authorizer.
    function setCaller(address _caller) external onlyOwner {
        caller = _caller;
        emit CallerSet(_caller);
    }

    /// @notice Change the account.
    /// @param _account the account which the authorizer get role manager from.
    function setAccount(address _account) external onlyOwner {
        account = _account;
        emit AccountSet(_account);
    }

    /// @notice Change the tag for the contract instance.
    /// @dev For off-chain index.
    /// @param _tag the tag
    function setTag(bytes32 _tag) external onlyOwner {
        tag = _tag;
        emit TagSet(_tag);
    }

    /// @notice Set the pause status. Authorizer just denies all when paused.
    /// @param _paused the paused status: true or false.
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit PausedSet(_paused);
    }

    /// @notice Function check if a transaction can be executed.
    /// @param transaction Transaction data which contains from,to,value,data,delegate
    /// @return authData Return check status, error message and hint (if needed)
    function preExecCheck(
        TransactionData calldata transaction
    ) external virtual onlyCaller returns (AuthorizerReturnData memory authData) {
        if (paused) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.AUTHORIZER_PAUSED;
        } else {
            authData = _preExecCheck(transaction);
        }
    }

    /// @notice Check after transaction execution.
    /// @param transaction Transaction data which contains from,to,value,data,delegate
    /// @param callResult Transaction call status and return data.
    function postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) external virtual onlyCaller returns (AuthorizerReturnData memory authData) {
        if (paused) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.AUTHORIZER_PAUSED;
        } else {
            authData = _postExecCheck(transaction, callResult, preData);
        }
    }

    /// @dev Perform actions before the transaction execution.
    /// `onlyCaller` check forced here or attacker can call this directly
    /// to pollute our data.
    function preExecProcess(TransactionData calldata transaction) external virtual onlyCaller {
        if (!paused) _preExecProcess(transaction);
    }

    /// @dev Perform actions after the transaction execution.
    /// `onlyCaller` check forced here or attacker can call this directly
    /// to pollute our data.
    function postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) external virtual onlyCaller {
        if (!paused) _postExecProcess(transaction, callResult);
    }

    /// @dev Extract the roles of the delegate. If no roleManager set return empty lists.
    function _authenticate(TransactionData calldata transaction) internal view returns (bytes32[] memory roles) {
        return _authenticate(transaction.delegate);
    }

    function _authenticate(address delegate) internal view returns (bytes32[] memory roles) {
        require(account != address(0), Errors.ACCOUNT_NOT_SET);
        address roleManager = IAccount(account).roleManager();
        require(roleManager != address(0), Errors.ROLE_MANAGER_NOT_SET);
        roles = IRoleManager(roleManager).getRoles(delegate);
    }

    /// @dev Call `roleManager` to validate the role of delegate.
    function _hasRole(TransactionData calldata transaction, bytes32 role) internal view returns (bool) {
        return _hasRole(transaction.delegate, role);
    }

    function _hasRole(address delegate, bytes32 role) internal view returns (bool) {
        require(account != address(0), Errors.ACCOUNT_NOT_SET);
        address roleManager = IAccount(account).roleManager();
        require(roleManager != address(0), Errors.ROLE_MANAGER_NOT_SET);
        return IRoleManager(roleManager).hasRole(delegate, role);
    }

    /// @dev Override this to implement new authorization.
    ///      NOTE: If your check involves side-effect, onlyCaller should be used.
    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual returns (AuthorizerReturnData memory authData) {}

    /// @dev Override this to implement new authorization.
    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual returns (AuthorizerReturnData memory) {}

    function _preExecProcess(TransactionData calldata transaction) internal virtual {}

    function _postExecProcess(
        TransactionData calldata transaction,
        TransactionResult calldata callResult
    ) internal virtual {}

    /// @dev Override this if you implement new type of authorizer.
    function TYPE() external view virtual returns (bytes32) {
        return AuthType.COMMON;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseAuthorizer.sol";

/// @title FuncAuthorizer - Manages contract, method pairs which can be accessed by delegates.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice FuncAuthorizer only checks selector. Use ACL if function arguments check is needed.
contract FuncAuthorizer is BaseAuthorizer {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant NAME = "FuncAuthorizer";
    uint256 public constant VERSION = 1;
    uint256 public constant flag = AuthFlags.HAS_PRE_CHECK_MASK;
    bytes32 public constant override TYPE = AuthType.FUNC;

    /// @dev Tracks the set of contract address.
    EnumerableSet.AddressSet contractSet;

    /// @dev `contract address` => `function selectors`
    mapping(address => EnumerableSet.Bytes32Set) allowContractToFuncs;

    /// Events

    event AddContractFunc(address indexed _contract, string func, address indexed sender);
    event AddContractFuncSig(address indexed _contract, bytes4 indexed funcSig, address indexed sender);
    event RemoveContractFunc(address indexed _contract, string func, address indexed sender);
    event RemoveContractFuncSig(address indexed _contract, bytes4 indexed funcSig, address indexed sender);

    constructor(address _owner, address _caller) BaseAuthorizer(_owner, _caller) {}

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal view override returns (AuthorizerReturnData memory authData) {
        // If calldata size is less than a selector, deny it.
        // Use TransferAuthorizer to check ETH transfer.
        if (transaction.data.length < 4) {
            authData.result = AuthResult.FAILED;
            authData.message = "invalid data length";
            return authData;
        }

        bytes4 selector = _getSelector(transaction.data);

        if (_isAllowedSelector(transaction.to, selector)) {
            authData.result = AuthResult.SUCCESS;
        } else {
            authData.result = AuthResult.FAILED;
            authData.message = "function not allowed";
        }
    }

    function _getSelector(bytes calldata data) internal pure returns (bytes4 selector) {
        assembly {
            selector := calldataload(data.offset)
        }
    }

    function _isAllowedSelector(address target, bytes4 selector) internal view returns (bool) {
        return allowContractToFuncs[target].contains(selector);
    }

    /// @dev Default success.
    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal view override returns (AuthorizerReturnData memory authData) {
        authData.result = AuthResult.SUCCESS;
    }

    /// @notice Add contract and related function signature list. The function signature should be
    ///         canonicalized removing argument names and blanks chars.
    ///         ref: https://docs.soliditylang.org/en/v0.8.19/abi-spec.html#function-selector
    /// @dev keccak256 hash is calcuated and only 4 bytes selector is stored to reduce storage usage.
    function addContractFuncs(address _contract, string[] calldata funcList) external onlyOwner {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (allowContractToFuncs[_contract].add(funcSelector32)) {
                emit AddContractFunc(_contract, funcList[index], msg.sender);
                emit AddContractFuncSig(_contract, funcSelector, msg.sender);
            }
        }

        contractSet.add(_contract);
    }

    /// @notice Remove contract and its function signature list from access list.
    function removeContractFuncs(address _contract, string[] calldata funcList) external onlyOwner {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (allowContractToFuncs[_contract].remove(funcSelector32)) {
                emit RemoveContractFunc(_contract, funcList[index], msg.sender);
                emit RemoveContractFuncSig(_contract, funcSelector, msg.sender);
            }
        }

        if (allowContractToFuncs[_contract].length() == 0) {
            contractSet.remove(_contract);
        }
    }

    /// @notice Similar to `addContractFuncs()` but bytes4 selector is used.
    /// @dev keccak256 hash should be performed off-chain.
    function addContractFuncsSig(address _contract, bytes4[] calldata funcSigList) external onlyOwner {
        require(funcSigList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcSigList.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList[index]);
            if (allowContractToFuncs[_contract].add(funcSelector32)) {
                emit AddContractFuncSig(_contract, funcSigList[index], msg.sender);
            }
        }

        contractSet.add(_contract);
    }

    /// @notice Remove contract and its function selector list from access list.
    function removeContractFuncsSig(address _contract, bytes4[] calldata funcSigList) external onlyOwner {
        require(funcSigList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcSigList.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList[index]);
            if (allowContractToFuncs[_contract].remove(funcSelector32)) {
                emit RemoveContractFuncSig(_contract, funcSigList[index], msg.sender);
            }
        }

        if (allowContractToFuncs[_contract].length() == 0) {
            contractSet.remove(_contract);
        }
    }

    /// @notice Get all the contracts ever associated with any role
    /// @return list of contract addresses
    function getAllContracts() public view returns (address[] memory) {
        return contractSet.values();
    }

    /// @notice Given a contract, list all the function selectors of this contract associated with a role
    /// @param _contract the contract
    /// @return list of function selectors in the contract ever associated with a role
    function getFuncsByContract(address _contract) public view returns (bytes32[] memory) {
        return allowContractToFuncs[_contract].values();
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseACL.sol";

/// @title TransferAuthorizer - Manages ERC20/ETH transfer permissons.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice This checks token-receiver pairs, no amount is restricted.
contract TransferAuthorizer is BaseAuthorizer {
    bytes32 public constant NAME = "TransferAuthorizer";
    uint256 public constant VERSION = 2;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bytes32 public constant override TYPE = AuthType.TRANSFER;
    uint256 public constant flag = AuthFlags.HAS_PRE_CHECK_MASK;

    // function transfer(address recipient, uint256 amount)
    bytes4 TRANSFER_SELECTOR = 0xa9059cbb;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet tokenSet;

    mapping(address => EnumerableSet.AddressSet) tokenToReceivers;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);

    event TokenReceiverAdded(address indexed token, address indexed receiver);
    event TokenReceiverRemoved(address indexed token, address indexed receiver);

    struct TokenReceiver {
        address token;
        address receiver;
    }

    constructor(address _owner, address _caller) BaseAuthorizer(_owner, _caller) {}

    /// @notice Add token-receiver pairs. Use 0xee..ee for native ETH.
    function addTokenReceivers(TokenReceiver[] calldata tokenReceivers) external onlyOwner {
        for (uint i = 0; i < tokenReceivers.length; i++) {
            address token = tokenReceivers[i].token;
            address receiver = tokenReceivers[i].receiver;
            if (tokenSet.add(token)) {
                emit TokenAdded(token);
            }

            if (tokenToReceivers[token].add(receiver)) {
                emit TokenReceiverAdded(token, receiver);
            }
        }
    }

    function removeTokenReceivers(TokenReceiver[] calldata tokenReceivers) external onlyOwner {
        for (uint i = 0; i < tokenReceivers.length; i++) {
            address token = tokenReceivers[i].token;
            address receiver = tokenReceivers[i].receiver;
            if (tokenToReceivers[token].remove(receiver)) {
                emit TokenReceiverRemoved(token, receiver);
                if (tokenToReceivers[tokenReceivers[i].token].length() == 0) {
                    if (tokenSet.remove(token)) {
                        emit TokenRemoved(token);
                    }
                }
            }
        }
    }

    // View functions.

    function getAllToken() external view returns (address[] memory) {
        return tokenSet.values();
    }

    /// @dev View function allow user to specify the range in case we have very big token set
    ///      which can exhaust the gas of block limit.
    function getTokens(uint256 start, uint256 end) external view returns (address[] memory) {
        uint256 size = tokenSet.length();
        if (end > size) end = size;
        require(start < end, "start >= end");
        address[] memory _tokens = new address[](end - start);
        for (uint i = 0; i < end - start; i++) {
            _tokens[i] = tokenSet.at(start + i);
        }
        return _tokens;
    }

    function getTokenReceivers(address token) external view returns (address[] memory) {
        return tokenToReceivers[token].values();
    }

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        if (
            transaction.data.length == 68 && // 4 + 32 + 32
            bytes4(transaction.data[0:4]) == TRANSFER_SELECTOR &&
            transaction.value == 0
        ) {
            // ETH transfer not allowed and token in white list.
            (address recipient /*uint256 amount*/, ) = abi.decode(transaction.data[4:], (address, uint256));
            address token = transaction.to;
            if (tokenToReceivers[token].contains(recipient)) {
                authData.result = AuthResult.SUCCESS;
                return authData;
            }
        } else if (transaction.data.length == 0 && transaction.value > 0) {
            // Contract call not allowed and token in white list.
            address recipient = transaction.to;
            if (tokenToReceivers[ETH].contains(recipient)) {
                authData.result = AuthResult.SUCCESS;
                return authData;
            }
        }
        authData.result = AuthResult.FAILED;
        authData.message = "transfer not allowed";
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        authData.result = AuthResult.SUCCESS;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseAuthorizer.sol";

/// @title BaseACL - Basic ACL template which uses the call-self trick to perform function and parameters check.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @dev Steps to extend this:
///        1. Set the NAME and VERSION.
///        2. Write ACL functions according the target contract.
///        3. Add a constructor. eg:
///           `constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}`
///        4. Override `contracts()` to only target contracts that you checks. For txn
////          whose to address is not in the list `_preExecCheck()` will revert.
///        5. (Optional) If state changing operation in the checking method is required,
///           override `_preExecCheck()` to change `staticcall` to `call`.
///        6. (Optional) Override `permissions()` to summary your checking methods.
///
///      NOTE for ACL developers:
///        1. Implement your checking functions which should be defined extractly the same as
///           the target method to control so you do not bother to write a lot abi.decode code.
///        2. Checking funtions should NOT return any value, use `require` to perform your check.
///        3. BaseACL may serve for multiple target contracts.
///            - Implement contracts() to manage the target contracts set.
///            - Use `onlyContract` modifier or check `_txn().to` in checking functions.
///        4. Do NOT implement your own `setXXX` function, wrap your data into `Variant` and
///           use `setVariant` `getVariant` instead.
///        5. If you still need your own setter, ensure `onlyOwner` is used.

abstract contract BaseACL is BaseAuthorizer {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @dev Set such constants in sub contract.
    // bytes32 public constant NAME = "BaseACL";
    // bytes32 public constant override TYPE = "ACLType";
    // uint256 public constant VERSION = 0;

    /// Only preExecCheck is used in BaseACL.
    uint256 public constant flag = AuthFlags.HAS_PRE_CHECK_MASK;

    constructor(address _owner, address _caller) BaseAuthorizer(_owner, _caller) {}

    /// Internal functions.
    function _parseReturnData(
        bool success,
        bytes memory revertData
    ) internal pure returns (AuthorizerReturnData memory authData) {
        if (success) {
            // ACL check function should return empty bytes which differs from normal view functions.
            require(revertData.length == 0, Errors.ACL_FUNC_RETURNS_NON_EMPTY);
            authData.result = AuthResult.SUCCESS;
        } else {
            if (revertData.length < 68) {
                // 4(Error sig) + 32(offset) + 32(length)
                authData.message = string(revertData);
            } else {
                assembly {
                    // Slice the sighash.
                    revertData := add(revertData, 0x04)
                }
                authData.message = abi.decode(revertData, (string));
            }
        }
    }

    function _contractCheck(TransactionData calldata transaction) internal virtual returns (bool result) {
        // This works as a catch-all check. Sample but safer.
        address to = transaction.to;
        address[] memory _contracts = contracts(); // Call external.
        for (uint i = 0; i < _contracts.length; i++) {
            if (to == _contracts[i]) return true;
        }
        return false;
    }

    function _packTxn(TransactionData calldata transaction) internal pure virtual returns (bytes memory) {
        bytes memory txnData = abi.encode(transaction);
        bytes memory callDataSize = abi.encode(transaction.data.length);
        return abi.encodePacked(transaction.data, txnData, callDataSize);
    }

    function _unpackTxn() internal pure virtual returns (TransactionData memory transaction) {
        uint256 end = msg.data.length;
        uint256 callDataSize = abi.decode(msg.data[end - 32:end], (uint256));
        transaction = abi.decode(msg.data[callDataSize:], (TransactionData));
    }

    // @dev Only valid in self-call checking functions.
    function _txn() internal pure virtual returns (TransactionData memory transaction) {
        return _unpackTxn();
    }

    function _preExecCheck(
        TransactionData calldata transaction
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        if (!_contractCheck(transaction)) {
            authData.result = AuthResult.FAILED;
            authData.message = Errors.NOT_IN_CONTRACT_LIST;
            return authData;
        }
        (bool success, bytes memory revertData) = address(this).staticcall(_packTxn(transaction));
        return _parseReturnData(success, revertData);
    }

    function _postExecCheck(
        TransactionData calldata transaction,
        TransactionResult calldata callResult,
        AuthorizerReturnData calldata preData
    ) internal virtual override returns (AuthorizerReturnData memory authData) {
        authData.result = AuthResult.SUCCESS;
    }

    // Internal view functions.

    // Utilities for checking functions.
    function _checkRecipient(address _recipient) internal view {
        require(_recipient == _txn().from, "Invalid recipient");
    }

    function _checkContract(address _contract) internal view {
        require(_contract == _txn().to, "Invalid contract");
    }

    // Modifiers.

    modifier onlyContract(address _contract) {
        _checkContract(_contract);
        _;
    }

    /// External functions

    /// @dev Implement your own access control checking functions here.

    // example:

    // function transfer(address to, uint256 amount)
    //     onlyContract(USDT_ADDR)
    //     external view
    // {
    //     require(amount > 0 & amount < 10000, "amount not in range");
    // }

    /// @dev Override this as `_preExecCheck` used.
    /// @notice Target contracts this BaseACL controls.
    function contracts() public view virtual returns (address[] memory _contracts) {}

    fallback() external virtual {
        revert(Errors.METHOD_NOT_ALLOW);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "EnumerableSet.sol";

import "BaseACL.sol";

/// @title DEXBaseACL - ACL template for DEX.
/// @author Cobo Safe Dev Team https://www.cobo.com/
abstract contract DEXBaseACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant override TYPE = AuthType.DEX;

    EnumerableSet.AddressSet swapInTokenWhitelist;
    EnumerableSet.AddressSet swapOutTokenWhitelist;

    event SwapInTokenAdded(address indexed token);
    event SwapInTokenRemoved(address indexed token);
    event SwapOutTokenAdded(address indexed token);
    event SwapOutTokenRemoved(address indexed token);

    struct SwapInToken {
        address token;
        bool tokenStatus;
    }

    struct SwapOutToken {
        address token;
        bool tokenStatus;
    }

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    // External set functions.

    function addSwapInTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (swapInTokenWhitelist.add(token)) {
                emit SwapInTokenAdded(token);
            }
        }
    }

    function removeSwapInTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (swapInTokenWhitelist.remove(token)) {
                emit SwapInTokenRemoved(token);
            }
        }
    }

    function addSwapOutTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (swapOutTokenWhitelist.add(token)) {
                emit SwapOutTokenAdded(token);
            }
        }
    }

    function removeSwapOutTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (swapOutTokenWhitelist.remove(token)) {
                emit SwapOutTokenRemoved(token);
            }
        }
    }

    // External view functions.
    function hasSwapInToken(address _token) public view returns (bool) {
        return swapInTokenWhitelist.contains(_token);
    }

    function getSwapInTokens() external view returns (address[] memory tokens) {
        return swapInTokenWhitelist.values();
    }

    function hasSwapOutToken(address _token) public view returns (bool) {
        return swapOutTokenWhitelist.contains(_token);
    }

    function getSwapOutTokens() external view returns (address[] memory tokens) {
        return swapOutTokenWhitelist.values();
    }

    // Internal check utility functions.

    function _swapInTokenCheck(address _token) internal view {
        require(hasSwapInToken(_token), "In token not allowed");
    }

    function _swapOutTokenCheck(address _token) internal view {
        require(hasSwapOutToken(_token), "Out token not allowed");
    }

    function _swapInOutTokenCheck(address _inToken, address _outToken) internal view {
        _swapInTokenCheck(_inToken);
        _swapOutTokenCheck(_outToken);
    }
}