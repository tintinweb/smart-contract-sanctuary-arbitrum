// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";

import "../utils/proxy/ProxyReentrancyGuard.sol";
import "../utils/proxy/ProxyOwned.sol";
import "../utils/proxy/ProxyPausable.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";

import "../interfaces/IEscrowThales.sol";
import "../interfaces/IStakingThales.sol";
import "../interfaces/ISNXRewards.sol";
import "../interfaces/IThalesRoyale.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IThalesStakingRewardsPool.sol";
import "../interfaces/IAddressResolver.sol";
import "../interfaces/ISportsAMMLiquidityPool.sol";
import "../interfaces/IThalesAMMLiquidityPool.sol";
import "../interfaces/IParlayAMMLiquidityPool.sol";
import "../interfaces/IThalesAMM.sol";
import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IStakingThalesBonusRewardsManager.sol";

/// @title A Staking contract that provides logic for staking and claiming rewards
contract StakingThales is IStakingThales, Initializable, ProxyOwned, ProxyReentrancyGuard, ProxyPausable {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IEscrowThales public iEscrowThales;
    IERC20 public stakingToken;
    IERC20 public feeToken;
    ISNXRewards public SNXRewards;
    IThalesRoyale public thalesRoyale;
    IPriceFeed public priceFeed;

    uint public periodsOfStaking;
    uint public lastPeriodTimeStamp;
    uint public durationPeriod;
    uint public unstakeDurationPeriod;
    uint public startTimeStamp;
    uint public currentPeriodRewards;
    uint public currentPeriodFees;
    bool public distributeFeesEnabled;
    uint public fixedPeriodReward;
    uint public periodExtraReward;
    uint public totalSNXRewardsInPeriod;
    uint public totalSNXFeesInPeriod;
    bool public claimEnabled;

    mapping(address => uint) public stakerLifetimeRewardsClaimed;
    mapping(address => uint) public stakerFeesClaimed;

    uint private _totalStakedAmount;
    uint private _totalEscrowedAmount;
    uint private _totalPendingStakeAmount;
    uint private _totalUnclaimedRewards;
    uint private _totalRewardsClaimed;
    uint private _totalRewardFeesClaimed;

    mapping(address => uint) public lastUnstakeTime;
    mapping(address => bool) public unstaking;
    mapping(address => uint) public unstakingAmount;
    mapping(address => uint) private _stakedBalances;
    mapping(address => uint) private _lastRewardsClaimedPeriod;
    address public thalesAMM;

    uint constant HUNDRED = 1e18;
    uint constant AMM_EXTRA_REWARD_PERIODS = 4;

    struct AMMVolumeEntry {
        uint amount;
        uint period;
    }
    mapping(address => uint) private lastAMMUpdatePeriod;
    mapping(address => AMMVolumeEntry[AMM_EXTRA_REWARD_PERIODS]) private stakerAMMVolume;

    bool public extraRewardsActive;
    IThalesStakingRewardsPool public ThalesStakingRewardsPool;

    uint public maxSNXRewardsPercentage;
    uint public maxAMMVolumeRewardsPercentage;
    uint public AMMVolumeRewardsMultiplier;
    uint public maxThalesRoyaleRewardsPercentage;

    uint constant ONE = 1e18;
    uint constant ONE_PERCENT = 1e16;

    uint public SNXVolumeRewardsMultiplier;

    mapping(address => uint) private _lastStakingPeriod;

    uint public totalStakedLastPeriodEnd;
    uint public totalEscrowedLastPeriodEnd;
    address public exoticBonds;

    IAddressResolver public addressResolver;

    address public thalesRangedAMM;
    address public sportsAMM;

    mapping(address => uint) private lastThalesAMMUpdatePeriod;
    mapping(address => AMMVolumeEntry[AMM_EXTRA_REWARD_PERIODS]) private thalesAMMVolume;
    mapping(address => uint) private lastThalesRangedAMMUpdatePeriod;
    mapping(address => AMMVolumeEntry[AMM_EXTRA_REWARD_PERIODS]) private thalesRangedAMMVolume;
    mapping(address => uint) private lastExoticMarketsUpdatePeriod;
    mapping(address => AMMVolumeEntry[AMM_EXTRA_REWARD_PERIODS]) private exoticMarketsVolume;
    mapping(address => uint) private lastSportsAMMUpdatePeriod;
    mapping(address => AMMVolumeEntry[AMM_EXTRA_REWARD_PERIODS]) private sportsAMMVolume;

    mapping(address => mapping(address => bool)) public canClaimOnBehalf;

    bool public mergeAccountEnabled;

    mapping(address => address) public delegatedVolume;
    mapping(address => bool) public supportedSportVault;
    mapping(address => bool) public supportedAMMVault;

    ISportsAMMLiquidityPool public sportsAMMLiquidityPool;
    IThalesAMMLiquidityPool public thalesAMMLiquidityPool;

    IStakingThalesBonusRewardsManager public stakingThalesBonusRewardsManager;
    IParlayAMMLiquidityPool public parlayAMMLiquidityPool;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _iEscrowThales, //THALES
        address _stakingToken, //THALES
        address _feeToken, //sUSD
        uint _durationPeriod,
        uint _unstakeDurationPeriod,
        address _ISNXRewards
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        iEscrowThales = IEscrowThales(_iEscrowThales);
        stakingToken = IERC20(_stakingToken);
        feeToken = IERC20(_feeToken);
        stakingToken.approve(_iEscrowThales, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        durationPeriod = _durationPeriod;
        unstakeDurationPeriod = _unstakeDurationPeriod;
        fixedPeriodReward = 70000 * 1e18;
        periodExtraReward = 21000 * 1e18;
        SNXRewards = ISNXRewards(_ISNXRewards);
    }

    /* ========== VIEWS ========== */

    /// @notice Get the total staked amount on the contract
    /// @return total staked amount
    function totalStakedAmount() external view returns (uint) {
        return _totalStakedAmount;
    }

    /// @notice Get the staked balance for the account
    /// @param account to get the staked balance for
    /// @return the staked balance for the account
    function stakedBalanceOf(address account) external view returns (uint) {
        return _stakedBalances[account];
    }

    /// @notice Get the last period of claimed rewards for the account
    /// @param account to get the last period of claimed rewards for
    /// @return the last period of claimed rewards for the account
    function getLastPeriodOfClaimedRewards(address account) external view returns (uint) {
        return _lastRewardsClaimedPeriod[account];
    }

    /// @notice Get the rewards available for the claim for the account
    /// @param account to get the rewards available for the claim for
    /// @return the rewards available for the claim for the account
    function getRewardsAvailable(address account) external view returns (uint) {
        return _calculateAvailableRewardsToClaim(account);
    }

    /// @notice Get the reward fees available for the claim for the account
    /// @param account to get the reward fees available for the claim for
    /// @return the rewards fees available for the claim for the account
    function getRewardFeesAvailable(address account) external view returns (uint) {
        return _calculateAvailableFeesToClaim(account);
    }

    /// @notice Get the total rewards claimed for the account until now
    /// @param account to get the total rewards claimed for
    /// @return the total rewards claimed for the account until now
    function getAlreadyClaimedRewards(address account) external view returns (uint) {
        return stakerLifetimeRewardsClaimed[account];
    }

    /// @notice Get the rewards funds available on the rewards pool
    /// @return the rewards funds available on the rewards pool
    function getContractRewardFunds() external view returns (uint) {
        return stakingToken.balanceOf(address(ThalesStakingRewardsPool));
    }

    /// @notice Get the fee funds available on the staking contract
    /// @return the fee funds available on the staking contract
    function getContractFeeFunds() external view returns (uint) {
        return feeToken.balanceOf(address(this));
    }

    /// @notice Set staking parametars
    /// @param _claimEnabled enable/disable claim rewards
    /// @param _distributeFeesEnabled enable/disable fees distribution
    /// @param _durationPeriod duration of the staking period
    /// @param _unstakeDurationPeriod duration of the unstaking cooldown period
    /// @param _mergeAccountEnabled enable/disable account merging
    function setStakingParameters(
        bool _claimEnabled,
        bool _distributeFeesEnabled,
        uint _durationPeriod,
        uint _unstakeDurationPeriod,
        bool _mergeAccountEnabled
    ) external onlyOwner {
        claimEnabled = _claimEnabled;
        distributeFeesEnabled = _distributeFeesEnabled;
        durationPeriod = _durationPeriod;
        unstakeDurationPeriod = _unstakeDurationPeriod;
        mergeAccountEnabled = _mergeAccountEnabled;

        emit StakingParametersChanged(
            _claimEnabled,
            _distributeFeesEnabled,
            _durationPeriod,
            _unstakeDurationPeriod,
            _mergeAccountEnabled
        );
    }

    /// @notice Set staking rewards parameters
    /// @param _fixedReward amount for weekly base rewards pool
    /// @param _extraReward amount for weekly bonus rewards pool
    /// @param _extraRewardsActive enable/disable bonus rewards
    /// @param _maxSNXRewardsPercentage maximum percentage for SNX rewards
    /// @param _maxAMMVolumeRewardsPercentage maximum percentage for protocol volume rewards
    /// @param _maxThalesRoyaleRewardsPercentage maximum percentage for rewards for participation in Thales Royale
    /// @param _SNXVolumeRewardsMultiplier multiplier for SNX rewards
    /// @param _AMMVolumeRewardsMultiplier multiplier for protocol volume rewards
    function setStakingRewardsParameters(
        uint _fixedReward,
        uint _extraReward,
        bool _extraRewardsActive,
        uint _maxSNXRewardsPercentage,
        uint _maxAMMVolumeRewardsPercentage,
        uint _maxThalesRoyaleRewardsPercentage,
        uint _SNXVolumeRewardsMultiplier,
        uint _AMMVolumeRewardsMultiplier
    ) public onlyOwner {
        fixedPeriodReward = _fixedReward;
        periodExtraReward = _extraReward;
        extraRewardsActive = _extraRewardsActive;
        maxSNXRewardsPercentage = _maxSNXRewardsPercentage;
        maxAMMVolumeRewardsPercentage = _maxAMMVolumeRewardsPercentage;
        maxThalesRoyaleRewardsPercentage = _maxThalesRoyaleRewardsPercentage;
        SNXVolumeRewardsMultiplier = _SNXVolumeRewardsMultiplier;
        AMMVolumeRewardsMultiplier = _AMMVolumeRewardsMultiplier;

        emit StakingRewardsParametersChanged(
            _fixedReward,
            _extraReward,
            _extraRewardsActive,
            _maxSNXRewardsPercentage,
            _maxAMMVolumeRewardsPercentage,
            _AMMVolumeRewardsMultiplier,
            _maxThalesRoyaleRewardsPercentage,
            _SNXVolumeRewardsMultiplier
        );
    }

    /// @notice Set contract addresses
    /// @param _snxRewards address of SNX rewards contract
    /// @param _thalesAMM address of Thales AMM contract
    /// @param _thalesRangedAMM address of Thales ranged AMM contract
    /// @param _sportsAMM address of sport markets AMM contract
    /// @param _priceFeed address of price feed contract
    /// @param _thalesStakingRewardsPool address of Thales staking rewards pool
    /// @param _addressResolver address of address resolver contract
    /// @param _sportsAMMLiquidityPool address of Sport AMM Liquidity Pool
    /// @param _thalesAMMLiquidityPool address of thales AMM Liquidity Pool
    /// @param _stakingThalesBonusRewardsManager manager for TIP-135 gamification systme
    function setAddresses(
        address _snxRewards,
        address _thalesAMM,
        address _thalesRangedAMM,
        address _sportsAMM,
        address _priceFeed,
        address _thalesStakingRewardsPool,
        address _addressResolver,
        address _sportsAMMLiquidityPool,
        address _thalesAMMLiquidityPool,
        address _parlayAMMLiquidityPool,
        address _stakingThalesBonusRewardsManager
    ) external onlyOwner {
        SNXRewards = ISNXRewards(_snxRewards);
        thalesAMM = _thalesAMM;
        thalesRangedAMM = _thalesRangedAMM;
        sportsAMM = _sportsAMM;
        priceFeed = IPriceFeed(_priceFeed);
        ThalesStakingRewardsPool = IThalesStakingRewardsPool(_thalesStakingRewardsPool);
        addressResolver = IAddressResolver(_addressResolver);
        sportsAMMLiquidityPool = ISportsAMMLiquidityPool(_sportsAMMLiquidityPool);
        thalesAMMLiquidityPool = IThalesAMMLiquidityPool(_thalesAMMLiquidityPool);
        parlayAMMLiquidityPool = IParlayAMMLiquidityPool(_parlayAMMLiquidityPool);
        stakingThalesBonusRewardsManager = IStakingThalesBonusRewardsManager(_stakingThalesBonusRewardsManager);
        emit AddressesChanged(
            _snxRewards,
            _thalesAMM,
            _thalesRangedAMM,
            _sportsAMM,
            _priceFeed,
            _thalesStakingRewardsPool,
            _addressResolver,
            _sportsAMMLiquidityPool,
            _thalesAMMLiquidityPool,
            _parlayAMMLiquidityPool,
            _stakingThalesBonusRewardsManager
        );
    }

    /// @notice Set address of Escrow Thales contract
    /// @param _escrowThalesContract address of Escrow Thales contract
    function setEscrow(address _escrowThalesContract) external onlyOwner {
        if (address(iEscrowThales) != address(0)) {
            stakingToken.approve(address(iEscrowThales), 0);
        }
        iEscrowThales = IEscrowThales(_escrowThalesContract);
        stakingToken.approve(_escrowThalesContract, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        emit EscrowChanged(_escrowThalesContract);
    }

    /// @notice add a sport vault address to count towards gamified staking volume
    /// @param _sportVault address to set
    /// @param value to set
    function setSupportedSportVault(address _sportVault, bool value) external onlyOwner {
        supportedSportVault[_sportVault] = value;
        emit SupportedSportVaultSet(_sportVault, value);
    }

    /// @notice add a amm vault address to count towards gamified staking volume
    /// @param _ammVault address to set
    /// @param value to set
    function setSupportedAMMVault(address _ammVault, bool value) external onlyOwner {
        supportedAMMVault[_ammVault] = value;
        emit SupportedAMMVaultSet(_ammVault, value);
    }

    /// @notice Get the address of the SNX rewards contract
    /// @return the address of the SNX rewards contract
    function getSNXRewardsAddress() public view returns (address) {
        if (address(addressResolver) == address(0)) {
            return address(0);
        } else {
            return addressResolver.getAddress("Issuer");
        }
    }

    /// @notice Get the amount of SNX staked for the account
    /// @param account to get the amount of SNX staked for
    /// @return the amount of SNX staked for the account
    function getSNXStaked(address account) external view returns (uint) {
        return _getSNXStakedForAccount(account);
    }

    /// @notice Get the base reward amount available for the claim for the account
    /// @param account to get the base reward amount available for the claim for
    /// @return the base reward amount available for the claim for the account
    function getBaseReward(address account) public view returns (uint _baseRewards) {
        if (
            !((_lastStakingPeriod[account] == periodsOfStaking) ||
                (_stakedBalances[account] == 0) ||
                (_lastRewardsClaimedPeriod[account] == periodsOfStaking) ||
                (totalStakedLastPeriodEnd == 0))
        ) {
            _baseRewards = _stakedBalances[account]
                .add(iEscrowThales.getStakedEscrowedBalanceForRewards(account))
                .mul(currentPeriodRewards)
                .div(totalStakedLastPeriodEnd.add(totalEscrowedLastPeriodEnd));
        }
    }

    /// @notice Get the total protocol volume for the account
    /// @param account to get the total protocol volume for
    /// @return the total protocol volume for the account
    function getAMMVolume(address account) external view returns (uint) {
        return _getTotalAMMVolume(account);
    }

    /// @notice Get the AMM volume for the account
    /// @param account to get the AMM volume for
    /// @return the AMM volume for the account
    function getThalesAMMVolume(address account) external view returns (uint volumeforAccount) {
        for (uint i = 0; i < AMM_EXTRA_REWARD_PERIODS; i++) {
            if (periodsOfStaking < thalesAMMVolume[account][i].period.add(AMM_EXTRA_REWARD_PERIODS))
                volumeforAccount = volumeforAccount.add(thalesAMMVolume[account][i].amount);
        }
    }

    /// @notice Get the ranged AMM volume for the account
    /// @param account to get the ranged AMM volume for
    /// @return the ranged AMM volume for the account
    function getThalesRangedAMMVolume(address account) external view returns (uint volumeforAccount) {
        for (uint i = 0; i < AMM_EXTRA_REWARD_PERIODS; i++) {
            if (periodsOfStaking < thalesRangedAMMVolume[account][i].period.add(AMM_EXTRA_REWARD_PERIODS))
                volumeforAccount = volumeforAccount.add(thalesRangedAMMVolume[account][i].amount);
        }
    }

    /// @notice Get the exotic markets volume for the account
    /// @param account to get exotic markets volume for
    /// @return the exotic markets volume for the account
    function getExoticMarketsVolume(address account) external view returns (uint volumeforAccount) {
        for (uint i = 0; i < AMM_EXTRA_REWARD_PERIODS; i++) {
            if (periodsOfStaking < exoticMarketsVolume[account][i].period.add(AMM_EXTRA_REWARD_PERIODS))
                volumeforAccount = volumeforAccount.add(exoticMarketsVolume[account][i].amount);
        }
    }

    /// @notice Get the sport markets AMM volume for the account
    /// @param account to get the sport markets AMM volume for
    /// @return the sport markets AMM volume for the account
    function getSportsAMMVolume(address account) external view returns (uint volumeforAccount) {
        for (uint i = 0; i < AMM_EXTRA_REWARD_PERIODS; i++) {
            if (periodsOfStaking < sportsAMMVolume[account][i].period.add(AMM_EXTRA_REWARD_PERIODS))
                volumeforAccount = volumeforAccount.add(sportsAMMVolume[account][i].amount);
        }
    }

    /// @notice Get the percentage of SNX rewards for the account
    /// @param account to get the percentage of SNX rewards for
    /// @return the percentage of SNX rewards for the account
    function getSNXBonusPercentage(address account) public view returns (uint) {
        uint baseReward = getBaseReward(account);
        if (baseReward == 0) {
            return 0;
        }
        uint stakedSNX = _getSNXStakedForAccount(account);
        // SNX staked more than base reward
        return
            stakedSNX >= baseReward.mul(SNXVolumeRewardsMultiplier)
                ? maxSNXRewardsPercentage.mul(ONE_PERCENT)
                : stakedSNX.mul(maxSNXRewardsPercentage).mul(ONE_PERCENT).div(baseReward.mul(SNXVolumeRewardsMultiplier));
    }

    /// @notice Get the SNX staking bonus rewards for the account
    /// @param account to get the SNX staking bonus rewards for
    /// @return the SNX staking bonus rewards for the account
    function getSNXBonus(address account) public view returns (uint) {
        uint baseReward = getBaseReward(account);
        uint SNXBonusPercentage = getSNXBonusPercentage(account);

        return baseReward.mul(SNXBonusPercentage).div(ONE);
    }

    /// @notice Get the percentage of protocol volume rewards for the account
    /// @param account to get the percentage of protocol volume rewards for
    /// @return the percentage of protocol volume rewards for the account
    function getAMMBonusPercentage(address account) public view returns (uint) {
        uint baseReward = getBaseReward(account);
        if (baseReward == 0) {
            return 0;
        }
        return
            _getTotalAMMVolume(account) >= baseReward.mul(AMMVolumeRewardsMultiplier)
                ? maxAMMVolumeRewardsPercentage.mul(ONE_PERCENT)
                : _getTotalAMMVolume(account).mul(ONE_PERCENT).mul(maxAMMVolumeRewardsPercentage).div(
                    baseReward.mul(AMMVolumeRewardsMultiplier)
                );
    }

    /// @notice Get the protocol volume bonus rewards for the account
    /// @param account to get the protocol volume bonus rewards for
    /// @return the protocol volume bonus rewards for the account
    function getAMMBonus(address account) public view returns (uint) {
        uint baseReward = getBaseReward(account);
        uint AMMPercentage = getAMMBonusPercentage(account);
        return baseReward.mul(AMMPercentage).div(ONE);
    }

    function getTotalBonusPercentage(address account) public view returns (uint) {
        uint snxPercentage = getSNXBonusPercentage(account);
        uint ammPercentage = getAMMBonusPercentage(account);
        return snxPercentage.add(ammPercentage);
    }

    /// @notice Get the total bonus rewards for the account
    /// @param account to get the total bonus rewards for
    /// @return the total bonus rewards for the account
    function getTotalBonus(address account) public view returns (uint) {
        if (
            (address(stakingThalesBonusRewardsManager) != address(0)) && stakingThalesBonusRewardsManager.useNewBonusModel()
        ) {
            return
                periodExtraReward
                    .mul(stakingThalesBonusRewardsManager.getUserRoundBonusShare(account, periodsOfStaking - 1))
                    .div(ONE);
        } else {
            uint baseReward = getBaseReward(account);
            uint totalBonusPercentage = getTotalBonusPercentage(account);
            // failsafe
            require(totalBonusPercentage < ONE, "Bonus Exceeds base rewards");
            return baseReward.mul(totalBonusPercentage).div(ONE);
        }
    }

    /// @notice Get the flag that indicates whether the current period can be closed
    /// @return the flag that indicates whether the current period can be closed
    function canClosePeriod() external view returns (bool) {
        return (startTimeStamp > 0 && (block.timestamp >= lastPeriodTimeStamp.add(durationPeriod)));
    }

    /// @notice Get the current SNX target ratio
    /// @return the current SNX target ratio
    function getSNXTargetRatio() public view returns (uint) {
        uint hund = 100 * 100 * 1e18;
        return hund.div(ISNXRewards(getSNXRewardsAddress()).issuanceRatio());
    }

    /// @notice Get the current SNX C-Ratio for the account
    /// @param account to get the current SNX C-Ratio for
    /// @return the current SNX C-Ratio for the account
    function getCRatio(address account) public view returns (uint) {
        uint debt = ISNXRewards(getSNXRewardsAddress()).debtBalanceOf(account, "sUSD");
        if (debt == 0) {
            return 0;
        }
        uint hund = 100 * 100 * 1e18;
        (uint cRatio, ) = ISNXRewards(getSNXRewardsAddress()).collateralisationRatioAndAnyRatesInvalid(account);
        return hund.div(cRatio);
    }

    /// @notice Get the current SNX rate
    /// @return the current SNX rate
    function getSNXRateForCurrency() public view returns (uint) {
        return priceFeed.rateForCurrency("SNX");
    }

    /// @notice Get the current SNX debt for the account
    /// @param account to get the current SNX debt for
    /// @return the current SNX debt for the account
    function getSNXDebt(address account) public view returns (uint) {
        return ISNXRewards(getSNXRewardsAddress()).debtBalanceOf(account, "sUSD");
    }

    /* ========== PUBLIC ========== */

    /// @notice Start the first staking period
    function startStakingPeriod() external onlyOwner {
        require(startTimeStamp == 0, "Staking has already started");
        startTimeStamp = block.timestamp;
        periodsOfStaking = 0;
        lastPeriodTimeStamp = startTimeStamp;
        _totalUnclaimedRewards = 0;
        _totalRewardsClaimed = 0;
        _totalRewardFeesClaimed = 0;
        _totalStakedAmount = 0;
        _totalEscrowedAmount = 0;
        _totalPendingStakeAmount = 0;
        emit StakingPeriodStarted();
    }

    /// @notice Close the current staking period
    function closePeriod() external nonReentrant notPaused {
        require(startTimeStamp > 0, "Staking period has not started");
        require(
            block.timestamp >= lastPeriodTimeStamp.add(durationPeriod),
            "A full period has not passed since the last closed period"
        );

        iEscrowThales.updateCurrentPeriod();
        lastPeriodTimeStamp = block.timestamp;
        periodsOfStaking = iEscrowThales.currentVestingPeriod();

        _totalEscrowedAmount = iEscrowThales.totalEscrowedRewards().sub(
            iEscrowThales.totalEscrowBalanceNotIncludedInStaking()
        );

        //Actions taken on every closed period
        currentPeriodRewards = fixedPeriodReward;
        _totalUnclaimedRewards = _totalUnclaimedRewards.add(currentPeriodRewards.add(periodExtraReward));

        currentPeriodFees = feeToken.balanceOf(address(this));

        totalStakedLastPeriodEnd = _totalStakedAmount;
        totalEscrowedLastPeriodEnd = _totalEscrowedAmount;

        emit ClosedPeriod(periodsOfStaking, lastPeriodTimeStamp);
    }

    /// @notice Stake the amount of staking token to get weekly rewards
    /// @param amount to stake
    function stake(uint amount) external nonReentrant notPaused {
        _stake(amount, msg.sender, msg.sender);
        emit Staked(msg.sender, amount);
    }

    /// @notice Start unstaking cooldown for the amount of staking token
    /// @param amount to unstake
    function startUnstake(uint amount) external notPaused {
        require(amount > 0, "Cannot unstake 0");
        require(_stakedBalances[msg.sender] >= amount, "Account doesnt have that much staked");
        require(!unstaking[msg.sender], "Account has already triggered unstake cooldown");

        if (address(sportsAMMLiquidityPool) != address(0)) {
            require(!sportsAMMLiquidityPool.isUserLPing(msg.sender), "Cannot unstake while LPing");
        }

        if (address(thalesAMMLiquidityPool) != address(0)) {
            require(!thalesAMMLiquidityPool.isUserLPing(msg.sender), "Cannot unstake while LPing");
        }

        if (address(parlayAMMLiquidityPool) != address(0)) {
            require(!parlayAMMLiquidityPool.isUserLPing(msg.sender), "Cannot unstake while LPing");
        }

        if (_calculateAvailableRewardsToClaim(msg.sender) > 0) {
            _claimReward(msg.sender);
        }
        lastUnstakeTime[msg.sender] = block.timestamp;
        unstaking[msg.sender] = true;
        _totalStakedAmount = _totalStakedAmount.sub(amount);
        unstakingAmount[msg.sender] = amount;
        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].sub(amount);

        // on full unstake add his escrowed balance to totalEscrowBalanceNotIncludedInStaking
        if (_stakedBalances[msg.sender] == 0) {
            if (iEscrowThales.totalAccountEscrowedAmount(msg.sender) > 0) {
                iEscrowThales.addTotalEscrowBalanceNotIncludedInStaking(
                    iEscrowThales.totalAccountEscrowedAmount(msg.sender)
                );
            }
        }

        emit UnstakeCooldown(msg.sender, lastUnstakeTime[msg.sender].add(unstakeDurationPeriod), amount);
    }

    /// @notice Cancel unstaking cooldown
    function cancelUnstake() external notPaused {
        require(unstaking[msg.sender], "Account is not unstaking");

        // on revert full unstake remove his escrowed balance from totalEscrowBalanceNotIncludedInStaking
        _subtractTotalEscrowBalanceNotIncludedInStaking(msg.sender);

        if (_calculateAvailableRewardsToClaim(msg.sender) > 0) {
            _claimReward(msg.sender);
        }

        unstaking[msg.sender] = false;
        _totalStakedAmount = _totalStakedAmount.add(unstakingAmount[msg.sender]);
        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].add(unstakingAmount[msg.sender]);
        unstakingAmount[msg.sender] = 0;

        emit CancelUnstake(msg.sender);
    }

    /// @notice Unstake after the cooldown period expired
    function unstake() external notPaused {
        require(unstaking[msg.sender], "Account has not triggered unstake cooldown");
        require(
            lastUnstakeTime[msg.sender] < block.timestamp.sub(unstakeDurationPeriod),
            "Cannot unstake yet, cooldown not expired."
        );
        unstaking[msg.sender] = false;
        uint unstakeAmount = unstakingAmount[msg.sender];
        stakingToken.safeTransfer(msg.sender, unstakeAmount);
        unstakingAmount[msg.sender] = 0;
        emit Unstaked(msg.sender, unstakeAmount);
    }

    /// @notice Claim the weekly staking rewards
    function claimReward() public nonReentrant notPaused {
        _claimReward(msg.sender);
    }

    /// @notice Claim the weekly staking rewards on behalf of the account
    /// @param account to claim on behalf of
    function claimRewardOnBehalf(address account) public nonReentrant notPaused {
        require(account != address(0) && account != msg.sender, "Invalid address");
        require(canClaimOnBehalf[account][msg.sender], "Cannot claim on behalf");
        _claimReward(account);
    }

    /// @notice Update the protocol volume for the account
    /// @param account to update the protocol volume for
    /// @param amount to add to the existing protocol volume
    function updateVolume(address account, uint amount) external {
        require(account != address(0) && amount > 0, "Invalid params");
        if (delegatedVolume[account] != address(0)) {
            account = delegatedVolume[account];
        }

        require(
            msg.sender == thalesAMM ||
                msg.sender == exoticBonds ||
                msg.sender == thalesRangedAMM ||
                msg.sender == sportsAMM ||
                supportedSportVault[msg.sender] ||
                supportedAMMVault[msg.sender],
            "Invalid address"
        );
        amount = IPositionalMarketManager(IThalesAMM(sportsAMM).manager()).reverseTransformCollateral(amount);
        if (lastAMMUpdatePeriod[account] < periodsOfStaking) {
            stakerAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount = 0;
            stakerAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].period = periodsOfStaking;
            lastAMMUpdatePeriod[account] = periodsOfStaking;
        }
        stakerAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount = stakerAMMVolume[account][
            periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)
        ].amount.add(amount);

        if (msg.sender == thalesAMM || supportedAMMVault[msg.sender]) {
            if (lastThalesAMMUpdatePeriod[account] < periodsOfStaking) {
                thalesAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount = 0;
                thalesAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].period = periodsOfStaking;
                lastThalesAMMUpdatePeriod[account] = periodsOfStaking;
            }
            thalesAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount = thalesAMMVolume[account][
                periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)
            ].amount.add(amount);
        }

        if (msg.sender == thalesRangedAMM) {
            if (lastThalesRangedAMMUpdatePeriod[account] < periodsOfStaking) {
                thalesRangedAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount = 0;
                thalesRangedAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].period = periodsOfStaking;
                lastThalesRangedAMMUpdatePeriod[account] = periodsOfStaking;
            }
            thalesRangedAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount = thalesRangedAMMVolume[
                account
            ][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount.add(amount);
        }

        if (msg.sender == sportsAMM || supportedSportVault[msg.sender]) {
            if (lastSportsAMMUpdatePeriod[account] < periodsOfStaking) {
                sportsAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount = 0;
                sportsAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].period = periodsOfStaking;
                lastSportsAMMUpdatePeriod[account] = periodsOfStaking;
            }
            sportsAMMVolume[account][periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)].amount = sportsAMMVolume[account][
                periodsOfStaking.mod(AMM_EXTRA_REWARD_PERIODS)
            ].amount.add(amount);
        }

        if (address(stakingThalesBonusRewardsManager) != address(0)) {
            stakingThalesBonusRewardsManager.storePoints(account, msg.sender, amount, periodsOfStaking);
        }

        emit AMMVolumeUpdated(account, amount, msg.sender);
    }

    /// @notice Merge account to transfer all staking amounts to another account
    /// @param destAccount to merge into
    function mergeAccount(address destAccount) external notPaused {
        require(mergeAccountEnabled, "Merge account is disabled");
        require(destAccount != address(0) && destAccount != msg.sender, "Invalid address");
        require(
            _calculateAvailableRewardsToClaim(msg.sender) == 0 && _calculateAvailableRewardsToClaim(destAccount) == 0,
            "Cannot merge, claim rewards on both accounts before merging"
        );
        require(
            !unstaking[msg.sender] && !unstaking[destAccount],
            "Cannot merge, cancel unstaking on both accounts before merging"
        );

        if (address(sportsAMMLiquidityPool) != address(0)) {
            require(!sportsAMMLiquidityPool.isUserLPing(msg.sender), "Cannot merge while LPing");
        }

        if (address(thalesAMMLiquidityPool) != address(0)) {
            require(!thalesAMMLiquidityPool.isUserLPing(msg.sender), "Cannot merge while LPing");
        }

        if (address(parlayAMMLiquidityPool) != address(0)) {
            require(!parlayAMMLiquidityPool.isUserLPing(msg.sender), "Cannot merge while LPing");
        }

        iEscrowThales.mergeAccount(msg.sender, destAccount);

        _stakedBalances[destAccount] = _stakedBalances[destAccount].add(_stakedBalances[msg.sender]);
        stakerLifetimeRewardsClaimed[destAccount] = stakerLifetimeRewardsClaimed[destAccount].add(
            stakerLifetimeRewardsClaimed[msg.sender]
        );
        stakerFeesClaimed[destAccount] = stakerFeesClaimed[destAccount].add(stakerFeesClaimed[msg.sender]);

        _lastRewardsClaimedPeriod[destAccount] = periodsOfStaking;
        _lastStakingPeriod[destAccount] = periodsOfStaking;
        lastAMMUpdatePeriod[destAccount] = periodsOfStaking;

        uint stakerAMMVolumeIndex;
        uint stakerAMMVolumePeriod;
        for (uint i = 1; i <= AMM_EXTRA_REWARD_PERIODS; i++) {
            stakerAMMVolumeIndex = periodsOfStaking.add(i).mod(AMM_EXTRA_REWARD_PERIODS);
            stakerAMMVolumePeriod = periodsOfStaking.sub(AMM_EXTRA_REWARD_PERIODS.sub(i));

            if (stakerAMMVolumePeriod != stakerAMMVolume[destAccount][stakerAMMVolumeIndex].period) {
                stakerAMMVolume[destAccount][stakerAMMVolumeIndex].amount = 0;
                stakerAMMVolume[destAccount][stakerAMMVolumeIndex].period = stakerAMMVolumePeriod;
            }

            if (stakerAMMVolumePeriod == stakerAMMVolume[msg.sender][stakerAMMVolumeIndex].period) {
                stakerAMMVolume[destAccount][stakerAMMVolumeIndex].amount = stakerAMMVolume[destAccount][
                    stakerAMMVolumeIndex
                ].amount.add(stakerAMMVolume[msg.sender][stakerAMMVolumeIndex].amount);
            }
        }

        delete lastUnstakeTime[msg.sender];
        delete unstaking[msg.sender];
        delete unstakingAmount[msg.sender];
        delete _stakedBalances[msg.sender];
        delete stakerLifetimeRewardsClaimed[msg.sender];
        delete stakerFeesClaimed[msg.sender];
        delete _lastRewardsClaimedPeriod[msg.sender];
        delete _lastStakingPeriod[msg.sender];
        delete lastAMMUpdatePeriod[msg.sender];
        delete stakerAMMVolume[msg.sender];

        emit AccountMerged(msg.sender, destAccount);
    }

    /// @notice Set flag to enable/disable claim on behalf of the msg.sender for the account
    /// @param account to enable/disable claim on behalf of msg.sender
    /// @param _canClaimOnBehalf enable/disable claim on behalf of the msg.sender for the account
    function setCanClaimOnBehalf(address account, bool _canClaimOnBehalf) external notPaused {
        require(account != address(0) && account != msg.sender, "Invalid address");
        canClaimOnBehalf[msg.sender][account] = _canClaimOnBehalf;
        emit CanClaimOnBehalfChanged(msg.sender, account, _canClaimOnBehalf);
    }

    /// @notice delegate your volume to another address
    /// @param account address to delegate to
    function delegateVolume(address account) external notPaused {
        delegatedVolume[msg.sender] = account;
        emit DelegatedVolume(account);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _claimReward(address account) internal notPaused {
        require(claimEnabled, "Claiming is not enabled.");
        require(startTimeStamp > 0, "Staking period has not started");

        //Calculate rewards
        if (distributeFeesEnabled) {
            uint availableFeesToClaim = _calculateAvailableFeesToClaim(account);
            if (availableFeesToClaim > 0) {
                feeToken.safeTransfer(account, availableFeesToClaim);
                stakerFeesClaimed[account] = stakerFeesClaimed[account].add(availableFeesToClaim);
                _totalRewardFeesClaimed = _totalRewardFeesClaimed.add(availableFeesToClaim);
                emit FeeRewardsClaimed(account, availableFeesToClaim);
            }
        }
        uint availableRewardsToClaim = _calculateAvailableRewardsToClaim(account);
        if (availableRewardsToClaim > 0) {
            // Transfer THALES to Escrow contract
            ThalesStakingRewardsPool.addToEscrow(account, availableRewardsToClaim);
            // Record the total claimed rewards
            stakerLifetimeRewardsClaimed[account] = stakerLifetimeRewardsClaimed[account].add(availableRewardsToClaim);
            _totalRewardsClaimed = _totalRewardsClaimed.add(availableRewardsToClaim);
            _totalUnclaimedRewards = _totalUnclaimedRewards.sub(availableRewardsToClaim);

            emit RewardsClaimed(
                account,
                availableRewardsToClaim,
                getBaseReward(account),
                getSNXBonus(account),
                getAMMBonus(account)
            );
        }
        // Update last claiming period
        _lastRewardsClaimedPeriod[account] = periodsOfStaking;
    }

    function _stake(
        uint amount,
        address staker,
        address sender
    ) internal {
        require(startTimeStamp > 0, "Staking period has not started");
        require(amount > 0, "Cannot stake 0");
        require(!unstaking[staker], "The staker is paused from staking due to unstaking");
        // Check if there are not claimable rewards from last period.
        // Claim them, and add new stake
        if (_calculateAvailableRewardsToClaim(staker) > 0) {
            _claimReward(staker);
        }
        _lastStakingPeriod[staker] = periodsOfStaking;

        // if just started staking subtract his escrowed balance from totalEscrowBalanceNotIncludedInStaking
        _subtractTotalEscrowBalanceNotIncludedInStaking(staker);

        _totalStakedAmount = _totalStakedAmount.add(amount);
        _stakedBalances[staker] = _stakedBalances[staker].add(amount);
        stakingToken.safeTransferFrom(sender, address(this), amount);
    }

    function _subtractTotalEscrowBalanceNotIncludedInStaking(address account) internal {
        if (_stakedBalances[account] == 0) {
            if (iEscrowThales.totalAccountEscrowedAmount(account) > 0) {
                iEscrowThales.subtractTotalEscrowBalanceNotIncludedInStaking(
                    iEscrowThales.totalAccountEscrowedAmount(account)
                );
            }
        }
    }

    function _calculateAvailableRewardsToClaim(address account) internal view returns (uint) {
        uint baseReward = getBaseReward(account);
        if (baseReward == 0) {
            return 0;
        }
        if (!extraRewardsActive) {
            return baseReward;
        } else {
            return baseReward.add(getTotalBonus(account));
        }
    }

    function _calculateAvailableFeesToClaim(address account) internal view returns (uint) {
        uint baseReward = getBaseReward(account);
        if (baseReward == 0) {
            return 0;
        }

        return
            _stakedBalances[account]
                .add(iEscrowThales.getStakedEscrowedBalanceForRewards(account))
                .mul(currentPeriodFees)
                .div(totalStakedLastPeriodEnd.add(totalEscrowedLastPeriodEnd));
    }

    function _getSNXStakedForAccount(address account) internal view returns (uint snxStaked) {
        if (address(addressResolver) != address(0)) {
            uint cRatio = getCRatio(account);
            uint targetRatio = getSNXTargetRatio();
            uint snxPrice = priceFeed.rateForCurrency("SNX");
            uint debt = ISNXRewards(getSNXRewardsAddress()).debtBalanceOf(account, "sUSD");
            if (cRatio < targetRatio) {
                snxStaked = (cRatio.mul(cRatio).mul(debt).mul(1e14)).div(targetRatio.mul(snxPrice));
            } else {
                snxStaked = (targetRatio.mul(debt).mul(1e14)).div(snxPrice);
            }
        }
    }

    function _getTotalAMMVolume(address account) internal view returns (uint totalAMMforAccount) {
        if (!(periodsOfStaking >= lastAMMUpdatePeriod[account].add(AMM_EXTRA_REWARD_PERIODS))) {
            for (uint i = 0; i < AMM_EXTRA_REWARD_PERIODS; i++) {
                if (periodsOfStaking < stakerAMMVolume[account][i].period.add(AMM_EXTRA_REWARD_PERIODS))
                    totalAMMforAccount = totalAMMforAccount.add(stakerAMMVolume[account][i].amount);
            }
        }
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint reward);
    event Staked(address user, uint amount);
    event StakedOnBehalf(address user, address staker, uint amount);
    event ClosedPeriod(uint PeriodOfStaking, uint lastPeriodTimeStamp);
    event RewardsClaimed(address account, uint unclaimedReward, uint baseRewards, uint snxBonus, uint protocolBonus);
    event FeeRewardsClaimed(address account, uint unclaimedFees);
    event UnstakeCooldown(address account, uint cooldownTime, uint amount);
    event CancelUnstake(address account);
    event Unstaked(address account, uint unstakeAmount);
    event StakingParametersChanged(
        bool claimEnabled,
        bool distributeFeesEnabled,
        uint durationPeriod,
        uint unstakeDurationPeriod,
        bool mergeAccountEnabled
    );
    event StakingRewardsParametersChanged(
        uint fixedPeriodReward,
        uint periodExtraReward,
        bool extraRewardsActive,
        uint maxSNXRewardsPercentage,
        uint maxAMMVolumeRewardsPercentage,
        uint maxThalesRoyaleRewardsPercentage,
        uint SNXVolumeRewardsMultiplier,
        uint AMMVolumeRewardsMultiplier
    );
    event AddressesChanged(
        address SNXRewards,
        address thalesAMM,
        address thalesRangedAMM,
        address sportsAMM,
        address priceFeed,
        address ThalesStakingRewardsPool,
        address addressResolver,
        address sportsAMMLiquidityPool,
        address thalesAMMLiquidityPool,
        address parlayAMMLiquidityPool,
        address stakingThalesBonusRewardsManager
    );
    event EscrowChanged(address newEscrow);
    event StakingPeriodStarted();
    event AMMVolumeUpdated(address account, uint amount, address source);
    event AccountMerged(address srcAccount, address destAccount);
    event DelegatedVolume(address destAccount);
    event CanClaimOnBehalfChanged(address sender, address account, bool canClaimOnBehalf);
    event SupportedAMMVaultSet(address vault, bool value);
    event SupportedSportVaultSet(address vault, bool value);
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

// Inheritance
import "./ProxyOwned.sol";

// Clone of syntetix contract without constructor

contract ProxyPausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IEscrowThales {
    /* ========== VIEWS / VARIABLES ========== */
    function getStakerPeriod(address account, uint index) external view returns (uint);

    function getStakerAmounts(address account, uint index) external view returns (uint);

    function totalAccountEscrowedAmount(address account) external view returns (uint);

    function getStakedEscrowedBalanceForRewards(address account) external view returns (uint);

    function totalEscrowedRewards() external view returns (uint);

    function totalEscrowBalanceNotIncludedInStaking() external view returns (uint);

    function currentVestingPeriod() external view returns (uint);

    function updateCurrentPeriod() external returns (bool);

    function claimable(address account) external view returns (uint);

    function addToEscrow(address account, uint amount) external;

    function vest(uint amount) external returns (bool);

    function addTotalEscrowBalanceNotIncludedInStaking(uint amount) external;

    function subtractTotalEscrowBalanceNotIncludedInStaking(uint amount) external;

    function mergeAccount(address srcAccount, address destAccount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IStakingThales {
    function updateVolume(address account, uint amount) external;

    /* ========== VIEWS / VARIABLES ==========  */
    function totalStakedAmount() external view returns (uint);

    function stakedBalanceOf(address account) external view returns (uint);

    function currentPeriodRewards() external view returns (uint);

    function currentPeriodFees() external view returns (uint);

    function getLastPeriodOfClaimedRewards(address account) external view returns (uint);

    function getRewardsAvailable(address account) external view returns (uint);

    function getRewardFeesAvailable(address account) external view returns (uint);

    function getAlreadyClaimedRewards(address account) external view returns (uint);

    function getContractRewardFunds() external view returns (uint);

    function getContractFeeFunds() external view returns (uint);

    function getAMMVolume(address account) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface ISNXRewards {
    /* ========== VIEWS / VARIABLES ========== */
    function collateralisationRatioAndAnyRatesInvalid(address account) external view returns (uint, bool);

    function debtBalanceOf(address _issuer, bytes32 currencyKey) external view returns (uint);

    function issuanceRatio() external view returns (uint);

    function setCRatio(address account, uint _c_ratio) external;

    function setIssuanceRatio(uint _issuanceRation) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;
import "../interfaces/IPassportPosition.sol";

interface IThalesRoyale {
    /* ========== VIEWS / VARIABLES ========== */
    function getBuyInAmount() external view returns (uint);

    function season() external view returns (uint);

    function tokenSeason(uint tokenId) external view returns (uint);

    function seasonFinished(uint _season) external view returns (bool);

    function roundInASeason(uint _round) external view returns (uint);

    function roundResultPerSeason(uint _season, uint round) external view returns (uint);

    function isTokenAliveInASpecificSeason(uint tokenId, uint _season) external view returns (bool);

    function hasParticipatedInCurrentOrLastRoyale(address _player) external view returns (bool);

    function getTokenPositions(uint tokenId) external view returns (IPassportPosition.Position[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPriceFeed {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IThalesStakingRewardsPool {
    function addToEscrow(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IAddressResolver {
    /* ========== VIEWS / VARIABLES ========== */
    function getAddress(bytes32 name) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface ISportsAMMLiquidityPool {
    /* ========== VIEWS / VARIABLES ========== */

    function isUserLPing(address user) external view returns (bool isUserInLP);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface IThalesAMMLiquidityPool {
    /* ========== VIEWS / VARIABLES ========== */

    function isUserLPing(address user) external view returns (bool isUserInLP);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface IParlayAMMLiquidityPool {
    function commitTrade(address market, uint amountToMint) external;

    function getMarketRound(address market) external view returns (uint _round);

    function getMarketPool(address market) external view returns (address roundPool);

    function transferToPool(address market, uint amount) external;

    function isUserLPing(address user) external view returns (bool isUserInLP);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "./IPriceFeed.sol";

interface IThalesAMM {
    enum Position {
        Up,
        Down
    }

    function manager() external view returns (address);

    function availableToBuyFromAMM(address market, Position position) external view returns (uint);

    function impliedVolatilityPerAsset(bytes32 oracleKey) external view returns (uint);

    function buyFromAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function buyFromAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external returns (uint);

    function availableToSellToAMM(address market, Position position) external view returns (uint);

    function sellToAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function sellToAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external returns (uint);

    function isMarketInAMMTrading(address market) external view returns (bool);

    function price(address market, Position position) external view returns (uint);

    function buyPriceImpact(
        address market,
        Position position,
        uint amount
    ) external view returns (int);

    function sellPriceImpact(
        address market,
        Position position,
        uint amount
    ) external view returns (int);

    function priceFeed() external view returns (IPriceFeed);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarket.sol";

interface IPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function durations() external view returns (uint expiryDuration, uint maxTimeToMaturity);

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function onlyAMMMintingAndBurning() external view returns (bool);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getThalesAMM() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint // initial sUSD to mint options for,
    ) external returns (IPositionalMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IStakingThalesBonusRewardsManager {
    function storePoints(
        address user,
        address origin,
        uint basePoins,
        uint round
    ) external;

    function getUserRoundBonusShare(address user, uint round) external view returns (uint);

    function useNewBonusModel() external view returns (bool);
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPassportPosition {
    struct Position {
        uint round;
        uint position;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface IPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Up,
        Down
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions() external view returns (IPosition up, IPosition down);

    function times() external view returns (uint maturity, uint destructino);

    function getOracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees() external view returns (uint poolFee, uint creatorFee);

    function deposited() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePrice() external view returns (uint);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint up, uint down);

    function totalSupplies() external view returns (uint up, uint down);

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);

    function exerciseWithAmount(address claimant, uint amount) external;
}