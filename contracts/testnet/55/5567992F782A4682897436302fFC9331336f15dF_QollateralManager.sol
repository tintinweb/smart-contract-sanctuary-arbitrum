//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./interfaces/IQAdmin.sol";
import "./interfaces/IQPriceOracle.sol";
import "./interfaces/IQollateralManager.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/moonwell/MTokenInterfaces.sol";
import "./libraries/QTypes.sol";

contract QollateralManager is Initializable, ReentrancyGuard, IQollateralManager {

  using SafeERC20 for IERC20;
  
  /// @notice Contract storing all global Qoda parameters
  IQAdmin private _qAdmin;

  /// @notice Contract for price oracle feeds
  IQPriceOracle private _qPriceOracle;

  /// @notice 0x0 null address for convenience
  address constant NULL = address(0);

  /// @notice Native Token (WETH equivalent) for convenience
  /// @custom:deprecated to be replaced by _qAdmin.WETH() 
  address constant _NATIVE_TOKEN_ADDRESS = 0x0000000000000000000000000000000000000802;
  
  /// @notice Use this for quick lookups of collateral balances by asset
  /// account => tokenAddress => balanceLocal
  mapping(address => mapping(IERC20 => uint)) private _collateralBalances;

  /// @notice Iterable list of all collateral addresses which an account has nonzero balance.
  /// Use this when calculating `collateralValue` for liquidity considerations
  /// account => tokenAddresses[]
  mapping(address => IERC20[]) private _iterableCollateralAddresses;
  
  /// @notice Iterable list of all markets which an account has participated.
  /// Use this when calculating `totalBorrowValue` for liquidity considerations
  /// account => fixedRateMarketAddresses[]
  mapping(address => IFixedRateMarket[]) private _iterableAccountMarkets;

  /// @notice Non-iterable list of collateral which an account has nonzero balance.
  /// Use this for quick lookups
  /// account => tokenAddress => bool;
  mapping(address => mapping(IERC20 => bool)) private _accountCollateral;

  /// @notice Non-iterable list of markets which an account has participated.
  /// Use this for quick lookups
  /// account => fixedRateMarketAddress => bool;
  mapping(address => mapping(IFixedRateMarket => bool)) private _accountMarkets;
  
  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress_ Address of the `QAdmin` contract
  /// @param qPriceOracleAddress_ Address of the `QPriceOracle` contract
  function initialize(address qAdminAddress_, address qPriceOracleAddress_) external initializer {
    _qAdmin = IQAdmin(qAdminAddress_);
    _qPriceOracle = IQPriceOracle(qPriceOracleAddress_);
  }

  /// @notice Needed for receiving native token when redeeming from Moonwell
  receive() external payable {}

  modifier onlyAdmin() {
    require(_qAdmin.hasRole(_qAdmin.ADMIN_ROLE(), msg.sender), "QM0 only admin");
    _;
  }

  modifier onlyMarket() {
    require(_qAdmin.hasRole(_qAdmin.MARKET_ROLE(), msg.sender), "QM1 only market");
    _;
  }
  
  /** ADMIN/RESTRICTED FUNCTIONS **/

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `borrowValue`. Only the `FixedRateMarket` contract itself may call
  /// this function
  /// @param account User account
  /// @param market Address of the `FixedRateMarket` market
  function _addAccountMarket(address account, IFixedRateMarket market) external onlyMarket {

    // Record that account now has participated in this `FixedRateMarket`
    if(!_accountMarkets[account][market]){
      _accountMarkets[account][market] = true;
      _iterableAccountMarkets[account].push(market);
    }

    /// Emit the event
    emit AddAccountMarket(account, address(market));
  }

  /// @notice Transfer collateral balances from one account to another. Only
  /// `FixedRateMarket` contracts can call this restricted function. This is used
  /// for when a liquidator liquidates an account.
  /// @param token ERC20 token
  /// @param from Sender address
  /// @param to Recipient address
  /// @param amount Amount to transfer
  function _transferCollateral(
                               IERC20 token,
                               address from,
                               address to,
                               uint amount
                               ) external onlyMarket {
    // Amount must be positive
    require(amount > 0, "QM10 transfer amount must be > 0");

    // Check `from` address has enough collateral balance
    require(amount <= _collateralBalances[from][token], "QM2 not enough collateral balance");

    // Transfer the balance to recipient    
    _subtractCollateral(from, token, amount);
    token.safeTransfer(to, amount);

    // Emit the event
    emit TransferCollateral(address(token), from, to, amount);    
  }

  /** USER INTERFACE **/

  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param token ERC20 token
  /// @param amount Amount to deposit (in local ccy)
  /// @return uint New collateral balance
  function depositCollateral(IERC20 token, uint amount) external returns(uint) {
    return _depositCollateral(msg.sender, token, amount);
  }

  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped into MTokens for convenience so users can
  /// automatically earn interest on their collateral.
  /// @param underlying Underlying ERC20 token
  /// @param amount Amount to deposit (in underlying local currency)
  /// @return uint New collateral balance (in MToken balance)
  function depositCollateralWithMTokenWrap(IERC20 underlying, uint amount) external returns(uint) {
    return _depositCollateralWithMTokenWrap(msg.sender, underlying, amount, false);
  }
  
  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped from ETH to WETH.
  /// @return uint New collateral balance (in WETH balance)
  function depositCollateralWithETH() external payable returns(uint) {
    return _depositCollateralWithETH(msg.sender, msg.value);
  } 

  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped from ETH into MTokens for convenience so users can
  /// automatically earn interest on their collateral.
  /// @return uint New collateral balance (in MToken balance)
  function depositCollateralWithMTokenWrapWithETH() external payable returns(uint) {
    return _depositCollateralWithMTokenWrap(msg.sender, IERC20(_qAdmin.WETH()), msg.value, true);
  }
    
  /// @notice Users call this to withdraw collateral
  /// @param token ERC20 token
  /// @param amount Amount to withdraw (in local ccy)
  /// @return uint New collateral balance 
  function withdrawCollateral(IERC20 token, uint amount) external nonReentrant returns(uint) {
    return _withdrawCollateral(msg.sender, token, amount);
  }

  /// @notice Users call this to withdraw mToken collateral, where their
  /// collateral is automatically unwrapped into underlying tokens for
  /// convenience.
  /// @param mTokenAddress Yield-bearing token address
  /// @param amount Amount to withdraw (in mToken local currency)
  /// @return uint New collateral balance (in MToken balance)
  function withdrawCollateralWithMTokenUnwrap(
                                              address mTokenAddress,
                                              uint amount
                                              ) external nonReentrant returns(uint) {
    return _withdrawCollateralWithMTokenUnwrap(msg.sender, mTokenAddress, amount, false);
  }
  
  /// @notice Users call this to withdraw ETH collateral, where their
  /// collateral is automatically unwrapped from WETH for convenience.
  /// @param amount Amount to withdraw (in WETH local currency)
  /// @return uint New collateral balance (in WETH balance)
  function withdrawCollateralWithETH(uint amount) external nonReentrant returns(uint) {
    return _withdrawCollateralWithETH(msg.sender, amount);
  }
    
  /// @notice Users call this to withdraw mToken collateral, where their
  /// collateral is automatically unwrapped into ETH for convenience.
  /// @param amount Amount to withdraw (in WETH local currency)
  /// @return uint New collateral balance (in MToken balance)
  function withdrawCollateralWithMTokenWrapWithETH(uint amount) external nonReentrant returns(uint) {
    IWETH weth = IWETH(_qAdmin.WETH());
    address mTokenAddress = _qAdmin.underlyingToMToken(weth);
    return _withdrawCollateralWithMTokenUnwrap(msg.sender, mTokenAddress, amount, true);
  }
  
  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address){
    return address(_qAdmin);
  }

  /// @notice Get the address of the `QPriceOracle` contract
  /// @return address Address of `QPriceOracle` contract
  function qPriceOracle() external view returns(address){
    return address(_qPriceOracle);
  }

  /// @notice Get all enabled `Asset`s
  /// @return address[] iterable list of enabled `Asset`s
  function allAssets() external view returns(address[] memory) {
    return _qAdmin.allAssets();
  }
  
  /// @notice Gets the `CollateralFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Collateral Factor, scaled by 1e8
  function collateralFactor(IERC20 token) external view returns(uint) {
    return _qAdmin.collateralFactor(token);
  }

  /// @notice Gets the `MarketFactor` associated with a ERC20 token
  /// @param token ERC20 token
  /// @return uint Market Factor, scaled by 1e8
  function marketFactor(IERC20 token) external view returns(uint) {
    return _qAdmin.marketFactor(token);
  }
  
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
                                       ) external view returns(uint){
    return _getHypotheticalCollateralRatio(
                                           account,
                                           hypotheticalToken,
                                           withdrawAmount,
                                           depositAmount,
                                           hypotheticalMarket,
                                           borrowAmount,
                                           lendAmount
                                           );
  }

  /// @notice Return the current collateral ratio for an account.
  /// The collateral ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// If the returned value falls below 1e8, the account can be liquidated
  /// @param account User account
  /// @return uint Collateral ratio
  function collateralRatio(address account) public view returns(uint){
    return _getHypotheticalCollateralRatio(
                                           account,
                                           IERC20(NULL),
                                           0,
                                           0,
                                           IFixedRateMarket(NULL),
                                           0,
                                           0
                                           );
  }

  /// @notice Get the `collateralFactor` weighted value (in USD) of all the
  /// collateral deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD, scaled to 1e18
  function virtualCollateralValue(address account) public view returns(uint){
    return _getHypotheticalCollateralValue(account, IERC20(NULL), 0, 0, true);
  }

  /// @notice Get the `collateralFactor` weighted value (in USD) for the tokens
  /// deposited for an account
  /// @param account Account to query
  /// @param token ERC20 token
  /// @return uint Value of token collateral of account in USD, scaled to 1e18
  function virtualCollateralValueByToken(
                                         address account,
                                         IERC20 token
                                         ) external view returns(uint){
    return _getHypotheticalCollateralValueByToken(account, token, 0, 0, true);
  }

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
                                          ) external view returns(uint){
    return _getHypotheticalBorrowValue(account, hypotheticalMarket, borrowAmount, lendAmount, true);
  }

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function virtualBorrowValue(address account) public view returns(uint){
    return _getHypotheticalBorrowValue(account, IFixedRateMarket(NULL), 0, 0, true);
  }

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param market `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function virtualBorrowValueByMarket(
                                      address account,
                                      IFixedRateMarket market
                                      ) external view returns(uint){
    return _getHypotheticalBorrowValueByMarket(account, market, 0, 0, true);
  }
  
  /// @notice Get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD, scaled to 1e18
  function realCollateralValue(address account) external view returns(uint){
    return _getHypotheticalCollateralValue(account, IERC20(NULL), 0, 0, false);
  }
  
  /// @notice Get the unweighted value (in USD) of the tokens deposited
  /// for an account
  /// @param account Account to query
  /// @param token ERC20 token
  /// @return uint Value of token collateral of account in USD, scaled to 1e18
  function realCollateralValueByToken(
                                      address account,
                                      IERC20 token
                                      ) external view returns(uint){
    return _getHypotheticalCollateralValueByToken(account, token, 0, 0, false);
  }
  
  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function realBorrowValue(address account) external view returns(uint){
    return _getHypotheticalBorrowValue(account, IFixedRateMarket(NULL), 0, 0, false);
  }

  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param market `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function realBorrowValueByMarket(
                                   address account,
                                   IFixedRateMarket market
                                   ) external view returns(uint){
    return _getHypotheticalBorrowValueByMarket(account, market, 0, 0, false);
  }
  
  /// @notice Get an account's maximum available borrow amount in a specific FixedRateMarket.
  /// For example, what is the maximum amount of GLMRJUL22 that an account can borrow
  /// while ensuring their account health continues to be acceptable?
  /// Note: This function will return 0 if market to borrow is disabled
  /// Note: This function will return creditLimit() if maximum amount allowed for one market exceeds creditLimit()
  /// Note: User can only borrow up to `initCollateralRatio` for their own protection against instant liquidations
  /// @param account User account
  /// @param borrowMarket Address of the `FixedRateMarket` market to borrow
  /// @return uint Maximum available amount user can borrow (in FV) without breaching `initCollateralRatio`
  function hypotheticalMaxBorrowFV(address account, IFixedRateMarket borrowMarket) external view returns(uint) {
    IERC20 borrowERC20 = borrowMarket.underlyingToken();
    QTypes.Asset memory asset = _qAdmin.assets(borrowERC20);
    uint currentRatio = collateralRatio(account);
    uint initRatio = _qAdmin.initCollateralRatio(account);
    if (currentRatio <= initRatio) {
      return 0;
    }
    uint creditLimit = _qAdmin.creditLimit(account);
    // initCollateralRatio = virtualCollateralValue / (virtualBorrowValue + virtualMaxBorrowFV) 
    // => virtualMaxBorrowFV = virtualCollateralValue / initCollateralRatio - virtualBorrowValue
    uint virtualCollateral = virtualCollateralValue(account);
    uint virtualBorrow = virtualBorrowValue(account);
    uint virtualUSD = (virtualCollateral * _qAdmin.MANTISSA_COLLATERAL_RATIO() / initRatio) - virtualBorrow;
    if (virtualUSD > creditLimit) {
      // borrow value should not breach credit limit
      virtualUSD = creditLimit;
    }
    uint realUSD = virtualUSD * asset.marketFactor / _qAdmin.MANTISSA_FACTORS();
    uint valueLocal = _qPriceOracle.USDToLocal(borrowERC20, realUSD);
    uint marketLocalLend = borrowMarket.balanceOf(account);
    
    // qToken can also be counted towards borrowable amount    
    return valueLocal + marketLocalLend;
  }
  
  /// @notice Get the minimum collateral ratio. Scaled by 1e8.
  /// @return uint Minimum collateral ratio
  function minCollateralRatio() external view returns(uint){
    return _qAdmin.minCollateralRatio(msg.sender);
  }
  
  /// @notice Get the minimum collateral ratio for a user account. Scaled by 1e8.
  /// @param account User account 
  /// @return uint Minimum collateral ratio
  function minCollateralRatio(address account) external view returns(uint){
    return _qAdmin.minCollateralRatio(account);
  }

  /// @notice Get the initial collateral ratio. Scaled by 1e8
  /// @return uint Initial collateral ratio
  function initCollateralRatio() external view returns(uint){
    return _qAdmin.initCollateralRatio(msg.sender);
  }
  
  /// @notice Get the initial collateral ratio for a user account. Scaled by 1e8
  /// @param account User account 
  /// @return uint Initial collateral ratio
  function initCollateralRatio(address account) external view returns(uint){
    return _qAdmin.initCollateralRatio(account);
  }

  /// @notice Get the close factor. Scaled by 1e8
  /// @return uint Close factor
  function closeFactor() external view returns(uint){
    return _qAdmin.closeFactor();
  }

  /// @notice Get the liquidation incentive. Scaled by 1e8
  /// @return uint Liquidation incentive
  function liquidationIncentive() external view returns(uint){
    return _qAdmin.liquidationIncentive();
  }

  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param account User account  
  /// @param token ERC20 token
  /// @return uint Balance in local
  function collateralBalance(address account, IERC20 token) external view returns(uint){
    return _collateralBalances[account][token];
  }

  /// @notice Get iterable list of collateral addresses which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function iterableCollateralAddresses(address account) external view returns(IERC20[] memory){
    return _iterableCollateralAddresses[account];
  }

  /// @notice Quick lookup of whether an account has a particular collateral
  /// @param account User account
  /// @param token ERC20 token addresses
  /// @return bool True if account has collateralized with given ERC20 token, false otherwise
  function accountCollateral(address account, IERC20 token) external view returns(bool) {
    return _accountCollateral[account][token];
  }
  
  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function iterableAccountMarkets(address account) external view returns(IFixedRateMarket[] memory){
    return _iterableAccountMarkets[account];
  }

  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param account User account
  /// @param market`FixedRateLoanMarket` contract
  /// @return bool True if participated, false otherwise
  function accountMarkets(address account, IFixedRateMarket market) external view returns(bool){
    return _accountMarkets[account][market];
  }

  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD, scaled to 1e18
  function localToUSD(
                      IERC20 token,
                      uint amountLocal
                      ) external view returns(uint){
    return _qPriceOracle.localToUSD(token, amountLocal);
  }

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(
                      IERC20 token,
                      uint valueUSD
                      ) external view returns(uint){
    return _qPriceOracle.USDToLocal(token, valueUSD);
  }
  
  /** INTERNAL FUNCTIONS **/

  /// @notice Return what the collateral ratio for an account would be
  /// with a hypothetical collateral withdraw and/or token borrow.
  /// The collateral ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// If the returned value falls below 1e8, the account can be liquidated
  /// @param account User account
  /// @param hypotheticalToken Currency of hypothetical withdraw / deposit
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param depositAmount Amount of hypothetical deposit in local currency
  /// @param hypotheticalMarket Market of hypothetical borrow / lend
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param lendAmount Amount of hypothetical lend in local ccy
  /// @return uint Hypothetical collateral ratio
  function _getHypotheticalCollateralRatio(
                                           address account,
                                           IERC20 hypotheticalToken,
                                           uint withdrawAmount,
                                           uint depositAmount,
                                           IFixedRateMarket hypotheticalMarket,
                                           uint borrowAmount,
                                           uint lendAmount
                                           ) internal view returns(uint){
    
    // The numerator is the weighted hypothetical collateral value
    uint num = _getHypotheticalCollateralValue(
                                               account,
                                               hypotheticalToken,
                                               withdrawAmount,
                                               depositAmount,
                                               true
                                               );

    // The denominator is the weighted hypothetical borrow value
    uint denom = _getHypotheticalBorrowValue(
                                             account,
                                             hypotheticalMarket,
                                             borrowAmount,
                                             lendAmount,
                                             true
                                             );

    if(denom == 0){
      // Need to handle division by zero if account has no borrows
      return _qAdmin.UINT_MAX();      
    }else{
      // Return the collateral  ratio as a value from 0-1, scaled by 1e8
      return num * _qAdmin.MANTISSA_COLLATERAL_RATIO() / denom;
    }        
  }

  /// @notice Return what the total collateral value for an account would be
  /// with a hypothetical withdraw, with an option for weighted or unweighted value
  /// @param account Account to query
  /// @param hypotheticalToken Currency of hypothetical withdraw / deposit
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param depositAmount Amount of hypothetical deposit in local currency
  /// @param applyCollateralFactor True to get the `collateralFactor` weighted value, false otherwise
  /// @return uint Total value of account in USD, scaled to 1e18
  function _getHypotheticalCollateralValue(
                                           address account,
                                           IERC20 hypotheticalToken,
                                           uint withdrawAmount,
                                           uint depositAmount,
                                           bool applyCollateralFactor
                                           ) internal view returns(uint){
            
    uint totalValueUSD = 0;

    // If user has never deposited collateral in `hypotheticalToken` before, it
    // will not be included in `_iterableCollateralAddresses` by default, so
    // it needs to be handled separately
    uint newTokenOffset = _qAdmin.assets(hypotheticalToken).isEnabled && !_accountCollateral[account][hypotheticalToken] ? 1 : 0;

    for (uint i = 0; i < _iterableCollateralAddresses[account].length + newTokenOffset; i++){

      // Get the token address in i'th slot of `_iterableCollateralAddresses[account]`
      // or else the `hypotheticalToken` if it is not included in `iterableColalteralAddresses`
      IERC20 token = i < _iterableCollateralAddresses[account].length ? _iterableCollateralAddresses[account][i] : hypotheticalToken;

      // Check if token address matches token in target
      if(address(token) == address(hypotheticalToken)){
        // Add value to total adjusted by hypothetical deposit / withdraw amount
        totalValueUSD += _getHypotheticalCollateralValueByToken(
                                                                account,
                                                                hypotheticalToken,
                                                                withdrawAmount,
                                                                depositAmount,
                                                                applyCollateralFactor
                                                                );
      }else{
        // Add value to total without adjustment
        totalValueUSD += _getHypotheticalCollateralValueByToken(
                                                                account,
                                                                token,
                                                                0,
                                                                0,
                                                                applyCollateralFactor
                                                                );
      }
    }
    
    return totalValueUSD;
  }

  /// @notice Return what the collateral value by token for an account would be
  /// with a hypothetical withdraw, with an option for weighted or unweighted value
  /// @param account Account to query
  /// @param token ERC20 token
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param depositAmount Amount of hypothetical deposit in local currency
  /// @param applyCollateralFactor True to get the `collateralFactor` weighted value, false otherwise
  /// @return uint Total value of account in USD, scaled to 1e18
  function _getHypotheticalCollateralValueByToken(
                                                  address account,
                                                  IERC20 token,
                                                  uint withdrawAmount,
                                                  uint depositAmount,
                                                  bool applyCollateralFactor
                                                  ) internal view returns(uint){

    // Withdraw amount must be less than collateral balance
    require(withdrawAmount <= _collateralBalances[account][token], "QM3 withdraw > collateral");
    
    // Get the `Asset` associated to this token
    QTypes.Asset memory asset = _qAdmin.assets(token);

    // Value of collateral in any unsupported `Asset` is zero
    if(!asset.isEnabled){
      return 0;
    }
    
    // Get the local balance of the account for the given `token`
    uint balanceLocal = _collateralBalances[account][token];

    // Adjust by hypothetical withdraw / deposit amount. Guaranteed not to underflow
    balanceLocal = balanceLocal + depositAmount - withdrawAmount;
    
    // Convert the local balance to USD
    uint valueUSD = _qPriceOracle.localToUSD(token, balanceLocal);
    
    if(applyCollateralFactor){
      // Apply the `collateralFactor` to get the discounted value of the asset       
      valueUSD = valueUSD * asset.collateralFactor / _qAdmin.MANTISSA_FACTORS();
    }
    
    return valueUSD;
  }

  /// @notice Return what the total borrow value for an account would be
  /// with a hypothetical borrow, with an option for weighted or unweighted value  
  /// @param account Account to query
  /// @param hypotheticalMarket Market of hypothetical borrow / lend
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param lendAmount Amount of hypothetical lend in local ccy
  /// @param applyMarketFactor True to get the `marketFactor` weighted value, false otherwise
  /// @return uint Borrow value of account in USD, scaled to 1e18
  function _getHypotheticalBorrowValue(
                                       address account,
                                       IFixedRateMarket hypotheticalMarket,
                                       uint borrowAmount,
                                       uint lendAmount,
                                       bool applyMarketFactor
                                       ) internal view returns(uint){
    uint totalValueUSD = 0;
    
    // If user has never entered `hypotheticalMarket` before, it will not be
    // included in `_iterableAccountMarkets` by default, so it needs to be
    // handled separately
    uint newMarketOffset = _qAdmin.isMarketEnabled(address(hypotheticalMarket)) && !_accountMarkets[account][hypotheticalMarket] ? 1 : 0;
    
    for (uint i = 0; i < _iterableAccountMarkets[account].length + newMarketOffset; i++) {
      
      // Get the market address in i'th slot of `_iterableAccountMarkets[account]`
      IFixedRateMarket market = i < _iterableAccountMarkets[account].length ? _iterableAccountMarkets[account][i] : hypotheticalMarket;
      
      // Check if the user is requesting to borrow more in this `Market`
      if(address(market) == address(hypotheticalMarket)){
        // User requesting to borrow / lend in this `Market`, adjust amount accordingly
        totalValueUSD += _getHypotheticalBorrowValueByMarket(
                                                             account,
                                                             hypotheticalMarket,
                                                             borrowAmount,
                                                             lendAmount,
                                                             applyMarketFactor
                                                             );
      }else{
        // User not requesting to borrow more in this `Market`, just get current value
        totalValueUSD += _getHypotheticalBorrowValueByMarket(
                                                             account,   
                                                             market,
                                                             0,
                                                             0,
                                                             applyMarketFactor
                                                             );
      }
    }
    return totalValueUSD;    
  }

  /// @notice Return what the borrow value by `Market` for an account would be
  /// with a hypothetical borrow, with an option for weighted or unweighted value  
  /// @param account Account to query
  /// @param market Market of the hypothetical borrow / lend
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param lendAmount Amount of hypothetical lend in local ccy
  /// @param applyMarketFactor True to get the `marketFactor` weighted value, false otherwise
  /// @return uint Borrow value of account in USD (18 decimal places)
  function _getHypotheticalBorrowValueByMarket(
                                               address account,
                                               IFixedRateMarket market,
                                               uint borrowAmount,
                                               uint lendAmount,
                                               bool applyMarketFactor
                                               ) internal view returns(uint){
    
    // Total `borrowsLocal` should be current borrow plus `borrowAmount`
    uint borrowsLocal = market.accountBorrows(account) + borrowAmount;

    // Total `lendsLocal` should be user's balance of qTokens plus `lendAmount`
    uint lendsLocal = market.balanceOf(account) + lendAmount;
    if(lendsLocal >= borrowsLocal){
      // Default to zero if lends greater than borrows
      return 0;
    }else{
      
      // Get the net amount being borrowed in local
      // Guaranteed not to underflow from the above check
      uint borrowValueLocal = borrowsLocal - lendsLocal;     

      // Convert from local value to value in USD
      IERC20 token = market.underlyingToken();
      QTypes.Asset memory asset = _qAdmin.assets(token);
      uint borrowValueUSD = _qPriceOracle.localToUSD(token, borrowValueLocal);

      if(applyMarketFactor){
        // Apply the `marketFactor` to get the risk premium value of the borrow
        borrowValueUSD = borrowValueUSD * _qAdmin.MANTISSA_FACTORS() / asset.marketFactor;
      }
      
      return borrowValueUSD;
    }
  }

  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param account Address of user
  /// @param token ERC20 token
  /// @param amount Amount to deposit (in local ccy)
  /// @return uint New collateral balance
  function _depositCollateral(address account, IERC20 token, uint amount) internal returns(uint) {
    // Amount must be positive
    require(amount > 0, "QM9 deposit amount must be > 0");
    
    // Transfer the collateral from the account to this contract
    uint balanceBefore = token.balanceOf(address(this));
    token.safeTransferFrom(account, address(this), amount);
    uint balanceAfter = token.balanceOf(address(this));

    // Get more accurate amount of user deposit
    uint actualDeposit = balanceAfter - balanceBefore;    
    
    // Update internal account collateral balance mappings
    _addCollateral(account, token, actualDeposit);
        
    // Return the account's updated collateral balance for this token
    return _collateralBalances[account][token];
  }

  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped into MTokens for convenience so users can
  /// automatically earn interest on their collateral.
  /// @param account Address of the user
  /// @param underlying Underlying ERC20 token
  /// @param amount Amount to deposit (in underlying local currency)
  /// @param isPaidInETH Is amount being paid in ETH
  /// @return uint New collateral balance (in MToken balance)
  function _depositCollateralWithMTokenWrap(
                                            address account,
                                            IERC20 underlying,
                                            uint amount,
                                            bool isPaidInETH
                                            ) internal returns(uint) {
    // Amount must be positive
    require(amount > 0, "QM9 deposit amount must be > 0");

    // Get the address of the corresponding MToken
    address mTokenAddress = _qAdmin.underlyingToMToken(underlying);
    
    // Check that the MToken asset has been enabled as collateral
    require(mTokenAddress != address(0), "QM4 MToken unsupported");
      
    // Get accurate amount of user deposit
    uint actualDepositUnderlying = msg.value;
      
    if (!isPaidInETH) {
      uint balanceBeforeUnderlying = underlying.balanceOf(address(this));
        
      // Transfer the underlying collateral from the account to this contract
      underlying.safeTransferFrom(account, address(this), amount);
        
      // Update user deposit balance for ERC20
      actualDepositUnderlying = underlying.balanceOf(address(this)) - balanceBeforeUnderlying;
    }
    
    if (address(underlying) == _qAdmin.WETH()) {
      // If ERC20 is sent instead of native token, unwrap it first before mint 
      // operation can be called
      if (!isPaidInETH) {
          
        IWETH weth = IWETH(_qAdmin.WETH());
        weth.withdraw(actualDepositUnderlying);
          
      }
        
      // Hardcode special logic for native token ERC20
      // Moonwell uses the Compound-style transferring of native token
      // so we must follow a different interface
      MGlimmerInterface mToken = MGlimmerInterface(mTokenAddress);

      // Forward user collateral to MToken
      uint balanceBeforeMToken = mToken.balanceOf(address(this));
      mToken.mint{value: actualDepositUnderlying}();

      // Get accurate amount of MToken minted
      uint actualDepositMToken = mToken.balanceOf(address(this)) - balanceBeforeMToken;

      // Update internal account collateral balance mappings
      _addCollateral(account, mToken, actualDepositMToken);

      return _collateralBalances[account][mToken];
      
    } else {
      // Make underlying token approval
      // NOTE: This "approve" call should be safe as it only approves the bare
      // minimum transferred, but in general be careful of attacks here. We are
      // relying on the above "require" check that `mTokenAddress` is a safe
      // address, so we should make sure that only admin is able to add
      // `mTokenAddress` as a whitelisted address or else an attacker can
      // potentially drain funds
      underlying.approve(mTokenAddress, actualDepositUnderlying);
      
      // Generic logic for all other ERC20 tokens using
      // ERC20 transfer function
      MErc20Interface mToken = MErc20Interface(mTokenAddress);

      // Forward user collateral to MToken
      uint balanceBeforeMToken = mToken.balanceOf(address(this));
      mToken.mint(actualDepositUnderlying);

      // Get accurate amount of mTokens minted
      uint actualDepositMToken = mToken.balanceOf(address(this)) - balanceBeforeMToken;

      // Update internal account collateral balance mappings
      _addCollateral(account, mToken, actualDepositMToken);

      return _collateralBalances[account][mToken];      
    }
    
  }
  
  /// @notice Users call this to deposit collateral to fund their borrows, where their
  /// collateral is automatically wrapped from ETH to WETH.
  /// @param account Address of the user
  /// @param amount Amount to deposit (in WETH local currency)
  /// @return uint New collateral balance (in WETH balance)
  function _depositCollateralWithETH(address account, uint amount) internal returns(uint) {
    IWETH weth = IWETH(_qAdmin.WETH());
    
    // Wrap ETH into WETH
    weth.deposit{ value: amount }();

    // Update internal account collateral balance mappings
    _addCollateral(account, weth, amount);

    // Return the account's updated collateral balance for this token
    return _collateralBalances[account][weth];
  }
    
  // User sends 10 ETH --> wrap it into METH and deposit
  
  /// @notice Users call this to withdraw collateral
  /// @param account Address of user
  /// @param token ERC20 token
  /// @param amount Amount to withdraw (in local ccy)
  /// @return uint New collateral balance 
  function _withdrawCollateral(address account, IERC20 token, uint amount) internal returns(uint) {
    
    // Amount must be positive
    require(amount > 0, "QM5 withdraw amount must be > 0");
    
    // Get the hypothetical collateral ratio after withdrawal
    uint collateralRatio_ = _getHypotheticalCollateralRatio(
                                                            account,
                                                            token,
                                                            amount,
                                                            0,
                                                            IFixedRateMarket(NULL),
                                                            0,
                                                            0
                                                            );

    // Check that the `collateralRatio` after withdrawal is still healthy.
    // User is only allowed to withdraw up to `_initCollateralRatio`, not
    // `_minCollateralRatio`, for their own protection against instant liquidations.
    require(collateralRatio_ >= _qAdmin.initCollateralRatio(account), "QM6 invalid withdraw amount");

    // Update internal account collateral balance mappings
    _subtractCollateral(account, token, amount);

    // Send collateral from the protocol to the account
    token.safeTransfer(account, amount);

    // Emit the event
    emit WithdrawCollateral(account, address(token), amount);

    // Return the account's updated collateral balance for this token
    return _collateralBalances[account][token];
  }

  /// @notice Users call this to withdraw mToken collateral, where their
  /// collateral is automatically unwrapped into underlying tokens for
  /// convenience.
  /// @param account Address of the user
  /// @param mTokenAddress Yield-bearing token address
  /// @param amount Amount to withdraw (in mToken local currency)
  /// @param isPaidInETH Is amount being paid in ETH
  /// @return uint New collateral balance (in MToken balance)
  function _withdrawCollateralWithMTokenUnwrap(
                                               address account,
                                               address mTokenAddress,
                                               uint amount,
                                               bool isPaidInETH
                                               ) internal returns(uint) {
    // Amount must be positive
    require(amount > 0, "QM5 withdraw amount must be > 0");
    
    // Get the corresponding underlying
    address underlyingAddress = _qAdmin.assets(IERC20(mTokenAddress)).underlying;
    IERC20 underlying = IERC20(underlyingAddress);
    uint actualAmountUnderlying = 0;
    
    if (underlyingAddress == _qAdmin.WETH()) {
      // Hardcode special logic for native token ERC20
      // Moonwell uses the Compound-style transferring of native token
      // so we must follow a different interface
      MGlimmerInterface mToken = MGlimmerInterface(mTokenAddress);

      // Redeem mTokens for underlying and return it to user
      uint balanceBeforeNative = address(this).balance; 
      mToken.redeem(amount);
      
      // Get accurate amount of native token redeemed
      actualAmountUnderlying = address(this).balance - balanceBeforeNative;
      
      // Update internal account collateral balance mappings
      _subtractCollateral(account, mToken, amount);
      
    } else {
      // Generic logic for all other ERC20 tokens using
      // ERC20 transfer function
      MErc20Interface mToken = MErc20Interface(mTokenAddress);

      // Redeem mTokens for underlying and return it to user
      uint balanceBeforeUnderlying = underlying.balanceOf(address(this));
      mToken.redeem(amount);
      
      // Get accurate amount of underlying redeemed
      actualAmountUnderlying = underlying.balanceOf(address(this)) - balanceBeforeUnderlying;

      // Update internal account collateral balance mappings
      _subtractCollateral(account, mToken, amount);
      
    }
      
    if (isPaidInETH) {
      // Underlying address must be WETH if withdrawal is to be paid in ETH
      // So just sent native token to user directly
      (bool success,) = msg.sender.call{ value: actualAmountUnderlying }("");
      require(success, "QM11 unsuccessful ETH transfer");
      
    } else {
      // If underlying is WETH but withdrawal is not paid in ETH
      // Needs to wrap native token before sending to user
      if (underlyingAddress == _qAdmin.WETH()) {
          
        IWETH weth = IWETH(_qAdmin.WETH());
        weth.deposit{ value: actualAmountUnderlying }();
        
      }
      
      // Send underlying collateral from the protocol to the account
      underlying.safeTransfer(account, actualAmountUnderlying);
      
    }

    // Emit the event
    emit WithdrawCollateral(account, mTokenAddress, amount);
    
    return _collateralBalances[account][IERC20(mTokenAddress)];
  }

  /// @notice Users call this to withdraw ETH collateral, where their
  /// collateral is automatically unwrapped from WETH for convenience.
  /// @param account Address of the user
  /// @param amount Amount to withdraw (in currency of WETH)
  /// @return uint New collateral balance (in WETH balance)
  function _withdrawCollateralWithETH(address account, uint amount) internal returns(uint) {
    IWETH weth = IWETH(_qAdmin.WETH());
    
    // Amount must be positive
    require(amount > 0, "QM5 withdraw amount must be > 0");
    
    // Get the hypothetical collateral ratio after withdrawal
    uint collateralRatio_ = _getHypotheticalCollateralRatio(
                                                            account,
                                                            weth,
                                                            amount,
                                                            0,
                                                            IFixedRateMarket(NULL),
                                                            0,
                                                            0
                                                            );

    // Check that the `collateralRatio` after withdrawal is still healthy.
    // User is only allowed to withdraw up to `_initCollateralRatio`, not
    // `_minCollateralRatio`, for their own protection against instant liquidations.
    require(collateralRatio_ >= _qAdmin.initCollateralRatio(account), "QM6 invalid withdraw amount");

    // Update internal account collateral balance mappings
    _subtractCollateral(account, weth, amount);

    // Unwrap WETH
    weth.withdraw(amount);
    
    // Send collateral from the protocol to the account
    (bool success,) = account.call{value: amount}("");
    require(success, "QM11 unsuccessful ETH transfer");

    // Emit the event
    emit WithdrawCollateral(account, address(0), amount);

    // Return the account's updated collateral balance for this token
    return _collateralBalances[account][weth];
  }
  
  /// @notice Add to internal account collateral balance and related mappings
  /// @param account User account
  /// @param token Currency which the collateral will be denominated in
  /// @param amount Amount to add
  function _addCollateral(address account, IERC20 token, uint amount) internal{

    // Get the associated `Asset` to the token address
    QTypes.Asset memory asset = _qAdmin.assets(token);

    // Only enabled assets are supported as collateral
    require(asset.isEnabled, "QM7 asset unsupported");

    // Record that sender now has collateral deposited in this currency
    // This should only be updated once per account when initially depositing
    // collateral in a new currency to ensure that the `_accountCollateral` mapping
    // remains unique
    if(!_accountCollateral[account][token]){
      _iterableCollateralAddresses[account].push(token);
      _accountCollateral[account][token] = true;
    }

    // Record the increase in collateral balance for the account
    _collateralBalances[account][token] += amount;

    // Emit the event
    emit DepositCollateral(account, address(token), amount);
  }

  /// @notice Subtract from internal account collateral balance and related mappings
  /// @param account User account
  /// @param token Currency which the collateral will be denominated in
  /// @param amount Amount to subtract
  function _subtractCollateral(address account, IERC20 token, uint amount) internal{

    // Check that user has enough collateral to be subtracted
    require(_collateralBalances[account][token] >= amount, "QM8 not enough collateral");
    
    // Record the decrease in collateral balance for the account
    _collateralBalances[account][token] -= amount;
  }

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/QTypes.sol";

interface IFixedRateMarket is IERC20Upgradeable, IERC20MetadataUpgradeable {
  
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
  
  /// @notice Emitted when an account redeems their qTokens
  event RedeemQTokens(address indexed account, uint amount);
    
  /// @notice Emitted when setting `_quoteManager`
  event SetQuoteManager(address quoteManagerAddress);


  /** ADMIN FUNCTIONS **/
  
  /// @notice Call upon initialization after deploying `QuoteManager` contract
  /// @param quoteManagerAddress Address of `QuoteManager` deployment
  function _setQuoteManager(address quoteManagerAddress) external;
  
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
  
  /// @notice This function allows net lenders to redeem qTokens for the
  /// underlying token. Redemptions may only be permitted after loan maturity
  /// plus `_maturityGracePeriod`. The public interface redeems specified amount
  /// of qToken from existing balance.
  /// @param amount Amount of qTokens to redeem
  /// @return uint Amount of qTokens redeemed
  function redeemQTokensByRatio(uint amount) external returns(uint);

  /// @notice This function allows net lenders to redeem qTokens for the
  /// underlying token. Redemptions may only be permitted after loan maturity
  /// plus `_maturityGracePeriod`. The public interface redeems the entire qToken
  /// balance.
  /// @return uint Amount of qTokens redeemed
  function redeemAllQTokensByRatio() external returns(uint);
  
  /// @notice This function allows net lenders to redeem qTokens for ETH.
  /// Redemptions may only be permitted after loan maturity plus 
  /// `_maturityGracePeriod`. The public interface redeems specified amount
  /// of qToken from existing balance.
  /// @param amount Amount of qTokens to redeem
  /// @return uint Amount of qTokens redeemed
  function redeemQTokensByRatioWithETH(uint amount) external returns(uint);
    
  /// @notice This function allows net lenders to redeem qTokens for ETH.
  /// Redemptions may only be permitted after loan maturity plus
  /// `_maturityGracePeriod`. The public interface redeems the entire qToken
  /// balance.
  /// @return uint Amount of qTokens redeemed
  function redeemAllQTokensByRatioWithETH() external returns(uint);

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

  /// @notice Get the address of the `QAdmin`
  /// @return address
  function qAdmin() external view returns(address);
  
  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManager() external view returns(address);
    
  /// @notice Get the address of the `QuoteManager`
  /// @return address
  function quoteManager() external view returns(address);

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

  /// @notice Get amount of qTokens user can redeem based on current loan repayment ratio
  /// @return uint amount of qTokens user can redeem
  function redeemableQTokens() external view returns(uint);
  
  /// @notice Get amount of qTokens user can redeem based on current loan repayment ratio
  /// @param account Account to query
  /// @return uint amount of qTokens user can redeem
  function redeemableQTokens(address account) external view returns(uint);
  
  /// @notice Gets the current `redemptionRatio` where owned qTokens can be redeemed up to
  /// @return uint redemption ratio, capped and scaled by 1e18
  function redemptionRatio() external view returns(uint);

  /// @notice Tokens redeemed across all users so far
  function tokensRedeemedTotal() external view returns(uint);
  
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

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/QTypes.sol";

interface IQAdmin is IAccessControlUpgradeable {

  /// @notice Emitted when a new FixedRateMarket is deployed
  event CreateFixedRateMarket(address indexed marketAddress, address indexed tokenAddress, uint maturity);
  
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQPriceOracle {
  
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint);

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint);

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @return answer uint256, decimals uint8
  function priceFeed(address oracleFeed) external view returns(uint256, uint8);
  
  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./InterestRateModel.sol";

interface MTokenInterface is IERC20 {
 
  function accrualBlockTimestamp() external view returns(uint);
  function exchangeRateStored() external view returns(uint);
  function getCash() external view returns(uint);
  function totalBorrows() external view returns(uint);
  function totalReserves() external view returns(uint);
  function reserveFactorMantissa() external view returns(uint);
  function interestRateModel() external view returns(InterestRateModel);
  
}

interface MErc20Interface is MTokenInterface {

  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
  function liquidateBorrow(address borrower, uint repayAmount, MTokenInterface mTokenCollateral) external returns (uint);
  
}

interface MGlimmerInterface is MTokenInterface {

  function mint() external payable;
  function redeem(uint redeemTokens) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow() external payable;
  function repayBorrowBehalf(address borrower) external payable;
  function liquidateBorrow(address borrower, MTokenInterface mTokenCollateral) external payable;
  
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface InterestRateModel {

  /**
   * @notice Calculates the current borrow interest rate per timestmp
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per timestmp (as a percentage, and scaled by 1e18)
   */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
     * @notice Calculates the current supply interest rate per timestmp
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per timestmp (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa)  external view returns (uint);

  
}