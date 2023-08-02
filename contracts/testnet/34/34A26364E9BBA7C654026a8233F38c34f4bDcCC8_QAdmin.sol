//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./interfaces/IQollateralManager.sol";
import "./interfaces/IFeeEmissionsQontroller.sol";
import "./interfaces/ILiquidityEmissionsQontroller.sol";
import "./interfaces/IStakingEmissionsQontroller.sol";
import "./interfaces/ITradingEmissionsQontroller.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IQAdmin.sol";
import "./interfaces/IQodaLens.sol";
import "./interfaces/IVeQoda.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/QTypes.sol";

contract QAdmin is Initializable, AccessControlEnumerableUpgradeable, IQAdmin {
  
  /// @notice Identifier of the admin role
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @notice Identifier of the market role
  bytes32 public constant MARKET_ROLE = keccak256("MARKET");

  /// @notice Identifier of the role who allows accounts to mint tokens in QodaERC20
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");

  /// @notice Identifier of the veToken role to do stake / unstake in StakingEmissionsQontroller
  bytes32 public constant VETOKEN_ROLE = keccak256("VETOKEN");
  
  /// @notice Reserve storage gap so introduction of new parent class later on can be done via upgrade
  uint256[50] __gap;

  /// @notice Contract for managing user collateral
  IQollateralManager private _qollateralManager;  

  /// @notice Contract for staking rewards
  IStakingEmissionsQontroller private _stakingEmissionsQontroller;

  /// @notice Contract for trading volume rewards
  ITradingEmissionsQontroller private _tradingEmissionsQontroller;

  /// @notice Contract for handling protocol fee charging and emission
  IFeeEmissionsQontroller private _feeEmissionsQontroller;

  /// @notice Contract for veQoda Token
  IVeQoda private _veQoda;

  /// @notice Iterable list of all `Asset` addresses
  address[] private _allAssets;
  
  /// @notice Default value for `minCollateralRatio` if it is not defined in `_creditFacilityMap` for given address
  /// Scaled by 1e8
  uint private _minCollateralRatio;

  /// @notice Default value for `initCollateralRatio` if it is not defined in `_creditFacilityMap` for given address
  /// Scaled by 1e8
  uint private _initCollateralRatio;

  /// @notice The percent, ranging from 0% to 100%, of a liquidatable account's
  /// borrow that can be repaid in a single liquidate transaction.
  /// Scaled by 1e8
  uint private _closeFactor;

  /// @notice Grace period (in seconds) after maturity before liquidators are allowed to
  /// liquidate underwater accounts.
  uint private _repaymentGracePeriod;
  
  /// @notice Grace period (in seconds) after maturity before lenders are allowed to
  /// redeem their qTokens for underlying tokens
  uint private _maturityGracePeriod;
  
  /// @notice Additional collateral given to liquidator as incentive to liquidate
  /// underwater accounts. For example, if liquidation incentive is 1.1, liquidator
  /// receives extra 10% of borrowers' collateral
  /// Scaled by 1e8
  uint private _liquidationIncentive;
  
  /// @notice threshold in USD where protocol fee from each market will be transferred into `FeeEmissionsQontroller`
  /// once this amount is reached, scaled by 1e18
  uint private _thresholdUSD;

  /// @notice Mapping for the annualized fee for loans in basis points for each `FixedRateMarket`.
  /// The fee is charged to both the lender and the borrower on any given deal. The fee rate will
  /// need to be scaled for loans that mature outside of 1 year.
  /// Scaled by 1e4
  mapping(IFixedRateMarket => uint) private _protocolFee;

  /// @notice All enabled `Asset`s
  /// tokenAddress => Asset
  mapping(IERC20 => QTypes.Asset) private _assets;

  /// @notice Get the `FixedRateMarket` contract address for any given
  /// token and maturity time
  /// tokenAddress => maturity => fixedRateMarketAddress
  mapping(IERC20 => mapping(uint => address)) private _fixedRateMarkets;

  /// @notice Mapping for the MToken market corresponding to any underlying ERC20
  /// tokenAddress => mTokenAddress
  mapping(IERC20 => address) private _underlyingToMToken;
  
  /// @notice Mapping to determine whether a `FixedRateMarket` address
  /// is enabled or not
  /// fixedRateMarketAddress => bool
  mapping(address => bool) private _enabledMarkets;

  /// @notice Mapping to determine the minimum quote size for any `FixedRateMarket`
  /// in PV terms, denominated in local currency
  /// fixedRateMarketAddress => minQuoteSize
  mapping(address => uint) private _minQuoteSize;
  
  /// @notice Mapping to determine collateral ratio and credit limit of each address
  /// userAddress => creditInfo
  mapping(address => QTypes.CreditFacility) private _creditFacilityMap;
  
  /// @notice Contract for QodaLens
  IQodaLens private _qodaLens;
  
  /// @notice Contract for WETH
  IWETH private _weth;
  
  /// @notice Boolean to indicate if all markets are paused
  bool private _marketsPaused;
  
  /// @notice Mapping to indicate if specified contract address is paused
  mapping(address => bool) private _contractPausedMap;
  
  /// @notice Mapping to indicate if specified operation is paused
  mapping(uint => bool) private _operationPausedMap;
  
  /// @notice Contract for top-of-book quote rewards
  ILiquidityEmissionsQontroller private _liquidityEmissionsQontroller;

  /// @notice Constructor for upgradeable contracts
  function initialize(address admin) public initializer {

    // Initialize access control
    __AccessControlEnumerable_init();
    _setupRole(ADMIN_ROLE, admin);
    _setupRole(MARKET_ROLE, admin);
    _setupRole(MINTER_ROLE, admin);
    _setupRole(VETOKEN_ROLE, admin);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    _setRoleAdmin(MARKET_ROLE, ADMIN_ROLE);
    _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    _setRoleAdmin(VETOKEN_ROLE, ADMIN_ROLE);
    
    // Set initial values for parameters
    _minCollateralRatio = 1e8;
    _initCollateralRatio = 1.1e8;
    _closeFactor = 0.5e8;
    _repaymentGracePeriod = 14400;
    _maturityGracePeriod = 28800;
    _liquidationIncentive = 1.1e8;
  }

  modifier onlyAdmin() {
    if (!hasRole(ADMIN_ROLE, msg.sender)) {
      revert CustomErrors.QA_OnlyAdmin();
    }
    _;
  }

  modifier onlyMarket() {
    if (!hasRole(MARKET_ROLE, msg.sender)) {
      revert CustomErrors.QA_OnlyMarket();
    }
    _;
  }

  modifier onlyVeToken() {
    if (!hasRole(VETOKEN_ROLE, msg.sender)) {
      revert CustomErrors.QA_OnlyVeToken();
    }
    _;
  }

  /** ADMIN FUNCTIONS **/
  
  /// @notice Call upon initialization after deploying `QAdmin` contract
  /// @param wethAddress Address of `WETH` contract of the network 
  function _setWETH(address wethAddress) external onlyAdmin {
    if (address(_weth) == address(0)) {
      // Initialize the value
      _weth = IWETH(wethAddress);
      
      // Emit the event
      emit SetWETH(wethAddress);
    }
  }

  /// @notice Call upon initialization after deploying `QollateralManager` contract
  /// @param qollateralManagerAddress Address of `QollateralManager` deployment
  function _setQollateralManager(address qollateralManagerAddress) external onlyAdmin {
    
    // Initialize the value
    _qollateralManager = IQollateralManager(qollateralManagerAddress);

    // Emit the event
    emit SetQollateralManager(qollateralManagerAddress);
  }

  /// @notice Call upon initialization after deploying `StakingEmissionsQontroller` contract
  /// @param stakingEmissionsQontrollerAddress Address of `StakingEmissionsQontroller` deployment
  function _setStakingEmissionsQontroller(address stakingEmissionsQontrollerAddress) external onlyAdmin {

    // Initialize the value
    _stakingEmissionsQontroller = IStakingEmissionsQontroller(stakingEmissionsQontrollerAddress);

    // Emit the event
    emit SetStakingEmissionsQontroller(stakingEmissionsQontrollerAddress);
  }

  /// @notice Call upon initialization after deploying `TradingEmissionsQontroller` contract
  /// @param tradingEmissionsQontrollerAddress Address of `TradingEmissionsQontroller` deployment
  function _setTradingEmissionsQontroller(address tradingEmissionsQontrollerAddress) external onlyAdmin {
    
    // Initialize the value
    _tradingEmissionsQontroller = ITradingEmissionsQontroller(tradingEmissionsQontrollerAddress);

    // Emit the event
    emit SetTradingEmissionsQontroller(tradingEmissionsQontrollerAddress);
  }

  /// @notice Call upon initialization after deploying `FeeEmissionsQontroller` contract
  /// @param feeEmissionsQontrollerAddress Address of `FeeEmissionsQontroller` deployment
  function _setFeeEmissionsQontroller(address feeEmissionsQontrollerAddress) external onlyAdmin {
    // Initialize the value
    _feeEmissionsQontroller = IFeeEmissionsQontroller(feeEmissionsQontrollerAddress);

    // Emit the event
    emit SetFeeEmissionsQontroller(feeEmissionsQontrollerAddress);
  }
  
  /// @notice Call upon initialization after deploying `LiquidityEmissionsQontroller` contract
  /// @param liquidityEmissionsQontrollerAddress Address of `LiquidityEmissionsQontroller` deployment
  function _setLiquidityEmissionsQontroller(address liquidityEmissionsQontrollerAddress) external onlyAdmin {
    // Initialize the value
    _liquidityEmissionsQontroller = ILiquidityEmissionsQontroller(liquidityEmissionsQontrollerAddress);

    // Emit the event
    emit SetLiquidityEmissionsQontroller(liquidityEmissionsQontrollerAddress);
  }

  /// @notice Call upon initialization after deploying `veQoda` contract
  /// @param veQodaAddress Address of `veQoda` deployment
  function _setVeQoda(address veQodaAddress) external onlyAdmin {

    // Initialize the value
    _veQoda = IVeQoda(veQodaAddress);

    // Give `veQoda` the VETOKEN access control role
    _setupRole(VETOKEN_ROLE, veQodaAddress);

    // Emit the event
    emit SetVeQoda(veQodaAddress);
  }
  
  /// @notice Call upon initialization after deploying `QodaLens` contract
  /// @param qodaLensAddress Address of `QodaLens` deployment
  function _setQodaLens(address qodaLensAddress) external onlyAdmin {
    // Initialize the value
    _qodaLens = IQodaLens(qodaLensAddress);
    
    // Emit the event
    emit SetQodaLens(qodaLensAddress);
  }
  
  /// @notice Admin function for adding new Assets. An Asset must be added before it
  /// can be used as collateral or borrowed. Note: We can create functionality for
  /// allowing borrows of a token but not using it as collateral by setting
  /// `collateralFactor` to zero.
  /// @param tokenAddress ERC20 token corresponding to the Asset
  /// @param isYieldBearing True if token bears interest (eg aToken, cToken, mToken, etc)
  /// @param underlying Address of the underlying token
  /// @param oracleFeed_ Chainlink price feed address
  /// @param collateralFactor_ 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @param marketFactor_ 0.0 to 1.0 (scaled to 1e8) for premium on risky borrows
  function _addAsset(
                     address tokenAddress,
                     bool isYieldBearing,
                     address underlying,
                     address oracleFeed_,
                     uint collateralFactor_,
                     uint marketFactor_
                     ) external onlyAdmin {
    
    IERC20 token = IERC20(tokenAddress);  

    // Cannot add the same asset twice
    if (_assets[token].isEnabled) {
      revert CustomErrors.QA_AssetExist();
    }

    // `collateralFactor` must be between 0 and 1 (scaled to 1e8)
    if (collateralFactor_ > MAX_COLLATERAL_FACTOR()) {
      revert CustomErrors.QA_InvalidCollateralFactor();
    }

    // `marketFactor` must be between 0 and 1 (scaled to 1e8)
    if (marketFactor_ > MAX_MARKET_FACTOR()) {
      revert CustomErrors.QA_InvalidMarketFactor();
    }

    // Initialize the `Asset` with the given parameters, and no enabled
    // maturities to begin with
    uint[] memory maturities_;
    QTypes.Asset memory asset = QTypes.Asset(
                                             true,
                                             isYieldBearing,
                                             underlying,
                                             oracleFeed_,
                                             collateralFactor_,
                                             marketFactor_,
                                             maturities_
                                             );
    _assets[token] = asset;
    _allAssets.push(tokenAddress);
    
    // Add yield-bearing assets to the (underlying => MToken) mapping
    if(isYieldBearing) {
      _underlyingToMToken[IERC20(underlying)]= tokenAddress;
    }
    
    // Emit the event
    emit AddAsset(tokenAddress, isYieldBearing, oracleFeed_, collateralFactor_, marketFactor_);
  }
  
  /// @notice Admin function for removing an asset
  /// @param token ERC20 token corresponding to the Asset
  function _removeAsset(IERC20 token) external onlyAdmin {
    QTypes.Asset memory asset = _assets[token];
    
    // Cannot delete non-existent asset
    if (!asset.isEnabled) {
      revert CustomErrors.QA_AssetNotExist();
    }
    
    // Remove from mapping if it is yield-bearing asset
    if(asset.isYieldBearing){
      delete _underlyingToMToken[IERC20(asset.underlying)];
    }
    
    // Remove from all assets by swapping with last element and pop it out
    for(uint i = 0; i < _allAssets.length; i++) {
      if (_allAssets[i] == address(token)) {
        _allAssets[i] = _allAssets[_allAssets.length - 1];
        _allAssets.pop();
        break;
      }
    }
    
    // Remove token from asset
    delete _assets[token];
    
    // Emit the event
    emit RemoveAsset(address(token));
  }

  /// @notice Adds a new `FixedRateMarket` contract into the internal mapping of
  /// whitelisted market addresses
  /// @param marketAddress New `FixedRateMarket` contract address
  /// @param protocolFee_ Corresponding protocol fee in basis points
  /// @param minQuoteSize_ Size in PV terms, local currency
  function _addFixedRateMarket(
                               address marketAddress,
                               uint protocolFee_,
                               uint minQuoteSize_
                               ) external onlyAdmin {
    
    // Get the values from the corresponding `FixedRateMarket` contract
    IFixedRateMarket market = IFixedRateMarket(marketAddress);
    uint maturity = market.maturity();
    IERC20 token = market.underlyingToken();

    // Don't allow zero address
    if (address(token) == address(0)) {
      revert CustomErrors.QA_InvalidAddress();
    }

    // Only allow `Markets` where the corresponding `Asset` is enabled
    if (!_assets[token].isEnabled) {
      revert CustomErrors.QA_AssetNotSupported();
    }

    // Check that this market hasn't already been instantiated before
    if (_fixedRateMarkets[token][maturity] != address(0)) {
      revert CustomErrors.QA_MarketExist();
    }

    // Add the maturity as enabled to the corresponding Asset
    QTypes.Asset storage asset = _assets[token];
    asset.maturities.push(maturity);
    
    // Add newly-created `FixedRateMarket` to the lookup list
    _fixedRateMarkets[token][maturity] = marketAddress;

    // Enable newly-created `FixedRateMarket`
    _enabledMarkets[marketAddress] = true;

    // Give `FixedRateMarket` the MARKET access control role
    _setupRole(MARKET_ROLE, marketAddress);
    
    // Emit the event
    emit CreateFixedRateMarket(
                               marketAddress,
                               address(token),
                               maturity
                               );

    // Initialize the protocol fee for this `market`
    _setProtocolFee(marketAddress, protocolFee_);

    // Initialize the minimum `Quote` size for this `market`
    _setMinQuoteSize(marketAddress, minQuoteSize_);
  }
  
  function _removeFixedRateMarket(address marketAddress) external onlyAdmin {
    // Get the values from the corresponding `FixedRateMarket` contract
    IFixedRateMarket market = IFixedRateMarket(marketAddress);
    uint maturity = market.maturity();
    IERC20 token = market.underlyingToken();
    
    // Cannot delete non-existent market
    if (_fixedRateMarkets[token][maturity] == address(0)) {
      revert CustomErrors.QA_MarketNotExist();
    }

    // Remove from asset maturities by swapping with last element and pop it out
    QTypes.Asset storage asset = _assets[token];
    for(uint i = 0; i < asset.maturities.length; i++) {
      if (asset.maturities[i] == maturity) {
        asset.maturities[i] = asset.maturities[asset.maturities.length - 1];
        asset.maturities.pop();
        break;
      }
    }
    
    // Remove market from existing market list
    delete _fixedRateMarkets[token][maturity];
    
    // Emit the event
    emit RemoveFixedRateMarket(
                               marketAddress,
                               address(token),
                               maturity
                               );
  }
  
  /// @notice Update the `collateralFactor` for a given `Asset`
  /// @param token ERC20 token corresponding to the Asset
  /// @param collateralFactor_ 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setCollateralFactor(
                                IERC20 token,
                                uint collateralFactor_
                                ) external onlyAdmin {

    // Asset must already be enabled
    if (!_assets[token].isEnabled) {
      revert CustomErrors.QA_AssetNotEnabled();
    }

    // `collateralFactor` must be between 0 and 1 (scaled to 1e8)
    if (collateralFactor_ > MAX_COLLATERAL_FACTOR()) {
      revert CustomErrors.QA_InvalidCollateralFactor();
    }

    // Look up the corresponding asset
    QTypes.Asset storage asset = _assets[token];

    // Emit the event
    emit SetCollateralFactor(address(token), asset.collateralFactor, collateralFactor_);

    // Set `collateralFactor`
    asset.collateralFactor = collateralFactor_;
  }

  /// @notice Update the `marketFactor` for a given `Asset`
  /// @param token Address of the token corresponding to the Asset
  /// @param marketFactor_ 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setMarketFactor(
                            IERC20 token,
                            uint marketFactor_
                            ) external onlyAdmin {

    // Asset must already be enabled
    if (!_assets[token].isEnabled) {
      revert CustomErrors.QA_AssetNotEnabled();
    }

    // `marketFactor` must be between 0 and 1 (scaled to 1e8)
    if (marketFactor_ > MAX_MARKET_FACTOR()) {
      revert CustomErrors.QA_InvalidMarketFactor();
    }

    // Look up the corresponding asset
    QTypes.Asset storage asset = _assets[token];

    // Emit the event
    emit SetMarketFactor(address(token), asset.marketFactor, marketFactor_);
    
    // Set `marketFactor`
    asset.marketFactor = marketFactor_;
  }

  /// @notice Set the minimum quote size for a particular `FixedRateMarket`
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @param minQuoteSize_ Size in PV terms, local currency
  function _setMinQuoteSize(address marketAddress, uint minQuoteSize_) public onlyAdmin {
    IFixedRateMarket market = IFixedRateMarket(marketAddress);
    
    // `FixedRateMarket` must already exist
    if (_fixedRateMarkets[market.underlyingToken()][market.maturity()] == address(0)) {
      revert CustomErrors.QA_MarketNotExist();
    }

    // Emit the event
    emit SetMinQuoteSize(address(market), _minQuoteSize[marketAddress], minQuoteSize_);

    // Set `minQuoteSize`
    _minQuoteSize[marketAddress] = minQuoteSize_;
  }
  
  /// @notice Set the global minimum and initial collateral ratio
  /// @param minCollateralRatio_ New global minimum collateral ratio value
  /// @param initCollateralRatio_ New global initial collateral ratio value
  function _setCollateralRatio(uint minCollateralRatio_, uint initCollateralRatio_) external onlyAdmin {
    // `minCollateralRatio_` cannot be above `initCollateralRatio_`
    if (minCollateralRatio_ > initCollateralRatio_) {
      revert CustomErrors.QA_MinCollateralRatioNotGreaterThanInit();
    }

    // Emit the event
    emit SetCollateralRatio(_minCollateralRatio, _initCollateralRatio, minCollateralRatio_, initCollateralRatio_);
    
    // Set `_minCollateralRatio` to new value
    _minCollateralRatio = minCollateralRatio_;
    
    // Set `_initCollateralRatio` to new value
    _initCollateralRatio = initCollateralRatio_;
  }
  
  /// @notice Set credit facility for specified account
  /// @param account_ account for credit facility adjustment
  /// @param enabled_ If credit facility should be enabled 
  /// @param minCollateralRatio_ New minimum collateral ratio value
  /// @param initCollateralRatio_ New initial collateral ratio value
  /// @param creditLimit_ new credit limit in USD, scaled by 1e18
  function _setCreditFacility(address account_, bool enabled_, uint minCollateralRatio_, uint initCollateralRatio_, uint creditLimit_) external onlyAdmin {
    // `minCollateralRatio_` cannot be above `initCollateralRatio_` 
    if (minCollateralRatio_ > initCollateralRatio_) {
      revert CustomErrors.QA_MinCollateralRatioNotGreaterThanInit();
    }
    // Emit the event
    emit SetCreditFacility(
      account_, 
      _creditFacilityMap[account_].enabled,
      _creditFacilityMap[account_].minCollateralRatio, 
      _creditFacilityMap[account_].initCollateralRatio,
      _creditFacilityMap[account_].creditLimit,
      enabled_,
      minCollateralRatio_, 
      initCollateralRatio_,
      creditLimit_);
    
    // Set CreditFacility to new value
    _creditFacilityMap[account_].enabled = enabled_;
    _creditFacilityMap[account_].minCollateralRatio = minCollateralRatio_;
    _creditFacilityMap[account_].initCollateralRatio = initCollateralRatio_;
    _creditFacilityMap[account_].creditLimit = creditLimit_;
  }
  
  /// @notice Set the global close factor
  /// @param closeFactor_ New close factor value
  function _setCloseFactor(uint closeFactor_) external onlyAdmin {
    
    // `_closeFactor` needs to be between 0 and 1
    if (closeFactor_ > MANTISSA_FACTORS()) {
      revert CustomErrors.QA_OverThreshold(closeFactor_, MANTISSA_FACTORS());
    }

    // Emit the event
    emit SetCloseFactor(_closeFactor, closeFactor_);
    
    // Set `_closeFactor` to new value
    _closeFactor = closeFactor_;
  }

  /// @notice Set the global repayment grace period
  /// @param repaymentGracePeriod_ New repayment grace period
  function _setRepaymentGracePeriod(uint repaymentGracePeriod_) external onlyAdmin {

    // `_repaymentGracePeriod` needs to be <= 60*60*24 (ie 24 hours)
    if (repaymentGracePeriod_ > 86400) {
      revert CustomErrors.QA_OverThreshold(repaymentGracePeriod_, 86400);
    }

    // Emit the event
    emit SetRepaymentGracePeriod(_repaymentGracePeriod, repaymentGracePeriod_);

    // set `_repaymentGracePeriod` to new value
    _repaymentGracePeriod = repaymentGracePeriod_;
  }

  /// @notice Set the global maturity grace period
  /// @param maturityGracePeriod_ New maturity grace period
  function _setMaturityGracePeriod(uint maturityGracePeriod_) external onlyAdmin {
    
    // `_maturityGracePeriod` needs to be <= 60*60*24 (ie 24 hours)
    if (maturityGracePeriod_ > 86400) {
      revert CustomErrors.QA_OverThreshold(maturityGracePeriod_, 86400);
    }

    // Emit the event
    emit SetMaturityGracePeriod(_maturityGracePeriod, maturityGracePeriod_);
    
    // set `_maturityGracePeriod` to new value
    _maturityGracePeriod = maturityGracePeriod_;
  }
  
  /// @notice Set the global liquidation incetive
  /// @param liquidationIncentive_ New liquidation incentive value
  function _setLiquidationIncentive(uint liquidationIncentive_) external onlyAdmin {

    // `_liquidationIncentive` needs to be greater than or equal to 1
    if (liquidationIncentive_ < MANTISSA_FACTORS()) {
      revert CustomErrors.QA_UnderThreshold(liquidationIncentive_, MANTISSA_FACTORS());
    }

    // Emit the event
    emit SetLiquidationIncentive(_liquidationIncentive, liquidationIncentive_);   
    
    // Set `_liquidationIncentive` to new value
    _liquidationIncentive = liquidationIncentive_;
  }

  /// @notice Set the annualized protocol fees for each market in basis points
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @param protocolFee_ New protocol fee value (scaled to 1e4)
  function _setProtocolFee(address marketAddress, uint protocolFee_) public onlyAdmin {

    // Max annual protocol fees of 250 basis points
    if (protocolFee_ > 250) {
      revert CustomErrors.QA_OverThreshold(protocolFee_, 250);
    }

    // Min annual protocol fees of 1 basis point
    if (protocolFee_ < 1) {
      revert CustomErrors.QA_UnderThreshold(protocolFee_, 1);
    }
    
    // Casting from address into corresponding interface 
    IFixedRateMarket market = IFixedRateMarket(marketAddress);
    
    // Emit the event
    emit SetProtocolFee(_protocolFee[market], protocolFee_);
    
    // Set `_protocolFee` to new value
    _protocolFee[market] = protocolFee_;
  }

  /// @notice Set the global threshold in USD for protocol fee transfer
  /// @param thresholdUSD_ New threshold USD value (scaled by 1e18)
  function _setThresholdUSD(uint thresholdUSD_) external onlyAdmin {
    _thresholdUSD = thresholdUSD_;
  }
  
  /// @notice Pause/unpause all markets for admin
  /// @param paused Boolean to indicate if all markets should be paused
  function _setMarketsPaused(bool paused) external onlyAdmin {
    if (_marketsPaused != paused) {
      // Set `_marketsPaused` to new value
      _marketsPaused = paused;
      
      // Emit the event
      emit SetMarketPaused(paused);
    }
  }
  
  /// @notice Pause/unpause specified list of contracts for admin
  /// @param contractsAddr List of contract addresses to pause/unpause
  /// @param paused Boolean to indicate if specified contract should be paused
  function _setContractPaused(address[] memory contractsAddr, bool paused) external onlyAdmin {
    for (uint i = 0; i < contractsAddr.length; i++) {
      _setContractPaused(contractsAddr[i], paused);
    }
  }
  
  /// @notice Pause/unpause specified contract for admin
  /// @param contractAddr Address of contract to pause/unpause
  /// @param paused Boolean to indicate if specified contract should be paused
  function _setContractPaused(address contractAddr, bool paused) public onlyAdmin {
    if (_contractPausedMap[contractAddr] != paused) {
      // Set address in `_contractPausedMap` to new value
      _contractPausedMap[contractAddr] = paused;
      
      // Emit the event
      emit SetContractPaused(contractAddr, paused);
    }
  }
  
  /// @notice Pause/unpause specified list of operations for admin
  /// @param operationIds List of ids for operation to pause/unpause
  /// @param paused Boolean to indicate if specified operation should be paused
  function _setOperationPaused(uint[] memory operationIds, bool paused) external onlyAdmin {
    for (uint i = 0; i < operationIds.length; i++) {
      _setOperationPaused(operationIds[i], paused);
    }
  }
  
  /// @notice Pause/unpause specified operation for admin
  /// @param operationId Id for operation to pause/unpause
  /// @param paused Boolean to indicate if specified operation should be paused
  function _setOperationPaused(uint operationId, bool paused) public onlyAdmin {
    if (_operationPausedMap[operationId] != paused) {
      // Set id in `_operationPausedMap` to new value
      _operationPausedMap[operationId] = paused;
      
      // Emit the event
      emit SetOperationPaused(operationId, paused);
    }
  }

  /** VIEW FUNCTIONS **/
  
  /// @notice Get the address of the `WETH` contract
  function WETH() external view returns(address) {
    return address(_weth);
  }
  
  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManager() external view returns(address) {
    return address(_qollateralManager);
  }

  /// @notice Get the address of the `QPriceOracle` contract
  function qPriceOracle() external view returns(address) {
    if(address(_qollateralManager) != address(0)){
      return _qollateralManager.qPriceOracle();
    }else {
      return address(0);
    }
  }

  /// @notice Get the address of the `StakingEmissionsQontroller` contract
  function stakingEmissionsQontroller() external view returns(address) {
    return address(_stakingEmissionsQontroller);
  }

  /// @notice Get the address of the `TradingEmissionsQontroller` contract
  function tradingEmissionsQontroller() external view returns(address) {
    return address(_tradingEmissionsQontroller);
  }

  /// @notice Get the address of the `FeeEmissionsQontroller` contract
  function feeEmissionsQontroller() external view returns(address) {
    return address(_feeEmissionsQontroller);
  }
  
  /// @notice Get the address of the `LiquidityEmissionsQontroller` contract
  function liquidityEmissionsQontroller() external view returns(address) {
    return address(_liquidityEmissionsQontroller);
  }

  /// @notice Get the address of the `veQoda` contract
  function veQoda() external view returns(address) {
    return address(_veQoda);
  }
  
  /// @notice Get the address of the `QodaLens` contract
  function qodaLens() external view returns(address) {
    return address(_qodaLens);
  }

  /// @notice Get the credit limit with associated address, scaled by 1e6
  function creditLimit(address account_) external view returns(uint) {
    return _creditFacilityMap[account_].enabled? _creditFacilityMap[account_].creditLimit: UINT_MAX();
  }
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param token ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(IERC20 token) external view returns(QTypes.Asset memory) {
    return _assets[token];
  }

  /// @notice Get all enabled `Asset`s
  /// @return address[] iterable list of enabled `Asset`s
  function allAssets() external view returns(address[] memory) {
    return _allAssets;
  }

  /// @notice Gets the `oracleFeed` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return address Address of the oracle feed
  function oracleFeed(IERC20 token) external view returns(address) {
    return _assets[token].oracleFeed;
  }
  
  /// @notice Gets the `CollateralFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Collateral Factor, scaled by 1e8
  function collateralFactor(IERC20 token) external view returns(uint) {
    return _assets[token].collateralFactor;
  }

  /// @notice Gets the `MarketFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Market Factor, scaled by 1e8
  function marketFactor(IERC20 token) external view returns(uint) {
    return _assets[token].marketFactor;
  }

  /// @notice Gets the `maturities` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint[] array of UNIX timestamps (in seconds) of the maturity dates
  function maturities(IERC20 token) external view returns(uint[] memory) {
    return _assets[token].maturities;
  }
  
  /// @notice Get the MToken market corresponding to any underlying ERC20
  /// tokenAddress => mTokenAddress
  function underlyingToMToken(IERC20 token) external view returns(address) {
    return _underlyingToMToken[token];
  }
  
  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param token ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarkets(
                            IERC20 token,
                            uint maturity
                            ) external view returns(address){
    return _fixedRateMarkets[token][maturity];
  }

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(address marketAddress) external view returns(bool){
    return _enabledMarkets[marketAddress];
  }  

  function minQuoteSize(address marketAddress) external view returns(uint) {
    return _minQuoteSize[marketAddress];
  }
  
  function minCollateralRatio() public view returns(uint){
    return minCollateralRatio(msg.sender);
  }
  
  function minCollateralRatio(address account) public view returns(uint){
    return _creditFacilityMap[account].enabled? _creditFacilityMap[account].minCollateralRatio: _minCollateralRatio;
  }

  function initCollateralRatio() public view returns(uint){
    return initCollateralRatio(msg.sender);
  }
  
  function initCollateralRatio(address account) public view returns(uint){
    return _creditFacilityMap[account].enabled? _creditFacilityMap[account].initCollateralRatio: _initCollateralRatio;
  }

  function closeFactor() public view returns(uint){
    return _closeFactor;
  }

  function repaymentGracePeriod() public view returns(uint){
    return _repaymentGracePeriod;
  }

  function maturityGracePeriod() public view returns(uint){
    return _maturityGracePeriod;
  }
  
  function liquidationIncentive() public view returns(uint){
    return _liquidationIncentive;
  }

  /// @notice Annualized protocol fee in basis points, scaled by 1e4
  function protocolFee(address marketAddress) public view returns(uint) {
    return _protocolFee[IFixedRateMarket(marketAddress)];
  }

  /// @notice threshold in USD where protocol fee from each market will be transferred into `FeeEmissionsQontroller`
  /// once this amount is reached, scaled by 1e6
  function thresholdUSD() external view returns(uint) {
    return _thresholdUSD;
  }
  
  /// @notice Boolean to indicate if all markets are paused
  function marketsPaused() external view returns(bool) {
    return _marketsPaused;
  }
  
  /// @notice Boolean to indicate if specified contract address is paused
  function contractPaused(address contractAddr) external view returns(bool) {
    return _contractPausedMap[contractAddr];
  }
  
  /// @notice Boolean to indicate if specified operation is paused
  function operationPaused(uint operationId) external view returns(bool) {
    return _operationPausedMap[operationId];
  }
  
  /// @notice Check if given combination of contract address and operation should be allowed
  function isPaused(address contractAddr, uint operationId) external view returns(bool) {
    // Check if address is a market and if market is paused
    if (_marketsPaused && _enabledMarkets[contractAddr]) {
      return true;
    }
    // Check if pausing is applied for a particular contract 
    if (_contractPausedMap[contractAddr]) {
      return true;
    }
    // Check if pausing is applied for a particular operation
    if (_operationPausedMap[operationId]) {
      return true;
    }
    return false;
  }
  
  /// @notice 2**256 - 1
  function UINT_MAX() public pure returns(uint){
    return type(uint).max;
  }
  
  /// @notice Generic mantissa corresponding to ETH decimals
  function MANTISSA_DEFAULT() public pure returns(uint){
    return 1e18;
  }

  /// @notice Mantissa for USD
  function MANTISSA_USD() public pure returns(uint){
    return 1e18;
  }
  
  /// @notice Mantissa for collateral ratio
  function MANTISSA_COLLATERAL_RATIO() public pure returns(uint){
    return 1e8;
  }

  /// @notice `assetFactor` and `marketFactor` have up to 8 decimal places precision
  function MANTISSA_FACTORS() public pure returns(uint){
    return 1e8;
  }

  /// @notice Basis points have 4 decimal place precision
  function MANTISSA_BPS() public pure returns(uint){
    return 1e4;
  }

  /// @notice Staked Qoda has 6 decimal place precision
  function MANTISSA_STAKING() public pure returns(uint) {
    return 1e6;
  }
  
  /// @notice `collateralFactor` cannot be above 1.0
  function MAX_COLLATERAL_FACTOR() public pure returns(uint){
    return 1e8;
  }

  /// @notice `marketFactor` cannot be above 1.0
  function MAX_MARKET_FACTOR() public pure returns(uint){
    return 1e8;
  }
  
  /// @notice version number of this contract, will be bumped upon contractual change
  function VERSION_NUMBER() public pure returns(string memory){
    return "0.2.10";
  }
  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/QTypes.sol";

interface IFixedRateMarket {
  
  /// @notice Emitted when market order is created and loan can be created with one or more quotes
  event ExecMarketOrder(
                        uint8 indexed quoteSide,
                        address indexed account,
                        uint totalExecutedPV,
                        uint totalExecutedFV
                        );
  
  /// @notice Emitted when a borrower repays borrow.
  /// Boolean flag `withQTokens`= true if repaid via qTokens, false otherwise.
  event RepayBorrow(address indexed borrower, uint amount, bool withQTokens);
  
  /// @notice Emitted when a borrower is liquidated
  event LiquidateBorrow(
                        address indexed borrower,
                        address indexed liquidator,
                        uint amount,
                        address collateralTokenAddr,
                        uint reward
                        );
  
  /// @notice Emitted when a borrower and lender are matched for a fixed rate loan
  event FixedRateLoan(
                      uint8 indexed quoteSide,
                      address indexed borrower,
                      address indexed lender,
                      uint amountPV,
                      uint amountFV,
                      uint feeIncurred,
                      uint64 APR
                      );
    
  /// @notice Emitted when setting `_quoteManager`
  event SetQuoteManager(address quoteManagerAddress);
  
  /// @notice Emitted when setting `_qToken`
  event SetQToken(address qTokenAddress);

  /** ADMIN FUNCTIONS **/
  
  /// @notice Call upon initialization after deploying `QuoteManager` contract
  /// @param quoteManagerAddress Address of `QuoteManager` deployment
  function _setQuoteManager(address quoteManagerAddress) external;
    
  /// @notice Call upon initialization after deploying `QToken` contract
  /// @param qTokenAddress Address of `QToken` deployment
  function _setQToken(address qTokenAddress) external;
  
  /// @notice Function to be used by qToken contract to transfer native or underlying token to recipient
  /// Transfer operation is centralized in FixedRateMarket so token held does not need to be transferred
  /// to/from qToken contract.
  /// @param receiver Account of the receiver
  /// @param amount Size of the fund to be transferred from sender to receiver
  /// @param isSendingETH Indicate if sender is sending fund with ETH
  /// @param isReceivingETH Indicate if receiver is receiving fund with ETH
  function _transferTokenOrETH(
                               address receiver,
                               uint amount,
                               bool isSendingETH,
                               bool isReceivingETH
                               ) external;
  
  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param to Address of the receiver
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function _repayBorrowInQToken(address to, uint amount) external returns(uint);
  
  function _updateLiquidityEmissionsOnRedeem(uint8 side, uint64 id) external;
  
  /// @notice Call upon quote creation
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onCreateQuote(uint8 side, uint64 id) external;
    
  /// @notice Call upon quote fill
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onFillQuote(uint8 side, uint64 id) external;
    
  /// @notice Call upon quote cancellation
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function _onCancelQuote(uint8 side, uint64 id) external;
  
  /** USER INTERFACE **/
  
  /// @notice Creates a new  `Quote` and adds it to the `OrderbookSide` linked list by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param APR In decimal form scaled by 1e4 (ex. 1052 = 10.52%)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  function createQuote(uint8 side, uint8 quoteType, uint64 APR, uint cashflow) external;
  
  /// @notice Analogue of market order to borrow against current lend `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// @param amountPV The maximum amount to borrow
  /// @param maxAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function borrow(uint amountPV, uint64 maxAPR) external;
    
  /// @notice Analogue of market order to borrow against current lend `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// ETH will be sent to borrower
  /// @param amountPV The maximum amount to borrow
  /// @param maxAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function borrowETH(uint amountPV, uint64 maxAPR) external;

  /// @notice Analogue of market order to lend against current borrow `Quote`s.
  /// Only fills at most up to `amountPV`, any unfilled amount is discarded.
  /// @param amountPV The maximum amount to lend
  /// @param minAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function lend(uint amountPV, uint64 minAPR) external;
    
  /// @notice Analogue of market order to lend against current borrow `Quote`s.
  /// Only fills at most up to `msg.value`, any unfilled amount is discarded.
  /// Excessive amount will be sent back to lender
  /// Note that protocol fee should also be included as ETH sent in the function call
  /// @param minAPR Only accept `Quote`s up to specified APR. You may think of
  /// this as a maximum slippage tolerance variable
  function lendETH(uint64 minAPR) external payable;

  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function repayBorrow(uint amount) external returns(uint);
  
  /// @notice Borrower will make repayments to the smart contract using ETH, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @return uint Remaining account borrow amount
  function repayBorrowWithETH() external payable returns(uint);
  
  /// @notice Cancel `Quote` by id. Note this is a O(1) operation
  /// since `OrderbookSide` uses hashmaps under the hood. However, it is
  /// O(n) against the array of `Quote` ids by account so we should ensure
  /// that array should not grow too large in practice.
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of the `Quote`
  function cancelQuote(uint8 side, uint64 id) external;

  /// @notice If an account is in danger of being underwater (i.e. collateralRatio < 1.0)
  /// or has not repaid past maturity plus `_repaymentGracePeriod`, any user may
  /// liquidate that account by paying back the loan on behalf of the account. In return,
  /// the liquidator receives collateral belonging to the account equal in value to
  /// the repayment amount in USD plus the liquidation incentive amount as a bonus.
  /// @param borrower Address of account to liquidate
  /// @param amount Amount to repay on behalf of account in the currency of the loan
  /// @param collateralToken Liquidator's choice of which currency to be paid in
  function liquidateBorrow(address borrower, uint amount, IERC20 collateralToken) external;
    
  /** VIEW FUNCTIONS **/
  
  /// @notice Get the name of this contract
  /// @return address contract name
  function name() external view returns(string memory);
  
  /// @notice Get the symbol representing this contract
  /// @return address contract symbol
  function symbol() external view returns(string memory);

  /// @notice Get the address of the `QAdmin`
  /// @return address
  function qAdmin() external view returns(address);
  
  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManager() external view returns(address);
    
  /// @notice Get the address of the `QuoteManager`
  /// @return address
  function quoteManager() external view returns(address);
  
  /// @notice Get the address of the `QToken`
  /// @return address
  function qToken() external view returns(address);

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return IERC20
  function underlyingToken() external view returns(IERC20);

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint);

  /// @notice Get the minimum quote size for this market
  /// @return uint Minimum quote size, in PV terms, local currency
  function minQuoteSize() external view returns(uint);

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint);

  /// @notice Get the linked list pointer top of book for `Quote` by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return uint64 id of top of book `Quote` 
  function getQuoteHeadId(uint8 side) external view returns(uint64);

  /// @notice Get the top of book for `Quote` by side
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return QTypes.Quote head `Quote`
  function getQuoteHead(uint8 side) external view returns(QTypes.Quote memory);
  
  /// @notice Get the `Quote` for the given `side` and `id`
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param id Id of `Quote`
  /// @return QTypes.Quote `Quote` associated with the id
  function getQuote(uint8 side, uint64 id) external view returns(QTypes.Quote memory);

  /// @notice Get all live `Quote` id's by `account` and `side`
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Account to query
  /// @return uint[] Unsorted array of borrow `Quote` id's
  function getAccountQuotes(uint8 side, address account) external view returns(uint64[] memory);

  /// @notice Get the number of active `Quote`s by `side` in the orderbook
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return uint Number of `Quote`s
  function getNumQuotes(uint8 side) external view returns(uint);
    
  /// @notice Gets the `protocolFee` associated with this market
  /// @return uint annualized protocol fee, scaled by 1e4
  function protocolFee() external view returns(uint);

  /// @notice Gets the `protocolFee` associated with this market, prorated by time till maturity 
  /// @param amount loan amount
  /// @return uint prorated protocol fee in local currency
  function proratedProtocolFee(uint amount) external view returns(uint);
  
  /// @notice Gets the `protocolFee` associated with this market, prorated by time till maturity 
  /// @param amount loan amount
  /// @param timestamp UNIX timestamp in seconds
  /// @return uint prorated protocol fee in local currency
  function proratedProtocolFee(uint amount, uint timestamp) external view returns(uint);

  /// @notice Get total protocol fee accrued in this market so far, in local currency
  /// @return uint accrued fee
  function totalAccruedFees() external view returns(uint);

  /// @notice Get the PV of a cashflow amount based on the `quoteType`
  /// @param quoteType 0 for PV, 1 for FV
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param sTime PV start time
  /// @param eTime FV end time
  /// @param amount Value to be PV'ed
  /// @return uint PV of the `amount`
  function getPV(
                 uint8 quoteType,
                 uint64 APR,
                 uint amount,
                 uint sTime,
                 uint eTime
                 ) external view returns(uint);

  /// @notice Get the FV of a cashflow amount based on the `quoteType`
  /// @param quoteType 0 for PV, 1 for FV
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param sTime PV start time
  /// @param eTime FV end time
  /// @param amount Value to be FV'ed
  /// @return uint FV of the `amount`
  function getFV(
                 uint8 quoteType,
                 uint64 APR,
                 uint amount,
                 uint sTime,
                 uint eTime
                 ) external view returns(uint);

  /// @notice Get maximum value user can lend with given amount when protocol fee is factored in.
  /// Mantissa is added to reduce precision error during calculation
  /// @param amount Lending amount with protocol fee factored in
  /// @return uint Maximum value user can lend with protocol fee considered
  function hypotheticalMaxLendPV(uint amount) external view returns (uint);
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFixedRateMarket.sol";

interface IQollateralManager {

  /// @notice Emitted when an account deposits collateral into the contract
  event DepositCollateral(address indexed account, address tokenAddress, uint amount);

  /// @notice Emitted when an account withdraws collateral from the contract
  event WithdrawCollateral(address indexed account, address tokenAddress, uint amount);
  
  /// @notice Emitted when an account first interacts with the `Market`
  event AddAccountMarket(address indexed account, address indexed market);

  /// @notice Emitted when collateral is transferred from one account to another
  event TransferCollateral(address indexed tokenAddress, address indexed from, address indexed to, uint amount);
  
  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress_ Address of the `QAdmin` contract
  /// @param qPriceOracleAddress_ Address of the `QPriceOracle` contract
  function initialize(address qAdminAddress_, address qPriceOracleAddress_) external;

  /** ADMIN/RESTRICTED FUNCTIONS **/

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `borrowValue`. Only the `FixedRateMarket` contract itself may call
  /// this function
  /// @param account User account
  /// @param market Address of the `FixedRateMarket` market
  function _addAccountMarket(address account, IFixedRateMarket market) external;

  /// @notice Transfer collateral balances from one account to another. Only
  /// `FixedRateMarket` contracts can call this restricted function. This is used
  /// for when a liquidator liquidates an account.
  /// @param token ERC20 token
  /// @param from Sender address
  /// @param to Recipient address
  /// @param amount Amount to transfer
  function _transferCollateral(IERC20 token, address from, address to, uint amount) external;
  
  /** USER INTERFACE **/
  
  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param token ERC20 token
  /// @param amount Amount to deposit (in local ccy)
  /// @return uint New collateral balance
  function depositCollateral(IERC20 token, uint amount) external returns(uint);

  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped into MTokens for convenience so users can
  /// automatically earn interest on their collateral.
  /// @param underlying Underlying ERC20 token
  /// @param amount Amount to deposit (in underlying local currency)
  /// @return uint New collateral balance (in MToken balance)
  function depositCollateralWithMTokenWrap(IERC20 underlying, uint amount) external returns(uint);
  
  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped from ETH to WETH.
  /// @return uint New collateral balance (in WETH balance)
  function depositCollateralWithETH() external payable returns(uint);
  
  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped from ETH into MTokens for convenience so users can
  /// automatically earn interest on their collateral.
  /// @return uint New collateral balance (in MToken balance)
  function depositCollateralWithMTokenWrapWithETH() external payable returns(uint);
  
  /// @notice Users call this to withdraw collateral
  /// @param token ERC20 token
  /// @param amount Amount to withdraw (in local ccy)
  /// @return uint New collateral balance
  function withdrawCollateral(IERC20 token, uint amount) external returns(uint);

  /// @notice Users call this to withdraw mToken collateral, where their
  /// collateral is automatically unwrapped into underlying tokens for
  /// convenience.
  /// @param mTokenAddress Yield-bearing token address
  /// @param amount Amount to withdraw (in mToken local currency)
  /// @return uint New collateral balance (in MToken balance)
  function withdrawCollateralWithMTokenUnwrap(
                                              address mTokenAddress,
                                              uint amount
                                              ) external returns(uint);
    
  /// @notice Users call this to withdraw ETH collateral, where their
  /// collateral is automatically unwrapped from WETH for convenience.
  /// @param amount Amount to withdraw (in WETH local currency)
  /// @return uint New collateral balance (in WETH balance)
  function withdrawCollateralWithETH(uint amount) external returns(uint);
  
  /// @notice Users call this to withdraw mToken collateral, where their
  /// collateral is automatically unwrapped into ETH for convenience.
  /// @param amount Amount to withdraw (in WETH local currency)
  /// @return uint New collateral balance (in MToken balance)
  function withdrawCollateralWithMTokenWrapWithETH(uint amount) external returns(uint);
  
  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);

  /// @notice Get the address of the `QPriceOracle` contract
  /// @return address Address of `QPriceOracle` contract
  function qPriceOracle() external view returns(address);

  /// @notice Get all enabled `Asset`s
  /// @return address[] iterable list of enabled `Asset`s
  function allAssets() external view returns(address[] memory);
  
  /// @notice Gets the `CollateralFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Collateral Factor, scaled by 1e8
  function collateralFactor(IERC20 token) external view returns(uint);

  /// @notice Gets the `MarketFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Market Factor, scaled by 1e8
  function marketFactor(IERC20 token) external view returns(uint);
  
  /// @notice Return what the collateral ratio for an account would be
  /// with a hypothetical collateral withdraw/deposit and/or token borrow/lend.
  /// The collateral ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// If the returned value falls below 1e8, the account can be liquidated
  /// @param account User account
  /// @param hypotheticalToken Currency of hypothetical withdraw / deposit
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param depositAmount Amount of hypothetical deposit in local currency
  /// @param hypotheticalMarket Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param lendAmount Amount of hypothetical lend in local ccy
  /// @return uint Hypothetical collateral ratio
  function hypotheticalCollateralRatio(
                                       address account,
                                       IERC20 hypotheticalToken,
                                       uint withdrawAmount,
                                       uint depositAmount,
                                       IFixedRateMarket hypotheticalMarket,
                                       uint borrowAmount,
                                       uint lendAmount
                                       ) external view returns(uint);

  /// @notice Return the current collateral ratio for an account.
  /// The collateral ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// If the returned value falls below 1e8, the account can be liquidated
  /// @param account User account
  /// @return uint Collateral ratio
  function collateralRatio(address account) external view returns(uint);
  
  /// @notice Get the `collateralFactor` weighted value (in USD) of all the
  /// collateral deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD, scaled to 1e18
  function virtualCollateralValue(address account) external view returns(uint);
  
  /// @notice Get the `collateralFactor` weighted value (in USD) for the tokens
  /// deposited for an account
  /// @param account Account to query
  /// @param token ERC20 token
  /// @return uint Value of token collateral of account in USD, scaled to 1e18
  function virtualCollateralValueByToken(
                                         address account,
                                         IERC20 token
                                         ) external view returns(uint);

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function virtualBorrowValue(address account) external view returns(uint);
  
  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param market `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function virtualBorrowValueByMarket(
                                      address account,
                                      IFixedRateMarket market
                                      ) external view returns(uint);

  /// @notice Return what the weighted total borrow value for an account would be with a hypothetical borrow  
  /// @param account Account to query
  /// @param hypotheticalMarket Market of hypothetical borrow / lend
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param lendAmount Amount of hypothetical lend in local ccy
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function hypotheticalVirtualBorrowValue(
                                          address account,
                                          IFixedRateMarket hypotheticalMarket,
                                          uint borrowAmount,
                                          uint lendAmount
                                          ) external view returns(uint);
  
  /// @notice Get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD, scaled to 1e18
  function realCollateralValue(address account) external view returns(uint);
  
  /// @notice Get the unweighted value (in USD) of the tokens deposited
  /// for an account
  /// @param account Account to query
  /// @param token ERC20 token
  /// @return uint Value of token collateral of account in USD, scaled to 1e18
  function realCollateralValueByToken(
                                      address account,
                                      IERC20 token
                                      ) external view returns(uint);
  
  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function realBorrowValue(address account) external view returns(uint);

  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param market `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function realBorrowValueByMarket(
                                   address account,
                                   IFixedRateMarket market
                                   ) external view returns(uint);
  
  /// @notice Get an account's maximum available borrow amount in a specific FixedRateMarket.
  /// For example, what is the maximum amount of GLMRJUL22 that an account can borrow
  /// while ensuring their account health continues to be acceptable?
  /// Note: This function will return 0 if market to borrow is disabled
  /// Note: This function will return creditLimit() if maximum amount allowed for one market exceeds creditLimit()
  /// Note: User can only borrow up to `initCollateralRatio` for their own protection against instant liquidations
  /// @param account User account
  /// @param borrowMarket Address of the `FixedRateMarket` market to borrow
  /// @return uint Maximum available amount user can borrow (in FV) without breaching `initCollateralRatio`
  function hypotheticalMaxBorrowFV(address account, IFixedRateMarket borrowMarket) external view returns(uint);

  /// @notice Get the minimum collateral ratio. Scaled by 1e8.
  /// @return uint Minimum collateral ratio
  function minCollateralRatio() external view returns(uint);
  
  /// @notice Get the minimum collateral ratio for a user account. Scaled by 1e8.
  /// @param account User account 
  /// @return uint Minimum collateral ratio
  function minCollateralRatio(address account) external view returns(uint);
  
  /// @notice Get the initial collateral ratio. Scaled by 1e8
  /// @return uint Initial collateral ratio
  function initCollateralRatio() external view returns(uint);
  
  /// @notice Get the initial collateral ratio for a user account. Scaled by 1e8
  /// @param account User account 
  /// @return uint Initial collateral ratio
  function initCollateralRatio(address account) external view returns(uint);
  
  /// @notice Get the close factor. Scaled by 1e8
  /// @return uint Close factor
  function closeFactor() external view returns(uint);

  /// @notice Get the liquidation incentive. Scaled by 1e8
  /// @return uint Liquidation incentive
  function liquidationIncentive() external view returns(uint);
  
  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param account User account
  /// @param token ERC20 token
  /// @return uint Balance in local
  function collateralBalance(address account, IERC20 token) external view returns(uint);

  /// @notice Get iterable list of collateral addresses which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function iterableCollateralAddresses(address account) external view returns(IERC20[] memory);

  /// @notice Quick lookup of whether an account has a particular collateral
  /// @param account User account
  /// @param token ERC20 token addresses
  /// @return bool True if account has collateralized with given ERC20 token, false otherwise
  function accountCollateral(address account, IERC20 token) external view returns(bool);

  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function iterableAccountMarkets(address account) external view returns(IFixedRateMarket[] memory);
                                                                         
  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param account User account
  /// @param market`FixedRateLoanMarket` contract
  /// @return bool True if participated, false otherwise
  function accountMarkets(address account, IFixedRateMarket market) external view returns(bool);
                                                                       
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD, scaled to 1e18
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint);

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeEmissionsQontroller {

  /// @notice Emitted when user claims emissions
  event ClaimEmissions(address indexed account, uint amount);

  /// @notice Emitted when fee is accrued in a round
  event FeesAccrued(uint indexed round, address token, uint amount, uint amountInRound);

  /// @notice Emitted when we move to a new round
  event NewFeeEmissionsRound(uint indexed currentPeriod, uint startTime, uint endTime);

  /** ACCESS CONTROLLED FUNCTIONS **/

  function receiveFees(IERC20 underlyingToken, uint feeLocal) external;

  function veIncrease(address account, uint veIncreased) external;

  function veReset(address account) external;

  /** USER INTERFACE **/

  function claimEmissions() external;

  function claimEmissions(address account) external;


  /** VIEW FUNCTIONS **/
  
  function claimableEmissions() external view returns (uint);
  
  function claimableEmissions(address account) external view returns (uint);
  
  function expectedClaimableEmissions() external view returns (uint);
  
  function expectedClaimableEmissions(address account) external view returns (uint);

  function qAdmin() external view returns (address);

  function veToken() external view returns (address);

  function swapContract() external view returns (address);

  function WETH() external view returns (IERC20);

  function emissionsRound() external view returns (uint, uint, uint);
  
  function emissionsRound(uint round_) external view returns (uint, uint, uint);

  function timeTillRoundEnd() external view returns (uint);

  function stakedVeAtRound(address account, uint round) external view returns (uint);

  function roundInterval() external view returns (uint);

  function currentRound() external view returns (uint);

  function lastClaimedRound() external view returns (uint);

  function lastClaimedRound(address account) external view returns (uint);

  function lastClaimedVeBalance() external view returns (uint);

  function lastClaimedVeBalance(address account) external view returns (uint);
  
  function claimedEmissions() external view returns (uint);
    
  function claimedEmissions(address account) external view returns (uint);

  function totalFeesAccrued() external view returns (uint);

  function totalFeesClaimed() external view returns (uint);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IFixedRateMarket.sol";
import "../libraries/QTypes.sol";

interface ILiquidityEmissionsQontroller {
  /** EVENTS **/
  
  /// @notice Emitted when user claims emissions
  event ClaimEmissions(address indexed account, uint emission);
  
  /** ACCESS CONTROLLED FUNCTIONS **/
  
  /// @notice Distribute cumulated reward to the top-of-book
  /// Function will be invoked whenever quotes within a market is updated, which happens when:
  /// - New quote is created
  /// - Existing quote gets filled
  /// - Existing quote gets cancelled
  /// - Market expiry is reached
  /// @param market `FixedRateMarket` contract where quote update happens
  /// @param side Order book side for reward to be distributed. 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param currQuoteId Id of the newly created quote
  function updateRewards(IFixedRateMarket market, uint8 side, uint64 currQuoteId) external;
  
  /// @notice Function to set number of token to distribute per second for given market
  /// @param market `FixedRateMarket` contract
  /// @param rewardPerSec_ Number of token to distribute per second, scaled to decimal of the token
  function _setRewardPerSec(address market, uint rewardPerSec_) external;
  
  /// @notice Function to set all detail related for given market, can only be invoked once.
  /// Note that reward token should be approved on sender side before this function is invoked.
  /// @param market `FixedRateMarket` contract
  /// @param rewardTokenAddress Address of reward token to distribute
  /// @param rewardPerSec_ Number of token to distribute per second, scaled to decimal of the token
  /// @param allocation Maximum reward given market can distribute to user, scaled to decimal of the token
  function _setMarketInfo(address market, address rewardTokenAddress, uint rewardPerSec_, uint allocation) external;
  
  /// @notice Function to start reward distribution for given market, can only be invoked once.
  /// @param startSec start time in second for reward distribution, 0 for current time
  function _startDistribution(address market, uint startSec) external;
  
  /// @notice Withdraw the specified amount if possible.
  /// @param rewardTokenAddress Address of reward token to withdraw
  /// @param amount the amount to withdraw
  function _withdraw(address rewardTokenAddress, uint amount) external;
  
  /** USER INTERFACE **/
  
  /// @notice Distribute cumulated reward to the top-of-book for specified market and side
  /// Unless forcing reward emission in given market is needed (e.g. user is top-of-book but there 
  /// is no market activity), user can simply rely on market contract to manage reward distribution
  /// @param market `FixedRateMarket` contract where quote update happens
  /// @param side Order book side for reward to be distributed. 0 for borrow `Quote`, 1 for lend `Quote`
  function updateRewards(IFixedRateMarket market, uint8 side) external;
  
  /// @notice Mint unclaimed rewards to user and reset their claimable emissions
  function claimEmissions() external;
  
  /// @notice Mint unclaimed rewards to specified account and reset their claimable emissions
  /// @param account Address of the user
  function claimEmissions(address account) external;
  
  /// @notice Do top-of-book calculation for given market before transferring unclaimed reward to specified account and resetting
  /// @param account Address of the user
  /// @param market `FixedRateMarket` contract where quote update happens
  function claimEmissionsWithRewardUpdate(address account, IFixedRateMarket market) external;
  
  /** VIEW FUNCTIONS **/
    
  /// @notice Check if given account is top-of-book of specified side of the market
  /// Note that function assumes quotes in each market is ordered by best APR first, 
  /// followed by quote creation sequence in case of ties
  /// @param market `FixedRateMarket` contract for top-of-book check
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Address of the user
  /// @return bool true if account is currently top-of-book of specified side of the market
  function isTopOfBook(IFixedRateMarket market, uint8 side, address account) external view returns(bool);
  
  /// @notice Check if given account is top-of-book of specified side of the market,
  /// starting with given quote id
  /// Note that function assumes quotes in each market is ordered by best APR first, 
  /// followed by quote creation sequence in case of ties
  /// @param market `FixedRateMarket` contract for top-of-book check
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @param account Address of the user
  /// @param startQuoteId Quote id to start top-of-book check
  /// @return bool true if account is currently top-of-book of specified side of the market
  function isTopOfBook(IFixedRateMarket market, uint8 side, address account, uint64 startQuoteId) external view returns(bool);
  
  /// @notice Get top-of-book quote of specified side of the market
  /// @param market `FixedRateMarket` contract for top-of-book check
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return QTypes.Quote top-of-book quote for specified side of the market
  function getQuoteEligibleForReward(IFixedRateMarket market, uint8 side) external view returns (QTypes.Quote memory);
  
  /// @notice Get top-of-book quote of specified side of the market,
  /// starting with given quote id
  /// @param market `FixedRateMarket` contract for top-of-book check
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return QTypes.Quote top-of-book quote for specified side of the market
  function getQuoteEligibleForReward(IFixedRateMarket market, uint8 side, uint64 startQuoteId) external view returns (QTypes.Quote memory);
  
  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);

  /// @notice Get the address of the reward token to distribute
  /// @param marketAddress `FixedRateMarket` contract address
  /// @return address Address of the reward token to distribute
  function rewardToken(address marketAddress) external view returns(address);
  
  /// @notice Get reward pending to claim for specified account
  /// @param account Account to query
  /// @param rewardTokenAddress Address of reward token to distribute
  /// @return uint reward pending to claim for specified account, scaled to decimal of the token
  function pendingReward(address account, address rewardTokenAddress) external view returns(uint);
  
  /// @notice Get amount per second to grant top-of-book quoter with given market
  /// @param marketAddress `FixedRateMarket` contract address
  /// @return Reward per second, scaled to decimal of the token
  function rewardPerSec(address marketAddress) external view returns(uint);
  
  /// @notice Get last reward distribution time for given market and side
  /// @param marketAddress `FixedRateMarket` contract address
  /// @param side 0 for borrow `Quote`, 1 for lend `Quote`
  /// @return Last reward distribution time, measured in second
  function lastDistributeTime(address marketAddress, uint8 side) external view returns(uint);
  
  /// @notice Get total allocated token balance for given market
  /// @param marketAddress `FixedRateMarket` contract address
  /// @return Total allocated token balance for given market, scaled to decimal of the token
  function totalAllocation(address marketAddress) external view returns(uint);
  
  /// @notice Get remaining allocated token balance for given market
  /// @param marketAddress `FixedRateMarket` contract address
  /// @return Remaining allocated token balance for given market, scaled to decimal of the token
  function remainingAllocation(address marketAddress) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IStakingEmissionsQontroller {

  /** EVENTS **/
  
  /// @notice Emitted when we move to a new emissions regime
  event NewEmissionsPerSec(uint indexed currentPeriod, uint startTime, uint emissions, uint numSecs);

  /// @notice Emitted when user claims emissions
  event ClaimEmissions(address indexed account, uint emission);
  
  /// @notice Emitted when user deposits
  event Deposit(address indexed account, uint amount);

  /// @notice Emitted when user withdraws
  event Withdraw(address indexed account, uint amount);
  
  /** ACCESS CONTROLLED FUNCTIONS **/
  
  /// @notice Credits the account with the given amount in `StakingEmissionsQontroller`
  /// This function should only be called by the veToken contract when the user
  /// claims their accrued veTokens.
  /// @param account Address of the user
  /// @param amount Amount to credit the account
  function deposit(address account, uint amount) external;

  /// @notice Cancels account's full amount and debt from `StakingEmissionsQontroller`
  /// and claims any remaining emissions for that account. This should only
  /// be called by the veToken contract when the user unstakes the underlying
  /// @param account Address of the user.
  function withdraw(address account) external;
  
  /// @notice Function to start reward distribution, can only be invoked once.
  /// @param startSec start time in second for reward distribution, 0 for current time
  function _startStaking(uint startSec) external;

  /** USER INTERFACE **/

  /// @notice Transfer accrued emissions from `StakingEmissionsQontroller` to veToken holder
  /// This function can be called by the user anytime and as often as they wish.
  function claimEmissions() external;

  /// @notice Update emissions variables of the pool
  function updatePool() external;

  /** VIEW FUNCTIONS **/

  /// @notice Calculates the amount of emissions claimable by a user by updating
  /// the pool info in memory without writing to storage so that viewing the
  /// claimable amount does not incur gas costs.
  /// @param account Address of the user
  /// @return uint Amount claimable
  function claimableEmissions(address account) external view returns(uint);

  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);
  
  /// @notice Get the address of the `QodaERC20` contract
  /// @return address Address of `QodaERC20` contract
  function qodaERC20() external view returns(address);

  /// @notice Get the address of the `veQoda` contract
  /// @return address Address of `veQoda` contract
  function veToken() external view returns(address);

  function numPeriods() external view returns(uint);
  
  function accTokenPerShare() external view returns(uint);

  function currentPeriod() external view returns(uint);

  function endTime() external view returns(uint);

  function lastEmissionsTime() external view returns(uint);

  function emissions() external view returns(uint);

  function numSecs() external view returns(uint);

  // @return emissions per second, scaled by 1e18
  function emissionsPerSec() external view returns(uint);

  function userInfo(address account) external view returns(uint, uint, uint);
  
  function stakingPeriod(uint i) external view returns(uint, uint);
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ITradingEmissionsQontroller {

  /** ACCESS CONTROLLED FUNCTIONS **/
  
  /// @notice Use the fees generated (in USD) as basis to calculate how much
  /// token reward to disburse for trading volumes. Only `FixedRateMarket`
  /// contracts may call this function.
  /// @param borrower Address of the borrower
  /// @param lender Address of the lender
  /// @param feeUSD Fees generated (in USD, scaled to 1e18)
  function updateRewards(address borrower, address lender, uint feeUSD) external;

  
  /** USER INTERFACE **/

  /// @notice Mint the unclaimed rewards to user and reset their claimable emissions
  function claimEmissions() external;

  
  /** VIEW FUNCTIONS **/

  /// @notice Checks the amount of unclaimed trading rewards that the user can claim
  /// @param account Address of the user
  /// @return uint Amount of QODA token rewards the user may claim
  function claimableEmissions(address account) external view returns(uint);

  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);

  /// @notice Get the address of the ERC20 token to distribute
  /// @return address Address of the ERC20 token to distribute
  function underlying() external view returns(address);

  function numPhases() external view returns(uint);

  function currentPhase() external view returns(uint);

  function totalAllocation() external view returns(uint);

  function emissionsPhase(uint phase) external view returns(uint, uint, uint);
  
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/QTypes.sol";

interface IQAdmin is IAccessControlUpgradeable {

  /// @notice Emitted when a new FixedRateMarket is deployed
  event CreateFixedRateMarket(address indexed marketAddress, address indexed tokenAddress, uint maturity);
  
  /// @notice Emitted when existing FixedRateMarket is removed
  event RemoveFixedRateMarket(address indexed marketAddress, address indexed tokenAddress, uint maturity);
  
  /// @notice Emitted when a new `Asset` is added
  event AddAsset(
                 address indexed tokenAddress,
                 bool isYieldBearing,
                 address oracleFeed,
                 uint collateralFactor,
                 uint marketFactor);
  
  /// @notice Emitted when existing `Asset` is removed
  event RemoveAsset(address indexed tokenAddress);
  
  /// @notice Emitted when setting `_weth`
  event SetWETH(address wethAddress);

  /// @notice Emitted when setting `_qollateralManager`
  event SetQollateralManager(address qollateralManagerAddress);

  /// @notice Emitted when setting `_stakingEmissionsQontroller`
  event SetStakingEmissionsQontroller(address stakingEmissionsQontrollerAddress);

  /// @notice Emitted when setting `_tradingEmissionsQontroller`
  event SetTradingEmissionsQontroller(address tradingEmissionsQontrollerAddress);

  /// @notice Emitted when setting `_feeEmissionsQontroller`
  event SetFeeEmissionsQontroller(address feeEmissionsQontrollerAddress);
  
  /// @notice Emitted when setting `_liquidityEmissionsQontroller`
  event SetLiquidityEmissionsQontroller(address liquidityEmissionsQontrollerAddress);

  /// @notice Emitted when setting `_veQoda`
  event SetVeQoda(address veQodaAddress);
  
  /// @notice Emitted when setting `_qodaLens`
  event SetQodaLens(address qodaLensAddress);
  
  /// @notice Emitted when setting `collateralFactor`
  event SetCollateralFactor(address indexed tokenAddress, uint oldValue, uint newValue);

  /// @notice Emitted when setting `marketFactor`
  event SetMarketFactor(address indexed tokenAddress, uint oldValue, uint newValue);

  /// @notice Emitted when setting `minQuoteSize`
  event SetMinQuoteSize(address indexed tokenAddress, uint oldValue, uint newValue);
  
  /// @notice Emitted when `_minCollateralRatioDefault` and `_initCollateralRatioDefault` get updated
  event SetCollateralRatio(uint oldMinValue, uint oldInitValue, uint newMinValue, uint newInitValue);
  
  /// @notice Emitted when `CreditFacility` gets updated
  event SetCreditFacility(address account, bool oldEnabled, uint oldMinValue, uint oldInitValue, uint oldCreditValue, bool newEnabled, uint newMinValue, uint newInitValue, uint newCreditValue);
  
  /// @notice Emitted when `_closeFactor` gets updated
  event SetCloseFactor(uint oldValue, uint newValue);

  /// @notice Emitted when `_repaymentGracePeriod` gets updated
  event SetRepaymentGracePeriod(uint oldValue, uint newValue);
  
  /// @notice Emitted when `_maturityGracePeriod` gets updated
  event SetMaturityGracePeriod(uint oldValue, uint newValue);
  
  /// @notice Emitted when `_liquidationIncentive` gets updated
  event SetLiquidationIncentive(uint oldValue, uint newValue);

  /// @notice Emitted when `_protocolFee` gets updated
  event SetProtocolFee(uint oldValue, uint newValue);
  
  /// @notice Emitted when pause state of all `FixedRateMarket` contract is changed
  event SetMarketPaused(bool paused);
  
  /// @notice Emitted when pause state of a particular contract is changed
  event SetContractPaused(address contractAddr, bool paused);
  
  /// @notice Emitted when pause state of a particular operation is changed
  event SetOperationPaused(uint operationId, bool paused);
  
  /** ADMIN FUNCTIONS **/

  /// @notice Call upon initialization after deploying `QAdmin` contract
  /// @param wethAddress Address of `WETH` contract of the network 
  function _setWETH(address wethAddress) external;
  
  /// @notice Call upon initialization after deploying `QollateralManager` contract
  /// @param qollateralManagerAddress Address of `QollateralManager` deployment
  function _setQollateralManager(address qollateralManagerAddress) external;

  /// @notice Call upon initialization after deploying `StakingEmissionsQontroller` contract
  /// @param stakingEmissionsQontrollerAddress Address of `StakingEmissionsQontroller` deployment
  function _setStakingEmissionsQontroller(address stakingEmissionsQontrollerAddress) external;

  /// @notice Call upon initialization after deploying `TradingEmissionsQontroller` contract
  /// @param tradingEmissionsQontrollerAddress Address of `TradingEmissionsQontroller` deployment
  function _setTradingEmissionsQontroller(address tradingEmissionsQontrollerAddress) external;

  /// @notice Call upon initialization after deploying `FeeEmissionsQontroller` contract
  /// @param feeEmissionsQontrollerAddress Address of `FeeEmissionsQontroller` deployment
  function _setFeeEmissionsQontroller(address feeEmissionsQontrollerAddress) external;
  
  /// @notice Call upon initialization after deploying `LiquidityEmissionsQontroller` contract
  /// @param liquidityEmissionsQontrollerAddress Address of `LiquidityEmissionsQontroller` deployment
  function _setLiquidityEmissionsQontroller(address liquidityEmissionsQontrollerAddress) external;

  /// @notice Call upon initialization after deploying `veQoda` contract
  /// @param veQodaAddress Address of `veQoda` deployment
  function _setVeQoda(address veQodaAddress) external;
  
  /// @notice Call upon initialization after deploying `QodaLens` contract
  /// @param qodaLensAddress Address of `QodaLens` deployment
  function _setQodaLens(address qodaLensAddress) external;
  
  /// @notice Set credit facility for specified account
  /// @param account_ account for credit facility adjustment
  /// @param enabled_ If credit facility should be enabled
  /// @param minCollateralRatio_ New minimum collateral ratio value
  /// @param initCollateralRatio_ New initial collateral ratio value
  /// @param creditLimit_ new credit limit in USD, scaled by 1e18
  function _setCreditFacility(address account_, bool enabled_, uint minCollateralRatio_, uint initCollateralRatio_, uint creditLimit_) external;
  
  /// @notice Admin function for adding new Assets. An Asset must be added before it
  /// can be used as collateral or borrowed. Note: We can create functionality for
  /// allowing borrows of a token but not using it as collateral by setting
  /// `collateralFactor` to zero.
  /// @param tokenAddress ERC20 token corresponding to the Asset
  /// @param isYieldBearing True if token bears interest (eg aToken, cToken, mToken, etc)
  /// @param underlying Address of the underlying token
  /// @param oracleFeed Chainlink price feed address
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for premium on risky borrows
  function _addAsset(
                     address tokenAddress,
                     bool isYieldBearing,
                     address underlying,
                     address oracleFeed,
                     uint collateralFactor,
                     uint marketFactor
                     ) external;
  
  /// @notice Admin function for removing an asset
  /// @param token ERC20 token corresponding to the Asset
  function _removeAsset(IERC20 token) external;

  /// @notice Adds a new `FixedRateMarket` contract into the internal mapping of
  /// whitelisted market addresses
  /// @param marketAddress New `FixedRateMarket` contract address
  /// @param protocolFee_ Corresponding protocol fee in basis points
  /// @param minQuoteSize_ Size in PV terms, local currency
  function _addFixedRateMarket(
                               address marketAddress,
                               uint protocolFee_,
                               uint minQuoteSize_
                               ) external;
  
  /// @notice Update the `collateralFactor` for a given `Asset`
  /// @param token ERC20 token corresponding to the Asset
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setCollateralFactor(IERC20 token, uint collateralFactor) external;

  /// @notice Update the `marketFactor` for a given `Asset`
  /// @param token Address of the token corresponding to the Asset
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setMarketFactor(IERC20 token, uint marketFactor) external;

  /// @notice Set the minimum quote size for a particular `FixedRateMarket`
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @param minQuoteSize_ Size in PV terms, local currency
  function _setMinQuoteSize(address marketAddress, uint minQuoteSize_) external;
  
  /// @notice Set the global minimum and initial collateral ratio
  /// @param minCollateralRatio_ New global minimum collateral ratio value
  /// @param initCollateralRatio_ New global initial collateral ratio value
  function _setCollateralRatio(uint minCollateralRatio_, uint initCollateralRatio_) external;
  
  /// @notice Set the global close factor
  /// @param closeFactor_ New close factor value
  function _setCloseFactor(uint closeFactor_) external;

  /// @notice Set the global repayment grace period
  /// @param repaymentGracePeriod_ New repayment grace period
  function _setRepaymentGracePeriod(uint repaymentGracePeriod_) external;

  /// @notice Set the global maturity grace period
  /// @param maturityGracePeriod_ New maturity grace period
  function _setMaturityGracePeriod(uint maturityGracePeriod_) external;
  
  /// @notice Set the global liquidation incetive
  /// @param liquidationIncentive_ New liquidation incentive value
  function _setLiquidationIncentive(uint liquidationIncentive_) external;

  /// @notice Set the global annualized protocol fees for each market in basis points
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @param protocolFee_ New protocol fee value (scaled to 1e4)
  function _setProtocolFee(address marketAddress, uint protocolFee_) external;
  
  /// @notice Set the global threshold in USD for protocol fee transfer
  /// @param thresholdUSD_ New threshold USD value (scaled by 1e6)
  function _setThresholdUSD(uint thresholdUSD_) external;
  
  /// @notice Pause/unpause all markets for admin
  /// @param paused Boolean to indicate if all markets should be paused
  function _setMarketsPaused(bool paused) external;
  
  /// @notice Pause/unpause specified list of contracts for admin
  /// @param contractsAddr List of contract addresses to pause/unpause
  /// @param paused Boolean to indicate if specified contract should be paused
  function _setContractPaused(address[] memory contractsAddr, bool paused) external;
  
  /// @notice Pause/unpause specified contract for admin
  /// @param contractAddr Address of contract to pause/unpause
  /// @param paused Boolean to indicate if specified contract should be paused
  function _setContractPaused(address contractAddr, bool paused) external;
  
  /// @notice Pause/unpause specified list of operations for admin
  /// @param operationIds List of ids for operation to pause/unpause
  /// @param paused Boolean to indicate if specified operation should be paused
  function _setOperationPaused(uint[] memory operationIds, bool paused) external;
  
  /// @notice Pause/unpause specified operation for admin
  /// @param operationId Id for operation to pause/unpause
  /// @param paused Boolean to indicate if specified operation should be paused
  function _setOperationPaused(uint operationId, bool paused) external;
  
  /** VIEW FUNCTIONS **/

  function ADMIN_ROLE() external view returns(bytes32);

  function MARKET_ROLE() external view returns(bytes32);

  function MINTER_ROLE() external view returns(bytes32);

  function VETOKEN_ROLE() external view returns(bytes32);
  
  /// @notice Get the address of the `WETH` contract
  function WETH() external view returns(address);
  
  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManager() external view returns(address);

  /// @notice Get the address of the `QPriceOracle` contract
  function qPriceOracle() external view returns(address);

  /// @notice Get the address of the `StakingEmissionsQontroller` contract
  function stakingEmissionsQontroller() external view returns(address);

  /// @notice Get the address of the `TradingEmissionsQontroller` contract
  function tradingEmissionsQontroller() external view returns(address);

  /// @notice Get the address of the `FeeEmissionsQontroller` contract
  function feeEmissionsQontroller() external view returns(address);
  
  /// @notice Get the address of the `LiquidityEmissionsQontroller` contract
  function liquidityEmissionsQontroller() external view returns(address);

  /// @notice Get the address of the `veQoda` contract
  function veQoda() external view returns(address);
  
  /// @notice Get the address of the `QodaLens` contract
  function qodaLens() external view returns(address);

  /// @notice Get the credit limit with associated address, scaled by 1e18
  function creditLimit(address account_) external view returns(uint);
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param token ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(IERC20 token) external view returns(QTypes.Asset memory);

  /// @notice Get all enabled `Asset`s
  /// @return address[] iterable list of enabled `Asset`s
  function allAssets() external view returns(address[] memory);

  /// @notice Gets the `oracleFeed` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return address Address of the oracle feed
  function oracleFeed(IERC20 token) external view returns(address);
  
  /// @notice Gets the `CollateralFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Collateral Factor, scaled by 1e8
  function collateralFactor(IERC20 token) external view returns(uint);

  /// @notice Gets the `MarketFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Market Factor, scaled by 1e8
  function marketFactor(IERC20 token) external view returns(uint);

  /// @notice Gets the `maturities` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint[] array of UNIX timestamps (in seconds) of the maturity dates
  function maturities(IERC20 token) external view returns(uint[] memory);
  
  /// @notice Get the MToken market corresponding to any underlying ERC20
  /// tokenAddress => mTokenAddress
  function underlyingToMToken(IERC20 token) external view returns(address);
  
  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param token ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarkets(IERC20 token, uint maturity) external view returns(address);

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(address marketAddress) external view returns(bool);

  function minQuoteSize(address marketAddress) external view returns(uint);
  
  function minCollateralRatio() external view returns(uint);
  
  function minCollateralRatio(address account) external view returns(uint);
  
  function initCollateralRatio() external view returns(uint);
  
  function initCollateralRatio(address account) external view returns(uint);
  
  function closeFactor() external view returns(uint);

  function repaymentGracePeriod() external view returns(uint);
  
  function maturityGracePeriod() external view returns(uint);
  
  function liquidationIncentive() external view returns(uint);

  /// @notice Annualized protocol fee in basis points, scaled by 1e4
  function protocolFee(address marketAddress) external view returns(uint);

  /// @notice threshold in USD where protocol fee from each market will be transferred into `FeeEmissionsQontroller`
  /// once this amount is reached, scaled by 1e6
  function thresholdUSD() external view returns(uint);
  
  /// @notice Boolean to indicate if all markets are paused
  function marketsPaused() external view returns(bool);
  
  /// @notice Boolean to indicate if specified contract address is paused
  function contractPaused(address contractAddr) external view returns(bool);
  
  /// @notice Boolean to indicate if specified operation is paused
  function operationPaused(uint operationId) external view returns(bool);
  
  /// @notice Check if given combination of contract address and operation should be allowed
  function isPaused(address contractAddr, uint operationId) external view returns(bool);
  
  /// @notice 2**256 - 1
  function UINT_MAX() external pure returns(uint);
  
  /// @notice Generic mantissa corresponding to ETH decimals
  function MANTISSA_DEFAULT() external pure returns(uint);

  /// @notice Mantissa for USD
  function MANTISSA_USD() external pure returns(uint);
  
  /// @notice Mantissa for collateral ratio
  function MANTISSA_COLLATERAL_RATIO() external pure returns(uint);

  /// @notice `assetFactor` and `marketFactor` have up to 8 decimal places precision
  function MANTISSA_FACTORS() external pure returns(uint);

  /// @notice Basis points have 4 decimal place precision
  function MANTISSA_BPS() external pure returns(uint);

  /// @notice Staked Qoda has 6 decimal place precision
  function MANTISSA_STAKING() external pure returns(uint);
  
  /// @notice `collateralFactor` cannot be above 1.0
  function MAX_COLLATERAL_FACTOR() external pure returns(uint);

  /// @notice `marketFactor` cannot be above 1.0
  function MAX_MARKET_FACTOR() external pure returns(uint);

  /// @notice version number of this contract, will be bumped upon contractual change
  function VERSION_NUMBER() external pure returns(string memory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libraries/QTypes.sol";
import "../libraries/QTypesPeripheral.sol";
import "./IFixedRateMarket.sol";

interface IQodaLens {

  /// @notice Gets the first N `Quote`s for a given `FixedRateMarket` and
  /// `side`, filtering for only if the quoter has the requisite hypothetical
  /// collateral ratio and allowance/balance for borrow and lend `Quote`s,
  /// respectively.
  /// For convenience, this function also returns the associated current
  /// collateral ratio and underlying balance of the publisher for the `Quote`.
  /// @param market Market to query
  /// @param side 0 for borrow `Quote`s, 1 for lend `Quote`s
  /// @param n Maximum number of `Quote`s to return
  /// @return QTypes.Quote[], uint[] `collateralRatio`s, uint[] underlying balances
  function takeNFilteredQuotes(
                               IFixedRateMarket market,
                               uint8 side,
                               uint n
                               ) external view returns(QTypes.Quote[] memory, uint[] memory, uint[] memory);
  
  /// @notice Gets the first N `Quote`s for a given `FixedRateMarket` and `side`.
  /// For convenience, this function also returns the associated current
  /// collateral ratio and underlying balance of the publisher for the `Quote`.
  /// @param market Market to query
  /// @param side 0 for borrow `Quote`s, 1 for lend `Quote`s
  /// @param n Maximum number of `Quote`s to return
  /// @return QTypes.Quote[], uint[] `collateralRatio`s, uint[] underlying balances
  function takeNQuotes(
                       IFixedRateMarket market,
                       uint8 side,
                       uint n
                       ) external view returns(QTypes.Quote[] memory, uint[] memory, uint[] memory);
  
  /// @notice Gets all open quotes from all unexpired market for a given account
  /// @param account Account for getting all open quotes
  /// @return QTypesPeripheral.AccountQuote[] Related quotes for given account
  function takeAccountQuotes(address account) external view returns (QTypesPeripheral.AccountQuote[] memory);

  /// @notice Convenience function to convert an array of `Quote` ids to
  /// an array of the underlying `Quote` structs
  /// @param market Market to query
  /// @param side 0 for borrow `Quote`s, 1 for lend `Quote`s
  /// @param quoteIds array of `Quote` ids to query
  /// @return QTypes.Quote[] Ordered array of `Quote`s corresponding to `Quote` ids
  function quoteIdsToQuotes(
                            IFixedRateMarket market,
                            uint8 side,
                            uint64[] calldata quoteIds
                            ) external view returns(QTypes.Quote[] memory);

  /// @notice Get the weighted average estimated APR for a requested market
  /// order `size`. The estimated APR is the weighted average of the first N
  /// `Quote`s APR until the full `size` is satisfied. The `size` can be in
  /// either PV terms or FV terms. This function also returns the confirmed
  /// filled amount in the case that the entire list of `Quote`s in the
  /// orderbook is smaller than the requested size. It returns default (0,0) if
  /// the orderbook is currently empty.
  /// @param market Market to query
  /// @param account Account to view estimated APR from
  /// @param size Size requested by the user. Can be in either PV or FV terms
  /// @param side 0 for borrow `Quote`s, 1 for lend `Quote`s
  /// @param quoteType 0 for PV, 1 for FV
  /// @return uint Estimated APR, scaled by 1e4, uint Confirmed filled size
  function getEstimatedAPR(
                           IFixedRateMarket market,
                           address account,
                           uint size,
                           uint8 side,
                           uint8 quoteType
                           ) external view returns(uint, uint);
  
  /// @notice Get an account's maximum available collateral user can withdraw in specified asset.
  /// For example, what is the maximum amount of GLMR that an account can withdraw
  /// while ensuring their account health continues to be acceptable?
  /// Note: This function will return withdrawable amount that user has indeed collateralized, not amount that user can borrow
  /// Note: User can only withdraw up to `initCollateralRatio` for their own protection against instant liquidations
  /// Note: Design decision: asset-enabled check not done as collateral can be disabled after
  /// @param account User account
  /// @param withdrawToken Currency of collateral to withdraw
  /// @return uint Maximum available collateral user can withdraw in specified asset
  function hypotheticalMaxWithdraw(address account, address withdrawToken) external view returns (uint);
  
  /// @notice Get an account's maximum available borrow amount in a specific FixedRateMarket.
  /// For example, what is the maximum amount of GLMRJUL22 that an account can borrow
  /// while ensuring their account health continues to be acceptable?
  /// Note: This function will return 0 if market to borrow is disabled
  /// Note: This function will return creditLimit() if maximum amount allowed for one market exceeds creditLimit()
  /// Note: User can only borrow up to `initCollateralRatio` for their own protection against instant liquidations
  /// @param account User account
  /// @param borrowMarket Address of the `FixedRateMarket` market to borrow
  /// @return uint Maximum available amount user can borrow (in FV) without breaching `initCollateralRatio`
  function hypotheticalMaxBorrowFV(address account, IFixedRateMarket borrowMarket) external view returns (uint);
  
  /// @notice Get an account's maximum value user can lend in specified market when protocol fee is factored in.
  /// @param account User account
  /// @param lendMarket Address of the `FixedRateMarket` market to lend
  /// @return uint Maximum value user can lend in specified market with protocol fee considered
  function hypotheticalMaxLendPV(address account, IFixedRateMarket lendMarket) external view returns (uint);
  
  /// @notice Get an account's minimum collateral to further deposit if user wants to borrow specified amount in a certain market.
  /// For example, what is the minimum amount of USDC to deposit so that an account can borrow 100 DEV token from qDEVJUL22
  /// while ensuring their account health continues to be acceptable?
  /// @param account User account
  /// @param collateralToken Currency to collateralize in
  /// @param borrowMarket Address of the `FixedRateMarket` market to borrow
  /// @param borrowAmount Amount to borrow in local ccy
  /// @return uint Minimum collateral required to further deposit
  function minimumCollateralRequired(
                                     address account,
                                     IERC20 collateralToken,
                                     IFixedRateMarket borrowMarket,
                                     uint borrowAmount
                                     ) external view returns (uint);
  
  function getAllMarketsByAsset(IERC20 token) external view returns (IFixedRateMarket[] memory);
      
  function totalLoansTradedByMarket(IFixedRateMarket market) external view returns (uint);
  function totalRedeemedLendsByMarket(IFixedRateMarket market) external view returns (uint);
  function totalUnredeemedLendsByMarket(IFixedRateMarket market) external view returns (uint);
  function totalRepaidBorrowsByMarket(IFixedRateMarket market) external view returns (uint);
  function totalUnrepaidBorrowsByMarket(IFixedRateMarket market) external view returns (uint);
  
  function totalLoansTradedByAsset(IERC20 token) external view returns (uint);
  function totalRedeemedLendsByAsset(IERC20 token) external view returns (uint);
  function totalUnredeemedLendsByAsset(IERC20 token) external view returns (uint);
  function totalRepaidBorrowsByAsset(IERC20 token) external view returns (uint);
  function totalUnrepaidBorrowsByAsset(IERC20 token) external view returns (uint);
  
  function totalLoansTradedInUSD() external view returns (uint);
  function totalRedeemedLendsInUSD() external view returns (uint);
  function totalUnredeemedLendsInUSD() external view returns (uint);
  function totalRepaidBorrowsInUSD() external view returns (uint);
  function totalUnrepaidBorrowsInUSD() external view returns (uint);
    
  /// @notice Get the address of the `QollateralManager` contract
  /// @return address Address of `QollateralManager` contract
  function qollateralManager() external view returns(address);
  
  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);
  
  /// @notice Get the address of the `QPriceOracle` contract
  /// @return address Address of `QPriceOracle` contract
  function qPriceOracle() external view returns(address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVeQoda is IERC20Upgradeable {

  /** EVENTS **/
  
  /// @notice Emitted when user stakes underlying QODA
  event Stake(address indexed account, uint amount);

  /// @notice Emitted when user unstakes underlying QODA
  event Unstake(address indexed account, uint amount);

  /// @notice Emitted when user claims veToken
  event Claim(address indexed account, uint amount);

  /** USER INTERFACE **/
  
  /// @notice Stake underlying into contract
  /// @param amount Amount of underlying to stake
  function stake(uint256 amount) external;
  
  /// @notice Unstake underlying tokens
  /// NOTE: You will lose ALL your veToken if you unstake ANY amount of underlying tokens
  /// @param amount Amount of underlying tokens to unstake
  function unstake(uint amount) external;

  /// @notice Claims accumulated veToken
  function claimVeToken() external;

  /// @notice Claims accumulated veToken on behalf of an account
  function claimVeToken(address account) external;
  
  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QAdmin`
  /// @return address
  function qAdmin() external view returns(address);
  
  /// @notice checks whether user has underlying staked
  /// @param account The user address to check
  /// @return true if the user has underlying in stake, false otherwise
  function hasStaked(address account) external view returns (bool);
  
  /// @notice Calculate the amount of veToken that can be claimed by user
  /// @param account Address to check
  /// @return uint Amount of veToken that can be claimed by user
  function claimableVeToken(address account) external view returns(uint);
  
  /// @notice Returns the underlying amount of underlying staked by the user
  /// @param account User address to check
  /// @return uint Amount of staked underlying underlying
  function getStakedAmount(address account) external view returns(uint);

  function qodaERC20() external view returns(address);

  function stakingEmissionsQontroller() external view returns(address);

  function feeEmissionsQontroller() external view returns(address);

  function veTokenPerSec() external view returns(uint);

  function maxVeToken() external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library CustomErrors {
  
  error QA_OnlyAdmin();
  
  error QM_OnlyAdmin();
  
  error FRM_OnlyAdmin();
  
  error SEQ_OnlyAdmin();
  
  error LEQ_OnlyAdmin();
  
  error SOS_OnlyAdmin();
  
  error STS_OnlyAdmin();
  
  error TV_OnlyAdmin();

  error QPO_OnlyAdmin();

  error FEQ_OnlyMarket();
  
  error QA_OnlyMarket();
  
  error QM_OnlyMarket();
  
  error QUM_OnlyMarket();
  
  error QTK_OnlyMarket();
  
  error TEQ_OnlyMarket();
  
  error LEQ_OnlyMarket();
  
  error SOS_OnlyMarket();
  
  error STS_OnlyMarket();
  
  error SS_OnlyMarket();
  
  error QE_OnlyMinter();
  
  error FEQ_OnlyVeToken();
  
  error QA_OnlyVeToken();
  
  error SEQ_OnlyVeToken();
  
  error FRM_OnlyQToken();
  
  error QA_AssetExist();

  error QA_AssetNotExist();

  error QA_AssetNotEnabled();

  error QA_AssetNotSupported();
  
  error QM_AssetNotSupported();
  
  error QPO_AssetNotSupported();

  error QA_MarketExist();
  
  error QA_MarketNotExist();

  error QA_InvalidCollateralFactor();

  error QA_InvalidMarketFactor();

  error QA_InvalidAddress();
  
  error QA_MinCollateralRatioNotGreaterThanInit();

  error QA_OverThreshold(uint actual, uint expected);

  error QA_UnderThreshold(uint actual, uint expected);

  error QM_OperationPaused(uint operationId);
  
  error FRM_OperationPaused(uint operationId);
  
  error QUM_OperationPaused(uint operationId);
  
  error QTK_OperationPaused(uint operationId);
  
  error SEQ_OperationPaused(uint operationId);
  
  error TEQ_OperationPaused(uint operationId);
  
  error LEQ_OperationPaused(uint operationId);
  
  error FEQ_OperationPaused(uint operationId);
  
  error VQ_OperationPaused(uint operationId);
  
  error FRM_ReentrancyDetected();
  
  error QTK_ReentrancyDetected();
  
  error QM_ReentrancyDetected();
  
  error FRM_AmountZero();
  
  error SEQ_AmountZero();
  
  error QM_ZeroTransferAmount();
  
  error QM_ZeroDepositAmount();
  
  error SEQ_ZeroDepositAmount();
  
  error QM_ZeroWithdrawAmount();
  
  error QTK_ZeroRedeemAmount();
  
  error TEQ_ZeroRewardAmount();
  
  error VQ_ZeroStakeAmount();
  
  error VQ_ZeroUnstakeAmount();
  
  error FRM_InsufficientAllowance();
  
  error QUM_InsufficientAllowance();
  
  error FRM_InsufficientBalance();
  
  error QUM_InsufficientBalance();
  
  error VQ_InsufficientBalance();
  
  error TT_InsufficientBalance();
  
  error QM_InsufficientCollateralBalance();
  
  error TT_InsufficientEth();
  
  error QM_WithdrawMoreThanCollateral();
  
  error QM_MTokenUnsupported();
  
  error QTK_CannotRedeemEarly();
  
  error FRM_NotLiquidatable();
  
  error QM_NotEnoughCollateral();
  
  error FRM_NotEnoughCollateral();
  
  error QTK_BorrowsMoreThanLends();
  
  error FRM_AmountLessThanProtocolFee();
  
  error FRM_MarketExpired();
  
  error FRM_InvalidSide();
  
  error QUM_InvalidSide();
  
  error QL_InvalidSide();
  
  error QUM_InvalidQuoteType();
  
  error QL_InvalidQuoteType();
  
  error FRM_InvalidAPR();
  
  error FRM_InvalidCounterparty();
  
  error FRM_InvalidMaturity();
  
  error QM_InvalidWithdrawal(uint actual, uint expected);
  
  error QUM_InvalidFillAmount();
  
  error QUM_InvalidCashflowSize();
  
  error INT_InvalidTimeInterval();
  
  error QTK_AmountExceedsRedeemable();
  
  error QTK_AmountExceedsBorrows();
  
  error FRM_MaxBorrowExceeded();
  
  error QUM_MaxBorrowExceeded();
  
  error QL_MaxBorrowExceeded();
  
  error QUM_QuoteNotFound();
  
  error QUM_QuoteSizeTooSmall();
  
  error QPO_ExchangeRateOutOfBound();
  
  error SEQ_LengthMismatch();
  
  error TEQ_LengthMismatch();
  
  error SEQ_InvokeMoreThanOnce();
  
  error LEQ_InvokeMoreThanOnce();
  
  error VQ_TransferDisabled();
  
  error QM_UnsuccessfulEthTransfer();
  
  error FRM_UnsuccessfulEthTransfer();
  
  error MT_UnsuccessfulEthTransfer();
  
  error TT_UnsuccessfulEthTransfer();
  
  error UTL_UnsuccessfulEthTransfer();
  
  error FRM_EthOperationNotPermitted();
  
  error QTK_EthOperationNotPermitted();
  
  error LEQ_ContractInitializationProblem();
  
  error FEQ_ContractInitializationProblem();
  
  error FEQ_Unauthorized();
  
  error QUM_Unauthorized();

  error QPO_Already_Set();
  
  error QPO_DIA_Key_Not_Found();
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if an asset is defined, false otherwise
  /// @member isYieldBearing True if token bears interest (eg aToken, cToken, mToken, etc)
  /// @member underlying Address of the underlying token
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member marketFactor 0.0 1.0 for premium on risky borrows
  /// @member maturities Iterable storage for all enabled maturities
  struct Asset {
    bool isEnabled;
    bool isYieldBearing;
    address underlying;
    address oracleFeed;
    uint collateralFactor;
    uint marketFactor;
    uint[] maturities;
  }
  
  /// @notice Contains all the fields of a created Quote
  /// @param id ID of the quote
  /// @param next Next quote in the list
  /// @param prev Previous quote in the list
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param filled Amount quote has got filled partially 
  struct Quote {
    uint64 id;
    uint64 next;
    uint64 prev;
    address quoter;
    uint8 quoteType;
    uint64 APR;
    uint cashflow;
    uint filled;
  }
  
  /// @notice Contains all the configurations customizable to an address
  /// @member enabled If config for an address is enabled. When enabled is false, credit limit is infinite even if value is 0
  /// @member minCollateralRatio If collateral ratio falls below `_minCollateralRatio`, it is subject to liquidation. Scaled by 1e8
  /// @member initCollateralRatio When initially taking a loan, collateral ratio must be higher than this. `initCollateralRatio` should always be higher than `minCollateralRatio`. Scaled by 1e8
  /// @member creditLimit Allowed limit in virtual USD for each address to do uncollateralized borrow, scaled by 1e18
  struct CreditFacility {
    bool enabled;
    uint minCollateralRatio;
    uint initCollateralRatio;
    uint creditLimit;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypesPeripheral {
  
  /// @notice Contains all the fields (market and side included) of a created Quote
  /// @param market Address of the market
  /// @param id ID of the quote
  /// @param side 0 for borrow quote, 1 for lend quote
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param filled Amount quote has got filled partially 
  struct AccountQuote {
    address market;
    uint64 id;
    uint8 side;
    address quoter;
    uint8 quoteType;
    uint64 APR;
    uint cashflow;
    uint filled;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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