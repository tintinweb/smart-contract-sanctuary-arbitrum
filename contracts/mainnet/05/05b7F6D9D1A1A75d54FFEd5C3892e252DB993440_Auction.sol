// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/introspection/ERC165Storage.sol";
import "@solidstate/contracts/utils/Multicall.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "./AuctionInternal.sol";
import "./IAuction.sol";

/**
 * @title Knox Dutch Auction Contract
 * @dev deployed standalone and referenced by AuctionProxy
 */

contract Auction is AuctionInternal, IAuction, Multicall, ReentrancyGuard {
    using ABDKMath64x64 for int128;
    using AuctionStorage for AuctionStorage.Layout;
    using EnumerableSet for EnumerableSet.UintSet;
    using ERC165Storage for ERC165Storage.Layout;
    using OrderBook for OrderBook.Index;
    using SafeERC20 for IERC20;

    int128 private constant ONE_64x64 = 0x10000000000000000;

    constructor(
        bool isCall,
        address pool,
        address vault,
        address weth
    ) AuctionInternal(isCall, pool, vault, weth) {}

    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @inheritdoc IAuction
     */
    function setDeltaOffset64x64(int128 newDeltaOffset64x64)
        external
        onlyOwner
    {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        require(newDeltaOffset64x64 > 0, "delta <= 0");
        require(newDeltaOffset64x64 < ONE_64x64, "delta > 1");

        emit DeltaOffsetSet(
            l.deltaOffset64x64,
            newDeltaOffset64x64,
            msg.sender
        );

        l.deltaOffset64x64 = newDeltaOffset64x64;
    }

    /**
     * @inheritdoc IAuction
     */
    function setExchangeHelper(address newExchangeHelper) external onlyOwner {
        AuctionStorage.Layout storage l = AuctionStorage.layout();

        require(newExchangeHelper != address(0), "address not provided");
        require(
            newExchangeHelper != address(l.Exchange),
            "new address equals old"
        );

        emit ExchangeHelperSet(
            address(l.Exchange),
            newExchangeHelper,
            msg.sender
        );

        l.Exchange = IExchangeHelper(newExchangeHelper);
    }

    /**
     * @inheritdoc IAuction
     */
    function setMinSize(uint256 newMinSize) external onlyOwner {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        require(newMinSize > 0, "value exceeds minimum");
        emit MinSizeSet(l.minSize, newMinSize, msg.sender);
        l.minSize = newMinSize;
    }

    /**
     * @inheritdoc IAuction
     */
    function setPricer(address newPricer) external onlyOwner {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        require(newPricer != address(0), "address not provided");
        require(newPricer != address(l.Pricer), "new address equals old");
        emit PricerSet(address(l.Pricer), newPricer, msg.sender);
        l.Pricer = IPricer(newPricer);
    }

    /************************************************
     *  INITIALIZE AUCTION
     ***********************************************/

    /**
     * @inheritdoc IAuction
     */
    function initialize(AuctionStorage.InitAuction memory initAuction)
        external
        onlyVault
    {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[initAuction.epoch];

        require(
            auction.status == AuctionStorage.Status.UNINITIALIZED,
            "status != uninitialized"
        );

        if (
            initAuction.startTime >= initAuction.endTime ||
            block.timestamp > initAuction.startTime ||
            block.timestamp > initAuction.expiry ||
            initAuction.strike64x64 <= 0 ||
            initAuction.longTokenId <= 0
        ) {
            // the auction is cancelled if the start time is greater than or equal to
            // the end time, the current time is greater than the start time, or the
            // option parameters are invalid
            _cancel(l.auctions[initAuction.epoch], initAuction.epoch);
        } else {
            auction.expiry = initAuction.expiry;
            auction.strike64x64 = initAuction.strike64x64;
            auction.startTime = initAuction.startTime;
            auction.endTime = initAuction.endTime;
            auction.longTokenId = initAuction.longTokenId;

            _updateStatus(
                auction,
                AuctionStorage.Status.INITIALIZED,
                initAuction.epoch
            );
        }
    }

    /**
     * @inheritdoc IAuction
     */
    function setAuctionPrices(uint64 epoch) external {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        require(
            AuctionStorage.Status.INITIALIZED == auction.status,
            "status != initialized"
        );

        require(
            block.timestamp > auction.startTime - 30 minutes,
            "price set too early"
        );

        require(
            auction.minPrice64x64 <= 0 || auction.maxPrice64x64 <= 0,
            "prices are already set"
        );

        if (auction.startTime > block.timestamp) {
            int128 spot64x64;
            int128 timeToMaturity64x64;

            // fetches the spot price of the underlying
            try l.Pricer.latestAnswer64x64() returns (int128 _spot64x64) {
                spot64x64 = _spot64x64;
            } catch Error(string memory message) {
                emit Log(message);
                spot64x64 = 0;
            }

            // fetches the time to maturity of the option
            try l.Pricer.getTimeToMaturity64x64(auction.expiry) returns (
                int128 _timeToMaturity64x64
            ) {
                timeToMaturity64x64 = _timeToMaturity64x64;
            } catch Error(string memory message) {
                emit Log(message);
                timeToMaturity64x64 = 0;
            }

            if (spot64x64 > 0 && timeToMaturity64x64 > 0) {
                _setAuctionPrices(
                    l,
                    auction,
                    epoch,
                    spot64x64,
                    timeToMaturity64x64
                );
            }
        }

        _validateAuctionPrices(auction, epoch);
    }

    /************************************************
     *  PRICING
     ***********************************************/

    /**
     * @inheritdoc IAuction
     */
    function lastPrice64x64(uint64 epoch) external view returns (int128) {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];
        return _lastPrice64x64(auction);
    }

    /**
     * @inheritdoc IAuction
     */
    function priceCurve64x64(uint64 epoch) external view returns (int128) {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];
        return _priceCurve64x64(auction);
    }

    /**
     * @inheritdoc IAuction
     */
    function clearingPrice64x64(uint64 epoch) external view returns (int128) {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];
        return _clearingPrice64x64(auction);
    }

    /************************************************
     *  PURCHASE
     ***********************************************/

    /**
     * @inheritdoc IAuction
     */
    function addLimitOrder(
        uint64 epoch,
        int128 price64x64,
        uint256 size
    ) external payable nonReentrant {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        _limitOrdersAllowed(auction);

        uint256 cost = _validateLimitOrder(l, price64x64, size);
        uint256 credited = _wrapNativeToken(cost);
        // an approve() by the msg.sender is required beforehand
        ERC20.safeTransferFrom(msg.sender, address(this), cost - credited);
        _addOrder(l, auction, epoch, price64x64, size, true);
    }

    /**
     * @inheritdoc IAuction
     */
    function swapAndAddLimitOrder(
        IExchangeHelper.SwapArgs calldata s,
        uint64 epoch,
        int128 price64x64,
        uint256 size
    ) external payable nonReentrant {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        _limitOrdersAllowed(auction);

        uint256 cost = _validateLimitOrder(l, price64x64, size);
        uint256 credited = _swapForPoolTokens(l.Exchange, s, address(ERC20));
        _transferAssets(credited, cost, msg.sender);
        _addOrder(l, auction, epoch, price64x64, size, true);
    }

    /**
     * @inheritdoc IAuction
     */
    function cancelLimitOrder(uint64 epoch, uint128 orderId)
        external
        nonReentrant
    {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        _limitOrdersAllowed(auction);

        require(orderId > 0, "invalid order id");

        OrderBook.Index storage orderbook = l.orderbooks[epoch];
        OrderBook.Data memory data = orderbook._getOrderById(orderId);

        require(data.buyer != address(0), "order does not exist");
        require(data.buyer == msg.sender, "buyer != msg.sender");

        orderbook._remove(orderId);
        // removes unique order id associated with epoch and id
        _removeUniqueOrderId(l, epoch, orderId);

        if (block.timestamp >= auction.startTime) {
            _finalizeAuction(l, auction, epoch);
        }

        uint256 cost = data.price64x64.mulu(data.size);
        ERC20.safeTransfer(msg.sender, cost);

        emit OrderCanceled(epoch, orderId, msg.sender);
    }

    /**
     * @inheritdoc IAuction
     */
    function addMarketOrder(
        uint64 epoch,
        uint256 size,
        uint256 maxCost
    ) external payable nonReentrant {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        _marketOrdersAllowed(auction);

        (int128 price64x64, uint256 cost) =
            _validateMarketOrder(l, auction, size, maxCost);

        uint256 credited = _wrapNativeToken(cost);
        // an approve() by the msg.sender is required beforehand
        ERC20.safeTransferFrom(msg.sender, address(this), cost - credited);
        _addOrder(l, auction, epoch, price64x64, size, false);
    }

    /**
     * @inheritdoc IAuction
     */
    function swapAndAddMarketOrder(
        IExchangeHelper.SwapArgs calldata s,
        uint64 epoch,
        uint256 size,
        uint256 maxCost
    ) external payable nonReentrant {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        _marketOrdersAllowed(auction);

        (int128 price64x64, uint256 cost) =
            _validateMarketOrder(l, auction, size, maxCost);

        uint256 credited = _swapForPoolTokens(l.Exchange, s, address(ERC20));
        _transferAssets(credited, cost, msg.sender);
        _addOrder(l, auction, epoch, price64x64, size, false);
    }

    /************************************************
     *  WITHDRAW
     ***********************************************/

    /**
     * @inheritdoc IAuction
     */
    function withdraw(uint64 epoch) external nonReentrant {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        require(
            AuctionStorage.Status.PROCESSED == auction.status ||
                AuctionStorage.Status.CANCELLED == auction.status,
            "status != processed || cancelled"
        );

        if (AuctionStorage.Status.PROCESSED == auction.status) {
            // long tokens are withheld for 24 hours after the auction has been processed, otherwise
            // if a long position is exercised within 24 hours of the position being underwritten
            // the collateral from the position will be moved to the pools "free liquidity" queue.
            require(
                block.timestamp >= auction.processedTime + 24 hours,
                "hold period has not ended"
            );
        }

        _withdraw(l, epoch);
    }

    /**
     * @inheritdoc IAuction
     */
    function previewWithdraw(uint64 epoch) external returns (uint256, uint256) {
        return _previewWithdraw(epoch, msg.sender);
    }

    /**
     * @inheritdoc IAuction
     */
    function previewWithdraw(uint64 epoch, address buyer)
        external
        returns (uint256, uint256)
    {
        return _previewWithdraw(epoch, buyer);
    }

    /************************************************
     *  FINALIZE AUCTION
     ***********************************************/

    /**
     * @inheritdoc IAuction
     */
    function finalizeAuction(uint64 epoch) external {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        if (
            block.timestamp > auction.endTime + 24 hours &&
            (auction.status == AuctionStorage.Status.INITIALIZED ||
                auction.status == AuctionStorage.Status.FINALIZED)
        ) {
            // cancel the auction if it has not been processed within 24 hours of the
            // auction end time so that buyers may withdraw their refunded amount
            _cancel(auction, epoch);
        } else if (
            block.timestamp >= auction.startTime &&
            auction.status == AuctionStorage.Status.INITIALIZED
        ) {
            // finalize the auction only if the auction has started
            _finalizeAuction(l, auction, epoch);
        }
    }

    /**
     * @inheritdoc IAuction
     */
    function processAuction(uint64 epoch)
        external
        onlyVault
        returns (uint256, uint256)
    {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        require(
            AuctionStorage.Status.FINALIZED == auction.status,
            "status != finalized"
        );

        auction.totalPremiums = _lastPrice64x64(auction).mulu(
            auction.totalContractsSold
        );

        ERC20.safeTransfer(address(Vault), auction.totalPremiums);

        auction.processedTime = block.timestamp;

        _updateStatus(auction, AuctionStorage.Status.PROCESSED, epoch);
        return (auction.totalPremiums, auction.totalContractsSold);
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @inheritdoc IAuction
     */
    function getAuction(uint64 epoch)
        external
        view
        returns (AuctionStorage.Auction memory)
    {
        return AuctionStorage._getAuction(epoch);
    }

    /**
     * @inheritdoc IAuction
     */
    function getDeltaOffset64x64() external view returns (int128) {
        return AuctionStorage._getDeltaOffset64x64();
    }

    /**
     * @inheritdoc IAuction
     */
    function getMinSize() external view returns (uint256) {
        return AuctionStorage._getMinSize();
    }

    /**
     * @inheritdoc IAuction
     */
    function getOrderById(uint64 epoch, uint128 orderId)
        external
        view
        returns (OrderBook.Data memory)
    {
        return AuctionStorage._getOrderById(epoch, orderId);
    }

    /**
     * @inheritdoc IAuction
     */
    function getStatus(uint64 epoch)
        external
        view
        returns (AuctionStorage.Status)
    {
        return AuctionStorage._getStatus(epoch);
    }

    /**
     * @inheritdoc IAuction
     */
    function getTotalContracts(uint64 epoch) external view returns (uint256) {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        // returns the stored total contracts if the auction has started
        if (auction.startTime > 0 && block.timestamp >= auction.startTime) {
            return AuctionStorage._getTotalContracts(epoch);
        }

        return 0;
    }

    /**
     * @inheritdoc IAuction
     */
    function getTotalContractsSold(uint64 epoch)
        external
        view
        returns (uint256)
    {
        return AuctionStorage._getTotalContractsSold(epoch);
    }

    /**
     * @inheritdoc IAuction
     */
    function getUniqueOrderIds(address buyer)
        external
        view
        returns (uint256[] memory)
    {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        EnumerableSet.UintSet storage uoids = l.uoids[buyer];

        uint256[] memory _uoids = new uint256[](uoids.length());

        unchecked {
            for (uint256 i; i < uoids.length(); ++i) {
                uint256 uoid = uoids.at(i);
                _uoids[i] = uoid;
            }
        }

        return _uoids;
    }

    /************************************************
     *  ERC165 SUPPORT
     ***********************************************/

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }

    /************************************************
     *  ERC1155 SUPPORT
     ***********************************************/

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMulticall } from './IMulticall.sol';

/**
 * @title Utility contract for supporting processing of multiple function calls in a single transaction
 */
abstract contract Multicall is IMulticall {
    /**
     * @inheritdoc IMulticall
     */
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);

        unchecked {
            for (uint256 i; i < data.length; i++) {
                (bool success, bytes memory returndata) = address(this)
                    .delegatecall(data[i]);

                if (success) {
                    results[i] = returndata;
                } else {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }
        }

        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        require(l.status != 2, 'ReentrancyGuard: reentrant call');
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import "@solidstate/contracts/token/ERC1155/IERC1155.sol";
import "@solidstate/contracts/token/ERC20/IERC20.sol";
import "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import "@solidstate/contracts/utils/IWETH.sol";
import "@solidstate/contracts/utils/SafeCast.sol";
import "@solidstate/contracts/utils/SafeERC20.sol";

import "../libraries/OptionMath.sol";

import "../vendor/IPremiaPool.sol";

import "../vault/IVault.sol";

import "./AuctionStorage.sol";
import "./IAuctionEvents.sol";

/**
 * @title Knox Dutch Auction Internal Contract
 */

contract AuctionInternal is IAuctionEvents, OwnableInternal {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64Token for int128;
    using ABDKMath64x64Token for uint256;
    using AuctionStorage for AuctionStorage.Layout;
    using EnumerableSet for EnumerableSet.UintSet;
    using OptionMath for uint256;
    using OrderBook for OrderBook.Index;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    bool internal immutable isCall;
    uint8 internal immutable baseDecimals;
    uint8 internal immutable underlyingDecimals;

    IERC20 public immutable ERC20;
    IPremiaPool public immutable Pool;
    IVault public immutable Vault;
    IWETH public immutable WETH;

    constructor(
        bool _isCall,
        address pool,
        address vault,
        address weth
    ) {
        isCall = _isCall;

        Pool = IPremiaPool(pool);
        IPremiaPool.PoolSettings memory settings = Pool.getPoolSettings();
        address asset = isCall ? settings.underlying : settings.base;

        baseDecimals = IERC20Metadata(settings.base).decimals();
        underlyingDecimals = IERC20Metadata(settings.underlying).decimals();

        ERC20 = IERC20(asset);
        Vault = IVault(vault);
        WETH = IWETH(weth);
    }

    /************************************************
     *  ACCESS CONTROL
     ***********************************************/

    /**
     * @dev Throws if called by any account other than the vault
     */
    modifier onlyVault() {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        require(msg.sender == address(Vault), "!vault");
        _;
    }

    /**
     * @dev Throws if limit orders are not allowed
     * @param auction storage params
     */
    function _limitOrdersAllowed(AuctionStorage.Auction storage auction)
        internal
        view
    {
        require(
            AuctionStorage.Status.INITIALIZED == auction.status,
            "status != initialized"
        );
        _auctionHasNotEnded(auction);
    }

    /**
     * @dev Throws if market orders are not allowed
     * @param auction storage params
     */
    function _marketOrdersAllowed(AuctionStorage.Auction storage auction)
        internal
        view
    {
        require(
            AuctionStorage.Status.INITIALIZED == auction.status,
            "status != initialized"
        );
        _auctionHasStarted(auction);
        _auctionHasNotEnded(auction);
    }

    /**
     * @dev Throws if auction has not started.
     * @param auction storage params
     */
    function _auctionHasStarted(AuctionStorage.Auction storage auction)
        private
        view
    {
        require(auction.startTime > 0, "start time is not set");
        require(block.timestamp >= auction.startTime, "auction not started");
    }

    /**
     * @dev Throws if auction has ended.
     * @param auction storage params
     */
    function _auctionHasNotEnded(AuctionStorage.Auction storage auction)
        private
        view
    {
        require(auction.endTime > 0, "end time is not set");
        require(block.timestamp <= auction.endTime, "auction has ended");
    }

    /************************************************
     *  PRICING
     ***********************************************/

    /**
     * @notice returns the last price paid during the auction
     * @param auction storage params
     * @return price as 64x64 fixed point number
     */
    function _lastPrice64x64(AuctionStorage.Auction storage auction)
        internal
        view
        returns (int128)
    {
        return auction.lastPrice64x64;
    }

    /**
     * @notice calculates the current price using the price curve function
     * @param auction storage params
     * @return price as 64x64 fixed point number
     */
    function _priceCurve64x64(AuctionStorage.Auction storage auction)
        internal
        view
        returns (int128)
    {
        uint256 startTime = auction.startTime;
        uint256 totalTime = auction.endTime - auction.startTime;

        int128 maxPrice64x64 = auction.maxPrice64x64;
        int128 minPrice64x64 = auction.minPrice64x64;

        /**
         *
         * price curve equation:
         * assumes max price is always greater than min price
         * assumes the time remaining is in the range of 0 and 1
         * ------------------------------
         * time_remaning_percent(t) = (t - time_start) / time_total
         * price(t) = max_price - time_remaning_percent(t) * (max_price - min_price)
         *
         */

        if (block.timestamp <= startTime) return maxPrice64x64;
        if (block.timestamp >= auction.endTime) return minPrice64x64;

        uint256 elapsed = block.timestamp - startTime;
        int128 timeRemaining64x64 = elapsed.divu(totalTime);

        int128 x = maxPrice64x64.sub(minPrice64x64);
        int128 y = timeRemaining64x64.mul(x);
        return maxPrice64x64.sub(y);
    }

    /**
     * @notice returns the current price established by the price curve if the auction
     * is still ongoing, otherwise the last price paid is returned
     * @param auction storage params
     * @return price as 64x64 fixed point number
     */
    function _clearingPrice64x64(AuctionStorage.Auction storage auction)
        internal
        view
        returns (int128)
    {
        if (
            auction.status == AuctionStorage.Status.FINALIZED ||
            auction.status == AuctionStorage.Status.PROCESSED ||
            auction.status == AuctionStorage.Status.CANCELLED
        ) {
            return _lastPrice64x64(auction);
        }
        return _priceCurve64x64(auction);
    }

    /**
     * @notice calculates and sets the option max and min price
     * @param l auction storage layout
     * @param auction storage params
     * @param epoch epoch id
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     */
    function _setAuctionPrices(
        AuctionStorage.Layout storage l,
        AuctionStorage.Auction storage auction,
        uint64 epoch,
        int128 spot64x64,
        int128 timeToMaturity64x64
    ) internal {
        int128 strike64x64 = auction.strike64x64;

        // calculates the further OTM strike price
        int128 offsetAmount64x64 = strike64x64.mul(l.deltaOffset64x64);
        int128 offsetStrike64x64 =
            isCall
                ? strike64x64.add(offsetAmount64x64)
                : strike64x64.sub(offsetAmount64x64);

        /**
         * it is assumed that the rounded strike price will always be further ITM than the offset
         * strike price. the further ITM option will always be more expensive and will therefore
         * be used to determine the max price of the auction. likewise, the offset strike price
         * (further OTM) should resemble a cheaper option and it is therefore used as the min
         * option price in our auction.
         *
         *
         * Call Option
         * -----------
         * Strike    Rounded Strike             Offset Strike
         *   |  ---------> |                          |
         *   |             |                          |
         * -----------------------Price------------------------>
         *
         *
         * Put Option
         * -----------
         * Offset Strike              Rounded Strike    Strike
         *       |                           | <--------- |
         *       |                           |            |
         * -----------------------Price------------------------>
         *
         *
         */

        // calculates the auction max price using the strike price (further ITM)
        auction.maxPrice64x64 = l.Pricer.getBlackScholesPrice64x64(
            spot64x64,
            strike64x64,
            timeToMaturity64x64,
            isCall
        );

        // calculates the auction min price using the offset strike price (further OTM)
        auction.minPrice64x64 = l.Pricer.getBlackScholesPrice64x64(
            spot64x64,
            offsetStrike64x64,
            timeToMaturity64x64,
            isCall
        );

        if (isCall) {
            // denominates price in the collateral asset
            auction.maxPrice64x64 = auction.maxPrice64x64.div(spot64x64);
            auction.minPrice64x64 = auction.minPrice64x64.div(spot64x64);
        }

        emit AuctionPricesSet(
            epoch,
            strike64x64,
            offsetStrike64x64,
            spot64x64,
            auction.maxPrice64x64,
            auction.minPrice64x64
        );
    }

    /**
     * @notice validates the max and min prices
     * @param auction storage params
     * @param epoch epoch id
     */
    function _validateAuctionPrices(
        AuctionStorage.Auction storage auction,
        uint64 epoch
    ) internal {
        if (
            auction.maxPrice64x64 <= 0 ||
            auction.minPrice64x64 <= 0 ||
            auction.maxPrice64x64 <= auction.minPrice64x64
        ) {
            // if either price is 0 or the max price is less than or equal to the min price,
            // the auction should always be cancelled.
            _cancel(auction, epoch);
        }
    }

    /************************************************
     *  WITHDRAW
     ***********************************************/

    /**
     * @notice withdraws any amount(s) owed to the buyer (fill and/or refund)
     * @param l auction storage layout
     * @param epoch epoch id
     */
    function _withdraw(AuctionStorage.Layout storage l, uint64 epoch) internal {
        (uint256 refund, uint256 fill) =
            _previewWithdraw(l, false, epoch, msg.sender);

        // removes all unique order ids associated with epoch
        _removeUniqueOrderId(l, epoch, 0);

        // fetches the exercised value of the options
        (bool expired, uint256 exercisedAmount) =
            _getExerciseAmount(l, epoch, fill);

        if (expired) {
            if (exercisedAmount > 0) {
                // if expired ITM, adjust refund by the amount exercised
                refund += exercisedAmount;
            }

            // set fill to 0, buyer will not receive any long tokens
            fill = 0;
        }

        if (fill > 0) {
            // transfers long tokens to msg.sender
            Pool.safeTransferFrom(
                address(this),
                msg.sender,
                l.auctions[epoch].longTokenId,
                fill,
                ""
            );
        }

        if (refund > 0) {
            // transfers refunded premium to msg.sender
            ERC20.safeTransfer(msg.sender, refund);
        }

        emit OrderWithdrawn(epoch, msg.sender, refund, fill);
    }

    /**
     * @notice calculates amount(s) owed to the buyer
     * @param epoch epoch id
     * @param buyer address of buyer
     * @return amount refunded
     * @return amount filled
     */
    function _previewWithdraw(uint64 epoch, address buyer)
        internal
        returns (uint256, uint256)
    {
        AuctionStorage.Layout storage l = AuctionStorage.layout();
        return _previewWithdraw(l, true, epoch, buyer);
    }

    /**
     * @notice traverses the orderbook and returns the refund and fill amounts
     * @param l auction storage layout
     * @param epoch epoch id
     * @param buyer address of buyer
     * @return amount refunded
     * @return amount filled
     */
    function _previewWithdraw(
        AuctionStorage.Layout storage l,
        bool isPreview,
        uint64 epoch,
        address buyer
    ) private returns (uint256, uint256) {
        AuctionStorage.Auction storage auction = l.auctions[epoch];
        OrderBook.Index storage orderbook = l.orderbooks[epoch];

        uint256 refund;
        uint256 fill;

        int128 lastPrice64x64 = _clearingPrice64x64(auction);
        uint256 totalUnclaimedContracts = auction.totalUnclaimedContracts;

        // traverse the order book and return orders placed by the buyer until the end of the orderbook has been reached
        OrderBook.Data memory data = orderbook._getOrderById(orderbook._head());
        do {
            uint256 next = orderbook._getNextOrder(data.id);

            if (data.buyer == buyer) {
                uint256 claimed;
                uint256 paid = data.price64x64.mulu(data.size);

                if (
                    auction.status != AuctionStorage.Status.CANCELLED &&
                    totalUnclaimedContracts > 0 &&
                    data.price64x64 >= lastPrice64x64
                ) {
                    // if the auction has not been cancelled, and the order price is greater than or
                    // equal to the last price, fill the order and calculate the refund amount
                    uint256 cost = lastPrice64x64.mulu(data.size);

                    if (data.size > totalUnclaimedContracts) {
                        // if part of the current order exceeds the total contracts available, partially
                        // fill the order, and refund the remainder
                        cost = lastPrice64x64.mulu(totalUnclaimedContracts);
                        fill += totalUnclaimedContracts;
                        claimed += totalUnclaimedContracts;
                    } else {
                        // otherwise, fill the entire order
                        fill += data.size;
                        claimed += data.size;
                    }
                    // the refund takes the difference between the amount paid and the "true" cost of
                    // of the order. the "true" cost can be calculated when the clearing price has been
                    // set.
                    refund += paid - cost;
                } else {
                    // if no contracts are available, the auction has been cancelled, or the bid is too
                    // low, only send refund
                    refund += paid;
                }

                if (!isPreview) {
                    // if the buyer has a filled order, remove it from the unclaimed
                    // contract balance
                    auction.totalUnclaimedContracts -= claimed;

                    // when a withdrawal is made, remove the order from the order book
                    orderbook._remove(data.id);
                }

                // claimed amount is reset after every filled order
                claimed = 0;
            }

            if (totalUnclaimedContracts > 0) {
                if (data.size > totalUnclaimedContracts) {
                    totalUnclaimedContracts = 0;
                } else {
                    totalUnclaimedContracts -= data.size;
                }
            }

            data = orderbook._getOrderById(next);
        } while (data.id != 0);

        return (refund, fill);
    }

    /************************************************
     *  FINALIZE AUCTION
     ***********************************************/

    /**
     * @notice traverses the orderbook and checks if the auction has reached 100% utilization
     * @param l auction storage layout
     * @param epoch epoch id
     * @return true if the auction has reached 100% utilization
     */
    function _processOrders(AuctionStorage.Layout storage l, uint64 epoch)
        private
        returns (bool)
    {
        OrderBook.Index storage orderbook = l.orderbooks[epoch];
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        // if the total contracts has not been set for the auction, the vault contract will be
        // queried and the amount will be determined from the collateral in the vault.
        if (auction.totalContracts <= 0) {
            uint256 totalContracts = _getTotalContracts(auction);

            // auction is cancelled if there are no contracts available
            if (totalContracts <= 0) {
                _cancel(auction, epoch);
                return false;
            }

            auction.totalContracts = totalContracts;
        }

        uint256 totalContractsSold;
        int128 lastPrice64x64;

        // traverse the order book and sum the contracts sold until the utilization == 100% or
        // the end of the orderbook has been reached
        OrderBook.Data memory data = orderbook._getOrderById(orderbook._head());
        do {
            uint256 next = orderbook._getNextOrder(data.id);

            // orders in the order book are sorted by price in a descending order. if the
            // order price < clearing price the last order which should be accepeted has
            // been reached.
            if (data.price64x64 < _clearingPrice64x64(auction)) break;

            // checks if utilization >= 100%
            if (totalContractsSold + data.size >= auction.totalContracts) {
                auction.lastPrice64x64 = data.price64x64;
                auction.totalContractsSold = auction.totalContracts;
                return true;
            }

            totalContractsSold += data.size;
            lastPrice64x64 = data.price64x64;

            data = orderbook._getOrderById(next);
        } while (data.id != 0);

        /**
         * sets the last price reached in the order book equal to the last price paid in the auction.
         *
         *
         * Orderbook | price curve == 96
         * ---------
         * id -  price
         * 0  -  100
         * 1  -  97 --- last price
         * 2  -  95
         * */

        auction.lastPrice64x64 = lastPrice64x64;
        auction.totalContractsSold = totalContractsSold;
        return false;
    }

    /**
     * @notice determines whether the auction has reached finality. the end criteria for the auction are
     * met if the auction has reached 100% utilization or the end time has been exceeded.
     * @param l auction storage layout
     * @param auction storage params
     * @param epoch epoch id
     */
    function _finalizeAuction(
        AuctionStorage.Layout storage l,
        AuctionStorage.Auction storage auction,
        uint64 epoch
    ) internal {
        _validateAuctionPrices(auction, epoch);

        if (
            auction.status != AuctionStorage.Status.CANCELLED &&
            (_processOrders(l, epoch) || block.timestamp > auction.endTime)
        ) {
            if (auction.totalContractsSold > 0) {
                auction.totalUnclaimedContracts = auction.totalContractsSold;
                _updateStatus(auction, AuctionStorage.Status.FINALIZED, epoch);
            } else {
                _cancel(auction, epoch);
            }
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice calculates the total number of contracts that can be sold during the auction
     * @param auction storage params
     * @return total contracts available
     */
    function _getTotalContracts(AuctionStorage.Auction storage auction)
        private
        view
        returns (uint256)
    {
        uint256 collateral = Vault.totalCollateral();
        uint256 reserves = Vault.previewReserves();

        return
            collateral > reserves
                ? (collateral - reserves).fromCollateralToContracts(
                    isCall,
                    baseDecimals,
                    auction.strike64x64
                )
                : 0;
    }

    /************************************************
     *  PURCHASE HELPERS
     ***********************************************/

    /**
     * @notice checks whether the limit order parameters are valid and returns the cost
     * @param l auction storage layout
     * @param price64x64 max price as 64x64 fixed point number
     * @param size amount of contracts
     * @return cost of the order given the size and price
     */
    function _validateLimitOrder(
        AuctionStorage.Layout storage l,
        int128 price64x64,
        uint256 size
    ) internal view returns (uint256) {
        require(price64x64 > 0, "price <= 0");
        require(size >= l.minSize, "size < minimum");

        uint256 cost = price64x64.mulu(size);
        return cost;
    }

    /**
     * @notice checks whether the market order parameters are valid and returns the price and cost
     * @param l auction storage layout
     * @param auction storage params
     * @param size amount of contracts
     * @param maxCost max cost of buyer is willing to pay
     * @return price established by the price curve
     * @return cost of the order given the size and price
     */
    function _validateMarketOrder(
        AuctionStorage.Layout storage l,
        AuctionStorage.Auction storage auction,
        uint256 size,
        uint256 maxCost
    ) internal view returns (int128, uint256) {
        require(size >= l.minSize, "size < minimum");

        int128 price64x64 = _priceCurve64x64(auction);
        uint256 cost = price64x64.mulu(size);

        require(maxCost >= cost, "cost > maxCost");
        return (price64x64, cost);
    }

    /**
     * @notice transfers the premium to the buyer if a refund is due, ortherwise, pull funds
     * from buyer if funds are owed to the auction contract.
     * @param credited amount already paid by the buyer
     * @param cost total amount which must be paid by the buyer
     * @param buyer account being debited or credited
     */
    function _transferAssets(
        uint256 credited,
        uint256 cost,
        address buyer
    ) internal {
        if (credited > cost) {
            // refund buyer the amount overpaid
            ERC20.safeTransfer(buyer, credited - cost);
        } else if (cost > credited) {
            // an approve() by the msg.sender is required beforehand
            ERC20.safeTransferFrom(buyer, address(this), cost - credited);
        }
    }

    /**
     * @notice checks whether the market order parameters are valid and returns the price and cost
     * @param l auction storage layout
     * @param auction storage params
     * @param epoch epoch id
     * @param price64x64 max price as 64x64 fixed point number
     * @param size amount of contracts
     * @param isLimitOrder true, if the order is a limit order
     */
    function _addOrder(
        AuctionStorage.Layout storage l,
        AuctionStorage.Auction storage auction,
        uint64 epoch,
        int128 price64x64,
        uint256 size,
        bool isLimitOrder
    ) internal {
        uint128 orderId =
            l.orderbooks[epoch]
                ._insert(price64x64, size, msg.sender)
                .toUint128();

        // format the unique order id and add it to storage
        uint256 uoid = AuctionStorage._formatUniqueOrderId(epoch, orderId);
        l.uoids[msg.sender].add(uoid);

        if (block.timestamp >= auction.startTime) {
            _finalizeAuction(l, auction, epoch);
        }

        emit OrderAdded(
            epoch,
            orderId,
            msg.sender,
            price64x64,
            size,
            isLimitOrder
        );
    }

    /**
     * @notice wraps ETH sent to the contract and credits the amount, if the collateral asset
     * is not WETH, the transaction will revert
     * @param amount total collateral deposited
     * @return credited amount
     */
    function _wrapNativeToken(uint256 amount) internal returns (uint256) {
        uint256 credit;

        if (msg.value > 0) {
            require(address(ERC20) == address(WETH), "collateral != wETH");

            if (msg.value > amount) {
                // if the ETH amount is greater than the amount needed, it will be sent
                // back to the msg.sender
                unchecked {
                    (bool success, ) =
                        payable(msg.sender).call{value: msg.value - amount}("");

                    require(success, "ETH refund failed");

                    credit = amount;
                }
            } else {
                credit = msg.value;
            }

            WETH.deposit{value: credit}();
        }

        return credit;
    }

    /**
     * @notice pull token from user, send to exchangeHelper trigger a trade from
     * ExchangeHelper, and credits the amount
     * @param Exchange ExchangeHelper contract interface
     * @param s swap arguments
     * @param tokenOut token to swap for. should always equal to the collateral asset
     * @return credited amount
     */
    function _swapForPoolTokens(
        IExchangeHelper Exchange,
        IExchangeHelper.SwapArgs calldata s,
        address tokenOut
    ) internal returns (uint256) {
        if (msg.value > 0) {
            require(s.tokenIn == address(WETH), "tokenIn != wETH");
            WETH.deposit{value: msg.value}();
            WETH.safeTransfer(address(Exchange), msg.value);
        }

        if (s.amountInMax > 0) {
            IERC20(s.tokenIn).safeTransferFrom(
                msg.sender,
                address(Exchange),
                s.amountInMax
            );
        }

        uint256 amountCredited =
            Exchange.swapWithToken(
                s.tokenIn,
                tokenOut,
                s.amountInMax + msg.value,
                s.callee,
                s.allowanceTarget,
                s.data,
                s.refundAddress
            );

        require(
            amountCredited >= s.amountOutMin,
            "not enough output from trade"
        );

        return amountCredited;
    }

    /************************************************
     * HELPERS
     ***********************************************/

    /**
     * @notice cancels all orders and finalizes the auction
     * @param auction the auction to cancel
     * @param epoch epoch id
     */
    function _cancel(AuctionStorage.Auction storage auction, uint64 epoch)
        internal
    {
        auction.totalPremiums = 0;
        _updateStatus(auction, AuctionStorage.Status.CANCELLED, epoch);
    }

    /**
     * @notice calculates the expected proceeds of the option if it has expired
     * @param epoch epoch id
     * @param size amount of contracts
     * @return true if the option has expired
     * @return the exercised amount
     */
    function _getExerciseAmount(
        AuctionStorage.Layout storage l,
        uint64 epoch,
        uint256 size
    ) private view returns (bool, uint256) {
        AuctionStorage.Auction storage auction = l.auctions[epoch];

        uint64 expiry = auction.expiry;
        int128 strike64x64 = auction.strike64x64;

        if (block.timestamp < expiry) return (false, 0);

        int128 spot64x64 = Pool.getPriceAfter64x64(expiry);
        uint256 amount;

        if (isCall && spot64x64 > strike64x64) {
            amount = spot64x64.sub(strike64x64).div(spot64x64).mulu(size);
        } else if (!isCall && strike64x64 > spot64x64) {
            uint256 value = strike64x64.sub(spot64x64).mulu(size);

            // converts the value to the base asset amount, this is particularly important where the
            // the decimals of the underlying are different from the base (e.g. wBTC/DAI)
            amount = OptionMath.toBaseTokenAmount(
                underlyingDecimals,
                baseDecimals,
                value
            );
        }

        return (true, amount);
    }

    /**
     * @notice removes the active unique order id from uoids mapping
     * @param l auction storage layout
     * @param epoch epoch id
     * @param orderId order id
     */
    function _removeUniqueOrderId(
        AuctionStorage.Layout storage l,
        uint64 epoch,
        uint128 orderId
    ) internal {
        EnumerableSet.UintSet storage uoids = l.uoids[msg.sender];

        unchecked {
            for (uint256 i; i < uoids.length(); ++i) {
                uint256 uoid = uoids.at(i);
                (, uint64 _epoch, uint128 _orderId) =
                    AuctionStorage._parseUniqueOrderId(uoid);

                if (
                    (orderId == 0 && _epoch == epoch) ||
                    (_orderId == orderId && _epoch == epoch)
                ) {
                    uoids.remove(uoid);
                }
            }
        }
    }

    function _updateStatus(
        AuctionStorage.Auction storage auction,
        AuctionStorage.Status status,
        uint64 epoch
    ) internal {
        auction.status = status;
        emit AuctionStatusSet(epoch, auction.status);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/introspection/IERC165.sol";
import "@solidstate/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@solidstate/contracts/utils/IMulticall.sol";

import "../vendor/IExchangeHelper.sol";

import "./AuctionStorage.sol";
import "./IAuctionEvents.sol";

/**
 * @title Knox Auction Interface
 */

interface IAuction is IAuctionEvents, IERC165, IERC1155Receiver, IMulticall {
    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @notice sets the percent offset from delta strike
     * @param newDeltaOffset64x64 new percent offset value as a 64x64 fixed point number
     */
    function setDeltaOffset64x64(int128 newDeltaOffset64x64) external;

    /**
     * @notice sets a new Exchange Helper contract
     * @param newExchangeHelper new Exchange Helper contract address
     */
    function setExchangeHelper(address newExchangeHelper) external;

    /**
     * @notice sets a new minimum order size
     * @param newMinSize new minimum order size
     */
    function setMinSize(uint256 newMinSize) external;

    /**
     * @notice sets the new pricer
     * @dev the pricer contract address must be set during the vault initialization
     * @param newPricer address of the new pricer
     */
    function setPricer(address newPricer) external;

    /************************************************
     *  INITIALIZE AUCTION
     ***********************************************/

    /**
     * @notice initializes a new auction
     * @param initAuction auction parameters
     */
    function initialize(AuctionStorage.InitAuction memory initAuction) external;

    /**
     * @notice sets the auction max/min prices
     * @param epoch epoch id
     */
    function setAuctionPrices(uint64 epoch) external;

    /************************************************
     *  PRICING
     ***********************************************/

    /**
     * @notice returns the last price paid during the auction
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function lastPrice64x64(uint64 epoch) external view returns (int128);

    /**
     * @notice calculates the current price using the price curve function
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function priceCurve64x64(uint64 epoch) external view returns (int128);

    /**
     * @notice returns the current price established by the price curve if the auction
     * is still ongoing, otherwise the last price paid is returned
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function clearingPrice64x64(uint64 epoch) external view returns (int128);

    /************************************************
     *  PURCHASE
     ***********************************************/

    /**
     * @notice adds an order specified by the price and size
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param epoch epoch id
     * @param price64x64 max price as 64x64 fixed point number
     * @param size amount of contracts
     */
    function addLimitOrder(
        uint64 epoch,
        int128 price64x64,
        uint256 size
    ) external payable;

    /**
     * @notice swaps into the collateral asset and adds an order specified by the price and size
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     * @param epoch epoch id
     * @param price64x64 max price as 64x64 fixed point number
     * @param size amount of contracts
     */
    function swapAndAddLimitOrder(
        IExchangeHelper.SwapArgs calldata s,
        uint64 epoch,
        int128 price64x64,
        uint256 size
    ) external payable;

    /**
     * @notice cancels an order
     * @dev sender must approve contract
     * @param epoch epoch id
     * @param orderId order id
     */
    function cancelLimitOrder(uint64 epoch, uint128 orderId) external;

    /**
     * @notice adds an order specified by size only
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param epoch epoch id
     * @param size amount of contracts
     * @param maxCost max cost of buyer is willing to pay
     */
    function addMarketOrder(
        uint64 epoch,
        uint256 size,
        uint256 maxCost
    ) external payable;

    /**
     * @notice swaps into the collateral asset and adds an order specified by size only
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     * @param epoch epoch id
     * @param size amount of contracts
     * @param maxCost max cost of buyer is willing to pay
     */
    function swapAndAddMarketOrder(
        IExchangeHelper.SwapArgs calldata s,
        uint64 epoch,
        uint256 size,
        uint256 maxCost
    ) external payable;

    /************************************************
     *  WITHDRAW
     ***********************************************/

    /**
     * @notice withdraws any amount(s) owed to the buyer (fill and/or refund)
     * @param epoch epoch id
     */
    function withdraw(uint64 epoch) external;

    /**
     * @notice calculates amount(s) owed to the buyer
     * @param epoch epoch id
     * @return amount refunded
     * @return amount filled
     */
    function previewWithdraw(uint64 epoch) external returns (uint256, uint256);

    /**
     * @notice calculates amount(s) owed to the buyer
     * @param epoch epoch id
     * @param buyer address of buyer
     * @return amount refunded
     * @return amount filled
     */
    function previewWithdraw(uint64 epoch, address buyer)
        external
        returns (uint256, uint256);

    /************************************************
     *  FINALIZE AUCTION
     ***********************************************/

    /**
     * @notice determines whether the auction has reached finality. the end criteria for the auction are
     * met if the auction has reached 100% utilization or the end time has been exceeded.
     * @param epoch epoch id
     */
    function finalizeAuction(uint64 epoch) external;

    /**
     * @notice transfers premiums and updates auction state
     * @param epoch epoch id
     * @return amount in premiums paid during auction
     * @return total number of contracts sold
     */
    function processAuction(uint64 epoch) external returns (uint256, uint256);

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the auction parameters
     * @param epoch epoch id
     * @return auction parameters
     */
    function getAuction(uint64 epoch)
        external
        view
        returns (AuctionStorage.Auction memory);

    /**
     * @notice returns percent delta offset
     * @return percent delta offset as a 64x64 fixed point number
     */
    function getDeltaOffset64x64() external view returns (int128);

    /**
     * @notice returns the minimum order size
     * @return minimum order size
     */
    function getMinSize() external view returns (uint256);

    /**
     * @notice returns the order from the auction orderbook
     * @param epoch epoch id
     * @param orderId order id
     * @return order from auction orderbook
     */
    function getOrderById(uint64 epoch, uint128 orderId)
        external
        view
        returns (OrderBook.Data memory);

    /**
     * @notice returns the status of the auction
     * @param epoch epoch id
     * @return auction status
     */
    function getStatus(uint64 epoch)
        external
        view
        returns (AuctionStorage.Status);

    /**
     * @notice returns the stored total number of contracts that can be sold during the auction
     * returns 0 if the auction has not started
     * @param epoch epoch id
     * @return total number of contracts which may be sold
     */
    function getTotalContracts(uint64 epoch) external view returns (uint256);

    /**
     * @notice returns the total number of contracts sold
     * @param epoch epoch id
     * @return total number of contracts sold
     */
    function getTotalContractsSold(uint64 epoch)
        external
        view
        returns (uint256);

    /**
     * @notice returns the active unique order ids
     * @param buyer address of buyer
     * @return array of unique order ids
     */
    function getUniqueOrderIds(address buyer)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from './IERC1155Internal.sol';
import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(address holder, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../token/ERC20/IERC20.sol';
import { IERC20Metadata } from '../token/ERC20/metadata/IERC20Metadata.sol';

/**
 * @title WETH (Wrapped ETH) interface
 */
interface IWETH is IERC20, IERC20Metadata {
    /**
     * @notice convert ETH to WETH
     */
    function deposit() external payable;

    /**
     * @notice convert WETH to ETH
     * @dev if caller is a contract, it should have a fallback or receive function
     * @param amount quantity of WETH to convert, denominated in wei
     */
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Helper library for safe casting of uint and int values
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, 'SafeCast: value does not fit');
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, 'SafeCast: value does not fit');
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, 'SafeCast: value does not fit');
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, 'SafeCast: value does not fit');
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, 'SafeCast: value does not fit');
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, 'SafeCast: value does not fit');
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, 'SafeCast: value does not fit');
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, 'SafeCast: value must be positive');
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            'SafeCast: value does not fit'
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            'SafeCast: value does not fit'
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            'SafeCast: value does not fit'
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            'SafeCast: value does not fit'
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            'SafeCast: value does not fit'
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            'SafeCast: value does not fit'
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../token/ERC20/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                'SafeERC20: decreased allowance below zero'
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@solidstate/abdk-math-extensions/contracts/ABDKMath64x64Token.sol";

/**
 * @title Option Math Helper Library
 */

library OptionMath {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64Token for int128;
    using ABDKMath64x64Token for uint256;

    int256 private constant ONE = 10000000000000000000;

    struct Value {
        int256 value;
        int256 ruler;
    }

    /**
     * @custom:author Yaojin Sun
     * @notice applies ceiling to the second highest place value of a positive 64x64 fixed point number
     * @param x 64x64 fixed point number
     * @return rounded 64x64 fixed point number
     */
    function ceil64x64(int128 x) internal pure returns (int128) {
        require(x > 0);

        (int256 integer, Value[3] memory values) = _getPositivePlaceValues(x);

        // if the summation of first and second values is equal to integer, the integer has already been rounded
        if (
            values[0].ruler *
                values[0].value +
                values[1].ruler *
                values[1].value ==
            integer
        ) {
            return int128((integer << 64) / ONE);
        }

        return
            int128(
                (((values[0].ruler * values[0].value) +
                    (values[1].ruler * (values[1].value + 1))) << 64) / ONE
            );
    }

    /**
     * @custom:author Yaojin Sun
     * @notice applies floor to the second highest place value of a positive 64x64 fixed point number
     * @param x 64x64 fixed point number
     * @return rounded 64x64 fixed point number
     */
    function floor64x64(int128 x) internal pure returns (int128) {
        require(x > 0);

        (, Value[3] memory values) = _getPositivePlaceValues(x);

        // No matter whether third value is non-zero or not, we ONLY need to keep the first and second places.
        int256 res =
            (values[0].ruler * values[0].value) +
                (values[1].ruler * values[1].value);
        return int128((res << 64) / ONE);
    }

    function _getPositivePlaceValues(int128 x)
        private
        pure
        returns (int256, Value[3] memory)
    {
        // move the decimal part to integer by multiplying 10...0
        int256 integer = (int256(x) * ONE) >> 64;

        // scan and identify the highest position
        int256 ruler = 100000000000000000000000000000000000000; // 10^38
        while (integer < ruler) {
            ruler = ruler / 10;
        }

        Value[3] memory values;

        // find the first/second/third largest places and there value
        values[0] = Value(0, 0);
        values[1] = Value(0, 0);
        values[2] = Value(0, 0);

        // setup the first place value
        values[0].ruler = ruler;
        if (values[0].ruler != 0) {
            values[0].value = (integer / values[0].ruler) % 10;

            // setup the second place value
            values[1].ruler = ruler / 10;
            if (values[1].ruler != 0) {
                values[1].value = (integer / values[1].ruler) % 10;

                // setup the third place value
                values[2].ruler = ruler / 100;
                if (values[2].ruler != 0) {
                    values[2].value = (integer / values[2].ruler) % 10;
                }
            }
        }

        return (integer, values);
    }

    /**
     * @notice converts the value to the base token amount
     * @param underlyingDecimals decimal precision of the underlying asset
     * @param baseDecimals decimal precision of the base asset
     * @param value amount to convert
     * @return decimal representation of base token amount
     */
    function toBaseTokenAmount(
        uint8 underlyingDecimals,
        uint8 baseDecimals,
        uint256 value
    ) internal pure returns (uint256) {
        int128 value64x64 = value.fromDecimals(underlyingDecimals);
        return value64x64.toDecimals(baseDecimals);
    }

    /**
     * @notice calculates the collateral asset amount from the number of contracts
     * @param isCall option type, true if call option
     * @param underlyingDecimals decimal precision of the underlying asset
     * @param baseDecimals decimal precision of the base asset
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @return collateral asset amount
     */
    function fromContractsToCollateral(
        uint256 contracts,
        bool isCall,
        uint8 underlyingDecimals,
        uint8 baseDecimals,
        int128 strike64x64
    ) internal pure returns (uint256) {
        if (strike64x64 == 0) {
            return 0;
        }

        if (isCall) {
            return contracts;
        }

        return
            toBaseTokenAmount(
                underlyingDecimals,
                baseDecimals,
                strike64x64.mulu(contracts)
            );
    }

    /**
     * @notice calculates number of contracts from the collateral asset amount
     * @param isCall option type, true if call option
     * @param baseDecimals decimal precision of the base asset
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @return number of contracts
     */
    function fromCollateralToContracts(
        uint256 collateral,
        bool isCall,
        uint8 baseDecimals,
        int128 strike64x64
    ) internal pure returns (uint256) {
        if (strike64x64 == 0) {
            return 0;
        }

        if (isCall) {
            return collateral;
        }

        int128 collateral64x64 = collateral.fromDecimals(baseDecimals);
        return collateral64x64.div(strike64x64).toDecimals(baseDecimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPremiaPool {
    struct PoolSettings {
        address underlying;
        address base;
        address underlyingOracle;
        address baseOracle;
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice exercise option on behalf of holder
     * @param holder owner of long option tokens to exercise
     * @param longTokenId long option token id
     * @param contractSize quantity of tokens to exercise
     */
    function exerciseFrom(
        address holder,
        uint256 longTokenId,
        uint256 contractSize
    ) external;

    /**
     * @notice get fundamental pool attributes
     * @return structured PoolSettings
     */
    function getPoolSettings() external view returns (PoolSettings memory);

    /**
     * @notice get first oracle price update after timestamp. If no update has been registered yet,
     * return current price feed spot price
     * @param timestamp timestamp to query
     * @return spot64x64 64x64 fixed point representation of price
     */
    function getPriceAfter64x64(uint256 timestamp)
        external
        view
        returns (int128 spot64x64);

    /**
     * @notice process expired option, freeing liquidity and distributing profits
     * @param longTokenId long option token id
     * @param contractSize quantity of tokens to process
     */
    function processExpired(uint256 longTokenId, uint256 contractSize) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice set timestamp after which reinvestment is disabled
     * @param timestamp timestamp to begin divestment
     * @param isCallPool whether we set divestment timestamp for the call pool or put pool
     */
    function setDivestmentTimestamp(uint64 timestamp, bool isCallPool) external;

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice force update of oracle price and pending deposit pool
     */
    function update() external;

    /**
     * @notice redeem pool share tokens for underlying asset
     * @param amount quantity of share tokens to redeem
     * @param isCallPool whether to deposit underlying in the call pool or base in the put pool
     */
    function withdraw(uint256 amount, bool isCallPool) external;

    /**
     * @notice write option without using liquidity from the pool on behalf of another address
     * @param underwriter underwriter of the option from who collateral will be deposited
     * @param longReceiver address who will receive the long token (Can be the underwriter)
     * @param maturity timestamp of option maturity
     * @param strike64x64 64x64 fixed point representation of strike price
     * @param contractSize quantity of option contract tokens to write
     * @param isCall whether this is a call or a put
     * @return longTokenId token id of the long call
     * @return shortTokenId token id of the short option
     */
    function writeFrom(
        address underwriter,
        address longReceiver,
        uint64 maturity,
        int128 strike64x64,
        uint256 contractSize,
        bool isCall
    ) external payable returns (uint256 longTokenId, uint256 shortTokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../vendor/IPremiaPool.sol";

import "./IVaultAdmin.sol";
import "./IVaultBase.sol";
import "./IVaultEvents.sol";
import "./IVaultView.sol";

/**
 * @title Knox Vault Interface
 */

interface IVault is IVaultAdmin, IVaultBase, IVaultEvents, IVaultView {
    /**
     * @notice gets the collateral asset ERC20 interface
     * @return ERC20 interface
     */
    function ERC20() external view returns (IERC20);

    /**
     * @notice gets the pool interface
     * @return pool interface
     */
    function Pool() external view returns (IPremiaPool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/utils/EnumerableSet.sol";

import "../pricer/IPricer.sol";

import "../vendor/IExchangeHelper.sol";

import "./OrderBook.sol";

/**
 * @title Knox Dutch Auction Diamond Storage Library
 */

library AuctionStorage {
    using OrderBook for OrderBook.Index;

    struct InitAuction {
        uint64 epoch;
        uint64 expiry;
        int128 strike64x64;
        uint256 longTokenId;
        uint256 startTime;
        uint256 endTime;
    }

    enum Status {UNINITIALIZED, INITIALIZED, FINALIZED, PROCESSED, CANCELLED}

    struct Auction {
        // status of the auction
        Status status;
        // option expiration timestamp
        uint64 expiry;
        // option strike price
        int128 strike64x64;
        // auction max price
        int128 maxPrice64x64;
        // auction min price
        int128 minPrice64x64;
        // last price paid during the auction
        int128 lastPrice64x64;
        // auction start timestamp
        uint256 startTime;
        // auction end timestamp
        uint256 endTime;
        // auction processed timestamp
        uint256 processedTime;
        // total contracts available
        uint256 totalContracts;
        // total contracts sold
        uint256 totalContractsSold;
        // total unclaimed contracts
        uint256 totalUnclaimedContracts;
        // total premiums collected
        uint256 totalPremiums;
        // option long token id
        uint256 longTokenId;
    }

    struct Layout {
        // percent offset from delta strike
        int128 deltaOffset64x64;
        // minimum order size
        uint256 minSize;
        // mapping of auctions to epoch id (epoch id -> auction)
        mapping(uint64 => Auction) auctions;
        // mapping of order books to epoch id (epoch id -> order book)
        mapping(uint64 => OrderBook.Index) orderbooks;
        // mapping of unique order ids (uoids) to buyer addresses (buyer -> uoid)
        mapping(address => EnumerableSet.UintSet) uoids;
        // ExchangeHelper contract interface
        IExchangeHelper Exchange;
        // Pricer contract interface
        IPricer Pricer;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("knox.contracts.storage.Auction");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the auction parameters
     * @param epoch epoch id
     * @return auction parameters
     */
    function _getAuction(uint64 epoch) internal view returns (Auction memory) {
        return layout().auctions[epoch];
    }

    /**
     * @notice returns percent delta offset
     * @return percent delta offset as a 64x64 fixed point number
     */
    function _getDeltaOffset64x64() internal view returns (int128) {
        return layout().deltaOffset64x64;
    }

    /**
     * @notice returns the minimum order size
     * @return minimum order size
     */
    function _getMinSize() internal view returns (uint256) {
        return layout().minSize;
    }

    /**
     * @notice returns the order from the auction orderbook
     * @param epoch epoch id
     * @param orderId order id
     * @return order from auction orderbook
     */
    function _getOrderById(uint64 epoch, uint128 orderId)
        internal
        view
        returns (OrderBook.Data memory)
    {
        OrderBook.Index storage orderbook = layout().orderbooks[epoch];
        return orderbook._getOrderById(orderId);
    }

    /**
     * @notice returns the status of the auction
     * @param epoch epoch id
     * @return auction status
     */
    function _getStatus(uint64 epoch)
        internal
        view
        returns (AuctionStorage.Status)
    {
        return layout().auctions[epoch].status;
    }

    /**
     * @notice returns the stored total number of contracts that can be sold during the auction
     * returns 0 if the auction has not started
     * @param epoch epoch id
     * @return total number of contracts which may be sold
     */
    function _getTotalContracts(uint64 epoch) internal view returns (uint256) {
        return layout().auctions[epoch].totalContracts;
    }

    /**
     * @notice returns the total number of contracts sold
     * @param epoch epoch id
     * @return total number of contracts sold
     */
    function _getTotalContractsSold(uint64 epoch)
        internal
        view
        returns (uint256)
    {
        return layout().auctions[epoch].totalContractsSold;
    }

    /************************************************
     * HELPERS
     ***********************************************/

    /**
     * @notice calculates the unique order id
     * @param epoch epoch id
     * @param orderId order id
     * @return unique order id
     */
    function _formatUniqueOrderId(uint64 epoch, uint128 orderId)
        internal
        view
        returns (uint256)
    {
        // uses the first 8 bytes of the contract address to salt uoid
        bytes8 salt = bytes8(bytes20(address(this)));
        return
            (uint256(uint64(salt)) << 192) +
            (uint256(epoch) << 128) +
            uint256(orderId);
    }

    /**
     * @notice derives salt, epoch id, and order id from the unique order id
     * @param uoid unique order id
     * @return salt
     * @return epoch id
     * @return order id
     */
    function _parseUniqueOrderId(uint256 uoid)
        internal
        pure
        returns (
            bytes8,
            uint64,
            uint128
        )
    {
        uint64 salt;
        uint64 epoch;
        uint128 orderId;

        assembly {
            salt := shr(192, uoid)
            epoch := shr(128, uoid)
            orderId := uoid
        }

        return (bytes8(salt), epoch, orderId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuctionStorage.sol";

/**
 * @title Knox Auction Events Interface
 */

interface IAuctionEvents {
    /**
     * @notice emitted when the auction max/min prices have been set
     * @param epoch epoch id
     * @param strike64x64 strike price as a 64x64 fixed point number
     * @param offsetStrike64x64 offset strike price as a 64x64 fixed point number
     * @param spot64x64 spot price as a 64x64 fixed point number
     * @param maxPrice64x64 max price as a 64x64 fixed point number
     * @param minPrice64x64 min price as a 64x64 fixed point number
     */
    event AuctionPricesSet(
        uint64 indexed epoch,
        int128 strike64x64,
        int128 offsetStrike64x64,
        int128 spot64x64,
        int128 maxPrice64x64,
        int128 minPrice64x64
    );

    /**
     * @notice emitted when the exchange auction status is updated
     * @param epoch epoch id
     * @param status auction status
     */
    event AuctionStatusSet(uint64 indexed epoch, AuctionStorage.Status status);

    /**
     * @notice emitted when the delta offset is updated
     * @param oldDeltaOffset previous delta offset
     * @param newDeltaOffset new delta offset
     * @param caller address of admin
     */
    event DeltaOffsetSet(
        int128 oldDeltaOffset,
        int128 newDeltaOffset,
        address caller
    );

    /**
     * @notice emitted when the exchange helper contract address is updated
     * @param oldExchangeHelper previous exchange helper address
     * @param newExchangeHelper new exchange helper address
     * @param caller address of admin
     */
    event ExchangeHelperSet(
        address oldExchangeHelper,
        address newExchangeHelper,
        address caller
    );

    /**
     * @notice emitted when an external function reverts
     * @param message error message
     */
    event Log(string message);

    /**
     * @notice emitted when the minimum order size is updated
     * @param oldMinSize previous minimum order size
     * @param newMinSize new minimum order size
     * @param caller address of admin
     */
    event MinSizeSet(uint256 oldMinSize, uint256 newMinSize, address caller);

    /**
     * @notice emitted when a market or limit order has been placed
     * @param epoch epoch id
     * @param orderId order id
     * @param buyer address of buyer
     * @param price64x64 price paid as a 64x64 fixed point number
     * @param size quantity of options purchased
     * @param isLimitOrder true if order is a limit order
     */
    event OrderAdded(
        uint64 indexed epoch,
        uint128 orderId,
        address buyer,
        int128 price64x64,
        uint256 size,
        bool isLimitOrder
    );

    /**
     * @notice emitted when a limit order has been cancelled
     * @param epoch epoch id
     * @param orderId order id
     * @param buyer address of buyer
     */
    event OrderCanceled(uint64 indexed epoch, uint128 orderId, address buyer);

    /**
     * @notice emitted when an order (filled or unfilled) is withdrawn
     * @param epoch epoch id
     * @param buyer address of buyer
     * @param refund amount sent back to the buyer as a result of an overpayment
     * @param fill amount in long token contracts sent to the buyer
     */
    event OrderWithdrawn(
        uint64 indexed epoch,
        address buyer,
        uint256 refund,
        uint256 fill
    );

    /**
     * @notice emitted when the pricer contract address is updated
     * @param oldPricer previous pricer address
     * @param newPricer new pricer address
     * @param caller address of admin
     */
    event PricerSet(address oldPricer, address newPricer, address caller);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';

/**
 * @title SolidState token extensions for ABDKMath64x64 library
 */
library ABDKMath64x64Token {
    using ABDKMath64x64 for int128;

    /**
     * @notice convert 64x64 fixed point representation of token amount to decimal
     * @param value64x64 64x64 fixed point representation of token amount
     * @param decimals token display decimals
     * @return value decimal representation of token amount
     */
    function toDecimals(int128 value64x64, uint8 decimals)
        internal
        pure
        returns (uint256 value)
    {
        value = value64x64.mulu(10**decimals);
    }

    /**
     * @notice convert decimal representation of token amount to 64x64 fixed point
     * @param value decimal representation of token amount
     * @param decimals token display decimals
     * @return value64x64 64x64 fixed point representation of token amount
     */
    function fromDecimals(uint256 value, uint8 decimals)
        internal
        pure
        returns (int128 value64x64)
    {
        value64x64 = ABDKMath64x64.divu(value, 10**decimals);
    }

    /**
     * @notice convert 64x64 fixed point representation of token amount to wei (18 decimals)
     * @param value64x64 64x64 fixed point representation of token amount
     * @return value wei representation of token amount
     */
    function toWei(int128 value64x64) internal pure returns (uint256 value) {
        value = toDecimals(value64x64, 18);
    }

    /**
     * @notice convert wei representation (18 decimals) of token amount to 64x64 fixed point
     * @param value wei representation of token amount
     * @return value64x64 64x64 fixed point representation of token amount
     */
    function fromWei(uint256 value) internal pure returns (int128 value64x64) {
        value64x64 = fromDecimals(value, 18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultStorage.sol";

/**
 * @title Knox Vault Admin Interface
 */

interface IVaultAdmin {
    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @notice sets the new auction
     * @dev the auction contract address must be set during the vault initialization
     * @param newAuction address of the new auction
     */
    function setAuction(address newAuction) external;

    /**
     * @notice sets the start and end offsets for the auction
     * @param newStartOffset new start offset
     * @param newEndOffset new end offset
     */
    function setAuctionWindowOffsets(
        uint256 newStartOffset,
        uint256 newEndOffset
    ) external;

    /**
     * @notice sets the option delta value
     * @param newDelta64x64 new option delta value as a 64x64 fixed point number
     */
    function setDelta64x64(int128 newDelta64x64) external;

    /**
     * @notice sets the new fee recipient
     * @param newFeeRecipient address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external;

    /**
     * @notice sets the new keeper
     * @param newKeeper address of the new keeper
     */
    function setKeeper(address newKeeper) external;

    /**
     * @notice sets the new pricer
     * @dev the pricer contract address must be set during the vault initialization
     * @param newPricer address of the new pricer
     */
    function setPricer(address newPricer) external;

    /**
     * @notice sets the new queue
     * @dev the queue contract address must be set during the vault initialization
     * @param newQueue address of the new queue
     */
    function setQueue(address newQueue) external;

    /**
     * @notice sets the performance fee for the vault
     * @param newPerformanceFee64x64 performance fee as a 64x64 fixed point number
     */
    function setPerformanceFee64x64(int128 newPerformanceFee64x64) external;

    /************************************************
     *  INITIALIZE AUCTION
     ***********************************************/

    /**
     * @notice sets the option parameters which will be sold, then initializes the auction
     */
    function initializeAuction() external;

    /************************************************
     *  INITIALIZE EPOCH
     ***********************************************/

    /**
     * @notice collects performance fee from epoch income, processes the queued deposits,
     * increments the epoch id, then sets the auction prices
     * @dev it assumed that an auction has already been initialized
     */
    function initializeEpoch() external;

    /************************************************
     *  PROCESS AUCTION
     ***********************************************/

    /**
     * @notice processes the auction when it has been finalized or cancelled
     * @dev it assumed that an auction has already been initialized and the auction prices
     * have been set
     */
    function processAuction() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import "@solidstate/contracts/token/ERC4626/IERC4626.sol";
import "@solidstate/contracts/utils/IMulticall.sol";

/**
 * @title Knox Vault Base Interface
 * @dev includes ERC20Metadata and ERC4626 interfaces
 */

interface IVaultBase is IERC20Metadata, IERC4626, IMulticall {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Vault Events Interface
 */

interface IVaultEvents {
    /**
     * @notice emitted when the auction contract address is updated
     * @param epoch epoch id
     * @param oldAuction previous auction address
     * @param newAuction new auction address
     * @param caller address of admin
     */
    event AuctionSet(
        uint64 indexed epoch,
        address oldAuction,
        address newAuction,
        address caller
    );

    /**
     * @notice emitted when the is processed
     * @param epoch epoch id
     * @param totalCollateralUsed contracts sold, denominated in the collateral asset
     * @param totalContractsSold contracts sold during the auction
     * @param totalPremiums premiums earned during the auction
     */
    event AuctionProcessed(
        uint64 indexed epoch,
        uint256 totalCollateralUsed,
        uint256 totalContractsSold,
        uint256 totalPremiums
    );

    /**
     * @notice emitted when the auction offset window is updated
     * @param epoch epoch id
     * @param oldStartOffset previous start offset
     * @param newStartOffset new start offset
     * @param oldEndOffset previous end offset
     * @param newEndOffset new end offset
     * @param caller address of admin
     */
    event AuctionWindowOffsetsSet(
        uint64 indexed epoch,
        uint256 oldStartOffset,
        uint256 newStartOffset,
        uint256 oldEndOffset,
        uint256 newEndOffset,
        address caller
    );

    /**
     * @notice emitted when the option delta is updated
     * @param epoch epoch id
     * @param oldDelta previous option delta
     * @param newDelta new option delta
     * @param caller address of admin
     */
    event DeltaSet(
        uint64 indexed epoch,
        int128 oldDelta,
        int128 newDelta,
        address caller
    );

    /**
     * @notice emitted when a distribution is sent to a liquidity provider
     * @param epoch epoch id
     * @param collateralAmount quantity of collateral distributed to the receiver
     * @param shortContracts quantity of short contracts distributed to the receiver
     * @param receiver address of the receiver
     */
    event DistributionSent(
        uint64 indexed epoch,
        uint256 collateralAmount,
        uint256 shortContracts,
        address receiver
    );

    /**
     * @notice emitted when the fee recipient address is updated
     * @param epoch epoch id
     * @param oldFeeRecipient previous fee recipient address
     * @param newFeeRecipient new fee recipient address
     * @param caller address of admin
     */
    event FeeRecipientSet(
        uint64 indexed epoch,
        address oldFeeRecipient,
        address newFeeRecipient,
        address caller
    );

    /**
     * @notice emitted when the keeper address is updated
     * @param epoch epoch id
     * @param oldKeeper previous keeper address
     * @param newKeeper new keeper address
     * @param caller address of admin
     */
    event KeeperSet(
        uint64 indexed epoch,
        address oldKeeper,
        address newKeeper,
        address caller
    );

    /**
     * @notice emitted when an external function reverts
     * @param message error message
     */
    event Log(string message);

    /**
     * @notice emitted when option parameters are set
     * @param epoch epoch id
     * @param expiry expiration timestamp
     * @param strike64x64 strike price as a 64x64 fixed point number
     * @param longTokenId long token id
     * @param shortTokenId short token id
     */
    event OptionParametersSet(
        uint64 indexed epoch,
        uint64 expiry,
        int128 strike64x64,
        uint256 longTokenId,
        uint256 shortTokenId
    );

    /**
     * @notice emitted when the performance fee is collected
     * @param epoch epoch id
     * @param gain amount earned during the epoch
     * @param loss amount lost during the epoch
     * @param feeInCollateral fee from net income, denominated in the collateral asset
     */
    event PerformanceFeeCollected(
        uint64 indexed epoch,
        uint256 gain,
        uint256 loss,
        uint256 feeInCollateral
    );

    /**
     * @notice emitted when the performance fee is updated
     * @param epoch epoch id
     * @param oldPerformanceFee previous performance fee
     * @param newPerformanceFee new performance fee
     * @param caller address of admin
     */
    event PerformanceFeeSet(
        uint64 indexed epoch,
        int128 oldPerformanceFee,
        int128 newPerformanceFee,
        address caller
    );

    /**
     * @notice emitted when the pricer contract address is updated
     * @param epoch epoch id
     * @param oldPricer previous pricer address
     * @param newPricer new pricer address
     * @param caller address of admin
     */
    event PricerSet(
        uint64 indexed epoch,
        address oldPricer,
        address newPricer,
        address caller
    );

    /**
     * @notice emitted when the queue contract address is updated
     * @param epoch epoch id
     * @param oldQueue previous queue address
     * @param newQueue new queue address
     * @param caller address of admin
     */
    event QueueSet(
        uint64 indexed epoch,
        address oldQueue,
        address newQueue,
        address caller
    );

    /**
     * @notice emitted when the reserved liquidity is withdrawn from the pool
     * @param epoch epoch id
     * @param amount quantity of reserved liquidity removed from pool
     */
    event ReservedLiquidityWithdrawn(uint64 indexed epoch, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultStorage.sol";

/**
 * @title Knox Vault View Interface
 */

interface IVaultView {
    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the address of assigned actors
     * @return address of owner
     * @return address of fee recipient
     * @return address of keeper
     */
    function getActors()
        external
        view
        returns (
            address,
            address,
            address
        );

    /**
     * @notice returns the auction window offsets
     * @return start offset
     * @return end offset
     */
    function getAuctionWindowOffsets() external view returns (uint256, uint256);

    /**
     * @notice returns the address of connected services
     * @return address of Auction
     * @return address of Premia Pool
     * @return address of Pricer
     * @return address of Queue
     */
    function getConnections()
        external
        view
        returns (
            address,
            address,
            address,
            address
        );

    /**
     * @notice returns option delta
     * @return option delta as a 64x64 fixed point number
     */
    function getDelta64x64() external view returns (int128);

    /**
     * @notice returns the current epoch
     * @return current epoch id
     */
    function getEpoch() external view returns (uint64);

    /**
     * @notice returns the option by epoch id
     * @return option parameters
     */
    function getOption(uint64 epoch)
        external
        view
        returns (VaultStorage.Option memory);

    /**
     * @notice returns option type (call/put)
     * @return true if opton is a call
     */
    function getOptionType() external view returns (bool);

    /**
     * @notice returns performance fee
     * @return performance fee as a 64x64 fixed point number
     */
    function getPerformanceFee64x64() external view returns (int128);

    /**
     * @notice returns the total amount of collateral and short contracts to distribute
     * @param assetAmount quantity of assets to withdraw
     * @return distribution amount in collateral asset
     * @return distribution amount in the short contracts
     */
    function previewDistributions(uint256 assetAmount)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice estimates the total reserved "active" collateral
     * @dev collateral is reserved from the auction to ensure the Vault has sufficent funds to
     * cover the APY fee
     * @return estimated amount of reserved "active" collateral
     */
    function previewReserves() external view returns (uint256);

    /**
     * @notice estimates the total number of contracts from the collateral and reserves held by the vault
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param collateral amount of collateral held by vault
     * @param reserves amount of reserves held by vault
     * @return estimated number of contracts
     */
    function previewTotalContracts(
        int128 strike64x64,
        uint256 collateral,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice calculates the total active vault by deducting the premiums from the ERC20 balance
     * @return total active collateral
     */
    function totalCollateral() external view returns (uint256);

    /**
     * @notice calculates the short position value denominated in the collateral asset
     * @return total short position in collateral amount
     */
    function totalShortAsCollateral() external view returns (uint256);

    /**
     * @notice returns the amount in short contracts underwitten by the vault
     * @return total short contracts
     */
    function totalShortAsContracts() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../auction/IAuction.sol";

import "../pricer/IPricer.sol";

import "../queue/IQueue.sol";

/**
 * @title Knox Vault Diamond Storage Library
 */

library VaultStorage {
    struct InitProxy {
        bool isCall;
        int128 delta64x64;
        int128 reserveRate64x64;
        int128 performanceFee64x64;
        string name;
        string symbol;
        address keeper;
        address feeRecipient;
        address pricer;
        address pool;
    }

    struct InitImpl {
        address auction;
        address queue;
        address pricer;
    }

    struct Option {
        // option expiration timestamp
        uint64 expiry;
        // option strike price
        int128 strike64x64;
        // option long token id
        uint256 longTokenId;
        // option short token id
        uint256 shortTokenId;
    }

    struct Layout {
        // base asset decimals
        uint8 baseDecimals;
        // underlying asset decimals
        uint8 underlyingDecimals;
        // option type, true if option is a call
        bool isCall;
        // auction processing flag, true if auction has been processed
        bool auctionProcessed;
        // vault option delta
        int128 delta64x64;
        // mapping of options to epoch id (epoch id -> option)
        mapping(uint64 => Option) options;
        // epoch id
        uint64 epoch;
        // auction start offset in seconds (startOffset = startTime - expiry)
        uint256 startOffset;
        // auction end offset in seconds (endOffset = endTime - expiry)
        uint256 endOffset;
        // auction start timestamp
        uint256 startTime;
        // total asset amount withdrawn during an epoch
        uint256 totalWithdrawals;
        // total asset amount not including premiums collected from the auction
        uint256 lastTotalAssets;
        // total premium collected during the auction
        uint256 totalPremium;
        // performance fee collected during epoch initialization
        uint256 fee;
        // percentage of asset to be held as reserves
        int128 reserveRate64x64;
        // percentage of fees taken from net income
        int128 performanceFee64x64;
        // fee recipient address
        address feeRecipient;
        // keeper bot address
        address keeper;
        // Auction contract interface
        IAuction Auction;
        // Queue contract interface
        IQueue Queue;
        // Pricer contract interface
        IPricer Pricer;
    }

    bytes32 internal constant LAYOUT_SLOT =
        keccak256("knox.contracts.storage.Vault");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = LAYOUT_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the current epoch
     * @return current epoch id
     */
    function _getEpoch() internal view returns (uint64) {
        return layout().epoch;
    }

    /**
     * @notice returns the option by epoch id
     * @return option parameters
     */
    function _getOption(uint64 epoch) internal view returns (Option memory) {
        return layout().options[epoch];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Knox Pricer Interface
 */

interface IPricer {
    /**
     * @notice gets the latest price of the underlying denominated in the base
     * @return price of underlying asset as 64x64 fixed point number
     */
    function latestAnswer64x64() external view returns (int128);

    /**
     * @notice calculates the time remaining until maturity
     * @param expiry the expiry date as UNIX timestamp
     * @return time remaining until maturity
     */
    function getTimeToMaturity64x64(uint64 expiry)
        external
        view
        returns (int128);

    /**
     * @notice gets the annualized volatility of the pool pair
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     * @return annualized volatility as 64x64 fixed point number
     */
    function getAnnualizedVolatility64x64(
        int128 spot64x64,
        int128 strike64x64,
        int128 timeToMaturity64x64
    ) external view returns (int128);

    /**
     * @notice gets the option price using the Black-Scholes model
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     * @param isCall option type, true if call option
     * @return price of the option denominated in the base as 64x64 fixed point number
     */
    function getBlackScholesPrice64x64(
        int128 spot64x64,
        int128 strike64x64,
        int128 timeToMaturity64x64,
        bool isCall
    ) external view returns (int128);

    /**
     * @notice calculates the delta strike price
     * @param isCall option type, true if call option
     * @param expiry the expiry date as UNIX timestamp
     * @param delta64x64 option delta as 64x64 fixed point number
     * @return delta strike price as 64x64 fixed point number
     */
    function getDeltaStrikePrice64x64(
        bool isCall,
        uint64 expiry,
        int128 delta64x64
    ) external view returns (int128);

    /**
     * @notice rounds a value to the floor or ceiling depending on option type
     * @param isCall option type, true if call option
     * @param n input value
     * @return rounded value as 64x64 fixed point number
     */
    function snapToGrid64x64(bool isCall, int128 n)
        external
        view
        returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/introspection/IERC165.sol";
import "@solidstate/contracts/token/ERC1155/IERC1155.sol";
import "@solidstate/contracts/token/ERC1155/enumerable/IERC1155Enumerable.sol";
import "@solidstate/contracts/utils/IMulticall.sol";

import "../vendor/IExchangeHelper.sol";

import "./IQueueEvents.sol";

/**
 * @title Knox Queue Interface
 */

interface IQueue is
    IERC165,
    IERC1155,
    IERC1155Enumerable,
    IMulticall,
    IQueueEvents
{
    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @notice sets a new max TVL for deposits
     * @param newMaxTVL is the new TVL limit for deposits
     */
    function setMaxTVL(uint256 newMaxTVL) external;

    /**
     * @notice sets a new Exchange Helper contract
     * @param newExchangeHelper is the new Exchange Helper contract address
     */
    function setExchangeHelper(address newExchangeHelper) external;

    /************************************************
     *  DEPOSIT
     ***********************************************/

    /**
     * @notice deposits collateral asset
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param amount total collateral deposited
     */
    function deposit(uint256 amount) external payable;

    /**
     * @notice swaps into the collateral asset and deposits the proceeds
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     */
    function swapAndDeposit(IExchangeHelper.SwapArgs calldata s)
        external
        payable;

    /************************************************
     *  CANCEL
     ***********************************************/

    /**
     * @notice cancels deposit, refunds collateral asset
     * @dev cancellation must be made within the same epoch as the deposit
     * @param amount total collateral which will be withdrawn
     */
    function cancel(uint256 amount) external;

    /************************************************
     *  REDEEM
     ***********************************************/

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     */
    function redeem(uint256 tokenId) external;

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     * @param receiver vault share recipient
     */
    function redeem(uint256 tokenId, address receiver) external;

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     * @param receiver vault share recipient
     * @param owner claim token holder
     */
    function redeem(
        uint256 tokenId,
        address receiver,
        address owner
    ) external;

    /**
     * @notice exchanges all claim tokens for vault shares
     */
    function redeemMax() external;

    /**
     * @notice exchanges all claim tokens for vault shares
     * @param receiver vault share recipient
     */
    function redeemMax(address receiver) external;

    /**
     * @notice exchanges all claim tokens for vault shares
     * @param receiver vault share recipient
     * @param owner claim token holder
     */
    function redeemMax(address receiver, address owner) external;

    /************************************************
     *  INITIALIZE EPOCH
     ***********************************************/

    /**
     * @notice transfers deposited collateral to vault, calculates the price per share
     */
    function processDeposits() external;

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the current claim token id
     * @return claim token id
     */
    function getCurrentTokenId() external view returns (uint256);

    /**
     * @notice returns the current epoch of the queue
     * @return epoch id
     */
    function getEpoch() external view returns (uint64);

    /**
     * @notice returns the max total value locked of the vault
     * @return max total value
     */
    function getMaxTVL() external view returns (uint256);

    /**
     * @notice returns the price per share for a given claim token id
     * @param tokenId claim token id
     * @return price per share
     */
    function getPricePerShare(uint256 tokenId) external view returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for a given claim token
     * @param tokenId claim token id
     * @return unredeemed vault share amount
     */
    function previewUnredeemed(uint256 tokenId) external view returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for a given claim token
     * @param tokenId claim token id
     * @param owner claim token holder
     * @return unredeemed vault share amount
     */
    function previewUnredeemed(uint256 tokenId, address owner)
        external
        view
        returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for all claim tokens
     * @param owner claim token holder
     * @return unredeemed vault share amount
     */
    function previewMaxUnredeemed(address owner)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title Premia Exchange Helper
 * @dev deployed standalone and referenced by internal functions
 * @dev do NOT set approval to this contract!
 */
interface IExchangeHelper {
    struct SwapArgs {
        // token to pass in to swap
        address tokenIn;
        // amount of tokenIn to trade
        uint256 amountInMax;
        //min amount out to be used to purchase
        uint256 amountOutMin;
        // exchange address to call to execute the trade
        address callee;
        // address for which to set allowance for the trade
        address allowanceTarget;
        // data to execute the trade
        bytes data;
        // address to which refund excess tokens
        address refundAddress;
    }

    /**
     * @notice perform arbitrary swap transaction
     * @param sourceToken source token to pull into this address
     * @param targetToken target token to buy
     * @param pullAmount amount of source token to start the trade
     * @param callee exchange address to call to execute the trade.
     * @param allowanceTarget address for which to set allowance for the trade
     * @param data calldata to execute the trade
     * @param refundAddress address that un-used source token goes to
     * @return amountOut quantity of targetToken yielded by swap
     */
    function swapWithToken(
        address sourceToken,
        address targetToken,
        uint256 pullAmount,
        address callee,
        address allowanceTarget,
        bytes calldata data,
        address refundAddress
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Auction Order Book Library
 * @dev based on PiperMerriam's Grove v0.3
 * https://github.com/pipermerriam/ethereum-grove
 */

library OrderBook {
    struct Index {
        uint256 head;
        uint256 length;
        uint256 root;
        mapping(uint256 => Order) orders;
    }

    struct Order {
        Data data;
        uint256 parent;
        uint256 left;
        uint256 right;
        uint256 height;
    }

    struct Data {
        uint256 id;
        int128 price64x64;
        uint256 size;
        address buyer;
    }

    /// @dev Retrieve the highest bid in the order book.
    /// @param index The index that the order is part of.
    function _head(Index storage index) internal view returns (uint256) {
        return index.head;
    }

    /// @dev Retrieve the number of bids in the order book.
    /// @param index The index that the order is part of.
    function _length(Index storage index) internal view returns (uint256) {
        return index.length;
    }

    /// @dev Retrieve the id, price, size, and buyer for the order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getOrderById(Index storage index, uint256 id)
        internal
        view
        returns (Data memory)
    {
        return index.orders[id].data;
    }

    /// @dev Returns the previous bid in descending order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getPreviousOrder(Index storage index, uint256 id)
        internal
        view
        returns (uint256)
    {
        Order storage currentOrder = index.orders[id];

        if (currentOrder.data.id == 0) {
            // Unknown order, just return 0;
            return 0;
        }

        Order memory child;

        if (currentOrder.left != 0) {
            // Trace left to latest child in left tree.
            child = index.orders[currentOrder.left];

            while (child.right != 0) {
                child = index.orders[child.right];
            }
            return child.data.id;
        }

        if (currentOrder.parent != 0) {
            // Now we trace back up through parent relationships, looking
            // for a link where the child is the right child of it's
            // parent.
            Order storage parent = index.orders[currentOrder.parent];
            child = currentOrder;

            while (true) {
                if (parent.right == child.data.id) {
                    return parent.data.id;
                }

                if (parent.parent == 0) {
                    break;
                }
                child = parent;
                parent = index.orders[parent.parent];
            }
        }

        // This is the first order, and has no previous order.
        return 0;
    }

    /// @dev Returns the next bid in descending order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getNextOrder(Index storage index, uint256 id)
        internal
        view
        returns (uint256)
    {
        Order storage currentOrder = index.orders[id];

        if (currentOrder.data.id == 0) {
            // Unknown order, just return 0;
            return 0;
        }

        Order memory child;

        if (currentOrder.right != 0) {
            // Trace right to earliest child in right tree.
            child = index.orders[currentOrder.right];

            while (child.left != 0) {
                child = index.orders[child.left];
            }
            return child.data.id;
        }

        if (currentOrder.parent != 0) {
            // if the order is the left child of it's parent, then the
            // parent is the next one.
            Order storage parent = index.orders[currentOrder.parent];
            child = currentOrder;

            while (true) {
                if (parent.left == child.data.id) {
                    return parent.data.id;
                }

                if (parent.parent == 0) {
                    break;
                }
                child = parent;
                parent = index.orders[parent.parent];
            }

            // Now we need to trace all the way up checking to see if any parent is the
        }

        // This is the final order.
        return 0;
    }

    /// @dev Updates or Inserts the id into the index at its appropriate location based on the price provided.
    /// @param index The index that the order is part of.
    // / @param id The unique identifier of the data element the index order will represent.
    /// @param price64x64 The unit price specified by the buyer.
    /// @param size The size specified by the buyer.
    /// @param buyer The buyers wallet address.
    function _insert(
        Index storage index,
        int128 price64x64,
        uint256 size,
        address buyer
    ) internal returns (uint256) {
        index.length = index.length + 1;
        uint256 id = index.length;

        Data memory data = _getOrderById(index, index.head);

        int128 highestPricePaid = data.price64x64;

        if (index.head == 0 || price64x64 > highestPricePaid) {
            index.head = id;
        }

        if (index.orders[id].data.id == id) {
            // A order with this id already exists.  If the price is
            // the same, then just return early, otherwise, remove it
            // and reinsert it.
            if (index.orders[id].data.price64x64 == price64x64) {
                return id;
            }
            _remove(index, id);
        }

        uint256 previousOrderId = 0;

        if (index.root == 0) {
            index.root = id;
        }
        Order storage currentOrder = index.orders[index.root];

        // Do insertion
        while (true) {
            if (currentOrder.data.id == 0) {
                // This is a new unpopulated order.
                currentOrder.data.id = id;
                currentOrder.parent = previousOrderId;
                currentOrder.data.price64x64 = price64x64;
                currentOrder.data.size = size;
                currentOrder.data.buyer = buyer;
                break;
            }

            // Set the previous order id.
            previousOrderId = currentOrder.data.id;

            // The new order belongs in the right subtree
            if (price64x64 <= currentOrder.data.price64x64) {
                if (currentOrder.right == 0) {
                    currentOrder.right = id;
                }
                currentOrder = index.orders[currentOrder.right];
                continue;
            }

            // The new order belongs in the left subtree.
            if (currentOrder.left == 0) {
                currentOrder.left = id;
            }
            currentOrder = index.orders[currentOrder.left];
        }

        // Rebalance the tree
        _rebalanceTree(index, currentOrder.data.id);

        return id;
    }

    /// @dev Remove the order for the given unique identifier from the index.
    /// @param index The index that should be removed
    /// @param id The unique identifier of the data element to remove.
    function _remove(Index storage index, uint256 id) internal returns (bool) {
        if (id == index.head) {
            index.head = _getNextOrder(index, id);
        }

        Order storage replacementOrder;
        Order storage parent;
        Order storage child;
        uint256 rebalanceOrigin;

        Order storage orderToDelete = index.orders[id];

        if (orderToDelete.data.id != id) {
            // The id does not exist in the tree.
            return false;
        }

        if (orderToDelete.left != 0 || orderToDelete.right != 0) {
            // This order is not a leaf order and thus must replace itself in
            // it's tree by either the previous or next order.
            if (orderToDelete.left != 0) {
                // This order is guaranteed to not have a right child.
                replacementOrder = index.orders[
                    _getPreviousOrder(index, orderToDelete.data.id)
                ];
            } else {
                // This order is guaranteed to not have a left child.
                replacementOrder = index.orders[
                    _getNextOrder(index, orderToDelete.data.id)
                ];
            }
            // The replacementOrder is guaranteed to have a parent.
            parent = index.orders[replacementOrder.parent];

            // Keep note of the location that our tree rebalancing should
            // start at.
            rebalanceOrigin = replacementOrder.data.id;

            // Join the parent of the replacement order with any subtree of
            // the replacement order.  We can guarantee that the replacement
            // order has at most one subtree because of how getNextOrder and
            // getPreviousOrder are used.
            if (parent.left == replacementOrder.data.id) {
                parent.left = replacementOrder.right;
                if (replacementOrder.right != 0) {
                    child = index.orders[replacementOrder.right];
                    child.parent = parent.data.id;
                }
            }
            if (parent.right == replacementOrder.data.id) {
                parent.right = replacementOrder.left;
                if (replacementOrder.left != 0) {
                    child = index.orders[replacementOrder.left];
                    child.parent = parent.data.id;
                }
            }

            // Now we replace the orderToDelete with the replacementOrder.
            // This includes parent/child relationships for all of the
            // parent, the left child, and the right child.
            replacementOrder.parent = orderToDelete.parent;
            if (orderToDelete.parent != 0) {
                parent = index.orders[orderToDelete.parent];
                if (parent.left == orderToDelete.data.id) {
                    parent.left = replacementOrder.data.id;
                }
                if (parent.right == orderToDelete.data.id) {
                    parent.right = replacementOrder.data.id;
                }
            } else {
                // If the order we are deleting is the root order update the
                // index root order pointer.
                index.root = replacementOrder.data.id;
            }

            replacementOrder.left = orderToDelete.left;
            if (orderToDelete.left != 0) {
                child = index.orders[orderToDelete.left];
                child.parent = replacementOrder.data.id;
            }

            replacementOrder.right = orderToDelete.right;
            if (orderToDelete.right != 0) {
                child = index.orders[orderToDelete.right];
                child.parent = replacementOrder.data.id;
            }
        } else if (orderToDelete.parent != 0) {
            // The order being deleted is a leaf order so we only erase it's
            // parent linkage.
            parent = index.orders[orderToDelete.parent];

            if (parent.left == orderToDelete.data.id) {
                parent.left = 0;
            }
            if (parent.right == orderToDelete.data.id) {
                parent.right = 0;
            }

            // keep note of where the rebalancing should begin.
            rebalanceOrigin = parent.data.id;
        } else {
            // This is both a leaf order and the root order, so we need to
            // unset the root order pointer.
            index.root = 0;
        }

        // Now we zero out all of the fields on the orderToDelete.
        orderToDelete.data.id = 0;
        orderToDelete.data.price64x64 = 0;
        orderToDelete.data.size = 0;
        orderToDelete.data.buyer = 0x0000000000000000000000000000000000000000;
        orderToDelete.parent = 0;
        orderToDelete.left = 0;
        orderToDelete.right = 0;
        orderToDelete.height = 0;

        // Walk back up the tree rebalancing
        if (rebalanceOrigin != 0) {
            _rebalanceTree(index, rebalanceOrigin);
        }

        return true;
    }

    function _rebalanceTree(Index storage index, uint256 id) private {
        // Trace back up rebalancing the tree and updating heights as
        // needed..
        Order storage currentOrder = index.orders[id];

        while (true) {
            int256 balanceFactor =
                _getBalanceFactor(index, currentOrder.data.id);

            if (balanceFactor == 2) {
                // Right rotation (tree is heavy on the left)
                if (_getBalanceFactor(index, currentOrder.left) == -1) {
                    // The subtree is leaning right so it need to be
                    // rotated left before the current order is rotated
                    // right.
                    _rotateLeft(index, currentOrder.left);
                }
                _rotateRight(index, currentOrder.data.id);
            }

            if (balanceFactor == -2) {
                // Left rotation (tree is heavy on the right)
                if (_getBalanceFactor(index, currentOrder.right) == 1) {
                    // The subtree is leaning left so it need to be
                    // rotated right before the current order is rotated
                    // left.
                    _rotateRight(index, currentOrder.right);
                }
                _rotateLeft(index, currentOrder.data.id);
            }

            if ((-1 <= balanceFactor) && (balanceFactor <= 1)) {
                _updateOrderHeight(index, currentOrder.data.id);
            }

            if (currentOrder.parent == 0) {
                // Reached the root which may be new due to tree
                // rotation, so set it as the root and then break.
                break;
            }

            currentOrder = index.orders[currentOrder.parent];
        }
    }

    function _getBalanceFactor(Index storage index, uint256 id)
        private
        view
        returns (int256)
    {
        Order storage order = index.orders[id];
        return
            int256(index.orders[order.left].height) -
            int256(index.orders[order.right].height);
    }

    function _updateOrderHeight(Index storage index, uint256 id) private {
        Order storage order = index.orders[id];
        order.height =
            _max(
                index.orders[order.left].height,
                index.orders[order.right].height
            ) +
            1;
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a >= b) {
            return a;
        }
        return b;
    }

    function _rotateLeft(Index storage index, uint256 id) private {
        Order storage originalRoot = index.orders[id];

        if (originalRoot.right == 0) {
            // Cannot rotate left if there is no right originalRoot to rotate into
            // place.
            revert();
        }

        // The right child is the new root, so it gets the original
        // `originalRoot.parent` as it's parent.
        Order storage newRoot = index.orders[originalRoot.right];
        newRoot.parent = originalRoot.parent;

        // The original root needs to have it's right child nulled out.
        originalRoot.right = 0;

        if (originalRoot.parent != 0) {
            // If there is a parent order, it needs to now point downward at
            // the newRoot which is rotating into the place where `order` was.
            Order storage parent = index.orders[originalRoot.parent];

            // figure out if we're a left or right child and have the
            // parent point to the new order.
            if (parent.left == originalRoot.data.id) {
                parent.left = newRoot.data.id;
            }
            if (parent.right == originalRoot.data.id) {
                parent.right = newRoot.data.id;
            }
        }

        if (newRoot.left != 0) {
            // If the new root had a left child, that moves to be the
            // new right child of the original root order
            Order storage leftChild = index.orders[newRoot.left];
            originalRoot.right = leftChild.data.id;
            leftChild.parent = originalRoot.data.id;
        }

        // Update the newRoot's left order to point at the original order.
        originalRoot.parent = newRoot.data.id;
        newRoot.left = originalRoot.data.id;

        if (newRoot.parent == 0) {
            index.root = newRoot.data.id;
        }

        _updateOrderHeight(index, originalRoot.data.id);
        _updateOrderHeight(index, newRoot.data.id);
    }

    function _rotateRight(Index storage index, uint256 id) private {
        Order storage originalRoot = index.orders[id];

        if (originalRoot.left == 0) {
            // Cannot rotate right if there is no left order to rotate into
            // place.
            revert();
        }

        // The left child is taking the place of order, so we update it's
        // parent to be the original parent of the order.
        Order storage newRoot = index.orders[originalRoot.left];
        newRoot.parent = originalRoot.parent;

        // Null out the originalRoot.left
        originalRoot.left = 0;

        if (originalRoot.parent != 0) {
            // If the order has a parent, update the correct child to point
            // at the newRoot now.
            Order storage parent = index.orders[originalRoot.parent];

            if (parent.left == originalRoot.data.id) {
                parent.left = newRoot.data.id;
            }
            if (parent.right == originalRoot.data.id) {
                parent.right = newRoot.data.id;
            }
        }

        if (newRoot.right != 0) {
            Order storage rightChild = index.orders[newRoot.right];
            originalRoot.left = newRoot.right;
            rightChild.parent = originalRoot.data.id;
        }

        // Update the new root's right order to point to the original order.
        originalRoot.parent = newRoot.data.id;
        newRoot.right = originalRoot.data.id;

        if (newRoot.parent == 0) {
            index.root = newRoot.data.id;
        }

        // Recompute heights.
        _updateOrderHeight(index, originalRoot.data.id);
        _updateOrderHeight(index, newRoot.data.id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from '../IERC1155Internal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155Internal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Queue Events Interface
 */

interface IQueueEvents {
    /**
     * @notice emitted when a deposit is cancelled
     * @param epoch epoch id
     * @param depositer address of depositer
     * @param amount quantity of collateral assets removed from queue
     */
    event Cancel(uint64 indexed epoch, address depositer, uint256 amount);

    /**
     * @notice emitted when a deposit is made
     * @param epoch epoch id
     * @param depositer address of depositer
     * @param amount quantity of collateral assets added to queue
     */
    event Deposit(uint64 indexed epoch, address depositer, uint256 amount);

    /**
     * @notice emitted when the exchange helper contract address is updated
     * @param oldExchangeHelper previous exchange helper address
     * @param newExchangeHelper new exchange helper address
     * @param caller address of admin
     */
    event ExchangeHelperSet(
        address oldExchangeHelper,
        address newExchangeHelper,
        address caller
    );

    /**
     * @notice emitted when the max TVL is updated
     * @param epoch epoch id
     * @param oldMaxTVL previous max TVL amount
     * @param newMaxTVL new max TVL amount
     * @param caller address of admin
     */
    event MaxTVLSet(
        uint64 indexed epoch,
        uint256 oldMaxTVL,
        uint256 newMaxTVL,
        address caller
    );

    /**
     * @notice emitted when vault shares are redeemed
     * @param epoch epoch id
     * @param receiver address of receiver
     * @param depositer address of depositer
     * @param shares quantity of vault shares sent to receiver
     */
    event Redeem(
        uint64 indexed epoch,
        address receiver,
        address depositer,
        uint256 shares
    );

    /**
     * @notice emitted when the queued deposits are processed
     * @param epoch epoch id
     * @param deposits quantity of collateral assets processed
     * @param pricePerShare vault price per share calculated
     * @param shares quantity of vault shares sent to queue contract
     * @param claimTokenSupply quantity of claim tokens in supply
     */
    event ProcessQueuedDeposits(
        uint64 indexed epoch,
        uint256 deposits,
        uint256 pricePerShare,
        uint256 shares,
        uint256 claimTokenSupply
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../ERC20/IERC20.sol';
import { IERC4626Internal } from './IERC4626Internal.sol';

/**
 * @title ERC4626 interface
 * @dev see https://github.com/ethereum/EIPs/issues/4626
 */
interface IERC4626 is IERC4626Internal, IERC20 {
    /**
     * @notice get the address of the base token used for vault accountin purposes
     * @return base token address
     */
    function asset() external view returns (address);

    /**
     * @notice get the total quantity of the base asset currently managed by the vault
     * @return total managed asset amount
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice calculate the quantity of shares received in exchange for a given quantity of assets, not accounting for slippage
     * @param assetAmount quantity of assets to convert
     * @return shareAmount quantity of shares calculated
     */
    function convertToShares(uint256 assetAmount)
        external
        view
        returns (uint256 shareAmount);

    /**
     * @notice calculate the quantity of assets received in exchange for a given quantity of shares, not accounting for slippage
     * @param shareAmount quantity of shares to convert
     * @return assetAmount quantity of assets calculated
     */
    function convertToAssets(uint256 shareAmount)
        external
        view
        returns (uint256 assetAmount);

    /**
     * @notice calculate the maximum quantity of base assets which may be deposited on behalf of given receiver
     * @param receiver recipient of shares resulting from deposit
     * @return maxAssets maximum asset deposit amount
     */
    function maxDeposit(address receiver)
        external
        view
        returns (uint256 maxAssets);

    /**
     * @notice calculate the maximum quantity of shares which may be minted on behalf of given receiver
     * @param receiver recipient of shares resulting from deposit
     * @return maxShares maximum share mint amount
     */
    function maxMint(address receiver)
        external
        view
        returns (uint256 maxShares);

    /**
     * @notice calculate the maximum quantity of base assets which may be withdrawn by given holder
     * @param owner holder of shares to be redeemed
     * @return maxAssets maximum asset mint amount
     */
    function maxWithdraw(address owner)
        external
        view
        returns (uint256 maxAssets);

    /**
     * @notice calculate the maximum quantity of shares which may be redeemed by given holder
     * @param owner holder of shares to be redeemed
     * @return maxShares maximum share redeem amount
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @notice simulate a deposit of given quantity of assets
     * @param assetAmount quantity of assets to deposit
     * @return shareAmount quantity of shares to mint
     */
    function previewDeposit(uint256 assetAmount)
        external
        view
        returns (uint256 shareAmount);

    /**
     * @notice simulate a minting of given quantity of shares
     * @param shareAmount quantity of shares to mint
     * @return assetAmount quantity of assets to deposit
     */
    function previewMint(uint256 shareAmount)
        external
        view
        returns (uint256 assetAmount);

    /**
     * @notice simulate a withdrawal of given quantity of assets
     * @param assetAmount quantity of assets to withdraw
     * @return shareAmount quantity of shares to redeem
     */
    function previewWithdraw(uint256 assetAmount)
        external
        view
        returns (uint256 shareAmount);

    /**
     * @notice simulate a redemption of given quantity of shares
     * @param shareAmount quantity of shares to redeem
     * @return assetAmount quantity of assets to withdraw
     */
    function previewRedeem(uint256 shareAmount)
        external
        view
        returns (uint256 assetAmount);

    /**
     * @notice execute a deposit of assets on behalf of given address
     * @param assetAmount quantity of assets to deposit
     * @param receiver recipient of shares resulting from deposit
     * @return shareAmount quantity of shares to mint
     */
    function deposit(uint256 assetAmount, address receiver)
        external
        returns (uint256 shareAmount);

    /**
     * @notice execute a minting of shares on behalf of given address
     * @param shareAmount quantity of shares to mint
     * @param receiver recipient of shares resulting from deposit
     * @return assetAmount quantity of assets to deposit
     */
    function mint(uint256 shareAmount, address receiver)
        external
        returns (uint256 assetAmount);

    /**
     * @notice execute a withdrawal of assets on behalf of given address
     * @param assetAmount quantity of assets to withdraw
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return shareAmount quantity of shares to redeem
     */
    function withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) external returns (uint256 shareAmount);

    /**
     * @notice execute a redemption of shares on behalf of given address
     * @param shareAmount quantity of shares to redeem
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return assetAmount quantity of assets to withdraw
     */
    function redeem(
        uint256 shareAmount,
        address receiver,
        address owner
    ) external returns (uint256 assetAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC4626 interface needed by internal functions
 */
interface IERC4626Internal {
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
}