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

import { LibDiamond } from "./LibDiamond.sol";
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
    uint16 muonAppId;
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
    mapping(address => uint256[]) _openRequestForQuotesList;
    // Positions
    mapping(uint256 => Position) _allPositionsMap;
    uint256 _allPositionsLength;
    mapping(address => uint256[]) _openPositionsIsolatedList;
    mapping(address => uint256[]) _openPositionsCrossList;
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
    bytes32 public constant APP_STORAGE_POSITION = keccak256("diamond.standard.app.storage");

    function diamondStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsOwnerOrContract() internal view {
        require(
            msg.sender == diamondStorage().contractOwner || msg.sender == address(this),
            "LibDiamond: Must be contract or owner"
        );
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
                .facetAddressAndSelectorPosition[selector];
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(0),
                "LibDiamondCut: Can't remove function that doesn't exist"
            );
            // can't remove immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(this),
                "LibDiamondCut: Can't remove immutable function."
            );
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition
                    .selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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