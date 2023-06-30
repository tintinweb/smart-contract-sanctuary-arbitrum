/**
 * Used to create & manage strategy vaults
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../vault/Vault.sol";
import "../../storage/Strategies.sol";
import "../../storage/Users.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";
import "../triggers/TriggersManager.sol";
import "../../Modifiers.sol";

contract FactoryFacet is Modifiers {
    // ==================
    //      EVENTS
    // ==================
    /**
     * Deployed on strategy deployment
     */
    event VaultCreated(
        address indexed strategyAddress,
        address indexed creator,
        address indexed depositToken,
        bytes constructorArgs
    );

    // ==================
    //     MODIFIERS
    // ==================
    /**
     * Asserts that an inputted address must be a premium user, if an inputted
     * boolean is "false" (if a vault is private)
     */
    modifier noPrivacyForTheWicked(bool isPublic, address requester) {
        require(
            isPublic || UsersStorageLib.getUsersStorage().isPremium[requester],
            "No Privacy For The Wicked"
        );
        _;
    }

    // ==================
    //     METHODS
    // ==================
    /**
     * @notice
     * Create & Deploy A Vault
     * @param seedSteps - The seed steps that run on a deposit trigger
     * @param treeSteps - The tree of steps that run on any of the strategy's triggers
     * @param uprootSteps - The uproot steps that run on a withdrawal trigger
     * @param approvalPairs - A 2D array of [ERC20Token, addressToApprove]. Which will be approved on deployment of the vault
     * @param depositToken - An IERC20 token which is used for deposits into the vault
     * @param isPublic - The visibility/privacy of this vault. Private only allowed for premium users!!
     */
    function createVault(
        bytes[] memory seedSteps,
        bytes[] memory treeSteps,
        bytes[] memory uprootSteps,
        address[2][] memory approvalPairs,
        Trigger[] memory triggers,
        IERC20 depositToken,
        bool isPublic
    )
        external
        noPrivacyForTheWicked(isPublic, msg.sender)
        returns (Vault createdVault)
    {
        /**
         * Assert that the triggers & triggers settings lengths math
         */

        /**
         * Begin by deploying the vault contract (With the msg.sender of this call as the creator)
         */
        createdVault = new Vault(
            seedSteps,
            treeSteps,
            uprootSteps,
            approvalPairs,
            depositToken,
            isPublic,
            msg.sender
        );

        emit VaultCreated(
            address(createdVault),
            msg.sender,
            address(depositToken),
            abi.encode(
                seedSteps,
                treeSteps,
                uprootSteps,
                approvalPairs,
                depositToken,
                isPublic,
                msg.sender
            )
        );

        /**
         * Push the strategy to the storage array
         */
        StrategiesStorageLib.retreive().strategies.push(createdVault);

        StrategiesStorageLib.retreive().strategiesState[
            createdVault
        ] = StrategyState(true, 0);

        // Register all of the triggers for the strategy
        TriggersManagerFacet(address(this)).registerTriggers(
            triggers,
            createdVault
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import {SafeERC20} from "../libs/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "./VaultExecution.sol";

/**
 * The part of the vault contract containing various
 * state (storage) variables and immutables.
 *
 * This is the root contract being inherited
 */

contract Vault is VaultExecution {
    // LIBS
    using SafeERC20 for IERC20;

    // =====================
    //      CONSTRUCTOR
    // =====================
    /**
     * @notice
     * The constructor,
     * accepts all of the different configs for this strategy contract
     * @param steps - A linked list of YCStep. a YCStep specifies the encoded FunctionCall of a step,
     * the indexes of it's children within the array, and an optional array of "conditions".
     * In which case it means the step is a conditional block.
     * @param seedSteps - A linked list of YCStep like the above, this time,
     * for the seed strategy (i.e, the strategy that runs on deposit)
     * @param uprootSteps - Another linked list of YCStep,
     * but for the "Uprooting" strategy (the reverse version of the strategy)
     * @param approvalPairs - A 2D array of addresses -
     * at index 0 there is an ERC20-compatible token contract address, and at index 1 there is a
     * contract address to approve. This is in order to iterate over and pre-approve all addresses required.
     * @param depositToken - The token of this vault that users deposit into here, as an address
     *
     * @param ispublic - Whether the vault is publicly accessible or not
     */
    constructor(
        bytes[] memory seedSteps,
        bytes[] memory steps,
        bytes[] memory uprootSteps,
        address[2][] memory approvalPairs,
        IERC20 depositToken,
        bool ispublic,
        address creator
    )
        VaultState(
            seedSteps,
            steps,
            uprootSteps,
            approvalPairs,
            depositToken,
            ispublic,
            creator
        )
    {}

    // ==============================
    //     PUBLIC VAULT METHODS
    // ==============================

    /**
     * @notice
     * Request A Deposit Into The Vault
     * @param amount - The amount of the deposit token to deposit
     */
    function deposit(
        uint256 amount
    ) external payable onlyWhitelistedOrPublicVault {
        // Reserve first memory spot for some value (e.g deposit amount)
        assembly {
            mstore(0x40, add(mload(0x40), 0x20))
        }
        _executeDeposit(
            abi.encode(new bytes[](0)),
            abi.encode(DepositData(amount))
        );
    }

    /**
     * @notice
     * Request to withdraw out of the vault
     * @param amount - the amount of shares to withdraw
     */
    function withdraw(
        uint256 amount
    ) external payable onlyWhitelistedOrPublicVault {
        // Reserve first memory spot for some value (e.g withdrawal % share)
        assembly {
            mstore(0x40, add(mload(0x40), 0x20))
        }
        _executeWithdrawal(
            abi.encode(new bytes[](0)),
            abi.encode(WithdrawalData(amount))
        );
    }

    /**
     * @notice
     * runStrategy()
     * Requests a strategy execution operation,
     * only called by the diamond (i.e from an executor on the diamond)
     */
    function runStrategy() external onlyDiamond {
        // Reserve first memory spot for some value (e.g deposit amount)
        assembly {
            mstore(0x40, add(mload(0x40), 0x20))
        }
        _executeStrategy(abi.encode(new bytes[](0)), new bytes(0));
    }

    /**
     * @notice
     * @dev
     * Only called by Diamond.
     * Internal approval - Used by utility/adapter facets to approve tokens
     * on our behalf, to the diamond (only!), that we could not pre-approve in advanced.
     * Things like LP tokens that may not be known pre-deployment, may require runtime approvals.
     * We of course only allow this to be on the Diamond itself - So anything that wants to implement this
     * must be a facet on the Diamond itself, which is more secure.
     * @param token - Token to approve
     * @param amt - Amount to approve
     */
    function approveDaddyDiamond(
        address token,
        uint256 amt
    ) external onlyDiamond {
        // Cheaper to read msg.sender than YC_DIAMOND, we know it's only the Diamond already here
        IERC20(token).approve(msg.sender, amt);
    }
}

/**
 * Strategies storage for the YC Diamond
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../vault/Vault.sol";

/**
 * Represents a strategy's state/settings
 */
struct StrategyState {
    /**
     * Whether it's registered or not (used to verify if a strategy exists)
     */
    bool registered;
    /**
     * The strategy's gas balance in WEI
     */
    uint256 gasBalanceWei;
}

struct StrategiesStorage {
    /**
     * An array of strategies (to make the mapping iterable)
     */
    Vault[] strategies;
    /**
     * @notice
     * Mapping strategies => their corresponding settings
     */
    mapping(Vault => StrategyState) strategiesState;
}

/**
 * The lib to use to retreive the storage
 */
library StrategiesStorageLib {
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.strategies");

    // Function to retreive our storage
    function retreive() internal pure returns (StrategiesStorage storage s) {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function getStrategyState(
        Vault strategy
    ) internal view returns (StrategyState storage stratState) {
        stratState = retreive().strategiesState[strategy];
    }
}

/**
 * User-related storage for the YC Diamond.
 * Mainly used for analytical purposes of users,
 * and managing premium users
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../vault/Vault.sol";

struct UsersStorage {
    /**
     * Mapping user addresses => Whether they are premium or not
     */
    mapping(address => bool) isPremium;
    /**
     * Mapping user addresses => Their portfolio vaults.
     * Each time someone deposits/withdraws into a vault, it will call a function on our facet and
     * update the user's portfolio accordingly
     */
    mapping(address => Vault[]) portfolios;
}

/**
 * The lib to use to retreive the storage
 */
library UsersStorageLib {
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.users");

    // Function to retreive our storage
    function getUsersStorage() internal pure returns (UsersStorage storage s) {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

    function decimals() external view returns (uint256);
}

/**
 * Facet to register, check on & execute triggers
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../Modifiers.sol";
import "../../../Types.sol";
import "../../storage/TriggersManager.sol";
import "../../storage/Strategies.sol";
import "./automation/Automation.sol";
import "../core/StrategiesViewer.sol";
import {GasManagerStorageLib} from "../../storage/GasManager.sol";
import {BytesLib} from "lib/solidity-bytes-utils/contracts/BytesLib.sol";

contract TriggersManagerFacet is Modifiers {
    // =================
    //      ERRORS
    // =================
    error InsufficientGasBalance();

    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    error TriggerNotReady();

    // =================
    //     MODIFIERS
    // =================

    /**
     * Sponsors a call's gas from a vault's gas balance - When received encoded vault
     * @param encodedVaultRunParams - The vault to take gas from - Encoded
     */
    modifier gasless(bytes calldata encodedVaultRunParams) {
        uint256 startingGas = gasleft();
        // We assume msg.data contains all non-empty bytes, (evm costs 16 gas for non-empty & 4 for empty byte),
        // This is because iterating over all of the bytes and incrementing a cost basis would make the actual calculation
        // cost exponential and thus be not worth it.
        uint256 intrinsicGasCost = 21000 + (msg.data.length * 16);
        (Vault vault, ) = abi.decode(encodedVaultRunParams, (Vault, uint256));
        _; // Marks body of the entire function we are applied to
        console.log("Function Ends, Gas Calc Begins...");
        uint256 leftGas = gasleft();
        // 2300 for ETH .trasnfer()
        uint256 weiSpent = ((startingGas - leftGas + intrinsicGasCost + 2300) *
            tx.gasprice) + GasManagerStorageLib.getAdditionalGasCost();

        StrategyState storage state = StrategiesStorageLib.getStrategyState(
            vault
        );

        console.log("Wei Spent:", weiSpent);

        if (weiSpent > state.gasBalanceWei) revert InsufficientGasBalance();

        state.gasBalanceWei -= weiSpent;

        payable(msg.sender).transfer(weiSpent);
    }

    // =================
    //     FUNCTIONS
    // =================

    // ==========
    //  REGISTER
    // ==========
    /**
     * Register multiple triggers
     * @param triggers - Array of the trigger structs to register
     * @param vault - The strategy address to register the triggers on
     */
    function registerTriggers(
        Trigger[] calldata triggers,
        Vault vault
    ) public onlySelf {
        TriggersManagerStorage
            storage triggersStorage = TriggersManagerStorageLib.retreive();

        for (uint256 i; i < triggers.length; i++) {
            triggersStorage.registeredTriggers[vault].push(
                RegisteredTrigger(
                    triggers[i].triggerType,
                    block.timestamp,
                    60 // TODO: Integrate delays from user end
                )
            );

            if (triggers[i].triggerType == TriggerTypes.AUTOMATION)
                return
                    AutomationFacet(address(this)).registerAutomationTrigger(
                        triggers[i],
                        vault,
                        i
                    );
        }
    }

    // ==========
    //  CHECK
    // ==========
    /**
     * Check all triggers of all strategies
     * @return triggersStatus - 2D Array of booleans, each index is a strategy and has an array of booleans
     * (it's trigger indices, whether it should exec them)
     */
    function checkStrategiesTriggers()
        external
        view
        returns (bool[][] memory triggersStatus)
    {
        Vault[] memory vaults = StrategiesViewerFacet(address(this))
            .getStrategiesList();

        TriggersManagerStorage
            storage triggersStorage = TriggersManagerStorageLib.retreive();

        triggersStatus = new bool[][](vaults.length);

        for (uint256 i; i < vaults.length; i++) {
            Vault vault = vaults[i];

            RegisteredTrigger[] memory registeredTriggers = triggersStorage
                .registeredTriggers[vault];

            bool[] memory vaultTriggersStatus = new bool[](
                registeredTriggers.length
            );

            for (
                uint256 triggerIdx;
                triggerIdx < registeredTriggers.length;
                triggerIdx++
            ) {
                vaultTriggersStatus[triggerIdx] = _checkTrigger(
                    vault,
                    triggerIdx,
                    registeredTriggers[triggerIdx]
                );
            }

            if (vaultTriggersStatus.length > 0)
                triggersStatus[i] = vaultTriggersStatus;
        }
    }

    /**
     * Check a single trigger condition (internal)
     * @param vault - The vault to check
     * @param triggerIdx - The trigger index to check
     * @param trigger - The actual registered trigger
     * @return shouldTrigger
     */
    function _checkTrigger(
        Vault vault,
        uint256 triggerIdx,
        RegisteredTrigger memory trigger
    ) internal view returns (bool shouldTrigger) {
        // The required delay registered for the trigger to run
        if (block.timestamp - trigger.lastStrategyRun < trigger.requiredDelay)
            return false;

        if (trigger.triggerType == TriggerTypes.AUTOMATION)
            return
                AutomationFacet(address(this)).shouldExecuteAutomationTrigger(
                    vault,
                    triggerIdx
                );

        return false;
    }

    // ==========
    //    EXEC
    // ==========

    /**
     * Execute a strategy's trigger with CCIP data
     * @param strategyResponse - Response from CCIP endpoint if request by strategy (otherwise use empty bytes)
     * @param encodedContext - CCIP Extra data (Context of execution - Strategy Index + Trigger Index)
     * ** GasLess - Pays back the gas used **
     */
    function executeStrategyTriggerWithData(
        bytes calldata strategyResponse,
        bytes calldata encodedContext
    ) external gasless(encodedContext) {
        (Vault vault, uint256 strategyTriggerIdx) = abi.decode(
            encodedContext,
            (Vault, uint256)
        );

        _executeTrigger(vault, strategyTriggerIdx, strategyResponse);
    }

    /**
     * Internal function to execute a strategy's trigger
     * @param vault - THe vault to execute a trigger on
     * @param strategyTriggerIdx - Index of the trigger of the strategy mapped to it in storage
     * Note it's external because we want to be able to catch errors here
     */

    function _executeTrigger(
        Vault vault,
        uint256 strategyTriggerIdx,
        bytes memory strategyData
    ) internal {
        try
            TriggersManagerFacet(address(this)).tryExecuteTrigger(
                vault,
                strategyTriggerIdx,
                strategyData
            )
        {} catch (bytes memory revertData) {
            // Only interested in modifying CCIP
            if (bytes4(revertData) != 0x556f1830)
                assembly {
                    revert(revertData, mload(revertData))
                }

            (, string[] memory urls, bytes memory callData, , ) = abi.decode(
                BytesLib.slice(revertData, 4, revertData.length - 4),
                (address, string[], bytes, bytes4, bytes)
            );

            revert OffchainLookup(
                address(this),
                urls,
                callData,
                TriggersManagerFacet.executeStrategyTriggerWithData.selector,
                abi.encode(vault, strategyTriggerIdx)
            );
        }

        TriggersManagerStorageLib
        .retreive()
        .registeredTriggers[vault][strategyTriggerIdx].lastStrategyRun = block
            .timestamp;
    }

    /**
     * Internal function to execute a strategy's trigger
     * @param vault - THe vault to execute a trigger on
     * @param strategyTriggerIdx - Index of the trigger of the strategy mapped to it in storage
     * Note it's external because we want to be able to catch errors here, but shouldnt be called directly
     */
    function tryExecuteTrigger(
        Vault vault,
        uint256 strategyTriggerIdx,
        bytes calldata strategyData
    ) external onlySelf {
        TriggersManagerStorage
            storage triggersStorage = TriggersManagerStorageLib.retreive();

        RegisteredTrigger[] memory registeredTriggers = triggersStorage
            .registeredTriggers[vault];

        RegisteredTrigger memory trigger = registeredTriggers[
            strategyTriggerIdx
        ];

        if (!_checkTrigger(vault, strategyTriggerIdx, trigger))
            revert TriggerNotReady();

        // Switch case
        if (trigger.triggerType == TriggerTypes.AUTOMATION)
            AutomationFacet(address(this)).executeAutomationTrigger(
                vault,
                strategyTriggerIdx,
                strategyData
            );
    }

    // =================
    //     GETTERS
    // =================
    function getVaultTriggers(
        Vault vault
    ) external view returns (RegisteredTrigger[] memory triggers) {
        return TriggersManagerStorageLib.retreive().registeredTriggers[vault];
    }
}

/**
 * A base contract to inherit from which provides some modifiers,
 * using storage from the storage libs.
 *
 * Since libs are not capable of defining modiifers.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./storage/AccessControl.sol";
import "./storage/Strategies.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";

contract Modifiers {
    /**
     * Only allow owner of the diamond to access
     */
    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner(), "ERR: Only Owner");
        _;
    }

    /**
     * Only allow a whitelisted executor
     */
    modifier onlyExecutors() {
        require(
            AccessControlStorageLib.getAccessControlStorage().isWhitelisted[
                msg.sender
            ],
            "ERR: Not Whitelisted Executor"
        );
        _;
    }

    /**
     * Only allow vaults to call some function
     */
    modifier onlyVaults() {
        require(
            StrategiesStorageLib
                .retreive()
                .strategiesState[Vault(msg.sender)]
                .registered,
            "Not A Registered Vault"
        );
        _;
    }

    /**
     * Only allow self to call
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "Only Self");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../libs/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

/**
 * The execution functions for the vault (Internal/Used by YC Diamond)
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import {SafeERC20} from "../libs/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "../vm/VM.sol";
import "./State.sol";
import "./Constants.sol";
import "./VaultUtilities.sol";
import "../diamond/interfaces/IAccessControl.sol";
import "src/Types.sol";
import "forge-std/console.sol";
import "./Schema.sol";

abstract contract VaultExecution is
    YCVM,
    VaultUtilities,
    VaultConstants,
    VaultState
{
    // ===========
    //    LIBS
    // ===========
    using SafeERC20 for IERC20;

    // =================
    //      METHODS
    // =================
    /**
     * @notice
     * executeDeposit()
     * The actual deposit logic
     * @param response - Optional response from OffchainLookup
     * @param encodedDepositData - Encoded DepositData struct, set as extraData in offchain lookups
     */
    function executeDeposit(
        bytes memory response,
        bytes memory encodedDepositData
    ) external onlyWhitelistedOrPublicVault {
        _executeDeposit(response, encodedDepositData);
    }

    function _executeDeposit(
        bytes memory response,
        bytes memory encodedDepositData
    ) internal {
        DepositData memory depositData = abi.decode(
            encodedDepositData,
            (DepositData)
        );

        uint256 amount = depositData.amount;

        if (DEPOSIT_TOKEN.allowance(msg.sender, address(this)) < amount)
            revert InsufficientAllowance();

        // Transfer to us
        DEPOSIT_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        // Increment total shares supply & user's balance
        totalShares += amount;
        balances[msg.sender] += amount;

        assembly {
            // We MSTORE at the deposit amount memory location the deposit amount
            // (may be accessed by commands to determine amount arguments)
            mstore(DEPOSIT_AMT_MEM_LOCATION, amount)
        }

        bytes[] memory cachedOffchainCommands = abi.decode(response, (bytes[]));

        executeStepTree(
            SEED_STEPS,
            cachedOffchainCommands,
            new uint256[](1),
            VaultExecution.executeDeposit.selector,
            encodedDepositData
        );
    }

    /**
     * @notice
     * executeWithdraw()
     * The actual withdraw logic
     * @param response - Optional response from OffchainLookup
     * @param encodedWithdrawalData - Encoded WithdrawalData struct, set as extraData in offchain lookups
     */
    function executeWithdrawal(
        bytes calldata response,
        bytes calldata encodedWithdrawalData
    ) external onlyWhitelistedOrPublicVault {
        _executeWithdrawal(response, encodedWithdrawalData);
    }

    function _executeWithdrawal(
        bytes memory response,
        bytes memory encodedWithdrawalData
    ) internal {
        WithdrawalData memory withdrawalData = abi.decode(
            encodedWithdrawalData,
            (WithdrawalData)
        );

        uint256 amount = withdrawalData.amount;

        if (amount > balances[msg.sender]) revert InsufficientShares();

        balances[msg.sender] -= amount;
        totalShares -= amount;

        uint256 shareOfVaultInPercentage = (totalShares + amount) / amount;

        assembly {
            // We MSTORE at the withdraw share memory location the % share of the withdraw amount of the total vault, times 100
            // (e.g, 100 shares to withdraw, 1000 total shares = 1000 / 100 * 100(%) = 1000 (10% multipled by 100, for safe maths...))
            mstore(
                WITHDRAW_SHARES_MEM_LOCATION,
                mul(shareOfVaultInPercentage, 100)
            )
        }

        uint256 preVaultBalance = DEPOSIT_TOKEN.balanceOf(address(this));

        bytes[] memory cachedOffchainCommands = abi.decode(response, (bytes[]));

        executeStepTree(
            UPROOTING_STEPS,
            cachedOffchainCommands,
            new uint256[](1),
            VaultExecution.executeWithdrawal.selector,
            encodedWithdrawalData
        );

        uint256 debt = DEPOSIT_TOKEN.balanceOf(address(this)) - preVaultBalance;

        DEPOSIT_TOKEN.safeTransfer(msg.sender, debt);
    }

    /**
     * Execute strategy
     */
    function executeStrategy(
        bytes calldata response,
        bytes calldata extraData
    ) external onlyDiamond {
        _executeStrategy(response, extraData);
    }

    function _executeStrategy(
        bytes memory response,
        bytes memory extraData
    ) internal {
        bytes[] memory cachedOffchainCommands = abi.decode(response, (bytes[]));

        executeStepTree(
            STEPS,
            cachedOffchainCommands,
            new uint256[](1),
            VaultExecution.executeStrategy.selector,
            extraData
        );
    }

    // ========================
    //     INTERNAL METHODS
    // ========================
    /**
     * @notice
     * executeStepTree()
     * Accepts a linked-list (array) of YCStep, and a starting index to begin executing.
     * Note this function is recursive - It executes a step, then all of it's children, then all of their children, etc.
     *
     * @param virtualTree - A linked list array of YCSteps to execute
     * @param startingIndices - An array of indicies of the steps to begin executing the tree from
     */
    function executeStepTree(
        bytes[] memory virtualTree,
        bytes[] memory cachedOffchainCommands,
        uint256[] memory startingIndices,
        bytes4 callbackFunction,
        bytes memory actionContext
    ) internal {
        /**
         * Iterate over each one of the starting indices
         */
        for (uint256 i = 0; i < startingIndices.length; i++) {
            uint256 stepIndex = startingIndices[i];

            YCStep memory step = abi.decode(virtualTree[stepIndex], (YCStep));

            /**
             * We first check to see if this step is a callback step.
             */
            if (step.isCallback) {
                // If already got the command, run it
                if (
                    cachedOffchainCommands.length > stepIndex &&
                    bytes32(cachedOffchainCommands[stepIndex]) != bytes32(0)
                )
                    _runFunction(cachedOffchainCommands[stepIndex]);

                    // Revert with OffchainLookup, CCIP read will fetch from corresponding Offchain Action.
                else
                    _requestOffchainLookup(
                        step,
                        stepIndex,
                        cachedOffchainCommands,
                        callbackFunction,
                        actionContext
                    );
            } else if (bytes32(step.func) != bytes32(0))
                _runFunction(step.func);

            executeStepTree(
                virtualTree,
                cachedOffchainCommands,
                step.childrenIndices,
                callbackFunction,
                actionContext
            );
        }
    }

    /**
     * Send a CCIP OffchainLookup request to get a step's data
     * @param step - The original step
     * @param idx - The index of that step
     * @param cachedOffchainCommands - Commands that were already returned by offchain
     * @param callbackSelector - The selector of the function to callback with the new data
     * @param actionContext - ExtraData passed by the action
     */
    function _requestOffchainLookup(
        YCStep memory step,
        uint256 idx,
        bytes[] memory cachedOffchainCommands,
        bytes4 callbackSelector,
        bytes memory actionContext
    ) internal {
        (bytes memory nakedFunc, , ) = _separateCommand(step.func);

        FunctionCall memory originalCall = abi.decode(
            nakedFunc,
            (FunctionCall)
        );

        bytes memory interpretedArgs = interpretCommandsAndEncodeChunck(
            originalCall.args
        );

        string memory offchainActionsUrl = IAccessControlFacet(
            address(YC_DIAMOND)
        ).getOffchainActionsUrl();

        string[] memory urls = new string[](1);
        urls[0] = offchainActionsUrl;

        OffchainActionRequest memory offchainRequest = OffchainActionRequest(
            address(this),
            block.chainid,
            idx,
            cachedOffchainCommands,
            originalCall.target_address,
            originalCall.signature,
            interpretedArgs
        );

        revert OffchainLookup(
            address(this),
            urls,
            abi.encode(offchainRequest),
            callbackSelector,
            actionContext
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// =================
//     ENUMS
// =================
/**
 * Different types of executionable requests. In order to avoid over
 * flexability of the executors, so that they are not able to input completely arbitrary steps data
 */
enum ExecutionTypes {
    SEED,
    TREE,
    UPROOT
}

/**
 * An enum representing all different types of "triggers" that
 * a strategy can register
 */
enum TriggerTypes {
    AUTOMATION
}

//===============================================//
//                   STRUCTS                     //
//===============================================//
/**
 * Struct representing a registered trigger,
 * including the trigger type, and an arbitrary byte which is it's settings
 */
struct Trigger {
    TriggerTypes triggerType;
    bytes extraData;
}
/**
 * @notice
 * @FunctionCall
 * A struct that defines a function call. Is used as a standard to pass on steps' functions, or
 * functions to be used to retreive some return value, as some sort of a dynamic variable that can be
 * pre-encoded & standardized.
 *
 *
 * ----- // @PARAMETERS // -----
 * @param target_address
 * @address -  The target address the function should be called on.
 *
 * @param args
 * @bytes[] - The arguments for the function call, encoded. Should be wrapped inside getArgValue()
 *
 * @param signature
 * @string - The function sig. Can be either external (When function is a dynamic variable),
 * or a YC Classified function (e.g "func_30(bytes[])")
 *
 * @param is_callback
 * @bool - Specifies whether the function is a callback. Callback means it submits an off-chain request, which
 * should stop the current execution context - Which, in turn, may have itself/another process resumed by the request's
 * fullfill operation.
 *
 * @param is_static
 * @bool - Specifies whether the function can be called with staticcall. If true, can save significant (9000) gas.
 *
 * -----------------------------
 */
struct FunctionCall {
    address target_address;
    bytes[] args; // [FunctionCall("getAmount()", args[0xETHTOKEN, ])]
    string signature; // "addLiquidity(uint256,uint256)"
}

/**
 * @notice
 * @YCStep
 * A struct defining a Yieldchain strategy step. Is used to standardized a classification of each one of a strategy's
 * steps. Defining it's function call, as well as it's underlying protocol's details, and it's tokens flows.
 * While this will be used in the strategy's logic (The function calls), it can also be consumed by frontends
 * (which have access to our ABI).
 * ----- // @PARAMETERS // -----
 * @param step_function
 * @FunctionCall, encoded
 * The function to call on this step.
 *
 * @param protocol_details
 * @ProtocolDetails
 * The details of the protocol the function reaches. Consumed by frontends.
 *
 * @param token_flows
 * @TokenFlow[]
 * An array of TokenFlow structs, consumed by frontends.
 *
 * @param childrenIndices
 * @uint256
 * A uint representing the index within the strategy's containers array of the step's children container.
 * -----------------------------
 */
struct YCStep {
    bytes func;
    uint256[] childrenIndices;
    bytes[] conditions;
    bool isCallback;
}

/**
 * @notice
 * A struct representing an operation request item.
 * Action requests (deposits, withdrawals, strategy runs) are not processed immediately, but rather hydrated
 * by an offchain handler, then executed. This is in order to process any offchain computation that may be required beforehand,
 * to avoid any stops mid-run (which can overcomplicate the entire architecutre)
 *
 * @param action - An ExecutionType enum representing the action to complete, handled by a switch case in the router
 * @param initiator - The user address that initiated this queue request
 * @param commandCalldatas - An array specifying hydrated calldatas. If a step is an offchain step, the hydrated calldata would be stored
 * here in the index of it within it's own virtual tree (for instance, a step at index 9 of SEED_STEPS tree, would have it's
 * YC command stored at index 9 here in the commandCalldatas)
 * @param arguments - An arbitrary array of bytes being the arguments, usually would be something like an amount.
 */
struct OperationItem {
    ExecutionTypes action;
    address initiator;
    uint256 gas;
    bytes[] arguments;
    bytes[] commandCalldatas;
    bool executed;
}

struct OffchainActionRequest {
    address initiator;
    uint256 chainId;
    uint256 stepIndex;
    bytes[] cachedOffchainCommands;
    address callTargetAddress;
    string signature;
    bytes args;
}

/**
 * Storage for the triggers manager
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../vault/Vault.sol";

struct RegisteredTrigger {
    TriggerTypes triggerType;
    uint256 lastStrategyRun;
    uint256 requiredDelay;
}

struct TriggersManagerStorage {
    /**
     * Mapping each vault, to registerd triggers
     */
    mapping(Vault => RegisteredTrigger[]) registeredTriggers;
}

/**
 * The lib to use to retreive the storage
 */
library TriggersManagerStorageLib {
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.triggers_manager");

    // Function to retreive our storage
    function retreive()
        internal
        pure
        returns (TriggersManagerStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}

/**
 * Automation Trigger Facet
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Types.sol";
import "../../../../Types.sol";
import "../../../storage/triggers/Automation.sol";

contract AutomationFacet {
    /**
     * Register an automation trigger
     * @param automationTrigger - Trigger struct, type must be AUTOMATION
     * @param vault - Vault address to register on
     * @param triggerIdx - Index of the requested trigger
     */
    function registerAutomationTrigger(
        Trigger calldata automationTrigger,
        Vault vault,
        uint256 triggerIdx
    ) public {
        require(
            automationTrigger.triggerType == TriggerTypes.AUTOMATION,
            "Trigger Type Is Not Automation"
        );

        AutomationStorage storage automationStorage = AutomationStorageLib
            .getAutomationStorage();

        uint256 automationInterval = abi.decode(
            automationTrigger.extraData,
            (uint256)
        );

        automationStorage.scheduledAutomations[vault][
            triggerIdx
        ] = ScheduledAutomation(automationInterval, block.timestamp);
    }

    /**
     * Check if an automation trigger should be executed
     * @param vault - The vault to check on
     * @param triggerIdx - The idx of the trigger
     * @return shouldExecute - Whether you should execute this trigger already
     */
    function shouldExecuteAutomationTrigger(
        Vault vault,
        uint256 triggerIdx
    ) public view returns (bool shouldExecute) {
        shouldExecute = _shouldExecuteAutomationTrigger(vault, triggerIdx);
    }

    /**
     * Execute an automation trigger
     * @param vault - The vault to execute an automation trigger on
     * @param triggerIdx - The index of the trigger
     */
    function executeAutomationTrigger(
        Vault vault,
        uint256 triggerIdx,
        bytes calldata strategyData
    ) public {
        // Sufficient check
        if (!_shouldExecuteAutomationTrigger(vault, triggerIdx)) return;

        // We call executeStrategy with optional pass response data, and extraData is empty (no context needed for run)
        vault.executeStrategy(strategyData, new bytes(0));

        AutomationStorageLib
        .getAutomationStorage()
        .scheduledAutomations[vault][triggerIdx].lastExecutedTimestamp = block
            .timestamp;
    }

    /**
     * Internal function to check the execution condition of the automation
     * @param vault - The vault to check on
     * @param triggerIdx - The idx of the trigger
     * @return shouldExecute - Whether you should execute this trigger already
     */
    function _shouldExecuteAutomationTrigger(
        Vault vault,
        uint256 triggerIdx
    ) internal view returns (bool shouldExecute) {
        AutomationStorage storage automationStorage = AutomationStorageLib
            .getAutomationStorage();

        ScheduledAutomation memory scheduledAutomation = automationStorage
            .scheduledAutomations[vault][triggerIdx];

        shouldExecute =
            block.timestamp - scheduledAutomation.lastExecutedTimestamp >
            scheduledAutomation.interval;
    }

    /**
     * View function (external)
     * get registered automation on vault & index
     * @param vault - Vault to get on
     * @param triggerIdx - Idx of the trigger
     * @return registeredAutomation ScheduledAutomation
     */
    function getRegisteredAutomation(
        Vault vault,
        uint256 triggerIdx
    ) external view returns (ScheduledAutomation memory registeredAutomation) {
        return
            AutomationStorageLib.getAutomationStorage().scheduledAutomations[
                vault
            ][triggerIdx];
    }
}

/**
 * Strategies storage view facet
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../vault/Vault.sol";
import "../../storage/Strategies.sol";
import "../../storage/TriggersManager.sol";
import "../../storage/Users.sol";
import "../../Modifiers.sol";

contract StrategiesViewerFacet is Modifiers {
    // ==================
    //     GETTERS
    // ==================
    function getStrategiesList()
        external
        view
        returns (Vault[] memory strategies)
    {
        strategies = StrategiesStorageLib.retreive().strategies;
    }

    function getStrategyState(
        Vault strategy
    ) external view returns (StrategyState memory strategyState) {
        strategyState = StrategiesStorageLib.retreive().strategiesState[
            strategy
        ];
    }

    function getStrategyGasBalance(
        Vault strategy
    ) external view returns (uint256 vaultGasBalance) {
        vaultGasBalance = StrategiesStorageLib
            .retreive()
            .strategiesState[strategy]
            .gasBalanceWei;
    }

    function getStrategyTriggers(
        Vault strategy
    ) external view returns (RegisteredTrigger[] memory triggers) {
        return
            TriggersManagerStorageLib.retreive().registeredTriggers[strategy];
    }

    function purgeStrategies() external onlyExecutors {
        StrategiesStorageLib.retreive().strategies = new Vault[](0);
    }
}

/**
 * Storage for the gas manager
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../vault/Vault.sol";
import {IGasHook} from "src/gas-hooks/IGasHook.sol";

struct GasManagerStorage {
    /**
     * Current L2 hook, that returns additional gas costs to charge the vault's gas blance,
     * that the usual gasleft() does not include
     */
    IGasHook gasHook;
}

/**
 * The lib to use to retreive the storage
 */
library GasManagerStorageLib {
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.gas_manager");

    // Function to retreive our storage
    function retreive() internal pure returns (GasManagerStorage storage s) {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function getAdditionalGasCost()
        internal
        view
        returns (uint256 additionalWeiCost)
    {
        IGasHook hook = retreive().gasHook;
        if (address(hook) == address(0)) return 0;

        additionalWeiCost = hook.getAdditionalGasCost();
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

/**
 * Storage for managing executors access control
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../vault/Vault.sol";

struct AccessControlStorage {
    /**
     * Owner of the diamond
     */
    address owner;
    /**
     * Iterable mapping for whitelisted executors
     */
    address[] executors;
    mapping(address => bool) isWhitelisted;
    /**
     * The current CCIP gateway URL used for Offchain Actions
     */
    string offchainActionsUrl;
}

/**
 * The lib to use to retreive the storage
 */
library AccessControlStorageLib {
    // ======================
    //       STORAGE
    // ======================
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.access_control");

    // Function to retreive our storage
    function getAccessControlStorage()
        internal
        pure
        returns (AccessControlStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function _setOffchainLookupUrl(string calldata newUrl) internal {
        AccessControlStorage
            storage accessControlStorage = getAccessControlStorage();
        accessControlStorage.offchainActionsUrl = newUrl;
    }

    function _getOffchainLookupUrl()
        internal
        view
        returns (string memory offchainurl)
    {
        offchainurl = getAccessControlStorage().offchainActionsUrl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamond } from "../interfaces/IDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();

error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if(msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }        
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if(functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        if(_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);                
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if(oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }            
            ds.facetAddressAndSelectorPosition[selector] 
            = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        if(_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if(oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if(oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if(oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if(_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }        
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition 
            = ds.facetAddressAndSelectorPosition[selector];
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }
            
            
            // can't remove immutable functions -- functions defined directly in the diamond
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = 
                oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }        
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if(contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.18;

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
pragma solidity ^0.8.18;
import "./Interface.sol";
import "./Opcodes.sol";
import "./Utilities.sol";

contract YCVM is Utilities, IVM, Opcodes {
    // ================
    //    FUNCTIONS
    // ================
    /**
     * @notice
     * The main high-level function used to run encoded FunctionCall's, which are stored on the YCStep's.
     * It uses other internal functions to interpret it and it's arguments, build the calldata & call it accordingly.
     * @param encodedFunctionCall - The encoded FunctionCall struct
     * @return returnVal returned by the low-level function calls
     */
    function _runFunction(
        bytes memory encodedFunctionCall
    ) public override returns (bytes memory returnVal) {
        /**
         * Seperate the FunctionCall command body from the typeflags
         */
        (bytes memory commandBody, bytes1 typeflag, ) = _separateCommand(
            encodedFunctionCall
        );

        /**
         * Assert that the typeflag must be either 0x04, 0x05, or 0x06 (The function call flags)
         */
        require(
            typeflag <= DELEGATECALL_COMMAND_FLAG &&
                typeflag >= STATICCALL_COMMAND_FLAG,
            "ycVM: Invalid Function Typeflag"
        );

        /**
         * Decode the FunctionCall command
         */
        FunctionCall memory decodedFunctionCall = abi.decode(
            commandBody,
            (FunctionCall)
        );

        /**
         * Execute it & assign to the return value
         */
        returnVal = _execFunctionCall(decodedFunctionCall, typeflag);
    }

    /**
     * _execFunctionCall()
     * Accepts a decoded FunctionCall struct, and a typeflag. Builds the calldata,
     * calls the function on the target address, and returns the return value.
     * @param func - The FunctionCall struct which represents the call to make
     * @param typeflag - The typeflag specifying the type of call STATICCALL, CALL, OR DELEGATECALL
     * @return returnVal - The return value of the function call
     */
    function _execFunctionCall(
        FunctionCall memory func,
        bytes1 typeflag
    ) internal returns (bytes memory returnVal) {
        /**
         * @notice
         * First check is to always see if the typeflag is equal to the INTERNAL_LOAD_FLAG,
         * which would mean we need to manually MLOAD at the first item in the function's arguments (supposed to be a pointer).
         * This is because a caller may want to access an in-memory state variable - And when making low level calls, the memory stack
         * is reset on the new call (a new one is created), which means the current "inline" or "internal" memory stack would not
         * be accessible.
         * Note that it only supports fixed-length variables for now
         */
        if (typeflag == INTERNAL_LOAD_FLAG) {
            /**
             * The standard for an internal load is, there is a single
             * arg which is the ABI encoded pointer. We get it's raw value (2x 0x00 typeflags + 32 byte ptr)
             */
            bytes memory extendedPtr = func.args[0];

            // We load the word using assembly and return an ABI encoded version of this value
            bytes32 loadedWord;
            assembly {
                // We assign to the return value the mloaded variable (location of raw + 34 (32 to skip ref length, 2 to skip typeflags))
                loadedWord := mload(mload(add(extendedPtr, 34)))
            }

            returnVal = abi.encode(loadedWord);
            return returnVal;
        }

        /**
         * First, build the calldata for the function & it's args
         */
        bytes memory callData = _buildCalldata(func);

        /**
         * If the target address equals to the 0 address, we assume the intention
         * was to call ourselves - and we thus do so
         */
        address targetAddress = func.target_address == address(0)
            ? address(this)
            : func.target_address;

        /**
         * Switch case for the function call type
         */

        // STATICALL
        if (typeflag == STATICCALL_COMMAND_FLAG) {
            (, returnVal) = targetAddress.staticcall(callData);
            return returnVal;
        }
        // CALL
        if (typeflag == CALL_COMMAND_FLAG) {
            (, returnVal) = targetAddress.call(callData);
            return returnVal;
        }
        // DELEGATECALL
        if (typeflag == DELEGATECALL_COMMAND_FLAG) {
            (, returnVal) = targetAddress.delegatecall(callData);
            return returnVal;
        }
    }

    /**
     * _buildCalldata()
     * Builds a complete calldata from a FunctionCall struct
     * @param _func - The FunctionCall struct which represents the function we shall construct a calldata for
     * @return constructedCalldata - A complete constructed calldata which can be used to make the desired call
     */
    function _buildCalldata(
        FunctionCall memory _func
    ) internal returns (bytes memory constructedCalldata) {
        /**
         * Get the 4 bytes keccak256 hash selector of the signature (used at the end to concat w the calldata body)
         */
        bytes4 selector = bytes4(keccak256(bytes(_func.signature)));

        /**
         * @notice
         * We call the interpretCommandsAndEncodeChunck() function with the function's array of arguments
         * (which are YC commands), which will:
         *
         * 1) Interpret each argument using the _separateAndGetCommandValue() function
         * 2) Encode all of them as an ABI-compatible chunck, which can be used as the calldata
         *
         * And assign to the constructed calldata the concatinated selector + encoded chunck we recieve
         */
        constructedCalldata = bytes.concat(
            selector,
            interpretCommandsAndEncodeChunck(_func.args)
        );
    }

    /**
     * _separateAndGetCommandValue()
     * Separate & get a command/argument's actual value, by parsing it, and potentially
     * using it's return value (if a function call)
     * @param command - the full encoded command, including typeflags
     * @return interpretedValue - The interpreted underlying value of the argument
     * @return typeflag - The typeflag of the underlying value
     */
    function _separateAndGetCommandValue(
        bytes memory command
    ) internal returns (bytes memory interpretedValue, bytes1 typeflag) {
        // First, seperate the command/variable from it's typeflag & return var typeflag
        bytes1 retTypeFlag;
        (interpretedValue, typeflag, retTypeFlag) = _separateCommand(command);

        /**
         * Then, check to see if it's either one of the CALL typeflags, to determine
         * whether it's a function call or not
         */
        if (typeflag >= STATICCALL_COMMAND_FLAG) {
            /*
             * If it is, it means the body is an encoded FunctionCall struct.
             * We call the internal _execFunction() function with our command body & typeflag,
             * in order to execute this function and retreive it's return value - And then use the
             * usual _getCommandValue() function to parse it's primitive value, with the return typeflag.
             * We also assign to the typeflag the command's returnTypeFlag that we got when separating.
             */
            // Decode it first
            FunctionCall memory functionCallCommand = abi.decode(
                interpretedValue,
                (FunctionCall)
            );

            /**
             * To the interpretedValue variable, assign the interpreted result
             * of the return value of the function call. And to the typeflag, assign
             * the returned typeflag (which should be the typeflag of the underlying return value)
             * Note that, to avoid any doubts -
             * The underlying typeflag in this case should always just be the return type flag of the function call,
             * that we input into the function. It's just the uniform API of the function that makes it more efficient
             * to receive it from this call anyway.
             *
             * The additional interpretation is done in order to comply the primitive underlying return value
             * with the rest of the system (i.e chunck/calldata encoder). For example, if the function returns
             * a ref variable - We need to remove it's initial 32-byte offset pointer in order for it to
             * be compliant with the calldata builder.
             */

            return (
                _getCommandValue(
                    _execFunctionCall(functionCallCommand, typeflag),
                    retTypeFlag,
                    retTypeFlag
                )
            );
        }

        /**
         * At this point, if it's not a FunctionCall - It is another command type.
         *
         * We call the _getCommandValue() function with our command body & typeflag,
         * which will interpret it and return the underlying value, along with the underlying typeflag.
         */
        (interpretedValue, typeflag) = _getCommandValue(
            interpretedValue,
            typeflag,
            retTypeFlag
        );
    }

    /**
     * @notice
     * _getCommandValue
     * Accepts a primitive value, a typeflag - and interprets it
     * @param commandVariable - A command variable without the typeflags
     * @param typeFlag - The typeflag
     */

    function _getCommandValue(
        bytes memory commandVariable,
        bytes1 typeflag,
        bytes1 retTypeflag
    ) internal returns (bytes memory parsedPrimitiveValue, bytes1 typeFlag) {
        /**
         * We initially set parsed primitive value and typeFlag to the provided ones
         */
        parsedPrimitiveValue = commandVariable;
        typeFlag = typeflag;

        /**
         * If the typeflag is VALUE_VAR_FLAG, it's a value variable and we just return it (simplest case)
         */
        if (typeflag == VALUE_VAR_FLAG) return (parsedPrimitiveValue, typeflag);

        /**
         * If the typeflag is REF_VAR_FLAG, it's a ref variable (string, array...), we parse and return it
         */
        if (typeflag == REF_VAR_FLAG) {
            return (_removePrependedBytes(parsedPrimitiveValue, 32), typeflag);
        }

        /**
         * If the typeflag is RAW_REF_VAR_FLAG, then it means it's a VALUE_VAR that needs to be ABI encoded, in order to be interpreted as a ref var
         */
        if (typeflag == RAW_REF_VAR_FLAG)
            return (
                _removePrependedBytes(abi.encode(parsedPrimitiveValue), 32),
                REF_VAR_FLAG
            );

        /**
         * If the typeflag equals to the commands array flag, we call the interpretCommandsArray() function,
         * which will iterate over each item, parse it, and in addition, have some more utility parsings
         * depending on it's typeflag (e.g appending/not appending additional length argument, etc).
         *
         * We also return the return typeflag as the typeflag here.
         */
        if (
            typeflag == COMMANDS_LIST_FLAG || typeflag == COMMANDS_REF_ARR_FLAG
        ) {
            return (
                interpretCommandsArr(parsedPrimitiveValue, typeflag),
                retTypeflag
            );
        }
    }

    /**
     * @notice
     * interpretCommandsAndEncodeChunck
     * Accepts an array of YC commands - interprets each one of them, then encodes an ABI-compatible chunck of bytes,
     * corresponding of all of these arguments (account for value & ref variables)
     * @param ycCommands - an array of yc commands to interpret
     * @return interpretedEncodedChunck - A chunck of bytes which is an ABI-compatible encoded version
     * of all of the interpreted commands
     */
    function interpretCommandsAndEncodeChunck(
        bytes[] memory ycCommands
    ) internal returns (bytes memory interpretedEncodedChunck) {
        /**
         * We begin by getting the amount of all ref variables,
         * in order to instantiate the array.
         *
         * Note that we are looking at the RETURN typeflag of the command at idx 1,
         * and we're doing it since a command may be flagged as some certain type in order to be parsed correctly,
         * but the end result, the underlaying value we will be getting from the parsing iteration is different.
         * For example, dynamic-length commands arrays (dynamic-length arrays which are made up of YC commands)
         * are flagged as 0x03 in order to be parsed in a certain way, yet at the end we're supposed to get a
         * reguler dynamic flag from the parsing (Since that is what the end contract expects,
         * a dynamic-length argument which is some array).
         * This means that for a ref variable to be flagged correctly, it's return type need to be flagged
         * also as REF_VAR_FLAG (0x01)
         */
        uint256 refVarsAmt = 0;
        for (uint256 i = 0; i < ycCommands.length; i++) {
            if (
                ycCommands[i][1] == REF_VAR_FLAG ||
                ycCommands[i][1] == RAW_REF_VAR_FLAG
            ) ++refVarsAmt;
        }

        /**
         * Will save the ref variables' body values/data here
         */
        bytes[] memory refVars = new bytes[](refVarsAmt);

        /**
         * The indexes of the ref variables' offset pointers
         */
        uint256[] memory refVarsIndexes = new uint256[](refVarsAmt);

        /**
         * Keep a uint in order to track the current free idx in the array (cannot push to mem arrays in solidity)
         */
        uint256 freeRefVarIndexPtr = 0;

        /**
         * Iterate over each one of the ycCommands,
         * call the _separateAndGetCommandValue() function on them, which returns both the value and their typeflag.
         */
        for (uint256 i = 0; i < ycCommands.length; i++) {
            /**
             * Get the value of the argument and it's underlying typeflag
             */
            (
                bytes memory argumentValue,
                bytes1 typeflag
            ) = _separateAndGetCommandValue(ycCommands[i]);

            /**
             * Assert that the typeflag must either be a value or a ref variable.
             * At this point, the argument should have been interpreted/parsed up until the point where
             * it's either a ref or a value variable.
             */
            require(typeflag < 0x02, "typeflag must < 2 after parsing");

            /**
             * If it's a value variable, we simply concat the existing chunck with it
             */
            if (typeflag == VALUE_VAR_FLAG)
                interpretedEncodedChunck = bytes.concat(
                    interpretedEncodedChunck,
                    argumentValue
                );

                /**
                 * Otherwise, we process it as a ref variable
                 */
            else {
                /**
                 * We save the current chunck length as the index of the 32 byte pointer of this ref variable,
                 * in our array of refVarIndexes
                 */
                refVarsIndexes[freeRefVarIndexPtr] = interpretedEncodedChunck
                    .length;

                /**
                 * We then append an empty 32 byte placeholder at that index on the chunck
                 * ("mocking" what would have been the offset pointer)
                 */
                interpretedEncodedChunck = bytes.concat(
                    interpretedEncodedChunck,
                    new bytes(32)
                );

                /**
                 * We then, at the same index as we saved the chunck pointer's index,
                 * save the parsed value of the ref argument (it was parsed to be just the length + data
                 * by the getCommandValue() function, it does not include the default prepended offset pointer now).
                 */
                refVars[freeRefVarIndexPtr] = argumentValue;

                // Increment the free index pointer of the dynamic variables
                ++freeRefVarIndexPtr;
            }
        }

        /**
         * @notice,
         * at this point we have iterated over each command.
         * The value arguments were concatinated with our chunck,
         * whilst the ref variables have been replaced with an empty 32 byte placeholder at their index,
         * their values & the indexes of their empty placeholders were saved into our arrays.
         *
         * We now perform an additional iteration over these arrays, where we append the
         * ref variables to the end of the encoded chunck, save that new index of where we appended it,
         * go back to the index of the corresponding empty placeholder, and replace it with a pointer to our new index.
         *
         * the EVM, when accepting this chunck as calldata, will expect this memory pointer at the index, which, points
         * to where our variable is located in terms of offset since the beginning of the chunck
         */
        for (uint256 i = 0; i < refVars.length; i++) {
            // Shorthand for the index of our placeholder pointer
            uint256 index = refVarsIndexes[i];

            // The new index/pointer
            uint256 newPtr = interpretedEncodedChunck.length;

            // Go into assembly (much cheaper & more conveient to just mstore the 32 byte word)
            assembly {
                mstore(add(add(interpretedEncodedChunck, 0x20), index), newPtr)
            }

            /**
             * Finally, concat the existing chunck with our ref variable's data
             * (At what would now be stored in the original index as the offset pointer)
             */
            interpretedEncodedChunck = bytes.concat(
                interpretedEncodedChunck,
                refVars[i]
            );
        }
    }

    /**
     * interpretCommandsArr
     * @param ycCommandsArr - An encoded dynamic-length array of YC commands
     * @param typeflag - The typeflag of the array command. This may be COMMANDS_LIST or COMMANDS_REF_ARR,
     * which we act differently upon
     * @return interpretedArray - The interpreted command as a chunck,
     * which should directly be inputted into external calldata.
     */
    function interpretCommandsArr(
        bytes memory ycCommandsArr,
        bytes1 typeflag
    ) internal returns (bytes memory interpretedArray) {
        /**
         * We begin by decoding the encoded array into a bytes[]
         */
        bytes[] memory decodedCommandsArray = abi.decode(
            ycCommandsArr,
            (bytes[])
        );

        /**
         * We then call the interpretCommandsAndEncodeChunck() function with our array of YC commands,
         * which will interpret each command, and encode it into a single chunck.
         */
        interpretedArray = interpretCommandsAndEncodeChunck(
            decodedCommandsArray
        );

        /**
         * @notice
         * We check to see our provided typeflag,
         * which is supposed to be the typeflag of this command (the array of commands as a whole).
         *
         * If the typeflag is a COMMANDS_REF_ARR_FLAG,
         * this means we need to concat the length of the array to the chunck (because it's a dynamic-length array).
         * Otherwise, it is either a fixed-length array, or a struct. In which case, we do not append any length.
         *
         * Do note that, in neither cases, we append an offset pointer. The calldata builder expects
         * a "naked" value ((optional length) + data), and manages the offset pointers itself.
         */
        if (typeflag == COMMANDS_REF_ARR_FLAG) {
            interpretedArray = bytes.concat(
                abi.encode(decodedCommandsArray.length),
                interpretedArray
            );
        }
    }
}

/**
 * State for the vault
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import {IERC20} from "../interfaces/IERC20.sol";
import "./AccessControl.sol";

abstract contract VaultState is AccessControl {
    // =====================
    //      CONSTRUCTOR
    // =====================
    /**
     * @notice
     * The constructor,
     * accepts all of the different configs for this strategy contract
     * @param steps - A linked list of YCStep. a YCStep specifies the encoded FunctionCall of a step,
     * the indexes of it's children within the array, and an optional array of "conditions".
     * In which case it means the step is a conditional block.
     * @param seedSteps - A linked list of YCStep like the above, this time,
     * for the seed strategy (i.e, the strategy that runs on deposit)
     * @param uprootSteps - Another linked list of YCStep,
     * but for the "Uprooting" strategy (the reverse version of the strategy)
     * @param approvalPairs - A 2D array of addresses -
     * at index 0 there is an ERC20-compatible token contract address, and at index 1 there is a
     * contract address to approve. This is in order to iterate over and pre-approve all addresses required.
     * @param depositToken - The token of this vault that users deposit into here, as an address
     *
     * @param ispublic - Whether the vault is publicly accessible or not
     */
    constructor(
        bytes[] memory seedSteps,
        bytes[] memory steps,
        bytes[] memory uprootSteps,
        address[2][] memory approvalPairs,
        IERC20 depositToken,
        bool ispublic,
        address creator
    ) AccessControl(creator, msg.sender) {
        /**
         * @dev We set the immutable set of steps, seed steps, and uproot steps
         */
        STEPS = steps;
        SEED_STEPS = seedSteps;
        UPROOTING_STEPS = uprootSteps;

        /**
         * @dev We set the depositToken immutable variable
         */
        DEPOSIT_TOKEN = depositToken;

        /**
         * @dev
         * We set the vault's initial privacy
         */
        isPublic = ispublic;

        /**
         * @dev We iterate over each approval pair and approve them as needed.
         */
        for (uint256 i = 0; i < approvalPairs.length; i++) {
            address addressToApprove = approvalPairs[i][1];
            addressToApprove = addressToApprove == address(0)
                ? msg.sender // The diamond
                : addressToApprove;

            IERC20(approvalPairs[i][0]).approve(
                addressToApprove,
                type(uint256).max
            );
        }

        /**
         * @dev We also add mods and admin permission to the creator
         */
        admins[creator] = true;
        mods[creator] = true;
        whitelistedUsers[creator] = true;

        // save diamond address in a hash, to be adapters-compatible
        bytes32 diamondStorageNamespace = keccak256(
            "adapters.yieldchain_diamond"
        );
        assembly {
            sstore(diamondStorageNamespace, caller())
        }
    }

    // =====================
    //      IMMUTABLES
    // =====================

    /**
     * @dev The deposit token of the vault
     */
    IERC20 public immutable DEPOSIT_TOKEN;

    /**
     * @notice
     * @dev
     * A linked list containing the tree of (encoded) steps to execute on the main triggers
     */
    bytes[] internal STEPS;

    /**
     * @dev Just as the above -
     * A linked list of encoded steps, but for the seed strategy (runs on deposit, i.e initial allocations)
     */
    bytes[] internal SEED_STEPS;

    /**
     * @dev Another linked list of steps,
     * but for the "uprooting" strategy (A "reverse" version of the strategy, executed on withdrawals)
     */
    bytes[] internal UPROOTING_STEPS;

    // ==============================
    //           STORAGE
    // ==============================
    /**
     * @notice
     * The total amount of shares of this vault, directly correlated with deposit tokens
     * 1 token deposited += totalShares(1)
     * 1 token withdrawan -= totalShares(1)
     */
    uint256 public totalShares;

    /**
     * @notice
     * Mapping user addresses to their corresponding balances of vault shares
     */
    mapping(address => uint256) public balances;

    // =====================
    //        GETTERS
    // =====================
    function getVirtualStepsTree(
        ExecutionTypes executionType
    ) public view returns (bytes[] memory) {
        if (executionType == ExecutionTypes.SEED) return SEED_STEPS;
        if (executionType == ExecutionTypes.TREE) return STEPS;
        if (executionType == ExecutionTypes.UPROOT) return UPROOTING_STEPS;
        revert();
    }
}

/**
 * Utility constants for the vault
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract VaultConstants {
    /**
     * Constant memory location for where user's withdraw shares are stored in memory
     */
    uint256 internal constant WITHDRAW_SHARES_MEM_LOCATION =
        0x00000000000000000000000000000000000000000000000000000000000000000080;
    /**
     * Constant memory location for where user's deposit amount is stored in memory
     */
    uint256 internal constant DEPOSIT_AMT_MEM_LOCATION =
        0x00000000000000000000000000000000000000000000000000000000000000000080;
}

/**
 * Utilities used by the vault contract
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../vm/VM.sol";

import "./Schema.sol";
import {IERC20} from "../interfaces/IERC20.sol";

abstract contract VaultUtilities is VaultTypes, YCVM {
    // ===================
    //     FUNCTIONS
    // ===================
    /**
     * @notice
     * getInvestmentAmount()
     * A standard function which is used to call some balance/position getter,
     * and divise it by a divisor.
     * @param amt - THe initial amount to divise
     * @param divisor - A divisor which is meant to be x100 larger than it actually is, to support uints (i.e, a divisor of 3.3 will be 330)
     */
    function getInvestmentAmount(
        uint256 amt,
        uint256 divisor
    ) public pure returns (uint256 investmentAmount) {
        return (amt * 100) / divisor;
    }

    /**
     * @notice
     * balanceOf
     * Accepts an ERC20 token address, returns balance of the vault on it
     * @param token - Address of the ERC20 token
     * @return erc20Balance - The balance of the vault on that ERC20 token
     */
    function balanceOf(
        address token
    ) public view returns (uint256 erc20Balance) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice
     * _determineConditions()
     * Accepts an array of YCStep's, which are meant to be the conditional step's children.
     * It attempts to execute their YC commands in order - Once one resolves to true, it returns their index + 1.
     * Otherwise, it returns 0 (indiciating none went through). The index is +1'ed so that we can use the 0 index as a nullish indicator,
     * where none of the conditions resolved to true.
     * @param conditions - An array of encoded YC steps, the conditions to execute
     */
    function _determineConditions(
        bytes[] memory conditions
    ) internal returns (uint256) {
        for (uint256 i; i < conditions.length; i++) {
            /**
             * Decode the condition to a YC step
             */
            YCStep memory conditionalStep = abi.decode(conditions[i], (YCStep));

            /**
             * Attempt to execute the condition's complex YC command,
             * if it resolves to true, we return it's index,
             * otherwise, we continue
             */
            if (abi.decode(_runFunction(conditionalStep.func), (bool)))
                return i + 1;
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAccessControlFacet {
    function getOffchainActionsUrl()
        external
        view
        returns (string memory offchainActionsUrl);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
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

/**
 * Contains all different events, structs, enums, etc of the vault
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../Types.sol";

abstract contract VaultTypes {
    // =====================
    //        EVENTS
    // =====================
    /**
     * Deposit
     * Emitted when a deposit happens into the vault
     * @param sender - The user that deposited
     * @param amount - The amount that was deposited
     */
    event Deposit(address indexed sender, uint256 indexed amount);

    /**
     * Withdraw
     * Emitted when a withdrawal finallizes from the vault
     * @param receiver - The user who made the withdraw
     * @param amount - The amount that was withdrawn
     */
    event Withdraw(address indexed receiver, uint256 indexed amount);

    // =====================
    //        ERRORS
    // =====================
    /**
     * Insufficient allownace is thrown when a user attempts to complete an operation (deposit),
     * but has not approved this vault contract for enough tokens
     */
    error InsufficientAllowance();

    /**
     * Insufficient shares is thrown when a user attempts to withdraw an amount of tokens that they do not own.
     */
    error InsufficientShares();

    /**
     * When there is insufficient gas prepayance (msg.value)
     */
    error InsufficientGasPrepay();

    /**
     * When we execute a callback step, there's no calldata hydrated for it and we are on mainnet
     */
    error NoOffchainComputedCommand(uint256 stepIndex);

    /**
     * CCIP Offchain Loockup
     */
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    // =====================
    //        TYPES
    // =====================
    struct WithdrawalData {
        uint256 amount;
    }

    struct DepositData {
        uint256 amount;
    }
}

/**
 * Types for the Automation facet
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct ScheduledAutomation {
    uint256 interval;
    uint256 lastExecutedTimestamp;
}

/**
 * Storage For The Automation Facet
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../vault/Vault.sol";
import "../../facets/triggers/automation/Types.sol";

struct AutomationStorage {
    /**
     * Mapping each registered strategy to a trigger idx to an ScheduledAutomation struct
     */
    mapping(Vault => mapping(uint256 => ScheduledAutomation)) scheduledAutomations;
}

/**
 * The lib to use to retreive the storage
 */
library AutomationStorageLib {
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.triggers.automation");

    // Function to retreive our storage
    function getAutomationStorage()
        internal
        pure
        returns (AutomationStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IGasHook
 * @author Ofir Smolinsky
 * @notice Defines an interface for a gas hook, simply returns all additional WEI that should be paid
 * by a vault (L2's specifically have different calcs for htat)
 */
interface IGasHook {
    function getAdditionalGasCost() external view returns (uint256 gasLeft);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {    

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVM {
    function _runFunction(
        bytes memory encodedFunctionCall
    ) external returns (bytes memory returnVal);
}

/**
 * A bunch of simple functions, reimplementing native opcodes or solidity features
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Opcodes {
    /**
     * self()
     * get own address
     * @return ownAddress
     */
    function self() public view returns (address ownAddress) {
        ownAddress = address(this);
    }

    /**
     * encodeWordAtIndex()
     * @param arg - The original arg to extract from
     * @param idx - The index of the word to extract (starts at 0 for first word)
     * @return extractedWord - 32 byte at the index
     */
    function extractWordAtIndex(
        bytes memory arg,
        uint256 idx
    ) public pure returns (bytes32 extractedWord) {
        assembly {
            extractedWord := mload(add(arg, add(0x20, mul(0x20, idx))))
        }
    }
}

/**
 * @notice
 * Utilities-related functions for the ycVM.
 * This includes stuff like encoding chuncks, separating commands, etc.
 * Everything that has no 'dependencies' - pure functions.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../Types.sol";
import "./Constants.sol";

contract Utilities is Constants {
    /**
     * _seperateCommand()
     * Takes in a full encoded ycCommand, returns it seperated (naked) with the type & return type flags
     * @param ycCommand - The full encoded ycCommand to separate
     * @return nakedCommand - the command without it's type flags
     * @return typeflag - the typeflag of the command
     * @return retTypeflag - the typeflag of the return value of the command
     */
    function _separateCommand(
        bytes memory ycCommand
    )
        internal
        pure
        returns (bytes memory nakedCommand, bytes1 typeflag, bytes1 retTypeflag)
    {
        // Assign the typeflag & retTypeFlag
        typeflag = ycCommand[0];
        retTypeflag = ycCommand[1];

        // The length of the original command
        uint256 originalLen = ycCommand.length;

        // The new desired length
        uint256 newLen = originalLen - 2;

        /**
         * We load the first word of the command,
         * by mloading it's first 32 bytes, shifting them 2 bytes to the left,
         * then convering assigning that to bytes30. The result is the first 30 bytes of the command,
         * minus the typeflags.
         */
        bytes30 firstWord;
        assembly {
            firstWord := shl(16, mload(add(ycCommand, 0x20)))
        }

        /**
         * Initiate the naked command to a byte the length of the original command, minus 32 bytes.
         * -2 to account for the flags we are omitting, and -30 to account for the first loaded bytes.
         * We will later concat the first 30 bytes from the original command (that does not include the typeflags)
         */
        nakedCommand = new bytes(newLen - 30);

        assembly {
            /**
             * We begin by getting the base origin & destination pointers.
             * For the base destination, it is 62 bytes - 32 bytes to skip the length,
             * and an additional 30 bytes to account for the first word (minus the typeflags) which we have loaded
             * For the baseOrigin, it is 64 bytes - 32 bytes for the length skipping, and an additional 32 bytes
             * to skip the first word, including the typeflags
             *
             * Note that there should not be any free memory issue. It is true that we may go off a bit with
             * the new byte assignment than our naked command's length (nit-picking would be expsv here), but
             * it shouldnt matter as the size we care about is already allocated to our new naked command,
             * and anything that would like to override the extra empty bytes after it is more than welcome
             */
            let baseOrigin := add(ycCommand, 0x40)
            let baseDst := add(nakedCommand, 0x20)

            // If there should be an additional iteration that may be needed
            // (depending on whether it is a multiple of 32 or not)
            let extraIters := and(1, mod(newLen, 32))

            // The iterations amount to do
            let iters := add(div(newLen, 32), extraIters)

            /*
             * We iterate over our original command in 32 byte increments,
             * and copy over the bytes to the new nakedCommand (again, with the base
             * of the origin being 32 bytes late, to skip the first word
             */
            for {
                let i := 0
            } lt(i, iters) {
                i := add(i, 1)
            } {
                mstore(
                    add(baseDst, mul(i, 0x20)),
                    mload(add(baseOrigin, mul(i, 0x20)))
                )
            }
        }

        // We concat the first 30 byte word with the new naked command - completeing the operation, and returning.
        nakedCommand = bytes.concat(firstWord, nakedCommand);
    }

    /**
     * _separateAndRemovePrependedBytes
     * An arbitrary function that tkaes in a chunck of bytes (must be a multiple of 32 in length!!!!!!!),
     * and a uint specifying how many  bytes to remove (also must be a multiple of 32 length) from the beggining.
     * It uses the _removePrependedBytes() function, returns the bytes iwthout the prepended bytes, but also the
     * prepended bytes on their own chunck.
     * @param chunck - a chunck of bytes
     * @param bytesToRemove - A multiple of 32, amount of bytes to remove from the beginning
     * @return parsedChunck - the chunck without the first multiples of 32 bytes
     * @return junk - The omitted specified bytes
     */
    function _separateAndRemovePrependedBytes(
        bytes memory chunck,
        uint256 bytesToRemove
    ) internal pure returns (bytes memory parsedChunck, bytes memory junk) {
        /**
         * Assign to the junk first
         */
        uint256 len = chunck.length;

        assembly {
            // Require the argument & bytes to remove to be a multiple of 32 bytes
            if or(mod(len, 0x20), mod(bytesToRemove, 0x20)) {
                revert(0, 0)
            }

            // The pointer to start mloading from (beggining of data)
            let startPtr := add(chunck, 0x20)

            // The pointer to end mloading on (the start pointer + the amount of bytes to remove)
            let endPtr := add(startPtr, bytesToRemove)

            // Start pointer to mstore to
            let baseDst := add(junk, 0x20)

            // The amount of iterations to make
            let iters := div(sub(endPtr, startPtr), 0x20)

            // Iterate in 32 byte increments, mstoring it on the parsedChunck
            for {
                let i := 0
            } lt(i, iters) {
                i := add(i, 1)
            } {
                mstore(
                    add(baseDst, mul(i, 0x20)),
                    mload(add(baseDst, mul(i, 0x20)))
                )
            }
        }

        /**
         * Remove the prepended bytes using the remove prepended bytes function,
         * and return the new parsed chunck + the junk
         */
        parsedChunck = _removePrependedBytes(chunck, bytesToRemove);
    }

    /**
     * @notice
     * _removePrependedBytes
     * Takes in a chunck of bytes (must be a multiple of 32 in length!!!!!!!),
     * Note that the chunck must be a "dynamic" variable, so the first 32 bytes must specify it's length.
     * and a uint specifying how many  bytes to remove (also must be a multiple of 32 length) from the beggining.
     * @param chunck - a chunck of bytes
     * @param bytesToRemove - A multiple of 32, amount of bytes to remove from the beginning
     * @return parsedChunck - the chunck without the first multiples of 32 bytes
     */
    function _removePrependedBytes(
        bytes memory chunck,
        uint256 bytesToRemove
    ) internal pure returns (bytes memory parsedChunck) {
        // Shorthand for the length of the bytes chunck
        uint256 len = chunck.length;

        // We create the new value, which is the length of the argument *minus* the bytes to remove
        parsedChunck = new bytes(len - bytesToRemove);

        assembly {
            // Require the argument & bytes to remove to be a multiple of 32 bytes
            if or(mod(len, 0x20), mod(bytesToRemove, 0x20)) {
                revert(0, 0)
            }

            // New length's multiple of 32 (the amount of iterations we need to do)
            let iters := div(sub(len, bytesToRemove), 0x20)

            // Base pointer for the original value - Base ptr + ptr pointing to value + bytes to remove
            //  (first 32 bytes of the value)
            let baseOriginPtr := add(chunck, add(0x20, bytesToRemove))

            // Base destination pointer
            let baseDstPtr := add(parsedChunck, 0x20)

            // Iterating over the variable, copying it's bytes to the new value - except the first *bytes to remove*
            for {
                let i := 0
            } lt(i, iters) {
                i := add(i, 1)
            } {
                // Current 32 bytes
                let currpart := mload(add(baseOriginPtr, mul(0x20, i)))

                // Paste them into the new value
                mstore(add(baseDstPtr, mul(0x20, i)), currpart)
            }
        }
    }
}

/**
 * Access Control (whitelisting, admins, mods) used by the vault contract.
 * Note only relevent for private vaults!
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Schema.sol";

contract AccessControl {
    // ===================
    //      ABSTRACTS
    // ===================
    /**
     * @dev The address of the Yieldchain diamond contract
     */
    address public immutable YC_DIAMOND;

    /**
     * @dev The address of the creator of this strategy
     */
    address public immutable CREATOR;

    constructor(address creator, address diamond) {
        CREATOR = creator;
        YC_DIAMOND = diamond;
    }

    // ===================
    //      STORAGE
    // ===================
    /**
     * @dev
     * Tracking whether the strategy is private or not,
     * this is not immutable since we would allow to change it from the diamond (deploying) contract,
     * if permmited.
     */
    bool public isPublic;

    /**
     * @dev
     * Keeping track of whitelisted users that are allowed to use this vault
     * @notice This is only relevent for private vaults - In public vaults, everyone is allowed in.
     */
    mapping(address => bool) public whitelistedUsers;

    /**
     * @dev
     * Keeping track of all of the admins of the vault,
     * that can whitelist/blacklist users from using it,
     * also only relevent for private vaults
     */
    mapping(address => bool) public mods;

    /**
     * @dev
     * Keeping track of all of the administrators of the vault,
     * Adminstrators have mods permissions but can also add/remove other mods,
     * also only relevent for private vaults
     */
    mapping(address => bool) public admins;

    // ===================
    //      MODIFIERS
    // ===================
    /**
     * Requires the msg.sender to be the Yieldchain dimaond
     */
    modifier onlyDiamond() {
        require(msg.sender == YC_DIAMOND, "You Are Not Yieldchain Diamond");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Only self");
        _;
    }

    /**
     * Requires the msg.sender to be the vault's creator
     */
    modifier onlyCreator() {
        require(msg.sender == CREATOR, "You Are Not Vault Creator");
        _;
    }

    /**
     * Requires the msg.sender to be a moderator of this vault
     */
    modifier onlyMods() {
        require(mods[msg.sender], "You Are Not A Mod");
        _;
    }
    /**
     * Requires the msg.sender to be an admin of this vault
     */
    modifier onlyAdmins() {
        require(admins[msg.sender], "You Are Not An Admin");
        _;
    }

    /**
     * Requires an inputted address to not be another moderator
     * @notice We do allow it if msg.sender is an administrator (higher role)
     */
    modifier peaceAmongstMods(address otherMod) {
        require(
            !mods[otherMod] || (admins[msg.sender] && !admins[otherMod]),
            "Mods Cannot Betray Mods"
        );
        _;
    }

    /**
     * Requires an inputted address to not be another adminstrator
     */
    modifier peaceAmongstAdmins(address otherAdmin) {
        require(
            admins[msg.sender] && !admins[otherAdmin],
            "Admins Cannot Betray Admins"
        );
        _;
    }

    /**
     * Requires the msg.sender to either be whitelisted, or the vault be public
     */
    modifier onlyWhitelistedOrPublicVault() {
        require(
            isPublic || whitelistedUsers[msg.sender],
            "You Are Not Whitelisted"
        );
        _;
    }

    // ===================
    //      FUNCTIONS
    // ===================
    /**
     * @dev
     * changePrivacy()
     * Changes the privacy of this vault.
     * @notice ONLY callable by the Diamond. This is in order to enforce some rules logic, like:
     * 1) A public vault cannot be changed to private in most cases
     * 2) Vaults can only be private for premium users,
     * etc.
     *
     * The logic may change in the future
     *
     * @param shouldBePublic - true: Public, false: private.
     */
    function changePrivacy(bool shouldBePublic) external onlyDiamond {
        isPublic = shouldBePublic;
    }

    /**
     * @dev
     * Whitelist an address
     * @param userAddress - The address to whitelist
     */
    function whitelist(address userAddress) external onlyMods {
        whitelistedUsers[userAddress] = true;
    }

    /**
     * @dev
     * Blacklist an address
     * @param userAddress - The address to whitelist
     */
    function blacklist(
        address userAddress
    ) external onlyMods peaceAmongstMods(userAddress) {
        whitelistedUsers[userAddress] = false;
    }

    /**
     * @dev
     * Add a moderator
     */
    function addModerator(address userAddress) external onlyAdmins {
        mods[userAddress] = true;
        whitelistedUsers[userAddress] = true;
    }

    /**
     * @dev
     * Remove a moderator
     */
    function removeModerator(
        address userAddress
    ) external onlyAdmins peaceAmongstAdmins(userAddress) {
        mods[userAddress] = false;
    }

    /**
     * @dev
     * Add an administrator
     */
    function addAdministrator(address userAddress) external onlyCreator {
        mods[userAddress] = true;
        admins[userAddress] = true;
        whitelistedUsers[userAddress] = true;
    }

    /**
     * @dev
     * Remove an administrator
     */
    function removeAdministrator(address userAddress) external onlyCreator {
        admins[userAddress] = false;
        mods[userAddress] = false;
    }
}

/**
 * Constants for the ycVM.
 * Just the flags of each operation and etc
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../Types.sol";

contract Constants {
    // ================
    //    CONSTANTS
    // ================
    bytes1 internal constant VALUE_VAR_FLAG = 0x00;
    bytes1 internal constant REF_VAR_FLAG = 0x01;
    bytes1 internal constant COMMANDS_LIST_FLAG = 0x02;
    bytes1 internal constant COMMANDS_REF_ARR_FLAG = 0x03;
    bytes1 internal constant RAW_REF_VAR_FLAG = 0x04;
    bytes1 internal constant STATICCALL_COMMAND_FLAG = 0x05;
    bytes1 internal constant CALL_COMMAND_FLAG = 0x06;
    bytes1 internal constant DELEGATECALL_COMMAND_FLAG = 0x07;
    bytes1 internal constant INTERNAL_LOAD_FLAG = 0x08;
}