/**
 * Used to create & manage strategy vaults
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../vault/Vault.sol";
import "../../storage/Strategies.sol";
import "../../storage/Users.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../triggers/Registry.sol";
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
        address indexed depositToken
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
    //     GETTERS
    // ==================
    function getStrategiesList()
        external
        view
        returns (Vault[] memory strategies)
    {
        strategies = StrategiesStorageLib.getStrategiesStorage().strategies;
    }

    function getStrategyState(
        Vault strategy
    ) external view returns (StrategyState memory strategyState) {
        strategyState = StrategiesStorageLib
            .getStrategiesStorage()
            .strategiesState[strategy];
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
    // 
     * @param approvalPairs - A 2D array of [ERC20Token, addressToApprove]. Which will be approved on deployment of the vault
     * @param depositToken - An ERC20 token which is used for deposits into the vault
     * @param isPublic - The visibility/privacy of this vault. Private only allowed for premium users!!

     */
    function createVault(
        bytes[] memory seedSteps,
        bytes[] memory treeSteps,
        bytes[] memory uprootSteps,
        address[2][] memory approvalPairs,
        ERC20 depositToken,
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

        /**
         * Push the strategy to the storage array
         */
        StrategiesStorageLib.getStrategiesStorage().strategies.push(
            createdVault
        );

        StrategiesStorageLib.getStrategiesStorage().strategiesState[
                createdVault
            ] = StrategyState(true, 0);

        emit VaultCreated(
            address(createdVault),
            msg.sender,
            address(depositToken)
        );
        /**
         * Finally, we move onto registering each one of the triggers on the Registry facet.
         * The Registry facet will register it on the corresponding trigger-specific facet,
         * and on the strategy's mapping in the general storage, where we store an array of the registered triggers.
         */
     
    }

    /**
     * @notice
     * Fund a vault's native gas balance
     * @param strategyAddress - Address of the strategy to fund
     */
    function fundGasBalance(address strategyAddress) public payable {
        /**
         * Shorthand for strategies storage
         */
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();
        /**
         * Storage ref to our strategy in the mapping
         */
        StrategyState storage strategy = strategiesStorage.strategiesState[
            Vault(strategyAddress)
        ];

        /**
         * Require the strategy to exist
         */
        require(strategy.registered, "Vault Does Not Exist");

        /**
         * Finally, increment the gas balance in the amount provided
         */
        strategy.gasBalanceWei += msg.value;
    }

    /**
     * @notice
     * deductAndTransferVaultGas()
     * Deduct from a vault's gas balance, and transfer it to some address
     * can only be called internally!!
     * @param strategy - Address of the strategy to deduct
     * @param receiver - The address of the Ether receiver
     * @param debtInWei - The debt of the strategy in WEI (not GWEI!!) to deduct
     */
    function deductAndTransferVaultGas(
        Vault strategy,
        address payable receiver,
        uint256 debtInWei
    ) public onlySelf {
        // Shorthand for strategies storage

        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();

        // Storage ref to our strategy in the mapping
        StrategyState storage strategyState = strategiesStorage.strategiesState[
            strategy
        ];

        // Assert that the balance is sufficient and deduct the debt
        require(
            strategyState.gasBalanceWei >= debtInWei,
            "Insufficient Gas Balance To Deduct."
        );

        // Deduct it
        strategyState.gasBalanceWei -= debtInWei;

        // Transfer to the receiver
        receiver.transfer(debtInWei);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import {SafeERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../diamond/interfaces/ITokenStash.sol";
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
        /**
         * We assert that the user must have given us appropriate allowance of the deposit token,
         * so that we can transfer the amount to us
         */
        if (DEPOSIT_TOKEN.allowance(msg.sender, address(this)) < amount)
            revert InsufficientAllowance();

        /**
         * @dev We assert that the msg.value of this call is atleast of the deposit approximation * the delta
         */
        if (msg.value < approxDepositGas * GAS_FEE_APPROXIMATION_DELTA)
            revert InsufficientGasPrepay();

        /**
         * @notice
         * We get the user's tokens into our balance, and then @dev stash it on the Yieldchain Diamond's TokenStasher facet.
         * This is in order for us to get the tokens right away, without messing with the balances of other operations
         */

        // Transfer to us
        DEPOSIT_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        // Stash in TokenStasher
        ITokenStash(YC_DIAMOND).stashTokens(address(DEPOSIT_TOKEN), amount);

        // Increment total shares supply & user's balance
        totalShares += amount;
        balances[msg.sender] += amount;

        /**
         * Create an operation item, and request it (adding to the state array & emitting an event w a request to handle)
         */

        // Create the args array which just includes the encoded amount
        bytes[] memory depositArgs = new bytes[](1);
        depositArgs[0] = abi.encode(amount);

        // Create the queue item
        OperationItem memory depositRequest = OperationItem(
            ExecutionTypes.SEED,
            msg.sender,
            msg.value,
            depositArgs,
            new bytes[](0),
            false
        );

        // Request the operation
        requestOperation(depositRequest);
    }

    /**
     * @notice
     * Request to withdraw out of the vault
     * @param amount - the amount of shares to withdraw
     */
    function withdraw(
        uint256 amount
    ) external payable onlyWhitelistedOrPublicVault {
        /**
         * We assert the user's shares are sufficient
         * Note this is re-checked when handling the actual withdrawal
         */
        if (amount > balances[msg.sender]) revert InsufficientShares();

        /**
         * @dev We assert that the msg.value of this call is atleast of the withdraw approximation * the delta
         */
        if (msg.value < approxWithdrawalGas * GAS_FEE_APPROXIMATION_DELTA)
            revert InsufficientGasPrepay();

        /**
         * We deduct the total shares & balance from the user
         */
        balances[msg.sender] -= amount;
        totalShares -= amount;

        /**
         * We create an Operation request item for our withdrawal and add it to the state, whilst requesting an offchain hydration & reentrance
         */
        bytes[] memory withdrawArgs = new bytes[](1);
        withdrawArgs[0] = abi.encode(amount);

        // Create the queue item
        OperationItem memory withdrawRequest = OperationItem(
            ExecutionTypes.UPROOT,
            msg.sender,
            msg.value,
            withdrawArgs,
            new bytes[](0),
            false
        );

        // Request the operation
        requestOperation(withdrawRequest);
    }

    /**
     * @notice
     * runStrategy()
     * Requests a strategy execution operation,
     * only called by the diamond (i.e from an executor on the diamond)
     */
    function runStrategy() external onlyDiamond {
        /**
         * We create a QueueItem for our run and enqueue it, which should either begin executing it,
         * or begin waiting for it's turn
         */
        // Create the queue item
        OperationItem memory runRequest = OperationItem(
            // Request to execute the strategy tree
            ExecutionTypes.TREE,
            // Initiator is YC diamond
            YC_DIAMOND,
            // Gas not required here (using gas balance of entire vault)
            0,
            // No custom args, and ofc no calldata atm (will be set by the offchain handler if any)
            new bytes[](0),
            new bytes[](0),
            false
        );

        // Request the run
        requestOperation(runRequest);
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
    function getStrategiesStorage()
        internal
        pure
        returns (StrategiesStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

/**
 * The registry for triggers on strategies
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../vault/Vault.sol";
import "../../storage/Strategies.sol";

contract Registry {
    /**
     * Register a trigger on a strategy
     * @param strategy - The strategy vault to register the trigger on
     * @param trigger - The type of trigger to register (Triggers enum)
     * @param triggerSettings - Arbitrary bytes. The settings to pass on to the specific trigger registry (decoding is up to it)
     */
    function registerTrigger(
        Vault strategy,
        Triggers trigger,
        bytes memory triggerSettings
    ) public view {
        /**
         * @notice
         * We make a switch case per trigger case and call it's specific registry,
         *  with the provided setting
         */
        if (trigger == Triggers.AUTOMATION) {
            strategy;
            triggerSettings;
        }
        address(this);
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
                .getStrategiesStorage()
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

/**
 * Interface for the TokenStasher
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ITokenStash {
    function unstashTokens(address tokenAddress, uint256 amount) external;
    function stashTokens(address tokenAddress, uint256 amount) external;
}

/**
 * The execution functions for the vault (Internal/Used by YC Diamond)
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import {SafeERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../vm/VM.sol";
import "./OperationsQueue.sol";
import "./State.sol";
import "./Constants.sol";
import "./VaultUtilities.sol";
import "../diamond/interfaces/ITokenStash.sol";

abstract contract VaultExecution is
    YCVM,
    OperationsQueue,
    VaultUtilities,
    VaultConstants,
    VaultState
{
    // Libs
    using SafeERC20 for IERC20;

    // =========================================
    //       DIAMOND-PERMISSIONED METHODS
    // =========================================
    /**
     * hydrateAndExecuteRun
     * Hydrates an OperationItem from storage with provided calldatas and executes it
     * @param operationIndex - The index of the operation from within storage
     * @param commandCalldatas - Array of arbitrary YC commands, should be the fullfilling calldatas for the
     * run if required
     */
    function hydrateAndExecuteRun(
        uint256 operationIndex,
        bytes[] calldata commandCalldatas
    ) external onlyDiamond returns (OperationItem memory operation) {
        // We allocate to the current free memory pointer,
        // which may be used/overwritten by subsequent internal function calls
        // (e.g, saving a user's share in memory)
        assembly {
            mstore(0x40, add(mload(0x40), 0x20))
        }

        /**
         * We retreive the current operation to handle.
         * Note that we do not dequeue it, as we want it to remain visible in storage
         * until the operation fully completes (incase there is an offchain break inbetween execution steps).
         * Dequeuing it & resaving to storage would be highly unneccsery gas-wise, and hence we leave it in the queue,
         * and leave it upto the handling function to dequeue it
         */

        operation = operationRequests[operationIndex];

        require(!operation.executed, "Operation Already Executed");

        /**
         * We hydrate it with the command calldatas
         */
        operation.commandCalldatas = commandCalldatas;

        uint256[] memory startingIndices = new uint256[](1);
        startingIndices[0] = 0;

        /**
         * Switch statement for the operation to run
         */
        if (operation.action == ExecutionTypes.SEED)
            executeDeposit(operation, startingIndices);
        else if (operation.action == ExecutionTypes.UPROOT)
            executeWithdraw(operation, startingIndices);
        else if (operation.action == ExecutionTypes.TREE)
            executeStrategy(operation, startingIndices);
        else revert();

        // We unlock the contract state once the operation has completed
        operationRequests[operationIndex].executed = true;
    }

    /**
     * @dev
     * Claim gas paid by an operation request
     * @param operationIndex - The index of the operation in storage
     * @param receiver - The address of the executor that should receive this transfer
     * @param claimAmount - The amount of gas to claim
     */
    function claimOperationGas(
        uint256 operationIndex,
        address payable receiver,
        uint256 claimAmount
    ) external onlyDiamond {
        // Get the amount of gas that was included in this request
        OperationItem memory opRequest = operationRequests[operationIndex];
        uint256 availableAmt = opRequest.gas;

        // Make sure claim amount is sufficient to the available amount
        require(
            availableAmt >= claimAmount,
            "Insufficient Request Gas To Claim"
        );

        // Set the gas in the storage item to 0, since we now claim the gas there shouldnt be a need for that
        operationRequests[operationIndex].gas = 0;

        // Transfer requested gas to diamond
        // Note that the Diamond is responsible for refunding unused gas at the end.
        payable(receiver).transfer(claimAmount);
    }

    /**
     * storeGasApproximation()
     * Stores a gas approximation for some action
     * @param operationType - ExecutionType enum so that we know where to store to
     * @param approximation - The approximation of gas
     */
    function storeGasApproximation(
        ExecutionTypes operationType,
        uint256 approximation
    ) external onlyDiamond {
        // Switch case based on the type
        if (operationType == ExecutionTypes.SEED)
            approxDepositGas = approximation;
        else if (operationType == ExecutionTypes.UPROOT)
            approxWithdrawalGas = approximation;
        else if (operationType == ExecutionTypes.TREE)
            approxStrategyGas = approximation;
    }

    // ============================
    //       INTERNAL METHODS
    // ============================
    /**
     * @notice
     * executeDeposit()
     * The actual deposit execution handler,
     * @dev Should be called once hydrated with the operation offchain computed data
     * @param depositItem - OperationItem from the operations queue, representing the deposit request
     */
    function executeDeposit(
        OperationItem memory depositItem,
        uint256[] memory startingIndices
    ) internal {
        /**
         * @dev
         * At this point, we have transferred the user's funds to our stash in the Diamond,
         * and had the offchain handler hydrate our item's calldatas (if any are required).
         */

        /**
         * Decode the first byte argument as an amount
         */
        uint256 amount = abi.decode(depositItem.arguments[0], (uint256));

        assembly {
            // We MSTORE at the deposit amount memory location the deposit amount (may be accessed by commands to determine amount arguments)
            mstore(DEPOSIT_AMT_MEM_LOCATION, amount)
        }

        /**
         * We unstash the user's tokens from the Yieldchain Diamond, so that it is (obv) used within the operation
         */
        ITokenStash(YC_DIAMOND).unstashTokens(address(DEPOSIT_TOKEN), amount);

        /**
         * @notice  We execute the seed steps, starting from the root step
         */
        executeStepTree(SEED_STEPS, startingIndices, depositItem);
    }

    /**
     * @notice
     * handleWithdraw()
     * The actual withdraw execution handler
     * @param withdrawItem - OperationItem from the operations queue, representing the withdrawal request
     */
    function executeWithdraw(
        OperationItem memory withdrawItem,
        uint256[] memory startingIndices
    ) internal {
        /**
         * @dev At this point, we have deducted the shares from the user's balance and the total supply
         * when the request was made.
         */

        /**
         * Decode the first byte argument as an amount
         */
        uint256 amount = abi.decode(withdrawItem.arguments[0], (uint256));

        /**
         * The share in % this amount represnets of the total shares (Plus the amount b4 dividing, since we already deducted from it in the initial function)
         */
        uint256 shareOfVaultInPercentage = (totalShares + amount) / amount;

        assembly {
            // We MSTORE at the withdraw share memory location the % share of the withdraw amount of the total vault, times 100
            // (e.g, 100 shares to withdraw, 1000 total shares = 1000 / 100 * 100(%) = 1000 (10% multipled by 100, for safe maths...))
            mstore(
                WITHDRAW_SHARES_MEM_LOCATION,
                mul(shareOfVaultInPercentage, 100)
            )
        }

        /**
         * @notice We keep track of what the deposit token balance was prior to the execution
         */
        uint256 preVaultBalance = DEPOSIT_TOKEN.balanceOf(address(this));

        /**
         * @notice  We begin executing the uproot (reverse) steps
         */
        executeStepTree(UPROOTING_STEPS, startingIndices, withdrawItem);

        /**
         * After executing all of the steps, we get the balance difference,
         * and transfer to the user.
         * We use safeERC20, so if the debt is 0, the execution reverts.
         */
        uint256 debt = DEPOSIT_TOKEN.balanceOf(address(this)) - preVaultBalance;
        DEPOSIT_TOKEN.safeTransfer(withdrawItem.initiator, debt);
    }

    /**
     * @notice
     * handleRunStrategy()
     * Handles a strategy run request
     */
    function executeStrategy(
        OperationItem memory strategyRunRequest,
        uint256[] memory startingIndices
    ) internal {
        /**
         * Execute the strategy's tree of steps with the provided startingIndices and fullfill command
         */
        executeStepTree(STEPS, startingIndices, strategyRunRequest);
    }

    // ==============================
    //        STEPS EXECUTION
    // ==============================
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
        uint256[] memory startingIndices,
        OperationItem memory operationRequest
    ) internal {
        /**
         * Iterate over each one of the starting indices
         */
        for (uint256 i = 0; i < startingIndices.length; i++) {
            /**
             * Load the current virtualTree step index
             */
            uint256 stepIndex = startingIndices[i];

            /**
             * Begin by retreiving & decoding the current YC step from the virtual tree
             */
            YCStep memory step = abi.decode(virtualTree[stepIndex], (YCStep));

            /**
             * @notice Initiating a variable for the "chosenOffspringIdx", which is ONLY RELEVENT
             * for conditional steps.
             *
             * When a conditional step runs, it will reassign to this variable either:
             * - An index of one of it's children
             * - 0
             * If it's an index of one of it's children, it means that it found a case where
             * one of it's children conditions returned true, and we should only execute it (rather than all of it's children indexes).
             * Otherwise, if the index is 0, it means it did not find any, and we should not execute any of it's children.
             * (It is impossible for a condition index to be 0, since it will always be the root)
             */
            // uint256 chosenOffspringIdx;

            /**
             * Check to see if current step is a condition - Execute the conditional function with it's children if it is.
             */
            // if (step.conditions.length > 0) {
            //     // Sufficient check to make sure there are as many conditions as there are children
            //     require(
            //         step.conditions.length == step.childrenIndices.length,
            //         "Conditions & Children Mismatch"
            //     );

            //     // Assign to the chosenOffspringIdx variable the return value from the conditional checker
            //     chosenOffspringIdx = _determineConditions(step.conditions);
            // }

            /**
             * We first check to see if this step is a callback step.
             */
            if (step.isCallback) {
                /**
                 * @notice @dev
                 * A callback step means it requires offchain-computed data to be used.
                 * When the initial request for this operation run was made, it was re-entered with the offchain-computed data,
                 * and set on our operation item in an array of YC commands.
                 * We check to see if, at our (step) index, the command calldata exists. If it does, we run it.
                 * Otherwise, we check to see if we are on mainnet currently. If we are, it means something is wrong, and we shall revert.
                 * If we are on a fork, we emit a "RequestFullfill" event. Which will be used by the offchain simulator to create the command calldata,
                 * which we should have on every mainnet execution for callback steps.
                 */
                if (
                    operationRequest.commandCalldatas.length > stepIndex &&
                    bytes32(operationRequest.commandCalldatas[stepIndex]) !=
                    bytes32(0)
                )
                    _runFunction(operationRequest.commandCalldatas[stepIndex]);

                    // Revert if we are on mainnet
                else if (isMainnet) revert NoOffchainComputedCommand(stepIndex);
                // Emit a fullfill event otherwise
                else {
                    (bytes memory nakedFunc, , ) = _separateCommand(step.func);

                    FunctionCall memory originalCall = abi.decode(
                        nakedFunc,
                        (FunctionCall)
                    );

                    bytes[] memory builtArgs = new bytes[](
                        originalCall.args.length
                    );

                    for (uint256 j; j < builtArgs.length; j++) {
                        bytes[] memory ownArray = new bytes[](1);
                        ownArray[0] = originalCall.args[j];
                        builtArgs[j] = interpretCommandsAndEncodeChunck(
                            ownArray
                        );
                    }

                    emit RequestFullfill(
                        stepIndex,
                        abi.encode(
                            FunctionCall(
                                originalCall.target_address,
                                builtArgs,
                                originalCall.signature
                            )
                        )
                    );
                }
            }
            /**
             * If the step is not a callback (And also not empty), we execute the step's function
             */
            else if (bytes32(step.func) != bytes32(0)) _runFunction(step.func);

            /**
             * @notice
             * At this point, we move onto executing the step's children.
             * If the chosenOffSpringIdx variable does not equal to 0, we execute the children idx at that index
             * of the array of indexes of the step. So if the index 2 was returnd, we execute virtualTree[step.childrenIndices[2]].
             * Otherwise, we do a full iteration over all children
             */

            // We initiatre this array to a length of 1. If we should execute all children, this is reassigned to.
            uint256[] memory childrenStartingIndices = new uint256[](1);

            // // If offspring idx is valid, we assign to index 0 it's index
            // if (chosenOffspringIdx > 0)
            //     childrenStartingIndices[0] = step.childrenIndices[
            //         // Note we -1 here, since the chosenOffspringIdx would have upped it up by 1 (to retain 0 as the falsy indicator)
            //         chosenOffspringIdx - 1
            //     ];

            //     // Else it equals to all of the step's children
            // else
            childrenStartingIndices = step.childrenIndices;

            /**
             * We now iterate over each children and @recruse the function call
             * Note that the executeStepTree() function accepts an array of steps to execute.
             * You may would have expected us to do an iteration over each child, but in order to be complied with
             * the fact that, an execution tree may emit multiple offchain requests in a single transaction - We accept an array
             * of starting indices, rather than a single starting index. (Offchain actions will be batched per transaction and executed together here,
             * rather than per-event).
             */
            executeStepTree(
                virtualTree,
                childrenStartingIndices,
                operationRequest
            );
        }
    }

    // =========================
    //    SIMULATION METHODS
    // =========================
    //------------------
    // @notice ONLY ON FORKS, IRRELEVENT ON MAINNETS
    //------------------

    /**
     * @dev
     * ONLY ON FORK!!
     * set fork status
     */
    function setForkStatus() external {
        require(msg.sender == address(0), "Only Fork Address Can Do This");
        isMainnet = false;
    }

    /**
     * @dev
     * ONLY ON FORK!!
     * Used for simulating the run
     * @param operationIdx - The idx of the operation to simulate
     * @param startingIndices - The starting indices
     * @param commandsHydratedThusFar - Commands that were hydrated thus far
     */
    function simulateOperationHydrationAndExecution(
        uint256 operationIdx,
        uint256[] memory startingIndices,
        bytes[] memory commandsHydratedThusFar
    ) external {
        require(msg.sender == address(0), "Only Fork Address Can Do This");
        OperationItem memory operation = operationRequests[operationIdx];

        /**
         * We hydrate it with the command calldatas
         */
        operation.commandCalldatas = commandsHydratedThusFar;

        /**
         * Switch statement for the operation to run
         */
        if (operation.action == ExecutionTypes.SEED)
            executeDeposit(operation, startingIndices);
        else if (operation.action == ExecutionTypes.UPROOT)
            executeWithdraw(operation, startingIndices);
        else if (operation.action == ExecutionTypes.TREE)
            executeStrategy(operation, startingIndices);
        else revert();
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
 * Base logic for the vault operations queue,
 * which enables queueing on operations locks, for a robust working
 * system even with offchain interverience
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Schema.sol";

abstract contract OperationsQueue is IVault {
    // ==============================
    //      OPERATIONS MANAGER
    // ==============================

    /**
     * @dev An array keeping track of the operation requests
     */
    OperationItem[] internal operationRequests;

    function getOperationItem(
        uint256 idx
    ) external view returns (OperationItem memory opItem) {
        opItem = operationRequests[idx];
    }

    function getOperationRequests()
        external
        view
        returns (OperationItem[] memory reqs)
    {
        reqs = operationRequests;
    }

    /**
     * @notice
     * @dev
     * Request an operation run.
     * An operation may be a deposit, withdraw, or a strategy run.
     * @param operationItem - the operation item to push.
     */
    function requestOperation(OperationItem memory operationItem) internal {
        // We push the operation item into our requests array
        operationRequests.push(operationItem);

        /**
         * @notice
         * We emit a "HydrateRun" event to hydrate our operation item.
         * The offchain handler will find it in storage (based on our provided index), retreive
         * the required command calldatas (if any) using simulations and offchain computation,
         * and reenter this contract in order to execute it
         */
        emit HydrateRun(operationRequests.length - 1);
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
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
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

    /**
     * @notice @dev
     * Used in offchain simulations when hydrating calldata
     */
    bool isMainnet = true;

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

    /**
     * @notice
     * @dev
     * We keep track of the approximate gas required to execute withdraw and deposit operations.
     * This is in order to charge users for the gas they are going to cost the executor
     * after their offchain hydration.
     *
     * We also keep track of the gas for the strategy run operation, mainly for analytical purposes, tho.
     */
    uint256 public approxWithdrawalGas = 0.001 ether;

    uint256 public approxDepositGas = 0.001 ether;

    uint256 public approxStrategyGas = 0.001 ether;

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
    uint256 internal constant WITHDRAW_SHARES_MEM_LOCATION = 0x00000000000000000000000000000000000000000000000000000000000000000140;
    /**
     * Constant memory location for where user's deposit amount is stored in memory
     */
    uint256 internal constant DEPOSIT_AMT_MEM_LOCATION = 0x00000000000000000000000000000000000000000000000000000000000000000140;

    /**
     * Constant "delta" variable that we require when sending gas in individual users' operations.
     *
     * For instance, if our approximation for a deposit gas on a vault is 500K WEI, and the delta is 2, then
     * we require the msg.value (the "extra" prepaid gas) to be atleast 500K WEI * 2 = 1M WEI.
     */
    uint256 internal constant GAS_FEE_APPROXIMATION_DELTA = 2;
}

/**
 * Utilities used by the vault contract
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../vm/VM.sol";

import "./Schema.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

abstract contract VaultUtilities is IVault, YCVM {
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
        return ERC20(token).balanceOf(address(this));
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
 * Contains all different events, structs, enums, etc of the vault
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../Types.sol";

abstract contract IVault {
    // =====================
    //        EVENTS
    // =====================
    /**
     * @notice
     * HydrateRun event
     * Emitted when a new operation request is received (e.g deposit, withdraw, or strategy run), as a request
     * to hydrate it's command calldatas in place.
     * those calldatas are used in steps which are classified as "offchain" steps, whom require some computation
     * to run offchain.
     * @param operationKey - The key of the operation within the operation requests array in storage
     */
    event HydrateRun(uint256 indexed operationKey);

    /**
     * @notice
     * RequestFullfill event,
     * emitted in order to request an offchain fullfill of computations/actions, when simulating them in an hydration run request offchain.
     * @param stepIndex - the index of the step within the run requesting the offchain computation
     * @param ycCommand - The yc command to execute offchain
     */
    event RequestFullfill(uint256 indexed stepIndex, bytes ycCommand);

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
enum Triggers {
    AUTOMATION,
    EVENT
}

//===============================================//
//                   STRUCTS                     //
//===============================================//
/**
 * Struct representing a registered trigger,
 * including the trigger type, and an arbitrary byte which is it's settings
 */
struct RegisteredTrigger {
    Triggers triggerType;
    bytes triggerSettings;
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
 * @param action - An ActionType enum representing the action to complete, handled by a switch case in the router
 * @param initiator - The user address that initiated this queue request
 * @param gas - The gas that was received with this operation request (in WEI)
 * @param commandCalldatas - An array specifying hydrated calldatas. If a step is an offchain step, the hydrated calldata would be stored
 * here in the index of it within it's own virtual tree (for instance, a step at index 9 of SEED_STEPS tree, would have it's
 * YC command stored at index 9 here in the callDatas)
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