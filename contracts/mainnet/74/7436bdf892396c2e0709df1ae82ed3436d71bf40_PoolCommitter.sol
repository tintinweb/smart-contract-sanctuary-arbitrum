//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/IPoolCommitter.sol";
import "../interfaces/ILeveragedPool.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IAutoClaim.sol";
import "../interfaces/IPausable.sol";
import "../interfaces/IInvariantCheck.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/PoolSwapLibrary.sol";
import "../libraries/CalldataLogic.sol";

/// @title This contract is responsible for handling commitment logic
contract PoolCommitter is IPoolCommitter, IPausable, Initializable {
    // #### Globals
    uint128 public constant LONG_INDEX = 0;
    uint128 public constant SHORT_INDEX = 1;
    // Set max minting fee to 100%. This is a ABDKQuad representation of 1 * 10 ** 18
    bytes16 public constant MAX_MINTING_FEE = 0x403abc16d674ec800000000000000000;
    // Set max burning fee to 10%. This is a ABDKQuad representation of 0.1 * 10 ** 18
    bytes16 public constant MAX_BURNING_FEE = 0x40376345785d8a000000000000000000;
    // Maximum changeInterval is the theoretical maximum change to the minting fee in one update interval.
    bytes16 public constant MAX_CHANGE_INTERVAL = MAX_MINTING_FEE;

    // 15 was chosen because it will definitely fit in a block on Arbitrum which can be tricky to ascertain definitive computation cap without trial and error, while it is also a reasonable number of upkeeps to get executed in one transaction
    uint8 public constant MAX_ITERATIONS = 15;
    IAutoClaim public autoClaim;
    uint128 public override updateIntervalId = 1;
    // The amount that is extracted from each mint and burn, being left in the pool. Given as the decimal * 10 ^ 18. For example, 60% fee is 0.6 * 10 ^ 18
    // Fees can be 0.
    bytes16 public mintingFee;
    bytes16 public burningFee;
    // The amount that the `mintingFee` will change each update interval, based on `updateMintingFee`, given as a decimal * 10 ^ 18 (same format as `_mintingFee`)
    bytes16 public changeInterval;

    // Index 0 is the LONG token, index 1 is the SHORT token.
    // Fetched from the LeveragedPool when leveragedPool is set
    address[2] public tokens;

    mapping(uint256 => Prices) public priceHistory; // updateIntervalId => tokenPrice
    mapping(uint256 => bytes16) public burnFeeHistory; // updateIntervalId => burn fee. We need to store this historically because people can claim at any time after the update interval, but we want them to pay the fee from the update interval in which they committed.
    mapping(address => Balance) public userAggregateBalance;

    // The total amount of settlement that has been committed to mints that are not yet executed
    uint256 public override pendingMintSettlementAmount;
    // The total amount of short pool tokens that have been burnt that are not yet executed on
    uint256 public override pendingShortBurnPoolTokens;
    // The total amount of long pool tokens that have been burnt that are not yet executed on
    uint256 public override pendingLongBurnPoolTokens;
    // Update interval ID => TotalCommitment
    mapping(uint256 => TotalCommitment) public totalPoolCommitments;
    // Address => Update interval ID => UserCommitment
    mapping(address => mapping(uint256 => UserCommitment)) public userCommitments;
    // The last interval ID for which a given user's balance was updated
    mapping(address => uint256) public lastUpdatedIntervalId;
    // An array for all update intervals in which a user committed
    mapping(address => uint256[]) public unAggregatedCommitments;
    // Used to create a dynamic array that is used to copy the new unAggregatedCommitments array into the mapping after updating balance
    uint256[] private storageArrayPlaceHolder;

    address public factory;
    address public governance;
    address public feeController;
    address public leveragedPool;
    address public invariantCheck;
    bool public override paused;

    modifier onlyFeeController() {
        require(msg.sender == feeController, "msg.sender not fee controller");
        _;
    }

    modifier onlyUnpaused() {
        require(!paused, "Pool is paused");
        _;
    }

    modifier onlyGov() {
        require(msg.sender == governance, "msg.sender not governance");
        _;
    }

    /**
     * @notice Asserts that the caller is the associated `PoolFactory` contract
     */
    modifier onlyFactory() {
        require(msg.sender == factory, "Committer: not factory");
        _;
    }

    /**
     * @notice Asserts that the caller is the associated `LeveragedPool` contract
     */
    modifier onlyPool() {
        require(msg.sender == leveragedPool, "msg.sender not leveragedPool");
        _;
    }

    modifier onlyInvariantCheckContract() {
        require(msg.sender == invariantCheck, "msg.sender not invariantCheck");
        _;
    }

    modifier onlyAutoClaimOrCommitter(address user) {
        require(msg.sender == user || msg.sender == address(autoClaim), "msg.sender not committer or AutoClaim");
        _;
    }

    /**
     * @notice Determines whether the provided commitment type represents a
     *          mint
     * @return Boolean indicating if `t` is mint
     */
    function isMint(CommitType t) external pure override returns (bool) {
        return t == CommitType.LongMint || t == CommitType.ShortMint;
    }

    /**
     * @notice Determines whether the provided commitment type represents a
     *          burn
     * @return Boolean indicating if `t` is burn
     */
    function isBurn(CommitType t) external pure override returns (bool) {
        return t == CommitType.LongBurn || t == CommitType.ShortBurn;
    }

    /**
     * @notice Determines whether the provided commitment type represents a
     *          long
     * @return Boolean indicating if `t` is long
     */
    function isLong(CommitType t) external pure override returns (bool) {
        return t == CommitType.LongMint || t == CommitType.LongBurn;
    }

    /**
     * @notice Determines whether the provided commitment type represents a
     *          short
     * @return Boolean indicating if `t` is short
     */
    function isShort(CommitType t) external pure override returns (bool) {
        return t == CommitType.ShortMint || t == CommitType.ShortBurn;
    }

    /**
     * @notice Initialises the contract
     * @param _factory Address of the associated `PoolFactory` contract
     * @param _autoClaim Address of the associated `AutoClaim` contract
     * @param _factoryOwner Address of the owner of the `PoolFactory`
     * @param _invariantCheck Address of the `InvariantCheck` contract
     * @param _mintingFee The percentage that is taken from each mint, given as a decimal * 10 ^ 18
     * @param _burningFee The percentage that is taken from each burn, given as a decimal * 10 ^ 18
     * @param _changeInterval The amount that the `mintingFee` will change each update interval, based on `updateMintingFee`, given as a decimal * 10 ^ 18 (same format as `_mintingFee`)
     * @dev Throws if factory contract address is null
     * @dev Throws if autoClaim contract address is null
     * @dev Throws if autoclaim contract address is null
     * @dev Only callable by the associated initializer address
     * @dev Throws if minting fee is over MAX_MINTING_FEE
     * @dev Throws if burning fee is over MAX_BURNING_FEE
     * @dev Throws if changeInterval is over MAX_CHANGE_INTERVAL
     * @dev Emits a `ChangeIntervalSet` event on success
     */
    function initialize(
        address _factory,
        address _autoClaim,
        address _factoryOwner,
        address _feeController,
        address _invariantCheck,
        uint256 _mintingFee,
        uint256 _burningFee,
        uint256 _changeInterval
    ) external override initializer {
        require(_factory != address(0), "Factory cannot be null");
        require(_autoClaim != address(0), "AutoClaim cannot be null");
        require(_feeController != address(0), "fee controller cannot be null");
        require(_invariantCheck != address(0), "invariantCheck cannot be null");
        updateIntervalId = 1;
        factory = _factory;
        invariantCheck = _invariantCheck;
        mintingFee = PoolSwapLibrary.convertUIntToDecimal(_mintingFee);
        burningFee = PoolSwapLibrary.convertUIntToDecimal(_burningFee);
        changeInterval = PoolSwapLibrary.convertUIntToDecimal(_changeInterval);
        require(mintingFee <= MAX_MINTING_FEE, "Minting fee exceeds limit");
        require(burningFee <= MAX_BURNING_FEE, "Burning fee exceeds limit");
        require(changeInterval <= MAX_CHANGE_INTERVAL, "Change Interval exceeds limit");

        feeController = _feeController;
        autoClaim = IAutoClaim(_autoClaim);
        governance = _factoryOwner;
    }

    /**
     * @notice Apply commitment data to storage
     * @param pool The LeveragedPool of this PoolCommitter instance
     * @param commitType The type of commitment being made
     * @param amount The amount of tokens being committed
     * @param fromAggregateBalance If minting, burning, or rebalancing into a delta neutral position,
     *                             will tokens be taken from user's aggregate balance?
     * @param userCommit The appropriate update interval's commitment data for the user
     * @param totalCommit The appropriate update interval's commitment data for the entire pool
     */
    function applyCommitment(
        ILeveragedPool pool,
        CommitType commitType,
        uint256 amount,
        bool fromAggregateBalance,
        UserCommitment storage userCommit,
        TotalCommitment storage totalCommit
    ) private {
        Balance memory balance = userAggregateBalance[msg.sender];
        uint256 feeAmount;

        if (this.isMint(commitType)) {
            // We want to deduct the amount of settlement tokens that will be recorded under the commit by the minting fee
            // and then add it to the correct side of the pool
            feeAmount = PoolSwapLibrary.mintingOrBurningFee(mintingFee, amount);
            amount = amount - feeAmount;
            pendingMintSettlementAmount += amount;
        }

        if (commitType == CommitType.LongMint) {
            (uint256 shortBalance, uint256 longBalance) = pool.balances();
            userCommit.longMintSettlement += amount;
            totalCommit.longMintSettlement += amount;
            // Add the fee to long side. This has been taken from the commit amount.
            pool.setNewPoolBalances(longBalance + feeAmount, shortBalance);
            // If we are minting from balance, this would already have thrown in `commit` if we are minting more than entitled too
        } else if (commitType == CommitType.LongBurn) {
            pendingLongBurnPoolTokens += amount;
            userCommit.longBurnPoolTokens += amount;
            totalCommit.longBurnPoolTokens += amount;
            // long burning: pull in long pool tokens from committer
            if (fromAggregateBalance) {
                // Burning from user's aggregate balance
                require(amount <= balance.longTokens, "Insufficient pool tokens");
                userAggregateBalance[msg.sender].longTokens -= amount;
                // Burn from leveragedPool, because that is the official owner of the tokens before they are claimed
                pool.burnTokens(LONG_INDEX, amount, leveragedPool);
            } else {
                // Burning from user's wallet
                pool.burnTokens(LONG_INDEX, amount, msg.sender);
            }
        } else if (commitType == CommitType.ShortMint) {
            (uint256 shortBalance, uint256 longBalance) = pool.balances();
            userCommit.shortMintSettlement += amount;
            totalCommit.shortMintSettlement += amount;
            // Add the fee to short side. This has been taken from the commit amount.
            pool.setNewPoolBalances(longBalance, shortBalance + feeAmount);
            // If we are minting from balance, this would already have thrown in `commit` if we are minting more than entitled too
        } else if (commitType == CommitType.ShortBurn) {
            pendingShortBurnPoolTokens += amount;
            userCommit.shortBurnPoolTokens += amount;
            totalCommit.shortBurnPoolTokens += amount;
            if (fromAggregateBalance) {
                // Burning from user's aggregate balance
                require(amount <= balance.shortTokens, "Insufficient pool tokens");
                userAggregateBalance[msg.sender].shortTokens -= amount;
                // Burn from leveragedPool, because that is the official owner of the tokens before they are claimed
                pool.burnTokens(SHORT_INDEX, amount, leveragedPool);
            } else {
                // Burning from user's wallet
                pool.burnTokens(SHORT_INDEX, amount, msg.sender);
            }
        } else if (commitType == CommitType.LongBurnShortMint) {
            pendingLongBurnPoolTokens += amount;
            userCommit.longBurnShortMintPoolTokens += amount;
            totalCommit.longBurnShortMintPoolTokens += amount;
            if (fromAggregateBalance) {
                require(amount <= balance.longTokens, "Insufficient pool tokens");
                userAggregateBalance[msg.sender].longTokens -= amount;
                pool.burnTokens(LONG_INDEX, amount, leveragedPool);
            } else {
                pool.burnTokens(LONG_INDEX, amount, msg.sender);
            }
        } else if (commitType == CommitType.ShortBurnLongMint) {
            pendingShortBurnPoolTokens += amount;
            userCommit.shortBurnLongMintPoolTokens += amount;
            totalCommit.shortBurnLongMintPoolTokens += amount;
            if (fromAggregateBalance) {
                require(amount <= balance.shortTokens, "Insufficient pool tokens");
                userAggregateBalance[msg.sender].shortTokens -= amount;
                pool.burnTokens(SHORT_INDEX, amount, leveragedPool);
            } else {
                pool.burnTokens(SHORT_INDEX, amount, msg.sender);
            }
        }
    }

    /**
     * @notice Commit to minting/burning long/short tokens after the next price change
     * @param args Arguments for the commit function packed into one bytes32
     *  _______________________________________________________________________________________
     * |   104 bits  |     8 bits    |        8 bits        |    8 bits    |      128 bits     |
     * |  0-padding  |  payForClaim  | fromAggregateBalance |  commitType  |  shortenedAmount  |
     *  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
     * @dev Arguments can be encoded with `L2Encoder.encodeCommitParams`
     * @dev bool payForClaim: True if user wants to pay for the commit to be claimed
     * @dev bool fromAggregateBalance: If minting, burning, or rebalancing into a delta neutral position,
     *                                 will tokens be taken from user's aggregate balance?
     * @dev CommitType commitType: Type of commit you're doing (Long vs Short, Mint vs Burn)
     * @dev uint128 shortenedAmount: Amount of settlement tokens you want to commit to minting; OR amount of pool
     *                               tokens you want to burn. Expanded to uint256 at decode time
     * @dev Emits a `CreateCommit` event on success
     */
    function commit(bytes32 args) external payable override {
        (uint256 amount, CommitType commitType, bool fromAggregateBalance, bool payForClaim) = CalldataLogic
            .decodeCommitParams(args);
        require(amount > 0, "Amount must not be zero");
        updateAggregateBalance(msg.sender);
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256 updateInterval = pool.updateInterval();
        uint256 lastPriceTimestamp = pool.lastPriceTimestamp();
        uint256 frontRunningInterval = pool.frontRunningInterval();

        uint256 appropriateUpdateIntervalId = PoolSwapLibrary.appropriateUpdateIntervalId(
            block.timestamp,
            lastPriceTimestamp,
            frontRunningInterval,
            updateInterval,
            updateIntervalId
        );
        TotalCommitment storage totalCommit = totalPoolCommitments[appropriateUpdateIntervalId];
        UserCommitment storage userCommit = userCommitments[msg.sender][appropriateUpdateIntervalId];

        if (userCommit.updateIntervalId == 0) {
            userCommit.updateIntervalId = appropriateUpdateIntervalId;
        }

        uint256 length = unAggregatedCommitments[msg.sender].length;
        if (length == 0 || unAggregatedCommitments[msg.sender][length - 1] < appropriateUpdateIntervalId) {
            // Push to the array if the most recent commitment was done in a prior update interval
            unAggregatedCommitments[msg.sender].push(appropriateUpdateIntervalId);
        }

        /*
         * Below, we want to follow the "Checks, Effects, Interactions" pattern.
         * `applyCommitment` adheres to the pattern, so we must put our effects before this, and interactions after.
         * Hence, we do the storage change if `fromAggregateBalance == true` before calling `applyCommitment`, and do the interaction if `fromAggregateBalance == false` after.
         * Lastly, we call `AutoClaim::makePaidClaimRequest`, which is an external interaction (albeit with a protocol contract).
         */
        if (this.isMint(commitType) && fromAggregateBalance) {
            // Want to take away from their balance's settlement tokens
            require(amount <= userAggregateBalance[msg.sender].settlementTokens, "Insufficient settlement tokens");
            userAggregateBalance[msg.sender].settlementTokens -= amount;
        }

        applyCommitment(pool, commitType, amount, fromAggregateBalance, userCommit, totalCommit);

        if (this.isMint(commitType) && !fromAggregateBalance) {
            // minting: pull in the settlement token from the committer
            // Do not need to transfer if minting using aggregate balance tokens, since the leveraged pool already owns these tokens.
            pool.settlementTokenTransferFrom(msg.sender, leveragedPool, amount);
        }

        if (payForClaim) {
            require(msg.value != 0, "Must pay for claim");
            autoClaim.makePaidClaimRequest{value: msg.value}(msg.sender);
        } else {
            require(msg.value == 0, "msg.value must be zero");
        }

        emit CreateCommit(
            msg.sender,
            amount,
            commitType,
            appropriateUpdateIntervalId,
            fromAggregateBalance,
            payForClaim,
            mintingFee
        );
    }

    /**
     * @notice Claim user's balance. This can be done either by the user themself or by somebody else on their behalf.
     * @param user Address of the user to claim against
     * @dev Updates aggregate user balances
     * @dev Emits a `Claim` event on success
     */
    function claim(address user) external override onlyAutoClaimOrCommitter(user) onlyUnpaused {
        updateAggregateBalance(user);
        Balance memory balance = userAggregateBalance[user];
        ILeveragedPool pool = ILeveragedPool(leveragedPool);

        /* update bookkeeping *before* external calls! */
        delete userAggregateBalance[user];
        emit Claim(user);

        if (msg.sender == user && autoClaim.checkUserClaim(user, address(this))) {
            // If the committer is claiming for themself and they have a valid pending claim, clear it.
            autoClaim.withdrawUserClaimRequest(user);
        }

        if (balance.settlementTokens > 0) {
            pool.settlementTokenTransfer(user, balance.settlementTokens);
        }
        if (balance.longTokens > 0) {
            pool.poolTokenTransfer(true, user, balance.longTokens);
        }
        if (balance.shortTokens > 0) {
            pool.poolTokenTransfer(false, user, balance.shortTokens);
        }
    }

    /**
     * @notice Retrieves minting fee from each mint being left in the pool
     * @return Minting fee
     */
    function getMintingFee() external view returns (uint256) {
        return PoolSwapLibrary.convertDecimalToUInt(mintingFee);
    }

    /**
     * @notice Retrieves burning fee from each burn being left in the pool
     * @return Burning fee
     */
    function getBurningFee() external view returns (uint256) {
        return PoolSwapLibrary.convertDecimalToUInt(burningFee);
    }

    /**
     * @notice Executes every commitment specified in the list
     * @param _commits Array of `TotalCommitment`s
     * @param executionTracking A struct containing the update interval ID being executed, and the long and short total supplies
     * @param longBalance The amount of settlement tokens in the long side of the pool
     * @param shortBalance The amount of settlement tokens in the short side of the pool
     * @return newLongTotalSupply The total supply of long pool tokens as a result of minting
     * @return newShortTotalSupply The total supply of short pool tokens as a result of minting
     * @return newLongBalance The amount of settlement tokens in the long side of the pool as a result of minting and burning
     * @return newShortBalance The amount of settlement tokens in the short side of the pool as a result of minting and burning
     */
    function executeGivenCommitments(
        TotalCommitment memory _commits,
        CommitmentExecutionTracking memory executionTracking,
        uint256 longBalance,
        uint256 shortBalance
    )
        internal
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        pendingMintSettlementAmount =
            pendingMintSettlementAmount -
            totalPoolCommitments[executionTracking._updateIntervalId].longMintSettlement -
            totalPoolCommitments[executionTracking._updateIntervalId].shortMintSettlement;

        BalancesAndSupplies memory balancesAndSupplies = BalancesAndSupplies({
            newShortBalance: _commits.shortMintSettlement + shortBalance,
            newLongBalance: _commits.longMintSettlement + longBalance,
            longMintPoolTokens: 0,
            shortMintPoolTokens: 0,
            longBurnInstantMintSettlement: 0,
            shortBurnInstantMintSettlement: 0,
            totalLongBurnPoolTokens: _commits.longBurnPoolTokens + _commits.longBurnShortMintPoolTokens,
            totalShortBurnPoolTokens: _commits.shortBurnPoolTokens + _commits.shortBurnLongMintPoolTokens
        });

        bytes16 longPrice = PoolSwapLibrary.getPrice(
            longBalance,
            executionTracking.longTotalSupply + pendingLongBurnPoolTokens
        );
        bytes16 shortPrice = PoolSwapLibrary.getPrice(
            shortBalance,
            executionTracking.shortTotalSupply + pendingShortBurnPoolTokens
        );
        // Update price before values change
        priceHistory[executionTracking._updateIntervalId] = Prices({longPrice: longPrice, shortPrice: shortPrice});

        // Amount of collateral tokens that are generated from the long burn into instant mints
        {
            (uint256 mintSettlement, , ) = PoolSwapLibrary.processBurnInstantMintCommit(
                _commits.longBurnShortMintPoolTokens,
                longPrice,
                burningFee,
                mintingFee
            );
            balancesAndSupplies.longBurnInstantMintSettlement = mintSettlement;
        }

        balancesAndSupplies.newShortBalance += balancesAndSupplies.longBurnInstantMintSettlement;
        // Amount of collateral tokens that are generated from the short burn into instant mints
        {
            (uint256 mintSettlement, , ) = PoolSwapLibrary.processBurnInstantMintCommit(
                _commits.shortBurnLongMintPoolTokens,
                shortPrice,
                burningFee,
                mintingFee
            );
            balancesAndSupplies.shortBurnInstantMintSettlement = mintSettlement;
        }
        balancesAndSupplies.newLongBalance += balancesAndSupplies.shortBurnInstantMintSettlement;

        // Long Mints
        balancesAndSupplies.longMintPoolTokens = PoolSwapLibrary.getMintAmount(
            executionTracking.longTotalSupply, // long token total supply,
            _commits.longMintSettlement + balancesAndSupplies.shortBurnInstantMintSettlement, // Add the settlement tokens that will be generated from burning shorts for instant long mint
            longBalance, // total quote tokens in the long pool
            pendingLongBurnPoolTokens // total pool tokens commited to be burned
        );

        // Long Burns
        balancesAndSupplies.newLongBalance -= PoolSwapLibrary.getWithdrawAmountOnBurn(
            executionTracking.longTotalSupply,
            balancesAndSupplies.totalLongBurnPoolTokens,
            longBalance,
            pendingLongBurnPoolTokens
        );

        // Short Mints
        balancesAndSupplies.shortMintPoolTokens = PoolSwapLibrary.getMintAmount(
            executionTracking.shortTotalSupply, // short token total supply
            _commits.shortMintSettlement + balancesAndSupplies.longBurnInstantMintSettlement, // Add the settlement tokens that will be generated from burning longs for instant short mint
            shortBalance,
            pendingShortBurnPoolTokens
        );

        // Short Burns
        balancesAndSupplies.newShortBalance -= PoolSwapLibrary.getWithdrawAmountOnBurn(
            executionTracking.shortTotalSupply,
            balancesAndSupplies.totalShortBurnPoolTokens,
            shortBalance,
            pendingShortBurnPoolTokens
        );

        pendingLongBurnPoolTokens -= balancesAndSupplies.totalLongBurnPoolTokens;
        pendingShortBurnPoolTokens -= balancesAndSupplies.totalShortBurnPoolTokens;

        return (
            executionTracking.longTotalSupply + balancesAndSupplies.longMintPoolTokens,
            executionTracking.shortTotalSupply + balancesAndSupplies.shortMintPoolTokens,
            balancesAndSupplies.newLongBalance,
            balancesAndSupplies.newShortBalance
        );
    }

    /**
     * @notice Executes all commitments currently queued for the associated `LeveragedPool`
     * @dev Only callable by the associated `LeveragedPool` contract
     * @dev Emits an `ExecutedCommitsForInterval` event for each update interval processed
     * @param lastPriceTimestamp The timestamp when the last price update happened
     * @param updateInterval The number of seconds that must occur between upkeeps
     * @param longBalance The amount of settlement tokens in the long side of the pool
     * @param shortBalance The amount of settlement tokens in the short side of the pool
     * @return longTotalSupplyChange The amount of long pool tokens that have been added to the supply, passed back to LeveragedPool to mint them.
     * @return shortTotalSupplyChange The amount of short pool tokens that have been added to the supply, passed back to LeveragedPool to mint them.
     * @return newLongBalance The updated longBalance
     * @return newShortBalance The updated longBalance
     * @return lastPriceTimestamp The correct price timestamp for LeveragedPool to set. This is in case not all update intervals get upkept, we can track the time of the most recent upkept one.
     */
    function executeCommitments(
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 longBalance,
        uint256 shortBalance
    )
        external
        override
        onlyPool
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint8 counter = 1;

        /*
         * (old)
         * updateIntervalId
         * |
         * |    updateIntervalId
         * |    |
         * |    |    counter
         * |    |    |
         * |    |    |              (end)
         * |    |    |              |
         * V    V    V              V
         * +----+----+----+~~~~+----+
         * |    |    |    |....|    |
         * +----+----+----+~~~~+----+
         *
         * Iterate over the sequence of possible update periods from the most
         * recent (i.e., the value of `updateIntervalId` as at the entry point
         * of this function) until the end of the queue.
         *
         * At each iteration, execute all of the (total) commitments for the
         * pool for that period and then remove them from the queue.
         *
         * In reality, this should never iterate more than once, since more than one update interval
         * should never be passed without the previous one being upkept.
         */

        CommitmentExecutionTracking memory executionTracking = CommitmentExecutionTracking({
            longTotalSupply: IERC20(tokens[LONG_INDEX]).totalSupply(),
            shortTotalSupply: IERC20(tokens[SHORT_INDEX]).totalSupply(),
            longTotalSupplyBefore: 0,
            shortTotalSupplyBefore: 0,
            _updateIntervalId: 0
        });

        executionTracking.longTotalSupplyBefore = executionTracking.longTotalSupply;
        executionTracking.shortTotalSupplyBefore = executionTracking.shortTotalSupply;

        while (counter <= MAX_ITERATIONS) {
            if (block.timestamp >= lastPriceTimestamp + updateInterval * counter) {
                // Another update interval has passed, so we have to do the nextIntervalCommit as well
                executionTracking._updateIntervalId = updateIntervalId;
                burnFeeHistory[executionTracking._updateIntervalId] = burningFee;
                (
                    executionTracking.longTotalSupply,
                    executionTracking.shortTotalSupply,
                    longBalance,
                    shortBalance
                ) = executeGivenCommitments(
                    totalPoolCommitments[executionTracking._updateIntervalId],
                    executionTracking,
                    longBalance,
                    shortBalance
                );
                emit ExecutedCommitsForInterval(executionTracking._updateIntervalId, burningFee);
                delete totalPoolCommitments[executionTracking._updateIntervalId];

                // update interval realistically won't overflow for the foreseeable future
                unchecked {
                    updateIntervalId += 1;
                }
            } else {
                break;
            }

            // counter overflowing would require an unrealistic number of update intervals to be updated
            // This wouldn't fit in a block, anyway.
            unchecked {
                counter += 1;
            }
        }

        updateMintingFee(
            PoolSwapLibrary.getPrice(longBalance, executionTracking.longTotalSupply),
            PoolSwapLibrary.getPrice(shortBalance, executionTracking.shortTotalSupply)
        );

        // if we maxed out the number of intervals upkept and projected lastPriceTimestamp is >= than `updateInterval` seconds ago
        // it means there are more intervals to upkeep (equal means that another upkeep is due right now but we already ran out of iterations)
        // counter will be MAX_ITERATIONS + 1 if we hit max iterations because of the loop condition `while (counter <= MAX_ITERATIONS)`
        if (
            counter > MAX_ITERATIONS &&
            (block.timestamp - (lastPriceTimestamp + updateInterval * (counter - 1))) >= updateInterval
        ) {
            // shift lastPriceTimestamp so next time the executeCommitments() will continue where it left off
            lastPriceTimestamp = lastPriceTimestamp + updateInterval * (counter - 1);
        } else {
            // Set to current time if finished every update interval
            lastPriceTimestamp = block.timestamp;
        }
        return (
            executionTracking.longTotalSupply - executionTracking.longTotalSupplyBefore,
            executionTracking.shortTotalSupply - executionTracking.shortTotalSupplyBefore,
            longBalance,
            shortBalance,
            lastPriceTimestamp
        );
    }

    function updateMintingFee(bytes16 longTokenPrice, bytes16 shortTokenPrice) private {
        bytes16 multiple = PoolSwapLibrary.multiplyBytes(longTokenPrice, shortTokenPrice);
        if (PoolSwapLibrary.compareDecimals(PoolSwapLibrary.ONE, multiple) == -1) {
            // longTokenPrice * shortTokenPrice > 1
            if (PoolSwapLibrary.compareDecimals(mintingFee, changeInterval) == -1) {
                // mintingFee < changeInterval. Prevent underflow by setting mintingFee to lowest acceptable value (0)
                mintingFee = 0;
            } else {
                mintingFee = PoolSwapLibrary.subtractBytes(mintingFee, changeInterval);
            }
        } else {
            // longTokenPrice * shortTokenPrice <= 1
            mintingFee = PoolSwapLibrary.addBytes(mintingFee, changeInterval);

            if (PoolSwapLibrary.compareDecimals(mintingFee, MAX_MINTING_FEE) == 1) {
                // mintingFee is greater than 1 (100%).
                // We want to cap this at a theoretical max of 100%
                mintingFee = MAX_MINTING_FEE;
            }
        }
    }

    /**
     * @notice Updates the aggregate balance based on the result of application
     *          of the provided (user) commitment
     * @param _commit Commitment to apply
     * @return The PoolSwapLibrary.UpdateResult struct with the data pertaining to the update of user's aggregate balance
     * @dev Wraps two (pure) library functions from `PoolSwapLibrary`
     */
    function getBalanceSingleCommitment(UserCommitment memory _commit)
        internal
        view
        returns (PoolSwapLibrary.UpdateResult memory)
    {
        PoolSwapLibrary.UpdateData memory updateData = PoolSwapLibrary.UpdateData({
            longPrice: priceHistory[_commit.updateIntervalId].longPrice,
            shortPrice: priceHistory[_commit.updateIntervalId].shortPrice,
            currentUpdateIntervalId: updateIntervalId,
            updateIntervalId: _commit.updateIntervalId,
            longMintSettlement: _commit.longMintSettlement,
            longBurnPoolTokens: _commit.longBurnPoolTokens,
            shortMintSettlement: _commit.shortMintSettlement,
            shortBurnPoolTokens: _commit.shortBurnPoolTokens,
            longBurnShortMintPoolTokens: _commit.longBurnShortMintPoolTokens,
            shortBurnLongMintPoolTokens: _commit.shortBurnLongMintPoolTokens,
            burnFee: burnFeeHistory[_commit.updateIntervalId],
            mintingFeeRate: mintingFee
        });

        return PoolSwapLibrary.getUpdatedAggregateBalance(updateData);
    }

    /**
     * @notice Add the result of a user's most recent commit to their aggregated balance
     * @param user Address of the given user
     * @dev Updates the `userAggregateBalance` mapping by applying `BalanceUpdate`s derived from iteration over the entirety of unaggregated commitments associated with the given user
     * @dev Emits an `AggregateBalanceUpdated` event upon successful termination
     */
    function updateAggregateBalance(address user) public override {
        Balance storage balance = userAggregateBalance[user];

        BalanceUpdate memory update = BalanceUpdate({
            _updateIntervalId: updateIntervalId,
            _newLongTokensSum: 0,
            _newShortTokensSum: 0,
            _newSettlementTokensSum: 0,
            _longSettlementFee: 0,
            _shortSettlementFee: 0,
            _maxIterations: 0
        });

        uint256[] memory currentIntervalIds = unAggregatedCommitments[user];
        uint256 unAggregatedLength = currentIntervalIds.length;

        update._maxIterations = unAggregatedLength < MAX_ITERATIONS ? uint8(unAggregatedLength) : MAX_ITERATIONS; // casting to uint8 is safe because we know it is less than MAX_ITERATIONS, a uint8

        // Iterate from the most recent up until the current update interval
        for (uint256 i = 0; i < update._maxIterations; i = unchecked_inc(i)) {
            uint256 id = currentIntervalIds[i];
            if (id == 0) {
                continue;
            }
            UserCommitment memory commitment = userCommitments[user][id];

            if (commitment.updateIntervalId < updateIntervalId) {
                PoolSwapLibrary.UpdateResult memory result = getBalanceSingleCommitment(commitment);
                update._newLongTokensSum += result._newLongTokens;
                update._newShortTokensSum += result._newShortTokens;
                // result._newSettlementTokens has already been decremented by the minting fees from the `LongBurnShortMint` and `ShortBurnLongMint` commits.
                update._newSettlementTokensSum += result._newSettlementTokens;
                update._longSettlementFee += result._longSettlementFee;
                update._shortSettlementFee += result._shortSettlementFee;
                delete userCommitments[user][id];
                uint256[] storage commitmentIds = unAggregatedCommitments[user];
                if (unAggregatedLength > MAX_ITERATIONS && commitmentIds.length > 1 && i < commitmentIds.length - 1) {
                    // We only enter this branch if our iterations are capped (i.e. we do not delete the array after the loop)
                    // Order doesn't actually matter in this array, so we can just put the last element into this index
                    commitmentIds[i] = commitmentIds[commitmentIds.length - 1];
                }
                commitmentIds.pop();
            } else {
                // This commitment wasn't ready to be completely added to the balance, so copy it over into the new ID array
                if (unAggregatedLength <= MAX_ITERATIONS) {
                    storageArrayPlaceHolder.push(currentIntervalIds[i]);
                }
            }
        }

        if (unAggregatedLength <= MAX_ITERATIONS) {
            // We got through all update intervals, so we can replace all unaggregated update interval IDs
            unAggregatedCommitments[user] = storageArrayPlaceHolder;
            delete storageArrayPlaceHolder;
        }

        // Add new tokens minted, and remove the ones that were burnt from this balance
        balance.longTokens += update._newLongTokensSum;
        balance.shortTokens += update._newShortTokensSum;
        balance.settlementTokens += update._newSettlementTokensSum;

        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (uint256 shortBalance, uint256 longBalance) = pool.balances();
        pool.setNewPoolBalances(longBalance + update._longSettlementFee, shortBalance + update._shortSettlementFee);

        emit AggregateBalanceUpdated(user);
    }

    /**
     * @return which update interval ID a commit would be placed into if made now
     * @dev Calls PoolSwapLibrary::appropriateUpdateIntervalId
     */
    function getAppropriateUpdateIntervalId() external view override returns (uint128) {
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        return
            uint128(
                PoolSwapLibrary.appropriateUpdateIntervalId(
                    block.timestamp,
                    pool.lastPriceTimestamp(),
                    pool.frontRunningInterval(),
                    pool.updateInterval(),
                    updateIntervalId
                )
            );
    }

    /**
     * @notice A copy of `updateAggregateBalance` that returns the aggregated balance without updating it
     * @param user Address of the given user
     * @return Associated `Balance` for the given user after aggregation
     */
    function getAggregateBalance(address user) external view override returns (Balance memory) {
        Balance memory _balance = userAggregateBalance[user];

        BalanceUpdate memory update = BalanceUpdate({
            _updateIntervalId: updateIntervalId,
            _newLongTokensSum: 0,
            _newShortTokensSum: 0,
            _newSettlementTokensSum: 0,
            _longSettlementFee: 0,
            _shortSettlementFee: 0,
            _maxIterations: 0
        });

        uint256[] memory currentIntervalIds = unAggregatedCommitments[user];
        uint256 unAggregatedLength = currentIntervalIds.length;

        update._maxIterations = unAggregatedLength < MAX_ITERATIONS ? uint8(unAggregatedLength) : MAX_ITERATIONS; // casting to uint8 is safe because we know it is less than MAX_ITERATIONS, a uint8
        // Iterate from the most recent up until the current update interval
        for (uint256 i = 0; i < update._maxIterations; i = unchecked_inc(i)) {
            uint256 id = currentIntervalIds[i];
            if (id == 0) {
                continue;
            }
            UserCommitment memory commitment = userCommitments[user][id];

            /* If the update interval of commitment has not yet passed, we still
            want to deduct burns from the balance from a user's balance.
            Therefore, this should happen outside of the if block below.*/
            if (commitment.updateIntervalId < updateIntervalId) {
                PoolSwapLibrary.UpdateResult memory result = getBalanceSingleCommitment(commitment);
                update._newLongTokensSum += result._newLongTokens;
                update._newShortTokensSum += result._newShortTokens;
                // result._newSettlementTokens has already been decremented by the minting fees from the `LongBurnShortMint` and `ShortBurnLongMint` commits.
                update._newSettlementTokensSum += result._newSettlementTokens;
            }
        }

        // Add new tokens minted, and remove the ones that were burnt from this balance
        _balance.longTokens += update._newLongTokensSum;
        _balance.shortTokens += update._newShortTokensSum;
        _balance.settlementTokens += update._newSettlementTokensSum;

        return _balance;
    }

    /**
     * @notice Sets the settlement token address and the address of the associated `LeveragedPool` contract to the provided values
     * @param _leveragedPool Address of the pool to use
     * @dev Only callable by the associated `PoolFactory` contract
     * @dev Throws if either address are null
     * @dev Emits a `PoolChanged` event on success
     */
    function setPool(address _leveragedPool) external override onlyFactory {
        require(_leveragedPool != address(0), "Leveraged pool cannot be null");

        leveragedPool = _leveragedPool;
        tokens = ILeveragedPool(leveragedPool).poolTokens();
        emit PoolChanged(_leveragedPool);
    }

    /**
     * @notice Sets the burning fee to be applied to future burn commitments indefinitely
     * @param _burningFee The new burning fee
     * @dev Converts `_burningFee` to a `bytes16` to be compatible with arithmetic library
     * @dev Emits a `BurningFeeSet` event on success
     */
    function setBurningFee(uint256 _burningFee) external override onlyFeeController {
        burningFee = PoolSwapLibrary.convertUIntToDecimal(_burningFee);
        require(burningFee < MAX_BURNING_FEE, "Burning fee >= 10%");
        emit BurningFeeSet(_burningFee);
    }

    /**
     * @notice Sets the minting fee to be applied to future burn commitments indefinitely
     * @param _mintingFee The new minting fee
     * @dev Converts `_mintingFee` to a `bytes16` to be compatible with arithmetic library
     * @dev Emits a `MintingFeeSet` event on success
     */
    function setMintingFee(uint256 _mintingFee) external override onlyFeeController {
        mintingFee = PoolSwapLibrary.convertUIntToDecimal(_mintingFee);
        require(mintingFee <= MAX_MINTING_FEE, "Minting fee > 100%");
        emit MintingFeeSet(_mintingFee);
    }

    /**
     * @notice Sets the change interval used to update the minting fee every update interval
     * @param _changeInterval The new change interval
     * @dev Converts `_changeInterval` to a `bytes16` to be compatible with arithmetic library TODO UPDATE
     * @dev Emits a `ChangeIntervalSet` event on success
     */
    function setChangeInterval(uint256 _changeInterval) external override onlyFeeController {
        changeInterval = PoolSwapLibrary.convertUIntToDecimal(_changeInterval);
        require(changeInterval <= MAX_CHANGE_INTERVAL, "Change Interval exceeds limit");
        emit ChangeIntervalSet(_changeInterval);
    }

    function setFeeController(address _feeController) external override {
        require(msg.sender == governance || msg.sender == feeController, "Cannot set feeController");
        feeController = _feeController;
        emit FeeControllerSet(_feeController);
    }

    /**
     * @notice Pauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function pause() external override onlyInvariantCheckContract {
        paused = true;
        emit Paused();
    }

    /**
     * @notice Unpauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function unpause() external override onlyGov {
        paused = false;
        emit Unpaused();
    }

    function unchecked_inc(uint256 i) private pure returns (uint256) {
        unchecked {
            return ++i;
        }
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The interface for the contract that handles pool commitments
interface IPoolCommitter {
    /// Type of commit
    enum CommitType {
        ShortMint, // Mint short tokens
        ShortBurn, // Burn short tokens
        LongMint, // Mint long tokens
        LongBurn, // Burn long tokens
        LongBurnShortMint, // Burn Long tokens, then instantly mint in same upkeep
        ShortBurnLongMint // Burn Short tokens, then instantly mint in same upkeep
    }

    function isMint(CommitType t) external pure returns (bool);

    function isBurn(CommitType t) external pure returns (bool);

    function isLong(CommitType t) external pure returns (bool);

    function isShort(CommitType t) external pure returns (bool);

    // Pool balances and supplies
    struct BalancesAndSupplies {
        uint256 newShortBalance;
        uint256 newLongBalance;
        uint256 longMintPoolTokens;
        uint256 shortMintPoolTokens;
        uint256 longBurnInstantMintSettlement;
        uint256 shortBurnInstantMintSettlement;
        uint256 totalLongBurnPoolTokens;
        uint256 totalShortBurnPoolTokens;
    }

    // User aggregate balance
    struct Balance {
        uint256 longTokens;
        uint256 shortTokens;
        uint256 settlementTokens;
    }

    // Token Prices
    struct Prices {
        bytes16 longPrice;
        bytes16 shortPrice;
    }

    // Commit information
    struct Commit {
        uint256 amount;
        CommitType commitType;
        uint40 created;
        address owner;
    }

    // Commit information
    struct TotalCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
    }

    // User updated aggregate balance
    struct BalanceUpdate {
        uint256 _updateIntervalId;
        uint256 _newLongTokensSum;
        uint256 _newShortTokensSum;
        uint256 _newSettlementTokensSum;
        uint256 _longSettlementFee;
        uint256 _shortSettlementFee;
        uint8 _maxIterations;
    }

    // Track how much of a user's commitments are being done from their aggregate balance
    struct UserCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
        uint256 updateIntervalId;
    }

    // Track the relevant data when executing a range of update interval's commitments (stack too deep)
    struct CommitmentExecutionTracking {
        uint256 longTotalSupply;
        uint256 shortTotalSupply;
        uint256 longTotalSupplyBefore;
        uint256 shortTotalSupplyBefore;
        uint256 _updateIntervalId;
    }

    /**
     * @notice Creates a notification when a commit is created
     * @param user The user making the commitment
     * @param amount Amount of the commit
     * @param commitType Type of the commit (Short v Long, Mint v Burn)
     * @param appropriateUpdateIntervalId Id of update interval where this commit can be executed as part of upkeep
     * @param fromAggregateBalance whether or not to commit from aggregate (unclaimed) balance
     * @param payForClaim whether or not to request this commit be claimed automatically
     * @param mintingFee Minting fee at time of commit creation
     */
    event CreateCommit(
        address indexed user,
        uint256 indexed amount,
        CommitType indexed commitType,
        uint256 appropriateUpdateIntervalId,
        bool fromAggregateBalance,
        bool payForClaim,
        bytes16 mintingFee
    );

    /**
     * @notice Creates a notification when a user's aggregate balance is updated
     */
    event AggregateBalanceUpdated(address indexed user);

    /**
     * @notice Creates a notification when the PoolCommitter's leveragedPool address has been updated.
     * @param newPool the address of the new leveraged pool
     */
    event PoolChanged(address indexed newPool);

    /**
     * @notice Creates a notification when commits for a given update interval are executed
     * @param updateIntervalId Unique identifier for the relevant update interval
     * @param burningFee Burning fee at the time of commit execution
     */
    event ExecutedCommitsForInterval(uint256 indexed updateIntervalId, bytes16 burningFee);

    /**
     * @notice Creates a notification when a claim is made, depositing pool tokens in user's wallet
     */
    event Claim(address indexed user);

    /*
     * @notice Creates a notification when the burningFee is updated
     */
    event BurningFeeSet(uint256 indexed _burningFee);

    /**
     * @notice Creates a notification when the mintingFee is updated
     */
    event MintingFeeSet(uint256 indexed _mintingFee);

    /**
     * @notice Creates a notification when the changeInterval is updated
     */
    event ChangeIntervalSet(uint256 indexed _changeInterval);

    /**
     * @notice Creates a notification when the feeController is updated
     */
    event FeeControllerSet(address indexed _feeController);

    // #### Functions

    function initialize(
        address _factory,
        address _autoClaim,
        address _factoryOwner,
        address _feeController,
        address _invariantCheck,
        uint256 mintingFee,
        uint256 burningFee,
        uint256 _changeInterval
    ) external;

    function commit(bytes32 args) external payable;

    function updateIntervalId() external view returns (uint128);

    function pendingMintSettlementAmount() external view returns (uint256);

    function pendingShortBurnPoolTokens() external view returns (uint256);

    function pendingLongBurnPoolTokens() external view returns (uint256);

    function claim(address user) external;

    function executeCommitments(
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 longBalance,
        uint256 shortBalance
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function updateAggregateBalance(address user) external;

    function getAggregateBalance(address user) external view returns (Balance memory _balance);

    function getAppropriateUpdateIntervalId() external view returns (uint128);

    function setPool(address _leveragedPool) external;

    function setBurningFee(uint256 _burningFee) external;

    function setMintingFee(uint256 _mintingFee) external;

    function setChangeInterval(uint256 _changeInterval) external;

    function setFeeController(address _feeController) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The pool controller contract interface
interface ILeveragedPool {
    // Initialisation parameters for new market
    struct Initialization {
        address _owner; // Owner of the contract
        address _keeper; // The address of the PoolKeeper contract
        address _oracleWrapper; // The oracle wrapper for the derivative price feed
        address _settlementEthOracle; // The oracle wrapper for the SettlementToken/ETH price feed
        address _longToken; // Address of the long pool token
        address _shortToken; // Address of the short pool token
        address _poolCommitter; // Address of the PoolCommitter contract
        address _invariantCheck; // Address of the InvariantCheck contract
        string _poolName; // The pool identification name
        uint32 _frontRunningInterval; // The minimum number of seconds that must elapse before a commit is forced to wait until the next interval
        uint32 _updateInterval; // The minimum number of seconds that must elapse before a commit can be executed
        uint16 _leverageAmount; // The amount of exposure to price movements for the pool
        uint256 _fee; // The fund movement fee. This amount is extracted from the deposited asset with every update and sent to the fee address. Given as the decimal * 10 ^ 18. For example, 60% fee is 0.6 * 10 ^ 18
        address _feeAddress; // The address that the fund movement fee is sent to
        address _secondaryFeeAddress; // The address of fee recieved by third party deployers
        address _settlementToken; //  The digital asset that the pool accepts. Must have a decimals() function
        uint256 _secondaryFeeSplitPercent; // Percent of fees that go to secondary fee address if it exists
    }

    // #### Events
    /**
     * @notice Creates a notification when the pool is setup and ready for use
     * @param longToken The address of the LONG pair token
     * @param shortToken The address of the SHORT pair token
     * @param settlementToken The address of the digital asset that the pool accepts
     * @param poolName The identification name of the pool
     */
    event PoolInitialized(
        address indexed longToken,
        address indexed shortToken,
        address settlementToken,
        string poolName
    );

    /**
     * @notice Creates a notification when the pool is rebalanced
     * @param shortBalanceChange The change of funds in the short side
     * @param longBalanceChange The change of funds in the long side
     * @param shortFeeAmount Proportional fee taken from short side
     * @param longFeeAmount Proportional fee taken from long side
     */
    event PoolRebalance(
        int256 shortBalanceChange,
        int256 longBalanceChange,
        uint256 shortFeeAmount,
        uint256 longFeeAmount
    );

    /**
     * @notice Creates a notification when the pool's price execution fails
     * @param startPrice Price prior to price change execution
     * @param endPrice Price during price change execution
     */
    event PriceChangeError(int256 indexed startPrice, int256 indexed endPrice);

    /**
     * @notice Represents change in fee receiver's address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event FeeAddressUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Represents change in secondary fee receiver's address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event SecondaryFeeAddressUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Represents change in keeper's address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event KeeperAddressChanged(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Indicates a payment of fees to the secondary fee address
     * @param secondaryFeeAddress The address that got fees paid to it
     * @param amount Amount of settlement token paid
     */
    event SecondaryFeesPaid(address indexed secondaryFeeAddress, uint256 amount);

    /**
     * @notice Indicates a payment of fees to the primary fee address
     * @param feeAddress The address that got fees paid to it
     * @param amount Amount of settlement token paid
     */
    event PrimaryFeesPaid(address indexed feeAddress, uint256 amount);

    /**
     * @notice Indicates settlement assets have been withdrawn from the system
     * @param to Receipient
     * @param quantity Quantity of settlement tokens withdrawn
     */
    event SettlementWithdrawn(address indexed to, uint256 indexed quantity);

    /**
     * @notice Indicates that the balance of pool tokens on issue for the pool
     *          changed
     * @param long New quantity of long pool tokens
     * @param short New quantity of short pool tokens
     */
    event PoolBalancesChanged(uint256 indexed long, uint256 indexed short);

    function leverageAmount() external view returns (bytes16);

    function poolCommitter() external view returns (address);

    function settlementToken() external view returns (address);

    function primaryFees() external view returns (uint256);

    function secondaryFees() external view returns (uint256);

    function oracleWrapper() external view returns (address);

    function lastPriceTimestamp() external view returns (uint256);

    function poolName() external view returns (string calldata);

    function updateInterval() external view returns (uint32);

    function shortBalance() external view returns (uint256);

    function longBalance() external view returns (uint256);

    function frontRunningInterval() external view returns (uint32);

    function poolTokens() external view returns (address[2] memory);

    function settlementEthOracle() external view returns (address);

    // #### Functions
    /**
     * @notice Configures the pool on deployment. The pools are EIP 1167 clones.
     * @dev This should only be able to be run once to prevent abuse of the pool. Use of Openzeppelin Initializable or similar is recommended
     * @param initialization The struct Initialization containing initialization data
     */
    function initialize(Initialization calldata initialization) external;

    function poolUpkeep(int256 _oldPrice, int256 _newPrice) external;

    function settlementTokenTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function payKeeperFromBalances(address to, uint256 amount) external returns (bool);

    function settlementTokenTransfer(address to, uint256 amount) external;

    function claimPrimaryFees() external;

    function claimSecondaryFees() external;

    /**
     * @notice Transfer pool tokens from pool to user
     * @param isLongToken True if transferring long pool token; False if transferring short pool token
     * @param to Address of account to transfer to
     * @param amount Amount of pool tokens being transferred
     * @dev Only callable by the associated `PoolCommitter` contract
     * @dev Only callable when the market is *not* paused
     */
    function poolTokenTransfer(
        bool isLongToken,
        address to,
        uint256 amount
    ) external;

    function setNewPoolBalances(uint256 _longBalance, uint256 _shortBalance) external;

    /**
     * @return _latestPrice The oracle price
     * @return _data The oracleWrapper's metadata. Implementations can choose what data to return here
     * @return _lastPriceTimestamp The timestamp of the last upkeep
     * @return _updateInterval The update frequency for this pool
     * @dev To save gas so PoolKeeper does not have to make three external calls
     */
    function getUpkeepInformation()
        external
        view
        returns (
            int256 _latestPrice,
            bytes memory _data,
            uint256 _lastPriceTimestamp,
            uint256 _updateInterval
        );

    function getOraclePrice() external view returns (int256);

    function intervalPassed() external view returns (bool);

    function balances() external view returns (uint256 _shortBalance, uint256 _longBalance);

    function setKeeper(address _keeper) external;

    function updateFeeAddress(address account) external;

    function updateSecondaryFeeAddress(address account) external;

    function burnTokens(
        uint256 tokenType,
        uint256 amount,
        address burner
    ) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The contract factory for the keeper and pool contracts. Utilizes minimal clones to keep gas costs low
interface IPoolFactory {
    struct PoolDeployment {
        string poolName; // The name to identify a pool by
        uint32 frontRunningInterval; // The minimum number of seconds that must elapse before a commit can be executed. Must be smaller than or equal to the update interval to prevent deadlock
        uint32 updateInterval; // The minimum number of seconds that must elapse before a price change
        uint16 leverageAmount; // The amount of exposure to price movements for the pool
        address settlementToken; // The digital asset that the pool accepts
        address oracleWrapper; // The IOracleWrapper implementation for fetching price feed data
        address settlementEthOracle; // The oracle to fetch the price of Ether in terms of the settlement token
        address feeController;
        // The fee taken for each mint and burn. Fee value as a decimal multiplied by 10^18. For example, 50% is represented as 0.5 * 10^18
        uint256 mintingFee; // The fee amount for mints
        uint256 changeInterval; // The interval at which the mintingFee in a market either increases or decreases, as per the logic in `PoolCommitter::updateMintingFee`
        uint256 burningFee; // The fee amount for burns
    }

    // #### Events
    /**
     * @notice Creates a notification when a pool is deployed
     * @param pool Address of the new pool
     * @param ticker Ticker of the new pool
     */
    event DeployPool(address indexed pool, address poolCommitter, string ticker);

    /**
     * @notice Indicates that the InvariantCheck contract has changed
     * @param invariantCheck New InvariantCheck contract
     */
    event InvariantCheckChanged(address indexed invariantCheck);

    /**
     * @notice Creates a notification when a PoolCommitter is deployed
     * @param poolCommitterAddress Address of new PoolCommitter
     * @param settlementToken Address of new settlementToken
     * @param pool Address of the pool associated with this PoolCommitter
     * @param changeInterval The amount that the `mintingFee` will change each update interval, based on `updateMintingFee`, given as a decimal * 10 ^ 18 (same format as `_mintingFee`)
     * @param feeController The address that has control over fee parameters
     */
    event DeployCommitter(
        address poolCommitterAddress,
        address settlementToken,
        address pool,
        uint256 changeInterval,
        address feeController
    );

    /**
     * @notice Creates a notification when the pool keeper changes
     * @param _poolKeeper Address of the new pool keeper
     */
    event PoolKeeperChanged(address _poolKeeper);

    /**
     * @notice Indicates that the maximum allowed leverage has changed
     * @param leverage New maximum allowed leverage value
     */
    event MaxLeverageChanged(uint256 indexed leverage);

    /**
     * @notice Indicates that the receipient of fees has changed
     * @param receiver Address of the new receipient of fees
     */
    event FeeReceiverChanged(address indexed receiver);

    /**
     * @notice Indicates that the receipient of fees has changed
     * @param fee Address of the new receipient of fees
     */
    event SecondaryFeeSplitChanged(uint256 indexed fee);

    /**
     * @notice Indicates that the trading fee has changed
     * @param fee New trading fee
     */
    event FeeChanged(uint256 indexed fee);

    /**
     * @notice Indicates that the AutoClaim contract has changed
     * @param autoClaim New AutoClaim contract
     */
    event AutoClaimChanged(address indexed autoClaim);

    /**
     * @notice Indicates that the minting and burning fees have changed
     * @param mint Minting fee
     * @param burn Burning fee
     */
    event MintAndBurnFeesChanged(uint256 indexed mint, uint256 indexed burn);

    /**
     * @notice Indicates that the deployment fee has changed
     * @param fee New deployment fee
     */
    event DeploymentFeeChanged(address _token, uint256 fee, address _receiver);

    // #### Getters for Globals
    function pools(uint256 id) external view returns (address);

    function numPools() external view returns (uint256);

    function isValidPool(address _pool) external view returns (bool);

    function isValidPoolCommitter(address _poolCommitter) external view returns (bool);

    function getPoolKeeper() external view returns (address);

    // #### Functions
    function deployPool(PoolDeployment calldata deploymentParameters) external returns (address);

    function setPoolKeeper(address _poolKeeper) external;

    function setAutoClaim(address _autoClaim) external;

    function setInvariantCheck(address _invariantCheck) external;

    function setFeeReceiver(address _feeReceiver) external;

    function setFee(uint256 _fee) external;

    function setDeploymentFee(
        address _token,
        uint256 _fee,
        address _receiver
    ) external;

    function setSecondaryFeeSplitPercent(uint256 newFeePercent) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

interface IAutoClaim {
    /**
     * @notice Creates a notification when an auto-claim request is updated. i.e. When another commit is added and reward is incremented.
     * @param user The user whose request got updated
     * @param poolCommitter The PoolCommitter instance in which the commits were made
     * @param updateIntervalId The update interval ID that the corresponding commitment was allocated for
     * @param newReward The new total reward for the auto-claim
     */
    event PaidClaimRequestUpdate(
        address indexed user,
        address indexed poolCommitter,
        uint256 indexed updateIntervalId,
        uint256 newReward
    );

    /**
     * @notice Creates a notification when an auto-claim request is executed
     * @param user The user whose request got executed
     * @param poolCommitter The PoolCommitter instance in which the original commit was made
     * @param reward The reward for the auto-claim
     */
    event PaidRequestExecution(address indexed user, address indexed poolCommitter, uint256 indexed reward);

    /**
     * @notice Creates a notification when an auto-claim request is withdrawn
     * @param user The user whose request got withdrawn
     * @param poolCommitter The PoolCommitter instance in which the original commit was made
     */
    event RequestWithdrawn(address indexed user, address indexed poolCommitter);

    struct ClaimRequest {
        uint128 updateIntervalId; // The update interval during which a user requested a claim.
        uint256 reward; // The amount of ETH in wei that was given by the user to pay for upkeep
    }

    /**
     * @notice Pay for your commit to be claimed. This means that a willing participant can claim on `user`'s behalf when the current update interval ends.
     * @dev Only callable by this contract's associated PoolCommitter instance. This prevents griefing. Consider a permissionless function, where a user can claim that somebody else wants to auto claim when they do not.
     * @param user The user who wants to autoclaim.
     */
    function makePaidClaimRequest(address user) external payable;

    /**
     * @notice Claim on the behalf of a user who has requests to have their commit automatically claimed by a keeper.
     * @param user The user who requested an autoclaim.
     * @param poolCommitterAddress The PoolCommitter address within which the user's claim will be executed
     */
    function paidClaim(address user, address poolCommitterAddress) external;

    function multiPaidClaimMultiplePoolCommitters(bytes memory args1, bytes memory args2) external;

    /**
     * @notice Call `paidClaim` for multiple users, in a single PoolCommitter.
     * @param args Arguments for the function packed into a bytes array. Generated with L2Encoder.encode
     * -------------------------------------------------------------------------------------------------------------------------
     * |          20 bytes          |          20 bytes         |          20 bytes          |          20 bytes         | ... |
     * |      0th user address      |     1st user address      |      3rd user address      |      4th user address     | ... |
     * -------------------------------------------------------------------------------------------------------------------------
     * @param poolCommitterAddress The PoolCommitter address within which you would like to claim for the respective user
     * @dev poolCommitterAddress should be the PoolCommitter where the all supplied user addresses requested an auto claim
     */
    function multiPaidClaimSinglePoolCommitter(bytes calldata args, address poolCommitterAddress) external;

    /**
     * @notice If a user's claim request never gets executed (due to not high enough of a reward), or they change their minds, enable them to withdraw their request.
     * @param poolCommitter The PoolCommitter for which the user's commit claim is to be withdrawn.
     */
    function withdrawClaimRequest(address poolCommitter) external;

    /**
     * @notice When the user claims themself through poolCommitter, you want the user to be able to withdraw their request through the poolCommitter as msg.sender
     * @param user The user who will have their claim request withdrawn.
     */
    function withdrawUserClaimRequest(address user) external;

    /**
     * @notice Check the validity of a user's claim request for a given pool committer.
     * @return true if the claim request can be executed.
     * @param user The user whose claim request will be checked.
     * @param poolCommitter The pool committer in which to look for a user's claim request.
     */
    function checkUserClaim(address user, address poolCommitter) external view returns (bool);

    /**
     * @return true if the given claim request can be executed.
     * @dev A claim request can be executed only if one exists and is from an update interval that has passed.
     * @param request The ClaimRequest object to be checked.
     * @param currentUpdateIntervalId The current update interval. Used to compare to the update interval of the ClaimRequest.
     */
    function checkClaim(ClaimRequest memory request, uint256 currentUpdateIntervalId) external pure returns (bool);
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The pausable contract
interface IPausable {
    /**
     * @notice Pauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function pause() external;

    /**
     * @notice Unpauses the pool
     * @dev Prevents all state updates until unpaused
     */
    function unpause() external;

    /**
     * @return true if paused
     */
    function paused() external returns (bool);

    event Paused();
    event Unpaused();
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The contract factory for the keeper and pool contracts. Utilizes minimal clones to keep gas costs low
interface IInvariantCheck {
    event InvariantsHold();
    event InvariantsFail(string message);

    /**
     * @notice Checks all invariants, and pauses all contracts if
     *         any invariant does not hold.
     */
    function checkInvariants(address pool) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "abdk-libraries-solidity/ABDKMathQuad.sol";

/// @title Library for various useful (mostly) mathematical functions
library PoolSwapLibrary {
    /// ABDKMathQuad-formatted representation of the number one
    bytes16 public constant ONE = 0x3fff0000000000000000000000000000;

    /// ABDKMathQuad-formatted representation of negative zero
    bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

    /// Maximum number of decimal places supported by this contract
    /// (ABDKMathQuad defines this but it's private)
    uint256 public constant MAX_DECIMALS = 18;

    /// Maximum precision supportable via wad arithmetic (for this contract)
    uint256 public constant WAD_PRECISION = 10**18;

    /// Information required to update a given user's aggregated balance
    struct UpdateData {
        bytes16 longPrice;
        bytes16 shortPrice;
        bytes16 mintingFeeRate;
        uint256 currentUpdateIntervalId;
        uint256 updateIntervalId;
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 longBurnShortMintPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        bytes16 burnFee;
    }

    /// Information about the result of calculating a user's updated aggregate balance
    struct UpdateResult {
        uint256 _newLongTokens; // Quantity of long pool tokens post-application
        uint256 _newShortTokens; // Quantity of short pool tokens post-application
        uint256 _longSettlementFee; // The fee taken from ShortBurnLongMint commits
        uint256 _shortSettlementFee; // The fee taken from ShortBurnLongMint commits
        uint256 _newSettlementTokens; // Quantity of settlement tokens post
    }

    /// Information required to perform a price change (of the underlying asset)
    struct PriceChangeData {
        int256 oldPrice;
        int256 newPrice;
        uint256 longBalance;
        uint256 shortBalance;
        bytes16 leverageAmount;
        bytes16 fee;
    }

    /**
     * @notice Calculates the ratio between two numbers
     * @dev Rounds any overflow towards 0. If either parameter is zero, the ratio is 0
     * @param _numerator The "parts per" side of the equation. If this is zero, the ratio is zero
     * @param _denominator The "per part" side of the equation. If this is zero, the ratio is zero
     * @return the ratio, as an ABDKMathQuad number (IEEE 754 quadruple precision floating point)
     */
    function getRatio(uint256 _numerator, uint256 _denominator) public pure returns (bytes16) {
        // Catch the divide by zero error.
        if (_denominator == 0) {
            return 0;
        }
        return ABDKMathQuad.div(ABDKMathQuad.fromUInt(_numerator), ABDKMathQuad.fromUInt(_denominator));
    }

    /**
     * @notice Multiplies two numbers
     * @param x The number to be multiplied by `y`
     * @param y The number to be multiplied by `x`
     */
    function multiplyBytes(bytes16 x, bytes16 y) external pure returns (bytes16) {
        return ABDKMathQuad.mul(x, y);
    }

    /**
     * @notice Performs a subtraction on two bytes16 numbers
     * @param x The number to be subtracted by `y`
     * @param y The number to subtract from `x`
     */
    function subtractBytes(bytes16 x, bytes16 y) external pure returns (bytes16) {
        return ABDKMathQuad.sub(x, y);
    }

    /**
     * @notice Performs an addition on two bytes16 numbers
     * @param x The number to be added with `y`
     * @param y The number to be added with `x`
     */
    function addBytes(bytes16 x, bytes16 y) external pure returns (bytes16) {
        return ABDKMathQuad.add(x, y);
    }

    /**
     * @notice Gets the short and long balances after the keeper rewards have been paid out
     *         Keeper rewards are paid proportionally to the short and long pool
     * @dev Assumes shortBalance + longBalance >= reward
     * @param reward Amount of keeper reward
     * @param shortBalance Short balance of the pool
     * @param longBalance Long balance of the pool
     * @return shortBalanceAfterFees Short balance of the pool after the keeper reward has been paid
     * @return longBalanceAfterFees Long balance of the pool after the keeper reward has been paid
     */
    function getBalancesAfterFees(
        uint256 reward,
        uint256 shortBalance,
        uint256 longBalance
    ) external pure returns (uint256, uint256) {
        bytes16 ratioShort = getRatio(shortBalance, shortBalance + longBalance);

        uint256 shortFees = convertDecimalToUInt(multiplyDecimalByUInt(ratioShort, reward));

        uint256 shortBalanceAfterFees = shortBalance - shortFees;
        uint256 longBalanceAfterFees = longBalance - (reward - shortFees);

        // Return shortBalance and longBalance after rewards are paid out
        return (shortBalanceAfterFees, longBalanceAfterFees);
    }

    /**
     * @notice Compares two decimal numbers
     * @param x The first number to compare
     * @param y The second number to compare
     * @return -1 if x < y, 0 if x = y, or 1 if x > y
     */
    function compareDecimals(bytes16 x, bytes16 y) public pure returns (int8) {
        return ABDKMathQuad.cmp(x, y);
    }

    /**
     * @notice Converts an integer value to a compatible decimal value
     * @param amount The amount to convert
     * @return The amount as a IEEE754 quadruple precision number
     */
    function convertUIntToDecimal(uint256 amount) external pure returns (bytes16) {
        return ABDKMathQuad.fromUInt(amount);
    }

    /**
     * @notice Converts a raw decimal value to a more readable uint256 value
     * @param ratio The value to convert
     * @return The converted value
     */
    function convertDecimalToUInt(bytes16 ratio) public pure returns (uint256) {
        return ABDKMathQuad.toUInt(ratio);
    }

    /**
     * @notice Multiplies a decimal and an unsigned integer
     * @param a The first term
     * @param b The second term
     * @return The product of a*b as a decimal
     */
    function multiplyDecimalByUInt(bytes16 a, uint256 b) public pure returns (bytes16) {
        return ABDKMathQuad.mul(a, ABDKMathQuad.fromUInt(b));
    }

    /**
     * @notice Divides two unsigned integers
     * @param a The dividend
     * @param b The divisor
     * @return The quotient
     */
    function divUInt(uint256 a, uint256 b) private pure returns (bytes16) {
        return ABDKMathQuad.div(ABDKMathQuad.fromUInt(a), ABDKMathQuad.fromUInt(b));
    }

    /**
     * @notice Divides two integers
     * @param a The dividend
     * @param b The divisor
     * @return The quotient
     */
    function divInt(int256 a, int256 b) public pure returns (bytes16) {
        return ABDKMathQuad.div(ABDKMathQuad.fromInt(a), ABDKMathQuad.fromInt(b));
    }

    /**
     * @notice Multiply an integer by a fraction
     * @notice number * numerator / denominator
     * @param number The number with which the fraction calculated from `numerator` and `denominator` will be multiplied
     * @param numerator The numerator of the fraction being multipled with `number`
     * @param denominator The denominator of the fraction being multipled with `number`
     * @return The result of multiplying number with numerator/denominator, as an integer
     */
    function mulFraction(
        uint256 number,
        uint256 numerator,
        uint256 denominator
    ) public pure returns (uint256) {
        if (denominator == 0) {
            return 0;
        }
        bytes16 multiplyResult = ABDKMathQuad.mul(ABDKMathQuad.fromUInt(number), ABDKMathQuad.fromUInt(numerator));
        bytes16 result = ABDKMathQuad.div(multiplyResult, ABDKMathQuad.fromUInt(denominator));
        return convertDecimalToUInt(result);
    }

    /**
     * @notice Calculates the loss multiplier to apply to the losing pool. Includes the power leverage
     * @param ratio The ratio of new price to old price
     * @param direction The direction of the change. -1 if it's decreased, 0 if it hasn't changed, and 1 if it's increased
     * @param leverage The amount of leverage to apply
     * @return The multiplier
     */
    function getLossMultiplier(
        bytes16 ratio,
        int8 direction,
        bytes16 leverage
    ) public pure returns (bytes16) {
        // If decreased:  2 ^ (leverage * log2[(1 * new/old) + [(0 * 1) / new/old]])
        //              = 2 ^ (leverage * log2[(new/old)])
        // If increased:  2 ^ (leverage * log2[(0 * new/old) + [(1 * 1) / new/old]])
        //              = 2 ^ (leverage * log2([1 / new/old]))
        //              = 2 ^ (leverage * log2([old/new]))
        return
            ABDKMathQuad.pow_2(
                ABDKMathQuad.mul(leverage, ABDKMathQuad.log_2(direction < 0 ? ratio : ABDKMathQuad.div(ONE, ratio)))
            );
    }

    /**
     * @notice Calculates the amount to take from the losing pool
     * @param lossMultiplier The multiplier to use
     * @param balance The balance of the losing pool
     */
    function getLossAmount(bytes16 lossMultiplier, uint256 balance) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.sub(ONE, lossMultiplier), ABDKMathQuad.fromUInt(balance))
            );
    }

    /**
     * @notice Calculates the effect of a price change. This involves calculating how many funds to transfer from the losing pool to the other.
     * @dev This function should be called by the LeveragedPool
     * @dev The value transfer is calculated using a sigmoid function
     * @dev The sigmoid function used is defined as follows:
     *          when newPrice >= oldPrice
     *              losing_pool_multiplier = 2 / (1 + e^(-2 * L * (1 - (newPrice / oldPrice)))) - 1
     *          when newPrice < oldPrice
     *              losing_pool_multiplier = 2 / (1 + e^(-2 * L * (1 - (oldPrice / newPrice)))) - 1
     *          where
     *              e = euler's number
     *              L = leverage
     *              newPrice = the new oracle price
     *              oldPrice = the previous oracle price
     * @param longBalance Settlement token balance on the long side of the pool before the price change
     * @param shortBalance Settlement token balance on the short side of the pool before the price change
     * @param leverageAmount The leverage of the pool
     * @param oldPrice The previous price
     * @param newPrice The new price
     * @param fee The pool's annualised protocol fee
     * @return Resulting long balance
     * @return Resulting short balance
     * @return Resulting fees taken from long balance
     * @return Resulting fees taken from short balance
     */
    function calculateValueTransfer(
        uint256 longBalance,
        uint256 shortBalance,
        bytes16 leverageAmount,
        int256 oldPrice,
        int256 newPrice,
        bytes16 fee
    )
        external
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Copy into a struct (otherwise stack gets too deep)
        PriceChangeData memory priceChangeData = PoolSwapLibrary.PriceChangeData(
            oldPrice,
            newPrice,
            longBalance,
            shortBalance,
            leverageAmount,
            fee
        );
        // Calculate fees from long and short sides
        uint256 longFeeAmount = convertDecimalToUInt(
            multiplyDecimalByUInt(priceChangeData.fee, priceChangeData.longBalance)
        ) / PoolSwapLibrary.WAD_PRECISION;
        uint256 shortFeeAmount = convertDecimalToUInt(
            multiplyDecimalByUInt(priceChangeData.fee, priceChangeData.shortBalance)
        ) / PoolSwapLibrary.WAD_PRECISION;

        priceChangeData.shortBalance -= shortFeeAmount;
        priceChangeData.longBalance -= longFeeAmount;

        uint256 sumBeforePriceChange = priceChangeData.shortBalance + priceChangeData.longBalance;

        if (newPrice >= oldPrice && priceChangeData.shortBalance > 0) {
            // Price increased
            // Using the sigmoid function defined in the function's natspec, move funds from short side to long side
            bytes16 ratio = divInt(priceChangeData.oldPrice, priceChangeData.newPrice);
            bytes16 poolMultiplier = sigmoid(leverageAmount, ratio);

            priceChangeData.longBalance += ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.fromUInt(priceChangeData.shortBalance), poolMultiplier)
            );
            priceChangeData.shortBalance = ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(
                    ABDKMathQuad.fromUInt(priceChangeData.shortBalance),
                    ABDKMathQuad.sub(ONE, poolMultiplier)
                )
            );
        } else if (newPrice < oldPrice && priceChangeData.longBalance > 0) {
            // Price decreased
            // Using the sigmoid function defined in the function's natspec, move funds from long side to short side
            bytes16 ratio = divInt(priceChangeData.newPrice, priceChangeData.oldPrice);
            bytes16 poolMultiplier = sigmoid(leverageAmount, ratio);

            priceChangeData.shortBalance += ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.fromUInt(priceChangeData.longBalance), poolMultiplier)
            );
            priceChangeData.longBalance = ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(
                    ABDKMathQuad.fromUInt(priceChangeData.longBalance),
                    ABDKMathQuad.sub(ONE, poolMultiplier)
                )
            );
        }

        if (sumBeforePriceChange > priceChangeData.longBalance + priceChangeData.shortBalance) {
            // Move dust into winning side
            // This is only ever 1 wei (negligible)
            if (newPrice > oldPrice) {
                priceChangeData.longBalance +=
                    sumBeforePriceChange -
                    (priceChangeData.longBalance + priceChangeData.shortBalance);
            } else {
                priceChangeData.shortBalance +=
                    sumBeforePriceChange -
                    (priceChangeData.longBalance + priceChangeData.shortBalance);
            }
        }

        return (priceChangeData.longBalance, priceChangeData.shortBalance, longFeeAmount, shortFeeAmount);
    }

    /**
     * @notice Use a sigmoid function to determine the losing pool multiplier.
     * @return The losing pool multiplier, represented as an ABDKMathQuad IEEE754 quadruple-precision binary floating-point numbers
     * @dev The returned value is used in `calculateValueTransfer` as the portion to move from the losing side into the winning side
     */
    function sigmoid(bytes16 leverage, bytes16 ratio) private pure returns (bytes16) {
        /**
         * denominator = 1 + e ^ (-2 * leverage * (1 - ratio))
         */
        bytes16 denominator = ABDKMathQuad.mul(ABDKMathQuad.fromInt(-2), leverage);
        denominator = ABDKMathQuad.mul(denominator, ABDKMathQuad.sub(ONE, ratio));
        denominator = ABDKMathQuad.add(ONE, ABDKMathQuad.exp(denominator));
        bytes16 numerator = ABDKMathQuad.add(ONE, ONE); // 2
        return ABDKMathQuad.sub((ABDKMathQuad.div(numerator, denominator)), ONE);
    }

    /**
     * @notice Returns true if the given timestamp is BEFORE the frontRunningInterval starts
     * @param subjectTime The timestamp for which you want to calculate if it was beforeFrontRunningInterval
     * @param lastPriceTimestamp The timestamp of the last price update
     * @param updateInterval The interval between price updates
     * @param frontRunningInterval The window of time before a price update in which users can have their commit executed from
     */
    function isBeforeFrontRunningInterval(
        uint256 subjectTime,
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 frontRunningInterval
    ) public pure returns (bool) {
        return lastPriceTimestamp + updateInterval - frontRunningInterval > subjectTime;
    }

    /**
     * @notice Calculates the update interval ID that a commitment should be placed in.
     * @param timestamp Current block.timestamp
     * @param lastPriceTimestamp The timestamp of the last price update
     * @param frontRunningInterval The frontrunning interval of a pool - The amount of time before an update interval that you must commit to get included in that update
     * @param updateInterval The frequency of a pool's updates
     * @param currentUpdateIntervalId The current update interval's ID
     * @dev Note that the timestamp parameter is required to be >= lastPriceTimestamp
     * @return The update interval ID in which a commit being made at time timestamp should be included
     */
    function appropriateUpdateIntervalId(
        uint256 timestamp,
        uint256 lastPriceTimestamp,
        uint256 frontRunningInterval,
        uint256 updateInterval,
        uint256 currentUpdateIntervalId
    ) external pure returns (uint256) {
        require(lastPriceTimestamp <= timestamp, "timestamp in the past");
        if (frontRunningInterval <= updateInterval) {
            // This is the "simple" case where we either want the current update interval or the next one
            if (isBeforeFrontRunningInterval(timestamp, lastPriceTimestamp, updateInterval, frontRunningInterval)) {
                // We are before the frontRunning interval
                return currentUpdateIntervalId;
            } else {
                // Floor of `timePassed / updateInterval` to get the number of intervals passed
                uint256 updateIntervalsPassed = (timestamp - lastPriceTimestamp) / updateInterval;
                // If 1 update interval has passed, we want to check if we are within the frontrunning interval of currentUpdateIntervalId + 1
                uint256 frontRunningIntervalStart = lastPriceTimestamp +
                    ((updateIntervalsPassed + 1) * updateInterval) -
                    frontRunningInterval;
                if (timestamp >= frontRunningIntervalStart) {
                    // add an extra update interval because the frontrunning interval has passed
                    return currentUpdateIntervalId + updateIntervalsPassed + 1;
                } else {
                    return currentUpdateIntervalId + updateIntervalsPassed;
                }
            }
        } else {
            // frontRunningInterval > updateInterval
            // This is the generalised case, where it could be any number of update intervals in the future
            // Minimum time is the earliest we could possible execute this commitment (i.e. the current time plus frontrunning interval)
            uint256 minimumTime = timestamp + frontRunningInterval;
            // Number of update intervals that would have had to have passed.
            uint256 updateIntervals = (minimumTime - lastPriceTimestamp) / updateInterval;

            return currentUpdateIntervalId + updateIntervals;
        }
    }

    /**
     * @notice Gets the number of settlement tokens to be withdrawn based on a pool token burn amount
     * @dev Calculates as `balance * amountIn / (tokenSupply + shadowBalance)
     * @param tokenSupply Total supply of pool tokens
     * @param amountIn Commitment amount of pool tokens going into the pool
     * @param balance Balance of the pool (no. of underlying settlement tokens in pool)
     * @param pendingBurnPoolTokens Amount of pool tokens being burnt during this update interval
     * @return Number of settlement tokens to be withdrawn on a burn
     */
    function getWithdrawAmountOnBurn(
        uint256 tokenSupply,
        uint256 amountIn,
        uint256 balance,
        uint256 pendingBurnPoolTokens
    ) external pure returns (uint256) {
        // Catch the divide by zero error, or return 0 if amountIn is 0
        if ((balance == 0) || (tokenSupply + pendingBurnPoolTokens == 0) || (amountIn == 0)) {
            return amountIn;
        }
        return (balance * amountIn) / (tokenSupply + pendingBurnPoolTokens);
    }

    /**
     * @notice Gets the number of pool tokens to be minted based on existing tokens
     * @dev Calculated as (tokenSupply + shadowBalance) * amountIn / balance
     * @param tokenSupply Total supply of pool tokens
     * @param amountIn Commitment amount of settlement tokens going into the pool
     * @param balance Balance of the pool (no. of underlying settlement tokens in pool)
     * @param pendingBurnPoolTokens Amount of pool tokens being burnt during this update interval
     * @return Number of pool tokens to be minted
     */
    function getMintAmount(
        uint256 tokenSupply,
        uint256 amountIn,
        uint256 balance,
        uint256 pendingBurnPoolTokens
    ) external pure returns (uint256) {
        // Catch the divide by zero error, or return 0 if amountIn is 0
        if (balance == 0 || tokenSupply + pendingBurnPoolTokens == 0 || amountIn == 0) {
            return amountIn;
        }

        return ((tokenSupply + pendingBurnPoolTokens) * amountIn) / balance;
    }

    /**
     * @notice Get the Settlement/PoolToken price, in ABDK IEE754 precision
     * @dev Divide the side balance by the pool token's total supply
     * @param sideBalance no. of underlying settlement tokens on that side of the pool
     * @param tokenSupply Total supply of pool tokens
     */
    function getPrice(uint256 sideBalance, uint256 tokenSupply) external pure returns (bytes16) {
        if (tokenSupply == 0) {
            return ONE;
        }
        return ABDKMathQuad.div(ABDKMathQuad.fromUInt(sideBalance), ABDKMathQuad.fromUInt(tokenSupply));
    }

    /**
     * @notice Calculates the number of pool tokens to mint, given some settlement token amount and a price
     * @param price Price of a pool token
     * @param amount Amount of settlement tokens being used to mint
     * @return Quantity of pool tokens to mint
     * @dev Throws if price is zero, or IEEE754 negative zero
     * @dev `getMint()`
     */
    function getMint(bytes16 price, uint256 amount) public pure returns (uint256) {
        require(price != 0, "price == 0");
        require(price != NEGATIVE_ZERO, "price == negative zero");
        return ABDKMathQuad.toUInt(ABDKMathQuad.div(ABDKMathQuad.fromUInt(amount), price));
    }

    /**
     * @notice Calculate the number of settlement tokens to return, based on a price and an amount of pool tokens being burnt
     * @param price Price of a pool token
     * @param amount Amount of pool tokens being used to burn
     * @return Quantity of settlement tokens to return to the user after `amount` pool tokens are burnt.
     * @dev amount * price, where amount is in PoolToken and price is in USD/PoolToken
     * @dev Throws if price is zero, or IEEE754 negative zero
     * @dev `getBurn()`
     */
    function getBurn(bytes16 price, uint256 amount) public pure returns (uint256) {
        require(price != 0, "price == 0");
        require(price != NEGATIVE_ZERO, "price == negative zero");
        return ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(amount), price));
    }

    /**
     * @notice Calculate the amount of settlement tokens to take as the minting fee
     * @param feeRate PoolCommitter's mintingFee or burningFee - The amount that is extracted from each mint or burn. Given as the decimal * 10 ^ 18. For example, 60% fee is 0.6 * 10 ^ 18 Fees can be 0.
     * @param amount The amount of settlement tokens being committed to mint
     */
    function mintingOrBurningFee(bytes16 feeRate, uint256 amount) public pure returns (uint256) {
        return ABDKMathQuad.toUInt(multiplyDecimalByUInt(feeRate, amount)) / WAD_PRECISION;
    }

    /**
     * @notice Converts from a WAD to normal value
     * @param _wadValue wad number
     * @param _decimals Quantity of decimal places to support
     * @return Converted (non-WAD) value
     */
    function fromWad(uint256 _wadValue, uint256 _decimals) external pure returns (uint256) {
        uint256 scaler = 10**(MAX_DECIMALS - _decimals);
        return _wadValue / scaler;
    }

    /**
     * @notice Given an amount of pool tokens to flip to the other side of the pool, calculate the amount of settlement tokens generated from the burn, burn fee, and subsequent minting fee
     * @dev Takes out the burn fee before taking out the mint fee.
     * @param amount The amount of pool tokens being flipped
     * @param burnPrice The price of the pool token being burnt
     * @param burningFee Fee rate for pool token burns
     * @param mintingFee Fee rate for mints
     * @return Amount of settlement tokens used to mint.
     * @return The burn fee. This should be given to the side of the pool of the burnt tokens.
     * @return The mint fee. This should be given to the side of the pool that is being minted into.
     */
    function processBurnInstantMintCommit(
        uint256 amount,
        bytes16 burnPrice,
        bytes16 burningFee,
        bytes16 mintingFee
    )
        public
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Settlement tokens earned from burning pool tokens (for instant mint)
        uint256 mintSettlement = getBurn(burnPrice, amount);
        // The burn fee. This should be given to the side of the pool of the burnt tokens.
        uint256 burnFee = mintingOrBurningFee(burningFee, mintSettlement);
        mintSettlement -= burnFee;

        // The mint fee. This should be given to the side of the pool that is being minted into.
        uint256 mintFee = mintingOrBurningFee(mintingFee, mintSettlement);
        mintSettlement -= mintFee;
        return (mintSettlement, burnFee, mintFee);
    }

    /**
     * @notice Calculate the change in a user's balance based on recent commit(s)
     * @param data Information needed for updating the balance including prices and recent commit amounts
     * @return The UpdateResult struct with the data pertaining to the update of user's aggregate balance
     */
    function getUpdatedAggregateBalance(UpdateData calldata data) external pure returns (UpdateResult memory) {
        UpdateResult memory result = UpdateResult(0, 0, 0, 0, 0);
        if (data.updateIntervalId >= data.currentUpdateIntervalId) {
            // Update interval has not passed: No change
            return result;
        }

        /**
         * Start by looking at the "flip" commitments (either LongBurnShortMint, or ShortBurnLongMint), and determine the amount of settlement tokens were generated from them.
         * Then, take the burning fee off them and add that to the relevant side's fee amount. e.g. a ShortBurnLongMint will generate burn fees for the short side.
         * Now, we can calculate how much minting fee should be paid by the user. This should then be added to the side which they are minting on.
         */
        uint256 shortBurnLongMintResult; // Settlement to be included in the long mint
        uint256 longBurnShortMintResult; // Settlement to be included in the short mint
        if (data.shortBurnLongMintPoolTokens > 0) {
            uint256 burnFeeSettlement;
            uint256 mintFeeSettlement;
            (shortBurnLongMintResult, burnFeeSettlement, mintFeeSettlement) = processBurnInstantMintCommit(
                data.shortBurnLongMintPoolTokens,
                data.shortPrice,
                data.burnFee,
                data.mintingFeeRate
            );
            result._shortSettlementFee += burnFeeSettlement;
            result._longSettlementFee += mintFeeSettlement;
        }
        if (data.longBurnShortMintPoolTokens > 0) {
            // Settlement tokens earned from burning long tokens (for instant mint)
            longBurnShortMintResult = getBurn(data.longPrice, data.longBurnShortMintPoolTokens);
            // The burn fee taken from this burn. This should be given to the long side.
            uint256 burnFeeSettlement = mintingOrBurningFee(data.burnFee, longBurnShortMintResult);
            longBurnShortMintResult -= burnFeeSettlement;

            // The mint fee taken from the subsequent mint
            uint256 mintFeeSettlement = mintingOrBurningFee(data.mintingFeeRate, longBurnShortMintResult);
            longBurnShortMintResult -= mintFeeSettlement;

            result._longSettlementFee += burnFeeSettlement;
            result._shortSettlementFee += mintFeeSettlement;
        }

        /**
         * Calculate the new long tokens minted.
         * Use amount committed LongMint/ShortMint, as well as settlement tokens generated from ShortBurnLongMint/LongBurnShortMint commits.
         */
        if (data.longMintSettlement > 0 || shortBurnLongMintResult > 0) {
            result._newLongTokens += getMint(data.longPrice, data.longMintSettlement + shortBurnLongMintResult);
        }
        if (data.shortMintSettlement > 0 || longBurnShortMintResult > 0) {
            result._newShortTokens += getMint(data.shortPrice, data.shortMintSettlement + longBurnShortMintResult);
        }

        /**
         * Calculate the settlement tokens earned through LongBurn/ShortBurn commits.
         * Once this is calculated, take off the burn fee, and add to the respective side's fee amount.
         */
        if (data.longBurnPoolTokens > 0) {
            // Calculate the amount of settlement tokens earned from burning long tokens
            uint256 longBurnResult = getBurn(data.longPrice, data.longBurnPoolTokens);
            // Calculate the fee
            uint256 longBurnFee = mintingOrBurningFee(data.burnFee, longBurnResult);
            result._longSettlementFee += longBurnFee;
            // Subtract the fee from settlement token amount
            longBurnResult -= longBurnFee;
            result._newSettlementTokens += longBurnResult;
        }
        if (data.shortBurnPoolTokens > 0) {
            // Calculate the amount of settlement tokens earned from burning short tokens
            uint256 shortBurnResult = getBurn(data.shortPrice, data.shortBurnPoolTokens);
            // Calculate the fee
            uint256 shortBurnFee = mintingOrBurningFee(data.burnFee, shortBurnResult);
            result._shortSettlementFee += shortBurnFee;
            // Subtract the fee from settlement token amount
            shortBurnResult -= shortBurnFee;
            result._newSettlementTokens += shortBurnResult;
        }

        return result;
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "../interfaces/IPoolCommitter.sol";

/// @title CalldataLogic library
/// @notice Library to decode calldata, used to optimize calldata size in PerpetualPools for L2 transaction cost reduction
library CalldataLogic {
    /*
     * Calldata when parameter is a tightly packed byte array looks like this:
     * -----------------------------------------------------------------------------------------------------
     * | function signature | offset of byte array | length of byte array |           bytes array           |
     * |      4 bytes       |       32 bytes       |       32 bytes       |  20 * number_of_addresses bytes |
     * -----------------------------------------------------------------------------------------------------
     *
     * If there are two bytes arrays, then it looks like
     * ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     * | function signature | offset of 1st byte array | offset of 2nd byte array | length of 1st byte array |        1st bytes array          | length of 2nd byte array |        2nd bytes array          |
     * |      4 bytes       |        32 bytes          |        32 bytes          |         32 bytes         |  20 * number_of_addresses bytes |         32 bytes         |  20 * number_of_addresses bytes |
     * ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     * and so on...
     * Note that the offset indicates where the length is indicated, and the actual array itself starts 32 bytes after that
     */
    // Length of address = 20
    uint16 internal constant ADDRESS_LENGTH = 20;

    function getAddressAtOffset(uint256 offset) internal pure returns (address) {
        bytes20 addressAtOffset;
        assembly {
            addressAtOffset := calldataload(offset)
        }
        return (address(addressAtOffset));
    }

    /**
     * @notice decodes compressed commit params to standard params
     * @param args The packed commit args
     * @return The amount of settlement or pool tokens to commit
     * @return The CommitType
     * @return Whether to make the commitment from user's aggregate balance
     * @return Whether to pay for an autoclaim or not
     */
    function decodeCommitParams(bytes32 args)
        internal
        pure
        returns (
            uint256,
            IPoolCommitter.CommitType,
            bool,
            bool
        )
    {
        uint256 amount;
        IPoolCommitter.CommitType commitType;
        bool fromAggregateBalance;
        bool payForClaim;

        // `amount` is implicitly capped at 128 bits.
        assembly {
            amount := and(args, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            commitType := and(shr(128, args), 0xFF)
            fromAggregateBalance := and(shr(136, args), 0xFF)
            payForClaim := and(shr(144, args), 0xFF)
        }
        return (amount, commitType, fromAggregateBalance, payForClaim);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16510); // Overflow
      if (exponent < 16255) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16367) result >>= 16367 - exponent;
      else if (exponent > 16367) result <<= exponent - 16367;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint128 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16446); // Overflow
      if (exponent < 16319) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16431) result >>= 16431 - exponent;
      else if (exponent > 16431) result <<= exponent - 16431;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x80000000000000000000000000000000);
        return -int128 (int256 (result)); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
      }
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    unchecked {
      bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

      uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
      uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFFF) {
        if (significand > 0) return NaN;
        else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      }

      if (exponent > 278526)
        return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      else if (exponent < 245649)
        return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
      else if (exponent < 245761) {
        significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
        exponent = 0;
      } else {
        significand >>= 124;
        exponent -= 245760;
      }

      uint128 result = uint128 (significand | exponent << 112);
      if (negative) result |= 0x80000000000000000000000000000000;

      return bytes16 (result);
    }
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 245649 + msb;
        }
      } else {
        result <<= 124;
        exponent += 245760;
      }

      result |= exponent << 236;
      if (uint128 (x) >= 0x80000000000000000000000000000000)
        result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

      return bytes32 (result);
    }
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    unchecked {
      uint256 exponent = uint64 (x) >> 52 & 0x7FF;

      uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

      if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 15309 + msb;
        }
      } else {
        result <<= 60;
        exponent += 15360;
      }

      result |= exponent << 112;
      if (x & 0x8000000000000000 > 0)
        result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    unchecked {
      bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) {
        if (significand > 0) return 0x7FF8000000000000; // NaN
        else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      }

      if (exponent > 17406)
        return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      else if (exponent < 15309)
        return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
      else if (exponent < 15361) {
        significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
        exponent = 0;
      } else {
        significand >>= 60;
        exponent -= 15360;
      }

      uint64 result = uint64 (significand | exponent << 52);
      if (negative) result |= 0x8000000000000000;

      return bytes8 (result);
    }
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      if (absoluteX == 0) return 0;
      else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
      else return 1;
    }
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

      // Not infinities of the same sign
      require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

      if (x == y) return 0;
      else {
        bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
        bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

        if (negativeX) {
          if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
          else return -1; 
        } else {
          if (negativeY) return 1;
          else return absoluteX > absoluteY ? int8 (1) : -1;
        }
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    unchecked {
      if (x == y) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
          0x7FFF0000000000000000000000000000;
      } else return false;
    }
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) { 
          if (x == y) return x;
          else return NaN;
        } else return x; 
      } else if (yExponent == 0x7FFF) return y;
      else {
        bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
        else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
        else {
          int256 delta = int256 (xExponent) - int256 (yExponent);
  
          if (xSign == ySign) {
            if (delta > 112) return x;
            else if (delta > 0) ySignifier >>= uint256 (delta);
            else if (delta < -112) return y;
            else if (delta < 0) {
              xSignifier >>= uint256 (-delta);
              xExponent = yExponent;
            }
  
            xSignifier += ySignifier;
  
            if (xSignifier >= 0x20000000000000000000000000000) {
              xSignifier >>= 1;
              xExponent += 1;
            }
  
            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else {
              if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
              else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
              return bytes16 (uint128 (
                  (xSign ? 0x80000000000000000000000000000000 : 0) |
                  (xExponent << 112) |
                  xSignifier)); 
            }
          } else {
            if (delta > 0) {
              xSignifier <<= 1;
              xExponent -= 1;
            } else if (delta < 0) {
              ySignifier <<= 1;
              xExponent = yExponent - 1;
            }

            if (delta > 112) ySignifier = 1;
            else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
            else if (delta < -112) xSignifier = 1;
            else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

            if (xSignifier >= ySignifier) xSignifier -= ySignifier;
            else {
              xSignifier = ySignifier - xSignifier;
              xSign = ySign;
            }

            if (xSignifier == 0)
              return POSITIVE_ZERO;

            uint256 msb = mostSignificantBit (xSignifier);

            if (msb == 113) {
              xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent += 1;
            } else if (msb < 112) {
              uint256 shift = 112 - msb;
              if (xExponent > shift) {
                xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                xExponent -= shift;
              } else {
                xSignifier <<= xExponent - 1;
                xExponent = 0;
              }
            } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier));
          }
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      return add (x, y ^ 0x80000000000000000000000000000000);
    }
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) {
          if (x == y) return x ^ y & 0x80000000000000000000000000000000;
          else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
          else return NaN;
        } else {
          if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return x ^ y & 0x80000000000000000000000000000000;
        }
      } else if (yExponent == 0x7FFF) {
          if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return y ^ x & 0x80000000000000000000000000000000;
      } else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        xSignifier *= ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        xExponent += yExponent;

        uint256 msb =
          xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
          xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
          mostSignificantBit (xSignifier);

        if (xExponent + msb < 16496) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb < 16608) { // Subnormal
          if (xExponent < 16496)
            xSignifier >>= 16496 - xExponent;
          else if (xExponent > 16496)
            xSignifier <<= xExponent - 16496;
          xExponent = 0;
        } else if (xExponent + msb > 49373) {
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else {
          if (msb > 112)
            xSignifier >>= msb - 112;
          else if (msb < 112)
            xSignifier <<= 112 - msb;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb - 16607;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x ^ 0x80000000000000000000000000000000;
    }
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return POSITIVE_ZERO;

          bool oddExponent = xExponent & 0x1 == 0;
          xExponent = xExponent + 16383 >> 1;

          if (oddExponent) {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 113;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (226 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          } else {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 112;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (225 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          }

          uint256 r = 0x10000000000000000000000000000;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
          uint256 r1 = xSignifier / r;
          if (r1 < r) r = r1;

          return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
      else if (xExponent > 16397)
        return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
      else if (xExponent < 16255)
        return 0x3FFF0000000000000000000000000000;
      else {
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xExponent > 16367)
          xSignifier <<= xExponent - 16367;
        else if (xExponent < 16367)
          xSignifier >>= 16367 - xExponent;

        if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
          return POSITIVE_ZERO;

        if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
          return POSITIVE_INFINITY;

        uint256 resultExponent = xSignifier >> 128;
        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xNegative && xSignifier != 0) {
          xSignifier = ~xSignifier;
          resultExponent += 1;
        }

        uint256 resultSignifier = 0x80000000000000000000000000000000;
        if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
        if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
        if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
        if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
        if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
        if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
        if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
        if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
        if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
        if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
        if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
        if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
        if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
        if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
        if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
        if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
        if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
        if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
        if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
        if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
        if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
        if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
        if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
        if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
        if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
        if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
        if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
        if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
        if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
        if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
        if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
        if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
        if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
        if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
        if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
        if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
        if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
        if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
        if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
        if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
        if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
        if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
        if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
        if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
        if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
        if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
        if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
        if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
        if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
        if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
        if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
        if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
        if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
        if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
        if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
        if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
        if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
        if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
        if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
        if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
        if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
        if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
        if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
        if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

        if (!xNegative) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent += 0x3FFF;
        } else if (resultExponent <= 0x3FFE) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent = 0x3FFF - resultExponent;
        } else {
          resultSignifier = resultSignifier >> resultExponent - 16367;
          resultExponent = 0;
        }

        return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
      }
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}