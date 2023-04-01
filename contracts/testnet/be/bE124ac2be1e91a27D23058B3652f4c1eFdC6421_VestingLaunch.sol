// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import "../lib/OwnableAdmin.sol";
import {UD60x18, div} from "../lib/prb-math-3/UD60x18.sol";
import {mulDiv} from "../lib/prb-math-3/Core.sol";
import "../lib/SafeERC20.sol";
import "../lib/int/IERC20.sol";
import "../lib/int/ILaunchTreasury.sol";
import "../lib/int/IRegistry.sol";
import "../utils/PricerLib.sol";

contract VestingLaunch is OwnableAdmin {
    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    event Deposited(
        uint256 deposit,
        uint256 payout,
        uint256 expires,
        uint256 tier
    );
    event Redeemed(
        address recipient,
        uint256 payout,
        uint256 remaining,
        uint256 tier
    );
    event LiquidityAdded(
        uint256 amountLiqPayin,
        uint256 amountLiqPayout,
        uint256 amountLP
    );

    /* ======== STATE VARIABLES ======== */

    IERC20 public immutable payoutToken; // token paid for payinToken
    IERC20 public immutable payinToken; // inflow token
    ILaunchTreasury public immutable customTreasury; // pays for and receives payinToken
    IRegistry public immutable MizuRegistry; // registry where Mizu stores data
    address public immutable factory; // address of the MizuFactory
    address public quoteToken; // token used to calculate launch payin/payout ratio (IE. WETH / USDC)
    address public Router; // the router of the dex pair (used for calculations)
    uint256 public minBonus; // in thousandths of a %. i.e. 500 = 0.5% of bonus if isPriceVariable = true
    //I.E. bonus= 7% & minBonus = 50000 bonus= 3500;
    bool public isPriceVariable; // does the price scale with launch deposits/hardcap ratio?
    uint256 public slippageRatio; // amountIn*slippageRatio/100000 when calculating payout ratio
    uint[4] public tiersPayinDeposited; // tracks payin deposited in the launch
    uint256 public totalPayoutGiven; // tracks payout withdrawn from treasury
    Tiers public tiers; // stores launch tiers
    mapping(address => Deposits) public depositsInfo; // stores launch information for depositors
    address public receivingAddress; //store the address of lp receiver
    uint256 public startingBlock; // starting block when users can start depositing
    uint256 public softCapBlock; // block at wich softcap needs to get hit to continue
    uint256 public softCapAmount; // amount of tokens to hit softcap and start adding liquidity
    uint256 public initialPrice; // ratio to start adding tokens (500 = 1 payinToken = 500 payoutTokens)
    uint256 public liquidityPercentage; // 1000 = 100%
    bool public firstLiquidityAdded; // tells wether liquidity has been  already added
    bool public isWhitelistActive; // wheter the launch uses whitelist
    mapping(address => mapping(uint => bool)) public whitelisted; // address => tier => isWhitelisted?

    /* ======== STRUCTS ======== */

    // Info for launch tiers
    struct Tiers {
        uint256[4] vestingTerms; // in blocks
        uint256[4] bonus; // 1000/100000 = 1%
        uint256[4] hardCap; // maximum amount of payoutToken to be payout to depositors
        uint256[4] minDeposit; // minimum amount of payintokens to enter the launch tier
        uint256[4] maxDeposit; // maximum amount of payintokens each user can deposit
        uint256 number; // 0 used only to use arrays in the struct
    }

    // Info for depositors
    struct Deposits {
        uint256[4] payout; // payout token remaining to be paid
        uint256[4] vesting; // Blocks left to vest
        uint256[4] lastBlocks; // Last interaction for each tier
        uint256[4] payinAmount; //amount of payinTokens deposited, used to redeem them if launch fail
        uint256 nonce; // tracks how many deposits user makes
    }

    /* ======== AFFILIATE ======== */

    address public Affiliate; //tracks affiliate address
    uint256 public AffiliateEarnings; //tracks affiliate earnings

    /**
     * @notice send the affiliate its earnings
     */
    function claimAffiliate() external {
        require(
            getStage() >= 3 && totalPayinDeposited() >= softCapAmount,
            "need softcap"
        );
        require(AffiliateEarnings > 0, "0 fees");
        uint256 earnings = AffiliateEarnings;
        AffiliateEarnings = 0;
        payinToken.safeTransfer(Affiliate, earnings);
    }

    /* ======== REFERRAL ======== */

    uint256 public totalReffererEarnings; //tracks the total referrer earnings before reaching softcap
    mapping(address => uint256) public ReferralEarnings; //maps the earnings of each referral

    /**
     * @notice send the referrer its earnings
     * @param  _referrer  the address of the referrer.
     */
    function claimReferral(address _referrer) external {
        require(
            getStage() >= 3 && totalPayinDeposited() >= softCapAmount,
            "need softcap"
        );
        require(ReferralEarnings[_referrer] > 0, "0 fees");
        uint256 earnings = ReferralEarnings[_referrer];
        delete ReferralEarnings[_referrer];
        payinToken.safeTransfer(_referrer, earnings);
    }

    /* ======== CONSTRUCTOR ======== */

    constructor(
        address _customTreasury,
        address _payoutToken,
        address _payinToken,
        address _initialOwner,
        address _registry,
        address _affiliate,
        address _quoteToken,
        address _router,
        address _receiver
    ) OwnableAdmin(_initialOwner) {
        require(_customTreasury != address(0));
        customTreasury = ILaunchTreasury(_customTreasury);
        require(_payoutToken != address(0));
        payoutToken = IERC20(_payoutToken);
        require(_payinToken != address(0));
        payinToken = IERC20(_payinToken);
        require(_initialOwner != address(0));
        admin = _initialOwner;
        require(_registry != address(0));
        MizuRegistry = IRegistry(_registry);
        require(_quoteToken != address(0));
        quoteToken = _quoteToken;
        require(_router != address(0));
        Router = _router;
        receivingAddress = _receiver;

        if (MizuRegistry.AffWhitelist(_affiliate)) {
            Affiliate = _affiliate;
        } else {
            Affiliate = address(0);
        }
        slippageRatio = 100; //set the slippageRatio at 0.1% of amountIn
        // it is mainly useful for small pairs and allows bigger deposit sizes
        // if you want to have a the launch token price accounting the real price impact
        //set it at 100000 calling setSlippageRate...
        factory = msg.sender;

        //approve the router for max in order to add liquidity
        IERC20(_payinToken).safeApprove(_router, 2 ** 256 - 1);
        IERC20(_payoutToken).safeApprove(_router, 2 ** 256 - 1);
    }

    /* ======== ADMIN FUNCTIONS ======== */

    /**
     * @notice Initialize the launch and set up the bonus tiers, can only be called by admin.
     * @param _tiers The bonus tiers to be used for the launch
     * @param _minBonus The minimum bonus that can be reached if isVariable = true
     * @param _isVariable Boolean indicating whether the bonus is variable
     * @param _startingBlock The block number at which the launch will start
     * @param _softCapBlock The block number at which the launch need to reach its soft cap
     * @param _softCapAmount The amount of payinToken required to reach the soft cap
     * @param _initialPrice The initial payout token price
     * @param _liquidityPercentage The percentage of deposits that will be used for liquidity
     * @param _isWhitelistActive Boolean indicating whether the whitelist is active
     */
    function initialize(
        Tiers calldata _tiers,
        uint _minBonus,
        bool _isVariable,
        uint256 _startingBlock,
        uint256 _softCapBlock,
        uint256 _softCapAmount,
        uint256 _initialPrice,
        uint256 _liquidityPercentage,
        bool _isWhitelistActive
    ) external onlyAdmin {
        if (startingBlock != 0) {
            require(getStage() <= 1 && block.number < (startingBlock - 100)); //check that launch isnt started
        }

        isPriceVariable = _isVariable;
        minBonus = _minBonus;
        tiers = _tiers;
        startingBlock = _startingBlock;
        softCapBlock = _softCapBlock;
        softCapAmount = _softCapAmount;
        initialPrice = _initialPrice;
        liquidityPercentage = _liquidityPercentage;
        isWhitelistActive = _isWhitelistActive;
    }

    /**
     * @dev allows the admin to update the launch parameters before the launch.
     * @param _minBonus uint in thousandths of a %. i.e. 500 = 0.5% of bonus if isPriceVariable = true
     * @param _isVariable bool Whether or not the launch bonus is variable.
     * @param _startingBlock uint256 The block at which the launch will start.
     * @param _softCapBlock uint256 The block at which the soft cap need to be reached.
     * @param _softCapAmount uint256 The amount at which the soft cap will be reached.
     * @param _initialPrice uint256 The initial price of the payout tokens.
     * @param _liquidityPercentage uint256 The % of deposit allocated to liquidity.
     */
    function updateLaunchParameters(
        uint _minBonus,
        bool _isVariable,
        uint256 _startingBlock,
        uint256 _softCapBlock,
        uint256 _softCapAmount,
        uint256 _initialPrice,
        uint256 _liquidityPercentage
    ) external onlyAdmin {
        require(getStage() <= 1 && block.number < (startingBlock - 100)); //check that launch isnt started
        isPriceVariable = _isVariable;
        minBonus = _minBonus;
        softCapBlock = _softCapBlock;
        startingBlock = _startingBlock;
        softCapAmount = _softCapAmount;
        initialPrice = _initialPrice;
        liquidityPercentage = _liquidityPercentage;
    }

    /**
     * @notice allows the admin to update the vesting terms, bonus,
     * hard cap, minimum deposit, and maximum deposit for each tier
     * @dev is only callable by admin and the the block < than startingBlock - 100
     * @param _vestingTerms an array with 4 uints representing vesting terms for each tier
     * @param _bonus an array with 4 uints representing bonus for each tier
     * @param _hardCap an array with 4 uints representing hard cap for each tier
     * @param _minDeposit an array with 4 uints representing min deposit for each tier
     * @param _maxDeposit an array with 4 uints representing user max deposit for each tier
     */
    function updateTiers(
        uint256[4] memory _vestingTerms,
        uint256[4] calldata _bonus,
        uint256[4] calldata _hardCap,
        uint256[4] calldata _minDeposit,
        uint256[4] calldata _maxDeposit
    ) external onlyAdmin {
        require(getStage() <= 1 && block.number < (startingBlock - 100));
        tiers = Tiers({
            vestingTerms: _vestingTerms,
            bonus: _bonus,
            hardCap: _hardCap,
            minDeposit: _minDeposit,
            maxDeposit: _maxDeposit,
            number: 0
        });
    }

    /**
     *  @notice update the affiliate of the launch if it wasn't registered on creation
     *  @dev can only be used by MizuDao saved in the MizuRegistry contract
     *  @param _affiliate address the address of the affiliate
     */
    function setAffiliate(address _affiliate) external {
        require(msg.sender == MizuRegistry.MizuDao(), "not Mizu");
        Affiliate = _affiliate;
    }

    /**
     *  @notice update the slippageRatio in thousandths of a %. i.e. 500 = 0.5%
     *  @notice used for launch token price calculations decreasing the deposit amountIn
     *  @dev set 100% to use actual price impact for amountIn when depositing
     *  @param _slippageRatio uint
     */
    function setSlippageRatio(uint256 _slippageRatio) external onlyAdmin {
        //reduce _amountIn to allow larger deposits
        require(_slippageRatio <= 100000, "!100%"); // 100% = 100000
        slippageRatio = _slippageRatio; // update state variable
    }

    /**
     *  @notice update the quotetoken address used as intermediate for calculating payin/payout ratio
     *  @dev be sure that both tokens have a pair with quoteToken before updating
     *  @param _newQuoteToken address
     */
    function updateQuoteToken(address _newQuoteToken) external onlyAdmin {
        require(_newQuoteToken != address(0));
        quoteToken = _newQuoteToken; // update state variable
    }

    /**
     *  @notice recover tokens balance in case it get stuck
     *  @dev to protect users positions, you cant withdraw payoutToken
     *  @dev you can withdraw tokens if launch fails
     */
    function recoverTokens(address _token) external onlyAdmin {
        require(_token != address(payinToken)); //protect users payinTokens that can be redeeme if launch fails
        if (getStage() == 4 && totalPayinDeposited() < softCapAmount) {
            //if launch failed allow withdrawing payoutTokens
            IERC20(_token).safeTransfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
        } else {
            require(_token != address(payoutToken)); // if launch didnt fail protect users redeemable tokens
            IERC20(_token).safeTransfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    /**
     *  @notice set the address where lp will be sent
     *  @dev set address(0) to burn or external timelock for locked liquidity
     *  @param _receivingAddress address where LP will be sent
     */
    function setReceiver(address _receivingAddress) external onlyAdmin {
        require(getStage() < 2, "started"); // allow to change receiver only before launch starts
        receivingAddress = _receivingAddress;
    }

    /**
     * @notice Set the whitelisted status for a list of addresses.
     * @dev This function can only be called by the contract owner.
     * @param _address The list of addresses to be whitelisted.
     * @param _isWhitelisted The list of whitelisted status for the corresponding address.
     * @param _maxTier The list of the max tier for the corresponding address.
     */
    function setWhitelistedAddresses(
        address[] calldata _address,
        bool[] calldata _isWhitelisted,
        uint[] calldata _maxTier
    ) external onlyAdmin {
        require(
            _address.length == _isWhitelisted.length &&
                _isWhitelisted.length == _maxTier.length
        );
        for (uint256 i = 0; i < _address.length; i++) {
            require(_address[i] != address(0));
            for (uint256 tier = 0; tier <= _maxTier[i]; tier++) {
                whitelisted[_address[i]][tier] = _isWhitelisted[i];
            }
        }
    }

    /**
     * @notice Deactivates whitelist making the launch public
     * @dev This function can only be called by the admin.
     * @dev BE CAREFUL BECAUSE IT CAN'T BE REACTIVATED
     */
    function deactivateWhitelist() external onlyAdmin {
        require(isWhitelistActive);
        isWhitelistActive = false;
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit for depositor, calculate payout and add liquidity
     *  @param _amount uint the amount of payinToken to be sent to the launch
     *  @param _depositor address the address that will be able to redeem the payout
     *  @param _referrer address of the referrer
     *  @param _tier uint the ID of the tier, bonus and hardCap to be used
     *  @param _minBonus uint the minimum bonus to receive, if bonus < _minBonus reverts
     *  @return uint amount of payout token that depositor will be able to redeem
     */
    function deposit(
        uint256 _amount,
        address _depositor,
        address _referrer,
        uint256 _tier,
        uint256 _minBonus
    ) external returns (uint256) {
        if (isWhitelistActive) {
            require(checkWhitelist(_depositor, _tier), "not whitelisted");
        }
        require(getStage() > 1, "not started"); // only works when launch is started and not finished
        require(getStage() < 4, "ended");
        require(_amount >= tiers.minDeposit[_tier], "too small");
        require(_depositor != address(0), "Invalid address");
        require(tiers.hardCap[_tier] > 0, "Tier not set");

        uint256 payout = getPayout(_amount, _tier); // payout for depositor is computed

        require(
            payout >= 10 ** payoutToken.decimals() / 100,
            "too small"
        ); // must be > 0.01 payout token ( underflow protection )

        require(getBonus(_tier) >= _minBonus); //check if bonus received is higher than _minBonus (slippage protection)
        // fees are calculated
        (uint256 fee, uint256 refFee, uint256 affFee) = actualFee(
            _amount,
            _referrer
        );
        //the actual amount used to add liquidity (amountIn - fees)
        uint256 depositAmount = _amount - (fee + (refFee + (affFee)));

        //calculate the amount of tokens to withdraw from treasury to add liquidity
        uint256 amtLiquidity = getLpQuote(
            ((depositAmount * liquidityPercentage) / 1000),
            IUniswapV2Router01(Router).factory()
        );

        if (refFee > 0 && _referrer != address(0)) {
            ReferralEarnings[_referrer] += (refFee); // update referrer earnings
            if (getStage() < 3) {
                totalReffererEarnings += refFee; //track total ref fees if soft cap not reached
            }
        }
        if (Affiliate != address(0) && affFee > 0) {
            AffiliateEarnings = AffiliateEarnings + (affFee); // update affiliate earnings
        }

        // total deposit is increased
        tiersPayinDeposited[_tier] += (_amount);
        // depositor info is stored
        (depositsInfo[_depositor].payout[_tier]) += (payout);
        (depositsInfo[_depositor].vesting[_tier]) = tiers.vestingTerms[_tier];
        (depositsInfo[_depositor].lastBlocks[_tier]) =
            block.number +
            (softCapBlock - startingBlock);
        depositsInfo[_depositor].payinAmount[_tier] += _amount;
        depositsInfo[_depositor].nonce += 1;
        require(
            depositsInfo[_depositor].payinAmount[_tier] <=
                tiers.maxDeposit[_tier],
            "maxDeposit reached"
        );
        // increase total payout given to protect users funds before adding liquidity
        totalPayoutGiven += payout; // total payout increased
        require(
            tiers.maxDeposit[_tier] <= tiers.hardCap[_tier],
            "tier hardcap"
        );
        require(totalPayinDeposited() <= totalHardCap(), "total hardcap");
        /**
         * payinToken is transferred in
         * approved and
         * added as liquidity and sent to receivingAddress
         */
        payinToken.safeTransferFrom(msg.sender, address(this), _amount);
        //withdraw from treasury the payout and amount of liquidity tokens needed
        uint256 amountTreasury = depositAmount -
            ((depositAmount * liquidityPercentage) / 1000);
        if (getStage() <= 3 && !firstLiquidityAdded) {
            // before hitting soft cap keep accumulating payin in launch contract
            customTreasury.deposit(
                address(payinToken),
                0,
                payout,
                amtLiquidity
            );
            //save the depositor deposited amount to allow redeem of it if launch fails
        } else {
            payinToken.approve(address(customTreasury), amountTreasury);
            customTreasury.deposit(
                address(payinToken),
                amountTreasury,
                payout,
                amtLiquidity
            );
        }

        if (fee != 0 && firstLiquidityAdded) {
            // fee is transferred to dao
            payinToken.safeTransfer(getMizuTreasury(), fee);
        }

        addLiquidity(
            ((depositAmount * liquidityPercentage) / 1000),
            amtLiquidity
        );

        // indexed events are emitted
        emit Deposited(
            _amount,
            payout,
            block.number +
                (tiers.vestingTerms[_tier] + (softCapBlock - startingBlock)),
            _tier
        );

        require(
            totalPayinDeposited() <= totalHardCap(),
            "hardcap"
        );

        return payout;
    }

    /**
     *  @notice redeem payout for depositor for a specific _tier
     *  @param _depositor address of the depositor
     *  @param _tier uint the tier for the deposit to be redeemed
     *  @return uint amount of tokens redeemed
     */
    function redeem(
        address _depositor,
        uint256 _tier
    ) external returns (uint256) {
        if (getStage() == 4 && totalPayinDeposited() < softCapAmount) {
            // if launch fails users can redeem payin
            uint256 amount;
            for (uint256 i = 0; i < tiers.vestingTerms.length; i++) {
                amount += depositsInfo[_depositor].payinAmount[i];
                // delete records of payinAmount of depositor
                delete depositsInfo[_depositor].payinAmount[i];
            }
            //send the depositor its payinAmount
            payinToken.safeTransfer(_depositor, amount);
            return amount;
        } else {
            // redeem vested payout
            uint256 percentVested = percentVestedFor(_depositor, _tier); // (blocks since last interaction / vesting term remaining)

            if (percentVested >= 10000) {
                // if fully vested
                uint256 payout = depositsInfo[_depositor].payout[_tier];

                // delete user info but mantain payinAmount to be able to force maxDeposit
                delete depositsInfo[_depositor].payout[_tier];
                delete depositsInfo[_depositor].vesting[_tier];
                delete depositsInfo[_depositor].lastBlocks[_tier];

                emit Redeemed(
                    _depositor,
                    depositsInfo[_depositor].payout[_tier],
                    0,
                    _tier
                ); // emit redeem data
                payoutToken.safeTransfer(
                    _depositor,
                    depositsInfo[_depositor].payout[_tier]
                );
                return payout;
            } else {
                // if unfinished
                // calculate payout vested
                uint256 payout = (depositsInfo[_depositor].payout[_tier] *
                    (percentVested)) / (10000);

                depositsInfo[_depositor].payout[_tier] =
                    depositsInfo[_depositor].payout[_tier] -
                    (payout);

                depositsInfo[_depositor].vesting[_tier] =
                    depositsInfo[_depositor].vesting[_tier] -
                    (block.number -
                        (depositsInfo[_depositor].lastBlocks[_tier]));

                depositsInfo[_depositor].lastBlocks[_tier] = block.number;
                // store updated deposit info

                emit Redeemed(
                    _depositor,
                    payout,
                    depositsInfo[_depositor].payout[_tier],
                    _tier
                );
                payoutToken.safeTransfer(_depositor, payout);
                return payout;
            }
        }
    }

    /**
     *  @notice calculates the fees for MizuDao, affiliate, referrer
     */
    function actualFee(
        uint256 _amount,
        address _referrer
    )
        internal
        view
        returns (uint256 mizuFee_, uint256 refFee_, uint256 affFee_)
    {
        uint256 fee = (_amount * (currentMizuFee())) / (1e6);
        uint256 refPerc = MizuRegistry.getRefPerc(_referrer);
        if (Affiliate == address(0)) {
            affFee_ = 0;
        } else {
            uint256 affPerc = MizuRegistry.getAffiliate(Affiliate);
            affFee_ = (fee * (affPerc)) / (1e6);
        }
        if (_referrer == address(0)) {
            refFee_ = 0;
        } else {
            refFee_ = (fee * (refPerc)) / (1e6);
        }
        mizuFee_ = fee - (refFee_ + (affFee_));
        return (mizuFee_, refFee_, affFee_);
    }

    /**
     *  @notice used to calculate amount of liquidity tokens to withdraw from treasury
     */
    function getLpQuote(
        uint256 _payinAmount,
        address _factory
    ) internal view returns (uint256) {
        if (getStage() > 2) {
            (uint256 reservePayin, uint256 reservePayout) = UniswapV2Library
                .getReserves(
                    _factory,
                    address(payinToken),
                    address(payoutToken)
                );
            return
                UniswapV2Library.quote(
                    _payinAmount,
                    reservePayin,
                    reservePayout
                );
        } else {
            return mulDiv(_payinAmount, initialPrice, 1e18);
        }
    }

    /**
     *  @notice performs addLiquidity operations using router
     *  @dev if your token have tax fees, exclude launch, treasury and router from fees
     */
    function addLiquidity(
        uint256 amountPayin,
        uint256 amountPayout
    )
        private
        returns (uint256 amountPayin_, uint256 amountPayout_, uint256 amountLP_)
    {
        if (getStage() < 3) {
            // dont do nothing until stage 3 and keep accumulating funds
            return (0, 0, 0);
        } else if (getStage() == 3 && !firstLiquidityAdded) {
            //add liquidity, send fees to mizu, send payin to treasury
            // the balance of payin tokens accumulated
            uint256 payinBalance = payinToken.balanceOf(address(this));
            //calculate mizu fees
            uint256 mizuFee = (payinBalance * currentMizuFee()) / 1_000_000;
            // remove the fees from the payinTokens accumulated
            payinBalance -= mizuFee;
            //
            uint256 firstLiqPayinAmount = (payinBalance * liquidityPercentage) /
                1000;

            uint256 treasuryAmount = payinBalance - firstLiqPayinAmount;

            // sets the state variable to stop accumulating and add liquidity with any deposit
            firstLiquidityAdded = true;

            //send tokens to the treasury
            payinToken.safeTransfer(address(customTreasury), treasuryAmount);
            // remove affiliate and referral earnings from Mizu fees
            mizuFee -= totalReffererEarnings + AffiliateEarnings;
            //send fees to mizu
            payinToken.safeTransfer(getMizuTreasury(), mizuFee);

            // add liquidity and send LP to receivingAddress
            (amountPayin_, amountPayout_, amountLP_) = IUniswapV2Router01(
                Router
            ).addLiquidity(
                    address(payinToken),
                    address(payoutToken),
                    firstLiqPayinAmount,
                    // remove depositor payout from balance to ensure depositors tokens dont get touched
                    payoutToken.balanceOf(address(this)) - totalPayoutGiven,
                    0,
                    0,
                    receivingAddress,
                    block.timestamp
                );
            emit LiquidityAdded(amountPayin_, amountPayout_, amountLP_);
        } else {
            // add liquidity with market price
            (amountPayin_, amountPayout_, amountLP_) = IUniswapV2Router01(
                Router
            ).addLiquidity(
                    address(payinToken),
                    address(payoutToken),
                    amountPayin,
                    amountPayout,
                    0,
                    0,
                    receivingAddress,
                    block.timestamp
                );
            emit LiquidityAdded(amountPayin_, amountPayout_, amountLP_);
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     * @dev Returns the total amount of funds deposited into the contract
     * @return total_ uint The total amount of funds deposited into the contract
     */
    function totalPayinDeposited() public view returns (uint256 total_) {
        for (uint256 i = 0; i < tiersPayinDeposited.length; i++) {
            total_ += tiersPayinDeposited[i];
        }
    }

    /**
     * @notice Returns the total hard cap of all tiers for the launch
     * @dev The total hard cap is determined by summing the hard caps of all tiers
     * @return hardCap_ uint The total hard cap of all tiers
     */
    function totalHardCap() public view returns (uint256 hardCap_) {
        for (uint256 i = 0; i < tiers.vestingTerms.length; i++) {
            hardCap_ += tiers.hardCap[i];
        }
    }

    /**
     * @notice Gets the current stage of the launch.
     * @return stage_ Returns a uint256 indicating the current stage:
     * 0 - not initialized;
     * 1 - not started but initialized;
     * 2 - launch started;
     * 3 - soft cap reached;
     * 4 - launch ended because either hardcap is reached or softcap target is not hit in time.
     */
    function getStage() public view returns (uint256 stage_) {
        if (startingBlock == 0) {
            stage_ = 0; // not initialized
        } else if (block.number < startingBlock) {
            stage_ = 1; // not started but initialized
        } else if (
            block.number >= startingBlock &&
            block.number < softCapBlock &&
            totalPayinDeposited() < softCapAmount
        ) {
            stage_ = 2; // launch started
        } else if (totalPayinDeposited() >= softCapAmount) {
            stage_ = 3; // soft cap reached
        } else if (totalPayinDeposited() >= totalHardCap()) {
            stage_ = 4; // launch ended because hardcap is reached
        } else if (
            totalPayinDeposited() < softCapAmount && block.number > softCapBlock
        ) {
            stage_ = 4; // launch ended because didnt hit softcap target in time
        }
    }

    /**
     * @dev Checks a whitelist for an address and tier
     * @param _address Address of whitelist to check
     * @param _tier Tier associated with address
     * @return bool True if address and tier combination is whitelisted, false otherwise
     */
    function checkWhitelist(
        address _address,
        uint _tier
    ) public view returns (bool) {
        return whitelisted[_address][_tier];
    }

    /**
     *  @notice return the struct tiers, useful for frontend
     */
    function getTiers()
        external
        view
        returns (
            uint256[4] memory vestings_,
            uint256[4] memory bonuses_,
            uint256[4] memory hardCap_,
            uint256[4] memory minDeposit_,
            uint256[4] memory maxDeposit_
        )
    {
        vestings_ = tiers.vestingTerms;
        bonuses_ = tiers.bonus;
        hardCap_ = tiers.hardCap;
        minDeposit_ = tiers.minDeposit;
        maxDeposit_ = tiers.maxDeposit;
    }

    /**
     * @notice Gets the payout for a given amount with a given tier applied
     * @dev requires an amount > 100,000 and will return a payout applying the bonus.
     * @dev The bonus varies based on the given tier.
     * @param _amountIn The amount being exchanged
     * @param _tier The tier associated with the payout
     * @return payout_ The payout after applying the bonus
     */
    function getPayout(
        uint256 _amountIn,
        uint256 _tier
    ) public view returns (uint256 payout_) {
        require(_amountIn >= 100000, "too small");

        if (getStage() > 2) {
            uint256 amountReduced = (_amountIn * (slippageRatio)) / (100000);

            //get the ratio between tokens, calculate amount and apply bonus
            uint256 ratio = PricerLib.getTokensBondRatio(
                address(payinToken),
                amountReduced,
                address(payoutToken),
                quoteToken,
                Router
            );
            payout_ = mulDiv(_amountIn, (ratio), (1e18));
        } else {
            payout_ = mulDiv(_amountIn, initialPrice, 1e18);
        }
        //apply bonus
        payout_ += mulDiv(payout_, getBonus(_tier), 100_000);
    }

    /**
     *  @notice get the MizuTreasury address where fees are sent
     */
    function getMizuTreasury() public view returns (address mizuTreasury) {
        //read and returns mizuTreasury from MizuRegistry
        mizuTreasury = MizuRegistry.MizuTreasury();
    }

    /**
     *  @notice uses depositRatio(_tier) to calculate the actual bonus if isPriceVariable
     *  @return bonus_ uint in thousandths of a %. i.e. 500 = 0.5%
     */
    function getBonus(uint256 _tier) public view returns (uint256 bonus_) {
        if (isPriceVariable) {
            if (depositRatio(_tier) > 100000) {
                bonus_ = (tiers.bonus[_tier] * minBonus) / 100000;
            } else {
                bonus_ =
                    (tiers.bonus[_tier]) -
                    mulDiv(tiers.bonus[_tier], depositRatio(_tier), 100000);
                if (
                    bonus_ <
                    tiers.bonus[_tier] -
                        (((tiers.bonus[_tier] * minBonus) / 100000))
                ) {
                    bonus_ = (tiers.bonus[_tier] * minBonus) / 100000;
                }
            }
        } else {
            bonus_ = tiers.bonus[_tier];
        }
    }

    /**
     *  @notice sums deposit of each tier to get totalDeposits_
     *  @return totalDeposits_ uint
     */
    function totalDeposited() public view returns (uint256 totalDeposits_) {
        for (uint256 i = 0; i < tiersPayinDeposited.length; i++) {
            totalDeposits_ = (tiersPayinDeposited[i]);
        }
    }

    /**
     *  @notice calculate current ratio of current deposit / hardCap(tier)
     *  @return depositRatio_ uint
     *
     */
    function depositRatio(
        uint256 _tier
    ) public view returns (uint256 depositRatio_) {
        // 18 decimals, 1ether = 100%
        depositRatio_ = (simpleRatio(_tier) * 100000) / 1e18;
    }

    function simpleRatio(uint256 _tier) internal view returns (uint256 simple) {
        simple = PricerLib.FixedFraction(
            tiersPayinDeposited[_tier],
            tiers.hardCap[_tier]
        );
    }

    /**
     * @dev Calculates the percentage of tokens vested for a given _depositor and _tier.
     * @dev If fully vested returns 10_000 ore more
     * @param _depositor The address of the depositor.
     * @param _tier The tier of the vesting period.
     * @return percentVested_ The percentage of tokens vested.
     */
    function percentVestedFor(
        address _depositor,
        uint256 _tier
    ) public view returns (uint256 percentVested_) {
        Deposits memory deposits = depositsInfo[_depositor];
        uint256 blocksSinceLast;
        uint256 vesting;
        if (deposits.lastBlocks[_tier] > block.number) {
            return 0;
        } else {
            blocksSinceLast = block.number - (deposits.lastBlocks[_tier]);
            vesting = deposits.vesting[_tier];
        }

        if (vesting > 0) {
            percentVested_ = (blocksSinceLast * (10000)) / (vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     * @notice Returns the pending payout for a given depostitor and tier.
     * @param _depositor The address of the depositor.
     * @param _tier The tier of the deposit.
     * @return pendingPayout_ The pending payout for the given depositor and tier.
     */
    function pendingPayoutFor(
        address _depositor,
        uint256 _tier
    ) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositor, _tier);
        uint256 payout = depositsInfo[_depositor].payout[_tier];

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = (payout * (percentVested)) / (10000);
        }
    }

    /**
     *  @notice current fee Mizu takes of each deposit based on the current admin address
     *  @return currentFee_ uint
     */
    function currentMizuFee() public view returns (uint256 currentFee_) {
        currentFee_ = MizuRegistry.getFee(address(this));
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value: amount}("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage)
        internal
        view
        returns (bytes memory)
    {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage)
        internal
        pure
        returns (bytes memory)
    {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
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
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
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
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILaunchTreasury {
  function admin (  ) external view returns ( address );
  function deposit ( address _payinToken, uint256 _payinAmount, uint256 _amountPayoutToken, uint256 _tokensForLiquidity ) external;
  function launchContract ( address ) external view returns ( bool );
  function payoutToken (  ) external view returns ( address );
  function toggleLaunchContract ( address _launchContract ) external;
  function transferManagment ( address _newOwner ) external;
  function withdraw ( address _token, address _destination, uint256 _amount ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

interface IRegistry {
    function AFFILIATE_ROLE() external view returns (bytes32);

    function AffPercentage(address) external view returns (uint256);

    function AffWhitelist(address) external view returns (bool);

    function BaseAffPerc() external view returns (uint256);

    function BaseRefPerc() external view returns (uint256);

    function CustomRefPerc(address) external view returns (uint256);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function FACTORY_ROLE() external view returns (bytes32);

    function FEE_DECIMALS() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function MizuDao() external view returns (address);

    function MizuTreasury() external view returns (address);

    function REFERRAL_ROLE() external view returns (bytes32);

    function SETFEE_ROLE() external view returns (bytes32);

    function addFactory(address _factory) external;

    function bondDetails(uint256)
        external
        view
        returns (
            address _payoutToken,
            address _principleToken,
            address _treasuryAddress,
            address _bondAddress,
            address _initialOwner,
            address _factory
        );

    function bondTypeFee(address) external view returns (uint256);

    function claimAllAff(address _affiliate) external;

    function claimAllRef(address _referrer) external;

    function factories(uint256) external view returns (address);

    function feeDiscount(address) external view returns (uint256);

    function getAffiliate(address _affiliate) external view returns (uint256 _percentage);

    function getFee(address _bond) external view returns (uint256 _checkedFee);

    function getRefPerc(address _referrer) external view returns (uint256 _percentage);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function indexOfBond(address) external view returns (uint256);

    function pushBond(
        address _payoutToken,
        address _principleToken,
        address _customTreasury,
        address _customBond,
        address _initialOwner,
        address _factory
    ) external returns (address _treasury, address _bond);

    function renounceRole(bytes32 role, address account) external;

    function resetFeeDiscount(address _bondOwner) external;

    function revokeRole(bytes32 role, address account) external;

    function setAffPerc(address _affiliate, uint256 _percentage) external;

    function setAffWhitelist(address _affiliate, bool _bool) external;

    function setBaseAffPerc(uint256 _percentage) external;

    function setBaseRefPerc(uint256 _percentage) external;

    function setBondTypeFees(address _factory, uint256 _fee) external;

    function setFeeDiscount(address _bondOwner, uint256 _newFeeDiscount) external;

    function setMizuDAO(address _mizuDao) external;

    function setMizuTreasury(address _mizuTreasury) external;

    function setRefPerc(address _referrer, uint256 _percentage) external;
}

// https://uniswap.org/docs/v2/smart-contracts/factory/
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Factory.solimplementation
// SPDX-License-Identifier: MIT
// UniswapV2Factory is deployed at 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f on the Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// https://uniswap.org/docs/v2/smart-contracts/pair/
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol implementation
// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

// https://uniswap.org/docs/v2/smart-contracts/router01/
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router01.sol implementation
// UniswapV2Router01 is deployed at 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a on the Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// https://uniswap.org/docs/v2/smart-contracts/router02/
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router02.sol implementation
// UniswapV2Router02 is deployed at 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D on the Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets.

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

// You can add this typing "uniV2Router01"
import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

contract OwnableAdmin {
    address public admin;

    constructor(address _initialOwner) {
        admin = _initialOwner;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Ownable: caller is not the admin");
        _;
    }

    function transferManagment(address _newOwner) external onlyAdmin {
        require(_newOwner != address(0));
        admin = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Common mathematical functions used in both SD59x18 and UD60x18. Note that these global functions do not
/// always operate with SD59x18 and UD60x18 numbers.

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Emitted when the ending result in the fixed-point version of `mulDiv` would overflow uint256.
error PRBMath__MulDiv18Overflow(uint256 x, uint256 y);

/// @notice Emitted when the ending result in `mulDiv` would overflow uint256.
error PRBMath__MulDivOverflow(uint256 x, uint256 y, uint256 denominator);

/// @notice Emitted when attempting to run `mulDiv` with one of the inputs `type(int256).min`.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the ending result in the signed version of `mulDiv` would overflow int256.
error PRBMath__MulDivSignedOverflow(int256 x, int256 y);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev How many trailing decimals can be represented.
uint256 constant UNIT = 1e18;

/// @dev Largest power of two that is a divisor of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;

/// @dev The `UNIT` number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Finds the zero-based index of the first one in the binary representation of x.
/// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
///
/// Each of the steps in this implementation is equivalent to this high-level code:
///
/// ```solidity
/// if (x >= 2 ** 128) {
///     x >>= 128;
///     result += 128;
/// }
/// ```
///
/// Where 128 is swapped with each respective power of two factor. See the full high-level implementation here:
/// https://gist.github.com/paulrberg/f932f8693f2733e30c4d479e8e980948
///
/// A list of the Yul instructions used below:
/// - "gt" is "greater than"
/// - "or" is the OR bitwise operator
/// - "shl" is "shift left"
/// - "shr" is "shift right"
///
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return result The index of the most significant bit as an uint256.
function msb(uint256 x) pure returns (uint256 result) {
    // 2^128
    assembly {
        let factor := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^64
    assembly {
        let factor := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^32
    assembly {
        let factor := shl(5, gt(x, 0xFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^16
    assembly {
        let factor := shl(4, gt(x, 0xFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^8
    assembly {
        let factor := shl(3, gt(x, 0xFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^4
    assembly {
        let factor := shl(2, gt(x, 0xF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^2
    assembly {
        let factor := shl(1, gt(x, 0x3))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^1
    // No need to shift x any more.
    assembly {
        let factor := gt(x, 0x1)
        result := or(result, factor)
    }
}

/// @notice Calculates floor(x*y÷denominator) with full precision.
///
/// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
///
/// Requirements:
/// - The denominator cannot be zero.
/// - The result must fit within uint256.
///
/// Caveats:
/// - This function does not work with fixed-point numbers.
///
/// @param x The multiplicand as an uint256.
/// @param y The multiplier as an uint256.
/// @param denominator The divisor as an uint256.
/// @return result The result as an uint256.
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
            return prod0 / denominator;
        }
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert PRBMath__MulDivOverflow(x, y, denominator);
    }

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly {
        // Compute remainder using the mulmod Yul instruction.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512 bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
    // See https://cs.stackexchange.com/q/138556/92363.
    unchecked {
        // Does not overflow because the denominator cannot be zero at this stage in the function.
        uint256 lpotdod = denominator & (~denominator + 1);
        assembly {
            // Divide denominator by lpotdod.
            denominator := div(denominator, lpotdod)

            // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

            // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
            lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * lpotdod;

        // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
        // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
        // four bits. That is, denominator * inv = 1 mod 2^4.
        uint256 inverse = (3 * denominator) ^ 2;

        // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
        // in modular arithmetic, doubling the correct bits in each step.
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
    }
}

/// @notice Calculates floor(x*y÷1e18) with full precision.
///
/// @dev Variant of `mulDiv` with constant folding, i.e. in which the denominator is always 1e18. Before returning the
/// final result, we add 1 if `(x * y) % UNIT >= HALF_UNIT`. Without this adjustment, 6.6e-19 would be truncated to 0
/// instead of being rounded to 1e-18. See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
///
/// Requirements:
/// - The result must fit within uint256.
///
/// Caveats:
/// - The body is purposely left uncommented; to understand how this works, see the NatSpec comments in `mulDiv`.
/// - It is assumed that the result can never be `type(uint256).max` when x and y solve the following two equations:
///     1. x * y = type(uint256).max * UNIT
///     2. (x * y) % UNIT >= UNIT / 2
///
/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
function mulDiv18(uint256 x, uint256 y) pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 >= UNIT) {
        revert PRBMath__MulDiv18Overflow(x, y);
    }

    uint256 remainder;
    assembly {
        remainder := mulmod(x, y, UNIT)
    }

    if (prod1 == 0) {
        unchecked {
            return prod0 / UNIT;
        }
    }

    assembly {
        result :=
            mul(
                or(
                    div(sub(prod0, remainder), UNIT_LPOTD),
                    mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
                ),
                UNIT_INVERSE
            )
    }
}

/// @notice Calculates floor(x*y÷denominator) with full precision.
///
/// @dev An extension of `mulDiv` for signed numbers. Works by computing the signs and the absolute values separately.
///
/// Requirements:
/// - None of the inputs can be `type(int256).min`.
/// - The result must fit within int256.
///
/// @param x The multiplicand as an int256.
/// @param y The multiplier as an int256.
/// @param denominator The divisor as an int256.
/// @return result The result as an int256.
function mulDivSigned(int256 x, int256 y, int256 denominator) pure returns (int256 result) {
    if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
        revert PRBMath__MulDivSignedInputTooSmall();
    }

    // Get hold of the absolute values of x, y and the denominator.
    uint256 absX;
    uint256 absY;
    uint256 absD;
    unchecked {
        absX = x < 0 ? uint256(-x) : uint256(x);
        absY = y < 0 ? uint256(-y) : uint256(y);
        absD = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

    // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
    uint256 rAbs = mulDiv(absX, absY, absD);
    if (rAbs > uint256(type(int256).max)) {
        revert PRBMath__MulDivSignedOverflow(x, y);
    }

    // Get the signs of x, y and the denominator.
    uint256 sx;
    uint256 sy;
    uint256 sd;
    assembly {
        // This works thanks to two's complement.
        // "sgt" stands for "signed greater than" and "sub(0,1)" is max uint256.
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
        sd := sgt(denominator, sub(0, 1))
    }

    // XOR over sx, sy and sd. What this does is to check whether there are 1 or 3 negative signs in the inputs.
    // If there are, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers.
/// See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
function prbExp2(uint256 x) pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
        // because the initial result is 2^191 and all magic factors are less than 2^65.
        if (x & 0xFF00000000000000 > 0) {
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
        }

        if (x & 0xFF000000000000 > 0) {
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
        }

        if (x & 0xFF0000000000 > 0) {
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
        }

        if (x & 0xFF0000 > 0) {
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
        }

        if (x & 0xFF00 > 0) {
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
        }

        if (x & 0xFF > 0) {
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
        }

        // We're doing two things at the same time:
        //
        //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
        //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
        //      rather than 192.
        //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
        //
        // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
        result *= UNIT;
        result >>= (191 - (x >> 64));
    }
}

/// @notice Calculates the square root of x, rounding down if x is not a perfect square.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
/// Credits to OpenZeppelin for the explanations in code comments below.
///
/// Caveats:
/// - This function does not work with fixed-point numbers.
///
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as an uint256.
function prbSqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of x.
    //
    // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
    //
    // $$
    // msb(x) <= x <= 2*msb(x)$
    // $$
    //
    // We write $msb(x)$ as $2^k$ and we get:
    //
    // $$
    // k = log_2(x)
    // $$
    //
    // Thus we can write the initial inequality as:
    //
    // $$
    // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
    // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
    // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
    // $$
    //
    // Consequently, $2^{log_2(x) /2}` is a good first approximation of sqrt(x) with at least one correct bit.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 2 ** 128) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 2 ** 64) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 2 ** 32) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 2 ** 16) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 2 ** 8) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 2 ** 4) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 2 ** 2) {
        result <<= 1;
    }

    // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
    // most 128 bits, since  it is the square root of a uint256. Newton's method converges quadratically (precision
    // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
    // precision into the expected uint128 result.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        // Round down the result in case x is not a perfect square.
        uint256 roundedDownResult = x / result;
        if (result >= roundedDownResult) {
            result = roundedDownResult;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {msb, mulDiv, mulDiv18, prbExp2, prbSqrt} from "./Core.sol";

/// @notice The unsigned 60.18-decimal fixed-point number representation, which can have up to 60 digits and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the Solidity type uint256.
type UD60x18 is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Emitted when adding two numbers overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, UD60x18 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(UD60x18 x);

/// @notice Emitted when taking the natural exponent of a base greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(UD60x18 x);

/// @notice Emitted when taking the binary exponent of a base greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(UD60x18 x);

/// @notice Emitted when taking the geometric mean of two numbers and multiplying them overflows UD60x18.
error PRBMathUD60x18__GmOverflow(UD60x18 x, UD60x18 y);

/// @notice Emitted when taking the logarithm of a number less than 1.
error PRBMathUD60x18__LogInputTooSmall(UD60x18 x);

/// @notice Emitted when calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(UD60x18 x);

/// @notice Emitted when subtracting one number from another underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(UD60x18 x, UD60x18 y);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows UD60x18.
error PRBMathUD60x18__ToUD60x18Overflow(uint256 x);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as an UD60x18 number.
UD60x18 constant E = UD60x18.wrap(2_718281828459045235);

/// @dev Half the UNIT number.
uint256 constant uHALF_UNIT = 0.5e18;
UD60x18 constant HALF_UNIT = UD60x18.wrap(uHALF_UNIT);

/// @dev log2(10) as an UD60x18 number.
uint256 constant uLOG2_10 = 3_321928094887362347;
UD60x18 constant LOG2_10 = UD60x18.wrap(uLOG2_10);

/// @dev log2(e) as an UD60x18 number.
uint256 constant uLOG2_E = 1_442695040888963407;
UD60x18 constant LOG2_E = UD60x18.wrap(uLOG2_E);

/// @dev The maximum value an UD60x18 number can have.
uint256 constant uMAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
UD60x18 constant MAX_UD60x18 = UD60x18.wrap(uMAX_UD60x18);

/// @dev The maximum whole value an UD60x18 number can have.
uint256 constant uMAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_000000000000000000;
UD60x18 constant MAX_WHOLE_UD60x18 = UD60x18.wrap(uMAX_WHOLE_UD60x18);

/// @dev PI as an UD60x18 number.
UD60x18 constant PI = UD60x18.wrap(3_141592653589793238);

/// @dev The unit amount which implies how many trailing decimals can be represented.
uint256 constant uUNIT = 1e18;
UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

/// @dev Zero as an UD60x18 number.
UD60x18 constant ZERO = UD60x18.wrap(0);

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {avg, ceil, div, exp, exp2, floor, frac, gm, inv, ln, log10, log2, mul, pow, powu, sqrt} for UD60x18 global;

/// @notice Calculates the arithmetic average of x and y, rounding down.
///
/// @dev Based on the formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
//
/// In English, what this formula does is:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @param x The first operand as an UD60x18 number.
/// @param y The second operand as an UD60x18 number.
/// @return result The arithmetic average as an UD60x18 number.
function avg(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Yields the smallest whole UD60x18 number greater than or equal to x.
///
/// @dev This is optimized for fractional value inputs, because for every whole value there are "1e18 - 1" fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_UD60x18`.
///
/// @param x The UD60x18 number to ceil.
/// @param result The least number greater than or equal to x, as an UD60x18 number.
function ceil(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    if (xUint > uMAX_WHOLE_UD60x18) {
        revert PRBMathUD60x18__CeilOverflow(x);
    }

    assembly {
        // Equivalent to "x % UNIT" but faster.
        let remainder := mod(x, uUNIT)

        // Equivalent to "UNIT - remainder" but faster.
        let delta := sub(uUNIT, remainder)

        // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
        result := add(x, mul(delta, gt(remainder, 0)))
    }
}

/// @notice Divides two UD60x18 numbers, returning a new UD60x18 number. Rounds towards zero.
///
/// @dev Uses `mulDiv` to enable overflow-safe multiplication and division.
///
/// Requirements:
/// - The denominator cannot be zero.
///
/// @param x The numerator as an UD60x18 number.
/// @param y The denominator as an UD60x18 number.
/// @param result The quotient as an UD60x18 number.
function div(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(mulDiv(unwrap(x), uUNIT, unwrap(y)));
}

/// @notice Calculates the natural exponent of x.
///
/// @dev Based on the formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// Requirements:
/// - All from `log2`.
/// - x must be less than 133.084258667509499441.
///
/// @param x The exponent as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function exp(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    // Without this check, the value passed to `exp2` would be greater than 192.
    if (xUint >= 133_084258667509499441) {
        revert PRBMathUD60x18__ExpInputTooBig(x);
    }

    unchecked {
        // We do the fixed-point multiplication inline rather than via the `mul` function to save gas.
        uint256 doubleUnitProduct = xUint * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Requirements:
/// - x must be 192 or less.
/// - The result must fit within `MAX_UD60x18`.
///
/// @param x The exponent as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function exp2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    // Numbers greater than or equal to 2^192 don't fit within the 192.64-bit format.
    if (xUint >= 192e18) {
        revert PRBMathUD60x18__Exp2InputTooBig(x);
    }

    // Convert x to the 192.64-bit fixed-point format.
    uint256 x_192x64 = (xUint << 64) / uUNIT;

    // Pass x to the `prbExp2` function, which uses the 192.64-bit fixed-point number representation.
    result = wrap(prbExp2(x_192x64));
}

/// @notice Yields the greatest whole UD60x18 number less than or equal to x.
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
/// @param x The UD60x18 number to floor.
/// @param result The greatest integer less than or equal to x, as an UD60x18 number.
function floor(UD60x18 x) pure returns (UD60x18 result) {
    assembly {
        // Equivalent to "x % UNIT" but faster.
        let remainder := mod(x, uUNIT)

        // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
        result := sub(x, mul(remainder, gt(remainder, 0)))
    }
}

/// @notice Yields the excess beyond the floor of x.
/// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
/// @param x The UD60x18 number to get the fractional part of.
/// @param result The fractional part of x as an UD60x18 number.
function frac(UD60x18 x) pure returns (UD60x18 result) {
    assembly {
        result := mod(x, uUNIT)
    }
}

/// @notice Calculates the geometric mean of x and y, i.e. $$sqrt(x * y)$$, rounding down.
///
/// @dev Requirements:
/// - x * y must fit within `MAX_UD60x18`, lest it overflows.
///
/// @param x The first operand as an UD60x18 number.
/// @param y The second operand as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function gm(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);
    if (xUint == 0 || yUint == 0) {
        return ZERO;
    }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        uint256 xyUint = xUint * yUint;
        if (xyUint / xUint != yUint) {
            revert PRBMathUD60x18__GmOverflow(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product had picked up a factor of `UNIT`
        // during multiplication. See the comments in the `prbSqrt` function.
        result = wrap(prbSqrt(xyUint));
    }
}

/// @notice Calculates 1 / x, rounding toward zero.
///
/// @dev Requirements:
/// - x cannot be zero.
///
/// @param x The UD60x18 number for which to calculate the inverse.
/// @return result The inverse as an UD60x18 number.
function inv(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // 1e36 is UNIT * UNIT.
        result = wrap(1e36 / unwrap(x));
    }
}

/// @notice Calculates the natural logarithm of x.
///
/// @dev Based on the formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}$$.
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
/// - This doesn't return exactly 1 for 2.718281828459045235, for that more fine-grained precision is needed.
///
/// @param x The UD60x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an UD60x18 number.
function ln(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // We do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value
        // that `log2` can return is 196.205294292027477728.
        result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_E);
    }
}

/// @notice Calculates the common logarithm of x.
///
/// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
/// logarithm based on the formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
///
/// @param x The UD60x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an UD60x18 number.
function log10(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    if (xUint < uUNIT) {
        revert PRBMathUD60x18__LogInputTooSmall(x);
    }

    // Note that the `mul` in this assembly block is the assembly multiplication operation, not the UD60x18 `mul`.
    // prettier-ignore
    assembly {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 59) }
        default { result := uMAX_UD60x18 }
    }

    if (unwrap(result) == uMAX_UD60x18) {
        unchecked {
            // Do the fixed-point division inline to save gas.
            result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x.
///
/// @dev Based on the iterative approximation algorithm.
/// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Requirements:
/// - x must be greater than or equal to UNIT, otherwise the result would be negative.
///
/// Caveats:
/// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
///
/// @param x The UD60x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an UD60x18 number.
function log2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    if (xUint < uUNIT) {
        revert PRBMathUD60x18__LogInputTooSmall(x);
    }

    unchecked {
        // Calculate the integer part of the logarithm, add it to the result and finally calculate y = x * 2^(-n).
        uint256 n = msb(xUint / uUNIT);

        // This is the integer part of the logarithm as an UD60x18 number. The operation can't overflow because n
        // n is maximum 255 and UNIT is 1e18.
        uint256 resultUint = n * uUNIT;

        // This is $y = x * 2^{-n}$.
        uint256 y = xUint >> n;

        // If y is 1, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultUint);
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta.rshift(1)" part is equivalent to "delta /= 2", but shifting bits is faster.
        uint256 DOUBLE_UNIT = 2e18;
        for (uint256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultUint += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        result = wrap(resultUint);
    }
}

/// @notice Multiplies two UD60x18 numbers together, returning a new UD60x18 number.
/// @dev See the documentation for the `Core/mulDiv18` function.
/// @param x The multiplicand as an UD60x18 number.
/// @param y The multiplier as an UD60x18 number.
/// @return result The product as an UD60x18 number.
function mul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(mulDiv18(unwrap(x), unwrap(y)));
}

/// @notice Raises x to the power of y.
///
/// @dev Based on the formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// Requirements:
/// - All from `exp2`, `log2` and `mul`.
///
/// Caveats:
/// - All from `exp2`, `log2` and `mul`.
/// - Assumes 0^0 is 1.
///
/// @param x Number to raise to given power y, as an UD60x18 number.
/// @param y Exponent to raise x to, as an UD60x18 number.
/// @return result x raised to power y, as an UD60x18 number.
function pow(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);

    if (xUint == 0) {
        result = yUint == 0 ? UNIT : ZERO;
    } else {
        if (yUint == uUNIT) {
            result = x;
        } else {
            result = exp2(mul(log2(x), y));
        }
    }
}

/// @notice Raises x (an UD60x18 number) to the power y (unsigned basic integer) using the famous algorithm
/// "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
///
/// Requirements:
/// - The result must fit within `MAX_UD60x18`.
///
/// Caveats:
/// - All from "Core/mulDiv18".
/// - Assumes 0^0 is 1.
///
/// @param x The base as an UD60x18 number.
/// @param y The exponent as an uint256.
/// @return result The result as an UD60x18 number.
function powu(UD60x18 x, uint256 y) pure returns (UD60x18 result) {
    // Calculate the first iteration of the loop in advance.
    uint256 xUint = unwrap(x);
    uint256 resultUint = y & 1 > 0 ? xUint : uUNIT;

    // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
    for (y >>= 1; y > 0; y >>= 1) {
        xUint = mulDiv18(xUint, xUint);

        // Equivalent to "y % 2 == 1" but faster.
        if (y & 1 > 0) {
            resultUint = mulDiv18(resultUint, xUint);
        }
    }
    result = wrap(resultUint);
}

/// @notice Calculates the square root of x, rounding down.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Requirements:
/// - x must be less than `MAX_UD60x18` divided by `UNIT`.
///
/// @param x The UD60x18 number for which to calculate the square root.
/// @return result The result as an UD60x18 number.
function sqrt(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    unchecked {
        if (xUint > uMAX_UD60x18 / uUNIT) {
            revert PRBMathUD60x18__SqrtOverflow(x);
        }
        // Multiply x by `UNIT` to account for the factor of `UNIT` that is picked up when multiplying two UD60x18
        // numbers together (in this case, the two numbers are both the square root).
        result = wrap(prbSqrt(xUint * uUNIT));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                            CONVERSION FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Converts an UD60x18 number to a simple integer by dividing it by `UNIT`. Rounds towards zero in the process.
/// @dev Rounds down in the process.
/// @param x The UD60x18 number to convert.
/// @return result The same number in basic integer form.
function fromUD60x18(UD60x18 x) pure returns (uint256 result) {
    result = unwrap(x) / uUNIT;
}

/// @notice Converts a simple integer to UD60x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UD60x18` divided by `UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to UD60x18.
function toUD60x18(uint256 x) pure returns (UD60x18 result) {
    if (x > uMAX_UD60x18 / uUNIT) {
        revert PRBMathUD60x18__ToUD60x18Overflow(x);
    }
    unchecked {
        result = wrap(x * uUNIT);
    }
}

/// @notice Wraps an unsigned integer into the UD60x18 type.
function ud(uint256 x) pure returns (UD60x18 result) {
    result = wrap(x);
}

/// @notice Wraps an unsigned integer into the UD60x18 type.
/// @dev Alias for the "ud" function defined above.
function ud60x18(uint256 x) pure returns (UD60x18 result) {
    result = wrap(x);
}

/// @notice Unwraps an UD60x18 number into the underlying unsigned integer.
function unwrap(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Wraps an unsigned integer into the UD60x18 type.
function wrap(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/*//////////////////////////////////////////////////////////////////////////
                        GLOBAL-SCOPED HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    add,
    and,
    eq,
    gt,
    gte,
    isZero,
    lshift,
    lt,
    lte,
    mod,
    neq,
    or,
    rshift,
    sub,
    uncheckedAdd,
    uncheckedSub,
    xor
} for UD60x18 global;

/// @notice Implements the checked addition operation (+) in the UD60x18 type.
function add(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) + unwrap(y));
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) & bits);
}

/// @notice Implements the equal operation (==) in the UD60x18 type.
function eq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) == unwrap(y);
}

/// @notice Implements the greater than operation (>) in the UD60x18 type.
function gt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) > unwrap(y);
}

/// @notice Implements the greater than or equal to operation (>=) in the UD60x18 type.
function gte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) >= unwrap(y);
}

/// @notice Implements a zero comparison check function in the UD60x18 type.
function isZero(UD60x18 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = unwrap(x) == 0;
}

/// @notice Implements the left shift operation (<<) in the UD60x18 type.
function lshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) << bits);
}

/// @notice Implements the lower than operation (<) in the UD60x18 type.
function lt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) < unwrap(y);
}

/// @notice Implements the lower than or equal to operation (<=) in the UD60x18 type.
function lte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) <= unwrap(y);
}

/// @notice Implements the checked modulo operation (%) in the UD60x18 type.
function mod(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) % unwrap(y));
}

/// @notice Implements the not equal operation (!=) in the UD60x18 type
function neq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) != unwrap(y);
}

/// @notice Implements the OR (|) bitwise operation in the UD60x18 type.
function or(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) | unwrap(y));
}

/// @notice Implements the right shift operation (>>) in the UD60x18 type.
function rshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD60x18 type.
function sub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) - unwrap(y));
}

/// @notice Implements the unchecked addition operation (+) in the UD60x18 type.
function uncheckedAdd(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(unwrap(x) + unwrap(y));
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD60x18 type.
function uncheckedSub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(unwrap(x) - unwrap(y));
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD60x18 type.
function xor(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) ^ unwrap(y));
}

/*//////////////////////////////////////////////////////////////////////////
                        FILE-SCOPED HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {uncheckedDiv, uncheckedMul} for UD60x18;

/// @notice Implements the unchecked standard division operation in the UD60x18 type.
function uncheckedDiv(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(unwrap(x) / unwrap(y));
    }
}

/// @notice Implements the unchecked standard multiplication operation in the UD60x18 type.
function uncheckedMul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(unwrap(x) * unwrap(y));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./int/IERC20.sol";
import "./Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../lib/int/IUniswapV2Pair.sol";
import "../lib/int/IUniswapV2Factory.sol";

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) =
            IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA, tokenB)).getReserves();
        //changed how it gets the pair address to avoid having fixed init code hash
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * (reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * (997);
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * (1000) + (amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * (amountOut) * (1000);
        uint256 denominator = reserveOut - (amountOut) * (997);
        amountIn = (numerator / denominator) + (1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../lib/int/IUniswapV2Factory.sol";
import "../lib/int/IUniswapV2Pair.sol";
import "../lib/int/IUniswapV2Router02.sol";
import "../lib/int/IERC20.sol";
import "../lib/Babylonian.sol";
import {UD60x18, div} from "../lib/prb-math-3/UD60x18.sol";
import "../lib/FullMath.sol";
import "../lib/UniswapV2Library.sol";

library PricerLib {
    function getRatio(address tokenIn, uint256 amountIn, address tokenOut, address _quoteToken, address router)
        internal
        view
        returns (uint256 ratio)
    {
        IUniswapV2Router02 Router = IUniswapV2Router02(router);

        address[] memory path;
        path = new address[](3);
        path[0] = tokenIn;
        path[1] = _quoteToken;
        path[2] = tokenOut;

        uint256[] memory amounts = Router.getAmountsOut(amountIn, path);

        ratio = FixedFraction(amounts[2], amountIn); //returns the ratio between the two tokens with 18 decimals precision
    }

    function getAmtOut(uint256 amountIn, address token0, address token1, address router)
        internal
        view
        returns (uint256 amoutOut)
    {
        IUniswapV2Router02 Router = IUniswapV2Router02(router);

        address[] memory path;
        path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256[] memory amounts = Router.getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        bool feeOn,
        uint256 kLast
    ) internal pure returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        if (feeOn && kLast > 0) {
            uint256 rootK = Babylonian.sqrt(reservesA * (reservesB));
            uint256 rootKLast = Babylonian.sqrt(kLast);
            if (rootK > rootKLast) {
                uint256 numerator1 = totalSupply;
                uint256 numerator2 = rootK - (rootKLast);
                uint256 denominator = rootK * (5) + (rootKLast);
                uint256 feeLiquidity = FullMath.mulDiv(numerator1, numerator2, denominator);
                totalSupply = totalSupply + (feeLiquidity);
            }
        }
        return (reservesA * (liquidityAmount) / totalSupply, reservesB * (liquidityAmount) / totalSupply);
    }

    function getLiquidityValue(address factory, address tokenA, address tokenB, uint256 liquidityAmount)
        internal
        view
        returns (uint256 tokenAAmount, uint256 tokenBAmount)
    {
        (uint256 reservesA, uint256 reservesB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA, tokenB));
        bool feeOn = IUniswapV2Factory(factory).feeTo() != address(0);
        uint256 kLast = feeOn ? pair.kLast() : 0;
        uint256 totalSupply = pair.totalSupply();
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }

    function getLpTokens(address lp) internal view returns (address token0, address token1) {
        IUniswapV2Pair pair = IUniswapV2Pair(lp);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function getLpTokensAmount(address lp, uint256 amountLp)
        internal
        view
        returns (address tokenA, uint256 amountA, address tokenB, uint256 amountB)
    {
        address factory = IUniswapV2Pair(lp).factory();
        (tokenA, tokenB) = getLpTokens(lp);
        (amountA, amountB) = getLiquidityValue(factory, tokenA, tokenB, amountLp);
    }

    function getTokensBondRatio(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        address _quoteToken,
        address router
    ) internal view returns (uint256 ratio) {
        if (tokenIn == _quoteToken || tokenOut == _quoteToken) {
            uint256 amountOut = getAmtOut(amountIn, tokenIn, tokenOut, router);
            ratio = FixedFraction(amountOut, amountIn);
        } else {
            ratio = getRatio(tokenIn, amountIn, tokenOut, _quoteToken, router);
        }
    }

    function FixedFraction(uint256 numerator, uint256 denominator) internal pure returns (uint256 result) {
        UD60x18 numD = UD60x18.wrap(numerator);
        UD60x18 denD = UD60x18.wrap(denominator);
        UD60x18 resultEnc = div(numD, denD);
        result = UD60x18.unwrap(resultEnc);
    }
}