// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, Position, Fill } from "../../libraries/LibAppStorage.sol";
import { SchnorrSign } from "../../interfaces/IMuonV03.sol";
import { LibOracle, PositionPrice } from "../../libraries/LibOracle.sol";
import { LibMaster } from "../../libraries/LibMaster.sol";
import { LibHedgers } from "../../libraries/LibHedgers.sol";
import { Decimal } from "../../libraries/LibDecimal.sol";
import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { C } from "../../C.sol";
import "../../libraries/LibEnums.sol";

contract LiquidationFacet {
    using Decimal for Decimal.D256;

    AppStorage internal s;

    /**
     * @dev Unlike a cross liquidation, we don't check for deficits here.
     *      Counterparties should put limit sell orders at the liquidation price
     *      of the user, in order to mitigate the deficit. Failure to do so
     *      would result in the counterParty paying for the deficit.
     */
    function liquidatePositionIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice,
        bytes calldata reqId,
        uint256 timestamp_,
        SchnorrSign[] calldata sigs
    ) external {
        // Verify oracle signatures
        LibOracle.verifyPositionPriceOrThrow(positionId, bidPrice, askPrice, reqId, timestamp_, sigs);

        // Check if the position should be liquidated
        (bool shouldBeLiquidated, int256 pnlA, ) = LibMaster.positionShouldBeLiquidatedIsolated(
            positionId,
            bidPrice,
            askPrice
        );
        require(shouldBeLiquidated, "Not liquidatable");

        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.ISOLATED, "Position is not isolated");
        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");

        uint256 amount = (position.lockedMargin * 2) + (position.cva * 2) + position.liquidationFee;

        // If partyA is in a loss, then that means he's the one who needs to be liquidated
        if (pnlA < 0) {
            s.ma._marginBalances[position.partyB] += amount;
        } else {
            s.ma._marginBalances[position.partyA] += amount;
        }

        // Reward the liquidator
        s.ma._marginBalances[msg.sender] += position.liquidationFee;

        // Update mappings
        _updatePositionDataIsolated(positionId, LibOracle.createPositionPrice(positionId, bidPrice, askPrice));
    }

    // solhint-disable-next-line code-complexity
    function liquidatePartyCross(
        address party,
        uint256[] calldata positionIds,
        uint256[] calldata bidPrices,
        uint256[] calldata askPrices,
        bytes calldata reqId,
        uint256 timestamp_,
        SchnorrSign[] calldata sigs
    ) external {
        // Verify oracle signatures
        LibOracle.verifyPositionPricesOrThrow(positionIds, bidPrices, askPrices, reqId, timestamp_, sigs);

        // Check if all positionIds are provided by length
        require(positionIds.length == s.ma._openPositionsCrossLength[party], "Invalid positionIds length");

        // Create structs for positionIds and prices
        PositionPrice[] memory positionPrices = LibOracle.createPositionPrices(positionIds, bidPrices, askPrices);

        /**
         * The below checks whether the party should be liquidated. We can do that based
         * on malicious inputs. If malicious then the next `for` loop will revert it.
         */
        (int256 uPnLCross, ) = LibMaster.calculateUPnLCross(positionPrices, party);
        bool shouldBeLiquidated = LibMaster.partyShouldBeLiquidatedCross(party, uPnLCross);
        require(shouldBeLiquidated, "Not liquidatable");

        /**
         * At this point the positionIds can still be malicious in nature. They can be:
         * - tied to a different party
         * - arbitrary positionIds
         * - no longer be valid (e.g. Muon is n-blocks behind)
         *
         * They can NOT:
         * - have a different length than the open positions list, see earlier `require`
         *
         * _calculateRealizedDistribution will catch & revert on any of the above issues.
         */
        uint256 received = 0;
        uint256 owed = 0;
        int256 lastPnL = 0;
        uint256 totalSingleLiquidationFees = 0;
        uint256 totalSingleCVA = 0;

        for (uint256 i = 0; i < positionPrices.length; i++) {
            (
                int256 pnl,
                uint256 r,
                uint256 o,
                uint256 singleLiquidationFee,
                uint256 singleCVA
            ) = _calculateRealizedDistribution(party, positionPrices[i]);
            received += r;
            owed += o;

            if (i != 0) {
                require(pnl <= lastPnL, "PNL must be in descending order");
            }
            lastPnL = pnl;
            totalSingleLiquidationFees += singleLiquidationFee;
            totalSingleCVA += singleCVA;
        }

        require(owed >= received, "Invalid realized distribution");
        uint256 deficit = owed - received;

        if (deficit < totalSingleLiquidationFees) {
            /// @dev See _distributePnLDeficitOne.
            Decimal.D256 memory liquidationFeeRatio = Decimal.ratio(
                totalSingleLiquidationFees - deficit,
                totalSingleLiquidationFees
            );
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitOne(party, positionPrices[i], liquidationFeeRatio, msg.sender);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else if (deficit < totalSingleLiquidationFees + totalSingleCVA) {
            /// @dev See _distributePnLDeficitTwo.
            Decimal.D256 memory cvaRatio = Decimal.ratio(
                totalSingleLiquidationFees + totalSingleCVA - deficit,
                totalSingleCVA
            );
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitTwo(party, positionPrices[i], cvaRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else if (deficit < totalSingleLiquidationFees + totalSingleCVA * 2) {
            /// @dev See _distributePnLDeficitThree.
            Decimal.D256 memory cvaRatio = Decimal.ratio(
                totalSingleLiquidationFees + (totalSingleCVA * 2) - deficit,
                totalSingleCVA
            );
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitThree(party, positionPrices[i], cvaRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else if (deficit < totalSingleLiquidationFees * 2 + totalSingleCVA * 2) {
            /// @dev See _distributePnLDeficitFour.
            Decimal.D256 memory liquidationFeeRatio = Decimal.ratio(
                (totalSingleLiquidationFees * 2) + (totalSingleCVA * 2) - deficit,
                totalSingleLiquidationFees
            );
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitFour(party, positionPrices[i], liquidationFeeRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else {
            /// @dev See _distributePnLDeficitFive.
            // The deficit is too high, winning counterparties will receive a reduced PNL.
            uint256 pendingDeficit = deficit - (totalSingleLiquidationFees * 2) + (totalSingleCVA * 2);
            Decimal.D256 memory pnlRatio = pendingDeficit >= received
                ? Decimal.ratio(0, 1) // Nobody gets ANY pnl.
                : Decimal.ratio(received - pendingDeficit, received);

            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitFive(party, positionPrices[i], pnlRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        }

        // Ultimately, reset the liquidated party his lockedMargin.
        s.ma._lockedMargin[party] = 0;
    }

    function _calculateRealizedDistribution(address party, PositionPrice memory positionPrice)
        private
        view
        returns (
            int256 pnl,
            uint256 received,
            uint256 owed,
            uint256 singleLiquidationFee,
            uint256 singleCVA
        )
    {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");
        require(position.positionType == PositionType.CROSS, "Invalid position type");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        pnl = position.partyA == party ? pnlA : pnlB;

        if (pnl <= 0) {
            received = 0;
            owed = uint256(-pnl);
        } else {
            uint256 amount = uint256(pnl);
            // Counterparty is isolated
            received = amount > position.lockedMargin ? position.lockedMargin : amount;
            owed = 0;
        }

        singleLiquidationFee = position.liquidationFee;
        singleCVA = position.cva;
    }

    function _updatePositionDataIsolated(uint256 positionId, PositionPrice memory positionPrice) private {
        Position memory position = s.ma._allPositionsMap[positionId];

        _updatePositionDataBase(positionId, positionPrice);
        s.ma._openPositionsIsolatedLength[position.partyA]--;
        s.ma._openPositionsIsolatedLength[position.partyB]--;
    }

    function _updatePositionDataCross(uint256 positionId, PositionPrice memory positionPrice) private {
        Position memory position = s.ma._allPositionsMap[positionId];

        _updatePositionDataBase(positionId, positionPrice);
        s.ma._openPositionsCrossLength[position.partyA]--;
        s.ma._openPositionsIsolatedLength[position.partyB]--;
    }

    function _updatePositionDataBase(uint256 positionId, PositionPrice memory positionPrice) private {
        Position storage position = s.ma._allPositionsMap[positionId];

        // Add the Fill
        LibMaster.createFill(
            position.positionId,
            position.side == Side.BUY ? Side.SELL : Side.BUY,
            position.currentBalanceUnits,
            position.side == Side.BUY ? positionPrice.bidPrice : positionPrice.askPrice
        );

        // Update the position state
        position.state = PositionState.LIQUIDATED;
        position.currentBalanceUnits = 0;
        position.mutableTimestamp = block.timestamp;
    }

    /**
     * @notice Deficit < liquidationFeeLiquidatedParty
     *
     * - Deficit is covered by the liquidator, he earns the remainder.
     * - CounterParty gets his CVA back.
     * - CounterParty gets the CVA of the liquidated party.
     * - CounterParty gets his liquidationFee back.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets the entire PnL.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitOne(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory liquidationFeeRatio,
        address liquidator
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = (position.cva * 2) + position.liquidationFee;

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + uint256(-pnl) + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 marginReturned = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            uint256 amount = baseReturnAmount + marginReturned;
            s.ma._marginBalances[counterParty] += amount;
        }

        // Reward the liquidator + protocol
        uint256 liquidationFee = Decimal.mul(liquidationFeeRatio, position.liquidationFee).asUint256();
        uint256 protocolShare = Decimal.mul(C.getProtocolLiquidationShare(), liquidationFee).asUint256();
        s.ma._accountBalances[liquidator] += (liquidationFee - protocolShare);
        s.ma._accountBalances[LibDiamond.contractOwner()] += protocolShare;
    }

    /**
     * @notice Deficit < liquidationFeeLiquidatedParty + CVALiquidatedParty
     *
     * - Deficit is not sufficiently covered by the liquidationFee, liquidator earns nothing.
     * - Deficit is covered by the liquidatedParty's CVA, the counterParty receives the remainder.
     * - CounterParty gets his CVA back.
     * - CounterParty gets his liquidationFee back.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets the entire PnL.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitTwo(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory cvaRatio
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = position.cva +
            Decimal.mul(cvaRatio, position.cva).asUint256() +
            position.liquidationFee;

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + uint256(-pnl) + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 marginReturned = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            uint256 amount = baseReturnAmount + marginReturned;
            s.ma._marginBalances[counterParty] += amount;
        }
    }

    /**
     * @notice Deficit < liquidationFeeLiquidatedParty + CVALiquidatedParty + CVACounterParty
     *
     * - Deficit is not sufficiently covered by the liquidationFee, liquidator earns nothing.
     * - Deficit is not sufficiently covered by the liquidatedParty's CVA.
     * - Deficit is covered by the counterParty's CVA, he receives the remainder.
     * - CounterParty gets his liquidationFee back.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets the entire PnL.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitThree(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory cvaRatio
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = Decimal.mul(cvaRatio, position.cva).asUint256() + position.liquidationFee;

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + uint256(-pnl) + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 marginReturned = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            uint256 amount = baseReturnAmount + marginReturned;
            s.ma._marginBalances[counterParty] += amount;
        }
    }

    /**
     * @notice Deficit < liquidationFeeLiquidatedParty + liquidationFeeCounterParty + CVALiquidatedParty + CVACounterParty
     *
     * - Deficit is not sufficiently covered by the liquidationFee, liquidator earns nothing.
     * - Deficit is not sufficiently covered by the liquidatedParty's CVA.
     * - Deficit is not sufficiently covered by the counterParty's CVA.
     * - Deficit is covered by the counterParty's liquidationFee, he receives the remainder.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets the entire PnL.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitFour(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory liquidationFeeRatio
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = Decimal.mul(liquidationFeeRatio, position.liquidationFee).asUint256();

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + uint256(-pnl) + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 marginReturned = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            uint256 amount = baseReturnAmount + marginReturned;
            s.ma._marginBalances[counterParty] += amount;
        }
    }

    /**
     * @notice Deficit > liquidationFeeLiquidatedParty + liquidationFeeCounterParty + CVALiquidatedParty + CVACounterParty
     *
     * - Deficit is not sufficiently covered by the liquidationFee, liquidator earns nothing.
     * - Deficit is not sufficiently covered by the liquidatedParty's CVA.
     * - Deficit is not sufficiently covered by the counterParty's CVA.
     * - Deficit is not sufficiently covered by the counterParty's liquidationFee.
     * - Deficit is covered by the counterParty's PNL.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets a reduced amount of the PNL back.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitFive(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory pnlRatio
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = Decimal.mul(pnlRatio, uint256(pnl)).asUint256();

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 amount = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            s.ma._marginBalances[counterParty] += amount;
        }
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

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV03 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { SchnorrSign, IMuonV03 } from "../interfaces/IMuonV03.sol";
import { C } from "../C.sol";

struct PositionPrice {
    uint256 positionId;
    uint256 bidPrice;
    uint256 askPrice;
}

library LibOracle {
    using ECDSA for bytes32;

    /**
     * @notice Verify the binding of prices with the positionId
     */
    function verifyPositionPriceOrThrow(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice,
        bytes calldata reqId,
        uint256 timestamp_,
        SchnorrSign[] calldata sigs
    ) internal {
        require(sigs.length >= C.getMinimumRequiredSignatures(), "Insufficient signatures");

        bytes32 hash = keccak256(abi.encodePacked(C.getMuonAppId(), reqId, positionId, bidPrice, askPrice, timestamp_));
        IMuonV03 _muon = IMuonV03(C.getMuon());

        bool verified = _muon.verify(reqId, uint256(hash), sigs);
        require(verified, "Invalid signatures");
    }

    /**
     * @notice Verify the binding of prices with the positionIds
     * @dev The caller defines the positionIds and its order, Muon doesn't perform a check.
     * @dev Prices are valid by expiration, but the positionIds are valid per-block.
     */
    function verifyPositionPricesOrThrow(
        uint256[] memory positionIds,
        uint256[] memory bidPrices,
        uint256[] memory askPrices,
        bytes calldata reqId,
        uint256 timestamp_,
        SchnorrSign[] calldata sigs
    ) internal {
        require(sigs.length >= C.getMinimumRequiredSignatures(), "Insufficient signatures");

        bytes32 hash = keccak256(
            abi.encodePacked(C.getMuonAppId(), reqId, positionIds, bidPrices, askPrices, timestamp_)
        );
        IMuonV03 _muon = IMuonV03(C.getMuon());

        bool verified = _muon.verify(reqId, uint256(hash), sigs);
        require(verified, "Invalid signatures");
    }

    function createPositionPrice(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    ) internal pure returns (PositionPrice memory positionPrice) {
        return PositionPrice(positionId, bidPrice, askPrice);
    }

    function createPositionPrices(
        uint256[] memory positionIds,
        uint256[] memory bidPrices,
        uint256[] memory askPrices
    ) internal pure returns (PositionPrice[] memory positionPrices) {
        require(
            positionPrices.length == bidPrices.length && positionPrices.length == askPrices.length,
            "Invalid position prices"
        );

        positionPrices = new PositionPrice[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            positionPrices[i] = PositionPrice(positionIds[i], bidPrices[i], askPrices[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage, RequestForQuote, Position, Fill } from "../libraries/LibAppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibMarkets } from "../libraries/LibMarkets.sol";
import { PositionPrice } from "../libraries/LibOracle.sol";
import { Decimal } from "../libraries/LibDecimal.sol";
import { C } from "../C.sol";
import "../libraries/LibEnums.sol";

library LibMaster {
    using Decimal for Decimal.D256;

    // --------------------------------//
    //---- INTERNAL WRITE FUNCTIONS ---//
    // --------------------------------//

    function onRequestForQuote(
        address partyA,
        address partyB,
        uint256 marketId,
        PositionType positionType,
        OrderType orderType,
        HedgerMode hedgerMode,
        Side side,
        uint256 usdAmountToSpend,
        uint16 leverage,
        uint256 minExpectedUnits,
        uint256 maxExpectedUnits
    ) internal returns (RequestForQuote memory rfq) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(LibMarkets.isValidMarketId(marketId), "Invalid market");

        uint256 notionalUsd = usdAmountToSpend * leverage;
        uint256 protocolFee = calculateProtocolFeeAmount(notionalUsd);
        uint256 liquidationFee = calculateLiquidationFeeAmount(notionalUsd);
        uint256 cva = calculateCVAAmount(notionalUsd);
        uint256 amount = usdAmountToSpend + protocolFee + liquidationFee + cva;

        require(amount <= s.ma._marginBalances[partyA], "Insufficient margin balance");
        s.ma._marginBalances[partyA] -= amount;
        s.ma._lockedMarginReserved[partyA] += amount;

        // Create the RFQ
        uint256 currentRfqId = s.ma._requestForQuotesLength + 1;
        rfq = RequestForQuote({
            rfqId: currentRfqId,
            state: RequestForQuoteState.ORPHAN,
            positionType: positionType,
            orderType: orderType,
            partyA: partyA,
            partyB: partyB,
            hedgerMode: hedgerMode,
            marketId: marketId,
            side: side,
            notionalUsd: notionalUsd,
            leverageUsed: leverage,
            lockedMargin: usdAmountToSpend,
            protocolFee: protocolFee,
            liquidationFee: liquidationFee,
            cva: cva,
            minExpectedUnits: minExpectedUnits,
            maxExpectedUnits: maxExpectedUnits,
            creationTimestamp: block.timestamp,
            mutableTimestamp: block.timestamp
        });

        s.ma._requestForQuotesMap[currentRfqId] = rfq;
        s.ma._requestForQuotesLength++;
    }

    function onFillOpenMarket(
        address partyB,
        uint256 rfqId,
        uint256 filledAmountUnits,
        uint256 avgPriceUsd
    ) internal returns (Position memory position) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        RequestForQuote storage rfq = s.ma._requestForQuotesMap[rfqId];

        require(
            rfq.state == RequestForQuoteState.ORPHAN || rfq.state == RequestForQuoteState.CANCELATION_REQUESTED,
            "Invalid RFQ state"
        );
        require(rfq.minExpectedUnits <= filledAmountUnits, "Invalid min filled amount");
        require(rfq.maxExpectedUnits >= filledAmountUnits, "Invalid max filled amount");

        // Update the RFQ
        rfq.state = RequestForQuoteState.ACCEPTED;
        rfq.mutableTimestamp = block.timestamp;

        // Create the Position
        uint256 currentPositionId = s.ma._allPositionsLength + 1;
        position = Position({
            positionId: currentPositionId,
            state: PositionState.OPEN,
            positionType: rfq.positionType,
            marketId: rfq.marketId,
            partyA: rfq.partyA,
            partyB: rfq.partyB,
            leverageUsed: rfq.leverageUsed,
            side: rfq.side,
            lockedMargin: rfq.lockedMargin,
            protocolFeePaid: rfq.protocolFee,
            liquidationFee: rfq.liquidationFee,
            cva: rfq.cva,
            currentBalanceUnits: filledAmountUnits,
            initialNotionalUsd: rfq.notionalUsd,
            creationTimestamp: block.timestamp,
            mutableTimestamp: block.timestamp
        });

        // Create the first Fill
        createFill(currentPositionId, rfq.side, filledAmountUnits, avgPriceUsd);

        // Update global mappings
        s.ma._allPositionsMap[currentPositionId] = position;
        s.ma._allPositionsLength++;

        // Transfer partyA's collateral
        uint256 deductableMarginA = rfq.lockedMargin + rfq.protocolFee + rfq.liquidationFee + rfq.cva;
        s.ma._lockedMarginReserved[rfq.partyA] -= deductableMarginA;

        // Transfer partyB's collateral
        uint256 deductableMarginB = rfq.lockedMargin + rfq.liquidationFee + rfq.cva; // hedger doesn't pay protocolFee
        require(deductableMarginB <= s.ma._marginBalances[partyB], "Insufficient margin balance");
        s.ma._marginBalances[partyB] -= deductableMarginB;

        // Distribute the fee paid by partyA
        s.ma._accountBalances[LibDiamond.contractOwner()] += rfq.protocolFee;

        if (rfq.positionType == PositionType.ISOLATED) {
            s.ma._openPositionsIsolatedLength[rfq.partyA]++;
            s.ma._openPositionsIsolatedLength[partyB]++;
        } else {
            s.ma._openPositionsCrossLength[rfq.partyA]++;
            s.ma._openPositionsIsolatedLength[partyB]++;

            // Lock margins
            s.ma._lockedMargin[rfq.partyA] += rfq.lockedMargin;
            s.ma._lockedMargin[partyB] += rfq.lockedMargin;
        }
    }

    function onFillCloseMarket(uint256 positionId, PositionPrice memory positionPrice) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position storage position = s.ma._allPositionsMap[positionId];

        uint256 price = position.side == Side.BUY ? positionPrice.bidPrice : positionPrice.askPrice;

        // Add the Fill
        createFill(positionId, position.side == Side.BUY ? Side.SELL : Side.BUY, position.currentBalanceUnits, price);

        // Calculate the PnL of PartyA
        (int256 pnlA, , ) = _calculateUPnLIsolated(
            position.side,
            position.currentBalanceUnits,
            position.initialNotionalUsd,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Distribute the PnL accordingly
        if (position.positionType == PositionType.ISOLATED) {
            distributePnLIsolated(position.positionId, pnlA);
        } else {
            distributePnLCross(position.positionId, pnlA);
        }

        // Return parties their reserved liquidation fees
        s.ma._marginBalances[position.partyA] += (position.liquidationFee + position.cva);
        s.ma._marginBalances[position.partyB] += (position.liquidationFee + position.cva);

        // Update Position
        position.state = PositionState.CLOSED;
        position.currentBalanceUnits = 0;
        position.mutableTimestamp = block.timestamp;

        // Update mappings
        if (position.positionType == PositionType.ISOLATED) {
            s.ma._openPositionsIsolatedLength[position.partyA]--;
            s.ma._openPositionsIsolatedLength[position.partyB]--;
        } else {
            s.ma._openPositionsCrossLength[position.partyA]--;
            s.ma._openPositionsIsolatedLength[position.partyB]--;
        }
    }

    function distributePnLIsolated(uint256 positionId, int256 pnlA) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.ISOLATED, "Invalid position type");

        /**
         * Winning party receives the PNL.
         * Losing party pays for the PNL using the margin that was locked inside the position.
         */

        if (pnlA >= 0) {
            uint256 amount = uint256(pnlA);
            if (amount > position.lockedMargin) {
                s.ma._marginBalances[position.partyA] += position.lockedMargin * 2;
            } else {
                s.ma._marginBalances[position.partyA] += (position.lockedMargin + amount);
                s.ma._marginBalances[position.partyB] += (position.lockedMargin - amount);
            }
        } else {
            uint256 amount = uint256(-pnlA);
            if (amount > position.lockedMargin) {
                s.ma._marginBalances[position.partyB] += position.lockedMargin * 2;
            } else {
                s.ma._marginBalances[position.partyB] += (position.lockedMargin + amount);
                s.ma._marginBalances[position.partyA] += (position.lockedMargin - amount);
            }
        }
    }

    function distributePnLCross(uint256 positionId, int256 pnlA) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.CROSS, "Invalid position type");

        /**
         * Winning party receives the PNL.
         * If partyA is the losing party: pays for the PNL using his lockedMargin.
         * If partyB is the losing party: pays for the PNL using his margin locked inside the position (he's isolated).
         */
        address partyA = position.partyA;
        address partyB = position.partyB;

        if (pnlA >= 0) {
            /**
             * PartyA will NOT receive his lockedMargin back,
             * he'll have to withdraw it manually. This has to do with the
             * risk of liquidation + the fact that his initially lockedMargin
             * could be greater than what he currently has locked.
             */
            uint256 amount = uint256(pnlA);
            if (amount > position.lockedMargin) {
                s.ma._marginBalances[position.partyA] += position.lockedMargin;
            } else {
                s.ma._marginBalances[position.partyA] += amount;
                s.ma._marginBalances[position.partyB] += (position.lockedMargin - amount);
            }
        } else {
            uint256 amount = uint256(-pnlA);
            if (s.ma._lockedMargin[partyA] < amount) {
                s.ma._marginBalances[partyB] += (s.ma._lockedMargin[partyA] + position.lockedMargin);
                s.ma._lockedMargin[partyA] = 0;
            } else {
                s.ma._marginBalances[partyB] += (amount + position.lockedMargin);
                s.ma._lockedMargin[partyA] -= amount;
            }
        }
    }

    function createFill(
        uint256 positionId,
        Side side,
        uint256 amount,
        uint256 price
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 fillId = s.ma._positionFills[positionId].length;
        Fill memory fill = Fill(fillId, positionId, side, amount, price, block.timestamp);
        s.ma._positionFills[positionId].push(fill);
    }

    // --------------------------------//
    //---- INTERNAL VIEW FUNCTIONS ----//
    // --------------------------------//

    /**
     * @notice Returns the UPnL for a specific position.
     * @dev This is a naive function, inputs can not be trusted. Use cautiously.
     */
    function calculateUPnLIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    ) internal view returns (int256 uPnLA, int256 uPnLB) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];

        (uPnLA, uPnLB, ) = _calculateUPnLIsolated(
            position.side,
            position.currentBalanceUnits,
            position.initialNotionalUsd,
            bidPrice,
            askPrice
        );
    }

    /**
     * @notice Returns the UPnL of a party across all his open positions.
     * @dev This is a naive function, inputs can NOT be trusted. Use cautiously.
     *      Use Muon to verify inputs to prevent expensive computational costs.
     * @dev positionPrices can have an incorrect length.
     * @dev positionPrices can have an arbitrary order.
     * @dev positionPrices can contain forged duplicates.
     */
    function calculateUPnLCross(PositionPrice[] memory positionPrices, address party)
        internal
        view
        returns (int256 uPnLCross, int256 notionalCross)
    {
        (uPnLCross, notionalCross) = _calculateUPnLCross(positionPrices, party);
    }

    function calculateProtocolFeeAmount(uint256 notionalUsd) internal view returns (uint256) {
        return Decimal.from(notionalUsd).mul(C.getProtocolFee()).asUint256();
    }

    function calculateLiquidationFeeAmount(uint256 notionalUsd) internal view returns (uint256) {
        return Decimal.from(notionalUsd).mul(C.getLiquidationFee()).asUint256();
    }

    function calculateCVAAmount(uint256 notionalSize) internal view returns (uint256) {
        return Decimal.from(notionalSize).mul(C.getCVA()).asUint256();
    }

    function calculateCrossMarginHealth(uint256 lockedMargin, int256 uPnLCross)
        internal
        pure
        returns (Decimal.D256 memory ratio)
    {
        if (lockedMargin == 0) {
            return Decimal.ratio(1, 1);
        }

        if (uPnLCross >= 0) {
            return Decimal.ratio(lockedMargin + uint256(uPnLCross), lockedMargin);
        }

        uint256 pnl = uint256(-uPnLCross);
        if (pnl >= lockedMargin) {
            return Decimal.zero();
        }

        ratio = Decimal.ratio(lockedMargin - pnl, lockedMargin);
    }

    function positionShouldBeLiquidatedIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    )
        internal
        view
        returns (
            bool shouldBeLiquidated,
            int256 pnlA,
            int256 pnlB
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.ISOLATED, "Position is not isolated");
        (pnlA, pnlB) = calculateUPnLIsolated(positionId, bidPrice, askPrice);
        shouldBeLiquidated = pnlA <= 0
            ? uint256(pnlB) >= position.lockedMargin
            : uint256(pnlA) >= position.lockedMargin;
    }

    function partyShouldBeLiquidatedCross(address party, int256 uPnLCross) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return calculateCrossMarginHealth(s.ma._lockedMargin[party], uPnLCross).isZero();
    }

    // --------------------------------//
    //----- PRIVATE VIEW FUNCTIONS ----//
    // --------------------------------//

    /**
     * @notice Returns the UPnL for a specific position.
     * @dev This is a naive function, inputs can not be trusted. Use cautiously.
     */
    function _calculateUPnLIsolated(
        Side side,
        uint256 currentBalanceUnits,
        uint256 initialNotionalUsd,
        uint256 bidPrice,
        uint256 askPrice
    )
        private
        pure
        returns (
            int256 uPnLA,
            int256 uPnLB,
            int256 notionalIsolated
        )
    {
        if (currentBalanceUnits == 0) return (0, 0, 0);

        uint256 precision = C.getPrecision();

        if (side == Side.BUY) {
            require(bidPrice != 0, "Oracle bidPrice is invalid");
            notionalIsolated = int256((currentBalanceUnits * bidPrice) / precision);
            uPnLA = notionalIsolated - int256(initialNotionalUsd);
        } else {
            require(askPrice != 0, "Oracle askPrice is invalid");
            notionalIsolated = int256((currentBalanceUnits * askPrice) / precision);
            uPnLA = int256(initialNotionalUsd) - notionalIsolated;
        }

        return (uPnLA, -uPnLA, notionalIsolated);
    }

    /**
     * @notice Returns the UPnL of a party across all his open positions.
     * @dev This is a naive function, inputs can NOT be trusted. Use cautiously.
     * @dev positionPrices can have an incorrect length.
     * @dev positionPrices can have an arbitrary order.
     * @dev positionPrices can contain forged duplicates.
     */
    function _calculateUPnLCross(PositionPrice[] memory positionPrices, address party)
        private
        view
        returns (int256 uPnLCross, int256 notionalCross)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 numOpenPositionsCross = s.ma._openPositionsCrossLength[party];

        if (numOpenPositionsCross == 0) {
            return (0, 0);
        }

        for (uint256 i = 0; i < positionPrices.length; i++) {
            uint256 positionId = positionPrices[i].positionId;
            uint256 bidPrice = positionPrices[i].bidPrice;
            uint256 askPrice = positionPrices[i].askPrice;

            Position memory position = s.ma._allPositionsMap[positionId];
            require(position.partyA == party || position.partyB == party, "PositionId mismatch");

            (int256 _uPnLIsolatedA, int256 _uPnLIsolatedB, int256 _notionalIsolated) = _calculateUPnLIsolated(
                position.side,
                position.currentBalanceUnits,
                position.initialNotionalUsd,
                bidPrice,
                askPrice
            );

            if (position.partyA == party) {
                uPnLCross += _uPnLIsolatedA;
            } else {
                uPnLCross += _uPnLIsolatedB;
            }

            notionalCross += _notionalIsolated;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({ value: 0 });
    }

    function one() internal pure returns (D256 memory) {
        return D256({ value: BASE });
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.mul(b) });
    }

    function div(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.div(b) });
    }

    function pow(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; ++i) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(D256 memory a, D256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
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

import { Decimal } from "./libraries/LibDecimal.sol";
import { AppStorage, LibAppStorage } from "./libraries/LibAppStorage.sol";

library C {
    using Decimal for Decimal.D256;

    uint256 private constant PERCENT_BASE = 1e18;
    uint256 private constant PRECISION = 1e18;

    function getPrecision() internal pure returns (uint256) {
        return PRECISION;
    }

    function getPercentBase() internal pure returns (uint256) {
        return PERCENT_BASE;
    }

    function getCollateral() internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.collateral;
    }

    function getMuon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.muon;
    }

    function getMuonAppId() internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.muonAppId;
    }

    function getMinimumRequiredSignatures() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.minimumRequiredSignatures;
    }

    function getProtocolFee() internal view returns (Decimal.D256 memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return Decimal.ratio(s.constants.protocolFee, PERCENT_BASE);
    }

    function getLiquidationFee() internal view returns (Decimal.D256 memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return Decimal.ratio(s.constants.liquidationFee, PERCENT_BASE);
    }

    function getProtocolLiquidationShare() internal view returns (Decimal.D256 memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return Decimal.ratio(s.constants.protocolLiquidationShare, PERCENT_BASE);
    }

    function getCVA() internal view returns (Decimal.D256 memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return Decimal.ratio(s.constants.cva, PERCENT_BASE);
    }

    function getRequestTimeout() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.requestTimeout;
    }

    function getMaxOpenPositionsCross() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.maxOpenPositionsCross;
    }

    function getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage } from "../libraries/LibAppStorage.sol";

library LibMarkets {
    function isValidMarketId(uint256 marketId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.markets._marketList.length;
        return marketId < length;
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