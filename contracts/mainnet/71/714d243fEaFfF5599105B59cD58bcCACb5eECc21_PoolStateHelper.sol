//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILeveragedPool.sol";
import "./interfaces/IPoolCommitter.sol";
import "./interfaces/IPoolKeeper.sol";
import "./interfaces/IOracleWrapper.sol";
import "./libraries/PoolSwapLibrary.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @dev Extended interfaces
interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint256);
}

interface IPoolCommitter2 is IPoolCommitter {
    function totalPoolCommitments(uint256 _updateIntervalId)
        external
        view
        returns (IPoolCommitter.TotalCommitment memory);

    function burningFee() external view returns (bytes16);

    function mintingFee() external view returns (bytes16);
}

interface ILeveragedPool2 is ILeveragedPool {
    function fee() external view returns (bytes16);

    function keeper() external view returns (address);

    function leverageAmount() external view override returns (bytes16);
}

interface IPoolKeeper2 is IPoolKeeper {
    function executionPrice(address _poolAddress)
        external
        view
        returns (int256 _lastExecutionPrice);
}

interface ISMAOracle is IOracleWrapper {
    function numPeriods() external view returns (int256);

    function prices(int256 _numPeriod) external view returns (int256 price);

    function periodCount() external view returns (int256);
}

interface IPoolStateHelper {
    error INVALID_PERIOD();

    struct SideInfo {
        uint256 supply; // poolToken.totalSupply()
        uint256 settlementBalance; // balance of settlementTokens associated with supply
        uint256 pendingBurnPoolTokens;
    }

    struct PoolInfo {
        SideInfo long;
        SideInfo short;
    }

    struct SMAInfo {
        int256[] prices;
        uint256 numPeriods;
    }

    struct ExpectedPoolState {
        //in settlementToken decimals
        uint256 cumulativePendingMintSettlement;
        uint256 longSupply;
        uint256 longBalance;
        uint256 shortSupply;
        uint256 shortBalance;
        int256 oraclePrice;
    }

    struct PoolStateSnapshot {
        uint256 pointer;
        IPoolCommitter2.TotalCommitment[] commitQueue;
        int256 lastExecutedPrice;
        int256 spotPrice;
        SMAInfo smaInfo;
        PoolInfo poolInfo;
        bytes16 leverageAmount;
        bytes16 poolManagementFee;
        bytes16 burningFee;
        bytes16 mintingFee;
        uint256 pendingMintSettlement;
        uint256 settlementTokenDecimals;
    }

    function getCommitQueue(IPoolCommitter2 committer, uint256 periods)
        external
        view
        returns (IPoolCommitter2.TotalCommitment[] memory commitQueue);

    function getPoolInfo(ILeveragedPool2 pool, IPoolCommitter2 committer)
        external
        view
        returns (PoolInfo memory poolInfo);

    function getExpectedState(ILeveragedPool2 pool, uint256 periods)
        external
        view
        returns (ExpectedPoolState memory finalExpectedPoolState);

    function fullCommitPeriod(ILeveragedPool2 pool)
        external
        view
        returns (uint256);
}

contract PoolStateHelper is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IPoolStateHelper
{
    // From LeveragedPool.sol
    uint128 public constant LONG_INDEX = 0;
    uint128 public constant SHORT_INDEX = 1;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @notice Get an array of TotalCommitment in ascending order for a given period.
     * @return commitQueue
     * @param committer The PoolCommitter contract.
     * @param periods The number of commits to get.
     */
    function getCommitQueue(IPoolCommitter2 committer, uint256 periods)
        public
        view
        override
        returns (IPoolCommitter2.TotalCommitment[] memory commitQueue)
    {
        uint256 currentUpdateIntervalId = committer.updateIntervalId();
        commitQueue = new IPoolCommitter2.TotalCommitment[](periods);

        unchecked {
            for (uint256 i; i < periods; i++) {
                commitQueue[i] = committer.totalPoolCommitments(
                    currentUpdateIntervalId + i
                );
            }
        }
    }

    ///@dev Get latest SMA prices. The oldest price is omitted if the SMA is fully "ramped up", i.e. smaOracle.periodCount() >= smaOracle.numPeriods().
    function getSMAPrices(ISMAOracle smaOracle)
        public
        view
        returns (SMAInfo memory smaInfo)
    {
        uint256 _periodCount = uint256(smaOracle.periodCount());
        uint256 _numPeriods = uint256(smaOracle.numPeriods());
        uint256 _i;

        smaInfo.numPeriods = _numPeriods;

        unchecked {
            if (_periodCount < _numPeriods) {
                _i = 0;
                smaInfo.prices = new int256[](_periodCount);
            } else {
                // Exclude price at index[0] because prices are FIFO up to numPeriods, so -1.
                _i = _periodCount - (_numPeriods - 1);
                smaInfo.prices = new int256[](_numPeriods - 1);
            }

            for (uint256 i = _i; i < _periodCount; i++) {
                smaInfo.prices[
                    _periodCount < _numPeriods
                        ? i
                        : i + _numPeriods - _periodCount - 1
                ] = smaOracle.prices(int256(i));
            }
        }
    }

    /**
     * @notice Get relevant information from pool.
     * @return poolInfo
     * @param pool The LeveragedPool contract.
     * @param committer The PoolCommiter contract.
     */
    function getPoolInfo(ILeveragedPool2 pool, IPoolCommitter2 committer)
        public
        view
        override
        returns (PoolInfo memory poolInfo)
    {
        address[2] memory tokens = pool.poolTokens();

        poolInfo = PoolInfo({
            long: SideInfo({
                supply: IERC20(tokens[LONG_INDEX]).totalSupply(),
                settlementBalance: pool.longBalance(),
                pendingBurnPoolTokens: committer.pendingLongBurnPoolTokens()
            }),
            short: SideInfo({
                supply: IERC20(tokens[SHORT_INDEX]).totalSupply(),
                settlementBalance: pool.shortBalance(),
                pendingBurnPoolTokens: committer.pendingShortBurnPoolTokens()
            })
        });
    }

    /**
     * @notice The number of TotalCommitments that will be executed at the end of the frontrunning interval.
     * Rounded up if not fully divisible.
     * @return fullCommitPeriod
     * @param pool The LeveragedPool contract.
     */
    function fullCommitPeriod(ILeveragedPool2 pool)
        public
        view
        override
        returns (uint256)
    {
        return (pool.frontRunningInterval() / pool.updateInterval()) + 1;
    }

    function currentPoolState(ILeveragedPool2 pool)
        private
        view
        returns (ExpectedPoolState memory)
    {
        address[2] memory tokens = pool.poolTokens();
        address oracleWrapper = pool.oracleWrapper();

        return
            ExpectedPoolState({
                cumulativePendingMintSettlement: 0, // There are no pending settlements, since we're getting the most recent state
                longSupply: IERC20(tokens[LONG_INDEX]).totalSupply(),
                longBalance: pool.longBalance(),
                shortSupply: IERC20(tokens[SHORT_INDEX]).totalSupply(),
                shortBalance: pool.shortBalance(),
                oraclePrice: IOracleWrapper(oracleWrapper).getPrice()
            });
    }

    function isSMAOracle(address oracle) public view returns (bool result) {
        try ISMAOracle(oracle).numPeriods() returns (int256) {
            result = true;
        } catch (bytes memory) {
            result = false;
        }
    }

    function getExpectedState(ILeveragedPool2 pool, uint256 periods)
        external
        view
        override
        returns (ExpectedPoolState memory finalExpectedPoolState)
    {
        if (periods > fullCommitPeriod(pool)) revert INVALID_PERIOD();

        if (periods == 0) {
            return currentPoolState(pool);
        }

        address priceOracle = pool.oracleWrapper();

        int256 _spotPrice;
        SMAInfo memory _smaInfo;

        if (isSMAOracle(priceOracle)) {
            // SMA -> spot -> chainlink
            _spotPrice = IOracleWrapper(IOracleWrapper(priceOracle).oracle())
                .getPrice();
            _smaInfo = getSMAPrices(ISMAOracle(priceOracle));
        } else {
            // spot -> chainlink
            _spotPrice = IOracleWrapper(priceOracle).getPrice();
        }

        IPoolKeeper2 keeper = IPoolKeeper2(pool.keeper());
        IPoolCommitter2 committer = IPoolCommitter2(pool.poolCommitter());
        uint256 settlementTokenDecimals = IERC20WithDecimals(
            pool.settlementToken()
        ).decimals();

        PoolStateSnapshot memory poolStateSnapshot = PoolStateSnapshot({
            pointer: 0,
            commitQueue: getCommitQueue(committer, periods),
            lastExecutedPrice: keeper.executionPrice(address(pool)),
            spotPrice: _spotPrice,
            smaInfo: _smaInfo,
            poolInfo: getPoolInfo(pool, committer),
            leverageAmount: pool.leverageAmount(),
            poolManagementFee: pool.fee(),
            burningFee: committer.burningFee(),
            mintingFee: committer.mintingFee(),
            pendingMintSettlement: 0, // Cumulative pendingMintSettlementAmount. Should match PoolCommitter.pendingMintSettlementAmount() as a sanity check at the end of a full commitQueue.
            settlementTokenDecimals: settlementTokenDecimals
        });

        finalExpectedPoolState = simExpectedPoolState(poolStateSnapshot);
    }

    /// @dev Exclusive of keeper fee, and dynamic minting fees, may be iffy if frontRunningInterval is not completely divisible by updateInterval
    function simExpectedPoolState(PoolStateSnapshot memory poolStateSnapshot)
        private
        view
        returns (ExpectedPoolState memory finalExpectedPoolState)
    {
        // Calculate new price

        int256 newPrice;
        SMAInfo memory updatedSmaInfo;

        // Assumption: If it's an SMAOracle, numPeriods is at least 1.
        if (poolStateSnapshot.smaInfo.numPeriods == 0) {
            newPrice = poolStateSnapshot.spotPrice;
            updatedSmaInfo = poolStateSnapshot.smaInfo;
        } else {
            (newPrice, updatedSmaInfo) = getNewPrice(
                poolStateSnapshot.smaInfo,
                poolStateSnapshot.spotPrice
            );
        }

        PoolInfo memory newPoolInfo = executeGivenCommit(
            poolStateSnapshot.commitQueue[poolStateSnapshot.pointer],
            calculateValueTransfer(
                poolStateSnapshot.lastExecutedPrice,
                newPrice,
                poolStateSnapshot.poolInfo,
                poolStateSnapshot.leverageAmount,
                poolStateSnapshot.poolManagementFee
            ),
            poolStateSnapshot.burningFee,
            poolStateSnapshot.mintingFee
        );

        uint256 newPendingSettlement = poolStateSnapshot.pendingMintSettlement +
            poolStateSnapshot
                .commitQueue[poolStateSnapshot.pointer]
                .longMintSettlement +
            poolStateSnapshot
                .commitQueue[poolStateSnapshot.pointer]
                .shortMintSettlement;

        if (
            poolStateSnapshot.pointer + 1 ==
            poolStateSnapshot.commitQueue.length
        ) {
            // Base case
            finalExpectedPoolState = ExpectedPoolState({
                cumulativePendingMintSettlement: newPendingSettlement,
                longBalance: newPoolInfo.long.settlementBalance,
                longSupply: newPoolInfo.long.supply,
                shortBalance: newPoolInfo.short.settlementBalance,
                shortSupply: newPoolInfo.short.supply,
                oraclePrice: newPrice
            });
        } else {
            PoolStateSnapshot memory newPoolStateSnapshot = poolStateSnapshot;

            newPoolStateSnapshot.pointer = poolStateSnapshot.pointer + 1;
            newPoolStateSnapshot.poolInfo = newPoolInfo;
            newPoolStateSnapshot.lastExecutedPrice = newPrice;

            newPoolStateSnapshot.pendingMintSettlement = newPendingSettlement;
            newPoolStateSnapshot.smaInfo = updatedSmaInfo;

            finalExpectedPoolState = simExpectedPoolState(newPoolStateSnapshot);
        }
    }

    /** PURE FUNCTIONS */

    function getNewPrice(SMAInfo memory smaInfo, int256 spotPrice)
        public
        pure
        returns (int256, SMAInfo memory updatedSmaInfo)
    {
        unchecked {
            uint256 len = smaInfo.prices.length;
            int256 sum;

            // if len < numperiods; len + 1 : numPeriods - 1;
            uint256 updatedLen = len < smaInfo.numPeriods - 1
                ? len + 1
                : smaInfo.numPeriods - 1;
            updatedSmaInfo.prices = new int256[](updatedLen);

            for (uint256 i; i < len; i++) {
                sum += smaInfo.prices[i];

                if (i < len - 1) {
                    updatedSmaInfo.prices[i] = smaInfo.prices[i + 1];
                }
            }

            sum += spotPrice;
            updatedSmaInfo.prices[updatedLen - 1] = spotPrice;
            updatedSmaInfo.numPeriods = smaInfo.numPeriods;
            return (sum / int256(len + 1), updatedSmaInfo);
        }
    }

    /**
     * @notice Returns updated PoolInfo after value transfer.
     * @return newPoolInfo
     * @param oldPrice last executed price.
     * @param newPrice new price.
     * @param poolInfo pool info snapshot.
     * @param leverageAmount leverage.
     * @param poolManagementFee fee.
     */
    function calculateValueTransfer(
        int256 oldPrice,
        int256 newPrice,
        PoolInfo memory poolInfo,
        bytes16 leverageAmount,
        bytes16 poolManagementFee
    ) public pure returns (PoolInfo memory newPoolInfo) {
        (
            uint256 postXferLongBalance,
            uint256 postXferShortBalance,
            ,

        ) = PoolSwapLibrary.calculateValueTransfer(
                poolInfo.long.settlementBalance,
                poolInfo.short.settlementBalance,
                leverageAmount,
                oldPrice,
                newPrice,
                poolManagementFee
            );

        newPoolInfo = poolInfo;
        newPoolInfo.long.settlementBalance = postXferLongBalance;
        newPoolInfo.short.settlementBalance = postXferShortBalance;
    }

    /**
     * @notice Returns price of token given sideInfo.
     * @return price bytes16
     * @param sideInfo Information on the side to get price of.
     */
    function getPrice(SideInfo memory sideInfo) public pure returns (bytes16) {
        return
            PoolSwapLibrary.getPrice(
                sideInfo.settlementBalance,
                sideInfo.supply + sideInfo.pendingBurnPoolTokens
            );
    }

    function executeInstantSettlements(
        IPoolCommitter2.TotalCommitment memory totalCommitment,
        PoolInfo memory poolInfo,
        bytes16 burningFee,
        bytes16 mintingFee
    )
        public
        pure
        returns (
            uint256 longBurnInstantMintSettlement,
            uint256 shortBurnInstantMintSettlement
        )
    {
        // Amount of collateral tokens that are generated from burns into instant mints

        (longBurnInstantMintSettlement, , ) = PoolSwapLibrary
            .processBurnInstantMintCommit(
                totalCommitment.longBurnShortMintPoolTokens,
                getPrice(poolInfo.long),
                burningFee,
                mintingFee
            );

        (shortBurnInstantMintSettlement, , ) = PoolSwapLibrary
            .processBurnInstantMintCommit(
                totalCommitment.shortBurnLongMintPoolTokens,
                getPrice(poolInfo.short),
                burningFee,
                mintingFee
            );
    }

    function executeCommitsForSide(
        IPoolCommitter2.TotalCommitment memory totalCommitment,
        SideInfo memory side,
        uint256 shortBurnInstantMintSettlement,
        uint256 totalBurnPoolTokens
    ) public pure returns (uint256 mintedPoolTokens, uint256 burnedPooltokens) {
        // Mints
        mintedPoolTokens = PoolSwapLibrary.getMintAmount(
            side.supply, // long token total supply,
            totalCommitment.longMintSettlement + shortBurnInstantMintSettlement, // Add the settlement tokens that will be generated from burning shorts for instant long mint
            side.settlementBalance, // total quote tokens in the long pool
            side.pendingBurnPoolTokens // total pool tokens commited to be burned
        );

        // Burns
        burnedPooltokens = PoolSwapLibrary.getWithdrawAmountOnBurn(
            side.supply,
            totalBurnPoolTokens,
            side.settlementBalance,
            side.pendingBurnPoolTokens
        );
    }

    function executeGivenCommit(
        IPoolCommitter2.TotalCommitment memory totalCommitment,
        PoolInfo memory poolInfo,
        bytes16 burningFee,
        bytes16 mintingFee
    ) public pure returns (PoolInfo memory newPoolInfo) {
        newPoolInfo = PoolInfo({
            long: SideInfo({
                supply: poolInfo.long.supply,
                settlementBalance: totalCommitment.longMintSettlement +
                    poolInfo.long.settlementBalance,
                pendingBurnPoolTokens: poolInfo.long.pendingBurnPoolTokens
            }),
            short: SideInfo({
                supply: poolInfo.short.supply,
                settlementBalance: totalCommitment.shortMintSettlement +
                    poolInfo.short.settlementBalance,
                pendingBurnPoolTokens: poolInfo.short.pendingBurnPoolTokens
            })
        });

        // Flips
        (
            uint256 longBurnInstantMintSettlement,
            uint256 shortBurnInstantMintSettlement
        ) = executeInstantSettlements(
                totalCommitment,
                poolInfo,
                burningFee,
                mintingFee
            );

        newPoolInfo.short.settlementBalance += longBurnInstantMintSettlement;
        newPoolInfo.long.settlementBalance += shortBurnInstantMintSettlement;

        // Long mints & burns
        {
            uint256 totalLongBurnPoolTokens = totalCommitment
                .longBurnPoolTokens +
                totalCommitment.longBurnShortMintPoolTokens;

            (
                uint256 longMintPoolTokens,
                uint256 longBurnPoolTokens
            ) = executeCommitsForSide(
                    totalCommitment,
                    poolInfo.long,
                    shortBurnInstantMintSettlement,
                    totalLongBurnPoolTokens
                );

            newPoolInfo.long.settlementBalance -= longBurnPoolTokens;
            newPoolInfo.long.supply += longMintPoolTokens;
            newPoolInfo.long.pendingBurnPoolTokens -= totalLongBurnPoolTokens;
        }

        // Short mints & burns
        {
            uint256 totalShortBurnPoolTokens = totalCommitment
                .shortBurnPoolTokens +
                totalCommitment.shortBurnLongMintPoolTokens;

            (
                uint256 shortMintPoolTokens,
                uint256 shortBurnPoolTokens
            ) = executeCommitsForSide(
                    totalCommitment,
                    poolInfo.short,
                    longBurnInstantMintSettlement,
                    totalShortBurnPoolTokens
                );

            newPoolInfo.short.settlementBalance -= shortBurnPoolTokens;
            newPoolInfo.short.supply += shortMintPoolTokens;
            newPoolInfo.short.pendingBurnPoolTokens -= totalShortBurnPoolTokens;
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
    event FeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @notice Represents change in secondary fee receiver's address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event SecondaryFeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @notice Represents change in keeper's address
     * @param oldAddress Previous address
     * @param newAddress Address after change
     */
    event KeeperAddressChanged(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @notice Indicates a payment of fees to the secondary fee address
     * @param secondaryFeeAddress The address that got fees paid to it
     * @param amount Amount of settlement token paid
     */
    event SecondaryFeesPaid(
        address indexed secondaryFeeAddress,
        uint256 amount
    );

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

    function payKeeperFromBalances(address to, uint256 amount)
        external
        returns (bool);

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

    function setNewPoolBalances(uint256 _longBalance, uint256 _shortBalance)
        external;

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

    function balances()
        external
        view
        returns (uint256 _shortBalance, uint256 _longBalance);

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
    event ExecutedCommitsForInterval(
        uint256 indexed updateIntervalId,
        bytes16 burningFee
    );

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

    function getAggregateBalance(address user)
        external
        view
        returns (Balance memory _balance);

    function getAppropriateUpdateIntervalId() external view returns (uint128);

    function setPool(address _leveragedPool) external;

    function setBurningFee(uint256 _burningFee) external;

    function setMintingFee(uint256 _mintingFee) external;

    function setChangeInterval(uint256 _changeInterval) external;

    function setFeeController(address _feeController) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The manager contract interface for multiple markets and the pools in them
interface IPoolKeeper {
    // #### Events
    /**
     * @notice Creates a notification when a pool is created
     * @param poolAddress The pool address of the newly created pool
     * @param firstPrice The price of the market oracle when the pool was created
     */
    event PoolAdded(address indexed poolAddress, int256 indexed firstPrice);

    /**
     * @notice Creates a notification when a call to LeveragedPool:poolUpkeep is successful
     * @param pool The pool address being upkept
     * @param data Extra data about the price fetch. This could be roundID in the case of Chainlink Oracles
     * @param startPrice The previous price of the pool
     * @param endPrice The new price of the pool
     */
    event UpkeepSuccessful(
        address indexed pool,
        bytes data,
        int256 indexed startPrice,
        int256 indexed endPrice
    );

    /**
     * @notice Creates a notification when a keeper is paid for doing upkeep for a pool
     * @param _pool Address of pool being upkept
     * @param keeper Keeper to be rewarded for upkeeping
     * @param reward Keeper's reward (in settlement tokens)
     */
    event KeeperPaid(
        address indexed _pool,
        address indexed keeper,
        uint256 reward
    );

    /**
     * @notice Creates a notification when a keeper's payment for upkeeping a pool failed
     * @param _pool Address of pool being upkept
     * @param keeper Keeper to be rewarded for upkeeping
     * @param expectedReward Keeper's expected reward (in settlement tokens); not actually transferred
     */
    event KeeperPaymentError(
        address indexed _pool,
        address indexed keeper,
        uint256 expectedReward
    );

    /**
     * @notice Creates a notification of a failed pool update
     * @param pool The pool that failed to update
     * @param reason The reason for the error
     */
    event PoolUpkeepError(address indexed pool, string reason);

    /**
     * @notice Indicates that the factory address has changed
     * @param factory Address of the new factory
     */
    event FactoryChanged(address indexed factory);

    /**
     * @notice Indicates that the KeeperRewards contract has
     * @param oldKeeperRewards The previous KeeperRewards contract
     * @param newKeeperRewards The new KeeperRewards contract
     */
    event KeeperRewardsSet(
        address indexed oldKeeperRewards,
        address indexed newKeeperRewards
    );

    /**
     * @notice Indicates that the gas price for keeper rewards changed
     * @param price New gas price
     */
    event GasPriceChanged(uint256 indexed price);

    // #### Variables

    function keeperRewards() external returns (address);

    // #### Functions
    function newPool(address _poolAddress) external;

    function isUpkeepRequiredSinglePool(address pool)
        external
        view
        returns (bool);

    function checkUpkeepMultiplePools(address[] calldata pools)
        external
        view
        returns (bool);

    function performUpkeepSinglePool(address pool) external;

    function performUpkeepMultiplePools(address[] calldata pools) external;

    function setKeeperRewards(address _keeperRewards) external;

    function setGasPrice(uint256 _price) external;

    function performUpkeepMultiplePoolsPacked(bytes calldata pools) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The oracle wrapper contract interface
interface IOracleWrapper {
    function oracle() external view returns (address);

    function decimals() external view returns (uint8);

    function deployer() external view returns (address);

    // #### Functions

    /**
     * @notice Returns the current price for the asset in question
     * @return The latest price
     */
    function getPrice() external view returns (int256);

    /**
     * @return _price The latest round data price
     * @return _data The metadata. Implementations can choose what data to return here
     */
    function getPriceAndMetadata()
        external
        view
        returns (int256 _price, bytes memory _data);

    /**
     * @notice Converts from a WAD to normal value
     * @return Converted non-WAD value
     */
    function fromWad(int256 wad) external view returns (int256);

    /**
     * @notice Updates the underlying oracle state and returns the new price
     * @dev Spot oracles must implement but it will be a no-op
     */
    function poll() external returns (int256);
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
    function getRatio(uint256 _numerator, uint256 _denominator)
        public
        pure
        returns (bytes16)
    {
        // Catch the divide by zero error.
        if (_denominator == 0) {
            return 0;
        }
        return
            ABDKMathQuad.div(
                ABDKMathQuad.fromUInt(_numerator),
                ABDKMathQuad.fromUInt(_denominator)
            );
    }

    /**
     * @notice Multiplies two numbers
     * @param x The number to be multiplied by `y`
     * @param y The number to be multiplied by `x`
     */
    function multiplyBytes(bytes16 x, bytes16 y)
        external
        pure
        returns (bytes16)
    {
        return ABDKMathQuad.mul(x, y);
    }

    /**
     * @notice Performs a subtraction on two bytes16 numbers
     * @param x The number to be subtracted by `y`
     * @param y The number to subtract from `x`
     */
    function subtractBytes(bytes16 x, bytes16 y)
        external
        pure
        returns (bytes16)
    {
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

        uint256 shortFees = convertDecimalToUInt(
            multiplyDecimalByUInt(ratioShort, reward)
        );

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
    function convertUIntToDecimal(uint256 amount)
        external
        pure
        returns (bytes16)
    {
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
    function multiplyDecimalByUInt(bytes16 a, uint256 b)
        public
        pure
        returns (bytes16)
    {
        return ABDKMathQuad.mul(a, ABDKMathQuad.fromUInt(b));
    }

    /**
     * @notice Divides two unsigned integers
     * @param a The dividend
     * @param b The divisor
     * @return The quotient
     */
    function divUInt(uint256 a, uint256 b) private pure returns (bytes16) {
        return
            ABDKMathQuad.div(
                ABDKMathQuad.fromUInt(a),
                ABDKMathQuad.fromUInt(b)
            );
    }

    /**
     * @notice Divides two integers
     * @param a The dividend
     * @param b The divisor
     * @return The quotient
     */
    function divInt(int256 a, int256 b) public pure returns (bytes16) {
        return
            ABDKMathQuad.div(ABDKMathQuad.fromInt(a), ABDKMathQuad.fromInt(b));
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
        bytes16 multiplyResult = ABDKMathQuad.mul(
            ABDKMathQuad.fromUInt(number),
            ABDKMathQuad.fromUInt(numerator)
        );
        bytes16 result = ABDKMathQuad.div(
            multiplyResult,
            ABDKMathQuad.fromUInt(denominator)
        );
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
                ABDKMathQuad.mul(
                    leverage,
                    ABDKMathQuad.log_2(
                        direction < 0 ? ratio : ABDKMathQuad.div(ONE, ratio)
                    )
                )
            );
    }

    /**
     * @notice Calculates the amount to take from the losing pool
     * @param lossMultiplier The multiplier to use
     * @param balance The balance of the losing pool
     */
    function getLossAmount(bytes16 lossMultiplier, uint256 balance)
        public
        pure
        returns (uint256)
    {
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(
                    ABDKMathQuad.sub(ONE, lossMultiplier),
                    ABDKMathQuad.fromUInt(balance)
                )
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
        PriceChangeData memory priceChangeData = PoolSwapLibrary
            .PriceChangeData(
                oldPrice,
                newPrice,
                longBalance,
                shortBalance,
                leverageAmount,
                fee
            );
        // Calculate fees from long and short sides
        uint256 longFeeAmount = convertDecimalToUInt(
            multiplyDecimalByUInt(
                priceChangeData.fee,
                priceChangeData.longBalance
            )
        ) / PoolSwapLibrary.WAD_PRECISION;
        uint256 shortFeeAmount = convertDecimalToUInt(
            multiplyDecimalByUInt(
                priceChangeData.fee,
                priceChangeData.shortBalance
            )
        ) / PoolSwapLibrary.WAD_PRECISION;

        priceChangeData.shortBalance -= shortFeeAmount;
        priceChangeData.longBalance -= longFeeAmount;

        uint256 sumBeforePriceChange = priceChangeData.shortBalance +
            priceChangeData.longBalance;

        if (newPrice >= oldPrice && priceChangeData.shortBalance > 0) {
            // Price increased
            // Using the sigmoid function defined in the function's natspec, move funds from short side to long side
            bytes16 ratio = divInt(
                priceChangeData.oldPrice,
                priceChangeData.newPrice
            );
            bytes16 poolMultiplier = sigmoid(leverageAmount, ratio);

            priceChangeData.longBalance += ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(
                    ABDKMathQuad.fromUInt(priceChangeData.shortBalance),
                    poolMultiplier
                )
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
            bytes16 ratio = divInt(
                priceChangeData.newPrice,
                priceChangeData.oldPrice
            );
            bytes16 poolMultiplier = sigmoid(leverageAmount, ratio);

            priceChangeData.shortBalance += ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(
                    ABDKMathQuad.fromUInt(priceChangeData.longBalance),
                    poolMultiplier
                )
            );
            priceChangeData.longBalance = ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(
                    ABDKMathQuad.fromUInt(priceChangeData.longBalance),
                    ABDKMathQuad.sub(ONE, poolMultiplier)
                )
            );
        }

        if (
            sumBeforePriceChange >
            priceChangeData.longBalance + priceChangeData.shortBalance
        ) {
            // Move dust into winning side
            // This is only ever 1 wei (negligible)
            if (newPrice > oldPrice) {
                priceChangeData.longBalance +=
                    sumBeforePriceChange -
                    (priceChangeData.longBalance +
                        priceChangeData.shortBalance);
            } else {
                priceChangeData.shortBalance +=
                    sumBeforePriceChange -
                    (priceChangeData.longBalance +
                        priceChangeData.shortBalance);
            }
        }

        return (
            priceChangeData.longBalance,
            priceChangeData.shortBalance,
            longFeeAmount,
            shortFeeAmount
        );
    }

    /**
     * @notice Use a sigmoid function to determine the losing pool multiplier.
     * @return The losing pool multiplier, represented as an ABDKMathQuad IEEE754 quadruple-precision binary floating-point numbers
     * @dev The returned value is used in `calculateValueTransfer` as the portion to move from the losing side into the winning side
     */
    function sigmoid(bytes16 leverage, bytes16 ratio)
        private
        pure
        returns (bytes16)
    {
        /**
         * denominator = 1 + e ^ (-2 * leverage * (1 - ratio))
         */
        bytes16 denominator = ABDKMathQuad.mul(
            ABDKMathQuad.fromInt(-2),
            leverage
        );
        denominator = ABDKMathQuad.mul(
            denominator,
            ABDKMathQuad.sub(ONE, ratio)
        );
        denominator = ABDKMathQuad.add(ONE, ABDKMathQuad.exp(denominator));
        bytes16 numerator = ABDKMathQuad.add(ONE, ONE); // 2
        return
            ABDKMathQuad.sub((ABDKMathQuad.div(numerator, denominator)), ONE);
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
        return
            lastPriceTimestamp + updateInterval - frontRunningInterval >
            subjectTime;
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
            if (
                isBeforeFrontRunningInterval(
                    timestamp,
                    lastPriceTimestamp,
                    updateInterval,
                    frontRunningInterval
                )
            ) {
                // We are before the frontRunning interval
                return currentUpdateIntervalId;
            } else {
                // Floor of `timePassed / updateInterval` to get the number of intervals passed
                uint256 updateIntervalsPassed = (timestamp -
                    lastPriceTimestamp) / updateInterval;
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
            uint256 updateIntervals = (minimumTime - lastPriceTimestamp) /
                updateInterval;

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
        if (
            (balance == 0) ||
            (tokenSupply + pendingBurnPoolTokens == 0) ||
            (amountIn == 0)
        ) {
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
        if (
            balance == 0 ||
            tokenSupply + pendingBurnPoolTokens == 0 ||
            amountIn == 0
        ) {
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
    function getPrice(uint256 sideBalance, uint256 tokenSupply)
        external
        pure
        returns (bytes16)
    {
        if (tokenSupply == 0) {
            return ONE;
        }
        return
            ABDKMathQuad.div(
                ABDKMathQuad.fromUInt(sideBalance),
                ABDKMathQuad.fromUInt(tokenSupply)
            );
    }

    /**
     * @notice Calculates the number of pool tokens to mint, given some settlement token amount and a price
     * @param price Price of a pool token
     * @param amount Amount of settlement tokens being used to mint
     * @return Quantity of pool tokens to mint
     * @dev Throws if price is zero, or IEEE754 negative zero
     * @dev `getMint()`
     */
    function getMint(bytes16 price, uint256 amount)
        public
        pure
        returns (uint256)
    {
        require(price != 0, "price == 0");
        require(price != NEGATIVE_ZERO, "price == negative zero");
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.div(ABDKMathQuad.fromUInt(amount), price)
            );
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
    function getBurn(bytes16 price, uint256 amount)
        public
        pure
        returns (uint256)
    {
        require(price != 0, "price == 0");
        require(price != NEGATIVE_ZERO, "price == negative zero");
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.fromUInt(amount), price)
            );
    }

    /**
     * @notice Calculate the amount of settlement tokens to take as the minting fee
     * @param feeRate PoolCommitter's mintingFee or burningFee - The amount that is extracted from each mint or burn. Given as the decimal * 10 ^ 18. For example, 60% fee is 0.6 * 10 ^ 18 Fees can be 0.
     * @param amount The amount of settlement tokens being committed to mint
     */
    function mintingOrBurningFee(bytes16 feeRate, uint256 amount)
        public
        pure
        returns (uint256)
    {
        return
            ABDKMathQuad.toUInt(multiplyDecimalByUInt(feeRate, amount)) /
            WAD_PRECISION;
    }

    /**
     * @notice Converts from a WAD to normal value
     * @param _wadValue wad number
     * @param _decimals Quantity of decimal places to support
     * @return Converted (non-WAD) value
     */
    function fromWad(uint256 _wadValue, uint256 _decimals)
        external
        pure
        returns (uint256)
    {
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
    function getUpdatedAggregateBalance(UpdateData calldata data)
        external
        pure
        returns (UpdateResult memory)
    {
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
            (
                shortBurnLongMintResult,
                burnFeeSettlement,
                mintFeeSettlement
            ) = processBurnInstantMintCommit(
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
            longBurnShortMintResult = getBurn(
                data.longPrice,
                data.longBurnShortMintPoolTokens
            );
            // The burn fee taken from this burn. This should be given to the long side.
            uint256 burnFeeSettlement = mintingOrBurningFee(
                data.burnFee,
                longBurnShortMintResult
            );
            longBurnShortMintResult -= burnFeeSettlement;

            // The mint fee taken from the subsequent mint
            uint256 mintFeeSettlement = mintingOrBurningFee(
                data.mintingFeeRate,
                longBurnShortMintResult
            );
            longBurnShortMintResult -= mintFeeSettlement;

            result._longSettlementFee += burnFeeSettlement;
            result._shortSettlementFee += mintFeeSettlement;
        }

        /**
         * Calculate the new long tokens minted.
         * Use amount committed LongMint/ShortMint, as well as settlement tokens generated from ShortBurnLongMint/LongBurnShortMint commits.
         */
        if (data.longMintSettlement > 0 || shortBurnLongMintResult > 0) {
            result._newLongTokens += getMint(
                data.longPrice,
                data.longMintSettlement + shortBurnLongMintResult
            );
        }
        if (data.shortMintSettlement > 0 || longBurnShortMintResult > 0) {
            result._newShortTokens += getMint(
                data.shortPrice,
                data.shortMintSettlement + longBurnShortMintResult
            );
        }

        /**
         * Calculate the settlement tokens earned through LongBurn/ShortBurn commits.
         * Once this is calculated, take off the burn fee, and add to the respective side's fee amount.
         */
        if (data.longBurnPoolTokens > 0) {
            // Calculate the amount of settlement tokens earned from burning long tokens
            uint256 longBurnResult = getBurn(
                data.longPrice,
                data.longBurnPoolTokens
            );
            // Calculate the fee
            uint256 longBurnFee = mintingOrBurningFee(
                data.burnFee,
                longBurnResult
            );
            result._longSettlementFee += longBurnFee;
            // Subtract the fee from settlement token amount
            longBurnResult -= longBurnFee;
            result._newSettlementTokens += longBurnResult;
        }
        if (data.shortBurnPoolTokens > 0) {
            // Calculate the amount of settlement tokens earned from burning short tokens
            uint256 shortBurnResult = getBurn(
                data.shortPrice,
                data.shortBurnPoolTokens
            );
            // Calculate the fee
            uint256 shortBurnFee = mintingOrBurningFee(
                data.burnFee,
                shortBurnResult
            );
            result._shortSettlementFee += shortBurnFee;
            // Subtract the fee from settlement token amount
            shortBurnResult -= shortBurnFee;
            result._newSettlementTokens += shortBurnResult;
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
library StorageSlotUpgradeable {
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