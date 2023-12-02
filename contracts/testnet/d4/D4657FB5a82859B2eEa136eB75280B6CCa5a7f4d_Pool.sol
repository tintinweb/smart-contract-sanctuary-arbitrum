// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Configurable Interface
/// @notice This interface defines the functions for manage USD stablecoins and token configurations
interface IConfigurable {
    /// @notice Emitted when a USD stablecoin is enabled
    /// @param usd The ERC20 token representing the USD stablecoin used in pools
    event USDEnabled(IERC20 indexed usd);

    /// @notice Emitted when a token's configuration is changed
    /// @param token The ERC20 token used in the pool
    /// @param newCfg The new token configuration
    /// @param newFeeRateCfg The new token fee rate configuration
    /// @param newPriceCfg The new token price configuration
    event TokenConfigChanged(
        IERC20 indexed token,
        TokenConfig newCfg,
        TokenFeeRateConfig newFeeRateCfg,
        TokenPriceConfig newPriceCfg
    );

    /// @notice Token is not enabled
    error TokenNotEnabled(IERC20 token);
    /// @notice Token is already enabled
    error TokenAlreadyEnabled(IERC20 token);
    /// @notice Invalid maximum risk rate for LP positions
    error InvalidMaxRiskRatePerLiquidityPosition(uint32 maxRiskRatePerLiquidityPosition);
    /// @notice Invalid maximum leverage for LP positions
    error InvalidMaxLeveragePerLiquidityPosition(uint32 maxLeveragePerLiquidityPosition);
    /// @notice Invalid maximum leverage for trader positions
    error InvalidMaxLeveragePerPosition(uint32 maxLeveragePerPosition);
    /// @notice Invalid liquidation fee rate for trader positions
    error InvalidLiquidationFeeRatePerPosition(uint32 liquidationFeeRatePerPosition);
    /// @notice Invalid interest rate
    error InvalidInterestRate(uint32 interestRate);
    /// @notice Invalid maximum funding rate
    error InvalidMaxFundingRate(uint32 maxFundingRate);
    /// @notice Invalid trading fee rate
    error InvalidTradingFeeRate(uint32 tradingFeeRate);
    /// @notice Invalid liquidity fee rate
    error InvalidLiquidityFeeRate(uint32 liquidityFeeRate);
    /// @notice Invalid protocol fee rate
    error InvalidProtocolFeeRate(uint32 protocolFeeRate);
    /// @notice Invalid referral return fee rate
    error InvalidReferralReturnFeeRate(uint32 referralReturnFeeRate);
    /// @notice Invalid referral parent return fee rate
    error InvalidReferralParentReturnFeeRate(uint32 referralParentReturnFeeRate);
    /// @notice Invalid referral discount rate
    error InvalidReferralDiscountRate(uint32 referralDiscountRate);
    /// @notice Invalid fee rate
    error InvalidFeeRate(
        uint32 liquidityFeeRate,
        uint32 protocolFeeRate,
        uint32 referralReturnFeeRate,
        uint32 referralParentReturnFeeRate
    );
    /// @notice Invalid maximum price impact liquidity
    error InvalidMaxPriceImpactLiquidity(uint128 maxPriceImpactLiquidity);
    /// @notice Invalid vertices length
    /// @dev The length of vertices must be equal to the `VERTEX_NUM`
    error InvalidVerticesLength(uint256 length, uint256 requiredLength);
    /// @notice Invalid liquidation vertex index
    /// @dev The liquidation vertex index must be less than the length of vertices
    error InvalidLiquidationVertexIndex(uint8 liquidationVertexIndex);
    /// @notice Invalid vertex
    /// @param index The index of the vertex
    error InvalidVertex(uint8 index);

    struct TokenConfig {
        // ==================== LP Position Configuration ====================
        uint64 minMarginPerLiquidityPosition;
        uint32 maxRiskRatePerLiquidityPosition;
        uint32 maxLeveragePerLiquidityPosition;
        // ==================== Trader Position Configuration ==================
        uint64 minMarginPerPosition;
        uint32 maxLeveragePerPosition;
        uint32 liquidationFeeRatePerPosition;
        // ==================== Other Configuration ==========================
        uint64 liquidationExecutionFee;
        uint32 interestRate;
        uint32 maxFundingRate;
    }

    struct TokenFeeRateConfig {
        uint32 tradingFeeRate;
        uint32 liquidityFeeRate;
        uint32 protocolFeeRate;
        uint32 referralReturnFeeRate;
        uint32 referralParentReturnFeeRate;
        uint32 referralDiscountRate;
    }

    struct VertexConfig {
        uint32 balanceRate;
        uint32 premiumRate;
    }

    struct TokenPriceConfig {
        uint128 maxPriceImpactLiquidity;
        uint8 liquidationVertexIndex;
        VertexConfig[] vertices;
    }

    /// @notice Get the USD stablecoin used in pools
    /// @return The ERC20 token representing the USD stablecoin used in pools
    function USD() external view returns (IERC20);

    /// @notice Checks if a token is enabled
    /// @param token The ERC20 token used in the pool
    /// @return True if the token is enabled, false otherwise
    function isEnabledToken(IERC20 token) external view returns (bool);

    /// @notice Get token configuration
    /// @param token The ERC20 token used in the pool
    /// @return minMarginPerLiquidityPosition The minimum entry margin required for LP positions
    /// @return maxRiskRatePerLiquidityPosition The maximum risk rate for LP positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return maxLeveragePerLiquidityPosition The maximum leverage for LP positions
    /// @return minMarginPerPosition The minimum entry margin required for trader positions
    /// @return maxLeveragePerPosition The maximum leverage for trader positions
    /// @return liquidationFeeRatePerPosition The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return liquidationExecutionFee The liquidation execution fee for LP and trader positions
    /// @return interestRate The interest rate used to calculate the funding rate,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return maxFundingRate The maximum funding rate, denominated in ten thousandths of a bip (i.e. 1e-8)
    function tokenConfigs(
        IERC20 token
    )
        external
        view
        returns (
            uint64 minMarginPerLiquidityPosition,
            uint32 maxRiskRatePerLiquidityPosition,
            uint32 maxLeveragePerLiquidityPosition,
            uint64 minMarginPerPosition,
            uint32 maxLeveragePerPosition,
            uint32 liquidationFeeRatePerPosition,
            uint64 liquidationExecutionFee,
            uint32 interestRate,
            uint32 maxFundingRate
        );

    /// @notice Get token fee rate configuration
    /// @param token The ERC20 token used in the pool
    /// @return tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return liquidityFeeRate The liquidity fee rate as a percentage of trading fee,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return protocolFeeRate The protocol fee rate as a percentage of trading fee,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return referralReturnFeeRate The referral return fee rate as a percentage of trading fee,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return referralParentReturnFeeRate The referral parent return fee rate as a percentage of trading fee,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return referralDiscountRate The discount rate for referrals,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    function tokenFeeRateConfigs(
        IERC20 token
    )
        external
        view
        returns (
            uint32 tradingFeeRate,
            uint32 liquidityFeeRate,
            uint32 protocolFeeRate,
            uint32 referralReturnFeeRate,
            uint32 referralParentReturnFeeRate,
            uint32 referralDiscountRate
        );

    /// @notice Get token price configuration
    /// @param token The ERC20 token used in the pool
    /// @return maxPriceImpactLiquidity The maximum LP liquidity value used to calculate
    /// premium rate when trader increase or decrease positions
    /// @return liquidationVertexIndex The index used to store the net position of the liquidation
    function tokenPriceConfigs(
        IERC20 token
    ) external view returns (uint128 maxPriceImpactLiquidity, uint8 liquidationVertexIndex);

    /// @notice Get token price vertex configuration
    /// @param token The ERC20 token used in the pool
    /// @param index The index of the vertex
    /// @return balanceRate The balance rate of the vertex, denominated in a bip (i.e. 1e-8)
    /// @return premiumRate The premium rate of the vertex, denominated in a bip (i.e. 1e-8)
    function tokenPriceVertexConfigs(
        IERC20 token,
        uint8 index
    ) external view returns (uint32 balanceRate, uint32 premiumRate);

    /// @notice Enable a token
    /// @dev The call will fail if caller is not the governor or the token is already enabled
    /// @param token The ERC20 token used in the pool
    /// @param cfg The token configuration
    /// @param feeRateCfg The token fee rate configuration
    /// @param priceCfg The token price configuration
    function enableToken(
        IERC20 token,
        TokenConfig calldata cfg,
        TokenFeeRateConfig calldata feeRateCfg,
        TokenPriceConfig calldata priceCfg
    ) external;

    /// @notice Update a token configuration
    /// @dev The call will fail if caller is not the governor or the token is not enabled
    /// @param token The ERC20 token used in the pool
    /// @param newCfg The new token configuration
    /// @param newFeeRateCfg The new token fee rate configuration
    /// @param newPriceCfg The new token price configuration
    function updateTokenConfig(
        IERC20 token,
        TokenConfig calldata newCfg,
        TokenFeeRateConfig calldata newFeeRateCfg,
        TokenPriceConfig calldata newPriceCfg
    ) external;
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

import "./IConfigurable.sol";
import "../../plugins/Router.sol";
import "../../oracle/interfaces/IPriceFeed.sol";
import "../../farming/interfaces/IRewardFarmCallback.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title Pool Factory Interface
/// @notice This interface defines the functions for creating pools
interface IPoolFactory is IConfigurable, IAccessControl {
    /// @notice Emitted when a new pool is created
    /// @param pool The address of the created pool
    /// @param token The ERC20 token used in the pool
    /// @param usd The ERC20 token representing the USD stablecoin used in the pool
    event PoolCreated(IPool indexed pool, IERC20 indexed token, IERC20 indexed usd);

    /// @notice Pool factory is not initialized
    error NotInitialized();

    /// @notice Pool already exists
    error PoolAlreadyExists(IPool pool);

    /// @notice Get the address of the governor
    /// @return The address of the governor
    function gov() external view returns (address);

    /// @notice Retrieve the price feed contract used for fetching token prices
    function priceFeed() external view returns (IPriceFeed);

    /// @notice Retrieve the deployment parameters for a pool
    /// @return token The ERC20 token used in the pool
    /// @return usd The ERC20 token representing the USD stablecoin used in the pool
    /// @return router The router contract used in the pool
    /// @return feeDistributor The fee distributor contract used for distributing fees
    /// @return EFC The EFC contract used for referral program
    /// @return callback The reward farm callback contract used for distributing rewards
    function deployParameters()
        external
        view
        returns (
            IERC20 token,
            IERC20 usd,
            Router router,
            IFeeDistributor feeDistributor,
            IEFC EFC,
            IRewardFarmCallback callback
        );

    /// @notice Get the pool associated with a token and USD stablecoin
    /// @param token The ERC20 token used in the pool
    /// @return pool The address of the created pool (address(0) if not exists)
    function pools(IERC20 token) external view returns (IPool pool);

    /// @notice Check if a pool exist
    /// @param pool The address of the pool
    /// @return True if the pool exist
    function isPool(address pool) external view returns (bool);

    /// @notice Create a new pool
    /// @dev The call will fail if any of the following conditions are not met:
    /// - The caller is the governor
    /// - The pool does not already exist
    /// - The token is enabled
    /// @param token The ERC20 token used in the pool
    /// @return pool The address of the created pool
    function createPool(IERC20 token) external returns (IPool pool);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.21;

import "../libraries/PoolUtil.sol";
import "../libraries/PriceUtil.sol";
import "../libraries/FundingRateUtil.sol";
import "../libraries/ReentrancyGuard.sol";

contract Pool is IPool, ReentrancyGuard {
    using SafeCast for *;
    using SafeERC20 for IERC20;

    struct TradingFeeState {
        uint32 tradingFeeRate;
        uint32 referralReturnFeeRate;
        uint32 referralParentReturnFeeRate;
        uint256 referralToken;
        uint256 referralParentToken;
    }

    IPoolFactory private immutable poolFactory;
    Router private immutable router;

    IFeeDistributor private immutable feeDistributor;
    IEFC private immutable EFC;
    IRewardFarmCallback private immutable callback;

    IPriceFeed public priceFeed;
    /// @dev The serial number of the next liquidity position, starting from 1
    uint96 private liquidityPositionIDNext;
    /// @inheritdoc IPool
    IERC20 public immutable override token;
    IERC20 private immutable usd;

    IConfigurable.TokenConfig private tokenConfig;
    IConfigurable.TokenFeeRateConfig private tokenFeeRateConfig;
    PriceState private priceState0;

    uint128 public usdBalance;
    /// @inheritdoc IPool
    uint128 public override protocolFee;
    /// @inheritdoc IPool
    mapping(uint256 => uint256) public override referralFees;

    // ==================== Liquidity Position Stats ====================

    /// @inheritdoc IPoolLiquidityPosition
    GlobalLiquidityPosition public override globalLiquidityPosition;
    /// @inheritdoc IPoolLiquidityPosition
    GlobalUnrealizedLossMetrics public override globalUnrealizedLossMetrics;
    /// @inheritdoc IPoolLiquidityPosition
    mapping(uint96 => LiquidityPosition) public override liquidityPositions;

    // ==================== Risk Buffer Fund Position Stats =============

    /// @inheritdoc IPoolLiquidityPosition
    GlobalRiskBufferFund public override globalRiskBufferFund;
    /// @inheritdoc IPoolLiquidityPosition
    mapping(address => RiskBufferFundPosition) public override riskBufferFundPositions;

    // ==================== Position Stats ==============================

    /// @inheritdoc IPoolPosition
    GlobalPosition public override globalPosition;
    /// @inheritdoc IPoolPosition
    PreviousGlobalFundingRate public override previousGlobalFundingRate;
    /// @inheritdoc IPoolPosition
    GlobalFundingRateSample public override globalFundingRateSample;
    /// @inheritdoc IPoolPosition
    mapping(address => mapping(Side => Position)) public override positions;

    constructor() {
        poolFactory = IPoolFactory(msg.sender);
        (token, usd, router, feeDistributor, EFC, callback) = poolFactory.deployParameters();
        priceFeed = poolFactory.priceFeed();

        PoolUtil.changeTokenConfig(tokenConfig, tokenFeeRateConfig, priceState0, poolFactory, token);

        globalFundingRateSample.lastAdjustFundingRateTime = _calculateFundingRateTime(_blockTimestamp());
    }

    // ==================== Liquidity Position Methods ====================

    /// @inheritdoc IPoolLiquidityPosition
    function liquidityPositionAccount(uint96 _positionID) external view override returns (address account) {
        return liquidityPositions[_positionID].account;
    }

    /// @inheritdoc IPoolLiquidityPosition
    function openLiquidityPosition(
        address _account,
        uint128 _margin,
        uint128 _liquidity
    ) external override nonReentrant returns (uint96 positionID) {
        _onlyRouter();

        _sampleAndAdjustFundingRate();

        if (_liquidity == 0) revert InvalidLiquidityToOpen();

        _validateMargin(_margin, tokenConfig.minMarginPerLiquidityPosition);
        _validateLeverage(_margin, _liquidity, tokenConfig.maxLeveragePerLiquidityPosition);
        _validateTransferInAndUpdateBalance(_margin);

        GlobalLiquidityPosition memory globalPositionCache = globalLiquidityPosition;
        // prettier-ignore
        (
            uint64 blockTimestamp,
            uint256 unrealizedLoss,
            /* GlobalUnrealizedLossMetrics memory globalMetricsCache */
        ) = _updateUnrealizedLossMetrics(globalPositionCache, int256(uint256(_liquidity)));

        // Update global liquidity position
        globalLiquidityPosition.liquidity = globalPositionCache.liquidity + _liquidity;

        positionID = ++liquidityPositionIDNext;
        liquidityPositions[positionID] = LiquidityPosition({
            margin: _margin,
            liquidity: _liquidity,
            entryUnrealizedLoss: unrealizedLoss,
            entryRealizedProfitGrowthX64: globalPositionCache.realizedProfitGrowthX64,
            entryTime: blockTimestamp,
            account: _account
        });

        emit LiquidityPositionOpened(
            _account,
            positionID,
            _margin,
            _liquidity,
            unrealizedLoss,
            globalPositionCache.realizedProfitGrowthX64
        );

        _changePriceVertices();

        // callback for reward farm
        callback.onLiquidityPositionChanged(_account, int256(uint256(_liquidity)));
    }

    /// @inheritdoc IPoolLiquidityPosition
    function closeLiquidityPosition(uint96 _positionID, address _receiver) external override nonReentrant {
        _onlyRouter();
        _validateLiquidityPosition(_positionID);

        _sampleAndAdjustFundingRate();

        GlobalLiquidityPosition memory globalPositionCache = globalLiquidityPosition;
        LiquidityPosition memory positionCache = liquidityPositions[_positionID];

        if (
            globalPositionCache.liquidity == positionCache.liquidity &&
            (globalPositionCache.netSize | globalPositionCache.liquidationBufferNetSize) > 0
        ) revert LastLiquidityPositionCannotBeClosed();

        (
            uint64 blockTimestamp,
            uint256 unrealizedLoss,
            GlobalUnrealizedLossMetrics memory globalMetricsCache
        ) = _updateUnrealizedLossMetrics(globalPositionCache, 0);

        uint256 positionRealizedProfit = LiquidityPositionUtil.calculateRealizedProfit(
            positionCache,
            globalPositionCache
        );
        uint256 marginAfter = positionCache.margin + positionRealizedProfit;

        uint128 positionUnrealizedLoss = LiquidityPositionUtil.calculatePositionUnrealizedLoss(
            positionCache,
            globalMetricsCache,
            globalPositionCache.liquidity,
            unrealizedLoss
        );

        uint64 liquidationExecutionFee = tokenConfig.liquidationExecutionFee;
        _validateLiquidityPositionRiskRate(marginAfter, liquidationExecutionFee, positionUnrealizedLoss, false);

        LiquidityPositionUtil.updateUnrealizedLossMetrics(
            globalUnrealizedLossMetrics,
            unrealizedLoss,
            blockTimestamp,
            -int256(uint256(positionCache.liquidity)),
            positionCache.entryTime,
            positionCache.entryUnrealizedLoss
        );
        _emitGlobalUnrealizedLossMetricsChangedEvent();

        unchecked {
            // never underflow because of the validation above
            marginAfter -= positionUnrealizedLoss;
            _transferOutAndUpdateBalance(_receiver, marginAfter);

            // Update global liquidity position
            globalLiquidityPosition.liquidity = globalPositionCache.liquidity - positionCache.liquidity;
        }

        int256 riskBufferFundAfter = globalRiskBufferFund.riskBufferFund + int256(uint256(positionUnrealizedLoss));
        globalRiskBufferFund.riskBufferFund = riskBufferFundAfter;
        emit GlobalRiskBufferFundChanged(riskBufferFundAfter);

        delete liquidityPositions[_positionID];

        emit LiquidityPositionClosed(
            _positionID,
            marginAfter.toUint128(),
            positionUnrealizedLoss,
            positionRealizedProfit,
            _receiver
        );

        _changePriceVertices();

        // callback for reward farm
        callback.onLiquidityPositionChanged(positionCache.account, -int256(uint256(positionCache.liquidity)));
    }

    /// @inheritdoc IPoolLiquidityPosition
    function adjustLiquidityPositionMargin(
        uint96 _positionID,
        int128 _marginDelta,
        address _receiver
    ) external override nonReentrant {
        _onlyRouter();
        _validateLiquidityPosition(_positionID);

        _sampleAndAdjustFundingRate();

        if (_marginDelta > 0) _validateTransferInAndUpdateBalance(uint128(_marginDelta));

        GlobalLiquidityPosition memory globalPositionCache = globalLiquidityPosition;
        // prettier-ignore
        (
            /* uint64 blockTimestamp */,
            uint256 unrealizedLoss,
            GlobalUnrealizedLossMetrics memory globalMetricsCache
        ) = _updateUnrealizedLossMetrics(globalPositionCache, 0);

        LiquidityPosition memory positionCache = liquidityPositions[_positionID];
        uint256 positionRealizedProfit = LiquidityPositionUtil.calculateRealizedProfit(
            positionCache,
            globalPositionCache
        );
        uint256 marginAfter = positionCache.margin + positionRealizedProfit;
        if (_marginDelta >= 0) {
            marginAfter += uint128(_marginDelta);
        } else {
            // If marginDelta is equal to type(int128).min, it will revert here
            if (marginAfter < uint128(-_marginDelta)) revert InsufficientMargin();
            // prettier-ignore
            unchecked { marginAfter -= uint128(-_marginDelta); }
        }

        uint64 liquidationExecutionFee = tokenConfig.liquidationExecutionFee;
        uint128 positionUnrealizedLoss = LiquidityPositionUtil.calculatePositionUnrealizedLoss(
            positionCache,
            globalMetricsCache,
            globalPositionCache.liquidity,
            unrealizedLoss
        );
        _validateLiquidityPositionRiskRate(marginAfter, liquidationExecutionFee, positionUnrealizedLoss, false);

        if (_marginDelta < 0) {
            _validateLeverage(marginAfter, positionCache.liquidity, tokenConfig.maxLeveragePerLiquidityPosition);
            _transferOutAndUpdateBalance(_receiver, uint128(-_marginDelta));
        }

        // Update position
        LiquidityPosition storage position = liquidityPositions[_positionID];
        position.margin = marginAfter.toUint128();
        position.entryRealizedProfitGrowthX64 = globalPositionCache.realizedProfitGrowthX64;

        emit LiquidityPositionMarginAdjusted(
            _positionID,
            _marginDelta,
            marginAfter.toUint128(),
            globalPositionCache.realizedProfitGrowthX64,
            _receiver
        );
    }

    /// @inheritdoc IPoolLiquidityPosition
    function liquidateLiquidityPosition(uint96 _positionID, address _feeReceiver) external override nonReentrant {
        _onlyLiquidityPositionLiquidator();

        _validateLiquidityPosition(_positionID);

        _sampleAndAdjustFundingRate();

        GlobalLiquidityPosition memory globalPositionCache = globalLiquidityPosition;
        // prettier-ignore
        (
            uint64 blockTimestamp,
            uint256 unrealizedLoss,
            GlobalUnrealizedLossMetrics memory globalMetricsCache
        ) = _updateUnrealizedLossMetrics(globalPositionCache, 0);

        LiquidityPosition memory positionCache = liquidityPositions[_positionID];

        uint256 positionRealizedProfit = LiquidityPositionUtil.calculateRealizedProfit(
            positionCache,
            globalPositionCache
        );
        uint256 marginAfter = positionCache.margin + positionRealizedProfit;

        uint128 positionUnrealizedLoss = LiquidityPositionUtil.calculatePositionUnrealizedLoss(
            positionCache,
            globalMetricsCache,
            globalPositionCache.liquidity,
            unrealizedLoss
        );
        uint64 liquidationExecutionFee = tokenConfig.liquidationExecutionFee;
        _validateLiquidityPositionRiskRate(marginAfter, liquidationExecutionFee, positionUnrealizedLoss, true);

        unchecked {
            if (marginAfter < liquidationExecutionFee) {
                liquidationExecutionFee = uint64(marginAfter);
                marginAfter = 0;
            } else marginAfter -= liquidationExecutionFee;
            _transferOutAndUpdateBalance(_feeReceiver, liquidationExecutionFee);
        }

        LiquidityPositionUtil.updateUnrealizedLossMetrics(
            globalUnrealizedLossMetrics,
            unrealizedLoss,
            blockTimestamp,
            -int256(uint256(positionCache.liquidity)),
            positionCache.entryTime,
            positionCache.entryUnrealizedLoss
        );
        _emitGlobalUnrealizedLossMetricsChangedEvent();

        // Update global liquidity position
        // prettier-ignore
        unchecked { globalLiquidityPosition.liquidity = globalPositionCache.liquidity - positionCache.liquidity; }

        int256 riskBufferFundAfter = globalRiskBufferFund.riskBufferFund + marginAfter.toInt256();
        globalRiskBufferFund.riskBufferFund = riskBufferFundAfter;
        emit GlobalRiskBufferFundChanged(riskBufferFundAfter);

        delete liquidityPositions[_positionID];

        emit LiquidityPositionLiquidated(
            msg.sender,
            _positionID,
            positionRealizedProfit,
            marginAfter,
            liquidationExecutionFee,
            _feeReceiver
        );

        _changePriceVertices();

        // callback for reward farm
        callback.onLiquidityPositionChanged(positionCache.account, -int256(uint256(positionCache.liquidity)));
    }

    /// @inheritdoc IPoolLiquidityPosition
    function govUseRiskBufferFund(address _receiver, uint128 _riskBufferFundDelta) external override nonReentrant {
        if (msg.sender != poolFactory.gov()) revert InvalidCaller(poolFactory.gov());

        _sampleAndAdjustFundingRate();

        _updateUnrealizedLossMetrics(globalLiquidityPosition, 0);

        int256 riskBufferFundAfter = LiquidityPositionUtil.govUseRiskBufferFund(
            globalLiquidityPosition,
            globalRiskBufferFund,
            _chooseIndexPriceX96(globalLiquidityPosition.side),
            _riskBufferFundDelta
        );
        _transferOutAndUpdateBalance(_receiver, _riskBufferFundDelta);
        emit GlobalRiskBufferFundGovUsed(_receiver, _riskBufferFundDelta);
        emit GlobalRiskBufferFundChanged(riskBufferFundAfter);
    }

    /// @inheritdoc IPoolLiquidityPosition
    function increaseRiskBufferFundPosition(address _account, uint128 _liquidityDelta) external override nonReentrant {
        _onlyRouter();

        _sampleAndAdjustFundingRate();

        _validateTransferInAndUpdateBalance(_liquidityDelta);

        _updateUnrealizedLossMetrics(globalLiquidityPosition, 0);

        (uint128 positionLiquidityAfter, uint64 unlockTimeAfter, int256 riskBufferFundAfter) = LiquidityPositionUtil
            .increaseRiskBufferFundPosition(globalRiskBufferFund, riskBufferFundPositions, _account, _liquidityDelta);

        emit RiskBufferFundPositionIncreased(_account, positionLiquidityAfter, unlockTimeAfter);
        emit GlobalRiskBufferFundChanged(riskBufferFundAfter);

        // callback for reward farm
        callback.onRiskBufferFundPositionChanged(_account, positionLiquidityAfter);
    }

    /// @inheritdoc IPoolLiquidityPosition
    function decreaseRiskBufferFundPosition(
        address _account,
        uint128 _liquidityDelta,
        address _receiver
    ) external override nonReentrant {
        _onlyRouter();

        _sampleAndAdjustFundingRate();

        _updateUnrealizedLossMetrics(globalLiquidityPosition, 0);

        (uint128 positionLiquidityAfter, int256 riskBufferFundAfter) = LiquidityPositionUtil
            .decreaseRiskBufferFundPosition(
                globalLiquidityPosition,
                globalRiskBufferFund,
                riskBufferFundPositions,
                _chooseIndexPriceX96(globalLiquidityPosition.side),
                _account,
                _liquidityDelta
            );
        _transferOutAndUpdateBalance(_receiver, _liquidityDelta);

        emit RiskBufferFundPositionDecreased(_account, positionLiquidityAfter, _receiver);
        emit GlobalRiskBufferFundChanged(riskBufferFundAfter);

        // callback for reward farm
        callback.onRiskBufferFundPositionChanged(_account, positionLiquidityAfter);
    }

    // ==================== Position Methods ====================

    /// @inheritdoc IPoolPosition
    function increasePosition(
        address _account,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta
    ) external override nonReentrant returns (uint160 tradePriceX96) {
        _side.requireValid();
        _onlyRouter();

        _sampleAndAdjustFundingRate();

        Position memory positionCache = positions[_account][_side];
        if (positionCache.size == 0) {
            if (_sizeDelta == 0) revert PositionNotFound(_account, _side);

            _validateMargin(_marginDelta, tokenConfig.minMarginPerPosition);
        }

        if (_marginDelta > 0) _validateTransferInAndUpdateBalance(_marginDelta);

        GlobalLiquidityPosition memory globalLiquidityPositionCache = globalLiquidityPosition;
        _validateGlobalLiquidity(globalLiquidityPositionCache.liquidity);

        _updateUnrealizedLossMetrics(globalLiquidityPositionCache, 0);

        uint128 tradingFee;
        TradingFeeState memory tradingFeeState = _buildTradingFeeState(_account);
        if (_sizeDelta > 0) {
            tradePriceX96 = PriceUtil.updatePriceState(
                globalLiquidityPosition,
                priceState0,
                _side,
                _sizeDelta,
                _chooseIndexPriceX96(_side),
                false
            );

            tradingFee = _adjustGlobalLiquidityPosition(
                globalLiquidityPositionCache,
                tradingFeeState,
                _account,
                _side,
                tradePriceX96,
                _sizeDelta,
                0
            );
        }

        int192 globalFundingRateGrowthX96 = PositionUtil.chooseFundingRateGrowthX96(globalPosition, _side);
        int256 fundingFee = PositionUtil.calculateFundingFee(
            globalFundingRateGrowthX96,
            positionCache.entryFundingRateGrowthX96,
            positionCache.size
        );

        int256 marginAfter = int256(uint256(positionCache.margin) + _marginDelta);
        marginAfter += fundingFee - int256(uint256(tradingFee));

        uint160 entryPriceAfterX96 = PositionUtil.calculateNextEntryPriceX96(
            _side,
            positionCache.size,
            positionCache.entryPriceX96,
            _sizeDelta,
            tradePriceX96
        );
        uint128 sizeAfter = positionCache.size + _sizeDelta;

        _validatePositionLiquidateMaintainMarginRate(
            marginAfter,
            _side,
            sizeAfter,
            entryPriceAfterX96,
            _chooseIndexPriceX96(_side.flip()), // Use the closing price to validate the margin rate
            tradingFeeState.tradingFeeRate,
            false
        );
        uint128 marginAfterUint128 = uint256(marginAfter).toUint128();

        if (_sizeDelta > 0) {
            _validateLeverage(
                marginAfterUint128,
                PositionUtil.calculateLiquidity(sizeAfter, entryPriceAfterX96),
                tokenConfig.maxLeveragePerPosition
            );
            _increaseGlobalPosition(_side, _sizeDelta);
        }

        Position storage position = positions[_account][_side];
        position.margin = marginAfterUint128;
        position.size = sizeAfter;
        position.entryPriceX96 = entryPriceAfterX96;
        position.entryFundingRateGrowthX96 = globalFundingRateGrowthX96;
        emit PositionIncreased(
            _account,
            _side,
            _marginDelta,
            marginAfterUint128,
            sizeAfter,
            tradePriceX96,
            entryPriceAfterX96,
            fundingFee,
            tradingFee
        );

        // callback for reward farm
        callback.onPositionChanged(_account, _side, sizeAfter, entryPriceAfterX96);
    }

    /// @inheritdoc IPoolPosition
    function decreasePosition(
        address _account,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta,
        address _receiver
    ) external override nonReentrant returns (uint160 tradePriceX96) {
        _onlyRouter();

        _sampleAndAdjustFundingRate();

        Position memory positionCache = positions[_account][_side];
        if (positionCache.size == 0) revert PositionNotFound(_account, _side);

        if (positionCache.size < _sizeDelta) revert InsufficientSizeToDecrease(positionCache.size, _sizeDelta);

        GlobalLiquidityPosition memory globalLiquidityPositionCache = globalLiquidityPosition;
        _validateGlobalLiquidity(globalLiquidityPositionCache.liquidity);

        _updateUnrealizedLossMetrics(globalLiquidityPositionCache, 0);

        uint160 decreaseIndexPriceX96 = _chooseIndexPriceX96(_side.flip());

        uint128 tradingFee;
        uint128 sizeAfter = positionCache.size;
        int256 realizedPnLDelta;
        TradingFeeState memory tradingFeeState = _buildTradingFeeState(_account);
        if (_sizeDelta > 0) {
            // never underflow because of the validation above
            // prettier-ignore
            unchecked { sizeAfter = positionCache.size - _sizeDelta; }

            tradePriceX96 = PriceUtil.updatePriceState(
                globalLiquidityPosition,
                priceState0,
                _side.flip(),
                _sizeDelta,
                decreaseIndexPriceX96,
                false
            );

            tradingFee = _adjustGlobalLiquidityPosition(
                globalLiquidityPositionCache,
                tradingFeeState,
                _account,
                _side.flip(),
                tradePriceX96,
                _sizeDelta,
                0
            );
            realizedPnLDelta = PositionUtil.calculateUnrealizedPnL(
                _side,
                _sizeDelta,
                positionCache.entryPriceX96,
                tradePriceX96
            );
        }

        int192 globalFundingRateGrowthX96 = PositionUtil.chooseFundingRateGrowthX96(globalPosition, _side);
        int256 fundingFee = PositionUtil.calculateFundingFee(
            globalFundingRateGrowthX96,
            positionCache.entryFundingRateGrowthX96,
            positionCache.size
        );

        int256 marginAfter = int256(uint256(positionCache.margin));
        marginAfter += realizedPnLDelta + fundingFee - int256(uint256(tradingFee) + _marginDelta);
        if (marginAfter < 0) revert InsufficientMargin();

        uint128 marginAfterUint128 = uint256(marginAfter).toUint128();
        if (sizeAfter > 0) {
            _validatePositionLiquidateMaintainMarginRate(
                marginAfter,
                _side,
                sizeAfter,
                positionCache.entryPriceX96,
                decreaseIndexPriceX96,
                tradingFeeState.tradingFeeRate,
                false
            );
            if (_marginDelta > 0)
                _validateLeverage(
                    marginAfterUint128,
                    PositionUtil.calculateLiquidity(sizeAfter, positionCache.entryPriceX96),
                    tokenConfig.maxLeveragePerPosition
                );

            // Update position
            Position storage position = positions[_account][_side];
            position.margin = marginAfterUint128;
            position.size = sizeAfter;
            position.entryFundingRateGrowthX96 = globalFundingRateGrowthX96;
        } else {
            // If the position is closed, the marginDelta needs to be added back to ensure that the
            // remaining margin of the position is 0.
            _marginDelta += marginAfterUint128;
            marginAfterUint128 = 0;

            // Delete position
            delete positions[_account][_side];
        }

        if (_marginDelta > 0) _transferOutAndUpdateBalance(_receiver, _marginDelta);

        if (_sizeDelta > 0) _decreaseGlobalPosition(_side, _sizeDelta);

        emit PositionDecreased(
            _account,
            _side,
            _marginDelta,
            marginAfterUint128,
            sizeAfter,
            tradePriceX96,
            realizedPnLDelta,
            fundingFee,
            tradingFee,
            _receiver
        );

        // callback for reward farm
        callback.onPositionChanged(_account, _side, sizeAfter, positionCache.entryPriceX96);
    }

    /// @inheritdoc IPoolPosition
    function liquidatePosition(address _account, Side _side, address _feeReceiver) external override nonReentrant {
        _onlyPositionLiquidator();

        _sampleAndAdjustFundingRate();

        Position memory positionCache = positions[_account][_side];
        if (positionCache.size == 0) revert PositionNotFound(_account, _side);

        GlobalLiquidityPosition memory globalLiquidityPositionCache = globalLiquidityPosition;
        _validateGlobalLiquidity(globalLiquidityPositionCache.liquidity);

        _updateUnrealizedLossMetrics(globalLiquidityPositionCache, 0);

        uint160 decreaseIndexPriceX96 = _chooseIndexPriceX96(_side.flip());

        TradingFeeState memory tradingFeeState = _buildTradingFeeState(_account);
        int256 requiredFundingFee = PositionUtil.calculateFundingFee(
            PositionUtil.chooseFundingRateGrowthX96(globalPosition, _side),
            positionCache.entryFundingRateGrowthX96,
            positionCache.size
        );

        _validatePositionLiquidateMaintainMarginRate(
            int256(uint256(positionCache.margin)) + requiredFundingFee,
            _side,
            positionCache.size,
            positionCache.entryPriceX96,
            decreaseIndexPriceX96,
            tradingFeeState.tradingFeeRate,
            true
        );

        // try to update price state
        PriceUtil.updatePriceState(
            globalLiquidityPosition,
            priceState0,
            _side.flip(),
            positionCache.size,
            decreaseIndexPriceX96,
            true
        );

        _liquidatePosition(
            globalLiquidityPositionCache,
            positionCache,
            tradingFeeState,
            _account,
            _side,
            decreaseIndexPriceX96,
            requiredFundingFee,
            _feeReceiver
        );

        // callback for reward farm
        callback.onPositionChanged(_account, _side, 0, 0);
    }

    /// @inheritdoc IPool
    function priceState()
        external
        view
        override
        returns (
            uint128 maxPriceImpactLiquidity,
            uint128 premiumRateX96,
            PriceVertex[7] memory priceVertices,
            uint8 pendingVertexIndex,
            uint8 liquidationVertexIndex,
            uint8 currentVertexIndex,
            uint128[7] memory liquidationBufferNetSizes
        )
    {
        return (
            priceState0.maxPriceImpactLiquidity,
            priceState0.premiumRateX96,
            priceState0.priceVertices,
            priceState0.pendingVertexIndex,
            priceState0.liquidationVertexIndex,
            priceState0.currentVertexIndex,
            priceState0.liquidationBufferNetSizes
        );
    }

    /// @inheritdoc IPool
    function marketPriceX96(Side _side) external view override returns (uint160 _marketPriceX96) {
        _marketPriceX96 = PriceUtil.calculateMarketPriceX96(
            globalLiquidityPosition.side,
            _side,
            _chooseIndexPriceX96(_side),
            priceState0.premiumRateX96
        );
    }

    /// @inheritdoc IPool
    /// @dev This function does not include the nonReentrant modifier because it is intended
    /// to be called internally by the contract itself.
    function changePriceVertex(uint8 _startExclusive, uint8 _endInclusive) external override {
        if (msg.sender != address(this)) revert InvalidCaller(address(this));

        unchecked {
            // If the vertex represented by end is the same as the vertex represented by end + 1,
            // then the vertices in the range (start, LATEST_VERTEX] need to be updated
            if (_endInclusive < Constants.LATEST_VERTEX) {
                PriceVertex memory previous = priceState0.priceVertices[_endInclusive];
                PriceVertex memory next = priceState0.priceVertices[_endInclusive + 1];
                if (previous.size >= next.size || previous.premiumRateX96 >= next.premiumRateX96)
                    _endInclusive = Constants.LATEST_VERTEX;
            }
        }

        _changePriceVertex(_startExclusive, _endInclusive);
    }

    /// @inheritdoc IPool
    function onChangeTokenConfig() external override nonReentrant {
        if (msg.sender != address(poolFactory)) revert InvalidCaller(address(poolFactory));

        _sampleAndAdjustFundingRate();

        _updateUnrealizedLossMetrics(globalLiquidityPosition, 0);

        PoolUtil.changeTokenConfig(tokenConfig, tokenFeeRateConfig, priceState0, poolFactory, token);

        _changePriceVertices();

        priceFeed = poolFactory.priceFeed();
    }

    /// @inheritdoc IPool
    function sampleAndAdjustFundingRate() external override nonReentrant {
        _sampleAndAdjustFundingRate();

        _updateUnrealizedLossMetrics(globalLiquidityPosition, 0);
    }

    /// @inheritdoc IPool
    function collectProtocolFee() external override nonReentrant {
        _sampleAndAdjustFundingRate();

        _updateUnrealizedLossMetrics(globalLiquidityPosition, 0);

        uint128 protocolFeeCopy = protocolFee;
        delete protocolFee;

        _transferOutAndUpdateBalance(address(feeDistributor), protocolFeeCopy);
        feeDistributor.depositFee(protocolFeeCopy);
        emit ProtocolFeeCollected(protocolFeeCopy);
    }

    /// @inheritdoc IPool
    function collectReferralFee(
        uint256 _referralToken,
        address _receiver
    ) external override nonReentrant returns (uint256 amount) {
        _onlyRouter();

        _sampleAndAdjustFundingRate();

        _updateUnrealizedLossMetrics(globalLiquidityPosition, 0);

        amount = referralFees[_referralToken];
        delete referralFees[_referralToken];

        _transferOutAndUpdateBalance(_receiver, amount);
        emit ReferralFeeCollected(_referralToken, _receiver, amount);
    }

    function _onlyRouter() private view {
        if (msg.sender != address(router)) revert InvalidCaller(address(router));
    }

    function _onlyLiquidityPositionLiquidator() private view {
        if (!poolFactory.hasRole(Constants.ROLE_LIQUIDITY_POSITION_LIQUIDATOR, msg.sender))
            revert CallerNotLiquidator();
    }

    function _onlyPositionLiquidator() private view {
        if (!poolFactory.hasRole(Constants.ROLE_POSITION_LIQUIDATOR, msg.sender)) revert CallerNotLiquidator();
    }

    function _validateTransferInAndUpdateBalance(uint128 _amount) private {
        uint128 balanceAfter = usd.balanceOf(address(this)).toUint128();
        if (balanceAfter - usdBalance < _amount) revert InsufficientBalance(usdBalance, _amount);
        usdBalance += _amount;
    }

    function _transferOutAndUpdateBalance(address _to, uint256 _amount) private {
        usdBalance = (usdBalance - _amount).toUint128();
        usd.safeTransfer(_to, _amount);
    }

    function _validateLeverage(uint256 _margin, uint128 _liquidity, uint32 _maxLeverage) private pure {
        if (_margin * _maxLeverage < _liquidity) revert LeverageTooHigh(_margin, _liquidity, _maxLeverage);
    }

    function _validateMargin(uint128 _margin, uint64 _minMargin) private pure {
        if (_margin < _minMargin) revert InsufficientMargin();
    }

    function _validateLiquidityPosition(uint96 _positionID) private view {
        if (liquidityPositions[_positionID].liquidity == 0) revert LiquidityPositionNotFound(_positionID);
    }

    /// @dev Validate the position risk rate
    /// @param _margin The margin of the position
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @param _positionUnrealizedLoss The unrealized loss incurred by the position at the time of closing
    /// @param _liquidatablePosition Whether it is a liquidatable position, if true, the position must be liquidatable,
    /// otherwise the position must be non-liquidatable
    function _validateLiquidityPositionRiskRate(
        uint256 _margin,
        uint64 _liquidationExecutionFee,
        uint128 _positionUnrealizedLoss,
        bool _liquidatablePosition
    ) private view {
        unchecked {
            if (!_liquidatablePosition) {
                if (
                    _margin < (uint256(_liquidationExecutionFee) + _positionUnrealizedLoss) ||
                    Math.mulDiv(
                        _margin - _liquidationExecutionFee,
                        tokenConfig.maxRiskRatePerLiquidityPosition,
                        Constants.BASIS_POINTS_DIVISOR
                    ) <=
                    _positionUnrealizedLoss
                ) revert RiskRateTooHigh(_margin, _liquidationExecutionFee, _positionUnrealizedLoss);
            } else {
                if (
                    _margin > (uint256(_liquidationExecutionFee) + _positionUnrealizedLoss) &&
                    Math.mulDiv(
                        _margin - _liquidationExecutionFee,
                        tokenConfig.maxRiskRatePerLiquidityPosition,
                        Constants.BASIS_POINTS_DIVISOR
                    ) >
                    _positionUnrealizedLoss
                ) revert RiskRateTooLow(_margin, _liquidationExecutionFee, _positionUnrealizedLoss);
            }
        }
    }

    function _changePriceVertices() private {
        uint8 currentVertexIndex = priceState0.currentVertexIndex;
        priceState0.pendingVertexIndex = currentVertexIndex;

        _changePriceVertex(currentVertexIndex, Constants.LATEST_VERTEX);
    }

    /// @dev Change the price vertex
    /// @param _startExclusive The start index of the price vertex to be changed, exclusive
    /// @param _endInclusive The end index of the price vertex to be changed, inclusive
    function _changePriceVertex(uint8 _startExclusive, uint8 _endInclusive) private {
        uint160 indexPriceX96 = priceFeed.getMaxPriceX96(token);
        uint128 liquidity = uint128(Math.min(globalLiquidityPosition.liquidity, priceState0.maxPriceImpactLiquidity));

        unchecked {
            for (uint8 index = _startExclusive + 1; index <= _endInclusive; ++index) {
                (uint32 balanceRate, uint32 premiumRate) = poolFactory.tokenPriceVertexConfigs(token, index);
                (uint128 sizeAfter, uint128 premiumRateAfterX96) = _calculatePriceVertex(
                    balanceRate,
                    premiumRate,
                    liquidity,
                    indexPriceX96
                );
                if (index > 1) {
                    PriceVertex memory previous = priceState0.priceVertices[index - 1];
                    if (previous.size >= sizeAfter || previous.premiumRateX96 >= premiumRateAfterX96)
                        (sizeAfter, premiumRateAfterX96) = (previous.size, previous.premiumRateX96);
                }

                priceState0.priceVertices[index].size = sizeAfter;
                priceState0.priceVertices[index].premiumRateX96 = premiumRateAfterX96;
                emit PriceVertexChanged(index, sizeAfter, premiumRateAfterX96);

                // If the vertex represented by end is the same as the vertex represented by end + 1,
                // then the vertices in range (start, LATEST_VERTEX] need to be updated
                if (index == _endInclusive && _endInclusive < Constants.LATEST_VERTEX) {
                    PriceVertex memory next = priceState0.priceVertices[index + 1];
                    if (sizeAfter >= next.size || premiumRateAfterX96 >= next.premiumRateX96)
                        _endInclusive = Constants.LATEST_VERTEX;
                }
            }
        }
    }

    function _calculatePriceVertex(
        uint32 _balanceRate,
        uint32 _premiumRate,
        uint128 _liquidity,
        uint160 _indexPriceX96
    ) private pure returns (uint128 size, uint128 premiumRateX96) {
        unchecked {
            uint256 balanceRateX96 = (Constants.Q96 * _balanceRate) / Constants.BASIS_POINTS_DIVISOR;
            size = Math.mulDiv(balanceRateX96, _liquidity, _indexPriceX96).toUint128();

            premiumRateX96 = uint128((Constants.Q96 * _premiumRate) / Constants.BASIS_POINTS_DIVISOR);
        }
    }

    function _updateUnrealizedLossMetrics(
        GlobalLiquidityPosition memory _globalPositionCache,
        int256 _liquidityDelta
    ) private returns (uint64 blockTimestamp, uint256 unrealizedLoss, GlobalUnrealizedLossMetrics memory metricsCache) {
        blockTimestamp = _blockTimestamp();
        unrealizedLoss = LiquidityPositionUtil.calculateUnrealizedLoss(
            _globalPositionCache.side,
            _globalPositionCache.netSize + _globalPositionCache.liquidationBufferNetSize,
            _globalPositionCache.entryPriceX96,
            _chooseIndexPriceX96(_globalPositionCache.side),
            globalRiskBufferFund.riskBufferFund
        );
        LiquidityPositionUtil.updateUnrealizedLossMetrics(
            globalUnrealizedLossMetrics,
            unrealizedLoss,
            blockTimestamp,
            _liquidityDelta,
            blockTimestamp,
            unrealizedLoss
        );

        metricsCache = _emitGlobalUnrealizedLossMetricsChangedEvent();
    }

    function _emitGlobalUnrealizedLossMetricsChangedEvent()
        private
        returns (GlobalUnrealizedLossMetrics memory metricsCache)
    {
        metricsCache = globalUnrealizedLossMetrics;
        emit GlobalUnrealizedLossMetricsChanged(
            metricsCache.lastZeroLossTime,
            metricsCache.liquidity,
            metricsCache.liquidityTimesUnrealizedLoss
        );
    }

    /// @dev Choose the index price function, which returns the maximum or minimum price index
    /// based on the given side (Long or Short)
    /// @param _side The side of the position, long for increasing long position or decreasing short position,
    /// short for increasing short position or decreasing long position
    function _chooseIndexPriceX96(Side _side) private view returns (uint160) {
        return _side.isLong() ? priceFeed.getMaxPriceX96(token) : priceFeed.getMinPriceX96(token);
    }

    function _calculateFundingRateTime(uint64 _timestamp) private pure returns (uint64) {
        // prettier-ignore
        unchecked { return _timestamp - (_timestamp % Constants.ADJUST_FUNDING_RATE_INTERVAL); }
    }

    /// @notice Validate the position has not reached the liquidation margin rate
    /// @param _margin The margin of the position
    /// @param _side The side of the position
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _decreasePriceX96 The price at which the position is decreased, as a Q64.96
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// param _liquidatablePosition Whether it is a liquidatable position, if true, the position must be liquidatable,
    /// otherwise the position must be non-liquidatable
    function _validatePositionLiquidateMaintainMarginRate(
        int256 _margin,
        Side _side,
        uint128 _size,
        uint160 _entryPriceX96,
        uint160 _decreasePriceX96,
        uint32 _tradingFeeRate,
        bool _liquidatablePosition
    ) private view {
        int256 unrealizedPnL = PositionUtil.calculateUnrealizedPnL(_side, _size, _entryPriceX96, _decreasePriceX96);
        uint256 maintenanceMargin = PositionUtil.calculateMaintenanceMargin(
            _size,
            _entryPriceX96,
            _decreasePriceX96,
            tokenConfig.liquidationFeeRatePerPosition,
            _tradingFeeRate,
            tokenConfig.liquidationExecutionFee
        );
        int256 marginAfter = _margin + unrealizedPnL;
        if (!_liquidatablePosition) {
            if (_margin <= 0 || marginAfter <= 0 || maintenanceMargin >= uint256(marginAfter))
                revert MarginRateTooHigh(_margin, unrealizedPnL, maintenanceMargin);
        } else {
            if (_margin > 0 && marginAfter > 0 && maintenanceMargin < uint256(marginAfter))
                revert MarginRateTooLow(_margin, unrealizedPnL, maintenanceMargin);
        }
    }

    function _liquidatePosition(
        GlobalLiquidityPosition memory _globalLiquidityPositionCache,
        Position memory _positionCache,
        TradingFeeState memory _tradingFeeState,
        address _account,
        Side _side,
        uint160 decreaseIndexPriceX96,
        int256 requiredFundingFee,
        address _feeReceiver
    ) private {
        // transfer liquidation fee directly to fee receiver
        _transferOutAndUpdateBalance(_feeReceiver, tokenConfig.liquidationExecutionFee);

        (uint160 liquidationPriceX96, int256 adjustedFundingFee) = PositionUtil.calculateLiquidationPriceX96(
            _positionCache,
            previousGlobalFundingRate,
            _side,
            requiredFundingFee,
            tokenConfig.liquidationFeeRatePerPosition,
            _tradingFeeState.tradingFeeRate,
            tokenConfig.liquidationExecutionFee
        );

        uint128 liquidationFee = PositionUtil.calculateLiquidationFee(
            _positionCache.size,
            _positionCache.entryPriceX96,
            tokenConfig.liquidationFeeRatePerPosition
        );
        int256 riskBufferFundDelta = int256(uint256(liquidationFee));

        if (requiredFundingFee != adjustedFundingFee)
            riskBufferFundDelta += _adjustFundingRateByLiquidation(_side, requiredFundingFee, adjustedFundingFee);

        uint128 tradingFee = _adjustGlobalLiquidityPosition(
            _globalLiquidityPositionCache,
            _tradingFeeState,
            _account,
            _side.flip(),
            liquidationPriceX96,
            _positionCache.size,
            riskBufferFundDelta
        );

        _decreaseGlobalPosition(_side, _positionCache.size);

        delete positions[_account][_side];

        emit PositionLiquidated(
            msg.sender,
            _account,
            _side,
            decreaseIndexPriceX96,
            liquidationPriceX96,
            adjustedFundingFee,
            tradingFee,
            liquidationFee,
            tokenConfig.liquidationExecutionFee,
            _feeReceiver
        );
    }

    function _adjustGlobalLiquidityPosition(
        GlobalLiquidityPosition memory _positionCache,
        TradingFeeState memory _tradingFeeState,
        address _account,
        Side _side,
        uint160 _tradePriceX96,
        uint128 _sizeDelta,
        int256 _riskBufferFundDelta
    ) private returns (uint128 tradingFee) {
        (int256 realizedPnL, uint160 entryPriceAfterX96) = LiquidityPositionUtil
            .calculateRealizedPnLAndNextEntryPriceX96(_positionCache, _side, _tradePriceX96, _sizeDelta);

        globalLiquidityPosition.entryPriceX96 = entryPriceAfterX96;
        emit GlobalLiquidityPositionNetPositionAdjusted(
            globalLiquidityPosition.netSize,
            globalLiquidityPosition.liquidationBufferNetSize,
            entryPriceAfterX96,
            globalLiquidityPosition.side
        );

        uint128 liquidityFee;
        uint128 riskBufferFundFee;
        (tradingFee, liquidityFee, riskBufferFundFee) = _calculateFee(
            _tradingFeeState,
            _account,
            _sizeDelta,
            _tradePriceX96
        );

        int256 riskBufferFundRealizedPnLDelta = _riskBufferFundDelta + realizedPnL + riskBufferFundFee.toInt256();

        int256 riskBufferFundAfter = globalRiskBufferFund.riskBufferFund + riskBufferFundRealizedPnLDelta;
        globalRiskBufferFund.riskBufferFund = riskBufferFundAfter;
        emit GlobalRiskBufferFundChanged(riskBufferFundAfter);

        uint256 realizedProfitGrowthAfterX64 = _positionCache.realizedProfitGrowthX64 +
            (uint256(liquidityFee) << 64) /
            _positionCache.liquidity;
        globalLiquidityPosition.realizedProfitGrowthX64 = realizedProfitGrowthAfterX64;
        emit GlobalLiquidityPositionRealizedProfitGrowthChanged(realizedProfitGrowthAfterX64);
    }

    function _calculateFee(
        TradingFeeState memory _tradingFeeState,
        address _account,
        uint128 _sizeDelta,
        uint160 _tradePriceX96
    ) private returns (uint128 tradingFee, uint128 liquidityFee, uint128 riskBufferFundFee) {
        unchecked {
            tradingFee = PositionUtil.calculateTradingFee(_sizeDelta, _tradePriceX96, _tradingFeeState.tradingFeeRate);
            liquidityFee = _splitFee(tradingFee, tokenFeeRateConfig.liquidityFeeRate);

            uint128 _protocolFee = _splitFee(tradingFee, tokenFeeRateConfig.protocolFeeRate);
            protocolFee += _protocolFee; // overflow is desired
            emit ProtocolFeeIncreased(_protocolFee);

            riskBufferFundFee = tradingFee - liquidityFee - _protocolFee;

            if (_tradingFeeState.referralToken > 0) {
                uint128 referralFee = _splitFee(tradingFee, _tradingFeeState.referralReturnFeeRate);
                referralFees[_tradingFeeState.referralToken] += referralFee; // overflow is desired

                uint128 referralParentFee = _splitFee(tradingFee, _tradingFeeState.referralParentReturnFeeRate);
                referralFees[_tradingFeeState.referralParentToken] += referralParentFee; // overflow is desired

                emit ReferralFeeIncreased(
                    _account,
                    _tradingFeeState.referralToken,
                    referralFee,
                    _tradingFeeState.referralParentToken,
                    referralParentFee
                );

                riskBufferFundFee -= referralFee + referralParentFee;
            }
        }
    }

    function _splitFee(uint128 _tradingFee, uint32 _feeRate) private pure returns (uint128 amount) {
        // prettier-ignore
        unchecked { amount = uint128((uint256(_tradingFee) * _feeRate) / Constants.BASIS_POINTS_DIVISOR); }
    }

    function _buildTradingFeeState(address _account) private view returns (TradingFeeState memory state) {
        (state.referralToken, state.referralParentToken) = EFC.referrerTokens(_account);

        if (state.referralToken == 0) state.tradingFeeRate = tokenFeeRateConfig.tradingFeeRate;
        else {
            state.tradingFeeRate = uint32(
                Math.mulDivUp(
                    tokenFeeRateConfig.tradingFeeRate,
                    tokenFeeRateConfig.referralDiscountRate,
                    Constants.BASIS_POINTS_DIVISOR
                )
            );

            state.referralReturnFeeRate = tokenFeeRateConfig.referralReturnFeeRate;
            state.referralParentReturnFeeRate = tokenFeeRateConfig.referralParentReturnFeeRate;
        }
    }

    function _validateGlobalLiquidity(uint128 _globalLiquidity) private pure {
        if (_globalLiquidity == 0) revert InsufficientGlobalLiquidity();
    }

    function _increaseGlobalPosition(Side _side, uint128 _size) private {
        if (_side.isLong()) globalPosition.longSize += _size;
        else globalPosition.shortSize += _size;
    }

    function _decreaseGlobalPosition(Side _side, uint128 _size) private {
        unchecked {
            if (_side.isLong()) globalPosition.longSize -= _size;
            else globalPosition.shortSize -= _size;
        }
    }

    function _sampleAndAdjustFundingRate() private {
        (bool shouldAdjustFundingRate, int256 fundingRateDeltaX96) = FundingRateUtil.samplePremiumRate(
            globalFundingRateSample,
            globalLiquidityPosition,
            priceState0,
            tokenConfig.interestRate,
            _blockTimestamp()
        );

        if (shouldAdjustFundingRate) {
            GlobalPosition memory globalPositionCache = globalPosition;

            (int256 clampedDeltaX96, int192 longGrowthAfterX96, int192 shortGrowthAfterX96) = FundingRateUtil
                .calculateFundingRateGrowthX96(
                    globalRiskBufferFund,
                    globalPositionCache,
                    fundingRateDeltaX96,
                    tokenConfig.maxFundingRate,
                    priceFeed.getMaxPriceX96(token)
                );

            _snapshotAndAdjustGlobalFundingRate(
                globalPositionCache,
                clampedDeltaX96,
                longGrowthAfterX96,
                shortGrowthAfterX96
            );
        }
    }

    function _adjustFundingRateByLiquidation(
        Side _side,
        int256 _requiredFundingFee,
        int256 _adjustedFundingFee
    ) private returns (int256 riskBufferFundLoss) {
        int256 insufficientFundingFee = _adjustedFundingFee - _requiredFundingFee;
        GlobalPosition memory globalPositionCache = globalPosition;
        uint128 oppositeSize = _side.isLong() ? globalPositionCache.shortSize : globalPositionCache.longSize;
        if (oppositeSize > 0) {
            int192 insufficientFundingRateGrowthDeltaX96 = Math
                .mulDiv(uint256(insufficientFundingFee), Constants.Q96, oppositeSize)
                .toInt256()
                .toInt192();
            int192 longFundingRateGrowthAfterX96 = globalPositionCache.longFundingRateGrowthX96;
            int192 shortFundingRateGrowthAfterX96 = globalPositionCache.shortFundingRateGrowthX96;
            if (_side.isLong()) shortFundingRateGrowthAfterX96 -= insufficientFundingRateGrowthDeltaX96;
            else longFundingRateGrowthAfterX96 -= insufficientFundingRateGrowthDeltaX96;
            _snapshotAndAdjustGlobalFundingRate(
                globalPositionCache,
                0,
                longFundingRateGrowthAfterX96,
                shortFundingRateGrowthAfterX96
            );
        } else riskBufferFundLoss = -insufficientFundingFee;
    }

    function _snapshotAndAdjustGlobalFundingRate(
        GlobalPosition memory _positionCache,
        int256 _fundingRateDeltaX96,
        int192 _longFundingRateGrowthAfterX96,
        int192 _shortFundingRateGrowthAfterX96
    ) private {
        // snapshot previous global funding rate
        previousGlobalFundingRate.longFundingRateGrowthX96 = _positionCache.longFundingRateGrowthX96;
        previousGlobalFundingRate.shortFundingRateGrowthX96 = _positionCache.shortFundingRateGrowthX96;

        globalPosition.longFundingRateGrowthX96 = _longFundingRateGrowthAfterX96;
        globalPosition.shortFundingRateGrowthX96 = _shortFundingRateGrowthAfterX96;
        emit FundingRateGrowthAdjusted(
            _fundingRateDeltaX96,
            _longFundingRateGrowthAfterX96,
            _shortFundingRateGrowthAfterX96,
            globalFundingRateSample.lastAdjustFundingRateTime
        );
    }

    function _blockTimestamp() private view returns (uint64) {
        return block.timestamp.toUint64();
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

interface IRewardFarmCallback {
    /// @notice The callback function was called after referral token bound
    /// @param referee The address of the user who bound the referral token
    /// @param oldReferralToken The referral token that the user had previously bound
    /// @param oldReferralParentToken The parent of the referral token that the user had previously bound
    /// @param newReferralToken The referral token that is currently bound by the user
    /// @param newReferralParentToken The parent of the referral token that is currently bound by the user
    function onChangeReferralToken(
        address referee,
        uint256 oldReferralToken,
        uint256 oldReferralParentToken,
        uint256 newReferralToken,
        uint256 newReferralParentToken
    ) external;

    /// @notice The callback function was called after a new liquidity position was opened
    /// @param account The owner of the liquidity position
    /// @param liquidityDelta The liquidity delta of the position
    function onLiquidityPositionChanged(address account, int256 liquidityDelta) external;

    /// @notice The callback function was called after a risk buffer fund position was changed
    /// @param account The owner of the position
    /// @param liquidityAfter The liquidity of the position after the change
    function onRiskBufferFundPositionChanged(address account, uint256 liquidityAfter) external;

    /// @notice The callback function was called after a position was changed
    /// @param account The owner of the position
    /// @param side The side of the position
    /// @param sizeAfter The size of the position after the change
    /// @param entryPriceAfterX96 The entry price of the position after the change, as a Q64.96
    function onPositionChanged(address account, Side side, uint128 sizeAfter, uint160 entryPriceAfterX96) external;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Constants {
    uint32 internal constant BASIS_POINTS_DIVISOR = 100_000_000;

    uint16 internal constant ADJUST_FUNDING_RATE_INTERVAL = 1 hours;
    uint16 internal constant SAMPLE_PREMIUM_RATE_INTERVAL = 5 seconds;
    uint16 internal constant REQUIRED_SAMPLE_COUNT = ADJUST_FUNDING_RATE_INTERVAL / SAMPLE_PREMIUM_RATE_INTERVAL;
    /// @dev 8 * (1+2+3+...+720) = 8 * ((1+720) * 720 / 2) = 8 * 259560
    uint32 internal constant PREMIUM_RATE_AVG_DENOMINATOR = 8 * 259560;
    /// @dev RoundingUp(50000 / 8 * Q96 / BASIS_POINTS_DIVISOR) = 4951760157141521099596497
    int256 internal constant PREMIUM_RATE_CLAMP_BOUNDARY_X96 = 4951760157141521099596497; // 0.05% / 8

    uint8 internal constant VERTEX_NUM = 7;
    uint8 internal constant LATEST_VERTEX = VERTEX_NUM - 1;

    uint64 internal constant RISK_BUFFER_FUND_LOCK_PERIOD = 90 days;

    uint256 internal constant Q64 = 1 << 64;
    uint256 internal constant Q96 = 1 << 96;

    bytes32 internal constant ROLE_POSITION_LIQUIDATOR = keccak256("ROLE_POSITION_LIQUIDATOR");
    bytes32 internal constant ROLE_LIQUIDITY_POSITION_LIQUIDATOR = keccak256("ROLE_LIQUIDITY_POSITION_LIQUIDATOR");
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./PositionUtil.sol";

/// @notice Utility library for calculating funding rates
library FundingRateUtil {
    using SafeCast for *;

    /// @notice Emitted when the funding rate sample is adjusted
    /// @param sampleCountAfter The adjusted `sampleCount`
    /// @param cumulativePremiumRateAfterX96 The adjusted `cumulativePremiumRateX96`, as a Q80.96
    event GlobalFundingRateSampleAdjusted(uint16 sampleCountAfter, int176 cumulativePremiumRateAfterX96);

    /// @notice Emitted when the risk buffer fund is changed
    event GlobalRiskBufferFundChanged(int256 riskBufferFundAfter);

    /// @notice Sample the premium rate
    /// @param _sample The global funding rate sample
    /// @param _position The global liquidity position
    /// @param _priceState The global price state
    /// @param _interestRate The interest rate used to calculate the funding rate,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _currentTimestamp The current timestamp
    /// @return shouldAdjustFundingRate Whether to adjust the funding rate
    /// @return fundingRateDeltaX96 The delta of the funding rate, as a Q160.96
    function samplePremiumRate(
        IPoolPosition.GlobalFundingRateSample storage _sample,
        IPoolLiquidityPosition.GlobalLiquidityPosition storage _position,
        IPool.PriceState storage _priceState,
        uint32 _interestRate,
        uint64 _currentTimestamp
    ) public returns (bool shouldAdjustFundingRate, int256 fundingRateDeltaX96) {
        uint64 lastAdjustFundingRateTime = _sample.lastAdjustFundingRateTime;
        uint64 maxSamplingTime = lastAdjustFundingRateTime + Constants.ADJUST_FUNDING_RATE_INTERVAL;

        // At most 1 hour of premium rate sampling
        if (maxSamplingTime < _currentTimestamp) _currentTimestamp = maxSamplingTime;

        unchecked {
            uint64 lastSamplingTime = lastAdjustFundingRateTime +
                _sample.sampleCount *
                Constants.SAMPLE_PREMIUM_RATE_INTERVAL;

            uint16 timeDelta = uint16(_currentTimestamp - lastSamplingTime);
            if (timeDelta < Constants.SAMPLE_PREMIUM_RATE_INTERVAL) return (false, 0);

            uint128 premiumRateX96 = _position.liquidity > _priceState.maxPriceImpactLiquidity
                ? uint128(
                    Math.mulDivUp(_priceState.premiumRateX96, _priceState.maxPriceImpactLiquidity, _position.liquidity)
                )
                : _priceState.premiumRateX96;

            (shouldAdjustFundingRate, fundingRateDeltaX96) = _samplePremiumRate(
                _sample,
                _position.side,
                premiumRateX96,
                _interestRate,
                maxSamplingTime,
                timeDelta
            );

            emit GlobalFundingRateSampleAdjusted(_sample.sampleCount, _sample.cumulativePremiumRateX96);
        }
    }

    /// @notice Calculate the funding rate growth
    /// @dev If the opposite position is 0, the funding fee will be accumulated into the risk buffer fund
    /// @param _globalRiskBufferFund The global risk buffer fund
    /// @param _globalPositionCache The global position cache
    /// @param _fundingRateDeltaX96 The delta of the funding rate, as a Q160.96
    /// @param _maxFundingRate The maximum funding rate, denominated in ten thousandths of a bip (i.e. 1e-8).
    /// If the funding rate exceeds the maximum funding rate, the funding rate will be clamped to the maximum funding
    /// rate. If the funding rate is less than the negative value of the maximum funding rate, the funding rate will
    /// be clamped to the negative value of the maximum funding rate
    /// @param _indexPriceX96 The index price, as a Q64.96
    /// @return clampedFundingRateDeltaX96 The clamped delta of the funding rate, as a Q160.96
    /// @return longFundingRateGrowthAfterX96 The long funding rate growth after the funding rate is updated, as
    /// a Q96.96
    /// @return shortFundingRateGrowthAfterX96 The short funding rate growth after the funding rate is updated, as
    /// a Q96.96
    function calculateFundingRateGrowthX96(
        IPoolLiquidityPosition.GlobalRiskBufferFund storage _globalRiskBufferFund,
        IPoolPosition.GlobalPosition memory _globalPositionCache,
        int256 _fundingRateDeltaX96,
        uint32 _maxFundingRate,
        uint160 _indexPriceX96
    )
        public
        returns (
            int256 clampedFundingRateDeltaX96,
            int192 longFundingRateGrowthAfterX96,
            int192 shortFundingRateGrowthAfterX96
        )
    {
        // The funding rate is clamped to the maximum funding rate
        int256 maxFundingRateX96 = _calculateMaxFundingRateX96(_maxFundingRate);
        if (_fundingRateDeltaX96 > maxFundingRateX96) clampedFundingRateDeltaX96 = maxFundingRateX96;
        else if (_fundingRateDeltaX96 < -maxFundingRateX96) clampedFundingRateDeltaX96 = -maxFundingRateX96;
        else clampedFundingRateDeltaX96 = _fundingRateDeltaX96;

        (uint128 paidSize, uint128 receivedSize, uint256 clampedFundingRateDeltaAbsX96) = clampedFundingRateDeltaX96 >=
            0
            ? (_globalPositionCache.longSize, _globalPositionCache.shortSize, uint256(clampedFundingRateDeltaX96))
            : (_globalPositionCache.shortSize, _globalPositionCache.longSize, uint256(-clampedFundingRateDeltaX96));

        // paidFundingRateGrowthDelta = (paidSize * price * fundingRate) / paidSize = price * fundingRate
        int192 paidFundingRateGrowthDeltaX96 = Math
            .mulDivUp(_indexPriceX96, clampedFundingRateDeltaAbsX96, Constants.Q96)
            .toInt256()
            .toInt192();

        int192 receivedFundingRateGrowthDeltaX96;
        if (paidFundingRateGrowthDeltaX96 > 0) {
            if (receivedSize > 0) {
                // receivedFundingRateGrowthDelta = (paidSize * price * fundingRate) / receivedSize
                //                                = (paidSize * paidFundingRateGrowthDelta) / receivedSize
                receivedFundingRateGrowthDeltaX96 = Math
                    .mulDiv(paidSize, uint192(paidFundingRateGrowthDeltaX96), receivedSize)
                    .toInt256()
                    .toInt192();
            } else {
                // riskBufferFundDelta = paidSize * price * fundingRate
                int256 riskBufferFundDelta = int256(
                    Math.mulDiv(paidSize, uint192(paidFundingRateGrowthDeltaX96), Constants.Q96)
                );
                int256 riskBufferFundAfter = _globalRiskBufferFund.riskBufferFund + riskBufferFundDelta;
                _globalRiskBufferFund.riskBufferFund = riskBufferFundAfter;
                emit GlobalRiskBufferFundChanged(riskBufferFundAfter);
            }
        }

        longFundingRateGrowthAfterX96 = _globalPositionCache.longFundingRateGrowthX96;
        shortFundingRateGrowthAfterX96 = _globalPositionCache.shortFundingRateGrowthX96;
        if (clampedFundingRateDeltaX96 >= 0) {
            longFundingRateGrowthAfterX96 -= paidFundingRateGrowthDeltaX96;
            shortFundingRateGrowthAfterX96 += receivedFundingRateGrowthDeltaX96;
        } else {
            shortFundingRateGrowthAfterX96 -= paidFundingRateGrowthDeltaX96;
            longFundingRateGrowthAfterX96 += receivedFundingRateGrowthDeltaX96;
        }
    }

    function _calculateMaxFundingRateX96(uint32 _maxFundingRate) private pure returns (int256 maxFundingRateX96) {
        return int256(Math.mulDivUp(_maxFundingRate, Constants.Q96, Constants.BASIS_POINTS_DIVISOR));
    }

    function _samplePremiumRate(
        IPoolPosition.GlobalFundingRateSample storage _sample,
        Side _side,
        uint128 _premiumRateX96,
        uint32 _interestRate,
        uint64 _maxSamplingTime,
        uint16 _timeDelta
    ) internal returns (bool shouldAdjustFundingRate, int256 fundingRateDeltaX96) {
        // When the net position held by LP is long, the premium rate is negative, otherwise it is positive
        int176 premiumRateX96 = _side.isLong() ? -int176(uint176(_premiumRateX96)) : int176(uint176(_premiumRateX96));

        int176 cumulativePremiumRateX96;
        unchecked {
            // The number of samples is limited to a maximum of 720, so there will be no overflow here
            uint16 sampleCountDelta = _timeDelta / Constants.SAMPLE_PREMIUM_RATE_INTERVAL;
            uint16 sampleCountAfter = _sample.sampleCount + sampleCountDelta;
            // formula: cumulativePremiumRateDeltaX96 = premiumRateX96 * (n + (n+1) + (n+2) + ... + (n+m))
            // Since (n + (n+1) + (n+2) + ... + (n+m)) is at most equal to 259560, it can be stored using int24.
            // Additionally, since the type of premiumRateX96 is int136, storing the result of
            // type(int136).max * type(int24).max in int176 will not overflow
            int176 cumulativePremiumRateDeltaX96 = premiumRateX96 *
                int24(((uint24(_sample.sampleCount) + 1 + sampleCountAfter) * sampleCountDelta) >> 1);
            cumulativePremiumRateX96 = _sample.cumulativePremiumRateX96 + cumulativePremiumRateDeltaX96;

            // If the sample count is less than the required sample count, there is no need to update the funding rate
            if (sampleCountAfter < Constants.REQUIRED_SAMPLE_COUNT) {
                _sample.sampleCount = sampleCountAfter;
                _sample.cumulativePremiumRateX96 = cumulativePremiumRateX96;
                return (false, 0);
            }
        }

        int256 premiumRateAvgX96 = cumulativePremiumRateX96 >= 0
            ? int256(Math.ceilDiv(uint256(int256(cumulativePremiumRateX96)), Constants.PREMIUM_RATE_AVG_DENOMINATOR))
            : -int256(Math.ceilDiv(uint256(-int256(cumulativePremiumRateX96)), Constants.PREMIUM_RATE_AVG_DENOMINATOR));

        fundingRateDeltaX96 = premiumRateAvgX96 + _clamp(premiumRateAvgX96, _interestRate);

        // Update the sample data
        _sample.lastAdjustFundingRateTime = _maxSamplingTime;
        _sample.sampleCount = 0;
        _sample.cumulativePremiumRateX96 = 0;

        return (true, fundingRateDeltaX96);
    }

    function _clamp(int256 _premiumRateAvgX96, uint32 _interestRate) private pure returns (int256) {
        int256 interestRateX96 = int256(Math.mulDivUp(_interestRate, Constants.Q96, Constants.BASIS_POINTS_DIVISOR));
        int256 rateDeltaX96 = interestRateX96 - _premiumRateAvgX96;
        if (rateDeltaX96 > Constants.PREMIUM_RATE_CLAMP_BOUNDARY_X96) return Constants.PREMIUM_RATE_CLAMP_BOUNDARY_X96;
        else if (rateDeltaX96 < -Constants.PREMIUM_RATE_CLAMP_BOUNDARY_X96)
            return -Constants.PREMIUM_RATE_CLAMP_BOUNDARY_X96;
        else return rateDeltaX96;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./PositionUtil.sol";

/// @notice Utility library for liquidity positions
library LiquidityPositionUtil {
    using SafeCast for *;

    /// @notice Insufficient risk buffer fund
    error InsufficientRiskBufferFund(int256 unrealizedLoss, uint128 requiredRiskBufferFund);
    /// @notice The position has not reached the unlock time
    error UnlockTimeNotReached(uint64 requiredUnlockTime);
    /// @notice Insufficient liquidity
    error InsufficientLiquidity(uint256 liquidity, uint256 requiredLiquidity);
    /// @notice The risk buffer fund is experiencing losses
    error RiskBufferFundLoss();

    /// @notice Calculate the unrealized loss of the net position held by all LPs
    /// @param _side The side of the position (Long or Short)
    /// @param _netSize The size of the net position held by all LPs
    /// @param _entryPriceX96 The entry price of the net position held by all LPs, as a Q64.96
    /// @param _indexPriceX96 The index price, as a Q64.96
    /// @param _riskBufferFund The risk buffer fund
    /// @return unrealizedLoss The unrealized loss of the net position held by all LPs
    function calculateUnrealizedLoss(
        Side _side,
        uint128 _netSize,
        uint160 _entryPriceX96,
        uint160 _indexPriceX96,
        int256 _riskBufferFund
    ) internal pure returns (uint256 unrealizedLoss) {
        int256 unrealizedPnL = PositionUtil.calculateUnrealizedPnL(_side, _netSize, _entryPriceX96, _indexPriceX96);
        unrealizedPnL += _riskBufferFund;
        // Even if `unrealizedPnL` is `type(int256).min`, the unsafe type conversion
        // will still produce the correct result
        // prettier-ignore
        unchecked { return unrealizedPnL >= 0 ? 0 : uint256(-unrealizedPnL); }
    }

    /// @notice Update the global unrealized loss metrics
    /// @param _metrics The current metrics
    /// @param _currentUnrealizedLoss The current unrealized loss of the net position held by all LPs,
    /// see `calculateUnrealizedLoss`
    /// @param _currentTimestamp The current timestamp
    /// @param _liquidityDelta The change in liquidity, positive for increase, negative for decrease
    /// @param _liquidityDeltaEntryTime The entry time of the liquidity delta
    /// @param _liquidityDeltaEntryUnrealizedLoss The snapshot of unrealized loss
    /// at the entry time of the liquidity delta
    function updateUnrealizedLossMetrics(
        IPoolLiquidityPosition.GlobalUnrealizedLossMetrics storage _metrics,
        uint256 _currentUnrealizedLoss,
        uint64 _currentTimestamp,
        int256 _liquidityDelta,
        uint64 _liquidityDeltaEntryTime,
        uint256 _liquidityDeltaEntryUnrealizedLoss
    ) internal {
        if (_currentUnrealizedLoss == 0) {
            _metrics.lastZeroLossTime = _currentTimestamp;
            _metrics.liquidity = 0;
            _metrics.liquidityTimesUnrealizedLoss = 0;
        } else if (_liquidityDeltaEntryTime > _metrics.lastZeroLossTime && _liquidityDelta != 0) {
            if (_liquidityDelta > 0) {
                // The liquidityDelta is at most type(uint128).max, so liquidityDelta will not overflow here
                _metrics.liquidity += uint128(uint256(_liquidityDelta));
                _metrics.liquidityTimesUnrealizedLoss += _liquidityDeltaEntryUnrealizedLoss * uint256(_liquidityDelta);
            } else {
                unchecked {
                    // The liquidityDelta is at most -type(uint128).max, so -liquidityDelta will not overflow here
                    uint256 liquidityDeltaCast = uint256(-_liquidityDelta);
                    _metrics.liquidity -= uint128(liquidityDeltaCast);
                    _metrics.liquidityTimesUnrealizedLoss -= _liquidityDeltaEntryUnrealizedLoss * liquidityDeltaCast;
                }
            }
        }
    }

    /// @notice Calculate the realized profit of the specified LP position
    function calculateRealizedProfit(
        IPoolLiquidityPosition.LiquidityPosition memory _positionCache,
        IPoolLiquidityPosition.GlobalLiquidityPosition memory _globalPositionCache
    ) internal pure returns (uint256 realizedProfit) {
        uint256 deltaX64;
        unchecked {
            deltaX64 = _globalPositionCache.realizedProfitGrowthX64 - _positionCache.entryRealizedProfitGrowthX64;
        }
        realizedProfit = Math.mulDiv(deltaX64, _positionCache.liquidity, Constants.Q64);
    }

    /// @notice Calculate the unrealized loss for the specified LP position
    /// @param _globalLiquidity The total liquidity of all LPs
    /// @param _unrealizedLoss The current unrealized loss of the net position held by all LPs,
    /// see `calculateUnrealizedLoss`
    /// @return positionUnrealizedLoss The unrealized loss incurred by the position at the time of closing
    function calculatePositionUnrealizedLoss(
        IPoolLiquidityPosition.LiquidityPosition memory _positionCache,
        IPoolLiquidityPosition.GlobalUnrealizedLossMetrics memory _metricsCache,
        uint128 _globalLiquidity,
        uint256 _unrealizedLoss
    ) internal pure returns (uint128 positionUnrealizedLoss) {
        unchecked {
            if (_positionCache.entryTime > _metricsCache.lastZeroLossTime) {
                if (_unrealizedLoss > _positionCache.entryUnrealizedLoss)
                    positionUnrealizedLoss = Math
                        .mulDivUp(
                            _unrealizedLoss - _positionCache.entryUnrealizedLoss,
                            _positionCache.liquidity,
                            _globalLiquidity
                        )
                        .toUint128();
            } else {
                uint256 wamUnrealizedLoss = calculateWAMUnrealizedLoss(_metricsCache);
                uint128 liquidityDelta = _globalLiquidity - _metricsCache.liquidity;
                if (_unrealizedLoss > wamUnrealizedLoss) {
                    positionUnrealizedLoss = Math
                        .mulDivUp(_unrealizedLoss - wamUnrealizedLoss, _positionCache.liquidity, _globalLiquidity)
                        .toUint128();
                    positionUnrealizedLoss += Math
                        .mulDivUp(wamUnrealizedLoss, _positionCache.liquidity, liquidityDelta)
                        .toUint128();
                } else {
                    positionUnrealizedLoss = Math
                        .mulDivUp(_unrealizedLoss, _positionCache.liquidity, liquidityDelta)
                        .toUint128();
                }
            }
        }
    }

    /// @notice Calculate the weighted average mean (WAM) component of the unrealized loss
    /// for the specified LP position
    function calculateWAMUnrealizedLoss(
        IPoolLiquidityPosition.GlobalUnrealizedLossMetrics memory _metricsCache
    ) internal pure returns (uint256 wamUnrealizedLoss) {
        if (_metricsCache.liquidity > 0)
            wamUnrealizedLoss = Math.ceilDiv(_metricsCache.liquidityTimesUnrealizedLoss, _metricsCache.liquidity);
    }

    /// @notice Calculate the realized PnL and next entry price of the LP net position
    /// @param _side The side of the trader's position adjustment, long for increasing long position
    /// or decreasing short position, short for increasing short position or decreasing long position
    /// @param _tradePriceX96 The trade price of the trader's position adjustment, as a Q64.96
    /// @param _sizeDelta The size adjustment of the trader's position
    /// @return realizedPnL The realized PnL of the LP net position
    /// @param entryPriceAfterX96 The next entry price of the LP net position, as a Q64.96
    function calculateRealizedPnLAndNextEntryPriceX96(
        IPoolLiquidityPosition.GlobalLiquidityPosition memory _positionCache,
        Side _side,
        uint160 _tradePriceX96,
        uint128 _sizeDelta
    ) internal pure returns (int256 realizedPnL, uint160 entryPriceAfterX96) {
        entryPriceAfterX96 = _positionCache.entryPriceX96;

        unchecked {
            uint256 netSizeAfter = uint256(_positionCache.netSize) + _positionCache.liquidationBufferNetSize;
            if (netSizeAfter > 0 && _side == _positionCache.side) {
                uint128 sizeUsed = _sizeDelta > netSizeAfter ? uint128(netSizeAfter) : _sizeDelta;
                realizedPnL = PositionUtil.calculateUnrealizedPnL(
                    _side,
                    sizeUsed,
                    _positionCache.entryPriceX96,
                    _tradePriceX96
                );

                _sizeDelta -= sizeUsed;
                netSizeAfter -= sizeUsed;

                if (netSizeAfter == 0) entryPriceAfterX96 = 0;
            }

            if (_sizeDelta > 0)
                entryPriceAfterX96 = PositionUtil.calculateNextEntryPriceX96(
                    _side.flip(),
                    netSizeAfter.toUint128(),
                    entryPriceAfterX96,
                    _sizeDelta,
                    _tradePriceX96
                );
        }
    }

    /// @notice `Gov` uses the risk buffer fund
    /// @return riskBufferFundAfter The total risk buffer fund after the use
    function govUseRiskBufferFund(
        IPoolLiquidityPosition.GlobalLiquidityPosition storage _position,
        IPoolLiquidityPosition.GlobalRiskBufferFund storage _riskBufferFund,
        uint160 _indexPriceX96,
        uint128 _riskBufferFundDelta
    ) public returns (int256 riskBufferFundAfter) {
        // Calculate the unrealized loss of the net position held by all LPs
        int256 unrealizedLoss = PositionUtil.calculateUnrealizedPnL(
            _position.side,
            _position.netSize + _position.liquidationBufferNetSize,
            _position.entryPriceX96,
            _indexPriceX96
        );
        unrealizedLoss = unrealizedLoss >= 0 ? int256(0) : -unrealizedLoss;

        riskBufferFundAfter = _riskBufferFund.riskBufferFund - int256(uint256(_riskBufferFundDelta));
        if (riskBufferFundAfter - unrealizedLoss - _riskBufferFund.liquidity.toInt256() < 0)
            revert InsufficientRiskBufferFund(unrealizedLoss, _riskBufferFundDelta);

        _riskBufferFund.riskBufferFund = riskBufferFundAfter;
    }

    /// @notice Increase the liquidity of a risk buffer fund position
    /// @return positionLiquidityAfter The total liquidity of the position after the increase
    /// @return unlockTimeAfter The unlock time of the position after the increase
    /// @return riskBufferFundAfter The total risk buffer fund after the increase
    function increaseRiskBufferFundPosition(
        IPoolLiquidityPosition.GlobalRiskBufferFund storage _riskBufferFund,
        mapping(address => IPoolLiquidityPosition.RiskBufferFundPosition) storage _positions,
        address _account,
        uint128 _liquidityDelta
    ) public returns (uint128 positionLiquidityAfter, uint64 unlockTimeAfter, int256 riskBufferFundAfter) {
        _riskBufferFund.liquidity += _liquidityDelta;

        IPoolLiquidityPosition.RiskBufferFundPosition storage position = _positions[_account];
        positionLiquidityAfter = position.liquidity + _liquidityDelta;
        unlockTimeAfter = block.timestamp.toUint64() + Constants.RISK_BUFFER_FUND_LOCK_PERIOD;

        position.liquidity = positionLiquidityAfter;
        position.unlockTime = unlockTimeAfter;

        riskBufferFundAfter = _riskBufferFund.riskBufferFund + _liquidityDelta.toInt256();
        _riskBufferFund.riskBufferFund = riskBufferFundAfter;
    }

    /// @notice Decrease the liquidity of a risk buffer fund position
    /// @return positionLiquidityAfter The total liquidity of the position after the decrease
    /// @return riskBufferFundAfter The total risk buffer fund after the decrease
    function decreaseRiskBufferFundPosition(
        IPoolLiquidityPosition.GlobalLiquidityPosition storage _globalPosition,
        IPoolLiquidityPosition.GlobalRiskBufferFund storage _riskBufferFund,
        mapping(address => IPoolLiquidityPosition.RiskBufferFundPosition) storage _positions,
        uint160 _indexPriceX96,
        address _account,
        uint128 _liquidityDelta
    ) public returns (uint128 positionLiquidityAfter, int256 riskBufferFundAfter) {
        IPoolLiquidityPosition.RiskBufferFundPosition memory positionCache = _positions[_account];

        if (positionCache.unlockTime >= block.timestamp) revert UnlockTimeNotReached(positionCache.unlockTime);

        if (positionCache.liquidity < _liquidityDelta)
            revert InsufficientLiquidity(positionCache.liquidity, _liquidityDelta);

        int256 unrealizedPnL = PositionUtil.calculateUnrealizedPnL(
            _globalPosition.side,
            _globalPosition.netSize + _globalPosition.liquidationBufferNetSize,
            _globalPosition.entryPriceX96,
            _indexPriceX96
        );
        if (_riskBufferFund.riskBufferFund + unrealizedPnL - _riskBufferFund.liquidity.toInt256() < 0)
            revert RiskBufferFundLoss();

        unchecked {
            positionLiquidityAfter = positionCache.liquidity - _liquidityDelta;

            if (positionLiquidityAfter == 0) delete _positions[_account];
            else _positions[_account].liquidity = positionLiquidityAfter;

            _riskBufferFund.liquidity -= _liquidityDelta;
        }

        riskBufferFundAfter = _riskBufferFund.riskBufferFund - _liquidityDelta.toInt256();
        _riskBufferFund.riskBufferFund = riskBufferFundAfter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Math as _math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Math library
/// @dev Derived from OpenZeppelin's Math library. To avoid conflicts with OpenZeppelin's Math,
/// it has been renamed to `M` here. Import it using the following statement:
///      import {M as Math} from "path/to/Math.sol";
library M {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Calculate `a / b` with rounding up
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // Guarantee the same behavior as in a regular Solidity division
        if (b == 0) return a / b;

        // prettier-ignore
        unchecked { return a == 0 ? 0 : (a - 1) / b + 1; }
    }

    /// @notice Calculate `x * y / denominator` with rounding down
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator);
    }

    /// @notice Calculate `x * y / denominator` with rounding up
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator, _math.Rounding.Up);
    }

    /// @notice Calculate `x * y / denominator` with rounding down and up
    /// @return result Result with rounding down
    /// @return resultUp Result with rounding up
    function mulDiv2(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result, uint256 resultUp) {
        result = _math.mulDiv(x, y, denominator);
        resultUp = result;
        if (mulmod(x, y, denominator) > 0) resultUp += 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Constants.sol";
import "../core/interfaces/IPoolFactory.sol";

/// @notice Utility library for Pool
library PoolUtil {
    function changeTokenConfig(
        IConfigurable.TokenConfig storage _tokenConfig,
        IConfigurable.TokenFeeRateConfig storage _tokenFeeRateConfig,
        IPool.PriceState storage _priceState,
        IPoolFactory _poolFactory,
        IERC20 _token
    ) public {
        _changeTokenConfig(_tokenConfig, _poolFactory, _token);

        _changeTokenFeeRateConfig(_tokenFeeRateConfig, _poolFactory, _token);

        _changeTokenPriceConfig(_priceState, _poolFactory, _token);
    }

    function _changeTokenConfig(
        IConfigurable.TokenConfig storage _tokenConfig,
        IPoolFactory _poolFactory,
        IERC20 _token
    ) private {
        (
            _tokenConfig.minMarginPerLiquidityPosition,
            _tokenConfig.maxRiskRatePerLiquidityPosition,
            _tokenConfig.maxLeveragePerLiquidityPosition,
            _tokenConfig.minMarginPerPosition,
            _tokenConfig.maxLeveragePerPosition,
            _tokenConfig.liquidationFeeRatePerPosition,
            _tokenConfig.liquidationExecutionFee,
            _tokenConfig.interestRate,
            _tokenConfig.maxFundingRate
        ) = _poolFactory.tokenConfigs(_token);
    }

    function _changeTokenFeeRateConfig(
        IConfigurable.TokenFeeRateConfig storage _tokenFeeRateConfig,
        IPoolFactory _poolFactory,
        IERC20 _token
    ) private {
        (
            _tokenFeeRateConfig.tradingFeeRate,
            _tokenFeeRateConfig.liquidityFeeRate,
            _tokenFeeRateConfig.protocolFeeRate,
            _tokenFeeRateConfig.referralReturnFeeRate,
            _tokenFeeRateConfig.referralParentReturnFeeRate,
            _tokenFeeRateConfig.referralDiscountRate
        ) = _poolFactory.tokenFeeRateConfigs(_token);
    }

    function _changeTokenPriceConfig(
        IPool.PriceState storage _priceState,
        IPoolFactory _poolFactory,
        IERC20 _token
    ) private {
        (uint128 _liquidity, uint8 _index) = _poolFactory.tokenPriceConfigs(_token);
        (_priceState.maxPriceImpactLiquidity, _priceState.liquidationVertexIndex) = (_liquidity, _index);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {M as Math} from "./Math.sol";
import "./Constants.sol";
import "./SafeCast.sol";
import "../core/interfaces/IPool.sol";
import {Side} from "../types/Side.sol";

/// @notice Utility library for trader positions
library PositionUtil {
    using SafeCast for *;

    /// @notice Calculate the next entry price of a position
    /// @param _side The side of the position (Long or Short)
    /// @param _sizeBefore The size of the position before the trade
    /// @param _entryPriceBeforeX96 The entry price of the position before the trade, as a Q64.96
    /// @param _sizeDelta The size of the trade
    /// @param _tradePriceX96 The price of the trade, as a Q64.96
    /// @return nextEntryPriceX96 The entry price of the position after the trade, as a Q64.96
    function calculateNextEntryPriceX96(
        Side _side,
        uint128 _sizeBefore,
        uint160 _entryPriceBeforeX96,
        uint128 _sizeDelta,
        uint160 _tradePriceX96
    ) internal pure returns (uint160 nextEntryPriceX96) {
        if ((_sizeBefore | _sizeDelta) == 0) nextEntryPriceX96 = 0;
        else if (_sizeBefore == 0) nextEntryPriceX96 = _tradePriceX96;
        else if (_sizeDelta == 0) nextEntryPriceX96 = _entryPriceBeforeX96;
        else {
            uint256 liquidityAfterX96 = uint256(_sizeBefore) * _entryPriceBeforeX96;
            liquidityAfterX96 += uint256(_sizeDelta) * _tradePriceX96;
            unchecked {
                uint256 sizeAfter = uint256(_sizeBefore) + _sizeDelta;
                nextEntryPriceX96 = (
                    _side.isLong() ? Math.ceilDiv(liquidityAfterX96, sizeAfter) : liquidityAfterX96 / sizeAfter
                ).toUint160();
            }
        }
    }

    /// @notice Calculate the liquidity (value) of a position
    /// @param _size The size of the position
    /// @param _priceX96 The trade price, as a Q64.96
    /// @return liquidity The liquidity (value) of the position
    function calculateLiquidity(uint128 _size, uint160 _priceX96) internal pure returns (uint128 liquidity) {
        liquidity = Math.mulDivUp(_size, _priceX96, Constants.Q96).toUint128();
    }

    /// @dev Calculate the unrealized PnL of a position based on entry price
    /// @param _side The side of the position (Long or Short)
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _priceX96 The trade price or index price, as a Q64.96
    /// @return unrealizedPnL The unrealized PnL of the position, positive value means profit,
    /// negative value means loss
    function calculateUnrealizedPnL(
        Side _side,
        uint128 _size,
        uint160 _entryPriceX96,
        uint160 _priceX96
    ) internal pure returns (int256 unrealizedPnL) {
        unchecked {
            // Because the maximum value of size is type(uint128).max, and the maximum value of entryPriceX96 and
            // priceX96 is type(uint160).max, so the maximum value of
            //      size * (entryPriceX96 - priceX96) / Q96
            // is type(uint192).max, so it is safe to convert the type to int256.
            if (_side.isLong()) {
                if (_entryPriceX96 > _priceX96)
                    unrealizedPnL = -int256(Math.mulDivUp(_size, _entryPriceX96 - _priceX96, Constants.Q96));
                else unrealizedPnL = int256(Math.mulDiv(_size, _priceX96 - _entryPriceX96, Constants.Q96));
            } else {
                if (_entryPriceX96 < _priceX96)
                    unrealizedPnL = -int256(Math.mulDivUp(_size, _priceX96 - _entryPriceX96, Constants.Q96));
                else unrealizedPnL = int256(Math.mulDiv(_size, _entryPriceX96 - _priceX96, Constants.Q96));
            }
        }
    }

    function chooseFundingRateGrowthX96(
        IPoolPosition.GlobalPosition storage _globalPosition,
        Side _side
    ) internal view returns (int192) {
        return _side.isLong() ? _globalPosition.longFundingRateGrowthX96 : _globalPosition.shortFundingRateGrowthX96;
    }

    /// @notice Calculate the trading fee of a trade
    /// @param _size The size of the trade
    /// @param _tradePriceX96 The price of the trade, as a Q64.96
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    function calculateTradingFee(
        uint128 _size,
        uint160 _tradePriceX96,
        uint32 _tradingFeeRate
    ) internal pure returns (uint128 tradingFee) {
        unchecked {
            uint256 denominator = Constants.BASIS_POINTS_DIVISOR * Constants.Q96;
            tradingFee = Math.mulDivUp(uint256(_size) * _tradingFeeRate, _tradePriceX96, denominator).toUint128();
        }
    }

    /// @notice Calculate the liquidation fee of a position
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return liquidationFee The liquidation fee of the position
    function calculateLiquidationFee(
        uint128 _size,
        uint160 _entryPriceX96,
        uint32 _liquidationFeeRate
    ) internal pure returns (uint128 liquidationFee) {
        unchecked {
            uint256 denominator = Constants.BASIS_POINTS_DIVISOR * Constants.Q96;
            liquidationFee = Math
                .mulDivUp(uint256(_size) * _liquidationFeeRate, _entryPriceX96, denominator)
                .toUint128();
        }
    }

    /// @notice Calculate the funding fee of a position
    /// @param _globalFundingRateGrowthX96 The global funding rate growth, as a Q96.96
    /// @param _positionFundingRateGrowthX96 The position funding rate growth, as a Q96.96
    /// @param _positionSize The size of the position
    /// @return fundingFee The funding fee of the position, a positive value means the position receives
    /// funding fee, while a negative value means the position pays funding fee
    function calculateFundingFee(
        int192 _globalFundingRateGrowthX96,
        int192 _positionFundingRateGrowthX96,
        uint128 _positionSize
    ) internal pure returns (int256 fundingFee) {
        int256 deltaX96 = _globalFundingRateGrowthX96 - _positionFundingRateGrowthX96;
        if (deltaX96 >= 0) fundingFee = Math.mulDiv(uint256(deltaX96), _positionSize, Constants.Q96).toInt256();
        else fundingFee = -Math.mulDivUp(uint256(-deltaX96), _positionSize, Constants.Q96).toInt256();
    }

    /// @notice Calculate the maintenance margin
    /// @dev maintenanceMargin = size * (entryPrice * liquidationFeeRate
    ///                          + indexPrice * tradingFeeRate)
    ///                          + liquidationExecutionFee
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _indexPriceX96 The index price, as a Q64.96
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return maintenanceMargin The maintenance margin
    function calculateMaintenanceMargin(
        uint128 _size,
        uint160 _entryPriceX96,
        uint160 _indexPriceX96,
        uint32 _liquidationFeeRate,
        uint32 _tradingFeeRate,
        uint64 _liquidationExecutionFee
    ) internal pure returns (uint256 maintenanceMargin) {
        unchecked {
            maintenanceMargin = Math.mulDivUp(
                _size,
                uint256(_entryPriceX96) * _liquidationFeeRate + uint256(_indexPriceX96) * _tradingFeeRate,
                Constants.BASIS_POINTS_DIVISOR * Constants.Q96
            );
            // Because the maximum value of size is type(uint128).max, and the maximum value of entryPriceX96 and
            // indexPriceX96 is type(uint160).max, and liquidationFeeRate + tradingFeeRate is at most 2 * DIVISOR,
            // so the maximum value of
            //      size * (entryPriceX96 * liquidationFeeRate + indexPriceX96 * tradingFeeRate) / (Q96 * DIVISOR)
            // is type(uint193).max, so there will be no overflow here.
            maintenanceMargin += _liquidationExecutionFee;
        }
    }

    /// @notice calculate the liquidation price
    /// @param _positionCache The cache of position
    /// @param _side The side of the position (Long or Short)
    /// @param _fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return liquidationPriceX96 The liquidation price of the position, as a Q64.96
    /// @return adjustedFundingFee The liquidation price based on the funding fee. If `_fundingFee` is negative,
    /// then this value is not less than `_fundingFee`
    function calculateLiquidationPriceX96(
        IPool.Position memory _positionCache,
        IPool.PreviousGlobalFundingRate storage _previousGlobalFundingRate,
        Side _side,
        int256 _fundingFee,
        uint32 _liquidationFeeRate,
        uint32 _tradingFeeRate,
        uint64 _liquidationExecutionFee
    ) public view returns (uint160 liquidationPriceX96, int256 adjustedFundingFee) {
        int256 marginInt256 = int256(uint256(_positionCache.margin));
        if ((marginInt256 + _fundingFee) > 0) {
            liquidationPriceX96 = _calculateLiquidationPriceX96(
                _positionCache,
                _side,
                _fundingFee,
                _liquidationFeeRate,
                _tradingFeeRate,
                _liquidationExecutionFee
            );
            if (_isAcceptableLiquidationPriceX96(_side, liquidationPriceX96, _positionCache.entryPriceX96))
                return (liquidationPriceX96, _fundingFee);
        }
        // Try to use the previous funding rate to calculate the funding fee
        adjustedFundingFee = calculateFundingFee(
            _choosePreviousGlobalFundingRateGrowthX96(_previousGlobalFundingRate, _side),
            _positionCache.entryFundingRateGrowthX96,
            _positionCache.size
        );
        if (adjustedFundingFee > _fundingFee && (marginInt256 + adjustedFundingFee) > 0) {
            liquidationPriceX96 = _calculateLiquidationPriceX96(
                _positionCache,
                _side,
                adjustedFundingFee,
                _liquidationFeeRate,
                _tradingFeeRate,
                _liquidationExecutionFee
            );
            if (_isAcceptableLiquidationPriceX96(_side, liquidationPriceX96, _positionCache.entryPriceX96))
                return (liquidationPriceX96, adjustedFundingFee);
        } else adjustedFundingFee = _fundingFee;

        // Only try to use zero funding fee calculation when the current best funding fee is negative,
        // then zero funding fee is the best
        if (adjustedFundingFee < 0) {
            adjustedFundingFee = 0;
            liquidationPriceX96 = _calculateLiquidationPriceX96(
                _positionCache,
                _side,
                adjustedFundingFee,
                _liquidationFeeRate,
                _tradingFeeRate,
                _liquidationExecutionFee
            );
        }
    }

    function _choosePreviousGlobalFundingRateGrowthX96(
        IPool.PreviousGlobalFundingRate storage _pgrf,
        Side _side
    ) private view returns (int192) {
        return _side.isLong() ? _pgrf.longFundingRateGrowthX96 : _pgrf.shortFundingRateGrowthX96;
    }

    function _isAcceptableLiquidationPriceX96(
        Side _side,
        uint160 _liquidationPriceX96,
        uint160 _entryPriceX96
    ) private pure returns (bool) {
        return
            (_side.isLong() && _liquidationPriceX96 < _entryPriceX96) ||
            (_side.isShort() && _liquidationPriceX96 > _entryPriceX96);
    }

    /// @notice Calculate the liquidation price
    /// @dev Given the liquidation condition as:
    /// For long position: margin + fundingFee - positionSize * (entryPrice - liquidationPrice)
    ///                     = entryPrice * positionSize * liquidationFeeRate
    ///                         + liquidationPrice * positionSize * tradingFeeRate + liquidationExecutionFee
    /// For short position: margin + fundingFee - positionSize * (liquidationPrice - entryPrice)
    ///                     = entryPrice * positionSize * liquidationFeeRate
    ///                         + liquidationPrice * positionSize * tradingFeeRate + liquidationExecutionFee
    /// We can get:
    /// Long position liquidation price:
    ///     liquidationPrice
    ///       = [margin + fundingFee - liquidationExecutionFee - entryPrice * positionSize * (1 + liquidationFeeRate)]
    ///       / [positionSize * (tradingFeeRate - 1)]
    /// Short position liquidation price:
    ///     liquidationPrice
    ///       = [margin + fundingFee - liquidationExecutionFee + entryPrice * positionSize * (1 - liquidationFeeRate)]
    ///       / [positionSize * (tradingFeeRate + 1)]
    /// @param _positionCache The cache of position
    /// @param _side The side of the position (Long or Short)
    /// @param _fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return liquidationPriceX96 The liquidation price of the position, as a Q64.96
    function _calculateLiquidationPriceX96(
        IPool.Position memory _positionCache,
        Side _side,
        int256 _fundingFee,
        uint32 _liquidationFeeRate,
        uint32 _tradingFeeRate,
        uint64 _liquidationExecutionFee
    ) private pure returns (uint160 liquidationPriceX96) {
        uint256 marginAfter = uint256(_positionCache.margin);
        if (_fundingFee >= 0) marginAfter += uint256(_fundingFee);
        else marginAfter -= uint256(-_fundingFee);

        (uint256 numeratorX96, uint256 denominator) = _side.isLong()
            ? (Constants.BASIS_POINTS_DIVISOR + _liquidationFeeRate, Constants.BASIS_POINTS_DIVISOR - _tradingFeeRate)
            : (Constants.BASIS_POINTS_DIVISOR - _liquidationFeeRate, Constants.BASIS_POINTS_DIVISOR + _tradingFeeRate);

        uint256 numeratorPart2X96 = marginAfter >= _liquidationExecutionFee
            ? marginAfter - _liquidationExecutionFee
            : _liquidationExecutionFee - marginAfter;

        numeratorX96 *= uint256(_positionCache.entryPriceX96) * _positionCache.size;
        denominator *= _positionCache.size;
        numeratorPart2X96 *= Constants.BASIS_POINTS_DIVISOR * Constants.Q96;

        if (_side.isLong()) {
            numeratorX96 = marginAfter >= _liquidationExecutionFee
                ? numeratorX96 - numeratorPart2X96
                : numeratorX96 + numeratorPart2X96;
        } else {
            numeratorX96 = marginAfter >= _liquidationExecutionFee
                ? numeratorX96 + numeratorPart2X96
                : numeratorX96 - numeratorPart2X96;
        }
        liquidationPriceX96 = _side.isLong()
            ? (numeratorX96 / denominator).toUint160()
            : Math.ceilDiv(numeratorX96, denominator).toUint160();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./LiquidityPositionUtil.sol";

library PriceUtil {
    using SafeCast for *;

    struct MoveStep {
        Side side;
        uint128 sizeLeft;
        uint160 indexPriceX96;
        bool improveBalance;
        IPool.PriceVertex from;
        IPool.PriceVertex current;
        IPool.PriceVertex to;
    }

    struct PriceStateCache {
        uint128 premiumRateX96;
        uint8 pendingVertexIndex;
        uint8 liquidationVertexIndex;
        uint8 currentVertexIndex;
    }

    /// @notice Emitted when the premium rate is changed
    event PremiumRateChanged(uint128 premiumRateAfterX96);

    /// @notice Emitted when liquidation buffer net size is changed
    event LiquidationBufferNetSizeChanged(uint8 index, uint128 netSizeAfter);

    /// @notice Emitted when premium rate overflows, should stop calculation
    error MaxPremiumRateExceeded();

    /// @notice Emitted when sizeDelta is zero
    error ZeroSizeDelta();

    /// @notice Calculate trade price and update the price state when traders adjust positions.
    /// For liquidations, call this function to update the price state but the trade price returned is invalid
    /// @param _globalPosition Global position of the lp, will be updated
    /// @param _priceState States of the price, will be updated
    /// @param _side Side of the operation
    /// @param _sizeDelta The adjustment of size
    /// @param _indexPriceX96 The index price, as a Q64.96
    /// @param _liquidation Whether the operation is liquidation
    /// @return tradePriceX96 The average price of the adjustment if liquidation is false, invalid otherwise
    function updatePriceState(
        IPool.GlobalLiquidityPosition storage _globalPosition,
        IPool.PriceState storage _priceState,
        Side _side,
        uint128 _sizeDelta,
        uint160 _indexPriceX96,
        bool _liquidation
    ) public returns (uint160 tradePriceX96) {
        if (_sizeDelta == 0) revert ZeroSizeDelta();
        IPool.GlobalLiquidityPosition memory globalPositionCache = _globalPosition;
        PriceStateCache memory priceStateCache = PriceStateCache({
            premiumRateX96: _priceState.premiumRateX96,
            pendingVertexIndex: _priceState.pendingVertexIndex,
            liquidationVertexIndex: _priceState.liquidationVertexIndex,
            currentVertexIndex: _priceState.currentVertexIndex
        });

        bool improveBalance = _side == globalPositionCache.side &&
            (globalPositionCache.netSize | globalPositionCache.liquidationBufferNetSize) > 0;

        (uint256 tradePriceX96TimesSizeTotal, uint128 sizeLeft, uint128 totalBufferUsed) = _updatePriceState(
            globalPositionCache,
            _priceState,
            priceStateCache,
            _side,
            improveBalance,
            _sizeDelta,
            _indexPriceX96,
            _liquidation
        );

        if (!improveBalance) {
            globalPositionCache.side = _side.flip();
            globalPositionCache.netSize += _sizeDelta - totalBufferUsed;
            globalPositionCache.liquidationBufferNetSize += totalBufferUsed;
        } else {
            // When the net position of LP decreases and reaches or crosses the vertex,
            // at least the vertex represented by (current, pending] needs to be updated
            if (priceStateCache.pendingVertexIndex > priceStateCache.currentVertexIndex) {
                IPool(address(this)).changePriceVertex(
                    priceStateCache.currentVertexIndex,
                    priceStateCache.pendingVertexIndex
                );
                _priceState.pendingVertexIndex = priceStateCache.currentVertexIndex;
            }

            globalPositionCache.netSize -= _sizeDelta - sizeLeft - totalBufferUsed;
            globalPositionCache.liquidationBufferNetSize -= totalBufferUsed;
        }

        if (sizeLeft > 0) {
            assert((globalPositionCache.netSize | globalPositionCache.liquidationBufferNetSize) == 0);

            // Note that if and only if crossed the (0, 0), update the global position side
            globalPositionCache.side = globalPositionCache.side.flip();

            (uint256 tradePriceX96TimesSizeTotal2, , uint128 totalBufferUsed2) = _updatePriceState(
                globalPositionCache,
                _priceState,
                priceStateCache,
                _side,
                false,
                sizeLeft,
                _indexPriceX96,
                _liquidation
            );

            tradePriceX96TimesSizeTotal += tradePriceX96TimesSizeTotal2;

            globalPositionCache.netSize = sizeLeft - totalBufferUsed2;
            globalPositionCache.liquidationBufferNetSize = totalBufferUsed2;
        }

        tradePriceX96 = _side.isLong()
            ? Math.ceilDiv(tradePriceX96TimesSizeTotal, _sizeDelta).toUint160()
            : (tradePriceX96TimesSizeTotal / _sizeDelta).toUint160();

        // Write the changes back to storage
        _globalPosition.side = globalPositionCache.side;
        _globalPosition.netSize = globalPositionCache.netSize;
        _globalPosition.liquidationBufferNetSize = globalPositionCache.liquidationBufferNetSize;
        _priceState.premiumRateX96 = priceStateCache.premiumRateX96;
        _priceState.currentVertexIndex = priceStateCache.currentVertexIndex;

        emit PremiumRateChanged(priceStateCache.premiumRateX96);
    }

    function _updatePriceState(
        IPool.GlobalLiquidityPosition memory _globalPositionCache,
        IPool.PriceState storage _priceState,
        PriceStateCache memory _priceStateCache,
        Side _side,
        bool _improveBalance,
        uint128 _sizeDelta,
        uint160 _indexPriceX96,
        bool _liquidation
    ) internal returns (uint256 tradePriceX96TimesSizeTotal, uint128 sizeLeft, uint128 totalBufferUsed) {
        MoveStep memory step = MoveStep({
            side: _side,
            sizeLeft: _sizeDelta,
            indexPriceX96: _indexPriceX96,
            improveBalance: _improveBalance,
            from: IPool.PriceVertex(0, 0),
            current: IPool.PriceVertex(_globalPositionCache.netSize, _priceStateCache.premiumRateX96),
            to: IPool.PriceVertex(0, 0)
        });
        if (!step.improveBalance) {
            // Balance rate got worse
            if (_priceStateCache.currentVertexIndex == 0) _priceStateCache.currentVertexIndex = 1;
            uint8 end = _liquidation ? _priceStateCache.liquidationVertexIndex + 1 : Constants.VERTEX_NUM;
            for (uint8 i = _priceStateCache.currentVertexIndex; i < end && step.sizeLeft > 0; ++i) {
                (step.from, step.to) = (_priceState.priceVertices[i - 1], _priceState.priceVertices[i]);
                (uint160 tradePriceX96, uint128 sizeUsed, , int256 premiumRateAfterX96) = simulateMove(step);

                if (sizeUsed < step.sizeLeft && !(_liquidation && i == _priceStateCache.liquidationVertexIndex)) {
                    // Crossed
                    // prettier-ignore
                    unchecked { _priceStateCache.currentVertexIndex = i + 1; }
                    step.current = step.to;
                }

                // prettier-ignore
                unchecked { step.sizeLeft -= sizeUsed; }
                tradePriceX96TimesSizeTotal += uint256(tradePriceX96) * sizeUsed;
                _priceStateCache.premiumRateX96 = uint256(premiumRateAfterX96).toUint128();
            }

            if (step.sizeLeft > 0) {
                if (!_liquidation) revert MaxPremiumRateExceeded();

                // prettier-ignore
                unchecked { totalBufferUsed += step.sizeLeft; }

                uint8 liquidationVertexIndex = _priceStateCache.liquidationVertexIndex;
                uint128 liquidationBufferNetSizeAfter = _priceState.liquidationBufferNetSizes[liquidationVertexIndex] +
                    step.sizeLeft;
                _priceState.liquidationBufferNetSizes[liquidationVertexIndex] = liquidationBufferNetSizeAfter;
                emit LiquidationBufferNetSizeChanged(liquidationVertexIndex, liquidationBufferNetSizeAfter);
            }
        } else {
            // Balance rate got better, note that when `i` == 0, loop continues to use liquidation buffer in (0, 0)
            for (uint8 i = _priceStateCache.currentVertexIndex; i >= 0 && step.sizeLeft > 0; --i) {
                // Use liquidation buffer in `from`
                uint128 bufferSizeAfter = _priceState.liquidationBufferNetSizes[i];
                if (bufferSizeAfter > 0) {
                    uint128 sizeUsed = uint128(Math.min(bufferSizeAfter, step.sizeLeft));
                    uint160 tradePriceX96 = calculateMarketPriceX96(
                        _globalPositionCache.side,
                        _side,
                        _indexPriceX96,
                        step.current.premiumRateX96
                    );
                    // prettier-ignore
                    unchecked { bufferSizeAfter -= sizeUsed; }
                    _priceState.liquidationBufferNetSizes[i] = bufferSizeAfter;
                    // prettier-ignore
                    unchecked { totalBufferUsed += sizeUsed; }

                    // prettier-ignore
                    unchecked { step.sizeLeft -= sizeUsed; }
                    tradePriceX96TimesSizeTotal += uint256(tradePriceX96) * sizeUsed;
                    emit LiquidationBufferNetSizeChanged(i, bufferSizeAfter);
                }
                if (i == 0) break;
                if (step.sizeLeft > 0) {
                    step.from = _priceState.priceVertices[uint8(i)];
                    step.to = _priceState.priceVertices[uint8(i - 1)];
                    (uint160 tradePriceX96, uint128 sizeUsed, bool reached, int256 premiumRateAfterX96) = simulateMove(
                        step
                    );
                    if (reached) {
                        // Reached or crossed
                        _priceStateCache.currentVertexIndex = uint8(i - 1);
                        step.current = step.to;
                    }
                    // prettier-ignore
                    unchecked { step.sizeLeft -= sizeUsed; }
                    tradePriceX96TimesSizeTotal += uint256(tradePriceX96) * sizeUsed;
                    _priceStateCache.premiumRateX96 = uint256(premiumRateAfterX96).toUint128();
                }
            }
            sizeLeft = step.sizeLeft;
        }
    }

    function calculateAX96AndBX96(
        Side _globalSide,
        IPool.PriceVertex memory _from,
        IPool.PriceVertex memory _to
    ) internal pure returns (uint256 aX96, int256 bX96) {
        if (_from.size > _to.size) (_from, _to) = (_to, _from);
        assert(_to.premiumRateX96 >= _from.premiumRateX96);

        unchecked {
            uint128 sizeDelta = _to.size - _from.size;
            aX96 = Math.ceilDiv(_to.premiumRateX96 - _from.premiumRateX96, sizeDelta);

            uint256 numeratorPart1X96 = uint256(_from.premiumRateX96) * _to.size;
            uint256 numeratorPart2X96 = uint256(_to.premiumRateX96) * _from.size;
            if (_globalSide.isShort()) {
                if (numeratorPart1X96 >= numeratorPart2X96)
                    bX96 = ((numeratorPart1X96 - numeratorPart2X96) / sizeDelta).toInt256();
                else bX96 = -((numeratorPart2X96 - numeratorPart1X96) / sizeDelta).toInt256();
            } else {
                if (numeratorPart2X96 >= numeratorPart1X96)
                    bX96 = ((numeratorPart2X96 - numeratorPart1X96) / sizeDelta).toInt256();
                else bX96 = -((numeratorPart1X96 - numeratorPart2X96) / sizeDelta).toInt256();
            }
        }
    }

    function simulateMove(
        MoveStep memory _step
    ) internal pure returns (uint160 tradePriceX96, uint128 sizeUsed, bool reached, int256 premiumRateAfterX96) {
        (reached, sizeUsed) = calculateReachedAndSizeUsed(_step);
        premiumRateAfterX96 = calculatePremiumRateAfterX96(_step, reached, sizeUsed);
        int256 premiumRateBeforeX96 = _step.current.premiumRateX96.toInt256();
        (uint256 tradePriceX96Down, uint256 tradePriceX96Up) = Math.mulDiv2(
            _step.indexPriceX96,
            (_step.improveBalance && _step.side.isLong()) || (!_step.improveBalance && _step.side.isShort())
                ? ((int256(Constants.Q96) << 1) - premiumRateBeforeX96 - premiumRateAfterX96).toUint256()
                : ((int256(Constants.Q96) << 1) + premiumRateBeforeX96 + premiumRateAfterX96).toUint256(),
            Constants.Q96 << 1
        );
        tradePriceX96 = (_step.side.isLong() ? tradePriceX96Up : tradePriceX96Down).toUint160();
    }

    function calculateReachedAndSizeUsed(MoveStep memory _step) internal pure returns (bool reached, uint128 sizeUsed) {
        uint128 sizeCost = _step.improveBalance
            ? _step.current.size - _step.to.size
            : _step.to.size - _step.current.size;
        reached = _step.sizeLeft >= sizeCost;
        sizeUsed = reached ? sizeCost : _step.sizeLeft;
    }

    function calculatePremiumRateAfterX96(
        MoveStep memory _step,
        bool _reached,
        uint128 _sizeUsed
    ) internal pure returns (int256 premiumRateAfterX96) {
        if (_reached) {
            premiumRateAfterX96 = _step.to.premiumRateX96.toInt256();
        } else {
            Side globalSide = _step.improveBalance ? _step.side : _step.side.flip();
            (uint256 aX96, int256 bX96) = calculateAX96AndBX96(globalSide, _step.from, _step.to);
            uint256 sizeAfter = _step.improveBalance ? _step.current.size - _sizeUsed : _step.current.size + _sizeUsed;
            if (globalSide.isLong()) bX96 = -bX96;
            premiumRateAfterX96 = (aX96 * sizeAfter).toInt256() + bX96;
        }
    }

    function calculateMarketPriceX96(
        Side _globalSide,
        Side _side,
        uint160 _indexPriceX96,
        uint128 _premiumRateX96
    ) public pure returns (uint160 marketPriceX96) {
        uint256 premiumRateAfterX96 = _globalSide.isLong()
            ? Constants.Q96 - _premiumRateX96
            : Constants.Q96 + _premiumRateX96;
        marketPriceX96 = _side.isLong()
            ? Math.mulDivUp(_indexPriceX96, premiumRateAfterX96, Constants.Q96).toUint160()
            : Math.mulDiv(_indexPriceX96, premiumRateAfterX96, Constants.Q96).toUint160();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.19;

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

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.19;

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
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
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
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
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
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
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
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
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
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
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
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
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
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
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
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
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
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
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
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
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
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
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
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
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
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
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
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
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
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
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
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
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
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
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
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
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
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
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
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
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
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
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
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
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
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
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
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
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
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
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
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
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
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
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
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
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
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
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
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
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
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
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
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
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
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
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
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
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
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
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
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
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
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
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
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
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
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
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
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
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
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
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
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
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
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
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
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
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
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
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
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
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
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
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
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
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
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
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
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
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
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
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
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
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
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
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
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
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
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
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
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
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
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
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
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
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

interface IChainLinkAggregator {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IChainLinkAggregator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeed {
    /// @notice Emitted when token price updated
    /// @param token Token address
    /// @param priceX96 The price passed in by updater, as a Q64.96
    /// @param maxPriceX96 Calculated maximum price, as a Q64.96
    /// @param minPriceX96 Calculated minimum price, as a Q64.96
    event PriceUpdated(IERC20 indexed token, uint160 priceX96, uint160 minPriceX96, uint160 maxPriceX96);

    /// @notice Emitted when maxCumulativeDeltaDiff exceeded
    /// @param token Token address
    /// @param priceX96 The price passed in by updater, as a Q64.96
    /// @param refPriceX96 The price provided by ChainLink, as a Q64.96
    /// @param cumulativeDelta The cumulative value of the price change ratio
    /// @param cumulativeRefDelta The cumulative value of the ChainLink price change ratio
    event MaxCumulativeDeltaDiffExceeded(
        IERC20 token,
        uint160 priceX96,
        uint160 refPriceX96,
        uint64 cumulativeDelta,
        uint64 cumulativeRefDelta
    );

    /// @notice Price not be initialized
    error NotInitialized();

    /// @notice Reference price feed not set
    error ReferencePriceFeedNotSet();

    /// @notice Invalid reference price
    /// @param referencePrice Reference price
    error InvalidReferencePrice(int256 referencePrice);

    /// @notice Reference price timeout
    /// @param elapsed The time elapsed since the last price update.
    error ReferencePriceTimeout(uint256 elapsed);

    /// @notice Stable token price timeout
    /// @param elapsed The time elapsed since the last price update.
    error StableTokenPriceTimeout(uint256 elapsed);

    /// @notice Invalid stable token price
    /// @param stableTokenPrice Stable token price
    error InvalidStableTokenPrice(int256 stableTokenPrice);

    /// @notice Invalid update timestamp
    /// @param timestamp Update timestamp
    error InvalidUpdateTimestamp(uint64 timestamp);
    /// @notice L2 sequencer is down
    error SequencerDown();
    /// @notice Grace period is not over
    /// @param sequencerUptime Sequencer uptime
    error GracePeriodNotOver(uint256 sequencerUptime);

    struct Slot {
        uint32 maxDeviationRatio;
        uint32 cumulativeRoundDuration;
        uint32 refPriceExtraSample;
        uint32 updateTxTimeout;
    }

    struct TokenConfig {
        IChainLinkAggregator refPriceFeed;
        uint32 refHeartbeatDuration;
        uint64 maxCumulativeDeltaDiff;
    }

    struct PriceDataItem {
        uint32 prevRound;
        uint160 prevRefPriceX96;
        uint64 cumulativeRefPriceDelta;
        uint160 prevPriceX96;
        uint64 cumulativePriceDelta;
    }

    struct PricePack {
        uint64 updateTimestamp;
        uint160 maxPriceX96;
        uint160 minPriceX96;
        uint64 updateBlockTimestamp;
    }

    struct TokenPrice {
        IERC20 token;
        uint160 priceX96;
    }

    /// @notice Get the address of stable token price feed
    /// @return priceFeed The address of stable token price feed
    function stableTokenPriceFeed() external view returns (IChainLinkAggregator priceFeed);

    /// @notice Get the expected update interval of stable token price
    /// @return duration The expected update interval of stable token price
    function stableTokenPriceFeedHeartBeatDuration() external view returns (uint32 duration);

    /// @notice The 0th storage slot in the price feed stores many values, which helps reduce gas
    /// costs when interacting with the price feed.
    /// @return maxDeviationRatio Maximum deviation ratio between price and ChainLink price.
    /// @return cumulativeRoundDuration Period for calculating cumulative deviation ratio.
    /// @return refPriceExtraSample The number of additional rounds for ChainLink prices to participate in price
    /// update calculation.
    /// @return updateTxTimeout The timeout for price update transactions.
    function slot()
        external
        view
        returns (
            uint32 maxDeviationRatio,
            uint32 cumulativeRoundDuration,
            uint32 refPriceExtraSample,
            uint32 updateTxTimeout
        );

    /// @notice Get token configuration for updating price
    /// @param token The token address to query the configuration
    /// @return refPriceFeed ChainLink contract address for corresponding token
    /// @return refHeartbeatDuration Expected update interval of chain link price feed
    /// @return maxCumulativeDeltaDiff Maximum cumulative change ratio difference between prices and ChainLink prices
    /// within a period of time.
    function tokenConfigs(
        IERC20 token
    )
        external
        view
        returns (IChainLinkAggregator refPriceFeed, uint32 refHeartbeatDuration, uint64 maxCumulativeDeltaDiff);

    /// @notice Get latest price data for corresponding token.
    /// @param token The token address to query the price data
    /// @return updateTimestamp The timestamp when updater uploads the price
    /// @return maxPriceX96 Calculated maximum price, as a Q64.96
    /// @return minPriceX96 Calculated minimum price, as a Q64.96
    /// @return updateBlockTimestamp The block timestamp when price is committed
    function latestPrices(
        IERC20 token
    )
        external
        view
        returns (uint64 updateTimestamp, uint160 maxPriceX96, uint160 minPriceX96, uint64 updateBlockTimestamp);

    /// @notice Update prices
    /// @dev Updater calls this method to update prices for multiple tokens. The contract calculation requires
    /// higher precision prices, so the passed-in prices need to be adjusted.
    ///
    /// ## Example
    ///
    /// The price of ETH is $2000, and ETH has 18 decimals, so the price of one unit of ETH is $`2000 / (10 ^ 18)`.
    ///
    /// The price of USD is $1, and USD has 6 decimals, so the price of one unit of USD is $`1 / (10 ^ 6)`.
    ///
    /// Then the price of ETH/USD pair is 2000 / (10 ^ 18) * (10 ^ 6)
    ///
    /// Finally convert the price to Q64.96, ETH/USD priceX96 = 2000 / (10 ^ 18) * (10 ^ 6) * (2 ^ 96)
    /// @param tokenPrices Array of token addresses and prices to update for
    /// @param timestamp The timestamp of price update
    function setPriceX96s(TokenPrice[] calldata tokenPrices, uint64 timestamp) external;

    /// @notice calculate min and max price if passed a specific price value
    /// @param tokenPrices Array of token addresses and prices to update for
    function calculatePriceX96s(
        TokenPrice[] calldata tokenPrices
    ) external view returns (uint160[] memory minPriceX96s, uint160[] memory maxPriceX96s);

    /// @notice Get minimum token price
    /// @param token The token address to query the price
    /// @return priceX96 Minimum token price
    function getMinPriceX96(IERC20 token) external view returns (uint160 priceX96);

    /// @notice Get maximum token price
    /// @param token The token address to query the price
    /// @return priceX96 Maximum token price
    function getMaxPriceX96(IERC20 token) external view returns (uint160 priceX96);

    /// @notice Set updater status active or not
    /// @param account Updater address
    /// @param active Status of updater permission to set
    function setUpdater(address account, bool active) external;

    /// @notice Check if is updater
    /// @param account The address to query the status
    /// @return active Status of updater
    function isUpdater(address account) external returns (bool active);

    /// @notice Set ChainLink contract address for corresponding token.
    /// @param token The token address to set
    /// @param priceFeed ChainLink contract address
    function setRefPriceFeed(IERC20 token, IChainLinkAggregator priceFeed) external;

    /// @notice Set SequencerUptimeFeed contract address.
    /// @param sequencerUptimeFeed SequencerUptimeFeed contract address
    function setSequencerUptimeFeed(IChainLinkAggregator sequencerUptimeFeed) external;

    /// @notice Get SequencerUptimeFeed contract address.
    /// @return sequencerUptimeFeed SequencerUptimeFeed contract address
    function sequencerUptimeFeed() external returns (IChainLinkAggregator sequencerUptimeFeed);

    /// @notice Set the expected update interval for the ChainLink oracle price of the corresponding token.
    /// If ChainLink does not update the price within this period, it is considered that ChainLink has broken down.
    /// @param token The token address to set
    /// @param duration Expected update interval
    function setRefHeartbeatDuration(IERC20 token, uint32 duration) external;

    /// @notice Set maximum deviation ratio between price and ChainLink price.
    /// If exceeded, the updated price will refer to ChainLink price.
    /// @param maxDeviationRatio Maximum deviation ratio
    function setMaxDeviationRatio(uint32 maxDeviationRatio) external;

    /// @notice Set period for calculating cumulative deviation ratio.
    /// @param cumulativeRoundDuration Period in seconds to set.
    function setCumulativeRoundDuration(uint32 cumulativeRoundDuration) external;

    /// @notice Set the maximum acceptable cumulative change ratio difference between prices and ChainLink prices
    /// within a period of time. If exceeded, the updated price will refer to ChainLink price.
    /// @param token The token address to set
    /// @param maxCumulativeDeltaDiff Maximum cumulative change ratio difference
    function setMaxCumulativeDeltaDiffs(IERC20 token, uint64 maxCumulativeDeltaDiff) external;

    /// @notice Set number of additional rounds for ChainLink prices to participate in price update calculation.
    /// @param refPriceExtraSample The number of additional sampling rounds.
    function setRefPriceExtraSample(uint32 refPriceExtraSample) external;

    /// @notice Set the timeout for price update transactions.
    /// @param updateTxTimeout The timeout for price update transactions
    function setUpdateTxTimeout(uint32 updateTxTimeout) external;

    /// @notice Set ChainLink contract address and heart beat duration config for stable token.
    /// @param stableTokenPriceFeed The stable token address to set
    /// @param stableTokenPriceFeedHeartBeatDuration The expected update interval of stable token price
    function setStableTokenPriceFeed(
        IChainLinkAggregator stableTokenPriceFeed,
        uint32 stableTokenPriceFeedHeartBeatDuration
    ) external;
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