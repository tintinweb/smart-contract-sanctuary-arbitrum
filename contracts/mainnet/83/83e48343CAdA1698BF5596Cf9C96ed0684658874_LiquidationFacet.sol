// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, Position } from "../../libraries/LibAppStorage.sol";
import { LibOracle, SchnorrSign, PositionPrice } from "../../libraries/LibOracle.sol";
import { LibMaster } from "../../libraries/LibMaster.sol";
import { Decimal } from "../../libraries/LibDecimal.sol";
import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { C } from "../../C.sol";
import "../../libraries/LibEnums.sol";

contract LiquidationFacet {
    using Decimal for Decimal.D256;

    AppStorage internal s;

    /*------------------------*
     * PUBLIC WRITE FUNCTIONS *
     *------------------------*/

    /**
     * @dev Unlike a cross liquidation, we don't check for major deficits here.
     *      Counterparties should put limit sell orders at the liquidation price
     *      of the user, in order to mitigate the deficit. Failure to do so
     *      would result in the counterParty paying for the deficit.
     * @dev The above describes 'major' deficits. There's always a deficit,
     *      however the CVA aims to cover that.
     * @dev Cross positions are ALLOWED in order to liquidate partyB.
     */
    function liquidatePositionIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) external {
        // Verify oracle signatures
        LibOracle.verifyPositionPriceOrThrow(positionId, bidPrice, askPrice, reqId, sign, gatewaySignature);

        Position memory position = s.ma._allPositionsMap[positionId];

        // Check if the position should be liquidated
        (bool shouldBeLiquidated, int256 uPnLA, ) = LibMaster.positionShouldBeLiquidatedIsolated(
            positionId,
            bidPrice,
            askPrice
        );
        require(shouldBeLiquidated, "Not liquidatable");
        require(
            position.state != PositionState.LIQUIDATED && position.state != PositionState.CLOSED,
            "Position already closed"
        );

        /**
         * -PnL = position.lockedMargin(AorB) + a deficit
         *
         * Note: we're NOT dealing with PnL here for distribution, because
         * the PnL implies that a deficit is possible. However, since this
         * is an isolated liquidation, the (hidden) deficit is covered by
         * the CVA where its remainder (although not calculated) goes to
         * the counterParty.
         *
         * The liquidation takes form through not returning any funds to
         * to the counterParty because it's all strictly Isolated.
         **/
        if (position.positionType == PositionType.ISOLATED) {
            // We are liquidating either PartyA or PartyB.
            uint256 amount = position.lockedMarginA +
                position.lockedMarginB +
                (position.cva * 2) +
                position.liquidationFee;

            // PartyA is in profit, thus we're liquidating PartyB.
            if (uPnLA >= 0) {
                s.ma._marginBalances[position.partyA] += amount;
            } else {
                s.ma._marginBalances[position.partyB] += amount;
            }
        } else {
            // We are liquidating PartyB as Isolated, despite PartyA being Cross.
            require(uPnLA >= 0, "PartyA should be profitable");
            // Amount excludes lockedMarginA, because he already has a claim to that.
            uint256 amount = position.lockedMarginB + (position.cva * 2) + position.liquidationFee;
            // PartyA receives money as CrossLockedMargin, thus improving his health.
            s.ma._crossLockedMargin[position.partyA] += amount;
        }

        // Reward the liquidator + protocol
        uint256 protocolShare = Decimal.mul(C.getProtocolLiquidationShare(), position.liquidationFee).asUint256();
        s.ma._accountBalances[msg.sender] += (position.liquidationFee - protocolShare);
        s.ma._accountBalances[LibDiamond.contractOwner()] += protocolShare;

        // Update mappings
        _updatePositionDataIsolated(position, LibOracle.createPositionPrice(positionId, bidPrice, askPrice));
    }

    function liquidatePartyCross(
        address partyA,
        uint256[] calldata positionIds,
        uint256[] calldata bidPrices,
        uint256[] calldata askPrices,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) external {
        // Verify oracle signatures
        LibOracle.verifyPositionPricesOrThrow(positionIds, bidPrices, askPrices, reqId, sign, gatewaySignature);

        // Check if all positionIds are provided by length
        require(positionIds.length == s.ma._openPositionsCrossLength[partyA], "Invalid positionIds length");

        // Create structs for positionIds and prices
        PositionPrice[] memory positionPrices = LibOracle.createPositionPrices(positionIds, bidPrices, askPrices);

        /**
         * The below checks whether the party should be liquidated. We can do that based
         * on malicious inputs. If malicious then the next `for` loop will revert it regardless.
         */
        int256 uPnLCross = LibMaster.calculateUPnLCross(positionPrices, partyA);
        bool shouldBeLiquidated = LibMaster.partyShouldBeLiquidatedCross(partyA, uPnLCross);
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
        uint256 debit = 0;
        uint256 credit = 0;
        int256 lastPnL = 0;
        uint256 totalSingleLiquidationFees = 0;
        uint256 totalDoubleCVA = 0;

        for (uint256 i = 0; i < positionPrices.length; i++) {
            (
                int256 pnl,
                uint256 _debit,
                uint256 _credit,
                uint256 singleLiquidationFee,
                uint256 doubleCVA
            ) = _calculateRealizedDistribution(partyA, positionPrices[i]);
            debit += _debit;
            credit += _credit;

            if (i != 0) {
                require(pnl <= lastPnL, "PNL must be in descending order");
            }
            lastPnL = pnl;
            totalSingleLiquidationFees += singleLiquidationFee;
            totalDoubleCVA += doubleCVA;
        }

        /**
         * Debit vs. Credit is basically the same as PnLA.
         * If we owe less than what we should receive then
         * technically the party should not be liquidated.
         * */
        require(credit >= debit, "PartyA should have more credit");
        uint256 deficit = credit - debit - s.ma._crossLockedMargin[partyA];

        /**
         * We have a deficit that needs to be covered:
         * 1) Covered by the total CVA of all parties involved.
         * 2) Option 1 isn't sufficient. Covered by the PNL of all profitable PartyB's.
         */
        if (deficit < totalDoubleCVA) {
            Decimal.D256 memory doubleCVARatio = Decimal.ratio(totalDoubleCVA - deficit, totalDoubleCVA);
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitThroughCVA(positionPrices[i], doubleCVARatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else {
            // The deficit is too high, profitable PartyB's will receive a reduced PNL.
            uint256 pendingDeficit = deficit - totalDoubleCVA;
            Decimal.D256 memory creditRatio = pendingDeficit >= credit
                ? Decimal.ratio(0, 1) // Nobody gets ANY pnl, extremely unlikely.
                : Decimal.ratio(credit - pendingDeficit, credit);

            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitThroughCredit(positionPrices[i], creditRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        }

        // Ultimately, reset the liquidated party his lockedMargin.
        s.ma._crossLockedMargin[partyA] = 0;

        // Reward the liquidator + protocol
        uint256 protocolShare = Decimal.mul(C.getProtocolLiquidationShare(), totalSingleLiquidationFees).asUint256();
        s.ma._accountBalances[msg.sender] += (totalSingleLiquidationFees - protocolShare);
        s.ma._accountBalances[LibDiamond.contractOwner()] += protocolShare;
    }

    /*-------------------------*
     * PRIVATE WRITE FUNCTIONS *
     *-------------------------*/

    function _distributePnLDeficitThroughCVA(
        PositionPrice memory positionPrice,
        Decimal.D256 memory doubleCVARatio
    ) private {
        Position memory position = s.ma._allPositionsMap[positionPrice.positionId];

        // Calculate the PnL of PartyA.
        (int256 uPnLA, ) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        uint256 bonusAmount = Decimal.mul(doubleCVARatio, position.cva * 2).asUint256() + position.liquidationFee;

        if (uPnLA >= 0) {
            uint256 pnl = uint256(uPnLA);
            // PartyB gets his lockedMargin back minus the PnL that PartyA has earned.
            uint256 marginAmount = pnl >= position.lockedMarginB
                ? 0 // PartyB should've been liquidated here already.
                : position.lockedMarginB - pnl;
            s.ma._marginBalances[position.partyB] += marginAmount + bonusAmount;
        } else {
            uint256 amount = bonusAmount + uint256(-uPnLA) + position.lockedMarginB;
            s.ma._marginBalances[position.partyB] += amount;
        }
    }

    function _distributePnLDeficitThroughCredit(
        PositionPrice memory positionPrice,
        Decimal.D256 memory creditRatio
    ) private {
        Position memory position = s.ma._allPositionsMap[positionPrice.positionId];

        // Calculate the PnL of PartyA.
        (int256 uPnLA, ) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        if (uPnLA >= 0) {
            uint256 pnl = uint256(uPnLA);
            uint256 marginAmount = pnl >= position.lockedMarginB
                ? 0 // PartyB should've been liquidated here already.
                : position.lockedMarginB - pnl;
            s.ma._marginBalances[position.partyB] += marginAmount + position.liquidationFee;
        } else {
            // PartyB gets a reduced PNL, where -uPnLA == credit.
            uint256 amount = position.lockedMarginB +
                Decimal.mul(creditRatio, uint256(-uPnLA)).asUint256() +
                position.liquidationFee;
            s.ma._marginBalances[position.partyB] += amount;
        }
    }

    function _updatePositionDataIsolated(Position memory position, PositionPrice memory positionPrice) private {
        _updatePositionDataTemplate(position.positionId, positionPrice);
        s.ma._openPositionsIsolatedLength[position.partyA]--;
        s.ma._openPositionsIsolatedLength[position.partyB]--;
    }

    function _updatePositionDataCross(uint256 positionId, PositionPrice memory positionPrice) private {
        Position memory position = s.ma._allPositionsMap[positionId];
        _updatePositionDataTemplate(positionId, positionPrice);
        s.ma._openPositionsCrossLength[position.partyA]--;
        s.ma._openPositionsIsolatedLength[position.partyB]--;
    }

    function _updatePositionDataTemplate(uint256 positionId, PositionPrice memory positionPrice) private {
        Position storage position = s.ma._allPositionsMap[positionId];

        // Emit the Fill
        LibMaster.emitFill(
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

    /*------------------------*
     * PRIVATE VIEW FUNCTIONS *
     *------------------------*/

    /**
     * @dev Calculates the realized distribution for a single position to uncover deficits.
     * @dev Strictly limited to Cross positions.
     * @dev Strictly targetting partyA (the liquidated party).
     */
    function _calculateRealizedDistribution(
        address partyA,
        PositionPrice memory positionPrice
    )
        private
        view
        returns (int256 uPnLA, uint256 debit, uint256 credit, uint256 singleLiquidationFee, uint256 doubleCVA)
    {
        Position memory position = s.ma._allPositionsMap[positionPrice.positionId];

        require(
            position.state != PositionState.LIQUIDATED && position.state != PositionState.CLOSED,
            "Position already closed"
        );
        require(position.partyA == partyA, "Invalid party");
        require(position.positionType == PositionType.CROSS, "Invalid position type");

        // Calculate the PnL of PartyA
        (uPnLA, ) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        /**
         * Note: 'single' implies the half that PartyA locked into
         * the position, which he will now lose.
         *
         * His half + the other half (together 'double') will be:
         * - used for the global deficit (CVA)
         * - used to reward the liquidator (LiquidationFee)
         * - returned to PartyB
         **/
        singleLiquidationFee = position.liquidationFee;
        doubleCVA = position.cva * 2;

        if (uPnLA >= 0) {
            // PartyA receives the PNL.
            uint256 amount = uint256(uPnLA);
            debit = amount >= position.lockedMarginB
                ? position.lockedMarginB // PartyB should've been liquidated here already.
                : amount;
            credit = 0;
        } else {
            // PartyA has to pay PartyB.
            debit = 0;
            credit = uint256(-uPnLA);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;
import "./LibEnums.sol";
import { PublicKey } from "./LibOracle.sol";

struct Hedger {
    address addr;
    string[] pricingWssURLs;
    string[] marketsHttpsURLs;
}

struct Market {
    uint256 marketId;
    string identifier;
    MarketType marketType;
    bool active;
    string baseCurrency;
    string quoteCurrency;
    string symbol;
    bytes32 muonPriceFeedId;
    bytes32 fundingRateId;
}

struct RequestForQuote {
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
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
    uint256 lockedMarginA;
    uint256 protocolFee;
    uint256 liquidationFee;
    uint256 cva;
    uint256 minExpectedUnits;
    uint256 maxExpectedUnits;
    address affiliate;
}

struct Position {
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
    uint256 positionId;
    bytes16 uuid;
    PositionState state;
    PositionType positionType;
    uint256 marketId;
    address partyA;
    address partyB;
    Side side;
    uint256 lockedMarginA;
    uint256 lockedMarginB;
    uint256 protocolFeePaid;
    uint256 liquidationFee;
    uint256 cva;
    uint256 currentBalanceUnits;
    uint256 initialNotionalUsd;
    address affiliate;
}

struct Constants {
    address collateral;
    address muon; // DEPRECATED
    bytes32 muonAppId; // DEPRECATED
    uint8 minimumRequiredSignatures; // DEPRECATED
    uint256 protocolFee;
    uint256 liquidationFee;
    uint256 protocolLiquidationShare;
    uint256 cva;
    uint256 requestTimeout;
    uint256 maxOpenPositionsCross;
    uint256 muonAppIdV2;
    PublicKey muonPublicKey;
    address muonGatewaySigner;
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
    mapping(address => uint256) _crossLockedMargin;
    mapping(address => uint256) _crossLockedMarginReserved;
    // RequestForQuotes
    mapping(uint256 => RequestForQuote) _requestForQuotesMap;
    uint256 _requestForQuotesLength;
    mapping(address => uint256) _crossRequestForQuotesLength;
    // Positions
    mapping(uint256 => Position) _allPositionsMap;
    uint256 _allPositionsLength;
    mapping(address => uint256) _openPositionsIsolatedLength;
    mapping(address => uint256) _openPositionsCrossLength;
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

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../utils/SchnorrSECP256K1Verifier.sol";
import { C } from "../C.sol";

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

struct PublicKey {
    uint256 x;
    uint8 parity;
}

struct PositionPrice {
    uint256 positionId;
    uint256 bidPrice;
    uint256 askPrice;
}

library LibOracle {
    using ECDSA for bytes32;

    /*------------------------*
     * PRIVATE VIEW FUNCTIONS *
     *------------------------*/

    function _getMuonConstants()
        private
        view
        returns (uint256 muonAppId, PublicKey memory muonPublicKey, address muonGatewaySigner)
    {
        return (C.getMuonAppId(), C.getMuonPublicKey(), C.getMuonGatewaySigner());
    }

    function _verifySignature(
        uint256 hash,
        SchnorrSign memory signature,
        PublicKey memory pubKey
    ) private pure returns (bool) {
        return
            SchnorrSECP256K1Verifier.verifySignature(
                pubKey.x,
                pubKey.parity,
                signature.signature,
                hash,
                signature.nonce
            );
    }

    /*-------------------------*
     * INTERNAL VIEW FUNCTIONS *
     *-------------------------*/

    function verifyTSSOrThrow(string calldata data, bytes calldata reqId, SchnorrSign calldata sign) internal view {
        (uint256 muonAppId, PublicKey memory muonPublicKey, ) = _getMuonConstants();

        bytes32 hash = keccak256(abi.encodePacked(muonAppId, reqId, data));
        bool verified = _verifySignature(uint256(hash), sign, muonPublicKey);
        require(verified, "TSS not verified");
    }

    // To get the gatewaySignature, gwSign=true should be passed to the MuonApp.
    function verifyTSSAndGatewayOrThrow(
        bytes32 hash,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) internal view {
        (, PublicKey memory muonPublicKey, address muonGatewaySigner) = _getMuonConstants();

        bool verified = _verifySignature(uint256(hash), sign, muonPublicKey);
        require(verified, "TSS not verified");

        hash = hash.toEthSignedMessageHash();
        address gatewaySigner = hash.recover(gatewaySignature);
        require(gatewaySigner == muonGatewaySigner, "Invalid gateway signer");
    }

    function verifyPositionPriceOrThrow(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) internal view {
        (uint256 muonAppId, , ) = _getMuonConstants();

        bytes32 hash = keccak256(abi.encodePacked(muonAppId, reqId, positionId, bidPrice, askPrice));
        verifyTSSAndGatewayOrThrow(hash, sign, gatewaySignature);
    }

    function verifyPositionPricesOrThrow(
        uint256[] memory positionIds,
        uint256[] memory bidPrices,
        uint256[] memory askPrices,
        bytes calldata reqId,
        SchnorrSign calldata sign,
        bytes calldata gatewaySignature
    ) internal view {
        (uint256 muonAppId, , ) = _getMuonConstants();

        bytes32 hash = keccak256(abi.encodePacked(muonAppId, reqId, positionIds, bidPrices, askPrices));
        verifyTSSAndGatewayOrThrow(hash, sign, gatewaySignature);
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

import { AppStorage, LibAppStorage, RequestForQuote, Position, Market } from "../libraries/LibAppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibMarkets } from "../libraries/LibMarkets.sol";
import { PositionPrice } from "../libraries/LibOracle.sol";
import { Decimal } from "../libraries/LibDecimal.sol";
import { C } from "../C.sol";
import "../libraries/LibEnums.sol";

library LibMaster {
    using Decimal for Decimal.D256;

    event Fill(uint256 indexed positionId, Side side, uint256 amount, uint256 price);

    /*--------------------------*
     * INTERNAL WRITE FUNCTIONS *
     *--------------------------*/

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
        uint256 maxExpectedUnits,
        address affiliate
    ) internal returns (RequestForQuote memory rfq) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // This inherently validates the existence of a market as well.
        require(LibMarkets.isActiveMarket(marketId), "Market not active");

        if (positionType == PositionType.CROSS) {
            uint256 numOpenPositionsCross = s.ma._openPositionsCrossLength[partyA];
            uint256 numOpenRfqsCross = s.ma._crossRequestForQuotesLength[partyA];
            require(
                numOpenPositionsCross + numOpenRfqsCross < C.getMaxOpenPositionsCross(),
                "Max open positions cross reached"
            );
        }

        uint256 notionalUsd = usdAmountToSpend * leverage;
        uint256 protocolFee = calculateProtocolFeeAmount(notionalUsd);
        uint256 liquidationFee = calculateLiquidationFeeAmount(notionalUsd);
        uint256 cva = calculateCVAAmount(notionalUsd);
        uint256 amount = usdAmountToSpend + protocolFee + liquidationFee + cva;

        require(amount <= s.ma._marginBalances[partyA], "Insufficient margin balance");
        s.ma._marginBalances[partyA] -= amount;
        s.ma._crossLockedMarginReserved[partyA] += amount;

        // Create the RFQ
        uint256 currentRfqId = s.ma._requestForQuotesLength + 1;
        rfq = RequestForQuote({
            creationTimestamp: block.timestamp,
            mutableTimestamp: block.timestamp,
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
            lockedMarginA: usdAmountToSpend,
            protocolFee: protocolFee,
            liquidationFee: liquidationFee,
            cva: cva,
            minExpectedUnits: minExpectedUnits,
            maxExpectedUnits: maxExpectedUnits,
            affiliate: affiliate
        });

        s.ma._requestForQuotesMap[currentRfqId] = rfq;
        s.ma._requestForQuotesLength++;

        // Increase the number of active RFQs
        if (positionType == PositionType.CROSS) {
            s.ma._crossRequestForQuotesLength[partyA]++;
        }
    }

    function onFillOpenMarket(
        address partyB,
        uint256 rfqId,
        uint256 filledAmountUnits,
        uint256 avgPriceUsd,
        bytes16 uuid
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

        // TODO: allow hedger to set his own locked margin amount
        uint256 lockedMarginB = rfq.lockedMarginA;

        // Create the Position
        uint256 currentPositionId = s.ma._allPositionsLength + 1;
        position = Position({
            creationTimestamp: block.timestamp,
            mutableTimestamp: block.timestamp,
            positionId: currentPositionId,
            uuid: uuid,
            state: PositionState.OPEN,
            positionType: rfq.positionType,
            marketId: rfq.marketId,
            partyA: rfq.partyA,
            partyB: rfq.partyB,
            side: rfq.side,
            lockedMarginA: rfq.lockedMarginA,
            lockedMarginB: lockedMarginB,
            protocolFeePaid: rfq.protocolFee,
            liquidationFee: rfq.liquidationFee,
            cva: rfq.cva,
            currentBalanceUnits: filledAmountUnits,
            initialNotionalUsd: rfq.notionalUsd,
            affiliate: rfq.affiliate
        });

        // Update global mappings
        s.ma._allPositionsMap[currentPositionId] = position;
        s.ma._allPositionsLength++;

        // Transfer partyA's collateral
        uint256 deductableMarginA = rfq.lockedMarginA + rfq.protocolFee + rfq.liquidationFee + rfq.cva;
        s.ma._crossLockedMarginReserved[rfq.partyA] -= deductableMarginA;

        // Transfer partyB's collateral
        uint256 deductableMarginB = lockedMarginB + rfq.liquidationFee + rfq.cva; // hedger doesn't pay protocolFee
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
            s.ma._crossLockedMargin[rfq.partyA] += rfq.lockedMarginA;
            s.ma._crossLockedMargin[partyB] += lockedMarginB;

            // Decrease the number of active RFQs
            s.ma._crossRequestForQuotesLength[rfq.partyA]--;
        }

        emitFill(currentPositionId, rfq.side, filledAmountUnits, avgPriceUsd);
    }

    function onFillCloseMarket(uint256 positionId, PositionPrice memory positionPrice) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position storage position = s.ma._allPositionsMap[positionId];

        uint256 price = position.side == Side.BUY ? positionPrice.bidPrice : positionPrice.askPrice;

        // Emit the Fill
        emitFill(positionId, position.side == Side.BUY ? Side.SELL : Side.BUY, position.currentBalanceUnits, price);

        // Calculate the PnL of PartyA
        (int256 uPnLA, ) = _calculateUPnLIsolated(
            position.side,
            position.currentBalanceUnits,
            position.initialNotionalUsd,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Distribute the PnL accordingly
        if (position.positionType == PositionType.ISOLATED) {
            distributePnLIsolated(position.positionId, uPnLA);
        } else {
            distributePnLCross(position.positionId, uPnLA);
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

    function distributePnLIsolated(uint256 positionId, int256 uPnLA) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.ISOLATED, "Invalid position type");

        /**
         * Winning party receives the PNL.
         * Losing party pays for the PNL using isolated margin.
         */

        if (uPnLA >= 0) {
            uint256 amount = uint256(uPnLA);
            if (amount >= position.lockedMarginB) {
                // Technically this represents a liquidation.
                s.ma._marginBalances[position.partyA] += (position.lockedMarginA + position.lockedMarginB);
            } else {
                s.ma._marginBalances[position.partyA] += (position.lockedMarginA + amount);
                s.ma._marginBalances[position.partyB] += (position.lockedMarginB - amount);
            }
        } else {
            uint256 amount = uint256(-uPnLA);
            if (amount >= position.lockedMarginA) {
                // Technically this represents a liquidation.
                s.ma._marginBalances[position.partyB] += (position.lockedMarginA + position.lockedMarginB);
            } else {
                s.ma._marginBalances[position.partyB] += (position.lockedMarginB + amount);
                s.ma._marginBalances[position.partyA] += (position.lockedMarginA - amount);
            }
        }
    }

    function distributePnLCross(uint256 positionId, int256 uPnLA) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.CROSS, "Invalid position type");

        /**
         * Winning party receives the PNL.
         * Losing party pays for the PNL using his globally lockedMargin (Cross).
         */
        address partyA = position.partyA;
        address partyB = position.partyB;

        if (uPnLA >= 0) {
            /**
             * PartyA will NOT receive his lockedMargin back,
             * he'll have to withdraw it manually. This has to do with the
             * risk of liquidation + the fact that his initially lockedMargin
             * could be greater than what he currently has locked.
             */
            uint256 amount = uint256(uPnLA);
            if (amount >= position.lockedMarginB) {
                // Technically this represents a liquidation.
                s.ma._marginBalances[position.partyA] += position.lockedMarginB;
                // We don't have to reset the lockedMargin of PartyB because he's Isolated.
            } else {
                s.ma._marginBalances[position.partyA] += amount;
                s.ma._marginBalances[position.partyB] += (position.lockedMarginB - amount);
            }
        } else {
            uint256 amount = uint256(-uPnLA);
            // PartyB is Isolated by nature.
            if (amount >= s.ma._crossLockedMargin[partyA]) {
                // Technically this represents a liquidation.
                s.ma._marginBalances[partyB] += (s.ma._crossLockedMargin[partyA] + position.lockedMarginB);
                s.ma._crossLockedMargin[partyA] = 0;
            } else {
                s.ma._marginBalances[partyB] += (position.lockedMarginB + amount);
                s.ma._crossLockedMargin[partyA] -= amount;
            }
        }
    }

    function emitFill(uint256 positionId, Side side, uint256 amount, uint256 price) internal {
        emit Fill(positionId, side, amount, price);
    }

    /*-------------------------*
     * INTERNAL VIEW FUNCTIONS *
     *-------------------------*/

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

        (uPnLA, uPnLB) = _calculateUPnLIsolated(
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
    function calculateUPnLCross(
        PositionPrice[] memory positionPrices,
        address party
    ) internal view returns (int256 uPnLCross) {
        return _calculateUPnLCross(positionPrices, party);
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

    function calculateCrossMarginHealth(
        address party,
        int256 uPnLCross
    ) internal view returns (Decimal.D256 memory ratio) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lockedMargin = s.ma._crossLockedMargin[party];
        uint256 openPositions = s.ma._openPositionsCrossLength[party];

        if (lockedMargin == 0 && openPositions == 0) {
            return Decimal.ratio(1, 1);
        } else if (lockedMargin == 0) {
            return Decimal.zero();
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
    ) internal view returns (bool shouldBeLiquidated, int256 uPnLA, int256 uPnLB) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];

        (uPnLA, uPnLB) = calculateUPnLIsolated(positionId, bidPrice, askPrice);
        shouldBeLiquidated = uPnLA <= 0
            ? uint256(uPnLB) >= position.lockedMarginA
            : uint256(uPnLA) >= position.lockedMarginB;
    }

    function partyShouldBeLiquidatedCross(address party, int256 uPnLCross) internal view returns (bool) {
        Decimal.D256 memory ratio = calculateCrossMarginHealth(party, uPnLCross);
        return ratio.isZero();
    }

    /*------------------------*
     * PRIVATE VIEW FUNCTIONS *
     *------------------------*/

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
    ) private pure returns (int256 uPnLA, int256 uPnLB) {
        if (currentBalanceUnits == 0) return (0, 0);

        uint256 precision = C.getPrecision();

        // Note: it's safe to typecast notional values to int256 because they cannot be <= 0.
        if (side == Side.BUY) {
            require(bidPrice != 0, "Oracle bidPrice is invalid");
            int256 notionalIsolatedA = int256((currentBalanceUnits * bidPrice) / precision);
            uPnLA = notionalIsolatedA - int256(initialNotionalUsd);
        } else {
            require(askPrice != 0, "Oracle askPrice is invalid");
            int256 notionalIsolatedA = int256((currentBalanceUnits * askPrice) / precision);
            uPnLA = int256(initialNotionalUsd) - notionalIsolatedA;
        }

        return (uPnLA, -uPnLA);
    }

    /**
     * @notice Returns the UPnL of a party across all his open positions.
     * @dev This is a naive function, inputs can NOT be trusted. Use cautiously.
     * @dev positionPrices can have an incorrect length.
     * @dev positionPrices can have an arbitrary order.
     * @dev positionPrices can contain forged duplicates.
     */
    function _calculateUPnLCross(
        PositionPrice[] memory positionPrices,
        address party
    ) private view returns (int256 uPnLCrossA) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        for (uint256 i = 0; i < positionPrices.length; i++) {
            uint256 positionId = positionPrices[i].positionId;
            uint256 bidPrice = positionPrices[i].bidPrice;
            uint256 askPrice = positionPrices[i].askPrice;

            Position memory position = s.ma._allPositionsMap[positionId];
            require(position.partyA == party, "PositionId mismatch");

            (int256 _uPnLIsolatedA, ) = _calculateUPnLIsolated(
                position.side,
                position.currentBalanceUnits,
                position.initialNotionalUsd,
                bidPrice,
                askPrice
            );

            uPnLCrossA += _uPnLIsolatedA;
        }
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

    uint256 constant BASE = 10 ** 18;

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

    function sub(D256 memory self, uint256 b, string memory reason) internal pure returns (D256 memory) {
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

    function sub(D256 memory self, D256 memory b, string memory reason) internal pure returns (D256 memory) {
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

    function getPartial(uint256 target, uint256 numerator, uint256 denominator) private pure returns (uint256) {
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
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
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
import { PublicKey } from "./libraries/LibOracle.sol";
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

    function getMuonAppId() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.muonAppIdV2;
    }

    function getMuonPublicKey() internal view returns (PublicKey memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.muonPublicKey;
    }

    function getMuonGatewaySigner() internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.muonGatewaySigner;
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
    METALS,
    ENERGIES,
    INDICES,
    STOCKS,
    COMMODITIES,
    BONDS,
    ETFS,
    CRYPTO
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-version
pragma solidity  >=0.7.0 <0.9.0;

library SchnorrSECP256K1Verifier {
  // See https://en.bitcoin.it/wiki/Secp256k1 for this constant.
  uint256 constant public Q = // Group order of secp256k1
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
  uint256 constant public HALF_Q = (Q >> 1) + 1;

  /** **************************************************************************
      @notice verifySignature returns true iff passed a valid Schnorr signature.
      @dev See https://en.wikipedia.org/wiki/Schnorr_signature for reference.
      @dev In what follows, let d be your secret key, PK be your public key,
      PKx be the x ordinate of your public key, and PKyp be the parity bit for
      the y ordinate (i.e., 0 if PKy is even, 1 if odd.)
      **************************************************************************
      @dev TO CREATE A VALID SIGNATURE FOR THIS METHOD
      @dev First PKx must be less than HALF_Q. Then follow these instructions
           (see evm/test/schnorr_test.js, for an example of carrying them out):
      @dev 1. Hash the target message to a uint256, called msgHash here, using
              keccak256
      @dev 2. Pick k uniformly and cryptographically securely randomly from
              {0,...,Q-1}. It is critical that k remains confidential, as your
              private key can be reconstructed from k and the signature.
      @dev 3. Compute k*g in the secp256k1 group, where g is the group
              generator. (This is the same as computing the public key from the
              secret key k. But it's OK if k*g's x ordinate is greater than
              HALF_Q.)
      @dev 4. Compute the ethereum address for k*g. This is the lower 160 bits
              of the keccak hash of the concatenated affine coordinates of k*g,
              as 32-byte big-endians. (For instance, you could pass k to
              ethereumjs-utils's privateToAddress to compute this, though that
              should be strictly a development convenience, not for handling
              live secrets, unless you've locked your javascript environment
              down very carefully.) Call this address
              nonceTimesGeneratorAddress.
      @dev 5. Compute e=uint256(keccak256(PKx as a 32-byte big-endian
                                        ‖ PKyp as a single byte
                                        ‖ msgHash
                                        ‖ nonceTimesGeneratorAddress))
              This value e is called "msgChallenge" in verifySignature's source
              code below. Here "‖" means concatenation of the listed byte
              arrays.
      @dev 6. Let x be your secret key. Compute s = (k - d * e) % Q. Add Q to
              it, if it's negative. This is your signature. (d is your secret
              key.)
      **************************************************************************
      @dev TO VERIFY A SIGNATURE
      @dev Given a signature (s, e) of msgHash, constructed as above, compute
      S=e*PK+s*generator in the secp256k1 group law, and then the ethereum
      address of S, as described in step 4. Call that
      nonceTimesGeneratorAddress. Then call the verifySignature method as:
      @dev    verifySignature(PKx, PKyp, s, msgHash,
                              nonceTimesGeneratorAddress)
      **************************************************************************
      @dev This signging scheme deviates slightly from the classical Schnorr
      signature, in that the address of k*g is used in place of k*g itself,
      both when calculating e and when verifying sum S as described in the
      verification paragraph above. This reduces the difficulty of
      brute-forcing a signature by trying random secp256k1 points in place of
      k*g in the signature verification process from 256 bits to 160 bits.
      However, the difficulty of cracking the public key using "baby-step,
      giant-step" is only 128 bits, so this weakening constitutes no compromise
      in the security of the signatures or the key.
      @dev The constraint signingPubKeyX < HALF_Q comes from Eq. (281), p. 24
      of Yellow Paper version 78d7b9a. ecrecover only accepts "s" inputs less
      than HALF_Q, to protect against a signature- malleability vulnerability in
      ECDSA. Schnorr does not have this vulnerability, but we must account for
      ecrecover's defense anyway. And since we are abusing ecrecover by putting
      signingPubKeyX in ecrecover's "s" argument the constraint applies to
      signingPubKeyX, even though it represents a value in the base field, and
      has no natural relationship to the order of the curve's cyclic group.
      **************************************************************************
      @param signingPubKeyX is the x ordinate of the public key. This must be
             less than HALF_Q. 
      @param pubKeyYParity is 0 if the y ordinate of the public key is even, 1 
             if it's odd.
      @param signature is the actual signature, described as s in the above
             instructions.
      @param msgHash is a 256-bit hash of the message being signed.
      @param nonceTimesGeneratorAddress is the ethereum address of k*g in the
             above instructions
      **************************************************************************
      @return True if passed a valid signature, false otherwise. */
  function verifySignature(
    uint256 signingPubKeyX,
    uint8 pubKeyYParity,
    uint256 signature,
    uint256 msgHash,
    address nonceTimesGeneratorAddress) internal pure returns (bool) {
    require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
    // Avoid signature malleability from multiple representations for ℤ/Qℤ elts
    require(signature < Q, "signature must be reduced modulo Q");

    // Forbid trivial inputs, to avoid ecrecover edge cases. The main thing to
    // avoid is something which causes ecrecover to return 0x0: then trivial
    // signatures could be constructed with the nonceTimesGeneratorAddress input
    // set to 0x0.
    //
    require(nonceTimesGeneratorAddress != address(0) && signingPubKeyX > 0 &&
      signature > 0 && msgHash > 0, "no zero inputs allowed");

    uint256 msgChallenge = // "e"
      uint256(keccak256(abi.encodePacked(nonceTimesGeneratorAddress, msgHash)));

    // Verify msgChallenge * signingPubKey + signature * generator ==
    //        nonce * generator
    //
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    // The point corresponding to the address returned by
    // ecrecover(-s*r,v,r,e*r) is (r⁻¹ mod Q)*(e*r*R-(-s)*r*g)=e*R+s*g, where R
    // is the (v,r) point. See https://crypto.stackexchange.com/a/18106
    //
    address recoveredAddress = ecrecover(
      bytes32(Q - mulmod(signingPubKeyX, signature, Q)),
      // https://ethereum.github.io/yellowpaper/paper.pdf p. 24, "The
      // value 27 represents an even y value and 28 represents an odd
      // y value."
      (pubKeyYParity == 0) ? 27 : 28,
      bytes32(signingPubKeyX),
      bytes32(mulmod(msgChallenge, signingPubKeyX, Q)));
    return nonceTimesGeneratorAddress == recoveredAddress;
  }

  function validatePubKey (uint256 signingPubKeyX) internal pure {
    require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage, Market } from "../libraries/LibAppStorage.sol";

library LibMarkets {
    function isValidMarketId(uint256 marketId) internal pure returns (bool) {
        return marketId != 0;
    }

    function isActiveMarket(uint256 marketId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.markets._marketMap[marketId].active;
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
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

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