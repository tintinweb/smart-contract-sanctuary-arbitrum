// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.22 >=0.8.0 ^0.8.0 ^0.8.20;

// lib/cozy-safety-module-shared/src/interfaces/ICommonErrors.sol

interface ICommonErrors {
  /// @dev Thrown if the current state does not allow the requested action to be performed.
  error InvalidState();

  /// @dev Thrown when a requested state transition is not allowed.
  error InvalidStateTransition();

  /// @dev Thrown if the request action is not allowed because zero units would be transferred, burned, minted, etc.
  error RoundsToZero();

  /// @dev Thrown if the request action is not allowed because the requested amount is zero.
  error AmountIsZero();

  /// @dev Thrown when a drip model returns an invalid drip factor.
  error InvalidDripFactor();
}

// lib/cozy-safety-module-shared/src/interfaces/IDripModel.sol

interface IDripModel {
  /// @notice Returns the drip factor, given the `lastDripTime_` and `initialAmount_`.
  function dripFactor(uint256 lastDripTime_, uint256 initialAmount_) external view returns (uint256 dripFactor_);
}

// lib/cozy-safety-module-shared/src/interfaces/IERC20.sol

/**
 * @dev Interface for ERC20 tokens.
 */
interface IERC20 {
  /// @dev Emitted when the allowance of a `spender_` for an `owner_` is updated, where `amount_` is the new allowance.
  event Approval(address indexed owner_, address indexed spender_, uint256 value_);
  /// @dev Emitted when `amount_` tokens are moved from `from_` to `to_`.
  event Transfer(address indexed from_, address indexed to_, uint256 value_);

  /// @notice Returns the remaining number of tokens that `spender_` will be allowed to spend on behalf of `holder_`.
  function allowance(address owner_, address spender_) external view returns (uint256);

  /// @notice Sets `amount_` as the allowance of `spender_` over the caller's tokens.
  function approve(address spender_, uint256 amount_) external returns (bool);

  /// @notice Returns the amount of tokens owned by `account_`.
  function balanceOf(address account_) external view returns (uint256);

  /// @notice Returns the decimal places of the token.
  function decimals() external view returns (uint8);

  /// @notice Sets `value_` as the allowance of `spender_` over `owner_`s tokens, given a signed approval from the
  /// owner.
  function permit(address owner_, address spender_, uint256 value_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
    external;

  /// @notice Returns the name of the token.
  function name() external view returns (string memory);

  /// @notice Returns the nonce of `owner_`.
  function nonces(address owner_) external view returns (uint256);

  /// @notice Returns the symbol of the token.
  function symbol() external view returns (string memory);

  /// @notice Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);

  /// @notice Moves `amount_` tokens from the caller's account to `to_`.
  function transfer(address to_, uint256 amount_) external returns (bool);

  /// @notice Moves `amount_` tokens from `from_` to `to_` using the allowance mechanism. `amount`_ is then deducted
  /// from the caller's allowance.
  function transferFrom(address from_, address to_, uint256 amount_) external returns (bool);
}

// lib/cozy-safety-module-shared/src/interfaces/IOwnable.sol

interface IOwnable {
  function owner() external view returns (address);
}

// lib/cozy-safety-module-shared/src/lib/MathConstants.sol

library MathConstants {
  uint256 constant ZOC = 1e4;
  uint256 constant ZOC2 = 1e8;
  uint256 constant WAD = 1e18;
  uint256 constant WAD_ZOC2 = 1e26;
}

// lib/cozy-safety-module-shared/src/lib/SafeCastLib.sol

/**
 * @dev Wrappers over Solidity's casting operators that revert if the input overflows the new type when downcasted.
 */
library SafeCastLib {
  /// @dev Thrown when a downcast fails.
  error SafeCastFailed();

  /// @dev Downcast `x` to a `uint216`, reverting if `x > type(uint216).max`.
  function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
    if (x > type(uint216).max) revert SafeCastFailed();
    y = uint216(x);
  }

  /// @dev Downcast `x` to a `uint176`, reverting if `x > type(uint176).max`.
  function safeCastTo176(uint256 x) internal pure returns (uint176 y) {
    if (x > type(uint176).max) revert SafeCastFailed();
    y = uint176(x);
  }

  /// @dev Downcast `x` to a `uint128`, reverting if `x > type(uint128).max`.
  function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
    if (x > type(uint128).max) revert SafeCastFailed();
    y = uint128(x);
  }

  /// @dev Downcast `x` to a `uint96`, reverting if `x > type(uint96).max`.
  function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
    if (x > type(uint96).max) revert SafeCastFailed();
    y = uint96(x);
  }

  /// @dev Downcast `x` to a `uint64`, reverting if `x > type(uint64).max`.
  function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
    if (x > type(uint64).max) revert SafeCastFailed();
    y = uint64(x);
  }

  // @dev Downcast `x` to a `uint40`, reverting if `x > type(uint40).max`.
  function safeCastTo40(uint256 x) internal pure returns (uint40 y) {
    if (x > type(uint40).max) revert SafeCastFailed();
    y = uint40(x);
  }

  // @dev Downcast `x` to a `uint48`, reverting if `x > type(uint48).max`.
  function safeCastTo48(uint256 x) internal pure returns (uint48 y) {
    if (x > type(uint48).max) revert SafeCastFailed();
    y = uint48(x);
  }

  /// @dev Downcast `x` to a `uint32`, reverting if `x > type(uint32).max`.
  function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
    if (x > type(uint32).max) revert SafeCastFailed();
    y = uint32(x);
  }

  /// @dev Downcast `x` to a `uint16`, reverting if `x > type(uint16).max`.
  function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
    if (x > type(uint16).max) revert SafeCastFailed();
    y = uint16(x);
  }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC-20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[ERC-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC-20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// lib/solmate/src/utils/FixedPointMathLib.sol

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function log2(uint256 x) internal pure returns (uint256 r) {
        require(x > 0, "UNDEFINED");

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := div(x, y)
        }
    }

    /// @dev Will return 0 instead of reverting if y is zero.
    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// src/interfaces/IConfiguratorErrors.sol

interface IConfiguratorErrors {
  /// @dev Thrown when an update's configuration does not meet all requirements.
  error InvalidConfiguration();
}

// src/interfaces/IDepositorErrors.sol

interface IDepositorErrors {
  /// @dev Thrown when attempting an invalid deposit.
  error InvalidDeposit();
}

// src/interfaces/IRedemptionErrors.sol

interface IRedemptionErrors {
  /// @dev Thrown when attempting to complete an redemption that doesn't exist.
  error RedemptionNotFound();

  /// @dev Thrown when redemption delay has not elapsed.
  error DelayNotElapsed();

  /// @dev Thrown when attempting to queue a redemption when there are not assets available in the reserve pool.
  error NoAssetsToRedeem();
}

// src/interfaces/ISlashHandlerErrors.sol

interface ISlashHandlerErrors {
  /// @dev Thrown when the slash percentage exceeds the max slash percentage allowed for the reserve pool.
  error ExceedsMaxSlashPercentage(uint8 reservePoolId_, uint256 slashPercentage_);

  /// @dev Thrown when the reserve pool has already been slashed.
  error AlreadySlashed(uint8 reservePoolId_);
}

// src/interfaces/ISlashHandlerEvents.sol

interface ISlashHandlerEvents {
  /// @dev Emitted when a reserve pool is slashed.
  event Slashed(
    address indexed payoutHandler_, address indexed receiver_, uint8 indexed reservePoolId_, uint256 assetAmount_
  );
}

// src/interfaces/IStateChangerErrors.sol

interface IStateChangerErrors {
  /// @dev Thrown when the trigger is not allowed to trigger the SafetyModule.
  error InvalidTrigger();
}

// src/lib/CozyMath.sol

/**
 * @dev Helper methods for common math operations.
 */
library CozyMath {
  /// @dev Performs `x * y` without overflow checks. Only use this when you are sure `x * y` will not overflow.
  function unsafemul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assembly {
      z := mul(x, y)
    }
  }

  /// @dev Performs `x / y` without divide by zero checks. Only use this when you are sure `y` is not zero.
  function unsafediv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    // Only use this when you are sure y is not zero.
    assembly {
      z := div(x, y)
    }
  }

  /// @dev Returns `x - y` if the result is positive, or zero if `x - y` would overflow and result in a negative value.
  function differenceOrZero(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      z = x >= y ? x - y : 0;
    }
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x > y ? y : x;
  }
}

// src/lib/SafetyModuleStates.sol

enum SafetyModuleState {
  ACTIVE,
  TRIGGERED,
  PAUSED
}

enum TriggerState {
  ACTIVE,
  TRIGGERED,
  FROZEN
}

// src/lib/structs/Delays.sol

/// @notice Delays for the SafetyModule.
struct Delays {
  // Duration between when SafetyModule updates are queued and when they can be executed.
  uint64 configUpdateDelay;
  // Defines how long the owner has to execute a configuration change, once it can be executed.
  uint64 configUpdateGracePeriod;
  // Delay for two-step withdraw process (for deposited reserve assets).
  uint64 withdrawDelay;
}

// src/lib/structs/Slash.sol

struct Slash {
  // ID of the reserve pool.
  uint8 reservePoolId;
  // Asset amount that will be slashed from the reserve pool.
  uint256 amount;
}

// lib/cozy-safety-module-shared/src/interfaces/IGovernable.sol

interface IGovernable is IOwnable {
  function pauser() external view returns (address);
}

// lib/cozy-safety-module-shared/src/interfaces/IReceiptToken.sol

interface IReceiptToken is IERC20 {
  /// @notice Burns `amount_` of tokens from `from`_.
  function burn(address caller_, address from_, uint256 amount_) external;

  /// @notice Replaces the constructor for minimal proxies.
  /// @param module_ The safety/rewards module for this ReceiptToken.
  /// @param name_ The name of the token.
  /// @param symbol_ The symbol of the token.
  /// @param decimals_ The decimal places of the token.
  function initialize(address module_, string memory name_, string memory symbol_, uint8 decimals_) external;

  /// @notice Mints `amount_` of tokens to `to_`.
  function mint(address to_, uint256 amount_) external;

  /// @notice Address of this token's safety/rewards module.
  function module() external view returns (address);
}

// lib/cozy-safety-module-shared/src/lib/Ownable.sol

/**
 * @dev Contract module providing owner functionality, intended to be used through inheritance.
 */
abstract contract Ownable is IOwnable {
  /// @notice Contract owner.
  address public owner;

  /// @notice The pending new owner.
  address public pendingOwner;

  /// @dev Emitted when the owner address is updated.
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @dev Emitted when the first step of the two step ownership transfer is executed.
  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

  /// @dev Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @dev Thrown when an invalid address is passed as a parameter.
  error InvalidAddress();

  /// @dev Initializer, replaces constructor for minimal proxies. Must be kept internal and it's up
  /// to the caller to make sure this can only be called once.
  /// @param owner_ The contract owner.
  function __initOwnable(address owner_) internal {
    emit OwnershipTransferred(owner, owner_);
    owner = owner_;
  }

  /// @notice Callable by the pending owner to transfer ownership to them.
  /// @dev Updates the owner in storage to newOwner_ and resets the pending owner.
  function acceptOwnership() external {
    if (msg.sender != pendingOwner) revert Unauthorized();
    delete pendingOwner;
    address oldOwner_ = owner;
    owner = msg.sender;
    emit OwnershipTransferred(oldOwner_, msg.sender);
  }

  /// @notice Starts the ownership transfer of the contract to a new account.
  /// Replaces the pending transfer if there is one.
  /// @param newOwner_ The new owner of the contract.
  function transferOwnership(address newOwner_) external onlyOwner {
    _assertAddressNotZero(newOwner_);
    pendingOwner = newOwner_;
    emit OwnershipTransferStarted(owner, newOwner_);
  }

  /// @dev Revert if the address is the zero address.
  function _assertAddressNotZero(address address_) internal pure {
    if (address_ == address(0)) revert InvalidAddress();
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
  }
}

// src/interfaces/ITrigger.sol

/**
 * @dev The minimal functions a trigger must implement to work with SafetyModules.
 */
interface ITrigger {
  /// @notice The current trigger state.
  function state() external returns (TriggerState);
}

// src/lib/SafetyModuleCalculationsLib.sol

/**
 * @notice Read-only safety module calculations.
 */
library SafetyModuleCalculationsLib {
  using FixedPointMathLib for uint256;

  uint256 internal constant POOL_AMOUNT_FLOOR = 1;

  /// @notice The `receiptTokenAmount_` that the safety module would exchange for `assetAmount_` of receipt token
  /// provided.
  /// @dev See the ERC-4626 spec for more info.
  /// @param assetAmount_ The amount of assets to convert to receipt tokens.
  /// @param receiptTokenSupply_ The total supply of the receipt token.
  /// @param poolAmount_ The pool amount for the purposes of performing conversions.
  function convertToReceiptTokenAmount(uint256 assetAmount_, uint256 receiptTokenSupply_, uint256 poolAmount_)
    internal
    pure
    returns (uint256 receiptTokenAmount_)
  {
    receiptTokenAmount_ = receiptTokenSupply_ == 0
      ? assetAmount_
      : assetAmount_.mulDivDown(receiptTokenSupply_, _poolAmountWithFloor(poolAmount_));
  }

  /// @notice The `assetAmount_` that the safety module would exchange for `receiptTokenAmount_` of the receipt
  /// token provided.
  /// @dev Note that we do not floor the pool amount here, as the pool amount never shows up in the denominator.
  /// @dev See the ERC-4626 spec for more info.
  /// @param receiptTokenAmount_ The amount of receipt tokens to convert to assets.
  /// @param receiptTokenSupply_ The total supply of the receipt token.
  /// @param poolAmount_ The pool amount for the purposes of performing conversions.
  function convertToAssetAmount(uint256 receiptTokenAmount_, uint256 receiptTokenSupply_, uint256 poolAmount_)
    internal
    pure
    returns (uint256 assetAmount_)
  {
    assetAmount_ = receiptTokenSupply_ == 0 ? 0 : receiptTokenAmount_.mulDivDown(poolAmount_, receiptTokenSupply_);
  }

  /// @notice The pool amount for the purposes of performing conversions. We set a floor once
  /// DepositReceiptTokens have been initialized to avoid divide-by-zero errors that would occur when the supply
  /// of DepositReceiptTokens > 0, but the `poolAmount` = 0.
  function _poolAmountWithFloor(uint256 poolAmount_) private pure returns (uint256) {
    return poolAmount_ > POOL_AMOUNT_FLOOR ? poolAmount_ : POOL_AMOUNT_FLOOR;
  }
}

// src/lib/StateTransitionsLib.sol

/// @dev Enum representing what the caller of a function is.
/// NONE indicates that the caller has no authorization privileges.
/// OWNER indicates that the caller is the owner of the SafetyModule.
/// PAUSER indicates that the caller is the pauser of the SafetyModule.
/// MANAGER indicates that the caller is the manager of the SafetyModule.
enum CallerRole {
  NONE,
  OWNER,
  PAUSER,
  MANAGER
}

library StateTransitionsLib {
  /// @notice Returns true if the state transition from `from_` to `to_` is valid when called
  /// by `role_`, false otherwise.
  /// @param role_ The CallerRole for the state transition.
  /// @param to_ The SafetyModuleState that is being transitioned to.
  /// @param from_ The SafetyModuleState that is being transitioned from.
  /// @param nonZeroPendingSlashes_ True if the number of pending slashes >= 1.
  function isValidStateTransition(
    CallerRole role_,
    SafetyModuleState to_,
    SafetyModuleState from_,
    bool nonZeroPendingSlashes_
  ) public pure returns (bool) {
    // STATE TRANSITION RULES FOR SAFETY MODULES.
    // To read the below table:
    //   - Rows headers are the "from" state,
    //   - Column headers are the "to" state.
    //   - Cells describe whether that transition is allowed.
    //   - Numbers in parentheses indicate conditional transitions with details described in footnotes.
    //   - Letters in parentheses indicate who can perform the transition with details described in footnotes.
    //
    // | From / To | ACTIVE      | TRIGGERED   | PAUSED   |
    // | --------- | ----------- | ----------- | -------- |
    // | ACTIVE    | -           | true (1)    | true (P) |
    // | TRIGGERED | true (0)    | -           | true (P) |
    // | PAUSED    | true (0, A) | true (1, A) | -        |
    //
    // (0) Only allowed if number of pending slashes == 0.
    // (1) Only allowed if number of pending slashes >= 1.
    // (A) Only allowed if msg.sender is the owner or the manager.
    // (P) Only allowed if msg.sender is the owner, pauser, or manager.

    // The TRIGGERED-ACTIVE cell logic is checked in SlashHandler.slash and does not need to be checked here.
    // The ACTIVE-TRIGGERED cell logic is checked in StateChanger.trigger and does not need to be checked here.
    if (to_ == from_) return false;
    if (role_ == CallerRole.NONE) return false;

    return
    // The PAUSED column.
    (
      to_ == SafetyModuleState.PAUSED
        && (role_ == CallerRole.OWNER || role_ == CallerRole.PAUSER || role_ == CallerRole.MANAGER)
    )
    // The PAUSED-ACTIVE cell.
    || (
      from_ == SafetyModuleState.PAUSED && to_ == SafetyModuleState.ACTIVE && !nonZeroPendingSlashes_
        && (role_ == CallerRole.OWNER || role_ == CallerRole.MANAGER)
    )
    // The PAUSED-TRIGGERED cell.
    || (
      from_ == SafetyModuleState.PAUSED && to_ == SafetyModuleState.TRIGGERED && nonZeroPendingSlashes_
        && (role_ == CallerRole.OWNER || role_ == CallerRole.MANAGER)
    );
  }
}

// lib/cozy-safety-module-shared/src/interfaces/IReceiptTokenFactory.sol

interface IReceiptTokenFactory {
  enum PoolType {
    RESERVE,
    STAKE,
    REWARD
  }

  /// @dev Emitted when a new ReceiptToken is deployed.
  event ReceiptTokenDeployed(
    IReceiptToken receiptToken,
    address indexed module,
    uint16 indexed poolId,
    PoolType indexed poolType,
    uint8 decimals_
  );

  /// @notice Given a `module_`, its `poolId_`, and `poolType_`, compute and return the address of its
  /// ReceiptToken.
  function computeAddress(address module_, uint16 poolId_, PoolType poolType_) external view returns (address);

  /// @notice Creates a new ReceiptToken contract with the given number of `decimals_`. The ReceiptToken's
  /// safety / rewards module is identified by the caller address. The pool id of the ReceiptToken in the module and
  /// its `PoolType` is used to generate a unique salt for deploy.
  function deployReceiptToken(uint16 poolId_, PoolType poolType_, uint8 decimals_)
    external
    returns (IReceiptToken receiptToken_);
}

// src/interfaces/IStateChangerEvents.sol

interface IStateChangerEvents {
  /// @dev Emitted when the SafetyModule changes state.
  event SafetyModuleStateUpdated(SafetyModuleState indexed updatedTo_);

  /// @dev Emitted when the SafetyModule is triggered.
  event Triggered(ITrigger indexed trigger);
}

// src/lib/structs/Pools.sol

struct AssetPool {
  // The total balance of assets held by a SafetyModule, should be equivalent to
  // token.balanceOf(address(this)), discounting any assets directly sent
  // to the SafetyModule via direct transfer.
  uint256 amount;
}

struct ReservePool {
  // The internally accounted total amount of assets held by the reserve pool. This amount includes
  // pendingWithdrawalsAmount.
  uint256 depositAmount;
  // The amount of assets that are currently queued for withdrawal from the reserve pool.
  uint256 pendingWithdrawalsAmount;
  // The amount of fees that have accumulated in the reserve pool since the last fee claim.
  uint256 feeAmount;
  // The max percentage of the reserve pool deposit amount that can be slashed in a SINGLE slash as a ZOC.
  // If multiple slashes occur, they compound, and the final deposit amount can be less than (1 - maxSlashPercentage)%
  // following all the slashes.
  uint256 maxSlashPercentage;
  // The underlying asset of the reserve pool.
  IERC20 asset;
  // The receipt token that represents reserve pool deposits.
  IReceiptToken depositReceiptToken;
  // The timestamp of the last time fees were dripped to the reserve pool.
  uint128 lastFeesDripTime;
}

// src/lib/structs/Redemptions.sol

struct Redemption {
  uint8 reservePoolId; // ID of the reserve pool.
  uint216 receiptTokenAmount; // Deposit receipt token amount burned to queue the redemption.
  IReceiptToken receiptToken; // The receipt token being redeemed.
  uint128 assetAmount; // Asset amount that will be paid out upon completion of the redemption.
  address owner; // Owner of the deposit tokens.
  address receiver; // Receiver of reserve assets.
  uint40 queueTime; // Timestamp at which the redemption was requested.
  uint40 delay; // SafetyModule redemption delay at the time of request.
  uint32 queuedAccISFsLength; // Length of pendingRedemptionAccISFs at queue time.
  uint256 queuedAccISF; // Last pendingRedemptionAccISFs value at queue time.
}

struct RedemptionPreview {
  uint40 delayRemaining; // SafetyModule redemption delay remaining.
  uint216 receiptTokenAmount; // Deposit receipt token amount burned to queue the redemption.
  IReceiptToken receiptToken; // The receipt token being redeemed.
  uint128 reserveAssetAmount; // Asset amount that will be paid out upon completion of the redemption.
  address owner; // Owner of the deposit receipt tokens.
  address receiver; // Receiver of the assets.
}

// src/lib/structs/Trigger.sol

struct Trigger {
  // Whether the trigger exists.
  bool exists;
  // The payout handler that is authorized to slash assets when the trigger is triggered.
  address payoutHandler;
  // Whether the trigger has triggered the SafetyModule. A trigger cannot trigger the SafetyModule more than once.
  bool triggered;
}

struct TriggerConfig {
  // The trigger that is being configured.
  ITrigger trigger;
  // The address that is authorized to slash assets when the trigger is triggered.
  address payoutHandler;
  // Whether the trigger is used by the SafetyModule.
  bool exists;
}

struct TriggerMetadata {
  // The name that should be used for SafetyModules that use the trigger.
  string name;
  // A human-readable description of the trigger.
  string description;
  // The URI of a logo image to represent the trigger.
  string logoURI;
  // Any extra data that should be included in the trigger's metadata.
  string extraData;
}

// lib/cozy-safety-module-shared/src/lib/Governable.sol

/**
 * @dev Contract module providing owner and pauser functionality, intended to be used through inheritance.
 * @dev No modifiers are provided to avoid the chance of dead code, as the child contract may
 * have more complex authentication requirements than just a modifier from this contract.
 */
abstract contract Governable is Ownable, IGovernable {
  /// @notice Contract pauser.
  address public pauser;

  /// @dev Emitted when the pauser address is updated.
  event PauserUpdated(address indexed newPauser_);

  /// @dev Initializer, replaces constructor for minimal proxies. Must be kept internal and it's up
  /// to the caller to make sure this can only be called once.
  /// @param owner_ The contract owner.
  /// @param pauser_ The contract pauser.
  function __initGovernable(address owner_, address pauser_) internal {
    __initOwnable(owner_);
    pauser = pauser_;
    emit PauserUpdated(pauser_);
  }

  /// @notice Update pauser to `_newPauser`.
  /// @param _newPauser The new pauser.
  function _updatePauser(address _newPauser) internal {
    if (msg.sender != owner && msg.sender != pauser) revert Unauthorized();
    emit PauserUpdated(_newPauser);
    pauser = _newPauser;
  }
}

// lib/cozy-safety-module-shared/src/lib/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 * @dev This is a forked version which uses our IERC20 interfaces instead of the OpenZeppelin's ERC20. The formatting
 * is kept consistent with the original so its easier to compare.
 */
library SafeERC20 {
  using Address for address;

  /**
   * @dev An operation with an ERC20 token failed.
   */
  error SafeERC20FailedOperation(address token);

  /**
   * @dev Indicates a failed `decreaseAllowance` request.
   */
  error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

  /**
   * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
   * non-reverting calls are assumed to be successful.
   */
  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
  }

  /**
   * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
   * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
   */
  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
  }

  /**
   * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful.
   */
  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 oldAllowance = token.allowance(address(this), spender);
    forceApprove(token, spender, oldAllowance + value);
  }

  /**
   * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
   * value, non-reverting calls are assumed to be successful.
   */
  function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
    unchecked {
      uint256 currentAllowance = token.allowance(address(this), spender);
      if (currentAllowance < requestedDecrease) {
        revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
      }
      forceApprove(token, spender, currentAllowance - requestedDecrease);
    }
  }

  /**
   * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
   * to be set to zero before setting it to a non-zero value, such as USDT.
   */
  function forceApprove(IERC20 token, address spender, uint256 value) internal {
    bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

    if (!_callOptionalReturnBool(token, approvalCall)) {
      _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
      _callOptionalReturn(token, approvalCall);
    }
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

    bytes memory returndata = address(token).functionCall(data);
    if (returndata.length != 0 && !abi.decode(returndata, (bool))) revert SafeERC20FailedOperation(address(token));
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
    return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
  }
}

// src/lib/structs/Configs.sol

/// @notice Configuration for a reserve pool.
struct ReservePoolConfig {
  // The maximum percentage of the reserve pool assets that can be slashed in a single transaction, represented as a
  // ZOC. If multiple slashes occur, they compound, and the final reserve pool amount can be less than
  // (1 - maxSlashPercentage)% following all the slashes.
  uint256 maxSlashPercentage;
  // The underlying asset of the reserve pool.
  IERC20 asset;
}

/// @notice Metadata for a configuration update.
struct ConfigUpdateMetadata {
  // A hash representing queued `ReservePoolConfig[]`, TriggerConfig[], and `Delays` updates. This hash is
  // used to prove that the params used when applying config updates are identical to the queued updates.
  // This strategy is used instead of storing non-hashed `ReservePoolConfig[]`, `TriggerConfig[] and
  // `Delays` for gas optimization and to avoid dynamic array manipulation. This hash is set to bytes32(0) when there is
  // no config update queued.
  bytes32 queuedConfigUpdateHash;
  // Earliest timestamp at which finalizeUpdateConfigs can be called to apply config updates queued by updateConfigs.
  uint64 configUpdateTime;
  // The latest timestamp after configUpdateTime at which finalizeUpdateConfigs can be called to apply config
  // updates queued by updateConfigs. After this timestamp, the queued config updates expire and can no longer be
  // applied.
  uint64 configUpdateDeadline;
}

/// @notice Parameters for configuration updates.
struct UpdateConfigsCalldataParams {
  // The new reserve pool configs.
  ReservePoolConfig[] reservePoolConfigs;
  // The new trigger configs.
  TriggerConfig[] triggerConfigUpdates;
  // The new delays config.
  Delays delaysConfig;
}

// src/interfaces/IConfiguratorEvents.sol

interface IConfiguratorEvents {
  /// @dev Emitted when a SafetyModule owner queues a new configuration.
  event ConfigUpdatesQueued(
    ReservePoolConfig[] reservePoolConfigs,
    TriggerConfig[] triggerConfigUpdates,
    Delays delaysConfig,
    uint256 updateTime,
    uint256 updateDeadline
  );

  /// @dev Emitted when a SafetyModule's queued configuration updates are applied.
  event ConfigUpdatesFinalized(
    ReservePoolConfig[] reservePoolConfigs, TriggerConfig[] triggerConfigUpdates, Delays delaysConfig
  );

  /// @notice Emitted when a reserve pool is created.
  event ReservePoolCreated(uint16 indexed reservePoolId, IERC20 reserveAsset, IReceiptToken depositReceiptToken);
}

// src/lib/RedemptionLib.sol

/**
 * @notice Read-only logic for redemptions.
 */
library RedemptionLib {
  using CozyMath for uint256;
  using FixedPointMathLib for uint256;
  using SafeCastLib for uint256;

  // Accumulator values are 1/x in WAD, where x is a scaling factor. This is the smallest
  // accumulator value (inverse scaling factor) that is not 1/0 (infinity). Any value greater than this
  // will scale any assets to zero.
  // 1e18/1e-18 => 1e18 * 1e18 / 1 => WAD ** 2 (1e36)
  // SUB_INF_INV_SCALING_FACTOR = 1_000_000_000_000_000_000_000_000_000_000_000_000;
  // Adding 1 to SUB_INF_INV_SCALING_FACTOR will turn to zero when inverted,
  // so this value is effectively an inverted zero scaling factor (infinity).
  uint256 internal constant INF_INV_SCALING_FACTOR = 1_000_000_000_000_000_000_000_000_000_000_000_001;
  // This is the maximum value an accumulator value can hold. Any more and it could overflow
  // during calculations. This value should not overflow a uint256 when multiplied by 1 WAD.
  // Equiv to uint256.max / WAD
  // MAX_SAFE_ACCUM_INV_SCALING_FACTOR_VALUE =
  //   115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457;
  // When a new accumulator value exceeds this threshold, a new entry should be used.
  // When this value is multiplied by INF_INV_SCALING_FACTOR, it should be <= MAX_SAFE_ACCUM_INV_SCALING_FACTOR_VALUE
  // Equiv to MAX_SAFE_ACCUM_INV_SCALING_FACTOR_VALUE / ((INF_INV_SCALING_FACTOR + WAD-1) / WAD)
  uint256 internal constant NEW_ACCUM_INV_SCALING_FACTOR_THRESHOLD =
    115_792_089_237_316_195_307_778_895_771_371_712_545_491;
  // The maximum value an accumulator should ever actually hold, if everything is working correctly.
  // Equiv to: NEW_ACCUM_INV_SCALING_FACTOR_THRESHOLD.mulWadUp(INF_INV_SCALING_FACTOR);
  // Should be <= MAX_SAFE_ACCUM_INV_SCALING_FACTOR_VALUE
  // Equiv to (NEW_ACCUM_INV_SCALING_FACTOR_THRESHOLD * INF_INV_SCALING_FACTOR + WAD-1) / WAD
  uint256 internal constant MAX_ACCUM_INV_SCALING_FACTOR_VALUE =
    115_792_089_237_316_195_307_778_895_771_371_712_661_283_089_237_316_195_307_779;

  // @dev Compute the tokens settled by a pending redemption, which will be scaled (down) by the accumulated
  // scaling factors of triggers that happened after it was queued.
  function computeFinalReserveAssetsRedeemed(
    uint256[] storage accISFs_,
    uint128 queuedReserveAssetAmount_,
    uint256 queuedAccISF_,
    uint32 queuedAccISFsLength_
  ) internal view returns (uint128 reserveAssetAmountRedeemed_) {
    // If a trigger occurs after the redemption was queued, the tokens returned will need to be scaled down
    // by a factor equivalent to how much was taken out relative to the usable reserve assets
    // (which includes pending redemptions):
    //    factor = 1 - slashedAmount / reservePool.amount
    // The values of `accISFs_` are the product of the inverse of this scaling factor
    // after each trigger, with the last one being the most recent. We cache the latest scaling factor at queue time
    // and can divide the current scaling factor by the cached value to isolate the scaling that needs to
    // be applied to the queued assets to redeem.
    uint256 invScalingFactor_ = MathConstants.WAD;
    if (queuedAccISFsLength_ != 0) {
      // Get the current scaling factor at the index of the last scaling factor we queued at.
      uint256 currentScalingFactorAtQueueIndex_ = accISFs_[queuedAccISFsLength_ - 1];
      // Divide/factor out the scaling factor we queued at. If this value hasn't changed then scaling
      // will come out to 1.0.
      // Note that we round UP here because these are inverse scaling factors (larger -> less assets).
      invScalingFactor_ = currentScalingFactorAtQueueIndex_.divWadUp(queuedAccISF_);
    }
    // The queuedAccISF_ and queuedAccISFsLength_ are the last value of accISFs_ and the length of
    // that array when the redemption was queued. If the array has had more entries added to it since
    // then, we need to scale our factor with each of those as well, to account for the effects of
    // ALL triggers since we queued.
    uint256 ScalingFactorsLength_ = accISFs_.length;
    // Note that the maximum length accISFs_ can be is the number of markets in the set, and probably only
    // if every market triggered a 100% collateral loss, since anything less would likely be compressed into
    // the previous accumulator entry. Even then, we break early if we accumulate >= a factor that
    // scales assets to 0 so, in practice, this loop will only iterate once or twice.
    for (uint256 i = queuedAccISFsLength_; i < ScalingFactorsLength_; i++) {
      // If the scaling factor is large enough, the resulting assets will come out to essentially zero
      // anyway, so we can stop early.
      if (invScalingFactor_ >= INF_INV_SCALING_FACTOR) break;
      // Note that we round UP here because these are inverse scaling factors (larger -> less assets).
      invScalingFactor_ = invScalingFactor_.mulWadUp(accISFs_[i]);
    }
    // This accumulated value is actually the inverse of the true scaling factor, so we need to invert it first.
    // We need to do this step separately from the next to minimize rounding errors.
    uint256 scalingFactor_ =
      invScalingFactor_ >= INF_INV_SCALING_FACTOR ? 0 : MathConstants.WAD.divWadDown(invScalingFactor_);
    // Now we can just scale the queued tokens by this scaling factor to get the final tokens redeemed.
    reserveAssetAmountRedeemed_ = scalingFactor_.mulWadDown(queuedReserveAssetAmount_).safeCastTo128();
  }

  /// @dev Prepares pending redemptions to have their exchange rates adjusted after a trigger.
  function updateRedemptionsAfterTrigger(
    uint256 pendingRedemptionsAmount_,
    uint256 redemptionAmount_,
    uint256 slashAmount_,
    uint256[] storage pendingAccISFs_
  ) internal returns (uint256) {
    uint256 numScalingFactors_ = pendingAccISFs_.length;
    uint256 currAccISF_ = numScalingFactors_ == 0 ? MathConstants.WAD : pendingAccISFs_[numScalingFactors_ - 1];
    (uint256 newAssetsPendingRedemption_, uint256 accISF_) = computeNewPendingRedemptionsAccumulatedScalingFactor(
      currAccISF_, pendingRedemptionsAmount_, redemptionAmount_, slashAmount_
    );
    if (numScalingFactors_ == 0) {
      // First trigger for this safety module. Create an accumulator entry.
      pendingAccISFs_.push(accISF_);
    } else {
      // Update the last accumulator entry.
      pendingAccISFs_[numScalingFactors_ - 1] = accISF_;
    }
    if (accISF_ > NEW_ACCUM_INV_SCALING_FACTOR_THRESHOLD) {
      // The new entry is very large and cannot be safely combined with the next trigger, so append
      // a new 1.0 entry for next time.
      pendingAccISFs_.push(MathConstants.WAD);
    }
    return newAssetsPendingRedemption_;
  }

  // @dev Compute the scaled tokens pending redemptions and accumulated inverse scaling factor
  // as a result of a trigger.
  function computeNewPendingRedemptionsAccumulatedScalingFactor(
    uint256 currAccISF_,
    uint256 oldAssetsPendingRedemption_,
    uint256 oldPoolAmount_,
    uint256 slashAmount_
  ) internal pure returns (uint256 newAssetsPendingRedemption_, uint256 newAccISF_) {
    // The incoming accumulator should be less than the threshold to use a new one.
    assert(currAccISF_ <= NEW_ACCUM_INV_SCALING_FACTOR_THRESHOLD);
    // The incoming accumulator should be >= 1.0 because it starts at 1.0 and
    // should only ever increase (or stay the same). This is because scalingFactor will always <= 1.0 and
    // we accumulate *= 1/scalingFactor.
    assert(currAccISF_ >= MathConstants.WAD);
    uint256 scalingFactor_ = computeNextPendingRedemptionsScalingFactorForTrigger(oldPoolAmount_, slashAmount_);
    // Computed scaling factor as a result of this trigger should be <= 1.0.
    assert(scalingFactor_ <= MathConstants.WAD);
    newAssetsPendingRedemption_ = oldAssetsPendingRedemption_.mulWadDown(scalingFactor_);
    // The accumulator is actually the products of the inverse of each scaling factor.
    uint256 invScalingFactor_ =
      scalingFactor_ == 0 ? INF_INV_SCALING_FACTOR : MathConstants.WAD.divWadUp(scalingFactor_);
    newAccISF_ = invScalingFactor_.mulWadUp(currAccISF_);
    assert(newAccISF_ <= MAX_ACCUM_INV_SCALING_FACTOR_VALUE);
  }

  function computeNextPendingRedemptionsScalingFactorForTrigger(uint256 oldPoolAmount_, uint256 slashAmount_)
    internal
    pure
    returns (uint256 scalingFactor_)
  {
    // Because the slash amount will be removed from the redemption amount, the value of all
    // redeemed tokens will be scaled (down) by:
    //      scalingFactor = 1 - slashAmount_ / oldPoolAmount_
    if (slashAmount_ > oldPoolAmount_) return 0;
    if (oldPoolAmount_ == 0) return 0;
    return MathConstants.WAD - slashAmount_.divWadUp(oldPoolAmount_);
  }

  /// @dev Gets the amount of time remaining that must elapse before a queued redemption can be completed.
  function getRedemptionDelayTimeRemaining(
    SafetyModuleState safetyModuleState_,
    uint256 redemptionQueueTime_,
    uint256 redemptionDelay_,
    uint256 now_
  ) internal pure returns (uint256) {
    // Redemptions can occur immediately when the safety module is paused.
    return safetyModuleState_ == SafetyModuleState.PAUSED
      ? 0
      : redemptionDelay_.differenceOrZero(now_ - redemptionQueueTime_);
  }
}

// src/interfaces/ICozySafetyModuleManagerEvents.sol

/**
 * @dev Data types and events for the Manager.
 */
interface ICozySafetyModuleManagerEvents {
  /// @dev Emitted when accrued Cozy fees are swept from a SafetyModule to the Cozy Safety Module protocol owner.
  event ClaimedSafetyModuleFees(ISafetyModule indexed safetyModule_);

  /// @dev Emitted when the default fee drip model is updated by the Cozy Safety Module protocol owner.
  event FeeDripModelUpdated(IDripModel indexed feeDripModel_);

  /// @dev Emitted when an override fee drip model is updated by the Cozy Safety Module protocol owner.
  event OverrideFeeDripModelUpdated(ISafetyModule indexed safetyModule_, IDripModel indexed feeDripModel_);
}

// src/interfaces/ICozySafetyModuleManager.sol

interface ICozySafetyModuleManager is IOwnable, ICozySafetyModuleManagerEvents {
  /// @notice Deploys a new SafetyModule with the provided parameters.
  /// @param owner_ The owner of the SafetyModule.
  /// @param pauser_ The pauser of the SafetyModule.
  /// @param configs_ The configuration for the SafetyModule.
  /// @param salt_ Used to compute the resulting address of the SafetyModule.
  function createSafetyModule(
    address owner_,
    address pauser_,
    UpdateConfigsCalldataParams calldata configs_,
    bytes32 salt_
  ) external returns (ISafetyModule safetyModule_);

  /// @notice For the specified SafetyModule, returns whether it's a valid Cozy Safety Module.
  function isSafetyModule(ISafetyModule safetyModule_) external view returns (bool);

  /// @notice For the specified SafetyModule, returns the drip model used for fee accrual.
  function getFeeDripModel(ISafetyModule safetyModule_) external view returns (IDripModel);

  /// @notice Number of reserve pools allowed per SafetyModule.
  function allowedReservePools() external view returns (uint8);
}

// src/interfaces/ISafetyModule.sol

interface ISafetyModule {
  /// @notice The asset pools configured for this SafetyModule.
  /// @dev Used for doing aggregate accounting of reserve assets.
  function assetPools(IERC20 asset_) external view returns (AssetPool memory assetPool_);

  /// @notice Claims any accrued fees to the CozySafetyModuleManager owner.
  /// @dev Validation is handled in the CozySafetyModuleManager, which is the only account authorized to call this
  /// method.
  /// @param owner_ The address to transfer the fees to.
  /// @param dripModel_ The drip model to use for calculating fee drip.
  function claimFees(address owner_, IDripModel dripModel_) external;

  /// @notice Completes the redemption request for the specified redemption ID.
  /// @param redemptionId_ The ID of the redemption to complete.
  function completeRedemption(uint64 redemptionId_) external returns (uint256 assetAmount_);

  /// @notice Returns the receipt token amount for a given amount of reserve assets after taking into account
  /// any pending fee drip.
  /// @param reservePoolId_ The ID of the reserve pool to convert the reserve asset amount for.
  /// @param reserveAssetAmount_ The amount of reserve assets to convert to deposit receipt tokens.
  function convertToReceiptTokenAmount(uint8 reservePoolId_, uint256 reserveAssetAmount_)
    external
    view
    returns (uint256 depositReceiptTokenAmount_);

  /// @notice Returns the reserve asset amount for a given amount of deposit receipt tokens after taking into account
  /// any
  /// pending fee drip.
  /// @param reservePoolId_ The ID of the reserve pool to convert the deposit receipt token amount for.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to convert to reserve assets.
  function convertToReserveAssetAmount(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 reserveAssetAmount_);

  /// @notice Address of the Cozy Safety Module protocol manager contract.
  function cozySafetyModuleManager() external view returns (ICozySafetyModuleManager);

  /// @notice Config, withdrawal and unstake delays.
  function delays() external view returns (Delays memory delays_);

  /// @notice Deposits reserve assets into the SafetyModule and mints deposit receipt tokens.
  /// @dev Expects `msg.sender` to have approved this SafetyModule for `reserveAssetAmount_` of
  /// `reservePools[reservePoolId_].asset` so it can `transferFrom` the assets to this SafetyModule.
  /// @param reservePoolId_ The ID of the reserve pool to deposit assets into.
  /// @param reserveAssetAmount_ The amount of reserve assets to deposit.
  /// @param receiver_ The address to receive the deposit receipt tokens.
  function depositReserveAssets(uint8 reservePoolId_, uint256 reserveAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);

  /// @notice Deposits reserve assets into the SafetyModule and mints deposit receipt tokens.
  /// @dev Expects depositer to transfer assets to the SafetyModule beforehand.
  /// @param reservePoolId_ The ID of the reserve pool to deposit assets into.
  /// @param reserveAssetAmount_ The amount of reserve assets to deposit.
  /// @param receiver_ The address to receive the deposit receipt tokens.
  function depositReserveAssetsWithoutTransfer(uint8 reservePoolId_, uint256 reserveAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);

  /// @notice Updates the fee amounts for each reserve pool by applying a drip factor on the deposit amounts.
  function dripFees() external;

  /// @notice Drips fees from a specific reserve pool.
  /// @param reservePoolId_ The ID of the reserve pool to drip fees from.
  function dripFeesFromReservePool(uint8 reservePoolId_) external;

  /// @notice Execute queued updates to the safety module configs.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  function finalizeUpdateConfigs(UpdateConfigsCalldataParams calldata configUpdates_) external;

  /// @notice Returns the maximum amount of assets that can be slashed from the specified reserve pool.
  /// @param reservePoolId_ The ID of the reserve pool to get the maximum slashable amount for.
  function getMaxSlashableReservePoolAmount(uint8 reservePoolId_)
    external
    view
    returns (uint256 slashableReservePoolAmount_);

  /// @notice Initializes the SafetyModule with the specified parameters.
  /// @dev Replaces the constructor for minimal proxies.
  /// @param owner_ The SafetyModule owner.
  /// @param pauser_ The SafetyModule pauser.
  /// @param configs_ The SafetyModule configuration parameters. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  function initialize(address owner_, address pauser_, UpdateConfigsCalldataParams calldata configs_) external;

  /// @notice Metadata about the most recently queued configuration update.
  function lastConfigUpdate() external view returns (ConfigUpdateMetadata memory);

  /// @notice The number of slashes that must occur before the SafetyModule can be active.
  /// @dev This value is incremented when a trigger occurs, and decremented when a slash from a trigger assigned payout
  /// handler occurs. When this value is non-zero, the SafetyModule is triggered (or paused).
  function numPendingSlashes() external returns (uint16);

  /// @notice Returns the address of the SafetyModule owner.
  function owner() external view returns (address);

  /// @notice Pauses the SafetyModule if it's a valid state transition.
  /// @dev Only the owner or pauser can call this function.
  function pause() external;

  /// @notice Address of the SafetyModule pauser.
  function pauser() external view returns (address);

  /// @notice Maps payout handlers to the number of slashes they are currently entitled to.
  /// @dev The number of slashes that a payout handler is entitled to is increased each time a trigger triggers this
  /// SafetyModule, if the payout handler is assigned to the trigger. The number of slashes is decreased each time a
  /// slash from the trigger assigned payout handler occurs.
  function payoutHandlerNumPendingSlashes(address payoutHandler_) external returns (uint256);

  /// @notice Allows an on-chain or off-chain user to simulate the effects of their queued redemption (i.e. view the
  /// number of reserve assets received) at the current block, given current on-chain conditions.
  /// @param redemptionId_ The ID of the redemption to preview.
  function previewQueuedRedemption(uint64 redemptionId_)
    external
    view
    returns (RedemptionPreview memory redemptionPreview_);

  /// @notice Allows an on-chain or off-chain user to simulate the effects of their redemption (i.e. view the number
  /// of reserve assets received) at the current block, given current on-chain conditions.
  /// @param reservePoolId_ The ID of the reserve pool to redeem from.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to redeem.
  function previewRedemption(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 reserveAssetAmount_);

  /// @notice Address of the Cozy Safety Module protocol ReceiptTokenFactory.
  function receiptTokenFactory() external view returns (IReceiptTokenFactory);

  /// @notice Queues a redemption by burning `depositReceiptTokenAmount_` of `reservePoolId_` reserve pool deposit
  /// tokens.
  /// When the redemption is completed, `reserveAssetAmount_` of `reservePoolId_` reserve pool assets will be sent
  /// to `receiver_` if the reserve pool's assets are not slashed. If the SafetyModule is paused, the redemption
  /// will be completed instantly.
  /// @dev Assumes that user has approved the SafetyModule to spend its deposit tokens.
  /// @param reservePoolId_ The ID of the reserve pool to redeem from.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to redeem.
  /// @param receiver_ The address to receive the reserve assets.
  /// @param owner_ The address that owns the deposit receipt tokens.
  function redeem(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_, address receiver_, address owner_)
    external
    returns (uint64 redemptionId_, uint256 reserveAssetAmount_);

  /// @notice Accounting and metadata for reserve pools configured for this SafetyModule.
  /// @dev Reserve pool index in this array is its ID
  function reservePools(uint256 id_) external view returns (ReservePool memory reservePool_);

  /// @notice The state of this SafetyModule.
  function safetyModuleState() external view returns (SafetyModuleState);

  /// @notice Slashes the reserve pools, sends the assets to the receiver, and returns the safety module to the ACTIVE
  /// state if there are no payout handlers that still need to slash assets. Note: Payout handlers can call this
  /// function once for each triggered trigger that has it assigned as its payout handler.
  /// @param slashes_ The slashes to execute.
  /// @param receiver_ The address to receive the slashed assets.
  function slash(Slash[] memory slashes_, address receiver_) external;

  /// @notice Triggers the SafetyModule by referencing one of the triggers configured for this SafetyModule.
  /// @param trigger_ The trigger to reference when triggering the SafetyModule.
  function trigger(ITrigger trigger_) external;

  /// @notice Returns trigger related data.
  /// @param trigger_ The trigger to get data for.
  function triggerData(ITrigger trigger_) external view returns (Trigger memory);

  /// @notice Unpauses the SafetyModule.
  function unpause() external;

  /// @notice Signal an update to the safety module configs. Existing queued updates are overwritten.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  function updateConfigs(UpdateConfigsCalldataParams calldata configUpdates_) external;
}

// src/lib/SafetyModuleBaseStorage.sol

abstract contract SafetyModuleBaseStorage {
  /// @notice Accounting and metadata for reserve pools configured for this SafetyModule.
  /// @dev Reserve pool index in this array is its ID
  ReservePool[] public reservePools;

  /// @notice The asset pools configured for this SafetyModule.
  /// @dev Used for doing aggregate accounting of reserve assets.
  mapping(IERC20 reserveAsset_ => AssetPool assetPool_) public assetPools;

  /// @notice Maps triggers to trigger related data.
  mapping(ITrigger trigger_ => Trigger triggerData_) public triggerData;

  /// @notice Maps payout handlers to the number of slashes they are currently entitled to.
  /// @dev The number of slashes that a payout handler is entitled to is increased each time a trigger triggers this
  /// SafetyModule, if the payout handler is assigned to the trigger. The number of slashes is decreased each time a
  /// slash from the trigger assigned payout handler occurs.
  mapping(address payoutHandler_ => uint256 numPendingSlashes_) public payoutHandlerNumPendingSlashes;

  /// @notice Config, withdrawal and unstake delays.
  Delays public delays;

  /// @notice Metadata about the most recently queued configuration update.
  ConfigUpdateMetadata public lastConfigUpdate;

  /// @notice The state of this SafetyModule.
  SafetyModuleState public safetyModuleState;

  /// @notice The number of slashes that must occur before the SafetyModule can be active.
  /// @dev This value is incremented when a trigger occurs, and decremented when a slash from a trigger assigned payout
  /// handler occurs. When this value is non-zero, the SafetyModule is triggered (or paused).
  uint16 public numPendingSlashes;

  /// @notice True if the SafetyModule has been initialized.
  bool public initialized;

  /// @dev The Cozy SafetyModule protocol manager contract.
  ICozySafetyModuleManager public immutable cozySafetyModuleManager;

  /// @notice Address of the Cozy SafetyModule protocol ReceiptTokenFactory.
  IReceiptTokenFactory public immutable receiptTokenFactory;
}

// src/lib/SafetyModuleCommon.sol

abstract contract SafetyModuleCommon is SafetyModuleBaseStorage, ICommonErrors {
  /// @notice Returns the receipt token amount for a given amount of reserve assets after taking into account
  /// any pending fee drip.
  /// @dev Defined in SafetyModuleInspector.
  /// @param reservePoolId_ The ID of the reserve pool to convert the reserve asset amount for.
  /// @param reserveAssetAmount_ The amount of reserve assets to convert to deposit receipt tokens.
  function convertToReceiptTokenAmount(uint8 reservePoolId_, uint256 reserveAssetAmount_)
    public
    view
    virtual
    returns (uint256);

  // @notice Returns the reserve asset amount for a given amount of deposit receipt tokens after taking into account any
  // pending fee drip.
  /// @dev Defined in SafetyModuleInspector.
  /// @param reservePoolId_ The ID of the reserve pool to convert the deposit receipt token amount for.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to convert to reserve assets.
  function convertToReserveAssetAmount(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    public
    view
    virtual
    returns (uint256);

  /// @notice Updates the fee amounts for each reserve pool by applying a drip factor on the deposit amounts.
  /// @dev Defined in FeesHandler.
  function dripFees() public virtual;

  /// @notice Drips fees from the specified reserve pool.
  /// @dev Defined in FeesHandler.
  /// @param reservePool_ The reserve pool to drip fees from.
  /// @param dripModel_ The drip model to use for calculating the fees to drip.
  function _dripFeesFromReservePool(ReservePool storage reservePool_, IDripModel dripModel_) internal virtual;

  /// @notice Returns the next amount of fees to drip from the reserve pool.
  /// @dev Defined in FeesHandler.
  /// @param totalBaseAmount_ The total amount assets in the reserve pool, before the next drip.
  /// @param dripModel_ The drip model to use for calculating the fees to drip.
  /// @param lastDripTime_ The last time fees were dripped from the reserve pool.
  function _getNextDripAmount(uint256 totalBaseAmount_, IDripModel dripModel_, uint256 lastDripTime_)
    internal
    view
    virtual
    returns (uint256);

  /// @dev Prepares pending withdrawals to have their exchange rates adjusted after a trigger. Defined in `Redeemer`.
  /// @dev Defined in Redeemer.
  function _updateWithdrawalsAfterTrigger(
    uint8 reservePoolId_,
    ReservePool storage reservePool_,
    uint256 depositAmount_,
    uint256 slashAmount_
  ) internal virtual returns (uint256 newPendingWithdrawalsAmount_);
}

// src/lib/ConfiguratorLib.sol

library ConfiguratorLib {
  error InvalidTimestamp();

  /// @notice Signal an update to the SafetyModule configs. Existing queued updates are overwritten.
  /// @param lastConfigUpdate_ Metadata about the most recently queued configuration update.
  /// @param safetyModuleState_ The state of the SafetyModule.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param triggerData_ The mapping of trigger to trigger data.
  /// @param delays_ The existing delays config.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  /// @param manager_ The Cozy Safety Module protocol Manager.
  function updateConfigs(
    ConfigUpdateMetadata storage lastConfigUpdate_,
    SafetyModuleState safetyModuleState_,
    ReservePool[] storage reservePools_,
    mapping(ITrigger => Trigger) storage triggerData_,
    Delays storage delays_,
    UpdateConfigsCalldataParams calldata configUpdates_,
    ICozySafetyModuleManager manager_
  ) internal {
    if (safetyModuleState_ == SafetyModuleState.TRIGGERED) revert ICommonErrors.InvalidState();
    if (!isValidUpdate(reservePools_, triggerData_, configUpdates_, manager_)) {
      revert IConfiguratorErrors.InvalidConfiguration();
    }

    // Hash stored to ensure only queued updates can be applied.
    lastConfigUpdate_.queuedConfigUpdateHash = keccak256(
      abi.encode(configUpdates_.reservePoolConfigs, configUpdates_.triggerConfigUpdates, configUpdates_.delaysConfig)
    );

    uint64 configUpdateTime_ = uint64(block.timestamp) + delays_.configUpdateDelay;
    uint64 configUpdateDeadline_ = configUpdateTime_ + delays_.configUpdateGracePeriod;
    emit IConfiguratorEvents.ConfigUpdatesQueued(
      configUpdates_.reservePoolConfigs,
      configUpdates_.triggerConfigUpdates,
      configUpdates_.delaysConfig,
      configUpdateTime_,
      configUpdateDeadline_
    );

    lastConfigUpdate_.configUpdateTime = configUpdateTime_;
    lastConfigUpdate_.configUpdateDeadline = configUpdateDeadline_;
  }

  /// @notice Execute queued updates to SafetyModule configs.
  /// @dev If the SafetyModule becomes triggered before the queued update is applied, the queued update is cancelled
  /// and can be requeued by the owner when the SafetyModule returns to the active or paused states.
  /// @param lastConfigUpdate_ Metadata about the most recently queued configuration update.
  /// @param safetyModuleState_ The state of the SafetyModule.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param triggerData_ The mapping of trigger to trigger data.
  /// @param delays_ The existing delays config.
  /// @param receiptTokenFactory_ The ReceiptToken factory.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  function finalizeUpdateConfigs(
    ConfigUpdateMetadata storage lastConfigUpdate_,
    SafetyModuleState safetyModuleState_,
    ReservePool[] storage reservePools_,
    mapping(ITrigger => Trigger) storage triggerData_,
    Delays storage delays_,
    IReceiptTokenFactory receiptTokenFactory_,
    UpdateConfigsCalldataParams calldata configUpdates_
  ) internal {
    if (safetyModuleState_ == SafetyModuleState.TRIGGERED) revert ICommonErrors.InvalidState();
    if (block.timestamp < lastConfigUpdate_.configUpdateTime) revert InvalidTimestamp();
    if (block.timestamp > lastConfigUpdate_.configUpdateDeadline) revert InvalidTimestamp();

    // Ensure the queued config update hash matches the provided config updates.
    if (
      keccak256(
        abi.encode(configUpdates_.reservePoolConfigs, configUpdates_.triggerConfigUpdates, configUpdates_.delaysConfig)
      ) != lastConfigUpdate_.queuedConfigUpdateHash
    ) revert IConfiguratorErrors.InvalidConfiguration();

    // Reset the config update hash.
    lastConfigUpdate_.queuedConfigUpdateHash = 0;
    applyConfigUpdates(reservePools_, triggerData_, delays_, receiptTokenFactory_, configUpdates_);
  }

  /// @notice Returns true if the provided configs are valid for the SafetyModule, false otherwise.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param triggerData_ The mapping of trigger to trigger data.
  /// @param configUpdates_ The new configs.
  /// @param manager_ The Cozy Safety Module protocol Manager.
  function isValidUpdate(
    ReservePool[] storage reservePools_,
    mapping(ITrigger => Trigger) storage triggerData_,
    UpdateConfigsCalldataParams calldata configUpdates_,
    ICozySafetyModuleManager manager_
  ) internal view returns (bool) {
    // Generic validation of the configuration parameters.
    if (
      !isValidConfiguration(
        configUpdates_.reservePoolConfigs, configUpdates_.delaysConfig, manager_.allowedReservePools()
      )
    ) return false;

    // Validate number of reserve pools. It is only possible to add new pools, not remove existing ones.
    uint256 numExistingReservePools_ = reservePools_.length;
    if (configUpdates_.reservePoolConfigs.length < numExistingReservePools_) return false;

    // Validate existing reserve pools.
    for (uint8 i = 0; i < numExistingReservePools_; i++) {
      // Existing reserve pools cannot have their asset updated.
      if (reservePools_[i].asset != configUpdates_.reservePoolConfigs[i].asset) return false;
    }

    // Validate trigger config.
    for (uint16 i = 0; i < configUpdates_.triggerConfigUpdates.length; i++) {
      // Triggers that have successfully called trigger() on the safety module cannot be updated.
      if (triggerData_[configUpdates_.triggerConfigUpdates[i].trigger].triggered) return false;
    }

    return true;
  }

  /// @notice Returns true if the provided configs are generically valid, false otherwise.
  /// @dev Does not include SafetyModule-specific checks, e.g. checks based on existing reserve pools.
  function isValidConfiguration(
    ReservePoolConfig[] calldata reservePoolConfigs_,
    Delays calldata delaysConfig_,
    uint8 maxReservePools_
  ) internal pure returns (bool) {
    // Validate number of reserve pools.
    if (reservePoolConfigs_.length > maxReservePools_) return false;

    // Validate delays.
    if (delaysConfig_.configUpdateDelay <= delaysConfig_.withdrawDelay) return false;

    // Validate max slash percentages.
    for (uint8 i = 0; i < reservePoolConfigs_.length; i++) {
      if (reservePoolConfigs_[i].maxSlashPercentage > MathConstants.ZOC) return false;
    }

    return true;
  }

  /// @notice Apply queued updates to SafetyModule config.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param triggerData_ The mapping of trigger to trigger data.
  /// @param delays_ The existing delays config.
  /// @param receiptTokenFactory_ The ReceiptToken factory.
  /// @param configUpdates_ The new configs.
  function applyConfigUpdates(
    ReservePool[] storage reservePools_,
    mapping(ITrigger => Trigger) storage triggerData_,
    Delays storage delays_,
    IReceiptTokenFactory receiptTokenFactory_,
    UpdateConfigsCalldataParams calldata configUpdates_
  ) public {
    // Update existing reserve pool maxSlashPercentages. Reserve pool assets cannot be updated.
    uint8 numExistingReservePools_ = uint8(reservePools_.length);
    for (uint8 i = 0; i < numExistingReservePools_; i++) {
      reservePools_[i].maxSlashPercentage = configUpdates_.reservePoolConfigs[i].maxSlashPercentage;
    }

    // Initialize new reserve pools.
    for (uint8 i = numExistingReservePools_; i < configUpdates_.reservePoolConfigs.length; i++) {
      initializeReservePool(reservePools_, receiptTokenFactory_, configUpdates_.reservePoolConfigs[i], i);
    }

    // Update trigger configs.
    for (uint256 i = 0; i < configUpdates_.triggerConfigUpdates.length; i++) {
      // Triggers that have successfully called trigger() on the Safety cannot be updated.
      // The trigger must also not be in a triggered state.
      if (
        triggerData_[configUpdates_.triggerConfigUpdates[i].trigger].triggered
          || configUpdates_.triggerConfigUpdates[i].trigger.state() == TriggerState.TRIGGERED
      ) revert IConfiguratorErrors.InvalidConfiguration();
      triggerData_[configUpdates_.triggerConfigUpdates[i].trigger] = Trigger({
        exists: configUpdates_.triggerConfigUpdates[i].exists,
        payoutHandler: configUpdates_.triggerConfigUpdates[i].payoutHandler,
        triggered: false
      });
    }

    // Update delays.
    delays_.configUpdateDelay = configUpdates_.delaysConfig.configUpdateDelay;
    delays_.configUpdateGracePeriod = configUpdates_.delaysConfig.configUpdateGracePeriod;
    delays_.withdrawDelay = configUpdates_.delaysConfig.withdrawDelay;

    emit IConfiguratorEvents.ConfigUpdatesFinalized(
      configUpdates_.reservePoolConfigs, configUpdates_.triggerConfigUpdates, configUpdates_.delaysConfig
    );
  }

  /// @notice Initializes a new reserve pool when it is added to the SafetyModule.
  /// @param reservePools_ The array of existing reserve pools.
  /// @param receiptTokenFactory_ The ReceiptToken factory.
  /// @param reservePoolConfig_ The new reserve pool config.
  /// @param reservePoolId_ The ID of the new reserve pool.
  function initializeReservePool(
    ReservePool[] storage reservePools_,
    IReceiptTokenFactory receiptTokenFactory_,
    ReservePoolConfig calldata reservePoolConfig_,
    uint8 reservePoolId_
  ) internal {
    IReceiptToken reserveDepositReceiptToken_ = receiptTokenFactory_.deployReceiptToken(
      reservePoolId_, IReceiptTokenFactory.PoolType.RESERVE, reservePoolConfig_.asset.decimals()
    );

    reservePools_.push(
      ReservePool({
        asset: reservePoolConfig_.asset,
        depositReceiptToken: reserveDepositReceiptToken_,
        depositAmount: 0,
        pendingWithdrawalsAmount: 0,
        feeAmount: 0,
        maxSlashPercentage: reservePoolConfig_.maxSlashPercentage,
        lastFeesDripTime: uint128(block.timestamp)
      })
    );

    emit IConfiguratorEvents.ReservePoolCreated(reservePoolId_, reservePoolConfig_.asset, reserveDepositReceiptToken_);
  }
}

// src/lib/SafetyModuleInspector.sol

abstract contract SafetyModuleInspector is SafetyModuleCommon {
  /// @notice Returns the receipt token amount for a given amount of reserve assets after taking into account
  /// any pending fee drip.
  /// @param reservePoolId_ The ID of the reserve pool to convert the reserve asset amount for.
  /// @param reserveAssetAmount_ The amount of reserve assets to convert to deposit receipt tokens.
  function convertToReceiptTokenAmount(uint8 reservePoolId_, uint256 reserveAssetAmount_)
    public
    view
    override
    returns (uint256)
  {
    ReservePool memory reservePool_ = reservePools[reservePoolId_];
    uint256 nextTotalPoolAmount_ = _getTotalReservePoolAmountForExchangeRate(reservePool_);
    return SafetyModuleCalculationsLib.convertToReceiptTokenAmount(
      reserveAssetAmount_, reservePool_.depositReceiptToken.totalSupply(), nextTotalPoolAmount_
    );
  }

  /// @notice Returns the reserve asset amount for a given amount of deposit receipt tokens after taking into account
  /// any
  /// pending fee drip.
  /// @param reservePoolId_ The ID of the reserve pool to convert the deposit receipt token amount for.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to convert to reserve assets.
  function convertToReserveAssetAmount(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    public
    view
    override
    returns (uint256)
  {
    ReservePool memory reservePool_ = reservePools[reservePoolId_];
    uint256 nextTotalPoolAmount_ = _getTotalReservePoolAmountForExchangeRate(reservePool_);
    return SafetyModuleCalculationsLib.convertToAssetAmount(
      depositReceiptTokenAmount_, reservePool_.depositReceiptToken.totalSupply(), nextTotalPoolAmount_
    );
  }

  /// @notice Returns the amount of assets in the reserve pool to be used for exchange rate calculations after taking
  /// into
  /// account any pending fee drip.
  /// @param reservePool_ The reserve pool to target.
  function _getTotalReservePoolAmountForExchangeRate(ReservePool memory reservePool_) internal view returns (uint256) {
    uint256 totalPoolAmount_ = reservePool_.depositAmount - reservePool_.pendingWithdrawalsAmount;
    if (safetyModuleState == SafetyModuleState.ACTIVE) {
      return totalPoolAmount_
        - _getNextDripAmount(
          totalPoolAmount_,
          cozySafetyModuleManager.getFeeDripModel(ISafetyModule(address(this))),
          reservePool_.lastFeesDripTime
        );
    } else {
      return totalPoolAmount_;
    }
  }
}

// src/lib/Depositor.sol

abstract contract Depositor is SafetyModuleCommon, IDepositorErrors {
  using SafeERC20 for IERC20;

  /// @dev Emitted when a user deposits reserve assets.
  event Deposited(
    address indexed caller_,
    address indexed receiver_,
    uint8 indexed reservePoolId_,
    IReceiptToken depositReceiptToken_,
    uint256 assetAmount_,
    uint256 depositReceiptTokenAmount_
  );

  /// @notice Deposits reserve assets into the SafetyModule and mints deposit receipt tokens.
  /// @dev Expects `msg.sender` to have approved this SafetyModule for `reserveAssetAmount_` of
  /// `reservePools[reservePoolId_].asset` so it can `transferFrom` the assets to this SafetyModule.
  /// @param reservePoolId_ The ID of the reserve pool to deposit assets into.
  /// @param reserveAssetAmount_ The amount of reserve assets to deposit.
  /// @param receiver_ The address to receive the deposit receipt tokens.
  function depositReserveAssets(uint8 reservePoolId_, uint256 reserveAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_)
  {
    ReservePool storage reservePool_ = reservePools[reservePoolId_];

    IERC20 underlyingToken_ = reservePool_.asset;
    AssetPool storage assetPool_ = assetPools[underlyingToken_];

    // Pull in deposited assets. After the transfer we ensure we no longer need any assets. This check is
    // required to support fee on transfer tokens, for example if USDT enables a fee.
    // Also, we need to transfer before minting or ERC777s could reenter.
    underlyingToken_.safeTransferFrom(msg.sender, address(this), reserveAssetAmount_);

    depositReceiptTokenAmount_ =
      _executeReserveDeposit(reservePoolId_, underlyingToken_, reserveAssetAmount_, receiver_, assetPool_, reservePool_);
  }

  /// @notice Deposits reserve assets into the SafetyModule and mints deposit receipt tokens.
  /// @dev Expects depositer to transfer assets to the SafetyModule beforehand.
  /// @param reservePoolId_ The ID of the reserve pool to deposit assets into.
  /// @param reserveAssetAmount_ The amount of reserve assets to deposit.
  /// @param receiver_ The address to receive the deposit receipt tokens.
  function depositReserveAssetsWithoutTransfer(uint8 reservePoolId_, uint256 reserveAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_)
  {
    ReservePool storage reservePool_ = reservePools[reservePoolId_];
    IERC20 underlyingToken_ = reservePool_.asset;
    AssetPool storage assetPool_ = assetPools[underlyingToken_];

    depositReceiptTokenAmount_ =
      _executeReserveDeposit(reservePoolId_, underlyingToken_, reserveAssetAmount_, receiver_, assetPool_, reservePool_);
  }

  /// @notice Deposits reserve assets into the SafetyModule and mints deposit receipt tokens.
  /// @param reservePoolId_ The ID of the reserve pool to deposit assets into.
  /// @param underlyingToken_ The address of the underlying token to deposit.
  /// @param reserveAssetAmount_ The amount of reserve assets to deposit.
  /// @param receiver_ The address to receive the deposit receipt tokens.
  /// @param assetPool_ The asset pool for the underlying asset of the reserve pool that is being deposited into.
  /// @param reservePool_ The reserve pool to deposit assets into.
  function _executeReserveDeposit(
    uint8 reservePoolId_,
    IERC20 underlyingToken_,
    uint256 reserveAssetAmount_,
    address receiver_,
    AssetPool storage assetPool_,
    ReservePool storage reservePool_
  ) internal returns (uint256 depositReceiptTokenAmount_) {
    SafetyModuleState safetyModuleState_ = safetyModuleState;
    if (safetyModuleState_ == SafetyModuleState.PAUSED) revert InvalidState();

    // Ensure the deposit amount is valid w.r.t. the balance of the SafetyModule.
    if (underlyingToken_.balanceOf(address(this)) - assetPool_.amount < reserveAssetAmount_) revert InvalidDeposit();

    if (safetyModuleState_ == SafetyModuleState.ACTIVE) {
      _dripFeesFromReservePool(reservePool_, cozySafetyModuleManager.getFeeDripModel(ISafetyModule(address(this))));
    }

    IReceiptToken depositReceiptToken_ = reservePool_.depositReceiptToken;
    // Fees were dripped in this block if the SafetyModule is active, so we don't need to subtract next drip amount
    // and can use the SafetyModuleCalculationsLib directly. Fees do not drip while the SafetyModule is not active.
    depositReceiptTokenAmount_ = SafetyModuleCalculationsLib.convertToReceiptTokenAmount(
      reserveAssetAmount_,
      depositReceiptToken_.totalSupply(),
      reservePool_.depositAmount - reservePool_.pendingWithdrawalsAmount
    );
    if (depositReceiptTokenAmount_ == 0) revert RoundsToZero();

    // Increment reserve pool accounting only after calculating `depositReceiptTokenAmount_` to mint.
    reservePool_.depositAmount += reserveAssetAmount_;
    assetPool_.amount += reserveAssetAmount_;

    depositReceiptToken_.mint(receiver_, depositReceiptTokenAmount_);
    emit Deposited(
      msg.sender, receiver_, reservePoolId_, depositReceiptToken_, reserveAssetAmount_, depositReceiptTokenAmount_
    );
  }
}

// src/lib/FeesHandler.sol

abstract contract FeesHandler is SafetyModuleCommon {
  using FixedPointMathLib for uint256;
  using SafeERC20 for IERC20;

  /// @dev Emitted when fees are claimed.
  event ClaimedFees(IERC20 indexed reserveAsset_, uint256 feeAmount_, address indexed owner_);

  /// @inheritdoc SafetyModuleCommon
  function dripFees() public override {
    if (safetyModuleState != SafetyModuleState.ACTIVE) return;
    IDripModel dripModel_ = cozySafetyModuleManager.getFeeDripModel(ISafetyModule(address(this)));

    uint256 numReserveAssets_ = reservePools.length;
    for (uint8 i = 0; i < numReserveAssets_; i++) {
      _dripFeesFromReservePool(reservePools[i], dripModel_);
    }
  }

  /// @notice Drips fees from a specific reserve pool.
  /// @param reservePoolId_ The ID of the reserve pool to drip fees from.
  function dripFeesFromReservePool(uint8 reservePoolId_) external {
    if (safetyModuleState != SafetyModuleState.ACTIVE) return;
    IDripModel dripModel_ = cozySafetyModuleManager.getFeeDripModel(ISafetyModule(address(this)));

    _dripFeesFromReservePool(reservePools[reservePoolId_], dripModel_);
  }

  /// @notice Claims any accrued fees to the CozySafetyModuleManager owner.
  /// @dev Validation is handled in the CozySafetyModuleManager, which is the only account authorized to call this
  /// method.
  /// @param owner_ The address to transfer the fees to.
  /// @param dripModel_ The drip model to use for calculating fee drip.
  function claimFees(address owner_, IDripModel dripModel_) external {
    // Cozy fee claims will often be batched, so we require it to be initiated from the CozySafetyModuleManager to save
    // gas by removing calls and SLOADs to check the owner addresses each time.
    if (msg.sender != address(cozySafetyModuleManager)) revert Ownable.Unauthorized();

    uint256 numReservePools_ = reservePools.length;
    bool safetyModuleIsActive_ = safetyModuleState == SafetyModuleState.ACTIVE;
    for (uint8 i = 0; i < numReservePools_; i++) {
      ReservePool storage reservePool_ = reservePools[i];
      _claimFees(reservePool_, dripModel_, safetyModuleIsActive_, owner_);
    }
  }

  /// @notice Claims any accrued fees for the specified reserve pools to the CozySafetyModuleManager owner.
  /// @param reservePoolIds_ The IDs of the reserve pools to claim fees from.
  function claimFees(uint8[] calldata reservePoolIds_) external {
    address receiver_ = cozySafetyModuleManager.owner();
    IDripModel dripModel_ = cozySafetyModuleManager.getFeeDripModel(ISafetyModule(address(this)));

    bool safetyModuleIsActive_ = safetyModuleState == SafetyModuleState.ACTIVE;
    for (uint8 i = 0; i < reservePoolIds_.length; i++) {
      ReservePool storage reservePool_ = reservePools[reservePoolIds_[i]];
      _claimFees(reservePool_, dripModel_, safetyModuleIsActive_, receiver_);
    }
  }

  /// @notice Claims any accrued fees from the specified reserve pool to the specified receiver.
  /// @param reservePool_ The reserve pool to claim fees from.
  /// @param dripModel_ The drip model to use for calculating fee drip.
  /// @param safetyModuleIsActive Whether the safety module is active.
  /// @param receiver_ The address to transfer the fees to.
  function _claimFees(
    ReservePool storage reservePool_,
    IDripModel dripModel_,
    bool safetyModuleIsActive,
    address receiver_
  ) internal {
    if (safetyModuleIsActive) _dripFeesFromReservePool(reservePool_, dripModel_);

    uint256 feeAmount_ = reservePool_.feeAmount;
    if (feeAmount_ > 0) {
      IERC20 asset_ = reservePool_.asset;
      reservePool_.feeAmount = 0;
      assetPools[asset_].amount -= feeAmount_;
      asset_.safeTransfer(receiver_, feeAmount_);

      emit ClaimedFees(asset_, feeAmount_, receiver_);
    }
  }

  /// @notice Drips fees from the specified reserve pool.
  /// @param reservePool_ The reserve pool to drip fees from.
  /// @param dripModel_ The drip model to use for calculating the fees to drip.
  function _dripFeesFromReservePool(ReservePool storage reservePool_, IDripModel dripModel_) internal override {
    uint256 drippedFromDepositAmount_ = _getNextDripAmount(
      reservePool_.depositAmount - reservePool_.pendingWithdrawalsAmount, dripModel_, reservePool_.lastFeesDripTime
    );

    if (drippedFromDepositAmount_ > 0) {
      reservePool_.feeAmount += drippedFromDepositAmount_;
      reservePool_.depositAmount -= drippedFromDepositAmount_;
    }

    reservePool_.lastFeesDripTime = uint128(block.timestamp);
  }

  /// @inheritdoc SafetyModuleCommon
  function _getNextDripAmount(uint256 totalBaseAmount_, IDripModel dripModel_, uint256 lastDripTime_)
    internal
    view
    override
    returns (uint256)
  {
    uint256 dripFactor_ = dripModel_.dripFactor(lastDripTime_, totalBaseAmount_);
    if (dripFactor_ > MathConstants.WAD) revert InvalidDripFactor();

    return totalBaseAmount_.mulWadDown(dripFactor_);
  }
}

// src/lib/StateChanger.sol

abstract contract StateChanger is SafetyModuleCommon, Governable, IStateChangerEvents, IStateChangerErrors {
  /// @notice Pauses the SafetyModule if it's a valid state transition.
  /// @dev Only the owner or pauser can call this function.
  function pause() external {
    SafetyModuleState currState_ = safetyModuleState;
    if (
      !StateTransitionsLib.isValidStateTransition(
        _getCallerRole(msg.sender), SafetyModuleState.PAUSED, currState_, _nonZeroPendingSlashes()
      )
    ) revert InvalidStateTransition();

    // If transitioning to paused from triggered, any queued config update is reset to prevent config updates from
    // accruing config delay time while triggered, which would result in the possibility of finalizing config updates
    // when the SafetyModule becomes paused, before users have sufficient time to react to the queued update.
    if (currState_ == SafetyModuleState.TRIGGERED) lastConfigUpdate.queuedConfigUpdateHash = bytes32(0);

    // Drip fees before pausing, since fees are not dripped while the SafetyModule is paused.
    dripFees();
    safetyModuleState = SafetyModuleState.PAUSED;
    emit SafetyModuleStateUpdated(SafetyModuleState.PAUSED);
  }

  /// @notice Unpauses the SafetyModule if it's a valid state transition.
  /// @dev Only the owner can call this function.
  function unpause() external {
    SafetyModuleState currState_ = safetyModuleState;
    // If number of pending slashes is non-zero, when the safety module is unpaused it will transition to TRIGGERED.
    SafetyModuleState newState_ = _nonZeroPendingSlashes() ? SafetyModuleState.TRIGGERED : SafetyModuleState.ACTIVE;
    if (
      currState_ != SafetyModuleState.PAUSED
        || !StateTransitionsLib.isValidStateTransition(
          _getCallerRole(msg.sender), newState_, currState_, _nonZeroPendingSlashes()
        )
    ) revert InvalidStateTransition();

    safetyModuleState = newState_;
    // Drip fees after unpausing since fees are not dripped while the SafetyModule is paused.
    dripFees();
    emit SafetyModuleStateUpdated(newState_);
  }

  /// @notice Triggers the SafetyModule by referencing one of the triggers configured for this SafetyModule.
  /// @param trigger_ The trigger to reference when triggering the SafetyModule.
  function trigger(ITrigger trigger_) external {
    Trigger memory triggerData_ = triggerData[trigger_];

    if (!triggerData_.exists || trigger_.state() != TriggerState.TRIGGERED || triggerData_.triggered) {
      revert InvalidTrigger();
    }

    // Drip fees before triggering the safety module, since fees are not dripped while the SafetyModule is triggered.
    dripFees();

    // Each trigger has an assigned payout handler that is authorized to slash assets once when the trigger is
    // used to trigger the SafetyModule. Payout handlers can be assigned to multiple triggers, but each trigger
    // can only have one payout handler.
    numPendingSlashes += 1;
    payoutHandlerNumPendingSlashes[triggerData_.payoutHandler] += 1;
    triggerData[trigger_].triggered = true;
    emit Triggered(trigger_);

    // If the SafetyModule is PAUSED, it remains PAUSED and will transition to TRIGGERED when unpaused since
    // now we have `numPendingSlashes` >= 1.
    // If the SafetyModule is TRIGGERED, it remains TRIGGERED since now we have `numPendingSlashes` >= 2.
    // If the SafetyModule is ACTIVE, it needs to be transition to TRIGGERED.
    if (safetyModuleState == SafetyModuleState.ACTIVE) {
      safetyModuleState = SafetyModuleState.TRIGGERED;
      emit SafetyModuleStateUpdated(SafetyModuleState.TRIGGERED);
    }
  }

  /// @notice Returns the role of the caller.
  /// @param who_ The address of the caller.
  function _getCallerRole(address who_) internal view returns (CallerRole) {
    CallerRole role_ = CallerRole.NONE;
    if (who_ == owner) role_ = CallerRole.OWNER;
    else if (who_ == pauser) role_ = CallerRole.PAUSER;
    // If the caller is the Manager itself, authorization for the call is done
    // in the Manager.
    else if (who_ == address(cozySafetyModuleManager)) role_ = CallerRole.MANAGER;
    return role_;
  }

  /// @notice Returns whether the number of pending slashes is non-zero.
  function _nonZeroPendingSlashes() internal view returns (bool) {
    return numPendingSlashes > 0;
  }
}

// src/lib/Configurator.sol

abstract contract Configurator is SafetyModuleCommon, Governable {
  /// @notice Signal an update to the safety module configs. Existing queued updates are overwritten.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  function updateConfigs(UpdateConfigsCalldataParams calldata configUpdates_) external onlyOwner {
    ConfiguratorLib.updateConfigs(
      lastConfigUpdate, safetyModuleState, reservePools, triggerData, delays, configUpdates_, cozySafetyModuleManager
    );
  }

  /// @notice Execute queued updates to the safety module configs.
  /// @dev If the SafetyModule becomes triggered before the queued update is applied, the queued update is cancelled
  /// and can be requeued by the owner when the SafetyModule returns to the active or paused states.
  /// @param configUpdates_ The new configs. Includes:
  /// - reservePoolConfigs: The array of new reserve pool configs, sorted by associated ID. The array may also
  /// include config for new reserve pools.
  /// - triggerConfigUpdates: The array of trigger config updates. It only needs to include config for updates to
  /// existing triggers or new triggers.
  /// - delaysConfig: The new delays config.
  function finalizeUpdateConfigs(UpdateConfigsCalldataParams calldata configUpdates_) external {
    ConfiguratorLib.finalizeUpdateConfigs(
      lastConfigUpdate, safetyModuleState, reservePools, triggerData, delays, receiptTokenFactory, configUpdates_
    );
  }

  /// @notice Update pauser to `newPauser_`.
  /// @param newPauser_ The new pauser.
  function updatePauser(address newPauser_) external {
    if (newPauser_ == address(cozySafetyModuleManager)) revert IConfiguratorErrors.InvalidConfiguration();
    _updatePauser(newPauser_);
  }
}

// src/lib/SlashHandler.sol

abstract contract SlashHandler is SafetyModuleCommon, ISlashHandlerErrors, ISlashHandlerEvents {
  using FixedPointMathLib for uint256;
  using SafeERC20 for IERC20;

  /// @notice Slashes the reserve pools, sends the assets to the receiver, and returns the safety module to the ACTIVE
  /// state if there are no payout handlers that still need to slash assets. Note: Payout handlers can call this
  /// function once for each triggered trigger that has it assigned as its payout handler.
  /// @param slashes_ The slashes to execute.
  /// @param receiver_ The address to receive the slashed assets.
  function slash(Slash[] memory slashes_, address receiver_) external {
    // If the payout handler is invalid, the default numPendingSlashes state is also 0.
    if (payoutHandlerNumPendingSlashes[msg.sender] == 0) revert Ownable.Unauthorized();
    if (safetyModuleState != SafetyModuleState.TRIGGERED) revert InvalidState();

    // Once all slashes are processed from each of the triggered trigger's assigned payout handlers, the safety module
    // is returned to the ACTIVE state.
    numPendingSlashes -= 1;
    payoutHandlerNumPendingSlashes[msg.sender] -= 1;
    if (numPendingSlashes == 0) {
      // If transitioning to triggered from active, any queued config update is reset to prevent config updates
      // from accruing config delay time while triggered, which would result in the possibility of finalizing config
      // updates when the SafetyModule returns to active, before users have sufficient time to react to the queued
      // update.
      lastConfigUpdate.queuedConfigUpdateHash = bytes32(0);

      safetyModuleState = SafetyModuleState.ACTIVE;
      emit IStateChangerEvents.SafetyModuleStateUpdated(SafetyModuleState.ACTIVE);
    }

    // Create a bitmap to track which reserve pools have already been slashed during execution of the following loop.
    uint256 alreadySlashed_ = 0;
    for (uint16 i = 0; i < slashes_.length; i++) {
      alreadySlashed_ = _updateAlreadySlashed(alreadySlashed_, slashes_[i].reservePoolId);

      Slash memory slash_ = slashes_[i];
      ReservePool storage reservePool_ = reservePools[slash_.reservePoolId];
      IERC20 reserveAsset_ = reservePool_.asset;
      uint256 reservePoolDepositAmount_ = reservePool_.depositAmount;

      // Slash reserve pool assets.
      if (slash_.amount > 0 && reservePoolDepositAmount_ > 0) {
        uint256 slashPercentage_ = _computeSlashPercentage(slash_.amount, reservePoolDepositAmount_);
        if (slashPercentage_ > reservePool_.maxSlashPercentage) {
          revert ExceedsMaxSlashPercentage(slash_.reservePoolId, slashPercentage_);
        }

        reservePool_.pendingWithdrawalsAmount =
          _updateWithdrawalsAfterTrigger(slash_.reservePoolId, reservePool_, reservePoolDepositAmount_, slash_.amount);
        reservePool_.depositAmount -= slash_.amount;
        assetPools[reserveAsset_].amount -= slash_.amount;

        // Transfer the slashed assets to the specified receiver.
        reserveAsset_.safeTransfer(receiver_, slash_.amount);
        emit Slashed(msg.sender, receiver_, slash_.reservePoolId, slash_.amount);
      }
    }
  }

  /// @notice Returns the maximum amount of assets that can be slashed from the specified reserve pool.
  /// @param reservePoolId_ The ID of the reserve pool to get the maximum slashable amount for.
  function getMaxSlashableReservePoolAmount(uint8 reservePoolId_)
    external
    view
    returns (uint256 slashableReservePoolAmount_)
  {
    return reservePools[reservePoolId_].depositAmount.mulDivDown(
      reservePools[reservePoolId_].maxSlashPercentage, MathConstants.ZOC
    );
  }

  /// @notice Returns the percentage corresponding to the amount of assets to be slashed from the reserve pool.
  /// @param slashAmount_ The amount of assets to be slashed.
  /// @param totalReservePoolAmount_ The total amount of assets in the reserve pool.
  function _computeSlashPercentage(uint256 slashAmount_, uint256 totalReservePoolAmount_)
    internal
    pure
    returns (uint256)
  {
    // Round up, in favor of depositors.
    return slashAmount_.mulDivUp(MathConstants.ZOC, totalReservePoolAmount_);
  }

  /// @notice Updates the bitmap used to track which reserve pools have already been slashed.
  /// @param alreadySlashed_ The bitmap to update.
  /// @param poolId_ The ID of the reserve pool to update the bitmap for.
  function _updateAlreadySlashed(uint256 alreadySlashed_, uint8 poolId_) internal pure returns (uint256) {
    // Using the left shift here is valid because poolId_ < allowedReservePools <= 255.
    if ((alreadySlashed_ & (1 << poolId_)) != 0) revert AlreadySlashed(poolId_);
    return alreadySlashed_ | (1 << poolId_);
  }
}

// src/lib/Redeemer.sol

abstract contract Redeemer is SafetyModuleCommon, IRedemptionErrors {
  using SafeERC20 for IERC20;
  using SafeCastLib for uint256;
  using CozyMath for uint256;

  /// @notice List of accumulated inverse scaling factors for redemption, with the last value being the latest,
  ///         on a reserve pool basis.
  /// @dev Every time there is a trigger, a scaling factor is retroactively applied to every pending
  ///      redemption equiv to:
  ///        x = 1 - slashedAmount / reservePool.depositAmount
  ///      The last value of this array (a) will be updated to be a = a * 1 / x (scaled by WAD).
  ///      Because x will always be <= 1, the accumulated scaling factor will always INCREASE by a factor of 1/x
  ///      and can run out of usable bits (see RedemptionLib.MAX_SAFE_ACCUM_INV_SCALING_FACTOR_VALUE).
  ///      This can even happen after a single trigger if 100% of pool is consumed because 1/0 = INF.
  ///      If this happens, a new entry (1.0) is appended to the end of this array and the next trigger
  ///      will accumulate on that value.
  mapping(uint8 reservePoolId_ => uint256[] reservePoolPendingRedemptionAccISFs) internal pendingRedemptionAccISFs;

  /// @notice ID of next redemption.
  uint64 internal redemptionIdCounter;
  mapping(uint256 => Redemption) public redemptions;

  /// @dev Emitted when a user redeems.
  event Redeemed(
    address caller_,
    address indexed receiver_,
    address indexed owner_,
    uint8 indexed reservePoolId_,
    IReceiptToken receiptToken_,
    uint256 receiptTokenAmount_,
    uint256 reserveAssetAmount_,
    uint64 redemptionId_
  );

  /// @dev Emitted when a user queues an redemption.
  event RedemptionPending(
    address caller_,
    address indexed receiver_,
    address indexed owner_,
    uint8 indexed reservePoolId_,
    IReceiptToken receiptToken_,
    uint256 receiptTokenAmount_,
    uint256 reserveAssetAmount_,
    uint64 redemptionId_
  );

  /// @notice Queues a redemption by burning `depositReceiptTokenAmount_` of `reservePoolId_` reserve pool deposit
  /// tokens.
  /// When the redemption is completed, `reserveAssetAmount_` of `reservePoolId_` reserve pool assets will be sent
  /// to `receiver_` if the reserve pool's assets are not slashed. If the SafetyModule is paused, the redemption
  /// will be completed instantly.
  /// @dev Assumes that user has approved the SafetyModule to spend its deposit tokens.
  /// @param reservePoolId_ The ID of the reserve pool to redeem from.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to redeem.
  /// @param receiver_ The address to receive the reserve assets.
  /// @param owner_ The address that owns the deposit receipt tokens.
  function redeem(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_, address receiver_, address owner_)
    external
    returns (uint64 redemptionId_, uint256 reserveAssetAmount_)
  {
    SafetyModuleState safetyModuleState_ = safetyModuleState;
    if (safetyModuleState_ == SafetyModuleState.TRIGGERED) revert InvalidState();

    ReservePool storage reservePool_ = reservePools[reservePoolId_];
    if (safetyModuleState_ == SafetyModuleState.ACTIVE) {
      _dripFeesFromReservePool(reservePool_, cozySafetyModuleManager.getFeeDripModel(ISafetyModule(address(this))));
    }

    IReceiptToken receiptToken_ = reservePool_.depositReceiptToken;
    {
      // Fees were dripped already in this function if the SafetyModule is active, so we don't need to accomodate for
      // next fee drip amount here.
      uint256 assetsAvailableForRedemption_ = reservePool_.depositAmount - reservePool_.pendingWithdrawalsAmount;
      if (assetsAvailableForRedemption_ == 0) revert NoAssetsToRedeem();

      // Fees were dripped already in this function if the SafetyModule is active, so we can use the
      // SafetyModuleCalculationsLib directly. Fees do not drip while the SafetyModule is not active.
      reserveAssetAmount_ = SafetyModuleCalculationsLib.convertToAssetAmount(
        depositReceiptTokenAmount_, receiptToken_.totalSupply(), assetsAvailableForRedemption_
      );
      if (reserveAssetAmount_ == 0) revert RoundsToZero(); // Check for rounding error since we round down in
        // conversion.
    }

    redemptionId_ = _queueRedemption(
      owner_,
      receiver_,
      reservePool_,
      receiptToken_,
      depositReceiptTokenAmount_,
      reserveAssetAmount_,
      reservePoolId_,
      safetyModuleState_
    );
  }

  /// @notice Completes the redemption request for the specified redemption ID.
  /// @param redemptionId_ The ID of the redemption to complete.
  function completeRedemption(uint64 redemptionId_) external returns (uint256 reserveAssetAmount_) {
    Redemption memory redemption_ = redemptions[redemptionId_];
    delete redemptions[redemptionId_];
    return _completeRedemption(redemptionId_, redemption_);
  }

  /// @notice Allows an on-chain or off-chain user to simulate the effects of their redemption (i.e. view the number
  /// of reserve assets received) at the current block, given current on-chain conditions.
  /// @param reservePoolId_ The ID of the reserve pool to redeem from.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to redeem.
  function previewRedemption(uint8 reservePoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 reserveAssetAmount_)
  {
    if (safetyModuleState == SafetyModuleState.TRIGGERED) revert InvalidState();
    return convertToReserveAssetAmount(reservePoolId_, depositReceiptTokenAmount_);
  }

  /// @notice Allows an on-chain or off-chain user to simulate the effects of their queued redemption (i.e. view the
  /// number of reserve assets received) at the current block, given current on-chain conditions.
  /// @param redemptionId_ The ID of the redemption to preview.
  function previewQueuedRedemption(uint64 redemptionId_)
    external
    view
    returns (RedemptionPreview memory redemptionPreview_)
  {
    Redemption memory redemption_ = redemptions[redemptionId_];
    redemptionPreview_ = RedemptionPreview({
      delayRemaining: _getRedemptionDelayTimeRemaining(redemption_.queueTime, redemption_.delay).safeCastTo40(),
      receiptToken: redemption_.receiptToken,
      receiptTokenAmount: redemption_.receiptTokenAmount,
      reserveAssetAmount: _computeFinalReserveAssetsRedeemed(
        redemption_.reservePoolId, redemption_.assetAmount, redemption_.queuedAccISF, redemption_.queuedAccISFsLength
        ),
      owner: redemption_.owner,
      receiver: redemption_.receiver
    });
  }

  /// @notice Logic to queue a redemption.
  /// @param owner_ The owner of the deposit receipt tokens.
  /// @param receiver_ The address to receive the reserve assets.
  /// @param reservePool_ The reserve pool to redeem from.
  /// @param depositReceiptToken_ The deposit receipt token being redeemed.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to redeem.
  /// @param reserveAssetAmount_ The amount of reserve assets to redeem.
  /// @param reservePoolId_ The ID of the reserve pool to redeem from.
  /// @param safetyModuleState_ The current state of the SafetyModule.
  function _queueRedemption(
    address owner_,
    address receiver_,
    ReservePool storage reservePool_,
    IReceiptToken depositReceiptToken_,
    uint256 depositReceiptTokenAmount_,
    uint256 reserveAssetAmount_,
    uint8 reservePoolId_,
    SafetyModuleState safetyModuleState_
  ) internal returns (uint64 redemptionId_) {
    depositReceiptToken_.burn(msg.sender, owner_, depositReceiptTokenAmount_);

    redemptionId_ = redemptionIdCounter;
    unchecked {
      // Increments can never realistically overflow. Even with a uint64, you'd need to have 1000 redemptions per
      // second for 584,542,046 years.
      redemptionIdCounter = redemptionId_ + 1;
      reservePool_.pendingWithdrawalsAmount += reserveAssetAmount_;
    }

    uint256[] storage reservePoolPendingAccISFs = pendingRedemptionAccISFs[reservePoolId_];
    uint256 numScalingFactors_ = reservePoolPendingAccISFs.length;
    Redemption memory redemption_ = Redemption({
      reservePoolId: reservePoolId_,
      receiptToken: depositReceiptToken_,
      receiptTokenAmount: depositReceiptTokenAmount_.safeCastTo216(),
      assetAmount: reserveAssetAmount_.safeCastTo128(),
      owner: owner_,
      receiver: receiver_,
      queueTime: uint40(block.timestamp),
      // If the safety module is paused, redemptions can occur instantly.
      delay: safetyModuleState_ == SafetyModuleState.PAUSED ? 0 : uint40(delays.withdrawDelay),
      queuedAccISFsLength: uint32(numScalingFactors_),
      // If there are no scaling factors, the last scaling factor is 1.0.
      queuedAccISF: numScalingFactors_ == 0 ? MathConstants.WAD : reservePoolPendingAccISFs[numScalingFactors_ - 1]
    });

    if (redemption_.delay == 0) {
      _completeRedemption(redemptionId_, redemption_);
    } else {
      redemptions[redemptionId_] = redemption_;
      emit RedemptionPending(
        msg.sender,
        receiver_,
        owner_,
        reservePoolId_,
        depositReceiptToken_,
        depositReceiptTokenAmount_,
        reserveAssetAmount_,
        redemptionId_
      );
    }
  }

  /// @notice Logic to complete a redemption.
  /// @param redemptionId_ The ID of the redemption to complete.
  /// @param redemption_ The Redemption struct for the redemption to complete.
  function _completeRedemption(uint64 redemptionId_, Redemption memory redemption_)
    internal
    returns (uint128 reserveAssetAmountRedeemed_)
  {
    if (safetyModuleState == SafetyModuleState.TRIGGERED) revert InvalidState();
    if (redemption_.owner == address(0)) revert RedemptionNotFound();
    {
      if (_getRedemptionDelayTimeRemaining(redemption_.queueTime, redemption_.delay) != 0) revert DelayNotElapsed();
    }

    ReservePool storage reservePool_ = reservePools[redemption_.reservePoolId];
    IERC20 reserveAsset_ = reservePool_.asset;

    // Compute the final reserve assets to redemptions, which can be scaled down if triggers and slashes have occurred
    // since the redemption was queued.
    reserveAssetAmountRedeemed_ = _computeFinalReserveAssetsRedeemed(
      redemption_.reservePoolId, redemption_.assetAmount, redemption_.queuedAccISF, redemption_.queuedAccISFsLength
    );
    if (reserveAssetAmountRedeemed_ != 0) {
      reservePool_.depositAmount -= reserveAssetAmountRedeemed_;
      reservePool_.pendingWithdrawalsAmount -= reserveAssetAmountRedeemed_;
      assetPools[reserveAsset_].amount -= reserveAssetAmountRedeemed_;
      reserveAsset_.safeTransfer(redemption_.receiver, reserveAssetAmountRedeemed_);
    }

    emit Redeemed(
      msg.sender,
      redemption_.receiver,
      redemption_.owner,
      redemption_.reservePoolId,
      redemption_.receiptToken,
      redemption_.receiptTokenAmount,
      reserveAssetAmountRedeemed_,
      redemptionId_
    );
  }

  /// @inheritdoc SafetyModuleCommon
  function _updateWithdrawalsAfterTrigger(
    uint8 reservePoolId_,
    ReservePool storage reservePool_,
    uint256 oldDepositAmount_,
    uint256 slashAmount_
  ) internal override returns (uint256 newPendingWithdrawalsAmount_) {
    uint256[] storage reservePoolPendingRedemptionsAccISFs = pendingRedemptionAccISFs[reservePoolId_];
    newPendingWithdrawalsAmount_ = RedemptionLib.updateRedemptionsAfterTrigger(
      reservePool_.pendingWithdrawalsAmount, oldDepositAmount_, slashAmount_, reservePoolPendingRedemptionsAccISFs
    );
  }

  /// @notice Returns the amount of time remaining before a queued redemption can be completed.
  /// @param queueTime_ The time at which the redemption was queued.
  /// @param delay_ The delay for the redemption.
  function _getRedemptionDelayTimeRemaining(uint40 queueTime_, uint256 delay_) internal view returns (uint256) {
    return RedemptionLib.getRedemptionDelayTimeRemaining(safetyModuleState, queueTime_, delay_, block.timestamp);
  }

  /// @notice Returns the amount of assets to be redeemed, which may be less than the amount saved when the redemption
  /// was queued if the assets are used in a payout for a trigger since then.
  /// @param reservePoolId_ The ID of the reserve pool to redeem from.
  /// @param queuedReserveAssetAmount_ The amount of reserve assets to redeem when the redemption was queued.
  /// @param queuedAccISF_ The last pendingRedemptionAccISFs value at queue time.
  /// @param queuedAccISFLength_ The length of pendingRedemptionAccISFs at queue time.
  function _computeFinalReserveAssetsRedeemed(
    uint8 reservePoolId_,
    uint128 queuedReserveAssetAmount_,
    uint256 queuedAccISF_,
    uint32 queuedAccISFLength_
  ) internal view returns (uint128) {
    uint256[] storage reservePoolPendingAccISFs_ = pendingRedemptionAccISFs[reservePoolId_];
    return RedemptionLib.computeFinalReserveAssetsRedeemed(
      reservePoolPendingAccISFs_, queuedReserveAssetAmount_, queuedAccISF_, queuedAccISFLength_
    );
  }
}

// src/SafetyModule.sol

contract SafetyModule is
  SafetyModuleBaseStorage,
  SafetyModuleInspector,
  Configurator,
  Depositor,
  Redeemer,
  SlashHandler,
  FeesHandler,
  StateChanger
{
  /// @dev Thrown if the contract is already initialized.
  error Initialized();

  /// @param cozySafetyModuleManager_ The Cozy Safety Module protocol manager.
  /// @param receiptTokenFactory_ The Cozy Safety Module protocol ReceiptTokenFactory.
  constructor(ICozySafetyModuleManager cozySafetyModuleManager_, IReceiptTokenFactory receiptTokenFactory_) {
    _assertAddressNotZero(address(cozySafetyModuleManager_));
    _assertAddressNotZero(address(receiptTokenFactory_));
    cozySafetyModuleManager = cozySafetyModuleManager_;
    receiptTokenFactory = receiptTokenFactory_;
  }

  /// @notice Initializes the SafetyModule with the specified parameters.
  /// @dev Replaces the constructor for minimal proxies.
  /// @param owner_ The SafetyModule owner.
  /// @param pauser_ The SafetyModule pauser.
  /// @param configs_ The SafetyModule configuration parameters. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  function initialize(address owner_, address pauser_, UpdateConfigsCalldataParams calldata configs_) external {
    if (initialized) revert Initialized();

    // Safety Modules are minimal proxies, so the owner and pauser is set to address(0) in the constructor for the logic
    // contract. When the set is initialized for the minimal proxy, we update the owner and pauser.
    if (pauser_ == address(cozySafetyModuleManager)) revert IConfiguratorErrors.InvalidConfiguration();
    __initGovernable(owner_, pauser_);

    initialized = true;
    ConfiguratorLib.applyConfigUpdates(reservePools, triggerData, delays, receiptTokenFactory, configs_);
  }
}