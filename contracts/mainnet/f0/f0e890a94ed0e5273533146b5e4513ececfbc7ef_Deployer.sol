// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './AuthorizedHelpers.sol';
import './interfaces/IAuthorized.sol';
import './interfaces/IAuthorizer.sol';

/**
 * @title Authorized
 * @dev Implementation using an authorizer as its access-control mechanism. It offers `auth` and `authP` modifiers to
 * tag its own functions in order to control who can access them against the authorizer referenced.
 */
contract Authorized is IAuthorized, Initializable, AuthorizedHelpers {
    // Authorizer reference
    address public override authorizer;

    /**
     * @dev Modifier that should be used to tag protected functions
     */
    modifier auth() {
        _authenticate(msg.sender, msg.sig);
        _;
    }

    /**
     * @dev Modifier that should be used to tag protected functions with params
     */
    modifier authP(uint256[] memory params) {
        _authenticate(msg.sender, msg.sig, params);
        _;
    }

    /**
     * @dev Creates a new authorized contract. Note that initializers are disabled at creation time.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the authorized contract. It does call upper contracts initializers.
     * @param _authorizer Address of the authorizer to be set
     */
    function __Authorized_init(address _authorizer) internal onlyInitializing {
        __Authorized_init_unchained(_authorizer);
    }

    /**
     * @dev Initializes the authorized contract. It does not call upper contracts initializers.
     * @param _authorizer Address of the authorizer to be set
     */
    function __Authorized_init_unchained(address _authorizer) internal onlyInitializing {
        authorizer = _authorizer;
    }

    /**
     * @dev Reverts if `who` is not allowed to call `what`
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     */
    function _authenticate(address who, bytes4 what) internal view {
        _authenticate(who, what, new uint256[](0));
    }

    /**
     * @dev Reverts if `who` is not allowed to call `what` with `how`
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     * @param how Params to be authenticated
     */
    function _authenticate(address who, bytes4 what, uint256[] memory how) internal view {
        require(_isAuthorized(who, what, how), 'AUTH_SENDER_NOT_ALLOWED');
    }

    /**
     * @dev Tells whether `who` has any permission on this contract
     * @param who Address asking permissions for
     */
    function _hasPermissions(address who) internal view returns (bool) {
        return IAuthorizer(authorizer).hasPermissions(who, address(this));
    }

    /**
     * @dev Tells whether `who` is allowed to call `what`
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     */
    function _isAuthorized(address who, bytes4 what) internal view returns (bool) {
        return _isAuthorized(who, what, new uint256[](0));
    }

    /**
     * @dev Tells whether `who` is allowed to call `what` with `how`
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function _isAuthorized(address who, bytes4 what, uint256[] memory how) internal view returns (bool) {
        return IAuthorizer(authorizer).isAuthorized(who, address(this), what, how);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

/**
 * @title AuthorizedHelpers
 * @dev Syntax sugar methods to operate with authorizer params easily
 */
contract AuthorizedHelpers {
    function authParams(address p1) internal pure returns (uint256[] memory r) {
        return authParams(uint256(uint160(p1)));
    }

    function authParams(bytes32 p1) internal pure returns (uint256[] memory r) {
        return authParams(uint256(p1));
    }

    function authParams(uint256 p1) internal pure returns (uint256[] memory r) {
        r = new uint256[](1);
        r[0] = p1;
    }

    function authParams(address p1, bool p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(uint160(p1));
        r[1] = p2 ? 1 : 0;
    }

    function authParams(address p1, uint256 p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
    }

    function authParams(address p1, address p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
    }

    function authParams(bytes32 p1, bytes32 p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(p1);
        r[1] = uint256(p2);
    }

    function authParams(address p1, address p2, uint256 p3) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = p3;
    }

    function authParams(address p1, address p2, address p3) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = uint256(uint160(p3));
    }

    function authParams(address p1, address p2, bytes4 p3) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = uint256(uint32(p3));
    }

    function authParams(address p1, uint256 p2, uint256 p3) internal pure returns (uint256[] memory r) {
        r = new uint256[](3);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
        r[2] = p3;
    }

    function authParams(address p1, address p2, uint256 p3, uint256 p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = p3;
        r[3] = p4;
    }

    function authParams(address p1, uint256 p2, uint256 p3, uint256 p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
        r[2] = p3;
        r[3] = p4;
    }

    function authParams(bytes32 p1, address p2, uint256 p3, bool p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = uint256(p1);
        r[1] = uint256(uint160(p2));
        r[2] = p3;
        r[3] = p4 ? 1 : 0;
    }

    function authParams(address p1, uint256 p2, uint256 p3, uint256 p4, uint256 p5)
        internal
        pure
        returns (uint256[] memory r)
    {
        r = new uint256[](5);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
        r[2] = p3;
        r[3] = p4;
        r[4] = p5;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import './AuthorizedHelpers.sol';
import './interfaces/IAuthorizer.sol';

/**
 * @title Authorizer
 * @dev Authorization mechanism based on permissions
 */
contract Authorizer is IAuthorizer, AuthorizedHelpers, Initializable, ReentrancyGuardUpgradeable {
    // Constant used to denote that a permission is open to anyone
    address public constant ANYONE = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    // Constant used to denote that a permission is open to anywhere
    address public constant ANYWHERE = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    // Param logic op types
    enum Op {
        NONE,
        EQ,
        NEQ,
        GT,
        LT,
        GTE,
        LTE
    }

    /**
     * @dev Permission information
     * @param authorized Whether it is authorized or not
     * @param params List of params defined for each permission
     */
    struct Permission {
        bool authorized;
        Param[] params;
    }

    /**
     * @dev Permissions list information
     * @param count Number of permissions
     * @param permissions List of permissions indexed by what
     */
    struct PermissionsList {
        uint256 count;
        mapping (bytes4 => Permission) permissions;
    }

    // List of permissions indexed by who => where
    mapping (address => mapping (address => PermissionsList)) private _permissionsLists;

    /**
     * @dev Creates a new authorizer contract. Note that initializers are disabled at creation time.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialization function.
     * @param owners List of addresses that will be allowed to authorize and unauthorize permissions
     */
    function initialize(address[] memory owners) external virtual initializer {
        __ReentrancyGuard_init();
        for (uint256 i = 0; i < owners.length; i++) {
            _authorize(owners[i], address(this), IAuthorizer.authorize.selector, new Param[](0));
            _authorize(owners[i], address(this), IAuthorizer.unauthorize.selector, new Param[](0));
        }
    }

    /**
     * @dev Tells whether `who` has any permission on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function hasPermissions(address who, address where) external view override returns (bool) {
        return _permissionsLists[who][where].count > 0;
    }

    /**
     * @dev Tells the number of permissions `who` has on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function getPermissionsLength(address who, address where) external view override returns (uint256) {
        return _permissionsLists[who][where].count;
    }

    /**
     * @dev Tells whether `who` is allowed to call `what` on `where` with `how`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function isAuthorized(address who, address where, bytes4 what, uint256[] memory how)
        public
        view
        override
        returns (bool)
    {
        if (_isAuthorized(who, where, what, how)) return true; // direct permission
        if (_isAuthorized(ANYONE, where, what, how)) return true; // anyone is allowed
        if (_isAuthorized(who, ANYWHERE, what, how)) return true; // direct permission on anywhere
        if (_isAuthorized(ANYONE, ANYWHERE, what, how)) return true; // anyone allowed anywhere
        return false;
    }

    /**
     * @dev Tells the params set for a given permission
     * @param who Address asking permission params of
     * @param where Target address asking permission params of
     * @param what Function selector asking permission params of
     */
    function getPermissionParams(address who, address where, bytes4 what)
        external
        view
        override
        returns (Param[] memory)
    {
        return _permissionsLists[who][where].permissions[what].params;
    }

    /**
     * @dev Executes a list of permission changes. Sender must be authorized.
     * @param changes List of permission changes to be executed
     */
    function changePermissions(PermissionChange[] memory changes) external override {
        for (uint256 i = 0; i < changes.length; i++) {
            PermissionChange memory change = changes[i];
            for (uint256 j = 0; j < change.grants.length; j++) {
                GrantPermission memory grant = change.grants[j];
                authorize(grant.who, change.where, grant.what, grant.params);
            }
            for (uint256 j = 0; j < change.revokes.length; j++) {
                RevokePermission memory revoke = change.revokes[j];
                unauthorize(revoke.who, change.where, revoke.what);
            }
        }
    }

    /**
     * @dev Authorizes `who` to call `what` on `where` restricted by `params`. Sender must be authorized.
     * @param who Address to be authorized
     * @param where Target address to be granted for
     * @param what Function selector to be granted
     * @param params Optional params to restrict a permission attempt
     */
    function authorize(address who, address where, bytes4 what, Param[] memory params) public override nonReentrant {
        uint256[] memory how = authParams(who, where, what);
        bool allowed = isAuthorized(msg.sender, address(this), IAuthorizer.authorize.selector, how);
        require(allowed, 'AUTHORIZER_SENDER_NOT_ALLOWED');
        _authorize(who, where, what, params);
    }

    /**
     * @dev Unauthorizes `who` to call `what` on `where`. Sender must be authorized.
     * @param who Address to be authorized
     * @param where Target address to be revoked for
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, address where, bytes4 what) public override nonReentrant {
        uint256[] memory how = authParams(who, where, what);
        bool allowed = isAuthorized(msg.sender, address(this), IAuthorizer.unauthorize.selector, how);
        require(allowed, 'AUTHORIZER_SENDER_NOT_ALLOWED');
        _unauthorize(who, where, what);
    }

    /**
     * @dev Tells whether `who` is allowed to call `what` on `where` with `how`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function _isAuthorized(address who, address where, bytes4 what, uint256[] memory how) internal view returns (bool) {
        Permission storage permission = _permissionsLists[who][where].permissions[what];
        return permission.authorized && _evalParams(permission.params, how);
    }

    /**
     * @dev Authorizes `who` to call `what` on `where` restricted by `params`
     * @param who Address to be authorized
     * @param where Target address to be granted for
     * @param what Function selector to be granted
     * @param params Optional params to restrict a permission attempt
     */
    function _authorize(address who, address where, bytes4 what, Param[] memory params) internal {
        PermissionsList storage list = _permissionsLists[who][where];
        Permission storage permission = list.permissions[what];
        if (!permission.authorized) list.count++;
        permission.authorized = true;
        delete permission.params;
        for (uint256 i = 0; i < params.length; i++) permission.params.push(params[i]);
        emit Authorized(who, where, what, params);
    }

    /**
     * @dev Unauthorizes `who` to call `what` on `where`
     * @param who Address to be authorized
     * @param where Target address to be revoked for
     * @param what Function selector to be revoked
     */
    function _unauthorize(address who, address where, bytes4 what) internal {
        PermissionsList storage list = _permissionsLists[who][where];
        Permission storage permission = list.permissions[what];
        if (permission.authorized) list.count--;
        delete list.permissions[what];
        emit Unauthorized(who, where, what);
    }

    /**
     * @dev Evaluates a list of params defined for a permission against a list of values given by a call
     * @param params List of expected params
     * @param how List of actual given values
     * @return True if all the given values hold against the list of params
     */
    function _evalParams(Param[] memory params, uint256[] memory how) private pure returns (bool) {
        for (uint256 i = 0; i < params.length; i++) {
            Param memory param = params[i];
            if ((i < how.length && !_evalParam(param, how[i])) || (i >= how.length && Op(param.op) != Op.NONE)) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Evaluates a single param defined for a permission against a single value
     * @param param Expected params
     * @param how Actual given value
     * @return True if the given value hold against the expected param
     */
    function _evalParam(Param memory param, uint256 how) private pure returns (bool) {
        if (Op(param.op) == Op.NONE) return true;
        if (Op(param.op) == Op.EQ) return how == param.value;
        if (Op(param.op) == Op.NEQ) return how != param.value;
        if (Op(param.op) == Op.GT) return how > param.value;
        if (Op(param.op) == Op.LT) return how < param.value;
        if (Op(param.op) == Op.GTE) return how >= param.value;
        if (Op(param.op) == Op.LTE) return how <= param.value;
        revert('AUTHORIZER_INVALID_PARAM_OP');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @dev Authorized interface
 */
interface IAuthorized {
    /**
     * @dev Tells the address of the authorizer reference
     */
    function authorizer() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @dev Authorizer interface
 */
interface IAuthorizer {
    /**
     * @dev Permission change
     * @param where Address of the contract to change a permission for
     * @param changes List of permission changes to be executed
     */
    struct PermissionChange {
        address where;
        GrantPermission[] grants;
        RevokePermission[] revokes;
    }

    /**
     * @dev Grant permission data
     * @param who Address to be authorized
     * @param what Function selector to be authorized
     * @param params List of params to restrict the given permission
     */
    struct GrantPermission {
        address who;
        bytes4 what;
        Param[] params;
    }

    /**
     * @dev Revoke permission data
     * @param who Address to be unauthorized
     * @param what Function selector to be unauthorized
     */
    struct RevokePermission {
        address who;
        bytes4 what;
    }

    /**
     * @dev Params used to validate permissions params against
     * @param op ID of the operation to compute in order to validate a permission param
     * @param value Comparison value
     */
    struct Param {
        uint8 op;
        uint248 value;
    }

    /**
     * @dev Emitted every time `who`'s permission to perform `what` on `where` is granted with `params`
     */
    event Authorized(address indexed who, address indexed where, bytes4 indexed what, Param[] params);

    /**
     * @dev Emitted every time `who`'s permission to perform `what` on `where` is revoked
     */
    event Unauthorized(address indexed who, address indexed where, bytes4 indexed what);

    /**
     * @dev Tells whether `who` has any permission on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function hasPermissions(address who, address where) external view returns (bool);

    /**
     * @dev Tells the number of permissions `who` has on `where`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     */
    function getPermissionsLength(address who, address where) external view returns (uint256);

    /**
     * @dev Tells whether `who` is allowed to call `what` on `where` with `how`
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     * @param how Params asking permission for
     */
    function isAuthorized(address who, address where, bytes4 what, uint256[] memory how) external view returns (bool);

    /**
     * @dev Tells the params set for a given permission
     * @param who Address asking permission params of
     * @param where Target address asking permission params of
     * @param what Function selector asking permission params of
     */
    function getPermissionParams(address who, address where, bytes4 what) external view returns (Param[] memory);

    /**
     * @dev Executes a list of permission changes
     * @param changes List of permission changes to be executed
     */
    function changePermissions(PermissionChange[] memory changes) external;

    /**
     * @dev Authorizes `who` to call `what` on `where` restricted by `params`
     * @param who Address to be authorized
     * @param where Target address to be granted for
     * @param what Function selector to be granted
     * @param params Optional params to restrict a permission attempt
     */
    function authorize(address who, address where, bytes4 what, Param[] memory params) external;

    /**
     * @dev Unauthorizes `who` to call `what` on `where`. Sender must be authorized.
     * @param who Address to be authorized
     * @param where Target address to be revoked for
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, address where, bytes4 what) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @dev Fee controller interface
 */
interface IFeeController {
    /**
     * @dev Emitted every time a default fee collector is set
     */
    event DefaultFeeCollectorSet(address indexed collector);

    /**
     * @dev Emitted every time a max fee percentage is set for a smart vault
     */
    event MaxFeePercentageSet(address indexed smartVault, uint256 maxPct);

    /**
     * @dev Emitted every time a custom fee percentage is set
     */
    event FeePercentageSet(address indexed smartVault, uint256 pct);

    /**
     * @dev Emitted every time a custom fee collector is set
     */
    event FeeCollectorSet(address indexed smartVault, address indexed collector);

    /**
     * @dev Tells the default fee collector
     */
    function defaultFeeCollector() external view returns (address);

    /**
     * @dev Tells if there is a fee set for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function hasFee(address smartVault) external view returns (bool);

    /**
     * @dev Tells the applicable fee information for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function getFee(address smartVault) external view returns (uint256 max, uint256 pct, address collector);

    /**
     * @dev Sets the default fee collector
     * @param collector Default fee collector to be set
     */
    function setDefaultFeeCollector(address collector) external;

    /**
     * @dev Sets a max fee percentage for a smart vault
     * @param smartVault Address of smart vault to set a fee percentage for
     * @param maxPct Max fee percentage to be set
     */
    function setMaxFeePercentage(address smartVault, uint256 maxPct) external;

    /**
     * @dev Sets a fee percentage for a smart vault
     * @param smartVault Address of smart vault to set a fee percentage for
     * @param pct Fee percentage to be set
     */
    function setFeePercentage(address smartVault, uint256 pct) external;

    /**
     * @dev Sets a fee collector for a smart vault
     * @param smartVault Address of smart vault to set a fee collector for
     * @param collector Fee collector to be set
     */
    function setFeeCollector(address smartVault, address collector) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title FixedPoint
 * @dev Math library to operate with fixed point values with 18 decimals
 */
library FixedPoint {
    // 1 in fixed point value: 18 decimal places
    uint256 internal constant ONE = 1e18;

    /**
     * @dev Multiplies two fixed point numbers rounding down
     */
    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, 'MUL_OVERFLOW');
            return product / ONE;
        }
    }

    /**
     * @dev Multiplies two fixed point numbers rounding up
     */
    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, 'MUL_OVERFLOW');
            return product == 0 ? 0 : (((product - 1) / ONE) + 1);
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding down
     */
    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'ZERO_DIVISION');
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, 'DIV_INTERNAL');
            return aInflated / b;
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding up
     */
    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'ZERO_DIVISION');
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, 'DIV_INTERNAL');
            return ((aInflated - 1) / b) + 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title BytesHelpers
 * @dev Provides a list of Bytes helper methods
 */
library BytesHelpers {
    /**
     * @dev Concatenates an address to a bytes array
     */
    function concat(bytes memory self, address value) internal pure returns (bytes memory) {
        return abi.encodePacked(self, value);
    }

    /**
     * @dev Concatenates an uint24 to a bytes array
     */
    function concat(bytes memory self, uint24 value) internal pure returns (bytes memory) {
        return abi.encodePacked(self, value);
    }

    /**
     * @dev Decodes a bytes array into an uint256
     */
    function toUint256(bytes memory self) internal pure returns (uint256) {
        return toUint256(self, 0);
    }

    /**
     * @dev Reads an uint256 from a bytes array starting at a given position
     */
    function toUint256(bytes memory self, uint256 start) internal pure returns (uint256 result) {
        require(self.length >= start + 32, 'BYTES_OUT_OF_BOUNDS');
        assembly {
            result := mload(add(add(self, 0x20), start))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title Denominations
 * @dev Provides a list of ground denominations for those tokens that cannot be represented by an ERC20.
 * For now, the only needed is the native token that could be ETH, MATIC, or other depending on the layer being operated.
 */
library Denominations {
    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
    address internal constant USD = address(840);

    function isNativeToken(address token) internal pure returns (bool) {
        return token == NATIVE_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './Denominations.sol';

/**
 * @title ERC20Helpers
 * @dev Provides a list of ERC20 helper methods
 */
library ERC20Helpers {
    function approve(address token, address to, uint256 amount) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeApprove(IERC20(token), to, amount);
    }

    function transfer(address token, address to, uint256 amount) internal {
        if (Denominations.isNativeToken(token)) Address.sendValue(payable(to), amount);
        else SafeERC20.safeTransfer(IERC20(token), to, amount);
    }

    function balanceOf(address token, address account) internal view returns (uint256) {
        if (Denominations.isNativeToken(token)) return address(account).balance;
        else return IERC20(token).balanceOf(address(account));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title IWrappedNativeToken
 */
interface IWrappedNativeToken is IERC20 {
    /**
     * @dev Wraps msg.value into the wrapped-native token
     */
    function deposit() external payable;

    /**
     * @dev Unwraps requested amount to the native token
     */
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import '@mimic-fi/v3-authorizer/contracts/interfaces/IAuthorized.sol';

/**
 * @title IPriceOracle
 * @dev Price oracle interface
 *
 * Tells the price of a token (base) in a given quote based the following rule: the response is expressed using the
 * corresponding number of decimals so that when performing a fixed point product of it by a `base` amount it results
 * in a value expressed in `quote` decimals. For example, if `base` is ETH and `quote` is USDC, then the returned
 * value is expected to be expressed using 6 decimals:
 *
 * FixedPoint.mul(X[ETH], price[USDC/ETH]) = FixedPoint.mul(X[18], price[6]) = X * price [6]
 */
interface IPriceOracle is IAuthorized {
    /**
     * @dev Price data
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param rate Price of a token (base) expressed in `quote`
     * @param deadline Expiration timestamp until when the given quote is considered valid
     */
    struct PriceData {
        address base;
        address quote;
        uint256 rate;
        uint256 deadline;
    }

    /**
     * @dev Emitted every time a signer is changed
     */
    event SignerSet(address indexed signer, bool allowed);

    /**
     * @dev Emitted every time a feed is set for (base, quote) pair
     */
    event FeedSet(address indexed base, address indexed quote, address feed);

    /**
     * @dev Tells whether an address is as an allowed signer or not
     * @param signer Address of the signer being queried
     */
    function isSignerAllowed(address signer) external view returns (bool);

    /**
     * @dev Tells the list of allowed signers
     */
    function getAllowedSigners() external view returns (address[] memory);

    /**
     * @dev Tells the digest expected to be signed by the off-chain oracle signers for a list of prices
     * @param prices List of prices to be signed
     */
    function getPricesDigest(PriceData[] memory prices) external view returns (bytes32);

    /**
     * @dev Tells the price of a token `base` expressed in a token `quote`
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getPrice(address base, address quote) external view returns (uint256);

    /**
     * @dev Tells the price of a token `base` expressed in a token `quote`
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param data Encoded data to validate in order to compute the requested rate
     */
    function getPrice(address base, address quote, bytes memory data) external view returns (uint256);

    /**
     * @dev Tells the feed address for (base, quote) pair. It returns the zero address if there is no one set.
     * @param base Token to be rated
     * @param quote Token used for the price rate
     */
    function getFeed(address base, address quote) external view returns (address);

    /**
     * @dev Sets a signer condition
     * @param signer Address of the signer to be set
     * @param allowed Whether the requested signer is allowed
     */
    function setSigner(address signer, bool allowed) external;

    /**
     * @dev Sets a feed for a (base, quote) pair
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Feed to be set
     */
    function setFeed(address base, address quote, address feed) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';

import './interfaces/IPriceOracle.sol';

/**
 * @title OnChainOracle
 * @dev Price oracle mixing both on-chain and off-chain oracle alternatives
 *
 * The on-chain oracle that interfaces with Chainlink feeds to provide rates between two tokens. This oracle only
 * operates with ERC20 tokens, it does not allow querying quotes for any other denomination. Additionally, it only
 * supports feeds that implement ChainLink's proposed `AggregatorV3Interface` interface.
 *
 *  The off-chain oracle that uses off-chain signatures to compute prices between two tokens
 */
contract PriceOracle is IPriceOracle, Authorized, ReentrancyGuardUpgradeable {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Number of decimals used for fixed point operations: 18
    uint256 private constant FP_DECIMALS = 18;

    // Maximum number of decimals supported for a token when computing inverse quotes: 36
    uint256 private constant INVERSE_FEED_MAX_DECIMALS = 36;

    // It allows denoting a single token to pivot between feeds in case a direct path is not available
    address public pivot;

    // Mapping of feeds from "token A" to "token B"
    mapping (address => mapping (address => address)) public override getFeed;

    // Enumerable set of trusted signers
    EnumerableSet.AddressSet private _signers;

    /**
     * @dev Feed data, only used during initialization
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param feed Chainlink oracle to fetch the given pair price
     */
    struct FeedData {
        address base;
        address quote;
        address feed;
    }

    /**
     * @dev Initializes the price oracle
     * @param _authorizer Address of the authorizer to be set
     * @param _signer Address of the initial allowed signer
     * @param _pivot Address of the token to be used as the pivot
     * @param _feeds List of feeds to be initialized with
     */
    function initialize(address _authorizer, address _signer, address _pivot, FeedData[] memory _feeds)
        external
        initializer
    {
        __PriceOracle_init(_authorizer, _signer, _pivot, _feeds);
    }

    /**
     * @dev Initializes the price oracle. It does call upper contracts initializers.
     * @param _authorizer Address of the authorizer to be set
     * @param _signer Address of the initial allowed signer
     * @param _pivot Address of the token to be used as the pivot
     * @param _feeds List of feeds to be initialized with
     */
    function __PriceOracle_init(address _authorizer, address _signer, address _pivot, FeedData[] memory _feeds)
        internal
        onlyInitializing
    {
        __ReentrancyGuard_init();
        __Authorized_init(_authorizer);
        __PriceOracle_init_unchained(_authorizer, _signer, _pivot, _feeds);
    }

    /**
     * @dev Initializes the price oracle. It does not call upper contracts initializers.
     * @param _signer Address of the initial allowed signer
     * @param _pivot Address of the token to be used as the pivot
     * @param _feeds List of feeds to be initialized with
     */
    function __PriceOracle_init_unchained(address, address _signer, address _pivot, FeedData[] memory _feeds)
        internal
        onlyInitializing
    {
        _setSigner(_signer, true);
        pivot = _pivot;
        for (uint256 i = 0; i < _feeds.length; i++) _setFeed(_feeds[i].base, _feeds[i].quote, _feeds[i].feed);
    }

    /**
     * @dev Tells whether an address is as an allowed signer or not
     * @param signer Address of the signer being queried
     */
    function isSignerAllowed(address signer) public view override returns (bool) {
        return _signers.contains(signer);
    }

    /**
     * @dev Tells the list of allowed signers
     */
    function getAllowedSigners() external view override returns (address[] memory) {
        return _signers.values();
    }

    /**
     * @dev Tells the digest expected to be signed by the off-chain oracle signers for a list of prices
     * @param prices List of prices to be signed
     */
    function getPricesDigest(PriceData[] memory prices) public pure override returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encode(prices)));
    }

    /**
     * @dev Tells the price of a token (base) in a given quote. The response is expressed using the corresponding
     * number of decimals so that when performing a fixed point product of it by a `base` amount it results in
     * a value expressed in `quote` decimals.
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getPrice(address base, address quote) public view override returns (uint256) {
        if (base == quote) return FixedPoint.ONE;

        // If `base * result / 1e18` must be expressed in `quote` decimals, then
        uint256 baseDecimals = IERC20Metadata(base).decimals();
        uint256 quoteDecimals = IERC20Metadata(quote).decimals();

        // No need for checked math as an uint8 + FP_DECIMALS (constant) will always fit in an uint256
        require(baseDecimals <= quoteDecimals + FP_DECIMALS, 'BASE_DECIMALS_TOO_BIG');

        // No need for checked math as we are checking it manually beforehand
        uint256 resultDecimals = quoteDecimals + FP_DECIMALS - baseDecimals;
        (uint256 price, uint256 decimals) = _getPrice(base, quote);
        return _scalePrice(price, decimals, resultDecimals);
    }

    /**
     /**
     * @dev Tries fetching a price for base/quote pair from an external encoded data. It fall-backs using the on-chain
     * oracle in case the require price is missing. It reverts in case the off-chain data verification fails.
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param data Encoded prices data along with its corresponding signature
     */
    function getPrice(address base, address quote, bytes memory data) external view override returns (uint256) {
        if (base == quote) return FixedPoint.ONE;

        PriceData[] memory prices = _decodePricesData(data);
        for (uint256 i = 0; i < prices.length; i++) {
            PriceData memory price = prices[i];
            if (price.base == base && price.quote == quote) {
                require(price.deadline >= block.timestamp, 'ORACLE_PRICE_OUTDATED');
                return price.rate;
            }
        }

        return getPrice(base, quote);
    }

    /**
     * @dev Sets a signer condition
     * @param signer Address of the signer to be set
     * @param allowed Whether the requested signer is allowed
     */
    function setSigner(address signer, bool allowed) external override nonReentrant authP(authParams(signer, allowed)) {
        _setSigner(signer, allowed);
    }

    /**
     * @dev Sets a feed for a (base, quote) pair. Sender must be authorized.
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Feed to be set
     */
    function setFeed(address base, address quote, address feed)
        external
        override
        nonReentrant
        authP(authParams(base, quote, feed))
    {
        _setFeed(base, quote, feed);
    }

    /**
     * @dev Tells the price of a token (base) in a given quote.
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @return price Requested price rate
     * @return decimals Decimals of the requested price rate
     */
    function _getPrice(address base, address quote) internal view returns (uint256 price, uint256 decimals) {
        address feed = getFeed[base][quote];
        if (feed != address(0)) return _getFeedData(feed);

        address inverseFeed = getFeed[quote][base];
        if (inverseFeed != address(0)) return _getInversePrice(inverseFeed);

        address baseFeed = getFeed[base][pivot];
        address quoteFeed = getFeed[quote][pivot];
        if (baseFeed != address(0) && quoteFeed != address(0)) return _getPivotPrice(baseFeed, quoteFeed);

        revert('ORACLE_MISSING_FEED');
    }

    /**
     * @dev Fetches data from a Chainlink feed
     * @param feed Address of the Chainlink feed to fetch data from. It must support ChainLink `AggregatorV3Interface`.
     * @return price Requested price
     * @return decimals Decimals of the requested price
     */
    function _getFeedData(address feed) internal view returns (uint256 price, uint256 decimals) {
        decimals = AggregatorV3Interface(feed).decimals();
        (, int256 priceInt, , , ) = AggregatorV3Interface(feed).latestRoundData();
        price = SafeCast.toUint256(priceInt);
    }

    /**
     * @dev Tells a price based on an inverse feed
     * @param inverseFeed Feed of the inverse pair
     * @return price Requested price rate
     * @return decimals Decimals of the requested price rate
     */
    function _getInversePrice(address inverseFeed) internal view returns (uint256 price, uint256 decimals) {
        (uint256 inversePrice, uint256 inverseFeedDecimals) = _getFeedData(inverseFeed);
        require(inverseFeedDecimals <= INVERSE_FEED_MAX_DECIMALS, 'FEED_DECIMALS_TOO_BIG');

        // Prices are requested for different purposes, we are rounding down always to follow a single strategy
        price = FixedPoint.ONE.divDown(inversePrice);
        // No need for checked math as we are checking it manually beforehand
        decimals = INVERSE_FEED_MAX_DECIMALS - inverseFeedDecimals;
    }

    /**
     * @dev Report a price based on two relative feeds
     * @param baseFeed Feed of the base token
     * @param quoteFeed Feed of the quote token
     * @return price Requested price rate
     * @return decimals Decimals of the requested price rate
     */
    function _getPivotPrice(address baseFeed, address quoteFeed)
        internal
        view
        returns (uint256 price, uint256 decimals)
    {
        (uint256 basePrice, uint256 baseFeedDecimals) = _getFeedData(baseFeed);
        (uint256 quotePrice, uint256 quoteFeedDecimals) = _getFeedData(quoteFeed);

        // No need for checked math as an uint8 + FP_DECIMALS (constant) will always fit in an uint256
        require(quoteFeedDecimals <= baseFeedDecimals + FP_DECIMALS, 'QUOTE_FEED_DECIMALS_TOO_BIG');

        // Price is base/quote = (base/pivot) / (quote/pivot)
        // Prices are requested for different purposes, we are rounding down always to follow a single strategy
        price = basePrice.divDown(quotePrice);
        // No need for checked math as we are checking it manually beforehand
        decimals = baseFeedDecimals + FP_DECIMALS - quoteFeedDecimals;
    }

    /**
     * @dev Upscales or downscale a price rate
     * @param price Value to be scaled
     * @param priceDecimals Decimals in which `price` is originally represented
     * @return resultDecimals Decimals requested for the result
     */
    function _scalePrice(uint256 price, uint256 priceDecimals, uint256 resultDecimals) internal pure returns (uint256) {
        return
            resultDecimals >= priceDecimals
                ? (price * 10**(resultDecimals - priceDecimals))
                : (price / 10**(priceDecimals - resultDecimals));
    }

    /**
     * @dev Decodes a list of off-chain encoded prices. It returns an empty array in case it is malformed. It reverts
     * if the data is considered properly encoded but the signer is not allowed.
     * @param data Data to be decoded
     */
    function _decodePricesData(bytes memory data) internal view returns (PriceData[] memory) {
        if (!_isOffChainDataEncodedProperly(data)) return new PriceData[](0);

        (PriceData[] memory prices, bytes memory signature) = abi.decode(data, (PriceData[], bytes));
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(getPricesDigest(prices), signature);
        require(error == ECDSA.RecoverError.NoError && isSignerAllowed(recovered), 'ORACLE_INVALID_SIGNER');
        return prices;
    }

    /**
     * @dev Sets the off-chain oracle signer
     * @param signer Address of the signer to be set
     */
    function _setSigner(address signer, bool allowed) internal {
        allowed ? _signers.add(signer) : _signers.remove(signer);
        emit SignerSet(signer, allowed);
    }

    /**
     * @dev Sets a new feed for a (base, quote) pair
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Feed to be set
     */
    function _setFeed(address base, address quote, address feed) internal {
        getFeed[base][quote] = feed;
        emit FeedSet(base, quote, feed);
    }

    /**
     * @dev Tells if a data array is encoded as expected for a list off-chain prices
     * @param data Data to be evaluated
     */
    function _isOffChainDataEncodedProperly(bytes memory data) private pure returns (bool) {
        // Check the minimum expected data length based on how ABI encoding works.
        // Considering the structure (PriceData[], bytes), the encoding should have the following pattern:
        //
        // [ PRICES OFFSET ][ SIG OFFSET ][ PRICES DATA LENGTH ][ PRICES DATA ][ SIG LENGTH ][ VRS SIG ]
        // [       32      ][     32     ][         32         ][   N * 128   ][     32     ][  32 * 3 ]
        //
        // Therefore the minimum length expected is:
        uint256 minimumLength = 32 + 32 + 32 + 32 + 96;
        if (data.length < minimumLength) return false;

        // There must be at least the same number of bytes specified by the prices offset value:
        uint256 pricesOffset = data.toUint256(0);
        if (data.length < pricesOffset) return false;

        // The exact expected data length can be now computed based on the prices length:
        uint256 pricesLength = data.toUint256(pricesOffset);
        if (data.length != minimumLength + (pricesLength * 128)) return false;

        // The signature offset can be computed based on the prices length:
        uint256 signatureOffset = data.toUint256(32);
        if (signatureOffset != (32 * 3) + (pricesLength * 128)) return false;

        // Finally the signature length must be 64 or 65:
        uint256 signatureLength = data.toUint256(signatureOffset);
        if (signatureLength != 64 && signatureLength != 65) return false;

        // Finally confirm the data types for each of the price data attributes:
        for (uint256 i = 0; i < pricesLength; i++) {
            uint256 offset = i * 128;

            // Base should be a valid address
            uint256 priceBase = data.toUint256(32 * 3 + offset);
            if (priceBase > type(uint160).max) return false;

            // Quote should be a valid address
            uint256 priceQuote = data.toUint256(32 * 4 + offset);
            if (priceQuote > type(uint160).max) return false;
        }

        // Otherwise the data can be decoded properly
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import './IRegistry.sol';

/**
 * @dev Registry interface
 */
interface IRegistry {
    /**
     * @dev Emitted every time an implementation is registered
     */
    event Registered(address indexed implementation, string name, bool stateless);

    /**
     * @dev Emitted every time an implementation is deprecated
     */
    event Deprecated(address indexed implementation);

    /**
     * @dev Tells whether an implementation is registered
     * @param implementation Address of the implementation being queried
     */
    function isRegistered(address implementation) external view returns (bool);

    /**
     * @dev Tells whether an implementation is stateless or not
     * @param implementation Address of the implementation being queried
     */
    function isStateless(address implementation) external view returns (bool);

    /**
     * @dev Tells whether an implementation is deprecated
     * @param implementation Address of the implementation being queried
     */
    function isDeprecated(address implementation) external view returns (bool);

    /**
     * @dev Creates and registers an implementation
     * @param name Name of the implementation
     * @param code Code of the implementation to create and register
     * @param stateless Whether the new implementation is considered stateless or not
     */
    function create(string memory name, bytes memory code, bool stateless) external;

    /**
     * @dev Registers an implementation
     * @param name Name of the implementation
     * @param implementation Address of the implementation to be registered
     * @param stateless Whether the given implementation is considered stateless or not
     */
    function register(string memory name, address implementation, bool stateless) external;

    /**
     * @dev Deprecates an implementation
     * @param implementation Address of the implementation to be deprecated
     */
    function deprecate(address implementation) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import '@mimic-fi/v3-authorizer/contracts/interfaces/IAuthorized.sol';

/**
 * @dev Smart Vault interface
 */
interface ISmartVault is IAuthorized {
    /**
     * @dev Emitted every time a smart vault is paused
     */
    event Paused();

    /**
     * @dev Emitted every time a smart vault is unpaused
     */
    event Unpaused();

    /**
     * @dev Emitted every time the price oracle is set
     */
    event PriceOracleSet(address indexed priceOracle);

    /**
     * @dev Emitted every time a connector check is overridden
     */
    event ConnectorCheckOverridden(address indexed connector, bool ignored);

    /**
     * @dev Emitted every time a balance connector is updated
     */
    event BalanceConnectorUpdated(bytes32 indexed id, address indexed token, uint256 amount, bool added);

    /**
     * @dev Emitted every time `execute` is called
     */
    event Executed(address indexed connector, bytes data, bytes result);

    /**
     * @dev Emitted every time `call` is called
     */
    event Called(address indexed target, bytes data, uint256 value, bytes result);

    /**
     * @dev Emitted every time `wrap` is called
     */
    event Wrapped(uint256 amount);

    /**
     * @dev Emitted every time `unwrap` is called
     */
    event Unwrapped(uint256 amount);

    /**
     * @dev Emitted every time `collect` is called
     */
    event Collected(address indexed token, address indexed from, uint256 amount);

    /**
     * @dev Emitted every time `withdraw` is called
     */
    event Withdrawn(address indexed token, address indexed recipient, uint256 amount, uint256 fee);

    /**
     * @dev Tells if the smart vault is paused or not
     */
    function isPaused() external view returns (bool);

    /**
     * @dev Tells the address of the price oracle
     */
    function priceOracle() external view returns (address);

    /**
     * @dev Tells the address of the Mimic's registry
     */
    function registry() external view returns (address);

    /**
     * @dev Tells the address of the Mimic's fee controller
     */
    function feeController() external view returns (address);

    /**
     * @dev Tells the address of the wrapped native token
     */
    function wrappedNativeToken() external view returns (address);

    /**
     * @dev Tells if a connector check is ignored
     * @param connector Address of the connector being queried
     */
    function isConnectorCheckIgnored(address connector) external view returns (bool);

    /**
     * @dev Tells the balance to a balance connector for a token
     * @param id Balance connector identifier
     * @param token Address of the token querying the balance connector for
     */
    function getBalanceConnector(bytes32 id, address token) external view returns (uint256);

    /**
     * @dev Tells whether someone has any permission over the smart vault
     */
    function hasPermissions(address who) external view returns (bool);

    /**
     * @dev Pauses a smart vault
     */
    function pause() external;

    /**
     * @dev Unpauses a smart vault
     */
    function unpause() external;

    /**
     * @dev Sets the price oracle
     * @param newPriceOracle Address of the new price oracle to be set
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @dev Overrides connector checks
     * @param connector Address of the connector to override its check
     * @param ignored Whether the connector check should be ignored
     */
    function overrideConnectorCheck(address connector, bool ignored) external;

    /**
     * @dev Updates a balance connector
     * @param id Balance connector identifier to be updated
     * @param token Address of the token to update the balance connector for
     * @param amount Amount to be updated to the balance connector
     * @param add Whether the balance connector should be increased or decreased
     */
    function updateBalanceConnector(bytes32 id, address token, uint256 amount, bool add) external;

    /**
     * @dev Executes a connector inside of the Smart Vault context
     * @param connector Address of the connector that will be executed
     * @param data Call data to be used for the delegate-call
     * @return result Call response if it was successful, otherwise it reverts
     */
    function execute(address connector, bytes memory data) external returns (bytes memory result);

    /**
     * @dev Executes an arbitrary call from the Smart Vault
     * @param target Address where the call will be sent
     * @param data Call data to be used for the call
     * @param value Value in wei that will be attached to the call
     * @return result Call response if it was successful, otherwise it reverts
     */
    function call(address target, bytes memory data, uint256 value) external returns (bytes memory result);

    /**
     * @dev Wrap an amount of native tokens to the wrapped ERC20 version of it
     * @param amount Amount of native tokens to be wrapped
     */
    function wrap(uint256 amount) external;

    /**
     * @dev Unwrap an amount of wrapped native tokens
     * @param amount Amount of wrapped native tokens to unwrapped
     */
    function unwrap(uint256 amount) external;

    /**
     * @dev Collect tokens from an external account to the Smart Vault
     * @param token Address of the token to be collected
     * @param from Address where the tokens will be transferred from
     * @param amount Amount of tokens to be transferred
     */
    function collect(address token, address from, uint256 amount) external;

    /**
     * @dev Withdraw tokens to an external account
     * @param token Address of the token to be withdrawn
     * @param recipient Address where the tokens will be transferred to
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(address token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-authorizer/contracts/interfaces/IAuthorizer.sol';
import '@mimic-fi/v3-fee-controller/contracts/interfaces/IFeeController.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';
import '@mimic-fi/v3-helpers/contracts/utils/IWrappedNativeToken.sol';
import '@mimic-fi/v3-price-oracle/contracts/interfaces/IPriceOracle.sol';
import '@mimic-fi/v3-registry/contracts/interfaces/IRegistry.sol';

import './interfaces/ISmartVault.sol';

/**
 * @title Smart Vault
 * @dev Core component where the interaction with the DeFi world occurs
 */
contract SmartVault is ISmartVault, Authorized, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using FixedPoint for uint256;

    // Whether the smart vault is paused or not
    bool public override isPaused;

    // Price oracle reference
    address public override priceOracle;

    // Mimic registry reference
    address public immutable override registry;

    // Mimic fee controller reference
    address public immutable override feeController;

    // Wrapped native token reference
    address public immutable override wrappedNativeToken;

    // Tells whether a connector check is ignored or not
    mapping (address => bool) public override isConnectorCheckIgnored;

    // Balance connectors are used to define separate tasks workflows, indexed from id and token address
    mapping (bytes32 => mapping (address => uint256)) public override getBalanceConnector;

    /**
     * @dev Modifier to tag smart vault functions in order to check if it is paused
     */
    modifier notPaused() {
        require(!isPaused, 'SMART_VAULT_PAUSED');
        _;
    }

    /**
     * @dev Creates a new Smart Vault implementation with the references that should be shared among all implementations
     * @param _registry Address of the Mimic registry to be referenced
     * @param _feeController Address of the Mimic fee controller to be referenced
     * @param _wrappedNativeToken Address of the wrapped native token to be used
     */
    constructor(address _registry, address _feeController, address _wrappedNativeToken) {
        registry = _registry;
        feeController = _feeController;
        wrappedNativeToken = _wrappedNativeToken;
    }

    /**
     * @dev Initializes the smart vault
     * @param _authorizer Address of the authorizer to be linked
     * @param _priceOracle Address of the price oracle to be set, it is ignored in case it's zero
     */
    function initialize(address _authorizer, address _priceOracle) external virtual initializer {
        __SmartVault_init(_authorizer, _priceOracle);
    }

    /**
     * @dev Initializes the smart vault. It does call upper contracts initializers.
     * @param _authorizer Address of the authorizer to be linked
     * @param _priceOracle Address of the price oracle to be set, it is ignored in case it's zero
     */
    function __SmartVault_init(address _authorizer, address _priceOracle) internal onlyInitializing {
        __ReentrancyGuard_init();
        __Authorized_init(_authorizer);
        __SmartVault_init_unchained(_authorizer, _priceOracle);
    }

    /**
     * @dev Initializes the smart vault. It does not call upper contracts initializers.
     * @param _priceOracle Address of the price oracle to be set, it is ignored in case it's zero
     */
    function __SmartVault_init_unchained(address, address _priceOracle) internal onlyInitializing {
        _setPriceOracle(_priceOracle);
    }

    /**
     * @dev It allows receiving native token transfers
     */
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells whether someone has any permission over the smart vault
     */
    function hasPermissions(address who) external view override returns (bool) {
        return _hasPermissions(who);
    }

    /**
     * @dev Pauses a smart vault. Sender must be authorized.
     */
    function pause() external override auth {
        require(!isPaused, 'SMART_VAULT_ALREADY_PAUSED');
        isPaused = true;
        emit Paused();
    }

    /**
     * @dev Unpauses a samrt vault. Sender must be authorized.
     */
    function unpause() external override auth {
        require(isPaused, 'SMART_VAULT_ALREADY_UNPAUSED');
        isPaused = false;
        emit Unpaused();
    }

    /**
     * @dev Sets the price oracle. Sender must be authorized. Smart vault must not be paused.
     * @param newPriceOracle Address of the new price oracle to be set
     */
    function setPriceOracle(address newPriceOracle)
        external
        override
        nonReentrant
        notPaused
        authP(authParams(newPriceOracle))
    {
        _setPriceOracle(newPriceOracle);
    }

    /**
     * @dev Overrides connector checks. Sender must be authorized. Smart vault must not be paused.
     * @param connector Address of the connector to override its check
     * @param ignored Whether the connector check should be ignored
     */
    function overrideConnectorCheck(address connector, bool ignored)
        external
        override
        nonReentrant
        notPaused
        authP(authParams(connector, ignored))
    {
        isConnectorCheckIgnored[connector] = ignored;
        emit ConnectorCheckOverridden(connector, ignored);
    }

    /**
     * @dev Updates a balance connector. Sender must be authorized. Smart vault must not be paused.
     * @param id Balance connector identifier to be updated
     * @param token Address of the token to update the balance connector for
     * @param amount Amount to be updated to the balance connector
     * @param add Whether the balance connector should be increased or decreased
     */
    function updateBalanceConnector(bytes32 id, address token, uint256 amount, bool add)
        external
        override
        nonReentrant
        notPaused
        authP(authParams(id, token, amount, add))
    {
        require(id != bytes32(0), 'SMART_VAULT_CONNECTOR_ID_ZERO');
        require(token != address(0), 'SMART_VAULT_CONNECTOR_TOKEN_ZERO');
        (add ? _increaseBalanceConnector : _decreaseBalanceConnector)(id, token, amount);
    }

    /**
     * @dev Executes a connector inside of the Smart Vault context. Sender must be authorized. Smart vault must not be paused.
     * @param connector Address of the connector that will be executed
     * @param data Call data to be used for the delegate-call
     * @return result Call response if it was successful, otherwise it reverts
     */
    function execute(address connector, bytes memory data)
        external
        override
        nonReentrant
        notPaused
        authP(authParams(connector))
        returns (bytes memory result)
    {
        _validateConnector(connector);
        result = Address.functionDelegateCall(connector, data, 'SMART_VAULT_EXECUTE_FAILED');
        emit Executed(connector, data, result);
    }

    /**
     * @dev Executes an arbitrary call from the Smart Vault. Sender must be authorized. Smart vault must not be paused.
     * @param target Address where the call will be sent
     * @param data Call data to be used for the call
     * @param value Value in wei that will be attached to the call
     * @return result Call response if it was successful, otherwise it reverts
     */
    function call(address target, bytes memory data, uint256 value)
        external
        override
        nonReentrant
        notPaused
        authP(authParams(target))
        returns (bytes memory result)
    {
        result = Address.functionCallWithValue(target, data, value, 'SMART_VAULT_CALL_FAILED');
        emit Called(target, data, value, result);
    }

    /**
     * @dev Wrap an amount of native tokens to the wrapped ERC20 version of it. Sender must be authorized. Smart vault must not be paused.
     * @param amount Amount of native tokens to be wrapped
     */
    function wrap(uint256 amount) external override nonReentrant notPaused authP(authParams(amount)) {
        require(amount > 0, 'SMART_VAULT_WRAP_AMOUNT_ZERO');
        require(address(this).balance >= amount, 'SMART_VAULT_WRAP_NO_BALANCE');
        IWrappedNativeToken(wrappedNativeToken).deposit{ value: amount }();
        emit Wrapped(amount);
    }

    /**
     * @dev Unwrap an amount of wrapped native tokens. Sender must be authorized. Smart vault must not be paused.
     * @param amount Amount of wrapped native tokens to unwrapped
     */
    function unwrap(uint256 amount) external override nonReentrant notPaused authP(authParams(amount)) {
        require(amount > 0, 'SMART_VAULT_UNWRAP_AMOUNT_ZERO');
        IWrappedNativeToken(wrappedNativeToken).withdraw(amount);
        emit Unwrapped(amount);
    }

    /**
     * @dev Collect tokens from an external account to the Smart Vault. Sender must be authorized. Smart vault must not be paused.
     * @param token Address of the token to be collected
     * @param from Address where the tokens will be transferred from
     * @param amount Amount of tokens to be transferred
     */
    function collect(address token, address from, uint256 amount)
        external
        override
        nonReentrant
        notPaused
        authP(authParams(token, from, amount))
    {
        require(amount > 0, 'SMART_VAULT_COLLECT_AMOUNT_ZERO');
        IERC20(token).safeTransferFrom(from, address(this), amount);
        emit Collected(token, from, amount);
    }

    /**
     * @dev Withdraw tokens to an external account. Sender must be authorized. Smart vault must not be paused.
     * @param token Address of the token to be withdrawn
     * @param recipient Address where the tokens will be transferred to
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(address token, address recipient, uint256 amount)
        external
        override
        nonReentrant
        notPaused
        authP(authParams(token, recipient, amount))
    {
        require(amount > 0, 'SMART_VAULT_WITHDRAW_AMOUNT_ZERO');
        require(recipient != address(0), 'SMART_VAULT_WITHDRAW_DEST_ZERO');

        (, uint256 pct, address collector) = IFeeController(feeController).getFee(address(this));
        uint256 feeAmount = amount.mulDown(pct);
        _safeTransfer(token, collector, feeAmount);

        uint256 withdrawn = amount - feeAmount;
        _safeTransfer(token, recipient, withdrawn);
        emit Withdrawn(token, recipient, withdrawn, feeAmount);
    }

    /**
     * @dev Transfers ERC20 or native tokens from the Smart Vault to an external account
     * @param token Address of the ERC20 token to transfer
     * @param to Address transferring the tokens to
     * @param amount Amount of tokens to transfer
     */
    function _safeTransfer(address token, address to, uint256 amount) internal {
        if (amount == 0) return;
        ERC20Helpers.transfer(token, to, amount);
    }

    /**
     * @dev Sets the price oracle instance
     * @param newPriceOracle Address of the new price oracle to be set
     */
    function _setPriceOracle(address newPriceOracle) internal {
        priceOracle = newPriceOracle;
        emit PriceOracleSet(newPriceOracle);
    }

    /**
     * @dev Increases a balance connector
     * @param id Balance connector id to be increased
     * @param token Address of the token to increase the balance connector for
     * @param amount Amount to be added to the connector
     */
    function _increaseBalanceConnector(bytes32 id, address token, uint256 amount) internal {
        getBalanceConnector[id][token] += amount;
        emit BalanceConnectorUpdated(id, token, amount, true);
    }

    /**
     * @dev Decreases a balance connector
     * @param id Balance connector id
     * @param token Address of the token to decrease the balance connector for
     * @param amount Amount to be added to the connector
     */
    function _decreaseBalanceConnector(bytes32 id, address token, uint256 amount) internal {
        uint256 value = getBalanceConnector[id][token];
        require(value >= amount, 'SMART_VAULT_CONNECTOR_NO_BALANCE');
        getBalanceConnector[id][token] = value - amount;
        emit BalanceConnectorUpdated(id, token, amount, false);
    }

    /**
     * @dev Validates a connector against the Mimic Registry
     * @param connector Address of the connector to validate
     */
    function _validateConnector(address connector) private view {
        if (isConnectorCheckIgnored[connector]) return;
        require(IRegistry(registry).isRegistered(connector), 'SMART_VAULT_CON_NOT_REGISTERED');
        require(IRegistry(registry).isStateless(connector), 'SMART_VAULT_CON_NOT_STATELESS');
        require(!IRegistry(registry).isDeprecated(connector), 'SMART_VAULT_CON_DEPRECATED');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v3-price-oracle/contracts/interfaces/IPriceOracle.sol';
import '@mimic-fi/v3-smart-vault/contracts/interfaces/ISmartVault.sol';

import '../interfaces/base/IBaseTask.sol';

/**
 * @title BaseTask
 * @dev Base task implementation with a Smart Vault reference and using the Authorizer
 */
abstract contract BaseTask is IBaseTask, Authorized {
    // Smart Vault reference
    address public override smartVault;

    // Optional balance connector id for the previous task in the workflow
    bytes32 public override previousBalanceConnectorId;

    // Optional balance connector id for the next task in the workflow
    bytes32 public override nextBalanceConnectorId;

    /**
     * @dev Base task config. Only used in the initializer.
     * @param smartVault Address of the smart vault this task will reference, it cannot be changed once set
     * @param previousBalanceConnectorId Balance connector id for the previous task in the workflow
     * @param nextBalanceConnectorId Balance connector id for the next task in the workflow
     */
    struct BaseConfig {
        address smartVault;
        bytes32 previousBalanceConnectorId;
        bytes32 nextBalanceConnectorId;
    }

    /**
     * @dev Initializes the base task. It does call upper contracts initializers.
     * @param config Base task config
     */
    function __BaseTask_init(BaseConfig memory config) internal onlyInitializing {
        __Authorized_init(ISmartVault(config.smartVault).authorizer());
        __BaseTask_init_unchained(config);
    }

    /**
     * @dev Initializes the base task. It does not call upper contracts initializers.
     * @param config Base task config
     */
    function __BaseTask_init_unchained(BaseConfig memory config) internal onlyInitializing {
        smartVault = config.smartVault;
        _setBalanceConnectors(config.previousBalanceConnectorId, config.nextBalanceConnectorId);
    }

    /**
     * @dev Tells the address from where the token amounts to execute this task are fetched.
     * Since by default tasks are supposed to use balance connectors, the tokens source has to be the smart vault.
     * In case a task does not need to rely on a previous balance connector, it must override this function to specify
     * where it is getting its tokens from.
     */
    function getTokensSource() external view virtual override returns (address) {
        return smartVault;
    }

    /**
     * @dev Tells the amount a task should use for a token. By default tasks are expected to use balance connectors.
     * In case a task relies on an external tokens source, it must override how the task amount is calculated.
     * @param token Address of the token being queried
     */
    function getTaskAmount(address token) external view virtual override returns (uint256) {
        return ISmartVault(smartVault).getBalanceConnector(previousBalanceConnectorId, token);
    }

    /**
     * @dev Sets the balance connectors
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function setBalanceConnectors(bytes32 previous, bytes32 next) external override authP(authParams(previous, next)) {
        _setBalanceConnectors(previous, next);
    }

    /**
     * @dev Before base task hook
     */
    function _beforeBaseTask(address token, uint256 amount) internal virtual {
        _decreaseBalanceConnector(token, amount);
    }

    /**
     * @dev After base task hook
     */
    function _afterBaseTask(address, uint256) internal virtual {
        emit Executed();
    }

    /**
     * @dev Decreases the previous balance connector in the smart vault if defined
     * @param token Address of the token to update the previous balance connector of
     * @param amount Amount to be updated
     */
    function _decreaseBalanceConnector(address token, uint256 amount) internal {
        if (previousBalanceConnectorId != bytes32(0)) {
            ISmartVault(smartVault).updateBalanceConnector(previousBalanceConnectorId, token, amount, false);
        }
    }

    /**
     * @dev Increases the next balance connector in the smart vault if defined
     * @param token Address of the token to update the next balance connector of
     * @param amount Amount to be updated
     */
    function _increaseBalanceConnector(address token, uint256 amount) internal {
        if (nextBalanceConnectorId != bytes32(0)) {
            ISmartVault(smartVault).updateBalanceConnector(nextBalanceConnectorId, token, amount, true);
        }
    }

    /**
     * @dev Sets the balance connectors
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal virtual {
        require(previous != next || previous == bytes32(0), 'TASK_SAME_BALANCE_CONNECTORS');
        previousBalanceConnectorId = previous;
        nextBalanceConnectorId = next;
        emit BalanceConnectorsSet(previous, next);
    }

    /**
     * @dev Fetches a base/quote price from the smart vault's price oracle
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256) {
        address priceOracle = ISmartVault(smartVault).priceOracle();
        require(priceOracle != address(0), 'TASK_PRICE_ORACLE_NOT_SET');
        return IPriceOracle(priceOracle).getPrice(_wrappedIfNative(base), _wrappedIfNative(quote));
    }

    /**
     * @dev Tells the wrapped native token address if the given address is the native token
     * @param token Address of the token to be checked
     */
    function _wrappedIfNative(address token) internal view returns (address) {
        return Denominations.isNativeToken(token) ? _wrappedNativeToken() : token;
    }

    /**
     * @dev Tells whether a token is the native or the wrapped native token
     */
    function _isWrappedOrNative(address token) internal view returns (bool) {
        return Denominations.isNativeToken(token) || token == _wrappedNativeToken();
    }

    /**
     * @dev Tells the wrapped native token address
     */
    function _wrappedNativeToken() internal view returns (address) {
        return ISmartVault(smartVault).wrappedNativeToken();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import '@mimic-fi/v3-authorizer/contracts/interfaces/IAuthorized.sol';

/**
 * @dev Base task interface
 */
interface IBaseTask is IAuthorized {
    // Execution type serves for relayers in order to distinguish how each task must be executed
    // solhint-disable-next-line func-name-mixedcase
    function EXECUTION_TYPE() external view returns (bytes32);

    /**
     * @dev Emitted every time a task is executed
     */
    event Executed();

    /**
     * @dev Emitted every time the balance connectors are set
     */
    event BalanceConnectorsSet(bytes32 indexed previous, bytes32 indexed next);

    /**
     * @dev Tells the address of the Smart Vault tied to it, it cannot be changed
     */
    function smartVault() external view returns (address);

    /**
     * @dev Tells the balance connector id of the previous task in the workflow
     */
    function previousBalanceConnectorId() external view returns (bytes32);

    /**
     * @dev Tells the balance connector id of the next task in the workflow
     */
    function nextBalanceConnectorId() external view returns (bytes32);

    /**
     * @dev Tells the address from where the token amounts to execute this task are fetched.
     * This address must the the Smart Vault in case the previous balance connector is set.
     */
    function getTokensSource() external view returns (address);

    /**
     * @dev Tells the amount a task should use for a token
     * @param token Address of the token being queried
     */
    function getTaskAmount(address token) external view returns (uint256);

    /**
     * @dev Sets the balance connector IDs
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function setBalanceConnectors(bytes32 previous, bytes32 next) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at you[r option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import 'solmate/src/utils/CREATE3.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v3-authorizer/contracts/Authorizer.sol';
import '@mimic-fi/v3-price-oracle/contracts/PriceOracle.sol';
import '@mimic-fi/v3-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v3-registry/contracts/interfaces/IRegistry.sol';

contract Deployer {
    using Address for address;

    // Registry reference
    IRegistry public immutable registry;

    /**
     * @dev Emitted every time an authorizer is deployed
     */
    event AuthorizerDeployed(string namespace, string name, address instance, address implementation);

    /**
     * @dev Emitted every time a price oracle is deployed
     */
    event PriceOracleDeployed(string namespace, string name, address instance, address implementation);

    /**Bas
     * @dev Emitted every time a smart vault is deployed
     */
    event SmartVaultDeployed(string namespace, string name, address instance, address implementation);

    /**
     * @dev Emitted every time a task is deployed
     */
    event TaskDeployed(string namespace, string name, address instance, address implementation);

    /**
     * @dev Creates a new Deployer contract
     * @param _registry Address of the Mimic Registry to be referenced
     */
    constructor(IRegistry _registry) {
        registry = _registry;
    }

    /**
     * @dev Authorizer params
     * @param impl Address of the Authorizer implementation to be used
     * @param owners List of addresses that will be allowed to authorize and unauthorize permissions
     */
    struct AuthorizerParams {
        address impl;
        address[] owners;
    }

    /**
     * @dev Price oracle params
     * @param impl Address of the Price Oracle implementation to be used
     * @param authorizer Address of the authorizer to be linked
     * @param signer Address of the allowed signer
     * @param pivot Address of the token to be used as the pivot
     * @param feeds List of feeds to be set for the price oracle
     */
    struct PriceOracleParams {
        address impl;
        address authorizer;
        address signer;
        address pivot;
        PriceOracle.FeedData[] feeds;
    }

    /**
     * @dev Smart vault params
     * @param impl Address of the Smart Vault implementation to be used
     * @param authorizer Address of the authorizer to be linked
     * @param priceOracle Optional price Oracle to set for the Smart Vault
     */
    struct SmartVaultParams {
        address impl;
        address authorizer;
        address priceOracle;
    }

    /**
     * @dev Task params
     * @param custom Whether the implementation is custom or not, if it is it won't be checked with Mimic's Registry
     * @param impl Address of the task implementation to be used
     * @param initializeData Call-data to initialize the new task instance
     */
    struct TaskParams {
        bool custom;
        address impl;
        bytes initializeData;
    }

    /**
     * @dev Tells the deployed address for a given input
     */
    function getAddress(address sender, string memory namespace, string memory name) external view returns (address) {
        return CREATE3.getDeployed(getSalt(sender, namespace, name));
    }

    /**
     * @dev Tells the salt for a given input
     */
    function getSalt(address sender, string memory namespace, string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, namespace, name));
    }

    /**
     * @dev Deploys a new authorizer instance
     */
    function deployAuthorizer(string memory namespace, string memory name, AuthorizerParams memory params) external {
        _validateImplementation(params.impl);
        address instance = _deployClone(namespace, name, params.impl);
        Authorizer(instance).initialize(params.owners);
        emit AuthorizerDeployed(namespace, name, instance, params.impl);
    }

    /**
     * @dev Deploys a new price oracle instance
     */
    function deployPriceOracle(string memory namespace, string memory name, PriceOracleParams memory params) external {
        _validateImplementation(params.impl);
        address instance = _deployClone(namespace, name, params.impl);
        PriceOracle(instance).initialize(params.authorizer, params.signer, params.pivot, params.feeds);
        emit PriceOracleDeployed(namespace, name, instance, params.impl);
    }

    /**
     * @dev Deploys a new smart vault instance
     */
    function deploySmartVault(string memory namespace, string memory name, SmartVaultParams memory params) external {
        _validateImplementation(params.impl);
        address payable instance = payable(_deployClone(namespace, name, params.impl));
        SmartVault(instance).initialize(params.authorizer, params.priceOracle);
        emit SmartVaultDeployed(namespace, name, instance, params.impl);
    }

    /**
     * @dev Deploys a new task instance
     */
    function deployTask(string memory namespace, string memory name, TaskParams memory params) external {
        if (!params.custom) _validateImplementation(params.impl);
        address instance = _deployClone(namespace, name, params.impl);
        if (params.initializeData.length > 0) instance.functionCall(params.initializeData, 'DEPLOYER_TASK_INIT_FAILED');
        emit TaskDeployed(namespace, name, instance, params.impl);
    }

    /**
     * @dev Validates if an implementation is registered, not deprecated, and considered stateful
     * @param implementation Address of the implementation to be checked
     */
    function _validateImplementation(address implementation) internal view {
        require(registry.isRegistered(implementation), 'DEPLOYER_IMPL_NOT_REGISTERED');
        require(!registry.isStateless(implementation), 'DEPLOYER_IMPL_STATELESS');
        require(!registry.isDeprecated(implementation), 'DEPLOYER_IMPL_DEPRECATED');
    }

    /**
     * @dev Deploys a new clone using CREATE3
     */
    function _deployClone(string memory namespace, string memory name, address implementation)
        internal
        returns (address)
    {
        require(bytes(namespace).length > 0, 'DEPLOYER_NAMESPACE_EMPTY');
        require(bytes(name).length > 0, 'DEPLOYER_NAME_EMPTY');

        bytes memory bytecode = abi.encodePacked(
            hex'3d602d80600a3d3981f3363d3d373d3d3d363d73',
            implementation,
            hex'5af43d82803e903d91602b57fd5bf3'
        );

        bytes32 salt = getSalt(msg.sender, namespace, name);
        return CREATE3.deploy(salt, bytecode, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@mimic-fi/v3-tasks/contracts/base/BaseTask.sol';

contract TaskMock is BaseTask {
    bytes32 public constant override EXECUTION_TYPE = keccak256('TASK');

    function initialize(BaseConfig memory config) external virtual initializer {
        __BaseTask_init(config);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Bytes32AddressLib} from "./Bytes32AddressLib.sol";

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                address(this),
                // Salt:
                salt,
                // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}