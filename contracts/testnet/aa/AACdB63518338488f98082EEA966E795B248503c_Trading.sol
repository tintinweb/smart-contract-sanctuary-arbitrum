//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./utils/MetaContext.sol";
import "./interfaces/ITrading.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPairsContract.sol";
import "./interfaces/IReferrals.sol";
import "./interfaces/IPosition.sol";
import "./interfaces/IGovNFT.sol";
import "./interfaces/IStableVault.sol";
import "./interfaces/INativeStableVault.sol";
import "./utils/TradingLibrary.sol";

interface ITradingExtension {
    function getVerifiedPrice(
        uint _asset,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        bool _isTrade,
        uint _withSpreadIsLong
    ) external returns(uint256 _price);
    function getRef(
        address _trader
    ) external pure returns(address);
    function _setReferral(
        bytes32 _referral,
        address _trader
    ) external;
    function validateTrade(uint _asset, address _tigAsset, uint _margin, uint _leverage) external view;
    function isPaused() external view returns(bool);
    function minPos(address) external view returns(uint);
    function modifyLongOi(
        uint _asset,
        address _tigAsset,
        bool _onOpen,
        uint _size
    ) external;
    function modifyShortOi(
        uint _asset,
        address _tigAsset,
        bool _onOpen,
        uint _size
    ) external;
    function paused() external returns(bool);
    function getSpread(uint _asset) external returns(uint);
    function _limitClose(
        uint _id,
        bool _tp,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external returns(uint _limitPrice, address _tigAsset);
    function _checkGas() external view;
    function _closePosition(
        uint _id,
        uint _price,
        uint _percent
    ) external returns (IPosition.Trade memory _trade, uint256 _positionSize, int256 _payout);
}

interface IStable is IERC20 {
    function burnFrom(address account, uint amount) external;
    function mintFor(address account, uint amount) external;
}

interface ExtendedIERC20 is IERC20 {
    function decimals() external view returns (uint);
}

interface ERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract Trading is MetaContext, ITrading {

    error LimitNotSet(); //7
    error NotLiquidatable();
    error TradingPaused();
    error NotNativeSupport();
    error BadDeposit();
    error BadWithdraw();
    error ValueNotEqualToMargin();
    error BadLeverage();
    error NotMargin();
    error NotAllowedPair();
    error BelowMinPositionSize();
    error BadClosePercent();
    error NoPrice();
    error LiqThreshold();

    uint constant private DIVISION_CONSTANT = 1e10; // 100%
    address constant private eth = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint private constant liqPercent = 9e9; // 90%

    struct Fees {
        uint daoFees;
        uint burnFees;
        uint referralFees;
        uint botFees;
    }
    Fees public openFees = Fees(
        0,
        0,
        0,
        0
    );
    Fees public closeFees = Fees(
        0,
        0,
        0,
        0
    );
    uint public limitOrderPriceRange = 1e8; // 1%

    uint public maxWinPercent;
    uint public vaultFundingPercent;

    IPairsContract private pairsContract;
    IPosition private position;
    IGovNFT private gov;
    ITradingExtension private tradingExtension;

    struct Delay {
        uint delay; // Block number where delay ends
        bool actionType; // True for open, False for close
    }
    mapping(uint => Delay) public blockDelayPassed; // id => Delay
    uint public blockDelay;
    mapping(uint => uint) public limitDelay; // id => block.timestamp

    constructor(
        address _position,
        address _gov,
        address _pairsContract
    )
    {
        position = IPosition(_position);
        gov = IGovNFT(_gov);
        pairsContract = IPairsContract(_pairsContract);
    }

    function setTradingExtension(
        address _ext
    ) external onlyOwner() {
        tradingExtension = ITradingExtension(_ext);
    }

    // ===== END-USER FUNCTIONS =====

    /**
     * @param _tradeInfo Trade info
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     * @param _permitData data and signature needed for token approval
     */
    function initiateMarketOrder(
        TradeInfo calldata _tradeInfo,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        ERC20PermitData calldata _permitData
    )
        external payable
    {
        _checkDelay(position.getCount(), true);
        address _tigAsset = IStableVault(_tradeInfo.stableVault).stable();
        tradingExtension.validateTrade(_tradeInfo.asset, _tigAsset, _tradeInfo.margin, _tradeInfo.leverage);
        tradingExtension._setReferral(_tradeInfo.referral, _msgSender());
        uint256 _fee = _handleOpenFees(_tradeInfo.asset, _tradeInfo.margin*_tradeInfo.leverage/1e18, _msgSender(), _tigAsset);
        uint256 _positionSize = (_tradeInfo.margin - _fee) * _tradeInfo.leverage / 1e18;
        _handleDeposit(_tigAsset, _tradeInfo.marginAsset, _tradeInfo.margin, _tradeInfo.stableVault, _permitData);
        uint _withSpreadIsLong = _tradeInfo.direction ? 1 : 2;
        uint256 _price = tradingExtension.getVerifiedPrice(_tradeInfo.asset, _priceData, _signature, true, _withSpreadIsLong);
        _checkSl(_tradeInfo.slPrice, _tradeInfo.direction, _price);
        unchecked {
            if (_tradeInfo.direction) {
                tradingExtension.modifyLongOi(_tradeInfo.asset, _tigAsset, true, _positionSize);
            } else {
                tradingExtension.modifyShortOi(_tradeInfo.asset, _tigAsset, true, _positionSize);
            }
        }
        updateFunding(_tradeInfo.asset, _tigAsset);
        position.mint(
            IPosition.MintTrade(
                _msgSender(),
                _tradeInfo.margin - _fee,
                _tradeInfo.leverage,
                _tradeInfo.asset,
                _tradeInfo.direction,
                _price,
                _tradeInfo.tpPrice,
                _tradeInfo.slPrice,
                0,
                _tigAsset
            )
        );
        unchecked {
            emit PositionOpened(_tradeInfo, 0, _price, position.getCount()-1, _msgSender());
        }   
    }

    /**
     * @dev initiate closing position
     * @param _id id of the position NFT
     * @param _percent percent of the position being closed in BP
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     * @param _stableVault StableVault address
     * @param _outputToken Token received upon closing trade
     */
    function initiateCloseOrder(
        uint _id,
        uint _percent,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        address _stableVault,
        address _outputToken
    )
        external
    {
        _checkDelay(_id, false);
        _checkOwner(_id);
        IPosition.Trade memory _trade = position.trades(_id);
        if (_trade.orderType != 0) revert("4"); //IsLimit        
        uint256 _price = tradingExtension.getVerifiedPrice(_trade.asset, _priceData, _signature, true, 0);

        if (_percent > DIVISION_CONSTANT || _percent == 0) revert BadClosePercent();
        _closePosition(_id, _percent, _price, _stableVault, _outputToken); 
    }

    function addToPosition(
        uint _id,
        uint _addMargin,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        address _stableVault,
        address _marginAsset,
        ERC20PermitData calldata _permitData
    )
        external
    {
        _checkOwner(_id);
        _checkDelay(_id, true);
        IPosition.Trade memory _trade = position.trades(_id);
        tradingExtension.validateTrade(_trade.asset, _trade.tigAsset, _trade.margin + _addMargin, _trade.leverage);
        if (_trade.orderType != 0) revert("4"); //IsLimit
        uint _fee = _handleOpenFees(_trade.asset, _addMargin*_trade.leverage/1e18, _msgSender(), _trade.tigAsset);
        _handleDeposit(
            _trade.tigAsset,
            _marginAsset,
            _addMargin - _fee,
            _stableVault,
            _permitData
        );
        position.setAccInterest(_id);
        unchecked {
            uint _positionSize = (_addMargin - _fee) * _trade.leverage / 1e18;
            if (_trade.direction) {
                tradingExtension.modifyLongOi(_trade.asset, _trade.tigAsset, true, _positionSize);
            } else {
                tradingExtension.modifyShortOi(_trade.asset, _trade.tigAsset, true, _positionSize);     
            }
            updateFunding(_trade.asset, _trade.tigAsset);
            _addMargin -= _fee;
            uint _newMargin = _trade.margin + _addMargin;
            uint _newPrice;
            {
                uint256 _price = tradingExtension.getVerifiedPrice(_trade.asset, _priceData, _signature, true, _trade.direction ? 1 : 2);
                _newPrice = _trade.price*_trade.margin/_newMargin + _price*_addMargin/_newMargin;
            }

            position.addToPosition(
                _id,
                _newMargin,
                _newPrice
            );
            
            emit AddToPosition(_id, _newMargin, _newPrice, _trade.trader);
        }
    }

    function initiateLimitOrder(
        TradeInfo calldata _tradeInfo,
        uint256 _orderType, // 1 limit, 2 momentum
        uint256 _price,
        ERC20PermitData calldata _permitData
    )
        external payable
    {
        address _tigAsset = IStableVault(_tradeInfo.stableVault).stable();
        tradingExtension.validateTrade(_tradeInfo.asset, _tigAsset, _tradeInfo.margin, _tradeInfo.leverage);
        if (_orderType == 0) revert("5");
        if (_price == 0) revert NoPrice();
        tradingExtension._setReferral(_tradeInfo.referral, _msgSender());
        _handleDeposit(_tigAsset, _tradeInfo.marginAsset, _tradeInfo.margin, _tradeInfo.stableVault, _permitData);
        _checkSl(_tradeInfo.slPrice, _tradeInfo.direction, _price);
        uint256 _id = position.getCount();
        position.mint(
            IPosition.MintTrade(
                _msgSender(),
                _tradeInfo.margin,
                _tradeInfo.leverage,
                _tradeInfo.asset,
                _tradeInfo.direction,
                _price,
                _tradeInfo.tpPrice,
                _tradeInfo.slPrice,
                _orderType,
                _tigAsset
            )
        );
        limitDelay[_id] = block.timestamp + 10;
        emit PositionOpened(_tradeInfo, _orderType, _price, _id, _msgSender());
    }

    function cancelLimitOrder(
        uint256 _id
    )
        external
    {
        _checkOwner(_id);
        IPosition.Trade memory _trade = position.trades(_id);
        if (_trade.orderType == 0) revert("5");
        IStable(_trade.tigAsset).mintFor(_msgSender(), _trade.margin);
        position.burn(_id);
        emit LimitCancelled(_id, _msgSender());
    }

    function addMargin(
        uint256 _id,
        address _marginAsset,
        address _stableVault,
        uint256 _addMargin,
        ERC20PermitData calldata _permitData
    )
        external payable
    {
        _checkOwner(_id);
        IPosition.Trade memory _trade = position.trades(_id);
        if (_trade.orderType != 0) revert("4"); //IsLimit
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_trade.asset);
        _handleDeposit(_trade.tigAsset, _marginAsset, _addMargin, _stableVault, _permitData);
        unchecked {
            uint256 _newMargin = _trade.margin + _addMargin;
            uint256 _newLeverage = _trade.margin * _trade.leverage / _newMargin;
            if (_newLeverage < asset.minLeverage) revert("!lev");
            position.modifyMargin(_id, _newMargin, _newLeverage);
            emit MarginModified(_id, _newMargin, _newLeverage, true, _msgSender());            
        }
    }

    function removeMargin(
        uint256 _id,
        address _stableVault,
        address _outputToken,
        uint256 _removeMargin,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    )
        external
    {
        _checkOwner(_id);

        IPosition.Trade memory _trade = position.trades(_id);
        if (_trade.orderType != 0) revert("4"); //IsLimit
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_trade.asset);
        uint256 _newMargin = _trade.margin - _removeMargin;
        uint256 _newLeverage = _trade.margin * _trade.leverage / _newMargin;
        if (_newLeverage > asset.maxLeverage) revert("!lev");
        uint _assetPrice = tradingExtension.getVerifiedPrice(_trade.asset, _priceData, _signature, true, 0);
        (,int256 _payout) = TradingLibrary.pnl(_trade.direction, _assetPrice, _trade.price, _newMargin, _newLeverage, _trade.accInterest);
        unchecked {
            if (_payout <= int256(_newMargin*(DIVISION_CONSTANT-liqPercent)/DIVISION_CONSTANT)) revert LiqThreshold();
        }
        position.modifyMargin(_id, _newMargin, _newLeverage);
        _handleWithdraw(_trade, _stableVault, _outputToken, _removeMargin);
        emit MarginModified(_id, _newMargin, _newLeverage, false, _msgSender());
    }

    function updateTpSl(
        bool _type, // true is TP
        uint _id,
        uint _limitPrice,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    )
        external
    {
        _checkOwner(_id);
        IPosition.Trade memory _trade = position.trades(_id);
        if (_trade.orderType != 0) revert("4"); //IsLimit
        if (_type) {
            position.modifyTp(_id, _limitPrice);
        } else {
            uint256 _price = tradingExtension.getVerifiedPrice(_trade.asset, _priceData, _signature, true, 0);
            _checkSl(_limitPrice, _trade.direction, _price);
            position.modifySl(_id, _limitPrice);
        }
        emit UpdateTPSL(_id, _type, _limitPrice, _msgSender());
    }

    function executeLimitOrder(
        uint _id, 
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) 
        external
    {
        unchecked {
            _checkDelay(_id, true);
            tradingExtension._checkGas();
            if (tradingExtension.paused()) revert TradingPaused();
            require(block.timestamp >= limitDelay[_id]);
            IPosition.Trade memory trade = position.trades(_id);
            IPairsContract.Asset memory asset = pairsContract.idToAsset(trade.asset);
            uint256 _refFee = (trade.margin*trade.leverage/1e18)*openFees.referralFees*asset.feeMultiplier/DIVISION_CONSTANT/DIVISION_CONSTANT;
            IStable(trade.tigAsset).mintFor(
                trade.trader,
                _refFee
            );
            uint _fee = _handleOpenFees(trade.asset, trade.margin*trade.leverage/1e18, trade.trader, trade.tigAsset);
            uint256 _price = tradingExtension.getVerifiedPrice(trade.asset, _priceData, _signature, false, 0);
            if (trade.orderType == 0) revert("5");
            if (_price > trade.price+trade.price*limitOrderPriceRange/DIVISION_CONSTANT || _price < trade.price-trade.price*limitOrderPriceRange/DIVISION_CONSTANT) revert("6"); //LimitNotMet
            _price = tradingExtension.getVerifiedPrice(trade.asset, _priceData, _signature, false, trade.direction ? 1 : 2);
            if (trade.direction && trade.orderType == 1) {
                if (trade.price < _price) revert("6"); //LimitNotMet
            } else if (!trade.direction && trade.orderType == 1) {
                if (trade.price > _price) revert("6"); //LimitNotMet      
            } else if (!trade.direction && trade.orderType == 2) {
                if (trade.price < _price) revert("6"); //LimitNotMet
                trade.price = _price;
            } else {
                if (trade.price > _price) revert("6"); //LimitNotMet
                trade.price = _price;
            }
            if (trade.direction) {
                tradingExtension.modifyLongOi(trade.asset, trade.tigAsset, true, trade.margin*trade.leverage/1e18);
            } else {
                tradingExtension.modifyShortOi(trade.asset, trade.tigAsset, true, trade.margin*trade.leverage/1e18);
            }
            updateFunding(trade.asset, trade.tigAsset);
            position.executeLimitOrder(_id, trade.price, trade.margin - _fee);
            emit LimitOrderExecuted(trade.asset, trade.direction, trade.price, trade.leverage, trade.margin - _fee, _id, trade.trader, _msgSender());
        }
    }

    /**
     * @dev liquidate position
     * @param _id id of the position NFT
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     */
    function liquidatePosition(
        uint _id,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    )
        external
    {
        unchecked {
            tradingExtension._checkGas();
            IPosition.Trade memory _trade = position.trades(_id);
            if (_trade.orderType != 0) revert("4"); //IsLimit

            uint256 _price = tradingExtension.getVerifiedPrice(_trade.asset, _priceData, _signature, false, 0);
            (uint256 _positionSizeAfterPrice, int256 _payout) = TradingLibrary.pnl(_trade.direction, _price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
            uint256 _positionSize = _trade.margin*_trade.leverage/1e18;
            if (_payout > int256(_trade.margin*(DIVISION_CONSTANT-liqPercent)/DIVISION_CONSTANT)) revert NotLiquidatable();
            if (_trade.direction) {
                tradingExtension.modifyLongOi(_trade.asset, _trade.tigAsset, false, _positionSize);
            } else {
                tradingExtension.modifyShortOi(_trade.asset, _trade.tigAsset, false, _positionSize);
            }
            updateFunding(_trade.asset, _trade.tigAsset);
            _handleCloseFees(_trade.asset, type(uint).max, _trade.tigAsset, _positionSizeAfterPrice, _trade.trader);
            position.burn(_id);
            emit PositionLiquidated(_id, _trade.trader, _msgSender());
        }
    }

    /**
     * @dev close position at a pre-set price
     * @param _id id of the position NFT
     * @param _tp true if take profit
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     */
    function limitClose(
        uint _id,
        bool _tp,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    )
        external
    {
        _checkDelay(_id, false);
        (uint _limitPrice, address _tigAsset) = tradingExtension._limitClose(_id, _tp, _priceData, _signature);
        _closePosition(_id, DIVISION_CONSTANT, _limitPrice, address(0), _tigAsset);
    }



    // ===== INTERNAL FUNCTIONS =====

    /**
     * @dev close the initiated position.
     * @param _id id of the position NFT
     * @param _percent percent of the position being closed in BP
     * @param _price asset price
     * @param _stableVault StableVault address
     * @param _outputToken Token that trader will receive
     */
    function _closePosition(
        uint _id,
        uint _percent,
        uint _price,
        address _stableVault,
        address _outputToken
    )
        internal
    {
        (IPosition.Trade memory _trade, uint256 _positionSize, int256 _payout) = tradingExtension._closePosition(_id, _price, _percent);
        position.setAccInterest(_id);
        updateFunding(_trade.asset, _trade.tigAsset);
        if (_percent < DIVISION_CONSTANT) {
            if ((_trade.margin*_trade.leverage*(DIVISION_CONSTANT-_percent)/DIVISION_CONSTANT)/1e18 < tradingExtension.minPos(_trade.tigAsset)) revert("!size");
            position.reducePosition(_id, _percent);
        } else {
            position.burn(_id);
        }
        uint256 _toMint;
        if (_payout > 0) {
            unchecked {
                _toMint = _handleCloseFees(_trade.asset, uint256(_payout)*_percent/DIVISION_CONSTANT, _trade.tigAsset, _positionSize*_percent/DIVISION_CONSTANT, _trade.trader);
                if (maxWinPercent > 0 && _toMint > _trade.margin*maxWinPercent/DIVISION_CONSTANT) {
                    _toMint = _trade.margin*maxWinPercent/DIVISION_CONSTANT;
                }
            }
            _handleWithdraw(_trade, _stableVault, _outputToken, _toMint);
        }
        emit PositionClosed(_id, _price, _percent, _toMint, _trade.trader, _msgSender());
    }

    function _handleDeposit(address _tigAsset, address _marginAsset, uint256 _margin, address _stableVault, ERC20PermitData calldata _permitData) internal {
        IStable tigAsset = IStable(_tigAsset);
        if (_tigAsset != _marginAsset) {
            if (msg.value > 0) {
                if (_marginAsset != eth) revert BadDeposit();
            } else {
                if (_permitData.usePermit) {
                    ERC20Permit(_marginAsset).permit(_msgSender(), address(this), _permitData.amount, _permitData.deadline, _permitData.v, _permitData.r, _permitData.s);
                }
            }
            uint256 _balBefore = tigAsset.balanceOf(address(this));
            if (_marginAsset != eth){
                uint _marginDecMultiplier = 10**(18-ExtendedIERC20(_marginAsset).decimals());
                IERC20(_marginAsset).transferFrom(_msgSender(), address(this), _margin/_marginDecMultiplier);
                IERC20(_marginAsset).approve(_stableVault, type(uint).max);
                IStableVault(_stableVault).deposit(_marginAsset, _margin/_marginDecMultiplier);
                if (tigAsset.balanceOf(address(this)) != _balBefore + _margin) revert BadDeposit();
                tigAsset.burnFrom(address(this), tigAsset.balanceOf(address(this)));
            } else {
                if (msg.value != _margin) revert ValueNotEqualToMargin();
                try INativeStableVault(_stableVault).depositNative{value: _margin}() {} catch {
                    revert NotNativeSupport();
                }
                if (tigAsset.balanceOf(address(this)) != _balBefore + _margin) revert BadDeposit();
                tigAsset.burnFrom(address(this), _margin);
            }
        } else {
            tigAsset.burnFrom(_msgSender(), _margin);
        }        
    }

    function _handleWithdraw(IPosition.Trade memory _trade, address _stableVault, address _outputToken, uint _toMint) internal {
        IStable(_trade.tigAsset).mintFor(address(this), _toMint);
        if (_outputToken == _trade.tigAsset) {
            IERC20(_outputToken).transfer(_trade.trader, _toMint);
        } else {
            if (_outputToken != eth) {
                uint256 _balBefore = IERC20(_outputToken).balanceOf(address(this));
                IStableVault(_stableVault).withdraw(_outputToken, _toMint);
                if (IERC20(_outputToken).balanceOf(address(this)) != _balBefore + _toMint/(10**(18-ExtendedIERC20(_outputToken).decimals()))) revert BadWithdraw();
                IERC20(_outputToken).transfer(_trade.trader, IERC20(_outputToken).balanceOf(address(this)) - _balBefore);          
            } else {
                uint256 _balBefore = address(this).balance;
                try INativeStableVault(_stableVault).withdrawNative(_toMint) {} catch {
                    revert NotNativeSupport();
                }
                if (address(this).balance != _balBefore + _toMint) revert BadWithdraw();
                payable(_msgSender()).transfer(address(this).balance - _balBefore);
            }
        }        
    }

    /**
     * @dev handle fees distribution and margin size after fees for opening
     * @param _asset asset id
     * @param _positionSize position size
     * @param _trader trader address
     * @param _tigAsset tigAsset address
     */
    function _handleOpenFees(
        uint _asset,
        uint _positionSize,
        address _trader,
        address _tigAsset
    )
        internal
        returns (uint _feePaid)
    {
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_asset);
        Fees memory _fees = openFees;
        unchecked {
            _fees.daoFees = _fees.daoFees * asset.feeMultiplier / DIVISION_CONSTANT;
            _fees.burnFees = _fees.burnFees * asset.feeMultiplier / DIVISION_CONSTANT;
            _fees.referralFees = _fees.referralFees * asset.feeMultiplier / DIVISION_CONSTANT;
            _fees.botFees = _fees.botFees * asset.feeMultiplier / DIVISION_CONSTANT;
        }
        address _referrer = tradingExtension.getRef(_trader); //referrals.getReferral(referrals.getReferred(_trader));
        if (_referrer != address(0)) {
            unchecked {
                IStable(_tigAsset).mintFor(
                    _referrer,
                    _positionSize
                    * _fees.referralFees // get referral fee%
                    / DIVISION_CONSTANT // divide by 100%
                );
            }
            _fees.daoFees = _fees.daoFees - _fees.referralFees*2;
        }
        if (_trader != _msgSender()) {
            unchecked {
                IStable(_tigAsset).mintFor(
                    _msgSender(),
                    _positionSize
                    * _fees.botFees // get bot fee%
                    / DIVISION_CONSTANT // divide by 100%
                );
            }
            _fees.daoFees = _fees.daoFees - _fees.botFees;
        } else {
            _fees.botFees = 0;
        }
        unchecked {
            uint _daoFeesPaid = _positionSize * _fees.daoFees / DIVISION_CONSTANT;
            _feePaid =
                _positionSize
                * (_fees.burnFees + _fees.botFees) // get total fee%
                / DIVISION_CONSTANT // divide by 100%
                + _daoFeesPaid;
            emit FeesDistributed(
                _tigAsset,
                _daoFeesPaid,
                _positionSize * _fees.burnFees / DIVISION_CONSTANT,
                _referrer != address(0) ? _positionSize * _fees.referralFees / DIVISION_CONSTANT : 0,
                _positionSize * _fees.botFees / DIVISION_CONSTANT,
                _referrer
            );
            IStable(_tigAsset).mintFor(address(this), _daoFeesPaid);
        }
        gov.distribute(_tigAsset, IStable(_tigAsset).balanceOf(address(this)));
    }

    /**
     * @dev handle fees distribution after closing
     * @param _asset asset id
     * @param _payout payout to trader before fees
     * @param _tigAsset margin asset
     * @param _positionSize position size + pnl
     * @param _trader trader address
     * @return payout_ payout to trader after fees
     */
    function _handleCloseFees(
        uint _asset,
        uint _payout,
        address _tigAsset,
        uint _positionSize,
        address _trader
    )
        internal
        returns (uint payout_)
    {
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_asset);
        Fees memory _fees = closeFees;
        uint _daoFeesPaid;
        uint _burnFeesPaid;
        uint _referralFeesPaid;
        unchecked {
            _daoFeesPaid = (_positionSize*_fees.daoFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
            _burnFeesPaid = (_positionSize*_fees.burnFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
        }
        uint _botFeesPaid;
        address _referrer = tradingExtension.getRef(_trader);//referrals.getReferral(referrals.getReferred(_trader));
        if (_referrer != address(0)) {
            unchecked {
                _referralFeesPaid = (_positionSize*_fees.referralFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
            }
            IStable(_tigAsset).mintFor(
                _referrer,
                _referralFeesPaid
            );
             _daoFeesPaid = _daoFeesPaid-_referralFeesPaid*2;
        }
        if (_trader != _msgSender()) {
            unchecked {
                _botFeesPaid = (_positionSize*_fees.botFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
                IStable(_tigAsset).mintFor(
                    _msgSender(),
                    _botFeesPaid
                );
            }
            _daoFeesPaid = _daoFeesPaid - _botFeesPaid;
        }
        emit FeesDistributed(_tigAsset, _daoFeesPaid, _burnFeesPaid, _referralFeesPaid, _botFeesPaid, _referrer);
        payout_ = _payout - _daoFeesPaid - _burnFeesPaid - _botFeesPaid;
        IStable(_tigAsset).mintFor(address(this), _daoFeesPaid);
        IStable(_tigAsset).approve(address(gov), type(uint).max);
        gov.distribute(_tigAsset, _daoFeesPaid);
        return payout_;
    }

    function updateFunding(uint256 _asset, address _tigAsset) internal {
        position.updateFunding(
            _asset,
            _tigAsset,
            pairsContract.idToOi(_asset, _tigAsset).longOi,
            pairsContract.idToOi(_asset, _tigAsset).shortOi,
            pairsContract.idToAsset(_asset).baseFundingRate,
            vaultFundingPercent
        );
    }

    function _checkSl(uint _sl, bool _direction, uint _price) internal pure {
        if (_direction) {
            if (_sl > _price) revert("3"); //BadStopLoss
        } else {
            if (_sl < _price && _sl != 0) revert("3"); //BadStopLoss
        }
    }

    function _checkOwner(uint _id) internal view {
        if (position.ownerOf(_id) != _msgSender()) revert("2"); //NotPositionOwner   
    }

    function _checkDelay(uint _id, bool _type) internal {
        unchecked {
            Delay memory _delay = blockDelayPassed[_id];
            if (_delay.actionType == _type) {
                blockDelayPassed[_id].delay = block.number + blockDelay;
            } else {
                if (block.number < _delay.delay) revert("0"); //Wait
                blockDelayPassed[_id].delay = block.number + blockDelay;
                blockDelayPassed[_id].actionType = _type;
            }
        }
    }

    // ===== GOVERNANCE-ONLY =====

    /**
     * @notice in blocks not seconds
     */
    function setBlockDelay(
        uint _blockDelay
    )
        external
        onlyOwner
    {
        blockDelay = _blockDelay;
    }

    function setMaxWinPercent(
        uint _maxWinPercent
    )
        external
        onlyOwner
    {
        maxWinPercent = _maxWinPercent;
    }

    function setLimitOrderPriceRange(uint _range) external onlyOwner {
        limitOrderPriceRange = _range;
    }

    /**
     * @dev Sets the fees for the trading protocol
     * @param _daoFees Fees distributed to the DAO
     * @param _burnFees Fees which get burned
     * @param _referralFees Fees given to referrers
     * @param _botFees Fees given to bots that execute limit orders
     */
    function setFees(bool _open, uint _daoFees, uint _burnFees, uint _referralFees, uint _botFees, uint _percent) external onlyOwner {
        unchecked {
            require(_daoFees >= _botFees+_referralFees*2);
            if (_open) {
                openFees.daoFees = _daoFees;
                openFees.burnFees = _burnFees;
                openFees.referralFees = _referralFees;
                openFees.botFees = _botFees;
            } else {
                closeFees.daoFees = _daoFees;
                closeFees.burnFees = _burnFees;
                closeFees.referralFees = _referralFees;
                closeFees.botFees = _botFees;                
            }
            require(_percent <= DIVISION_CONSTANT);
            vaultFundingPercent = _percent;
        }
    }

    // ===== EVENTS =====

    event PositionOpened(
        TradeInfo _tradeInfo,
        uint _orderType,
        uint _price,
        uint _id,
        address _trader
    );

    event PositionClosed(
        uint _id,
        uint _closePrice,
        uint _percent,
        uint _payout,
        address _trader,
        address _executor
    );

    event PositionLiquidated(
        uint _id,
        address _trader,
        address _executor
    );

    event LimitOrderExecuted(
        uint _asset,
        bool _direction,
        uint _openPrice,
        uint _lev,
        uint _margin,
        uint _id,
        address _trader,
        address _executor
    );

    event UpdateTPSL(
        uint _id,
        bool _isTp,
        uint _price,
        address _trader
    );

    event LimitCancelled(
        uint _id,
        address _trader
    );

    event MarginModified(
        uint _id,
        uint _newMargin,
        uint _newLeverage,
        bool _isMarginAdded,
        address _trader
    );

    event AddToPosition(
        uint _id,
        uint _newMargin,
        uint _newPrice,
        address _trader
    );

    event FeesDistributed(
        address _tigAsset,
        uint _daoFees,
        uint _burnFees,
        uint _refFees,
        uint _botFees,
        address _referrer
    );

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaContext is Ownable {
    mapping(address => bool) private _isTrustedForwarder;

    function setTrustedForwarder(address _forwarder, bool _bool) external onlyOwner {
        _isTrustedForwarder[_forwarder] = _bool;
    }

    function isTrustedForwarder(address _forwarder) external view returns (bool) {
        return _isTrustedForwarder[_forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (_isTrustedForwarder[msg.sender]) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (_isTrustedForwarder[msg.sender]) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferrals {

    function createReferralCode(bytes32 _hash) external;
    function setReferred(address _referredTrader, bytes32 _hash) external;
    function getReferred(address _trader) external view returns (bytes32);
    function getReferral(bytes32 _hash) external view returns (address);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPosition {

    struct Trade {
        uint margin;
        uint leverage;
        uint asset;
        bool direction;
        uint price;
        uint tpPrice;
        uint slPrice;
        uint orderType;
        address trader;
        uint id;
        address tigAsset;
        int accInterest;
    }

    struct MintTrade {
        address account;
        uint256 margin;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 price;
        uint256 tp;
        uint256 sl;
        uint256 orderType;
        address tigAsset;
    }

    function trades(uint256) external view returns (Trade memory);
    function executeLimitOrder(uint256 _id, uint256 _price, uint256 _newMargin) external;
    function modifyMargin(uint256 _id, uint256 _newMargin, uint256 _newLeverage) external;
    function addToPosition(uint256 _id, uint256 _newMargin, uint256 _newPrice) external;
    function reducePosition(uint256 _id, uint256 _newMargin) external;
    function assetOpenPositions(uint256 _asset) external view returns (uint256[] calldata);
    function assetOpenPositionsIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function limitOrders(uint256 _asset) external view returns (uint256[] memory);
    function limitOrderIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function assetOpenPositionsLength(uint256 _asset) external view returns (uint256);
    function limitOrdersLength(uint256 _asset) external view returns (uint256);
    function ownerOf(uint _id) external view returns (address);
    function mint(MintTrade memory _mintTrade) external;
    function burn(uint _id) external;
    function modifyTp(uint _id, uint _tpPrice) external;
    function modifySl(uint _id, uint _slPrice) external;
    function getCount() external view returns (uint);
    function updateFunding(uint256 _asset, address _tigAsset, uint256 _longOi, uint256 _shortOi, uint256 _baseFundingRate, uint256 _vaultFundingPercent) external;
    function setAccInterest(uint256 _id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStableVault {
    function deposit(address, uint) external;
    function withdraw(address, uint) external returns (uint256);
    function allowed(address) external view returns (bool);
    function stable() external view returns (address);
}

// SPDX-License-Identifier: MIT

import "../utils/TradingLibrary.sol";

pragma solidity ^0.8.0;

interface ITrading {

    struct TradeInfo {
        uint256 margin;
        address marginAsset;
        address stableVault;
        uint256 leverage;
        uint256 asset;
        bool direction;
        uint256 tpPrice;
        uint256 slPrice;
        bytes32 referral;
    }

    struct ERC20PermitData {
        uint256 deadline;
        uint256 amount;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool usePermit;
    }

    function initiateMarketOrder(
        TradeInfo calldata _tradeInfo,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        ERC20PermitData calldata _permitData
    ) external payable;

    function initiateCloseOrder(
        uint _id,
        uint _percent,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        address _stableVault,
        address _outputToken
    ) external;

    function addMargin(
        uint256 _id,
        address _marginAsset,
        address _stableVault,
        uint256 _addMargin,
        ERC20PermitData calldata _permitData
    ) external payable;

    function removeMargin(
        uint256 _id,
        address _stableVault,
        address _outputToken,
        uint256 _removeMargin,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;

    function addToPosition(
        uint _id,
        uint _addMargin,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,
        address _stableVault,
        address _marginAsset,
        ERC20PermitData calldata _permitData
    ) external;

    function initiateLimitOrder(
        TradeInfo calldata _tradeInfo,
        uint256 _orderType, // 1 limit, 2 momentum
        uint256 _price,
        ERC20PermitData calldata _permitData
    ) external payable;

    function cancelLimitOrder(
        uint256 _id
    ) external;

    function updateTpSl(
        bool _type, // true is TP
        uint _id,
        uint _limitPrice,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;

    function executeLimitOrder(
        uint _id, 
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;

    function liquidatePosition(
        uint _id,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;

    function limitClose(
        uint _id,
        bool _tp,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IPosition.sol";

interface IPrice {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}

struct PriceData {
    address provider;
    uint256 asset;
    uint256 price;
    uint256 timestamp;
    bool isClosed;
}

library TradingLibrary {

    using ECDSA for bytes32;

    function pnl(bool _direction, uint _currentPrice, uint _price, uint _margin, uint _leverage, int256 accInterest) external pure returns (uint256 _positionSize, int256 _payout) {
        unchecked {
            uint _initPositionSize = _margin * _leverage / 1e18;
            if (_direction && _currentPrice >= _price) {
                _payout = int256(_margin) + int256(_initPositionSize * (1e18 * _currentPrice / _price - 1e18)/1e18) + accInterest;
            } else if (_direction && _currentPrice < _price) {
                _payout = int256(_margin) - int256(_initPositionSize * (1e18 - 1e18 * _currentPrice / _price)/1e18) + accInterest;
            } else if (!_direction && _currentPrice <= _price) {
                _payout = int256(_margin) + int256(_initPositionSize * (1e18 - 1e18 * _currentPrice / _price)/1e18) + accInterest;
            } else {
                _payout = int256(_margin) - int256(_initPositionSize * (1e18 * _currentPrice / _price - 1e18)/1e18) + accInterest;
            }
            _positionSize = _initPositionSize * _currentPrice / _price;
        }
    }

    function liqPrice(bool _direction, uint _tradePrice, uint _leverage, uint _margin, int _accInterest, uint _liqPercent) public pure returns (uint256 _liqPrice) {
        if (_direction) {
            _liqPrice = _tradePrice - ((_tradePrice*1e18/_leverage) * uint(int(_margin)+_accInterest) / _margin) * _liqPercent / 1e10;
        } else {
            _liqPrice = _tradePrice + ((_tradePrice*1e18/_leverage) * uint(int(_margin)+_accInterest) / _margin) * _liqPercent / 1e10;
        }
    }

    function getLiqPrice(address _positions, uint _id, uint _liqPercent) external view returns (uint256) {
        IPosition.Trade memory _trade = IPosition(_positions).trades(_id);
        return liqPrice(_trade.direction, _trade.price, _trade.leverage, _trade.margin, _trade.accInterest, _liqPercent);
    }

    function verifyAndCreatePrice(
        uint256 _minNodeCount,
        uint256 _validSignatureTimer,
        uint256 _asset,
        bool _chainlinkEnabled,
        address _chainlinkFeed,
        PriceData[] calldata _priceData,
        bytes[] calldata _signature,        
        mapping(address => bool) storage _nodeProvided,
        mapping(address => bool) storage _isNode
    )
        external returns (uint256)
    {
        uint256 _length = _signature.length;
        require(_priceData.length == _length, "length");
        require(_length >= _minNodeCount, "minNode");
        address[] memory _nodes = new address[](_length);
        uint256[] memory _prices = new uint256[](_length);
        for (uint256 i=0; i<_length; i++) {
            require(_asset == _priceData[i].asset, "!Asset");
            address _provider = (
                keccak256(abi.encode(_priceData[i]))
            ).toEthSignedMessageHash().recover(_signature[i]);
            require(_provider == _priceData[i].provider, "BadSig");
            require(_isNode[_provider], "!Node");
            _nodes[i] = _provider;
            require(_nodeProvided[_provider] == false, "NodeP");
            _nodeProvided[_provider] = true;
            require(!_priceData[i].isClosed, "Closed");
            require(block.timestamp >= _priceData[i].timestamp, "FutSig");
            require(block.timestamp <= _priceData[i].timestamp + _validSignatureTimer, "ExpSig");
            require(_priceData[i].price > 0, "NoPrice");
            _prices[i] = _priceData[i].price;
        }
        uint256 _price = median(_prices);
        if (_chainlinkEnabled && _chainlinkFeed != address(0)) {
            int256 assetChainlinkPriceInt = IPrice(_chainlinkFeed).latestAnswer();
            if (assetChainlinkPriceInt != 0) {
                uint256 assetChainlinkPrice = uint256(assetChainlinkPriceInt) * 10**(18 - IPrice(_chainlinkFeed).decimals());
                require(
                    _price < assetChainlinkPrice+assetChainlinkPrice*2/100 &&
                    _price > assetChainlinkPrice-assetChainlinkPrice*2/100, "!chainlinkPrice"
                );
            }
        }
        for (uint i=0; i<_length; i++) {
            delete _nodeProvided[_nodes[i]];
        }
        return _price;
    }

    /**
     * @dev Gets the median value from an array
     * @param array array of unsigned integers to get the median from
     * @return median value from the array
     */
    function median(uint[] memory array) private pure returns(uint) {
        unchecked {
            sort(array, 0, array.length);
            return array.length % 2 == 0 ? (array[array.length/2-1]+array[array.length/2])/2 : array[array.length/2];            
        }
    }

    function swap(uint[] memory array, uint i, uint j) private pure { 
        (array[i], array[j]) = (array[j], array[i]); 
    }

    function sort(uint[] memory array, uint begin, uint end) private pure {
        unchecked {
            if (begin >= end) { return; }
            uint j = begin;
            uint pivot = array[j];
            for (uint i = begin + 1; i < end; ++i) {
                if (array[i] < pivot) {
                    swap(array, i, ++j);
                }
            }
            swap(array, begin, j);
            sort(array, begin, j);
            sort(array, j + 1, end);            
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPairsContract {

    struct Asset {
        string name;
        address chainlinkFeed;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 feeMultiplier;
        uint256 baseFundingRate;
    }

    struct OpenInterest {
        uint256 longOi;
        uint256 shortOi;
        uint256 maxOi;
    }

    function allowedAsset(uint) external view returns (bool);
    function idToAsset(uint256 _asset) external view returns (Asset memory);
    function idToOi(uint256 _asset, address _tigAsset) external view returns (OpenInterest memory);
    function setAssetBaseFundingRate(uint256 _asset, uint256 _baseFundingRate) external;
    function modifyLongOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
    function modifyShortOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovNFT {
    function distribute(address _tigAsset, uint _amount) external;
    function safeTransferMany(address _to, uint[] calldata _ids) external;
    function claim(address _tigAsset) external;
    function pending(address user, address _tigAsset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INativeStableVault {
    function depositNative() external payable;
    function withdrawNative(uint256 _amount) external returns (uint256);
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