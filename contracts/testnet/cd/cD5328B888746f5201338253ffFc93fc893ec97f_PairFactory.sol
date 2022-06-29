// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IPairFactory.sol";
import "../interfaces/IAmmFactory.sol";
import "../interfaces/IMarginFactory.sol";
import "../interfaces/IAmm.sol";
import "../interfaces/IMargin.sol";
import "../utils/Ownable.sol";
import "./Margin.sol";
import "./Amm.sol";

contract PairFactory is IPairFactory, Ownable {
    address public override ammFactory;
    address public override marginFactory;
    //todo
    bytes public  marginBytecode ;
    bytes public  ammBytecode ;
    address public proxyAdmin;

    constructor() {
        owner = msg.sender;
    }

    function init(address ammFactory_, address marginFactory_) external onlyOwner {
        require(ammFactory == address(0) && marginFactory == address(0), "PairFactory: ALREADY_INITED");
        require(ammFactory_ != address(0) && marginFactory_ != address(0), "PairFactory: ZERO_ADDRESS");
        ammFactory = ammFactory_;
        marginFactory = marginFactory_;
        // init value
        marginBytecode = type(Margin).creationCode;
        ammBytecode = type(Amm).creationCode;

    }

    function createPair(address baseToken, address quoteToken) external override returns (address amm, address margin) {
        amm = IAmmFactory(ammFactory).createAmm(baseToken, quoteToken, ammBytecode, proxyAdmin);
        margin = IMarginFactory(marginFactory).createMargin(baseToken, quoteToken, marginBytecode, proxyAdmin);
        IAmmFactory(ammFactory).initAmm(baseToken, quoteToken, margin);
        IMarginFactory(marginFactory).initMargin(baseToken, quoteToken, amm);
        emit NewPair(baseToken, quoteToken, amm, margin);
    }


    // todo
    function setMarginBytecode( bytes memory newMarginByteCode) external  {
        marginBytecode = newMarginByteCode; 
    }

    //todo
    function setAmmBytecode( bytes memory newAmmBytecode) external   {
        ammBytecode = newAmmBytecode; 
    }

 function setProxyAdmin( address newProxyAdmin) external   {
        proxyAdmin = newProxyAdmin; 
    }

    function getAmm(address baseToken, address quoteToken) external view override returns (address) {
        return IAmmFactory(ammFactory).getAmm(baseToken, quoteToken);
    }

    function getMargin(address baseToken, address quoteToken) external view override returns (address) {
        return IMarginFactory(marginFactory).getMargin(baseToken, quoteToken);
    }


}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPairFactory {
    event NewPair(address indexed baseToken, address indexed quoteToken, address amm, address margin);

    function createPair(address baseToken, address quotoToken) external returns (address amm, address margin);

    function ammFactory() external view returns (address);

    function marginFactory() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmmFactory {
    event AmmCreated(address indexed baseToken, address indexed quoteToken, address amm);

    function createAmm(address baseToken, address quoteToken, bytes memory ammBytecode, address proxyAdmin) external returns (address amm);

    function initAmm(
        address baseToken,
        address quoteToken,
        address margin
    ) external;

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function upperFactory() external view returns (address);

    function config() external view returns (address);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address amm);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMarginFactory {
    event MarginCreated(address indexed baseToken, address indexed quoteToken,address margin,  address proxy);

    function createMargin(address baseToken, address quoteToken, bytes memory marginBytecode, address proxyAdmin ) external returns (address margin);

    function initMargin(
        address baseToken,
        address quoteToken,
        address amm
    ) external;

    function upperFactory() external view returns (address);

    function config() external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address margin);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Swap(address indexed trader, address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed trader, address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteReserveBefore, uint256 quoteReserveAfter, uint256 _baseReserve , uint256 quoteReserveFromInternal,  uint256 quoteReserveFromExternal );
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    // only factory can call this function
    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external;

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function burn(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    // only binding margin can call this function
    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external returns (uint256[2] memory amounts);

    // only binding margin can call this function
    function forceSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external;

    function rebase() external returns (uint256 quoteReserveAfter);

    function collectFee() external returns (bool feeOn);

    function factory() external view returns (address);

    function config() external view returns (address);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function margin() external view returns (address);

    function lastPrice() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function getFeeLiquidity() external view returns (uint256);

    function getTheMaxBurnLiquidity() external view returns (uint256 maxLiquidity);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMargin {
    struct Position {
        int256 quoteSize; //quote amount of position
        int256 baseSize; //margin + fundingFee + unrealizedPnl + deltaBaseWhenClosePosition
        uint256 tradeSize; //if quoteSize>0 unrealizedPnl = baseValueOfQuoteSize - tradeSize; if quoteSize<0 unrealizedPnl = tradeSize - baseValueOfQuoteSize;
    }

    event AddMargin(address indexed trader, uint256 depositAmount, Position position);
    event RemoveMargin(
        address indexed trader,
        address indexed to,
        uint256 withdrawAmount,
        int256 fundingFee,
        uint256 withdrawAmountFromMargin,
        Position position
    );
    event OpenPosition(
        address indexed trader,
        uint8 side,
        uint256 baseAmount,
        uint256 quoteAmount,
        int256 fundingFee,
        Position position
    );
    event ClosePosition(
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        int256 fundingFee,
        Position position
    );
    event Liquidate(
        address indexed liquidator,
        address indexed trader,
        address indexed to,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 bonus,
        int256 fundingFee,
        Position position
    );
    event UpdateCPF(uint256 timeStamp, int256 cpf);

    /// @notice only factory can call this function
    /// @param baseToken_ margin's baseToken.
    /// @param quoteToken_ margin's quoteToken.
    /// @param amm_ amm address.
    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_
    ) external;

    /// @notice add margin to trader
    /// @param trader .
    /// @param depositAmount base amount to add.
    function addMargin(address trader, uint256 depositAmount) external;

    /// @notice remove margin to msg.sender
    /// @param withdrawAmount base amount to withdraw.
    function removeMargin(
        address trader,
        address to,
        uint256 withdrawAmount
    ) external;

    /// @notice open position with side and quoteAmount by msg.sender
    /// @param side long or short.
    /// @param quoteAmount quote amount.
    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external returns (uint256 baseAmount);

    /// @notice close msg.sender's position with quoteAmount
    /// @param quoteAmount quote amount to close.
    function closePosition(address trader, uint256 quoteAmount) external returns (uint256 baseAmount);

    /// @notice liquidate trader
    function liquidate(address trader, address to)
        external
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        );

    function updateCPF() external returns (int256);

    /// @notice get factory address
    function factory() external view returns (address);

    /// @notice get config address
    function config() external view returns (address);

    /// @notice get base token address
    function baseToken() external view returns (address);

    /// @notice get quote token address
    function quoteToken() external view returns (address);

    /// @notice get amm address of this margin
    function amm() external view returns (address);

    /// @notice get all users' net position of quote
    function netPosition() external view returns (int256 netQuotePosition);

    /// @notice get all users' net position of quote
    function totalPosition() external view returns (uint256 totalQuotePosition);

    /// @notice get trader's position
    function getPosition(address trader)
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );

    /// @notice get withdrawable margin of trader
    function getWithdrawable(address trader) external view returns (uint256 amount);

    /// @notice check if can liquidate this trader's position
    function canLiquidate(address trader) external view returns (bool);

    /// @notice calculate the latest funding fee with current position
    function calFundingFee(address trader) external view returns (int256 fundingFee);

    /// @notice calculate the latest debt ratio with Pnl and funding fee
    function calDebtRatio(address trader) external view returns (uint256 debtRatio);

    function calUnrealizedPnl(address trader) external view returns (int256);

    function getNewLatestCPF() external view returns (int256);

    function querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IMarginFactory.sol";
import "../interfaces/IAmmFactory.sol";
import "../interfaces/IAmm.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IMargin.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IWETH.sol";
import "../utils/Reentrant.sol";
import "../libraries/SignedMath.sol";
import "../libraries/ChainAdapter.sol";
import "../utils/Initializable.sol";

contract Margin is IMargin, IVault, Reentrant, Initializable {
    using SignedMath for int256;

    address public  override factory;
    address public override config;
    address public override amm;
    address public override baseToken;
    address public override quoteToken;
    mapping(address => Position) public traderPositionMap;
    mapping(address => int256) public traderCPF; //trader's latestCPF checkpoint, to calculate funding fee
    uint256 public override reserve;
    uint256 public lastUpdateCPF; //last timestamp update cpf
    uint256 public totalQuoteLong;
    uint256 public totalQuoteShort;
    int256 internal latestCPF; //latestCPF with 1e18 multiplied

    // constructor() {
    //     factory = msg.sender;
    // }

    function initialize  (
        address baseToken_,
        address quoteToken_,
        address amm_
    ) public initializer override {
       // require(factory == msg.sender, "Margin.initialize: FORBIDDEN");
        baseToken = baseToken_;
        quoteToken = quoteToken_;
        amm = amm_;
        factory = msg.sender;
        config = IMarginFactory(factory).config();
        
    }

    //@notice before add margin, ensure contract's baseToken balance larger than depositAmount
    function addMargin(address trader, uint256 depositAmount) external override nonReentrant {
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        uint256 _reserve = reserve;
        require(depositAmount <= balance - _reserve, "Margin.addMargin: WRONG_DEPOSIT_AMOUNT");
        Position memory traderPosition = traderPositionMap[trader];

        traderPosition.baseSize = traderPosition.baseSize.addU(depositAmount);
        traderPositionMap[trader] = traderPosition;
        reserve = _reserve + depositAmount;

        emit AddMargin(trader, depositAmount, traderPosition);
    }

    //remove baseToken from trader's fundingFee+unrealizedPnl+margin, remain position need to meet the requirement of initMarginRatio
    function removeMargin(
        address trader,
        address to,
        uint256 withdrawAmount
    ) external override nonReentrant {
        require(withdrawAmount > 0, "Margin.removeMargin: ZERO_WITHDRAW_AMOUNT");
        require(IConfig(config).routerMap(msg.sender), "Margin.removeMargin: FORBIDDEN");
        int256 _latestCPF = updateCPF();
        Position memory traderPosition = traderPositionMap[trader];

        //after last time operating trader's position, new fundingFee to earn.
        int256 fundingFee = _calFundingFee(trader, _latestCPF);
        //if close all position, trader can withdraw how much and earn how much pnl
        (uint256 withdrawableAmount, int256 unrealizedPnl) = _getWithdrawable(
            traderPosition.quoteSize,
            traderPosition.baseSize + fundingFee,
            traderPosition.tradeSize
        );
        require(withdrawAmount <= withdrawableAmount, "Margin.removeMargin: NOT_ENOUGH_WITHDRAWABLE");

        uint256 withdrawAmountFromMargin;
        //withdraw from fundingFee firstly, then unrealizedPnl, finally margin
        int256 uncoverAfterFundingFee = int256(1).mulU(withdrawAmount) - fundingFee;
        if (uncoverAfterFundingFee > 0) {
            //fundingFee cant cover withdrawAmount, use unrealizedPnl and margin.
            //update tradeSize only, no quoteSize, so can sub uncoverAfterFundingFee directly
            if (uncoverAfterFundingFee <= unrealizedPnl) {
                traderPosition.tradeSize -= uncoverAfterFundingFee.abs();
            } else {
                //fundingFee and unrealizedPnl cant cover withdrawAmount, use margin
                withdrawAmountFromMargin = (uncoverAfterFundingFee - unrealizedPnl).abs();
                //update tradeSize to current price to make unrealizedPnl zero
                traderPosition.tradeSize = traderPosition.quoteSize < 0
                    ? (int256(1).mulU(traderPosition.tradeSize) - unrealizedPnl).abs()
                    : (int256(1).mulU(traderPosition.tradeSize) + unrealizedPnl).abs();
            }
        }

        traderPosition.baseSize = traderPosition.baseSize - uncoverAfterFundingFee;

        traderPositionMap[trader] = traderPosition;
        traderCPF[trader] = _latestCPF;
        _withdraw(trader, to, withdrawAmount);

        emit RemoveMargin(trader, to, withdrawAmount, fundingFee, withdrawAmountFromMargin, traderPosition);
    }

    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external override nonReentrant returns (uint256 baseAmount) {
        require(side == 0 || side == 1, "Margin.openPosition: INVALID_SIDE");
        require(quoteAmount > 0, "Margin.openPosition: ZERO_QUOTE_AMOUNT");
        require(IConfig(config).routerMap(msg.sender), "Margin.openPosition: FORBIDDEN");
        int256 _latestCPF = updateCPF();

        Position memory traderPosition = traderPositionMap[trader];

        uint256 quoteSizeAbs = traderPosition.quoteSize.abs();
        int256 fundingFee = _calFundingFee(trader, _latestCPF);

        uint256 quoteAmountMax;
        {
            int256 marginAcc;
            if (traderPosition.quoteSize == 0) {
                marginAcc = traderPosition.baseSize + fundingFee;
            } else if (traderPosition.quoteSize > 0) {
                //simulate to close short
                uint256[2] memory result = IAmm(amm).estimateSwap(
                    address(quoteToken),
                    address(baseToken),
                    traderPosition.quoteSize.abs(),
                    0
                );
                marginAcc = traderPosition.baseSize.addU(result[1]) + fundingFee;
            } else {
                //simulate to close long
                uint256[2] memory result = IAmm(amm).estimateSwap(
                    address(baseToken),
                    address(quoteToken),
                    0,
                    traderPosition.quoteSize.abs()
                );
                marginAcc = traderPosition.baseSize.subU(result[0]) + fundingFee;
            }
            require(marginAcc > 0, "Margin.openPosition: INVALID_MARGIN_ACC");
            (, uint112 quoteReserve, ) = IAmm(amm).getReserves();
            (, uint256 _quoteAmountT, bool isIndexPrice) = IPriceOracle(IConfig(config).priceOracle())
                .getMarkPriceInRatio(amm, 0, marginAcc.abs());

            uint256 _quoteAmount = isIndexPrice
                ? _quoteAmountT
                : IAmm(amm).estimateSwap(baseToken, quoteToken, marginAcc.abs(), 0)[1];

            quoteAmountMax =
                (quoteReserve * 10000 * _quoteAmount) /
                ((IConfig(config).initMarginRatio() * quoteReserve) + (200 * _quoteAmount * IConfig(config).beta()));
        }

        bool isLong = side == 0;
        baseAmount = _addPositionWithAmm(trader, isLong, quoteAmount);
        require(baseAmount > 0, "Margin.openPosition: TINY_QUOTE_AMOUNT");

        if (
            traderPosition.quoteSize == 0 ||
            (traderPosition.quoteSize < 0 == isLong) ||
            (traderPosition.quoteSize > 0 == !isLong)
        ) {
            //baseAmount is real base cost
            traderPosition.tradeSize = traderPosition.tradeSize + baseAmount;
        } else {
            if (quoteAmount < quoteSizeAbs) {
                //entry price not change
                traderPosition.tradeSize =
                    traderPosition.tradeSize -
                    (quoteAmount * traderPosition.tradeSize) /
                    quoteSizeAbs;
            } else {
                //after close all opposite position, create new position with new entry price
                traderPosition.tradeSize = ((quoteAmount - quoteSizeAbs) * baseAmount) / quoteAmount;
            }
        }

        if (isLong) {
            traderPosition.quoteSize = traderPosition.quoteSize.subU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.addU(baseAmount) + fundingFee;
            totalQuoteLong = totalQuoteLong + quoteAmount;
        } else {
            traderPosition.quoteSize = traderPosition.quoteSize.addU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.subU(baseAmount) + fundingFee;
            totalQuoteShort = totalQuoteShort + quoteAmount;
        }
        require(traderPosition.quoteSize.abs() <= quoteAmountMax, "Margin.openPosition: INIT_MARGIN_RATIO");
        require(
            _calDebtRatio(traderPosition.quoteSize, traderPosition.baseSize) < IConfig(config).liquidateThreshold(),
            "Margin.openPosition: WILL_BE_LIQUIDATED"
        );

        traderCPF[trader] = _latestCPF;
        traderPositionMap[trader] = traderPosition;
        emit OpenPosition(trader, side, baseAmount, quoteAmount, fundingFee, traderPosition);
    }

    function closePosition(address trader, uint256 quoteAmount)
        external
        override
        nonReentrant
        returns (uint256 baseAmount)
    {
        require(IConfig(config).routerMap(msg.sender), "Margin.openPosition: FORBIDDEN");
        int256 _latestCPF = updateCPF();

        Position memory traderPosition = traderPositionMap[trader];
        require(quoteAmount != 0, "Margin.closePosition: ZERO_POSITION");
        uint256 quoteSizeAbs = traderPosition.quoteSize.abs();
        require(quoteAmount <= quoteSizeAbs, "Margin.closePosition: ABOVE_POSITION");

        bool isLong = traderPosition.quoteSize < 0;
        int256 fundingFee = _calFundingFee(trader, _latestCPF);
        require(
            _calDebtRatio(traderPosition.quoteSize, traderPosition.baseSize + fundingFee) <
                IConfig(config).liquidateThreshold(),
            "Margin.closePosition: DEBT_RATIO_OVER"
        );

        baseAmount = _minusPositionWithAmm(trader, isLong, quoteAmount);
        traderPosition.tradeSize -= (quoteAmount * traderPosition.tradeSize) / quoteSizeAbs;

        if (isLong) {
            totalQuoteLong = totalQuoteLong - quoteAmount;
            traderPosition.quoteSize = traderPosition.quoteSize.addU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.subU(baseAmount) + fundingFee;
        } else {
            totalQuoteShort = totalQuoteShort - quoteAmount;
            traderPosition.quoteSize = traderPosition.quoteSize.subU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.addU(baseAmount) + fundingFee;
        }
        if (traderPosition.quoteSize == 0 && traderPosition.baseSize < 0) {
            IAmm(amm).forceSwap(trader, quoteToken, baseToken, 0, traderPosition.baseSize.abs());
            traderPosition.baseSize = 0;
        }

        traderCPF[trader] = _latestCPF;
        traderPositionMap[trader] = traderPosition;

        emit ClosePosition(trader, quoteAmount, baseAmount, fundingFee, traderPosition);
    }

    function liquidate(address trader, address to)
        external
        override
        nonReentrant
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        )
    {
        require(IConfig(config).routerMap(msg.sender), "Margin.openPosition: FORBIDDEN");
        int256 _latestCPF = updateCPF();
        Position memory traderPosition = traderPositionMap[trader];
        int256 baseSize = traderPosition.baseSize;
        int256 quoteSize = traderPosition.quoteSize;
        require(quoteSize != 0, "Margin.liquidate: ZERO_POSITION");

        quoteAmount = quoteSize.abs();
        bool isLong = quoteSize < 0;
        int256 fundingFee = _calFundingFee(trader, _latestCPF);
        require(
            _calDebtRatio(quoteSize, baseSize + fundingFee) >= IConfig(config).liquidateThreshold(),
            "Margin.liquidate: NOT_LIQUIDATABLE"
        );

        {
            (uint256 _baseAmountT, , bool isIndexPrice) = IPriceOracle(IConfig(config).priceOracle())
                .getMarkPriceInRatio(amm, quoteAmount, 0);

            baseAmount = isIndexPrice ? _baseAmountT : _querySwapBaseWithAmm(isLong, quoteAmount);
            (uint256 _baseAmount, uint256 _quoteAmount) = (baseAmount, quoteAmount);
            bonus = _executeSettle(trader, isIndexPrice, isLong, fundingFee, baseSize, _baseAmount, _quoteAmount);
            if (isLong) {
                totalQuoteLong = totalQuoteLong - quoteSize.abs();
            } else {
                totalQuoteShort = totalQuoteShort - quoteSize.abs();
            }
        }

        traderCPF[trader] = _latestCPF;
        if (bonus > 0) {
            _withdraw(trader, to, bonus);
        }

        delete traderPositionMap[trader];

        emit Liquidate(msg.sender, trader, to, quoteAmount, baseAmount, bonus, fundingFee, traderPosition);
    }

    function _executeSettle(
        address _trader,
        bool isIndexPrice,
        bool isLong,
        int256 fundingFee,
        int256 baseSize,
        uint256 baseAmount,
        uint256 quoteAmount
    ) internal returns (uint256 bonus) {
        int256 remainBaseAmountAfterLiquidate = isLong
            ? baseSize.subU(baseAmount) + fundingFee
            : baseSize.addU(baseAmount) + fundingFee;

        if (remainBaseAmountAfterLiquidate >= 0) {
            bonus = (remainBaseAmountAfterLiquidate.abs() * IConfig(config).liquidateFeeRatio()) / 10000;
            if (!isIndexPrice) {
                if (isLong) {
                    IAmm(amm).forceSwap(_trader, baseToken, quoteToken, baseAmount, quoteAmount);
                } else {
                    IAmm(amm).forceSwap(_trader, quoteToken, baseToken, quoteAmount, baseAmount);
                }
            }

            if (remainBaseAmountAfterLiquidate.abs() > bonus) {
                address treasury = IAmmFactory(IAmm(amm).factory()).feeTo();
                if (treasury != address(0)) {
                    IERC20(baseToken).transfer(treasury, remainBaseAmountAfterLiquidate.abs() - bonus);
                } else {
                    IAmm(amm).forceSwap(
                        _trader,
                        baseToken,
                        quoteToken,
                        remainBaseAmountAfterLiquidate.abs() - bonus,
                        0
                    );
                }
            }
        } else {
            if (!isIndexPrice) {
                if (isLong) {
                    IAmm(amm).forceSwap(
                        _trader,
                        baseToken,
                        quoteToken,
                        ((baseSize.subU(bonus) + fundingFee).abs()),
                        quoteAmount
                    );
                } else {
                    IAmm(amm).forceSwap(
                        _trader,
                        quoteToken,
                        baseToken,
                        quoteAmount,
                        ((baseSize.subU(bonus) + fundingFee).abs())
                    );
                }
            } else {
                IAmm(amm).forceSwap(_trader, quoteToken, baseToken, 0, remainBaseAmountAfterLiquidate.abs());
            }
        }
    }

    function deposit(address user, uint256 amount) external override nonReentrant {
        require(msg.sender == amm, "Margin.deposit: REQUIRE_AMM");
        require(amount > 0, "Margin.deposit: AMOUNT_IS_ZERO");
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        require(amount <= balance - reserve, "Margin.deposit: INSUFFICIENT_AMOUNT");

        reserve = reserve + amount;

        emit Deposit(user, amount);
    }

    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external override nonReentrant {
        require(msg.sender == amm, "Margin.withdraw: REQUIRE_AMM");

        _withdraw(user, receiver, amount);
    }

    function _withdraw(
        address user,
        address receiver,
        uint256 amount
    ) internal {
        require(amount > 0, "Margin._withdraw: AMOUNT_IS_ZERO");
        require(amount <= reserve, "Margin._withdraw: NOT_ENOUGH_RESERVE");
        reserve = reserve - amount;
        IERC20(baseToken).transfer(receiver, amount);

        emit Withdraw(user, receiver, amount);
    }

    //swap exact quote to base
    function _addPositionWithAmm(
        address trader,
        bool isLong,
        uint256 quoteAmount
    ) internal returns (uint256 baseAmount) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            !isLong,
            quoteAmount
        );

        uint256[2] memory result = IAmm(amm).swap(trader, inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[1] : result[0];
    }

    //close position, swap base to get exact quoteAmount, the base has contained pnl
    function _minusPositionWithAmm(
        address trader,
        bool isLong,
        uint256 quoteAmount
    ) internal returns (uint256 baseAmount) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            quoteAmount
        );

        uint256[2] memory result = IAmm(amm).swap(trader, inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    //update global funding fee
    function updateCPF() public override returns (int256 newLatestCPF) {
        uint256 currentTimeStamp = block.timestamp;
        newLatestCPF = _getNewLatestCPF();

        latestCPF = newLatestCPF;
        lastUpdateCPF = currentTimeStamp;

        emit UpdateCPF(currentTimeStamp, newLatestCPF);
    }

    function querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) external view override returns (uint256) {
        return _querySwapBaseWithAmm(isLong, quoteAmount);
    }

    function getPosition(address trader)
        external
        view
        override
        returns (
            int256,
            int256,
            uint256
        )
    {
        Position memory position = traderPositionMap[trader];
        return (position.baseSize, position.quoteSize, position.tradeSize);
    }

    function getWithdrawable(address trader) external view override returns (uint256 withdrawable) {
        Position memory position = traderPositionMap[trader];
        int256 fundingFee = _calFundingFee(trader, _getNewLatestCPF());

        (withdrawable, ) = _getWithdrawable(position.quoteSize, position.baseSize + fundingFee, position.tradeSize);
    }

    function getNewLatestCPF() external view override returns (int256) {
        return _getNewLatestCPF();
    }

    function canLiquidate(address trader) external view override returns (bool) {
        Position memory position = traderPositionMap[trader];
        int256 fundingFee = _calFundingFee(trader, _getNewLatestCPF());

        return
            _calDebtRatio(position.quoteSize, position.baseSize + fundingFee) >= IConfig(config).liquidateThreshold();
    }

    function calFundingFee(address trader) public view override returns (int256) {
        return _calFundingFee(trader, _getNewLatestCPF());
    }

    function calDebtRatio(address trader) external view override returns (uint256 debtRatio) {
        Position memory position = traderPositionMap[trader];
        int256 fundingFee = _calFundingFee(trader, _getNewLatestCPF());

        return _calDebtRatio(position.quoteSize, position.baseSize + fundingFee);
    }

    function calUnrealizedPnl(address trader) external view override returns (int256 unrealizedPnl) {
        Position memory position = traderPositionMap[trader];
        if (position.quoteSize.abs() == 0) return 0;
        (uint256 _baseAmountT, , bool isIndexPrice) = IPriceOracle(IConfig(config).priceOracle()).getMarkPriceInRatio(
            amm,
            position.quoteSize.abs(),
            0
        );
        uint256 repayBaseAmount = isIndexPrice
            ? _baseAmountT
            : _querySwapBaseWithAmm(position.quoteSize < 0, position.quoteSize.abs());
        if (position.quoteSize < 0) {
            //borrowed - repay, earn when borrow more and repay less
            unrealizedPnl = int256(1).mulU(position.tradeSize).subU(repayBaseAmount);
        } else if (position.quoteSize > 0) {
            //repay - lent, earn when lent less and repay more
            unrealizedPnl = int256(1).mulU(repayBaseAmount).subU(position.tradeSize);
        }
    }

    function netPosition() external view override returns (int256) {
        require(totalQuoteShort < type(uint128).max, "Margin.netPosition: OVERFLOW");
        return int256(totalQuoteShort).subU(totalQuoteLong);
    }

    function totalPosition() external view override returns (uint256 totalQuotePosition) {
        totalQuotePosition = totalQuoteLong + totalQuoteShort;
    }

    //query swap exact quote to base
    function _querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) internal view returns (uint256) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            quoteAmount
        );

        uint256[2] memory result = IAmm(amm).estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    //@notice returns newLatestCPF with 1e18 multiplied
    function _getNewLatestCPF() internal view returns (int256 newLatestCPF) {
        int256 premiumFraction = IPriceOracle(IConfig(config).priceOracle()).getPremiumFraction(amm);
        uint256 maxCPFBoost = IConfig(config).maxCPFBoost();
        int256 delta;
        if (
            totalQuoteLong <= maxCPFBoost * totalQuoteShort &&
            totalQuoteShort <= maxCPFBoost * totalQuoteLong &&
            !(totalQuoteShort == 0 && totalQuoteLong == 0)
        ) {
            delta = premiumFraction >= 0
                ? premiumFraction.mulU(totalQuoteLong).divU(totalQuoteShort)
                : premiumFraction.mulU(totalQuoteShort).divU(totalQuoteLong);
        } else if (totalQuoteLong > maxCPFBoost * totalQuoteShort) {
            delta = premiumFraction >= 0 ? premiumFraction.mulU(maxCPFBoost) : premiumFraction.divU(maxCPFBoost);
        } else if (totalQuoteShort > maxCPFBoost * totalQuoteLong) {
            delta = premiumFraction >= 0 ? premiumFraction.divU(maxCPFBoost) : premiumFraction.mulU(maxCPFBoost);
        } else {
            delta = premiumFraction;
        }

        newLatestCPF = delta.mulU(block.timestamp - lastUpdateCPF) + latestCPF;
    }

    //@notice withdrawable from fundingFee, unrealizedPnl and margin
    function _getWithdrawable(
        int256 quoteSize,
        int256 baseSize,
        uint256 tradeSize
    ) internal view returns (uint256 amount, int256 unrealizedPnl) {
        if (quoteSize == 0) {
            amount = baseSize <= 0 ? 0 : baseSize.abs();
        } else if (quoteSize < 0) {
            uint256[2] memory result = IAmm(amm).estimateSwap(
                address(baseToken),
                address(quoteToken),
                0,
                quoteSize.abs()
            );

            uint256 a = result[0] * 10000;
            uint256 b = (10000 - IConfig(config).initMarginRatio());
            //calculate how many base needed to maintain current position
            uint256 baseNeeded = a / b;
            if (a % b != 0) {
                baseNeeded += 1;
            }
            //borrowed - repay, earn when borrow more and repay less
            unrealizedPnl = int256(1).mulU(tradeSize).subU(result[0]);
            amount = baseSize.abs() <= baseNeeded ? 0 : baseSize.abs() - baseNeeded;
        } else {
            uint256[2] memory result = IAmm(amm).estimateSwap(
                address(quoteToken),
                address(baseToken),
                quoteSize.abs(),
                0
            );

            uint256 baseNeeded = (result[1] * (10000 - IConfig(config).initMarginRatio())) / 10000;
            //repay - lent, earn when lent less and repay more
            unrealizedPnl = int256(1).mulU(result[1]).subU(tradeSize);
            int256 remainBase = baseSize.addU(baseNeeded);
            amount = remainBase <= 0 ? 0 : remainBase.abs();
        }
    }

    function _calFundingFee(address trader, int256 _latestCPF) internal view returns (int256) {
        Position memory position = traderPositionMap[trader];

        int256 baseAmountFunding;
        if (position.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = position.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, position.quoteSize.abs()))
                : int256(0).addU(_querySwapBaseWithAmm(false, position.quoteSize.abs()));
        }

        return (baseAmountFunding * (_latestCPF - traderCPF[trader])).divU(1e18);
    }

    function _calDebtRatio(int256 quoteSize, int256 baseSize) internal view returns (uint256 debtRatio) {
        if (quoteSize == 0 || (quoteSize > 0 && baseSize >= 0)) {
            debtRatio = 0;
        } else if (quoteSize < 0 && baseSize <= 0) {
            debtRatio = 10000;
        } else if (quoteSize > 0) {
            uint256 quoteAmount = quoteSize.abs();
            //simulate to close short, markPriceAcc bigger, asset undervalue
            uint256 baseAmount = IPriceOracle(IConfig(config).priceOracle()).getMarkPriceAcc(
                amm,
                IConfig(config).beta(),
                quoteAmount,
                false
            );

            debtRatio = baseAmount == 0 ? 10000 : (baseSize.abs() * 10000) / baseAmount;
        } else {
            uint256 quoteAmount = quoteSize.abs();
            //simulate to close long, markPriceAcc smaller, debt overvalue
            uint256 baseAmount = IPriceOracle(IConfig(config).priceOracle()).getMarkPriceAcc(
                amm,
                IConfig(config).beta(),
                quoteAmount,
                true
            );

            debtRatio = (baseAmount * 10000) / baseSize.abs();
        }
    }

    function _getSwapParam(bool isCloseLongOrOpenShort, uint256 amount)
        internal
        view
        returns (
            address inputToken,
            address outputToken,
            uint256 inputAmount,
            uint256 outputAmount
        )
    {
        if (isCloseLongOrOpenShort) {
            outputToken = quoteToken;
            outputAmount = amount;
            inputToken = baseToken;
        } else {
            inputToken = quoteToken;
            inputAmount = amount;
            outputToken = baseToken;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./LiquidityERC20.sol";
import "../interfaces/IAmmFactory.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IMarginFactory.sol";
import "../interfaces/IAmm.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IMargin.sol";
import "../interfaces/IPairFactory.sol";
import "../utils/Reentrant.sol";
import "../libraries/UQ112x112.sol";
import "../libraries/Math.sol";
import "../libraries/FullMath.sol";
import "../libraries/ChainAdapter.sol";
import "../libraries/SignedMath.sol";

import "../utils/Initializable.sol";

contract Amm is IAmm, LiquidityERC20, Reentrant, Initializable {
    using UQ112x112 for uint224;
    using SignedMath for int256;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;

    address public  override factory;
    address public override config;
    address public override baseToken;
    address public override quoteToken;
    address public override margin;

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;

    uint256 public kLast;
    uint256 public override lastPrice;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    uint112 private baseReserve; // uses single storage slot, accessible via getReserves
    uint112 private quoteReserve; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast;
    uint256 private lastBlockNumber;
    uint256 private rebaseTimestampLast;

    modifier onlyMargin() {
        require(margin == msg.sender, "Amm: ONLY_MARGIN");
        _;
    }

    // constructor() {
    //     factory = msg.sender;
    // }

    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) public initializer override {
    //    require(msg.sender == factory, "Amm.initialize: FORBIDDEN"); // sufficient check
        baseToken = baseToken_;
        quoteToken = quoteToken_;
        margin = margin_;
        factory = msg.sender ; 
        config = IAmmFactory(factory).config();
    }

    /// @notice add liquidity
    /// @dev  calculate the liquidity according to the real baseReserve.
    function mint(address to)
        external
        override
        nonReentrant
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        // only router can add liquidity
        require(IConfig(config).routerMap(msg.sender), "Amm.mint: FORBIDDEN");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings

        // get real baseReserve
        uint256 realBaseReserve = getRealBaseReserve();

        baseAmount = IERC20(baseToken).balanceOf(address(this));
        require(baseAmount > 0, "Amm.mint: ZERO_BASE_AMOUNT");

        bool feeOn = _mintFee(_baseReserve, _quoteReserve);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            (quoteAmount, ) = IPriceOracle(IConfig(config).priceOracle()).quote(baseToken, quoteToken, baseAmount);

            require(quoteAmount > 0, "Amm.mint: INSUFFICIENT_QUOTE_AMOUNT");
            liquidity = Math.sqrt(baseAmount * quoteAmount) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            quoteAmount = (baseAmount * _quoteReserve) / _baseReserve;

            // realBaseReserve
            liquidity = (baseAmount * _totalSupply) / realBaseReserve;
        }
        require(liquidity > 0, "Amm.mint: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        //price check  0.1%
        require(
            (_baseReserve + baseAmount) * _quoteReserve * 999 <= (_quoteReserve + quoteAmount) * _baseReserve * 1000,
            "Amm.mint: PRICE_BEFORE_AND_AFTER_MUST_BE_THE_SAME"
        );
        require(
            (_quoteReserve + quoteAmount) * _baseReserve * 1000 <= (_baseReserve + baseAmount) * _quoteReserve * 1001,
            "Amm.mint: PRICE_BEFORE_AND_AFTER_MUST_BE_THE_SAME"
        );

        _update(_baseReserve + baseAmount, _quoteReserve + quoteAmount, _baseReserve, _quoteReserve, false);

        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        _safeTransfer(baseToken, margin, baseAmount);
        IVault(margin).deposit(msg.sender, baseAmount);

        emit Mint(msg.sender, to, baseAmount, quoteAmount, liquidity);
    }

    /// @notice add liquidity
    /// @dev  calculate the liquidity according to the real baseReserve.
    function burn(address to)
        external
        override
        nonReentrant
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        // only router can burn liquidity
        require(IConfig(config).routerMap(msg.sender), "Amm.mint: FORBIDDEN");
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        liquidity = balanceOf[address(this)];

        // get real baseReserve
        uint256 realBaseReserve = getRealBaseReserve();

        // calculate the fee
        bool feeOn = _mintFee(_baseReserve, _quoteReserve);

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        baseAmount = (liquidity * realBaseReserve) / _totalSupply;
        // quoteAmount = (liquidity * _quoteReserve) / _totalSupply; // using balances ensures pro-rata distribution
        quoteAmount = (baseAmount * _quoteReserve) / _baseReserve;
        require(baseAmount > 0 && quoteAmount > 0, "Amm.burn: INSUFFICIENT_LIQUIDITY_BURNED");

        // gurantee the net postion close and total position(quote) in a tolerant sliappage after remove liquidity
        maxWithdrawCheck(uint256(_quoteReserve), quoteAmount);

        require(
            (_baseReserve - baseAmount) * _quoteReserve * 999 <= (_quoteReserve - quoteAmount) * _baseReserve * 1000,
            "Amm.burn: PRICE_BEFORE_AND_AFTER_MUST_BE_THE_SAME"
        );
        require(
            (_quoteReserve - quoteAmount) * _baseReserve * 1000 <= (_baseReserve - baseAmount) * _quoteReserve * 1001,
            "Amm.burn: PRICE_BEFORE_AND_AFTER_MUST_BE_THE_SAME"
        );

        _burn(address(this), liquidity);
        _update(_baseReserve - baseAmount, _quoteReserve - quoteAmount, _baseReserve, _quoteReserve, false);
        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        IVault(margin).withdraw(msg.sender, to, baseAmount);
        emit Burn(msg.sender, to, baseAmount, quoteAmount, liquidity);
    }

    function maxWithdrawCheck(uint256 quoteReserve_, uint256 quoteAmount) public view {
        int256 quoteTokenOfNetPosition = IMargin(margin).netPosition();
        uint256 quoteTokenOfTotalPosition = IMargin(margin).totalPosition();
        uint256 lpWithdrawThresholdForNet = IConfig(config).lpWithdrawThresholdForNet();
        uint256 lpWithdrawThresholdForTotal = IConfig(config).lpWithdrawThresholdForTotal();

        require(
            quoteTokenOfNetPosition.abs() * 100 <= (quoteReserve_ - quoteAmount) * lpWithdrawThresholdForNet,
            "Amm.burn: TOO_LARGE_LIQUIDITY_WITHDRAW_FOR_NET_POSITION"
        );
        require(
            quoteTokenOfTotalPosition * 100 <= (quoteReserve_ - quoteAmount) * lpWithdrawThresholdForTotal,
            "Amm.burn: TOO_LARGE_LIQUIDITY_WITHDRAW_FOR_TOTAL_POSITION"
        );
    }

    function getRealBaseReserve() public view returns (uint256 realBaseReserve) {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();

        int256 quoteTokenOfNetPosition = IMargin(margin).netPosition();

        require(int256(uint256(_quoteReserve)) + quoteTokenOfNetPosition <= 2**112, "Amm.mint:NetPosition_VALUE_WRONT");

        uint256 baseTokenOfNetPosition;

        if (quoteTokenOfNetPosition == 0) {
            return uint256(_baseReserve);
        }

        uint256[2] memory result;
        if (quoteTokenOfNetPosition < 0) {
            // long  （+， -）
            result = estimateSwap(baseToken, quoteToken, 0, quoteTokenOfNetPosition.abs());
            baseTokenOfNetPosition = result[0];

            realBaseReserve = uint256(_baseReserve) + baseTokenOfNetPosition;
        } else {
            //short  （-， +）
            result = estimateSwap(quoteToken, baseToken, quoteTokenOfNetPosition.abs(), 0);
            baseTokenOfNetPosition = result[1];

            realBaseReserve = uint256(_baseReserve) - baseTokenOfNetPosition;
        }
    }

    /// @notice
    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override nonReentrant onlyMargin returns (uint256[2] memory amounts) {
        uint256[2] memory reserves;
        (reserves, amounts) = _estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
        //check trade slippage
        _checkTradeSlippage(reserves[0], reserves[1], baseReserve, quoteReserve);
        _update(reserves[0], reserves[1], baseReserve, quoteReserve, false);

        emit Swap(trader, inputToken, outputToken, amounts[0], amounts[1]);
    }

    /// @notice  use in the situation  of forcing closing position
    function forceSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override nonReentrant onlyMargin {
        require(inputToken == baseToken || inputToken == quoteToken, "Amm.forceSwap: WRONG_INPUT_TOKEN");
        require(outputToken == baseToken || outputToken == quoteToken, "Amm.forceSwap: WRONG_OUTPUT_TOKEN");
        require(inputToken != outputToken, "Amm.forceSwap: SAME_TOKENS");
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        bool feeOn = _mintFee(_baseReserve, _quoteReserve);

        uint256 reserve0;
        uint256 reserve1;
        if (inputToken == baseToken) {
            reserve0 = _baseReserve + inputAmount;
            reserve1 = _quoteReserve - outputAmount;
        } else {
            reserve0 = _baseReserve - outputAmount;
            reserve1 = _quoteReserve + inputAmount;
        }

        _update(reserve0, reserve1, _baseReserve, _quoteReserve, true);
        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        emit ForceSwap(trader, inputToken, outputToken, inputAmount, outputAmount);
    }

    /// @notice invoke when price gap is larger than "gap" percent;
    /// @notice gap is in config contract
    function rebase() external override nonReentrant returns (uint256 quoteReserveAfter) {
        require(msg.sender == tx.origin, "Amm.rebase: ONLY_EOA");
        uint256 interval = IConfig(config).rebaseInterval();
        require(block.timestamp - rebaseTimestampLast >= interval, "Amm.rebase: NOT_REACH_NEXT_REBASE_TIME");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        bool feeOn = _mintFee(_baseReserve, _quoteReserve);

        uint256 quoteReserveFromInternal;
        (uint256 quoteReserveFromExternal, uint8 priceSource) = IPriceOracle(IConfig(config).priceOracle()).quote(
            baseToken,
            quoteToken,
            _baseReserve
        );
        if (priceSource == 0) {
            // external price use UniswapV3Twap, internal price use ammTwap
            quoteReserveFromInternal = IPriceOracle(IConfig(config).priceOracle()).quoteFromAmmTwap(
                address(this),
                _baseReserve
            );
        } else {
            // otherwise, use lastPrice as internal price
            quoteReserveFromInternal = (lastPrice * _baseReserve) / 2**112;
        }

        uint256 gap = IConfig(config).rebasePriceGap();
        require(
            quoteReserveFromExternal * 100 >= quoteReserveFromInternal * (100 + gap) ||
                quoteReserveFromExternal * 100 <= quoteReserveFromInternal * (100 - gap),
            "Amm.rebase: NOT_BEYOND_PRICE_GAP"
        );

        quoteReserveAfter = quoteReserveFromExternal;

        rebaseTimestampLast = uint32(block.timestamp % 2**32);
        _update(_baseReserve, quoteReserveAfter, _baseReserve, _quoteReserve, true);
        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        emit Rebase(_quoteReserve, quoteReserveAfter, _baseReserve, quoteReserveFromInternal, quoteReserveFromExternal);
    }

    function collectFee() external override returns (bool feeOn) {
        require(IConfig(config).routerMap(msg.sender), "Amm.collectFee: FORBIDDEN");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        feeOn = _mintFee(_baseReserve, _quoteReserve);
        if (feeOn) kLast = uint256(_baseReserve) * _quoteReserve;
    }

    /// notice view method for estimating swap
    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) public view override returns (uint256[2] memory amounts) {
        (, amounts) = _estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
    }

    //query max withdraw liquidity
    function getTheMaxBurnLiquidity() public view override returns (uint256 maxLiquidity) {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        // get real baseReserve
        uint256 realBaseReserve = getRealBaseReserve();
        int256 quoteTokenOfNetPosition = IMargin(margin).netPosition();
        uint256 quoteTokenOfTotalPosition = IMargin(margin).totalPosition();
        uint256 _totalSupply = totalSupply + getFeeLiquidity();

        uint256 lpWithdrawThresholdForNet = IConfig(config).lpWithdrawThresholdForNet();
        uint256 lpWithdrawThresholdForTotal = IConfig(config).lpWithdrawThresholdForTotal();

        //  for net position  case
        uint256 maxQuoteLeftForNet = (quoteTokenOfNetPosition.abs() * 100) / lpWithdrawThresholdForNet;
        uint256 maxWithdrawQuoteAmountForNet;
        if (_quoteReserve > maxQuoteLeftForNet) {
            maxWithdrawQuoteAmountForNet = _quoteReserve - maxQuoteLeftForNet;
        }

        //  for total position  case
        uint256 maxQuoteLeftForTotal = (quoteTokenOfTotalPosition * 100) / lpWithdrawThresholdForTotal;
        uint256 maxWithdrawQuoteAmountForTotal;
        if (_quoteReserve > maxQuoteLeftForTotal) {
            maxWithdrawQuoteAmountForTotal = _quoteReserve - maxQuoteLeftForTotal;
        }

        uint256 maxWithdrawBaseAmount;
        // use the min quote amount;
        if (maxWithdrawQuoteAmountForNet > maxWithdrawQuoteAmountForTotal) {
            maxWithdrawBaseAmount = (maxWithdrawQuoteAmountForTotal * _baseReserve) / _quoteReserve;
        } else {
            maxWithdrawBaseAmount = (maxWithdrawQuoteAmountForNet * _baseReserve) / _quoteReserve;
        }

        maxLiquidity = (maxWithdrawBaseAmount * _totalSupply) / realBaseReserve;
    }

    function getFeeLiquidity() public view override returns (uint256) {
        address feeTo = IAmmFactory(factory).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        uint256 liquidity;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(baseReserve) * quoteReserve);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);

                    uint256 feeParameter = IConfig(config).feeParameter();
                    uint256 denominator = (rootK * feeParameter) / 100 + rootKLast;
                    liquidity = numerator / denominator;
                }
            }
        }
        return liquidity;
    }

    function getReserves()
        public
        view
        override
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        )
    {
        reserveBase = baseReserve;
        reserveQuote = quoteReserve;
        blockTimestamp = blockTimestampLast;
    }

    function _checkTradeSlippage(
        uint256 baseReserveNew,
        uint256 quoteReserveNew,
        uint112 baseReserveOld,
        uint112 quoteReserveOld
    ) internal view {
        // check trade slippage for every transaction
        uint256 numerator = quoteReserveNew * baseReserveOld * 100;
        uint256 demominator = baseReserveNew * quoteReserveOld;
        uint256 tradingSlippage = IConfig(config).tradingSlippage();
        require(
            (numerator < (100 + tradingSlippage) * demominator) && (numerator > (100 - tradingSlippage) * demominator),
            "AMM._update: TRADINGSLIPPAGE_TOO_LARGE_THAN_LAST_TRANSACTION"
        );
        require(
            (quoteReserveNew * 100 < ((100 + tradingSlippage) * baseReserveNew * lastPrice) / 2**112) &&
                (quoteReserveNew * 100 > ((100 - tradingSlippage) * baseReserveNew * lastPrice) / 2**112),
            "AMM._update: TRADINGSLIPPAGE_TOO_LARGE_THAN_LAST_BLOCK"
        );
    }

    function _estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) internal view returns (uint256[2] memory reserves, uint256[2] memory amounts) {
        require(inputToken == baseToken || inputToken == quoteToken, "Amm._estimateSwap: WRONG_INPUT_TOKEN");
        require(outputToken == baseToken || outputToken == quoteToken, "Amm._estimateSwap: WRONG_OUTPUT_TOKEN");
        require(inputToken != outputToken, "Amm._estimateSwap: SAME_TOKENS");
        require(inputAmount > 0 || outputAmount > 0, "Amm._estimateSwap: INSUFFICIENT_AMOUNT");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        uint256 reserve0;
        uint256 reserve1;
        if (inputAmount > 0 && inputToken != address(0)) {
            // swapInput
            if (inputToken == baseToken) {
                outputAmount = _getAmountOut(inputAmount, _baseReserve, _quoteReserve);
                reserve0 = _baseReserve + inputAmount;
                reserve1 = _quoteReserve - outputAmount;
            } else {
                outputAmount = _getAmountOut(inputAmount, _quoteReserve, _baseReserve);
                reserve0 = _baseReserve - outputAmount;
                reserve1 = _quoteReserve + inputAmount;
            }
        } else {
            // swapOutput
            if (outputToken == baseToken) {
                require(outputAmount < _baseReserve, "AMM._estimateSwap: INSUFFICIENT_LIQUIDITY");
                inputAmount = _getAmountIn(outputAmount, _quoteReserve, _baseReserve);
                reserve0 = _baseReserve - outputAmount;
                reserve1 = _quoteReserve + inputAmount;
            } else {
                require(outputAmount < _quoteReserve, "AMM._estimateSwap: INSUFFICIENT_LIQUIDITY");
                inputAmount = _getAmountIn(outputAmount, _baseReserve, _quoteReserve);
                reserve0 = _baseReserve + inputAmount;
                reserve1 = _quoteReserve - outputAmount;
            }
        }
        reserves = [reserve0, reserve1];
        amounts = [inputAmount, outputAmount];
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Amm._getAmountOut: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Amm._getAmountOut: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 999;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "Amm._getAmountIn: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Amm._getAmountIn: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 999;
        amountIn = (numerator / denominator) + 1;
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 reserve0, uint112 reserve1) private returns (bool feeOn) {
        address feeTo = IAmmFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(reserve0) * reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);

                    uint256 feeParameter = IConfig(config).feeParameter();
                    uint256 denominator = (rootK * feeParameter) / 100 + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _update(
        uint256 baseReserveNew,
        uint256 quoteReserveNew,
        uint112 baseReserveOld,
        uint112 quoteReserveOld,
        bool isRebaseOrForceSwap
    ) private {
        require(baseReserveNew <= type(uint112).max && quoteReserveNew <= type(uint112).max, "AMM._update: OVERFLOW");

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        // last price means last block price.
        if (timeElapsed > 0 && baseReserveOld != 0 && quoteReserveOld != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(quoteReserveOld).uqdiv(baseReserveOld)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(baseReserveOld).uqdiv(quoteReserveOld)) * timeElapsed;
            // update twap
            IPriceOracle(IConfig(config).priceOracle()).updateAmmTwap(address(this));
        }

        uint256 blockNumberDelta = ChainAdapter.blockNumber() - lastBlockNumber;
        //every arbi block number calculate
        if (blockNumberDelta > 0 && baseReserveOld != 0) {
            lastPrice = uint256(UQ112x112.encode(quoteReserveOld).uqdiv(baseReserveOld));
        }

        //set the last price to current price for rebase may cause price gap oversize the tradeslippage.
        if ((lastPrice == 0 && baseReserveNew != 0) || isRebaseOrForceSwap) {
            lastPrice = uint256(UQ112x112.encode(uint112(quoteReserveNew)).uqdiv(uint112(baseReserveNew)));
        }

        baseReserve = uint112(baseReserveNew);
        quoteReserve = uint112(quoteReserveNew);

        lastBlockNumber = ChainAdapter.blockNumber();
        blockTimestampLast = blockTimestamp;

        emit Sync(baseReserve, quoteReserve);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "AMM._safeTransfer: TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IConfig {
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event RebasePriceGapChanged(uint256 oldGap, uint256 newGap);
    event RebaseIntervalChanged(uint256 oldInterval, uint256 newInterval);
    event TradingSlippageChanged(uint256 oldTradingSlippage, uint256 newTradingSlippage);
    event RouterRegistered(address indexed router);
    event RouterUnregistered(address indexed router);
    event SetLiquidateFeeRatio(uint256 oldLiquidateFeeRatio, uint256 liquidateFeeRatio);
    event SetLiquidateThreshold(uint256 oldLiquidateThreshold, uint256 liquidateThreshold);
    event SetLpWithdrawThresholdForNet(uint256 oldLpWithdrawThresholdForNet, uint256 lpWithdrawThresholdForNet);
    event SetLpWithdrawThresholdForTotal(uint256 oldLpWithdrawThresholdForTotal, uint256 lpWithdrawThresholdForTotal);
    event SetInitMarginRatio(uint256 oldInitMarginRatio, uint256 initMarginRatio);
    event SetBeta(uint256 oldBeta, uint256 beta);
    event SetFeeParameter(uint256 oldFeeParameter, uint256 feeParameter);
    event SetMaxCPFBoost(uint256 oldMaxCPFBoost, uint256 maxCPFBoost);
    event SetEmergency(address indexed router);

    /// @notice get price oracle address.
    function priceOracle() external view returns (address);

    /// @notice get beta of amm.
    function beta() external view returns (uint8);

    /// @notice get feeParameter of amm.
    function feeParameter() external view returns (uint256);

    /// @notice get init margin ratio of margin.
    function initMarginRatio() external view returns (uint256);

    /// @notice get liquidate threshold of margin.
    function liquidateThreshold() external view returns (uint256);

    /// @notice get liquidate fee ratio of margin.
    function liquidateFeeRatio() external view returns (uint256);

    /// @notice get trading slippage  of amm.
    function tradingSlippage() external view returns (uint256);

    /// @notice get rebase gap of amm.
    function rebasePriceGap() external view returns (uint256);

    /// @notice get lp withdraw threshold of amm.
    function lpWithdrawThresholdForNet() external view returns (uint256);
  
    /// @notice get lp withdraw threshold of amm.
    function lpWithdrawThresholdForTotal() external view returns (uint256);

    function rebaseInterval() external view returns (uint256);

    function routerMap(address) external view returns (bool);

    function maxCPFBoost() external view returns (uint256);

    function inEmergency(address router) external view returns (bool);

    function registerRouter(address router) external;

    function unregisterRouter(address router) external;

    /// @notice Set a new oracle
    /// @param newOracle new oracle address.
    function setPriceOracle(address newOracle) external;

    /// @notice Set a new beta of amm
    /// @param newBeta new beta.
    function setBeta(uint8 newBeta) external;

    /// @notice Set a new rebase gap of amm
    /// @param newGap new gap.
    function setRebasePriceGap(uint256 newGap) external;

    function setRebaseInterval(uint256 interval) external;

    /// @notice Set a new trading slippage of amm
    /// @param newTradingSlippage .
    function setTradingSlippage(uint256 newTradingSlippage) external;

    /// @notice Set a new init margin ratio of margin
    /// @param marginRatio new init margin ratio.
    function setInitMarginRatio(uint256 marginRatio) external;

    /// @notice Set a new liquidate threshold of margin
    /// @param threshold new liquidate threshold of margin.
    function setLiquidateThreshold(uint256 threshold) external;
  
     /// @notice Set a new lp withdraw threshold of amm net position
    /// @param newLpWithdrawThresholdForNet new lp withdraw threshold of amm.
    function setLpWithdrawThresholdForNet(uint256 newLpWithdrawThresholdForNet) external;
    
    /// @notice Set a new lp withdraw threshold of amm total position
    /// @param newLpWithdrawThresholdForTotal new lp withdraw threshold of amm.
    function setLpWithdrawThresholdForTotal(uint256 newLpWithdrawThresholdForTotal) external;

    /// @notice Set a new liquidate fee of margin
    /// @param feeRatio new liquidate fee of margin.
    function setLiquidateFeeRatio(uint256 feeRatio) external;

    /// @notice Set a new feeParameter.
    /// @param newFeeParameter New feeParameter get from AMM swap fee.
    /// @dev feeParameter = (1/fee -1 ) *100 where fee set by owner.
    function setFeeParameter(uint256 newFeeParameter) external;

    function setMaxCPFBoost(uint256 newMaxCPFBoost) external;

    function setEmergency(address router) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, address indexed receiver, uint256 amount);

    /// @notice deposit baseToken to user
    function deposit(address user, uint256 amount) external;

    /// @notice withdraw user's baseToken from margin contract to receiver
    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external;

    /// @notice get baseToken amount in margin
    function reserve() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPriceOracle {
    function setupTwap(address amm) external;

    function quoteFromAmmTwap(address amm, uint256 baseAmount) external view returns (uint256 quoteAmount);

    function updateAmmTwap(address pair) external;

    // index price maybe get from different oracle, like UniswapV3 TWAP,Chainklink, or others
    // source represents which oracle used. 0 = UniswapV3 TWAP
    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount, uint8 source);

    function getIndexPrice(address amm) external view returns (uint256);

    function getMarketPrice(address amm) external view returns (uint256);

    function getMarkPrice(address amm) external view returns (uint256 price, bool isIndexPrice);

    function getMarkPriceAfterSwap(
        address amm,
        uint256 quoteAmount,
        uint256 baseAmount
    ) external view returns (uint256 price, bool isIndexPrice);

    function getMarkPriceInRatio(
        address amm,
        uint256 quoteAmount,
        uint256 baseAmount
    )
        external
        view
        returns (
            uint256 resultBaseAmount,
            uint256 resultQuoteAmount,
            bool isIndexPrice
        );

    function getMarkPriceAcc(
        address amm,
        uint8 beta,
        uint256 quoteAmount,
        bool negative
    ) external view returns (uint256 baseAmount);

    function getPremiumFraction(address amm) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SignedMath {
    function abs(int256 x) internal pure returns (uint256) {
        if (x < 0) {
            return uint256(0 - x);
        }
        return uint256(x);
    }

    function addU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x + int256(y);
    }

    function subU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x - int256(y);
    }

    function mulU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x * int256(y);
    }

    function divU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x / int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IArbSys {
    function arbBlockNumber() external view returns (uint256);
}

library ChainAdapter {
    address constant arbSys = address(100);

    function blockNumber() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        if (chainId == 421611 || chainId == 42161) { // Arbitrum Testnet || Arbitrum Mainnet
            return IArbSys(arbSys).arbBlockNumber();
        } else {
            return block.number;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/ILiquidityERC20.sol";

contract LiquidityERC20 is ILiquidityERC20 {
    string public constant override name = "APEX LP";
    string public constant override symbol = "APEX-LP";
    uint8 public constant override decimals = 18;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public immutable override DOMAIN_SEPARATOR;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public override nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "LiquidityERC20: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "LiquidityERC20: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x > y) {
            return y;
        }
        return x;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        // todo unchecked
        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ILiquidityERC20 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
}