// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/erc20/IIntegratedLimitOrderDEX.sol";

import "../common/Composable.sol";

import "../interfaces/erc20/IDEXRouter.sol";

// The IntegratedLimitOrderDEX has an issue where it can be upgraded with the FrabricERC20 by a Thread
// This is completely intended behavior
// The issue is that the UX is expected to offer infinite approvals on each DEX to reduce the number of transactions required
// If a single Thread goes rogue under this system, it can have the DEX drain user wallets via these approvals
// To solve this, this DEX router exists. Users approve the DEX router to spend their non-Thread tokens
// Since this isn't deployed by a proxy, no party can upgrade it to drain wallets
// Thread tokens are still directly traded via communicating with the Thread contract
// Order cancellations are still handled via communicating with the Thread contract
// The Thread can still upgrade to abscond with all coins held in open orders

// A global DEX not built into each Thread's ERC20 would also make sense,
// especially since there's now this global contract, except slash mechanics
// are most effective when the DEX is built into the ERC20 controlled by the Thread
// While Uniswap will be whitelisted, it can't be used to effectively hold tokens,
// only to sell them or provide liquidity (a form of holding yet one requiring equal
// capital lockup while providing a service others can take advantage of)

/**
 * @title DEXRouter contract
 * @author Fractional Finance
 * @notice This contract implements a router for DEXs, preventing Threads from upgrading to drain approvals
 */
contract DEXRouter is Composable, IDEXRouter {
  constructor() Composable("DEXRouter") initializer {
    __Composable_init("DEXRouter", true);
    supportsInterface[type(IDEXRouter).interfaceId] = true;
  }

  /**
   * @notice Purchase tokens from their DEX
   * @param token Token to be purchased
   * @param tradeToken Token to be used to purchase said token
   * @param payment Amount of `tradeToken` to be used in this purchase
   * @param price Price per whole token
   * @param minimumAmount Minimum amount of tokens to be received (in whole tokens)
   * @return filled uint256 quantity of succesfully purchased tokens
   */
  function buy(
    address token,
    address tradeToken,
    uint256 payment,
    uint256 price,
    uint256 minimumAmount
  ) external override returns (uint256) {
    // Doesn't bother checking the supported interfaces to minimize gas usage
    // If this function executes in its entirety, then the contract has all needed functions

    // Transfer only the specified of capital

    // We could derive tradeToken from IIntegratedLimitOrderDEX(token), yet that opens a frontrunning
    // attack where a user intending to spend token A ends up spending the much more expensive token B
    // While this could be the wrong tradeToken, if the contract is honest, the user will receive minimumAmount
    // no matter what so there's no issue. If it's dishonest, there's already little to be done
    // The important thing is that the user knows when they make their TX what capital they're putting up
    // and that is confirmed

    // Doesn't bother with SafeERC20 as the ILODEX will fully validate this transfer as needed
    // Solely wastes gas to use it here as well
    IERC20(tradeToken).transferFrom(msg.sender, token, payment);

    return IIntegratedLimitOrderDEX(token).buy(msg.sender, price, minimumAmount);
  }

  // Doesn't have a fund recover function as this should never hold funds
  // Any recovery function would be a MEV pit unless a specific address received the funds
  // That would acknowledge a Frabric which is not the intent nor role of this contract
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import {errors} from "../common/Errors.sol";
import "../common/IComposable.sol";

interface IIntegratedLimitOrderDEXCore {
  enum OrderType { Null, Buy, Sell }

  event Order(OrderType indexed orderType, uint256 indexed price);
  event OrderIncrease(address indexed trader, uint256 indexed price, uint256 amount);
  event OrderFill(address indexed orderer, uint256 indexed price, address indexed executor, uint256 amount);
  event OrderCancelling(address indexed trader, uint256 indexed price);
  event OrderCancellation(address indexed trader, uint256 indexed price, uint256 amount);

  // Part of core to symbolize amount should always be whole while price is atomic
  function atomic(uint256 amount) external view returns (uint256);

  function tradeToken() external view returns (address);

  // sell is here as the FrabricDAO has the ability to sell tokens on their integrated DEX
  // That means this function API can't change (along with cancelOrder which FrabricDAO also uses)
  // buy is meant to be used by users, offering greater flexibility, especially as it has a router for a frontend
  function sell(uint256 price, uint256 amount) external returns (uint256);
  function cancelOrder(uint256 price, uint256 i) external returns (bool);
}

interface IIntegratedLimitOrderDEX is IComposable, IIntegratedLimitOrderDEXCore {
  function tradeTokenBalance() external view returns (uint256);
  function tradeTokenBalances(address trader) external view returns (uint256);
  function locked(address trader) external view returns (uint256);

  function withdrawTradeToken(address trader) external;

  function buy(
    address trader,
    uint256 price,
    uint256 minimumAmount
  ) external returns (uint256);

  function pointType(uint256 price) external view returns (IIntegratedLimitOrderDEXCore.OrderType);
  function orderQuantity(uint256 price) external view returns (uint256);
  function orderTrader(uint256 price, uint256 i) external view returns (address);
  function orderAmount(uint256 price, uint256 i) external view returns (uint256);
}

error LessThanMinimumAmount(uint256 amount, uint256 minimumAmount);
error NotEnoughFunds(uint256 required, uint256 balance);
error NotOrderTrader(address caller, address trader);

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import "../interfaces/common/IComposable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Composable is Initializable, IComposable {
  // Doesn't use "name" due to IERC20 using "name"
  bytes32 public override contractName;
  // Version is global, and not per-interface, as interfaces aren't "DAO" and "FrabricDAO"
  // Any version which changes the API would change the interface ID, so checking
  // for supported functionality should be via supportsInterface, not version
  uint256 public override version;
  mapping(bytes4 => bool) public override supportsInterface;

  // While this could probably get away with 5 variables, and other contracts
  // with 20, the fact this is free (and a permanent decision) leads to using
  // these large gaps
  uint256[100] private __gap;

  // Code should set its name so Beacons can identify code
  // That said, code shouldn't declare support for interfaces or have any version
  // Hence this
  // Due to solidity requirements, final constracts (non-proxied) which call init
  // yet still use constructors will have to call this AND init. It's a minor
  // gas inefficiency not worth optimizing around
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(string memory name) {
    contractName = keccak256(bytes(name));

    supportsInterface[type(IERC165Upgradeable).interfaceId] = true;
    supportsInterface[type(IComposable).interfaceId] = true;
  }

  function __Composable_init(string memory name, bool finalized) internal onlyInitializing {
    contractName = keccak256(bytes(name));
    if (!finalized) {
      version = 1;
    } else {
      version = type(uint256).max;
    }

    supportsInterface[type(IERC165Upgradeable).interfaceId] = true;
    supportsInterface[type(IComposable).interfaceId] = true;
  }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/IComposable.sol";

interface IDEXRouter is IComposable {
  function buy(
    address token,
    address tradeToken,
    uint256 payment,
    uint256 price,
    uint256 minimumAmount
  ) external returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

library errors {
    error UnhandledEnumCase(string label, uint256 enumValue);
    error ZeroPrice();
    error ZeroAmount();

    error UnsupportedInterface(address contractAddress, bytes4 interfaceID);

    error ExternalCallFailed(address called, bytes4 selector, bytes error);

    error Unauthorized(address caller, address user);
    error Replay(uint256 nonce, uint256 expected);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IComposable is IERC165Upgradeable {
  function contractName() external returns (bytes32);
  // Returns uint256 max if not upgradeable
  function version() external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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