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
        if (!_isAuthorized(who, what, how)) revert AuthSenderNotAllowed(who, what, how);
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

    function authParams(uint256 p1, uint256 p2, uint256 p3, uint256 p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = p1;
        r[1] = p2;
        r[2] = p3;
        r[3] = p4;
    }

    function authParams(address p1, address p2, uint256 p3, uint256 p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(uint160(p2));
        r[2] = p3;
        r[3] = p4;
    }

    function authParams(address p1, uint256 p2, address p3, uint256 p4) internal pure returns (uint256[] memory r) {
        r = new uint256[](4);
        r[0] = uint256(uint160(p1));
        r[1] = p2;
        r[2] = uint256(uint160(p3));
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

    function authParams(address p1, bytes32 p2) internal pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r[0] = uint256(uint160(p1));
        r[1] = uint256(p2);
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
     * @dev Sender `who` is not allowed to call `what` with `how`
     */
    error AuthSenderNotAllowed(address who, bytes4 what, uint256[] how);

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
     * @dev Sender is not authorized to call `what` on `where` with `how`
     */
    error AuthorizerSenderNotAllowed(address who, address where, bytes4 what, uint256[] how);

    /**
     * @dev The operation param is invalid
     */
    error AuthorizerInvalidParamOp(uint8 op);

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
     * @dev Tells whether `who` has permission to call `what` on `where`. Note `how` is not evaluated here,
     * which means `who` might be authorized on or not depending on the call at the moment of the execution
     * @param who Address asking permission for
     * @param where Target address asking permission for
     * @param what Function selector asking permission for
     */
    function hasPermission(address who, address where, bytes4 what) external view returns (bool);

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
 * @title 1inch V5 connector interface
 */
interface IOneInchV5Connector {
    /**
     * @dev The token in is the same as the token out
     */
    error OneInchV5SwapSameToken(address token);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error OneInchV5BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error OneInchV5BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to 1inch aggregation router v5
     */
    function oneInchV5Router() external view returns (address);

    /**
     * @dev Executes a token swap in 1Inch V5
     * @param tokenIn Token to be sent
     * @param tokenOut Token to be received
     * @param amountIn Amount of token in to be swapped
     * @param minAmountOut Minimum amount of token out willing to receive
     * @param data Calldata to be sent to the 1inch aggregation router
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut);
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
 * @title Axelar connector interface
 */
interface IAxelarConnector {
    /**
     * @dev The recipient address is zero
     */
    error AxelarBridgeRecipientZero();

    /**
     * @dev The source and destination chains are the same
     */
    error AxelarBridgeSameChain(uint256 chainId);

    /**
     * @dev The chain ID is not supported
     */
    error AxelarBridgeUnknownChainId(uint256 chainId);

    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error AxelarBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the Axelar gateway of the source chain
     */
    function axelarGateway() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Axelar
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param recipient Address that will receive the tokens on the destination chain
     */
    function execute(uint256 chainId, address token, uint256 amount, address recipient) external;
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
 * @title Balancer pool connector interface
 */
interface IBalancerV2PoolConnector {
    /**
     * @dev The given input length is invalid or do not match
     */
    error BalancerV2InvalidInputLength();

    /**
     * @dev The given tokens out length is not the expected one
     */
    error BalancerV2InvalidTokensOutLength();

    /**
     * @dev The given pool ID and bpt in do not match on Balancer vault
     */
    error BalancerV2InvalidPoolId(bytes32 poolId, address bpt);

    /**
     * @dev The given token does not belong to the pool
     */
    error BalancerV2InvalidToken(bytes32 poolId, address token);

    /**
     * @dev The post balance of the token in unexpected
     */
    error BalancerV2BadTokenInBalance(uint256 postBalance, uint256 preBalance, uint256 amountIn);

    /**
     * @dev The post balance of the token out is unexpected
     */
    error BalancerV2BadTokenOutBalance(uint256 postBalance, uint256 preBalance);

    /**
     * @dev The resulting amount out is lower than the expected min amount out
     */
    error BalancerV2BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev Tells the reference to Balancer v2 vault
     */
    function balancerV2Vault() external view returns (address);

    /**
     * @dev Adds liquidity to a Balancer pool
     * @param poolId Balancer pool ID
     * @param tokenIn Address of the token to join the Balancer pool
     * @param amountIn Amount of tokens to join the Balancer pool
     * @param minAmountOut Minimum amount of pool tokens expected to receive after join
     */
    function join(bytes32 poolId, address tokenIn, uint256 amountIn, uint256 minAmountOut)
        external
        returns (uint256 amountOut);

    /**
     * @dev Removes liquidity from a Balancer pool
     * @param tokenIn Address of the pool to exit
     * @param amountIn Amount of pool tokens to exit
     * @param tokensOut List of addresses of tokens in the pool
     * @param minAmountsOut List of min amounts out to be expected for each pool token
     */
    function exit(address tokenIn, uint256 amountIn, address[] memory tokensOut, uint256[] memory minAmountsOut)
        external
        returns (uint256[] memory amountsOut);
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
 * @title Balancer v2 swap connector interface
 */
interface IBalancerV2SwapConnector {
    /**
     * @dev The input length mismatch
     */
    error BalancerV2InputLengthMismatch();

    /**
     * @dev The token in is the same as the token out
     */
    error BalancerV2SwapSameToken(address token);

    /**
     * @dev The pool does not exist on the Balancer vault
     */
    error BalancerV2InvalidPool(bytes32 poolId);

    /**
     * @dev The requested tokens do not belong to the pool
     */
    error BalancerV2InvalidPoolTokens(bytes32 poolId, address tokenA, address tokenB);

    /**
     * @dev The returned amount in is not equal to the requested amount in
     */
    error BalancerV2InvalidAmountIn(int256 amountIn);

    /**
     * @dev The returned amount out is greater than or equal to zero
     */
    error BalancerV2InvalidAmountOut(int256 amountOut);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error BalancerV2BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error BalancerV2BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to Balancer v2 vault
     */
    function balancerV2Vault() external view returns (address);

    /**
     * @dev Executes a token swap in Balancer V2
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param poolId Pool ID to be used
     * @param hopPoolsIds Optional list of hop-pools between tokenIn and tokenOut, only used for multi-hops
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes32 poolId,
        bytes32[] memory hopPoolsIds,
        address[] memory hopTokens
    ) external returns (uint256 amountOut);
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

interface IBalancerV2Vault {
    function getPool(bytes32 poolId) external view returns (address, uint256);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    struct JoinPoolRequest {
        IERC20[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;

    struct ExitPoolRequest {
        IERC20[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        payable
        returns (uint256);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
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
 * @title Bebop connector interface
 */
interface IBebopConnector {
    /**
     * @dev The token in is the same as the token out
     */
    error BebopSwapSameToken(address token);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error BebopBadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error BebopBadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to Bebop Settlement contract
     */
    function bebopSettlement() external view returns (address);

    /**
     * @dev Executes a token swap using Bebop
     * @param tokenIn Token to be sent
     * @param tokenOut Token to be received
     * @param amountIn Amount of token in to be swapped
     * @param minAmountOut Minimum amount of token out willing to receive
     * @param data Calldata to be sent to the Bebop Settlement contract
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut);
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
 * @title Connext connector interface
 * @dev Interfaces with Connext to bridge tokens
 */
interface IConnextConnector {
    /**
     * @dev The recipient address is zero
     */
    error ConnextBridgeRecipientZero();

    /**
     * @dev The source and destination chains are the same
     */
    error ConnextBridgeSameChain(uint256 chainId);

    /**
     * @dev The chain ID is not supported
     */
    error ConnextBridgeUnknownChainId(uint256 chainId);

    /**
     * @dev The relayer fee is greater than the amount to be bridged
     */
    error ConnextBridgeRelayerFeeGtAmount(uint256 relayerFee, uint256 amount);

    /**
     * @dev The minimum amount out is greater than the amount to be bridged minus the relayer fee
     */
    error ConnextBridgeMinAmountOutTooBig(uint256 minAmountOut, uint256 amount, uint256 relayerFee);

    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error ConnextBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the Connext contract of the source chain
     */
    function connext() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Connext
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Min amount of tokens to receive on the destination chain after relayer fees and slippage
     * @param recipient Address that will receive the tokens on the destination chain
     * @param relayerFee Fee to be paid to the relayer
     */
    function execute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        uint256 relayerFee
    ) external;
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
 * @title Convex connector interface
 */
interface IConvexConnector {
    /**
     * @dev Missing Convex pool for the requested Curve pool
     */
    error ConvexCvxPoolNotFound(address curvePool);

    /**
     * @dev Failed to deposit tokens into the Convex booster
     */
    error ConvexBoosterDepositFailed(uint256 poolId, uint256 amount);

    /**
     * @dev Failed to withdraw tokens from Convex pool
     */
    error ConvexCvxPoolWithdrawFailed(address cvxPool, uint256 amount);

    /**
     * @dev Tells the reference to the Convex booster
     */
    function booster() external view returns (address);

    /**
     * @dev Finds the Curve pool address associated to a Convex pool
     */
    function getCurvePool(address cvxPool) external view returns (address);

    /**
     * @dev Finds the Curve pool address associated to a Convex pool
     */
    function getCvxPool(address curvePool) external view returns (address);

    /**
     * @dev Claims Convex pool rewards for a Curve pool
     */
    function claim(address cvxPool) external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     * @dev Deposits Curve pool tokens into Convex
     * @param curvePool Address of the Curve pool to join Convex
     * @param amount Amount of Curve pool tokens to be deposited into Convex
     */
    function join(address curvePool, uint256 amount) external returns (uint256);

    /**
     * @dev Withdraws Curve pool tokens from Convex
     * @param cvxPool Address of the Convex pool to exit from Convex
     * @param amount Amount of Convex tokens to be withdrawn
     */
    function exit(address cvxPool, uint256 amount) external returns (uint256);
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
 * @title Curve 2CRV connector interface
 */
interface ICurve2CrvConnector {
    /**
     * @dev Failed to find the token in the 2CRV pool
     */
    error Curve2CrvTokenNotFound(address pool, address token);

    /**
     * @dev Token decimals exceed 18
     */
    error Curve2CrvTokenDecimalsAbove18(address token, uint256 decimals);

    /**
     * @dev The slippage is above one
     */
    error Curve2CrvSlippageAboveOne(uint256 slippage);

    /**
     * @dev Adds liquidity to the 2CRV pool
     * @param pool Address of the 2CRV pool to join
     * @param tokenIn Address of the token to join the 2CRV pool
     * @param amountIn Amount of tokens to join the 2CRV pool
     * @param slippage Slippage value to be used to compute the desired min amount out of pool tokens
     */
    function join(address pool, address tokenIn, uint256 amountIn, uint256 slippage) external returns (uint256);

    /**
     * @dev Removes liquidity from 2CRV pool
     * @param pool Address of the 2CRV pool to exit
     * @param amountIn Amount of pool tokens to exit from the 2CRV pool
     * @param tokenOut Address of the token to exit the pool
     * @param slippage Slippage value to be used to compute the desired min amount out of tokens
     */
    function exit(address pool, uint256 amountIn, address tokenOut, uint256 slippage)
        external
        returns (uint256 amountOut);
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
 * @title ERC4626 connector interface
 */
interface IERC4626Connector {
    /**
     * @dev The token is not the underlying token of the ERC4626
     */
    error ERC4626InvalidToken(address token, address underlying);

    /**
     * @dev The amount deposited is lower than the expected amount
     */
    error ERC4626BadSharesOut(uint256 shares, uint256 minSharesOut);

    /**
     * @dev The amount redeemed is lower than the expected amount
     */
    error ERC4626BadAssetsOut(uint256 assets, uint256 minAssetsOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error ERC4626BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the underlying token of an ERC4626
     */
    function getToken(address erc4626) external view returns (address);

    /**
     * @dev Deposits assets to the underlying ERC4626
     * @param erc4626 Address of the ERC4626 to join
     * @param tokenIn Address of the token to join the ERC4626
     * @param assets Amount of assets to be deposited
     * @param minSharesOut Minimum amount of shares willing to receive
     */
    function join(address erc4626, address tokenIn, uint256 assets, uint256 minSharesOut)
        external
        returns (address tokenOut, uint256 shares);

    /**
     * @dev Withdraws assets from the underlying ERC4626
     * @param erc4626 Address of the ERC4626 to exit
     * @param shares Amount of shares to be redeemed
     * @param minAssetsOut Minimum amount of assets willing to receive
     */
    function exit(address erc4626, uint256 shares, uint256 minAssetsOut)
        external
        returns (address token, uint256 assets);
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
 * @title Hop connector interface
 */
interface IHopBridgeConnector {
    /**
     * @dev The source and destination chains are the same
     */
    error HopBridgeSameChain(uint256 chainId);

    /**
     * @dev The bridge operation is not supported
     */
    error HopBridgeOpNotSupported();

    /**
     * @dev The recipient address is zero
     */
    error HopBridgeRecipientZero();

    /**
     * @dev The relayer was sent when not needed
     */
    error HopBridgeRelayerNotNeeded();

    /**
     * @dev The deadline was sent when not needed
     */
    error HopBridgeDeadlineNotNeeded();

    /**
     * @dev The deadline is in the past
     */
    error HopBridgePastDeadline(uint256 deadline, uint256 currentTimestamp);

    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error HopBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the wrapped native token address
     */
    function wrappedNativeToken() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Hop Exchange
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param bridge Address of the bridge component (i.e. hopBridge or hopAMM)
     * @param deadline Deadline to be used when bridging to L2 in order to swap the corresponding hToken
     * @param relayer Only used when transferring from L1 to L2 if a 3rd party is relaying the transfer on the user's behalf
     * @param fee Fee to be sent to the bridge based on the source and destination chain (i.e. relayerFee or bonderFee)
     */
    function execute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        address bridge,
        uint256 deadline,
        address relayer,
        uint256 fee
    ) external;
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

interface IHopL2Amm {
    function hToken() external view returns (address);

    function exchangeAddress() external view returns (address);

    /**
     * @notice To send funds L2->L1 or L2->L2, call the swapAndSend method on the L2 AMM Wrapper contract
     * @dev Do not set destinationAmountOutMin and destinationDeadline when sending to L1 because there is no AMM on L1,
     * otherwise the calculated transferId will be invalid and the transfer will be unbondable. These parameters should
     * be set to 0 when sending to L1.
     * @param amount is the amount the user wants to send plus the Bonder fee
     */
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;
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
 * @title Hop swap connector interface
 */
interface IHopSwapConnector {
    /**
     * @dev The dex address is zero
     */
    error HopDexAddressZero();

    /**
     * @dev The token in is the same as the token out
     */
    error HopSwapSameToken(address token);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error HopBadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the pre token in balance minus the amount in
     */
    error HopBadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Executes a token swap in Hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param hopDexAddress Address of the Hop dex to be used
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address hopDexAddress)
        external
        returns (uint256 amountOut);
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
 * @title Paraswap V5 connector interface
 */
interface IParaswapV5Connector {
    /**
     * @dev The token in is the same as the token out
     */
    error ParaswapV5SwapSameToken(address token);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error ParaswapV5BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error ParaswapV5BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to Paraswap V5 Augustus swapper
     */
    function paraswapV5Augustus() external view returns (address);

    /**
     * @dev Executes a token swap in Paraswap V5
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param data Calldata to be sent to the Augusuts swapper
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut);
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
 * @title Symbiosis connector interface
 */
interface ISymbiosisConnector {
    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error SymbiosisBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the Symbiosis MetaRouter contract of the source chain
     */
    function symbiosisMetaRouter() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Symbiosis
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param data Calldata to be sent to the symbiosis router
     */
    function execute(address token, uint256 amount, bytes memory data) external;
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
 * @title Uniswap V2 connector interface
 */
interface IUniswapV2Connector {
    /**
     * @dev The token in is the same as the token out
     */
    error UniswapV2SwapSameToken(address token);

    /**
     * @dev The pool does not exist
     */
    error UniswapV2InvalidPool(address tokenA, address tokenB);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error UniswapV2BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error UniswapV2BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to UniswapV2 router
     */
    function uniswapV2Router() external view returns (address);

    /**
     * @dev Executes a token swap in Uniswap V2
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory hopTokens
    ) external returns (uint256 amountOut);
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
 * @title Uniswap V3 connector interface
 */
interface IUniswapV3Connector {
    /**
     * @dev The input length mismatch
     */
    error UniswapV3InputLengthMismatch();

    /**
     * @dev The token in is the same as the token out
     */
    error UniswapV3SwapSameToken(address token);

    /**
     * @dev A pool with the given tokens and fee does not exist
     */
    error UniswapV3InvalidPoolFee(address token0, address token1, uint24 fee);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error UniswapV3BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error UniswapV3BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to UniswapV3 router
     */
    function uniswapV3Router() external view returns (address);

    /**
     * @dev Executes a token swap in Uniswap V3
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param fee Fee to be used
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     * @param hopFees Optional list of hop-fees between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) external returns (uint256 amountOut);
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
 * @title Wormhole connector interface
 */
interface IWormholeConnector {
    /**
     * @dev The recipient address is zero
     */
    error WormholeBridgeRecipientZero();

    /**
     * @dev The source and destination chains are the same
     */
    error WormholeBridgeSameChain(uint256 chainId);

    /**
     * @dev The chain ID is not supported
     */
    error WormholeBridgeUnknownChainId(uint256 chainId);

    /**
     * @dev The relayer fee is greater than the amount to be bridged
     */
    error WormholeBridgeRelayerFeeGtAmount(uint256 relayerFee, uint256 amount);

    /**
     * @dev The minimum amount out is greater than the amount to be bridged minus the relayer fee
     */
    error WormholeBridgeMinAmountOutTooBig(uint256 minAmountOut, uint256 amount, uint256 relayerFee);

    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error WormholeBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the Wormhole's CircleRelayer contract of the source chain
     */
    function wormholeCircleRelayer() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Wormhole's CircleRelayer integration
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain after relayer fees
     * @param recipient Address that will receive the tokens on the destination chain
     */
    function execute(uint256 chainId, address token, uint256 amount, uint256 minAmountOut, address recipient) external;
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
     * @dev Multiplication overflow
     */
    error FixedPointMulOverflow(uint256 a, uint256 b);

    /**
     * @dev Division by zero
     */
    error FixedPointZeroDivision();

    /**
     * @dev Division internal error
     */
    error FixedPointDivInternal(uint256 a, uint256 aInflated);

    /**
     * @dev Multiplies two fixed point numbers rounding down
     */
    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            if (a != 0 && product / a != b) revert FixedPointMulOverflow(a, b);
            return product / ONE;
        }
    }

    /**
     * @dev Multiplies two fixed point numbers rounding up
     */
    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            if (a != 0 && product / a != b) revert FixedPointMulOverflow(a, b);
            return product == 0 ? 0 : (((product - 1) / ONE) + 1);
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding down
     */
    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) revert FixedPointZeroDivision();
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            if (aInflated / a != ONE) revert FixedPointDivInternal(a, aInflated);
            return aInflated / b;
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding up
     */
    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) revert FixedPointZeroDivision();
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            if (aInflated / a != ONE) revert FixedPointDivInternal(a, aInflated);
            return ((aInflated - 1) / b) + 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract TokenMock is ERC20 {
    uint8 internal _decimals;

    constructor(string memory symbol, uint8 dec) ERC20(symbol, symbol) {
        _decimals = dec;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
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
     * @dev The length is shorter than start plus 32
     */
    error BytesOutOfBounds(uint256 start, uint256 length);

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
        if (self.length < start + 32) revert BytesOutOfBounds(start, self.length);
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
        SafeERC20.forceApprove(IERC20(token), to, amount);
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
     * @dev The signer is not allowed
     */
    error PriceOracleInvalidSigner(address signer);

    /**
     * @dev The feed for the given (base, quote) pair doesn't exist
     */
    error PriceOracleMissingFeed(address base, address quote);

    /**
     * @dev The price deadline is in the past
     */
    error PriceOracleOutdatedPrice(address base, address quote, uint256 deadline, uint256 currentTimestamp);

    /**
     * @dev The base decimals are bigger than the quote decimals plus the fixed point decimals
     */
    error PriceOracleBaseDecimalsTooBig(address base, uint256 baseDecimals, address quote, uint256 quoteDecimals);

    /**
     * @dev The inverse feed decimals are bigger than the maximum inverse feed decimals
     */
    error PriceOracleInverseFeedDecimalsTooBig(address inverseFeed, uint256 inverseFeedDecimals);

    /**
     * @dev The quote feed decimals are bigger than the base feed decimals plus the fixed point decimals
     */
    error PriceOracleQuoteFeedDecimalsTooBig(uint256 quoteFeedDecimals, uint256 baseFeedDecimals);

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

/**
 * @dev Relayer interface
 */
interface IRelayer {
    /**
     * @dev The token is zero
     */
    error RelayerTokenZero();

    /**
     * @dev The amount is zero
     */
    error RelayerAmountZero();

    /**
     * @dev The collector is zero
     */
    error RelayerCollectorZero();

    /**
     * @dev The recipient is zero
     */
    error RelayerRecipientZero();

    /**
     * @dev The executor is zero
     */
    error RelayerExecutorZero();

    /**
     * @dev Relayer no task given to execute
     */
    error RelayerNoTaskGiven();

    /**
     * @dev Relayer input length mismatch
     */
    error RelayerInputLengthMismatch();

    /**
     * @dev The sender is not allowed
     */
    error RelayerExecutorNotAllowed(address sender);

    /**
     * @dev Trying to execute tasks from different smart vaults
     */
    error RelayerMultipleTaskSmartVaults(address task, address taskSmartVault, address expectedSmartVault);

    /**
     * @dev The task to execute does not have permissions on the associated smart vault
     */
    error RelayerTaskDoesNotHavePermissions(address task, address smartVault);

    /**
     * @dev The smart vault balance plus the available quota are lower than the amount to pay the relayer
     */
    error RelayerPaymentInsufficientBalance(address smartVault, uint256 balance, uint256 quota, uint256 amount);

    /**
     * @dev It failed to send amount minus quota to the smart vault's collector
     */
    error RelayerPaymentFailed(address smartVault, uint256 amount, uint256 quota);

    /**
     * @dev The smart vault balance is lower than the amount to withdraw
     */
    error RelayerWithdrawInsufficientBalance(address sender, uint256 balance, uint256 amount);

    /**
     * @dev It failed to send the amount to the sender
     */
    error RelayerWithdrawFailed(address sender, uint256 amount);

    /**
     * @dev The value sent and the amount differ
     */
    error RelayerValueDoesNotMatchAmount(uint256 value, uint256 amount);

    /**
     * @dev The simulation executed properly
     */
    error RelayerSimulationResult(TaskResult[] taskResults);

    /**
     * @dev Emitted every time an executor is configured
     */
    event ExecutorSet(address indexed executor, bool allowed);

    /**
     * @dev Emitted every time the default collector is set
     */
    event DefaultCollectorSet(address indexed collector);

    /**
     * @dev Emitted every time a collector is set for a smart vault
     */
    event SmartVaultCollectorSet(address indexed smartVault, address indexed collector);

    /**
     * @dev Emitted every time a smart vault's maximum quota is set
     */
    event SmartVaultMaxQuotaSet(address indexed smartVault, uint256 maxQuota);

    /**
     * @dev Emitted every time a smart vault's task is executed
     */
    event TaskExecuted(
        address indexed smartVault,
        address indexed task,
        bytes data,
        bool success,
        bytes result,
        uint256 gas,
        uint256 index
    );

    /**
     * @dev Emitted every time some native tokens are deposited for the smart vault's balance
     */
    event Deposited(address indexed smartVault, uint256 amount);

    /**
     * @dev Emitted every time some native tokens are withdrawn from the smart vault's balance
     */
    event Withdrawn(address indexed smartVault, uint256 amount);

    /**
     * @dev Emitted every time some ERC20 tokens are withdrawn from the relayer to an external account
     */
    event FundsRescued(address indexed token, address indexed recipient, uint256 amount);

    /**
     * @dev Emitted every time a smart vault's quota is paid
     */
    event QuotaPaid(address indexed smartVault, uint256 amount);

    /**
     * @dev Emitted every time a smart vault pays for transaction gas to the relayer
     */
    event GasPaid(address indexed smartVault, uint256 amount, uint256 quota);

    /**
     * @dev Task result
     * @param success Whether the task execution succeeds or not
     * @param result Result of the task execution
     */
    struct TaskResult {
        bool success;
        bytes result;
    }

    /**
     * @dev Tells the default collector address
     */
    function defaultCollector() external view returns (address);

    /**
     * @dev Tells whether an executor is allowed
     * @param executor Address of the executor being queried
     */
    function isExecutorAllowed(address executor) external view returns (bool);

    /**
     * @dev Tells the smart vault available balance to relay transactions
     * @param smartVault Address of the smart vault being queried
     */
    function getSmartVaultBalance(address smartVault) external view returns (uint256);

    /**
     * @dev Tells the custom collector address set for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function getSmartVaultCollector(address smartVault) external view returns (address);

    /**
     * @dev Tells the smart vault maximum quota to be used
     * @param smartVault Address of the smart vault being queried
     */
    function getSmartVaultMaxQuota(address smartVault) external view returns (uint256);

    /**
     * @dev Tells the smart vault used quota
     * @param smartVault Address of the smart vault being queried
     */
    function getSmartVaultUsedQuota(address smartVault) external view returns (uint256);

    /**
     * @dev Tells the collector address applicable for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function getApplicableCollector(address smartVault) external view returns (address);

    /**
     * @dev Configures an external executor
     * @param executor Address of the executor to be set
     * @param allowed Whether the given executor should be allowed or not
     */
    function setExecutor(address executor, bool allowed) external;

    /**
     * @dev Sets the default collector
     * @param collector Address of the new default collector to be set
     */
    function setDefaultCollector(address collector) external;

    /**
     * @dev Sets a custom collector for a smart vault
     * @param smartVault Address of smart vault to set a collector for
     * @param collector Address of the collector to be set for the given smart vault
     */
    function setSmartVaultCollector(address smartVault, address collector) external;

    /**
     * @dev Sets a maximum quota for a smart vault
     * @param smartVault Address of smart vault to set a maximum quota for
     * @param maxQuota Maximum quota to be set for the given smart vault
     */
    function setSmartVaultMaxQuota(address smartVault, uint256 maxQuota) external;

    /**
     * @dev Deposits native tokens for a given smart vault
     * @param smartVault Address of smart vault to deposit balance for
     * @param amount Amount of native tokens to be deposited, must match msg.value
     */
    function deposit(address smartVault, uint256 amount) external payable;

    /**
     * @dev Withdraws native tokens from a given smart vault
     * @param amount Amount of native tokens to be withdrawn
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev Executes a list of tasks
     * @param tasks Addresses of the tasks to execute
     * @param data List of calldata to execute each of the given tasks
     * @param continueIfFailed Whether the execution should fail in case one of the tasks fail
     */
    function execute(address[] memory tasks, bytes[] memory data, bool continueIfFailed) external;

    /**
     * @dev Simulates an execution.
     * WARNING: THIS METHOD IS MEANT TO BE USED AS A VIEW FUNCTION
     * This method will always revert. Successful results or task execution errors are returned as
     * `RelayerSimulationResult` errors. Any other error should be treated as failure.
     * @param tasks Addresses of the tasks to simulate the execution of
     * @param data List of calldata to simulate each of the given tasks execution
     * @param continueIfFailed Whether the simulation should fail in case one of the tasks execution fails
     */
    function simulate(address[] memory tasks, bytes[] memory data, bool continueIfFailed) external;

    /**
     * @dev Withdraw ERC20 tokens to an external account. To be used in case of accidental token transfers.
     * @param token Address of the token to be withdrawn
     * @param recipient Address where the tokens will be transferred to
     * @param amount Amount of tokens to withdraw
     */
    function rescueFunds(address token, address recipient, uint256 amount) external;
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
     * @dev The smart vault is paused
     */
    error SmartVaultPaused();

    /**
     * @dev The smart vault is unpaused
     */
    error SmartVaultUnpaused();

    /**
     * @dev The token is zero
     */
    error SmartVaultTokenZero();

    /**
     * @dev The amount is zero
     */
    error SmartVaultAmountZero();

    /**
     * @dev The recipient is zero
     */
    error SmartVaultRecipientZero();

    /**
     * @dev The connector is deprecated
     */
    error SmartVaultConnectorDeprecated(address connector);

    /**
     * @dev The connector is not registered
     */
    error SmartVaultConnectorNotRegistered(address connector);

    /**
     * @dev The connector is not stateless
     */
    error SmartVaultConnectorNotStateless(address connector);

    /**
     * @dev The connector ID is zero
     */
    error SmartVaultBalanceConnectorIdZero();

    /**
     * @dev The balance connector's balance is lower than the requested amount to be deducted
     */
    error SmartVaultBalanceConnectorInsufficientBalance(bytes32 id, address token, uint256 balance, uint256 amount);

    /**
     * @dev The smart vault's native token balance is lower than the requested amount to be deducted
     */
    error SmartVaultInsufficientNativeTokenBalance(uint256 balance, uint256 amount);

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
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
    bytes32 internal previousBalanceConnectorId;

    // Optional balance connector id for the next task in the workflow
    bytes32 internal nextBalanceConnectorId;

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
    function getTaskAmount(address token) public view virtual override returns (uint256) {
        return ISmartVault(smartVault).getBalanceConnector(previousBalanceConnectorId, token);
    }

    /**
     * @dev Tells the previous and next balance connectors id of the previous task in the workflow
     */
    function getBalanceConnectors() external view returns (bytes32 previous, bytes32 next) {
        previous = previousBalanceConnectorId;
        next = nextBalanceConnectorId;
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
     * @dev Tells the wrapped native token address if the given address is the native token
     * @param token Address of the token to be checked
     */
    function _wrappedIfNative(address token) internal view returns (address) {
        return Denominations.isNativeToken(token) ? _wrappedNativeToken() : token;
    }

    /**
     * @dev Tells whether a token is the native or the wrapped native token
     * @param token Address of the token to be checked
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

    /**
     * @dev Fetches a base/quote price from the smart vault's price oracle
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256) {
        address priceOracle = ISmartVault(smartVault).priceOracle();
        if (priceOracle == address(0)) revert TaskSmartVaultPriceOracleNotSet(smartVault);
        bytes memory extraCallData = _decodeExtraCallData();
        return
            extraCallData.length == 0
                ? IPriceOracle(priceOracle).getPrice(_wrappedIfNative(base), _wrappedIfNative(quote))
                : IPriceOracle(priceOracle).getPrice(_wrappedIfNative(base), _wrappedIfNative(quote), extraCallData);
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
        if (previous == next && previous != bytes32(0)) revert TaskSameBalanceConnectors(previous);
        previousBalanceConnectorId = previous;
        nextBalanceConnectorId = next;
        emit BalanceConnectorsSet(previous, next);
    }

    /**
     * @dev Decodes any potential extra calldata stored in the calldata space. Tasks relying on the extra calldata
     * pattern, assume that the last word of the calldata stores the extra calldata length so it can be decoded. Note
     * that tasks relying on this pattern must contemplate this function may return bogus data if no extra calldata
     * was given.
     */
    function _decodeExtraCallData() private pure returns (bytes memory data) {
        uint256 length = uint256(_decodeLastCallDataWord());
        if (msg.data.length < length) return new bytes(0);
        data = new bytes(length);
        assembly {
            calldatacopy(add(data, 0x20), sub(sub(calldatasize(), length), 0x20), length)
        }
    }

    /**
     * @dev Returns the last calldata word. This function returns zero if the calldata is not long enough.
     */
    function _decodeLastCallDataWord() private pure returns (bytes32 result) {
        if (msg.data.length < 36) return bytes32(0);
        assembly {
            result := calldataload(sub(calldatasize(), 0x20))
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

    // Gas limits config
    GasLimitConfig internal gasLimits;

    /**
     * @dev Gas limits config
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
        _setGasLimits(config.gasPriceLimit, config.priorityFeeLimit, config.txCostLimit, config.txCostLimitPct);
    }

    /**
     * @dev Tells the gas limits config
     */
    function getGasLimits()
        external
        view
        returns (uint256 gasPriceLimit, uint256 priorityFeeLimit, uint256 txCostLimit, uint256 txCostLimitPct)
    {
        return (gasLimits.gasPriceLimit, gasLimits.priorityFeeLimit, gasLimits.txCostLimit, gasLimits.txCostLimitPct);
    }

    /**
     * @dev Sets the gas limits config
     * @param newGasPriceLimit New gas price limit to be set
     * @param newPriorityFeeLimit New priority fee limit to be set
     * @param newTxCostLimit New tx cost limit to be set
     * @param newTxCostLimitPct New tx cost percentage limit to be set
     */
    function setGasLimits(
        uint256 newGasPriceLimit,
        uint256 newPriorityFeeLimit,
        uint256 newTxCostLimit,
        uint256 newTxCostLimitPct
    ) external override authP(authParams(newGasPriceLimit, newPriorityFeeLimit, newTxCostLimit, newTxCostLimitPct)) {
        _setGasLimits(newGasPriceLimit, newPriorityFeeLimit, newTxCostLimit, newTxCostLimitPct);
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
        GasLimitConfig memory config = gasLimits;
        bool isGasPriceAllowed = config.gasPriceLimit == 0 || tx.gasprice <= config.gasPriceLimit;
        if (!isGasPriceAllowed) revert TaskGasPriceLimitExceeded(tx.gasprice, config.gasPriceLimit);

        if (config.priorityFeeLimit > 0) {
            uint256 priorityFee = tx.gasprice - block.basefee;
            bool isPriorityFeeAllowed = priorityFee <= config.priorityFeeLimit;
            if (!isPriorityFeeAllowed) revert TaskPriorityFeeLimitExceeded(priorityFee, config.priorityFeeLimit);
        }
    }

    /**
     * @dev Validates transaction cost limit
     */
    function _afterGasLimitedTask(address token, uint256 amount) internal virtual {
        if (__initialGas__ == 0) revert TaskGasNotInitialized();

        GasLimitConfig memory config = gasLimits;
        uint256 totalGas = __initialGas__ - gasleft();
        uint256 totalCost = totalGas * tx.gasprice;
        bool isTxCostAllowed = config.txCostLimit == 0 || totalCost <= config.txCostLimit;
        if (!isTxCostAllowed) revert TaskTxCostLimitExceeded(totalCost, config.txCostLimit);
        delete __initialGas__;

        if (config.txCostLimitPct > 0 && amount > 0) {
            uint256 price = _getPrice(ISmartVault(this.smartVault()).wrappedNativeToken(), token);
            uint256 totalCostInToken = totalCost.mulUp(price);
            uint256 txCostPct = totalCostInToken.divUp(amount);
            if (txCostPct > config.txCostLimitPct) revert TaskTxCostLimitPctExceeded(txCostPct, config.txCostLimitPct);
        }
    }

    /**
     * @dev Sets the gas limits config
     * @param newGasPriceLimit New gas price limit to be set
     * @param newPriorityFeeLimit New priority fee limit to be set
     * @param newTxCostLimit New tx cost limit to be set
     * @param newTxCostLimitPct New tx cost percentage limit to be set
     */
    function _setGasLimits(
        uint256 newGasPriceLimit,
        uint256 newPriorityFeeLimit,
        uint256 newTxCostLimit,
        uint256 newTxCostLimitPct
    ) internal {
        if (newTxCostLimitPct > FixedPoint.ONE) revert TaskTxCostLimitPctAboveOne();

        gasLimits.gasPriceLimit = newGasPriceLimit;
        gasLimits.priorityFeeLimit = newPriorityFeeLimit;
        gasLimits.txCostLimit = newTxCostLimit;
        gasLimits.txCostLimitPct = newTxCostLimitPct;
        emit GasLimitsSet(newGasPriceLimit, newPriorityFeeLimit, newTxCostLimit, newTxCostLimitPct);
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
        if (isPaused) revert TaskPaused();
        isPaused = true;
        emit Paused();
    }

    /**
     * @dev Unpauses a task
     */
    function unpause() external override auth {
        if (!isPaused) revert TaskUnpaused();
        isPaused = false;
        emit Unpaused();
    }

    /**
     * @dev Before pausable task hook
     */
    function _beforePausableTask(address, uint256) internal virtual {
        if (isPaused) revert TaskPaused();
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

import '@quant-finance/solidity-datetime/contracts/DateTime.sol';
import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';

import '../interfaces/base/ITimeLockedTask.sol';

/**
 * @dev Time lock config for tasks. It allows limiting the frequency of a task.
 */
abstract contract TimeLockedTask is ITimeLockedTask, Authorized {
    using DateTime for uint256;

    uint256 private constant DAYS_28 = 60 * 60 * 24 * 28;

    /**
     * @dev Time-locks supports different frequency modes
     * @param Seconds To indicate the execution must occur every certain number of seconds
     * @param OnDay To indicate the execution must occur on day number from 1 to 28 every certain months
     * @param OnLastMonthDay To indicate the execution must occur on the last day of the month every certain months
     */
    enum Mode {
        Seconds,
        OnDay,
        OnLastMonthDay
    }

    // Time lock mode
    Mode internal _mode;

    // Time lock frequency
    uint256 internal _frequency;

    // Future timestamp since when the task can be executed
    uint256 internal _allowedAt;

    // Next future timestamp since when the task can be executed to be set, only used internally
    uint256 internal _nextAllowedAt;

    // Period in seconds during when a time-locked task can be executed since the allowed timestamp
    uint256 internal _window;

    /**
     * @dev Time lock config params. Only used in the initializer.
     * @param mode Time lock mode
     * @param frequency Time lock frequency value
     * @param allowedAt Time lock allowed date
     * @param window Time lock execution window
     */
    struct TimeLockConfig {
        uint8 mode;
        uint256 frequency;
        uint256 allowedAt;
        uint256 window;
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
        _setTimeLock(config.mode, config.frequency, config.allowedAt, config.window);
    }

    /**
     * @dev Tells the time-lock related information
     */
    function getTimeLock() external view returns (uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window) {
        return (uint8(_mode), _frequency, _allowedAt, _window);
    }

    /**
     * @dev Sets a new time lock
     */
    function setTimeLock(uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window)
        external
        override
        authP(authParams(mode, frequency, allowedAt, window))
    {
        _setTimeLock(mode, frequency, allowedAt, window);
    }

    /**
     * @dev Before time locked task hook
     */
    function _beforeTimeLockedTask(address, uint256) internal virtual {
        // Load storage variables
        Mode mode = _mode;
        uint256 frequency = _frequency;
        uint256 allowedAt = _allowedAt;
        uint256 window = _window;

        // First we check the current timestamp is not in the past
        if (block.timestamp < allowedAt) revert TaskTimeLockActive(block.timestamp, allowedAt);

        if (mode == Mode.Seconds) {
            if (frequency == 0) return;

            // If no window is set, the next allowed date is simply moved the number of seconds set as frequency.
            // Otherwise, the offset must be validated and the next allowed date is set to the next period.
            if (window == 0) _nextAllowedAt = block.timestamp + frequency;
            else {
                uint256 diff = block.timestamp - allowedAt;
                uint256 periods = diff / frequency;
                uint256 offset = diff - (periods * frequency);
                if (offset > window) revert TaskTimeLockActive(block.timestamp, allowedAt);
                _nextAllowedAt = allowedAt + ((periods + 1) * frequency);
            }
        } else {
            if (block.timestamp >= allowedAt && block.timestamp <= allowedAt + window) {
                // Check the current timestamp has not passed the allowed date set
                _nextAllowedAt = _getNextAllowedDate(allowedAt, frequency);
            } else {
                // Check the current timestamp is not before the current allowed date
                uint256 currentAllowedDay = mode == Mode.OnDay ? allowedAt.getDay() : block.timestamp.getDaysInMonth();
                uint256 currentAllowedAt = _getCurrentAllowedDate(allowedAt, currentAllowedDay);
                if (block.timestamp < currentAllowedAt) revert TaskTimeLockActive(block.timestamp, currentAllowedAt);

                // Check the current timestamp has not passed the allowed execution window
                uint256 extendedCurrentAllowedAt = currentAllowedAt + window;
                bool exceedsExecutionWindow = block.timestamp > extendedCurrentAllowedAt;
                if (exceedsExecutionWindow) revert TaskTimeLockActive(block.timestamp, extendedCurrentAllowedAt);

                // Finally set the next allowed date to the corresponding number of months from the current date
                _nextAllowedAt = _getNextAllowedDate(currentAllowedAt, frequency);
            }
        }
    }

    /**
     * @dev After time locked task hook
     */
    function _afterTimeLockedTask(address, uint256) internal virtual {
        if (_nextAllowedAt == 0) return;
        _setTimeLockAllowedAt(_nextAllowedAt);
        _nextAllowedAt = 0;
    }

    /**
     * @dev Sets a new time lock
     */
    function _setTimeLock(uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window) internal {
        if (mode == uint8(Mode.Seconds)) {
            // The execution window and timestamp are optional, but both must be given or none
            // If given the execution window cannot be larger than the number of seconds
            // Also, if these are given the frequency must be checked as well, otherwise it could be unsetting the lock
            if (window > 0 || allowedAt > 0) {
                if (frequency == 0) revert TaskInvalidFrequency(mode, frequency);
                if (window == 0 || window > frequency) revert TaskInvalidAllowedWindow(mode, window);
                if (allowedAt == 0) revert TaskInvalidAllowedDate(mode, allowedAt);
            }
        } else {
            // The other modes can be "on-day" or "on-last-day" where the frequency represents a number of months
            // There is no limit for the frequency, it simply cannot be zero
            if (frequency == 0) revert TaskInvalidFrequency(mode, frequency);

            // The execution window cannot be larger than the number of months considering months of 28 days
            if (window == 0 || window > frequency * DAYS_28) revert TaskInvalidAllowedWindow(mode, window);

            // The allowed date cannot be zero
            if (allowedAt == 0) revert TaskInvalidAllowedDate(mode, allowedAt);

            // If the mode is "on-day", the allowed date must be valid for every month, then the allowed day cannot be
            // larger than 28. But if the mode is "on-last-day", the allowed date day must be the last day of the month
            if (mode == uint8(Mode.OnDay)) {
                if (allowedAt.getDay() > 28) revert TaskInvalidAllowedDate(mode, allowedAt);
            } else if (mode == uint8(Mode.OnLastMonthDay)) {
                if (allowedAt.getDay() != allowedAt.getDaysInMonth()) revert TaskInvalidAllowedDate(mode, allowedAt);
            } else {
                revert TaskInvalidFrequencyMode(mode);
            }
        }

        _mode = Mode(mode);
        _frequency = frequency;
        _allowedAt = allowedAt;
        _window = window;

        emit TimeLockSet(mode, frequency, allowedAt, window);
    }

    /**
     * @dev Sets the time-lock execution allowed timestamp
     * @param allowedAt New execution allowed timestamp to be set
     */
    function _setTimeLockAllowedAt(uint256 allowedAt) internal {
        _allowedAt = allowedAt;
        emit TimeLockAllowedAtSet(allowedAt);
    }

    /**
     * @dev Tells the corresponding allowed date based on a current timestamp
     */
    function _getCurrentAllowedDate(uint256 allowedAt, uint256 day) private view returns (uint256) {
        (uint256 year, uint256 month, ) = block.timestamp.timestampToDate();
        return _getAllowedDateFor(allowedAt, year, month, day);
    }

    /**
     * @dev Tells the next allowed date based on a current allowed date considering a number of months to increase
     */
    function _getNextAllowedDate(uint256 allowedAt, uint256 monthsToIncrease) private view returns (uint256) {
        (uint256 year, uint256 month, uint256 day) = allowedAt.timestampToDate();
        uint256 increasedMonth = month + monthsToIncrease;
        uint256 nextMonth = increasedMonth % 12;
        uint256 nextYear = year + (increasedMonth / 12);
        uint256 nextDay = _mode == Mode.OnLastMonthDay ? DateTime._getDaysInMonth(nextYear, nextMonth) : day;
        return _getAllowedDateFor(allowedAt, nextYear, nextMonth, nextDay);
    }

    /**
     * @dev Builds an allowed date using a specific year, month, and day
     */
    function _getAllowedDateFor(uint256 allowedAt, uint256 year, uint256 month, uint256 day)
        private
        pure
        returns (uint256)
    {
        return
            DateTime.timestampFromDateTime(
                year,
                month,
                day,
                allowedAt.getHour(),
                allowedAt.getMinute(),
                allowedAt.getSecond()
            );
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
     * @dev Tells whether a token is allowed or not
     * @param token Address of the token being queried
     */
    function isTokenAllowed(address token) public view override returns (bool) {
        bool containsToken = _tokens.contains(token);
        return tokensAcceptanceType == TokensAcceptanceType.AllowList ? containsToken : !containsToken;
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
        if (tokens.length != added.length) revert TaskAcceptanceInputLengthMismatch();
        for (uint256 i = 0; i < tokens.length; i++) {
            _setTokenAcceptanceList(tokens[i], added[i]);
        }
    }

    /**
     * @dev Before token indexed task hook
     */
    function _beforeTokenIndexedTask(address token, uint256) internal virtual {
        if (!isTokenAllowed(token)) revert TaskTokenNotAllowed(token);
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
        if (token == address(0)) revert TaskAcceptanceTokenZero();
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
     * @dev Threshold defined by a token address and min/max values
     */
    struct Threshold {
        address token;
        uint256 min;
        uint256 max;
    }

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
    function defaultTokenThreshold() external view override returns (address thresholdToken, uint256 min, uint256 max) {
        Threshold memory threshold = _defaultThreshold;
        return (threshold.token, threshold.min, threshold.max);
    }

    /**
     * @dev Tells the token threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenThreshold(address token)
        external
        view
        override
        returns (address thresholdToken, uint256 min, uint256 max)
    {
        Threshold memory threshold = _customThresholds[token];
        return (threshold.token, threshold.min, threshold.max);
    }

    /**
     * @dev Tells the threshold that should be used for a token, it prioritizes custom thresholds over the default one
     * @param token Address of the token being queried
     */
    function getTokenThreshold(address token)
        external
        view
        virtual
        override
        returns (address thresholdToken, uint256 min, uint256 max)
    {
        Threshold memory threshold = _getTokenThreshold(token);
        return (threshold.token, threshold.min, threshold.max);
    }

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param min New threshold minimum to be set
     * @param max New threshold maximum to be set
     */
    function setDefaultTokenThreshold(address thresholdToken, uint256 min, uint256 max)
        external
        override
        authP(authParams(thresholdToken, min, max))
    {
        _setDefaultTokenThreshold(thresholdToken, min, max);
    }

    /**
     * @dev Sets a custom token threshold
     * @param token Address of the token to set a custom threshold for
     * @param thresholdToken New custom threshold token to be set
     * @param min New custom threshold minimum to be set
     * @param max New custom threshold maximum to be set
     */
    function setCustomTokenThreshold(address token, address thresholdToken, uint256 min, uint256 max)
        external
        override
        authP(authParams(token, thresholdToken, min, max))
    {
        _setCustomTokenThreshold(token, thresholdToken, min, max);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256);

    /**
     * @dev Tells the threshold that should be used for a token, it prioritizes custom thresholds over the default one
     * @param token Address of the token being queried
     */
    function _getTokenThreshold(address token) internal view returns (Threshold memory) {
        Threshold storage customThreshold = _customThresholds[token];
        return customThreshold.token == address(0) ? _defaultThreshold : customThreshold;
    }

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256 amount) internal virtual {
        Threshold memory threshold = _getTokenThreshold(token);
        if (threshold.token == address(0)) return;

        uint256 convertedAmount = threshold.token == token ? amount : amount.mulDown(_getPrice(token, threshold.token));
        bool isValid = convertedAmount >= threshold.min && (threshold.max == 0 || convertedAmount <= threshold.max);
        if (!isValid) revert TaskTokenThresholdNotMet(threshold.token, convertedAmount, threshold.min, threshold.max);
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
     * @param min New threshold minimum to be set
     * @param max New threshold maximum to be set
     */
    function _setDefaultTokenThreshold(address thresholdToken, uint256 min, uint256 max) internal {
        _setTokenThreshold(_defaultThreshold, thresholdToken, min, max);
        emit DefaultTokenThresholdSet(thresholdToken, min, max);
    }

    /**
     * @dev Sets a custom of tokens thresholds
     * @param token Address of the token to set a custom threshold for
     * @param thresholdToken New custom threshold token to be set
     * @param min New custom threshold minimum to be set
     * @param max New custom threshold maximum to be set
     */
    function _setCustomTokenThreshold(address token, address thresholdToken, uint256 min, uint256 max) internal {
        if (token == address(0)) revert TaskThresholdTokenZero();
        _setTokenThreshold(_customThresholds[token], thresholdToken, min, max);
        emit CustomTokenThresholdSet(token, thresholdToken, min, max);
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
        if (!isZeroThreshold && !isNonZeroThreshold) revert TaskInvalidThresholdInput(token, min, max);

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
    function defaultVolumeLimit()
        external
        view
        override
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime)
    {
        VolumeLimit memory limit = _defaultVolumeLimit;
        return (limit.token, limit.amount, limit.accrued, limit.period, limit.nextResetTime);
    }

    /**
     * @dev Tells the custom volume limit set for a specific token
     * @param token Address of the token being queried
     */
    function customVolumeLimit(address token)
        external
        view
        override
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime)
    {
        VolumeLimit memory limit = _customVolumeLimits[token];
        return (limit.token, limit.amount, limit.accrued, limit.period, limit.nextResetTime);
    }

    /**
     * @dev Tells the volume limit that should be used for a token, it prioritizes custom limits over the default one
     * @param token Address of the token being queried
     */
    function getVolumeLimit(address token)
        external
        view
        override
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime)
    {
        VolumeLimit memory limit = _getVolumeLimit(token);
        return (limit.token, limit.amount, limit.accrued, limit.period, limit.nextResetTime);
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
        if (processedVolume > limit.amount) revert TaskVolumeLimitExceeded(limit.token, limit.amount, processedVolume);
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
        if (token == address(0)) revert TaskVolumeLimitTokenZero();
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
        if (!isZeroLimit && !isNonZeroLimit) revert TaskInvalidVolumeLimitInput(token, amount, period);

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

pragma solidity ^0.8.0;

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/axelar/IAxelarConnector.sol';

import './BaseBridgeTask.sol';
import '../interfaces/bridge/IAxelarBridger.sol';

/**
 * @title Axelar bridger
 * @dev Task that extends the base bridge task to use Axelar
 */
contract AxelarBridger is IAxelarBridger, BaseBridgeTask {
    using FixedPoint for uint256;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('AXELAR_BRIDGER');

    /**
     * @dev Axelar bridge config. Only used in the initializer.
     */
    struct AxelarBridgeConfig {
        BaseBridgeConfig baseBridgeConfig;
    }

    /**
     * @dev Initializes the Axelar bridger
     * @param config Axelar bridge config
     */
    function initialize(AxelarBridgeConfig memory config) external virtual initializer {
        __AxelarBridger_init(config);
    }

    /**
     * @dev Initializes the Axelar bridger. It does call upper contracts initializers.
     * @param config Axelar bridge config
     */
    function __AxelarBridger_init(AxelarBridgeConfig memory config) internal onlyInitializing {
        __BaseBridgeTask_init(config.baseBridgeConfig);
        __AxelarBridger_init_unchained(config);
    }

    /**
     * @dev Initializes the Axelar bridger. It does not call upper contracts initializers.
     * @param config Axelar bridge config
     */
    function __AxelarBridger_init_unchained(AxelarBridgeConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Axelar bridger
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeAxelarBridger(token, amount);

        bytes memory connectorData = abi.encodeWithSelector(
            IAxelarConnector.execute.selector,
            getDestinationChain(token),
            token,
            amount,
            recipient
        );

        ISmartVault(smartVault).execute(connector, connectorData);
        _afterAxelarBridger(token, amount);
    }

    /**
     * @dev Before Axelar bridger hook
     */
    function _beforeAxelarBridger(address token, uint256 amount) internal virtual {
        // Axelar does not support specifying slippage nor fee
        _beforeBaseBridgeTask(token, amount, 0, 0);
    }

    /**
     * @dev After Axelar bridger task hook
     */
    function _afterAxelarBridger(address token, uint256 amount) internal virtual {
        // Axelar does not support specifying slippage nor fee
        _afterBaseBridgeTask(token, amount, 0, 0);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import '../Task.sol';
import '../interfaces/bridge/IBaseBridgeTask.sol';

/**
 * @title Base bridge task
 * @dev Task that offers the basic components for more detailed bridge tasks
 */
abstract contract BaseBridgeTask is IBaseBridgeTask, Task {
    using FixedPoint for uint256;

    // Connector address
    address public override connector;

    // Recipient address
    address public override recipient;

    // Default destination chain
    uint256 public override defaultDestinationChain;

    // Default maximum slippage in fixed point
    uint256 public override defaultMaxSlippage;

    // Default maximum fee
    MaxFee internal _defaultMaxFee;

    // Destination chain per token address
    mapping (address => uint256) public override customDestinationChain;

    // Maximum slippage per token address
    mapping (address => uint256) public override customMaxSlippage;

    // Maximum fee per token address
    mapping (address => MaxFee) internal _customMaxFee;

    /**
     * @dev Maximum fee defined by a token address and a max fee value
     */
    struct MaxFee {
        address token;
        uint256 amount;
    }

    /**
     * @dev Custom destination chain config. Only used in the initializer.
     */
    struct CustomDestinationChain {
        address token;
        uint256 destinationChain;
    }

    /**
     * @dev Custom max slippage config. Only used in the initializer.
     */
    struct CustomMaxSlippage {
        address token;
        uint256 maxSlippage;
    }

    /**
     * @dev Custom max fee config. Only used in the initializer.
     */
    struct CustomMaxFee {
        address token;
        MaxFee maxFee;
    }

    /**
     * @dev Base bridge config. Only used in the initializer.
     */
    struct BaseBridgeConfig {
        address connector;
        address recipient;
        uint256 destinationChain;
        uint256 maxSlippage;
        MaxFee maxFee;
        CustomDestinationChain[] customDestinationChains;
        CustomMaxSlippage[] customMaxSlippages;
        CustomMaxFee[] customMaxFees;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the base bridge task. It does call upper contracts initializers.
     * @param config Base bridge config
     */
    function __BaseBridgeTask_init(BaseBridgeConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __BaseBridgeTask_init_unchained(config);
    }

    /**
     * @dev Initializes the base bridge task. It does not call upper contracts initializers.
     * @param config Base bridge config
     */
    function __BaseBridgeTask_init_unchained(BaseBridgeConfig memory config) internal onlyInitializing {
        _setConnector(config.connector);
        _setRecipient(config.recipient);
        _setDefaultDestinationChain(config.destinationChain);
        _setDefaultMaxSlippage(config.maxSlippage);
        MaxFee memory defaultFee = config.maxFee;
        _setDefaultMaxFee(defaultFee.token, defaultFee.amount);

        for (uint256 i = 0; i < config.customDestinationChains.length; i++) {
            CustomDestinationChain memory customConfig = config.customDestinationChains[i];
            _setCustomDestinationChain(customConfig.token, customConfig.destinationChain);
        }

        for (uint256 i = 0; i < config.customMaxSlippages.length; i++) {
            _setCustomMaxSlippage(config.customMaxSlippages[i].token, config.customMaxSlippages[i].maxSlippage);
        }

        for (uint256 i = 0; i < config.customMaxFees.length; i++) {
            CustomMaxFee memory customConfig = config.customMaxFees[i];
            MaxFee memory maxFee = customConfig.maxFee;
            _setCustomMaxFee(customConfig.token, maxFee.token, maxFee.amount);
        }
    }

    /**
     * @dev Tells the default max fee
     */
    function defaultMaxFee() external view override returns (address maxFeeToken, uint256 amount) {
        MaxFee memory maxFee = _defaultMaxFee;
        return (maxFee.token, maxFee.amount);
    }

    /**
     * @dev Tells the max fee defined for a specific token
     * @param token Address of the token being queried
     */
    function customMaxFee(address token) external view override returns (address maxFeeToken, uint256 amount) {
        MaxFee memory maxFee = _customMaxFee[token];
        return (maxFee.token, maxFee.amount);
    }

    /**
     * @dev Tells the destination chain that should be used for a token
     * @param token Address of the token to get the destination chain for
     */
    function getDestinationChain(address token) public view virtual override returns (uint256) {
        uint256 chain = customDestinationChain[token];
        return chain == 0 ? defaultDestinationChain : chain;
    }

    /**
     * @dev Tells the max slippage that should be used for a token
     * @param token Address of the token to get the max slippage for
     */
    function getMaxSlippage(address token) public view virtual override returns (uint256) {
        uint256 maxSlippage = customMaxSlippage[token];
        return maxSlippage == 0 ? defaultMaxSlippage : maxSlippage;
    }

    /**
     * @dev Tells the max fee that should be used for a token
     * @param token Address of the token to get the max fee for
     */
    function getMaxFee(address token) external view virtual override returns (address maxFeeToken, uint256 amount) {
        MaxFee memory maxFee = _getMaxFee(token);
        return (maxFee.token, maxFee.amount);
    }

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external override authP(authParams(newConnector)) {
        _setConnector(newConnector);
    }

    /**
     * @dev Sets the recipient address. Sender must be authorized.
     * @param newRecipient Address of the new recipient to be set
     */
    function setRecipient(address newRecipient) external override authP(authParams(newRecipient)) {
        _setRecipient(newRecipient);
    }

    /**
     * @dev Sets the default destination chain
     * @param destinationChain Default destination chain to be set
     */
    function setDefaultDestinationChain(uint256 destinationChain)
        external
        override
        authP(authParams(destinationChain))
    {
        _setDefaultDestinationChain(destinationChain);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external override authP(authParams(maxSlippage)) {
        _setDefaultMaxSlippage(maxSlippage);
    }

    /**
     * @dev Sets the default max fee
     * @param maxFeeToken Default max fee token to be set
     * @param amount Default max fee amount to be set
     */
    function setDefaultMaxFee(address maxFeeToken, uint256 amount)
        external
        override
        authP(authParams(maxFeeToken, amount))
    {
        _setDefaultMaxFee(maxFeeToken, amount);
    }

    /**
     * @dev Sets a custom destination chain
     * @param token Address of the token to set a custom destination chain for
     * @param destinationChain Destination chain to be set
     */
    function setCustomDestinationChain(address token, uint256 destinationChain)
        external
        override
        authP(authParams(token, destinationChain))
    {
        _setCustomDestinationChain(token, destinationChain);
    }

    /**
     * @dev Sets a custom max slippage
     * @param token Address of the token to set a custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function setCustomMaxSlippage(address token, uint256 maxSlippage)
        external
        override
        authP(authParams(token, maxSlippage))
    {
        _setCustomMaxSlippage(token, maxSlippage);
    }

    /**
     * @dev Sets a custom max fee
     * @param token Address of the token to set a custom max fee for
     * @param maxFeeToken Max fee token to be set for the given token
     * @param amount Max fee amount to be set for the given token
     */
    function setCustomMaxFee(address token, address maxFeeToken, uint256 amount)
        external
        override
        authP(authParams(token, maxFeeToken, amount))
    {
        _setCustomMaxFee(token, maxFeeToken, amount);
    }

    /**
     * @dev Tells the max fee that should be used for a token
     * @param token Address of the token to get the max fee for
     */
    function _getMaxFee(address token) internal view virtual returns (MaxFee memory) {
        MaxFee memory maxFee = _customMaxFee[token];
        return maxFee.token == address(0) ? _defaultMaxFee : maxFee;
    }

    /**
     * @dev Before base bridge task hook
     */
    function _beforeBaseBridgeTask(address token, uint256 amount, uint256 slippage, uint256 fee) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
        if (getDestinationChain(token) == 0) revert TaskDestinationChainNotSet();

        uint256 maxSlippage = getMaxSlippage(token);
        if (slippage > maxSlippage) revert TaskSlippageAboveMax(slippage, maxSlippage);

        // If no fee is given we simply ignore the max fee config
        if (fee == 0) return;

        // Otherwise, we revert in case there is no max fee set
        MaxFee memory maxFee = _getMaxFee(token);
        if (maxFee.token == address(0)) revert TaskFeeAboveMax(fee, maxFee.amount);

        uint256 convertedFee = maxFee.token == token ? fee : fee.mulDown(_getPrice(token, maxFee.token));
        if (convertedFee > maxFee.amount) revert TaskFeeAboveMax(convertedFee, maxFee.amount);
    }

    /**
     * @dev After base bridge task hook
     */
    function _afterBaseBridgeTask(address token, uint256 amount, uint256, uint256) internal virtual {
        _afterTask(token, amount);
    }

    /**
     * @dev Sets the balance connectors. Next balance connector must be unset.
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal virtual override {
        if (next != bytes32(0)) revert TaskNextConnectorNotZero(next);
        super._setBalanceConnectors(previous, next);
    }

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function _setConnector(address newConnector) internal {
        if (newConnector == address(0)) revert TaskConnectorZero();
        connector = newConnector;
        emit ConnectorSet(newConnector);
    }

    /**
     * @dev Sets the recipient address
     * @param newRecipient Address of the new recipient to be set
     */
    function _setRecipient(address newRecipient) internal {
        if (newRecipient == address(0)) revert TaskRecipientZero();
        recipient = newRecipient;
        emit RecipientSet(newRecipient);
    }

    /**
     * @dev Sets the default destination chain
     * @param destinationChain Default destination chain to be set
     */
    function _setDefaultDestinationChain(uint256 destinationChain) internal {
        if (destinationChain == block.chainid) revert TaskBridgeCurrentChainId(destinationChain);
        defaultDestinationChain = destinationChain;
        emit DefaultDestinationChainSet(destinationChain);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function _setDefaultMaxSlippage(uint256 maxSlippage) internal {
        if (maxSlippage > FixedPoint.ONE) revert TaskSlippageAboveOne();
        defaultMaxSlippage = maxSlippage;
        emit DefaultMaxSlippageSet(maxSlippage);
    }

    /**
     * @dev Sets the default max fee
     * @param maxFeeToken Default max fee token to be set
     * @param amount Default max fee amount to be set
     */
    function _setDefaultMaxFee(address maxFeeToken, uint256 amount) internal {
        _setMaxFee(_defaultMaxFee, maxFeeToken, amount);
        emit DefaultMaxFeeSet(maxFeeToken, amount);
    }

    /**
     * @dev Sets a custom destination chain for a token
     * @param token Address of the token to set the custom destination chain for
     * @param destinationChain Destination chain to be set
     */
    function _setCustomDestinationChain(address token, uint256 destinationChain) internal {
        if (token == address(0)) revert TaskTokenZero();
        if (destinationChain == block.chainid) revert TaskBridgeCurrentChainId(destinationChain);
        customDestinationChain[token] = destinationChain;
        emit CustomDestinationChainSet(token, destinationChain);
    }

    /**
     * @dev Sets a custom max slippage for a token
     * @param token Address of the token to set the custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function _setCustomMaxSlippage(address token, uint256 maxSlippage) internal {
        if (token == address(0)) revert TaskTokenZero();
        if (maxSlippage > FixedPoint.ONE) revert TaskSlippageAboveOne();
        customMaxSlippage[token] = maxSlippage;
        emit CustomMaxSlippageSet(token, maxSlippage);
    }

    /**
     * @dev Sets a custom max fee for a token
     * @param token Address of the token to set the custom max fee for
     * @param maxFeeToken Max fee token to be set for the given token
     * @param amount Max fee amount to be set for the given token
     */
    function _setCustomMaxFee(address token, address maxFeeToken, uint256 amount) internal {
        if (token == address(0)) revert TaskTokenZero();
        _setMaxFee(_customMaxFee[token], maxFeeToken, amount);
        emit CustomMaxFeeSet(token, maxFeeToken, amount);
    }

    /**
     * @dev Sets a max fee
     * @param maxFee Max fee to be updated
     * @param token Max fee token to be set
     * @param amount Max fee amount to be set
     */
    function _setMaxFee(MaxFee storage maxFee, address token, uint256 amount) private {
        if (token == address(0) && amount != 0) revert TaskInvalidMaxFee();
        maxFee.token = token;
        maxFee.amount = amount;
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/connext/IConnextConnector.sol';

import './BaseBridgeTask.sol';
import '../interfaces/bridge/IConnextBridger.sol';

/**
 * @title Connext bridger
 * @dev Task that extends the base bridge task to use Connext
 */
contract ConnextBridger is IConnextBridger, BaseBridgeTask {
    using FixedPoint for uint256;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('CONNEXT_BRIDGER');

    /**
     * @dev Connext bridge config. Only used in the initializer.
     */
    struct ConnextBridgeConfig {
        BaseBridgeConfig baseBridgeConfig;
    }

    /**
     * @dev Initializes the Connext bridger
     * @param config Connext bridge config
     */
    function initialize(ConnextBridgeConfig memory config) external virtual initializer {
        __ConnextBridger_init(config);
    }

    /**
     * @dev Initializes the Connext bridger. It does call upper contracts initializers.
     * @param config Connext bridge config
     */
    function __ConnextBridger_init(ConnextBridgeConfig memory config) internal onlyInitializing {
        __BaseBridgeTask_init(config.baseBridgeConfig);
        __ConnextBridger_init_unchained(config);
    }

    /**
     * @dev Initializes the Connext bridger. It does not call upper contracts initializers.
     * @param config Connext bridge config
     */
    function __ConnextBridger_init_unchained(ConnextBridgeConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Connext bridger
     */
    function call(address token, uint256 amount, uint256 slippage, uint256 fee)
        external
        override
        authP(authParams(token, amount, slippage, fee))
    {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeConnextBridger(token, amount, slippage, fee);

        uint256 amountAfterFees = amount - fee;
        uint256 minAmountOut = amountAfterFees.mulUp(FixedPoint.ONE - slippage);
        bytes memory connectorData = abi.encodeWithSelector(
            IConnextConnector.execute.selector,
            getDestinationChain(token),
            token,
            amount,
            minAmountOut,
            recipient,
            fee
        );

        ISmartVault(smartVault).execute(connector, connectorData);
        _afterConnextBridger(token, amount, slippage, fee);
    }

    /**
     * @dev Before connext bridger hook
     */
    function _beforeConnextBridger(address token, uint256 amount, uint256 slippage, uint256 fee) internal virtual {
        _beforeBaseBridgeTask(token, amount, slippage, fee);
    }

    /**
     * @dev After connext bridger hook
     */
    function _afterConnextBridger(address token, uint256 amount, uint256 slippage, uint256 fee) internal virtual {
        _afterBaseBridgeTask(token, amount, slippage, fee);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/hop/IHopBridgeConnector.sol';

import './BaseBridgeTask.sol';
import '../interfaces/bridge/IHopBridger.sol';

/**
 * @title Hop bridger
 * @dev Task that extends the base bridge task to use Hop
 */
contract HopBridger is IHopBridger, BaseBridgeTask {
    using FixedPoint for uint256;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('HOP_BRIDGER');

    // Relayer address
    address public override relayer;

    // Maximum deadline in seconds
    uint256 public override maxDeadline;

    // List of Hop entrypoints per token
    mapping (address => address) public override tokenHopEntrypoint;

    /**
     * @dev Token Hop entrypoint config. Only used in the initializer.
     */
    struct TokenHopEntrypoint {
        address token;
        address entrypoint;
    }

    /**
     * @dev Hop bridge config. Only used in the initializer.
     */
    struct HopBridgeConfig {
        address relayer;
        uint256 maxDeadline;
        TokenHopEntrypoint[] tokenHopEntrypoints;
        BaseBridgeConfig baseBridgeConfig;
    }

    /**
     * @dev Initializes the Hop bridger
     * @param config Hop bridge config
     */
    function initialize(HopBridgeConfig memory config) external virtual initializer {
        __HopBridger_init(config);
    }

    /**
     * @dev Initializes the Hop bridger. It does call upper contracts initializers.
     * @param config Hop bridge config
     */
    function __HopBridger_init(HopBridgeConfig memory config) internal onlyInitializing {
        __BaseBridgeTask_init(config.baseBridgeConfig);
        __HopBridger_init_unchained(config);
    }

    /**
     * @dev Initializes the Hop bridger. It does not call upper contracts initializers.
     * @param config Hop bridge config
     */
    function __HopBridger_init_unchained(HopBridgeConfig memory config) internal onlyInitializing {
        _setRelayer(config.relayer);
        _setMaxDeadline(config.maxDeadline);

        for (uint256 i = 0; i < config.tokenHopEntrypoints.length; i++) {
            TokenHopEntrypoint memory customConfig = config.tokenHopEntrypoints[i];
            _setTokenHopEntrypoint(customConfig.token, customConfig.entrypoint);
        }
    }

    /**
     * @dev Sets the relayer, only used when bridging from L1 to L2
     * @param newRelayer New relayer address to be set
     */
    function setRelayer(address newRelayer) external override authP(authParams(newRelayer)) {
        _setRelayer(newRelayer);
    }

    /**
     * @dev Sets the max deadline
     * @param newMaxDeadline New max deadline to be set
     */
    function setMaxDeadline(uint256 newMaxDeadline) external override authP(authParams(newMaxDeadline)) {
        _setMaxDeadline(newMaxDeadline);
    }

    /**
     * @dev Sets an entrypoint for a tokens
     * @param token Token address to set a Hop entrypoint for
     * @param entrypoint Hop entrypoint address to be set for a token
     */
    function setTokenHopEntrypoint(address token, address entrypoint)
        external
        override
        authP(authParams(token, entrypoint))
    {
        _setTokenHopEntrypoint(token, entrypoint);
    }

    /**
     * @dev Execute Hop bridger
     */
    function call(address token, uint256 amount, uint256 slippage, uint256 fee)
        external
        override
        authP(authParams(token, amount, slippage, fee))
    {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeHopBridger(token, amount, slippage, fee);

        uint256 amountAfterFees = amount - fee;
        uint256 minAmountOut = amountAfterFees.mulUp(FixedPoint.ONE - slippage);
        bytes memory connectorData = abi.encodeWithSelector(
            IHopBridgeConnector.execute.selector,
            getDestinationChain(token),
            token,
            amount,
            minAmountOut,
            recipient,
            tokenHopEntrypoint[token],
            block.timestamp + maxDeadline,
            relayer,
            fee
        );

        ISmartVault(smartVault).execute(connector, connectorData);
        _afterHopBridger(token, amount, slippage, fee);
    }

    /**
     * @dev Before Hop bridger hook
     */
    function _beforeHopBridger(address token, uint256 amount, uint256 slippage, uint256 fee) internal virtual {
        _beforeBaseBridgeTask(token, amount, slippage, fee);
        if (tokenHopEntrypoint[token] == address(0)) revert TaskMissingHopEntrypoint();
    }

    /**
     * @dev After Hop bridger hook
     */
    function _afterHopBridger(address token, uint256 amount, uint256 slippage, uint256 fee) internal virtual {
        _afterBaseBridgeTask(token, amount, slippage, fee);
    }

    /**
     * @dev Sets the relayer address, only used when bridging from L1 to L2
     */
    function _setRelayer(address _relayer) internal {
        relayer = _relayer;
        emit RelayerSet(_relayer);
    }

    /**
     * @dev Sets the max deadline
     */
    function _setMaxDeadline(uint256 _maxDeadline) internal {
        if (_maxDeadline == 0) revert TaskMaxDeadlineZero();
        maxDeadline = _maxDeadline;
        emit MaxDeadlineSet(_maxDeadline);
    }

    /**
     * @dev Set a Hop entrypoint for a token
     * @param token Address of the token to set a Hop entrypoint for
     * @param entrypoint Hop entrypoint to be set
     */
    function _setTokenHopEntrypoint(address token, address entrypoint) internal {
        if (token == address(0)) revert TaskTokenZero();
        tokenHopEntrypoint[token] = entrypoint;
        emit TokenHopEntrypointSet(token, entrypoint);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/symbiosis/ISymbiosisConnector.sol';

import './BaseBridgeTask.sol';
import '../interfaces/bridge/ISymbiosisBridger.sol';

/**
 * @title Symbiosis bridger
 * @dev Task that extends the base bridge task to use Symbiosis
 */
contract SymbiosisBridger is ISymbiosisBridger, BaseBridgeTask {
    using FixedPoint for uint256;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('SYMBIOSIS_BRIDGER');

    /**
     * @dev Symbiosis bridge config. Only used in the initializer.
     */
    struct SymbiosisBridgeConfig {
        BaseBridgeConfig baseBridgeConfig;
    }

    /**
     * @dev Initializes the Symbiosis bridger
     * @param config Symbiosis bridge config
     */
    function initialize(SymbiosisBridgeConfig memory config) external virtual initializer {
        __SymbiosisBridger_init(config);
    }

    /**
     * @dev Initializes the Symbiosis bridger. It does call upper contracts initializers.
     * @param config Symbiosis bridge config
     */
    function __SymbiosisBridger_init(SymbiosisBridgeConfig memory config) internal onlyInitializing {
        __BaseBridgeTask_init(config.baseBridgeConfig);
        __SymbiosisBridger_init_unchained(config);
    }

    /**
     * @dev Initializes the Symbiosis bridger. It does not call upper contracts initializers.
     * @param config Symbiosis bridge config
     */
    function __SymbiosisBridger_init_unchained(SymbiosisBridgeConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Symbiosis bridger
     */
    function call(address token, uint256 amount, bytes memory data) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeSymbiosisBridger(token, amount);

        bytes memory connectorData = abi.encodeWithSelector(ISymbiosisConnector.execute.selector, token, amount, data);

        ISmartVault(smartVault).execute(connector, connectorData);
        _afterSymbiosisBridger(token, amount);
    }

    /**
     * @dev Before Symbiosis bridger hook
     */
    function _beforeSymbiosisBridger(address token, uint256 amount) internal virtual {
        // Symbiosis does not support specifying slippage nor fee
        _beforeBaseBridgeTask(token, amount, 0, 0);
    }

    /**
     * @dev After Symbiosis bridger task hook
     */
    function _afterSymbiosisBridger(address token, uint256 amount) internal virtual {
        // Symbiosis does not support specifying slippage nor fee
        _afterBaseBridgeTask(token, amount, 0, 0);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/wormhole/IWormholeConnector.sol';

import './BaseBridgeTask.sol';
import '../interfaces/bridge/IWormholeBridger.sol';

/**
 * @title Wormhole bridger
 * @dev Task that extends the bridger task to use Wormhole
 */
contract WormholeBridger is IWormholeBridger, BaseBridgeTask {
    using FixedPoint for uint256;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('WORMHOLE_BRIDGER');

    /**
     * @dev Wormhole bridge config. Only used in the initializer.
     */
    struct WormholeBridgeConfig {
        BaseBridgeConfig baseBridgeConfig;
    }

    /**
     * @dev Initializes the Wormhole bridger
     * @param config Wormhole bridge config
     */
    function initialize(WormholeBridgeConfig memory config) external virtual initializer {
        __WormholeBridger_init(config);
    }

    /**
     * @dev Initializes the Wormhole bridger. It does call upper contracts initializers.
     * @param config Wormhole bridge config
     */
    function __WormholeBridger_init(WormholeBridgeConfig memory config) internal onlyInitializing {
        __BaseBridgeTask_init(config.baseBridgeConfig);
        __WormholeBridger_init_unchained(config);
    }

    /**
     * @dev Initializes the Wormhole bridger. It does not call upper contracts initializers.
     * @param config Wormhole bridge config
     */
    function __WormholeBridger_init_unchained(WormholeBridgeConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Wormhole bridger
     */
    function call(address token, uint256 amount, uint256 fee) external override authP(authParams(token, amount, fee)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeWormholeBridger(token, amount, fee);

        uint256 minAmountOut = amount - fee;
        bytes memory connectorData = abi.encodeWithSelector(
            IWormholeConnector.execute.selector,
            getDestinationChain(token),
            token,
            amount,
            minAmountOut,
            recipient
        );

        ISmartVault(smartVault).execute(connector, connectorData);
        _afterWormholeBridger(token, amount, fee);
    }

    /**
     * @dev Before Wormhole bridger hook
     */
    function _beforeWormholeBridger(address token, uint256 amount, uint256 fee) internal virtual {
        // Wormhole does not support specifying slippage
        _beforeBaseBridgeTask(token, amount, 0, fee);
    }

    /**
     * @dev After Wormhole bridger hook
     */
    function _afterWormholeBridger(address token, uint256 amount, uint256 fee) internal virtual {
        // Wormhole does not support specifying slippage
        _afterBaseBridgeTask(token, amount, 0, fee);
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
     * @dev The balance connectors are the same
     */
    error TaskSameBalanceConnectors(bytes32 connectorId);

    /**
     * @dev The smart vault's price oracle is not set
     */
    error TaskSmartVaultPriceOracleNotSet(address smartVault);

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
     * @dev Tells the address from where the token amounts to execute this task are fetched.
     * This address must be the Smart Vault in case the previous balance connector is set.
     */
    function getTokensSource() external view returns (address);

    /**
     * @dev Tells the amount a task should use for a token
     * @param token Address of the token being queried
     */
    function getTaskAmount(address token) external view returns (uint256);

    /**
     * @dev Tells the previous and next balance connectors id of the previous task in the workflow
     */
    function getBalanceConnectors() external view returns (bytes32 previous, bytes32 next);

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
     * @dev The tx initial gas cache has not been initialized
     */
    error TaskGasNotInitialized();

    /**
     * @dev The gas price used is greater than the limit
     */
    error TaskGasPriceLimitExceeded(uint256 gasPrice, uint256 gasPriceLimit);

    /**
     * @dev The priority fee used is greater than the priority fee limit
     */
    error TaskPriorityFeeLimitExceeded(uint256 priorityFee, uint256 priorityFeeLimit);

    /**
     * @dev The transaction cost is greater than the transaction cost limit
     */
    error TaskTxCostLimitExceeded(uint256 txCost, uint256 txCostLimit);

    /**
     * @dev The transaction cost percentage is greater than the transaction cost limit percentage
     */
    error TaskTxCostLimitPctExceeded(uint256 txCostPct, uint256 txCostLimitPct);

    /**
     * @dev The new transaction cost limit percentage is greater than one
     */
    error TaskTxCostLimitPctAboveOne();

    /**
     * @dev Emitted every time the gas limits are set
     */
    event GasLimitsSet(uint256 gasPriceLimit, uint256 priorityFeeLimit, uint256 txCostLimit, uint256 txCostLimitPct);

    /**
     * @dev Tells the gas limits config
     */
    function getGasLimits()
        external
        view
        returns (uint256 gasPriceLimit, uint256 priorityFeeLimit, uint256 txCostLimit, uint256 txCostLimitPct);

    /**
     * @dev Sets the gas limits config
     * @param newGasPriceLimit New gas price limit to be set
     * @param newPriorityFeeLimit New priority fee limit to be set
     * @param newTxCostLimit New tx cost limit to be set
     * @param newTxCostLimitPct New tx cost percentage limit to be set
     */
    function setGasLimits(
        uint256 newGasPriceLimit,
        uint256 newPriorityFeeLimit,
        uint256 newTxCostLimit,
        uint256 newTxCostLimitPct
    ) external;
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
     * @dev The task is paused
     */
    error TaskPaused();

    /**
     * @dev The task is unpaused
     */
    error TaskUnpaused();

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
     * @dev The time lock frequency mode requested is invalid
     */
    error TaskInvalidFrequencyMode(uint8 mode);

    /**
     * @dev The time lock frequency is not valid
     */
    error TaskInvalidFrequency(uint8 mode, uint256 frequency);

    /**
     * @dev The time lock allowed date is not valid
     */
    error TaskInvalidAllowedDate(uint8 mode, uint256 date);

    /**
     * @dev The time lock allowed window is not valid
     */
    error TaskInvalidAllowedWindow(uint8 mode, uint256 window);

    /**
     * @dev The time lock is still active
     */
    error TaskTimeLockActive(uint256 currentTimestamp, uint256 expiration);

    /**
     * @dev Emitted every time a new time lock is set
     */
    event TimeLockSet(uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window);

    /**
     * @dev Emitted every time a new expiration timestamp is set
     */
    event TimeLockAllowedAtSet(uint256 allowedAt);

    /**
     * @dev Tells all the time-lock related information
     */
    function getTimeLock() external view returns (uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window);

    /**
     * @dev Sets the time-lock
     * @param mode Time lock mode
     * @param frequency Time lock frequency
     * @param allowedAt Future timestamp since when the task can be executed
     * @param window Period in seconds during when a time-locked task can be executed since the allowed timestamp
     */
    function setTimeLock(uint8 mode, uint256 frequency, uint256 allowedAt, uint256 window) external;
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
     * @dev The acceptance token is zero
     */
    error TaskAcceptanceTokenZero();

    /**
     * @dev The tokens acceptance input length mismatch
     */
    error TaskAcceptanceInputLengthMismatch();

    /**
     * @dev The token is not allowed
     */
    error TaskTokenNotAllowed(address token);

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
     * @dev Tells whether a token is allowed or not
     * @param token Address of the token being queried
     */
    function isTokenAllowed(address token) external view returns (bool);

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
     * @dev The token threshold token is zero
     */
    error TaskThresholdTokenZero();

    /**
     * @dev The token threshold to be set is invalid
     */
    error TaskInvalidThresholdInput(address token, uint256 min, uint256 max);

    /**
     * @dev The token threshold has not been met
     */
    error TaskTokenThresholdNotMet(address token, uint256 amount, uint256 min, uint256 max);

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
    function defaultTokenThreshold() external view returns (address thresholdToken, uint256 min, uint256 max);

    /**
     * @dev Tells the custom threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenThreshold(address token)
        external
        view
        returns (address thresholdToken, uint256 min, uint256 max);

    /**
     * @dev Tells the threshold that should be used for a token
     * @param token Address of the token being queried
     */
    function getTokenThreshold(address token) external view returns (address thresholdToken, uint256 min, uint256 max);

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param min New threshold minimum to be set
     * @param max New threshold maximum to be set
     */
    function setDefaultTokenThreshold(address thresholdToken, uint256 min, uint256 max) external;

    /**
     * @dev Sets a custom token threshold
     * @param token Address of the token to set a custom threshold
     * @param thresholdToken New custom threshold token to be set
     * @param min New custom threshold minimum to be set
     * @param max New custom threshold maximum to be set
     */
    function setCustomTokenThreshold(address token, address thresholdToken, uint256 min, uint256 max) external;
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
     * @dev The volume limit token is zero
     */
    error TaskVolumeLimitTokenZero();

    /**
     * @dev The volume limit to be set is invalid
     */
    error TaskInvalidVolumeLimitInput(address token, uint256 amount, uint256 period);

    /**
     * @dev The volume limit has been exceeded
     */
    error TaskVolumeLimitExceeded(address token, uint256 limit, uint256 volume);

    /**
     * @dev Emitted every time a default volume limit is set
     */
    event DefaultVolumeLimitSet(address indexed limitToken, uint256 amount, uint256 period);

    /**
     * @dev Emitted every time a custom volume limit is set
     */
    event CustomVolumeLimitSet(address indexed token, address indexed limitToken, uint256 amount, uint256 period);

    /**
     * @dev Tells the default volume limit set
     */
    function defaultVolumeLimit()
        external
        view
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime);

    /**
     * @dev Tells the custom volume limit set for a specific token
     * @param token Address of the token being queried
     */
    function customVolumeLimit(address token)
        external
        view
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime);

    /**
     * @dev Tells the volume limit that should be used for a token
     * @param token Address of the token being queried
     */
    function getVolumeLimit(address token)
        external
        view
        returns (address limitToken, uint256 amount, uint256 accrued, uint256 period, uint256 nextResetTime);

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

import './IBaseBridgeTask.sol';

/**
 * @dev Axelar bridger task interface
 */
interface IAxelarBridger is IBaseBridgeTask {
    /**
     * @dev Execute Axelar bridger task
     */
    function call(address token, uint256 amountIn) external;
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
 * @dev Base bridge task interface
 */
interface IBaseBridgeTask is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The recipient is zero
     */
    error TaskRecipientZero();

    /**
     * @dev The connector is zero
     */
    error TaskConnectorZero();

    /**
     * @dev The next balance connector is not zero
     */
    error TaskNextConnectorNotZero(bytes32 id);

    /**
     * @dev The destination chain is not set
     */
    error TaskDestinationChainNotSet();

    /**
     * @dev The destination chain id is the same as the current chain id
     */
    error TaskBridgeCurrentChainId(uint256 destinationChain);

    /**
     * @dev The slippage to be set is greater than one
     */
    error TaskSlippageAboveOne();

    /**
     * @dev The requested slippage is greater than the maximum slippage
     */
    error TaskSlippageAboveMax(uint256 slippage, uint256 maxSlippage);

    /**
     * @dev The requested fee is greater than the maximum fee
     */
    error TaskFeeAboveMax(uint256 fee, uint256 maxFee);

    /**
     * @dev The max fee token is zero but the max fee value is not zero
     */
    error TaskInvalidMaxFee();

    /**
     * @dev Emitted every time the connector is set
     */
    event ConnectorSet(address indexed connector);

    /**
     * @dev Emitted every time the recipient is set
     */
    event RecipientSet(address indexed recipient);

    /**
     * @dev Emitted every time the default destination chain is set
     */
    event DefaultDestinationChainSet(uint256 indexed defaultDestinationChain);

    /**
     * @dev Emitted every time the default max slippage is set
     */
    event DefaultMaxSlippageSet(uint256 maxSlippage);

    /**
     * @dev Emitted every time the default max fee is set
     */
    event DefaultMaxFeeSet(address indexed maxFeeToken, uint256 amount);

    /**
     * @dev Emitted every time a custom destination chain is set for a token
     */
    event CustomDestinationChainSet(address indexed token, uint256 indexed destinationChain);

    /**
     * @dev Emitted every time a custom max slippage is set
     */
    event CustomMaxSlippageSet(address indexed token, uint256 maxSlippage);

    /**
     * @dev Emitted every time a custom max fee is set
     */
    event CustomMaxFeeSet(address indexed token, address indexed maxFeeToken, uint256 amount);

    /**
     * @dev Tells the connector tied to the task
     */
    function connector() external view returns (address);

    /**
     * @dev Tells the address of the allowed recipient
     */
    function recipient() external view returns (address);

    /**
     * @dev Tells the default destination chain
     */
    function defaultDestinationChain() external view returns (uint256);

    /**
     * @dev Tells the default max slippage
     */
    function defaultMaxSlippage() external view returns (uint256);

    /**
     * @dev Tells the default max fee
     */
    function defaultMaxFee() external view returns (address maxFeeToken, uint256 amount);

    /**
     * @dev Tells the destination chain defined for a specific token
     * @param token Address of the token being queried
     */
    function customDestinationChain(address token) external view returns (uint256);

    /**
     * @dev Tells the max slippage defined for a specific token
     * @param token Address of the token being queried
     */
    function customMaxSlippage(address token) external view returns (uint256);

    /**
     * @dev Tells the max fee defined for a specific token
     * @param token Address of the token being queried
     */
    function customMaxFee(address token) external view returns (address maxFeeToken, uint256 amount);

    /**
     * @dev Tells the destination chain that should be used for a token
     * @param token Address of the token to get the destination chain for
     */
    function getDestinationChain(address token) external view returns (uint256);

    /**
     * @dev Tells the max slippage that should be used for a token
     * @param token Address of the token to get the max slippage for
     */
    function getMaxSlippage(address token) external view returns (uint256);

    /**
     * @dev Tells the max fee that should be used for a token
     * @param token Address of the token to get the max fee for
     */
    function getMaxFee(address token) external view returns (address maxFeeToken, uint256 amount);

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external;

    /**
     * @dev Sets the recipient address
     * @param recipient Address of the new recipient to be set
     */
    function setRecipient(address recipient) external;

    /**
     * @dev Sets the default destination chain
     * @param destinationChain Default destination chain to be set
     */
    function setDefaultDestinationChain(uint256 destinationChain) external;

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external;

    /**
     * @dev Sets the default max fee
     * @param maxFeeToken Default max fee token to be set
     * @param amount Default max fee amount to be set
     */
    function setDefaultMaxFee(address maxFeeToken, uint256 amount) external;

    /**
     * @dev Sets a custom destination chain for a token
     * @param token Address of the token to set a custom destination chain for
     * @param destinationChain Destination chain to be set
     */
    function setCustomDestinationChain(address token, uint256 destinationChain) external;

    /**
     * @dev Sets a custom max slippage
     * @param token Address of the token to set a custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function setCustomMaxSlippage(address token, uint256 maxSlippage) external;

    /**
     * @dev Sets a custom max fee
     * @param token Address of the token to set a custom max fee for
     * @param maxFeeToken Max fee token to be set for the given token
     * @param amount Max fee amount to be set for the given token
     */
    function setCustomMaxFee(address token, address maxFeeToken, uint256 amount) external;
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

import './IBaseBridgeTask.sol';

/**
 * @dev Connext bridger task interface
 */
interface IConnextBridger is IBaseBridgeTask {
    /**
     * @dev Execute Connext bridger task
     */
    function call(address token, uint256 amountIn, uint256 slippage, uint256 relayerFee) external;
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

import './IBaseBridgeTask.sol';

/**
 * @dev Hop bridger task interface
 */
interface IHopBridger is IBaseBridgeTask {
    /**
     * @dev The max deadline is zero
     */
    error TaskMaxDeadlineZero();

    /**
     * @dev The Hop entrypoint is zero
     */
    error TaskMissingHopEntrypoint();

    /**
     * @dev Emitted every time the relayer is set
     */
    event RelayerSet(address indexed relayer);

    /**
     * @dev Emitted every time the max deadline is set
     */
    event MaxDeadlineSet(uint256 maxDeadline);

    /**
     * @dev Emitted every time a Hop entrypoint is set for a token
     */
    event TokenHopEntrypointSet(address indexed token, address indexed entrypoint);

    /**
     * @dev Tells the relayer address, only used when bridging from L1 to L2
     */
    function relayer() external view returns (address);

    /**
     * @dev Tells the max deadline
     */
    function maxDeadline() external view returns (uint256);

    /**
     * @dev Tells Hop entrypoint set for a token
     */
    function tokenHopEntrypoint(address token) external view returns (address entrypoint);

    /**
     * @dev Sets the relayer, only used when bridging from L1 to L2
     * @param relayer New relayer address to be set
     */
    function setRelayer(address relayer) external;

    /**
     * @dev Sets the max deadline
     * @param maxDeadline New max deadline to be set
     */
    function setMaxDeadline(uint256 maxDeadline) external;

    /**
     * @dev Sets an entrypoint for a tokens
     * @param token Token address to set a Hop entrypoint for
     * @param entrypoint Hop entrypoint address to be set for a token
     */
    function setTokenHopEntrypoint(address token, address entrypoint) external;

    /**
     * @dev Execution function
     */
    function call(address token, uint256 amountIn, uint256 slippage, uint256 fee) external;
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

import './IBaseBridgeTask.sol';

/**
 * @dev Symbiosis bridger task interface
 */
interface ISymbiosisBridger is IBaseBridgeTask {
    /**
     * @dev Execute Symbiosis bridger task
     */
    function call(address token, uint256 amount, bytes memory data) external;
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

import './IBaseBridgeTask.sol';

/**
 * @dev Wormhole bridger task interface
 */
interface IWormholeBridger is IBaseBridgeTask {
    /**
     * @dev Execute Wormhole bridger task
     */
    function call(address token, uint256 amountIn, uint256 fee) external;
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
import './base/IPausableTask.sol';
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
    IPausableTask,
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

pragma solidity ^0.8.0;

import './IBalancerPool.sol';

interface IBalancerBoostedPool is IBalancerPool {
    function getRate() external view returns (uint256);

    function getBptIndex() external view returns (uint256);
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

import './IBalancerPool.sol';

interface IBalancerLinearPool is IBalancerPool {
    function getRate() external view returns (uint256);

    function getMainToken() external view returns (address);
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

interface IBalancerPool is IERC20 {
    function getPoolId() external view returns (bytes32);
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

import '../../ITask.sol';

/**
 * @dev Balancer V2 pool exit task interface
 */
interface IBalancerV2PoolExiter is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The connector is zero
     */
    error TaskConnectorZero();

    /**
     * @dev The slippage to be set is greater than one
     */
    error TaskSlippageAboveOne();

    /**
     * @dev The requested slippage is greater than the maximum slippage
     */
    error TaskSlippageAboveMax(uint256 slippage, uint256 maxSlippage);

    /**
     * @dev Emitted every time the connector is set
     */
    event ConnectorSet(address indexed connector);

    /**
     * @dev Emitted every time the default max slippage is set
     */
    event DefaultMaxSlippageSet(uint256 maxSlippage);

    /**
     * @dev Emitted every time a custom max slippage is set
     */
    event CustomMaxSlippageSet(address indexed token, uint256 maxSlippage);

    /**
     * @dev Tells the connector tied to the task
     */
    function connector() external view returns (address);

    /**
     * @dev Tells the default token threshold
     */
    function defaultMaxSlippage() external view returns (uint256);

    /**
     * @dev Tells the max slippage defined for a specific token
     * @param token Address of the token being queried
     */
    function customMaxSlippage(address token) external view returns (uint256);

    /**
     * @dev Tells the max slippage that should be used for a token
     */
    function getMaxSlippage(address token) external view returns (uint256);

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external;

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external;

    /**
     * @dev Sets a custom max slippage
     * @param token Address of the token to set a custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function setCustomMaxSlippage(address token, uint256 maxSlippage) external;

    /**
     * @dev Execute Balancer v2 pool exiter
     * @param tokenIn Address of the Balancer pool token to exit
     * @param amountIn Amount of Balancer pool tokens to exit
     * @param slippage Slippage to be applied
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage) external;
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

interface IBalancerVault {
    function getPool(bytes32 poolId) external view returns (address, uint256);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    struct JoinPoolRequest {
        IERC20[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;

    struct ExitPoolRequest {
        IERC20[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        payable
        returns (uint256);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
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

import '../../ITask.sol';

/**
 * @dev Base Convex task interface
 */
interface IBaseConvexTask is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The connector is zero
     */
    error TaskConnectorZero();

    /**
     * @dev Emitted every time the connector is set
     */
    event ConnectorSet(address indexed connector);

    /**
     * @dev Tells the connector tied to the task
     */
    function connector() external view returns (address);

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external;
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

import './IBaseConvexTask.sol';

/**
 * @dev Convex claimer task interface
 */
interface IConvexClaimer is IBaseConvexTask {
    /**
     * @dev The amount is not zero
     */
    error TaskAmountNotZero();

    /**
     * @dev The previous balance connector is not zero
     */
    error TaskPreviousConnectorNotZero(bytes32 id);

    /**
     * @dev The length of the claim result mismatch
     */
    error TaskClaimResultLengthMismatch();

    /**
     * @dev Executes the Convex claimer task
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

pragma solidity >=0.8.0;

import './IBaseConvexTask.sol';

/**
 * @dev Convex exiter task interface
 */
interface IConvexExiter is IBaseConvexTask {
    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev Executes the Convex exiter task
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

pragma solidity >=0.8.0;

import './IBaseConvexTask.sol';

/**
 * @dev Convex joiner task interface
 */
interface IConvexJoiner is IBaseConvexTask {
    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev Executes the Convex joiner task
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

pragma solidity >=0.8.0;

import '../../ITask.sol';

/**
 * @dev Base Curve task interface
 */
interface IBaseCurveTask is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The connector is zero
     */
    error TaskConnectorZero();

    /**
     * @dev The token out is not set
     */
    error TaskTokenOutNotSet();

    /**
     * @dev The slippage to be set is greater than one
     */
    error TaskSlippageAboveOne();

    /**
     * @dev The requested slippage is greater than the maximum slippage
     */
    error TaskSlippageAboveMax(uint256 slippage, uint256 maxSlippage);

    /**
     * @dev Emitted every time the connector is set
     */
    event ConnectorSet(address indexed connector);

    /**
     * @dev Emitted every time the default token out is set
     */
    event DefaultTokenOutSet(address indexed tokenOut);

    /**
     * @dev Emitted every time the default max slippage is set
     */
    event DefaultMaxSlippageSet(uint256 maxSlippage);

    /**
     * @dev Emitted every time a custom token out is set
     */
    event CustomTokenOutSet(address indexed token, address tokenOut);

    /**
     * @dev Emitted every time a custom max slippage is set
     */
    event CustomMaxSlippageSet(address indexed token, uint256 maxSlippage);

    /**
     * @dev Tells the connector tied to the task
     */
    function connector() external view returns (address);

    /**
     * @dev Tells the default token out
     */
    function defaultTokenOut() external view returns (address);

    /**
     * @dev Tells the default token threshold
     */
    function defaultMaxSlippage() external view returns (uint256);

    /**
     * @dev Tells the token out defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenOut(address token) external view returns (address);

    /**
     * @dev Tells the max slippage defined for a specific token
     * @param token Address of the token being queried
     */
    function customMaxSlippage(address token) external view returns (uint256);

    /**
     * @dev Tells the token out that should be used for a token
     */
    function getTokenOut(address token) external view returns (address);

    /**
     * @dev Tells the max slippage that should be used for a token
     */
    function getMaxSlippage(address token) external view returns (uint256);

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external;

    /**
     * @dev Sets the default token out
     * @param tokenOut Address of the default token out to be set
     */
    function setDefaultTokenOut(address tokenOut) external;

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external;

    /**
     * @dev Sets a custom token out
     * @param token Address of the token to set a custom token out for
     * @param tokenOut Address of the token out to be set
     */
    function setCustomTokenOut(address token, address tokenOut) external;

    /**
     * @dev Sets a custom max slippage
     * @param token Address of the token to set a custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function setCustomMaxSlippage(address token, uint256 maxSlippage) external;
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

import './IBaseCurveTask.sol';

/**
 * @dev Curve 2CRV exiter task interface
 */
interface ICurve2CrvExiter is IBaseCurveTask {
    /**
     * @dev Executes the Curve 2CRV exiter task
     */
    function call(address token, uint256 amount, uint256 slippage) external;
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

import './IBaseCurveTask.sol';

/**
 * @dev Curve 2CRV joiner task interface
 */
interface ICurve2CrvJoiner is IBaseCurveTask {
    /**
     * @dev Executes the Curve 2CRV joiner task
     */
    function call(address token, uint256 amount, uint256 slippage) external;
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

import '../../ITask.sol';

/**
 * @dev Base ERC4626 task interface
 */
interface IBaseERC4626Task is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The connector is zero
     */
    error TaskConnectorZero();

    /**
     * @dev Emitted every time the connector is set
     */
    event ConnectorSet(address indexed connector);

    /**
     * @dev Tells the connector tied to the task
     */
    function connector() external view returns (address);

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external;
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

import './IBaseERC4626Task.sol';

/**
 * @dev ERC4626 exiter task interface
 */
interface IERC4626Exiter is IBaseERC4626Task {
    /**
     * @dev Executes the ERC4626 exiter task
     */
    function call(address erc4626, uint256 amount, uint256 minAmountOut) external;
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

import './IBaseERC4626Task.sol';

/**
 * @dev ERC4626 joiner task interface
 */
interface IERC4626Joiner is IBaseERC4626Task {
    /**
     * The ERC4626 reference is zero
     */
    error TaskERC4626Zero();

    /**
     * @dev Executes the ERC4626 joiner task
     */
    function call(address token, uint256 amount, address erc4626, uint256 minAmountOut) external;
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
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The tokens source is zero
     */
    error TaskTokensSourceZero();

    /**
     * @dev The previous balance connector is not zero
     */
    error TaskPreviousConnectorNotZero(bytes32 id);

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
     * @dev Executes the collector task
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

pragma solidity >=0.8.0;

import '../ITask.sol';

/**
 * @dev Depositor task interface
 */
interface IDepositor is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The msg value is zero
     */
    error TaskValueZero();

    /**
     * @dev The previous balance connector is not zero
     */
    error TaskPreviousConnectorNotZero(bytes32 id);

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

pragma solidity >=0.8.0;

import '../ITask.sol';

/**
 * @dev Hand over task interface
 */
interface IHandleOver is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The tokens source is zero
     */
    error TaskConnectorZero(bytes32 id);

    /**
     * @dev Executes the hand over task
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

pragma solidity >=0.8.0;

import '../ITask.sol';

/**
 * @dev Unwrapper task interface
 */
interface IUnwrapper is ITask {
    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The token is not the wrapped native token
     */
    error TaskTokenNotWrapped();

    /**
     * @dev Executes the unwrapper task
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

pragma solidity >=0.8.0;

import '../ITask.sol';

/**
 * @dev Withdrawer task interface
 */
interface IWithdrawer is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The recipient is zero
     */
    error TaskRecipientZero();

    /**
     * @dev The recipient to be set is the smart vault
     */
    error TaskRecipientEqualsSmartVault(address recipient);

    /**
     * @dev The next balance connector is not zero
     */
    error TaskNextConnectorNotZero(bytes32 id);

    /**
     * @dev Emitted every time the recipient is set
     */
    event RecipientSet(address indexed recipient);

    /**
     * @dev Tells the address of the allowed recipient
     */
    function recipient() external view returns (address);

    /**
     * @dev Sets the recipient address
     * @param recipient Address of the new recipient to be set
     */
    function setRecipient(address recipient) external;

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

pragma solidity >=0.8.0;

import '../ITask.sol';

/**
 * @dev Wrapper task interface
 */
interface IWrapper is ITask {
    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The token is not the native token
     */
    error TaskTokenNotNative();

    /**
     * @dev Executes the wrapper task
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

pragma solidity >=0.8.0;

import '../ITask.sol';

/**
 * @dev Base relayer fund task interface
 */
interface IBaseRelayerFundTask is ITask {
    /**
     * @dev The relayer is zero
     */
    error TaskRelayerZero();

    /**
     * @dev The task initializer is disabled
     */
    error TaskInitializerDisabled();

    /**
     * @dev There is no threshold set for the given token
     */
    error TaskTokenThresholdNotSet(address token);

    /**
     * @dev The deposited amount is above the minimum threshold
     */
    error TaskDepositAboveMinThreshold(uint256 balance, uint256 min);

    /**
     * @dev The new amount to be deposited does not cover the used quota
     */
    error TaskDepositBelowUsedQuota(uint256 amount, uint256 quota);

    /**
     * @dev The requested amount would result in a new balance below the minimum threshold
     */
    error TaskNewDepositBelowMinThreshold(uint256 balance, uint256 min);

    /**
     * @dev The requested amount would result in a new balance above the maximum threshold
     */
    error TaskNewDepositAboveMaxThreshold(uint256 balance, uint256 max);

    /**
     * @dev Emitted every time the relayer is set
     */
    event RelayerSet(address indexed relayer);

    /**
     * @dev Tells the relayer
     */
    function relayer() external view returns (address);

    /**
     * @dev Sets the relayer
     * @param newRelayer Address of the relayer to be set
     */
    function setRelayer(address newRelayer) external;
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
 * @dev Relayer depositor task interface
 */
interface IRelayerDepositor is ITask {
    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The relayer is zero
     */
    error TaskRelayerZero();

    /**
     * @dev Emitted every time the relayer is set
     */
    event RelayerSet(address indexed relayer);

    /**
     * @dev Tells the relayer
     */
    function relayer() external view returns (address);

    /**
     * @dev Sets the relayer
     * @param newRelayer Address of the relayer to be set
     */
    function setRelayer(address newRelayer) external;

    /**
     * @dev Executes the relayer depositor task
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

pragma solidity >=0.8.0;

import './IBaseSwapTask.sol';

/**
 * @dev Balancer v2 BPT swapper task interface
 */
interface IBalancerV2BptSwapper is IBaseSwapTask {
    /**
     * @dev Execution function
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage) external;
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

import './IBaseSwapTask.sol';

/**
 * @dev Balancer v2 swapper task interface
 */
interface IBalancerV2Swapper is IBaseSwapTask {
    /**
     * @dev The pool id for the token is not set
     */
    error TaskMissingPoolId();

    /**
     * @dev Emitted every time a pool is set for a token
     */
    event BalancerPoolIdSet(address indexed token, bytes32 poolId);

    /**
     * @dev Execution function
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage) external;
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
 * @dev Base swap task interface
 */
interface IBaseSwapTask is ITask {
    /**
     * @dev The token is zero
     */
    error TaskTokenZero();

    /**
     * @dev The amount is zero
     */
    error TaskAmountZero();

    /**
     * @dev The connector is zero
     */
    error TaskConnectorZero();

    /**
     * @dev The token out is not set
     */
    error TaskTokenOutNotSet();

    /**
     * @dev The slippage to be set is greater than one
     */
    error TaskSlippageAboveOne();

    /**
     * @dev The slippage is greater than the maximum slippage
     */
    error TaskSlippageAboveMax(uint256 slippage, uint256 maxSlippage);

    /**
     * @dev Emitted every time the connector is set
     */
    event ConnectorSet(address indexed connector);

    /**
     * @dev Emitted every time the default token out is set
     */
    event DefaultTokenOutSet(address indexed tokenOut);

    /**
     * @dev Emitted every time the default max slippage is set
     */
    event DefaultMaxSlippageSet(uint256 maxSlippage);

    /**
     * @dev Emitted every time a custom token out is set
     */
    event CustomTokenOutSet(address indexed token, address tokenOut);

    /**
     * @dev Emitted every time a custom max slippage is set
     */
    event CustomMaxSlippageSet(address indexed token, uint256 maxSlippage);

    /**
     * @dev Tells the connector tied to the task
     */
    function connector() external view returns (address);

    /**
     * @dev Tells the default token out
     */
    function defaultTokenOut() external view returns (address);

    /**
     * @dev Tells the default max slippage
     */
    function defaultMaxSlippage() external view returns (uint256);

    /**
     * @dev Tells the token out defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenOut(address token) external view returns (address);

    /**
     * @dev Tells the max slippage defined for a specific token
     * @param token Address of the token being queried
     */
    function customMaxSlippage(address token) external view returns (uint256);

    /**
     * @dev Tells the token out that should be used for a token
     */
    function getTokenOut(address token) external view returns (address);

    /**
     * @dev Tells the max slippage that should be used for a token
     */
    function getMaxSlippage(address token) external view returns (uint256);

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external;

    /**
     * @dev Sets the default token out
     * @param tokenOut Address of the default token out to be set
     */
    function setDefaultTokenOut(address tokenOut) external;

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external;

    /**
     * @dev Sets a custom token out
     * @param token Address of the token to set a custom token out for
     * @param tokenOut Address of the token out to be set
     */
    function setCustomTokenOut(address token, address tokenOut) external;

    /**
     * @dev Sets a custom max slippage
     * @param token Address of the token to set a custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function setCustomMaxSlippage(address token, uint256 maxSlippage) external;
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

import './IBaseSwapTask.sol';

/**
 * @dev Bebop swapper interface
 */
interface IBebopSwapper is IBaseSwapTask {
    /**
     * @dev Execution function
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, bytes memory data) external;
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

import './IBaseSwapTask.sol';

/**
 * @dev L2 Hop swapper task interface
 */
interface IHopL2Swapper is IBaseSwapTask {
    /**
     * @dev The amm for the token is not set
     */
    error TaskMissingHopTokenAmm();

    /**
     * @dev The hToken to be set is not the hToken of the Hop L2 amm to be used
     */
    error TaskHopTokenAmmMismatch(address hToken, address amm);

    /**
     * @dev Emitted every time an AMM is set for a token
     */
    event TokenAmmSet(address indexed token, address amm);

    /**
     * @dev Tells AMM set for a token
     */
    function tokenAmm(address token) external view returns (address);

    /**
     * @dev Sets an AMM for a hToken
     * @param hToken Address of the hToken to be set
     * @param amm AMM address to be set for the hToken
     */
    function setTokenAmm(address hToken, address amm) external;

    /**
     * @dev Executes the L2 hop swapper task
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage) external;
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

import './IBaseSwapTask.sol';

/**
 * @dev 1inch v5 swapper task interface
 */
interface IOneInchV5Swapper is IBaseSwapTask {
    /**
     * @dev Execution function
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, bytes memory data) external;
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

import './IBaseSwapTask.sol';

/**
 * @dev Paraswap v5 swapper task interface
 */
interface IParaswapV5Swapper is IBaseSwapTask {
    /**
     * @dev Executes Paraswap V5 swapper task
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, bytes memory data) external;
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

import './IBaseSwapTask.sol';

/**
 * @dev Uniswap v2 swapper task interface
 */
interface IUniswapV2Swapper is IBaseSwapTask {
    /**
     * @dev Execution function
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, address[] memory hopTokens) external;
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

import './IBaseSwapTask.sol';

/**
 * @dev Uniswap v3 swapper task interface
 */
interface IUniswapV3Swapper is IBaseSwapTask {
    /**
     * @dev Execution function
     */
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) external;
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/balancer/IBalancerV2Vault.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/balancer/IBalancerV2PoolConnector.sol';

import '../../Task.sol';
import '../../interfaces/liquidity/balancer/IBalancerPool.sol';
import '../../interfaces/liquidity/balancer/IBalancerV2PoolExiter.sol';

/**
 * @title Balancer v2 pool exiter
 * @dev Task that offers the components to exit Balancer pools
 */
contract BalancerV2PoolExiter is IBalancerV2PoolExiter, Task {
    using FixedPoint for uint256;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('BALANCER_V2_POOL_EXITER');

    // Task connector address
    address public override connector;

    // Default maximum slippage in fixed point
    uint256 public override defaultMaxSlippage;

    // Maximum slippage per token address
    mapping (address => uint256) public override customMaxSlippage;

    /**
     * @dev Custom max slippage config. Only used in the initializer.
     */
    struct CustomMaxSlippage {
        address token;
        uint256 maxSlippage;
    }

    /**
     * @dev Balancer pool exit config. Only used in the initializer.
     */
    struct BalancerPoolExitConfig {
        address connector;
        uint256 maxSlippage;
        CustomMaxSlippage[] customMaxSlippages;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes a Balancer v2 pool exiter
     * @param config Balancer pool exit config
     */
    function initialize(BalancerPoolExitConfig memory config) external virtual initializer {
        __BalancerV2PoolExiter_init(config);
    }

    /**
     * @dev Initializes the Balancer v2 pool exiter. It does call upper contracts initializers.
     * @param config Balancer pool exit config
     */
    function __BalancerV2PoolExiter_init(BalancerPoolExitConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __BalancerV2PoolExiter_init_unchained(config);
    }

    /**
     * @dev Initializes the Balancer v2 pool exiter. It does not call upper contracts initializers.
     * @param config Balancer pool exit config
     */
    function __BalancerV2PoolExiter_init_unchained(BalancerPoolExitConfig memory config) internal onlyInitializing {
        _setConnector(config.connector);
        _setDefaultMaxSlippage(config.maxSlippage);
        for (uint256 i = 0; i < config.customMaxSlippages.length; i++) {
            _setCustomMaxSlippage(config.customMaxSlippages[i].token, config.customMaxSlippages[i].maxSlippage);
        }
    }

    /**
     * @dev Tells the max slippage that should be used for a token
     */
    function getMaxSlippage(address token) public view virtual override returns (uint256) {
        uint256 maxSlippage = customMaxSlippage[token];
        return maxSlippage == 0 ? defaultMaxSlippage : maxSlippage;
    }

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external override authP(authParams(newConnector)) {
        _setConnector(newConnector);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external override authP(authParams(maxSlippage)) {
        _setDefaultMaxSlippage(maxSlippage);
    }

    /**
     * @dev Sets a custom max slippage
     * @param token Address of the token to set a custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function setCustomMaxSlippage(address token, uint256 maxSlippage)
        external
        override
        authP(authParams(token, maxSlippage))
    {
        _setCustomMaxSlippage(token, maxSlippage);
    }

    /**
     * @dev Execute Balancer v2 pool exiter
     * @param tokenIn Address of the Balancer pool token to exit
     * @param amountIn Amount of Balancer pool tokens to exit
     * @param slippage Slippage to be applied
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage)
        external
        override
        authP(authParams(tokenIn, amountIn, slippage))
    {
        if (amountIn == 0) amountIn = getTaskAmount(tokenIn);
        _beforeBalancerV2PoolExiter(tokenIn, amountIn, slippage);

        (address[] memory tokensOut, uint256[] memory minAmountsOut) = _getTokensOut(tokenIn, amountIn, slippage);
        bytes memory connectorData = abi.encodeWithSelector(
            IBalancerV2PoolConnector.exit.selector,
            tokenIn,
            amountIn,
            tokensOut,
            minAmountsOut
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        uint256[] memory amountsOut = abi.decode(result, (uint256[]));
        _afterBalancerV2PoolExiter(tokenIn, amountIn, tokensOut, amountsOut);
    }

    /**
     * @dev Tells the list of tokens and min amounts out based on a number of BPTs to exit
     * @param tokenIn Address of the pool being exited
     * @param amountIn Amount of tokens to exit the pool with
     * @param slippage Slippage to be used
     */
    function _getTokensOut(address tokenIn, uint256 amountIn, uint256 slippage)
        internal
        view
        returns (address[] memory tokensOut, uint256[] memory minAmountsOut)
    {
        uint256 bptTotalSupply = IERC20(tokenIn).totalSupply();
        uint256 bptRatio = amountIn.divDown(bptTotalSupply);

        bytes32 poolId = IBalancerPool(tokenIn).getPoolId();
        address balancerV2Vault = IBalancerV2PoolConnector(connector).balancerV2Vault();
        (IERC20[] memory tokens, uint256[] memory balances, ) = IBalancerV2Vault(balancerV2Vault).getPoolTokens(poolId);

        tokensOut = new address[](tokens.length);
        minAmountsOut = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            tokensOut[i] = address(tokens[i]);
            uint256 expectedAmountsOut = balances[i].mulDown(bptRatio);
            minAmountsOut[i] = expectedAmountsOut.mulDown(FixedPoint.ONE - slippage);
        }
    }

    /**
     * @dev Before Balancer v2 pool exiter hook
     */
    function _beforeBalancerV2PoolExiter(address tokenIn, uint256 amountIn, uint256 slippage) internal virtual {
        _beforeTask(tokenIn, amountIn);
        if (tokenIn == address(0)) revert TaskTokenZero();
        if (amountIn == 0) revert TaskAmountZero();

        uint256 maxSlippage = getMaxSlippage(tokenIn);
        if (slippage > maxSlippage) revert TaskSlippageAboveMax(slippage, maxSlippage);
    }

    /**
     * @dev After Balancer v2 pool exiter hook
     */
    function _afterBalancerV2PoolExiter(
        address tokenIn,
        uint256 amountIn,
        address[] memory tokensOut,
        uint256[] memory amountsOut
    ) internal virtual {
        for (uint256 i = 0; i < tokensOut.length; i++) _increaseBalanceConnector(tokensOut[i], amountsOut[i]);
        _afterTask(tokenIn, amountIn);
    }

    /**
     * @dev Sets the task connector
     * @param newConnector New connector to be set
     */
    function _setConnector(address newConnector) internal {
        if (newConnector == address(0)) revert TaskConnectorZero();
        connector = newConnector;
        emit ConnectorSet(newConnector);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function _setDefaultMaxSlippage(uint256 maxSlippage) internal {
        if (maxSlippage > FixedPoint.ONE) revert TaskSlippageAboveOne();
        defaultMaxSlippage = maxSlippage;
        emit DefaultMaxSlippageSet(maxSlippage);
    }

    /**
     * @dev Sets a custom max slippage for a token
     * @param token Address of the token to set the custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function _setCustomMaxSlippage(address token, uint256 maxSlippage) internal {
        if (token == address(0)) revert TaskTokenZero();
        if (maxSlippage > FixedPoint.ONE) revert TaskSlippageAboveOne();
        customMaxSlippage[token] = maxSlippage;
        emit CustomMaxSlippageSet(token, maxSlippage);
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

import '../../Task.sol';
import '../../interfaces/liquidity/convex/IBaseConvexTask.sol';

/**
 * @title Base Convex task
 * @dev Task that offers the basic components for more detailed Convex related tasks
 */
abstract contract BaseConvexTask is IBaseConvexTask, Task {
    // Task connector address
    address public override connector;

    /**
     * @dev Base Convex config. Only used in the initializer.
     */
    struct BaseConvexConfig {
        address connector;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the base Convex task. It does call upper contracts initializers.
     * @param config Base Convex config
     */
    function __BaseConvexTask_init(BaseConvexConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __BaseConvexTask_init_unchained(config);
    }

    /**
     * @dev Initializes the base Convex task. It does not call upper contracts initializers.
     * @param config Base Convex config
     */
    function __BaseConvexTask_init_unchained(BaseConvexConfig memory config) internal onlyInitializing {
        _setConnector(config.connector);
    }

    /**
     * @dev Sets the task connector
     * @param newConnector Address of the new connector to be set
     */
    function setConnector(address newConnector) external override authP(authParams(newConnector)) {
        _setConnector(newConnector);
    }

    /**
     * @dev Before base Convex task hook
     */
    function _beforeBaseConvexTask(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
    }

    /**
     * @dev After base Convex task hook
     */
    function _afterBaseConvexTask(address token, uint256 amount) internal virtual {
        _afterTask(token, amount);
    }

    /**
     * @dev Sets the task connector
     * @param newConnector New connector to be set
     */
    function _setConnector(address newConnector) internal {
        if (newConnector == address(0)) revert TaskConnectorZero();
        connector = newConnector;
        emit ConnectorSet(newConnector);
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

import '@mimic-fi/v3-connectors/contracts/interfaces/convex/IConvexConnector.sol';

import './BaseConvexTask.sol';
import '../../interfaces/liquidity/convex/IConvexClaimer.sol';

/**
 * @title Convex claimer
 */
contract ConvexClaimer is IConvexClaimer, BaseConvexTask {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('CONVEX_CLAIMER');

    /**
     * @dev Convex claim config. Only used in the initializer.
     */
    struct ConvexClaimConfig {
        BaseConvexConfig baseConvexConfig;
    }

    /**
     * @dev Initializes a Convex claimer
     * @param config Convex claim config
     */
    function initialize(ConvexClaimConfig memory config) external virtual initializer {
        __ConvexClaimer_init(config);
    }

    /**
     * @dev Initializes the Convex claimer. It does call upper contracts initializers.
     * @param config Convex claim config
     */
    function __ConvexClaimer_init(ConvexClaimConfig memory config) internal onlyInitializing {
        __BaseConvexTask_init(config.baseConvexConfig);
        __ConvexClaimer_init_unchained(config);
    }

    /**
     * @dev Initializes the Convex claimer. It does not call upper contracts initializers.
     * @param config Convex claim config
     */
    function __ConvexClaimer_init_unchained(ConvexClaimConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells the address from where the token amounts to execute this task are fetched
     */
    function getTokensSource() external view virtual override(IBaseTask, BaseTask) returns (address) {
        return IConvexConnector(connector).booster();
    }

    /**
     * @dev Tells the amount a task should use for a token, in this case always zero since it is not possible to
     * compute on-chain how many tokens are available to be claimed.
     */
    function getTaskAmount(address) public pure virtual override(IBaseTask, BaseTask) returns (uint256) {
        return 0;
    }

    /**
     * @dev Execute Convex claimer
     * @param token Address of the Convex pool token to claim rewards for
     * @param amount Must be zero, it is not possible to claim a specific number of tokens
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeConvexClaimer(token, amount);
        bytes memory connectorData = abi.encodeWithSelector(IConvexConnector.claim.selector, token);
        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        (address[] memory tokens, uint256[] memory amounts) = abi.decode(result, (address[], uint256[]));
        _afterConvexClaimer(token, amount, tokens, amounts);
    }

    /**
     * @dev Before Convex claimer hook
     */
    function _beforeConvexClaimer(address token, uint256 amount) internal virtual {
        _beforeBaseConvexTask(token, amount);
        if (amount != 0) revert TaskAmountNotZero();
    }

    /**
     * @dev After Convex claimer hook
     */
    function _afterConvexClaimer(
        address tokenIn,
        uint256 amountIn,
        address[] memory tokensOut,
        uint256[] memory amountsOut
    ) internal virtual {
        if (tokensOut.length != amountsOut.length) revert TaskClaimResultLengthMismatch();
        for (uint256 i = 0; i < tokensOut.length; i++) _increaseBalanceConnector(tokensOut[i], amountsOut[i]);
        _afterBaseConvexTask(tokenIn, amountIn);
    }

    /**
     * @dev Sets the balance connectors. Previous balance connector must be unset.
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal virtual override {
        if (previous != bytes32(0)) revert TaskPreviousConnectorNotZero(previous);
        super._setBalanceConnectors(previous, next);
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

import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/convex/IConvexConnector.sol';

import './BaseConvexTask.sol';
import '../../interfaces/liquidity/convex/IConvexExiter.sol';

/**
 * @title Convex exiter
 * @dev Task that extends the base Convex task to exit Convex pools
 */
contract ConvexExiter is IConvexExiter, BaseConvexTask {
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('CONVEX_EXITER');

    /**
     * @dev Convex exit config. Only used in the initializer.
     */
    struct ConvexExitConfig {
        BaseConvexConfig baseConvexConfig;
    }

    /**
     * @dev Initializes a Convex exiter
     * @param config Convex exit config
     */
    function initialize(ConvexExitConfig memory config) external virtual initializer {
        __ConvexExiter_init(config);
    }

    /**
     * @dev Initializes the Convex exiter. It does call upper contracts initializers.
     * @param config Convex exit config
     */
    function __ConvexExiter_init(ConvexExitConfig memory config) internal onlyInitializing {
        __BaseConvexTask_init(config.baseConvexConfig);
        __ConvexExiter_init_unchained(config);
    }

    /**
     * @dev Initializes the Convex exiter. It does not call upper contracts initializers.
     * @param config Convex exit config
     */
    function __ConvexExiter_init_unchained(ConvexExitConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the Convex exiter task
     * @param token Address of the Convex pool token to be exited with
     * @param amount Amount of Convex pool tokens to be exited with
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeConvexExiter(token, amount);
        bytes memory connectorData = abi.encodeWithSelector(IConvexConnector.exit.selector, token, amount);
        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterConvexExiter(token, amount, IConvexConnector(connector).getCurvePool(token), result.toUint256());
    }

    /**
     * @dev Before Convex exiter hook
     */
    function _beforeConvexExiter(address token, uint256 amount) internal virtual {
        _beforeBaseConvexTask(token, amount);
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After Convex exiter hook
     */
    function _afterConvexExiter(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut)
        internal
        virtual
    {
        _increaseBalanceConnector(tokenOut, amountOut);
        _afterBaseConvexTask(tokenIn, amountIn);
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

import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/convex/IConvexConnector.sol';

import './BaseConvexTask.sol';
import '../../interfaces/liquidity/convex/IConvexJoiner.sol';

/**
 * @title Convex joiner
 * @dev Task that extends the base Convex task to join Convex pools
 */
contract ConvexJoiner is IConvexJoiner, BaseConvexTask {
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('CONVEX_JOINER');

    /**
     * @dev Convex join config. Only used in the initializer.
     */
    struct ConvexJoinConfig {
        BaseConvexConfig baseConvexConfig;
    }

    /**
     * @dev Initializes a Convex joiner
     * @param config Convex join config
     */
    function initialize(ConvexJoinConfig memory config) external virtual initializer {
        __ConvexJoiner_init(config);
    }

    /**
     * @dev Initializes the Convex joiner. It does call upper contracts initializers.
     * @param config Convex join config
     */
    function __ConvexJoiner_init(ConvexJoinConfig memory config) internal onlyInitializing {
        __BaseConvexTask_init(config.baseConvexConfig);
        __ConvexJoiner_init_unchained(config);
    }

    /**
     * @dev Initializes the Convex joiner. It does not call upper contracts initializers.
     * @param config Convex join config
     */
    function __ConvexJoiner_init_unchained(ConvexJoinConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the Convex joiner task
     * @param token Address of the Curve pool token to be joined with
     * @param amount Amount of Curve pool tokens to be joined with
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeConvexJoiner(token, amount);
        bytes memory connectorData = abi.encodeWithSelector(IConvexConnector.join.selector, token, amount);
        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterConvexJoiner(token, amount, IConvexConnector(connector).getCvxPool(token), result.toUint256());
    }

    /**
     * @dev Before Convex joiner hook
     */
    function _beforeConvexJoiner(address token, uint256 amount) internal virtual {
        _beforeBaseConvexTask(token, amount);
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After Convex joiner hook
     */
    function _afterConvexJoiner(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut)
        internal
        virtual
    {
        _increaseBalanceConnector(tokenOut, amountOut);
        _afterBaseConvexTask(tokenIn, amountIn);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import '../../Task.sol';
import '../../interfaces/liquidity/curve/IBaseCurveTask.sol';

/**
 * @title Base Curve task
 * @dev Task that offers the basic components for more detailed Curve related tasks
 */
abstract contract BaseCurveTask is IBaseCurveTask, Task {
    using FixedPoint for uint256;

    // Task connector address
    address public override connector;

    // Default token out
    address public override defaultTokenOut;

    // Default maximum slippage in fixed point
    uint256 public override defaultMaxSlippage;

    // Token out per token
    mapping (address => address) public override customTokenOut;

    // Maximum slippage per token address
    mapping (address => uint256) public override customMaxSlippage;

    /**
     * @dev Custom token out config. Only used in the initializer.
     */
    struct CustomTokenOut {
        address token;
        address tokenOut;
    }

    /**
     * @dev Custom max slippage config. Only used in the initializer.
     */
    struct CustomMaxSlippage {
        address token;
        uint256 maxSlippage;
    }

    /**
     * @dev Base Curve config. Only used in the initializer.
     */
    struct BaseCurveConfig {
        address connector;
        address tokenOut;
        uint256 maxSlippage;
        CustomTokenOut[] customTokensOut;
        CustomMaxSlippage[] customMaxSlippages;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the base Curve task. It does call upper contracts initializers.
     * @param config Base Curve config
     */
    function __BaseCurveTask_init(BaseCurveConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __BaseCurveTask_init_unchained(config);
    }

    /**
     * @dev Initializes the base Curve task. It does not call upper contracts initializers.
     * @param config Base Curve config
     */
    function __BaseCurveTask_init_unchained(BaseCurveConfig memory config) internal onlyInitializing {
        _setConnector(config.connector);
        _setDefaultTokenOut(config.tokenOut);
        _setDefaultMaxSlippage(config.maxSlippage);
        for (uint256 i = 0; i < config.customTokensOut.length; i++) {
            _setCustomTokenOut(config.customTokensOut[i].token, config.customTokensOut[i].tokenOut);
        }
        for (uint256 i = 0; i < config.customMaxSlippages.length; i++) {
            _setCustomMaxSlippage(config.customMaxSlippages[i].token, config.customMaxSlippages[i].maxSlippage);
        }
    }

    /**
     * @dev Tells the token out that should be used for a token
     */
    function getTokenOut(address token) public view virtual override returns (address) {
        address tokenOut = customTokenOut[token];
        return tokenOut == address(0) ? defaultTokenOut : tokenOut;
    }

    /**
     * @dev Tells the max slippage that should be used for a token
     */
    function getMaxSlippage(address token) public view virtual override returns (uint256) {
        uint256 maxSlippage = customMaxSlippage[token];
        return maxSlippage == 0 ? defaultMaxSlippage : maxSlippage;
    }

    /**
     * @dev Sets the task connector
     * @param newConnector Address of the new connector to be set
     */
    function setConnector(address newConnector) external override authP(authParams(newConnector)) {
        _setConnector(newConnector);
    }

    /**
     * @dev Sets the default token out
     * @param tokenOut Address of the default token out to be set
     */
    function setDefaultTokenOut(address tokenOut) external override authP(authParams(tokenOut)) {
        _setDefaultTokenOut(tokenOut);
    }

    /**
     * @dev Sets the default max slippage
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external override authP(authParams(maxSlippage)) {
        _setDefaultMaxSlippage(maxSlippage);
    }

    /**
     * @dev Sets a custom token out
     * @param token Address of the token to set a custom token out for
     * @param tokenOut Address of the token out to be set
     */
    function setCustomTokenOut(address token, address tokenOut) external override authP(authParams(token, tokenOut)) {
        _setCustomTokenOut(token, tokenOut);
    }

    /**
     * @dev Sets a a custom max slippage
     * @param token Address of the token to set a max slippage for
     * @param maxSlippage Max slippage to be set for the given token
     */
    function setCustomMaxSlippage(address token, uint256 maxSlippage)
        external
        override
        authP(authParams(token, maxSlippage))
    {
        _setCustomMaxSlippage(token, maxSlippage);
    }

    /**
     * @dev Before base Curve task hook
     */
    function _beforeBaseCurveTask(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
        if (getTokenOut(token) == address(0)) revert TaskTokenOutNotSet();

        uint256 maxSlippage = getMaxSlippage(token);
        if (slippage > maxSlippage) revert TaskSlippageAboveMax(slippage, maxSlippage);
    }

    /**
     * @dev After base Curve task hook
     */
    function _afterBaseCurveTask(address tokenIn, uint256 amountIn, uint256, address tokenOut, uint256 amountOut)
        internal
        virtual
    {
        _increaseBalanceConnector(tokenOut, amountOut);
        _afterTask(tokenIn, amountIn);
    }

    /**
     * @dev Sets the task connector
     * @param newConnector New connector to be set
     */
    function _setConnector(address newConnector) internal {
        if (newConnector == address(0)) revert TaskConnectorZero();
        connector = newConnector;
        emit ConnectorSet(newConnector);
    }

    /**
     * @dev Sets the default token out
     * @param tokenOut Default token out to be set
     */
    function _setDefaultTokenOut(address tokenOut) internal {
        defaultTokenOut = tokenOut;
        emit DefaultTokenOutSet(tokenOut);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function _setDefaultMaxSlippage(uint256 maxSlippage) internal {
        if (maxSlippage > FixedPoint.ONE) revert TaskSlippageAboveOne();
        defaultMaxSlippage = maxSlippage;
        emit DefaultMaxSlippageSet(maxSlippage);
    }

    /**
     * @dev Sets a custom token out for a token
     * @param token Address of the token to set the custom token out for
     * @param tokenOut Address of the token out to be set
     */
    function _setCustomTokenOut(address token, address tokenOut) internal {
        if (token == address(0)) revert TaskTokenZero();
        customTokenOut[token] = tokenOut;
        emit CustomTokenOutSet(token, tokenOut);
    }

    /**
     * @dev Sets a custom max slippage for a token
     * @param token Address of the token to set the custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function _setCustomMaxSlippage(address token, uint256 maxSlippage) internal {
        if (token == address(0)) revert TaskTokenZero();
        if (maxSlippage > FixedPoint.ONE) revert TaskSlippageAboveOne();
        customMaxSlippage[token] = maxSlippage;
        emit CustomMaxSlippageSet(token, maxSlippage);
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

import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/curve/ICurve2CrvConnector.sol';

import './BaseCurveTask.sol';
import '../../interfaces/liquidity/curve/ICurve2CrvExiter.sol';

/**
 * @title Curve 2CRV exiter
 * @dev Task that extends the base Curve task to exit 2CRV pools
 */
contract Curve2CrvExiter is ICurve2CrvExiter, BaseCurveTask {
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('CURVE_2CRV_EXITER');

    /**
     * @dev Curve 2CRV exit config. Only used in the initializer.
     */
    struct Curve2CrvExitConfig {
        BaseCurveConfig baseCurveConfig;
    }

    /**
     * @dev Initializes a Curve 2CRV exiter
     * @param config Curve 2CRV exit config
     */
    function initialize(Curve2CrvExitConfig memory config) external virtual initializer {
        __Curve2CrvExiter_init(config);
    }

    /**
     * @dev Initializes the Curve 2CRV exiter. It does call upper contracts initializers.
     * @param config Curve 2CRV exit config
     */
    function __Curve2CrvExiter_init(Curve2CrvExitConfig memory config) internal onlyInitializing {
        __BaseCurveTask_init(config.baseCurveConfig);
        __Curve2CrvExiter_init_unchained(config);
    }

    /**
     * @dev Initializes the Curve 2CRV exiter. It does not call upper contracts initializers.
     * @param config Curve 2CRV exit config
     */
    function __Curve2CrvExiter_init_unchained(Curve2CrvExitConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Curve 2CRV exiter
     * @param token Address of the Curve pool token to exit
     * @param amount Amount of Curve pool tokens to exit
     */
    function call(address token, uint256 amount, uint256 slippage)
        external
        override
        authP(authParams(token, amount, slippage))
    {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeCurve2CrvExiter(token, amount, slippage);

        address tokenOut = getTokenOut(token);
        bytes memory connectorData = abi.encodeWithSelector(
            ICurve2CrvConnector.exit.selector,
            token,
            amount,
            tokenOut,
            slippage
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterCurve2CrvExiter(token, amount, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Curve 2CRV exiter hook
     */
    function _beforeCurve2CrvExiter(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseCurveTask(token, amount, slippage);
    }

    /**
     * @dev After Curve 2CRV exiter hook
     */
    function _afterCurve2CrvExiter(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseCurveTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
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

import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/curve/ICurve2CrvConnector.sol';

import './BaseCurveTask.sol';
import '../../interfaces/liquidity/curve/ICurve2CrvJoiner.sol';

/**
 * @title Curve 2CRV joiner
 * @dev Task that extends the base Curve task to join 2CRV pools
 */
contract Curve2CrvJoiner is ICurve2CrvJoiner, BaseCurveTask {
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('CURVE_2CRV_JOINER');

    /**
     * @dev Curve 2CRV join config. Only used in the initializer.
     */
    struct Curve2CrvJoinConfig {
        BaseCurveConfig baseCurveConfig;
    }

    /**
     * @dev Initializes a Curve 2CRV joiner
     * @param config Curve 2CRV join config
     */
    function initialize(Curve2CrvJoinConfig memory config) external virtual initializer {
        __Curve2CrvJoiner_init(config);
    }

    /**
     * @dev Initializes the Curve 2CRV joiner. It does call upper contracts initializers.
     * @param config Curve 2CRV join config
     */
    function __Curve2CrvJoiner_init(Curve2CrvJoinConfig memory config) internal onlyInitializing {
        __BaseCurveTask_init(config.baseCurveConfig);
        __Curve2CrvJoiner_init_unchained(config);
    }

    /**
     * @dev Initializes the Curve 2CRV joiner. It does not call upper contracts initializers.
     * @param config Curve 2CRV join config
     */
    function __Curve2CrvJoiner_init_unchained(Curve2CrvJoinConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Curve 2CRV joiner
     * @param token Address of the token to join the Curve pool with
     * @param amount Amount of tokens to join the Curve pool with
     */
    function call(address token, uint256 amount, uint256 slippage)
        external
        override
        authP(authParams(token, amount, slippage))
    {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeCurve2CrvJoiner(token, amount, slippage);

        address tokenOut = getTokenOut(token);
        bytes memory connectorData = abi.encodeWithSelector(
            ICurve2CrvConnector.join.selector,
            tokenOut,
            token,
            amount,
            slippage
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterCurve2CrvJoiner(token, amount, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Curve 2CRV joiner hook
     */
    function _beforeCurve2CrvJoiner(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseCurveTask(token, amount, slippage);
    }

    /**
     * @dev After Curve 2CRV joiner hook
     */
    function _afterCurve2CrvJoiner(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseCurveTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
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

import '../../Task.sol';
import '../../interfaces/liquidity/erc4626/IBaseERC4626Task.sol';

/**
 * @title Base ERC4626 task
 * @dev Task that offers the basic components for more detailed ERC4626 related tasks
 */
abstract contract BaseERC4626Task is IBaseERC4626Task, Task {
    // Task connector address
    address public override connector;

    /**
     * @dev Base ERC4626 config. Only used in the initializer.
     */
    struct BaseERC4626Config {
        address connector;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the base ERC4626 task. It does call upper contracts initializers.
     * @param config Base ERC4626 config
     */
    function __BaseERC4626Task_init(BaseERC4626Config memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __BaseERC4626Task_init_unchained(config);
    }

    /**
     * @dev Initializes the base ERC4626 task. It does not call upper contracts initializers.
     * @param config Base ERC4626 config
     */
    function __BaseERC4626Task_init_unchained(BaseERC4626Config memory config) internal onlyInitializing {
        _setConnector(config.connector);
    }

    /**
     * @dev Sets the task connector
     * @param newConnector Address of the new connector to be set
     */
    function setConnector(address newConnector) external override authP(authParams(newConnector)) {
        _setConnector(newConnector);
    }

    /**
     * @dev Before base ERC4626 task hook
     */
    function _beforeBaseERC4626Task(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After base ERC4626 task hook
     */
    function _afterBaseERC4626Task(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut)
        internal
        virtual
    {
        _increaseBalanceConnector(tokenOut, amountOut);
        _afterTask(tokenIn, amountIn);
    }

    /**
     * @dev Sets the task connector
     * @param newConnector New connector to be set
     */
    function _setConnector(address newConnector) internal {
        if (newConnector == address(0)) revert TaskConnectorZero();
        connector = newConnector;
        emit ConnectorSet(newConnector);
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

import '@mimic-fi/v3-connectors/contracts/interfaces/erc4626/IERC4626Connector.sol';

import './BaseERC4626Task.sol';
import '../../interfaces/liquidity/erc4626/IERC4626Exiter.sol';

/**
 * @title ERC4626 exiter
 * @dev Task that extends the base ERC4626 task to exit an ERC4626 vault
 */
contract ERC4626Exiter is IERC4626Exiter, BaseERC4626Task {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('ERC4626_EXITER');

    /**
     * @dev ERC4626 exit config. Only used in the initializer.
     */
    struct ERC4626ExitConfig {
        BaseERC4626Config baseERC4626Config;
    }

    /**
     * @dev Initializes a ERC4626 exiter
     * @param config ERC4626 exit config
     */
    function initialize(ERC4626ExitConfig memory config) external virtual initializer {
        __ERC4626Exiter_init(config);
    }

    /**
     * @dev Initializes the ERC4626 exiter. It does call upper contracts initializers.
     * @param config ERC4626 exit config
     */
    function __ERC4626Exiter_init(ERC4626ExitConfig memory config) internal onlyInitializing {
        __BaseERC4626Task_init(config.baseERC4626Config);
        __ERC4626Exiter_init_unchained(config);
    }

    /**
     * @dev Initializes the ERC4626 exiter. It does not call upper contracts initializers.
     * @param config ERC4626 exit config
     */
    function __ERC4626Exiter_init_unchained(ERC4626ExitConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the ERC4626 exiter task. Note that the ERC4626 is also the token.
     * @param erc4626 Address of the ERC4626 to be exited
     * @param amount Amount of shares to be exited with
     * @param minAmountOut Minimum amount of assets willing to receive
     */
    function call(address erc4626, uint256 amount, uint256 minAmountOut)
        external
        override
        authP(authParams(erc4626, amount, minAmountOut))
    {
        if (amount == 0) amount = getTaskAmount(erc4626);
        _beforeERC4626Exiter(erc4626, amount);
        bytes memory connectorData = abi.encodeWithSelector(
            IERC4626Connector.exit.selector,
            erc4626,
            amount,
            minAmountOut
        );
        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        (address tokenOut, uint256 amountOut) = abi.decode(result, (address, uint256));
        _afterERC4626Exiter(erc4626, amount, tokenOut, amountOut);
    }

    /**
     * @dev Before ERC4626 exiter hook
     */
    function _beforeERC4626Exiter(address token, uint256 amount) internal virtual {
        _beforeBaseERC4626Task(token, amount);
    }

    /**
     * @dev After ERC4626 exiter hook
     */
    function _afterERC4626Exiter(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut)
        internal
        virtual
    {
        _afterBaseERC4626Task(tokenIn, amountIn, tokenOut, amountOut);
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

import '@mimic-fi/v3-connectors/contracts/interfaces/erc4626/IERC4626Connector.sol';

import './BaseERC4626Task.sol';
import '../../interfaces/liquidity/erc4626/IERC4626Joiner.sol';

/**
 * @title ERC4626 joiner
 * @dev Task that extends the base ERC4626 task to join an ERC4626 vault
 */
contract ERC4626Joiner is IERC4626Joiner, BaseERC4626Task {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('ERC4626_JOINER');

    /**
     * @dev ERC4626 join config. Only used in the initializer.
     */
    struct ERC4626JoinConfig {
        BaseERC4626Config baseERC4626Config;
    }

    /**
     * @dev Initializes a ERC4626 joiner
     * @param config ERC4626 join config
     */
    function initialize(ERC4626JoinConfig memory config) external virtual initializer {
        __ERC4626Joiner_init(config);
    }

    /**
     * @dev Initializes the ERC4626 joiner. It does call upper contracts initializers.
     * @param config ERC4626 join config
     */
    function __ERC4626Joiner_init(ERC4626JoinConfig memory config) internal onlyInitializing {
        __BaseERC4626Task_init(config.baseERC4626Config);
        __ERC4626Joiner_init_unchained(config);
    }

    /**
     * @dev Initializes the ERC4626 joiner. It does not call upper contracts initializers.
     * @param config ERC4626 join config
     */
    function __ERC4626Joiner_init_unchained(ERC4626JoinConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the ERC4626 joiner task
     * @param token Address of the token to be joined with
     * @param amount Amount of assets to be joined with
     * @param erc4626 Address of the ERC4626 to be joined
     * @param minAmountOut Minimum amount of shares willing to receive
     */
    function call(address token, uint256 amount, address erc4626, uint256 minAmountOut)
        external
        override
        authP(authParams(token, amount, erc4626, minAmountOut))
    {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeERC4626Joiner(token, amount, erc4626);
        bytes memory connectorData = abi.encodeWithSelector(
            IERC4626Connector.join.selector,
            erc4626,
            token,
            amount,
            minAmountOut
        );
        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        (address tokenOut, uint256 amountOut) = abi.decode(result, (address, uint256));
        _afterERC4626Joiner(token, amount, tokenOut, amountOut);
    }

    /**
     * @dev Before ERC4626 joiner hook
     */
    function _beforeERC4626Joiner(address token, uint256 amount, address erc4626) internal virtual {
        _beforeBaseERC4626Task(token, amount);
        if (erc4626 == address(0)) revert TaskERC4626Zero();
    }

    /**
     * @dev After ERC4626 joiner hook
     */
    function _afterERC4626Joiner(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut)
        internal
        virtual
    {
        _afterBaseERC4626Task(tokenIn, amountIn, tokenOut, amountOut);
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

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

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
    function getTokensSource() public view virtual override(IBaseTask, BaseTask) returns (address) {
        return _tokensSource;
    }

    /**
     * @dev Tells the balance of the depositor for a given token
     * @param token Address of the token being queried
     */
    function getTaskAmount(address token) public view virtual override(IBaseTask, BaseTask) returns (uint256) {
        return ERC20Helpers.balanceOf(token, getTokensSource());
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
        if (amount == 0) amount = getTaskAmount(token);
        _beforeCollector(token, amount);
        ISmartVault(smartVault).collect(token, _tokensSource, amount);
        _afterCollector(token, amount);
    }

    /**
     * @dev Before collector hook
     */
    function _beforeCollector(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
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
        if (previous != bytes32(0)) revert TaskPreviousConnectorNotZero(previous);
        super._setBalanceConnectors(previous, next);
    }

    /**
     * @dev Sets the source address
     * @param tokensSource Address of the tokens source to be set
     */
    function _setTokensSource(address tokensSource) internal virtual {
        if (tokensSource == address(0)) revert TaskTokensSourceZero();
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

import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';
import '@mimic-fi/v3-helpers/contracts/utils/Denominations.sol';

import '../Task.sol';
import '../interfaces/primitives/IDepositor.sol';

/**
 * @title Depositor
 * @dev Task that can be used as the origin to start any workflow
 */
contract Depositor is IDepositor, Task {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('DEPOSITOR');

    /**
     * @dev Deposit config. Only used in the initializer.
     */
    struct DepositConfig {
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the depositor
     * @param config Deposit config
     */
    function initialize(DepositConfig memory config) external virtual initializer {
        __Depositor_init(config);
    }

    /**
     * @dev Initializes the depositor. It does call upper contracts initializers.
     * @param config Deposit config
     */
    function __Depositor_init(DepositConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __Depositor_init_unchained(config);
    }

    /**
     * @dev Initializes the depositor. It does not call upper contracts initializers.
     * @param config Deposit config
     */
    function __Depositor_init_unchained(DepositConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells the address from where the token amounts to execute this task are fetched
     */
    function getTokensSource() public view virtual override(IBaseTask, BaseTask) returns (address) {
        return address(this);
    }

    /**
     * @dev Tells the balance of the depositor for a given token
     * @param token Address of the token being queried
     */
    function getTaskAmount(address token) public view virtual override(IBaseTask, BaseTask) returns (uint256) {
        return ERC20Helpers.balanceOf(token, getTokensSource());
    }

    /**
     * @dev It allows receiving native token transfers
     */
    receive() external payable {
        if (msg.value == 0) revert TaskValueZero();
    }

    /**
     * @dev Execute Depositor
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeDepositor(token, amount);

        if (Denominations.isNativeToken(token)) {
            Address.sendValue(payable(smartVault), amount);
        } else {
            ERC20Helpers.approve(token, smartVault, amount);
            ISmartVault(smartVault).collect(token, getTokensSource(), amount);
        }

        _afterDepositor(token, amount);
    }

    /**
     * @dev Before depositor hook
     */
    function _beforeDepositor(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After depositor hook
     */
    function _afterDepositor(address token, uint256 amount) internal virtual {
        _increaseBalanceConnector(token, amount);
        _afterTask(token, amount);
    }

    /**
     * @dev Sets the balance connectors. Previous balance connector must be unset.
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal virtual override {
        if (previous != bytes32(0)) revert TaskPreviousConnectorNotZero(previous);
        super._setBalanceConnectors(previous, next);
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

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import '../Task.sol';
import '../interfaces/primitives/IHandleOver.sol';

/**
 * @title Hand over task
 * @dev Task that simply moves tokens from one balance connector to the other
 */
contract HandleOver is IHandleOver, Task {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('HANDLE_OVER');

    /**
     * @dev Hand over config. Only used in the initializer.
     */
    struct HandleOverConfig {
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the hand over task
     * @param config Hand over config
     */
    function initialize(HandleOverConfig memory config) external virtual initializer {
        __HandleOver_init(config);
    }

    /**
     * @dev Initializes the hand over task. It does call upper contracts initializers.
     * @param config Hand over config
     */
    function __HandleOver_init(HandleOverConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __HandleOver_init_unchained(config);
    }

    /**
     * @dev Initializes the hand over task. It does not call upper contracts initializers.
     * @param config Hand over config
     */
    function __HandleOver_init_unchained(HandleOverConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute the hand over taks
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeHandleOver(token, amount);
        _afterHandleOver(token, amount);
    }

    /**
     * @dev Before hand over task hook
     */
    function _beforeHandleOver(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After hand over task hook
     */
    function _afterHandleOver(address token, uint256 amount) internal virtual {
        _increaseBalanceConnector(token, amount);
        _afterTask(token, amount);
    }

    /**
     * @dev Sets the balance connectors. Both balance connector must be set.
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal virtual override {
        if (previous == bytes32(0)) revert TaskConnectorZero(previous);
        if (next == bytes32(0)) revert TaskConnectorZero(next);
        super._setBalanceConnectors(previous, next);
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

import '../Task.sol';
import '../interfaces/primitives/IUnwrapper.sol';

/**
 * @title Unwrapper
 * @dev Task that offers facilities to unwrap wrapped native tokens
 */
contract Unwrapper is IUnwrapper, Task {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('UNWRAPPER');

    /**
     * @dev Unwrap config. Only used in the initializer.
     * @param taskConfig Task config params
     */
    struct UnwrapConfig {
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the unwrapper
     * @param config Unwrap config
     */
    function initialize(UnwrapConfig memory config) external virtual initializer {
        __Unwrapper_init(config);
    }

    /**
     * @dev Initializes the unwrapper. It does call upper contracts initializers.
     * @param config Unwrap config
     */
    function __Unwrapper_init(UnwrapConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __Unwrapper_init_unchained(config);
    }

    /**
     * @dev Initializes the unwrapper. It does not call upper contracts initializers.
     * @param config Unwrap config
     */
    function __Unwrapper_init_unchained(UnwrapConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Unwrapper
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeUnwrapper(token, amount);
        ISmartVault(smartVault).unwrap(amount);
        _afterUnwrapper(token, amount);
    }

    /**
     * @dev Before unwrapper hook
     */
    function _beforeUnwrapper(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (token != _wrappedNativeToken()) revert TaskTokenNotWrapped();
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After unwrapper hook
     */
    function _afterUnwrapper(address token, uint256 amount) internal virtual {
        _increaseBalanceConnector(Denominations.NATIVE_TOKEN, amount);
        _afterTask(token, amount);
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

import '../Task.sol';
import '../interfaces/primitives/IWithdrawer.sol';

/**
 * @title Withdrawer
 * @dev Task that offers a recipient address where funds can be withdrawn
 */
contract Withdrawer is IWithdrawer, Task {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('WITHDRAWER');

    // Address where tokens will be transferred to
    address public override recipient;

    /**
     * @dev Withdraw config. Only used in the initializer.
     */
    struct WithdrawConfig {
        address recipient;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the withdrawer
     * @param config Withdraw config
     */
    function initialize(WithdrawConfig memory config) external virtual initializer {
        __Withdrawer_init(config);
    }

    /**
     * @dev Initializes the withdrawer. It does call upper contracts initializers.
     * @param config Withdraw config
     */
    function __Withdrawer_init(WithdrawConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __Withdrawer_init_unchained(config);
    }

    /**
     * @dev Initializes the withdrawer. It does not call upper contracts initializers.
     * @param config Withdraw config
     */
    function __Withdrawer_init_unchained(WithdrawConfig memory config) internal onlyInitializing {
        _setRecipient(config.recipient);
    }

    /**
     * @dev Sets the recipient address. Sender must be authorized.
     * @param newRecipient Address of the new recipient to be set
     */
    function setRecipient(address newRecipient) external override authP(authParams(newRecipient)) {
        _setRecipient(newRecipient);
    }

    /**
     * @dev Executes the Withdrawer
     */
    function call(address token, uint256 amount) external virtual override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeWithdrawer(token, amount);
        ISmartVault(smartVault).withdraw(token, recipient, amount);
        _afterWithdrawer(token, amount);
    }

    /**
     * @dev Before withdrawer hook
     */
    function _beforeWithdrawer(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After withdrawer hook
     */
    function _afterWithdrawer(address token, uint256 amount) internal virtual {
        _afterTask(token, amount);
    }

    /**
     * @dev Sets the recipient address
     * @param newRecipient Address of the new recipient to be set
     */
    function _setRecipient(address newRecipient) internal {
        if (newRecipient == address(0)) revert TaskRecipientZero();
        if (newRecipient == smartVault) revert TaskRecipientEqualsSmartVault(newRecipient);
        recipient = newRecipient;
        emit RecipientSet(newRecipient);
    }

    /**
     * @dev Sets the balance connectors. Next balance connector must be unset.
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal virtual override {
        if (next != bytes32(0)) revert TaskNextConnectorNotZero(next);
        super._setBalanceConnectors(previous, next);
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

import '@mimic-fi/v3-helpers/contracts/utils/Denominations.sol';

import '../Task.sol';
import '../interfaces/primitives/IWrapper.sol';

/**
 * @title Wrapper
 * @dev Task that offers facilities to wrap native tokens
 */
contract Wrapper is IWrapper, Task {
    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('WRAPPER');

    /**
     * @dev Wrap config. Only used in the initializer.
     */
    struct WrapConfig {
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the wrapper
     * @param config Wrap config
     */
    function initialize(WrapConfig memory config) external virtual initializer {
        __Wrapper_init(config);
    }

    /**
     * @dev Initializes the wrapper. It does call upper contracts initializers.
     * @param config Wrap config
     */
    function __Wrapper_init(WrapConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __Wrapper_init_unchained(config);
    }

    /**
     * @dev Initializes the wrapper. It does not call upper contracts initializers.
     * @param config Wrap config
     */
    function __Wrapper_init_unchained(WrapConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Wrapper
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeWrapper(token, amount);
        ISmartVault(smartVault).wrap(amount);
        _afterWrapper(token, amount);
    }

    /**
     * @dev Before wrapper hook
     */
    function _beforeWrapper(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (token != Denominations.NATIVE_TOKEN) revert TaskTokenNotNative();
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After wrapper hook
     */
    function _afterWrapper(address token, uint256 amount) internal virtual {
        _increaseBalanceConnector(_wrappedNativeToken(), amount);
        _afterTask(token, amount);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-relayer/contracts/interfaces/IRelayer.sol';

import '../Task.sol';
import '../interfaces/relayer/IBaseRelayerFundTask.sol';

/**
 * @title Base relayer fund task
 * @dev Task that offers the basic components for more detailed relayer fund tasks
 */
abstract contract BaseRelayerFundTask is IBaseRelayerFundTask, Task {
    using FixedPoint for uint256;

    // Reference to the contract to be funded
    address public override relayer;

    /**
     * @dev Base relayer fund config. Only used in the initializer.
     */
    struct BaseRelayerFundConfig {
        address relayer;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the base relayer fund task. It does call upper contracts initializers.
     * @param config Base relayer fund config
     */
    function __BaseRelayerFundTask_init(BaseRelayerFundConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __BaseRelayerFundTask_init_unchained(config);
    }

    /**
     * @dev Initializes the base relayer fund task. It does not call upper contracts initializers.
     * @param config Base relayer fund config
     */
    function __BaseRelayerFundTask_init_unchained(BaseRelayerFundConfig memory config) internal onlyInitializing {
        _setRelayer(config.relayer);
    }

    /**
     * @dev Tells the amount in `token` to be paid to the relayer
     * @param token Address of the token to be used to pay the relayer
     */
    function getTaskAmount(address token) public view virtual override(IBaseTask, BaseTask) returns (uint256) {
        Threshold memory threshold = _getTokenThreshold(token);
        if (threshold.token == address(0)) return 0;

        uint256 depositedThresholdToken = _getDepositedInThresholdToken(threshold.token);
        if (depositedThresholdToken >= threshold.min) return 0;

        uint256 usedQuotaThresholdToken = _getUsedQuotaInThresholdToken(threshold.token);
        uint256 diff = threshold.max - depositedThresholdToken + usedQuotaThresholdToken;
        return (token == threshold.token) ? diff : diff.mulUp(_getPrice(threshold.token, token));
    }

    /**
     * @dev Sets the relayer
     * @param newRelayer Address of the relayer to be set
     */
    function setRelayer(address newRelayer) external override authP(authParams(newRelayer)) {
        _setRelayer(newRelayer);
    }

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256 amount) internal virtual override {
        Threshold memory threshold = _getTokenThreshold(token);
        if (threshold.token == address(0)) revert TaskTokenThresholdNotSet(token);

        uint256 amountInThresholdToken = amount.mulUp(_getPrice(token, threshold.token));
        uint256 depositedInThresholdToken = _getDepositedInThresholdToken(threshold.token);
        bool isCurrentBalanceAboveMin = depositedInThresholdToken >= threshold.min;
        if (isCurrentBalanceAboveMin) revert TaskDepositAboveMinThreshold(depositedInThresholdToken, threshold.min);

        uint256 usedQuotaInThresholdToken = _getUsedQuotaInThresholdToken(threshold.token);
        bool coversUsedQuota = amountInThresholdToken > usedQuotaInThresholdToken;
        if (!coversUsedQuota) revert TaskDepositBelowUsedQuota(amountInThresholdToken, usedQuotaInThresholdToken);

        uint256 balanceAfterDeposit = amountInThresholdToken + depositedInThresholdToken - usedQuotaInThresholdToken;
        bool isNewBalanceBelowMin = balanceAfterDeposit < threshold.min;
        if (isNewBalanceBelowMin) revert TaskNewDepositBelowMinThreshold(balanceAfterDeposit, threshold.min);

        bool isNewBalanceAboveMax = balanceAfterDeposit > threshold.max;
        if (isNewBalanceAboveMax) revert TaskNewDepositAboveMaxThreshold(balanceAfterDeposit, threshold.max);
    }

    /**
     * @dev Tells the deposited balance in the relayer expressed in another token
     */
    function _getDepositedInThresholdToken(address token) internal view returns (uint256) {
        // Relayer balance is expressed in ETH
        uint256 depositedNativeToken = IRelayer(relayer).getSmartVaultBalance(smartVault);
        return depositedNativeToken.mulUp(_getPrice(_wrappedNativeToken(), token));
    }

    /**
     * @dev Tells the used quota in the relayer expressed in another token
     */
    function _getUsedQuotaInThresholdToken(address token) internal view returns (uint256) {
        // Relayer used quota is expressed in ETH
        uint256 usedQuotaNativeToken = IRelayer(relayer).getSmartVaultUsedQuota(smartVault);
        return usedQuotaNativeToken.mulUp(_getPrice(_wrappedNativeToken(), token));
    }

    /**
     * @dev Sets the relayer
     * @param newRelayer Address of the relayer to be set
     */
    function _setRelayer(address newRelayer) internal {
        if (newRelayer == address(0)) revert TaskRelayerZero();
        relayer = newRelayer;
        emit RelayerSet(newRelayer);
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

import '../primitives/Collector.sol';
import './BaseRelayerFundTask.sol';

/**
 * @title Collector relayer funder
 * @dev Task used to convert funds in order to pay relayers using an collector
 */
contract CollectorRelayerFunder is BaseRelayerFundTask, Collector {
    /**
     * @dev Disables the default collector initializer
     */
    function initialize(CollectConfig memory) external pure override {
        revert TaskInitializerDisabled();
    }

    /**
     * @dev Initializes the collector relayer funder
     * @param config Collect config
     * @param relayer Relayer address
     */
    function initializeCollectorRelayerFunder(CollectConfig memory config, address relayer)
        external
        virtual
        initializer
    {
        __CollectorRelayerFunder_init(config, relayer);
    }

    /**
     * @dev Initializes the collector relayer funder. It does call upper contracts initializers.
     * @param config Collect config
     * @param relayer Relayer address
     */
    function __CollectorRelayerFunder_init(CollectConfig memory config, address relayer) internal onlyInitializing {
        __Collector_init(config);
        __BaseRelayerFundTask_init_unchained(BaseRelayerFundConfig(relayer, config.taskConfig));
        __CollectorRelayerFunder_init_unchained(config, relayer);
    }

    /**
     * @dev Initializes the collector relayer funder. It does not call upper contracts initializers.
     * @param config Collect config
     * @param relayer Relayer address
     */
    function __CollectorRelayerFunder_init_unchained(CollectConfig memory config, address relayer)
        internal
        onlyInitializing
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells the address from where the token amounts to execute this task are fetched
     */
    function getTokensSource() public view override(Collector, IBaseTask, BaseTask) returns (address) {
        return Collector.getTokensSource();
    }

    /**
     * @dev Tells the `token` amount to be funded
     * @param token Address of the token to be used to fund the relayer
     */
    function getTaskAmount(address token) public view override(BaseRelayerFundTask, Collector) returns (uint256) {
        return BaseRelayerFundTask.getTaskAmount(token);
    }

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256 amount)
        internal
        override(BaseRelayerFundTask, TokenThresholdTask)
    {
        BaseRelayerFundTask._beforeTokenThresholdTask(token, amount);
    }

    /**
     * @dev Sets the balance connectors. Previous balance connector must be unset.
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function _setBalanceConnectors(bytes32 previous, bytes32 next) internal override(Collector, BaseTask) {
        Collector._setBalanceConnectors(previous, next);
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

import './BaseRelayerFundTask.sol';
import '../swap/OneInchV5Swapper.sol';

/**
 * @title 1inch v5 relayer funder
 * @dev Task used to convert funds in order to pay relayers using a 1inch v5 swapper
 */
contract OneInchV5RelayerFunder is BaseRelayerFundTask, OneInchV5Swapper {
    /**
     * @dev Disables the default 1inch v5 swapper initializer
     */
    function initialize(OneInchV5SwapConfig memory) external pure override {
        revert TaskInitializerDisabled();
    }

    /**
     * @dev Initializes the 1inch v5 relayer funder
     * @param config 1inch v5 swap config
     * @param relayer Relayer address
     */
    function initializeOneInchV5RelayerFunder(OneInchV5SwapConfig memory config, address relayer)
        external
        virtual
        initializer
    {
        __OneInchV5RelayerFunder_init(config, relayer);
    }

    /**
     * @dev Initializes the 1inch v5 relayer funder. It does call upper contracts initializers.
     * @param config 1inch v5 swap config
     * @param relayer Relayer address
     */
    function __OneInchV5RelayerFunder_init(OneInchV5SwapConfig memory config, address relayer)
        internal
        onlyInitializing
    {
        __OneInchV5Swapper_init(config);
        __BaseRelayerFundTask_init_unchained(BaseRelayerFundConfig(relayer, config.baseSwapConfig.taskConfig));
        __OneInchV5RelayerFunder_init_unchained(config, relayer);
    }

    /**
     * @dev Initializes the 1inch v5 relayer funder. It does not call upper contracts initializers.
     * @param config Unwrap config
     * @param relayer Relayer address
     */
    function __OneInchV5RelayerFunder_init_unchained(OneInchV5SwapConfig memory config, address relayer)
        internal
        onlyInitializing
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells the amount in `token` to be funded
     * @param token Address of the token to be used for funding
     */
    function getTaskAmount(address token)
        public
        view
        override(BaseRelayerFundTask, IBaseTask, BaseTask)
        returns (uint256)
    {
        return BaseRelayerFundTask.getTaskAmount(token);
    }

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256 amount)
        internal
        override(BaseRelayerFundTask, TokenThresholdTask)
    {
        BaseRelayerFundTask._beforeTokenThresholdTask(token, amount);
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

import './BaseRelayerFundTask.sol';
import '../swap/ParaswapV5Swapper.sol';

/**
 * @title Paraswap v5 relayer funder
 * @dev Task used to convert funds in order to pay relayers using Paraswap v5 swapper
 */
contract ParaswapV5RelayerFunder is BaseRelayerFundTask, ParaswapV5Swapper {
    /**
     * @dev Disables the default Paraswap v5 swapper initializer
     */
    function initialize(ParaswapV5SwapConfig memory) external pure override {
        revert TaskInitializerDisabled();
    }

    /**
     * @dev Initializes the Paraswap v5 relayer funder
     * @param config Paraswap v5 swap config
     * @param relayer Relayer address
     */
    function initializeParaswapV5RelayerFunder(ParaswapV5SwapConfig memory config, address relayer)
        external
        virtual
        initializer
    {
        __ParaswapV5RelayerFunder_init(config, relayer);
    }

    /**
     * @dev Initializes the Paraswap v5 relayer funder. It does call upper contracts initializers.
     * @param config Paraswap v5 swap config
     * @param relayer Relayer address
     */
    function __ParaswapV5RelayerFunder_init(ParaswapV5SwapConfig memory config, address relayer)
        internal
        onlyInitializing
    {
        __ParaswapV5Swapper_init(config);
        __BaseRelayerFundTask_init_unchained(BaseRelayerFundConfig(relayer, config.baseSwapConfig.taskConfig));
        __ParaswapV5RelayerFunder_init_unchained(config, relayer);
    }

    /**
     * @dev Initializes the Paraswap v5 relayer funder. It does not call upper contracts initializers.
     * @param config Unwrap config
     * @param relayer Relayer address
     */
    function __ParaswapV5RelayerFunder_init_unchained(ParaswapV5SwapConfig memory config, address relayer)
        internal
        onlyInitializing
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells the amount in `token` to be funded
     * @param token Address of the token to be used for funding
     */
    function getTaskAmount(address token)
        public
        view
        override(BaseRelayerFundTask, IBaseTask, BaseTask)
        returns (uint256)
    {
        return BaseRelayerFundTask.getTaskAmount(token);
    }

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256 amount)
        internal
        override(BaseRelayerFundTask, TokenThresholdTask)
    {
        BaseRelayerFundTask._beforeTokenThresholdTask(token, amount);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-relayer/contracts/interfaces/IRelayer.sol';

import '../Task.sol';
import '../interfaces/relayer/IRelayerDepositor.sol';

/**
 * @title Relayer depositor
 * @dev Task that offers facilities to deposit balance for Mimic relayers
 */
contract RelayerDepositor is IRelayerDepositor, Task {
    using FixedPoint for uint256;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('RELAYER_DEPOSITOR');

    // Reference to the contract to be funded
    address public override relayer;

    /**
     * @dev Initializes the relayer depositor
     * @param config Task config
     * @param _relayer Relayer address
     */
    function initialize(TaskConfig memory config, address _relayer) external virtual initializer {
        __RelayerDepositor_init(config, _relayer);
    }

    /**
     * @dev Initializes the relayer depositor. It does call upper contracts initializers.
     * @param config Task config
     * @param _relayer Relayer address
     */
    function __RelayerDepositor_init(TaskConfig memory config, address _relayer) internal onlyInitializing {
        __Task_init(config);
        __RelayerDepositor_init_unchained(config, _relayer);
    }

    /**
     * @dev Initializes the relayer depositor. It does not call upper contracts initializers.
     * @param _relayer Relayer address
     */
    function __RelayerDepositor_init_unchained(TaskConfig memory, address _relayer) internal onlyInitializing {
        _setRelayer(_relayer);
    }

    /**
     * @dev Sets the relayer
     * @param newRelayer Address of the relayer to be set
     */
    function setRelayer(address newRelayer) external override authP(authParams(newRelayer)) {
        _setRelayer(newRelayer);
    }

    /**
     * @dev Executes the relayer depositor task
     */
    function call(address token, uint256 amount) external override authP(authParams(token, amount)) {
        if (amount == 0) amount = getTaskAmount(token);
        _beforeRelayerDepositor(token, amount);
        bytes memory relayerData = abi.encodeWithSelector(IRelayer.deposit.selector, smartVault, amount);
        // solhint-disable-next-line avoid-low-level-calls
        ISmartVault(smartVault).call(relayer, relayerData, amount);
        _afterRelayerDepositor(token, amount);
    }

    /**
     * @dev Before relayer depositor hook
     */
    function _beforeRelayerDepositor(address token, uint256 amount) internal virtual {
        _beforeTask(token, amount);
        if (amount == 0) revert TaskAmountZero();
    }

    /**
     * @dev After relayer depositor hook
     */
    function _afterRelayerDepositor(address token, uint256 amount) internal virtual {
        _afterTask(token, amount);
    }

    /**
     * @dev Sets the relayer
     * @param newRelayer Address of the relayer to be set
     */
    function _setRelayer(address newRelayer) internal {
        if (newRelayer == address(0)) revert TaskRelayerZero();
        relayer = newRelayer;
        emit RelayerSet(newRelayer);
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

import './BaseRelayerFundTask.sol';
import '../primitives/Unwrapper.sol';

/**
 * @title Unwrapper relayer funder
 * @dev Task used to convert funds in order to pay relayers using an unwrapper
 */
contract UnwrapperRelayerFunder is BaseRelayerFundTask, Unwrapper {
    /**
     * @dev Disables the default unwrapper initializer
     */
    function initialize(UnwrapConfig memory) external pure override {
        revert TaskInitializerDisabled();
    }

    /**
     * @dev Initializes the unwrapper relayer funder
     * @param config Unwrap config
     * @param relayer Relayer address
     */
    function initializeUnwrapperRelayerFunder(UnwrapConfig memory config, address relayer)
        external
        virtual
        initializer
    {
        __UnwrapperRelayerFunder_init(config, relayer);
    }

    /**
     * @dev Initializes the unwrapper relayer funder. It does call upper contracts initializers.
     * @param config Unwrap config
     * @param relayer Relayer address
     */
    function __UnwrapperRelayerFunder_init(UnwrapConfig memory config, address relayer) internal onlyInitializing {
        __Unwrapper_init(config);
        __BaseRelayerFundTask_init_unchained(BaseRelayerFundConfig(relayer, config.taskConfig));
        __UnwrapperRelayerFunder_init_unchained(config, relayer);
    }

    /**
     * @dev Initializes the unwrapper relayer funder. It does not call upper contracts initializers.
     * @param config Unwrap config
     * @param relayer Relayer address
     */
    function __UnwrapperRelayerFunder_init_unchained(UnwrapConfig memory config, address relayer)
        internal
        onlyInitializing
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells the `token` amount to be funded
     * @param token Address of the token to be used to fund the relayer
     */
    function getTaskAmount(address token)
        public
        view
        override(BaseRelayerFundTask, IBaseTask, BaseTask)
        returns (uint256)
    {
        return BaseRelayerFundTask.getTaskAmount(token);
    }

    /**
     * @dev Before token threshold task hook
     */
    function _beforeTokenThresholdTask(address token, uint256 amount)
        internal
        override(BaseRelayerFundTask, TokenThresholdTask)
    {
        BaseRelayerFundTask._beforeTokenThresholdTask(token, amount);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/balancer/IBalancerV2Vault.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/balancer/IBalancerV2SwapConnector.sol';

import './BalancerV2BptSwapper.sol';
import '../interfaces/liquidity/balancer/IBalancerBoostedPool.sol';

/**
 * @title Balancer v2 boosted swapper task
 * @dev Task that extends the Balancer v2 BPT swapper task specially for boosted pools
 */
contract BalancerV2BoostedSwapper is BalancerV2BptSwapper {
    /**
     * @dev Tells the token out that should be used for a token. In case there is no token out defined for the
     * requested token, it will use one of the underlying pool tokens.
     */
    function getTokenOut(address token) public view virtual override(IBaseSwapTask, BaseSwapTask) returns (address) {
        address tokenOut = BaseSwapTask.getTokenOut(token);
        if (tokenOut != address(0)) return tokenOut;

        bytes32 poolId = IBalancerBoostedPool(token).getPoolId();
        uint256 bptIndex = IBalancerBoostedPool(token).getBptIndex();
        address balancerV2Vault = IBalancerV2SwapConnector(connector).balancerV2Vault();
        (IERC20[] memory tokens, , ) = IBalancerV2Vault(balancerV2Vault).getPoolTokens(poolId);
        return address(bptIndex == 0 ? tokens[1] : tokens[0]);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/balancer/IBalancerV2SwapConnector.sol';

import './BaseSwapTask.sol';
import '../interfaces/swap/IBalancerV2BptSwapper.sol';
import '../interfaces/liquidity/balancer/IBalancerPool.sol';

/**
 * @title Balancer v2 BPT swapper task
 * @dev Task that extends the swapper task to use Balancer v2
 */
contract BalancerV2BptSwapper is IBalancerV2BptSwapper, BaseSwapTask {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('BALANCER_V2_BPT_SWAPPER');

    /**
     * @dev Balancer v2 BPT swap config. Only used in the initializer.
     */
    struct BalancerV2BptSwapConfig {
        BaseSwapConfig baseSwapConfig;
    }

    /**
     * @dev Initializes the Balancer v2 BPT swapper
     * @param config Balancer v2 BPT swap config
     */
    function initialize(BalancerV2BptSwapConfig memory config) external initializer {
        __BalancerV2BptSwapper_init(config);
    }

    /**
     * @dev Initializes the Balancer v2 BPT swapper. It does call upper contracts.
     * @param config Balancer v2 BPT swap config
     */
    function __BalancerV2BptSwapper_init(BalancerV2BptSwapConfig memory config) internal onlyInitializing {
        __BaseSwapTask_init(config.baseSwapConfig);
        __BalancerV2BptSwapper_init_unchained(config);
    }

    /**
     * @dev Initializes the Balancer v2 BPT swapper. It does not call upper contracts.
     * @param config Balancer v2 BPT swap config
     */
    function __BalancerV2BptSwapper_init_unchained(BalancerV2BptSwapConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the Balancer v2 BPT swapper task
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage)
        external
        override
        authP(authParams(tokenIn, amountIn, slippage))
    {
        if (amountIn == 0) amountIn = getTaskAmount(tokenIn);
        _beforeBalancerV2BptSwapper(tokenIn, amountIn, slippage);

        address tokenOut = getTokenOut(tokenIn);
        uint256 price = _getPrice(tokenIn, tokenOut);
        uint256 minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE - slippage);

        bytes memory connectorData = abi.encodeWithSelector(
            IBalancerV2SwapConnector.execute.selector,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            IBalancerPool(tokenIn).getPoolId(),
            new bytes32[](0),
            new address[](0)
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterBalancerV2BptSwapper(tokenIn, amountIn, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Balancer v2 BPT swapper task
     */
    function _beforeBalancerV2BptSwapper(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseSwapTask(token, amount, slippage);
    }

    /**
     * @dev After Balancer v2 BPT swapper hook
     */
    function _afterBalancerV2BptSwapper(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseSwapTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/balancer/IBalancerV2SwapConnector.sol';

import './BalancerV2BptSwapper.sol';
import '../interfaces/liquidity/balancer/IBalancerLinearPool.sol';

/**
 * @title Balancer v2 linear swapper task
 * @dev Task that extends the Balancer v2 BPT swapper task specially for linear pools
 */
contract BalancerV2LinearSwapper is BalancerV2BptSwapper {
    /**
     * @dev Tells the token out that should be used for a token. In case there is no token out defined for the
     * requested token, it will use the linear pool main token.
     */
    function getTokenOut(address token) public view virtual override(IBaseSwapTask, BaseSwapTask) returns (address) {
        address tokenOut = BaseSwapTask.getTokenOut(token);
        if (tokenOut != address(0)) return tokenOut;
        return IBalancerLinearPool(token).getMainToken();
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/balancer/IBalancerV2SwapConnector.sol';

import './BaseSwapTask.sol';
import '../interfaces/swap/IBalancerV2Swapper.sol';
import '../interfaces/liquidity/balancer/IBalancerPool.sol';

/**
 * @title Balancer v2 swapper task
 * @dev Task that extends the base swap task to use Balancer
 */
contract BalancerV2Swapper is IBalancerV2Swapper, BaseSwapTask {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('BALANCER_V2_SWAPPER');

    // List of pool id's per token
    mapping (address => bytes32) public balancerPoolId;

    /**
     * @dev Balancer pool id config. Only used in the initializer.
     */
    struct BalancerPoolId {
        address token;
        bytes32 poolId;
    }

    /**
     * @dev Balancer v2 swap config. Only used in the initalizer
     */
    struct BalancerV2SwapConfig {
        BalancerPoolId[] balancerPoolIds;
        BaseSwapConfig baseSwapConfig;
    }

    /**
     * @dev Initializes the Balancer v2 swapper
     * @param config Balancer v2 swap config
     */
    function initialize(BalancerV2SwapConfig memory config) external initializer {
        __BalancerV2Swapper_init(config);
    }

    /**
     * @dev Initializes the Balancer v2 swapper. It does call upper contracts.
     * @param config Balancer v2 swap config
     */
    function __BalancerV2Swapper_init(BalancerV2SwapConfig memory config) internal onlyInitializing {
        __BaseSwapTask_init(config.baseSwapConfig);
        __BalancerV2Swapper_init_unchained(config);
    }

    /**
     * @dev Initializes the Balancer swapper. It does not call upper contracts
     * @param config Balancer V2 swap config
     */
    function __BalancerV2Swapper_init_unchained(BalancerV2SwapConfig memory config) internal onlyInitializing {
        for (uint256 i = 0; i < config.balancerPoolIds.length; i++) {
            _setPoolId(config.balancerPoolIds[i].token, config.balancerPoolIds[i].poolId);
        }
    }

    /**
     * @dev Sets a Balancer pool ID for a token
     * @param token Address of the token to set the pool ID of
     * @param poolId ID of the pool to be set for the given token
     */
    function setPoolId(address token, bytes32 poolId) external authP(authParams(token, poolId)) {
        _setPoolId(token, poolId);
    }

    /**
     * @dev Executes the Balancer v2 swapper task
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage)
        external
        override
        authP(authParams(tokenIn, amountIn, slippage))
    {
        if (amountIn == 0) amountIn = getTaskAmount(tokenIn);
        _beforeBalancerV2Swapper(tokenIn, amountIn, slippage);

        address tokenOut = getTokenOut(tokenIn);
        uint256 price = _getPrice(tokenIn, tokenOut);
        uint256 minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE - slippage);
        bytes32 poolId = balancerPoolId[tokenIn];

        bytes memory connectorData = abi.encodeWithSelector(
            IBalancerV2SwapConnector.execute.selector,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            poolId,
            new bytes32[](0),
            new address[](0)
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterBalancerV2Swapper(tokenIn, amountIn, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Balancer V2 swapper hook
     */
    function _beforeBalancerV2Swapper(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseSwapTask(token, amount, slippage);
        if (balancerPoolId[token] == bytes32(0)) revert TaskMissingPoolId();
    }

    /**
     * @dev After Balancer v2 swapper hook
     */
    function _afterBalancerV2Swapper(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseSwapTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
    }

    /**
     * @dev Sets a Balancer pool ID for a token
     * @param token Address of the token to set the pool ID of
     * @param poolId ID of the pool to be set for the given token
     */
    function _setPoolId(address token, bytes32 poolId) internal {
        if (token == address(0)) revert TaskTokenZero();

        balancerPoolId[token] = poolId;
        emit BalancerPoolIdSet(token, poolId);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/Denominations.sol';

import '../Task.sol';
import '../interfaces/swap/IBaseSwapTask.sol';

/**
 * @title Base swap task
 * @dev Task that offers the basic components for more detailed swap tasks
 */
abstract contract BaseSwapTask is IBaseSwapTask, Task {
    using FixedPoint for uint256;

    // Connector address
    address public override connector;

    // Default token out
    address public override defaultTokenOut;

    // Default maximum slippage in fixed point
    uint256 public override defaultMaxSlippage;

    // Token out per token
    mapping (address => address) public override customTokenOut;

    // Maximum slippage per token address
    mapping (address => uint256) public override customMaxSlippage;

    /**
     * @dev Custom token out config. Only used in the initializer.
     */
    struct CustomTokenOut {
        address token;
        address tokenOut;
    }

    /**
     * @dev Custom max slippage config. Only used in the initializer.
     */
    struct CustomMaxSlippage {
        address token;
        uint256 maxSlippage;
    }

    /**
     * @dev Base swap config. Only used in the initializer.
     */
    struct BaseSwapConfig {
        address connector;
        address tokenOut;
        uint256 maxSlippage;
        CustomTokenOut[] customTokensOut;
        CustomMaxSlippage[] customMaxSlippages;
        TaskConfig taskConfig;
    }

    /**
     * @dev Initializes the base swap task. It does call upper contracts initializers.
     * @param config Base swap config
     */
    function __BaseSwapTask_init(BaseSwapConfig memory config) internal onlyInitializing {
        __Task_init(config.taskConfig);
        __BaseSwapTask_init_unchained(config);
    }

    /**
     * @dev Initializes the base swap task. It does not call upper contracts initializers.
     * @param config Base swap config
     */
    function __BaseSwapTask_init_unchained(BaseSwapConfig memory config) internal onlyInitializing {
        _setConnector(config.connector);
        _setDefaultTokenOut(config.tokenOut);
        _setDefaultMaxSlippage(config.maxSlippage);

        for (uint256 i = 0; i < config.customTokensOut.length; i++) {
            _setCustomTokenOut(config.customTokensOut[i].token, config.customTokensOut[i].tokenOut);
        }

        for (uint256 i = 0; i < config.customMaxSlippages.length; i++) {
            _setCustomMaxSlippage(config.customMaxSlippages[i].token, config.customMaxSlippages[i].maxSlippage);
        }
    }

    /**
     * @dev Tells the token out that should be used for a token
     */
    function getTokenOut(address token) public view virtual override returns (address) {
        address tokenOut = customTokenOut[token];
        return tokenOut == address(0) ? defaultTokenOut : tokenOut;
    }

    /**
     * @dev Tells the max slippage that should be used for a token
     */
    function getMaxSlippage(address token) public view virtual override returns (uint256) {
        uint256 maxSlippage = customMaxSlippage[token];
        return maxSlippage == 0 ? defaultMaxSlippage : maxSlippage;
    }

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function setConnector(address newConnector) external override authP(authParams(newConnector)) {
        _setConnector(newConnector);
    }

    /**
     * @dev Sets the default token out
     * @param tokenOut Address of the default token out to be set
     */
    function setDefaultTokenOut(address tokenOut) external override authP(authParams(tokenOut)) {
        _setDefaultTokenOut(tokenOut);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external override authP(authParams(maxSlippage)) {
        _setDefaultMaxSlippage(maxSlippage);
    }

    /**
     * @dev Sets a custom token out
     * @param token Address of the token to set a custom token out for
     * @param tokenOut Address of the token out to be set
     */
    function setCustomTokenOut(address token, address tokenOut) external override authP(authParams(token, tokenOut)) {
        _setCustomTokenOut(token, tokenOut);
    }

    /**
     * @dev Sets a custom max slippage
     * @param token Address of the token to set a custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function setCustomMaxSlippage(address token, uint256 maxSlippage)
        external
        override
        authP(authParams(token, maxSlippage))
    {
        _setCustomMaxSlippage(token, maxSlippage);
    }

    /**
     * @dev Before base swap task hook
     */
    function _beforeBaseSwapTask(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeTask(token, amount);
        if (token == address(0)) revert TaskTokenZero();
        if (amount == 0) revert TaskAmountZero();
        if (getTokenOut(token) == address(0)) revert TaskTokenOutNotSet();

        uint256 maxSlippage = getMaxSlippage(token);
        if (slippage > maxSlippage) revert TaskSlippageAboveMax(slippage, maxSlippage);
    }

    /**
     * @dev After base swap task hook
     */
    function _afterBaseSwapTask(address tokenIn, uint256 amountIn, uint256, address tokenOut, uint256 amountOut)
        internal
        virtual
    {
        _increaseBalanceConnector(tokenOut, amountOut);
        _afterTask(tokenIn, amountIn);
    }

    /**
     * @dev Sets a new connector
     * @param newConnector Address of the connector to be set
     */
    function _setConnector(address newConnector) internal {
        if (newConnector == address(0)) revert TaskConnectorZero();
        connector = newConnector;
        emit ConnectorSet(newConnector);
    }

    /**
     * @dev Sets the default token out
     * @param tokenOut Default token out to be set
     */
    function _setDefaultTokenOut(address tokenOut) internal {
        defaultTokenOut = tokenOut;
        emit DefaultTokenOutSet(tokenOut);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function _setDefaultMaxSlippage(uint256 maxSlippage) internal {
        if (maxSlippage > FixedPoint.ONE) revert TaskSlippageAboveOne();
        defaultMaxSlippage = maxSlippage;
        emit DefaultMaxSlippageSet(maxSlippage);
    }

    /**
     * @dev Sets a custom token out for a token
     * @param token Address of the token to set the custom token out for
     * @param tokenOut Address of the token out to be set
     */
    function _setCustomTokenOut(address token, address tokenOut) internal {
        if (token == address(0)) revert TaskTokenZero();
        customTokenOut[token] = tokenOut;
        emit CustomTokenOutSet(token, tokenOut);
    }

    /**
     * @dev Sets a custom max slippage for a token
     * @param token Address of the token to set the custom max slippage for
     * @param maxSlippage Max slippage to be set
     */
    function _setCustomMaxSlippage(address token, uint256 maxSlippage) internal {
        if (token == address(0)) revert TaskTokenZero();
        if (maxSlippage > FixedPoint.ONE) revert TaskSlippageAboveOne();
        customMaxSlippage[token] = maxSlippage;
        emit CustomMaxSlippageSet(token, maxSlippage);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/bebop/IBebopConnector.sol';

import './BaseSwapTask.sol';
import '../interfaces/swap/IBebopSwapper.sol';

/**
 * @title Bebop swapper
 * @dev Task that extends the base swap task to use Bebop
 */
contract BebopSwapper is IBebopSwapper, BaseSwapTask {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('BEBOP_SWAPPER');

    /**
     * @dev Bebop swap config. Only used in the initializer.
     */
    struct BebopSwapConfig {
        BaseSwapConfig baseSwapConfig;
    }

    /**
     * @dev Initializes the Bebop swapper
     * @param config Bebop swap config
     */
    function initialize(BebopSwapConfig memory config) external virtual initializer {
        __BebopSwapper_init(config);
    }

    /**
     * @dev Initializes the Bebop swapper. It does call upper contracts initializers.
     * @param config Bebop swap config
     */
    function __BebopSwapper_init(BebopSwapConfig memory config) internal onlyInitializing {
        __BaseSwapTask_init(config.baseSwapConfig);
        __BebopSwapper_init_unchained(config);
    }

    /**
     * @dev Initializes the Bebop swapper. It does not call upper contracts initializers.
     * @param config Bebop swap config
     */
    function __BebopSwapper_init_unchained(BebopSwapConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the Bebop swapper
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, bytes memory data)
        external
        override
        authP(authParams(tokenIn, amountIn, slippage))
    {
        if (amountIn == 0) amountIn = getTaskAmount(tokenIn);
        _beforeBebopSwapper(tokenIn, amountIn, slippage);

        address tokenOut = getTokenOut(tokenIn);
        uint256 price = _getPrice(tokenIn, tokenOut);
        uint256 minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE - slippage);
        bytes memory connectorData = abi.encodeWithSelector(
            IBebopConnector.execute.selector,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            data
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterBebopSwapper(tokenIn, amountIn, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Bebop swapper hook
     */
    function _beforeBebopSwapper(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseSwapTask(token, amount, slippage);
    }

    /**
     * @dev After Bebop swapper hook
     */
    function _afterBebopSwapper(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseSwapTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
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

import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/hop/IHopL2Amm.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/hop/IHopSwapConnector.sol';

import './BaseSwapTask.sol';
import '../interfaces/swap/IHopL2Swapper.sol';

/**
 * @title Hop L2 swapper
 * @dev Task that extends the base swap task to use Hop
 */
contract HopL2Swapper is IHopL2Swapper, BaseSwapTask {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('HOP_L2_SWAPPER');

    // List of AMMs per token
    mapping (address => address) public override tokenAmm;

    /**
     * @dev Token amm config. Only used in the initializer.
     */
    struct TokenAmm {
        address token;
        address amm;
    }

    /**
     * @dev Hop L2 swap config. Only used in the initializer.
     */
    struct HopL2SwapConfig {
        TokenAmm[] tokenAmms;
        BaseSwapConfig baseSwapConfig;
    }

    /**
     * @dev Initializes the Hop L2 swapper
     * @param config Hop L2 swap config
     */
    function initialize(HopL2SwapConfig memory config) external virtual initializer {
        __HopL2Swapper_init(config);
    }

    /**
     * @dev Initializes the Hop L2 swapper. It does call upper contracts initializers.
     * @param config Hop L2 swap config
     */
    function __HopL2Swapper_init(HopL2SwapConfig memory config) internal onlyInitializing {
        __BaseSwapTask_init(config.baseSwapConfig);
        __HopL2Swapper_init_unchained(config);
    }

    /**
     * @dev Initializes the Hop L2 swapper. It does not call upper contracts initializers.
     * @param config Hop L2 swap config
     */
    function __HopL2Swapper_init_unchained(HopL2SwapConfig memory config) internal onlyInitializing {
        for (uint256 i = 0; i < config.tokenAmms.length; i++) {
            _setTokenAmm(config.tokenAmms[i].token, config.tokenAmms[i].amm);
        }
    }

    /**
     * @dev Sets an AMM for a hToken
     * @param hToken Address of the hToken to be set
     * @param amm AMM address to be set for the hToken
     */
    function setTokenAmm(address hToken, address amm) external authP(authParams(hToken, amm)) {
        _setTokenAmm(hToken, amm);
    }

    /**
     * @dev Execution function
     */
    function call(address hToken, uint256 amount, uint256 slippage)
        external
        override
        authP(authParams(hToken, amount, slippage))
    {
        if (amount == 0) amount = getTaskAmount(hToken);
        _beforeHopL2Swapper(hToken, amount, slippage);

        address tokenOut = getTokenOut(hToken);
        address dexAddress = IHopL2Amm(tokenAmm[hToken]).exchangeAddress();
        uint256 minAmountOut = amount.mulUp(FixedPoint.ONE - slippage);
        bytes memory connectorData = abi.encodeWithSelector(
            IHopSwapConnector.execute.selector,
            hToken,
            tokenOut,
            amount,
            minAmountOut,
            dexAddress
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterHopL2Swapper(hToken, amount, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Hop L2 swapper hook
     */
    function _beforeHopL2Swapper(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseSwapTask(token, amount, slippage);
        if (tokenAmm[token] == address(0)) revert TaskMissingHopTokenAmm();
    }

    /**
     * @dev After Hop L2 swapper hook
     */
    function _afterHopL2Swapper(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseSwapTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
    }

    /**
     * @dev Set an AMM for a Hop token
     * @param hToken Address of the hToken to set an AMM for
     * @param amm AMM to be set
     */
    function _setTokenAmm(address hToken, address amm) internal {
        if (hToken == address(0)) revert TaskTokenZero();
        if (amm != address(0) && hToken != IHopL2Amm(amm).hToken()) revert TaskHopTokenAmmMismatch(hToken, amm);

        tokenAmm[hToken] = amm;
        emit TokenAmmSet(hToken, amm);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/1inch/IOneInchV5Connector.sol';

import './BaseSwapTask.sol';
import '../interfaces/swap/IOneInchV5Swapper.sol';

/**
 * @title 1inch v5 swapper
 * @dev Task that extends the base swap task to use 1inch v5
 */
contract OneInchV5Swapper is IOneInchV5Swapper, BaseSwapTask {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('1INCH_V5_SWAPPER');

    /**
     * @dev 1inch v5 swap config. Only used in the initializer.
     */
    struct OneInchV5SwapConfig {
        BaseSwapConfig baseSwapConfig;
    }

    /**
     * @dev Initializes the 1inch v5 swapper
     * @param config 1inch v5 swap config
     */
    function initialize(OneInchV5SwapConfig memory config) external virtual initializer {
        __OneInchV5Swapper_init(config);
    }

    /**
     * @dev Initializes the 1inch v5 swapper. It does call upper contracts initializers.
     * @param config 1inch v5 swap config
     */
    function __OneInchV5Swapper_init(OneInchV5SwapConfig memory config) internal onlyInitializing {
        __BaseSwapTask_init(config.baseSwapConfig);
        __OneInchV5Swapper_init_unchained(config);
    }

    /**
     * @dev Initializes the 1inch v5 swapper. It does not call upper contracts initializers.
     * @param config 1inch v5 swap config
     */
    function __OneInchV5Swapper_init_unchained(OneInchV5SwapConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the 1inch V5 swapper task
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, bytes memory data)
        external
        override
        authP(authParams(tokenIn, amountIn, slippage))
    {
        if (amountIn == 0) amountIn = getTaskAmount(tokenIn);
        _beforeOneInchV5Swapper(tokenIn, amountIn, slippage);

        address tokenOut = getTokenOut(tokenIn);
        uint256 price = _getPrice(tokenIn, tokenOut);
        uint256 minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE - slippage);
        bytes memory connectorData = abi.encodeWithSelector(
            IOneInchV5Connector.execute.selector,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            data
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterOneInchV5Swapper(tokenIn, amountIn, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before 1inch v5 swapper hook
     */
    function _beforeOneInchV5Swapper(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseSwapTask(token, amount, slippage);
    }

    /**
     * @dev After 1inch v5 swapper hook
     */
    function _afterOneInchV5Swapper(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseSwapTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/paraswap/IParaswapV5Connector.sol';

import './BaseSwapTask.sol';
import '../interfaces/swap/IParaswapV5Swapper.sol';

/**
 * @title Paraswap V5 swapper task
 * @dev Task that extends the swapper task to use Paraswap v5
 */
contract ParaswapV5Swapper is IParaswapV5Swapper, BaseSwapTask {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('PARASWAP_V5_SWAPPER');

    /**
     * @dev Paraswap v5 swap config. Only used in the initializer.
     */
    struct ParaswapV5SwapConfig {
        BaseSwapConfig baseSwapConfig;
    }

    /**
     * @dev Initializes the Paraswap v5 swapper
     * @param config Paraswap v5 swap config
     */
    function initialize(ParaswapV5SwapConfig memory config) external virtual initializer {
        __ParaswapV5Swapper_init(config);
    }

    /**
     * @dev Initializes the Paraswap v5 swapper. It does call upper contracts initializers.
     * @param config Paraswap v5 swap config
     */
    function __ParaswapV5Swapper_init(ParaswapV5SwapConfig memory config) internal onlyInitializing {
        __BaseSwapTask_init(config.baseSwapConfig);
        __ParaswapV5Swapper_init_unchained(config);
    }

    /**
     * @dev Initializes the Paraswap v5 swapper. It does not call upper contracts initializers.
     * @param config Paraswap v5 swap config
     */
    function __ParaswapV5Swapper_init_unchained(ParaswapV5SwapConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execute Paraswap v5 swapper task
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, bytes memory data)
        external
        override
        authP(authParams(tokenIn, amountIn, slippage))
    {
        if (amountIn == 0) amountIn = getTaskAmount(tokenIn);
        _beforeParaswapV5Swapper(tokenIn, amountIn, slippage);

        address tokenOut = getTokenOut(tokenIn);
        uint256 price = _getPrice(tokenIn, tokenOut);
        uint256 minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE - slippage);
        bytes memory connectorData = abi.encodeWithSelector(
            IParaswapV5Connector.execute.selector,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            data
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterParaswapV5Swapper(tokenIn, amountIn, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Paraswap v5 swapper hook
     */
    function _beforeParaswapV5Swapper(address tokenIn, uint256 amountIn, uint256 slippage) internal virtual {
        _beforeBaseSwapTask(tokenIn, amountIn, slippage);
    }

    /**
     * @dev After Paraswap v5 swapper hook
     */
    function _afterParaswapV5Swapper(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseSwapTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/uniswap/IUniswapV2Connector.sol';

import './BaseSwapTask.sol';
import '../interfaces/swap/IUniswapV2Swapper.sol';

/**
 * @title Uniswap v2 swapper
 * @dev Task that extends the base swap task to use Uniswap v2
 */
contract UniswapV2Swapper is IUniswapV2Swapper, BaseSwapTask {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('UNISWAP_V2_SWAPPER');

    /**
     * @dev Uniswap v2 swap config. Only used in the initializer.
     */
    struct UniswapV2SwapConfig {
        BaseSwapConfig baseSwapConfig;
    }

    /**
     * @dev Initializes the Uniswap v2 swapper
     * @param config Uniswap v2 swap config
     */
    function initialize(UniswapV2SwapConfig memory config) external initializer {
        __UniswapV2Swapper_init(config);
    }

    /**
     * @dev Initializes the Uniswap v2 swapper. It does call upper contracts.
     * @param config Uniswap v2 swap config
     */
    function __UniswapV2Swapper_init(UniswapV2SwapConfig memory config) internal onlyInitializing {
        __BaseSwapTask_init(config.baseSwapConfig);
        __UniswapV2Swapper_init_unchained(config);
    }

    /**
     * @dev Initializes the Uniswap v2 swapper. It does not call upper contracts.
     * @param config Uniswap v2 swap config
     */
    function __UniswapV2Swapper_init_unchained(UniswapV2SwapConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the Uniswap v2 swapper task
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, address[] memory hopTokens)
        external
        override
        authP(authParams(tokenIn, amountIn, slippage))
    {
        if (amountIn == 0) amountIn = getTaskAmount(tokenIn);
        _beforeUniswapV2Swapper(tokenIn, amountIn, slippage);

        address tokenOut = getTokenOut(tokenIn);
        uint256 price = _getPrice(tokenIn, tokenOut);
        uint256 minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE - slippage);

        bytes memory connectorData = abi.encodeWithSelector(
            IUniswapV2Connector.execute.selector,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            hopTokens
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterUniswapV2Swapper(tokenIn, amountIn, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Uniswap v2 swapper hook
     */
    function _beforeUniswapV2Swapper(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseSwapTask(token, amount, slippage);
    }

    /**
     * @dev After Uniswap v2 swapper hook
     */
    function _afterUniswapV2Swapper(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseSwapTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
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

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-connectors/contracts/interfaces/uniswap/IUniswapV3Connector.sol';

import './BaseSwapTask.sol';
import '../interfaces/swap/IUniswapV3Swapper.sol';

/**
 * @title Uniswap v3 swapper task
 * @dev Task that extends the swapper task to use Uniswap v3
 */
contract UniswapV3Swapper is IUniswapV3Swapper, BaseSwapTask {
    using FixedPoint for uint256;
    using BytesHelpers for bytes;

    // Execution type for relayers
    bytes32 public constant override EXECUTION_TYPE = keccak256('UNISWAP_V3_SWAPPER');

    /**
     * @dev Uniswap v3 swap config. Only used in the initializer.
     */
    struct UniswapV3SwapConfig {
        BaseSwapConfig baseSwapConfig;
    }

    /**
     * @dev Initializes the Uniswap v3 swapper
     * @param config Uniswap v3 swap config
     */
    function initialize(UniswapV3SwapConfig memory config) external initializer {
        __UniswapV3Swapper_init(config);
    }

    /**
     * @dev Initializes the Uniswap V3 swapper. It does call upper contracts.
     * @param config Uniswap v3 swap config
     */
    function __UniswapV3Swapper_init(UniswapV3SwapConfig memory config) internal onlyInitializing {
        __BaseSwapTask_init(config.baseSwapConfig);
        __UniswapV3Swapper_init_unchained(config);
    }

    /**
     * @dev Initializes the Uniswap V3 swapper. It does not call upper contracts.
     * @param config Uniswap v3 swap config
     */
    function __UniswapV3Swapper_init_unchained(UniswapV3SwapConfig memory config) internal onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes the Uniswap v3 swapper task
     */
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) external override authP(authParams(tokenIn, amountIn, slippage, fee)) {
        if (amountIn == 0) amountIn = getTaskAmount(tokenIn);
        _beforeUniswapV3Swapper(tokenIn, amountIn, slippage);

        address tokenOut = getTokenOut(tokenIn);
        uint256 price = _getPrice(tokenIn, tokenOut);
        uint256 minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE - slippage);

        bytes memory connectorData = abi.encodeWithSelector(
            IUniswapV3Connector.execute.selector,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            fee,
            hopTokens,
            hopFees
        );

        bytes memory result = ISmartVault(smartVault).execute(connector, connectorData);
        _afterUniswapV3Swapper(tokenIn, amountIn, slippage, tokenOut, result.toUint256());
    }

    /**
     * @dev Before Uniswap v3 swapper task
     */
    function _beforeUniswapV3Swapper(address token, uint256 amount, uint256 slippage) internal virtual {
        _beforeBaseSwapTask(token, amount, slippage);
    }

    /**
     * @dev After Uniswap v3 swapper hook
     */
    function _afterUniswapV3Swapper(
        address tokenIn,
        uint256 amountIn,
        uint256 slippage,
        address tokenOut,
        uint256 amountOut
    ) internal virtual {
        _afterBaseSwapTask(tokenIn, amountIn, slippage, tokenOut, amountOut);
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

pragma solidity ^0.8.0;

import '../../base/BaseTask.sol';

contract BaseTaskMock is BaseTask {
    bytes32 public constant override EXECUTION_TYPE = keccak256('BASE_TASK');

    function initialize(BaseConfig memory config) external virtual initializer {
        __BaseTask_init(config);
    }

    function call(address token, uint256 amount) external {
        _beforeBaseTask(token, amount);
        _afterBaseTask(token, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../base/BaseTask.sol';
import '../../base/GasLimitedTask.sol';

contract GasLimitedTaskMock is BaseTask, GasLimitedTask {
    bytes32 public constant override EXECUTION_TYPE = keccak256('GAS_LIMITED_TASK');

    struct GasLimitMockConfig {
        BaseConfig baseConfig;
        GasLimitConfig gasLimitConfig;
    }

    function initialize(GasLimitMockConfig memory config) external virtual initializer {
        __BaseTask_init(config.baseConfig);
        __GasLimitedTask_init(config.gasLimitConfig);
    }

    function call(address token, uint256 amount) external {
        _beforeGasLimitedTaskMock(token, amount);
        _afterGasLimitedTaskMock(token, amount);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote) internal view override(BaseTask, GasLimitedTask) returns (uint256) {
        return BaseTask._getPrice(base, quote);
    }

    /**
     * @dev Before gas limited task mock hook
     */
    function _beforeGasLimitedTaskMock(address token, uint256 amount) internal virtual {
        _beforeBaseTask(token, amount);
        _beforeGasLimitedTask(token, amount);
    }

    /**
     * @dev After gas limited task mock hook
     */
    function _afterGasLimitedTaskMock(address token, uint256 amount) internal virtual {
        _afterGasLimitedTask(token, amount);
        _afterBaseTask(token, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../base/BaseTask.sol';
import '../../base/PausableTask.sol';

contract PausableTaskMock is BaseTask, PausableTask {
    bytes32 public constant override EXECUTION_TYPE = keccak256('PAUSABLE_TASK');

    struct PauseMockConfig {
        BaseConfig baseConfig;
    }

    function initialize(PauseMockConfig memory config) external virtual initializer {
        __BaseTask_init(config.baseConfig);
        __PausableTask_init();
    }

    function call(address token, uint256 amount) external {
        if (amount == 0) amount = getTaskAmount(token);
        _beforePausableTaskMock(token, amount);
        _afterPausableTaskMock(token, amount);
    }

    /**
     * @dev Before pausable task mock hook
     */
    function _beforePausableTaskMock(address token, uint256 amount) internal virtual {
        _beforeBaseTask(token, amount);
        _beforePausableTask(token, amount);
    }

    /**
     * @dev After pausable task mock hook
     */
    function _afterPausableTaskMock(address token, uint256 amount) internal virtual {
        _afterPausableTask(token, amount);
        _afterBaseTask(token, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../base/BaseTask.sol';
import '../../base/TimeLockedTask.sol';

contract TimeLockedTaskMock is BaseTask, TimeLockedTask {
    bytes32 public constant override EXECUTION_TYPE = keccak256('TIME_LOCKED_TASK');

    struct TimeLockMockConfig {
        BaseConfig baseConfig;
        TimeLockConfig timeLockConfig;
    }

    function initialize(TimeLockMockConfig memory config) external virtual initializer {
        __BaseTask_init(config.baseConfig);
        __TimeLockedTask_init(config.timeLockConfig);
    }

    function call() external {
        _beforeTimeLockedTaskMock();
        _afterTimeLockedTaskMock();
    }

    /**
     * @dev Before time locked task mock hook
     */
    function _beforeTimeLockedTaskMock() internal virtual {
        _beforeBaseTask(address(0), 0);
        _beforeTimeLockedTask(address(0), 0);
    }

    /**
     * @dev After time locked task mock hook
     */
    function _afterTimeLockedTaskMock() internal virtual {
        _afterTimeLockedTask(address(0), 0);
        _afterBaseTask(address(0), 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../base/BaseTask.sol';
import '../../base/TokenIndexedTask.sol';

contract TokenIndexedTaskMock is BaseTask, TokenIndexedTask {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant override EXECUTION_TYPE = keccak256('TOKEN_INDEXED_TASK');

    struct TokenIndexMockConfig {
        BaseConfig baseConfig;
        TokenIndexConfig tokenIndexConfig;
    }

    function initialize(TokenIndexMockConfig memory config) external virtual initializer {
        __BaseTask_init(config.baseConfig);
        __TokenIndexedTask_init(config.tokenIndexConfig);
    }

    function call(address token) external {
        _beforeTokenIndexedTaskMock(token);
        _afterTokenIndexedTaskMock(token);
    }

    /**
     * @dev Before token indexed task mock hook
     */
    function _beforeTokenIndexedTaskMock(address token) internal virtual {
        _beforeBaseTask(token, 0);
        _beforeTokenIndexedTask(token, 0);
    }

    /**
     * @dev After token indexed task mock hook
     */
    function _afterTokenIndexedTaskMock(address token) internal virtual {
        _afterTokenIndexedTask(token, 0);
        _afterBaseTask(token, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../base/BaseTask.sol';
import '../../base/TokenThresholdTask.sol';

contract TokenThresholdTaskMock is BaseTask, TokenThresholdTask {
    bytes32 public constant override EXECUTION_TYPE = keccak256('TOKEN_THRESHOLD_TASK');

    struct TokenThresholdMockConfig {
        BaseConfig baseConfig;
        TokenThresholdConfig tokenThresholdConfig;
    }

    function initialize(TokenThresholdMockConfig memory config) external virtual initializer {
        __BaseTask_init(config.baseConfig);
        __TokenThresholdTask_init(config.tokenThresholdConfig);
    }

    function call(address token, uint256 amount) external {
        _beforeTokenThresholdTask(token, amount);
        _afterTokenThresholdTask(token, amount);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote)
        internal
        view
        override(BaseTask, TokenThresholdTask)
        returns (uint256)
    {
        return BaseTask._getPrice(base, quote);
    }

    /**
     * @dev Before token threshold task mock hook
     */
    function _beforeTokenThresholdTaskMock(address token, uint256 amount) internal virtual {
        _beforeBaseTask(token, amount);
        _beforeTokenThresholdTask(token, amount);
    }

    /**
     * @dev After token threshold task mock hook
     */
    function _afterTokenThresholdTaskMock(address token, uint256 amount) internal virtual {
        _afterTokenThresholdTask(token, amount);
        _afterBaseTask(token, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../base/BaseTask.sol';
import '../../base/VolumeLimitedTask.sol';

contract VolumeLimitedTaskMock is BaseTask, VolumeLimitedTask {
    bytes32 public constant override EXECUTION_TYPE = keccak256('VOLUME_LIMITED_TASK');

    struct VolumeLimitMockConfig {
        BaseConfig baseConfig;
        VolumeLimitConfig volumeLimitConfig;
    }

    function initialize(VolumeLimitMockConfig memory config) external virtual initializer {
        __BaseTask_init(config.baseConfig);
        __VolumeLimitedTask_init(config.volumeLimitConfig);
    }

    function call(address token, uint256 amount) external {
        _beforeVolumeLimitedTaskMock(token, amount);
        _afterVolumeLimitedTaskMock(token, amount);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote)
        internal
        view
        override(BaseTask, VolumeLimitedTask)
        returns (uint256)
    {
        return BaseTask._getPrice(base, quote);
    }

    /**
     * @dev Before volume limited task mock hook
     */
    function _beforeVolumeLimitedTaskMock(address token, uint256 amount) internal virtual {
        _beforeBaseTask(token, amount);
        _beforeVolumeLimitedTask(token, amount);
    }

    /**
     * @dev After volume limited task mock hook
     */
    function _afterVolumeLimitedTaskMock(address token, uint256 amount) internal virtual {
        _afterVolumeLimitedTask(token, amount);
        _afterBaseTask(token, amount);
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

contract AxelarConnectorMock {
    event LogExecute(uint256 chainId, address token, uint256 amount, address recipient);

    function execute(uint256 chainId, address token, uint256 amount, address recipient) external {
        emit LogExecute(chainId, token, amount, recipient);
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

contract ConnextConnectorMock {
    event LogExecute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        uint256 relayerFee
    );

    function execute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        uint256 relayerFee
    ) external {
        emit LogExecute(chainId, token, amount, minAmountOut, recipient, relayerFee);
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

contract HopBridgeConnectorMock {
    event LogExecute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        address bridge,
        uint256 deadline,
        address relayer,
        uint256 fee
    );

    function execute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        address bridge,
        uint256 deadline,
        address relayer,
        uint256 fee
    ) external {
        emit LogExecute(chainId, token, amount, minAmountOut, recipient, bridge, deadline, relayer, fee);
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

contract SymbiosisConnectorMock {
    event LogExecute(address token, uint256 amount, bytes data);

    function execute(address token, uint256 amount, bytes memory data) external {
        emit LogExecute(token, amount, data);
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

contract WormholeConnectorMock {
    event LogExecute(uint256 chainId, address token, uint256 amount, uint256 minAmountOut, address recipient);

    function execute(uint256 chainId, address token, uint256 amount, uint256 minAmountOut, address recipient) external {
        emit LogExecute(chainId, token, amount, minAmountOut, recipient);
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

pragma solidity ^0.8.0;

contract BalancerV2PoolConnectorMock {
    address public immutable balancerV2Vault;

    constructor(address _balancerV2Vault) {
        balancerV2Vault = _balancerV2Vault;
    }

    event LogExecute(address tokenIn, uint256 amountIn, address[] tokensOut, uint256[] minAmountsOut);

    function exit(address tokenIn, uint256 amountIn, address[] memory tokensOut, uint256[] memory minAmountsOut)
        external
        returns (uint256[] memory amountsOut)
    {
        emit LogExecute(tokenIn, amountIn, tokensOut, minAmountsOut);
        return minAmountsOut;
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

import '@mimic-fi/v3-helpers/contracts/mocks/TokenMock.sol';

contract ConvexConnectorMock {
    IERC20 public immutable rewardToken;
    uint256 public immutable rewardAmount;

    constructor() {
        rewardAmount = 5e18;
        rewardToken = new TokenMock('Convex Claimer Reward', 18);
    }

    mapping (address => address) public getCvxPool;

    mapping (address => address) public getCurvePool;

    event LogClaim(address cvxPool);

    event LogJoin(address curvePool, uint256 amount);

    event LogExit(address cvxPool, uint256 amount);

    function setCvxPool(address curvePool, address cvxPool) external {
        getCvxPool[curvePool] = cvxPool;
    }

    function setCurvePool(address cvxPool, address curvePool) external {
        getCurvePool[cvxPool] = curvePool;
    }

    function claim(address cvxPool) external returns (address[] memory tokens, uint256[] memory amounts) {
        tokens = new address[](1);
        tokens[0] = address(rewardToken);
        amounts = new uint256[](1);
        amounts[0] = rewardAmount;
        emit LogClaim(cvxPool);
    }

    function join(address curvePool, uint256 amount) external returns (uint256) {
        emit LogJoin(curvePool, amount);
        return amount;
    }

    function exit(address cvxPool, uint256 amount) external returns (uint256) {
        emit LogExit(cvxPool, amount);
        return amount;
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

contract Curve2CrvConnectorMock {
    event LogJoin(address pool, address tokenIn, uint256 amountIn, uint256 slippage);

    event LogExit(address pool, uint256 amountIn, address tokenOut, uint256 slippage);

    function join(address pool, address tokenIn, uint256 amountIn, uint256 slippage) external returns (uint256) {
        emit LogJoin(pool, tokenIn, amountIn, slippage);
        return amountIn;
    }

    function exit(address pool, uint256 amountIn, address tokenOut, uint256 slippage) external returns (uint256) {
        emit LogExit(pool, amountIn, tokenOut, slippage);
        return amountIn;
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

contract ERC4626ConnectorMock {
    address public immutable tokenOut;

    event LogJoin(address erc4626, address token, uint256 amount, uint256 minAmountOut);

    event LogExit(address erc4626, uint256 amount, uint256 minAmountOut);

    constructor(address _tokenOut) {
        tokenOut = _tokenOut;
    }

    function join(address erc4626, address token, uint256 assets, uint256 minSharesOut)
        external
        returns (address, uint256)
    {
        emit LogJoin(erc4626, token, assets, minSharesOut);
        return (erc4626, minSharesOut);
    }

    function exit(address erc4626, uint256 shares, uint256 minAssetsOut) external returns (address, uint256) {
        emit LogExit(erc4626, shares, minAssetsOut);
        return (tokenOut, minAssetsOut);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HopL2AmmMock {
    address public immutable hToken;
    address public immutable l2CanonicalToken;

    constructor(address _token, address _hToken) {
        l2CanonicalToken = _token;
        hToken = _hToken;
    }

    function exchangeAddress() external view returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RelayerMock {
    event Deposited(address smartVault, uint256 amount);

    mapping (address => uint256) public getSmartVaultBalance;

    mapping (address => uint256) public getSmartVaultUsedQuota;

    function deposit(address smartVault, uint256 amount) external payable {
        getSmartVaultBalance[smartVault] += amount;
        emit Deposited(smartVault, amount);
    }

    function setSmartVaultUsedQuota(address smartVault, uint256 quota) external {
        getSmartVaultUsedQuota[smartVault] = quota;
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

pragma solidity ^0.8.0;

contract BalancerV2SwapConnectorMock {
    address public immutable balancerV2Vault;

    constructor(address _balancerV2Vault) {
        balancerV2Vault = _balancerV2Vault;
    }

    event LogExecute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes32 poolId,
        bytes32[] hopPoolsIds,
        address[] hopTokens
    );

    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes32 poolId,
        bytes32[] memory hopPoolsIds,
        address[] memory hopTokens
    ) external returns (uint256) {
        emit LogExecute(tokenIn, tokenOut, amountIn, minAmountOut, poolId, hopPoolsIds, hopTokens);
        return minAmountOut;
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

contract BebopConnectorMock {
    event LogExecute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes data);

    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256)
    {
        emit LogExecute(tokenIn, tokenOut, amountIn, minAmountOut, data);
        return minAmountOut;
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

contract HopSwapConnectorMock {
    event LogExecute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address hopDexAddress);

    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address hopDexAddress)
        external
        returns (uint256)
    {
        emit LogExecute(tokenIn, tokenOut, amountIn, minAmountOut, hopDexAddress);
        return minAmountOut;
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

contract OneInchV5ConnectorMock {
    event LogExecute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes data);

    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256)
    {
        emit LogExecute(tokenIn, tokenOut, amountIn, minAmountOut, data);
        return minAmountOut;
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

contract ParaswapV5ConnectorMock {
    event LogExecute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes data);

    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256)
    {
        emit LogExecute(tokenIn, tokenOut, amountIn, minAmountOut, data);
        return minAmountOut;
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

contract UniswapV2ConnectorMock {
    event LogExecute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address[] hopTokens);

    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory hopTokens
    ) external returns (uint256) {
        emit LogExecute(tokenIn, tokenOut, amountIn, minAmountOut, hopTokens);
        return minAmountOut;
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

pragma solidity ^0.8.0;

contract UniswapV3ConnectorMock {
    event LogExecute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint24 fee,
        address[] hopTokens,
        uint24[] hopFees
    );

    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) external returns (uint256) {
        emit LogExecute(tokenIn, tokenOut, amountIn, minAmountOut, fee, hopTokens, hopFees);
        return minAmountOut;
    }
}