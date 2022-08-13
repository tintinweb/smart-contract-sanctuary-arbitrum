//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {Vault} from "../Vault.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title VaultFactory
/// @notice VaultFactory serves as a factory and controller for vaults implementation and proxies.
contract VaultFactory is ProxyAdmin {
    /// @notice The implementation used to deploy proxies.
    address private implementation;

    /// @notice Event emitted when a Vault is deployed.
    event VaultDeployed(address indexed proxy, address indexed underlying, address auth);

    /// @notice Implementation updated
    event ImplementationUpdated(address implementation);

    /// @notice Get the current implementation.
    function getImplementation() external view returns (address) {
        return implementation;
    }

    /// @notice Set the current implementation.
    /// @param newImplementation The new implementation.
    function setImplementation(address newImplementation) external onlyOwner {
        implementation = newImplementation;

        emit ImplementationUpdated(newImplementation);
    }

    /// @notice Deploys a new Vault given input data.
    /// @param underlying The underlying asset.
    /// @param auth The Auth module used by the Vault.
    /// @param harvestFeeReceiver The harvest fees receiver.
    /// @param burnFeeReceiver The batched burns fees receiver.
    function deployVault(
        address underlying,
        address auth,
        address harvestFeeReceiver,
        address burnFeeReceiver
    ) external returns (Vault vault) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            address(this),
            abi.encodeWithSelector(Vault.initialize.selector, underlying, auth, harvestFeeReceiver, burnFeeReceiver)
        );

        emit VaultDeployed(address(proxy), underlying, auth);

        return Vault(address(proxy));
    }
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {Authority} from "./auth/Auth.sol";
import {IVault} from "@vault-interfaces/IVault.sol";
import {IStrategy} from "@vault-interfaces/IStrategy.sol";
import {SafeCastLib as SafeCast} from "./libraries/SafeCastLib.sol";
import {FixedPointMathLib as FixedPointMath} from "./libraries/FixedPointMathLib.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title Vault
/// @author dantop114
/// @notice A vault seeking for yield.
contract Vault is ERC20, Pausable {
    using SafeERC20 for ERC20;
    using SafeCast for uint256;
    using FixedPointMath for uint256;

    /*///////////////////////////////////////////////////////////////
                              IMMUTABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice The Vault's token symbol prefix.
    bytes internal constant S_PREFIX = bytes("auxo");

    /// @notice The Vault's token name prefix.
    bytes internal constant N_PREFIX = bytes("Auxo ");

    /// @notice The Vault's token name suffix.
    bytes internal constant N_SUFFIX = bytes(" Vault");

    /// @notice Max number of strategies the Vault can handle.
    uint256 internal constant MAX_STRATEGIES = 20;

    /// @notice Vault's API version.
    string public constant VERSION = "0.2";

    /*///////////////////////////////////////////////////////////////
                        STRUCTS DECLARATIONS
    ///////////////////////////////////////////////////////////////*/

    /// @dev Packed struct of strategy data.
    /// @param trusted Whether the strategy is trusted.
    /// @param balance The amount of underlying tokens held in the strategy.
    struct StrategyData {
        // Used to determine if the Vault will operate on a strategy.
        bool trusted;
        // Used to determine profit and loss during harvests of the strategy.
        uint248 balance;
    }

    /// @dev Struct for batched burning events.
    /// @param totalShares Shares to burn during the event.
    /// @param amountPerShare Underlying amount per share (this differs from exchangeRate at the moment of batched burning).
    struct BatchBurn {
        uint256 totalShares;
        uint256 amountPerShare;
    }

    /// @dev Struct for users' batched burning requests.
    /// @param round Batched burning event index.
    /// @param shares Shares to burn for the user.
    struct BatchBurnReceipt {
        uint256 round;
        uint256 shares;
    }

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Blocks mined in a year.
    uint256 public blocksPerYear;

    /// @notice Vault Auth module.
    Authority public auth;

    /// @notice The underlying token the vault accepts.
    ERC20 public underlying;

    /// @notice The underlying token decimals.
    uint8 public underlyingDecimals;

    /// @notice The base unit of the underlying token and hence the Vault share token.
    /// @dev Equal to 10 ** underlyingDecimals. Used for fixed point arithmetic.
    uint256 public baseUnit;

    /// @notice The percentage of profit recognized each harvest to reserve as fees.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    uint256 public harvestFeePercent;

    /// @notice The address receiving harvest fees (denominated in Vault's shares).
    address public harvestFeeReceiver;

    /// @notice The percentage of shares recognized each burning to reserve as fees.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    uint256 public burningFeePercent;

    /// @notice The address receiving burning fees (denominated in Vault's shares).
    address public burningFeeReceiver;

    /// @notice The period in seconds during which multiple harvests can occur
    /// regardless if they are taking place before the harvest delay has elapsed.
    /// @dev Long harvest delays open up the Vault to profit distribution DOS attacks.
    uint128 public harvestWindow;

    /// @notice The period in seconds over which locked profit is unlocked.
    /// @dev Cannot be 0 as it opens harvests up to sandwich attacks.
    uint64 public harvestDelay;

    /// @notice The value that will replace harvestDelay next harvest.
    /// @dev In the case that the next delay is 0, no update will be applied.
    uint64 public nextHarvestDelay;

    /// @notice The total amount of underlying tokens held in strategies at the time of the last harvest.
    /// @dev Includes maxLockedProfit, must be correctly subtracted to compute available/free holdings.
    uint256 public totalStrategyHoldings;

    /// @notice Maps strategies to data the Vault holds on them.
    mapping(IStrategy => StrategyData) public getStrategyData;

    /// @notice Exchange rate at the beginning of latest harvest window
    uint256 public lastHarvestExchangeRate;

    /// @notice Latest harvest interval in blocks
    uint256 public lastHarvestIntervalInBlocks;

    /// @notice The block number when the first harvest in the most recent harvest window occurred.
    uint256 public lastHarvestWindowStartBlock;

    /// @notice A timestamp representing when the first harvest in the most recent harvest window occurred.
    /// @dev May be equal to lastHarvest if there was/has only been one harvest in the most last/current window.
    uint64 public lastHarvestWindowStart;

    /// @notice A timestamp representing when the most recent harvest occurred.
    uint64 public lastHarvest;

    /// @notice The amount of locked profit at the end of the last harvest.
    uint128 public maxLockedProfit;

    /// @notice An ordered array of strategies representing the withdrawal queue.
    /// @dev The queue is processed in descending order, meaning the last index will be withdrawn from first.
    /// @dev There are not sanity checks on the withdrawal queue, so any control should be done off-chain.
    IStrategy[] public withdrawalQueue;

    /// @notice Current batched burning round.
    uint256 public batchBurnRound;

    /// @notice Balance reserved to batched burning withdrawals.
    uint256 public batchBurnBalance;

    /// @notice Maps user's address to withdrawal request.
    mapping(address => BatchBurnReceipt) public userBatchBurnReceipts;

    /// @notice Maps social burning events rounds to batched burn details.
    mapping(uint256 => BatchBurn) public batchBurns;

    /// @notice Amount of shares a single address can hold.
    uint256 public userDepositLimit;

    /// @notice Amount of underlying cap for this vault.
    uint256 public vaultDepositLimit;

    /// @notice Estimated return recorded during last harvest.
    uint256 public estimatedReturn;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the Authority module is updated.
    /// @param newAuth The new Authority module.
    event AuthUpdated(Authority newAuth);

    /// @notice Emitted when the fee percentage is updated.
    /// @param newFeePercent The new fee percentage.
    event HarvestFeePercentUpdated(uint256 newFeePercent);

    /// @notice Emitted when the batched burning fee percentage is updated.
    /// @param newFeePercent The new fee percentage.
    event BurningFeePercentUpdated(uint256 newFeePercent);

    /// @notice Emitted when harvest fees receiver is updated.
    /// @param receiver The new receiver
    event HarvestFeeReceiverUpdated(address indexed receiver);

    /// @notice Emitted when burning fees receiver is updated.
    /// @param receiver The new receiver
    event BurningFeeReceiverUpdated(address indexed receiver);

    //// @notice Emitted when the harvest window is updated.
    //// @param newHarvestWindow The new harvest window.
    event HarvestWindowUpdated(uint128 newHarvestWindow);

    /// @notice Emitted when the harvest delay is updated.
    /// @param account The address changing the harvest delay
    /// @param newHarvestDelay The new harvest delay.
    event HarvestDelayUpdated(address indexed account, uint64 newHarvestDelay);

    /// @notice Emitted when the harvest delay is scheduled to be updated next harvest.
    /// @param newHarvestDelay The scheduled updated harvest delay.
    event HarvestDelayUpdateScheduled(uint64 newHarvestDelay);

    /// @notice Emitted when the withdrawal queue is updated.
    /// @param replacedWithdrawalQueue The new withdrawal queue.
    event WithdrawalQueueSet(IStrategy[] replacedWithdrawalQueue);

    /// @notice Emitted when a strategy is set to trusted.
    /// @param strategy The strategy that became trusted.
    event StrategyTrusted(IStrategy indexed strategy);

    /// @notice Emitted when a strategy is set to untrusted.
    /// @param strategy The strategy that became untrusted.
    event StrategyDistrusted(IStrategy indexed strategy);

    /// @notice Emitted when underlying tokens are deposited into the vault.
    /// @param from The user depositing into the vault.
    /// @param to The user receiving Vault's shares.
    /// @param value The shares `to` is receiving.
    event Deposit(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted after a user enters a batched burn round.
    /// @param round Batched burn round.
    /// @param account User's address.
    /// @param amount Amount of shares to be burned.
    event EnterBatchBurn(
        uint256 indexed round,
        address indexed account,
        uint256 amount
    );

    /// @notice Emitted after a user exits a batched burn round.
    /// @param round Batched burn round.
    /// @param account User's address.
    /// @param amount Amount of underlying redeemed.
    event ExitBatchBurn(
        uint256 indexed round,
        address indexed account,
        uint256 amount
    );

    /// @notice Emitted after a batched burn event happens.
    /// @param round Batched burn round.
    /// @param executor User that executes the batch burn.
    /// @param shares Total amount of burned shares.
    /// @param amount Total amount of underlying redeemed.
    event ExecuteBatchBurn(
        uint256 indexed round,
        address indexed executor,
        uint256 shares,
        uint256 amount
    );

    /// @notice Emitted after a successful harvest.
    /// @param account The harvester address.
    /// @param strategies The set of strategies.
    event Harvest(address indexed account, IStrategy[] strategies);

    /// @notice Emitted after the Vault deposits into a strategy contract.
    /// @param account The address depositing funds into the strategy.
    /// @param strategy The strategy that was deposited into.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event StrategyDeposit(
        address indexed account,
        IStrategy indexed strategy,
        uint256 underlyingAmount
    );

    /// @notice Emitted after the Vault withdraws funds from a strategy contract.
    /// @param account The user pulling funds from the strategy
    /// @param strategy The strategy that was withdrawn from.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event StrategyWithdrawal(
        address indexed account,
        IStrategy indexed strategy,
        uint256 underlyingAmount
    );

    /// @notice Event emitted when the deposit limits are updated.
    /// @param perUser New underlying limit per address.
    /// @param perVault New underlying limit per vault.
    event DepositLimitsUpdated(uint256 perUser, uint256 perVault);

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier requiresAuth(address addr) {
        require(auth.canCall(addr, address(this), msg.sig), "UNAUTHORIZED");

        _;
    }

    /*///////////////////////////////////////////////////////////////
                    INITIALIZER AND PAUSE TRIGGER
    //////////////////////////////////////////////////////////////*/

    /// @notice Triggers the Vault's pause
    /// @dev Only owner can call this method.
    function triggerPause() external requiresAuth(msg.sender) {
        paused() ? _unpause() : _pause();
    }

    /// @notice Internal initializer method.
    /// @param underlying_ The underlying token the vault accepts.
    /// @param auth_ The Auth mo    dule that will be used for this Vault.
    /// @param harvestFeeReceiver_ The harvesting fee receiver address.
    /// @param burnFeeReceiver_ The batched burns fee receiver address.
    /// @param name_ The Vault shares' name.
    /// @param symbol_ The Vault shares' symbol.
    function __Vault_init(
        ERC20 underlying_,
        Authority auth_,
        address harvestFeeReceiver_,
        address burnFeeReceiver_,
        string memory name_,
        string memory symbol_
    ) internal initializer {
        // Initialize ERC20 trait.
        __ERC20_init(name_, symbol_);

        // Initialize Pausable trait.
        __Pausable_init();

        // Initialize Pausable trait.
        _pause();

        // Initialize the storage.
        underlying = underlying_;
        baseUnit = 10**underlying_.decimals();
        underlyingDecimals = underlying_.decimals();

        auth = auth_;
        burningFeeReceiver = burnFeeReceiver_;
        harvestFeeReceiver = harvestFeeReceiver_;

        // Sets batchBurnRound to 1.
        // NOTE: needed to have 0 as an uninitialized withdraw request.
        batchBurnRound = 1;
    }

    /// @notice The initialize method
    /// @param underlying_ The underlying token the vault accepts.
    /// @param auth_ The Auth module that will be used for this Vault.
    /// @param harvestFeeReceiver_ The harvesting fee receiver address.
    /// @param burnFeeReceiver_ The batched burns fee receiver address.
    function initialize(
        ERC20 underlying_,
        Authority auth_,
        address harvestFeeReceiver_,
        address burnFeeReceiver_
    ) external initializer {
        // Initialize the Vault.
        __Vault_init(
            underlying_,
            auth_,
            harvestFeeReceiver_,
            burnFeeReceiver_,
            string(bytes.concat(N_PREFIX, bytes(underlying_.name()), N_SUFFIX)),
            string(bytes.concat(S_PREFIX, bytes(underlying_.symbol())))
        );
    }

    /*///////////////////////////////////////////////////////////////
                        DECIMAL OVERRIDING
    //////////////////////////////////////////////////////////////*/

    /// @notice Overrides `decimals` method.
    /// @dev Needed because Openzeppelin's logic for decimals.
    /// @return Vault's shares token decimals (underlying token decimals).
    function decimals() public view override returns (uint8) {
        return underlyingDecimals;
    }

    /*///////////////////////////////////////////////////////////////
                    UNDERLYING CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Set new deposit limits for this vault.
    /// @param user New user deposit limit.
    /// @param vault New vault deposit limit.
    function setDepositLimits(uint256 user, uint256 vault)
        external
        requiresAuth(msg.sender)
    {
        userDepositLimit = user;
        vaultDepositLimit = vault;

        emit DepositLimitsUpdated(user, vault);
    }

    /*///////////////////////////////////////////////////////////////
                        AUTH CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Set a new Authority module.
    /// @param newAuth The new Authority module.
    function setAuth(Authority newAuth) external requiresAuth(msg.sender) {
        auth = newAuth;
        emit AuthUpdated(newAuth);
    }

    /*///////////////////////////////////////////////////////////////
                     BLOCKS PER YEAR CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets blocks per year.
    /// @param blocks Blocks in a given year.
    function setBlocksPerYear(uint256 blocks)
        external
        requiresAuth(msg.sender)
    {
        blocksPerYear = blocks;
    }

    /*///////////////////////////////////////////////////////////////
                           FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Set a new fee percentage.
    /// @param newFeePercent The new fee percentage.
    function setHarvestFeePercent(uint256 newFeePercent)
        external
        requiresAuth(msg.sender)
    {
        // A fee percentage over 100% doesn't make sense.
        require(newFeePercent <= 1e18, "setHarvestFeePercent::FEE_TOO_HIGH");

        // Update the fee percentage.
        harvestFeePercent = newFeePercent;

        emit HarvestFeePercentUpdated(newFeePercent);
    }

    /// @notice Set a new burning fee percentage.
    /// @param newFeePercent The new fee percentage.
    function setBurningFeePercent(uint256 newFeePercent)
        external
        requiresAuth(msg.sender)
    {
        // A fee percentage over 100% doesn't make sense.
        require(
            newFeePercent <= 1e18,
            "setBatchedBurningFeePercent::FEE_TOO_HIGH"
        );

        // Update the fee percentage.
        burningFeePercent = newFeePercent;

        emit BurningFeePercentUpdated(newFeePercent);
    }

    /// @notice Set a new harvest fees receiver.
    /// @param harvestFeeReceiver_ The new harvest fees receiver.
    function setHarvestFeeReceiver(address harvestFeeReceiver_)
        external
        requiresAuth(msg.sender)
    {
        // Update the fee percentage.
        harvestFeeReceiver = harvestFeeReceiver_;

        emit HarvestFeeReceiverUpdated(harvestFeeReceiver_);
    }

    /// @notice Set a new burning fees receiver.
    /// @param burningFeeReceiver_ The new burning fees receiver.
    function setBurningFeeReceiver(address burningFeeReceiver_)
        external
        requiresAuth(msg.sender)
    {
        // Update the fee percentage.
        burningFeeReceiver = burningFeeReceiver_;

        emit BurningFeeReceiverUpdated(burningFeeReceiver_);
    }

    /*///////////////////////////////////////////////////////////////
                        HARVEST CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Set a new harvest window.
    /// @param newHarvestWindow The new harvest window.
    /// @dev The Vault's harvestDelay must already be set before calling.
    function setHarvestWindow(uint128 newHarvestWindow)
        external
        requiresAuth(msg.sender)
    {
        // A harvest window longer than the harvest delay doesn't make sense.
        require(
            newHarvestWindow <= harvestDelay,
            "setHarvestWindow::WINDOW_TOO_LONG"
        );

        // Update the harvest window.
        harvestWindow = newHarvestWindow;

        emit HarvestWindowUpdated(newHarvestWindow);
    }

    /// @notice Set a new harvest delay delay.
    /// @param newHarvestDelay The new harvest delay to set.
    /// @dev If the current harvest delay is 0, meaning it has not
    /// been set before, it will be updated immediately; otherwise
    /// it will be scheduled to take effect after the next harvest.
    function setHarvestDelay(uint64 newHarvestDelay)
        external
        requiresAuth(msg.sender)
    {
        // A harvest delay of 0 makes harvests vulnerable to sandwich attacks.
        require(newHarvestDelay != 0, "setHarvestDelay::DELAY_CANNOT_BE_ZERO");

        // A target harvest delay over 1 year doesn't make sense.
        require(newHarvestDelay <= 365 days, "setHarvestDelay::DELAY_TOO_LONG");

        // If the harvest delay is 0, meaning it has not been set before:
        if (harvestDelay == 0) {
            // We'll apply the update immediately.
            harvestDelay = newHarvestDelay;

            emit HarvestDelayUpdated(msg.sender, newHarvestDelay);
        } else {
            // We'll apply the update next harvest.
            nextHarvestDelay = newHarvestDelay;

            emit HarvestDelayUpdateScheduled(newHarvestDelay);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        WITHDRAWAL QUEUE
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the full withdrawal queue.
    /// @return An ordered array of strategies representing the withdrawal queue.
    /// @dev This is provided because Solidity converts public arrays into index getters,
    /// but we need a way to allow external contracts and users to access the whole array.
    function getWithdrawalQueue() external view returns (IStrategy[] memory) {
        return withdrawalQueue;
    }

    /// @notice Set the withdrawal queue.
    /// @param newQueue The new withdrawal queue.
    /// @dev There are no sanity checks on the `newQueue` argument so they should be done off-chain.
    function setWithdrawalQueue(IStrategy[] calldata newQueue)
        external
        requiresAuth(msg.sender)
    {
        // Check for duplicated in queue
        require(
            newQueue.length <= MAX_STRATEGIES,
            "setWithdrawalQueue::QUEUE_TOO_BIG"
        );

        // Replace the withdrawal queue.
        withdrawalQueue = newQueue;

        emit WithdrawalQueueSet(newQueue);
    }

    /*///////////////////////////////////////////////////////////////
                      STRATEGY TRUST/DISTRUST LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Store a strategy as trusted, enabling it to be harvested.
    /// @param strategy The strategy to make trusted.
    function trustStrategy(IStrategy strategy)
        external
        requiresAuth(msg.sender)
    {
        // Ensure the strategy accepts the correct underlying token.
        // If the strategy accepts ETH the Vault should accept WETH, it'll handle wrapping when necessary.
        require(
            strategy.underlying() == underlying,
            "trustStrategy::WRONG_UNDERLYING"
        );

        // Store the strategy as trusted.
        getStrategyData[strategy].trusted = true;

        emit StrategyTrusted(strategy);
    }

    /// @notice Store a strategy as untrusted, disabling it from being harvested.
    /// @param strategy The strategy to make untrusted.
    function distrustStrategy(IStrategy strategy)
        external
        requiresAuth(msg.sender)
    {
        // Store the strategy as untrusted.
        getStrategyData[strategy].trusted = false;

        emit StrategyDistrusted(strategy);
    }

    /*///////////////////////////////////////////////////////////////
                            DEPOSIT/BURN
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a specific amount of underlying tokens.
    /// @dev User needs to approve `underlyingAmount` of underlying tokens to spend.
    /// @param to The address to receive shares corresponding to the deposit.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    /// @return shares The amount of shares minted using `underlyingAmount`.
    function deposit(address to, uint256 underlyingAmount)
        external
        requiresAuth(to)
        returns (uint256 shares)
    {
        _deposit(
            to,
            (shares = calculateShares(underlyingAmount)),
            underlyingAmount
        );
    }

    /// @notice Enter a batched burn event.
    /// @dev Each user can take part to one batched burn event a time.
    /// @dev User's shares amount will be staked until the burn happens.
    /// @param shares Shares to withdraw during the next batched burn event.
    function enterBatchBurn(uint256 shares) external {
        uint256 batchBurnRound_ = batchBurnRound;
        uint256 userRound = userBatchBurnReceipts[msg.sender].round;

        if (userRound == 0) {
            // user is depositing for the first time in this round
            // so we set his round to current round

            userBatchBurnReceipts[msg.sender].round = batchBurnRound_;
            userBatchBurnReceipts[msg.sender].shares = shares;
        } else {
            // user is not depositing for the first time or took part in a previous round:
            //      - first case: we stack the deposits.
            //      - second case: revert, user needs to withdraw before requesting
            //                     to take part in another round.

            require(
                userRound == batchBurnRound_,
                "enterBatchBurn::DIFFERENT_ROUNDS"
            );
            userBatchBurnReceipts[msg.sender].shares += shares;
        }

        batchBurns[batchBurnRound_].totalShares += shares;

        require(transfer(address(this), shares));

        emit EnterBatchBurn(batchBurnRound_, msg.sender, shares);
    }

    /// @notice Withdraw underlying redeemed in batched burning events.
    function exitBatchBurn() external {
        uint256 batchBurnRound_ = batchBurnRound;
        BatchBurnReceipt memory receipt = userBatchBurnReceipts[msg.sender];

        require(receipt.round != 0, "exitBatchBurn::NO_DEPOSITS");
        require(
            receipt.round < batchBurnRound_,
            "exitBatchBurn::ROUND_NOT_EXECUTED"
        );

        userBatchBurnReceipts[msg.sender].round = 0;
        userBatchBurnReceipts[msg.sender].shares = 0;

        uint256 underlyingAmount = receipt.shares.fmul(
            batchBurns[receipt.round].amountPerShare,
            baseUnit
        );

        batchBurnBalance -= underlyingAmount;
        underlying.safeTransfer(msg.sender, underlyingAmount);

        emit ExitBatchBurn(batchBurnRound_, msg.sender, underlyingAmount);
    }

    /// @notice Execute batched burns
    function execBatchBurn() external requiresAuth(msg.sender) {
        // let's wait for lockedProfit to go to 0
        require(
            block.timestamp >= (lastHarvest + harvestDelay),
            "batchBurn::LATEST_HARVEST_NOT_EXPIRED"
        );

        uint256 batchBurnRound_ = batchBurnRound++;

        BatchBurn memory batchBurn = batchBurns[batchBurnRound_];
        uint256 totalShares = batchBurn.totalShares;

        // burning 0 shares is not convenient
        require(totalShares != 0, "batchBurn::TOTAL_SHARES_CANNOT_BE_ZERO");

        uint256 underlyingAmount = totalShares.fmul(exchangeRate(), baseUnit);
        require(
            underlyingAmount <= totalFloat(),
            "batchBurn::NOT_ENOUGH_UNDERLYING"
        );

        _burn(address(this), totalShares);

        // Compute fees and transfer underlying amount if any
        if (burningFeePercent != 0) {
            uint256 accruedFees = underlyingAmount.fmul(
                burningFeePercent,
                10**18
            );
            underlyingAmount -= accruedFees;

            underlying.safeTransfer(burningFeeReceiver, accruedFees);
        }

        batchBurns[batchBurnRound_].amountPerShare = underlyingAmount.fdiv(
            totalShares,
            baseUnit
        );
        batchBurnBalance += underlyingAmount;

        emit ExecuteBatchBurn(
            batchBurnRound_,
            msg.sender,
            totalShares,
            underlyingAmount
        );
    }

    /// @dev Internal function to deposit into the Vault.
    /// @param to The address to receive shares corresponding to the deposit.
    /// @param shares The amount of Vault's shares to mint.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    function _deposit(
        address to,
        uint256 shares,
        uint256 underlyingAmount
    ) internal virtual whenNotPaused {
        uint256 userUnderlying = calculateUnderlying(balanceOf(to)) +
            underlyingAmount;
        uint256 vaultUnderlying = totalUnderlying() + underlyingAmount;

        require(
            userUnderlying <= userDepositLimit,
            "_deposit::USER_DEPOSIT_LIMITS_REACHED"
        );
        require(
            vaultUnderlying <= vaultDepositLimit,
            "_deposit::VAULT_DEPOSIT_LIMITS_REACHED"
        );

        // Determine te equivalent amount of shares and mint them
        _mint(to, shares);

        emit Deposit(msg.sender, to, underlyingAmount);

        // Transfer in underlying tokens from the user.
        // This will revert if the user does not have the amount specified.
        underlying.safeTransferFrom(
            msg.sender,
            address(this),
            underlyingAmount
        );
    }

    /// @notice Calculates the amount of Vault's shares for a given amount of underlying tokens.
    /// @param underlyingAmount The underlying token's amount.
    /// @return The amount of shares given `underlyingAmount`.
    function calculateShares(uint256 underlyingAmount)
        public
        view
        returns (uint256)
    {
        return underlyingAmount.fdiv(exchangeRate(), baseUnit);
    }

    /// @notice Calculates the amount of underlying tokens corresponding to a given amount of Vault's shares.
    /// @param sharesAmount The shares amount.
    /// @return The amount of underlying given `sharesAmount`.
    function calculateUnderlying(uint256 sharesAmount)
        public
        view
        returns (uint256)
    {
        return sharesAmount.fmul(exchangeRate(), baseUnit);
    }

    /*///////////////////////////////////////////////////////////////
                             HARVEST LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Harvest a set of trusted strategies.
    /// @param strategies The trusted strategies to harvest.
    /// @dev Will always revert if called outside of an active
    /// harvest window or before the harvest delay has passed.
    function harvest(IStrategy[] calldata strategies)
        external
        requiresAuth(msg.sender)
    {
        // If this is the first harvest after the last window:
        if (block.timestamp >= lastHarvest + harvestDelay) {
            // Accounts for:
            //    - harvest interval (from latest harvest)
            //    - harvest exchange rate
            //    - harvest window starting block
            lastHarvestExchangeRate = exchangeRate();
            lastHarvestIntervalInBlocks =
                block.number -
                lastHarvestWindowStartBlock;
            lastHarvestWindowStartBlock = block.number;

            // Set the harvest window's start timestamp.
            lastHarvestWindowStart = uint64(block.timestamp);
        } else {
            // We know this harvest is not the first in the window so we need to ensure it's within it.
            require(
                block.timestamp <= lastHarvestWindowStart + harvestWindow,
                "harvest::BAD_HARVEST_TIME"
            );
        }

        // Get the Vault's current total strategy holdings.
        uint256 oldTotalStrategyHoldings = totalStrategyHoldings;

        // Used to store the total profit accrued by the strategies.
        uint256 totalProfitAccrued;

        // Used to store the new total strategy holdings after harvesting.
        uint256 newTotalStrategyHoldings = oldTotalStrategyHoldings;

        // Will revert if any of the specified strategies are untrusted.
        for (uint256 i = 0; i < strategies.length; i++) {
            // Get the strategy at the current index.
            IStrategy strategy = strategies[i];

            // If an untrusted strategy could be harvested a malicious user could use
            // a fake strategy that over-reports holdings to manipulate the exchange rate.
            require(
                getStrategyData[strategy].trusted,
                "harvest::UNTRUSTED_STRATEGY"
            );

            // Get the strategy's previous and current balance.
            uint256 balanceLastHarvest = getStrategyData[strategy].balance;
            uint256 balanceThisHarvest = strategy.estimatedUnderlying();

            // Update the strategy's stored balance.
            getStrategyData[strategy].balance = balanceThisHarvest
                .safeCastTo248();

            // Increase/decrease newTotalStrategyHoldings based on the profit/loss registered.
            // We cannot wrap the subtraction in parenthesis as it would underflow if the strategy had a loss.
            newTotalStrategyHoldings =
                newTotalStrategyHoldings +
                balanceThisHarvest -
                balanceLastHarvest;

            // Update the total profit accrued while counting losses as zero profit.
            totalProfitAccrued += balanceThisHarvest > balanceLastHarvest
                ? balanceThisHarvest - balanceLastHarvest // Profits since last harvest.
                : 0; // If the strategy registered a net loss we don't have any new profit.
        }

        // Compute fees as the fee percent multiplied by the profit.
        uint256 feesAccrued = totalProfitAccrued.fmul(harvestFeePercent, 1e18);

        // If we accrued any fees, mint an equivalent amount of Vault's shares.
        if (feesAccrued != 0 && harvestFeeReceiver != address(0)) {
            _mint(
                harvestFeeReceiver,
                feesAccrued.fdiv(exchangeRate(), baseUnit)
            );
        }

        // Update max unlocked profit based on any remaining locked profit plus new profit.
        uint128 maxLockedProfit_ = (lockedProfit() +
            totalProfitAccrued -
            feesAccrued).safeCastTo128();
        maxLockedProfit = maxLockedProfit_;

        // Compute estimated returns
        uint256 strategyHoldings = newTotalStrategyHoldings -
            uint256(maxLockedProfit_);
        estimatedReturn = computeEstimatedReturns(
            strategyHoldings,
            uint256(maxLockedProfit_),
            lastHarvestIntervalInBlocks
        );

        // Set strategy holdings to our new total.
        totalStrategyHoldings = newTotalStrategyHoldings;

        // Update the last harvest timestamp.
        lastHarvest = uint64(block.timestamp);

        emit Harvest(msg.sender, strategies);

        // Get the next harvest delay.
        uint64 newHarvestDelay = nextHarvestDelay;

        // If the next harvest delay is not 0:
        if (newHarvestDelay != 0) {
            // Update the harvest delay.
            harvestDelay = newHarvestDelay;

            // Reset the next harvest delay.
            nextHarvestDelay = 0;

            emit HarvestDelayUpdated(msg.sender, newHarvestDelay);
        }
    }

    /*///////////////////////////////////////////////////////////////
                    STRATEGY DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a specific amount of float into a trusted strategy.
    /// @param strategy The trusted strategy to deposit into.
    /// @param underlyingAmount The amount of underlying tokens in float to deposit.
    function depositIntoStrategy(IStrategy strategy, uint256 underlyingAmount)
        external
        requiresAuth(msg.sender)
    {
        // A strategy must be trusted before it can be deposited into.
        require(
            getStrategyData[strategy].trusted,
            "depositIntoStrategy::UNTRUSTED_STRATEGY"
        );

        // We don't allow depositing 0 to prevent emitting a useless event.
        require(
            underlyingAmount != 0,
            "depositIntoStrategy::AMOUNT_CANNOT_BE_ZERO"
        );

        // Increase totalStrategyHoldings to account for the deposit.
        totalStrategyHoldings += underlyingAmount;

        // Without this the next harvest would count the deposit as profit.
        getStrategyData[strategy].balance += underlyingAmount.safeCastTo248();

        emit StrategyDeposit(msg.sender, strategy, underlyingAmount);

        // Approve underlyingAmount to the strategy so we can deposit.
        underlying.safeApprove(address(strategy), underlyingAmount);

        // Deposit into the strategy and revert if it returns an error code.
        require(
            strategy.deposit(underlyingAmount) == 0,
            "depositIntoStrategy::MINT_FAILED"
        );
    }

    /// @notice Withdraw a specific amount of underlying tokens from a strategy.
    /// @param strategy The strategy to withdraw from.
    /// @param underlyingAmount  The amount of underlying tokens to withdraw.
    /// @dev Withdrawing from a strategy will not remove it from the withdrawal queue.
    function withdrawFromStrategy(IStrategy strategy, uint256 underlyingAmount)
        external
        requiresAuth(msg.sender)
    {
        // A strategy must be trusted before it can be withdrawn from.
        require(
            getStrategyData[strategy].trusted,
            "withdrawFromStrategy::UNTRUSTED_STRATEGY"
        );

        // We don't allow withdrawing 0 to prevent emitting a useless event.
        require(
            underlyingAmount != 0,
            "withdrawFromStrategy::AMOUNT_CANNOT_BE_ZERO"
        );

        // Without this the next harvest would count the withdrawal as a loss.
        getStrategyData[strategy].balance -= underlyingAmount.safeCastTo248();

        // Decrease totalStrategyHoldings to account for the withdrawal.
        totalStrategyHoldings -= underlyingAmount;

        emit StrategyWithdrawal(msg.sender, strategy, underlyingAmount);

        // Withdraw from the strategy and revert if returns an error code.
        require(
            strategy.withdraw(underlyingAmount) == 0,
            "withdrawFromStrategy::REDEEM_FAILED"
        );
    }

    /*///////////////////////////////////////////////////////////////
                                ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the amount of underlying tokens a share can be redeemed for.
    /// @return The amount of underlying tokens a share can be redeemed for.
    function exchangeRate() public view returns (uint256) {
        // Get the total supply of shares.
        uint256 shareSupply = totalSupply();

        // If there are no shares in circulation, return an exchange rate of 1:1.
        if (shareSupply == 0) return baseUnit;

        return totalUnderlying().fdiv(shareSupply, baseUnit);
    }

    /// @notice Returns a user's Vault balance in underlying tokens.
    /// @param user THe user to get the underlying balance of.
    /// @return The user's Vault balance in underlying tokens.
    function balanceOfUnderlying(address user) external view returns (uint256) {
        return calculateUnderlying(balanceOf(user));
    }

    /// @notice Returns the amount of underlying tokens that idly sit in the Vault.
    /// @return The amount of underlying tokens that sit idly in the Vault.
    function totalFloat() public view returns (uint256) {
        return underlying.balanceOf(address(this)) - batchBurnBalance;
    }

    /// @notice Calculate the current amount of locked profit.
    /// @return The current amount of locked profit.
    function lockedProfit() public view returns (uint256) {
        // Get the last harvest and harvest delay.
        uint256 previousHarvest = lastHarvest;
        uint256 harvestInterval = harvestDelay;

        // If the harvest delay has passed, there is no locked profit.
        if (block.timestamp >= previousHarvest + harvestInterval) return 0;

        // Get the maximum amount we could return.
        uint256 maximumLockedProfit = maxLockedProfit;

        // Compute how much profit remains locked based on the last harvest and harvest delay.
        return
            maximumLockedProfit -
            (maximumLockedProfit * (block.timestamp - previousHarvest)) /
            harvestInterval;
    }

    /// @notice Calculates the total amount of underlying tokens the Vault holds.
    /// @return totalUnderlyingHeld The total amount of underlying tokens the Vault holds.
    function totalUnderlying() public view virtual returns (uint256) {
        return totalStrategyHoldings - lockedProfit() + totalFloat();
    }

    /// @notice Compute an estimated return given the auxoToken supply, initial exchange rate and locked profits.
    /// @param invested The underlying deposited in strategies.
    /// @param profit The profit derived from harvest.
    /// @param interval The period during which `profit` was generated.
    function computeEstimatedReturns(
        uint256 invested,
        uint256 profit,
        uint256 interval
    ) internal view returns (uint256) {
        return
            (invested == 0 || profit == 0)
                ? 0
                : profit.fdiv(invested, baseUnit) *
                    (blocksPerYear / interval) *
                    100;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
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
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
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
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

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
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title IVault
/// @notice Basic MonoVault interface.
/// @dev This interface should not change frequently and can be used to code interactions
///      for the users of the Vault. Admin functions are available through the `VaultBase` contract.
interface IVault is IERC20 {
    /*///////////////////////////////////////////////////////////////
                              Vault API Version
    ///////////////////////////////////////////////////////////////*/

    /// @notice The API version the vault implements
    function version() external view returns (string memory);

    /*///////////////////////////////////////////////////////////////
                              ERC20Detailed
    ///////////////////////////////////////////////////////////////*/

    /// @notice The Vault shares token name.
    function name() external view returns (string calldata);

    /// @notice The Vault shares token symbol.
    function symbol() external view returns (string calldata);

    /// @notice The Vault shares token decimals.
    function decimals() external view returns (uint8);

    /*///////////////////////////////////////////////////////////////
                              Batched burns
    ///////////////////////////////////////////////////////////////*/

    /// @dev Struct for users' batched burning requests.
    /// @param round Batched burning event index.
    /// @param shares Shares to burn for the user.
    struct BatchBurnReceipt {
        uint256 round;
        uint256 shares;
    }

    /// @dev Struct for batched burning events.
    /// @param totalShares Shares to burn during the event.
    /// @param amountPerShare Underlying amount per share (this differs from exchangeRate at the moment of batched burning).
    struct BatchBurn {
        uint256 totalShares;
        uint256 amountPerShare;
    }

    /// @notice Current batched burning round.
    function batchBurnRound() external view returns (uint256);

    /// @notice Maps user's address to withdrawal request.
    function userBatchBurnReceipt(address account) external view returns (BatchBurnReceipt memory);

    /// @notice Maps social burning events rounds to batched burn details.
    function batchBurns(uint256 round) external view returns (BatchBurn memory);

    /// @notice Enter a batched burn event.
    /// @dev Each user can take part to one batched burn event a time.
    /// @dev User's shares amount will be staked until the burn happens.
    /// @param shares Shares to withdraw during the next batched burn event.
    function enterBatchBurn(uint256 shares) external;

    /// @notice Withdraw underlying redeemed in batched burning events.
    function exitBatchBurn() external;

    /*///////////////////////////////////////////////////////////////
                              ERC4626-like
    ///////////////////////////////////////////////////////////////*/

    /// @notice The underlying token the vault accepts
    function underlying() external view returns (IERC20);

    /// @notice Deposit a specific amount of underlying tokens.
    /// @dev User needs to approve `underlyingAmount` of underlying tokens to spend.
    /// @param to The address to receive shares corresponding to the deposit.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    /// @return shares The amount of shares minted using `underlyingAmount`.
    function deposit(address to, uint256 underlyingAmount) external returns (uint256);

    /// @notice Deposit a specific amount of underlying tokens.
    /// @dev User needs to approve `underlyingAmount` of underlying tokens to spend.
    /// @param to The address to receive shares corresponding to the deposit.
    /// @param shares The amount of Vault's shares to mint.
    /// @return underlyingAmount The amount needed to mint `shares` amount of shares.
    function mint(address to, uint256 shares) external returns (uint256);

    /// @notice Returns a user's Vault balance in underlying tokens.
    /// @param user THe user to get the underlying balance of.
    /// @return The user's Vault balance in underlying tokens.
    function balanceOfUnderlying(address user) external view returns (uint256);

    /// @notice Calculates the amount of Vault's shares for a given amount of underlying tokens.
    /// @param underlyingAmount The underlying token's amount.
    function calculateShares(uint256 underlyingAmount) external view returns (uint256);

    /// @notice Calculates the amount of underlying tokens corresponding to a given amount of Vault's shares.
    /// @param sharesAmount The shares amount.
    function calculateUnderlying(uint256 sharesAmount) external view returns (uint256);

    /// @notice Returns the amount of underlying tokens a share can be redeemed for.
    /// @return The amount of underlying tokens a share can be redeemed for.
    function exchangeRate() external view returns (uint256);

    /// @notice Returns the amount of underlying tokens that idly sit in the Vault.
    /// @return The amount of underlying tokens that sit idly in the Vault.
    function totalFloat() external view returns (uint256);

    /// @notice Calculate the current amount of locked profit.
    /// @return The current amount of locked profit.
    function lockedProfit() external view returns (uint256);

    /// @notice Calculates the total amount of underlying tokens the Vault holds.
    /// @return The total amount of underlying tokens the Vault holds.
    function totalUnderlying() external view returns (uint256);

    /// @notice Returns an estimated return for the vault.
    /// @dev This method should not be used to get a precise estimate.
    /// @return A formatted APR value
    function estimatedReturn() external view returns (uint256);
}

//   ______
//  /      \
// /$$$$$$  | __    __  __    __   ______
// $$ |__$$ |/  |  /  |/  \  /  | /      \
// $$    $$ |$$ |  $$ |$$  \/$$/ /$$$$$$  |
// $$$$$$$$ |$$ |  $$ | $$  $$<  $$ |  $$ |
// $$ |  $$ |$$ \__$$ | /$$$$  \ $$ \__$$ |
// $$ |  $$ |$$    $$/ /$$/ $$  |$$    $$/
// $$/   $$/  $$$$$$/  $$/   $$/  $$$$$$/
//
// auxo.fi

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IVault} from "./IVault.sol";

/// @title IStrategy
/// @notice Basic Vault Strategy interface.
interface IStrategy {
    /*///////////////////////////////////////////////////////////////
                             GENERAL INFO
    //////////////////////////////////////////////////////////////*/

    /// @notice The strategy name.
    function name() external view returns (string calldata);

    /// @notice The Vault managing this strategy.
    function vault() external view returns (IVault);

    /*///////////////////////////////////////////////////////////////
                            DEPOSIT/WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a specific amount of underlying tokens.
    function deposit(uint256) external returns (uint8);

    /// @notice Withdraw a specific amount of underlying tokens.
    function withdraw(uint256) external returns (uint8);

    /*///////////////////////////////////////////////////////////////
                            ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    /// @notice The underlying token the strategy accepts.
    function underlying() external view returns (IERC20);

    /// @notice The amount deposited by the Vault in this strategy.
    function depositedUnderlying() external returns (uint256);

    /// @notice An estimate amount of underlying managed by the strategy.
    function estimatedUnderlying() external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x <= type(uint248).max);

        y = uint248(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x <= type(uint96).max);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x <= type(uint64).max);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x <= type(uint32).max);

        y = uint32(x);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

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
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
interface IERC20PermitUpgradeable {
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