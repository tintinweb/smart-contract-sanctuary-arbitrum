// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //audit: use V4.9.0
import {MintBurnToken} from "./MintBurnToken.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {ICompounder} from "./interfaces/ICompounder.sol";
import {IRewarder} from "./interfaces/IRewarder.sol";


// ============================================
// ==          CUSTOM ERROR MESSAGES         ==
// ============================================
error DeadlineExpired();
error PortalNotActive();
error PortalAlreadyActive();
error AccountDoesNotExist();
error InsufficientToWithdraw();
error InsufficientStake();
error InsufficientPEtokens();
error InsufficientBalance();
error InvalidOutput();
error InvalidInput();
error InvalidToken();
error FundingPhaseOngoing();
error DurationLocked();
error DurationCannotIncrease();
error TradeTimelockActive();
error FailedToSendNativeToken();

/// @title Portal Contract
/// @author Possum Labs
/** @notice This contract accepts user deposits and withdrawals of a specific token
* The deposits are redirected to an external protocol to generate yield
* Yield is claimed and collected into this contract
* Users accrue portalEnergy points over time while staking their tokens
* portalEnergy can be exchanged against the PSM token using the internal Liquidity Pool or minted as ERC20
* The contract can receive PSM tokens during the funding phase and issues bTokens as receipt
* bTokens can be redeemed against the fundingRewardPool which consists of PSM tokens
* The fundingRewardPool is filled over time by taking a 10% cut from the Converter
* The Converter is an arbitrage mechanism that allows anyone to sweep the contract balance of a token
* When triggering the Converter, the arbitrager must send a fixed amount of PSM tokens to the contract
*/

contract Portal is ReentrancyGuard {
    constructor(uint256 _FUNDING_PHASE_DURATION, 
        uint256 _FUNDING_EXCHANGE_RATIO,
        uint256 _FUNDING_REWARD_RATE, 
        address _PRINCIPAL_TOKEN_ADDRESS,
        uint256 _DECIMALS,
        address _PSM_ADDRESS,
        address _B_TOKEN,
        address _PORTAL_ENERGY,
        uint256 _TERMINAL_MAX_LOCK_DURATION, 
        uint256 _AMOUNT_TO_CONVERT,
        uint256 _TRADE_TIMELOCK)
        {
            if (_FUNDING_PHASE_DURATION < 259200 || _FUNDING_PHASE_DURATION > 2592000) {revert InvalidInput();}
            if (_FUNDING_EXCHANGE_RATIO == 0) {revert InvalidInput();}
            if (_FUNDING_REWARD_RATE == 0) {revert InvalidInput();}
            if (_PRINCIPAL_TOKEN_ADDRESS == address(0)) {revert InvalidInput();}
            if (_DECIMALS == 0) {revert InvalidInput();}
            if (_PSM_ADDRESS == address(0)) {revert InvalidInput();}
            if (_B_TOKEN == address(0)) {revert InvalidInput();}
            if (_PORTAL_ENERGY == address(0)) {revert InvalidInput();}
            if (_TERMINAL_MAX_LOCK_DURATION < maxLockDuration) {revert InvalidInput();}
            if (_AMOUNT_TO_CONVERT == 0) {revert InvalidInput();}
            if (_TRADE_TIMELOCK == 0) {revert InvalidInput();}

            FUNDING_PHASE_DURATION = _FUNDING_PHASE_DURATION;
            FUNDING_EXCHANGE_RATIO = _FUNDING_EXCHANGE_RATIO;
            FUNDING_REWARD_RATE = _FUNDING_REWARD_RATE;
            PRINCIPAL_TOKEN_ADDRESS = _PRINCIPAL_TOKEN_ADDRESS;
            DECIMALS_ADJUSTMENT = 10**_DECIMALS;
            PSM_ADDRESS = _PSM_ADDRESS;
            bToken = MintBurnToken(_B_TOKEN);
            portalEnergyToken = MintBurnToken(_PORTAL_ENERGY);
            TERMINAL_MAX_LOCK_DURATION = _TERMINAL_MAX_LOCK_DURATION;
            AMOUNT_TO_CONVERT = _AMOUNT_TO_CONVERT;
            CREATION_TIME = block.timestamp;
            TRADE_TIMELOCK = _TRADE_TIMELOCK;
    }

    // ============================================
    // ==        GLOBAL VARIABLES & EVENTS       ==
    // ============================================
    using SafeERC20 for IERC20;

    // general
    MintBurnToken bToken;                                   // the receipt token from bootstrapping
    MintBurnToken portalEnergyToken;                        // the ERC20 representation of portalEnergy

    address immutable public PSM_ADDRESS;                   // address of PSM token
    uint256 immutable public AMOUNT_TO_CONVERT;             // constant amount of PSM tokens required to withdraw yield in the contract
    uint256 immutable public TERMINAL_MAX_LOCK_DURATION;    // terminal maximum lock duration of a user´s balance in seconds
    uint256 immutable public CREATION_TIME;                 // time stamp of deployment
    uint256 constant private SECONDS_PER_YEAR = 31536000;   // seconds in a 365 day year
    uint256 public maxLockDuration = 7776000;               // starting value for maximum allowed lock duration of user´s balance in seconds (90 days)
    uint256 public totalPrincipalStaked;                    // shows how much principal is staked by all users combined
    bool private lockDurationUpdateable = true;             // flag to signal if the lock duration can still be updated

    // principal management related
    address immutable public PRINCIPAL_TOKEN_ADDRESS;       // address of the token accepted by the strategy as deposit (HLP)
    uint256 immutable public DECIMALS_ADJUSTMENT;           // scaling factor to account for the decimals of the principal token
    address payable private constant COMPOUNDER_ADDRESS = payable (0x8E5D083BA7A46f13afccC27BFB7da372E9dFEF22);

    address payable private constant HLP_STAKING = payable (0xbE8f8AF5953869222eA8D39F1Be9d03766010B1C);
    address private constant HLP_PROTOCOL_REWARDER = 0x665099B3e59367f02E5f9e039C3450E31c338788;
    address private constant HLP_EMISSIONS_REWARDER = 0x6D2c18B559C5343CB0703bB55AADB5f22152cC32;

    address private constant HMX_STAKING = 0x92E586B8D4Bf59f4001604209A292621c716539a;
    address private constant HMX_PROTOCOL_REWARDER = 0xB698829C4C187C85859AD2085B24f308fC1195D3;
    address private constant HMX_EMISSIONS_REWARDER = 0x94c22459b145F012F1c6791F2D729F7a22c44764;
    address private constant HMX_DRAGONPOINTS_REWARDER = 0xbEDd351c62111FB7216683C2A26319743a06F273;

    uint256 private constant HMX_TIMESTAMP = 1689206400;
    uint256 private constant HMX_NUMBER = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // bootstrapping related
    uint256 immutable public FUNDING_PHASE_DURATION;        // seconds that the funding phase lasts before Portal can be activated
    uint256 immutable public FUNDING_REWARD_RATE;           // baseline return on funding the Portal
    uint256 immutable private FUNDING_EXCHANGE_RATIO;       // amount of portalEnergy per PSM for calculating k during funding process
    uint256 constant public FUNDING_REWARD_SHARE = 10;      // 10% of yield goes to the funding pool until investors are paid back
    uint256 public fundingBalance;                          // sum of all PSM funding contributions
    uint256 public fundingRewardPool;                       // amount of PSM available for redemption against bTokens
    uint256 public fundingRewardsCollected;                 // tracker of PSM collected over time for the reward pool
    uint256 public fundingMaxRewards;                       // maximum amount of PSM to be collected for reward pool
    bool public isActivePortal;                             // Start with false, will be set to true when funding phase ends.

    // exchange related
    uint256 public constantProduct;                         // the K constant of the (x*y = K) constant product formula
    uint256 immutable public TRADE_TIMELOCK;                // Time that must pass between a user´s interactions with the LP        
    mapping(address => uint256) public lastTradeTime;       // Track the last interaction with the LP by the user

    // staking related
    struct Account {                                        // contains information of user stake positions
        bool isExist;
        uint256 lastUpdateTime;
        uint256 lastMaxLockDuration;
        uint256 stakedBalance;
        uint256 maxStakeDebt;
        uint256 portalEnergy;
        uint256 availableToWithdraw;
    }
    mapping(address => Account) public accounts;            // Associate users with their stake position

    // --- Events related to the funding phase ---
    event PortalActivated(address indexed, uint256 fundingBalance);
    event FundingReceived(address indexed, uint256 amount);
    event RewardsRedeemed(address indexed, uint256 amountBurned, uint256 amountReceived);

    // --- Events related to internal exchange PSM vs. portalEnergy ---
    event PortalEnergyBuyExecuted(address indexed, uint256 amount);
    event PortalEnergySellExecuted(address indexed, uint256 amount);

    // --- Events related to minting and burning portalEnergyToken ---
    event PortalEnergyMinted(address indexed, address recipient, uint256 amount);
    event PortalEnergyBurned(address indexed, address recipient, uint256 amount);

    // --- Events related to staking & unstaking ---
    event TokenStaked(address indexed user, uint256 amountStaked);
    event TokenUnstaked(address indexed user, uint256 amountUnstaked);
    event RewardsClaimed(address[] indexed pools, address[][] rewarders, uint256 timeStamp);

    event StakePositionUpdated(address indexed user, 
        uint256 lastUpdateTime,
        uint256 lastMaxLockDuration,
        uint256 stakedBalance,
        uint256 maxStakeDebt,
        uint256 portalEnergy,
        uint256 availableToWithdraw);                       // principal available to withdraw

    // ============================================
    // ==               MODIFIERS                ==
    // ============================================
    modifier activePortalCheck() {
        if (!isActivePortal) {
            revert PortalNotActive();
        }
        _;
    }

    modifier nonActivePortalCheck() {
        if (isActivePortal) {
        revert PortalAlreadyActive();
        }
        _;
    }

    modifier existingAccount() {
        if (!accounts[msg.sender].isExist) {
            revert AccountDoesNotExist();
        }
        _;
    }

    // ============================================
    // ==           STAKING & UNSTAKING          ==
    // ============================================
    /// @notice Update user data to the current state
    /// @dev This function updates the user data to the current state
    /// @dev It calculates the accrued portalEnergy since the last update
    /// @dev It calculates the added portalEnergy due to increased stake balance
    /// @dev It updates the last update time stamp
    /// @dev It updates the user's staked balance
    /// @dev It updates the user's maxStakeDebt
    /// @dev It updates the user's portalEnergy
    /// @dev It updates the amount available to unstake
    /// @param _user The user whose data is to be updated
    /// @param _amount The amount to be added to the user's staked balance
    function _updateAccount(address _user, uint256 _amount) private {
        /// @dev Calculate the accrued portalEnergy since the last update
        uint256 portalEnergyEarned = (accounts[_user].stakedBalance * 
            (block.timestamp - accounts[_user].lastUpdateTime) * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);

        /// @dev Calculate the increase of portalEnergy due to balance increase
        uint256 portalEnergyIncrease = ((accounts[_user].stakedBalance * (maxLockDuration - 
            accounts[_user].lastMaxLockDuration) + (_amount * maxLockDuration)) * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);

        /// @dev Update the last update time stamp
        accounts[_user].lastUpdateTime = block.timestamp;

        /// @dev Update the user's maximum lock duration
        accounts[_user].lastMaxLockDuration = maxLockDuration;

        /// @dev Update the user's staked balance
        accounts[_user].stakedBalance += _amount;

        /// @dev Update the user's maxStakeDebt based on added stake amount and current maxLockDuration
        accounts[_user].maxStakeDebt = (accounts[_user].stakedBalance * maxLockDuration * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);

        /// @dev Update the user's portalEnergy
        accounts[_user].portalEnergy += portalEnergyEarned + portalEnergyIncrease;

        /// @dev Update the amount available to unstake
        if (accounts[_user].portalEnergy >= accounts[_user].maxStakeDebt) {
            accounts[_user].availableToWithdraw = accounts[_user].stakedBalance;
        } else {
            accounts[_user].availableToWithdraw = (accounts[_user].stakedBalance * accounts[_user].portalEnergy) / accounts[_user].maxStakeDebt;
        }
    }


    /// @notice Stake the principal token into the Portal & redirect principal to yield source
    /// @dev This function allows users to stake their principal tokens into the Portal
    /// @dev It checks if the Portal is active
    /// @dev It transfers the user's principal tokens to the contract
    /// @dev It updates the total stake balance
    /// @dev It deposits the principal into the yield source (external protocol)
    /// @dev It checks if the user has a staking position, else it initializes a new stake
    /// @dev It emits an event with the updated stake information
    /// @param _amount The amount of tokens to stake    
    function stake(uint256 _amount) external nonReentrant activePortalCheck {
        /// @dev Require that the staked amount is greater than zero
        if (_amount == 0) {revert InvalidInput();}

        /// @dev Check if the user has a staking account and update, else initialize a new account
        if(accounts[msg.sender].isExist == true){
            /// @dev Update the user's stake info
            _updateAccount(msg.sender, _amount);
        } 
        else {
            uint256 maxStakeDebt = (_amount * maxLockDuration * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);
            uint256 availableToWithdraw = _amount;
            uint256 portalEnergy = maxStakeDebt;
            
            accounts[msg.sender] = Account(true, 
                block.timestamp,
                maxLockDuration, 
                _amount, 
                maxStakeDebt, 
                portalEnergy,
                availableToWithdraw);     
        }

        /// @dev Update the total stake balance
        totalPrincipalStaked += _amount;

        /// @dev Transfer the user's principal tokens to the contract
        IERC20(PRINCIPAL_TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), _amount);

        /// @dev Deposit the principal into the yield source (external protocol)
        _depositToYieldSource(_amount);

        /// @dev Emit an event with the updated stake information
        emit StakePositionUpdated(msg.sender, 
        block.timestamp,
        maxLockDuration,
        accounts[msg.sender].stakedBalance,
        accounts[msg.sender].maxStakeDebt, 
        accounts[msg.sender].portalEnergy, 
        accounts[msg.sender].availableToWithdraw);
    }


    /// @notice Serve unstaking requests & withdraw principal from yield source
    /// @dev This function allows users to unstake their tokens and withdraw the principal from the yield source
    /// @dev It checks if the user has a stake and updates the user's stake data
    /// @dev It checks if the amount to be unstaked is less than or equal to the available withdrawable balance and the staked balance
    /// @dev It withdraws the matching amount of principal from the yield source (external protocol)
    /// @dev It updates the user's staked balance
    /// @dev It updates the user's maximum stake debt
    /// @dev It updates the user's withdrawable balance
    /// @dev It updates the global tracker of staked principal
    /// @dev It sends the principal tokens to the user
    /// @dev It emits an event with the updated stake information
    /// @param _amount The amount of tokens to unstake
    function unstake(uint256 _amount) external nonReentrant existingAccount {
        /// @dev Require that the unstaked amount is greater than zero
        if (_amount == 0) {revert InvalidInput();}        

        /// @dev Update the user's stake data
        _updateAccount(msg.sender,0);

        /// @dev Require that the amount to be unstaked is less than or equal to the available withdrawable balance and the staked balance
        if(_amount > accounts[msg.sender].availableToWithdraw) {revert InsufficientToWithdraw();}
        if(_amount > accounts[msg.sender].stakedBalance) {revert InsufficientStake();}

        /// @dev Withdraw the matching amount of principal from the yield source (external protocol)
        /// @dev Sanity check that the withdrawn amount from yield source is the amount sent to user
        uint256 balanceBefore = IERC20(PRINCIPAL_TOKEN_ADDRESS).balanceOf(address(this));
        _withdrawFromYieldSource(_amount);
        uint256 balanceAfter = IERC20(PRINCIPAL_TOKEN_ADDRESS).balanceOf(address(this));
        uint256 availableAmount = balanceAfter - balanceBefore;

        /// @dev Update the user's stake info & cache to memory
        uint256 stakedBalance = accounts[msg.sender].stakedBalance -= _amount;
        uint256 maxStakeDebt = accounts[msg.sender].maxStakeDebt = (stakedBalance * maxLockDuration * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);
        uint256 portalEnergy = accounts[msg.sender].portalEnergy -= (_amount * maxLockDuration * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);
        uint256 availableToWithdraw = accounts[msg.sender].availableToWithdraw = portalEnergy >= maxStakeDebt ? stakedBalance : (stakedBalance * portalEnergy) / maxStakeDebt;

        /// @dev Update the global tracker of staked principal
        totalPrincipalStaked -= _amount;

        /// @dev Send the principal tokens to the user
        IERC20(PRINCIPAL_TOKEN_ADDRESS).safeTransfer(msg.sender, availableAmount);

        /// @dev Emit an event with the updated stake information
        emit StakePositionUpdated(msg.sender, 
        block.timestamp,
        maxLockDuration,
        stakedBalance,
        maxStakeDebt, 
        portalEnergy,
        availableToWithdraw);
    }


    /// @notice Force unstaking via burning portalEnergyToken from user wallet to decrease debt sufficiently
    /// @dev This function allows users to force unstake all their tokens by burning portalEnergyToken from their wallet
    /// @dev It checks if the user has a stake and updates the user's stake data
    /// @dev It calculates how many portalEnergyToken must be burned from the user's wallet, if any
    /// @dev It burns the appropriate portalEnergyToken from the user's wallet to increase portalEnergy sufficiently
    /// @dev It withdraws the principal from the yield source to pay the user
    /// @dev It updates the user's information
    /// @dev It sends the full stake balance to the user
    /// @dev It emits an event with the updated stake information
    function forceUnstakeAll() external nonReentrant existingAccount {
        /// @dev Update the user's stake data
        _updateAccount(msg.sender,0);

        /// @dev Initialize cached variable
        uint256 portalEnergy = accounts[msg.sender].portalEnergy;

        /// @dev Calculate how many portalEnergyToken must be burned from the user's wallet, if any
        if(portalEnergy < accounts[msg.sender].maxStakeDebt) {

            uint256 remainingDebt = accounts[msg.sender].maxStakeDebt - portalEnergy;

            /// @dev Require that the user has enough Portal Energy Tokens
            if(IERC20(portalEnergyToken).balanceOf(address(msg.sender)) < remainingDebt) {revert InsufficientPEtokens();}
            
            /// @dev Burn the appropriate portalEnergyToken from the user's wallet to increase portalEnergy sufficiently
            _burnPortalEnergyToken(msg.sender, remainingDebt);
        }

        /// @dev Withdraw the principal from the yield source to pay the user
        uint256 balance = accounts[msg.sender].stakedBalance;
        uint256 balanceBefore = IERC20(PRINCIPAL_TOKEN_ADDRESS).balanceOf(address(this)); 
        _withdrawFromYieldSource(balance);
        uint256 balanceAfter = IERC20(PRINCIPAL_TOKEN_ADDRESS).balanceOf(address(this));
        uint256 availableAmount = balanceAfter - balanceBefore;

        /// @dev Update the user's stake info
        accounts[msg.sender].stakedBalance = 0;
        accounts[msg.sender].maxStakeDebt = 0;
        portalEnergy = accounts[msg.sender].portalEnergy -= (balance * maxLockDuration * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);
        accounts[msg.sender].availableToWithdraw = 0;

        /// @dev Send the user´s staked balance to the user
        IERC20(PRINCIPAL_TOKEN_ADDRESS).safeTransfer(msg.sender, availableAmount);
        
        /// @dev Update the global tracker of staked principal
        totalPrincipalStaked -= balance;

        /// @dev Emit an event with the updated stake information
        emit StakePositionUpdated(msg.sender, 
        block.timestamp,
        maxLockDuration,
        0,
        0, 
        portalEnergy,
        0);
    }

    // ============================================
    // ==      PRINCIPAL & REWARD MANAGEMENT     ==
    // ============================================
    /// @notice Deposit principal into yield source
    /// @dev This function deposits principal tokens from the Portal into the external protocol
    /// @dev It approves the amount of tokens to be transferred
    /// @dev It transfers the tokens from the Portal to the external protocol via interface
    /// @dev It emits an Event that tokens have been staked
    function _depositToYieldSource(uint256 _amount) private {
        /// @dev Approve the amount to be transferred
        IERC20(PRINCIPAL_TOKEN_ADDRESS).approve(HLP_STAKING, 0);
        IERC20(PRINCIPAL_TOKEN_ADDRESS).approve(HLP_STAKING, _amount);

        /// @dev Transfer the approved balance to the external protocol using the interface
        IStaking(HLP_STAKING).deposit(address(this), _amount);

        /// @dev Emit an event that tokens have been staked for the user
        emit TokenStaked(msg.sender, _amount);
    }


    /// @notice Withdraw principal from yield source into this contract
    /// @dev This function withdraws principal tokens from the external protocol to the Portal
    /// @dev It transfers the tokens from the external protocol to the Portal via interface
    /// @dev It emits an Event that tokens have been unstaked
    /// @param _amount The amount of tokens to withdraw
    function _withdrawFromYieldSource(uint256 _amount) private {

        /// @dev Withdraw the staked balance from external protocol using the interface
        IStaking(HLP_STAKING).withdraw(_amount);

        /// @dev Emit and event that tokens have been unstaked for the user
        emit TokenUnstaked(msg.sender, _amount);
    }


    /// @notice Claim rewards related to HLP and HMX staked by this contract
    /// @dev This function claims staking rewards from the external protocol to the Portal
    /// @dev It transfers the tokens from the external protocol to the Portal via interface
    /// @dev It emits an Event that tokens have been claimed
    function claimRewardsHLPandHMX() external {
        /// @dev Initialize the first input array for the compounder and assign values
        address[] memory pools = new address[](2);
        pools[0] = HLP_STAKING;
        pools[1] = HMX_STAKING;

        /// @dev Initialize the second input array for the compounder and assign values    
        address[][] memory rewarders = new address[][](2);
        rewarders[0] = new address[](2);
        rewarders[0][0] = HLP_PROTOCOL_REWARDER;
        rewarders[0][1] = HLP_EMISSIONS_REWARDER;

        rewarders[1] = new address[](3);
        rewarders[1][0] = HMX_PROTOCOL_REWARDER;
        rewarders[1][1] = HMX_EMISSIONS_REWARDER;
        rewarders[1][2] = HMX_DRAGONPOINTS_REWARDER;

        /// @dev Claim rewards from HLP and HMX staking via the interface
        /// @dev esHMX and DP rewards are staked automatically, USDC is transferred to contract
        ICompounder(COMPOUNDER_ADDRESS).compound(
            pools,
            rewarders,
            HMX_TIMESTAMP,
            HMX_NUMBER,
            new uint256[](0)
        );

        /// @dev Emit event that rewards have been claimed
        emit RewardsClaimed(pools, rewarders, block.timestamp);
    }


    /// @notice If the above claim function breaks in the future, use this function to claim specific rewards
    /// @param _pools The pools to claim rewards from
    /// @param _rewarders The rewarders to claim rewards from
    function claimRewardsManual(address[] memory _pools, address[][] memory _rewarders) external {
        /// @dev claim rewards from any staked token and any rewarder via interface
        /// @dev esHMX and DP rewards are staked automatically, USDC or other reward tokens are transferred to contract
        ICompounder(COMPOUNDER_ADDRESS).compound(
            _pools,
            _rewarders,
            HMX_TIMESTAMP,
            HMX_NUMBER,
            new uint256[](0)
        );

        /// @dev Emit event that rewards have been claimed
        emit RewardsClaimed(_pools, _rewarders, block.timestamp);
    }

    // ============================================
    // ==               INTERNAL LP              ==
    // ============================================
    /// @notice Sell PSM into contract to top up portalEnergy balance
    /// @dev This function allows users to sell PSM tokens to the contract to increase their portalEnergy
    /// @dev It checks if the user has a stake and updates the stake data
    /// @dev It checks if the user has enough PSM tokens
    /// @dev It updates the input token reserve and calculates the reserve of portalEnergy (Output)
    /// @dev It calculates the amount of portalEnergy received based on the amount of PSM tokens sold
    /// @dev It checks if the amount of portalEnergy received is greater than or equal to the minimum expected output
    /// @dev It transfers the PSM tokens from the user to the contract
    /// @dev It increases the portalEnergy of the user by the amount of portalEnergy received
    /// @dev It emits a portalEnergyBuyExecuted event
    /// @param _amountInput The amount of PSM tokens to sell
    /// @param _minReceived The minimum amount of portalEnergy to receive
    function buyPortalEnergy(uint256 _amountInput, uint256 _minReceived, uint256 _deadline) external nonReentrant existingAccount {
        /// @dev Require that the input amount & minimum received is greater than zero
        if (_amountInput == 0) {revert InvalidInput();}
        if (_minReceived == 0) {revert InvalidInput();}

        /// @dev Require that the deadline has not expired
        if (_deadline < block.timestamp) {revert DeadlineExpired();}

        /// @dev Calculate the time passed since the user´s last trade on the internal LP
        uint256 passedTime = block.timestamp - lastTradeTime[msg.sender];

        /// @dev Check that the user has not interacted with the LP recently
        if (passedTime < TRADE_TIMELOCK) {revert TradeTimelockActive();}

        /// @dev Require that the user has enough PSM token to sell
        if(IERC20(PSM_ADDRESS).balanceOf(msg.sender) < _amountInput) {revert InsufficientBalance();}

        /// @dev Calculate the PSM token reserve (input)
        uint256 reserve0 = IERC20(PSM_ADDRESS).balanceOf(address(this)) - fundingRewardPool;

        /// @dev Calculate the reserve of portalEnergy (output)
        uint256 reserve1 = constantProduct / reserve0;

        /// @dev Calculate the amount of portalEnergy received based on the amount of PSM tokens sold
        uint256 amountReceived = (_amountInput * reserve1) / (_amountInput + reserve0);

        /// @dev Require that the amount of portalEnergy received is greater than or equal to the minimum expected output
        if(amountReceived < _minReceived) {revert InvalidOutput();}

        /// @dev Update the user´s last interaction time with the internal LP
        lastTradeTime[msg.sender] = block.timestamp;

        /// @dev Update the stake data of the user
        _updateAccount(msg.sender,0);

        /// @dev Increase the portalEnergy of the user by the amount of portalEnergy received
        accounts[msg.sender].portalEnergy += amountReceived;

        /// @dev Transfer the PSM tokens from the user to the contract
        IERC20(PSM_ADDRESS).safeTransferFrom(msg.sender, address(this), _amountInput);

        /// @dev Emit the portalEnergyBuyExecuted event with the user's address and the amount of portalEnergy received
        emit PortalEnergyBuyExecuted(msg.sender, amountReceived);
    }


    /// @notice Sell portalEnergy into contract to receive PSM
    /// @dev This function allows users to sell their portalEnergy to the contract to receive PSM tokens
    /// @dev It checks if the user has a stake and updates the stake data
    /// @dev It checks if the user has enough portalEnergy to sell
    /// @dev It updates the output token reserve and calculates the reserve of portalEnergy (Input)
    /// @dev It calculates the amount of output token received based on the amount of portalEnergy sold
    /// @dev It checks if the amount of output token received is greater than or equal to the minimum expected output
    /// @dev It reduces the portalEnergy balance of the user by the amount of portalEnergy sold
    /// @dev It sends the output token to the user
    /// @dev It emits a portalEnergySellExecuted event
    /// @param _amountInput The amount of portalEnergy to sell
    /// @param _minReceived The minimum amount of PSM tokens to receive
    function sellPortalEnergy(uint256 _amountInput, uint256 _minReceived, uint256 _deadline) external nonReentrant existingAccount {
        /// @dev Require that the input amount & minimum received is greater than zero
        if (_amountInput == 0) {revert InvalidInput();}
        if (_minReceived == 0) {revert InvalidInput();}   
        
        /// @dev Require that the deadline has not expired
        if (_deadline < block.timestamp) {revert DeadlineExpired();}

        /// @dev Calculate the time passed since the user´s last trade on the internal LP
        uint256 passedTime = block.timestamp - lastTradeTime[msg.sender];

        /// @dev Require that the user has not interacted with the LP recently
        if (passedTime < TRADE_TIMELOCK) {revert TradeTimelockActive();}

        /// @dev Update the stake data of the user
        _updateAccount(msg.sender,0);
        
        /// @dev Require that the user has enough portalEnergy to sell
        if(accounts[msg.sender].portalEnergy < _amountInput) {revert InsufficientBalance();}

        /// @dev Calculate the PSM token reserve (output)
        uint256 reserve0 = IERC20(PSM_ADDRESS).balanceOf(address(this)) - fundingRewardPool;

        /// @dev Calculate the reserve of portalEnergy (input)
        uint256 reserve1 = constantProduct / reserve0;

        /// @dev Calculate the amount of output token received based on the amount of portalEnergy sold
        uint256 amountReceived = (_amountInput * reserve0) / (_amountInput + reserve1);

        /// @dev Require that the amount of output token received is greater than or equal to the minimum expected output
        if(amountReceived < _minReceived) {revert InvalidOutput();}

        /// @dev update the user´s last interaction time with the internal LP
        lastTradeTime[msg.sender] = block.timestamp;

        /// @dev Reduce the portalEnergy balance of the user by the amount of portalEnergy sold
        accounts[msg.sender].portalEnergy -= _amountInput;

        /// @dev Send the output token to the user
        IERC20(PSM_ADDRESS).safeTransfer(msg.sender, amountReceived);

        /// @dev Emit the portalEnergySellExecuted event with the user's address and the amount of portalEnergy sold
        emit PortalEnergySellExecuted(msg.sender, _amountInput);
    }


    /// @notice Simulate buying portalEnergy (output) with PSM tokens (input) and return amount received (output)
    /// @dev This function allows the caller to simulate a portalEnergy buy order of any size
    function quoteBuyPortalEnergy(uint256 _amountInput) external activePortalCheck view returns(uint256) { 
        /// @dev Calculate the PSM token reserve (input)
        uint256 reserve0 = IERC20(PSM_ADDRESS).balanceOf(address(this)) - fundingRewardPool;

        /// @dev Calculate the reserve of portalEnergy (output)
        uint256 reserve1 = constantProduct / reserve0;

        /// @dev Calculate the amount of portalEnergy received based on the amount of PSM tokens sold
        uint256 amountReceived = (_amountInput * reserve1) / (_amountInput + reserve0);

        return (amountReceived);
    }


    /// @notice Simulate selling portalEnergy (input) against PSM tokens (output) and return amount received (output)
    /// @dev This function allows the caller to simulate a portalEnergy sell order of any size
    function quoteSellPortalEnergy(uint256 _amountInput) external activePortalCheck view returns(uint256) {
        /// @dev Calculate the PSM token reserve (output)
        uint256 reserve0 = IERC20(PSM_ADDRESS).balanceOf(address(this)) - fundingRewardPool;

        /// @dev Calculate the reserve of portalEnergy (input)
        uint256 reserve1 = constantProduct / reserve0;

        /// @dev Calculate the amount of PSM tokens received based on the amount of portalEnergy sold
        uint256 amountReceived = (_amountInput * reserve0) / (_amountInput + reserve1);

        return (amountReceived);
    }

    // ============================================
    // ==              PSM CONVERTER             ==
    // ============================================
    /// @notice Handle the arbitrage conversion of tokens inside the contract for PSM tokens
    /// @dev This function handles the conversion of tokens inside the contract for PSM tokens
    /// @dev It checks if the output token is not the input token (PSM)
    /// @dev It checks if output tokens are available in the contract for frontrun protection
    /// @dev It updates the funding reward pool balance and the tracker of collected rewards
    /// @dev It transfers the input (PSM) token from the user to the contract
    /// @dev It transfers the output token from the contract to the user
    /// @param _token The token to convert
    /// @param _minReceived The minimum amount of tokens to receive
    function convert(address _token, uint256 _minReceived, uint256 _deadline) external nonReentrant {
        /// @dev Require that the output token is not the input token (PSM)
        if(_token == PSM_ADDRESS) {revert InvalidToken();}

        /// @dev Require that the deadline has not expired
        if(_deadline < block.timestamp) {revert DeadlineExpired();}

        /// @dev Get the contract balance of the correct token
        uint256 contractBalance;
        if(_token == address(0)) {
        contractBalance = address(this).balance;         
        } else {
        contractBalance = IERC20(_token).balanceOf(address(this));
        }

        /// @dev Check if sufficient output token is available in the contract for frontrun protection
        if(contractBalance < _minReceived) {revert InvalidOutput();}
        if(contractBalance == 0) {revert InvalidOutput();}

        /// @dev Update the funding reward pool balance and the tracker of collected rewards
        if (bToken.totalSupply() > 0 && fundingRewardsCollected < fundingMaxRewards) {
            uint256 newRewards = (FUNDING_REWARD_SHARE * AMOUNT_TO_CONVERT) / 100;
            fundingRewardPool += newRewards;
            fundingRewardsCollected += newRewards;
        }

        /// @dev Transfer the input token (PSM) from the user to the contract
        IERC20(PSM_ADDRESS).safeTransferFrom(msg.sender, address(this), AMOUNT_TO_CONVERT); 

        /// @dev Transfer the output token from the contract to the user
        if(_token == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: contractBalance}("");
            if (!sent) {revert FailedToSendNativeToken();}
        } else {
            IERC20(_token).safeTransfer(msg.sender, contractBalance);
        }
    }

    // ============================================
    // ==              BOOTSTRAPPING             ==
    // ============================================
    /// @notice Allow users to deposit PSM to provide initial upfront yield
    /// @dev This function allows users to deposit PSM tokens during the funding phase of the contract
    /// @dev The contract must be the owner of the specific bToken
    /// @dev It checks if the portal is not already active and if the funding phase is ongoing before proceeding
    /// @dev It increases the funding tracker balance by the amount of PSM deposited
    /// @dev It calculates the amount of bTokens to be minted based on the funding reward rate
    /// @dev It transfers the PSM tokens from the user to the contract
    /// @dev It mints bTokens to the user and emits a FundingReceived event
    /// @param _amount The amount of PSM to deposit
    function contributeFunding(uint256 _amount) external nonReentrant nonActivePortalCheck {
        /// @dev Require that the deposit amount is greater than zero
        if(_amount == 0) {revert InvalidInput();}

        /// @dev Calculate the amount of bTokens to be minted based on the funding reward rate
        uint256 mintableAmount = _amount * FUNDING_REWARD_RATE;

        /// @dev Increase the funding tracker balance by the amount of PSM deposited
        fundingBalance += _amount;

        /// @dev Transfer the PSM tokens from the user to the contract
        IERC20(PSM_ADDRESS).safeTransferFrom(msg.sender, address(this), _amount); 

        /// @dev Mint bTokens to the user
        bToken.mint(msg.sender, mintableAmount);

        /// @dev Emit the FundingReceived event with the user's address and the mintable amount
        emit FundingReceived(msg.sender, mintableAmount);
    }


    /// @notice Calculate the current burn value of amount bTokens. Return value is amount PSM tokens
    /// @param _amount The amount of bTokens to burn
    function getBurnValuePSM(uint256 _amount) public view returns(uint256 burnValue) {
        burnValue = (fundingRewardPool * _amount) / bToken.totalSupply();
    }


    /// @notice Burn user bTokens to receive PSM
    /// @dev This function allows users to burn bTokens to receive PSM during the active phase of the contract
    /// @dev It checks if the portal is active and if the burn amount is greater than zero before proceeding
    /// @dev It calculates how many PSM the user receives based on the burn amount
    /// @dev It burns the bTokens from the user's balance
    /// @dev It reduces the funding reward pool by the amount of PSM payable to the user
    /// @dev It transfers the PSM to the user
    /// @param _amount The amount of bTokens to burn
    function burnBtokens(uint256 _amount) external nonReentrant activePortalCheck {
        /// @dev Require that the burn amount is greater than zero
        if(_amount == 0) {revert InvalidInput();}

        /// @dev Calculate how many PSM the user receives based on the burn amount
        uint256 amountToReceive = getBurnValuePSM(_amount);

        /// @dev Burn the bTokens from the user's balance
        bToken.burnFrom(msg.sender, _amount);

        /// @dev Reduce the funding reward pool by the amount of PSM payable to the user
        fundingRewardPool -= amountToReceive;

        /// @dev Transfer the PSM to the user
        IERC20(PSM_ADDRESS).safeTransfer(msg.sender, amountToReceive);

        /// @dev Event that informs about burn amount and received PSM by the caller
        emit RewardsRedeemed(address(msg.sender), _amount, amountToReceive);
    }


    /// @notice End the funding phase and enable normal contract functionality
    /// @dev This function activates the portal and prepares it for normal operation
    /// @dev It checks if the portal is not already active and if the funding phase is over before proceeding
    /// @dev It calculates the amount of portalEnergy to match the funding amount in the internal liquidity pool
    /// @dev It sets the constant product K, which is used in the calculation of the amount of assets in the liquidity pool
    /// @dev It calculates the maximum rewards to be collected in PSM tokens over time
    /// @dev It activates the portal and emits the PortalActivated event
    /// @dev The PortalActivated event is emitted with the address of the contract and the funding balance
    function activatePortal() external nonActivePortalCheck {
        /// @dev Require that the funding phase is over
        if(block.timestamp < CREATION_TIME + FUNDING_PHASE_DURATION) {revert FundingPhaseOngoing();}

        /// @dev Set the constant product K, which is used in the calculation of the amount of assets in the liquidity pool
        constantProduct = fundingBalance**2 / FUNDING_EXCHANGE_RATIO;

        /// @dev Calculate the maximum rewards to be collected in PSM tokens over time
        fundingMaxRewards = bToken.totalSupply();

        /// @dev Activate the portal  
        isActivePortal = true;

        /// @dev Emit the PortalActivated event with the address of the contract and the funding balance
        emit PortalActivated(address(this), fundingBalance);
    }

    // ============================================
    // ==           GENERAL FUNCTIONS            ==
    // ============================================
    /// @notice Mint portalEnergyToken to recipient and decrease portalEnergy of caller equally
    /// @dev Contract must be owner of the portalEnergyToken
    /// @param _recipient The recipient of the portalEnergyToken
    /// @param _amount The amount of portalEnergyToken to mint
    function mintPortalEnergyToken(address _recipient, uint256 _amount) external nonReentrant {   
        /// @dev Require that the minted amount is greater than zero
        if (_amount == 0) {revert InvalidInput();}  

        /// @dev Require that the recipient is not the zero-address
        if (_recipient == address(0)) {revert InvalidInput();}
        
        /// @dev Get the current portalEnergy of the user
        (, , , , , uint256 portalEnergy,) = getUpdateAccount(msg.sender,0);

        /// @dev Require that the caller has sufficient portalEnergy to mint the amount of portalEnergyToken
        if(portalEnergy < _amount) {revert InsufficientBalance();}

        /// @dev Calculate the time passed since the user´s last trade on the internal LP
        uint256 passedTime = block.timestamp - lastTradeTime[msg.sender];

        /// @dev Check that the user has not interacted with the LP recently
        if (passedTime < TRADE_TIMELOCK) {revert TradeTimelockActive();}

        /// @dev Update the user´s last interaction time with the internal LP
        lastTradeTime[msg.sender] = block.timestamp;

        /// @dev Update the user´s stake data
        _updateAccount(msg.sender,0);

        /// @dev Reduce the portalEnergy of the caller by the amount of portal energy tokens to be minted
        accounts[msg.sender].portalEnergy -= _amount;

        /// @dev Mint portal energy tokens to the recipient's wallet
        portalEnergyToken.mint(_recipient, _amount);

        /// @dev Emit the event that the ERC20 representation has been minted to recipient
        emit PortalEnergyMinted(address(msg.sender), _recipient, _amount);
    }


    /// @notice Burn portalEnergyToken from user wallet and increase portalEnergy of recipient equally
    /// @param _recipient The recipient of the portalEnergy increase
    /// @param _amount The amount of portalEnergyToken to burn
    function burnPortalEnergyToken(address _recipient, uint256 _amount) external nonReentrant {   
        /// @dev Require that the burned amount is greater than zero
        if (_amount == 0) {revert InvalidInput();}  
        
        /// @dev Require that the recipient has a stake position
        if(accounts[_recipient].isExist == false) {revert AccountDoesNotExist();}

        /// @dev Require that the caller has sufficient tokens to burn
        if(portalEnergyToken.balanceOf(address(msg.sender)) < _amount) {revert InsufficientBalance();}

        /// @dev Calculate the time passed since the user´s last trade on the internal LP
        uint256 passedTime = block.timestamp - lastTradeTime[msg.sender];

        /// @dev Check that the user has not interacted with the LP recently
        if (passedTime < TRADE_TIMELOCK) {revert TradeTimelockActive();}

        /// @dev Update the user´s last interaction time with the internal LP
        lastTradeTime[msg.sender] = block.timestamp;

        /// @dev Increase the portalEnergy of the recipient by the amount of portalEnergyToken burned
        accounts[_recipient].portalEnergy += _amount;

        /// @dev Burn portalEnergyToken from the caller's wallet
        portalEnergyToken.burnFrom(msg.sender, _amount);

        /// @dev Emit the event that the ERC20 representation has been burned and value accrued to recipient
        emit PortalEnergyBurned(address(msg.sender), _recipient, _amount);
    }


    /// @notice Burn portalEnergyToken from user wallet and increase portalEnergy of user equally
    /// @dev This function is private and can only be called internally
    /// @param _user The user whose portalEnergy is to be increased
    /// @param _amount The amount of portalEnergyToken to burn
    function _burnPortalEnergyToken(address _user, uint256 _amount) private {   
        /// @dev Calculate the time passed since the user´s last trade on the internal LP
        uint256 passedTime = block.timestamp - lastTradeTime[msg.sender];

        /// @dev Check that the user has not interacted with the LP recently
        if (passedTime < TRADE_TIMELOCK) {revert TradeTimelockActive();}

        /// @dev Update the user´s last interaction time with the internal LP
        lastTradeTime[msg.sender] = block.timestamp;

        /// @dev Burn portalEnergyToken from the caller's wallet
        portalEnergyToken.burnFrom(_user, _amount);

        /// @dev Increase the portalEnergy of the user by the amount of portalEnergyToken burned
        accounts[_user].portalEnergy += _amount;
    }


    /// @notice Update the maximum lock duration up to the terminal value
    function updateMaxLockDuration() external {
        /// @dev Require that the lock duration can be updated        
        if(lockDurationUpdateable == false) {revert DurationLocked();}

        /// @dev Calculate new lock duration
        uint256 newValue = 2 * (block.timestamp - CREATION_TIME);

        /// @dev Require that the new value will be larger than the existing value
        if(newValue <= maxLockDuration) {revert DurationCannotIncrease();}

        if(newValue >= TERMINAL_MAX_LOCK_DURATION) {
            maxLockDuration = TERMINAL_MAX_LOCK_DURATION;
            lockDurationUpdateable = false;
        } 
        else if (newValue > maxLockDuration) {
            maxLockDuration = newValue;
        }
    }


    /// @notice Simulate updating a user stake position and return the values without updating the struct
    /// @param _user The user whose stake position is to be updated
    /// @param _amount The amount to add to the user's stake position
    /// @dev Returns the simulated up-to-date user stake information
    function getUpdateAccount(address _user, uint256 _amount) public view returns(
        address user,
        uint256 lastUpdateTime,
        uint256 lastMaxLockDuration,
        uint256 stakedBalance,
        uint256 maxStakeDebt,
        uint256 portalEnergy,
        uint256 availableToWithdraw) {

        /// @dev Check if the queried user has an account and revert if not
        if (!accounts[_user].isExist) {
            revert AccountDoesNotExist();
        }

        /// @dev Calculate the portalEnergy earned since the last update
        uint256 portalEnergyEarned = (accounts[_user].stakedBalance * 
            (block.timestamp - accounts[_user].lastUpdateTime) * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);
      
        /// @dev Calculate the increase of portalEnergy due to balance increase
        uint256 portalEnergyIncrease = ((accounts[_user].stakedBalance * (maxLockDuration - 
            accounts[_user].lastMaxLockDuration) + (_amount * maxLockDuration)) * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);

        /// @dev Set the last update time to the current timestamp
        lastUpdateTime = block.timestamp;

        /// @dev Get the updated last maxLockDuration
        lastMaxLockDuration = maxLockDuration;

        /// @dev Calculate the user's staked balance
        stakedBalance = accounts[_user].stakedBalance + _amount;

        /// @dev Update the user's max stake debt
        maxStakeDebt = (stakedBalance * maxLockDuration * 1e18) / (SECONDS_PER_YEAR * DECIMALS_ADJUSTMENT);

        /// @dev Update the user's portalEnergy by adding the portalEnergy earned since the last update
        portalEnergy = accounts[_user].portalEnergy + portalEnergyEarned + portalEnergyIncrease;

        /// @dev Update the amount available to unstake based on the updated portalEnergy and max stake debt
        if (portalEnergy >= maxStakeDebt) {
            availableToWithdraw = stakedBalance;
        } else {
            availableToWithdraw = (stakedBalance * portalEnergy) / maxStakeDebt;
        }

        /// @dev Set the user for the return values
        user = _user;
    }


    /// @notice Simulate forced unstake and return the number of portal energy tokens to be burned      
    /// @param _user The user whose stake position is to be updated for the simulation
    /// @return portalEnergyTokenToBurn Returns the number of portal energy tokens to be burned for a full unstake
    function quoteforceUnstakeAll(address _user) external view returns(uint256 portalEnergyTokenToBurn) {

        /// @dev Get the relevant data from the simulated account update
        (, , , , uint256 maxStakeDebt, uint256 portalEnergy,) = getUpdateAccount(_user,0);

        /// @dev Calculate how many portal energy tokens must be burned for a full unstake
        if(maxStakeDebt > portalEnergy) {
            portalEnergyTokenToBurn = maxStakeDebt - portalEnergy;
        }
    }


    /// @notice View balance of tokens inside the contract
    /// @param _token The token for which the balance is to be checked
    /// @return Returns the balance of the specified token inside the contract
    function getBalanceOfToken(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }


    /// @notice View claimable yield from a specific rewarder contract of the yield source
    /// @dev This function allows you to view the claimable yield from a specific rewarder contract of the yield source
    /// @param _rewarder The rewarder contract whose pending reward is to be viewed
    function getPendingRewards(address _rewarder) external view returns(uint256 claimableReward){
        claimableReward = IRewarder(_rewarder).pendingReward(address(this));
    }


    receive() external payable { }
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IRewarder {
    // Call a specific reward contract to get the claimable reward for a specific staker
    function pendingReward(address _claimer) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface ICompounder {

    function compound(
        address[] memory pools,
        address[][] memory rewarders,
        uint256 startEpochTimestamp,
        uint256 noOfEpochs,
        uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IStaking {
    function deposit(address _to, uint256 _amount) external;

    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MintBurnToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor(
        address initialOwner,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(initialOwner) ERC20Permit(name) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.19;

import {IERC20Permit} from "./IERC20Permit.sol";
import {ERC20} from "../ERC20.sol";
import {ECDSA} from "../../../utils/cryptography/ECDSA.sol";
import {EIP712} from "../../../utils/cryptography/EIP712.sol";
import {Nonces} from "../../../utils/Nonces.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712, Nonces {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Permit deadline has expired.
     */
    error ERC2612ExpiredSignature(uint256 deadline);

    /**
     * @dev Mismatched signature.
     */
    error ERC2612InvalidSigner(address signer, address owner);

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        _approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.19;

import {ERC20} from "../ERC20.sol";
import {Context} from "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, deducting from
     * the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     */
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.19;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.19;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Nonces.sol)
pragma solidity ^0.8.19;

/**
 * @dev Provides tracking nonces for addresses. Nonces will only increment.
 */
abstract contract Nonces {
    /**
     * @dev The nonce used for an `account` is not the expected current nonce.
     */
    error InvalidAccountNonce(address account, uint256 currentNonce);

    mapping(address account => uint256) private _nonces;

    /**
     * @dev Returns the next unused nonce for an address.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(address owner) internal virtual returns (uint256) {
        // For each account, the nonce has an initial value of 0, can only be incremented by one, and cannot be
        // decremented or reset. This guarantees that the nonce never overflows.
        unchecked {
            // It is important to do x++ and not ++x here.
            return _nonces[owner]++;
        }
    }

    /**
     * @dev Same as {_useNonce} but checking that `nonce` is the next valid for `owner`.
     */
    function _useCheckedNonce(address owner, uint256 nonce) internal virtual {
        uint256 current = _useNonce(owner);
        if (nonce != current) {
            revert InvalidAccountNonce(owner, current);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.19;

import {MessageHashUtils} from "./MessageHashUtils.sol";
import {ShortStrings, ShortString} from "../ShortStrings.sol";
import {IERC5267} from "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding scheme specified in the EIP requires a domain separator and a hash of the typed structured data, whose
 * encoding is very generic and therefore its implementation in Solidity is not feasible, thus this contract
 * does not implement the encoding itself. Protocols need to implement the type-specific encoding they need in order to
 * produce the hash of their typed data using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the {_domainSeparatorV4} function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {IERC-5267}.
     */
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _name which is an immutable value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    function _EIP712Name() internal view returns (string memory) {
        return _name.toStringWithFallback(_nameFallback);
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _version which is an immutable value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     */
    // solhint-disable-next-line func-name-mixedcase
    function _EIP712Version() internal view returns (string memory) {
        return _version.toStringWithFallback(_versionFallback);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.19;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.19;

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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.19;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.19;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.19;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.19;

import {StorageSlot} from "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using
     * {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.19;

import {Strings} from "../Strings.sol";

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return
            keccak256(bytes.concat("\x19Ethereum Signed Message:\n", bytes(Strings.toString(message.length)), message));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.19;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.19;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}