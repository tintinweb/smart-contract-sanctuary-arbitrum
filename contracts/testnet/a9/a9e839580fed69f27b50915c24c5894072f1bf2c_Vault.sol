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

    modifier isGlobalPause() {
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
import "solmate/src/utils/SafeTransferLib.sol";
import "../interfaces/tokens/wlp/IUSDW.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/gmx/IVaultPriceFeedGMX.sol";
import "../interfaces/jbcontracts/IVaultManager.sol";
import "../interfaces/core/IWLPManager.sol";
import "./AccessControlBase.sol";

contract Vault is ReentrancyGuard, AccessControlBase, IVault {
    /*==================== Constants *====================*/
    uint256 private constant BASIS_POINTS_DIVISOR = 1e4;
    uint256 private constant PRICE_PRECISION = 1e30;
    uint256 private constant USDW_DECIMALS = 18;
    uint256 private constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint256 private constant MAX_WAGER_FEE = 1500; // 15%

    /*==================== State Variables *====================*/
    bool public override isInitialized;
    bool public override isSwapEnabled = true;
    IVaultUtils public vaultUtils;
    address public errorController;
    address public override router;
    address public override priceFeed;
    address public override usdw;
    uint256 public override whitelistedTokenCount;

    // all the fees are in basis points, scaled 1e4, so 100% = 1e4
    uint256 public override taxBasisPoints = 50; // 0.5%
    uint256 public override stableTaxBasisPoints = 20; // 0.2%
    uint256 public override mintBurnFeeBasisPoints = 30; // 0.3%
    uint256 public override swapFeeBasisPoints = 30; // 0.3%
    uint256 public override stableSwapFeeBasisPoints = 4; // 0.04%
    bool public override hasDynamicFees = false;
    uint256 public override totalTokenWeights;
    bool public override inManagerMode = false;
    mapping (address => bool) public override isManager;
    address private managerAddress;
    address[] public override allWhitelistedTokens;
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
    // feeReserves tracks the amount of fees per token
    mapping (address => uint256) public override feeReserves;
    mapping (uint256 => string) public errors;

    error TokenBufferViolation(address tokenAddress);
    error PriceZero();

    /*==================== State Variables Custom WINR/JB *====================*/

    // if set to true, all swaps by the payout function will not 
    bool public feelessSwapForPayout = false;
    address public override vaultManagerAddress;
    bool private payoutsHalted = false;
    // mapping that stores the amount of wager fees accumulated per vault aset
    // tokenAddress => amountOfWagerFees accumulated
    mapping (address => uint256) public override wagerFeeReserves;
    // percentage fee that will be charged over every wager coming into the contract
    uint256 public override wagerFee;
    // address of the feeCollector contract (only contract allowed to harest swap and wager fees)
    address public feeCollector;
    mapping(address => bool) public rebalancer;

    constructor(
        address _vaultRegistry,
        address _timelock
    ) AccessControlBase(_vaultRegistry, _timelock) {}

    // note; initializer can only be called once
    function initialize(
        address _router,
        address _usdw,
        address _priceFeed
    ) external onlyGovernance {
        _validate(!isInitialized, 1);
        isInitialized = true;
        router = _router;
        usdw = _usdw;
        priceFeed = _priceFeed;
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
    ) external override nonReentrant isGlobalPause {
        _validate(_totalAmount > 0, 27);
        _validate(_escrowAmount > 0, 27);
        _validate(whitelistedTokens[_tokens[0]], 14);
        _validate(whitelistedTokens[_tokens[1]], 14);
        // todo fix the error message of vaultmaanger!
        _validate(_msgSender() == vaultManagerAddress, 15);
        // todo fix the erro message!
        _validate(!payoutsHalted, 15);
        // cache the balacne of the incoming token 
        uint256 balanceBefore_ = ERC20(_tokens[0]).balanceOf(address(this));
        // pull the escrowed tokens from the escrow contract
        IVaultManager(_escrowAddress).getEscrowedTokens(_tokens[0], _escrowAmount);
        // note: this check is sort of optional - in the current design of VaultManager faulure of transfer would already fail the getEscrowedTokens external call
        require(
            (balanceBefore_ + _escrowAmount) == ERC20(_tokens[0]).balanceOf(address(this)),
            "Vault: EscrowIn was unsuccessful"
        );
        // collect the wager fees, charged in the wager token _tokens[0]
        (uint256 amountAfterWagerFee_, uint256 wagerFee_) = _collectWagerFees(_tokens[0], _escrowAmount);
        // note: the wager fee is charged over the incoming asset (the wagerAsset, _tokens[0])
        // note: the wagerFee stays in the Vault  (for now) however it is not part of the WLP anymore!
        // note: the _escrowAmount now resides in this contract. we have not yet done any pool or tokenbalance accounting
        // how much the WLP contract will have to pay on net
        uint256 toPayOnNet_;
        // if the the wager and the payout token are the same no swap is needed  
        if (_tokens[0] == _tokens[1]) { // token in, is the same as token out
            // calculate how much the WLP needs to pay to the recipient, we deduct the wagerFee off the totalAmount won by the player, since that will stay in this contract
            //  wagerFee_ cannot be larger as _totalAmount since the wagerFee cannot be higher as 100% 
            toPayOnNet_ = _totalAmount - wagerFee_;
            // the wagerFee leaves the pool 'accounting wise' hence we deduct the _escrowAmount from the winnings, even though the wagerFee remains in the vault
            /**
             * For the bookkeeping, we need to calculate how much net loss the WLP/LPs have due to this payout.
             * The WLP has received the _escrowAmount. The wager fee is not part of the WLP profit so we will not take it into account.
             */
            uint256 _amountNetLoss;
            if (amountAfterWagerFee_ <= _totalAmount) {
                // the WLP Lps have a loss, the wagerFee is not fully for the WLP, so we deduct amountAfterWagerFee_ instead
                _amountNetLoss = _totalAmount - amountAfterWagerFee_;
                // decrease the amount the WLP has to pay (accounting)
                _decreasePoolAmount(_tokens[1], _amountNetLoss);
            } else {
                // in this case (which is unusual, the pool has actually made a profit) - as before the wagerFee is not part of the profits of the WLPs so we exclusde it by deducting totalAmount from amountAfterWagerFee_
                _amountNetLoss = amountAfterWagerFee_ - _totalAmount;
                // with the incoming escrow being larger as the payout, the vault actually made a profit
                _increasePoolAmount(_tokens[1], _amountNetLoss);
            }
            // transfer the tokens to the player and do accounting ofthe internal balances
            _payout(
                _tokens[1], // _addressTokenOut (same as _tokens[0])
                toPayOnNet_,  // _toPayOnNet
                _recipient // _recipient
            );
        } else { // token in, is different from token out
            // the player wants the totalAmount in a different asset, so we need to swap in this section
            uint256 amountOutTokenOut_ = _amountOfTokenForToken(
                _tokens[0],
                _tokens[1], 
                (_totalAmount - wagerFee_)
            );
            if(amountOutTokenOut_ == 0) {
                return;
            }
            // note _totalAmount is denominated in _tokens[0], so we first need to convert it to _tokens[1]
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
                    true
                );
                // note uncessary, undeclared variable are 0
                feesPaidInOut_= 0;
            }
            // fist we calculate how much convert the _totalAmount is when converted into _tokens[1] asset
            // note: we deduct de wager fee from the _totalAmount since here, since it is now still denominated in the same asset.
            // note: the wagerFee is always deducted from the escrow and hence also needs to be deducted from the winning amount
            // uint256 amountOutTokenOut_ = _amountOfTokenForToken(
            //     _tokens[0],
            //     _tokens[1], 
            //     (_totalAmount - wagerFee_)
            // );
            // if(amountOutTokenOut_ == 0) {
            //     return;
            // }
            // note: what if amountOutTokenOut_ is 0?
            /**
             * note todo kk; we could consider adding a sanity check of the amountOutTokenOut_ value. Meaning if an attacker somehow has maniputated the oracles so that it seems like _tokens[0] is super expensive (that it actually is) then the amountOutTokenOut_ could be aggressively high. We could consider to check if amountOutTokenOut_ is not more than x % of the reserves or something else. I personally don't think it is really needed - but it can be considered.
            */
            /**
             * due to the swap (the tokenOut proceeds went to this contract) the balance of both _tokens[0] and _tokens[1] is different than the contract has registered in the tokenBalances mapping. 
             * If we do not update the tokenBalances mapping, in the next swap for _tokens[0] the contract will calculate an invalid amount of incoming assets. 
             * _tokens[1] will already be updated in the _transferOut tx, that is why now we only need to update the _tokens[0] mapping using the _updateTokenBalance function
             */
            _updateTokenBalance(_tokens[0]);
            // Calculate how much the WLP needs to pay the player on net. we deduct the feesPaid in the swap since these stay in the contract. We do not need to deduct that wagerFee since we already deducted that in the step where we calculated  amountOutTokenOut_. amountOutTokenOut_ cannot be higher as feesPaidInOut_ because the swap fee is a percentage (small as 100) that is 
            toPayOnNet_ = (amountOutTokenOut_ - feesPaidInOut_);
            uint256 _amountNetLoss;
            // even though it would be unusual for this if statement to be false, we still add this logic in case
            if (amountOutTokenOut_ >= amountOutAfterSwap_) {
                 // the swap fees earned not owned by the WLP LPs exclusively, so we don't add them 
                _amountNetLoss = amountOutTokenOut_ - amountOutAfterSwap_;
                // we register the loss with the pool balances
                _decreasePoolAmount(_tokens[1], _amountNetLoss);
                // the value of the WLP has decreased
            } else {
                // in this case, the wlp pool actually made a profit (quite unusual, but we still want to handle this situation)
                _amountNetLoss = amountOutAfterSwap_ - amountOutTokenOut_;
                // we register the profit with the pool balances
                _increasePoolAmount(_tokens[1], _amountNetLoss);
                // the value of the WLP has increased
            }
            // note: the swapFee stays in the Vault  (for now) however it is not part of the WLP anymore! the _swap function has already done the _updateTokenBalance so we do not need to do that anymore
            // transfer the tokens to the player and do accounting ofthe internal balances
            _payout(
                _tokens[1], 
                toPayOnNet_, 
                _recipient
            );
        }
    }

    /**
     * @notice function called by the vault manager to add assets to the WLP (profit)
     * @dev can only be called by the vault manager
     * @dev a wagerFee will be charged over the incoming assets
     * @param _inputToken the address of the escrowed token
     * @param _escrowAddress the address where the _inputToken is in escrow
     * @param _escrowAmount the amount of the _inputToken that is held in escrow
     */
    function payin(
        address _inputToken,
        address _escrowAddress,
        uint256 _escrowAmount) external nonReentrant isGlobalPause {
        // check if the incoming payin asset is whitelisted
        _validate(whitelistedTokens[_inputToken], 14);
        // note check error message correctness!
        _validate(_escrowAmount > 0, 15); 
        // todo fix the error message of vaultmaanger!
        _validate(_msgSender() == vaultManagerAddress, 15);
        // pull the ecrowed tokens to the vault from the vault manager
        IVaultManager(_escrowAddress).getEscrowedTokens(_inputToken, _escrowAmount);
        // note: the escrowed tokens now sit in this contract
        // deduct the wager fees from the escrowed tokens
        (uint256 amountAfterWagerFee_,) = _collectWagerFees(_inputToken, _escrowAmount);
        // note the wagerFees collected remain in this contract, but they are not part of the profit/value of the WLP LPs
        // add the tokens to the WLP, this will incrase the value of the wlp
        _increasePoolAmount(_inputToken, amountAfterWagerFee_);
        // update the balace of tokenBalances to ensure that the next swapper for this token isn't credited for this payin
        _updateTokenBalance(_inputToken);
        emit PayinWLP(
            _inputToken,
            _escrowAmount,
            tokenToUsdMin(_inputToken, _escrowAmount)
        );
    }

    /*==================== Operational functions WINR/JB *====================*/

    /**
     * @notice function that adds a whitelisted asset to the pool, without issuance of WLP or USDW!
     * @param _tokenIn address of the token to directly deposit into the pool
     * @dev take note that depositing LP by this means will NOT mint WLP to the caller. This function would only make sense to use if called by the WINR DAO. If you call this function you will receive nothing in return, it is effectively gifting liquidity to the pool without getting anything back.
     * DO NOT USE THIS FUNCTION IF YOU WANT TO RECEIVE WLP!
     */
    function directPoolDeposit(address _tokenIn) external override isGlobalPause {
        require(
            ERC20(usdw).totalSupply() > 0,
            "Vault: USDW supply 0"
        );
        _validate(whitelistedTokens[_tokenIn], 14);
        uint256 tokenAmount_ = _transferIn(_tokenIn);
        _validate(tokenAmount_ > 0, 15);
        _increasePoolAmount(_tokenIn, tokenAmount_);
        emit DirectPoolDeposit(_tokenIn, tokenAmount_);
    }

    /**
     * @dev function can only be called by the feecollector
     * @param _token token address to withdraw aggregated fees of
     * @return amountWagerFee_ amount left after deduction of wager fee
     */
    function withdrawWagerFees(address _token) external override isGlobalPause returns (uint256 amountWagerFee_) {
        //  cache address to save on SLOADS
        address feeCollector_ = feeCollector;
        require(
            _msgSender() == feeCollector_,
            "Vault: Caller must be feecollector"
        );
        amountWagerFee_ = wagerFeeReserves[_token];
        if(amountWagerFee_ == 0) { return 0; }
        wagerFeeReserves[_token] = 0;
        _transferOut(_token, amountWagerFee_, feeCollector_);
        return amountWagerFee_;
    }

    /**
     * @notice function that withdraws the swap fees and transfers them to the feeCollector contract
     * @dev this does't withdraw the wager fee reserves! also function only withdraws aggregated swap fees of one type of whitelisted token
     * @dev function can only be called by the FeeCollector
     * @param _tokenToWithdraw the address of the token you want to withdraw fees from
     * todo consider hardcoding the _receiver so that the tokens can only ever go to one address
     * note removed onlyGoverance and replaced for the require 
     */ 
    function withdrawSwapFees(address _tokenToWithdraw) external override isGlobalPause returns (uint256 amountCollected_) {
        address feeCollector_ = feeCollector;
        require(
            _msgSender() == feeCollector_,
            "Vault: Caller must be feecollector"
        );
        amountCollected_ = feeReserves[_tokenToWithdraw];
        if(amountCollected_ == 0) { return 0; }
        feeReserves[_tokenToWithdraw] = 0;
        _transferOut(_tokenToWithdraw, amountCollected_, feeCollector_);
        return amountCollected_;
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
        address _receiverUSDW) external override isGlobalPause nonReentrant returns (uint256 mintAmountUsdw_) {
        _validateManager();
        _validate(whitelistedTokens[_tokenIn], 16);
        uint256 tokenAmount_ = _transferIn(_tokenIn);
        _validate(tokenAmount_ > 0, 17);
        // fetch the price of the incoming token, the vault always prices an incoming asset by its lower bound price (so in the benefit of the WLPs)
        uint256 price_ = getMinPrice(_tokenIn);
        // cache to memory  usdw address to save on sloads
        address usdw_ = usdw;
        uint256 usdwAmount_ = (tokenAmount_ * price_) / PRICE_PRECISION;
        usdwAmount_ = adjustForDecimals(usdwAmount_, _tokenIn, usdw_);
        _validate(usdwAmount_ > 0, 18);
        uint256 feeBasisPoints_ = vaultUtils.getBuyUsdwFeeBasisPoints(_tokenIn, usdwAmount_);
        // note: the swapfee is charged in the incoming token (so in _tokenIn)
        (uint256 amountAfterFees_,) = _collectSwapFees(_tokenIn, tokenAmount_, feeBasisPoints_);
        // calculate the USDW value of the deposit
        mintAmountUsdw_ = (amountAfterFees_ * price_) / PRICE_PRECISION;
        mintAmountUsdw_ = adjustForDecimals(mintAmountUsdw_, _tokenIn, usdw_);
        // increase the _tokenIn debt (in usdw)
        _increaseUsdwAmount(_tokenIn, mintAmountUsdw_);
        _increasePoolAmount(_tokenIn, amountAfterFees_);
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
     * @notice redeem wlp for asset of choice (burn wlp, withdraw asset) -> sellUSDW/sellUSDG
     * @param _tokenOut the address of the token the seller wants to redeem his USDW for
     * @param _receiverTokenOut the address that will receive the _tokenOut (so the asset the withdrawer is redeeming their WLP for)
     * @return amountOut the amount of _tokenOut that the receiver has redeemed
     * @dev when ManagerMode is enabled, this function can only be called by the wlpManager contract!
     */
    function withdraw(
        address _tokenOut, 
        address _receiverTokenOut) external isGlobalPause override nonReentrant returns (uint256) {
        _validateManager();
        _validate(whitelistedTokens[_tokenOut], 19);
        address usdw_ = usdw;
        uint256 usdwAmount_ = _transferIn(usdw_);
        _validate(usdwAmount_ > 0, 20);
        uint256 redemptionAmount = getRedemptionAmount(_tokenOut, usdwAmount_);
        _validate(redemptionAmount > 0, 21);
        _decreaseUsdwAmount(_tokenOut, usdwAmount_);
        _decreasePoolAmount(_tokenOut, redemptionAmount);
        // NEW note, check if after the withdraw the buffer amount isn't violated
        _validateBufferAmount(_tokenOut);
        // USDW held in this contract (the vault) is burned  
        IUSDW(usdw_).burn(address(this), usdwAmount_);
        // the _transferIn call increased the value of tokenBalances[usdw]
        // usually decreases in token balances are synced by calling _transferOut
        // however, for usdw, the tokens are burnt, so _updateTokenBalance should
        // be manually called to record the decrease in tokens
        _updateTokenBalance(usdw_);
        uint256 feeBasisPoints_ = vaultUtils.getSellUsdwFeeBasisPoints(_tokenOut, usdwAmount_);
        (uint256 amountOut_,) = _collectSwapFees(_tokenOut, redemptionAmount, feeBasisPoints_);
        _validate(amountOut_ > 0, 22);
        _transferOut(_tokenOut, amountOut_, _receiverTokenOut);
        emit SellUSDW(
            _receiverTokenOut, 
            _tokenOut, 
            usdwAmount_, 
            amountOut_, 
            feeBasisPoints_
        );
        return amountOut_;
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
        address _receiver) external override nonReentrant isGlobalPause returns (uint256 amountOutAfterFees_) {
        _validate(isSwapEnabled, 23);
        _validate(whitelistedTokens[_tokenIn], 24);
        _validate(whitelistedTokens[_tokenOut], 25);
        _validate(_tokenIn != _tokenOut, 26);
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
    ) external isGlobalPause nonReentrant {
        // todo: consider do we want to return anything? what if this tx fails? how do we ensure that we do not mess up the accounting?
        _isRebalancer();
        // add check if this doesn't do something we don't want (like withdraw a token that is already scarce in the vault?)
        uint256 priceIn_ = getMinPrice(_tokenToRebalanceWith);
        // adjust usdwAmounts by the same usdwAmount as debt is shifted between the assets
        uint256 usdwAmount_ = (_amountToRebalanceWith * priceIn_) / PRICE_PRECISION;
        usdwAmount_ = adjustForDecimals(usdwAmount_, _tokenToRebalanceWith, usdw);
        _decreaseUsdwAmount(_tokenToRebalanceWith, usdwAmount_);
        // TODO: be very certain that we do not need to decrease/increase USDW debt / count in this step!
        // decrease the pool amount, temporarily lowering the WLP value
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
    ) external nonReentrant isGlobalPause {
        _isRebalancer();
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
        _validate(_amountIn > 0, 27);
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
     * 
     * @dev wager fees accumulate in this contract and need to be periodically sweeped
     * @param _tokenEscrowIn the address of the token the wagerFee is charged over
     * @param _amountEscrow the amount of _token the wagerFee is charged over
     * @return amountEscrowLeft_ wager amount of the _token that is left after the fee is deducted
     * @return feeAmountCharged_ amount of fee charged, denominated in _token (not USD value)
     * note the wagerFee stays in the vault contract until it is farmed by  the FeeCollector
     */
    function _collectWagerFees(
        address _tokenEscrowIn, 
        uint256 _amountEscrow) private returns (uint256 amountEscrowLeft_, uint256 feeAmountCharged_) {
        uint256 wagerFee_ = wagerFee;
        amountEscrowLeft_ = (_amountEscrow * (BASIS_POINTS_DIVISOR - wagerFee_)) / BASIS_POINTS_DIVISOR;
        feeAmountCharged_ = _amountEscrow - amountEscrowLeft_;
        wagerFeeReserves[_tokenEscrowIn] += feeAmountCharged_;
        emit WagerFeesCollected(
            _tokenEscrowIn, 
            tokenToUsdMin(_tokenEscrowIn, feeAmountCharged_), 
            feeAmountCharged_
        );
        return (amountEscrowLeft_, feeAmountCharged_);
    }

    /**
     * @dev swap fees arge charged over/on the outgoing token
     * @param _tokenAddress the address of the token the fees are charged over
     * @param _amountOfToken the amount of the ingoing 
     * @param _feeBasisPoints amount of baiss points (scaled 1e4)
     * @return afterFeeAmount_ the amount of _tokenAddress that is left after fees are deducted
     * @return feeAmount_ the amount of _tokenAddress that 'stays behind' in the vailt
     */
    function _collectSwapFees(
        address _tokenAddress, 
        uint256 _amountOfToken, 
        uint256 _feeBasisPoints) private returns (uint256 afterFeeAmount_, uint256 feeAmount_) {
        afterFeeAmount_ = (_amountOfToken * (BASIS_POINTS_DIVISOR - _feeBasisPoints)) / BASIS_POINTS_DIVISOR;
        feeAmount_ = (_amountOfToken - afterFeeAmount_);
        feeReserves[_tokenAddress] += feeAmount_;
        emit CollectSwapFees(
            _tokenAddress, 
            tokenToUsdMin(_tokenAddress, feeAmount_), 
            feeAmount_
        );
        return (afterFeeAmount_, feeAmount_);
    }

   /**
     * @notice internal payout function -  transfer the token to the recipient
     * @param _addressTokenOut the address of the token that will be transferred to the player
     * @param _toPayOnNet amount of _addressTokenOut the WLP will transfer to the  
     * @param _recipient the address of the recipient of the token _recipient
     */
    function _payout(
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
        uint256 nextBalance_ = ERC20(_tokenIn).balanceOf(address(this));
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
        SafeTransferLib.safeTransfer(ERC20(_tokenOut), _receiver, _amountOut);
        // update the tokenBalance of the outgoing token
        tokenBalances[_tokenOut] = ERC20(_tokenOut).balanceOf(address(this));
    }

    function _updateTokenBalance(address _tokenToUpdate) private {
        tokenBalances[_tokenToUpdate] = ERC20(_tokenToUpdate).balanceOf(address(this));
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
            poolAmounts[_tokenIn] <= ERC20(_tokenIn).balanceOf(address(this)),
            49
        );
        emit IncreasePoolAmount(_tokenIn, _amountToIncrease);
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
        emit DecreasePoolAmount(_tokenOut, _amountToDecrease);
    }

    function _validateBufferAmount(address _token) private view {
        // require(
        //     poolAmounts[_token] > bufferAmounts[_token],
        //     "Vault: Buffer limit exceeded"
        // );
        if (poolAmounts[_token] < bufferAmounts[_token]) {
            revert TokenBufferViolation(_token);
        }
    }

    /**
     * @notice returns the amount of fee basis points for a swap
     * @param _tokenInAddress the address of the token going in (being sold)
     * @param _tokenOutAddress the amount of the token going out (being bought)
     * @param _amountIn amount of _tokenInAddress (where the fee will be charged over)
     * @return feeBasisPoint_ the amount of fees in basis points
     * @dev all the fees are in basis points, scaled 1e4, so 100% = 1000
     */
    function _getFeeBasisPoints(
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _amountIn
    ) internal view returns (uint256 feeBasisPoint_) {
        if (_tokenInAddress == _tokenOutAddress) return 0;
        uint256 priceIn_ = getMinPrice(_tokenInAddress);
        uint256 usdwAmount_ = (_amountIn * priceIn_) / PRICE_PRECISION;
        usdwAmount_ = adjustForDecimals(usdwAmount_, _tokenInAddress, usdw);
        feeBasisPoint_ = vaultUtils.getSwapFeeBasisPoints(_tokenInAddress, _tokenOutAddress, usdwAmount_); 
    }

    function _isRebalancer() internal view {
        require(
            rebalancer[_msgSender()],
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
            _validate(usdwAmounts[_token] <= maxUsdwAmount_, 51);
        }
        emit IncreaseUsdwAmount(_token, _amountToIncrease);
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
            emit DecreaseUsdwAmount(_token, value_);
            return;
        }
        usdwAmounts[_token] = (value_ - _amountToDecrease);
        emit DecreaseUsdwAmount(_token, _amountToDecrease);
    }

    /**
     * @notice internal require that checks if the caller is a manager
     */
    function _validateManager() private view {
        if (inManagerMode) {
            _validate(isManager[_msgSender()], 54);
        }
    }

    /**
     * @notice internal require checker to emit certain error messages 
     * @dev using internal function as to reduce contract size
     */
    function _validate(bool _condition, uint256 _errorCode) private view {
        require(_condition, errors[_errorCode]);
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
        priceUpperBound_ = IVaultPriceFeedGMX(priceFeed).getPrice(
            _token, 
            true, /** max or minimise price */
            false, /** previously includeAmmPrice */
            false /** previously useSwapPricing */
        );
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
        priceLowerBound_ = IVaultPriceFeedGMX(priceFeed).getPrice(
            _token, 
            false,  /** max or minimise price */
            false, /** previously includeAmmPrice */
            false /** previously useSwapPricing */
        );
        _revertIfZero(priceLowerBound_);
    }

    function _revertIfZero(uint256 _value) internal pure {
        if(_value == 0) {
            revert PriceZero();
        }
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

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    /**
     * @notice returns the fee(in basis points) that needs to be paid for a certain transaction(swapping)
     * @param _token the address of the token
     * @param _usdwDelta the value in usdw of the tokenIn (price * amoutIn)
     * @param _feeBasisPoints uint of vaults swap (or stable) fee basis points
     * @param _taxBasisPoints uint of amount of tax basis points
     * @param _increment if the _token is entering the pool (true for tokenIn, false for tokenOut)
     */
    function getFeeBasisPoints(
        address _token, 
        uint256 _usdwDelta, 
        uint256 _feeBasisPoints, 
        uint256 _taxBasisPoints, 
        bool _increment) public override view returns (uint256 basisPoints_) {
        basisPoints_ = vaultUtils.getFeeBasisPoints(
            _token, 
            _usdwDelta, 
            _feeBasisPoints, 
            _taxBasisPoints, 
            _increment
        );
    }

    /*==================== View functions Winr/JB *====================*/
    
    /**
     * @notice returns the usd value of all the assets in the wlp combined (only the realized ones)
     * @dev take note that usd value is scaled 1e30 not 1e18
     */
    function getReserve() external override view returns(uint256 totalReserveValue_) {
        totalReserveValue_ = IWLPManager(managerAddress).getAum(false);
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
        wlpValue_ = IWLPManager(managerAddress).getPriceWlp(false);
    }

    /**
     *
     * @notice returns the amount of tokenOut you receive if you sell tokenIn 
     * @dev NOTE this doesn't account for swap fees you will pay if you conduct this swap!!!
     * @param _tokenInAddress address of the token you are selling
     * @param _tokenOutAddress address of the token that is being bought
     * @param _amountIn amount of tokenIn that is being sold (or queried to be sold)
     * @return amountOut_ amount of tokenOut that the swap will yield (NOT ACCOUNTING FOR SWAP FEES)
     */
    function _amountOfTokenForToken(
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _amountIn
    ) internal view returns(uint256 amountOut_) {
        uint256 priceIn_ = getMinPrice(_tokenInAddress);
        uint256 priceOut_ = getMaxPrice(_tokenOutAddress);
        amountOut_ = (_amountIn * priceIn_) / priceOut_;
        amountOut_ = adjustForDecimals(
            amountOut_, 
            _tokenInAddress, 
            _tokenOutAddress
        );
        return amountOut_;
    }

    /**
     * @notice returns how much USDW debt a certain token should have (not denominated in the token, but in USDW)
     * @dev this function is used to determine if a certain asset is scarce in the pool, or abundant
     * @param _token address of the token
     */
    function getTargetUsdwAmount(address _token) public override view returns (uint256 usdwAmount_) {
        uint256 supply_ = ERC20(usdw).totalSupply();
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
     * @param _amount amount to migrate
     * @param _upgrade bool singalling if the balances need to be updated
     * note todo probably we should check more stuff here! like if it is paused and all that!
     */
    function upgradeVault(
        address _newVault, 
        address _token, 
        uint256 _amount,
        bool _upgrade) external onlyTimelockGovernance {
        SafeTransferLib.safeTransfer(ERC20(_token), _newVault, _amount);
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
     * @dev due to the imporance of the priceFeed, this function is protected by the timelocked modifier
     * @param _priceFeed address of the price feed
     */
    function setPriceFeed(address _priceFeed) external override onlyTimelockGovernance {
        priceFeed = _priceFeed;
    }

    /**
     * @dev due to the right the rebalancer has, this function is protected by the timelocked modifier
     * @param _rebalancerAddress address of a contract allowed to rebalance
     * @param _setting if the rebalancerAddress needs to be added(true) or removed(false)
     */
    function setRebalancer(
        address _rebalancerAddress,
        bool _setting
    ) external onlyTimelockGovernance {
        rebalancer[_rebalancerAddress] = _setting;
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
        bool _hasDynamicFees
    ) external override onlyGovernance {
        _validate(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, 3);
        _validate(_stableTaxBasisPoints <= MAX_FEE_BASIS_POINTS, 4);
        _validate(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 5);
        _validate(_swapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 6);
        _validate(_stableSwapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 7);
        taxBasisPoints = _taxBasisPoints;
        stableTaxBasisPoints = _stableTaxBasisPoints;
        mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
        swapFeeBasisPoints = _swapFeeBasisPoints;
        stableSwapFeeBasisPoints = _stableSwapFeeBasisPoints;
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
            whitelistedTokenCount += 1;
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
        // require(
        //     getMaxPrice(_token) != 0,
        //     "Vault: Oracle error"
        // );
    }

    /**
     * @notice function that deletes the configuration of a certain token
     * @param _token address of the token 
     */
    function clearTokenConfig(address _token) external onlyGovernance {
        _validate(whitelistedTokens[_token], 13);
        totalTokenWeights -= tokenWeights[_token];
        delete whitelistedTokens[_token];
        delete tokenDecimals[_token];
        delete tokenWeights[_token];
        delete maxUsdwAmounts[_token];
        delete stableTokens[_token];
        whitelistedTokenCount -= 1;
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

    function setVaultUtils(IVaultUtils _vaultUtils) external override onlyGovernance {
        vaultUtils = _vaultUtils;
    }

    /**
     * @notice configuration function to set a new error controller function
     * @param _errorController address of the new error controller
     */
    function setErrorController(address _errorController) external onlyGovernance {
        errorController = _errorController;
    }

    /**
     * @notice configuration function that can change/add a config function
     * @param _errorCode uint pointing to a certain error code
     * @param _error string of new error code
     */
    function setError(uint256 _errorCode, string calldata _error) external override {
        require(_msgSender() == errorController, "Vault: invalid errorController");
        errors[_errorCode] = _error;
    }

    /*==================== Configuration functions Economic (onlyGovernance) *====================*/

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
    function setWagerFee(uint256 _wagerFee) external override onlyGovernance {
        require(
            _wagerFee <= MAX_WAGER_FEE,
            "Vault: Wagerfee exceed maximum"
        );
        wagerFee = _wagerFee;
    }

    /**
     * @notice enanables managed mode - when enabled only addresses configured as mananager can mint usdw (so wlpManager for example)
     */
    function setInManagerMode(bool _inManagerMode) external override onlyGovernance {
        inManagerMode = _inManagerMode;
    }

    /*==================== Configuration functions Accounting / Corrections (onlyGovernance) *====================*/

    /**
     * @notice configuration function that can add/remove contracts/addressees that are allowed to mint/redeem USDW
     * @dev take note that the WLPManager mints the WLP, the vault mints USDW
     * @param _manager address of the manager to add/remove
     * @param _isManager bool that determines if a manager is added or removed
     */
    function setManager(address _manager, bool _isManager) external override onlyGovernance {
        isManager[_manager] = _isManager;
        managerAddress = _manager;
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
    /*==================================================== EVENTS GMX ===========================================================*/
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
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseUsdwAmount(address token, uint256 amount);
    event DecreaseUsdwAmount(address token, uint256 amount);

    /*================================================== Operational Functions GMX =================================================*/
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;
    function router() external view returns (address);
    function usdw() external view returns (address);
    function whitelistedTokenCount() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdwAmount(address _token) external view returns (uint256);
    function inManagerMode() external view returns (bool);
    function isManager(address _account) external view returns (bool);
    function tokenBalances(address _token) external view returns (uint256);
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setUsdwAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        bool _hasDynamicFees
    ) external;
    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _maxUsdwAmount,
        bool _isStable
    ) external;
    function setPriceFeed(address _priceFeed) external;
    function withdrawSwapFees(address _token) external returns (uint256);
    function directPoolDeposit(address _token) external;
    function deposit(address _tokenIn, address _receiver) external returns (uint256);
    function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function tokenToUsdMin(address _tokenToPrice, uint256 _tokenAmount) external view returns (uint256);
    function priceFeed() external view returns (address);
    function getFeeBasisPoints(
        address _token, 
        uint256 _usdwDelta, 
        uint256 _feeBasisPoints, 
        uint256 _taxBasisPoints, 
        bool _increment
    ) external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function usdwAmounts(address _token) external view returns (uint256);
    function maxUsdwAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    /*==================== Events WINR  *====================*/

    event PlayerPayout(
        address recipient,
        uint256 amountPayoutTotal
    );

    event WagerFeesCollected(
        address tokenAddress,
        uint256 usdValueFee,
        uint256 feeInTokenCharged
    );

    event PayinWLP(
        address tokenInAddress,
        uint256 amountPayin,
        uint256 usdValueProfit
    );

    event RebalancingWithdraw(
        address tokenWithdrawn,
        uint256 amountWithdrawn
    );

    event RebalancingDeposit(
        address tokenDeposit,
        uint256 amountDeposit
    );

    /*==================== Operational Functions WINR *====================*/
    function setVaultManagerAddress(address _vaultManagerAddress) external;
    function vaultManagerAddress() external view returns (address);
    function wagerFee() external view returns (uint256);
    function setWagerFee(uint256 _wagerFee) external;
    function wagerFeeReserves(address _token) external view returns(uint256);
    function withdrawWagerFees(address _token) external returns (uint256);
    function setFeeLessForPayout(bool _setting) external;
    function getReserve() external view returns (uint256);
    function getDollarValue(address _token) external view returns (uint256);
    function getWlpValue() external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns(uint256);
    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) external view returns(uint256);

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

    /*==================== Events WINR  *====================*/

    event DeadmanSwitchFlipped();
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

    // function getPrice(bool _maximise) external view returns(uint256);

    function getPriceWlp(bool _maximise) external view returns(uint256);

    function getPriceWLPInUsdw(bool _maximise) external view returns(uint256);

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

    event HandlerSet(
        address handlerAddress,
        bool isSet
    );


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultPriceFeedGMX {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
    function getAmmPrice(address _token) external view returns (uint256);
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
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

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}