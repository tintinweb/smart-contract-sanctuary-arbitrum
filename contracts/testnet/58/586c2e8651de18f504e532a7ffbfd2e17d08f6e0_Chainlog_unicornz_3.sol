// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Auth} from "chronicle-std/auth/Auth.sol";

import {IChainlog} from "src/IChainlog.sol";

/**
 * @title Chainlog
 *
 * @notice Chainlog provides a public readable contract registry
 *
 * @dev The contract uses the `chronicle-std/Auth` module for access control.
 *      While the registry is public readable, state mutating functions are only
 *      callable by auth'ed addresses.
 */
contract Chainlog_unicornz_3 is IChainlog, Auth {
    struct Location {
        uint pos;
        address addr;
    }

    /// @inheritdoc IChainlog
    string public version;

    /// @inheritdoc IChainlog
    string public sha256sum;

    /// @inheritdoc IChainlog
    string public ipfs;

    /// @dev Mapping storing a key's position and address.
    /// @custom:invariant Location's `pos` is not mutated after being set.
    ///                     ∀x ∊ bytes32: pos = preTx(_locations[x].pos) ⋀ pos != 0
    ///                         → postTx(_locations[x].pos == pos)
    mapping(bytes32 => Location) private _locations;

    /// @dev List of known keys.
    /// @custom:invariant Does not contain duplicates.
    ///                     ∀x ∊ bytes32: _keys.count(x) <= 1
    /// @custom:invariant Each non-empty key links to an address in _locations.
    ///                     ∀x ∊ bytes32: _keys.count(x) > 0 ⋀ x != ""
    ///                         → _locations[x].addr != address(0)
    /// @custom:invariant Elements may only be added, never deleted or mutated.
    ///                     ∀x ∊ [0, _keys.length-1]:
    ///                         preTx(_keys[x]) == postTx(_keys[x])
    /// @custom:invariant Zero index links to empty key.
    ///                     _keys[0] = ""
    bytes32[] private _keys;

    constructor(address initialAuthed) Auth(initialAuthed) {
        // Let _keys[0] = "";
        _keys.push("");

        _setVersion("0.0.0");
        _setAddress("CHANGELOG", address(this));
    }

    /// @inheritdoc IChainlog
    function setVersion(string memory version_) external auth {
        _setVersion(version_);
    }

    function _setVersion(string memory version_) internal {
        if (!equal(version, version_)) {
            emit VersionUpdated(msg.sender, version, version_);
            version = version_;
        }
    }

    /// @inheritdoc IChainlog
    function setSha256sum(string memory sha256sum_) external auth {
        if (!equal(sha256sum, sha256sum_)) {
            emit Sha256sumUpdated(msg.sender, sha256sum, sha256sum_);
            sha256sum = sha256sum_;
        }
    }

    /// @inheritdoc IChainlog
    function setIPFS(string memory ipfs_) external auth {
        if (!equal(ipfs, ipfs_)) {
            emit IPFSUpdated(msg.sender, ipfs, ipfs_);
            ipfs = ipfs_;
        }
    }

    /// @inheritdoc IChainlog
    function setAddress(bytes32 key, address addr) external auth {
        _setAddress(key, addr);
    }

    function _setAddress(bytes32 key, address addr) internal {
        if (key == "") {
            revert EmptyKey();
        }

        // Get reference to key's location instance.
        Location storage keyLoc = _locations[key];

        // Assign position to key, if key unknown.
        if (keyLoc.pos == 0) {
            _keys.push(key);
            keyLoc.pos = _keys.length - 1;
        }

        // Update key's address, if necessary.
        if (keyLoc.addr != addr) {
            emit AddressUpdated(msg.sender, key, keyLoc.addr, addr);
            keyLoc.addr = addr;
        }
    }

    /// @inheritdoc IChainlog
    function get(bytes32 key) external view returns (address) {
        if (!exists(key)) {
            revert UnknownKey(key);
        }

        return _locations[key].addr;
    }

    /// @inheritdoc IChainlog
    function tryGet(bytes32 key) external view returns (bool, address) {
        if (exists(key)) {
            return (true, _locations[key].addr);
        } else {
            return (false, address(0));
        }
    }

    /// @inheritdoc IChainlog
    /// @custom:invariant Contains every key for which a non-zero address is set.
    ///                     ∀x ∊ _keys: _locations[x].addr != address(0)
    ///                         → x ∊ list()
    function list() public view returns (bytes32[] memory) {
        // Initiate array with upper limit length.
        bytes32[] memory keys = new bytes32[](_keys.length);

        // Iterate through all known keys.
        uint ctr;
        for (uint i; i < keys.length; i++) {
            // Add key only if key still exists.
            if (exists(_keys[i])) {
                keys[ctr++] = _keys[i];
            }
        }

        // Set length of array to number of keys actually included.
        assembly ("memory-safe") {
            mstore(keys, ctr)
        }

        return keys;
    }

    /// @inheritdoc IChainlog
    /// @custom:invariant Equals list() if start is zero and size big enough to
    ///                   hold all keys.
    ///                     start = 0 ⋀ size >= _keys.length
    ///                         → list(start, size) == list()
    function list(uint start, uint size)
        external
        view
        returns (bytes32[] memory)
    {
        // Initiate array with upper limit length.
        bytes32[] memory keys = new bytes32[](size);

        // Iterate over up to size known keys, starting at start.
        uint ctr;
        uint i = start;
        while (i <= start + size && i < _keys.length) {
            // Add key only if key still exists.
            if (exists(_keys[i])) {
                keys[ctr++] = _keys[i];
            }

            i++;
        }

        // Set length of array to number of keys actually included.
        assembly ("memory-safe") {
            mstore(keys, ctr)
        }

        return keys;
    }

    /// @inheritdoc IChainlog
    /// @custom:invariant Equals the number of keys returned via list().
    ///                     count() == list().length
    function count() external view returns (uint) {
        // Iterate through all known keys.
        uint ctr;
        for (uint i; i < _keys.length; i++) {
            // Increase counter if key exists.
            if (exists(_keys[i])) {
                ctr++;
            }
        }

        return ctr;
    }

    /// @inheritdoc IChainlog
    function exists(bytes32 key) public view returns (bool) {
        return _locations[key].addr != address(0);
    }

    // -- Helpers --

    function equal(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAuth} from "./IAuth.sol";

/**
 * @title Auth Module
 *
 * @dev The `Auth` contract module provides a basic access control mechanism,
 *      where a set of addresses are granted access to protected functions.
 *      These addresses are said to be _auth'ed_.
 *
 *      Initially, the address given as constructor argument is the only address
 *      auth'ed. Through the `rely(address)` and `deny(address)` functions,
 *      auth'ed callers are able to grant/renounce auth to/from addresses.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `auth`, which can be applied to functions to restrict their
 *      use to only auth'ed callers.
 */
abstract contract Auth is IAuth {
    /// @dev Mapping storing whether address is auth'ed.
    /// @custom:invariant Image of mapping is {0, 1}.
    ///                     ∀x ∊ Address: _wards[x] ∊ {0, 1}
    /// @custom:invariant Only address given as constructor argument is authenticated after deployment.
    ///                     deploy(initialAuthed) → (∀x ∊ Address: _wards[x] == 1 → x == initialAuthed)
    /// @custom:invariant Only functions `rely` and `deny` may mutate the mapping's state.
    ///                     ∀x ∊ Address: preTx(_wards[x]) != postTx(_wards[x])
    ///                                     → (msg.sig == "rely" ∨ msg.sig == "deny")
    /// @custom:invariant Mapping's state may only be mutated by authenticated caller.
    ///                     ∀x ∊ Address: preTx(_wards[x]) != postTx(_wards[x]) → _wards[msg.sender] = 1
    mapping(address => uint) private _wards;

    /// @dev List of addresses possibly being auth'ed.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being auth'ed anymore.
    /// @custom:invariant Every address being auth'ed once is element of the list.
    ///                     ∀x ∊ Address: authed(x) -> x ∊ _wardsTouched
    address[] private _wardsTouched;

    /// @dev Ensures caller is auth'ed.
    modifier auth() {
        assembly ("memory-safe") {
            // Compute slot of _wards[msg.sender].
            mstore(0x00, caller())
            mstore(0x20, _wards.slot)
            let slot := keccak256(0x00, 0x40)

            // Revert if caller not auth'ed.
            let isAuthed := sload(slot)
            if iszero(isAuthed) {
                // Store selector of `NotAuthorized(address)`.
                mstore(0x00, 0x4a0bfec1)
                // Store msg.sender.
                mstore(0x20, caller())
                // Revert with (offset, size).
                revert(0x1c, 0x24)
            }
        }
        _;
    }

    constructor(address initialAuthed) {
        _wards[initialAuthed] = 1;
        _wardsTouched.push(initialAuthed);

        // Note to use address(0) as caller to indicate address was auth'ed
        // during deployment.
        emit AuthGranted(address(0), initialAuthed);
    }

    /// @inheritdoc IAuth
    function rely(address who) external auth {
        if (_wards[who] == 1) return;

        _wards[who] = 1;
        _wardsTouched.push(who);
        emit AuthGranted(msg.sender, who);
    }

    /// @inheritdoc IAuth
    function deny(address who) external auth {
        if (_wards[who] == 0) return;

        _wards[who] = 0;
        emit AuthRenounced(msg.sender, who);
    }

    /// @inheritdoc IAuth
    function authed(address who) public view returns (bool) {
        return _wards[who] == 1;
    }

    /// @inheritdoc IAuth
    /// @custom:invariant Only contains auth'ed addresses.
    ///                     ∀x ∊ authed(): _wards[x] == 1
    /// @custom:invariant Contains all auth'ed addresses.
    ///                     ∀x ∊ Address: _wards[x] == 1 → x ∊ authed()
    function authed() public view returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory wardsList = new address[](_wardsTouched.length);

        // Iterate through all possible auth'ed addresses.
        uint ctr;
        for (uint i; i < wardsList.length; i++) {
            // Add address only if still auth'ed.
            if (_wards[_wardsTouched[i]] == 1) {
                wardsList[ctr++] = _wardsTouched[i];
            }
        }

        // Set length of array to number of auth'ed addresses actually included.
        assembly ("memory-safe") {
            mstore(wardsList, ctr)
        }

        return wardsList;
    }

    /// @inheritdoc IAuth
    function wards(address who) public view returns (uint) {
        return _wards[who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IChainlog {
    /// @notice Thrown if given key unknown.
    /// @param key The unknown key given.
    error UnknownKey(bytes32 key);

    /// @notice Thrown if empty key given.
    error EmptyKey();

    /// @notice Emitted when an address updated.
    /// @param caller The caller's address.
    /// @param key The key of the address updated.
    /// @param oldAddr The old address.
    /// @param newAddr The new address.
    event AddressUpdated(
        address indexed caller,
        bytes32 indexed key,
        address oldAddr,
        address newAddr
    );

    /// @notice Emitted when version identifier updated.
    /// @param caller The caller's address.
    /// @param oldVersion The old version identifier.
    /// @param newVersion The new version identifier.
    event VersionUpdated(
        address indexed caller, string oldVersion, string newVersion
    );

    /// @notice Emitted when sha256sum identifier updated.
    /// @param caller The caller's address.
    /// @param oldSha256sum The old sha256sum identifier.
    /// @param newSha256sum The new sha256sum identifier.
    event Sha256sumUpdated(
        address indexed caller, string oldSha256sum, string newSha256sum
    );

    /// @notice Emitted when IPFS identifier updated.
    /// @param caller The caller's address.
    /// @param oldIPFS The old ipfs identifier.
    /// @param newIPFS The new ipfs identifier.
    event IPFSUpdated(address indexed caller, string oldIPFS, string newIPFS);

    /// @notice Updates `key'`s address to `addr`.
    /// @dev Only callable by auth'ed address.
    /// @param key The key to update.
    /// @param addr The address to set for `key`.
    function setAddress(bytes32 key, address addr) external;

    /// @notice Updates version identifier to `version`.
    /// @dev Only callable by auth'ed address.
    /// @param version The value to update version to.
    function setVersion(string memory version) external;

    /// @notice Updates sha256sum identifier to `sha256sum`.
    /// @dev Only callable by auth'ed address.
    /// @param sha256sum The value to update sha256sum to.
    function setSha256sum(string memory sha256sum) external;

    /// @notice Updates IPFS identifier to `ipfs`.
    /// @dev Only callable by auth'ed address.
    /// @param ipfs The value to update ipfs to.
    function setIPFS(string memory ipfs) external;

    /// @notice Returns the address set for key `key`.
    /// @dev Reverts if key unknown.
    /// @param key The key to return its address.
    function get(bytes32 key) external view returns (address);

    /// @notice Returns the address set for key `key`.
    /// @param key The key to return its address.
    /// @return True if key `key` exists, false otherwise.
    /// @return The address of key `key` if `key` exists, zero address
    ///         otherwise.
    function tryGet(bytes32 key) external view returns (bool, address);

    /// @notice Returns the list of keys for which a non-zero address is set.
    /// @dev May reverts if number of keys is too large.
    ///      If so, use list(uint,uint)(bytes32) to read keys in pages.
    /// @return The list existing keys.
    function list() external view returns (bytes32[] memory);

    /// @notice Returns the paginated list of keys starting with index `start`
    ///         and maximum size `size`.
    /// @dev Use this function to read keys paginated.
    /// @return The list of existing keys, paginated via `start` and `size`.
    function list(uint start, uint size)
        external
        view
        returns (bytes32[] memory);

    /// @notice Returns the number of keys existing.
    /// @return The number of keys existing.
    function count() external view returns (uint);

    /// @notice Returns whether key `key` exists.
    /// @return True if key `key` exists, false otherwise.
    function exists(bytes32 key) external view returns (bool);

    /// @notice Returns the chainlog's version identifier.
    /// @return The chainlog's version identifier.
    function version() external view returns (string memory);

    /// @notice Returns the chainlog's sha256sum identifier.
    /// @return The chainlog's sha256sum identifier.
    function sha256sum() external view returns (string memory);

    /// @notice Returns the chainlog's IPFS identifier.
    /// @return The chainlog's IPFS identifier.
    function ipfs() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAuth {
    /// @notice Thrown by protected function if caller not auth'ed.
    /// @param caller The caller's address.
    error NotAuthorized(address caller);

    /// @notice Emitted when auth granted to address.
    /// @param caller The caller's address.
    /// @param who The address auth got granted to.
    event AuthGranted(address indexed caller, address indexed who);

    /// @notice Emitted when auth renounced from address.
    /// @param caller The caller's address.
    /// @param who The address auth got renounced from.
    event AuthRenounced(address indexed caller, address indexed who);

    /// @notice Grants address `who` auth.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to grant auth.
    function rely(address who) external;

    /// @notice Renounces address `who`'s auth.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to renounce auth.
    function deny(address who) external;

    /// @notice Returns whether address `who` is auth'ed.
    /// @param who The address to check.
    /// @return True if `who` is auth'ed, false otherwise.
    function authed(address who) external view returns (bool);

    /// @notice Returns full list of addresses granted auth.
    /// @dev May contain duplicates.
    /// @return List of addresses granted auth.
    function authed() external view returns (address[] memory);

    /// @notice Returns whether address `who` is auth'ed.
    /// @custom:deprecated Use `authed(address)(bool)` instead.
    /// @param who The address to check.
    /// @return 1 if `who` is auth'ed, 0 otherwise.
    function wards(address who) external view returns (uint);
}