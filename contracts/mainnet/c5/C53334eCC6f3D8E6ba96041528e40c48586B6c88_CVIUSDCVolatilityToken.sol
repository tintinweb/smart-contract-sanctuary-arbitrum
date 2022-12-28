// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import '@coti-cvi/contracts-cvi/contracts/VolatilityToken.sol';

contract CVIUSDCVolatilityToken is VolatilityToken {
  constructor() VolatilityToken() {}
}

contract CVIUSDCVolatilityToken2X is VolatilityToken {
  constructor() VolatilityToken() {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IVolatilityToken.sol";
import "./interfaces/IRequestManager.sol";
import "./ElasticToken.sol";

contract VolatilityToken is Initializable, IVolatilityToken, IRequestManager, ReentrancyGuardUpgradeable, ElasticToken {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint8 public constant MINT_REQUEST_TYPE = 1;
    uint8 public constant BURN_REQUEST_TYPE = 2;

    uint16 public constant MAX_PERCENTAGE = 10000;

    uint8 public override leverage; // Obsolete
    uint8 private rebaseLag; // Obsolete

    uint16 public minDeviationPercentage;

    uint256 public override initialTokenToLPTokenRate;

    IERC20Upgradeable public token;
    IPlatform public override platform;
    IFeesCollector public feesCollector;
    IFeesCalculator public feesCalculator;
    IRequestFeesCalculator public override requestFeesCalculator;
    ICVIOracle public cviOracle;

    uint256 public override nextRequestId;

    mapping(uint256 => Request) public override requests;

    uint256 public totalRequestsAmount;
    uint256 public maxTotalRequestsAmount;
    bool public verifyTotalRequestsAmount;

    uint16 public deviationPerSingleRebaseLag;
    uint16 public maxDeviationPercentage;

    bool public cappedRebase;

    uint256 public constant PRECISION_DECIMALS = 1e10;
    uint256 public constant CVI_DECIMALS_FIX = 100;

    uint256 public override minRequestId;
    uint256 public override maxMinRequestIncrements;

    address public fulfiller;

    address public keepersFeeVaultAddress;

    uint256 public minKeepersMintAmount;
    uint256 public minKeepersBurnAmount;
    
    address public minter;

    function initialize(IERC20Upgradeable _token, string memory _lpTokenName, string memory _lpTokenSymbolName, uint8 _leverage, uint256 _initialTokenToVolTokenRate, 
            IPlatform _platform, IFeesCollector _feesCollector, IFeesCalculator _feesCalculator, IRequestFeesCalculator _requestFeesCalculator, ICVIOracle _cviOracle) public initializer {
        minDeviationPercentage = 100;
        deviationPerSingleRebaseLag = 1000;
        maxDeviationPercentage = 5000;
        cappedRebase = true;

        nextRequestId = 1;
        minRequestId = 1;

        maxMinRequestIncrements = 30;

        ElasticToken.__ElasticToken_init(_lpTokenName, _lpTokenSymbolName, 18);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        token = _token;
        platform = _platform;
        feesCollector = _feesCollector;
        feesCalculator = _feesCalculator;
        requestFeesCalculator = _requestFeesCalculator;
        cviOracle = _cviOracle;
        initialTokenToLPTokenRate = _initialTokenToVolTokenRate;
        leverage = _leverage;

        totalRequestsAmount = 0;
        maxTotalRequestsAmount = 1e11;
        verifyTotalRequestsAmount = true;

        if (address(token) != address(0)) {
            token.safeApprove(address(_platform), type(uint256).max);
            token.safeApprove(address(_feesCollector), type(uint256).max);
        }
    }

    // If not rebaser, the rebase underlying method will revert
    function rebaseCVI() external override {
        (uint256 balance, bool isBalancePositive,,,,) = platform.calculatePositionBalance(address(this));
        require(isBalancePositive, "Negative balance");

        // Note: the price is measured by token units, so we want its decimals on the position value as well, as precision decimals
        // We use the rate multiplication to have balance / totalSupply be done with matching decimals
        uint256 positionValue = balance * initialTokenToLPTokenRate * PRECISION_DECIMALS / totalSupply;

        (uint256 cviValueOracle,,) = cviOracle.getCVILatestRoundData();
        uint256 cviValue = cviValueOracle * PRECISION_DECIMALS / CVI_DECIMALS_FIX;

        require(cviValue > positionValue, "Positive rebase disallowed");
        uint256 deviation = cviValue - positionValue;

        require(!cappedRebase || deviation >= cviValue * minDeviationPercentage / MAX_PERCENTAGE, "Not enough deviation");
        require(!cappedRebase || deviation <= cviValue * maxDeviationPercentage / MAX_PERCENTAGE, "Deviation too big");

        // Note: rounding up (ceiling) the rebase lag so it is >= 1 and bumps by 1 for every deviationPerSingleRebaseLag percentage
        uint256 rebaseLagNew = cappedRebase ? (deviation * MAX_PERCENTAGE - 1) / (cviValue * deviationPerSingleRebaseLag) + 1 : 1;

        if (rebaseLagNew > 1) {
            deviation = deviation / rebaseLagNew;
            cviValue = positionValue + deviation;
        }

        uint256 delta = DELTA_PRECISION_DECIMALS * deviation / cviValue;

        rebase(delta, false);
    }

    function submitMintRequest(uint168 _tokenAmount, uint32 _timeDelay) external virtual override returns (uint256 requestId) {
        requireTotalRequestsAmount(_tokenAmount);
        return submitRequest(MINT_REQUEST_TYPE, _tokenAmount, _timeDelay, false, 0);
    }

    function submitKeepersMintRequest(uint168 _tokenAmount, uint32 _timeDelay, uint16 _maxBuyingPremiumFeePercentage) external override returns (uint256 requestId) {
        requireTotalRequestsAmount(_tokenAmount);
        require(_tokenAmount >= minKeepersMintAmount, "Not enough tokens");
        return submitRequest(MINT_REQUEST_TYPE, _tokenAmount, _timeDelay, true, _maxBuyingPremiumFeePercentage);
    }

    function submitBurnRequest(uint168 _tokenAmount, uint32 _timeDelay) external override returns (uint256 requestId) {
        return submitRequest(BURN_REQUEST_TYPE, _tokenAmount, _timeDelay, false, 0);
    }

    function submitKeepersBurnRequest(uint168 _tokenAmount, uint32 _timeDelay) external override returns (uint256 requestId) {
        require(_tokenAmount >= minKeepersBurnAmount, "Not enough tokens");
        return submitRequest(BURN_REQUEST_TYPE, _tokenAmount, _timeDelay, true, 0);
    }

    function fulfillMintRequest(uint256 _requestId, uint16 _maxBuyingPremiumFeePercentage, bool _keepersCalled) public virtual override returns (uint256 tokensMinted, bool success) {
        require(!_keepersCalled || msg.sender == fulfiller); // Not allowed
        Request memory request = requests[_requestId];
        return _fulfillMintRequest(_requestId, request, _maxBuyingPremiumFeePercentage, _keepersCalled);
    }

    function fulfillBurnRequest(uint256 _requestId,  bool _keepersCalled) external override returns (uint256 tokensReceived) {
        require(!_keepersCalled || msg.sender == fulfiller); // Not allowed
        Request memory request = requests[_requestId];
        return _fulfillBurnRequest(_requestId, request, _keepersCalled);
    }

    function mintTokens(uint168 tokenAmount) external override returns (uint256 mintedTokens) {
        require(msg.sender == minter);
        token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        (mintedTokens,) = mintTokens(0, msg.sender, tokenAmount, MAX_PERCENTAGE, false, false);
    }

    function burnTokens(uint168 burnAmount) external override returns (uint256 tokenAmount) {
        require(msg.sender == minter);
        IERC20Upgradeable(address(this)).safeTransferFrom(msg.sender, address(this), underlyingToValue(valueToUnderlying(uint256(burnAmount))));
        (tokenAmount,) = burnTokens(0, msg.sender, burnAmount, 0, 0, false, false);
    }

    function liquidateRequest(uint256 _requestId) external override nonReentrant returns (uint256 findersFeeAmount) {
        Request memory request = requests[_requestId];
        require(request.requestType != 0, "Request id not found");
        require(requestFeesCalculator.isLiquidable(request), "Not liquidable");
        findersFeeAmount = _liquidateRequest(_requestId, request);
    }

    function setMinter(address _newMinter) external override onlyOwner {
        minter = _newMinter;
    }

    function setPlatform(IPlatform _newPlatform) external override onlyOwner {
        if (address(platform) != address(0) && address(token) != address(0)) {
            token.safeApprove(address(platform), type(uint256).max);
        }

        platform = _newPlatform;

        if (address(_newPlatform) != address(0) && address(token) != address(0)) {
            token.safeApprove(address(_newPlatform), type(uint256).max);
        }
    }

    function setFeesCalculator(IFeesCalculator _newFeesCalculator) external override onlyOwner {
        feesCalculator = _newFeesCalculator;
    }

    function setFeesCollector(IFeesCollector _newCollector) external override onlyOwner {
        if (address(feesCollector) != address(0) && address(token) != address(0)) {
            token.safeApprove(address(feesCollector), 0);
        }

        feesCollector = _newCollector;

        if (address(_newCollector) != address(0) && address(token) != address(0)) {
            token.safeApprove(address(_newCollector), type(uint256).max);
        }
    }

    function setRequestFeesCalculator(IRequestFeesCalculator _newRequestFeesCalculator) external override onlyOwner {
        requestFeesCalculator = _newRequestFeesCalculator;
    }

    function setCVIOracle(ICVIOracle _newCVIOracle) external override onlyOwner {
        cviOracle = _newCVIOracle;
    }

    function setDeviationParameters(uint16 _newDeviationPercentagePerSingleRebaseLag, uint16 _newMinDeviationPercentage, uint16 _newMaxDeviationPercentage) external override onlyOwner {
        deviationPerSingleRebaseLag = _newDeviationPercentagePerSingleRebaseLag;
        minDeviationPercentage = _newMinDeviationPercentage;
        maxDeviationPercentage = _newMaxDeviationPercentage;
    }

    function setVerifyTotalRequestsAmount(bool _verifyTotalRequestsAmount) external override onlyOwner {
        verifyTotalRequestsAmount = _verifyTotalRequestsAmount;
    }

    function setMaxTotalRequestsAmount(uint256 _maxTotalRequestsAmount) external override onlyOwner {
        maxTotalRequestsAmount = _maxTotalRequestsAmount;
    }

    function setCappedRebase(bool _newCappedRebase) external override onlyOwner {
        cappedRebase = _newCappedRebase;
    }

    function setMinRequestId(uint256 _newMinRequestId) external override onlyOwner {
        minRequestId = _newMinRequestId;
    }

    function setMaxMinRequestIncrements(uint256 _newMaxMinRequestIncrements) external override onlyOwner {
        maxMinRequestIncrements = _newMaxMinRequestIncrements;
    }

    function setFulfiller(address _fulfiller) external override onlyOwner {
        fulfiller = _fulfiller;
    }

    function setKeepersFeeVaultAddress(address _newKeepersFeeVaultAddress) external override onlyOwner {
        keepersFeeVaultAddress = _newKeepersFeeVaultAddress;
    }

    function setMinKeepersAmounts(uint256 _newMinKeepersMintAmount, uint256 _newMinKeepersBurnAmount) external override onlyOwner {
        minKeepersMintAmount = _newMinKeepersMintAmount;
        minKeepersBurnAmount = _newMinKeepersBurnAmount;
    }

    struct SubmitRequestLocals {
        uint168 updatedTokenAmount;
        uint16 timeDelayFeePercent;
        uint16 maxFeesPercent;
        uint256 timeDelayFeeAmount;
        uint256 maxFeesAmount;
    }

    function submitRequest(uint8 _type, uint168 _tokenAmount, uint32 _timeDelay, bool _useKeepers, uint16 _maxBuyingPremiumFeePercentage) private nonReentrant returns (uint requestId) {
        require(_tokenAmount > 0);

        SubmitRequestLocals memory locals;

        // Converting to underlying value in case of burn request, to support rebasing until fulfill
        locals.updatedTokenAmount = _tokenAmount;
        if (_type == BURN_REQUEST_TYPE) {
            uint256 __updatedTokenAmount = valueToUnderlying(_tokenAmount);
            require(uint168(__updatedTokenAmount) == __updatedTokenAmount);
            locals.updatedTokenAmount = uint168(__updatedTokenAmount);
        }

        locals.timeDelayFeePercent = requestFeesCalculator.calculateTimeDelayFee(_timeDelay);
        locals.maxFeesPercent = requestFeesCalculator.getMaxFees();

        locals.timeDelayFeeAmount = locals.updatedTokenAmount * locals.timeDelayFeePercent / MAX_PERCENTAGE;
        locals.maxFeesAmount = locals.updatedTokenAmount * locals.maxFeesPercent / MAX_PERCENTAGE;

        requestId = nextRequestId;
        nextRequestId = nextRequestId + 1; // Overflow allowed to keep id cycling

        uint32 targetTimestamp = uint32(block.timestamp + _timeDelay);

        requests[requestId] = Request(_type, locals.updatedTokenAmount, locals.timeDelayFeePercent, locals.maxFeesPercent, msg.sender, uint32(block.timestamp), targetTimestamp, _useKeepers, _maxBuyingPremiumFeePercentage);

        if (_type != BURN_REQUEST_TYPE) {
            totalRequestsAmount = totalRequestsAmount + _tokenAmount;
        }

        collectRelevantTokens(_type, _useKeepers ? _tokenAmount : (_type == BURN_REQUEST_TYPE ? underlyingToValue(locals.timeDelayFeeAmount + locals.maxFeesAmount) : locals.timeDelayFeeAmount + locals.maxFeesAmount));

        emit SubmitRequest(requestId, _type, msg.sender, _tokenAmount, _type == BURN_REQUEST_TYPE ? underlyingToValue(locals.timeDelayFeeAmount) : locals.timeDelayFeeAmount, uint32(block.timestamp), targetTimestamp, _useKeepers, _maxBuyingPremiumFeePercentage);
    }

    struct PreFulfillResults {
        uint168 amountToFulfill;
        uint168 fulfillFees;
        uint168 timeDelayFees;
        uint16 fulfillFeesPercentage;
        bool wasLiquidated;
        uint168 depositAmount;
        uint168 mintAmount;
        bool shouldAbort;
        uint168 keepersFee;
    }

    function preFulfillRequest(uint256 _requestId, Request memory _request, uint8 _expectedType, bool _keepersCalled) private returns (PreFulfillResults memory results) {
        require((_keepersCalled && _request.useKeepers) || _request.owner == msg.sender); // Not allowed
        require(_request.requestType == _expectedType, "Wrong request type");

        if (requestFeesCalculator.isLiquidable(_request)) {
            _liquidateRequest(_requestId, _request);
            results.wasLiquidated = true;
        } else {
            require(!_keepersCalled || block.timestamp >= _request.targetTimestamp, "Target time not reached");
            results.fulfillFeesPercentage = _request.useKeepers && block.timestamp >= _request.targetTimestamp ? 0 : requestFeesCalculator.calculateTimePenaltyFee(_request);

            results.timeDelayFees = _request.tokenAmount * _request.timeDelayRequestFeesPercent / MAX_PERCENTAGE;

            if (_request.requestType == MINT_REQUEST_TYPE) {
                if (_request.useKeepers && _keepersCalled) {
                    // Note: Cast is safe as keepers fee is always less than amount
                    results.keepersFee = uint168(requestFeesCalculator.calculateKeepersFee(_request.tokenAmount));
                }

                results.fulfillFees = _request.tokenAmount * results.fulfillFeesPercentage / MAX_PERCENTAGE;
                results.amountToFulfill = _request.tokenAmount - results.timeDelayFees - results.fulfillFees - results.keepersFee;
            }

            if (!_request.useKeepers) {
                uint256 tokensLeftToTransfer = getUpdatedTokenAmount(_request.requestType, _request.tokenAmount - results.timeDelayFees - (_request.tokenAmount * _request.maxRequestFeesPercent / MAX_PERCENTAGE));
                collectRelevantTokens(_request.requestType, tokensLeftToTransfer);
            }

            if (_request.requestType == BURN_REQUEST_TYPE) {
                results.amountToFulfill = getUpdatedTokenAmount(_request.requestType, _request.tokenAmount);
            }
        }
    }

    function requireTotalRequestsAmount(uint168 _newTokenAmount) private view {
        require(!verifyTotalRequestsAmount || _newTokenAmount + totalRequestsAmount <= maxTotalRequestsAmount, "Total requests amount exceeded");
    }

    function _fulfillMintRequest(uint256 _requestId, Request memory _request, uint16 _maxBuyingPremiumFeePercentage, bool _keepersCalled) private returns (uint256 tokensMinted, bool success) {
        PreFulfillResults memory results = preFulfillRequest(_requestId, _request, MINT_REQUEST_TYPE, _keepersCalled);

        if (results.wasLiquidated) {
            success = true;
        } else {
            (tokensMinted, success) = mintTokens(_requestId, _request.owner, results.amountToFulfill, _maxBuyingPremiumFeePercentage, _request.useKeepers && _keepersCalled, true);

            if (success) {
                subtractTotalRequestAmount(_request.tokenAmount);
                deleteRequest(_requestId);

                feesCollector.sendProfit(results.timeDelayFees + results.fulfillFees, IERC20(address(token)));

                if (results.keepersFee > 0) {
                    token.safeTransfer(keepersFeeVaultAddress, results.keepersFee);
                }

                emit FulfillRequest(_requestId, _request.requestType, _request.owner, results.fulfillFees + results.keepersFee, false, _request.useKeepers, _keepersCalled, msg.sender, uint32(block.timestamp));
            }
        }
    }

    function _fulfillBurnRequest(uint256 _requestId, Request memory _request, bool _keepersCalled) private nonReentrant returns (uint256 tokensReceived) {
        PreFulfillResults memory results = preFulfillRequest(_requestId, _request, BURN_REQUEST_TYPE, _keepersCalled);

        if (!results.wasLiquidated) {
            deleteRequest(_requestId);

            uint256 fulfillFees;
            (tokensReceived, fulfillFees) = burnTokens(_requestId, _request.owner, results.amountToFulfill, _request.timeDelayRequestFeesPercent, results.fulfillFeesPercentage, _keepersCalled && _request.useKeepers, true);

            emit FulfillRequest(_requestId, _request.requestType, _request.owner, fulfillFees, false, _request.useKeepers, _keepersCalled, msg.sender, uint32(block.timestamp));
        }
    }

    function mintTokens(uint256 _requestId, address _owner, uint168 _tokenAmount, uint16 _maxBuyingPremiumFeePercentage, bool _catchRevert, bool _chargeOpenFee) private returns (uint256 tokensMinted, bool success) {
        uint256 balance = 0;

        {
            bool isPositive = true;

            (uint256 currPositionUnits,,,,) = platform.positions(address(this));
            if (currPositionUnits != 0) {
                (balance, isPositive,,,,) = platform.calculatePositionBalance(address(this));
            }
            require(isPositive, "Negative balance");
        }

        uint256 supply = totalSupply;

        (, uint256 positionedTokenAmount, uint256 openPositionFee, uint256 buyingPremiumFee, bool transactionSuccess) = openPosition(_tokenAmount, _maxBuyingPremiumFeePercentage, _catchRevert, _chargeOpenFee);

        if (transactionSuccess) {   
            if (supply > 0 && balance > 0) {
                tokensMinted = positionedTokenAmount * supply / balance;
            } else {
                tokensMinted = positionedTokenAmount * initialTokenToLPTokenRate;
            }

            emit Mint(_requestId, _owner, _tokenAmount, positionedTokenAmount, tokensMinted, openPositionFee, buyingPremiumFee);

            require(tokensMinted > 0, "Too few tokens");

            _mint(_owner, tokensMinted);
            success = true;
        }
    }

    function burnTokens(uint256 _requestId, address _owner, uint168 _tokenAmount, uint16 _timeDelayFeesPercentage, uint16 _fulfillFeesPercentage, bool _hasKeepersFee, bool _chargeCloseFee) private returns (uint256 tokensReceived, uint256 fulfillFees) {
        (uint256 tokensBeforeFees, uint256 closePositionFee, uint256 closingPremiumFee) = _burnTokens(_tokenAmount, _chargeCloseFee);

        {
            uint256 timeDelayFee = tokensBeforeFees * _timeDelayFeesPercentage / MAX_PERCENTAGE;
            fulfillFees = tokensBeforeFees * _fulfillFeesPercentage / MAX_PERCENTAGE;

            uint256 keepersFee = 0;
            if (_hasKeepersFee) {
                keepersFee = requestFeesCalculator.calculateKeepersFee(tokensBeforeFees);
            }

            tokensReceived = tokensBeforeFees - fulfillFees - timeDelayFee - keepersFee;

            if (fulfillFees + timeDelayFee > 0) {
                feesCollector.sendProfit(fulfillFees + timeDelayFee, IERC20(address(token)));
            }
            
            if (keepersFee > 0) {
                token.safeTransfer(keepersFeeVaultAddress, keepersFee);
                fulfillFees += keepersFee;
            }
        }

        token.safeTransfer(_owner, tokensReceived);

        emit Burn(_requestId, _owner, tokensBeforeFees, tokensReceived, _tokenAmount, closePositionFee, closingPremiumFee);
    }

    function _burnTokens(uint256 _tokenAmount, bool _chargeCloseFee) private returns (uint256 tokensReceived, uint256 closePositionFee, uint256 closingPremiumFee) {
        (, bool isPositive, uint168 totalPositionUnits,,,) = platform.calculatePositionBalance(address(this));
        require(isPositive, "Negative balance");

        uint256 positionUnits = totalPositionUnits * _tokenAmount / totalSupply;
        require(positionUnits == uint168(positionUnits), "Too much position units");

        if (positionUnits > 0) {
            (tokensReceived, closePositionFee, closingPremiumFee) = _chargeCloseFee ? 
                platform.closePosition(uint168(positionUnits), 1) :
                platform.closePositionWithoutFee(uint168(positionUnits), 1);
        }

        // Note: Moving to underlying and back in case rebase occured, and trying to burn too much because of rounding
        _burn(address(this), underlyingToValue(valueToUnderlying(_tokenAmount)));
    }

    function _liquidateRequest(uint256 _requestId, Request memory _request) private returns (uint256 findersFeeAmount) {
        uint168 updatedTokenAmount = getUpdatedTokenAmount(_request.requestType, _request.tokenAmount);
        uint256 leftAmount = updatedTokenAmount;

        if (!_request.useKeepers) {
            uint168 timeDelayFeeAmount = updatedTokenAmount * _request.timeDelayRequestFeesPercent / MAX_PERCENTAGE;
            uint168 maxFeesAmount = updatedTokenAmount * _request.maxRequestFeesPercent / MAX_PERCENTAGE;
            leftAmount = timeDelayFeeAmount + maxFeesAmount;   
        }

        if (_request.requestType == BURN_REQUEST_TYPE) {
            (leftAmount,,) = _burnTokens(leftAmount, true);
        } else {
            subtractTotalRequestAmount(updatedTokenAmount);
        }

        findersFeeAmount = _request.useKeepers ? requestFeesCalculator.calculateKeepersFee(leftAmount) : requestFeesCalculator.calculateFindersFee(leftAmount);

        deleteRequest(_requestId);

        if (_request.useKeepers) {
            token.safeTransfer(_request.owner, leftAmount - findersFeeAmount);
        } else {
            feesCollector.sendProfit(leftAmount - findersFeeAmount, IERC20(address(token)));
        }

        token.safeTransfer(msg.sender, findersFeeAmount);

        emit LiquidateRequest(_requestId, _request.requestType, _request.owner, msg.sender, findersFeeAmount, _request.useKeepers, uint32(block.timestamp));
    }

    function deleteRequest(uint256 _requestId) private {
        delete requests[_requestId];

        uint256 currMinRequestId = minRequestId;
        uint256 increments = 0;
        bool didIncrement = false;

        // Skip over non-keepers request ids as well as fulfilled ones, 
        // as minRequestId is used only to allow keepers to test which requests are waiting to be fulfilled
        while (currMinRequestId < nextRequestId && increments < maxMinRequestIncrements && (requests[currMinRequestId].owner == address(0) || requests[currMinRequestId].useKeepers == false)) {
            increments++;
            currMinRequestId++;
            didIncrement = true;
        }

        if (didIncrement) {
            minRequestId = currMinRequestId;
        }
    }

    function subtractTotalRequestAmount(uint256 _amount) private {
        if (_amount > totalRequestsAmount) {
            totalRequestsAmount = 0;
        } else {
            totalRequestsAmount = totalRequestsAmount - _amount;
        }
    }

    function collectRelevantTokens(uint8 _requestType, uint256 _tokenAmount) private {
        if (_requestType == BURN_REQUEST_TYPE) {
            require(balanceOf(msg.sender) >= _tokenAmount, "Not enough tokens");
            IERC20Upgradeable(address(this)).safeTransferFrom(msg.sender, address(this), _tokenAmount);
        } else {
            token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        }
    }

    function openPosition(uint168 _amount, uint16 _maxBuyingPremiumFeePercentage, bool _catchRevert, bool _chargeOpenFee) private returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee, bool transactionSuccess) {
        transactionSuccess = true;

        if (_catchRevert) {
            (bool success, bytes memory returnData) = 
                address(platform).call(abi.encodePacked(platform.openPosition.selector, abi.encode(_amount, platform.maxCVIValue(), _maxBuyingPremiumFeePercentage, 1)));

            if (success) {
                (positionUnitsAmount, positionedTokenAmount, openPositionFee, buyingPremiumFee) = abi.decode(returnData, (uint168, uint168, uint168, uint168));
            } else {
                transactionSuccess = false;
            }
        } else {
            (positionUnitsAmount, positionedTokenAmount, openPositionFee, buyingPremiumFee) = !_chargeOpenFee ? 
                platform.openPositionWithoutFee(_amount, platform.maxCVIValue(), 1) : 
                platform.openPosition(_amount, platform.maxCVIValue(), _maxBuyingPremiumFeePercentage, 1);
        }
    }

    function getUpdatedTokenAmount(uint8 _requestType, uint168 _requestAmount) private view returns (uint168 updatedTokenAmount) {
        if (_requestType != BURN_REQUEST_TYPE) {
            return _requestAmount;
        }

        uint256 __updatedTokenAmount = underlyingToValue(_requestAmount);
        require(uint168(__updatedTokenAmount) == __updatedTokenAmount);
        updatedTokenAmount = uint168(__updatedTokenAmount);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IPlatform.sol";
import "./IRequestFeesCalculator.sol";
import "./ICVIOracle.sol";

interface IVolatilityToken {

    struct Request {
        uint8 requestType; // 1 => mint, 2 => burn
        uint168 tokenAmount;
        uint16 timeDelayRequestFeesPercent;
        uint16 maxRequestFeesPercent;
        address owner;
        uint32 requestTimestamp;
        uint32 targetTimestamp;
        bool useKeepers;
        uint16 maxBuyingPremiumFeePercentage;
    }

    event SubmitRequest(uint256 requestId, uint8 requestType, address indexed account, uint256 tokenAmount, uint256 submitFeesAmount, uint32 requestTimestamp, uint32 targetTimestamp, bool useKeepers, uint16 maxBuyingPremiumFeePercentage);
    event FulfillRequest(uint256 requestId, uint8 requestType, address indexed account, uint256 fulfillFeesAmount, bool isAborted, bool useKeepers, bool keepersCalled, address indexed fulfiller, uint32 fulfillTimestamp);
    event LiquidateRequest(uint256 requestId, uint8 requestType, address indexed account, address indexed liquidator, uint256 findersFeeAmount, bool useKeepers, uint32 liquidateTimestamp);
    event Mint(uint256 requestId, address indexed account, uint256 tokenAmount, uint256 positionedTokenAmount, uint256 mintedTokens, uint256 openPositionFee, uint256 buyingPremiumFee);
    event Burn(uint256 requestId, address indexed account, uint256 tokenAmountBeforeFees, uint256 tokenAmount, uint256 burnedTokens, uint256 closePositionFee, uint256 closingPremiumFee);

    function rebaseCVI() external;

    function submitMintRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);
    function submitKeepersMintRequest(uint168 tokenAmount, uint32 timeDelay, uint16 maxBuyingPremiumFeePercentage) external returns (uint256 requestId);
    function submitBurnRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);
    function submitKeepersBurnRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);

    function fulfillMintRequest(uint256 requestId, uint16 maxBuyingPremiumFeePercentage, bool keepersCalled) external returns (uint256 tokensMinted, bool success);
    function fulfillBurnRequest(uint256 requestId, bool keepersCalled) external returns (uint256 tokensBurned);

    function mintTokens(uint168 tokenAmount) external returns (uint256 mintedTokens);
    function burnTokens(uint168 burnAmount) external returns (uint256 tokenAmount);

    function liquidateRequest(uint256 requestId) external returns (uint256 findersFeeAmount);

    function setMinter(address minter) external;
    function setPlatform(IPlatform newPlatform) external;
    function setFeesCalculator(IFeesCalculator newFeesCalculator) external;
    function setFeesCollector(IFeesCollector newCollector) external;
    function setRequestFeesCalculator(IRequestFeesCalculator newRequestFeesCalculator) external;
    function setCVIOracle(ICVIOracle newCVIOracle) external;
    function setDeviationParameters(uint16 newDeviationPercentagePerSingleRebaseLag, uint16 newMinDeviationPercentage, uint16 newMaxDeviationPercentage) external;
    function setVerifyTotalRequestsAmount(bool verifyTotalRequestsAmount) external;
    function setMaxTotalRequestsAmount(uint256 maxTotalRequestsAmount) external;
    function setCappedRebase(bool newCappedRebase) external;

    function setMinRequestId(uint256 newMinRequestId) external;
    function setMaxMinRequestIncrements(uint256 newMaxMinRequestIncrements) external;

    function setFulfiller(address fulfiller) external;

    function setKeepersFeeVaultAddress(address newKeepersFeeVaultAddress) external;

    function setMinKeepersAmounts(uint256 newMinKeepersMintAmount, uint256 newMinKeepersBurnAmount) external;

    function platform() external view returns (IPlatform);
    function requestFeesCalculator() external view returns (IRequestFeesCalculator);
    function leverage() external view returns (uint8);
    function initialTokenToLPTokenRate() external view returns (uint256);

    function requests(uint256 requestId) external view returns (uint8 requestType, uint168 tokenAmount, uint16 timeDelayRequestFeesPercent, uint16 maxRequestFeesPercent,
        address owner, uint32 requestTimestamp, uint32 targetTimestamp, bool useKeepers, uint16 maxBuyingPremiumFeePercentage);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IRequestManager {

	function nextRequestId() external view returns (uint256);
    function minRequestId() external view returns (uint256);
    function maxMinRequestIncrements() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IElasticToken.sol";

contract ElasticToken is IElasticToken, OwnableUpgradeable {

    uint256 public constant SCALING_FACTOR_DECIMALS = 10**24;
    uint256 public constant DELTA_PRECISION_DECIMALS = 10**18;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public scalingFactor;
    uint256 public initSupply;
    address public rebaser;

    mapping(address => uint256) internal _underlyingBalances;
    mapping(address => mapping(address => uint256)) internal _allowedFragments;

    modifier onlyRebaser() {
        require(msg.sender == rebaser, "Not allowed");
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0), "Zero address");
        _;
    }

    function __ElasticToken_init(string memory name_, string memory symbol_, uint8 decimals_) public onlyInitializing {
        OwnableUpgradeable.__Ownable_init();

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        scalingFactor = SCALING_FACTOR_DECIMALS;
    }

    function maxScalingFactor() public view override returns (uint256) {
        // Scaling factor can only go up to 2**256-1 = initSupply * scalingFactor
        return type(uint256).max / initSupply;
    }

    function _mint(address to, uint256 amount) internal validRecipient(to) {
        _beforeTokenTransfer(address(0), to, amount);

        totalSupply = totalSupply + amount;
        uint256 underlyingValue = valueToUnderlying(amount);
        initSupply = initSupply + underlyingValue;

        // Make sure init suuply increase keeps scaling factor below max
        require(scalingFactor <= maxScalingFactor(), "Max scaling factor too low");

        _underlyingBalances[to] = _underlyingBalances[to] + underlyingValue;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address to, uint256 amount) internal validRecipient(to) {
        _beforeTokenTransfer(to, address(0), amount);

        totalSupply = totalSupply - amount;
        uint256 underlyingValue = valueToUnderlying(amount);

        // Note: as initSupply decreases, max sacling factor increases, so no need to test scaling factor against it
        initSupply = initSupply - underlyingValue;

        _underlyingBalances[to] = _underlyingBalances[to] - underlyingValue;

        emit Transfer(to, address(0), amount);
    }

    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool) {
        // Note: As scaling factor grows, dust will be untransferrable
        // Minimum transfer value == scalingFactor / 1e24;

        _beforeTokenTransfer(msg.sender, to, value);

        uint256 underlyingValue = valueToUnderlying(value);
        _underlyingBalances[msg.sender] = _underlyingBalances[msg.sender] - underlyingValue;
        _underlyingBalances[to] = _underlyingBalances[to] + underlyingValue;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override validRecipient(from) validRecipient(to) returns (bool) {
        _beforeTokenTransfer(from, to, value);

        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender] - value;

        uint256 underlyingValue = valueToUnderlying(value);
        _underlyingBalances[from] = _underlyingBalances[from] - underlyingValue;
        _underlyingBalances[to] = _underlyingBalances[to] + underlyingValue;
        emit Transfer(from, to, value);

        return true;
    }

    function balanceOf(address who) public view override returns (uint256) {
      return underlyingToValue(_underlyingBalances[who]);
    }

    function balanceOfUnderlying(address who) external view override returns (uint256) {
      return _underlyingBalances[who];
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function setRebaser(address _rebaser) external override onlyOwner {
        rebaser = _rebaser;
    }

    /**
    * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
    *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
    *      and targetRate is CpiOracleRate / baseCpi
    */
    function rebase(uint256 indexDelta, bool positive) internal onlyRebaser returns (uint256) {        
        if (indexDelta == 0) {
          emit Rebase(block.timestamp, scalingFactor, scalingFactor);
          return totalSupply;
        }

        uint256 prevScalingFactor = scalingFactor;

        if (!positive) {
            // Negative rebase, decrease scaling factor
            scalingFactor = scalingFactor * (DELTA_PRECISION_DECIMALS - indexDelta) / DELTA_PRECISION_DECIMALS;
        } else {
            // Positive reabse, increase scaling factor
            uint256 newScalingFactor = scalingFactor * (DELTA_PRECISION_DECIMALS + indexDelta) / DELTA_PRECISION_DECIMALS;
            if (newScalingFactor < maxScalingFactor()) {
                scalingFactor = newScalingFactor;
            } else {
                scalingFactor = maxScalingFactor();
            }
        }

        totalSupply = underlyingToValue(initSupply);

        emit Rebase(block.timestamp, prevScalingFactor, scalingFactor);
        return totalSupply;
    }

    function underlyingToValue(uint256 unerlyingValue) public override view returns (uint256) {
        return unerlyingValue * scalingFactor / SCALING_FACTOR_DECIMALS;
    }

    function valueToUnderlying(uint256 value) public override view returns (uint256) {
        return value * SCALING_FACTOR_DECIMALS / scalingFactor;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";
import "./IFeesCalculator.sol";
import "./IRewardsCollector.sol";
import "./IFeesCollector.sol";
import "./ILiquidation.sol";

interface IPlatform {

    struct Position {
        uint168 positionUnitsAmount;
        uint8 leverage;
        uint32 openCVIValue;
        uint32 creationTimestamp;
        uint32 originalCreationTimestamp;
    }

    event Deposit(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event Withdraw(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event OpenPosition(address indexed account, uint256 tokenAmount, uint8 leverage, uint256 feeAmount, uint256 positionUnitsAmount, uint256 cviValue);
    event ClosePosition(address indexed account, uint256 tokenAmount, uint256 feeAmount, uint256 positionUnitsAmount, uint8 leverage, uint256 cviValue);
    event LiquidatePosition(address indexed positionAddress, uint256 currentPositionBalance, bool isBalancePositive, uint256 positionUnitsAmount);

    function deposit(uint256 tokenAmount, uint256 minLPTokenAmount) external returns (uint256 lpTokenAmount);
    function withdraw(uint256 tokenAmount, uint256 maxLPTokenBurnAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);
    function withdrawLPTokens(uint256 lpTokenAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);

    function increaseSharedPool(uint256 tokenAmount) external;

    function openPositionWithoutFee(uint168 tokenAmount, uint32 maxCVI, uint8 leverage) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function openPosition(uint168 tokenAmount, uint32 maxCVI, uint16 maxBuyingPremiumFeePercentage, uint8 leverage) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function closePositionWithoutFee(uint168 positionUnitsAmount, uint32 minCVI) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);
    function closePosition(uint168 positionUnitsAmount, uint32 minCVI) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);

    function liquidatePositions(address[] calldata positionOwners) external returns (uint256 finderFeeAmount);

    function setAddressSpecificParameters(address holderAddress, bool shouldLockPosition, bool noPremiumFeeAllowed, bool increaseSharedPoolAllowed, bool isLiquidityProvider) external;

    function setRevertLockedTransfers(bool revertLockedTransfers) external;

    function setSubContracts(IFeesCollector newCollector, ICVIOracle newOracle, IRewardsCollector newRewards, ILiquidation newLiquidation, address _newStakingContractAddress) external;
    function setFeesCalculator(IFeesCalculator newCalculator) external;

    function setLatestOracleRoundId(uint80 newOracleRoundId) external;
    function setMaxTimeAllowedAfterLatestRound(uint32 newMaxTimeAllowedAfterLatestRound) external;

    function setLockupPeriods(uint256 newLPLockupPeriod, uint256 newBuyersLockupPeriod) external;

    function setEmergencyParameters(bool newEmergencyWithdrawAllowed, bool newCanPurgeSnapshots) external;

    function setMaxAllowedLeverage(uint8 newMaxAllowedLeverage) external;

    function calculatePositionBalance(address positionAddress) external view returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt);
    function calculatePositionPendingFees(address positionAddress, uint168 positionUnitsAmount) external view returns (uint256 pendingFees);

    function totalBalance(bool _withAddendum) external view returns (uint256 balance);

    function calculateLatestTurbulenceIndicatorPercent() external view returns (uint16);

    function cviOracle() external view returns (ICVIOracle);
    function feesCalculator() external view returns (IFeesCalculator);

    function PRECISION_DECIMALS() external view returns (uint256);

    function totalPositionUnitsAmount() external view returns (uint256);
    function totalLeveragedTokensAmount() external view returns (uint256);
    function totalFundingFeesAmount() external view returns (uint256);
    function latestFundingFees() external view returns (uint256);

    function positions(address positionAddress) external view returns (uint168 positionUnitsAmount, uint8 leverage, uint32 openCVIValue, uint32 creationTimestamp, uint32 originalCreationTimestamp);
    function buyersLockupPeriod() external view returns (uint256);
    function maxCVIValue() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IVolatilityToken.sol";

interface IRequestFeesCalculator {
    function calculateTimePenaltyFee(IVolatilityToken.Request calldata request) external view returns (uint16 feePercentage);
    function calculateTimeDelayFee(uint256 timeDelay) external view returns (uint16 feePercentage);
    function calculateFindersFee(uint256 tokensLeftAmount) external view returns (uint256 findersFeeAmount);
    function calculateKeepersFee(uint256 tokensAmount) external view returns (uint256 keepersFeeAmount);

    function isLiquidable(IVolatilityToken.Request calldata request) external view returns (bool liquidable);

    function minWaitTime() external view returns (uint32);

    function setTimeWindow(uint32 minTimeWindow, uint32 maxTimeWindow) external;
    function setTimeDelayFeesParameters(uint16 minTimeDelayFeePercent, uint16 maxTimeDelayFeePercent) external;
    function setMinWaitTime(uint32 newMinWaitTime) external;
    function setTimePenaltyFeeParameters(uint16 beforeTargetTimeMaxPenaltyFeePercent, uint32 afterTargetMidTime, uint16 afterTargetMidTimePenaltyFeePercent, uint32 afterTargetMaxTime, uint16 afterTargetMaxTimePenaltyFeePercent) external;
    function setFindersFee(uint16 findersFeePercent) external;
    function setKeepersFeePercent(uint16 keepersFeePercent) external;
    function setKeepersFeeMax(uint256 keepersFeeMax) external;

    function getMaxFees() external view returns (uint16 maxFeesPercent);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint32 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);

    function setDeviationCheck(bool newDeviationCheck) external;
    function setMaxDeviation(uint16 newMaxDeviation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";
import "./IThetaVaultInfo.sol";

interface IFeesCalculator {

    struct CVIValue {
        uint256 period;
        uint32 cviValue;
    }

    struct SnapshotUpdate {
        uint256 latestSnapshot;
        uint256 singleUnitFundingFee;
        uint256 totalTime;
        uint256 totalRounds;
        uint256 cviValueTimestamp;
        uint80 newLatestRoundId;
        uint32 cviValue;
        bool updatedSnapshot;
        bool updatedLatestRoundId;
        bool updatedLatestTimestamp;
        bool updatedTurbulenceData;
    }

    function updateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint32 lastCVIValue, uint32 currCVIValue) external;

    function setOracle(ICVIOracle cviOracle) external;
    function setThetaVault(IThetaVaultInfo thetaVault) external;

    function setStateUpdator(address newUpdator) external;

    function setDepositFee(uint16 newDepositFeePercentage) external;
    function setWithdrawFee(uint16 newWithdrawFeePercentage) external;
    function setOpenPositionFee(uint16 newOpenPositionFeePercentage) external;
    function setOpenPositionLPFee(uint16 newOpenPositionLPFeePercent) external;
    function setClosePositionLPFee(uint16 newClosePositionLPFeePercent) external;
    function setClosePositionFee(uint16 newClosePositionFeePercentage) external;
    function setClosePositionMaxFee(uint16 newClosePositionMaxFeePercentage) external;
    function setClosePositionFeeDecay(uint256 newClosePositionFeeDecayPeriod) external;
    
    function setOracleHeartbeatPeriod(uint256 newOracleHeartbeatPeriod) external;
    function setBuyingPremiumFeeMax(uint16 newBuyingPremiumFeeMaxPercentage) external;
    function setBuyingPremiumThreshold(uint16 newBuyingPremiumThreshold) external;
    function setClosingPremiumFeeMax(uint16 newClosingPremiumFeeMaxPercentage) external;
    function setCollateralToBuyingPremiumMapping(uint16[] calldata newCollateralToBuyingPremiumMapping) external;
    function setFundingFeeConstantRate(uint16 newfundingFeeConstantRate) external;
    function setCollateralToExtraFundingFeeMapping(uint32[] calldata newCollateralToExtraFundingFeeMapping) external;
    function setTurbulenceStep(uint16 newTurbulenceStepPercentage) external;
    function setMaxTurbulenceFeePercentToTrim(uint16 newMaxTurbulenceFeePercentToTrim) external;
    function setTurbulenceDeviationThresholdPercent(uint16 newTurbulenceDeviationThresholdPercent) external;
    function setTurbulenceDeviationPercent(uint16 newTurbulenceDeviationPercentage) external;

    function calculateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint32 _lastCVIValue, uint32 _currCVIValue) external view returns (uint16);

    function calculateBuyingPremiumFee(uint168 tokenAmount, uint8 leverage, uint256 lastTotalLeveragedTokens, uint256 lastTotalPositionUnits, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    function calculateBuyingPremiumFeeWithAddendum(uint168 tokenAmount, uint8 leverage, uint256 lastTotalLeveragedTokens, uint256 lastTotalPositionUnits, uint256 totalLeveragedTokens, uint256 totalPositionUnits, uint16 _turbulenceIndicatorPercent) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);

    function calculateClosingPremiumFee() external view returns (uint16 combinedPremiumFeePercentage);

    function calculateSingleUnitFundingFee(CVIValue[] memory cviValues, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint256 fundingFee);
    function calculateSingleUnitPeriodFundingFee(CVIValue memory cviValue, uint256 collateralRatio) external view returns (uint256 fundingFee, uint256 fundingFeeRatePercents);
    function updateSnapshots(uint256 latestTimestamp, uint256 blockTimestampSnapshot, uint256 latestTimestampSnapshot, uint80 latestOracleRoundId, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (SnapshotUpdate memory snapshotUpdate);

    function calculateClosePositionFeePercent(uint256 creationTimestamp, bool isNoLockPositionAddress) external view returns (uint16);
    function calculateWithdrawFeePercent(uint256 lastDepositTimestamp) external view returns (uint16);

    function calculateCollateralRatio(uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint256 collateralRatio);

    function depositFeePercent() external view returns (uint16);
    function withdrawFeePercent() external view returns (uint16);
    function openPositionFeePercent() external view returns (uint16);
    function closePositionFeePercent() external view returns (uint16);
    function openPositionLPFeePercent() external view returns (uint16);
    function closePositionLPFeePercent() external view returns (uint16);

    function openPositionFees() external view returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult);

    function turbulenceIndicatorPercent() external view returns (uint16);
    function oracleLeverage() external view returns (uint8);

    function getCollateralToBuyingPremiumMapping() external view returns(uint16[] memory);
    function getCollateralToExtraFundingFeeMapping() external view returns(uint32[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IRewardsCollector {
	function reward(address account, uint256 positionUnits, uint8 leverage) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeesCollector {
    function sendProfit(uint256 amount, IERC20 token) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ILiquidation {	
	function setMinLiquidationThresholdPercents(uint16[8] calldata newMinThresholdPercents) external;
	function setMinLiquidationRewardPercent(uint16 newMinRewardPercent) external;
	function setMaxLiquidationRewardPercents(uint16[8] calldata newMaxRewardPercents) external;
	function isLiquidationCandidate(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint32 openCVIValue, uint8 leverage) external view returns (bool);
	function getLiquidationReward(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint32 openCVIValue, uint8 leverage) external view returns (uint256 finderFeeAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IThetaVaultInfo {
    function totalVaultLeveragedAmount() external view returns (uint256);
    function vaultPositionUnits() external view returns (uint256);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IElasticToken {

    event Rebase(uint256 epoch, uint256 prevScalingFactor, uint256 newScalingFactor);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function balanceOf(address who) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function balanceOfUnderlying(address who) external view returns(uint256);
    function maxScalingFactor() external view returns (uint256);
    function underlyingToValue(uint256 unerlyingValue) external view returns (uint256);
    function valueToUnderlying(uint256 value) external view returns (uint256);

    function setRebaser(address rebaser) external;
}