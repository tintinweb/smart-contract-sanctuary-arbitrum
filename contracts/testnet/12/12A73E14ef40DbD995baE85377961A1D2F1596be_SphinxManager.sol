// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_MerkleTree
 * @author River Keefer
 */
library Lib_MerkleTree {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying, then
     * this may allow empty leaves past _elements.length to pass a verification check down the line.
     * Note that the _elements argument is modified, therefore it must not be used again afterwards
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(bytes32[] memory _elements) internal pure returns (bytes32) {
        require(_elements.length > 0, "Lib_MerkleTree: Must provide at least one leaf hash.");

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[16] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize; // rowSize / 2
        bool rowSizeIsOdd; // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling = _elements[(2 * i)];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibline nodes in the inclusion proof, starting from depth 0
     * (bottom of the tree).
     * @param _totalLeaves The total number of leaves originally passed into.
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    ) internal pure returns (bool) {
        require(_totalLeaves > 0, "Lib_MerkleTree: Total leaves must be greater than zero.");

        require(_index < _totalLeaves, "Lib_MerkleTree: Index out of bounds.");

        require(
            _siblings.length == _ceilLog2(_totalLeaves),
            "Lib_MerkleTree: Total siblings does not correctly correspond to total leaves."
        );

        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(abi.encodePacked(_siblings[i], computedRoot));
            } else {
                computedRoot = keccak256(abi.encodePacked(computedRoot, _siblings[i]));
            }

            _index >>= 1;
        }

        return _root == computedRoot;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Calculates the integer ceiling of the log base 2 of an input.
     * @param _in Unsigned input to calculate the log.
     * @return ceil(log_base_2(_in))
     */
    function _ceilLog2(uint256 _in) private pure returns (uint256) {
        require(_in > 0, "Lib_MerkleTree: Cannot compute ceil(log_2) of 0.");

        if (_in == 1) {
            return 0;
        }

        // Find the highest set bit (will be floor(log_2)).
        // Borrowed with <3 from https://github.com/ethereum/solidity-examples
        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (((uint256(1) << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }

        // Increment by one if this is not a perfect logarithm.
        if ((uint256(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Version } from "./SphinxDataTypes.sol";

/**
 * @title Semver
 * @notice Semver is a simple contract for managing contract versions.
 */
contract Semver {
    /**
     * @notice Contract version number (major).
     */
    uint256 private immutable MAJOR_VERSION;

    /**
     * @notice Contract version number (minor).
     */
    uint256 private immutable MINOR_VERSION;

    /**
     * @notice Contract version number (patch).
     */
    uint256 private immutable PATCH_VERSION;

    /**
     * @param _major Version number (major).
     * @param _minor Version number (minor).
     * @param _patch Version number (patch).
     */
    constructor(uint256 _major, uint256 _minor, uint256 _patch) {
        MAJOR_VERSION = _major;
        MINOR_VERSION = _minor;
        PATCH_VERSION = _patch;
    }

    /**
     * @notice Returns the full semver contract version.
     *
     * @return Semver contract version as a struct.
     */
    function version() public view returns (Version memory) {
        return Version(MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4 <0.9.0;

/**
 * @notice Struct representing the state of a deployment.
 *
 * @custom:field status The status of the deployment.
 * @custom:field actions An array of actions in the deployment. This is a legacy field that should
   not be used.
 * @custom:field numInitialActions The number of initial actions in the deployment, which are either
 *               `CALL` or `DEPLOY_CONTRACT` actions.
 * @custom:field numSetStorageActions The number of `SET_STORAGE` actions in the deployment.
 * @custom:field targets The number of targets in the deployment.
 * @custom:field actionRoot The root of the Merkle tree of actions.
 * @custom:field targetRoot The root of the Merkle tree of targets.
 * @custom:field numImmutableContracts The number of immutable contracts in the deployment. This is
   a legacy field that should not be used.
 * @custom:field actionsExecuted The number of actions that have been executed so far in the
   deployment.
 * @custom:field timeClaimed The time at which the deployment was claimed by a remote executor.
 * @custom:field selectedExecutor The address of the selected remote executor.
 * @custom:field remoteExecution Whether or not the deployment is being executed remotely.
 * @custom:field configUri URI pointing to the config file for the deployment.
 */
struct DeploymentState {
    DeploymentStatus status;
    bool[] actions;
    uint256 targets;
    bytes32 actionRoot;
    bytes32 targetRoot;
    uint256 numImmutableContracts;
    uint256 actionsExecuted;
    uint256 timeClaimed;
    address selectedExecutor;
    bool remoteExecution;
    string configUri;
    uint256 numInitialActions;
    uint256 numSetStorageActions;
}

/**
 * @notice Struct representing a Sphinx action.
 *
 * @custom:field actionType The type of action.
 * @custom:field index The unique index of the action in the deployment. Actions must be executed in
   ascending order according to their index.
 * @custom:field data The ABI-encoded data associated with the action.
 */
struct RawSphinxAction {
    SphinxActionType actionType;
    uint256 index;
    bytes data;
}

/**
 * @notice Struct representing a target.
 *
 * @custom:field addr The address of the proxy associated with this target.
 * @custom:field implementation The address that will be the proxy's implementation at the end of
   the deployment.
 * @custom:field contractKindHash The hash of the contract kind associated with this contract.
 */
struct SphinxTarget {
    address payable addr;
    address implementation;
    bytes32 contractKindHash;
}

/**
 * @notice Enum representing possible action types.
 *
 * @custom:value SET_STORAGE Set a storage slot value in a proxy contract.
 * @custom:value DEPLOY_CONTRACT Deploy a contract.
 * @custom:value CALL Execute a low-level call on an address.
 */
enum SphinxActionType {
    SET_STORAGE,
    DEPLOY_CONTRACT,
    CALL
}

/**
 * @notice Enum representing the status of the deployment. These steps occur in sequential order,
   with the `CANCELLED` status being an exception.
 *
 * @custom:value EMPTY The deployment does not exist.
 * @custom:value APPROVED The deployment has been approved by the owner.
 * @custom:value INITIAL_ACTIONS_EXECUTED The initial `DEPLOY_CONTRACT` and `CALL` actions in the
   deployment have been executed.
 * @custom:value PROXIES_INITIATED The proxies in the deployment have been initiated.
 * @custom:value SET_STORAGE_ACTIONS_EXECUTED The `SET_STORAGE` actions in the deployment have been
                 executed.
 * @custom:value COMPLETED The deployment has been completed.
 * @custom:value CANCELLED The deployment has been cancelled.
 * @custom:value FAILED The deployment has failed. This is deprecated as we no longer allow
 *               deployments to silently fail.
 */
enum DeploymentStatus {
    EMPTY,
    APPROVED,
    PROXIES_INITIATED,
    COMPLETED,
    CANCELLED,
    FAILED,
    INITIAL_ACTIONS_EXECUTED,
    SET_STORAGE_ACTIONS_EXECUTED
}

/**
 * @notice Version number as a struct.
 *
 * @custom:field major Major version number.
 * @custom:field minor Minor version number.
 * @custom:field patch Patch version number.
 */
struct Version {
    uint256 major;
    uint256 minor;
    uint256 patch;
}

struct RegistrationInfo {
    Version version;
    address owner;
    bytes managerInitializerData;
}

/**
 * @notice Struct representing a leaf in an auth Merkle tree. This represents an arbitrary
   authenticated action taken by a permissioned account such as an owner or proposer.
 *
 * @custom:field chainId The chain ID for the leaf to be executed on.
 * @custom:field to The address that is the subject of the data in this leaf. This should always be
                 a SphinxManager.
 * @custom:field index The index of the leaf. Each index must be unique on a chain, and start from
                 zero. Leafs must be executed in ascending order according to their index. This
                 makes it possible to ensure that leafs in an Auth tree will be executed in a
                 certain order, e.g. creating a proposal then approving it.
 */
struct AuthLeaf {
    uint256 chainId;
    address to;
    uint256 index;
    bytes data;
}

/**
 * @notice Struct representing the state of an auth Merkle tree.
 *
 * @custom:field status The status of the auth Merkle tree.
 * @custom:field leafsExecuted The number of auth leafs that have been executed.
 * @custom:field numLeafs The total number of leafs in the auth Merkle tree on a chain.
 */
struct AuthState {
    AuthStatus status;
    uint256 leafsExecuted;
    uint256 numLeafs;
}

enum AuthStatus {
    EMPTY,
    SETUP,
    PROPOSED,
    COMPLETED
}

struct SetRoleMember {
    address member;
    bool add;
}

struct DeploymentApproval {
    bytes32 actionRoot;
    bytes32 targetRoot;
    uint256 numInitialActions;
    uint256 numSetStorageActions;
    uint256 numTargets;
    string configUri;
}

enum AuthLeafType {
    SETUP,
    PROPOSE,
    EXPORT_PROXY,
    SET_OWNER,
    SET_THRESHOLD,
    TRANSFER_MANAGER_OWNERSHIP,
    UPGRADE_MANAGER_IMPLEMENTATION,
    UPGRADE_AUTH_IMPLEMENTATION,
    UPGRADE_MANAGER_AND_AUTH_IMPL,
    SET_PROPOSER,
    APPROVE_DEPLOYMENT,
    CANCEL_ACTIVE_DEPLOYMENT
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {
    DeploymentState,
    RawSphinxAction,
    SphinxTarget,
    SphinxActionType,
    DeploymentStatus
} from "./SphinxDataTypes.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ISphinxRegistry } from "./interfaces/ISphinxRegistry.sol";
import { ISphinxManager } from "./interfaces/ISphinxManager.sol";
import { IProxyAdapter } from "./interfaces/IProxyAdapter.sol";
import {
    Lib_MerkleTree as MerkleTree
} from "@eth-optimism/contracts/libraries/utils/Lib_MerkleTree.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ICreate3 } from "./interfaces/ICreate3.sol";
import { Semver, Version } from "./Semver.sol";
import {
    ContextUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { SphinxManagerEvents } from "./SphinxManagerEvents.sol";

/**
 * @title SphinxManager
 * @custom:version 0.2.4
 * @notice This contract contains the logic for managing the entire lifecycle of a project's
 *         deployments. It contains the functionality for approving and executing deployments and
 *         exporting proxies out of the Sphinx system if desired. It exists as a single
 *         implementation contract behind SphinxManagerProxy contracts, which are each owned by a
 *         single project team.
 *
 *         After a deployment is approved, it is executed in the following steps, which must occur
 *         in order:
 *         1. The `executeInitialActions` function: `DEPLOY_CONTRACT` and `CALL` actions are
 *            executed in ascending order according to their index.
 *         The next steps only occur if the deployment is upgrading proxies.
 *         2. The `initiateProxies` function: sets the implementation of each proxy to a contract
 *            that can only be called by the user's SphinxManager. This ensures that the upgrade is
 *            atomic, which means that all proxies are upgraded in a single transaction.
 *         3. Execute all of the `SET_STORAGE` actions using the `executeActions` function.
 *         4. The `completeUpgrade` function, which upgrades all of the proxies to their new
 *            implementations in a single transaction.
 */
contract SphinxManager is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Semver,
    ISphinxManager,
    SphinxManagerEvents
{
    /**
     * @notice Role required to be a remote executor for a deployment.
     */
    bytes32 internal constant REMOTE_EXECUTOR_ROLE = keccak256("REMOTE_EXECUTOR_ROLE");

    /**
     * @notice The contract kind hash for immutable contracts. This does not include
     *         implementation contracts that exist behind proxies.
     */
    bytes32 internal constant IMMUTABLE_CONTRACT_KIND_HASH = keccak256("immutable");

    /**
     * @notice The contract kind hash for implementation contracts, which exist behind proxies.
     */
    bytes32 internal constant IMPLEMENTATION_CONTRACT_KIND_HASH = keccak256("implementation");

    /**
     * @notice Address of the SphinxRegistry.
     */
    ISphinxRegistry public immutable registry;

    string public projectName;

    /**
     * @notice Address of the Create3 contract.
     */
    address internal immutable create3;

    /**
     * @notice Address of the ManagedService contract.
     */
    IAccessControl internal immutable managedService;

    /**
     * @notice Amount of time for a remote executor to finish executing a deployment once they have
       claimed it.
     */
    uint256 internal immutable executionLockTime;

    /**
     * @notice Mapping of deployment IDs to deployment state.
     */
    mapping(bytes32 => DeploymentState) private _deployments;

    /**
     * @notice ID of the currently active deployment.
     */
    bytes32 public activeDeploymentId;

    /**
     * @notice Mapping of call hashes to nonces. A call hash is the hash of the address and calldata
       of a `CALL` action. The nonce is incremented each time the call is executed. This makes it
       easy for off-chain code to keep track of which calls to skip if a deployment is re-executed.
       Although this same functionality could be achieved using events, we opt for a mapping because
       some chains make it difficult to query events that occurred past a certain block.
     */
    mapping(bytes32 => uint256) public callNonces;

    /**
     * @notice Reverts if the caller is not a remote executor.
     */
    error CallerIsNotRemoteExecutor();

    /**
     * @notice Reverts if the deployment state cannot be approved.
     */
    error DeploymentStateIsNotApprovable();

    /**
     * @notice Reverts if there is another active deployment ID.
     */
    error DeploymentInProgress();

    /**
     * @notice Reverts if there is currently no active deployment ID.
     */
    error NoActiveDeployment();

    /**
     * @notice Reverts if a deployment can only be self-executed by the owner.
     */
    error RemoteExecutionDisabled();

    /**
     * @notice Reverts if the deployment has already been claimed by another remote executor.
     */
    error DeploymentAlreadyClaimed();

    /**
     * @notice Reverts if there is no bytecode at a given address.
     */
    error ContractDoesNotExist();

    /**
     * @notice Reverts if an invalid contract kind is provided.
     */
    error InvalidContractKind();

    /**
     * @notice Reverts if the call to export ownership of a proxy from this contract fails.
     */
    error ProxyExportFailed();

    /**
     * @notice Reverts if an empty actions array is provided as input to the transaction.
     */
    error EmptyActionsArray();

    /**
     * @notice Reverts if the action has already been executed in this deployment.
     */
    error ActionAlreadyExecuted();

    /**
     * @notice Reverts if an invalid Merkle proof is provided.
     */
    error InvalidMerkleProof();

    /**
     * @notice Reverts if the action type is not `DEPLOY_CONTRACT` or `SET_STORAGE`.
     */
    error InvalidActionType();

    /**
     * @notice Reverts if an action is executed out of order.
     */
    error InvalidActionIndex();

    /**
     * @notice Reverts if the provided number of targets does not match the actual number of targets
       in the deployment.
     */
    error IncorrectNumberOfTargets();

    /**
     * @notice Reverts if a non-proxy contract type is used instead of a proxy type.
     */
    error OnlyProxiesAllowed();

    /**
     * @notice Reverts if the call to initiate an upgrade on a proxy fails.
     */
    error FailedToInitiateUpgrade();

    /**
     * @notice Reverts if an upgrade is completed before all of the actions have been executed.
     */
    error FinalizedUpgradeTooEarly();

    /**
     * @notice Reverts if the call to finalize an upgrade on a proxy fails.
     */
    error FailedToFinalizeUpgrade();

    /**
     * @notice Reverts if a function is called in an incorrect order during the deployment
     *        process.
     */
    error InvalidDeploymentStatus();

    /**
     * @notice Reverts if the call to modify a proxy's storage slot value fails.
     */
    error SetStorageFailed();

    /**
     * @notice Reverts if the caller is not a selected executor.
     */
    error CallerIsNotSelectedExecutor();

    /**
     * @notice Reverts if the caller is not the owner.
     */
    error CallerIsNotOwner();

    /**
     * @notice Reverts if the low-level delegatecall to get an address fails.
     */
    error FailedToGetAddress();

    error EmptyProjectName();
    error ProjectNameCannotBeEmpty();
    error InvalidAddress();

    /**
     * @notice Reverts if the deployment fails due to an error in a contract constructor
     *         or call.
     * @param deploymentId ID of the deployment that failed.
     * @param actionIndex  Index of the action that caused the deployment to fail.
     */
    error DeploymentFailed(uint256 actionIndex, bytes32 deploymentId);

    /**
     * @notice Modifier that reverts if the caller is not a remote executor.
     */
    modifier onlyExecutor() {
        if (!managedService.hasRole(REMOTE_EXECUTOR_ROLE, msg.sender)) {
            revert CallerIsNotRemoteExecutor();
        }
        _;
    }

    /**
     * @param _registry                  Address of the SphinxRegistry.
     * @param _create3                   Address of the Create3 contract.
     * @param _managedService            Address of the ManagedService contract.
     * @param _executionLockTime         Amount of time for a remote executor to completely execute
       a deployment after claiming it.
     * @param _version                   Version of this contract.
     */
    constructor(
        ISphinxRegistry _registry,
        address _create3,
        IAccessControl _managedService,
        uint256 _executionLockTime,
        Version memory _version
    ) Semver(_version.major, _version.minor, _version.patch) {
        registry = _registry;
        create3 = _create3;
        managedService = _managedService;
        executionLockTime = _executionLockTime;

        _disableInitializers();
    }

    /**
     * @inheritdoc ISphinxManager

     * @return Empty bytes.
     */
    function initialize(
        address _owner,
        string memory _projectName,
        bytes memory
    ) external initializer returns (bytes memory) {
        if (bytes(_projectName).length == 0) revert EmptyProjectName();

        projectName = _projectName;

        __ReentrancyGuard_init();
        __Ownable_init();
        _transferOwnership(_owner);

        return "";
    }

    /**
     * @notice Approve a deployment. Only callable by the owner of this contract.
     *
     * @param _actionRoot Root of the Merkle tree containing the actions for the deployment.
     * This may be `bytes32(0)` if there are no actions in the deployment.
     * @param _targetRoot Root of the Merkle tree containing the targets for the deployment.
     * This may be `bytes32(0)` if there are no targets in the deployment.
     * @param _numInitialActions Number of `DEPLOY_CONTRACT` and `CALL` actions in the deployment.
     * @param _numTargets Number of targets in the deployment.
     * @param _configUri  URI pointing to the config file for the deployment.
     * @param _remoteExecution Whether or not to allow remote execution of the deployment.
     */
    function approve(
        bytes32 _actionRoot,
        bytes32 _targetRoot,
        uint256 _numInitialActions,
        uint256 _numSetStorageActions,
        uint256 _numTargets,
        string memory _configUri,
        bool _remoteExecution
    ) public onlyOwner {
        if (activeDeploymentId != bytes32(0)) {
            revert DeploymentInProgress();
        }

        // Compute the deployment ID.
        bytes32 deploymentId = keccak256(
            abi.encode(
                _actionRoot,
                _targetRoot,
                _numInitialActions,
                _numSetStorageActions,
                _numTargets,
                _configUri
            )
        );

        DeploymentState storage deployment = _deployments[deploymentId];

        DeploymentStatus status = deployment.status;
        if (
            status != DeploymentStatus.EMPTY &&
            status != DeploymentStatus.COMPLETED &&
            status != DeploymentStatus.CANCELLED
        ) {
            revert DeploymentStateIsNotApprovable();
        }

        activeDeploymentId = deploymentId;

        deployment.status = DeploymentStatus.APPROVED;
        deployment.actionRoot = _actionRoot;
        deployment.targetRoot = _targetRoot;
        deployment.numInitialActions = _numInitialActions;
        deployment.numSetStorageActions = _numSetStorageActions;
        deployment.targets = _numTargets;
        deployment.remoteExecution = _remoteExecution;
        deployment.configUri = _configUri;

        emit SphinxDeploymentApproved(
            deploymentId,
            _actionRoot,
            _targetRoot,
            _numInitialActions,
            _numSetStorageActions,
            _numTargets,
            _configUri,
            _remoteExecution,
            msg.sender
        );
        registry.announceWithData("SphinxDeploymentApproved", abi.encodePacked(msg.sender));
    }

    /**
     * @notice Helper function that executes an entire upgrade in a single transaction. This allows
       the proxies in smaller upgrades to have zero downtime. This must occur after all of the
       initial `DEPLOY_CONTRACT` and `CALL` actions have been executed.
     */
    function executeEntireUpgrade(
        SphinxTarget[] memory _targets,
        bytes32[][] memory _targetProofs,
        RawSphinxAction[] memory _setStorageActions,
        bytes32[][] memory _setStorageProofs
    ) external {
        initiateUpgrade(_targets, _targetProofs);

        // Execute the `SET_STORAGE` actions if there are any.
        if (_setStorageActions.length > 0) {
            setStorage(_setStorageActions, _setStorageProofs);
        }

        finalizeUpgrade(_targets, _targetProofs);
    }

    /**
     * @notice **WARNING**: Cancellation is a potentially dangerous action and should not be
     *         executed unless in an emergency.
     *
     *         Allows the owner to cancel an active deployment that was approved.
     */
    function cancelActiveSphinxDeployment() external onlyOwner {
        if (activeDeploymentId == bytes32(0)) {
            revert NoActiveDeployment();
        }

        DeploymentState storage deployment = _deployments[activeDeploymentId];

        bytes32 cancelledDeploymentId = activeDeploymentId;
        activeDeploymentId = bytes32(0);
        deployment.status = DeploymentStatus.CANCELLED;

        emit SphinxDeploymentCancelled(
            cancelledDeploymentId,
            msg.sender,
            deployment.actionsExecuted
        );
        registry.announce("SphinxDeploymentCancelled");
    }

    /**
     * @notice Allows a remote executor to claim the sole right to execute a deployment over a
               period of `executionLockTime`. Executors must finish executing the deployment within
               `executionLockTime` or else another executor may claim the deployment.
     */
    function claimDeployment() external onlyExecutor {
        if (activeDeploymentId == bytes32(0)) {
            revert NoActiveDeployment();
        }

        DeploymentState storage deployment = _deployments[activeDeploymentId];

        if (!deployment.remoteExecution) {
            revert RemoteExecutionDisabled();
        }

        if (block.timestamp <= deployment.timeClaimed + executionLockTime) {
            revert DeploymentAlreadyClaimed();
        }

        deployment.timeClaimed = block.timestamp;
        deployment.selectedExecutor = msg.sender;

        emit SphinxDeploymentClaimed(activeDeploymentId, msg.sender);
        registry.announce("SphinxDeploymentClaimed");
    }

    /**
     * @notice Transfers ownership of a proxy away from this contract to a specified address. Only
       callable by the owner. Note that this function allows the owner to send ownership of their
       proxy to address(0), which would make their proxy non-upgradeable.
     *
     * @param _proxy  Address of the proxy to transfer ownership of.
     * @param _contractKindHash  Hash of the contract kind, which represents the proxy type.
     * @param _newOwner  Address of the owner to receive ownership of the proxy.
     */
    function exportProxy(
        address payable _proxy,
        bytes32 _contractKindHash,
        address _newOwner
    ) external onlyOwner {
        if (_proxy.code.length == 0) {
            revert ContractDoesNotExist();
        }

        if (activeDeploymentId != bytes32(0)) {
            revert DeploymentInProgress();
        }

        // Get the adapter that corresponds to this contract type.
        address adapter = registry.adapters(_contractKindHash);
        if (adapter == address(0)) {
            revert InvalidContractKind();
        }

        emit ProxyExported(_proxy, _contractKindHash, _newOwner);

        // Delegatecall the adapter to change ownership of the proxy.
        // slither-disable-next-line controlled-delegatecall
        (bool success, ) = adapter.delegatecall(
            abi.encodeCall(IProxyAdapter.changeProxyAdmin, (_proxy, _newOwner))
        );
        if (!success) {
            revert ProxyExportFailed();
        }

        registry.announce("ProxyExported");
    }

    function transferOwnership(address _newOwner) public override onlyOwner {
        if (_newOwner == address(0)) revert InvalidAddress();
        _transferOwnership(_newOwner);
        registry.announceWithData("OwnershipTransferred", abi.encodePacked(_newOwner));
    }

    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
        registry.announceWithData("OwnershipTransferred", abi.encodePacked(address(0)));
    }

    /**
     * @notice Gets the DeploymentState struct for a given deployment ID. Note that we explicitly
     *         define this function because the getter function auto-generated by Solidity doesn't
     *         return array members of structs: https://github.com/ethereum/solidity/issues/12792.
     *         If we remove this function and make the `_deployments` mapping public, we will get a
     *         compilation error for this reason.
     *
     * @param _deploymentId Deployment ID.
     *
     * @return DeploymentState struct.
     */
    function deployments(bytes32 _deploymentId) external view returns (DeploymentState memory) {
        return _deployments[_deploymentId];
    }

    /**
     * @inheritdoc ISphinxManager
     */
    function isExecuting() external view returns (bool) {
        return activeDeploymentId != bytes32(0);
    }

    /**
     * @notice Deploys contracts and executes arbitrary calls in a deployment. This must be called
     *         after the deployment is approved. A contract deployment will be skipped if a contract
     *         already exists at its CREATE3 address. If a contract deployment or call fails, the
     *         entire deployment will be marked as `FAILED` and no further actions will be executed.
     *
     * @param _actions The `DEPLOY_CONTRACT` and `CALL` actions to execute.
     * @param _proofs The Merkle proofs for the actions.
     */
    function executeInitialActions(
        RawSphinxAction[] memory _actions,
        bytes32[][] memory _proofs
    ) public nonReentrant {
        DeploymentState storage deployment = _deployments[activeDeploymentId];
        if (deployment.status != DeploymentStatus.APPROVED) revert InvalidDeploymentStatus();

        _assertCallerIsOwnerOrSelectedExecutor(deployment.remoteExecution);

        uint256 numActions = _actions.length;
        uint256 numTotalActions = deployment.numInitialActions + deployment.numSetStorageActions;

        // Prevents the executor from repeatedly sending an empty array of `_actions`, which would
        // cause the executor to be paid for doing nothing.
        if (numActions == 0) {
            revert EmptyActionsArray();
        }

        RawSphinxAction memory action;
        bytes32[] memory proof;
        for (uint256 i = 0; i < numActions; i++) {
            action = _actions[i];
            proof = _proofs[i];

            if (deployment.actionsExecuted != action.index) {
                revert InvalidActionIndex();
            }

            if (
                !MerkleTree.verify(
                    deployment.actionRoot,
                    keccak256(abi.encode(action.actionType, action.data)),
                    action.index,
                    proof,
                    numTotalActions
                )
            ) {
                revert InvalidMerkleProof();
            }

            deployment.actionsExecuted++;

            if (action.actionType == SphinxActionType.CALL) {
                (uint256 nonce, address to, bytes memory data) = abi.decode(
                    action.data,
                    (uint256, address, bytes)
                );
                bytes32 callHash = keccak256(abi.encode(to, data));
                uint256 currentNonce = callNonces[callHash];
                if (nonce != currentNonce) {
                    emit CallSkipped(activeDeploymentId, action.index);
                    registry.announce("CallSkipped");
                } else {
                    (bool success, ) = to.call(data);
                    if (success) {
                        callNonces[callHash] = currentNonce + 1;
                        emit CallExecuted(activeDeploymentId, callHash, action.index);
                        registry.announce("CallExecuted");
                    } else {
                        // External call failed. Could happen if insufficient gas is supplied
                        // to this transaction or if the function has logic that causes the call to
                        // fail.
                        revert DeploymentFailed(action.index, activeDeploymentId);
                    }
                }
            } else if (action.actionType == SphinxActionType.DEPLOY_CONTRACT) {
                (bytes32 salt, bytes memory creationCodeWithConstructorArgs) = abi.decode(
                    action.data,
                    (bytes32, bytes)
                );

                address expectedAddress = ICreate3(create3).getAddressFromDeployer(
                    salt,
                    address(this)
                );

                // Check if the contract has already been deployed.
                if (expectedAddress.code.length > 0) {
                    // Skip deploying the contract if it already exists. Execution would halt if
                    // we attempt to deploy a contract that has already been deployed at the same
                    // address.
                    emit ContractDeploymentSkipped(
                        expectedAddress,
                        activeDeploymentId,
                        action.index
                    );
                    registry.announce("ContractDeploymentSkipped");
                } else {
                    // We delegatecall the Create3 contract so that the SphinxManager address is
                    // used in the address calculation of the deployed contract. If we call the
                    // Create3 contract instead of delegatecalling it, it'd be possible for an
                    // attacker to deploy a malicious contract at the expected address by calling
                    // the `deploy` function on the Create3 contract directly.
                    (bool deploySuccess, ) = create3.delegatecall(
                        abi.encodeCall(ICreate3.deploy, (salt, creationCodeWithConstructorArgs, 0))
                    );

                    if (deploySuccess) {
                        emit ContractDeployed(
                            expectedAddress,
                            activeDeploymentId,
                            keccak256(creationCodeWithConstructorArgs)
                        );
                        registry.announce("ContractDeployed");
                    } else {
                        // Contract deployment failed. Could happen if insufficient gas is supplied
                        // to this transaction or if the creation bytecode has logic that causes the
                        // call to fail (e.g. a constructor that reverts).
                        revert DeploymentFailed(action.index, activeDeploymentId);
                    }
                }
            } else {
                revert InvalidActionType();
            }
        }

        // If all of the actions have been executed, mark the deployment as completed. This will
        // always be the case unless the deployment is upgrading proxies.
        if (deployment.actionsExecuted == deployment.numInitialActions) {
            if (deployment.targets == 0) {
                _completeDeployment(deployment);
            } else {
                deployment.status = DeploymentStatus.INITIAL_ACTIONS_EXECUTED;
            }
        }
    }

    /**
     * @notice Initiate the proxies in an upgrade. This must be called after the contracts are
       deployment is approved, and before the rest of the execution process occurs. In this
       function, all of the proxies in the deployment are disabled by setting their implementations
       to a contract that can only be called by the team's SphinxManagerProxy. This must occur
       in a single transaction to make the process atomic, which means the proxies are upgraded as a
       single unit.

     * @param _targets Array of SphinxTarget structs containing the targets for the deployment.
     * @param _proofs Array of Merkle proofs for the targets.
     */
    function initiateUpgrade(
        SphinxTarget[] memory _targets,
        bytes32[][] memory _proofs
    ) public nonReentrant {
        DeploymentState storage deployment = _deployments[activeDeploymentId];

        _assertCallerIsOwnerOrSelectedExecutor(deployment.remoteExecution);

        if (deployment.status != DeploymentStatus.INITIAL_ACTIONS_EXECUTED)
            revert InvalidDeploymentStatus();

        uint256 numTargets = _targets.length;
        if (numTargets != deployment.targets) {
            revert IncorrectNumberOfTargets();
        }

        SphinxTarget memory target;
        bytes32[] memory proof;
        for (uint256 i = 0; i < numTargets; i++) {
            target = _targets[i];
            proof = _proofs[i];

            if (
                target.contractKindHash == IMMUTABLE_CONTRACT_KIND_HASH ||
                target.contractKindHash == IMPLEMENTATION_CONTRACT_KIND_HASH
            ) {
                revert OnlyProxiesAllowed();
            }

            if (
                !MerkleTree.verify(
                    deployment.targetRoot,
                    keccak256(
                        abi.encode(target.addr, target.implementation, target.contractKindHash)
                    ),
                    i,
                    proof,
                    deployment.targets
                )
            ) {
                revert InvalidMerkleProof();
            }

            address adapter = registry.adapters(target.contractKindHash);
            if (adapter == address(0)) {
                revert InvalidContractKind();
            }

            // Set the proxy's implementation to be a ProxyUpdater. Updaters ensure that only the
            // SphinxManager can interact with a proxy that is in the process of being updated.
            // Note that we use the Updater contract to provide a generic interface for updating a
            // variety of proxy types. Note no adapter is necessary for non-proxied contracts as
            // they are not upgradable and cannot have state.
            // slither-disable-next-line controlled-delegatecall
            (bool success, ) = adapter.delegatecall(
                abi.encodeCall(IProxyAdapter.initiateUpgrade, (target.addr))
            );
            if (!success) {
                revert FailedToInitiateUpgrade();
            }
        }

        // Mark the deployment as initiated.
        deployment.status = DeploymentStatus.PROXIES_INITIATED;

        emit ProxiesInitiated(activeDeploymentId, msg.sender);
        registry.announce("ProxiesInitiated");
    }

    /**
     * @notice Sets storage values within proxies to upgrade them. Must be called after
     *         the `initiateProxies` function.
     *
     * @param _actions The `SET_STORAGE` actions to execute.
     * @param _proofs The Merkle proofs for the actions.
     */
    function setStorage(
        RawSphinxAction[] memory _actions,
        bytes32[][] memory _proofs
    ) public nonReentrant {
        DeploymentState storage deployment = _deployments[activeDeploymentId];
        if (deployment.status != DeploymentStatus.PROXIES_INITIATED)
            revert InvalidDeploymentStatus();

        _assertCallerIsOwnerOrSelectedExecutor(deployment.remoteExecution);

        uint256 numActions = _actions.length;
        uint256 numTotalActions = deployment.numInitialActions + deployment.numSetStorageActions;

        // Prevents the executor from repeatedly sending an empty array of `_actions`, which would
        // cause the executor to be paid for doing nothing.
        if (numActions == 0) {
            revert EmptyActionsArray();
        }

        RawSphinxAction memory action;
        bytes32[] memory proof;
        for (uint256 i = 0; i < numActions; i++) {
            action = _actions[i];
            proof = _proofs[i];

            if (deployment.actionsExecuted != action.index) {
                revert InvalidActionIndex();
            }
            if (action.actionType != SphinxActionType.SET_STORAGE) revert InvalidActionType();

            if (
                !MerkleTree.verify(
                    deployment.actionRoot,
                    keccak256(abi.encode(action.actionType, action.data)),
                    action.index,
                    proof,
                    numTotalActions
                )
            ) {
                revert InvalidMerkleProof();
            }

            deployment.actionsExecuted++;

            (
                bytes32 contractKindHash,
                address to,
                bytes32 key,
                uint8 offset,
                bytes memory val
            ) = abi.decode(action.data, (bytes32, address, bytes32, uint8, bytes));

            if (
                contractKindHash == IMMUTABLE_CONTRACT_KIND_HASH ||
                contractKindHash == IMPLEMENTATION_CONTRACT_KIND_HASH
            ) {
                revert OnlyProxiesAllowed();
            }

            // Get the adapter for this reference name.
            address adapter = registry.adapters(contractKindHash);

            // Delegatecall the adapter to call `setStorage` on the proxy.
            // slither-disable-next-line controlled-delegatecall
            (bool success, ) = adapter.delegatecall(
                abi.encodeCall(IProxyAdapter.setStorage, (payable(to), key, offset, val))
            );
            if (!success) {
                revert SetStorageFailed();
            }

            emit SetProxyStorage(activeDeploymentId, to, msg.sender, action.index);
            registry.announce("SetProxyStorage");
        }

        if (deployment.actionsExecuted == numTotalActions) {
            deployment.status = DeploymentStatus.SET_STORAGE_ACTIONS_EXECUTED;
        }
    }

    /**
     * @notice Finalizes the upgrade by upgrading all proxies to their new implementations. This
     *         occurs in a single transaction to ensure that the upgrade is atomic.
     *
     * @param _targets Array of SphinxTarget structs containing the targets for the deployment.
     * @param _proofs Array of Merkle proofs for the targets.
     */
    function finalizeUpgrade(
        SphinxTarget[] memory _targets,
        bytes32[][] memory _proofs
    ) public nonReentrant {
        DeploymentState storage deployment = _deployments[activeDeploymentId];

        _assertCallerIsOwnerOrSelectedExecutor(deployment.remoteExecution);

        if (deployment.status != DeploymentStatus.SET_STORAGE_ACTIONS_EXECUTED)
            revert InvalidDeploymentStatus();

        uint256 numTargets = _targets.length;
        if (numTargets != deployment.targets) {
            revert IncorrectNumberOfTargets();
        }

        SphinxTarget memory target;
        bytes32[] memory proof;
        for (uint256 i = 0; i < numTargets; i++) {
            target = _targets[i];
            proof = _proofs[i];

            if (
                target.contractKindHash == IMMUTABLE_CONTRACT_KIND_HASH ||
                target.contractKindHash == IMPLEMENTATION_CONTRACT_KIND_HASH
            ) {
                revert OnlyProxiesAllowed();
            }

            if (
                !MerkleTree.verify(
                    deployment.targetRoot,
                    keccak256(
                        abi.encode(target.addr, target.implementation, target.contractKindHash)
                    ),
                    i,
                    proof,
                    deployment.targets
                )
            ) {
                revert InvalidMerkleProof();
            }

            // Get the proxy type and adapter for this reference name.
            address adapter = registry.adapters(target.contractKindHash);
            if (adapter == address(0)) {
                revert InvalidContractKind();
            }

            // Upgrade the proxy's implementation contract.
            (bool success, ) = adapter.delegatecall(
                abi.encodeCall(IProxyAdapter.finalizeUpgrade, (target.addr, target.implementation))
            );
            if (!success) {
                revert FailedToFinalizeUpgrade();
            }

            emit ProxyUpgraded(activeDeploymentId, target.addr);
            registry.announceWithData("ProxyUpgraded", abi.encodePacked(target.addr));
        }

        _completeDeployment(deployment);
    }

    /**
     * @notice Queries the selected executor for a given project/deployment. This will return
       address(0) if the deployment is being self-executed by the owner.
     *
     * @param _deploymentId ID of the deployment to query.
     *
     * @return Address of the selected executor.
     */
    function getSelectedExecutor(bytes32 _deploymentId) public view returns (address) {
        DeploymentState storage deployment = _deployments[_deploymentId];
        return deployment.selectedExecutor;
    }

    /**
     * @notice Mark the deployment as completed and reset the active deployment ID.

     * @param _deployment The current deployment state struct. The data location is "s  rage"
       because we modify the struct.
     */
    function _completeDeployment(DeploymentState storage _deployment) private {
        _deployment.status = DeploymentStatus.COMPLETED;

        emit SphinxDeploymentCompleted(activeDeploymentId, msg.sender);
        registry.announce("SphinxDeploymentCompleted");

        activeDeploymentId = bytes32(0);
    }

    /**
     * @notice If the deployment is being executed remotely, this function will check that the
     * caller is the selected executor. If the deployment is being executed locally, this function
     * will check that the caller is the owner. Throws an error otherwise.

       @param _remoteExecution True if the deployment is being executed remotely, otherwise false.

     */
    function _assertCallerIsOwnerOrSelectedExecutor(bool _remoteExecution) internal view {
        if (_remoteExecution == true && getSelectedExecutor(activeDeploymentId) != msg.sender) {
            revert CallerIsNotSelectedExecutor();
        } else if (_remoteExecution == false && owner() != msg.sender) {
            revert CallerIsNotOwner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SphinxManagerEvents {
    /**
     * @notice Emitted when a deployment is approved.

     * @param deploymentId   ID of the deployment that was approved.
     * @param actionRoot   Root of the Merkle tree containing the actions for the deployment.
     * @param targetRoot   Root of the Merkle tree containing the targets for the deployment.
     * @param numInitialActions   Number of initial `CALL` or `DEPLOY_CONTRACT` actions in the
       deployment, which must occur before an upgrade is initiated (if applicable).
     * @param numSetStorageActions   Number of `SET_STORAGE` actions in the deployment.
     * @param numTargets   Number of targets in the deployment.
     * @param configUri  URI of the config file that can be used to fetch the deployment.
     * @param remoteExecution Boolean indicating if the deployment should be remotely executed.
     * @param approver     Address of the account that approved the deployment.
     */
    event SphinxDeploymentApproved(
        bytes32 indexed deploymentId,
        bytes32 actionRoot,
        bytes32 targetRoot,
        uint256 numInitialActions,
        uint256 numSetStorageActions,
        uint256 numTargets,
        string configUri,
        bool remoteExecution,
        address approver
    );

    /**
     * @notice Emitted when a storage slot in a proxy is modified.
     *
     * @param deploymentId Current deployment ID.
     * @param proxy        Address of the proxy.
     * @param executor Address of the caller for this transaction.
     * @param actionIndex Index of this action.
     */
    event SetProxyStorage(
        bytes32 indexed deploymentId,
        address indexed proxy,
        address indexed executor,
        uint256 actionIndex
    );

    /**
     * @notice Emitted when a deployment is initiated.
     *
     * @param deploymentId   ID of the active deployment.
     * @param executor        Address of the caller that initiated the deployment.
     */
    event ProxiesInitiated(bytes32 indexed deploymentId, address indexed executor);

    event ProxyUpgraded(bytes32 indexed deploymentId, address indexed proxy);

    /**
     * @notice Emitted when a deployment is completed.
     *
     * @param deploymentId   ID of the active deployment.
     * @param executor        Address of the caller that initiated the deployment.
     */
    event SphinxDeploymentCompleted(bytes32 indexed deploymentId, address indexed executor);

    /**
     * @notice Emitted when the owner of this contract cancels an active deployment.
     *
     * @param deploymentId        Deployment ID that was cancelled.
     * @param owner           Address of the owner that cancelled the deployment.
     * @param actionsExecuted Total number of completed actions before cancellation.
     */
    event SphinxDeploymentCancelled(
        bytes32 indexed deploymentId,
        address indexed owner,
        uint256 actionsExecuted
    );

    /**
     * @notice Emitted when ownership of a proxy is transferred away from this contract.
     *
     * @param proxy            Address of the proxy that was exported.
     * @param contractKindHash The proxy's contract kind hash, which indicates the proxy's type.
     * @param newOwner         Address of the new owner of the proxy.
     */
    event ProxyExported(address indexed proxy, bytes32 indexed contractKindHash, address newOwner);

    /**
     * @notice Emitted when a deployment is claimed by a remote executor.
     *
     * @param deploymentId ID of the deployment that was claimed.
     * @param executor Address of the executor that claimed the deployment.
     */
    event SphinxDeploymentClaimed(bytes32 indexed deploymentId, address indexed executor);

    /**
     * @notice Emitted when a contract is deployed by this contract.
     *
     * @param contractAddress   Address of the deployed contract.
     * @param deploymentId          ID of the deployment in which the contract was deployed.
     * @param creationCodeWithArgsHash Hash of the creation code with constructor args.
     */
    event ContractDeployed(
        address indexed contractAddress,
        bytes32 indexed deploymentId,
        bytes32 creationCodeWithArgsHash
    );

    /**
     * @notice Emitted when a `CALL` action is executed.
     *
     * @param deploymentId ID of the deployment in which the call was executed.
     * @param callHash     The ABI-encoded hash of the `to` field and the `data` field in the `CALL`
     *                     action.
     * @param actionIndex Index of the `CALL` action that was executed.
     */
    event CallExecuted(bytes32 indexed deploymentId, bytes32 indexed callHash, uint256 actionIndex);

    /**
     * @notice Emitted when a `CALL` action is skipped, which occurs if its nonce is incorrect.
     *
     * @param deploymentId ID of the deployment in which the call was skipped.
     * @param actionIndex Index of the `CALL` action that was skipped.
     */
    event CallSkipped(bytes32 indexed deploymentId, uint256 actionIndex);

    /**
     * @notice Emitted when a contract deployment is skipped. This occurs when a contract already
       exists at the Create3 address.
     *
     * @param contractAddress   Address of the deployed contract.
     * @param deploymentId          ID of the deployment in which the contract was deployed.
     * @param actionIndex Index of the action that attempted to deploy the contract.
     */
    event ContractDeploymentSkipped(
        address indexed contractAddress,
        bytes32 indexed deploymentId,
        uint256 actionIndex
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title ICreate3
 * @notice Interface for a Create3 contract. Normally, this functionality would exist as internal
 *         functions in a library, which can be inherited by other contracts. Instead, we put this
 *         functionality in a contract so that other contracts can use non-standard Create3 formulas
 *         in a modular way. These non-standard Create3 formulas exist on some EVM-compatible
 *         chains. Each Create3 contract that inherits from this interface will implement its own
 *         Create3 formula.
 *
 *         The contracts that inherit from this interface are meant to be delegatecalled by the
 *         `SphinxManager` in order to deploy contracts. It's important to note that a Create3
 *         contract must be delegatecalled by the `SphinxManager` and not called directly. This
 *         ensures that the address of the deployed contract is determined by the address of the
 *         `SphinxManager` contract and not the Create3 contract. Otherwise, it'd be possible for an
 *         attacker to snipe a user's contract by calling the `deploy` function on the Create3
 *         contract.
 */
interface ICreate3 {
    // The creation code isn't used in the address calculation.
    function deploy(
        bytes32 _salt,
        bytes memory _creationCode,
        uint256 _value
    ) external returns (address deployed);

    function getAddress(bytes32 _salt) external view returns (address);

    function getAddressFromDeployer(
        bytes32 _salt,
        address _deployer
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IProxyAdapter
 * @notice Interface that must be inherited by each proxy adapter. Proxy adapters allow other
   contracts to delegatecall into proxies of different types (e.g. Transparent, UUPS, etc.) through
   a standard interface.
 */
interface IProxyAdapter {
    /**
     * @notice Initiate a deployment or upgrade of a proxy.
     *
     * @param _proxy Address of the proxy.
     */
    function initiateUpgrade(address payable _proxy) external;

    /**
     * @notice Complete a deployment or upgrade of a proxy.
     *
     * @param _proxy          Address of the proxy.
     * @param _implementation Address of the proxy's final implementation.
     */
    function finalizeUpgrade(address payable _proxy, address _implementation) external;

    /**
     * @notice Sets a proxy's storage slot value at a given storage slot key and offset.
     *
     * @param _proxy  Address of the proxy to modify.
     * @param _key     Storage slot key to modify.
     * @param _offset  Bytes offset of the new storage slot value from the right side of the storage
       slot. An offset of 0 means the new value will start at the right-most byte of the storage
       slot.
     * @param _value New value of the storage slot at the given key and offset. The length of the
                     value is in the range [1, 32] (inclusive).
     */
    function setStorage(
        address payable _proxy,
        bytes32 _key,
        uint8 _offset,
        bytes memory _value
    ) external;

    /**
     * @notice Changes the admin of the proxy. Note that this function is not triggered during a
               deployment. Instead, it's only triggered if transferring ownership of the UUPS proxy
               away from the SphinxManager, which occurs outside of the deployment process.
     *
     * @param _proxy    Address of the proxy.
     * @param _newAdmin Address of the new admin.
     */
    function changeProxyAdmin(address payable _proxy, address _newAdmin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4 <0.9.0;
pragma experimental ABIEncoderV2;

import { ISphinxRegistry } from "./ISphinxRegistry.sol";
import { DeploymentState, RawSphinxAction, SphinxTarget, Version } from "../SphinxDataTypes.sol";

/**
 * @title SphinxManager
 * @notice Interface that must be inherited by the SphinxManager contract.
 */
interface ISphinxManager {
    /**
     * @notice Initializes this contract. Must only be callable one time, which should occur
       immediately after contract creation. This is necessary because this contract is meant to
       exist as an implementation behind proxies.
     *
     * @return Arbitrary bytes.
     */
    function initialize(
        address _owner,
        string memory _projectName,
        bytes memory _data
    ) external returns (bytes memory);

    /**
     * @notice Indicates whether or not a deployment is currently being executed.
     *
     * @return Whether or not a deployment is currently being executed.
     */
    function isExecuting() external view returns (bool);

    /**
     * @notice The SphinxRegistry.
     *
     * @return Address of the SphinxRegistry.
     */
    function registry() external view returns (ISphinxRegistry);

    function cancelActiveSphinxDeployment() external;

    function exportProxy(
        address payable _proxy,
        bytes32 _contractKindHash,
        address _newOwner
    ) external;

    function approve(
        bytes32 _actionRoot,
        bytes32 _targetRoot,
        uint256 _numInitialActions,
        uint256 _numSetStorageActions,
        uint256 _numTargets,
        string memory _configUri,
        bool _remoteExecution
    ) external;

    function activeDeploymentId() external view returns (bytes32);

    function deployments(bytes32 _deploymentId) external view returns (DeploymentState memory);

    function callNonces(bytes32 _callHash) external view returns (uint256);

    function executeInitialActions(
        RawSphinxAction[] memory _actions,
        bytes32[][] memory _proofs
    ) external;

    function setStorage(RawSphinxAction[] memory _actions, bytes32[][] memory _proofs) external;

    function initiateUpgrade(SphinxTarget[] memory _targets, bytes32[][] memory _proofs) external;

    function finalizeUpgrade(SphinxTarget[] memory _targets, bytes32[][] memory _proofs) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4 <0.9.0;
pragma experimental ABIEncoderV2;

import { Version } from "../SphinxDataTypes.sol";

interface ISphinxRegistry {
    function managers(bytes32) external view returns (address payable);

    function register(
        address _owner,
        string memory _projectName,
        bytes memory _data
    ) external returns (address);

    function isManagerDeployed(address) external view returns (bool);

    function addContractKind(bytes32 _contractKindHash, address _adapter) external;

    function addVersion(address _manager) external;

    function announce(string memory _event) external;

    function announceWithData(string memory _event, bytes memory _data) external;

    function adapters(bytes32) external view returns (address);

    function setCurrentManagerImplementation(address _manager) external;
}