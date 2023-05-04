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

import '@mimic-fi/v2-registry/contracts/implementations/IImplementation.sol';

/**
 * @title IBridgeConnector
 * @dev Bridge Connector interface to bridge tokens between different chains. It must follow IImplementation interface.
 */
interface IBridgeConnector is IImplementation {
    /**
     * @dev Enum identifying the sources proposed: Hop only for now.
     */
    enum Source {
        Hop
    }

    /**
     * @dev Bridge assets to a different chain
     * @param source Source to execute the requested bridge op
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amountIn Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param data ABI encoded data that will depend on the requested source
     */
    function bridge(
        uint8 source,
        uint256 chainId,
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        bytes memory data
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

interface IHopL1Bridge {
    /**
     * @notice To send funds L1->L2, call the sendToL2 method on the L1 Bridge contract
     * @notice `amountOutMin` and `deadline` should be 0 when no swap is intended at the destination.
     * @notice `amount` is the total amount the user wants to send including the relayer fee
     * @dev Send tokens to a supported layer-2 to mint hToken and optionally swap the hToken in the
     * AMM at the destination.
     * @param chainId The chainId of the destination chain
     * @param recipient The address receiving funds at the destination
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     * @param relayer The address of the relayer at the destination.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     */
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
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

interface IHopL2AMM {
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

pragma solidity ^0.8.0;

import './IAuthorizer.sol';

/**
 * @title Authorizer
 * @dev Authorization module to be used by contracts that need to implement permissions for their methods.
 * It provides a permissions model to list who is allowed to call what function in a contract. And only accounts
 * authorized to manage those permissions are the ones that are allowed to authorize or unauthorize accounts.
 */
contract Authorizer is IAuthorizer {
    // Constant used to denote that a permission is open to anyone
    address public constant ANY_ADDRESS = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    // Internal mapping to tell who is allowed to do what indexed by (account, function selector)
    mapping (address => mapping (bytes4 => bool)) private authorized;

    /**
     * @dev Modifier that should be used to tag protected functions
     */
    modifier auth() {
        _authenticate(msg.sender, msg.sig);
        _;
    }

    /**
     * @dev Tells whether someone is allowed to call a function or not. It returns true if it's allowed to anyone.
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     */
    function isAuthorized(address who, bytes4 what) public view override returns (bool) {
        return authorized[ANY_ADDRESS][what] || authorized[who][what];
    }

    /**
     * @dev Authorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be authorized
     * @param what Function selector to be granted
     */
    function authorize(address who, bytes4 what) external override auth {
        _authorize(who, what);
    }

    /**
     * @dev Unauthorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be unauthorized
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, bytes4 what) external override auth {
        _unauthorize(who, what);
    }

    /**
     * @dev Internal function to authenticate someone over a function.
     * It reverts if the given account is not authorized to call the requested function.
     * @param who Address to be authenticated
     * @param what Function selector to be authenticated
     */
    function _authenticate(address who, bytes4 what) internal view {
        require(isAuthorized(who, what), 'AUTH_SENDER_NOT_ALLOWED');
    }

    /**
     * @dev Internal function to authorize someone to call a function
     * @param who Address to be authorized
     * @param what Function selector to be granted
     */
    function _authorize(address who, bytes4 what) internal {
        authorized[who][what] = true;
        emit Authorized(who, what);
    }

    /**
     * @dev Internal function to unauthorize someone to call a function
     * @param who Address to be unauthorized
     * @param what Function selector to be revoked
     */
    function _unauthorize(address who, bytes4 what) internal {
        authorized[who][what] = false;
        emit Unauthorized(who, what);
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
 * @title IAuthorizer
 */
interface IAuthorizer {
    /**
     * @dev Emitted when an account is authorized to call a function
     */
    event Authorized(address indexed who, bytes4 what);

    /**
     * @dev Emitted when an account is unauthorized to call a function
     */
    event Unauthorized(address indexed who, bytes4 what);

    /**
     * @dev Authorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be authorized
     * @param what Function selector to be granted
     */
    function authorize(address who, bytes4 what) external;

    /**
     * @dev Unauthorizes someone to call a function. Sender must be authorize to do so.
     * @param who Address to be unauthorized
     * @param what Function selector to be revoked
     */
    function unauthorize(address who, bytes4 what) external;

    /**
     * @dev Tells whether someone is allowed to call a function or not. It returns true if it's allowed to anyone.
     * @param who Address asking permission for
     * @param what Function selector asking permission for
     */
    function isAuthorized(address who, bytes4 what) external view returns (bool);
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
 * @title UncheckedMath
 * @dev Math library to perform unchecked operations
 */
library UncheckedMath {
    /**
     * @dev Unsafely adds two unsigned integers
     */
    function uncheckedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    /**
     * @dev Unsafely subtracts two unsigned integers
     */
    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }

    /**
     * @dev Unsafely multiplies two unsigned integers
     */
    function uncheckedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a * b;
        }
    }

    /**
     * @dev Unsafely multiplies two signed integers
     */
    function uncheckedMul(int256 a, int256 b) internal pure returns (int256) {
        unchecked {
            return a * b;
        }
    }

    /**
     * @dev Unsafely divides two unsigned integers
     */
    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a / b;
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

// SPDX-License-Identifier: MIT

// Based on the EnumerableMap library from OpenZeppelin Contracts

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.AddressToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.AddressToAddressMap private myMap;
 * }
 * ```
 */

library EnumerableMap {
    using EnumerableSet for EnumerableSet.AddressSet;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // address keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as AddressToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in address.

    struct AddressToAddressMap {
        // Storage of keys
        EnumerableSet.AddressSet _keys;
        mapping (address => address) _values;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(AddressToAddressMap storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToAddressMap storage map, address key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToAddressMap storage map, address key, address value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToAddressMap storage map, address key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToAddressMap storage map, uint256 index) internal view returns (address, address) {
        address key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToAddressMap storage map, address key) internal view returns (address) {
        address value = map._values[key];
        require(value != address(0) || contains(map, key), 'EnumerableMap: nonexistent key');
        return value;
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToAddressMap storage map, address key) internal view returns (bool, address) {
        address value = map._values[key];
        if (value == address(0)) {
            return (contains(map, key), address(0));
        } else {
            return (true, value);
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

/**
 * @title IPriceFeedProvider
 * @dev Contract providing price feed references for (base, quote) token pairs
 */
interface IPriceFeedProvider {
    /**
     * @dev Emitted every time a price feed is set for (base, quote) pair
     */
    event PriceFeedSet(address indexed base, address indexed quote, address feed);

    /**
     * @dev Tells the price feed address for (base, quote) pair. It returns the zero address if there is no one set.
     * @param base Token to be rated
     * @param quote Token used for the price rate
     */
    function getPriceFeed(address base, address quote) external view returns (address);

    /**
     * @dev Sets a of price feed
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Price feed to be set
     */
    function setPriceFeed(address base, address quote, address feed) external;

    /**
     * @dev Sets a list of price feeds
     * @param bases List of token bases to be set
     * @param quotes List of token quotes to be set
     * @param feeds List of price feeds to be set
     */
    function setPriceFeeds(address[] memory bases, address[] memory quotes, address[] memory feeds) external;
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

import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';

import './IPriceFeedProvider.sol';

/**
 * @title IPriceFeedProvider
 * @dev Contract providing price feed references for (base, quote) token pairs
 */
contract PriceFeedProvider is IPriceFeedProvider {
    using UncheckedMath for uint256;

    // Mapping of price feeds from "token A" to "token B"
    mapping (address => mapping (address => address)) private _priceFeeds;

    /**
     * @dev Tells the price feed address for (base, quote) pair. It returns the zero address if there is no one set.
     * @param base Token to be rated
     * @param quote Token used for the price rate
     */
    function getPriceFeed(address base, address quote) external view override returns (address) {
        return _priceFeeds[base][quote];
    }

    /**
     * @dev Sets a of price feed
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Price feed to be set
     */
    function setPriceFeed(address base, address quote, address feed) public virtual override {
        _priceFeeds[base][quote] = feed;
        emit PriceFeedSet(base, quote, feed);
    }

    /**
     * @dev Sets a list of price feeds. Sender must be authorized.
     * @param bases List of token bases to be set
     * @param quotes List of token quotes to be set
     * @param feeds List of price feeds to be set
     */
    function setPriceFeeds(address[] memory bases, address[] memory quotes, address[] memory feeds)
        public
        virtual
        override
    {
        require(bases.length == quotes.length, 'SET_FEEDS_INVALID_QUOTES_LENGTH');
        require(bases.length == feeds.length, 'SET_FEEDS_INVALID_FEEDS_LENGTH');
        for (uint256 i = 0; i < bases.length; i = i.uncheckedAdd(1)) setPriceFeed(bases[i], quotes[i], feeds[i]);
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

import '@mimic-fi/v2-registry/contracts/implementations/IImplementation.sol';

/**
 * @title IPriceOracle
 * @dev Oracle that interfaces with external feeds to provide quotes for tokens based on any other token.
 * It must support also `IImplementation`.
 */
interface IPriceOracle is IImplementation {
    /**
     * @dev Tells the price of a token (base) in a given quote. The response is expressed using the corresponding
     * number of decimals so that when performing a fixed point product of it by a `base` amount it results in
     * a value expressed in `quote` decimals. For example, if `base` is ETH and `quote` is USDC, then the returned
     * value is expected to be expressed using 6 decimals:
     *
     * FixedPoint.mul(X[ETH], price[USDC/ETH]) = FixedPoint.mul(X[18], price[6]) = X * price [6]
     *
     * @param provider Contract providing the price feeds to use by the oracle
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getPrice(address provider, address base, address quote) external view returns (uint256);
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

import '@mimic-fi/v2-helpers/contracts/auth/Authorizer.sol';

import './BaseImplementation.sol';

/**
 * @title BaseAuthorizedImplementation
 * @dev BaseImplementation using the Authorizer mixin. Base implementations that want to use the Authorizer
 * permissions mechanism should inherit from this contract instead.
 */
abstract contract BaseAuthorizedImplementation is BaseImplementation, Authorizer {
    /**
     * @dev Creates a new BaseAuthorizedImplementation
     * @param admin Address to be granted authorize and unauthorize permissions
     * @param registry Address of the Mimic Registry
     */
    constructor(address admin, address registry) BaseImplementation(registry) {
        _authorize(admin, Authorizer.authorize.selector);
        _authorize(admin, Authorizer.unauthorize.selector);
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

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import './IImplementation.sol';
import '../registry/IRegistry.sol';

/**
 * @title BaseImplementation
 * @dev This implementation contract comes with an immutable reference to an implementations registry where it should
 * be registered as well (checked during initialization). It allows requesting new instances of other registered
 * implementations to as another safety check to make sure valid instances are referenced in case it's needed.
 */
abstract contract BaseImplementation is IImplementation {
    // Immutable implementations registry reference
    address public immutable override registry;

    /**
     * @dev Creates a new BaseImplementation
     * @param _registry Address of the Mimic Registry where dependencies will be validated against
     */
    constructor(address _registry) {
        registry = _registry;
    }

    /**
     * @dev Internal function to validate a new dependency that must be registered as stateless.
     * It checks the new dependency is registered, not deprecated, and stateless.
     * @param dependency New stateless dependency to be set
     */
    function _validateStatelessDependency(address dependency) internal view {
        require(_validateDependency(dependency), 'DEPENDENCY_NOT_STATELESS');
    }

    /**
     * @dev Internal function to validate a new dependency that cannot be registered as stateless.
     * It checks the new dependency is registered, not deprecated, and not stateful.
     * @param dependency New stateful dependency to be set
     */
    function _validateStatefulDependency(address dependency) internal view {
        require(!_validateDependency(dependency), 'DEPENDENCY_NOT_STATEFUL');
    }

    /**
     * @dev Internal function to validate a new dependency. It checks the dependency is registered and not deprecated.
     * @param dependency New dependency to be set
     * @return Whether the dependency is stateless or not
     */
    function _validateDependency(address dependency) private view returns (bool) {
        (bool stateless, bool deprecated, bytes32 namespace) = IRegistry(registry).implementationData(dependency);
        require(namespace != bytes32(0), 'DEPENDENCY_NOT_REGISTERED');
        require(!deprecated, 'DEPENDENCY_DEPRECATED');
        return stateless;
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

// solhint-disable func-name-mixedcase

/**
 * @title IImplementation
 * @dev Implementation interface that must be followed for implementations to be registered in the Mimic Registry
 */
interface IImplementation {
    /**
     * @dev Tells the namespace under which the implementation is registered in the Mimic Registry
     */
    function NAMESPACE() external view returns (bytes32);

    /**
     * @dev Tells the address of the Mimic Registry
     */
    function registry() external view returns (address);
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

import '@mimic-fi/v2-helpers/contracts/auth/Authorizer.sol';

import './InitializableImplementation.sol';

/**
 * @title InitializableAuthorizedImplementation
 * @dev InitializableImplementation using the Authorizer mixin. Initializable implementations that want to use the
 * Authorizer permissions mechanism should inherit from this contract instead.
 */
abstract contract InitializableAuthorizedImplementation is InitializableImplementation, Authorizer {
    /**
     * @dev Creates a new InitializableAuthorizedImplementation
     * @param registry Address of the Mimic Registry
     */
    constructor(address registry) InitializableImplementation(registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Initialization function that authorizes an admin account to authorize and unauthorize accounts.
     * Note this function can only be called from a function marked with the `initializer` modifier.
     * @param admin Address to be granted authorize and unauthorize permissions
     */
    function _initialize(address admin) internal onlyInitializing {
        _initialize();
        _authorize(admin, Authorizer.authorize.selector);
        _authorize(admin, Authorizer.unauthorize.selector);
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

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import './BaseImplementation.sol';

/**
 * @title InitializableImplementation
 * @dev Implementation contract to be used through proxies. Inheriting contracts are meant to be initialized through
 * initialization functions instead of constructor functions. It allows re-using the same logic contract while making
 * deployments cheaper.
 */
abstract contract InitializableImplementation is BaseImplementation, Initializable {
    /**
     * @dev Creates a new BaseImplementation. Note that initializers are disabled at creation time.
     */
    constructor(address registry) BaseImplementation(registry) {
        _disableInitializers();
    }

    /**
     * @dev Initialization function.
     * Note this function can only be called from a function marked with the `initializer` modifier.
     */
    function _initialize() internal view onlyInitializing {
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

pragma solidity >=0.8.0;

import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';

/**
 * @title IRegistry
 * @dev Registry interface, it must follow the IAuthorizer interface.
 */
interface IRegistry is IAuthorizer {
    /**
     * @dev Emitted every time a new implementation is registered
     */
    event Registered(bytes32 indexed namespace, address indexed implementation, bool stateless);

    /**
     * @dev Emitted every time an implementation is deprecated
     */
    event Deprecated(bytes32 indexed namespace, address indexed implementation);

    /**
     * @dev Tells the data of an implementation:
     * @param implementation Address of the implementation to request it's data
     */
    function implementationData(address implementation)
        external
        view
        returns (bool stateless, bool deprecated, bytes32 namespace);

    /**
     * @dev Tells if a specific implementation is registered under a certain namespace and it's not deprecated
     * @param namespace Namespace asking for
     * @param implementation Address of the implementation to be checked
     */
    function isActive(bytes32 namespace, address implementation) external view returns (bool);

    /**
     * @dev Registers a new implementation for a given namespace
     * @param namespace Namespace to be used for the implementation
     * @param implementation Address of the implementation to be registered
     * @param stateless Whether the implementation is stateless or not
     */
    function register(bytes32 namespace, address implementation, bool stateless) external;

    /**
     * @dev Deprecates a registered implementation
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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v2-bridge-connector/contracts/IBridgeConnector.sol';

/**
 * @title BridgeConnectorLib
 * @dev Library used to delegate-call bridge ops and decode return data correctly
 */
library BridgeConnectorLib {
    /**
     * @dev Delegate-calls a bridge to the bridge connector and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function bridge(
        address connector,
        uint8 source,
        uint256 chainId,
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        bytes memory data
    ) internal {
        bytes memory bridgeData = abi.encodeWithSelector(
            IBridgeConnector.bridge.selector,
            source,
            chainId,
            token,
            amountIn,
            minAmountOut,
            recipient,
            data
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = connector.delegatecall(bridgeData);
        Address.verifyCallResult(success, returndata, 'BRIDGE_CALL_REVERTED');
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

import '@mimic-fi/v2-strategies/contracts/IStrategy.sol';

/**
 * @title StrategyLib
 * @dev Library used to delegate-call to strategy and decode return data correctly
 */
library StrategyLib {
    /**
     * @dev Delegate-calls a claim to a strategy and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function claim(address strategy, bytes memory data) internal returns (address[] memory, uint256[] memory) {
        bytes memory claimData = abi.encodeWithSelector(IStrategy.claim.selector, data);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = strategy.delegatecall(claimData);
        Address.verifyCallResult(success, returndata, 'CLAIM_CALL_REVERTED');
        return abi.decode(returndata, (address[], uint256[]));
    }

    /**
     * @dev Delegate-calls a join to a strategy and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function join(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) internal returns (address[] memory tokensOut, uint256[] memory amountsOut, uint256 value) {
        bytes memory joinData = abi.encodeWithSelector(IStrategy.join.selector, tokensIn, amountsIn, slippage, data);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = strategy.delegatecall(joinData);
        Address.verifyCallResult(success, returndata, 'JOIN_CALL_REVERTED');
        return abi.decode(returndata, (address[], uint256[], uint256));
    }

    /**
     * @dev Delegate-calls a exit to a strategy and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function exit(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) internal returns (address[] memory tokensOut, uint256[] memory amountsOut, uint256 value) {
        bytes memory exitData = abi.encodeWithSelector(IStrategy.exit.selector, tokensIn, amountsIn, slippage, data);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = strategy.delegatecall(exitData);
        Address.verifyCallResult(success, returndata, 'EXIT_CALL_REVERTED');
        return abi.decode(returndata, (address[], uint256[], uint256));
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

import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';

/**
 * @title SwapConnectorLib
 * @dev Library used to delegate-call swaps and decode return data correctly
 */
library SwapConnectorLib {
    /**
     * @dev Delegate-calls a swap to the swap connector and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function swap(
        address connector,
        uint8 source,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes memory data
    ) internal returns (uint256 amountOut) {
        bytes memory swapData = abi.encodeWithSelector(
            ISwapConnector.swap.selector,
            source,
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            data
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = connector.delegatecall(swapData);
        Address.verifyCallResult(success, returndata, 'SWAP_CALL_REVERTED');
        return abi.decode(returndata, (uint256));
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

import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';
import '@mimic-fi/v2-price-oracle/contracts/feeds/IPriceFeedProvider.sol';
import '@mimic-fi/v2-registry/contracts/implementations/IImplementation.sol';

/**
 * @title ISmartVault
 * @dev Mimic Smart Vault interface to manage assets. It must support also `IImplementation` and `IAuthorizer`
 */
interface ISmartVault is IPriceFeedProvider, IImplementation, IAuthorizer {
    enum SwapLimit {
        Slippage,
        MinAmountOut
    }

    enum BridgeLimit {
        Slippage,
        MinAmountOut
    }

    /**
     * @dev Emitted every time a new strategy is set for the Smart Vault
     */
    event StrategySet(address indexed strategy, bool allowed);

    /**
     * @dev Emitted every time a new price oracle is set for the Smart Vault
     */
    event PriceOracleSet(address indexed priceOracle);

    /**
     * @dev Emitted every time a new swap connector is set for the Smart Vault
     */
    event SwapConnectorSet(address indexed swapConnector);

    /**
     * @dev Emitted every time a new bridge connector is set for the Smart Vault
     */
    event BridgeConnectorSet(address indexed bridgeConnector);

    /**
     * @dev Emitted every time a new fee collector is set
     */
    event FeeCollectorSet(address indexed feeCollector);

    /**
     * @dev Emitted every time the withdraw fee percentage is set
     */
    event WithdrawFeeSet(uint256 pct, uint256 cap, address token, uint256 period);

    /**
     * @dev Emitted every time the performance fee percentage is set
     */
    event PerformanceFeeSet(uint256 pct, uint256 cap, address token, uint256 period);

    /**
     * @dev Emitted every time the swap fee percentage is set
     */
    event SwapFeeSet(uint256 pct, uint256 cap, address token, uint256 period);

    /**
     * @dev Emitted every time the bridge fee percentage is set
     */
    event BridgeFeeSet(uint256 pct, uint256 cap, address token, uint256 period);

    /**
     * @dev Emitted every time `call` is called
     */
    event Call(address indexed target, bytes callData, uint256 value, bytes result, bytes data);

    /**
     * @dev Emitted every time `collect` is called
     */
    event Collect(address indexed token, address indexed from, uint256 collected, bytes data);

    /**
     * @dev Emitted every time `withdraw` is called
     */
    event Withdraw(address indexed token, address indexed recipient, uint256 withdrawn, uint256 fee, bytes data);

    /**
     * @dev Emitted every time `wrap` is called
     */
    event Wrap(uint256 amount, uint256 wrapped, bytes data);

    /**
     * @dev Emitted every time `unwrap` is called
     */
    event Unwrap(uint256 amount, uint256 unwrapped, bytes data);

    /**
     * @dev Emitted every time `claim` is called
     */
    event Claim(address indexed strategy, address[] tokens, uint256[] amounts, bytes data);

    /**
     * @dev Emitted every time `join` is called
     */
    event Join(
        address indexed strategy,
        address[] tokensIn,
        uint256[] amountsIn,
        address[] tokensOut,
        uint256[] amountsOut,
        uint256 value,
        uint256 slippage,
        bytes data
    );

    /**
     * @dev Emitted every time `exit` is called
     */
    event Exit(
        address indexed strategy,
        address[] tokensIn,
        uint256[] amountsIn,
        address[] tokensOut,
        uint256[] amountsOut,
        uint256 value,
        uint256[] fees,
        uint256 slippage,
        bytes data
    );

    /**
     * @dev Emitted every time `swap` is called
     */
    event Swap(
        uint8 indexed source,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 minAmountOut,
        uint256 fee,
        bytes data
    );

    /**
     * @dev Emitted every time `bridge` is called
     */
    event Bridge(
        uint8 indexed source,
        uint256 indexed chainId,
        address indexed token,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 fee,
        address recipient,
        bytes data
    );

    /**
     * @dev Tells a strategy is allowed or not
     * @param strategy Address of the strategy being queried
     */
    function isStrategyAllowed(address strategy) external view returns (bool);

    /**
     * @dev Tells the invested value for a strategy
     * @param strategy Address of the strategy querying the invested value of
     */
    function investedValue(address strategy) external view returns (uint256);

    /**
     * @dev Tells the last value accrued for a strategy. Note this value can be outdated.
     * @param strategy Address of the strategy querying the last value of
     */
    function lastValue(address strategy) external view returns (uint256);

    /**
     * @dev Tells the price oracle associated to a Smart Vault
     */
    function priceOracle() external view returns (address);

    /**
     * @dev Tells the swap connector associated to a Smart Vault
     */
    function swapConnector() external view returns (address);

    /**
     * @dev Tells the bridge connector associated to a Smart Vault
     */
    function bridgeConnector() external view returns (address);

    /**
     * @dev Tells the address where fees will be deposited
     */
    function feeCollector() external view returns (address);

    /**
     * @dev Tells the withdraw fee configuration
     */
    function withdrawFee()
        external
        view
        returns (uint256 pct, uint256 cap, address token, uint256 period, uint256 totalCharged, uint256 nextResetTime);

    /**
     * @dev Tells the performance fee configuration
     */
    function performanceFee()
        external
        view
        returns (uint256 pct, uint256 cap, address token, uint256 period, uint256 totalCharged, uint256 nextResetTime);

    /**
     * @dev Tells the swap fee configuration
     */
    function swapFee()
        external
        view
        returns (uint256 pct, uint256 cap, address token, uint256 period, uint256 totalCharged, uint256 nextResetTime);

    /**
     * @dev Tells the bridge fee configuration
     */
    function bridgeFee()
        external
        view
        returns (uint256 pct, uint256 cap, address token, uint256 period, uint256 totalCharged, uint256 nextResetTime);

    /**
     * @dev Tells the address of the wrapped native token
     */
    function wrappedNativeToken() external view returns (address);

    /**
     * @dev Sets a new strategy as allowed or not for a Smart Vault
     * @param strategy Address of the strategy to be set
     * @param allowed Whether the strategy is allowed or not
     */
    function setStrategy(address strategy, bool allowed) external;

    /**
     * @dev Sets a new price oracle to a Smart Vault
     * @param newPriceOracle Address of the new price oracle to be set
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @dev Sets a new swap connector to a Smart Vault
     * @param newSwapConnector Address of the new swap connector to be set
     */
    function setSwapConnector(address newSwapConnector) external;

    /**
     * @dev Sets a new bridge connector to a Smart Vault
     * @param newBridgeConnector Address of the new bridge connector to be set
     */
    function setBridgeConnector(address newBridgeConnector) external;

    /**
     * @dev Sets a new fee collector
     * @param newFeeCollector Address of the new fee collector to be set
     */
    function setFeeCollector(address newFeeCollector) external;

    /**
     * @dev Sets a new withdraw fee configuration
     * @param pct Withdraw fee percentage to be set
     * @param cap New maximum amount of withdraw fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the withdraw fee
     */
    function setWithdrawFee(uint256 pct, uint256 cap, address token, uint256 period) external;

    /**
     * @dev Sets a new performance fee configuration
     * @param pct Performance fee percentage to be set
     * @param cap New maximum amount of performance fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the performance fee
     */
    function setPerformanceFee(uint256 pct, uint256 cap, address token, uint256 period) external;

    /**
     * @dev Sets a new swap fee configuration
     * @param pct Swap fee percentage to be set
     * @param cap New maximum amount of swap fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the swap fee
     */
    function setSwapFee(uint256 pct, uint256 cap, address token, uint256 period) external;

    /**
     * @dev Sets a new bridge fee configuration
     * @param pct Bridge fee percentage to be set
     * @param cap New maximum amount of bridge fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the bridge fee
     */
    function setBridgeFee(uint256 pct, uint256 cap, address token, uint256 period) external;

    /**
     * @dev Tells the price of a token (base) in a given quote
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getPrice(address base, address quote) external view returns (uint256);

    /**
     * @dev Execute an arbitrary call from a Smart Vault
     * @param target Address where the call will be sent
     * @param callData Calldata to be used for the call
     * @param value Value in wei that will be attached to the call
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return result Call response if it was successful, otherwise it reverts
     */
    function call(address target, bytes memory callData, uint256 value, bytes memory data)
        external
        returns (bytes memory result);

    /**
     * @dev Collect tokens from a sender to a Smart Vault
     * @param token Address of the token to be collected
     * @param from Address where the tokens will be transfer from
     * @param amount Amount of tokens to be transferred
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return collected Amount of tokens assigned to the Smart Vault
     */
    function collect(address token, address from, uint256 amount, bytes memory data)
        external
        returns (uint256 collected);

    /**
     * @dev Withdraw tokens to an external account
     * @param token Address of the token to be withdrawn
     * @param amount Amount of tokens to withdraw
     * @param recipient Address where the tokens will be transferred to
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return withdrawn Amount of tokens transferred to the recipient address
     */
    function withdraw(address token, uint256 amount, address recipient, bytes memory data)
        external
        returns (uint256 withdrawn);

    /**
     * @dev Wrap an amount of native tokens to the wrapped ERC20 version of it
     * @param amount Amount of native tokens to be wrapped
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return wrapped Amount of tokens wrapped
     */
    function wrap(uint256 amount, bytes memory data) external returns (uint256 wrapped);

    /**
     * @dev Unwrap an amount of wrapped native tokens
     * @param amount Amount of wrapped native tokens to unwrapped
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return unwrapped Amount of tokens unwrapped
     */
    function unwrap(uint256 amount, bytes memory data) external returns (uint256 unwrapped);

    /**
     * @dev Claim strategy rewards
     * @param strategy Address of the strategy to claim rewards
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return tokens Addresses of the tokens received as rewards
     * @return amounts Amounts of the tokens received as rewards
     */
    function claim(address strategy, bytes memory data)
        external
        returns (address[] memory tokens, uint256[] memory amounts);

    /**
     * @dev Join a strategy with an amount of tokens
     * @param strategy Address of the strategy to join
     * @param tokensIn List of token addresses to join with
     * @param amountsIn List of token amounts to join with
     * @param slippage Slippage that will be used to compute the join
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return tokensOut List of token addresses received after the join
     * @return amountsOut List of token amounts received after the join
     */
    function join(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) external returns (address[] memory tokensOut, uint256[] memory amountsOut);

    /**
     * @dev Exit a strategy
     * @param strategy Address of the strategy to exit
     * @param tokensIn List of token addresses to exit with
     * @param amountsIn List of token amounts to exit with
     * @param slippage Slippage that will be used to compute the exit
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return tokensOut List of token addresses received after the exit
     * @return amountsOut List of token amounts received after the exit
     */
    function exit(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) external returns (address[] memory tokensOut, uint256[] memory amountsOut);

    /**
     * @dev Swaps two tokens
     * @param source Source to request the swap. It depends on the Swap Connector attached to a Smart Vault.
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param limitType Swap limit to be applied: slippage or min amount out
     * @param limitAmount Amount of the swap limit to be applied depending on limitType
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return amountOut Received amount of tokens out
     */
    function swap(
        uint8 source,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        SwapLimit limitType,
        uint256 limitAmount,
        bytes memory data
    ) external returns (uint256 amountOut);

    /**
     * @dev Bridge assets to another chain
     * @param source Source to request the bridge. It depends on the Bridge Connector attached to a Smart Vault.
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param limitType Swap limit to be applied: slippage or min amount out
     * @param limitAmount Amount of the swap limit to be applied depending on limitType
     * @param recipient Address that will receive the tokens on the destination chain
     * @param data Extra data that may enable or not different behaviors depending on the implementation
     * @return bridged Amount requested to be bridged after fees
     */
    function bridge(
        uint8 source,
        uint256 chainId,
        address token,
        uint256 amount,
        BridgeLimit limitType,
        uint256 limitAmount,
        address recipient,
        bytes memory data
    ) external returns (uint256 bridged);
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

import '@mimic-fi/v2-registry/contracts/implementations/IImplementation.sol';

/**
 * @title ISmartVaultsFactory
 * @dev Smart Vaults Factory interface, it must follow the IImplementation interface.
 */
interface ISmartVaultsFactory is IImplementation {
    /**
     * @dev Emitted every time a new Smart Vault instance is created
     */
    event Created(address indexed implementation, address indexed instance, bytes initializeResult);

    /**
     * @dev Tells the implementation associated to a contract instance
     * @param instance Address of the instance to request it's implementation
     */
    function implementationOf(address instance) external view returns (address);

    /**
     * @dev Creates a new Smart Vault pointing to a registered implementation
     * @param salt Salt bytes to derivate the address of the new instance
     * @param implementation Address of the implementation to be instanced
     * @param initializeData Arbitrary data to be sent after deployment
     * @return instance Address of the new instance created
     */
    function create(bytes32 salt, address implementation, bytes memory initializeData) external returns (address);
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
import '@openzeppelin/contracts/utils/math/Math.sol';

import '@mimic-fi/v2-bridge-connector/contracts/IBridgeConnector.sol';
import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v2-helpers/contracts/utils/IWrappedNativeToken.sol';
import '@mimic-fi/v2-price-oracle/contracts/oracle/IPriceOracle.sol';
import '@mimic-fi/v2-price-oracle/contracts/feeds/PriceFeedProvider.sol';
import '@mimic-fi/v2-strategies/contracts/IStrategy.sol';
import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';
import '@mimic-fi/v2-registry/contracts/implementations/InitializableAuthorizedImplementation.sol';

import './ISmartVault.sol';
import './helpers/StrategyLib.sol';
import './helpers/SwapConnectorLib.sol';
import './helpers/BridgeConnectorLib.sol';

/**
 * @title Smart Vault
 * @dev Smart Vault contract where funds are being held offering a bunch of primitives to allow users model any
 * type of action to manage them, these are: collector, withdraw, swap, bridge, join, exit, bridge, wrap, and unwrap.
 *
 * It inherits from InitializableAuthorizedImplementation which means it's implementation can be cloned
 * from the Mimic Registry and should be initialized depending on each case.
 */
contract SmartVault is ISmartVault, PriceFeedProvider, InitializableAuthorizedImplementation {
    using SafeERC20 for IERC20;
    using FixedPoint for uint256;
    using UncheckedMath for uint256;
    using StrategyLib for address;
    using SwapConnectorLib for address;
    using BridgeConnectorLib for address;

    // Namespace under which the Smart Vault is registered in the Mimic Registry
    bytes32 public constant override NAMESPACE = keccak256('SMART_VAULT');

    /**
     * @dev Fee configuration parameters
     * @param pct Percentage expressed using 16 decimals (1e18 = 100%)
     * @param cap Maximum amount of fees to be charged per period
     * @param token Address of the token to express the cap amount
     * @param period Period length in seconds
     * @param totalCharged Total amount of fees charged in the current period
     * @param nextResetTime Current cap period end date
     */
    struct Fee {
        uint256 pct;
        uint256 cap;
        address token;
        uint256 period;
        uint256 totalCharged;
        uint256 nextResetTime;
    }

    // Price oracle reference
    address public override priceOracle;

    // Swap connector reference
    address public override swapConnector;

    // Bridge connector reference
    address public override bridgeConnector;

    // List of allowed strategies indexed by strategy address
    mapping (address => bool) public override isStrategyAllowed;

    // List of invested values indexed by strategy address
    mapping (address => uint256) public override investedValue;

    // Fee collector address where fees will be deposited
    address public override feeCollector;

    // Withdraw fee configuration
    Fee public override withdrawFee;

    // Performance fee configuration
    Fee public override performanceFee;

    // Swap fee configuration
    Fee public override swapFee;

    // Bridge fee configuration
    Fee public override bridgeFee;

    // Wrapped native token reference
    address public immutable override wrappedNativeToken;

    /**
     * @dev Creates a new Smart Vault implementation with references that should be shared among all implementations
     * @param _wrappedNativeToken Address of the wrapped native token to be used
     * @param _registry Address of the Mimic Registry to be referenced
     */
    constructor(address _wrappedNativeToken, address _registry) InitializableAuthorizedImplementation(_registry) {
        wrappedNativeToken = _wrappedNativeToken;
    }

    /**
     * @dev Initializes the Smart Vault instance
     * @param admin Address that will be granted with admin rights
     */
    function initialize(address admin) external initializer {
        _initialize(admin);
    }

    /**
     * @dev It allows receiving native token transfers
     */
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets a new strategy as allowed or not for a Smart Vault. Sender must be authorized.
     * @param strategy Address of the strategy to be set
     * @param allowed Whether the strategy is allowed or not
     */
    function setStrategy(address strategy, bool allowed) external override auth {
        _setStrategy(strategy, allowed);
    }

    /**
     * @dev Sets a new price oracle to a Smart Vault. Sender must be authorized.
     * @param newPriceOracle Address of the new price oracle to be set
     */
    function setPriceOracle(address newPriceOracle) external override auth {
        _setPriceOracle(newPriceOracle);
    }

    /**
     * @dev Sets a new swap connector to a Smart Vault. Sender must be authorized.
     * @param newSwapConnector Address of the new swap connector to be set
     */
    function setSwapConnector(address newSwapConnector) external override auth {
        _setSwapConnector(newSwapConnector);
    }

    /**
     * @dev Sets a new bridge connector to a Smart Vault. Sender must be authorized.
     * @param newBridgeConnector Address of the new bridge connector to be set
     */
    function setBridgeConnector(address newBridgeConnector) external override auth {
        _setBridgeConnector(newBridgeConnector);
    }

    /**
     * @dev Sets a new fee collector. Sender must be authorized.
     * @param newFeeCollector Address of the new fee collector to be set
     */
    function setFeeCollector(address newFeeCollector) external override auth {
        _setFeeCollector(newFeeCollector);
    }

    /**
     * @dev Sets a new withdraw fee. Sender must be authorized.
     * @param pct Withdraw fee percentage to be set
     * @param cap New maximum amount of withdraw fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the withdraw fee
     */
    function setWithdrawFee(uint256 pct, uint256 cap, address token, uint256 period) external override auth {
        _setFeeConfiguration(withdrawFee, pct, cap, token, period);
        emit WithdrawFeeSet(pct, cap, token, period);
    }

    /**
     * @dev Sets a new performance fee. Sender must be authorized.
     * @param pct Performance fee percentage to be set
     * @param cap New maximum amount of performance fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the performance fee
     */
    function setPerformanceFee(uint256 pct, uint256 cap, address token, uint256 period) external override auth {
        _setFeeConfiguration(performanceFee, pct, cap, token, period);
        emit PerformanceFeeSet(pct, cap, token, period);
    }

    /**
     * @dev Sets a new swap fee. Sender must be authorized.
     * @param pct New swap fee percentage to be set
     * @param cap New maximum amount of swap fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the swap fee
     */
    function setSwapFee(uint256 pct, uint256 cap, address token, uint256 period) external override auth {
        _setFeeConfiguration(swapFee, pct, cap, token, period);
        emit SwapFeeSet(pct, cap, token, period);
    }

    /**
     * @dev Sets a new bridge fee. Sender must be authorized.
     * @param pct New bridge fee percentage to be set
     * @param cap New maximum amount of bridge fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the bridge fee
     */
    function setBridgeFee(uint256 pct, uint256 cap, address token, uint256 period) external override auth {
        _setFeeConfiguration(bridgeFee, pct, cap, token, period);
        emit BridgeFeeSet(pct, cap, token, period);
    }

    /**
     * @dev Sets a of price feed
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Price feed to be set
     */
    function setPriceFeed(address base, address quote, address feed)
        public
        override(IPriceFeedProvider, PriceFeedProvider)
        auth
    {
        super.setPriceFeed(base, quote, feed);
    }

    /**
     * @dev Tells the price of a token (base) in a given quote
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getPrice(address base, address quote) public view override returns (uint256) {
        return IPriceOracle(priceOracle).getPrice(address(this), base, quote);
    }

    /**
     * @dev Tells the last value accrued for a strategy. Note this value can be outdated.
     * @param strategy Address of the strategy querying the last value of
     */
    function lastValue(address strategy) public view override returns (uint256) {
        return IStrategy(strategy).lastValue(address(this));
    }

    /**
     * @dev Execute an arbitrary call from a Smart Vault. Sender must be authorized.
     * @param target Address where the call will be sent
     * @param data Calldata to be used for the call
     * @param value Value in wei that will be attached to the call
     * @return result Call response if it was successful, otherwise it reverts
     */
    function call(address target, bytes memory callData, uint256 value, bytes memory data)
        external
        override
        auth
        returns (bytes memory result)
    {
        result = Address.functionCallWithValue(target, callData, value, 'SMART_VAULT_ARBITRARY_CALL_FAIL');
        emit Call(target, callData, value, result, data);
    }

    /**
     * @dev Collect tokens from an external account to a Smart Vault. Sender must be authorized.
     * @param token Address of the token to be collected
     * @param from Address where the tokens will be transfer from
     * @param amount Amount of tokens to be transferred
     * @param data Extra data only logged
     * @return collected Amount of tokens collected
     */
    function collect(address token, address from, uint256 amount, bytes memory data)
        external
        override
        auth
        returns (uint256 collected)
    {
        require(amount > 0, 'COLLECT_AMOUNT_ZERO');

        uint256 previousBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(from, address(this), amount);
        uint256 currentBalance = IERC20(token).balanceOf(address(this));

        collected = currentBalance - previousBalance;
        emit Collect(token, from, collected, data);
    }

    /**
     * @dev Withdraw tokens to an external account. Sender must be authorized.
     * @param token Address of the token to be withdrawn
     * @param amount Amount of tokens to withdraw
     * @param recipient Address where the tokens will be transferred to
     * @param data Extra data only logged
     * @return withdrawn Amount of tokens transferred to the recipient address
     */
    function withdraw(address token, uint256 amount, address recipient, bytes memory data)
        external
        override
        auth
        returns (uint256 withdrawn)
    {
        require(amount > 0, 'WITHDRAW_AMOUNT_ZERO');
        require(recipient != address(0), 'RECIPIENT_ZERO');

        uint256 withdrawFeeAmount = recipient == feeCollector ? 0 : _payFee(token, amount, withdrawFee);
        withdrawn = amount - withdrawFeeAmount;
        _safeTransfer(token, recipient, withdrawn);
        emit Withdraw(token, recipient, withdrawn, withdrawFeeAmount, data);
    }

    /**
     * @dev Wrap an amount of native tokens to the wrapped ERC20 version of it. Sender must be authorized.
     * @param amount Amount of native tokens to be wrapped
     * @param data Extra data only logged
     * @return wrapped Amount of tokens wrapped
     */
    function wrap(uint256 amount, bytes memory data) external override auth returns (uint256 wrapped) {
        require(amount > 0, 'WRAP_AMOUNT_ZERO');
        require(address(this).balance >= amount, 'WRAP_INSUFFICIENT_AMOUNT');

        IWrappedNativeToken wrappedToken = IWrappedNativeToken(wrappedNativeToken);
        uint256 previousBalance = wrappedToken.balanceOf(address(this));
        wrappedToken.deposit{ value: amount }();
        uint256 currentBalance = wrappedToken.balanceOf(address(this));

        wrapped = currentBalance - previousBalance;
        emit Wrap(amount, wrapped, data);
    }

    /**
     * @dev Unwrap an amount of wrapped native tokens. Sender must be authorized.
     * @param amount Amount of wrapped native tokens to unwrapped
     * @param data Extra data only logged
     * @return unwrapped Amount of tokens unwrapped
     */
    function unwrap(uint256 amount, bytes memory data) external override auth returns (uint256 unwrapped) {
        require(amount > 0, 'UNWRAP_AMOUNT_ZERO');

        uint256 previousBalance = address(this).balance;
        IWrappedNativeToken(wrappedNativeToken).withdraw(amount);
        uint256 currentBalance = address(this).balance;

        unwrapped = currentBalance - previousBalance;
        emit Unwrap(amount, unwrapped, data);
    }

    /**
     * @dev Claim strategy rewards. Sender must be authorized.
     * @param strategy Address of the strategy to claim rewards
     * @param data Extra data passed to the strategy and logged
     * @return tokens Addresses of the tokens received as rewards
     * @return amounts Amounts of the tokens received as rewards
     */
    function claim(address strategy, bytes memory data)
        external
        override
        auth
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        require(isStrategyAllowed[strategy], 'STRATEGY_NOT_ALLOWED');
        (tokens, amounts) = strategy.claim(data);
        emit Claim(strategy, tokens, amounts, data);
    }

    /**
     * @dev Join a strategy with an amount of tokens. Sender must be authorized.
     * @param strategy Address of the strategy to join
     * @param tokensIn List of token addresses to join with
     * @param amountsIn List of token amounts to join with
     * @param slippage Slippage that will be used to compute the join
     * @param data Extra data passed to the strategy and logged
     * @return tokensOut List of token addresses received after the join
     * @return amountsOut List of token amounts received after the join
     */
    function join(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) external override auth returns (address[] memory tokensOut, uint256[] memory amountsOut) {
        require(isStrategyAllowed[strategy], 'STRATEGY_NOT_ALLOWED');
        require(slippage <= FixedPoint.ONE, 'JOIN_SLIPPAGE_ABOVE_ONE');
        require(tokensIn.length == amountsIn.length, 'JOIN_INPUT_INVALID_LENGTH');

        uint256 value;
        (tokensOut, amountsOut, value) = strategy.join(tokensIn, amountsIn, slippage, data);
        require(tokensOut.length == amountsOut.length, 'JOIN_OUTPUT_INVALID_LENGTH');

        investedValue[strategy] = investedValue[strategy] + value;
        emit Join(strategy, tokensIn, amountsIn, tokensOut, amountsOut, value, slippage, data);
    }

    /**
     * @dev Exit a strategy. Sender must be authorized.
     * @param strategy Address of the strategy to exit
     * @param tokensIn List of token addresses to exit with
     * @param amountsIn List of token amounts to exit with
     * @param slippage Slippage that will be used to compute the exit
     * @param data Extra data passed to the strategy and logged
     * @return tokensOut List of token addresses received after the exit
     * @return amountsOut List of token amounts received after the exit
     */
    function exit(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) external override auth returns (address[] memory tokensOut, uint256[] memory amountsOut) {
        require(isStrategyAllowed[strategy], 'STRATEGY_NOT_ALLOWED');
        require(investedValue[strategy] > 0, 'EXIT_NO_INVESTED_VALUE');
        require(slippage <= FixedPoint.ONE, 'EXIT_SLIPPAGE_ABOVE_ONE');
        require(tokensIn.length == amountsIn.length, 'EXIT_INPUT_INVALID_LENGTH');

        uint256 value;
        (tokensOut, amountsOut, value) = strategy.exit(tokensIn, amountsIn, slippage, data);
        require(tokensOut.length == amountsOut.length, 'EXIT_OUTPUT_INVALID_LENGTH');
        uint256[] memory performanceFeeAmounts = new uint256[](amountsOut.length);

        // It can rely on the last updated value since we have just exited, no need to compute current value
        uint256 valueBeforeExit = lastValue(strategy) + value;
        if (valueBeforeExit <= investedValue[strategy]) {
            // There were losses, invested value is simply reduced using the exited ratio compared to the value
            // before exit. Invested value is round up to avoid interpreting losses due to rounding errors
            investedValue[strategy] -= investedValue[strategy].mulUp(value).divUp(valueBeforeExit);
        } else {
            // If value gains are greater than the exit value, it means only gains are being withdrawn. In that case
            // the taxable amount is the entire exited amount, otherwise it should be the equivalent gains ratio of it.
            uint256 valueGains = valueBeforeExit.uncheckedSub(investedValue[strategy]);
            bool onlyGains = valueGains >= value;

            // If the exit value is greater than the value gains, the invested value should be reduced by the portion
            // of the invested value being exited. Otherwise, it's still the same, only gains are being withdrawn.
            // No need for checked math as we are checking it manually beforehand
            uint256 decrement = onlyGains ? 0 : value.uncheckedSub(valueGains);
            investedValue[strategy] = investedValue[strategy] - decrement;

            // Compute performance fees per token out
            for (uint256 i = 0; i < tokensOut.length; i = i.uncheckedAdd(1)) {
                address token = tokensOut[i];
                uint256 amount = amountsOut[i];
                uint256 taxableAmount = onlyGains ? amount : ((amount * valueGains) / value);
                uint256 feeAmount = _payFee(token, taxableAmount, performanceFee);
                amountsOut[i] = amount - feeAmount;
                performanceFeeAmounts[i] = feeAmount;
            }
        }

        emit Exit(strategy, tokensIn, amountsIn, tokensOut, amountsOut, value, performanceFeeAmounts, slippage, data);
    }

    /**
     * @dev Swaps two tokens. Sender must be authorized.
     * @param source Source to request the swap: Uniswap V2, Uniswap V3, Balancer V2, or Paraswap V5.
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param limitType Swap limit to be applied: slippage or min amount out
     * @param limitAmount Amount of the swap limit to be applied depending on limitType
     * @param data Encoded data to specify different swap parameters depending on the source picked
     * @return amountOut Received amount of tokens out
     */
    function swap(
        uint8 source,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        SwapLimit limitType,
        uint256 limitAmount,
        bytes memory data
    ) external override auth returns (uint256 amountOut) {
        require(tokenIn != tokenOut, 'SWAP_SAME_TOKEN');
        require(swapConnector != address(0), 'SWAP_CONNECTOR_NOT_SET');

        uint256 minAmountOut;
        if (limitType == SwapLimit.MinAmountOut) {
            minAmountOut = limitAmount;
        } else if (limitType == SwapLimit.Slippage) {
            require(limitAmount <= FixedPoint.ONE, 'SWAP_SLIPPAGE_ABOVE_ONE');
            uint256 price = getPrice(tokenIn, tokenOut);
            // No need for checked math as we are checking it manually beforehand
            // Always round up the expected min amount out. Limit amount is slippage.
            minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE.uncheckedSub(limitAmount));
        } else {
            revert('SWAP_INVALID_LIMIT_TYPE');
        }

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        swapConnector.swap(source, tokenIn, tokenOut, amountIn, minAmountOut, data);

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'SWAP_BAD_TOKEN_IN_BALANCE');

        uint256 amountOutBeforeFees = IERC20(tokenOut).balanceOf(address(this)) - preBalanceOut;
        require(amountOutBeforeFees >= minAmountOut, 'SWAP_MIN_AMOUNT');

        uint256 swapFeeAmount = _payFee(tokenOut, amountOutBeforeFees, swapFee);
        amountOut = amountOutBeforeFees - swapFeeAmount;
        emit Swap(source, tokenIn, tokenOut, amountIn, amountOut, minAmountOut, swapFeeAmount, data);
    }

    /**
     * @dev Bridge assets to another chain
     * @param source Source to request the bridge. It depends on the Bridge Connector attached to a Smart Vault.
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param limitType Bridge limit to be applied: slippage or min amount out
     * @param limitAmount Amount of the swap limit to be applied depending on limitType
     * @param recipient Address that will receive the tokens on the destination chain
     * @param data Encoded data to specify different bridge parameters depending on the source picked
     * @return bridged Amount requested to be bridged after fees
     */
    function bridge(
        uint8 source,
        uint256 chainId,
        address token,
        uint256 amount,
        BridgeLimit limitType,
        uint256 limitAmount,
        address recipient,
        bytes memory data
    ) external override auth returns (uint256 bridged) {
        require(block.chainid != chainId, 'BRIDGE_SAME_CHAIN');
        require(recipient != address(0), 'BRIDGE_RECIPIENT_ZERO');
        require(bridgeConnector != address(0), 'BRIDGE_CONNECTOR_NOT_SET');

        uint256 bridgeFeeAmount = _payFee(token, amount, bridgeFee);
        bridged = amount - bridgeFeeAmount;

        uint256 minAmountOut;
        if (limitType == BridgeLimit.MinAmountOut) {
            minAmountOut = limitAmount;
        } else if (limitType == BridgeLimit.Slippage) {
            require(limitAmount <= FixedPoint.ONE, 'BRIDGE_SLIPPAGE_ABOVE_ONE');
            // No need for checked math as we are checking it manually beforehand
            // Always round up the expected min amount out. Limit amount is slippage.
            minAmountOut = bridged.mulUp(FixedPoint.ONE.uncheckedSub(limitAmount));
        } else {
            revert('BRIDGE_INVALID_LIMIT_TYPE');
        }

        uint256 preBalanceIn = IERC20(token).balanceOf(address(this));
        bridgeConnector.bridge(source, chainId, token, bridged, minAmountOut, recipient, data);
        uint256 postBalanceIn = IERC20(token).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - bridged, 'BRIDGE_BAD_TOKEN_IN_BALANCE');

        emit Bridge(source, chainId, token, bridged, minAmountOut, bridgeFeeAmount, recipient, data);
    }

    /**
     * @dev Internal function to pay the amount of fees to be charged based on a fee configuration to the fee collector
     * @param token Token being charged
     * @param amount Token amount to be taxed with fees
     * @param fee Fee configuration to be applied
     * @return paidAmount Amount of fees paid to the fee collector
     */
    function _payFee(address token, uint256 amount, Fee storage fee) internal returns (uint256 paidAmount) {
        // Fee amounts are always rounded down
        uint256 feeAmount = amount.mulDown(fee.pct);

        // If cap amount or cap period are not set, charge the entire amount
        if (fee.token == address(0) || fee.cap == 0 || fee.period == 0) {
            _safeTransfer(token, feeCollector, feeAmount);
            return feeAmount;
        }

        // Reset cap totalizator if necessary
        if (block.timestamp >= fee.nextResetTime) {
            fee.totalCharged = 0;
            fee.nextResetTime = block.timestamp + fee.period;
        }

        // Calc fee amount in the fee token used for the cap
        uint256 feeTokenPrice = getPrice(token, fee.token);
        uint256 feeAmountInFeeToken = feeAmount.mulDown(feeTokenPrice);

        // Compute fee amount picking the minimum between the chargeable amount and the remaining part for the cap
        if (fee.totalCharged + feeAmountInFeeToken <= fee.cap) {
            paidAmount = feeAmount;
            fee.totalCharged += feeAmountInFeeToken;
        } else if (fee.totalCharged < fee.cap) {
            paidAmount = (fee.cap.uncheckedSub(fee.totalCharged) * feeAmount) / feeAmountInFeeToken;
            fee.totalCharged = fee.cap;
        } else {
            // This case is when the total charged amount is already greater than the cap amount. It could happen if
            // the cap amounts is decreased or if the cap token is changed. In this case the total charged amount is
            // not updated, and the amount to paid is zero.
            paidAmount = 0;
        }

        // Pay fee amount to the fee collector
        _safeTransfer(token, feeCollector, paidAmount);
    }

    /**
     * @dev Internal method to transfer ERC20 or native tokens from a Smart Vault
     * @param token Address of the ERC20 token to transfer
     * @param to Address transferring the tokens to
     * @param amount Amount of tokens to transfer
     */
    function _safeTransfer(address token, address to, uint256 amount) internal {
        if (amount == 0) return;
        if (Denominations.isNativeToken(token)) Address.sendValue(payable(to), amount);
        else IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev Sets a new strategy as allowed or not
     * @param strategy Address of the strategy to be set
     * @param allowed Whether the strategy is allowed or not
     */
    function _setStrategy(address strategy, bool allowed) internal {
        if (allowed) _validateStatelessDependency(strategy);
        isStrategyAllowed[strategy] = allowed;
        emit StrategySet(strategy, allowed);
    }

    /**
     * @dev Sets a new price oracle
     * @param newPriceOracle New price oracle to be set
     */
    function _setPriceOracle(address newPriceOracle) internal {
        _validateStatelessDependency(newPriceOracle);
        priceOracle = newPriceOracle;
        emit PriceOracleSet(newPriceOracle);
    }

    /**
     * @dev Sets a new swap connector
     * @param newSwapConnector New swap connector to be set
     */
    function _setSwapConnector(address newSwapConnector) internal {
        _validateStatelessDependency(newSwapConnector);
        swapConnector = newSwapConnector;
        emit SwapConnectorSet(newSwapConnector);
    }

    /**
     * @dev Sets a new bridge connector
     * @param newBridgeConnector New bridge connector to be set
     */
    function _setBridgeConnector(address newBridgeConnector) internal {
        _validateStatelessDependency(newBridgeConnector);
        bridgeConnector = newBridgeConnector;
        emit BridgeConnectorSet(newBridgeConnector);
    }

    /**
     * @dev Internal method to set the fee collector
     * @param newFeeCollector New fee collector to be set
     */
    function _setFeeCollector(address newFeeCollector) internal {
        require(newFeeCollector != address(0), 'FEE_COLLECTOR_ZERO');
        feeCollector = newFeeCollector;
        emit FeeCollectorSet(newFeeCollector);
    }

    /**
     * @dev Internal method to set a new fee cap configuration
     * @param fee Fee configuration to be updated
     * @param pct Fee percentage to be set
     * @param cap New maximum amount of fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds
     */
    function _setFeeConfiguration(Fee storage fee, uint256 pct, uint256 cap, address token, uint256 period) internal {
        require(pct <= FixedPoint.ONE, 'FEE_PCT_ABOVE_ONE');

        // If there is no fee percentage, there must not be a fee cap
        bool isZeroCap = token == address(0) && cap == 0 && period == 0;
        require(pct != 0 || isZeroCap, 'INVALID_CAP_WITH_FEE_ZERO');

        // If there is a cap, all values must be non-zero
        bool isNonZeroCap = token != address(0) && cap != 0 && period != 0;
        require(isZeroCap || isNonZeroCap, 'INCONSISTENT_CAP_VALUES');

        // Changing the fee percentage does not affect the totalizator at all, it only affects future fee charges
        fee.pct = pct;

        // Changing the fee cap amount does not affect the totalizator, it only applies when changing the for the total
        // charged amount. Note that it can happen that the cap amount is lower than the total charged amount if the
        // cap amount is lowered. However, there shouldn't be any accounting issues with that.
        fee.cap = cap;

        // Changing the cap period only affects the end time of the next period, but not the end date of the current one
        fee.period = period;

        // Therefore, only clean the totalizators if the cap is being removed
        if (isZeroCap) {
            fee.totalCharged = 0;
            fee.nextResetTime = 0;
        } else {
            // If cap values are not zero, set the next reset time if it wasn't set already
            // Otherwise, if the cap token is being changed the total charged amount must be updated accordingly
            if (fee.nextResetTime == 0) {
                fee.nextResetTime = block.timestamp + period;
            } else if (fee.token != token) {
                uint256 newTokenPrice = getPrice(fee.token, token);
                fee.totalCharged = fee.totalCharged.mulDown(newTokenPrice);
            }
        }

        // Finally simply set the new requested token
        fee.token = token;
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
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '@mimic-fi/v2-smart-vault/contracts/ISmartVault.sol';
import '@mimic-fi/v2-helpers/contracts/auth/Authorizer.sol';
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v2-helpers/contracts/utils/ERC20Helpers.sol';
import '@mimic-fi/v2-registry/contracts/implementations/BaseAuthorizedImplementation.sol';

import './IAction.sol';
import 'hardhat/console.sol';

/**
 * @title BaseAction
 * @dev Simple action implementation with a Smart Vault reference and using the Authorizer mixin
 */
contract BaseAction is IAction, BaseAuthorizedImplementation, ReentrancyGuard {
    bytes32 public constant override NAMESPACE = keccak256('ACTION');

    // Smart Vault reference
    ISmartVault public override smartVault;

    /**
     * @dev Emitted every time a new smart vault is set
     */
    event SmartVaultSet(address indexed smartVault);

    /**
     * @dev Creates a new BaseAction
     * @param admin Address to be granted authorize and unauthorize permissions
     * @param registry Address of the Mimic Registry
     */
    constructor(address admin, address registry) BaseAuthorizedImplementation(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets the Smart Vault tied to the Action. Sender must be authorized. It can be set only once.
     * @param newSmartVault Address of the smart vault to be set
     */
    function setSmartVault(address newSmartVault) external auth {
        require(address(smartVault) == address(0), 'SMART_VAULT_ALREADY_SET');
        smartVault = ISmartVault(newSmartVault);
        emit SmartVaultSet(newSmartVault);
    }

    /**
     * @dev Tells the balance of the Smart Vault for a given token
     * @param token Address of the token querying the balance of
     * @notice Denominations.NATIVE_TOKEN_ADDRESS can be used to query the native token balance
     */
    function _balanceOf(address token) internal view returns (uint256) {
        return ERC20Helpers.balanceOf(token, address(smartVault));
    }

    /**
     * @dev Tells the wrapped native token address if the given address is the native token
     * @param token Address of the token to be checked
     */
    function _wrappedIfNative(address token) internal view returns (address) {
        return Denominations.isNativeToken(token) ? smartVault.wrappedNativeToken() : token;
    }

    /**
     * @dev Tells whether the given token is either the native or wrapped native token
     * @param token Address of the token being queried
     */
    function _isWrappedOrNativeToken(address token) internal view returns (bool) {
        return Denominations.isNativeToken(token) || token == smartVault.wrappedNativeToken();
    }

    /**
     * @dev Internal function to fetch prices for a base-quote pair. The default implementation tries to fetch it from
     * the Smart Vault's price oracle but it can be overridden to specify a different use case.
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256) {
        return smartVault.getPrice(base, quote);
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

import '@mimic-fi/v2-smart-vault/contracts/ISmartVault.sol';
import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';

/**
 * @title IAction
 * @dev Action interface it must follow the IAuthorizer interface
 */
interface IAction is IAuthorizer {
    /**
     * @dev Emitted every time an action is executed
     */
    event Executed();

    /**
     * @dev Tells the address of the Smart Vault tied to it, it cannot be changed
     */
    function smartVault() external view returns (ISmartVault);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './BaseAction.sol';

/**
 * @dev Action that can work with off-chain passed feed data from trusted oracles.
 * It relies on a specific "extra-calldata" layout as follows:
 *
 * [ feed 1 | feed 2 | ... | feed n | n | v | r | s ]
 *
 * For simplicity, we use full 256 bit slots for 'n', 'v', 'r', and 's' values.
 * Note that 'n' denotes the number of encoded feeds, while [v,r,s] denote the corresponding oracle signature.
 * Each feed has the following 4-words layout:
 *
 * [ base | quote | rate | deadline ]
 */
abstract contract OracledAction is BaseAction {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Feed data
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param rate Price of a token (base) expressed in `quote`. It must use the corresponding number of decimals so
     *             that when performing a fixed point product of it by a `base` amount, the result is expressed in
     *             `quote` decimals. For example, if `base` is ETH and `quote` is USDC, the number of decimals of `rate`
     *             must be 6: FixedPoint.mul(X[ETH], rate[USDC/ETH]) = FixedPoint.mul(X[18], price[6]) = X * price [6].
     * @param deadline Expiration timestamp until when the given quote is considered valid
     */
    struct FeedData {
        address base;
        address quote;
        uint256 rate;
        uint256 deadline;
    }

    // Enumerable set of trusted signers
    EnumerableSet.AddressSet private signers;

    /**
     * @dev Emitted every time a signer condition is changed
     */
    event OracleSignerSet(address indexed signer, bool allowed);

    /**
     * @dev Change an oracle signer condition
     * @param signer Address of the signer being queried
     * @param allowed Whether the signer should be allowed or not
     * @return success True if the signer was actually added or removed from the list of oracle signers
     */
    function setOracleSigner(address signer, bool allowed) external auth returns (bool success) {
        require(signer != address(0), 'ORACLED_SIGNER_ZERO');
        success = allowed ? signers.add(signer) : signers.remove(signer);
        if (success) emit OracleSignerSet(signer, allowed);
    }

    /**
     * @dev Tells the list of oracle signers
     */
    function getOracleSigners() external view returns (address[] memory) {
        return signers.values();
    }

    /**
     * @dev Tells whether an address is as an oracle signer or not
     * @param signer Address of the signer being queried
     */
    function isOracleSigner(address signer) public view returns (bool) {
        return signers.contains(signer);
    }

    /**
     * @dev Hashes the list of feeds
     * @param feeds List of feeds to be hashed
     */
    function getFeedsDigest(FeedData[] memory feeds) public pure returns (bytes32) {
        return keccak256(abi.encode(feeds));
    }

    /**
     * @dev Tries fetching a price for base/quote pair from any potential encoded off-chain oracle data. Otherwise
     * it fallbacks to the smart vault's price oracle. Off-chain oracle data is only used when it can be trusted, this
     * is: well-formed, signed by an allowed oracle, and up-to-date.
     */
    function _getPrice(address base, address quote) internal view virtual override returns (uint256) {
        (FeedData[] memory feeds, address signer) = _getEncodedOracleData();

        if (signer != address(0) && isOracleSigner(signer)) {
            for (uint256 i = 0; i < feeds.length; i++) {
                FeedData memory feed = feeds[i];
                if (feed.base == base && feed.quote == quote) {
                    require(feed.deadline >= block.timestamp, 'ORACLE_FEED_OUTDATED');
                    return feed.rate;
                }
            }
        }

        return smartVault.getPrice(base, quote);
    }

    /**
     * @dev Decodes any potential encoded off-chain oracle data.
     * @return feeds List of feeds encoded in the extra calldata.
     * @return signer Address recovered from the encoded signature in the extra calldata. A zeroed address is invalid.
     */
    function _getEncodedOracleData() private pure returns (FeedData[] memory feeds, address signer) {
        feeds = _getOracleFeeds();
        bytes32 message = ECDSA.toEthSignedMessageHash(getFeedsDigest(feeds));
        uint8 v = _getOracleSignatureV();
        bytes32 r = _getOracleSignatureR();
        bytes32 s = _getOracleSignatureS();
        signer = ecrecover(message, v, r, s);
    }

    /**
     * @dev Extracts the list of feeds encoded in the extra calldata. This function returns bogus data if there is no
     * extra calldata in place. The last feed is stored using the first four words right before the feeds length.
     */
    function _getOracleFeeds() private pure returns (FeedData[] memory feeds) {
        feeds = new FeedData[](_getFeedsLength());
        for (uint256 i = 0; i < feeds.length; i++) {
            uint256 pos = 4 * (feeds.length - i);
            FeedData memory feed = feeds[i];
            feed.base = address(uint160(uint256(_decodeCalldataWord(pos + 3))));
            feed.quote = address(uint160(uint256(_decodeCalldataWord(pos + 2))));
            feed.rate = uint256(_decodeCalldataWord(pos + 1));
            feed.deadline = uint256(_decodeCalldataWord(pos));
        }
    }

    /**
     * @dev Extracts the number of feeds encoded in the extra calldata. This function returns bogus data if there is no
     * extra calldata in place. The number of encoded feeds is encoded in the 4th word from the calldata end.
     */
    function _getFeedsLength() private pure returns (uint256) {
        return uint256(_decodeCalldataWord(3));
    }

    /**
     * @dev Extracts the component V of the oracle signature parameter from extra calldata. This function returns bogus
     * data if no signature is included. This is not a security risk, as that data would not be considered a valid
     * signature in the first place. The component V is encoded in the 3rd word from the calldata end.
     */
    function _getOracleSignatureV() private pure returns (uint8) {
        return uint8(uint256(_decodeCalldataWord(2)));
    }

    /**
     * @dev Extracts the component R of the oracle signature parameter from extra calldata. This function returns bogus
     * data if no signature is included. This is not a security risk, as that data would not be considered a valid
     * signature in the first place. The component R is encoded in the 2nd word from the calldata end.
     */
    function _getOracleSignatureR() private pure returns (bytes32) {
        return _decodeCalldataWord(1);
    }

    /**
     * @dev Extracts the component S of the oracle signature parameter from extra calldata. This function returns bogus
     * data if no signature is included. This is not a security risk, as that data would not be considered a valid
     * signature in the first place. The component S is encoded in the last word from the calldata end.
     */
    function _getOracleSignatureS() private pure returns (bytes32) {
        return _decodeCalldataWord(0);
    }

    /**
     * @dev Returns the nth 256 bit word starting from the calldata end (0 means the last calldata word).
     * This function returns bogus data if no signature is included.
     */
    function _decodeCalldataWord(uint256 n) private pure returns (bytes32 result) {
        assembly {
            result := calldataload(sub(calldatasize(), mul(0x20, add(n, 1))))
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

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './BaseAction.sol';

abstract contract ReceiverAction is BaseAction {
    using SafeERC20 for IERC20;

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    function transferToSmartVault(address token, uint256 amount) external auth {
        _transferToSmartVault(token, amount);
    }

    function _transferToSmartVault(address token, uint256 amount) internal {
        ERC20Helpers.transfer(token, address(smartVault), amount);
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

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';

import './BaseAction.sol';

/**
 * @title RelayedAction
 * @dev Action that offers a relayed mechanism to allow reimbursing tx costs after execution in any ERC20 token.
 * This type of action at least require having withdraw permissions from the Smart Vault tied to it.
 */
abstract contract RelayedAction is BaseAction {
    using FixedPoint for uint256;

    // Base gas amount charged to cover default amounts
    // solhint-disable-next-line func-name-mixedcase
    function BASE_GAS() external view virtual returns (uint256);

    // Note to be used to mark tx cost payments
    bytes private constant REDEEM_GAS_NOTE = bytes('RELAYER');

    // Internal variable used to allow a better developer experience to reimburse tx gas cost
    uint256 private _initialGas;

    // Gas price limit expressed in the native token, if surpassed it wont relay the transaction
    uint256 public gasPriceLimit;

    // Total transaction cost limit expressed in the native token, if surpassed it wont relay the transaction
    uint256 public txCostLimit;

    // Allows relaying transactions even if there is not enough balance in the Smart Vault to pay for the tx gas cost
    bool public isPermissiveRelayedModeActive;

    // List of allowed relayers indexed by address
    mapping (address => bool) public isRelayer;

    /**
     * @dev Emitted every time the relayers list is changed
     */
    event RelayerSet(address indexed relayer, bool allowed);

    /**
     * @dev Emitted every time the relayer limits are set
     */
    event LimitsSet(uint256 gasPriceLimit, uint256 txCostLimit);

    /**
     * @dev Emitted every time the permissive relayed mode is changed
     */
    event PermissiveRelayedModeSet(bool active);

    /**
     * @dev Modifier that can be used to reimburse the gas cost of the tagged function paying in a specific token
     */
    modifier redeemGas(address token) {
        _initRelayedTx();
        _;
        _payRelayedTx(token);
    }

    /**
     * @dev Sets a relayer address. Sender must be authorized.
     * @param relayer Address of the relayer to be set
     * @param allowed Whether it should be allowed or not
     */
    function setRelayer(address relayer, bool allowed) external auth {
        isRelayer[relayer] = allowed;
        emit RelayerSet(relayer, allowed);
    }

    /**
     * @dev Sets the relayed action permissive relayed mode. If active, it won't fail when trying to redeem gas costs to the
     * relayer if the smart vault does not have enough balance. Sender must be authorized.
     * @param active Whether the permissive relayed mode should be active or not
     */
    function setPermissiveRelayedMode(bool active) external auth {
        isPermissiveRelayedModeActive = active;
        emit PermissiveRelayedModeSet(active);
    }

    /**
     * @dev Sets the relayer limits. Sender must be authorized.
     * @param _gasPriceLimit New gas price limit to be set
     * @param _txCostLimit New total cost limit to be set
     */
    function setLimits(uint256 _gasPriceLimit, uint256 _txCostLimit) external auth {
        gasPriceLimit = _gasPriceLimit;
        txCostLimit = _txCostLimit;
        emit LimitsSet(_gasPriceLimit, _txCostLimit);
    }

    /**
     * @dev Internal init hook used for relayed txs. It checks tx limit validations only when the sender is a relayer.
     */
    function _initRelayedTx() internal {
        if (!isRelayer[msg.sender]) return;
        _initialGas = gasleft();
        uint256 limit = gasPriceLimit;
        require(limit == 0 || tx.gasprice <= limit, 'GAS_PRICE_ABOVE_LIMIT');
    }

    /**
     * @dev Internal function to pay for a relayed tx. Only when the sender is marked as a relayer.
     * @param token Address of the token to use in order to pay the tx cost
     * @return Amount of tokens paid to reimburse the tx cost
     */
    function _payRelayedTx(address token) internal returns (uint256) {
        if (!isRelayer[msg.sender]) return 0;
        require(_initialGas > 0, 'RELAYED_TX_NOT_INITIALIZED');

        uint256 limit = txCostLimit;
        uint256 totalGas = _initialGas - gasleft();
        uint256 totalCostNative = (totalGas + RelayedAction(this).BASE_GAS()) * tx.gasprice;
        require(limit == 0 || totalCostNative <= limit, 'TX_COST_ABOVE_LIMIT');

        // Total cost is rounded down to make sure we always match at least the threshold
        uint256 price = _getNativeTokenPriceIn(token);
        uint256 totalCostToken = totalCostNative.mulDown(price);
        if (_balanceOf(token) >= totalCostToken || !isPermissiveRelayedModeActive) {
            smartVault.withdraw(token, totalCostToken, smartVault.feeCollector(), REDEEM_GAS_NOTE);
        }

        delete _initialGas;
        return totalCostToken;
    }

    /**
     * @dev Tells the price of the native token quoted in a another token
     * @param token Address of the token to quote the native token in
     */
    function _getNativeTokenPriceIn(address token) private view returns (uint256) {
        if (_isWrappedOrNativeToken(token)) return FixedPoint.ONE;
        return _getPrice(smartVault.wrappedNativeToken(), token);
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

import './BaseAction.sol';

/**
 * @title Time-locked action
 * @dev Action that offers a time-lock mechanism to allow executing it only once during a set period of time
 */
abstract contract TimeLockedAction is BaseAction {
    // Period in seconds
    uint256 public period;

    // Next timestamp in the future when the action can be executed again
    uint256 public nextResetTime;

    /**
     * @dev Emitted every time a time-lock is set
     */
    event TimeLockSet(uint256 period);

    /**
     * @dev Creates a new time-locked action
     */
    constructor() {
        nextResetTime = block.timestamp;
    }

    /**
     * @dev Sets a new period for the time-locked action
     * @param newPeriod New period to be set
     */
    function setTimeLock(uint256 newPeriod) external auth {
        period = newPeriod;
        emit TimeLockSet(newPeriod);
    }

    /**
     * @dev Internal function to tell whether the current time-lock has passed
     */
    function _passesTimeLock() internal view returns (bool) {
        return block.timestamp >= nextResetTime;
    }

    /**
     * @dev Internal function to validate the time-locked action
     */
    function _validateTimeLock() internal {
        require(_passesTimeLock(), 'TIME_LOCK_NOT_EXPIRED');
        nextResetTime = block.timestamp + period;
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

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';

import './BaseAction.sol';

/**
 * @title TokenThresholdAction
 * @dev Action that offers a token threshold limit. It can be used for minimum swap amounts, or minimum withdrawal
 * amounts, etc. This type of action does not require any specific permission on the Smart Vault.
 */
abstract contract TokenThresholdAction is BaseAction {
    using FixedPoint for uint256;

    address public thresholdToken;
    uint256 public thresholdAmount;

    event ThresholdSet(address indexed token, uint256 amount);

    /**
     * @dev Sets a new threshold configuration. Sender must be authorized.
     * @param token New token threshold to be set
     * @param amount New amount threshold to be set
     */
    function setThreshold(address token, uint256 amount) external auth {
        thresholdToken = token;
        thresholdAmount = amount;
        emit ThresholdSet(token, amount);
    }

    /**
     * @dev Internal function to check the set threshold
     * @param token Token address of the given amount to evaluate the threshold
     * @param amount Amount of tokens to validate the threshold
     */
    function _passesThreshold(address token, uint256 amount) internal view returns (bool) {
        uint256 price = _getPrice(_wrappedIfNative(token), thresholdToken);
        // Result balance is rounded down to make sure we always match at least the threshold
        return amount.mulDown(price) >= thresholdAmount;
    }

    /**
     * @dev Internal function to validate the set threshold
     * @param token Token address of the given amount to evaluate the threshold
     * @param amount Amount of tokens to validate the threshold
     */
    function _validateThreshold(address token, uint256 amount) internal view {
        require(_passesThreshold(token, amount), 'MIN_THRESHOLD_NOT_MET');
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

import './BaseAction.sol';

/**
 * @title Withdrawal action
 * @dev Action that offers a recipient address where funds can be withdrawn. This type of action at least require
 * having withdraw permissions from the Smart Vault tied to it.
 */
abstract contract WithdrawalAction is BaseAction {
    // Address where tokens will be transferred to
    address public recipient;

    /**
     * @dev Emitted every time the recipient is set
     */
    event RecipientSet(address indexed recipient);

    /**
     * @dev Sets the recipient address. Sender must be authorized.
     * @param newRecipient Address of the new recipient to be set
     */
    function setRecipient(address newRecipient) external auth {
        require(newRecipient != address(0), 'RECIPIENT_ZERO');
        recipient = newRecipient;
        emit RecipientSet(newRecipient);
    }

    /**
     * @dev Internal function to withdraw all the available balance of a token from the Smart Vault to the recipient
     * @param token Address of the token to be withdrawn
     */
    function _withdraw(address token) internal {
        uint256 balance = _balanceOf(token);
        _withdraw(token, balance);
    }

    /**
     * @dev Internal function to withdraw a specific amount of a token from the Smart Vault to the recipient
     * @param token Address of the token to be withdrawn
     * @param amount Amount of tokens to be withdrawn
     */
    function _withdraw(address token, uint256 amount) internal {
        smartVault.withdraw(token, amount, recipient, new bytes(0));
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

import '@openzeppelin/contracts/access/Ownable.sol';

import './Deployer.sol';
import '../permissions/PermissionsManager.sol';

contract BaseDeployer is Ownable {
    event PermissionsManagerDeployed(address permissionsManager);

    constructor(address owner) {
        _transferOwnership(owner);
    }

    function deployPermissionsManager(address admin) external onlyOwner {
        PermissionsManager manager = Deployer.createPermissionsManager(admin);
        emit PermissionsManagerDeployed(address(manager));
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

import '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v2-smart-vault/contracts/ISmartVaultsFactory.sol';
import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';
import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';

import '../actions/ReceiverAction.sol';
import '../actions/RelayedAction.sol';
import '../actions/TimeLockedAction.sol';
import '../actions/TokenThresholdAction.sol';
import '../actions/WithdrawalAction.sol';
import '../permissions/PermissionsManager.sol';
import '../permissions/PermissionsHelpers.sol';

/**
 * @title Deployer
 * @dev Deployer library offering a bunch of set-up methods to deploy and customize smart vaults
 */
library Deployer {
    using UncheckedMath for uint256;
    using PermissionsHelpers for PermissionsManager;

    // Namespace to use by this deployer to fetch ISmartVaultFactory implementations from the Mimic Registry
    bytes32 private constant SMART_VAULT_FACTORY_NAMESPACE = keccak256('SMART_VAULTS_FACTORY');

    // Namespace to use by this deployer to fetch ISmartVault implementations from the Mimic Registry
    bytes32 private constant SMART_VAULT_NAMESPACE = keccak256('SMART_VAULT');

    // Namespace to use by this deployer to fetch IStrategy implementations from the Mimic Registry
    bytes32 private constant STRATEGY_NAMESPACE = keccak256('STRATEGY');

    // Namespace to use by this deployer to fetch IPriceOracle implementations from the Mimic Registry
    bytes32 private constant PRICE_ORACLE_NAMESPACE = keccak256('PRICE_ORACLE');

    // Namespace to use by this deployer to fetch ISwapConnector implementations from the Mimic Registry
    bytes32 private constant SWAP_CONNECTOR_NAMESPACE = keccak256('SWAP_CONNECTOR');

    // Namespace to use by this deployer to fetch IBridgeConnector implementations from the Mimic Registry
    bytes32 private constant BRIDGE_CONNECTOR_NAMESPACE = keccak256('BRIDGE_CONNECTOR');

    /**
     * @dev Smart vault params
     * @param factory Address of the factory that will be used to deploy an instance of the Smart Vault implementation
     * @param impl Address of the Smart Vault implementation to be used
     * @param salt Salt bytes to derivate the address of the new Smart Vault instance
     * @param admin Address that will be granted with admin rights for the deployed Smart Vault
     * @param bridgeConnector Optional Bridge Connector to set for the Smart Vault
     * @param swapConnector Optional Swap Connector to set for the Smart Vault
     * @param strategies List of strategies to be allowed for the Smart Vault
     * @param priceOracle Optional Price Oracle to set for the Smart Vault
     * @param priceFeedParams List of price feeds to be set for the Smart Vault
     * @param feeCollector Address to be set as the fee collector
     * @param swapFee Swap fee params
     * @param bridgeFee Bridge fee params
     * @param withdrawFee Withdraw fee params
     * @param performanceFee Performance fee params
     */
    struct SmartVaultParams {
        address factory;
        address impl;
        bytes32 salt;
        address admin;
        address[] strategies;
        address bridgeConnector;
        address swapConnector;
        address priceOracle;
        PriceFeedParams[] priceFeedParams;
        address feeCollector;
        address feeCollectorAdmin;
        SmartVaultFeeParams swapFee;
        SmartVaultFeeParams bridgeFee;
        SmartVaultFeeParams withdrawFee;
        SmartVaultFeeParams performanceFee;
    }

    /**
     * @dev Smart Vault price feed params
     * @param base Base token of the price feed
     * @param quote Quote token of the price feed
     * @param feed Address of the price feed
     */
    struct PriceFeedParams {
        address base;
        address quote;
        address feed;
    }

    /**
     * @dev Smart Vault fee configuration parameters
     * @param pct Percentage expressed using 16 decimals (1e18 = 100%)
     * @param cap Maximum amount of fees to be charged per period
     * @param token Address of the token to express the cap amount
     * @param period Period length in seconds
     */
    struct SmartVaultFeeParams {
        uint256 pct;
        uint256 cap;
        address token;
        uint256 period;
    }

    /**
     * @dev Relayed action params
     * @param relayers List of addresses to be marked as allowed executors and in particular as authorized relayers
     * @param gasPriceLimit Gas price limit to be used for the relayed action
     * @param txCostLimit Total transaction cost limit to be used for the relayed action
     * @param permissiveRelayedMode Whether the permissive relayed mode is active
     */
    struct RelayedActionParams {
        address[] relayers;
        uint256 gasPriceLimit;
        uint256 txCostLimit;
        bool permissiveRelayedMode;
    }

    /**
     * @dev Token threshold action params
     * @param token Address of the token of the threshold
     * @param amount Amount of tokens of the threshold
     */
    struct TokenThresholdActionParams {
        address token;
        uint256 amount;
    }

    /**
     * @dev Time-locked action params
     * @param period Period in seconds to be set for the time lock
     */
    struct TimeLockedActionParams {
        uint256 period;
    }

    /**
     * @dev Withdrawal action params
     * @param recipient Address that will receive the funds from the withdraw action
     */
    struct WithdrawalActionParams {
        address recipient;
    }

    /**
     * @dev Transfer Permission Manager control to a list of owners
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param owners Addresses that will be able to call the permission manager
     */
    function transferPermissionManagerControl(PermissionsManager manager, address[] memory owners) external {
        manager.authorize(manager, owners, manager.execute.selector);
        manager.unauthorize(manager, address(this), manager.execute.selector);
    }

    /**
     * @dev Creates a new Permissions Manager instance
     */
    function createPermissionsManager(address admin) external returns (PermissionsManager) {
        return new PermissionsManager(admin);
    }

    /**
     * @dev Create a new Smart Vault instance
     * @param registry Address of the registry to validate the Smart Vault implementation
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param params Params to customize the Smart Vault to be deployed
     * creating the Smart Vault. Sometimes this is not desired if further customization might take in place.
     */
    function createSmartVault(IRegistry registry, PermissionsManager manager, SmartVaultParams memory params)
        external
        returns (SmartVault smartVault)
    {
        require(params.admin != address(0), 'SMART_VAULT_ADMIN_ZERO');
        require(params.feeCollectorAdmin != address(0), 'SMART_VAULT_FEE_ADMIN_ZERO');

        // Clone requested Smart Vault implementation and initialize
        require(registry.isActive(SMART_VAULT_FACTORY_NAMESPACE, params.factory), 'BAD_SMART_VAULT_FACTORY_IMPL');
        ISmartVaultsFactory factory = ISmartVaultsFactory(params.factory);

        bytes memory initializeData = abi.encodeWithSelector(SmartVault.initialize.selector, address(manager));
        bytes32 senderSalt = keccak256(abi.encodePacked(msg.sender, params.salt));
        smartVault = SmartVault(payable(factory.create(senderSalt, params.impl, initializeData)));

        // Authorize admin to perform any action except from fee collector setter
        bytes4[] memory whats = new bytes4[](19);
        whats[0] = smartVault.collect.selector;
        whats[1] = smartVault.withdraw.selector;
        whats[2] = smartVault.wrap.selector;
        whats[3] = smartVault.unwrap.selector;
        whats[4] = smartVault.claim.selector;
        whats[5] = smartVault.join.selector;
        whats[6] = smartVault.exit.selector;
        whats[7] = smartVault.swap.selector;
        whats[8] = smartVault.bridge.selector;
        whats[9] = smartVault.setStrategy.selector;
        whats[10] = smartVault.setPriceFeed.selector;
        whats[11] = smartVault.setPriceFeeds.selector;
        whats[12] = smartVault.setPriceOracle.selector;
        whats[13] = smartVault.setSwapConnector.selector;
        whats[14] = smartVault.setBridgeConnector.selector;
        whats[15] = smartVault.setWithdrawFee.selector;
        whats[16] = smartVault.setPerformanceFee.selector;
        whats[17] = smartVault.setSwapFee.selector;
        whats[18] = smartVault.setBridgeFee.selector;
        manager.authorize(smartVault, params.admin, whats);

        // Set price feeds if any
        if (params.priceFeedParams.length > 0) {
            manager.authorize(smartVault, address(this), smartVault.setPriceFeed.selector);
            for (uint256 i = 0; i < params.priceFeedParams.length; i = i.uncheckedAdd(1)) {
                PriceFeedParams memory feedParams = params.priceFeedParams[i];
                smartVault.setPriceFeed(feedParams.base, feedParams.quote, feedParams.feed);
            }
            manager.unauthorize(smartVault, address(this), smartVault.setPriceFeed.selector);
        }

        // Set price oracle if given
        if (params.priceOracle != address(0)) {
            require(registry.isActive(PRICE_ORACLE_NAMESPACE, params.priceOracle), 'BAD_PRICE_ORACLE_DEPENDENCY');
            manager.authorize(smartVault, address(this), smartVault.setPriceOracle.selector);
            smartVault.setPriceOracle(params.priceOracle);
            manager.unauthorize(smartVault, address(this), smartVault.setPriceOracle.selector);
        }

        // Set strategies if any
        if (params.strategies.length > 0) {
            manager.authorize(smartVault, address(this), smartVault.setStrategy.selector);
            for (uint256 i = 0; i < params.strategies.length; i = i.uncheckedAdd(1)) {
                require(registry.isActive(STRATEGY_NAMESPACE, params.strategies[i]), 'BAD_STRATEGY_DEPENDENCY');
                smartVault.setStrategy(params.strategies[i], true);
            }
            manager.unauthorize(smartVault, address(this), smartVault.setStrategy.selector);
        }

        // Set swap connector if given
        if (params.swapConnector != address(0)) {
            require(registry.isActive(SWAP_CONNECTOR_NAMESPACE, params.swapConnector), 'BAD_SWAP_CONNECTOR_DEPENDENCY');
            manager.authorize(smartVault, address(this), smartVault.setSwapConnector.selector);
            smartVault.setSwapConnector(params.swapConnector);
            manager.unauthorize(smartVault, address(this), smartVault.setSwapConnector.selector);
        }

        // Set bridge connector if given
        if (params.bridgeConnector != address(0)) {
            bool isActive = registry.isActive(BRIDGE_CONNECTOR_NAMESPACE, params.bridgeConnector);
            require(isActive, 'BAD_BRIDGE_CONNECTOR_DEPENDENCY');
            manager.authorize(smartVault, address(this), smartVault.setBridgeConnector.selector);
            smartVault.setBridgeConnector(params.bridgeConnector);
            manager.unauthorize(smartVault, address(this), smartVault.setBridgeConnector.selector);
        }

        // If no fee collector is given, make sure no fee amounts are requested too
        manager.authorize(smartVault, params.feeCollectorAdmin, smartVault.setFeeCollector.selector);
        if (params.feeCollector != address(0)) {
            manager.authorize(smartVault, address(this), smartVault.setFeeCollector.selector);
            smartVault.setFeeCollector(params.feeCollector);
            manager.unauthorize(smartVault, address(this), smartVault.setFeeCollector.selector);
        } else {
            bool noFees = params.withdrawFee.pct == 0 &&
                params.swapFee.pct == 0 &&
                params.bridgeFee.pct == 0 &&
                params.performanceFee.pct == 0;
            require(noFees, 'SMART_VAULT_FEES_NO_COLLECTOR');
        }

        // Set withdraw fee if not zero
        SmartVaultFeeParams memory withdrawFee = params.withdrawFee;
        if (withdrawFee.pct != 0) {
            manager.authorize(smartVault, address(this), smartVault.setWithdrawFee.selector);
            smartVault.setWithdrawFee(withdrawFee.pct, withdrawFee.cap, withdrawFee.token, withdrawFee.period);
            manager.unauthorize(smartVault, address(this), smartVault.setWithdrawFee.selector);
        }

        // Set swap fee if not zero
        SmartVaultFeeParams memory swapFee = params.swapFee;
        if (swapFee.pct != 0) {
            manager.authorize(smartVault, address(this), smartVault.setSwapFee.selector);
            smartVault.setSwapFee(swapFee.pct, swapFee.cap, swapFee.token, swapFee.period);
            manager.unauthorize(smartVault, address(this), smartVault.setSwapFee.selector);
        }

        // Set bridge fee if not zero
        SmartVaultFeeParams memory bridgeFee = params.bridgeFee;
        if (bridgeFee.pct != 0) {
            manager.authorize(smartVault, address(this), smartVault.setBridgeFee.selector);
            smartVault.setBridgeFee(bridgeFee.pct, bridgeFee.cap, bridgeFee.token, bridgeFee.period);
            manager.unauthorize(smartVault, address(this), smartVault.setBridgeFee.selector);
        }

        // Set performance fee if not zero
        SmartVaultFeeParams memory perfFee = params.performanceFee;
        if (perfFee.pct != 0) {
            manager.authorize(smartVault, address(this), smartVault.setPerformanceFee.selector);
            smartVault.setPerformanceFee(perfFee.pct, perfFee.cap, perfFee.token, perfFee.period);
            manager.unauthorize(smartVault, address(this), smartVault.setPerformanceFee.selector);
        }
    }

    /**
     * @dev Set up a base action
     * @param action Base action to be set up
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Base Action
     * @param smartVault Address of the Smart Vault to be set in the Base Action
     */
    function setupBaseAction(BaseAction action, PermissionsManager manager, address admin, address smartVault)
        external
    {
        require(admin != address(0), 'BASE_ACTION_ADMIN_ZERO');

        manager.authorize(action, Arrays.from(admin, address(this)), action.setSmartVault.selector);
        action.setSmartVault(smartVault);
        manager.unauthorize(action, address(this), action.setSmartVault.selector);
    }

    /**
     * @dev Set up a list of executors for a given action
     * @param action Action whose executors are being allowed
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param executors List of addresses to be allowed to call the given action
     * @param callSelector Selector of the function to allow the list of executors
     */
    function setupActionExecutors(
        BaseAction action,
        PermissionsManager manager,
        address[] memory executors,
        bytes4 callSelector
    ) external {
        manager.authorize(action, executors, callSelector);
    }

    /**
     * @dev Set up a Relayed action
     * @param action Relayed action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Relayed action
     * @param params Params to customize the Relayed action
     */
    function setupRelayedAction(
        RelayedAction action,
        PermissionsManager manager,
        address admin,
        RelayedActionParams memory params
    ) external {
        // Authorize admin to set relayers and txs limits
        require(admin != address(0), 'RELAYED_ACTION_ADMIN_ZERO');

        address[] memory whos = Arrays.from(admin, address(this));
        bytes4[] memory whats = Arrays.from(
            action.setLimits.selector,
            action.setRelayer.selector,
            action.setPermissiveRelayedMode.selector
        );

        manager.authorize(action, whos, whats);

        action.setLimits(params.gasPriceLimit, params.txCostLimit);
        action.setPermissiveRelayedMode(params.permissiveRelayedMode);
        for (uint256 i = 0; i < params.relayers.length; i = i.uncheckedAdd(1)) {
            action.setRelayer(params.relayers[i], true);
        }

        manager.unauthorize(action, address(this), whats);
    }

    /**
     * @dev Set up a Token Threshold action
     * @param action Token threshold action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Token Threshold action
     * @param params Params to customize the Token Threshold action
     */
    function setupTokenThresholdAction(
        TokenThresholdAction action,
        PermissionsManager manager,
        address admin,
        TokenThresholdActionParams memory params
    ) external {
        require(admin != address(0), 'TOKEN_THRESHOLD_ADMIN_ZERO');
        manager.authorize(action, Arrays.from(admin, address(this)), action.setThreshold.selector);
        action.setThreshold(params.token, params.amount);
        manager.unauthorize(action, address(this), action.setThreshold.selector);
    }

    /**
     * @dev Set up a Time-locked action
     * @param action Time-locked action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Time-locked action
     * @param params Params to customize the Time-locked action
     */
    function setupTimeLockedAction(
        TimeLockedAction action,
        PermissionsManager manager,
        address admin,
        TimeLockedActionParams memory params
    ) external {
        require(admin != address(0), 'TIME_LOCKED_ACTION_ADMIN_ZERO');
        manager.authorize(action, Arrays.from(admin, address(this)), action.setTimeLock.selector);
        action.setTimeLock(params.period);
        manager.unauthorize(action, address(this), action.setTimeLock.selector);
    }

    /**
     * @dev Set up a Withdrawal action
     * @param action Relayed action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Withdrawal action
     * @param params Params to customize the Withdrawal action
     */
    function setupWithdrawalAction(
        WithdrawalAction action,
        PermissionsManager manager,
        address admin,
        WithdrawalActionParams memory params
    ) external {
        require(admin != address(0), 'WITHDRAWAL_ACTION_ADMIN_ZERO');
        manager.authorize(action, Arrays.from(admin, address(this)), action.setRecipient.selector);
        action.setRecipient(params.recipient);
        manager.unauthorize(action, address(this), action.setRecipient.selector);
    }

    /**
     * @dev Set up a Receiver action
     * @param action Relayed action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Receiver action
     */
    function setupReceiverAction(ReceiverAction action, PermissionsManager manager, address admin) external {
        require(admin != address(0), 'RECEIVER_ACTION_ADMIN_ZERO');
        manager.authorize(action, admin, action.transferToSmartVault.selector);
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

import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';

/**
 * @title Arrays
 * @dev Helper methods to operate arrays
 */
library Arrays {
    using UncheckedMath for uint256;

    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function concat(address[] memory a, address[] memory b) internal pure returns (address[] memory r) {
        // No need for checked math since we are simply adding two memory array's length
        r = new address[](a.length.uncheckedAdd(b.length));

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < a.length; i = i.uncheckedAdd(1)) {
            r[i] = a[i];
        }

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < b.length; i = i.uncheckedAdd(1)) {
            r[a.length.uncheckedAdd(i)] = b[i];
        }
    }

    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function from(address a, address[] memory b, address[] memory c) internal pure returns (address[] memory result) {
        // No need for checked math since we are simply adding two memory array's length
        result = new address[](b.length.uncheckedAdd(c.length).uncheckedAdd(1));
        result[0] = a;

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < b.length; i = i.uncheckedAdd(1)) {
            result[i.uncheckedAdd(1)] = b[i];
        }

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < c.length; i = i.uncheckedAdd(1)) {
            result[b.length.uncheckedAdd(1).uncheckedAdd(i)] = c[i];
        }
    }

    // Address helpers

    function from(address a) internal pure returns (address[] memory r) {
        r = new address[](1);
        r[0] = a;
    }

    function from(address a, address b) internal pure returns (address[] memory r) {
        r = new address[](2);
        r[0] = a;
        r[1] = b;
    }

    function from(address a, address b, address c) internal pure returns (address[] memory r) {
        r = new address[](3);
        r[0] = a;
        r[1] = b;
        r[2] = c;
    }

    function from(address a, address b, address c, address d) internal pure returns (address[] memory r) {
        r = new address[](4);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
    }

    function from(address a, address b, address c, address d, address e) internal pure returns (address[] memory r) {
        r = new address[](5);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
        r[4] = e;
    }

    // Bytes4 helpers

    function from(bytes4 a) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](1);
        r[0] = a;
    }

    function from(bytes4 a, bytes4 b) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](2);
        r[0] = a;
        r[1] = b;
    }

    function from(bytes4 a, bytes4 b, bytes4 c) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](3);
        r[0] = a;
        r[1] = b;
        r[2] = c;
    }

    function from(bytes4 a, bytes4 b, bytes4 c, bytes4 d) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](4);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
    }

    function from(bytes4 a, bytes4 b, bytes4 c, bytes4 d, bytes4 e) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](5);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
        r[4] = e;
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

import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';

/**
 * @dev Permission
 * @param what Function selector to be referred
 * @param who Address to be referred
 */
struct Permission {
    bytes4 what;
    address who;
}

/**
 * @dev Permission change
 * @param grant Whether the permission should be granted (authorize) or revoked (unauthorize)
 * @param permissions Permission to be changed
 */
struct PermissionChange {
    bool grant;
    Permission permission;
}

/**
 * @dev Permission change request
 * @param target Address of the contract to be affected
 * @param changes List of permission changes to be performed
 */
struct PermissionChangeRequest {
    IAuthorizer target;
    PermissionChange[] changes;
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

import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';

import './Arrays.sol';
import './PermissionsManager.sol';
import { Permission, PermissionChange, PermissionChangeRequest } from './PermissionsData.sol';

library PermissionsHelpers {
    /**
     * @dev Builds a permission object
     * @param who Address to be referred
     * @param what Function selector to be referred
     */
    function permission(address who, bytes4 what) internal pure returns (Permission memory) {
        return Permission(what, who);
    }

    /**
     * @dev Builds a permission change object
     * @param grant Whether the permission should be granted or revoked
     * @param who Address to be referred
     * @param what Function selector to be referred
     */
    function change(bool grant, address who, bytes4 what) internal pure returns (PermissionChange memory) {
        return PermissionChange(grant, permission(who, what));
    }

    /**
     * @dev Grants permission to `who` to perform `what` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be granted
     * @param who Address of the account that will be authorized
     * @param what Function selector to be authorized
     */
    function authorize(PermissionsManager self, IAuthorizer where, address who, bytes4 what) internal {
        authorize(self, where, Arrays.from(who), Arrays.from(what));
    }

    /**
     * @dev Revokes permission from `who` to perform `what` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be revoked
     * @param who Address of the account that will be unauthorized
     * @param what Function selector to be unauthorized
     */
    function unauthorize(PermissionsManager self, IAuthorizer where, address who, bytes4 what) internal {
        unauthorize(self, where, Arrays.from(who), Arrays.from(what));
    }

    /**
     * @dev Grants permission to `whos` to perform `what` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be granted
     * @param whos List of addresses of the accounts that will be authorized
     * @param what Function selector to be authorized
     */
    function authorize(PermissionsManager self, IAuthorizer where, address[] memory whos, bytes4 what) internal {
        authorize(self, where, whos, Arrays.from(what));
    }

    /**
     * @dev Revokes permission from `whos` to perform `what` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be revoked
     * @param whos List of addresses of the accounts that will be unauthorized
     * @param what Function selector to be unauthorized
     */
    function unauthorize(PermissionsManager self, IAuthorizer where, address[] memory whos, bytes4 what) internal {
        unauthorize(self, where, whos, Arrays.from(what));
    }

    /**
     * @dev Grants permissions to `who` to perform `whats` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be granted
     * @param who Address of the account that will be authorized
     * @param whats List of function selectors to be authorized
     */
    function authorize(PermissionsManager self, IAuthorizer where, address who, bytes4[] memory whats) internal {
        authorize(self, where, Arrays.from(who), whats);
    }

    /**
     * @dev Revokes permissions from `who` to perform `whats` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be revoked
     * @param who Address of the account that will be unauthorized
     * @param whats List of function selectors to be unauthorized
     */
    function unauthorize(PermissionsManager self, IAuthorizer where, address who, bytes4[] memory whats) internal {
        unauthorize(self, where, Arrays.from(who), whats);
    }

    /**
     * @dev Grants permissions to `whos` to perform `whats` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be granted
     * @param whos List of addresses of the accounts that will be authorized
     * @param whats List of function selectors to be authorized
     */
    function authorize(PermissionsManager self, IAuthorizer where, address[] memory whos, bytes4[] memory whats)
        internal
    {
        execute(self, where, whos, whats, true);
    }

    /**
     * @dev Revokes permissions from `whos` to perform `whats` in `where` through the permissions manager `self`
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission will be revoked
     * @param whos List of addresses of the accounts that will be unauthorized
     * @param whats List of function selectors to be unauthorized
     */
    function unauthorize(PermissionsManager self, IAuthorizer where, address[] memory whos, bytes4[] memory whats)
        internal
    {
        execute(self, where, whos, whats, false);
    }

    /**
     * @dev Executes a list of permission changes
     * @param self Permissions manager to be used
     * @param where Address of the contract where the permission change will be executed
     * @param whos List of addresses of the accounts that will be affected
     * @param whats List of function selectors to be affected
     * @param grant Whether the permissions should be granted or revoked
     */
    function execute(
        PermissionsManager self,
        IAuthorizer where,
        address[] memory whos,
        bytes4[] memory whats,
        bool grant
    ) private {
        PermissionChangeRequest[] memory requests = new PermissionChangeRequest[](1);
        requests[0].target = where;
        requests[0].changes = new PermissionChange[](whos.length * whats.length);

        for (uint256 i = 0; i < whos.length; i++) {
            for (uint256 j = 0; j < whats.length; j++) {
                uint256 index = (i * whats.length) + j;
                requests[0].changes[index] = change(grant, whos[i], whats[j]);
            }
        }

        self.execute(requests);
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

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '@mimic-fi/v2-helpers/contracts/auth/Authorizer.sol';
import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';

import { Permission, PermissionChange, PermissionChangeRequest } from './PermissionsData.sol';

/**
 * @title PermissionsManager
 * @dev This implementation is meant to be used as a proxy in order to control many `IAuthorizer` implementations.
 * It allows to implement a layout of permissions over a group of `IAuthorizer` implementations, otherwise in order
 * to connect a big number of `IAuthorizer` implementations between each other, admins would had to perform many
 * transactions manually.
 */
contract PermissionsManager is Authorizer, ReentrancyGuard {
    /**
     * @dev Creates a new permission manager, allowing itself to authorize and unauthorize its own permissions
     * @param admin Address that will be allowed to execute permissions changes through the permissions manager
     */
    constructor(address admin) {
        _authorize(admin, PermissionsManager.execute.selector);
        _authorize(admin, PermissionsManager.execute.selector);
        _authorize(address(this), Authorizer.authorize.selector);
        _authorize(address(this), Authorizer.unauthorize.selector);
    }

    /**
     * @dev Executes a list of permissions change requests. Sender must be authorized.
     * @param requests List of requests to be executed
     */
    function execute(PermissionChangeRequest[] memory requests) external auth nonReentrant {
        for (uint256 i = 0; i < requests.length; i++) _execute(requests[i]);
    }

    /**
     * @dev Executes a single permissions change request
     * @param request Request to be executed
     */
    function _execute(PermissionChangeRequest memory request) private {
        IAuthorizer target = request.target;
        for (uint256 i = 0; i < request.changes.length; i++) {
            PermissionChange memory change = request.changes[i];
            (change.grant ? target.authorize : target.unauthorize)(change.permission.who, change.permission.what);
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

import '@mimic-fi/v2-registry/contracts/implementations/IImplementation.sol';

/**
 * @title IStrategy
 * @dev Strategy interface required by Mimic Smart Vaults. It must follow the IImplementation interface.
 */
interface IStrategy is IImplementation {
    /**
     * @dev Tokens accepted to join the strategy
     */
    function joinTokens() external view returns (address[] memory);

    /**
     * @dev Tokens accepted to exit the strategy
     */
    function exitTokens() external view returns (address[] memory);

    /**
     * @dev Tells how much a value unit means expressed in the asset token.
     * For example, if a strategy has a value of 100 in T0, and then it has a value of 120 in T1,
     * and the value rate is 1.5, it means the strategy has earned 30 strategy tokens between T0 and T1.
     */
    function valueRate() external view returns (uint256);

    /**
     * @dev Tells the last value an account has over time. Note this value can be outdated: there could be rewards to
     * be claimed that will affect the accrued value. For example, if an account has a value of 100 in T0, and then it
     * has a value of 120 in T1, it means it gained a 20% between T0 and T1.
     * @param account Address of the account querying the last value of
     */
    function lastValue(address account) external view returns (uint256);

    /**
     * @dev Claim any existing rewards
     * @param data Arbitrary extra data
     * @return tokens Addresses of the tokens received as rewards
     * @return amounts Amounts of the tokens received as rewards
     */
    function claim(bytes memory data) external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     * @dev Join the interfaced DeFi protocol
     * @param tokensIn List of token addresses to join with
     * @param amountsIn List of token amounts to join with
     * @param slippage Slippage value to join with
     * @param data Arbitrary extra data
     * @return tokensOut List of token addresses received after the join
     * @return amountsOut List of token amounts received after the join
     * @return value Value represented by the joined amount
     */
    function join(address[] memory tokensIn, uint256[] memory amountsIn, uint256 slippage, bytes memory data)
        external
        returns (address[] memory tokensOut, uint256[] memory amountsOut, uint256 value);

    /**
     * @dev Exit the interfaced DeFi protocol
     * @param tokensIn List of token addresses to exit with
     * @param amountsIn List of token amounts to exit with
     * @param slippage Slippage value to exit with
     * @param data Arbitrary extra data
     * @return tokensOut List of token addresses received after the exit
     * @return amountsOut List of token amounts received after the exit
     * @return value Value represented by the exited amount
     */
    function exit(address[] memory tokensIn, uint256[] memory amountsIn, uint256 slippage, bytes memory data)
        external
        returns (address[] memory tokensOut, uint256[] memory amountsOut, uint256 value);
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

import '@mimic-fi/v2-registry/contracts/implementations/IImplementation.sol';

/**
 * @title ISwapConnector
 * @dev Swap Connector interface to perform token swaps. It must follow the IImplementation interface.
 */
interface ISwapConnector is IImplementation {
    /**
     * @dev Enum identifying the sources proposed: Uniswap V2, Uniswap V3, Balancer V2, Paraswap V5, 1inch V5, and Hop.
     */
    enum Source {
        UniswapV2,
        UniswapV3,
        BalancerV2,
        ParaswapV5,
        OneInchV5,
        Hop
    }

    /**
     * @dev Swaps two tokens
     * @param source Source to execute the requested swap
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param data Encoded data to specify different swap parameters depending on the source picked
     */
    function swap(
        uint8 source,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes memory data
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
abstract contract ReentrancyGuard {
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

    constructor() {
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
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

abstract contract BaseHopBridger is BaseAction, TokenThresholdAction, RelayedAction {
    // Hop Exchange source number
    uint8 internal constant HOP_SOURCE = 0;

    // Ethereum mainnet chain ID
    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant GOERLI_CHAIN_ID = 5;

    uint256 public maxDeadline;
    uint256 public maxSlippage;
    uint256 public destinationChainId;

    event MaxDeadlineSet(uint256 maxDeadline);
    event MaxSlippageSet(uint256 maxSlippage);
    event DestinationChainIdSet(uint256 indexed chainId);

    function getTokens() external view virtual returns (address[] memory);

    function getTokensLength() external view virtual returns (uint256);

    function setMaxDeadline(uint256 newMaxDeadline) external auth {
        require(newMaxDeadline > 0, 'BRIDGER_MAX_DEADLINE_ZERO');
        maxDeadline = newMaxDeadline;
        emit MaxDeadlineSet(newMaxDeadline);
    }

    function setMaxSlippage(uint256 newMaxSlippage) external auth {
        require(newMaxSlippage <= FixedPoint.ONE, 'BRIDGER_SLIPPAGE_ABOVE_ONE');
        maxSlippage = newMaxSlippage;
        emit MaxSlippageSet(newMaxSlippage);
    }

    function setDestinationChainId(uint256 chainId) external auth {
        require(chainId != block.chainid, 'BRIDGER_SAME_CHAIN_ID');
        destinationChainId = chainId;
        emit DestinationChainIdSet(chainId);
    }

    function _bridgingToL1() internal view returns (bool) {
        return destinationChainId == MAINNET_CHAIN_ID || destinationChainId == GOERLI_CHAIN_ID;
    }

    function _bridge(address token, uint256 amount, uint256 slippage, bytes memory data) internal {
        smartVault.bridge(
            HOP_SOURCE,
            destinationChainId,
            token,
            amount,
            ISmartVault.BridgeLimit.Slippage,
            slippage,
            address(smartVault),
            data
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

pragma solidity ^0.8.0;

import '@mimic-fi/v2-bridge-connector/contracts/interfaces/IHopL1Bridge.sol';
import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/utils/EnumerableMap.sol';

import './BaseHopBridger.sol';

contract L1HopBridger is BaseHopBridger {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 140e3;

    mapping (address => uint256) public getMaxRelayerFeePct;
    EnumerableMap.AddressToAddressMap private tokenBridges;

    event TokenBridgeSet(address indexed token, address indexed bridge);
    event MaxRelayerFeePctSet(address indexed relayer, uint256 maxFeePct);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getTokensLength() external view override returns (uint256) {
        return tokenBridges.length();
    }

    function getTokenBridge(address token) external view returns (address bridge) {
        (, bridge) = tokenBridges.tryGet(token);
    }

    function getTokens() external view override returns (address[] memory tokens) {
        tokens = new address[](tokenBridges.length());
        for (uint256 i = 0; i < tokens.length; i++) {
            (address token, ) = tokenBridges.at(i);
            tokens[i] = token;
        }
    }

    function getTokenBridges() external view returns (address[] memory tokens, address[] memory bridges) {
        tokens = new address[](tokenBridges.length());
        bridges = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            (address token, address bridge) = tokenBridges.at(i);
            tokens[i] = token;
            bridges[i] = bridge;
        }
    }

    function setMaxRelayerFeePct(address relayer, uint256 newMaxFeePct) external auth {
        require(newMaxFeePct <= FixedPoint.ONE, 'BRIDGER_RELAYER_FEE_PCT_GT_ONE');
        getMaxRelayerFeePct[relayer] = newMaxFeePct;
        emit MaxRelayerFeePctSet(relayer, newMaxFeePct);
    }

    function setTokenBridge(address token, address bridge) external auth {
        require(token != address(0), 'BRIDGER_TOKEN_ZERO');
        require(!Denominations.isNativeToken(token), 'BRIDGER_NATIVE_TOKEN');
        bridge == address(0) ? tokenBridges.remove(token) : tokenBridges.set(token, bridge);
        emit TokenBridgeSet(token, bridge);
    }

    function call(address token, uint256 slippage, address relayer, uint256 relayerFee) external auth nonReentrant {
        _initRelayedTx();
        uint256 balance = _balanceOf(token);
        bytes memory data = _prepareBridge(token, balance, slippage, relayer, relayerFee);
        uint256 gasRefund = _payRelayedTx(token);
        _bridge(token, balance - gasRefund, slippage, data);
    }

    function _prepareBridge(address token, uint256 amount, uint256 slippage, address relayer, uint256 relayerFee)
        internal
        returns (bytes memory)
    {
        (bool existsBridge, address bridge) = tokenBridges.tryGet(token);
        require(existsBridge, 'BRIDGER_TOKEN_BRIDGE_NOT_SET');
        require(amount > 0, 'BRIDGER_AMOUNT_ZERO');
        require(destinationChainId != 0, 'BRIDGER_CHAIN_NOT_SET');
        require(slippage <= maxSlippage, 'BRIDGER_SLIPPAGE_ABOVE_MAX');
        require(relayerFee.divUp(amount) <= getMaxRelayerFeePct[relayer], 'BRIDGER_RELAYER_FEE_ABOVE_MAX');
        _validateThreshold(token, amount);

        uint256 deadline = block.timestamp + maxDeadline;
        bytes memory data = abi.encode(bridge, deadline, relayer, relayerFee);

        emit Executed();
        return data;
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

import '@mimic-fi/v2-bridge-connector/contracts/interfaces/IHopL2AMM.sol';
import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/utils/EnumerableMap.sol';

import './BaseHopBridger.sol';

contract L2HopBridger is BaseHopBridger {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 140e3;

    uint256 public maxBonderFeePct;
    EnumerableMap.AddressToAddressMap private tokenAmms;

    event MaxBonderFeePctSet(uint256 maxBonderFeePct);
    event TokenAmmSet(address indexed token, address indexed amm);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getTokensLength() external view override returns (uint256) {
        return tokenAmms.length();
    }

    function getTokenAmm(address token) external view returns (address amm) {
        (, amm) = tokenAmms.tryGet(token);
    }

    function getTokens() external view override returns (address[] memory tokens) {
        tokens = new address[](tokenAmms.length());
        for (uint256 i = 0; i < tokens.length; i++) {
            (address token, ) = tokenAmms.at(i);
            tokens[i] = token;
        }
    }

    function getTokenAmms() external view returns (address[] memory tokens, address[] memory amms) {
        tokens = new address[](tokenAmms.length());
        amms = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            (address token, address amm) = tokenAmms.at(i);
            tokens[i] = token;
            amms[i] = amm;
        }
    }

    function setMaxBonderFeePct(uint256 newMaxBonderFeePct) external auth {
        require(newMaxBonderFeePct <= FixedPoint.ONE, 'BRIDGER_BONDER_FEE_PCT_ABOVE_ONE');
        maxBonderFeePct = newMaxBonderFeePct;
        emit MaxBonderFeePctSet(newMaxBonderFeePct);
    }

    function setTokenAmm(address token, address amm) external auth {
        require(token != address(0), 'BRIDGER_TOKEN_ZERO');
        require(!Denominations.isNativeToken(token), 'BRIDGER_NATIVE_TOKEN');
        amm == address(0) ? tokenAmms.remove(token) : tokenAmms.set(token, amm);
        emit TokenAmmSet(token, amm);
    }

    function call(address token, uint256 slippage, uint256 bonderFee) external auth nonReentrant {
        _initRelayedTx();
        uint256 balance = _balanceOf(token);
        bytes memory data = _prepareBridge(token, balance, slippage, bonderFee);
        uint256 gasRefund = _payRelayedTx(token);
        _bridge(token, balance - gasRefund, slippage, data);
    }

    function _prepareBridge(address token, uint256 amount, uint256 slippage, uint256 bonderFee)
        internal
        returns (bytes memory)
    {
        (bool existsAmm, address amm) = tokenAmms.tryGet(token);
        require(existsAmm, 'BRIDGER_TOKEN_AMM_NOT_SET');
        require(amount > 0, 'BRIDGER_AMOUNT_ZERO');
        require(destinationChainId != 0, 'BRIDGER_CHAIN_NOT_SET');
        require(slippage <= maxSlippage, 'BRIDGER_SLIPPAGE_ABOVE_MAX');
        require(bonderFee.divUp(amount) <= maxBonderFeePct, 'BRIDGER_BONDER_FEE_ABOVE_MAX');
        _validateThreshold(token, amount);

        bytes memory data = _bridgingToL1()
            ? abi.encode(amm, bonderFee)
            : abi.encode(amm, bonderFee, block.timestamp + maxDeadline);

        emit Executed();
        return data;
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

import '@mimic-fi/v2-bridge-connector/contracts/interfaces/IHopL2AMM.sol';
import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-helpers/contracts/utils/EnumerableMap.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

contract L2HopSwapper is BaseAction, RelayedAction {
    using FixedPoint for uint256;
    using UncheckedMath for uint256;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 50e3;

    // Hop Exchange source number
    uint8 internal constant HOP_SOURCE = 5;

    uint256 public maxSlippage;
    EnumerableMap.AddressToAddressMap private tokenAmms;

    event MaxSlippageSet(uint256 maxSlippage);
    event TokenAmmSet(address indexed token, address indexed amm);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getTokensLength() external view returns (uint256) {
        return tokenAmms.length();
    }

    function getTokenAmm(address token) external view returns (address amm) {
        (, amm) = tokenAmms.tryGet(token);
    }

    function getTokens() external view returns (address[] memory tokens) {
        tokens = new address[](tokenAmms.length());
        for (uint256 i = 0; i < tokens.length; i++) {
            (address token, ) = tokenAmms.at(i);
            tokens[i] = token;
        }
    }

    function getTokenAmms() external view returns (address[] memory tokens, address[] memory amms) {
        tokens = new address[](tokenAmms.length());
        amms = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            (address token, address amm) = tokenAmms.at(i);
            tokens[i] = token;
            amms[i] = amm;
        }
    }

    function setMaxSlippage(uint256 newMaxSlippage) external auth {
        require(newMaxSlippage <= FixedPoint.ONE, 'SWAPPER_SLIPPAGE_ABOVE_ONE');
        maxSlippage = newMaxSlippage;
        emit MaxSlippageSet(newMaxSlippage);
    }

    function setTokenAmm(address token, address amm) external auth {
        require(token != address(0), 'SWAPPER_TOKEN_ZERO');
        amm == address(0) ? tokenAmms.remove(token) : tokenAmms.set(token, amm);
        emit TokenAmmSet(token, amm);
    }

    function call(address token, uint256 amount, uint256 slippage) external auth nonReentrant redeemGas(token) {
        (bool existsAmm, address amm) = tokenAmms.tryGet(token);
        require(existsAmm, 'SWAPPER_TOKEN_AMM_NOT_SET');
        require(amount > 0, 'SWAPPER_AMOUNT_ZERO');

        address hToken = IHopL2AMM(amm).hToken();
        require(amount <= _balanceOf(hToken), 'SWAPPER_AMOUNT_EXCEEDS_BALANCE');
        require(slippage <= maxSlippage, 'SWAPPER_SLIPPAGE_ABOVE_MAX');

        bytes memory data = abi.encode(IHopL2AMM(amm).exchangeAddress());
        uint256 minAmountOut = amount.mulUp(FixedPoint.ONE.uncheckedSub(slippage));
        smartVault.swap(HOP_SOURCE, hToken, token, amount, ISmartVault.SwapLimit.MinAmountOut, minAmountOut, data);
        emit Executed();
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

import '@mimic-fi/v2-helpers/contracts/utils/ERC20Helpers.sol';

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/OracledAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';

import './IProtocolFeeWithdrawer.sol';

contract Claimer is BaseAction, OracledAction, RelayedAction, TokenThresholdAction {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 72e3;

    address public payingGasToken;
    address public protocolFeeWithdrawer;

    event PayingGasTokenSet(address indexed payingGasToken);
    event ProtocolFeeWithdrawerSet(address indexed protocolFeeWithdrawer);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getClaimableBalance(address token) public view returns (uint256) {
        return ERC20Helpers.balanceOf(token, protocolFeeWithdrawer);
    }

    function setPayingGasToken(address newPayingGasToken) external auth {
        require(newPayingGasToken != address(0), 'CLAIMER_PAYING_GAS_TOKEN_ZERO');
        payingGasToken = newPayingGasToken;
        emit PayingGasTokenSet(newPayingGasToken);
    }

    function setProtocolFeeWithdrawer(address newProtocolFeeWithdrawer) external auth {
        require(newProtocolFeeWithdrawer != address(0), 'CLAIMER_WITHDRAWER_ADDRESS_ZERO');
        protocolFeeWithdrawer = newProtocolFeeWithdrawer;
        emit ProtocolFeeWithdrawerSet(newProtocolFeeWithdrawer);
    }

    function call(address token) external auth nonReentrant redeemGas(payingGasToken) {
        require(payingGasToken != address(0), 'CLAIMER_PAYING_GAS_TOKEN_ZERO');
        require(token != address(0), 'CLAIMER_TOKEN_ADDRESS_ZERO');
        require(!Denominations.isNativeToken(token), 'CLAIMER_NATIVE_TOKEN');

        uint256 amount = getClaimableBalance(token);
        _validateThreshold(token, amount);

        // solhint-disable-next-line avoid-low-level-calls
        smartVault.call(protocolFeeWithdrawer, _buildData(token, amount), 0, new bytes(0));
        emit Executed();
    }

    function _buildData(address token, uint256 amount) internal view returns (bytes memory) {
        address[] memory tokens = new address[](1);
        tokens[0] = token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        return
            abi.encodeWithSelector(
                IProtocolFeeWithdrawer.withdrawCollectedFees.selector,
                tokens,
                amounts,
                address(smartVault)
            );
    }

    function _getPrice(address base, address quote)
        internal
        view
        override(BaseAction, OracledAction)
        returns (uint256)
    {
        return OracledAction._getPrice(base, quote);
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

interface IProtocolFeeWithdrawer {
    function withdrawCollectedFees(address[] calldata tokens, uint256[] calldata amounts, address recipient) external;
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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

abstract contract BaseSwapper is BaseAction, TokenThresholdAction, RelayedAction {
    using FixedPoint for uint256;
    using UncheckedMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public tokenOut;
    address public swapSigner;
    uint256 public defaultMaxSlippage;
    mapping (address => uint256) public tokenMaxSlippages;
    EnumerableSet.AddressSet private deniedTokens;

    event TokenOutSet(address indexed tokenOut);
    event SwapSignerSet(address indexed swapSigner);
    event DefaultMaxSlippageSet(uint256 maxSlippage);
    event TokenMaxSlippageSet(address indexed token, uint256 maxSlippage);
    event DeniedTokenSet(address indexed token, bool denied);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getTokenSlippage(address token) public view returns (uint256) {
        uint256 tokenMaxSlippage = tokenMaxSlippages[token];
        return tokenMaxSlippage > 0 ? tokenMaxSlippage : defaultMaxSlippage;
    }

    function isTokenDenied(address token) public view returns (bool) {
        return deniedTokens.contains(token);
    }

    function getDeniedTokens() external view returns (address[] memory) {
        return deniedTokens.values();
    }

    function setTokenOut(address newTokenOut) external auth {
        require(newTokenOut != address(0), 'SWAPPER_TOKEN_ADDRESS_ZERO');
        tokenOut = newTokenOut;
        emit TokenOutSet(newTokenOut);
    }

    function setSwapSigner(address newSwapSigner) external auth {
        swapSigner = newSwapSigner;
        emit SwapSignerSet(newSwapSigner);
    }

    function setDefaultMaxSlippage(uint256 slippage) external auth {
        require(slippage <= FixedPoint.ONE, 'SWAPPER_DEFAULT_SLIPPAGE_ABOVE_1');
        defaultMaxSlippage = slippage;
        emit DefaultMaxSlippageSet(slippage);
    }

    function setTokenMaxSlippage(address token, uint256 slippage) external auth {
        require(token != address(0), 'SWAPPER_TOKEN_ADDRESS_ZERO');
        require(slippage <= FixedPoint.ONE, 'SWAPPER_TOKEN_SLIPPAGE_ABOVE_1');
        tokenMaxSlippages[token] = slippage;
        emit TokenMaxSlippageSet(token, slippage);
    }

    function setDeniedTokens(address[] memory tokens, bool[] memory denies) external auth {
        require(tokens.length == denies.length, 'SWAPPER_DENIED_TOKENS_INV_LEN');
        for (uint256 i = 0; i < tokens.length; i = i.uncheckedAdd(1)) {
            if (denies[i]) deniedTokens.add(tokens[i]);
            else deniedTokens.remove(tokens[i]);
            emit DeniedTokenSet(tokens[i], denies[i]);
        }
    }

    function _validateToken(address token) internal view {
        require(token != address(0), 'SWAPPER_TOKEN_ADDRESS_ZERO');
        require(!Denominations.isNativeToken(token), 'SWAPPER_NATIVE_TOKEN');
        require(!isTokenDenied(token), 'SWAPPER_DENIED_TOKEN');
    }

    function _validateSlippage(address tokenIn, uint256 minAmountOut, uint256 expectedAmountOut) internal view {
        if (minAmountOut >= expectedAmountOut) return; // Return if in case we have a positive slippage
        uint256 slippage = FixedPoint.ONE - minAmountOut.divUp(expectedAmountOut);
        require(slippage <= getTokenSlippage(tokenIn), 'SWAPPER_SLIPPAGE_TOO_BIG');
    }

    function _validateSig(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) internal view {
        bytes32 message = _hash(tokenIn, amountIn, minAmountOut, expectedAmountOut, deadline, data);
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(message), sig);
        require(signer == swapSigner, 'SWAPPER_INVALID_SIGNATURE');
        require(block.timestamp <= deadline, 'SWAPPER_DEADLINE_EXPIRED');
    }

    function _hash(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data
    ) private view returns (bytes32) {
        bool isBuy = false;
        return
            keccak256(
                abi.encodePacked(tokenIn, tokenOut, isBuy, amountIn, minAmountOut, expectedAmountOut, deadline, data)
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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/OracledAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

import './balancer/IBalancerBoostedPool.sol';
import './balancer/IBalancerPool.sol';
import './balancer/IBalancerVault.sol';

// solhint-disable avoid-low-level-calls

contract BPTSwapper is BaseAction, OracledAction, RelayedAction, TokenThresholdAction {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 95e3;

    // Internal constant used to exit balancer pools
    uint256 private constant EXACT_BPT_IN_FOR_TOKENS_OUT = 1;

    // Address of the token used in order to pay gas
    address public payingGasToken;

    // Balancer Vault reference - it cannot be changed
    address public immutable balancerVault;

    /**
     * @dev Emitted every time a paying gas token is set
     */
    event PayingGasTokenSet(address indexed payingGasToken);

    /**
     * @dev Creates a new BPT swapper action
     * @param _balancerVault Address of the Balancer Vault
     */
    constructor(address _balancerVault, address admin, address registry) BaseAction(admin, registry) {
        balancerVault = _balancerVault;
    }

    /**
     * @dev Sets a paying gas token
     * @param newPayingGasToken Address of the new token to be used to pay gas costs
     */
    function setPayingGasToken(address newPayingGasToken) external auth {
        require(newPayingGasToken != address(0), 'CLAIMER_PAYING_GAS_TOKEN_ZERO');
        payingGasToken = newPayingGasToken;
        emit PayingGasTokenSet(newPayingGasToken);
    }

    /**
     * @dev Executes the BPT swapper action for a token and amount pair
     * @param pool Address of the Balancer pool (token) to swap
     * @param amount Amount of BPTs to swap
     */
    function call(address pool, uint256 amount) external auth nonReentrant redeemGas(payingGasToken) {
        require(payingGasToken != address(0), 'CLAIMER_PAYING_GAS_TOKEN_ZERO');
        require(pool != address(0), 'BPT_SWAPPER_ADDRESS_ZERO');
        require(amount > 0, 'BPT_SWAPPER_AMOUNT_ZERO');
        _validateThreshold(pool, amount);

        smartVault.call(pool, abi.encodeWithSelector(IERC20.approve.selector, balancerVault, amount), 0, new bytes(0));
        smartVault.call(balancerVault, _buildSwapCall(pool, amount), 0, new bytes(0));
        emit Executed();
    }

    /**
     * @dev Builds the corresponding data to swap a BPT into its underlying tokens
     * @param pool Address of the Balancer pool (token) to swap
     * @param amount Amount of BPTs to swap
     */
    function _buildSwapCall(address pool, uint256 amount) private view returns (bytes memory) {
        try IBalancerBoostedPool(pool).getBptIndex() returns (uint256 bptIndex) {
            return _buildBoostedPoolSwap(pool, amount, bptIndex);
        } catch {
            return _buildNormalPoolExit(pool, amount);
        }
    }

    /**
     * @dev Exit normal pools using a exact BPT for tokens out. Note that there is no need to compute
     * minimum amounts since this is considered a proportional exit.
     * @param pool Address of the Balancer pool (token) to exit
     * @param amount Amount of BPTs to exit
     */
    function _buildNormalPoolExit(address pool, uint256 amount) private view returns (bytes memory) {
        // Fetch the list of tokens of the pool
        bytes32 poolId = IBalancerPool(pool).getPoolId();
        (IERC20[] memory tokens, , ) = IBalancerVault(balancerVault).getPoolTokens(poolId);

        // Proportional exit
        IBalancerVault.ExitPoolRequest memory request = IBalancerVault.ExitPoolRequest({
            assets: tokens,
            minAmountsOut: new uint256[](tokens.length),
            userData: abi.encodePacked(EXACT_BPT_IN_FOR_TOKENS_OUT, amount),
            toInternalBalance: false
        });

        return
            abi.encodeWithSelector(
                IBalancerVault.exitPool.selector,
                poolId,
                address(smartVault),
                payable(address(smartVault)),
                request
            );
    }

    /**
     * @dev Exit boosted pools using a swap request in exchange for the first underlying token of the pool. The min
     * amount out is computed based on the current rate of the boosted pool.
     * @param pool Address of the Balancer pool (token) to swap
     * @param amount Amount of BPTs to swap
     * @param bptIndex Index of the BPT in the list of tokens tracked by the Balancer Vault
     */
    function _buildBoostedPoolSwap(address pool, uint256 amount, uint256 bptIndex) private view returns (bytes memory) {
        // Pick the first underlying token of the boosted pool
        bytes32 poolId = IBalancerPool(pool).getPoolId();
        (IERC20[] memory tokens, , ) = IBalancerVault(balancerVault).getPoolTokens(poolId);
        address underlying = address(bptIndex == 0 ? tokens[1] : tokens[0]);

        // Compute minimum amount out in the underlying token
        uint256 rate = IBalancerBoostedPool(pool).getRate();
        uint256 decimals = IERC20Metadata(underlying).decimals();
        uint256 minAmountOut = decimals <= 18 ? (rate / (10**(18 - decimals))) : (rate * (10**(decimals - 18)));

        // Swap from BPT to underlying token
        IBalancerVault.SingleSwap memory request = IBalancerVault.SingleSwap({
            poolId: IBalancerPool(pool).getPoolId(),
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: pool,
            assetOut: underlying,
            amount: amount,
            userData: new bytes(0)
        });

        // Build fund management object: smart vault is the sender and recipient
        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
            sender: address(smartVault),
            fromInternalBalance: false,
            recipient: payable(address(smartVault)),
            toInternalBalance: false
        });

        return abi.encodeWithSelector(IBalancerVault.swap.selector, request, funds, minAmountOut, block.timestamp);
    }

    function _getPrice(address base, address quote)
        internal
        view
        override(BaseAction, OracledAction)
        returns (uint256)
    {
        return OracledAction._getPrice(base, quote);
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

import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';

import './BaseSwapper.sol';
import './ParaswapSwapper.sol';

contract OneInchSwapper is BaseSwapper {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 58e3;

    struct ParaswapData {
        uint256 minAmountOut;
        uint256 expectedAmountOut;
        uint256 deadline;
        bytes data;
        bytes sig;
    }

    constructor(address admin, address registry) BaseSwapper(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes memory data,
        ParaswapData memory paraswapData
    ) external auth nonReentrant redeemGas(tokenOut) {
        _validateToken(tokenIn);
        _validateThreshold(tokenOut, minAmountOut);
        _validateSlippage(tokenIn, minAmountOut, paraswapData);
        _validateSig(tokenIn, amountIn, paraswapData);

        smartVault.swap(
            uint8(ISwapConnector.Source.OneInchV5),
            tokenIn,
            tokenOut,
            amountIn,
            ISmartVault.SwapLimit.MinAmountOut,
            minAmountOut,
            data
        );

        emit Executed();
    }

    function _validateSlippage(address tokenIn, uint256 minAmountOut, ParaswapData memory paraswapData) internal view {
        require(minAmountOut >= paraswapData.minAmountOut, 'SWAPPER_1INCH_MIN_AMOUNT_LT_PSP');
        _validateSlippage(tokenIn, minAmountOut, paraswapData.expectedAmountOut);
    }

    function _validateSig(address tokenIn, uint256 amountIn, ParaswapData memory paraswapData) internal view {
        _validateSig(
            tokenIn,
            amountIn,
            paraswapData.minAmountOut,
            paraswapData.expectedAmountOut,
            paraswapData.deadline,
            paraswapData.data,
            paraswapData.sig
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

pragma solidity ^0.8.0;

import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';

import './BaseSwapper.sol';

contract ParaswapSwapper is BaseSwapper {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 55e3;

    constructor(address admin, address registry) BaseSwapper(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) external auth nonReentrant redeemGas(tokenOut) {
        _validateToken(tokenIn);
        _validateThreshold(tokenOut, minAmountOut);
        _validateSlippage(tokenIn, minAmountOut, expectedAmountOut);
        _validateSig(tokenIn, amountIn, minAmountOut, expectedAmountOut, deadline, data, sig);

        smartVault.swap(
            uint8(ISwapConnector.Source.ParaswapV5),
            tokenIn,
            tokenOut,
            amountIn,
            ISmartVault.SwapLimit.MinAmountOut,
            minAmountOut,
            data
        );

        emit Executed();
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

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TimeLockedAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/WithdrawalAction.sol';

contract Withdrawer is BaseAction, RelayedAction, TimeLockedAction, TokenThresholdAction, WithdrawalAction {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 110e3;

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call(address token) external auth nonReentrant {
        _initRelayedTx();
        _validateTimeLock();

        uint256 amount = _balanceOf(token);
        _validateThreshold(token, amount);
        emit Executed();

        _payRelayedTx(token);
        _withdraw(token);
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

import '@openzeppelin/contracts/access/Ownable.sol';

import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/BaseDeployer.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/Arrays.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsHelpers.sol';

import './actions/claim/Claimer.sol';
import './actions/swap/BPTSwapper.sol';
import './actions/swap/BaseSwapper.sol';

// solhint-disable avoid-low-level-calls

contract BaseSmartVaultDeployer is BaseDeployer {
    using UncheckedMath for uint256;
    using PermissionsHelpers for PermissionsManager;

    struct ClaimerActionParams {
        address impl;
        address admin;
        address[] managers;
        address oracleSigner;
        address payingGasToken;
        address protocolFeeWithdrawer;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct BptSwapperActionParams {
        address impl;
        address admin;
        address[] managers;
        address oracleSigner;
        address payingGasToken;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct SwapperActionParams {
        address impl;
        address admin;
        address[] managers;
        address tokenOut;
        address swapSigner;
        address[] deniedTokens;
        uint256 defaultMaxSlippage;
        address[] customSlippageTokens;
        uint256[] customSlippageValues;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    constructor(address owner) BaseDeployer(owner) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _setupClaimer(SmartVault smartVault, PermissionsManager manager, ClaimerActionParams memory params)
        internal
    {
        // Create and setup action
        Claimer claimer = Claimer(params.impl);
        Deployer.setupBaseAction(claimer, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(claimer, manager, executors, claimer.call.selector);
        Deployer.setupTokenThresholdAction(claimer, manager, params.admin, params.tokenThresholdActionParams);
        Deployer.setupRelayedAction(claimer, manager, params.admin, params.relayedActionParams);

        // Set oracle signers
        manager.authorize(claimer, Arrays.from(params.admin, address(this)), claimer.setOracleSigner.selector);
        claimer.setOracleSigner(params.oracleSigner, true);
        manager.unauthorize(claimer, address(this), claimer.setOracleSigner.selector);

        // Set paying gas token
        manager.authorize(claimer, Arrays.from(params.admin, address(this)), claimer.setPayingGasToken.selector);
        claimer.setPayingGasToken(params.payingGasToken);
        manager.unauthorize(claimer, address(this), claimer.setPayingGasToken.selector);

        // Set protocol fee withdrawer
        manager.authorize(claimer, Arrays.from(params.admin, address(this)), claimer.setProtocolFeeWithdrawer.selector);
        claimer.setProtocolFeeWithdrawer(params.protocolFeeWithdrawer);
        manager.unauthorize(claimer, address(this), claimer.setProtocolFeeWithdrawer.selector);

        // Authorize action to call and withdraw
        bytes4[] memory whats = Arrays.from(smartVault.call.selector, smartVault.withdraw.selector);
        manager.authorize(smartVault, address(claimer), whats);
    }

    function _setupBptSwapper(SmartVault smartVault, PermissionsManager manager, BptSwapperActionParams memory params)
        internal
    {
        // Create and setup action
        BPTSwapper swapper = BPTSwapper(params.impl);
        Deployer.setupBaseAction(swapper, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(swapper, manager, executors, swapper.call.selector);
        Deployer.setupTokenThresholdAction(swapper, manager, params.admin, params.tokenThresholdActionParams);
        Deployer.setupRelayedAction(swapper, manager, params.admin, params.relayedActionParams);

        // Set oracle signers
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setOracleSigner.selector);
        swapper.setOracleSigner(params.oracleSigner, true);
        manager.unauthorize(swapper, address(this), swapper.setOracleSigner.selector);

        // Set paying gas token
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setPayingGasToken.selector);
        swapper.setPayingGasToken(params.payingGasToken);
        manager.unauthorize(swapper, address(this), swapper.setPayingGasToken.selector);

        // Authorize action to call and withdraw
        bytes4[] memory whats = Arrays.from(smartVault.call.selector, smartVault.withdraw.selector);
        manager.authorize(smartVault, address(swapper), whats);
    }

    function _setupSwapper(
        SmartVault smartVault,
        PermissionsManager manager,
        SwapperActionParams memory params,
        bytes4 selector
    ) internal {
        // Create and setup action
        BaseSwapper swapper = BaseSwapper(params.impl);
        Deployer.setupBaseAction(swapper, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(swapper, manager, executors, selector);
        Deployer.setupTokenThresholdAction(swapper, manager, params.admin, params.tokenThresholdActionParams);
        Deployer.setupRelayedAction(swapper, manager, params.admin, params.relayedActionParams);

        // Set token out
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setTokenOut.selector);
        swapper.setTokenOut(params.tokenOut);
        manager.unauthorize(swapper, address(this), swapper.setTokenOut.selector);

        // Set swap signer
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setSwapSigner.selector);
        swapper.setSwapSigner(params.swapSigner);
        manager.unauthorize(swapper, address(this), swapper.setSwapSigner.selector);

        // Set default max slippage
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setDefaultMaxSlippage.selector);
        swapper.setDefaultMaxSlippage(params.defaultMaxSlippage);
        manager.unauthorize(swapper, address(this), swapper.setDefaultMaxSlippage.selector);

        // Set custom token max slippages
        bool isCustomSlippageLengthValid = params.customSlippageTokens.length == params.customSlippageValues.length;
        require(isCustomSlippageLengthValid, 'DEPLOYER_SLIPPAGES_INVALID_LEN');
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setTokenMaxSlippage.selector);
        for (uint256 i = 0; i < params.customSlippageTokens.length; i++) {
            swapper.setTokenMaxSlippage(params.customSlippageTokens[i], params.customSlippageValues[i]);
        }
        manager.unauthorize(swapper, address(this), swapper.setTokenMaxSlippage.selector);

        // Deny requested tokens
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setDeniedTokens.selector);
        swapper.setDeniedTokens(params.deniedTokens, _trues(params.deniedTokens.length));
        manager.unauthorize(swapper, address(this), swapper.setDeniedTokens.selector);

        // Authorize action to swap and withdraw
        bytes4[] memory whats = Arrays.from(smartVault.swap.selector, smartVault.withdraw.selector);
        manager.authorize(smartVault, address(swapper), whats);
    }

    function _trues(uint256 length) internal pure returns (bool[] memory arr) {
        arr = new bool[](length);
        for (uint256 i = 0; i < length; i = i.uncheckedAdd(1)) arr[i] = true;
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

import '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';
import '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/Arrays.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsHelpers.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsManager.sol';

import './BaseSmartVaultDeployer.sol';
import './actions/swap/OneInchSwapper.sol';
import './actions/swap/ParaswapSwapper.sol';
import './actions/withdraw/Withdrawer.sol';

// solhint-disable avoid-low-level-calls

contract L1SmartVaultDeployer is BaseSmartVaultDeployer {
    using PermissionsHelpers for PermissionsManager;

    struct Params {
        address[] owners;
        IRegistry registry;
        PermissionsManager manager;
        Deployer.SmartVaultParams smartVaultParams;
        ClaimerActionParams claimerActionParams;
        SwapperActionParams oneInchSwapperActionParams;
        SwapperActionParams paraswapSwapperActionParams;
        BptSwapperActionParams bptSwapperActionParams;
        WithdrawerActionParams withdrawerActionParams;
    }

    struct WithdrawerActionParams {
        address impl;
        address admin;
        address[] managers;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.WithdrawalActionParams withdrawalActionParams;
        Deployer.TimeLockedActionParams timeLockedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    constructor(address owner) BaseSmartVaultDeployer(owner) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function deploy(Params memory params) external onlyOwner {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.manager, params.smartVaultParams);
        _setupClaimer(smartVault, params.manager, params.claimerActionParams);
        _setupSwapper(smartVault, params.manager, params.oneInchSwapperActionParams, OneInchSwapper.call.selector);
        _setupSwapper(smartVault, params.manager, params.paraswapSwapperActionParams, ParaswapSwapper.call.selector);
        _setupBptSwapper(smartVault, params.manager, params.bptSwapperActionParams);
        _setupWithdrawer(smartVault, params.manager, params.withdrawerActionParams);
        Deployer.transferPermissionManagerControl(params.manager, params.owners);
    }

    function _setupWithdrawer(SmartVault smartVault, PermissionsManager manager, WithdrawerActionParams memory params)
        internal
    {
        // Create and setup action
        Withdrawer withdrawer = Withdrawer(params.impl);
        Deployer.setupBaseAction(withdrawer, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(withdrawer, manager, executors, withdrawer.call.selector);
        Deployer.setupRelayedAction(withdrawer, manager, params.admin, params.relayedActionParams);
        Deployer.setupTokenThresholdAction(withdrawer, manager, params.admin, params.tokenThresholdActionParams);
        Deployer.setupWithdrawalAction(withdrawer, manager, params.admin, params.withdrawalActionParams);

        // Authorize action to withdraw from Smart Vault
        manager.authorize(smartVault, address(withdrawer), smartVault.withdraw.selector);
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

import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';
import '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/Arrays.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsHelpers.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsManager.sol';

import './BaseSmartVaultDeployer.sol';
import './actions/bridge/L2HopBridger.sol';
import './actions/swap/OneInchSwapper.sol';
import './actions/swap/ParaswapSwapper.sol';

// solhint-disable avoid-low-level-calls

contract L2SmartVaultDeployer is BaseSmartVaultDeployer {
    using UncheckedMath for uint256;
    using PermissionsHelpers for PermissionsManager;

    struct Params {
        address[] owners;
        IRegistry registry;
        PermissionsManager manager;
        Deployer.SmartVaultParams smartVaultParams;
        ClaimerActionParams claimerActionParams;
        SwapperActionParams oneInchSwapperActionParams;
        SwapperActionParams paraswapSwapperActionParams;
        BptSwapperActionParams bptSwapperActionParams;
        L2HopBridgerActionParams l2HopBridgerActionParams;
    }

    struct L2HopBridgerActionParams {
        address impl;
        address admin;
        address[] managers;
        uint256 maxDeadline;
        uint256 maxSlippage;
        uint256 maxBonderFeePct;
        uint256 destinationChainId;
        HopAmmParams[] hopAmmParams;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct HopAmmParams {
        address token;
        address amm;
    }

    constructor(address owner) BaseSmartVaultDeployer(owner) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function deploy(Params memory params) external onlyOwner {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.manager, params.smartVaultParams);
        _setupClaimer(smartVault, params.manager, params.claimerActionParams);
        _setupSwapper(smartVault, params.manager, params.oneInchSwapperActionParams, OneInchSwapper.call.selector);
        _setupSwapper(smartVault, params.manager, params.paraswapSwapperActionParams, ParaswapSwapper.call.selector);
        _setupBptSwapper(smartVault, params.manager, params.bptSwapperActionParams);
        _setupL2HopBridger(smartVault, params.manager, params.l2HopBridgerActionParams);
        Deployer.transferPermissionManagerControl(params.manager, params.owners);
    }

    function _setupL2HopBridger(
        SmartVault smartVault,
        PermissionsManager manager,
        L2HopBridgerActionParams memory params
    ) internal {
        // Create and setup action
        L2HopBridger bridger = L2HopBridger(payable(params.impl));
        Deployer.setupBaseAction(bridger, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(bridger, manager, executors, bridger.call.selector);
        Deployer.setupRelayedAction(bridger, manager, params.admin, params.relayedActionParams);
        Deployer.setupTokenThresholdAction(bridger, manager, params.admin, params.tokenThresholdActionParams);

        // Set bridger max deadline
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setMaxDeadline.selector);
        bridger.setMaxDeadline(params.maxDeadline);
        manager.unauthorize(bridger, address(this), bridger.setMaxDeadline.selector);

        // Set bridger max slippage
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setMaxSlippage.selector);
        bridger.setMaxSlippage(params.maxSlippage);
        manager.unauthorize(bridger, address(this), bridger.setMaxSlippage.selector);

        // Set bridger max bonder fee pct
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setMaxBonderFeePct.selector);
        bridger.setMaxBonderFeePct(params.maxBonderFeePct);
        manager.unauthorize(bridger, address(this), bridger.setMaxBonderFeePct.selector);

        // Set bridger AMMs
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setTokenAmm.selector);
        for (uint256 i = 0; i < params.hopAmmParams.length; i = i.uncheckedAdd(1)) {
            HopAmmParams memory hopAmmParam = params.hopAmmParams[i];
            bridger.setTokenAmm(hopAmmParam.token, hopAmmParam.amm);
        }
        manager.unauthorize(bridger, address(this), bridger.setTokenAmm.selector);

        // Set bridger destination chain ID
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setDestinationChainId.selector);
        bridger.setDestinationChainId(params.destinationChainId);
        manager.unauthorize(bridger, address(this), bridger.setDestinationChainId.selector);

        // Authorize action to bridge and withdraw from Smart Vault
        bytes4[] memory whats = Arrays.from(smartVault.bridge.selector, smartVault.withdraw.selector);
        manager.authorize(smartVault, address(bridger), whats);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@mimic-fi/v2-helpers/contracts/utils/ERC20Helpers.sol';

import '../actions/claim/IProtocolFeeWithdrawer.sol';

contract ProtocolFeeWithdrawerMock is IProtocolFeeWithdrawer {
    function withdrawCollectedFees(address[] calldata tokens, uint256[] calldata amounts, address recipient)
        external
        override
    {
        require(tokens.length == amounts.length, 'WITHDRAWER_INVALID_INPUT_LEN');
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ERC20Helpers.balanceOf(tokens[i], address(this)) >= amounts[i], 'INVALID_WITHDRAWER_BALANCE');
            ERC20Helpers.transfer(tokens[i], recipient, amounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}