/**
 *Submitted for verification at Arbiscan on 2022-10-28
*/

pragma solidity ^0.8.10;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

error TargetNotAContract(address target_);
error InvalidKeycode(bytes5 keycode_);
error InvalidRole(bytes32 role_);

function ensureContract(address target_) view {
    if (target_.code.length == 0) revert TargetNotAContract(target_);
}

function ensureValidKeycode(bytes5 keycode_) pure {
    for (uint256 i = 0; i < 5; ) {
        bytes1 char = keycode_[i];

        if (char < 0x41 || char > 0x5A) revert InvalidKeycode(keycode_); // A-Z only

        unchecked {
            i++;
        }
    }
}

function ensureValidRole(bytes32 role_) pure {
    for (uint256 i = 0; i < 32; ) {
        bytes1 char = role_[i];
        if ((char < 0x61 || char > 0x7A) && char != 0x00) {
            revert InvalidRole(role_); // a-z only
        }
        unchecked {
            i++;
        }
    }
}

// ######################## ~ ERRORS ~ ########################

// KERNEL ADAPTER

error KernelAdapter_OnlyKernel(address caller_);

// MODULE

error Module_PolicyNotAuthorized(address policy_);

// POLICY

error Policy_OnlyRole(bytes32 role_);
error Policy_ModuleDoesNotExist(bytes5 keycode_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
error Kernel_OnlyAdmin(address caller_);
error Kernel_ModuleAlreadyInstalled(bytes5 module_);
error Kernel_InvalidModuleUpgrade(bytes5 module_);
error Kernel_PolicyAlreadyApproved(address policy_);
error Kernel_PolicyNotApproved(address policy_);
error Kernel_AddressAlreadyHasRole(address addr_, bytes32 role_);
error Kernel_AddressDoesNotHaveRole(address addr_, bytes32 role_);
error Kernel_RoleDoesNotExist(bytes32 role_);

// ######################## ~ GLOBAL TYPES ~ ########################

enum Actions {
    InstallModule,
    UpgradeModule,
    ActivatePolicy,
    DeactivatePolicy,
    ChangeExecutor,
    ChangeAdmin,
    MigrateKernel
}

struct Instruction {
    Actions action;
    address target;
}

struct Permissions {
    bytes5 keycode;
    bytes4 funcSelector;
}

// type Keycode is bytes5;
// type Role is bytes32;

// ######################## ~ MODULE ABSTRACT ~ ########################

abstract contract KernelAdapter {
    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert KernelAdapter_OnlyKernel(msg.sender);
        _;
    }

    function changeKernel(Kernel newKernel_) external onlyKernel {
        kernel = newKernel_;
    }
}

abstract contract Module is KernelAdapter {
    event PermissionSet(bytes4 funcSelector_, address policy_, bool permission_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    modifier permissioned() {
        if (!kernel.modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig))
            revert Module_PolicyNotAuthorized(msg.sender);
        _;
    }

    function KEYCODE() public pure virtual returns (bytes5);

    /// @notice Specify which version of a module is being implemented.
    /// @dev Minor version change retains interface. Major version upgrade indicates
    /// @dev breaking change to the interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module.
    /// @dev This function is called when the module is installed or upgraded by the kernel.
    /// @dev Used to encompass any upgrade logic. Must be gated by onlyKernel.
    function INIT() external virtual onlyKernel {}
}

abstract contract Policy is KernelAdapter {
    bool public isActive;

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    modifier onlyRole(bytes32 role_) {
        if (!kernel.hasRole(msg.sender, role_)) revert Policy_OnlyRole(role_);
        _;
    }

    function configureDependencies() external virtual onlyKernel returns (bytes5[] memory dependencies) {}

    function requestPermissions() external view virtual onlyKernel returns (Permissions[] memory requests) {}

    function getModuleAddress(bytes5 keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));
        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);
        return moduleForKeycode;
    }

    /// @notice Function to let kernel grant or revoke active status
    function setActiveStatus(bool activate_) external onlyKernel {
        isActive = activate_;
    }
}

contract Kernel {
    // ######################## ~ VARS ~ ########################
    address public executor;
    address public admin;

    // ######################## ~ DEPENDENCY MANAGEMENT ~ ########################

    // Module Management
    bytes5[] public allKeycodes;
    mapping(bytes5 => Module) public getModuleForKeycode; // get contract for module keycode
    mapping(Module => bytes5) public getKeycodeForModule; // get module keycode for contract

    // Module dependents data. Manages module dependencies for policies
    mapping(bytes5 => Policy[]) public moduleDependents;
    mapping(bytes5 => mapping(Policy => uint256)) public getDependentIndex;

    // Module <> Policy Permissions. Policy -> Keycode -> Function Selector -> Permission
    mapping(bytes5 => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions; // for policy addr, check if they have permission to call the function int he module

    // List of all active policies
    Policy[] public activePolicies;
    mapping(Policy => uint256) public getPolicyIndex;

    // Policy roles data
    mapping(address => mapping(bytes32 => bool)) public hasRole;
    mapping(bytes32 => bool) public isRole;

    // ######################## ~ EVENTS ~ ########################

    event PermissionsUpdated(bytes5 indexed keycode_, Policy indexed policy_, bytes4 funcSelector_, bool granted_);
    event RoleGranted(bytes32 indexed role_, address indexed addr_);
    event RoleRevoked(bytes32 indexed role_, address indexed addr_);
    event ActionExecuted(Actions indexed action_, address indexed target_);

    // ######################## ~ BODY ~ ########################

    constructor() {
        executor = msg.sender;
        admin = msg.sender;
    }

    // ######################## ~ MODIFIERS ~ ########################

    // Role reserved for governor or any executing address
    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    // Role for managing policy roles
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Kernel_OnlyAdmin(msg.sender);
        _;
    }

    // ######################## ~ KERNEL INTERFACE ~ ########################

    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _installModule(Module(target_));
        } else if (action_ == Actions.UpgradeModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _upgradeModule(Module(target_));
        } else if (action_ == Actions.ActivatePolicy) {
            ensureContract(target_);
            _activatePolicy(Policy(target_));
        } else if (action_ == Actions.DeactivatePolicy) {
            ensureContract(target_);
            _deactivatePolicy(Policy(target_));
        } else if (action_ == Actions.MigrateKernel) {
            ensureContract(target_);
            _migrateKernel(Kernel(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.ChangeAdmin) {
            admin = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    // ######################## ~ KERNEL INTERNAL ~ ########################

    function _installModule(Module newModule_) internal {
        bytes5 keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0)) revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
        allKeycodes.push(keycode);

        newModule_.INIT();
    }

    function _upgradeModule(Module newModule_) internal {
        bytes5 keycode = newModule_.KEYCODE();
        Module oldModule = getModuleForKeycode[keycode];

        if (address(oldModule) == address(0) || oldModule == newModule_) revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = bytes5(0);
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        newModule_.INIT();

        _reconfigurePolicies(keycode);
    }

    function _activatePolicy(Policy policy_) internal {
        if (policy_.isActive()) revert Kernel_PolicyAlreadyApproved(address(policy_));

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length - 1;

        // Record module dependencies
        bytes5[] memory dependencies = policy_.configureDependencies();
        uint256 depLength = dependencies.length;

        for (uint256 i; i < depLength; ) {
            bytes5 keycode = dependencies[i];

            moduleDependents[keycode].push(policy_);
            getDependentIndex[keycode][policy_] = moduleDependents[keycode].length - 1;

            unchecked {
                ++i;
            }
        }

        // Set policy status to active
        policy_.setActiveStatus(true);
    }

    function _deactivatePolicy(Policy policy_) internal {
        if (!policy_.isActive()) revert Kernel_PolicyNotApproved(address(policy_));

        // Revoke permissions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, false);

        // Remove policy from all policy data structures
        uint256 idx = getPolicyIndex[policy_];
        Policy lastPolicy = activePolicies[activePolicies.length - 1];

        activePolicies[idx] = lastPolicy;
        activePolicies.pop();
        getPolicyIndex[lastPolicy] = idx;
        delete getPolicyIndex[policy_];

        // Remove policy from module dependents
        _pruneFromDependents(policy_);

        // Set policy status to inactive
        policy_.setActiveStatus(false);
    }

    // WARNING: ACTION WILL BRICK THIS KERNEL. All functionality will move to the new kernel
    // New kernel must add in all of the modules and policies via executeAction
    // NOTE: Data does not get cleared from this kernel
    function _migrateKernel(Kernel newKernel_) internal {
        uint256 keycodeLen = allKeycodes.length;
        for (uint256 i; i < keycodeLen; ) {
            Module module = Module(getModuleForKeycode[allKeycodes[i]]);
            module.changeKernel(newKernel_);
            unchecked {
                ++i;
            }
        }

        uint256 policiesLen = activePolicies.length;
        for (uint256 j; j < policiesLen; ) {
            Policy policy = activePolicies[j];

            // Deactivate before changing kernel
            policy.setActiveStatus(false);
            policy.changeKernel(newKernel_);
            unchecked {
                ++j;
            }
        }
    }

    function _reconfigurePolicies(bytes5 keycode_) internal {
        Policy[] memory dependents = moduleDependents[keycode_];
        uint256 depLength = dependents.length;

        for (uint256 i; i < depLength; ) {
            dependents[i].configureDependencies();

            unchecked {
                ++i;
            }
        }
    }

    function _setPolicyPermissions(
        Policy policy_,
        Permissions[] memory requests_,
        bool grant_
    ) internal {
        uint256 reqLength = requests_.length;
        for (uint256 i = 0; i < reqLength; ) {
            Permissions memory request = requests_[i];
            modulePermissions[request.keycode][policy_][request.funcSelector] = grant_;

            emit PermissionsUpdated(request.keycode, policy_, request.funcSelector, grant_);

            unchecked {
                ++i;
            }
        }
    }

    function _pruneFromDependents(Policy policy_) internal {
        bytes5[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            bytes5 keycode = dependencies[i];
            Policy[] storage dependents = moduleDependents[keycode];

            uint256 origIndex = getDependentIndex[keycode][policy_];
            Policy lastPolicy = dependents[dependents.length - 1];

            // Swap with last and pop
            dependents[origIndex] = lastPolicy;
            dependents.pop();

            // Record new index and delete terminated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }

    function grantRole(bytes32 role_, address addr_) public onlyAdmin {
        if (hasRole[addr_][role_]) revert Kernel_AddressAlreadyHasRole(addr_, role_);

        ensureValidRole(role_);
        if (!isRole[role_]) isRole[role_] = true;

        hasRole[addr_][role_] = true;

        emit RoleGranted(role_, addr_);
    }

    function revokeRole(bytes32 role_, address addr_) public onlyAdmin {
        if (!isRole[role_]) revert Kernel_RoleDoesNotExist(role_);
        if (!hasRole[addr_][role_]) revert Kernel_AddressDoesNotHaveRole(addr_, role_);

        hasRole[addr_][role_] = false;

        emit RoleRevoked(role_, addr_);
    }
}

contract BarnBondingModule is Module {
    using SafeTransferLib for ERC20;

    //////////////////////////////////////////////////////////////////////////////
    //                              SYSTEM CONFIG                               //
    //////////////////////////////////////////////////////////////////////////////

    constructor(Kernel kernel_) Module(kernel_) {}
    
    /// @inheritdoc Module
    function KEYCODE() public pure override returns (bytes5) {
        return "BNDNG";
    }
    
    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        return (1, 0);
    }

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price, In thousandths of a % i.e. 500 = 0.5%
        uint256 maxDebt; // Maximum amount of debt we can take on
        uint256 decayLength; // Amount of time it takes for debt to decay
        uint256 vestingTerm; // in timestamp
        uint256 fee; // as % of bond payout, in hundreths. ( 50 = 0.5%)
    }

    enum PARAMETER {
        VESTING,
        DECAY,
        FEE,
        DEBT,
        CONTROL
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // BOND remaining to be paid
        uint256 vesting; // Time left to vest
        uint256 lastBlockTimestamp; // Last interaction
        uint256 pricePaid; // In DAI, for front end viewing
    }
    mapping(address => Terms) public terms; // stores terms for new bonds
    mapping(address => uint256) public lastDecay; // stores the timestamp for when the bond was last decayed
    mapping(address => uint256) public currentDebt; // stores the amount of debt we currently have for an asset
    mapping(address => mapping(address => Bond)) public bondInfo; // stores bond information for depositors
    mapping(address => bool) public acceptedAsset;

    /////////////////////////////////////////////////////////////////////////////////
    //                             Policy Interface                                //
    /////////////////////////////////////////////////////////////////////////////////

    event AssetAdded(address indexed token);
    event AssetRemoved(address indexed token);
    event BondCreated(address indexed token, address recipient, uint256 payout, uint256 expires, uint256 price);
    event BondRedeemed(address indexed token, address recipient, uint256 payout, uint256 remaining, uint256 vesting);
    event BondTermsSet(address indexed token, PARAMETER parameter, uint256 input);
    event BondTermsConfigured(
        address indexed token,
        uint256 controlVariable,
        uint256 vestingTerm,
        uint256 maxDebt,
        uint256 decayLength,
        uint256 fee
    );

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _fee uint
     *  @param _asset address
     */
    function configureBondTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _maxDebt,
        uint256 _decayLength,
        uint256 _fee,
        address _asset
    ) external permissioned {
        terms[_asset] = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            maxDebt: _maxDebt,
            decayLength: _decayLength,
            fee: _fee
        });
        if (lastDecay[_asset] == 0) lastDecay[_asset] = block.timestamp;
        emit BondTermsConfigured(_asset, _controlVariable, _vestingTerm, _maxDebt, _decayLength, _fee);
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _asset asset
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms(
        address _asset,
        PARAMETER _parameter,
        uint256 _input
    ) external permissioned {
        if (_parameter == PARAMETER.VESTING) {
            // 0
            require(_input >= 129600, "Vesting must be longer than 36 hours");
            terms[_asset].vestingTerm = _input;
        } else if (_parameter == PARAMETER.DECAY) {
            // 1
            require(_input >= 1 days, "DAO decay must be greater than 1 day");
            terms[_asset].decayLength = _input;
        } else if (_parameter == PARAMETER.FEE) {
            // 2
            terms[_asset].fee = _input;
        } else if (_parameter == PARAMETER.DEBT) {
            // 3
            terms[_asset].maxDebt = _input;
        } else if (_parameter == PARAMETER.CONTROL) {
            // 4
            terms[_asset].controlVariable = _input;
        }
        emit BondTermsSet(_asset, _parameter, _input);
    }

    /**
     *  @notice deposit bond
     *  @param _asset address
     *  @param _depositor address
     *  @param _priceInUSD uint
     *  @param _payout uint
     */
    function deposit(
        address _asset,
        address _depositor,
        uint256 _priceInUSD,
        uint256 _payout
    ) external permissioned {
        require(acceptedAsset[_asset], "Asset hasn't been added");
        // depositor info is stored
        bondInfo[_depositor][_asset] = Bond({
            payout: bondInfo[_depositor][_asset].payout + _payout,
            vesting: terms[_asset].vestingTerm,
            lastBlockTimestamp: block.timestamp,
            pricePaid: _priceInUSD
        });
        currentDebt[_asset] += _payout;
        emit BondCreated(_asset, _depositor, _payout, block.timestamp + terms[_asset].vestingTerm, _priceInUSD);
    }

    /**
     *  @notice redeem bond for user
     *  @param _asset address
     *  @param _recipient address
     *  @return uint
     */
    function redeem(address _asset, address _recipient) external permissioned returns (uint256) {
        Bond memory info = bondInfo[_recipient][_asset];
        uint256 percentVested = percentVestedFor(_asset, _recipient); // (blocks since last interaction / vesting term remaining)

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[_recipient][_asset]; // delete user info
            emit BondRedeemed(_asset, _recipient, info.payout, 0, 0); // emit bond data
            return info.payout;
        } else {
            uint256 payout = (info.payout * percentVested) / 10000;
            // store updated deposit info
            bondInfo[_recipient][_asset] = Bond({
                payout: info.payout - payout,
                vesting: info.vesting - (block.timestamp - info.lastBlockTimestamp),
                lastBlockTimestamp: block.timestamp,
                pricePaid: info.pricePaid
            });

            emit BondRedeemed(
                _asset,
                _recipient,
                payout,
                bondInfo[_recipient][_asset].payout,
                bondInfo[_recipient][_asset].vesting
            );
            return payout;
        }
    }

    function decayDebt(address _asset) external permissioned {
        Terms memory term = terms[_asset];
        uint256 decay = (term.maxDebt / term.decayLength) * (block.timestamp - lastDecay[_asset]);
        lastDecay[_asset] = block.timestamp;
        if (decay > currentDebt[_asset]) {
            currentDebt[_asset] = 0;
        } else {
            currentDebt[_asset] = currentDebt[_asset] - decay;
        }
    }

    function addAcceptedAsset(address token_) external permissioned {
        require(terms[token_].vestingTerm != 0, "Must have a valid term");
        acceptedAsset[token_] = true;

        emit AssetAdded(token_);
    }

    function removeAcceptedAsset(address token_) external permissioned {
        acceptedAsset[token_] = false;

        emit AssetRemoved(token_);
    }

    /////////////////////////////////////////////////////////////////////////////////
    //                            External Functions                               //
    /////////////////////////////////////////////////////////////////////////////////

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _asset address
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _asset, address _depositor) public view returns (uint256 percentVested_) {
        Bond memory bond = bondInfo[_depositor][_asset];
        uint256 blocksSinceLast = block.timestamp - bond.lastBlockTimestamp;
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = (blocksSinceLast * 10000) / vesting;
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of BOND available for claim by depositor
     *  @param _asset address
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _asset, address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_asset, _depositor);
        uint256 payout = bondInfo[_depositor][_asset].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = (payout * percentVested) / 10000;
        }
    }

    function bondPrice(address _asset, uint256 currentPrice) external view returns (uint256 price_) {
        price_ = currentPrice - ((terms[_asset].controlVariable * currentPrice) / 100000);
    }

    function getTerms(address _asset)
        public
        view
        returns (
            uint256 controlVariable,
            uint256 maxDebt,
            uint256 decayLength,
            uint256 vestingTerm,
            uint256 fee,
            uint256 currentDebt_
        )
    {
        return (
            terms[_asset].controlVariable,
            terms[_asset].maxDebt,
            terms[_asset].decayLength,
            terms[_asset].vestingTerm,
            terms[_asset].fee,
            currentDebt[_asset]
        );
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or BARN) to the DAO
     *  @return bool
     */
    // function recoverLostToken(address _token) external returns (bool) {
    //     require(_token != BARN);
    //     require(_token != principle);
    //     IERC20(_token).safeTransfer(DAO, IERC20(_token).balanceOf(address(this)));
    //     return true;
    // }
}