// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165 {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPoolErrors.sol";
import "./IPoolPosition.sol";
import "./IPoolLiquidityPosition.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Perpetual Pool Position Interface
/// @notice This interface defines the functions for managing positions and liquidity positions in a perpetual pool
interface IPool is IPoolLiquidityPosition, IPoolPosition, IPoolErrors {
    struct PriceVertex {
        uint128 size;
        uint128 premiumRateX96;
    }

    struct PriceState {
        uint128 maxPriceImpactLiquidity;
        uint128 premiumRateX96;
        PriceVertex[7] priceVertices;
        uint8 pendingVertexIndex;
        uint8 liquidationVertexIndex;
        uint8 currentVertexIndex;
        uint128[7] liquidationBufferNetSizes;
    }

    /// @notice Emitted when the price vertex is changed
    event PriceVertexChanged(uint8 index, uint128 sizeAfter, uint128 premiumRateAfterX96);

    /// @notice Emitted when the protocol fee is increased
    /// @param amount The increased protocol fee
    event ProtocolFeeIncreased(uint128 amount);

    /// @notice Emitted when the protocol fee is collected
    /// @param amount The collected protocol fee
    event ProtocolFeeCollected(uint128 amount);

    /// @notice Emitted when the referral fee is increased
    /// @param referee The address of the referee
    /// @param referralToken The id of the referral token
    /// @param referralFee The amount of referral fee
    /// @param referralParentToken The id of the referral parent token
    /// @param referralParentFee The amount of referral parent fee
    event ReferralFeeIncreased(
        address indexed referee,
        uint256 indexed referralToken,
        uint128 referralFee,
        uint256 indexed referralParentToken,
        uint128 referralParentFee
    );

    /// @notice Emitted when the referral fee is collected
    /// @param referralToken The id of the referral token
    /// @param receiver The address to receive the referral fee
    /// @param amount The collected referral fee
    event ReferralFeeCollected(uint256 indexed referralToken, address indexed receiver, uint256 amount);

    function token() external view returns (IERC20);

    /// @notice Change the token config
    /// @dev The call will fail if caller is not the pool factory
    function onChangeTokenConfig() external;

    /// @notice Sample and adjust the funding rate
    function sampleAndAdjustFundingRate() external;

    /// @notice Return the price state
    /// @return maxPriceImpactLiquidity The maximum LP liquidity value used to calculate
    /// premium rate when trader increase or decrease positions
    /// @return premiumRateX96 The premium rate during the last position adjustment by the trader, as a Q32.96
    /// @return priceVertices The price vertices used to determine the pricing function
    /// @return pendingVertexIndex The index used to track the pending update of the price vertex
    /// @return liquidationVertexIndex The index used to store the net position of the liquidation
    /// @return currentVertexIndex The index used to track the current used price vertex
    /// @return liquidationBufferNetSizes The net sizes of the liquidation buffer
    function priceState()
        external
        view
        returns (
            uint128 maxPriceImpactLiquidity,
            uint128 premiumRateX96,
            PriceVertex[7] memory priceVertices,
            uint8 pendingVertexIndex,
            uint8 liquidationVertexIndex,
            uint8 currentVertexIndex,
            uint128[7] memory liquidationBufferNetSizes
        );

    /// @notice Get the market price
    /// @param side The side of the position adjustment, 1 for opening long or closing short positions,
    /// 2 for opening short or closing long positions
    /// @return marketPriceX96 The market price, as a Q64.96
    function marketPriceX96(Side side) external view returns (uint160 marketPriceX96);

    /// @notice Change the price vertex
    /// @param startExclusive The start index of the price vertex to be changed, exclusive
    /// @param endInclusive The end index of the price vertex to be changed, inclusive
    function changePriceVertex(uint8 startExclusive, uint8 endInclusive) external;

    /// @notice Return the protocol fee
    function protocolFee() external view returns (uint128);

    /// @notice Collect the protocol fee
    /// @dev This function can be called without authorization
    function collectProtocolFee() external;

    /// @notice Return the referral fee
    /// @param referralToken The id of the referral token
    function referralFees(uint256 referralToken) external view returns (uint256);

    /// @notice Collect the referral fee
    /// @param referralToken The id of the referral token
    /// @param receiver The address to receive the referral fee
    /// @return The collected referral fee
    function collectReferralFee(uint256 referralToken, address receiver) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

interface IPoolErrors {
    /// @notice Liquidity is not enough to open a liquidity position
    error InvalidLiquidityToOpen();
    /// @notice Invalid caller
    error InvalidCaller(address requiredCaller);
    /// @notice Insufficient size to decrease
    error InsufficientSizeToDecrease(uint128 size, uint128 requiredSize);
    /// @notice Insufficient margin
    error InsufficientMargin();
    /// @notice Position not found
    error PositionNotFound(address requiredAccount, Side requiredSide);
    /// @notice Liquidity position not found
    error LiquidityPositionNotFound(uint256 requiredPositionID);
    /// @notice Last liquidity position cannot be closed
    error LastLiquidityPositionCannotBeClosed();
    /// @notice Caller is not the liquidator
    error CallerNotLiquidator();
    /// @notice Insufficient balance
    error InsufficientBalance(uint128 balance, uint128 requiredAmount);
    /// @notice Leverage is too high
    error LeverageTooHigh(uint256 margin, uint128 liquidity, uint32 maxLeverage);
    /// @notice Insufficient global liquidity
    error InsufficientGlobalLiquidity();
    /// @notice Risk rate is too high
    error RiskRateTooHigh(uint256 margin, uint64 liquidationExecutionFee, uint128 positionUnrealizedLoss);
    /// @notice Risk rate is too low
    error RiskRateTooLow(uint256 margin, uint64 liquidationExecutionFee, uint128 positionUnrealizedLoss);
    /// @notice Position margin rate is too low
    error MarginRateTooLow(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
    /// @notice Position margin rate is too high
    error MarginRateTooHigh(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

/// @title Perpetual Pool Liquidity Position Interface
/// @notice This interface defines the functions for managing liquidity positions in a perpetual pool
interface IPoolLiquidityPosition {
    /// @notice Emitted when the unrealized loss metrics of the global liquidity position are changed
    /// @param lastZeroLossTimeAfter The time when the LP's net position no longer has unrealized losses
    /// or the risk buffer fund has enough balance to cover the unrealized losses of all LPs
    /// @param liquidityAfter The total liquidity of all LPs whose entry time is
    /// after `lastZeroLossTime`
    /// @param liquidityTimesUnrealizedLossAfter The product of liquidity and unrealized loss for
    /// each LP whose entry time is after `lastZeroLossTime`
    event GlobalUnrealizedLossMetricsChanged(
        uint64 lastZeroLossTimeAfter,
        uint128 liquidityAfter,
        uint256 liquidityTimesUnrealizedLossAfter
    );

    /// @notice Emitted when an LP opens a liquidity position
    /// @param account The owner of the position
    /// @param positionID The position ID
    /// @param margin The margin of the position
    /// @param liquidity The liquidity of the position
    /// @param entryUnrealizedLoss The snapshot of the unrealized loss of LP at the time of opening the position
    /// @param realizedProfitGrowthX64 The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
    /// at the time of opening the position, as a Q192.64
    event LiquidityPositionOpened(
        address indexed account,
        uint96 positionID,
        uint128 margin,
        uint128 liquidity,
        uint256 entryUnrealizedLoss,
        uint256 realizedProfitGrowthX64
    );

    /// @notice Emitted when an LP closes a liquidity position
    /// @param positionID The position ID
    /// @param margin The margin removed from the position after closing
    /// @param unrealizedLoss The unrealized loss incurred by the position at the time of closing,
    /// which will be transferred to `GlobalLiquidityPosition.riskBufferFund`
    /// @param realizedProfit The realized profit of the position at the time of closing
    /// @param receiver The address that receives the margin upon closing
    event LiquidityPositionClosed(
        uint96 indexed positionID,
        uint128 margin,
        uint128 unrealizedLoss,
        uint256 realizedProfit,
        address receiver
    );

    /// @notice Emitted when the margin of an LP's position is adjusted
    /// @param positionID The position ID
    /// @param marginDelta Change in margin, positive for increase and negative for decrease
    /// @param marginAfter Adjusted margin
    /// @param entryRealizedProfitGrowthAfterX64 The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
    ///  after adjustment, as a Q192.64
    /// @param receiver The address that receives the margin when it is decreased
    event LiquidityPositionMarginAdjusted(
        uint96 indexed positionID,
        int128 marginDelta,
        uint128 marginAfter,
        uint256 entryRealizedProfitGrowthAfterX64,
        address receiver
    );

    /// @notice Emitted when an LP's position is liquidated
    /// @param liquidator The address that executes the liquidation of the position
    /// @param positionID The position ID to be liquidated
    /// @param realizedProfit The realized profit of the position at the time of liquidation
    /// @param riskBufferFundDelta The remaining margin of the position after liquidation,
    /// which will be transferred to `GlobalLiquidityPosition.riskBufferFund`
    /// @param liquidationExecutionFee The liquidation execution fee paid by the position
    /// @param feeReceiver The address that receives the liquidation execution fee
    event LiquidityPositionLiquidated(
        address indexed liquidator,
        uint96 indexed positionID,
        uint256 realizedProfit,
        uint256 riskBufferFundDelta,
        uint64 liquidationExecutionFee,
        address feeReceiver
    );

    /// @notice Emitted when the net position of all LP's is adjusted
    /// @param netSizeAfter The adjusted net position size
    /// @param liquidationBufferNetSizeAfter The adjusted net position size in the liquidation buffer
    /// @param entryPriceAfterX96 The adjusted entry price, as a Q64.96
    /// @param sideAfter The adjusted side of the net position
    event GlobalLiquidityPositionNetPositionAdjusted(
        uint128 netSizeAfter,
        uint128 liquidationBufferNetSizeAfter,
        uint160 entryPriceAfterX96,
        Side sideAfter
    );

    /// @notice Emitted when the `realizedProfitGrowthX64` of the global liquidity position is changed
    /// @param realizedProfitGrowthAfterX64 The adjusted `realizedProfitGrowthX64`, as a Q192.64
    event GlobalLiquidityPositionRealizedProfitGrowthChanged(uint256 realizedProfitGrowthAfterX64);

    /// @notice Emitted when the risk buffer fund is used by `Gov`
    /// @param receiver The address that receives the risk buffer fund
    /// @param riskBufferFundDelta The amount of risk buffer fund used
    event GlobalRiskBufferFundGovUsed(address indexed receiver, uint128 riskBufferFundDelta);

    /// @notice Emitted when the risk buffer fund is changed
    event GlobalRiskBufferFundChanged(int256 riskBufferFundAfter);

    /// @notice Emitted when the liquidity of the risk buffer fund is increased
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the increase
    /// @param unlockTimeAfter The unlock time of the position after the increase
    event RiskBufferFundPositionIncreased(address indexed account, uint128 liquidityAfter, uint64 unlockTimeAfter);

    /// @notice Emitted when the liquidity of the risk buffer fund is decreased
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the decrease
    /// @param receiver The address that receives the liquidity when it is decreased
    event RiskBufferFundPositionDecreased(address indexed account, uint128 liquidityAfter, address receiver);

    struct GlobalLiquidityPosition {
        uint128 netSize;
        uint128 liquidationBufferNetSize;
        uint160 entryPriceX96;
        Side side;
        uint128 liquidity;
        uint256 realizedProfitGrowthX64;
    }

    struct GlobalRiskBufferFund {
        int256 riskBufferFund;
        uint256 liquidity;
    }

    struct GlobalUnrealizedLossMetrics {
        uint64 lastZeroLossTime;
        uint128 liquidity;
        uint256 liquidityTimesUnrealizedLoss;
    }

    struct LiquidityPosition {
        uint128 margin;
        uint128 liquidity;
        uint256 entryUnrealizedLoss;
        uint256 entryRealizedProfitGrowthX64;
        uint64 entryTime;
        address account;
    }

    struct RiskBufferFundPosition {
        uint128 liquidity;
        uint64 unlockTime;
    }

    /// @notice Get the global liquidity position
    /// @return netSize The size of the net position held by all LPs
    /// @return liquidationBufferNetSize The size of the net position held by all LPs in the liquidation buffer
    /// @return entryPriceX96 The entry price of the net position held by all LPs, as a Q64.96
    /// @return side The side of the position (Long or Short)
    /// @return liquidity The total liquidity of all LPs
    /// @return realizedProfitGrowthX64 The accumulated realized profit growth per liquidity unit, as a Q192.64
    function globalLiquidityPosition()
        external
        view
        returns (
            uint128 netSize,
            uint128 liquidationBufferNetSize,
            uint160 entryPriceX96,
            Side side,
            uint128 liquidity,
            uint256 realizedProfitGrowthX64
        );

    /// @notice Get the global unrealized loss metrics
    /// @return lastZeroLossTime The time when the LP's net position no longer has unrealized losses
    /// or the risk buffer fund has enough balance to cover the unrealized losses of all LPs
    /// @return liquidity The total liquidity of all LPs whose entry time is
    /// after `lastZeroLossTime`
    /// @return liquidityTimesUnrealizedLoss The product of liquidity and unrealized loss for
    /// each LP whose entry time is after `lastZeroLossTime`
    function globalUnrealizedLossMetrics()
        external
        view
        returns (uint64 lastZeroLossTime, uint128 liquidity, uint256 liquidityTimesUnrealizedLoss);

    /// @notice Get the information of a liquidity position
    /// @param positionID The position ID
    /// @return margin The margin of the position
    /// @return liquidity The liquidity (value) of the position
    /// @return entryUnrealizedLoss The snapshot of unrealized loss of LP at the time of opening the position
    /// @return entryRealizedProfitGrowthX64 The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
    /// at the time of opening the position, as a Q192.64
    /// @return entryTime The time when the position is opened
    /// @return account The owner of the position
    function liquidityPositions(
        uint96 positionID
    )
        external
        view
        returns (
            uint128 margin,
            uint128 liquidity,
            uint256 entryUnrealizedLoss,
            uint256 entryRealizedProfitGrowthX64,
            uint64 entryTime,
            address account
        );

    /// @notice Get the owner of a specific liquidity position
    /// @param positionID The position ID
    /// @return account The owner of the position, `address(0)` returned if the position does not exist
    function liquidityPositionAccount(uint96 positionID) external view returns (address account);

    /// @notice Open a new liquidity position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param account The owner of the position
    /// @param margin The margin of the position
    /// @param liquidity The liquidity (value) of the position
    /// @return positionID The position ID
    function openLiquidityPosition(
        address account,
        uint128 margin,
        uint128 liquidity
    ) external returns (uint96 positionID);

    /// @notice Close a liquidity position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param positionID The position ID
    /// @param receiver The address to receive the margin at the time of closing
    function closeLiquidityPosition(uint96 positionID, address receiver) external;

    /// @notice Adjust the margin of a liquidity position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param positionID The position ID
    /// @param marginDelta The change in margin, positive for increasing margin and negative for decreasing margin
    /// @param receiver The address to receive the margin when the margin is decreased
    function adjustLiquidityPositionMargin(uint96 positionID, int128 marginDelta, address receiver) external;

    /// @notice Liquidate a liquidity position
    /// @dev The call will fail if the caller is not the liquidator or the position does not exist
    /// @param positionID The position ID
    /// @param feeReceiver The address to receive the liquidation execution fee
    function liquidateLiquidityPosition(uint96 positionID, address feeReceiver) external;

    /// @notice `Gov` uses the risk buffer fund
    /// @dev The call will fail if the caller is not the `Gov` or
    /// the adjusted remaining risk buffer fund cannot cover the unrealized loss
    /// @param receiver The address to receive the risk buffer fund
    /// @param riskBufferFundDelta The used risk buffer fund
    function govUseRiskBufferFund(address receiver, uint128 riskBufferFundDelta) external;

    /// @notice Get the global risk buffer fund
    /// @return riskBufferFund The risk buffer fund, which accumulated by unrealized losses and price impact fees
    /// paid by LPs when positions are closed or liquidated. It also accumulates the remaining margin of LPs
    /// after liquidation. Additionally, the net profit or loss from closing LP's net position is also accumulated
    /// in the risk buffer fund
    /// @return liquidity The total liquidity of the risk buffer fund
    function globalRiskBufferFund() external view returns (int256 riskBufferFund, uint256 liquidity);

    /// @notice Get the liquidity of the risk buffer fund
    /// @param account The owner of the position
    /// @return liquidity The liquidity of the risk buffer fund
    /// @return unlockTime The time when the liquidity can be withdrawn
    function riskBufferFundPositions(address account) external view returns (uint128 liquidity, uint64 unlockTime);

    /// @notice Increase the liquidity of a risk buffer fund position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param account The owner of the position
    /// @param liquidityDelta The increase in liquidity
    function increaseRiskBufferFundPosition(address account, uint128 liquidityDelta) external;

    /// @notice Decrease the liquidity of a risk buffer fund position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param account The owner of the position
    /// @param liquidityDelta The decrease in liquidity
    /// @param receiver The address to receive the liquidity when it is decreased
    function decreaseRiskBufferFundPosition(address account, uint128 liquidityDelta, address receiver) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

/// @title Perpetual Pool Position Interface
/// @notice This interface defines the functions for managing positions in a perpetual pool
interface IPoolPosition {
    /// @notice Emitted when the funding rate growth is adjusted
    /// @param fundingRateDeltaX96 The change in funding rate, a positive value means longs pay shorts,
    /// when a negative value means shorts pay longs, as a Q160.96
    /// @param longFundingRateGrowthAfterX96 The adjusted `GlobalPosition.longFundingRateGrowthX96`, as a Q96.96
    /// @param shortFundingRateGrowthAfterX96 The adjusted `GlobalPosition.shortFundingRateGrowthX96`, as a Q96.96
    /// @param lastAdjustFundingRateTime The adjusted `GlobalFundingRateSample.lastAdjustFundingRateTime`
    event FundingRateGrowthAdjusted(
        int256 fundingRateDeltaX96,
        int192 longFundingRateGrowthAfterX96,
        int192 shortFundingRateGrowthAfterX96,
        uint64 lastAdjustFundingRateTime
    );

    /// @notice Emitted when the position margin/liquidity (value) is increased
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    /// @param entryPriceAfterX96 The adjusted entry price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives funding fee,
    /// while a negative value means the position positive pays funding fee
    /// @param tradingFee The trading fee paid by the position
    event PositionIncreased(
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        uint160 entryPriceAfterX96,
        int256 fundingFee,
        uint128 tradingFee
    );

    /// @notice Emitted when the position margin/liquidity (value) is decreased
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decreased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    /// @param realizedPnLDelta The realized PnL
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param tradingFee The trading fee paid by the position
    /// @param receiver The address that receives the margin
    event PositionDecreased(
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        int256 realizedPnLDelta,
        int256 fundingFee,
        uint128 tradingFee,
        address receiver
    );

    /// @notice Emitted when a position is liquidated
    /// @param liquidator The address that executes the liquidation of the position
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param indexPriceX96 The index price when liquidating the position, as a Q64.96
    /// @param liquidationPriceX96 The liquidation price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee. If it's negative,
    /// it represents the actual funding fee paid during liquidation
    /// @param tradingFee The trading fee paid by the position
    /// @param liquidationFee The liquidation fee paid by the position
    /// @param liquidationExecutionFee The liquidation execution fee paid by the position
    /// @param feeReceiver The address that receives the liquidation execution fee
    event PositionLiquidated(
        address indexed liquidator,
        address indexed account,
        Side side,
        uint160 indexPriceX96,
        uint160 liquidationPriceX96,
        int256 fundingFee,
        uint128 tradingFee,
        uint128 liquidationFee,
        uint64 liquidationExecutionFee,
        address feeReceiver
    );

    struct GlobalPosition {
        uint128 longSize;
        uint128 shortSize;
        int192 longFundingRateGrowthX96;
        int192 shortFundingRateGrowthX96;
    }

    struct PreviousGlobalFundingRate {
        int192 longFundingRateGrowthX96;
        int192 shortFundingRateGrowthX96;
    }

    struct GlobalFundingRateSample {
        uint64 lastAdjustFundingRateTime;
        uint16 sampleCount;
        int176 cumulativePremiumRateX96;
    }

    struct Position {
        uint128 margin;
        uint128 size;
        uint160 entryPriceX96;
        int192 entryFundingRateGrowthX96;
    }

    /// @notice Get the global position
    /// @return longSize The sum of long position sizes
    /// @return shortSize The sum of short position sizes
    /// @return longFundingRateGrowthX96 The funding rate growth per unit of long position sizes, as a Q96.96
    /// @return shortFundingRateGrowthX96 The funding rate growth per unit of short position sizes, as a Q96.96
    function globalPosition()
        external
        view
        returns (
            uint128 longSize,
            uint128 shortSize,
            int192 longFundingRateGrowthX96,
            int192 shortFundingRateGrowthX96
        );

    /// @notice Get the previous global funding rate growth
    /// @return longFundingRateGrowthX96 The funding rate growth per unit of long position sizes, as a Q96.96
    /// @return shortFundingRateGrowthX96 The funding rate growth per unit of short position sizes, as a Q96.96
    function previousGlobalFundingRate()
        external
        view
        returns (int192 longFundingRateGrowthX96, int192 shortFundingRateGrowthX96);

    /// @notice Get the global funding rate sample
    /// @return lastAdjustFundingRateTime The timestamp of the last funding rate adjustment
    /// @return sampleCount The number of samples taken since the last funding rate adjustment
    /// @return cumulativePremiumRateX96 The cumulative premium rate of the samples taken
    /// since the last funding rate adjustment, as a Q80.96
    function globalFundingRateSample()
        external
        view
        returns (uint64 lastAdjustFundingRateTime, uint16 sampleCount, int176 cumulativePremiumRateX96);

    /// @notice Get the information of a position
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @return margin The margin of the position
    /// @return size The size of the position
    /// @return entryPriceX96 The entry price of the position, as a Q64.96
    /// @return entryFundingRateGrowthX96 The snapshot of the funding rate growth at the time the position was opened.
    /// For long positions it is `GlobalPosition.longFundingRateGrowthX96`,
    /// and for short positions it is `GlobalPosition.shortFundingRateGrowthX96`
    function positions(
        address account,
        Side side
    ) external view returns (uint128 margin, uint128 size, uint160 entryPriceX96, int192 entryFundingRateGrowthX96);

    /// @notice Increase the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increase in margin, which can be 0
    /// @param sizeDelta The increase in size, which can be 0
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    function increasePosition(
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta
    ) external returns (uint160 tradePriceX96);

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decrease in margin, which can be 0
    /// @param sizeDelta The decrease in size, which can be 0
    /// @param receiver The address to receive the margin
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    function decreasePosition(
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        address receiver
    ) external returns (uint160 tradePriceX96);

    /// @notice Liquidate a position
    /// @dev The call will fail if the caller is not the liquidator or the position does not exist
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param feeReceiver The address that receives the liquidation execution fee
    function liquidatePosition(address account, Side side, address feeReceiver) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../core/interfaces/IPool.sol";
import {Bitmap} from "../../types/Bitmap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardFarm {
    /// @notice Emitted when the reward debt is changed
    /// @param pool The address of the pool
    /// @param account The owner of the liquidity reward
    /// @param rewardDebtDelta The change in reward debt for the account
    event LiquidityRewardDebtChanged(IPool indexed pool, address indexed account, uint256 rewardDebtDelta);

    /// @notice Emitted when the liquidity reward is collected
    /// @param pools The pool addresses
    /// @param account The owner of the liquidity reward
    /// @param receiver The address to receive the liquidity reward
    /// @param rewardDebt The amount of liquidity reward received
    event LiquidityRewardCollected(
        IPool[] pools,
        address indexed account,
        address indexed receiver,
        uint256 rewardDebt
    );

    /// @notice Emitted when the risk buffer fund reward debt is changed
    /// @param pool The address of the pool
    /// @param account The owner of the risk buffer fund reward
    /// @param rewardDebtDelta The change in reward debt for the account
    event RiskBufferFundRewardDebtChanged(IPool indexed pool, address indexed account, uint256 rewardDebtDelta);

    /// @notice Emitted when the risk buffer fund reward is collected
    /// @param pools The pool addresses
    /// @param account The owner of the risk buffer fund reward
    /// @param receiver The address to receive the liquidity reward
    /// @param rewardDebt The amount of risk buffer fund reward received
    event RiskBufferFundRewardCollected(
        IPool[] pools,
        address indexed account,
        address indexed receiver,
        uint256 rewardDebt
    );

    /// @notice Emitted when the liquidity reward growth is increased
    /// @param pool The address of the pool
    /// @param rewardDelta The change in liquidity reward for the pool
    /// @param rewardGrowthAfterX64 The adjusted `PoolReward.liquidityRewardGrowthX64`, as a Q64.64
    event PoolLiquidityRewardGrowthIncreased(IPool indexed pool, uint256 rewardDelta, uint128 rewardGrowthAfterX64);

    /// @notice Emitted when the referral token reward growth is increased
    /// @param pool The address of the pool
    /// @param rewardDelta The change in referral token reward for the pool
    /// @param rewardGrowthAfterX64 The adjusted `PoolReward.referralTokenRewardGrowthX64`, as a Q64.64
    /// @param positionRewardDelta The change in referral token position reward for the pool
    /// @param positionRewardGrowthAfterX64 The adjusted
    /// `PoolReward.referralTokenPositionRewardGrowthX64`, as a Q64.64
    event PoolReferralTokenRewardGrowthIncreased(
        IPool indexed pool,
        uint256 rewardDelta,
        uint128 rewardGrowthAfterX64,
        uint256 positionRewardDelta,
        uint128 positionRewardGrowthAfterX64
    );

    /// @notice Emitted when the referral token reward growth is increased
    /// @param pool The address of the pool
    /// @param rewardDelta The change in referral parent token reward for the pool
    /// @param rewardGrowthAfterX64 The adjusted `PoolReward.referralParentTokenRewardGrowthX64`, as a Q64.64
    /// @param positionRewardDelta The change in referral parent token position reward for the pool
    /// @param positionRewardGrowthAfterX64 The adjusted
    /// `PoolReward.referralParentTokenPositionRewardGrowthX64`, as a Q64.64
    event PoolReferralParentTokenRewardGrowthIncreased(
        IPool indexed pool,
        uint256 rewardDelta,
        uint128 rewardGrowthAfterX64,
        uint256 positionRewardDelta,
        uint128 positionRewardGrowthAfterX64
    );

    /// @notice Emitted when the risk buffer fund reward growth is increased
    /// @param pool The address of the pool
    /// @param rewardDelta The change in risk buffer fund reward for the pool
    /// @param rewardGrowthAfterX64 The adjusted `PoolReward.riskBufferFundRewardGrowthX64`, as a Q64.64
    event PoolRiskBufferFundRewardGrowthIncreased(
        IPool indexed pool,
        uint256 rewardDelta,
        uint128 rewardGrowthAfterX64
    );

    /// @notice Emitted when the pool reward updated
    /// @param pool The address of the pool
    /// @param rewardPerSecond The amount minted per second
    event PoolRewardUpdated(IPool indexed pool, uint160 rewardPerSecond);

    /// @notice Emitted when the referral liquidity reward debt is changed
    /// @param pool The address of the pool
    /// @param referralToken The ID of the referral token
    /// @param rewardDebtDelta The change in reward debt for the referral token
    event ReferralLiquidityRewardDebtChanged(
        IPool indexed pool,
        uint256 indexed referralToken,
        uint256 rewardDebtDelta
    );

    /// @notice Emitted when the referral position reward debt is changed
    /// @param pool The address of the pool
    /// @param referralToken The ID of the referral token
    /// @param rewardDebtDelta The change in reward debt for the referral token
    event ReferralPositionRewardDebtChanged(IPool indexed pool, uint256 indexed referralToken, uint256 rewardDebtDelta);

    /// @notice Emitted when the referral reward is collected
    /// @param pools The pool addresses
    /// @param referralTokens The IDs of the referral tokens
    /// @param receiver The address to receive the referral reward
    /// @param rewardDebt The amount of the referral reward received
    event ReferralRewardCollected(
        IPool[] pools,
        uint256[] referralTokens,
        address indexed receiver,
        uint256 rewardDebt
    );

    /// @notice Emitted when configuration is changed
    /// @param newConfig The new configuration
    event ConfigChanged(Config newConfig);

    /// @notice Emitted when the reward cap is changed
    /// @param rewardCapAfter The reward cap after change
    event RewardCapChanged(uint128 rewardCapAfter);

    /// @notice Invalid caller
    error InvalidCaller(address caller);
    /// @notice Invalid argument
    error InvalidArgument();
    /// @notice Invalid pool
    error InvalidPool(IPool pool);
    /// @notice Invalid mint time
    /// @param mintTime The time of starting minting
    error InvalidMintTime(uint64 mintTime);
    /// @notice Invalid mining rate
    /// @param rate The rate of mining
    error InvalidMiningRate(uint256 rate);
    /// @notice Too many pools
    error TooManyPools();
    /// @notice Invalid reward cap
    error InvalidRewardCap();

    struct Config {
        uint32 liquidityRate;
        uint32 riskBufferFundLiquidityRate;
        uint32 referralTokenRate;
        uint32 referralParentTokenRate;
    }

    struct PoolReward {
        uint128 liquidity;
        uint128 liquidityRewardGrowthX64;
        uint128 referralLiquidity;
        uint128 referralTokenRewardGrowthX64;
        uint128 referralParentTokenRewardGrowthX64;
        uint128 referralPosition;
        uint128 referralTokenPositionRewardGrowthX64;
        uint128 referralParentTokenPositionRewardGrowthX64;
        uint128 riskBufferFundLiquidity;
        uint128 riskBufferFundRewardGrowthX64;
        uint128 rewardPerSecond;
        uint128 lastMintTime;
    }

    struct Reward {
        /// @dev The liquidity of risk buffer fund position or LP position
        uint128 liquidity;
        /// @dev The snapshot of `PoolReward.riskBufferFundRewardGrowthX64` or `PoolReward.liquidityRewardGrowthX64`
        uint128 rewardGrowthX64;
    }

    struct RewardWithPosition {
        /// @dev The total liquidity of all referees
        uint128 liquidity;
        /// @dev The snapshot of
        /// `PoolReward.referralTokenRewardGrowthX64` or `PoolReward.referralParentTokenRewardGrowthX64`
        uint128 rewardGrowthX64;
        /// @dev The total position value of all referees
        uint128 position;
        /// @dev The snapshot of
        /// `PoolReward.referralTokenPositionRewardGrowthX64` or `PoolReward.referralParentTokenPositionRewardGrowthX64`
        uint128 positionRewardGrowthX64;
    }

    struct ReferralReward {
        /// @dev Unclaimed reward amount
        uint256 rewardDebt;
        /// @dev Mapping of pool to referral reward
        mapping(IPool => RewardWithPosition) rewards;
    }

    struct RiskBufferFundReward {
        /// @dev Unclaimed reward amount
        uint256 rewardDebt;
        /// @dev Mapping of pool to risk buffer fund reward
        mapping(IPool => Reward) rewards;
    }

    struct LiquidityReward {
        /// @dev The bitwise representation of the pool index with existing LP position
        Bitmap bitmap;
        /// @dev Unclaimed reward amount
        uint256 rewardDebt;
        /// @dev Mapping of pool to liquidity reward
        mapping(IPool => Reward) rewards;
    }

    struct SidePosition {
        /// @dev Value of long position
        uint128 long;
        /// @dev Value of short position
        uint128 short;
    }

    struct Position {
        /// @dev The bitwise representation of the pool index with existing position
        Bitmap bitmap;
        /// @dev Mapping of pool to position value
        mapping(IPool => SidePosition) sidePositions;
    }

    /// @notice Get mining rate configuration
    /// @return liquidityRate The liquidity rate as a percentage of mining,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return riskBufferFundLiquidityRate The risk buffer fund liquidity rate as a percentage of mining,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return referralTokenRate The referral token rate as a percentage of mining,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return referralParentTokenRate The referral parent token rate as a percentage of mining,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    function config()
        external
        view
        returns (
            uint32 liquidityRate,
            uint32 riskBufferFundLiquidityRate,
            uint32 referralTokenRate,
            uint32 referralParentTokenRate
        );

    /// @notice Get the pool reward
    /// @param pool The address of the pool
    /// @return liquidity The sum of all liquidity in this pool
    /// @return liquidityRewardGrowthX64 The reward growth per unit of liquidity, as a Q64.64
    /// @return referralLiquidity The sum of all the referral liquidity
    /// @return referralTokenRewardGrowthX64 The reward growth per unit of referral token liquidity, as a Q64.64
    /// @return referralParentTokenRewardGrowthX64 The reward growth per unit of referral token parent liquidity,
    /// as a Q64.64
    /// @return referralPosition The sum of all the referral position liquidity
    /// @return referralTokenPositionRewardGrowthX64 The reward growth per unit of referral token position liquidity,
    /// as a Q64.64
    /// @return referralParentTokenPositionRewardGrowthX64 The reward growth per unit of referral token parent
    /// position, as a Q64.64
    /// @return riskBufferFundLiquidity The sum of the liquidity of all risk buffer fund
    /// @return riskBufferFundRewardGrowthX64 The reward growth per unit of risk buffer fund liquidity, as a Q64.64
    /// @return rewardPerSecond The amount minted per second
    /// @return lastMintTime The Last mint time
    function poolRewards(
        IPool pool
    )
        external
        view
        returns (
            uint128 liquidity,
            uint128 liquidityRewardGrowthX64,
            uint128 referralLiquidity,
            uint128 referralTokenRewardGrowthX64,
            uint128 referralParentTokenRewardGrowthX64,
            uint128 referralPosition,
            uint128 referralTokenPositionRewardGrowthX64,
            uint128 referralParentTokenPositionRewardGrowthX64,
            uint128 riskBufferFundLiquidity,
            uint128 riskBufferFundRewardGrowthX64,
            uint128 rewardPerSecond,
            uint128 lastMintTime
        );

    /// @notice Collect the liquidity reward
    /// @param pools The pool addresses
    /// @param account The owner of the liquidity reward
    /// @param receiver The address to receive the reward
    /// @return rewardDebt The amount of liquidity reward received
    function collectLiquidityRewardBatch(
        IPool[] calldata pools,
        address account,
        address receiver
    ) external returns (uint256 rewardDebt);

    /// @notice Collect the risk buffer fund reward
    /// @param pools The pool addresses
    /// @param account The owner of the risk buffer fund reward
    /// @param receiver The address to receive the reward
    /// @return rewardDebt The amount of risk buffer fund reward received
    function collectRiskBufferFundRewardBatch(
        IPool[] calldata pools,
        address account,
        address receiver
    ) external returns (uint256 rewardDebt);

    /// @notice Collect the referral reward
    /// @param pools The pool addresses
    /// @param referralTokens The IDs of the referral tokens
    /// @param receiver The address to receive the referral reward
    /// @return rewardDebt The amount of the referral reward
    function collectReferralRewardBatch(
        IPool[] calldata pools,
        uint256[] calldata referralTokens,
        address receiver
    ) external returns (uint256 rewardDebt);

    /// @notice Set reward data for the pool
    /// @param pools The pool addresses
    /// @param rewardsPerSecond The EQU amount minted per second for pools
    function setPoolsReward(IPool[] calldata pools, uint128[] calldata rewardsPerSecond) external;

    /// @notice Set configuration information
    /// @param config The configuration
    function setConfig(Config memory config) external;

    /// @notice Set the reward cap
    /// @param rewardCap The reward cap
    function setRewardCap(uint128 rewardCap) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

abstract contract Governable {
    address private _gov;
    address private _pendingGov;

    event ChangeGovStarted(address indexed previousGov, address indexed newGov);
    event GovChanged(address indexed previousGov, address indexed newGov);

    error Forbidden();

    modifier onlyGov() {
        _onlyGov();
        _;
    }

    constructor() {
        _changeGov(msg.sender);
    }

    function gov() public view virtual returns (address) {
        return _gov;
    }

    function pendingGov() public view virtual returns (address) {
        return _pendingGov;
    }

    function changeGov(address _newGov) public virtual onlyGov {
        _pendingGov = _newGov;
        emit ChangeGovStarted(_gov, _newGov);
    }

    function acceptGov() public virtual {
        if (msg.sender != _pendingGov) revert Forbidden();

        delete _pendingGov;
        _changeGov(msg.sender);
    }

    function _changeGov(address _newGov) internal virtual {
        address previousGov = _gov;
        _gov = _newGov;
        emit GovChanged(previousGov, _newGov);
    }

    function _onlyGov() internal view {
        if (msg.sender != _gov) revert Forbidden();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

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
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`.
     * If `token` returns no value,
     * non-reverting calls are assumed to be successful.
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
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
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
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Plugin Manager Interface
/// @notice The interface defines the functions to manage plugins
interface IPluginManager {
    /// @notice Emitted when a new plugin is registered
    /// @param plugin The registered plugin
    event PluginRegistered(address indexed plugin);

    /// @notice Emitted when a plugin is approved
    /// @param account The account that approved the plugin
    /// @param plugin The approved plugin
    event PluginApproved(address indexed account, address indexed plugin);

    /// @notice Emitted when a plugin is revoked
    /// @param account The account that revoked the plugin
    /// @param plugin The revoked plugin
    event PluginRevoked(address indexed account, address indexed plugin);

    /// @notice Emitted when a new liquidator is registered
    /// @param liquidator The registered liquidator
    event LiquidatorRegistered(address indexed liquidator);

    /// @notice Plugin is already registered
    error PluginAlreadyRegistered(address plugin);
    /// @notice Plugin is not registered
    error PluginNotRegistered(address plugin);
    /// @notice Plugin is already approved
    error PluginAlreadyApproved(address sender, address plugin);
    /// @notice Plugin is not approved
    error PluginNotApproved(address sender, address plugin);
    /// @notice Liquidator is already registered
    error LiquidatorAlreadyRegistered(address liquidator);

    /// @notice Register a new plugin
    /// @dev The call will fail if the caller is not the governor or the plugin is already registered
    /// @param plugin The plugin to register
    function registerPlugin(address plugin) external;

    /// @notice Checks if a plugin is registered
    /// @param plugin The plugin to check
    /// @return True if the plugin is registered, false otherwise
    function registeredPlugins(address plugin) external view returns (bool);

    /// @notice Approve a plugin
    /// @dev The call will fail if the plugin is not registered or already approved
    /// @param plugin The plugin to approve
    function approvePlugin(address plugin) external;

    /// @notice Revoke approval for a plugin
    /// @dev The call will fail if the plugin is not approved
    /// @param plugin The plugin to revoke
    function revokePlugin(address plugin) external;

    /// @notice Checks if a plugin is approved for an account
    /// @param account The account to check
    /// @param plugin The plugin to check
    /// @return True if the plugin is approved for the account, false otherwise
    function isPluginApproved(address account, address plugin) external view returns (bool);

    /// @notice Register a new liquidator
    /// @dev The call will fail if the caller if not the governor or the liquidator is already registered
    /// @param liquidator The liquidator to register
    function registerLiquidator(address liquidator) external;

    /// @notice Checks if a liquidator is registered
    /// @param liquidator The liquidator to check
    /// @return True if the liquidator is registered, false otherwise
    function isRegisteredLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../governance/Governable.sol";
import "./interfaces/IPluginManager.sol";

abstract contract PluginManager is IPluginManager, Governable {
    /// @inheritdoc IPluginManager
    mapping(address => bool) public override registeredPlugins;
    mapping(address => bool) private registeredLiquidators;
    mapping(address => mapping(address => bool)) private pluginApprovals;

    /// @inheritdoc IPluginManager
    function registerPlugin(address _plugin) external override onlyGov {
        if (registeredPlugins[_plugin]) revert PluginAlreadyRegistered(_plugin);

        registeredPlugins[_plugin] = true;

        emit PluginRegistered(_plugin);
    }

    /// @inheritdoc IPluginManager
    function approvePlugin(address _plugin) external override {
        if (pluginApprovals[msg.sender][_plugin]) revert PluginAlreadyApproved(msg.sender, _plugin);

        if (!registeredPlugins[_plugin]) revert PluginNotRegistered(_plugin);

        pluginApprovals[msg.sender][_plugin] = true;
        emit PluginApproved(msg.sender, _plugin);
    }

    /// @inheritdoc IPluginManager
    function revokePlugin(address _plugin) external {
        if (!pluginApprovals[msg.sender][_plugin]) revert PluginNotApproved(msg.sender, _plugin);

        delete pluginApprovals[msg.sender][_plugin];
        emit PluginRevoked(msg.sender, _plugin);
    }

    /// @inheritdoc IPluginManager
    function isPluginApproved(address _account, address _plugin) public view override returns (bool) {
        return pluginApprovals[_account][_plugin];
    }

    /// @inheritdoc IPluginManager
    function registerLiquidator(address _liquidator) external override onlyGov {
        if (registeredLiquidators[_liquidator]) revert LiquidatorAlreadyRegistered(_liquidator);

        registeredLiquidators[_liquidator] = true;

        emit LiquidatorRegistered(_liquidator);
    }

    /// @inheritdoc IPluginManager
    function isRegisteredLiquidator(address _liquidator) public view override returns (bool) {
        return registeredLiquidators[_liquidator];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.21;

import "./Router.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RewardCollector is Multicall {
    using SafeMath for uint256;

    Router public immutable router;
    IERC20 public immutable EQU;
    IEFC public immutable EFC;

    error InvalidCaller(address caller, address requiredCaller);
    error InsufficientBalance(uint256 amount, uint256 requiredAmount);

    constructor(Router _router, IERC20 _EQU, IEFC _EFC) {
        (router, EQU, EFC) = (_router, _EQU, _EFC);
    }

    function sweepToken(
        IERC20 _token,
        uint256 _amountMinimum,
        address _receiver
    ) external virtual returns (uint256 amount) {
        amount = _token.balanceOf(address(this));
        if (amount < _amountMinimum) revert InsufficientBalance(amount, _amountMinimum);

        SafeERC20.safeTransfer(_token, _receiver, amount);
    }

    function collectReferralFeeBatch(
        IPool[] calldata _pools,
        uint256[] calldata _referralTokens
    ) external virtual returns (uint256 amount) {
        _validateOwner(_referralTokens);

        IPool pool;
        uint256 poolsLen = _pools.length;
        uint256 tokensLen;
        for (uint256 i; i < poolsLen; ++i) {
            (pool, tokensLen) = (_pools[i], _referralTokens.length);
            for (uint256 j; j < tokensLen; ++j)
                amount += router.pluginCollectReferralFee(pool, _referralTokens[j], address(this));
        }
    }

    function collectFarmLiquidityRewardBatch(IPool[] calldata _pools) external virtual returns (uint256 rewardDebt) {
        rewardDebt = router.pluginCollectFarmLiquidityRewardBatch(_pools, msg.sender, address(this));
    }

    function collectFarmRiskBufferFundRewardBatch(
        IPool[] calldata _pools
    ) external virtual returns (uint256 rewardDebt) {
        rewardDebt = router.pluginCollectFarmRiskBufferFundRewardBatch(_pools, msg.sender, address(this));
    }

    function collectFarmReferralRewardBatch(
        IPool[] calldata _pools,
        uint256[] calldata _referralTokens
    ) external virtual returns (uint256 rewardDebt) {
        _validateOwner(_referralTokens);
        return router.pluginCollectFarmReferralRewardBatch(_pools, _referralTokens, address(this));
    }

    function collectStakingRewardBatch(uint256[] calldata _ids) external virtual returns (uint256 rewardDebt) {
        rewardDebt = router.pluginCollectStakingRewardBatch(msg.sender, address(this), _ids);
    }

    function collectV3PosStakingRewardBatch(uint256[] calldata _ids) external virtual returns (uint256 rewardDebt) {
        rewardDebt = router.pluginCollectV3PosStakingRewardBatch(msg.sender, address(this), _ids);
    }

    function collectArchitectRewardBatch(uint256[] calldata _tokenIDs) external virtual returns (uint256 rewardDebt) {
        _validateOwner(_tokenIDs);
        rewardDebt = router.pluginCollectArchitectRewardBatch(address(this), _tokenIDs);
    }

    function _validateOwner(uint256[] calldata _referralTokens) internal view virtual {
        (address caller, uint256 tokensLen) = (msg.sender, _referralTokens.length);
        for (uint256 i; i < tokensLen; ++i) {
            if (EFC.ownerOf(_referralTokens[i]) != caller)
                revert InvalidCaller(caller, EFC.ownerOf(_referralTokens[i]));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.21;

import "./PluginManager.sol";
import "../libraries/SafeERC20.sol";
import "../tokens/interfaces/IEFC.sol";
import "../farming/interfaces/IRewardFarm.sol";
import "../staking/interfaces/IFeeDistributor.sol";

contract Router is PluginManager {
    IEFC public immutable EFC;
    IRewardFarm public immutable rewardFarm;
    IFeeDistributor public immutable feeDistributor;

    /// @notice Caller is not a plugin or not approved
    error CallerUnauthorized();
    /// @notice Owner mismatch
    error OwnerMismatch(address owner, address expectedOwner);

    constructor(IEFC _EFC, IRewardFarm _rewardFarm, IFeeDistributor _feeDistributor) {
        (EFC, rewardFarm, feeDistributor) = (_EFC, _rewardFarm, _feeDistributor);
    }

    /// @notice Transfers `_amount` of `_token` from `_from` to `_to`
    /// @param _token The address of the ERC20 token
    /// @param _from The address to transfer the tokens from
    /// @param _to The address to transfer the tokens to
    /// @param _amount The amount of tokens to transfer
    function pluginTransfer(IERC20 _token, address _from, address _to, uint256 _amount) external {
        _onlyPluginApproved(_from);
        SafeERC20.safeTransferFrom(_token, _from, _to, _amount);
    }

    /// @notice Transfers an NFT token from `_from` to `_to`
    /// @param _token The address of the ERC721 token to transfer
    /// @param _from The address to transfer the NFT from
    /// @param _to The address to transfer the NFT to
    /// @param _tokenId The ID of the NFT token to transfer
    function pluginTransferNFT(IERC721 _token, address _from, address _to, uint256 _tokenId) external {
        _onlyPluginApproved(_from);
        _token.safeTransferFrom(_from, _to, _tokenId);
    }

    /// @notice Open a new liquidity position
    /// @param _pool The pool in which to open liquidity position
    /// @param _account The owner of the position
    /// @param _margin The margin of the position
    /// @param _liquidity The liquidity (value) of the position
    /// @return positionID The position ID
    function pluginOpenLiquidityPosition(
        IPool _pool,
        address _account,
        uint128 _margin,
        uint128 _liquidity
    ) external returns (uint96 positionID) {
        _onlyPluginApproved(_account);
        return _pool.openLiquidityPosition(_account, _margin, _liquidity);
    }

    /// @notice Close a liquidity position
    /// @param _pool The pool in which to close liquidity position
    /// @param _positionID The position ID
    /// @param _receiver The address to receive the margin at the time of closing
    function pluginCloseLiquidityPosition(IPool _pool, uint96 _positionID, address _receiver) external {
        _onlyPluginApproved(_pool.liquidityPositionAccount(_positionID));
        _pool.closeLiquidityPosition(_positionID, _receiver);
    }

    /// @notice Adjust the margin of a liquidity position
    /// @param _pool The pool in which to adjust liquidity position margin
    /// @param _positionID The position ID
    /// @param _marginDelta The change in margin, positive for increasing margin and negative for decreasing margin
    /// @param _receiver The address to receive the margin when the margin is decreased
    function pluginAdjustLiquidityPositionMargin(
        IPool _pool,
        uint96 _positionID,
        int128 _marginDelta,
        address _receiver
    ) external {
        _onlyPluginApproved(_pool.liquidityPositionAccount(_positionID));
        _pool.adjustLiquidityPositionMargin(_positionID, _marginDelta, _receiver);
    }

    /// @notice Increase the liquidity of a risk buffer fund position
    /// @param _pool The pool in which to increase liquidity
    /// @param _account The owner of the position
    /// @param _liquidityDelta The increase in liquidity
    function pluginIncreaseRiskBufferFundPosition(IPool _pool, address _account, uint128 _liquidityDelta) external {
        _onlyPluginApproved(_account);
        _pool.increaseRiskBufferFundPosition(_account, _liquidityDelta);
    }

    /// @notice Decrease the liquidity of a risk buffer fund position
    /// @param _pool The pool in which to decrease liquidity
    /// @param _account The owner of the position
    /// @param _liquidityDelta The decrease in liquidity
    /// @param _receiver The address to receive the liquidity when it is decreased
    function pluginDecreaseRiskBufferFundPosition(
        IPool _pool,
        address _account,
        uint128 _liquidityDelta,
        address _receiver
    ) external {
        _onlyPluginApproved(_account);
        _pool.decreaseRiskBufferFundPosition(_account, _liquidityDelta, _receiver);
    }

    /// @notice Increase the margin/liquidity (value) of a position
    /// @param _pool The pool in which to increase position
    /// @param _account The owner of the position
    /// @param _side The side of the position (Long or Short)
    /// @param _marginDelta The increase in margin, which can be 0
    /// @param _sizeDelta The increase in size, which can be 0
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    function pluginIncreasePosition(
        IPool _pool,
        address _account,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta
    ) external returns (uint160 tradePriceX96) {
        _onlyPluginApproved(_account);
        return _pool.increasePosition(_account, _side, _marginDelta, _sizeDelta);
    }

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @param _pool The pool in which to decrease position
    /// @param _account The owner of the position
    /// @param _side The side of the position (Long or Short)
    /// @param _marginDelta The decrease in margin, which can be 0
    /// @param _sizeDelta The decrease in size, which can be 0
    /// @param _receiver The address to receive the margin
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    function pluginDecreasePosition(
        IPool _pool,
        address _account,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta,
        address _receiver
    ) external returns (uint160 tradePriceX96) {
        _onlyPluginApproved(_account);
        return _pool.decreasePosition(_account, _side, _marginDelta, _sizeDelta, _receiver);
    }

    /// @notice Close a position by the liquidator
    /// @param _pool The pool in which to close position
    /// @param _account The owner of the position
    /// @param _side The side of the position (Long or Short)
    /// @param _sizeDelta The decrease in size
    /// @param _receiver The address to receive the margin
    function pluginClosePositionByLiquidator(
        IPool _pool,
        address _account,
        Side _side,
        uint128 _sizeDelta,
        address _receiver
    ) external {
        _onlyLiquidator();
        _pool.decreasePosition(_account, _side, 0, _sizeDelta, _receiver);
    }

    /// @notice Collect the referral fee
    /// @param _pool The pool in which to collect referral fee
    /// @param _referralToken The id of the referral token
    /// @param _receiver The address to receive the referral fee
    /// @return The amount of referral fee received
    function pluginCollectReferralFee(
        IPool _pool,
        uint256 _referralToken,
        address _receiver
    ) external returns (uint256) {
        _onlyPluginApproved(EFC.ownerOf(_referralToken));
        return _pool.collectReferralFee(_referralToken, _receiver);
    }

    /// @notice Collect the liquidity reward
    /// @param _pools The pools in which to collect farm liquidity reward
    /// @param _owner The address of the reward owner
    /// @param _receiver The address to receive the reward
    /// @return rewardDebt The amount of liquidity reward received
    function pluginCollectFarmLiquidityRewardBatch(
        IPool[] calldata _pools,
        address _owner,
        address _receiver
    ) external returns (uint256 rewardDebt) {
        _onlyPluginApproved(_owner);
        return rewardFarm.collectLiquidityRewardBatch(_pools, _owner, _receiver);
    }

    /// @notice Collect the risk buffer fund reward
    /// @param _pools The pools in which to collect farm risk buffer fund reward
    /// @param _owner The address of the reward owner
    /// @param _receiver The address to receive the reward
    /// @return rewardDebt The amount of risk buffer fund reward received
    function pluginCollectFarmRiskBufferFundRewardBatch(
        IPool[] calldata _pools,
        address _owner,
        address _receiver
    ) external returns (uint256 rewardDebt) {
        _onlyPluginApproved(_owner);
        return rewardFarm.collectRiskBufferFundRewardBatch(_pools, _owner, _receiver);
    }

    /// @notice Collect the farm referral reward
    /// @param _pools The pools in which to collect farm risk buffer fund reward
    /// @param _referralTokens The IDs of the referral tokens
    /// @param _receiver The address to receive the referral reward
    /// @return rewardDebt The amount of the referral reward received
    function pluginCollectFarmReferralRewardBatch(
        IPool[] calldata _pools,
        uint256[] calldata _referralTokens,
        address _receiver
    ) external returns (uint256 rewardDebt) {
        uint256 tokensLen = _referralTokens.length;
        require(tokensLen > 0);

        address owner = EFC.ownerOf(_referralTokens[0]);
        _onlyPluginApproved(owner);
        for (uint256 i = 1; i < tokensLen; ++i)
            if (EFC.ownerOf(_referralTokens[i]) != owner) revert OwnerMismatch(EFC.ownerOf(_referralTokens[i]), owner);

        return rewardFarm.collectReferralRewardBatch(_pools, _referralTokens, _receiver);
    }

    /// @notice Collect EQU staking reward tokens
    /// @param _owner The staker
    /// @param _receiver The address used to receive staking reward tokens
    /// @param _ids Index of EQU tokens staking information that need to be collected
    /// @return rewardDebt The amount of staking reward tokens received
    function pluginCollectStakingRewardBatch(
        address _owner,
        address _receiver,
        uint256[] calldata _ids
    ) external returns (uint256 rewardDebt) {
        _onlyPluginApproved(_owner);
        return feeDistributor.collectBatchByRouter(_owner, _receiver, _ids);
    }

    /// @notice Collect Uniswap V3 positions NFT staking reward tokens
    /// @param _owner The Staker
    /// @param _receiver The address used to receive staking reward tokens
    /// @param _ids Index of Uniswap V3 positions NFTs staking information that need to be collected
    /// @return rewardDebt The amount of staking reward tokens received
    function pluginCollectV3PosStakingRewardBatch(
        address _owner,
        address _receiver,
        uint256[] calldata _ids
    ) external returns (uint256 rewardDebt) {
        _onlyPluginApproved(_owner);
        return feeDistributor.collectV3PosBatchByRouter(_owner, _receiver, _ids);
    }

    /// @notice Collect the architect reward
    /// @param _receiver The address used to receive rewards
    /// @param _tokenIDs The IDs of the Architect-type NFT
    /// @return rewardDebt The amount of architect rewards received
    function pluginCollectArchitectRewardBatch(
        address _receiver,
        uint256[] calldata _tokenIDs
    ) external returns (uint256 rewardDebt) {
        uint256 idsLen = _tokenIDs.length;
        require(idsLen > 0);

        address owner = EFC.ownerOf(_tokenIDs[0]);
        _onlyPluginApproved(owner);
        for (uint256 i = 1; i < idsLen; ++i)
            if (EFC.ownerOf(_tokenIDs[i]) != owner) revert OwnerMismatch(EFC.ownerOf(_tokenIDs[i]), owner);

        return feeDistributor.collectArchitectBatchByRouter(_receiver, _tokenIDs);
    }

    function _onlyPluginApproved(address _account) internal view {
        if (!isPluginApproved(_account, msg.sender)) revert CallerUnauthorized();
    }

    function _onlyLiquidator() internal view {
        if (!isRegisteredLiquidator(msg.sender)) revert CallerUnauthorized();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeDistributor {
    /// @notice Emitted when EQU tokens are staked
    /// @param sender The address to apply for staking
    /// @param account Which address to stake to
    /// @param id Index of EQU tokens staking information
    /// @param amount The amount of EQU tokens that already staked
    /// @param period Lockup period
    event Staked(address indexed sender, address indexed account, uint256 indexed id, uint256 amount, uint16 period);

    /// @notice Emitted when Uniswap V3 positions NFTs are staked
    /// @param sender The address to apply for staking
    /// @param account Which address to stake to
    /// @param id Index of Uniswap V3 positions NFTs staking information
    /// @param amount The amount of Uniswap V3 positions NFT converted into EQU tokens that already staked
    /// @param period Lockup period
    event V3PosStaked(
        address indexed sender,
        address indexed account,
        uint256 indexed id,
        uint256 amount,
        uint16 period
    );

    /// @notice Emitted when EQU tokens are unstaked
    /// @param owner The address to apply for unstaking
    /// @param receiver The address used to receive the stake tokens
    /// @param id Index of EQU tokens staking information
    /// @param amount0 The amount of EQU tokens that already unstaked
    /// @param amount1 The amount of staking rewards received
    event Unstaked(
        address indexed owner,
        address indexed receiver,
        uint256 indexed id,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when Uniswap V3 positions NFTs are unstaked
    /// @param owner The address to apply for unstaking
    /// @param receiver The address used to receive the Uniswap V3 positions NFT
    /// @param id Index of Uniswap V3 positions NFTs staking information
    /// @param amount0 The amount of Uniswap V3 positions NFT converted into EQU tokens that already unstaked
    /// @param amount1 The amount of staking rewards received
    event V3PosUnstaked(
        address indexed owner,
        address indexed receiver,
        uint256 indexed id,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when claiming stake rewards
    /// @param owner The address to apply for claiming staking rewards
    /// @param receiver The address used to receive staking rewards
    /// @param id Index of EQU tokens staking information
    /// @param amount The amount of staking rewards received
    event Collected(address indexed owner, address indexed receiver, uint256 indexed id, uint256 amount);

    /// @notice Emitted when claiming stake rewards
    /// @param owner The address to apply for claiming staking rewards
    /// @param receiver The address used to receive staking rewards
    /// @param id Index of Uniswap V3 positions NFTs staking information
    /// @param amount The amount of staking rewards received
    event V3PosCollected(address indexed owner, address indexed receiver, uint256 indexed id, uint256 amount);

    /// @notice Emitted when claiming Architect-type NFT rewards
    /// @param receiver The address used to receive rewards
    /// @param tokenID The ID of the Architect-type NFT
    /// @param amount The amount of rewards received
    event ArchitectCollected(address indexed receiver, uint256 indexed tokenID, uint256 amount);

    /// @notice Emitted when deposit staking reward tokens
    /// @param amount The amount of staking reward tokens deposited
    /// @param equFeeAmount The amount of reward tokens allocated to the EQU
    /// @param architectFeeAmount The amount of reward tokens allocated to the Architect-type NFT pool
    /// @param perShareGrowthAfterX64 The adjusted `perShareGrowthX64`, as a Q96.64
    /// @param architectPerShareGrowthAfterX64 The adjusted `architectPerShareGrowthX64`, as a Q96.64
    event FeeDeposited(
        uint256 amount,
        uint256 equFeeAmount,
        uint256 architectFeeAmount,
        uint160 perShareGrowthAfterX64,
        uint160 architectPerShareGrowthAfterX64
    );

    /// @notice Emitted when the lockup periods and lockup multipliers are set
    /// @param lockupRewardMultiplierParameters The list of LockupRewardMultiplierParameter
    event LockupRewardMultipliersSet(LockupRewardMultiplierParameter[] lockupRewardMultiplierParameters);

    /// @notice The number of Architect-type NFT that has been mined is 0
    /// or the EQU tokens that Uniswap V3 positions NFTs converted into total staked amount is 0.
    error DepositConditionNotMet();
    /// @notice Invalid caller
    error InvalidCaller(address caller);
    /// @notice Invalid NFT owner
    error InvalidNFTOwner(address owner, uint256 tokenID);
    /// @notice Invalid lockup period
    error InvalidLockupPeriod(uint16 period);
    /// @notice Invalid StakeID
    error InvalidStakeID(uint256 id);
    /// @notice Not yet reached the unlocking time
    error NotYetReachedTheUnlockingTime(uint256 id);
    /// @notice Deposit amount is greater than the transfer amount
    error DepositAmountIsGreaterThanTheTransfer(uint256 depositAmount, uint256 balance);
    /// @notice The NFT is not part of the EQU-WETH pool
    error InvalidUniswapV3PositionNFT(address token0, address token1);
    /// @notice The exchangeable amount of EQU is 0
    error ExchangeableEQUAmountIsZero();
    /// @notice Invalid Uniswap V3 fee
    error InvalidUniswapV3Fee(uint24 fee);
    /// @notice The price range of the Uniswap V3 position is not full range
    error RequireFullRangePosition(int24 tickLower, int24 tickUpper, int24 tickSpacing);

    struct StakeInfo {
        uint256 amount;
        uint64 lockupStartTime;
        uint16 multiplier;
        uint16 period;
        uint160 perShareGrowthX64;
    }

    struct LockupRewardMultiplierParameter {
        uint16 period;
        uint16 multiplier;
    }

    /// @notice Get the fee token balance
    /// @return balance The balance of the fee token
    function feeBalance() external view returns (uint96 balance);

    /// @notice Get the fee token
    /// @return token The fee token
    function feeToken() external view returns (IERC20 token);

    /// @notice Get the total amount with multiplier of staked EQU tokens
    /// @return amount The total amount with multiplier of staked EQU tokens
    function totalStakedWithMultiplier() external view returns (uint256 amount);

    /// @notice Get the accumulated staking rewards growth per share
    /// @return perShareGrowthX64 The accumulated staking rewards growth per share, as a Q96.64
    function perShareGrowthX64() external view returns (uint160 perShareGrowthX64);

    /// @notice Get EQU staking information
    /// @param account The staker of EQU tokens
    /// @param stakeID Index of EQU tokens staking information
    /// @return amount The amount of EQU tokens that already staked
    /// @return lockupStartTime Lockup start time
    /// @return multiplier Lockup reward multiplier
    /// @return period Lockup period
    /// @return perShareGrowthX64 The accumulated staking rewards growth per share, as a Q96.64
    function stakeInfos(
        address account,
        uint256 stakeID
    )
        external
        view
        returns (uint256 amount, uint64 lockupStartTime, uint16 multiplier, uint16 period, uint160 perShareGrowthX64);

    /// @notice Get Uniswap V3 positions NFTs staking information
    /// @param account The staker of Uniswap V3 positions NFTs
    /// @param stakeID Index of Uniswap V3 positions NFTs staking information
    /// @return amount The amount of EQU tokens that Uniswap V3 positions NFTs converted into that already staked
    /// @return lockupStartTime Lockup start time
    /// @return multiplier Lockup reward multiplier
    /// @return period Lockup period
    /// @return perShareGrowthX64 The accumulated staking rewards growth per share, as a Q96.64
    function v3PosStakeInfos(
        address account,
        uint256 stakeID
    )
        external
        view
        returns (uint256 amount, uint64 lockupStartTime, uint16 multiplier, uint16 period, uint160 perShareGrowthX64);

    /// @notice Get withdrawal time period
    /// @return period Withdrawal time period
    function withdrawalPeriod() external view returns (uint16 period);

    /// @notice Get lockup multiplier based on lockup period
    /// @param period Lockup period
    /// @return multiplier Lockup multiplier
    function lockupRewardMultipliers(uint16 period) external view returns (uint16 multiplier);

    /// @notice The number of Architect-type NFTs minted
    /// @return quantity The number of Architect-type NFTs minted
    function mintedArchitects() external view returns (uint16 quantity);

    /// @notice Get the accumulated reward growth for each Architect-type NFT
    /// @return perShareGrowthX64 The accumulated reward growth for each Architect-type NFT, as a Q96.64
    function architectPerShareGrowthX64() external view returns (uint160 perShareGrowthX64);

    /// @notice Get the accumulated reward growth for each Architect-type NFT
    /// @param tokenID The ID of the Architect-type NFT
    /// @return perShareGrowthX64 The accumulated reward growth for each Architect-type NFT, as a Q96.64
    function architectPerShareGrowthX64s(uint256 tokenID) external view returns (uint160 perShareGrowthX64);

    /// @notice Set lockup reward multiplier
    /// @param lockupRewardMultiplierParameters The list of LockupRewardMultiplierParameter
    function setLockupRewardMultipliers(
        LockupRewardMultiplierParameter[] calldata lockupRewardMultiplierParameters
    ) external;

    /// @notice Deposite staking reward tokens
    /// @param amount The amount of reward tokens deposited
    function depositFee(uint256 amount) external;

    /// @notice Stake EQU
    /// @param amount The amount of EQU tokens that need to be staked
    /// @param account Which address to stake to
    /// @param period Lockup period
    function stake(uint256 amount, address account, uint16 period) external;

    /// @notice Stake Uniswap V3 positions NFT
    /// @param id The ID of the Uniswap V3 positions NFT
    /// @param account Which address to stake to
    /// @param period Lockup period
    function stakeV3Pos(uint256 id, address account, uint16 period) external;

    /// @notice Unstake EQU
    /// @param ids Indexs of EQU tokens staking information that need to be unstaked
    /// @param receiver The address used to receive the staked tokens
    /// @return rewardAmount The amount of staking reward tokens received
    function unstake(uint256[] calldata ids, address receiver) external returns (uint256 rewardAmount);

    /// @notice Unstake Uniswap V3 positions NFT
    /// @param ids Indexs of Uniswap V3 positions NFTs staking information that need to be unstaked
    /// @param receiver The address used to receive the Uniswap V3 positions NFTs
    /// @return rewardAmount The amount of staking reward tokens received
    function unstakeV3Pos(uint256[] calldata ids, address receiver) external returns (uint256 rewardAmount);

    /// @notice Collect EQU staking rewards through router
    /// @param owner The Staker
    /// @param receiver The address used to receive staking rewards
    /// @param ids Index of EQU tokens staking information that need to be collected
    /// @return rewardAmount The amount of staking reward tokens received
    function collectBatchByRouter(
        address owner,
        address receiver,
        uint256[] calldata ids
    ) external returns (uint256 rewardAmount);

    /// @notice Collect Uniswap V3 positions NFT staking rewards through router
    /// @param owner The Staker
    /// @param receiver The address used to receive staking reward tokens
    /// @param ids Index of Uniswap V3 positions NFTs staking information that need to be collected
    /// @return rewardAmount The amount of staking reward tokens received
    function collectV3PosBatchByRouter(
        address owner,
        address receiver,
        uint256[] calldata ids
    ) external returns (uint256 rewardAmount);

    /// @notice Collect rewards for architect-type NFTs through router
    /// @param receiver The address used to receive staking reward tokens
    /// @param tokenIDs The IDs of the Architect-type NFT
    /// @return rewardAmount The amount of staking reward tokens received
    function collectArchitectBatchByRouter(
        address receiver,
        uint256[] calldata tokenIDs
    ) external returns (uint256 rewardAmount);

    /// @notice Collect EQU staking rewards
    /// @param receiver The address used to receive staking reward tokens
    /// @param ids Index of EQU tokens staking information that need to be collected
    /// @return rewardAmount The amount of staking reward tokens received
    function collectBatch(address receiver, uint256[] calldata ids) external returns (uint256 rewardAmount);

    /// @notice Collect Uniswap V3 positions NFT staking rewards
    /// @param receiver The address used to receive staking reward tokens
    /// @param ids Index of Uniswap V3 positions NFTs staking information that need to be collected
    /// @return rewardAmount The amount of staking reward tokens received
    function collectV3PosBatch(address receiver, uint256[] calldata ids) external returns (uint256 rewardAmount);

    /// @notice Collect rewards for architect-type NFTs
    /// @param receiver The address used to receive rewards
    /// @param tokenIDs The IDs of the Architect-type NFT
    /// @return rewardAmount The amount of staking reward tokens received
    function collectArchitectBatch(
        address receiver,
        uint256[] calldata tokenIDs
    ) external returns (uint256 rewardAmount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Interface for the IEFC contract
/// @notice This contract is used to register referral codes and bind them to users
interface IEFC is IERC721 {
    /// @notice Emitted when a referral code is registered
    /// @param referrer The address of the user who registered the code
    /// @param code The code to register
    /// @param tokenId The id of the token to register the code for
    event CodeRegistered(address indexed referrer, uint256 indexed tokenId, string code);

    /// @notice Emitted when a referral code is bound
    /// @param referee The address of the user who bound the code
    /// @param code The code to bind
    /// @param tokenIdBefore The id of the token before the code is bound
    /// @param tokenIdAfter The id of the token after the code is bound
    event CodeBound(address indexed referee, string code, uint256 tokenIdBefore, uint256 tokenIdAfter);

    /// @notice Param cap is too large
    /// @param capArchitect Cap of architect can be minted
    /// @param capConnector Cap of connector can be minted
    error CapTooLarge(uint256 capArchitect, uint256 capConnector);

    /// @notice Token is not member
    /// @param tokenId The tokenId
    error NotMemberToken(uint256 tokenId);

    /// @notice Token is not connector
    /// @param tokenId The tokenId
    error NotConnectorToken(uint256 tokenId);

    /// @notice Cap exceeded
    /// @param cap The cap
    error CapExceeded(uint256 cap);

    /// @notice Invalid code
    error InvalidCode();

    /// @notice Caller is not the owner
    /// @param owner The owner
    error CallerIsNotOwner(address owner);

    /// @notice Code is already registered
    /// @param code The code
    error CodeAlreadyRegistered(string code);

    /// @notice Code is not registered
    /// @param code The code
    error CodeNotRegistered(string code);

    /// @notice Set the base URI of nft assets
    /// @param baseURI Base URI for NFTs
    function setBaseURI(string calldata baseURI) external;

    /// @notice Get the token for a code
    /// @param code The code to get the token for
    /// @return tokenId The id of the token for the code
    function codeTokens(string calldata code) external view returns (uint256 tokenId);

    /// @notice Get the member and connector token id who referred the referee
    /// @param referee The address of the referee
    /// @return memberTokenId The token id of the member
    /// @return connectorTokenId The token id of the connector
    function referrerTokens(address referee) external view returns (uint256 memberTokenId, uint256 connectorTokenId);

    /// @notice Register a referral code for the referrer
    /// @param tokenId The id of the token to register the code for
    /// @param code The code to register
    function registerCode(uint256 tokenId, string calldata code) external;

    /// @notice Bind a referral code for the referee
    /// @param code The code to bind
    function bindCode(string calldata code) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "solady/src/utils/LibBit.sol";

type Bitmap is uint256;

using {flip, searchNextPosition} for Bitmap global;

/// @dev Flip the bit at the specified position in the given bitmap
/// @param self The original bitmap
/// @param position The position of the bit to be flipped
/// @return The updated bitmap after flipping the specified bit
function flip(Bitmap self, uint8 position) pure returns (Bitmap) {
    return Bitmap.wrap(Bitmap.unwrap(self) ^ (1 << position));
}

/// @dev Search for the next position in a bitmap starting from a given index
/// @param self The bitmap to search within
/// @param startInclusive The index to start the search from (inclusive)
/// @return next The next position found in the bitmap
/// @return found A boolean indicating whether the next position was found or not
function searchNextPosition(Bitmap self, uint8 startInclusive) pure returns (uint8 next, bool found) {
    uint256 mask = ~uint256(0) << startInclusive;
    uint256 masked = Bitmap.unwrap(self) & mask;
    return masked == 0 ? (0, false) : (uint8(LibBit.ffs(masked)), true);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

Side constant LONG = Side.wrap(1);
Side constant SHORT = Side.wrap(2);

type Side is uint8;

error InvalidSide(Side side);

using {requireValid, isLong, isShort, flip, eq as ==} for Side global;

function requireValid(Side self) pure {
    if (!isLong(self) && !isShort(self)) revert InvalidSide(self);
}

function isLong(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(LONG);
}

function isShort(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(SHORT);
}

function eq(Side self, Side other) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(other);
}

function flip(Side self) pure returns (Side) {
    return isLong(self) ? SHORT : LONG;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for bit twiddling and boolean operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBit.sol)
/// @author Inspired by (https://graphics.stanford.edu/~seander/bithacks.html)
library LibBit {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  BIT TWIDDLING OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Find last set.
    /// Returns the index of the most significant bit of `x`,
    /// counting from the least significant bit position.
    /// If `x` is zero, returns 256.
    function fls(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := or(shl(8, iszero(x)), shl(7, lt(0xffffffffffffffffffffffffffffffff, x)))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, byte(shr(r, x), hex"00000101020202020303030303030303"))
        }
    }

    /// @dev Count leading zeros.
    /// Returns the number of zeros preceding the most significant one bit.
    /// If `x` is zero, returns 256.
    function clz(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            // forgefmt: disable-next-item
            r := add(iszero(x), xor(255,
                or(r, byte(shr(r, x), hex"00000101020202020303030303030303"))))
        }
    }

    /// @dev Find first set.
    /// Returns the index of the least significant bit of `x`,
    /// counting from the least significant bit position.
    /// If `x` is zero, returns 256.
    /// Equivalent to `ctz` (count trailing zeros), which gives
    /// the number of zeros following the least significant one bit.
    function ffs(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Isolate the least significant bit.
            let b := and(x, add(not(x), 1))

            r := or(shl(8, iszero(x)), shl(7, lt(0xffffffffffffffffffffffffffffffff, b)))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, b))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, b))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // forgefmt: disable-next-item
            r := or(r, byte(and(div(0xd76453e0, shr(r, b)), 0x1f),
                0x001f0d1e100c1d070f090b19131c1706010e11080a1a141802121b1503160405))
        }
    }

    /// @dev Returns the number of set bits in `x`.
    function popCount(uint256 x) internal pure returns (uint256 c) {
        /// @solidity memory-safe-assembly
        assembly {
            let max := not(0)
            let isMax := eq(x, max)
            x := sub(x, and(shr(1, x), div(max, 3)))
            x := add(and(x, div(max, 5)), and(shr(2, x), div(max, 5)))
            x := and(add(x, shr(4, x)), div(max, 17))
            c := or(shl(8, isMax), shr(248, mul(x, div(max, 255))))
        }
    }

    /// @dev Returns whether `x` is a power of 2.
    function isPo2(uint256 x) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `x && !(x & (x - 1))`.
            result := iszero(add(and(x, sub(x, 1)), iszero(x)))
        }
    }

    /// @dev Returns `x` reversed at the bit level.
    function reverseBits(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Computing masks on-the-fly reduces bytecode size by about 500 bytes.
            let m := not(0)
            r := x
            for { let s := 128 } 1 {} {
                m := xor(m, shl(s, m))
                r := or(and(shr(s, r), m), and(shl(s, r), not(m)))
                s := shr(1, s)
                if iszero(s) { break }
            }
        }
    }

    /// @dev Returns `x` reversed at the byte level.
    function reverseBytes(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Computing masks on-the-fly reduces bytecode size by about 200 bytes.
            let m := not(0)
            r := x
            for { let s := 128 } 1 {} {
                m := xor(m, shl(s, m))
                r := or(and(shr(s, r), m), and(shl(s, r), not(m)))
                s := shr(1, s)
                if eq(s, 4) { break }
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     BOOLEAN OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // A Solidity bool on the stack or memory is represented as a 256-bit word.
    // Non-zero values are true, zero is false.
    // A clean bool is either 0 (false) or 1 (true) under the hood.
    // Usually, if not always, the bool result of a regular Solidity expression,
    // or the argument of a public/external function will be a clean bool.
    // You can usually use the raw variants for more performance.
    // If uncertain, test (best with exact compiler settings).
    // Or use the non-raw variants (compiler can sometimes optimize out the double `iszero`s).

    /// @dev Returns `x & y`. Inputs must be clean.
    function rawAnd(bool x, bool y) internal pure returns (bool z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := and(x, y)
        }
    }

    /// @dev Returns `x & y`.
    function and(bool x, bool y) internal pure returns (bool z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := and(iszero(iszero(x)), iszero(iszero(y)))
        }
    }

    /// @dev Returns `x | y`. Inputs must be clean.
    function rawOr(bool x, bool y) internal pure returns (bool z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := or(x, y)
        }
    }

    /// @dev Returns `x | y`.
    function or(bool x, bool y) internal pure returns (bool z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := or(iszero(iszero(x)), iszero(iszero(y)))
        }
    }

    /// @dev Returns 1 if `b` is true, else 0. Input must be clean.
    function rawToUint(bool b) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := b
        }
    }

    /// @dev Returns 1 if `b` is true, else 0.
    function toUint(bool b) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := iszero(iszero(b))
        }
    }
}