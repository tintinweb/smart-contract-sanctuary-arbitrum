// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Auth} from "chronicle-std/auth/Auth.sol";
import {Toll} from "chronicle-std/toll/Toll.sol";

import {IGreenhouse} from "./IGreenhouse.sol";

import {LibCREATE3} from "./libs/LibCREATE3.sol";

/**
 * @title Greenhouse
 * @custom:version 1.0.0
 *
 * @notice A greenhouse to plant contracts using CREATE3
 *
 * @dev Greenhouse is a contract factory planting contracts at deterministic
 *      addresses. The address of the planted contract solely depends on the
 *      provided salt.
 *
 *      The contract uses `chronicle-std`'s `Auth` module to grant addresses
 *      access to protected functions. `chronicle-std`'s `Toll` module is
 *      utilized to determine which addresses are eligible to plant new
 *      contracts. Note that auth'ed addresses are _not_ eligible to plant new
 *      contracts.
 */
contract Greenhouse is IGreenhouse, Auth, Toll {
    constructor(address initialAuthed) Auth(initialAuthed) {}

    /// @inheritdoc IGreenhouse
    ///
    /// @custom:invariant Planted contract's address is deterministic and solely
    ///                   depends on `salt`.
    ///                     ∀s ∊ bytes32: plant(s, _) = addressOf(s)
    function plant(bytes32 salt, bytes memory creationCode)
        external
        toll
        returns (address)
    {
        if (salt == bytes32(0)) {
            revert EmptySalt();
        }
        if (creationCode.length == 0) {
            revert EmptyCreationCode();
        }

        if (addressOf(salt).code.length != 0) {
            revert AlreadyPlanted(salt);
        }

        bool ok;
        address addr;
        (ok, addr) = LibCREATE3.tryDeploy(salt, creationCode);
        if (!ok) {
            revert PlantingFailed(salt);
        }
        // assert(addr == addressOf(salt));

        emit Planted(msg.sender, salt, addr);

        return addr;
    }

    /// @inheritdoc IGreenhouse
    function addressOf(bytes32 salt) public view returns (address) {
        return LibCREATE3.addressOf(salt);
    }

    /// @dev Defines authorization for IToll's authenticated functions.
    function toll_auth() internal override(Toll) auth {}
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

import {IToll} from "./IToll.sol";

/**
 * @title Toll Module
 *
 * @notice "Toll paid, we kiss - but dissension looms, maybe diss?"
 *
 * @dev The `Toll` contract module provides a basic access control mechanism,
 *      where a set of addresses are granted access to protected functions.
 *      These addresses are said the be _tolled_.
 *
 *      Initially, no address is tolled. Through the `kiss(address)` and
 *      `diss(address)` functions, auth'ed callers are able to toll/de-toll
 *      addresses. Authentication for these functions is defined via the
 *      downstream implemented `toll_auth()` function.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `toll`, which can be applied to functions to restrict their
 *      use to only tolled callers.
 */
abstract contract Toll is IToll {
    /// @dev Mapping storing whether address is tolled.
    /// @custom:invariant Image of mapping is {0, 1}.
    ///                     ∀x ∊ Address: _buds[x] ∊ {0, 1}
    /// @custom:invariant Only functions `kiss` and `diss` may mutate the mapping's state.
    ///                     ∀x ∊ Address: preTx(_buds[x]) != postTx(_buds[x])
    ///                                     → (msg.sig == "kiss" ∨ msg.sig == "diss")
    /// @custom:invariant Mapping's state may only be mutated by authenticated caller.
    ///                     ∀x ∊ Address: preTx(_buds[x]) != postTx(_buds[x])
    ///                                     → toll_auth()
    mapping(address => uint) private _buds;

    /// @dev List of addresses possibly being tolled.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being tolled anymore.
    /// @custom:invariant Every address being tolled once is element of the list.
    ///                     ∀x ∊ Address: tolled(x) → x ∊ _budsTouched
    address[] private _budsTouched;

    /// @dev Ensures caller is tolled.
    modifier toll() {
        assembly ("memory-safe") {
            // Compute slot of _buds[msg.sender].
            mstore(0x00, caller())
            mstore(0x20, _buds.slot)
            let slot := keccak256(0x00, 0x40)

            // Revert if caller not tolled.
            let isTolled := sload(slot)
            if iszero(isTolled) {
                // Store selector of `NotTolled(address)`.
                mstore(0x00, 0xd957b595)
                // Store msg.sender.
                mstore(0x20, caller())
                // Revert with (offset, size).
                revert(0x1c, 0x24)
            }
        }
        _;
    }

    /// @dev Reverts if caller not allowed to access protected function.
    /// @dev Must be implemented in downstream contract.
    function toll_auth() internal virtual;

    /// @inheritdoc IToll
    function kiss(address who) external {
        toll_auth();

        if (_buds[who] == 1) return;

        _buds[who] = 1;
        _budsTouched.push(who);
        emit TollGranted(msg.sender, who);
    }

    /// @inheritdoc IToll
    function diss(address who) external {
        toll_auth();

        if (_buds[who] == 0) return;

        _buds[who] = 0;
        emit TollRenounced(msg.sender, who);
    }

    /// @inheritdoc IToll
    function tolled(address who) public view returns (bool) {
        return _buds[who] == 1;
    }

    /// @inheritdoc IToll
    /// @custom:invariant Only contains tolled addresses.
    ///                     ∀x ∊ tolled(): _tolled[x]
    /// @custom:invariant Contains all tolled addresses.
    ///                     ∀x ∊ Address: _tolled[x] == 1 → x ∊ tolled()
    function tolled() public view returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory budsList = new address[](_budsTouched.length);

        // Iterate through all possible tolled addresses.
        uint ctr;
        for (uint i; i < budsList.length; i++) {
            // Add address only if still tolled.
            if (_buds[_budsTouched[i]] == 1) {
                budsList[ctr++] = _budsTouched[i];
            }
        }

        // Set length of array to number of tolled addresses actually included.
        assembly ("memory-safe") {
            mstore(budsList, ctr)
        }

        return budsList;
    }

    /// @inheritdoc IToll
    function bud(address who) public view returns (uint) {
        return _buds[who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IGreenhouse {
    /// @notice Thrown if salt `salt` already planted.
    /// @param salt The salt to plant.
    error AlreadyPlanted(bytes32 salt);

    /// @notice Thrown if planting at salt `salt` failed.
    /// @param salt The salt to plant.
    error PlantingFailed(bytes32 salt);

    /// @notice Thrown if provided salt is empty.
    error EmptySalt();

    /// @notice Thrown if provided creation code is empty.
    error EmptyCreationCode();

    /// @notice Emitted when new contract planted.
    /// @param caller The caller's address.
    /// @param salt The salt the contract got planted at.
    /// @param addr The address of the planted contract.
    event Planted(
        address indexed caller, bytes32 indexed salt, address indexed addr
    );

    /// @notice Plants a new contract with creation code `creationCode` to a
    ///         deterministic address solely depending on the salt `salt`.
    ///
    /// @dev Only callable by toll'ed addresses.
    ///
    /// @dev Note to add constructor arguments to the creation code, if
    ///      applicable!
    ///
    /// @custom:example Appending constructor arguments to the creation code:
    ///
    ///     ```solidity
    ///     bytes memory creationCode = abi.encodePacked(
    ///         // Receive the creation code of `MyContract`.
    ///         type(MyContract).creationCode,
    ///
    ///         // `MyContract` receives as constructor arguments an address
    ///         // and a uint.
    ///         abi.encode(address(0xcafe), uint(1))
    ///     );
    ///     ```
    ///
    /// @param salt The salt to plant the contract at.
    /// @param creationCode The creation code of the contract to plant.
    /// @return The address of the planted contract.
    function plant(bytes32 salt, bytes memory creationCode)
        external
        returns (address);

    /// @notice Returns the deterministic address for salt `salt`.
    /// @dev Note that the address is not guaranteed to be utilized yet.
    ///
    /// @custom:example Verifying a contract is planted at some salt:
    ///
    ///     ```solidity
    ///     bytes32 salt = bytes32("salt");
    ///     address contract_ = addressOf(salt);
    ///     bool isPlanted = contract_.code.length != 0;
    ///     ```
    ///
    /// @param salt The salt to query their deterministic address.
    /// @return The deterministic address for given salt.
    function addressOf(bytes32 salt) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title LibCREATE3
 *
 * @notice Library to deploy to deterministic addresses without an initcode
 *         factor
 *
 * @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/CREATE3.sol)
 * @author Modified from Solady (https://github.com/Vectorized/solady/blob/50cbe1909e773b7e4ba76049c75a203e626d55ba/src/utils/CREATE3.sol)
 */
library LibCREATE3 {
    // ╭────────────────────────────────────────────────────────────────────╮
    // │ Opcode      │ Mnemonic         │ Stack        │ Memory             │
    // ├────────────────────────────────────────────────────────────────────┤
    // │ 36          │ CALLDATASIZE     │ cds          │                    │
    // │ 3d          │ RETURNDATASIZE   │ 0 cds        │                    │
    // │ 3d          │ RETURNDATASIZE   │ 0 0 cds      │                    │
    // │ 37          │ CALLDATACOPY     │              │ [0..cds): calldata │
    // │ 36          │ CALLDATASIZE     │ cds          │ [0..cds): calldata │
    // │ 3d          │ RETURNDATASIZE   │ 0 cds        │ [0..cds): calldata │
    // │ 34          │ CALLVALUE        │ value 0 cds  │ [0..cds): calldata │
    // │ f0          │ CREATE           │ newContract  │ [0..cds): calldata │
    // ├────────────────────────────────────────────────────────────────────┤
    // │ Opcode      │ Mnemonic         │ Stack        │ Memory             │
    // ├────────────────────────────────────────────────────────────────────┤
    // │ 67 bytecode │ PUSH8 bytecode   │ bytecode     │                    │
    // │ 3d          │ RETURNDATASIZE   │ 0 bytecode   │                    │
    // │ 52          │ MSTORE           │              │ [0..8): bytecode   │
    // │ 60 0x08     │ PUSH1 0x08       │ 0x08         │ [0..8): bytecode   │
    // │ 60 0x18     │ PUSH1 0x18       │ 0x18 0x08    │ [0..8): bytecode   │
    // │ f3          │ RETURN           │              │ [0..8): bytecode   │
    // ╰────────────────────────────────────────────────────────────────────╯
    bytes private constant _PROXY_BYTECODE =
        hex"67363d3d37363d34f03d5260086018f3";

    bytes32 private constant _PROXY_BYTECODE_HASH = keccak256(_PROXY_BYTECODE);

    /// @dev Deploys `creationCode` deterministically with `salt` and returns the
    ///      deployed contract's address.
    ///
    ///      Note that the address of the deployed contract solely depends on
    ///      `salt`. The deterministic address for `salt` can be computed
    ///      beforehand via `addressOf(bytes32)(address)`.
    function tryDeploy(bytes32 salt, bytes memory creationCode)
        internal
        returns (bool, address)
    {
        // Load proxy's bytecode into memory as direct access not supported in
        // inline assembly.
        bytes memory proxyBytecode = _PROXY_BYTECODE;

        address proxy;
        assembly ("memory-safe") {
            // Deploy a new contract with pre-made bytecode via CREATE2.
            // Start 32 bytes into the code to avoid copying the byte length.
            // forgefmt: disable-next-item
            proxy := create2(
                        0,
                        add(proxyBytecode, 32),
                        mload(proxyBytecode),
                        salt
                     )
        }

        // Fail if deployment failed.
        if (proxy == address(0)) {
            return (false, address(0));
        }

        // Get deployed proxy and initialize creationCode.
        address deployed = addressOf(salt);
        (bool ok,) = proxy.call(creationCode);

        // Fail if call or initialization failed.
        if (!ok || deployed.code.length == 0) {
            return (false, address(0));
        }

        // Otherwise return deployed contract address.
        return (true, deployed);
    }

    /// @dev Returns the deterministic address for `salt`.
    function addressOf(bytes32 salt) internal view returns (address) {
        address proxy = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            // Prefix:
                            bytes1(0xFF),
                            // Creator:
                            address(this),
                            // Salt:
                            salt,
                            // Bytecode hash:
                            _PROXY_BYTECODE_HASH
                        )
                    )
                )
            )
        );

        return address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            // 0xd6 =   0xc0 (short RLP prefix)
                            //        + 0x16 (length of 0x94 ++ proxy ++ 0x01)
                            // 0x94 =   0x80
                            //        + 0x14 (0x14 = 20 = length of address)
                            hex"d694",
                            proxy,
                            // Nonce of proxy contract:
                            hex"01"
                        )
                    )
                )
            )
        );
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IToll {
    /// @notice Thrown by protected function if caller not tolled.
    /// @param caller The caller's address.
    error NotTolled(address caller);

    /// @notice Emitted when toll granted to address.
    /// @param caller The caller's address.
    /// @param who The address toll got granted to.
    event TollGranted(address indexed caller, address indexed who);

    /// @notice Emitted when toll renounced from address.
    /// @param caller The caller's address.
    /// @param who The address toll got renounced from.
    event TollRenounced(address indexed caller, address indexed who);

    /// @notice Grants address `who` toll.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to grant toll.
    function kiss(address who) external;

    /// @notice Renounces address `who`'s toll.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to renounce toll.
    function diss(address who) external;

    /// @notice Returns whether address `who` is tolled.
    /// @param who The address to check.
    /// @return True if `who` is tolled, false otherwise.
    function tolled(address who) external view returns (bool);

    /// @notice Returns full list of addresses tolled.
    /// @dev May contain duplicates.
    /// @return List of addresses tolled.
    function tolled() external view returns (address[] memory);

    /// @notice Returns whether address `who` is tolled.
    /// @custom:deprecated Use `tolled(address)(bool)` instead.
    /// @param who The address to check.
    /// @return 1 if `who` is tolled, 0 otherwise.
    function bud(address who) external view returns (uint);
}