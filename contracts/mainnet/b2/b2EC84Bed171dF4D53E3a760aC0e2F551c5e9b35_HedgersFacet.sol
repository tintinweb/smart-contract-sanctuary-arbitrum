// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { LibHedgers } from "../libraries/LibHedgers.sol";
import { AppStorage, Hedger } from "../libraries/LibAppStorage.sol";

contract HedgersFacet {
    AppStorage internal s;

    event Enlist(address indexed hedger);
    event UpdatePricingURLs(address indexed hedger, string[] pricingURLs);
    event UpdateMarketsURLs(address indexed hedger, string[] marketsURLs);

    // --------------------------------//
    //----- PUBLIC WRITE FUNCTIONS ----//
    // --------------------------------//

    function enlist(string[] calldata pricingWssURLs, string[] calldata marketsHttpsURLs)
        external
        returns (Hedger memory hedger)
    {
        require(msg.sender != address(0), "Invalid address");
        require(s.hedgers._hedgerMap[msg.sender].addr != msg.sender, "Hedger already exists");

        require(pricingWssURLs.length > 0, "pricingWebsocketURLs must be non-empty");
        require(marketsHttpsURLs.length > 0, "pricingWebsocketURLs must be non-empty");
        mustBeHTTPSOrThrow(marketsHttpsURLs);
        mustBeWSSOrThrow(pricingWssURLs);

        hedger = Hedger(msg.sender, pricingWssURLs, marketsHttpsURLs);
        s.hedgers._hedgerMap[msg.sender] = hedger;
        s.hedgers._hedgerList.push(hedger);

        emit Enlist(msg.sender);
    }

    function updatePricingWssURLs(string[] calldata _pricingWssURLs) external {
        Hedger memory hedger = LibHedgers.getHedgerByAddressOrThrow(msg.sender);

        require(hedger.addr == msg.sender, "Access Denied");
        require(_pricingWssURLs.length > 0, "pricingWssURLs must be non-empty");
        mustBeWSSOrThrow(_pricingWssURLs);

        s.hedgers._hedgerMap[msg.sender].pricingWssURLs = _pricingWssURLs;

        emit UpdatePricingURLs(msg.sender, _pricingWssURLs);
    }

    function updateMarketsHttpsURLs(string[] calldata _marketsHttpsURLs) external {
        Hedger memory hedger = LibHedgers.getHedgerByAddressOrThrow(msg.sender);

        require(hedger.addr == msg.sender, "Access Denied");
        require(_marketsHttpsURLs.length > 0, "marketsHttpsURLs must be non-empty");
        mustBeHTTPSOrThrow(_marketsHttpsURLs);

        s.hedgers._hedgerMap[msg.sender].marketsHttpsURLs = _marketsHttpsURLs;

        emit UpdateMarketsURLs(msg.sender, _marketsHttpsURLs);
    }

    // --------------------------------//
    //----- PUBLIC VIEW FUNCTIONS -----//
    // --------------------------------//

    function getHedgerByAddress(address addr) external view returns (bool success, Hedger memory hedger) {
        hedger = s.hedgers._hedgerMap[addr];
        return hedger.addr == address(0) ? (false, hedger) : (true, hedger);
    }

    function getHedgers() external view returns (Hedger[] memory hedgerList) {
        return s.hedgers._hedgerList;
    }

    function getHedgersLength() external view returns (uint256 length) {
        return s.hedgers._hedgerList.length;
    }

    // --------------------------------//
    //----- PRIVATE VIEW FUNCTIONS ----//
    // --------------------------------//

    function substringASCII(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function mustBeWSSOrThrow(string[] calldata urls) private pure {
        for (uint256 i = 0; i < urls.length; i++) {
            require(compareStrings(substringASCII(urls[i], 0, 6), "wss://"), "websocketURLs must be secure");
        }
    }

    function mustBeHTTPSOrThrow(string[] calldata urls) private pure {
        for (uint256 i = 0; i < urls.length; i++) {
            require(compareStrings(substringASCII(urls[i], 0, 8), "https://"), "httpsURLs must be secure");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage, Hedger } from "../libraries/LibAppStorage.sol";

library LibHedgers {
    function isValidHedger(address partyB) internal view returns (bool, Hedger memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Hedger memory hedger = s.hedgers._hedgerMap[partyB];
        return hedger.addr == address(0) ? (false, hedger) : (true, hedger);
    }

    function getHedgerByAddressOrThrow(address partyB) internal view returns (Hedger memory) {
        (bool isValid, Hedger memory hedger) = isValidHedger(partyB);
        require(isValid, "Hedger is not valid");
        return hedger;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;
import "./LibEnums.sol";

struct Hedger {
    address addr;
    string[] pricingWssURLs;
    string[] marketsHttpsURLs;
}

struct Market {
    uint256 marketId;
    string identifier;
    MarketType marketType;
    TradingSession tradingSession;
    bool active;
    string baseCurrency;
    string quoteCurrency;
    string symbol;
    // TODO: bytes32 muonPriceFeedID;
    // TODO: bytes32 muonFundingRateFeedID;
}

struct RequestForQuote {
    uint256 rfqId;
    RequestForQuoteState state;
    PositionType positionType;
    OrderType orderType;
    address partyA;
    address partyB;
    HedgerMode hedgerMode;
    uint256 marketId;
    Side side;
    uint256 notionalUsd;
    uint16 leverageUsed;
    uint256 lockedMargin;
    uint256 protocolFee;
    uint256 liquidationFee;
    uint256 cva;
    uint256 minExpectedUnits;
    uint256 maxExpectedUnits;
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
}

struct Fill {
    uint256 fillId;
    uint256 positionId;
    Side side;
    uint256 filledAmountUnits;
    uint256 avgPriceUsd;
    uint256 timestamp;
}

struct Position {
    uint256 positionId;
    PositionState state;
    PositionType positionType;
    uint256 marketId;
    address partyA;
    address partyB;
    uint16 leverageUsed;
    Side side;
    uint256 lockedMargin;
    uint256 protocolFeePaid;
    uint256 liquidationFee;
    uint256 cva;
    uint256 currentBalanceUnits;
    uint256 initialNotionalUsd;
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
}

struct Constants {
    address collateral;
    address muon;
    bytes32 muonAppId;
    uint8 minimumRequiredSignatures;
    uint256 protocolFee;
    uint256 liquidationFee;
    uint256 protocolLiquidationShare;
    uint256 cva;
    uint256 requestTimeout;
    uint256 maxOpenPositionsCross;
}

struct HedgersState {
    mapping(address => Hedger) _hedgerMap;
    Hedger[] _hedgerList;
}

struct MarketsState {
    mapping(uint256 => Market) _marketMap;
    Market[] _marketList;
}

struct MAState {
    // Balances
    mapping(address => uint256) _accountBalances;
    mapping(address => uint256) _marginBalances;
    mapping(address => uint256) _lockedMargin;
    mapping(address => uint256) _lockedMarginReserved;
    // RequestForQuotes
    mapping(uint256 => RequestForQuote) _requestForQuotesMap;
    uint256 _requestForQuotesLength;
    // Positions
    mapping(uint256 => Position) _allPositionsMap;
    uint256 _allPositionsLength;
    mapping(address => uint256) _openPositionsIsolatedLength;
    mapping(address => uint256) _openPositionsCrossLength;
    mapping(uint256 => Fill[]) _positionFills;
}

struct AppStorage {
    bool paused;
    uint128 pausedAt;
    uint256 reentrantStatus;
    address ownerCandidate;
    Constants constants;
    HedgersState hedgers;
    MarketsState markets;
    MAState ma;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

enum MarketType {
    FOREX,
    CRYPTO,
    STOCK
}

enum TradingSession {
    _24_7,
    _24_5
}

enum Side {
    BUY,
    SELL
}

enum HedgerMode {
    SINGLE,
    HYBRID,
    AUTO
}

enum OrderType {
    LIMIT,
    MARKET
}

enum PositionType {
    ISOLATED,
    CROSS
}

enum RequestForQuoteState {
    ORPHAN,
    CANCELATION_REQUESTED,
    CANCELED,
    REJECTED,
    ACCEPTED
}

enum PositionState {
    OPEN,
    MARKET_CLOSE_REQUESTED,
    MARKET_CLOSE_CANCELATION_REQUESTED,
    LIMIT_CLOSE_REQUESTED,
    LIMIT_CLOSE_CANCELATION_REQUESTED,
    LIMIT_CLOSE_ACTIVE,
    CLOSED,
    LIQUIDATED
}