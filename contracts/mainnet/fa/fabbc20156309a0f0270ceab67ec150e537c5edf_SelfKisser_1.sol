// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAuth} from "chronicle-std/auth/IAuth.sol";
import {Auth} from "chronicle-std/auth/Auth.sol";

import {IToll} from "chronicle-std/toll/IToll.sol";

import {ISelfKisser} from "./ISelfKisser.sol";

contract SelfKisser is ISelfKisser, Auth {
    /// @dev Mapping storing whether address is supported oracle.
    mapping(address => uint) internal _oracles;

    /// @dev List of addresses possibly being supported oracles.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being supported oracles anymore.
    address[] internal _oraclesTouched;

    /// @dev Whether SelfKisser is dead.
    uint internal _dead;

    modifier live() {
        if (_dead == 1) {
            revert Dead();
        }
        _;
    }

    modifier supported(address oracle) {
        if (_oracles[oracle] == 0) {
            revert OracleNotSupported(oracle);
        }
        _;
    }

    constructor(address initialAuthed) Auth(initialAuthed) {}

    // -- User Functionality --

    /// @inheritdoc ISelfKisser
    function selfKiss(address oracle) external {
        selfKiss(oracle, msg.sender);
    }

    /// @inheritdoc ISelfKisser
    function selfKiss(address oracle, address who)
        public
        live
        supported(oracle)
    {
        IToll(oracle).kiss(who);
        emit SelfKissed(msg.sender, oracle, who);
    }

    // -- View Functionality --

    /// @inheritdoc ISelfKisser
    function oracles(address oracle) external view returns (bool) {
        return _oracles[oracle] == 1;
    }

    /// @inheritdoc ISelfKisser
    function oracles() external view returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory oraclesList = new address[](_oraclesTouched.length);

        // Iterate through all possible support oracle.
        uint ctr;
        for (uint i; i < oraclesList.length; i++) {
            // Add address only if still auth'ed.
            if (_oracles[_oraclesTouched[i]] == 1) {
                oraclesList[ctr++] = _oraclesTouched[i];
            }
        }

        // Set length of array to number of oracles actually included.
        assembly ("memory-safe") {
            mstore(oraclesList, ctr)
        }

        return oraclesList;
    }

    /// @inheritdoc ISelfKisser
    function dead() external view returns (bool) {
        return _dead == 1;
    }

    // -- Auth'ed Functionality --

    /// @inheritdoc ISelfKisser
    function support(address oracle) external live auth {
        if (_oracles[oracle] == 1) return;

        require(IAuth(oracle).authed(address(this)));

        _oracles[oracle] = 1;
        _oraclesTouched.push(oracle);
        emit OracleSupported(msg.sender, oracle);
    }

    /// @inheritdoc ISelfKisser
    function unsupport(address oracle) external live auth {
        if (_oracles[oracle] == 0) return;

        _oracles[oracle] = 0;
        emit OracleUnsupported(msg.sender, oracle);
    }

    /// @inheritdoc ISelfKisser
    function kill() external auth {
        if (_dead == 1) return;

        _dead = 1;
        emit Killed(msg.sender);
    }
}

/**
 * @dev Contract overwrite to deploy contract instances with specific naming.
 *
 *      For more info, see docs/Deployment.md.
 */
contract SelfKisser_1 is SelfKisser {
    constructor(address initialAuthed) SelfKisser(initialAuthed) {}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ISelfKisser {
    /// @notice Thrown if SelfKisser dead.
    error Dead();

    /// @notice Thrown if oracle not supported.
    /// @param oracle The oracle not supported.
    error OracleNotSupported(address oracle);

    /// @notice Emitted when SelfKisser killed.
    /// @param caller The caller's address.
    event Killed(address indexed caller);

    /// @notice Emitted when support for oracle added.
    /// @param caller The caller's address.
    /// @param oracle The oracle that support got added.
    event OracleSupported(address indexed caller, address indexed oracle);

    /// @notice Emitted when support for oracle removed.
    /// @param caller The caller's address.
    /// @param oracle The oracle that support got removed.
    event OracleUnsupported(address indexed caller, address indexed oracle);

    /// @notice Emitted when new address kissed on an oracle.
    /// @param caller The caller's address.
    /// @param oracle The oracle on which address `who` got kissed on.
    /// @param who The address that got kissed on oracle `oracle`.
    event SelfKissed(
        address indexed caller, address indexed oracle, address indexed who
    );

    // -- User Functionality --

    /// @notice Kisses caller on oracle `oracle`.
    ///
    /// @dev Reverts if oracle `oracle` not supported.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to kiss the caller on.
    function selfKiss(address oracle) external;

    /// @notice Kisses address `who` on oracle `oracle`.
    ///
    /// @dev Reverts if oracle `oracle` not supported.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to kiss address `who` on.
    /// @param who The address to kiss on oracle `oracle`.
    function selfKiss(address oracle, address who) external;

    // -- View Functionality --

    /// @notice Returns whether oracle `oracle` is supported.
    /// @param oracle The oracle to check whether its supported.
    /// @return True if oracle supported, false otherwise.
    function oracles(address oracle) external view returns (bool);

    /// @notice Returns the list of supported oracles.
    ///
    /// @dev May contain duplicates.
    ///
    /// @return List of supported oracles.
    function oracles() external view returns (address[] memory);

    /// @notice Returns whether SelfKisser is dead.
    /// @return True if SelfKisser dead, false otherwise.
    function dead() external view returns (bool);

    // -- Auth'ed Functionality --

    /// @notice Adds support for oracle `oracle`.
    /// @dev Only callable by auth'ed address.
    ///
    /// @dev Reverts if SelfKisser not auth'ed on oracle `oracle`.
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to add support for.
    function support(address oracle) external;

    /// @notice Removes support for oracle `oracle`.
    /// @dev Only callable by auth'ed address.
    ///
    /// @dev Reverts if SelfKisser dead.
    ///
    /// @param oracle The oracle to remove support for.
    function unsupport(address oracle) external;

    /// @notice Kills the contract.
    /// @dev Only callable by auth'ed address.
    function kill() external;
}