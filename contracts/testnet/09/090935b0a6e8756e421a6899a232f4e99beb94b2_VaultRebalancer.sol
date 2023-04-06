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

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AccessControlBase.sol";

// WINR Protocol Interfaces
import "../interfaces/core/IVault.sol";
import "../interfaces/core/IRouter.sol";
import "../interfaces/core/IReader.sol";
import "../interfaces/core/IVaultRebalancer.sol";

// GMX Protocol Interfaces
import "../interfaces/gmx/IVaultGMX.sol";
import "../interfaces/gmx/IRouterGMX.sol";
import "../interfaces/core/IWLPManager.sol";

/**
 * @title VaultRebalancer.
 * @author balingghost
 */
contract VaultRebalancer is IVaultRebalancer, AccessControlBase, ReentrancyGuard {

    /*==================== Constants *====================*/
    uint8 private constant USDW_DECIMALS = 18;
    uint32 private constant BASIS_POINTS_DIVISOR = 1e4;
    uint128 public constant MINIMUM_EXCESS = 100 * 1e18;

    /*==================== State Variabes *====================*/
    address public gmxVault;
    IVault public vault;
    address public winrRouter;
    address public gmxRouter;
    address public readerAddress;
    uint256 public gmxSwapSlippageMax;

    error BorrowIsZero();

    constructor(
        address _vaultRegistry,
        address _timelock
    ) AccessControlBase(_vaultRegistry, _timelock){
        gmxSwapSlippageMax = 500;
    }

    /*==================== Configuration functions*====================*/

    function configureContract(
        address _gmxVault,
        address _winrVault,
        address _gmxRouter,
        address _winrRouter,
        address _reader
    ) external onlyGovernance {
        _checkIfZero(_gmxVault);
        _checkIfZero(_winrVault);
        _checkIfZero(_gmxRouter);
        _checkIfZero(_winrRouter);
        _checkIfZero(_reader);
        gmxVault = _gmxVault;
        vault = IVault(_winrVault);
        winrRouter = _winrRouter;
        gmxRouter = _gmxRouter;
        readerAddress = _reader;
    }

    /*==================== Operational functions WINR/JB *====================*/

    /**
     * @param _rebalanceTokenTarget address of the token to replenish (should be scarce in the vault)
     * @param _rebalanceTokenToUse address of the token to sell (of the vault)
     * @param _usdwValueToReplenish usdw(1e18) denominated value of _rebalanceTokenToUse that will be withdrawn and consequently swapped
     * @param _maxSplippageBasisPoint max basis point slippage tolerated 
     * @return amountAfterFees_ the amiunt of _rebalanceTokenTarget that the 
     * @dev the caller should select a 'in abundance' asset for _rebalanceTokenToUse 
     */
    function rebalanceVaultByUsdw(
        address _rebalanceTokenTarget,
        address _rebalanceTokenToUse,
        uint256 _usdwValueToReplenish,
        uint256 _maxSplippageBasisPoint
    ) public onlyManager nonReentrant returns(uint256 amountAfterFees_) {
        // todo add description
        uint256 _units = ((_usdwValueToReplenish * 1e30) / vault.getMinPrice(_rebalanceTokenToUse)); 
        // calculate how much of _rebalanceTokenToUse this contract will withdraw
        uint256 _amountToBorrow = adjustForDecimals(_units, vault.usdw(), _rebalanceTokenToUse);
        // if the _amountToBorrow rounds to 0,  we revert because it is impossible to withdraw nothing 
        if  (_amountToBorrow == 0) {
            revert BorrowIsZero();
        }
        // pull/borrow the _rebalanceTokenToUse from the vault
        vault.rebalanceWithdraw(
            _rebalanceTokenToUse,
            _amountToBorrow
        );

        // the vaults tokens now sit in this contract

        // approve the gmx router to swap the tokens
        SafeERC20.safeApprove(
            IERC20(_rebalanceTokenToUse), 
            address(gmxRouter), 
            _amountToBorrow
        );

        (uint256 outMax_,) = IReader(readerAddress).getAmountOut(
            vault,
            _rebalanceTokenToUse,
            _rebalanceTokenTarget,
            _amountToBorrow
        );

        uint256 minOut_ = (outMax_ * (BASIS_POINTS_DIVISOR - gmxSwapSlippageMax)) / BASIS_POINTS_DIVISOR;

        address[] memory path_ = new address[](2); 
        path_[0] = _rebalanceTokenToUse;
        path_[1] = _rebalanceTokenTarget;

        uint256 balBefore_ = IERC20(_rebalanceTokenTarget).balanceOf(address(this));
        
        IRouterGMX(gmxRouter).swap(
            path_,
            _amountToBorrow,
            minOut_,
            address(this)
        );

        uint256 balAfter_ = IERC20(_rebalanceTokenTarget).balanceOf(address(this));
        amountAfterFees_ = balAfter_ - balBefore_;
        require(
            amountAfterFees_ != 0,
            "VaultRebalancer: Swap failed"
        );

        // transfer the amountAfterFees_ to the winrVault
        SafeERC20.safeTransfer(
            IERC20(_rebalanceTokenTarget), 
            address(vault), 
            amountAfterFees_
        );

        // register the rebalancing with the winrVaults accounting
        vault.rebalanceDeposit(
            _rebalanceTokenTarget,
            amountAfterFees_
        );

        // the rebalancing is now complete 
        emit RebalancingComplete();
        return (amountAfterFees_);
    }

    /**
     * @notice rebalancing function that swaps a certain USD amount of a abundant asset, for a scarce asset
     * @dev can only be called by the manager role. be aware, this will reduce the WLP value since fees are paid to GMXs vault!!
     * @param _rebalanceTokenTarget address of the token to replenish (should be scarce in the vault)
     * @param _rebalanceTokenToUse address of the token to sell (of the vault)
     * @param _usdValueToReplenish usd(1e30) denominated value of _rebalanceTokenToUse that will be withdrawn and consequently swapped
     * @param _maxSplippageBasisPoint max basis point slippage tolerated 
     */
    function rebalanceVaultByUsdSimple(
        address _rebalanceTokenTarget,
        address _rebalanceTokenToUse,
        uint256 _usdValueToReplenish,
        uint256 _maxSplippageBasisPoint
    ) public onlyManager nonReentrant returns(uint256 amountAfterFees_) {
        // calculate how much of _rebalanceTokenToUse this contract will withdraw
        uint256 _amountToBorrow = vault.usdToTokenMax(_rebalanceTokenToUse, _usdValueToReplenish);
        // if the _amountToBorrow rounds to 0,  we revert because it is impossible to withdraw nothing 
        if  (_amountToBorrow == 0) {
            revert BorrowIsZero();
        }
        // pull/borrow the _rebalanceTokenToUse from the vault
        vault.rebalanceWithdraw(
            _rebalanceTokenToUse,
            _amountToBorrow
        );

        // the borrowered _rebalanceTokenToUse tokens (_amountToBorrow) now sit in this contract
        // the vaults tokens now sit in this contract

        // approve the gmx router to swap the tokens
        SafeERC20.safeApprove(
            IERC20(_rebalanceTokenToUse), 
            address(gmxRouter), 
            _amountToBorrow
        );

        (uint256 outMax_,) = IReader(readerAddress).getAmountOut(
            vault,
            _rebalanceTokenToUse,
            _rebalanceTokenTarget,
            _amountToBorrow
        );

        uint256 minOut_ = (outMax_ * (BASIS_POINTS_DIVISOR - gmxSwapSlippageMax)) / BASIS_POINTS_DIVISOR;

        address[] memory path_ = new address[](2); 
        path_[0] = _rebalanceTokenToUse;
        path_[1] = _rebalanceTokenTarget;

        uint256 balBefore_ = IERC20(_rebalanceTokenTarget).balanceOf(address(this));
        
        IRouterGMX(gmxRouter).swap(
            path_,
            _amountToBorrow,
            minOut_,
            address(this)
        );

        uint256 balAfter_ = IERC20(_rebalanceTokenTarget).balanceOf(address(this));
        amountAfterFees_ = balAfter_ - balBefore_;
        require(
            amountAfterFees_ != 0,
            "VaultRebalancer: Swap failed"
        );

        /**
         * At this stage the rebalancer has swapped the 'scarce' assset with the GMX vault for a less scarce asset. The swapped asset now sits in this contract. We will now transfer the swapped asset to the vault.
         */
        // transfer the amountAfterFees_ to the winrVault 
        SafeERC20.safeTransfer(
            IERC20(_rebalanceTokenTarget), 
            address(vault), 
            amountAfterFees_
        );
        // call the vault as to register the 
        vault.rebalanceDeposit(
            _rebalanceTokenTarget,
            amountAfterFees_
        );
        // the rebalancing is now complete , todo emit proper event
        emit RebalancingComplete();
        return amountAfterFees_;
    }

    /**
     * @return xxx
     * @return xxx
     * @return xxx
     */
    function rebalanceSimple() external onlyManager returns(uint, address, address) {
        uint256 length_ = vault.allWhitelistedTokensLength();
        address tokenExcessHighest_;
        uint highestExcess_;
        address tokenDeficit_;
        uint highestDeficit_;
        uint balancedCount_;
        for (uint256 i = 0; i < length_; i++) {
            address token_ = vault.allWhitelistedTokens(i);
            bool isWhitelisted_ = vault.whitelistedTokens(token_);
            if (!isWhitelisted_) {
                continue;
            }
            (uint excess_, uint extent_) = outputExcessOrDeficitTokensUint(token_);

            if(excess_ == 2) { // token is in excess
                if(extent_ >= highestExcess_) {
                    highestExcess_ = extent_;
                    tokenExcessHighest_ = token_;
                }
            } 
            else if (excess_ == 1) { // token is in deficit
                if(extent_ >= highestDeficit_) {
                    highestDeficit_ = extent_;
                    tokenDeficit_ = token_;
                }
            } 
            else { // token is balanced
                balancedCount_++;
            }
        }
        if(balancedCount_ == length_) {
            // the pool is perfectly balanced, do nothing
            return (0, address(0x0), address(0x0));
        }
        if((tokenExcessHighest_ == address(0x0)) || (highestExcess_ == 0)) {
            // there is no excess token to rebalance the pool with
            return (0, address(0x0), address(0x0));
        }
        if(tokenDeficit_ == address(0x0) || (highestDeficit_ == 0)) {
            // there is no excess token to rebalance the pool with
            return (0, address(0x0), address(0x0));
        }
        (uint amount_) = rebalanceVaultByUsdw(
            tokenDeficit_,
            tokenExcessHighest_,
            _returnRebalanceAmount(highestExcess_, highestDeficit_),
            3000
        );
        return (amount_, tokenDeficit_, tokenExcessHighest_);
    }

    /*==================== View Functions *====================*/

    function outputExcessOrDeficitUSDW(address _token) external view returns(
        Delta delta_, 
        uint256 extent_
        ) {
            uint256 currentAmount_ = vault.usdwAmounts(_token);
            uint256 targetAmount_ = vault.getTargetUsdwAmount(_token);
            if (currentAmount_ < targetAmount_) { 
                // deficit:  there is too little of the _token in the vault
                delta_ = Delta.DEFICIT;
                extent_ = targetAmount_ - currentAmount_;
            } else if (currentAmount_ > targetAmount_) {
                // excess:  there is too much of the _token in the vault
                delta_ = Delta.EXCESS;
                extent_ = currentAmount_ - targetAmount_;
            } else {
                // even: there is just as much of the token in the vault as there should be
                delta_ = Delta.EVEN;
                extent_ = 0;
            }
            return(delta_, extent_);
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
        address usdw_ = vault.usdw();
        uint256 decimalsDiv_ = _tokenDiv == usdw_ ? USDW_DECIMALS : vault.tokenDecimals(_tokenDiv);
        uint256 decimalsMul_ = _tokenMul == usdw_ ? USDW_DECIMALS : vault.tokenDecimals(_tokenMul);
        scaledAmount_ = (_amount * (10 ** decimalsMul_)) / (10 ** decimalsDiv_);
    }

    /**
     * @param _token xxx
     * @return delta_ xxx
     * @return extent_ xxx
     */
    function outputExcessOrDeficitTokens(address _token) external view returns(Delta delta_, uint256 extent_) {
        uint256 currentAmount_ = vault.usdwAmounts(_token);
        uint256 targetAmount_ = vault.getTargetUsdwAmount(_token);
        uint256 price_ = vault.getMinPrice(_token);
        if (currentAmount_ < targetAmount_) { 
            // deficit:  there is too little of the _token in the vault
            delta_ = Delta.DEFICIT;
            extent_ = ((targetAmount_ - currentAmount_) * 1e30) / price_;
        } else if (currentAmount_ > targetAmount_) {
            // excess:  there is too much of the _token in the vault
            delta_ = Delta.EXCESS;
            extent_ = ((currentAmount_ - targetAmount_) * 1e30) / price_;
        } else {
            // even: there is just as much of the token in the vault as there should be
            delta_ = Delta.EVEN;
            extent_ = 0;
        }
        return(delta_, extent_);
    }

    /**
     * @param _token xxx
     * @return excess_ xxx
     * @return extent_ xxx
     */
    function outputExcessOrDeficitTokensUint(address _token) public view returns(uint excess_, uint256 extent_) {
        uint256 currentAmount_ = vault.usdwAmounts(_token);
        uint256 targetAmount_ = vault.getTargetUsdwAmount(_token);
        if (currentAmount_ < targetAmount_) { 
            // deficit:  there is too little of the _token in the vault
            excess_ = 1;
            extent_ = (targetAmount_ - currentAmount_);
        } else if (currentAmount_ > (targetAmount_ + MINIMUM_EXCESS)) {
            // excess:  there is too much of the _token in the vault
            excess_ = 2;
            extent_ = (currentAmount_ - targetAmount_);
        } else {
            // even: there is just as much of the token in the vault as there should be
            excess_ = 0;
            extent_ = 0;
        }
        return(excess_, extent_);
    }

    /*==================== Internal functions WINR/JB *====================*/

    function _checkIfZero(address _configuredAddress) internal pure {
        require(
            _configuredAddress != address(0x0),
            "VaultRebalancer: address zero"
        );
    }

    function _returnRebalanceAmount(
        uint256 _excessAmount,
        uint256 _deficitAmount
    ) internal pure returns(uint256 usdAmount_) {
        usdAmount_ = (_excessAmount >= _deficitAmount) ? _deficitAmount : _excessAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVault.sol";
import "../gmx/IVaultPriceFeedGMX.sol";

interface IReader {
    function getFees(address _vault, address[] memory _tokens) external view returns (uint256[] memory);
    function getWagerFees(address _vault, address[] memory _tokens) external view returns (uint256[] memory);
   function getSwapFeeBasisPoints(
        IVault _vault, 
        address _tokenIn, 
        address _tokenOut, 
        uint256 _amountIn) external view returns (uint256, uint256, uint256);
    function getAmountOut(
        IVault _vault, 
        address _tokenIn, 
        address _tokenOut, 
        uint256 _amountIn) external view returns (uint256, uint256);
    function getMaxAmountIn(
        IVault _vault,
        address _tokenIn, 
        address _tokenOut) external view returns (uint256);
    function getPrices(
        IVaultPriceFeedGMX _priceFeed, 
        address[] memory _tokens) external view returns (uint256[] memory);
    function getVaultTokenInfo(
        address _vault, 
        address _weth, 
        uint256 _usdwAmount, 
        address[] memory _tokens) external view returns (uint256[] memory);    
    function getFullVaultTokenInfo(
        address _vault, 
        address _weth, 
        uint256 _usdwAmount, 
        address[] memory _tokens) external view returns (uint256[] memory);
    function getFeesForGameSetupFeesUSD(
        address _tokenWager,
        address _tokenWinnings,
        uint256 _amountWager
    ) external view returns(
        uint256 wagerFeeUsd_,
        uint256 swapFeeUsd_,
        uint256 swapFeeBp_
    );
    function getNetWinningsAmount(
        address _tokenWager,
        address _tokenWinnings,
        uint256 _amountWager,
        uint256 _multiple
    ) external view returns(
        uint256 amountWon_,
        uint256 wagerFeeToken_,
        uint256 swapFeeToken_
    );
    function getSwapFeePercentageMatrix(
        uint256 _usdValueOfSwapAsset
    ) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IRouter {

    /*==================== Public Functions *====================*/
    
    function addPlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    /*==================== Events WINR  *====================*/

    event Swap(
        address account, 
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn, 
        uint256 amountOut
    );
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

interface IVaultRebalancer {

    /*==================== Events WINR  *====================*/
    enum Delta {
        EVEN,
        DEFICIT,
        EXCESS
    }

    /*================================================== Operational Functions GMX =================================================*/
    function rebalanceVaultByUsdSimple(
        address _rebalanceTokenTarget,
        address _rebalanceTokenToUse,
        uint256 _usdValueToReplenish,
        uint256 _maxSplippageBasisPoint
    ) external returns(uint256);

    function outputExcessOrDeficitUSDW(address _token) external view returns(Delta delta_, uint256 extent_);
    function outputExcessOrDeficitTokens(address _token) external view returns(Delta delta_, uint256 extent_);

    /*==================== Events WINR  *====================*/

    event RebalancingComplete();
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IRouterGMX {
    function addPlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtilsGMX.sol";

interface IVaultGMX {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtilsGMX _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function usdw() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdwAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setUsdwAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdwAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDW(address _token, address _receiver) external returns (uint256);
    function sellUSDW(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdwDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function swapFeeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdwAmounts(address _token) external view returns (uint256);
    function maxUsdwAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
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

    // added by WINR

    function getPriceV1(address _token, bool _maximise, bool _includeAmmPrice) external view returns (uint256);
    function getPriceV2(address _token, bool _maximise, bool _includeAmmPrice) external view returns (uint256);
     function getAmmPriceV2(address _token, bool _maximise, uint256 _primaryPrice) external view returns (uint256);
     function getSecondaryPrice(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);
     function getPairPrice(address _pair, bool _divByReserve0) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtilsGMX {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSellUsdwFeeBasisPoints(address _token, uint256 _usdwAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdwAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdwDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
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