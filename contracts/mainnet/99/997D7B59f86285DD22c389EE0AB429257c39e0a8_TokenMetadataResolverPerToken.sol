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
pragma solidity ^0.8.22;

/// @notice Thrown when trying to transfer tokens without calldata to the contract.
error EtherReceptionDisabled();

/// @notice Thrown when the multiple related arrays have different lengths.
error InconsistentArrayLengths();

/// @notice Thrown when an ETH transfer has failed.
error TransferFailed();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Thrown when an account does not have the required role.
/// @param role The role the caller is missing.
/// @param account The account that was checked.
error NotRoleHolder(bytes32 role, address account);

/// @notice Thrown when an account does not have the required role on a target contract.
/// @param targetContract The contract that was checked.
/// @param role The role that was checked.
/// @param account The account that was checked.
error NotTargetContractRoleHolder(address targetContract, bytes32 role, address account);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Thrown when the target contract is actually not a contract.
/// @param targetContract The contract that was checked
error TargetIsNotAContract(address targetContract);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Emitted when `role` is granted to `account`.
/// @param role The role that has been granted.
/// @param account The account that has been granted the role.
/// @param operator The account that granted the role.
event RoleGranted(bytes32 role, address account, address operator);

/// @notice Emitted when `role` is revoked from `account`.
/// @param role The role that has been revoked.
/// @param account The account that has been revoked the role.
/// @param operator The account that revoked the role.
event RoleRevoked(bytes32 role, address account, address operator);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title Access control via roles management (functions)
interface IAccessControl {
    /// @notice Renounces a role by the sender.
    /// @dev Reverts if `sender` does not have `role`.
    /// @dev Emits a {RoleRevoked} event.
    /// @param role The role to renounce.
    function renounceRole(bytes32 role) external;

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return hasRole_ Whether `account` has `role`.
    function hasRole(bytes32 role, address account) external view returns (bool hasRole_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {NotRoleHolder, NotTargetContractRoleHolder} from "./../errors/AccessControlErrors.sol";
import {TargetIsNotAContract} from "./../errors/Common.sol";
import {RoleGranted, RoleRevoked} from "./../events/AccessControlEvents.sol";
import {IAccessControl} from "./../interfaces/IAccessControl.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

library AccessControlStorage {
    using Address for address;
    using AccessControlStorage for AccessControlStorage.Layout;

    struct Layout {
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.access.AccessControl.storage")) - 1);

    /// @notice Grants a role to an account.
    /// @dev Note: Call to this function should be properly access controlled.
    /// @dev Emits a {RoleGranted} event if the account did not previously have the role.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    /// @param operator The account requesting the role change.
    function grantRole(Layout storage s, bytes32 role, address account, address operator) internal {
        if (!s.hasRole(role, account)) {
            s.roles[role][account] = true;
            emit RoleGranted(role, account, operator);
        }
    }

    /// @notice Revokes a role from an account.
    /// @dev Note: Call to this function should be properly access controlled.
    /// @dev Emits a {RoleRevoked} event if the account previously had the role.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    /// @param operator The account requesting the role change.
    function revokeRole(Layout storage s, bytes32 role, address account, address operator) internal {
        if (s.hasRole(role, account)) {
            s.roles[role][account] = false;
            emit RoleRevoked(role, account, operator);
        }
    }

    /// @notice Renounces a role by the sender.
    /// @dev Reverts with {NotRoleHolder} if `sender` does not have `role`.
    /// @dev Emits a {RoleRevoked} event.
    /// @param sender The message sender.
    /// @param role The role to renounce.
    function renounceRole(Layout storage s, address sender, bytes32 role) internal {
        s.enforceHasRole(role, sender);
        s.roles[role][sender] = false;
        emit RoleRevoked(role, sender, sender);
    }

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return hasRole_ Whether `account` has `role`.
    function hasRole(Layout storage s, bytes32 role, address account) internal view returns (bool hasRole_) {
        return s.roles[role][account];
    }

    /// @notice Checks whether an account has a role in a target contract.
    /// @param targetContract The contract to check.
    /// @param role The role to check.
    /// @param account The account to check.
    /// @return hasTargetContractRole_ Whether `account` has `role` in `targetContract`.
    function hasTargetContractRole(address targetContract, bytes32 role, address account) internal view returns (bool hasTargetContractRole_) {
        if (!targetContract.isContract()) revert TargetIsNotAContract(targetContract);
        return IAccessControl(targetContract).hasRole(role, account);
    }

    /// @notice Ensures that an account has a role.
    /// @dev Reverts with {NotRoleHolder} if `account` does not have `role`.
    /// @param role The role.
    /// @param account The account.
    function enforceHasRole(Layout storage s, bytes32 role, address account) internal view {
        if (!s.hasRole(role, account)) revert NotRoleHolder(role, account);
    }

    /// @notice Enforces that an account has a role in a target contract.
    /// @dev Reverts with {NotTargetContractRoleHolder} if the account does not have the role.
    /// @param targetContract The contract to check.
    /// @param role The role to check.
    /// @param account The account to check.
    function enforceHasTargetContractRole(address targetContract, bytes32 role, address account) internal view {
        if (!hasTargetContractRole(targetContract, role, account)) revert NotTargetContractRoleHolder(targetContract, role, account);
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {InconsistentArrayLengths} from "./../../CommonErrors.sol";
import {ITokenMetadataResolver} from "./interfaces/ITokenMetadataResolver.sol";
import {AccessControlStorage} from "./../../access/libraries/AccessControlStorage.sol";

/// @title TokenMetadataResolverPerToken.
/// @notice Token Metadata Resolver which stores the metadata URI for each token.
/// @notice Only minters of the target token contract can set the token metadata URI for this target contract.
contract TokenMetadataResolverPerToken is ITokenMetadataResolver {
    using AccessControlStorage for address;

    bytes32 public constant MINTER_ROLE = "minter";

    mapping(address => mapping(uint256 => string)) public metadataURI;

    /// @notice Sets the metadata URI for a token on a contract.
    /// @dev Reverts with {NotTargetContractRoleHolder} if the sender is not a 'minter' of the token contract.
    /// @param tokenContract The token contract on which to set the token URI.
    /// @param tokenId The token identifier.
    /// @param tokenURI The token metadata URI.
    function setTokenURI(address tokenContract, uint256 tokenId, string calldata tokenURI) public virtual {
        tokenContract.enforceHasTargetContractRole(MINTER_ROLE, msg.sender);
        metadataURI[tokenContract][tokenId] = tokenURI;
    }

    /// @notice Sets the metadata URIs for a batch of tokens on a contract.
    /// @dev Reverts with {InconsistentArrayLengths} if the arrays are of inconsistent lengths.
    /// @dev Reverts with {NotTargetContractRoleHolder} if the sender is not a 'minter' of the token contract.
    /// @param tokenContract The token contract on which to set the token URI.
    /// @param tokenIds The token identifiers.
    /// @param tokenURIs The token metadata URIs.
    function batchSetTokenURI(address tokenContract, uint256[] calldata tokenIds, string[] calldata tokenURIs) public virtual {
        uint256 length = tokenIds.length;
        if (length != tokenURIs.length) {
            revert InconsistentArrayLengths();
        }
        tokenContract.enforceHasTargetContractRole(MINTER_ROLE, msg.sender);

        for (uint256 i; i < length; ++i) {
            metadataURI[tokenContract][tokenIds[i]] = tokenURIs[i];
        }
    }

    /// @notice Gets the token metadata URI for a token.
    /// @param tokenContract The token contract for which to retrieve the token URI.
    /// @param tokenId The token identifier.
    /// @return tokenURI The token metadata URI.
    function tokenMetadataURI(address tokenContract, uint256 tokenId) external view virtual override returns (string memory tokenURI) {
        return metadataURI[tokenContract][tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title ITokenMetadataResolver
/// @notice Interface for Token Metadata Resolvers.
interface ITokenMetadataResolver {
    /// @notice Gets the token metadata URI for a token.
    /// @param tokenContract The token contract for which to retrieve the token URI.
    /// @param tokenId The token identifier.
    /// @return tokenURI The token metadata URI.
    function tokenMetadataURI(address tokenContract, uint256 tokenId) external view returns (string memory tokenURI);
}