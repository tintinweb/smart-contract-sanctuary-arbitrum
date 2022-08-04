// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {Term, IERC165} from './Term.sol';
import {Right} from './Right.sol';
import {ITags, IAgreementManager} from './ITags.sol';
import {UintBitMap} from '../libraries/UintBitMap.sol';

/// @notice Agreement Term for 256 flexible read-only tags.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/Tags.sol)
contract Tags is Right, ITags {
    using UintBitMap for uint256;

    /// @dev tags storage per tokenId
    mapping(IAgreementManager => mapping(uint256 => uint256)) internal tags;

    function getTags(IAgreementManager manager, uint256 tokenId) public view virtual override returns (uint256) {
        return tags[manager][tokenId];
    }

    function hasTag(
        IAgreementManager manager,
        uint256 tokenId,
        uint8 tag
    ) public view virtual override returns (bool) {
        return tags[manager][tokenId].get(tag);
    }

    function packTags(uint8[] memory tagSet) public pure virtual returns (uint256 packedTags) {
        packedTags = 0;
        for (uint8 i = 0; i < tagSet.length; i++) {
            packedTags = packedTags.set(tagSet[i]);
        }
    }

    function _createTerm(
        IAgreementManager manager,
        uint256 tokenId,
        bytes calldata data
    ) internal virtual override {
        tags[manager][tokenId] = abi.decode(data, (uint256));
    }

    function _settleTerm(IAgreementManager, uint256) internal virtual override {}

    function _cancelTerm(IAgreementManager, uint256) internal virtual override {}

    function _afterTermResolved(IAgreementManager manager, uint256 tokenId) internal virtual override {
        delete tags[manager][tokenId];

        super._afterTermResolved(manager, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Term) returns (bool) {
        return interfaceId == type(ITags).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {ERC165, IERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import {ITerm, IAgreementManager} from './ITerm.sol';
import {AnnotatingMulticall} from '../AnnotatingMulticall.sol';

/// @notice Base implementation for composable agreements.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/Term.sol)
abstract contract Term is ERC165, ITerm, AnnotatingMulticall {
    /// @dev Throws if called by an account other than the manager contract
    function onlyManager(IAgreementManager manager) internal view virtual {
        if (msg.sender != address(manager)) revert Term__NotManager(msg.sender);
    }

    function percentOfTotal(uint256 amount, uint256 total) internal pure virtual returns (uint256) {
        return (100 ether * amount) / total;
    }

    /// @inheritdoc ITerm
    function createTerm(
        IAgreementManager manager,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override {
        onlyManager(manager);

        _createTerm(manager, tokenId, data);
    }

    /// @inheritdoc ITerm
    function settleTerm(IAgreementManager manager, uint256 tokenId) public virtual override {
        onlyManager(manager);
        if (constraintStatus(manager, tokenId) != 100 ether) revert Term__TermNotSatisfied();

        _settleTerm(manager, tokenId);
        _afterTermResolved(manager, tokenId);
    }

    /// @inheritdoc ITerm
    function cancelTerm(IAgreementManager manager, uint256 tokenId) public virtual override {
        onlyManager(manager);

        _cancelTerm(manager, tokenId);
        _afterTermResolved(manager, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ITerm).interfaceId || super.supportsInterface(interfaceId);
    }

    /* ------ Abstract ------ */

    function constraintStatus(IAgreementManager manager, uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256);

    function _createTerm(
        IAgreementManager manager,
        uint256 tokenId,
        bytes calldata data
    ) internal virtual;

    function _settleTerm(IAgreementManager manager, uint256 tokenId) internal virtual;

    function _cancelTerm(IAgreementManager manager, uint256 tokenId) internal virtual;

    function _afterTermResolved(IAgreementManager manager, uint256 tokenId) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {Term, IAgreementManager} from './Term.sol';

/// @notice Agreement Term that places no constraints.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/Right.sol)
abstract contract Right is Term {
    function constraintStatus(IAgreementManager, uint256) public pure virtual override returns (uint256) {
        return 100 ether;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {ITerm, IAgreementManager} from './ITerm.sol';

/// @notice Agreement Term for 256 flexible read-only tags.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/ITags.sol)
interface ITags is ITerm {
    function getTags(IAgreementManager manager, uint256 tokenId) external view returns (uint256);

    function hasTag(
        IAgreementManager manager,
        uint256 tokenId,
        uint8 tag
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @dev Library for managing uint8 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Interface modified from OpenZeppelin's https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol.
 */
library UintBitMap {
    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(uint256 bitmap, uint8 index) internal pure returns (bool) {
        return (bitmap >> index) & 1 != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    // slither-disable-next-line dead-code
    function setTo(
        uint256 bitmap,
        uint8 index,
        bool value
    ) internal pure returns (uint256) {
        if (value) {
            return set(bitmap, index);
        } else {
            return unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(uint256 bitmap, uint8 index) internal pure returns (uint256) {
        return bitmap | uint256(1 << index);
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    // slither-disable-next-line dead-code
    function unset(uint256 bitmap, uint8 index) internal pure returns (uint256) {
        return bitmap & ~uint256(1 << index);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {IAgreementManager} from '../IAgreementManager.sol';

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/// @notice Base implementation for composable agreements.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/ITerm.sol)
interface ITerm is IERC165 {
    error Term__NotManager(address account);
    error Term__TermNotSatisfied();
    error Term__ZeroValue();
    error Term__ZeroAddress();
    error Term__NotIssuer(address account);
    error Term__Expired();
    error Term__NotTokenOwner(address account);

    /**
     * @notice Percent complete value according to satisfaction of terms
     * @dev Computed with standard ether decimals
     */
    function constraintStatus(IAgreementManager manager, uint256 tokenId) external view returns (uint256);

    /**
     * @notice Create new term
     * @dev Only callable by manager
     * @param manager AgreementManager contract address
     * @param tokenId Agreement Token ID Created in Agreement Manager
     * @param data Initialization data struct
     */
    function createTerm(
        IAgreementManager manager,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @notice Final resolution of terms
     * @dev Only callable by manager
     * This resolves the term in the agreement owner's favor whenever possible
     */
    function settleTerm(IAgreementManager manager, uint256 tokenId) external;

    /**
     * @notice Reversion of any unsettled terms
     * @dev Only callable by manager
     * This resolves the term in the agreement issuer's favor whenever possible
     */
    function cancelTerm(IAgreementManager manager, uint256 tokenId) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';

/// @notice Writes notes to event log for function calls.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/AnnotatingMulticall.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Multicall.sol)
abstract contract AnnotatingMulticall {
    event Multicall(bytes[] results, string[] notes);

    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data, string[] calldata notes) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // Assumes delegatecall to address(this) is safe for a proxy
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        emit Multicall(results, notes);
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

/// @notice Orchistrates Term based agreements.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/IAgreementManager.sol)
interface IAgreementManager {
    struct AgreementTerms {
        // Account the caller would like to create agreement with
        address party;
        // Deadline after which agreement becomes void
        uint256 expiration;
        // Array of terms contracts
        address[] terms;
        // Terms contracts encoded initialization data
        bytes[] termsData;
    }

    error AgreementManager__ZeroAddress();
    error AgreementManager__TimeInPast();
    error AgreementManager__NoArrayParity();
    error AgreementManager__NoTerms();
    error AgreementManager__Expired();
    error AgreementManager__DuplicateTerm();
    error AgreementManager__NotTokenOwner(address account);
    error AgreementManager__NotIssuer(address account);
    error AgreementManager__InvalidAmendment();
    error AgreementManager__TermNotFound();

    event AgreementCreated(uint256 indexed tokenId, address indexed issuer, AgreementTerms agreementData);
    event AgreementSettled(uint256 indexed tokenId);
    event AgreementCancelled(uint256 indexed tokenId);
    event AmendmentProposed(uint256 indexed tokenId, AgreementTerms agreementData);
    event AgreementAmended(uint256 indexed tokenId, AgreementTerms agreementData);

    /**
     * @notice Create Agreement with specific terms
     * @dev Intended role: AgreementCreator
     */
    function createAgreement(AgreementTerms calldata agreementData) external returns (uint256);

    /**
     * @notice Settle all agreement terms
     * @dev Only callable by token owner
     * All terms must be settled, or none
     * This resolves the agreement in the token owner's favor whenever possible
     * @param tokenId Agreement id
     */
    function settleAgreement(uint256 tokenId) external;

    /**
     * @notice Cancel all agreement terms
     * @dev Only callable by agreement issuer
     * This resolves the agreement in the issuer's favor whenever possible
     * @param tokenId Agreement id
     */
    function cancelAgreement(uint256 tokenId) external;

    /**
     * @notice Propose amendment to agreement terms
     * @dev Only callable by the agreement owner
     */
    function proposeAmendment(uint256 tokenId, AgreementTerms calldata agreementData) external;

    /**
     * @notice Execute amendment to terms of an agreement
     * @dev Only callable by the agreement issuer.
     * WARNING: Other contracts make assumptions about stability of term ordering.
     */
    function amendAgreement(uint256 tokenId, AgreementTerms calldata agreementData) external;

    /// @notice Account that created agreement
    function issuer(uint256 tokenId) external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Expiration timestamp
    function expiration(uint256 tokenId) external view returns (uint256);

    function terms(uint256 tokenId, uint256 index) external view returns (address);

    /// @notice Term contracts
    function termsList(uint256 tokenId) external view returns (address[] memory);

    function containsTerm(uint256 tokenId, address term) external view returns (bool);

    function expired(uint256 tokenId) external view returns (bool);

    function constraintStatus(uint256 tokenId) external view returns (uint256);
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