// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {Term, ITerm} from './Term.sol';
import {ITokenTransfer, IAgreementManager} from './ITokenTransfer.sol';
import {IRolesAuthority} from '../security/IRolesAuthority.sol';
import {Roles} from '../libraries/Roles.sol';

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/// @notice Agreement Term requiring token payment.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/terms/TokenTransfer.sol)
contract TokenTransfer is Term, ITokenTransfer {
    using Roles for IRolesAuthority;
    using SafeERC20 for IERC20;

    /// @dev Storage of TokenTransfer Terms by Agreement ID
    /// Only set at terms creation
    mapping(IAgreementManager => mapping(uint256 => TokenTransferData)) public tokenTransferData;

    /// @dev Storage this contract's token balance per Agreement
    mapping(IAgreementManager => mapping(uint256 => uint256)) public totalPaid;

    IRolesAuthority public whitelistAuthority;

    constructor(IRolesAuthority _whitelistAuthority) {
        whitelistAuthority = _whitelistAuthority;
    }

    function getData(IAgreementManager manager, uint256 tokenId)
        public
        view
        virtual
        override
        returns (TokenTransferData memory)
    {
        return tokenTransferData[manager][tokenId];
    }

    function constraintStatus(IAgreementManager manager, uint256 tokenId)
        public
        view
        virtual
        override(Term, ITerm)
        returns (uint256)
    {
        return percentOfTotal(totalPaid[manager][tokenId], tokenTransferData[manager][tokenId].amount);
    }

    // slither-disable-next-line dead-code
    function _createTerm(
        IAgreementManager manager,
        uint256 tokenId,
        bytes calldata data
    ) internal virtual override {
        TokenTransferData memory _data = abi.decode(data, (TokenTransferData));
        initializeData(manager, tokenId, _data);
    }

    function initializeData(
        IAgreementManager manager,
        uint256 tokenId,
        TokenTransferData memory data
    ) internal {
        whitelistAuthority.checkUserRole(address(data.token), Roles.PAYMENT_TOKEN_ROLE);
        if (data.to == address(0)) revert Term__ZeroAddress();
        if (data.amount == 0) revert Term__ZeroValue();
        if (data.priorTransfers > data.amount) revert TokenTransfer__PriorTransfersTooLarge();

        totalPaid[manager][tokenId] = data.priorTransfers;
        tokenTransferData[manager][tokenId] = data;
    }

    function _settleTerm(IAgreementManager, uint256) internal virtual override {}

    function _cancelTerm(IAgreementManager, uint256) internal virtual override {}

    function _afterTermResolved(IAgreementManager manager, uint256 tokenId) internal virtual override {
        delete totalPaid[manager][tokenId];
        delete tokenTransferData[manager][tokenId];

        super._afterTermResolved(manager, tokenId);
    }

    function payableAmount(IAgreementManager manager, uint256 tokenId) public view virtual override returns (uint256) {
        // Total eligible amount
        uint256 payableUpTo = 0;
        if (tokenTransferData[manager][tokenId].restrictedExercise) {
            payableUpTo = (manager.constraintStatus(tokenId) * tokenTransferData[manager][tokenId].amount) / 100 ether;
        } else {
            payableUpTo = tokenTransferData[manager][tokenId].amount;
        }

        // Adjust for previously paid amount
        return payableUpTo - totalPaid[manager][tokenId];
    }

    function transfer(
        IAgreementManager manager,
        uint256 tokenId,
        uint256 amount
    ) public virtual override {
        if (manager.expired(tokenId)) revert Term__Expired();
        if (amount > payableAmount(manager, tokenId)) revert TokenTransfer__RestrictedExercise();

        totalPaid[manager][tokenId] = totalPaid[manager][tokenId] + amount;

        tokenTransferData[manager][tokenId].token.safeTransferFrom(
            msg.sender,
            tokenTransferData[manager][tokenId].to,
            amount
        );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Term) returns (bool) {
        return interfaceId == type(ITokenTransfer).interfaceId || super.supportsInterface(interfaceId);
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {Authority} from './AuthBase.sol';

/// @notice Interface for solmate's RolesAuthority.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/security/IRolesAuthority.sol)
/// @dev Used for role based whitelisting
interface IRolesAuthority is Authority {
    function getUserRoles(address user) external view returns (bytes32);

    function isCapabilityPublic(address target, bytes4 functionSig) external view returns (bool);

    function getRolesWithCapability(address target, bytes4 functionSig) external view returns (bytes32);

    function doesUserHaveRole(address user, uint8 role) external view returns (bool);

    function doesRoleHaveCapability(
        uint8 role,
        address target,
        bytes4 functionSig
    ) external view returns (bool);

    function setPublicCapability(
        address target,
        bytes4 functionSig,
        bool enabled
    ) external;

    function setRoleCapability(
        uint8 role,
        address target,
        bytes4 functionSig,
        bool enabled
    ) external;

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.15;

import {IRolesAuthority} from '../security/IRolesAuthority.sol';

/// @notice Extensions for RolesAuthority.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/libraries/Roles.sol)
library Roles {
    error Roles__MissingRole(address account, address target, uint8 role);

    uint8 public constant TERM_ROLE = 31;
    uint8 public constant PAYMENT_TOKEN_ROLE = 32;

    function checkUserRole(
        IRolesAuthority authority,
        address account,
        uint8 role
    ) internal view {
        if (!authority.doesUserHaveRole(account, role)) revert Roles__MissingRole(account, address(this), role);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/security/AuthBase.sol)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @dev Needs constructor or initializer
abstract contract AuthBase {
    error Auth__Unauthorized(address user, address target, bytes4 functionSig);

    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    // slither-disable-next-line naming-convention
    function setup(address _owner, Authority _authority) internal {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        if (!isAuthorized(msg.sender, msg.sig)) revert Auth__Unauthorized(msg.sender, address(this), msg.sig);

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        // slither-disable-next-line missing-zero-check
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    // slither-disable-next-line naming-convention,unused-state
    uint256[48] private __gap;
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Dinari (https://github.com/dinaricrypto/dinari-contracts/blob/main/contracts/security/AuthBase.sol)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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