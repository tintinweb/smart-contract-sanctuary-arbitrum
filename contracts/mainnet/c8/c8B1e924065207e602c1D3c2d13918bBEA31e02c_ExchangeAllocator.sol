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

pragma solidity ^0.8.17;

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-smart-vault/contracts/interfaces/ISmartVault.sol';

import '../interfaces/base/IGasLimitedTask.sol';

/**
 * @dev Gas config for tasks. It allows setting different gas-related configs, specially useful to control relayed txs.
 */
abstract contract GasLimitedTask is IGasLimitedTask, Authorized {
    using FixedPoint for uint256;

    // Variable used to allow a better developer experience to reimburse tx gas cost
    // solhint-disable-next-line var-name-mixedcase
    uint256 private __initialGas__;

    // Gas price limit expressed in the native token
    uint256 public override gasPriceLimit;

    // Priority fee limit expressed in the native token
    uint256 public override priorityFeeLimit;

    // Total transaction cost limit expressed in the native token
    uint256 public override txCostLimit;

    // Transaction cost limit percentage
    uint256 public override txCostLimitPct;

    /**
     * @dev Gas limit config params. Only used in the initializer.
     * @param gasPriceLimit Gas price limit expressed in the native token
     * @param priorityFeeLimit Priority fee limit expressed in the native token
     * @param txCostLimit Transaction cost limit to be set
     * @param txCostLimitPct Transaction cost limit percentage to be set
     */
    struct GasLimitConfig {
        uint256 gasPriceLimit;
        uint256 priorityFeeLimit;
        uint256 txCostLimit;
        uint256 txCostLimitPct;
    }

    /**
     * @dev Initializes the gas limited task. It does call upper contracts initializers.
     * @param config Gas limited task config
     */
    function __GasLimitedTask_init(GasLimitConfig memory config) internal onlyInitializing {
        __GasLimitedTask_init_unchained(config);
    }

    /**
     * @dev Initializes the gas limited task. It does not call upper contracts initializers.
     * @param config Gas limited task config
     */
    function __GasLimitedTask_init_unchained(GasLimitConfig memory config) internal onlyInitializing {
        _setGasPriceLimit(config.gasPriceLimit);
        _setPriorityFeeLimit(config.priorityFeeLimit);
        _setTxCostLimit(config.txCostLimit);
        _setTxCostLimitPct(config.txCostLimitPct);
    }

    /**
     * @dev Sets the gas price limit
     * @param newGasPriceLimit New gas price limit to be set
     */
    function setGasPriceLimit(uint256 newGasPriceLimit) external override authP(authParams(newGasPriceLimit)) {
        _setGasPriceLimit(newGasPriceLimit);
    }

    /**
     * @dev Sets the priority fee limit
     * @param newPriorityFeeLimit New priority fee limit to be set
     */
    function setPriorityFeeLimit(uint256 newPriorityFeeLimit) external override authP(authParams(newPriorityFeeLimit)) {
        _setPriorityFeeLimit(newPriorityFeeLimit);
    }

    /**
     * @dev Sets the transaction cost limit
     * @param newTxCostLimit New transaction cost limit to be set
     */
    function setTxCostLimit(uint256 newTxCostLimit) external override authP(authParams(newTxCostLimit)) {
        _setTxCostLimit(newTxCostLimit);
    }

    /**
     * @dev Sets the transaction cost limit percentage
     * @param newTxCostLimitPct New transaction cost limit percentage to be set
     */
    function setTxCostLimitPct(uint256 newTxCostLimitPct) external override authP(authParams(newTxCostLimitPct)) {
        _setTxCostLimitPct(newTxCostLimitPct);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256);

    /**
     * @dev Initializes gas limited tasks and validates gas price limit
     */
    function _beforeGasLimitedTask(address, uint256) internal virtual {
        __initialGas__ = gasleft();
        require(gasPriceLimit == 0 || tx.gasprice <= gasPriceLimit, 'TASK_GAS_PRICE_LIMIT');
        require(priorityFeeLimit == 0 || tx.gasprice - block.basefee <= priorityFeeLimit, 'TASK_PRIORITY_FEE_LIMIT');
    }

    /**
     * @dev Validates transaction cost limit
     */
    function _afterGasLimitedTask(address token, uint256 amount) internal virtual {
        require(__initialGas__ > 0, 'TASK_GAS_NOT_INITIALIZED');

        uint256 totalGas = __initialGas__ - gasleft();
        uint256 totalCost = totalGas * tx.gasprice;
        require(txCostLimit == 0 || totalCost <= txCostLimit, 'TASK_TX_COST_LIMIT');
        delete __initialGas__;

        if (txCostLimitPct > 0) {
            require(amount > 0, 'TASK_TX_COST_LIMIT_PCT');
            uint256 price = _getPrice(ISmartVault(this.smartVault()).wrappedNativeToken(), token);
            uint256 totalCostInToken = totalCost.mulUp(price);
            require(totalCostInToken.divUp(amount) <= txCostLimitPct, 'TASK_TX_COST_LIMIT_PCT');
        }
    }

    /**
     * @dev Sets the gas price limit
     * @param newGasPriceLimit New gas price limit to be set
     */
    function _setGasPriceLimit(uint256 newGasPriceLimit) internal {
        gasPriceLimit = newGasPriceLimit;
        emit GasPriceLimitSet(newGasPriceLimit);
    }

    /**
     * @dev Sets the priority fee limit
     * @param newPriorityFeeLimit New priority fee limit to be set
     */
    function _setPriorityFeeLimit(uint256 newPriorityFeeLimit) internal {
        priorityFeeLimit = newPriorityFeeLimit;
        emit PriorityFeeLimitSet(newPriorityFeeLimit);
    }

    /**
     * @dev Sets the transaction cost limit
     * @param newTxCostLimit New transaction cost limit to be set
     */
    function _setTxCostLimit(uint256 newTxCostLimit) internal {
        txCostLimit = newTxCostLimit;
        emit TxCostLimitSet(newTxCostLimit);
    }

    /**
     * @dev Sets the transaction cost limit percentage
     * @param newTxCostLimitPct New transaction cost limit percentage to be set
     */
    function _setTxCostLimitPct(uint256 newTxCostLimitPct) internal {
        require(newTxCostLimitPct <= FixedPoint.ONE, 'TASK_TX_COST_LIMIT_PCT_ABOVE_ONE');
        txCostLimitPct = newTxCostLimitPct;
        emit TxCostLimitPctSet(newTxCostLimitPct);
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

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import '../interfaces/base/IPausableTask.sol';

/**
 * @dev Pausable config for tasks
 */
abstract contract PausableTask is IPausableTask, Authorized {
    using FixedPoint for uint256;

    // Whether the task is paused or not
    bool public override isPaused;

    /**
     * @dev Initializes the pausable task. It does call upper contracts initializers.
     */
    function __PausableTask_init() internal onlyInitializing {
        __PausableTask_init_unchained();
    }

    /**
     * @dev Initializes the pausable task. It does not call upper contracts initializers.
     */
    function __PausableTask_init_unchained() internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Pauses a task
     */
    function pause() external override auth {
        require(!isPaused, 'TASK_ALREADY_PAUSED');
        isPaused = true;
        emit Paused();
    }

    /**
     * @dev Unpauses a task
     */
    function unpause() external override auth {
        require(isPaused, 'TASK_ALREADY_UNPAUSED');
        isPaused = false;
        emit Unpaused();
    }

    /**
     * @dev Before pausable task hook
     */
    function _beforePausableTask(address, uint256) internal virtual {
        require(!isPaused, 'TASK_PAUSED');
    }

    /**
     * @dev After pausable task hook
     */
    function _afterPausableTask(address, uint256) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
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

pragma solidity ^0.8.3;

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '../interfaces/base/ITimeLockedTask.sol';

/**
 * @dev Time lock config for tasks. It allows limiting the frequency of a task.
 */
abstract contract TimeLockedTask is ITimeLockedTask, Authorized {
    // Period in seconds that must pass after a task has been executed
    uint256 public override timeLockDelay;

    // Future timestamp in which the task can be executed
    uint256 public override timeLockExpiration;

    // Period in seconds during when a time-locked task can be executed right after it becomes executable
    uint256 public override timeLockExecutionPeriod;

    /**
     * @dev Time lock config params. Only used in the initializer.
     * @param delay Period in seconds that must pass after a task has been executed
     * @param nextExecutionTimestamp Next time when the task can be executed
     * @param executionPeriod Period in seconds during when a time-locked task can be executed
     */
    struct TimeLockConfig {
        uint256 delay;
        uint256 nextExecutionTimestamp;
        uint256 executionPeriod;
    }

    /**
     * @dev Initializes the time locked task. It does not call upper contracts initializers.
     * @param config Time locked task config
     */
    function __TimeLockedTask_init(TimeLockConfig memory config) internal onlyInitializing {
        __TimeLockedTask_init_unchained(config);
    }

    /**
     * @dev Initializes the time locked task. It does call upper contracts initializers.
     * @param config Time locked task config
     */
    function __TimeLockedTask_init_unchained(TimeLockConfig memory config) internal onlyInitializing {
        _setTimeLockDelay(config.delay);
        _setTimeLockExpiration(config.nextExecutionTimestamp);
        _setTimeLockExecutionPeriod(config.executionPeriod);
    }

    /**
     * @dev Sets the time-lock delay
     * @param delay New delay to be set
     */
    function setTimeLockDelay(uint256 delay) external override authP(authParams(delay)) {
        _setTimeLockDelay(delay);
    }

    /**
     * @dev Sets the time-lock expiration timestamp
     * @param expiration New expiration timestamp to be set
     */
    function setTimeLockExpiration(uint256 expiration) external override authP(authParams(expiration)) {
        _setTimeLockExpiration(expiration);
    }

    /**
     * @dev Sets the time-lock execution period
     * @param period New execution period to be set
     */
    function setTimeLockExecutionPeriod(uint256 period) external override authP(authParams(period)) {
        _setTimeLockExecutionPeriod(period);
    }

    /**
     * @dev Tells the number of delay periods passed between the last expiration timestamp and the current timestamp
     */
    function _getDelayPeriods() internal view returns (uint256) {
        uint256 diff = block.timestamp - timeLockExpiration;
        return diff / timeLockDelay;
    }

    /**
     * @dev Before time locked task hook
     */
    function _beforeTimeLockedTask(address, uint256) internal virtual {
        require(block.timestamp >= timeLockExpiration, 'TASK_TIME_LOCK_NOT_EXPIRED');

        if (timeLockExecutionPeriod > 0) {
            uint256 diff = block.timestamp - timeLockExpiration;
            uint256 periods = diff / timeLockDelay;
            uint256 offset = diff - (periods * timeLockDelay);
            require(offset <= timeLockExecutionPeriod, 'TASK_TIME_LOCK_WAIT_NEXT_PERIOD');
        }
    }

    /**
     * @dev After time locked task hook
     */
    function _afterTimeLockedTask(address, uint256) internal virtual {
        if (timeLockDelay > 0) {
            uint256 nextExpirationTimestamp;
            if (timeLockExpiration == 0) {
                nextExpirationTimestamp = block.timestamp + timeLockDelay;
            } else {
                uint256 diff = block.timestamp - timeLockExpiration;
                uint256 nextPeriod = (diff / timeLockDelay) + 1;
                nextExpirationTimestamp = timeLockExpiration + (nextPeriod * timeLockDelay);
            }
            _setTimeLockExpiration(nextExpirationTimestamp);
        }
    }

    /**
     * @dev Sets the time-lock delay
     * @param delay New delay to be set
     */
    function _setTimeLockDelay(uint256 delay) internal {
        require(delay >= timeLockExecutionPeriod, 'TASK_DELAY_GT_EXECUTION_PERIOD');
        timeLockDelay = delay;
        emit TimeLockDelaySet(delay);
    }

    /**
     * @dev Sets the time-lock expiration timestamp
     * @param expiration New expiration timestamp to be set
     */
    function _setTimeLockExpiration(uint256 expiration) internal {
        timeLockExpiration = expiration;
        emit TimeLockExpirationSet(expiration);
    }

    /**
     * @dev Sets the time-lock execution period
     * @param period New execution period to be set
     */
    function _setTimeLockExecutionPeriod(uint256 period) internal {
        require(period <= timeLockDelay, 'TASK_EXECUTION_PERIOD_GT_DELAY');
        timeLockExecutionPeriod = period;
        emit TimeLockExecutionPeriodSet(period);
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

pragma solidity ^0.8.3;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';

import '../interfaces/base/ITokenIndexedTask.sol';

/**
 * @dev Token indexed task. It defines a token acceptance list to tell which are the tokens supported by the
 * task. Tokens acceptance can be configured either as an allow list or as a deny list.
 */
abstract contract TokenIndexedTask is ITokenIndexedTask, Authorized {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Acceptance list type
    TokensAcceptanceType public override tokensAcceptanceType;

    // Enumerable set of tokens included in the acceptance list
    EnumerableSet.AddressSet internal _tokens;

    /**
     * @dev Token index config. Only used in the initializer.
     * @param acceptanceType Token acceptance type to be set
     * @param tokens List of token addresses to be set for the acceptance list
     */
    struct TokenIndexConfig {
        TokensAcceptanceType acceptanceType;
        address[] tokens;
    }

    /**
     * @dev Initializes the token indexed task. It does not call upper contracts initializers.
     * @param config Token indexed task config
     */
    function __TokenIndexedTask_init(TokenIndexConfig memory config) internal onlyInitializing {
        __TokenIndexedTask_init_unchained(config);
    }

    /**
     * @dev Initializes the token indexed task. It does call upper contracts initializers.
     * @param config Token indexed task config
     */
    function __TokenIndexedTask_init_unchained(TokenIndexConfig memory config) internal onlyInitializing {
        _setTokensAcceptanceType(config.acceptanceType);

        for (uint256 i = 0; i < config.tokens.length; i++) {
            _setTokenAcceptanceList(config.tokens[i], true);
        }
    }

    /**
     * @dev Sets the tokens acceptance type of the task
     * @param newTokensAcceptanceType New token acceptance type to be set
     */
    function setTokensAcceptanceType(TokensAcceptanceType newTokensAcceptanceType)
        external
        override
        authP(authParams(uint8(newTokensAcceptanceType)))
    {
        _setTokensAcceptanceType(newTokensAcceptanceType);
    }

    /**
     * @dev Updates the list of tokens of the tokens acceptance list
     * @param tokens List of tokens to be updated from the acceptance list
     * @param added Whether each of the given tokens should be added or removed from the list
     */
    function setTokensAcceptanceList(address[] memory tokens, bool[] memory added) external override auth {
        require(tokens.length == added.length, 'TASK_ACCEPTANCE_BAD_LENGTH');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setTokenAcceptanceList(tokens[i], added[i]);
        }
    }

    /**
     * @dev Before token indexed task hook
     */
    function _beforeTokenIndexedTask(address token, uint256) internal virtual {
        bool containsToken = _tokens.contains(token);
        bool isTokenAllowed = tokensAcceptanceType == TokensAcceptanceType.AllowList ? containsToken : !containsToken;
        require(isTokenAllowed, 'TASK_TOKEN_NOT_ALLOWED');
    }

    /**
     * @dev After token indexed task hook
     */
    function _afterTokenIndexedTask(address token, uint256) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets the tokens acceptance type of the task
     * @param newTokensAcceptanceType New token acceptance type to be set
     */
    function _setTokensAcceptanceType(TokensAcceptanceType newTokensAcceptanceType) internal {
        tokensAcceptanceType = newTokensAcceptanceType;
        emit TokensAcceptanceTypeSet(newTokensAcceptanceType);
    }

    /**
     * @dev Updates a token from the tokens acceptance list
     * @param token Token to be updated from the acceptance list
     * @param added Whether the token should be added or removed from the list
     */
    function _setTokenAcceptanceList(address token, bool added) internal {
        require(token != address(0), 'TASK_ACCEPTANCE_TOKEN_ZERO');
        added ? _tokens.add(token) : _tokens.remove(token);
        emit TokensAcceptanceListSet(token, added);
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

pragma solidity ^0.8.3;

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import '../interfaces/base/ITokenThresholdTask.sol';

/**
 * @dev Token threshold task. It mainly works with token threshold configs that can be used to tell if
 * a specific token amount is compliant with certain minimum or maximum values. Token threshold tasks
 * make use of a default threshold config as a fallback in case there is no custom threshold defined for the token
 * being evaluated.
 */
abstract contract TokenThresholdTask is ITokenThresholdTask, Authorized {
    using FixedPoint for uint256;

    // Default threshold
    Threshold internal _defaultThreshold;

    // Custom thresholds per token
    mapping (address => Threshold) internal _customThresholds;

    /**
     * @dev Custom token threshold config. Only used in the initializer.
     */
    struct CustomThresholdConfig {
        address token;
        Threshold threshold;
    }

    /**
     * @dev Token threshold config. Only used in the initializer.
     * @param defaultThreshold Default threshold to be set
     * @param customThresholdConfigs List of custom threshold configs to be set
     */
    struct TokenThresholdConfig {
        Threshold defaultThreshold;
        CustomThresholdConfig[] customThresholdConfigs;
    }

    /**
     * @dev Initializes the token threshold task. It does not call upper contracts initializers.
     * @param config Token threshold task config
     */
    function __TokenThresholdTask_init(TokenThresholdConfig memory config) internal onlyInitializing {
        __TokenThresholdTask_init_unchained(config);
    }

    /**
     * @dev Initializes the token threshold task. It does call upper contracts initializers.
     * @param config Token threshold task config
     */
    function __TokenThresholdTask_init_unchained(TokenThresholdConfig memory config) internal onlyInitializing {
        Threshold memory defaultThreshold = config.defaultThreshold;
        _setDefaultTokenThreshold(defaultThreshold.token, defaultThreshold.min, defaultThreshold.max);

        for (uint256 i = 0; i < config.customThresholdConfigs.length; i++) {
            CustomThresholdConfig memory customThresholdConfig = config.customThresholdConfigs[i];
            Threshold memory custom = customThresholdConfig.threshold;
            _setCustomTokenThreshold(customThresholdConfig.token, custom.token, custom.min, custom.max);
        }
    }

    /**
     * @dev Tells the default token threshold
     */
    function defaultTokenThreshold() external view override returns (Threshold memory) {
        return _defaultThreshold;
    }

    /**
     * @dev Tells the token threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenThreshold(address token) public view override returns (Threshold memory) {
        return _customThresholds[token];
    }

    /**
     * @dev Tells the threshold that should be used for a token, it prioritizes custom thresholds over the default one
     * @param token Address of the token being queried
     */
    function getTokenThreshold(address token) public view virtual override returns (Threshold memory) {
        Threshold storage customThreshold = _customThresholds[token];
        return customThreshold.token == address(0) ? _defaultThreshold : customThreshold;
    }

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param thresholdMin New threshold minimum to be set
     * @param thresholdMax New threshold maximum to be set
     */
    function setDefaultTokenThreshold(address thresholdToken, uint256 thresholdMin, uint256 thresholdMax)
        external
        override
        authP(authParams(thresholdToken, thresholdMin, thresholdMax))
    {
        _setDefaultTokenThreshold(thresholdToken, thresholdMin, thresholdMax);
    }

    /**
     * @dev Sets a custom token threshold
     * @param token Address of the token to set a custom threshold for
     * @param thresholdToken New custom threshold token to be set
     * @param thresholdMin New custom threshold minimum to be set
     * @param thresholdMax New custom threshold maximum to be set
     */
    function setCustomTokenThreshold(address token, address thresholdToken, uint256 thresholdMin, uint256 thresholdMax)
        external
        override
        authP(authParams(token, thresholdToken, thresholdMin, thresholdMax))
    {
        _setCustomTokenThreshold(token, thresholdToken, thresholdMin, thresholdMax);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256);

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256 amount) internal virtual {
        Threshold memory threshold = getTokenThreshold(token);
        if (threshold.token == address(0)) return;

        uint256 convertedAmount = threshold.token == token ? amount : amount.mulDown(_getPrice(token, threshold.token));
        bool isValid = convertedAmount >= threshold.min && (threshold.max == 0 || convertedAmount <= threshold.max);
        require(isValid, 'TASK_TOKEN_THRESHOLD_NOT_MET');
    }

    /**
     * @dev After token threshold task hook
     */
    function _afterTokenThresholdTask(address, uint256) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param thresholdMin New threshold minimum to be set
     * @param thresholdMax New threshold maximum to be set
     */
    function _setDefaultTokenThreshold(address thresholdToken, uint256 thresholdMin, uint256 thresholdMax) internal {
        _setTokenThreshold(_defaultThreshold, thresholdToken, thresholdMin, thresholdMax);
        emit DefaultTokenThresholdSet(thresholdToken, thresholdMin, thresholdMax);
    }

    /**
     * @dev Sets a custom of tokens thresholds
     * @param token Address of the token to set a custom threshold for
     * @param thresholdToken New custom threshold token to be set
     * @param thresholdMin New custom threshold minimum to be set
     * @param thresholdMax New custom threshold maximum to be set
     */
    function _setCustomTokenThreshold(address token, address thresholdToken, uint256 thresholdMin, uint256 thresholdMax)
        internal
    {
        require(token != address(0), 'TASK_THRESHOLD_TOKEN_ZERO');
        _setTokenThreshold(_customThresholds[token], thresholdToken, thresholdMin, thresholdMax);
        emit CustomTokenThresholdSet(token, thresholdToken, thresholdMin, thresholdMax);
    }

    /**
     * @dev Sets a threshold
     * @param threshold Threshold to be updated
     * @param token New threshold token to be set
     * @param min New threshold minimum to be set
     * @param max New threshold maximum to be set
     */
    function _setTokenThreshold(Threshold storage threshold, address token, uint256 min, uint256 max) private {
        // If there is no threshold, all values must be zero
        bool isZeroThreshold = token == address(0) && min == 0 && max == 0;
        bool isNonZeroThreshold = token != address(0) && (max == 0 || max >= min);
        require(isZeroThreshold || isNonZeroThreshold, 'TASK_INVALID_THRESHOLD_INPUT');

        threshold.token = token;
        threshold.min = min;
        threshold.max = max;
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

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import '../interfaces/base/IVolumeLimitedTask.sol';

/**
 * @dev Volume limit config for tasks. It allows setting volume limit per period of time.
 */
abstract contract VolumeLimitedTask is IVolumeLimitedTask, Authorized {
    using FixedPoint for uint256;

    // Default volume limit
    VolumeLimit internal _defaultVolumeLimit;

    // Custom volume limits per token
    mapping (address => VolumeLimit) internal _customVolumeLimits;

    /**
     * @dev Volume limit params. Only used in the initializer.
     */
    struct VolumeLimitParams {
        address token;
        uint256 amount;
        uint256 period;
    }

    /**
     * @dev Custom token volume limit config. Only used in the initializer.
     */
    struct CustomVolumeLimitConfig {
        address token;
        VolumeLimitParams volumeLimit;
    }

    /**
     * @dev Volume limit config. Only used in the initializer.
     */
    struct VolumeLimitConfig {
        VolumeLimitParams defaultVolumeLimit;
        CustomVolumeLimitConfig[] customVolumeLimitConfigs;
    }

    /**
     * @dev Initializes the volume limited task. It does call upper contracts initializers.
     * @param config Volume limited task config
     */
    function __VolumeLimitedTask_init(VolumeLimitConfig memory config) internal onlyInitializing {
        __VolumeLimitedTask_init_unchained(config);
    }

    /**
     * @dev Initializes the volume limited task. It does not call upper contracts initializers.
     * @param config Volume limited task config
     */
    function __VolumeLimitedTask_init_unchained(VolumeLimitConfig memory config) internal onlyInitializing {
        VolumeLimitParams memory defaultLimit = config.defaultVolumeLimit;
        _setDefaultVolumeLimit(defaultLimit.token, defaultLimit.amount, defaultLimit.period);

        for (uint256 i = 0; i < config.customVolumeLimitConfigs.length; i++) {
            CustomVolumeLimitConfig memory customVolumeLimitConfig = config.customVolumeLimitConfigs[i];
            VolumeLimitParams memory custom = customVolumeLimitConfig.volumeLimit;
            _setCustomVolumeLimit(customVolumeLimitConfig.token, custom.token, custom.amount, custom.period);
        }
    }

    /**
     * @dev Tells the default volume limit set
     */
    function defaultVolumeLimit() external view override returns (VolumeLimit memory) {
        return _defaultVolumeLimit;
    }

    /**
     * @dev Tells the custom volume limit set for a specific token
     * @param token Address of the token being queried
     */
    function customVolumeLimit(address token) external view override returns (VolumeLimit memory) {
        return _customVolumeLimits[token];
    }

    /**
     * @dev Tells the volume limit that should be used for a token, it prioritizes custom limits over the default one
     * @param token Address of the token being queried
     */
    function getVolumeLimit(address token) public view virtual override returns (VolumeLimit memory) {
        return _getVolumeLimit(token);
    }

    /**
     * @dev Sets a the default volume limit config
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setDefaultVolumeLimit(address limitToken, uint256 limitAmount, uint256 limitPeriod)
        external
        override
        authP(authParams(limitToken, limitAmount, limitPeriod))
    {
        _setDefaultVolumeLimit(limitToken, limitAmount, limitPeriod);
    }

    /**
     * @dev Sets a custom volume limit
     * @param token Address of the token to set a custom volume limit for
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setCustomVolumeLimit(address token, address limitToken, uint256 limitAmount, uint256 limitPeriod)
        external
        override
        authP(authParams(token, limitToken, limitAmount, limitPeriod))
    {
        _setCustomVolumeLimit(token, limitToken, limitAmount, limitPeriod);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256);

    /**
     * @dev Tells the volume limit that should be used for a token, it prioritizes custom limits over the default one
     * @param token Address of the token being queried
     */
    function _getVolumeLimit(address token) internal view returns (VolumeLimit storage) {
        VolumeLimit storage customLimit = _customVolumeLimits[token];
        return customLimit.token == address(0) ? _defaultVolumeLimit : customLimit;
    }

    /**
     * @dev Before volume limited task hook
     */
    function _beforeVolumeLimitedTask(address token, uint256 amount) internal virtual {
        VolumeLimit memory limit = _getVolumeLimit(token);
        if (limit.token == address(0)) return;

        uint256 amountInLimitToken = limit.token == token ? amount : amount.mulDown(_getPrice(token, limit.token));
        uint256 processedVolume = amountInLimitToken + (block.timestamp < limit.nextResetTime ? limit.accrued : 0);
        require(processedVolume <= limit.amount, 'TASK_VOLUME_LIMIT_EXCEEDED');
    }

    /**
     * @dev After volume limited task hook
     */
    function _afterVolumeLimitedTask(address token, uint256 amount) internal virtual {
        VolumeLimit storage limit = _getVolumeLimit(token);
        if (limit.token == address(0)) return;

        uint256 amountInLimitToken = limit.token == token ? amount : amount.mulDown(_getPrice(token, limit.token));
        if (block.timestamp >= limit.nextResetTime) {
            limit.accrued = 0;
            limit.nextResetTime = block.timestamp + limit.period;
        }
        limit.accrued += amountInLimitToken;
    }

    /**
     * @dev Sets the default volume limit
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function _setDefaultVolumeLimit(address limitToken, uint256 limitAmount, uint256 limitPeriod) internal {
        _setVolumeLimit(_defaultVolumeLimit, limitToken, limitAmount, limitPeriod);
        emit DefaultVolumeLimitSet(limitToken, limitAmount, limitPeriod);
    }

    /**
     * @dev Sets a custom volume limit
     * @param token Address of the token to set a custom volume limit for
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function _setCustomVolumeLimit(address token, address limitToken, uint256 limitAmount, uint256 limitPeriod)
        internal
    {
        require(token != address(0), 'TASK_VOLUME_LIMIT_TOKEN_ZERO');
        _setVolumeLimit(_customVolumeLimits[token], limitToken, limitAmount, limitPeriod);
        emit CustomVolumeLimitSet(token, limitToken, limitAmount, limitPeriod);
    }

    /**
     * @dev Sets a volume limit
     * @param limit Volume limit to be updated
     * @param token Address of the token to measure the volume limit
     * @param amount Amount of tokens to be applied for the volume limit
     * @param period Frequency to Amount of tokens to be applied for the volume limit
     */
    function _setVolumeLimit(VolumeLimit storage limit, address token, uint256 amount, uint256 period) private {
        // If there is no limit, all values must be zero
        bool isZeroLimit = token == address(0) && amount == 0 && period == 0;
        bool isNonZeroLimit = token != address(0) && amount > 0 && period > 0;
        require(isZeroLimit || isNonZeroLimit, 'TASK_INVALID_VOLUME_LIMIT_INPUT');

        // Changing the period only affects the end time of the next period, but not the end date of the current one
        limit.period = period;

        // Changing the amount does not affect the totalizator, it only applies when updating the accrued amount.
        // Note that it can happen that the new amount is lower than the accrued amount if the amount is lowered.
        // However, there shouldn't be any accounting issues with that.
        limit.amount = amount;

        // Therefore, only clean the totalizators if the limit is being removed
        if (isZeroLimit) {
            limit.accrued = 0;
            limit.nextResetTime = 0;
        } else {
            // If limit is not zero, set the next reset time if it wasn't set already
            // Otherwise, if the token is being changed the accrued amount must be updated accordingly
            if (limit.nextResetTime == 0) {
                limit.accrued = 0;
                limit.nextResetTime = block.timestamp + period;
            } else if (limit.token != token) {
                uint256 price = _getPrice(limit.token, token);
                limit.accrued = limit.accrued.mulDown(price);
            }
        }

        // Finally simply set the new requested token
        limit.token = token;
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

import './IBaseTask.sol';

/**
 * @dev Gas limited task interface
 */
interface IGasLimitedTask is IBaseTask {
    /**
     * @dev Emitted every time the gas price limit is set
     */
    event GasPriceLimitSet(uint256 gasPriceLimit);

    /**
     * @dev Emitted every time the priority fee limit is set
     */
    event PriorityFeeLimitSet(uint256 priorityFeeLimit);

    /**
     * @dev Emitted every time the transaction cost limit is set
     */
    event TxCostLimitSet(uint256 txCostLimit);

    /**
     * @dev Emitted every time the transaction cost limit percentage is set
     */
    event TxCostLimitPctSet(uint256 txCostLimitPct);

    /**
     * @dev Tells the gas price limit
     */
    function gasPriceLimit() external view returns (uint256);

    /**
     * @dev Tells the priority fee limit
     */
    function priorityFeeLimit() external view returns (uint256);

    /**
     * @dev Tells the transaction cost limit
     */
    function txCostLimit() external view returns (uint256);

    /**
     * @dev Tells the transaction cost limit percentage
     */
    function txCostLimitPct() external view returns (uint256);

    /**
     * @dev Sets the gas price limit
     * @param newGasPriceLimit New gas price limit to be set
     */
    function setGasPriceLimit(uint256 newGasPriceLimit) external;

    /**
     * @dev Sets the priority fee limit
     * @param newPriorityFeeLimit New priority fee limit to be set
     */
    function setPriorityFeeLimit(uint256 newPriorityFeeLimit) external;

    /**
     * @dev Sets the transaction cost limit
     * @param newTxCostLimit New transaction cost limit to be set
     */
    function setTxCostLimit(uint256 newTxCostLimit) external;

    /**
     * @dev Sets the transaction cost limit percentage
     * @param newTxCostLimitPct New transaction cost limit percentage to be set
     */
    function setTxCostLimitPct(uint256 newTxCostLimitPct) external;
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

import './IBaseTask.sol';

/**
 * @dev Pausable task interface
 */
interface IPausableTask is IBaseTask {
    /**
     * @dev Emitted every time a task is paused
     */
    event Paused();

    /**
     * @dev Emitted every time a task is unpaused
     */
    event Unpaused();

    /**
     * @dev Tells the task is paused or not
     */
    function isPaused() external view returns (bool);

    /**
     * @dev Pauses a task
     */
    function pause() external;

    /**
     * @dev Unpauses a task
     */
    function unpause() external;
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

import './IBaseTask.sol';

/**
 * @dev Time-locked task interface
 */
interface ITimeLockedTask is IBaseTask {
    /**
     * @dev Emitted every time a new time-lock delay is set
     */
    event TimeLockDelaySet(uint256 delay);

    /**
     * @dev Emitted every time a new expiration timestamp is set
     */
    event TimeLockExpirationSet(uint256 expiration);

    /**
     * @dev Emitted every time a new execution period is set
     */
    event TimeLockExecutionPeriodSet(uint256 period);

    /**
     * @dev Tells the time-lock delay in seconds
     */
    function timeLockDelay() external view returns (uint256);

    /**
     * @dev Tells the time-lock expiration timestamp
     */
    function timeLockExpiration() external view returns (uint256);

    /**
     * @dev Tells the time-lock execution period
     */
    function timeLockExecutionPeriod() external view returns (uint256);

    /**
     * @dev Sets the time-lock delay
     * @param delay New delay to be set
     */
    function setTimeLockDelay(uint256 delay) external;

    /**
     * @dev Sets the time-lock expiration timestamp
     * @param expiration New expiration timestamp to be set
     */
    function setTimeLockExpiration(uint256 expiration) external;

    /**
     * @dev Sets the time-lock execution period
     * @param period New execution period to be set
     */
    function setTimeLockExecutionPeriod(uint256 period) external;
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

import './IBaseTask.sol';

/**
 * @dev Token indexed task interface
 */
interface ITokenIndexedTask is IBaseTask {
    /**
     * @dev Acceptance list types: either deny-list to express "all except" or allow-list to express "only"
     */
    enum TokensAcceptanceType {
        DenyList,
        AllowList
    }

    /**
     * @dev Emitted every time a tokens acceptance type is set
     */
    event TokensAcceptanceTypeSet(TokensAcceptanceType acceptanceType);

    /**
     * @dev Emitted every time a token is added or removed from the acceptance list
     */
    event TokensAcceptanceListSet(address indexed token, bool added);

    /**
     * @dev Tells the acceptance type of the config
     */
    function tokensAcceptanceType() external view returns (TokensAcceptanceType);

    /**
     * @dev Sets the tokens acceptance type of the task
     * @param newTokensAcceptanceType New token acceptance type to be set
     */
    function setTokensAcceptanceType(TokensAcceptanceType newTokensAcceptanceType) external;

    /**
     * @dev Updates the list of tokens of the tokens acceptance list
     * @param tokens List of tokens to be updated from the acceptance list
     * @param added Whether each of the given tokens should be added or removed from the list
     */
    function setTokensAcceptanceList(address[] memory tokens, bool[] memory added) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General External License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General External License for more details.

// You should have received a copy of the GNU General External License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './IBaseTask.sol';

/**
 * @dev Token threshold task interface
 */
interface ITokenThresholdTask is IBaseTask {
    /**
     * @dev Threshold defined by a token address and min/max values
     */
    struct Threshold {
        address token;
        uint256 min;
        uint256 max;
    }

    /**
     * @dev Emitted every time a default threshold is set
     */
    event DefaultTokenThresholdSet(address token, uint256 min, uint256 max);

    /**
     * @dev Emitted every time a token threshold is set
     */
    event CustomTokenThresholdSet(address indexed token, address thresholdToken, uint256 min, uint256 max);

    /**
     * @dev Tells the default token threshold
     */
    function defaultTokenThreshold() external view returns (Threshold memory);

    /**
     * @dev Tells the custom threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenThreshold(address token) external view returns (Threshold memory);

    /**
     * @dev Tells the threshold that should be used for a token
     * @param token Address of the token being queried
     */
    function getTokenThreshold(address token) external view returns (Threshold memory);

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param thresholdMin New threshold minimum to be set
     * @param thresholdMax New threshold maximum to be set
     */
    function setDefaultTokenThreshold(address thresholdToken, uint256 thresholdMin, uint256 thresholdMax) external;

    /**
     * @dev Sets a custom token threshold
     * @param token Address of the token to set a custom threshold
     * @param thresholdToken New custom threshold token to be set
     * @param thresholdMin New custom threshold minimum to be set
     * @param thresholdMax New custom threshold maximum to be set
     */
    function setCustomTokenThreshold(address token, address thresholdToken, uint256 thresholdMin, uint256 thresholdMax)
        external;
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

import './IBaseTask.sol';

/**
 * @dev Volume limited task interface
 */
interface IVolumeLimitedTask is IBaseTask {
    /**
     * @dev Volume limit config
     * @param token Address to measure the volume limit
     */
    struct VolumeLimit {
        address token;
        uint256 amount;
        uint256 accrued;
        uint256 period;
        uint256 nextResetTime;
    }

    /**
     * @dev Emitted every time a default volume limit is set
     */
    event DefaultVolumeLimitSet(address indexed token, uint256 amount, uint256 period);

    /**
     * @dev Emitted every time a custom volume limit is set
     */
    event CustomVolumeLimitSet(address indexed token, address indexed limitToken, uint256 amount, uint256 period);

    /**
     * @dev Tells the default volume limit set
     */
    function defaultVolumeLimit() external view returns (VolumeLimit memory);

    /**
     * @dev Tells the custom volume limit set for a specific token
     * @param token Address of the token being queried
     */
    function customVolumeLimit(address token) external view returns (VolumeLimit memory);

    /**
     * @dev Tells the volume limit that should be used for a token
     * @param token Address of the token being queried
     */
    function getVolumeLimit(address token) external view returns (VolumeLimit memory);

    /**
     * @dev Sets a the default volume limit config
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setDefaultVolumeLimit(address limitToken, uint256 limitAmount, uint256 limitPeriod) external;

    /**
     * @dev Sets a custom volume limit
     * @param token Address of the token to set a custom volume limit for
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setCustomVolumeLimit(address token, address limitToken, uint256 limitAmount, uint256 limitPeriod) external;
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

import './base/IBaseTask.sol';
import './base/IGasLimitedTask.sol';
import './base/ITimeLockedTask.sol';
import './base/ITokenIndexedTask.sol';
import './base/ITokenThresholdTask.sol';
import './base/IVolumeLimitedTask.sol';

// solhint-disable no-empty-blocks

/**
 * @dev Task interface
 */
interface ITask is
    IBaseTask,
    IGasLimitedTask,
    ITimeLockedTask,
    ITokenIndexedTask,
    ITokenThresholdTask,
    IVolumeLimitedTask
{

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

import '../ITask.sol';

/**
 * @dev Collector task interface
 */
interface ICollector is ITask {
    /**
     * @dev Emitted every time the tokens source is set
     */
    event TokensSourceSet(address indexed tokensSource);

    /**
     * @dev Sets the tokens source address
     * @param tokensSource Address of the tokens source to be set
     */
    function setTokensSource(address tokensSource) external;

    /**
     * @dev Executes the withdrawer task
     */
    function call(address token, uint256 amount) external;
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

import '@mimic-fi/v3-helpers/contracts/utils/Denominations.sol';

import '../Task.sol';
import '../interfaces/primitives/ICollector.sol';

/**
 * @title Collector
 * @dev Task that offers a source address where funds can be pulled from
 */
contract Collector is ICollector, Task {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('COLLECTOR');

    // Address from where the tokens will be pulled
    address internal _tokensSource;

    /**
     * @dev Collect config. Only used in the initializer.
     */
    struct CollectConfig {
        address tokensSource;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the collector
     * @param config Collect config
     */
    function initialize(CollectConfig memory config) external virtual initializer {
        __Collector_init(config);
    }

    /**
     * @dev Initializes the collector. It does call upper contracts initializers.
     * @param config Collect config
     */
    function __Collector_init(CollectConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __Collector_init_unchained(config);
    }

    /**
     * @dev Initializes the collector. It does not call upper contracts initializers.
     * @param config Collect config
     */
    function __Collector_init_unchained(CollectConfig memory config) internal onlyInitializing {
        _setTokensSource(config.tokensSource);
    }

    /**
     * @dev Tells the address from where the token amounts to execute this task are fetched
     */
    function getTokensSource() external view virtual override(IBaseTask, BaseTask) returns (address) {
        return _tokensSource;
    }

    /**
     * @dev Sets the tokens source address. Sender must be authorized.
     * @param tokensSource Address of the tokens source to be set
     */
    function setTokensSource(address tokensSource) external override authP(authParams(tokensSource)) {
        _setTokensSource(tokensSource);
    }

    /**
     * @dev Execute Collector
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        _beforeCollector(token, amount);
        ISmartVault(smartVault).collect(token, _tokensSource, amount);
        _afterCollector(token, amount);
    }

    /**
     * @dev Before collector hook
     */
    function _beforeCollector(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        require(token != address(0), 'TASK_TOKEN_ZERO');
        require(amount > 0, 'TASK_AMOUNT_ZERO');
    }

    /**
     * @dev After collector hook
     */
    function _afterCollector(address token, uint256 amount) internal virtual {
        _increaseBalanceConnector(token, amount);
        _afterTask(token, amount);
    }

    /**
     * @dev Sets the balance connectors. Previous balance connector must be unset.
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal virtual override {
        require(previous == bytes32(0), 'TASK_PREVIOUS_CONNECTOR_NOT_ZERO');
        super._setBalanceConnectors(previous, next);
    }

    /**
     * @dev Sets the source address
     * @param tokensSource Address of the tokens source to be set
     */
    function _setTokensSource(address tokensSource) internal virtual {
        require(tokensSource != address(0), 'TASK_TOKENS_SOURCE_ZERO');
        _tokensSource = tokensSource;
        emit TokensSourceSet(tokensSource);
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

import './interfaces/ITask.sol';
import './base/BaseTask.sol';
import './base/PausableTask.sol';
import './base/GasLimitedTask.sol';
import './base/TimeLockedTask.sol';
import './base/TokenIndexedTask.sol';
import './base/TokenThresholdTask.sol';
import './base/VolumeLimitedTask.sol';

/**
 * @title Task
 * @dev Shared components across all tasks
 */
abstract contract Task is
    ITask,
    BaseTask,
    PausableTask,
    GasLimitedTask,
    TimeLockedTask,
    TokenIndexedTask,
    TokenThresholdTask,
    VolumeLimitedTask
{
    /**
     * @dev Task config. Only used in the initializer.
     */
    struct TaskConfig {
        BaseConfig baseConfig;
        GasLimitConfig gasLimitConfig;
        TimeLockConfig timeLockConfig;
        TokenIndexConfig tokenIndexConfig;
        TokenThresholdConfig tokenThresholdConfig;
        VolumeLimitConfig volumeLimitConfig;
    }

    /**
     * @dev Initializes the task. It does call upper contracts initializers.
     * @param config Task config
     */
    function __Task_init(TaskConfig memory config) internal onlyInitializing {
        __BaseTask_init(config.baseConfig);
        __PausableTask_init();
        __GasLimitedTask_init(config.gasLimitConfig);
        __TimeLockedTask_init(config.timeLockConfig);
        __TokenIndexedTask_init(config.tokenIndexConfig);
        __TokenThresholdTask_init(config.tokenThresholdConfig);
        __VolumeLimitedTask_init(config.volumeLimitConfig);
        __Task_init_unchained(config);
    }

    /**
     * @dev Initializes the task. It does not call upper contracts initializers.
     * @param config Task config
     */
    function __Task_init_unchained(TaskConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote)
        internal
        view
        override(BaseTask, GasLimitedTask, TokenThresholdTask, VolumeLimitedTask)
        returns (uint256)
    {
        return BaseTask._getPrice(base, quote);
    }

    /**
     * @dev Before task hook
     */
    function _beforeTask(address token, uint256 amount) internal virtual {
        _beforeBaseTask(token, amount);
        _beforePausableTask(token, amount);
        _beforeGasLimitedTask(token, amount);
        _beforeTimeLockedTask(token, amount);
        _beforeTokenIndexedTask(token, amount);
        _beforeTokenThresholdTask(token, amount);
        _beforeVolumeLimitedTask(token, amount);
    }

    /**
     * @dev After task hook
     */
    function _afterTask(address token, uint256 amount) internal virtual {
        _afterVolumeLimitedTask(token, amount);
        _afterTokenThresholdTask(token, amount);
        _afterTokenIndexedTask(token, amount);
        _afterTimeLockedTask(token, amount);
        _afterGasLimitedTask(token, amount);
        _afterPausableTask(token, amount);
        _afterBaseTask(token, amount);
    }
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
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v3-tasks/contracts/primitives/Collector.sol';

import './interfaces/IExchangeAllocator.sol';

/**
 * @title Exchange allocator
 * @dev Task used to pay The Graph's allocation exchange recurring subscriptions
 */
contract ExchangeAllocator is IExchangeAllocator, Collector {
    using FixedPoint for uint256;

    address public override allocationExchange;

    /**
     * @dev Disables the default collector initializer
     */
    function initialize(CollectConfig memory) external pure override {
        revert('COLLECTOR_INITIALIZER_DISABLED');
    }

    /**
     * @dev Initializes the exchange allocator
     * @param config Collect config
     * @param exchange Allocation exchange address
     */
    function initializeExchangeAllocator(CollectConfig memory config, address exchange) external virtual initializer {
        __ExchangeAllocator_init(config, exchange);
    }

    /**
     * @dev Initializes the exchange allocator. It does call upper contracts initializers.
     * @param config Exchange allocator config
     * @param exchange Allocation exchange address
     */
    function __ExchangeAllocator_init(CollectConfig memory config, address exchange) internal onlyInitializing {
        __Collector_init(config);
        __ExchangeAllocator_init_unchained(config, exchange);
    }

    /**
     * @dev Initializes the exchange allocator. It does not call upper contracts initializers.
     * @param exchange Allocation exchange address
     */
    function __ExchangeAllocator_init_unchained(CollectConfig memory, address exchange) internal onlyInitializing {
        _setAllocationExchange(exchange);
    }

    /**
     * @dev Sets the allocation exchange address. Sender must be authorized.
     * @param newAllocationExchange Address of the allocation exchange to be set
     */
    function setAllocationExchange(address newAllocationExchange)
        external
        override
        authP(authParams(newAllocationExchange))
    {
        _setAllocationExchange(newAllocationExchange);
    }

    /**
     * @dev Tells the amount in `token` to be funded
     * @param token Address of the token to be used for funding
     */
    function getTaskAmount(address token) public view virtual override(IBaseTask, BaseTask) returns (uint256) {
        Threshold memory threshold = TokenThresholdTask.getTokenThreshold(token);
        uint256 currentBalance = IERC20(threshold.token).balanceOf(allocationExchange);
        if (currentBalance >= threshold.min) return 0;

        uint256 diff = threshold.max - currentBalance;
        return (token == threshold.token) ? diff : diff.mulUp(_getPrice(threshold.token, token));
    }

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256) internal virtual override {
        Threshold memory threshold = TokenThresholdTask.getTokenThreshold(token);
        uint256 currentBalance = IERC20(threshold.token).balanceOf(allocationExchange);
        require(currentBalance < threshold.min, 'TASK_TOKEN_THRESHOLD_NOT_MET');
    }

    /**
     * @dev Sets the allocation exchange address
     * @param newAllocationExchange Address of the allocation exchange to be set
     */
    function _setAllocationExchange(address newAllocationExchange) internal {
        allocationExchange = newAllocationExchange;
        emit AllocationExchangeSet(newAllocationExchange);
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

import '@mimic-fi/v3-tasks/contracts/interfaces/primitives/ICollector.sol';

/**
 * @title Exchange allocator interface
 */
interface IExchangeAllocator is ICollector {
    /**
     * @dev Emitted every time the allocation exchange address is set
     */
    event AllocationExchangeSet(address indexed allocationExchange);

    /**
     * @dev Tells the allocation exchange address
     */
    function allocationExchange() external view returns (address);

    /**
     * @dev Sets the allocation exchange address
     * @param newAllocationExchange Address of the allocation exchange to be set
     */
    function setAllocationExchange(address newAllocationExchange) external;
}