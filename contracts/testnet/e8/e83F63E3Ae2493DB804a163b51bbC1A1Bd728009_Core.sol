// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./CoreBase.sol";
import "./interface/ICore.sol";
import "./libraries/FixedMath.sol";
import "./utils/OwnableUpgradeable.sol";

/// @title Azuro internal core managing pre-match conditions and processing bets on them
contract Core is CoreBase, ICore {
    using FixedMath for uint64;
    using SafeCast for uint256;

    /**
     * @notice See {ICoreBase-createCondition}.
     */
    function createCondition(
        uint256 gameId,
        uint256 conditionId,
        uint64[2] calldata odds,
        uint64[2] calldata outcomes,
        uint128 reinforcement,
        uint64 margin
    ) external override restricted(this.createCondition.selector) {
        _createCondition(
            gameId,
            conditionId,
            odds,
            outcomes,
            reinforcement,
            margin
        );
        if (lp.addCondition(gameId) <= block.timestamp)
            revert GameAlreadyStarted();
    }

    /**
     * @notice Liquidity Pool: See {IBet-putBet}.
     */
    function putBet(
        address bettor,
        uint128 amount,
        IBet.BetData calldata betData
    ) external override onlyLp returns (uint256 tokenId) {
        CoreBetData memory data = abi.decode(betData.data, (CoreBetData));
        Condition storage condition = _getCondition(data.conditionId);
        _conditionIsRunning(condition);

        uint256 outcomeIndex = _getOutcomeIndex(condition, data.outcomeId);

        uint128[2] memory virtualFunds = condition.virtualFunds;
        uint64 odds = CoreTools
            .calcOdds(virtualFunds, amount, outcomeIndex, condition.margin)
            .toUint64();
        if (odds < data.minOdds) revert SmallOdds();

        uint128 payout = odds.mul(amount).toUint128();
        uint128 deltaPayout = payout - amount;

        virtualFunds[outcomeIndex] += amount;
        virtualFunds[1 - outcomeIndex] -= deltaPayout;
        condition.virtualFunds = virtualFunds;

        {
            uint128[2] memory funds = condition.funds;
            _changeFunds(
                condition,
                funds,
                outcomeIndex == 0
                    ? [funds[0] + amount, funds[1] - deltaPayout]
                    : [funds[0] - deltaPayout, funds[1] + amount]
            );
        }

        _updateContribution(
            betData.affiliate,
            data.conditionId,
            amount,
            payout,
            outcomeIndex
        );

        tokenId = azuroBet.mint(bettor);
        {
            Bet storage bet = bets[tokenId];
            bet.conditionId = data.conditionId;
            bet.amount = amount;
            bet.payout = payout;
            bet.outcome = data.outcomeId;
        }

        emit NewBet(
            bettor,
            betData.affiliate,
            data.conditionId,
            tokenId,
            data.outcomeId,
            amount,
            odds,
            virtualFunds
        );
    }

    /**
     * @notice Indicate outcome `outcomeWin` as happened in condition `conditionId`.
     * @notice See {CoreBase-_resolveCondition}.
     */
    function resolveCondition(uint256 conditionId, uint64 outcomeWin)
        external
        override
    {
        _resolveCondition(conditionId, outcomeWin);
    }

    /**
     * @notice Liquidity Pool: Resolve AzuroBet token `tokenId` payout.
     * @param  tokenId AzuroBet token ID
     * @return winning account
     * @return amount of winnings
     */
    function resolvePayout(uint256 tokenId)
        external
        override
        onlyLp
        returns (address, uint128)
    {
        return _resolvePayout(tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./interface/IAzuroBet.sol";
import "./interface/ICoreBase.sol";
import "./interface/ILP.sol";
import "./libraries/AffiliateHelper.sol";
import "./libraries/CoreTools.sol";
import "./libraries/FixedMath.sol";
import "./libraries/SafeCast.sol";
import "./libraries/Math.sol";
import "./utils/OwnableUpgradeable.sol";

/// @title Base contract for Azuro cores
abstract contract CoreBase is OwnableUpgradeable, ICoreBase {
    using FixedMath for uint256;
    using SafeCast for uint256;
    using SafeCast for uint128;

    mapping(uint256 => Bet) public bets;
    mapping(uint256 => Condition) public conditions;

    IAzuroBet public azuroBet;
    ILP public lp;

    AffiliateHelper.Contributions internal contributions;
    AffiliateHelper.ContributedConditionIds internal contributedConditionIds;
    AffiliateHelper.AffiliatedProfits internal affiliatedProfits;

    /**
     * @notice Throw if caller is not the Liquidity Pool.
     */
    modifier onlyLp() {
        _checkOnlyLp();
        _;
    }

    /**
     * @notice Throw if caller have no access to function with selector `selector`.
     */
    modifier restricted(bytes4 selector) {
        lp.checkAccess(msg.sender, address(this), selector);
        _;
    }

    function initialize(address azuroBet_, address lp_)
        external
        virtual
        override
        initializer
    {
        __Ownable_init();
        azuroBet = IAzuroBet(azuroBet_);
        lp = ILP(lp_);
    }

    /**
     * @notice Indicate the condition `conditionId` as canceled.
     * @notice The condition creator can always cancel it regardless of granted access tokens.
     */
    function cancelCondition(uint256 conditionId) external {
        Condition storage condition = _getCondition(conditionId);
        if (msg.sender != condition.oracle)
            lp.checkAccess(
                msg.sender,
                address(this),
                this.cancelCondition.selector
            );

        uint256 gameId = condition.gameId;
        if (_isConditionResolved(condition) || _isConditionCanceled(condition))
            revert ConditionAlreadyResolved();

        condition.state = ConditionState.CANCELED;

        AffiliateHelper.delAffiliatedProfit(affiliatedProfits, conditionId);

        uint128 lockedReserve = _calcReserve(
            condition.reinforcement,
            condition.funds
        );
        if (lockedReserve > 0)
            lp.changeLockedLiquidity(gameId, -lockedReserve.toInt128());

        emit ConditionResolved(
            conditionId,
            uint8(ConditionState.CANCELED),
            0,
            0
        );
    }

    /**
     * @notice Change the current condition `conditionId` odds.
     */
    function changeOdds(uint256 conditionId, uint64[2] calldata newOdds)
        external
        restricted(this.changeOdds.selector)
    {
        Condition storage condition = _getCondition(conditionId);
        _conditionIsRunning(condition);

        _applyOdds(condition, newOdds);
        emit OddsChanged(conditionId, newOdds);
    }

    /**
     * @notice Indicate the status of condition `conditionId` bet lock.
     * @param  conditionId the match or condition ID
     * @param  flag if stop receiving bets for the condition or not
     */
    function stopCondition(uint256 conditionId, bool flag)
        external
        restricted(this.stopCondition.selector)
    {
        Condition storage condition = _getCondition(conditionId);
        // only CREATED state can be stopped
        // only PAUSED state can be restored
        ConditionState state = condition.state;
        if (
            (state != ConditionState.CREATED && flag) ||
            (state != ConditionState.PAUSED && !flag) ||
            lp.isGameCanceled(condition.gameId)
        ) revert CantChangeFlag();

        condition.state = flag ? ConditionState.PAUSED : ConditionState.CREATED;

        emit ConditionStopped(conditionId, flag);
    }

    /**
     * @notice Liquidity Pool: Resolve affiliate's contribution to total profit that is not rewarded yet.
     * @param  affiliate address indicated as an affiliate when placing bets
     * @param data core pre-match affiliate params
     * @return reward contribution amount
     */
    function resolveAffiliateReward(address affiliate, bytes calldata data)
        external
        virtual
        override
        onlyLp
        returns (uint256 reward)
    {
        uint256[] storage conditionIds = contributedConditionIds.map[affiliate];

        AffiliateParams memory decoded = abi.decode(data, (AffiliateParams));

        uint256 start = decoded.start;
        if (conditionIds.length == 0) revert NoPendingReward();
        if (start >= conditionIds.length)
            revert StartOutOfRange(conditionIds.length);

        uint256 conditionId;
        Condition storage condition;
        AffiliateHelper.Contribution memory contribution;
        uint256 payout;

        uint256 end = (decoded.count != 0 &&
            start + decoded.count < conditionIds.length)
            ? start + decoded.count
            : conditionIds.length;
        while (start < end) {
            conditionId = conditionIds[start];
            condition = conditions[conditionId];
            if (_isConditionResolved(condition)) {
                uint256 affiliatesReward = condition.affiliatesReward;
                if (affiliatesReward > 0) {
                    contribution = contributions.map[affiliate][conditionId];
                    uint256 outcomeWinIndex = condition.outcomeWin ==
                        condition.outcomes[0]
                        ? 0
                        : 1;
                    payout = contribution.payouts[outcomeWinIndex];
                    if (contribution.totalNetBets > payout) {
                        reward +=
                            ((contribution.totalNetBets - payout) *
                                affiliatesReward) /
                            affiliatedProfits.map[conditionId][outcomeWinIndex];
                    }
                }
            } else if (!_isConditionCanceled(condition)) {
                start++;
                continue;
            }
            delete contributions.map[affiliate][conditionId];
            conditionIds[start] = conditionIds[conditionIds.length - 1];
            conditionIds.pop();
            end--;
        }
        return reward;
    }

    /**
     * @notice Calculate the odds of bet with amount `amount` for outcome `outcome` of condition `conditionId`.
     * @param  conditionId the match or condition ID
     * @param  amount amount of tokens to bet
     * @param  outcome predicted outcome
     * @return odds betting odds
     */
    function calcOdds(
        uint256 conditionId,
        uint128 amount,
        uint64 outcome
    ) external view override returns (uint64 odds) {
        Condition storage condition = _getCondition(conditionId);
        odds = CoreTools
            .calcOdds(
                condition.virtualFunds,
                amount,
                _getOutcomeIndex(condition, outcome),
                condition.margin
            )
            .toUint64();
    }

    /**
     * @notice Get condition by it's ID.
     * @param  conditionId the match or condition ID
     * @return the condition struct
     */
    function getCondition(uint256 conditionId)
        external
        view
        returns (Condition memory)
    {
        return conditions[conditionId];
    }

    /**
     * @notice Get the count of conditions contributed by `affiliate` that are not rewarded yet.
     */
    function getContributedConditionsCount(address affiliate)
        external
        view
        returns (uint256)
    {
        return contributedConditionIds.map[affiliate].length;
    }

    function isConditionCanceled(uint256 conditionId)
        public
        view
        returns (bool)
    {
        return _isConditionCanceled(_getCondition(conditionId));
    }

    /**
     * @notice Get AzuroBet token `tokenId` payout for `account`.
     * @param  tokenId AzuroBet token ID
     * @return winnings of the token owner
     */
    function viewPayout(uint256 tokenId) public view virtual returns (uint128) {
        Bet storage bet = bets[tokenId];
        if (bet.conditionId == 0) revert BetNotExists();
        if (bet.isPaid) revert AlreadyPaid();

        Condition storage condition = _getCondition(bet.conditionId);
        if (_isConditionResolved(condition)) {
            if (bet.outcome == condition.outcomeWin) return bet.payout;
            else return 0;
        }
        if (_isConditionCanceled(condition)) return bet.amount;

        revert ConditionNotFinished();
    }

    /**
     * @notice Register new condition.
     * @param  gameId the game ID the condition belongs
     * @param  conditionId the match or condition ID according to oracle's internal numbering
     * @param  odds start odds for [team 1, team 2]
     * @param  outcomes unique outcomes for the condition [outcome 1, outcome 2]
     * @param  reinforcement maximum amount of liquidity intended to condition reinforcement
     * @param  margin bookmaker commission
     */
    function _createCondition(
        uint256 gameId,
        uint256 conditionId,
        uint64[2] calldata odds,
        uint64[2] calldata outcomes,
        uint128 reinforcement,
        uint64 margin
    ) internal {
        if (conditionId == 0) revert IncorrectConditionId();
        if (outcomes[0] == outcomes[1]) revert SameOutcomes();
        if (margin > FixedMath.ONE) revert IncorrectMargin();

        Condition storage newCondition = conditions[conditionId];
        if (newCondition.gameId != 0) revert ConditionAlreadyCreated();

        newCondition.funds = [reinforcement, reinforcement];
        _applyOdds(newCondition, odds);
        newCondition.reinforcement = reinforcement;
        newCondition.gameId = gameId;
        newCondition.margin = margin;
        newCondition.outcomes = outcomes;
        newCondition.oracle = msg.sender;
        newCondition.leaf = lp.getLeaf();

        emit ConditionCreated(gameId, conditionId);
    }

    /**
     * @notice Indicate outcome `outcomeWin` as happened in condition `conditionId`.
     * @notice Only condition creator can resolve it.
     * @param  conditionId the match or condition ID
     * @param  outcomeWin ID of happened condition's outcome
     */
    function _resolveCondition(uint256 conditionId, uint64 outcomeWin)
        internal
    {
        Condition storage condition = _getCondition(conditionId);
        address oracle = condition.oracle;
        if (msg.sender != oracle) revert OnlyOracle(oracle);
        {
            (uint64 timeOut, bool gameIsCanceled) = lp.getGameInfo(
                condition.gameId
            );
            if (
                // TODO: Use only `_isConditionCanceled` to check if condition or its game is canceled
                gameIsCanceled ||
                condition.state == ConditionState.CANCELED ||
                _isConditionResolved(condition)
            ) revert ConditionAlreadyResolved();

            timeOut += 1 minutes;
            if (block.timestamp < timeOut) revert ResolveTooEarly(timeOut);
        }
        uint256 outcomeIndex = _getOutcomeIndex(condition, outcomeWin);
        uint256 oppositeIndex = 1 - outcomeIndex;

        condition.outcomeWin = outcomeWin;
        condition.state = ConditionState.RESOLVED;

        uint128 lockedReserve;
        uint128 profitReserve;
        {
            uint128 reinforcement = condition.reinforcement;
            uint128[2] memory funds = condition.funds;
            lockedReserve = _calcReserve(reinforcement, funds);
            profitReserve =
                lockedReserve +
                funds[oppositeIndex] -
                reinforcement;
        }

        uint128 affiliatesReward = lp.addReserve(
            condition.gameId,
            lockedReserve,
            profitReserve,
            condition.leaf
        );
        if (affiliatesReward > 0) condition.affiliatesReward = affiliatesReward;

        AffiliateHelper.delAffiliatedProfitOutcome(
            affiliatedProfits,
            conditionId,
            oppositeIndex
        );

        emit ConditionResolved(
            conditionId,
            uint8(ConditionState.RESOLVED),
            outcomeWin,
            profitReserve.toInt128() - lockedReserve.toInt128()
        );
    }

    /**
     * @notice Calculate the distribution of available fund into [outcome1Fund, outcome2Fund] compliant to odds `odds`
     *         and set it as condition virtual funds.
     */
    function _applyOdds(Condition storage condition, uint64[2] calldata odds)
        internal
    {
        if (odds[0] == 0 || odds[1] == 0) revert ZeroOdds();

        uint128 fund = Math.min(condition.funds[0], condition.funds[1]);
        uint128 fund0 = uint128(
            (uint256(fund) * odds[1]) / (odds[0] + odds[1])
        );
        condition.virtualFunds = [fund0, fund - fund0];
    }

    /**
     * @notice Change condition funds and update the locked reserve amount according to the new funds value.
     */
    function _changeFunds(
        Condition storage condition,
        uint128[2] memory funds,
        uint128[2] memory newFunds
    ) internal {
        uint128 reinforcement = condition.reinforcement;
        lp.changeLockedLiquidity(
            condition.gameId,
            _calcReserve(reinforcement, newFunds).toInt128() -
                _calcReserve(reinforcement, funds).toInt128()
        );
        condition.funds = newFunds;
    }

    /**
     * @notice Resolve AzuroBet token `tokenId` payout.
     * @param  tokenId AzuroBet token ID
     * @return winning account
     * @return amount of winnings
     */
    function _resolvePayout(uint256 tokenId)
        internal
        returns (address, uint128)
    {
        uint128 amount = viewPayout(tokenId);

        bets[tokenId].isPaid = true;
        return (azuroBet.ownerOf(tokenId), amount);
    }

    /**
     * @notice Add information about the bet made from an affiliate.
     * @param  affiliate_ address indicated as an affiliate when placing bet
     * @param  conditionId the match or condition ID
     * @param  betAmount amount of tokens is bet from the affiliate
     * @param  payout possible bet winnings
     * @param  outcomeIndex index of predicted outcome
     */
    function _updateContribution(
        address affiliate_,
        uint256 conditionId,
        uint128 betAmount,
        uint128 payout,
        uint256 outcomeIndex
    ) internal {
        AffiliateHelper.updateContribution(
            contributions,
            contributedConditionIds,
            affiliatedProfits,
            affiliate_,
            conditionId,
            betAmount,
            payout,
            outcomeIndex
        );
    }

    /**
     * @notice Throw if the condition can't accept any bet now.
     * @notice This can happen because the condition is started, resolved or stopped or
     *         the game the condition is bounded with is canceled.
     * @param  condition the condition pointer
     */
    function _conditionIsRunning(Condition storage condition)
        internal
        view
        virtual
    {
        if (condition.state != ConditionState.CREATED)
            revert ActionNotAllowed();
        (uint64 startsAt, bool gameIsCanceled) = lp.getGameInfo(
            condition.gameId
        );
        if (gameIsCanceled || block.timestamp >= startsAt)
            revert ActionNotAllowed();
    }

    /**
     * @notice Calculate the amount of liquidity to be reserved.
     */
    function _calcReserve(uint128 reinforcement, uint128[2] memory funds)
        internal
        pure
        returns (uint128)
    {
        return
            Math
                .max(
                    Math.diffOrZero(reinforcement, funds[0]),
                    Math.diffOrZero(reinforcement, funds[1])
                )
                .toUint128();
    }

    function _checkOnlyLp() internal view {
        if (msg.sender != address(lp)) revert OnlyLp();
    }

    /**
     * @notice Get condition by it's ID.
     */
    function _getCondition(uint256 conditionId)
        internal
        view
        returns (Condition storage)
    {
        Condition storage condition = conditions[conditionId];
        if (condition.gameId == 0) revert ConditionNotExists();

        return condition;
    }

    /**
     * @notice Get condition's index of outcome `outcome`.
     * @dev    Throw if the condition haven't outcome `outcome` as possible
     * @param  condition the condition pointer
     * @param  outcome outcome ID
     */
    function _getOutcomeIndex(Condition storage condition, uint64 outcome)
        internal
        pure
        returns (uint256)
    {
        return CoreTools.getOutcomeIndex(condition, outcome);
    }

    /**
     * @notice Check if condition or game it is bound with is cancelled or not.
     */
    function _isConditionCanceled(Condition storage condition)
        internal
        view
        returns (bool)
    {
        return
            lp.isGameCanceled(condition.gameId) ||
            condition.state == ConditionState.CANCELED;
    }

    /**
     * @notice Check if condition is resolved or not.
     */
    function _isConditionResolved(Condition storage condition)
        internal
        view
        returns (bool)
    {
        return condition.state == ConditionState.RESOLVED;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IAffiliate {
    function resolveAffiliateReward(address affiliate, bytes calldata data)
        external
        returns (uint256 contribution);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IAzuroBet is IOwnable, IERC721EnumerableUpgradeable {
    function initialize(address core) external;

    function burn(uint256 id) external;

    function mint(address account) external returns (uint256);

    error OnlyCore();
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IBet {
    struct BetData {
        address affiliate; // address indicated as an affiliate when placing bet
        bytes data; // core-specific customized bet data
    }

    error BetNotExists();
    error SmallOdds();

    /**
     * @notice Register new bet.
     * @param  bettor wallet for emitting bet token
     * @param  amount amount of tokens to bet
     * @param  betData customized bet data
     */
    function putBet(
        address bettor,
        uint128 amount,
        BetData calldata betData
    ) external returns (uint256 tokenId);

    function resolvePayout(uint256 tokenId)
        external
        returns (address account, uint128 payout);

    function viewPayout(uint256 tokenId) external view returns (uint128 payout);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface ICondition {
    enum ConditionState {
        CREATED,
        RESOLVED,
        CANCELED,
        PAUSED
    }

    struct Condition {
        uint256 gameId;
        uint128[2] funds;
        uint128[2] virtualFunds;
        uint128 reinforcement;
        uint128 affiliatesReward;
        uint64[2] outcomes;
        uint64 outcomeWin;
        uint64 margin;
        address oracle;
        uint64 endsAt;
        ConditionState state;
        uint48 leaf;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./ICoreBase.sol";

interface ICore is ICoreBase {
    event NewBet(
        address indexed bettor,
        address indexed affiliate,
        uint256 indexed conditionId,
        uint256 tokenId,
        uint64 outcomeId,
        uint128 amount,
        uint64 odds,
        uint128[2] funds
    );

    function resolveCondition(uint256 conditionId, uint64 outcomeWin) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IOwnable.sol";
import "./ICondition.sol";
import "./IBet.sol";
import "./IAffiliate.sol";

interface ICoreBase is ICondition, IOwnable, IBet, IAffiliate {
    struct AffiliateParams {
        uint256 start;
        uint256 count;
    }

    struct Bet {
        uint256 conditionId;
        uint128 amount;
        uint128 payout;
        uint64 outcome;
        bool isPaid;
    }

    struct CoreBetData {
        uint256 conditionId; // The match or game ID
        uint64 outcomeId; // ID of predicted outcome
        uint64 minOdds; // Minimum allowed betting odds
    }

    event ConditionCreated(uint256 indexed gameId, uint256 indexed conditionId);
    event ConditionResolved(
        uint256 indexed conditionId,
        uint8 state,
        uint64 outcomeWin,
        int128 lpProfit
    );
    event ConditionStopped(uint256 indexed conditionId, bool flag);

    event OddsChanged(uint256 indexed conditionId, uint64[2] newOdds);

    error OnlyLp();

    error AlreadyPaid();
    error IncorrectConditionId();
    error IncorrectMargin();
    error IncorrectTimestamp();
    error NoPendingReward();
    error OnlyOracle(address);
    error SameOutcomes();
    error StartOutOfRange(uint256 pendingRewardsCount);
    error ZeroOdds();

    error ActionNotAllowed();
    error CantChangeFlag();
    error ConditionAlreadyCreated();
    error ConditionAlreadyResolved();
    error ConditionNotExists();
    error ConditionNotFinished();
    error GameAlreadyStarted();
    error ResolveTooEarly(uint64 waitTime);

    function initialize(address azuroBet, address lp) external;

    function calcOdds(
        uint256 conditionId,
        uint128 amount,
        uint64 outcome
    ) external view returns (uint64 odds);

    function changeOdds(uint256 conditionId, uint64[2] calldata newOdds)
        external;

    function getCondition(uint256 conditionId)
        external
        view
        returns (Condition memory);

    /**
     * @notice Register new condition.
     * @param  gameId the game ID the condition belongs
     * @param  conditionId the match or condition ID according to oracle's internal numbering
     * @param  odds start odds for [team 1, team 2]
     * @param  outcomes unique outcomes for the condition [outcome 1, outcome 2]
     * @param  reinforcement maximum amount of liquidity intended to condition reinforcement
     * @param  margin bookmaker commission
     */
    function createCondition(
        uint256 gameId,
        uint256 conditionId,
        uint64[2] calldata odds,
        uint64[2] calldata outcomes,
        uint128 reinforcement,
        uint64 margin
    ) external;

    function cancelCondition(uint256 conditionId) external;

    function stopCondition(uint256 conditionId, bool flag) external;

    function isConditionCanceled(uint256 conditionId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./ICore.sol";
import "./IOwnable.sol";

interface ILP is IOwnable {
    enum FeeType {
        DAO,
        DATA_PROVIDER,
        AFFILIATE
    }

    enum CoreState {
        UNKNOWN,
        ACTIVE,
        INACTIVE
    }

    struct Condition {
        address core;
        uint256 conditionId;
    }

    struct CoreData {
        CoreState state;
        uint64 reinforcementAbility;
        uint128 minBet;
        uint128 lockedLiquidity;
    }

    struct Game {
        bytes32 ipfsHash;
        uint128 lockedLiquidity;
        uint64 startsAt;
        bool canceled;
    }

    struct Reward {
        int128 amount;
        uint64 claimedAt;
    }

    event CoreSettingsUpdated(
        address indexed core,
        CoreState state,
        uint64 reinforcementAbility,
        uint128 minBet
    );

    event AffiliateRewarded(address indexed affiliate, uint256 amount);
    event BettorWin(
        address indexed core,
        address indexed bettor,
        uint256 tokenId,
        uint256 amount
    );
    event ClaimTimeoutChanged(uint64 newClaimTimeout);
    event DataProviderChanged(address newDataProvider);
    event FeeChanged(FeeType feeType, uint64 fee);
    event GameCanceled(uint256 indexed gameId);
    event GameShifted(uint256 indexed gameId, uint64 newStart);
    event LiquidityAdded(
        address indexed account,
        uint48 indexed leaf,
        uint256 amount
    );
    event LiquidityRemoved(
        address indexed account,
        uint48 indexed leaf,
        uint256 amount
    );
    event MinBetChanged(address core, uint128 newMinBet);
    event MinDepoChanged(uint128 newMinDepo);
    event NewGame(uint256 indexed gameId, bytes32 ipfsHash, uint64 startsAt);
    event ReinforcementAbilityChanged(uint128 newReinforcementAbility);
    event WithdrawTimeoutChanged(uint64 newWithdrawTimeout);

    error OnlyFactory();

    error SmallDepo();

    error BetExpired();
    error CoreNotActive();
    error ClaimTimeout(uint64 waitTime);
    error GameAlreadyCanceled();
    error GameAlreadyCreated();
    error GameCanceled_();
    error GameNotExists();
    error IncorrectCoreState();
    error IncorrectFee();
    error IncorrectGameId();
    error IncorrectMinBet();
    error IncorrectMinDepo();
    error IncorrectReinforcementAbility();
    error IncorrectTimestamp();
    error LiquidityNotOwned();
    error LiquidityIsLocked();
    error NoLiquidity();
    error NotEnoughLiquidity();
    error SmallBet();
    error UnknownCore();
    error WithdrawalTimeout(uint64 waitTime);

    function initialize(
        address access,
        address dataProvider,
        address token,
        uint128 minDepo,
        uint64 daoFee,
        uint64 dataProviderFee,
        uint64 affiliateFee
    ) external;

    function addCore(address core) external;

    function addLiquidity(uint128 amount) external;

    function addLiquidityNative() external payable;

    function withdrawLiquidity(
        uint48 depNum,
        uint40 percent,
        bool isNative
    ) external;

    function viewPayout(address core, uint256 tokenId)
        external
        view
        returns (uint128 payout);

    function betFor(
        address bettor,
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external returns (uint256 tokenId);

    function betNative(
        address core,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external payable returns (uint256 tokenId);

    /**
     * @notice Make new bet.
     * @notice Emits bet token to `msg.sender`.
     * @param  core address of the Core the bet is intended
     * @param  amount amount of tokens to bet
     * @param  expiresAt the time before which bet should be made
     * @param  betData customized bet data
     */
    function bet(
        address core,
        uint128 amount,
        uint64 expiresAt,
        IBet.BetData calldata betData
    ) external returns (uint256 tokenId);

    function changeDataProvider(address newDataProvider) external;

    function claimAffiliateRewardFor(
        address core,
        bytes calldata data,
        address affiliate
    ) external returns (uint256);

    function claimReward() external returns (uint256);

    function getReserve() external view returns (uint128);

    function addReserve(
        uint256 gameId,
        uint128 lockedReserve,
        uint128 profitReserve,
        uint48 leaf
    ) external returns (uint128 affiliatesReward);

    function addCondition(uint256 gameId) external returns (uint64);

    function withdrawPayout(
        address core,
        uint256 tokenId,
        bool isNative
    ) external;

    function changeLockedLiquidity(uint256 gameId, int128 deltaReserve)
        external;

    /**
     * @notice Indicate the game `gameId` as canceled.
     * @param  gameId the game ID
     */
    function cancelGame(uint256 gameId) external;

    /**
     * @notice Create new game.
     * @param  gameId the match or condition ID according to oracle's internal numbering
     * @param  ipfsHash hash of detailed info about the game stored in the IPFS
     * @param  startsAt timestamp when the game starts
     */
    function createGame(
        uint256 gameId,
        bytes32 ipfsHash,
        uint64 startsAt
    ) external;

    /**
     * @notice Set `startsAt` as new game `gameId` start time.
     * @param  gameId the game ID
     * @param  startsAt new timestamp when the game starts
     */
    function shiftGame(uint256 gameId, uint64 startsAt) external;

    function getGameInfo(uint256 gameId)
        external
        view
        returns (uint64 startsAt, bool canceled);

    function getLockedLiquidityLimit(address core)
        external
        view
        returns (uint128);

    function isGameCanceled(uint256 gameId)
        external
        view
        returns (bool canceled);

    function checkAccess(
        address account,
        address target,
        bytes4 selector
    ) external;

    function checkCore(address core) external view;

    function getLeaf() external view returns (uint48 leaf);

    function coreAffRewards(address) external view returns (uint128);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function checkOwner(address account) external view;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "../libraries/Math.sol";
import "../libraries/SafeCast.sol";

/// @title Specific tools for Affiliate rewards calc
library AffiliateHelper {
    using SafeCast for uint256;

    struct Contribution {
        uint128[2] payouts;
        uint128 totalNetBets;
    }
    // affiliate -> conditionId -> Contribution
    struct Contributions {
        mapping(address => mapping(uint256 => Contribution)) map;
    }
    // affiliate -> conditionIds
    struct ContributedConditionIds {
        mapping(address => uint256[]) map;
    }
    // conditionId -> total contribution to profit of beneficial affiliates for each outcome
    struct AffiliatedProfits {
        mapping(uint256 => uint128[2]) map;
    }

    /**
     * @notice Clear information about contribution to profit of beneficial affiliates for
     *         outcome `outId` of condition `conditionId`.
     */
    function delAffiliatedProfitOutcome(
        AffiliatedProfits storage _affiliatedProfits,
        uint256 conditionId,
        uint256 outId
    ) public {
        delete _affiliatedProfits.map[conditionId][outId];
    }

    /**
     * @notice Clear information about contribution to profit of beneficial affiliates
     *         for each outcome of condition `conditionId`.
     */
    function delAffiliatedProfit(
        AffiliatedProfits storage _affiliatedProfits,
        uint256 conditionId
    ) public {
        delete _affiliatedProfits.map[conditionId];
    }

    /**
     * @notice Add information about the bet made from an affiliate.
     * @param  affiliate address indicated as an affiliate when placing bet
     * @param  conditionId the match or condition ID
     * @param  betAmount amount of tokens is bet from the affiliate
     * @param  payout possible bet winnings
     * @param  outcomeIndex index of predicted outcome
     */
    function updateContribution(
        Contributions storage _contributions,
        ContributedConditionIds storage _contributedConditionIds,
        AffiliatedProfits storage _affiliatedProfits,
        address affiliate,
        uint256 conditionId,
        uint128 betAmount,
        uint128 payout,
        uint256 outcomeIndex
    ) public {
        Contribution storage contribution = _contributions.map[affiliate][
            conditionId
        ];
        Contribution memory contribution_ = contribution;

        if (contribution_.totalNetBets == 0)
            _contributedConditionIds.map[affiliate].push(conditionId);

        uint128[2] storage affiliateProfits = _affiliatedProfits.map[
            conditionId
        ];
        uint256 oldProfit;
        uint256 newProfit;
        for (uint256 i = 0; i < 2; i++) {
            oldProfit = Math.diffOrZero(
                contribution_.totalNetBets,
                contribution_.payouts[i]
            );
            newProfit = Math.diffOrZero(
                contribution_.totalNetBets + betAmount,
                contribution_.payouts[i] + (i == outcomeIndex ? payout : 0)
            );

            if (newProfit > oldProfit)
                affiliateProfits[i] += (newProfit - oldProfit).toUint128();
            else if (newProfit < oldProfit)
                affiliateProfits[i] -= (oldProfit - newProfit).toUint128();
        }
        contribution.totalNetBets += betAmount;
        contribution.payouts[outcomeIndex] += payout;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./FixedMath.sol";
import "../interface/ICondition.sol";
import "./SafeCast.sol";

/// @title Specific tools for Azuro Cores
library CoreTools {
    using FixedMath for uint256;
    using SafeCast for uint256;

    error LargeFundsRatio();
    error WrongOutcome();

    /**
     * @notice Get commission adjusted betting odds.
     * @param  odds pure betting odds
     * @param  margin bookmaker commission
     * @return newOdds commission adjusted betting odds
     */
    function marginAdjustedOdds(uint256 odds, uint256 margin)
        internal
        pure
        returns (uint64)
    {
        uint256 oppositeOdds = FixedMath.ONE.div(
            FixedMath.ONE - FixedMath.ONE.div(odds)
        );
        uint256 a = ((margin + FixedMath.ONE) *
            (oppositeOdds - FixedMath.ONE)) / (odds - FixedMath.ONE);
        uint256 b = margin +
            ((oppositeOdds - FixedMath.ONE) * margin) /
            (odds - FixedMath.ONE);

        return
            ((FixedMath.sqrt(b.sqr() + 4 * a.mul(FixedMath.ONE - margin)) - b)
                .div(2 * a) + FixedMath.ONE).toUint64();
    }

    /**
     * @notice Calculate the odds of bet with amount `amount` for outcome `outcome` of condition `conditionId`.
     * @param  amount amount of tokens to bet
     * @param  outcomeIndex ID of predicted outcome
     * @param  margin bookmaker commission
     * @return odds betting odds
     */
    function calcOdds(
        uint128[2] memory funds,
        uint128 amount,
        uint256 outcomeIndex,
        uint256 margin
    ) internal pure returns (uint256) {
        uint256 odds = uint256(funds[0] + funds[1] + amount).div(
            funds[outcomeIndex] + amount
        );
        if (odds == FixedMath.ONE) revert LargeFundsRatio();

        if (margin > 0) {
            return marginAdjustedOdds(odds, margin);
        } else {
            return odds;
        }
    }

    function getOutcomeIndex(
        ICondition.Condition memory condition,
        uint64 outcome
    ) internal pure returns (uint256) {
        if (outcome == condition.outcomes[0]) return 0;
        if (outcome == condition.outcomes[1]) return 1;
        revert WrongOutcome();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @title Fixed-point math tools
library FixedMath {
    uint256 constant ONE = 1e12;

    function mul(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * other) / ONE;
    }

    function div(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * ONE) / other;
    }

    function sqr(uint256 self) internal pure returns (uint256) {
        return (self * self) / ONE;
    }

    function sqrt(uint256 self) internal pure returns (uint256) {
        self *= ONE;
        uint256 previous = self;
        uint256 next = (self + 1) / 2;
        while (next < previous) {
            previous = next;
            next = (self / next + next) / 2;
        }
        return previous;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @title Common math tools
library Math {
    /**
     * @notice Get non-negative difference of `minuend` and `subtracted`.
     * @return `minuend - subtracted`if it is non-negative or 0
     */
    function diffOrZero(uint256 minuend, uint256 subtracted)
        internal
        pure
        returns (uint256)
    {
        return minuend > subtracted ? minuend - subtracted : 0;
    }

    /**
     * @notice Get max of `a` and `b`.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice Get min of `a` and `b`.
     */
    function min(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library SafeCast {
    enum Type {
        BYTES32,
        INT128,
        UINT64,
        UINT128
    }
    error SafeCastError(Type to);

    function toBytes32(string calldata value) internal pure returns (bytes32) {
        bytes memory value_ = bytes(value);
        if (value_.length > 32) revert SafeCastError(Type.BYTES32);
        return bytes32(value_);
    }

    function toInt128(uint128 value) internal pure returns (int128) {
        if (value > uint128(type(int128).max))
            revert SafeCastError(Type.INT128);
        return int128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) revert SafeCastError(Type.UINT64);
        return uint64(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) revert SafeCastError(Type.UINT128);
        return uint128(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interface/IOwnable.sol";

/**
 * @dev Forked from OpenZeppelin contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/ae03ee04ae226526abad6731cf4024134f46ae28/contracts/access/OwnableUpgradeable.sol
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
abstract contract OwnableUpgradeable is
    IOwnable,
    Initializable,
    ContextUpgradeable
{
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the account is not the owner.
     */
    function checkOwner(address account) public view virtual override {
        require(owner() == account, "Ownable: account is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}