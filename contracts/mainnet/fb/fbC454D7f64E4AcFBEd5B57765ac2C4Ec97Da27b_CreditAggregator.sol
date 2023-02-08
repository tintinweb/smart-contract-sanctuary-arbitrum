// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import { ICreditAggregator } from "./interfaces/ICreditAggregator.sol";
import { IAddressProvider } from "../interfaces/IAddressProvider.sol";
import { IGmxRewardRouter } from "../depositors/interfaces/IGmxRewardRouter.sol";
import { IGlpManager } from "../depositors/interfaces/IGlpManager.sol";
import { IGmxVault } from "../depositors/interfaces/IGmxVault.sol";

contract CreditAggregator is Initializable, ICreditAggregator {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    address private constant ZERO = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant GMX_DIVISION_LOSS_COMPENSATION = 10000; // 0.01 %
    uint256 private constant BASIS_POINTS_DIVISOR = 10000;
    uint256 private constant MINT_BURN_FEE_BASIS_POINTS = 25;
    uint256 private constant TAX_BASIS_POINTS = 50;
    uint8 private constant GLP_DECIMALS = 18;
    uint8 private constant USDG_DECIMALS = 18;
    uint8 private constant PRICE_DECIMALS = 30;

    address public addressProvider;
    address public router;
    address public glpManager;
    address public vault;
    address public usdg;
    address public glp;

    // @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function initialize(address _addressProvider) external initializer {
        require(_addressProvider != address(0), "CreditAggregator: _addressProvider cannot be 0x0");
        require(_addressProvider.isContract(), "CreditAggregator: _addressProvider is not a contract");

        addressProvider = _addressProvider;
    }

    function update() public {
        router = IAddressProvider(addressProvider).getGmxRewardRouter();
        glpManager = IGmxRewardRouter(router).glpManager();
        glp = IGlpManager(glpManager).glp();
        vault = IGlpManager(glpManager).vault();
        usdg = IGlpManager(glpManager).usdg();
    }

    /// @dev Get glp price
    /// @return 1e30
    function getGlpPrice(bool _isBuying) public view override returns (uint256) {
        // uint256[] memory aums = IGlpManager(glpManager).getAums();

        // if (aums.length > 0) {
        //     uint256 aum;

        //     if (_isBuying) {
        //         aum = aums[0];
        //     } else {
        //         aum = aums[1];
        //     }

        //     uint256 glpSupply = _totalSupply(glp);

        //     if (glpSupply > 0) {
        //         return aum.mul(10**PRICE_DECIMALS) / glpSupply;
        //     }
        // }

        uint256 aumInUsdg = IGlpManager(glpManager).getAumInUsdg(_isBuying);
        uint256 glpSupply = _totalSupply(glp);

        if (glpSupply > 0) {
            return aumInUsdg.mul(10**PRICE_DECIMALS).div(glpSupply);
        }

        return 0;
    }

    /* 
        glpPrice = 939690091372936156490347029512
        btcPrice = 23199207122640000000000000000000000
        ethPrice = 1652374189683000000000000000000000
        usdcPrice = 1000000000000000000000000000000

        # glp to token
        3422 × 1e18 × 0.939 × 1e30  / btcPrice / 1e18 glp decimals
        3422 × 1e18 × 0.939 × 1e30 / ethPrice / 1e18 glp decimals
        3422 × 1e18 × 0.939 × 1e30 / usdcPrice / 1e18 glp decimals

        # token to glp
        2 × 1e8 × btcPrice  / glpPrice / 1e8 token decimals
        2 × 1e18 × ethPrice / glpPrice / 1e18 token decimals
        300 × 1e6 × usdcPrice / glpPrice / 1e6 token decimals
     */

    function getBuyGlpToAmount(address _fromToken, uint256 _tokenAmountIn) external view override returns (uint256, uint256) {
        uint256 tokenPrice = IGmxVault(vault).getMinPrice(_fromToken);
        uint256 glpPrice = getGlpPrice(true);
        uint256 glpAmount = _tokenAmountIn.mul(tokenPrice).div(glpPrice);
        uint256 tokenDecimals = IGmxVault(vault).tokenDecimals(_fromToken);
        uint256 usdgAmount = _tokenAmountIn.mul(tokenPrice).div(10**PRICE_DECIMALS);

        glpAmount = adjustForDecimals(glpAmount, tokenDecimals, GLP_DECIMALS);
        usdgAmount = adjustForDecimals(usdgAmount, tokenDecimals, USDG_DECIMALS);

        uint256 feeBasisPoints = IGmxVault(vault).getFeeBasisPoints(_fromToken, usdgAmount, MINT_BURN_FEE_BASIS_POINTS, TAX_BASIS_POINTS, true);

        glpAmount = glpAmount.mul(BASIS_POINTS_DIVISOR - feeBasisPoints).div(BASIS_POINTS_DIVISOR);

        return (glpAmount, feeBasisPoints);
    }

    function getSellGlpFromAmount(address _fromToken, uint256 _tokenAmountIn) external view override returns (uint256, uint256) {
        uint256 tokenPrice = IGmxVault(vault).getMaxPrice(_fromToken);
        uint256 glpPrice = getGlpPrice(false);

        uint256 glpAmount = _tokenAmountIn.mul(tokenPrice).div(glpPrice);
        uint256 tokenDecimals = IGmxVault(vault).tokenDecimals(_fromToken);
        uint256 usdgAmount = _tokenAmountIn.mul(tokenPrice).div(10**PRICE_DECIMALS);

        glpAmount = adjustForDecimals(glpAmount, tokenDecimals, GLP_DECIMALS);
        usdgAmount = adjustForDecimals(usdgAmount, tokenDecimals, USDG_DECIMALS);

        uint256 feeBasisPoints = IGmxVault(vault).getFeeBasisPoints(_fromToken, usdgAmount, MINT_BURN_FEE_BASIS_POINTS, TAX_BASIS_POINTS, false);

        glpAmount = glpAmount.mul(BASIS_POINTS_DIVISOR).div(BASIS_POINTS_DIVISOR - feeBasisPoints);
        glpAmount = glpAmount.add(glpAmount.div(GMX_DIVISION_LOSS_COMPENSATION));

        return (glpAmount, feeBasisPoints);
    }

    function getBuyGlpFromAmount(address _toToken, uint256 _glpAmountIn) external view override returns (uint256, uint256) {
        uint256 tokenPrice = IGmxVault(vault).getMinPrice(_toToken);
        uint256 glpPrice = getGlpPrice(true);

        uint256 tokenAmountOut = _glpAmountIn.mul(glpPrice).div(tokenPrice);
        uint256 tokenDecimals = IGmxVault(vault).tokenDecimals(_toToken);

        tokenAmountOut = adjustForDecimals(tokenAmountOut, GLP_DECIMALS, tokenDecimals);

        uint256 usdgAmount = _glpAmountIn.mul(glpPrice).div(10**PRICE_DECIMALS);
        uint256 feeBasisPoints = IGmxVault(vault).getFeeBasisPoints(_toToken, usdgAmount, MINT_BURN_FEE_BASIS_POINTS, TAX_BASIS_POINTS, true);

        tokenAmountOut = tokenAmountOut.mul(BASIS_POINTS_DIVISOR).div(BASIS_POINTS_DIVISOR - feeBasisPoints);

        return (tokenAmountOut, feeBasisPoints);
    }

    function getSellGlpToAmount(address _toToken, uint256 _glpAmountIn) external view override returns (uint256, uint256) {
        uint256 tokenPrice = IGmxVault(vault).getMaxPrice(_toToken);
        uint256 glpPrice = getGlpPrice(false);
        uint256 tokenAmountOut = _glpAmountIn.mul(glpPrice).div(tokenPrice);
        uint256 tokenDecimals = IGmxVault(vault).tokenDecimals(_toToken);

        tokenAmountOut = adjustForDecimals(tokenAmountOut, GLP_DECIMALS, tokenDecimals);

        uint256 usdgAmount = _glpAmountIn.mul(glpPrice).div(10**PRICE_DECIMALS);
        uint256 feeBasisPoints = IGmxVault(vault).getFeeBasisPoints(_toToken, usdgAmount, MINT_BURN_FEE_BASIS_POINTS, TAX_BASIS_POINTS, false);

        tokenAmountOut = tokenAmountOut.mul(BASIS_POINTS_DIVISOR - feeBasisPoints).div(BASIS_POINTS_DIVISOR);

        return (tokenAmountOut, feeBasisPoints);
    }

    function adjustForDecimals(
        uint256 _amountIn,
        uint256 _divDecimals,
        uint256 _mulDecimals
    ) public pure override returns (uint256) {
        return _amountIn.mul(10**_mulDecimals).div(10**_divDecimals);
    }

    function getVaultPool(address _token)
        external
        view
        returns (
            uint256 poolTotalUSD,
            uint256 poolMaxPoolCapacity,
            uint256 poolAvailables,
            uint256 tokenPrice
        )
    {
        tokenPrice = getTokenPrice(_token);

        bool isStable = IGmxVault(vault).stableTokens(_token);
        uint256 availableAmount = IGmxVault(vault).poolAmounts(_token).sub(IGmxVault(vault).reservedAmounts(_token));
        uint256 tokenDecimals = IGmxVault(vault).tokenDecimals(_token);
        uint256 availableUsd = isStable
            ? IGmxVault(vault).poolAmounts(_token).mul(tokenPrice).div(10**tokenDecimals)
            : availableAmount.mul(tokenPrice).div(10**tokenDecimals);

        poolTotalUSD = availableUsd.add(IGmxVault(vault).guaranteedUsd(_token));
        poolMaxPoolCapacity = IGmxVault(vault).maxUsdgAmounts(_token);
        poolAvailables = poolTotalUSD.mul(10**tokenDecimals).div(tokenPrice);
    }

    function _totalSupply(address _token) internal view returns (uint256) {
        return IERC20Upgradeable(_token).totalSupply();
    }

    function getTokenPrice(address _token) public view override returns (uint256) {
        uint256 diff = 0;
        uint256 price0 = getMinPrice(_token);
        uint256 price1 = getMaxPrice(_token);
        uint256 price = price0;

        if (price0 > price1) {
            diff = price0 - price1;

            price = price1;
        } else {
            diff = price1 - price0;
        }

        if (diff > 0) {
            diff = diff / 2;
        }

        return price + diff;
    }

    function getMaxPrice(address _token) public view returns (uint256) {
        return IGmxVault(vault).getMaxPrice(_token);
    }

    function getMinPrice(address _token) public view returns (uint256) {
        return IGmxVault(vault).getMinPrice(_token);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditAggregator {
    function getGlpPrice(bool _isBuying) external view returns (uint256);

    function getBuyGlpToAmount(address _fromToken, uint256 _tokenAmountIn) external view returns (uint256, uint256);

    function getSellGlpToAmount(address _toToken, uint256 _glpAmountIn) external view returns (uint256, uint256);

    function getBuyGlpFromAmount(address _toToken, uint256 _glpAmountIn) external view returns (uint256, uint256);

    function getSellGlpFromAmount(address _fromToken, uint256 _tokenAmountIn) external view returns (uint256, uint256);

    function getTokenPrice(address _token) external view returns (uint256);

    function adjustForDecimals(
        uint256 _amountIn,
        uint256 _divDecimals,
        uint256 _mulDecimals
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IGlpManager {
    function glp() external view returns (address);

    function usdg() external view returns (address);

    function vault() external view returns (address);

    function getAums() external view returns (uint256[] memory);

    function getAumInUsdg(bool maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IGmxRewardRouter {
    function stakeGmx(uint256 _amount) external;

    function stakeEsGmx(uint256 _amount) external;

    function unstakeGmx(uint256 _amount) external;

    function unstakeEsGmx(uint256 _amount) external;

    function claim() external;

    function claimEsGmx() external;

    function claimFees() external;

    function compound() external;

    function glpManager() external view returns (address);

    function feeGlpTracker() external view returns (address);

    function stakedGlpTracker() external view returns (address);

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IGmxVault {
    function totalTokenWeights() external view returns (uint256);

    function usdgAmounts(address _swapToken) external view returns (uint256);

    function tokenDecimals(address _swapToken) external view returns (uint256);

    function tokenWeights(address _swapToken) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function stableTokens(address _token) external view returns (bool);

    function poolAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IAddressProvider {
    function getGmxRewardRouterV1() external view returns (address);

    function getGmxRewardRouter() external view returns (address);

    function getCreditAggregator() external view returns (address);

    event AddressSet(bytes32 indexed _key, address indexed _value);
}