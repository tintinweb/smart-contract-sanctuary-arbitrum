// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IClearing} from "../interfaces/IClearing.sol";
import {IProduct} from "../interfaces/IProduct.sol";
import {IOracleModule} from "../interfaces/IOracleModule.sol";
import {IErrors} from "../interfaces/IErrors.sol";

// NOTE: Private functions converted to internal for tests
contract BinaryOption is IProduct {
    /// @notice The required liveness for the oracle price
    uint256 public constant LIVENESS = 1 hours;

    /// @notice The fixed take for the protocol
    uint256 public constant FIXED_TAKE = 25e3; // 2.5%

    /// @notice The scaling factor used for divison
    uint256 public constant SCALING_FACTOR = 1e6; // 100%

    /// @notice The address of the protocol
    address public constant PROTOCOL_ADDR = address(0x111);

    function buildTrade(IClearing.MatchOrder[] calldata _matchOrder)
        external
        view
        returns (IClearing.Trade[] memory trade, IClearing.Fees[] memory fees)
    {
        // Configuring arrays for trade
        trade = new IClearing.Trade[](_matchOrder.length);
        fees = new IClearing.Fees[](_matchOrder.length);

        // Building trade for each match order
        for (uint256 i = 0; i < _matchOrder.length; i++) {
            // Fetching order details
            IClearing.SignedOrder memory takerOrder = _matchOrder[i].takerOrder;
            IClearing.SignedOrder memory makerOrder = _matchOrder[i].makerOrder;

            // Configuring the roles, checking returns, and expiration
            (
                address buyer,
                address seller,
                uint256 buyerAmount,
                uint256 sellerAmount,
                uint256 buyerAccountType,
                uint256 sellerAccountType,
                uint256 expiration
            ) = _checkTerms(takerOrder.order, makerOrder.order);

            // Configuring the fee transfer from buyer to seller
            fees[i].to = new address[](2);
            fees[i].amount = new uint256[](2);
            fees[i].asset = new address[](2);
            fees[i].accountType = new uint256[](2);

            // Fee from the buyer to the seller
            uint256 protocolTake = (buyerAmount * FIXED_TAKE) / SCALING_FACTOR;
            fees[i] = _buildFees(
                fees[i], 0, takerOrder.order.settleAsset, buyerAmount - protocolTake, buyer, seller, sellerAccountType
            );
            // Fee from the buyer to the protocol (fixed take on premium)
            fees[i] = _buildFees(fees[i], 1, takerOrder.order.settleAsset, protocolTake, buyer, PROTOCOL_ADDR, 1);

            // Configuring the trade information
            trade[i] = IClearing.Trade({
                instrument: takerOrder.order.instrument,
                direction: takerOrder.order.direction,
                buyerAmount: uint128(buyerAmount),
                sellerAmount: uint128(sellerAmount),
                buyerFee: 0,
                sellerFee: 0,
                price: takerOrder.order.price,
                speculateAsset: takerOrder.order.speculateAsset,
                settleAsset: takerOrder.order.settleAsset,
                buyer: buyer,
                buyerAccountType: uint8(buyerAccountType),
                seller: seller,
                sellerAccountType: uint8(sellerAccountType),
                input: abi.encode(expiration, block.timestamp)
            });
        }
    }

    // /// @dev buyerAmount is the premium and the _buyerReturn is the expected ROI on premium e.g. 10_000_000 would be 10x
    // /// @dev sellerAmount needs to be scaled by correct decimals to match the buyerAmount
    // /**
    //     Example with 6 decimals:
    //         buyerAmount = 100e6 (100 USDC)
    //         sellerAmount = 1000e6 (1000 USDC)
    //         buyerReturn = 10_000_000 (10x)

    //         100e6 * 10_000_000 (10e6) = 1000_000_000_000_000 (1000e12)
    //         Values will be same in this example

    //     Example with 18 decimals:
    //         buyerAmount = 100e18 (100 USDT)
    //         sellerAmount = 1000e18 (1000 USDT)
    //         buyerReturn = 10_000_000 (10x)

    //         100e18 * 10_000_000 (10e6) = 1000_000_000_000_000_000_000 (1000e24)
    //         1000e24 / 1e6 = 1000e18
    //         Values will be same in this example
    //  */
    // function _returnsMatch(uint128 _buyerAmount, uint128 _sellerAmount, uint256 _buyerReturn) private view returns (bool) {
    //     // Calculating the payout by applying the ROI multiple to the taker amount
    //     return ((_buyerAmount * _buyerReturn)/SCALING_FACTOR) == _sellerAmount;
    // }

    /**
     * Examples:
     *         Perp funding fees - 0.05% per 8 hours and opened for 80 hours so 0.05% * 10 = 0.5%
     *             => Funding fees goes to the seller
     *         Trade closing fees (Perp/American option) - 0.1% of trade amount
     *             => Closing fees goes to the the protocol
     *
     *     Would need to sendFunds for PnL and also sendFunds for fees
     *         => When seller wins then sendFunds called on buyer account with SendingAmount[toSeller, toProtocol]
     *         => When buyer wins then sendFunds called on seller account with SendingAmount[toBuyer]
     *             Then sendFunds needs to be called on buyer account with SendingAmount[toProtocol]
     *
     *     NOTE: Could return an array of arrays where:
     *         pnl[0][0] = PnL
     *         pnl[0][1] = protocolFees
     *
     *         OR could return two arrays:
     *             Check then: pnl[0] = PnL
     *             Check then: protocolFees[0] = protocolFees
     *
     *                 IF PnL is positive = buyer wins (Send from seller)
     *                 IF fees is positive = seller pays (Send from seller)
     *
     *                 Construct new array of 2:
     *                     funds[0] = PnL
     *                     funds[1] = protocolFees
     *
     *     With binary option there would be a protocolFee if the buyer wins
     */
    function closeTrade(
        IOracleModule _oracleModule,
        IClearing.Trade[] calldata _trade,
        IClearing.Close[] calldata _close,
        bytes32[] memory _oracle
    ) external returns (IClearing.Pnl[] memory pnl, IClearing.Fees[] memory fees) {
        // Configuring arrays for PnL and fees
        pnl = new IClearing.Pnl[](_trade.length);
        fees = new IClearing.Fees[](_trade.length);

        // Configuring arrays and fetching prices from oracle
        uint256[] memory prices = new uint256[](_oracle.length);
        uint256[] memory updatedAt = new uint256[](_oracle.length);
        (prices, updatedAt) = _oracleModule.bulkGetLatestPrice(_oracle);

        // Calculating PnL for each trade
        for (uint256 i = 0; i < _trade.length;) {
            // !tradeExpired and !strikeHit reverts && !tradeExpired and strikeHit continue && tradeExpired and !strikeHit resolves
            // Checking the oracle price liveness
            if (block.timestamp > updatedAt[i] + LIVENESS) {
                revert IErrors.OraclePriceOutdated();
            }

            // Fetching trade details
            IClearing.Trade memory trade = _trade[i];

            // Checking closing amount is the full amount - as binary can either win or lose and can't be partially closed
            if (_close[i].amount != trade.buyerAmount) {
                revert IErrors.ProductError();
            }

            // Checking the expiration has passed on the option OR strike has hit
            uint256 expiration = abi.decode(trade.input, (uint256));

            // Checking the strike has hit - if direction = 1 then call and if direction = 2 then put
            bool strikeHit = trade.direction == 1 ? prices[i] >= trade.price : prices[i] <= trade.price;
            bool tradeExpired = block.timestamp > expiration;
            if (!tradeExpired && !strikeHit) {
                revert IErrors.NotExpired();
            }
            // Calculating the PnL
            // NOTE: PnL will return sellerAmount if buyer wins and 0 if seller wins (i.e. refund collateral)
            else if (!tradeExpired && strikeHit) {
                (pnl[i], fees[i]) = _calculatePnl(trade, prices[i]);
            } else {
                // If the trade has expired then the buyer gets 0 and the seller gets the collateral back
                pnl[i].buyerChange = int128(0);
                pnl[i].sellerChange = int128(trade.sellerAmount);
            }

            unchecked {
                i++;
            }
        }
    }

    function calculatePnl(IOracleModule _oracleModule, IClearing.Trade calldata _trade, bytes32 _oracle)
        external
        view
        returns (IClearing.Pnl memory pnl, IClearing.Fees memory fees)
    {
        // Fetching price from oracle
        (uint256 price,) = _oracleModule.getLatestPrice(_oracle);

        // Calculating PnL
        return _calculatePnl(_trade, price);
    }

    /////////////////////////////// Internal Functions ///////////////////////////////////////
    /// @dev Price must match and UI must ensure correct decimals used for option prices to resolve
    function _checkTerms(IClearing.Order memory takerOrder, IClearing.Order memory makerOrder)
        internal
        view
        returns (
            address buyer,
            address seller,
            uint256 buyerAmount,
            uint256 sellerAmount,
            uint256 buyerAccountType,
            uint256 sellerAcountType,
            uint256 expiration
        )
    {
        // Checking price (strike) matches for both sides - strikes must always be the same with a binary option
        // Clearinghouse has already checked instrument, direction, speculateAsset, settleAsset, role, and expiration are valid
        if (takerOrder.price != makerOrder.price) {
            revert IErrors.MismatchPrice();
        }

        // Setting buyer and seller based on role whether takerOrder is 1 = buyer and 2 = seller
        if (takerOrder.role == 1) {
            buyer = takerOrder.account;
            seller = makerOrder.account;
            buyerAccountType = takerOrder.accountType;
            sellerAcountType = makerOrder.accountType;

            // Setting the buyerAmount based on buyer/seller
            buyerAmount = takerOrder.amount;

            // Decoding the input to get the returns and expiration
            uint256 takerReturn;
            (takerReturn, expiration) = abi.decode(takerOrder.input, (uint256, uint256));
            (uint256 makerReturn, uint256 sellerExpiration) = abi.decode(makerOrder.input, (uint256, uint256));
            if (expiration != sellerExpiration) revert IErrors.MismatchExpiration();

            // Checking the returns match, calculate sellerAmount (maxLoss/reqCollat) and the expirations are the same
            sellerAmount = _checkReturns(makerReturn, takerReturn, buyerAmount, buyer == takerOrder.account);
            if (sellerAmount > makerOrder.amount) revert IErrors.InvalidFillAmount();
        } else {
            seller = takerOrder.account;
            buyer = makerOrder.account;
            sellerAcountType = takerOrder.accountType;
            buyerAccountType = makerOrder.accountType;

            // Setting the buyerAmount based on buyer/seller
            sellerAmount = takerOrder.amount;

            // Decoding the input to get the returns and expiration
            uint256 makerReturn;
            (makerReturn, expiration) = abi.decode(makerOrder.input, (uint256, uint256));
            (uint256 takerReturn, uint256 sellerExpiration) = abi.decode(takerOrder.input, (uint256, uint256));
            if (expiration != sellerExpiration) revert IErrors.MismatchExpiration();

            // Checking the returns match, calculate sellerAmount (maxLoss/reqCollat) and the expirations are the same
            buyerAmount = _checkReturns(makerReturn, takerReturn, sellerAmount, buyer == takerOrder.account);
            if (buyerAmount > makerOrder.amount) revert IErrors.InvalidFillAmount();
        }
    }

    function _buildFees(
        IClearing.Fees memory fee,
        uint256 index,
        address _settleAsset,
        uint256 _buyerAmount,
        address _buyer,
        address _seller,
        uint256 _sellerAccountType
    ) internal pure returns (IClearing.Fees memory) {
        // Configuring the fees for the trade
        fee.from = _buyer;
        fee.to[index] = _seller;
        fee.amount[index] = _buyerAmount;
        fee.asset[index] = _settleAsset;
        fee.accountType[index] = _sellerAccountType;

        return fee;
    }

    /**
     * When taker is the buyer we need to make sure seller is getting ROI >= to terms
     *     - Terms are in taker terms e.g. 10x equates to 10% for seller
     *     - SellerReturn must be <= buyerReturn
     *     - ExampleA: sellerReturn = 10% (10x) and buyerReturn = 5x (20%) i.e. sellerReturn: 10_000_000 and buyerReturn: 5_000_000
     *     - ExampleB: sellerReturn = 10% (10x) and buyerReturn = 20x (5%) i.e. sellerReturn: 10_000_000 and buyerReturn: 20_000_000
     *
     *     For (A) sellerReturn > buyerReturn meaning seller
     *     For (B) sellerReturn < buyerReturn meaning buyer
     *
     *     If the taker is the seller then they are taking liquidity from the book so their order must pay >= to the expected trade:
     *
     *     - TakerIsSeller means the buyer has a limit order (e.g. 10x) and seller is filling it
     *     - When takerIsSeller the seller must pay the buyer 10x or more
     *         -> It must be 10x (10%) or more as 10x is 10_000_000 and 20x (5%) is 20_000_000
     *             - If >10_000_000 then the maker (buyer) is getting 10x or with 20_000_000 they get 20x
     *         -> The seller (taker)
     *
     *     - !TakerIsSeller means the seller has a limit order (e.g. 10%) and buyer is filling it
     *     - When !takerIsSeller the buyer must pay the seller 10% or less
     *         -> It must be 10% (10x) or less as 10x is 10_000_000 and 20% (5x) is 5_000_000
     *             - If <10_000_000 then the maker (seller) is getting 10x or with 5_000_000 they get 5x
     *         -> The buyer (taker)
     */
    function _checkReturns(uint256 _makerReturn, uint256 _takerReturn, uint256 _takerAmount, bool _takerIsBuyer)
        internal
        view
        returns (uint256 returnAmount)
    {
        if (_takerIsBuyer) {
            // IF taker (buyer) wants 20x (5% to seller) and maker (seller) wants 10x (10% to seller)
            // THEN takerR > makerR = REVERT (as the maker/seller is getting a worse fill)
            if (_takerReturn > _makerReturn) revert IErrors.MismatchTerms();
            returnAmount = (_takerReturn * _takerAmount) / SCALING_FACTOR;
        } else {
            // IF taker (seller) want 5x (20% to seller) and maker (buyer) wants 10x (10% to seller)
            // THEN takerR < makerR = REVERT (as the maker/buyer is getting a worse fill)
            if (_takerReturn < _makerReturn) revert IErrors.MismatchTerms();
            returnAmount = (_takerAmount * SCALING_FACTOR) / _takerReturn;
        }

        // NOTE: We know takerReturn is same or better than expected so always fill with it
        // AUDIT TODO: Should the scalingFactor vary based on the token in use decimals?
    }

    function _calculatePnl(IClearing.Trade memory _trade, uint256 price)
        internal
        pure
        returns (IClearing.Pnl memory _pnl, IClearing.Fees memory _fees)
    {
        // If trade direction equals 1 then it's a call option
        if ((_trade.direction == 1 && price >= _trade.price) || (_trade.direction == 2 && price <= _trade.price)) {
            // Configuring the PnL for the buyer and seller
            _pnl.buyerChange = int128(_trade.sellerAmount);
            _pnl.sellerChange = 0;

            // Calculating the protocol take
            uint256 protocolTake = (_trade.sellerAmount * FIXED_TAKE) / SCALING_FACTOR;

            // Building the fee struct for this trade incl. value exchange between parties and protocol
            _fees = IClearing.Fees({
                from: address(0),
                to: new address[](2),
                amount: new uint256[](2),
                asset: new address[](2),
                accountType: new uint256[](2)
            });
            _fees = _buildFees(
                _fees,
                0,
                _trade.settleAsset,
                _trade.sellerAmount - protocolTake,
                _trade.seller,
                _trade.buyer,
                _trade.buyerAccountType
            );
            _fees = _buildFees(_fees, 1, _trade.settleAsset, protocolTake, _trade.seller, PROTOCOL_ADDR, 1);
        } else {
            _pnl.buyerChange = int128(0);
            _pnl.sellerChange = int128(_trade.sellerAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IClearing {
    struct MatchOrder {
        SignedOrder takerOrder;
        SignedOrder makerOrder;
    }

    struct SignedOrder {
        Order order;
        bytes sig;
        address sender;
    }

    /**
     * @dev role: 1 = buyer, 2 = seller
     *     @dev direction: 1 = long, 2 = short
     *     @dev expiration: timestamp
     *     @dev price: Perp = price, Option = strike
     *     @dev input: contains instrument specific info
     */
    struct Order {
        address account;
        uint8 accountType; // 1 - basicAccount, 2 - poolAccount
        address instrument; // BinaryOption || AmericanOption || PerpetualOption
        address speculateAsset;
        address settleAsset;
        uint8 role; // Seller || Buyer
        uint8 direction; // Long || Short
        uint128 amount;
        uint128 expiration;
        uint256 price;
        uint256 nonce;
        bytes input;
    }

    struct Close {
        uint128 amount;
        uint64 nonce;
        bool isLiquidation;
    }

    /**
     * @dev direction: 1 = long, 2 = short
     *     @dev For any trade seller must lock an amount of asset to cover maxLoss - sellerAmount
     *     Example with sellerAmount/maxLoss = 100
     *         Binary Option:
     *             buyerAmount = 10
     *             sellerAmount = 100
     *                 => buyer gets 10x on strike and seller gets 10% on no-strike
     *         American Option:
     *             buyerAmount = 10
     *             sellerAmount = 100
     *                 => buyer gets dynamic return up to 10x and seller gets 10% on no-strike
     *         Perpetual Contract:
     *             buyerAmount = 10
     *             sellerAmount = 100
     *                 => buyer gets dynamic return up to 10x
     *                 => seller gets dynamic loss of buyer plus fees
     *                 => seller maxLoss funds still required to ensure payment to trader
     */
    struct Trade {
        address instrument;
        uint8 direction;
        uint128 buyerAmount;
        uint128 sellerAmount;
        uint128 buyerFee;
        uint128 sellerFee;
        uint256 price;
        address speculateAsset;
        address settleAsset;
        address buyer;
        uint8 buyerAccountType;
        address seller;
        uint8 sellerAccountType;
        bytes input; // Appended timestamp - used for nonce in subgraph
    }

    struct Fees {
        address from;
        address[] to;
        uint256[] amount;
        address[] asset;
        uint256[] accountType;
    }

    struct Gas {
        address fromAccount;
        address to;
        uint256 amount;
        address asset;
        uint128 nonce;
    }

    struct Pnl {
        int256 buyerChange;
        int256 sellerChange;
    }

    function addAccount(address _account, uint256 _accountType, address _accountOwner) external;

    function updateCollateral(bool _add, address _token, uint256 _amount, bytes memory _bytes) external;

    function updateManager(address _newManager) external;

    function updateInstrumentForAccount(address[] calldata _instrument, bool[] calldata _status) external;

    function updateInstrumentForAccount(address _instrument, bool _status) external;

    function openTrade(MatchOrder[] calldata _matchOrder, address _instrument)
        external
        returns (IClearing.Trade[] memory trade, IClearing.Fees[] memory fees);

    function closeTrade(bytes32[] calldata _tradeHash, Close[] calldata _close, bytes[] calldata _sig)
        external
        returns (IClearing.Pnl[] memory pnl, IClearing.Fees[] memory fees);

    function cancelTrade(Order[] calldata _order, bytes[] memory _sig) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IClearing} from "../interfaces/IClearing.sol";
import {IOracleModule} from "../interfaces/IOracleModule.sol";

interface IProduct {
    function buildTrade(IClearing.MatchOrder[] calldata _matchOrder) external returns (IClearing.Trade[] memory trade, IClearing.Fees[] memory fees);

    function closeTrade(IOracleModule _oracleModule, IClearing.Trade[] calldata _trade, IClearing.Close[] calldata _close, bytes32[] memory _oracle) external returns (IClearing.Pnl[] memory pnl, IClearing.Fees[] memory fees);

    function calculatePnl(IOracleModule _oracleModule, IClearing.Trade calldata _trade, bytes32 _oracle) external view returns (IClearing.Pnl memory pnl, IClearing.Fees memory fees);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IOracleModule {
    function updatePrice(bytes32 _oracle, bytes[] calldata _input) external payable;

    function bulkUpdatePrice(bytes32[] calldata _oracle, bytes[][] calldata _input) external payable;

    function bulkGetLatestPrice(bytes32[] calldata _oracle)
        external
        returns (uint256[] memory price, uint256[] memory updatedAt);

    function getLatestPrice(bytes32 _oracle) external view returns (uint256 price, uint256 updatedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IErrors {
    // Generic Errors //
    error InvalidLength();
    error InvalidCaller();
    error InvalidAccount();
    error InvalidAddress();
    error InvalidInstrument();
    error InvalidUint();
    error InvalidSignature();
    error InvalidLiquidation();
    error InvalidFillAmount();
    error Overfilled();
    error InvalidArrayInstrument();

    // Product Errors
    error ProductError();
    error MaxLeverage();

    // Account Errors //
    error Implemented();

    // Order Errors //
    error OrderExpired();
    error MismatchInstrument();
    error MismatchSpecAsset();
    error MismatchSettleAsset();
    error MismatchRoles();
    error MismatchDirection();
    error MismatchPrice();
    error MismatchPayout();
    error MismatchTerms();
    error MismatchExpiration();
    error MoreThanPosition();
    error NotExpired();

    // Oracle Errors //
    error InvalidResponse();
    error UpdateActive();
    error CooldownActive();
    error OraclePriceOutdated();
    error InvalidOracle();
    error InvalidTimestamp();

    // Pool Errors //
    error MaxExceeded();
    error NotImplemented();
    error MoreThanBalance();
    error NoAllowance();
    error EpochNotEnded();
    error InvalidToken();
    error MathOverflowedMulDiv();
    error InsufficientAllowance();
    error DelayPending();
}