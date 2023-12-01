// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Scamfari is OwnableUpgradeable {
    modifier onlyInvestigator() {
        require(investigators[_msgSender()], "Caller is not an investigator");
        _;
    }

    /// Initializes the contract
    function initialize() public initializer {
        __Ownable_init();
    }

    struct Configuration {
        address reward_token;
        uint256 reward_amount;
    }

    enum Network {
        NEAR,
        Aurora,
        Solana,
        Ethereum,
        BNBChain,
        Bitcoin,
        Polygon,
        OKTC,
        Tron,
        Linea,
        Arbitrum,
        Optimism,
        Avalanche,
        Cronos
    }

    enum Category {
        SocialMediaScammer,
        FraudulentWebsite,
        ScamProject,
        TerroristFinancing,
        FinancialFraud,
        RugPull,
        PumpAndDumpSchemes,
        PonziSchemes,
        Honeypots,
        MoneyLaundering,
        TradeBasedLaundering,
        MixingServices,
        Crime,
        Counterfeiting,
        OrganizedCrime,
        GangOperations,
        MafiaActivities,
        CyberCrime,
        APTGroup,
        PhishingAttacks,
        HackingTool,
        Hackers,
        DataBreaches,
        Drug,
        Trafficking,
        Distribution,
        Manufacturing,
        WeaponsTrade,
        HumanTrafficking,
        SocialScam,
        Blackmail,
        InvestmentScam,
        LotteryScam,
        DataTheft,
        NFTScam,
        IllegalActivity,
        TerroristFinance,
        Sanction,
        DarknetMarkets,
        WarDonations // NOTE: update getCategoryRewards() if you add a new category
    }

    enum ReportStatus {
        Pending,
        Accepted,
        Rejected,
        Claimed
    }

    struct Report {
        uint id;
        address reporter;
        Network network;
        Category category;
        string addr;
        string url;
        ReportStatus status;
        string reject_reason;
        string[] proof;
        string description;
        string country;
    }

    enum ReporterStatus {
        None,
        Blocked,
        Active
    }

    struct Reporter {
        uint[] reports;
        uint256 reward;
        ReporterStatus status;
        string username;
        uint accepted_reports;
    }

    Configuration public configuration;
    mapping(address => bool) private investigators;
    mapping(uint => Report) private reports;
    uint public report_count;

    uint private constant TOP_REPORTER_COUNT = 10;
    struct TopReporter {
        address reporter;
        uint accepted_reports;
    }

    mapping(address => Reporter) private reporters;
    mapping(string => bool) private reported_address;

    event ConfigurationUpdated(address reward_token, uint256 reward_amount);

    /**
     * @param reward_token_ The address of the reward token contract
     * @param reward_amount_ The amount of reward tokens to give to reporters
     * @dev Throws if called by any account other than the contract owner
     */
    function updateConfiguration(
        address reward_token_,
        uint256 reward_amount_
    ) public onlyOwner {
        configuration.reward_token = reward_token_;
        configuration.reward_amount = reward_amount_;

        emit ConfigurationUpdated(reward_token_, reward_amount_);
    }

    event ReportCreated(uint indexed id, address reporter, string addr);

    /**
     * @param network_ The network (blockchain) of the report
     * @param category_ The category of the report
     * @param addr_ The address of the scammer
     * @param url_ The URL associated with the illicit activity
     * @param proof_ The proof of the illicit activity (e.g. links to screenshots)
     * @dev Throws if the reward token is not set
     * @dev Throws if the reward amount is not set
     * @dev Throws if the reporter is blocked
     */
    function createReport(
        Network network_,
        Category category_,
        string memory addr_,
        string memory url_,
        string[] memory proof_,
        string memory description_,
        string memory country_
    ) public {
        require(
            configuration.reward_token != address(0),
            "Reward token not set"
        );
        require(configuration.reward_amount > 0, "Reward amount not set");

        require(
            reporters[_msgSender()].status != ReporterStatus.Blocked,
            "Reporter is blocked"
        );

        require(!reported_address[addr_], "Address is already reported");

        // Increment report count
        report_count += 1;

        uint id = report_count;

        // Add report ID to reporter's list of reports
        reporters[_msgSender()].reports.push(report_count);

        // If reporter is new, set status to active
        if (reporters[_msgSender()].status == ReporterStatus.None) {
            reporters[_msgSender()].status = ReporterStatus.Active;
            reporters_count += 1;
        }

        // Add report record to list of reports
        reports[id] = Report({
            id: id,
            reporter: _msgSender(),
            network: network_,
            category: category_,
            addr: addr_,
            url: url_,
            status: ReportStatus.Pending,
            reject_reason: "",
            proof: proof_,
            description: description_,
            country: country_
        });

        // Mark address as reported
        reported_address[addr_] = true;

        emit ReportCreated(id, _msgSender(), addr_);
    }

    event ReportAccepted(uint indexed id);

    /**
     * @param id_ The ID of the report to accept
     * @dev Throws if called by any account other than an investigator
     * @dev Throws if the report does not exist
     * @dev Throws if the report is not pending
     */
    function accept(uint id_) public onlyInvestigator {
        require(reports[id_].id == id_, "Report does not exist");
        require(
            reports[id_].status == ReportStatus.Pending,
            "Report is not pending"
        );

        // Set report status to Accepted
        reports[id_].status = ReportStatus.Accepted;

        // Get reward amount for the category, if category is not set, use default reward amount
        uint256 reward_amount = category_rewards[reports[id_].category];
        if (reward_amount == 0) {
            reward_amount = configuration.reward_amount;
        }

        // Add the reward amount to the reporter's balance
        reporters[reports[id_].reporter].reward += reward_amount;
        reporters[reports[id_].reporter].accepted_reports += 1;

        uint accepted_reports = reporters[reports[id_].reporter]
            .accepted_reports;

        updateTopReporters(reports[id_].reporter, accepted_reports);

        accepted_reports_count += 1;

        emit ReportAccepted(id_);
    }

    /**
     * @param reporter The address of the reporter that should be checked for the top list
     * @param accepted_reports The number of accepted reports of the reporter
     **/
    function updateTopReporters(
        address reporter,
        uint accepted_reports
    ) private {
        // Be the first to make the list
        if (top_reporters.length == 0) {
            top_reporters.push(
                TopReporter({
                    reporter: reporter,
                    accepted_reports: accepted_reports
                })
            );
            return;
        }

        // Check whether the reporter belongs to the list of top men
        uint threshold = top_reporters[top_reporters.length - 1]
            .accepted_reports;

        // The barrier of entry is zero if the list is not full yet
        if (top_reporters.length < TOP_REPORTER_COUNT) {
            threshold = 0;
        }

        if (accepted_reports > threshold) {
            // Update the new value of accepted reports for the reporter
            bool found = false;
            uint pos = 0;
            for (uint i = 0; i < top_reporters.length; i++) {
                pos = i;
                if (top_reporters[i].reporter == reporter) {
                    top_reporters[i].accepted_reports = accepted_reports;
                    found = true;
                    break;
                }
            }

            // It seems that our guy has pushed someone else off the chart
            if (!found) {
                // Another one bites the dust
                if (top_reporters.length == TOP_REPORTER_COUNT) {
                    top_reporters.pop();
                }

                // There's a new contender in town
                top_reporters.push(
                    TopReporter({
                        reporter: reporter,
                        accepted_reports: accepted_reports
                    })
                );
            }

            // Move the reporter up the chart until it reaches its rightful place
            for (uint i = pos; i > 0; i--) {
                if (
                    top_reporters[i].accepted_reports >
                    top_reporters[i - 1].accepted_reports
                ) {
                    TopReporter memory temp = top_reporters[i - 1];
                    top_reporters[i - 1] = top_reporters[i];
                    top_reporters[i] = temp;
                } else {
                    break;
                }
            }
        }
    }

    event ReportRejected(uint indexed id);

    /**
     * @param id_ The ID of the report to reject
     * @param reason The reason for rejecting the report
     * @dev Throws if called by any account other than an investigator
     * @dev Throws if the report does not exist
     * @dev Throws if the report is not pending
     */
    function reject(uint id_, string memory reason) public onlyInvestigator {
        require(reports[id_].id == id_, "Report does not exist");
        require(
            reports[id_].status == ReportStatus.Pending,
            "Report is not pending"
        );

        // Set report status to Rejected
        reports[id_].status = ReportStatus.Rejected;

        // Set reject reason
        reports[id_].reject_reason = reason;

        // Make address reportable again
        reported_address[reports[id_].addr] = false;

        emit ReportRejected(id_);
    }

    /**
     * @param id_ The ID of the report to get
     * @return report The report
     */
    function getReport(uint id_) public view returns (Report memory) {
        return reports[id_];
    }

    /**
     * @param addr_ The address of the reporter
     * @param skip The number of reports to skip
     * @param take The number of reports to take
     * @return result The list of reports
     */
    function getReportsByReporter(
        address addr_,
        uint skip,
        uint take
    ) public view returns (Report[] memory) {
        uint[] memory report_ids = reporters[addr_].reports;
        uint total_count = report_ids.length;

        if (total_count == 0) {
            return new Report[](0);
        }

        uint count = take;
        if (count > total_count - skip) {
            count = total_count - skip;
        }

        Report[] memory result = new Report[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = reports[report_ids[skip + i]];
        }

        return result;
    }

    /**
     * @param skip The number of reports to skip
     * @param take The number of reports to take
     * @return result The list of reports
     */
    function getReports(
        uint skip,
        uint take
    ) public view returns (Report[] memory) {
        uint total_count = report_count;

        if (total_count == 0) {
            return new Report[](0);
        }

        uint count = take;
        if (count > total_count - skip) {
            count = total_count - skip;
        }

        Report[] memory result = new Report[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = reports[skip + i + 1];
        }

        return result;
    }

    /**
     * @return status_ Reporter status
     * @return reward_ Reporter reward balance
     * @return report_count_ Number of reports submitted by the reporter
     * @return is_investigator_ Whether the reporter is an investigator
     * @return username_ Reporter username
     */
    function getMyStatus()
        public
        view
        returns (
            ReporterStatus status_,
            uint256 reward_,
            uint report_count_,
            bool is_investigator_,
            string memory username_
        )
    {
        Reporter memory reporter = reporters[_msgSender()];
        return (
            reporter.status,
            reporter.reward,
            reporter.reports.length,
            investigators[_msgSender()],
            reporter.username
        );
    }

    event RewardClaimed(address indexed reporter, uint256 amount);

    /**
     * @param amount_ The amount of reward tokens to claim
     * @dev Throws if the reporter does not have enough reward balance
     * @dev Throws if the transfer fails
     */
    function claim(uint256 amount_) public {
        require(
            reporters[_msgSender()].reward >= amount_,
            "Insufficient balance"
        );
        require(
            IERC20(configuration.reward_token).transfer(_msgSender(), amount_),
            "Transfer failed"
        );
        require(
            reporters[_msgSender()].status == ReporterStatus.Active,
            "Reporter is not active"
        );

        checkDailyLimit(amount_);

        reporters[_msgSender()].reward -= amount_;

        applyDailyLimit(amount_);

        emit RewardClaimed(_msgSender(), amount_);
    }

    event ReporterBlocked(address indexed reporter);

    /**
     * @param addr_ The address of the reporter to block
     * @dev Throws if called by any account other than the contract owner
     * @dev Throws if the reporter is not active
     */
    function blockReporter(address addr_) public onlyOwner {
        require(
            reporters[addr_].status == ReporterStatus.Active,
            "Reporter is not active"
        );

        reporters[addr_].status = ReporterStatus.Blocked;

        emit ReporterBlocked(addr_);
    }

    event ReporterUnblocked(address indexed reporter);

    /**
     * @param addr_ The address of the reporter to unblock
     * @dev Throws if called by any account other than the contract owner
     * @dev Throws if the reporter is not blocked
     */
    function unblockReporter(address addr_) public onlyOwner {
        require(
            reporters[addr_].status == ReporterStatus.Blocked,
            "Reporter is not blocked"
        );

        reporters[addr_].status = ReporterStatus.Active;

        emit ReporterUnblocked(addr_);
    }

    event InvestigatorAdded(address indexed investigator);

    /**
     * @param addr_ The address of the investigator to add
     */
    function addInvestigator(address addr_) public onlyOwner {
        require(!investigators[addr_], "Account is already an investigator");

        investigators[addr_] = true;

        emit InvestigatorAdded(addr_);
    }

    event InvestigatorRemoved(address indexed investigator);

    /**
     * @param addr_ The address of the investigator to remove
     */
    function removeInvestigator(address addr_) public onlyOwner {
        require(investigators[addr_], "Account is not an investigator");

        investigators[addr_] = false;

        emit InvestigatorRemoved(addr_);
    }

    /**
     * @param addr_ The address to check
     * @return result Whether the address is already reported
     */
    function checkAddress(string memory addr_) public view returns (bool) {
        return reported_address[addr_];
    }

    event ReporterProfileUpdated(address indexed reporter, string username);

    /**
     * @param username_ The username to set
     */
    function setReporterProfile(string memory username_) public {
        require(
            reporters[_msgSender()].status != ReporterStatus.Blocked,
            "Reporter is blocked"
        );

        // If reporter is new, set status to active
        if (reporters[_msgSender()].status == ReporterStatus.None) {
            reporters[_msgSender()].status = ReporterStatus.Active;
        }

        reporters[_msgSender()].username = username_;

        emit ReporterProfileUpdated(_msgSender(), username_);
    }

    struct TopReporterRecord {
        address addr;
        string username;
        uint score;
    }
    TopReporter[] private top_reporters;

    /**
     * @return result The list of top reporters
     */
    function getTopReporters()
        public
        view
        returns (TopReporterRecord[] memory)
    {
        uint count = top_reporters.length;

        if (count == 0) {
            return new TopReporterRecord[](0);
        }

        TopReporterRecord[] memory result = new TopReporterRecord[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = TopReporterRecord({
                addr: top_reporters[i].reporter,
                username: reporters[top_reporters[i].reporter].username,
                score: top_reporters[i].accepted_reports
            });
        }

        return result;
    }

    uint public reporters_count;
    uint public accepted_reports_count;

    /**
     * @return result The last 10 reports
     */
    function getLastReports() public view returns (Report[] memory) {
        uint count = 10;

        if (report_count == 0) {
            return new Report[](0);
        }

        if (report_count < 10) {
            count = report_count;
        }

        Report[] memory result = new Report[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = reports[report_count - i];
        }

        return result;
    }

    mapping(Category => uint256) public category_rewards;

    /**
     * @param category_ The category to get the reward for
     * @param reward_amount_ The reward amount
     * @dev Throws if called by any account other than the contract owner
     */
    function setCategoryReward(
        Category category_,
        uint256 reward_amount_
    ) public onlyOwner {
        category_rewards[category_] = reward_amount_;
    }

    uint256 private _daily_claim_limit; // 0 = no limit

    struct DailyClaim {
        uint256 claimed_today; // amount claimed today
        uint256 today_started; // timestamp of "today's" start
    }

    mapping(address => DailyClaim) private _daily_claims;

    event DailyClaimLimitUpdated(uint256 daily_claim_limit_);

    /**
     * @param daily_claim_limit The daily claim limit
     * @dev Throws if called by any account other than the contract owner
     */
    function setDailyClaimLimit(uint256 daily_claim_limit) public onlyOwner {
        _daily_claim_limit = daily_claim_limit;
        emit DailyClaimLimitUpdated(daily_claim_limit);
    }

    /**
     * @return claimed_today The amount of tokens that were claimed today
     * @return today_started The timestamp of the today's start
     * @return daily_limit The daily claim limit
     */
    function getMyDailyLimit()
        public
        view
        returns (uint256 claimed_today, uint today_started, uint256 daily_limit)
    {
        DailyClaim storage daily_claim = _daily_claims[_msgSender()];
        if (block.timestamp - daily_claim.today_started > 24 hours) {
            // Reset daily claim amount if the timestamp has expired
            return (0, 0, _daily_claim_limit);
        } else {
            return (
                daily_claim.claimed_today,
                daily_claim.today_started,
                _daily_claim_limit
            );
        }
    }

    /**
     * @param amount_ The amount of tokens to check
     * @dev Throws if the amount exceeds the daily claim limit
     */
    function checkDailyLimit(uint256 amount_) internal {
        if (_daily_claim_limit == 0) {
            return;
        }

        (uint256 claimed_today, , ) = getMyDailyLimit();
        require(
            claimed_today + amount_ <= _daily_claim_limit,
            "Daily limit exceeded"
        );

        DailyClaim storage daily_claim = _daily_claims[_msgSender()];
        if (block.timestamp - daily_claim.today_started > 24 hours) {
            daily_claim.today_started = block.timestamp;
            daily_claim.claimed_today = 0;
        }
    }

    /**
     * @param amount_ The amount of tokens to apply
     * @dev Applies the daily claim limit
     */
    function applyDailyLimit(uint256 amount_) internal {
        if (_daily_claim_limit == 0) {
            return;
        }

        DailyClaim storage daily_claim = _daily_claims[_msgSender()];
        daily_claim.today_started = block.timestamp;
        if (daily_claim.claimed_today == 0) {
            daily_claim.claimed_today = amount_;
        } else {
            daily_claim.claimed_today += amount_;
        }
    }

    struct CategoryReward {
        Category category;
        uint256 reward_amount;
    }

    event CategoriesRewardsUpdated(CategoryReward[] categories_reward_);

    /**
     * @param categories_reward_ The list of categories and reward amounts
     * @dev Throws if called by any account other than the contract owner
     */
    function setCategoriesRewards(CategoryReward[] memory categories_reward_)
        public
        onlyOwner
    {
        for (uint i = 0; i < categories_reward_.length; i++) {
            category_rewards[categories_reward_[i].category] = categories_reward_[i].reward_amount;
        }

        emit CategoriesRewardsUpdated(categories_reward_);
    }

    function getCategoryRewards()
        public
        view
        returns (CategoryReward[] memory)
    {
        CategoryReward[] memory result = new CategoryReward[](
            uint(Category.WarDonations) + 1
        );

        for (uint i = 0; i < result.length; i++) {
            result[i] = CategoryReward({
                category: Category(i),
                reward_amount: category_rewards[Category(i)]
            });
        }

        return result;
    }
}