//TODO add events

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

    // Errors
    error IsLimit();
    error NotLimit();
    error LimitNotMet();
    error LimitNotSet();
    error NotLiquidatable();
    error TradingPaused();
    error NotNativeSupport();
    error BadDeposit();
    error BadWithdraw();
    error ValueNotEqualToMargin();
    error BadLeverage();
    error BadStopLoss();
    error Wait();
    error GasPriceTooHigh();
    error NotPositionOwner();
    error NotMargin();
    error NotAllowedPair();
    error BelowMinPositionSize();
    error BadClosePercent();
    error NoPrice();
    error LiqThreshold();

    mapping(address => bool) private nodeProvided; // Used for TradingLibrary

    uint constant private DIVISION_CONSTANT = 1e10; // 100%
    address constant private eth = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint private constant liqPercent = 9e9; // 90%

    uint public daoFees; // 0.1%
    uint public burnFees; // 0%
    uint public referralFees; // 0.01%
    uint public botFees; // 0.02%
    uint public maxGasPrice = 1000000000000; // 1000 gwei
    uint public limitOrderPriceRange = 1e8; // 1%
    mapping(address => uint) public minPositionSize;
    
    uint public maxWinPercent;
    uint public vaultFundingPercent;

    bool public paused;

    bool public chainlinkEnabled;

    mapping(address => bool) public allowedMargin;

    IPairsContract private pairsContract;
    IReferrals private referrals;
    IPosition private position;
    IGovNFT private gov;

    mapping(address => bool) private isNode;
    uint256 public validSignatureTimer;
    uint256 public minNodeCount;

    struct Delay {
        uint delay; // Block number where delay ends
        bool actionType; // True for open, False for close
    }
    mapping(uint => Delay) public blockDelayPassed; // id => Delay
    uint public blockDelay;

    constructor(
        address _position,
        address _gov,
        address _pairsContract,
        address _referrals
    )
    {
        position = IPosition(_position);
        gov = IGovNFT(_gov);
        pairsContract = IPairsContract(_pairsContract);
        referrals = IReferrals(_referrals);
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
        validateTrade(_tradeInfo.asset, _tigAsset, _tradeInfo.margin, _tradeInfo.leverage);
        _handleDeposit(_tigAsset, _tradeInfo.marginAsset, _tradeInfo.margin, _tradeInfo.stableVault, _permitData);
        uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, _tradeInfo.asset, chainlinkEnabled, pairsContract.idToAsset(_tradeInfo.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
        _setReferral(_tradeInfo.referral);
        _checkSl(_tradeInfo.slPrice, _tradeInfo.direction, _price);
        unchecked {
            if (_tradeInfo.direction) {
                pairsContract.modifyLongOi(_tradeInfo.asset, _tigAsset, true, _tradeInfo.margin*_tradeInfo.leverage/1e18);
            } else {
                pairsContract.modifyShortOi(_tradeInfo.asset, _tigAsset, true, _tradeInfo.margin*_tradeInfo.leverage/1e18);
            }
        }
        updateFunding(_tradeInfo.asset, _tigAsset);
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
        if (_trade.orderType != 0) revert IsLimit();        
        uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, _trade.asset, chainlinkEnabled, pairsContract.idToAsset(_trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
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
        validateTrade(_trade.asset, _trade.tigAsset, _trade.margin + _addMargin, _trade.leverage);
        if (_trade.orderType != 0) revert IsLimit();
        _handleDeposit(_trade.tigAsset, _marginAsset, _addMargin, _stableVault, _permitData);
        position.setAccInterest(_id);
        unchecked {
            if (_trade.direction) {
                pairsContract.modifyLongOi(_trade.asset, _trade.tigAsset, true, _addMargin*_trade.leverage/1e18);
            } else {
                pairsContract.modifyShortOi(_trade.asset, _trade.tigAsset, true, _addMargin*_trade.leverage/1e18);     
            }
            updateFunding(_trade.asset, _trade.tigAsset);
            uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, _trade.asset, chainlinkEnabled, pairsContract.idToAsset(_trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
            uint _oldMargin = _trade.margin;
            uint _newMargin = _oldMargin + _addMargin;
            uint _newPrice = _trade.price*_oldMargin/_newMargin + _price*_addMargin/_newMargin;

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
        validateTrade(_tradeInfo.asset, _tigAsset, _tradeInfo.margin, _tradeInfo.leverage);
        if (_orderType == 0) revert NotLimit();
        if (_price == 0) revert NoPrice();
        _handleDeposit(_tigAsset, _tradeInfo.marginAsset, _tradeInfo.margin, _tradeInfo.stableVault, _permitData);
        _checkSl(_tradeInfo.slPrice, _tradeInfo.direction, _price);
        _setReferral(_tradeInfo.referral);
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
        unchecked {
            emit PositionOpened(_tradeInfo, _orderType, _price, position.getCount() - 1, _msgSender());
        }
    }

    function cancelLimitOrder(
        uint256 _id
    )
        external
    {
        _checkOwner(_id);
        IPosition.Trade memory trade = position.trades(_id);
        if (trade.orderType == 0) revert NotLimit();
        IStable(trade.tigAsset).mintFor(_msgSender(), trade.margin);
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
        if (_trade.orderType != 0) revert IsLimit();
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_trade.asset);
        _handleDeposit(_trade.tigAsset, _marginAsset, _addMargin, _stableVault, _permitData);
        unchecked {
            uint256 _newMargin = _trade.margin + _addMargin;
            uint256 _newLeverage = _trade.margin * _trade.leverage / _newMargin;
            if (_newLeverage < asset.minLeverage) revert BadLeverage();
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
        if (_trade.orderType != 0) revert IsLimit();
        IPairsContract.Asset memory asset = pairsContract.idToAsset(_trade.asset);
        uint256 _newMargin = _trade.margin - _removeMargin;
        uint256 _newLeverage = _trade.margin * _trade.leverage / _newMargin;
        if (_newLeverage > asset.maxLeverage) revert BadLeverage();
        uint _assetPrice = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, _trade.asset, chainlinkEnabled, asset.chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
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
        if (_trade.orderType != 0) revert IsLimit();
        if (_type) {
            position.modifyTp(_id, _limitPrice);
        } else {
            uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, _trade.asset, chainlinkEnabled, pairsContract.idToAsset(_trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
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
            _checkGas();
            if (paused) revert TradingPaused();
            IPosition.Trade memory trade = position.trades(_id);
            IPairsContract.Asset memory asset = pairsContract.idToAsset(trade.asset);
            uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, trade.asset, chainlinkEnabled, asset.chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
            if (trade.orderType == 0) revert NotLimit();
            if (_price > trade.price+trade.price*limitOrderPriceRange/DIVISION_CONSTANT || _price < trade.price-trade.price*limitOrderPriceRange/DIVISION_CONSTANT) revert LimitNotMet();
            if (trade.direction && trade.orderType == 1) {
                if (trade.price < _price) revert LimitNotMet();
            } else if (!trade.direction && trade.orderType == 1) {
                if (trade.price > _price) revert LimitNotMet();      
            } else if (!trade.direction && trade.orderType == 2) {
                if (trade.price < _price) revert LimitNotMet();
                trade.price = _price;
            } else {
                if (trade.price > _price) revert LimitNotMet();
                trade.price = _price;
            }
            if (trade.direction) {
                pairsContract.modifyLongOi(trade.asset, trade.tigAsset, true, trade.margin*trade.leverage/1e18);
            } else {
                pairsContract.modifyShortOi(trade.asset, trade.tigAsset, true, trade.margin*trade.leverage/1e18);
            }
            updateFunding(trade.asset, trade.tigAsset);
            IStable(trade.tigAsset).mintFor(
                _msgSender(),
                ((trade.margin*trade.leverage/1e18)*botFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT
            );
            position.executeLimitOrder(_id, trade.price, trade.margin);
            emit LimitOrderExecuted(trade.asset, trade.direction, trade.price, trade.leverage, trade.margin, _id, trade.trader, _msgSender());
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
            _checkGas();
            IPosition.Trade memory _trade = position.trades(_id);
            IPairsContract.Asset memory asset = pairsContract.idToAsset(_trade.asset);
            uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, _trade.asset, chainlinkEnabled, asset.chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
            if (_trade.orderType != 0) revert IsLimit();
            (uint256 _positionSizeAfterPrice, int256 _payout) = TradingLibrary.pnl(_trade.direction, _price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
            uint256 _positionSize = _trade.margin*_trade.leverage/1e18;
            if (_payout > int256(_trade.margin*(DIVISION_CONSTANT-liqPercent)/DIVISION_CONSTANT)) revert NotLiquidatable();
            if (_trade.direction) {
                pairsContract.modifyLongOi(_trade.asset, _trade.tigAsset, false, _positionSize);
            } else {
                pairsContract.modifyShortOi(_trade.asset, _trade.tigAsset, false, _positionSize);
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
        _checkGas();
        IPosition.Trade memory _trade = position.trades(_id);
        uint256 _price = TradingLibrary.verifyAndCreatePrice(minNodeCount, validSignatureTimer, _trade.asset, chainlinkEnabled, pairsContract.idToAsset(_trade.asset).chainlinkFeed, _priceData, _signature, nodeProvided, isNode);
        if (_trade.orderType != 0) revert IsLimit();
        uint _limitPrice;
        if (_tp) {
            if (_trade.tpPrice == 0) revert LimitNotSet();
            if (_trade.direction) {
                if (_trade.tpPrice > _price) revert LimitNotMet();
            } else {
                if (_trade.tpPrice < _price) revert LimitNotMet();
            }
            _limitPrice = _trade.tpPrice;
        } else {
            if (_trade.slPrice == 0) revert LimitNotSet();
            if (_trade.direction) {
                if (_trade.slPrice < _price) revert LimitNotMet();
            } else {
                if (_trade.slPrice > _price) revert LimitNotMet();
            }
            _limitPrice = _trade.slPrice;
        }
        _closePosition(_id, DIVISION_CONSTANT, _limitPrice, address(0), _trade.tigAsset);
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
        IPosition.Trade memory _trade = position.trades(_id);
        (uint256 _positionSize, int256 _payout) = TradingLibrary.pnl(_trade.direction, _price, _trade.price, _trade.margin, _trade.leverage, _trade.accInterest);
        unchecked {
            if (_trade.direction) {
                pairsContract.modifyLongOi(_trade.asset, _trade.tigAsset, false, (_trade.margin*_trade.leverage/1e18)*_percent/DIVISION_CONSTANT);
            } else {
                pairsContract.modifyShortOi(_trade.asset, _trade.tigAsset, false, (_trade.margin*_trade.leverage/1e18)*_percent/DIVISION_CONSTANT);     
            }
        }
        position.setAccInterest(_id);
        updateFunding(_trade.asset, _trade.tigAsset);
        if (_percent < DIVISION_CONSTANT) {
            if ((_trade.margin*_trade.leverage*(DIVISION_CONSTANT-_percent)/DIVISION_CONSTANT)/1e18 < minPositionSize[_trade.tigAsset]) revert BelowMinPositionSize();
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
        address msgSender = _msgSender();
        if (_tigAsset != _marginAsset) {
            if (msg.value > 0) {
                if (_marginAsset != eth) revert BadDeposit();
            } else {
                if (_permitData.usePermit) {
                    ERC20Permit(_marginAsset).permit(msgSender, address(this), _permitData.amount, _permitData.deadline, _permitData.v, _permitData.r, _permitData.s);
                }
            }
            uint256 _balBefore = tigAsset.balanceOf(address(this));
            if (_marginAsset != eth){
                uint _marginDecMultiplier = 10**(18-ExtendedIERC20(_marginAsset).decimals());
                IERC20(_marginAsset).transferFrom(msgSender, address(this), _margin/_marginDecMultiplier);
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
            tigAsset.burnFrom(msgSender, _margin);
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
        uint _daoFeesPaid;
        uint _burnFeesPaid;
        uint _referralFeesPaid;
        unchecked {
            _daoFeesPaid = (_positionSize*daoFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
            _burnFeesPaid = (_positionSize*burnFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
            _referralFeesPaid = (_positionSize*referralFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
        }
        uint _botFeesPaid;
        address _referrer = referrals.getReferral(referrals.getReferred(_trader));
        if (_referrer != address(0)) {
            IStable(_tigAsset).mintFor(
                _referrer,
                _referralFeesPaid
            );
            unchecked {
                _daoFeesPaid = _daoFeesPaid-_referralFeesPaid;
            }
        }
        if (_trader != _msgSender()) {
            unchecked {
                _botFeesPaid = (_positionSize*botFees/DIVISION_CONSTANT)*asset.feeMultiplier/DIVISION_CONSTANT;
                IStable(_tigAsset).mintFor(
                    _msgSender(),
                    _botFeesPaid
                );
                _daoFeesPaid = _daoFeesPaid - _botFeesPaid;
            }
        }
        payout_ = _payout - _daoFeesPaid - _burnFeesPaid - _botFeesPaid;
        IStable(_tigAsset).mintFor(address(this), _daoFeesPaid);
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

    function _setReferral(bytes32 _referral) internal {
        if (_referral != bytes32(0)) {
            if (referrals.getReferral(_referral) != address(0)) {
                if (referrals.getReferred(_msgSender()) == bytes32(0)) {
                    referrals.setReferred(_msgSender(), _referral);
                }
            }
        }
    }

    /**
     * @dev validates the inputs of trades
     * @param _asset asset id
     * @param _tigAsset margin asset
     * @param _margin margin
     * @param _leverage leverage
     */
    function validateTrade(uint _asset, address _tigAsset, uint _margin, uint _leverage) internal view {
        unchecked {
            IPairsContract.Asset memory asset = pairsContract.idToAsset(_asset);
            if (!allowedMargin[_tigAsset]) revert NotMargin();
            if (paused) revert TradingPaused();
            if (!pairsContract.allowedAsset(_asset)) revert NotAllowedPair();
            if (_leverage < asset.minLeverage || _leverage > asset.maxLeverage) revert BadLeverage();
            if (_margin*_leverage/1e18 < minPositionSize[_tigAsset]) revert BelowMinPositionSize();
        }
    }

    function _checkSl(uint _sl, bool _direction, uint _price) internal pure {
        if (_direction) {
            if (_sl > _price) revert BadStopLoss();
        } else {
            if (_sl < _price && _sl != 0) revert BadStopLoss();
        }
    }

    function _checkOwner(uint _id) internal view {
        if (position.ownerOf(_id) != _msgSender()) revert NotPositionOwner();    
    }

    function _checkGas() internal view {
        if (tx.gasprice > maxGasPrice) revert GasPriceTooHigh();
    }

    function _checkDelay(uint _id, bool _type) internal {
        unchecked {
            Delay memory _delay = blockDelayPassed[_id];
            if (_delay.actionType == _type) {
                blockDelayPassed[_id].delay = block.number + blockDelay;
            } else {
                if (block.number < _delay.delay) revert Wait();
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

    function setValidSignatureTimer(
        uint _validSignatureTimer
    )
        external
        onlyOwner
    {
        validSignatureTimer = _validSignatureTimer;
    }

    function setMinNodeCount(
        uint _minNodeCount
    )
        external
        onlyOwner
    {
        minNodeCount = _minNodeCount;
    }

    /**
     * @dev Allows a tigAsset to be used
     * @param _tigAsset tigAsset
     * @param _bool bool
     */
    function setAllowedMargin(
        address _tigAsset,
        bool _bool
    ) 
        external
        onlyOwner
    {
        allowedMargin[_tigAsset] = _bool;
        IStable(_tigAsset).approve(address(gov), type(uint).max);
    }

    /**
     * @dev changes the minimum position size
     * @param _tigAsset tigAsset
     * @param _min minimum position size 18 decimals
     */
    function setMinPositionSize(
        address _tigAsset,
        uint _min
    ) 
        external
        onlyOwner
    {
        minPositionSize[_tigAsset] = _min;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setMaxGasPrice(uint _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;
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
    function setFees(uint _daoFees, uint _burnFees, uint _referralFees, uint _botFees, uint _percent) external onlyOwner {
        unchecked {
            require(_daoFees >= _botFees+_referralFees);
            daoFees = _daoFees;
            burnFees = _burnFees;
            referralFees = _referralFees;
            botFees = _botFees;
            require(_percent <= DIVISION_CONSTANT);
            vaultFundingPercent = _percent;
        }
    }

    /**
     * @dev whitelists a node
     * @param _node node address
     * @param _bool bool
     */
    function setNode(address _node, bool _bool) external onlyOwner {
        isNode[_node] = _bool;
    }

    function setChainlinkEnabled(bool _bool) external onlyOwner {
        chainlinkEnabled = _bool;
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

    receive() external payable {}

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

    function allowedMargin(address _tigAsset) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferrals {

    function createReferralCode(bytes32 _hash) external;
    function setReferred(address _referredTrader, bytes32 _hash) external;
    function getReferred(address _trader) external view returns (bytes32);
    function getReferral(bytes32 _hash) external view returns (address);
    
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