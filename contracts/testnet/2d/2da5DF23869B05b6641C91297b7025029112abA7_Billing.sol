// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IBilling } from "./IBilling.sol";
import { Governed } from "./Governed.sol";
import { Rescuable } from "./Rescuable.sol";
import { AddressAliasHelper } from "./arbitrum/AddressAliasHelper.sol";

/**
 * @title Billing Contract
 * @dev The billing contract allows for Graph Tokens to be added by a user. The token can then
 * be pulled by a permissioned set of users named 'collectors'. It is owned and controlled by the 'governor'.
 */
contract Billing is IBilling, Governed, Rescuable {
    // -- State --

    // The contract for interacting with The Graph Token
    IERC20 private immutable graphToken;
    // True for addresses that are Collectors
    mapping(address => bool) public isCollector;

    // maps user address --> user billing balance
    mapping(address => uint256) public userBalances;

    // The L2 token gateway address
    address public l2TokenGateway;

    // The L1 BillingConnector address
    address public l1BillingConnector;

    // -- Events --

    /**
     * @dev User adds tokens
     */
    event TokensAdded(address indexed user, uint256 amount);

    /**
     * @dev User removes tokens
     */
    event TokensRemoved(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev User tried to remove tokens from L1,
     * but they did not have enough balance
     */
    event InsufficientBalanceForRemoval(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Gateway pulled tokens from a user
     */
    event TokensPulled(address indexed user, uint256 amount);

    /**
     * @dev Collector added or removed
     */
    event CollectorUpdated(address indexed collector, bool enabled);

    /**
     * @dev L2 Token Gateway address updated
     */
    event L2TokenGatewayUpdated(address l2TokenGateway);

    /**
     * @dev L1 BillingConnector address updated
     */
    event L1BillingConnectorUpdated(address l1BillingConnector);

    /**
     * @notice Constructor function for the Billing contract
     * @dev Note that the l1BillingConnector address must be provided
     * afterwards through setL1BillingConnector, since it's expected
     * to be deployed after this one.
     * @param _collector   Initial collector address
     * @param _token     Graph Token address
     * @param _governor  Governor address
     */
    constructor(
        address _collector,
        IERC20 _token,
        address _governor,
        address _l2TokenGateway
    ) Governed(_governor) {
        _setCollector(_collector, true);
        _setL2TokenGateway(_l2TokenGateway);
        graphToken = _token;
    }

    /**
     * @dev Check if the caller is a Collector.
     */
    modifier onlyCollector() {
        require(isCollector[msg.sender], "Caller must be Collector");
        _;
    }

    /**
     * @dev Check if the caller is the L2 token gateway.
     */
    modifier onlyL2TokenGateway() {
        require(msg.sender == l2TokenGateway, "Caller must be L2 token gateway");
        _;
    }

    /**
     * @dev Check if the caller is the L2 alias of the L1 BillingConnector
     */
    modifier onlyL1BillingConnector() {
        require(l1BillingConnector != address(0), "BillingConnector not set");
        require(
            msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1BillingConnector),
            "Caller must be L1 BillingConnector"
        );
        _;
    }

    /**
     * @notice Set or unset an address as an allowed Collector
     * @param _collector  Collector address
     * @param _enabled True to set the _collector address as a Collector, false to remove it
     */
    function setCollector(address _collector, bool _enabled) external override onlyGovernor {
        _setCollector(_collector, _enabled);
    }

    /**
     * @notice Sets the L2 token gateway address
     * @param _l2TokenGateway New address for the L2 token gateway
     */
    function setL2TokenGateway(address _l2TokenGateway) external override onlyGovernor {
        _setL2TokenGateway(_l2TokenGateway);
    }

    /**
     * @notice Sets the L1 Billing Connector address
     * @param _l1BillingConnector New address for the L1 BillingConnector (without any aliasing!)
     */
    function setL1BillingConnector(address _l1BillingConnector) external override onlyGovernor {
        require(_l1BillingConnector != address(0), "L1 Billing Connector cannot be 0");
        l1BillingConnector = _l1BillingConnector;
        emit L1BillingConnectorUpdated(_l1BillingConnector);
    }

    /**
     * @notice Add tokens into the billing contract
     * @dev Ensure graphToken.approve() is called on the billing contract first
     * @param _amount  Amount of tokens to add
     */
    function add(uint256 _amount) external override {
        _pullAndAdd(msg.sender, msg.sender, _amount);
    }

    /**
     * @notice Add tokens into the billing contract for any user
     * @dev Ensure graphToken.approve() is called on the billing contract first
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function addTo(address _to, uint256 _amount) external override {
        _pullAndAdd(msg.sender, _to, _amount);
    }

    /**
     * @notice Receive tokens with a callhook from the Arbitrum GRT bridge
     * @dev Expects an `address user` in the encoded _data.
     * @param _from Token sender in L1
     * @param _amount Amount of tokens that were transferred
     * @param _data ABI-encoded callhook data: contains address that tokens are being added to
     */
    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external override onlyL2TokenGateway {
        require(l1BillingConnector != address(0), "BillingConnector not set");
        require(_from == l1BillingConnector, "Invalid L1 sender!");
        address user = abi.decode(_data, (address));
        _add(user, _amount);
    }

    /**
     * @notice Remove tokens from the billing contract, from L1
     * @dev This can only be called from the BillingConnector on L1.
     * If the user does not have enough balance, rather than reverting,
     * this function will succeed and emit InsufficientBalanceForRemoval.
     * @param _from  Address from which the tokens are removed
     * @param _to Address to send the tokens
     * @param _amount  Amount of tokens to remove
     */
    function removeFromL1(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyL1BillingConnector {
        require(_to != address(0), "destination != 0");
        require(_amount != 0, "Must remove more than 0");
        if (userBalances[_from] >= _amount) {
            userBalances[_from] = userBalances[_from] - _amount;
            graphToken.transfer(_to, _amount);
            emit TokensRemoved(_from, _to, _amount);
        } else {
            emit InsufficientBalanceForRemoval(_from, _to, _amount);
        }
    }

    /**
     * @notice Add tokens into the billing contract in bulk
     * @dev Ensure graphToken.approve() is called on the billing contract first
     * @param _to  Array of addresses where to add tokens
     * @param _amount  Array of amount of tokens to add to each account
     */
    function addToMany(address[] calldata _to, uint256[] calldata _amount) external override {
        require(_to.length == _amount.length, "Lengths not equal");

        // Get total amount to add
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amount.length; i++) {
            require(_amount[i] > 0, "Must add more than 0");
            totalAmount += _amount[i];
        }
        graphToken.transferFrom(msg.sender, address(this), totalAmount);

        // Add each amount
        for (uint256 i = 0; i < _to.length; i++) {
            address user = _to[i];
            require(user != address(0), "user != 0");
            userBalances[user] += _amount[i];
            emit TokensAdded(user, _amount[i]);
        }
    }

    /**
     * @notice Remove tokens from the billing contract
     * @dev Tokens will be removed from the sender's balance
     * @param _to  Address that tokens will be sent to
     * @param _amount  Amount of tokens to remove
     */
    function remove(address _to, uint256 _amount) external override {
        require(_to != address(0), "destination != 0");
        require(_amount != 0, "Must remove more than 0");
        require(userBalances[msg.sender] >= _amount, "Too much removed");
        userBalances[msg.sender] = userBalances[msg.sender] - _amount;
        graphToken.transfer(_to, _amount);
        emit TokensRemoved(msg.sender, _to, _amount);
    }

    /**
     * @notice Collector pulls tokens from the billing contract
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     * @param _to Destination to send pulled tokens
     */
    function pull(
        address _user,
        uint256 _amount,
        address _to
    ) external override onlyCollector {
        uint256 maxAmount = _pull(_user, _amount);
        _sendTokens(_to, maxAmount);
    }

    /**
     * @notice Collector pulls tokens from many users in the billing contract
     * @param _users  Addresses that tokens are being pulled from
     * @param _amounts  Amounts of tokens to pull from each user
     * @param _to Destination to send pulled tokens
     */
    function pullMany(
        address[] calldata _users,
        uint256[] calldata _amounts,
        address _to
    ) external override onlyCollector {
        require(_users.length == _amounts.length, "Lengths not equal");
        uint256 totalPulled;
        for (uint256 i = 0; i < _users.length; i++) {
            uint256 userMax = _pull(_users[i], _amounts[i]);
            totalPulled = totalPulled + userMax;
        }
        _sendTokens(_to, totalPulled);
    }

    /**
     * @notice Allows the Governor to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyGovernor {
        _rescueTokens(_to, _token, _amount);
    }

    /**
     * @dev Collector pulls tokens from the billing contract. Uses Math.min() so that it won't fail
     * in the event that a user removes in front of the Collector pulling
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     */
    function _pull(address _user, uint256 _amount) internal returns (uint256) {
        uint256 maxAmount = Math.min(_amount, userBalances[_user]);
        if (maxAmount > 0) {
            userBalances[_user] = userBalances[_user] - maxAmount;
            emit TokensPulled(_user, maxAmount);
        }
        return maxAmount;
    }

    /**
     * @dev Send tokens to a destination account
     * @param _to Address where to send tokens
     * @param _amount Amount of tokens to send
     */
    function _sendTokens(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            require(_to != address(0), "Cannot transfer to empty address");
            graphToken.transfer(_to, _amount);
        }
    }

    /**
     * @dev Set or unset an address as an allowed Collector
     * @param _collector  Collector address
     * @param _enabled True to set the _collector address as a Collector, false to remove it
     */
    function _setCollector(address _collector, bool _enabled) internal {
        require(_collector != address(0), "Collector cannot be 0");
        isCollector[_collector] = _enabled;
        emit CollectorUpdated(_collector, _enabled);
    }

    /**
     * @dev Set the new L2 token gateway address
     * @param _l2TokenGateway  New L2 token gateway address
     */
    function _setL2TokenGateway(address _l2TokenGateway) internal {
        require(_l2TokenGateway != address(0), "L2 Token Gateway cannot be 0");
        l2TokenGateway = _l2TokenGateway;
        emit L2TokenGatewayUpdated(_l2TokenGateway);
    }

    /**
     * @dev Pull, then add tokens into the billing contract
     * Ensure graphToken.approve() is called on the billing contract first
     * @param _from  Address that is sending tokens
     * @param _user  User that is adding tokens
     * @param _amount  Amount of tokens to add
     */
    function _pullAndAdd(
        address _from,
        address _user,
        uint256 _amount
    ) private {
        require(_amount != 0, "Must add more than 0");
        require(_user != address(0), "user != 0");
        graphToken.transferFrom(_from, address(this), _amount);
        _add(_user, _amount);
    }

    /**
     * @dev Add tokens into the billing account balance for a user
     * Tokens must already be in this contract's balance
     * @param _user  User that is adding tokens
     * @param _amount  Amount of tokens to add
     */
    function _add(address _user, uint256 _amount) private {
        userBalances[_user] = userBalances[_user] + _amount;
        emit TokensAdded(_user, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IBilling {
    /**
     * @dev Set or unset an address as an allowed Collector
     * @param _collector  Collector address
     * @param _enabled True to set the _collector address as a Collector, false to remove it
     */
    function setCollector(address _collector, bool _enabled) external; // onlyGovernor

    /**
     * @dev Sets the L2 token gateway address
     * @param _l2TokenGateway New address for the L2 token gateway
     */
    function setL2TokenGateway(address _l2TokenGateway) external;

    /**
     * @dev Sets the L1 Billing Connector address
     * @param _l1BillingConnector New address for the L1 BillingConnector (without any aliasing!)
     */
    function setL1BillingConnector(address _l1BillingConnector) external;

    /**
     * @dev Add tokens into the billing contract
     * @param _amount  Amount of tokens to add
     */
    function add(uint256 _amount) external;

    /**
     * @dev Add tokens into the billing contract for any user
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function addTo(address _to, uint256 _amount) external;

    /**
     * @dev Receive tokens with a callhook from the Arbitrum GRT bridge
     * Expects an `address user` in the encoded _data.
     * @param _from Token sender in L1
     * @param _amount Amount of tokens that were transferred
     * @param _data ABI-encoded callhook data: contains address that tokens are being added to
     */
    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /**
     * @dev Remove tokens from the billing contract, from L1
     * This can only be called from the BillingConnector on L1.
     * @param _from  Address from which the tokens are removed
     * @param _to Address to send the tokens
     * @param _amount  Amount of tokens to remove
     */
    function removeFromL1(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     * @dev Add tokens into the billing contract in bulk
     * Ensure graphToken.approve() is called on the billing contract first
     * @param _to  Array of addresses where to add tokens
     * @param _amount  Array of amount of tokens to add to each account
     */
    function addToMany(address[] calldata _to, uint256[] calldata _amount) external;

    /**
     * @dev Remove tokens from the billing contract
     * Tokens will be removed from the sender's balance
     * @param _to  Address that tokens are being moved to
     * @param _amount  Amount of tokens to remove
     */
    function remove(address _to, uint256 _amount) external;

    /**
     * @dev Collector pulls tokens from the billing contract
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     * @param _to Destination to send pulled tokens
     */
    function pull(
        address _user,
        uint256 _amount,
        address _to
    ) external;

    /**
     * @dev Collector pulls tokens from many users in the billing contract
     * @param _users  Addresses that tokens are being pulled from
     * @param _amounts  Amounts of tokens to pull from each user
     * @param _to Destination to send pulled tokens
     */
    function pullMany(
        address[] calldata _users,
        uint256[] calldata _amounts,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/**
 * @title Graph Governance contract
 * @dev Allows a contract to be owned and controlled by the 'governor'
 */
contract Governed {
    // -- State --

    // The address of the governor
    address public governor;
    // The address of the pending governor
    address public pendingGovernor;

    // -- Events --

    // Emit when the pendingGovernor state variable is updated
    event NewPendingOwnership(address indexed from, address indexed to);
    // Emit when the governor state variable is updated
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor() {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor with the _initGovernor param.
     * @param _initGovernor Governor address
     */
    constructor(address _initGovernor) {
        require(_initGovernor != address(0), "Governor must not be 0");
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(pendingGovernor != address(0) && msg.sender == pendingGovernor, "Caller must be pending governor");

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Rescuable contract
 * @dev Allows a contract to have a function to rescue tokens sent by mistake.
 * The contract must implement the external rescueTokens function or similar,
 * that calls this contract's _rescueTokens.
 */
contract Rescuable {
    /**
     * @dev Tokens rescued by the permissioned user
     */
    event TokensRescued(address indexed to, address indexed token, uint256 amount);

    /**
     * @dev Allows a permissioned user to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function _rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        require(_to != address(0), "Cannot send to address(0)");
        require(_amount != 0, "Cannot rescue 0 tokens");
        IERC20 token = IERC20(_token);
        require(token.transfer(_to, _amount), "Rescue tokens failed");
        emit TokensRescued(_to, _token, _amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/84e64dee6ee82adbf8ec34fd4b86c207a61d9007/packages/arb-bridge-eth
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.8.16 ([email protected])
 *
 */

pragma solidity ^0.8.16;

library AddressAliasHelper {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        l1Address = address(uint160(l2Address) - offset);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}