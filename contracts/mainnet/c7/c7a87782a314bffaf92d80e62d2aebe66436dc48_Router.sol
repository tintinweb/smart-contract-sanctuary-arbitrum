// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/ILpManager.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IDipxStorage.sol";
import "./interfaces/IPositionManager.sol";
import "./oracle/interfaces/IVaultPriceFeed.sol";
import "./oracle/interfaces/IPythPriceFeed.sol";
import "./referrals/interfaces/IReferral.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract Router is IRouter,Initializable,OwnableUpgradeable,ReentrancyGuardUpgradeable{
  address public dipxStorage;

  mapping(address => bool) public plugins;

  function initialize(address _dipxStorage) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    dipxStorage = _dipxStorage;
  }

  receive() external payable{}

  function setDipxStorage(address _dipxStorage) external override onlyOwner{
    dipxStorage = _dipxStorage;
  }

  function getLpManager() public view returns(address){
    return IDipxStorage(dipxStorage).lpManager();
  }
  function getPositionManager() public view returns(address){
    return IDipxStorage(dipxStorage).positionManager();
  }
  function getReferral() public view returns(address){
    return IDipxStorage(dipxStorage).referral();
  }
  function getPricefeed() public view returns(address){
    return IDipxStorage(dipxStorage).priceFeed();
  }
  function isLpToken(address _token) public override view returns(bool,bool) {
    address lpManager = getLpManager();
    bool isLp = ILpManager(lpManager).isLpToken(_token);
    bool enable = ILpManager(lpManager).lpEnable(_token);
    return (isLp, enable);
  }
  function getLpToken(address collateralToken) public override view returns(address){
    address lpManager = getLpManager();
    return ILpManager(lpManager).lpTokens(collateralToken);
  }
  function getPoolPrice(address _pool,bool _maximise,bool _includeProfit,bool _includeLoss) public override view returns(uint256){
    address lpManager = getLpManager();
    if(ILpManager(lpManager).isLpToken(_pool)){
      return ILpManager(lpManager).getPoolPrice(_pool, _maximise, _includeProfit, _includeLoss);
    }else{
      uint256 pricePrecision = 10**IVaultPriceFeed(getPricefeed()).decimals();
      return 1 * pricePrecision;
    }
  }

  function getAccountPools(address _account) public view returns(Liquidity[] memory){
    ILpManager lpManager = ILpManager(getLpManager());
    uint256 len = lpManager.getAccountPoolLength(_account);
    uint256 count = 0;
    for (uint256 i = 0; i < len; i++) {
      address pool = lpManager.getAccountPoolAt(_account, i);
      if(IERC20Metadata(pool).balanceOf(_account) > 0){
        count = count + 1;
      }
    }
    Liquidity[] memory datas = new Liquidity[](count);
    uint256 index = 0;
    for (uint256 i = 0; i < len; i++) {
      address pool = lpManager.getAccountPoolAt(_account, i);
      IERC20Metadata erc20 = IERC20Metadata(pool);
      uint256 balance = erc20.balanceOf(_account);
      if(balance > 0){
        datas[index] = Liquidity(
                        pool,
                        erc20.name(),
                        erc20.symbol(),
                        erc20.decimals(),
                        balance
                      );
        index = index + 1;
      }
    }

    return datas;
  }

  function getAccountPositions(address _account) public view returns(IPositionManager.Position[] memory){
    IPositionManager pm = IPositionManager(getPositionManager());
    uint256 len = pm.getPositionKeyLength(_account);
    IPositionManager.Position[] memory positions = new IPositionManager.Position[](len);
    for (uint256 i = 0; i < len; i++) {
      bytes32 key = pm.getPositionKeyAt(_account,i);
      positions[i] = pm.getPositionByKey(key);
    }
    return positions;
  }

  function _updatePrice(bytes[] memory _priceUpdateData) private{
    if(_priceUpdateData.length == 0){
      return;
    }

    IVaultPriceFeed pricefeed = IVaultPriceFeed(getPricefeed());
    IPythPriceFeed pythPricefeed = IPythPriceFeed(pricefeed.pythPriceFeed());
    pythPricefeed.updatePriceFeeds(_priceUpdateData);
  }

  function addLiquidityNative(
    address _targetPool,
    uint256 _amountIn, 
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external nonReentrant payable override returns(uint256){
    require(_amountIn>0 && _amountIn==msg.value, "Insufficient token");
    address pool = _targetPool;
    address lpManager = getLpManager();
    if(pool == address(0)){
      pool = ILpManager(lpManager).lpTokens(IDipxStorage(dipxStorage).nativeCurrency());
    }
    _setReferrer(msg.sender, _referrer);
    _updatePrice(_priceUpdateData);
    uint256 currentPrice = getPoolPrice(pool, true, true, true);
    require(_price >= currentPrice, "Pool price higher than limit");
    TransferHelper.safeTransferETH(lpManager, _amountIn);
    return ILpManager(lpManager).addLiquidityNative(_to,_targetPool);
  }

  function addLiquidity(
    address _collateralToken,
    address _targetPool,
    uint256 _amount,
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external override nonReentrant returns(uint256){
    address pool = _targetPool;
    address lpManager = getLpManager();
    if(pool == address(0)){
      pool = ILpManager(lpManager).lpTokens(_collateralToken);
    }
    _setReferrer(msg.sender, _referrer);
    _updatePrice(_priceUpdateData);
    uint256 currentPrice = getPoolPrice(pool, true, true, true);
    require(_price >= currentPrice, "Pool price higher than limit");

    require(_amount>0, "Insufficient amount");
    TransferHelper.safeTransferFrom(_collateralToken, msg.sender, lpManager, _amount);
    return ILpManager(lpManager).addLiquidity(_collateralToken,_targetPool, _to);
  }

  function removeLiquidity(
    address _lpToken,
    address _receiveToken, 
    uint256 _liquidity,
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external override nonReentrant returns(uint256){
    _updatePrice(_priceUpdateData);

    uint256 currentPrice = getPoolPrice(_lpToken, false, true, true);
    require(_price <= currentPrice, "Pool price lower than limit");
    require(_liquidity>0, "Insufficient liquidity");

    _setReferrer(msg.sender, _referrer);
    address lpManager = getLpManager();
    TransferHelper.safeTransferFrom(_lpToken, msg.sender, lpManager, _liquidity);
    return ILpManager(lpManager).removeLiquidity(_lpToken, _receiveToken, _to);
  }

  function getPoolLiqFee(address _pool) external view override returns(uint256){
    return IDipxStorage(dipxStorage).getTokenGasFee(_pool);
  }

  function addPlugin(address _plugin) external override onlyOwner {
    plugins[_plugin] = true;
  }

  function removePlugin(address _plugin) external override onlyOwner {
    plugins[_plugin] = false;
  }

  function _validatePlugin(address _plugin) private view{
    require(plugins[_plugin], "PositionRouter: invalid plugin");
  }

  function _setReferrer(address _account, address _referrer) private{
    if(_referrer != address(0)){
      address referral = getReferral();
      if(referral != address(0)){
        (
            address preReferrer,
            /*uint256 totalRebate*/,
            /*uint256 discountShare*/
        ) = IReferral(referral).getTraderReferralInfo(_account);
        if(preReferrer == address(0)){
          IReferral(referral).setTraderReferral(_account, _referrer);
        }
      }
    }
  }

  function increasePosition(
    address _indexToken,
    address _collateralToken,
    uint256 _amountIn,
    uint256 _sizeDelta,
    uint256 _price,
    bool _isLong,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external override payable nonReentrant{
    _updatePrice(_priceUpdateData);

    IPositionManager positionManager = IPositionManager(getPositionManager());
    if(_isLong){
      require(positionManager.getMaxPrice(_indexToken)<=_price, "PositionRouter: mark price higher than limit");
    }else{
      require(positionManager.getMinPrice(_indexToken)>=_price, "PositionRouter: mark price lower than limit");
    }
    _setReferrer(msg.sender, _referrer);
    TransferHelper.safeTransferFrom(_collateralToken, msg.sender, address(positionManager), _amountIn);
    _increasePosition(msg.sender, _indexToken, _collateralToken, _sizeDelta, _isLong);
  }

  function pluginIncreasePosition(
    address _account,
    address _indexToken,
    address _collateralToken,
    uint256 _amountIn,
    uint256 _sizeDelta,
    bool _isLong
  ) external override payable nonReentrant{
    _validatePlugin(msg.sender);
    TransferHelper.safeTransfer(_collateralToken, IDipxStorage(dipxStorage).positionManager(), _amountIn);
    _increasePosition(_account, _indexToken, _collateralToken, _sizeDelta, _isLong);
  }

  function decreasePosition(
    address _indexToken, 
    address _collateralToken, 
    uint256 _sizeDelta, 
    uint256 _collateralDelta, 
    bool _isLong, 
    address _receiver,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  )external override payable nonReentrant returns(uint256){
    _updatePrice(_priceUpdateData);

    IPositionManager positionManager = IPositionManager(getPositionManager());
    if(_isLong){
      require(positionManager.getMinPrice(_indexToken)>=_price, "PositionRouter: mark price lower than limit");
    }else{
      require(positionManager.getMaxPrice(_indexToken)<=_price, "PositionRouter: mark price high than limit");
    }
    _setReferrer(msg.sender, _referrer);
    return _decreasePosition(msg.sender, _indexToken, _collateralToken, _sizeDelta, _collateralDelta, _isLong, _receiver);
  }

  function pluginDecreasePosition(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    uint256 _sizeDelta, 
    uint256 _collateralDelta, 
    bool _isLong, 
    address _receiver
  )external override payable nonReentrant returns(uint256){
    _validatePlugin(msg.sender);
    return _decreasePosition(_account, _indexToken, _collateralToken, _sizeDelta, _collateralDelta, _isLong, _receiver);
  }

  function _decreasePosition(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    uint256 _sizeDelta, 
    uint256 _collateralDelta, 
    bool _isLong, 
    address _receiver
  )private returns(uint256){
    IPositionManager positionManager = IPositionManager(getPositionManager());
    (uint256 liquidationState, ) = positionManager.validateLiquidation(_account, _collateralToken, _indexToken, _isLong, false);
    if(liquidationState==0){
      uint256 tokenOutAfterFee = positionManager.decreasePosition{value:msg.value}(_account, _indexToken, _collateralToken, _sizeDelta, _collateralDelta, _isLong, _receiver);
      return tokenOutAfterFee;
    }else{
      positionManager.liquidatePosition(
        _account, 
        _indexToken, 
        _collateralToken, 
        _isLong,
        msg.sender
      );
      if(msg.value>0){
        TransferHelper.safeTransferETH(msg.sender, msg.value);
      }
      return 0;
    }
  }

  function _increasePosition(
    address _account,
    address _indexToken,
    address _collateralToken,
    uint256 _sizeDelta,
    bool _isLong
  ) private{
    IPositionManager positionManager = IPositionManager(getPositionManager());
    positionManager.increasePosition{value:msg.value}(_account, _indexToken, _collateralToken, _sizeDelta, _isLong);
  }

  function liquidatePosition(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    bool _isLong,
    address _feeReceiver,
    bytes[] memory _priceUpdateData
  ) external override{
    _updatePrice(_priceUpdateData);
    IPositionManager positionManager = IPositionManager(getPositionManager());
    positionManager.liquidatePosition(
      _account, 
      _indexToken, 
      _collateralToken, 
      _isLong,
      _feeReceiver
    );
  }

  function withdrawETH(address _receiver, uint256 _amountOut) external onlyOwner {
    TransferHelper.safeTransferETH(_receiver, _amountOut);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IStorageSet.sol";

interface ILpManager is IStorageSet{
  function isLpToken(address _lpToken) external view returns(bool);
  function lpEnable(address _lpToken) external view returns(bool);

  function getAccountPoolLength(address _account) external view returns(uint256);
  function getAccountPoolAt(address _account, uint256 _index) external view returns(address);

  function getPoolPrice(address _pool, bool _maximise,bool _includeProfit, bool _includeLoss) external view returns(uint256);
  function lpTokens(address collateralToken) external view returns(address);
  function getSupplyWithPnl(address _lpToken, bool _includeProfit, bool _includeLoss) external view returns(uint256);

  function addLiquidityNative(address _to,address _targetPool) external returns(uint256);
  function addLiquidity(address _collateralToken,address _targetPool,address _to) external returns(uint256);
  function removeLiquidity(address _pool,address _receiveToken, address _to) external returns(uint256);

  function setPoolActive(address _pool, bool _isLp, bool _active) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IStorageSet.sol";

interface IRouter is IStorageSet{
  struct Liquidity{
    address pool;
    string name;
    string symbol;
    uint8 decimals;
    uint256 balance;
  }
  function isLpToken(address token) external view returns(bool,bool);
  function getLpToken(address collateralToken) external view returns(address);
  function getPoolPrice(address _pool,bool _maximise,bool _includeProfit,bool _includeLoss) external view returns(uint256);

  function addLiquidityNative(
    address _targetPool,
    uint256 _amount, 
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external payable returns(uint256);
  function addLiquidity(
    address _collateralToken,
    address _targetPool,
    uint256 _amount,
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external returns(uint256);
  function removeLiquidity(
    address _collateralToken,
    address _receiveToken,
    uint256 _liquidity,
    address _to,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external returns(uint256);

  function getPoolLiqFee(address pool) external view returns(uint256);
  function addPlugin(address _plugin) external;
  function removePlugin(address _plugin) external;
  
  function increasePosition(
    address _indexToken,
    address _collateralToken,
    uint256 _amountIn,
    uint256 _sizeDelta,
    uint256 _price,
    bool _isLong,
    address _referrer,
    bytes[] memory _priceUpdateData
  ) external payable;

  function decreasePosition(
    address _indexToken, 
    address _collateralToken, 
    uint256 _sizeDelta, 
    uint256 _collateralDelta, 
    bool _isLong, 
    address _receiver,
    uint256 _price,
    address _referrer,
    bytes[] memory _priceUpdateData
  )external payable returns(uint256);

  function pluginIncreasePosition(
    address _account,
    address _indexToken,
    address _collateralToken,
    uint256 _amountIn,
    uint256 _sizeDelta,
    bool _isLong
  ) external payable;

  function pluginDecreasePosition(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    uint256 _sizeDelta, 
    uint256 _collateralDelta, 
    bool _isLong, 
    address _receiver
  )external payable returns(uint256);

  function liquidatePosition(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    bool _isLong,
    address _feeReceiver,
    bytes[] memory _priceUpdateData
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IDipxStorage{
  struct SkewRule{
    uint256 min;             // BASIS_POINT_DIVISOR = 1
    uint256 max;             // BASIS_POINT_DIVISOR = 1
    uint256 delta;
    int256 light;            // BASIS_POINT_DIVISOR = 1
    uint256 heavy;
  }

  function initConfig(
    address _genesisPass,
    address _feeTo,
    address _vault, 
    address _lpManager, 
    address _positionManager, 
    address _priceFeed,
    address _router,
    address _referral,
    uint256 _positionFeePoints,
    uint256 _lpFeePoints,
    uint256 _fundingRateFactor,
    uint256 _gasFee
  ) external;

  function setContracts(
    address _genesisPass,
    address _feeTo,
    address _vault, 
    address _lpManager, 
    address _positionManager,
    address _priceFeed,
    address _router,
    address _handler,
    address _referral
  ) external;

  function genesisPass() external view returns(address);
  function vault() external view returns(address);
  function lpManager() external view returns(address);
  function positionManager() external view returns(address);
  function priceFeed() external view returns(address);
  function router() external view returns(address);
  function handler() external view returns(address);
  function referral() external view returns(address);

  function setGenesisPass(address _genesisPass,uint256 _gpDiscount) external;
  function setLpManager(address _lpManager) external;
  function setPositionManager(address _positionManager) external;
  function setVault(address _vault) external;
  function setPriceFeed(address _priceFeed) external;
  function setRouter(address _router) external;
  function setHandler(address _handler) external;
  function setReferral(address _referral) external;

  function feeTo() external view returns(address);
  function setFeeTo(address _feeTo) external;

  function setDefaultGasFee(uint256 _gasFee) external;
  function setTokenGasFee(address _collateralToken, bool _requireFee, uint256 _fee) external;
  function getTokenGasFee(address _collateralToken) external view returns(uint256);

  function currentFundingFactor(address _account,address _indexToken, address _collateralToken, bool _isLong) external view returns(int256);
  function cumulativeFundingRates(address indexToken, address collateralToken) external returns(uint256);
  function lastFundingTimes(address indexToken, address collateralToken) external returns(uint256);
  function setFundingInterval(uint256 _fundingInterval) external;
  function setFundingRateFactor(uint256 _fundingRateFactor) external;
  function updateCumulativeFundingRate(address _indexToken,address _collateralToken) external;
  function getFundingFee(
    address _account,
    address _indexToken, 
    address _collateralToken, 
    bool _isLong
  ) external view returns (int256);
  function setDefaultSkewRules(
    SkewRule[] memory _rules
  ) external;
  function setTokenSkewRules(
    address _collateralToken,
    SkewRule[] memory _rules
  ) external;

  function setAccountsFeePoint(
    address[] memory _accounts, 
    bool[] memory _whitelisted, 
    uint256[] memory _feePoints
  ) external;

  function setPositionFeePoints(uint256 _point,uint256 _lpPoint) external;
  function setTokenPositionFeePoints(address[] memory _lpTokens, uint256[] memory _rates) external;

  function getPositionFeePoints(address _collateralToken) external view returns(uint256);
  function getLpPositionFee(address _collateralToken,uint256 totalFee) external view returns(uint256);
  function getPositionFee(address _account,address _indexToken,address _collateralToken, uint256 _tradeAmount) external view returns(uint256);

  function setLpTaxPoints(address _pool, uint256 _buyFeePoints, uint256 _sellFeePoints) external;

  function eth() external view returns(address);
  function nativeCurrencyDecimals() external view returns(uint8);
  function nativeCurrency() external view returns(address);
  function nativeCurrencySymbol() external view returns(string memory);
  function isNativeCurrency(address token) external view returns(bool);
  function getTokenDecimals(address token) external view returns(uint256);

  function BASIS_POINT_DIVISOR() external view returns(uint256);
  function getBuyLpFeePoints(address _pool, address token,uint256 tokenDelta) external view returns(uint256);
  function getSellLpFeePoints(address _pool, address receiveToken,uint256 dlpDelta) external view returns(uint256);

  function greylist(address _account) external view returns(bool);
  function greylistAddress(address _address) external;
  function greylistedTokens(address _token) external view returns(bool);
  function setGreyListTokens(address[] memory _tokens, bool[] memory _disables) external;

  function increasePaused() external view returns(bool);
  function toggleIncrease() external;
  function tokenIncreasePaused(address _token) external view returns(bool);
  function toggleTokenIncrease(address _token) external;

  function decreasePaused() external view returns(bool);
  function toggleDecrease() external;
  function tokenDecreasePaused(address _token) external view returns(bool);
  function toggleTokenDecrease(address _token) external;

  function liquidatePaused() external view returns(bool);
  function toggleLiquidate() external;
  function tokenLiquidatePaused(address _token) external view returns(bool);
  function toggleTokenLiquidate(address _token) external;

  function maxLeverage() external view returns(uint256);
  function setMaxLeverage(uint256) external;
  
  function minProfitTime() external view returns(uint256);
  function minProfitBasisPoints(address) external view returns(uint256);
  function setMinProfit(uint256 _minProfitTime,address[] memory _indexTokens, uint256[] memory _minProfitBps) external;

  function approvedRouters(address,address) external view returns(bool);
  function approveRouter(address _router, bool _enable) external;
  function isLiquidator(address _account) external view returns (bool);
  function setLiquidator(address _liquidator, bool _isActive) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IStorageSet.sol";

interface IPositionManager is IStorageSet{
  struct Position {
    uint256 size;
    uint256 collateral;  
    uint256 averagePrice;
    uint256 entryFundingRate;
    int256 fundingFactor;
    uint256 lastIncreasedTime;
    int256 realisedPnl;
    uint256 averagePoolPrice;
    address account;
    address indexToken;
    address collateralToken;
    bool isLong;
  }

  function globalBorrowAmounts(address collateralToken) external view returns(uint256);

  function indexTokenLength() external view returns(uint256);
  function indexTokenAt(uint256 _at) external view returns(address);

  function enableIndexToken(address _indexToken,bool _enable) external;
  function toggleCollateralsAccept(address _indexToken) external;
  function addIndexCollaterals(address _indexToken,address[] memory _collateralTokens) external;
  function removeIndexCollaterals(address _indexToken,address[] memory _collateralTokens) external;

  function getMaxPrice(address _token) external view returns (uint256);
  function getMinPrice(address _token) external view returns (uint256);

  function getPositionLeverage(address _account, address _indexToken, address _collateralToken, bool _isLong) external view returns (uint256);

  function calculateUnrealisedPnl(address _indexToken, address _collateralToken) external view returns(bool, uint256);
  function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external returns (uint256, uint256);
  function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);

  function getPositionKeyLength(address _account) external view returns(uint256);
  function getPositionKeyAt(address _account, uint256 _index) external view returns(bytes32);

  function getPositionByKey(bytes32 key) external view returns(Position memory);
  function getPosition(
    address account,
    address indexToken, 
    address collateralToken, 
    bool isLong
  ) external view returns(Position memory);

  function increasePosition(
    address account,
    address indexToken, 
    address collateralToken,
    uint256 sizeDelta,
    bool isLong
  ) external payable;

  function decreasePosition(
    address account,
    address indexToken, 
    address collateralToken, 
    uint256 sizeDelta, 
    uint256 collateralDelta, 
    bool isLong, 
    address receiver
  ) external payable returns(uint256);

  function liquidatePosition(
    address account, 
    address indexToken, 
    address collateralToken, 
    bool isLong,
    address feeReceiver
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IVaultPriceFeed {
  function chainlinkPriceFeed() external view returns(address);
  function pythPriceFeed() external view returns(address);
  function eth() external view returns(address);
  function btc() external view returns(address);
  function decimals() external view returns(uint8);
  function getPrice(address _token, bool _maximise) external view returns (uint256);
  function setPythEnabled(bool _isEnabled) external;
  function setAmmEnabled(bool _isEnabled) external;
  function setTokens(address _btc, address _eth) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IPythPriceFeed{
  function getBtcUsdPrice() external view returns (int256,uint32);
  function getEthUsdPrice() external view returns (int256,uint32);
  function getPrice(address _token) external view returns (int256,uint32);
  function updatePriceFeeds(bytes[] memory _priceUpdateData) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IReferral {
    function BASIS_POINTS() external view returns(uint256);
    function setHandler(address _handler, bool _isActive) external;
    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external;
    function setReferrerTier(address _referrer, uint256 _tierId) external;
    function setTraderReferral(address _account, address _referrer) external;

    function getTraderReferralInfo(address _account) external returns(address, uint256, uint256);

    function calculateRebateAmount(address _account, uint256 _fee) external view returns(uint256);
    function rebate(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IStorageSet{
  function setDipxStorage(address _dipxStorage) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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