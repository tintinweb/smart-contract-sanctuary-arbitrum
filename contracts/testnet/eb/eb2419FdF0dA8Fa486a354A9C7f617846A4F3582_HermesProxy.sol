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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IPool.sol";
import "./IOwnable.sol";
import "./IERC20.sol";

/**
 * @title CRPool definition interface
 *
 * @dev Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
 *      Removing circularity allows flattener tools to work, which enables Etherscan verification
 *      Only contains the definitions of the ConfigurableRigthsPool.sol contract and no parent classes
 */
interface IConfigurableRightsPoolDef {
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
        external
        returns (uint poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    )
        external
        returns (uint tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
        external
        returns (uint tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        returns (uint poolAmountIn);

    function updateWeight(address token, uint newWeight) external;
    function updateWeightsGradually(uint[] calldata newWeights, uint startBlock, uint endBlock) external;
    function pokeWeights() external;
    function commitAddToken(address token, uint balance, uint denormalizedWeight) external;
    function applyAddToken() external;
    function removeToken(address token) external;
    function mintPoolShareFromLib(uint amount) external;
    function pushPoolShareFromLib(address to, uint amount) external;
    function pullPoolShareFromLib(address from, uint amount) external;
    function burnPoolShareFromLib(uint amount) external;

    function newToken() external view returns(
        bool isCommitted,
        address addr,
        uint256 commitBlock,
        uint256 denorm,
        uint256 balance
    );

    function corePool() external view returns(IPool);
}

/**
 * @title CRPool interface for external contracts
 *
 * @dev Joins the CRPool definition and the token and ownable interfaces
 */
interface IConfigurableRightsPool is IConfigurableRightsPoolDef, IOwnable, IERC20 {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/* solhint-disable ordering */

/**
 * @title An ERC20 compatible token interface
 */
interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title Interface for the pure math functions
 *
 * @dev IPool inherits this, so it's only needed if you only want to interact with the Math functions
 */
interface IMath {
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee,
        uint exitFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee,
        uint exitFee
    )
        external pure
        returns (uint poolAmountIn);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMayfairCommunityStore {
    struct PoolInfo {
        address manager;
        uint256 feesToManager;
        uint256 feesToReferral;
        bool isPrivate;
    }

    function setInvestor(
        address poolAddress,
        address investor,
        bool isAproved
    ) external;

    function isTokenWhitelisted(address token) external returns (bool);

    function getPoolInfo(
        address poolAddress
    ) external returns (PoolInfo calldata);

    function getPrivateInvestor(
        address poolAddress,
        address investor
    ) external returns (bool);

    function setWriter(address writer, bool allowance) external;

    function setPrivatePool(address poolAddress, bool isPrivate) external;

    function whitelistToken(address token, bool whitelist) external;

    function setManager(
        address poolAddress,
        address poolCreator,
        uint256 feesToManager,
        uint256 feesToReferral,
        bool isPrivate
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title Ownable.sol interface
 *
 * @dev Other interfaces might inherit this one so it may be unnecessary to use it
 */
interface IOwnable {
    function getController() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMath.sol";

/**
 * @title Core pool definition
 *
 * @dev Only contains the definitions of the Pool.sol contract and no parent classes
 */
interface IPoolDef {
    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    )
        external
        returns (
            uint tokenAmountOut,
            uint spotPriceAfter
        );

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    )
        external
        returns (
            uint tokenAmountIn,
            uint spotPriceAfter
        );

    function setSwapFee(uint swapFee) external;
    function setExitFee(uint exitFee) external;
    function setPublicSwap(bool publicSwap) external;
    function setExitFeeCollector(address feeCollector) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function rebind(address token, uint balance, uint denorm) external;

    function getExitFeeCollector() external view returns (address);
    function isPublicSwap() external view returns (bool);
    function isBound(address token) external view returns(bool);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint);
    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint);
    function getExitFee() external view returns (uint);
}

/**
 * @title Core pool interface for external contracts
 *
 * @dev Joins the Core pool definition and the Math abstract contract
 */
interface IPool is IPoolDef, IMath {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title An interface for wrapped native tokens
 */
interface IWrappedNative {
    // Wraps the native tokens for an ERC-20 compatible token
    function deposit() external payable;

    // Unwraps the ERC-20 tokens to native tokens
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @author Mayfair (from Balancer Labs)
 *
 * @title Put all the constants in one place
 */
library MayfairConstants {
    // State variables (must be constant in a library)

    /// "ONE" - all math is in the "realm" of 10 ** 18; where numeric 1 = 10 ** 18
    uint public constant ONE = 10 ** 18;

    /// Minimum denormalized weight one token can have
    uint public constant MIN_WEIGHT = ONE / 10;
    /// Maximum denormalized weight one token can have
    uint public constant MAX_WEIGHT = ONE * 50;
    /// Maximum denormalized weight the entire pool can have
    uint public constant MAX_TOTAL_WEIGHT = ONE * 50;

    /// Minimum token balance inside the pool
    uint public constant MIN_BALANCE = ONE / 10 ** 6;
    // Maximum token balance inside the pool
    // uint public constant MAX_BALANCE       = ONE * 10**12;

    /// Minimum supply of pool tokens
    uint public constant MIN_POOL_SUPPLY = ONE * 100;
    /// Maximum supply of pool tokens
    uint public constant MAX_POOL_SUPPLY = ONE * 10 ** 9;

    /// Default fee for exiting a pool
    uint public constant EXIT_FEE = (ONE * 3) / 100;
    /// Minimum swap fee possible
    uint public constant MIN_FEE = ONE / 10 ** 6;
    /// Maximum swap fee possible
    uint public constant MAX_FEE = ONE / 10;

    /// Maximum ratio of the token balance that can be sent to the pool for a swap
    uint public constant MAX_IN_RATIO = ONE / 2;
    /// Maximum ratio of the token balance that can be taken out of the pool for a swap
    uint public constant MAX_OUT_RATIO = (ONE / 3) + 1 wei;

    /// Minimum amount of tokens in a pool
    uint public constant MIN_ASSET_LIMIT = 2;
    /// Maximum amount of tokens in a pool
    uint public constant MAX_ASSET_LIMIT = 16;

    /// Maximum representable number in uint256
    uint public constant MAX_UINT = type(uint).max;

    // Core Pools
    /// Minimum token balance inside the core pool
    uint public constant MIN_CORE_BALANCE = ONE / 10 ** 12;

    // Core Num
    /// Minimum base for doing a power of operation
    uint public constant MIN_BPOW_BASE = 1 wei;
    /// Maximum base for doing a power of operation
    uint public constant MAX_BPOW_BASE = (2 * ONE) - 1 wei;
    /// Precision of the approximate power function with fractional exponents
    uint public constant BPOW_PRECISION = ONE / 10 ** 10;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./MayfairConstants.sol";

/**
 * @author Mayfair (and Balancer Labs)
 *
 * @title SafeMath - Wrap Solidity operators to prevent underflow/overflow
 *
 * @dev mul/div have extra checks from OpenZeppelin SafeMath
 *      Most of this math is for dealing with 1 being 10^18
 */
library MayfairSafeMath {
    /**
     * @notice Safe signed subtraction
     *
     * @dev Do a signed subtraction
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        }
        return (b - a, true);
    }

    /**
     * @notice Safe multiplication
     *
     * @dev Multiply safely (and efficiently), rounding down
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Product of operands; throws if overflow or rounding error
     */
    function bmul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        uint c0 = a * b;
        // Round to 0 if x*y < ONE/2?
        uint c1 = c0 + (MayfairConstants.ONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        return c1 / MayfairConstants.ONE;
    }

    /**
     * @notice Safe division
     *
     * @dev Divide safely (and efficiently), rounding down
     *
     * @param dividend - First operand
     * @param divisor - Second operand
     *
     * @return Quotient; throws if overflow or rounding error
     */
    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0) {
            return 0;
        }

        uint c0 = dividend * MayfairConstants.ONE;
        require(c0 / dividend == MayfairConstants.ONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        return c1 / divisor;
    }

    /**
     * @notice Safe unsigned integer modulo
     *
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - First operand
     * @param divisor - Second operand -- cannot be zero
     *
     * @return Quotient; throws if overflow or rounding error
     */
    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Maximum of a and b
     */
    function bmax(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Minimum of a and b
     */
    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     *
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Average of the two values
     */
    function baverage(uint a, uint b) internal pure returns (uint) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     *
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     *
     * @param y - Operand
     *
     * @return z - Square root result
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @notice Remove the fractional part
     *
     * @dev Assumes the fractional part being everything below 10^18
     *
     * @param a - Operand
     *
     * @return Integer part of `a`
     */
    function btoi(uint a) internal pure returns (uint) {
        return a / MayfairConstants.ONE;
    }

    /**
     * @notice Floor function - Zeros the fractional part
     *
     * @dev Assumes the fractional part being everything below 10^18
     *
     * @param a - Operand
     *
     * @return Greatest integer less than or equal to x
     */
    function bfloor(uint a) internal pure returns (uint) {
        return btoi(a) * MayfairConstants.ONE;
    }

    /**
     * @notice Compute a^n where `n` does not have a fractional part
     *
     * @dev Based on code by _DSMath_, `n` must not have a fractional part
     *
     * @param a - Base that will be raised to the power of `n`
     * @param n - Integer exponent
     *
     * @return z - `a` raise to the power of `n`
     */
    function bpowi(uint a, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? a : MayfairConstants.ONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
    }

    /**
     * @notice Compute b^e where `e` has a fractional part
     *
     * @dev Compute b^e by splitting it into (b^i)*(b^f)
     *      Where `i` is the integer part and `f` the fractional part
     *      Uses `bpowi` for `b^e` and `bpowK` for k iterations of approximation of b^0.f
     *
     * @param base - Base that will be raised to the power of exp
     * @param exp - Exponent
     *
     * @return Approximation of b^e
     */
    function bpow(uint base, uint exp) internal pure returns (uint) {
        require(
            base >= MayfairConstants.MIN_BPOW_BASE,
            "ERR_BPOW_BASE_TOO_LOW"
        );
        require(
            base <= MayfairConstants.MAX_BPOW_BASE,
            "ERR_BPOW_BASE_TOO_HIGH"
        );

        uint integerPart = btoi(exp);
        uint fractionPart = exp - (integerPart * MayfairConstants.ONE);

        uint integerPartPow = bpowi(base, integerPart);

        if (fractionPart == 0) {
            return integerPartPow;
        }

        uint fractionPartPow = bpowApprox(
            base,
            fractionPart,
            MayfairConstants.BPOW_PRECISION
        );
        return bmul(integerPartPow, fractionPartPow);
    }

    /**
     * @notice Compute an approximation of b^e where `e` is a fractional part
     *
     * @dev Computes b^e for k iterations of approximation of b^0.f
     *
     * @param base - Base that will be raised to the power of exp
     * @param exp - Fractional exponent
     * @param precision - When the adjustment term goes below this number the function stops
     *
     * @return sum - Approximation of b^e according to precision
     */
    function bpowApprox(
        uint base,
        uint exp,
        uint precision
    ) internal pure returns (uint sum) {
        // term 0:
        (uint x, bool xneg) = bsubSign(base, MayfairConstants.ONE);
        uint term = MayfairConstants.ONE;
        bool negative = false;
        sum = term;

        // term(k) = numer / denom
        //         = (product(exp - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (exp-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * MayfairConstants.ONE;
            (uint c, bool cneg) = bsubSign(exp, (bigK - MayfairConstants.ONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);

            if (term == 0) break;

            if (xneg) negative = !negative;

            if (cneg) negative = !negative;

            if (negative) {
                sum -= term;
            } else {
                sum += term;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// solhint-disable reason-string

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

//SPDX-License-Identifier: GPL-3-or-later
pragma solidity ^0.8.0;

import "../libraries/SafeERC20.sol";
import "../libraries/MayfairSafeMath.sol";
import "../libraries/MayfairConstants.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IWrappedNative.sol";
import "../interfaces/IConfigurableRightsPool.sol";
import "../interfaces/IMayfairCommunityStore.sol";

import "../utils/Ownable.sol";

contract HermesProxy is Ownable {
    using SafeERC20 for IERC20;

    struct Wrappers {
        bytes4 deposit;
        bytes4 withdraw;
        bytes4 exchange;
        address wrapContract;
        uint256 creationBlock;
    }

    /// Native wrapped token address
    address public immutable wNativeToken;
    IMayfairCommunityStore public communityStore;
    address public swapProvider;

    mapping(address => mapping(address => Wrappers)) public wrappers;

    /**
     * @notice Emitted when a token has been set to be wrapped before entering the pool.
     *         This allows the pool to use some uncommon wrapped token, like an autocompounding
     *         protocol, while allowing the user to spend the common token being wrapped.
     *
     * @param crpPool - CRP address that uses this token
     * @param corePool - Core pool of the above CRP
     * @param tokenIn - Token that is not part of the pool but that will be made available for wrapping
     * @param wrappedToken - Underlying token the above token will be wrapped into, this is the token in the pool
     * @param depositSignature - Function signature for the wrapping function
     * @param withdrawSignature - Function signature for the unwrapping function
     * @param exchangeSignature - Function signature for the exchange rate function
     */
    event NewWrapper(
        address indexed crpPool,
        address indexed corePool,
        address indexed tokenIn,
        address wrappedToken,
        string depositSignature,
        string withdrawSignature,
        string exchangeSignature
    );

    /**
     * @notice Set the native token address on creation as it can't be changed
     *
     * @param wNative - The wrapped native blockchain token contract
     * @param communityStore_ - Address of contract that holds the list of whitelisted tokens
     * @param swapProvider_ - Address of a DEX contract that allows swapping tokens
     */
    constructor(
        address wNative,
        address communityStore_,
        address swapProvider_
    ) {
        wNativeToken = wNative;
        communityStore = IMayfairCommunityStore(communityStore_);
        swapProvider = swapProvider_;
    }

    /**
     * @notice Create a wrap interface for automatic wrapping and unwrapping any token.
     *
     * @param crpPool - CRP address that uses this token
     * @param corePool - Core pool of the above CRP
     * @param tokenIn - Token that is not part of the pool but that will be made available for wrapping
     * @param wrappedToken - Underlying token the above token will be wrapped into, this is the token in the pool
     * @param depositSignature - Function signature for the wrapping function
     * @param withdrawSignature - Function signature for the unwrapping function
     * @param exchangeSignature - Function signature for the exchange rate function
     */
    function setTokenWrapper(
        address crpPool,
        address corePool,
        address tokenIn,
        address wrappedToken,
        string memory depositSignature,
        string memory withdrawSignature,
        string memory exchangeSignature
    ) external onlyOwner {
        wrappers[corePool][tokenIn] = Wrappers({
            deposit: bytes4(keccak256(bytes(depositSignature))),
            withdraw: bytes4(keccak256(bytes(withdrawSignature))),
            exchange: bytes4(keccak256(bytes(exchangeSignature))),
            wrapContract: wrappedToken,
            creationBlock: block.number
        });

        wrappers[crpPool][tokenIn] = wrappers[corePool][tokenIn];

        IERC20 wToken = IERC20(wrappedToken);
        IERC20(tokenIn).approve(wrappedToken, type(uint256).max);
        wToken.approve(corePool, type(uint256).max);
        wToken.approve(crpPool, type(uint256).max);

        emit NewWrapper(
            crpPool,
            corePool,
            tokenIn,
            wrappedToken,
            depositSignature,
            withdrawSignature,
            exchangeSignature
        );
    }

    /**
     * @dev Change Swap Provider contract
     *
     * @param newSwapProvider - Address of a DEX contract that allows swapping tokens
     */
    function setSwapProvider(address newSwapProvider) external onlyOwner {
        swapProvider = newSwapProvider;
    }

    /**
     * @dev Change Community Store contract
     *
     * @param newCommunityStore - Address of contract that holds the list of whitelisted tokens
     */
    function updateCommunityStore(
        address newCommunityStore
    ) external onlyOwner {
        require(newCommunityStore != address(0), "ERR_ZERO_ADDRESS");
        communityStore = IMayfairCommunityStore(newCommunityStore);
    }

    /**
     * @notice Join a pool - mint pool tokens with underlying assets
     *
     * @dev Emits a LogJoin event for each token
     *      corePool is a contract interface; function calls on it are external
     *
     * @param crpPool - CRP the user want to interact with
     * @param poolAmountOut - Number of pool tokens to receive
     * @param tokensIn - Address of the tokens the user is sending
     * @param maxAmountsIn - Max amount of asset tokens to spend; will follow the pool order
     * @param referral - Broker address to receive fees
     */
    function joinPool(
        address crpPool,
        uint256 poolAmountOut,
        address[] calldata tokensIn,
        uint256[] calldata maxAmountsIn,
        address referral
    ) external payable {
        uint256[] memory underlyingMaxAmountsIn = new uint256[](
            maxAmountsIn.length
        );
        address[] memory underlyingTokens = new address[](maxAmountsIn.length);

        for (uint256 i = 0; i < tokensIn.length; i++) {
            if (msg.value == 0 || tokensIn[i] != wNativeToken) {
                IERC20(tokensIn[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    maxAmountsIn[i]
                );
            }

            (underlyingTokens[i], underlyingMaxAmountsIn[i]) = _wrapTokenIn(
                crpPool,
                tokensIn[i],
                maxAmountsIn[i]
            );
        }

        {
            IMayfairCommunityStore.PoolInfo memory poolInfo = communityStore
                .getPoolInfo(crpPool);
            require(
                !poolInfo.isPrivate ||
                    communityStore.getPrivateInvestor(crpPool, msg.sender),
                "ERR_INVESTOR_NOT_ALLOWED"
            );
            uint256 _poolAmountOut = MayfairSafeMath.bdiv(
                poolAmountOut,
                MayfairConstants.ONE -
                    poolInfo.feesToManager -
                    poolInfo.feesToReferral
            );
            uint256 _feesToManager = MayfairSafeMath.bmul(
                _poolAmountOut,
                poolInfo.feesToManager
            );
            uint256 _feesToReferral = MayfairSafeMath.bmul(
                _poolAmountOut,
                poolInfo.feesToReferral
            );
            IConfigurableRightsPool(crpPool).joinPool(
                _poolAmountOut,
                underlyingMaxAmountsIn
            );

            if (referral == address(0)) {
                referral = poolInfo.manager;
            }

            IERC20 crpPoolToken = IERC20(crpPool);
            crpPoolToken.safeTransfer(msg.sender, poolAmountOut);
            crpPoolToken.safeTransfer(poolInfo.manager, _feesToManager);
            crpPoolToken.safeTransfer(referral, _feesToReferral);
        }

        for (uint256 i = 0; i < tokensIn.length; i++) {
            address underlyingTokenOut = tokensIn[i];

            if (
                wrappers[crpPool][underlyingTokenOut].wrapContract != address(0)
            ) {
                underlyingTokenOut = wrappers[crpPool][underlyingTokenOut]
                    .wrapContract;
            }

            uint256 _tokenAmountOut = IERC20(underlyingTokens[i]).balanceOf(
                address(this)
            );
            _unwrapTokenOut(
                crpPool,
                underlyingTokenOut,
                underlyingTokens[i],
                _tokenAmountOut
            );
        }
    }

    /**
     * @notice Exit a pool - redeem/burn pool tokens for underlying assets
     *
     * @dev Emits a LogExit event for each token
     *      corePool is a contract interface; function calls on it are external
     *
     * @param crpPool - CRP the user want to interact with
     * @param poolAmountIn - Amount of pool tokens to redeem
     * @param tokensOut - Address of the tokens the user wants to receive
     * @param minAmountsOut - Minimum amount of asset tokens to receive
     */
    function exitPool(
        address crpPool,
        uint256 poolAmountIn,
        address[] calldata tokensOut,
        uint256[] calldata minAmountsOut
    ) external {
        uint256 numTokens = minAmountsOut.length;
        // get the pool tokens from the user to actually execute the exit
        IERC20(crpPool).safeTransferFrom(
            msg.sender,
            address(this),
            poolAmountIn
        );

        // execute the exit without limits, limits will be tested later
        IConfigurableRightsPool(crpPool).exitPool(
            poolAmountIn,
            new uint256[](numTokens)
        );

        // send received tokens to user
        for (uint256 i = 0; i < numTokens; i++) {
            address underlyingTokenOut = tokensOut[i];

            if (
                wrappers[crpPool][underlyingTokenOut].wrapContract != address(0)
            ) {
                underlyingTokenOut = wrappers[crpPool][underlyingTokenOut]
                    .wrapContract;
            }

            uint256 tokenAmountOut = IERC20(underlyingTokenOut).balanceOf(
                address(this)
            );
            tokenAmountOut = _unwrapTokenOut(
                crpPool,
                tokensOut[i],
                underlyingTokenOut,
                tokenAmountOut
            );
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
        }
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     *
     * @dev emits a LogJoin event
     *
     * @param crpPool - CRP the user want to interact with
     * @param tokenIn - Which token we're transferring in
     * @param tokenAmountIn - Amount of the deposit
     * @param minPoolAmountOut - Minimum of pool tokens to receive
     * @param referral - Broker Address to receive fees
     *
     * @return poolAmountOut - Amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(
        address crpPool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut,
        address referral
    ) external payable returns (uint256 poolAmountOut) {
        if (msg.value == 0) {
            IERC20(tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmountIn
            );
        } else {
            tokenAmountIn = 0;
        }

        return
            _joinswapExternAmountIn(
                crpPool,
                tokenIn,
                tokenAmountIn,
                minPoolAmountOut,
                referral
            );
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in using a DEX provider to swap the token
     *         (the token does not need to be present in the pool)
     *         System calculates the pool token amount
     *
     * @dev emits a LogJoin event
     *
     * @param crpPool - CRP the user want to interact with
     * @param tokenIn - Which token we're transferring in
     * @param tokenAmountIn - Amount of the deposit
     * @param minPoolAmountOut - Minimum of pool tokens to receive
     * @param referral - Broker Address to receive fees
     * @param data - Params encoded for send to swap provider
     *
     * @return poolAmountOut - Amount of pool tokens minted and transferred
     */
    function joinswapExternAmountInWithSwap(
        address crpPool,
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenExchange,
        uint256 minPoolAmountOut,
        address referral,
        bytes calldata data
    ) external payable returns (uint256 poolAmountOut) {
        uint balanceTokenExchange = IERC20(tokenExchange).balanceOf(
            address(this)
        );

        if (msg.value == 0) {
            IERC20(tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmountIn
            );
            if (
                IERC20(tokenIn).allowance(address(this), swapProvider) <
                tokenAmountIn
            ) {
                IERC20(tokenIn).safeApprove(swapProvider, type(uint256).max);
            }
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory response) = swapProvider.call{
            value: msg.value
        }(data);
        require(success, string(response));

        balanceTokenExchange =
            IERC20(tokenExchange).balanceOf(address(this)) -
            balanceTokenExchange;

        poolAmountOut = _joinswapExternAmountIn(
            crpPool,
            tokenExchange,
            balanceTokenExchange,
            minPoolAmountOut,
            referral
        );
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     *
     * @dev emits a LogJoin event
     *
     * @param crpPool - CRP the user want to interact with
     * @param tokenIn - Which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - Amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     * @param referral - Broker Address to receive fees
     *
     * @return tokenAmountIn - Amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(
        address crpPool,
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn,
        address referral
    ) external payable returns (uint256 tokenAmountIn) {
        // get tokens from user and wrap it if necessary
        if (msg.value == 0) {
            IERC20(tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                maxAmountIn
            );
        } else {
            maxAmountIn = 0;
        }

        (
            address underlyingTokenIn,
            uint256 underlyingMaxAmountIn
        ) = _wrapTokenIn(crpPool, tokenIn, maxAmountIn);

        IMayfairCommunityStore.PoolInfo memory poolInfo = communityStore
            .getPoolInfo(crpPool);
        require(
            !poolInfo.isPrivate ||
                communityStore.getPrivateInvestor(crpPool, msg.sender),
            "ERR_INVESTOR_NOT_ALLOWED"
        );
        uint256 _poolAmountOut = MayfairSafeMath.bdiv(
            poolAmountOut,
            MayfairConstants.ONE -
                poolInfo.feesToManager -
                poolInfo.feesToReferral
        );
        uint256 _feesToManager = MayfairSafeMath.bmul(
            _poolAmountOut,
            poolInfo.feesToManager
        );
        uint256 _feesToReferral = MayfairSafeMath.bmul(
            _poolAmountOut,
            poolInfo.feesToReferral
        );

        // execute join and get amount of underlying tokens used
        uint256 underlyingTokenAmountIn = IConfigurableRightsPool(crpPool)
            .joinswapPoolAmountOut(
                underlyingTokenIn,
                _poolAmountOut,
                underlyingMaxAmountIn
            );

        if (referral == address(0)) {
            referral = poolInfo.manager;
        }

        IERC20(crpPool).safeTransfer(msg.sender, poolAmountOut);
        IERC20(crpPool).safeTransfer(poolInfo.manager, _feesToManager);
        IERC20(crpPool).safeTransfer(referral, _feesToReferral);

        uint256 excessTokens = _unwrapTokenOut(
            crpPool,
            tokenIn,
            underlyingTokenIn,
            underlyingMaxAmountIn - underlyingTokenAmountIn
        );

        return maxAmountIn - excessTokens;
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool or must be registered as a unwrapped token,
     *         and will incur an _exitFee (if set to non-zero)
     *
     * @dev Emits a LogExit event for the token
     *
     * @param crpPool - CRP the user want to interact with
     * @param tokenOut - Which token the caller wants to receive
     * @param poolAmountIn - Amount of pool tokens to redeem
     * @param minAmountOut - Minimum asset tokens to receive
     *
     * @return tokenAmountOut - Amount of asset tokens returned
     */
    function exitswapPoolAmountIn(
        address crpPool,
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut) {
        // get the pool tokens from the user to actually execute the exit
        IERC20(crpPool).safeTransferFrom(
            msg.sender,
            address(this),
            poolAmountIn
        );
        address underlyingTokenOut = tokenOut;

        // check if the token being passed is the unwrapped version of the token inside the pool
        if (wrappers[crpPool][tokenOut].wrapContract != address(0)) {
            underlyingTokenOut = wrappers[crpPool][tokenOut].wrapContract;
        }

        // execute the exit and get how many tokens were received, we'll test minimum amount later
        uint256 underlyingTokenAmountOut = IConfigurableRightsPool(crpPool)
            .exitswapPoolAmountIn(underlyingTokenOut, poolAmountIn, 0);

        // unwrap the token if it's a wrapped version and send it to the user
        tokenAmountOut = _unwrapTokenOut(
            crpPool,
            tokenOut,
            underlyingTokenOut,
            underlyingTokenAmountOut
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool or must be registered as a unwrapped token
     *         and will incur an _exitFee (if set to non-zero)
     *
     * @dev Emits a LogExit event for the token
     *
     * @param crpPool - CRP the user want to interact with
     * @param tokenOut - Which token the caller wants to receive
     * @param tokenAmountOut - Amount of asset tokens to receive
     * @param maxPoolAmountIn - Maximum pool tokens to be redeemed
     *
     * @return poolAmountIn - Amount of pool tokens redeemed
     */
    /*function exitswapExternAmountOut(
        address crpPool,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        returns (
            uint poolAmountIn
        )
    {
        IERC20 crpPoolERC = IERC20(crpPool);
        // get the pool tokens from the user to actually execute the exit
        crpPoolERC.safeTransferFrom(msg.sender, address(this), maxPoolAmountIn);
        address underlyingTokenOut = tokenOut;

        // check if the token being passed is the unwrapped version of the token inside the pool
        if (wrappers[crpPool][tokenOut].wrapContract != address(0)) {
            underlyingTokenOut = wrappers[crpPool][tokenOut].wrapContract;
        }

        // check if the token being passed is the unwrapped version of the token inside the pool
        uint tokenOutRate = exchangeRate(crpPool, tokenOut);
        tokenAmountOut = MayfairSafeMath.bmul(tokenAmountOut, tokenOutRate);

        // execute the exit and get how many pool tokens were used
        poolAmountIn = IConfigurableRightsPool(crpPool).exitswapExternAmountOut(
            underlyingTokenOut,
            tokenAmountOut,
            maxPoolAmountIn
        );

        // unwrap the token if it's a wrapped version and send it to the user
        _unwrapTokenOut(crpPool, tokenOut, underlyingTokenOut, tokenAmountOut);
        // send back the difference of the maximum and what was used
        crpPoolERC.safeTransfer(msg.sender, maxPoolAmountIn - poolAmountIn);
    }*/

    /**
     * @notice Swap two tokens but sending a fixed amount
     *         This makes sure you spend exactly what you define,
     *         but you can't be sure of how much you'll receive
     *
     * @param corePool - Address of the core pool where the swap will occur
     * @param tokenIn - Address of the token you are sending
     * @param tokenAmountIn - Fixed amount of the token you are sending
     * @param tokenOut - Address of the token you want to receive
     * @param minAmountOut - Minimum amount of tokens you want to receive
     * @param maxPrice - Maximum price you want to pay
     *
     * @return tokenAmountOut - Amount of tokens received
     * @return spotPriceAfter - New price between assets
     */
    function swapExactAmountIn(
        address corePool,
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
        external
        payable
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        address underlyingTokenIn;
        address underlyingTokenOut = tokenOut;

        if (wrappers[corePool][tokenOut].wrapContract != address(0)) {
            underlyingTokenOut = wrappers[corePool][tokenOut].wrapContract;
        }

        (underlyingTokenIn, tokenAmountIn) = _wrapTokenIn(
            corePool,
            tokenIn,
            tokenAmountIn
        );
        uint256 tokenInExchange = exchangeRate(corePool, tokenIn);
        uint256 tokenOutExchange = exchangeRate(corePool, tokenOut);
        maxPrice = MayfairSafeMath.bdiv(
            MayfairSafeMath.bmul(maxPrice, tokenInExchange),
            tokenOutExchange
        );
        minAmountOut = MayfairSafeMath.bmul(minAmountOut, tokenOutExchange);
        // do the swap and get the output
        (
            uint256 underlyingTokenAmountOut,
            uint256 underlyingSpotPriceAfter
        ) = IPool(corePool).swapExactAmountIn(
                underlyingTokenIn,
                tokenAmountIn,
                underlyingTokenOut,
                minAmountOut,
                maxPrice
            );
        tokenAmountOut = _unwrapTokenOut(
            corePool,
            tokenOut,
            underlyingTokenOut,
            underlyingTokenAmountOut
        );
        spotPriceAfter = MayfairSafeMath.bdiv(
            MayfairSafeMath.bmul(underlyingSpotPriceAfter, tokenInExchange),
            tokenOutExchange
        );
    }

    /**
     * @notice Swap two tokens but receiving a fixed amount
     *         This makes sure you receive exactly what you define,
     *         but you can't be sure of how much you'll be spending
     *
     * @param corePool - Address of the core pool where the swap will occur
     * @param tokenIn - Address of the token you are sending
     * @param maxAmountIn - Maximum amount of the token you are sending you want to spend
     * @param tokenOut - Address of the token you want to receive
     * @param tokenAmountOut - Fixed amount of tokens you want to receive
     * @param maxPrice - Maximum price you want to pay
     *
     * @return tokenAmountIn - Amount of tokens sent
     * @return spotPriceAfter - New price between assets
     */
    /*function swapExactAmountOut(
        address corePool,
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    )
        external
        payable
        returns (
            uint tokenAmountIn,
            uint spotPriceAfter
        )
    {
        address underlyingTokenIn;
        address underlyingTokenOut = tokenOut;

        if (wrappers[corePool][tokenOut].wrapContract != address(0)) {
            underlyingTokenOut = wrappers[corePool][tokenOut].wrapContract;
        }

        (underlyingTokenIn, maxAmountIn) = _wrapTokenIn(corePool, tokenIn, maxAmountIn);

        uint tokenInExchange = exchangeRate(corePool, tokenIn);
        uint tokenOutExchange = exchangeRate(corePool, tokenOut);
        uint priceExchange = MayfairSafeMath.bdiv(tokenInExchange, tokenOutExchange);

        maxPrice = MayfairSafeMath.bdiv(maxPrice, priceExchange);

        (tokenAmountIn, spotPriceAfter) = IPool(corePool).swapExactAmountOut(
            underlyingTokenIn,
            maxAmountIn,
            underlyingTokenOut,
            tokenAmountOut,
            maxPrice
        );

        spotPriceAfter = MayfairSafeMath.bmul(spotPriceAfter, priceExchange);
        _unwrapTokenOut(corePool, tokenOut, underlyingTokenOut, tokenAmountOut);
        _unwrapTokenOut(corePool, tokenIn, underlyingTokenIn, maxAmountIn - tokenAmountIn);
    }*/

    /**
     * @notice Get the spot price between two tokens considering the swap fee
     *
     * @param corePool - Address of the core pool where the swap will occur
     * @param tokenIn - Address of the token being swapped-in
     * @param tokenOut - Address of the token being swapped-out
     *
     * @return price - Spot price as amount of swapped-in for every swapped-out
     */
    function getSpotPrice(
        address corePool,
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 price) {
        uint256 tokenInExchange = exchangeRate(corePool, tokenIn);
        uint256 tokenOutExchange = exchangeRate(corePool, tokenOut);

        if (wrappers[corePool][tokenIn].wrapContract != address(0)) {
            tokenIn = wrappers[corePool][tokenIn].wrapContract;
        }

        if (wrappers[corePool][tokenOut].wrapContract != address(0)) {
            tokenOut = wrappers[corePool][tokenOut].wrapContract;
        }

        price = MayfairSafeMath.bdiv(
            MayfairSafeMath.bmul(
                IPool(corePool).getSpotPrice(tokenIn, tokenOut),
                tokenInExchange
            ),
            tokenOutExchange
        );
    }

    /**
     * @notice Get the spot price between two tokens if there's no swap fee
     *
     * @param corePool - Address of the core pool where the swap will occur
     * @param tokenIn - Address of the token being swapped-in
     * @param tokenOut - Address of the token being swapped-out
     *
     * @return price - Spot price as amount of swapped-in for every swapped-out
     */
    function getSpotPriceSansFee(
        address corePool,
        address tokenIn,
        address tokenOut
    ) public view returns (uint256 price) {
        uint256 tokenInExchange = exchangeRate(corePool, tokenIn);
        uint256 tokenOutExchange = exchangeRate(corePool, tokenOut);

        if (wrappers[corePool][tokenIn].wrapContract != address(0)) {
            tokenIn = wrappers[corePool][tokenIn].wrapContract;
        }

        if (wrappers[corePool][tokenOut].wrapContract != address(0)) {
            tokenOut = wrappers[corePool][tokenOut].wrapContract;
        }

        price = MayfairSafeMath.bdiv(
            MayfairSafeMath.bmul(
                IPool(corePool).getSpotPriceSansFee(tokenIn, tokenOut),
                tokenInExchange
            ),
            tokenOutExchange
        );
    }

    /**
     * @notice Get the exchange rate of unwrapped tokens for a wrapped token
     *
     * @param pool - CRP or Core Pool where the tokens are used
     * @param token - The token you want to check the exchange rate
     */
    function exchangeRate(
        address pool,
        address token
    ) public view returns (uint256 tokenExchange) {
        tokenExchange = MayfairConstants.ONE;

        if (wrappers[pool][token].wrapContract != address(0)) {
            bytes4 exchangeFunction = wrappers[pool][token].exchange;
            token = wrappers[pool][token].wrapContract;

            if (exchangeFunction != bytes4(0)) {
                bytes memory callData = abi.encodePacked(
                    exchangeFunction,
                    tokenExchange
                );
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, bytes memory response) = token.staticcall(
                    callData
                );
                require(success, "ERR_DEPOSIT_REVERTED");
                tokenExchange = abi.decode(response, (uint256));
            }
        }
    }

    /**
     * @dev Wraps the token sent if necessary, it won't do anything if there's no wrapping to be done.
     *
     * @param pool - CRP or Core pool address
     * @param tokenIn - Address of the token sent by the user
     * @param tokenAmountIn - The amount of tokenIn
     *
     * @return wrappedTokenIn - Address of the wrapped token
     * @return wrappedTokenAmountIn - The amount of wrappedTokenIn
     */
    function _wrapTokenIn(
        address pool,
        address tokenIn,
        uint256 tokenAmountIn
    ) private returns (address wrappedTokenIn, uint256 wrappedTokenAmountIn) {
        address wrapContract = wrappers[pool][tokenIn].wrapContract;
        uint256 avaxIn;

        if (tokenIn == wNativeToken) {
            if (tokenAmountIn == 0) {
                avaxIn = msg.value;
            }

            if (address(this).balance > 0) {
                avaxIn = address(this).balance;
            }
        }

        wrappedTokenIn = tokenIn;
        wrappedTokenAmountIn = tokenAmountIn;

        if (wrapContract != address(0)) {
            wrappedTokenIn = wrapContract;

            bytes memory callData = abi.encodePacked(
                wrappers[pool][tokenIn].deposit,
                tokenAmountIn
            );
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory response) = wrappedTokenIn.call{
                value: avaxIn
            }(callData);
            require(success, string(response));
            wrappedTokenAmountIn = IERC20(wrappedTokenIn).balanceOf(
                address(this)
            );
        }

        // approve the core pool spending tokens sent to this contract so the swap can happen
        if (
            IERC20(wrappedTokenIn).allowance(address(this), pool) <
            wrappedTokenAmountIn
        ) {
            IERC20(wrappedTokenIn).safeApprove(pool, type(uint256).max);
        }
    }

    /**
     * @dev Unwraps the token received if necessary, it won't do anything if there's no unwrapping to be done.
     *      The user may request to receive the wrapped token, in this case we won't unwrap too.
     *
     * @param pool - CRP or Core pool address
     * @param tokenOut - Address of the token requested by the user
     * @param wrappedTokenOut - Address of the token received from the pool
     * @param tokenAmountOut - The amount of tokenOut
     *
     * @return unwrappedTokenAmountOut - The amount of tokens to be sent to the user
     */
    function _unwrapTokenOut(
        address pool,
        address tokenOut,
        address wrappedTokenOut,
        uint256 tokenAmountOut
    ) private returns (uint256 unwrappedTokenAmountOut) {
        unwrappedTokenAmountOut = tokenAmountOut;

        if (tokenOut != wrappedTokenOut) {
            bytes memory callData = abi.encodePacked(
                wrappers[pool][tokenOut].withdraw,
                tokenAmountOut
            );
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory response) = wrappedTokenOut.call(
                callData
            );
            require(success, string(response));
            // require(success, string(abi.encodePacked("ERR_WITHDRAW_REVERTED_", toAsciiString(tokenOut))));
            unwrappedTokenAmountOut = IERC20(tokenOut).balanceOf(address(this));
        }

        if (tokenOut == wNativeToken) {
            // unwrap the wrapped token and send to user unwrapped
            IWrappedNative(wNativeToken).withdraw(unwrappedTokenAmountOut);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(msg.sender).call{
                value: address(this).balance
            }("");
            require(success, "Failed to send AVAX");
        } else {
            // send the output token to the user
            IERC20(tokenOut).safeTransfer(msg.sender, unwrappedTokenAmountOut);
        }

        return unwrappedTokenAmountOut;
    }

    /**
     * @dev Join by swapping a fixed amount of an external token in (must be present in the pool)
     *      System calculates the pool token amount
     *      This does the actual investment in the pool
     *
     *      emits a LogJoin event
     *
     * @param crpPool - CRP the user want to interact with
     * @param tokenIn - Which token we're transferring in
     * @param tokenAmountIn - Amount of the deposit
     * @param minPoolAmountOut - Minimum of pool tokens to receive
     * @param referral - Broker Address to receive fees
     *
     * @return poolAmountOut - Amount of pool tokens minted and transferred
     */
    function _joinswapExternAmountIn(
        address crpPool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut,
        address referral
    ) private returns (uint256 poolAmountOut) {
        // get tokens from user and wrap it if necessary
        (
            address underlyingTokenIn,
            uint256 underlyingTokenAmountIn
        ) = _wrapTokenIn(crpPool, tokenIn, tokenAmountIn);

        // execute join and get amount of pool tokens minted
        poolAmountOut = IConfigurableRightsPool(crpPool).joinswapExternAmountIn(
                underlyingTokenIn,
                underlyingTokenAmountIn,
                minPoolAmountOut
            );

        IMayfairCommunityStore.PoolInfo memory poolInfo = communityStore
            .getPoolInfo(crpPool);
        require(
            !poolInfo.isPrivate ||
                communityStore.getPrivateInvestor(crpPool, msg.sender),
            "ERR_INVESTOR_NOT_ALLOWED"
        );
        uint256 _feesToManager = MayfairSafeMath.bmul(
            poolAmountOut,
            poolInfo.feesToManager
        );
        uint256 _feesToReferral = MayfairSafeMath.bmul(
            poolAmountOut,
            poolInfo.feesToReferral
        );
        uint256 _poolAmountOut = poolAmountOut -
            (_feesToReferral + _feesToManager);

        if (referral == address(0)) {
            referral = poolInfo.manager;
        }

        IERC20(crpPool).safeTransfer(msg.sender, _poolAmountOut);
        IERC20(crpPool).safeTransfer(poolInfo.manager, _feesToManager);
        IERC20(crpPool).safeTransfer(referral, _feesToReferral);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IOwnable.sol";

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
abstract contract Ownable is IOwnable {
    // owner of the contract
    address private _owner;

    /**
     * @notice Emitted when the owner is changed
     *
     * @param previousOwner - The previous owner of the contract
     * @param newOwner - The new owner of the contract
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     *
     * @dev external for gas optimization
     *
     * @param newOwner - Address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    /**
     * @notice Returns the address of the current owner
     *
     * @dev external for gas optimization
     *
     * @return address - of the owner (AKA controller)
     */
    function getController() external view override returns (address) {
        return _owner;
    }
}