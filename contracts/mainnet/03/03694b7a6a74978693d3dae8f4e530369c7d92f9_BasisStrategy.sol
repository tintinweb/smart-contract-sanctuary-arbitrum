// SPDX-License-Identifier: AGPL V3.0
pragma solidity 0.8.4;

import "OwnableUpgradeable.sol";
import "IERC20.sol";
import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "SafeERC20.sol";

import "IUniswapV3Pool.sol";
import "ISwapRouter.sol";

import "IMCLP.sol";
import "IOracle.sol";
import "IBasisVault.sol";
import "ILmClaimer.sol";

import "IRouterV2.sol";

/**
 * @title  BasisStrategy
 * @author akropolis.io
 * @notice A strategy used to perform basis trading using funds from a BasisVault
 */
contract BasisStrategy is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    // struct to store the position state of the strategy
    struct Positions {
        int256 perpContracts;
        int256 margin;
        int256 unitAccumulativeFunding;
    }

    // MCDEX Liquidity and Perpetual Pool interface address
    IMCLP public mcLiquidityPool;
    // Uniswap v3 pair pool interface address
    address public pool;
    // Uniswap v3 router interface address
    address public router;
    // Basis Vault interface address
    IBasisVault public vault;
    // MCDEX trade reward claimer
    ILmClaimer public lmClaimer;

    // address of the want (short collateral) of the strategy
    address public want;
    // address of the long asset of the strategy
    address public long;
    // address of the mcb token
    address public mcb;
    // address of the referrer for MCDEX
    address public referrer;
    // address of governance
    address public governance;
    // address of keeper
    address public keeper;
    // address weth
    address public weth;
    // Positions of the strategy
    Positions public positions;
    // perpetual index in MCDEX
    uint256 public perpetualIndex;
    // margin buffer of the strategy, between 0 and 10_000
    uint256 public buffer;
    // max bips
    uint256 public constant MAX_BPS = 1_000_000;
    // decimal shift for USDC
    int256 public DECIMAL_SHIFT;
    // dust for margin positions
    int256 public dust = 1000;
    // slippage Tolerance for the perpetual trade
    int256 public slippageTolerance;
    // unwind state tracker
    bool public isUnwind;
    // trade mode of the perp
    uint32 public tradeMode = 0x40000000;
    // bool determine layer version
    bool isV2;
    // bool for whether to turn on slippage control
    bool isSlippageControl;
    // modifier to check that the caller is governance
    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    // romove or rename
    // modifier to check that the caller is governance or owner
    modifier onlyAuthorised() {
        require(
            msg.sender == governance || msg.sender == owner(),
            "!authorised"
        );
        _;
    }

    // modifier to check that the caller is governance or owner or keeper
    modifier onlyKeeper() {
        require(
            msg.sender == governance ||
                msg.sender == owner() ||
                msg.sender == keeper,
            "!authorised"
        );
        _;
    }

    // modifier to check that the caller is the vault
    modifier onlyVault() {
        require(msg.sender == address(vault), "!vault");
        _;
    }

    /**
     * @param _long            address of the long asset of the strategy
     * @param _pool            Uniswap v3 pair pool address
     * @param _vault           Basis Vault address
     * @param _router          Uniswap v3 router address
     * @param _governance      Governance address
     * @param _mcLiquidityPool MCDEX Liquidity and Perpetual Pool address
     * @param _perpetualIndex  index of the perpetual market
     */
    function initialize(
        address _long,
        address _pool,
        address _vault,
        address _router,
        address _weth,
        address _governance,
        address _mcLiquidityPool,
        uint256 _perpetualIndex,
        uint256 _buffer,
        bool _isV2
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        require(_long != address(0), "!_long");
        require(_pool != address(0), "!_pool");
        require(_vault != address(0), "!_vault");
        require(_router != address(0), "!_router");
        require(_governance != address(0), "!_governance");
        require(_mcLiquidityPool != address(0), "!_mcLiquidityPool");
        require(_weth != address(0), "!_weth");
        require(_buffer < MAX_BPS, "!_buffer");
        long = _long;
        pool = _pool;
        vault = IBasisVault(_vault);
        router = _router;
        weth = _weth;
        governance = _governance;
        mcLiquidityPool = IMCLP(_mcLiquidityPool);
        perpetualIndex = _perpetualIndex;
        isV2 = _isV2;
        want = address(vault.want());
        buffer = _buffer;
        mcLiquidityPool.setTargetLeverage(perpetualIndex, address(this), 1e18);
        (, , , , uint256[6] memory stores) = mcLiquidityPool
            .getLiquidityPoolInfo();
        DECIMAL_SHIFT = int256(1e18 / 10**(stores[0]));
        isSlippageControl = true;
    }

    /**********
     * EVENTS *
     **********/

    event DepositToMarginAccount(uint256 amount, uint256 perpetualIndex);
    event WithdrawStrategy(uint256 amountWithdrawn, uint256 loss);
    event Harvest(int256 perpContracts, uint256 longPosition, int256 margin);
    event StrategyUnwind(uint256 positionSize);
    event EmergencyExit(address indexed recipient, uint256 positionSize);
    event Migrated(address indexed strategy, uint256 positionSize);
    event PerpPositionOpened(
        int256 perpPositions,
        uint256 perpetualIndex,
        uint256 collateral
    );
    event PerpPositionClosed(
        int256 perpPositions,
        uint256 perpetualIndex,
        uint256 collateral
    );
    event AllPerpPositionsClosed(int256 perpPositions, uint256 perpetualIndex);
    event Snapshot(
        int256 cash,
        int256 position,
        int256 availableMargin,
        int256 margin,
        int256 settleableMargin,
        bool isInitialMarginSafe,
        bool isMaintenanceMarginSafe,
        bool isMarginSafe // bankrupt
    );
    event BufferAdjusted(
        int256 oldMargin,
        int256 newMargin,
        int256 oldPerpContracts,
        int256 newPerpContracts,
        uint256 oldLong,
        uint256 newLong
    );
    event Remargined(int256 unwindAmount);
    event LiquidityPoolSet(address indexed oldAddress, address newAddress);
    event UniswapPoolSet(address indexed oldAddress, address newAddress);
    event VaultSet(address indexed oldAddress, address newAddress);
    event BufferSet(uint256 oldAmount, uint256 newAmount);
    event PerpIndexSet(uint256 oldAmount, uint256 newAmount);
    event ReferrerSet(address indexed oldAddress, address newAddress);
    event SlippageToleranceSet(int256 oldAmount, int256 newAmount);
    event DustSet(int256 oldAmount, int256 newAmount);
    event TradeModeSet(uint32 oldAmount, uint32 newAmount);
    event GovernanceSet(address indexed oldAddress, address newAddress);
    event KeeperSet(address indexed oldAddress, address newAddress);
    event VersionSet(bool oldState, bool newState);
    event LmClaimerSet(address indexed oldAddress, address newAddress);
    event McbSet(address indexed oldAddress, address newAddress);
    event SlippageControlSet(bool oldState, bool newState);

    /***********
     * SETTERS *
     ***********/

    /**
     * @notice  setter for the mcdex liquidity pool
     * @param   _mcLiquidityPool MCDEX Liquidity and Perpetual Pool address
     * @dev     only callable by owner
     */
    function setLiquidityPool(address _mcLiquidityPool) external onlyOwner {
        emit LiquidityPoolSet(address(mcLiquidityPool), _mcLiquidityPool);
        mcLiquidityPool = IMCLP(_mcLiquidityPool);
    }

    /**
     * @notice  setter for slippage control
     * @param   _isSlippageControl turns on slippage control for uniswap swaps
     * @dev     only callable by owner
     */
    function setSlippageControl(bool _isSlippageControl) external onlyOwner {
        emit SlippageControlSet(isSlippageControl, _isSlippageControl);
        isSlippageControl = _isSlippageControl;
    }

    /**
     * @notice  setter for the uniswap pair pool
     * @param   _pool Uniswap v3 pair pool address
     * @dev     only callable by owner
     */
    function setUniswapPool(address _pool) external onlyOwner {
        emit UniswapPoolSet(pool, _pool);
        pool = _pool;
    }

    /**
     * @notice  setter for the basis vault
     * @param   _vault Basis Vault address
     * @dev     only callable by owner
     */
    function setBasisVault(address _vault) external onlyOwner {
        emit VaultSet(address(vault), _vault);
        vault = IBasisVault(_vault);
    }

    /**
     * @notice  setter for buffer, does not remargin immediately
     * @param   _buffer Basis strategy margin buffer
     * @dev     only callable by owner
     */
    function setBuffer(uint256 _buffer) public onlyOwner {
        require(_buffer < 1_000_000, "!_buffer");
        emit BufferSet(buffer, _buffer);
        buffer = _buffer;
    }

    /**
     * @notice  setter for buffer including a remargin for remargin timing safety
     * @param   _buffer Basis strategy margin buffer
     * @dev     only callable by owner, this is the safer way to set a buffer
     */
    function setBufferAndRemargin(uint256 _buffer) public onlyOwner {
        require(_buffer < 1_000_000, "!_buffer");
        emit BufferSet(buffer, _buffer);
        buffer = _buffer;
        remargin();
    }

    /**
     * @notice  setter for perpetualIndex value
     * @param   _perpetualIndex MCDEX perpetual index
     * @dev     only callable by owner
     */
    function setPerpetualIndex(uint256 _perpetualIndex) external onlyOwner {
        emit PerpIndexSet(perpetualIndex, _perpetualIndex);
        perpetualIndex = _perpetualIndex;
    }

    /**
     * @notice  setter for referrer for MCDEX rebates
     * @param   _referrer address of the MCDEX referral recipient
     * @dev     only callable by owner
     */
    function setReferrer(address _referrer) external onlyOwner {
        emit ReferrerSet(referrer, _referrer);
        referrer = _referrer;
    }

    /**
     * @notice  setter for perpetual trade slippage tolerance
     * @param   _slippageTolerance amount of slippage tolerance to accept on perp trade
     * @dev     only callable by owner
     */
    function setSlippageTolerance(int256 _slippageTolerance)
        external
        onlyOwner
    {
        emit SlippageToleranceSet(slippageTolerance, _slippageTolerance);
        slippageTolerance = _slippageTolerance;
    }

    /**
     * @notice  setter for dust for closing margin positions
     * @param   _dust amount of dust in wei that is acceptable
     * @dev     only callable by owner
     */
    function setDust(int256 _dust) external onlyOwner {
        emit DustSet(dust, _dust);
        dust = _dust;
    }

    /**
     * @notice  setter for the tradeMode of the perp
     * @param   _tradeMode uint32 for the perp trade mode
     * @dev     only callable by owner
     */
    function setTradeMode(uint32 _tradeMode) external onlyOwner {
        emit TradeModeSet(tradeMode, _tradeMode);
        tradeMode = _tradeMode;
    }

    /**
     * @notice  setter for the governance address
     * @param   _governance address of governance
     * @dev     only callable by governance
     */
    function setGovernance(address _governance) external onlyGovernance {
        emit GovernanceSet(governance, _governance);
        governance = _governance;
    }

    /**
     * @notice  setter for the keeper address
     * @param   _keeper address of keeper
     * @dev     only callable by authorised
     */
    function setKeeper(address _keeper) external onlyAuthorised {
        emit KeeperSet(keeper, _keeper);
        keeper = _keeper;
    }

    /**
     * @notice set router version for network
     * @param _isV2 bool to set the version of rooter
     * @dev only callable by owner
     */
    function setVersion(bool _isV2) external onlyOwner {
        emit VersionSet(isV2, _isV2);
        isV2 = _isV2;
    }

    /**
     * @notice  setter for liquidity mining claim contract
     * @param   _lmClaimer the claim contract
     * @param   _mcb the mcb token address
     * @dev     only callable by owner
     */
    function setLmClaimerAndMcb(address _lmClaimer, address _mcb)
        external
        onlyOwner
    {
        emit LmClaimerSet(address(lmClaimer), _lmClaimer);
        emit McbSet(mcb, _mcb);
        lmClaimer = ILmClaimer(_lmClaimer);
        mcb = _mcb;
    }

    /**********************
     * EXTERNAL FUNCTIONS *
     **********************/

    /**
     * @notice  harvest the strategy. This involves accruing profits from the strategy and depositing
     *          user funds to the strategy. The funds are split into their constituents and then distributed
     *          to their appropriate location.
     *          For the shortPosition a perpetual position is opened, for the long position funds are swapped
     *          to the long asset. For the buffer position the funds are deposited to the margin account idle.
     * @dev     only callable by the owner, governance or keeper
     */
    function harvest() public onlyKeeper {
        uint256 shortPosition;
        uint256 longPosition;
        uint256 bufferPosition;
        isUnwind = false;

        mcLiquidityPool.forceToSyncState();
        // determine the profit since the last harvest and remove profits from the margin
        // account to be redistributed
        uint256 amount;
        bool loss;
        if (positions.unitAccumulativeFunding != 0) {
            (amount, loss) = _determineFee();
        }
        // update the vault with profits/losses accrued and receive deposits
        // vault.update(amount, loss) returns the total fund that will be deposit
        // strategy use the funds inside the vault, if loss no fees are taken
        vault.update(amount, loss);
        // combine the funds and check that they are larger than 0
        uint256 toActivate = IERC20(want).balanceOf(address(this));

        if (toActivate > 0) {
            // determine the split of the funds and trade for the spot position of long
            (shortPosition, longPosition, bufferPosition) = _calculateSplit(
                toActivate
            );
            // deposit the bufferPosition to the margin account
            _depositToMarginAccount(bufferPosition);
            // open a short perpetual position and store the number of perp contracts
            positions.perpContracts += _openPerpPosition(shortPosition, true);
        }
        // record incremented positions
        positions.margin = getMargin();
        positions.unitAccumulativeFunding = getUnitAccumulativeFunding();
        emit Harvest(
            positions.perpContracts,
            IERC20(long).balanceOf(address(this)),
            positions.margin
        );
    }

    /**
     * @notice  unwind the position in adverse funding rate scenarios, settle short position
     *          and pull funds from the margin account. Then converts the long position back
     *          to want.
     * @dev     only callable by the owner
     */
    function unwind() public onlyAuthorised {
        require(!isUnwind, "unwound");
        isUnwind = true;
        mcLiquidityPool.forceToSyncState();
        // swap long asset back to want
        _swap(IERC20(long).balanceOf(address(this)), long, want);
        // check if the perpetual is in settlement, if it is then settle it
        // otherwise unwind the fund as normal.
        if (!_settle()) {
            // close the short position
            _closeAllPerpPositions();
            // withdraw all cash in the margin account
            mcLiquidityPool.withdraw(
                perpetualIndex,
                address(this),
                getMargin()
            );
        }
        // reset positions
        positions.perpContracts = 0;
        positions.margin = getMargin();
        positions.unitAccumulativeFunding = getUnitAccumulativeFunding();
        emit StrategyUnwind(IERC20(want).balanceOf(address(this)));
    }

    /**
     * @notice  emergency exit the entire strategy in extreme circumstances
     *          unwind the strategy and send the funds to governance
     * @dev     only callable by governance
     */
    function emergencyExit() external onlyGovernance {
        // unwind strategy unless it is already unwound
        if (!isUnwind) {
            unwind();
        }
        uint256 wantBalance = IERC20(want).balanceOf(address(this));
        // send funds to governance
        IERC20(want).safeTransfer(governance, wantBalance);
        emit EmergencyExit(governance, wantBalance);
    }

    /**
     * @notice  remargin the strategy such that margin call risk is reduced
     * @dev     only callable by owner
     */
    function remargin() public onlyOwner {
        // harvest the funds so the positions are up to date
        harvest();
        // ratio of the short in the short and buffer
        int256 K = (((int256(MAX_BPS) - int256(buffer)) / 2) * 1e18) /
            (((int256(MAX_BPS) - int256(buffer)) / 2) + int256(buffer));
        // get the price of ETH
        (, address oracleAddress, ) = mcLiquidityPool.getPerpetualInfo(
            perpetualIndex
        );
        IOracle oracle = IOracle(oracleAddress);
        (int256 price, ) = oracle.priceTWAPLong();
        // calculate amount to unwind
        int256 unwindAmount = (((price * -getMarginPositions()) -
            K *
            getMargin()) * 1e18) / ((1e18 + K) * price);
        require(unwindAmount != 0, "no changes to margin necessary");
        // check if leverage is to be reduced or increased then act accordingly
        if (unwindAmount > 0) {
            // swap unwindAmount long to want
            uint256 wantAmount = _swap(uint256(unwindAmount), long, want);
            // close unwindAmount short to margin account
            mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                unwindAmount,
                price + slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
            // deposit long swapped collateral to margin account
            _depositToMarginAccount(wantAmount);
        } else if (unwindAmount < 0) {
            // the buffer is too high so reduce it to the correct size
            // open a perpetual short position using the unwindAmount
            mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                unwindAmount,
                price - slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
            // withdraw funds from the margin account
            int256 withdrawAmount = (price * -unwindAmount) / 1e18;
            mcLiquidityPool.withdraw(
                perpetualIndex,
                address(this),
                withdrawAmount
            );
            // open a long position with the withdrawn funds
            _swap(uint256(withdrawAmount / DECIMAL_SHIFT), want, long);
        }
        positions.margin = getMargin();
        positions.unitAccumulativeFunding = getUnitAccumulativeFunding();
        positions.perpContracts = getMarginPositions();
        emit Remargined(unwindAmount);
    }

    /**
     * @notice  withdraw funds from the strategy
     * @param   _amount the amount to be withdrawn
     * @return  loss loss recorded
     * @return  withdrawn amount withdrawn
     * @dev     only callable by the vault
     */
    function withdraw(uint256 _amount)
        external
        onlyVault
        returns (uint256 loss, uint256 withdrawn)
    {
        require(_amount > 0, "withdraw: _amount is 0");
        uint256 longPositionWant;
        if (!isUnwind) {
            mcLiquidityPool.forceToSyncState();
            // remove the buffer from the amount
            uint256 bufferPosition = (_amount * buffer) / MAX_BPS;
            // decrement the amount by buffer position
            uint256 _remAmount = _amount - bufferPosition;
            // determine the shortPosition
            uint256 shortPosition = _remAmount / 2;
            // close the short position
            int256 positionsClosed = _closePerpPosition(shortPosition);
            // determine the long position
            uint256 longPosition = uint256(positionsClosed);
            // check that there are enough long positions, if there is not then close all longs
            if (longPosition < IERC20(long).balanceOf(address(this))) {
                // if for whatever reason there are funds left in long when there shouldnt be then liquidate them
                if (getMarginPositions() == 0) {
                    longPosition = IERC20(long).balanceOf(address(this));
                }
                // convert the long to want
                longPositionWant = _swap(longPosition, long, want);
            } else {
                // convert the long to want
                longPositionWant = _swap(
                    IERC20(long).balanceOf(address(this)),
                    long,
                    want
                );
            }
            // check if there is enough margin to cover the buffer and short withdrawal
            // also make sure there are margin positions, as if there are none you can
            // withdraw most of the position
            if (
                getMargin() >
                int256(bufferPosition + shortPosition) * DECIMAL_SHIFT &&
                getMarginPositions() < 0
            ) {
                // withdraw the short and buffer from the margin account
                mcLiquidityPool.withdraw(
                    perpetualIndex,
                    address(this),
                    int256(bufferPosition + shortPosition) * DECIMAL_SHIFT
                );
            } else {
                if (getMarginPositions() < 0) {
                    _closeAllPerpPositions();
                }
                mcLiquidityPool.withdraw(
                    perpetualIndex,
                    address(this),
                    getMargin()
                );
            }
            withdrawn = longPositionWant + shortPosition + bufferPosition;
        } else {
            withdrawn = _amount;
        }

        uint256 wantBalance = IERC20(want).balanceOf(address(this));
        // transfer the funds back to the vault, if at this point needed isnt covered then
        // record a loss
        if (_amount > wantBalance) {
            IERC20(want).safeTransfer(address(vault), wantBalance);
            loss = _amount - wantBalance;
            withdrawn = wantBalance;
        } else {
            IERC20(want).safeTransfer(address(vault), _amount);
            loss = 0;
            withdrawn = _amount;
        }

        positions.perpContracts = getMarginPositions();
        positions.margin = getMargin();
        emit WithdrawStrategy(withdrawn, loss);
    }

    /**
     * @notice  emit a snapshot of the margin account
     */
    function snapshot() public {
        mcLiquidityPool.forceToSyncState();
        (
            int256 cash,
            int256 position,
            int256 availableMargin,
            int256 margin,
            int256 settleableMargin,
            bool isInitialMarginSafe,
            bool isMaintenanceMarginSafe,
            bool isMarginSafe,

        ) = mcLiquidityPool.getMarginAccount(perpetualIndex, address(this));
        emit Snapshot(
            cash,
            position,
            availableMargin,
            margin,
            settleableMargin,
            isInitialMarginSafe,
            isMaintenanceMarginSafe,
            isMarginSafe
        );
    }

    /**
     * @notice  gather any liquidity mining rewards of mcb and transfer them to governance
     *          further distribution
     * @param   epoch the epoch to claim rewards for
     * @param   amount the amount to redeem
     * @param   merkleProof the proof to use on the claim
     * @dev     only callable by governance
     */
    function gatherLMrewards(
        uint256 epoch,
        uint256 amount,
        bytes32[] memory merkleProof
    ) external onlyGovernance {
        lmClaimer.claimEpoch(epoch, amount, merkleProof);
        IERC20(mcb).safeTransfer(
            governance,
            IERC20(mcb).balanceOf(address(this))
        );
    }

    /**
     * @notice  migrate all strategy funds to a new strategy
     *          unwind the strategy and send the funds to the new strategy
     * @dev     only callable by governance, make sure the vault contract is paused
     *          before calling this function
     */
    function migrate(address newStrategy) external onlyGovernance {
        // unwind strategy unless it is already unwound
        if (!isUnwind) {
            unwind();
        }
        uint256 wantBalance = IERC20(want).balanceOf(address(this));
        // migrate the funds to the new strategy
        IERC20(want).safeTransfer(newStrategy, wantBalance);
        emit Migrated(newStrategy, wantBalance);
    }

    /**********************
     * INTERNAL FUNCTIONS *
     **********************/

    /**
     * @notice  open the perpetual short position on MCDEX
     * @param   _amount the collateral used to purchase the perpetual short position
     * @return  tradeAmount the amount of perpetual contracts opened
     */
    function _openPerpPosition(uint256 _amount, bool deposit)
        internal
        returns (int256 tradeAmount)
    {
        if (deposit) {
            // deposit funds to the margin account to enable trading
            _depositToMarginAccount(_amount);
        }

        (, address oracleAddress, ) = mcLiquidityPool.getPerpetualInfo(
            perpetualIndex
        );
        IOracle oracle = IOracle(oracleAddress);
        // get the long asset mark price from the MCDEX oracle
        (int256 price, ) = oracle.priceTWAPLong();
        // calculate the number of contracts (*1e12 because USDC is 6 decimals)
        int256 contracts = ((int256(_amount) * DECIMAL_SHIFT) * 1e18) / price;
        int256 longBalInt = -int256(IERC20(long).balanceOf(address(this)));
        // check that the long and short positions will be equal after the deposit
        if (-contracts + getMarginPositions() >= longBalInt) {
            // open short position
            tradeAmount = mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                -contracts,
                price - slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
        } else {
            tradeAmount = mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                -(getMarginPositions() - longBalInt),
                price - slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
        }
        emit PerpPositionOpened(tradeAmount, perpetualIndex, _amount);
    }

    /**
     * @notice  close the perpetual short position on MCDEX
     * @param   _amount the collateral to be returned from the short position
     * @return  tradeAmount the amount of perpetual contracts closed
     */
    function _closePerpPosition(uint256 _amount)
        internal
        returns (int256 tradeAmount)
    {
        (, address oracleAddress, ) = mcLiquidityPool.getPerpetualInfo(
            perpetualIndex
        );
        IOracle oracle = IOracle(oracleAddress);
        // get the long asset mark price from the MCDEX oracle
        (int256 price, ) = oracle.priceTWAPLong();
        // calculate the number of contracts (*1e12 because USDC is 6 decimals)
        int256 contracts = ((int256(_amount) * DECIMAL_SHIFT) * 1e18) / price;
        if (contracts + getMarginPositions() < -dust) {
            // close short position
            tradeAmount = mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                contracts,
                price + slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );
        } else {
            // close all remaining short positions
            tradeAmount = mcLiquidityPool.trade(
                perpetualIndex,
                address(this),
                -getMarginPositions(),
                price + slippageTolerance,
                block.timestamp,
                referrer,
                tradeMode
            );

            emit PerpPositionClosed(tradeAmount, perpetualIndex, _amount);
        }
    }

    /**
     * @notice  close all perpetual short positions on MCDEX
     * @return  tradeAmount the amount of perpetual contracts closed
     */
    function _closeAllPerpPositions() internal returns (int256 tradeAmount) {
        (, address oracleAddress, ) = mcLiquidityPool.getPerpetualInfo(
            perpetualIndex
        );
        IOracle oracle = IOracle(oracleAddress);
        // get the long asset mark price from the MCDEX oracle
        (int256 price, ) = oracle.priceTWAPLong();
        // close short position
        tradeAmount = mcLiquidityPool.trade(
            perpetualIndex,
            address(this),
            -getMarginPositions(),
            price + slippageTolerance,
            block.timestamp,
            referrer,
            tradeMode
        );
        emit AllPerpPositionsClosed(tradeAmount, perpetualIndex);
    }

    /**
     * @notice  deposit to the margin account without opening a perpetual position
     * @param   _amount the amount to deposit into the margin account
     */
    function _depositToMarginAccount(uint256 _amount) internal {
        IERC20(want).safeApprove(address(mcLiquidityPool), _amount);
        mcLiquidityPool.deposit(
            perpetualIndex,
            address(this),
            int256(_amount) * DECIMAL_SHIFT
        );
        emit DepositToMarginAccount(_amount, perpetualIndex);
    }

    /**
     * @notice  determine the funding premiums that have been collected since the last epoch
     * @return  fee  the funding rate premium collected since the last epoch
     * @return  loss whether the funding rate was a loss or not
     */
    function _determineFee() internal returns (uint256 fee, bool loss) {
        int256 feeInt;
        // get the cash held in the margin cash, funding rates are saved as cash in the margin account
        int256 newAccFunding = getUnitAccumulativeFunding();
        int256 prevAccFunding = positions.unitAccumulativeFunding;
        int256 livePositions = getMarginPositions();
        if (prevAccFunding >= newAccFunding) {
            // if the margin cash held has gone down then record a loss
            loss = true;
            feeInt = ((prevAccFunding - newAccFunding) * -livePositions) / 1e18; // why `-livePositions`?
            fee = uint256(feeInt / DECIMAL_SHIFT);
        } else {
            // if the margin cash held has gone up then record a profit and withdraw the excess for redistribution
            feeInt = ((newAccFunding - prevAccFunding) * -livePositions) / 1e18; // why `-livePositions`?
            uint256 balanceBefore = IERC20(want).balanceOf(address(this));
            if (feeInt > 0) {
                mcLiquidityPool.withdraw(perpetualIndex, address(this), feeInt);
            }
            fee = IERC20(want).balanceOf(address(this)) - balanceBefore;
        }
    }

    /**
     * @notice  split an amount of assets into three:
     *          the short position which represents the short perpetual position
     *          the long position which represents the long spot position
     *          the buffer position which represents the funds to be left idle in the margin account
     * @param   _amount the amount to be split in want
     * @return  shortPosition  the size of the short perpetual position in want
     * @return  longPosition   the size of the long spot position in long
     * @return  bufferPosition the size of the buffer position in want
     */
    function _calculateSplit(uint256 _amount)
        internal
        returns (
            uint256 shortPosition,
            uint256 longPosition,
            uint256 bufferPosition
        )
    {
        require(_amount > 0, "_calculateSplit: _amount is 0");
        // remove the buffer from the amount
        bufferPosition = (_amount * buffer) / MAX_BPS;
        // decrement the amount by buffer position
        _amount -= bufferPosition;
        // determine the longPosition in want then convert it to long
        uint256 longPositionWant = _amount / 2;
        longPosition = _swap(longPositionWant, want, long); // maybe need to move to the harvers function
        // determine the short position
        shortPosition = _amount - longPositionWant;
    }

    /**
     * @notice  swap function using uniswapv3 to facilitate the swap, specifying the amount in
     * @param   _amount    the amount to be swapped in want
     * @param   _tokenIn   the asset sent in
     * @param   _tokenOut  the asset taken out
     * @return  amountOut the amount of tokenOut exchanged for tokenIn
     */
    function _swap(
        uint256 _amount,
        address _tokenIn,
        address _tokenOut
    ) internal returns (uint256 amountOut) {
        // set up swap params
        if (!isV2) {
            uint256 deadline = block.timestamp;
            address tokenIn = _tokenIn;
            address tokenOut = _tokenOut;
            uint24 fee = IUniswapV3Pool(pool).fee();
            address recipient = address(this);
            uint256 amountIn = _amount;
            uint256 amountOutMinimum = 0;
            uint160 sqrtPriceLimitX96 = 0;
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams(
                    tokenIn,
                    tokenOut,
                    fee,
                    recipient,
                    deadline,
                    amountIn,
                    amountOutMinimum,
                    sqrtPriceLimitX96
                );
            // approve the router to spend the tokens
            IERC20(_tokenIn).safeApprove(router, _amount);
            // swap optimistically via the uniswap v3 router
            amountOut = ISwapRouter(router).exactInputSingle(params);
        } else {
            uint256 expectedAmountOut;
            //get balance of tokenOut
            uint256 amountTokenOut = IERC20(_tokenOut).balanceOf(address(this));
            // set the swap params
            uint256 deadline = block.timestamp;
            address[] memory path;
            if (_tokenIn == weth || _tokenOut == weth) {
                path = new address[](2);
                path[0] = _tokenIn;
                path[1] = _tokenOut;
                if (isSlippageControl) {
                    // maybe need to decrease by allowed slippage
                    expectedAmountOut = IRouterV2(router).getAmountsOut(
                        _amount,
                        path
                    )[1];
                }
            } else {
                path = new address[](3);
                path[0] = _tokenIn;
                path[1] = weth;
                path[2] = _tokenOut;
                if (isSlippageControl) {
                    // maybe need to decrease by allowed slippage
                    expectedAmountOut = IRouterV2(router).getAmountsOut(
                        _amount,
                        path
                    )[2];
                }
            }

            // approve the router to spend the token
            IERC20(_tokenIn).safeApprove(router, _amount);
            IRouterV2(router).swapExactTokensForTokens(
                _amount,
                expectedAmountOut,
                path,
                address(this),
                deadline
            );

            amountOut =
                IERC20(_tokenOut).balanceOf(address(this)) -
                amountTokenOut;
        }
    }

    /**
     * @notice  swap function using uniswapv3 to facilitate the swap, specifying the amount in
     * @param   _amount    the amount to be swapped into want
     * @param   _tokenIn   the asset sent in
     * @param   _tokenOut  the asset taken out
     * @return  out the amount of tokenOut exchanged for tokenIn
     */
    function _swapTokenOut(
        uint256 _amount,
        address _tokenIn,
        address _tokenOut
    ) internal returns (uint256 out) {
        if (!isV2) {
            // set up swap params
            uint256 deadline = block.timestamp;
            address tokenIn = _tokenIn;
            address tokenOut = _tokenOut;
            uint24 fee = IUniswapV3Pool(pool).fee();
            address recipient = address(this);
            uint256 amountOut = _amount;
            uint256 amountInMaximum = IERC20(_tokenIn).balanceOf(address(this));
            uint160 sqrtPriceLimitX96 = 0;
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams(
                    tokenIn,
                    tokenOut,
                    fee,
                    recipient,
                    deadline,
                    amountOut,
                    amountInMaximum,
                    sqrtPriceLimitX96
                );
            // approve the router to spend the tokens
            IERC20(_tokenIn).safeApprove(
                router,
                IERC20(_tokenIn).balanceOf(address(this))
            );
            // swap optimistically via the uniswap v3 router
            out = ISwapRouter(router).exactOutputSingle(params);
        } else {
            uint256 expectedAmountOut;
            //get balance of tokenOut
            uint256 amountTokenOut = IERC20(_tokenOut).balanceOf(address(this));
            // set the swap params
            uint256 deadline = block.timestamp;
            address[] memory path;
            if (_tokenIn == weth || _tokenOut == weth) {
                path = new address[](2);
                path[0] = _tokenIn;
                path[1] = _tokenOut;
                if (isSlippageControl) {
                    expectedAmountOut = IRouterV2(router).getAmountsOut(
                        _amount,
                        path
                    )[1];
                }
            } else {
                path = new address[](3);
                path[0] = _tokenIn;
                path[1] = weth;
                path[2] = _tokenOut;
                if (isSlippageControl) {
                    expectedAmountOut = IRouterV2(router).getAmountsOut(
                        _amount,
                        path
                    )[2];
                }
            }

            // approve the router to spend the token
            IERC20(_tokenIn).safeApprove(router, _amount);
            IRouterV2(router).swapExactTokensForTokens(
                _amount,
                expectedAmountOut,
                path,
                address(this),
                deadline
            );

            out = IERC20(_tokenOut).balanceOf(address(this)) - amountTokenOut;
        }
    }

    /**
     * @notice  settle function for dealing with the perpetual if it has settled
     * @return  isSettled whether the perp needed to be settled or not.
     */
    function _settle() internal returns (bool isSettled) {
        (IMCLP.PerpetualState perpetualState, , ) = mcLiquidityPool
            .getPerpetualInfo(perpetualIndex);
        if (perpetualState == IMCLP.PerpetualState.CLEARED) {
            mcLiquidityPool.settle(perpetualIndex, address(this));
            isSettled = true;
        }
    }

    /***********
     * GETTERS *
     ***********/

    /**
     * @notice  getter for the MCDEX margin account cash balance of the strategy
     * @return  cash of the margin account
     */
    function getMarginCash() public view returns (int256 cash) {
        (cash, , , , , , , , ) = mcLiquidityPool.getMarginAccount(
            perpetualIndex,
            address(this)
        );
    }

    /**
     * @notice  getter for the MCDEX margin positions of the strategy
     * @return  position of the margin account
     */
    function getMarginPositions() public view returns (int256 position) {
        (, position, , , , , , , ) = mcLiquidityPool.getMarginAccount(
            perpetualIndex,
            address(this)
        );
    }

    /**
     * @notice  getter for the MCDEX margin  of the strategy
     * @return  margin of the margin account
     */
    function getMargin() public view returns (int256 margin) {
        (, , , margin, , , , , ) = mcLiquidityPool.getMarginAccount(
            perpetualIndex,
            address(this)
        );
    }

    /**
     * @notice Get the account info of the trader. Need to update the funding state and the oracle price
     *         of each perpetual before and update the funding rate of each perpetual after
     * @return cash the cash held in the margin account
     * @return position The position of the account
     * @return availableMargin The available margin of the account
     * @return margin The margin of the account
     * @return settleableMargin The settleable margin of the account
     * @return isInitialMarginSafe True if the account is initial margin safe
     * @return isMaintenanceMarginSafe True if the account is maintenance margin safe
     * @return isMarginSafe True if the total value of margin account is beyond 0
     */
    function getMarginAccount()
        public
        view
        returns (
            int256 cash,
            int256 position,
            int256 availableMargin,
            int256 margin,
            int256 settleableMargin,
            bool isInitialMarginSafe,
            bool isMaintenanceMarginSafe,
            bool isMarginSafe // bankrupt
        )
    {
        (
            cash,
            position,
            availableMargin,
            margin,
            settleableMargin,
            isInitialMarginSafe,
            isMaintenanceMarginSafe,
            isMarginSafe,

        ) = mcLiquidityPool.getMarginAccount(perpetualIndex, address(this));
    }

    /**
     * @notice Get the funding rate
     * @return the funding rate of the perpetual
     */
    function getFundingRate() public view returns (int256) {
        (, , int256[39] memory nums) = mcLiquidityPool.getPerpetualInfo(
            perpetualIndex
        );
        return nums[3];
    }

    /**
     * @notice Get the unit accumulative funding
     * @return get the unit accumulative funding of the perpetual
     */
    function getUnitAccumulativeFunding() public view returns (int256) {
        (, , int256[39] memory nums) = mcLiquidityPool.getPerpetualInfo(
            perpetualIndex
        );
        return nums[4];
    }
}