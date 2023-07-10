//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./interfaces/IQodaLens.sol";
import "./interfaces/IQollateralManager.sol";
import "./interfaces/IQAdmin.sol";
import "./interfaces/IQPriceOracle.sol";
import "./interfaces/IQToken.sol";
import "./libraries/CustomErrors.sol";
import "./libraries/Interest.sol";
import "./libraries/QTypes.sol";
import "./libraries/QTypesPeripheral.sol";
import "./libraries/Utils.sol";

contract QodaLens is Initializable, IQodaLens {

  /// @notice Borrow side enum
  uint8 private constant _SIDE_BORROW = 0;

  /// @notice Lend side enum
  uint8 private constant _SIDE_LEND = 1;

  /// @notice PV enum
  uint8 private constant _TYPE_PV = 0;

  /// @notice FV enum
  uint8 private constant _TYPE_FV = 1;

  /// @notice Internal representation on null pointer for linked lists
  uint64 private constant _NULL_POINTER = 0;
    
  /// @notice Reserve storage gap so introduction of new parent class later on can be done via upgrade
  uint256[50] __gap;
  
  /// @notice Contract storing all global Qoda parameters
  IQAdmin private _qAdmin;

  /// @notice 0x0 null address for convenience
  address constant NULL = address(0);
  
  /// Note: Design decision: contracts are placed in constructor as Lens is
  /// stateless. Lens can be redeployed in case of contract upgrade
  function initialize(address qAdminAddress) public initializer {
    _qAdmin = IQAdmin(qAdminAddress);
  }
  
  /** VIEW FUNCTIONS **/

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
                               ) external view returns(QTypes.Quote[] memory, uint[] memory, uint[] memory) {
    
    // Handle invalid `side` inputs
    if(side != _SIDE_BORROW && side != _SIDE_LEND) {
      revert CustomErrors.QL_InvalidSide();
    }
    
    // Get QollateralManager for getting collateral ratio
    IQollateralManager _qollateralManager = IQollateralManager(_qAdmin.qollateralManager());
    
    // Size of `Quote`s linkedlist may be smaller than requested
    n = Math.min(n, market.getNumQuotes(side));
    
    // Initialize empty arrays to return
    QTypes.Quote[] memory quotes = new QTypes.Quote[](n);
    uint[] memory collateralRatios = new uint[](n);
    uint[] memory underlyingBalances = new uint[](n);
    
    // Get the head of the linked list
    QTypes.Quote memory currQuote = market.getQuoteHead(side);
    
    uint i = 0;
    while(i < n && currQuote.id != _NULL_POINTER) {

      // Hack to avoid "stack too deep" error - get necessary values from
      // `_takeNFilteredQuotesHelper` function
      // values[0] => amountPV
      // values[1] => amountFV
      // values[2] => hypothetical collateral ratio
      // values[3] => protocol fee
      // values[4] => underlying token balance
      // values[5] => underlying token allowance
      uint[] memory values = _takeNFilteredQuotesHelper(market, currQuote);
      
      // Filter out borrow `Quote`s if user's hypothetical collateral ratio is
      // less than the `initCollateralRatio` parameter
      if(side == _SIDE_BORROW && values[2] < _qollateralManager.initCollateralRatio(currQuote.quoter)) {        
        currQuote = market.getQuote(side, currQuote.next);
        continue;
      }

      // Filter out lend `Quote`s if user's current allowance or balance is
      // less than the size they are lending (plus fees)
      if(side == _SIDE_LEND && (values[0] + values[3] > values[5] || values[0] + values[3] > values[4])) {        
        currQuote = market.getQuote(side, currQuote.next);
        continue;        
      }

      // Current `Quote` passes the filter checks. Add data to the arrays
      quotes[i] = currQuote;
      collateralRatios[i] = _qollateralManager.collateralRatio(currQuote.quoter);
      underlyingBalances[i] = values[4];
        
      // Update the counter
      i++;
      
      // Go to the next `Quote`
      currQuote = market.getQuote(side, currQuote.next);
    }
    
    // Correct actual length of dynamic array
    assembly {
      mstore(quotes, i)
      mstore(collateralRatios, i)
      mstore(underlyingBalances, i)
    }
    
    // Return the array
    return (quotes, collateralRatios, underlyingBalances);
  }
  
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
                       ) external view returns(QTypes.Quote[] memory, uint[] memory, uint[] memory){

    // Handle invalid `side` inputs
    if(side != _SIDE_BORROW && side != _SIDE_LEND) {
      revert CustomErrors.QL_InvalidSide();
    }

    // Size of `Quote`s linkedlist may be smaller than requested
    n = Math.min(n, market.getNumQuotes(side));

    // Initialize empty arrays to return
    QTypes.Quote[] memory quotes = new QTypes.Quote[](n);
    uint[] memory collateralRatios = new uint[](n);
    uint[] memory underlyingBalances = new uint[](n);

    // Get the head of the linked list
    QTypes.Quote memory currQuote = market.getQuoteHead(side);

    // Get QollateralManager for getting collateral ratio
    IQollateralManager _qollateralManager = IQollateralManager(_qAdmin.qollateralManager());
    
    // Populate the arrays using the linkedlist pointers
    for(uint i=0; i<n; i++) {

      // Populate the `quotes` array
      quotes[i] = currQuote;
      address quoter = currQuote.quoter;

      // Populate the `collateralRatios` array
      uint collateralRatio = _qollateralManager.collateralRatio(quoter);
      collateralRatios[i] = collateralRatio;
      
      // Populate the `underlyingBalances` array
      uint balance = IERC20(market.underlyingToken()).balanceOf(quoter);
      underlyingBalances[i] = balance;

      // Go to next `Quote`
      currQuote = market.getQuote(side, currQuote.next);
    }        
    
    return (quotes, collateralRatios, underlyingBalances);    
  }
  
  function _takeMarkets() internal view returns (address[] memory) {
    address[] memory assetAddresses = _qAdmin.allAssets();
    
    // Get # markets for market array initialization
    uint marketLength = 0;
    for (uint i = 0; i < assetAddresses.length; i++) {
      QTypes.Asset memory asset = _qAdmin.assets(IERC20(assetAddresses[i]));
      marketLength += asset.maturities.length;
    }
    
    // Put unexpired markets into array, with length recorded in marketLength
    address[] memory marketAddresses = new address[](marketLength);
    marketLength = 0;
    for (uint i = 0; i < assetAddresses.length; i++) {
      IERC20 token = IERC20(assetAddresses[i]);
      QTypes.Asset memory asset = _qAdmin.assets(token);
      uint[] memory maturities = asset.maturities;
      for (uint j = 0; j < maturities.length; j++) {
        if (block.timestamp >= maturities[j]) {
          continue;
        }
        address marketAddress = _qAdmin.fixedRateMarkets(token, maturities[j]);
        if (!_qAdmin.isMarketEnabled(marketAddress)) {
          continue;
        }
        marketAddresses[marketLength] = marketAddress; 
        marketLength++;
      }
    }
    
    // Correct actual length of dynamic array
    assembly {
      mstore(marketAddresses, marketLength)
    }
    
    return marketAddresses;
  }

  /// @notice Gets all open quotes from all unexpired market for a given account
  /// @param account Account for getting all open quotes
  /// @return QTypesPeripheral.AccountQuote[] Related quotes for given account
  function takeAccountQuotes(address account) external view returns (QTypesPeripheral.AccountQuote[] memory) {
    address[] memory marketAddresses = _takeMarkets();
    
    // Get # quotes for quote array initialization
    uint quoteLength = 0;
    for (uint i = 0; i < marketAddresses.length; i++) {
      IFixedRateMarket market = IFixedRateMarket(marketAddresses[i]);
      for (uint8 side = 0; side <= 1; side++) {
        quoteLength += market.getAccountQuotes(side, account).length;
      }
    }
    
    // Put quote into array, with length recorded in quoteLength
    QTypesPeripheral.AccountQuote[] memory quotes = new QTypesPeripheral.AccountQuote[](quoteLength);
    quoteLength = 0;
    for (uint i = 0; i < marketAddresses.length; i++) {
      IFixedRateMarket market = IFixedRateMarket(marketAddresses[i]);
      for (uint8 side = 0; side <= 1; side++) {
        uint64[] memory ids = market.getAccountQuotes(side, account);
        for (uint j = 0; j < ids.length; j++) {
          QTypes.Quote memory quote = market.getQuote(side, ids[j]);
          quotes[quoteLength] = QTypesPeripheral.AccountQuote({
            market: address(market),
            id: ids[j],
            side: side,
            quoter: quote.quoter,
            quoteType: quote.quoteType,
            APR: quote.APR,
            cashflow: quote.cashflow,
            filled: quote.filled
          });
          quoteLength++;
        }
      }
    }
    
    return quotes;
  }

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
                            ) external view returns(QTypes.Quote[] memory){

    // Handle invalid `side` inputs
    if(side != _SIDE_BORROW && side != _SIDE_LEND) {
      revert CustomErrors.QL_InvalidSide();
    }

    // Initialize empty `Quote`s array to return
    QTypes.Quote[] memory quotes = new QTypes.Quote[](quoteIds.length);

    // Populate the array using the `quoteId` pointers
    for(uint i=0; i<quoteIds.length; i++) {
      quotes[i] = market.getQuote(side, quoteIds[i]);      
    }

    return quotes;
  }

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
                           ) external view returns(uint, uint){

    // Handle invalid `side` inputs
    if(side != _SIDE_BORROW && side != _SIDE_LEND) {
      revert CustomErrors.QL_InvalidSide();
    }

    // Handle invalid `quoteType` inputs
    if(quoteType != _TYPE_PV && quoteType != _TYPE_FV) {
      revert CustomErrors.QL_InvalidQuoteType();
    }

    // Get the current top of book
    QTypes.Quote memory currQuote = market.getQuoteHead(side);

    // Store the remaining size to be filled
    uint remainingSize = size;

    // Store the estimated APR weighted-avg numerator calculation
    uint num = 0;
    
    // Store the estimated APR weighted-avg denominator calculation
    uint denom = 0;
    
    // Loop until either the full size is satisfied or until the orderbook
    // runs out of quotes
    while(remainingSize != 0 && currQuote.id != _NULL_POINTER) {

      // Ignore self `Quote`s in estimation calculations
      if(currQuote.quoter == account) {
        currQuote = market.getQuote(side, currQuote.next);
        continue;
      }
      
      // Get the size of the current `Quote` in the orderbook
      uint quoteSize = currQuote.cashflow;

      // If the `quoteType` requested by user differs from the `quoteType`
      // of the current order, we need to do a FV -> PV conversion
      if(quoteType == _TYPE_PV && currQuote.quoteType == _TYPE_FV) {      
        quoteSize = Interest.FVToPV(
                                   currQuote.APR,
                                   currQuote.cashflow,
                                   block.timestamp,
                                   market.maturity(),
                                   _qAdmin.MANTISSA_BPS()
                                   );
      }

      // If the `quoteType` requested by user differs from the `quoteType`
      // of the current order, we need to do a PV -> FV conversion
      if(quoteType == _TYPE_FV && currQuote.quoteType == _TYPE_PV) {
        quoteSize = Interest.PVToFV(
                                   currQuote.APR,
                                   currQuote.cashflow,
                                   block.timestamp,
                                   market.maturity(),
                                   _qAdmin.MANTISSA_BPS()
                                   );        
      }
      
      uint currSize = Math.min(remainingSize, quoteSize);
      
      // Update the running estimated APR weighted-avg numerator calculation
      num += currSize * currQuote.APR;

      // Update the runniing estimated APR weighted-avg denominator calculation
      denom += currSize;
      
      // Subtract the current `Quote` size from the remaining size to be filled
      remainingSize = remainingSize - currSize;
      
      // Move on to the next best `Quote`
      currQuote = market.getQuote(side, currQuote.next);
    }

    if(denom == 0) {

      // No orders in the orderbook, return default null values
      return (0,0);

    } else {

      // The `estimatedAPR` is the weighted avg of `Quote` APRs by `Quote`
      // sizes i.e., `num` divided by `denom`
      uint estimatedAPR = num / denom;
      
      return (estimatedAPR, size - remainingSize);
    }
  }
  
  /// @notice Get an account's maximum available collateral user can withdraw in specified asset.
  /// For example, what is the maximum amount of GLMR that an account can withdraw
  /// while ensuring their account health continues to be acceptable?
  /// Note: This function will return withdrawable amount that user has indeed collateralized, not amount that user can borrow
  /// Note: User can only withdraw up to `initCollateralRatio` for their own protection against instant liquidations
  /// @param account User account
  /// @param withdrawToken Currency of collateral to withdraw
  /// @return uint Maximum available collateral user can withdraw in specified asset
  function hypotheticalMaxWithdraw(
                                   address account,
                                   address withdrawToken
                                   ) external view returns (uint) {
    return _hypotheticalMaxWithdraw(account, withdrawToken);
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
  function hypotheticalMaxBorrowFV(
                                   address account,
                                   IFixedRateMarket borrowMarket
                                   ) external view returns (uint) {
    IQollateralManager _qollateralManager = IQollateralManager(_qAdmin.qollateralManager());
    return _qollateralManager.hypotheticalMaxBorrowFV(account, borrowMarket);
  }
  
  /// @notice Get an account's maximum value user can lend in specified market when protocol fee is factored in.
  /// @param account User account
  /// @param lendMarket Address of the `FixedRateMarket` market to lend
  /// @return uint Maximum value user can lend in specified market with protocol fee considered
  function hypotheticalMaxLendPV(
                                 address account,
                                 IFixedRateMarket lendMarket
                                 ) external view returns (uint) {
    IERC20 underlying_ = lendMarket.underlyingToken();
    uint balance = underlying_.balanceOf(account);
    return lendMarket.hypotheticalMaxLendPV(balance);
  }

  /// @notice Get an account's minimum collateral to further deposit if user wants to borrow specified amount in a certain market.
  /// For example, what is the minimum amount of USDC to deposit so that an account can borrow 100 DEV token from qDEVJUL22
  /// while ensuring their account health continues to be acceptable?
  /// @param account User account
  /// @param collateralToken Currency to collateralize in
  /// @param borrowMarket Address of the `FixedRateMarket` market to borrow
  /// @param borrowAmountFV Amount to borrow in local ccy
  /// @return uint Minimum collateral required to further deposit
  function minimumCollateralRequired(
                                     address account,
                                     IERC20 collateralToken,
                                     IFixedRateMarket borrowMarket,
                                     uint borrowAmountFV
                                     ) external view returns (uint) {
    IQollateralManager _qollateralManager = IQollateralManager(_qAdmin.qollateralManager());
    IQPriceOracle _qPriceOracle = IQPriceOracle(_qAdmin.qPriceOracle());
    uint initRatio = _qollateralManager.initCollateralRatio(account);
    uint virtualCollateralValue = _qollateralManager.virtualCollateralValue(account);
    uint virtualBorrowValue = _qollateralManager.hypotheticalVirtualBorrowValue(account, borrowMarket, borrowAmountFV, 0) + 1; // + 1 to avoid rounding problem
    uint virtualUSD = Utils.roundUpDiv(initRatio * virtualBorrowValue, _qAdmin.MANTISSA_COLLATERAL_RATIO()) - virtualCollateralValue;
    if (virtualUSD > _qAdmin.creditLimit(account)) {
      revert CustomErrors.QL_MaxBorrowExceeded();
    }
    uint realUSD = Utils.roundUpDiv(virtualUSD * _qAdmin.MANTISSA_FACTORS(), _qAdmin.collateralFactor(collateralToken));
    uint realLocal = _qPriceOracle.USDToLocal(collateralToken, realUSD) + 1; // + 1 to avoid rounding problem
    return realLocal;
  }
  
  function getAllMarketsByAsset(IERC20 token) public view returns (IFixedRateMarket[] memory) {
    QTypes.Asset memory asset = _qAdmin.assets(token);
    IFixedRateMarket[] memory fixedRateMarkets = new IFixedRateMarket[](asset.maturities.length);
    for (uint i = 0; i < asset.maturities.length; i++) {
        fixedRateMarkets[i] = IFixedRateMarket(_qAdmin.fixedRateMarkets(token, asset.maturities[i]));
    }
    return fixedRateMarkets;
  }
    
  function totalLoansTradedByMarket(IFixedRateMarket market) public view returns (uint) {
    return totalUnredeemedLendsByMarket(market) + totalRedeemedLendsByMarket(market);
  }
    
  function totalRedeemedLendsByMarket(IFixedRateMarket market) public view returns (uint) {
    IQToken qToken = IQToken(market.qToken());
    return qToken.tokensRedeemedTotal();
  }
    
  function totalUnredeemedLendsByMarket(IFixedRateMarket market) public view returns (uint) {
    IQToken qToken = IQToken(market.qToken());
    return qToken.totalSupply();
  }
    
  function totalRepaidBorrowsByMarket(IFixedRateMarket market) public view returns (uint) {
    IERC20 token = market.underlyingToken();
    return token.balanceOf(address(market));
  }
    
  function totalUnrepaidBorrowsByMarket(IFixedRateMarket market) public view returns (uint) {
    return totalLoansTradedByMarket(market) - totalRepaidBorrowsByMarket(market); 
  }
    
  function totalLoansTradedByAsset(IERC20 token) public view returns (uint) {
    IFixedRateMarket[] memory fixedRateMarkets = getAllMarketsByAsset(token);
    uint totalLoansTraded = 0;
    for (uint i = 0; i < fixedRateMarkets.length; i++) {
        totalLoansTraded += totalLoansTradedByMarket(fixedRateMarkets[i]);
    }
    return totalLoansTraded;
  }
    
  function totalRedeemedLendsByAsset(IERC20 token) public view returns (uint) {
    IFixedRateMarket[] memory fixedRateMarkets = getAllMarketsByAsset(token);
    uint totalRedeemedLends = 0;
    for (uint i = 0; i < fixedRateMarkets.length; i++) {
        totalRedeemedLends += totalRedeemedLendsByMarket(fixedRateMarkets[i]);
    }
    return totalRedeemedLends;
  }
    
  function totalUnredeemedLendsByAsset(IERC20 token) public view returns (uint) {
    return totalLoansTradedByAsset(token) - totalRedeemedLendsByAsset(token);
  }
    
  function totalRepaidBorrowsByAsset(IERC20 token) public view returns (uint) {
    IFixedRateMarket[] memory fixedRateMarkets = getAllMarketsByAsset(token);
    uint totalRepaidBorrows = 0;
    for (uint i = 0; i < fixedRateMarkets.length; i++) {
        totalRepaidBorrows += totalRepaidBorrowsByMarket(fixedRateMarkets[i]);
    }
    return totalRepaidBorrows;
  }
    
  function totalUnrepaidBorrowsByAsset(IERC20 token) public view returns (uint) {
    return totalLoansTradedByAsset(token) - totalRepaidBorrowsByAsset(token); 
  }
    
  function totalLoansTradedInUSD() public view returns (uint) {
    IQPriceOracle _qPriceOracle = IQPriceOracle(_qAdmin.qPriceOracle());
    address[] memory assets = _qAdmin.allAssets();
    uint loansTradedUSD = 0;
    for (uint i = 0; i < assets.length; i++) {
      IERC20 asset = IERC20(assets[i]);
      uint loansTradedByAsset = totalLoansTradedByAsset(asset);
      loansTradedUSD += _qPriceOracle.localToUSD(asset, loansTradedByAsset); 
    }
    return loansTradedUSD;
  }
  
  function totalRedeemedLendsInUSD() public view returns (uint) {
    IQPriceOracle _qPriceOracle = IQPriceOracle(_qAdmin.qPriceOracle());
    address[] memory assets = _qAdmin.allAssets();
    uint redeemedLendsUSD = 0;
    for (uint i = 0; i < assets.length; i++) {
      IERC20 asset = IERC20(assets[i]);
      uint redeemedLendsByAsset = totalRedeemedLendsByAsset(asset);
      redeemedLendsUSD += _qPriceOracle.localToUSD(asset, redeemedLendsByAsset); 
    }
    return redeemedLendsUSD;
  }
    
  function totalUnredeemedLendsInUSD() public view returns (uint) {
    return totalLoansTradedInUSD() - totalRedeemedLendsInUSD();
  }
    
  function totalRepaidBorrowsInUSD() public view returns (uint) {
    IQPriceOracle _qPriceOracle = IQPriceOracle(_qAdmin.qPriceOracle());
    address[] memory assets = _qAdmin.allAssets();
    uint repaidBorrows = 0;
    for (uint i = 0; i < assets.length; i++) {
      IERC20 asset = IERC20(assets[i]);
      uint repaidBorrowsByAsset = totalRepaidBorrowsByAsset(asset);
      repaidBorrows += _qPriceOracle.localToUSD(asset, repaidBorrowsByAsset); 
    }
    return repaidBorrows;
  }
    
  function totalUnrepaidBorrowsInUSD() public view returns (uint) {
    return totalLoansTradedInUSD() - totalRepaidBorrowsInUSD(); 
  }
  
  /// @notice Get the address of the `QollateralManager` contract
  /// @return address Address of `QollateralManager` contract
  function qollateralManager() external view returns(address){
    return _qAdmin.qollateralManager();
  }
  
  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address){
    return address(_qAdmin);
  }
  
  /// @notice Get the address of the `QPriceOracle` contract
  /// @return address Address of `QPriceOracle` contract
  function qPriceOracle() external view returns(address){
    return _qAdmin.qPriceOracle();
  }

  
  /** INTERNAL FUNCTIONS **/

  
  /// @notice Get an account's maximum available collateral user can withdraw in specified asset.
  /// For example, what is the maximum amount of GLMR that an account can withdraw
  /// while ensuring their account health continues to be acceptable?
  /// Note: This function will return withdrawable amount that user has indeed collateralized, not amount that user can borrow
  /// Note: User can only withdraw up to `initCollateralRatio` for their own protection against instant liquidations
  /// @param account User account
  /// @param withdrawToken Currency of collateral to withdraw
  /// @return uint Maximum available collateral user can withdraw in specified asset
  function _hypotheticalMaxWithdraw(
                                    address account,
                                    address withdrawToken
                                    ) internal view returns(uint) {
    IQollateralManager _qollateralManager = IQollateralManager(_qAdmin.qollateralManager());
    IQPriceOracle _qPriceOracle = IQPriceOracle(_qAdmin.qPriceOracle());
    IERC20 withdrawERC20 = IERC20(withdrawToken);
    QTypes.Asset memory asset = _qAdmin.assets(withdrawERC20);
    uint currentRatio = _qollateralManager.collateralRatio(account);
    uint minRatio = _qAdmin.initCollateralRatio(account);
    uint collateralBalance = _qollateralManager.collateralBalance(account, withdrawERC20);
    if (collateralBalance == 0 || currentRatio <= minRatio) {
      return 0;
    }
    if (currentRatio >= _qAdmin.UINT_MAX()) {
      return collateralBalance;
    }
    uint virtualBorrow = _qollateralManager.virtualBorrowValue(account);
    uint virtualUSD = virtualBorrow * (currentRatio - minRatio) / _qAdmin.MANTISSA_COLLATERAL_RATIO();
    uint realUSD = virtualUSD * _qAdmin.MANTISSA_FACTORS() / asset.collateralFactor;
    uint valueLocal = _qPriceOracle.USDToLocal(withdrawERC20, realUSD);
    return valueLocal <= collateralBalance ? valueLocal : collateralBalance;   
  }

  /// @notice This is a hacky helper function that helps to avoid the
  /// "stack too deep" compile error.
  /// @param market Market to query
  /// @param quote Quote to query
  /// @return uint[] [amountPV, amountFV, hcr, fee, balance, allowance]
  function _takeNFilteredQuotesHelper(
                                      IFixedRateMarket market,
                                      QTypes.Quote memory quote
                                      ) internal view returns(uint[] memory) {

    // Get the PV of the remaining amount in the `Quote`
    uint amountPV = market.getPV(
                                 quote.quoteType,
                                 quote.APR,
                                 quote.cashflow - quote.filled,
                                 block.timestamp,
                                 market.maturity()
                                 );                             

    // Get the FV of the remaining amount in the `Quote`
    uint amountFV = market.getFV(
                                 quote.quoteType,
                                 quote.APR,
                                 quote.cashflow - quote.filled,
                                 block.timestamp,
                                 market.maturity()
                                 );
    
    // Get QollateralManager for hypothetical collateral ratio
    IQollateralManager _qollateralManager = IQollateralManager(_qAdmin.qollateralManager());
    
    // Get the user's hypothetical collateral ratio after `Quote` fill
    uint hcr = _qollateralManager.hypotheticalCollateralRatio(
                                                              quote.quoter,
                                                              market.underlyingToken(),
                                                              0,
                                                              0,
                                                              market,
                                                              amountFV,
                                                              0
                                                              );
    
    // Get the fee and user's current balance and allowance
    uint fee = market.proratedProtocolFee(amountPV, block.timestamp);
    uint balance = IERC20(market.underlyingToken()).balanceOf(quote.quoter);
    uint allowance = IERC20(market.underlyingToken()).allowance(quote.quoter, address(market));

    uint[] memory values = new uint[](6);
    values[0] = amountPV;
    values[1] = amountFV;
    values[2] = hcr;
    values[3] = fee;
    values[4] = balance;
    values[5] = allowance;   

    return values;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQPriceOracle {

  /// @notice Emitted when setting the DIA Oracle address
  event SetDIAOracle(address DIAOracle);
  
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

  /// @notice Convenience function for getting price feed from various oracles.
  /// Returned prices should ALWAYS be normalized to eight decimal places.
  /// @param underlyingToken Address of the underlying token
  /// @param oracleFeed Address of the oracle feed
  /// @return answer uint256, decimals uint8
  function priceFeed(
                     IERC20 underlyingToken,
                     address oracleFeed
                     ) external view returns(uint256, uint8);
  
  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQToken is IERC20Upgradeable, IERC20MetadataUpgradeable {
  
  /// @notice Emitted when an account redeems their qTokens
  event RedeemQTokens(address indexed account, uint amount);
  
  /** USER INTERFACE **/
  
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
  
  /** VIEW FUNCTIONS **/
  
  /// @notice Get the address of the `QAdmin`
  /// @return address
  function qAdmin() external view returns(address);
  
  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarket() external view returns(address);
  
  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return IERC20
  function underlyingToken() external view returns(IERC20);
  
  /// @notice Get amount of qTokens user can redeem based on current loan repayment ratio
  /// @return uint amount of qTokens user can redeem
  function redeemableQTokens() external view returns(uint);
  
  /// @notice Gets the current `redemptionRatio` where owned qTokens can be redeemed up to
  /// @return uint redemption ratio, capped and scaled by 1e18
  function redemptionRatio() external view returns(uint);
  
  /// @notice Tokens redeemed from message sender so far
  /// @return uint Token redeemed by message sender
  function tokensRedeemed() external view returns(uint);
  
  /// @notice Tokens redeemed from given account so far
  /// @param account Account to query
  /// @return uint Token redeemed by given account
  function tokensRedeemed(address account) external view returns(uint);
  
  /// @notice Tokens redeemed across all users so far
  function tokensRedeemedTotal() external view returns(uint);
  
  /** ERC20 Implementation **/
  
  /// @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
  /// @param account Account to receive qToken
  /// @param amount Amount of qToken to mint
  function mint(address account, uint256 amount) external;
  
  /// @notice Destroys `amount` tokens from `account`, reducing the total supply
  /// @param account Account to receive qToken
  /// @param amount Amount of qToken to mint
  function burn(address account, uint256 amount) external;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./CustomErrors.sol";

library Interest {

  function PVToFV(
                  uint64 APR,
                  uint PV,
                  uint sTime,
                  uint eTime,
                  uint mantissaAPR
                  ) internal pure returns(uint){

    if (sTime >= eTime) {
      revert CustomErrors.INT_InvalidTimeInterval();
    }

    // Seconds per 365-day year (60 * 60 * 24 * 365)
    uint year = 31536000;
    
    // elapsed time from now to maturity
    uint elapsed = eTime - sTime;

    uint interest = PV * APR * elapsed / mantissaAPR / year;

    return PV + interest;    
  }

  function FVToPV(
                  uint64 APR,
                  uint FV,
                  uint sTime,
                  uint eTime,
                  uint mantissaAPR
                  ) internal pure returns(uint){

    if (sTime >= eTime) {
      revert CustomErrors.INT_InvalidTimeInterval();
    }

    // Seconds per 365-day year (60 * 60 * 24 * 365)
    uint year = 31536000;
    
    // elapsed time from now to maturity
    uint elapsed = eTime - sTime;

    uint num = FV * mantissaAPR * year;
    uint denom = mantissaAPR * year + APR * elapsed;

    return num / denom;
    
  }  
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/CustomErrors.sol";

library Utils {
  
  using SafeERC20 for IERC20;
  
  function roundUpDiv(uint dividend, uint divider) internal pure returns(uint) {
    uint adjustment = dividend % divider > 0? 1: 0;
    return dividend / divider + adjustment;
  }
  
  /// @notice Transfer fund from sender to receiver, with handling of ETH wrapping and unwrapping
  /// if needed. Note that this function will not perform balance check and it should be done
  /// in the caller.
  /// @param sender Account of the sender
  /// @param receiver Account of the receiver
  /// @param amount Size of the fund to be transferred from sender to receiver
  /// @param isSendingETH Indicate if sender is sending fund with ETH
  /// @param isReceivingETH Indicate if receiver is receiving fund with ETH
  function transferTokenOrETH(
                              address sender,
                              address receiver,
                              uint amount,
                              IERC20 underlying,
                              address wethAddress,
                              bool isSendingETH,
                              bool isReceivingETH
                              ) internal {
    address sender_ = sender;
    address receiver_ = receiver;
    
    // If it is ETH transfer, contract will send/receive on behalf
    // and do needed token wrapping/unwrapping
    if (isSendingETH) {
      sender_ = address(this);
    }
    if (isReceivingETH) {
      receiver_ = address(this);
    }
    
    // If sender uses ETH for transfer, token wrapping is needed
    if (isSendingETH) {
      IWETH weth = IWETH(wethAddress);
      weth.deposit{ value: amount }();
    }
    
    // Transfer `amount` from sender to receiver
    if (sender_ == address(this)) {
      underlying.safeTransfer(receiver_, amount);
    } else {
      underlying.safeTransferFrom(sender_, receiver_, amount);
    }
    
    // For receiver getting ETH in transfer, token unwrapping is needed
    if (isReceivingETH) {
      IWETH weth = IWETH(wethAddress);
      weth.withdraw(amount);
      (bool success,) = receiver.call{value: amount}("");
      if (!success) {
        revert CustomErrors.UTL_UnsuccessfulEthTransfer();
      }
    }
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