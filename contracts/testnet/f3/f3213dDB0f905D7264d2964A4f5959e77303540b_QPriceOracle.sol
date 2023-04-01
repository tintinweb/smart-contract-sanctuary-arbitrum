//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/chainlink/AggregatorV3Interface.sol";
import "./interfaces/moonwell/MTokenInterfaces.sol";
import "./interfaces/IQAdmin.sol";
import "./interfaces/IQPriceOracle.sol";
import "./libraries/QTypes.sol";

contract QPriceOracle is Initializable, IQPriceOracle {

  /// @notice Contract storing all global Qoda parameters
  IQAdmin private _qAdmin;

  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress_ Address of the `QAdmin` contract
  function initialize(address qAdminAddress_) public initializer {
    _qAdmin = IQAdmin(qAdminAddress_);
  }
  
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD (18 digit precision)
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint){
    return _localToUSD(token, amountLocal);
  }

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD (18 digit precision)
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint){
    return _USDToLocal(token, valueUSD);
  }

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @return answer uint256, decimals uint8
  function priceFeed(address oracleFeed) external view returns(uint256, uint8){
    return _priceFeed(oracleFeed);
  }

  /// @notice Compound/Moonwell do not provide a view function for retrieving the
  /// current exchange rate between the yield bearing token and the underlying
  /// token. The protocol includes an exchangeRateCurrent() function which gives
  /// the value that we need, but it includes writes to storage, which is not gas
  /// efficient for our usage. Hence, we need this function to manually calculate
  /// the current exchange rate as a view function from the last stored exchange
  /// rate using 1) the interest accrual and 2) exchange rate formulas.
  /// @param mTokenAddress Address of the mToken contract
  function mTokenExchRateCurrent(address mTokenAddress) external view returns(uint){
    return _mTokenExchRateCurrent(mTokenAddress);
  }
  
  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address){
    return address(_qAdmin);
  }
  
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD (18 decimal place precision)
  function _localToUSD(IERC20 token, uint amountLocal) internal view returns(uint){
    
    // Check that the token is an enabled asset
    QTypes.Asset memory asset = _qAdmin.assets(token);
    require(asset.isEnabled, "QPO0 asset not supported");

    // Instantiate the underlying token ERC20 with decimal data
    IERC20Metadata underlyingMetadata = IERC20Metadata(asset.underlying);
    
    if(asset.isYieldBearing){
      // If the asset is yield-bearing, we need one extra step first
      // to convert from the amount of yield bearing tokens to
      // the amount of underlying tokens
            
      // mTokenExchRate is value of 1 mToken in underlying token
      uint mTokenExchRate = _mTokenExchRateCurrent(address(token));
      
      // amountUnderlying = mTokenAmount * mTokenExchRate / 10^18
      uint amountUnderlying = amountLocal * mTokenExchRate / (10 ** 18);

      // amountLocal now represents the amount of underlying tokens
      amountLocal = amountUnderlying;
    }
    
    // Get the oracle feed
    address oracleFeed = asset.oracleFeed;    
    (uint exchRate, uint8 exchDecimals) = _priceFeed(oracleFeed);
    
    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** underlyingMetadata.decimals();
    
    // Apply exchange rate to convert from amount of underlying tokens to value in USD
    uint valueUSD = amountLocal * exchRate * _qAdmin.MANTISSA_USD();
    
    // Divide by mantissas last for maximum precision
    valueUSD = valueUSD / tokenMantissa / exchRateMantissa;
    
    return valueUSD;
  }

  /// @notice Converts any value in USD into its amount in local using oracle feed price.
  /// For yield-bearing tokens, it will convert the value in USD directly into the
  /// amount of yield-bearing token (NOT the amount of underlying token)
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD (18 digit precision)
  /// @return uint Amount denominated in terms of the ERC20 token
  function _USDToLocal(IERC20 token, uint valueUSD) internal view returns(uint){

    // Check that the token is an enabled asset
    QTypes.Asset memory asset = _qAdmin.assets(token);
    require(asset.isEnabled, "QPO0 asset not supported");

    // Instantiate the underlying token ERC20 with decimal data
    IERC20Metadata underlyingMetadata = IERC20Metadata(asset.underlying);
    
    // Get the oracle feed
    address oracleFeed = asset.oracleFeed;
    (uint exchRate, uint8 exchDecimals) = _priceFeed(oracleFeed);

    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** underlyingMetadata.decimals();

    // Multiply by mantissas first for maximum precision
    uint amountUnderlying = valueUSD * tokenMantissa * exchRateMantissa;

    // Apply exchange rate to convert from value in USD to  amount of underlying tokens
    amountUnderlying = amountUnderlying / exchRate / _qAdmin.MANTISSA_USD();
    
    if(asset.isYieldBearing){
      // If the asset is yield-bearing, we need one extra step to convert
      // from the amount of underlying tokens to the amount of yield-bearing
      // tokens
            
      // mTokenExchRate is value of 1 mToken in underlying tokens
      uint mTokenExchRate = _mTokenExchRateCurrent(address(token));

      // Multiply by mantissa first for maximum precision
      uint amountMToken = amountUnderlying * (10 ** 18) / mTokenExchRate;
      
      return amountMToken;
      
    }else{

      // The asset is already the native underlying token, so we can just
      // return the amount of underlying tokens directly
      return amountUnderlying;    
    }
  }

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @return answer uint256, decimals uint8
  function _priceFeed(address oracleFeed) internal view returns(uint256, uint8){
    AggregatorV3Interface aggregator = AggregatorV3Interface(oracleFeed);
    (, int256 answer,,,) =  aggregator.latestRoundData();
    uint8 decimals = aggregator.decimals();
    return (uint(answer), decimals);
  }
  
  /// @notice Compound/Moonwell do not provide a view function for retrieving the
  /// current exchange rate between the yield bearing token and the underlying
  /// token. The protocol includes an exchangeRateCurrent() function which gives
  /// the value that we need, but it includes writes to storage, which is not gas
  /// efficient for our usage. Hence, we need this function to manually calculate
  /// the current exchange rate as a view function from the last stored exchange
  /// rate using 1) the interest accrual and 2) exchange rate formulas.
  /// @param mTokenAddress Address of the mToken contract
  function _mTokenExchRateCurrent(address mTokenAddress) internal view returns(uint){

    MTokenInterface mToken = MTokenInterface(mTokenAddress);
    
    // Step 1. Calculate Interest Accruals
    // See the accrueInterest() function in MToken.sol for implementation details
    
    // NOTE: Moonwell fork uses timestamps for interest calcs, NOT block as
    // per Compound. We will need to change the function call to
    // accrualBlockNumber() if we want to be compatible with Compound
    uint latestAccrualTimestamp = mToken.accrualBlockTimestamp();
    uint currentTimestamp = block.timestamp;
    if(currentTimestamp <= latestAccrualTimestamp){
      // No blocks have passed since the last interest accrual, so
      // we can just return the stored exchange rate directly
      return mToken.exchangeRateStored();
    }

    uint borrowRateMantissa = mToken.interestRateModel().getBorrowRate(mToken.getCash(),
                                                                       mToken.totalBorrows(),
                                                                       mToken.totalReserves()
                                                                       );
    uint simpleInterestFactor = borrowRateMantissa * (currentTimestamp - latestAccrualTimestamp);
    uint interestAccumulated = simpleInterestFactor * mToken.totalBorrows() / 1e18;
    uint totalBorrowsNew = interestAccumulated + mToken.totalBorrows();
    uint totalReservesNew = mToken.reserveFactorMantissa() * interestAccumulated / 1e18 + mToken.totalReserves();

    // Step 2. Calculate Exchange Rate
    // See exchangeRateCurrent(), exchangeRateStored(), and
    // exchangeRateStoredInternal()  in MToken.sol for implementation details
    uint totalSupply = mToken.totalSupply();
    uint cashPlusBorrowsMinusReserves = (mToken.getCash() + totalBorrowsNew - totalReservesNew);
    uint exchRateCurrent = cashPlusBorrowsMinusReserves * 1e18 / totalSupply;

    // Step 3. Perform sanity checks. `exchangeRateCurrent` should not deviate
    // by too much from `exchangeRateStored`
    require(exchRateCurrent <= mToken.exchangeRateStored() * 11 / 10, "QPO1 currentExchangeRate out of bounds"
            );
    require(exchRateCurrent >= mToken.exchangeRateStored() * 10 / 11, "QPO1 currentExchangeRate out of bounds");

    return exchRateCurrent;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
pragma solidity ^0.8.9;

interface AggregatorV3Interface {
    /**
     * Returns the decimals to offset on the getLatestPrice call
     */
    function decimals() external view returns (uint8);

    /**
     * Returns the description of the underlying price feed aggregator
     */
    function description() external view returns (string memory);

    /**
     * Returns the version number representing the type of aggregator the proxy points to
     */
    function version() external view returns (uint256);

    /**
     * Returns price data about a specific round
     */
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    /**
     * Returns price data from the latest round
     */
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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