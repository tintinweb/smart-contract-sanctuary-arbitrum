// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
library SafeMath {
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

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

library LiquityMath {
  using SafeMath for uint;

  uint internal constant DECIMAL_PRECISION = 1e18;

  /* Precision for Nominal ICR (independent of price). Rationale for the value:
   *
   * - Making it “too high” could lead to overflows.
   * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
   *
   * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
   * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
   *
   */
  uint internal constant NICR_PRECISION = 1e20;

  function _min(uint _a, uint _b) internal pure returns (uint) {
    return (_a < _b) ? _a : _b;
  }

  function _max(uint _a, uint _b) internal pure returns (uint) {
    return (_a >= _b) ? _a : _b;
  }

  /*
   * Multiply two decimal numbers and use normal rounding rules:
   * -round product up if 19'th mantissa digit >= 5
   * -round product down if 19'th mantissa digit < 5
   *
   * Used only inside the exponentiation, _decPow().
   */
  function decMul(uint x, uint y) internal pure returns (uint decProd) {
    uint prod_xy = x.mul(y);

    decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
  }

  /*
   * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
   *
   * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
   *
   * Called by two functions that represent time in units of minutes:
   * 1) TroveManager._calcDecayedBaseRate
   * 2) CommunityIssuance._getCumulativeIssuanceFraction
   *
   * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
   * "minutes in 1000 years": 60 * 24 * 365 * 1000
   *
   * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
   * negligibly different from just passing the cap, since:
   *
   * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
   * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
   */
  function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
    if (_minutes > 525600000) {
      _minutes = 525600000;
    } // cap to avoid overflow

    if (_minutes == 0) {
      return DECIMAL_PRECISION;
    }

    uint y = DECIMAL_PRECISION;
    uint x = _base;
    uint n = _minutes;

    // Exponentiation-by-squaring
    while (n > 1) {
      if (n % 2 == 0) {
        x = decMul(x, x);
        n = n.div(2);
      } else {
        // if (n % 2 != 0)
        y = decMul(x, y);
        x = decMul(x, x);
        n = (n.sub(1)).div(2);
      }
    }

    return decMul(x, y);
  }

  function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
    return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
  }

  function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
    if (_debt > 0) {
      return _coll.mul(NICR_PRECISION).div(_debt);
    }
    // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
    else {
      // if (_debt == 0)
      return 2 ** 256 - 1;
    }
  }

  function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
    if (_debt > 0) {
      uint newCollRatio = _coll.mul(_price).div(_debt);

      return newCollRatio;
    }
    // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
    else {
      // if (_debt == 0)
      return 2 ** 256 - 1;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import './CToken.sol';
import '../Interfaces/ICErc20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../Interfaces/ITimelock.sol';
import '../Interfaces/IEIP712.sol';

/**
 * @title Compound's CErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
contract CErc20 is CToken, ICErc20, Initializable {
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the new money market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   */
  function initialize(
    address underlying_,
    address comptroller_,
    address interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    uint256 discountRateMantissa_,
    uint256 reserveFactorMantissa_
  ) public virtual initializer {
    initInternal(
      underlying_,
      comptroller_,
      interestRateModel_,
      initialExchangeRateMantissa_,
      name_,
      symbol_,
      decimals_,
      admin_,
      discountRateMantissa_,
      reserveFactorMantissa_
    );
  }

  function initInternal(
    address underlying_,
    address comptroller_,
    address interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    uint256 discountRateMantissa_,
    uint256 reserveFactorMantissa_
  ) internal onlyInitializing {
    // CToken initialize does the bulk of the work
    CToken.initialize(
      comptroller_,
      interestRateModel_,
      initialExchangeRateMantissa_,
      name_,
      symbol_,
      decimals_,
      true,
      admin_,
      discountRateMantissa_,
      reserveFactorMantissa_
    );

    isCEther = false;

    // Set underlying and sanity check it
    if (underlying_ == address(0)) {
      revert InvalidAddress();
    }
    underlying = underlying_;
    // ICToken(underlying).totalSupply();
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external override returns (uint256) {
    (uint256 err, ) = mintInternal(mintAmount);
    return err;
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external override returns (uint256) {
    return redeemInternal(redeemTokens);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external override returns (uint256) {
    return redeemUnderlyingInternal(redeemAmount);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external override returns (uint256) {
    return borrowInternal(borrowAmount);
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrow(uint256 repayAmount) external override returns (uint256) {
    (uint256 err, ) = repayBorrowInternal(repayAmount);
    return err;
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being paid off
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external override returns (uint256) {
    (uint256 err, ) = repayBorrowBehalfInternal(borrower, repayAmount);
    return err;
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) external override returns (uint256) {
    (uint256 err, ) = liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
    return err;
  }

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
   * @param token The address of the ERC-20 token to sweep
   */
  function sweepToken(address token) external override {
    if (address(token) == underlying) {
      revert CantSweepUnderlying();
    }
    uint256 underlyingBalanceBefore = ICToken(underlying).balanceOf(address(this));
    uint256 balance = ICToken(token).balanceOf(address(this));
    ICToken(token).transfer(admin, balance);
    uint256 underlyingBalanceAfter = ICToken(underlying).balanceOf(address(this));
    if (underlyingBalanceBefore != underlyingBalanceAfter) {
      revert UnderlyingBalanceError();
    }
  }

  /**
   * @notice The sender adds to reserves.
   * @param addAmount The amount fo underlying token to add as reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves(uint256 addAmount) external override returns (uint256) {
    return _addReservesInternal(addAmount);
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() internal view virtual override returns (uint256) {
    // ICToken token = ICToken(underlying);
    // return token.balanceOf(address(this));
    return underlyingBalance;
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
   *      This will revert due to insufficient balance or insufficient allowance.
   *      This function returns the actual amount received,
   *      which may be less than `amount` if there is a fee attached to the transfer.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferIn(address from, uint256 amount) internal virtual override returns (uint256) {
    ICToken token = ICToken(underlying);
    uint256 balanceBefore = ICToken(underlying).balanceOf(address(this));
    token.transferFrom(from, address(this), amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    if (!success) {
      revert TokenTransferInFailed();
    }

    // Calculate the amount that was *actually* transferred
    uint256 balanceAfter = ICToken(underlying).balanceOf(address(this));
    if (balanceAfter < balanceBefore) {
      revert TokenTransferInFailed();
    }
    uint256 finalAmount = balanceAfter - balanceBefore;
    underlyingBalance += finalAmount;
    return finalAmount; // underflow already checked above, just subtract
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
   *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
   *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
   *      it is >= amount, this should not revert in normal conditions.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferOut(address payable to, uint256 amount) internal virtual override {
    ICToken token = ICToken(underlying);
    token.transfer(to, amount);
    underlyingBalance -= amount;

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    if (!success) {
      revert TokenTransferOutFailed();
    }
  }

  function transferToTimelock(bool isBorrow, address to, uint256 underlyAmount) internal virtual override {
    address timelock = IComptroller(comptroller).timelock();

    if (ITimelock(timelock).consumeValuePreview(underlyAmount, address(this))) {
      ITimelock(timelock).consumeValue(underlyAmount);
      doTransferOut(payable(to), underlyAmount);
    } else {
      doTransferOut(payable(timelock), underlyAmount);
      ITimelock(timelock).createAgreement(
        isBorrow ? ITimelock.TimeLockActionType.BORROW : ITimelock.TimeLockActionType.REDEEM,
        underlyAmount,
        to
      );
    }
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mintWithPermit(uint256 mintAmount, uint256 deadline, bytes memory signature) external returns (uint256) {
    IEIP712(underlying).permit(msg.sender, address(this), mintAmount, deadline, signature);
    (uint256 err, ) = mintInternal(mintAmount);
    return err;
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrowWithPermit(
    uint256 repayAmount,
    uint256 deadline,
    bytes memory signature
  ) external returns (uint256) {
    IEIP712(underlying).permit(msg.sender, address(this), repayAmount, deadline, signature);
    (uint256 err, ) = repayBorrowInternal(repayAmount);
    return err;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './CToken.sol';
import '../Interfaces/ICErc20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../Interfaces/ITimelock.sol';
import '../Comptroller/LiquityMath.sol';

/**
 * @title Compound's CEther Contract
 * @notice CToken which wraps Ether
 * @author Compound
 */
contract CEther is CToken, Initializable {
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Construct a new CEther money market
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   */
  function initialize(
    address comptroller_,
    address interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    uint256 discountRateMantissa_,
    uint256 reserveFactorMantissa_
  ) public initializer {
    super.initialize(
      comptroller_,
      interestRateModel_,
      initialExchangeRateMantissa_,
      name_,
      symbol_,
      decimals_,
      true,
      admin_,
      discountRateMantissa_,
      reserveFactorMantissa_
    );

    isCEther = true;
  }

  function _syncUnderlyingBalance() external override onlyAdmin {
    underlyingBalance = address(this).balance;
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Reverts upon any failure
   */
  function mint() external payable {
    (uint256 err, ) = mintInternal(msg.value);
    requireNoError(err, 'mint failed');
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external returns (uint256) {
    return redeemInternal(redeemTokens);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
    return redeemUnderlyingInternal(redeemAmount);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external returns (uint256) {
    return borrowInternal(borrowAmount);
  }

  /**
   * @notice Sender repays their own borrow
   * @dev Reverts upon any failure
   */
  function repayBorrow() external payable {
    (uint256 err, ) = repayBorrowInternal(msg.value);
    requireNoError(err, 'repayBorrow failed');
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @dev Reverts upon any failure
   * @param borrower the account with the debt being paid off
   */
  function repayBorrowBehalf(address borrower) external payable {
    (uint256 err, uint256 actualRepay) = repayBorrowBehalfInternal(borrower, msg.value);
    if (actualRepay < msg.value) {
      (bool sent, ) = msg.sender.call{gas: 5300, value: msg.value - actualRepay}('');
      require(sent, 'refund failed');
    }
    requireNoError(err, 'repayBorrowBehalf failed');
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @dev Reverts upon any failure
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   */
  function liquidateBorrow(address borrower, address cTokenCollateral) external payable {
    (uint256 err, ) = liquidateBorrowInternal(borrower, msg.value, cTokenCollateral);
    requireNoError(err, 'liquidateBorrow failed');
  }

  /**
   * @notice The sender adds to reserves.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves() external payable returns (uint256) {
    return _addReservesInternal(msg.value);
  }

  /**
   * @notice Send Ether to CEther to mint
   */
  receive() external payable {
    (uint256 err, ) = mintInternal(msg.value);
    requireNoError(err, 'mint failed');
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of Ether, before this message
   * @dev This excludes the value of the current message, if any
   * @return The quantity of Ether owned by this contract
   */
  function getCashPrior() internal view override returns (uint256) {
    // (MathError err, uint256 startingBalance) = address(this).balance.subUInt(msg.value);
    // require(err == MathError.NO_ERROR);
    // return startingBalance;
    return underlyingBalance;
  }

  /**
   * @notice Perform the actual transfer in, which is a no-op
   * @param from Address sending the Ether
   * @param amount Amount of Ether being sent
   * @return The actual amount of Ether transferred
   */
  function doTransferIn(address from, uint256 amount) internal override returns (uint256) {
    // Sanity checks
    require(msg.sender == from, 'sender mismatch');
    require(msg.value >= amount, 'value mismatch');
    underlyingBalance += amount;
    return amount;
  }

  function doTransferOut(address payable to, uint256 amount) internal override {
    underlyingBalance -= amount;
    /* Send the Ether, with minimal gas and revert on failure */
    // to.transfer(amount);
    (bool success, ) = to.call{gas: 5300, value: amount}('');
    require(success, 'unable to send value, recipient may have reverted');
  }

  function transferToTimelock(bool isBorrow, address to, uint256 underlyAmount) internal virtual override {
    address timelock = IComptroller(comptroller).timelock();

    if (ITimelock(timelock).consumeValuePreview(underlyAmount, address(this))) {
      // if leaky bucket covers underlyAmount, release immediately
      ITimelock(timelock).consumeValue(underlyAmount);
      doTransferOut(payable(to), underlyAmount);
    } else {
      doTransferOut(payable(timelock), underlyAmount);
      ITimelock(timelock).createAgreement(
        isBorrow ? ITimelock.TimeLockActionType.BORROW : ITimelock.TimeLockActionType.REDEEM,
        underlyAmount,
        to
      );
    }
  }

  function requireNoError(uint256 errCode, string memory message) internal pure {
    if (errCode == uint256(0)) {
      return;
    }

    bytes memory fullMessage = new bytes(bytes(message).length + 5);
    uint256 i;

    for (i = 0; i < bytes(message).length; i++) {
      fullMessage[i] = bytes(message)[i];
    }

    fullMessage[i + 0] = bytes1(uint8(32));
    fullMessage[i + 1] = bytes1(uint8(40));
    fullMessage[i + 2] = bytes1(uint8(48 + (errCode / 10)));
    fullMessage[i + 3] = bytes1(uint8(48 + (errCode % 10)));
    fullMessage[i + 4] = bytes1(uint8(41));

    require(errCode == uint256(0), string(fullMessage));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '../Interfaces/IComptroller.sol';
import '../Interfaces/IPriceOracle.sol';
import '../Interfaces/IInterestRateModel.sol';
import './CTokenStorage.sol';
import '../Exponential/ExponentialNoErrorNew.sol';
import '../Comptroller/LiquityMath.sol';
import '../SumerErrors.sol';

/**
 * @title Compound's CToken Contract
 * @notice Abstract base for CTokens
 * @author Compound
 */
abstract contract CToken is CTokenStorage, ExponentialNoErrorNew, SumerErrors {
  modifier onlyAdmin() {
    // Check caller is admin
    if (msg.sender != admin) {
      revert OnlyAdmin();
    }
    _;
  }

  /**
   * @notice Initialize the money market
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ EIP-20 name of this token
   * @param symbol_ EIP-20 symbol of this token
   * @param decimals_ EIP-20 decimal precision of this token
   */
  function initialize(
    address comptroller_,
    address interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    bool isCToken_,
    address payable _admin,
    uint256 discountRateMantissa_,
    uint256 reserveFactorMantissa_
  ) internal {
    admin = _admin;
    if (accrualBlockNumber != 0 || borrowIndex != 0) {
      revert MarketCanOnlyInitializeOnce(); // market may only be initialized once
    }

    isCToken = isCToken_;

    // Set initial exchange rate
    initialExchangeRateMantissa = initialExchangeRateMantissa_;
    if (initialExchangeRateMantissa <= 0) {
      revert InvalidExchangeRate();
    } // initial exchange rate must be greater than zero

    discountRateMantissa = discountRateMantissa_;
    if (discountRateMantissa <= 0 || discountRateMantissa > 1e18) {
      revert InvalidDiscountRate();
    } // rate must in [0,100]

    reserveFactorMantissa = reserveFactorMantissa_;
    // Set the comptroller
    // Set market's comptroller to newComptroller
    comptroller = comptroller_;

    // Emit NewComptroller(oldComptroller, newComptroller)
    emit NewComptroller(address(0), comptroller_);

    // Initialize block number and borrow index (block number mocks depend on comptroller being set)
    accrualBlockNumber = getBlockNumber();
    borrowIndex = 1e18;

    // Set the interest rate model (depends on block number / borrow index)
    interestRateModel = interestRateModel_;
    emit NewMarketInterestRateModel(address(0), interestRateModel_);

    name = name_;
    symbol = symbol_;
    decimals = decimals_;

    // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
    _notEntered = true;
  }

  /**
   * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
   * @dev Called by both `transfer` and `transferFrom` internally
   * @param spender The address of the account performing the transfer
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param tokens The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferTokens(address spender, address src, address dst, uint256 tokens) internal returns (uint256) {
    /* Fail if transfer not allowed */
    IComptroller(comptroller).transferAllowed(address(this), src, dst, tokens);

    /* Do not allow self-transfers */
    if (src == dst) {
      revert TransferNotAllowed();
    }

    /* Get the allowance, infinite for the account owner */
    uint256 startingAllowance = 0;
    if (spender == src) {
      startingAllowance = ~uint256(0);
    } else {
      startingAllowance = transferAllowances[src][spender];
    }

    /* Do the calculations, checking for {under,over}flow */
    uint allowanceNew = startingAllowance - tokens;
    uint srcTokensNew = accountTokens[src] - tokens;
    uint dstTokensNew = accountTokens[dst] + tokens;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    accountTokens[src] = srcTokensNew;
    accountTokens[dst] = dstTokensNew;

    /* Eat some of the allowance (if necessary) */
    if (startingAllowance != ~uint256(0)) {
      transferAllowances[src][spender] = allowanceNew;
    }

    /* We emit a Transfer event */
    emit Transfer(src, dst, tokens);

    // unused function
    // comptroller.transferVerify(address(this), src, dst, tokens);

    return uint256(0);
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
    return transferTokens(msg.sender, msg.sender, dst, amount) == uint256(0);
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(address src, address dst, uint256 amount) external override nonReentrant returns (bool) {
    return transferTokens(msg.sender, src, dst, amount) == uint256(0);
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    address src = msg.sender;
    transferAllowances[src][spender] = amount;
    emit Approval(src, spender, amount);
    return true;
  }

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return transferAllowances[owner][spender];
  }

  /**
   * @notice Get the token balance of the `owner`
   * @param owner The address of the account to query
   * @return The number of tokens owned by `owner`
   */
  function balanceOf(address owner) external view override returns (uint256) {
    return accountTokens[owner];
  }

  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner) external override returns (uint256) {
    Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
    return mul_ScalarTruncate(exchangeRate, accountTokens[owner]);
  }

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by comptroller to more efficiently perform liquidity checks.
   * @param account Address of the account to snapshot
   * @return (possible error, token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address account) external view override returns (uint256, uint256, uint256, uint256) {
    return (uint(0), accountTokens[account], borrowBalanceStoredInternal(account), exchangeRateStoredInternal());
  }

  /**
   * @dev Function to simply retrieve block number
   *  This exists mainly for inheriting test contracts to stub this result.
   */
  function getBlockNumber() internal view returns (uint256) {
    return block.number;
  }

  /**
   * @notice Returns the current per-block borrow interest rate for this cToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view override returns (uint256) {
    return IInterestRateModel(interestRateModel).getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
  }

  /**
   * @notice Returns the current per-block supply interest rate for this cToken
   * @return The supply interest rate per block, scaled by 1e18
   */
  function supplyRatePerBlock() external view override returns (uint256) {
    return
      IInterestRateModel(interestRateModel).getSupplyRate(
        getCashPrior(),
        totalBorrows,
        totalReserves,
        reserveFactorMantissa
      );
  }

  /**
   * @notice Returns the current total borrows plus accrued interest
   * @return The total borrows with interest
   */
  function totalBorrowsCurrent() external override nonReentrant returns (uint256) {
    accrueInterest();
    return totalBorrows;
  }

  /**
   * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
   * @param account The address whose balance should be calculated after updating borrowIndex
   * @return The calculated balance
   */
  function borrowBalanceCurrent(address account) external override nonReentrant returns (uint256) {
    accrueInterest();
    return borrowBalanceStored(account);
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return The calculated balance
   */
  function borrowBalanceStored(address account) public view override returns (uint256) {
    return borrowBalanceStoredInternal(account);
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return (error code, the calculated balance or 0 if error code is non-zero)
   */
  function borrowBalanceStoredInternal(address account) internal view returns (uint256) {
    /* Get borrowBalance and borrowIndex */
    BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

    /* If borrowBalance = 0 then borrowIndex is likely also 0.
     * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
     */
    if (borrowSnapshot.principal == 0) {
      return 0;
    }

    /* Calculate new borrow balance using the interest index:
     *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
     */
    uint principalTimesIndex = borrowSnapshot.principal * borrowIndex;
    return principalTimesIndex / borrowSnapshot.interestIndex;
  }

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() public override nonReentrant returns (uint256) {
    accrueInterest();
    return exchangeRateStored();
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() public view override returns (uint256) {
    return exchangeRateStoredInternal();
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return (error code, calculated exchange rate scaled by 1e18)
   */
  function exchangeRateStoredInternal() internal view returns (uint256) {
    if (!isCToken) {
      return initialExchangeRateMantissa;
    }

    uint _totalSupply = totalSupply;
    if (_totalSupply == 0) {
      /*
       * If there are no tokens minted:
       *  exchangeRate = initialExchangeRate
       */
      return initialExchangeRateMantissa;
    } else {
      /*
       * Otherwise:
       *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
       */
      uint totalCash = getCashPrior();
      uint cashPlusBorrowsMinusReserves = totalCash + totalBorrows - totalReserves;
      uint exchangeRate = (cashPlusBorrowsMinusReserves * expScale) / _totalSupply;

      return exchangeRate;
    }
  }

  /**
   * @notice Get cash balance of this cToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view override returns (uint256) {
    return getCashPrior();
  }

  /**
   * @notice Applies accrued interest to total borrows and reserves
   * @dev This calculates interest accrued from the last checkpointed block
   *   up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public virtual override returns (uint256) {
    /* Remember the initial block number */
    uint256 currentBlockNumber = getBlockNumber();
    uint256 accrualBlockNumberPrior = accrualBlockNumber;

    /* Short-circuit accumulating 0 interest */
    if (accrualBlockNumberPrior == currentBlockNumber) {
      return uint256(0);
    }

    /* Read the previous values out of storage */
    uint256 cashPrior = getCashPrior();
    uint256 borrowsPrior = totalBorrows;
    uint256 reservesPrior = totalReserves;
    uint256 borrowIndexPrior = borrowIndex;

    /* Calculate the current borrow interest rate */
    uint borrowRateMantissa = IInterestRateModel(interestRateModel).getBorrowRate(
      cashPrior,
      borrowsPrior,
      reservesPrior
    );
    // require(borrowRateMantissa <= borrowRateMaxMantissa, 'borrow rate is absurdly high');

    /* Calculate the number of blocks elapsed since the last accrual */
    uint blockDelta = currentBlockNumber - accrualBlockNumberPrior;

    /*
     * Calculate the interest accumulated into borrows and reserves and the new index:
     *  simpleInterestFactor = borrowRate * blockDelta
     *  interestAccumulated = simpleInterestFactor * totalBorrows
     *  totalBorrowsNew = interestAccumulated + totalBorrows
     *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
     *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
     */

    Exp memory simpleInterestFactor = mul_(Exp({mantissa: borrowRateMantissa}), blockDelta);
    uint interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, borrowsPrior);
    uint totalBorrowsNew = interestAccumulated + borrowsPrior;
    uint totalReservesNew = mul_ScalarTruncateAddUInt(
      Exp({mantissa: reserveFactorMantissa}),
      interestAccumulated,
      reservesPrior
    );
    uint borrowIndexNew = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accrualBlockNumber = currentBlockNumber;
    borrowIndex = borrowIndexNew;
    totalBorrows = totalBorrowsNew;
    totalReserves = totalReservesNew;

    /* We emit an AccrueInterest event */
    emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

    return uint256(0);
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
   */
  function mintInternal(uint256 mintAmount) internal nonReentrant returns (uint256, uint256) {
    accrueInterest();
    // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
    return mintFresh(msg.sender, mintAmount, true);
  }

  /**
   * @notice User supplies assets into the market and receives cTokens in exchange
   * @dev Assumes interest has already been accrued up to the current block
   * @param minter The address of the account which is supplying the assets
   * @param mintAmount The amount of the underlying asset to supply
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
   */
  function mintFresh(address minter, uint256 mintAmount, bool doTransfer) internal returns (uint256, uint256) {
    /* Fail if mint not allowed */
    IComptroller(comptroller).mintAllowed(address(this), minter, mintAmount);

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert MintMarketNotFresh();
    }

    Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     *  We call `doTransferIn` for the minter and the mintAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
     *  side-effects occurred. The function returns the amount actually transferred,
     *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
     *  of cash.
     */
    uint actualMintAmount;
    if (doTransfer) {
      actualMintAmount = doTransferIn(minter, mintAmount);
    } else {
      actualMintAmount = mintAmount;
      underlyingBalance += mintAmount;
    }

    /*
     * We get the current exchange rate and calculate the number of cTokens to be minted:
     *  mintTokens = actualMintAmount / exchangeRate
     */

    uint mintTokens = div_(actualMintAmount, exchangeRate);

    /*
     * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
     *  totalSupplyNew = totalSupply + mintTokens
     *  accountTokensNew = accountTokens[minter] + mintTokens
     */
    totalSupply = totalSupply + mintTokens;
    accountTokens[minter] = accountTokens[minter] + mintTokens;

    /* We emit a Mint event, and a Transfer event */
    emit Mint(minter, actualMintAmount, mintTokens);
    emit Transfer(address(this), minter, mintTokens);

    /* We call the defense hook */
    // unused function
    // comptroller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

    return (uint256(0), actualMintAmount);
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemInternal(uint256 redeemTokens) internal nonReentrant returns (uint256) {
    accrueInterest();
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    return redeemFresh(payable(msg.sender), redeemTokens, 0, true);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to receive from redeeming cTokens
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlyingInternal(uint256 redeemAmount) internal nonReentrant returns (uint256) {
    accrueInterest();
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    return redeemFresh(payable(msg.sender), 0, redeemAmount, true);
  }

  /**
   * @notice User redeems cTokens in exchange for the underlying asset
   * @dev Assumes interest has already been accrued up to the current block
   * @param redeemer The address of the account which is redeeming the tokens
   * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   * @param checkTimelock true=check timelock, false=direct transfer
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemFresh(
    address payable redeemer,
    uint256 redeemTokensIn,
    uint256 redeemAmountIn,
    bool checkTimelock
  ) internal returns (uint256) {
    if (redeemTokensIn != 0 && redeemAmountIn != 0) {
      revert TokenInOrAmountInMustBeZero();
    }

    /* exchangeRate = invoke Exchange Rate Stored() */
    Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});

    uint redeemTokens;
    uint redeemAmount;
    /* If redeemTokensIn > 0: */
    if (redeemTokensIn > 0) {
      /*
       * We calculate the exchange rate and the amount of underlying to be redeemed:
       *  redeemTokens = redeemTokensIn
       *  redeemAmount = redeemTokensIn x exchangeRateCurrent
       */
      redeemTokens = redeemTokensIn;
      redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokensIn);
    } else {
      /*
       * We get the current exchange rate and calculate the amount to be redeemed:
       *  redeemTokens = redeemAmountIn / exchangeRate
       *  redeemAmount = redeemAmountIn
       */

      redeemTokens = div_(redeemAmountIn, exchangeRate);
      redeemAmount = redeemAmountIn;
    }

    /* Fail if redeem not allowed */
    IComptroller(comptroller).redeemAllowed(address(this), redeemer, redeemTokens);

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert RedeemMarketNotFresh();
    }

    /* Fail gracefully if protocol has insufficient cash */
    if (isCToken && (getCashPrior() < redeemAmount)) {
      revert RedeemTransferOutNotPossible();
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write previously calculated values into storage */
    totalSupply = totalSupply - redeemTokens;
    accountTokens[redeemer] = accountTokens[redeemer] - redeemTokens;

    /*
     * We invoke doTransferOut for the redeemer and the redeemAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken has redeemAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    // doTransferOut(redeemer, vars.redeemAmount);
    if (checkTimelock) {
      transferToTimelock(false, redeemer, redeemAmount);
    } else {
      doTransferOut(redeemer, redeemAmount);
    }

    /* We emit a Transfer event, and a Redeem event */
    emit Transfer(redeemer, address(this), redeemTokens);
    emit Redeem(redeemer, redeemAmount, redeemTokens);

    /* We call the defense hook */
    // IComptroller(comptroller).redeemVerify(address(this), redeemer, redeemAmount, redeemTokens);

    return uint256(0);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrowInternal(uint256 borrowAmount) internal nonReentrant returns (uint256) {
    accrueInterest();
    // borrowFresh emits borrow-specific logs on errors, so we don't need to
    return borrowFresh(payable(msg.sender), borrowAmount, true);
  }

  /**
   * @notice Users borrow assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrowFresh(address payable borrower, uint256 borrowAmount, bool doTransfer) internal returns (uint256) {
    /* Fail if borrow not allowed */
    IComptroller(comptroller).borrowAllowed(address(this), borrower, borrowAmount);

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert BorrowMarketNotFresh();
    }

    /* Fail gracefully if protocol has insufficient underlying cash */
    if (isCToken && (getCashPrior() < borrowAmount)) {
      revert BorrowCashNotAvailable();
    }

    /*
     * We calculate the new borrower and total borrow balances, failing on overflow:
     *  accountBorrowsNew = accountBorrows + borrowAmount
     *  totalBorrowsNew = totalBorrows + borrowAmount
     */
    uint accountBorrowsPrev = borrowBalanceStoredInternal(borrower);
    uint accountBorrowsNew = accountBorrowsPrev + borrowAmount;
    uint totalBorrowsNew = totalBorrows + borrowAmount;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = totalBorrowsNew;

    /*
     * We invoke doTransferOut for the borrower and the borrowAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken borrowAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    // doTransferOut(borrower, borrowAmount);

    if (doTransfer) {
      transferToTimelock(true, borrower, borrowAmount);
    } else {
      underlyingBalance -= borrowAmount;
    }

    /* We emit a Borrow event */
    emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);

    /* We call the defense hook */
    IComptroller(comptroller).borrowVerify(borrower, borrowAmount);

    return uint256(0);
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowInternal(uint256 repayAmount) internal nonReentrant returns (uint256, uint256) {
    accrueInterest();
    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    return repayBorrowFresh(msg.sender, msg.sender, repayAmount);
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being paid off
   * @param repayAmount The amount to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowBehalfInternal(
    address borrower,
    uint256 repayAmount
  ) internal nonReentrant returns (uint256, uint256) {
    accrueInterest();
    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    return repayBorrowFresh(msg.sender, borrower, repayAmount);
  }

  /**
   * @notice Borrows are repaid by another user (possibly the borrower).
   * @param payer the account paying off the borrow
   * @param borrower the account with the debt being paid off
   * @param repayAmount the amount of underlying tokens being returned
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowFresh(address payer, address borrower, uint256 repayAmount) internal returns (uint256, uint256) {
    /* Fail if repayBorrow not allowed */
    IComptroller(comptroller).repayBorrowAllowed(address(this), payer, borrower, repayAmount);

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert RepayBorrowMarketNotFresh();
    }

    /* We remember the original borrowerIndex for verification purposes */
    uint256 borrowerIndex = accountBorrows[borrower].interestIndex;

    /* We fetch the amount the borrower owes, with accumulated interest */
    uint accountBorrowsPrev = borrowBalanceStoredInternal(borrower);

    /* If repayAmount == -1, repayAmount = accountBorrows */
    uint repayAmountFinal = LiquityMath._min(repayAmount, accountBorrowsPrev);

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the payer and the repayAmount
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken holds an additional repayAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *   it returns the amount actually transferred, in case of a fee.
     */
    uint actualRepayAmount = doTransferIn(payer, repayAmountFinal);

    /*
     * We calculate the new borrower and total borrow balances, failing on underflow:
     *  accountBorrowsNew = accountBorrows - actualRepayAmount
     *  totalBorrowsNew = totalBorrows - actualRepayAmount
     */
    uint accountBorrowsNew = accountBorrowsPrev - actualRepayAmount;
    uint totalBorrowsNew = totalBorrows - actualRepayAmount;

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = totalBorrowsNew;

    /* We emit a RepayBorrow event */
    emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);

    /* We call the defense hook */
    // IComptroller(comptroller).repayBorrowVerify(address(this), payer, borrower, actualRepayAmount, borrowerIndex);

    return (uint256(0), actualRepayAmount);
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function liquidateBorrowInternal(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) internal nonReentrant returns (uint256, uint256) {
    accrueInterest();
    ICToken(cTokenCollateral).accrueInterest();

    // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
    return liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
  }

  /**
   * @notice The liquidator liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param liquidator The address repaying the borrow and seizing collateral
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function liquidateBorrowFresh(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) internal returns (uint256, uint256) {
    /* Fail if liquidate not allowed */
    IComptroller(comptroller).liquidateBorrowAllowed(
      address(this),
      address(cTokenCollateral),
      liquidator,
      borrower,
      repayAmount
    );

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert LiquidateMarketNotFresh();
    }

    /* Verify cTokenCollateral market's block number equals current block number */
    if (ICToken(cTokenCollateral).accrualBlockNumber() != getBlockNumber()) {
      revert LiquidateCollateralMarketNotFresh();
    }

    /* Fail if borrower = liquidator */
    if (borrower == liquidator) {
      revert LiquidateBorrow_LiquidatorIsBorrower();
    }

    /* Fail if repayAmount = 0 */
    if (repayAmount == 0) {
      revert LiquidateBorrow_RepayAmountIsZero();
    }

    if (repayAmount == ~uint256(0)) {
      revert LiquidateBorrow_RepayAmountIsMax();
    }

    /* Fail if repayBorrow fails */
    (, uint256 actualRepayAmount) = repayBorrowFresh(liquidator, borrower, repayAmount);

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We calculate the number of collateral tokens that will be seized */
    (, uint256 seizeTokens, uint256 seizeProfitTokens) = liquidateCalculateSeizeTokens(
      cTokenCollateral,
      actualRepayAmount
    );

    /* Revert if borrower collateral token balance < seizeTokens */
    if (ICToken(cTokenCollateral).balanceOf(borrower) < seizeTokens) {
      revert LiquidateBorrow_SeizeTooMuch();
    }

    // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
    if (cTokenCollateral == address(this)) {
      seizeInternal(address(this), liquidator, borrower, seizeTokens, seizeProfitTokens, false, uint256(0));
    } else {
      ICToken(cTokenCollateral).seize(liquidator, borrower, seizeTokens, seizeProfitTokens, false, uint256(0));
    }

    /* We emit a LiquidateBorrow event */
    emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(cTokenCollateral), seizeTokens);

    /* We call the defense hook */
    // unused function
    // comptroller.liquidateBorrowVerify(address(this), address(cTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

    return (uint256(0), actualRepayAmount);
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Will fail unless called by another cToken during the process of liquidation.
   *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize in total (including profit)
   * @param seizeProfitTokens The number of cToken to seize as profit
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens,
    uint256 seizeProfitTokens,
    bool isRedemption,
    uint256 redemptionRateMantissa
  ) external override nonReentrant returns (uint256) {
    if (redemptionRateMantissa <= 0) {
      redemptionRateMantissa = 0;
    }
    if (redemptionRateMantissa > expScale) {
      redemptionRateMantissa = expScale;
    }

    return
      seizeInternal(
        msg.sender,
        liquidator,
        borrower,
        seizeTokens,
        seizeProfitTokens,
        isRedemption,
        redemptionRateMantissa
      );
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
   *  Its absolutely critical to use msg.sender as the seizer cToken and not a parameter.
   * @param seizerToken The contract seizing the collateral (i.e. borrowed cToken)
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seizeInternal(
    address seizerToken,
    address liquidator,
    address borrower,
    uint256 seizeTokens,
    uint256 seizeProfitTokens,
    bool isRedemption,
    uint256 redemptionRateMantissa
  ) internal returns (uint256) {
    /* Fail if seize not allowed */
    IComptroller(comptroller).seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);

    /* Fail if borrower = liquidator */
    if (borrower == liquidator) {
      revert Seize_LiquidatorIsBorrower();
    }

    /*
     * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
     *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
     *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
     */
    uint protocolSeizeTokens;
    if (isRedemption) {
      // redemption: protocol seize = total seize * redemptionRate
      protocolSeizeTokens = mul_(seizeTokens, Exp({mantissa: redemptionRateMantissa}));
    } else {
      // liquidation: protocol seize = profit * liquidatiionShare 30%
      protocolSeizeTokens = mul_(seizeProfitTokens, Exp({mantissa: protocolSeizeShareMantissa}));
    }
    if (seizeTokens < protocolSeizeTokens) {
      revert NotEnoughForSeize();
    }

    uint liquidatorSeizeTokens = seizeTokens - protocolSeizeTokens;
    Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});
    uint protocolSeizeAmount = mul_ScalarTruncate(exchangeRate, protocolSeizeTokens);
    uint totalReservesNew = totalReserves + protocolSeizeAmount;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    totalReserves = totalReservesNew;
    totalSupply = totalSupply - protocolSeizeTokens;
    accountTokens[borrower] = accountTokens[borrower] - seizeTokens;
    accountTokens[liquidator] = accountTokens[liquidator] + liquidatorSeizeTokens;

    /* Emit a Transfer event */
    emit Transfer(borrower, liquidator, liquidatorSeizeTokens);
    emit Transfer(borrower, address(this), protocolSeizeTokens);
    emit ReservesAdded(address(this), protocolSeizeAmount, totalReservesNew);

    /* We call the defense hook */
    // unused function
    // comptroller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);

    if (isRedemption) {
      redeemFresh(payable(liquidator), liquidatorSeizeTokens, uint256(0), true);
    } else {
      redeemFresh(payable(liquidator), liquidatorSeizeTokens, uint256(0), false);
    }

    return uint256(0);
  }

  /*** Admin Functions ***/

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(address payable newPendingAdmin) external override onlyAdmin returns (uint256) {
    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = pendingAdmin;

    // Store pendingAdmin with value newPendingAdmin
    if (newPendingAdmin == address(0)) {
      revert InvalidAddress();
    } // Address is Zero
    pendingAdmin = newPendingAdmin;

    // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

    return uint256(0);
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() external override returns (uint256) {
    // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
    if (msg.sender != pendingAdmin || msg.sender == address(0)) {
      revert OnlyPendingAdmin();
    }

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = payable(0);

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

    return uint256(0);
  }

  /**
   * @notice Sets a new comptroller for the market
   * @dev Admin function to set a new comptroller
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setComptroller(address newComptroller) public override onlyAdmin returns (uint256) {
    address oldComptroller = comptroller;
    // Ensure invoke comptroller.isComptroller() returns true
    if (!IComptroller(newComptroller).isComptroller()) {
      revert InvalidComptroller(); // market method returned false
    }

    // Set market's comptroller to newComptroller
    comptroller = newComptroller;

    // Emit NewComptroller(oldComptroller, newComptroller)
    emit NewComptroller(oldComptroller, newComptroller);

    return uint256(0);
  }

  /**
   * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
   * @dev Admin function to accrue interest and set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactor(uint256 newReserveFactorMantissa) external override nonReentrant returns (uint256) {
    accrueInterest();
    // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
    return _setReserveFactorFresh(newReserveFactorMantissa);
  }

  /**
   * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
   * @dev Admin function to set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactorFresh(uint256 newReserveFactorMantissa) internal onlyAdmin returns (uint256) {
    // Verify market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      revert SetReservesFactorMarketNotFresh();
    }

    // Check newReserveFactor ≤ maxReserveFactor
    if (newReserveFactorMantissa > RESERVE_FACTOR_MAX_MANTISSA) {
      revert InvalidReserveFactor();
    }

    uint256 oldReserveFactorMantissa = reserveFactorMantissa;
    reserveFactorMantissa = newReserveFactorMantissa;

    emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

    return uint256(0);
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring from msg.sender
   * @param addAmount Amount of addition to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReservesInternal(uint256 addAmount) internal nonReentrant returns (uint256) {
    accrueInterest();
    // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
    (uint256 error, ) = _addReservesFresh(addAmount);
    return error;
  }

  /**
   * @notice Add reserves by transferring from caller
   * @dev Requires fresh interest accrual
   * @param addAmount Amount of addition to reserves
   * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
   */
  function _addReservesFresh(uint256 addAmount) internal returns (uint256, uint256) {
    // totalReserves + actualAddAmount
    uint256 totalReservesNew;
    uint256 actualAddAmount;

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      revert AddReservesMarketNotFresh();
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the caller and the addAmount
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken holds an additional addAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *  it returns the amount actually transferred, in case of a fee.
     */

    actualAddAmount = doTransferIn(msg.sender, addAmount);

    totalReservesNew = totalReserves + actualAddAmount;

    /* Revert on overflow */
    if (totalReservesNew < totalReserves) {
      revert AddReservesOverflow();
    }

    // Store reserves[n+1] = reserves[n] + actualAddAmount
    totalReserves = totalReservesNew;

    /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
    emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

    /* Return (NO_ERROR, actualAddAmount) */
    return (uint256(0), actualAddAmount);
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring to admin
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReserves(uint256 reduceAmount) external override nonReentrant returns (uint256) {
    accrueInterest();
    // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
    return _reduceReservesFresh(reduceAmount);
  }

  /**
   * @notice Reduces reserves by transferring to admin
   * @dev Requires fresh interest accrual
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReservesFresh(uint256 reduceAmount) internal onlyAdmin returns (uint256) {
    // totalReserves - reduceAmount
    uint256 totalReservesNew;

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      revert ReduceReservesMarketNotFresh();
    }

    // Fail gracefully if protocol has insufficient underlying cash
    if (getCashPrior() < reduceAmount) {
      revert ReduceReservesCashNotAvailable();
    }

    // Check reduceAmount ≤ reserves[n] (totalReserves)
    if (reduceAmount > totalReserves) {
      revert InvalidReduceAmount();
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    totalReservesNew = totalReserves - reduceAmount;

    // Store reserves[n+1] = reserves[n] - reduceAmount
    totalReserves = totalReservesNew;

    // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
    doTransferOut(admin, reduceAmount);

    emit ReservesReduced(admin, reduceAmount, totalReservesNew);

    return uint256(0);
  }

  /**
   * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
   * @dev Admin function to accrue interest and update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModel(address newInterestRateModel) public override returns (uint256) {
    accrueInterest();
    // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
    return _setInterestRateModelFresh(newInterestRateModel);
  }

  /**
   * @notice updates the interest rate model (*requires fresh interest accrual)
   * @dev Admin function to update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModelFresh(address newInterestRateModel) internal onlyAdmin returns (uint256) {
    // Used to store old model for use in the event that is emitted on success
    address oldInterestRateModel;
    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      revert SetInterestRateModelMarketNotFresh();
    }

    // Track the market's current interest rate model
    oldInterestRateModel = interestRateModel;

    // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
    if (!IInterestRateModel(interestRateModel).isInterestRateModel()) {
      revert InvalidInterestRateModel();
    }

    // Set the interest rate model to newInterestRateModel
    interestRateModel = newInterestRateModel;

    // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
    emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

    return uint256(0);
  }

  function _syncUnderlyingBalance() virtual external onlyAdmin {
    underlyingBalance = ICToken(underlying).balanceOf(address(this));
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying owned by this contract
   */
  function getCashPrior() internal view virtual returns (uint256);

  /**
   * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
   *  This may revert due to insufficient balance or insufficient allowance.
   */
  function doTransferIn(address from, uint256 amount) internal virtual returns (uint256);

  /**
   * @dev Performs a transfer out, ideally returning an explanatory error code upon failure rather than reverting.
   *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
   *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
   */
  function doTransferOut(address payable to, uint256 amount) internal virtual;

  function transferToTimelock(bool isBorrow, address to, uint256 amount) internal virtual;

  /*** Reentrancy Guard ***/

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   */
  modifier nonReentrant() {
    require(_notEntered, 're-entered'); // re-entered
    _notEntered = false;
    _;
    _notEntered = true; // get a gas-refund post-Istanbul
  }

  /**
   * @notice Returns true if the given cToken market has been deprecated
   * @dev All borrows in a deprecated cToken market can be immediately liquidated
   */
  function isDeprecated() public view returns (bool) {
    return
      IComptroller(comptroller).marketGroupId(address(this)) == 0 &&
      //borrowGuardianPaused[cToken] == true &&
      IComptroller(comptroller).borrowGuardianPaused(address(this)) &&
      reserveFactorMantissa == 1e18;
  }

  /**
   * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
   * @dev Used in liquidation (called in ICToken(cToken).liquidateBorrowFresh)
   * @param cTokenCollateral The address of the collateral cToken
   * @param actualRepayAmount The amount of cTokenBorrowed underlying to convert into cTokenCollateral tokens
   * @return (errorCode, number of cTokenCollateral tokens to be seized in a liquidation, number of cTokenCollateral tokens to be seized as profit in a liquidation)
   */
  function liquidateCalculateSeizeTokens(
    address cTokenCollateral,
    uint256 actualRepayAmount
  ) public view returns (uint256, uint256, uint256) {
    (bool repayListed, uint8 repayTokenGroupId, ) = IComptroller(comptroller).markets(address(this));
    require(repayListed, 'repay token not listed');
    (bool seizeListed, uint8 seizeTokenGroupId, ) = IComptroller(comptroller).markets(cTokenCollateral);
    require(seizeListed, 'seize token not listed');

    (
      uint256 heteroLiquidationIncentive,
      uint256 homoLiquidationIncentive,
      uint256 sutokenLiquidationIncentive
    ) = IComptroller(comptroller).liquidationIncentiveMantissa();

    // default is repaying heterogeneous assets
    uint256 liquidationIncentiveMantissa = heteroLiquidationIncentive;
    if (repayTokenGroupId == seizeTokenGroupId) {
      if (CToken(address(this)).isCToken() == false) {
        // repaying sutoken
        liquidationIncentiveMantissa = sutokenLiquidationIncentive;
      } else {
        // repaying homogeneous assets
        liquidationIncentiveMantissa = homoLiquidationIncentive;
      }
    }

    /* Read oracle prices for borrowed and collateral markets */
    uint256 priceBorrowedMantissa = IComptroller(comptroller).getUnderlyingPriceNormalized(address(this));
    uint256 priceCollateralMantissa = IComptroller(comptroller).getUnderlyingPriceNormalized(cTokenCollateral);
    /*
     * Get the exchange rate and calculate the number of collateral tokens to seize:
     *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
     *  seizeTokens = seizeAmount / exchangeRate
     *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
     */
    uint256 exchangeRateMantissa = ICToken(cTokenCollateral).exchangeRateStored(); // Note: reverts on error

    Exp memory numerator = mul_(
      Exp({mantissa: liquidationIncentiveMantissa + expScale}),
      Exp({mantissa: priceBorrowedMantissa})
    );
    Exp memory profitNumerator = mul_(
      Exp({mantissa: liquidationIncentiveMantissa}),
      Exp({mantissa: priceBorrowedMantissa})
    );
    Exp memory denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));

    Exp memory ratio = div_(numerator, denominator);
    Exp memory profitRatio = div_(profitNumerator, denominator);

    uint256 seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);
    uint256 seizeProfitTokens = mul_ScalarTruncate(profitRatio, actualRepayAmount);

    return (uint256(0), seizeTokens, seizeProfitTokens);
  }

  function _setDiscountRate(uint256 discountRateMantissa_) external onlyAdmin returns (uint256) {
    uint256 oldDiscountRateMantissa_ = discountRateMantissa;
    discountRateMantissa = discountRateMantissa_;
    emit NewDiscountRate(oldDiscountRateMantissa_, discountRateMantissa_);
    return discountRateMantissa;
  }

  function borrowAndDepositBack(address borrower, uint256 borrowAmount) external nonReentrant returns (uint256) {
    // only allowed to be called from su token
    if (CToken(msg.sender).isCToken()) {
      revert NotSuToken();
    }
    // only cToken has this function
    if (!isCToken) {
      revert NotCToken();
    }
    if (!IComptroller(comptroller).isListed(msg.sender)) {
      revert MarketNotListed();
    }
    if (!IComptroller(comptroller).isListed(address(this))) {
      revert MarketNotListed();
    }
    return borrowAndDepositBackInternal(payable(borrower), borrowAmount);
  }

  /**
   * @notice Sender borrows assets from the protocol and deposit all of them back to the protocol
   * @param borrowAmount The amount of the underlying asset to borrow and deposit
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrowAndDepositBackInternal(address payable borrower, uint256 borrowAmount) internal returns (uint256) {
    accrueInterest();
    borrowFresh(borrower, borrowAmount, false);
    mintFresh(borrower, borrowAmount, false);
    return uint256(0);
  }

  function getBorrowSnapshot(address borrower) external view returns (BorrowSnapshot memory) {
    return accountBorrows[borrower];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import '../Interfaces/ICToken.sol';

abstract contract CTokenStorage is ICToken {
  bool public isCToken;
  bool public isCEther;
  /// @dev Guard variable for re-entrancy checks
  bool internal _notEntered;

  /// @notice Underlying asset for this CToken
  address public underlying;

  /// @notice EIP-20 token name for this token
  string public name;

  /// @notice EIP-20 token symbol for this token
  string public symbol;

  /// @notice EIP-20 token decimals for this token
  uint8 public decimals;

  /// @dev Maximum borrow rate that can ever be applied (.0005% / block)
  uint256 internal constant BORROW_RATE_MAX_MANTISSA = 0.0005e16;

  /// @dev Maximum fraction of interest that can be set aside for reserves
  uint256 internal constant RESERVE_FACTOR_MAX_MANTISSA = 1e18;

  /// @notice Administrator for this contract
  address payable public admin;

  /// @notice Pending administrator for this contract
  address payable public pendingAdmin;

  /// @notice Contract which oversees inter-cToken operations
  address public comptroller;

  /// @notice Model which tells what the current interest rate should be
  address public interestRateModel;

  /// @dev Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
  uint256 internal initialExchangeRateMantissa;

  /// @notice Fraction of interest currently set aside for reserves
  uint256 public reserveFactorMantissa;

  /// @notice Block number that interest was last accrued at
  uint256 public override accrualBlockNumber;

  /// @notice Accumulator of the total earned interest rate since the opening of the market
  uint256 public borrowIndex;

  /// @notice Total amount of outstanding borrows of the underlying in this market
  uint256 public totalBorrows;

  /// @notice Total amount of reserves of the underlying held in this market
  uint256 public totalReserves;

  /// @notice Total number of tokens in circulation
  uint256 public override totalSupply;

  /// @dev Official record of token balances for each account
  mapping(address => uint256) internal accountTokens;

  /// @dev Approved token transfer amounts on behalf of others
  mapping(address => mapping(address => uint256)) internal transferAllowances;

  /// @notice Container for borrow balance information
  /// @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
  /// @member interestIndex Global borrowIndex as of the most recent balance-changing action
  struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex;
  }

  /// @dev Mapping of account addresses to outstanding borrow balances
  mapping(address => BorrowSnapshot) internal accountBorrows;

  /// @notice Share of seized collateral that is added to reserves
  uint256 public constant protocolSeizeShareMantissa = 30e16; //30% of profit

  uint256 public discountRateMantissa = 1e18;

  uint256 public underlyingBalance;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import '../Interfaces/IEIP20NonStandard.sol';
import './CErc20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title Compound's suErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
contract suErc20 is CErc20 {
  constructor() {
    _disableInitializers();
  }
  /**
   * @notice Initialize the new money market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   */
  function initialize(
    address underlying_,
    address comptroller_,
    address interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    uint256 discountRateMantissa_,
    uint256 reserveFactorMantissa_
  ) public override initializer {
    // CToken initialize does the bulk of the work
    CErc20.initInternal(
      underlying_,
      comptroller_,
      interestRateModel_,
      initialExchangeRateMantissa_,
      name_,
      symbol_,
      decimals_,
      admin_,
      discountRateMantissa_,
      reserveFactorMantissa_
    );

    isCToken = false;
  }

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  // function getCashPrior() internal view virtual override returns (uint256) {
  //   // ICToken token = ICToken(underlying);
  //   // return token.balanceOf(address(this));
  //   return underlyingBalance;
  // }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
   *      This will revert due to insufficient balance or insufficient allowance.
   *      This function returns the actual amount received,
   *      which may be less than `amount` if there is a fee attached to the transfer.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferIn(address from, uint256 amount) internal override returns (uint256) {
    IEIP20NonStandard token = IEIP20NonStandard(underlying);
    token.burnFrom(from, amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    if (!success) {
      revert TokenTransferInFailed();
    }

    // Calculate the amount that was *actually* transferred
    return amount;
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
   *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
   *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
   *      it is >= amount, this should not revert in normal conditions.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferOut(address payable to, uint256 amount) internal override {
    IEIP20NonStandard token = IEIP20NonStandard(underlying);
    token.mint(to, amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    if (!success) {
      revert TokenTransferOutFailed();
    }
  }

  function executeRedemption(
    address redeemer,
    address provider,
    uint256 repayAmount,
    address cTokenCollateral,
    uint256 seizeAmount,
    uint256 redemptionRateMantissa
  ) external nonReentrant returns (uint256) {
    if (msg.sender != IComptroller(comptroller).redemptionManager()) {
      revert OnlyRedemptionManager();
    }

    if (this.isCToken()) {
      revert NotSuToken();
    }

    uint256 cExRateMantissa = CErc20(cTokenCollateral).exchangeRateStored();
    uint256 cPriceMantissa = IComptroller(comptroller).getUnderlyingPriceNormalized(cTokenCollateral);
    uint256 csuPriceMantissa = IComptroller(comptroller).getUnderlyingPriceNormalized(address(this));

    accrueInterest();
    ICToken(cTokenCollateral).accrueInterest();

    uint256 seizeVal = (cPriceMantissa * seizeAmount * cExRateMantissa) / expScale / expScale;
    uint256 repayVal = (csuPriceMantissa * repayAmount) / expScale;
    if (seizeVal > repayVal) {
      revert RedemptionSeizeTooMuch();
    }

    repayBorrowFresh(redeemer, provider, repayAmount);
    ICToken(cTokenCollateral).seize(redeemer, provider, seizeAmount, uint256(0), true, redemptionRateMantissa);

    emit RedeemFaceValue(redeemer, provider, repayAmount, cTokenCollateral, seizeAmount, redemptionRateMantissa);
    return uint256(0);
  }

  function protectedMint(
    address cTokenCollateral,
    uint256 cBorrowAmount,
    uint256 suBorrowAmount
  ) external nonReentrant returns (uint256) {
    if (!CToken(cTokenCollateral).isCToken()) {
      revert NotCToken();
    }

    (, uint8 suGroupId, ) = IComptroller(comptroller).markets(address(this));
    (, uint8 cGroupId, ) = IComptroller(comptroller).markets(cTokenCollateral);
    if (suGroupId != cGroupId) {
      revert ProtectedMint_OnlyAllowAssetsInTheSameGroup();
    }

    accrueInterest();

    if (cBorrowAmount <= 0) {
      revert InvalidAmount();
    }

    uint256 bnd = CToken(cTokenCollateral).borrowAndDepositBack(payable(msg.sender), cBorrowAmount);
    if (bnd != 0) {
      revert BorrowAndDepositBackFailed();
    }
    return borrowFresh(payable(msg.sender), suBorrowAmount, true);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.19;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoErrorNew {
  uint constant expScale = 1e18;
  uint constant doubleScale = 1e36;
  uint constant halfExpScale = expScale / 2;
  uint constant mantissaOne = expScale;

  struct Exp {
    uint mantissa;
  }

  struct Double {
    uint mantissa;
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mul_ScalarTruncate(Exp memory a, uint scalar) internal pure returns (uint) {
    Exp memory product = mul_(a, scalar);
    return truncate(product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) internal pure returns (uint) {
    Exp memory product = mul_(a, scalar);
    return add_(truncate(product), addend);
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint n, string memory errorMessage) internal pure returns (uint224) {
    require(n < 2 ** 224, errorMessage);
    return uint224(n);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2 ** 32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(uint a, uint b) internal pure returns (uint) {
    return a + b;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(uint a, uint b) internal pure returns (uint) {
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
  }

  function mul_(Exp memory a, uint b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint a, Exp memory b) internal pure returns (uint) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
  }

  function mul_(Double memory a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint a, Double memory b) internal pure returns (uint) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint a, uint b) internal pure returns (uint) {
    return a * b;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
  }

  function div_(Exp memory a, uint b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint a, Exp memory b) internal pure returns (uint) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
  }

  function div_(Double memory a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint a, Double memory b) internal pure returns (uint) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint a, uint b) internal pure returns (uint) {
    return a / b;
  }

  function fraction(uint a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a, doubleScale), b)});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICErc20 {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) external returns (uint256);

  function sweepToken(address token) external;

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IComptroller {
  /*** Assets You Are In ***/
  function isComptroller() external view returns (bool);

  function markets(address) external view returns (bool, uint8, bool);

  function getAllMarkets() external view returns (address[] memory);

  function oracle() external view returns (address);

  function redemptionManager() external view returns (address);

  function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

  function exitMarket(address cToken) external returns (uint256);

  function closeFactorMantissa() external view returns (uint256);

  function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);

  // function getAssetsIn(address) external view returns (ICToken[] memory);
  function claimComp(address) external;

  function compAccrued(address) external view returns (uint256);

  function getAssetsIn(address account) external view returns (address[] memory);

  function timelock() external view returns (address);

  function getUnderlyingPriceNormalized(address cToken) external view returns (uint256);
  /*** Policy Hooks ***/

  function mintAllowed(address cToken, address minter, uint256 mintAmount) external;

  function redeemAllowed(address cToken, address redeemer, uint256 redeemTokens) external;
  // function redeemVerify(address cToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external;

  function borrowAllowed(address cToken, address borrower, uint256 borrowAmount) external;
  function borrowVerify(address borrower, uint borrowAmount) external;

  function repayBorrowAllowed(address cToken, address payer, address borrower, uint256 repayAmount) external;
  // function repayBorrowVerify(
  //   address cToken,
  //   address payer,
  //   address borrower,
  //   uint repayAmount,
  //   uint borrowerIndex
  // ) external;

  function seizeAllowed(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external;
  function seizeVerify(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint seizeTokens
  ) external;

  function transferAllowed(address cToken, address src, address dst, uint256 transferTokens) external;

  /*** Liquidity/Liquidation Calculations ***/

  function liquidationIncentiveMantissa() external view returns (uint256, uint256, uint256);

  function isListed(address asset) external view returns (bool);

  function marketGroupId(address asset) external view returns (uint8);

  function getHypotheticalAccountLiquidity(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  ) external view returns (uint256, uint256, uint256);

  // function _getMarketBorrowCap(address cToken) external view returns (uint256);

  /// @notice Emitted when an action is paused on a market
  event ActionPaused(address cToken, string action, bool pauseState);

  /// @notice Emitted when borrow cap for a cToken is changed
  event NewBorrowCap(address indexed cToken, uint256 newBorrowCap);

  /// @notice Emitted when borrow cap guardian is changed
  event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

  /// @notice Emitted when pause guardian is changed
  event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

  event RemoveAssetGroup(uint8 indexed groupId, uint8 equalAssetsGroupNum);

  /// @notice AssetGroup, contains information of groupName and rateMantissas
  struct AssetGroup {
    uint8 groupId;
    string groupName;
    uint256 intraCRateMantissa;
    uint256 intraMintRateMantissa;
    uint256 intraSuRateMantissa;
    uint256 interCRateMantissa;
    uint256 interSuRateMantissa;
    bool exist;
  }

  function getAssetGroupNum() external view returns (uint8);

  function getAssetGroup(uint8 groupId) external view returns (AssetGroup memory);

  function getAllAssetGroup() external view returns (AssetGroup[] memory);

  function assetGroupIdToIndex(uint8) external view returns (uint8);

  function borrowGuardianPaused(address cToken) external view returns (bool);

  function getCompAddress() external view returns (address);

  function borrowCaps(address cToken) external view returns (uint256);

  function liquidateBorrowAllowed(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) external view;
  // function liquidateBorrowVerify(
  //   address cTokenBorrowed,
  //   address cTokenCollateral,
  //   address liquidator,
  //   address borrower,
  //   uint repayAmount,
  //   uint seizeTokens
  // ) external;

  function getCollateralRate(address collateralToken, address liabilityToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICToken {
  /*** Market Events ***/

  /**
   * @notice Event emitted when interest is accrued
   */
  event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

  /**
   * @notice Event emitted when tokens are minted
   */
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

  /**
   * @notice Event emitted when tokens are redeemed
   */
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

  /**
   * @notice Event emitted when underlying is borrowed
   */
  event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is repaid
   */
  event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is liquidated
   */
  event LiquidateBorrow(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral,
    uint256 seizeTokens
  );

  /*** Admin Events ***/

  /**
   * @notice Event emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @notice Event emitted when comptroller is changed
   */
  event NewComptroller(address oldComptroller, address newComptroller);

  /**
   * @notice Event emitted when interestRateModel is changed
   */
  event NewMarketInterestRateModel(address oldInterestRateModel, address newInterestRateModel);

  /**
   * @notice Event emitted when the reserve factor is changed
   */
  event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

  /**
   * @notice Event emitted when the reserves are added
   */
  event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

  /**
   * @notice Event emitted when the reserves are reduced
   */
  event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  event NewDiscountRate(uint256 oldDiscountRateMantissa, uint256 newDiscountRateMantissa);

  event RedeemFaceValue(
    address indexed redeemer,
    address indexed provider,
    uint256 repayAmount,
    address seizeToken,
    uint256 seizeAmount, // user seize amount + protocol seize amount
    uint256 redemptionRateMantissa
  );

  /*** User Interface ***/

  function transfer(address dst, uint256 amount) external returns (bool);

  function transferFrom(address src, address dst, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);

  function borrowRatePerBlock() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function borrowBalanceStored(address account) external view returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function getCash() external view returns (uint256);

  function accrueInterest() external returns (uint256);

  function accrualBlockNumber() external returns (uint256);

  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens,
    uint256 seizeProfitTokens,
    bool isRedemption,
    uint256 redemptionRateMantissa
  ) external returns (uint256);

  /*** Admin Functions ***/

  function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

  function _acceptAdmin() external returns (uint256);

  function _setComptroller(address newComptroller) external returns (uint256);

  function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

  function _reduceReserves(uint256 reduceAmount) external returns (uint256);

  function _setInterestRateModel(address newInterestRateModel) external returns (uint256);

  function discountRateMantissa() external view returns (uint256);

  function _setDiscountRate(uint256 discountRateMantissa) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {
  /**
   * @notice Get the total number of tokens in circulation
   * @return The supply of tokens
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Gets the balance of the specified address
   * @param owner The address from which the balance will be retrieved
   * @return balance The balance
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  ///
  /// !!!!!!!!!!!!!!
  /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
  /// !!!!!!!!!!!!!!
  ///

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transfer(address dst, uint256 amount) external;

  ///
  /// !!!!!!!!!!!!!!
  /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
  /// !!!!!!!!!!!!!!
  ///

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external;

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved
   * @return success Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool success);

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return remaining The number of tokens allowed to be spent
   */
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  /**
   * @dev Creates `amount` new tokens for `to`.
   * See {ERC20-_mint}.
   * Requirements:
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from the caller.
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   * See {ERC20-_burn} and {ERC20-allowance}.
   * Requirements:
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEIP712 {
  function permit(address owner, address spender, uint256 value, uint256 deadline, bytes memory signature) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface IInterestRateModel {
  function isInterestRateModel() external view returns (bool);

  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view returns (uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPriceOracle {
  /**
   * @notice Get the underlying price of a cToken asset
   * @param cToken The cToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   *  Zero means the price is unavailable.
   */
  function getUnderlyingPrice(address cToken) external view returns (uint256);

  /**
   * @notice Get the underlying price of cToken asset (normalized)
   * = getUnderlyingPrice * (10 ** (18 - cToken.decimals))
   */
  function getUnderlyingPriceNormalized(address cToken_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITimelock {
  /** @notice Event emitted when a new time-lock agreement is created
   * @param agreementId ID of the created agreement
   * @param beneficiary Address of the beneficiary
   * @param asset Address of the asset
   * @param actionType Type of action for the time-lock
   * @param amount  amount
   * @param timestamp Timestamp when the assets entered timelock
   */
  event AgreementCreated(
    uint256 indexed agreementId,
    address indexed beneficiary,
    address indexed asset,
    TimeLockActionType actionType,
    uint256 amount,
    uint256 timestamp
  );

  /** @notice Event emitted when a time-lock agreement is claimed
   * @param agreementId ID of the claimed agreement
   * @param beneficiary Beneficiary of the claimed agreement
   * @param asset Address of the asset
   * @param actionType Type of action for the time-lock
   * @param amount amount
   * @param beneficiary Address of the beneficiary
   */
  event AgreementClaimed(
    uint256 indexed agreementId,
    address indexed beneficiary,
    address indexed asset,
    TimeLockActionType actionType,
    uint256 amount
  );

  /** @notice Event emitted when a time-lock agreement is frozen or unfrozen
   * @param agreementId ID of the affected agreement
   * @param value Indicates whether the agreement is frozen (true) or unfrozen (false)
   */
  event AgreementFrozen(uint256 agreementId, bool value);

  /** @notice Event emitted when the entire TimeLock contract is frozen or unfrozen
   * @param value Indicates whether the contract is frozen (true) or unfrozen (false)
   */
  event TimeLockFrozen(bool value);

  /**
   * @dev Emitted during rescueAgreement()
   * @param agreementId The rescued agreement Id
   * @param underlyToken The adress of the underlying token
   * @param to The address of the recipient
   * @param underlyAmount The amount being rescued
   **/
  event RescueAgreement(uint256 agreementId, address indexed underlyToken, address indexed to, uint256 underlyAmount);

  enum TimeLockActionType {
    BORROW,
    REDEEM
  }
  struct Agreement {
    bool isFrozen;
    TimeLockActionType actionType;
    address cToken;
    address beneficiary;
    uint48 timestamp;
    uint256 agreementId;
    uint256 underlyAmount;
  }

  function createAgreement(
    TimeLockActionType actionType,
    uint256 underlyAmount,
    address beneficiary
  ) external returns (uint256);

  function consumeValuePreview(uint256 underlyAmount, address cToken) external view returns (bool);
  function consumeValue(uint256 underlyAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/// @title Multicall2 - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract SumerErrors {
  error PriceError();

  error RedemptionSignerNotInitialized();
  error NotEnoughForSeize();
  error NoRedemptionProvider();
  error MarketNotListed();
  error InsufficientShortfall();
  error TooMuchRepay();
  error OneOfRedeemTokensAndRedeemAmountMustBeZero();
  error InvalidMinSuBorrowValue();
  error BorrowValueMustBeLargerThanThreshold(uint256 usdThreshold);
  error ProtocolIsPaused();
  error MarketAlreadyListed();
  error InvalidAddress();
  error InvalidGroupId();
  error InvalidCloseFactor();
  error InvalidSuToken();
  error InvalidSignatureLength();
  error ExpiredSignature();
  error SenderMustBeCToken();
  error MintPaused();
  error BorrowPaused();
  error TransferPaused();
  error SeizePaused();
  error InsufficientCollateral();
  error GroupIdMismatch();
  error OneOfNetAssetAndNetDebtMustBeZero();

  error OnlyAdminOrCapper();
  error OnlyAdminOrPauser();

  // general errors
  error OnlyAdmin();
  error OnlyPendingAdmin();
  error OnlyRedemptionManager();
  error OnlyListedCToken();
  error OnlyCToken();
  error UnderlyingBalanceError();
  error MarketCanOnlyInitializeOnce();
  error CantSweepUnderlying();
  error TokenTransferInFailed();
  error TokenTransferOutFailed();
  error TransferNotAllowed();
  error TokenInOrAmountInMustBeZero();
  error AddReservesOverflow();
  error ReduceReservesOverflow();
  error RedeemTransferOutNotPossible();
  error BorrowCashNotAvailable();
  error ReduceReservesCashNotAvailable();
  error InvalidDiscountRate();
  error InvalidExchangeRate();
  error InvalidReduceAmount();
  error InvalidReserveFactor();
  error InvalidComptroller();
  error InvalidInterestRateModel();
  error InvalidAmount();
  error InvalidInput();
  error BorrowAndDepositBackFailed();
  error InvalidSignatureForRedeemFaceValue();

  error BorrowCapReached();
  error SupplyCapReached();
  error ComptrollerMismatch();

  error MintMarketNotFresh();
  error BorrowMarketNotFresh();
  error RepayBorrowMarketNotFresh();
  error RedeemMarketNotFresh();
  error LiquidateMarketNotFresh();
  error LiquidateCollateralMarketNotFresh();
  error ReduceReservesMarketNotFresh();
  error SetInterestRateModelMarketNotFresh();
  error AddReservesMarketNotFresh();
  error SetReservesFactorMarketNotFresh();
  error CantExitMarketWithNonZeroBorrowBalance();

  // error
  error NotCToken();
  error NotSuToken();

  // error in liquidateBorrow
  error LiquidateBorrow_RepayAmountIsZero();
  error LiquidateBorrow_RepayAmountIsMax();
  error LiquidateBorrow_LiquidatorIsBorrower();
  error LiquidateBorrow_SeizeTooMuch();

  // error in seize
  error Seize_LiquidatorIsBorrower();

  // error in protected mint
  error ProtectedMint_OnlyAllowAssetsInTheSameGroup();

  error RedemptionSeizeTooMuch();

  error MinDelayNotReached();

  error NotLiquidatableYet();
}