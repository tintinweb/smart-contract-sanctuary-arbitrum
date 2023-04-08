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
import "../interfaces/tokens/wlp/IUSDW.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/core/IOracleRouter.sol";
import "../interfaces/jbcontracts/IVaultManager.sol";
import "../interfaces/core/IWLPManager.sol";
import "./AccessControlBase.sol";

contract Vault is ReentrancyGuard, AccessControlBase, IVault {
    /*==================== Constants *====================*/
    uint32 private constant BASIS_POINTS_DIVISOR = 1e4;
    uint8 private constant USDW_DECIMALS = 18;
    uint16 private constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint128 private constant PRICE_PRECISION = 1e30;
    uint128 private constant MAX_WAGER_FEE = (15 * 1e16); // 15% | Scaling: 1e18 = 100% - 1e17 = 10% - 1e16 = 1%

    /*==================== State Variables *====================*/
    bool public override isInitialized;
    bool public override isSwapEnabled = true;
    bool public override hasDynamicFees = false;
    bool public override inManagerMode = false;
    bool private feelessSwapForPayout = false;
    bool private payoutsHalted = false;

    IVaultUtils public vaultUtils;
    address public override router;
    address public override priceOracleRouter;
    address public override usdw;

    // all the fees are in basis points, scaled 1e4, so 100% = 1e4
    uint256 public override taxBasisPoints = 50; // 0.5%
    uint256 public override stableTaxBasisPoints = 20; // 0.2%
    uint256 public override mintBurnFeeBasisPoints = 30; // 0.3%
    uint256 public override swapFeeBasisPoints = 30; // 0.3%
    uint256 public override stableSwapFeeBasisPoints = 4; // 0.04%
    uint256 public override minimumBurnMintFee = 15; // 0.15%

    // percentage fee that will be charged over every wager coming into the contract
    uint256 public override wagerFeeBasisPoints;
    uint256 public override totalTokenWeights;

    mapping (address => bool) public override isManager;
    mapping (address => bool) public override whitelistedTokens;
    mapping (address => uint256) public override tokenDecimals;
    mapping (address => bool) public override stableTokens;
    // tokenBalances is used only to determine _transferIn values
    mapping (address => uint256) public override tokenBalances;
    // tokenWeights allows customisation of index composition
    mapping (address => uint256) public override tokenWeights;
    // usdwAmounts tracks the amount of USDW debt for each whitelisted token
    mapping (address => uint256) public override usdwAmounts;
    // maxUsdwAmounts allows setting a max amount of USDW debt for a token
    mapping (address => uint256) public override maxUsdwAmounts;
    mapping (address => uint256) public override poolAmounts;
    // bufferAmounts allows specification of an amount to exclude from swaps
    mapping (address => uint256) public override bufferAmounts;
    mapping (uint256 => string) internal errors;

    // mapping that stores the amount of wager fees accumulated per vault aset
    // tokenAddress => amountOfWagerFees accumulated
    mapping (address => uint256) public override wagerFeeReserves;
    // swapFeeReserves tracks the amount of swap fees per token collecte
    mapping (address => uint256) public override swapFeeReserves;
    // mapping that stores the amount of referralfees that are collected in the vault
    mapping (address => uint256) public override referralReserves; 

    address public wlpManagerAddress;
    address public override vaultManagerAddress;
    address[] public override allWhitelistedTokens;
    // address of the feeCollector contract (only contract allowed to harest swap and wager fees)
    address public override feeCollector;
    address public rebalancer;

     /*==================== State Variables Custom WINR/JB INTERNAL *====================*/
    // internal storage (profit/loss) -> to be used to set fee strategies! STILL WIP DUE TO GAS COST CONCERNS
    // mapping storing the AGGREGATED (so of all time) amount of payouts via games! 
    // note this aggregated amount excludes wager and swap fees (and deposits). this exclusively tracks how much payouts the WLPs have 
    mapping(address => uint256) internal totalOut_;
    // // mapping storing the AGGREGATED (so of all time) amount of payins via games! 
    // // note this aggregated amount excludes wager and swap fees (and withdraws). this exclusively tracks how much payins the WLPs have 
    mapping(address => uint256) internal totalIn_;

    constructor(
        address _vaultRegistry,
        address _timelock
    ) AccessControlBase(_vaultRegistry, _timelock) {}

    function initialize(
        address _router,
        address _usdw,
        address _priceOracleRouter
    ) external onlyGovernance {
        _validate(!isInitialized, 1);
        isInitialized = true;
        router = _router;
        usdw = _usdw;
        priceOracleRouter = _priceOracleRouter;
    }

    /*==================== Operational functions Custom WINR/JB *====================*/

    /**
     * @notice function that collects the escrowerd tokens and pays out recipients based on info passed in by the VaultManager
     * @dev function can only be called by the vaultmanager contract
     * note: one of the most important contracts as it handles payouts to players
     * @param _tokens [0] is the wagerToken(coming into the contract), [1] is the payout token (leaving the contract)
     * @param _escrowAddress the address where the escrowed wager is held (generally vaultManager address)
     * @param _escrowAmount the amount of _tokens[0] held in escrow
     * @param _recipient the address the _tokens[1] will be sent to
     * @param _totalAmount total value of _tokens[1] the _recipient will receive (with fees deducted) - note that _totalAmount is denominated in _tokens[0]. 
     */
    function payout(
        address[2] memory _tokens,
        address _escrowAddress,
        uint256 _escrowAmount,
        address _recipient,
        uint256 _totalAmount
    ) external nonReentrant protocolNotPaused {
        _validate(_msgSender() == vaultManagerAddress, 13);
        _validate(!payoutsHalted, 19);
        _validate(_totalAmount > 0, 10);
        _validate(_escrowAmount > 0, 16);
        _validate(whitelistedTokens[_tokens[0]], 9);
        _validate(whitelistedTokens[_tokens[1]], 9);
        // pull the escrowed tokens from the escrow contract
        IVaultManager(_escrowAddress).getEscrowedTokens(_tokens[0], _escrowAmount);
        // collect the wager fees, charged in the wager token _tokens[0]
        (uint256 amountAfterWagerFee_, uint256 wagerFeeCharged_) = _collectWagerFees(
            _tokens[0], 
            _escrowAmount
        );
        // note: the wager fee is charged over the incoming asset (the wagerAsset, _tokens[0])
        // note: the _escrowAmount now resides in this contract. we have not yet done any pool or tokenbalance accounting
        // if the the wager and the payout token are the same no swap is needed  
        if (_tokens[0] == _tokens[1]) { // token in, is the same as token out
            uint256 _amountNetDifference;
            if (amountAfterWagerFee_ <= (_totalAmount + wagerFeeCharged_)) { // the vault made a loss
                _amountNetDifference = (_totalAmount + wagerFeeCharged_) - amountAfterWagerFee_;
                // decrease the net amount the WLP has to pay from the pool amounts
                totalOut_[_tokens[0]] += _amountNetDifference;
                _decreasePoolAmount(_tokens[0], _amountNetDifference);
            } else { // the vault made a profit!
                // vice versa as the if statement, we register the net proftfor the vault (the vault takes on the wagerFee)
                _amountNetDifference =  amountAfterWagerFee_ - (_totalAmount + wagerFeeCharged_);
                totalIn_[_tokens[0]] += _amountNetDifference;
                // with the incoming escrow being larger as the payout, the vault actually made a profit
                _increasePoolAmount(_tokens[0], _amountNetDifference);
            }
            _payoutPlayer(
                _tokens[0], // _addressTokenOut (same as _tokens[1])
                _totalAmount, 
                _recipient // _recipient
            );
            return;
        } else { // token in, is different from token out, the player wants the totalAmount in a different asset, so we need to swap in this scenario
            uint256 totalAmountOut_ = _amountOfTokenForToken(
                            _tokens[0],
                            _tokens[1], 
                            _totalAmount
                        );
            // note the player wants to receive the winnings in _tokens[1], the _totalAmount is denominated in _tokens[0] so before we proceed we need to calculate how much _totalAmount is in _tokens[1]. The _amountOfTokenForToken does this conversion.
            if(totalAmountOut_ == 0) { // the player has effectively won nothing expressed in _tokens[1]
                _increasePoolAmount(_tokens[0], amountAfterWagerFee_);
                totalIn_[_tokens[0]] += amountAfterWagerFee_;
                // sync the tokenbalance of the vault, as the wagerAsset now sits in this contract
                _updateTokenBalance(_tokens[0]);
                emit AmountOutNull(); // it should be highly unusual for this function to ever be reached!
                emit PlayerPayout(
                    _recipient,
                    _tokens[1],
                    0
                );
                return; // function stops as there is nothing to pay out!
            }

            // variable storing how much of _tokens[1] is returned after swapping the wager (minus the wager fee)
            uint256 amountOutAfterSwap_;
            // note swap fees are paid to the lps in the outgoing token (so _tokens[1])
            uint256 feesPaidInOut_;
            // check if the global config is for no swap fees to be charged to users of this particular function
            if (!feelessSwapForPayout) {  // swapper will pay swap fees
                 (amountOutAfterSwap_, feesPaidInOut_) = _swap(
                    _tokens[0], 
                    _tokens[1], 
                    address(this), 
                    amountAfterWagerFee_, 
                    false // fee will be charged
                );
            } else { // if the global config is that there are no swap fees charged for payout function users
               (amountOutAfterSwap_,) = _swap(
                    _tokens[0], 
                    _tokens[1], 
                    address(this), 
                    amountAfterWagerFee_, 
                    true // no fee will be charged
                );
                // feesPaidInOut_= 0;
            }
            _updateTokenBalance(_tokens[0]);
            uint256 _amountNetDifference;
            /**
             * both totalAmountOut_ and amountOutAfterSwap_ are tokens[1] (so the winAsset token)
             */
            if (totalAmountOut_ >= amountOutAfterSwap_) { // vault has made a loss
                _amountNetDifference = (totalAmountOut_ - amountOutAfterSwap_);
                totalOut_[_tokens[1]] += _amountNetDifference;
                // we register the loss with the pool balances
                _decreasePoolAmount(_tokens[1], _amountNetDifference);
            } else { // vault has made a profit
                _amountNetDifference = (amountOutAfterSwap_ - totalAmountOut_);
                totalIn_[_tokens[1]] += _amountNetDifference;
                // we register the profit with the pool balances
                _increasePoolAmount(_tokens[1], _amountNetDifference);
                if (feesPaidInOut_ >= totalAmountOut_) {
                    // if the feesPaidInOut_ is larger as the totalAmountOut_, the player is not receiving anything 
                    // still need to update the registered token balance of the vault (as the swap has already happened)
                    _updateTokenBalance(_tokens[1]);
                    emit PlayerPayout(
                        _recipient,
                        _tokens[1],
                        0
                    );
                    return; 
                }
            }
            // note: the swapFee stays in the Vault  (for now) however it is not part of the WLP anymore! the _swap function has already done the _updateTokenBalance so we do not need to do that anymore
            _payoutPlayer(
                _tokens[1], 
                (totalAmountOut_ - feesPaidInOut_),  // feesPaidInOut_ cannot be larger as because otherwise it would already have returned because of the previous if/else/if statement
                _recipient
            );
            return;
        }
    }

    /**
     * @notice function called by the vault manager to add assets to the WLP (profit)
     * @dev can only be called by the vault manager
     * @dev a wagerFeeBasisPoints will be charged over the incoming assets
     * @param _inputToken the address of the escrowed token
     * @param _escrowAddress the address where the _inputToken is in escrow
     * @param _escrowAmount the amount of the _inputToken that is held in escrow
     */
    function payin(
        address _inputToken,
        address _escrowAddress,
        uint256 _escrowAmount) external nonReentrant protocolNotPaused {
        _validate(whitelistedTokens[_inputToken], 9);
        _validate(_escrowAmount > 0, 16); 
        _validate(_msgSender() == vaultManagerAddress, 13);
        // pull the ecrowed tokens to the vault from the vault manager
        IVaultManager(_escrowAddress).getEscrowedTokens(
            _inputToken, 
            _escrowAmount
        );
        // note: the escrowed tokens now sit in this contract
        // deduct the wager fees from the escrowed tokens
        (uint256 amountAfterWagerFee_,) = _collectWagerFees(
            _inputToken,
            _escrowAmount
        );
        // note the wagerFees collected remain in this contract, but they are not part of the profit/value of the WLP LPs
        // add the tokens to the WLP, this will incrase the value of the wlp
        _increasePoolAmount(_inputToken, amountAfterWagerFee_);
        // update the balace of tokenBalances to ensure that the next swapper for this token isn't credited for this payin
        _updateTokenBalance(_inputToken);
        // register that tokens have gone into the vault! (excluding wagerFeeBasisPoints) - this is done to have an alternative way to track WLP profits (might be removed later!) - used for dynamic fee setting
        totalIn_[_inputToken] += amountAfterWagerFee_;
        emit PayinWLP(
            _inputToken,
            _escrowAmount
        );
    }

    /*==================== Operational functions WINR/JB *====================*/

    /**
     * @notice function that adds a whitelisted asset to the pool, without issuance of WLP or USDW!
     * @param _tokenIn address of the token to directly deposit into the pool
     * @dev take note that depositing LP by this means will NOT mint WLP to the caller. This function would only make sense to use if called by the WINR DAO. If you call this function you will receive nothing in return, it is effectively gifting liquidity to the pool without getting anything back.
     * DO NOT USE THIS FUNCTION IF YOU WANT TO RECEIVE WLP!
     */
    function directPoolDeposit(address _tokenIn) external override protocolNotPaused {
        require(
            IERC20(usdw).totalSupply() > 0,
            "Vault: USDW supply 0"
        );
        _validate(whitelistedTokens[_tokenIn], 9);
        uint256 tokenAmount_ = _transferIn(_tokenIn);
        _validate(tokenAmount_ > 0, 10);
        _increasePoolAmount(_tokenIn, tokenAmount_);
        emit DirectPoolDeposit(_tokenIn, tokenAmount_);
    }

    /**
     * @notice function that withdraws the swap fees and transfers them to the feeCollector contract
     * @dev function can only be called by the FeeCollector
     * @param _tokenToWithdraw the address of the token you want to withdraw fees from
     * @return collectedSwapFees_ the amount of swap fees that are available to be withdrawn
     * @return totalWagerFees_ the amount of wager fees that are available to be withdrawn
     * @return registeredReferralKickback_ the amount of referral kickback that is available to be withdrawn
     */
    function withdrawAllFees(address _tokenToWithdraw) external override protocolNotPaused returns(
            uint256 collectedSwapFees_, 
            uint256 totalWagerFees_, 
            uint256 registeredReferralKickback_) {
                // store to memory to save on SLOAD
                address feeCollector_ = feeCollector;
                // only a fecollector can collect fees
                require(
                    _msgSender() == feeCollector_,
                    "Vault: Caller must be feecollector"
                );

                collectedSwapFees_ = swapFeeReserves[_tokenToWithdraw];
                totalWagerFees_ = wagerFeeReserves[_tokenToWithdraw];
                registeredReferralKickback_ = referralReserves[_tokenToWithdraw];

                /**
                 * The amounnt of referral kickback is capped by the amount of wagerFees that is collected in a period. 
                 * As per rule the referral fees cannot bee more than 20% of the amount of wagerFees collected.
                 * If the referral fees are more than 20% of the wagerFees collected, the referral fees are capped at 20% of the wagerFees collected.
                 */

                // calculate the maximum amount of referral kickback that can be paid out (a fraction of wagerFeeReserves, the size of fraction is configured in WLPManager)
                uint256 maxAmountReferral_ = (totalWagerFees_ * IWLPManager(wlpManagerAddress).maxPercentageOfWagerFee()) / BASIS_POINTS_DIVISOR;

                // if the referral kickback is larger than the configured max fraction of the total wager fees, the referral kickback is somehow too large
                if(registeredReferralKickback_ > maxAmountReferral_) {
                    // the referral amount is larger as should be possible, this indicates there is a mistake or exploit in the referral system, hence we null the registeredReferralickback
                    
                    //  since we suspect a exploit/problem in referral system, we null the referral rewards, with this no funds can be lost
                    registeredReferralKickback_ = 0;
                } else {
                    // this is the normal situation, the referral kickback is smaller then the configured fraction of the total wager fees
                    _decreasePoolAmount(_tokenToWithdraw, registeredReferralKickback_);
                }

                // reset the fee reserves
                swapFeeReserves[_tokenToWithdraw] = 0;
                wagerFeeReserves[_tokenToWithdraw] = 0;
                referralReserves[_tokenToWithdraw] = 0;
                
                // transfer all the collected fees to the feecollector contract
                _transferOut(
                    _tokenToWithdraw, 
                    (collectedSwapFees_ + totalWagerFees_ + registeredReferralKickback_), 
                    feeCollector_
                );

                emit WithdrawAllFees(
                    _tokenToWithdraw, 
                    collectedSwapFees_, 
                    totalWagerFees_, 
                    registeredReferralKickback_
                );

                return (collectedSwapFees_, totalWagerFees_, registeredReferralKickback_);
    }

    /**
     * @notice function used to purchase USDW with 
     * @dev this was previously the buyUSDW function in GMX
     * @dev when ManagerMode is enabled, this function can only be called by the wlpManager contract
     * @param _tokenIn the token used to purchase/mint the WLP
     * @param _receiverUSDW the address the caller, this is generally the WLPManager contract, this address will receive the USDW (not the WLP)
     * note: remember that WLP is minted int he WLPManager contract!
     * @return mintAmountUsdw_ the amount of usdw that is minted to the glmManager contract
     */
    function deposit(
        address _tokenIn, 
        address _receiverUSDW) external override protocolNotPaused nonReentrant returns (uint256 mintAmountUsdw_) {
        // check if (when in manager mode) caller is the VaultManager 
        _validateManager();
        _validate(whitelistedTokens[_tokenIn], 9);
        uint256 tokenAmount_ = _transferIn(_tokenIn);
        _validate(tokenAmount_ > 0, 10);
        // fetch the price of the incoming token, the vault always prices an incoming asset by its lower bound price (so in the benefit of the WLPs)
        uint256 price_ = getMinPrice(_tokenIn);
        // cache to memory  usdw address to save on sloads
        address usdw_ = usdw;
        uint256 usdwAmount_ = (tokenAmount_ * price_) / PRICE_PRECISION;
        usdwAmount_ = adjustForDecimals(usdwAmount_, _tokenIn, usdw_);
        _validate(usdwAmount_ > 0, 12);
        uint256 feeBasisPoints_ = vaultUtils.getBuyUsdwFeeBasisPoints(_tokenIn, usdwAmount_);
        // note: the swapfee is charged in the incoming token (so in _tokenIn)
        (uint256 amountOutAfterFees_,) = _collectSwapFees(_tokenIn, tokenAmount_, feeBasisPoints_);
        // calculate the USDW value of the deposit (so this is the dollar value)
        mintAmountUsdw_ = (amountOutAfterFees_ * price_) / PRICE_PRECISION;
        // adjust to the correct amount of decimals
        mintAmountUsdw_ = adjustForDecimals(mintAmountUsdw_, _tokenIn, usdw_);
        // increase the _tokenIn debt (in usdw)
        _increaseUsdwAmount(_tokenIn, mintAmountUsdw_);
        _increasePoolAmount(_tokenIn, amountOutAfterFees_);
        // mint usdw to the _receiverUSDW contract (generally wlpManager if ManagerMode is enabled)
        IUSDW(usdw_).mint(_receiverUSDW, mintAmountUsdw_);
        emit BuyUSDW(
            _receiverUSDW, 
            _tokenIn, 
            tokenAmount_, 
            mintAmountUsdw_, 
            feeBasisPoints_
        );
        return mintAmountUsdw_;
    }

    /**
     * @notice redeem wlp for asset of choice (burn wlp, withdraw asset) -> sellUSDW/sellUSDW
     * @param _tokenOut the address of the token the seller wants to redeem his USDW for
     * @param _receiverTokenOut the address that will receive the _tokenOut (so the asset the withdrawer is redeeming their WLP for)
     * @return amountOut_ the amount of _tokenOut that the receiver has redeemed
     * @dev when ManagerMode is enabled, this function can only be called by the wlpManager contract!
     */
    function withdraw(
        address _tokenOut, 
        address _receiverTokenOut) external protocolNotPaused override nonReentrant returns (uint256) {
        _validateManager();
        _validate(whitelistedTokens[_tokenOut], 9);
        address usdw_ = usdw;
        uint256 usdwAmount_ = _transferIn(usdw_);
        _validate(usdwAmount_ > 0, 12);
        uint256 redemptionAmount_ = getRedemptionAmount(_tokenOut, usdwAmount_);
        _validate(redemptionAmount_ > 0, 15);
        _decreaseUsdwAmount(_tokenOut, usdwAmount_);
        _decreasePoolAmount(_tokenOut, redemptionAmount_);
        // check if the withdraw of the chose asset (_tokenOut) doesn't push the balance of the token under the bufferAmount
        _validateBufferAmount(_tokenOut);
        // USDW held in this contract (the vault) is burned  
        IUSDW(usdw_).burn(address(this), usdwAmount_);
        // the _transferIn call increased the value of tokenBalances[usdw]
        // usually decreases in token balances are synced by calling _transferOut
        // however, for usdw, the tokens are burnt, so _updateTokenBalance should
        // be manually called to record the decrease in tokens
        _updateTokenBalance(usdw_);
        uint256 feeBasisPoints_ = vaultUtils.getSellUsdwFeeBasisPoints(_tokenOut, usdwAmount_);
        // swap fee is collected in the outgoing token (so the token that is reedeemed)
        (uint256 amountOutAfterFees_,) = _collectSwapFees(_tokenOut, redemptionAmount_, feeBasisPoints_);
        _validate(amountOutAfterFees_ > 0, 10);
        _transferOut(_tokenOut, amountOutAfterFees_, _receiverTokenOut);
        emit SellUSDW(
            _receiverTokenOut, 
            _tokenOut, 
            usdwAmount_, 
            amountOutAfterFees_, 
            feeBasisPoints_
        );
        return amountOutAfterFees_;
    }

    /**
     * @notice function allowing a purchaser to buy a WLP asset with another WLP asset
     * @dev this function is generally used for arbitrage
     * @param _tokenIn address of the token that is being sold
     * @param _tokenOut address of token that is being bought
     * @param _receiver the address the tokenOut will be receive the _tokenOut
     * @return amountOutAfterFees_ amount of _tokenOut _receiver will be credited 
     */
    function swap(
        address _tokenIn, 
        address _tokenOut, 
        address _receiver) external override nonReentrant protocolNotPaused returns (uint256 amountOutAfterFees_) {
        _validate(isSwapEnabled, 17);
        _validate(whitelistedTokens[_tokenIn], 9);
        _validate(whitelistedTokens[_tokenOut], 9);
        _validate(_tokenIn != _tokenOut, 22);
        uint256 amountIn_ = _transferIn(_tokenIn);
        (amountOutAfterFees_,) = _swap(
            _tokenIn, 
            _tokenOut, 
            _receiver, 
            amountIn_, 
            false
        );
        return amountOutAfterFees_;
    }

    /** step 1 of rebalancing
     * @notice in this funciton the rebalancer contract borrows a certain amount of _tokenToRebalanceWith from the vault
     * @param _tokenToRebalanceWith address of the token that is going to be pulled/deducted by the rebalancing contract
     * @param _amountToRebalanceWith amount of the token that will be sold by the rebalancer contract
     */
    function rebalanceWithdraw(
        address _tokenToRebalanceWith,
        uint256 _amountToRebalanceWith
    ) external protocolNotPaused nonReentrant {
        _isRebalancer();
        _validate(whitelistedTokens[_tokenToRebalanceWith], 9);
        // add check if this doesn't do something we don't want (like withdraw a token that is already scarce in the vault?)
        uint256 priceIn_ = getMinPrice(_tokenToRebalanceWith);
        // adjust usdwAmounts by the same usdwAmount as debt is shifted between the assets
        uint256 usdwAmount_ = (_amountToRebalanceWith * priceIn_) / PRICE_PRECISION;
        usdwAmount_ = adjustForDecimals(usdwAmount_, _tokenToRebalanceWith, usdw);
        _decreaseUsdwAmount(_tokenToRebalanceWith, usdwAmount_);
        _decreasePoolAmount(_tokenToRebalanceWith, _amountToRebalanceWith);
        // check if the token leaving the vault isn't below the buffer amount now
        _validateBufferAmount(_tokenToRebalanceWith);
        // transfer the _tokenToRebalanceWith to the rebalancer contract
        _transferOut(_tokenToRebalanceWith, _amountToRebalanceWith, _msgSender());
        emit RebalancingWithdraw(
            _tokenToRebalanceWith,
            _amountToRebalanceWith
        );
    }

    /** step 2 of rebalancing. 
     * @dev only a contract that is allowed to rebalance (configured by the onlyTimeLockGovernance)
     * @param _tokenInDeposited address of the token that will be deposited in the pool
     * @param _amountDeposited amount of tokenIn that is 
     */
    function rebalanceDeposit(
        address _tokenInDeposited,
        uint256 _amountDeposited
    ) external nonReentrant protocolNotPaused {
        _isRebalancer();
        _validate(whitelistedTokens[_tokenInDeposited], 9);
        uint256 tokenAmount_ = _transferIn(_tokenInDeposited);
        _validate(tokenAmount_ > 0, 12);
        uint256 priceIn_ = getMinPrice(_tokenInDeposited);
        // adjust usdwAmounts by the same usdwAmount as debt is shifted between the assets
        uint256 usdwAmount_ = (_amountDeposited * priceIn_) / PRICE_PRECISION;
        usdwAmount_ = adjustForDecimals(usdwAmount_, _tokenInDeposited, usdw);
        // increase the deposited token balance registration
        _increaseUsdwAmount(_tokenInDeposited, usdwAmount_);
        // increase the pool amount, increasing/restoring the WLP value
        _increasePoolAmount(_tokenInDeposited, _amountDeposited);
        // update the token balance
        _updateTokenBalance(_tokenInDeposited);
        emit RebalancingDeposit(
            _tokenInDeposited,
            _amountDeposited
        );
    }

    /*==================== Internal functions *====================*/

     /**
     * @param _tokenIn address of the tokens being sold
     * @param _tokenOut address of the token being bought
     * @param _receiver address that will receive _receiver
     * @param _amountIn amount of _tokenIn being sold to the Vault
     * @param _feeLess bool signalling if a swapFee needs to be charged
     * @return amountOutAfterFees_ amount of _tokenOut that 
     * @return feesPaidInOut_ amount of swapFees charged in _tokenOut
     * @dev the swapFee is charged in the outgoing token (_tokenOut) 
     */
    function _swap(
        address _tokenIn, 
        address _tokenOut, 
        address _receiver,
        uint256 _amountIn,
        bool _feeLess
    ) internal returns (uint256 amountOutAfterFees_, uint256 feesPaidInOut_) {
        _validate(_amountIn > 0, 10);
        uint256 priceIn_ = getMinPrice(_tokenIn);
        uint256 amountOut_ = (_amountIn * priceIn_) / getMaxPrice(_tokenOut);
        amountOut_ = adjustForDecimals(amountOut_, _tokenIn, _tokenOut);
        // adjust usdwAmounts by the same usdwAmount as debt is shifted between the assets
        uint256 usdwAmount_ = (_amountIn * priceIn_) / PRICE_PRECISION;
        usdwAmount_ = adjustForDecimals(usdwAmount_, _tokenIn, usdw);
        uint256 feeBasisPoints_;
        if (_feeLess) {
            feeBasisPoints_ = 0;
            feesPaidInOut_ = 0;
            amountOutAfterFees_ = amountOut_;
        } else {
            feeBasisPoints_ = vaultUtils.getSwapFeeBasisPoints(_tokenIn, _tokenOut, usdwAmount_);
            // note: when swapping the swap fee is paid in the outgoing asset
            (amountOutAfterFees_, feesPaidInOut_) = _collectSwapFees(_tokenOut, amountOut_, feeBasisPoints_);
        }
        _increaseUsdwAmount(_tokenIn, usdwAmount_);
        _decreaseUsdwAmount(_tokenOut, usdwAmount_);
        _increasePoolAmount(_tokenIn, _amountIn);
        _decreasePoolAmount(_tokenOut, amountOut_);
        _validateBufferAmount(_tokenOut);
        _transferOut(_tokenOut, amountOutAfterFees_, _receiver);
        emit Swap(
            _receiver, 
            _tokenIn, 
            _tokenOut, 
            _amountIn, 
            amountOut_, 
            amountOutAfterFees_, 
            feeBasisPoints_
        );
        return (amountOutAfterFees_, feesPaidInOut_);
    }

    /**
     * @dev wager fees accumulate in this contract and need to be periodically sweeped
     * @param _tokenEscrowIn the address of the token the wagerFeeBasisPoints is charged over
     * @param _amountEscrow the amount of _token the wagerFeeBasisPoints is charged over
     * @return amountAfterWagerFee_ wager amount of the _token that is left after the fee is deducted
     * @return wagerFeeCharged_ amount of fee charged, denominated in _token (not USD value)
     * note the wagerFeeBasisPoints stays in the vault contract until it is farmed by the FeeCollector contract
     */
    function _collectWagerFees(
        address _tokenEscrowIn, 
        uint256 _amountEscrow) private returns (uint256 amountAfterWagerFee_, uint256 wagerFeeCharged_) {
        // using 1e18 scaling or wagerFee -  Scaling: 1e18 = 100% - 1e17 = 10% - 1e16 = 1%
        amountAfterWagerFee_ = (_amountEscrow * (1e18 - wagerFeeBasisPoints)) / 1e18;
        wagerFeeCharged_ = _amountEscrow - amountAfterWagerFee_;
        wagerFeeReserves[_tokenEscrowIn] += wagerFeeCharged_;
        return (amountAfterWagerFee_, wagerFeeCharged_);
    }

    /**
     * @dev swap fees arge charged over/on the outgoing token
     * @param _tokenAddress the address of the token the fees are charged over
     * @param _amountOfToken the amount of the ingoing 
     * @param _feeBasisPoints amount of baiss points (scaled 1e4)
     * @return amountOutAfterFees_ the amount of _tokenAddress that is left after fees are deducted
     * @return feesPaidInOut_ the amount of _tokenAddress that 'stays behind' in the vailt
     */
    function _collectSwapFees(
        address _tokenAddress, 
        uint256 _amountOfToken, 
        uint256 _feeBasisPoints) private returns (
            uint256 amountOutAfterFees_, 
            uint256 feesPaidInOut_) {
        amountOutAfterFees_ = (_amountOfToken * (BASIS_POINTS_DIVISOR - _feeBasisPoints)) / BASIS_POINTS_DIVISOR;
        feesPaidInOut_ = (_amountOfToken - amountOutAfterFees_);
        swapFeeReserves[_tokenAddress] += feesPaidInOut_;
        // emit CollectSwapFees(
        //     _tokenAddress, 
        //     tokenToUsdMin(_tokenAddress, feeAmount_), 
        //     feeAmount_
        // );
        return (amountOutAfterFees_, feesPaidInOut_);
    }

   /**
     * @notice internal payout function -  transfer the token to the recipient
     * @param _addressTokenOut the address of the token that will be transferred to the player
     * @param _toPayOnNet amount of _addressTokenOut the WLP will transfer to the  
     * @param _recipient the address of the recipient of the token _recipient
     */
    function _payoutPlayer(
        address _addressTokenOut,
        uint256 _toPayOnNet,
        address _recipient
    ) internal {
        // check if the configured buffer limits are not violated
        _transferOut(
            _addressTokenOut,
            _toPayOnNet, 
            _recipient
        );
        emit PlayerPayout(
            _recipient,
            _addressTokenOut,
            _toPayOnNet
        );
    }

    /**
     * @notice internal function that keeps track of the recorded incoming token transfers
     * @dev this function is crucial for the proper operation of swap and deposit functionality
     * @param _tokenIn address of the token that is (allegidly) transferred to the vault
     * @return amountTokenIn_ amount of _tokenIn that was transferred into the contract 
     */
    function _transferIn(address _tokenIn) private returns (uint256 amountTokenIn_) {
        uint256 prevBalance_ = tokenBalances[_tokenIn];
        uint256 nextBalance_ = IERC20(_tokenIn).balanceOf(address(this));
        tokenBalances[_tokenIn] = nextBalance_;
        amountTokenIn_ = (nextBalance_ - prevBalance_);
    }

    /**
     * @notice internal function that transfers tokens out to the receiver
     * @param _tokenOut address of the token transferred out
     * @param _amountOut amount of _token to send out of the vault
     * @param _receiver address that will receive the tokens
     */
    function _transferOut(
        address _tokenOut, 
        uint256 _amountOut, 
        address _receiver) private {
        SafeERC20.safeTransfer(IERC20(_tokenOut), _receiver, _amountOut);
        // update the tokenBalance of the outgoing token
        tokenBalances[_tokenOut] = IERC20(_tokenOut).balanceOf(address(this));
    }

    function _updateTokenBalance(address _tokenToUpdate) private {
        tokenBalances[_tokenToUpdate] = IERC20(_tokenToUpdate).balanceOf(address(this));
    }

    /**
     * @notice accounting function that increases the registered/realized WLP assets
     * @dev this is a very important function to understand! this function increases the value of WLP
     * @dev note that this is different from the tokenBalances! poolAmounts belong to the WLPs
     * @param _tokenIn  address of the token 
     * @param _amountToIncrease  amount to increment of the tokens poolAmounts
     */
    function _increasePoolAmount(
        address _tokenIn, 
        uint256 _amountToIncrease) private {
        poolAmounts[_tokenIn] += _amountToIncrease;
        // if the registered pool amounts are larger than the actual balance of the token, something went wrong in the accounting because this is technically a impossability - by definition the poolAmounts registered to WLPs will always be lower as the balance, even if the WLPs are in a net loss (historically). So this check is in place to essentially check if the vault isn't broken/exploited. 
        _validate(
            poolAmounts[_tokenIn] <= IERC20(_tokenIn).balanceOf(address(this)),
            11
        );
        // emit IncreasePoolAmount(_tokenIn, _amountToIncrease);
    }

    /**
     * @notice accounting function that decreases the registered/realized WLP assets
     * @dev this is a very important function to understand! this function decreases the value of WLP
     * @dev note that this is different from the tokenBalances! poolAmounts belong to the WLPs
     * @param _tokenOut  address of the token 
     * @param _amountToDecrease  amount to be deducted of the tokens poolAmounts
     */
    function _decreasePoolAmount(
        address _tokenOut, 
        uint256 _amountToDecrease) private {
        require(
            poolAmounts[_tokenOut] >= _amountToDecrease,
            "Vault: poolAmount exceeded"
        );
        poolAmounts[_tokenOut] -= _amountToDecrease;
        // emit DecreasePoolAmount(_tokenOut, _amountToDecrease);
    }

    /**
     * @dev this function should always be called after the _decreasePoolAmount is called!
     * @param _token address of the token
     */
    function _validateBufferAmount(address _token) private view {
        if (poolAmounts[_token] < bufferAmounts[_token]) {
            revert TokenBufferViolation(_token);
        }
    }

    function _isRebalancer() internal view {
        require(
            rebalancer == _msgSender() ,
            "Vault: Caller not rebalancer"
        );
    }

    /**
     * @notice increases the registered token-debt (in USDW)
     * @dev for each asset entering the vault, we register its USD value at the time it entered, the main use of this being that we can set max exposure in USD to a certain asset (for this maxUsdwAmount_ needs to be set)
     * @param _token  address of the token  
     * @param _amountToIncrease  amount the tokens maxUsdwAmounts mapping will be incremented
     */
    function _increaseUsdwAmount(
        address _token, 
        uint256 _amountToIncrease) private {
        usdwAmounts[_token] += _amountToIncrease;
        uint256 maxUsdwAmount_ = maxUsdwAmounts[_token];
        if (maxUsdwAmount_ != 0) {
            _validate(usdwAmounts[_token] <= maxUsdwAmount_, 8);
        }
        // emit IncreaseUsdwAmount(_token, _amountToIncrease);
    }

    /**
     * @notice decreases the registered token-debt (in USDW)
     * @dev when an asset leaves the pool, we deduct its USD value from the usdwAmounts, since the asset is not anymore 'on our books'.
     * @param _token  address of the token  
     * @param _amountToDecrease  amount the tokens maxUsdwAmounts mapping will be deducted
     */
    function _decreaseUsdwAmount(
        address _token, 
        uint256 _amountToDecrease) private {
        uint256 value_ = usdwAmounts[_token];
        // since USDW can be minted using multiple assets
        // it is possible for the USDW debt for a single asset to be less than zero
        // the USDW debt is capped to zero for this case
        if (value_ <= _amountToDecrease) {
            usdwAmounts[_token] = 0;
            // emit DecreaseUsdwAmount(_token, value_);
            return;
        }
        usdwAmounts[_token] = (value_ - _amountToDecrease);
        // emit DecreaseUsdwAmount(_token, _amountToDecrease);
    }

    /**
     * @notice internal require that checks if the caller is a manager
     */
    function _validateManager() private view {
        if (inManagerMode) {
            _validate(isManager[_msgSender()], 7);
        }
    }

    /**
     * @notice internal require checker to emit certain error messages 
     * @dev using internal function as to reduce contract size
     */
    function _validate(bool _condition, uint256 _errorCode) private view {
        require(_condition, errors[_errorCode]);
    }

    function _revertIfZero(uint256 _value) internal pure {
        if(_value == 0) {
            revert PriceZero();
        }
    }

    /*==================== View functions *====================*/

    /**
     * @notice returns the upperbound/maximum price of a asset
     * @dev the return value is scaled 1e30 (so $1 = 1e30)
     * @param _token address of the token/asset
     * @return priceUpperBound_ the amount of USD(scaled 1e30) 1 token unit of _token is worth using the upper price bound of the GMX oracle
     */
    function getMaxPrice(address _token) public override view returns (uint256 priceUpperBound_) {
        // note: the pricefeed being called is managed by GMX
        priceUpperBound_ = IOracleRouter(priceOracleRouter).getPriceMax(_token);
        _revertIfZero(priceUpperBound_);
    }

    /**
     * @notice returns the lowerbound/minimum price of the wlp asset
     * @dev the return value is scaled 1e30 (so $1 = 1e30)
     * @param _token address of the token/asset
     * @return priceLowerBound_ the amount of USD(scaled 1e30) 1 token unit of _token is worth using the lower price bound of the GMX oracle
     */
    function getMinPrice(address _token) public override view returns (uint256 priceLowerBound_) {
        // note: the pricefeed being called is managed by GMX
        priceLowerBound_ = IOracleRouter(priceOracleRouter).getPriceMin(_token);
        _revertIfZero(priceLowerBound_);
    }

    /**
     * @notice returns the amount of a specitic tokens can be redeemed for a certain amount of USDW 
     * @param _tokenOut address of the token/asset that to be redeemed
     * @param _usdwAmount amount of USDW that would be burned for the token/asset
     * @return redemptionAmount_ the amount of the _tokenOut that can be redeemed when burning the _usdwAmount in the vault
     */
    function getRedemptionAmount(
        address _tokenOut, 
        uint256 _usdwAmount) public override view returns (uint256 redemptionAmount_) {
        uint256 price_ = getMaxPrice(_tokenOut);
        redemptionAmount_ = (_usdwAmount * PRICE_PRECISION) / price_;
        redemptionAmount_ = adjustForDecimals(redemptionAmount_, usdw, _tokenOut);
    }

    /**
     * @notice function that scales multiplies and devides using the tokens decimals
     * @param _amount amount of the token (uints)
     * @param _tokenDiv address of the token to divide the product of _amount and _tokenMul with
     * @param _tokenMul address of the token to multiply _amount by
     * @return scaledAmount_ the scaled adjusted amount 
     */
    function adjustForDecimals(
        uint256 _amount, 
        address _tokenDiv, 
        address _tokenMul) public view returns (uint256 scaledAmount_) {
        // cache address to save on SLOADS
        address usdw_ = usdw;
        uint256 decimalsDiv_ = _tokenDiv == usdw_ ? USDW_DECIMALS : tokenDecimals[_tokenDiv];
        uint256 decimalsMul_ = _tokenMul == usdw_ ? USDW_DECIMALS : tokenDecimals[_tokenMul];
        scaledAmount_ = (_amount * (10 ** decimalsMul_)) / (10 ** decimalsDiv_);
    }

    /**
     * @notice function returns how much USD a certain amount of a token is worth
     * @dev the _tokenToPrice needs to be available in the GMX pricefeed
     * @param _tokenToPrice address of the token to price/value
     * @param _tokenAmount amount of the token you want to know the USD value of
     * @return usdAmount_ amount of USD(1e30 scaled) a _tokenAmount is worth using the lower price bound of the oracle
     */
    function tokenToUsdMin(
        address _tokenToPrice, 
        uint256 _tokenAmount) public override view returns (uint256 usdAmount_) {
        // using the lower price bound of the asset
        uint256 price_ = getMinPrice(_tokenToPrice);
        uint256 decimals_ = tokenDecimals[_tokenToPrice];
        usdAmount_ = (_tokenAmount * price_) / (10 ** decimals_);
    }

    /**
     * @notice function that returns the amount of tokens a certain amount of USD is worth - pricing by lower bound
     * @dev this function uses the lower bound price, so the price/value for outgoing assets this is at the benefit of the WLPs 
     * @param _tokenToPrice address of the token to price/value
     * @param _usdAmount amount of USD (in 1e30) you want to price
     * @return tokenAmountMax_ amount of the token the _usdAmount is worth 
     */
    function usdToTokenMax(
        address _tokenToPrice, 
        uint256 _usdAmount) public view returns (uint256 tokenAmountMax_) {
        // using the lower price bound of the asset
        tokenAmountMax_ = usdToToken(
            _tokenToPrice, 
            _usdAmount, 
            getMinPrice(_tokenToPrice)
        );
    }

    /**
     * @notice function that returns the amount of tokens a certain amount of USD is worth - pricing by upper bound
     * @dev this function uses the upper bound price, so the price/value is for incoming assets at the benefit of the WLPs
     * @param _tokenToPrice address of the token being queried
     * @param _usdAmount amount of USD (in 1e30) you want to price
     * @return tokenAmountMin_ amount of the token the _usdAmount is worth 
     */
    function usdToTokenMin(
        address _tokenToPrice, 
        uint256 _usdAmount) public view returns (uint256 tokenAmountMin_) {
        tokenAmountMin_ = usdToToken(
            _tokenToPrice, 
            _usdAmount, 
            getMaxPrice(_tokenToPrice)
        );
    }

    /**
     * @notice function that returns how much of a token is worth a certain amount of USD
     * @dev note: 1 USD value is 1e30 when plugged into _usdAmount
     * @param _token address of the token
     * @param _usdAmount amount of usd (1 usd = 1e30)
     * @param _priceToken the price of the token
     * @return tokenAmount_ amount of units of a token
     */
    function usdToToken(
        address _token, 
        uint256 _usdAmount, 
        uint256 _priceToken) public view returns (uint256 tokenAmount_) {
        uint256 decimals_ = tokenDecimals[_token];
        tokenAmount_ = ((_usdAmount * (10 ** decimals_)) / _priceToken);
    }

    function allWhitelistedTokensLength() external override view returns (uint256 whitelistedLength_) {
        whitelistedLength_ = allWhitelistedTokens.length;
    }

    /**
     * @notice returns the aggregated count of a token (total in all time, total out all time)
     * @param token_ address of the token to return the aggragated total of
     */
    function returnTotalInAndOut(address token_) external view returns(uint256 totalOutAllTime_, uint256 totalInAllTime_) {
        return(totalOut_[token_], totalIn_[token_]);
    }

    /*==================== View functions Winr/JB *====================*/
    
    /**
     * @notice returns the usd value of all the assets in the wlp combined (only the realized ones)
     * @dev take note that usd value is scaled 1e30 not 1e18
     */
    function getReserve() external override view returns(uint256 totalReserveValue_) {
        totalReserveValue_ = IWLPManager(wlpManagerAddress).getAum(false);
    }

    /**
     * @notice returns the USD value (in 1e30 = $1) of a certain amount of tokens
     * @dev take note that usd value is scaled 1e30 not 1e18
     * @param _token address of the token
     * @return usdValue_ usd value of the token
     */
    function getDollarValue(address _token) external view returns (uint256 usdValue_) {
        usdValue_ = getMinPrice(_token);
    }

    /**
     * @notice returns the USD(scaled 1e30) value of 1 WLP token
     */
    function getWlpValue() external view returns (uint256 wlpValue_) {
        wlpValue_ = IWLPManager(wlpManagerAddress).getPriceWlp(false);
    }

    /**
     * @notice function converts equivalent value from tokenIn to tokenOut
     * @dev this is mainly used for a multi-asset payout, the VM/Game represents a players winnings in its wagerAsset, with help of this function we convert the wagerAsset into the requested winningAsset by the plater
     * @param _tokenInAddress address of the token the value is expressed in
     * @param _tokenOutAddress address of the token you want this value to be expressed in
     * @param _amountIn amount of tokenIn (that you want to convert to a token amount in _tokenInAddress)
     * @return amountTokenOut_ amount of tokens _tokenOutAddress 
     */
    function _amountOfTokenForToken(
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _amountIn
    ) internal view returns(uint256 amountTokenOut_) {
        // convert tokenin amount to tokenput
        amountTokenOut_ = (_amountIn * getMinPrice(_tokenInAddress)) / getMaxPrice(_tokenOutAddress);
        // convert decimal notation
        amountTokenOut_ = adjustForDecimals(
            amountTokenOut_, 
            _tokenInAddress, 
            _tokenOutAddress
        );
        return amountTokenOut_;
    }

    /**
     * @notice returns how much value (in usd) of a certain token the vault should have according to its weight
     * @dev this function is used to determine if a certain asset is scarce in the pool
     * @param _token address of the token
     */
    function getTargetUsdwAmount(address _token) public override view returns (uint256 usdwAmount_) {
        uint256 supply_ = IERC20(usdw).totalSupply();
        if (supply_ == 0) { return 0; }
        uint256 weight_ = tokenWeights[_token];
        usdwAmount_ = ((weight_ * supply_) / totalTokenWeights);
    }

    /*==================== Timelocked / controversial functions (onlyTimelockGovernance) *====================*/

    /**
     * @notice migration function to a new vault
     * @dev this is a timelocked feature since it moves WLP owned tokens to a different address
     * @param _newVault address of the new vault
     * @param _token address of the token to migrate
     * @param _amount amount to migrate the token to
     * @param _upgrade bool singalling if the balances need to be updated
     * note todo probably we should check more stuff here! like if it is paused and all that!
     */
    function upgradeVault(
        address _newVault, 
        address _token, 
        uint256 _amount,
        bool _upgrade) external onlyTimelockGovernance {
        SafeERC20.safeTransfer(IERC20(_token), _newVault, _amount);
        if(_upgrade) {
            _decreasePoolAmount(_token, _amount);
            _updateTokenBalance(_token);
        }
    }

    /**
     * @notice function that changes the feecollector contract
     * @param _feeCollector address of the (new) feecollector
     */
    function setFeeCollector(address _feeCollector) external onlyTimelockGovernance {
        feeCollector = _feeCollector;
    }

    /**
     * @notice function that changes the vaultmanager contract
     * @param _vaultManagerAddress address of the (new) vaultmanager
     */
    function setVaultManagerAddress(address _vaultManagerAddress) external override onlyTimelockGovernance {
        vaultManagerAddress = _vaultManagerAddress;
    }

    /**
     * @dev due to the imporance of the priceOracleRouter, this function is protected by the timelocked modifier
     * @param _priceOracleRouter address of the price feed
     */
    function setPriceFeedRouter(address _priceOracleRouter) external override onlyTimelockGovernance {
        priceOracleRouter = _priceOracleRouter;
    }

    /**
     * @dev due to the right the rebalancer has, this function is protected by the timelocked modifier
     * @param _rebalancerAddress address of a contract allowed to rebalance
     */
    function setRebalancer(
        address _rebalancerAddress
    ) external onlyTimelockGovernance {
        rebalancer = _rebalancerAddress;
    }

    /*==================== Emergency intervention functions (onlyEmergency) *====================*/

    /**
     * @notice configuration function that sets the types of fees charged by the vault
     * @dev remember that 1e4 = 100% (so scaled by 1e4)
     * @param _taxBasisPoints tax basis points (incentive/punish (re/un)balancing)
     * @param _stableTaxBasisPoints stable swap basis points
     * @param _mintBurnFeeBasisPoints basis point tax/fee for minting/burning
     * @param _swapFeeBasisPoints swap fee basis piint
     * @param _stableSwapFeeBasisPoints base swap fee for stable -> stable swaps
     * @param _hasDynamicFees bool signifiying if the dynamic swap fee mechanism needs to be enabled
     */
    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _minimumBurnMintFee,
        bool _hasDynamicFees
    ) external override onlyGovernance {
        _validate(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, 2);
        _validate(_stableTaxBasisPoints <= MAX_FEE_BASIS_POINTS, 3);
        _validate(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 4);
        _validate(_swapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 5);
        _validate(_stableSwapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 6);
        _validate(_minimumBurnMintFee <= MAX_FEE_BASIS_POINTS, 6);
        taxBasisPoints = _taxBasisPoints;
        stableTaxBasisPoints = _stableTaxBasisPoints;
        mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
        swapFeeBasisPoints = _swapFeeBasisPoints;
        stableSwapFeeBasisPoints = _stableSwapFeeBasisPoints;
        minimumBurnMintFee = _minimumBurnMintFee;
        hasDynamicFees = _hasDynamicFees;
    }

    /**
     * @notice economic configuration function to set a token confugration
     * @param _token address of the token
     * @param _tokenDecimals amount of decimals that the token is denominated in 
     * @param _tokenWeight the weight (relative) the token will have in the pool/vault
     * @param _maxUsdwAmount maximum USDW debt of the token that the vault will maximally hold
     * @param _isStable if the token is a stable coin/token
     */
    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _maxUsdwAmount,
        bool _isStable
    ) external override onlyGovernance {
        // increment token count for the first time
        if (!whitelistedTokens[_token]) {
            allWhitelistedTokens.push(_token);
        }
        uint256 _totalTokenWeights = totalTokenWeights;
        _totalTokenWeights -= tokenWeights[_token];
        whitelistedTokens[_token] = true;
        tokenDecimals[_token] = _tokenDecimals;
        tokenWeights[_token] = _tokenWeight;
        maxUsdwAmounts[_token] = _maxUsdwAmount;
        stableTokens[_token] = _isStable;
        totalTokenWeights = (_totalTokenWeights + _tokenWeight);
        // check if the oracle returns a price for this token
        getMaxPrice(_token);
    }

    /**
     * @notice function that deletes the configuration of a certain token
     * @param _token address of the token 
     */
    function clearTokenConfig(address _token) external onlyGovernance {
        _validate(whitelistedTokens[_token], 9);
        totalTokenWeights -= tokenWeights[_token];
        delete whitelistedTokens[_token];
        delete tokenDecimals[_token];
        delete tokenWeights[_token];
        delete maxUsdwAmounts[_token];
        delete stableTokens[_token];
    }

    /**
     * @notice update the token balance sync in the contract
     * @dev this function should be called in cases where for some reason tokens end up on the contract 
     * @param _token address of the token to be updated
     */
    function updateTokenBalance(address _token) external onlyEmergency {
        _updateTokenBalance(_token);
    }

    /**
     * @notice function that flips if traders can swap/trade with the vault or not
     * @dev when enabled no external entities will be able to swap 
     * @param _isSwapEnabled what to flip the isSwapEnabled to
     */
    function setIsSwapEnabled(bool _isSwapEnabled) external override onlyEmergency {
        isSwapEnabled = _isSwapEnabled;
    }

    /**
     * @notice function that flips if the vault performs payouts or not
     * @param _setting what to flip the payoutsHalted to
     */
    function setPayoutHalted(bool _setting) external onlyEmergency {
        payoutsHalted = _setting;
    }

  /*==================== Configuration functions non-economic / operational (onlyGovernance) *====================*/

    function setVaultUtils(IVaultUtils _vaultUtils) external override onlyGovernance {
        vaultUtils = _vaultUtils;
    }

    /**
     * @notice configuration function that can change/add a config function
     * @param _errorCode uint pointing to a certain error code
     * @param _error string of new error code
     */
    function setError(uint256 _errorCode, string calldata _error) external override {
        _validate(!isInitialized, 1);
        errors[_errorCode] = _error;
    }

    function setAsideReferral(address _token, uint256 _amountSetAside) external onlyManager override {
        referralReserves[_token] += _amountSetAside;
    }

    /*==================== Configuration functions Economic (onlyGovernance / onlyManager) *====================*/

    /**
     * @notice configuration function that enables or disbles feeless swapping for payouts
     * @param _setting new setting for the switch
     */
    function setFeeLessForPayout(bool _setting) external override onlyGovernance {
        feelessSwapForPayout = _setting;
    }

    /**
     * @notice configuration function to set the amount of wagerFees
     * @param _wagerFee uint configuration for the wagerfee
     */
    function setWagerFee(uint256 _wagerFee) external override onlyManager {
        require(
            _wagerFee <= MAX_WAGER_FEE,
            "Vault: Wagerfee exceed maximum"
        );
        wagerFeeBasisPoints = _wagerFee;
        emit WagerFeeChanged(_wagerFee);
    }

    /**
     * @notice enanables managed mode - when enabled only addresses configured as mananager can mint usdw (so wlpManager for example)
     */
    function setInManagerMode(bool _inManagerMode) external override onlyGovernance {
        inManagerMode = _inManagerMode;
    }

    /**
     * @notice configuration function that can add/remove contracts/addressees that are allowed to mint/redeem USDW
     * @dev take note that the WLPManager mints the WLP, the vault mints USDW
     * @param _manager address of the manager to add/remove
     * @param _isManager bool that determines if a manager is added or removed
     */
    function setManager(address _manager, bool _isManager, bool _isWLPManager) external override onlyGovernance {
        isManager[_manager] = _isManager;
        if(_isWLPManager) {
            wlpManagerAddress = _manager;
        }
    }

    /**
     * @notice configuration function to set a minimum amount of a certain asset
     * @param _token address of the token
     * @param _amount buffer amount to be set
     */
    function setBufferAmount(address _token, uint256 _amount) external override onlyGovernance {
        bufferAmounts[_token] = _amount;
    }
   
    /**
     * @param _token address of the token
     * @param _amount amount of the USDW to set 
     */
    function setUsdwAmount(
        address _token, 
        uint256 _amount) external override onlyGovernance {
        uint256 usdwAmount_ = usdwAmounts[_token];
        if (_amount > usdwAmount_) {
            _increaseUsdwAmount(_token, (_amount - usdwAmount_));
        } else {
            _decreaseUsdwAmount(_token, (usdwAmount_ -_amount));
        }
    }

    /**
     * @notice configuration function to edit/change poolbalances
     * @dev note that this function can drascitally change the WLP value 
     * @param _token address of the token 
     * @param _amount amount to configure in poolAmounts
     * todo note consider making this a timelocked modifier since this has quite a large effect!
     */
    function setPoolBalance(address _token, uint256 _amount) external onlyGovernance {
        poolAmounts[_token] = _amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IOracleRouter {
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
    function getPriceMax(address _token) external view returns (uint256);
    function primaryPriceFeed() external view returns (address);
    function getPriceMin(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function adjustmentBasisPoints(address _token) external view returns (uint256);
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
    event DirectPoolDeposit(address token, uint256 amount);
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

    event WithdrawAllFees(
        address tokenCollected,
        uint256 swapFeesCollected,
        uint256 wagerFeesCollected,
        uint256 referralFeesCollected
    );

    event RebalancingWithdraw(
        address tokenWithdrawn,
        uint256 amountWithdrawn
    );

    event RebalancingDeposit(
        address tokenDeposit,
        uint256 amountDeposit
    );

    event WagerFeeChanged(
        uint256 newWagerFee
    );

    /*==================== Operational Functions *====================*/
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;
    function router() external view returns (address);
    function usdw() external view returns (address);
    function feeCollector() external returns(address);
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
    function addLiquidityFeeCollector(
        address _token, 
        uint256 _amount, 
        uint256 _minUsdw, 
        uint256 _minWlp) external returns (uint256 wlpAmount_);


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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev This contract designed to easing token transfers broadcasting information between contracts
interface IVaultManager {
  /// @notice escrow tokens into the manager
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function escrow(address _token, address _sender, uint256 _amount) external;

  /// @notice release some amount of escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient holder of tokens
  /// @param _amount the amount of token
  function payback(address _token, address _recipient, uint256 _amount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _amount the amount of token
  function getEscrowedTokens(address _token, uint256 _amount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  function payout(address[2] memory _tokens, address _recipient, uint256 _escrowAmount, uint256 _totalAmount) external;

  /// @notice lets vault get wager amount from escrowed tokens
  function payin(address _token, uint256 _escrowAmount) external;

  /// @notice transfers any whitelisted token into here
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _sender holder of tokens
  /// @param _amount the amount of token
  function transferIn(address _token, address _sender, uint256 _amount) external;

  /// @notice transfers any whitelisted token to recipient
  /// @param _token one of the whitelisted tokens which is collected in settings
  /// @param _recipient of tokens
  /// @param _amount the amount of token
  function transferOut(address _token, address _recipient, uint256 _amount) external;

  /// @notice transfers WLP tokens from this contract to Fee Collector and triggers Fee Collector
  /// @param _fee the amount of WLP sends to Fee Controller
  function transferWLPFee(uint256 _fee) external;

  function getMaxWager() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUSDW {

    event VaultAdded(
        address vaultAddress
    );

    event VaultRemoved(
        address vaultAddress
    );

    function addVault(address _vault) external;
    function removeVault(address _vault) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
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