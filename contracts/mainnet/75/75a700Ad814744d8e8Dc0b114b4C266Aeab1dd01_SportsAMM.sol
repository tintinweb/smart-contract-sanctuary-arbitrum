// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// internal
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

// interface
import "../interfaces/ISportPositionalMarket.sol";
import "../interfaces/ISportPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IStakingThales.sol";
import "../interfaces/ITherundownConsumer.sol";
import "../interfaces/ICurveSUSD.sol";
import "../interfaces/IReferrals.sol";
import "../interfaces/ISportsAMM.sol";
import "../interfaces/ITherundownConsumerWrapper.sol";

import "./SportsAMMUtils.sol";
import "./LiquidityPool/SportAMMLiquidityPool.sol";

/// @title Sports AMM contract
/// @author kirilaa
contract SportsAMM is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint private constant ONE = 1e18;
    uint private constant ZERO_POINT_ONE = 1e17;
    uint private constant ONE_PERCENT = 1e16;
    uint private constant MAX_APPROVAL = type(uint256).max;

    /// @return The sUSD contract used for payment
    IERC20Upgradeable public sUSD;

    /// @return The address of the SportsPositionalManager contract
    address public manager;

    /// @notice Each game has `defaultCapPerGame` available for trading
    /// @return The default cap per game.
    uint public defaultCapPerGame;

    /// @return The minimal spread/skrew percentage
    uint public min_spread;

    /// @return The maximum spread/skrew percentage
    uint public max_spread;

    /// @notice Each game will be restricted for AMM trading `minimalTimeLeftToMaturity` seconds before is mature
    /// @return The period of time before a game is matured and begins to be restricted for AMM trading
    uint public minimalTimeLeftToMaturity;

    enum Position {
        Home,
        Away,
        Draw
    }

    /// @return The sUSD amount bought from AMM by users for the market
    mapping(address => uint) public spentOnGame;

    /// @return The SafeBox address
    address public safeBox;

    /// @return The address of Therundown Consumer
    address public theRundownConsumer;

    /// @return The percentage that goes to SafeBox
    uint public safeBoxImpact;

    /// @return The address of the Staking contract
    IStakingThales public stakingThales;

    /// @return The minimum supported odd
    uint public minSupportedOdds;

    /// @return The maximum supported odd
    uint public maxSupportedOdds;

    /// @return The address of the Curve contract for multi-collateral
    ICurveSUSD public curveSUSD;

    /// @return The address of USDC
    address public usdc;

    /// @return The address of USDT (Tether)
    address public usdt;

    /// @return The address of DAI
    address public dai;

    /// @return Curve usage is enabled?
    bool public curveOnrampEnabled;

    /// @return Referrals contract address
    address public referrals;

    /// @return Default referrer fee
    uint public referrerFee;

    /// @return The address of Parlay AMM
    address public parlayAMM;

    /// @return The address of Apex Consumer
    address public apexConsumer; // deprecated

    /// @return maximum supported discount in percentage on sUSD purchases with different collaterals
    uint public maxAllowedPegSlippagePercentage;

    /// @return the cap per sportID. based on the tagID
    mapping(uint => uint) public capPerSport;

    SportsAMMUtils public sportAmmUtils;

    /// @return the cap per market. based on the marketId
    mapping(address => uint) public capPerMarket;

    /// @notice odds threshold which will trigger odds update
    /// @return The threshold.
    uint public thresholdForOddsUpdate;

    /// @return The address of wrapper contract
    ITherundownConsumerWrapper public wrapper;

    // @return specific SafeBoxFee per address
    mapping(address => uint) public safeBoxFeePerAddress;

    // @return specific min_spread per address
    mapping(address => uint) public min_spreadPerAddress;

    /// @return the cap per sportID and childID. based on the tagID[0] and tagID[1]
    mapping(uint => mapping(uint => uint)) public capPerSportAndChild;

    struct BuyFromAMMParams {
        address market;
        ISportsAMM.Position position;
        uint amount;
        uint expectedPayout;
        uint additionalSlippage;
        bool sendSUSD;
        uint sUSDPaid;
    }

    struct DoubleChanceStruct {
        bool isDoubleChance;
        ISportsAMM.Position position1;
        ISportsAMM.Position position2;
        address parentMarket;
    }

    /// @return the adddress of the AMMLP contract
    SportAMMLiquidityPool public liquidityPool;

    // @return specific min_spread per address
    mapping(uint => mapping(uint => uint)) public minSpreadPerSport;

    /// @notice Initialize the storage in the proxy contract with the parameters.
    /// @param _owner Owner for using the ownerOnly functions
    /// @param _sUSD The payment token (sUSD)
    /// @param _min_spread Minimal spread (percentage)
    /// @param _max_spread Maximum spread (percentage)
    /// @param _minimalTimeLeftToMaturity Period to close AMM trading befor maturity
    function initialize(
        address _owner,
        IERC20Upgradeable _sUSD,
        uint _defaultCapPerGame,
        uint _min_spread,
        uint _max_spread,
        uint _minimalTimeLeftToMaturity
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        sUSD = _sUSD;
        defaultCapPerGame = _defaultCapPerGame;
        min_spread = _min_spread;
        max_spread = _max_spread;
        minimalTimeLeftToMaturity = _minimalTimeLeftToMaturity;
    }

    /// @notice Returns the available position options to buy from AMM for specific market/game
    /// @param market The address of the SportPositional market created for a game
    /// @param position The position (home/away/draw) to check availability
    /// @return _available The amount of position options (tokens) available to buy from AMM.
    function availableToBuyFromAMM(address market, ISportsAMM.Position position) public view returns (uint _available) {
        if (isMarketInAMMTrading(market)) {
            uint baseOdds = _obtainOdds(market, position);
            if (baseOdds > 0) {
                _available = _availableToBuyFromAMMInternal(
                    market,
                    position,
                    baseOdds,
                    0,
                    false,
                    _getDoubleChanceStruct(market)
                );
            }
        }
    }

    /// @notice Calculate the sUSD cost to buy an amount of available position options from AMM for specific market/game
    /// @param market The address of the SportPositional market of a game
    /// @param position The position (home/away/draw) quoted to buy from AMM
    /// @param amount The position amount quoted to buy from AMM
    /// @return _quote The sUSD cost for buying the `amount` of `position` options (tokens) from AMM for `market`.
    function buyFromAmmQuote(
        address market,
        ISportsAMM.Position position,
        uint amount
    ) public view returns (uint _quote) {
        if (isMarketInAMMTrading(market)) {
            uint baseOdds = _obtainOdds(market, position);
            if (baseOdds > 0) {
                baseOdds = baseOdds < minSupportedOdds ? minSupportedOdds : baseOdds;
                _quote = _buyFromAmmQuoteWithBaseOdds(
                    market,
                    position,
                    amount,
                    baseOdds,
                    safeBoxImpact,
                    0,
                    false,
                    true,
                    _getDoubleChanceStruct(market)
                );
            }
        }
    }

    function _buyFromAmmQuoteWithBaseOdds(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint baseOdds,
        uint useSafeBoxSkewImpact,
        uint available,
        bool useAvailable,
        bool useDefaultMinSpread,
        DoubleChanceStruct memory dcs
    ) internal view returns (uint returnQuote) {
        if (dcs.isDoubleChance) {
            returnQuote = _buyFromAMMQuoteDoubleChance(
                market,
                position,
                amount,
                useSafeBoxSkewImpact,
                useDefaultMinSpread,
                dcs
            );
        } else {
            returnQuote = _buyFromAmmQuoteWithBaseOddsInternal(
                market,
                position,
                amount,
                baseOdds,
                useSafeBoxSkewImpact,
                available,
                useAvailable,
                useDefaultMinSpread
            );
        }
    }

    function _buyFromAmmQuoteWithBaseOddsInternal(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint baseOdds,
        uint useSafeBoxSkewImpact,
        uint available,
        bool useAvailable,
        bool useDefaultMinSpread
    ) internal view returns (uint returnQuote) {
        uint _available = useAvailable
            ? available
            : _availableToBuyFromAMMWithBaseOdds(market, position, baseOdds, 0, false);
        uint _availableOtherSide = _getAvailableOtherSide(market, position);
        if (amount <= _available) {
            int skewImpact = _buyPriceImpact(market, position, amount, _available, _availableOtherSide);

            baseOdds = (baseOdds * (ONE + _getMinSpreadToUse(useDefaultMinSpread, market))) / ONE;

            int tempQuote = sportAmmUtils.calculateTempQuote(skewImpact, baseOdds, useSafeBoxSkewImpact, amount);
            returnQuote = ISportPositionalMarketManager(manager).transformCollateral(uint(tempQuote));
        }
    }

    function _getTagsForMarket(address _market) internal view returns (uint tag1, uint tag2) {
        ISportPositionalMarket sportMarket = ISportPositionalMarket(_market);
        tag1 = sportMarket.tags(0);
        tag2 = sportMarket.isChild() ? sportMarket.tags(1) : 0;
    }

    function _getMinSpreadToUse(bool useDefaultMinSpread, address market) internal view returns (uint min_spreadToUse) {
        (uint tag1, uint tag2) = _getTagsForMarket(market);
        uint spreadForTag = tag2 > 0 && minSpreadPerSport[tag1][tag2] > 0
            ? minSpreadPerSport[tag1][tag2]
            : minSpreadPerSport[tag1][0];
        min_spreadToUse = useDefaultMinSpread
            ? (spreadForTag > 0 ? spreadForTag : min_spread)
            : (
                min_spreadPerAddress[msg.sender] > 0
                    ? min_spreadPerAddress[msg.sender]
                    : (spreadForTag > 0 ? spreadForTag : min_spread)
            );
    }

    function _buyFromAMMQuoteDoubleChance(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint useSafeBoxSkewImpact,
        bool useDefaultMinSpread,
        DoubleChanceStruct memory dcs
    ) internal view returns (uint returnQuote) {
        if (position == ISportsAMM.Position.Home) {
            (uint baseOdds1, uint baseOdds2) = sportAmmUtils.getBaseOddsForDoubleChance(market, minSupportedOdds);

            if (baseOdds1 > 0 && baseOdds2 > 0) {
                uint firstQuote = _buyFromAmmQuoteWithBaseOddsInternal(
                    dcs.parentMarket,
                    dcs.position1,
                    amount,
                    baseOdds1,
                    useSafeBoxSkewImpact,
                    0,
                    false,
                    useDefaultMinSpread
                );
                uint secondQuote = _buyFromAmmQuoteWithBaseOddsInternal(
                    dcs.parentMarket,
                    dcs.position2,
                    amount,
                    baseOdds2,
                    useSafeBoxSkewImpact,
                    0,
                    false,
                    useDefaultMinSpread
                );

                if (firstQuote > 0 && secondQuote > 0) {
                    returnQuote = firstQuote + secondQuote;
                }
            }
        }
    }

    function _getAvailableOtherSide(address market, ISportsAMM.Position position)
        internal
        view
        returns (uint _availableOtherSide)
    {
        ISportsAMM.Position positionFirst = ISportsAMM.Position((uint(position) + 1) % 3);
        ISportsAMM.Position positionSecond = ISportsAMM.Position((uint(position) + 2) % 3);

        (uint _availableOtherSideFirst, uint _availableOtherSideSecond) = _getAvailableForPositions(
            market,
            positionFirst,
            positionSecond
        );

        _availableOtherSide = _availableOtherSideFirst > _availableOtherSideSecond
            ? _availableOtherSideFirst
            : _availableOtherSideSecond;
    }

    function _getAvailableForPositions(
        address market,
        ISportsAMM.Position positionFirst,
        ISportsAMM.Position positionSecond
    ) internal view returns (uint _availableOtherSideFirst, uint _availableOtherSideSecond) {
        (uint baseOddsFirst, uint baseOddsSecond) = sportAmmUtils.obtainOddsMulti(market, positionFirst, positionSecond);
        baseOddsFirst = baseOddsFirst < minSupportedOdds ? minSupportedOdds : baseOddsFirst;
        baseOddsSecond = baseOddsSecond < minSupportedOdds ? minSupportedOdds : baseOddsSecond;

        (uint balanceFirst, uint balanceSecond) = sportAmmUtils.getBalanceOfPositionsOnMarketByPositions(
            market,
            liquidityPool.getMarketPool(market),
            positionFirst,
            positionSecond
        );

        _availableOtherSideFirst = _availableToBuyFromAMMWithBaseOdds(
            market,
            positionFirst,
            baseOddsFirst,
            balanceFirst,
            true
        );
        _availableOtherSideSecond = _availableToBuyFromAMMWithBaseOdds(
            market,
            positionSecond,
            baseOddsSecond,
            balanceSecond,
            true
        );
    }

    /// @notice Calculate the sUSD cost to buy an amount of available position options from AMM for specific market/game
    /// @param market The address of the SportPositional market of a game
    /// @param position The position (home/away/draw) quoted to buy from AMM
    /// @param amount The position amount quoted to buy from AMM
    /// @return _quote The sUSD cost for buying the `amount` of `position` options (tokens) from AMM for `market`.
    function buyFromAmmQuoteForParlayAMM(
        address market,
        ISportsAMM.Position position,
        uint amount
    ) public view returns (uint _quote) {
        uint baseOdds = _obtainOdds(market, position);
        baseOdds = (baseOdds > 0 && baseOdds < minSupportedOdds) ? minSupportedOdds : baseOdds;
        _quote = _buyFromAmmQuoteWithBaseOdds(
            market,
            position,
            amount,
            baseOdds,
            0,
            0,
            false,
            true,
            _getDoubleChanceStruct(market)
        );
    }

    /// @notice Calculate the sUSD cost to buy an amount of available position options from AMM for specific market/game
    /// @param market The address of the SportPositional market of a game
    /// @param position The position (home/away/draw) quoted to buy from AMM
    /// @param amount The position amount quoted to buy from AMM
    /// @param collateral The position amount quoted to buy from AMM
    /// @return collateralQuote The sUSD cost for buying the `amount` of `position` options (tokens) from AMM for `market`.
    /// @return sUSDToPay The sUSD cost for buying the `amount` of `position` options (tokens) from AMM for `market`.
    function buyFromAmmQuoteWithDifferentCollateral(
        address market,
        ISportsAMM.Position position,
        uint amount,
        address collateral
    ) public view returns (uint collateralQuote, uint sUSDToPay) {
        int128 curveIndex = _mapCollateralToCurveIndex(collateral);
        if (curveIndex > 0 && curveOnrampEnabled) {
            sUSDToPay = buyFromAmmQuote(market, position, amount);
            //cant get a quote on how much collateral is needed from curve for sUSD,
            //so rather get how much of collateral you get for the sUSD quote and add 0.2% to that
            collateralQuote = (curveSUSD.get_dy_underlying(0, curveIndex, sUSDToPay) * (ONE + (ONE_PERCENT / 5))) / ONE;
        }
    }

    /// @notice Calculates the buy price impact for given position amount. Changes with every new purchase.
    /// @param market The address of the SportPositional market of a game
    /// @param position The position (home/away/draw) for which the buy price impact is calculated
    /// @param amount The position amount to calculate the buy price impact
    /// @return impact The buy price impact after the buy of the amount of positions for market
    function buyPriceImpact(
        address market,
        ISportsAMM.Position position,
        uint amount
    ) public view returns (int impact) {
        if (ISportPositionalMarketManager(manager).isDoubleChanceMarket(market)) {
            if (position == ISportsAMM.Position.Home) {
                (ISportsAMM.Position position1, ISportsAMM.Position position2, address parentMarket) = sportAmmUtils
                    .getParentMarketPositions(market);

                int firstPriceImpact = buyPriceImpact(parentMarket, position1, amount);
                int secondPriceImpact = buyPriceImpact(parentMarket, position2, amount);

                impact = (firstPriceImpact + secondPriceImpact) / 2;
            }
        } else {
            uint _availableToBuyFromAMM = availableToBuyFromAMM(market, position);
            uint _availableOtherSide = _getAvailableOtherSide(market, position);
            if (amount > 0 && amount <= _availableToBuyFromAMM) {
                impact = _buyPriceImpact(market, position, amount, _availableToBuyFromAMM, _availableOtherSide);
            }
        }
    }

    /// @notice Obtains the oracle odds for `_position` of a given `_market` game. Odds do not contain price impact
    /// @param _market The address of the SportPositional market of a game
    /// @param _position The position (home/away/draw) to get the odds
    /// @return oddsToReturn The oracle odds for `_position` of a `_market`
    function obtainOdds(address _market, ISportsAMM.Position _position) external view returns (uint oddsToReturn) {
        oddsToReturn = _obtainOdds(_market, _position);
    }

    /// @notice Checks if a `market` is active for AMM trading
    /// @param market The address of the SportPositional market of a game
    /// @return isTrading Returns true if market is active, returns false if not active.
    function isMarketInAMMTrading(address market) public view returns (bool isTrading) {
        if (ISportPositionalMarketManager(manager).isActiveMarket(market)) {
            (uint maturity, ) = ISportPositionalMarket(market).times();
            if (maturity >= block.timestamp) {
                isTrading = (maturity - block.timestamp) > minimalTimeLeftToMaturity;
            }
        }
    }

    /// @notice Checks the default odds for a `_market`. These odds take into account the price impact.
    /// @param _market The address of the SportPositional market of a game
    /// @return odds Returns the default odds for the `_market` including the price impact.
    function getMarketDefaultOdds(address _market, bool isSell) public view returns (uint[] memory odds) {
        odds = new uint[](ISportPositionalMarket(_market).optionsCount());
        if (isMarketInAMMTrading(_market)) {
            for (uint i = 0; i < odds.length; i++) {
                odds[i] = buyFromAmmQuote(_market, ISportsAMM.Position(i), ONE);
            }
        }
    }

    // write methods

    /// @notice Buy amount of position for market/game from AMM using different collateral
    /// @param market The address of the SportPositional market of a game
    /// @param position The position (home/away/draw) to buy from AMM
    /// @param amount The position amount to buy from AMM
    /// @param expectedPayout The amount expected to pay in sUSD for the amount of position. Obtained by buyAMMQuote.
    /// @param additionalSlippage The slippage percentage for the payout
    /// @param collateral The address of the collateral used
    /// @param _referrer who referred the buyer to SportsAMM
    function buyFromAMMWithDifferentCollateralAndReferrer(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage,
        address collateral,
        address _referrer
    ) public nonReentrant whenNotPaused {
        if (_referrer != address(0)) {
            IReferrals(referrals).setReferrer(_referrer, msg.sender);
        }
        _buyFromAMMWithDifferentCollateral(market, position, amount, expectedPayout, additionalSlippage, collateral);
    }

    /// @notice Buy amount of position for market/game from AMM using different collateral
    /// @param market The address of the SportPositional market of a game
    /// @param position The position (home/away/draw) to buy from AMM
    /// @param amount The position amount to buy from AMM
    /// @param expectedPayout The amount expected to pay in sUSD for the amount of position. Obtained by buyAMMQuote.
    /// @param additionalSlippage The slippage percentage for the payout
    /// @param collateral The address of the collateral used
    function buyFromAMMWithDifferentCollateral(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage,
        address collateral
    ) public nonReentrant whenNotPaused {
        _buyFromAMMWithDifferentCollateral(market, position, amount, expectedPayout, additionalSlippage, collateral);
    }

    /// @notice Buy amount of position for market/game from AMM using sUSD
    /// @param market The address of the SportPositional market of a game
    /// @param position The position (home/away/draw) to buy from AMM
    /// @param amount The position amount to buy from AMM
    /// @param expectedPayout The sUSD amount expected to pay for buyuing the position amount. Obtained by buyAMMQuote.
    /// @param additionalSlippage The slippage percentage for the payout
    function buyFromAMM(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) public nonReentrant whenNotPaused {
        _buyFromAMM(BuyFromAMMParams(market, position, amount, expectedPayout, additionalSlippage, true, 0));
    }

    /// @notice Buy amount of position for market/game from AMM using sUSD
    /// @param market The address of the SportPositional market of a game
    /// @param position The position (home/away/draw) to buy from AMM
    /// @param amount The position amount to buy from AMM
    /// @param expectedPayout The sUSD amount expected to pay for buying the position amount. Obtained by buyAMMQuote.
    /// @param additionalSlippage The slippage percentage for the payout
    function buyFromAMMWithReferrer(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage,
        address _referrer
    ) public nonReentrant whenNotPaused {
        if (_referrer != address(0)) {
            IReferrals(referrals).setReferrer(_referrer, msg.sender);
        }
        _buyFromAMM(BuyFromAMMParams(market, position, amount, expectedPayout, additionalSlippage, true, 0));
    }

    /// @notice Send tokens from this contract to the destination address
    /// @param tokens to iterate and transfer
    /// @param account Address where to send the tokens
    /// @param amount Amount of tokens to be sent
    /// @param all ignore amount and send whole balance
    function transferTokens(
        address[] calldata tokens,
        address payable account,
        uint amount,
        bool all
    ) external onlyOwner {
        require(tokens.length > 0, "tokens array cant be empty");
        for (uint256 index = 0; index < tokens.length; index++) {
            if (all) {
                IERC20Upgradeable(tokens[index]).safeTransfer(
                    account,
                    IERC20Upgradeable(tokens[index]).balanceOf(address(this))
                );
            } else {
                IERC20Upgradeable(tokens[index]).safeTransfer(account, amount);
            }
        }
    }

    // setters
    /// @notice Setting all key parameters for AMM
    /// @param _minimalTimeLeftToMaturity The time period in seconds.
    /// @param _minSpread Minimum spread percentage expressed in ether unit (uses 18 decimals -> 1% = 0.01*1e18)
    /// @param _maxSpread Maximum spread percentage expressed in ether unit (uses 18 decimals -> 1% = 0.01*1e18)
    /// @param _minSupportedOdds Minimal oracle odd in ether unit (18 decimals)
    /// @param _maxSupportedOdds Maximum oracle odds in ether unit (18 decimals)
    /// @param _defaultCapPerGame Default sUSD cap per market (18 decimals)
    /// @param _safeBoxImpact Percentage expressed in ether unit (uses 18 decimals -> 1% = 0.01*1e18)
    /// @param _referrerFee how much of a fee to pay to referrers
    function setParameters(
        uint _minimalTimeLeftToMaturity,
        uint _minSpread,
        uint _maxSpread,
        uint _minSupportedOdds,
        uint _maxSupportedOdds,
        uint _defaultCapPerGame,
        uint _safeBoxImpact,
        uint _referrerFee,
        uint _threshold
    ) external onlyOwner {
        minimalTimeLeftToMaturity = _minimalTimeLeftToMaturity;
        min_spread = _minSpread;
        max_spread = _maxSpread;
        minSupportedOdds = _minSupportedOdds;
        maxSupportedOdds = _maxSupportedOdds;
        defaultCapPerGame = _defaultCapPerGame;
        safeBoxImpact = _safeBoxImpact;
        referrerFee = _referrerFee;
        thresholdForOddsUpdate = _threshold;

        emit ParametersUpdated(
            _minimalTimeLeftToMaturity,
            _minSpread,
            _maxSpread,
            _minSupportedOdds,
            _maxSupportedOdds,
            _defaultCapPerGame,
            _safeBoxImpact,
            _referrerFee,
            _threshold
        );
    }

    /// @notice Setting the main addresses for SportsAMM
    /// @param _safeBox Address of the Safe Box
    /// @param _sUSD Address of the sUSD
    /// @param _theRundownConsumer Address of Therundown consumer
    /// @param _stakingThales Address of Staking contract
    /// @param _referrals contract for referrals storage
    /// @param _wrapper contract for calling wrapper contract
    /// @param _lp contract for managing liquidity pools
    function setAddresses(
        address _safeBox,
        IERC20Upgradeable _sUSD,
        address _theRundownConsumer,
        IStakingThales _stakingThales,
        address _referrals,
        address _parlayAMM,
        address _wrapper,
        address _lp
    ) external onlyOwner {
        safeBox = _safeBox;
        sUSD = _sUSD;
        theRundownConsumer = _theRundownConsumer;
        stakingThales = _stakingThales;
        referrals = _referrals;
        parlayAMM = _parlayAMM;
        wrapper = ITherundownConsumerWrapper(_wrapper);
        liquidityPool = SportAMMLiquidityPool(_lp);

        emit AddressesUpdated(_safeBox, _sUSD, _theRundownConsumer, _stakingThales, _referrals, _parlayAMM, _wrapper, _lp);
    }

    /// @notice Setting the Sport Positional Manager contract address
    /// @param _manager Address of Staking contract
    function setSportsPositionalMarketManager(address _manager) external onlyOwner {
        if (address(_manager) != address(0)) {
            sUSD.approve(address(_manager), 0);
        }
        manager = _manager;
        sUSD.approve(manager, MAX_APPROVAL);
        emit SetSportsPositionalMarketManager(_manager);
    }

    /// @notice Updates contract parametars
    /// @param _address which has a specific safe box fee
    /// @param newSBFee the SafeBox fee for address
    /// @param newMSFee the min_spread fee for address
    function setSafeBoxFeeAndMinSpreadPerAddress(
        address _address,
        uint newSBFee,
        uint newMSFee
    ) external onlyOwner {
        safeBoxFeePerAddress[_address] = newSBFee;
        min_spreadPerAddress[_address] = newMSFee;
    }

    /// @notice Setting the Curve collateral addresses for all collaterals
    /// @param _curveSUSD Address of the Curve contract
    /// @param _dai Address of the DAI contract
    /// @param _usdc Address of the USDC contract
    /// @param _usdt Address of the USDT (Tether) contract
    /// @param _curveOnrampEnabled Enabling or restricting the use of multicollateral
    /// @param _maxAllowedPegSlippagePercentage maximum discount AMM accepts for sUSD purchases
    function setCurveSUSD(
        address _curveSUSD,
        address _dai,
        address _usdc,
        address _usdt,
        bool _curveOnrampEnabled,
        uint _maxAllowedPegSlippagePercentage
    ) external onlyOwner {
        curveSUSD = ICurveSUSD(_curveSUSD);
        dai = _dai;
        usdc = _usdc;
        usdt = _usdt;
        IERC20Upgradeable(dai).approve(_curveSUSD, MAX_APPROVAL);
        IERC20Upgradeable(usdc).approve(_curveSUSD, MAX_APPROVAL);
        IERC20Upgradeable(usdt).approve(_curveSUSD, MAX_APPROVAL);
        // not needed unless selling into different collateral is enabled
        //sUSD.approve(_curveSUSD, MAX_APPROVAL);
        curveOnrampEnabled = _curveOnrampEnabled;
        maxAllowedPegSlippagePercentage = _maxAllowedPegSlippagePercentage;
    }

    function setPaused(bool _setPausing) external onlyOwner {
        _setPausing ? _pause() : _unpause();
    }

    /// @notice Setting the Cap per Sport ID
    /// @param _sportID The tagID used for each market
    /// @param _capPerSport The cap amount used for the sportID
    function setCapPerSport(uint _sportID, uint _capPerSport) external onlyOwner {
        capPerSport[_sportID] = _capPerSport;
        emit SetCapPerSport(_sportID, _capPerSport);
    }

    /// @notice Setting the Min Spread per Sport ID
    /// @param _tag1 The first tagID used for each market
    /// @param _tag2 The second tagID used for each market
    /// @param _minSpread The min spread amount used for the sportID
    function setMinSpreadPerSport(
        uint _tag1,
        uint _tag2,
        uint _minSpread
    ) external onlyOwner {
        minSpreadPerSport[_tag1][_tag2] = _minSpread;
        emit SetMinSpreadPerSport(_tag1, _tag2, _minSpread);
    }

    /// @notice Setting the Cap per Sport ID
    /// @param _sportID The tagID used for sport (9004)
    /// @param _childID The tagID used for childid (10002)
    /// @param _capPerChild The cap amount used for the sportID
    function setCapPerSportAndChild(
        uint _sportID,
        uint _childID,
        uint _capPerChild
    ) external onlyOwner {
        capPerSportAndChild[_sportID][_childID] = _capPerChild;
        emit SetCapPerSportAndChild(_sportID, _childID, _capPerChild);
    }

    /// @notice Setting the Cap per spec. market
    /// @param _markets market addresses
    /// @param _capPerMarket The cap amount used for the specific markets
    function setCapPerMarket(address[] memory _markets, uint _capPerMarket) external {
        require(
            msg.sender == owner || ISportPositionalMarketManager(manager).isWhitelistedAddress(msg.sender),
            "Invalid sender"
        );
        for (uint i; i < _markets.length; i++) {
            capPerMarket[_markets[i]] = _capPerMarket;
            emit SetCapPerMarket(_markets[i], _capPerMarket);
        }
    }

    /// @notice used to update gamified Staking bonuses from Parlay contract
    /// @param _account Address to update volume for
    /// @param _amount of the volume
    function updateParlayVolume(address _account, uint _amount) external {
        require(msg.sender == parlayAMM, "Invalid caller");
        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(_account, _amount);
        }
    }

    /// @notice Updates contract parametars
    /// @param _ammUtils address of AMMUtils
    function setAmmUtils(SportsAMMUtils _ammUtils) external onlyOwner {
        sportAmmUtils = _ammUtils;
    }

    // Internal

    /// @notice calculate which cap needs to be applied to the given market
    /// @param market to get cap for
    /// @return toReturn cap to use
    function _calculateCapToBeUsed(address market) internal view returns (uint toReturn) {
        toReturn = capPerMarket[market];
        (uint tag1, uint tag2) = _getTagsForMarket(market);
        if (toReturn == 0) {
            uint capFirstTag = capPerSport[tag1];
            capFirstTag = capFirstTag > 0 ? capFirstTag : defaultCapPerGame;
            toReturn = capFirstTag;

            if (tag2 > 0) {
                uint capSecondTag = capPerSportAndChild[tag1][tag2];
                toReturn = capSecondTag > 0 ? capSecondTag : capFirstTag / 2;
            }
        }
    }

    function _buyFromAMMWithDifferentCollateral(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage,
        address collateral
    ) internal {
        int128 curveIndex = _mapCollateralToCurveIndex(collateral);
        require(curveIndex > 0 && curveOnrampEnabled, "unsupported collateral");

        (uint collateralQuote, uint susdQuote) = buyFromAmmQuoteWithDifferentCollateral(
            market,
            position,
            amount,
            collateral
        );

        uint transformedCollateralForPegCheck = collateral == usdc || collateral == usdt
            ? collateralQuote * (1e12)
            : collateralQuote;
        require(
            maxAllowedPegSlippagePercentage > 0 &&
                transformedCollateralForPegCheck >= (susdQuote * (ONE - (maxAllowedPegSlippagePercentage))) / ONE,
            "Max peg slippage"
        );

        require((collateralQuote * ONE) / (expectedPayout) <= (ONE + additionalSlippage), "High slippage");

        IERC20Upgradeable collateralToken = IERC20Upgradeable(collateral);
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralQuote);
        curveSUSD.exchange_underlying(curveIndex, 0, collateralQuote, susdQuote);

        return _buyFromAMM(BuyFromAMMParams(market, position, amount, susdQuote, additionalSlippage, false, susdQuote));
    }

    function _buyFromAMM(BuyFromAMMParams memory params) internal {
        require(isMarketInAMMTrading(params.market), "Not trading");

        uint optionsCount = ISportPositionalMarket(params.market).optionsCount();
        require(optionsCount > uint(params.position), "Invalid pos");

        DoubleChanceStruct memory dcs = _getDoubleChanceStruct(params.market);
        require(!dcs.isDoubleChance || params.position == ISportsAMM.Position.Home, "Invalid pos");

        uint baseOdds = _obtainOddsWithDC(params.market, params.position, dcs.isDoubleChance);
        require(baseOdds > 0, "No base odds");
        baseOdds = baseOdds < minSupportedOdds ? minSupportedOdds : baseOdds;

        uint availableInContract = sportAmmUtils.balanceOfPositionOnMarket(
            params.market,
            params.position,
            liquidityPool.getMarketPool(params.market)
        );
        uint availableToBuyFromAMMatm = _availableToBuyFromAMMInternal(
            params.market,
            params.position,
            baseOdds,
            availableInContract,
            true,
            dcs
        );
        require(params.amount > ZERO_POINT_ONE && params.amount <= availableToBuyFromAMMatm, "Low liquidity || 0");

        if (params.sendSUSD) {
            params.sUSDPaid = _buyFromAmmQuoteWithBaseOdds(
                params.market,
                params.position,
                params.amount,
                baseOdds,
                _getSafeBoxFeePerAddress(msg.sender),
                availableToBuyFromAMMatm,
                true,
                false,
                dcs
            );
            require((params.sUSDPaid * ONE) / params.expectedPayout <= (ONE + params.additionalSlippage), "High slippage");
            sUSD.safeTransferFrom(msg.sender, address(this), params.sUSDPaid);
        }

        if (dcs.isDoubleChance) {
            ISportPositionalMarket(params.market).mint(params.amount);
            _mintParentPositions(params.market, params.amount, dcs);

            (address parentMarketPosition1, address parentMarketPosition2) = sportAmmUtils.getParentMarketPositionAddresses(
                params.market
            );

            _getDoubleChanceOptions(params.amount, parentMarketPosition1, params.market);
            _getDoubleChanceOptions(params.amount, parentMarketPosition2, params.market);

            IERC20Upgradeable(parentMarketPosition1).safeTransfer(params.market, params.amount);
            IERC20Upgradeable(parentMarketPosition2).safeTransfer(params.market, params.amount);
        } else {
            uint toMint = availableInContract < params.amount ? params.amount - availableInContract : 0;
            if (toMint > 0) {
                liquidityPool.commitTrade(params.market, toMint);
                ISportPositionalMarket(params.market).mint(toMint);
                spentOnGame[params.market] = spentOnGame[params.market] + toMint;
            }
            liquidityPool.getOptionsForBuy(params.market, params.amount - toMint, params.position);
        }

        (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(params.market).getOptions();
        IPosition target = params.position == ISportsAMM.Position.Home ? home : params.position == ISportsAMM.Position.Away
            ? away
            : draw;
        IERC20Upgradeable(address(target)).safeTransfer(msg.sender, params.amount);

        if (
            !dcs.isDoubleChance && thresholdForOddsUpdate > 0 && (params.amount - params.sUSDPaid) >= thresholdForOddsUpdate
        ) {
            wrapper.callUpdateOddsForSpecificGame(params.market);
        }

        _updateSpentOnMarketOnBuy(
            dcs.isDoubleChance ? address(ISportPositionalMarket(params.market).parentMarket()) : params.market,
            params.sUSDPaid,
            msg.sender
        );

        _sendMintedPositionsAndUSDToLiquidityPool(
            dcs.isDoubleChance ? address(ISportPositionalMarket(params.market).parentMarket()) : params.market
        );

        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(msg.sender, params.sUSDPaid);
        }

        emit BoughtFromAmm(
            msg.sender,
            params.market,
            params.position,
            params.amount,
            params.sUSDPaid,
            address(sUSD),
            address(target)
        );
    }

    function _getDoubleChanceOptions(
        uint amount,
        address position,
        address market
    ) internal {
        uint balanceHeld = IERC20Upgradeable(position).balanceOf(address(this));
        if (amount > balanceHeld) {
            liquidityPool.getOptionsForBuyByAddress(
                address(ISportPositionalMarket(market).parentMarket()),
                amount - balanceHeld,
                position
            );
        }
    }

    function _availableToBuyFromAMMInternal(
        address market,
        ISportsAMM.Position position,
        uint baseOdds,
        uint balance,
        bool useBalance,
        DoubleChanceStruct memory dcs
    ) internal view returns (uint _available) {
        if (dcs.isDoubleChance) {
            if (position == ISportsAMM.Position.Home && (baseOdds > 0 && baseOdds < maxSupportedOdds)) {
                (uint availableFirst, uint availableSecond) = _getAvailableForPositions(
                    dcs.parentMarket,
                    dcs.position1,
                    dcs.position2
                );
                _available = availableFirst > availableSecond ? availableSecond : availableFirst;
            }
        } else {
            baseOdds = baseOdds < minSupportedOdds ? minSupportedOdds : baseOdds;
            _available = _availableToBuyFromAMMWithBaseOdds(market, position, baseOdds, balance, useBalance);
        }
    }

    function _availableToBuyFromAMMWithBaseOdds(
        address market,
        ISportsAMM.Position position,
        uint baseOdds,
        uint balance,
        bool useBalance
    ) internal view returns (uint availableAmount) {
        if (baseOdds > 0 && baseOdds < maxSupportedOdds) {
            baseOdds = (baseOdds * (ONE + min_spread)) / ONE;
            balance = useBalance
                ? balance
                : sportAmmUtils.balanceOfPositionOnMarket(market, position, liquidityPool.getMarketPool(market));

            availableAmount = sportAmmUtils.calculateAvailableToBuy(
                _calculateCapToBeUsed(market),
                spentOnGame[market],
                baseOdds,
                balance,
                max_spread
            );
        }
    }

    function _obtainOdds(address _market, ISportsAMM.Position _position) internal view returns (uint) {
        if (ISportPositionalMarketManager(manager).isDoubleChanceMarket(_market)) {
            if (_position == ISportsAMM.Position.Home) {
                return sportAmmUtils.getBaseOddsForDoubleChanceSum(_market, minSupportedOdds);
            }
        }
        return sportAmmUtils.obtainOdds(_market, _position);
    }

    function _obtainOddsWithDC(
        address _market,
        ISportsAMM.Position _position,
        bool isDoubleChance
    ) internal view returns (uint) {
        if (isDoubleChance) {
            return sportAmmUtils.getBaseOddsForDoubleChanceSum(_market, minSupportedOdds);
        }
        return sportAmmUtils.obtainOdds(_market, _position);
    }

    function _getSafeBoxFeePerAddress(address toCheck) internal view returns (uint toReturn) {
        if (toCheck != parlayAMM) {
            return safeBoxFeePerAddress[toCheck] > 0 ? safeBoxFeePerAddress[toCheck] : safeBoxImpact;
        }
    }

    function _sendMintedPositionsAndUSDToLiquidityPool(address market) internal {
        address _liquidityPool = liquidityPool.getOrCreateMarketPool(market);

        if (sUSD.balanceOf(address(this)) > 0) {
            sUSD.safeTransfer(_liquidityPool, sUSD.balanceOf(address(this)));
        }

        (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(market).getOptions();

        (uint homeBalance, uint awayBalance, uint drawBalance) = sportAmmUtils.getBalanceOfPositionsOnMarket(
            market,
            address(this)
        );

        if (homeBalance > 0) {
            IERC20Upgradeable(address(home)).safeTransfer(_liquidityPool, homeBalance);
        }

        if (awayBalance > 0) {
            IERC20Upgradeable(address(away)).safeTransfer(_liquidityPool, awayBalance);
        }
        if (drawBalance > 0) {
            IERC20Upgradeable(address(draw)).safeTransfer(_liquidityPool, drawBalance);
        }
    }

    function _updateSpentOnMarketOnBuy(
        address market,
        uint sUSDPaid,
        address buyer
    ) internal {
        uint safeBoxShare;
        uint sbimpact = _getSafeBoxFeePerAddress(buyer);
        if (sbimpact > 0) {
            safeBoxShare = sUSDPaid - (sUSDPaid * ONE) / (ONE + sbimpact);
            sUSD.safeTransfer(safeBox, safeBoxShare);
        }

        uint toSubtract = ISportPositionalMarketManager(manager).reverseTransformCollateral(sUSDPaid - safeBoxShare);

        spentOnGame[market] = spentOnGame[market] <= toSubtract
            ? 0
            : (spentOnGame[market] = spentOnGame[market] - toSubtract);

        if (referrerFee > 0 && referrals != address(0)) {
            uint referrerShare = sUSDPaid - ((sUSDPaid * ONE) / (ONE + referrerFee));
            _handleReferrer(buyer, referrerShare, sUSDPaid);
        }
    }

    function _buyPriceImpact(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint _availableToBuyFromAMM,
        uint _availableToBuyFromAMMOtherSide
    ) internal view returns (int priceImpact) {
        return
            sportAmmUtils.getBuyPriceImpact(
                SportsAMMUtils.PriceImpactParams(
                    market,
                    position,
                    amount,
                    _availableToBuyFromAMM,
                    _availableToBuyFromAMMOtherSide,
                    liquidityPool,
                    max_spread,
                    minSupportedOdds
                )
            );
    }

    function _handleReferrer(
        address buyer,
        uint referrerShare,
        uint volume
    ) internal {
        address referrer = IReferrals(referrals).sportReferrals(buyer);
        if (referrer != address(0) && referrerFee > 0) {
            sUSD.safeTransfer(referrer, referrerShare);
            emit ReferrerPaid(referrer, buyer, referrerShare, volume);
        }
    }

    function _mintParentPositions(
        address market,
        uint amount,
        DoubleChanceStruct memory dcs
    ) internal {
        (uint availableInContract1, uint availableInContract2) = sportAmmUtils.getBalanceOfPositionsOnMarketByPositions(
            dcs.parentMarket,
            liquidityPool.getMarketPool(market),
            dcs.position1,
            dcs.position2
        );

        uint toMintPosition1 = availableInContract1 < amount ? amount - availableInContract1 : 0;
        uint toMintPosition2 = availableInContract2 < amount ? amount - availableInContract2 : 0;

        uint toMint = toMintPosition1 < toMintPosition2 ? toMintPosition2 : toMintPosition1;

        if (toMint > 0) {
            liquidityPool.commitTrade(dcs.parentMarket, toMint);
            ISportPositionalMarket(dcs.parentMarket).mint(toMint);
            spentOnGame[dcs.parentMarket] = spentOnGame[dcs.parentMarket] + toMint;
        }
    }

    function _getDoubleChanceStruct(address market) internal view returns (DoubleChanceStruct memory) {
        if (!ISportPositionalMarketManager(manager).isDoubleChanceMarket(market)) {
            return DoubleChanceStruct(false, ISportsAMM.Position.Home, ISportsAMM.Position.Away, address(0));
        } else {
            (ISportsAMM.Position position1, ISportsAMM.Position position2, address parentMarket) = sportAmmUtils
                .getParentMarketPositions(market);
            return DoubleChanceStruct(true, position1, position2, parentMarket);
        }
    }

    function _mapCollateralToCurveIndex(address collateral) internal view returns (int128 mappedValue) {
        if (collateral == dai) {
            mappedValue = 1;
        }
        if (collateral == usdc) {
            mappedValue = 2;
        }
        if (collateral == usdt) {
            mappedValue = 3;
        }
    }

    // events
    event BoughtFromAmm(
        address buyer,
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint sUSDPaid,
        address susd,
        address asset
    );

    event ParametersUpdated(
        uint _minimalTimeLeftToMaturity,
        uint _minSpread,
        uint _maxSpread,
        uint _minSupportedOdds,
        uint _maxSupportedOdds,
        uint _defaultCapPerGame,
        uint _safeBoxImpact,
        uint _referrerFee,
        uint threshold
    );
    event AddressesUpdated(
        address _safeBox,
        IERC20Upgradeable _sUSD,
        address _theRundownConsumer,
        IStakingThales _stakingThales,
        address _referrals,
        address _parlayAMM,
        address _wrapper,
        address _lp
    );

    event SetSportsPositionalMarketManager(address _manager);
    event ReferrerPaid(address refferer, address trader, uint amount, uint volume);
    event SetCapPerSport(uint _sport, uint _cap);
    event SetMinSpreadPerSport(uint _tag1, uint _tag2, uint _spread);
    event SetCapPerMarket(address _market, uint _cap);
    event SetCapPerSportAndChild(uint _sport, uint _child, uint _cap);
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
pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface ISportPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Cancelled,
        Home,
        Away,
        Draw
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions()
        external
        view
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        );

    function times() external view returns (uint maturity, uint destruction);

    function initialMint() external view returns (uint);

    function getGameDetails() external view returns (bytes32 gameId, string memory gameLabel);

    function getGameId() external view returns (bytes32);

    function deposited() external view returns (uint);

    function optionsCount() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function cancelled() external view returns (bool);

    function paused() external view returns (bool);

    function phase() external view returns (Phase);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function isChild() external view returns (bool);

    function tags(uint idx) external view returns (uint);

    function getParentMarketPositions() external view returns (IPosition position1, IPosition position2);

    function getStampedOdds()
        external
        view
        returns (
            uint,
            uint,
            uint
        );

    function balancesOf(address account)
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function totalSupplies()
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function isDoubleChance() external view returns (bool);

    function parentMarket() external view returns (ISportPositionalMarket);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setPaused(bool _paused) external;

    function updateDates(uint256 _maturity, uint256 _expiry) external;

    function mint(uint value) external;

    function exerciseOptions() external;

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISportPositionalMarket.sol";

interface ISportPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function marketCreationEnabled() external view returns (bool);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isDoubleChanceMarket(address candidate) external view returns (bool);

    function isDoubleChanceSupported() external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getActiveMarketAddress(uint _index) external view returns (address);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function isMarketPaused(address _market) external view returns (bool);

    function expiryDuration() external view returns (uint);

    function isWhitelistedAddress(address _address) external view returns (bool);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 gameId,
        string memory gameLabel,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        uint positionCount,
        uint[] memory tags,
        bool isChild,
        address parentMarket
    ) external returns (ISportPositionalMarket);

    function setMarketPaused(address _market, bool _paused) external;

    function updateDatesForMarket(address _market, uint256 _newStartTime) external;

    function resolveMarket(address market, uint outcome) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);

    function exerciseWithAmount(address claimant, uint amount) external;
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

pragma solidity ^0.8.0;

interface ITherundownConsumer {
    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        string homeTeam;
        string awayTeam;
    }

    // view functions
    function supportedSport(uint _sportId) external view returns (bool);

    function getNormalizedOdds(bytes32 _gameId) external view returns (uint[] memory);

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

    function getNormalizedChildOdds(address _market) external view returns (uint[] memory);

    function getNormalizedOddsForTwoPosition(bytes32 _gameId) external view returns (uint[] memory);

    function getGamesPerDatePerSport(uint _sportId, uint _date) external view returns (bytes32[] memory);

    function getGamePropsForOdds(address _market)
        external
        view
        returns (
            uint,
            uint,
            bytes32
        );

    function gameIdPerMarket(address _market) external view returns (bytes32);

    function getGameCreatedById(bytes32 _gameId) external view returns (GameCreate memory);

    function isChildMarket(address _market) external view returns (bool);

    function gameFulfilledCreated(bytes32 _gameId) external view returns (bool);

    // write functions
    function fulfillGamesCreated(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportsId,
        uint _date
    ) external;

    function fulfillGamesResolved(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportsId
    ) external;

    function fulfillGamesOdds(bytes32 _requestId, bytes[] memory _games) external;

    function setPausedByCanceledStatus(address _market, bool _flag) external;

    function setGameIdPerChildMarket(bytes32 _gameId, address _child) external;

    function pauseOrUnpauseMarket(address _market, bool _pause) external;

    function setChildMarkets(
        bytes32 _gameId,
        address _main,
        address _child,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver
    ) external;

    function resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        bool _usebackupOdds
    ) external;

    function getOddsForGame(bytes32 _gameId)
        external
        view
        returns (
            int24,
            int24,
            int24
        );

    function sportsIdPerGame(bytes32 _gameId) external view returns (uint);

    function getGameStartTime(bytes32 _gameId) external view returns (uint256);

    function marketPerGameId(bytes32 _gameId) external view returns (address);

    function marketResolved(address _market) external view returns (bool);

    function marketCanceled(address _market) external view returns (bool);

    function invalidOdds(address _market) external view returns (bool);

    function isPausedByCanceledStatus(address _market) external view returns (bool);

    function isSportOnADate(uint _date, uint _sportId) external view returns (bool);

    function isSportTwoPositionsSport(uint _sportsId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface ICurveSUSD {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    //    @notice Perform an exchange between two underlying coins
    //    @param i Index value for the underlying coin to send
    //    @param j Index valie of the underlying coin to receive
    //    @param _dx Amount of `i` being exchanged
    //    @param _min_dy Minimum amount of `j` to receive
    //    @param _receiver Address that receives `j`
    //    @return Actual amount of `j` received

    // indexes:
    // 0 = sUSD 18 dec 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9
    // 1= DAI 18 dec 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1
    // 2= USDC 6 dec 0x7F5c764cBc14f9669B88837ca1490cCa17c31607
    // 3= USDT 6 dec 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface IReferrals {
    function referrals(address) external view returns (address);

    function sportReferrals(address) external view returns (address);

    function setReferrer(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISportsAMM {
    /* ========== VIEWS / VARIABLES ========== */

    enum Position {
        Home,
        Away,
        Draw
    }

    struct SellRequirements {
        address user;
        address market;
        Position position;
        uint amount;
        uint expectedPayout;
        uint additionalSlippage;
    }

    function theRundownConsumer() external view returns (address);

    function getMarketDefaultOdds(address _market, bool isSell) external view returns (uint[] memory);

    function isMarketInAMMTrading(address _market) external view returns (bool);

    function availableToBuyFromAMM(address market, Position position) external view returns (uint _available);

    function parlayAMM() external view returns (address);

    function minSupportedOdds() external view returns (uint);

    function maxSupportedOdds() external view returns (uint);

    function min_spread() external view returns (uint);

    function max_spread() external view returns (uint);

    function minimalTimeLeftToMaturity() external view returns (uint);

    function getSpentOnGame(address market) external view returns (uint);

    function safeBoxImpact() external view returns (uint);

    function manager() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function buyFromAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external;

    function buyFromAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function buyFromAmmQuoteForParlayAMM(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function updateParlayVolume(address _account, uint _amount) external;

    function buyPriceImpact(
        address market,
        ISportsAMM.Position position,
        uint amount
    ) external view returns (int impact);

    function obtainOdds(address _market, ISportsAMM.Position _position) external view returns (uint oddsToReturn);

    function buyFromAmmQuoteWithDifferentCollateral(
        address market,
        ISportsAMM.Position position,
        uint amount,
        address collateral
    ) external view returns (uint collateralQuote, uint sUSDToPay);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITherundownConsumerWrapper {
    function callUpdateOddsForSpecificGame(address _marketAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "../interfaces/ISportPositionalMarket.sol";
import "../interfaces/ISportPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/ITherundownConsumer.sol";
import "../interfaces/ISportsAMM.sol";

import "./LiquidityPool/SportAMMLiquidityPool.sol";

/// @title Sports AMM utils
contract SportsAMMUtils {
    uint private constant ONE = 1e18;
    uint private constant ZERO_POINT_ONE = 1e17;
    uint private constant ONE_PERCENT = 1e16;
    uint private constant MAX_APPROVAL = type(uint256).max;
    int private constant ONE_INT = 1e18;
    int private constant ONE_PERCENT_INT = 1e16;

    ISportsAMM public sportsAMM;

    constructor(address _sportsAMM) {
        sportsAMM = ISportsAMM(_sportsAMM);
    }

    struct DiscountParams {
        uint balancePosition;
        uint balanceOtherSide;
        uint amount;
        uint availableToBuyFromAMM;
        uint max_spread;
    }

    struct NegativeDiscountsParams {
        uint amount;
        uint balancePosition;
        uint balanceOtherSide;
        uint _availableToBuyFromAMMOtherSide;
        uint _availableToBuyFromAMM;
        uint pricePosition;
        uint priceOtherPosition;
        uint max_spread;
    }

    struct PriceImpactParams {
        address market;
        ISportsAMM.Position position;
        uint amount;
        uint _availableToBuyFromAMM;
        uint _availableToBuyFromAMMOtherSide;
        SportAMMLiquidityPool liquidityPool;
        uint max_spread;
        uint minSupportedOdds;
    }

    function buyPriceImpactImbalancedSkew(
        uint amount,
        uint balanceOtherSide,
        uint balancePosition,
        uint balanceOtherSideAfter,
        uint balancePositionAfter,
        uint availableToBuyFromAMM,
        uint max_spread
    ) public view returns (uint) {
        uint maxPossibleSkew = balanceOtherSide + availableToBuyFromAMM - balancePosition;
        uint skew = balanceOtherSideAfter - (balancePositionAfter);
        uint newImpact = (max_spread * ((skew * ONE) / (maxPossibleSkew))) / ONE;
        if (balancePosition > 0) {
            uint newPriceForMintedOnes = newImpact / 2;
            uint tempMultiplier = (amount - balancePosition) * newPriceForMintedOnes;
            return (tempMultiplier * ONE) / (amount) / ONE;
        } else {
            uint previousSkew = balanceOtherSide;
            uint previousImpact = (max_spread * ((previousSkew * ONE) / maxPossibleSkew)) / ONE;
            return (newImpact + previousImpact) / 2;
        }
    }

    function calculateDiscount(DiscountParams memory params) public view returns (int) {
        uint currentBuyImpactOtherSide = buyPriceImpactImbalancedSkew(
            params.amount,
            params.balancePosition,
            params.balanceOtherSide,
            params.balanceOtherSide > ONE
                ? params.balancePosition
                : params.balancePosition + (ONE - params.balanceOtherSide),
            params.balanceOtherSide > ONE ? params.balanceOtherSide - ONE : 0,
            params.availableToBuyFromAMM,
            params.max_spread
        );

        uint startDiscount = currentBuyImpactOtherSide;
        uint tempMultiplier = params.balancePosition - params.amount;
        uint finalDiscount = ((startDiscount / 2) * ((tempMultiplier * ONE) / params.balancePosition + ONE)) / ONE;

        return -int(finalDiscount);
    }

    function calculateDiscountFromNegativeToPositive(NegativeDiscountsParams memory params)
        public
        view
        returns (int priceImpact)
    {
        uint amountToBeMinted = params.amount - params.balancePosition;
        uint sum1 = params.balanceOtherSide + params.balancePosition;
        uint sum2 = params.balanceOtherSide + amountToBeMinted;
        uint red3 = params._availableToBuyFromAMM - params.balancePosition;
        uint positiveSkew = buyPriceImpactImbalancedSkew(amountToBeMinted, sum1, 0, sum2, 0, red3, params.max_spread);

        uint skew = (params.priceOtherPosition * positiveSkew) / params.pricePosition;

        int discount = calculateDiscount(
            DiscountParams(
                params.balancePosition,
                params.balanceOtherSide,
                params.balancePosition,
                params._availableToBuyFromAMMOtherSide,
                params.max_spread
            )
        );

        int discountBalance = int(params.balancePosition) * discount;
        int discountMinted = int(amountToBeMinted * skew);
        int amountInt = int(params.balancePosition + amountToBeMinted);

        priceImpact = (discountBalance + discountMinted) / amountInt;

        if (priceImpact > 0) {
            int numerator = int(params.pricePosition) * priceImpact;
            priceImpact = numerator / int(params.priceOtherPosition);
        }
    }

    function calculateTempQuote(
        int skewImpact,
        uint baseOdds,
        uint safeBoxImpact,
        uint amount
    ) public pure returns (int tempQuote) {
        if (skewImpact >= 0) {
            int impactPrice = ((ONE_INT - int(baseOdds)) * skewImpact) / ONE_INT;
            // add 2% to the price increase to avoid edge cases on the extremes
            impactPrice = (impactPrice * (ONE_INT + (ONE_PERCENT_INT * 2))) / ONE_INT;
            tempQuote = (int(amount) * (int(baseOdds) + impactPrice)) / ONE_INT;
        } else {
            tempQuote = ((int(amount)) * ((int(baseOdds) * (ONE_INT + skewImpact)) / ONE_INT)) / ONE_INT;
        }
        tempQuote = (tempQuote * (ONE_INT + (int(safeBoxImpact)))) / ONE_INT;
    }

    function calculateAvailableToBuy(
        uint capUsed,
        uint spentOnThisGame,
        uint baseOdds,
        uint balance,
        uint max_spread
    ) public view returns (uint availableAmount) {
        uint discountedPrice = (baseOdds * (ONE - max_spread / 2)) / ONE;
        uint additionalBufferFromSelling = (balance * discountedPrice) / ONE;
        if ((capUsed + additionalBufferFromSelling) > spentOnThisGame) {
            uint availableUntilCapSUSD = capUsed + additionalBufferFromSelling - spentOnThisGame;
            if (availableUntilCapSUSD > capUsed) {
                availableUntilCapSUSD = capUsed;
            }

            uint midImpactPriceIncrease = ((ONE - baseOdds) * (max_spread / 2)) / ONE;
            uint divider_price = ONE - (baseOdds + midImpactPriceIncrease);

            availableAmount = balance + ((availableUntilCapSUSD * ONE) / divider_price);
        }
    }

    function getCanExercize(address market, address toCheck) public view returns (bool canExercize) {
        if (
            ISportPositionalMarketManager(sportsAMM.manager()).isKnownMarket(market) &&
            !ISportPositionalMarket(market).paused() &&
            ISportPositionalMarket(market).resolved()
        ) {
            (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(market).getOptions();
            if (
                (home.getBalanceOf(address(toCheck)) > 0) ||
                (away.getBalanceOf(address(toCheck)) > 0) ||
                (ISportPositionalMarket(market).optionsCount() > 2 && draw.getBalanceOf(address(toCheck)) > 0)
            ) {
                canExercize = true;
            }
        }
    }

    function obtainOdds(address _market, ISportsAMM.Position _position) public view returns (uint oddsToReturn) {
        address theRundownConsumer = sportsAMM.theRundownConsumer();
        if (ISportPositionalMarket(_market).optionsCount() > uint(_position)) {
            uint[] memory odds = new uint[](ISportPositionalMarket(_market).optionsCount());
            odds = ITherundownConsumer(theRundownConsumer).getNormalizedOddsForMarket(_market);
            oddsToReturn = odds[uint(_position)];
        }
    }

    function obtainOddsMulti(
        address _market,
        ISportsAMM.Position _position1,
        ISportsAMM.Position _position2
    ) public view returns (uint oddsToReturn1, uint oddsToReturn2) {
        address theRundownConsumer = sportsAMM.theRundownConsumer();
        uint positionsCount = ISportPositionalMarket(_market).optionsCount();
        uint[] memory odds = new uint[](ISportPositionalMarket(_market).optionsCount());
        odds = ITherundownConsumer(theRundownConsumer).getNormalizedOddsForMarket(_market);
        if (positionsCount > uint(_position1)) {
            oddsToReturn1 = odds[uint(_position1)];
        }
        if (positionsCount > uint(_position2)) {
            oddsToReturn2 = odds[uint(_position2)];
        }
    }

    function getBalanceOtherSideOnThreePositions(
        ISportsAMM.Position position,
        address addressToCheck,
        address market
    ) public view returns (uint balanceOfTheOtherSide) {
        (uint homeBalance, uint awayBalance, uint drawBalance) = getBalanceOfPositionsOnMarket(market, addressToCheck);
        if (position == ISportsAMM.Position.Home) {
            balanceOfTheOtherSide = awayBalance < drawBalance ? awayBalance : drawBalance;
        } else if (position == ISportsAMM.Position.Away) {
            balanceOfTheOtherSide = homeBalance < drawBalance ? homeBalance : drawBalance;
        } else {
            balanceOfTheOtherSide = homeBalance < awayBalance ? homeBalance : awayBalance;
        }
    }

    function getBalanceOfPositionsOnMarket(address market, address addressToCheck)
        public
        view
        returns (
            uint homeBalance,
            uint awayBalance,
            uint drawBalance
        )
    {
        (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(market).getOptions();
        homeBalance = home.getBalanceOf(address(addressToCheck));
        awayBalance = away.getBalanceOf(address(addressToCheck));
        if (ISportPositionalMarket(market).optionsCount() == 3) {
            drawBalance = draw.getBalanceOf(address(addressToCheck));
        }
    }

    function getBalanceOfPositionsOnMarketByPositions(
        address market,
        address addressToCheck,
        ISportsAMM.Position position1,
        ISportsAMM.Position position2
    ) public view returns (uint firstBalance, uint secondBalance) {
        (uint homeBalance, uint awayBalance, uint drawBalance) = getBalanceOfPositionsOnMarket(market, addressToCheck);
        firstBalance = position1 == ISportsAMM.Position.Home ? homeBalance : position1 == ISportsAMM.Position.Away
            ? awayBalance
            : drawBalance;
        secondBalance = position2 == ISportsAMM.Position.Home ? homeBalance : position2 == ISportsAMM.Position.Away
            ? awayBalance
            : drawBalance;
    }

    function balanceOfPositionsOnMarket(
        address market,
        ISportsAMM.Position position,
        address addressToCheck
    )
        public
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        (IPosition home, IPosition away, ) = ISportPositionalMarket(market).getOptions();
        uint balance = position == ISportsAMM.Position.Home
            ? home.getBalanceOf(addressToCheck)
            : away.getBalanceOf(addressToCheck);
        uint balanceOtherSideMax = position == ISportsAMM.Position.Home
            ? away.getBalanceOf(addressToCheck)
            : home.getBalanceOf(addressToCheck);
        uint balanceOtherSideMin = balanceOtherSideMax;
        if (ISportPositionalMarket(market).optionsCount() == 3) {
            (uint homeBalance, uint awayBalance, uint drawBalance) = getBalanceOfPositionsOnMarket(market, addressToCheck);
            if (position == ISportsAMM.Position.Home) {
                balance = homeBalance;
                if (awayBalance < drawBalance) {
                    balanceOtherSideMax = drawBalance;
                    balanceOtherSideMin = awayBalance;
                } else {
                    balanceOtherSideMax = awayBalance;
                    balanceOtherSideMin = drawBalance;
                }
            } else if (position == ISportsAMM.Position.Away) {
                balance = awayBalance;
                if (homeBalance < drawBalance) {
                    balanceOtherSideMax = drawBalance;
                    balanceOtherSideMin = homeBalance;
                } else {
                    balanceOtherSideMax = homeBalance;
                    balanceOtherSideMin = drawBalance;
                }
            } else if (position == ISportsAMM.Position.Draw) {
                balance = drawBalance;
                if (homeBalance < awayBalance) {
                    balanceOtherSideMax = awayBalance;
                    balanceOtherSideMin = homeBalance;
                } else {
                    balanceOtherSideMax = homeBalance;
                    balanceOtherSideMin = awayBalance;
                }
            }
        }
        return (balance, balanceOtherSideMax, balanceOtherSideMin);
    }

    function balanceOfPositionOnMarket(
        address market,
        ISportsAMM.Position position,
        address addressToCheck
    ) public view returns (uint) {
        (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(market).getOptions();
        uint balance = position == ISportsAMM.Position.Home
            ? home.getBalanceOf(addressToCheck)
            : away.getBalanceOf(addressToCheck);
        if (ISportPositionalMarket(market).optionsCount() == 3 && position != ISportsAMM.Position.Home) {
            balance = position == ISportsAMM.Position.Away
                ? away.getBalanceOf(addressToCheck)
                : draw.getBalanceOf(addressToCheck);
        }
        return balance;
    }

    function getParentMarketPositions(address market)
        public
        view
        returns (
            ISportsAMM.Position position1,
            ISportsAMM.Position position2,
            address parentMarket
        )
    {
        ISportPositionalMarket parentMarketContract = ISportPositionalMarket(market).parentMarket();
        (IPosition parentPosition1, IPosition parentPosition2) = ISportPositionalMarket(market).getParentMarketPositions();
        (IPosition home, IPosition away, ) = parentMarketContract.getOptions();
        position1 = parentPosition1 == home ? ISportsAMM.Position.Home : parentPosition1 == away
            ? ISportsAMM.Position.Away
            : ISportsAMM.Position.Draw;
        position2 = parentPosition2 == home ? ISportsAMM.Position.Home : parentPosition2 == away
            ? ISportsAMM.Position.Away
            : ISportsAMM.Position.Draw;

        parentMarket = address(parentMarketContract);
    }

    function getParentMarketPositionAddresses(address market)
        public
        view
        returns (address parentMarketPosition1, address parentMarketPosition2)
    {
        (IPosition position1, IPosition position2) = ISportPositionalMarket(market).getParentMarketPositions();

        parentMarketPosition1 = address(position1);
        parentMarketPosition2 = address(position2);
    }

    function getBaseOddsForDoubleChance(address market, uint minSupportedOdds)
        public
        view
        returns (uint oddsPosition1, uint oddsPosition2)
    {
        (ISportsAMM.Position position1, ISportsAMM.Position position2, address parentMarket) = getParentMarketPositions(
            market
        );
        oddsPosition1 = obtainOdds(parentMarket, position1);
        oddsPosition2 = obtainOdds(parentMarket, position2);

        if (oddsPosition1 > 0 && oddsPosition2 > 0) {
            oddsPosition1 = oddsPosition1 < minSupportedOdds ? minSupportedOdds : oddsPosition1;
            oddsPosition2 = oddsPosition2 < minSupportedOdds ? minSupportedOdds : oddsPosition2;
        }
    }

    function getBaseOddsForDoubleChanceSum(address market, uint minSupportedOdds) public view returns (uint sum) {
        (uint oddsPosition1, uint oddsPosition2) = getBaseOddsForDoubleChance(market, minSupportedOdds);

        sum = oddsPosition1 + oddsPosition2;
    }

    function getBuyPriceImpact(PriceImpactParams memory params) public view returns (int priceImpact) {
        (uint balancePosition, , uint balanceOtherSide) = balanceOfPositionsOnMarket(
            params.market,
            params.position,
            params.liquidityPool.getMarketPool(params.market)
        );
        bool isTwoPositional = ISportPositionalMarket(params.market).optionsCount() == 2;
        uint balancePositionAfter = balancePosition > params.amount ? balancePosition - params.amount : 0;
        uint balanceOtherSideAfter = balancePosition > params.amount
            ? balanceOtherSide
            : balanceOtherSide + (params.amount - balancePosition);
        if (params.amount <= balancePosition) {
            priceImpact = calculateDiscount(
                DiscountParams(
                    balancePosition,
                    balanceOtherSide,
                    params.amount,
                    params._availableToBuyFromAMMOtherSide,
                    params.max_spread
                )
            );
        } else {
            if (balancePosition > 0) {
                uint pricePosition = _obtainOdds(params.market, params.position, params.minSupportedOdds);
                uint priceOtherPosition = isTwoPositional
                    ? _obtainOdds(
                        params.market,
                        params.position == ISportsAMM.Position.Home ? ISportsAMM.Position.Away : ISportsAMM.Position.Home,
                        params.minSupportedOdds
                    )
                    : ONE - pricePosition;
                priceImpact = calculateDiscountFromNegativeToPositive(
                    NegativeDiscountsParams(
                        params.amount,
                        balancePosition,
                        balanceOtherSide,
                        params._availableToBuyFromAMMOtherSide,
                        params._availableToBuyFromAMM,
                        pricePosition,
                        priceOtherPosition,
                        params.max_spread
                    )
                );
            } else {
                priceImpact = int(
                    buyPriceImpactImbalancedSkew(
                        params.amount,
                        balanceOtherSide,
                        balancePosition,
                        balanceOtherSideAfter,
                        balancePositionAfter,
                        params._availableToBuyFromAMM,
                        params.max_spread
                    )
                );
            }
        }
    }

    function _obtainOdds(
        address _market,
        ISportsAMM.Position _position,
        uint minSupportedOdds
    ) internal view returns (uint) {
        if (ISportPositionalMarket(_market).isDoubleChance()) {
            if (_position == ISportsAMM.Position.Home) {
                return getBaseOddsForDoubleChanceSum(_market, minSupportedOdds);
            }
        }
        return obtainOdds(_market, _position);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";

import "../../interfaces/ISportsAMM.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/IStakingThales.sol";

import "./SportAMMLiquidityPoolRound.sol";

contract SportAMMLiquidityPool is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    /* ========== LIBRARIES ========== */
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct InitParams {
        address _owner;
        ISportsAMM _sportsAmm;
        IERC20Upgradeable _sUSD;
        uint _roundLength;
        uint _maxAllowedDeposit;
        uint _minDepositAmount;
        uint _maxAllowedUsers;
    }

    /* ========== CONSTANTS ========== */
    uint private constant HUNDRED = 1e20;
    uint private constant ONE = 1e18;

    /* ========== STATE VARIABLES ========== */

    ISportsAMM public sportsAMM;
    IERC20Upgradeable public sUSD;

    bool public started;

    uint public round;
    uint public roundLength;
    uint public firstRoundStartTime;

    mapping(uint => address) public roundPools;

    mapping(uint => address[]) public usersPerRound;
    mapping(uint => mapping(address => bool)) public userInRound;

    mapping(uint => mapping(address => uint)) public balancesPerRound;
    mapping(uint => uint) public allocationPerRound;

    mapping(address => bool) public withdrawalRequested;

    mapping(uint => address[]) public tradingMarketsPerRound;
    mapping(uint => mapping(address => bool)) public isTradingMarketInARound;

    mapping(uint => uint) public profitAndLossPerRound;
    mapping(uint => uint) public cumulativeProfitAndLoss;

    uint public maxAllowedDeposit;
    uint public minDepositAmount;
    uint public maxAllowedUsers;
    uint public usersCurrentlyInPool;

    address public defaultLiquidityProvider;

    IStakingThales public stakingThales;

    uint public stakedThalesMultiplier;

    address public poolRoundMastercopy;

    mapping(address => bool) public whitelistedDeposits;

    uint public totalDeposited;

    bool public onlyWhitelistedStakersAllowed;

    mapping(address => bool) public whitelistedStakers;

    bool public needsTransformingCollateral;

    mapping(uint => mapping(address => bool)) public marketAlreadyExercisedInRound;

    bool public roundClosingPrepared;

    uint public usersProcessedInRound;

    /* ========== CONSTRUCTOR ========== */

    function initialize(InitParams calldata params) external initializer {
        setOwner(params._owner);
        initNonReentrant();
        sportsAMM = ISportsAMM(params._sportsAmm);

        sUSD = params._sUSD;
        roundLength = params._roundLength;
        maxAllowedDeposit = params._maxAllowedDeposit;
        minDepositAmount = params._minDepositAmount;
        maxAllowedUsers = params._maxAllowedUsers;

        sUSD.approve(address(sportsAMM), type(uint256).max);
    }

    /// @notice Start pool and begin round #1
    function start() external onlyOwner {
        require(!started, "Liquidity pool has already started");
        require(allocationPerRound[1] > 0, "can not start with 0 deposits");
        round = 1;
        firstRoundStartTime = block.timestamp;
        started = true;
        emit PoolStarted();
    }

    /// @notice Deposit funds from user into pool for the next round
    /// @param amount Value to be deposited
    function deposit(uint amount) external canDeposit(amount) nonReentrant whenNotPaused roundClosingNotPrepared {
        uint nextRound = round + 1;
        address roundPool = _getOrCreateRoundPool(nextRound);
        sUSD.safeTransferFrom(msg.sender, roundPool, amount);

        if (!whitelistedDeposits[msg.sender]) {
            require(!onlyWhitelistedStakersAllowed || whitelistedStakers[msg.sender], "Only whitelisted stakers allowed");
            require(
                (balancesPerRound[round][msg.sender] + amount + balancesPerRound[nextRound][msg.sender]) <=
                    _transformCollateral((stakingThales.stakedBalanceOf(msg.sender) * stakedThalesMultiplier) / ONE),
                "Not enough staked THALES"
            );
        }

        require(msg.sender != defaultLiquidityProvider, "Can't deposit directly as default liquidity provider");

        // new user enters the pool
        if (balancesPerRound[round][msg.sender] == 0 && balancesPerRound[nextRound][msg.sender] == 0) {
            require(usersCurrentlyInPool < maxAllowedUsers, "Max amount of users reached");
            usersPerRound[nextRound].push(msg.sender);
            usersCurrentlyInPool = usersCurrentlyInPool + 1;
        }

        balancesPerRound[nextRound][msg.sender] += amount;

        allocationPerRound[nextRound] += amount;
        totalDeposited += amount;

        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(msg.sender, amount);
        }

        emit Deposited(msg.sender, amount, round);
    }

    /// @notice get sUSD to mint for buy and store market as trading in the round
    /// @param market to trade
    /// @param amountToMint amount to get for mint
    function commitTrade(address market, uint amountToMint)
        external
        nonReentrant
        whenNotPaused
        onlyAMM
        roundClosingNotPrepared
    {
        require(started, "Pool has not started");
        require(amountToMint > 0, "Can't commit a zero trade");

        amountToMint = _transformCollateral(amountToMint);
        // add 1e-6 due to rounding issue, will be sent back to AMM at the end
        amountToMint = needsTransformingCollateral ? amountToMint + 1 : amountToMint;

        uint marketRound = getMarketRound(market);
        address liquidityPoolRound = _getOrCreateRoundPool(marketRound);

        if (marketRound == round) {
            sUSD.safeTransferFrom(liquidityPoolRound, address(sportsAMM), amountToMint);
        } else {
            uint poolBalance = sUSD.balanceOf(liquidityPoolRound);
            if (poolBalance > amountToMint) {
                sUSD.safeTransferFrom(liquidityPoolRound, address(sportsAMM), amountToMint);
            } else {
                uint differenceToLPAsDefault = amountToMint - poolBalance;
                _depositAsDefault(differenceToLPAsDefault, liquidityPoolRound, marketRound);
                sUSD.safeTransferFrom(liquidityPoolRound, address(sportsAMM), amountToMint);
            }
        }

        if (!isTradingMarketInARound[marketRound][market]) {
            tradingMarketsPerRound[marketRound].push(market);
            isTradingMarketInARound[marketRound][market] = true;
        }
    }

    /// @notice get options that are in the LP into the AMM for the buy tx
    /// @param market to get options for
    /// @param optionsAmount to get options for
    /// @param position to get options for
    function getOptionsForBuy(
        address market,
        uint optionsAmount,
        ISportsAMM.Position position
    ) external nonReentrant whenNotPaused onlyAMM roundClosingNotPrepared {
        if (optionsAmount > 0) {
            require(started, "Pool has not started");

            uint marketRound = getMarketRound(market);
            address liquidityPoolRound = _getOrCreateRoundPool(marketRound);

            (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(market).getOptions();
            IPosition target = position == ISportsAMM.Position.Home ? home : away;
            if (ISportPositionalMarket(market).optionsCount() > 2 && position != ISportsAMM.Position.Home) {
                target = position == ISportsAMM.Position.Away ? away : draw;
            }

            SportAMMLiquidityPoolRound(liquidityPoolRound).moveOptions(
                IERC20Upgradeable(address(target)),
                optionsAmount,
                address(sportsAMM)
            );
        }
    }

    /// @notice get options that are in the LP into the AMM for the buy tx
    /// @param market to get options for
    /// @param optionsAmount to get options for
    /// @param position to get options for
    function getOptionsForBuyByAddress(
        address market,
        uint optionsAmount,
        address position
    ) external nonReentrant whenNotPaused onlyAMM roundClosingNotPrepared {
        if (optionsAmount > 0) {
            require(started, "Pool has not started");

            uint marketRound = getMarketRound(market);
            address liquidityPoolRound = _getOrCreateRoundPool(marketRound);

            SportAMMLiquidityPoolRound(liquidityPoolRound).moveOptions(
                IERC20Upgradeable(position),
                optionsAmount,
                address(sportsAMM)
            );
        }
    }

    /// @notice request withdrawal from the LP
    /// @param market to check
    /// @return roundPool the pool for the passed market
    function getOrCreateMarketPool(address market)
        external
        onlyAMM
        nonReentrant
        whenNotPaused
        roundClosingNotPrepared
        returns (address roundPool)
    {
        uint marketRound = getMarketRound(market);
        roundPool = _getOrCreateRoundPool(marketRound);
    }

    /// @notice request withdrawal from the LP
    function withdrawalRequest() external nonReentrant whenNotPaused roundClosingNotPrepared {
        require(started, "Pool has not started");
        require(!withdrawalRequested[msg.sender], "Withdrawal already requested");
        require(balancesPerRound[round][msg.sender] > 0, "Nothing to withdraw");
        require(balancesPerRound[round + 1][msg.sender] == 0, "Can't withdraw as you already deposited for next round");

        if (!whitelistedDeposits[msg.sender]) {
            require(
                balancesPerRound[round][msg.sender] <
                    _transformCollateral(((stakingThales.stakedBalanceOf(msg.sender) * stakedThalesMultiplier) / ONE)),
                "Not enough staked THALES"
            );
        }

        if (totalDeposited > balancesPerRound[round][msg.sender]) {
            totalDeposited -= balancesPerRound[round][msg.sender];
        } else {
            totalDeposited = 0;
        }

        usersCurrentlyInPool = usersCurrentlyInPool - 1;
        withdrawalRequested[msg.sender] = true;
        emit WithdrawalRequested(msg.sender);
    }

    /// @notice Prepare round closing
    /// excercise options of trading markets and ensure there are no markets left unresolved
    function prepareRoundClosing() external nonReentrant whenNotPaused roundClosingNotPrepared {
        require(canCloseCurrentRound(), "Can't close current round");
        // excercise market options
        exerciseMarketsReadyToExercised();

        address roundPool = roundPools[round];
        // final balance is the final amount of sUSD in the round pool
        uint currentBalance = sUSD.balanceOf(roundPool);
        // calculate PnL

        // if no allocation for current round
        if (allocationPerRound[round] == 0) {
            profitAndLossPerRound[round] = 1;
        } else {
            profitAndLossPerRound[round] = (currentBalance * ONE) / allocationPerRound[round];
        }

        roundClosingPrepared = true;
    }

    /// @notice Prepare round closing
    /// excercise options of trading markets and ensure there are no markets left unresolved
    function processRoundClosingBatch(uint batchSize) external nonReentrant whenNotPaused {
        require(roundClosingPrepared, "Round closing not prepared");
        require(usersProcessedInRound < usersPerRound[round].length, "All users already processed");
        require(batchSize > 0, "batchSize has to be greater than 0");

        address roundPool = roundPools[round];

        uint endCursor = usersProcessedInRound + batchSize;
        if (endCursor > usersPerRound[round].length) {
            endCursor = usersPerRound[round].length;
        }

        for (uint i = usersProcessedInRound; i < endCursor; i++) {
            address user = usersPerRound[round][i];
            uint balanceAfterCurRound = (balancesPerRound[round][user] * profitAndLossPerRound[round]) / ONE;
            if (!withdrawalRequested[user] && (profitAndLossPerRound[round] > 0)) {
                balancesPerRound[round + 1][user] = balancesPerRound[round + 1][user] + balanceAfterCurRound;
                usersPerRound[round + 1].push(user);
                if (address(stakingThales) != address(0)) {
                    stakingThales.updateVolume(user, balanceAfterCurRound);
                }
            } else {
                balancesPerRound[round + 1][user] = 0;
                sUSD.safeTransferFrom(roundPool, user, balanceAfterCurRound);
                withdrawalRequested[user] = false;
                emit Claimed(user, balanceAfterCurRound);
            }
            usersProcessedInRound = usersProcessedInRound + 1;
        }
    }

    /// @notice Close current round and begin next round,
    /// calculate profit and loss and process withdrawals
    function closeRound() external nonReentrant whenNotPaused {
        require(roundClosingPrepared, "Round closing not prepared");
        require(usersProcessedInRound == usersPerRound[round].length, "Not all users processed yet");
        // set for next round to false
        roundClosingPrepared = false;

        address roundPool = roundPools[round];

        //always claim for defaultLiquidityProvider
        if (balancesPerRound[round][defaultLiquidityProvider] > 0) {
            uint balanceAfterCurRound = (balancesPerRound[round][defaultLiquidityProvider] * profitAndLossPerRound[round]) /
                ONE;
            sUSD.safeTransferFrom(roundPool, defaultLiquidityProvider, balanceAfterCurRound);
            emit Claimed(defaultLiquidityProvider, balanceAfterCurRound);
        }

        if (round == 1) {
            cumulativeProfitAndLoss[round] = profitAndLossPerRound[round];
        } else {
            cumulativeProfitAndLoss[round] = (cumulativeProfitAndLoss[round - 1] * profitAndLossPerRound[round]) / ONE;
        }

        // start next round
        round += 1;

        //add all carried over sUSD
        allocationPerRound[round] += sUSD.balanceOf(roundPool);

        totalDeposited = allocationPerRound[round] - balancesPerRound[round][defaultLiquidityProvider];

        address roundPoolNewRound = _getOrCreateRoundPool(round);

        sUSD.safeTransferFrom(roundPool, roundPoolNewRound, sUSD.balanceOf(roundPool));

        usersProcessedInRound = 0;

        emit RoundClosed(round - 1, profitAndLossPerRound[round - 1]);
    }

    /// @notice Iterate all markets in the current round and exercise those ready to be exercised
    function exerciseMarketsReadyToExercised() public roundClosingNotPrepared {
        SportAMMLiquidityPoolRound poolRound = SportAMMLiquidityPoolRound(roundPools[round]);
        ISportPositionalMarket market;
        for (uint i = 0; i < tradingMarketsPerRound[round].length; i++) {
            address marketAddress = tradingMarketsPerRound[round][i];
            if (!marketAlreadyExercisedInRound[round][marketAddress]) {
                market = ISportPositionalMarket(marketAddress);
                if (market.resolved()) {
                    poolRound.exerciseMarketReadyToExercised(market);
                    marketAlreadyExercisedInRound[round][marketAddress] = true;
                }
            }
        }
    }

    /* ========== VIEWS ========== */

    /// @notice whether the user is currently LPing
    /// @param user to check
    /// @return isUserInLP whether the user is currently LPing
    function isUserLPing(address user) external view returns (bool isUserInLP) {
        isUserInLP =
            (balancesPerRound[round][user] > 0 || balancesPerRound[round + 1][user] > 0) &&
            !withdrawalRequested[user];
    }

    /// @notice Return the maximum amount the user can deposit now
    /// @param user address to check
    /// @return maxDepositForUser the maximum amount the user can deposit in total including already deposited
    /// @return availableToDepositForUser the maximum amount the user can deposit now
    /// @return stakedThalesForUser how much THALES the user has staked
    function getMaxAvailableDepositForUser(address user)
        external
        view
        returns (
            uint maxDepositForUser,
            uint availableToDepositForUser,
            uint stakedThalesForUser
        )
    {
        uint nextRound = round + 1;
        stakedThalesForUser = stakingThales.stakedBalanceOf(user);
        maxDepositForUser = _transformCollateral((stakedThalesForUser * stakedThalesMultiplier) / ONE);
        availableToDepositForUser = maxDepositForUser > (balancesPerRound[round][user] + balancesPerRound[nextRound][user])
            ? (maxDepositForUser - balancesPerRound[round][user] - balancesPerRound[nextRound][user])
            : 0;
    }

    /// @notice Return how much the user needs to have staked to withdraw
    /// @param user address to check
    /// @return neededStaked how much the user needs to have staked to withdraw
    function getNeededStakedThalesToWithdrawForUser(address user) external view returns (uint neededStaked) {
        uint nextRound = round + 1;
        neededStaked =
            _reverseTransformCollateral((balancesPerRound[round][user] + balancesPerRound[nextRound][user]) * ONE) /
            stakedThalesMultiplier;
    }

    /// @notice get the pool address for the market
    /// @param market to check
    /// @return roundPool the pool address for the market
    function getMarketPool(address market) external view returns (address roundPool) {
        roundPool = roundPools[getMarketRound(market)];
    }

    /// @notice Checks if all conditions are met to close the round
    /// @return bool
    function canCloseCurrentRound() public view returns (bool) {
        if (!started || block.timestamp < getRoundEndTime(round)) {
            return false;
        }
        ISportPositionalMarket market;
        for (uint i = 0; i < tradingMarketsPerRound[round].length; i++) {
            address marketAddress = tradingMarketsPerRound[round][i];
            if (!marketAlreadyExercisedInRound[round][marketAddress]) {
                market = ISportPositionalMarket(marketAddress);
                if (!market.resolved()) {
                    return false;
                }
            }
        }
        return true;
    }

    /// @notice Iterate all markets in the current round and return true if at least one can be exercised
    function hasMarketsReadyToBeExercised() public view returns (bool) {
        SportAMMLiquidityPoolRound poolRound = SportAMMLiquidityPoolRound(roundPools[round]);
        ISportPositionalMarket market;
        for (uint i = 0; i < tradingMarketsPerRound[round].length; i++) {
            address marketAddress = tradingMarketsPerRound[round][i];
            if (!marketAlreadyExercisedInRound[round][marketAddress]) {
                market = ISportPositionalMarket(marketAddress);
                if (market.resolved()) {
                    (uint homeBalance, uint awayBalance, uint drawBalance) = market.balancesOf(address(poolRound));
                    if (homeBalance > 0 || awayBalance > 0 || drawBalance > 0) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /// @notice Return multiplied PnLs between rounds
    /// @param roundA Round number from
    /// @param roundB Round number to
    /// @return uint
    function cumulativePnLBetweenRounds(uint roundA, uint roundB) public view returns (uint) {
        return (cumulativeProfitAndLoss[roundB] * profitAndLossPerRound[roundA]) / cumulativeProfitAndLoss[roundA];
    }

    /// @notice Return the start time of the passed round
    /// @param _round number
    /// @return uint the start time of the given round
    function getRoundStartTime(uint _round) public view returns (uint) {
        return firstRoundStartTime + (_round - 1) * roundLength;
    }

    /// @notice Return the end time of the passed round
    /// @param _round number
    /// @return uint the end time of the given round
    function getRoundEndTime(uint _round) public view returns (uint) {
        return firstRoundStartTime + _round * roundLength;
    }

    /// @notice Return the round to which a market belongs to
    /// @param market to get the round for
    /// @return _round the round which the market belongs to
    function getMarketRound(address market) public view returns (uint _round) {
        ISportPositionalMarket marketContract = ISportPositionalMarket(market);
        (uint maturity, ) = marketContract.times();
        if (maturity > firstRoundStartTime) {
            _round = (maturity - firstRoundStartTime) / roundLength + 1;
        } else {
            _round = 1;
        }
    }

    /// @notice Return the count of users in current round
    /// @return _the count of users in current round
    function getUsersCountInCurrentRound() external view returns (uint) {
        return usersPerRound[round].length;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _transformCollateral(uint value) internal view returns (uint) {
        if (needsTransformingCollateral) {
            return value / 1e12;
        } else {
            return value;
        }
    }

    function _reverseTransformCollateral(uint value) internal view returns (uint) {
        if (needsTransformingCollateral) {
            return value * 1e12;
        } else {
            return value;
        }
    }

    function _depositAsDefault(
        uint amount,
        address roundPool,
        uint _round
    ) internal {
        require(defaultLiquidityProvider != address(0), "default liquidity provider not set");

        sUSD.safeTransferFrom(defaultLiquidityProvider, roundPool, amount);

        balancesPerRound[_round][defaultLiquidityProvider] += amount;
        allocationPerRound[_round] += amount;

        emit Deposited(defaultLiquidityProvider, amount, _round);
    }

    function _getOrCreateRoundPool(uint _round) internal returns (address roundPool) {
        roundPool = roundPools[_round];
        if (roundPool == address(0)) {
            require(poolRoundMastercopy != address(0), "Round pool mastercopy not set");
            SportAMMLiquidityPoolRound newRoundPool = SportAMMLiquidityPoolRound(Clones.clone(poolRoundMastercopy));
            newRoundPool.initialize(address(this), sUSD, _round, getRoundEndTime(_round), getRoundEndTime(_round + 1));
            roundPool = address(newRoundPool);
            roundPools[_round] = roundPool;
            emit RoundPoolCreated(_round, roundPool);
        }
    }

    /* ========== SETTERS ========== */

    function setPaused(bool _setPausing) external onlyOwner {
        _setPausing ? _pause() : _unpause();
    }

    /// @notice Set onlyWhitelistedStakersAllowed variable
    /// @param flagToSet self explanatory
    function setOnlyWhitelistedStakersAllowed(bool flagToSet) external onlyOwner {
        onlyWhitelistedStakersAllowed = flagToSet;
    }

    /// @notice setNeedsTransformingCollateral sets needsTransformingCollateral value
    /// @param _needsTransformingCollateral boolen value to be set
    function setNeedsTransformingCollateral(bool _needsTransformingCollateral) external onlyOwner {
        needsTransformingCollateral = _needsTransformingCollateral;
    }

    /// @notice Set _poolRoundMastercopy
    /// @param _poolRoundMastercopy to clone round pools from
    function setPoolRoundMastercopy(address _poolRoundMastercopy) external onlyOwner {
        poolRoundMastercopy = _poolRoundMastercopy;
        emit PoolRoundMastercopyChanged(poolRoundMastercopy);
    }

    /// @notice Set _stakedThalesMultiplier
    /// @param _stakedThalesMultiplier the number of sUSD one can deposit per THALES staked
    function setStakedThalesMultiplier(uint _stakedThalesMultiplier) external onlyOwner {
        stakedThalesMultiplier = _stakedThalesMultiplier;
        emit StakedThalesMultiplierChanged(_stakedThalesMultiplier);
    }

    /// @notice Set IStakingThales contract
    /// @param _stakingThales IStakingThales address
    function setStakingThales(IStakingThales _stakingThales) external onlyOwner {
        stakingThales = _stakingThales;
        emit StakingThalesChanged(address(_stakingThales));
    }

    /// @notice Set max allowed deposit
    /// @param _maxAllowedDeposit Deposit value
    function setMaxAllowedDeposit(uint _maxAllowedDeposit) external onlyOwner {
        maxAllowedDeposit = _maxAllowedDeposit;
        emit MaxAllowedDepositChanged(_maxAllowedDeposit);
    }

    /// @notice Set min allowed deposit
    /// @param _minDepositAmount Deposit value
    function setMinAllowedDeposit(uint _minDepositAmount) external onlyOwner {
        minDepositAmount = _minDepositAmount;
        emit MinAllowedDepositChanged(_minDepositAmount);
    }

    /// @notice Set _maxAllowedUsers
    /// @param _maxAllowedUsers Deposit value
    function setMaxAllowedUsers(uint _maxAllowedUsers) external onlyOwner {
        maxAllowedUsers = _maxAllowedUsers;
        emit MaxAllowedUsersChanged(_maxAllowedUsers);
    }

    /// @notice Set ThalesAMM contract
    /// @param _sportAMM ThalesAMM address
    function setSportAmm(ISportsAMM _sportAMM) external onlyOwner {
        sportsAMM = _sportAMM;
        sUSD.approve(address(sportsAMM), type(uint256).max);
        emit SportAMMChanged(address(_sportAMM));
    }

    /// @notice Set defaultLiquidityProvider wallet
    /// @param _defaultLiquidityProvider default liquidity provider
    function setDefaultLiquidityProvider(address _defaultLiquidityProvider) external onlyOwner {
        defaultLiquidityProvider = _defaultLiquidityProvider;
        emit DefaultLiquidityProviderChanged(_defaultLiquidityProvider);
    }

    /// @notice Set length of rounds
    /// @param _roundLength Length of a round in miliseconds
    function setRoundLength(uint _roundLength) external onlyOwner {
        require(!started, "Can't change round length after start");
        roundLength = _roundLength;
        emit RoundLengthChanged(_roundLength);
    }

    /// @notice This method only serves as a failsafe to extract tokens from a pool round contract
    /// @param tokens to iterate and transfer
    /// @param account Address where to send the tokens
    /// @param amount Amount of tokens to be sent
    /// @param pool where to transfer from
    /// @param all ignore amount and send whole balance
    function transferTokensFromLiquidityPool(
        address[] calldata tokens,
        address payable account,
        uint amount,
        bool all,
        address pool
    ) external onlyOwner {
        require(tokens.length > 0, "tokens array cant be empty");
        for (uint256 index = 0; index < tokens.length; index++) {
            if (all) {
                IERC20Upgradeable(tokens[index]).safeTransferFrom(
                    pool,
                    account,
                    IERC20Upgradeable(tokens[index]).balanceOf(pool)
                );
            } else {
                IERC20Upgradeable(tokens[index]).safeTransferFrom(pool, account, amount);
            }
        }
    }

    /// @notice This method only serves as a failsafe to extract tokens from this contract
    /// @param tokens to iterate and transfer
    /// @param account Address where to send the tokens
    /// @param amount Amount of tokens to be sent
    /// @param all ignore amount and send whole balance
    function transferTokens(
        address[] calldata tokens,
        address payable account,
        uint amount,
        bool all
    ) external onlyOwner {
        require(tokens.length > 0, "Whitelisted addresses cannot be empty");
        for (uint256 index = 0; index < tokens.length; index++) {
            if (all) {
                IERC20Upgradeable(tokens[index]).safeTransfer(
                    account,
                    IERC20Upgradeable(tokens[index]).balanceOf(address(this))
                );
            } else {
                IERC20Upgradeable(tokens[index]).safeTransfer(account, amount);
            }
        }
    }

    /// @notice set addresses which can deposit into the AMM bypassing the staking checks
    /// @param _whitelistedAddresses Addresses to set the whitelist flag for
    /// @param _flag to set
    function setWhitelistedAddresses(address[] calldata _whitelistedAddresses, bool _flag) external onlyOwner {
        require(_whitelistedAddresses.length > 0, "Whitelisted addresses cannot be empty");
        for (uint256 index = 0; index < _whitelistedAddresses.length; index++) {
            // only if current flag is different, if same skip it
            if (whitelistedDeposits[_whitelistedAddresses[index]] != _flag) {
                whitelistedDeposits[_whitelistedAddresses[index]] = _flag;
                emit AddedIntoWhitelist(_whitelistedAddresses[index], _flag);
            }
        }
    }

    /// @notice set addresses which can deposit into the AMM when only whitelisted stakers are allowed
    /// @param _whitelistedAddresses Addresses to set the whitelist flag for
    /// @param _flag to set
    function setWhitelistedStakerAddresses(address[] calldata _whitelistedAddresses, bool _flag) external onlyOwner {
        require(_whitelistedAddresses.length > 0, "Whitelisted addresses cannot be empty");
        for (uint256 index = 0; index < _whitelistedAddresses.length; index++) {
            // only if current flag is different, if same skip it
            if (whitelistedStakers[_whitelistedAddresses[index]] != _flag) {
                whitelistedStakers[_whitelistedAddresses[index]] = _flag;
                emit AddedIntoWhitelistStaker(_whitelistedAddresses[index], _flag);
            }
        }
    }

    /* ========== MODIFIERS ========== */

    modifier canDeposit(uint amount) {
        require(!withdrawalRequested[msg.sender], "Withdrawal is requested, cannot deposit");
        require(amount >= minDepositAmount, "Amount less than minDepositAmount");
        require(totalDeposited + amount <= maxAllowedDeposit, "Deposit amount exceeds AMM LP cap");
        _;
    }

    modifier onlyAMM() {
        require(msg.sender == address(sportsAMM), "only the AMM may perform these methods");
        _;
    }

    modifier roundClosingNotPrepared() {
        require(!roundClosingPrepared, "Not allowed during roundClosingPrepared");
        _;
    }

    /* ========== EVENTS ========== */
    event PoolStarted();
    event Deposited(address user, uint amount, uint round);
    event WithdrawalRequested(address user);
    event RoundClosed(uint round, uint roundPnL);
    event Claimed(address user, uint amount);
    event RoundPoolCreated(uint _round, address roundPool);
    event PoolRoundMastercopyChanged(address newMastercopy);
    event StakedThalesMultiplierChanged(uint _stakedThalesMultiplier);
    event StakingThalesChanged(address stakingThales);
    event MaxAllowedDepositChanged(uint maxAllowedDeposit);
    event MinAllowedDepositChanged(uint minAllowedDeposit);
    event MaxAllowedUsersChanged(uint MaxAllowedUsersChanged);
    event SportAMMChanged(address sportAMM);
    event DefaultLiquidityProviderChanged(address newProvider);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event AddedIntoWhitelistStaker(address _whitelistAddress, bool _flag);
    event RoundLengthChanged(uint roundLength);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarket.sol";

interface IPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function durations() external view returns (uint expiryDuration, uint maxTimeToMaturity);

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function onlyAMMMintingAndBurning() external view returns (bool);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getThalesAMM() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint // initial sUSD to mint options for,
    ) external returns (IPositionalMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPriceFeed {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface IPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Up,
        Down
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions() external view returns (IPosition up, IPosition down);

    function times() external view returns (uint maturity, uint destructino);

    function getOracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees() external view returns (uint poolFee, uint creatorFee);

    function deposited() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePrice() external view returns (uint);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint up, uint down);

    function totalSupplies() external view returns (uint up, uint down);

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../interfaces/ISportPositionalMarket.sol";

import "./SportAMMLiquidityPool.sol";

contract SportAMMLiquidityPoolRound {
    /* ========== LIBRARIES ========== */
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    SportAMMLiquidityPool public liquidityPool;
    IERC20Upgradeable public sUSD;

    uint public round;
    uint public roundStartTime;
    uint public roundEndTime;

    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(
        address _liquidityPool,
        IERC20Upgradeable _sUSD,
        uint _round,
        uint _roundStartTime,
        uint _roundEndTime
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;
        liquidityPool = SportAMMLiquidityPool(_liquidityPool);
        sUSD = _sUSD;
        round = _round;
        roundStartTime = _roundStartTime;
        roundEndTime = _roundEndTime;
        sUSD.approve(_liquidityPool, type(uint256).max);
    }

    function exerciseMarketReadyToExercised(ISportPositionalMarket market) external onlyLiquidityPool {
        if (market.resolved()) {
            (uint homeBalance, uint awayBalance, uint drawBalance) = market.balancesOf(address(this));
            if (homeBalance > 0 || awayBalance > 0 || drawBalance > 0) {
                market.exerciseOptions();
            }
        }
    }

    function moveOptions(
        IERC20Upgradeable option,
        uint optionsAmount,
        address destination
    ) external onlyLiquidityPool {
        option.safeTransfer(destination, optionsAmount);
    }

    modifier onlyLiquidityPool() {
        require(msg.sender == address(liquidityPool), "only the Pool manager may perform these methods");
        _;
    }
}