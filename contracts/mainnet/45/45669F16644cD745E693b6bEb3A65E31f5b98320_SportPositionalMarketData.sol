// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../interfaces/ISportsAMM.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/IGamesOddsObtainer.sol";

import "../../interfaces/IParlayMarketsAMM.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SportPositionalMarket.sol";
import "./SportPositionalMarketManager.sol";
import "../Rundown/GamesOddsObtainer.sol";
import "../Rundown/TherundownConsumer.sol";
import "../Voucher/OvertimeVoucherEscrow.sol";

contract SportPositionalMarketData is Initializable, ProxyOwned, ProxyPausable {
    uint private constant TAG_NUMBER_SPREAD = 10001;
    uint private constant TAG_NUMBER_TOTAL = 10002;
    uint private constant DOUBLE_CHANCE_TAG = 10003;
    struct ActiveMarketsOdds {
        address market;
        uint[] odds;
    }

    struct ActiveMarketsPriceImpact {
        address market;
        int[] priceImpact;
    }

    struct MarketData {
        bytes32 gameId;
        string gameLabel;
        uint firstTag;
        uint secondTag;
        uint maturity;
        bool resolved;
        uint finalResult;
        bool cancelled;
        bool paused;
        uint[] odds;
        address[] childMarkets;
        address[] doubleChanceMarkets;
        uint8 homeScore;
        uint8 awayScore;
        int16 spread;
        uint24 total;
    }

    struct MarketLiquidityAndPriceImpact {
        int homePriceImpact;
        int awayPriceImpact;
        int drawPriceImpact;
        uint homeLiquidity;
        uint awayLiquidity;
        uint drawLiquidity;
    }

    struct PositionDetails {
        int priceImpact;
        uint liquidity;
        uint quote;
        uint quoteDifferentCollateral;
    }

    struct VoucherEscrowData {
        uint period;
        bool isWhitelisted;
        bool isClaimed;
        uint voucherAmount;
        bool isPeriodEnded;
        uint periodEnd;
    }
    struct CombinedOdds {
        uint[2] tags;
        uint[6] odds;
    }
    struct SameGameParlayMarket {
        address mainMarket;
        CombinedOdds[] combinedOdds;
    }

    uint private constant ONE = 1e18;

    address public manager;
    address public sportsAMM;
    address public oddsObtainer;
    address public consumer;
    address public voucherEscrow;

    function initialize(address _owner) external initializer {
        setOwner(_owner);
    }

    function getOddsForAllActiveMarkets() external view returns (ActiveMarketsOdds[] memory) {
        address[] memory activeMarkets = SportPositionalMarketManager(manager).activeMarkets(
            0,
            SportPositionalMarketManager(manager).numActiveMarkets()
        );
        ActiveMarketsOdds[] memory marketOdds = new ActiveMarketsOdds[](activeMarkets.length);
        for (uint i = 0; i < activeMarkets.length; i++) {
            marketOdds[i].market = activeMarkets[i];
            marketOdds[i].odds = ISportsAMM(sportsAMM).getMarketDefaultOdds(activeMarkets[i], false);
        }
        return marketOdds;
    }

    function getOddsForAllActiveMarketsInBatches(uint batchNumber, uint batchSize)
        external
        view
        returns (ActiveMarketsOdds[] memory)
    {
        address[] memory activeMarkets = SportPositionalMarketManager(manager).activeMarkets(
            batchNumber * batchSize,
            batchSize
        );
        ActiveMarketsOdds[] memory marketOdds = new ActiveMarketsOdds[](activeMarkets.length);
        for (uint i = 0; i < activeMarkets.length; i++) {
            marketOdds[i].market = activeMarkets[i];
            marketOdds[i].odds = ISportsAMM(sportsAMM).getMarketDefaultOdds(activeMarkets[i], false);
        }
        return marketOdds;
    }

    function getBaseOddsForAllActiveMarkets() external view returns (ActiveMarketsOdds[] memory) {
        address[] memory activeMarkets = SportPositionalMarketManager(manager).activeMarkets(
            0,
            SportPositionalMarketManager(manager).numActiveMarkets()
        );
        ActiveMarketsOdds[] memory marketOdds = new ActiveMarketsOdds[](activeMarkets.length);
        for (uint i = 0; i < activeMarkets.length; i++) {
            marketOdds[i].market = activeMarkets[i];
            marketOdds[i].odds = new uint[](SportPositionalMarket(activeMarkets[i]).optionsCount());

            for (uint j = 0; j < marketOdds[i].odds.length; j++) {
                if (ISportsAMM(sportsAMM).isMarketInAMMTrading(activeMarkets[i])) {
                    ISportsAMM.Position position;
                    if (j == 0) {
                        position = ISportsAMM.Position.Home;
                    } else if (j == 1) {
                        position = ISportsAMM.Position.Away;
                    } else {
                        position = ISportsAMM.Position.Draw;
                    }
                    marketOdds[i].odds[j] = ISportsAMM(sportsAMM).obtainOdds(activeMarkets[i], position);
                }
            }
        }
        return marketOdds;
    }

    function getPriceImpactForAllActiveMarketsInBatches(uint batchNumber, uint batchSize)
        external
        view
        returns (ActiveMarketsPriceImpact[] memory)
    {
        address[] memory activeMarkets = SportPositionalMarketManager(manager).activeMarkets(
            batchNumber * batchSize,
            batchSize
        );
        ActiveMarketsPriceImpact[] memory marketPriceImpact = new ActiveMarketsPriceImpact[](activeMarkets.length);
        for (uint i = 0; i < activeMarkets.length; i++) {
            marketPriceImpact[i].market = activeMarkets[i];
            marketPriceImpact[i].priceImpact = new int[](SportPositionalMarket(activeMarkets[i]).optionsCount());

            for (uint j = 0; j < marketPriceImpact[i].priceImpact.length; j++) {
                if (ISportsAMM(sportsAMM).isMarketInAMMTrading(activeMarkets[i])) {
                    ISportsAMM.Position position;
                    if (j == 0) {
                        position = ISportsAMM.Position.Home;
                    } else if (j == 1) {
                        position = ISportsAMM.Position.Away;
                    } else {
                        position = ISportsAMM.Position.Draw;
                    }
                    marketPriceImpact[i].priceImpact[j] = ISportsAMM(sportsAMM).buyPriceImpact(
                        activeMarkets[i],
                        position,
                        ONE
                    );
                }
            }
        }
        return marketPriceImpact;
    }

    function getPriceImpactForAllActiveMarkets() external view returns (ActiveMarketsPriceImpact[] memory) {
        address[] memory activeMarkets = SportPositionalMarketManager(manager).activeMarkets(
            0,
            SportPositionalMarketManager(manager).numActiveMarkets()
        );
        ActiveMarketsPriceImpact[] memory marketPriceImpact = new ActiveMarketsPriceImpact[](activeMarkets.length);
        for (uint i = 0; i < activeMarkets.length; i++) {
            marketPriceImpact[i].market = activeMarkets[i];
            marketPriceImpact[i].priceImpact = new int[](SportPositionalMarket(activeMarkets[i]).optionsCount());

            for (uint j = 0; j < marketPriceImpact[i].priceImpact.length; j++) {
                if (ISportsAMM(sportsAMM).isMarketInAMMTrading(activeMarkets[i])) {
                    ISportsAMM.Position position;
                    if (j == 0) {
                        position = ISportsAMM.Position.Home;
                    } else if (j == 1) {
                        position = ISportsAMM.Position.Away;
                    } else {
                        position = ISportsAMM.Position.Draw;
                    }
                    marketPriceImpact[i].priceImpact[j] = ISportsAMM(sportsAMM).buyPriceImpact(
                        activeMarkets[i],
                        position,
                        ONE
                    );
                }
            }
        }
        return marketPriceImpact;
    }

    function getCombinedOddsForBatchOfMarkets(address[] memory _marketBatch)
        external
        view
        returns (SameGameParlayMarket[] memory sgpMarkets)
    {
        sgpMarkets = new SameGameParlayMarket[](_marketBatch.length);
        for (uint i = 0; i < _marketBatch.length; i++) {
            sgpMarkets[i] = _getCombinedOddsForMarket(_marketBatch[i]);
        }
    }

    function getCombinedOddsForMarket(address _mainMarket) external view returns (SameGameParlayMarket memory sgpMarket) {
        sgpMarket = _getCombinedOddsForMarket(_mainMarket);
    }

    function _getCombinedOddsForMarket(address _mainMarket) internal view returns (SameGameParlayMarket memory sgpMarket) {
        if (ISportPositionalMarketManager(manager).isActiveMarket(_mainMarket)) {
            sgpMarket.mainMarket = _mainMarket;
            (address totalsMarket, address spreadMarket) = IGamesOddsObtainer(
                ISportPositionalMarketManager(manager).getOddsObtainer()
            ).getActiveChildMarketsFromParent(_mainMarket);
            CombinedOdds[] memory totalCombainedOdds = new CombinedOdds[](2);
            if (totalsMarket != address(0)) {
                CombinedOdds memory newCombinedOdds;
                newCombinedOdds.tags = [
                    ISportPositionalMarket(totalsMarket).tags(0),
                    ISportPositionalMarket(totalsMarket).tags(1)
                ];
                if (
                    IParlayMarketsAMM(ISportsAMM(sportsAMM).parlayAMM()).getSgpFeePerCombination(
                        newCombinedOdds.tags[0],
                        0,
                        newCombinedOdds.tags[1]
                    ) > 0
                ) {
                    uint numOfOdds = ISportPositionalMarket(_mainMarket).optionsCount() > 2 ? 6 : 4;
                    for (uint j = 0; j < numOfOdds; j++) {
                        address[] memory markets = new address[](2);
                        markets[0] = _mainMarket;
                        markets[1] = totalsMarket;
                        uint[] memory positions = new uint[](2);
                        positions[0] = j > 1 ? (j > 3 ? 2 : 1) : 0;
                        positions[1] = j % 2;
                        (, , newCombinedOdds.odds[j], , , , ) = IParlayMarketsAMM(ISportsAMM(sportsAMM).parlayAMM())
                            .buyQuoteFromParlay(markets, positions, ONE);
                    }
                    newCombinedOdds.tags[0] = 0;
                    totalCombainedOdds[0] = newCombinedOdds;
                }
            }
            if (spreadMarket != address(0)) {
                CombinedOdds memory newCombinedOdds;
                newCombinedOdds.tags = [
                    ISportPositionalMarket(spreadMarket).tags(1),
                    ISportPositionalMarket(totalsMarket).tags(1)
                ];
                if (
                    IParlayMarketsAMM(ISportsAMM(sportsAMM).parlayAMM()).getSgpFeePerCombination(
                        ISportPositionalMarket(totalsMarket).tags(0),
                        newCombinedOdds.tags[0],
                        newCombinedOdds.tags[1]
                    ) > 0
                ) {
                    for (uint j = 0; j < 4; j++) {
                        address[] memory markets = new address[](2);
                        markets[0] = totalsMarket;
                        markets[1] = spreadMarket;
                        uint[] memory positions = new uint[](2);
                        positions[0] = j > 1 ? 1 : 0;
                        positions[1] = j % 2;
                        (, , newCombinedOdds.odds[j], , , , ) = IParlayMarketsAMM(ISportsAMM(sportsAMM).parlayAMM())
                            .buyQuoteFromParlay(markets, positions, ONE);
                    }
                    totalCombainedOdds[1] = newCombinedOdds;
                }
            }
            sgpMarket.combinedOdds = totalCombainedOdds;
        }
    }

    function getMarketData(address market) external view returns (MarketData memory) {
        SportPositionalMarket sportMarket = SportPositionalMarket(market);

        (bytes32 gameId, string memory gameLabel) = sportMarket.getGameDetails();
        uint secondTag = sportMarket.isDoubleChance() || sportMarket.isChild() ? sportMarket.tags(1) : 0;
        (uint maturity, ) = sportMarket.times();
        (, uint8 homeScore, uint8 awayScore, , ) = TherundownConsumer(consumer).gameResolved(gameId);

        return
            MarketData(
                gameId,
                gameLabel,
                sportMarket.tags(0),
                secondTag,
                maturity,
                sportMarket.resolved(),
                sportMarket.finalResult(),
                sportMarket.cancelled(),
                sportMarket.paused(),
                ISportsAMM(sportsAMM).getMarketDefaultOdds(market, false),
                GamesOddsObtainer(oddsObtainer).getAllChildMarketsFromParent(market),
                SportPositionalMarketManager(manager).getDoubleChanceMarketsByParentMarket(market),
                homeScore,
                awayScore,
                GamesOddsObtainer(oddsObtainer).childMarketSread(market),
                GamesOddsObtainer(oddsObtainer).childMarketTotal(market)
            );
    }

    function getMarketLiquidityAndPriceImpact(address market) external view returns (MarketLiquidityAndPriceImpact memory) {
        SportPositionalMarket sportMarket = SportPositionalMarket(market);
        uint optionsCount = sportMarket.optionsCount();

        MarketLiquidityAndPriceImpact memory marketLiquidityAndPriceImpact = MarketLiquidityAndPriceImpact(0, 0, 0, 0, 0, 0);

        for (uint i = 0; i < optionsCount; i++) {
            ISportsAMM.Position position;
            if (i == 0) {
                position = ISportsAMM.Position.Home;
                marketLiquidityAndPriceImpact.homePriceImpact = ISportsAMM(sportsAMM).buyPriceImpact(market, position, ONE);
                marketLiquidityAndPriceImpact.homeLiquidity = ISportsAMM(sportsAMM).availableToBuyFromAMM(market, position);
            } else if (i == 1) {
                position = ISportsAMM.Position.Away;
                marketLiquidityAndPriceImpact.awayPriceImpact = ISportsAMM(sportsAMM).buyPriceImpact(market, position, ONE);
                marketLiquidityAndPriceImpact.awayLiquidity = ISportsAMM(sportsAMM).availableToBuyFromAMM(market, position);
            } else {
                position = ISportsAMM.Position.Draw;
                marketLiquidityAndPriceImpact.drawPriceImpact = ISportsAMM(sportsAMM).buyPriceImpact(market, position, ONE);
                marketLiquidityAndPriceImpact.drawLiquidity = ISportsAMM(sportsAMM).availableToBuyFromAMM(market, position);
            }
        }

        return marketLiquidityAndPriceImpact;
    }

    function getPositionDetails(
        address market,
        ISportsAMM.Position position,
        uint amount,
        address collateral
    ) external view returns (PositionDetails memory) {
        uint quoteDifferentCollateral = 0;
        if (collateral != address(0)) {
            (uint collateralQuote, uint sUSDToPay) = ISportsAMM(sportsAMM).buyFromAmmQuoteWithDifferentCollateral(
                market,
                position,
                amount,
                collateral
            );
            quoteDifferentCollateral = collateralQuote;
        }

        return
            PositionDetails(
                ISportsAMM(sportsAMM).buyPriceImpact(market, position, amount),
                ISportsAMM(sportsAMM).availableToBuyFromAMM(market, position),
                ISportsAMM(sportsAMM).buyFromAmmQuote(market, position, amount),
                quoteDifferentCollateral
            );
    }

    function getVoucherEscrowData(address user) external view returns (VoucherEscrowData memory) {
        uint period = OvertimeVoucherEscrow(voucherEscrow).period();

        return
            VoucherEscrowData(
                period,
                OvertimeVoucherEscrow(voucherEscrow).isWhitelistedAddress(user),
                OvertimeVoucherEscrow(voucherEscrow).addressClaimedVoucherPerPeriod(period, user),
                OvertimeVoucherEscrow(voucherEscrow).voucherAmount(),
                OvertimeVoucherEscrow(voucherEscrow).claimingPeriodEnded(),
                OvertimeVoucherEscrow(voucherEscrow).periodEnd(period)
            );
    }

    function setSportPositionalMarketManager(address _manager) external onlyOwner {
        manager = _manager;
        emit SportPositionalMarketManagerChanged(_manager);
    }

    function setSportsAMM(address _sportsAMM) external onlyOwner {
        sportsAMM = _sportsAMM;
        emit SetSportsAMM(_sportsAMM);
    }

    function setOddsObtainer(address _oddsObtainer) external onlyOwner {
        oddsObtainer = _oddsObtainer;
        emit SetOddsObtainer(_oddsObtainer);
    }

    function setConsumer(address _consumer) external onlyOwner {
        consumer = _consumer;
        emit SetConsumer(_consumer);
    }

    function setVoucherEscrow(address _voucherEscrow) external onlyOwner {
        voucherEscrow = _voucherEscrow;
        emit SetVoucherEscrow(_voucherEscrow);
    }

    event SportPositionalMarketManagerChanged(address _manager);
    event SetSportsAMM(address _sportsAMM);
    event SetOddsObtainer(address _oddsObtainer);
    event SetConsumer(address _consumer);
    event SetVoucherEscrow(address _voucherEscrow);
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

    function isMarketForSportOnePositional(uint _tag) external view returns (bool);

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

    function getTags() external view returns (uint tag1, uint tag2);

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

    function getOddsObtainer() external view returns (address obtainer);

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

pragma solidity ^0.8.0;

interface IGamesOddsObtainer {
    struct GameOdds {
        bytes32 gameId;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        int16 spreadHome;
        int24 spreadHomeOdds;
        int16 spreadAway;
        int24 spreadAwayOdds;
        uint24 totalOver;
        int24 totalOverOdds;
        uint24 totalUnder;
        int24 totalUnderOdds;
    }

    // view

    function getActiveChildMarketsFromParent(address _parent) external view returns (address, address);

    function getSpreadTotalsChildMarketsFromParent(address _parent)
        external
        view
        returns (
            uint numOfSpreadMarkets,
            address[] memory spreadMarkets,
            uint numOfTotalsMarkets,
            address[] memory totalMarkets
        );

    function areOddsValid(bytes32 _gameId, bool _useBackup) external view returns (bool);

    function invalidOdds(address _market) external view returns (bool);

    function getNormalizedOdds(bytes32 _gameId) external view returns (uint[] memory);

    function getNormalizedChildOdds(address _market) external view returns (uint[] memory);

    function getOddsForGames(bytes32[] memory _gameIds) external view returns (int24[] memory odds);

    function mainMarketChildMarketIndex(address _main, uint _index) external view returns (address);

    function numberOfChildMarkets(address _main) external view returns (uint);

    function mainMarketSpreadChildMarket(address _main, int16 _spread) external view returns (address);

    function mainMarketTotalChildMarket(address _main, uint24 _total) external view returns (address);

    function childMarketMainMarket(address _market) external view returns (address);

    function currentActiveTotalChildMarket(address _main) external view returns (address);

    function currentActiveSpreadChildMarket(address _main) external view returns (address);

    function isSpreadChildMarket(address _child) external view returns (bool);

    function getOddsForGame(bytes32 _gameId)
        external
        view
        returns (
            int24,
            int24,
            int24,
            int24,
            int24,
            int24,
            int24
        );

    function getLinesForGame(bytes32 _gameId)
        external
        view
        returns (
            int16,
            int16,
            uint24,
            uint24
        );

    // executable

    function obtainOdds(
        bytes32 requestId,
        GameOdds memory _game,
        uint _sportId
    ) external;

    function setFirstOdds(
        bytes32 _gameId,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external;

    function setFirstNormalizedOdds(bytes32 _gameId, address _market) external;

    function setBackupOddsAsMainOddsForGame(bytes32 _gameId) external;

    function pauseUnpauseChildMarkets(address _main, bool _flag) external;

    function pauseUnpauseCurrentActiveChildMarket(
        bytes32 _gameId,
        address _main,
        bool _flag
    ) external;

    function resolveChildMarkets(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) external;

    function setChildMarketGameId(bytes32 gameId, address market) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../SportMarkets/Parlay/ParlayVerifier.sol";

interface IParlayMarketsAMM {
    /* ========== VIEWS / VARIABLES ========== */

    function parlaySize() external view returns (uint);

    function sUSD() external view returns (IERC20Upgradeable);

    function sportsAmm() external view returns (address);

    function parlayAmmFee() external view returns (uint);

    function maxAllowedRiskPerCombination() external view returns (uint);

    function maxSupportedOdds() external view returns (uint);

    function getSgpFeePerCombination(
        uint tag1,
        uint tag2_1,
        uint tag2_2
    ) external view returns (uint sgpFee);

    function riskPerCombination(
        address _sportMarkets1,
        uint _position1,
        address _sportMarkets2,
        uint _position2,
        address _sportMarkets3,
        uint _position3,
        address _sportMarkets4,
        uint _position4
    ) external view returns (uint);

    function riskPerGameCombination(
        address _sportMarkets1,
        address _sportMarkets2,
        address _sportMarkets3,
        address _sportMarkets4,
        address _sportMarkets5,
        address _sportMarkets6,
        address _sportMarkets7,
        address _sportMarkets8
    ) external view returns (uint);

    function riskPerPackedGamesCombination(bytes32 gamesPacked) external view returns (uint);

    function isActiveParlay(address _parlayMarket) external view returns (bool isActiveParlayMarket);

    function exerciseParlay(address _parlayMarket) external;

    function exerciseSportMarketInParlay(address _parlayMarket, address _sportMarket) external;

    function triggerResolvedEvent(address _account, bool _userWon) external;

    function resolveParlay() external;

    function buyFromParlay(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address _differentRecepient
    ) external;

    function buyQuoteFromParlay(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid
    )
        external
        view
        returns (
            uint sUSDAfterFees,
            uint totalBuyAmount,
            uint totalQuote,
            uint initialQuote,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        );

    function canCreateParlayMarket(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDToPay
    ) external view returns (bool canBeCreated);

    function numActiveParlayMarkets() external view returns (uint);

    function activeParlayMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function parlayVerifier() external view returns (ParlayVerifier);

    function minUSDAmount() external view returns (uint);

    function maxSupportedAmount() external view returns (uint);

    function safeBoxImpact() external view returns (uint);
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
pragma solidity ^0.8.0;

// Inheritance
import "../../OwnedWithInit.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ITherundownConsumer.sol";

// Libraries
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./SportPositionalMarketManager.sol";
import "./SportPosition.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";

contract SportPositionalMarket is OwnedWithInit, ISportPositionalMarket {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;

    /* ========== TYPES ========== */

    struct Options {
        SportPosition home;
        SportPosition away;
        SportPosition draw;
    }

    struct Times {
        uint maturity;
        uint expiry;
    }

    struct GameDetails {
        bytes32 gameId;
        string gameLabel;
    }

    struct SportPositionalMarketParameters {
        address owner;
        IERC20 sUSD;
        address creator;
        bytes32 gameId;
        string gameLabel;
        uint[2] times; // [maturity, expiry]
        uint deposit; // sUSD deposit
        address theRundownConsumer;
        address sportsAMM;
        uint positionCount;
        address[] positions;
        uint[] tags;
        bool isChild;
        address parentMarket;
        bool isDoubleChance;
    }

    /* ========== STATE VARIABLES ========== */

    Options public options;
    uint public override optionsCount;
    Times public override times;
    GameDetails public gameDetails;
    ITherundownConsumer public theRundownConsumer;
    IERC20 public sUSD;
    address public sportsAMM;
    uint[] public override tags;
    uint public finalResult;

    // `deposited` tracks the sum of all deposits.
    // This must explicitly be kept, in case tokens are transferred to the contract directly.
    uint public override deposited;
    uint public override initialMint;
    address public override creator;
    bool public override resolved;
    bool public override cancelled;
    uint public cancelTimestamp;
    uint public homeOddsOnCancellation;
    uint public awayOddsOnCancellation;
    uint public drawOddsOnCancellation;

    bool public invalidOdds;
    bool public initialized = false;
    bool public override paused;
    bool public override isChild;
    ISportPositionalMarket public override parentMarket;

    bool public override isDoubleChance;

    /* ========== CONSTRUCTOR ========== */
    function initialize(SportPositionalMarketParameters calldata _parameters) external {
        require(!initialized, "Positional Market already initialized");
        initialized = true;
        initOwner(_parameters.owner);
        sUSD = _parameters.sUSD;
        creator = _parameters.creator;
        theRundownConsumer = ITherundownConsumer(_parameters.theRundownConsumer);

        gameDetails = GameDetails(_parameters.gameId, _parameters.gameLabel);

        tags = _parameters.tags;
        times = Times(_parameters.times[0], _parameters.times[1]);

        deposited = _parameters.deposit;
        initialMint = _parameters.deposit;
        optionsCount = _parameters.positionCount;
        sportsAMM = _parameters.sportsAMM;
        isDoubleChance = _parameters.isDoubleChance;
        parentMarket = ISportPositionalMarket(_parameters.parentMarket);
        require(optionsCount == _parameters.positions.length, "Position count mismatch");

        // Instantiate the options themselves
        options.home = SportPosition(_parameters.positions[0]);
        options.away = SportPosition(_parameters.positions[1]);
        // abi.encodePacked("sUP: ", _oracleKey)
        // consider naming the option: sUpBTC>[email protected]
        if (_parameters.isChild) {
            isChild = true;
            require(tags.length > 1, "Child markets must have two tags");
            if (tags[1] == 10001) {
                options.home.initialize(gameDetails.gameLabel, "HOME", _parameters.sportsAMM);
                options.away.initialize(gameDetails.gameLabel, "AWAY", _parameters.sportsAMM);
            } else if (tags[1] == 10002) {
                options.home.initialize(gameDetails.gameLabel, "OVER", _parameters.sportsAMM);
                options.away.initialize(gameDetails.gameLabel, "UNDER", _parameters.sportsAMM);
            }
        } else {
            options.home.initialize(gameDetails.gameLabel, "HOME", _parameters.sportsAMM);
            options.away.initialize(gameDetails.gameLabel, "AWAY", _parameters.sportsAMM);
        }

        if (optionsCount > 2) {
            options.draw = SportPosition(_parameters.positions[2]);
            options.draw.initialize(gameDetails.gameLabel, "DRAW", _parameters.sportsAMM);
        }
        if (initialMint > 0) {
            _mint(creator, initialMint);
        }

        // Note: the ERC20 base contract does not have a constructor, so we do not have to worry
        // about initializing its state separately
    }

    /* ---------- External Contracts ---------- */

    function _manager() internal view returns (SportPositionalMarketManager) {
        return SportPositionalMarketManager(owner);
    }

    /* ---------- Phases ---------- */

    function _matured() internal view returns (bool) {
        return times.maturity < block.timestamp;
    }

    function _expired() internal view returns (bool) {
        return resolved && (times.expiry < block.timestamp || deposited == 0);
    }

    function _isPaused() internal view returns (bool) {
        return isDoubleChance ? parentMarket.paused() : paused;
    }

    function getTags() external view override returns (uint tag1, uint tag2) {
        if (tags.length > 1) {
            tag1 = tags[0];
            tag2 = tags[1];
        } else {
            tag1 = tags[0];
        }
    }

    function phase() external view override returns (Phase) {
        if (!_matured()) {
            return Phase.Trading;
        }
        if (!_expired()) {
            return Phase.Maturity;
        }
        return Phase.Expiry;
    }

    function setPaused(bool _paused) external override onlyOwner managerNotPaused {
        require(paused != _paused, "State not changed");
        paused = _paused;
        emit PauseUpdated(_paused);
    }

    function updateDates(uint256 _maturity, uint256 _expiry) external override onlyOwner managerNotPaused noDoubleChance {
        require(_maturity > block.timestamp, "Maturity must be in a future");
        times = Times(_maturity, _expiry);
        emit DatesUpdated(_maturity, _expiry);
    }

    /* ---------- Market Resolution ---------- */

    function canResolve() public view override returns (bool) {
        return !resolved && _matured() && !paused;
    }

    function getGameDetails() external view override returns (bytes32 gameId, string memory gameLabel) {
        return (gameDetails.gameId, gameDetails.gameLabel);
    }

    function getParentMarketPositions() public view override returns (IPosition position1, IPosition position2) {
        if (isDoubleChance) {
            (IPosition home, IPosition away, IPosition draw) = parentMarket.getOptions();
            if (keccak256(abi.encodePacked(gameDetails.gameLabel)) == keccak256(abi.encodePacked("HomeTeamNotToLose"))) {
                (position1, position2) = (home, draw);
            } else if (
                keccak256(abi.encodePacked(gameDetails.gameLabel)) == keccak256(abi.encodePacked("AwayTeamNotToLose"))
            ) {
                (position1, position2) = (away, draw);
            } else {
                (position1, position2) = (home, away);
            }
        }
    }

    function _result() internal view returns (Side) {
        if (!resolved || cancelled) {
            return Side.Cancelled;
        } else if (finalResult == 3 && optionsCount > 2) {
            return Side.Draw;
        } else {
            return finalResult == 1 ? Side.Home : Side.Away;
        }
    }

    function result() external view override returns (Side) {
        return _result();
    }

    /* ---------- Option Balances and Mints ---------- */
    function getGameId() external view override returns (bytes32) {
        return gameDetails.gameId;
    }

    function getStampedOdds()
        public
        view
        override
        returns (
            uint,
            uint,
            uint
        )
    {
        if (cancelled) {
            if (isDoubleChance) {
                (uint position1Odds, uint position2Odds) = _getParentPositionOdds();

                return (position1Odds + position2Odds, 0, 0);
            }
            return (homeOddsOnCancellation, awayOddsOnCancellation, drawOddsOnCancellation);
        } else {
            return (0, 0, 0);
        }
    }

    function _getParentPositionOdds() internal view returns (uint odds1, uint odds2) {
        (uint homeOddsParent, uint awayOddsParent, uint drawOddsParent) = parentMarket.getStampedOdds();
        (IPosition position1, IPosition position2) = getParentMarketPositions();
        (IPosition home, IPosition away, ) = parentMarket.getOptions();

        odds1 = position1 == home ? homeOddsParent : position1 == away ? awayOddsParent : drawOddsParent;
        odds2 = position2 == home ? homeOddsParent : position2 == away ? awayOddsParent : drawOddsParent;
    }

    function _balancesOf(address account)
        internal
        view
        returns (
            uint home,
            uint away,
            uint draw
        )
    {
        if (optionsCount > 2) {
            return (
                options.home.getBalanceOf(account),
                options.away.getBalanceOf(account),
                options.draw.getBalanceOf(account)
            );
        }
        return (options.home.getBalanceOf(account), options.away.getBalanceOf(account), 0);
    }

    function balancesOf(address account)
        external
        view
        override
        returns (
            uint home,
            uint away,
            uint draw
        )
    {
        return _balancesOf(account);
    }

    function totalSupplies()
        external
        view
        override
        returns (
            uint home,
            uint away,
            uint draw
        )
    {
        if (optionsCount > 2) {
            return (options.home.totalSupply(), options.away.totalSupply(), options.draw.totalSupply());
        }
        return (options.home.totalSupply(), options.away.totalSupply(), 0);
    }

    function getOptions()
        external
        view
        override
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        )
    {
        home = options.home;
        away = options.away;
        draw = options.draw;
    }

    function _getMaximumBurnable(address account) internal view returns (uint amount) {
        (uint homeBalance, uint awayBalance, uint drawBalance) = _balancesOf(account);
        uint min = homeBalance;
        if (min > awayBalance) {
            min = awayBalance;
            if (optionsCount > 2 && drawBalance < min) {
                min = drawBalance;
            }
        } else {
            if (optionsCount > 2 && drawBalance < min) {
                min = drawBalance;
            }
        }
        return min;
    }

    /* ---------- Utilities ---------- */

    function _incrementDeposited(uint value) internal returns (uint _deposited) {
        _deposited = deposited.add(value);
        deposited = _deposited;
        _manager().incrementTotalDeposited(value);
    }

    function _decrementDeposited(uint value) internal returns (uint _deposited) {
        _deposited = deposited.sub(value);
        deposited = _deposited;
        _manager().decrementTotalDeposited(value);
    }

    function _requireManagerNotPaused() internal view {
        require(!_manager().paused(), "This action cannot be performed while the contract is paused");
    }

    function requireUnpaused() external view {
        _requireManagerNotPaused();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Minting ---------- */

    function mint(uint value) external override {
        require(!_matured() && !_isPaused(), "Minting inactive");
        require(msg.sender == sportsAMM, "Invalid minter");
        if (value == 0) {
            return;
        }

        _mint(msg.sender, value);

        if (!isDoubleChance) {
            _incrementDeposited(value);
            _manager().transferSusdTo(msg.sender, address(this), value);
        }
    }

    function _mint(address minter, uint amount) internal {
        if (isDoubleChance) {
            options.home.mint(minter, amount);
            emit Mint(Side.Home, minter, amount);
        } else {
            options.home.mint(minter, amount);
            options.away.mint(minter, amount);
            emit Mint(Side.Home, minter, amount);
            emit Mint(Side.Away, minter, amount);
            if (optionsCount > 2) {
                options.draw.mint(minter, amount);
                emit Mint(Side.Draw, minter, amount);
            }
        }
    }

    /* ---------- Custom oracle configuration ---------- */
    function setTherundownConsumer(address _theRundownConsumer) external onlyOwner {
        theRundownConsumer = ITherundownConsumer(_theRundownConsumer);
        emit SetTherundownConsumer(_theRundownConsumer);
    }

    function setsUSD(address _address) external onlyOwner {
        sUSD = IERC20(_address);
        emit SetsUSD(_address);
    }

    /* ---------- Market Resolution ---------- */

    function resolve(uint _outcome) external onlyOwner managerNotPaused {
        require(_outcome <= optionsCount, "Invalid outcome");
        if (_outcome == 0) {
            cancelled = true;
            cancelTimestamp = block.timestamp;
            if (!isDoubleChance) {
                stampOdds();
            }
        } else {
            require(canResolve(), "Can not resolve market");
        }
        finalResult = _outcome;
        resolved = true;
        emit MarketResolved(_result(), deposited, 0, 0);
    }

    function stampOdds() internal {
        uint[] memory odds = new uint[](optionsCount);
        odds = ITherundownConsumer(theRundownConsumer).getNormalizedOddsForMarket(address(this));
        if (odds[0] == 0 || odds[1] == 0) {
            invalidOdds = true;
        }
        homeOddsOnCancellation = odds[0];
        awayOddsOnCancellation = odds[1];
        drawOddsOnCancellation = optionsCount > 2 ? odds[2] : 0;
        emit StoredOddsOnCancellation(homeOddsOnCancellation, awayOddsOnCancellation, drawOddsOnCancellation);
    }

    /* ---------- Claiming and Exercising Options ---------- */

    function exerciseOptions() external override {
        // The market must be resolved if it has not been.
        require(resolved, "Unresolved");
        require(!_isPaused(), "Paused");
        // If the account holds no options, revert.
        (uint homeBalance, uint awayBalance, uint drawBalance) = _balancesOf(msg.sender);
        require(homeBalance != 0 || awayBalance != 0 || drawBalance != 0, "Nothing to exercise");

        if (isDoubleChance && _canExerciseParentOptions()) {
            parentMarket.exerciseOptions();
        }
        // Each option only needs to be exercised if the account holds any of it.
        if (homeBalance != 0) {
            options.home.exercise(msg.sender);
        }
        if (awayBalance != 0) {
            options.away.exercise(msg.sender);
        }
        if (drawBalance != 0) {
            options.draw.exercise(msg.sender);
        }
        uint payout = _getPayout(homeBalance, awayBalance, drawBalance);

        if (cancelled) {
            require(
                block.timestamp > cancelTimestamp.add(_manager().cancelTimeout()) && !invalidOdds,
                "Unexpired timeout/ invalid odds"
            );
            payout = calculatePayoutOnCancellation(homeBalance, awayBalance, drawBalance);
        }
        emit OptionsExercised(msg.sender, payout);
        if (payout != 0) {
            if (!isDoubleChance) {
                _decrementDeposited(payout);
            }
            payout = _manager().transformCollateral(payout);
            sUSD.transfer(msg.sender, payout);
        }
    }

    function _canExerciseParentOptions() internal view returns (bool) {
        if (!parentMarket.resolved() && !parentMarket.canResolve()) {
            return false;
        }

        (uint homeBalance, uint awayBalance, uint drawBalance) = parentMarket.balancesOf(address(this));

        if (homeBalance == 0 && awayBalance == 0 && drawBalance == 0) {
            return false;
        }

        return true;
    }

    function _getPayout(
        uint homeBalance,
        uint awayBalance,
        uint drawBalance
    ) internal view returns (uint payout) {
        if (isDoubleChance) {
            if (_result() == Side.Home) {
                payout = homeBalance;
            }
        } else {
            payout = (_result() == Side.Home) ? homeBalance : awayBalance;

            if (optionsCount > 2 && _result() != Side.Home) {
                payout = _result() == Side.Away ? awayBalance : drawBalance;
            }
        }
    }

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external override onlyOwner {
        require(_homeOdds > 0 && _awayOdds > 0, "Invalid odd");
        homeOddsOnCancellation = _homeOdds;
        awayOddsOnCancellation = _awayOdds;
        drawOddsOnCancellation = optionsCount > 2 ? _drawOdds : 0;
        invalidOdds = false;
        emit StoredOddsOnCancellation(homeOddsOnCancellation, awayOddsOnCancellation, drawOddsOnCancellation);
    }

    function calculatePayoutOnCancellation(
        uint _homeBalance,
        uint _awayBalance,
        uint _drawBalance
    ) public view returns (uint payout) {
        if (!cancelled) {
            return 0;
        } else {
            if (isDoubleChance) {
                (uint position1Odds, uint position2Odds) = _getParentPositionOdds();
                payout = _homeBalance.mul(position1Odds).div(1e18);
                payout = payout.add(_homeBalance.mul(position2Odds).div(1e18));
            } else {
                payout = _homeBalance.mul(homeOddsOnCancellation).div(1e18);
                payout = payout.add(_awayBalance.mul(awayOddsOnCancellation).div(1e18));
                payout = payout.add(_drawBalance.mul(drawOddsOnCancellation).div(1e18));
            }
        }
    }

    /* ---------- Market Expiry ---------- */

    function _selfDestruct(address payable beneficiary) internal {
        uint _deposited = deposited;
        if (_deposited != 0) {
            _decrementDeposited(_deposited);
        }

        // Transfer the balance rather than the deposit value in case there are any synths left over
        // from direct transfers.
        uint balance = sUSD.balanceOf(address(this));
        if (balance != 0) {
            sUSD.transfer(beneficiary, balance);
        }

        // Destroy the option tokens before destroying the market itself.
        options.home.expire(beneficiary);
        options.away.expire(beneficiary);
        selfdestruct(beneficiary);
    }

    function expire(address payable beneficiary) external onlyOwner {
        require(_expired(), "Unexpired options remaining");
        emit Expired(beneficiary);
        _selfDestruct(beneficiary);
    }

    /* ========== MODIFIERS ========== */

    modifier managerNotPaused() {
        _requireManagerNotPaused();
        _;
    }

    modifier noDoubleChance() {
        require(!isDoubleChance, "Not supported for double chance markets");
        _;
    }

    /* ========== EVENTS ========== */

    event Mint(Side side, address indexed account, uint value);
    event MarketResolved(Side result, uint deposited, uint poolFees, uint creatorFees);

    event OptionsExercised(address indexed account, uint value);
    event OptionsBurned(address indexed account, uint value);
    event SetsUSD(address _address);
    event SetTherundownConsumer(address _address);
    event Expired(address beneficiary);
    event StoredOddsOnCancellation(uint homeOdds, uint awayOdds, uint drawOdds);
    event PauseUpdated(bool _paused);
    event DatesUpdated(uint256 _maturity, uint256 _expiry);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

// Libraries
import "../../utils/libraries/AddressSetLib.sol";
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./SportPositionalMarketFactory.sol";
import "./SportPositionalMarket.sol";
import "./SportPosition.sol";
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ITherundownConsumer.sol";

import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IGamesOddsObtainer.sol";

contract SportPositionalMarketManager is Initializable, ProxyOwned, ProxyPausable, ISportPositionalMarketManager {
    /* ========== LIBRARIES ========== */
    using SafeMath for uint;
    using AddressSetLib for AddressSetLib.AddressSet;

    /* ========== STATE VARIABLES ========== */

    uint public override expiryDuration;

    bool public override marketCreationEnabled;
    bool public customMarketCreationEnabled;

    uint public override totalDeposited;

    AddressSetLib.AddressSet internal _activeMarkets;
    AddressSetLib.AddressSet internal _maturedMarkets;

    SportPositionalMarketManager internal _migratingManager;

    IERC20 public sUSD;

    address public theRundownConsumer;
    address public sportPositionalMarketFactory;
    bool public needsTransformingCollateral;
    mapping(address => bool) public whitelistedAddresses;
    address public apexConsumer; // deprecated
    uint public cancelTimeout;
    mapping(address => bool) public whitelistedCancelAddresses;
    address public oddsObtainer;

    mapping(address => bool) public isDoubleChance;
    bool public override isDoubleChanceSupported;
    mapping(address => address[]) public doubleChanceMarketsByParent;
    mapping(uint => bool) public doesSportSupportDoubleChance;

    /* ========== CONSTRUCTOR ========== */

    function initialize(address _owner, IERC20 _sUSD) external initializer {
        setOwner(_owner);
        sUSD = _sUSD;

        // Temporarily change the owner so that the setters don't revert.
        owner = msg.sender;

        marketCreationEnabled = true;
        customMarketCreationEnabled = false;
    }

    /* ========== SETTERS ========== */
    function setSportPositionalMarketFactory(address _sportPositionalMarketFactory) external onlyOwner {
        sportPositionalMarketFactory = _sportPositionalMarketFactory;
        emit SetSportPositionalMarketFactory(_sportPositionalMarketFactory);
    }

    function setTherundownConsumer(address _theRundownConsumer) external onlyOwner {
        theRundownConsumer = _theRundownConsumer;
        emit SetTherundownConsumer(_theRundownConsumer);
    }

    function setOddsObtainer(address _oddsObtainer) external onlyOwner {
        oddsObtainer = _oddsObtainer;
        emit SetObtainerAddress(_oddsObtainer);
    }

    function getOddsObtainer() external view override returns (address obtainer) {
        obtainer = oddsObtainer;
    }

    /// @notice setNeedsTransformingCollateral sets needsTransformingCollateral value
    /// @param _needsTransformingCollateral boolen value to be set
    function setNeedsTransformingCollateral(bool _needsTransformingCollateral) external onlyOwner {
        needsTransformingCollateral = _needsTransformingCollateral;
    }

    /// @notice setWhitelistedAddresses enables whitelist addresses of given array
    /// @param _whitelistedAddresses array of whitelisted addresses
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function setWhitelistedAddresses(
        address[] calldata _whitelistedAddresses,
        bool _flag,
        uint8 _group
    ) external onlyOwner {
        require(_whitelistedAddresses.length > 0, "Whitelisted addresses cannot be empty");
        for (uint256 index = 0; index < _whitelistedAddresses.length; index++) {
            // only if current flag is different, if same skip it
            if (_group == 1) {
                if (whitelistedAddresses[_whitelistedAddresses[index]] != _flag) {
                    whitelistedAddresses[_whitelistedAddresses[index]] = _flag;
                    emit AddedIntoWhitelist(_whitelistedAddresses[index], _flag);
                }
            }
            if (_group == 2) {
                if (whitelistedCancelAddresses[_whitelistedAddresses[index]] != _flag) {
                    whitelistedCancelAddresses[_whitelistedAddresses[index]] = _flag;
                    emit AddedIntoWhitelist(_whitelistedAddresses[index], _flag);
                }
            }
        }
    }

    /* ========== VIEWS ========== */

    /* ---------- Market Information ---------- */

    function isKnownMarket(address candidate) public view override returns (bool) {
        return _activeMarkets.contains(candidate) || _maturedMarkets.contains(candidate);
    }

    function isActiveMarket(address candidate) public view override returns (bool) {
        return _activeMarkets.contains(candidate) && !ISportPositionalMarket(candidate).paused();
    }

    function isDoubleChanceMarket(address candidate) public view override returns (bool) {
        return isDoubleChance[candidate];
    }

    function numActiveMarkets() external view override returns (uint) {
        return _activeMarkets.elements.length;
    }

    function activeMarkets(uint index, uint pageSize) external view override returns (address[] memory) {
        return _activeMarkets.getPage(index, pageSize);
    }

    function numMaturedMarkets() external view override returns (uint) {
        return _maturedMarkets.elements.length;
    }

    function getActiveMarketAddress(uint _index) external view override returns (address) {
        if (_index < _activeMarkets.elements.length) {
            return _activeMarkets.elements[_index];
        } else {
            return address(0);
        }
    }

    function getDoubleChanceMarketsByParentMarket(address market) external view returns (address[] memory) {
        if (doubleChanceMarketsByParent[market].length > 0) {
            address[] memory markets = new address[](3);
            for (uint i = 0; i < doubleChanceMarketsByParent[market].length; i++) {
                markets[i] = doubleChanceMarketsByParent[market][i];
            }
            return markets;
        }
    }

    function maturedMarkets(uint index, uint pageSize) external view override returns (address[] memory) {
        return _maturedMarkets.getPage(index, pageSize);
    }

    function setMarketPaused(address _market, bool _paused) external override {
        require(
            msg.sender == owner ||
                msg.sender == theRundownConsumer ||
                msg.sender == oddsObtainer ||
                whitelistedAddresses[msg.sender],
            "Invalid caller"
        );
        require(ISportPositionalMarket(_market).paused() != _paused, "No state change");
        ISportPositionalMarket(_market).setPaused(_paused);
    }

    function updateDatesForMarket(address _market, uint256 _newStartTime) external override {
        require(msg.sender == owner || msg.sender == theRundownConsumer || msg.sender == oddsObtainer, "Invalid caller");

        uint expiry = _newStartTime.add(expiryDuration);

        // update main market
        _updateDatesForMarket(_market, _newStartTime, expiry);

        // number of child
        uint numberOfChildMarkets = IGamesOddsObtainer(oddsObtainer).numberOfChildMarkets(_market);

        for (uint i = 0; i < numberOfChildMarkets; i++) {
            address child = IGamesOddsObtainer(oddsObtainer).mainMarketChildMarketIndex(_market, i);
            _updateDatesForMarket(child, _newStartTime, expiry);
        }
    }

    function isMarketPaused(address _market) external view override returns (bool) {
        return ISportPositionalMarket(_market).paused();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Setters ---------- */

    function setExpiryDuration(uint _expiryDuration) public onlyOwner {
        expiryDuration = _expiryDuration;
        emit ExpiryDurationUpdated(_expiryDuration);
    }

    function setsUSD(address _address) external onlyOwner {
        sUSD = IERC20(_address);
        emit SetsUSD(_address);
    }

    /* ---------- Deposit Management ---------- */

    function incrementTotalDeposited(uint delta) external onlyActiveMarkets notPaused {
        totalDeposited = totalDeposited.add(delta);
    }

    function decrementTotalDeposited(uint delta) external onlyKnownMarkets notPaused {
        // NOTE: As individual market debt is not tracked here, the underlying markets
        //       need to be careful never to subtract more debt than they added.
        //       This can't be enforced without additional state/communication overhead.
        totalDeposited = totalDeposited.sub(delta);
    }

    /* ---------- Market Lifecycle ---------- */

    function createMarket(
        bytes32 gameId,
        string memory gameLabel,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        uint positionCount,
        uint[] memory tags,
        bool isChild,
        address parentMarket
    )
        external
        override
        notPaused
        returns (
            ISportPositionalMarket // no support for returning PositionalMarket polymorphically given the interface
        )
    {
        require(marketCreationEnabled, "Market creation is disabled");
        require(msg.sender == theRundownConsumer || msg.sender == oddsObtainer, "Invalid creator");

        uint expiry = maturity.add(expiryDuration);

        require(block.timestamp < maturity, "Maturity has to be in the future");
        // We also require maturity < expiry. But there is no need to check this.
        // The market itself validates the capital and skew requirements.

        ISportPositionalMarket market = _createMarket(
            SportPositionalMarketFactory.SportPositionCreationMarketParameters(
                msg.sender,
                sUSD,
                gameId,
                gameLabel,
                [maturity, expiry],
                initialMint,
                positionCount,
                msg.sender,
                tags,
                isChild,
                parentMarket,
                false
            )
        );

        // The debt can't be incremented in the new market's constructor because until construction is complete,
        // the manager doesn't know its address in order to grant it permission.
        totalDeposited = totalDeposited.add(initialMint);
        sUSD.transferFrom(msg.sender, address(market), _transformCollateral(initialMint));

        if (positionCount > 2 && isDoubleChanceSupported) {
            _createDoubleChanceMarkets(msg.sender, gameId, maturity, expiry, initialMint, address(market), tags[0]);
        }

        return market;
    }

    function createDoubleChanceMarketsForParent(address market) external notPaused onlyOwner {
        require(marketCreationEnabled, "Market creation is disabled");
        require(isDoubleChanceSupported, "Double chance not supported");
        ISportPositionalMarket marketContract = ISportPositionalMarket(market);

        require(marketContract.optionsCount() > 2, "Not supported for 2 options market");

        (uint maturity, uint expiry) = marketContract.times();
        _createDoubleChanceMarkets(
            marketContract.creator(),
            marketContract.getGameId(),
            maturity,
            expiry,
            marketContract.initialMint(),
            market,
            marketContract.tags(0)
        );
    }

    function _createMarket(SportPositionalMarketFactory.SportPositionCreationMarketParameters memory parameters)
        internal
        returns (ISportPositionalMarket)
    {
        SportPositionalMarket market = SportPositionalMarketFactory(sportPositionalMarketFactory).createMarket(parameters);

        _activeMarkets.add(address(market));

        (IPosition up, IPosition down, IPosition draw) = market.getOptions();

        emit MarketCreated(
            address(market),
            parameters.creator,
            parameters.gameId,
            parameters.times[0],
            parameters.times[1],
            address(up),
            address(down),
            address(draw)
        );
        emit MarketLabel(address(market), parameters.gameLabel);
        return market;
    }

    function _createDoubleChanceMarkets(
        address creator,
        bytes32 gameId,
        uint maturity,
        uint expiry,
        uint initialMint,
        address market,
        uint tag
    ) internal onlySupportedGameId(gameId) {
        string[3] memory labels = ["HomeTeamNotToLose", "AwayTeamNotToLose", "NoDraw"];
        uint[] memory tagsDoubleChance = new uint[](2);
        tagsDoubleChance[0] = tag;
        tagsDoubleChance[1] = 10003;
        for (uint i = 0; i < 3; i++) {
            ISportPositionalMarket doubleChanceMarket = _createMarket(
                SportPositionalMarketFactory.SportPositionCreationMarketParameters(
                    creator,
                    sUSD,
                    gameId,
                    labels[i],
                    [maturity, expiry],
                    initialMint,
                    2,
                    creator,
                    tagsDoubleChance,
                    false,
                    address(market),
                    true
                )
            );
            _activeMarkets.add(address(doubleChanceMarket));

            doubleChanceMarketsByParent[address(market)].push(address(doubleChanceMarket));
            isDoubleChance[address(doubleChanceMarket)] = true;

            IGamesOddsObtainer(oddsObtainer).setChildMarketGameId(gameId, address(doubleChanceMarket));

            emit DoubleChanceMarketCreated(address(market), address(doubleChanceMarket), tagsDoubleChance[1], labels[i]);
        }
    }

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external override {
        //only to be called by markets themselves
        require(isKnownMarket(address(msg.sender)), "Market unknown.");
        amount = _transformCollateral(amount);
        amount = needsTransformingCollateral ? amount + 1 : amount;
        bool success = sUSD.transferFrom(sender, receiver, amount);
        if (!success) {
            revert("TransferFrom function failed");
        }
    }

    function resolveMarket(address market, uint _outcome) external override {
        require(
            msg.sender == theRundownConsumer ||
                msg.sender == owner ||
                msg.sender == oddsObtainer ||
                whitelistedCancelAddresses[msg.sender],
            "Invalid resolver"
        );
        require(_activeMarkets.contains(market), "Not an active market");
        require(!isDoubleChance[market], "Not supported for double chance markets");
        // unpause if paused
        if (ISportPositionalMarket(market).paused()) {
            ISportPositionalMarket(market).setPaused(false);
        }
        SportPositionalMarket(market).resolve(_outcome);
        _activeMarkets.remove(market);
        _maturedMarkets.add(market);

        if (doubleChanceMarketsByParent[market].length > 0) {
            if (_outcome == 1) {
                // HomeTeamNotLose, NoDraw
                SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(1);
                SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(2);
                SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(1);
            } else if (_outcome == 2) {
                // AwayTeamNotLose, NoDraw
                SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(2);
                SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(1);
                SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(1);
            } else if (_outcome == 3) {
                // HomeTeamNotLose, AwayTeamNotLose
                SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(1);
                SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(1);
                SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(2);
            } else {
                // cancelled
                SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(0);
                SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(0);
                SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(0);
            }
            for (uint i = 0; i < doubleChanceMarketsByParent[market].length; i++) {
                _activeMarkets.remove(doubleChanceMarketsByParent[market][i]);
                _maturedMarkets.add(doubleChanceMarketsByParent[market][i]);
            }
        }
    }

    function resolveMarketWithResult(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        address _consumer,
        bool _useBackupOdds
    ) external {
        require(msg.sender == owner || whitelistedCancelAddresses[msg.sender], "Invalid resolver");
        require(!isDoubleChance[_market], "Not supported for double chance markets");

        if (_outcome != 0) {
            require(!_useBackupOdds, "Only use backup odds on cancelation, if needed!");
        }

        if (_consumer == theRundownConsumer) {
            ITherundownConsumer(theRundownConsumer).resolveMarketManually(
                _market,
                _outcome,
                _homeScore,
                _awayScore,
                _useBackupOdds
            );
        }
    }

    function overrideResolveWithCancel(address market, uint _outcome) external {
        require(msg.sender == owner || whitelistedCancelAddresses[msg.sender], "Invalid resolver");
        require(_outcome == 0, "Can only set 0 outcome");
        require(SportPositionalMarket(market).resolved(), "Market not resolved");
        require(!_activeMarkets.contains(market), "Active market");
        require(!isDoubleChance[market], "Not supported for double chance markets");
        // unpause if paused
        if (ISportPositionalMarket(market).paused()) {
            ISportPositionalMarket(market).setPaused(false);
        }
        SportPositionalMarket(market).resolve(_outcome);

        if (doubleChanceMarketsByParent[market].length > 0) {
            SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(0);
            SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(0);
            SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(0);
        }
    }

    function expireMarkets(address[] calldata markets) external override notPaused onlyOwner {
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];

            require(isKnownMarket(address(market)), "Market unknown.");

            // The market itself handles decrementing the total deposits.
            SportPositionalMarket(market).expire(payable(msg.sender));

            // Note that we required that the market is known, which guarantees
            // its index is defined and that the list of markets is not empty.
            _maturedMarkets.remove(market);

            emit MarketExpired(market);
        }
    }

    function restoreInvalidOddsForMarket(
        address _market,
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external onlyOwner {
        require(isKnownMarket(address(_market)), "Market unknown.");
        require(SportPositionalMarket(_market).cancelled(), "Market not cancelled.");
        SportPositionalMarket(_market).restoreInvalidOdds(_homeOdds, _awayOdds, _drawOdds);
        emit OddsForMarketRestored(_market, _homeOdds, _awayOdds, _drawOdds);
    }

    function setMarketCreationEnabled(bool enabled) external onlyOwner {
        if (enabled != marketCreationEnabled) {
            marketCreationEnabled = enabled;
            emit MarketCreationEnabledUpdated(enabled);
        }
    }

    function setCancelTimeout(uint _cancelTimeout) external onlyOwner {
        cancelTimeout = _cancelTimeout;
    }

    function setIsDoubleChanceSupported(bool _isDoubleChanceSupported) external onlyOwner {
        isDoubleChanceSupported = _isDoubleChanceSupported;
        emit DoubleChanceSupportChanged(_isDoubleChanceSupported);
    }

    function setSupportedSportForDoubleChance(uint[] memory _sportIds, bool _isSupported) external onlyOwner {
        for (uint256 index = 0; index < _sportIds.length; index++) {
            // only if current flag is different, if same skip it
            if (doesSportSupportDoubleChance[_sportIds[index]] != _isSupported) {
                doesSportSupportDoubleChance[_sportIds[index]] = _isSupported;
                emit SupportedSportForDoubleChanceAdded(_sportIds[index], _isSupported);
            }
        }
    }

    // support USDC with 6 decimals
    function transformCollateral(uint value) external view override returns (uint) {
        return _transformCollateral(value);
    }

    function _transformCollateral(uint value) internal view returns (uint) {
        if (needsTransformingCollateral) {
            return value / 1e12;
        } else {
            return value;
        }
    }

    function _updateDatesForMarket(
        address _market,
        uint256 _newStartTime,
        uint256 _expiry
    ) internal {
        ISportPositionalMarket(_market).updateDates(_newStartTime, _expiry);

        emit DatesUpdatedForMarket(_market, _newStartTime, _expiry);
    }

    function reverseTransformCollateral(uint value) external view override returns (uint) {
        if (needsTransformingCollateral) {
            return value * 1e12;
        } else {
            return value;
        }
    }

    function isWhitelistedAddress(address _address) external view override returns (bool) {
        return whitelistedAddresses[_address];
    }

    /* ========== MODIFIERS ========== */

    modifier onlyActiveMarkets() {
        require(_activeMarkets.contains(msg.sender), "Permitted only for active markets.");
        _;
    }

    modifier onlyKnownMarkets() {
        require(isKnownMarket(msg.sender), "Permitted only for known markets.");
        _;
    }

    modifier onlySupportedGameId(bytes32 gameId) {
        uint sportId = ITherundownConsumer(theRundownConsumer).sportsIdPerGame(gameId);
        if (doesSportSupportDoubleChance[sportId] && isDoubleChanceSupported) {
            _;
        }
    }

    /* ========== EVENTS ========== */

    event MarketCreated(
        address market,
        address indexed creator,
        bytes32 indexed gameId,
        uint maturityDate,
        uint expiryDate,
        address up,
        address down,
        address draw
    );
    event MarketLabel(address market, string gameLabel);
    event MarketExpired(address market);
    event MarketCreationEnabledUpdated(bool enabled);
    event MarketsMigrated(SportPositionalMarketManager receivingManager, SportPositionalMarket[] markets);
    event MarketsReceived(SportPositionalMarketManager migratingManager, SportPositionalMarket[] markets);
    event SetMigratingManager(address migratingManager);
    event ExpiryDurationUpdated(uint duration);
    event MaxTimeToMaturityUpdated(uint duration);
    event CreatorCapitalRequirementUpdated(uint value);
    event SetSportPositionalMarketFactory(address _sportPositionalMarketFactory);
    event SetsUSD(address _address);
    event SetTherundownConsumer(address theRundownConsumer);
    event SetObtainerAddress(address _obratiner);
    event OddsForMarketRestored(address _market, uint _homeOdds, uint _awayOdds, uint _drawOdds);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event DatesUpdatedForMarket(address _market, uint256 _newStartTime, uint256 _expiry);
    event DoubleChanceMarketCreated(address _parentMarket, address _doubleChanceMarket, uint tag, string label);
    event DoubleChanceSupportChanged(bool _isDoubleChanceSupported);
    event SupportedSportForDoubleChanceAdded(uint _sportId, bool _isSupported);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-4.4.1/utils/Strings.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

// interface
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/ITherundownConsumerVerifier.sol";
import "../../interfaces/ITherundownConsumer.sol";
import "../../interfaces/IGamesOddsObtainer.sol";

/// @title Contract, which works on odds obtain
/// @author gruja
contract GamesOddsObtainer is Initializable, ProxyOwned, ProxyPausable {
    /* ========== CONSTANTS =========== */
    uint public constant MIN_TAG_NUMBER = 9000;
    uint public constant TAG_NUMBER_SPREAD = 10001;
    uint public constant TAG_NUMBER_TOTAL = 10002;
    uint public constant CANCELLED = 0;
    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;

    /* ========== CONSUMER STATE VARIABLES ========== */

    ITherundownConsumer public consumer;
    ITherundownConsumerVerifier public verifier;
    ISportPositionalMarketManager public sportsManager;

    // game properties
    mapping(bytes32 => IGamesOddsObtainer.GameOdds) public gameOdds;
    mapping(bytes32 => IGamesOddsObtainer.GameOdds) public backupOdds;
    mapping(address => bool) public invalidOdds;
    mapping(bytes32 => uint) public oddsLastPulledForGame;
    mapping(address => bytes32) public gameIdPerChildMarket;
    mapping(uint => bool) public doesSportSupportSpreadAndTotal;

    // market props
    mapping(address => mapping(uint => address)) public mainMarketChildMarketIndex;
    mapping(address => uint) public numberOfChildMarkets;
    mapping(address => mapping(int16 => address)) public mainMarketSpreadChildMarket;
    mapping(address => mapping(uint24 => address)) public mainMarketTotalChildMarket;
    mapping(address => address) public childMarketMainMarket;
    mapping(address => int16) public childMarketSread;
    mapping(address => uint24) public childMarketTotal;
    mapping(address => address) public currentActiveTotalChildMarket;
    mapping(address => address) public currentActiveSpreadChildMarket;
    mapping(address => bool) public isSpreadChildMarket;
    mapping(address => bool) public childMarketCreated;
    mapping(address => bool) public normalizedOddsForMarketFulfilled;
    mapping(address => uint[]) public normalizedOddsForMarket;
    address public oddsReceiver;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        address _consumer,
        address _verifier,
        address _sportsManager,
        uint[] memory _supportedSportIds
    ) external initializer {
        setOwner(_owner);
        consumer = ITherundownConsumer(_consumer);
        verifier = ITherundownConsumerVerifier(_verifier);
        sportsManager = ISportPositionalMarketManager(_sportsManager);

        for (uint i; i < _supportedSportIds.length; i++) {
            doesSportSupportSpreadAndTotal[_supportedSportIds[i]] = true;
        }
    }

    /* ========== OBTAINER MAIN FUNCTIONS ========== */

    /// @notice main function for odds obtaining
    /// @param requestId chainlnink request ID
    /// @param _game game odds struct see @ IGamesOddsObtainer.GameOdds
    function obtainOdds(
        bytes32 requestId,
        IGamesOddsObtainer.GameOdds memory _game,
        uint _sportId
    ) external canUpdateOdds {
        if (_areOddsValid(_game)) {
            uint[] memory currentNormalizedOdd = getNormalizedOdds(_game.gameId);
            IGamesOddsObtainer.GameOdds memory currentOddsBeforeSave = gameOdds[_game.gameId];
            gameOdds[_game.gameId] = _game;
            oddsLastPulledForGame[_game.gameId] = block.timestamp;

            address _main = consumer.marketPerGameId(_game.gameId);
            _setNormalizedOdds(_main, _game.gameId, true);
            if (doesSportSupportSpreadAndTotal[_sportId]) {
                _obtainTotalAndSpreadOdds(_game, _main);
            }

            // if was paused and paused by invalid odds unpause
            if (sportsManager.isMarketPaused(_main)) {
                if (invalidOdds[_main] || consumer.isPausedByCanceledStatus(_main)) {
                    invalidOdds[_main] = false;
                    consumer.setPausedByCanceledStatus(_main, false);
                    _pauseOrUnpauseMarkets(_game, _main, false, true);
                }
            } else if (
                //if market is not paused but odd are not in threshold, pause parket
                !sportsManager.isMarketPaused(_main) &&
                !verifier.areOddsArrayInThreshold(
                    _sportId,
                    currentNormalizedOdd,
                    normalizedOddsForMarket[_main],
                    consumer.isSportTwoPositionsSport(_sportId)
                )
            ) {
                _pauseOrUnpauseMarkets(_game, _main, true, true);
                backupOdds[_game.gameId] = currentOddsBeforeSave;
                emit OddsCircuitBreaker(_main, _game.gameId);
            }
            emit GameOddsAdded(requestId, _game.gameId, _game, normalizedOddsForMarket[_main]);
        } else {
            address _main = consumer.marketPerGameId(_game.gameId);
            if (!sportsManager.isMarketPaused(_main)) {
                invalidOdds[_main] = true;
                _pauseOrUnpauseMarkets(_game, _main, true, true);
            }

            emit InvalidOddsForMarket(requestId, _main, _game.gameId, _game);
        }
    }

    /// @notice set first odds on creation
    /// @param _gameId game id
    /// @param _homeOdds home odds for a game
    /// @param _awayOdds away odds for a game
    /// @param _drawOdds draw odds for a game
    function setFirstOdds(
        bytes32 _gameId,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external onlyConsumer {
        gameOdds[_gameId] = IGamesOddsObtainer.GameOdds(_gameId, _homeOdds, _awayOdds, _drawOdds, 0, 0, 0, 0, 0, 0, 0, 0);
        oddsLastPulledForGame[_gameId] = block.timestamp;
    }

    /// @notice set first odds on creation market
    /// @param _gameId game id
    /// @param _market market
    function setFirstNormalizedOdds(bytes32 _gameId, address _market) external onlyConsumer {
        _setNormalizedOdds(_market, _gameId, true);
    }

    /// @notice set backup odds to be main odds
    /// @param _gameId game id which is using backup odds
    function setBackupOddsAsMainOddsForGame(bytes32 _gameId) external onlyConsumer {
        gameOdds[_gameId] = backupOdds[_gameId];
        address _main = consumer.marketPerGameId(_gameId);
        _setNormalizedOdds(_main, _gameId, true);
        emit GameOddsAdded(
            _gameId, // // no req. from CL (manual cancel) so just put gameID
            _gameId,
            gameOdds[_gameId],
            normalizedOddsForMarket[_main]
        );
    }

    /// @notice pause/unpause all child markets
    /// @param _main parent market for which we are pause/unpause child markets
    /// @param _flag pause -> true, unpause -> false
    function pauseUnpauseChildMarkets(address _main, bool _flag) external onlyConsumer {
        // number of childs more then 0
        for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
            consumer.pauseOrUnpauseMarket(mainMarketChildMarketIndex[_main][i], _flag);
        }
    }

    /// @notice pause/unpause current active child markets
    /// @param _gameId game id for spread and totals checking
    /// @param _main parent market for which we are pause/unpause child markets
    /// @param _flag pause -> true, unpause -> false
    function pauseUnpauseCurrentActiveChildMarket(
        bytes32 _gameId,
        address _main,
        bool _flag
    ) external onlyConsumer {
        _pauseOrUnpauseMarkets(gameOdds[_gameId], _main, _flag, true);
    }

    function setChildMarketGameId(bytes32 gameId, address market) external onlyManager {
        consumer.setGameIdPerChildMarket(gameId, market);
    }

    /// @notice resolve all child markets
    /// @param _main parent market for which we are resolving
    /// @param _outcome poitions thet is winning (homw, away, cancel)
    /// @param _homeScore points that home team score
    /// @param _awayScore points that away team score
    function resolveChildMarkets(
        address _main,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) external onlyConsumer {
        for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
            address child = mainMarketChildMarketIndex[_main][i];
            if (_outcome == CANCELLED) {
                sportsManager.resolveMarket(child, _outcome);
            } else if (isSpreadChildMarket[child]) {
                _resolveMarketSpread(child, uint16(_homeScore), uint16(_awayScore));
            } else {
                _resolveMarketTotal(child, uint24(_homeScore), uint24(_awayScore));
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice view function which returns normalized odds up to 100 (Example: 50-40-10)
    /// @param _gameId game id for which game is looking
    /// @return uint[] odds array normalized
    function getNormalizedOdds(bytes32 _gameId) public view returns (uint[] memory) {
        address market = consumer.marketPerGameId(_gameId);
        return
            normalizedOddsForMarketFulfilled[market]
                ? normalizedOddsForMarket[market]
                : getNormalizedOddsFromGameOddsStruct(_gameId);
    }

    /// @notice view function which returns normalized odds (spread or total) up to 100 (Example: 55-45)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedChildOdds(address _market) public view returns (uint[] memory) {
        return
            normalizedOddsForMarketFulfilled[_market]
                ? normalizedOddsForMarket[_market]
                : getNormalizedChildOddsFromGameOddsStruct(_market);
    }

    /// @notice view function which returns normalized odds up to 100 (Example: 50-50)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedOddsForMarket(address _market) public view returns (uint[] memory) {
        return getNormalizedChildOdds(_market);
    }

    /// @param _gameId game id for which game is looking
    /// @return uint[] odds array normalized
    function getNormalizedOddsFromGameOddsStruct(bytes32 _gameId) public view returns (uint[] memory) {
        int[] memory odds = new int[](3);
        odds[0] = gameOdds[_gameId].homeOdds;
        odds[1] = gameOdds[_gameId].awayOdds;
        odds[2] = gameOdds[_gameId].drawOdds;
        return verifier.calculateAndNormalizeOdds(odds);
    }

    /// @notice view function which returns normalized odds (spread or total) up to 100 (Example: 55-45)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedChildOddsFromGameOddsStruct(address _market) public view returns (uint[] memory) {
        bytes32 gameId = gameIdPerChildMarket[_market];
        int[] memory odds = new int[](2);
        odds[0] = isSpreadChildMarket[_market] ? gameOdds[gameId].spreadHomeOdds : gameOdds[gameId].totalOverOdds;
        odds[1] = isSpreadChildMarket[_market] ? gameOdds[gameId].spreadAwayOdds : gameOdds[gameId].totalUnderOdds;
        return verifier.calculateAndNormalizeOdds(odds);
    }

    /// @notice function which retrievers all markert addresses for given parent market
    /// @param _parent parent market
    /// @return address[] child addresses
    function getAllChildMarketsFromParent(address _parent) external view returns (address[] memory) {
        address[] memory allMarkets = new address[](numberOfChildMarkets[_parent]);
        for (uint i = 0; i < numberOfChildMarkets[_parent]; i++) {
            allMarkets[i] = mainMarketChildMarketIndex[_parent][i];
        }
        return allMarkets;
    }

    /// @notice function which retrievers all markert addresses for given parent market
    /// @param _parent parent market
    /// @return totalsMarket totals child address
    /// @return spreadsMarket spread child address
    function getActiveChildMarketsFromParent(address _parent)
        external
        view
        returns (address totalsMarket, address spreadsMarket)
    {
        totalsMarket = currentActiveTotalChildMarket[_parent];
        spreadsMarket = currentActiveSpreadChildMarket[_parent];
    }

    /// @notice are odds valid or not
    /// @param _gameId game id for which game is looking
    /// @param _useBackup see if looking at backupOdds
    /// @return bool true/false (valid or not)
    function areOddsValid(bytes32 _gameId, bool _useBackup) external view returns (bool) {
        return _useBackup ? _areOddsValid(backupOdds[_gameId]) : _areOddsValid(gameOdds[_gameId]);
    }

    /// @notice view function which returns odds
    /// @param _gameId game id
    /// @return spreadHome points difference between home and away
    /// @return spreadAway  points difference between home and away
    /// @return totalOver  points total in a game over limit
    /// @return totalUnder  points total in game under limit
    function getLinesForGame(bytes32 _gameId)
        public
        view
        returns (
            int16,
            int16,
            uint24,
            uint24
        )
    {
        return (
            gameOdds[_gameId].spreadHome,
            gameOdds[_gameId].spreadAway,
            gameOdds[_gameId].totalOver,
            gameOdds[_gameId].totalUnder
        );
    }

    /// @notice view function which returns odds
    /// @param _gameId game id
    /// @return homeOdds moneyline odd in a two decimal places
    /// @return awayOdds moneyline odd in a two decimal places
    /// @return drawOdds moneyline odd in a two decimal places
    /// @return spreadHomeOdds moneyline odd in a two decimal places
    /// @return spreadAwayOdds moneyline odd in a two decimal places
    /// @return totalOverOdds moneyline odd in a two decimal places
    /// @return totalUnderOdds moneyline odd in a two decimal places
    function getOddsForGame(bytes32 _gameId)
        public
        view
        returns (
            int24,
            int24,
            int24,
            int24,
            int24,
            int24,
            int24
        )
    {
        return (
            gameOdds[_gameId].homeOdds,
            gameOdds[_gameId].awayOdds,
            gameOdds[_gameId].drawOdds,
            gameOdds[_gameId].spreadHomeOdds,
            gameOdds[_gameId].spreadAwayOdds,
            gameOdds[_gameId].totalOverOdds,
            gameOdds[_gameId].totalUnderOdds
        );
    }

    /* ========== INTERNALS ========== */

    function _areOddsValid(IGamesOddsObtainer.GameOdds memory _game) internal view returns (bool) {
        return
            verifier.areOddsValid(
                consumer.isSportTwoPositionsSport(consumer.sportsIdPerGame(_game.gameId)),
                _game.homeOdds,
                _game.awayOdds,
                _game.drawOdds
            );
    }

    function _obtainTotalAndSpreadOdds(IGamesOddsObtainer.GameOdds memory _game, address _main) internal {
        if (_areTotalOddsValid(_game)) {
            _obtainSpreadTotal(_game, _main, false);
            emit GamedOddsAddedChild(
                _game.gameId,
                currentActiveTotalChildMarket[_main],
                _game,
                getNormalizedChildOdds(currentActiveTotalChildMarket[_main]),
                TAG_NUMBER_TOTAL
            );
        } else {
            _pauseTotalSpreadMarkets(_game, false);
        }
        if (_areSpreadOddsValid(_game)) {
            _obtainSpreadTotal(_game, _main, true);
            emit GamedOddsAddedChild(
                _game.gameId,
                currentActiveSpreadChildMarket[_main],
                _game,
                getNormalizedChildOdds(currentActiveSpreadChildMarket[_main]),
                TAG_NUMBER_SPREAD
            );
        } else {
            _pauseTotalSpreadMarkets(_game, true);
        }
    }

    function _areTotalOddsValid(IGamesOddsObtainer.GameOdds memory _game) internal view returns (bool) {
        return verifier.areTotalOddsValid(_game.totalOver, _game.totalOverOdds, _game.totalUnder, _game.totalUnderOdds);
    }

    function _areSpreadOddsValid(IGamesOddsObtainer.GameOdds memory _game) internal view returns (bool) {
        return verifier.areSpreadOddsValid(_game.spreadHome, _game.spreadHomeOdds, _game.spreadAway, _game.spreadAwayOdds);
    }

    function _obtainSpreadTotal(
        IGamesOddsObtainer.GameOdds memory _game,
        address _main,
        bool _isSpread
    ) internal {
        bool isNewMarket = numberOfChildMarkets[_main] == 0;

        address currentActiveChildMarket = _isSpread
            ? currentActiveSpreadChildMarket[_main]
            : currentActiveTotalChildMarket[_main];

        address currentMarket = _isSpread
            ? mainMarketSpreadChildMarket[_main][_game.spreadHome]
            : mainMarketTotalChildMarket[_main][_game.totalOver];

        if (isNewMarket || currentMarket == address(0)) {
            address newMarket = _createMarketSpreadTotalMarket(
                _game.gameId,
                _main,
                _isSpread,
                _game.spreadHome,
                _game.totalOver
            );

            _setCurrentChildMarkets(_main, newMarket, _isSpread);

            if (currentActiveChildMarket != address(0)) {
                consumer.pauseOrUnpauseMarket(currentActiveChildMarket, true);
            }
            _setNormalizedOdds(newMarket, _game.gameId, false);
        } else if (currentMarket != currentActiveChildMarket) {
            consumer.pauseOrUnpauseMarket(currentMarket, false);
            consumer.pauseOrUnpauseMarket(currentActiveChildMarket, true);
            _setCurrentChildMarkets(_main, currentMarket, _isSpread);
            _setNormalizedOdds(currentMarket, _game.gameId, false);
        } else {
            consumer.pauseOrUnpauseMarket(currentActiveChildMarket, false);
            _setNormalizedOdds(currentActiveChildMarket, _game.gameId, false);
        }
    }

    function _setNormalizedOdds(
        address _market,
        bytes32 _gameId,
        bool _isParent
    ) internal {
        normalizedOddsForMarket[_market] = _isParent
            ? getNormalizedOddsFromGameOddsStruct(_gameId)
            : getNormalizedChildOddsFromGameOddsStruct(_market);
        normalizedOddsForMarketFulfilled[_market] = true;
    }

    function _createMarketSpreadTotalMarket(
        bytes32 _gameId,
        address _mainMarket,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver
    ) internal returns (address _childMarket) {
        // create
        uint[] memory tags = _calculateTags(consumer.sportsIdPerGame(_gameId), _isSpread);
        sportsManager.createMarket(
            _gameId,
            _append(_gameId, _isSpread, _spreadHome, _totalOver), // gameLabel
            consumer.getGameCreatedById(_gameId).startTime, //maturity
            0, //initialMint
            2, // always two positions for spread/total
            tags, //tags
            true, // is child
            _mainMarket
        );

        _childMarket = sportsManager.getActiveMarketAddress(sportsManager.numActiveMarkets() - 1);

        // adding child markets
        _setChildMarkets(_gameId, _mainMarket, _childMarket, _isSpread, _spreadHome, _totalOver, tags[1]);
    }

    function _calculateTags(uint _sportsId, bool _isSpread) internal pure returns (uint[] memory) {
        uint[] memory result = new uint[](2);
        result[0] = MIN_TAG_NUMBER + _sportsId;
        result[1] = _isSpread ? TAG_NUMBER_SPREAD : TAG_NUMBER_TOTAL;
        return result;
    }

    function _append(
        bytes32 _gameId,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver
    ) internal view returns (string memory) {
        string memory teamVsTeam = string(
            abi.encodePacked(
                consumer.getGameCreatedById(_gameId).homeTeam,
                " vs ",
                consumer.getGameCreatedById(_gameId).awayTeam
            )
        );
        if (_isSpread) {
            return string(abi.encodePacked(teamVsTeam, "(", _parseSpread(_spreadHome), ")"));
        } else {
            return string(abi.encodePacked(teamVsTeam, " - ", Strings.toString(_totalOver)));
        }
    }

    function _parseSpread(int16 _spreadHome) internal pure returns (string memory) {
        return
            _spreadHome > 0
                ? Strings.toString(uint16(_spreadHome))
                : string(abi.encodePacked("-", Strings.toString(uint16(_spreadHome * (-1)))));
    }

    function _pauseOrUnpauseMarkets(
        IGamesOddsObtainer.GameOdds memory _game,
        address _main,
        bool _flag,
        bool _unpauseMain
    ) internal {
        if (_unpauseMain) {
            consumer.pauseOrUnpauseMarket(_main, _flag);
        }

        if (numberOfChildMarkets[_main] > 0) {
            if (_flag) {
                for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
                    consumer.pauseOrUnpauseMarket(mainMarketChildMarketIndex[_main][i], _flag);
                }
            } else {
                if (_areTotalOddsValid(_game)) {
                    address totalChildMarket = mainMarketTotalChildMarket[_main][_game.totalOver];
                    if (totalChildMarket == address(0)) {
                        address newMarket = _createMarketSpreadTotalMarket(
                            _game.gameId,
                            _main,
                            false,
                            _game.spreadHome,
                            _game.totalOver
                        );
                        _setCurrentChildMarkets(_main, newMarket, false);
                    } else {
                        consumer.pauseOrUnpauseMarket(totalChildMarket, _flag);
                        _setCurrentChildMarkets(_main, totalChildMarket, false);
                    }
                }
                if (_areSpreadOddsValid(_game)) {
                    address spreadChildMarket = mainMarketSpreadChildMarket[_main][_game.spreadHome];
                    if (spreadChildMarket == address(0)) {
                        address newMarket = _createMarketSpreadTotalMarket(
                            _game.gameId,
                            _main,
                            true,
                            _game.spreadHome,
                            _game.totalOver
                        );
                        _setCurrentChildMarkets(_main, newMarket, true);
                    } else {
                        consumer.pauseOrUnpauseMarket(spreadChildMarket, _flag);
                        _setCurrentChildMarkets(_main, spreadChildMarket, true);
                    }
                }
            }
        }
    }

    function _pauseTotalSpreadMarkets(IGamesOddsObtainer.GameOdds memory _game, bool _isSpread) internal {
        address _main = consumer.marketPerGameId(_game.gameId);
        // in number of childs more then 0
        if (numberOfChildMarkets[_main] > 0) {
            for (uint i = 0; i < numberOfChildMarkets[_main]; i++) {
                address _child = mainMarketChildMarketIndex[_main][i];
                if (isSpreadChildMarket[_child] == _isSpread) {
                    consumer.pauseOrUnpauseMarket(_child, true);
                }
            }
        }
    }

    function _setCurrentChildMarkets(
        address _main,
        address _child,
        bool _isSpread
    ) internal {
        if (_isSpread) {
            currentActiveSpreadChildMarket[_main] = _child;
        } else {
            currentActiveTotalChildMarket[_main] = _child;
        }
    }

    function _setChildMarkets(
        bytes32 _gameId,
        address _main,
        address _child,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver,
        uint _type
    ) internal {
        consumer.setGameIdPerChildMarket(_gameId, _child);
        gameIdPerChildMarket[_child] = _gameId;
        childMarketCreated[_child] = true;
        // adding child markets
        childMarketMainMarket[_child] = _main;
        mainMarketChildMarketIndex[_main][numberOfChildMarkets[_main]] = _child;
        numberOfChildMarkets[_main] = numberOfChildMarkets[_main] + 1;
        if (_isSpread) {
            mainMarketSpreadChildMarket[_main][_spreadHome] = _child;
            childMarketSread[_child] = _spreadHome;
            currentActiveSpreadChildMarket[_main] = _child;
            isSpreadChildMarket[_child] = true;
            emit CreateChildSpreadSportsMarket(_main, _child, _gameId, _spreadHome, getNormalizedChildOdds(_child), _type);
        } else {
            mainMarketTotalChildMarket[_main][_totalOver] = _child;
            childMarketTotal[_child] = _totalOver;
            currentActiveTotalChildMarket[_main] = _child;
            emit CreateChildTotalSportsMarket(_main, _child, _gameId, _totalOver, getNormalizedChildOdds(_child), _type);
        }
    }

    function _resolveMarketTotal(
        address _child,
        uint24 _homeScore,
        uint24 _awayScore
    ) internal {
        uint24 totalLine = childMarketTotal[_child];

        uint outcome = (_homeScore + _awayScore) * 100 > totalLine ? HOME_WIN : (_homeScore + _awayScore) * 100 < totalLine
            ? AWAY_WIN
            : CANCELLED;

        sportsManager.resolveMarket(_child, outcome);
        emit ResolveChildMarket(_child, outcome, childMarketMainMarket[_child], _homeScore, _awayScore);
    }

    function _resolveMarketSpread(
        address _child,
        uint16 _homeScore,
        uint16 _awayScore
    ) internal {
        int16 homeScoreWithSpread = int16(_homeScore) * 100 + childMarketSread[_child];
        int16 newAwayScore = int16(_awayScore) * 100;

        uint outcome = homeScoreWithSpread > newAwayScore ? HOME_WIN : homeScoreWithSpread < newAwayScore
            ? AWAY_WIN
            : CANCELLED;
        sportsManager.resolveMarket(_child, outcome);
        emit ResolveChildMarket(_child, outcome, childMarketMainMarket[_child], uint24(_homeScore), uint24(_awayScore));
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice sets consumer, verifier, manager address
    /// @param _consumer consumer address
    /// @param _verifier verifier address
    /// @param _sportsManager sport manager address
    function setContracts(
        address _consumer,
        address _verifier,
        address _sportsManager,
        address _receiver
    ) external onlyOwner {
        consumer = ITherundownConsumer(_consumer);
        verifier = ITherundownConsumerVerifier(_verifier);
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        oddsReceiver = _receiver;

        emit NewContractAddresses(_consumer, _verifier, _sportsManager, _receiver);
    }

    /// @notice sets if sport is suported or not (delete from supported sport)
    /// @param _sportId sport id which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedSportForTotalAndSpread(uint _sportId, bool _isSupported) external onlyOwner {
        doesSportSupportSpreadAndTotal[_sportId] = _isSupported;
        emit SupportedSportForTotalAndSpreadAdded(_sportId, _isSupported);
    }

    /* ========== MODIFIERS ========== */

    modifier canUpdateOdds() {
        require(msg.sender == address(consumer) || msg.sender == oddsReceiver, "Invalid sender");
        _;
    }

    modifier onlyConsumer() {
        require(msg.sender == address(consumer), "Only consumer");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == address(sportsManager), "Only manager");
        _;
    }

    /* ========== EVENTS ========== */

    event GameOddsAdded(bytes32 _requestId, bytes32 _id, IGamesOddsObtainer.GameOdds _game, uint[] _normalizedOdds);
    event GamedOddsAddedChild(
        bytes32 _id,
        address _market,
        IGamesOddsObtainer.GameOdds _game,
        uint[] _normalizedChildOdds,
        uint _type
    );
    event InvalidOddsForMarket(bytes32 _requestId, address _marketAddress, bytes32 _id, IGamesOddsObtainer.GameOdds _game);
    event OddsCircuitBreaker(address _marketAddress, bytes32 _id);
    event NewContractAddresses(address _consumer, address _verifier, address _sportsManager, address _receiver);
    event CreateChildSpreadSportsMarket(
        address _main,
        address _child,
        bytes32 _id,
        int16 _spread,
        uint[] _normalizedOdds,
        uint _type
    );
    event CreateChildTotalSportsMarket(
        address _main,
        address _child,
        bytes32 _id,
        uint24 _total,
        uint[] _normalizedOdds,
        uint _type
    );
    event SupportedSportForTotalAndSpreadAdded(uint _sportId, bool _isSupported);
    event ResolveChildMarket(address _child, uint _outcome, address _main, uint24 _homeScore, uint24 _awayScore);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";
import "./GamesQueue.sol";

// interface
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/ITherundownConsumerVerifier.sol";
import "../../interfaces/IGamesOddsObtainer.sol";
import "../../interfaces/ISportPositionalMarket.sol";

/// @title Consumer contract which stores all data from CL data feed (Link to docs: https://market.link/nodes/TheRundown/integrations), also creates all sports markets based on that data
/// @author gruja
contract TherundownConsumer is Initializable, ProxyOwned, ProxyPausable {
    /* ========== CONSTANTS =========== */

    uint public constant CANCELLED = 0;
    uint public constant HOME_WIN = 1;
    uint public constant AWAY_WIN = 2;
    uint public constant RESULT_DRAW = 3;
    uint public constant MIN_TAG_NUMBER = 9000;

    /* ========== CONSUMER STATE VARIABLES ========== */

    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        bytes32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
        uint40 lastUpdated;
    }

    struct GameOdds {
        bytes32 gameId;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
    }

    /* ========== STATE VARIABLES ========== */

    // global params
    address public wrapperAddress;
    mapping(address => bool) public whitelistedAddresses;

    // Maps <RequestId, Result>
    mapping(bytes32 => bytes[]) public requestIdGamesCreated; // deprecated see Wrapper
    mapping(bytes32 => bytes[]) public requestIdGamesResolved; // deprecated see Wrapper
    mapping(bytes32 => bytes[]) public requestIdGamesOdds; // deprecated see Wrapper

    // Maps <GameId, Game>
    mapping(bytes32 => GameCreate) public gameCreated;
    mapping(bytes32 => GameResolve) public gameResolved;
    mapping(bytes32 => GameOdds) public gameOdds; // deprecated see GamesOddsObtainer
    mapping(bytes32 => uint) public sportsIdPerGame;
    mapping(bytes32 => bool) public gameFulfilledCreated;
    mapping(bytes32 => bool) public gameFulfilledResolved;

    // sports props
    mapping(uint => bool) public supportedSport;
    mapping(uint => bool) public twoPositionSport;
    mapping(uint => bool) public supportResolveGameStatuses;
    mapping(uint => bool) public cancelGameStatuses;

    // market props
    ISportPositionalMarketManager public sportsManager;
    mapping(bytes32 => address) public marketPerGameId;
    mapping(address => bytes32) public gameIdPerMarket;
    mapping(address => bool) public marketResolved;
    mapping(address => bool) public marketCanceled;

    // game
    GamesQueue public queues;
    mapping(bytes32 => uint) public oddsLastPulledForGame; // deprecated see GamesOddsObtainer
    mapping(uint => bytes32[]) public gamesPerDate; // deprecated use gamesPerDatePerSport
    mapping(uint => mapping(uint => bool)) public isSportOnADate;
    mapping(address => bool) public invalidOdds; // deprecated see GamesOddsObtainer
    mapping(address => bool) public marketCreated;
    mapping(uint => mapping(uint => bytes32[])) public gamesPerDatePerSport;
    mapping(address => bool) public isPausedByCanceledStatus;
    mapping(address => bool) public canMarketBeUpdated; // deprecated
    mapping(bytes32 => uint) public gameOnADate;

    ITherundownConsumerVerifier public verifier;
    mapping(bytes32 => GameOdds) public backupOdds; // deprecated see GamesOddsObtainer
    IGamesOddsObtainer public oddsObtainer;
    uint public maxNumberOfMarketsToResolve;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        uint[] memory _supportedSportIds,
        address _sportsManager,
        uint[] memory _twoPositionSports,
        GamesQueue _queues,
        uint[] memory _resolvedStatuses,
        uint[] memory _cancelGameStatuses
    ) external initializer {
        setOwner(_owner);

        for (uint i; i < _supportedSportIds.length; i++) {
            supportedSport[_supportedSportIds[i]] = true;
        }
        for (uint i; i < _twoPositionSports.length; i++) {
            twoPositionSport[_twoPositionSports[i]] = true;
        }
        for (uint i; i < _resolvedStatuses.length; i++) {
            supportResolveGameStatuses[_resolvedStatuses[i]] = true;
        }
        for (uint i; i < _cancelGameStatuses.length; i++) {
            cancelGameStatuses[_cancelGameStatuses[i]] = true;
        }

        sportsManager = ISportPositionalMarketManager(_sportsManager);
        queues = _queues;
        whitelistedAddresses[_owner] = true;
    }

    /* ========== CONSUMER FULFILL FUNCTIONS ========== */

    /// @notice fulfill all data necessary to create sport markets
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to be stored and transfered to markets
    /// @param _sportId sports id which is provided from CL (Example: NBA = 4)
    /// @param _date date on which game/games are played
    function fulfillGamesCreated(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportId,
        uint _date
    ) external onlyWrapper {
        if (_games.length > 0) {
            isSportOnADate[_date][_sportId] = true;
        }

        for (uint i = 0; i < _games.length; i++) {
            GameCreate memory gameForProcessing = abi.decode(_games[i], (GameCreate));
            // new game
            if (
                !gameFulfilledCreated[gameForProcessing.gameId] &&
                !verifier.isInvalidNames(gameForProcessing.homeTeam, gameForProcessing.awayTeam) &&
                gameForProcessing.startTime > block.timestamp
            ) {
                _updateGameOnADate(gameForProcessing.gameId, _date, _sportId);
                _createGameFulfill(_requestId, gameForProcessing, _sportId);
            }
            // old game UFC checking fighters
            else if (gameFulfilledCreated[gameForProcessing.gameId]) {
                GameCreate memory currentGameValues = getGameCreatedById(gameForProcessing.gameId);

                // if name of fighter (away or home) is not the same
                if (
                    (!verifier.areTeamsEqual(gameForProcessing.homeTeam, currentGameValues.homeTeam) ||
                        !verifier.areTeamsEqual(gameForProcessing.awayTeam, currentGameValues.awayTeam))
                ) {
                    // double-check if market exists -> cancel market -> create new for queue
                    if (marketCreated[marketPerGameId[gameForProcessing.gameId]]) {
                        if (_sportId == 7) {
                            _cancelMarket(gameForProcessing.gameId, false);
                            _updateGameOnADate(gameForProcessing.gameId, _date, _sportId);
                            _createGameFulfill(_requestId, gameForProcessing, _sportId);
                        } else {
                            _pauseOrUnpauseMarket(marketPerGameId[gameForProcessing.gameId], true);
                            oddsObtainer.pauseUnpauseChildMarkets(marketPerGameId[gameForProcessing.gameId], true);
                        }
                    }
                    // checking time
                } else if (gameForProcessing.startTime != currentGameValues.startTime) {
                    _updateGameOnADate(gameForProcessing.gameId, _date, _sportId);
                    // if NEW start time is in future
                    if (gameForProcessing.startTime > block.timestamp) {
                        // this checks is for new markets
                        sportsManager.updateDatesForMarket(
                            marketPerGameId[gameForProcessing.gameId],
                            gameForProcessing.startTime
                        );
                        gameCreated[gameForProcessing.gameId] = gameForProcessing;
                        queues.updateGameStartDate(gameForProcessing.gameId, gameForProcessing.startTime);
                    } else {
                        // double-check if market existst
                        if (
                            marketCreated[marketPerGameId[gameForProcessing.gameId]] &&
                            currentGameValues.startTime > block.timestamp
                        ) {
                            _pauseOrUnpauseMarket(marketPerGameId[gameForProcessing.gameId], true);
                            oddsObtainer.pauseUnpauseChildMarkets(marketPerGameId[gameForProcessing.gameId], true);
                        }
                    }
                }
            }
        }
    }

    /// @notice fulfill all data necessary to resolve sport markets
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to be resolved
    /// @param _sportId sports id which is provided from CL (Example: NBA = 4)
    function fulfillGamesResolved(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportId
    ) external onlyWrapper {
        uint numberOfMarketsToResolve = _games.length;
        for (uint i = 0; i < _games.length; i++) {
            GameResolve memory game = abi.decode(_games[i], (GameResolve));
            address _main = marketPerGameId[game.gameId];
            numberOfMarketsToResolve = numberOfMarketsToResolve + oddsObtainer.numberOfChildMarkets(_main);
        }
        for (uint i = 0; i < _games.length; i++) {
            GameResolve memory game = abi.decode(_games[i], (GameResolve));
            // if game is not resolved already and there is market for that game
            if (!gameFulfilledResolved[game.gameId] && marketPerGameId[game.gameId] != address(0)) {
                _resolveGameFulfill(_requestId, game, _sportId, numberOfMarketsToResolve);
            }
        }
    }

    /// @notice fulfill all data necessary to populate odds of a game
    /// @param _requestId unique request id form CL
    /// @param _games array of a games that needed to update the odds
    function fulfillGamesOdds(bytes32 _requestId, bytes[] memory _games) external onlyWrapper {
        for (uint i = 0; i < _games.length; i++) {
            IGamesOddsObtainer.GameOdds memory game = abi.decode(_games[i], (IGamesOddsObtainer.GameOdds));
            // game needs to be fulfilled and market needed to be created
            if (gameFulfilledCreated[game.gameId] && marketPerGameId[game.gameId] != address(0)) {
                oddsObtainer.obtainOdds(_requestId, game, sportsIdPerGame[game.gameId]);
            }
        }
    }

    /// @notice creates market for a given game id
    /// @param _gameId game id
    function createMarketForGame(bytes32 _gameId) public {
        require(
            marketPerGameId[_gameId] == address(0) ||
                (marketCanceled[marketPerGameId[_gameId]] && marketPerGameId[_gameId] != address(0)),
            "ID1"
        );
        require(gameFulfilledCreated[_gameId], "ID2");
        require(queues.gamesCreateQueue(queues.firstCreated()) == _gameId, "ID3");
        _createMarket(_gameId);
    }

    /// @notice creates markets for a given game ids
    /// @param _gameIds game ids as array
    function createAllMarketsForGames(bytes32[] memory _gameIds) external {
        for (uint i; i < _gameIds.length; i++) {
            createMarketForGame(_gameIds[i]);
        }
    }

    /// @notice resolve market for a given game id
    /// @param _gameId game id
    function resolveMarketForGame(bytes32 _gameId) public {
        require(!isGameResolvedOrCanceled(_gameId), "ID4");
        require(gameFulfilledResolved[_gameId], "ID5");
        _resolveMarket(_gameId, false);
    }

    /// @notice resolve all markets for a given game ids
    /// @param _gameIds game ids as array
    function resolveAllMarketsForGames(bytes32[] memory _gameIds) external {
        for (uint i; i < _gameIds.length; i++) {
            resolveMarketForGame(_gameIds[i]);
        }
    }

    /// @notice resolve market for a given market address
    /// @param _market market address
    /// @param _outcome outcome of a game (1: home win, 2: away win, 3: draw, 0: cancel market)
    /// @param _homeScore score of home team
    /// @param _awayScore score of away team
    function resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        bool _useBackupOdds
    ) external isAddressWhitelisted canGameBeResolved(gameIdPerMarket[_market], _outcome, _homeScore, _awayScore) {
        _resolveMarketManually(_market, _outcome, _homeScore, _awayScore, _useBackupOdds);
    }

    /// @notice pause/unpause market for a given market address
    /// @param _market market address
    /// @param _pause pause = true, unpause = false
    function pauseOrUnpauseMarketManually(address _market, bool _pause) external isAddressWhitelisted {
        require(gameIdPerMarket[_market] != 0 && gameFulfilledCreated[gameIdPerMarket[_market]], "ID20");
        _pauseOrUnpauseMarketManually(_market, _pause);
    }

    /// @notice reopen game for processing the creation again
    /// @param gameId gameId
    function reopenGameForCreationProcessing(bytes32 gameId) external isAddressWhitelisted {
        require(gameFulfilledCreated[gameId], "ID22");
        gameFulfilledCreated[gameId] = false;
        gameFulfilledResolved[gameId] = false;
    }

    /// @notice setting isPausedByCanceledStatus from obtainer see @GamesOddsObtainer
    /// @param _market market address
    /// @param _flag flag true/false
    function setPausedByCanceledStatus(address _market, bool _flag) external onlyObtainer {
        isPausedByCanceledStatus[_market] = _flag;
    }

    /// @notice pause market from obtainer see @GamesOddsObtainer
    /// @param _market market address
    /// @param _pause flag true/false
    function pauseOrUnpauseMarket(address _market, bool _pause) external onlyObtainer {
        _pauseOrUnpauseMarket(_market, _pause);
    }

    /// @notice setting gameid per market
    /// @param _gameId game id
    /// @param _child child market address
    function setGameIdPerChildMarket(bytes32 _gameId, address _child) external onlyObtainer {
        gameIdPerMarket[_child] = _gameId;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice view function which returns game created object based on id of a game
    /// @param _gameId game id
    /// @return GameCreate game create object
    function getGameCreatedById(bytes32 _gameId) public view returns (GameCreate memory) {
        return gameCreated[_gameId];
    }

    /// @notice view function which returns game startTime
    /// @param _gameId game id
    function getGameStartTime(bytes32 _gameId) external view returns (uint256) {
        return gameCreated[_gameId].startTime;
    }

    /// @notice view function which returns games on certan date and sportid
    /// @param _sportId date
    /// @param _date date
    /// @return bytes32[] list of games
    function getGamesPerDatePerSport(uint _sportId, uint _date) external view returns (bytes32[] memory) {
        return gamesPerDatePerSport[_sportId][_date];
    }

    /// @notice view function which returns props (sportid and game date)
    /// @param _market market address
    /// @return _sportId sport ids
    /// @return _gameDate game date on which game is playing
    function getGamePropsForOdds(address _market)
        external
        view
        returns (
            uint _sportId,
            uint _gameDate,
            bytes32 _id
        )
    {
        return (sportsIdPerGame[gameIdPerMarket[_market]], gameOnADate[gameIdPerMarket[_market]], gameIdPerMarket[_market]);
    }

    /// @notice view function which returns if game is resolved or canceled and ready for market to be resolved or canceled
    /// @param _gameId game id for which game is looking
    /// @return bool is it ready for resolve or cancel true/false
    function isGameResolvedOrCanceled(bytes32 _gameId) public view returns (bool) {
        return marketResolved[marketPerGameId[_gameId]] || marketCanceled[marketPerGameId[_gameId]];
    }

    /// @notice view function which returns if sport is two positional (no draw, example: NBA)
    /// @param _sportsId sport id for which is looking
    /// @return bool is sport two positional true/false
    function isSportTwoPositionsSport(uint _sportsId) public view returns (bool) {
        return twoPositionSport[_sportsId];
    }

    /// @notice view function which returns if market is child or not
    /// @param _market address of the checked market
    /// @return bool if the _market is child or not (true/false)
    function isChildMarket(address _market) public view returns (bool) {
        return oddsObtainer.childMarketMainMarket(_market) != address(0);
    }

    /// @notice view function which returns if game is resolved
    /// @param _gameId game id for which game is looking
    /// @return bool is game resolved true/false
    function isGameInResolvedStatus(bytes32 _gameId) public view returns (bool) {
        return _isGameStatusResolved(gameResolved[_gameId]);
    }

    /// @notice view function which returns normalized odds up to 100 (Example: 50-40-10)
    /// @param _gameId game id for which game is looking
    /// @return uint[] odds array normalized
    function getNormalizedOdds(bytes32 _gameId) public view returns (uint[] memory) {
        return oddsObtainer.getNormalizedOdds(_gameId);
    }

    /// @notice view function which returns normalized odds up to 100 (Example: 50-40-10)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedOddsForMarket(address _market) public view returns (uint[] memory) {
        return marketCreated[_market] ? getNormalizedOdds(gameIdPerMarket[_market]) : getNormalizedChildOdds(_market);
    }

    /// @notice view function which returns normalized odds up to 100 (Example: 50-40-10)
    /// @param _market market
    /// @return uint[] odds array normalized
    function getNormalizedChildOdds(address _market) public view returns (uint[] memory) {
        return oddsObtainer.getNormalizedChildOdds(_market);
    }

    /* ========== INTERNALS ========== */

    function _createGameFulfill(
        bytes32 requestId,
        GameCreate memory _game,
        uint _sportId
    ) internal {
        gameCreated[_game.gameId] = _game;
        sportsIdPerGame[_game.gameId] = _sportId;
        queues.enqueueGamesCreated(_game.gameId, _game.startTime, _sportId);
        gameFulfilledCreated[_game.gameId] = true;
        oddsObtainer.setFirstOdds(_game.gameId, _game.homeOdds, _game.awayOdds, _game.drawOdds);

        emit GameCreated(
            requestId,
            _sportId,
            _game.gameId,
            _game,
            queues.lastCreated(),
            oddsObtainer.getNormalizedOdds(_game.gameId)
        );
    }

    function _resolveGameFulfill(
        bytes32 requestId,
        GameResolve memory _game,
        uint _sportId,
        uint _numberOfMarketsToResolve
    ) internal {
        GameCreate memory singleGameCreated = getGameCreatedById(_game.gameId);

        // if status is resolved OR (status is canceled AND start time has passed fulfill game to be resolved)
        if (
            _isGameStatusResolved(_game) ||
            (cancelGameStatuses[_game.statusId] && singleGameCreated.startTime < block.timestamp)
        ) {
            gameResolved[_game.gameId] = _game;
            gameFulfilledResolved[_game.gameId] = true;

            emit GameResolved(requestId, _sportId, _game.gameId, _game, queues.lastResolved());

            if (_numberOfMarketsToResolve >= maxNumberOfMarketsToResolve) {
                queues.enqueueGamesResolved(_game.gameId);
            } else {
                _resolveMarket(_game.gameId, true);
            }
        }
        // if status is canceled AND start time has not passed only pause market
        else if (cancelGameStatuses[_game.statusId] && singleGameCreated.startTime >= block.timestamp) {
            isPausedByCanceledStatus[marketPerGameId[_game.gameId]] = true;
            _pauseOrUnpauseMarket(marketPerGameId[_game.gameId], true);
            oddsObtainer.pauseUnpauseChildMarkets(marketPerGameId[_game.gameId], true);
        }
    }

    function _createMarket(bytes32 _gameId) internal {
        GameCreate memory game = getGameCreatedById(_gameId);
        // only markets in a future, if not dequeue that creation
        if (game.startTime > block.timestamp) {
            uint[] memory tags = _calculateTags(sportsIdPerGame[_gameId]);

            // create
            ISportPositionalMarket market = sportsManager.createMarket(
                _gameId,
                string(abi.encodePacked(game.homeTeam, " vs ", game.awayTeam)), // gameLabel
                game.startTime, //maturity
                0, //initialMint
                isSportTwoPositionsSport(sportsIdPerGame[_gameId]) ? 2 : 3,
                tags, //tags
                false,
                address(0)
            );

            marketPerGameId[game.gameId] = address(market);
            gameIdPerMarket[address(market)] = game.gameId;
            marketCreated[address(market)] = true;

            oddsObtainer.setFirstNormalizedOdds(game.gameId, address(market));

            queues.dequeueGamesCreated();

            emit CreateSportsMarket(address(market), game.gameId, game, tags, oddsObtainer.getNormalizedOdds(game.gameId));
        } else {
            queues.dequeueGamesCreated();
        }
    }

    function _resolveMarket(bytes32 _gameId, bool _resolveMarketWithoutQueue) internal {
        GameResolve memory game = gameResolved[_gameId];
        GameCreate memory singleGameCreated = getGameCreatedById(_gameId);

        if (_isGameStatusResolved(game)) {
            if (oddsObtainer.invalidOdds(marketPerGameId[game.gameId])) {
                _pauseOrUnpauseMarket(marketPerGameId[game.gameId], false);
                oddsObtainer.pauseUnpauseChildMarkets(marketPerGameId[game.gameId], false);
            }

            (uint _outcome, uint8 _homeScore, uint8 _awayScore) = _calculateOutcome(game);

            // if result is draw and game is UFC or NFL, cancel market
            if (_outcome == RESULT_DRAW && _isDrawForCancelationBySport(sportsIdPerGame[game.gameId])) {
                _cancelMarket(game.gameId, !_resolveMarketWithoutQueue);
            } else {
                // if market is paused only remove from queue
                if (!sportsManager.isMarketPaused(marketPerGameId[game.gameId])) {
                    _setMarketCancelOrResolved(marketPerGameId[game.gameId], _outcome, _homeScore, _awayScore);
                    if (!_resolveMarketWithoutQueue) {
                        _cleanStorageQueue();
                    }

                    emit ResolveSportsMarket(marketPerGameId[game.gameId], game.gameId, _outcome);
                } else {
                    if (!_resolveMarketWithoutQueue) {
                        _cleanStorageQueue();
                    }
                }
            }
            // if status is canceled and start time of a game passed cancel market
        } else if (cancelGameStatuses[game.statusId] && singleGameCreated.startTime < block.timestamp) {
            _cancelMarket(game.gameId, !_resolveMarketWithoutQueue);
        }
    }

    function _resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        bool _useBackupOdds
    ) internal {
        if (_useBackupOdds) {
            require(_outcome == CANCELLED, "ID17");
            require(oddsObtainer.areOddsValid(gameIdPerMarket[_market], _useBackupOdds));
            oddsObtainer.setBackupOddsAsMainOddsForGame(gameIdPerMarket[_market]);
        }

        _pauseOrUnpauseMarket(_market, false);
        oddsObtainer.pauseUnpauseChildMarkets(_market, false);
        _setMarketCancelOrResolved(_market, _outcome, _homeScore, _awayScore);
        gameResolved[gameIdPerMarket[_market]] = GameResolve(
            gameIdPerMarket[_market],
            _homeScore,
            _awayScore,
            isSportTwoPositionsSport(sportsIdPerGame[gameIdPerMarket[_market]]) ? 8 : 11,
            0
        );

        emit GameResolved(
            gameIdPerMarket[_market], // no req. from CL (manual resolve) so just put gameID
            sportsIdPerGame[gameIdPerMarket[_market]],
            gameIdPerMarket[_market],
            gameResolved[gameIdPerMarket[_market]],
            0
        );

        if (_outcome == CANCELLED) {
            emit CancelSportsMarket(_market, gameIdPerMarket[_market]);
        } else {
            emit ResolveSportsMarket(_market, gameIdPerMarket[_market], _outcome);
        }
    }

    function _pauseOrUnpauseMarketManually(address _market, bool _pause) internal {
        _pauseOrUnpauseMarket(_market, _pause);
        oddsObtainer.pauseUnpauseCurrentActiveChildMarket(gameIdPerMarket[_market], _market, _pause);
    }

    function _pauseOrUnpauseMarket(address _market, bool _pause) internal {
        if (sportsManager.isMarketPaused(_market) != _pause) {
            sportsManager.setMarketPaused(_market, _pause);
            emit PauseSportsMarket(_market, _pause);
        }
    }

    function _cancelMarket(bytes32 _gameId, bool cleanStorage) internal {
        _setMarketCancelOrResolved(marketPerGameId[_gameId], CANCELLED, 0, 0);
        if (cleanStorage) {
            _cleanStorageQueue();
        }

        emit CancelSportsMarket(marketPerGameId[_gameId], _gameId);
    }

    function _setMarketCancelOrResolved(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) internal {
        sportsManager.resolveMarket(_market, _outcome);
        oddsObtainer.resolveChildMarkets(_market, _outcome, _homeScore, _awayScore);
        marketCanceled[_market] = _outcome == CANCELLED;
        marketResolved[_market] = _outcome != CANCELLED;
    }

    function _cleanStorageQueue() internal {
        queues.dequeueGamesResolved();
    }

    function _calculateTags(uint _sportsId) internal pure returns (uint[] memory) {
        uint[] memory result = new uint[](1);
        result[0] = MIN_TAG_NUMBER + _sportsId;
        return result;
    }

    function _isDrawForCancelationBySport(uint _sportsId) internal pure returns (bool) {
        // UFC or NFL
        return _sportsId == 7 || _sportsId == 2;
    }

    function _isGameStatusResolved(GameResolve memory _game) internal view returns (bool) {
        return supportResolveGameStatuses[_game.statusId];
    }

    function _calculateOutcome(GameResolve memory _game)
        internal
        pure
        returns (
            uint,
            uint8,
            uint8
        )
    {
        if (_game.homeScore == _game.awayScore) {
            return (RESULT_DRAW, _game.homeScore, _game.awayScore);
        }
        return
            _game.homeScore > _game.awayScore
                ? (HOME_WIN, _game.homeScore, _game.awayScore)
                : (AWAY_WIN, _game.homeScore, _game.awayScore);
    }

    function _updateGameOnADate(
        bytes32 _gameId,
        uint _date,
        uint _sportId
    ) internal {
        if (gameOnADate[_gameId] != _date) {
            gamesPerDatePerSport[_sportId][_date].push(_gameId);
            gameOnADate[_gameId] = _date;
        }
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice sets if sport is suported or not (delete from supported sport)
    /// @param _sportId sport id which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedSport(uint _sportId, bool _isSupported) external onlyOwner {
        require(supportedSport[_sportId] != _isSupported);
        supportedSport[_sportId] = _isSupported;
        emit SupportedSportsChanged(_sportId, _isSupported);
    }

    /// @notice sets resolved status which is supported or not
    /// @param _status status ID which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedResolvedStatuses(uint _status, bool _isSupported) external onlyOwner {
        require(supportResolveGameStatuses[_status] != _isSupported);
        supportResolveGameStatuses[_status] = _isSupported;
        emit SupportedResolvedStatusChanged(_status, _isSupported);
    }

    /// @notice sets cancel status which is supported or not
    /// @param _status ststus ID which needs to be supported or not
    /// @param _isSupported true/false (supported or not)
    function setSupportedCancelStatuses(uint _status, bool _isSupported) external onlyOwner {
        require(cancelGameStatuses[_status] != _isSupported);
        cancelGameStatuses[_status] = _isSupported;
        emit SupportedCancelStatusChanged(_status, _isSupported);
    }

    /// @notice sets if sport is two positional (Example: NBA)
    /// @param _sportId sport ID which is two positional
    /// @param _isTwoPosition true/false (two positional sport or not)
    function setTwoPositionSport(uint _sportId, bool _isTwoPosition) external onlyOwner {
        require(supportedSport[_sportId] && twoPositionSport[_sportId] != _isTwoPosition);
        twoPositionSport[_sportId] = _isTwoPosition;
        emit TwoPositionSportChanged(_sportId, _isTwoPosition);
    }

    /// @notice sets how many markets (main + children) are processed without queue
    /// @param _maxNumberOfMarketsToResolve max number of markets for automatic resolve w/o queue entering
    function setNewMaxNumberOfMarketsToResolve(uint _maxNumberOfMarketsToResolve) external onlyOwner {
        require(maxNumberOfMarketsToResolve != _maxNumberOfMarketsToResolve);
        maxNumberOfMarketsToResolve = _maxNumberOfMarketsToResolve;
        emit NewMaxNumberOfMarketsToResolve(_maxNumberOfMarketsToResolve);
    }

    /// @notice sets wrapper, manager, queue  address
    /// @param _wrapperAddress wrapper address
    /// @param _queues queue address
    /// @param _sportsManager sport manager address
    function setSportContracts(
        address _wrapperAddress,
        GamesQueue _queues,
        address _sportsManager,
        address _verifier,
        address _oddsObtainer
    ) external onlyOwner {
        sportsManager = ISportPositionalMarketManager(_sportsManager);
        queues = _queues;
        wrapperAddress = _wrapperAddress;
        verifier = ITherundownConsumerVerifier(_verifier);
        oddsObtainer = IGamesOddsObtainer(_oddsObtainer);

        emit NewSportContracts(_wrapperAddress, _queues, _sportsManager, _verifier, _oddsObtainer);
    }

    /// @notice adding/removing whitelist address depending on a flag
    /// @param _whitelistAddress address that needed to be whitelisted/ ore removed from WL
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function addToWhitelist(address _whitelistAddress, bool _flag) external onlyOwner {
        require(_whitelistAddress != address(0) && whitelistedAddresses[_whitelistAddress] != _flag);
        whitelistedAddresses[_whitelistAddress] = _flag;
        emit AddedIntoWhitelist(_whitelistAddress, _flag);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyWrapper() {
        require(msg.sender == wrapperAddress, "ID9");
        _;
    }

    modifier onlyObtainer() {
        require(msg.sender == address(oddsObtainer), "ID16");
        _;
    }

    modifier isAddressWhitelisted() {
        require(whitelistedAddresses[msg.sender], "ID10");
        _;
    }

    modifier canGameBeResolved(
        bytes32 _gameId,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) {
        require(!isGameResolvedOrCanceled(_gameId), "ID13");
        require(marketPerGameId[_gameId] != address(0), "ID14");
        require(
            verifier.isValidOutcomeForGame(isSportTwoPositionsSport(sportsIdPerGame[_gameId]), _outcome) &&
                verifier.isValidOutcomeWithResult(_outcome, _homeScore, _awayScore),
            "ID15"
        );
        _;
    }
    /* ========== EVENTS ========== */

    event GameCreated(
        bytes32 _requestId,
        uint _sportId,
        bytes32 _id,
        GameCreate _game,
        uint _queueIndex,
        uint[] _normalizedOdds
    );
    event GameResolved(bytes32 _requestId, uint _sportId, bytes32 _id, GameResolve _game, uint _queueIndex);
    event GameOddsAdded(bytes32 _requestId, bytes32 _id, GameOdds _game, uint[] _normalizedOdds); // deprecated see GamesOddsObtainer
    event CreateSportsMarket(address _marketAddress, bytes32 _id, GameCreate _game, uint[] _tags, uint[] _normalizedOdds);
    event ResolveSportsMarket(address _marketAddress, bytes32 _id, uint _outcome);
    event PauseSportsMarket(address _marketAddress, bool _pause);
    event CancelSportsMarket(address _marketAddress, bytes32 _id);
    event InvalidOddsForMarket(bytes32 _requestId, address _marketAddress, bytes32 _id, GameOdds _game); // deprecated see GamesOddsObtainer
    event SupportedSportsChanged(uint _sportId, bool _isSupported);
    event SupportedResolvedStatusChanged(uint _status, bool _isSupported);
    event SupportedCancelStatusChanged(uint _status, bool _isSupported);
    event TwoPositionSportChanged(uint _sportId, bool _isTwoPosition);
    event NewSportsMarketManager(address _sportsManager); // deprecated
    event NewWrapperAddress(address _wrapperAddress); // deprecated
    event NewQueueAddress(GamesQueue _queues); // deprecated
    event NewSportContracts(
        address _wrapperAddress,
        GamesQueue _queues,
        address _sportsManager,
        address _verifier,
        address _oddsObtainer
    );
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event OddsCircuitBreaker(address _marketAddress, bytes32 _id); // deprecated see GamesOddsObtainer
    event NewMaxNumberOfMarketsToResolve(uint _maxNumber);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

import "./OvertimeVoucher.sol";

contract OvertimeVoucherEscrow is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    /* ========== LIBRARIES ========== */
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    /// @return The sUSD contract used for payment
    IERC20Upgradeable public sUSD;

    /// @return OvertimeVoucher used for minting tokens
    OvertimeVoucher public overtimeVoucher;

    /// @return Address whitelisted for claiming voucher in claiming period
    mapping(uint => mapping(address => bool)) public whitelistedAddressesPerPeriod;

    /// @return Address already claimed voucher in claiming period
    mapping(uint => mapping(address => bool)) public addressClaimedVoucherPerPeriod;

    /// @return Amount of sUSD in voucher to be minted/claimed
    uint public voucherAmount;

    /// @return Timestamp until claiming period is open
    mapping(uint => uint) public periodEnd;

    /// @return Current claiming period number
    uint public period;

    /* ========== CONSTRUCTOR ========== */
    function initialize(
        address _owner,
        IERC20Upgradeable _sUSD,
        address _overtimeVoucher,
        address[] calldata _whitelistedAddresses,
        uint _voucherAmount,
        uint _periodEnd
    ) external initializer {
        setOwner(_owner);
        initNonReentrant();
        sUSD = _sUSD;
        overtimeVoucher = OvertimeVoucher(_overtimeVoucher);
        voucherAmount = _voucherAmount;

        period = 1;
        periodEnd[1] = _periodEnd;

        setWhitelistedAddresses(_whitelistedAddresses, true);

        sUSD.approve(_overtimeVoucher, type(uint256).max);
    }

    /// @notice Mints OvertimeVoucher and sends it to the user if given address
    /// is whitelisted and claiming period is not closed yet
    function claimVoucher() external canClaim {
        overtimeVoucher.mint(msg.sender, voucherAmount);
        addressClaimedVoucherPerPeriod[period][msg.sender] = true;

        emit VoucherClaimed(msg.sender, voucherAmount);
    }

    /* ========== SETTERS ========== */

    /// @notice sets address of sUSD contract
    /// @param _address sUSD address
    function setsUSD(address _address) external onlyOwner {
        sUSD = IERC20Upgradeable(_address);
        emit SetsUSD(_address);
    }

    /// @notice sets address of OvertimeVoucher contract
    /// @param _address OvertimeVoucher address
    function setOvertimeVoucher(address _address) external onlyOwner {
        overtimeVoucher = OvertimeVoucher(_address);
        emit SetOvertimeVoucher(_address);
    }

    /// @notice setWhitelistedAddresses enables whitelist addresses of given array
    /// @param _whitelistedAddresses array of whitelisted addresses
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function setWhitelistedAddresses(address[] calldata _whitelistedAddresses, bool _flag) public onlyOwner {
        require(_whitelistedAddresses.length > 0, "Whitelisted addresses cannot be empty");
        for (uint i = 0; i < _whitelistedAddresses.length; i++) {
            if (whitelistedAddressesPerPeriod[period][_whitelistedAddresses[i]] != _flag) {
                whitelistedAddressesPerPeriod[period][_whitelistedAddresses[i]] = _flag;
                emit WhitelistChanged(_whitelistedAddresses[i], period, _flag);
            }
        }
    }

    /// @notice sets amount in voucher to be claimed/minted
    /// @param _voucherAmount sUSD amount
    function setVoucherAmount(uint _voucherAmount) external onlyOwner {
        voucherAmount = _voucherAmount;
        emit VoucherAmountChanged(_voucherAmount);
    }

    /// @notice sets timestamp until claiming is open
    /// @param _periodEnd new timestamp
    /// @param _startNextPeriod extend current period if false, start next period if true
    function setPeriodEndTimestamp(uint _periodEnd, bool _startNextPeriod) external onlyOwner {
        require(_periodEnd > periodEnd[period], "Invalid timestamp");
        if (_startNextPeriod) {
            period += 1;
        }

        periodEnd[period] = _periodEnd;

        emit PeriodEndTimestampChanged(_periodEnd);
    }

    /* ========== VIEWS ========== */

    /// @notice checks if address is whitelisted
    /// @param _address address to be checked
    /// @return bool
    function isWhitelistedAddress(address _address) public view returns (bool) {
        return whitelistedAddressesPerPeriod[period][_address];
    }

    /// @notice checks if current claiming period is closed
    /// @return bool
    function claimingPeriodEnded() public view returns (bool) {
        return block.timestamp >= periodEnd[period];
    }

    /* ========== MODIFIERS ========== */

    modifier canClaim() {
        require(!claimingPeriodEnded(), "Claiming period ended");
        require(isWhitelistedAddress(msg.sender), "Invalid address");
        require(!addressClaimedVoucherPerPeriod[period][msg.sender], "Address has already claimed voucher");

        require(sUSD.balanceOf(address(this)) >= voucherAmount, "Not enough sUSD in the contract");
        _;
    }

    /* ========== EVENTS ========== */

    event WhitelistChanged(address _address, uint period, bool _flag);
    event SetsUSD(address _address);
    event SetOvertimeVoucher(address _address);
    event VoucherAmountChanged(uint _amount);
    event PeriodEndTimestampChanged(uint _timestamp);
    event VoucherClaimed(address _address, uint _amount);
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

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);

    function exerciseWithAmount(address claimant, uint amount) external;
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
pragma solidity ^0.8.0;

// interfaces
import "./ParlayMarket.sol";
import "../../interfaces/IParlayMarketsAMM.sol";
import "../../interfaces/ISportsAMM.sol";
import "../../interfaces/IParlayMarketData.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/IStakingThales.sol";
import "../../interfaces/IReferrals.sol";
import "../../interfaces/ICurveSUSD.sol";
import "../../interfaces/ITherundownConsumer.sol";

contract ParlayVerifier {
    uint private constant ONE = 1e18;

    uint private constant TAG_F1 = 9445;
    uint private constant TAG_MOTOGP = 9497;
    uint private constant TAG_NUMBER_SPREAD = 10001;
    uint private constant TAG_NUMBER_TOTAL = 10002;
    uint private constant DOUBLE_CHANCE_TAG = 10003;

    struct InitialQuoteParameters {
        address[] sportMarkets;
        uint[] positions;
        uint totalSUSDToPay;
        uint parlaySize;
        uint defaultONE;
        uint sgpFee;
        ISportsAMM sportsAMM;
        address parlayAMM;
    }

    struct FinalQuoteParameters {
        address[] sportMarkets;
        uint[] positions;
        uint[] buyQuoteAmounts;
        ISportsAMM sportsAmm;
        uint sUSDAfterFees;
        uint defaultONE;
        uint sgpFee;
    }

    struct VerifyMarket {
        address[] sportMarkets;
        ISportsAMM sportsAMM;
        address parlayAMM;
    }

    struct CachedMarket {
        bytes32 gameId;
        uint gameCounter;
        uint tag1;
        uint tag2;
    }

    // ISportsAMM sportsAmm;

    function _verifyMarkets(VerifyMarket memory params)
        internal
        view
        returns (
            // address[] memory _sportMarkets,
            // uint[] memory _positions,
            // uint _totalSUSDToPay,
            // ISportsAMM _sportsAMM,
            // address _parlayAMM
            bool eligible,
            uint sgpFee
        )
    {
        eligible = true;
        ITherundownConsumer consumer = ITherundownConsumer(params.sportsAMM.theRundownConsumer());
        // bytes32[] memory cachedTeams = new bytes32[](_sportMarkets.length * 2);
        CachedMarket[] memory cachedTeams = new CachedMarket[](params.sportMarkets.length * 2);
        uint lastCachedIdx = 0;
        bytes32 gameIdHome;
        bytes32 gameIdAway;
        uint tag1;
        uint tag2;
        uint motoCounter = 0;
        for (uint i = 0; i < params.sportMarkets.length; i++) {
            address sportMarket = params.sportMarkets[i];
            (gameIdHome, gameIdAway) = _getGameIds(consumer, sportMarket);
            tag1 = ISportPositionalMarket(sportMarket).tags(0);
            tag2 = consumer.isChildMarket(sportMarket) ? ISportPositionalMarket(sportMarket).tags(1) : 0;
            motoCounter = (tag1 == TAG_F1 || tag1 == TAG_MOTOGP) ? ++motoCounter : motoCounter;
            require(motoCounter <= 1, "2xMotosport");
            // check if game IDs already exist
            for (uint j = 0; j < lastCachedIdx; j++) {
                if (
                    (cachedTeams[j].gameId == gameIdHome ||
                        (j > 1 && cachedTeams[j].gameId == gameIdAway && cachedTeams[j - 1].gameId != gameIdHome)) &&
                    cachedTeams[j].tag1 == tag1
                ) {
                    uint feeToApply = IParlayMarketsAMM(params.parlayAMM).getSgpFeePerCombination(
                        tag1,
                        tag2,
                        cachedTeams[j].tag2
                    );
                    if (cachedTeams[j].gameCounter > 0 || feeToApply == 0) {
                        revert("SameTeamOnParlay");
                    }
                    cachedTeams[j].gameCounter += 1;

                    sgpFee = sgpFee > 0 ? (sgpFee * feeToApply) / ONE : feeToApply;
                }
            }

            (cachedTeams[lastCachedIdx].tag1, cachedTeams[lastCachedIdx].tag2) = (tag1, tag2);
            cachedTeams[lastCachedIdx++].gameId = gameIdHome;
            (cachedTeams[lastCachedIdx].tag1, cachedTeams[lastCachedIdx].tag2) = (tag1, tag2);
            cachedTeams[lastCachedIdx++].gameId = gameIdAway;
        }
    }

    function _calculateRisk(
        address[] memory _sportMarkets,
        uint _sUSDInRisky,
        address _parlayAMM
    ) internal view returns (bool riskFree) {
        // address[] memory sortedAddresses = new address[](_sportMarkets.length);
        // sortedAddresses = _sort(_sportMarkets);
        require(_checkRisk(_sportMarkets, _sUSDInRisky, _parlayAMM), "RiskPerComb exceeded");
        riskFree = true;
    }

    function calculateInitialQuotesForParlay(InitialQuoteParameters memory params)
        external
        view
        returns (
            uint totalQuote,
            uint totalBuyAmount,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        )
    {
        uint numOfMarkets = params.sportMarkets.length;
        uint inverseSum;
        bool eligible;
        (eligible, params.sgpFee) = _verifyMarkets(VerifyMarket(params.sportMarkets, params.sportsAMM, params.parlayAMM));
        if (eligible && numOfMarkets == params.positions.length && numOfMarkets > 0 && numOfMarkets <= params.parlaySize) {
            finalQuotes = new uint[](numOfMarkets);
            amountsToBuy = new uint[](numOfMarkets);
            uint[] memory marketOdds;
            for (uint i = 0; i < numOfMarkets; i++) {
                if (params.positions[i] > 2) {
                    totalQuote = 0;
                    break;
                }
                marketOdds = params.sportsAMM.getMarketDefaultOdds(params.sportMarkets[i], false);
                if (marketOdds.length == 0) {
                    totalQuote = 0;
                    break;
                }
                finalQuotes[i] = (params.defaultONE * marketOdds[params.positions[i]]);
                totalQuote = totalQuote == 0 ? finalQuotes[i] : (totalQuote * finalQuotes[i]) / ONE;
                skewImpact = skewImpact + finalQuotes[i];
                // use as inverseQuotes
                finalQuotes[i] = ONE - finalQuotes[i];
                inverseSum = inverseSum + finalQuotes[i];
                if (totalQuote == 0) {
                    totalQuote = 0;
                    break;
                }
            }

            if (totalQuote > 0) {
                for (uint i = 0; i < finalQuotes.length; i++) {
                    // use finalQuotes as inverseQuotes in equation
                    // skewImpact is sumOfQuotes
                    // inverseSum is sum of InverseQuotes
                    amountsToBuy[i] =
                        ((ONE * finalQuotes[i] * params.totalSUSDToPay * skewImpact)) /
                        (totalQuote * inverseSum * skewImpact);
                }
                (totalQuote, totalBuyAmount, skewImpact, finalQuotes, amountsToBuy) = calculateFinalQuotes(
                    FinalQuoteParameters(
                        params.sportMarkets,
                        params.positions,
                        amountsToBuy,
                        params.sportsAMM,
                        params.totalSUSDToPay,
                        params.defaultONE,
                        params.sgpFee
                    )
                );
            }
        }
    }

    function calculateFinalQuotes(FinalQuoteParameters memory params)
        internal
        view
        returns (
            uint totalQuote,
            uint totalBuyAmount,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory buyAmountPerMarket
        )
    {
        uint[] memory buyQuoteAmountPerMarket = new uint[](params.sportMarkets.length);
        buyAmountPerMarket = params.buyQuoteAmounts;
        finalQuotes = new uint[](params.sportMarkets.length);
        for (uint i = 0; i < params.sportMarkets.length; i++) {
            totalBuyAmount += params.buyQuoteAmounts[i];
            // buyQuote always calculated with added SportsAMM fees
            buyQuoteAmountPerMarket[i] = (params.defaultONE *
                params.sportsAmm.buyFromAmmQuote(
                    params.sportMarkets[i],
                    obtainSportsAMMPosition(params.positions[i]),
                    params.buyQuoteAmounts[i]
                ));
            if (buyQuoteAmountPerMarket[i] == 0) {
                totalQuote = 0;
                totalBuyAmount = 0;
            }
        }
        for (uint i = 0; i < params.sportMarkets.length; i++) {
            finalQuotes[i] = ((buyQuoteAmountPerMarket[i] * ONE * ONE) / params.buyQuoteAmounts[i]) / ONE;
            totalQuote = (i == 0) ? finalQuotes[i] : (totalQuote * finalQuotes[i]) / ONE;
        }
        if (totalQuote > 0) {
            totalQuote = params.sgpFee > 0 ? ((totalQuote * ONE * ONE) / params.sgpFee) / ONE : totalQuote;
            if (totalQuote < IParlayMarketsAMM(params.sportsAmm.parlayAMM()).maxSupportedOdds()) {
                totalQuote = IParlayMarketsAMM(params.sportsAmm.parlayAMM()).maxSupportedOdds();
            }
            uint expectedPayout = ((params.sUSDAfterFees * ONE * ONE) / totalQuote) / ONE;
            skewImpact = expectedPayout > totalBuyAmount
                ? (((ONE * expectedPayout) - (ONE * totalBuyAmount)) / (totalBuyAmount))
                : (((ONE * totalBuyAmount) - (ONE * expectedPayout)) / (totalBuyAmount));
            buyAmountPerMarket = _applySkewImpactBatch(buyAmountPerMarket, skewImpact, (expectedPayout > totalBuyAmount));
            // finalQuotes = _applySkewImpactBatch(finalQuotes, (ONE*skewImpact/(4*finalQuotes.length))/ONE, (expectedPayout > totalBuyAmount));
            totalBuyAmount = applySkewImpact(totalBuyAmount, skewImpact, (expectedPayout > totalBuyAmount));
            _calculateRisk(params.sportMarkets, (totalBuyAmount - params.sUSDAfterFees), params.sportsAmm.parlayAMM());
        } else {
            totalBuyAmount = 0;
        }
    }

    function applySkewImpact(
        uint _value,
        uint _skewImpact,
        bool _addition
    ) public pure returns (uint newValue) {
        newValue = _addition ? (((ONE + _skewImpact) * _value) / ONE) : (((ONE - _skewImpact) * _value) / ONE);
    }

    function _applySkewImpactBatch(
        uint[] memory _values,
        uint _skewImpact,
        bool _addition
    ) internal pure returns (uint[] memory newValues) {
        newValues = new uint[](_values.length);
        for (uint i = 0; i < _values.length; i++) {
            newValues[i] = applySkewImpact(_values[i], _skewImpact, _addition);
        }
    }

    function obtainSportsAMMPosition(uint _position) public pure returns (ISportsAMM.Position) {
        if (_position == 0) {
            return ISportsAMM.Position.Home;
        } else if (_position == 1) {
            return ISportsAMM.Position.Away;
        }
        return ISportsAMM.Position.Draw;
    }

    function calculateCombinationKey(address[] memory _sportMarkets) public pure returns (bytes32) {
        address[] memory sortedAddresses = new address[](_sportMarkets.length);
        sortedAddresses = _sort(_sportMarkets);
        return keccak256(abi.encodePacked(sortedAddresses));
    }

    function _checkRisk(
        address[] memory _sportMarkets,
        uint _sUSDInRisk,
        address _parlayAMM
    ) internal view returns (bool riskFree) {
        if (_sportMarkets.length > 1 && _sportMarkets.length <= IParlayMarketsAMM(_parlayAMM).parlaySize()) {
            uint riskCombination = IParlayMarketsAMM(_parlayAMM).riskPerPackedGamesCombination(
                calculateCombinationKey(_sportMarkets)
            );
            riskFree = (riskCombination + _sUSDInRisk) <= IParlayMarketsAMM(_parlayAMM).maxAllowedRiskPerCombination();
        }
    }

    function sort(address[] memory data) external pure returns (address[] memory) {
        _quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function _sort(address[] memory data) internal pure returns (address[] memory) {
        _quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function _quickSort(
        address[] memory arr,
        int left,
        int right
    ) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        address pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    function _getGameIds(ITherundownConsumer consumer, address sportMarket)
        internal
        view
        returns (bytes32 home, bytes32 away)
    {
        ITherundownConsumer.GameCreate memory game = consumer.getGameCreatedById(consumer.gameIdPerMarket(sportMarket));

        home = keccak256(abi.encodePacked(game.homeTeam));
        away = keccak256(abi.encodePacked(game.awayTeam));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../OwnedWithInit.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/utils/SafeERC20.sol";

// Internal references
import "../../interfaces/IParlayMarketsAMM.sol";
import "../SportPositions/SportPosition.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ISportPositionalMarketManager.sol";

contract ParlayMarket is OwnedWithInit {
    using SafeERC20 for IERC20;

    uint private constant ONE = 1e18;
    uint private constant ONE_PERCENT = 1e16;
    uint private constant TWELVE_DECIMAL = 1e6;

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }

    struct SportMarkets {
        address sportAddress;
        uint position;
        uint odd;
        uint result;
        bool resolved;
        bool exercised;
        bool hasWon;
        bool isCancelled;
    }

    IParlayMarketsAMM public parlayMarketsAMM;
    address public parlayOwner;

    uint public expiry;
    uint public amount;
    uint public sUSDPaid;
    uint public totalResultQuote;
    uint public numOfSportMarkets;
    uint public numOfResolvedSportMarkets;
    uint public numOfAlreadyExercisedSportMarkets;

    bool public resolved;
    bool public paused;
    bool public parlayAlreadyLost;
    bool public initialized;
    bool public fundsIssued;

    mapping(uint => SportMarkets) public sportMarket;
    mapping(address => uint) private _sportMarketIndex;
    uint private noSkewTotalQuote;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address[] calldata _sportMarkets,
        uint[] calldata _positionPerMarket,
        uint _amount,
        uint _sUSDPaid,
        uint _expiryDuration,
        address _parlayMarketsAMM,
        address _parlayOwner,
        uint _totalQuote,
        uint[] calldata _marketQuotes
    ) external {
        require(!initialized, "Parlay Market already initialized");
        initialized = true;
        initOwner(msg.sender);
        parlayMarketsAMM = IParlayMarketsAMM(_parlayMarketsAMM);
        require(_sportMarkets.length == _positionPerMarket.length, "Lengths not matching");
        numOfSportMarkets = _sportMarkets.length;
        for (uint i = 0; i < numOfSportMarkets; i++) {
            sportMarket[i].sportAddress = _sportMarkets[i];
            sportMarket[i].position = _positionPerMarket[i];
            sportMarket[i].odd = _marketQuotes[i];
            _sportMarketIndex[_sportMarkets[i]] = i + 1;
            noSkewTotalQuote = (i == 0) ? _marketQuotes[i] : (noSkewTotalQuote * _marketQuotes[i]) / ONE;
        }
        amount = _amount;
        expiry = _expiryDuration;
        sUSDPaid = _sUSDPaid;
        parlayOwner = _parlayOwner;
        totalResultQuote = _totalQuote;
    }

    function isAnySportMarketExercisable() external view returns (bool isExercisable, address[] memory exercisableMarkets) {
        exercisableMarkets = new address[](numOfSportMarkets);
        bool exercisable;
        for (uint i = 0; i < numOfSportMarkets; i++) {
            if (!sportMarket[i].exercised) {
                (exercisable, ) = _isWinningSportMarket(sportMarket[i].sportAddress, sportMarket[i].position);
                if (exercisable) {
                    isExercisable = true;
                    exercisableMarkets[i] = sportMarket[i].sportAddress;
                }
            }
        }
    }

    //===================== VIEWS ===========================

    function isAnySportMarketResolved() external view returns (bool isResolved, address[] memory resolvableMarkets) {
        resolvableMarkets = new address[](numOfSportMarkets);
        bool resolvable;
        for (uint i = 0; i < numOfSportMarkets; i++) {
            if (!sportMarket[i].resolved) {
                (, resolvable) = _isWinningSportMarket(sportMarket[i].sportAddress, sportMarket[i].position);
                if (resolvable) {
                    isResolved = true;
                    resolvableMarkets[i] = sportMarket[i].sportAddress;
                }
            }
        }
    }

    function isUserTheWinner() external view returns (bool finalResult) {
        if (resolved) {
            finalResult = !parlayAlreadyLost;
        } else {
            (finalResult, ) = isParlayExercisable();
        }
    }

    function getSportMarketBalances() external view returns (uint[] memory allBalances) {
        allBalances = new uint[](numOfSportMarkets);
        allBalances = _marketPositionsAndBalances();
    }

    function phase() public view returns (Phase) {
        if (resolved) {
            if (resolved && expiry < block.timestamp) {
                return Phase.Expiry;
            } else {
                return Phase.Maturity;
            }
        } else {
            return Phase.Trading;
        }
    }

    function isParlayExercisable() public view returns (bool isExercisable, bool[] memory exercisedOrExercisableMarkets) {
        exercisedOrExercisableMarkets = new bool[](numOfSportMarkets);
        bool alreadyFalse;
        for (uint i = 0; i < numOfSportMarkets; i++) {
            if (sportMarket[i].exercised) {
                exercisedOrExercisableMarkets[i] = true;
            } else if (!sportMarket[i].exercised || !sportMarket[i].resolved) {
                (exercisedOrExercisableMarkets[i], ) = _isWinningSportMarket(
                    sportMarket[i].sportAddress,
                    sportMarket[i].position
                );
            }
            if (exercisedOrExercisableMarkets[i] == false && !alreadyFalse) {
                alreadyFalse = true;
            }
        }
        isExercisable = !alreadyFalse;
    }

    function getNewResolvedAndWinningPositions()
        external
        view
        returns (bool[] memory newResolvedMarkets, bool[] memory newWinningMarkets)
    {
        newResolvedMarkets = new bool[](numOfSportMarkets);
        newWinningMarkets = new bool[](numOfSportMarkets);
        for (uint i = 0; i < numOfSportMarkets; i++) {
            if (!sportMarket[i].exercised || !sportMarket[i].resolved) {
                (bool exercisable, bool isResolved) = _isWinningSportMarket(
                    sportMarket[i].sportAddress,
                    sportMarket[i].position
                );
                if (isResolved) {
                    newResolvedMarkets[i] = true;
                }
                if (exercisable) {
                    newWinningMarkets[i] = true;
                }
            }
        }
    }

    //============================== UPDATE PARAMETERS ===========================

    function setPaused(bool _paused) external onlyAMM {
        require(paused != _paused, "State not changed");
        paused = _paused;
        emit PauseUpdated(_paused);
    }

    //============================== EXERCISE ===================================

    function exerciseWiningSportMarkets() external onlyAMM {
        require(!paused, "Market paused");
        require(
            numOfAlreadyExercisedSportMarkets < numOfSportMarkets && numOfResolvedSportMarkets < numOfSportMarkets,
            "Already exercised all markets"
        );
        for (uint i = 0; i < numOfSportMarkets; i++) {
            _updateSportMarketParameters(sportMarket[i].sportAddress, i);
            if (sportMarket[i].resolved && !sportMarket[i].exercised) {
                _exerciseSpecificSportMarket(sportMarket[i].sportAddress, i);
            }
        }
        if (parlayAlreadyLost && !fundsIssued) {
            uint totalSUSDamount = parlayMarketsAMM.sUSD().balanceOf(address(this));
            if (totalSUSDamount > 0) {
                parlayMarketsAMM.sUSD().transfer(address(parlayMarketsAMM), totalSUSDamount);
            }
            if (numOfResolvedSportMarkets == numOfSportMarkets) {
                fundsIssued = true;
                parlayMarketsAMM.resolveParlay();
            }
        }
    }

    function exerciseSpecificSportMarket(address _sportMarket) external onlyAMM {
        require(_sportMarketIndex[_sportMarket] > 0, "Invalid market");
        require(!paused, "Market paused");
        uint idx = _sportMarketIndex[_sportMarket] - 1;
        _updateSportMarketParameters(_sportMarket, idx);
        if (sportMarket[idx].resolved && !sportMarket[idx].exercised) {
            _exerciseSpecificSportMarket(_sportMarket, idx);
        }
        if (parlayAlreadyLost && !fundsIssued) {
            uint totalSUSDamount = parlayMarketsAMM.sUSD().balanceOf(address(this));
            if (totalSUSDamount > 0) {
                parlayMarketsAMM.sUSD().transfer(address(parlayMarketsAMM), totalSUSDamount);
            }
            if (numOfResolvedSportMarkets == numOfSportMarkets) {
                fundsIssued = true;
                parlayMarketsAMM.resolveParlay();
            }
        }
    }

    //============================== INTERNAL FUNCTIONS ===================================

    function _exerciseSpecificSportMarket(address _sportMarket, uint _idx) internal {
        require(!sportMarket[_idx].exercised, "Exercised");
        require(sportMarket[_idx].resolved, "Unresolved");
        bool exercizable = sportMarket[_idx].resolved &&
            (sportMarket[_idx].hasWon || sportMarket[_idx].isCancelled) &&
            !sportMarket[_idx].exercised
            ? true
            : false;
        if (exercizable) {
            ISportPositionalMarket(_sportMarket).exerciseOptions();
            sportMarket[_idx].exercised = true;
            numOfAlreadyExercisedSportMarkets++;
            if (
                numOfResolvedSportMarkets == numOfSportMarkets &&
                numOfAlreadyExercisedSportMarkets == numOfSportMarkets &&
                !parlayAlreadyLost
            ) {
                uint totalSUSDamount = parlayMarketsAMM.sUSD().balanceOf(address(this));
                uint calculatedAmount = _recalculateAmount();
                _resolve(true);
                if (phase() != Phase.Expiry) {
                    if (calculatedAmount < totalSUSDamount) {
                        parlayMarketsAMM.sUSD().transfer(parlayOwner, calculatedAmount);
                        parlayMarketsAMM.sUSD().transfer(address(parlayMarketsAMM), (totalSUSDamount - calculatedAmount));
                    } else {
                        parlayMarketsAMM.sUSD().transfer(parlayOwner, totalSUSDamount);
                    }
                    fundsIssued = true;
                    parlayMarketsAMM.resolveParlay();
                }
            }
        } else {
            if (!parlayAlreadyLost) {
                _resolve(false);
            }
        }
    }

    function _updateSportMarketParameters(address _sportMarket, uint _idx) internal {
        if (!sportMarket[_idx].resolved) {
            ISportPositionalMarket currentSportMarket = ISportPositionalMarket(_sportMarket);
            uint result = uint(currentSportMarket.result());
            bool isResolved = currentSportMarket.resolved();
            if (isResolved) {
                numOfResolvedSportMarkets = numOfResolvedSportMarkets + 1;
                sportMarket[_idx].resolved = isResolved;
                sportMarket[_idx].result = result;
                sportMarket[_idx].hasWon = result == (sportMarket[_idx].position + 1);
                if (result == 0) {
                    (totalResultQuote, noSkewTotalQuote) = _getCancellQuotesForMarketIndex(_idx);
                    sportMarket[_idx].isCancelled = true;
                }
            }
        }
    }

    function _marketPositionsAndBalances() internal view returns (uint[] memory balances) {
        uint[] memory allBalancesPerMarket = new uint[](3);
        balances = new uint[](numOfSportMarkets);
        for (uint i = 0; i < numOfSportMarkets; i++) {
            (allBalancesPerMarket[0], allBalancesPerMarket[1], allBalancesPerMarket[2]) = ISportPositionalMarket(
                sportMarket[i].sportAddress
            ).balancesOf(address(this));
            balances[i] = allBalancesPerMarket[sportMarket[i].position];
        }
    }

    function _recalculateAmount() internal view returns (uint recalculated) {
        recalculated = ((sUSDPaid * ONE * ONE) / totalResultQuote) / ONE;
    }

    function _resolve(bool _userWon) internal {
        parlayAlreadyLost = !_userWon;
        resolved = true;
        parlayMarketsAMM.triggerResolvedEvent(parlayOwner, _userWon);
        emit Resolved(_userWon);
    }

    function _isWinningSportMarket(address _sportMarket, uint _userPosition)
        internal
        view
        returns (bool isWinning, bool isResolved)
    {
        ISportPositionalMarket currentSportMarket = ISportPositionalMarket(_sportMarket);
        if (currentSportMarket.resolved()) {
            isResolved = true;
        }
        if (
            isResolved &&
            (uint(currentSportMarket.result()) == (_userPosition + 1) ||
                currentSportMarket.result() == ISportPositionalMarket.Side.Cancelled)
        ) {
            isWinning = true;
        }
    }

    function _getCancellQuotesForMarketIndex(uint _index) internal view returns (uint discountedQuote, uint newNoSkewQuote) {
        newNoSkewQuote = ((noSkewTotalQuote * ONE * ONE) / sportMarket[_index].odd) / ONE;
        discountedQuote =
            totalResultQuote +
            (((ONE - totalResultQuote) * (newNoSkewQuote - noSkewTotalQuote)) / (ONE - noSkewTotalQuote));
    }

    //============================== ON EXPIRY FUNCTIONS ===================================

    function withdrawCollateral(address recipient) external onlyAMM {
        parlayMarketsAMM.sUSD().transfer(recipient, parlayMarketsAMM.sUSD().balanceOf(address(this)));
    }

    function expire(address payable beneficiary) external onlyAMM {
        require(phase() == Phase.Expiry, "Ticket Expired");
        emit Expired(beneficiary);
        _selfDestruct(beneficiary);
    }

    function _selfDestruct(address payable beneficiary) internal {
        // Transfer the balance rather than the deposit value in case there are any synths left over
        // from direct transfers.
        for (uint i = 0; i < numOfSportMarkets; i++) {
            _updateSportMarketParameters(sportMarket[i].sportAddress, i);
            if (sportMarket[i].resolved && !sportMarket[i].exercised) {
                _exerciseSpecificSportMarket(sportMarket[i].sportAddress, i);
            }
        }
        uint balance = parlayMarketsAMM.sUSD().balanceOf(address(this));
        if (balance != 0) {
            parlayMarketsAMM.sUSD().transfer(beneficiary, balance);
            fundsIssued = true;
        }

        // Destroy the option tokens before destroying the market itself.
        // selfdestruct(beneficiary);
    }

    modifier onlyAMM() {
        require(msg.sender == address(parlayMarketsAMM), "only the AMM may perform these methods");
        _;
    }

    event Resolved(bool isUserTheWinner);
    event Expired(address beneficiary);
    event PauseUpdated(bool _paused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IParlayMarketData {
    /* ========== VIEWS / VARIABLES ========== */
    function hasParlayGamePosition(
        address _parlay,
        address _game,
        uint _position
    ) external view returns (bool containsParlay);

    function addParlayForGamePosition(
        address _game,
        uint _position,
        address _parlayMarket,
        address _parlayOwner
    ) external;

    function removeParlayForGamePosition(
        address _game,
        uint _position,
        address _parlayMarket
    ) external;
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

interface IReferrals {
    function referrals(address) external view returns (address);

    function sportReferrals(address) external view returns (address);

    function setReferrer(address, address) external;
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

pragma solidity ^0.8.0;

contract OwnedWithInit {
    address public owner;
    address public nominatedOwner;

    constructor() {}

    function initOwner(address _owner) internal {
        require(owner == address(0), "Init can only be called when owner is 0");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";

import "../../interfaces/IPosition.sol";

// Libraries
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./SportPositionalMarket.sol";

contract SportPosition is IERC20, IPosition {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;

    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    SportPositionalMarket public market;

    mapping(address => uint) public override balanceOf;
    uint public override totalSupply;

    // The argument order is allowance[owner][spender]
    mapping(address => mapping(address => uint)) private allowances;

    // Enforce a 1 cent minimum amount
    uint internal constant _MINIMUM_AMOUNT = 1e16;

    address public sportsAMM;
    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _sportsAMM
    ) external {
        require(!initialized, "Positional Market already initialized");
        initialized = true;
        name = _name;
        symbol = _symbol;
        market = SportPositionalMarket(msg.sender);
        // add through constructor
        sportsAMM = _sportsAMM;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        if (spender == sportsAMM) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        } else {
            return allowances[owner][spender];
        }
    }

    function _requireMinimumAmount(uint amount) internal pure returns (uint) {
        require(amount >= _MINIMUM_AMOUNT || amount == 0, "Balance < $0.01");
        return amount;
    }

    function mint(address minter, uint amount) external onlyMarket {
        _requireMinimumAmount(amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[minter] = balanceOf[minter].add(amount); // Increment rather than assigning since a transfer may have occurred.

        emit Transfer(address(0), minter, amount);
        emit Issued(minter, amount);
    }

    // This must only be invoked after maturity.
    function exercise(address claimant) external onlyMarket {
        uint balance = balanceOf[claimant];

        if (balance == 0) {
            return;
        }

        balanceOf[claimant] = 0;
        totalSupply = totalSupply.sub(balance);

        emit Transfer(claimant, address(0), balance);
        emit Burned(claimant, balance);
    }

    // This must only be invoked after maturity.
    function exerciseWithAmount(address claimant, uint amount) external override onlyMarket {
        require(amount > 0, "Can not exercise zero amount!");

        require(balanceOf[claimant] >= amount, "Balance must be greather or equal amount that is burned");

        balanceOf[claimant] = balanceOf[claimant] - amount;
        totalSupply = totalSupply.sub(amount);

        emit Transfer(claimant, address(0), amount);
        emit Burned(claimant, amount);
    }

    // This must only be invoked after the exercise window is complete.
    // Note that any options which have not been exercised will linger.
    function expire(address payable beneficiary) external onlyMarket {
        selfdestruct(beneficiary);
    }

    /* ---------- ERC20 Functions ---------- */

    function _transfer(
        address _from,
        address _to,
        uint _value
    ) internal returns (bool success) {
        market.requireUnpaused();
        require(_to != address(0) && _to != address(this), "Invalid address");

        uint fromBalance = balanceOf[_from];
        require(_value <= fromBalance, "Insufficient balance");

        balanceOf[_from] = fromBalance.sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external override returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external override returns (bool success) {
        if (msg.sender != sportsAMM) {
            uint fromAllowance = allowances[_from][msg.sender];
            require(_value <= fromAllowance, "Insufficient allowance");
            allowances[_from][msg.sender] = fromAllowance.sub(_value);
        }
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) external override returns (bool success) {
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function getBalanceOf(address account) external view override returns (uint) {
        return balanceOf[account];
    }

    function getTotalSupply() external view override returns (uint) {
        return totalSupply;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMarket() {
        require(msg.sender == address(market), "Only market allowed");
        _;
    }

    /* ========== EVENTS ========== */

    event Issued(address indexed account, uint value);
    event Burned(address indexed account, uint value);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

// Inheritance
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

// Internal references
import "./SportPosition.sol";
import "./SportPositionalMarket.sol";
import "./SportPositionalMarketFactory.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SportPositionalMarketFactory is Initializable, ProxyOwned {
    /* ========== STATE VARIABLES ========== */
    address public positionalMarketManager;

    address public positionalMarketMastercopy;
    address public positionMastercopy;

    address public sportsAMM;

    struct SportPositionCreationMarketParameters {
        address creator;
        IERC20 _sUSD;
        bytes32 gameId;
        string gameLabel;
        uint[2] times; // [maturity, expiry]
        uint initialMint;
        uint positionCount;
        address theRundownConsumer;
        uint[] tags;
        bool isChild;
        address parentMarket;
        bool isDoubleChance;
    }

    /* ========== INITIALIZER ========== */

    function initialize(address _owner) external initializer {
        setOwner(_owner);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(SportPositionCreationMarketParameters calldata _parameters)
        external
        returns (SportPositionalMarket)
    {
        require(positionalMarketManager == msg.sender, "Only permitted by the manager.");

        SportPositionalMarket pom = SportPositionalMarket(Clones.clone(positionalMarketMastercopy));
        address[] memory positions = new address[](_parameters.positionCount);
        for (uint i = 0; i < _parameters.positionCount; i++) {
            positions[i] = address(SportPosition(Clones.clone(positionMastercopy)));
        }

        pom.initialize(
            SportPositionalMarket.SportPositionalMarketParameters(
                positionalMarketManager,
                _parameters._sUSD,
                _parameters.creator,
                _parameters.gameId,
                _parameters.gameLabel,
                _parameters.times,
                _parameters.initialMint,
                _parameters.theRundownConsumer,
                sportsAMM,
                _parameters.positionCount,
                positions,
                _parameters.tags,
                _parameters.isChild,
                _parameters.parentMarket,
                _parameters.isDoubleChance
            )
        );
        emit MarketCreated(
            address(pom),
            _parameters.gameId,
            _parameters.gameLabel,
            _parameters.times[0],
            _parameters.times[1],
            _parameters.initialMint,
            _parameters.positionCount,
            _parameters.tags,
            _parameters.isChild,
            _parameters.parentMarket
        );
        return pom;
    }

    /* ========== SETTERS ========== */
    function setSportPositionalMarketManager(address _positionalMarketManager) external onlyOwner {
        positionalMarketManager = _positionalMarketManager;
        emit SportPositionalMarketManagerChanged(_positionalMarketManager);
    }

    function setSportPositionalMarketMastercopy(address _positionalMarketMastercopy) external onlyOwner {
        positionalMarketMastercopy = _positionalMarketMastercopy;
        emit SportPositionalMarketMastercopyChanged(_positionalMarketMastercopy);
    }

    function setSportPositionMastercopy(address _positionMastercopy) external onlyOwner {
        positionMastercopy = _positionMastercopy;
        emit SportPositionMastercopyChanged(_positionMastercopy);
    }

    function setSportsAMM(address _sportsAMM) external onlyOwner {
        sportsAMM = _sportsAMM;
        emit SetSportsAMM(_sportsAMM);
    }

    event SportPositionalMarketManagerChanged(address _positionalMarketManager);
    event SportPositionalMarketMastercopyChanged(address _positionalMarketMastercopy);
    event SportPositionMastercopyChanged(address _positionMastercopy);
    event SetSportsAMM(address _sportsAMM);
    event SetLimitOrderProvider(address _limitOrderProvider);
    event MarketCreated(
        address market,
        bytes32 indexed gameId,
        string gameLabel,
        uint maturityDate,
        uint expiryDate,
        uint initialMint,
        uint positionCount,
        uint[] tags,
        bool isChild,
        address parent
    );
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity ^0.8.0;

interface ITherundownConsumerVerifier {
    // view functions
    function isInvalidNames(string memory _teamA, string memory _teamB) external view returns (bool);

    function areTeamsEqual(string memory _teamA, string memory _teamB) external view returns (bool);

    function isSupportedMarketType(string memory _market) external view returns (bool);

    function areOddsArrayInThreshold(
        uint _sportId,
        uint[] memory _currentOddsArray,
        uint[] memory _newOddsArray,
        bool _isTwoPositionalSport
    ) external view returns (bool);

    function areOddsValid(
        bool _isTwoPositionalSport,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external view returns (bool);

    function areSpreadOddsValid(
        int16 spreadHome,
        int24 spreadHomeOdds,
        int16 spreadAway,
        int24 spreadAwayOdds
    ) external view returns (bool);

    function areTotalOddsValid(
        uint24 totalOver,
        int24 totalOverOdds,
        uint24 totalUnder,
        int24 totalUnderOdds
    ) external view returns (bool);

    function isValidOutcomeForGame(bool _isTwoPositionalSport, uint _outcome) external view returns (bool);

    function isValidOutcomeWithResult(
        uint _outcome,
        uint _homeScore,
        uint _awayScore
    ) external view returns (bool);

    function calculateAndNormalizeOdds(int[] memory _americanOdds) external view returns (uint[] memory);

    function getBookmakerIdsBySportId(uint256 _sportId) external view returns (uint256[] memory);

    function getStringIDsFromBytesArrayIDs(bytes32[] memory _ids) external view returns (string[] memory);
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

/// @title Storage for games (created or resolved), calculation for order-making bot processing
/// @author gruja
contract GamesQueue is Initializable, ProxyOwned, ProxyPausable {
    // create games queue
    mapping(uint => bytes32) public gamesCreateQueue;
    mapping(bytes32 => bool) public existingGamesInCreatedQueue;
    uint public firstCreated;
    uint public lastCreated;
    mapping(bytes32 => uint) public gameStartPerGameId;

    // resolve games queue
    bytes32[] public unproccessedGames;
    mapping(bytes32 => uint) public unproccessedGamesIndex;
    mapping(uint => bytes32) public gamesResolvedQueue;
    mapping(bytes32 => bool) public existingGamesInResolvedQueue;
    uint public firstResolved;
    uint public lastResolved;

    address public consumer;
    mapping(address => bool) public whitelistedAddresses;

    /// @notice public initialize proxy method
    /// @param _owner future owner of a contract
    function initialize(address _owner) public initializer {
        setOwner(_owner);
        firstCreated = 1;
        lastCreated = 0;
        firstResolved = 1;
        lastResolved = 0;
    }

    /// @notice putting game in a crated queue and fill up unprocessed games array
    /// @param data id of a game in byte32
    /// @param startTime game start time
    /// @param sportsId id of a sport (Example: NBA = 4 etc.)
    function enqueueGamesCreated(
        bytes32 data,
        uint startTime,
        uint sportsId
    ) public canExecuteFunction {
        lastCreated += 1;
        gamesCreateQueue[lastCreated] = data;

        existingGamesInCreatedQueue[data] = true;
        gameStartPerGameId[data] = startTime;

        emit EnqueueGamesCreated(data, sportsId, lastCreated);
    }

    /// @notice removing first game in a queue from created queue
    /// @return data returns id of a game which is removed
    function dequeueGamesCreated() public canExecuteFunction returns (bytes32 data) {
        require(lastCreated >= firstCreated, "No more elements in a queue");

        data = gamesCreateQueue[firstCreated];

        delete gamesCreateQueue[firstCreated];
        firstCreated += 1;

        emit DequeueGamesCreated(data, firstResolved - 1);
    }

    /// @notice putting game in a resolved queue
    /// @param data id of a game in byte32
    function enqueueGamesResolved(bytes32 data) public canExecuteFunction {
        lastResolved += 1;
        gamesResolvedQueue[lastResolved] = data;
        existingGamesInResolvedQueue[data] = true;

        emit EnqueueGamesResolved(data, lastCreated);
    }

    /// @notice removing first game in a queue from resolved queue
    /// @return data returns id of a game which is removed
    function dequeueGamesResolved() public canExecuteFunction returns (bytes32 data) {
        require(lastResolved >= firstResolved, "No more elements in a queue");

        data = gamesResolvedQueue[firstResolved];

        delete gamesResolvedQueue[firstResolved];
        firstResolved += 1;

        emit DequeueGamesResolved(data, firstResolved - 1);
    }

    /// @notice update a game start date
    /// @param _gameId gameId which start date is updated
    /// @param _date date
    function updateGameStartDate(bytes32 _gameId, uint _date) public canExecuteFunction {
        require(_date > block.timestamp, "Date must be in future");
        require(gameStartPerGameId[_gameId] != 0, "Game not existing");
        gameStartPerGameId[_gameId] = _date;
        emit NewStartDateOnGame(_gameId, _date);
    }

    /// @notice sets the consumer contract address, which only owner can execute
    /// @param _consumer address of a consumer contract
    function setConsumerAddress(address _consumer) external onlyOwner {
        require(_consumer != address(0), "Invalid address");
        consumer = _consumer;
        emit NewConsumerAddress(_consumer);
    }

    /// @notice adding/removing whitelist address depending on a flag
    /// @param _whitelistAddress address that needed to be whitelisted/ ore removed from WL
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function addToWhitelist(address _whitelistAddress, bool _flag) external onlyOwner {
        require(_whitelistAddress != address(0) && whitelistedAddresses[_whitelistAddress] != _flag, "Invalid");
        whitelistedAddresses[_whitelistAddress] = _flag;
        emit AddedIntoWhitelist(_whitelistAddress, _flag);
    }

    modifier canExecuteFunction() {
        require(msg.sender == consumer || whitelistedAddresses[msg.sender], "Only consumer or whitelisted address");
        _;
    }

    event EnqueueGamesCreated(bytes32 _gameId, uint _sportId, uint _index);
    event EnqueueGamesResolved(bytes32 _gameId, uint _index);
    event DequeueGamesCreated(bytes32 _gameId, uint _index);
    event DequeueGamesResolved(bytes32 _gameId, uint _index);
    event NewConsumerAddress(address _consumer);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event NewStartDateOnGame(bytes32 _gameId, uint _date);
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

import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-4.4.1/utils/Counters.sol";
import "@openzeppelin/contracts-4.4.1/access/Ownable.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/ISportsAMM.sol";
import "../../interfaces/IParlayMarketsAMM.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/IPosition.sol";

contract OvertimeVoucher is ERC721URIStorage, Ownable {
    /* ========== LIBRARIES ========== */

    using Counters for Counters.Counter;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    Counters.Counter private _tokenIds;

    string public _name = "Overtime Voucher";
    string public _symbol = "OVER";
    bool public paused = false;
    string public tokenURIFive;
    string public tokenURITen;
    string public tokenURITwenty;
    string public tokenURIFifty;
    string public tokenURIHundred;
    string public tokenURITwoHundred;
    string public tokenURIFiveHundred;
    string public tokenURIThousand;

    ISportsAMM public sportsAMM;
    IParlayMarketsAMM public parlayAMM;

    uint public multiplier;

    IERC20 public sUSD;
    mapping(uint => uint) public amountInVoucher;

    /* ========== CONSTANTS ========== */
    uint private constant ONE = 1;
    uint private constant FIVE = 5;
    uint private constant TEN = 10;
    uint private constant TWENTY = 20;
    uint private constant FIFTY = 50;
    uint private constant HUNDRED = 100;
    uint private constant TWO_HUNDRED = 200;
    uint private constant FIVE_HUNDRED = 500;
    uint private constant THOUSAND = 1000;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _sUSD,
        string memory _tokenURIFive,
        string memory _tokenURITen,
        string memory _tokenURITwenty,
        string memory _tokenURIFifty,
        string memory _tokenURIHundred,
        string memory _tokenURITwoHundred,
        string memory _tokenURIFiveHundred,
        string memory _tokenURIThousand,
        address _sportsamm,
        address _parlayAMM
    ) ERC721(_name, _symbol) {
        sUSD = IERC20(_sUSD);
        tokenURIFive = _tokenURIFive;
        tokenURITen = _tokenURITen;
        tokenURITwenty = _tokenURITwenty;
        tokenURIFifty = _tokenURIFifty;
        tokenURIHundred = _tokenURIHundred;
        tokenURITwoHundred = _tokenURITwoHundred;
        tokenURIFiveHundred = _tokenURIFiveHundred;
        tokenURIThousand = _tokenURIThousand;
        sportsAMM = ISportsAMM(_sportsamm);
        sUSD.approve(_sportsamm, type(uint256).max);
        parlayAMM = IParlayMarketsAMM(_parlayAMM);
        sUSD.approve(_parlayAMM, type(uint256).max);
    }

    /* ========== TRV ========== */

    function mintBatch(address[] calldata recipients, uint amount) external returns (uint[] memory newItemId) {
        require(!paused, "Cant mint while paused");

        require(_checkAmount(amount), "Invalid amount");

        sUSD.safeTransferFrom(msg.sender, address(this), (recipients.length * amount));
        newItemId = new uint[](recipients.length);
        for (uint i = 0; i < recipients.length; i++) {
            _tokenIds.increment();
            newItemId[i] = _tokenIds.current();
            _mint(recipients[i], newItemId[i]);
            _setTokenURI(newItemId[i], _retrieveTokenURI(amount));
            amountInVoucher[newItemId[i]] = amount;
        }
    }

    function mint(address recipient, uint amount) external returns (uint newItemId) {
        require(!paused, "Cant mint while paused");

        require(_checkAmount(amount), "Invalid amount");

        sUSD.safeTransferFrom(msg.sender, address(this), amount);

        _tokenIds.increment();

        newItemId = _tokenIds.current();

        _mint(recipient, newItemId);

        _setTokenURI(newItemId, _retrieveTokenURI(amount));

        amountInVoucher[newItemId] = amount;
    }

    function buyFromAMMWithVoucher(
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint tokenId
    ) external {
        require(!paused, "Cant buy while paused");
        require(ERC721.ownerOf(tokenId) == msg.sender, "You are not the voucher owner!");

        uint quote = sportsAMM.buyFromAmmQuote(market, position, amount);
        require(quote < amountInVoucher[tokenId], "Insufficient amount in voucher");

        sportsAMM.buyFromAMM(market, position, amount, quote, 0);
        amountInVoucher[tokenId] = amountInVoucher[tokenId] - quote;

        (IPosition home, IPosition away, IPosition draw) = ISportPositionalMarket(market).getOptions();
        IPosition target = position == ISportsAMM.Position.Home ? home : position == ISportsAMM.Position.Away ? away : draw;

        IERC20(address(target)).safeTransfer(msg.sender, amount);

        //if less than 1 sUSD, transfer the rest to the owner and burn
        if (amountInVoucher[tokenId] < multiplier) {
            sUSD.safeTransfer(address(msg.sender), amountInVoucher[tokenId]);
            super._burn(tokenId);
        }
        emit BoughtFromAmmWithVoucher(msg.sender, market, position, amount, quote, address(sUSD), address(target));
    }

    function buyFromParlayAMMWithVoucher(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        uint tokenId
    ) external {
        require(!paused, "Cant buy while paused");
        require(ERC721.ownerOf(tokenId) == msg.sender, "You are not the voucher owner!");

        require(_sUSDPaid <= amountInVoucher[tokenId], "Insufficient amount in voucher");

        parlayAMM.buyFromParlay(_sportMarkets, _positions, _sUSDPaid, _additionalSlippage, _expectedPayout, msg.sender);
        amountInVoucher[tokenId] = amountInVoucher[tokenId] - _sUSDPaid;

        //if less than 1 sUSD, transfer the rest to the owner and burn
        if (amountInVoucher[tokenId] < multiplier) {
            sUSD.safeTransfer(address(msg.sender), amountInVoucher[tokenId]);
            super._burn(tokenId);
        }
        emit BoughtFromParlayWithVoucher(msg.sender, _sportMarkets, _positions, _sUSDPaid, _expectedPayout, address(sUSD));
    }

    /* ========== VIEW ========== */

    /* ========== INTERNALS ========== */

    function _transformConstant(uint value) internal view returns (uint) {
        return value * multiplier;
    }

    function _checkAmount(uint amount) internal view returns (bool) {
        return
            amount == _transformConstant(FIVE) ||
            amount == _transformConstant(TEN) ||
            amount == _transformConstant(TWENTY) ||
            amount == _transformConstant(FIFTY) ||
            amount == _transformConstant(HUNDRED) ||
            amount == _transformConstant(TWO_HUNDRED) ||
            amount == _transformConstant(FIVE_HUNDRED) ||
            amount == _transformConstant(THOUSAND);
    }

    function _retrieveTokenURI(uint amount) internal view returns (string memory) {
        return
            amount == _transformConstant(FIVE) ? tokenURIFive : amount == _transformConstant(TEN)
                ? tokenURITen
                : amount == _transformConstant(TWENTY)
                ? tokenURITwenty
                : amount == _transformConstant(FIFTY)
                ? tokenURIFifty
                : amount == _transformConstant(HUNDRED)
                ? tokenURIHundred
                : amount == _transformConstant(TWO_HUNDRED)
                ? tokenURITwoHundred
                : amount == _transformConstant(FIVE_HUNDRED)
                ? tokenURIFiveHundred
                : tokenURIThousand;
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    /// @notice Retrieve sUSD from the contract
    /// @param account whom to send the sUSD
    /// @param amount how much sUSD to retrieve
    function retrieveSUSDAmount(address payable account, uint amount) external onlyOwner {
        sUSD.safeTransfer(account, amount);
    }

    // function burnToken(uint _tokenId, address _recepient) external onlyOwner {
    //     require(amountInVoucher[_tokenId] > 0, "Amount is zero");
    //     if(_recepient != address(0)) {
    //         sUSD.safeTransfer(_recepient, amountInVoucher[_tokenId]);
    //     }
    //     super._burn(_tokenId);
    // }

    function setTokenUris(
        string memory _tokenURIFive,
        string memory _tokenURITen,
        string memory _tokenURITwenty,
        string memory _tokenURIFifty,
        string memory _tokenURIHundred,
        string memory _tokenURITwoHundred,
        string memory _tokenURIFiveHundred,
        string memory _tokenURIThousand
    ) external onlyOwner {
        tokenURIFive = _tokenURIFive;
        tokenURITen = _tokenURITen;
        tokenURITwenty = _tokenURITwenty;
        tokenURIFifty = _tokenURIFifty;
        tokenURIHundred = _tokenURIHundred;
        tokenURITwoHundred = _tokenURITwoHundred;
        tokenURIFiveHundred = _tokenURIFiveHundred;
        tokenURIThousand = _tokenURIThousand;
    }

    function setPause(bool _state) external onlyOwner {
        paused = _state;
        emit Paused(_state);
    }

    function setParlayAMM(address _parlayAMM) external onlyOwner {
        if (address(_parlayAMM) != address(0)) {
            sUSD.approve(address(sportsAMM), 0);
        }
        parlayAMM = IParlayMarketsAMM(_parlayAMM);
        sUSD.approve(_parlayAMM, type(uint256).max);
        emit NewParlayAMM(_parlayAMM);
    }

    function setSportsAMM(address _sportsAMM) external onlyOwner {
        if (address(_sportsAMM) != address(0)) {
            sUSD.approve(address(sportsAMM), 0);
        }
        sportsAMM = ISportsAMM(_sportsAMM);
        sUSD.approve(_sportsAMM, type(uint256).max);
        emit NewSportsAMM(_sportsAMM);
    }

    function setMultiplier(uint _multiplier) external onlyOwner {
        multiplier = _multiplier;
        emit MultiplierChanged(multiplier);
    }

    /* ========== EVENTS ========== */

    event BoughtFromAmmWithVoucher(
        address buyer,
        address market,
        ISportsAMM.Position position,
        uint amount,
        uint sUSDPaid,
        address susd,
        address asset
    );
    event BoughtFromParlayWithVoucher(
        address buyer,
        address[] _sportMarkets,
        uint[] _positions,
        uint _sUSDPaid,
        uint _expectedPayout,
        address susd
    );
    event NewTokenUri(string _tokenURI);
    event NewSportsAMM(address _sportsAMM);
    event NewParlayAMM(address _parlayAMM);
    event Paused(bool _state);
    event MultiplierChanged(uint multiplier);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
interface IERC165 {
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