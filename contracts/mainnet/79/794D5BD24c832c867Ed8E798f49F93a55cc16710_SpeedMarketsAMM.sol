// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// external
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

// internal
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../utils/proxy/solidity-0.8.0/ProxyPausable.sol";
import "../utils/libraries/AddressSetLib.sol";

import "../interfaces/IStakingThales.sol";
import "../interfaces/IMultiCollateralOnOffRamp.sol";

import "./SpeedMarket.sol";

/// @title An AMM for Thales speed markets
contract SpeedMarketsAMM is Initializable, ProxyOwned, ProxyPausable, ProxyReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressSetLib for AddressSetLib.AddressSet;

    AddressSetLib.AddressSet internal _activeMarkets;
    AddressSetLib.AddressSet internal _maturedMarkets;

    uint private constant ONE = 1e18;

    IERC20Upgradeable public sUSD;

    address public speedMarketMastercopy;

    uint public safeBoxImpact;
    uint public lpFee;

    address public safeBox;

    mapping(bytes32 => bool) public supportedAsset;

    uint public minimalTimeToMaturity;
    uint public maximalTimeToMaturity;

    uint public minBuyinAmount;
    uint public maxBuyinAmount;

    mapping(bytes32 => uint) public maxRiskPerAsset;
    mapping(bytes32 => uint) public currentRiskPerAsset;

    mapping(bytes32 => bytes32) public assetToPythId;

    //eth 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace
    IPyth public pyth;

    uint64 public maximumPriceDelay;

    /// @return The address of the Staking contract
    IStakingThales public stakingThales;

    mapping(address => AddressSetLib.AddressSet) internal _activeMarketsPerUser;
    mapping(address => AddressSetLib.AddressSet) internal _maturedMarketsPerUser;

    struct MarketData {
        address user;
        bytes32 asset;
        uint64 strikeTime;
        int64 strikePrice;
        SpeedMarket.Direction direction;
        uint buyinAmount;
        bool resolved;
        int64 finalPrice;
        SpeedMarket.Direction result;
        bool isUserWinner;
    }

    mapping(address => bool) public whitelistedAddresses;
    IMultiCollateralOnOffRamp public multiCollateralOnOffRamp;
    bool public multicollateralEnabled;

    function initialize(
        address _owner,
        IERC20Upgradeable _sUSD,
        IPyth _pyth
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        sUSD = _sUSD;
        pyth = _pyth;
    }

    function createNewMarket(
        bytes32 asset,
        uint64 strikeTime,
        SpeedMarket.Direction direction,
        uint buyinAmount,
        bytes[] calldata priceUpdateData
    ) external payable nonReentrant notPaused {
        _createNewMarket(asset, strikeTime, direction, buyinAmount, priceUpdateData, true);
    }

    function createNewMarketWithDelta(
        bytes32 asset,
        uint64 delta,
        SpeedMarket.Direction direction,
        uint buyinAmount,
        bytes[] calldata priceUpdateData
    ) external payable nonReentrant notPaused {
        _createNewMarket(asset, uint64(block.timestamp + delta), direction, buyinAmount, priceUpdateData, true);
    }

    function createNewMarketWithDifferentCollateral(
        bytes32 asset,
        uint64 strikeTime,
        SpeedMarket.Direction direction,
        bytes[] calldata priceUpdateData,
        address collateral,
        uint collateralAmount,
        bool isEth
    ) external payable nonReentrant notPaused {
        require(multicollateralEnabled, "Multicollateral onramp not enabled");
        uint buyinAmount = _convertCollateral(collateral, collateralAmount, isEth);
        _createNewMarket(asset, strikeTime, direction, buyinAmount, priceUpdateData, false);
    }

    function createNewMarketWithDifferentCollateralAndDelta(
        bytes32 asset,
        uint64 delta,
        SpeedMarket.Direction direction,
        bytes[] calldata priceUpdateData,
        address collateral,
        uint collateralAmount,
        bool isEth
    ) external payable nonReentrant notPaused {
        require(multicollateralEnabled, "Multicollateral onramp not enabled");
        uint buyinAmount = _convertCollateral(collateral, collateralAmount, isEth);
        _createNewMarket(asset, uint64(block.timestamp + delta), direction, buyinAmount, priceUpdateData, false);
    }

    function _convertCollateral(
        address collateral,
        uint collateralAmount,
        bool isEth
    ) internal returns (uint buyinAmount) {
        uint convertedAmount;
        if (isEth) {
            convertedAmount = multiCollateralOnOffRamp.onrampWithEth{value: msg.value}(collateralAmount);
        } else {
            IERC20Upgradeable(collateral).safeTransferFrom(msg.sender, address(this), collateralAmount);
            IERC20Upgradeable(collateral).approve(address(multiCollateralOnOffRamp), collateralAmount);
            convertedAmount = multiCollateralOnOffRamp.onramp(collateral, collateralAmount);
        }
        buyinAmount = (convertedAmount * (ONE - safeBoxImpact - lpFee)) / ONE;
    }

    function _createNewMarket(
        bytes32 asset,
        uint64 strikeTime,
        SpeedMarket.Direction direction,
        uint buyinAmount,
        bytes[] memory priceUpdateData,
        bool transferSusd
    ) internal {
        require(supportedAsset[asset], "Asset is not supported");
        require(buyinAmount >= minBuyinAmount && buyinAmount <= maxBuyinAmount, "wrong buy in amount");
        require(
            strikeTime >= (block.timestamp + minimalTimeToMaturity),
            "time has to be in the future + minimalTimeToMaturity"
        );
        require(strikeTime <= block.timestamp + maximalTimeToMaturity, "time too far into the future");

        uint fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        PythStructs.Price memory price = pyth.getPrice(assetToPythId[asset]);

        require((price.publishTime + maximumPriceDelay) > block.timestamp, "Stale price");

        if (transferSusd) {
            uint totalAmountToTransfer = (buyinAmount * (ONE + safeBoxImpact + lpFee)) / ONE;
            sUSD.safeTransferFrom(msg.sender, address(this), totalAmountToTransfer);
        }
        SpeedMarket srm = SpeedMarket(Clones.clone(speedMarketMastercopy));
        srm.initialize(
            SpeedMarket.InitParams(address(this), msg.sender, asset, strikeTime, price.price, direction, buyinAmount)
        );

        sUSD.safeTransfer(address(srm), buyinAmount * 2);

        sUSD.safeTransfer(safeBox, (buyinAmount * safeBoxImpact) / ONE);

        _activeMarkets.add(address(srm));
        _activeMarketsPerUser[msg.sender].add(address(srm));

        currentRiskPerAsset[asset] += buyinAmount;
        require(currentRiskPerAsset[asset] < maxRiskPerAsset[asset], "OI cap breached");

        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(msg.sender, buyinAmount);
        }

        emit MarketCreated(address(srm), msg.sender, asset, strikeTime, price.price, direction, buyinAmount);
    }

    /// @notice resolveMarket resolves an active market
    /// @param market address of the market
    function resolveMarket(address market, bytes[] calldata priceUpdateData) external payable nonReentrant notPaused {
        _resolveMarket(market, priceUpdateData);
    }

    /// @notice resolveMarkets in a batch
    function resolveMarketsBatch(address[] calldata markets, bytes[] calldata priceUpdateData)
        external
        payable
        nonReentrant
        notPaused
    {
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];
            if (canResolveMarket(market)) {
                bytes[] memory subarray = new bytes[](1);
                subarray[0] = priceUpdateData[i];
                _resolveMarket(market, subarray);
            }
        }
    }

    function _resolveMarket(address market, bytes[] memory priceUpdateData) internal {
        require(_activeMarkets.contains(market), "Not an active market");
        require(SpeedMarket(market).strikeTime() < block.timestamp, "Not ready to be resolved");
        require(!SpeedMarket(market).resolved(), "Already resolved");

        uint fee = pyth.getUpdateFee(priceUpdateData);

        bytes32[] memory priceIds = new bytes32[](1);
        priceIds[0] = assetToPythId[SpeedMarket(market).asset()];
        PythStructs.PriceFeed[] memory prices = pyth.parsePriceFeedUpdates{value: fee}(
            priceUpdateData,
            priceIds,
            SpeedMarket(market).strikeTime(),
            SpeedMarket(market).strikeTime() + maximumPriceDelay
        );

        PythStructs.Price memory price = prices[0].price;

        _resolveMarketWithPrice(market, price.price);
    }

    /// @notice admin resolve market for a given market address with finalPrice
    function resolveMarketManually(address _market, int64 _finalPrice) external isAddressWhitelisted {
        _resolveMarketManually(_market, _finalPrice);
    }

    /// @notice admin resolve for a given markets with finalPrices
    function resolveMarketManuallyBatch(address[] calldata markets, int64[] calldata finalPrices)
        external
        isAddressWhitelisted
    {
        for (uint i = 0; i < markets.length; i++) {
            if (canResolveMarket(markets[i])) {
                _resolveMarketManually(markets[i], finalPrices[i]);
            }
        }
    }

    function _resolveMarketManually(address _market, int64 _finalPrice) internal {
        require(_activeMarkets.contains(_market), "Not an active market");
        require(SpeedMarket(_market).strikeTime() < block.timestamp, "Not ready to be resolved");
        require(!SpeedMarket(_market).resolved(), "Already resolved");
        _resolveMarketWithPrice(_market, _finalPrice);
    }

    function _resolveMarketWithPrice(address market, int64 _finalPrice) internal {
        SpeedMarket(market).resolve(_finalPrice);
        _activeMarkets.remove(market);
        _maturedMarkets.add(market);
        address user = SpeedMarket(market).user();

        if (_activeMarketsPerUser[user].contains(market)) {
            _activeMarketsPerUser[user].remove(market);
        }
        _maturedMarketsPerUser[user].add(market);

        if (!SpeedMarket(market).isUserWinner()) {
            if (currentRiskPerAsset[SpeedMarket(market).asset()] > SpeedMarket(market).buyinAmount()) {
                currentRiskPerAsset[SpeedMarket(market).asset()] -= (SpeedMarket(market).buyinAmount());
            } else {
                currentRiskPerAsset[SpeedMarket(market).asset()] = 0;
            }
        }

        emit MarketResolved(market, SpeedMarket(market).result(), SpeedMarket(market).isUserWinner());
    }

    //////////// getters for active and matured markets/////////////////

    /// @notice isKnownMarket checks if market is among matured or active markets
    /// @param candidate Address of the market.
    /// @return bool
    function isKnownMarket(address candidate) public view returns (bool) {
        return _activeMarkets.contains(candidate) || _maturedMarkets.contains(candidate);
    }

    /// @notice isActiveMarket checks if market is active market
    /// @param candidate Address of the market.
    /// @return bool
    function isActiveMarket(address candidate) public view returns (bool) {
        return _activeMarkets.contains(candidate);
    }

    /// @notice numActiveMarkets returns number of active markets
    /// @return uint
    function numActiveMarkets() external view returns (uint) {
        return _activeMarkets.elements.length;
    }

    /// @notice activeMarkets returns list of active markets
    /// @param index index of the page
    /// @param pageSize number of addresses per page
    /// @return address[] active market list
    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory) {
        return _activeMarkets.getPage(index, pageSize);
    }

    /// @notice numMaturedMarkets returns number of mature markets
    /// @return uint
    function numMaturedMarkets() external view returns (uint) {
        return _maturedMarkets.elements.length;
    }

    /// @notice maturedMarkets returns list of matured markets
    /// @param index index of the page
    /// @param pageSize number of addresses per page
    /// @return address[] matured market list
    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory) {
        return _maturedMarkets.getPage(index, pageSize);
    }

    /// @notice numActiveMarkets returns number of active markets per use
    function numActiveMarketsPerUser(address user) external view returns (uint) {
        return _activeMarketsPerUser[user].elements.length;
    }

    /// @notice activeMarkets returns list of active markets per user
    function activeMarketsPerUser(
        uint index,
        uint pageSize,
        address user
    ) external view returns (address[] memory) {
        return _activeMarketsPerUser[user].getPage(index, pageSize);
    }

    /// @notice numMaturedMarkets returns number of matured markets per use
    function numMaturedMarketsPerUser(address user) external view returns (uint) {
        return _maturedMarketsPerUser[user].elements.length;
    }

    /// @notice maturedMarkets returns list of matured markets per user
    function maturedMarketsPerUser(
        uint index,
        uint pageSize,
        address user
    ) external view returns (address[] memory) {
        return _maturedMarketsPerUser[user].getPage(index, pageSize);
    }

    /// @notice whether a market can be resolved
    function canResolveMarket(address market) public view returns (bool) {
        return
            _activeMarkets.contains(market) &&
            (SpeedMarket(market).strikeTime() < block.timestamp) &&
            !SpeedMarket(market).resolved();
    }

    /// @notice return all market data for an array of markets
    function getMarketsData(address[] calldata marketsArray) external view returns (MarketData[] memory) {
        MarketData[] memory markets = new MarketData[](marketsArray.length);
        for (uint i = 0; i < marketsArray.length; i++) {
            SpeedMarket market = SpeedMarket(marketsArray[i]);
            markets[i].user = market.user();
            markets[i].asset = market.asset();
            markets[i].strikeTime = market.strikeTime();
            markets[i].strikePrice = market.strikePrice();
            markets[i].direction = market.direction();
            markets[i].buyinAmount = market.buyinAmount();
            markets[i].resolved = market.resolved();
            markets[i].finalPrice = market.finalPrice();
            markets[i].result = market.result();
            markets[i].isUserWinner = market.isUserWinner();
        }
        return markets;
    }

    //////////////////setters/////////////////

    /// @notice Set mastercopy to use to create markets
    /// @param _mastercopy to use to create markets
    function setMastercopy(address _mastercopy) external onlyOwner {
        speedMarketMastercopy = _mastercopy;
        emit MastercopyChanged(_mastercopy);
    }

    /// @notice Set minimum and maximum buyin amounts
    function setAmounts(uint _minBuyinAmount, uint _maxBuyinAmount) external onlyOwner {
        minBuyinAmount = _minBuyinAmount;
        maxBuyinAmount = _maxBuyinAmount;
        emit AmountsChanged(_minBuyinAmount, _maxBuyinAmount);
    }

    /// @notice Set minimum and maximum time to maturity
    function setTimes(uint _minimalTimeToMaturity, uint _maximalTimeToMaturity) external onlyOwner {
        minimalTimeToMaturity = _minimalTimeToMaturity;
        maximalTimeToMaturity = _maximalTimeToMaturity;
        emit TimesChanged(_minimalTimeToMaturity, _maximalTimeToMaturity);
    }

    /// @notice map asset to PythID, e.g. "ETH" as bytes 32 to an equivalent ID from pyth docs
    function setAssetToPythID(bytes32 asset, bytes32 pythId) external onlyOwner {
        assetToPythId[asset] = pythId;
        emit SetAssetToPythID(asset, pythId);
    }

    /// @notice whats the longest a price can be delayed
    function setMaximumPriceDelay(uint64 _maximumPriceDelay) external onlyOwner {
        maximumPriceDelay = _maximumPriceDelay;
        emit SetMaximumPriceDelay(maximumPriceDelay);
    }

    /// @notice maximum open interest per asset
    function setMaxRiskPerAsset(bytes32 asset, uint _maxRiskPerAsset) external onlyOwner {
        maxRiskPerAsset[asset] = _maxRiskPerAsset;
        emit SetMaxRiskPerAsset(asset, _maxRiskPerAsset);
    }

    /// @notice set SafeBox params
    function setSafeBoxParams(address _safeBox, uint _safeBoxImpact) external onlyOwner {
        safeBox = _safeBox;
        safeBoxImpact = _safeBoxImpact;
        emit SetSafeBoxParams(_safeBox, _safeBoxImpact);
    }

    /// @notice set LP fee
    function setLPFee(uint _lpFee) external onlyOwner {
        lpFee = _lpFee;
        emit SetLPFee(_lpFee);
    }

    /// @notice Set staking thales
    function setStakingThales(address _stakingThales) external onlyOwner {
        //TODO: dont set till StakingThalesBonusRewardsManager is ready for it
        stakingThales = IStakingThales(_stakingThales);
        emit SetStakingThales(_stakingThales);
    }

    /// @notice set whether an asset is supported
    function setSupportedAsset(bytes32 asset, bool _supported) external onlyOwner {
        supportedAsset[asset] = _supported;
        emit SetSupportedAsset(asset, _supported);
    }

    /// @notice set multicollateral onramp contract
    function setMultiCollateralOnOffRamp(address _onramper, bool enabled) external onlyOwner {
        multiCollateralOnOffRamp = IMultiCollateralOnOffRamp(_onramper);
        multicollateralEnabled = enabled;
        emit SetMultiCollateralOnOffRamp(_onramper, enabled);
    }

    /// @notice adding/removing whitelist address depending on a flag
    /// @param _whitelistAddress address that needed to be whitelisted/ ore removed from WL
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function addToWhitelist(address _whitelistAddress, bool _flag) external onlyOwner {
        require(_whitelistAddress != address(0) && whitelistedAddresses[_whitelistAddress] != _flag);
        whitelistedAddresses[_whitelistAddress] = _flag;
        emit AddedIntoWhitelist(_whitelistAddress, _flag);
    }

    //////////////////modifiers/////////////////

    modifier isAddressWhitelisted() {
        require(whitelistedAddresses[msg.sender], "ID10");
        _;
    }

    //////////////////events/////////////////

    event MarketCreated(
        address market,
        address user,
        bytes32 asset,
        uint strikeTime,
        int64 strikePrice,
        SpeedMarket.Direction direction,
        uint buyinAmount
    );

    event MarketResolved(address market, SpeedMarket.Direction result, bool userIsWinner);

    event MastercopyChanged(address mastercopy);
    event AmountsChanged(uint _minBuyinAmount, uint _maxBuyinAmount);
    event TimesChanged(uint _minimalTimeToMaturity, uint _maximalTimeToMaturity);
    event SetAssetToPythID(bytes32 asset, bytes32 pythId);
    event SetMaximumPriceDelay(uint _maximumPriceDelay);
    event SetMaxRiskPerAsset(bytes32 asset, uint _maxRiskPerAsset);
    event SetSafeBoxParams(address _safeBox, uint _safeBoxImpact);
    event SetLPFee(uint _lpFee);
    event SetStakingThales(address _stakingThales);
    event SetSupportedAsset(bytes32 asset, bool _supported);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event SetMultiCollateralOnOffRamp(address _onramper, bool enabled);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./ProxyOwned.sol";

// Clone of syntetix contract without constructor

contract ProxyPausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressSetLib {
    struct AddressSet {
        address[] elements;
        mapping(address => uint) indices;
    }

    function contains(AddressSet storage set, address candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getPage(
        AddressSet storage set,
        uint index,
        uint pageSize
    ) internal view returns (address[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new address[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        address[] memory page = new address[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(AddressSet storage set, address element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(AddressSet storage set, address element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            address shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IStakingThales {
    function updateVolume(address account, uint amount) external;

    /* ========== VIEWS / VARIABLES ==========  */
    function totalStakedAmount() external view returns (uint);

    function stakedBalanceOf(address account) external view returns (uint);

    function currentPeriodRewards() external view returns (uint);

    function currentPeriodFees() external view returns (uint);

    function getLastPeriodOfClaimedRewards(address account) external view returns (uint);

    function getRewardsAvailable(address account) external view returns (uint);

    function getRewardFeesAvailable(address account) external view returns (uint);

    function getAlreadyClaimedRewards(address account) external view returns (uint);

    function getContractRewardFunds() external view returns (uint);

    function getContractFeeFunds() external view returns (uint);

    function getAMMVolume(address account) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IMultiCollateralOnOffRamp {
    function onramp(address collateral, uint collateralAmount) external returns (uint);

    function onrampWithEth(uint amount) external payable returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./SpeedMarketsAMM.sol";

contract SpeedMarket {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct InitParams {
        address _speedMarketsAMM;
        address _user;
        bytes32 _asset;
        uint64 _strikeTime;
        int64 _strikePrice;
        Direction _direction;
        uint _buyinAmount;
    }

    enum Direction {
        Up,
        Down
    }

    address public user;
    bytes32 public asset;
    uint64 public strikeTime;
    int64 public strikePrice;
    Direction public direction;
    uint public buyinAmount;

    bool public resolved;
    int64 public finalPrice;
    Direction public result;

    SpeedMarketsAMM public speedMarketsAMM;

    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(InitParams calldata params) external {
        require(!initialized, "Speed  market already initialized");
        speedMarketsAMM = SpeedMarketsAMM(params._speedMarketsAMM);
        user = params._user;
        asset = params._asset;
        strikeTime = params._strikeTime;
        strikePrice = params._strikePrice;
        direction = params._direction;
        buyinAmount = params._buyinAmount;
        speedMarketsAMM.sUSD().approve(params._speedMarketsAMM, type(uint256).max);
    }

    function resolve(int64 _finalPrice) external onlyAMM {
        require(!resolved, "already resolved");
        require(block.timestamp > strikeTime, "not ready to be resolved");
        resolved = true;
        finalPrice = _finalPrice;

        if (finalPrice < strikePrice) {
            result = Direction.Down;
        } else {
            result = Direction.Up;
        }

        if (direction == result) {
            speedMarketsAMM.sUSD().safeTransfer(user, speedMarketsAMM.sUSD().balanceOf(address(this)));
        } else {
            speedMarketsAMM.sUSD().safeTransfer(address(speedMarketsAMM), speedMarketsAMM.sUSD().balanceOf(address(this)));
        }

        emit Resolved(finalPrice, result, direction == result);
    }

    function isUserWinner() external view returns (bool) {
        return resolved && (direction == result);
    }

    modifier onlyAMM() {
        require(msg.sender == address(speedMarketsAMM), "only the AMM may perform these methods");
        _;
    }

    event Resolved(int64 finalPrice, Direction result, bool userIsWinner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}