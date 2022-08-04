// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {Term, IERC165} from './Term.sol';
import {Right} from './Right.sol';
import {IFutureToken, ITokenTransfer, IAgreementManager} from './IFutureToken.sol';

import {ERC165Checker} from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';

/// @notice Agreement Term defining rights necessary to claim wrapped tokens to be created in the future.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/PostMoneyFutureToken.sol)
/// @dev Enforced and honored by issuer.
contract PostMoneyFutureToken is Right, IFutureToken {
    /// @dev Storage of Future Equity Terms by Agreement ID
    /// Only set at terms creation
    mapping(IAgreementManager => mapping(uint256 => FutureTokenData)) public futureTokenData;

    function _createTerm(
        IAgreementManager manager,
        uint256 tokenId,
        bytes calldata data
    ) internal virtual override {
        FutureTokenData memory _data = abi.decode(data, (FutureTokenData));

        // Agreement must contain TokenTransfer term
        address tokenTransfer = address(_data.tokenTransfer);
        if (!ERC165Checker.supportsInterface(tokenTransfer, type(ITokenTransfer).interfaceId))
            revert FutureToken__NotTokenTransfer(tokenTransfer);
        if (!manager.containsTerm(tokenId, tokenTransfer)) revert FutureToken__NoTokenTransferTerm();

        if (_data.discount >= 100 ether) revert FutureToken__DiscountTooLarge();
        if (_data.discount == 0 && _data.marketCapitalization == 0) revert FutureToken__IncompleteData();

        futureTokenData[manager][tokenId] = _data;
    }

    function _settleTerm(IAgreementManager, uint256) internal virtual override {
        revert Term__NotIssuer(msg.sender);
    }

    function _cancelTerm(IAgreementManager manager, uint256 tokenId) internal virtual override {
        delete futureTokenData[manager][tokenId];
    }

    /// @inheritdoc IFutureToken
    function effectiveMarketValue(
        IAgreementManager manager,
        uint256 tokenId,
        uint256 marketValue
    ) public view virtual override returns (uint256) {
        // Choose best of marketValue, FutureTokenData.marketCapitalization, or FutureTokenData.discount
        uint256 capValue = marketValue;
        uint256 marketCapValue = futureTokenData[manager][tokenId].marketCapitalization;
        if (marketCapValue != 0 && capValue > marketCapValue) {
            capValue = marketCapValue;
        }
        // Calculate from discount terms
        uint256 discount = futureTokenData[manager][tokenId].discount;
        if (discount > 0) {
            uint256 discounted = (marketValue * (100 ether - discount)) / 100 ether;
            if (capValue > discounted) {
                capValue = discounted;
            }
        }
        return capValue;
    }

    /// @inheritdoc IFutureToken
    function issuableForPricing(
        IAgreementManager manager,
        uint256 tokenId,
        uint256 postMoneyCapitalizationValue,
        uint256 postMoneyTotalSupply
    ) public view virtual override returns (uint256, uint256) {
        // totalIssuable = postMoneySupply * money / postMoneyValue
        // Eligible amount to issue
        uint256 effectiveCap = effectiveMarketValue(manager, tokenId, postMoneyCapitalizationValue);
        uint256 money = ITokenTransfer(futureTokenData[manager][tokenId].tokenTransfer)
            .getData(manager, tokenId)
            .amount;
        return (
            (manager.constraintStatus(tokenId) * postMoneyTotalSupply * money) / effectiveCap / 100 ether,
            effectiveCap
        );
    }

    function validateIssuance(
        IAgreementManager manager,
        uint256 tokenId,
        uint256 postMoneyCapitalizationValue,
        uint256 postMoneyTotalSupply
    ) public view override {
        // Checks that target percentage is between percentage of issuable and issuable + 1
        uint256 effectiveCap = effectiveMarketValue(manager, tokenId, postMoneyCapitalizationValue);
        uint256 money = ITokenTransfer(futureTokenData[manager][tokenId].tokenTransfer)
            .getData(manager, tokenId)
            .amount;
        uint256 targetPercentage = (1 ether * money) / effectiveCap;
        (uint256 issuableShares, ) = issuableForPricing(
            manager,
            tokenId,
            postMoneyCapitalizationValue,
            postMoneyTotalSupply
        );
        uint256 issuablePercentage = (1 ether * issuableShares) / postMoneyTotalSupply;
        uint256 issuablePlusPercentage = (1 ether * (issuableShares + 1)) / postMoneyTotalSupply;
        if (targetPercentage < issuablePercentage || targetPercentage > issuablePlusPercentage)
            revert FutureToken__InvalidIssuance(tokenId, issuableShares, targetPercentage, issuablePercentage);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(Term, IERC165) returns (bool) {
        return interfaceId == type(IFutureToken).interfaceId || super.supportsInterface(interfaceId);
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

import {ITokenTransfer} from './ITokenTransfer.sol';
import {ITerm, IAgreementManager} from './ITerm.sol';

/// @notice Agreement Term defining rights necessary to claim wrapped tokens to be created in the future.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/IFutureToken.sol)
/// @dev Enforced and honored by issuer.
interface IFutureToken is ITerm {
    /// @dev Data structure for FutureToken properties
    struct FutureTokenData {
        // The minimum discount applied to determine required amount with ether decimals
        uint256 discount;
        // A set market cap to determine best discount
        uint256 marketCapitalization;
        // The term contract to retrieve the value contributed by the investor
        ITokenTransfer tokenTransfer;
    }

    error FutureToken__DiscountTooLarge();
    error FutureToken__IncompleteData();
    error FutureToken__NotTokenTransfer(address term);
    error FutureToken__NoTokenTransferTerm();
    error FutureToken__InvalidIssuance(
        uint256 tokenId,
        uint256 issuance,
        uint256 targetPercentage,
        uint256 issuancePercentage
    );

    /**
     * @notice Computes effective token valuation for term
     * @param tokenId Agreement ID Created in Agreement Manager
     * @param marketValue Token market cap value
     */
    function effectiveMarketValue(
        IAgreementManager manager,
        uint256 tokenId,
        uint256 marketValue
    ) external view returns (uint256);

    /**
     * @notice Amount of token eligible for issuance
     * @dev Also returns effective market cap value
     */
    function issuableForPricing(
        IAgreementManager manager,
        uint256 tokenId,
        uint256 capitalizationValue,
        uint256 totalSupply
    ) external view returns (uint256, uint256);

    function validateIssuance(
        IAgreementManager manager,
        uint256 tokenId,
        uint256 postMoneyCapitalizationValue,
        uint256 postMoneyTotalSupply
    ) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (uint256)) > 0;
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {ITerm, IAgreementManager} from './ITerm.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @notice Agreement Term requiring token payment.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/ITokenTransfer.sol)
interface ITokenTransfer is ITerm {
    /// @dev Data structure for TokenTransfer properties
    struct TokenTransferData {
        // token contract address
        IERC20 token;
        // payable to
        address to;
        // total amount to transfer, including amount previously transferred
        uint256 amount;
        // payments disallowed in advance of other terms?
        bool restrictedExercise;
        // amount previously transferred
        uint256 priorTransfers;
    }

    error TokenTransfer__RestrictedExercise();
    error TokenTransfer__PriorTransfersTooLarge();

    function getData(IAgreementManager manager, uint256 tokenId) external view returns (TokenTransferData memory);

    function payableAmount(IAgreementManager manager, uint256 tokenId) external view returns (uint256);

    function transfer(
        IAgreementManager manager,
        uint256 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}