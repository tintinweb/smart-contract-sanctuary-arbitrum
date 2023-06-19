// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
  *******         **********     ***********     *****     ***********
  *      *        *              *                 *       *
  *        *      *              *                 *       *
  *         *     *              *                 *       *
  *         *     *              *                 *       *
  *         *     **********     *       *****     *       ***********
  *         *     *              *         *       *                 *
  *         *     *              *         *       *                 *
  *        *      *              *         *       *                 *
  *      *        *              *         *       *                 *
  *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "../util/OwnableWithoutContextUpgradeable.sol";
import "./interfaces/ExecutorDependencies.sol";
import "../voting/interfaces/VotingParameters.sol";
import "./interfaces/ExecutorEventError.sol";

/**
 * @title Executor Contract
 *
 * @author Eric Lee ([email protected]) & Primata ([email protected])
 *
 * @notice This is the executor contract for degis Protocol Protection
 * 
 *         The executor is responsible for the execution of the reports and pool proposals
 *         Both administrators or users can execute proposals and reports
 * 
 *         Execute a report means:
 *             - Mark the report as executed
 *             - Reward the reported from the Treasury
 *             - Liquidate / Move the total payout amount out of the priority pool (to the payout pool) 
 * 
 *         Execute a proposal means:
 *             - Mark the proposal as executed
 *             - Create a new priority pool
 */
contract Executor is
    VotingParameters,
    ExecutorEventError,
    OwnableWithoutContextUpgradeable,
    ExecutorDependencies
{
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Whether report already executed
    mapping(uint256 => bool) public reportExecuted;

    // Whether proposal already executed
    mapping(uint256 => bool) public proposalExecuted;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize() public initializer {
        __Ownable_init();
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function setPriorityPoolFactory(address _priorityPoolFactory)
        external
        onlyOwner
    {
        priorityPoolFactory = IPriorityPoolFactory(_priorityPoolFactory);
    }

    function setIncidentReport(address _incidentReport) external onlyOwner {
        incidentReport = IIncidentReport(_incidentReport);
    }

    function setOnboardProposal(address _onboardProposal) external onlyOwner {
        onboardProposal = IOnboardProposal(_onboardProposal);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = ITreasury(_treasury);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Execute a report
     *         The report must already been settled and the result is PASSED
     *         Execution means:
     *             1) Give 10% of protocol income to reporter (USDC)
     *             2) Move the total payout amount out of the priority pool (to payout pool)
     *             3) Deploy new generations of CRTokens and PRI-LP tokens
     *
     *         Can not execute a report before the previous liquidation ended
     *
     * @param _reportId Id of the report to be executed
     */
    function executeReport(uint256 _reportId) public {
        // Check and mark the report as "executed"
        if (reportExecuted[_reportId]) revert Executor__AlreadyExecuted();
        reportExecuted[_reportId] = true;

        IIncidentReport.Report memory report = incidentReport.getReport(
            _reportId
        );

        if (report.status != SETTLED_STATUS)
            revert Executor__ReportNotSettled();
        if (report.result != PASS_RESULT) revert Executor__ReportNotPassed();

        // Executed callback function
        incidentReport.executed(_reportId);

        // Give 10% of treasury to the reporter
        treasury.rewardReporter(report.poolId, report.reporter);

        // Unpause the priority pool and protection pool
        // factory.pausePriorityPool(report.poolId, false);

        // Liquidate the pool
        (, address poolAddress, , , ) = priorityPoolFactory.pools(
            report.poolId
        );
        IPriorityPool(poolAddress).liquidatePool(report.payout);

        emit ReportExecuted(poolAddress, report.poolId, _reportId);
    }

    /**
     * @notice Execute the proposal
     *         The proposal must already been settled and the result is PASSED
     *         New priority pool will be deployed with parameters
     *
     * @param _proposalId Proposal id
     */
    function executeProposal(uint256 _proposalId)
        external
        returns (address newPriorityPool)
    {
        // Check and mark the proposal as "executed"
        if (proposalExecuted[_proposalId]) revert Executor__AlreadyExecuted();
        proposalExecuted[_proposalId] = true;

        IOnboardProposal.Proposal memory proposal = onboardProposal.getProposal(
            _proposalId
        );

        if (proposal.status != SETTLED_STATUS)
            revert Executor__ProposalNotSettled();
        if (proposal.result != PASS_RESULT)
            revert Executor__ProposalNotPassed();

        // Execute the proposal
        newPriorityPool = priorityPoolFactory.deployPool(
            proposal.name,
            proposal.protocolToken,
            proposal.maxCapacity,
            proposal.basePremiumRatio
        );

        emit NewPoolExecuted(
            newPriorityPool,
            _proposalId,
            proposal.protocolToken
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OwnableWithoutContextUpgradeable is Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
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
    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

// import "../../interfaces/IPriorityPool.sol";
import "../../interfaces/IPriorityPoolFactory.sol";
import "../../interfaces/IOnboardProposal.sol";

import "../../interfaces/ITreasury.sol";

interface IPriorityPool {
    function liquidatePool(uint256 amount) external;
}

interface IIncidentReport {
    struct Report {
        uint256 poolId; // Project pool id
        uint256 reportTimestamp; // Time of starting report
        address reporter; // Reporter address
        uint256 voteTimestamp; // Voting start timestamp
        uint256 numFor; // Votes voting for
        uint256 numAgainst; // Votes voting against
        uint256 round; // 0: Initial round 3 days, 1: Extended round 1 day, 2: Double extended 1 day
        uint256 status; // 0: INIT, 1: PENDING, 2: VOTING, 3: SETTLED, 404: CLOSED
        uint256 result; // 1: Pass, 2: Reject, 3: Tied
        uint256 votingReward; // Voting reward per veDEG
        uint256 payout; // Payout amount of this report (partial payout)
    }

    function getReport(uint256) external view returns (Report memory);

    function executed(uint256 _reportId) external;
}

abstract contract ExecutorDependencies {
    IPriorityPoolFactory public priorityPoolFactory;
    IIncidentReport public incidentReport;
    IOnboardProposal public onboardProposal;
    ITreasury public treasury;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

abstract contract VotingParameters {
    // Status parameters for a voting
    uint256 internal constant INIT_STATUS = 0;
    uint256 internal constant PENDING_STATUS = 1;
    uint256 internal constant VOTING_STATUS = 2;
    uint256 internal constant SETTLED_STATUS = 3;
    uint256 internal constant CLOSE_STATUS = 404;

    // Result parameters for a voting
    uint256 internal constant INIT_RESULT = 0;
    uint256 internal constant PASS_RESULT = 1;
    uint256 internal constant REJECT_RESULT = 2;
    uint256 internal constant TIED_RESULT = 3;
    uint256 internal constant FAILED_RESULT = 4;

    // Voting choices
    uint256 internal constant VOTE_FOR = 1;
    uint256 internal constant VOTE_AGAINST = 2;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface ExecutorEventError {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event ReportExecuted(address pool, uint256 poolId, uint256 reportId);

    event NewPoolExecuted(
        address poolAddress,
        uint256 proposalId,
        address protocol
    );

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error Executor__ReportNotSettled();
    error Executor__ReportNotPassed();
    error Executor__ProposalNotSettled();
    error Executor__ProposalNotPassed();
    error Executor__AlreadyExecuted();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

pragma solidity ^0.8.13;

interface IPriorityPoolFactory {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event PoolCreated(
        address poolAddress,
        uint256 poolId,
        string protocolName,
        address protocolToken,
        uint256 maxCapacity,
        uint256 policyPricePerUSDC
    );

    struct PoolInfo {
        string a;
        address b;
        address c;
        uint256 d;
        uint256 e;
    }

    function deg() external view returns (address);

    function deployPool(
        string memory _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _policyPricePerToken
    ) external returns (address);

    function executor() external view returns (address);

    function getPoolAddressList() external view returns (address[] memory);

    function getPoolInfo(uint256 _id) external view returns (PoolInfo memory);

    function incidentReport() external view returns (address);

    function priorityPoolFactory() external view returns (address);

    function maxCapacity() external view returns (uint256);

    function owner() external view returns (address);

    function policyCenter() external view returns (address);

    function poolCounter() external view returns (uint256);

    function poolInfoById(uint256)
        external
        view
        returns (
            string memory protocolName,
            address poolAddress,
            address protocolToken,
            uint256 maxCapacity,
            uint256 policyPricePerUSDC
        );

    function poolRegistered(address) external view returns (bool);

    function protectionPool() external view returns (address);

    function setProtectionPool(address _protectionPool) external;

    function updateMaxCapacity(bool _isUp, uint256 _maxCapacity) external;

    function tokenRegistered(address) external view returns (bool);

    function totalMaxCapacity() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function veDeg() external view returns (address);

    function updateDynamicPool(uint256 _poolId) external;

    function dynamicPoolCounter() external view returns (uint256);

    function dynamic(address _pool) external view returns (bool);

    function pools(uint256 _poolId)
        external
        view
        returns (
            string memory name,
            address poolAddress,
            address protocolToken,
            uint256 maxCapacity,
            uint256 basePremiumRatio
        );

    function payoutPool() external view returns (address);

    function pausePriorityPool(uint256 _poolId, bool _paused) external;

   
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IOnboardProposal {
    struct Proposal {
        string name; // Pool name ("JOE", "GMX")
        address protocolToken; // Protocol native token address
        address proposer; // Proposer address
        uint256 proposeTimestamp; // Timestamp when proposing
        uint256 voteTimestamp; // Timestamp when start voting
        uint256 numFor; // Votes voting for
        uint256 numAgainst; // Votes voting against
        uint256 maxCapacity; // Max capacity ratio
        uint256 basePremiumRatio; // Base annual premium ratio
        uint256 poolId; // Priority pool id
        uint256 status; // Current status (PENDING, VOTING, SETTLED, CLOSED)
        uint256 result; // Final result (PASSED, REJECTED, TIED)
    }

    struct UserVote {
        uint256 choice; // 1: vote for, 2: vote against
        uint256 amount; // veDEG amount for voting
        bool claimed; // Voting reward already claimed
    }

    event NewProposal(
        string name,
        address token,
        uint256 maxCapacity,
        uint256 priceRatio
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event ProposalSettled(uint256 proposalId, uint256 result);
    event ProposalVoted(
        uint256 proposalId,
        address indexed user,
        uint256 voteFor,
        uint256 amount
    );

    function claim(uint256 _proposalId, address _user) external;

    function closeProposal(uint256 _proposalId) external;

    function deg() external view returns (address);

    function executor() external view returns (address);

    function getProposal(uint256 _proposalId)
        external
        view
        returns (Proposal memory);

    function incidentReport() external view returns (address);

    function priorityPoolFactory() external view returns (address);

    function onboardProposal() external view returns (address);

    function owner() external view returns (address);

    function policyCenter() external view returns (address);

    function poolProposed(address) external view returns (bool);

    function proposalCounter() external view returns (uint256);

    function proposals(uint256)
        external
        view
        returns (
            string memory name,
            address protocolToken,
            address proposer,
            uint256 proposeTimestamp,
            uint256 numFor,
            uint256 numAgainst,
            uint256 maxCapacity,
            uint256 priceRatio,
            uint256 poolId,
            uint256 status,
            uint256 result
        );

    function propose(
        string memory _name,
        address _token,
        uint256 _maxCapacity,
        uint256 _priceRatio,
        address _user
    ) external;

    function protectionPool() external view returns (address);

    function renounceOwnership() external;

    function setExecutor(address _executor) external;

    function setIncidentReport(address _incidentReport) external;

    function setPriorityPoolFactory(address _priorityPoolFactory) external;

    function setOnboardProposal(address _onboardProposal) external;

    function setPolicyCenter(address _policyCenter) external;

    function setProtectionPool(address _protectionPool) external;

    function settle(uint256 _proposalId) external;

    function startVoting(uint256 _proposalId) external;

    function transferOwnership(address newOwner) external;

    function getUserProposalVote(address user, uint256 proposalId)
        external
        view
        returns (UserVote memory);

    function veDeg() external view returns (address);

    function vote(
        uint256 _reportId,
        uint256 _isFor,
        uint256 _amount,
        address _user
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface ITreasury {
    function rewardReporter(uint256 _poolId, address _reporter) external;

    function premiumIncome(uint256 _poolId, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../interfaces/VotingParameters.sol";

abstract contract OnboardProposalParameters is VotingParameters {
    // TODO: Parameters for test
    //       2 hours for fujiInternal, 18 hours for fuji
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;

    // DEG threshold for starting a report
    // TODO: Different threshold for test and mainnet
    uint256 public constant PROPOSE_THRESHOLD = 0;

    // 10000 = 100%
    uint256 public constant MAX_CAPACITY_RATIO = 10000;
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
  *******         **********     ***********     *****     ***********
  *      *        *              *                 *       *
  *        *      *              *                 *       *
  *         *     *              *                 *       *
  *         *     *              *                 *       *
  *         *     **********     *       *****     *       ***********
  *         *     *              *         *       *                 *
  *         *     *              *         *       *                 *
  *        *      *              *         *       *                 *
  *      *        *              *         *       *                 *
  *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "../../util/OwnableWithoutContextUpgradeable.sol";

import "./OnboardProposalParameters.sol";
import "./OnboardProposalDependencies.sol";
import "./OnboardProposalEventError.sol";

import "../../interfaces/ExternalTokenDependencies.sol";

/**
 * @notice Onboard Proposal
 */
contract OnboardProposal is
    OnboardProposalParameters,
    OnboardProposalEventError,
    OwnableWithoutContextUpgradeable,
    ExternalTokenDependencies,
    OnboardProposalDependencies
{
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Total number of reports
    uint256 public proposalCounter;

    // Proposal quorum ratio
    uint256 public quorumRatio;

    struct Proposal {
        string name; // Pool name ("JOE", "GMX")
        address protocolToken; // Protocol native token address
        address proposer; // Proposer address
        uint256 proposeTimestamp; // Timestamp when proposing
        uint256 voteTimestamp; // Timestamp when start voting
        uint256 numFor; // Votes voting for
        uint256 numAgainst; // Votes voting against
        uint256 maxCapacity; // Max capacity ratio
        uint256 basePremiumRatio; // Base annual premium ratio
        uint256 poolId; // Priority pool id
        uint256 status; // Current status (PENDING, VOTING, SETTLED, CLOSED)
        uint256 result; // Final result (PASSED, REJECTED, TIED)
    }
    // Proposal ID => Proposal
    mapping(uint256 => Proposal) public proposals;

    // Protocol token => Whether proposed
    // A protocol can only have one pool
    mapping(address => bool) public proposed;

    struct UserVote {
        uint256 choice; // 1: vote for, 2: vote against
        uint256 amount; // veDEG amount for voting
        bool claimed; // Voting reward already claimed
    }
    // User address => report id => user's voting info
    mapping(address => mapping(uint256 => UserVote)) public votes;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(
        address _deg,
        address _veDeg
    ) public initializer {
        __Ownable_init();
        __ExternalToken__Init(_deg, _veDeg);

        // Initial quorum 30%
        quorumRatio = 30;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function getProposal(uint256 _proposalId)
        external
        view
        returns (Proposal memory)
    {
        return proposals[_proposalId];
    }

    function getUserProposalVote(address _user, uint256 _proposalId)
        external
        view
        returns (UserVote memory)
    {
        return votes[_user][_proposalId];
    }

    function getAllProposals()
        external
        view
        returns (Proposal[] memory allProposals)
    {
        uint256 totalProposal = proposalCounter;

        allProposals = new Proposal[](totalProposal);

        for (uint256 i; i < totalProposal; ) {
            allProposals[i] = proposals[i + 1];

            unchecked {
                ++i;
            }
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function setPriorityPoolFactory(address _priorityPoolFactory)
        external
        onlyOwner
    {
        priorityPoolFactory = IPriorityPoolFactory(_priorityPoolFactory);
    }

    function setQuorumRatio(uint256 _quorumRatio) external onlyOwner {
        quorumRatio = _quorumRatio;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Start a new proposal
     *
     * @param _name             New project name
     * @param _token            Native token address
     * @param _maxCapacity      Max capacity ratio for the project pool
     * @param _basePremiumRatio Base annual ratio of the premium
     */
    function propose(
        string calldata _name,
        address _token,
        uint256 _maxCapacity,
        uint256 _basePremiumRatio // 10000 == 100% premium annual cost
    ) external onlyOwner {
        _propose(_name, _token, _maxCapacity, _basePremiumRatio, msg.sender);
    }

    /**
     * @notice Start the voting process
     *         Need the approval of dev team (onlyOwner)
     *
     * @param _id Proposal id to start voting
     */
    function startVoting(uint256 _id) external onlyOwner {
        Proposal storage proposal = proposals[_id];

        if (proposal.status != PENDING_STATUS)
            revert OnboardProposal__WrongStatus();

        proposal.status = VOTING_STATUS;
        proposal.voteTimestamp = block.timestamp;

        emit ProposalVotingStart(_id, block.timestamp);
    }

    /**
     * @notice Close a pending proposal
     *         Need the approval of dev team (onlyOwner)
     *
     * @param _id Proposal id
     */
    function closeProposal(uint256 _id) external onlyOwner {
        Proposal storage proposal = proposals[_id];

        // require current proposal to be settled
        if (proposal.status != PENDING_STATUS)
            revert OnboardProposal__WrongStatus();

        proposal.status = CLOSE_STATUS;

        proposed[proposal.protocolToken] = false;

        emit ProposalClosed(_id, block.timestamp);
    }

    /**
     * @notice Vote for a proposal
     *
     *         Voting power is decided by the (unlocked) balance of veDEG
     *         Once voted, those veDEG will be locked
     *
     * @param _id     Proposal id
     * @param _isFor  Voting choice
     * @param _amount Amount of veDEG to vote
     */
    function vote(
        uint256 _id,
        uint256 _isFor,
        uint256 _amount
    ) external {
        _vote(_id, _isFor, _amount, msg.sender);
    }

    /**
     * @notice Settle the proposal result
     *
     * @param _id Proposal id
     */
    function settle(uint256 _id) external {
        Proposal storage proposal = proposals[_id];

        if (proposal.status != VOTING_STATUS)
            revert OnboardProposal__WrongStatus();

        if (!_passedVotingPeriod(proposal.voteTimestamp))
            revert OnboardProposal__WrongPeriod();

        // If reached quorum, settle the result
        if (_checkQuorum(proposal.numFor + proposal.numAgainst)) {
            uint256 res = _getVotingResult(
                proposal.numFor,
                proposal.numAgainst
            );

            // If this proposal not passed, allow new proposals for the same project
            // If it passed, not allow the same proposals
            if (res != PASS_RESULT) {
                // Allow for new proposals to be proposed for this protocol
                proposed[proposal.protocolToken] = false;
            }

            proposal.result = res;
            proposal.status = SETTLED_STATUS;

            emit ProposalSettled(_id, res);
        }
        // Else, set the result as "FAILED"
        else {
            proposal.result = FAILED_RESULT;
            proposal.status = SETTLED_STATUS;

            // Allow for new proposals to be proposed for this protocol
            proposed[proposal.protocolToken] = false;

            emit ProposalFailed(_id);
        }
    }

    /**
     * @notice Claim back veDEG after voting result settled
     *
     * @param _id Proposal id
     */
    function claim(uint256 _id) external {
        _claim(_id, msg.sender);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Start a new proposal
     *
     * @param _name             New project name
     * @param _token            Native token address
     * @param _maxCapacity      Max capacity ratio for the project pool
     * @param _basePremiumRatio Base annual ratio of the premium
     */
    function _propose(
        string calldata _name,
        address _token,
        uint256 _maxCapacity,
        uint256 _basePremiumRatio, // 10000 == 100% premium annual cost
        address _user
    ) internal {
        if (priorityPoolFactory.tokenRegistered(_token))
            revert OnboardProposal__AlreadyProtected();

        if (_maxCapacity == 0 || _maxCapacity > MAX_CAPACITY_RATIO)
            revert OnboardProposal__WrongCapacity();

        if (_basePremiumRatio >= 10000 || _basePremiumRatio == 0)
            revert OnboardProposal__WrongPremium();

        if (proposed[_token]) revert OnboardProposal__AlreadyProposed();

        // Burn degis tokens to start a proposal
        // deg.burnDegis(_user, PROPOSE_THRESHOLD);

        proposed[_token] = true;

        uint256 currentCounter = ++proposalCounter;
        // Record the proposal info
        Proposal storage proposal = proposals[currentCounter];
        proposal.name = _name;
        proposal.protocolToken = _token;
        proposal.proposer = _user;
        proposal.proposeTimestamp = block.timestamp;
        proposal.status = PENDING_STATUS;
        proposal.maxCapacity = _maxCapacity;
        proposal.basePremiumRatio = _basePremiumRatio;

        emit NewProposal(_name, _token, _user, _maxCapacity, _basePremiumRatio);
    }

    /**
     * @notice Vote for a proposal
     *
     * @param _id     Proposal id
     * @param _isFor  Voting choice
     * @param _amount Amount of veDEG to vote
     */
    function _vote(
        uint256 _id,
        uint256 _isFor,
        uint256 _amount,
        address _user
    ) internal {
        Proposal storage proposal = proposals[_id];

        // Should be manually switched on the voting process
        if (proposal.status != VOTING_STATUS)
            revert OnboardProposal__WrongStatus();
        if (_isFor != 1 && _isFor != 2) revert OnboardProposal__WrongChoice();
        if (_passedVotingPeriod(proposal.voteTimestamp))
            revert OnboardProposal__WrongPeriod();
        if (_amount == 0) revert OnboardProposal__ZeroAmount();

        _enoughVeDEG(_user, _amount);

        // Lock vedeg until this report is settled
        veDeg.lockVeDEG(_user, _amount);

        // Record the user's choice
        UserVote storage userVote = votes[_user][_id];
        if (userVote.amount > 0) {
            if (userVote.choice != _isFor)
                revert OnboardProposal__ChooseBothSides();
        } else {
            userVote.choice = _isFor;
        }
        userVote.amount += _amount;

        // Record the vote for this report
        if (_isFor == 1) {
            proposal.numFor += _amount;
        } else {
            proposal.numAgainst += _amount;
        }

        emit ProposalVoted(_id, _user, _isFor, _amount);
    }

    /**
     * @notice Claim back veDEG after voting result settled
     *
     * @param _id Proposal id
     */
    function _claim(uint256 _id, address _user) internal {
        Proposal storage proposal = proposals[_id];

        if (proposal.status != SETTLED_STATUS)
            revert OnboardProposal__WrongStatus();

        UserVote storage userVote = votes[_user][_id];

        // @audit Add claimed check
        if (userVote.claimed) revert OnboardProposal__AlreadyClaimed();

        // Unlock the veDEG used for voting
        // No reward / punishment
        veDeg.unlockVeDEG(_user, userVote.amount);

        userVote.claimed = true;

        emit Claimed(_id, _user, userVote.amount);
    }

    /**
     * @notice Get the final voting result
     *
     * @param _numFor     Votes for
     * @param _numAgainst Votes against
     *
     * @return result Pass, reject or tied
     */
    function _getVotingResult(uint256 _numFor, uint256 _numAgainst)
        internal
        pure
        returns (uint256 result)
    {
        if (_numFor > _numAgainst) result = PASS_RESULT;
        else if (_numFor < _numAgainst) result = REJECT_RESULT;
        else result = TIED_RESULT;
    }

    /**
     * @notice Check whether has passed the voting time period
     *
     * @param _voteTimestamp Start timestamp of the voting
     *
     * @return hasPassed True for passing
     */
    function _passedVotingPeriod(uint256 _voteTimestamp)
        internal
        view
        returns (bool)
    {
        uint256 endTime = _voteTimestamp + PROPOSAL_VOTING_PERIOD;
        return block.timestamp > endTime;
    }

    /**
     * @notice Check quorum requirement
     *         30% of totalSupply is the minimum requirement for participation
     *
     * @param _totalVotes Total vote numbers
     */
    function _checkQuorum(uint256 _totalVotes) internal view returns (bool) {
        return _totalVotes >= (veDeg.totalSupply() * quorumRatio) / 100;
    }

    /**
     * @notice Check veDEG to be enough
     *         Only unlocked veDEG will be counted
     *
     * @param _user   User address
     * @param _amount Amount to fulfill
     */
    function _enoughVeDEG(address _user, uint256 _amount) internal view {
        uint256 unlockedBalance = veDeg.balanceOf(_user) - veDeg.locked(_user);
        if (unlockedBalance < _amount) revert OnboardProposal__NotEnoughVeDEG();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../../interfaces/IPriorityPoolFactory.sol";

abstract contract OnboardProposalDependencies {
    IPriorityPoolFactory public priorityPoolFactory;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface OnboardProposalEventError {
    event NewProposal(
        string name,
        address token,
        address proposer,
        uint256 maxCapacity,
        uint256 priceRatio
    );

    event ProposalVotingStart(uint256 proposalId, uint256 timestamp);

    event ProposalClosed(uint256 proposalId, uint256 timestamp);

    event ProposalVoted(
        uint256 proposalId,
        address indexed user,
        uint256 voteFor,
        uint256 amount
    );

    event ProposalSettled(uint256 proposalId, uint256 result);

    event ProposalFailed(uint256 proposalId);

    event Claimed(uint256 proposalId, address user, uint256 amount);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error OnboardProposal__WrongStatus();
    error OnboardProposal__WrongPeriod();
    error OnboardProposal__WrongChoice();
    error OnboardProposal__ChooseBothSides();
    error OnboardProposal__NotEnoughVeDEG();
    error OnboardProposal__NotSettled();
    error OnboardProposal__NotWrongChoice();
    error OnboardProposal__AlreadyClaimed();
    error OnboardProposal__ProposeNotExist();
    error OnboardProposal__AlreadyProposed();
    error OnboardProposal__AlreadyProtected();
    error OnboardProposal__WrongCapacity();
    error OnboardProposal__WrongPremium();
    error OnboardProposal__ZeroAmount();
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "./IVeDEG.sol";
import "./IDegisToken.sol";
import "./CommonDependencies.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice External token dependencies
 *         Include the tokens that are not deployed by this repo
 *         DEG, veDEG
 *         They are set as immutable
 */
abstract contract ExternalTokenDependencies is
    CommonDependencies,
    Initializable
{
    IDegisToken internal deg;
    IVeDEG internal veDeg;

    function __ExternalToken__Init(address _deg, address _veDeg)
        internal
        onlyInitializing
    {
        deg = IDegisToken(_deg);
        veDeg = IVeDEG(_veDeg);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../util/SimpleIERC20.sol";

/**
 * @dev Interface of the VeDEG
 */
interface IVeDEG is SimpleIERC20 {
    // Get the locked amount of a user's veDeg
    function locked(address _user) external view returns (uint256);

    // Lock veDEG
    function lockVeDEG(address _to, uint256 _amount) external;

    // Unlock veDEG
    function unlockVeDEG(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../util/SimpleIERC20.sol";

interface IDegisToken is SimpleIERC20 {
    // Mint degis token
    function mintDegis(address _account, uint256 _amount) external;

    // Burn degis token
    function burnDegis(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

abstract contract CommonDependencies {
    uint256 internal constant SCALE = 1e12;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface SimpleIERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
  *******         **********     ***********     *****     ***********
  *      *        *              *                 *       *
  *        *      *              *                 *       *
  *         *     *              *                 *       *
  *         *     *              *                 *       *
  *         *     **********     *       *****     *       ***********
  *         *     *              *         *       *                 *
  *         *     *              *         *       *                 *
  *        *      *              *         *       *                 *
  *      *        *              *         *       *                 *
  *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "../../util/OwnableWithoutContextUpgradeable.sol";

import "./IncidentReportParameters.sol";
import "./IncidentReportDependencies.sol";
import "./IncidentReportEventError.sol";

import "../../interfaces/ExternalTokenDependencies.sol";

/**
 * @notice Incident Report Contract
 *
 *         New reports for project hacks are handled inside this contract
 *
 *         Timeline for a report is:
 *
 *         |-----------------------|----------------------|-------|-------|
 *               Pending Period         Voting Period       Extend Period
 *
 *         When a new report is proposed, it start with PENDING_STATUS.
 *         The person who start the report need to deposit REPORT_THRESHOLD DEG tokens.
 *         During PENDING_STATUS, users & security companies can look at the report event.
 *
 *         After PENDING_PERIOD, the voting can be started and status transfer to VOTING_STATUS.
 *         Users can vote for or against the report with veDeg tokens.
 *         VeDeg tokens used for voting will be tentatively locked until the voting is settled.
 *
 *         After VOTING_PERIOD, the voting can be settled and status transfer to SETTLED_STATUS.
 *         Depending on the votes of each side, the result can be PASSED, REJECTED or TIED.
 *         Different results for their veDeg tokens will be set depending on the result.
 *
 *         If the result has changes during the last 24 hours of voting, the voting will be extended.
 *         The time can only be extended twice.
 *
 *         For voters:
 *              PASSED: Who vote for will get all veDeg tokens from the opposite side
 *              REJECTED: Who vote against will get all veDeg tokens from the opposite side
 *              TIED: Users can unlock their veDeg tokens
 *         For reporter:
 *              PASSED: Get back REPORT_THRESHOLD and get extra REPORT_REWARD & 10% of total treasury income
 *              REJECTED: Lose REPORT_THRESHOLD to whom vote against
 *              TIED: Lose REPORT_THRESHOLD
 *
 *         When an incident report has passed and been executed
 *         The corresponding priority pool will be liquidated which means:
 *             - Move out some assets for users to claim
 *             - Deploy new generation of crTokens and PRI-LP tokens
 *             - Update the farming weights for the priority farming pool
 *
 */
contract IncidentReport is
    IncidentReportParameters,
    IncidentReportEventError,
    OwnableWithoutContextUpgradeable,
    ExternalTokenDependencies,
    IncidentReportDependencies
{
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Total number of reports
    uint256 public reportCounter;

    // Report quorum ratio
    uint256 public quorumRatio;

    struct Report {
        uint256 poolId; // Project pool id
        uint256 reportTimestamp; // Time of starting report
        address reporter; // Reporter address
        uint256 voteTimestamp; // Voting start timestamp
        uint256 numFor; // Votes voting for
        uint256 numAgainst; // Votes voting against
        uint256 round; // 0: Initial round 3 days, 1: Extended round 1 day, 2: Double extended 1 day
        uint256 status; // 0: INIT, 1: PENDING, 2: VOTING, 3: SETTLED, 404: CLOSED
        uint256 result; // 1: Pass, 2: Reject, 3: Tied
        uint256 votingReward; // Voting reward per veDEG
        uint256 payout; // Payout amount of this report (partial payout)
    }
    // Report id => Report
    mapping(uint256 => Report) public reports;

    // Pool id => All related reports
    mapping(uint256 => uint256[]) public poolReports;

    struct TempResult {
        uint256 result;
        uint256 sampleTimestamp;
        bool hasChanged;
    }
    mapping(uint256 => TempResult) public tempResults;

    struct UserVote {
        uint256 choice; // 1: vote for, 2: vote against
        uint256 amount; // total veDEG amount for voting
        bool claimed; // whether has claimed the reward
        bool paid; // whether has paid the debt   // @audit Add paid status
    }
    // User address => report id => user's voting info
    mapping(address => mapping(uint256 => UserVote)) public votes;

    // Pool id => whether the pool is being reported
    mapping(uint256 => bool) public reported;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(
        address _deg,
        address _veDeg
    ) public initializer {
        __Ownable_init();
        __ExternalToken__Init(_deg, _veDeg);

        // Initial quorum 50%
        quorumRatio = 50;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function getUserVote(address _user, uint256 _poolId)
        external
        view
        returns (UserVote memory)
    {
        return votes[_user][_poolId];
    }

    function getTempResult(uint256 _poolId)
        external
        view
        returns (TempResult memory)
    {
        return tempResults[_poolId];
    }

    function getReport(uint256 _id) public view returns (Report memory) {
        return reports[_id];
    }

    function getPoolReports(uint256 _poolId)
        external
        view
        returns (uint256[] memory)
    {
        return poolReports[_poolId];
    }

    function getPoolReportsAmount(uint256 _poolId)
        external
        view
        returns (uint256)
    {
        return poolReports[_poolId].length;
    }


    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function setPriorityPoolFactory(address _priorityPoolFactory)
        external
        onlyOwner
    {
        priorityPoolFactory = IPriorityPoolFactory(_priorityPoolFactory);
    }

    function setExecutor(address _executor) external onlyOwner {
        executor = _executor;
    }

    function setQuorumRatio(uint256 _ratio) external onlyOwner {
        if (_ratio >= 100) revert IncidentReport__QuorumRatioTooBig();
        quorumRatio = _ratio;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Start a new incident report
     *
     *         1000 DEG tokens are staked to start a report
     *         If the report is correct, reporter gets back 1000DEG + 10% usdc income + extra 1000DEG
     *         If the report is wrong, reporter loses 1000DEG to those who vote against
     *         Only callable through proposal center
     *
     * @param _poolId Pool id to report incident
     * @param _payout Payout amount of this report
     */
    function report(uint256 _poolId, uint256 _payout) external onlyOwner {
        _report(_poolId, _payout, msg.sender);
    }

    /**
     * @notice Start the voting process
     *
     *         Can only be started after the pending period
     *         Will change the status from PENDING to VOTING
     *
     * @param _id Report id
     */
    function startVoting(uint256 _id) external {
        Report storage currentReport = reports[_id];
        if (currentReport.status != PENDING_STATUS)
            revert IncidentReport__WrongStatus();

        // Can only start the voting after pending period
        if (!_passedPendingPeriod(currentReport.reportTimestamp))
            revert IncidentReport__WrongPeriod();

        currentReport.status = VOTING_STATUS;
        currentReport.voteTimestamp = block.timestamp;

        emit ReportVotingStart(_id, block.timestamp);
    }

    /**
     * @notice Close a pending report
     *
     *         Only owner can close a pending report
     *         Can only be closed before the pending period ends
     *         Will change the status from PENDING to CLOSED
     *
     * @param _id Report id
     */
    function closeReport(uint256 _id) external onlyOwner {
        Report storage currentReport = reports[_id];
        if (currentReport.status != PENDING_STATUS)
            revert IncidentReport__WrongStatus();

        // Must close the report before pending period ends
        if (_passedPendingPeriod(currentReport.reportTimestamp))
            revert IncidentReport__WrongPeriod();

        currentReport.status = CLOSE_STATUS;

        _setReportedStatus(_id, false);

        poolReports[currentReport.poolId].pop();

        _unpausePools(currentReport.poolId);

        emit ReportClosed(_id, block.timestamp);
    }

    /**
     * @notice Vote on current reports
     *
     *         Voting power is decided by the (unlocked) balance of veDEG
     *         Once voted, those veDEG will be locked
     *         Rewarded if votes with majority
     *         Punished if votes against majority
     *
     * @param _id     Id of the report to be voted on
     * @param _isFor  The user's choice (1: vote for, 2: vote against)
     * @param _amount Amount of veDEG used for this vote
     */
    function vote(
        uint256 _id,
        uint256 _isFor,
        uint256 _amount
    ) external {
        _vote(_id, _isFor, _amount, msg.sender);
    }

    /**
     * @notice Settle the final result for a report
     *
     * @param _id Report id
     */
    function settle(uint256 _id) external {
        Report storage currentReport = reports[_id];

        if (currentReport.status != VOTING_STATUS)
            revert IncidentReport__WrongStatus();

        // Check has passed the voting period
        if (
            !_passedVotingPeriod(
                currentReport.round,
                currentReport.voteTimestamp
            )
        ) revert IncidentReport__WrongPeriod();

        if (currentReport.result > 0) revert IncidentReport__AlreadySettled();

        uint256 res = _checkRoundExtended(_id, currentReport.round);

        if (res > 0) {
            currentReport.status = SETTLED_STATUS;
            if (_checkQuorum(currentReport.numFor + currentReport.numAgainst)) {
                // REJECT or TIED: unlock the priority pool & protection pool immediately
                //                 mark the report as not reported
                if (res != PASS_RESULT) {
                    uint256 poolId = currentReport.poolId;
                    _unpausePools(poolId);
                    _setReportedStatus(poolId, false);

                    poolReports[poolId].pop();
                }

                currentReport.result = res;

                _settleVotingReward(_id, res);
                emit ReportSettled(_id, res);
            } else {
                currentReport.result = FAILED_RESULT;
                uint256 poolId = currentReport.poolId;

                // FAILED: unlock the priority pool & protection pool immediately
                _unpausePools(poolId);
                _setReportedStatus(poolId, false);

                emit ReportFailed(_id);
            }
        } else {
            tempResults[_id].hasChanged = false;

            emit ReportExtended(_id, currentReport.round);
        }
    }

    /**
     * @notice Claim the voting reward
     *         Only callable through proposal center
     *
     * @param _id Report id
     */
    function claimReward(uint256 _id) external {
        _claimReward(_id, msg.sender);
    }

    /**
     * @notice Pay debt to get back veDEG
     *
     *         For those who made a wrong voting choice
     *         The paid DEG will be burned and the veDEG will be unlocked
     *
     *         Can not call this function when result is TIED or choose the correct side
     *
     * @param _id   Report id
     * @param _user User address (can pay debt for another user)
     */
    function payDebt(uint256 _id, address _user) external {
        UserVote memory userVote = votes[_user][_id];
        uint256 finalResult = reports[_id].result;

        if (finalResult == 0) revert IncidentReport__NotSettled();
        if (
            userVote.choice == finalResult ||
            finalResult == TIED_RESULT ||
            finalResult == FAILED_RESULT
        ) revert IncidentReport__NotWrongChoice();
        // @audit Add paid status
        if (userVote.paid) revert IncidentReport__AlreadyPaid();

        uint256 debt = (userVote.amount * DEBT_RATIO) / 10000;

        // Pay the debt in DEG
        deg.burnDegis(msg.sender, debt);

        // Unlock the user's veDEG
        veDeg.unlockVeDEG(_user, userVote.amount);

        // @audit Add paid status
        votes[_user][_id].paid = true;

        emit DebtPaid(msg.sender, _user, debt, userVote.amount);
    }

    function unpausePools(uint256 _poolId) external onlyOwner {
        _unpausePools(_poolId);
    }

    /**
     * @notice Update status after execution
     *         Only callable by executor
     *
     * @param _reportId Report id
     */
    function executed(uint256 _reportId) external {
        if (msg.sender != executor) revert IncidentReport__OnlyExecutor();

        uint256 poolId = reports[_reportId].poolId;
        _setReportedStatus(poolId, false);
        _unpausePools(poolId);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Start a new incident report
     *
     *         1000 DEG tokens are staked to start a report
     *         If the report is correct, reporter gets back 1000DEG + 10% usdc income + extra 1000DEG
     *         If the report is wrong, reporter loses 1000DEG to those who vote against
     *
     * @param _poolId Pool id to report incident
     * @param _payout Payout amount of this report
     * @param _user   Reporter
     */
    function _report(
        uint256 _poolId,
        uint256 _payout,
        address _user
    ) internal {
        // Check whether the pool can be reported
        _checkPoolStatus(_poolId, _payout);

        // Mark as already reported
        _setReportedStatus(_poolId, true);

        uint256 currentId = ++reportCounter;
        // Record the new report
        Report storage newReport = reports[currentId];
        newReport.poolId = _poolId;
        newReport.reportTimestamp = block.timestamp;
        newReport.reporter = _user;
        newReport.status = PENDING_STATUS;
        newReport.payout = _payout;

        // Burn degis tokens to start a report
        // Need to add this smart contract to burner list
        // deg.burnDegis(_user, REPORT_THRESHOLD);

        // Record this report id to this pool's all reports list
        poolReports[_poolId].push(currentId);

        // Pause pools immediately when report
        _pausePools(_poolId);

        emit ReportCreated(currentId, _poolId, block.timestamp, _user, _payout);
    }

    /**
     * @notice Vote on current reports
     *
     *         Voting power is decided by the (unlocked) balance of veDEG
     *         Once voted, those veDEG will be locked
     *         Rewarded if votes with majority
     *         Punished if votes against majority
     *
     * @param _id       Id of the report to be voted on
     * @param _isFor    The user's choice (1: vote for, 2: vote against)
     * @param _amount   Amount of veDEG used for this vote
     * @param _user     The user who votes on the incidnet
     */
    function _vote(
        uint256 _id,
        uint256 _isFor,
        uint256 _amount,
        address _user
    ) internal {
        // Should be manually switched on the voting process
        if (reports[_id].status != VOTING_STATUS)
            revert IncidentReport__WrongStatus();
        if (_amount == 0) revert IncidentReport__ZeroAmount();
        if (_isFor != VOTE_FOR && _isFor != VOTE_AGAINST)
            revert IncidentReport__WrongChoice();

        _enoughVeDEG(_user, _amount);

        // Lock vedeg until this report is settled
        _lockVeDEG(_user, _amount);

        // Record the user's choice
        UserVote storage userVote = votes[_user][_id];
        if (userVote.amount > 0) {
            if (userVote.choice != _isFor)
                revert IncidentReport__ChooseBothSides();
        } else {
            userVote.choice = _isFor;
        }
        userVote.amount += _amount;

        Report storage currentReport = reports[_id];
        // Record the vote for this report
        if (_isFor == VOTE_FOR) {
            currentReport.numFor += _amount;
        } else {
            currentReport.numAgainst += _amount;
        }

        // Record a temporary result
        // If the hasChanged already been true, no need for further update
        // If not reached the last day, no need for update
        if (
            !tempResults[_id].hasChanged &&
            _withinSamplePeriod(
                currentReport.voteTimestamp,
                currentReport.round
            )
        ) {
            _recordTempResult(
                _id,
                currentReport.numFor,
                currentReport.numAgainst
            );
        }

        emit ReportVoted(_id, _user, _isFor, _amount);
    }

    /**
     * @notice Claim the voting reward
     *
     *         Only called when:
     *         - Result is TIED or FAILED
     *         - Result is PASS or REJECT and you have the correct choice
     *
     *         If the result is TIED or FAILED, only unlock veDEG
     *         If the result is the same as your choice, get the reward
     *
     * @param _id   Report id
     * @param _user User address
     */
    function _claimReward(uint256 _id, address _user) internal {
        UserVote memory userVote = votes[_user][_id];
        uint256 finalResult = reports[_id].result;

        if (finalResult == INIT_RESULT) revert IncidentReport__NotSettled();
        if (userVote.claimed) revert IncidentReport__AlreadyClaimed();

        // Correct choice
        if (userVote.choice == finalResult) {
            uint256 reward = reports[_id].votingReward * userVote.amount;
            deg.mintDegis(_user, reward / SCALE);

            _unlockVeDEG(_user, userVote.amount);
        }
        // Tied result, give back user's veDEG
        else if (finalResult == TIED_RESULT || finalResult == FAILED_RESULT) {
            _unlockVeDEG(_user, userVote.amount);
        }
        // Wrong choice, no reward
        else revert IncidentReport__NoReward();

        votes[_user][_id].claimed = true;
    }

    /**
     * @notice Settle voting reward depending on the result
     *
     * @param _id     Report id
     * @param _result Settle result
     */
    function _settleVotingReward(uint256 _id, uint256 _result) internal {
        Report storage currentReport = reports[_id];

        uint256 numFor = currentReport.numFor;
        uint256 numAgainst = currentReport.numAgainst;

        uint256 totalRewardToVoters;

        if (_result == PASS_RESULT) {
            // Get back REPORT_THRESHOLD and get extra REPORTER_REWARD deg tokens
            deg.mintDegis(
                currentReport.reporter,
                REPORTER_REWARD + REPORT_THRESHOLD
            );

            // 40% of total deg reward to the opposite (deg amount)
            // REWARD_RATIO is 100 max
            // veDEG => DEG also divided by 100
            totalRewardToVoters = (numAgainst * REWARD_RATIO) / 10000;

            // Update deg reward for those who vote for
            currentReport.votingReward = (totalRewardToVoters * SCALE) / numFor;
        } else if (_result == REJECT_RESULT) {
            // Total deg reward = reporter's DEG + those who vote for
            totalRewardToVoters =
                REPORT_THRESHOLD +
                (numFor * REWARD_RATIO) /
                10000;

            // Update deg reward for those who vote against
            currentReport.votingReward =
                (totalRewardToVoters * SCALE) /
                numAgainst;
        }

        emit VotingRewardSettled(_id, totalRewardToVoters);
    }

    /**
     * @notice Check quorum requirement
     *         30% of totalSupply is the minimum requirement for participation
     *
     * @param _totalVotes Total vote numbers
     */
    function _checkQuorum(uint256 _totalVotes) internal view returns (bool) {
        return
            _totalVotes >=
            (SimpleIERC20(veDeg).totalSupply() * quorumRatio) / 100;
    }

    /**
     * @notice Check veDEG to be enough
     *
     * @param _user   User address
     * @param _amount Amount to fulfill
     */
    function _enoughVeDEG(address _user, uint256 _amount) internal view {
        uint256 unlockedBalance = veDeg.balanceOf(_user) - veDeg.locked(_user);
        if (unlockedBalance < _amount) revert IncidentReport__NotEnoughVeDEG();
    }

    /**
     * @notice Check whether has passed the pending time period
     *
     * @param _reportTimestamp Start timestamp of the report
     *
     * @return hasPassed True for passing
     */
    function _passedPendingPeriod(uint256 _reportTimestamp)
        internal
        view
        returns (bool)
    {
        return block.timestamp >= _reportTimestamp + PENDING_PERIOD;
    }

    /**
     * @notice Check whether has passed the voting time period
     *
     * @param _round         Current round
     * @param _voteTimestamp Start timestamp of the report voting
     *
     * @return hasPassed True for passing
     */
    function _passedVotingPeriod(uint256 _round, uint256 _voteTimestamp)
        internal
        view
        returns (bool)
    {
        uint256 endTime = _voteTimestamp +
            INCIDENT_VOTING_PERIOD +
            _round *
            EXTEND_PERIOD;
        return block.timestamp >= endTime;
    }

    /**
     * @notice Check whether this round need extend
     *
     * @param _id    Report id
     * @param _round Current round
     *
     * @return result 0 for extending, 1/2/3 for final result
     */
    function _checkRoundExtended(uint256 _id, uint256 _round)
        internal
        returns (uint256 result)
    {
        bool hasChanged = tempResults[_id].hasChanged;

        if (hasChanged && _round < MAX_EXTEND_ROUND) {
            _extendRound(_id);
        } else {
            result = _getVotingResult(
                reports[_id].numFor,
                reports[_id].numAgainst
            );
        }
    }

    /**
     * @notice Extend the current round
     *
     * @param _id Report id
     */
    function _extendRound(uint256 _id) internal {
        unchecked {
            ++reports[_id].round;
        }
    }

    /**
     * @notice Record a temporary result when goes in the sampling period
     *
     *         Temporary result use 1 for "pass" and 2 for "reject"
     *
     * @param _id         Report id
     * @param _numFor     Vote numbers for
     * @param _numAgainst Vote numbers against
     */
    function _recordTempResult(
        uint256 _id,
        uint256 _numFor,
        uint256 _numAgainst
    ) internal {
        TempResult storage temp = tempResults[_id];

        uint256 currentResult = _getVotingResult(_numFor, _numAgainst);

        // If this is the first time for sampling, not record hasChange state
        if (temp.result > 0) {
            temp.hasChanged = currentResult != temp.result;
        }

        // Store the current result and sample time
        temp.result = currentResult;
        temp.sampleTimestamp = block.timestamp;
    }

    /**
     * @notice Check time is within sample period
     *
     * @param _voteTimestamp Vote start timestamp
     * @param _round         Current round
     */
    function _withinSamplePeriod(uint256 _voteTimestamp, uint256 _round)
        internal
        view
        returns (bool)
    {
        uint256 endTime = _voteTimestamp +
            INCIDENT_VOTING_PERIOD +
            _extendTime(_round);

        uint256 lastDayStart = _voteTimestamp +
            INCIDENT_VOTING_PERIOD +
            _extendTime(_round) -
            SAMPLE_PERIOD;

        return block.timestamp > lastDayStart && block.timestamp < endTime;
    }

    /**
     * @notice Get the final voting result
     *
     * @param _numFor     Votes for
     * @param _numAgainst Votes against
     *
     * @return result PASS(1), REJECT(2) or TIED(3)reported
     */
    function _getVotingResult(uint256 _numFor, uint256 _numAgainst)
        internal
        pure
        returns (uint256 result)
    {
        if (_numFor > _numAgainst) result = PASS_RESULT;
        else if (_numFor < _numAgainst) result = REJECT_RESULT;
        else result = TIED_RESULT;
    }

    /**
     * @notice Check pool status and return address
     *         Ensure the pool:
     *             1) Exists
     *             2) Has not been reported'
     *             3) The payout is less than the active covered amount
     *
     * @param _poolId Pool id
     * @param _payout Payout amount
     *
     */
    function _checkPoolStatus(uint256 _poolId, uint256 _payout) internal view {
        (, address pool, , , ) = priorityPoolFactory.pools(_poolId);

        if (pool == address(0)) revert IncidentReport__PoolNotExist();
        if (reported[_poolId]) revert IncidentReport__AlreadyReported();

        if (_payout > ISimplePriorityPool(pool).activeCovered())
            revert IncidentReport__PayoutExceedCovered();
    }

    /**
     * @notice Pause the related priority pool and protection pool
     *         Once there is an incident reported and voting start
     *
     * @param _poolId Priority pool id
     */
    function _pausePools(uint256 _poolId) internal {
        IPriorityPoolFactory(priorityPoolFactory).pausePriorityPool(
            _poolId,
            true
        );
    }

    /**
     * @notice Unpause the related project pool and the re-insurance pool
     *         When the report was REJECTED / TIED / FAILED, unlock immediately
     *         When the report was PASSED, unlock when executor execute it
     *
     * @param _poolId Priority pool id
     */
    function _unpausePools(uint256 _poolId) internal {
        IPriorityPoolFactory(priorityPoolFactory).pausePriorityPool(
            _poolId,
            false
        );
    }

    /**
     * @notice Calculate the extend time
     *
     * @param _round Rounds to extend
     *
     * @return extendTime Extend time length
     */
    function _extendTime(uint256 _round) internal pure returns (uint256) {
        return _round * EXTEND_PERIOD;
    }

    /**
     * @notice Unlock veDEG
     *
     * @param _user   User address
     * @param _amount Amount to unlock
     */
    function _unlockVeDEG(address _user, uint256 _amount) internal {
        veDeg.unlockVeDEG(_user, _amount);
    }

    /**
     * @notice Lock veDEG
     *
     * @param _user   User address
     * @param _amount Amount to lock
     */
    function _lockVeDEG(address _user, uint256 _amount) internal {
        veDeg.lockVeDEG(_user, _amount);
    }

    /**
     * @notice Set reported status for a pool
     *
     * @param _poolId   Pool id
     * @param _reported Whether already reported
     */
    function _setReportedStatus(uint256 _poolId, bool _reported) internal {
        reported[_poolId] = _reported;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../interfaces/VotingParameters.sol";

abstract contract IncidentReportParameters is VotingParameters {
    // Cool down time parameter
    // If you submitted a wrong report, you cannot start another within cooldown period
    uint256 public constant COOLDOWN_WRONG_REPORT = 7 days;

    //  Pending period before start voting
    uint256 public constant PENDING_PERIOD = 1 days;

    // 16 hours for fuji, 2 hours for fujiInternal
    uint256 public constant INCIDENT_VOTING_PERIOD = 3 days;

    // Extend time length
    uint256 public constant EXTEND_PERIOD = 1 days;

    // Sample period for checking whether extend the round
    uint256 public constant SAMPLE_PERIOD = 1 days;

    // DEG threshold for starting a report
    uint256 public constant REPORT_THRESHOLD = 10000 ether;

    // DEG reward for correct reporter
    uint256 public constant REPORTER_REWARD = 10000 ether;

    // Reward & Punishment ratios
    uint256 public constant REWARD_RATIO = 40; // 40% go to winners, 40% reserve
    uint256 public constant RESERVE_RATIO = 40;
    uint256 public constant DEBT_RATIO = 80; // 80% as the debt to unlock veDEG

    // 2 extra rounds at most
    uint256 public constant MAX_EXTEND_ROUND = 2;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../../interfaces/IPriorityPoolFactory.sol";

interface ISimplePriorityPool {
    function activeCovered() external view returns (uint256);
}

abstract contract IncidentReportDependencies {
    IPriorityPoolFactory public priorityPoolFactory;

    address public executor;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IncidentReportEventError {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event ReportCreated(
        uint256 reportId,
        uint256 indexed poolId,
        uint256 reportTimestamp,
        address indexed reporter,
        uint256 payout
    );

    event ReportVotingStart(uint256 reportId, uint256 startTimestamp);

    event ReportClosed(uint256 reportId, uint256 closeTimestamp);

    event ReportVoted(
        uint256 reportId,
        address indexed user,
        uint256 voteFor,
        uint256 amount
    );

    event ReportSettled(uint256 reportId, uint256 result);

    event ReportExtended(uint256 reportId, uint256 round);

    event ReportFailed(uint256 reportId);

    event DebtPaid(
        address payer,
        address user,
        uint256 debt,
        uint256 unlockAmount
    );

    event VotingRewardSettled(uint256 reportId, uint256 totalRewardToVoters);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error IncidentReport__WrongStatus();
    error IncidentReport__WrongPeriod();
    error IncidentReport__WrongChoice();
    error IncidentReport__ChooseBothSides();
    error IncidentReport__NotEnoughVeDEG();
    error IncidentReport__AlreadySettled();
    error IncidentReport__NotSettled();
    error IncidentReport__NotWrongChoice();
    error IncidentReport__AlreadyClaimed();
    error IncidentReport__PoolNotExist();
    error IncidentReport__AlreadyReported();
    error IncidentReport__ZeroAmount();
    error IncidentReport__NoReward();
    error IncidentReport__PayoutExceedCovered();
    error IncidentReport__AlreadyPaid();
    error IncidentReport__OnlyExecutor();
    error IncidentReport__QuorumRatioTooBig();
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../util/OwnableWithoutContextUpgradeable.sol";

import "../../libraries/DateTime.sol";
import "../../interfaces/IPriorityPoolFactory.sol";

import "./WeightedFarmingPoolEventError.sol";
import "./WeightedFarmingPoolDependencies.sol";

/**
 * @notice Weighted Farming Pool
 *
 *         Weighted farming pool support multiple tokens to earn the same reward
 *         Different tokens will have different weights when calculating rewards
 *
 *
 *         Native token premiums will be transferred to this pool
 *         The distribution is in the way of "farming" but with multiple tokens
 *
 *         Different generations of PRI-LP-1-JOE-G1
 *
 *         About the scales of variables:
 *         - weight            SCALE
 *         - share             SCALE
 *         - accRewardPerShare SCALE * SCALE / SCALE = SCALE
 *         - rewardDebt        SCALE * SCALE / SCALE = SCALE
 *         So pendingReward = ((share * acc) / SCALE - debt) / SCALE
 */
contract WeightedFarmingPool is
    WeightedFarmingPoolEventError,
    OwnableWithoutContextUpgradeable,
    WeightedFarmingPoolDependencies
{
    using DateTimeLibrary for uint256;
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    uint256 public constant SCALE = 1e12;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    uint256 public counter;

    struct PoolInfo {
        address[] tokens; // Token addresses (PRI-LP)
        uint256[] amount; // Token amounts
        uint256[] weight; // Weight for each token
        uint256 shares; // Total shares (share = amount * weight)
        address rewardToken; // Reward token address
        uint256 lastRewardTimestamp; // Last reward timestamp
        uint256 accRewardPerShare; // Accumulated reward per share (not per token)
    }
    // Pool id => Pool info
    mapping(uint256 => PoolInfo) public pools;

    // Pool id => Year => Month => Speed
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))
        public speed;

    struct UserInfo {
        uint256[] amount; // Amount of each token
        uint256 shares; // Total shares (share = amount * weight)
        uint256 rewardDebt; // Reward debt
    }
    // Pool Id => User address => User Info
    mapping(uint256 => mapping(address => UserInfo)) public users;

    // Keccak256(poolId, token) => Whether supported
    // Ensure one token not be added for multiple times
    mapping(bytes32 => bool) public supported;

    // Pool id => Token address => Token index in the tokens array
    mapping(uint256 => mapping(address => uint256)) public tokenIndex;

    // Pool id => User address => Index => Previous Weight
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public preWeight;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _policyCenter, address _priorityPoolFactory)
        public
        initializer
    {
        if (_policyCenter == address(0) || _priorityPoolFactory == address(0)) {
            revert WeightedFarmingPool_ZeroAddress();
        }

        __Ownable_init();

        policyCenter = _policyCenter;
        priorityPoolFactory = _priorityPoolFactory;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    modifier isPriorityPool() {
        require(
            IPriorityPoolFactory(priorityPoolFactory).poolRegistered(
                msg.sender
            ),
            "Only Priority Pool"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            msg.sender == priorityPoolFactory,
            "Only Priority Pool Factory"
        );
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get a user's LP amount
     *
     * @param _poolId Pool id
     * @param _user   User address
     *
     * @return amounts Amount array of user's lp in each generation of lp token
     */
    function getUserLPAmount(uint256 _poolId, address _user)
        external
        view
        returns (uint256[] memory)
    {
        return users[_poolId][_user].amount;
    }

    /**
     * @notice Get pool information arrays
     *
     * @param _poolId Pool id
     *
     * @return tokens  Token addresses array
     * @return amounts Token amounts array
     * @return weights Token weights array
     */
    function getPoolArrays(uint256 _poolId)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        PoolInfo storage pool = pools[_poolId];
        return (pool.tokens, pool.amount, pool.weight);
    }

    /**
     * @notice Check whether a token is supported in a certain pool
     *
     * @param _poolId Pool id
     * @param _token  PRI-LP token address
     *
     * @return isSupported Whether supported
     */
    function supportedToken(uint256 _poolId, address _token)
        public
        view
        returns (bool isSupported)
    {
        bytes32 key = keccak256(abi.encodePacked(_poolId, _token));
        return supported[key];
    }

    /**
     * @notice Pending reward
     *
     * @param _id   Pool id
     * @param _user User's address
     *
     * @return pending Pending reward in native token
     */
    function pendingReward(uint256 _id, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo storage pool = pools[_id];
        UserInfo storage user = users[_id][_user];

        // accRewardPerShare has 1 * SCALE
        uint256 accReward = pool.accRewardPerShare;
        uint256 totalReward;

        uint256 currentTime = block.timestamp;
        uint256 lastRewardTime = pool.lastRewardTimestamp;

        if (user.shares > 0) {
            if (
                lastRewardTime > 0 && block.timestamp > pool.lastRewardTimestamp
            ) {
                (uint256 lastY, uint256 lastM, uint256 lastD) = lastRewardTime
                    .timestampToDate();

                (uint256 currentY, uint256 currentM, ) = currentTime
                    .timestampToDate();

                uint256 monthPassed = currentM - lastM;

                // In the same month, use current month speed
                if (monthPassed == 0) {
                    totalReward +=
                        (currentTime - lastRewardTime) *
                        speed[_id][currentY][currentM];
                }
                // Across months, use different months' speed
                else {
                    for (uint256 i; i < monthPassed + 1; ) {
                        // First month reward
                        if (i == 0) {
                            // End timestamp of the first month
                            uint256 endTimestamp = DateTimeLibrary
                                .timestampFromDateTime(
                                    lastY,
                                    lastM,
                                    lastD,
                                    23,
                                    59,
                                    59
                                );
                            totalReward +=
                                (endTimestamp - lastRewardTime) *
                                speed[_id][lastY][lastM];
                        }
                        // Last month reward
                        else if (i == monthPassed) {
                            uint256 startTimestamp = DateTimeLibrary
                                .timestampFromDateTime(
                                    lastY,
                                    lastM,
                                    1,
                                    0,
                                    0,
                                    0
                                );

                            totalReward +=
                                (currentTime - startTimestamp) *
                                speed[_id][lastY][lastM];
                        }
                        // Middle month reward
                        else {
                            uint256 daysInMonth = DateTimeLibrary
                                ._getDaysInMonth(lastY, lastM);

                            totalReward +=
                                (DateTimeLibrary.SECONDS_PER_DAY *
                                    daysInMonth) *
                                speed[_id][lastY][lastM];
                        }

                        unchecked {
                            if (++lastM > 12) {
                                ++lastY;
                                lastM = 1;
                            }

                            ++i;
                        }
                    }
                }
            }

            accReward += (totalReward * SCALE) / pool.shares;

            pending =
                ((user.shares * accReward) / SCALE - user.rewardDebt) /
                SCALE;
        }
    }

    /**
     * @notice Register a new famring pool for priority pool
     *
     * @param _rewardToken Reward token address (protocol native token)
     */
    function addPool(address _rewardToken) external onlyFactory {
        uint256 currentId = ++counter;

        PoolInfo storage pool = pools[currentId];
        pool.rewardToken = _rewardToken;

        emit PoolAdded(currentId, _rewardToken);
    }

    /**
     * @notice Register Pri-LP token
     *
     *         Called when new generation of PRI-LP tokens are deployed
     *         Only called from a priority pool
     *
     * @param _id     Pool Id
     * @param _token  Priority pool lp token address
     * @param _weight Weight of the token in the pool
     */
    function addToken(
        uint256 _id,
        address _token,
        uint256 _weight
    ) external isPriorityPool {
        bytes32 key = keccak256(abi.encodePacked(_id, _token));
        if (supported[key]) revert WeightedFarmingPool__AlreadySupported();

        // Record as supported
        supported[key] = true;

        pools[_id].tokens.push(_token);
        pools[_id].weight.push(_weight);

        uint256 index = pools[_id].tokens.length - 1;

        // Store the token index for later check
        tokenIndex[_id][_token] = index;

        emit NewTokenAdded(_id, _token, index, _weight);
    }

    /**
     * @notice Update the weight of a token in a given pool
     *
     *         Only called from a priority pool
     *
     * @param _id        Pool Id
     * @param _token     Token address
     * @param _newWeight New weight of the token in the pool
     */
    function updateWeight(
        uint256 _id,
        address _token,
        uint256 _newWeight
    ) external isPriorityPool {
        // First update the reward till now
        // Then update the index to be the new one
        updatePool(_id);

        uint256 index = _getIndex(_id, _token);

        PoolInfo storage pool = pools[_id];

        uint256 previousWeight = pool.weight[index];
        pool.weight[index] = _newWeight;

        // Update the pool's shares immediately
        // When user interaction, update each user's share first
        pool.shares -= pool.amount[index] * (previousWeight - _newWeight);

        emit PoolWeightUpdated(_id, index, _newWeight);
    }

    /**
     * @notice Update reward speed when new premium income
     *
     *         Only called from a priority pool
     *
     * @param _id       Pool id
     * @param _newSpeed New speed (SCALED)
     * @param _years    Years to be updated
     * @param _months   Months to be updated
     */
    function updateRewardSpeed(
        uint256 _id,
        uint256 _newSpeed,
        uint256[] memory _years,
        uint256[] memory _months
    ) external isPriorityPool {
        if (_years.length != _months.length)
            revert WeightedFarmingPool__WrongDateLength();

        uint256 length = _years.length;
        for (uint256 i; i < length; ) {
            speed[_id][_years[i]][_months[i]] += _newSpeed;

            unchecked {
                ++i;
            }
        }

        emit RewardSpeedUpdated(_id, _newSpeed, _years, _months);
    }

    /**
     * @notice Deposit from Policy Center
     *
     *         No need for approval
     *         Only called from policy center
     *
     * @param _id     Pool id
     * @param _token  PRI-LP token address
     * @param _amount Amount to deposit
     * @param _user   User address
     */
    function depositFromPolicyCenter(
        uint256 _id,
        address _token,
        uint256 _amount,
        address _user
    ) external {
        if (msg.sender != policyCenter)
            revert WeightedFarmingPool__OnlyPolicyCenter();

        _deposit(_id, _token, _amount, _user);
    }

    /**
     * @notice Directly deposit (need approval)
     */
    function deposit(
        uint256 _id,
        address _token,
        uint256 _amount
    ) external {
        _deposit(_id, _token, _amount, msg.sender);

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawFromPolicyCenter(
        uint256 _id,
        address _token,
        uint256 _amount,
        address _user
    ) external {
        if (msg.sender != policyCenter)
            revert WeightedFarmingPool__OnlyPolicyCenter();

        _withdraw(_id, _token, _amount, _user);
    }

    function withdraw(
        uint256 _id,
        address _token,
        uint256 _amount
    ) external {
        _withdraw(_id, _token, _amount, msg.sender);
    }

    /**
     * @notice Deposit PRI-LP tokens
     *
     * @param _id     Farming pool id
     * @param _token  PRI-LP token address
     * @param _amount PRI-LP token amount
     * @param _user   Real user address
     */
    function _deposit(
        uint256 _id,
        address _token,
        uint256 _amount,
        address _user
    ) internal {
        if (_amount == 0) revert WeightedFarmingPool__ZeroAmount();
        if (_id > counter) revert WeightedFarmingPool__InexistentPool();

        updatePool(_id);

        uint256 index = _getIndex(_id, _token);

        _updateUserWeight(_id, _user, index);

        PoolInfo storage pool = pools[_id];
        UserInfo storage user = users[_id][_user];

        if (user.shares > 0) {
            uint256 pending = ((user.shares * pool.accRewardPerShare) /
                SCALE -
                user.rewardDebt) / SCALE;

            uint256 actualReward = _safeRewardTransfer(
                pool.rewardToken,
                _user,
                pending
            );

            emit Harvest(_id, _user, _user, actualReward);
        }

        // check if current index exists for user
        // index is 0, push
        // length <= index
        uint256 userLength = user.amount.length;
        if (userLength < index + 1) {
            // If user amount length is 0, index is 1 => Push 2 zeros
            // If user amount length is 1, index is 1 => Push 1 zero
            // If user amount length is 1, index is 2 => Push 2 zeros
            for (uint256 i = userLength; i < index + 1; ) {
                user.amount.push(0);

                unchecked {
                    ++i;
                }
            }
        }

        uint256 poolLength = pool.amount.length;
        if (poolLength < index + 1) {
            for (uint256 i = poolLength; i < index + 1; ) {
                pool.amount.push(0);

                unchecked {
                    ++i;
                }
            }
        }

        uint256 currentWeight = pool.weight[index];

        // Update user amount for this gen lp token
        user.amount[index] += _amount;
        user.shares += _amount * currentWeight;

        // Record this user's previous weight for this token index
        preWeight[_id][_user][index] = currentWeight;

        // Update pool amount for this gen lp token
        pool.amount[index] += _amount;
        pool.shares += _amount * currentWeight;

        user.rewardDebt = (user.shares * pool.accRewardPerShare) / SCALE;
    }

    /**
     * @notice Update a user's weight
     *
     * @param _id    Pool id
     * @param _user  User address
     * @param _index Token index in this pool
     */
    function _updateUserWeight(
        uint256 _id,
        address _user,
        uint256 _index
    ) internal {
        PoolInfo storage pool = pools[_id];
        UserInfo storage user = users[_id][_user];

        if (pool.weight.length > 0) {
            uint256 weight = pool.weight[_index];
            uint256 previousWeight = preWeight[_id][_user][_index];

            if (previousWeight != 0) {
                // Only update when weight changes
                if (weight != previousWeight) {
                    uint256 amount = user.amount[_index];

                    // Weight is always decreasing
                    // Ensure: previousWeight - weight > 0
                    user.shares -= amount * (previousWeight - weight);
                }
            }
        }
    }

    function _withdraw(
        uint256 _id,
        address _token,
        uint256 _amount,
        address _user
    ) internal {
        if (_amount == 0) revert WeightedFarmingPool__ZeroAmount();
        if (_id > counter) revert WeightedFarmingPool__InexistentPool();
        if (!supportedToken(_id, _token))
            revert WeightedFarmingPool__NotSupported();

        updatePool(_id);

        uint256 index = _getIndex(_id, _token);

        _updateUserWeight(_id, _user, index);

        PoolInfo storage pool = pools[_id];
        UserInfo storage user = users[_id][_user];

        if (_amount > user.amount[index])
            revert WeightedFarmingPool__NotEnoughAmount();

        if (user.shares > 0) {
            uint256 pending = ((user.shares * pool.accRewardPerShare) /
                SCALE -
                user.rewardDebt) / SCALE;

            uint256 actualReward = _safeRewardTransfer(
                pool.rewardToken,
                _user,
                pending
            );

            emit Harvest(_id, _user, _user, actualReward);
        }

        IERC20(_token).transfer(_user, _amount);

        user.amount[index] -= _amount;
        user.shares -= _amount * pool.weight[index];

        pool.amount[index] -= _amount;
        pool.shares -= _amount * pool.weight[index];

        user.rewardDebt = (user.shares * pool.accRewardPerShare) / SCALE;
    }

    function updatePool(uint256 _id) public {
        PoolInfo storage pool = pools[_id];

        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }

        if (pool.shares > 0) {
            uint256 newReward = _updateReward(_id);

            // accRewardPerShare has 1 * SCALE
            pool.accRewardPerShare += (newReward * SCALE) / pool.shares;

            pool.lastRewardTimestamp = block.timestamp;

            emit PoolUpdated(_id, pool.accRewardPerShare);
        } else {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
    }

    function harvest(uint256 _id, address _to) external {
        if (_id > counter) revert WeightedFarmingPool__InexistentPool();

        updatePool(_id);

        PoolInfo storage pool = pools[_id];
        UserInfo storage user = users[_id][msg.sender];

        if (user.shares > 0) {
            uint256 pending = ((user.shares * pool.accRewardPerShare) /
                SCALE -
                user.rewardDebt) / SCALE;

            uint256 actualReward = _safeRewardTransfer(
                pool.rewardToken,
                _to,
                pending
            );

            emit Harvest(_id, msg.sender, _to, actualReward);

            user.rewardDebt = (user.shares * pool.accRewardPerShare) / SCALE;
        }
    }

    /**
     * @notice Update reward for a pool
     *
     * @param _id Pool id
     */
    function _updateReward(uint256 _id)
        internal
        view
        returns (uint256 totalReward)
    {
        PoolInfo storage pool = pools[_id];

        uint256 currentTime = block.timestamp;
        uint256 lastRewardTime = pool.lastRewardTimestamp;

        (uint256 lastY, uint256 lastM, ) = lastRewardTime.timestampToDate();

        (uint256 currentY, uint256 currentM, ) = currentTime.timestampToDate();

        // If time goes across years
        // Change the calculation of months passed
        uint256 monthPassed;
        if (currentY > lastY) {
            monthPassed = currentM + 12 * (currentY - lastY) - lastM;
        } else {
            monthPassed = currentM - lastM;
        }

        // In the same month, use current month speed
        if (monthPassed == 0) {
            totalReward +=
                (currentTime - lastRewardTime) *
                speed[_id][currentY][currentM];
        }
        // Across months, use different months' speed
        else {
            for (uint256 i; i < monthPassed + 1; ) {
                // First month reward
                if (i == 0) {
                    uint256 daysInMonth = DateTimeLibrary._getDaysInMonth(
                        lastY,
                        lastM
                    );
                    // End timestamp of the first month
                    uint256 endTimestamp = DateTimeLibrary
                        .timestampFromDateTime(
                            lastY,
                            lastM,
                            daysInMonth,
                            23,
                            59,
                            59
                        );
                    totalReward +=
                        (endTimestamp - lastRewardTime) *
                        speed[_id][lastY][lastM];
                }
                // Last month reward
                else if (i == monthPassed) {
                    uint256 startTimestamp = DateTimeLibrary
                        .timestampFromDateTime(lastY, lastM, 1, 0, 0, 0);

                    totalReward +=
                        (currentTime - startTimestamp) *
                        speed[_id][lastY][lastM];
                }
                // Middle month reward
                else {
                    uint256 daysInMonth = DateTimeLibrary._getDaysInMonth(
                        lastY,
                        lastM
                    );

                    totalReward +=
                        (DateTimeLibrary.SECONDS_PER_DAY * daysInMonth) *
                        speed[_id][lastY][lastM];
                }

                unchecked {
                    if (++lastM > 12) {
                        ++lastY;
                        lastM = 1;
                    }

                    ++i;
                }
            }
        }
    }

    /**
     * @notice Safely transfers reward to a user address
     *
     * @param _token  Reward token address
     * @param _to     Address to send reward to
     * @param _amount Amount to send
     */
    function _safeRewardTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256 actualAmount) {
        uint256 balance = IERC20(_token).balanceOf(address(this));

        if (_amount > balance) {
            actualAmount = balance;
        } else {
            actualAmount = _amount;
        }

        // Check the balance before and after the transfer
        // to check the final actual amount
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_to, actualAmount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));

        actualAmount = balanceBefore - balanceAfter;
    }

    /**
     * @notice Returns the index of Cover Right token given a pool id and crtoken address
     *
     *         If the token is not supported, revert with an error (to avoid return default value as 0)
     *
     * @param _id    Pool id
     * @param _token LP token address
     *
     * @return index Index of the token in the pool
     */
    function _getIndex(uint256 _id, address _token)
        internal
        view
        returns (uint256 index)
    {
        if (!supportedToken(_id, _token))
            revert WeightedFarmingPool__NotSupported();

        index = tokenIndex[_id][_token];
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
pragma solidity ^0.8.13;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        (uint256 year, uint256 month, ) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp)
        internal
        pure
        returns (uint256 minute)
    {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp)
        internal
        pure
        returns (uint256 second)
    {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    /**
     * @notice Get the expiry timestamp based on cover duration
     *
     * @param _now           Current timestamp
     * @param _coverDuration Months to cover: 1-3
     */
    function _getExpiry(uint256 _now, uint256 _coverDuration)
        internal
        pure
        returns (
            uint256 endTimestamp,
            uint256 year,
            uint256 month
        )
    {
        // Get the day of the month
        (, , uint256 day) = timestampToDate(_now);

        // Cover duration of 1 month means current month
        // unless today is the 25th calendar day or later
        uint256 monthsToAdd = _coverDuration - 1;

        // TODO: whether need this auto-extending feature
        if (day >= 25) {
            // Add one month
            monthsToAdd += 1;
        }

        return _getFutureMonthEndTime(_now, monthsToAdd);
    }

    /**
     * @notice Get the end timestamp of a future month
     *
     * @param _timestamp   Current timestamp
     * @param _monthsToAdd Months to be added
     *
     * @return endTimestamp End timestamp of a future month
     */
    function _getFutureMonthEndTime(uint256 _timestamp, uint256 _monthsToAdd)
        private
        pure
        returns (
            uint256 endTimestamp,
            uint256 year,
            uint256 month
        )
    {
        uint256 futureTimestamp = addMonths(_timestamp, _monthsToAdd);

        return _getMonthEndTimestamp(futureTimestamp);
    }

    /**
     * @notice Get the last second of a month
     *
     * @param _timestamp Timestamp to be calculated
     *
     * @return endTimestamp End timestamp of the month
     */
    function _getMonthEndTimestamp(uint256 _timestamp)
        private
        pure
        returns (
            uint256 endTimestamp,
            uint256 year,
            uint256 month
        )
    {
        // Get the year and month from the date
        (year, month, ) = timestampToDate(_timestamp);

        // Count the total number of days of that month and year
        uint256 daysInMonth = _getDaysInMonth(year, month);

        // Get the month end timestamp
        endTimestamp = timestampFromDateTime(
            year,
            month,
            daysInMonth,
            23,
            59,
            59
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

abstract contract WeightedFarmingPoolEventError {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event PoolAdded(uint256 poolId, address token);
    event NewTokenAdded(
        uint256 indexed poolId,
        address token,
        uint256 index,
        uint256 weight
    );
    event PoolUpdated(uint256 indexed poolId, uint256 accRewardPerShare);
    event Harvest(
        uint256 indexed poolId,
        address indexed user,
        address indexed receiver,
        uint256 reward
    );
    event PoolWeightUpdated(
        uint256 indexed poolId,
        uint256 index,
        uint256 newWeight
    );
    event RewardSpeedUpdated(
        uint256 indexed poolId,
        uint256 newSpeed,
        uint256[] yearsUpdated,
        uint256[] monthsUpdateed
    );

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error WeightedFarmingPool_ZeroAddress();
    error WeightedFarmingPool__AlreadySupported();
    error WeightedFarmingPool__WrongDateLength();
    error WeightedFarmingPool__ZeroAmount();
    error WeightedFarmingPool__InexistentPool();
    error WeightedFarmingPool__OnlyPolicyCenter();
    error WeightedFarmingPool__NotInPool();
    error WeightedFarmingPool__NotEnoughAmount();
    error WeightedFarmingPool__NotSupported();
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

abstract contract WeightedFarmingPoolDependencies {
    address public policyCenter;

    address public priorityPoolFactory;
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

/*
 //======================================================================\\
 //======================================================================\\
  *******         **********     ***********     *****     ***********
  *      *        *              *                 *       *
  *        *      *              *                 *       *
  *         *     *              *                 *       *
  *         *     *              *                 *       *
  *         *     **********     *       *****     *       ***********
  *         *     *              *         *       *                 *
  *         *     *              *         *       *                 *
  *        *      *              *         *       *                 *
  *      *        *              *         *       *                 *
  *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./ProtectionPoolDependencies.sol";
import "./ProtectionPoolEventError.sol";
import "../../interfaces/ExternalTokenDependencies.sol";

import "../../util/OwnableWithoutContextUpgradeable.sol";
import "../../util/PausableWithoutContextUpgradeable.sol";
import "../../util/FlashLoanPool.sol";

import "../../libraries/DateTime.sol";

/**
 * @title Protection Pool
 *
 * @author Eric Lee ([email protected]) & Primata ([email protected])
 *
 * @notice This is the protection pool contract for Degis Protocol Protection
 *
 *         Users can provide liquidity to protection pool and get PRO-LP token
 *
 *         If the priority pool is unable to fulfil the cover amount,
 *         Protection Pool will be able to provide the remaining part
 */

contract ProtectionPool is
    ProtectionPoolEventError,
    ERC20Upgradeable,
    FlashLoanPool,
    OwnableWithoutContextUpgradeable,
    PausableWithoutContextUpgradeable,
    ExternalTokenDependencies,
    ProtectionPoolDependencies
{
    using DateTimeLibrary for uint256;

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Pool start time
    uint256 public startTime;

    // Last pool reward distribution
    uint256 public lastRewardTimestamp;

    // PRO_LP token price
    uint256 public price;

    // Total amount staked
    uint256 public stakedSupply;

    // Year => Month => Speed
    mapping(uint256 => mapping(uint256 => uint256)) public rewardSpeed;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(
        address _deg,
        address _veDeg
    ) public initializer {
        __ERC20_init("ProtectionPool", "PRO-LP");
        __FlashLoan__Init(USDC);
        __Ownable_init();
        __Pausable_init();
        __ExternalToken__Init(_deg, _veDeg);

        // Register time that pool was deployed
        startTime = block.timestamp;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    modifier onlyPolicyCenter() {
        if (msg.sender != policyCenter)
            revert ProtectionPool__OnlyPolicyCenter();
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get total active cover amount of all pools
     *         Only calculate those "already dynamic" pools
     *
     * @return activeCovered Covered amount
     */
    function getTotalActiveCovered()
        public
        view
        returns (uint256 activeCovered)
    {
        IPriorityPoolFactory factory = IPriorityPoolFactory(
            priorityPoolFactory
        );

        uint256 poolAmount = factory.poolCounter();

        for (uint256 i; i < poolAmount; ) {
            (, address poolAddress, , , ) = factory.pools(i + 1);

            if (factory.dynamic(poolAddress)) {
                activeCovered += IPriorityPool(poolAddress).activeCovered();
            }

            unchecked {
                ++i;
            }
        }
    }

    function getTotalCovered() public view returns (uint256 totalCovered) {
        IPriorityPoolFactory factory = IPriorityPoolFactory(
            priorityPoolFactory
        );

        uint256 poolAmount = factory.poolCounter();

        for (uint256 i; i < poolAmount; ) {
            (, address poolAddress, , , ) = factory.pools(i + 1);

            totalCovered += IPriorityPool(poolAddress).activeCovered();

            unchecked {
                ++i;
            }
        }
    }

    // @audit change decimal
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function setIncidentReport(address _incidentReport) external onlyOwner {
        incidentReport = _incidentReport;
    }

    function setPolicyCenter(address _policyCenter) external onlyOwner {
        policyCenter = _policyCenter;
    }

    function setPriorityPoolFactory(address _priorityPoolFactory)
        external
        onlyOwner
    {
        priorityPoolFactory = _priorityPoolFactory;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Update index cut when claim happened
     */
    function updateIndexCut() public {
        IPriorityPoolFactory factory = IPriorityPoolFactory(
            priorityPoolFactory
        );

        uint256 poolAmount = factory.poolCounter();

        uint256 currentReserved = SimpleIERC20(USDC).balanceOf(address(this));

        uint256 indexToCut;
        uint256 minRequirement;

        for (uint256 i; i < poolAmount; ) {
            (, address poolAddress, , , ) = factory.pools(i + 1);

            minRequirement = IPriorityPool(poolAddress).minAssetRequirement();

            if (minRequirement > currentReserved) {
                indexToCut = (currentReserved * 10000) / minRequirement;
                IPriorityPool(poolAddress).setCoverIndex(indexToCut);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Updates and retrieves latest price to provide liquidity to Protection Pool
     */
    function getLatestPrice() external returns (uint256) {
        _updatePrice();
        return price;
    }

    /**
     * @notice Finish providing liquidity
     *         Only callable through policyCenter
     *
     * @param _amount   Liquidity amount (usdc)
     * @param _provider Provider address
     */
    function providedLiquidity(uint256 _amount, address _provider)
        external
        onlyPolicyCenter
    {
        _updatePrice();

        // Mint PRO_LP tokens to the user
        uint256 amountToMint = (_amount * SCALE) / price;
        _mint(_provider, amountToMint);
        emit LiquidityProvided(_amount, amountToMint, _provider);
    }

    /**
     * @notice Finish removing liquidity
     *         Only callable through 
     *         1) policyCenter (by user removing liquidity)
     *         2) 
     *         
     *
     * @param _amount   Liquidity to remove (LP token amount)
     * @param _provider Provider address
     */
    function removedLiquidity(uint256 _amount, address _provider)
        external
        whenNotPaused
        returns (uint256 usdcToTransfer)
    {
        if (
            msg.sender != policyCenter &&
            !IPriorityPoolFactory(priorityPoolFactory).poolRegistered(
                msg.sender
            )
        ) revert ProtectionPool__OnlyPriorityPoolOrPolicyCenter();

        if (_amount > totalSupply())
            revert ProtectionPool__ExceededTotalSupply();

        _updatePrice();

        // Burn PRO_LP tokens to the user
        usdcToTransfer = (_amount * price) / SCALE;

        if (msg.sender == policyCenter) {
            checkEnoughLiquidity(usdcToTransfer);
        }

        // @audit Change path
        // If sent from policyCenter => this is a user action
        // If sent from priority pool => this is a payout action
        address realPayer = msg.sender == policyCenter ? _provider : msg.sender;

        _burn(realPayer, _amount);
        SimpleIERC20(USDC).transfer(_provider, usdcToTransfer);

        emit LiquidityRemoved(_amount, usdcToTransfer, _provider);
    }

    function checkEnoughLiquidity(uint256 _amountToRemove) public view {
        // Minimum usdc requirement
        uint256 minRequirement = minAssetRequirement();

        uint256 currentReserved = SimpleIERC20(USDC).balanceOf(address(this));

        if (currentReserved < minRequirement + _amountToRemove)
            revert ProtectionPool__NotEnoughLiquidity();
    }

    function minAssetRequirement()
        public
        view
        returns (uint256 minRequirement)
    {
        IPriorityPoolFactory factory = IPriorityPoolFactory(
            priorityPoolFactory
        );

        uint256 poolAmount = factory.poolCounter();
        uint256 minRequirementForPool;

        for (uint256 i; i < poolAmount; ) {
            (, address poolAddress, , , ) = factory.pools(i + 1);

            minRequirementForPool = IPriorityPool(poolAddress)
                .minAssetRequirement();

            minRequirement = minRequirementForPool > minRequirement
                ? minRequirementForPool
                : minRequirement;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Removes liquidity when a claim is made
     *
     * @param _amount Amount of liquidity to remove
     * @param _to     Address to transfer the liquidity to
     */
    function removedLiquidityWhenClaimed(uint256 _amount, address _to)
        external
    {
        if (
            !IPriorityPoolFactory(priorityPoolFactory).poolRegistered(
                msg.sender
            )
        ) revert ProtectionPool__OnlyPriorityPool();

        if (_amount > SimpleIERC20(USDC).balanceOf(address(this)))
            revert ProtectionPool__NotEnoughBalance();

        SimpleIERC20(USDC).transfer(_to, _amount);

        _updatePrice();

        emit LiquidityRemovedWhenClaimed(msg.sender, _amount);
    }

    /**
     * @notice Update when new cover is bought
     */
    function updateWhenBuy() external onlyPolicyCenter {
        _updatePrice();
    }

    /**
     * @notice Set paused state of the protection pool
     *         Only callable by owner, incidentReport, or priorityPoolFactory
     *
     * @param _paused True for pause, false for unpause
     */
    function pauseProtectionPool(bool _paused) external {
        if (
            (msg.sender != owner()) &&
            (msg.sender != incidentReport) &&
            (msg.sender != priorityPoolFactory)
        ) revert ProtectionPool__NotAllowedToPause();
        _pause(_paused);
    }

    function updateStakedSupply(bool _isStake, uint256 _amount)
        external
        onlyPolicyCenter
    {
        if (_isStake) {
            stakedSupply += _amount;
        } else stakedSupply -= _amount;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Update the price of PRO_LP token
     */
    function _updatePrice() internal {
        if (totalSupply() == 0) {
            price = SCALE;
            return;
        }
        price =
            ((SimpleIERC20(USDC).balanceOf(address(this))) * SCALE) /
            totalSupply();

        emit PriceUpdated(price);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../../interfaces/CommonDependencies.sol";

interface IPriorityPoolFactory {
    function poolCounter() external view returns (uint256);

    function pools(uint256 _poolId)
        external
        view
        returns (
            string memory name,
            address poolAddress,
            address protocolToken,
            uint256 maxCapacity,
            uint256 basePremiumRatio
        );

    function poolRegistered(address) external view returns (bool);

    function dynamic(address) external view returns (bool);
}

interface IPriorityPool {
    function setCoverIndex(uint256 _newIndex) external;

    function minAssetRequirement() external view returns (uint256);

    function activeCovered() external view returns (uint256);
}

abstract contract ProtectionPoolDependencies {
    address public priorityPoolFactory;
    address public policyCenter;
    address public incidentReport;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface ProtectionPoolEventError {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event LiquidityProvided(
        uint256 usdcAmount,
        uint256 lpAmount,
        address sender
    );
    event LiquidityRemoved(
        uint256 lpAmount,
        uint256 usdcAmount,
        address sender
    );

    event LiquidityRemovedWhenClaimed(address pool, uint256 amount);

    event RewardUpdated(uint256 totalReward);

    event PriceUpdated(uint256 price);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error ProtectionPool__OnlyPolicyCenter();
    error ProtectionPool__ExceededTotalSupply();
    error ProtectionPool__OnlyPriorityPool();
    error ProtectionPool__NotEnoughLiquidity();
    error ProtectionPool__OnlyPriorityPoolOrPolicyCenter();
    error ProtectionPool__NotEnoughBalance();
    error ProtectionPool__NotAllowedToPause();

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract PausableWithoutContextUpgradeable is Initializable {
    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Paused");
        _;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function _pause(bool _p) internal virtual {
        _paused = _p;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

abstract contract FlashLoanPool is IERC3156FlashLender, Initializable {
    address public token;

    // 10000 = 100%
    uint256 public constant FEE = 10;

    event FlashLoanBorrowed(
        address indexed lender,
        address indexed borrower,
        address indexed stablecoin,
        uint256 amount,
        uint256 fee
    );

    function __FlashLoan__Init(address _usdc) internal onlyInitializing {
        token = _usdc;
    }

    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external override returns (bool) {
        require(_amount > 0, "Zero amount");

        uint256 fee = flashFee(_token, _amount);

        uint256 previousBalance = IERC20(_token).balanceOf(address(this));

        IERC20(_token).transfer(address(_receiver), _amount);
        require(
            _receiver.onFlashLoan(msg.sender, _token, _amount, fee, _data) ==
                keccak256("ERC3156FlashBorrower.onFlashLoan"),
            "IERC3156: Callback failed"
        );
        IERC20(_token).transferFrom(
            address(_receiver),
            address(this),
            _amount + fee
        );

        uint256 finalBalance = IERC20(_token).balanceOf(address(this));
        require(finalBalance >= previousBalance + fee, "Not enough pay back");

        emit FlashLoanBorrowed(
            address(this),
            address(_receiver),
            _token,
            _amount,
            fee
        );

        return true;
    }

    function flashFee(address _token, uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        require(_token == token, "Only usdc");
        return (_amount * FEE) / 10000;
    }

    function maxFlashLoan(address _token) external view returns (uint256) {
        require(_token == token, "only usdc");
        return IERC20(token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILBRouter {
    enum Version {
        V1,
        V2,
        V2_1
    }

    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function getSwapIn(
        address LBPair,
        uint128 amountOut,
        bool swapForY
    )
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(
        address LBPair,
        uint128 amountIn,
        bool swapForY
    )
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
  *******         **********     ***********     *****     ***********
  *      *        *              *                 *       *
  *        *      *              *                 *       *
  *         *     *              *                 *       *
  *         *     *              *                 *       *
  *         *     **********     *       *****     *       ***********
  *         *     *              *         *       *                 *
  *         *     *              *         *       *                 *
  *        *      *              *         *       *                 *
  *      *        *              *         *       *                 *
  *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

import "../util/OwnableWithoutContextUpgradeable.sol";

import "./ISwapRouter.sol";
import "./ILBRouter.sol";

pragma solidity ^0.8.13;

contract SwapHelper is OwnableWithoutContextUpgradeable {
    // Swap USDC to get protocol native tokens
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // Uniswap V3
    address public constant GMX = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address public constant GNS = 0x18c11FD286C5EC11c3b683Caa813B77f5163A122;
    address public constant WOM = 0x7B5EB3940021Ec0e8e463D5dBB4B7B09a89DDF96;
    address public constant LDO = 0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60;
    address public constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    // TraderJoe Liquidity Book V2_1
    address public constant JOE = 0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07;

    address public constant UNIV3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant JOEV21_ROUTER =
        0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30;

    // Fee rate in Uniswap V3
    uint256 public constant WETH_USDC_FEE = 500; // 0.05%
    uint256 public constant WETH_USDT_FEE = 500; // 0.05%

    uint256 public constant WOM_USDT_FEE = 3000;

    uint256 public constant GMX_WETH_FEE = 3000;
    uint256 public constant GNS_WETH_FEE = 3000;
    uint256 public constant LDO_WETH_FEE = 3000;
    uint256 public constant ARB_WETH_FEE = 500;

    // Router types:
    // 1: Uniswap V3
    // 2: Trader Joe V2.1
    mapping(address => uint256) public routerTypes;

    // Pool fees for those tokens that uses Uniswap V3
    // The pair may be token-USDC or token-USDT or token-WETH
    mapping(address => uint256) public poolFees;

    function initialize() public initializer {
        __Ownable_init();

        routerTypes[GMX] = 1;
        routerTypes[GNS] = 1;
        routerTypes[WOM] = 1;
        routerTypes[LDO] = 1;
        routerTypes[ARB] = 1;

        routerTypes[JOE] = 2;
    }

    function setRouterType(address _token, uint256 _type) external onlyOwner {
        routerTypes[_token] = _type;
    }

    function swap(address _token, uint256 _amount) external returns (uint256) {
        uint256 routerType = routerTypes[_token];

        if (routerType == 1) {
            return _univ3_swapExactTokensForTokens(_token, _amount);
        } else if (routerType == 2) {
            return _joev21_swapExactTokensForTokens(_token, _amount);
        } else revert("Wrong token");
    }

    function _univ3_swapExactTokensForTokens(
        address _token,
        uint256 _amount
    ) internal returns (uint256 amountOut) {
        if (
            IERC20(_token).allowance(address(this), UNIV3_ROUTER) < 1000000e18
        ) {
            IERC20(_token).approve(UNIV3_ROUTER, type(uint256).max);
        }

        bytes memory path = getUniV3Path(_token);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: path,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: 0
            });

        amountOut = ISwapRouter(UNIV3_ROUTER).exactInput(params);
    }

    function _getPairBinSteps(
        address _token
    ) internal pure returns (uint256[] memory pairBinSteps) {
        pairBinSteps = new uint256[](2);

        if (_token == JOE) {
            pairBinSteps[0] = 20; // JOE-ETH pair: 0x4b9bfeD1dD4E6780454b2B02213788f31FfBA74a 20bps V2_1
            pairBinSteps[1] = 50; // ETH-USDC pair: 0xb83783c9cb35f1b1A6338937F9BE3EBb36b46bfe 40bps V2_1
        } else revert("Wrong token");
    }

    function _getVersions(
        address _token
    ) internal pure returns (ILBRouter.Version[] memory versions) {
        versions = new ILBRouter.Version[](2);

        if (_token == JOE) {
            versions[0] = ILBRouter.Version.V2_1;
            versions[1] = ILBRouter.Version.V2_1;
        }
    }

    function _joev21_swapExactTokensForTokens(
        address _token,
        uint256 _amount
    ) internal returns (uint256 amountOut) {
        if (
            IERC20(_token).allowance(address(this), JOEV21_ROUTER) < 1000000e18
        ) {
            IERC20(_token).approve(JOEV21_ROUTER, type(uint256).max);
        }

        uint256[] memory pairBinSteps = _getPairBinSteps(_token);

        ILBRouter.Version[] memory versions = _getVersions(_token);

        IERC20[] memory tokenPath = new IERC20[](3);
        tokenPath[0] = IERC20(_token);
        tokenPath[1] = IERC20(WETH);
        tokenPath[2] = IERC20(USDC);

        ILBRouter.Path memory path = ILBRouter.Path({
            pairBinSteps: pairBinSteps,
            versions: versions,
            tokenPath: tokenPath
        });

        amountOut = ILBRouter(JOEV21_ROUTER).swapExactTokensForTokens(
            _amount,
            0,
            path,
            msg.sender,
            block.timestamp + 1
        );
    }

    function getUniV3Path(
        address _token
    ) public pure returns (bytes memory path) {
        if (_token == WOM) {
            path = abi.encodePacked(
                WOM,
                WOM_USDT_FEE,
                USDT,
                WETH_USDT_FEE,
                USDT
            );
        } else if (_token == GMX) {
            path = abi.encodePacked(
                GMX,
                GMX_WETH_FEE,
                WETH,
                WETH_USDC_FEE,
                USDC
            );
        } else if (_token == GNS) {
            path = abi.encodePacked(
                GNS,
                GNS_WETH_FEE,
                WETH,
                WETH_USDC_FEE,
                USDC
            );
        } else if (_token == LDO) {
            path = abi.encodePacked(
                LDO,
                LDO_WETH_FEE,
                WETH,
                WETH_USDC_FEE,
                USDC
            );
        } else if (_token == ARB) {
            path = abi.encodePacked(
                ARB,
                ARB_WETH_FEE,
                WETH,
                WETH_USDC_FEE,
                USDC
            );
        } else revert("Wrong token");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../../util/OwnableWithoutContextUpgradeable.sol";

import "../../util/SimpleIERC20.sol";

import "./TreasuryDependencies.sol";
import "./TreasuryEventError.sol";

/**
 * @notice Treasury Contract
 *
 *         Treasury will receive 5% of the premium income (usdc) from policyCenter.
 *         They are counted as different pools.
 *
 *         When a reporter gives a correct report (passed voting and executed),
 *         he will get 10% of the income of that project pool.
 *
 */
contract Treasury is
    TreasuryEventError,
    OwnableWithoutContextUpgradeable,
    TreasuryDependencies
{
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    uint256 public constant REPORTER_REWARD = 1000; // 10%

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    mapping(uint256 => uint256) public poolIncome;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(
        address _executor,
        address _policyCenter
    ) public initializer {
        __Ownable_init();

        executor = _executor;
        policyCenter = _policyCenter;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Reward the correct reporter
     *
     *         Part of the priority pool income will be given to the reporter
     *         Only called from executor when executing a report
     *
     * @param _poolId   Pool id
     * @param _reporter Reporter address
     */
    function rewardReporter(uint256 _poolId, address _reporter) external {
        if (msg.sender != executor) revert Treasury__OnlyExecutor();

        uint256 amount = (poolIncome[_poolId] * REPORTER_REWARD) / 10000;

        poolIncome[_poolId] -= amount;
        SimpleIERC20(USDC).transfer(_reporter, amount);

        emit ReporterRewarded(_reporter, amount);
    }

    /**
     * @notice Record when receiving new premium income
     *
     *         Only called from policy center
     *
     * @param _poolId Pool id
     * @param _amount Premium amount (usdc)
     */
    function premiumIncome(uint256 _poolId, uint256 _amount) external {
        if (msg.sender != policyCenter) revert Treasury__OnlyPolicyCenter();

        poolIncome[_poolId] += _amount;

        emit NewIncomeToTreasury(_poolId, _amount);
    }

    /**
     * @notice Claim usdc by the owner
     *
     * @param _amount Amount to claim
     */
    function claim(uint256 _amount) external onlyOwner {
        SimpleIERC20(USDC).transfer(owner(), _amount);

        emit ClaimedByOwner(_amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

abstract contract TreasuryDependencies {
    address public executor;

    address public policyCenter;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

abstract contract TreasuryEventError {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event ReporterRewarded(address indexed reporter, uint256 amount);

    event NewIncomeToTreasury(uint256 indexed poolId, uint256 amount);

    event ClaimedByOwner(uint256 amount);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error Treasury__OnlyExecutor();

    error Treasury__OnlyPolicyCenter();

    error Treasury__OnlyOwner();
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/ICoverRightTokenFactory.sol";
import "../../interfaces/ICoverRightToken.sol";
import "../../interfaces/IPriorityPool.sol";
import "../../interfaces/IPriorityPoolFactory.sol";

import "../../util/SimpleIERC20.sol";

/**
 * @notice Payout Pool
 *
 *         Every time there is a report passed, some assets will be moved to this pool
 *         It is stored as a Payout struct
 *         - amount       Total amount of this payout
 *         - remaining    Remaining amount
 *         - endTimestamp After this timestamp, no more claims
 *         - ratio        Max ratio of a user's crToken
 */
contract PayoutPool is Initializable {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    uint256 public constant SCALE = 1e12;

    uint256 public constant CLAIM_PERIOD = 30 days;

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Cover Right Token Factory
    address public crFactory;

    // Policy Center
    address public policyCenter;

    // Priority Pool Factory
    address public priorityPoolFactory;

    // About "ratio" and "coverIndex"
    // E.g. You have 1000 available crTokens
    //      There is a payout with ratio 1e11 and coverIndex 1000
    //      That means:
    //        - 10% of your crTokens can be used for claim (100 crTokens)
    //        - 1 crToken can be used to claim 0.1 USDC (get 10 USDC back)
    struct Payout {
        uint256 amount; // Total amount of this payment
        uint256 remaining; // Remaining amount
        uint256 endTiemstamp; // Claim period end timestamp
        uint256 ratio; // Ratio of your crTokens that can be claimed (SCALE = 1e12 = 100%)
        uint256 coverIndex;  // Index of the cover (ratio of the crTokens to USDC) (10000 = 100%)
        address priorityPool; // Which priority pool this payout belongs to
    }
    // Pool id => Generation => Payout
    // One pool & one generation has only one payout
    mapping(uint256 => mapping(uint256 => Payout)) public payouts;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event NewPayout(
        uint256 indexed _poolId,
        uint256 _generation,
        uint256 _amount,
        uint256 _ratio
    );

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error PayoutPool__OnlyPriorityPool();
    error PayoutPool__NotPolicyCenter();
    error PayoutPool__WrongCRToken();
    error PayoutPool__NoPayout();

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(
        address _policyCenter,
        address _crFactory,
        address _priorityPoolFactory
    ) public initializer {
        policyCenter = _policyCenter;
        crFactory = _crFactory;
        priorityPoolFactory = _priorityPoolFactory;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Only be called from one of the priority pools
    modifier onlyPriorityPool(uint256 _poolId) {
        (, address poolAddress, , , ) = IPriorityPoolFactory(
            priorityPoolFactory
        ).pools(_poolId);
        if (poolAddress != msg.sender) revert PayoutPool__OnlyPriorityPool();
        _;
    }

    // Only be called from policy center
    modifier onlyPolicyCenter() {
        if (msg.sender != policyCenter) revert PayoutPool__NotPolicyCenter();
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice New payout comes in
     *
     *         Only callable from one of the priority pools
     *
     *         After the pool's report is passed and executed,
     *         part of the assets will be moved to this pool.
     *
     *
     * @param _poolId       Pool Id
     * @param _generation   Generation of priority pool (start at 1)
     * @param _amount       Total amount to be claimed
     * @param _ratio        Payout ratio of this payout (users can only use part of their crTokens to claim)
     * @param _poolAddress  Address of priority pool
     */
    function newPayout(
        uint256 _poolId,
        uint256 _generation,
        uint256 _amount,
        uint256 _ratio,
        uint256 _coverIndex,
        address _poolAddress
    ) external onlyPriorityPool(_poolId) {
        Payout storage payout = payouts[_poolId][_generation];

        // Store the information
        payout.amount = _amount;
        payout.endTiemstamp = block.timestamp + CLAIM_PERIOD;
        payout.ratio = _ratio;
        payout.coverIndex = _coverIndex;
        payout.priorityPool = _poolAddress;

        emit NewPayout(_poolId, _generation, _amount, _ratio);
    }

    /**
     * @notice Claim payout for a user
     *
     *         Only callable from policy center
     *         Need provide certain crToken address and generation
     *
     * @param _user       User address
     * @param _crToken    Cover right token address
     * @param _poolId     Pool Id
     * @param _generation Generation of priority pool (started at 1)
     *
     * @return claimed               The actual amount transferred to the user
     * @return newGenerationCRAmount New generation crToken minted to the user
     */
    function claim(
        address _user,
        address _crToken,
        uint256 _poolId,
        uint256 _generation
    )
        external
        onlyPolicyCenter
        returns (uint256 claimed, uint256 newGenerationCRAmount)
    {
        Payout storage payout = payouts[_poolId][_generation];

        uint256 expiry = ICoverRightToken(_crToken).expiry();

        // Check the crToken address and generation matched
        bytes32 salt = keccak256(
            abi.encodePacked(_poolId, expiry, _generation)
        );
        if (ICoverRightTokenFactory(crFactory).saltToAddress(salt) != _crToken)
            revert PayoutPool__WrongCRToken();

        // Get claimable amount of crToken
        uint256 claimableBalance = ICoverRightToken(_crToken).getClaimableOf(
            _user
        );
        // Only part of the crToken can be used for claim
        uint256 claimable = (claimableBalance * payout.ratio) / SCALE;

        if (claimable == 0) revert PayoutPool__NoPayout();

        // Actual amount given to the user
        claimed = (claimable * payout.coverIndex) / 10000;

        // Reduce the active cover amount in priority pool
        (, address poolAddress, , , ) = IPriorityPoolFactory(
            priorityPoolFactory
        ).pools(_poolId);
        IPriorityPool(poolAddress).updateWhenClaimed(expiry, claimed);

        // Burn current crToken
        ICoverRightToken(_crToken).burn(
            _poolId,
            _user,
            // burns the users' crToken balance, not the payout amount,
            // since rest of the payout will be minted as a new generation token
            claimableBalance
        );

        SimpleIERC20(USDC).transfer(_user, claimed);

        // Amount of new generation cr token to be minted
        newGenerationCRAmount = claimableBalance - claimable;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface ICoverRightTokenFactory {
    function deployCRToken(
        string calldata _poolName,
        uint256 _poolId,
        string calldata _tokenName,
        uint256 _expiry,
        uint256 _generation
    ) external returns (address newCRTokenAddress);

    function deployed(bytes32 _salt) external view returns (bool);

    function saltToAddress(bytes32 _salt) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICoverRightToken {
    function expiry() external view returns (uint256);

    function getClaimableOf(address _user) external view returns (uint256);

    function mint(
        uint256 _poolId,
        address _user,
        uint256 _amount
    ) external;

    function burn(
        uint256 _poolId,
        address _user,
        uint256 _amount
    ) external;

    function generation() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IPriorityPool {
    //

    function lpTokenAddress(uint256 _generation)
        external
        view
        returns (address);

    function insuredToken() external view returns (address);

    function pausePriorityPool(bool _paused) external;

    function setCoverIndex(uint256 _newIndex) external;

    function minAssetRequirement() external view returns (uint256);

    function activeCovered() external view returns (uint256);

    function currentLPAddress() external view returns (address);

    function liquidatePool(uint256 amount) external;

    function generation() external view returns (uint256);

    function crTokenAddress(uint256 generation) external view returns (address);

    function poolInfo()
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function updateWhenBuy(
        uint256 _amount,
        uint256 _premium,
        uint256 _length,
        uint256 _timestampLength
    ) external;

    function stakedLiquidity(uint256 _amount, address _provider)
        external
        returns (address);

    function unstakedLiquidity(
        address _lpToken,
        uint256 _amount,
        address _provider
    ) external;

    function coverPrice(uint256 _amount, uint256 _length)
        external
        view
        returns (uint256, uint256);

    function maxCapacity() external view returns (uint256);

    function coverIndex() external view returns (uint256);

    function paused() external view returns (bool);

    function basePremiumRatio() external view returns (uint256);

    function updateWhenClaimed(uint256 expiry, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
  *******         **********     ***********     *****     ***********
  *      *        *              *                 *       *
  *        *      *              *                 *       *
  *         *     *              *                 *       *
  *         *     *              *                 *       *
  *         *     **********     *       *****     *       ***********
  *         *     *              *         *       *                 *
  *         *     *              *         *       *                 *
  *        *      *              *         *       *                 *
  *      *        *              *         *       *                 *
  *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "./PriorityPoolFactoryDependencies.sol";

import "../../util/OwnableWithoutContextUpgradeable.sol";
import "../../interfaces/ExternalTokenDependencies.sol";
import "./PriorityPoolFactoryEventError.sol";

// import "./PriorityPool.sol";

import "../../interfaces/IPriorityPool.sol";

/**
 * @title Insurance Pool Factory
 *
 * @author Eric Lee ([email protected])
 *
 * @notice This is the factory contract for deploying new insurance pools
 *         Each pool represents a project that has joined Degis Protocol Protection
 *
 *         Liquidity providers of Protection Pool can stake their LP tokens into priority pools
 *         Benefit:
 *             - Share the 45% part of the premium income (in native token form)
 *         Risk:
 *             - Will be liquidated first to pay for the claim amount
 *
 *
 */
contract PriorityPoolFactory is
    PriorityPoolFactoryEventError,
    OwnableWithoutContextUpgradeable,
    ExternalTokenDependencies,
    PriorityPoolFactoryDependencies
{
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    struct PoolInfo {
        string protocolName;
        address poolAddress;
        address protocolToken;
        uint256 maxCapacity; // max capacity ratio
        uint256 basePremiumRatio;
    }
    // poolId => Pool Information
    mapping(uint256 => PoolInfo) public pools;

    mapping(address => uint256) public poolAddressToId;

    uint256 public poolCounter;

    // Total max capacity
    uint256 public totalMaxCapacity;

    // Whether a pool is already dynamic
    mapping(address => bool) public dynamic;

    // Total dynamic pools
    uint256 public dynamicPoolCounter;

    // Record whether a protocol token or pool address has been registered
    mapping(address => bool) public poolRegistered;
    mapping(address => bool) public tokenRegistered;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(
        address _deg,
        address _veDeg,
        address _protectionPool
    ) public initializer {
        __ExternalToken__Init(_deg, _veDeg);
        __Ownable_init();

        protectionPool = _protectionPool;

        poolRegistered[_protectionPool] = true;
        tokenRegistered[USDC] = true;

        // Protection pool as pool 0
        pools[0] = PoolInfo("ProtectionPool", _protectionPool, USDC, 0, 0);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    modifier onlyPriorityPool() {
        if (!poolRegistered[msg.sender])
            revert PriorityPoolFactory__OnlyPriorityPool();
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the pool address list
     *
     * @return List of pool addresses
     */
    function getPoolAddressList() external view returns (address[] memory) {
        uint256 poolAmount = poolCounter + 1;

        address[] memory list = new address[](poolAmount);

        for (uint256 i; i < poolAmount; ) {
            list[i] = pools[i].poolAddress;

            unchecked {
                ++i;
            }
        }

        return list;
    }

    /**
     * @notice Get the pool information by pool id
     *
     * @param _poolId Pool id
     */
    function getPoolInfo(uint256 _poolId)
        public
        view
        returns (PoolInfo memory)
    {
        return pools[_poolId];
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function setPolicyCenter(address _policyCenter) external onlyOwner {
        policyCenter = _policyCenter;
    }

    function setWeightedFarmingPool(address _weightedFarmingPool)
        external
        onlyOwner
    {
        weightedFarmingPool = _weightedFarmingPool;
    }

    function setProtectionPool(address _protectionPool) external onlyOwner {
        protectionPool = _protectionPool;
    }

    function setExecutor(address _executor) external onlyOwner {
        executor = _executor;
    }

    function setIncidentReport(address _incidentReport) external onlyOwner {
        incidentReport = _incidentReport;
    }

    function setPriorityPoolDeployer(address _priorityPoolDeployer)
        external
        onlyOwner
    {
        priorityPoolDeployer = _priorityPoolDeployer;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Create a new priority pool
     *         Called by executor when an onboard proposal has passed
     *
     * @param _name             Name of the protocol
     * @param _protocolToken    Address of the token used for the protocol
     * @param _maxCapacity      Maximum capacity of the pool
     * @param _basePremiumRatio Initial policy price per usdc
     *
     * @return address Address of the new insurance pool
     */
    function deployPool(
        string calldata _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _basePremiumRatio
    ) public returns (address) {
        if (msg.sender != owner() && msg.sender != executor)
            revert PriorityPoolFactory__OnlyOwnerOrExecutor();
        if (tokenRegistered[_protocolToken])
            revert PriorityPoolFactory__TokenAlreadyRegistered();

        // Add new pool max capacity to sum of max capacities
        totalMaxCapacity += _maxCapacity;

        uint256 currentPoolId = ++poolCounter;

        address newAddress = IPriorityPoolDeployer(priorityPoolDeployer)
            .getPoolAddress(
                currentPoolId,
                _name,
                _protocolToken,
                _maxCapacity,
                _basePremiumRatio
            );
        poolRegistered[newAddress] = true;

        address newPoolAddress = IPriorityPoolDeployer(priorityPoolDeployer)
            .deployPool(
                currentPoolId,
                _name,
                _protocolToken,
                _maxCapacity,
                _basePremiumRatio
            );

        pools[currentPoolId] = PoolInfo(
            _name,
            newPoolAddress,
            _protocolToken,
            _maxCapacity,
            _basePremiumRatio
        );

        tokenRegistered[_protocolToken] = true;
        poolAddressToId[newPoolAddress] = currentPoolId;

        // Store pool information in Policy Center
        IPolicyCenter(policyCenter).storePoolInformation(
            newPoolAddress,
            _protocolToken,
            currentPoolId
        );

        // Add reward token in farming pool
        IWeightedFarmingPool(weightedFarmingPool).addPool(_protocolToken);

        emit PoolCreated(
            currentPoolId,
            newPoolAddress,
            _name,
            _protocolToken,
            _maxCapacity,
            _basePremiumRatio
        );

        return newPoolAddress;
    }

    /**
     * @notice Update a priority pool status to dynamic
     *         Only sent from priority pool
     *         "Dynamic" means:
     *                  The priority pool will be counted in the dynamic premium formula
     *
     * @param _poolId Pool id
     */
    function updateDynamicPool(uint256 _poolId) external onlyPriorityPool {
        address poolAddress = pools[_poolId].poolAddress;
        if (dynamic[poolAddress])
            revert PriorityPoolFactory__AlreadyDynamicPool();

        dynamic[poolAddress] = true;

        unchecked {
            ++dynamicPoolCounter;
        }

        emit DynamicPoolUpdate(_poolId, poolAddress, dynamicPoolCounter);
    }

    /**
     * @notice Update max capacity from a priority pool
     */
    function updateMaxCapacity(bool _isUp, uint256 _diff)
        external
        onlyPriorityPool
    {
        if (_isUp) {
            totalMaxCapacity += _diff;
        } else totalMaxCapacity -= _diff;

        emit MaxCapacityUpdated(totalMaxCapacity);
    }

    function pausePriorityPool(uint256 _poolId, bool _paused) external {
        if (msg.sender != incidentReport && msg.sender != executor)
            revert PriorityPoolFactory__OnlyIncidentReportOrExecutor();

        IPriorityPool(pools[_poolId].poolAddress).pausePriorityPool(_paused);

        IProtectionPool(protectionPool).pauseProtectionPool(_paused);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IPolicyCenter {
    function storePoolInformation(
        address _pool,
        address _token,
        uint256 _poolId
    ) external;
}

interface IWeightedFarmingPool {
    function addPool(address _token) external;

    function addToken(
        uint256 _id,
        address _token,
        uint256 _weight
    ) external;

    function updateRewardSpeed(
        uint256 _id,
        uint256 _newSpeed,
        uint256[] memory _years,
        uint256[] memory _months
    ) external;

    function updateWeight(
        uint256 _id,
        address _token,
        uint256 _newWeight
    ) external;
}

interface IProtectionPool {
    function getTotalActiveCovered() external view returns (uint256);

    function getLatestPrice() external returns (uint256);

    function removedLiquidity(uint256 _amount, address _provider)
        external
        returns (uint256);

    function removedLiquidityWhenClaimed(uint256 _amount, address _to) external;

    function pauseProtectionPool(bool _paused) external;

    function stakedSupply() external view returns (uint256);
}

interface IPriorityPoolDeployer {
    function deployPool(
        uint256 poolId,
        string calldata _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _basePremiumRatio
    ) external returns (address);

    function getPoolAddress(
        uint256 poolId,
        string calldata _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _basePremiumRatio
    ) external view returns (address);
}

abstract contract PriorityPoolFactoryDependencies {
    // Priority Pools need access to executor address
    address public executor;
    address public policyCenter;
    address public protectionPool;
    address public incidentReport;
    address public weightedFarmingPool;

    address public priorityPoolDeployer;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface PriorityPoolFactoryEventError {

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event PoolCreated(
        uint256 poolId,
        address poolAddress,
        string protocolName,
        address protocolToken,
        uint256 maxCapacity,
        uint256 basePremiumRatio
    );

    event DynamicPoolUpdate(
        uint256 poolId,
        address pool,
        uint256 dynamicPoolCounter
    );

    event MaxCapacityUpdated(uint256 totalMaxCapacity);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error PriorityPoolFactory__OnlyExecutor(); // 5900a8a9
    error PriorityPoolFactory__OnlyPolicyCenter(); // b4e0f8d9
    error PriorityPoolFactory__OnlyOwnerOrExecutor(); // 6adaa0f9a
    error PriorityPoolFactory__OnlyPriorityPool(); // 3f193ee4
    error PriorityPoolFactory__OnlyIncidentReportOrExecutor(); // ae1aa57a
    error PriorityPoolFactory__PoolNotRegistered(); // 76213a28
    error PriorityPoolFactory__TokenAlreadyRegistered(); // 45d3e1f8
    error PriorityPoolFactory__AlreadyDynamicPool(); // 34c8f8b9
    error PriorityPoolFactory__NotOwnerOrFactory(); // 8bc3f382
    error PriorityPoolFactory__WrongLPToken(); // 00de38c2
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "../../interfaces/IPriorityPool.sol";
import "../../interfaces/IProtectionPool.sol";
import "../../interfaces/IPriorityPoolFactory.sol";
import "../../interfaces/ICoverRightToken.sol";
import "../../interfaces/ICoverRightTokenFactory.sol";
import "../../interfaces/IPayoutPool.sol";
import "../../interfaces/IWeightedFarmingPool.sol";
import "../../interfaces/ITreasury.sol";
import "../../interfaces/IExchange.sol";
import "../../interfaces/IERC20Decimals.sol";

abstract contract PolicyCenterDependencies {
    // Max cover length
    // Different priority pools have different max lengths
    // This max length is the maximum of all pools
    // There will also be a check in each pool
    uint256 internal constant MAX_COVER_LENGTH = 3;

    // 10000 = 100%
    // Priority pool 45%
    uint256 internal constant PREMIUM_TO_PRIORITY = 4500;
    // Protection pool 50%
    uint256 internal constant PREMIUM_TO_PROTECTION = 5000;
    // Treasury 5%
    uint256 internal constant PREMIUM_TO_TREASURY = 500;

    // Swap slippage
    // TODO: Slippage tolerance parameter 10000 as 100%
    uint256 internal constant SLIPPAGE = 100;

    address public protectionPool;
    address public priceGetter;
    address public priorityPoolFactory;
    address public coverRightTokenFactory;
    address public weightedFarmingPool;
    address public exchange;
    address public payoutPool;
    address public treasury;

    address public dexPriceGetter;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IProtectionPool {
    function pauseProtectionPool(bool _paused) external;

    function providedLiquidity(uint256 _amount, address _provider) external;

    function removedLiquidity(uint256 _amount, address _provider)
        external
        returns (uint256);

    function getTotalCovered() external view returns (uint256);

    function getTotalActiveCovered() external view returns (uint256);

    function updateWhenBuy() external;

    function removedLiquidityWhenClaimed(uint256 _amount, address _to) external;

    function getLatestPrice() external returns (uint256);

    function updateStakedSupply(bool isStake, uint256 amount) external;

    function stakedSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IPayoutPool {
    function CLAIM_PERIOD() external view returns (uint256);

    function SCALE() external view returns (uint256);

    function claim(
        address _user,
        address _crToken,
        uint256 _poolId,
        uint256 _generation
    ) external returns (uint256 claimed, uint256 newGenerationCRAmount);

    function crFactory() external view returns (address);

    function newPayout(
        uint256 _poolId,
        uint256 _generation,
        uint256 _amount,
        uint256 _ratio,
        address _poolAddress
    ) external;

    function payoutCounter() external view returns (uint256);

    function payouts(uint256)
        external
        view
        returns (
            uint256 amount,
            uint256 remaining,
            uint256 endTiemstamp,
            uint256 ratio,
            address priorityPoolAddress
        );

    function policyCenter() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IWeightedFarmingPool {
    function addPool(address _token) external;

    function addToken(
        uint256 _id,
        address _token,
        uint256 _weight
    ) external;

    function updateRewardSpeed(
        uint256 _id,
        uint256 _newSpeed,
        uint256[] memory _years,
        uint256[] memory _months
    ) external;

    function depositFromPolicyCenter(
        uint256 _id,
        address _token,
        uint256 _amount,
        address _user
    ) external;

    function withdrawFromPolicyCenter(
        uint256 _id,
        address _token,
        uint256 _amount,
        address _user
    ) external;

    function updateWeight(
        uint256 _id,
        address _token,
        uint256 _newWeight
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IExchange {
    // TraderJoe Interfaces
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);
}

interface IJoeLiquidityBook {
    // TraderJoe Liquidity Book Interfaces
    function getSwapOut(
        address pair,
        uint256 amountIn,
        bool swapForY
    ) external view returns (uint256 amountOut, uint256 feesIn);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
  *******         **********     ***********     *****     ***********
  *      *        *              *                 *       *
  *        *      *              *                 *       *
  *         *     *              *                 *       *
  *         *     *              *                 *       *
  *         *     **********     *       *****     *       ***********
  *         *     *              *         *       *                 *
  *         *     *              *         *       *                 *
  *        *      *              *         *       *                 *
  *      *        *              *         *       *                 *
  *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "../interfaces/ExternalTokenDependencies.sol";
import "./interfaces/PolicyCenterEventError.sol";
import "./interfaces/PolicyCenterDependencies.sol";

import "../util/OwnableWithoutContextUpgradeable.sol";

import "../interfaces/IPriceGetter.sol";

import "../libraries/DateTime.sol";
import "../libraries/StringUtils.sol";
import "../libraries/SimpleSafeERC20.sol";

import "../swapHelper/ISwapHelper.sol";

/**
 * @title Policy Center
 *
 * @author Eric Lee ([email protected]) & Primata ([email protected])
 *
 * @notice This is the policy center for degis Protocol Protection
 *         Users can buy policies and get payoff here
 *         Sellers can provide liquidity and choose the pools to cover
 *
 */
contract PolicyCenter is
    PolicyCenterEventError,
    OwnableWithoutContextUpgradeable,
    ExternalTokenDependencies,
    PolicyCenterDependencies
{
    using SimpleSafeERC20 for SimpleIERC20;
    using StringUtils for uint256;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    // Pool Id => Priority Pool Address
    // Updated once pools are deployed
    // Protection Pool is pool 0
    mapping(uint256 => address) public priorityPools;

    // Pool Id => Pool Native Token Address
    mapping(uint256 => address) public tokenByPoolId;

    // Protocol token => Oracle type
    // 0: Default as chainlink oracle
    // 1: Dex oracle by traderJoe
    mapping(address => uint256) public oracleType;

    // Protocol token => Exchange router address
    // Some tokens use Joe-V1, some use Joe-LiquidityBook
    mapping(address => address) public exchangeByToken;

    address public swapHelper;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(
        address _deg,
        address _veDeg,
        address _protectionPool
    ) public initializer {
        __Ownable_init();
        __ExternalToken__Init(_deg, _veDeg);

        // Peotection pool as pool 0 and with usdc token
        priorityPools[0] = _protectionPool;
        tokenByPoolId[0] = USDC;

        protectionPool = _protectionPool;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Whether the pool exists
     */
    modifier poolExists(uint256 _poolId) {
        if (_poolId == 0 || priorityPools[_poolId] == address(0))
            revert PolicyCenter__NonExistentPool();
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Returns the current LP address for a Pool ID
     *
     *         "Current" means the LP address that is currently being used
     *         Because each priority pool may have several generations of LP tokens
     *         Once reported and paid out, the LP generation will be updated
     *
     * @param _poolId Priority Pool ID
     *
     * @return lpAddress Current generation LP token address
     */
    function currentLPAddress(
        uint256 _poolId
    ) external view returns (address lpAddress) {
        lpAddress = IPriorityPool(priorityPools[_poolId]).currentLPAddress();
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function setExchange(address _exchange) external onlyOwner {
        exchange = _exchange;
    }

    function setPriceGetter(address _priceGetter) external onlyOwner {
        priceGetter = _priceGetter;
    }

    function setProtectionPool(address _protectionPool) external onlyOwner {
        protectionPool = _protectionPool;
    }

    function setWeightedFarmingPool(
        address _weightedFarmingPool
    ) external onlyOwner {
        weightedFarmingPool = _weightedFarmingPool;
    }

    function setCoverRightTokenFactory(
        address _coverRightTokenFactory
    ) external onlyOwner {
        coverRightTokenFactory = _coverRightTokenFactory;
    }

    function setPriorityPoolFactory(
        address _priorityPoolFactory
    ) external onlyOwner {
        priorityPoolFactory = _priorityPoolFactory;
    }

    function setPayoutPool(address _payoutPool) external onlyOwner {
        payoutPool = _payoutPool;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setDexPriceGetter(address _dexPriceGetter) external onlyOwner {
        dexPriceGetter = _dexPriceGetter;
    }

    function setSwapHelper(address _swapHelper) external onlyOwner {
        swapHelper = _swapHelper;
    }

    function setOracleType(address _token, uint256 _type) external onlyOwner {
        require(_type < 2, "Wrong type");
        oracleType[_token] = _type;
    }

    function setExchangeByToken(
        address _token,
        address _exchange
    ) external onlyOwner {
        exchangeByToken[_token] = _exchange;
    }

    /**
     * @notice Approve the exchange to swap tokens
     *
     * @param _token Address of the approved token
     */
    function approvePoolToken(address _token) external onlyOwner {
        _approvePoolToken(_token);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Buy new cover for a given pool
     *
     *         Select a pool with parameter "poolId"
     *         Cover amount is in usdc and duration is in month
     *         The premium ratio may be dynamic so "maxPayment" is similar to "slippage"
     *
     * @param _poolId        Pool id
     * @param _coverAmount   Amount to cover
     * @param _coverDuration Cover duration in month (1 ~ 3)
     * @param _maxPayment    Maximum payment user can accept
     *
     * @return crToken CR token address
     */
    function buyCover(
        uint256 _poolId,
        uint256 _coverAmount,
        uint256 _coverDuration,
        uint256 _maxPayment
    ) external poolExists(_poolId) returns (address) {
        if (!_withinLength(_coverDuration)) revert PolicyCenter__BadLength();

        _checkCapacity(_poolId, _coverAmount);

        // Premium in USD and duration in second
        (uint256 premium, uint256 timestampDuration) = _getCoverPrice(
            _poolId,
            _coverAmount,
            _coverDuration
        );
        // Check if premium cost is within limits given by user
        if (premium > _maxPayment) revert PolicyCenter__PremiumTooHigh();

        // Mint cover right tokens to buyer
        // CR token has different months and generations
        address crToken = _checkCRToken(_poolId, _coverDuration);
        ICoverRightToken(crToken).mint(_poolId, msg.sender, _coverAmount);

        // Split the premium income and update the pool status
        (
            uint256 premiumToPriorityPool,
            ,
            uint256 premiumToTreasury
        ) = _splitPremium(_poolId, premium);

        IProtectionPool(protectionPool).updateWhenBuy();
        IPriorityPool(priorityPools[_poolId]).updateWhenBuy(
            _coverAmount,
            premiumToPriorityPool,
            _coverDuration,
            timestampDuration
        );
        ITreasury(treasury).premiumIncome(_poolId, premiumToTreasury);

        emit CoverBought(
            msg.sender,
            _poolId,
            _coverDuration,
            _coverAmount,
            premium
        );

        return crToken;
    }

    /**
     * @notice Provide liquidity to Protection Pool
     *
     * @param _amount Amount of liquidity (usdc) to provide
     */
    function provideLiquidity(uint256 _amount) external {
        if (_amount == 0) revert PolicyCenter__ZeroAmount();

        // Mint PRO-LP tokens and transfer usdc
        IProtectionPool(protectionPool).providedLiquidity(_amount, msg.sender);
        SimpleIERC20(USDC).transferFrom(msg.sender, protectionPool, _amount);

        emit LiquidityProvided(msg.sender, _amount);
    }

    /**
     * @notice Stake Protection Pool LP (PRO-LP) into priority pools
     *         And automatically stake the PRI-LP tokens into weighted farming pool
     *         With this function, no need for approval of PRI-LP tokens
     *
     *         If you want to hold the PRI-LP tokens for other usage
     *         Call "stakeLiquidityWithoutFarming"
     *
     * @param _poolId Pool id
     * @param _amount Amount of PRO-LP tokens to stake
     */
    function stakeLiquidity(
        uint256 _poolId,
        uint256 _amount
    ) public poolExists(_poolId) {
        if (_amount == 0) revert PolicyCenter__ZeroAmount();

        address pool = priorityPools[_poolId];

        // Update status and mint Prority Pool LP tokens
        // Directly mint pri-lp tokens to policy center
        // And send the PRI-LP tokens to weighted farming pool
        // No need for approval
        address lpToken = IPriorityPool(pool).stakedLiquidity(
            _amount,
            address(this)
        );
        SimpleIERC20(protectionPool).transferFrom(msg.sender, pool, _amount);
        IProtectionPool(protectionPool).updateStakedSupply(true, _amount);

        IWeightedFarmingPool(weightedFarmingPool).depositFromPolicyCenter(
            _poolId,
            lpToken,
            _amount,
            msg.sender
        );
        SimpleIERC20(lpToken).transfer(weightedFarmingPool, _amount);

        emit LiquidityStaked(msg.sender, _poolId, _amount);
    }

    /**
     * @notice Stake liquidity to priority pool without depositing into farming
     *
     * @param _poolId Pool id
     * @param _amount Amount of PRO-LP amount
     */
    function stakeLiquidityWithoutFarming(
        uint256 _poolId,
        uint256 _amount
    ) public poolExists(_poolId) {
        if (_amount == 0) revert PolicyCenter__ZeroAmount();

        address pool = priorityPools[_poolId];

        // Mint PRI-LP tokens to the user directly
        IPriorityPool(pool).stakedLiquidity(_amount, msg.sender);
        SimpleIERC20(protectionPool).transferFrom(msg.sender, pool, _amount);

        IProtectionPool(protectionPool).updateStakedSupply(true, _amount);

        emit LiquidityStakedWithoutFarming(msg.sender, _poolId, _amount);
    }

    /**
     * @notice Unstake Protection Pool LP from priority pools
     *         There may be different generations of priority lp tokens
     *
     *         This function will first remove the PRI-LP token from farming pool
     *         Ensure that your PRI-LP tokens are inside the farming pool
     *         If the PRI-LP tokens are in your own wallet, use "unstakeLiquidityWithoutFarming"
     *
     * @param _poolId     Pool id
     * @param _priorityLP Priority lp token address to withdraw
     * @param _amount     Amount of LP(priority lp) tokens to withdraw
     */
    function unstakeLiquidity(
        uint256 _poolId,
        address _priorityLP,
        uint256 _amount
    ) public poolExists(_poolId) {
        if (_amount == 0) revert PolicyCenter__ZeroAmount();

        // First remove the PRI-LP token from weighted farming pool
        IWeightedFarmingPool(weightedFarmingPool).withdrawFromPolicyCenter(
            _poolId,
            _priorityLP,
            _amount,
            msg.sender
        );

        // Burn PRI-LP tokens and give back PRO-LP tokens
        IPriorityPool(priorityPools[_poolId]).unstakedLiquidity(
            _priorityLP,
            _amount,
            msg.sender
        );

        IProtectionPool(protectionPool).updateStakedSupply(false, _amount);

        emit LiquidityUnstaked(msg.sender, _poolId, _priorityLP, _amount);
    }

    /**
     * @notice Unstake liquidity without removing PRI-LP from farming
     *
     * @param _poolId     Pool id
     * @param _priorityLP PRI-LP token address
     * @param _amount     PRI-LP token amount to remove
     */
    function unstakeLiquidityWithoutFarming(
        uint256 _poolId,
        address _priorityLP,
        uint256 _amount
    ) external poolExists(_poolId) {
        if (_amount == 0) revert PolicyCenter__ZeroAmount();

        IPriorityPool(priorityPools[_poolId]).unstakedLiquidity(
            _priorityLP,
            _amount,
            msg.sender
        );

        IProtectionPool(protectionPool).updateStakedSupply(false, _amount);

        emit LiquidityUnstakedWithoutFarming(
            msg.sender,
            _poolId,
            _priorityLP,
            _amount
        );
    }

    /**
     * @notice Remove liquidity from protection pool
     *
     * @param _amount Amount of liquidity to provide
     */
    function removeLiquidity(uint256 _amount) external {
        if (_amount == 0) revert PolicyCenter__ZeroAmount();

        IProtectionPool(protectionPool).removedLiquidity(_amount, msg.sender);

        emit LiquidityRemoved(msg.sender, _amount);
    }

    /**
     * @notice Claim payout
     *         Need to use a specific crToken address as parameter
     *
     * @param _poolId     Pool id
     * @param _crToken    Cover right token address
     * @param _generation Generation of the priority pool
     */
    function claimPayout(
        uint256 _poolId,
        address _crToken,
        uint256 _generation
    ) public poolExists(_poolId) {
        (string memory poolName, , , , ) = IPriorityPoolFactory(
            priorityPoolFactory
        ).pools(_poolId);

        // Claim payout from payout pool
        // Get the actual claimed amount and new generation cr token to be minted
        (uint256 claimed, uint256 newGenerationCRAmount) = IPayoutPool(
            payoutPool
        ).claim(msg.sender, _crToken, _poolId, _generation);

        emit PayoutClaimed(msg.sender, claimed);

        // Check if the new generation crToken has been deployed
        // If so, get the address
        // If not, deploy the new generation cr token
        if (newGenerationCRAmount > 0) {
            uint256 expiry = ICoverRightToken(_crToken).expiry();

            address newCRToken = _checkNewCRToken(
                _poolId,
                poolName,
                expiry,
                ++_generation
            );

            ICoverRightToken(newCRToken).mint(
                _poolId,
                msg.sender,
                newGenerationCRAmount
            );
        }
    }

    /**
     * @notice Store new pool information
     *
     * @param _pool   Address of the priority pool
     * @param _token  Address of the priority pool's native token
     * @param _poolId Pool id
     */
    function storePoolInformation(
        address _pool,
        address _token,
        uint256 _poolId
    ) external {
        if (msg.sender != priorityPoolFactory)
            revert PolicyCenter__OnlyPriorityPoolFactory();

        // Should never change the protection pool information
        assert(_poolId > 0);

        tokenByPoolId[_poolId] = _token;
        priorityPools[_poolId] = _pool;

        _approvePoolToken(_token);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Swap tokens to USDC
     *
     * @param _fromToken Token address to swap from
     * @param _amount    Amount of token to swap from
     *
     * @return received Actual usdc amount received
     */
    function _swapTokens(
        address _fromToken,
        uint256 _amount
    ) internal returns (uint256 received) {
        SimpleIERC20(_fromToken).transfer(swapHelper, _amount);
        received = ISwapHelper(swapHelper).swap(_fromToken, _amount);

        emit PremiumSwapped(_fromToken, _amount, received);
    }

    /**
     * @notice Check the cover length
     *
     * @param _length Length to check (in month)
     *
     * @return withinLength Whether the cover is within the length
     */
    function _withinLength(uint256 _length) internal pure returns (bool) {
        return _length > 0 && _length <= MAX_COVER_LENGTH;
    }

    /**
     * @notice Check cover right tokens
     *         If the crToken does not exist, it will be deployed here
     *
     * @param _poolId        Pool id
     * @param _coverDuration Cover length in month
     *
     * @return crToken Cover right token address
     */
    function _checkCRToken(
        uint256 _poolId,
        uint256 _coverDuration
    ) internal returns (address crToken) {
        // Get the expiry timestamp
        (uint256 expiry, uint256 year, uint256 month) = DateTimeLibrary
            ._getExpiry(block.timestamp, _coverDuration);

        (
            string memory poolName,
            address poolAddress,
            ,
            ,

        ) = IPriorityPoolFactory(priorityPoolFactory).pools(_poolId);

        uint256 generation = IPriorityPool(poolAddress).generation();

        crToken = _getCRTokenAddress(_poolId, expiry, generation);
        if (crToken == address(0)) {
            // CR-JOE-2022-1-G1
            string memory tokenName = string.concat(
                "CR-",
                poolName,
                "-",
                year._toString(),
                "-",
                month._toString(),
                "-G",
                generation._toString()
            );

            crToken = ICoverRightTokenFactory(coverRightTokenFactory)
                .deployCRToken(
                    poolName,
                    _poolId,
                    tokenName,
                    expiry,
                    generation
                );
        }
    }

    /**
     * @notice Check whether need to deploy new cr token
     *
     * @param _poolId        Pool id
     * @param _poolName      Pool name
     * @param _expiry        Expiry timestamp of the cr token
     * @param _newGeneration New generation of the cr token
     *
     * @return newCRToken New cover right token address
     */
    function _checkNewCRToken(
        uint256 _poolId,
        string memory _poolName,
        uint256 _expiry,
        uint256 _newGeneration
    ) internal returns (address newCRToken) {
        (uint256 year, uint256 month, ) = DateTimeLibrary.timestampToDate(
            _expiry
        );

        // Check the cr token exist
        newCRToken = _getCRTokenAddress(_poolId, _expiry, _newGeneration);

        // If cr token not exists, deploy it
        if (newCRToken == address(0)) {
            // CR-JOE-2022-1-G1
            string memory tokenName = string.concat(
                "CR-",
                _poolName,
                "-",
                year._toString(),
                "-",
                month._toString(),
                "-G",
                _newGeneration._toString()
            );

            newCRToken = ICoverRightTokenFactory(coverRightTokenFactory)
                .deployCRToken(
                    _poolName,
                    _poolId,
                    tokenName,
                    _expiry,
                    _newGeneration
                );
        }
    }

    /**
     * @notice Get cover right token address
     *         The address is determined by poolId and expiry (last second of each month)
     *         If token not exist, it will return zero address
     *
     * @param _poolId     Pool id
     * @param _expiry     Expiry timestamp
     * @param _generation Generation of the priority pool
     *
     * @return crToken Cover right token address
     */
    function _getCRTokenAddress(
        uint256 _poolId,
        uint256 _expiry,
        uint256 _generation
    ) internal view returns (address) {
        bytes32 salt = keccak256(
            abi.encodePacked(_poolId, _expiry, _generation)
        );

        return
            ICoverRightTokenFactory(coverRightTokenFactory).saltToAddress(salt);
    }

    /**
     * @notice Get native token amount to pay
     *
     * @param _premium Premium in USD
     * @param _token   Native token address
     *
     * @return premiumInNativeToken Premium calculated in native token
     */
    function _getNativeTokenAmount(
        uint256 _premium,
        address _token
    ) internal returns (uint256 premiumInNativeToken) {
        // Price in 18 decimals
        uint256 price;
        if (oracleType[_token] == 0) {
            // By default use chainlink
            price = IPriceGetter(priceGetter).getLatestPrice(_token);
        } else if (oracleType[_token] == 1) {
            // If no chainlink oracle, use dex price getter
            price = IPriceGetter(dexPriceGetter).getLatestPrice(_token);
        } else revert("Wrong oracle type");

        // @audit Fix decimal for native tokens
        // Check the real decimal diff
        uint256 decimalDiff = IERC20Decimals(_token).decimals() - 6;
        premiumInNativeToken = (_premium * 1e18 * (10 ** decimalDiff)) / price;

        // Pay native tokens
        SimpleIERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            premiumInNativeToken
        );
    }

    /**
     * @notice Split premium for a pool
     *         To priority pool is paid in native token
     *         To protection pool and treasury is paid in usdc
     *
     * @param _poolId       Pool id
     * @param _premiumInUSD Premium in USD
     *
     * @return toPriority   Premium to priority pool
     * @return toProtection Premium to protection pool
     * @return toTreasury   Premium to treasury
     */
    function _splitPremium(
        uint256 _poolId,
        uint256 _premiumInUSD
    )
        internal
        returns (uint256 toPriority, uint256 toProtection, uint256 toTreasury)
    {
        if (_premiumInUSD == 0) revert PolicyCenter__ZeroPremium();

        address nativeToken = tokenByPoolId[_poolId];

        // Premium in project native token (paid in internal function)
        uint256 premiumInNativeToken = _getNativeTokenAmount(
            _premiumInUSD,
            nativeToken
        );

        // Native tokens to Priority pool
        toPriority = (premiumInNativeToken * PREMIUM_TO_PRIORITY) / 10000;

        // Swap native tokens to usdc
        // Except for amount to priority pool, remaining is distributed in usdc
        uint256 amountToSwap = premiumInNativeToken - toPriority;
        // USDC amount received
        uint256 amountReceived = _swapTokens(nativeToken, amountToSwap);

        // USDC to Protection Pool
        toProtection =
            (amountReceived * PREMIUM_TO_PROTECTION) /
            (PREMIUM_TO_PROTECTION + PREMIUM_TO_TREASURY);
        // USDC to Treasury
        toTreasury = amountReceived - toProtection;

        emit PremiumSplitted(toPriority, toProtection, toTreasury);

        // @audit Add real transfer
        // Transfer tokens to different pools
        SimpleIERC20(nativeToken).transfer(weightedFarmingPool, toPriority);
        SimpleIERC20(USDC).transfer(protectionPool, toProtection);
        SimpleIERC20(USDC).transfer(treasury, toTreasury);
    }

    /**
     * @notice Approve a pool token for the exchange
     *
     * @param _token Token address
     */
    function _approvePoolToken(address _token) internal {
        address router = exchangeByToken[_token];
        if (router == address(0)) revert PolicyCenter__NoExchange();
        // approve exchange to swap policy center tokens for deg
        SimpleIERC20(_token).approve(router, type(uint256).max);
    }

    /**
     * @notice Get cover price from insurance pool
     *
     * @param _poolId        Pool id
     * @param _coverAmount   Cover amount (usdc)
     * @param _coverDuration Cover length in months (1,2,3)
     */
    function _getCoverPrice(
        uint256 _poolId,
        uint256 _coverAmount,
        uint256 _coverDuration
    ) internal view returns (uint256 price, uint256 timestampDuration) {
        (price, timestampDuration) = IPriorityPool(priorityPools[_poolId])
            .coverPrice(_coverAmount, _coverDuration);
    }

    /**
     * @notice Check priority pool capacity
     *
     * @param _poolId      Pool id
     * @param _coverAmount Amount (usdc) to cover
     */
    function _checkCapacity(
        uint256 _poolId,
        uint256 _coverAmount
    ) internal view {
        IPriorityPool pool = IPriorityPool(priorityPools[_poolId]);
        uint256 maxCapacityAmount = (SimpleIERC20(USDC).balanceOf(
            address(protectionPool)
        ) * pool.maxCapacity()) / 10000;

        if (maxCapacityAmount < _coverAmount + pool.activeCovered())
            revert PolicyCenter__InsufficientCapacity();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface PolicyCenterEventError {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event CoverBought(
        address indexed buyer,
        uint256 indexed poolId,
        uint256 coverDuration,
        uint256 coverAmount,
        uint256 premiumInUSDC
    );

    event LiquidityProvided(address indexed user, uint256 amount);

    event LiquidityStaked(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event LiquidityStakedWithoutFarming(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event LiquidityUnstaked(
        address indexed user,
        uint256 indexed poolId,
        address priorityLP,
        uint256 amount
    );

    event LiquidityUnstakedWithoutFarming(
        address indexed user,
        uint256 indexed poolId,
        address priorityLP,
        uint256 amount
    );

    event LiquidityRemoved(address indexed user, uint256 amount);

    event PayoutClaimed(address indexed user, uint256 amount);

    event PremiumSplitted(
        uint256 toPriority,
        uint256 toProtection,
        uint256 toTreasury
    );

    event PremiumSwapped(address fromToken, uint256 amount, uint256 received);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error PolicyCenter__AlreadyClaimedPayout(); // a2ded9c1
    error PolicyCenter__WrongPriorityPoolID(); // 67f304bf
    error PolicyCenter__InsufficientCapacity(); // 7730dc0b
    error PolicyCenter__OnlyPriorityPoolFactory(); // aca500b4
    error PolicyCenter__ZeroPremium(); // 720794bf
    error PolicyCenter__NoLiquidity(); // d5c16599
    error PolicyCenter__NoExchange(); // 7bb995d0
    error PolicyCenter__ZeroAmount(); // 1613633b
    error PolicyCenter__NoPayout(); // 6e472dea
    error PolicyCenter__NonExistentPool(); // 5824d49b
    error PolicyCenter__BadLength(); // 1eaaaf2c
    error PolicyCenter__PremiumTooHigh(); // 855e507b
    error PolicyCenter__InvalidPremiumSplit(); //
    error PolicyCenter__PoolPaused(); //
    error PolicyCenter__OnlyTreasury(); //
    error PolicyCenter__WrongPath();
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IPriceGetter {
    function getLatestPrice(string memory _tokenName)
        external
        returns (uint256 price);

    function getLatestPrice(address _token) external returns (uint256 price);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

library StringUtils {
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../util/SimpleIERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library SimpleSafeERC20 {
    using Address for address;

    function safeTransfer(
        SimpleIERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        SimpleIERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(SimpleIERC20 token, bytes memory data)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ISwapHelper {
    function swap(address _token, uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation()
        external
        ifAdmin
        returns (address implementation_)
    {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(
            msg.sender != _getAdmin(),
            "TransparentUpgradeableProxy: admin cannot fallback to proxy target"
        );
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    constructor() Ownable() {}

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"5c60da1b"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"f851a440"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(
        TransparentUpgradeableProxy proxy,
        address newAdmin
    ) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation)
        public
        virtual
        onlyOwner
    {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockVeDEG is ERC20 {
    uint256 public constant MAX_UINT256 = type(uint256).max;

    uint8 public _decimals; //How many decimals to show.

    mapping(address => uint256) public locked;

    mapping(address => bool) public alreadyMinted;

    address public owner;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
        require(_decimalUnits == 18);

        _mint(msg.sender, _initialAmount);

        _decimals = _decimalUnits; // Amount of decimals for display purposes

        owner = msg.sender;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address _user, uint256 _amount) public {
        if (msg.sender != owner) {
            require(_amount == 10000 ether, "Wrong amount");
            require(!alreadyMinted[_user], "Already minted");
        }
        alreadyMinted[_user] = true;
        _mint(_user, _amount);
    }

    function lockVeDEG(address _owner, uint256 _value) public {
        locked[_owner] += _value;
    }

    function unlockVeDEG(address _owner, uint256 _value) public {
        locked[_owner] -= _value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    uint8 private _decimals;

    address public owner;

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimal
    ) ERC20(_name, _symbol) {
        require(_decimal == 6);

        owner = msg.sender;

        _decimals = uint8(_decimal);
    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == owner);

        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external {
        require(msg.sender == owner);

        _burn(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockSHIELD is ERC20 {
    event Deposit(address indexed _from, uint256 _value);
    uint256 public constant MAX_UINT256 = type(uint256).max;

    uint8 public _decimals; //How many decimals to show.

    mapping(address => bool) public alreadyMinted;

    address public owner;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
        require(_decimalUnits == 6);

        _mint(msg.sender, _initialAmount);

        owner = msg.sender;

        _decimals = _decimalUnits; // Amount of decimals for display purposes
    }

    function mint(address _to, uint256 _amount) public {
        if (msg.sender != owner) {
            require(_amount == 10000 * 10**6, "Wrong amount");
            require(!alreadyMinted[_to], "Already minted");
        }

        alreadyMinted[_to] = true;
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) public {
        require(msg.sender == owner, "Only owner");

        _burn(_to, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function deposit(
        uint256 _type,
        address _token,
        uint256 _transfer,
        uint256 _minReceive
    ) public {
        if (_type == 1) {
            _mint(msg.sender, _minReceive);
            IERC20(_token).transferFrom(msg.sender, address(this), _transfer);
        } else revert("Wrong type");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint256 public constant MAX_HOLD = 10000 ether;

    uint8 private _decimals;

    address public owner;

    mapping(address => uint256) alreadyMinted;

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimal
    ) ERC20(_name, _symbol) {
        _decimals = uint8(_decimal);

        owner = msg.sender;
    }

    function mint(address _to, uint256 _amount) external {
        if (msg.sender != owner) {
            require(alreadyMinted[_to] + _amount <= MAX_HOLD);
        }

        alreadyMinted[_to] += _amount;
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external {
        require(msg.sender == owner);
        alreadyMinted[_to] -= _amount;
        _burn(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockDEG is ERC20 {
    uint256 public constant MAX_UINT256 = type(uint256).max;

    uint8 public _decimals; //How many decimals to show

    mapping(address => bool) public alreadyMinted;

    address public owner;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) {
        require(_decimalUnits == 18);

        _mint(msg.sender, _initialAmount);

        owner = msg.sender;

        _decimals = _decimalUnits; // Amount of decimals for display purposes
    }

    /**
     * @notice Free mint
     */
    function mintDegis(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }

    /**
     * @notice This is for frontend mint
     */
    function mint(address _account, uint256 _amount) external {
        if (msg.sender != owner) {
            require(_amount == 100 ether, "Wrong amount");
            require(!alreadyMinted[_account], "Already minted");
        }

        alreadyMinted[_account] = true;
        _mint(_account, _amount);
    }

    function burnDegis(address _account, uint256 _amount) external {
        _burn(_account, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../util/OwnableWithoutContext.sol";

import "../interfaces/IIncidentReport.sol";

import "../libraries/DateTime.sol";

/**
 * @notice Cover Right Tokens
 *
 *         ERC20 tokens that represent the cover you bought
 *         It is a special token:
 *             1) Can not be transferred to other addresses
 *             2) Has an expiry date
 *
 *         A new crToken will be deployed for each month's policies for a pool
 *         Each crToken will ended at the end timestamp of each month
 *
 *         To calculate a user's balance, we use coverFrom to record it.
 *         E.g.  CRToken CR-JOE-2022-8
 *               You bought X amount at timestamp t1 (in 2022-6 ~ 2022-8)
 *               coverStartFrom[yourAddress][t1] += X
 *
 *         When used for claiming, check your crTokens
 *             1) Not expired
 *             2) Not bought too close to the report timestamp
 *
 */
contract CoverRightToken is ERC20, ReentrancyGuard {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Generation of crToken
    // Same as the generation of the priority pool (when this token was deployed)
    uint256 public immutable generation;

    // Expiry date (always the last timestamp of a month)
    uint256 public immutable expiry;

    // Pool id for this crToken
    uint256 public immutable poolId;

    // Those covers bought within 2 days will be excluded
    // TODO: test will set it as 0
    uint256 public constant EXCLUDE_DAYS = 2;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Policy center address
    address public policyCenter;

    // Incident report address
    address public incidentReport;

    // Payout pool address
    address public payoutPool;

    // Pool name for this crToken
    string public poolName;

    // User address => start timestamp => cover amount
    mapping(address => mapping(uint256 => uint256)) public coverStartFrom;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(
        string memory _poolName,
        uint256 _poolId,
        string memory _name,
        uint256 _expiry,
        uint256 _generation,
        address _policyCenter,
        address _incidentReport,
        address _payoutPool
    ) ERC20(_name, "crToken") {
        expiry = _expiry;

        poolName = _poolName;
        poolId = _poolId;
        generation = _generation;

        policyCenter = _policyCenter;
        incidentReport = _incidentReport;
        payoutPool = _payoutPool;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Only called from permitted addresses
     *
     *         Permitted addresses:
     *            1) Policy center
     *            2) Payout pool
     *
     *         For policyCenter, when deploying new crTokens, the policyCenter address is still not initialized,
     *         so we only skip the test when policyCenter is address(0)
     */
    modifier onlyPermitted() {
        if (policyCenter != address(0)) {
            require(
                msg.sender == policyCenter || msg.sender == payoutPool,
                "Not permitted"
            );
        }
        _;
    }

    /**
     * @notice Override the decimals funciton
     *
     *         Cover right token is minted with reference to the cover amount he bought
     *         So keep the decimals the same with USDC
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint new crTokens when buying covers
     *
     * @param _poolId Pool id
     * @param _user   User address
     * @param _amount Amount to mint
     */
    function mint(
        uint256 _poolId,
        address _user,
        uint256 _amount
    ) external onlyPermitted nonReentrant {
        require(_amount > 0, "Zero Amount");
        require(_poolId == poolId, "Wrong pool id");

        // uint256 effectiveFrom = _getEOD(
        //     block.timestamp + EXCLUDE_DAYS * 1 days
        // );

        // Start from today's last timestamp
        uint256 effectiveFrom = _getEOD(block.timestamp);

        coverStartFrom[_user][effectiveFrom] += _amount;

        _mint(_user, _amount);
    }

    /**
     * @notice Burn crTokens to claim
     *         Only callable from policyCenter
     *
     * @param _poolId Pool id
     * @param _user   User address
     * @param _amount Amount to burn
     */
    function burn(
        uint256 _poolId,
        address _user,
        uint256 _amount
    ) external onlyPermitted nonReentrant {
        require(_amount > 0, "Zero Amount");
        require(_poolId == poolId, "Wrong pool id");

        _burn(_user, _amount);
    }

    /**
     * @notice Get the claimable amount of a user
     *         Claimable means "without those has passed the expiry date"
     *
     * @param _user User address
     *
     * @return claimable Claimable balance
     */
    function getClaimableOf(address _user) external view returns (uint256) {
        uint256 exclusion = getExcludedCoverageOf(_user);
        uint256 balance = balanceOf(_user);

        if (exclusion > balance) return 0;
        else return balance - exclusion;
    }

    /**
     * @notice Get the excluded amount of a user
     *         Excluded means "without those are bought within a short time before voteTimestamp"
     *
     *         Only count the corresponding one report (voteTimestamp)
     *         Each crToken & priorityPool has a generation
     *         And should get the correct report with this "Generation"
     *             - poolReports(poolId, generation)
     *
     * @param _user User address
     *
     * @return exclusion Amount not able to claim because cover period has ended
     */
    function getExcludedCoverageOf(address _user)
        public
        view
        returns (uint256 exclusion)
    {
        IIncidentReport incident = IIncidentReport(incidentReport);

        // Get the report amount for this pool
        // If report amount is 0, generation should be 1 and no excluded amount
        // If report amount > 0, the effective report should be amount - 1
        uint256 reportAmount = incident.getPoolReportsAmount(poolId);

        if (reportAmount > 0 && generation <= reportAmount) {
            // Only count for the valid report
            // E.g. Current report amount is 3, then for generation 1 crToken,
            //      its corresponding report index (in the array) is 0
            uint256 validReportId = incident.poolReports(
                poolId,
                generation - 1
            );

            (, , , uint256 voteTimestamp, , , , , uint256 result, , ) = incident
                .reports(validReportId);

            // If the result is not PASS, the voteTimestamp should not be counted
            if (result == 1) {
                // Check those bought within 2 days
                for (uint256 i; i < EXCLUDE_DAYS; ) {
                    if (voteTimestamp > i * 1 days) {
                        // * For local test EXCLUDE_DAYS can be set as 0 to avoid underflow
                        // * For mainnet or testnet, will never underflow
                        uint256 date = _getEOD(voteTimestamp - (i * 1 days));

                        exclusion += coverStartFrom[_user][date];
                    }
                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * @notice Get the timestamp at the end of the day
     *
     * @param _timestamp Timestamp to be transformed
     *
     * @return endTimestamp End timestamp of that day
     */
    function _getEOD(uint256 _timestamp) private pure returns (uint256) {
        (uint256 year, uint256 month, uint256 day) = DateTimeLibrary
            .timestampToDate(_timestamp);
        return
            DateTimeLibrary.timestampFromDateTime(year, month, day, 23, 59, 59);
    }

    /**
     * @notice Hooks before token transfer
     *         - Can burn expired crTokens (send to zero address)
     *         - Can be minted or used for claim
     *         Other transfers are banned
     *
     * @param from From address
     * @param to   To address
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal view override {
        if (block.timestamp > expiry) {
            require(to == address(0), "Expired crToken");
        }

        // crTokens can only be used for claim
        if (from != address(0) && to != address(0)) {
            require(to == policyCenter, "Only to policyCenter");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

abstract contract OwnableWithoutContext {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting a customized initial owner.
     */
    constructor(address _initOwner) {
        _owner = _initOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
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
    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IIncidentReport {
    struct Report {
        uint256 poolId; // Project pool id
        uint256 reportTimestamp; // Time of starting report
        address reporter; // Reporter address
        uint256 voteTimestamp; // Voting start timestamp
        uint256 numFor; // Votes voting for
        uint256 numAgainst; // Votes voting against
        uint256 round; // 0: Initial round 3 days, 1: Extended round 1 day, 2: Double extended 1 day
        uint256 status; // 0: INIT, 1: PENDING, 2: VOTING, 3: SETTLED, 404: CLOSED
        uint256 result; // 1: Pass, 2: Reject, 3: Tied
        uint256 votingReward; // Voting reward per veDEG
        uint256 payout; // Payout amount of this report (partial payout)
    }

    struct TempResult {
        uint256 a;
        uint256 b;
        bool c;
    }
    struct UserVote {
        uint256 choice;
        uint256 amount;
        bool claimed;
    }

    /**
     * @notice Cool down period when you submit a wrong report
     *         Wrong Report: Closed by the Admin team
     *
     * @return COOLDOWN_WRONG_REPORT Cooldown time in second (before you can submit another report)
     */
    function COOLDOWN_WRONG_REPORT() external view returns (uint256);

    /**
     * @notice Claim reward
     *         Users can claim reward when they vote correctly
     *
     * @param _reportId Report id
     */
    function claimReward(uint256 _reportId) external;

    /**
     * @notice Close a report
     *         Only callable by the owner
     *
     * @param _reportId Report id
     */
    function closeReport(uint256 _reportId) external;

    function deg() external view returns (address);

    function executor() external view returns (address);

    function getReport(uint256 _id) external view returns (Report memory);

    function getTempResult(uint256 _id)
        external
        view
        returns (TempResult memory);

    function getUserVote(address _user, uint256 _id)
        external
        view
        returns (UserVote memory);

    function incidentReport() external view returns (address);

    function priorityPoolFactory() external view returns (address);

    function onboardProposal() external view returns (address);

    function owner() external view returns (address);

    function payDebt(uint256 _reportId, address _user) external;

    function policyCenter() external view returns (address);

    function poolReported(address) external view returns (bool);

    function protectionPool() external view returns (address);

    function renounceOwnership() external;

    function report(
        uint256 _poolId,
        uint256 _payout,
        address _user
    ) external;

    function reportCounter() external view returns (uint256);

    function reportTempResults(uint256)
        external
        view
        returns (
            uint256 result,
            uint256 sampleTimestamp,
            bool hasChanged
        );

    function reports(uint256)
        external
        view
        returns (
            uint256 poolId,
            uint256 reportTimestamp,
            address reporter,
            uint256 voteTimestamp,
            uint256 numFor,
            uint256 numAgainst,
            uint256 round,
            uint256 status,
            uint256 result,
            uint256 votingReward,
            uint256 payout
        );

    function setExecutor(address _executor) external;

    function setIncidentReport(address _incidentReport) external;

    function setPriorityPoolFactory(address _priorityPoolFactory) external;

    function setOnboardProposal(address _onboardProposal) external;

    function setPolicyCenter(address _policyCenter) external;

    function setProtectionPool(address _protectionPool) external;

    function settle(uint256 _reportId) external;

    function startVoting(uint256 _reportId) external;

    function transferOwnership(address newOwner) external;

    function unpausePools(uint256 _poolId) external;

    function userCoolDownUntil(address) external view returns (uint256);

    function votes(address, uint256)
        external
        view
        returns (
            uint256 choice,
            uint256 amount,
            bool claimed
        );

    function veDeg() external view returns (address);

    function vote(
        uint256 _reportId,
        uint256 _isFor,
        uint256 _amount,
        address _user
    ) external;

    function poolReports(uint256 _poolId, uint256 _index)
        external
        view
        returns (uint256);

    function getPoolReportsAmount(uint256 _poolId)
        external
        view
        returns (uint256);

    function executed(uint256 _reportId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "./CoverRightToken.sol";
import "../util/OwnableWithoutContextUpgradeable.sol";

/**
 * @notice Factory for deploying crTokens
 *
 *         Salt as index for cover right tokens:
 *             salt = keccak256(poolId, expiry, genration)
 *
 *         Factory will record whether a crToken has been deployed
 *         Also record the generation of a specific crToken
 *         And find the address of the crToken with its salt
 *
 */
contract CoverRightTokenFactory is OwnableWithoutContextUpgradeable {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    address public policyCenter;

    address public incidentReport;

    address public payoutPool;

    // Salt => Already deployed
    mapping(bytes32 => bool) public deployed;

    // Salt => CR token address
    mapping(bytes32 => address) public saltToAddress;

    // Salt => Generation
    mapping(bytes32 => uint256) public generation;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event NewCRTokenDeployed(
        uint256 poolId,
        string tokenName,
        uint256 expiry,
        uint256 generation,
        address tokenAddress
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _policyCenter, address _incidentReport)
        public
        initializer
    {
        __Ownable_init();

        policyCenter = _policyCenter;
        incidentReport = _incidentReport;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get crToken address
     *
     * @param _poolId     Pool id
     * @param _expiry     Expiry timestamp
     * @param _generation Generation of the crToken
     *
     * @return crToken CRToken address
     */
    function getCRTokenAddress(
        uint256 _poolId,
        uint256 _expiry,
        uint256 _generation
    ) external view returns (address crToken) {
        crToken = saltToAddress[
            keccak256(abi.encodePacked(_poolId, _expiry, _generation))
        ];
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function setPayoutPool(address _payoutPool) external onlyOwner {
        require(_payoutPool != address(0), "Zero Address");
        payoutPool = _payoutPool;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Deploy Cover Right Token for a given pool
     *
     * @param _poolName   Name of Priority Pool
     * @param _poolId     Pool Id
     * @param _tokenName  Name of insured token (e.g. DEG)
     * @param _expiry     Expiry date of cover right token
     * @param _generation Generation of priority pool & crToken (1 if no liquidations occurred)
     *
     * @return newCRToken New deployed crToken address
     */
    function deployCRToken(
        string calldata _poolName,
        uint256 _poolId,
        string calldata _tokenName,
        uint256 _expiry,
        uint256 _generation
    ) external returns (address newCRToken) {
        require(msg.sender == policyCenter, "Only policy center");
        require(_expiry > 0, "Zero expiry date");

        bytes32 salt = keccak256(
            abi.encodePacked(_poolId, _expiry, _generation)
        );

        require(!deployed[salt], "Already deployed");
        deployed[salt] = true;

        bytes memory bytecode = _getCRTokenBytecode(
            _poolName,
            _poolId,
            _tokenName,
            _expiry,
            _generation
        );

        newCRToken = _deploy(bytecode, salt);
        saltToAddress[salt] = newCRToken;

        emit NewCRTokenDeployed(
            _poolId,
            _tokenName,
            _expiry,
            _generation,
            newCRToken
        );
    }

    /**
     * @notice Get cover right token deployment bytecode (with parameters)
     *
     * @param _poolName   Name of Priority Pool
     * @param _poolId     Pool Id
     * @param _tokenName  Name of insured token (e.g. DEG)
     * @param _expiry     Expiry date of cover right token
     * @param _generation Generation of priority pool (1 if no liquidations occurred)
     */
    function _getCRTokenBytecode(
        string memory _poolName,
        uint256 _poolId,
        string memory _tokenName,
        uint256 _expiry,
        uint256 _generation
    ) internal view returns (bytes memory code) {
        bytes memory bytecode = type(CoverRightToken).creationCode;

        require(policyCenter != address(0), "Zero Address");
        require(incidentReport != address(0), "Zero Address");
        require(payoutPool != address(0), "Zero Address");

        code = abi.encodePacked(
            bytecode,
            abi.encode(
                _tokenName,
                _poolId,
                _poolName,
                _expiry,
                _generation,
                policyCenter,
                incidentReport,
                payoutPool
            )
        );
    }

    /**
     * @notice Deploy function with create2
     *
     * @param code Byte code of the contract (creation code)
     * @param salt Salt for the deployment
     *
     * @return addr The deployed contract address
     */
    function _deploy(bytes memory code, bytes32 salt)
        internal
        returns (address addr)
    {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OwnableWithoutContext} from "../util/OwnableWithoutContext.sol";

/**
 * @title  Price Getter
 * @notice This is the contract for getting price feed from chainlink.
 *         The contract will keep a record from tokenName => priceFeed Address.
 *         Got the sponsorship and collaboration with Chainlink.
 * @dev    The price from chainlink priceFeed has different decimals, be careful.
 */
contract MockPriceGetter is OwnableWithoutContext {
    // Find address according to name
    mapping(string => address) public nameToAddress;

    event LatestPriceGet(address token);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor() OwnableWithoutContext(msg.sender) {}

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Main Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    function getLatestPrice(string memory _tokenName) public returns (uint256) {
        return getLatestPrice(nameToAddress[_tokenName]);
    }

    function getLatestPrice(address _tokenAddress) public returns (uint256) {
        emit LatestPriceGet(_tokenAddress);
        return 1e18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OwnableWithoutContextUpgradeable} from "../util/OwnableWithoutContextUpgradeable.sol";

/**
 * @title  Price Getter
 * @notice This is the contract for getting price feed from chainlink.
 *         The contract will keep a record from tokenName => priceFeed Address.
 *         Got the sponsorship and collaboration with Chainlink.
 * @dev    The price from chainlink priceFeed has different decimals, be careful.
 */
contract PriceGetter is OwnableWithoutContextUpgradeable {
    struct PriceFeedInfo {
        address priceFeedAddress;
        uint256 decimals;
    }
    // Use token address as the mapping key
    mapping(address => PriceFeedInfo) public priceFeedInfo;

    // Find address according to name
    mapping(string => address) public nameToAddress;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //
    event PriceFeedChanged(
        string tokenName,
        address tokenAddress,
        address feedAddress,
        uint256 decimals
    );

    event LatestPriceGet(
        uint80 roundID,
        int256 price,
        uint256 startedAt,
        uint256 timeStamp,
        uint80 answeredInRound
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize() public initializer {
        __Ownable_init();
    }

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Modifiers ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Can not give zero address
     */
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set a price feed oracle address for a token
     * @dev Only callable by the owner
     *      The price result decimal should be less than 18
     *
     * @param _tokenName   Address of the token
     * @param _tokenAddress Address of the token
     * @param _feedAddress Price feed oracle address
     * @param _decimals    Decimals of this price feed service
     */
    function setPriceFeed(
        string memory _tokenName,
        address _tokenAddress,
        address _feedAddress,
        uint256 _decimals
    ) public onlyOwner notZeroAddress(_feedAddress) {
        require(_decimals <= 18, "Too many decimals");

        priceFeedInfo[_tokenAddress] = PriceFeedInfo(_feedAddress, _decimals);
        nameToAddress[_tokenName] = _tokenAddress;

        emit PriceFeedChanged(
            _tokenName,
            _tokenAddress,
            _feedAddress,
            _decimals
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Main Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get latest price of a token
     *
     * @param _tokenName Name of the token
     *
     * @return price The latest price
     */
    function getLatestPrice(string memory _tokenName) public returns (uint256) {
        return getLatestPrice(nameToAddress[_tokenName]);
    }

    /**
     * @notice Get latest price of a token
     *
     * @param _tokenAddress Address of the token
     *
     * @return finalPrice The latest price
     */
    function getLatestPrice(address _tokenAddress)
        public
        returns (uint256 finalPrice)
    {
        PriceFeedInfo memory priceFeed = priceFeedInfo[_tokenAddress];

        if (priceFeed.priceFeedAddress == address(0)) {
            finalPrice = 1e18;
        } else {
            (
                uint80 roundID,
                int256 price,
                uint256 startedAt,
                uint256 timeStamp,
                uint80 answeredInRound
            ) = AggregatorV3Interface(priceFeed.priceFeedAddress)
                    .latestRoundData();

            // require(price > 0, "Only accept price that > 0");
            if (price < 0) price = 0;

            emit LatestPriceGet(
                roundID,
                price,
                startedAt,
                timeStamp,
                answeredInRound
            );
            // Transfer the result decimals
            finalPrice = uint256(price) * (10**(18 - priceFeed.decimals));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
  *******         **********     ***********     *****     ***********
  *      *        *              *                 *       *
  *        *      *              *                 *       *
  *         *     *              *                 *       *
  *         *     *              *                 *       *
  *         *     **********     *       *****     *       ***********
  *         *     *              *         *       *                 *
  *         *     *              *         *       *                 *
  *        *      *              *         *       *                 *
  *      *        *              *         *       *                 *
  *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "../../util/PausableWithoutContext.sol";

import "./PriorityPoolDependencies.sol";
import "./PriorityPoolEventError.sol";
import "./PriorityPoolToken.sol";

import "../../libraries/DateTime.sol";
import "../../libraries/StringUtils.sol";

/**
 * @title Priority Pool (for single project)
 *
 * @author Eric Lee ([email protected]) & Primata ([email protected])
 *
 * @notice Priority pool is used for protecting a specific project
 *         Each priority pool has a maxCapacity (0 ~ 10,000 <=> 0 ~ 100%) that it can cover
 *         (that ratio represents the part of total assets in Protection Pool)
 *
 *         When liquidity providers join a priority pool,
 *         they need to transfer their RP_LP token to this priority pool.
 *
 *         After that, they can share the 45% percent native token reward of this pool.
 *         At the same time, that also means these liquidity will be first liquidated,
 *         when there is an incident happened for this project.
 *
 *         This reward is distributed in another contract (WeightedFarmingPool)
 *         By default, policy center will help user to deposit into farming pool when staking liquidity
 *
 *         For liquidation process, the pool will first redeem USDC from protectionPool with the staked RP_LP tokens.
 *         - If that is enough, no more redeeming.
 *         - If still need some liquidity to cover, it will directly transfer part of the protectionPool assets to users.
 *
 *         Most of the functions need to be called through Policy Center:
 *             1) When buying new covers: updateWhenBuy
 *             2) When staking liquidity: stakedLiquidity
 *             3) When unstaking liquidity: unstakedLiquidity
 *
 */
contract PriorityPool is
    PriorityPoolEventError,
    PausableWithoutContext,
    PriorityPoolDependencies
{
    using StringUtils for uint256;
    using DateTimeLibrary for uint256;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Mininum cover amount 10U
    // Avoid accuracy issues
    uint256 internal constant MIN_COVER_AMOUNT = 10e6;

    // Max time length in month
    uint256 internal constant MAX_LENGTH = 3;

    // Min time length in month
    uint256 internal constant MIN_LENGTH = 1;

    address internal immutable owner;

    // Base premium ratio (max 10000) (260 means 2.6% annually)
    uint256 public immutable basePremiumRatio;

    // Pool id set when deployed
    uint256 public immutable poolId;

    // Timestamp of pool creation
    uint256 public immutable startTime;

    // Address of insured token (used for premium payment)
    address public immutable insuredToken;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Pool name
    string public poolName;

    // Current generation of this priority pool (start from 1)
    // Every time there is a report and liquidation, generation += 1
    uint256 public generation;

    // Max capacity of cover amount to be bought (ratio of total liquidity)
    // 10000 = 100%
    uint256 public maxCapacity;

    // Index for cover amount
    uint256 public coverIndex;

    // Has already passed the base premium ratio period
    bool public passedBasePeriod;

    // Year => Month => Amount of cover ends in that month
    mapping(uint256 => mapping(uint256 => uint256)) public coverInMonth;

    // Generation => lp token address
    mapping(uint256 => address) public lpTokenAddress;

    // Address => Whether is LP address
    mapping(address => bool) public isLPToken;

    // PRI-LP address => Price of lp tokens
    // PRI-LP token amount * Price Index = PRO-LP token amount
    mapping(address => uint256) public priceIndex;

    mapping(uint256 => mapping(uint256 => uint256)) public payoutInMonth;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(
        uint256 _poolId,
        string memory _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _baseRatio,
        address _owner,
        address _priorityPoolFactory,
        address _weightedFarmingPool,
        address _protectionPool,
        address _policyCenter,
        address _payoutPool
    ) {
        owner = _owner;

        poolId = _poolId;
        poolName = _name;

        insuredToken = _protocolToken;
        maxCapacity = _maxCapacity;
        startTime = block.timestamp;

        basePremiumRatio = _baseRatio;

        // Generation 1, price starts from 1 (SCALE)
        priceIndex[_deployNewGenerationLP(_weightedFarmingPool)] = SCALE;

        coverIndex = 10000;

        priorityPoolFactory = _priorityPoolFactory;

        weightedFarmingPool = _weightedFarmingPool;
        protectionPool = _protectionPool;
        policyCenter = _policyCenter;
        payoutPool = _payoutPool;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    modifier onlyExecutor() {
        if (msg.sender != IPriorityPoolFactory(priorityPoolFactory).executor())
            revert PriorityPool__OnlyExecutor();
        _;
    }

    modifier onlyPolicyCenter() {
        if (msg.sender != policyCenter) revert PriorityPool__OnlyPolicyCenter();
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get the current generation PRI-LP token address
     *
     * @return lpAddress Current pri-lp address
     */
    function currentLPAddress() public view returns (address) {
        return lpTokenAddress[generation];
    }

    /**
     * @notice Cost to buy a cover for a given period of time and amount of tokens
     *
     * @param _amount        Amount being covered (usdc)
     * @param _coverDuration Cover length in month
     *
     * @return price  Cover price in usdc
     * @return length Real length in timestamp
     */
    function coverPrice(uint256 _amount, uint256 _coverDuration)
        external
        view
        returns (uint256 price, uint256 length)
    {
        _checkAmount(_amount);

        // Dynamic premium ratio (annually)
        uint256 dynamicRatio = dynamicPremiumRatio(_amount);

        (uint256 endTimestamp, , ) = DateTimeLibrary._getExpiry(
            block.timestamp,
            _coverDuration
        );

        // Length in second
        length = endTimestamp - block.timestamp;

        // Price depends on the real timestamp length
        price = (dynamicRatio * _amount * length) / (SECONDS_PER_YEAR * 10000);
    }

    /**
     * @notice Get current active cover amount
     *         Active cover amount = sum of the nearest 3 months' covers
     *
     * @return covered Total active cover amount
     */
    function activeCovered() public view returns (uint256 covered) {
        (uint256 currentYear, uint256 currentMonth, ) = block
            .timestamp
            .timestampToDate();

        // Only count the latest 3 months
        for (uint256 i; i < 3; ) {
            covered += (coverInMonth[currentYear][currentMonth] -
                payoutInMonth[currentYear][currentMonth]);

            unchecked {
                if (++currentMonth > 12) {
                    ++currentYear;
                    currentMonth = 1;
                }

                ++i;
            }
        }

        covered = (covered * coverIndex) / 10000;
    }

    /**
     * @notice Current minimum asset requirement for Protection Pool
     *         Min requirement * capacity ratio = active covered
     *
     *         Total assets in protection pool should be larger than any of the "minAssetRequirement"
     *         Or the cover index would be cut
     */
    function minAssetRequirement() external view returns (uint256) {
        return (activeCovered() * 10000) / maxCapacity;
    }

    /**
     * @notice Get the dynamic premium ratio (annually)
     *         Depends on the covers sold and liquidity amount in all dynamic priority pools
     *         For the first 7 days, use the base premium ratio
     *
     * @param _coverAmount New cover amount (usdc) being bought
     *
     * @return ratio The dynamic ratio
     */
    function dynamicPremiumRatio(uint256 _coverAmount)
        public
        view
        returns (uint256 ratio)
    {
        // Time passed since this pool started
        uint256 fromStart = block.timestamp - startTime;

        uint256 totalActiveCovered = IProtectionPool(protectionPool)
            .getTotalActiveCovered();

        uint256 stakedProSupply = IProtectionPool(protectionPool)
            .stakedSupply();

        // First 7 days use base ratio
        // Then use dynamic ratio
        // TODO: test use 5 hours
        if (fromStart > DYNAMIC_TIME) {
            // Total dynamic pools
            uint256 numofDynamicPools = IPriorityPoolFactory(
                priorityPoolFactory
            ).dynamicPoolCounter();

            if (
                numofDynamicPools > 0 &&
                totalActiveCovered > 0 &&
                stakedProSupply > 0
            ) {
                // Covered ratio = Covered amount of this pool / Total covered amount
                uint256 coveredRatio = ((activeCovered() + _coverAmount) *
                    SCALE) / (totalActiveCovered + _coverAmount);

                address lp = currentLPAddress();

                //                         PRO-LP token in this pool
                // LP Token ratio =  -------------------------------------------
                //                    PRO-LP token staked in all priority pools
                //
                uint256 tokenRatio = (SimpleERC20(lp).totalSupply() * SCALE) /
                    stakedProSupply;

                // Dynamic premium ratio
                // ( N = total dynamic pools ≤ total pools )
                //
                //                      Covered          1
                //                   --------------- + -----
                //                    TotalCovered       N
                // dynamic ratio =  -------------------------- * base ratio
                //                      LP Amount         1
                //                  ----------------- + -----
                //                   Total LP Amount      N
                //
                ratio =
                    (basePremiumRatio *
                        (coveredRatio * numofDynamicPools + SCALE)) /
                    ((tokenRatio * numofDynamicPools) + SCALE);
            } else ratio = basePremiumRatio;
        } else {
            ratio = basePremiumRatio;
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set the max capacity of this priority pool manually
     *         Only owner set this function on a monthly / quaterly base
     *         (For those unpopular pools to decrease, and those popular ones to increase)
     *
     * @param _maxCapacity New max capacity of this pool
     */
    function setMaxCapacity(uint256 _maxCapacity) external {
        require(msg.sender == owner, "Only owner");

        maxCapacity = _maxCapacity;

        bool isUp = _maxCapacity > maxCapacity;

        uint256 diff;
        if (isUp) {
            diff = _maxCapacity - maxCapacity;
        } else {
            diff = maxCapacity - _maxCapacity;
        }

        // Store the max capacity change
        IPriorityPoolFactory(priorityPoolFactory).updateMaxCapacity(isUp, diff);
    }

    /**
     * @notice Set the cover index of this priority pool
     *
     *         Only called from protection pool
     *
     *         When a payout happened in another priority pool,
     *         and this priority pool's minAssetRequirement is less than proteciton pool's asset,
     *         the cover index of this pool will be cut by a ratio
     *
     * @param _newIndex New cover index
     */
    function setCoverIndex(uint256 _newIndex) external {
        require(msg.sender == protectionPool, "Only protection pool");

        emit CoverIndexChanged(coverIndex, _newIndex);
        coverIndex = _newIndex;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Provide liquidity to priority pool
     *         Only callable through policyCenter
     *         Can not provide new liquidity when paused
     *
     * @param _amount   Amount of liquidity (PRO-LP token) to provide
     * @param _provider Liquidity provider adress
     */
    function stakedLiquidity(uint256 _amount, address _provider)
        external
        whenNotPaused
        onlyPolicyCenter
        returns (address)
    {
        // Check whether this priority pool should be dynamic
        // If so, update it
        _updateDynamic();

        // Mint current generation lp tokens to the provider
        // PRI-LP amount always 1:1 to PRO-LP
        _mintLP(_provider, _amount);
        emit StakedLiquidity(_amount, _provider);

        return currentLPAddress();
    }

    /**
     * @notice Remove liquidity from priority pool
     *         Only callable through policyCenter
     *
     * @param _lpToken  Address of PRI-LP token
     * @param _amount   Amount of liquidity (PRI-LP) to remove
     * @param _provider Provider address
     */
    function unstakedLiquidity(
        address _lpToken,
        uint256 _amount,
        address _provider
    ) external whenNotPaused onlyPolicyCenter {
        if (!isLPToken[_lpToken]) revert PriorityPool__WrongLPToken();

        // Check whether this priority pool should be dynamic
        // If so, update it
        _updateDynamic();

        // Burn PRI-LP tokens and transfer PRO-LP tokens back
        _burnLP(_lpToken, _provider, _amount);
        emit UnstakedLiquidity(_amount, _provider);
    }

    /**
     * @notice Update the record when new policy is bought
     *         Only called from policy center
     *
     * @param _amount          Cover amount (usdc)
     * @param _premium         Premium for priority pool (in protocol token)
     * @param _length          Cover length (in month)
     * @param _timestampLength Cover length (in second)
     */
    function updateWhenBuy(
        uint256 _amount,
        uint256 _premium,
        uint256 _length,
        uint256 _timestampLength
    ) external whenNotPaused onlyPolicyCenter {
        // Check cover length
        _checkLength(_length);

        // Check cover amount
        _checkAmount(_amount);

        _updateDynamic();

        // Record cover amount in each month
        _updateCoverInfo(_amount, _length);

        // Update the weighted farming pool speed for this priority pool
        uint256 newSpeed = (_premium * SCALE) / _timestampLength;
        _updateWeightedFarmingSpeed(_length, newSpeed);
    }

    function _checkLength(uint256 _length) internal pure {
        if (_length > MAX_LENGTH || _length < MIN_LENGTH)
            revert PriorityPool__WrongCoverLength();
    }

    /**
     * @notice Pause this pool
     *
     * @param _paused True to pause, false to unpause
     */
    function pausePriorityPool(bool _paused) external {
        if ((msg.sender != owner) && (msg.sender != priorityPoolFactory))
            revert PriorityPool__NotOwnerOrFactory();

        _pause(_paused);
    }

    /**
     * @notice Liquidate pool
     *         Only callable by executor
     *         Only after the report has passed the voting
     *
     * @param _amount Payout amount to be moved out
     */
    function liquidatePool(uint256 _amount) external onlyExecutor {
        uint256 payout = _amount > activeCovered() ? activeCovered() : _amount;

        uint256 payoutRatio = _retrievePayout(payout);

        _updateCurrentLPWeight();

        _updateCoveredWhenLiquidated(payoutRatio);

        // Generation ++
        // Deploy the new generation lp token
        // Those who stake liquidity into this priority pool will be given the new lp token
        _deployNewGenerationLP(weightedFarmingPool);

        // Update other pools' cover indexes
        IProtectionPool(protectionPool).updateIndexCut();

        emit Liquidation(_amount, generation);
    }

    function _updateCoveredWhenLiquidated(uint256 _payoutRatio) internal {
        (uint256 currentYear, uint256 currentMonth, ) = block
            .timestamp
            .timestampToDate();

        // Only count the latest 3 months
        for (uint256 i; i < 3; ) {
            payoutInMonth[currentYear][currentMonth] =
                (coverInMonth[currentYear][currentMonth] * _payoutRatio) /
                SCALE;

            unchecked {
                if (++currentMonth > 12) {
                    ++currentYear;
                    currentMonth = 1;
                }

                ++i;
            }
        }
    }

    function updateWhenClaimed(uint256 _expiry, uint256 _amount) external {
        require(msg.sender == payoutPool, "Only payout pool");

        (uint256 currentYear, uint256 currentMonth, ) = _expiry
            .timestampToDate();

        coverInMonth[currentYear][currentMonth] -= _amount;
        payoutInMonth[currentYear][currentMonth] -= _amount;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Check & update dynamic status of this pool
     *         Record this pool as "already dynamic" in factory
     *
     *         Every time there is a new interaction, will do this check
     */
    function _updateDynamic() internal {
        // Put the cheaper check in the first place
        if (!passedBasePeriod && (block.timestamp - startTime > DYNAMIC_TIME)) {
            IPriorityPoolFactory(priorityPoolFactory).updateDynamicPool(poolId);
            passedBasePeriod = true;
        }
    }

    function _checkAmount(uint256 _amount) internal pure {
        if (_amount < MIN_COVER_AMOUNT)
            revert PriorityPool__UnderMinCoverAmount();
    }

    /**
     * @notice Deploy a new generation lp token
     *         Generation starts from 1
     *
     * @return newLPAddress The deployed lp token address
     */
    function _deployNewGenerationLP(address _weightedFarmingPool)
        internal
        returns (address newLPAddress)
    {
        uint256 currentGeneration = ++generation;

        // PRI-LP-2-JOE-G1: First generation of JOE priority pool with pool id 2
        string memory _name = string.concat(
            "PRI-LP-",
            poolId._toString(),
            "-",
            poolName,
            "-G",
            currentGeneration._toString()
        );

        newLPAddress = address(new PriorityPoolToken(_name));
        lpTokenAddress[currentGeneration] = newLPAddress;

        IWeightedFarmingPool(_weightedFarmingPool).addToken(
            poolId,
            newLPAddress,
            SCALE
        );

        priceIndex[newLPAddress] = SCALE;

        isLPToken[newLPAddress] = true;

        emit NewGenerationLPTokenDeployed(
            poolName,
            poolId,
            currentGeneration,
            _name,
            newLPAddress
        );
    }

    /**
     * @notice Mint current generation lp tokens
     *
     * @param _user   User address
     * @param _amount PRI-LP token amount
     */
    function _mintLP(address _user, uint256 _amount) internal {
        // Get current generation lp token address and mint tokens
        address lp = currentLPAddress();
        PriorityPoolToken(lp).mint(_user, _amount);
    }

    /**
     * @notice Burn lp tokens
     *         Need specific generation lp token address as parameter
     *
     * @param _lpToken PRI-LP token adderss
     * @param _user    User address
     * @param _amount  PRI-LP token amount to burn
     */
    function _burnLP(
        address _lpToken,
        address _user,
        uint256 _amount
    ) internal {
        // Transfer PRO-LP token to user
        uint256 proLPAmount = (priceIndex[_lpToken] * _amount) / SCALE;
        SimpleERC20(protectionPool).transfer(_user, proLPAmount);

        // Burn PRI-LP token
        PriorityPoolToken(_lpToken).burn(_user, _amount);
    }

    /**
     * @notice Update cover record info when new covers come in
     *         Record the total cover amount in each month
     *
     * @param _amount Cover amount
     * @param _length Cover length in month
     */
    function _updateCoverInfo(uint256 _amount, uint256 _length) internal {
        (uint256 currentYear, uint256 currentMonth, uint256 currentDay) = block
            .timestamp
            .timestampToDate();

        uint256 monthsToAdd = _length - 1;

        if (currentDay >= 25) {
            monthsToAdd++;
        }

        uint256 endYear = currentYear;
        uint256 endMonth;

        // Check if the cover will end in the same year
        if (currentMonth + monthsToAdd > 12) {
            endMonth = currentMonth + monthsToAdd - 12;
            ++endYear;
        } else {
            endMonth = currentMonth + monthsToAdd;
        }

        coverInMonth[endYear][endMonth] += _amount;
    }

    /**
     * @notice Update the farming speed in WeightedFarmingPool
     *
     * @param _length   Length in month
     * @param _newSpeed Speed to be added (SCALED)
     */
    function _updateWeightedFarmingSpeed(uint256 _length, uint256 _newSpeed)
        internal
    {
        uint256[] memory _years = new uint256[](_length);
        uint256[] memory _months = new uint256[](_length);

        (uint256 currentYear, uint256 currentMonth, ) = block
            .timestamp
            .timestampToDate();

        for (uint256 i; i < _length; ) {
            _years[i] = currentYear;
            _months[i] = currentMonth;

            unchecked {
                if (++currentMonth > 12) {
                    ++currentYear;
                    currentMonth = 1;
                }
                ++i;
            }
        }

        IWeightedFarmingPool(weightedFarmingPool).updateRewardSpeed(
            poolId,
            _newSpeed,
            _years,
            _months
        );
    }

    /**
     * @notice Retrieve assets from Protection Pool for payout
     *
     * @param _amount Amount of usdc to retrieve
     */
    function _retrievePayout(uint256 _amount)
        internal
        returns (uint256 payoutRatio)
    {
        // Current PRO-LP amount
        uint256 currentLPAmount = SimpleERC20(protectionPool).balanceOf(
            address(this)
        );

        IProtectionPool proPool = IProtectionPool(protectionPool);

        uint256 proLPPrice = proPool.getLatestPrice();

        // Need how many PRO-LP tokens to cover the _amount
        uint256 neededLPAmount = (_amount * SCALE) / proLPPrice;

        // If current PRO-LP inside priority pool is enough
        // Remove part of the liquidity from Protection Pool
        if (neededLPAmount < currentLPAmount) {
            proPool.removedLiquidity(neededLPAmount, payoutPool);

            priceIndex[currentLPAddress()] =
                ((currentLPAmount - neededLPAmount) * SCALE) /
                currentLPAmount;
        } else {
            uint256 usdcGot = proPool.removedLiquidity(
                currentLPAmount,
                payoutPool
            );

            uint256 remainingPayout = _amount - usdcGot;

            proPool.removedLiquidityWhenClaimed(remainingPayout, payoutPool);

            priceIndex[currentLPAddress()] = 0;
        }

        // Set a ratio used when claiming with crTokens
        // E.g. ratio is 1e11
        //      You can only use 10% (1e11 / SCALE) of your crTokens for claiming
        activeCovered() > 0
            ? payoutRatio = (_amount * SCALE) / activeCovered()
            : payoutRatio = 0;

        IPayoutPool(payoutPool).newPayout(
            poolId,
            generation,
            _amount,
            payoutRatio,
            coverIndex,
            address(this)
        );
    }

    function _updateCurrentLPWeight() internal {
        address lp = currentLPAddress();

        // Update the farming pool with the new price index
        IWeightedFarmingPool(weightedFarmingPool).updateWeight(
            poolId,
            lp,
            priceIndex[lp]
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

abstract contract PausableWithoutContext {
    bool private _paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Paused");
        _;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function _pause(bool _p) internal virtual {
        _paused = _p;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IPriorityPoolFactory {
    function dynamicPoolCounter() external view returns (uint256);

    function updateMaxCapacity(bool _isUp, uint256 _maxCapacity) external;

    function updateDynamicPool(uint256 _poolId) external;

    function executor() external view returns (address);
}

interface IProtectionPool {
    function getTotalActiveCovered() external view returns (uint256);

    function getLatestPrice() external returns (uint256);

    function removedLiquidity(uint256 _amount, address _provider)
        external
        returns (uint256);

    function removedLiquidityWhenClaimed(uint256 _amount, address _to) external;

    function pauseProtectionPool(bool _paused) external;

    function stakedSupply() external view returns (uint256);

    function updateIndexCut() external;
}

interface IPolicyCenter {
    function storePoolInformation(
        address _pool,
        address _token,
        uint256 _poolId
    ) external;
}

interface IPayoutPool {
    function newPayout(
        uint256 _poolId,
        uint256 _generation,
        uint256 _amount,
        uint256 _ratio,
        uint256 _coverIndex,
        address _poolAddress
    ) external;
}

interface IWeightedFarmingPool {
    function addPool(address _token) external;

    function addToken(
        uint256 _id,
        address _token,
        uint256 _weight
    ) external;

    function updateRewardSpeed(
        uint256 _id,
        uint256 _newSpeed,
        uint256[] memory _years,
        uint256[] memory _months
    ) external;

    function updateWeight(
        uint256 _id,
        address _token,
        uint256 _newWeight
    ) external;
}

abstract contract PriorityPoolDependencies {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    uint256 internal constant SCALE = 1e12;
    uint256 internal constant SECONDS_PER_YEAR = 86400 * 365;

    // TODO: Different parameters for test and mainnet
    uint256 internal constant DYNAMIC_TIME = 7 days;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    address internal policyCenter;
    address internal priorityPoolFactory;
    address internal protectionPool;
    address internal weightedFarmingPool;
    address internal payoutPool;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface PriorityPoolEventError {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event StakedLiquidity(uint256 amount, address sender);
    event UnstakedLiquidity(uint256 amount, address sender);
    event Liquidation(uint256 amount, uint256 generation);

    event NewGenerationLPTokenDeployed(
        string poolName,
        uint256 poolId,
        uint256 currentGeneration,
        string name,
        address newLPAddress
    );

    event CoverIndexChanged(uint256 oldIndex, uint256 newIndex);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    error PriorityPool__OnlyExecutor();
    error PriorityPool__OnlyPolicyCenter();
    error PriorityPool__NotOwnerOrFactory();
    error PriorityPool__WrongLPToken();
    error PriorityPool__WrongCoverLength();
    error PriorityPool__UnderMinCoverAmount();
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/


pragma solidity ^0.8.13;

import "../../util/SimpleERC20.sol";

/**
 * @notice LP token for priority pools
 *
 *         This lp token can be deposited into farming pool to get the premium income
 *         LP token has different generations and they are different in names
 *
 *         E.g.  PRI-LP-2-JOE-G1 and PRI-LP-2-JOE-G2
 *               They are both lp tokens for priority pool 2 (JOE pool)
 *               But with different generations, they have different weights in farming
 *
 *         Every time there is a report for the project and some payout are given out
 *         There will be a new generation of lp token
 *
 *         The weight will be set when the report happened
 *         and will depend on how much part are paid during that report
 */
contract PriorityPoolToken is SimpleERC20 {
    // Only minter and burner is Priority Pool
    address private priorityPool;

    modifier onlyPriorityPool() {
        require(msg.sender == priorityPool, "Only priority pool");
        _;
    }

    constructor(string memory _name) SimpleERC20(_name, "PRI-LP") {
        priorityPool = msg.sender;
    }

    function mint(address _user, uint256 _amount) external onlyPriorityPool {
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external onlyPriorityPool {
        _burn(_user, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

abstract contract SimpleERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public constant decimals = 6;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./PriorityPool.sol";

contract PriorityPoolDeployer is Initializable {
    address public owner;

    address public priorityPoolFactory;
    address public weightedFarmingPool;
    address public protectionPool;
    address public policyCenter;
    address public payoutPool;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(
        address _priorityPoolFactory,
        address _weightedFarmingPool,
        address _protectionPool,
        address _policyCenter,
        address _payoutPool
    ) public initializer {
        owner = msg.sender;

        priorityPoolFactory = _priorityPoolFactory;
        weightedFarmingPool = _weightedFarmingPool;
        protectionPool = _protectionPool;
        policyCenter = _policyCenter;
        payoutPool = _payoutPool;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Create a new priority pool
     *         Called by executor when an onboard proposal has passed
     *
     * @param _name             Name of the protocol
     * @param _protocolToken    Address of the token used for the protocol
     * @param _maxCapacity      Maximum capacity of the pool
     * @param _basePremiumRatio Initial policy price per usdc
     *
     * @return address Address of the new insurance pool
     */
    function deployPool(
        uint256 poolId,
        string calldata _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _basePremiumRatio
    ) public returns (address) {
        require(
            msg.sender == priorityPoolFactory || msg.sender == owner,
            "Only factory"
        );

        address newPoolAddress = _deployPool(
            poolId,
            _name,
            _protocolToken,
            _maxCapacity,
            _basePremiumRatio
        );

        return newPoolAddress;
    }

    function getPoolAddress(
        uint256 _poolId,
        string memory _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _baseRatio
    ) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_poolId, _name));
        bytes memory bytecodeWithParameters = _getBytecode(
            _poolId,
            _name,
            _protocolToken,
            _maxCapacity,
            _baseRatio
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecodeWithParameters)
            )
        );

        return address(uint160(uint256(hash)));
    }

    function _deployPool(
        uint256 _poolId,
        string memory _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _baseRatio
    ) internal returns (address addr) {
        bytes32 salt = keccak256(abi.encodePacked(_poolId, _name));

        bytes memory bytecodeWithParameters = _getBytecode(
            _poolId,
            _name,
            _protocolToken,
            _maxCapacity,
            _baseRatio
        );

        addr = _deploy(bytecodeWithParameters, salt);
    }

    function _getBytecode(
        uint256 _poolId,
        string memory _name,
        address _protocolToken,
        uint256 _maxCapacity,
        uint256 _baseRatio
    ) internal view returns (bytes memory bytecodeWithParameters) {
        bytes memory bytecode = type(PriorityPool).creationCode;

        bytecodeWithParameters = abi.encodePacked(
            bytecode,
            abi.encode(
                _poolId,
                _name,
                _protocolToken,
                _maxCapacity,
                _baseRatio,
                owner,
                priorityPoolFactory,
                weightedFarmingPool,
                protectionPool,
                policyCenter,
                payoutPool
            )
        );
    }

    /**
     * @notice Deploy function with create2
     *
     * @param _code Byte code of the contract (creation code) (including constructor parameters if any)
     * @param _salt Salt for the deployment
     *
     * @return addr The deployed contract address
     */
    function _deploy(bytes memory _code, bytes32 _salt)
        internal
        returns (address addr)
    {
        assembly {
            addr := create2(0, add(_code, 0x20), mload(_code), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IPriceGetter} from "../interfaces/IPriceGetter.sol";

import {IUniswapV2Pair} from "../libraries/IUniswapV2Pair.sol";
import {FixedPoint} from "../libraries/FixedPoint.sol";
import {UniswapV2OracleLibrary} from "../libraries/UniswapV2OracleLibrary.sol";
import {UniswapV2Library} from "../libraries/UniswapV2Library.sol";

/**
 * @title Price Getter for IDO Protection
 *
 * @notice This is the contract for getting price feed from DEX
 *         IDO projects does not have Chainlink feeds so we use DEX TWAP price as oracle
 *
 *         Workflow:
 *         1. Deploy naughty token for the IDO project and set its type as "IDO"
 *         2. Add ido price feed info by calling "addIDOPair" function
 *         3. Set auto tasks start within PERIOD to endTime to sample prices from DEX
 *         4. Call "settleFinalResult" function in core to settle the final price
 */

contract DexPriceGetter is OwnableUpgradeable {
    using FixedPoint for *;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // WAVAX address
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant USDC = 0x23d0cddC1Ea9Fcc5CA9ec6b5fC77E304bCe8d4c3;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Base price getter to transfer the price into USD
    IPriceGetter public basePriceGetter;

    struct IDOPriceInfo {
        address pair; // Pair on TraderJoe
        uint256 decimals; // If no special settings, it would be 0
        uint256 sampleInterval;
        uint256 isToken0;
        uint256 priceAverage;
        uint256 priceCumulativeLast;
        uint256 lastTimestamp;
    }
    // Policy Base Token Name => IDO Info
    mapping(string => IDOPriceInfo) public priceFeeds;

    mapping(address => string) public addressToName;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event SamplePrice(
        string policyToken,
        uint256 priceAverage,
        uint256 timestamp
    );

    event NewIDOPair(
        string policyToken,
        address pair,
        uint256 decimals,
        uint256 sampleInterval,
        uint256 isToken0
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    function initialize(address _priceGetter) public initializer {
        __Ownable_init();

        basePriceGetter = IPriceGetter(_priceGetter);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function addIDOPair(
        string calldata _policyToken,
        address _pair,
        uint256 _decimals,
        uint256 _interval
    ) external onlyOwner {
        require(IUniswapV2Pair(_pair).token0() != address(0), "Non exist pair");
        require(
            IUniswapV2Pair(_pair).token0() == WAVAX ||
                IUniswapV2Pair(_pair).token1() == WAVAX,
            "Not avax pair"
        );
        require(
            priceFeeds[_policyToken].pair == address(0),
            "Pair already exists"
        );

        IDOPriceInfo storage newFeed = priceFeeds[_policyToken];

        newFeed.pair = _pair;
        // Decimals should keep the priceAverage to have 18 decimals
        // WAVAX always have 18 decimals
        // E.g. Pair token both 18 decimals => price decimals 18
        //      (5e18, 10e18) real price 0.5 => we show priceAverage 0.5 * 10^18
        //      Pair token (18, 6) decimals => price decimals 6
        //      (5e18, 10e6) real price 0.5 => we show priceAverage 0.5 * 10^18
        newFeed.decimals = _decimals;
        newFeed.sampleInterval = _interval;

        // Check if the policy base token is token0
        bool isToken0 = !(IUniswapV2Pair(_pair).token0() == WAVAX);

        newFeed.isToken0 = isToken0 ? 1 : 0;

        (, , newFeed.lastTimestamp) = IUniswapV2Pair(_pair).getReserves();

        // Record the initial priceCumulativeLast
        newFeed.priceCumulativeLast = isToken0
            ? IUniswapV2Pair(_pair).price0CumulativeLast()
            : IUniswapV2Pair(_pair).price1CumulativeLast();

        emit NewIDOPair(
            _policyToken,
            _pair,
            _decimals,
            _interval,
            newFeed.isToken0
        );
    }

    /**
     * @notice Set price in avax
     *         Price in avax should be in 1e18
     *
     * @param _policyToken Policy token name
     * @param _price       Price in avax
     */
    function setPrice(string calldata _policyToken, uint256 _price)
        external
        onlyOwner
    {
        priceFeeds[_policyToken].priceAverage = _price;
    }

    function setAddressToName(address _token, string memory _name)
        external
        onlyOwner
    {
        addressToName[_token] = _name;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function samplePrice(string calldata _policyToken) external {
        IDOPriceInfo storage priceFeed = priceFeeds[_policyToken];

        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(priceFeed.pair);

        // Time between this sampling and last sampling (seconds)
        uint32 timeElapsed = blockTimestamp - uint32(priceFeed.lastTimestamp);

        uint256 decimals = priceFeed.decimals;

        require(
            timeElapsed > priceFeed.sampleInterval,
            "Minimum sample interval"
        );

        // Update priceAverage and priceCumulativeLast
        uint256 newPriceAverage;

        if (priceFeed.isToken0 > 0) {
            newPriceAverage = FixedPoint
                .uq112x112(
                    uint224(
                        ((price0Cumulative - priceFeed.priceCumulativeLast) *
                            10**decimals) / timeElapsed
                    )
                )
                .decode();

            priceFeed.priceCumulativeLast = price0Cumulative;
        } else {
            newPriceAverage = FixedPoint
                .uq112x112(
                    uint224(
                        ((price1Cumulative - priceFeed.priceCumulativeLast) *
                            10**decimals) / timeElapsed
                    )
                )
                .decode();

            priceFeed.priceCumulativeLast = price1Cumulative;
        }

        priceFeed.priceAverage = newPriceAverage;

        // Update lastTimestamp
        priceFeed.lastTimestamp = blockTimestamp;

        emit SamplePrice(_policyToken, newPriceAverage, blockTimestamp);
    }

    /**
     * @notice Get latest price of a token
     *
     * @param _token Address of the token
     *
     * @return price The latest price
     */
    function getLatestPrice(address _token) public returns (uint256) {
        return getLatestPriceFromName(addressToName[_token]);
    }

    /**
     * @notice Get latest price
     *
     * @param _policyToken Policy token name
     *
     * @return price USD price of the base token
     */
    function getLatestPriceFromName(string memory _policyToken)
        public
        returns (uint256 price)
    {
        uint256 priceInAVAX;

        // If token0 is WAVAX, use price1Average
        // Else, use price0Average
        priceInAVAX = priceFeeds[_policyToken].priceAverage;

        require(priceInAVAX > 0, "Zero Price");

        // AVAX price, 1e18 scale
        uint256 avaxPrice = basePriceGetter.getLatestPrice("AVAX");

        // Warning: for DCAR we tempararily double the price because the settlement price is 0.165
        //          but we set it as 0.33 (they changed the ido price after this round online)

        // This final price is also multiplied by 1e18
        price = (avaxPrice * priceInAVAX) / 1e18;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative +=
                uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
                timeElapsed;
            // counterfactual
            price1Cumulative +=
                uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
                timeElapsed;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IUniswapV2Pair.sol";

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.13;

import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/TickMath.sol";
import "./interfaces/FixedPoint96.sol";
import "./interfaces/FullMath.sol";

import "./ILBPair.sol";
import "./ILBFactory.sol";
import "./IUniswapV3Factory.sol";
import "../interfaces/IPriceGetter.sol";

import "../util/OwnableWithoutContextUpgradeable.sol";

import "hardhat/console.sol";

contract DexPriceGetterV2 is OwnableWithoutContextUpgradeable {
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant JOE = 0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07;
    address public constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    address public constant JOE_LB_FACTORY =
        0x8e42f2F4101563bF679975178e880FD87d3eFd4e;

    address public constant UNI_V3_FACTORY =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address public constant WOM = 0x7B5EB3940021Ec0e8e463D5dBB4B7B09a89DDF96;

    uint256 public constant WOM_USDT_FEE = 3000;

    uint256 public constant GMX_WETH_FEE = 3000;
    uint256 public constant GNS_WETH_FEE = 3000;
    uint256 public constant LDO_WETH_FEE = 3000;
    uint256 public constant ARB_WETH_FEE = 500;

    // Base price getter to transfer the price into USD
    IPriceGetter public basePriceGetter;

    struct LBPriceFeedInfo {
        uint64 lastCumulativeId;
        uint256 lastTimestamp;
        uint256 price;
    }
    mapping(address => LBPriceFeedInfo) public lbPriceFeeds;

    function initialize(address _priceGetter) public initializer {
        __Ownable_init();

        basePriceGetter = IPriceGetter(_priceGetter);
    }

    function getLatestPrice(address _token) external returns (uint256) {
        if (_token == JOE) {
            if (block.timestamp - lbPriceFeeds[_token].lastTimestamp <= 3600)
                return lbPriceFeeds[_token].price;
            else return samplePriceFromLB(_token);
        } else return samplePriceFromUniV3(_token);
    }

    function getSqrtTwapX96(
        address uniswapV3Pool,
        uint32 twapInterval
    ) public view returns (uint160 sqrtPriceX96) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool)
                .observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24(
                    uint24(
                        uint32(
                            uint56((tickCumulatives[1] - tickCumulatives[0]))
                        ) / twapInterval
                    )
                )
            );
        }
    }

    function getPriceX96FromSqrtPriceX96(
        uint160 sqrtPriceX96
    ) public pure returns (uint256 priceX96) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function samplePriceFromUniV3(address _token) public returns (uint256) {
        uint256 fee = _token == ARB ? ARB_WETH_FEE : 3000;

        address pool;

        if (_token == WOM) {
            pool = IUniswapV3Factory(UNI_V3_FACTORY).getPool(WOM, USDT, 3000);
        } else {
            pool = IUniswapV3Factory(UNI_V3_FACTORY).getPool(
                _token,
                WETH,
                uint24(fee)
            );
        }

        uint256 priceX96 = getPriceX96FromSqrtPriceX96(
            getSqrtTwapX96(pool, 3600)
        );

        uint256 ethPrice = basePriceGetter.getLatestPrice(WETH);
    }

    function samplePriceFromLB(address _token) public returns (uint256) {
        ILBFactory.LBPairInformation memory pairInfo = ILBFactory(
            JOE_LB_FACTORY
        ).getLBPairInformation(
                IERC20(_token),
                IERC20(WETH),
                _getLBPairBinStep(_token)
            );

        address pair = address(pairInfo.LBPair);

        (uint64 cumulativeId, , ) = ILBPair(pair).getOracleSampleAt(
            uint40(block.timestamp)
        );

        LBPriceFeedInfo storage lbPriceFeed = lbPriceFeeds[_token];

        if (lbPriceFeed.lastTimestamp == 0) {
            lbPriceFeed.lastTimestamp = block.timestamp;
            lbPriceFeed.lastCumulativeId = cumulativeId;
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lbPriceFeed.lastTimestamp;

        console.log("timeElapsed: %s", timeElapsed);
        console.log("cumulativeId: %s", cumulativeId);
        console.log("lastCumulativeId: %s", lbPriceFeed.lastCumulativeId);

        uint256 averageId = uint256(
            cumulativeId - lbPriceFeed.lastCumulativeId
        ) / timeElapsed;

        console.log("averageId: %s", averageId);

        uint256 price = ILBPair(pair).getPriceFromId(uint24(averageId));

        console.log("price: %s", price);

        lbPriceFeed.price = (price * 1e18) / 2 ** 128;
        lbPriceFeed.lastCumulativeId = cumulativeId;
        lbPriceFeed.lastTimestamp = block.timestamp;

        uint256 ethPrice = basePriceGetter.getLatestPrice(WETH);
        uint256 finalPrice = (ethPrice * price) / 1e18;

        return finalPrice;
    }

    function _getLBPairBinStep(
        address _token
    ) internal pure returns (uint256 binStep) {
        if (_token == JOE) {
            binStep = 20;
        } else revert("Wrong token");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function observe(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    function getSqrtRatioAtTick(
        int24 tick
    ) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(
        uint160 sqrtPriceX96
    ) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
            "R"
        );
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24(
            (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
        );
        int24 tickHi = int24(
            (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
        );

        tick = tickLow == tickHi
            ? tickLow
            : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = uint256(-int256(denominator) & int256(denominator));
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILBPair {
    function getOracleSampleAt(
        uint40 lookupTimestamp
    )
        external
        view
        returns (
            uint64 cumulativeId,
            uint64 cumulativeVolatility,
            uint64 cumulativeBinCrossed
        );

    function getPriceFromId(uint24 id) external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILBPair.sol";

interface ILBFactory {
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    function getLBPairInformation(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 binStep
    )
        external
        view
        returns (LBPairInformation memory lbPairInformation);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IERC20Decimals.sol";

contract MockExchange {
    constructor() {}

    function getAmountsOut(uint256 _amount, address[] memory _path) external view returns(uint256[] memory amountsOut) {
        amountsOut = new uint256[](_path.length);

        uint256 decimalDiff = IERC20Decimals(_path[0]).decimals() -
            IERC20Decimals(_path[1]).decimals();

        uint256 amountOut = _amount / 10**decimalDiff;

        amountsOut[0] = _amount;
        amountsOut[1] = amountOut;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        require(block.timestamp <= deadline);

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        // path[0] is native token with 18 decimals
        // path[1] is MockUSDC with 6 decimals
        uint256 decimalDiff = IERC20Decimals(path[0]).decimals() -
            IERC20Decimals(path[1]).decimals();

        // E.g. amountIn = 1e18
        //      amountOut = 1e6
        amountOut = amountIn / 10**decimalDiff;

        IERC20(path[1]).transfer(to, amountOut);
    }
}