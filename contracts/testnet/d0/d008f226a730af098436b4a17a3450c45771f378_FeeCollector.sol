// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/core/IVaultAccessControlRegistry.sol";

pragma solidity 0.8.17;

contract AccessControlBase is Context {
    IVaultAccessControlRegistry public immutable registry;
    address public immutable timelockAddressImmutable;

    constructor(
        address _vaultRegistry,
        address _timelock
    ) {
        registry = IVaultAccessControlRegistry(_vaultRegistry);
        timelockAddressImmutable = _timelock;
    }

    /*==================== Managed in VaultAccessControlRegistry *====================*/

    modifier onlyGovernance() {
        require(
            registry.isCallerGovernance(_msgSender()),
            "Forbidden: Only Governance"
        );
        _;
    }

    modifier onlyManager() {
        require(
            registry.isCallerManager(_msgSender()),
            "Forbidden: Only Manager"
        );
        _;
    }

    modifier onlyEmergency() {
        require(
            registry.isCallerEmergency(_msgSender()),
            "Forbidden: Only Emergency"
        );
        _;
    }

    modifier protocolNotPaused() {
        require(
            !registry.isProtocolPaused(),
            "Forbidden: Protocol Paused"
        );
        _;
    }

    /*==================== Managed in WINRTimelock *====================*/

    modifier onlyTimelockGovernance() {
        address timelockActive_;
        if(!registry.timelockActivated()) {
            // the flip is not switched yet, so this means that the governance address can still pass the onlyTimelockGoverance modifier
            timelockActive_ = registry.governanceAddress();
        } else {
            // the flip is switched, the immutable timelock is now locked in as the only adddress that can pass this modifier (and nothing can undo that)
            timelockActive_ = timelockAddressImmutable;
        }
        require(
            _msgSender() == timelockActive_,
            "Forbidden: Only TimelockGovernance"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/core/IWLPManager.sol";
import "../interfaces/core/IFeeCollector.sol";
import "../tokens/wlp/interfaces/IBasicFDT.sol";
import "./AccessControlBase.sol";

/**
 * This contract collects wager and swap fees from the vault - for each whitelisted token in the vault.
 * After the fees are collected (and reside in this contract), the contract transfer the collected fees to 3 entities, the amount of the collected fees these enities receive is based on the configured distribution ratio (in distributionConfig).
 * The swap+wager fee distribution function can only be called once per rewardInterval (configurable).
 */
contract FeeCollector is Pausable, ReentrancyGuard, AccessControlBase, IFeeCollector {

    /*==================== Constants *====================*/
    uint256 private constant MAX_INTERVAL = 14 days;
    uint256 private constant BASIS_POINTS_DIVISOR = 1e4;
    uint256 private constant PRICE_PRECISION = 1e30;

    /*==================== State Variabes *====================*/

    // vault contract address
    IVault public vault;
    // vault contract address
    IWLPManager public wlpManager;
    mapping(address => bool) private whitelistedDestinations;
    // the fee distribution reward interval
    uint256 public rewardInterval = 1 days;
    // timestamp of the last time fees where withdrawn
    uint256 public lastWithdrawTime;
    // last distribution times of destinations
    DistributionTimes public lastDistributionTimes;
    // array with addresses of all tokens fees are collected in
    address[] public allWhitelistedTokensFeeCollector;
    // distribution addresses
    DistributionAddresses public addresses;
    // stores wlp amounts of addresses
    Reserve public reserves;
    // stores tokens amounts of referral
    mapping(address => uint256) public referralReserve;
    WagerDistributionRation public wagerDistributionConfig;
    SwapDistributionRation public swapDistributionConfig;

    IERC20 public wlp;

    bool public failOnTime = false;

    function setFailOnTime(bool _setting) external onlyGovernance {
        failOnTime = _setting;
    }

    constructor(
        address _vaultRegistry,
        address _vault,
        address _wlpManager,
        address _wlpClaimContract,
        address _winrStakingContract,
        address _buybackContract,
        address _burnContract,
        address _coreDevelopment,
        address _referralContract,
        address _timelock
    ) AccessControlBase(_vaultRegistry, _timelock) Pausable() {
        _checkNotNull(_vault);
        _checkNotNull(_wlpManager);
        vault = IVault(_vault);
        wlpManager = IWLPManager(_wlpManager);

        addresses = IFeeCollector.DistributionAddresses(
            _wlpClaimContract, 
            _winrStakingContract, 
            _buybackContract, 
            _burnContract, 
            _coreDevelopment, 
            _referralContract
        );

        lastWithdrawTime = block.timestamp;
        lastDistributionTimes = DistributionTimes(
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp
        );

        wlp = IERC20(wlpManager.wlp());

        whitelistedDestinations[_wlpClaimContract] = true;
        whitelistedDestinations[_winrStakingContract] = true;
        whitelistedDestinations[_coreDevelopment] = true;
        whitelistedDestinations[_buybackContract] = true;
        whitelistedDestinations[_burnContract] = true;
        whitelistedDestinations[_referralContract] = true;
    }

    /*==================== Configuration functions (onlyGovernance) *====================*/

    /**
     * @notice function that changes vault address
     */
    function setVault(address vault_) public onlyGovernance {
        _checkNotNull(vault_);
        vault = IVault(vault_);
        emit VaultUpdated(vault_);
    }

    /**
     * @notice function that changes wlp manager address
     */
    function setWlpManager(address wlpManager_) public onlyGovernance {
        _checkNotNull(wlpManager_);
        wlpManager = IWLPManager(wlpManager_);
        wlp = IERC20(wlpManager.wlp());
        emit WLPManagerUpdated(address(wlpManager_));
    }

    /**
     * @param _wlpClaimContract address for the claim destination
     */
    function setClaimContract(
        address _wlpClaimContract
    ) external onlyGovernance {
        _checkNotNull(_wlpClaimContract);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.wlpClaim] = false;
        addresses.wlpClaim = _wlpClaimContract;
        whitelistedDestinations[_wlpClaimContract] = true;
        emit SetClaimDestination(_wlpClaimContract);
    }

    /**
     * @param _buybackContract address for the buyback destination
     */
    function setBuyBackContract(
        address _buybackContract
    ) external onlyGovernance {
        _checkNotNull(_buybackContract);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.buyback] = false;
        addresses.buyback = _buybackContract;
        whitelistedDestinations[_buybackContract] = true;
        emit SetBuybackDestination(_buybackContract);
    }

    /**
     * @param _burnContract address for the burn destination
     */
    function setBurnContract(
        address _burnContract
    ) external onlyGovernance {
        _checkNotNull(_burnContract);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.burn] = false;
        addresses.burn = _burnContract;
        whitelistedDestinations[_burnContract] = true;
        emit SetBurnDestination(_burnContract);
    }

    /**
     * @param _winrStakingContract address for the staking destination
     */
    function setStakingContract(
        address _winrStakingContract
    ) external onlyGovernance {
        _checkNotNull(_winrStakingContract);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.winrStaking] = false;
        addresses.winrStaking = _winrStakingContract;
        whitelistedDestinations[_winrStakingContract] = true;
        emit SetStakingDestination(_winrStakingContract);
    }

    /**
     * @param _coreDevelopment  address for the core destination
     */
    function setCoreDevelopment(
        address _coreDevelopment
    ) external onlyGovernance {
        _checkNotNull(_coreDevelopment);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.core] = false;
        addresses.core = _coreDevelopment;
        whitelistedDestinations[_coreDevelopment] = true;
        emit SetCoreDestination(_coreDevelopment);
    }

    /**
     * @param _referralAddress  address for the referral distributor
     */
    function setReferralDistributor(
        address _referralAddress
    ) external onlyGovernance {
        _checkNotNull(_referralAddress);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.referral] = false;
        addresses.referral = _referralAddress;
        whitelistedDestinations[_referralAddress] = true;
        emit SetReferralDestination(_referralAddress);
    }

    /**
     * @notice function to add a fee destination address to the whitelist
     * @dev can only be called by the timelock governance contract
     * @param _toWhitelistAddress address to whitelist
     * @param _setting bool to either whitelist or 'unwhitelist' address
     */
    function addToWhitelist(
        address _toWhitelistAddress,
        bool _setting
    ) external onlyTimelockGovernance {
        _checkNotNull(_toWhitelistAddress);
        whitelistedDestinations[_toWhitelistAddress] = _setting;
        emit WhitelistEdit(_toWhitelistAddress, _setting);
    }

    /**
     * @notice configuration function for 
     * @dev the configured fee collection interval cannot exceed the MAX_INTERVAL
     * @param _timeInterval uint time interval for fee collection
     */
    function setRewardInterval(
        uint256 _timeInterval
    ) external onlyGovernance {
        require(_timeInterval <= MAX_INTERVAL, "FeeCollector: invalid interval");
        rewardInterval = _timeInterval;
        emit SetRewardInterval(_timeInterval);
    }

    /**
     * @notice function that configures the collected wager fee distribution
     * @dev the ratios together should equal 1e4 (100%)
     * @param _stakingRatio the ratio of the winr stakers 
     * @param _burnRatio the ratio of the burning amounts
     * @param _coreRatio  the ratio of the core dev
     */
    function setWagerDistribution(
        uint64 _stakingRatio,
        uint64 _burnRatio,
        uint64 _coreRatio
    ) external onlyGovernance {
        // together all the ratios need to sum to 1e4 (100%)
        require(
            (_stakingRatio + _burnRatio + _coreRatio) == 1e4,
            "FeeCollector: Wager Ratios together don't sum to 1e4"
        );
        wagerDistributionConfig = WagerDistributionRation(
            _stakingRatio,
            _burnRatio,
            _coreRatio
        );
        emit WagerDistributionSet(
            _stakingRatio,
            _burnRatio,
            _coreRatio
        );
    }

    /**
     * @notice function that configures the collected swap fee distribution
     * @dev the ratios together should equal 1e4 (100%)
     * @param _wlpHoldersRatio the ratio of the totalRewards going to WLP holders
     * @param _stakingRatio the ratio of the totalRewards going to WINR stakers
     * @param _buybackRatio  the ratio of the buyBack going to buyback address
     * @param _coreRatio  the ratio of the totalRewars going to core dev
     */
    function setSwapDistribution(
        uint64 _wlpHoldersRatio,
        uint64 _stakingRatio,
        uint64 _buybackRatio,
        uint64 _coreRatio
    ) external onlyGovernance {
        // together all the ratios need to sum to 1e4 (100%)
        require(
            (_wlpHoldersRatio + _stakingRatio + _buybackRatio + _coreRatio) == 1e4,
            "FeeCollector: Ratios together don't sum to 1e4"
        );
        swapDistributionConfig = SwapDistributionRation(
            _wlpHoldersRatio,
            _stakingRatio,
            _buybackRatio,
            _coreRatio
        );
        emit SwapDistributionSet(
            _wlpHoldersRatio,
            _stakingRatio,
            _buybackRatio,
            _coreRatio
        );
    }

    /**
     * Context/Explanation of the feecollectors whitelistList:
     * The Vault collects fees of all actions of whitelisted tokens present in the vault (payins, swaps, deposit, withdraw).
     * The FeeCollector contract should be able to claim these tokens always (since the FeeCollectors role is to distribute these tokens to the recipients).
     * It is possible that tokens are removed from the vaults whitelist by WINR governance - while there are still collected wager/swap fee tokens present on the vault (this would be a one-time sitation). If the tokens are removed from the vaults whitelist, the FeeCollector will be unable to collect these tokens (since it iterates over the whitelisted token array of the Vault).
     * 
     * To make sure that tokens are still collectable, we added a set of functions in the FeeCollector that can manually add/remove tokens to the feecollectors whitelist. Managers are able to sync this array with the vault and manually add/remove tokens from it. 
     */

    /**
     * @notice function that syncs the whitelisted tokens with the vault
     */
    function syncWhitelistedTokens() public onlyManager {
        delete allWhitelistedTokensFeeCollector;
        uint256 count_ = vault.allWhitelistedTokensLength();
        for (uint256 i = 0; i < count_; i++) {
            address token_ = vault.allWhitelistedTokens(i);
            allWhitelistedTokensFeeCollector.push(token_);
        }
        emit SyncTokens();
    }

    /**
     * @notice manually adds a tokenaddress to the vault
     * @param _tokenToAdd address to manually add to the allWhitelistedTokensFeeCollector array
     */
    function addTokenToWhitelistList(
        address _tokenToAdd
    ) external onlyManager {
        allWhitelistedTokensFeeCollector.push(_tokenToAdd);
        emit TokenAddedToWhitelist(_tokenToAdd);
    }

    /**
     * @notice deletes entire whitelist array
     * @dev this function should be used before syncWhitelistedTokens is called!
     */
    function deleteWhitelistTokenList() external onlyManager {
        delete allWhitelistedTokensFeeCollector;
        emit DeleteAllWhitelistedTokens();
    }

    /*==================== Operational functions WINR/JB *====================*/

    function syncLastWithdraw() external onlyManager {
        lastWithdrawTime = block.timestamp;
        emit WithdrawSync();
    }

    function syncLastDistribution() external onlyManager {
        lastDistributionTimes = DistributionTimes(
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp
        );
        emit DistributionSync();
    }

    /*==================== Public callable operational functions *====================*/    

    function getReserves() public view returns(Reserve memory reserves_) {
        reserves_ = reserves;
    }

    function getSwapDistribution() public view returns(SwapDistributionRation memory swapDistributionConfig_) {
        swapDistributionConfig_ = swapDistributionConfig;
    }

    function getWagerDistribution() public view returns(WagerDistributionRation memory wagerDistributionConfig_) {
        wagerDistributionConfig_ = wagerDistributionConfig;
    }

    function getAddresses() public view returns(DistributionAddresses memory addresses_) {
        addresses_ = addresses;
    }

    function isWhitelistedDestination(address _address) public view returns (bool whitelisted_) {
        whitelisted_ = whitelistedDestinations[_address];
    }

    /**
     * @notice function that claims/farms the wager+swap fees in vault, and distributes it to wlp holders, stakers and core dev
     * @dev function can only be called once per interval period
     * note KK consider making this a protected function - although i don't see any attack vector 
     */
    function withdrawFeesAll() external onlyManager {
        // collected fees can only be distributed once every rewardIntervval
        require(
            lastWithdrawTime + rewardInterval <= block.timestamp,
            "Fees can only be withdrawn once per rewardInterval"
        );
        _withdrawAllFees();
        emit FeesDistributed();
    }

    /**
     * @notice manaul transfer tokens from the feecollector to a whitelisted destination address
     * @dev our of safety concerns it is only possilbe to do a manual transfer to a address/wallet that is whitelisted by the governance contract/address
     * @param _targetToken address of the token to manually distriuted
     * @param _amount amount of the _targetToken
     * @param _destination destination address that will receive the token
     */
    function manualDistributionTo(
        address _targetToken, 
        uint256 _amount, 
        address _destination) external onlyManager {
        /**
         * context: even though the manager role i a trusted team member, we do not want that that it is possible for this role to steal funds. Therefor the manager role can only manually transfer funds to a wallet that is whitelisted. On this whitelist only multi-sigs and governance controlled treasury wallets should be added.
         */
        require(
            whitelistedDestinations[_destination], 
            "FeeCollector: Destination not whitelisted"
        );
        SafeERC20.safeTransfer(
            IERC20(_targetToken), 
            _destination, 
            _amount
        );
        emit ManualDistributionManager(
            _targetToken,
            _amount,
            _destination
        );
    }

    /*==================== View functions *====================*/

    /**
     * @notice calculates what is a percentage portion of a certain input
     * @param _amountToDistribute amount to charge the fee over
     * @param _basisPointsPercentage basis point percentage scaled 1e4
     * @return amount_ amount to distribute
     */
    function calculateDistribution(
        uint256 _amountToDistribute,
        uint64 _basisPointsPercentage
    ) public pure returns(uint256 amount_) {
        amount_ = ((_amountToDistribute * _basisPointsPercentage) / BASIS_POINTS_DIVISOR);
    }

    /*==================== Emergency intervention functions (onlyEmergency or onlyTimelockGovernance) *====================*/

//     function pauseFeeColletor() external onlyManager {
//         _pause();
//     }

//    function unpauseFeeColletor() external onlyManager {
//         _unpause();
//     }

    /**
     * @notice governance function to rescue or correct any tokens that end up in this contract by accident
     * @dev this is a timelocked function! Only the timelock contract can call this function 
     * @param _tokenAddress address of the token to be transferred out
     * @param _amount amount of the token to be transferred out
     * @param _recipient address of the receiver of the token
     */
    function removeTokenByGoverance(
        address _tokenAddress,
        uint256 _amount,
        address _recipient
    ) external onlyTimelockGovernance {
        SafeERC20.safeTransfer(
            IERC20(_tokenAddress), 
            timelockAddressImmutable, 
            _amount
        );
        emit TokenTransferredByTimelock(
            _tokenAddress,
            _recipient,
            _amount
        );
    }

    /**
     * @notice emergency function that transfers all the tokens in this contact to the timelock contract.
     * @dev this function should be called when there is an exploit or a key of one of the manager is exposed 
     */
    function emergencyDistributionToTimelock() external onlyManager {
        address[] memory wlTokens_ = allWhitelistedTokensFeeCollector;
        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; i++) {
            address token_ = wlTokens_[i];
            uint256 bal_ = IERC20(wlTokens_[i]).balanceOf(address(this));
            if(bal_ == 0) {
                // no balance to swipe, so proceed to next interations
                continue;
            }
            SafeERC20.safeTransfer(
                IERC20(token_), 
                timelockAddressImmutable, 
                bal_
            );
            emit EmergencyWithdraw(
                msg.sender,
                token_,
                bal_,
                address(timelockAddressImmutable)
            );
        }
    }

    function distributeAll() external onlyManager {
        transferBuyBack();
        transferWinrStaking();
        transferWlpRewards();
        transferCore();
        transferBurn();
        transferReferral();
    }


    function transferBuyBack() public onlyManager {
        // collected fees can only be distributed once every rewardIntervval
        // require(
        //     lastDistributionTimes.buyback + rewardInterval <= block.timestamp,
        //     "Fees can only be transferred once per rewardInterval"
        // );
        if (_checkLastTime(lastDistributionTimes.buyback)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;
        }
        lastDistributionTimes.buyback = block.timestamp;
        uint256 amount_ = reserves.buyback;
        reserves.buyback = 0;
        // require(reserves.buyback != 0, "No token for amount");
        if(amount_ == 0) {
            return;
        }
        wlp.transfer(addresses.buyback, amount_);
        emit TransferBuybackTokens(addresses.buyback, amount_);
    }

    function transferBurn() public onlyManager {
        // collected fees can only be distributed once every rewardIntervval
        // require(
        //     lastDistributionTimes.burn + rewardInterval <= block.timestamp,
        //     "Fees can only be transferred once per rewardInterval"
        // );
        if (_checkLastTime(lastDistributionTimes.burn)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;
        }
        lastDistributionTimes.burn = block.timestamp;
        // require(reserves.burn != 0, "No token for burn");
        uint256 amount_ = reserves.burn;
        reserves.burn = 0;
        if(amount_ == 0) {
            return;
        }
        wlp.transfer(addresses.burn, amount_);
        emit TransferBurnTokens(addresses.burn, amount_);
    }

    function transferCore() public onlyManager {
        // collected fees can only be distributed once every rewardIntervval
        // require(
        //     lastDistributionTimes.core + rewardInterval <= block.timestamp,
        //     "Fees can only be transferred once per rewardInterval"
        // );
        if (_checkLastTime(lastDistributionTimes.core)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;
        }
        lastDistributionTimes.core = block.timestamp;
        // require(reserves.core != 0, "No token for core");
        uint256 amount_ = reserves.core;
        reserves.core = 0;
        if(amount_ == 0) {
            return;
        }
        wlp.transfer(addresses.core, amount_);
        emit TransferCoreTokens(addresses.core, amount_);
    }

    function transferWlpRewards() public onlyManager {
        // collected fees can only be distributed once every rewardIntervval
        // require(
        //     lastDistributionTimes.wlpClaim + rewardInterval <= block.timestamp,
        //     "Fees can only be transferred once per rewardInterval"
        // );
        if(_checkLastTime(lastDistributionTimes.wlpClaim)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;  
        }
        lastDistributionTimes.wlpClaim = block.timestamp;
        _transferWlpRewards();
    }

    function collectFeesBeforeLPEvent() external {
        require(
            msg.sender == address(wlpManager),
            "Only WLP Manager can call this function"
        );
        // withdraw fees from the vault and register/distribute the fees to according to the distribution ot all destinations
        _withdrawAllFees();
        // transfer the wlp rewards to the wlp claim contract
        _transferWlpRewards();
        // note we do not the other tokens of the partition
        // todo kasper finish this!!!
    }

    function _transferWlpRewards() internal {
        // require(reserves.wlpHolders != 0, "No token for rewards");
        uint256 amount_ = reserves.wlpHolders;
        reserves.wlpHolders = 0;
        if(amount_ == 0) {
            return;
        }
        wlp.transfer(addresses.wlpClaim, amount_);
        IBasicFDT(addresses.wlpClaim).updateFundsReceived_WLP();
        IBasicFDT(addresses.wlpClaim).updateFundsReceived_VWINR();
        // Since the wlp distributor calls the function no need to do anything
        emit TransferWLPRewardTokens(addresses.wlpClaim, amount_);
    }

    function transferWinrStaking() public onlyManager {
        // collected fees can only be distributed once every rewardIntervval
        // require(
        //     lastDistributionTimes.winrStaking + rewardInterval <= block.timestamp,
        //     "Fees can only be transferred once per rewardInterval"
        // );
        if(_checkLastTime(lastDistributionTimes.winrStaking)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;
        }
        lastDistributionTimes.winrStaking = block.timestamp;
        // require(reserves.staking != 0, "No token for winr staking");
        uint256 amount_ = reserves.staking;
        reserves.staking = 0;
        if(amount_ == 0) {
            return;
        }
        wlp.transfer(addresses.winrStaking, amount_);
        // call winrStaking.share with amount
        emit TransferWinrStakingTokens(addresses.wlpClaim, amount_);
    }

    // function transferReferral() public onlyManager {
    //     // collected fees can only be distributed once every rewardIntervval
    //     // require(
    //     //     lastDistributionTimes.referral + rewardInterval <= block.timestamp,
    //     //     "Fees can only be transferred once per rewardInterval"
    //     // );
    //     if(_checkLastTime(lastDistributionTimes.referral)) {
    //         // we return early, since the last time the referral was called was less than the reward interval
    //         return;
    //     }
    //     lastDistributionTimes.referral = block.timestamp;
    //     // all the swap and wager fees from the vault now sit in this contract
    //     address[] memory wlTokens_ = allWhitelistedTokensFeeCollector;
    //     // iterate over all te tokens that now sit in this contract
    //     for (uint256 i = 0; i < wlTokens_.length; i++) {
    //         uint256 amount_ = referralReserve[wlTokens_[i]];
    //         if (amount_ > 0) {
    //             address token_ = wlTokens_[i];
    //             IERC20(token_).transfer(addresses.referral, amount_);
    //             referralReserve[token_] = 0;
    //             emit TransferReferralTokens(token_, addresses.referral, amount_);
    //         }
    //     }
    // }

    function transferReferral() public onlyManager {
        // collected fees can only be distributed once every rewardIntervval
        // require(
        //     lastDistributionTimes.referral + rewardInterval <= block.timestamp,
        //     "Fees can only be transferred once per rewardInterval"
        // );
        if(_checkLastTime(lastDistributionTimes.referral)) {
            // we return early, since the last time the referral was called was less than the reward interval
            return;
        }
        lastDistributionTimes.referral = block.timestamp;
        // all the swap and wager fees from the vault now sit in this contract
        address[] memory wlTokens_ = allWhitelistedTokensFeeCollector;
        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; i++) {
            address token_ = wlTokens_[i];
            uint256 amount_ = referralReserve[token_];
            referralReserve[token_] = 0;
            if (amount_ > 0) {
                IERC20(token_).transfer(addresses.referral, amount_);
                emit TransferReferralTokens(token_, addresses.referral, amount_);
            }
        }
    }

    function _checkLastTime(uint256 _lastTime) internal view returns (bool) {
        bool inTime_ = _lastTime + rewardInterval <= block.timestamp;
        if(failOnTime) {
            require(inTime_, "Fees can only be transferred once per rewardInterval");
        } 
    }

    /*==================== Internal functions *====================*/

    function _withdrawAllFees() internal {
        // all the swap and wager fees from the vault now sit in this contract
        address[] memory wlTokens_ = allWhitelistedTokensFeeCollector;

        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; i++) {
            _withdraw(wlTokens_[i]);
        }
        lastWithdrawTime = block.timestamp;
    }

    /**
     * @notice internal withdraw function 
     * @param _token address of the token to be distributed
     */
    function _withdraw(address _token) internal {
        IVault vault_ = vault;
        (
            uint256 swapReserve_,
            uint256 wagerReserve_,
            uint256 referralReserve_
        ) = vault_.withdrawAllFees(_token);

        if (swapReserve_ > 0) {
            uint256 swapWlpAmount_ = _addLiquidity(_token, swapReserve_);
            // distribute the farmed swap fees to the addresses tat 
            _setAmountsForSwap(swapWlpAmount_);
        }
        if (wagerReserve_ > 0) {
            uint256 wagerWlpAmount_ = _addLiquidity(_token, wagerReserve_);
            _setAmountsForWager(wagerWlpAmount_);
        }

        if (referralReserve_ > 0) {
            referralReserve[_token] = referralReserve_;
        }
    }

    /**
     * @notice internal function that deposits tokens and returns amount of wlp
     * @param _token token address of amount which wants to deposit
     * @param _amount amount of the token collected (FeeCollector contract)
     * @return wlpAmount_ amount of the token minted to this by depositing
     */
    function _addLiquidity(address _token, uint256 _amount) internal returns (uint256 wlpAmount_) {
        uint256 before_ = wlp.balanceOf(address(this));
        IERC20(_token).approve(address(wlpManager), _amount);
        wlpAmount_ = wlpManager.addLiquidity(_token, _amount, 0, 0);
        require(
            wlp.balanceOf(address(this)) == wlpAmount_ + before_,
            "WLP amount mismatch"
        );
        return wlpAmount_;
    }

    /**
     * @notice internal function that calculates how much of each asset accumulated in the contract need to be distributed to the configured contracts and set
     * @param _amount amount of the token collected by swap in this (FeeCollector contract)
     */
    function _setAmountsForSwap(uint256 _amount) internal {
        reserves.wlpHolders += calculateDistribution(_amount, swapDistributionConfig.wlpHolders);
        reserves.staking += calculateDistribution(_amount, swapDistributionConfig.staking);
        reserves.buyback += calculateDistribution(_amount, swapDistributionConfig.buyback);
        reserves.core += calculateDistribution(_amount, swapDistributionConfig.core);
    }

    /**
     * @notice internal function that calculates how much of each asset accumulated in the contract need to be distributed to the configured contracts and set
     * @param _amount amount of the token collected by wager in this (FeeCollector contract)
     */
    function _setAmountsForWager(uint256 _amount) internal {
        reserves.staking += calculateDistribution(_amount, wagerDistributionConfig.staking);
        reserves.burn += calculateDistribution(_amount, wagerDistributionConfig.burn);
        reserves.core += calculateDistribution(_amount, wagerDistributionConfig.core);
    }

    /**
     * @notice internal function that checks if an address is not 0x0
     */
    function _checkNotNull(address _setAddress) internal pure {
        require(
            _setAddress != address(0x0),
            "FeeCollector: Null not allowed"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IFeeCollector {

    /*==================== Public Functions *====================*/
    
    struct SwapDistributionRation {
        uint64 wlpHolders;
        uint64 staking;
        uint64 buyback;
        uint64 core;
    }

    struct WagerDistributionRation {
        uint64 staking;
        uint64 burn;
        uint64 core;
    }

    struct Reserve {
        uint256 wlpHolders;
        uint256 staking;
        uint256 buyback;
        uint256 burn;
        uint256 core;
    }

    // *** Destination addresses for the farmed fees from the vault *** //
    // note: the 4 addresses below need to be able to receive ERC20 tokens
    struct DistributionAddresses {
        // the destination address for the collected fees attributed to WLP holders 
        address wlpClaim;
        // the destination address for the collected fees attributed  to WINR stakers
        address winrStaking;
        // address of the contract that does the 'buyback and burn'
        address buyback;
        // address of the contract that does the 'buyback and burn'
        address burn;
        // the destination address for the collected fees attributed to core development
        address core;
        // address of the contract/EOA that will distribute the referral fees
        address referral;
    }

    struct DistributionTimes {
        uint256 wlpClaim;
        uint256 winrStaking;
        uint256 buyback;
        uint256 burn;
        uint256 core;
        uint256 referral;
    }

    function getReserves() external returns (Reserve memory);
    function getSwapDistribution() external returns(SwapDistributionRation memory);
    function getWagerDistribution() external returns(WagerDistributionRation memory);
    function getAddresses() external returns (DistributionAddresses memory);
    function calculateDistribution(uint256 _amountToDistribute, uint64 _ratio) external pure returns(uint256 amount_);
    function withdrawFeesAll() external;
    function syncLastWithdraw() external;
    function isWhitelistedDestination(address _address) external returns (bool);
    function syncWhitelistedTokens() external;
        function addToWhitelist(
        address _toWhitelistAddress,
        bool _setting
    ) external;
    function setReferralDistributor(
        address _distributorAddress
    ) external;
    function setCoreDevelopment(
        address _coreDevelopment
    ) external;
    function setStakingContract(
        address _winrStakingContract
    ) external;
    function setBuyBackContract(
        address _buybackContract
    ) external;
    function setBurnContract(
        address _burnContract
    ) external;
    function setClaimContract(
        address _wlpClaimContract
    ) external;
    function setWagerDistribution(
        uint64 _stakingRatio,
        uint64 _burnRatio,
        uint64 _coreRatio
    ) external;
    function setSwapDistribution(
        uint64 _wlpHoldersRatio,
        uint64 _stakingRatio,
        uint64 _buybackRatio,
        uint64 _coreRatio
    ) external;
    function addTokenToWhitelistList(
        address _tokenToAdd
    ) external;
    function deleteWhitelistTokenList() external;

    function collectFeesBeforeLPEvent() external;

    /*==================== Events *====================*/

    event DistributionSync();
    event WithdrawSync();
    event WhitelistEdit(
        address whitelistAddress,
        bool setting
    );
    event EmergencyWithdraw(
        address caller,
        address token,
        uint256 amount,
        address destination
    );
    event ManualGovernanceDistro();
    event FeesDistributed();
    event WagerFeesManuallyFarmed(
        address tokenAddress,
        uint256 amountFarmed
    );
    event ManualDistributionManager(
        address targetToken,
        uint256 amountToken,
        address destinationAddress
    );
    event SetRewardInterval(uint256 timeInterval);
    event SetCoreDestination(address newDestination);
    event SetBuybackDestination(address newDestination);
    event SetBurnDestination(address newDestination);
    event SetClaimDestination(address newDestination);
    event SetReferralDestination(address referralDestination);
    event SetStakingDestination(address newDestination);
    event SwapFeesManuallyFarmed(
        address tokenAddress,
        uint256 totalAmountCollected
    );
    event CollectedWagerFees(
        address tokenAddress,
        uint256 amountCollected
    );
    event CollectedSwapFees(
        address tokenAddress,
        uint256 amountCollected
    );
    event NothingToDistribute(
        address token   
    );
    event DistributionComplete(
        address token,
        uint256 toWLP,
        uint256 toStakers,
        uint256 toBuyBack,
        uint256 toCore,
        uint256 toReferral
    );
    event WagerDistributionSet(
        uint64 stakingRatio,
        uint64 burnRatio,
        uint64 coreRatio
    );
    event SwapDistributionSet(
        uint64 _wlpHoldersRatio,
        uint64 _stakingRatio,
        uint64 _buybackRatio,
        uint64 _coreRatio
    );
    event SyncTokens();
    event DeleteAllWhitelistedTokens();
    event TokenAddedToWhitelist(address addedTokenAddress);
    event TokenTransferredByTimelock(
        address token,
        address recipient,
        uint256 amount
    );

    event TransferBuybackTokens(
        address receiver, 
        uint256 amount
    );

    event TransferBurnTokens(
        address receiver, 
        uint256 amount
    );

    event TransferCoreTokens(
        address receiver, 
        uint256 amount
    );

    event TransferWLPRewardTokens(
        address receiver, 
        uint256 amount
    );

    event TransferWinrStakingTokens(
        address receiver, 
        uint256 amount
    );

    event TransferReferralTokens(
        address token, 
        address receiver, 
        uint256 amount
    );
    event VaultUpdated(address vault);
    event WLPManagerUpdated(address wlpManager);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
    /*==================== Events *====================*/
    event BuyUSDW(
        address account, 
        address token, 
        uint256 tokenAmount, 
        uint256 usdwAmount, 
        uint256 feeBasisPoints
    );
    event SellUSDW(
        address account, 
        address token, 
        uint256 usdwAmount, 
        uint256 tokenAmount, 
        uint256 feeBasisPoints
    );
    event Swap(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn, 
        uint256 indexed amountOut, 
        uint256 indexed amountOutAfterFees, 
        uint256 indexed feeBasisPoints
    );
    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event DirectPoolDeposit(address token, uint256 amount);
    event IncreaseUsdwAmount(address token, uint256 amount);
    event DecreaseUsdwAmount(address token, uint256 amount);
    error TokenBufferViolation(address tokenAddress);
    error PriceZero();

    event PayinWLP(
        // address of the token sent into the vault 
        address tokenInAddress,
        // amount payed in (was in escrow)
        uint256 amountPayin
    );

    event PlayerPayout(
        // address the player receiving the tokens (do we need this? i guess it does not matter to who we send tokens for profit/loss calculations?)
        address recipient,
        // address of the token paid to the player
        address tokenOut,
        // net amount sent to the player (this is NOT the net loss, since it includes the payed in tokens, excludes wagerFee and swapFee!)
        uint256 amountPayoutTotal
    );

    event AmountOutNull();
    
    /**
     * Profit/loss calculations:
     * If you want to know the total payouts you sum all the amountPayoutTotal of a token
     * if you want to know the total payins you sum all the payins of a certain token
     * if you want to know net profit/loss for WLPs, you calculate the USD value of both and deduct them of each other!
     */

    // event IncreasePoolAmount(
    //     address tokenAddress, 
    //     uint256 amountIncreased
    // );

    // event DecreasePoolAmount(
    //     address tokenAddress, 
    //     uint256 amountDecreased
    // );

    // event WagerFeesCollected(
    //     address tokenAddress,
    //     uint256 usdValueFee,
    //     uint256 feeInTokenCharged
    // );

    event RebalancingWithdraw(
        address tokenWithdrawn,
        uint256 amountWithdrawn
    );

    event RebalancingDeposit(
        address tokenDeposit,
        uint256 amountDeposit
    );

    /*==================== Operational Functions *====================*/
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;
    function router() external view returns (address);
    function usdw() external view returns (address);
    function feeCollector() external returns(address);
    // function whitelistedTokenCount() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdwAmount(address _token) external view returns (uint256);
    function inManagerMode() external view returns (bool);
    function isManager(address _account) external view returns (bool);
    function tokenBalances(address _token) external view returns (uint256);
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager, bool _isWLPManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setUsdwAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _minimumBurnMintFee,
        bool _hasDynamicFees
    ) external;
    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _maxUsdwAmount,
        bool _isStable
    ) external;
    function setPriceFeedRouter(address _priceFeed) external;
    function withdrawAllFees(address _token) external returns (uint256,uint256,uint256);
    function directPoolDeposit(address _token) external;
    function deposit(address _tokenIn, address _receiver) external returns (uint256);
    function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function tokenToUsdMin(address _tokenToPrice, uint256 _tokenAmount) external view returns (uint256);
    function priceOracleRouter() external view returns (address);
    // function getFeeBasisPoints(
    //     address _token, 
    //     uint256 _usdwDelta, 
    //     uint256 _feeBasisPoints, 
    //     uint256 _taxBasisPoints, 
    //     bool _increment
    // ) external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function minimumBurnMintFee() external view returns (uint256);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function swapFeeReserves(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function usdwAmounts(address _token) external view returns (uint256);
    function maxUsdwAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);
    function setVaultManagerAddress(address _vaultManagerAddress) external;
    function vaultManagerAddress() external view returns (address);
    function wagerFeeBasisPoints() external view returns (uint256);
    function setWagerFee(uint256 _wagerFee) external;
    function wagerFeeReserves(address _token) external view returns(uint256);
    function referralReserves(address _token) external view returns(uint256);
    function setFeeLessForPayout(bool _setting) external;
    function getReserve() external view returns (uint256);
    function getDollarValue(address _token) external view returns (uint256);
    function getWlpValue() external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) external view returns(uint256);
    function returnTotalInAndOut(address token_) external view returns(uint256 totalOutAllTime_, uint256 totalInAllTime_);

    function adjustForDecimals(
        uint256 _amount, 
        address _tokenDiv, 
        address _tokenMul) external view returns (uint256 scaledAmount_);

    function payout(
        address[2] memory _tokens,
        address _escrowAddress,
        uint256 _escrowAmount,
        address _recipient,
        uint256 _totalAmount
    ) external;

    function payin(
        address _inputToken,
        address _escrowAddress,
        uint256 _escrowAmount
    ) external;

    function setAsideReferral(
        address _token,
        uint256 _amount
    ) external;

    function rebalanceWithdraw(
        address _tokenToRebalanceWith,
        uint256 _amountToRebalanceWith
    ) external;

    function rebalanceDeposit(
        address _tokenInDeposited,
        uint256 _amountDeposited
    ) external;
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/IAccessControl.sol";

pragma solidity >=0.6.0 <0.9.0;

interface IVaultAccessControlRegistry is IAccessControl {
    function timelockActivated() external view returns(bool);
    function governanceAddress() external view returns(address);
    function pauseProtocol() external;
    function unpauseProtocol() external;
    function isCallerGovernance(address _account) external view returns (bool);
    function isCallerManager(address _account) external view returns (bool);
    function isCallerEmergency(address _account) external view returns (bool);
    function isProtocolPaused() external view returns (bool);
    function changeGovernanceAddress(address _governanceAddress) external;

    /*==================== Events WINR  *====================*/

    event DeadmanSwitchFlipped();
    event GovernanceChange(
        address newGovernanceAddress
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtils {
    function getBuyUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSellUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdwAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdwDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVault.sol";

interface IWLPManager {
    function wlp() external view returns (address);
    function usdw() external view returns (address);
    function vault() external view returns (IVault);
    function cooldownDuration() external returns (uint256);
    function getAumInUsdw(bool maximise) external view returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdw, uint256 _minWlp) external returns (uint256);
    function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minUsdw, uint256 _minWlp) external returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _wlpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _wlpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function setCooldownDuration(uint256 _cooldownDuration) external;
    function getAum(bool _maximise) external view returns(uint256);
    function getPriceWlp(bool _maximise) external view returns(uint256);
    function getPriceWLPInUsdw(bool _maximise) external view returns(uint256);

    function maxPercentageOfWagerFee() external view returns(uint256);



    /*==================== Events *====================*/
    event AddLiquidity(
        address account,
        address token,
        uint256 amount,
        uint256 aumInUsdw,
        uint256 wlpSupply,
        uint256 usdwAmount,
        uint256 mintAmount
    );

    event RemoveLiquidity(
        address account,
        address token,
        uint256 wlpAmount,
        uint256 aumInUsdw,
        uint256 wlpSupply,
        uint256 usdwAmount,
        uint256 amountOut
    );

    event PrivateModeSet(
        bool inPrivateMode
    );

    event HandlerEnabling(
        bool setting
    );

    event HandlerSet(
        address handlerAddress,
        bool isActive
    );

    event CoolDownDurationSet(
        uint256 cooldownDuration
    );

    event AumAdjustmentSet(
        uint256 aumAddition,
        uint256 aumDeduction
    );

    event MaxPercentageOfWagerFeeSet(
        uint256 maxPercentageOfWagerFee
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IBaseFDT {

    /**
        @dev    Returns the total amount of funds a given address is able to withdraw currently.
        @param  owner Address of FDT holder.
        @return A uint256 representing the available funds for a given account.
    */
    function withdrawableFundsOf_WLP(address owner) external view returns (uint256);

    function withdrawableFundsOf_VWINR(address owner) external view returns (uint256);

    /**
        @dev Withdraws all available funds for a FDT holder.
    */
    function withdrawFunds_WLP() external;

    function withdrawFunds_VWINR() external;

    function withdrawFunds() external;

    /**
        @dev   This event emits when new funds are distributed.
        @param by               The address of the sender that distributed funds.
        @param fundsDistributed_WLP The amount of funds received for distribution.
    */
    event FundsDistributed_WLP(address indexed by, uint256 fundsDistributed_WLP);

    event FundsDistributed_VWINR(address indexed by, uint256 fundsDistributed_VWINR);


    /**
        @dev   This event emits when distributed funds are withdrawn by a token holder.
        @param by             The address of the receiver of funds.
        @param fundsWithdrawn_WLP The amount of funds that were withdrawn.
        @param totalWithdrawn_WLP The total amount of funds that were withdrawn.
    */
    event FundsWithdrawn_WLP(address indexed by, uint256 fundsWithdrawn_WLP, uint256 totalWithdrawn_WLP);

    event FundsWithdrawn_VWINR(address indexed by, uint256 fundsWithdrawn_VWINR, uint256 totalWithdrawn_VWINR);

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBaseFDT.sol";

interface IBasicFDT is IBaseFDT, IERC20 {

    event PointsPerShareUpdated_WLP(uint256);

    event PointsCorrectionUpdated_WLP(address indexed, int256);

    event PointsPerShareUpdated_VWINR(uint256);

    event PointsCorrectionUpdated_VWINR(address indexed, int256);

    function withdrawnFundsOf_WLP(address) external view returns (uint256);

    function accumulativeFundsOf_WLP(address) external view returns (uint256);

    function withdrawnFundsOf_VWINR(address) external view returns (uint256);

    function accumulativeFundsOf_VWINR(address) external view returns (uint256);

    function updateFundsReceived_WLP() external;

    function updateFundsReceived_VWINR() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}