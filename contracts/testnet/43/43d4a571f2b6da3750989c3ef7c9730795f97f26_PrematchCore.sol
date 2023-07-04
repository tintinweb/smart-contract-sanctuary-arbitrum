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

import "./interface/IAzuroBet.sol";
import "./interface/ICoreBase.sol";
import "./libraries/CoreTools.sol";
import "./libraries/FixedMath.sol";
import "./libraries/SafeCast.sol";
import "./libraries/Math.sol";
import "./utils/OwnableUpgradeable.sol";

/// @title Base contract for Azuro cores
abstract contract CoreBase is OwnableUpgradeable, ICoreBase {
    uint256 public constant MAX_OUTCOMES_COUNT = 20;

    using FixedMath for *;
    using SafeCast for *;

    mapping(uint256 => Bet) public bets;
    mapping(uint256 => Condition) public conditions;
    // Condition ID => outcome ID => Condition outcome index + 1
    mapping(uint256 => mapping(uint256 => uint256)) public outcomeNumbers;
    // Condition ID => outcome ID => is winning
    mapping(uint256 => mapping(uint256 => bool)) public winningOutcomes;

    IAzuroBet public azuroBet;
    ILP public lp;

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
     * @notice See {ICoreBase-cancelCondition}.
     */
    function cancelCondition(uint256 conditionId) external {
        Condition storage condition = _getCondition(conditionId);
        if (msg.sender != condition.oracle)
            lp.checkAccess(
                msg.sender,
                address(this),
                this.cancelCondition.selector
            );

        if (_isConditionResolved(condition) || _isConditionCanceled(condition))
            revert ConditionAlreadyResolved();

        _resolveCondition(
            condition,
            conditionId,
            ConditionState.CANCELED,
            new uint64[](0),
            condition.totalNetBets
        );
    }

    /**
     * @notice See {ICoreBase-changeMargin}.
     */
    function changeMargin(uint256 conditionId, uint64 newMargin)
        external
        restricted(this.changeMargin.selector)
    {
        Condition storage condition = _getCondition(conditionId);
        _conditionIsRunning(condition);

        if (newMargin > FixedMath.ONE) revert IncorrectMargin();

        condition.margin = newMargin;

        emit MarginChanged(conditionId, newMargin);
    }

    /**
     * @notice See {ICoreBase-changeOdds}.
     */
    function changeOdds(uint256 conditionId, uint256[] calldata newOdds)
        external
        restricted(this.changeOdds.selector)
    {
        Condition storage condition = _getCondition(conditionId);
        _conditionIsRunning(condition);
        if (newOdds.length != condition.payouts.length)
            revert OutcomesAndOddsCountDiffer();

        _applyOdds(condition, newOdds);
        emit OddsChanged(conditionId, newOdds);
    }

    /**
     * @notice See {ICoreBase-changeReinforcement}.
     */
    function changeReinforcement(uint256 conditionId, uint128 newReinforcement)
        external
        restricted(this.changeReinforcement.selector)
    {
        Condition storage condition = _getCondition(conditionId);
        _conditionIsRunning(condition);

        uint128 reinforcement = condition.reinforcement;
        uint128 newFund = condition.fund;

        if (newReinforcement == reinforcement) revert NothingChanged();

        if (newReinforcement > reinforcement) {
            newFund += newReinforcement - reinforcement;
        } else {
            if (newFund < reinforcement - newReinforcement)
                revert InsufficientFund();
            newFund -= reinforcement - newReinforcement;
        }

        if (
            newFund <
            Math.maxSum(condition.payouts, condition.winningOutcomesCount)
        ) revert IncorrectReinforcement();

        condition.reinforcement = newReinforcement;
        condition.fund = newFund;

        _applyOdds(
            condition,
            CoreTools.calcOdds(
                condition.virtualFunds,
                condition.margin,
                condition.winningOutcomesCount
            )
        );
        emit ReinforcementChanged(conditionId, newReinforcement);
    }

    /**
     * @notice See {ICoreBase-stopCondition}.
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
        uint256 outcomeIndex = getOutcomeIndex(conditionId, outcome);

        uint128[] memory virtualFunds = condition.virtualFunds;
        virtualFunds[outcomeIndex] += amount;
        odds = CoreTools
        .calcOdds(
            virtualFunds,
            condition.margin,
            condition.winningOutcomesCount
        )[outcomeIndex].toUint64();
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
     * @notice Get the AzuroBet token `tokenId` payout amount.
     * @param  tokenId AzuroBet token ID
     * @return amount payout for the token
     */
    function viewPayout(uint256 tokenId)
        external
        view
        returns (uint128 amount)
    {
        (, amount) = _viewPayout(tokenId);
    }

    /**
     * @notice Get condition's `conditionId` index of outcome `outcome`.
     */
    function getOutcomeIndex(uint256 conditionId, uint64 outcome)
        public
        view
        returns (uint256)
    {
        uint256 outcomeNumber = outcomeNumbers[conditionId][outcome];
        if (outcomeNumber == 0) revert WrongOutcome();

        return outcomeNumber - 1;
    }

    /**
     * @notice Check if `outcome` is winning outcome of condition `conditionId`.
     */
    function isOutcomeWinning(uint256 conditionId, uint64 outcome)
        public
        view
        returns (bool)
    {
        return winningOutcomes[conditionId][outcome];
    }

    function isConditionCanceled(uint256 conditionId)
        public
        view
        returns (bool)
    {
        return _isConditionCanceled(_getCondition(conditionId));
    }

    /**
     * @notice Register new condition.
     */
    function _createCondition(ConditionData calldata conditionData) internal {
        if (conditionData.id == 0) revert IncorrectConditionId();
        if (conditionData.margin > FixedMath.ONE) revert IncorrectMargin();

        uint256 length = conditionData.outcomes.length;
        if (length < 2 || length > MAX_OUTCOMES_COUNT)
            revert IncorrectOutcomesCount();
        if (conditionData.odds.length != length)
            revert OutcomesAndOddsCountDiffer();
        if (
            conditionData.winningOutcomesCount == 0 ||
            conditionData.winningOutcomesCount >= length
        ) revert IncorrectWinningOutcomesCount();

        Condition storage condition = conditions[conditionData.id];
        if (condition.gameId != 0) revert ConditionAlreadyCreated();

        condition.payouts = new uint128[](length);
        condition.virtualFunds = new uint128[](length);
        for (uint256 i = 0; i < length; ++i) {
            uint64 outcome = conditionData.outcomes[i];
            if (outcomeNumbers[conditionData.id][outcome] != 0)
                revert DuplicateOutcomes(outcome);
            outcomeNumbers[conditionData.id][outcome] = i + 1;
        }

        condition.reinforcement = conditionData.reinforcement;
        condition.fund = conditionData.reinforcement;
        condition.gameId = conditionData.gameId;
        condition.margin = conditionData.margin;
        condition.winningOutcomesCount = conditionData.winningOutcomesCount;
        condition.oracle = msg.sender;
        condition.lastDepositId = lp.getLastDepositId();
        _applyOdds(condition, conditionData.odds);

        emit ConditionCreated(
            conditionData.gameId,
            conditionData.id,
            conditionData.outcomes,
            conditionData.data
        );
    }

    /**
     * @notice Resolves a condition by updating its state and outcome information, updating Liquidity Pool liquidity and
     *         calculating and distributing payouts and rewards to relevant parties.
     * @param  condition the condition pointer
     * @param  conditionId the condition ID
     * @param  result the ConditionState enum value representing the result of the condition
     * @param  winningOutcomes_ the IDs of the winning outcomes of the condition. Set as empty array if the condition is canceled
     * @param  payout the payout amount to be distributed between bettors
     */
    function _resolveCondition(
        Condition storage condition,
        uint256 conditionId,
        ConditionState result,
        uint64[] memory winningOutcomes_,
        uint128 payout
    ) internal {
        condition.state = result;
        for (uint256 i = 0; i < winningOutcomes_.length; ++i) {
            winningOutcomes[conditionId][winningOutcomes_[i]] = true;
        }

        uint128 lockedReserve;
        uint128 profitReserve;
        {
            uint128[] memory payouts = condition.payouts;
            uint128 fund = condition.fund;
            uint128 reinforcement = condition.reinforcement;
            lockedReserve = _calcReserve(
                fund,
                condition.reinforcement,
                payouts,
                condition.totalNetBets,
                condition.winningOutcomesCount
            );
            profitReserve = lockedReserve + fund - reinforcement - payout;
        }

        lp.addReserve(
            condition.gameId,
            lockedReserve,
            profitReserve,
            condition.lastDepositId
        );

        emit ConditionResolved(
            conditionId,
            uint8(result),
            winningOutcomes_,
            profitReserve.toInt128() - lockedReserve.toInt128()
        );
    }

    /**
     * @notice Calculate the distribution of available fund into [outcome1Fund,..., outcomeNFund] compliant to odds `odds`
     *         and set it as condition virtual funds.
     */
    function _applyOdds(Condition storage condition, uint256[] memory odds)
        internal
    {
        uint256 length = odds.length;
        uint256 normalizer;
        for (uint256 i = 0; i < length; ++i) {
            uint256 odds_ = odds[i];
            if (odds_ == 0) revert ZeroOdds();
            normalizer += FixedMath.ONE.div(odds_);
        }

        uint256 fund = condition.fund -
            Math.maxSum(condition.payouts, condition.winningOutcomesCount);
        uint256 maxVirtualFund = fund / condition.winningOutcomesCount;
        // Multiplying by "FixedMath.ONE" reduces the gas cost of the loop below
        uint256 normalizedFund = (fund * FixedMath.ONE).div(normalizer);
        for (uint256 i = 0; i < length; ++i) {
            uint256 virtualFund = normalizedFund / odds[i];
            if (virtualFund >= maxVirtualFund) revert CoreTools.IncorrectOdds();

            condition.virtualFunds[i] = uint128(virtualFund);
        }
    }

    /**
     * @notice Change condition funds and update the locked reserve amount according to the new funds value.
     */
    function _changeFunds(
        Condition storage condition,
        uint256 outcomeIndex,
        uint128 deltaFund,
        uint128 deltaPayout,
        uint128 deltaTotalNetBets,
        uint8 winningOutcomesCount,
        bool isCashout
    ) internal {
        uint128[] memory payouts = condition.payouts;
        uint128[] memory newPayouts;

        uint128 newFund;
        uint128 newTotalNetBets;
        uint128 reinforcement = condition.reinforcement;

        int128 reserve;
        {
            uint128 fund = condition.fund;
            uint128 totalNetBets = condition.totalNetBets;
            reserve = _calcReserve(
                fund,
                reinforcement,
                payouts,
                totalNetBets,
                winningOutcomesCount
            ).toInt128();

            {
                uint256 length = payouts.length;
                newPayouts = new uint128[](length);
                for (uint256 i = 0; i < length; ++i) newPayouts[i] = payouts[i];
            }

            if (isCashout) {
                newFund = fund - deltaFund;
                newPayouts[outcomeIndex] -= deltaPayout;
                newTotalNetBets = totalNetBets - deltaTotalNetBets;
                if (
                    newFund < Math.maxSum(newPayouts, winningOutcomesCount) ||
                    newFund < condition.totalNetBets
                ) revert InsufficientFund();
            } else {
                newFund = fund + deltaFund;
                newPayouts[outcomeIndex] += deltaPayout;
                newTotalNetBets = totalNetBets + deltaTotalNetBets;
            }
        }

        int128 newReserve = _calcReserve(
            newFund,
            reinforcement,
            newPayouts,
            newTotalNetBets,
            winningOutcomesCount
        ).toInt128();
        lp.changeLockedLiquidity(condition.gameId, newReserve - reserve);

        condition.fund = newFund;
        condition.payouts[outcomeIndex] = newPayouts[outcomeIndex];
        condition.totalNetBets = newTotalNetBets;
    }

    /**
     * @notice Resolve AzuroBet token `tokenId` payout.
     * @param  caller The address that called the {LP-resolvePayout} function.
     * @param  tokenId AzuroBet token ID
     * @return winning account
     * @return amount of winnings
     */
    function _resolvePayout(address caller, uint256 tokenId)
        internal
        returns (address, uint128)
    {
        (bool isCashout, uint128 payout) = _viewPayout(tokenId);

        Bet storage bet = bets[tokenId];
        address betOwner = azuroBet.ownerOf(tokenId);

        if (isCashout) {
            if (caller != betOwner) revert OnlyBetOwner();

            uint256 conditionId = bet.conditionId;
            Condition storage condition = conditions[conditionId];

            uint128 betAmount = bet.amount;
            uint256 outcomeIndex = getOutcomeIndex(conditionId, bet.outcome);
            uint128[] memory virtualFunds = condition.virtualFunds;
            if (virtualFunds[outcomeIndex] <= betAmount)
                revert InsufficientVirtualFund();

            virtualFunds[outcomeIndex] -= betAmount;

            uint128 betPayout = bet.payout;
            _changeFunds(
                condition,
                outcomeIndex,
                payout,
                betPayout,
                betAmount,
                condition.winningOutcomesCount,
                true
            );

            {
                uint256 virtualFund = Math.sum(virtualFunds);
                uint256 oppositeVirtualFund = virtualFund -
                    virtualFunds[outcomeIndex];
                uint256 deltaPayout = betPayout - betAmount;
                uint256 length = virtualFunds.length;
                for (uint256 i = 0; i < length; ++i) {
                    if (i != outcomeIndex) {
                        virtualFunds[i] += uint128(
                            (deltaPayout * virtualFunds[i]) /
                                oppositeVirtualFund
                        );
                    }
                }

                virtualFund += deltaPayout;
                uint256 newVirtualFund = condition.fund -
                    Math.maxSum(
                        condition.payouts,
                        condition.winningOutcomesCount
                    );
                for (uint256 i = 0; i < length; ++i) {
                    virtualFunds[i] = uint128(
                        (newVirtualFund * virtualFunds[i]) / virtualFund
                    );
                    CoreTools.calcProbability(
                        virtualFunds[i],
                        newVirtualFund,
                        condition.winningOutcomesCount
                    );
                }
            }

            condition.virtualFunds = virtualFunds;
        }

        bets[tokenId].isPaid = true;
        return (betOwner, payout);
    }

    /**
     * @notice Get the cash-out amount for bet `bet`.
     * @notice The cash-out amount equals:
     *         the potential payout of the bet * probability of winning * (1 - marginality)
     */
    function _calcCashout(uint256 conditionId, Bet storage bet)
        internal
        view
        returns (uint128)
    {
        Condition storage condition = conditions[conditionId];
        uint128[] memory virtualFunds = condition.virtualFunds;
        uint256 probability = CoreTools.calcProbability(
            virtualFunds[getOutcomeIndex(conditionId, bet.outcome)],
            Math.sum(virtualFunds),
            condition.winningOutcomesCount
        );
        return
            (bet.payout.mul(probability).mul(FixedMath.ONE - condition.margin))
                .toUint128();
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
            revert ConditionNotRunning();
        (uint64 startsAt, bool gameIsCanceled) = lp.getGameInfo(
            condition.gameId
        );
        if (gameIsCanceled || block.timestamp >= startsAt)
            revert ConditionNotRunning();
    }

    /**
     * @notice Calculate the amount of liquidity to be reserved.
     */
    function _calcReserve(
        uint128 fund,
        uint128 reinforcement,
        uint128[] memory payouts,
        uint256 totalNetBets,
        uint8 winningOutcomesCount
    ) internal pure returns (uint128) {
        uint256 maxPayout = Math.maxSum(payouts, winningOutcomesCount);
        if (totalNetBets > maxPayout) maxPayout = totalNetBets;
        return
            (
                (fund > reinforcement)
                    ? Math.diffOrZero(maxPayout, fund - reinforcement)
                    : maxPayout + reinforcement - fund
            ).toUint128();
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

    /**
     * @notice Get the AzuroBet token `tokenId` payout amount.
     * @param  tokenId AzuroBet token ID
     * @return whether the payout is cash-out
     * @return payout for the token
     */
    function _viewPayout(uint256 tokenId)
        internal
        view
        virtual
        returns (bool, uint128)
    {
        Bet storage bet = bets[tokenId];
        if (bet.conditionId == 0) revert BetNotExists();
        if (bet.isPaid) revert AlreadyPaid();

        uint256 conditionId = bet.conditionId;
        Condition storage condition = _getCondition(conditionId);
        if (_isConditionResolved(condition)) {
            if (isOutcomeWinning(bet.conditionId, bet.outcome))
                return (false, bet.payout);
            else return (false, 0);
        }
        if (_isConditionCanceled(condition)) return (false, bet.amount);

        _conditionIsRunning(condition);
        return (true, _calcCashout(conditionId, bet));
    }
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
        uint64 minOdds;
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

    function resolvePayout(address caller, uint256 tokenId)
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
        uint128[] payouts;
        uint128[] virtualFunds;
        uint128 totalNetBets;
        uint128 reinforcement;
        uint128 fund;
        uint64 margin;
        uint64 endsAt;
        uint48 lastDepositId;
        uint8 winningOutcomesCount;
        ConditionState state;
        address oracle;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IBet.sol";
import "./ICondition.sol";
import "./ILP.sol";
import "./IOwnable.sol";
import "./IAzuroBet.sol";

interface ICoreBase is ICondition, IOwnable, IBet {
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
    }

    struct ConditionData {
        uint256 id; // The match or condition ID according to oracle's internal numbering
        uint256 gameId; // The game ID the condition belongs
        uint256[] odds; // Start odds for [team 1, ..., team N]
        uint64[] outcomes; // Unique outcomes for the condition [outcome 1, ..., outcome N]
        uint128 reinforcement; // Maximum amount of liquidity intended to condition reinforcement
        uint64 margin; // Bookmaker commission rate
        uint8 winningOutcomesCount; // The number of winning outcomes for the condition
        bytes[] data; // The additional data
    }

    event ConditionCreated(
        uint256 indexed gameId,
        uint256 indexed conditionId,
        uint64[] outcomes,
        bytes[] data
    );
    event ConditionResolved(
        uint256 indexed conditionId,
        uint8 state,
        uint64[] winningOutcomes,
        int128 lpProfit
    );
    event ConditionStopped(uint256 indexed conditionId, bool flag);

    event ReinforcementChanged(
        uint256 indexed conditionId,
        uint128 newReinforcement
    );
    event MarginChanged(uint256 indexed conditionId, uint64 newMargin);
    event OddsChanged(uint256 indexed conditionId, uint256[] newOdds);

    error OnlyLp();

    error AlreadyPaid();
    error DuplicateOutcomes(uint64 outcome);
    error IncorrectConditionId();
    error IncorrectMargin();
    error IncorrectReinforcement();
    error NothingChanged();
    error IncorrectTimestamp();
    error IncorrectWinningOutcomesCount();
    error IncorrectOutcomesCount();
    error NoPendingReward();
    error OnlyBetOwner();
    error OnlyOracle(address);
    error OutcomesAndOddsCountDiffer();
    error StartOutOfRange(uint256 pendingRewardsCount);
    error WrongOutcome();
    error ZeroOdds();

    error CantChangeFlag();
    error ConditionAlreadyCreated();
    error ConditionAlreadyResolved();
    error ConditionNotExists();
    error ConditionNotRunning();
    error GameAlreadyStarted();
    error InsufficientFund();
    error InsufficientVirtualFund();
    error ResolveTooEarly(uint64 waitTime);

    function lp() external view returns (ILP);

    function azuroBet() external view returns (IAzuroBet);

    function initialize(address azuroBet, address lp) external;

    function calcOdds(
        uint256 conditionId,
        uint128 amount,
        uint64 outcome
    ) external view returns (uint64 odds);

    /**
     * @notice Change the current condition `conditionId` margin.
     */
    function changeMargin(uint256 conditionId, uint64 newMargin) external;

    /**
     * @notice Change the current condition `conditionId` odds.
     */
    function changeOdds(uint256 conditionId, uint256[] calldata newOdds)
        external;

    /**
     * @notice Change the current condition `conditionId` reinforcement.
     */
    function changeReinforcement(uint256 conditionId, uint128 newReinforcement)
        external;

    function getCondition(uint256 conditionId)
        external
        view
        returns (Condition memory);

    /**
     * @notice Indicate the condition `conditionId` as canceled.
     * @notice The condition creator can always cancel it regardless of granted access tokens.
     */
    function cancelCondition(uint256 conditionId) external;

    /**
     * @notice Indicate the status of condition `conditionId` bet lock.
     * @param  conditionId the match or condition ID
     * @param  flag if stop receiving bets for the condition or not
     */
    function stopCondition(uint256 conditionId, bool flag) external;

    function createCondition(ConditionData calldata conditionData) external;

    function getOutcomeIndex(uint256 conditionId, uint64 outcome)
        external
        view
        returns (uint256);

    function isOutcomeWinning(uint256 conditionId, uint64 outcome)
        external
        view
        returns (bool);

    function isConditionCanceled(uint256 conditionId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./IBet.sol";
import "./IOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface ILP is IOwnable, IERC721EnumerableUpgradeable {
    enum FeeType {
        DAO,
        DATA_PROVIDER
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
        uint48 indexed depositId,
        uint256 amount
    );
    event LiquidityDonated(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event LiquidityManagerChanged(address newLiquidityManager);
    event LiquidityRemoved(
        address indexed account,
        uint48 indexed depositId,
        uint256 amount
    );
    event MinBetChanged(address core, uint128 newMinBet);
    event MinDepoChanged(uint128 newMinDepo);
    event NewGame(uint256 indexed gameId, bytes32 ipfsHash, uint64 startsAt);
    event ReinforcementAbilityChanged(uint128 newReinforcementAbility);
    event WithdrawTimeoutChanged(uint64 newWithdrawTimeout);

    error OnlyFactory();

    error SmallDepo();
    error SmallDonation();

    error BetExpired();
    error CoreNotActive();
    error ClaimTimeout(uint64 waitTime);
    error DepositDoesNotExist();
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
        uint64 dataProviderFee
    ) external;

    function addCore(address core) external;

    function addLiquidity(uint128 amount) external returns (uint48);

    function withdrawLiquidity(uint48 depositId, uint40 percent)
        external
        returns (uint128);

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

    function claimReward() external returns (uint128);

    function getReserve() external view returns (uint128);

    function addReserve(
        uint256 gameId,
        uint128 lockedReserve,
        uint128 profitReserve,
        uint48 depositId
    ) external;

    function addCondition(uint256 gameId) external view returns (uint64);

    function withdrawPayout(address core, uint256 tokenId)
        external
        returns (uint128);

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

    function getLastDepositId() external view returns (uint48 depositId);

    function isDepositExists(uint256 depositId) external view returns (bool);

    function token() external view returns (address);

    function fees(uint256) external view returns (uint64);
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

import "./ICoreBase.sol";

interface IPrematchCore is ICoreBase {
    event NewBet(
        address indexed bettor,
        address indexed affiliate,
        uint256 indexed conditionId,
        uint256 tokenId,
        uint64 outcomeId,
        uint128 amount,
        uint256 odds,
        uint128[] funds
    );

    /**
     * @notice Indicate outcomes `winningOutcomes` as happened in condition `conditionId`.
     * @notice See {CoreBase-_resolveCondition}.
     */
    function resolveCondition(
        uint256 conditionId,
        uint64[] calldata winningOutcomes
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./FixedMath.sol";
import "./Math.sol";
import "./SafeCast.sol";

/// @title Specific tools for Azuro Cores
library CoreTools {
    uint256 constant MAX_ODDS = FixedMath.ONE * 100;
    uint256 constant MAX_ITERATIONS = 25;
    uint256 constant PRECISION = 1e7;

    using FixedMath for *;
    using SafeCast for uint256;

    error IncorrectOdds();

    /**
     * @notice Get commission adjusted betting odds.
     * @param  probabilities the probabilities of each outcome of a condition
     * @param  margin bookmaker commission
     * @return odds commission adjusted betting odds for each outcome
     * @param  winningOutcomesCount the number of winning outcomes of the condition
     */
    function marginAdjustedOdds(
        uint256[] memory probabilities,
        uint256 margin,
        uint256 winningOutcomesCount
    ) internal pure returns (uint256[] memory odds) {
        uint256 length = probabilities.length;
        odds = new uint256[](length);
        uint256[] memory spreads = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            spreads[i] = (FixedMath.ONE - probabilities[i]).mul(margin);
        }

        uint256 error = margin;
        uint256 iteration;
        uint256 spreadMultiplier = winningOutcomesCount * FixedMath.ONE;
        for (; iteration < MAX_ITERATIONS; ++iteration) {
            uint256 oddsSpread;
            {
                uint256 spread;
                for (uint256 i = 0; i < length; ++i) {
                    uint256 odds_ = (FixedMath.ONE - spreads[i]).div(
                        probabilities[i]
                    );
                    odds[i] = odds_;
                    spread += FixedMath.ONE.div(odds_);
                }

                oddsSpread = FixedMath.ONE - spreadMultiplier.div(spread);
            }

            if (FixedMath.ratio(margin, oddsSpread) - FixedMath.ONE < PRECISION)
                break;
            assert(margin > oddsSpread);

            uint256 newError = margin - oddsSpread;
            if (newError == error) {
                assert(margin.div(oddsSpread) - FixedMath.ONE < 1e9); // Raise an assertion error if the difference between the expected and actual margin is greater than 0.1%
                break;
            }

            error = newError;

            for (uint256 i = 0; i < length; ++i)
                spreads[i] += (FixedMath.ONE - spreads[i] - probabilities[i])
                    .mul(
                        FixedMath.sigmoid(
                            (error * spreads[i])
                                .div(FixedMath.ONE - FixedMath.ONE.div(odds[i]))
                                .div(FixedMath.ONE - margin) / (oddsSpread)
                        )
                    );
        }

        assert(iteration < MAX_ITERATIONS);
    }

    /**
     * @notice Calculate the betting odds with bookmaker commission `margin` for each outcome of a condition.
     * @param  funds allocated to each outcome of the condition
     * @param  margin bookmaker commission
     * @param  winningOutcomesCount the number of winning outcomes of the condition
     */
    function calcOdds(
        uint128[] memory funds,
        uint256 margin,
        uint256 winningOutcomesCount
    ) internal pure returns (uint256[] memory odds) {
        uint128 fund = Math.sum(funds);
        uint256 length = funds.length;
        if (margin > 0) {
            uint256[] memory probabilities = new uint256[](length);
            for (uint256 i = 0; i < length; ++i) {
                probabilities[i] = calcProbability(
                    funds[i],
                    fund,
                    winningOutcomesCount
                );
            }
            odds = marginAdjustedOdds(
                probabilities,
                margin,
                winningOutcomesCount
            );
        } else {
            odds = new uint256[](length);
            for (uint256 i = 0; i < length; ++i) {
                uint256 odds_ = (fund).div(funds[i] * winningOutcomesCount);
                if (odds_ <= FixedMath.ONE) revert IncorrectOdds();

                odds[i] = odds_;
            }
        }

        for (uint256 i = 0; i < length; ++i) {
            uint256 odds_ = odds[i];
            if (odds_ > MAX_ODDS) odds[i] = MAX_ODDS;
        }

        return odds;
    }

    /**
     * @notice Calculate the probability of an outcome based on its fund and the total fund of a condition.
     */
    function calcProbability(
        uint256 outcomeFund,
        uint256 fund,
        uint256 winningOutcomesCount
    ) internal pure returns (uint256 probability) {
        probability = (outcomeFund * winningOutcomesCount).div(fund);
        if (probability < 1000 || probability >= FixedMath.ONE)
            revert IncorrectOdds(); // This constraint helps to avoid errors in marginAdjustedOdds call
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @title Fixed-point math tools
library FixedMath {
    uint256 constant ONE = 1e12;

    /**
     * @notice Get the ratio of `self` and `other` that is larger than 'ONE'.
     */
    function ratio(uint256 self, uint256 other)
        internal
        pure
        returns (uint256)
    {
        return self > other ? div(self, other) : div(other, self);
    }

    function mul(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * other) / ONE;
    }

    function div(uint256 self, uint256 other) internal pure returns (uint256) {
        return (self * ONE) / other;
    }

    /**
     * @notice Implementation of the sigmoid function.
     * @notice The sigmoid function is commonly used in machine learning to limit output values within a range of 0 to 1.
     */
    function sigmoid(uint256 self) internal pure returns (uint256) {
        return (self * ONE) / (self + ONE);
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
     * @notice Get the biggest item of `a`.
     */
    function max(uint128[] memory a) internal pure returns (uint128 max_) {
        max_ = a[0];
        uint256 length = a.length;
        for (uint256 i = 1; i < length; ++i) {
            uint128 value = a[i];
            if (value > max_) max_ = value;
        }
    }

    /**
     * @notice Get the sum of items of `a`.
     */
    function sum(uint128[] memory a) internal pure returns (uint128 sum_) {
        uint256 length = a.length;
        for (uint256 i = 0; i < length; ++i) {
            sum_ += a[i];
        }
    }

    /**
     * @notice Get the sum of `n` max items of `a`.
     */
    function maxSum(uint128[] memory a, uint256 n)
        internal
        pure
        returns (uint256 sum_)
    {
        if (n == 1) return max(a);

        uint256 length = a.length;

        uint128[] memory sorted = new uint128[](length);
        for (uint256 i = 0; i < length; ++i) {
            sorted[i] = a[i];
        }
        sort(sorted, 0, length - 1);

        for (uint256 i = 0; i < n; ++i) {
            sum_ += sorted[length - 1 - i];
        }
    }

    /**
     * @notice Sort the items of `a` in increasing order.
     */
    function sort(
        uint128[] memory a,
        uint256 left,
        uint256 right
    ) internal pure {
        if (left >= right) return;
        uint256 p = a[(left + right) / 2];
        uint256 i = left;
        uint256 j = right;
        while (i < j) {
            while (a[i] < p) ++i;
            while (a[j] > p) --j;
            if (a[i] > a[j]) (a[i], a[j]) = (a[j], a[i]);
            else ++i;
        }

        if (j > left) sort(a, left, j - 1);
        sort(a, j + 1, right);
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

import "./CoreBase.sol";
import "./interface/IPrematchCore.sol";
import "./libraries/FixedMath.sol";
import "./utils/OwnableUpgradeable.sol";

/// @title Azuro internal core managing pre-match conditions and processing bets on them
contract PrematchCore is CoreBase, IPrematchCore {
    using FixedMath for *;
    using SafeCast for uint256;

    /**
     * @notice See {ICoreBase-createCondition}.
     */
    function createCondition(ConditionData calldata conditionData)
        external
        override
        restricted(this.createCondition.selector)
    {
        _createCondition(conditionData);
        if (lp.addCondition(conditionData.gameId) <= block.timestamp)
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

        uint256 outcomeIndex = getOutcomeIndex(
            data.conditionId,
            data.outcomeId
        );

        uint128[] memory virtualFunds = condition.virtualFunds;
        virtualFunds[outcomeIndex] += amount;

        uint64 odds = CoreTools
        .calcOdds(
            virtualFunds,
            condition.margin,
            condition.winningOutcomesCount
        )[outcomeIndex].toUint64();
        if (odds < betData.minOdds) revert CoreTools.IncorrectOdds();

        uint128 payout = odds.mul(amount).toUint128();
        {
            uint256 virtualFund = Math.sum(virtualFunds);
            uint256 oppositeVirtualFund = virtualFund -
                virtualFunds[outcomeIndex];
            uint256 deltaPayout = payout - amount;
            uint256 length = virtualFunds.length;
            for (uint256 i = 0; i < length; ++i) {
                if (i != outcomeIndex) {
                    virtualFunds[i] -= uint128(
                        (deltaPayout * virtualFunds[i]) / oppositeVirtualFund
                    );
                    CoreTools.calcProbability(
                        virtualFunds[i],
                        virtualFund,
                        condition.winningOutcomesCount
                    );
                }
            }
        }

        condition.virtualFunds = virtualFunds;
        _changeFunds(
            condition,
            outcomeIndex,
            amount,
            payout,
            amount,
            condition.winningOutcomesCount,
            false
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
     * @notice Only condition creator can resolve it.
     * @param  conditionId the match or condition ID
     * @param  winningOutcomes_ the IDs of the winning outcomes of the condition
     */
    function resolveCondition(
        uint256 conditionId,
        uint64[] calldata winningOutcomes_
    ) external override {
        Condition storage condition = _getCondition(conditionId);
        if (winningOutcomes_.length != condition.winningOutcomesCount)
            revert IncorrectWinningOutcomesCount();

        address oracle = condition.oracle;
        if (msg.sender != oracle) revert OnlyOracle(oracle);
        {
            (uint64 timeOut, bool gameIsCanceled) = lp.getGameInfo(
                condition.gameId
            );
            if (
                /// TODO: Use only `_isConditionCanceled` to check if condition or its game is canceled
                gameIsCanceled ||
                condition.state == ConditionState.CANCELED ||
                _isConditionResolved(condition)
            ) revert ConditionAlreadyResolved();

            timeOut += 1 minutes;
            if (block.timestamp < timeOut) revert ResolveTooEarly(timeOut);
        }

        uint128 payout;
        for (uint256 i = 0; i < winningOutcomes_.length; ++i) {
            payout += condition.payouts[
                getOutcomeIndex(conditionId, winningOutcomes_[i])
            ];
        }
        _resolveCondition(
            condition,
            conditionId,
            ConditionState.RESOLVED,
            winningOutcomes_,
            payout
        );
    }

    /**
     * @notice Liquidity Pool: Resolve AzuroBet token `tokenId` payout.
     * @param  caller The address that called the {LP-resolvePayout} function.
     * @param  tokenId AzuroBet token ID
     * @return winning account
     * @return amount of winnings
     */
    function resolvePayout(address caller, uint256 tokenId)
        external
        override
        onlyLp
        returns (address, uint128)
    {
        return _resolvePayout(caller, tokenId);
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