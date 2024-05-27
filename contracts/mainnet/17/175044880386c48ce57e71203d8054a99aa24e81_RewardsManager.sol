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

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
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
  /// @notice Thrown when an config update does not meet all requirements.
  error InvalidConfiguration();
}

// src/interfaces/IDepositorErrors.sol

interface IDepositorErrors {
  /// @notice Thrown when attempting an invalid deposit.
  error InvalidDeposit();
}

// src/lib/RewardsManagerStates.sol

enum RewardsManagerState {
  ACTIVE,
  PAUSED
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

// src/interfaces/IStateChangerEvents.sol

interface IStateChangerEvents {
  /// @notice Emitted when the rewards manager changes state.
  /// @param updatedTo_ The new state of the rewards manager.
  event RewardsManagerStateUpdated(RewardsManagerState indexed updatedTo_);
}

// src/lib/RewardsManagerCalculationsLib.sol

/**
 * @notice Read-only rewards manager calculations.
 */
library RewardsManagerCalculationsLib {
  using FixedPointMathLib for uint256;

  /// @notice The `receiptTokenAmount_` of the receipt tokens that the rewards manager would exchange for `assetAmount_`
  /// of underlying asset provided.
  /// @dev See the ERC-4626 spec for more info.
  function convertToReceiptTokenAmount(uint256 assetAmount_, uint256 receiptTokenSupply_, uint256 poolAmount_)
    internal
    pure
    returns (uint256 receiptTokenAmount_)
  {
    receiptTokenAmount_ =
      receiptTokenSupply_ == 0 ? assetAmount_ : assetAmount_.mulDivDown(receiptTokenSupply_, poolAmount_);
  }

  /// @notice The `assetAmount_` of the underlying asset that the rewards manager would exchange for
  /// `receiptTokenAmount_` of the receipt token provided.
  /// @dev See the ERC-4626 spec for more info.
  function convertToAssetAmount(uint256 receiptTokenAmount_, uint256 receiptTokenSupply_, uint256 poolAmount_)
    internal
    pure
    returns (uint256 assetAmount_)
  {
    assetAmount_ = receiptTokenSupply_ == 0 ? 0 : receiptTokenAmount_.mulDivDown(poolAmount_, receiptTokenSupply_);
  }
}

// src/lib/structs/Rewards.sol

// Used to track the rewards a user is entitled to for a given (stake pool, reward pool) pair.
struct UserRewardsData {
  // The total amount of rewards accrued by the user.
  uint256 accruedRewards;
  // The index snapshot the relevant claimable rewards data, when the user's accrued rewards were updated. The index
  // snapshot must update each time the user's accrued rewards are updated.
  uint256 indexSnapshot;
}

struct ClaimRewardsArgs {
  // The ID of the stake pool.
  uint16 stakePoolId;
  // The address that will receive the rewards.
  address receiver;
  // The address that owns the stkReceiptTokens.
  address owner;
}

// Used to track the total rewards all users are entitled to for a given (stake pool, reward pool) pair.
struct ClaimableRewardsData {
  // The cumulative amount of rewards that are claimable. This value is reset to 0 on each config update.
  uint256 cumulativeClaimableRewards;
  // The index snapshot the relevant claimable rewards data, when the cumulative claimed rewards were updated. The index
  // snapshot must update each time the cumulative claimed rewards are updated.
  uint256 indexSnapshot;
}

// Used as a return type for the `previewClaimableRewards` function.
struct PreviewClaimableRewards {
  // The ID of the stake pool.
  uint16 stakePoolId;
  // An array of preview claimable rewards data with one entry for each reward pool.
  PreviewClaimableRewardsData[] claimableRewardsData;
}

struct PreviewClaimableRewardsData {
  // The ID of the reward pool.
  uint16 rewardPoolId;
  // The amount of claimable rewards.
  uint256 amount;
  // The reward asset.
  IERC20 asset;
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

// src/interfaces/IDepositorEvents.sol

interface IDepositorEvents {
  /// @notice Emitted when a user deposits.
  /// @param caller_ The caller of the deposit.
  /// @param receiver_ The receiver of the deposit receipt tokens.
  /// @param rewardPoolId_ The reward pool ID that the user deposited into.
  /// @param depositReceiptToken_ The deposit receipt token for the reward pool.
  /// @param assetAmount_ The amount of the underlying asset deposited.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens minted.
  event Deposited(
    address indexed caller_,
    address indexed receiver_,
    uint16 indexed rewardPoolId_,
    IReceiptToken depositReceiptToken_,
    uint256 assetAmount_,
    uint256 depositReceiptTokenAmount_
  );

  /// @notice Emitted when a user redeems undripped rewards.
  /// @param caller_ The caller of the redemption.
  /// @param receiver_ The receiver of the undripped reward assets.
  /// @param owner_ The owner of the deposit receipt tokens which are being redeemed.
  /// @param rewardPoolId_ The reward pool ID that the user is redeeming from.
  /// @param depositReceiptToken_ The deposit receipt token for the reward pool.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens being redeemed.
  /// @param rewardAssetAmount_ The amount of undripped reward assets being redeemed.
  event RedeemedUndrippedRewards(
    address caller_,
    address indexed receiver_,
    address indexed owner_,
    uint16 indexed rewardPoolId_,
    IReceiptToken depositReceiptToken_,
    uint256 depositReceiptTokenAmount_,
    uint256 rewardAssetAmount_
  );
}

// src/lib/structs/Configs.sol

struct RewardPoolConfig {
  // The underlying asset of the reward pool.
  IERC20 asset;
  // The drip model for the reward pool.
  IDripModel dripModel;
}

struct StakePoolConfig {
  // The underlying asset of the stake pool.
  IERC20 asset;
  // The rewards weight of the stake pool.
  uint16 rewardsWeight;
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

// src/lib/structs/Pools.sol

struct AssetPool {
  // The total balance of assets held by a rewards manager. This should be equivalent to asset.balanceOf(address(this)),
  // discounting any assets directly sent to the rewards manager via direct transfer.
  uint256 amount;
}

struct StakePool {
  // The balance of the underlying asset held by the stake pool.
  uint256 amount;
  // The underlying asset of the stake pool.
  IERC20 asset;
  // The receipt token for the stake pool.
  IReceiptToken stkReceiptToken;
  // The weighting of each stake pool's claim to all reward pools in terms of a ZOC. Must sum to ZOC. e.g.
  // stakePoolA.rewardsWeight = 10%, means stake pool A is eligible for up to 10% of rewards dripped from all reward
  // pools.
  uint16 rewardsWeight;
}

struct RewardPool {
  // The amount of undripped rewards held by the reward pool.
  uint256 undrippedRewards;
  // The cumulative amount of rewards dripped since the last config update. This value is reset to 0 on each config
  // update.
  uint256 cumulativeDrippedRewards;
  // The last time undripped rewards were dripped from the reward pool.
  uint128 lastDripTime;
  // The underlying asset of the reward pool.
  IERC20 asset;
  // The drip model for the reward pool.
  IDripModel dripModel;
  // The receipt token for the reward pool.
  IReceiptToken depositReceiptToken;
}

struct IdLookup {
  // The index of the item in an array.
  uint16 index;
  // Whether the item exists.
  bool exists;
}

// src/interfaces/IConfiguratorEvents.sol

interface IConfiguratorEvents {
  /// @notice Emitted when a stake pool is created.
  /// @param stakePoolId The ID of the stake pool.
  /// @param stkReceiptToken The receipt token for the stake pool.
  /// @param asset The underlying asset of the stake pool.
  event StakePoolCreated(uint16 indexed stakePoolId, IReceiptToken stkReceiptToken, IERC20 asset);

  /// @notice Emitted when an reward pool is created.
  /// @param rewardPoolId The ID of the reward pool.
  /// @param depositReceiptToken The receipt token for the reward pool.
  /// @param asset The underlying asset of the reward pool.
  event RewardPoolCreated(uint16 indexed rewardPoolId, IReceiptToken depositReceiptToken, IERC20 asset);

  /// @notice Emitted when a rewards manager's config updates are applied.
  /// @param stakePoolConfigs The updated stake pool configs.
  /// @param rewardPoolConfigs The updated reward pool configs.
  event ConfigUpdatesApplied(StakePoolConfig[] stakePoolConfigs, RewardPoolConfig[] rewardPoolConfigs);
}

// src/lib/ConfiguratorLib.sol

library ConfiguratorLib {
  /// @notice Returns true if the provided configs are valid for the rewards manager, false otherwise.
  /// @param stakePools_ The array of existing stake pools.
  /// @param rewardPools_ The array of existing reward pools.
  /// @param assetToStakePoolIds_ The mapping of asset to stake pool IDs index lookups.
  /// @param stakePoolConfigs_ The array of stake pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_ The array of reward pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param allowedStakePools_ The maximum number of allowed stake pools.
  /// @param allowedRewardPools_ The maximum number of allowed reward pools.
  /// @return True if the provided configs are valid for the rewards manager, false otherwise.
  function isValidUpdate(
    StakePool[] storage stakePools_,
    RewardPool[] storage rewardPools_,
    mapping(IERC20 => IdLookup) storage assetToStakePoolIds_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    uint16 allowedStakePools_,
    uint16 allowedRewardPools_
  ) internal view returns (bool) {
    uint256 numExistingStakePools_ = stakePools_.length;
    uint256 numExistingRewardPools_ = rewardPools_.length;

    // Validate the configuration parameters.
    if (
      !isValidConfiguration(
        stakePoolConfigs_,
        rewardPoolConfigs_,
        numExistingStakePools_,
        numExistingRewardPools_,
        allowedStakePools_,
        allowedRewardPools_
      )
    ) return false;

    // Validate existing stake pools. The existing stake pool's underlying asset cannot change.
    for (uint16 i = 0; i < numExistingStakePools_; i++) {
      if (stakePools_[i].asset != stakePoolConfigs_[i].asset) return false;
    }

    // Validate new stake pools. The new stake pool's underlying asset cannot already be in use by an existing stake
    // pool.
    for (uint256 i = numExistingStakePools_; i < stakePoolConfigs_.length; i++) {
      if (assetToStakePoolIds_[stakePoolConfigs_[i].asset].exists) return false;
    }

    // Validate existing reward pools. The existing reward pool's underlying asset cannot change.
    for (uint16 i = 0; i < numExistingRewardPools_; i++) {
      if (rewardPools_[i].asset != rewardPoolConfigs_[i].asset) return false;
    }

    return true;
  }

  /// @notice Returns true if the provided configs are generically valid for a rewards manager, false otherwise.
  /// @param stakePoolConfigs_ The array of stake pool configs.
  /// @param rewardPoolConfigs_ The array of reward pool configs.
  /// @param numExistingStakePools_ The number of existing stake pools.
  /// @param numExistingRewardPools_ The number of existing reward pools.
  /// @param allowedStakePools_ The maximum number of allowed stake pools.
  /// @param allowedRewardPools_ The maximum number of allowed reward pools.
  /// @return True if the provided configs are generically valid for a rewards manager, false otherwise. If this
  /// reverts, it means that a reward pool drip model does not conform to the required interface.
  function isValidConfiguration(
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    uint256 numExistingStakePools_,
    uint256 numExistingRewardPools_,
    uint16 allowedStakePools_,
    uint16 allowedRewardPools_
  ) internal view returns (bool) {
    // Validate number of stake pools. The number of stake pools configs must be greater than or equal to the number of
    // existing stake pools, and less than or equal to the maximum allowed stake pools.
    if (stakePoolConfigs_.length > allowedStakePools_ || stakePoolConfigs_.length < numExistingStakePools_) {
      return false;
    }

    // Validate number of reward pools. The number of reward pools configs must be greater than or equal to the number
    // of existing reward pools, and less than or equal to the maximum allowed reward pools.
    if (rewardPoolConfigs_.length > allowedRewardPools_ || rewardPoolConfigs_.length < numExistingRewardPools_) {
      return false;
    }

    if (stakePoolConfigs_.length != 0) {
      uint16 rewardsWeightSum_ = 0;

      for (uint256 i = 0; i < stakePoolConfigs_.length; i++) {
        rewardsWeightSum_ += stakePoolConfigs_[i].rewardsWeight;

        // New stake pool configs in the array must be sorted and not contain duplicate assets.
        if (
          i > numExistingStakePools_ && address(stakePoolConfigs_[i].asset) <= address(stakePoolConfigs_[i - 1].asset)
        ) return false;
      }

      // The sum of all stake pool rewards weights must be equivalent to a ZOC.
      if (rewardsWeightSum_ != MathConstants.ZOC) return false;
    }

    // Loosely validate drip models.
    for (uint256 i = 0; i < rewardPoolConfigs_.length; i++) {
      rewardPoolConfigs_[i].dripModel.dripFactor(block.timestamp, 0);
    }

    return true;
  }

  // @notice Execute config update to the rewards manager.
  /// @param stakePools_ The array of existing stake pools.
  /// @param rewardPools_ The array of existing reward pools.
  /// @param assetToStakePoolIds_ The mapping of asset to stake pool IDs index lookups.
  /// @param stkReceiptTokenToStakePoolIds_ The mapping of stkReceiptToken to stake pool IDs index lookups.
  /// @param receiptTokenFactory_ The receipt token factory.
  /// @param stakePoolConfigs_ The array of stake pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_ The array of reward pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param allowedStakePools_ The maximum number of allowed stake pools.
  /// @param allowedRewardPools_ The maximum number of allowed reward pools.
  function updateConfigs(
    StakePool[] storage stakePools_,
    RewardPool[] storage rewardPools_,
    mapping(IERC20 => IdLookup) storage assetToStakePoolIds_,
    mapping(IReceiptToken => IdLookup) storage stkReceiptTokenToStakePoolIds_,
    IReceiptTokenFactory receiptTokenFactory_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    uint16 allowedStakePools_,
    uint16 allowedRewardPools_
  ) internal {
    if (
      !isValidUpdate(
        stakePools_,
        rewardPools_,
        assetToStakePoolIds_,
        stakePoolConfigs_,
        rewardPoolConfigs_,
        allowedStakePools_,
        allowedRewardPools_
      )
    ) revert IConfiguratorErrors.InvalidConfiguration();

    applyConfigUpdates(
      stakePools_,
      rewardPools_,
      assetToStakePoolIds_,
      stkReceiptTokenToStakePoolIds_,
      receiptTokenFactory_,
      stakePoolConfigs_,
      rewardPoolConfigs_
    );
  }

  /// @notice Apply config updates to the rewards manager's stake and reward pools.
  /// @param stakePools_ The array of existing stake pools.
  /// @param rewardPools_ The array of existing reward pools.
  /// @param assetToStakePoolIds_ The mapping of asset to stake pool IDs index lookups.
  /// @param stkReceiptTokenToStakePoolIds_ The mapping of stkReceiptToken to stake pool IDs index lookups.
  /// @param receiptTokenFactory_ The receipt token factory.
  /// @param stakePoolConfigs_ The array of stake pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_ The array of reward pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  function applyConfigUpdates(
    StakePool[] storage stakePools_,
    RewardPool[] storage rewardPools_,
    mapping(IERC20 => IdLookup) storage assetToStakePoolIds_,
    mapping(IReceiptToken => IdLookup) storage stkReceiptTokenToStakePoolIds_,
    IReceiptTokenFactory receiptTokenFactory_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_
  ) internal {
    // Update existing stake pool weights. No need to update the stake pool asset since it cannot change.
    uint16 numExistingStakePools_ = uint16(stakePools_.length);
    for (uint16 i = 0; i < numExistingStakePools_; i++) {
      stakePools_[i].rewardsWeight = stakePoolConfigs_[i].rewardsWeight;
    }

    // Initialize new stake pools.
    for (uint16 i = numExistingStakePools_; i < stakePoolConfigs_.length; i++) {
      initializeStakePool(
        stakePools_, assetToStakePoolIds_, stkReceiptTokenToStakePoolIds_, receiptTokenFactory_, stakePoolConfigs_[i], i
      );
    }

    // Update existing reward pool drip models. No need to update the reward pool asset since it cannot change.
    uint16 numExistingRewardPools_ = uint16(rewardPools_.length);
    for (uint16 i = 0; i < numExistingRewardPools_; i++) {
      rewardPools_[i].dripModel = rewardPoolConfigs_[i].dripModel;
    }

    // Initialize new reward pools.
    for (uint16 i = numExistingRewardPools_; i < rewardPoolConfigs_.length; i++) {
      initializeRewardPool(rewardPools_, receiptTokenFactory_, rewardPoolConfigs_[i], i);
    }

    emit IConfiguratorEvents.ConfigUpdatesApplied(stakePoolConfigs_, rewardPoolConfigs_);
  }

  /// @notice Initializes a new stake pool when it is added to the rewards manager.
  /// @param stakePools_ The array of existing stake pools.
  /// @param assetToStakePoolIds_ The mapping of asset to stake pool IDs index lookups.
  /// @param stkReceiptTokenToStakePoolIds_ The mapping of stkReceiptToken to stake pool IDs index lookups.
  /// @param receiptTokenFactory_ The receipt token factory.
  /// @param stakePoolConfig_ The stake pool config.
  /// @param stakePoolId_ The ID of the stake pool.
  function initializeStakePool(
    StakePool[] storage stakePools_,
    mapping(IERC20 => IdLookup) storage assetToStakePoolIds_,
    mapping(IReceiptToken stkReceiptToken_ => IdLookup stakePoolId_) storage stkReceiptTokenToStakePoolIds_,
    IReceiptTokenFactory receiptTokenFactory_,
    StakePoolConfig calldata stakePoolConfig_,
    uint16 stakePoolId_
  ) internal {
    IReceiptToken stkReceiptToken_ = receiptTokenFactory_.deployReceiptToken(
      stakePoolId_, IReceiptTokenFactory.PoolType.STAKE, stakePoolConfig_.asset.decimals()
    );
    stakePools_.push(
      StakePool({
        amount: 0,
        asset: stakePoolConfig_.asset,
        stkReceiptToken: stkReceiptToken_,
        rewardsWeight: stakePoolConfig_.rewardsWeight
      })
    );
    stkReceiptTokenToStakePoolIds_[stkReceiptToken_] = IdLookup({index: stakePoolId_, exists: true});
    assetToStakePoolIds_[stakePoolConfig_.asset] = IdLookup({index: stakePoolId_, exists: true});

    emit IConfiguratorEvents.StakePoolCreated(stakePoolId_, stkReceiptToken_, stakePoolConfig_.asset);
  }

  /// @notice Initializes a new reward pool when it is added to the rewards manager.
  /// @param rewardPools_ The array of existing reward pools.
  /// @param receiptTokenFactory_ The receipt token factory.
  /// @param rewardPoolConfig_ The reward pool config.
  /// @param rewardPoolId_ The ID of the reward pool.
  function initializeRewardPool(
    RewardPool[] storage rewardPools_,
    IReceiptTokenFactory receiptTokenFactory_,
    RewardPoolConfig calldata rewardPoolConfig_,
    uint16 rewardPoolId_
  ) internal {
    IReceiptToken rewardDepositReceiptToken_ = receiptTokenFactory_.deployReceiptToken(
      rewardPoolId_, IReceiptTokenFactory.PoolType.REWARD, rewardPoolConfig_.asset.decimals()
    );

    rewardPools_.push(
      RewardPool({
        asset: rewardPoolConfig_.asset,
        undrippedRewards: 0,
        cumulativeDrippedRewards: 0,
        dripModel: rewardPoolConfig_.dripModel,
        depositReceiptToken: rewardDepositReceiptToken_,
        lastDripTime: uint128(block.timestamp)
      })
    );

    emit IConfiguratorEvents.RewardPoolCreated(rewardPoolId_, rewardDepositReceiptToken_, rewardPoolConfig_.asset);
  }
}

// src/interfaces/ICozyManager.sol

interface ICozyManager is IGovernable {
  /// @notice Cozy protocol RewardsManagerFactory.
  function rewardsManagerFactory() external view returns (IRewardsManagerFactory rewardsManagerFactory_);

  /// @notice Batch pauses rewardsManagers_. The manager's pauser or owner can perform this action.
  /// @param rewardsManagers_ The array of rewards managers to pause.
  function pause(IRewardsManager[] calldata rewardsManagers_) external;

  /// @notice Batch unpauses rewardsManagers_. The manager's owner can perform this action.
  /// @param rewardsManagers_ The array of rewards managers to unpause.
  function unpause(IRewardsManager[] calldata rewardsManagers_) external;

  /// @notice Deploys a new Rewards Manager with the provided parameters.
  /// @param owner_ The owner of the rewards manager.
  /// @param pauser_ The pauser of the rewards manager.
  /// @param stakePoolConfigs_ The array of stake pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_  The array of reward pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param salt_ Used to compute the resulting address of the rewards manager.
  /// @return rewardsManager_ The newly created rewards manager.
  function createRewardsManager(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    bytes32 salt_
  ) external returns (IRewardsManager rewardsManager_);

  /// @notice Given a `caller_` and `salt_`, compute and return the address of the RewardsManager deployed with
  /// `createRewardsManager`.
  /// @param caller_ The caller of the `createRewardsManager` function.
  /// @param salt_ Used to compute the resulting address of the rewards manager along with `caller_`.
  function computeRewardsManagerAddress(address caller_, bytes32 salt_) external view returns (address);
}

// src/interfaces/IRewardsManager.sol

interface IRewardsManager {
  function allowedRewardPools() external view returns (uint16);

  function allowedStakePools() external view returns (uint16);

  function assetPools(IERC20 asset_) external view returns (AssetPool memory);

  function claimableRewards(uint16 stakePoolId_, uint16 rewardPoolId_)
    external
    view
    returns (ClaimableRewardsData memory);

  function claimRewards(uint16 stakePoolId_, address receiver_) external;

  function convertRewardAssetToReceiptTokenAmount(uint16 rewardPoolId_, uint256 rewardAssetAmount_)
    external
    view
    returns (uint256 depositReceiptTokenAmount_);

  function cozyManager() external returns (ICozyManager);

  function depositRewardAssets(uint16 rewardPoolId_, uint256 rewardAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);

  function depositRewardAssetsWithoutTransfer(uint16 rewardPoolId_, uint256 rewardAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_);

  function dripRewardPool(uint16 rewardPoolId_) external;

  function dripRewards() external;

  function getClaimableRewards() external view returns (ClaimableRewardsData[][] memory);

  function getClaimableRewards(uint16 stakePoolId_) external view returns (ClaimableRewardsData[] memory);

  function getRewardPools() external view returns (RewardPool[] memory);

  function getStakePools() external view returns (StakePool[] memory);

  function getUserRewards(uint16 stakePoolId_, address user) external view returns (UserRewardsData[] memory);

  function initialize(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_
  ) external;

  function owner() external view returns (address);

  function pause() external;

  function pauser() external view returns (address);

  function previewClaimableRewards(uint16[] calldata stakePoolIds_, address owner_)
    external
    view
    returns (PreviewClaimableRewards[] memory);

  function previewUndrippedRewardsRedemption(uint16 rewardPoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 rewardAssetAmount_);

  function redeemUndrippedRewards(
    uint16 rewardPoolId_,
    uint256 depositReceiptTokenAmount_,
    address receiver_,
    address owner_
  ) external returns (uint256 rewardAssetAmount_);

  function receiptTokenFactory() external view returns (address);

  function rewardPools(uint256 id_) external view returns (RewardPool memory);

  function rewardsManagerState() external view returns (RewardsManagerState);

  function stake(uint16 stakePoolId_, uint256 assetAmount_, address receiver_) external;

  function stakePools(uint256 id_) external view returns (StakePool memory);

  function stakeWithoutTransfer(uint16 stakePoolId_, uint256 assetAmount_, address receiver_) external;

  function unpause() external;

  function updateConfigs(StakePoolConfig[] calldata stakePoolConfigs_, RewardPoolConfig[] calldata rewardPoolConfigs_)
    external;

  function unstake(uint16 stakePoolId_, uint256 stkReceiptTokenAmount_, address receiver_, address owner_) external;

  function updateUserRewardsForStkReceiptTokenTransfer(address from_, address to_) external;
}

// src/interfaces/IRewardsManagerFactory.sol

interface IRewardsManagerFactory {
  /// @dev Emitted when a new Rewards Manager is deployed.
  /// @param rewardsManager The deployed rewards manager.
  event RewardsManagerDeployed(IRewardsManager rewardsManager);

  /// @notice Address of the Rewards Manager logic contract used to deploy new reward managers.
  function rewardsManagerLogic() external view returns (IRewardsManager);

  /// @notice Creates a new Rewards Manager contract with the specified configuration.
  /// @param owner_ The owner of the rewards manager.
  /// @param pauser_ The pauser of the rewards manager.
  /// @param stakePoolConfigs_ The configuration for the stake pools. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_ The configuration for the reward pools. These configs must obey requirements described
  /// in `Configurator.updateConfigs`.
  /// @param baseSalt_ Used to compute the resulting address of the rewards manager.
  /// @return rewardsManager_ The deployed rewards manager.
  function deployRewardsManager(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_,
    bytes32 baseSalt_
  ) external returns (IRewardsManager rewardsManager_);

  /// @notice Given the `baseSalt_` compute and return the address that Rewards Manager will be deployed to.
  /// @dev Rewards Manager addresses are uniquely determined by their salt because the deployer is always the factory,
  /// and the use of minimal proxies means they all have identical bytecode and therefore an identical bytecode hash.
  /// @dev The `baseSalt_` is the user-provided salt, not the final salt after hashing with the chain ID.
  /// @param baseSalt_ The user-provided salt.
  /// @return The resulting address of the rewards manager.
  function computeAddress(bytes32 baseSalt_) external view returns (address);

  /// @notice Given the `baseSalt_`, return the salt that will be used for deployment.
  /// @param baseSalt_ The user-provided salt.
  /// @return The resulting salt that will be used for deployment.
  function salt(bytes32 baseSalt_) external view returns (bytes32);
}

// src/lib/RewardsManagerBaseStorage.sol

abstract contract RewardsManagerBaseStorage {
  /// @notice Address of the Cozy protocol manager.
  ICozyManager public immutable cozyManager;

  /// @notice Address of the receipt token factory.
  IReceiptTokenFactory public immutable receiptTokenFactory;

  /// @notice The reward manager's stake pools.
  /// @dev Stake pool index in this array is its ID.
  StakePool[] public stakePools;

  /// @notice The reward manager's reward pools.
  /// @dev Reward pool index in this array is its ID.
  RewardPool[] public rewardPools;

  /// @notice Maps an asset to its asset pool.
  /// @dev Used for doing aggregate accounting of stake/reward assets.
  mapping(IERC20 asset_ => AssetPool assetPool_) public assetPools;

  /// @notice Maps a stake pool id to an reward pool id to claimable rewards data.
  mapping(uint16 => mapping(uint16 => ClaimableRewardsData)) public claimableRewards;

  /// @notice Maps a stake pool id to a user address to an array of user rewards data.
  mapping(uint16 => mapping(address => UserRewardsData[])) public userRewards;

  /// @notice Maps a stake receipt token to an index lookup for its stake pool id.
  /// @dev Used for authorization check when transferring stkReceiptTokens.
  mapping(IReceiptToken stkReceiptToken_ => IdLookup stakePoolId_) public stkReceiptTokenToStakePoolIds;

  /// @notice Maps an asset to an index lookup for its stake pool id.
  /// @dev Used for checking that new stake pools have unique underlying assets in config updates.
  mapping(IERC20 asset_ => IdLookup stakePoolId_) public assetToStakePoolIds;

  /// @dev True if the rewards manager has been initialized.
  bool public initialized;

  /// @notice The state of this rewards manager.
  RewardsManagerState public rewardsManagerState;

  /// @notice The max number of stake pools allowed per rewards manager.
  uint16 public immutable allowedStakePools;

  /// @notice The max number of reward pools allowed per rewards manager.
  uint16 public immutable allowedRewardPools;
}

// src/lib/RewardsManagerCommon.sol

abstract contract RewardsManagerCommon is RewardsManagerBaseStorage, ICommonErrors {
  /// @dev Defined in RewardsDistributor.
  function _claimRewards(ClaimRewardsArgs memory args_) internal virtual;

  /// @dev Defined in RewardsDistributor.
  function dripRewards() public virtual;

  /// @notice The pool amount for the purposes of performing conversions. We set a floor once reward
  /// deposit receipt tokens have been initialized to avoid divide-by-zero errors that would occur when the supply
  /// of reward deposit receipt tokens > 0, but the `poolAmount` = 0, which can occur due to drip.
  /// @dev Defined in RewardsManagerInspector.
  function _poolAmountWithFloor(uint256 poolAmount_) internal pure virtual returns (uint256);

  /// @notice Helper to assert that the rewards manager has a balance of tokens that matches the required amount for a
  /// deposit/stake.
  /// @dev Defined in Depositor.
  function _assertValidDepositBalance(IERC20 token_, uint256 tokenPoolBalance_, uint256 depositAmount_)
    internal
    view
    virtual;

  /// @notice Returns the next amount of rewards/fees to be dripped given a base amount, drip model and last drip time.
  /// @dev Defined in RewardsDistributor.
  function _getNextDripAmount(uint256 totalBaseAmount_, IDripModel dripModel_, uint256 lastDripTime_)
    internal
    view
    virtual
    returns (uint256);

  /// @notice Compute the next amount of rewards/fees to be dripped given a base amount and a drip factor.
  /// @dev Defined in RewardsDistributor.
  function _computeNextDripAmount(uint256 totalBaseAmount_, uint256 dripFactor_)
    internal
    view
    virtual
    returns (uint256);

  /// @dev Defined in RewardsDistributor.
  function _updateUserRewards(
    uint256 userStkReceiptTokenBalance_,
    mapping(uint16 => ClaimableRewardsData) storage claimableRewards_,
    UserRewardsData[] storage userRewards_
  ) internal virtual;

  /// @dev Defined in RewardsDistributor.
  function _dripRewardPool(RewardPool storage rewardPool_) internal virtual;

  /// @dev Defined in RewardsDistributor.
  function _dripAndApplyPendingDrippedRewards(
    StakePool storage stakePool_,
    mapping(uint16 => ClaimableRewardsData) storage claimableRewards_
  ) internal virtual;

  /// @dev Defined in RewardsDistributor.
  function _dripAndResetCumulativeRewardsValues(StakePool[] storage stakePools_, RewardPool[] storage rewardPools_)
    internal
    virtual;
}

// src/lib/RewardsManagerInspector.sol

abstract contract RewardsManagerInspector is RewardsManagerCommon {
  uint256 internal constant POOL_AMOUNT_FLOOR = 1;

  /// @notice Converts a reward pool's reward asset amount to the corresponding reward deposit receipt token amount.
  /// @param rewardPoolId_ The ID of the reward pool.
  /// @param rewardAssetAmount_ The amount of the reward pool's asset to convert.
  /// @return depositReceiptTokenAmount_ The corresponding amount of deposit receipt tokens.
  function convertRewardAssetToReceiptTokenAmount(uint16 rewardPoolId_, uint256 rewardAssetAmount_)
    external
    view
    returns (uint256 depositReceiptTokenAmount_)
  {
    RewardPool storage rewardPool_ = rewardPools[rewardPoolId_];
    depositReceiptTokenAmount_ = RewardsManagerCalculationsLib.convertToReceiptTokenAmount(
      rewardAssetAmount_,
      rewardPool_.depositReceiptToken.totalSupply(),
      /// We set a floor to avoid divide-by-zero errors that would occur when the supply of deposit receipt tokens >
      /// 0, but the `poolAmount` == 0, which can occur due to drip.
      _poolAmountWithFloor(rewardPool_.undrippedRewards)
    );
  }

  /// @notice Converts a reward pool's reward deposit receipt token amount to the corresponding reward asset amount.
  /// @param rewardPoolId_ The ID of the reward pool.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to convert.
  /// @return rewardAssetAmount_ The corresponding amount of the reward pool's asset.
  function convertRewardReceiptTokenToAssetAmount(uint16 rewardPoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 rewardAssetAmount_)
  {
    RewardPool storage rewardPool_ = rewardPools[rewardPoolId_];
    rewardAssetAmount_ = RewardsManagerCalculationsLib.convertToAssetAmount(
      depositReceiptTokenAmount_,
      rewardPool_.depositReceiptToken.totalSupply(),
      // We set a floor to avoid divide-by-zero errors that would occur when the supply of depositReceiptTokens >
      // 0, but the `poolAmount` == 0, which can occur due to drip.
      _poolAmountWithFloor(rewardPool_.undrippedRewards)
    );
  }

  /// @notice Returns the reward manager's stake pools.
  /// @return stakePools_ The stake pools.
  function getStakePools() external view returns (StakePool[] memory) {
    return stakePools;
  }

  /// @notice Returns the reward manager's reward pools.
  /// @return rewardPools_ The reward pools.
  function getRewardPools() external view returns (RewardPool[] memory) {
    return rewardPools;
  }

  /// @notice Returns the rewards for a user in a stake pool.
  /// @param stakePoolId_ The ID of the stake pool.
  /// @param user The user's address.
  /// @return userRewards_ The array of user rewards data.
  function getUserRewards(uint16 stakePoolId_, address user) external view returns (UserRewardsData[] memory) {
    return userRewards[stakePoolId_][user];
  }

  /// @notice Returns all claimable rewards for all stake pools and reward pools.
  /// @return claimableRewards_ The claimable rewards data.
  function getClaimableRewards() external view returns (ClaimableRewardsData[][] memory) {
    uint256 numStakePools_ = stakePools.length;
    uint256 numRewardPools_ = rewardPools.length;

    ClaimableRewardsData[][] memory claimableRewards_ = new ClaimableRewardsData[][](numStakePools_);
    for (uint16 i = 0; i < numStakePools_; i++) {
      claimableRewards_[i] = new ClaimableRewardsData[](numRewardPools_);
      mapping(uint16 => ClaimableRewardsData) storage stakePoolClaimableRewards_ = claimableRewards[i];
      for (uint16 j = 0; j < numRewardPools_; j++) {
        claimableRewards_[i][j] = stakePoolClaimableRewards_[j];
      }
    }

    return claimableRewards_;
  }

  /// @notice Returns all claimable rewards for a given stake pool.
  /// @param stakePoolId_ The ID of the stake pool.
  /// @return claimableRewards_ The claimable rewards data.
  function getClaimableRewards(uint16 stakePoolId_) external view returns (ClaimableRewardsData[] memory) {
    mapping(uint16 => ClaimableRewardsData) storage stakePoolClaimableRewards_ = claimableRewards[stakePoolId_];

    uint256 numRewardPools_ = rewardPools.length;
    ClaimableRewardsData[] memory claimableRewards_ = new ClaimableRewardsData[](numRewardPools_);
    for (uint16 i = 0; i < numRewardPools_; i++) {
      claimableRewards_[i] = stakePoolClaimableRewards_[i];
    }

    return claimableRewards_;
  }

  /// @notice The pool amount for the purposes of performing conversions. We set a floor once reward
  /// deposit receipt tokens have been initialized to avoid divide-by-zero errors that would occur when the supply
  /// of reward deposit receipt tokens > 0, but the `poolAmount` = 0, which can occur due to drip.
  function _poolAmountWithFloor(uint256 poolAmount_) internal pure override returns (uint256) {
    return poolAmount_ > POOL_AMOUNT_FLOOR ? poolAmount_ : POOL_AMOUNT_FLOOR;
  }
}

// src/lib/StateChanger.sol

abstract contract StateChanger is RewardsManagerCommon, Governable, IStateChangerEvents {
  /// @notice Pause the rewards manager.
  /// @dev Only the owner, pauser, or Cozy manager can pause the rewards manager.
  function pause() external {
    if (msg.sender != owner && msg.sender != pauser && msg.sender != address(cozyManager)) revert Unauthorized();
    if (rewardsManagerState == RewardsManagerState.PAUSED) revert InvalidStateTransition();

    // Drip rewards before pausing.
    dripRewards();
    rewardsManagerState = RewardsManagerState.PAUSED;
    emit RewardsManagerStateUpdated(RewardsManagerState.PAUSED);
  }

  /// @notice Unpause the rewards manager.
  /// @dev Only the owner or Cozy manager can unpause the rewards manager.
  function unpause() external {
    if (msg.sender != owner && msg.sender != address(cozyManager)) revert Unauthorized();
    if (rewardsManagerState == RewardsManagerState.ACTIVE) revert InvalidStateTransition();

    rewardsManagerState = RewardsManagerState.ACTIVE;
    // Drip rewards after unpausing.
    dripRewards();
    emit RewardsManagerStateUpdated(RewardsManagerState.ACTIVE);
  }
}

// src/lib/Staker.sol

abstract contract Staker is RewardsManagerCommon {
  using SafeERC20 for IERC20;

  /// @notice Emitted when a user stakes.
  /// @param caller_ The address that called the stake function.
  /// @param receiver_ The address that received the stkReceiptTokens.
  /// @param stakePoolId_ The stake pool ID that the user staked in.
  /// @param stkReceiptToken_ The stkReceiptToken that was minted.
  /// @param assetAmount_ The amount of the underlying asset staked.
  event Staked(
    address indexed caller_,
    address indexed receiver_,
    uint16 indexed stakePoolId_,
    IReceiptToken stkReceiptToken_,
    uint256 assetAmount_
  );

  /// @notice Emitted when a user unstakes.
  /// @param caller_ The address that called the unstake function.
  /// @param receiver_ The address that received the unstaked assets.
  /// @param owner_ The owner of the stkReceiptTokens being unstaked.
  /// @param stakePoolId_ The stake pool ID that the user unstaked from.
  /// @param stkReceiptToken_ The stkReceiptToken that was burned.
  /// @param stkReceiptTokenAmount_ The amount of stkReceiptTokens burned.
  event Unstaked(
    address caller_,
    address indexed receiver_,
    address indexed owner_,
    uint16 indexed stakePoolId_,
    IReceiptToken stkReceiptToken_,
    uint256 stkReceiptTokenAmount_
  );

  /// @notice Stake by minting `assetAmount_` stkReceiptTokens to `receiver_` after depositing exactly `assetAmount_` of
  /// `stakePoolId_` stake pool asset.
  /// @dev Assumes that `msg.sender` has already approved this contract to transfer `assetAmount_` of the `stakePoolId_`
  /// stake pool asset.
  /// @param stakePoolId_ The ID of the stake pool to stake in.
  /// @param assetAmount_ The amount of the underlying asset to stake.
  /// @param receiver_ The address that will receive the stkReceiptTokens.
  function stake(uint16 stakePoolId_, uint256 assetAmount_, address receiver_) external {
    if (assetAmount_ == 0) revert AmountIsZero();

    StakePool storage stakePool_ = stakePools[stakePoolId_];
    IERC20 asset_ = stakePool_.asset;
    AssetPool storage assetPool_ = assetPools[asset_];

    // Pull in stake assets. After the transfer we ensure we no longer need any assets. This check is
    // required to support fee on transfer tokens, for example if USDT enables a fee.
    // Also, we need to transfer before minting or ERC777s could reenter.
    asset_.safeTransferFrom(msg.sender, address(this), assetAmount_);
    _assertValidDepositBalance(asset_, assetPool_.amount, assetAmount_);

    _executeStake(stakePoolId_, assetAmount_, receiver_, assetPool_, stakePool_);
  }

  /// @notice Stake by minting `assetAmount_` stkReceiptTokens to `receiver_`.
  /// @dev Assumes that `assetAmount_` of `stakePoolId_` stake pool asset has already been transferred to this rewards
  /// manager contract.
  /// @param stakePoolId_ The ID of the stake pool to stake in.
  /// @param assetAmount_ The amount of the underlying asset to stake.
  /// @param receiver_ The address that will receive the stkReceiptTokens.
  function stakeWithoutTransfer(uint16 stakePoolId_, uint256 assetAmount_, address receiver_) external {
    if (assetAmount_ == 0) revert AmountIsZero();

    StakePool storage stakePool_ = stakePools[stakePoolId_];
    IERC20 asset_ = stakePool_.asset;
    AssetPool storage assetPool_ = assetPools[asset_];

    _assertValidDepositBalance(asset_, assetPool_.amount, assetAmount_);

    _executeStake(stakePoolId_, assetAmount_, receiver_, assetPool_, stakePool_);
  }

  /// @notice Unstakes by burning `stkReceiptTokenAmount_` of `stakePoolId_` stake pool stake receipt tokens and
  /// sending `stkReceiptTokenAmount_` of `stakePoolId_` stake pool asset to `receiver_`. Also, claims ALL outstanding
  /// user rewards and sends them to `receiver_`.
  /// @dev Assumes that user has approved this rewards manager to spend its stkReceiptTokens.
  /// @dev The `receiver_` is transferred ALL claimable rewards of the `owner_`, not just those associated with the
  /// input amount, `stkReceiptTokenAmount_`.
  /// @param stakePoolId_ The ID of the stake pool to unstake from.
  /// @param stkReceiptTokenAmount_ The amount of stkReceiptTokens to unstake.
  /// @param receiver_ The address that will receive the unstaked assets.
  /// @param owner_ The owner of the stkReceiptTokens being unstaked.
  function unstake(uint16 stakePoolId_, uint256 stkReceiptTokenAmount_, address receiver_, address owner_) external {
    if (stkReceiptTokenAmount_ == 0) revert AmountIsZero();

    _claimRewards(ClaimRewardsArgs(stakePoolId_, receiver_, owner_));

    StakePool storage stakePool_ = stakePools[stakePoolId_];
    IReceiptToken stkReceiptToken_ = stakePool_.stkReceiptToken;
    IERC20 asset_ = stakePool_.asset;

    // Given the 1:1 conversion rate between the underlying asset and stkReceiptTokens, we always have `assetAmount_ ==
    // stkReceiptTokenAmount_`.
    stakePool_.amount -= stkReceiptTokenAmount_;
    assetPools[asset_].amount -= stkReceiptTokenAmount_;
    // Burn also ensures that the sender has sufficient allowance if they're not the owner.
    stkReceiptToken_.burn(msg.sender, owner_, stkReceiptTokenAmount_);

    asset_.safeTransfer(receiver_, stkReceiptTokenAmount_);

    emit Unstaked(msg.sender, receiver_, owner_, stakePoolId_, stkReceiptToken_, stkReceiptTokenAmount_);
  }

  function _executeStake(
    uint16 stakePoolId_,
    uint256 assetAmount_,
    address receiver_,
    AssetPool storage assetPool_,
    StakePool storage stakePool_
  ) internal {
    if (rewardsManagerState == RewardsManagerState.PAUSED) revert InvalidState();

    // Given the 1:1 conversion rate between the underlying asset and stkReceiptTokens, we always have `assetAmount_ ==
    // stkReceiptTokenAmount_`.
    stakePool_.amount += assetAmount_;
    assetPool_.amount += assetAmount_;

    // Update user rewards before minting any new stkReceiptTokens.
    IReceiptToken stkReceiptToken_ = stakePool_.stkReceiptToken;
    mapping(uint16 => ClaimableRewardsData) storage claimableRewards_ = claimableRewards[stakePoolId_];
    _dripAndApplyPendingDrippedRewards(stakePool_, claimableRewards_);
    _updateUserRewards(stkReceiptToken_.balanceOf(receiver_), claimableRewards_, userRewards[stakePoolId_][receiver_]);

    stkReceiptToken_.mint(receiver_, assetAmount_);
    emit Staked(msg.sender, receiver_, stakePoolId_, stkReceiptToken_, assetAmount_);
  }
}

// src/lib/Configurator.sol

abstract contract Configurator is RewardsManagerCommon, Governable {
  /// @notice Execute config update to the rewards manager.
  /// @param stakePoolConfigs_ The array of new stake pool configs. The array must contain configs for all existing
  /// stake pools sorted by stake pool ID (with potentially updated rewards weights, but the same underlying asset).
  /// Appended to the existing stake pool configs, the array may also include new stake pool configs, which must be
  /// sorted by the underlying asset address and must be unique (i.e., no two stake pools can have the same underlying
  /// asset). The rewards weight of the stake pools must sum to ZOC.
  /// @param rewardPoolConfigs_ The array of new reward pool configs (with potentially updated drip models, but the same
  /// underlying asset). The array must contain configs for all existing reward pools sorted by reward pool ID. Appended
  /// to the existing stake pool configs, the array may also include new reward pool configs.
  function updateConfigs(StakePoolConfig[] calldata stakePoolConfigs_, RewardPoolConfig[] calldata rewardPoolConfigs_)
    external
    onlyOwner
  {
    // A config update may change the rewards weights, which breaks the invariants that used to do claimable rewards
    // accounting. It may no longer hold that:
    //    claimableRewards[stakePoolId][rewardPoolId].cumulativeClaimedRewards <=
    //        rewardPools[rewardPoolId].cumulativeDrippedRewards.mulDivDown(stakePools[stakePoolId].rewardsWeight, ZOC)
    // To mantain the invariant, before applying the update: we drip rewards, update claimable reward indices and
    // reset the cumulative rewards values to 0. This reset is also executed when a config update occurs in the PAUSED
    // state, but in that case, the rewards are not dripped; the rewards are dripped when the rewards manager first
    // transitions to PAUSED.
    _dripAndResetCumulativeRewardsValues(stakePools, rewardPools);

    ConfiguratorLib.updateConfigs(
      stakePools,
      rewardPools,
      assetToStakePoolIds,
      stkReceiptTokenToStakePoolIds,
      receiptTokenFactory,
      stakePoolConfigs_,
      rewardPoolConfigs_,
      allowedStakePools,
      allowedRewardPools
    );
  }

  /// @notice Update pauser to `newPauser_`.
  /// @param newPauser_ The new pauser.
  function updatePauser(address newPauser_) external {
    if (newPauser_ == address(cozyManager)) revert IConfiguratorErrors.InvalidConfiguration();
    _updatePauser(newPauser_);
  }
}

// src/lib/RewardsDistributor.sol

abstract contract RewardsDistributor is RewardsManagerCommon {
  using FixedPointMathLib for uint256;
  using SafeERC20 for IERC20;

  event ClaimedRewards(
    uint16 indexed stakePoolId_,
    uint16 indexed rewardPoolId_,
    IERC20 rewardAsset_,
    uint256 amount_,
    address indexed owner_,
    address receiver_
  );

  struct RewardDrip {
    IERC20 rewardAsset;
    uint256 amount;
  }

  struct ClaimRewardsData {
    uint256 userStkReceiptTokenBalance;
    uint256 stkReceiptTokenSupply;
    uint256 rewardsWeight;
    uint256 numRewardAssets;
    uint256 numUserRewardAssets;
  }

  struct TransferClaimedRewardsArgs {
    uint16 stakePoolId;
    uint16 rewardPoolId;
    IERC20 rewardAsset;
    address owner;
    address receiver;
    uint256 amount;
  }

  /// @notice Drip rewards for all reward pools.
  function dripRewards() public override {
    if (rewardsManagerState == RewardsManagerState.PAUSED) revert InvalidState();
    uint256 numRewardAssets_ = rewardPools.length;
    for (uint16 i = 0; i < numRewardAssets_; i++) {
      _dripRewardPool(rewardPools[i]);
    }
  }

  /// @notice Drip rewards for a specific reward pool.
  /// @param rewardPoolId_ The ID of the reward pool to drip rewards for.
  function dripRewardPool(uint16 rewardPoolId_) external {
    if (rewardsManagerState == RewardsManagerState.PAUSED) revert InvalidState();
    _dripRewardPool(rewardPools[rewardPoolId_]);
  }

  /// @notice Claim rewards for a specific stake pool and transfer rewards to `receiver_`.
  /// @param stakePoolId_ The ID of the stake pool to claim rewards for.
  /// @param receiver_ The address to transfer the claimed rewards to.
  function claimRewards(uint16 stakePoolId_, address receiver_) external {
    _claimRewards(ClaimRewardsArgs(stakePoolId_, receiver_, msg.sender));
  }

  /// @notice Claim rewards for a set of stake pools and transfer rewards to `receiver_`.
  /// @param stakePoolIds_ The IDs of the stake pools to claim rewards for.
  /// @param receiver_ The address to transfer the claimed rewards to.
  function claimRewards(uint16[] calldata stakePoolIds_, address receiver_) external {
    for (uint256 i = 0; i < stakePoolIds_.length; i++) {
      _claimRewards(ClaimRewardsArgs(stakePoolIds_[i], receiver_, msg.sender));
    }
  }

  /// @notice Preview the claimable rewards for a given set of stake pools.
  /// @param stakePoolIds_ The IDs of the stake pools to preview claimable rewards for.
  /// @param owner_ The address of the user to preview claimable rewards for.
  function previewClaimableRewards(uint16[] calldata stakePoolIds_, address owner_)
    external
    view
    returns (PreviewClaimableRewards[] memory previewClaimableRewards_)
  {
    uint256 numRewardAssets_ = rewardPools.length;

    RewardDrip[] memory nextRewardDrips_ = new RewardDrip[](numRewardAssets_);
    for (uint16 i = 0; i < numRewardAssets_; i++) {
      nextRewardDrips_[i] = _previewNextRewardDrip(rewardPools[i]);
    }

    previewClaimableRewards_ = new PreviewClaimableRewards[](stakePoolIds_.length);
    for (uint256 i = 0; i < stakePoolIds_.length; i++) {
      previewClaimableRewards_[i] = _previewClaimableRewards(stakePoolIds_[i], owner_, nextRewardDrips_);
    }
  }

  /// @notice Update the user rewards data to prepare for a transfer of stkReceiptTokens.
  /// @dev stkReceiptTokens are expected to call this before the actual underlying ERC-20 transfer (e.g.
  /// `super.transfer(address to_, uint256 amount_)`). Otherwise, the `from_` user will have accrued less historical
  /// rewards they are entitled to as their new balance is smaller after the transfer. Also, the `to_` user will accure
  /// more historical rewards than they are entitled to as their new balance is larger after the transfer.
  /// @param from_ The address of the user transferring stkReceiptTokens.
  /// @param to_ The address of the user receiving stkReceiptTokens.
  function updateUserRewardsForStkReceiptTokenTransfer(address from_, address to_) external {
    // Check that only a registered stkReceiptToken can call this function.
    IdLookup memory idLookup_ = stkReceiptTokenToStakePoolIds[IReceiptToken(msg.sender)];
    if (!idLookup_.exists) revert Ownable.Unauthorized();

    uint16 stakePoolId_ = idLookup_.index;
    IReceiptToken stkReceiptToken_ = stakePools[stakePoolId_].stkReceiptToken;
    mapping(uint16 => ClaimableRewardsData) storage claimableRewards_ = claimableRewards[stakePoolId_];

    // Fully accure historical rewards for both users given their current stkReceiptToken balances. Moving forward all
    // rewards
    // will accrue based on: (1) the stkReceiptToken balances of the `from_` and `to_` address after the transfer, (2)
    // the
    // current claimable reward index snapshots.
    _updateUserRewards(stkReceiptToken_.balanceOf(from_), claimableRewards_, userRewards[stakePoolId_][from_]);
    _updateUserRewards(stkReceiptToken_.balanceOf(to_), claimableRewards_, userRewards[stakePoolId_][to_]);
  }

  function _dripRewardPool(RewardPool storage rewardPool_) internal override {
    RewardDrip memory rewardDrip_ = _previewNextRewardDrip(rewardPool_);
    if (rewardDrip_.amount > 0) {
      rewardPool_.undrippedRewards -= rewardDrip_.amount;
      rewardPool_.cumulativeDrippedRewards += rewardDrip_.amount;
    }
    rewardPool_.lastDripTime = uint128(block.timestamp);
  }

  function _claimRewards(ClaimRewardsArgs memory args_) internal override {
    StakePool storage stakePool_ = stakePools[args_.stakePoolId];
    IReceiptToken stkReceiptToken_ = stakePool_.stkReceiptToken;
    mapping(uint16 => ClaimableRewardsData) storage claimableRewards_ = claimableRewards[args_.stakePoolId];
    UserRewardsData[] storage userRewards_ = userRewards[args_.stakePoolId][args_.owner];

    ClaimRewardsData memory claimRewardsData_ = ClaimRewardsData({
      userStkReceiptTokenBalance: stkReceiptToken_.balanceOf(args_.owner),
      stkReceiptTokenSupply: stkReceiptToken_.totalSupply(),
      rewardsWeight: stakePool_.rewardsWeight,
      numRewardAssets: rewardPools.length,
      numUserRewardAssets: userRewards_.length
    });

    // When claiming rewards from a given reward pool, we take four steps:
    // (1) Drip from the reward pool since time may have passed since the last drip.
    // (2) Compute and update the next claimable rewards data for the (stake pool, reward pool) pair.
    // (3) Update the user's accrued rewards data for the (stake pool, reward pool) pair.
    // (4) Transfer the user's accrued rewards from the reward pool to the receiver.
    for (uint16 rewardPoolId_ = 0; rewardPoolId_ < claimRewardsData_.numRewardAssets; rewardPoolId_++) {
      // Step (1)
      RewardPool storage rewardPool_ = rewardPools[rewardPoolId_];
      if (rewardsManagerState == RewardsManagerState.ACTIVE) _dripRewardPool(rewardPool_);

      {
        // Step (2)
        ClaimableRewardsData memory newClaimableRewardsData_ = _previewNextClaimableRewardsData(
          claimableRewards_[rewardPoolId_],
          rewardPool_.cumulativeDrippedRewards,
          claimRewardsData_.stkReceiptTokenSupply,
          claimRewardsData_.rewardsWeight
        );
        claimableRewards_[rewardPoolId_] = newClaimableRewardsData_;

        // Step (3)
        UserRewardsData memory newUserRewardsData_ =
          UserRewardsData({accruedRewards: 0, indexSnapshot: newClaimableRewardsData_.indexSnapshot});
        // A new UserRewardsData struct is pushed to the array in the case a new reward pool was added since rewards
        // were last claimed for this user.
        uint256 oldIndexSnapshot_ = 0;
        uint256 oldAccruedRewards_ = 0;
        if (rewardPoolId_ < claimRewardsData_.numUserRewardAssets) {
          oldIndexSnapshot_ = userRewards_[rewardPoolId_].indexSnapshot;
          oldAccruedRewards_ = userRewards_[rewardPoolId_].accruedRewards;
          userRewards_[rewardPoolId_] = newUserRewardsData_;
        } else {
          userRewards_.push(newUserRewardsData_);
        }

        // Step (4)
        _transferClaimedRewards(
          TransferClaimedRewardsArgs(
            args_.stakePoolId,
            rewardPoolId_,
            rewardPool_.asset,
            args_.owner,
            args_.receiver,
            oldAccruedRewards_
              + _getUserAccruedRewards(
                claimRewardsData_.userStkReceiptTokenBalance, newClaimableRewardsData_.indexSnapshot, oldIndexSnapshot_
              )
          )
        );
      }
    }
  }

  function _previewNextClaimableRewardsData(
    ClaimableRewardsData memory claimableRewardsData_,
    uint256 cumulativeDrippedRewards_,
    uint256 stkReceiptTokenSupply_,
    uint256 rewardsWeight_
  ) internal pure returns (ClaimableRewardsData memory nextClaimableRewardsData_) {
    nextClaimableRewardsData_.cumulativeClaimableRewards = claimableRewardsData_.cumulativeClaimableRewards;
    nextClaimableRewardsData_.indexSnapshot = claimableRewardsData_.indexSnapshot;
    // If `stkReceiptTokenSupply_ == 0`, then we get a divide by zero error if we try to update the index snapshot. To
    // avoid this, we wait until the `stkReceiptTokenSupply_ > 0`, to apply all accumulated unclaimed dripped rewards to
    // the claimable rewards data. We have to update the index snapshot and cumulative claimed rewards at the same time
    // to keep accounting correct.
    if (stkReceiptTokenSupply_ > 0) {
      // Round down, in favor of leaving assets in the pool.
      uint256 unclaimedDrippedRewards_ = cumulativeDrippedRewards_.mulDivDown(rewardsWeight_, MathConstants.ZOC)
        - claimableRewardsData_.cumulativeClaimableRewards;

      nextClaimableRewardsData_.cumulativeClaimableRewards += unclaimedDrippedRewards_;
      // Round down, in favor of leaving assets in the claimable reward pool.
      nextClaimableRewardsData_.indexSnapshot +=
        unclaimedDrippedRewards_.mulDivDown(MathConstants.WAD ** 2, stkReceiptTokenSupply_);
    }
  }

  function _transferClaimedRewards(TransferClaimedRewardsArgs memory args_) internal {
    if (args_.amount == 0) return;
    assetPools[args_.rewardAsset].amount -= args_.amount;
    args_.rewardAsset.safeTransfer(args_.receiver, args_.amount);
    emit ClaimedRewards(
      args_.stakePoolId, args_.rewardPoolId, args_.rewardAsset, args_.amount, args_.owner, args_.receiver
    );
  }

  function _previewNextRewardDrip(RewardPool storage rewardPool_) internal view returns (RewardDrip memory) {
    return RewardDrip({
      rewardAsset: rewardPool_.asset,
      amount: _getNextDripAmount(rewardPool_.undrippedRewards, rewardPool_.dripModel, rewardPool_.lastDripTime)
    });
  }

  function _previewClaimableRewards(uint16 stakePoolId_, address owner_, RewardDrip[] memory nextRewardDrips_)
    internal
    view
    returns (PreviewClaimableRewards memory)
  {
    StakePool storage stakePool_ = stakePools[stakePoolId_];
    IReceiptToken stkReceiptToken_ = stakePool_.stkReceiptToken;
    uint256 stkReceiptTokenSupply_ = stkReceiptToken_.totalSupply();
    uint256 ownerStkReceiptTokenBalance_ = stkReceiptToken_.balanceOf(owner_);
    uint256 rewardsWeight_ = stakePool_.rewardsWeight;

    // Compute preview user accrued rewards accounting for any pending rewards drips.
    PreviewClaimableRewardsData[] memory claimableRewardsData_ =
      new PreviewClaimableRewardsData[](nextRewardDrips_.length);
    mapping(uint16 => ClaimableRewardsData) storage claimableRewards_ = claimableRewards[stakePoolId_];
    UserRewardsData[] storage userRewards_ = userRewards[stakePoolId_][owner_];
    uint256 numUserRewardAssets_ = userRewards[stakePoolId_][owner_].length;

    for (uint16 i = 0; i < nextRewardDrips_.length; i++) {
      RewardPool storage rewardPool_ = rewardPools[i];
      ClaimableRewardsData memory previewNextClaimableRewardsData_ = _previewNextClaimableRewardsData(
        claimableRewards_[i],
        rewardPool_.cumulativeDrippedRewards + nextRewardDrips_[i].amount,
        stkReceiptTokenSupply_,
        rewardsWeight_
      );
      claimableRewardsData_[i] = PreviewClaimableRewardsData({
        rewardPoolId: i,
        asset: nextRewardDrips_[i].rewardAsset,
        amount: i < numUserRewardAssets_
          ? _previewUpdateUserRewardsData(
            ownerStkReceiptTokenBalance_, previewNextClaimableRewardsData_.indexSnapshot, userRewards_[i]
          ).accruedRewards
          : _previewAddUserRewardsData(ownerStkReceiptTokenBalance_, previewNextClaimableRewardsData_.indexSnapshot)
            .accruedRewards
      });
    }

    return PreviewClaimableRewards({stakePoolId: stakePoolId_, claimableRewardsData: claimableRewardsData_});
  }

  function _getNextDripAmount(uint256 totalBaseAmount_, IDripModel dripModel_, uint256 lastDripTime_)
    internal
    view
    override
    returns (uint256)
  {
    if (rewardsManagerState == RewardsManagerState.PAUSED) return 0;
    uint256 dripFactor_ = dripModel_.dripFactor(lastDripTime_, totalBaseAmount_);
    if (dripFactor_ > MathConstants.WAD) revert InvalidDripFactor();

    return _computeNextDripAmount(totalBaseAmount_, dripFactor_);
  }

  function _computeNextDripAmount(uint256 totalBaseAmount_, uint256 dripFactor_)
    internal
    pure
    override
    returns (uint256)
  {
    return totalBaseAmount_.mulWadDown(dripFactor_);
  }

  function _dripAndApplyPendingDrippedRewards(
    StakePool storage stakePool_,
    mapping(uint16 => ClaimableRewardsData) storage claimableRewards_
  ) internal override {
    uint256 numRewardAssets_ = rewardPools.length;
    uint256 stkReceiptTokenSupply_ = stakePool_.stkReceiptToken.totalSupply();
    uint256 rewardsWeight_ = stakePool_.rewardsWeight;

    for (uint16 i = 0; i < numRewardAssets_; i++) {
      RewardPool storage rewardPool_ = rewardPools[i];
      _dripRewardPool(rewardPool_);
      ClaimableRewardsData storage claimableRewardsData_ = claimableRewards_[i];

      claimableRewards_[i] = _previewNextClaimableRewardsData(
        claimableRewardsData_, rewardPool_.cumulativeDrippedRewards, stkReceiptTokenSupply_, rewardsWeight_
      );
    }
  }

  /// @dev Drips rewards for all reward pools and resets the cumulative rewards values to 0. This function is only
  /// called on config updates (`Configurator.updateConfigs`), because config updates may change the rewards weights,
  /// which breaks the invariants that used to do claimable rewards accounting.
  function _dripAndResetCumulativeRewardsValues(StakePool[] storage stakePools_, RewardPool[] storage rewardPools_)
    internal
    override
  {
    uint256 numRewardAssets_ = rewardPools_.length;
    uint256 numStakePools_ = stakePools_.length;

    for (uint16 i = 0; i < numRewardAssets_; i++) {
      RewardPool storage rewardPool_ = rewardPools_[i];
      if (rewardsManagerState == RewardsManagerState.ACTIVE) _dripRewardPool(rewardPool_);
      uint256 oldCumulativeDrippedRewards_ = rewardPool_.cumulativeDrippedRewards;
      rewardPool_.cumulativeDrippedRewards = 0;

      for (uint16 j = 0; j < numStakePools_; j++) {
        StakePool storage stakePool_ = stakePools_[j];
        ClaimableRewardsData memory claimableRewardsData_ = _previewNextClaimableRewardsData(
          claimableRewards[j][i],
          oldCumulativeDrippedRewards_,
          stakePool_.stkReceiptToken.totalSupply(),
          stakePool_.rewardsWeight
        );
        claimableRewards[j][i] =
          ClaimableRewardsData({cumulativeClaimableRewards: 0, indexSnapshot: claimableRewardsData_.indexSnapshot});
      }
    }
  }

  function _updateUserRewards(
    uint256 userStkReceiptTokenBalance_,
    mapping(uint16 => ClaimableRewardsData) storage claimableRewards_,
    UserRewardsData[] storage userRewards_
  ) internal override {
    uint256 numRewardAssets_ = rewardPools.length;
    uint256 numUserRewardAssets_ = userRewards_.length;
    for (uint16 i = 0; i < numRewardAssets_; i++) {
      if (i < numUserRewardAssets_) {
        userRewards_[i] = _previewUpdateUserRewardsData(
          userStkReceiptTokenBalance_, claimableRewards_[i].indexSnapshot, userRewards_[i]
        );
      } else {
        userRewards_.push(_previewAddUserRewardsData(userStkReceiptTokenBalance_, claimableRewards_[i].indexSnapshot));
      }
    }
  }

  function _previewUpdateUserRewardsData(
    uint256 userStkReceiptTokenBalance_,
    uint256 newIndexSnapshot_,
    UserRewardsData storage userRewardsData_
  ) internal view returns (UserRewardsData memory newUserRewardsData_) {
    newUserRewardsData_.accruedRewards = userRewardsData_.accruedRewards
      + _getUserAccruedRewards(userStkReceiptTokenBalance_, newIndexSnapshot_, userRewardsData_.indexSnapshot);
    newUserRewardsData_.indexSnapshot = newIndexSnapshot_;
  }

  function _previewAddUserRewardsData(uint256 userStkReceiptTokenBalance_, uint256 newIndexSnapshot_)
    internal
    pure
    returns (UserRewardsData memory newUserRewardsData_)
  {
    newUserRewardsData_.accruedRewards = _getUserAccruedRewards(userStkReceiptTokenBalance_, newIndexSnapshot_, 0);
    newUserRewardsData_.indexSnapshot = newIndexSnapshot_;
  }

  function _getUserAccruedRewards(
    uint256 stkReceiptTokenAmount_,
    uint256 newRewardPoolIndex,
    uint256 oldRewardPoolIndex
  ) internal pure returns (uint256) {
    // Round down, in favor of leaving assets in the rewards pool.
    return stkReceiptTokenAmount_.mulDivDown(newRewardPoolIndex - oldRewardPoolIndex, MathConstants.WAD ** 2);
  }
}

// src/lib/Depositor.sol

abstract contract Depositor is RewardsManagerCommon, IDepositorErrors, IDepositorEvents {
  using SafeERC20 for IERC20;

  /// @notice Deposit `rewardAssetAmount_` assets into the `rewardPoolId_` reward pool on behalf of `from_` and mint
  /// `depositReceiptTokenAmount_` tokens to `receiver_`.
  /// @dev Assumes that `msg.sender` has approved the rewards manager to spend `rewardAssetAmount_` of the reward pool's
  /// asset.
  /// @param rewardPoolId_ The ID of the reward pool.
  /// @param rewardAssetAmount_ The amount of the reward pool's asset to deposit.
  /// @param receiver_ The address to mint the deposit receipt tokens to.
  /// @return depositReceiptTokenAmount_ The amount of deposit receipt tokens minted.
  function depositRewardAssets(uint16 rewardPoolId_, uint256 rewardAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_)
  {
    RewardPool storage rewardPool_ = rewardPools[rewardPoolId_];
    IERC20 asset_ = rewardPool_.asset;

    // Pull in deposited assets. After the transfer we ensure we no longer need any assets. This check is
    // required to support fee on transfer tokens, for example if USDT enables a fee.
    // Also, we need to transfer before minting or ERC777s could reenter.
    asset_.safeTransferFrom(msg.sender, address(this), rewardAssetAmount_);

    depositReceiptTokenAmount_ =
      _executeRewardDeposit(rewardPoolId_, asset_, rewardAssetAmount_, receiver_, rewardPool_);
  }

  /// @notice Deposit `rewardAssetAmount_` assets into the `rewardPoolId_` reward pool and mint
  /// `depositReceiptTokenAmount_` tokens to `receiver_`.
  /// @dev Assumes that the user has already transferred `rewardAssetAmount_` of the reward pool's asset to the rewards
  /// manager.
  /// @param rewardPoolId_ The ID of the reward pool.
  /// @param rewardAssetAmount_ The amount of the reward pool's asset to deposit.
  /// @param receiver_ The address to mint the deposit receipt tokens to.
  /// @return depositReceiptTokenAmount_ The amount of deposit receipt tokens minted.
  function depositRewardAssetsWithoutTransfer(uint16 rewardPoolId_, uint256 rewardAssetAmount_, address receiver_)
    external
    returns (uint256 depositReceiptTokenAmount_)
  {
    RewardPool storage rewardPool_ = rewardPools[rewardPoolId_];
    depositReceiptTokenAmount_ =
      _executeRewardDeposit(rewardPoolId_, rewardPool_.asset, rewardAssetAmount_, receiver_, rewardPool_);
  }

  /// @notice Redeem by burning `depositReceiptTokenAmount_` of `rewardPoolId_` reward pool deposit receipt tokens and
  /// sending `rewardAssetAmount_` of `rewardPoolId_` reward pool assets to `receiver_`. Reward pool assets can only be
  /// redeemed
  /// if they have not been dripped yet.
  /// @dev Assumes that user has approved the rewards manager to spend its deposit receipt tokens.
  /// @param rewardPoolId_ The ID of the reward pool.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to burn.
  /// @param receiver_ The address to send the reward pool's asset to.
  /// @param owner_ The owner of the deposit receipt tokens.
  /// @return rewardAssetAmount_ The amount of the reward pool's asset redeemed.
  function redeemUndrippedRewards(
    uint16 rewardPoolId_,
    uint256 depositReceiptTokenAmount_,
    address receiver_,
    address owner_
  ) external returns (uint256 rewardAssetAmount_) {
    RewardPool storage rewardPool_ = rewardPools[rewardPoolId_];
    if (rewardsManagerState == RewardsManagerState.ACTIVE) _dripRewardPool(rewardPool_);

    IReceiptToken depositReceiptToken_ = rewardPool_.depositReceiptToken;
    rewardAssetAmount_ = _previewRedemption(
      depositReceiptToken_,
      depositReceiptTokenAmount_,
      rewardPool_.dripModel,
      rewardPool_.undrippedRewards,
      rewardPool_.lastDripTime
    );
    if (rewardAssetAmount_ == 0) revert RoundsToZero(); // Check for rounding error since we round down in conversion.

    depositReceiptToken_.burn(msg.sender, owner_, depositReceiptTokenAmount_);

    IERC20 asset_ = rewardPool_.asset;
    rewardPool_.undrippedRewards -= rewardAssetAmount_;
    assetPools[asset_].amount -= rewardAssetAmount_;
    asset_.safeTransfer(receiver_, rewardAssetAmount_);

    emit RedeemedUndrippedRewards(
      msg.sender, receiver_, owner_, rewardPoolId_, depositReceiptToken_, depositReceiptTokenAmount_, rewardAssetAmount_
    );
  }

  /// @notice Preview the amount of undripped rewards that can be redeemed for `depositReceiptTokenAmount_` from a given
  /// reward pool.
  /// @param rewardPoolId_ The ID of the reward pool.
  /// @param depositReceiptTokenAmount_ The amount of deposit receipt tokens to redeem.
  /// @return rewardAssetAmount_ The amount of the reward pool's asset that can be redeemed.
  function previewUndrippedRewardsRedemption(uint16 rewardPoolId_, uint256 depositReceiptTokenAmount_)
    external
    view
    returns (uint256 rewardAssetAmount_)
  {
    RewardPool storage rewardPool_ = rewardPools[rewardPoolId_];

    rewardAssetAmount_ = _previewRedemption(
      rewardPool_.depositReceiptToken,
      depositReceiptTokenAmount_,
      rewardPool_.dripModel,
      rewardPool_.undrippedRewards,
      rewardPool_.lastDripTime
    );
  }

  function _executeRewardDeposit(
    uint16 rewardPoolId_,
    IERC20 token_,
    uint256 rewardAssetAmount_,
    address receiver_,
    RewardPool storage rewardPool_
  ) internal returns (uint256 depositReceiptTokenAmount_) {
    if (rewardsManagerState == RewardsManagerState.PAUSED) revert InvalidState();
    _assertValidDepositBalance(token_, assetPools[token_].amount, rewardAssetAmount_);

    IReceiptToken depositReceiptToken_ = rewardPool_.depositReceiptToken;

    depositReceiptTokenAmount_ = RewardsManagerCalculationsLib.convertToReceiptTokenAmount(
      rewardAssetAmount_, depositReceiptToken_.totalSupply(), _poolAmountWithFloor(rewardPool_.undrippedRewards)
    );
    if (depositReceiptTokenAmount_ == 0) revert RoundsToZero();

    // Increment reward pool accounting only after calculating `depositReceiptTokenAmount_` to mint.
    rewardPool_.undrippedRewards += rewardAssetAmount_;
    assetPools[token_].amount += rewardAssetAmount_;

    depositReceiptToken_.mint(receiver_, depositReceiptTokenAmount_);
    emit Deposited(
      msg.sender, receiver_, rewardPoolId_, depositReceiptToken_, rewardAssetAmount_, depositReceiptTokenAmount_
    );
  }

  function _previewRedemption(
    IReceiptToken receiptToken_,
    uint256 receiptTokenAmount_,
    IDripModel dripModel_,
    uint256 totalPoolAmount_,
    uint256 lastDripTime_
  ) internal view returns (uint256 assetAmount_) {
    uint256 nextDripAmount_ =
      (lastDripTime_ != block.timestamp) ? _getNextDripAmount(totalPoolAmount_, dripModel_, lastDripTime_) : 0;
    uint256 nextTotalPoolAmount_ = totalPoolAmount_ - nextDripAmount_;

    assetAmount_ = nextTotalPoolAmount_ == 0
      ? 0
      : RewardsManagerCalculationsLib.convertToAssetAmount(
        receiptTokenAmount_, receiptToken_.totalSupply(), nextTotalPoolAmount_
      );
  }

  function _assertValidDepositBalance(IERC20 token_, uint256 assetPoolBalance_, uint256 depositAmount_)
    internal
    view
    override
  {
    if (token_.balanceOf(address(this)) - assetPoolBalance_ < depositAmount_) revert InvalidDeposit();
  }
}

// src/RewardsManager.sol

contract RewardsManager is
  RewardsManagerCommon,
  RewardsManagerInspector,
  Configurator,
  Depositor,
  RewardsDistributor,
  Staker,
  StateChanger
{
  /// @notice Thrown if the rewards manager is already initialized.
  error Initialized();

  /// @param cozyManager_ The Cozy protocol manager.
  /// @param receiptTokenFactory_ The Cozy protocol receipt token factory.
  /// @param allowedStakePools_ The number of allowed stake pools.
  /// @param allowedRewardPools_ The number of allowed reward pools.
  constructor(
    ICozyManager cozyManager_,
    IReceiptTokenFactory receiptTokenFactory_,
    uint16 allowedStakePools_,
    uint16 allowedRewardPools_
  ) {
    _assertAddressNotZero(address(cozyManager_));
    _assertAddressNotZero(address(receiptTokenFactory_));
    cozyManager = cozyManager_;
    receiptTokenFactory = receiptTokenFactory_;
    allowedStakePools = allowedStakePools_;
    allowedRewardPools = allowedRewardPools_;
  }

  /// @notice Initializes the rewards manager with the provided parameters.
  /// @param owner_ The owner of the rewards manager.
  /// @param pauser_ The pauser of the rewards manager.
  /// @param stakePoolConfigs_ The array of stake pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  /// @param rewardPoolConfigs_ The array of reward pool configs. These configs must obey requirements described in
  /// `Configurator.updateConfigs`.
  function initialize(
    address owner_,
    address pauser_,
    StakePoolConfig[] calldata stakePoolConfigs_,
    RewardPoolConfig[] calldata rewardPoolConfigs_
  ) external {
    if (initialized) revert Initialized();
    if (
      !ConfiguratorLib.isValidConfiguration(
        stakePoolConfigs_, rewardPoolConfigs_, 0, 0, allowedStakePools, allowedRewardPools
      )
    ) revert IConfiguratorErrors.InvalidConfiguration();

    // Rewards managers are minimal proxies, so the owner and pauser is set to address(0) in the constructor for the
    // logic contract. When the rewards manager is initialized for the minimal proxy, we update the owner and pauser.
    if (pauser_ == address(cozyManager)) revert IConfiguratorErrors.InvalidConfiguration();
    __initGovernable(owner_, pauser_);

    initialized = true;
    ConfiguratorLib.applyConfigUpdates(
      stakePools,
      rewardPools,
      assetToStakePoolIds,
      stkReceiptTokenToStakePoolIds,
      receiptTokenFactory,
      stakePoolConfigs_,
      rewardPoolConfigs_
    );
  }
}