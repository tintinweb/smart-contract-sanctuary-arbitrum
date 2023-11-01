// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ISolve3Master {
    function initialize(address _signer) external;

    // ============ Views ============

    function getNonce(address _account) external view returns (uint256);

    // ============ Owner Functions ============

    function setSigner(address _account, bool _flag) external;

    function transferOwnership(address _newOwner) external;

    function recoverERC20(address _token) external;

    // ============ EIP 712 Functions ============

    function verifyProof(bytes calldata _proof)
        external
        returns (
            address account,
            uint256 timestamp,
            bool verified
        );
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

import "./Structs.sol";

contract MasterStorage is Structs {

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant PROOFDATA_TYPEHASH =
        keccak256("ProofData(address account,uint256 nonce,uint256 timestamp,address destination)");

    bytes32 DOMAIN_SEPARATOR;

    address public owner;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public signer;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./MasterStorage.sol";
import "./ISolve3Master.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @title Solve3Master
/// @author 0xKurt
/// @notice Solve3 caster contract to verify proofs
contract Solve3Master is ISolve3Master, Initializable, MasterStorage {

    // ============ Initializer ============
    /// @notice Initialize the contract
    /// @param _signer the Solve3 signer address
    function initialize(address _signer) external initializer {
        if (owner != address(0)) revert TransferOwnershipFailed();

        _transferOwnership(msg.sender);
        _setSigner(_signer, true);

        // EIP 712
        // https://eips.ethereum.org/EIPS/eip-712
        DOMAIN_SEPARATOR = _hash(
            EIP712Domain({
                name: "Solve3",
                version: "1",
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    // ============ Views ============

    /// @notice The nonce of an account is used to prevent replay attacks
    /// @param _account the account to get the nonce
    function getNonce(address _account)
        external
        view
        override
        returns (uint256)
    {
        return nonces[_account];
    }

    /// @notice Get the actual timestamp and nonce of an account
    /// @param _account the account to get nonce for
    function getTimestampAndNonce(address _account)
        external
        view
        returns (uint256, uint256)
    {
        return (block.timestamp, nonces[_account]);
    }

    /// @notice Get the signer status of an account
    /// @param _account the account to get signer status for
    function isSigner(address _account) external view returns (bool) {
        return signer[_account];
    }

    // ============ Owner Functions ============

    /// @notice Set the signer status of an account
    /// @param _account The account to set signer status for
    /// @param _flag The signer status to set
    function setSigner(address _account, bool _flag) external {
        _onlyOwner();
        _setSigner(_account, _flag);
    }

    /// @notice Set the signer status of an account
    /// @param _account The account to set signer status for
    /// @param _flag The signer status to set
    function _setSigner(address _account, bool _flag) internal {
        signer[_account] = _flag;
        emit SignerChanged(_account, _flag);
    }

    /// @notice Transfer ownership of the contract
    /// @param _newOwner The new owner of the contract
    function transferOwnership(address _newOwner) external {
        _onlyOwner();
        _transferOwnership(_newOwner);
    }

    /// @notice Transfer ownership of the contract
    /// @param _newOwner The new owner of the contract
    function _transferOwnership(address _newOwner) internal {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /// @notice Recover ERC20 tokens
    /// @param _token The token to recover
    function recoverERC20(address _token) external {
        _onlyOwner();
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, balance);
    }

    // ============ EIP 712 Functions ============

    /// @notice Verify a proof
    /// @param _proof The proof to verify
    /// @return account The account of the proof
    /// @return timestamp The timestamp of the proof
    /// @return verified The verification status of the proof
    function verifyProof(bytes calldata _proof)
        external
        returns (
            address account,
            uint256 timestamp,
            bool verified
        )
    {
        return _verifyProof(_proof);
    }

    /// @notice Verify a proof
    /// @param _proof The proof to verify
    /// @return account The account of the proof
    /// @return timestamp The timestamp of the proof
    /// @return verified The verification status of the proof
    function _verifyProof(bytes calldata _proof)
        internal
        returns (
            address,
            uint256,
            bool
        )
    {
        Proof memory proof = abi.decode(_proof, (Proof));
        ProofData memory proofData = proof.data;
        bool verified;
        address signerAddress;

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _hash(proofData))
        );

        signerAddress = ecrecover(digest, proof.v, proof.r, proof.s);
        
        if (
            nonces[proofData.account] == proofData.nonce &&
            proofData.timestamp < block.timestamp &&
            signer[signerAddress] &&
            msg.sender == proofData.destination
        ) {
            verified = true;
            nonces[proofData.account] += 1;
        } else {
          revert Solve3MasterNotVerified();
        }

        return (proofData.account, proofData.timestamp, verified);
    }

    // ============ Hash Functions ============

    /// @notice Hash the EIP712 domain
    /// @param _eip712Domain The EIP712 domain to hash
    /// @return The hash of the EIP712 domain
    function _hash(EIP712Domain memory _eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(_eip712Domain.name)),
                    keccak256(bytes(_eip712Domain.version)),
                    _eip712Domain.chainId,
                    _eip712Domain.verifyingContract
                )
            );
    }

    /// @notice Hash the proof data
    /// @param _data The proof data to hash
    /// @return The hash of the proof data
    function _hash(ProofData memory _data) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PROOFDATA_TYPEHASH,
                    _data.account,
                    _data.nonce,
                    _data.timestamp,
                    _data.destination
                )
            );
    }

    // ============ Modifier like functions ============

    /// @notice Check if the caller is the owner
    function _onlyOwner() internal view {
        if (msg.sender != owner) revert NotOwner();
    }

    // ============ Errors ============

    error TransferOwnershipFailed();
    error NotOwner();
    error Solve3MasterNotVerified();

    // ============ Events ============

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    event SignerChanged(address indexed account, bool flag);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

interface Structs {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct ProofData {
        address account;
        uint256 nonce;
        uint256 timestamp;
        address destination;
    }

    struct Proof {
        bytes32 s;
        bytes32 r;
        uint8 v;
        ProofData data;
    }
}