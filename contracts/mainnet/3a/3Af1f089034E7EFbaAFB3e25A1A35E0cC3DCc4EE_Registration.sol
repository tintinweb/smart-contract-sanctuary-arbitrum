// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

uint256 constant MAX_SMT_DEPTH = 64;

interface IState {
    /**
     * @dev Struct for public interfaces to represent a state information.
     * @param id An identity.
     * @param state A state.
     * @param replacedByState A state, which replaced this state for the identity.
     * @param createdAtTimestamp A time when the state was created.
     * @param replacedAtTimestamp A time when the state was replaced by the next identity state.
     * @param createdAtBlock A block number when the state was created.
     * @param replacedAtBlock A block number when the state was replaced by the next identity state.
     */
    struct StateInfo {
        uint256 id;
        uint256 state;
        uint256 replacedByState;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent GIST root information.
     * @param root This GIST root.
     * @param replacedByRoot A root, which replaced this root.
     * @param createdAtTimestamp A time, when the root was saved to blockchain.
     * @param replacedAtTimestamp A time, when the root was replaced by the next root in blockchain.
     * @param createdAtBlock A number of block, when the root was saved to blockchain.
     * @param replacedAtBlock A number of block, when the root was replaced by the next root in blockchain.
     */
    struct GistRootInfo {
        uint256 root;
        uint256 replacedByRoot;
        uint256 createdAtTimestamp;
        uint256 replacedAtTimestamp;
        uint256 createdAtBlock;
        uint256 replacedAtBlock;
    }

    /**
     * @dev Struct for public interfaces to represent GIST proof information.
     * @param root This GIST root.
     * @param existence A flag, which shows if the leaf index exists in the GIST.
     * @param siblings An array of GIST sibling node hashes.
     * @param index An index of the leaf in the GIST.
     * @param value A value of the leaf in the GIST.
     * @param auxExistence A flag, which shows if the auxiliary leaf exists in the GIST.
     * @param auxIndex An index of the auxiliary leaf in the GIST.
     * @param auxValue An value of the auxiliary leaf in the GIST.
     */
    struct GistProof {
        uint256 root;
        bool existence;
        uint256[MAX_SMT_DEPTH] siblings;
        uint256 index;
        uint256 value;
        bool auxExistence;
        uint256 auxIndex;
        uint256 auxValue;
    }

    /**
     * @dev Retrieve last state information of specific id.
     * @param id An identity.
     * @return The state info.
     */
    function getStateInfoById(uint256 id) external view returns (StateInfo memory);

    /**
     * @dev Retrieve state information by id and state.
     * @param id An identity.
     * @param state A state.
     * @return The state info.
     */
    function getStateInfoByIdAndState(
        uint256 id,
        uint256 state
    ) external view returns (StateInfo memory);

    /**
     * @dev Retrieve the specific GIST root information.
     * @param root GIST root.
     * @return The GIST root info.
     */
    function getGISTRootInfo(uint256 root) external view returns (GistRootInfo memory);

    /**
     * @dev Get defaultIdType
     * @return defaultIdType
     */
    function getDefaultIdType() external view returns (bytes2);

    /**
     * @dev Performs state transition
     * @param id Identifier of the identity
     * @param oldState Previous state of the identity
     * @param newState New state of the identity
     * @param isOldStateGenesis Flag if previous identity state is genesis
     * @param a Proof.A
     * @param b Proof.B
     * @param c Proof.C
     */
    function transitState(
        uint256 id,
        uint256 oldState,
        uint256 newState,
        bool isOldStateGenesis,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) external;

    /**
     * @dev Performs state transition
     * @param id Identity
     * @param oldState Previous identity state
     * @param newState New identity state
     * @param isOldStateGenesis Is the previous state genesis?
     * @param methodId State transition method id
     * @param methodParams State transition method-specific params
     */
    function transitStateGeneric(
        uint256 id,
        uint256 oldState,
        uint256 newState,
        bool isOldStateGenesis,
        uint256 methodId,
        bytes calldata methodParams
    ) external;

    /**
     * @dev Check if identity exists.
     * @param id Identity
     * @return True if the identity exists
     */
    function idExists(uint256 id) external view returns (bool);

    /**
     * @dev Check if state exists.
     * @param id Identity
     * @param state State
     * @return True if the state exists
     */
    function stateExists(uint256 id, uint256 state) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

library PoseidonUnit1L {
    function poseidon(uint256[1] calldata) public pure returns (uint256) {}
}

library PoseidonUnit2L {
    function poseidon(uint256[2] calldata) public pure returns (uint256) {}
}

library PoseidonUnit3L {
    function poseidon(uint256[3] calldata) public pure returns (uint256) {}
}

library PoseidonUnit4L {
    function poseidon(uint256[4] calldata) public pure returns (uint256) {}
}

library PoseidonUnit5L {
    function poseidon(uint256[5] calldata) public pure returns (uint256) {}
}

library PoseidonUnit6L {
    function poseidon(uint256[6] calldata) public pure returns (uint256) {}
}

library SpongePoseidon {
    uint32 internal constant BATCH_SIZE = 6;

    function hash(uint256[] calldata values) public pure returns (uint256) {
        uint256[BATCH_SIZE] memory frame = [uint256(0), 0, 0, 0, 0, 0];
        bool dirty = false;
        uint256 fullHash = 0;
        uint32 k = 0;
        for (uint32 i = 0; i < values.length; i++) {
            dirty = true;
            frame[k] = values[i];
            if (k == BATCH_SIZE - 1) {
                fullHash = PoseidonUnit6L.poseidon(frame);
                dirty = false;
                frame = [uint256(0), 0, 0, 0, 0, 0];
                frame[0] = fullHash;
                k = 1;
            } else {
                k++;
            }
        }
        if (dirty) {
            // we haven't hashed something in the main sponge loop and need to do hash here
            fullHash = PoseidonUnit6L.poseidon(frame);
        }
        return fullHash;
    }
}

library PoseidonFacade {
    function poseidon1(uint256[1] calldata el) public pure returns (uint256) {
        return PoseidonUnit1L.poseidon(el);
    }

    function poseidon2(uint256[2] calldata el) public pure returns (uint256) {
        return PoseidonUnit2L.poseidon(el);
    }

    function poseidon3(uint256[3] calldata el) public pure returns (uint256) {
        return PoseidonUnit3L.poseidon(el);
    }

    function poseidon4(uint256[4] calldata el) public pure returns (uint256) {
        return PoseidonUnit4L.poseidon(el);
    }

    function poseidon5(uint256[5] calldata el) public pure returns (uint256) {
        return PoseidonUnit5L.poseidon(el);
    }

    function poseidon6(uint256[6] calldata el) public pure returns (uint256) {
        return PoseidonUnit6L.poseidon(el);
    }

    function poseidonSponge(uint256[] calldata el) public pure returns (uint256) {
        return SpongePoseidon.hash(el);
    }
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
pragma solidity ^0.8.4;

/**
 * @notice Sparse Merkle Tree Module
 *
 * This implementation modifies and optimizes the Sparse Merkle Tree data structure as described
 * in [Sparse Merkle Trees](https://docs.iden3.io/publications/pdfs/Merkle-Tree.pdf), originally implemented in
 * the [iden3/contracts repository](https://github.com/iden3/contracts/blob/8815bf53e989311d94301f4c513436c1ff776911/contracts/lib/SmtLib.sol).
 *
 * It aims to provide more gas-efficient operations for the Sparse Merkle Tree while offering flexibility
 * in using different types of keys and values.
 *
 * The main differences from the original implementation include:
 * - Added the ability to remove or update nodes in the tree.
 * - Optimized storage usage to reduce the number of storage slots.
 * - Added the ability to set custom hash functions.
 * - Removed methods and associated storage for managing the tree root's history.
 *
 * Gas usage for adding (addUint) 20,000 leaves to a tree of size 80 "based" on the Poseidon Hash function is detailed below:
 *
 * | Statistic |     Add       |
 * |-----------|-------------- |
 * | Count     | 20,000        |
 * | Mean      | 890,446 gas |
 * | Std Dev   | 147,775 gas |
 * | Min       | 177,797 gas   |
 * | 25%       | 784,961 gas   |
 * | 50%       | 866,482 gas   |
 * | 75%       | 959,075 gas   |
 * | Max       | 1,937,554 gas |
 *
 * The gas cost increases linearly with the depth of the leaves added. This growth can be approximated by the following formula:
 * Linear regression formula: y = 46,377x + 215,088
 *
 * This implies that adding an element at depth 80 would approximately cost 3.93M gas.
 *
 * On the other hand, the growth of the gas cost for removing leaves can be approximated by the following formula:
 * Linear regression formula: y = 44840*x + 88821
 *
 * This implies that removing an element at depth 80 would approximately cost 3.68M gas.
 *
 * ## Usage Example:
 *
 * ```solidity
 * using SparseMerkleTree for SparseMerkleTree.UintSMT;
 *
 * SparseMerkleTree.UintSMT internal uintTree;
 * ...
 * uintTree.initialize(80);
 *
 * uintTree.add(100, 500);
 *
 * uintTree.getRoot();
 *
 * SparseMerkleTree.Proof memory proof = uintTree.getProof(100);
 *
 * uintTree.getNodeByKey(100);
 *
 * uintTree.remove(100);
 * ```
 */
library SparseMerkleTree {
    /**
     *********************
     *      UintSMT      *
     *********************
     */

    struct UintSMT {
        SMT _tree;
    }

    /**
     * @notice The function to initialize the Merkle tree.
     * Under the hood it sets the maximum depth of the Merkle tree, therefore can be considered
     * alias function for the `setMaxDepth`.
     *
     * Requirements:
     * - The current tree depth must be 0.
     *
     * @param tree self.
     * @param maxDepth_ The max depth of the Merkle tree.
     */
    function initialize(UintSMT storage tree, uint32 maxDepth_) internal {
        _initialize(tree._tree, maxDepth_);
    }

    /**
     * @notice The function to set the maximum depth of the Merkle tree. Complexity is O(1).
     *
     * Requirements:
     * - The max depth must be greater than zero.
     * - The max depth can only be increased.
     * - The max depth is less than or equal to MAX_DEPTH_HARD_CAP (256).
     *
     * @param tree self.
     * @param maxDepth_ The max depth of the Merkle tree.
     */
    function setMaxDepth(UintSMT storage tree, uint32 maxDepth_) internal {
        _setMaxDepth(tree._tree, maxDepth_);
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param tree self.
     * @param hash2_ The hash function that accepts two argument.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHashers(
        UintSMT storage tree,
        function(bytes32, bytes32) view returns (bytes32) hash2_,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(tree._tree, hash2_, hash3_);
    }

    /**
     * @notice The function to add a new element to the uint256 tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @param value_ The value of the element.
     */
    function add(UintSMT storage tree, bytes32 key_, uint256 value_) internal {
        _add(tree._tree, bytes32(key_), bytes32(value_));
    }

    /**
     * @notice The function to remove a (leaf) element from the uint256 tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     */
    function remove(UintSMT storage tree, bytes32 key_) internal {
        _remove(tree._tree, key_);
    }

    /**
     * @notice The function to update a (leaf) element in the uint256 tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @param newValue_ The new value of the element.
     */
    function update(UintSMT storage tree, bytes32 key_, uint256 newValue_) internal {
        _update(tree._tree, key_, bytes32(newValue_));
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the SMT.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @return SMT proof struct.
     */
    function getProof(UintSMT storage tree, bytes32 key_) internal view returns (Proof memory) {
        return _proof(tree._tree, bytes32(key_));
    }

    /**
     * @notice The function to get the root of the Merkle tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @return The root of the Merkle tree.
     */
    function getRoot(UintSMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(UintSMT storage tree, uint256 nodeId_) internal view returns (Node memory) {
        return _node(tree._tree, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(UintSMT storage tree, uint256 key_) internal view returns (Node memory) {
        return _nodeByKey(tree._tree, bytes32(key_));
    }

    /**
     * @notice The function to get the max depth of the Merkle tree.
     *
     * @param tree self.
     * @return The max depth of the Merkle tree.
     */
    function getMaxDepth(UintSMT storage tree) internal view returns (uint64) {
        return uint64(_maxDepth(tree._tree));
    }

    /**
     * @notice The function to get the number of nodes in the Merkle tree.
     *
     * @param tree self.
     * @return The number of nodes in the Merkle tree.
     */
    function getNodesCount(UintSMT storage tree) internal view returns (uint64) {
        return uint64(_nodesCount(tree._tree));
    }

    /**
     * @notice The function to check if custom hash functions are set.
     *
     * @param tree self.
     * @return True if custom hash functions are set, otherwise false.
     */
    function isCustomHasherSet(UintSMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._tree);
    }

    /**
     **********************
     *     Bytes32IMT     *
     **********************
     */

    struct Bytes32SMT {
        SMT _tree;
    }

    /**
     * @notice The function to initialize the Merkle tree.
     * Under the hood it sets the maximum depth of the Merkle tree, therefore can be considered
     * alias function for the `setMaxDepth`.
     *
     * Requirements:
     * - The current tree depth must be 0.
     *
     * @param tree self.
     * @param maxDepth_ The max depth of the Merkle tree.
     */
    function initialize(Bytes32SMT storage tree, uint32 maxDepth_) internal {
        _initialize(tree._tree, maxDepth_);
    }

    /**
     * @notice The function to set the maximum depth of the Merkle tree. Complexity is O(1).
     *
     * Requirements:
     * - The max depth must be greater than zero.
     * - The max depth can only be increased.
     * - The max depth is less than or equal to MAX_DEPTH_HARD_CAP (256).
     *
     * @param tree self.
     * @param maxDepth_ The max depth of the Merkle tree.
     */
    function setMaxDepth(Bytes32SMT storage tree, uint32 maxDepth_) internal {
        _setMaxDepth(tree._tree, maxDepth_);
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param tree self.
     * @param hash2_ The hash function that accepts two argument.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHashers(
        Bytes32SMT storage tree,
        function(bytes32, bytes32) view returns (bytes32) hash2_,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(tree._tree, hash2_, hash3_);
    }

    /**
     * @notice The function to add a new element to the bytes32 tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @param value_ The value of the element.
     */
    function add(Bytes32SMT storage tree, bytes32 key_, bytes32 value_) internal {
        _add(tree._tree, key_, value_);
    }

    /**
     * @notice The function to remove a (leaf) element from the bytes32 tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     */
    function remove(Bytes32SMT storage tree, bytes32 key_) internal {
        _remove(tree._tree, key_);
    }

    /**
     * @notice The function to update a (leaf) element in the bytes32 tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @param newValue_ The new value of the element.
     */
    function update(Bytes32SMT storage tree, bytes32 key_, bytes32 newValue_) internal {
        _update(tree._tree, key_, newValue_);
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the SMT.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @return SMT proof struct.
     */
    function getProof(Bytes32SMT storage tree, bytes32 key_) internal view returns (Proof memory) {
        return _proof(tree._tree, key_);
    }

    /**
     * @notice The function to get the root of the Merkle tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @return The root of the Merkle tree.
     */
    function getRoot(Bytes32SMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(
        Bytes32SMT storage tree,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(tree._tree, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(
        Bytes32SMT storage tree,
        bytes32 key_
    ) internal view returns (Node memory) {
        return _nodeByKey(tree._tree, key_);
    }

    /**
     * @notice The function to get the max depth of the Merkle tree.
     *
     * @param tree self.
     * @return The max depth of the Merkle tree.
     */
    function getMaxDepth(Bytes32SMT storage tree) internal view returns (uint64) {
        return uint64(_maxDepth(tree._tree));
    }

    /**
     * @notice The function to get the number of nodes in the Merkle tree.
     *
     * @param tree self.
     * @return The number of nodes in the Merkle tree.
     */
    function getNodesCount(Bytes32SMT storage tree) internal view returns (uint64) {
        return uint64(_nodesCount(tree._tree));
    }

    /**
     * @notice The function to check if custom hash functions are set.
     *
     * @param tree self.
     * @return True if custom hash functions are set, otherwise false.
     */
    function isCustomHasherSet(Bytes32SMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._tree);
    }

    /**
     ************************
     *      AddressSMT      *
     ************************
     */

    struct AddressSMT {
        SMT _tree;
    }

    /**
     * @notice The function to initialize the Merkle tree.
     * Under the hood it sets the maximum depth of the Merkle tree, therefore can be considered
     * alias function for the `setMaxDepth`.
     *
     * Requirements:
     * - The current tree depth must be 0.
     *
     * @param tree self.
     * @param maxDepth_ The max depth of the Merkle tree.
     */
    function initialize(AddressSMT storage tree, uint32 maxDepth_) internal {
        _initialize(tree._tree, maxDepth_);
    }

    /**
     * @notice The function to set the maximum depth of the Merkle tree. Complexity is O(1).
     *
     * Requirements:
     * - The max depth must be greater than zero.
     * - The max depth can only be increased.
     * - The max depth is less than or equal to MAX_DEPTH_HARD_CAP (256).
     *
     * @param tree self.
     * @param maxDepth_ The max depth of the Merkle tree.
     */
    function setMaxDepth(AddressSMT storage tree, uint32 maxDepth_) internal {
        _setMaxDepth(tree._tree, maxDepth_);
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param tree self.
     * @param hash2_ The hash function that accepts two argument.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHashers(
        AddressSMT storage tree,
        function(bytes32, bytes32) view returns (bytes32) hash2_,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHashers(tree._tree, hash2_, hash3_);
    }

    /**
     * @notice The function to add a new element to the address tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @param value_ The value of the element.
     */
    function add(AddressSMT storage tree, bytes32 key_, address value_) internal {
        _add(tree._tree, key_, bytes32(uint256(uint160(value_))));
    }

    /**
     * @notice The function to remove a (leaf) element from the address tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     */
    function remove(AddressSMT storage tree, bytes32 key_) internal {
        _remove(tree._tree, key_);
    }

    /**
     * @notice The function to update a (leaf) element in the address tree.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @param newValue_ The new value of the element.
     */
    function update(AddressSMT storage tree, bytes32 key_, address newValue_) internal {
        _update(tree._tree, key_, bytes32(uint256(uint160(newValue_))));
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the SMT.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @return SMT proof struct.
     */
    function getProof(AddressSMT storage tree, bytes32 key_) internal view returns (Proof memory) {
        return _proof(tree._tree, key_);
    }

    /**
     * @notice The function to get the root of the Merkle tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @return The root of the Merkle tree.
     */
    function getRoot(AddressSMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(
        AddressSMT storage tree,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(tree._tree, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the tree.
     *
     * @param tree self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(
        AddressSMT storage tree,
        bytes32 key_
    ) internal view returns (Node memory) {
        return _nodeByKey(tree._tree, key_);
    }

    /**
     * @notice The function to get the max depth of the Merkle tree.
     *
     * @param tree self.
     * @return The max depth of the Merkle tree.
     */
    function getMaxDepth(AddressSMT storage tree) internal view returns (uint64) {
        return uint64(_maxDepth(tree._tree));
    }

    /**
     * @notice The function to get the number of nodes in the Merkle tree.
     *
     * @param tree self.
     * @return The number of nodes in the Merkle tree.
     */
    function getNodesCount(AddressSMT storage tree) internal view returns (uint64) {
        return uint64(_nodesCount(tree._tree));
    }

    /**
     * @notice The function to check if custom hash functions are set.
     *
     * @param tree self.
     * @return True if custom hash functions are set, otherwise false.
     */
    function isCustomHasherSet(AddressSMT storage tree) internal view returns (bool) {
        return _isCustomHasherSet(tree._tree);
    }

    /**
     ************************
     *       InnerSMT       *
     ************************
     */

    /**
     * @dev A maximum depth hard cap for SMT
     * Due to the limitations of the uint256 data type, depths greater than 256 are not feasible.
     */
    uint16 internal constant MAX_DEPTH_HARD_CAP = 256;

    uint64 internal constant ZERO_IDX = 0;

    bytes32 internal constant ZERO_HASH = bytes32(0);

    /**
     * @notice The type of the node in the Merkle tree.
     */
    enum NodeType {
        EMPTY,
        LEAF,
        MIDDLE
    }

    /**
     * @notice Defines the structure of the Sparse Merkle Tree.
     *
     * @param nodes A mapping of the tree's nodes, where the key is the node's index, starting from 1 upon node addition.
     * This approach differs from the original implementation, which utilized a hash as the key:
     * H(k || v || 1) for leaf nodes and H(left || right) for middle nodes.
     *
     * @param merkleRootId The index of the root node.
     * @param maxDepth The maximum depth of the Merkle tree.
     * @param nodesCount The total number of nodes within the Merkle tree.
     * @param isCustomHasherSet Indicates whether custom hash functions have been configured (true) or not (false).
     * @param hash2 A hash function accepting two arguments.
     * @param hash3 A hash function accepting three arguments.
     */
    struct SMT {
        mapping(uint256 => Node) nodes;
        uint64 merkleRootId;
        uint64 nodesCount;
        uint64 deletedNodesCount;
        uint32 maxDepth;
        bool isCustomHasherSet;
        function(bytes32, bytes32) view returns (bytes32) hash2;
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3;
    }

    /**
     * @notice Describes a node within the Merkle tree, including its type, children, hash, and key-value pair.
     *
     * @param nodeType The type of the node.
     * @param childLeft The index of the left child node.
     * @param childRight The index of the right child node.
     * @param nodeHash The hash of the node, calculated as follows:
     * - For leaf nodes, H(k || v || 1) where k is the key and v is the value;
     * - For middle nodes, H(left || right) where left and right are the hashes of the child nodes.
     *
     * @param key The key associated with the node.
     * @param value The value associated with the node.
     */
    struct Node {
        NodeType nodeType;
        uint64 childLeft;
        uint64 childRight;
        bytes32 nodeHash;
        bytes32 key;
        bytes32 value;
    }

    /**
     * @notice Represents the proof of a node's (non-)existence within the Merkle tree.
     *
     * @param root The root hash of the Merkle tree.
     * @param siblings An array of sibling hashes can be used to get the Merkle Root.
     * @param existence Indicates the presence (true) or absence (false) of the node.
     * @param key The key associated with the node.
     * @param value The value associated with the node.
     * @param auxExistence Indicates the presence (true) or absence (false) of an auxiliary node.
     * @param auxKey The key of the auxiliary node.
     * @param auxValue The value of the auxiliary node.
     */
    struct Proof {
        bytes32 root;
        bytes32[] siblings;
        bool existence;
        bytes32 key;
        bytes32 value;
        bool auxExistence;
        bytes32 auxKey;
        bytes32 auxValue;
    }

    modifier onlyInitialized(SMT storage tree) {
        require(_isInitialized(tree), "SparseMerkleTree: tree is not initialized");
        _;
    }

    function _initialize(SMT storage tree, uint32 maxDepth_) private {
        require(!_isInitialized(tree), "SparseMerkleTree: tree is already initialized");

        _setMaxDepth(tree, maxDepth_);
    }

    function _setMaxDepth(SMT storage tree, uint32 maxDepth_) private {
        require(maxDepth_ > 0, "SparseMerkleTree: max depth must be greater than zero");
        require(maxDepth_ > tree.maxDepth, "SparseMerkleTree: max depth can only be increased");
        require(
            maxDepth_ <= MAX_DEPTH_HARD_CAP,
            "SparseMerkleTree: max depth is greater than hard cap"
        );

        tree.maxDepth = maxDepth_;
    }

    function _setHashers(
        SMT storage tree,
        function(bytes32, bytes32) view returns (bytes32) hash2_,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) private {
        require(_nodesCount(tree) == 0, "SparseMerkleTree: tree is not empty");

        tree.isCustomHasherSet = true;

        tree.hash2 = hash2_;
        tree.hash3 = hash3_;
    }

    function _add(SMT storage tree, bytes32 key_, bytes32 value_) private onlyInitialized(tree) {
        Node memory node_ = Node({
            nodeType: NodeType.LEAF,
            childLeft: ZERO_IDX,
            childRight: ZERO_IDX,
            nodeHash: ZERO_HASH,
            key: key_,
            value: value_
        });

        tree.merkleRootId = uint64(_add(tree, node_, tree.merkleRootId, 0));
    }

    function _remove(SMT storage tree, bytes32 key_) private onlyInitialized(tree) {
        tree.merkleRootId = uint64(_remove(tree, key_, tree.merkleRootId, 0));
    }

    function _update(
        SMT storage tree,
        bytes32 key_,
        bytes32 newValue_
    ) private onlyInitialized(tree) {
        Node memory node_ = Node({
            nodeType: NodeType.LEAF,
            childLeft: ZERO_IDX,
            childRight: ZERO_IDX,
            nodeHash: ZERO_HASH,
            key: key_,
            value: newValue_
        });

        _update(tree, node_, tree.merkleRootId, 0);
    }

    /**
     * @dev The check for whether the current depth exceeds the maximum depth is omitted for two reasons:
     * 1. The current depth may only surpass the maximum depth during the addition of a new leaf.
     * 2. As we navigate through middle nodes, the current depth is assured to remain below the maximum
     *    depth since the traversal must ultimately conclude at a leaf node.
     */
    function _add(
        SMT storage tree,
        Node memory newLeaf_,
        uint256 nodeId_,
        uint16 currentDepth_
    ) private returns (uint256) {
        Node memory currentNode_ = tree.nodes[nodeId_];

        if (currentNode_.nodeType == NodeType.EMPTY) {
            return _setNode(tree, newLeaf_);
        } else if (currentNode_.nodeType == NodeType.LEAF) {
            if (currentNode_.key == newLeaf_.key) {
                revert("SparseMerkleTree: the key already exists");
            }

            return _pushLeaf(tree, newLeaf_, currentNode_, nodeId_, currentDepth_);
        } else {
            uint256 nextNodeId_;

            if ((uint256(newLeaf_.key) >> currentDepth_) & 1 == 1) {
                nextNodeId_ = _add(tree, newLeaf_, currentNode_.childRight, currentDepth_ + 1);

                tree.nodes[nodeId_].childRight = uint64(nextNodeId_);
            } else {
                nextNodeId_ = _add(tree, newLeaf_, currentNode_.childLeft, currentDepth_ + 1);

                tree.nodes[nodeId_].childLeft = uint64(nextNodeId_);
            }

            tree.nodes[nodeId_].nodeHash = _getNodeHash(tree, tree.nodes[nodeId_]);

            return nodeId_;
        }
    }

    function _remove(
        SMT storage tree,
        bytes32 key_,
        uint256 nodeId_,
        uint16 currentDepth_
    ) private returns (uint256) {
        Node memory currentNode_ = tree.nodes[nodeId_];

        if (currentNode_.nodeType == NodeType.EMPTY) {
            revert("SparseMerkleTree: the node does not exist");
        } else if (currentNode_.nodeType == NodeType.LEAF) {
            if (currentNode_.key != key_) {
                revert("SparseMerkleTree: the leaf does not match");
            }

            _deleteNode(tree, nodeId_);

            return ZERO_IDX;
        } else {
            uint256 nextNodeId_;

            if ((uint256(key_) >> currentDepth_) & 1 == 1) {
                nextNodeId_ = _remove(tree, key_, currentNode_.childRight, currentDepth_ + 1);
            } else {
                nextNodeId_ = _remove(tree, key_, currentNode_.childLeft, currentDepth_ + 1);
            }

            NodeType rightType_ = tree.nodes[currentNode_.childRight].nodeType;
            NodeType leftType_ = tree.nodes[currentNode_.childLeft].nodeType;

            if (rightType_ == NodeType.EMPTY && leftType_ == NodeType.EMPTY) {
                _deleteNode(tree, nodeId_);

                return nextNodeId_;
            }

            NodeType nextType_ = tree.nodes[nextNodeId_].nodeType;

            if (
                (rightType_ == NodeType.EMPTY || leftType_ == NodeType.EMPTY) &&
                nextType_ != NodeType.MIDDLE
            ) {
                if (
                    nextType_ == NodeType.EMPTY &&
                    (leftType_ == NodeType.LEAF || rightType_ == NodeType.LEAF)
                ) {
                    _deleteNode(tree, nodeId_);

                    if (rightType_ == NodeType.LEAF) {
                        return currentNode_.childRight;
                    }

                    return currentNode_.childLeft;
                }

                if (rightType_ == NodeType.EMPTY) {
                    tree.nodes[nodeId_].childRight = uint64(nextNodeId_);
                } else {
                    tree.nodes[nodeId_].childLeft = uint64(nextNodeId_);
                }
            }

            tree.nodes[nodeId_].nodeHash = _getNodeHash(tree, tree.nodes[nodeId_]);

            return nodeId_;
        }
    }

    function _update(
        SMT storage tree,
        Node memory newLeaf_,
        uint256 nodeId_,
        uint16 currentDepth_
    ) private {
        Node memory currentNode_ = tree.nodes[nodeId_];

        if (currentNode_.nodeType == NodeType.EMPTY) {
            revert("SparseMerkleTree: the node does not exist");
        } else if (currentNode_.nodeType == NodeType.LEAF) {
            if (currentNode_.key != newLeaf_.key) {
                revert("SparseMerkleTree: the leaf does not match");
            }

            tree.nodes[nodeId_] = newLeaf_;
            currentNode_ = newLeaf_;
        } else {
            if ((uint256(newLeaf_.key) >> currentDepth_) & 1 == 1) {
                _update(tree, newLeaf_, currentNode_.childRight, currentDepth_ + 1);
            } else {
                _update(tree, newLeaf_, currentNode_.childLeft, currentDepth_ + 1);
            }
        }

        tree.nodes[nodeId_].nodeHash = _getNodeHash(tree, currentNode_);
    }

    function _pushLeaf(
        SMT storage tree,
        Node memory newLeaf_,
        Node memory oldLeaf_,
        uint256 oldLeafId_,
        uint16 currentDepth_
    ) private returns (uint256) {
        require(currentDepth_ < tree.maxDepth, "SparseMerkleTree: max depth reached");

        Node memory newNodeMiddle_;
        bool newLeafBitAtDepth_ = (uint256(newLeaf_.key) >> currentDepth_) & 1 == 1;
        bool oldLeafBitAtDepth_ = (uint256(oldLeaf_.key) >> currentDepth_) & 1 == 1;

        // Check if we need to go deeper if diverge at the depth's bit
        if (newLeafBitAtDepth_ == oldLeafBitAtDepth_) {
            uint256 nextNodeId_ = _pushLeaf(
                tree,
                newLeaf_,
                oldLeaf_,
                oldLeafId_,
                currentDepth_ + 1
            );

            if (newLeafBitAtDepth_) {
                // go right
                newNodeMiddle_ = Node({
                    nodeType: NodeType.MIDDLE,
                    childLeft: ZERO_IDX,
                    childRight: uint64(nextNodeId_),
                    nodeHash: ZERO_HASH,
                    key: ZERO_HASH,
                    value: ZERO_HASH
                });
            } else {
                // go left
                newNodeMiddle_ = Node({
                    nodeType: NodeType.MIDDLE,
                    childLeft: uint64(nextNodeId_),
                    childRight: ZERO_IDX,
                    nodeHash: ZERO_HASH,
                    key: ZERO_HASH,
                    value: ZERO_HASH
                });
            }

            return _setNode(tree, newNodeMiddle_);
        }

        uint256 newLeafId = _setNode(tree, newLeaf_);

        if (newLeafBitAtDepth_) {
            newNodeMiddle_ = Node({
                nodeType: NodeType.MIDDLE,
                childLeft: uint64(oldLeafId_),
                childRight: uint64(newLeafId),
                nodeHash: ZERO_HASH,
                key: ZERO_HASH,
                value: ZERO_HASH
            });
        } else {
            newNodeMiddle_ = Node({
                nodeType: NodeType.MIDDLE,
                childLeft: uint64(newLeafId),
                childRight: uint64(oldLeafId_),
                nodeHash: ZERO_HASH,
                key: ZERO_HASH,
                value: ZERO_HASH
            });
        }

        return _setNode(tree, newNodeMiddle_);
    }

    /**
     * @dev The function used to add new nodes.
     */
    function _setNode(SMT storage tree, Node memory node_) private returns (uint256) {
        node_.nodeHash = _getNodeHash(tree, node_);

        uint256 newCount_ = ++tree.nodesCount;
        tree.nodes[newCount_] = node_;

        return newCount_;
    }

    /**
     * @dev The function used to delete removed nodes.
     */
    function _deleteNode(SMT storage tree, uint256 nodeId_) private {
        delete tree.nodes[nodeId_];
        ++tree.deletedNodesCount;
    }

    /**
     * @dev The check for an empty node is omitted, as this function is called only with
     * non-empty nodes and is not intended for external use.
     */
    function _getNodeHash(SMT storage tree, Node memory node_) private view returns (bytes32) {
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = tree.isCustomHasherSet
            ? tree.hash3
            : _hash3;

        if (node_.nodeType == NodeType.LEAF) {
            return hash3_(node_.key, node_.value, bytes32(uint256(1)));
        }

        return hash2_(tree.nodes[node_.childLeft].nodeHash, tree.nodes[node_.childRight].nodeHash);
    }

    function _proof(SMT storage tree, bytes32 key_) private view returns (Proof memory) {
        uint256 maxDepth_ = _maxDepth(tree);

        Proof memory proof_ = Proof({
            root: _root(tree),
            siblings: new bytes32[](maxDepth_),
            existence: false,
            key: key_,
            value: ZERO_HASH,
            auxExistence: false,
            auxKey: ZERO_HASH,
            auxValue: ZERO_HASH
        });

        Node memory node_;
        uint256 nextNodeId_ = tree.merkleRootId;

        for (uint256 i = 0; i <= maxDepth_; i++) {
            node_ = _node(tree, nextNodeId_);

            if (node_.nodeType == NodeType.EMPTY) {
                break;
            } else if (node_.nodeType == NodeType.LEAF) {
                if (node_.key == proof_.key) {
                    proof_.existence = true;
                    proof_.value = node_.value;

                    break;
                } else {
                    proof_.auxExistence = true;
                    proof_.auxKey = node_.key;
                    proof_.auxValue = node_.value;
                    proof_.value = node_.value;

                    break;
                }
            } else {
                if ((uint256(proof_.key) >> i) & 1 == 1) {
                    nextNodeId_ = node_.childRight;

                    proof_.siblings[i] = tree.nodes[node_.childLeft].nodeHash;
                } else {
                    nextNodeId_ = node_.childLeft;

                    proof_.siblings[i] = tree.nodes[node_.childRight].nodeHash;
                }
            }
        }

        return proof_;
    }

    function _hash2(bytes32 a, bytes32 b) private pure returns (bytes32 result) {
        assembly {
            mstore(0, a)
            mstore(32, b)

            result := keccak256(0, 64)
        }
    }

    /**
     * @dev The decision not to update the free memory pointer is due to the temporary nature of the hash arguments.
     */
    function _hash3(bytes32 a, bytes32 b, bytes32 c) private pure returns (bytes32 result) {
        assembly {
            let free_ptr := mload(64)

            mstore(free_ptr, a)
            mstore(add(free_ptr, 32), b)
            mstore(add(free_ptr, 64), c)

            result := keccak256(free_ptr, 96)
        }
    }

    function _root(SMT storage tree) private view returns (bytes32) {
        return tree.nodes[tree.merkleRootId].nodeHash;
    }

    function _node(SMT storage tree, uint256 nodeId_) private view returns (Node memory) {
        return tree.nodes[nodeId_];
    }

    function _nodeByKey(SMT storage tree, bytes32 key_) private view returns (Node memory) {
        Node memory node_;
        uint256 nextNodeId_ = tree.merkleRootId;

        for (uint256 i = 0; i <= tree.maxDepth; i++) {
            node_ = tree.nodes[nextNodeId_];

            if (node_.nodeType == NodeType.EMPTY) {
                break;
            } else if (node_.nodeType == NodeType.LEAF) {
                if (node_.key == key_) {
                    break;
                }
            } else {
                if ((uint256(key_) >> i) & 1 == 1) {
                    nextNodeId_ = node_.childRight;
                } else {
                    nextNodeId_ = node_.childLeft;
                }
            }
        }

        return
            node_.key == key_
                ? node_
                : Node({
                    nodeType: NodeType.EMPTY,
                    childLeft: ZERO_IDX,
                    childRight: ZERO_IDX,
                    nodeHash: ZERO_HASH,
                    key: ZERO_HASH,
                    value: ZERO_HASH
                });
    }

    function _maxDepth(SMT storage tree) private view returns (uint256) {
        return tree.maxDepth;
    }

    function _nodesCount(SMT storage tree) private view returns (uint256) {
        return tree.nodesCount - tree.deletedNodesCount;
    }

    function _isInitialized(SMT storage tree) private view returns (bool) {
        return tree.maxDepth > 0;
    }

    function _isCustomHasherSet(SMT storage tree) private view returns (bool) {
        return tree.isCustomHasherSet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IRegistration} from "../interfaces/core/IRegistration.sol";
import {IBaseVerifier} from "../interfaces/iden3/verifiers/IBaseVerifier.sol";
import {IRegisterVerifier} from "../interfaces/iden3/verifiers/IRegisterVerifier.sol";

import {PoseidonSMT} from "../utils/PoseidonSMT.sol";

/**
 * @title Registration Contract
 * @dev Implements a registration system with zk-SNARKs for privacy and integrity, and a Merkle tree for registration tracking.
 */
contract Registration is IRegistration, PoseidonSMT, Initializable {
    /// The contract for registration proof verification
    IRegisterVerifier public immutable registerVerifier;

    /// The maximum depth of the Sparse Merkle Tree (SMT)
    uint256 public immutable smtTreeMaxDepth;

    /// Struct containing all relevant registration information
    RegistrationInfo public registrationInfo;

    /// Mapping to track commitments and prevent duplicate registrations
    mapping(bytes32 => bool) public commitments;

    /// Mapping to track roots and validate their existence
    mapping(bytes32 => bool) public rootsHistory;

    /**
     * @notice Initializes a new Registration contract with specified verifiers and SMT tree depth.
     * @param registerVerifier_ Address of the registration proof verifier contract.
     * @param treeHeight_ Maximum depth of the SMT used for registration tracking.
     */
    constructor(address registerVerifier_, uint256 treeHeight_) {
        registerVerifier = IRegisterVerifier(registerVerifier_);

        smtTreeMaxDepth = treeHeight_;

        _disableInitializers();
    }

    /**
     * @inheritdoc IRegistration
     */
    function __Registration_init(
        RegistrationParams calldata registrationParams_
    ) external initializer {
        __PoseidonSMT_init(smtTreeMaxDepth);

        _validateRegistrationParams(registrationParams_);

        registrationInfo.remark = registrationParams_.remark;
        registrationInfo.values.commitmentStartTime = registrationParams_.commitmentStart;
        registrationInfo.values.commitmentEndTime =
            registrationParams_.commitmentStart +
            registrationParams_.commitmentPeriod;

        emit RegistrationInitialized(msg.sender, registrationParams_);
    }

    /**
     * @inheritdoc IRegistration
     */
    function register(
        IBaseVerifier.ProveIdentityParams memory proveIdentityParams_,
        IRegisterVerifier.RegisterProofParams memory registerProofParams_,
        IBaseVerifier.TransitStateParams memory transitStateParams_,
        bool isTransitState_
    ) external {
        require(
            getRegistrationStatus() == RegistrationStatus.COMMITMENT,
            "Registration: the registration must be in the commitment state"
        );

        bytes32 commitment_ = registerProofParams_.commitment;

        require(!commitments[commitment_], "Registration: commitment already exists");

        IRegisterVerifier.RegisterProofInfo memory registerProofInfo_ = IRegisterVerifier
            .RegisterProofInfo({
                registerProofParams: registerProofParams_,
                registrationContractAddress: address(this)
            });

        if (isTransitState_) {
            registerVerifier.transitStateAndProveRegistration(
                proveIdentityParams_,
                registerProofInfo_,
                transitStateParams_
            );
        } else {
            registerVerifier.proveRegistration(proveIdentityParams_, registerProofInfo_);
        }

        _add(commitment_);
        commitments[commitment_] = true;
        rootsHistory[getRoot()] = true;
        registrationInfo.counters.totalRegistrations++;

        emit UserRegistered(msg.sender, proveIdentityParams_, registerProofParams_);
    }

    /**
     * @inheritdoc IRegistration
     */
    function isRootExists(bytes32 root) external view returns (bool) {
        return rootsHistory[root];
    }

    /**
     * @inheritdoc IRegistration
     */
    function getRegistrationInfo() external view returns (RegistrationInfo memory) {
        return registrationInfo;
    }

    /**
     * @inheritdoc IRegistration
     */
    function getRegistrationStatus() public view returns (RegistrationStatus) {
        if (registrationInfo.values.commitmentStartTime == 0) {
            return RegistrationStatus.NONE;
        }

        if (block.timestamp < registrationInfo.values.commitmentStartTime) {
            return RegistrationStatus.NOT_STARTED;
        }

        if (block.timestamp < registrationInfo.values.commitmentEndTime) {
            return RegistrationStatus.COMMITMENT;
        }

        return RegistrationStatus.ENDED;
    }

    /**
     * @inheritdoc IRegistration
     */
    function isUserRegistered(uint256 documentNullifier_) external view returns (bool) {
        return registerVerifier.isIdentityRegistered(address(this), documentNullifier_);
    }

    function _validateRegistrationParams(
        RegistrationParams calldata registrationParams_
    ) internal view {
        require(
            registrationParams_.commitmentStart > block.timestamp,
            "Registration: commitment start must be in the future"
        );
        require(
            registrationParams_.commitmentPeriod > 0,
            "Registration: commitment period must be greater than 0"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IBaseVerifier} from "../iden3/verifiers/IBaseVerifier.sol";
import {IRegisterVerifier} from "../iden3/verifiers/IRegisterVerifier.sol";

/**
 * @title IRegistration Interface
 * @dev Interface for the registration process, detailing the setup, registration for voting, and querying registration status.
 */
interface IRegistration {
    /**
     * @notice Enumeration for registration status
     */
    enum RegistrationStatus {
        NONE, // No registration created
        NOT_STARTED, // Registration created but not started
        COMMITMENT, // Commitment phase for registration
        ENDED // Registration has concluded
    }

    /**
     * @notice Struct for registration parameters configuration
     * @param remark Description or title of the registration phase
     * @param commitmentStart Timestamp for the start of the registration phase
     * @param commitmentPeriod Duration in seconds of the registration phase
     */
    struct RegistrationParams {
        string remark;
        uint256 commitmentStart;
        uint256 commitmentPeriod;
    }

    /**
     * @notice Struct for tracking registration phase timings
     * @param commitmentStartTime Start timestamp of the registration phase
     * @param commitmentEndTime End timestamp of the registration phase
     */
    struct RegistrationValues {
        uint256 commitmentStartTime;
        uint256 commitmentEndTime;
    }

    /**
     * @notice Struct for counting registrations
     * @param totalRegistrations Total number of registered users
     */
    struct RegistrationCounters {
        uint256 totalRegistrations;
    }

    /**
     * @notice Struct for detailed information about a registration phase
     * @param remark Title or description of the registration
     * @param values Timing information for the registration phases
     * @param counters Count of registered users
     */
    struct RegistrationInfo {
        string remark;
        RegistrationValues values;
        RegistrationCounters counters;
    }

    /**
     * @notice Emitted when a new registration is initialized
     * @param proposer Address of the proposer initializing the registration. Usually the factory contract
     * @param registrationParams Struct containing the parameters of the registration phase
     */
    event RegistrationInitialized(address indexed proposer, RegistrationParams registrationParams);

    /**
     * @notice Emitted when a user successfully registers
     * @param user Address of the user registering
     * @param proveIdentityParams Parameters used for proving the user's identity
     * @param registerProofParams Parameters used for the registration proof
     */
    event UserRegistered(
        address indexed user,
        IBaseVerifier.ProveIdentityParams proveIdentityParams,
        IRegisterVerifier.RegisterProofParams registerProofParams
    );

    /**
     * @notice Initializes a new registration session with specified parameters
     * @param registrationParams_ The parameters for the registration session, including start times, and periods.
     */
    function __Registration_init(RegistrationParams calldata registrationParams_) external;

    /**
     * @notice Registers a user, verifying their identity and registration proof
     * @dev Requires the voting to be in the registration phase. Emits a UserRegistered event upon success.
     * @param proveIdentityParams_ Parameters to prove the user's identity.
     * @param registerProofParams_ Parameters for the user's registration proof.
     * @param transitStateParams_ Parameters for state transition, if applicable.
     * @param isTransitState_ Flag indicating whether a state transition is required.
     */
    function register(
        IBaseVerifier.ProveIdentityParams memory proveIdentityParams_,
        IRegisterVerifier.RegisterProofParams memory registerProofParams_,
        IBaseVerifier.TransitStateParams memory transitStateParams_,
        bool isTransitState_
    ) external;

    /**
     * @notice Checks if the Merkle tree root exists
     * @param root The root of the Merkle tree
     * @return True if the root exists, false otherwise
     */
    function isRootExists(bytes32 root) external view returns (bool);

    /**
     * @notice Retrieves the registration information
     * @return RegistrationInfo Struct containing detailed information about the registration phase
     */
    function getRegistrationInfo() external view returns (RegistrationInfo memory);

    /**
     * @notice Retrieves the current status of the registration phase
     */
    function getRegistrationStatus() external view returns (RegistrationStatus);

    /**
     * @notice Checks if a user is already registered
     * @param documentNullifier_ The nullifier of the user's document
     * @return True if the user is already registered, false otherwise
     */
    function isUserRegistered(uint256 documentNullifier_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IState} from "@iden3/contracts/interfaces/IState.sol";

/**
 * @dev This contract is a copy of the ILightweightState contract from Rarimo [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).
 */
interface ILightweightState {
    enum MethodId {
        None,
        AuthorizeUpgrade,
        ChangeSourceStateContract
    }

    struct GistRootData {
        uint256 root;
        uint256 createdAtTimestamp;
    }

    struct IdentitiesStatesRootData {
        bytes32 root;
        uint256 setTimestamp;
    }

    struct StatesMerkleData {
        uint256 issuerId;
        uint256 issuerState;
        uint256 createdAtTimestamp;
        bytes32[] merkleProof;
    }

    event SignedStateTransited(uint256 newGistRoot, bytes32 newIdentitesStatesRoot);

    function changeSourceStateContract(
        address newSourceStateContract_,
        bytes calldata signature_
    ) external;

    function changeSigner(bytes calldata newSignerPubKey_, bytes calldata signature_) external;

    function signedTransitState(
        bytes32 newIdentitiesStatesRoot_,
        GistRootData calldata gistData_,
        bytes calldata proof_
    ) external;

    function sourceStateContract() external view returns (address);

    function sourceChainName() external view returns (string memory);

    function identitiesStatesRoot() external view returns (bytes32);

    function isIdentitiesStatesRootExists(bytes32 root_) external view returns (bool);

    function getIdentitiesStatesRootData(
        bytes32 root_
    ) external view returns (IdentitiesStatesRootData memory);

    function getGISTRoot() external view returns (uint256);

    function getCurrentGISTRootInfo() external view returns (GistRootData memory);

    function geGISTRootData(uint256 root_) external view returns (GistRootData memory);

    function verifyStatesMerkleData(
        StatesMerkleData calldata statesMerkleData_
    ) external view returns (bool, bytes32);
}

// This contract is a copy of the IZKPQueriesStorage contract from Rarimo
// [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ILightweightState} from "./ILightweightState.sol";

/**
 * @title IZKPQueriesStorage
 * @notice The IZKPQueriesStorage interface represents a contract that is responsible for storing and managing zero-knowledge proof (ZKP) queries.
 * It provides functions to set, retrieve, and remove ZKP queries from the storage.
 */
interface IZKPQueriesStorage {
    struct CircuitQuery {
        uint256 schema;
        uint8 slotIndex;
        uint8 operator;
        uint256 claimPathKey;
        uint256 claimPathNotExists;
        uint256[] values;
    }

    /**
     * @notice Contains the query information, including the circuit query and query validator
     * @param circuitQuery The circuit query
     * @param queryValidator The query validator
     * @param circuitId The circuit ID
     */
    struct QueryInfo {
        CircuitQuery circuitQuery;
        address queryValidator;
        string circuitId;
    }

    /**
     * @notice Event emitted when a ZKP query is set
     * @param queryId The ID of the query
     * @param queryValidator The address of the query validator
     * @param newCircuitQuery The new circuit query
     */
    event ZKPQuerySet(
        string indexed queryId,
        address queryValidator,
        CircuitQuery newCircuitQuery
    );

    /**
     * @notice Event emitted when a ZKP query is removed
     * @param queryId The ID of the query
     */
    event ZKPQueryRemoved(string indexed queryId);

    /**
     * @notice Function that set a ZKP query with the provided query ID and query information
     * @param queryId_ The query ID
     * @param queryInfo_ The query information
     */
    function setZKPQuery(string memory queryId_, QueryInfo memory queryInfo_) external;

    /**
     * @notice Function that remove a ZKP query with the specified query ID
     * @param queryId_ The query ID
     */
    function removeZKPQuery(string memory queryId_) external;

    function lightweightState() external view returns (ILightweightState);

    /**
     * @notice Function to get the supported query IDs
     * @return The array of supported query IDs
     */
    function getSupportedQueryIDs() external view returns (string[] memory);

    /**
     * @notice Function to get the query information for a given query ID
     * @param queryId_ The query ID
     * @return The QueryInfo structure with query information
     */
    function getQueryInfo(string memory queryId_) external view returns (QueryInfo memory);

    /**
     * @notice Function to get the query validator for a given query ID
     * @param queryId_ The query ID
     * @return The query validator contract address
     */
    function getQueryValidator(string memory queryId_) external view returns (address);

    /**
     * @notice Function to get the stored circuit query for a given query ID
     * @param queryId_ The query ID
     * @return The stored CircuitQuery structure
     */
    function getStoredCircuitQuery(
        string memory queryId_
    ) external view returns (CircuitQuery memory);

    /**
     * @notice Function to get the stored query hash for a given query ID
     * @param queryId_ The query ID
     * @return The stored query hash
     */
    function getStoredQueryHash(string memory queryId_) external view returns (uint256);

    /**
     * @notice Function to get the stored schema for a given query ID
     * @param queryId_ The query ID
     * @return The stored schema id
     */
    function getStoredSchema(string memory queryId_) external view returns (uint256);

    /**
     * @notice Function to check if a query exists for the given query ID
     * @param queryId_ The query ID
     * @return A boolean indicating whether the query exists
     */
    function isQueryExists(string memory queryId_) external view returns (bool);

    /**
     * @notice Function to get the query hash for the provided circuit query
     * @param circuitQuery_ The circuit query
     * @return The query hash
     */
    function getQueryHash(CircuitQuery memory circuitQuery_) external view returns (uint256);

    /**
     * @notice Function to get the query hash for the raw values
     * @param schema_ The schema id
     * @param slotIndex_ The slot index
     * @param operator_ The query operator
     * @param claimPathKey_ The claim path key
     * @param claimPathNotExists_ The claim path not exists
     * @param values_ The values array
     * @return The query hash
     */
    function getQueryHashRaw(
        uint256 schema_,
        uint256 slotIndex_,
        uint256 operator_,
        uint256 claimPathKey_,
        uint256 claimPathNotExists_,
        uint256[] memory values_
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IZKPQueriesStorage} from "../IZKPQueriesStorage.sol";

import {ILightweightState} from "../ILightweightState.sol";

/**
 * @dev This contract is a copy of the IBaseVerifier contract from Rarimo [identity-contracts repository](https://github.com/rarimo/identity-contracts/tree/aeb929ccc3fa8ab508fd7576f9fa853a081e5010).
 */
interface IBaseVerifier {
    struct ProveIdentityParams {
        ILightweightState.StatesMerkleData statesMerkleData;
        uint256[] inputs;
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct TransitStateParams {
        bytes32 newIdentitiesStatesRoot;
        ILightweightState.GistRootData gistData;
        bytes proof;
    }

    function setZKPQueriesStorage(IZKPQueriesStorage newZKPQueriesStorage_) external;

    function updateAllowedIssuers(
        uint256 schema_,
        uint256[] memory issuerIds_,
        bool isAdding_
    ) external;

    function zkpQueriesStorage() external view returns (IZKPQueriesStorage);

    function getAllowedIssuers(uint256 schema_) external view returns (uint256[] memory);

    function isAllowedIssuer(uint256 schema_, uint256 issuerId_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IBaseVerifier} from "./IBaseVerifier.sol";
import {ILightweightState} from "../ILightweightState.sol";

/**
 * @title IRegisterVerifier
 * @notice Interface for the RegisterVerifier contract.
 */
interface IRegisterVerifier is IBaseVerifier {
    /**
     * @notice Struct to hold parameters for registration proof.
     * @param issuingAuthority The identifier for the issuing authority.
     * @param documentNullifier The unique nullifier for the document to prevent double registration.
     * @param commitment A commitment hash representing the registered identity.
     */
    struct RegisterProofParams {
        uint256 issuingAuthority;
        uint256 documentNullifier;
        bytes32 commitment;
    }

    /**
     * @notice Struct to encapsulate registration proof parameters along with the voting address.
     * @param registerProofParams The registration proof parameters.
     * @param registrationContractAddress The address of the registration contract.
     */
    struct RegisterProofInfo {
        RegisterProofParams registerProofParams;
        address registrationContractAddress;
    }

    /**
     * @notice Emitted when a registration is accepted.
     * @param documentNullifier The unique nullifier for the document.
     * @param registerProofInfo The information regarding the registration proof.
     */
    event RegisterAccepted(uint256 documentNullifier, RegisterProofInfo registerProofInfo);

    /**
     * @notice Proves registration with given parameters.
     * @param proveIdentityParams_ Parameters required for proving identity.
     * @param registerProofInfo_ The registration proof information.
     */
    function proveRegistration(
        ProveIdentityParams memory proveIdentityParams_,
        RegisterProofInfo memory registerProofInfo_
    ) external;

    /**
     * @notice Transitions state and proves registration with given parameters.
     * @param proveIdentityParams_ Parameters required for proving identity.
     * @param registerProofInfo_ The registration proof information.
     * @param transitStateParams_ Parameters required for state transition.
     */
    function transitStateAndProveRegistration(
        ProveIdentityParams memory proveIdentityParams_,
        RegisterProofInfo memory registerProofInfo_,
        TransitStateParams memory transitStateParams_
    ) external;

    /**
     * @notice Retrieves registration proof information for a given document nullifier.
     * @param registrationContract_ The address of the registration contract.
     * @param documentNullifier_ The unique nullifier for the document.
     * @return RegisterProofInfo The registration proof information.
     */
    function getRegisterProofInfo(
        address registrationContract_,
        uint256 documentNullifier_
    ) external view returns (RegisterProofInfo memory);

    /**
     * @notice Checks if an identity is registered.
     * @param registrationContract_ The address of the registration contract.
     * @param documentNullifier_ The unique nullifier for the document.
     * @return bool True if the identity is registered, false otherwise.
     */
    function isIdentityRegistered(
        address registrationContract_,
        uint256 documentNullifier_
    ) external view returns (bool);

    /**
     * @notice Checks if an issuing authority is whitelisted.
     * @param issuingAuthority_ The identifier for the issuing authority.
     * @return bool True if the issuing authority is whitelisted, false otherwise.
     */
    function isIssuingAuthorityWhitelisted(uint256 issuingAuthority_) external view returns (bool);

    /**
     * @notice Checks if an issuing authority is blacklisted.
     * @param issuingAuthority_ The identifier for the issuing authority.
     * @return bool True if the issuing authority is blacklisted, false otherwise.
     */
    function isIssuingAuthorityBlacklisted(uint256 issuingAuthority_) external view returns (bool);

    /**
     * @notice Returns the number of issuing authorities in the whitelist.
     */
    function countIssuingAuthorityWhitelist() external view returns (uint256);

    /**
     * @notice Returns the number of issuing authorities in the blacklist.
     */
    function countIssuingAuthorityBlacklist() external view returns (uint256);

    /**
     * @notice Returns a list of issuing authorities in the whitelist.
     * @param offset_ The offset from which to start fetching the list.
     * @param limit_ The maximum number of items to fetch.
     * @return uint256[] The list of issuing authorities in the whitelist.
     */
    function listIssuingAuthorityWhitelist(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory);

    /**
     * @notice Returns a list of issuing authorities in the blacklist.
     * @param offset_ The offset from which to start fetching the list.
     * @param limit_ The maximum number of items to fetch.
     * @return uint256[] The list of issuing authorities in the blacklist.
     */
    function listIssuingAuthorityBlacklist(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {SparseMerkleTree} from "@solarity/solidity-lib/libs/data-structures/SparseMerkleTree.sol";

import {PoseidonUnit1L, PoseidonUnit2L, PoseidonUnit3L} from "@iden3/contracts/lib/Poseidon.sol";

contract PoseidonSMT {
    using SparseMerkleTree for SparseMerkleTree.Bytes32SMT;

    SparseMerkleTree.Bytes32SMT internal bytes32Tree;

    function __PoseidonSMT_init(uint256 treeHeight_) internal {
        bytes32Tree.initialize(uint32(treeHeight_));
        bytes32Tree.setHashers(_hash2, _hash3);
    }

    function getProof(bytes32 key_) external view returns (SparseMerkleTree.Proof memory) {
        return bytes32Tree.getProof(key_);
    }

    function getRoot() public view returns (bytes32) {
        return bytes32Tree.getRoot();
    }

    function getNodeByKey(bytes32 key_) public view returns (SparseMerkleTree.Node memory) {
        return bytes32Tree.getNodeByKey(key_);
    }

    function _add(bytes32 element_) internal {
        bytes32 keyOfElement = _hash1(element_);

        bytes32Tree.add(keyOfElement, element_);
    }

    function _hash1(bytes32 element1_) internal pure returns (bytes32) {
        return bytes32(PoseidonUnit1L.poseidon([uint256(element1_)]));
    }

    function _hash2(bytes32 element1_, bytes32 element2_) internal pure returns (bytes32) {
        return bytes32(PoseidonUnit2L.poseidon([uint256(element1_), uint256(element2_)]));
    }

    function _hash3(
        bytes32 element1_,
        bytes32 element2_,
        bytes32 element3_
    ) internal pure returns (bytes32) {
        return
            bytes32(
                PoseidonUnit3L.poseidon(
                    [uint256(element1_), uint256(element2_), uint256(element3_)]
                )
            );
    }
}