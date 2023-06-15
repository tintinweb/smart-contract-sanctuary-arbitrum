// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IFeeLP {
    function balanceOf(address account) external view returns (uint256);

    function unlock(
        address user,
        address lockTo,
        uint256 amount,
        bool isIncrease
    ) external;

    function burnLocked(
        address user,
        address lockTo,
        uint256 amount,
        bool isIncrease
    ) external;

    function lock(
        address user,
        address lockTo,
        uint256 amount,
        bool isIncrease
    ) external;

    function locked(
        address user,
        address lockTo,
        bool isIncrease
    ) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transfer(address recipient, uint256 amount) external;

    function isKeeper(address addr) external view returns (bool);

    function decimals() external pure returns (uint8);

    function mintTo(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILPToken {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function mintTo(address to, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRouter {
    function createIncreasePosition(
        address _inToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _insuranceLevel,
        uint256 _executionFee,
        bytes32 _referralCode
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address _inToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _insuranceLevel,
        uint256 _minOut,
        uint256 _executionFee
    ) external payable returns (bytes32);

    function increasePositionRequestKeysStart() external returns (uint256);

    function decreasePositionRequestKeysStart() external returns (uint256);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function referral() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IVault {
    struct Position {
        uint256 size; //LP
        uint256 collateral; //LP
        uint256 averagePrice;
        uint256 entryFundingRate;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
        uint256 insurance; //max 50%
        uint256 insuranceLevel;
    }

    struct UpdateGlobalDataParams {
        address account;
        address indexToken;
        uint256 sizeDelta;
        uint256 price; //current price
        bool isIncrease;
        bool isLong;
        uint256 insuranceLevel;
        uint256 insurance;
    }

    function getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _insuranceLevel
    ) external pure returns (bytes32);

    function getPositionsOfKey(
        bytes32 key
    ) external view returns (Position memory);

    function getPositions(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _insuranceLevel
    ) external view returns (Position memory);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function usdcToken() external view returns (address);

    function LPToken() external view returns (address);

    function feeReserves(address _token) external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(
        uint256 index
    ) external view returns (address);

    function whitelistedTokens(address token) external view returns (bool);

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _insuranceLevel
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, bool, uint256, uint256);

    function getProfitLP(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function USDC_DECIMALS() external view returns (uint256);

    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _insuranceLevel,
        uint256 feeLP
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        uint256 _collateralDelta,
        bool _isLong,
        address _receiver,
        uint256 _insuranceLevel,
        uint256 feeLP
    ) external returns (uint256, uint256);

    function insuranceOdds() external view returns (uint256);

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function insuranceLevel(uint256 lvl) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;

   
    function getPrice(address _token, bool _maximise) external view returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);
    function getLatestPrimaryPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "./IVault.sol";

interface IVaultUtil {
    function updateGlobalData(IVault.UpdateGlobalDataParams memory p) external;

    function updateGlobal(
        address _indexToken,
        uint256 price,
        uint256 _sizeDelta,
        bool _isLong,
        bool _increase,
        uint256 _insurance
    ) external;

    function getLPPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../library/utils/math/SafeMath.sol";
import "../library/token/ERC20/IERC20.sol";
import "../library/token/ERC20/utils/SafeERC20.sol";
import "../library/security/ReentrancyGuard.sol";

import "./interfaces/ILPToken.sol";
import "./interfaces/IFeeLP.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IVaultPriceFeed.sol";
import "./interfaces/IVaultUtil.sol";
import "../referrals/interfaces/IReferral.sol";


interface GLPmanager {
    function getAumInUsdg(bool maximise) external view returns (uint256);

    function getPrice(bool _maximise) external view returns (uint256);
}

contract Vault is ReentrancyGuard, IVault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct ReduceCollateralResult {
        bool hasProfit;
        uint256 LPOut;
        uint256 LPOutAfterFee;
        uint256 profit;
        uint256 feeLPAmount;
    }

    struct FinalDecreasePositionParams {
        address account;
        address receiver;
        bool hasProfit;
        uint256 orignLevel;
        uint256 LPOut;
        uint256 LPOutAfterFee;
        uint256 collateral;
        uint256 insurance;
        uint256 profit;
        uint256 insuranceProportion;
    }

    struct EmitPositionParams {
        uint256 LPOut;
        uint256 LPOutAfterFee;
        uint256 feeLPAmount;
        address account;
        address indexToken;
        uint256 orignLevel;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        uint256 price;
        uint256 insurance;
        uint256 insuranceLevel;
        uint256 payInsurance;
    }

    struct DecreasePositionParams {
        address account;
        address indexToken;
        uint256 sizeDelta;
        uint256 collateralDelta;
        bool isLong;
        address receiver;
        uint256 insuranceLevel; //0-5
        uint256 feeLP;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public maxLeverage = 50 * 10000; // 50x
    uint256 public LP_DECIMALS = 18;
    uint256 public USDC_DECIMALS = 6;
    uint256 public PRICE_DECIMALS = 30;
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%

    bool public isInitialized;
    address public priceFeed;
    address public LPToken;
    address public FeeLP;
    address public usdcToken; //only usdc can buy LP
    address public gov;
    IVaultUtil public vaultUtil; //keep all global data
    address public router;
    address public orderbook;
    uint256 public liquidationFee;
    bool public inPrivateLiquidationMode = true;
    mapping(address => bool) public isLiquidator;

    uint256 public liquidationFeeRate = 100; //1%
    uint256 public taxBasisPoints = 8; // base fee 0.08% for increase decrease
    uint256 public maxGasPrice;
    uint256 public minCollateral = 10e18; //10LP
    //0 no insurance; 1 10%;2 20%;3 30%;4 40%;5 50%
    mapping(uint256 => uint256) public insuranceLevel;
    uint256 public insuranceOdds = 20000; //insurance*2
    uint256 public insuranceFeeRate = 300; //3%
    //index token can open position
    address[] public allWhitelistedTokens;
    mapping(address => bool) public whitelistedTokens;
    //white listed token's decimal
    mapping(address => uint256) public tokenDecimals;

    //if profit have too much change in 2 minutes,profit set 0
    //if profit less than 0,sub from user's size when calculate next price
    uint256 public minProfitTime = 2 minutes; //calculate profit over 2 minutes
    mapping(address => uint256) public minProfitBasisPoints;

    //token=>amount,usdc for buy LP; LP transfer in for open close position
    mapping(address => uint256) public tokenBalances;
    //token=>fee,usdc for buy LP; LP fee for sell LP, open close position
    mapping(address => uint256) public feeReserves;

    //key=>position
    mapping(bytes32 => Position) public positions;

    address public teamAddress;
    address public earnAddress;
    uint256 public toTeamRatio = 2500;
    bool public LPFlag;

    uint256 public maxLiquidateLeverage = 1250 * 10000;

    uint256[50] private _gap;
    event BuyLP(
        address account,
        address receiver,
        address token,
        uint256 tokenAmount,
        uint256 LPAmount
    );

    event SellLP(
        address account,
        address receiver,
        address token,
        uint256 LPAmount,
        uint256 tokenAmount
    );

    event IncreasePosition(
        address account,
        address indexToken,
        uint256 orignLevel,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee,
        uint256 insurance,
        uint256 insuranceLevel
    );

    event DecreasePosition(
        address account,
        address indexToken,
        uint256 orignLevel,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee,
        uint256 insurance,
        uint256 insuranceLevel,
        uint256 LPOutAfterFee,
        uint256 payInsurance
    );

    event LiquidatePosition(
        address account,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        int256 realisedPnl,
        uint256 markPrice,
        uint256 insuranceLevel,
        uint256 marginAdnLiquidateFees,
        uint256 payInsurance
    );

    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        int256 realisedPnl,
        uint256 markPrice,
        uint256 insuranceLevel
    );

    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        int256 realisedPnl,
        uint256 insuranceLevel
    );

    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);
    event CollectMarginFees(uint256 feeLP);

    modifier onlyAuthorized() {
        require(
            (msg.sender == router) || (msg.sender == orderbook),
            "Vault: invalid sender"
        );
        _;
    }

    // once the parameters are verified to be working correctly,
    // gov should be set to a timelock contract or a governance contract
    function initialize(
        address _LPToken,
        address _FeeLP,
        address _usdc,
        address _priceFeed,
        address _vaultUtil,
        uint256 _liquidationFee
    ) external {
        require(!isInitialized, "Vault: inited");
        isInitialized = true;
        gov = msg.sender;
        LPToken = _LPToken;
        FeeLP = _FeeLP;
        usdcToken = _usdc;
        priceFeed = _priceFeed;
        vaultUtil = IVaultUtil(_vaultUtil);
        liquidationFee = _liquidationFee;
        // 1 10%;2 20%;3 30%;4 40%;5 50%
        insuranceLevel[1] = 1000;
        insuranceLevel[2] = 2000;
        insuranceLevel[3] = 3000;
        insuranceLevel[4] = 4000;
        insuranceLevel[5] = 5000;

        maxLeverage = 100 * 10000;
        maxLiquidateLeverage = 1250 * 10000;
        LP_DECIMALS = 18;
        USDC_DECIMALS = 6;
        PRICE_DECIMALS = 30;
        inPrivateLiquidationMode = true;
        liquidationFeeRate = 100; //1%
        taxBasisPoints = 8; // base fee 0.08% for increase decrease
        minCollateral = 10e18; //10LP
        insuranceOdds = 20000; //insurance*2
        insuranceFeeRate = 300; //3%
        minProfitTime = 2 minutes;
        toTeamRatio = 2500;
    }

    function buyLP(
        address _receiver,
        uint256 _amount,
        uint256 _LPMinOut
    ) external nonReentrant returns (uint256) {
        require(LPFlag, "Vault: buy forbidden");
        _validateGasPrice();
        IERC20(usdcToken).safeTransferFrom(msg.sender, address(this), _amount);
        //get price first,u
        uint256 LPPrice = vaultUtil.getLPPrice();
        require(LPPrice > 0, "Vault: LP price 0");
        uint256 mintAmount = _amount
            .mul(10 ** LP_DECIMALS)
            .mul(10 ** PRICE_DECIMALS)
            .div(LPPrice)
            .div(10 ** USDC_DECIMALS);

        if (_LPMinOut > 0) {
            require(mintAmount >= _LPMinOut, "Vault: need more slippage");
        }

        ILPToken(LPToken).mintTo(_receiver, mintAmount);
        _updateTokenBalance(usdcToken);
        emit BuyLP(msg.sender, _receiver, usdcToken, _amount, mintAmount);

        return mintAmount;
    }

    function sellLP(
        address _receiver,
        uint256 _amount
    ) external nonReentrant returns (uint256) {
        require(LPFlag, "Vault: sell forbidden");
        _validateGasPrice();
        //how much usdc
        uint256 LPPrice = vaultUtil.getLPPrice();

        require(_amount > 0, "Vault: _amount 0");
        //transfer in,keep fee,burn left
        IERC20(LPToken).safeTransferFrom(msg.sender, address(this), _amount);

        //tokenBalances[LPToken] = tokenBalances[LPToken].sub(_amount);
        ILPToken(LPToken).burn(address(this), _amount);

        uint256 tokenAmount = _amount
            .mul(LPPrice)
            .mul(10 ** USDC_DECIMALS)
            .div(10 ** LP_DECIMALS)
            .div(10 ** PRICE_DECIMALS);

        //update tokenBalances in this func
        _transferOut(usdcToken, tokenAmount, _receiver);

        emit SellLP(msg.sender, _receiver, usdcToken, _amount, tokenAmount);

        return tokenAmount;
    }

    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _insuranceLevel, //0 1-5
        uint256 feeLP
    ) external nonReentrant onlyAuthorized {
        if (_insuranceLevel > 0) {
            require(
                insuranceLevel[_insuranceLevel] > 0,
                "Vault: insurance level invalid"
            );
        }
        require(
            _collateralDelta >= minCollateral,
            "Vault: less than min collateral"
        );
        _validateGasPrice();
        uint256 _insurance;
        if (_insuranceLevel > 0 && _sizeDelta > 0) {
            _insurance = _collateralDelta
                .mul(insuranceLevel[_insuranceLevel])
                .div(BASIS_POINTS_DIVISOR);
        }

        //burn insurance
        if (_insurance > 0) {
            ILPToken(LPToken).burn(address(this), _insurance);
        }

        require(
            whitelistedTokens[_indexToken],
            "Vault: index token not white listed"
        );

        uint256 price = _isLong
            ? getMaxPrice(_indexToken)
            : getMinPrice(_indexToken);

        //update global data first before update size
        UpdateGlobalDataParams memory p = UpdateGlobalDataParams(
            _account,
            _indexToken,
            _sizeDelta, //return directly when _sizeDelta is 0
            price,
            true,
            _isLong,
            _insuranceLevel,
            _insurance
        );
        vaultUtil.updateGlobalData(p);
        uint256 fee = getPositionFee(_sizeDelta);
        if (feeLP == 0) {
            feeReserves[LPToken] = feeReserves[LPToken].add(fee);
            splitLP(_account, fee);
        } else {
            feeReserves[FeeLP] = feeReserves[FeeLP].add(feeLP);
        }

        _increasePosition(
            _account,
            _indexToken,
            _sizeDelta,
            _collateralDelta,
            fee,
            _isLong,
            _insurance,
            _insuranceLevel
        );
    }

    function _increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        uint256 _collateralDelta,
        uint256 _fee,
        bool _isLong,
        uint256 _insurance,
        uint256 _insuranceLevel
    ) private {
        bytes32 key = getPositionKey(
            _account,
            _indexToken,
            _isLong,
            _insuranceLevel
        );
        Position storage position = positions[key];
        position.insurance = position.insurance.add(_insurance);
        uint256 orignLevel = position.collateral > 0
            ? position.size.mul(BASIS_POINTS_DIVISOR).div(position.collateral)
            : 0;
        uint256 price = _isLong
            ? getMaxPrice(_indexToken)
            : getMinPrice(_indexToken);
        if (position.size == 0) {
            position.averagePrice = price;
        }

        if (position.size > 0 && _sizeDelta > 0) {
            position.averagePrice = getNextAveragePrice(
                _indexToken,
                position.size,
                position.averagePrice,
                price,
                _sizeDelta
            );
        }

        position.collateral = position.collateral.add(_collateralDelta);
        require(position.collateral >= _fee, "Vault: less than margin fee");
        position.size = position.size.add(_sizeDelta);
        position.lastIncreasedTime = block.timestamp;

        require(position.size >= position.collateral, "Vault: size<collateral");

        if (position.size == _sizeDelta) {
            require(
                position.collateral.mul(maxLeverage) >=
                    position.size.mul(BASIS_POINTS_DIVISOR),
                "Vault: maxLeverage exceeded"
            );
        } else {
            validateLiquidation(
                _account,
                _indexToken,
                _isLong,
                true,
                _insuranceLevel
            );
        }

        vaultUtil.updateGlobal(
            _indexToken,
            price,
            _sizeDelta,
            _isLong,
            true,
            _insurance
        );

        emit IncreasePosition(
            _account,
            _indexToken,
            orignLevel,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            price,
            _fee,
            _insurance,
            _insuranceLevel
        );
        emit UpdatePosition(
            key,
            position.size,
            position.collateral,
            position.averagePrice,
            position.realisedPnl,
            price,
            _insuranceLevel
        );
    }

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        uint256 _collateralDelta,
        bool _isLong,
        address _receiver,
        uint256 _insuranceLevel,
        uint256 feeLP
    ) external nonReentrant onlyAuthorized returns (uint256, uint256) {
        if (_insuranceLevel > 0) {
            require(
                insuranceLevel[_insuranceLevel] > 0,
                "Vault: insurance level error"
            );
        }
        _validateGasPrice();
        uint256 price = _isLong
            ? getMinPrice(_indexToken)
            : getMaxPrice(_indexToken);
        uint256 insurance;
        {
            bytes32 key = getPositionKey(
                _account,
                _indexToken,
                _isLong,
                _insuranceLevel
            );
            Position storage position = positions[key];
            insurance = position.insurance;
            require(position.size > 0, "Vault: size 0");
            require(
                position.size >= _sizeDelta,
                "Vault: _sizeDelta bigger than size"
            );
        }

        //update global data first before update size
        UpdateGlobalDataParams memory p = UpdateGlobalDataParams(
            _account,
            _indexToken,
            _sizeDelta,
            price,
            false,
            _isLong,
            _insuranceLevel,
            insurance
        );
        vaultUtil.updateGlobalData(p);

        DecreasePositionParams memory param = DecreasePositionParams(
            _account,
            _indexToken,
            _sizeDelta,
            _collateralDelta,
            _isLong,
            _receiver,
            _insuranceLevel,
            feeLP
        );
        return _decreasePosition(param);
    }

    function _decreasePosition(
        DecreasePositionParams memory param
    ) private returns (uint256, uint256) {
        bytes32 key = getPositionKey(
            param.account,
            param.indexToken,
            param.isLong,
            param.insuranceLevel
        );
        Position storage position = positions[key];
        uint256 originalCollateral = position.collateral;
        FinalDecreasePositionParams
            memory finalParams = FinalDecreasePositionParams(
                param.account,
                param.receiver,
                false, //result.hasProfit,
                position.size.mul(BASIS_POINTS_DIVISOR).div(
                    position.collateral
                ), //orign level  *  10000
                0, //result.LPOut,
                0, //result.LPOutAfterFee,
                position.collateral,
                position.insurance,
                0, //result.profit,
                param.sizeDelta.mul(BASIS_POINTS_DIVISOR).div(position.size)
            );

        require(
            position.size >= param.sizeDelta,
            "Vault: _sizeDelta bigger than size"
        );
        require(
            position.collateral >= param.collateralDelta,
            "Vault: collateral delta bigger than collateral"
        );

        ReduceCollateralResult memory result = _reduceCollateral(
            param.account,
            param.indexToken,
            param.collateralDelta,
            param.sizeDelta,
            param.isLong,
            param.insuranceLevel,
            param.feeLP
        );

        finalParams.hasProfit = result.hasProfit;
        finalParams.LPOut = result.LPOut;
        finalParams.LPOutAfterFee = result.LPOutAfterFee;
        finalParams.profit = result.profit;

        param.collateralDelta = position.size == param.sizeDelta
            ? originalCollateral
            : param.collateralDelta;

        if (result.hasProfit) {
            //mint profit here,then transfer to user
            ILPToken(LPToken).mintTo(address(this), result.profit);
        } else {
            //burn loss
            ILPToken(LPToken).burn(address(this), result.profit);
        }
        uint256 price = param.isLong
            ? getMinPrice(param.indexToken)
            : getMaxPrice(param.indexToken);

        {
            if (position.size != param.sizeDelta) {
                position.size = position.size.sub(param.sizeDelta);
                require(
                    position.collateral >= minCollateral,
                    "Vault: less than min collateral"
                );
                require(
                    position.size >= position.collateral,
                    "Vault: size less than collateral"
                );

                validateLiquidation(
                    param.account,
                    param.indexToken,
                    param.isLong,
                    true,
                    param.insuranceLevel
                );
                emit UpdatePosition(
                    key,
                    position.size,
                    position.collateral,
                    position.averagePrice,
                    position.realisedPnl,
                    price,
                    param.insuranceLevel
                );
            } else {
                emit ClosePosition(
                    key,
                    position.size,
                    position.collateral,
                    position.averagePrice,
                    position.realisedPnl,
                    param.insuranceLevel
                );
                delete positions[key];
            }

            EmitPositionParams memory tp = EmitPositionParams(
                result.LPOut,
                result.LPOutAfterFee,
                result.feeLPAmount,
                param.account,
                param.indexToken,
                finalParams.orignLevel,
                param.collateralDelta,
                param.sizeDelta,
                param.isLong,
                price,
                position.insurance, //0 when close all size
                param.insuranceLevel,
                0
            );

            vaultUtil.updateGlobal(
                param.indexToken,
                price,
                param.sizeDelta,
                param.isLong,
                false,
                position.insurance
            );

            return (
                position.collateral,
                finalDecreasePosition(
                    finalParams,
                    position,
                    param.sizeDelta,
                    tp
                )
            );
        }
    }

    function emitPosition(EmitPositionParams memory t) private {
        uint256 fee = t.LPOut.sub(t.LPOutAfterFee);
        if (fee == 0) {
            fee = t.feeLPAmount;
            feeReserves[FeeLP] = feeReserves[FeeLP].add(fee);
        } else {
            splitLP(t.account, fee);
            feeReserves[LPToken] = feeReserves[LPToken].add(fee);
        }

        emit DecreasePosition(
            t.account,
            t.indexToken,
            t.orignLevel,
            t.collateralDelta,
            t.sizeDelta,
            t.isLong,
            t.price,
            fee,
            t.insurance,
            t.insuranceLevel,
            t.LPOutAfterFee,
            t.payInsurance
        );
    }

    function finalDecreasePosition(
        FinalDecreasePositionParams memory f,
        Position storage position,
        uint256 _sizeDelta,
        EmitPositionParams memory tp
    ) private returns (uint256) {
        //user have no profit,need pay insurance to user with odds
        if ((f.insurance > 0) && !f.hasProfit && _sizeDelta > 0) {
            //calculate profit or not,f.LPOut>f.collateral means user have profit
            require(f.LPOut <= f.collateral, "Vault: profit invalid");

            //already burn in up level func
            uint256 loss = f.profit;
            //by proportion
            uint256 payOdds = f
                .insurance
                .mul(f.insuranceProportion)
                .mul(insuranceOdds)
                .div(BASIS_POINTS_DIVISOR)
                .div(BASIS_POINTS_DIVISOR);
            //need pay user's insurance
            tp.payInsurance = loss > payOdds ? payOdds : loss;
            //mint insurance part
            if (tp.payInsurance > 0) {
                ILPToken(LPToken).mintTo(address(this), tp.payInsurance);
            }
            uint256 insuranceFee = tp.payInsurance.mul(insuranceFeeRate).div(
                BASIS_POINTS_DIVISOR
            );
            splitInsurance(insuranceFee);
            tp.payInsurance = tp.payInsurance.sub(insuranceFee);
        }

        emitPosition(tp);
        //already update tokenBalances in _transferOut
        if (f.LPOutAfterFee.add(tp.payInsurance) > 0) {
            _transferOut(
                LPToken,
                f.LPOutAfterFee.add(tp.payInsurance),
                f.receiver
            );
        }
        position.insurance = position
            .insurance
            .mul(BASIS_POINTS_DIVISOR.sub(f.insuranceProportion))
            .div(BASIS_POINTS_DIVISOR);
        return f.LPOutAfterFee.add(tp.payInsurance);
    }

    function liquidatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        address _feeReceiver,
        uint256 _insuranceLevel
    ) external nonReentrant {
        if (inPrivateLiquidationMode) {
            require(isLiquidator[msg.sender], "not liquidator");
        }

        bytes32 key = getPositionKey(
            _account,
            _indexToken,
            _isLong,
            _insuranceLevel
        );
        Position memory position = positions[key];
        require(position.size > 0, "Vault: size 0");
        (
            uint256 liquidationState,
            uint256 marginFeesLP,
            uint256 profitLP
        ) = validateLiquidation(
                _account,
                _indexToken,
                _isLong,
                false,
                _insuranceLevel
            );
        // state 0 normal;
        // 1 fee over collateral or collateral<loss,need liquidate;
        // 2 only decrease position
        require(liquidationState != 0, "Vault: state 0");
        if (liquidationState == 2) {
            DecreasePositionParams memory param = DecreasePositionParams(
                _account,
                _indexToken,
                position.size,
                0,
                _isLong,
                _account,
                _insuranceLevel,
                0
            );
            _decreasePosition(param);
            return;
        }

        feeReserves[LPToken] = feeReserves[LPToken].add(marginFeesLP);

        uint256 markPrice = _isLong
            ? getMinPrice(_indexToken)
            : getMaxPrice(_indexToken);

        vaultUtil.updateGlobal(
            _indexToken,
            markPrice,
            position.size,
            _isLong,
            false,
            position.insurance
        );

        //pay insurance
        uint256 payInsurance;
        if (position.insurance > 0) {
            uint256 maxPayAmount = position.insurance.mul(insuranceOdds).div(
                BASIS_POINTS_DIVISOR
            );
            payInsurance = profitLP > maxPayAmount ? maxPayAmount : profitLP;
            ILPToken(LPToken).mintTo(address(this), payInsurance);
            uint256 insuranceFee = payInsurance.mul(insuranceFeeRate).div(
                BASIS_POINTS_DIVISOR
            );
            splitInsurance(insuranceFee);
            payInsurance = payInsurance.sub(insuranceFee);
            IERC20(LPToken).safeTransfer(_account, payInsurance);
        }

        emit LiquidatePosition(
            _account,
            _indexToken,
            _isLong,
            position.size,
            position.collateral,
            position.realisedPnl,
            markPrice,
            _insuranceLevel,
            marginFeesLP + liquidationFee,
            payInsurance
        );

        delete positions[key];
        if (position.collateral > (marginFeesLP + liquidationFee)) {
            ILPToken(LPToken).burn(
                address(this),
                position.collateral.sub(marginFeesLP).sub(liquidationFee)
            );
        }
        _transferOut(LPToken, liquidationFee, _feeReceiver);

        splitLP(_account, marginFeesLP);
    }

    function splitLP(address user, uint256 amount) private {
        if (amount == 0) {
            return;
        }
        //to referral
        address referral = IRouter(router).referral();
        (address parent, ) = IReferral(referral).getUserParentInfo(user);
        (uint256 rate, ) = IReferral(referral).getTradeFeeRewardRate(user);
        uint256 userRewardAmount = amount.mul(rate).div(BASIS_POINTS_DIVISOR);
        uint256 parentRewardAmount = userRewardAmount;

        uint256 toTeamAmount = amount.mul(toTeamRatio).div(
            BASIS_POINTS_DIVISOR
        );
        uint256 left = amount.sub(toTeamAmount);
        toTeamAmount = toTeamAmount.sub(userRewardAmount).sub(
            parentRewardAmount
        );
        if(userRewardAmount.add(parentRewardAmount) > 0){
            IReferral(referral).updateLPClaimReward(
                user,
                parent,
                userRewardAmount,
                parentRewardAmount
            );
            IERC20(LPToken).safeTransfer(
                referral,
                userRewardAmount.add(parentRewardAmount)
            );
        }
        IERC20(LPToken).safeTransfer(teamAddress, toTeamAmount);

        IERC20(LPToken).safeTransfer(earnAddress, left);
    }

    function splitInsurance(uint256 amount) private {
        if (amount == 0) {
            return;
        }
        uint256 toTeamAmount = amount.mul(toTeamRatio).div(
            BASIS_POINTS_DIVISOR
        );
        uint256 left = amount.sub(toTeamAmount);
        IERC20(LPToken).safeTransfer(teamAddress, toTeamAmount);
        IERC20(LPToken).safeTransfer(earnAddress, left);
    }

    function getMaxPrice(address _token) public view returns (uint256) {
        if (_token == LPToken) {
            return vaultUtil.getLPPrice();
        }
        return IVaultPriceFeed(priceFeed).getPrice(_token, true);
    }

    function getMinPrice(address _token) public view returns (uint256) {
        if (_token == LPToken) {
            return vaultUtil.getLPPrice();
        }
        return IVaultPriceFeed(priceFeed).getPrice(_token, false);
    }

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _insuranceLevel
    )
        public
        view
        returns (uint256, uint256, uint256, uint256, bool, uint256, uint256)
    {
        bytes32 key = getPositionKey(
            _account,
            _indexToken,
            _isLong,
            _insuranceLevel
        );
        Position memory position = positions[key];
        uint256 realisedPnl = position.realisedPnl > 0
            ? uint256(position.realisedPnl)
            : uint256(-position.realisedPnl);
        return (
            position.size, // 0
            position.collateral, // 1
            position.averagePrice, // 2
            realisedPnl, // 3
            position.realisedPnl >= 0, // 4
            position.lastIncreasedTime, // 5
            position.insurance //6
        );
    }

    function getPositions(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _insuranceLevel
    ) public view returns (Position memory) {
        bytes32 key = getPositionKey(
            _account,
            _indexToken,
            _isLong,
            _insuranceLevel
        );

        return positions[key];
    }

    function getPositionsOfKey(
        bytes32 key
    ) public view returns (Position memory) {
        return positions[key];
    }

    function getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _insuranceLevel
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _account,
                    _indexToken,
                    _isLong,
                    _insuranceLevel
                )
            );
    }

    function getPositionLeverage(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _insuranceLevel
    ) public view returns (uint256) {
        bytes32 key = getPositionKey(
            _account,
            _indexToken,
            _isLong,
            _insuranceLevel
        );
        Position memory position = positions[key];
        require(position.collateral > 0, "Vault: collateral 0");
        return position.size.mul(BASIS_POINTS_DIVISOR).div(position.collateral);
    }

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        uint256 _nextPrice, //index token price current
        uint256 _sizeDelta
    ) public view returns (uint256) {
        require(
            whitelistedTokens[_indexToken],
            "Vault: getNextAveragePrice index token not white listed"
        );
        if (_size == 0) {
            return _nextPrice;
        }

        uint256 pricePrecision = 10 ** PRICE_DECIMALS;
        uint256 sum = _size.mul(pricePrecision).div(_averagePrice).add(
            _sizeDelta.mul(pricePrecision).div(_nextPrice)
        );
        return _size.add(_sizeDelta).mul(pricePrecision).div(sum);
    }

    function getProfitLP(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) public view returns (bool, uint256) {
        if (_averagePrice == 0 || _size == 0) {
            return (false, 0);
        }

        uint256 price = _isLong
            ? getMinPrice(_indexToken)
            : getMaxPrice(_indexToken);
        uint256 priceDelta = _averagePrice > price
            ? _averagePrice.sub(price)
            : price.sub(_averagePrice);
        uint256 profit = _size.mul(priceDelta).div(_averagePrice);
        bool hasProfit;

        if (_isLong) {
            hasProfit = price > _averagePrice;
        } else {
            hasProfit = _averagePrice > price;
        }

        uint256 minBps = block.timestamp > _lastIncreasedTime.add(minProfitTime)
            ? 0
            : minProfitBasisPoints[_indexToken];
        if (
            hasProfit && profit.mul(BASIS_POINTS_DIVISOR) <= _size.mul(minBps)
        ) {
            profit = 0;
        }
        return (hasProfit, profit);
    }

    function getPositionFee(uint256 _sizeDelta) public view returns (uint256) {
        if (_sizeDelta == 0) {
            return 0;
        }
        require(BASIS_POINTS_DIVISOR > 0, "BASIS_POINTS_DIVISOR 0");
        uint256 afterFee = _sizeDelta
            .mul(BASIS_POINTS_DIVISOR.sub(taxBasisPoints))
            .div(BASIS_POINTS_DIVISOR);
        return _sizeDelta.sub(afterFee);
    }

    function _reduceCollateral(
        address _account,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _insuranceLevel,
        uint256 _feeLP
    ) private returns (ReduceCollateralResult memory r) {
        bytes32 key = getPositionKey(
            _account,
            _indexToken,
            _isLong,
            _insuranceLevel
        );
        Position storage position = positions[key];
        //return fee base on LP token and update feeReserve
        uint256 fee = _collectMarginFees(_sizeDelta);
        if (_feeLP >= fee) {
            fee = 0;
        }
        r.feeLPAmount = _feeLP;

        bool hasProfit;
        uint256 adjustedDelta;

        {
            (bool _hasProfit, uint256 delta) = getProfitLP(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong,
                position.lastIncreasedTime
            );
            hasProfit = _hasProfit;
            require(position.size > 0, "Vault: size 0 _reduceCollateral");
            adjustedDelta = _sizeDelta.mul(delta).div(position.size);
        }
        r.profit = adjustedDelta;
        uint256 LPOut;

        if (position.size == _sizeDelta) {
            LPOut = LPOut.add(position.collateral);
            position.collateral = 0;
        } else {
            LPOut = LPOut.add(_collateralDelta);
            //position reduce collateral
            require(
                position.collateral >= _collateralDelta,
                "Vault: collateral<_collateralDelta"
            );
            position.collateral = position.collateral.sub(_collateralDelta);
        }

        if (hasProfit) {
            LPOut = LPOut.add(adjustedDelta);
            position.realisedPnl = position.realisedPnl + int256(adjustedDelta);
        } else {
            position.realisedPnl = position.realisedPnl - int256(adjustedDelta);
            if (LPOut > adjustedDelta) {
                LPOut = LPOut.sub(adjustedDelta);
            } else {
                position.collateral = position.collateral.sub(adjustedDelta);
            }
        }

        uint256 LPOutAfterFee = LPOut;
        if (LPOut > fee) {
            LPOutAfterFee = LPOut.sub(fee);
        } else {
            position.collateral = position.collateral.sub(fee);
        }

        emit UpdatePnl(key, hasProfit, adjustedDelta);
        r.hasProfit = hasProfit;

        r.LPOut = LPOut;
        r.LPOutAfterFee = LPOutAfterFee;
    }

    // return fee LP and update feeReserve
    function _collectMarginFees(uint256 _sizeDelta) private returns (uint256) {
        uint256 feeLP = getPositionFee(_sizeDelta);
        feeReserves[LPToken] = feeReserves[LPToken].add(feeLP);
        emit CollectMarginFees(feeLP);
        return feeLP;
    }

    function _transferIn(address _token) private returns (uint256) {
        uint256 prevBalance = tokenBalances[_token];
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBalances[_token] = nextBalance;

        return nextBalance.sub(prevBalance);
    }

    function _transferOut(
        address _token,
        uint256 _amount,
        address _receiver
    ) private {
        IERC20(_token).safeTransfer(_receiver, _amount);
        tokenBalances[_token] = IERC20(_token).balanceOf(address(this));
    }

    function _updateTokenBalance(address _token) private {
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBalances[_token] = nextBalance;
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _onlyGov() private view {
        require(msg.sender == gov, "not gov");
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validateGasPrice() private view {
        if (maxGasPrice == 0) {
            return;
        }
        require(tx.gasprice <= maxGasPrice, "Vault: maxGasPrice exceeded");
    }

    //state 0 normal;
    // 1 fee over collateral or collateral<loss;
    // 2 over max leverage,need decrease position
    function validateLiquidation(
        address _account,
        address _indexToken,
        bool _isLong,
        bool _raise,
        uint256 _insuranceLevel
    ) public view returns (uint256, uint256, uint256) {
        bytes32 key = getPositionKey(
            _account,
            _indexToken,
            _isLong,
            _insuranceLevel
        );
        Position memory position = positions[key];
        require(position.size > 0, "Vault: key not exist");

        (bool hasProfit, uint256 profitLP) = getProfitLP(
            _indexToken,
            position.size,
            position.averagePrice,
            _isLong,
            position.lastIncreasedTime
        );

        uint256 marginFees = getPositionFee(position.size);
        if (!hasProfit && position.collateral < profitLP) {
            if (_raise) {
                revert("Vault: losses exceed collateral");
            }
            return (1, marginFees, profitLP);
        }

        uint256 remainingCollateral = position.collateral;

        if (!hasProfit) {
            remainingCollateral = position.collateral.sub(profitLP);
        }

        if (remainingCollateral < marginFees) {
            if (_raise) {
                revert("Vault: marginFees exceed collateral");
            }
            // cap the fees to the remainingCollateral
            return (1, remainingCollateral, profitLP);
        }

        if (remainingCollateral < marginFees.add(liquidationFee)) {
            if (_raise) {
                revert("Vault: liquidation fees exceed collateral");
            }
            return (1, marginFees, profitLP);
        }

        //remainingCollateral*maxLiquidateLeverage<=position.size
        if (
            remainingCollateral.mul(maxLiquidateLeverage) <=
            position.size.mul(BASIS_POINTS_DIVISOR)
        ) {
            if (_raise) {
                revert("Vault: maxLeverage exceeded");
            }
            return (2, marginFees, profitLP);
        }

        return (0, marginFees, profitLP);
    }

    function allWhitelistedTokensLength() external view returns (uint256) {
        return allWhitelistedTokens.length;
    }

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external {
        _onlyGov();
        inPrivateLiquidationMode = _inPrivateLiquidationMode;
    }

    function setLiquidator(address _liquidator, bool _isActive) external {
        _onlyGov();
        isLiquidator[_liquidator] = _isActive;
    }

    function setMaxGasPrice(uint256 _maxGasPrice) external {
        _onlyGov();
        maxGasPrice = _maxGasPrice;
    }

    function setGov(address _gov) external {
        _onlyGov();
        gov = _gov;
    }

    function setRouterOrderbook(address _router, address _orderbook) external {
        _onlyGov();
        router = _router;
        orderbook = _orderbook;
    }

    function setPriceFeed(address _priceFeed) external {
        _onlyGov();
        priceFeed = _priceFeed;
    }

    function setMaxLeverage(uint256 _maxLeverage) external {
        _onlyGov();
        require(_maxLeverage > MIN_LEVERAGE, "less than min Leverage");
        maxLeverage = _maxLeverage;
    }

    function setMaxLiquidateLeverage(uint256 _maxLiquidateLeverage) external {
        _onlyGov();
        require(_maxLiquidateLeverage > MIN_LEVERAGE, "less than min Leverage");
        maxLiquidateLeverage = _maxLiquidateLeverage;
    }

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _liquidationFeeRate,
        uint256 _minProfitTime,
        uint256 _liquidationFee
    ) external {
        _onlyGov();
        require(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, "tax fee");
        taxBasisPoints = _taxBasisPoints;
        liquidationFeeRate = _liquidationFeeRate;
        minProfitTime = _minProfitTime;
        liquidationFee = _liquidationFee;
    }

    //set for every token
    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps
    ) external {
        _onlyGov();
        // increment token count for the first time
        if (!whitelistedTokens[_token]) {
            allWhitelistedTokens.push(_token);
        }

        whitelistedTokens[_token] = true;
        tokenDecimals[_token] = _tokenDecimals;
        minProfitBasisPoints[_token] = _minProfitBps;
        // validate price feed
        getMaxPrice(_token);
    }

    function setInsuranceLevel(
        uint256[] calldata _type,
        uint256[] calldata _rate
    ) external {
        _onlyGov();
        require(_type.length == _rate.length, "Vault: len not equal");
        for (uint256 i; i < _type.length; i++) {
            insuranceLevel[_type[i]] = _rate[i];
        }
    }

    function clearTokenConfig(address _token) external {
        _onlyGov();

        require(whitelistedTokens[_token], "white listed");
        delete whitelistedTokens[_token];
        delete tokenDecimals[_token];
        delete minProfitBasisPoints[_token];
    }

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256) {
        _onlyGov();
        uint256 amount = feeReserves[_token];
        if (amount == 0) {
            return 0;
        }
        feeReserves[_token] = 0;
        _transferOut(_token, amount, _receiver);
        return amount;
    }

    // the governance controlling this function should have a timelock
    function migrateVault(
        address _newVault,
        address _token,
        uint256 _amount
    ) external {
        _onlyGov();
        IERC20(_token).safeTransfer(_newVault, _amount);
    }

    function setDecimal(uint256 LPDecimal, uint256 usdcDecimal) external {
        _onlyGov();
        LP_DECIMALS = LPDecimal;
        USDC_DECIMALS = usdcDecimal;
    }

    function setMinCollateral(uint256 _minCollateral) external {
        _onlyGov();
        minCollateral = _minCollateral;
    }

    function subFeeReserves(uint256 _subAmount, address _token) external {
        _onlyGov();
        feeReserves[_token] = feeReserves[_token].sub(_subAmount);
    }

    function setSplitFeeParams(
        address _teamAddress,
        address _earnAddress,
        uint256 _toTeamRatio
    ) external {
        _onlyGov();
        teamAddress = _teamAddress;
        earnAddress = _earnAddress;
        toTeamRatio = _toTeamRatio;
    }

    function setLPToken(
        address _LPToken,
        address _FeeLP,
        address _usdc,
        IVaultUtil _vaultUtil
    ) external {
        _onlyGov();
        LPToken = _LPToken;
        FeeLP = _FeeLP;
        usdcToken = _usdc;
        vaultUtil = _vaultUtil;
    }

    function setInsurance(
        uint256 _insuranceOdds,
        uint256 _insuranceFeeRate
    ) external {
        _onlyGov();
        insuranceOdds = _insuranceOdds;
        insuranceFeeRate = _insuranceFeeRate;
    }

    function setLPFlag(bool _LPFlag) external {
        _onlyGov();
        LPFlag = _LPFlag;
    }

    function adjustForDecimals(
        uint256 _amount,
        address _tokenFrom,
        address _tokenTo
    ) public view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        uint256 decimalsDiv;
        uint256 decimalsMul;
        if (_tokenFrom == LPToken) {
            decimalsDiv = LP_DECIMALS;
        } else if (_tokenFrom == usdcToken) {
            decimalsDiv = USDC_DECIMALS;
        } else {
            decimalsDiv = tokenDecimals[_tokenFrom];
        }

        if (_tokenTo == LPToken) {
            decimalsMul = LP_DECIMALS;
        } else if (_tokenTo == usdcToken) {
            decimalsMul = USDC_DECIMALS;
        } else {
            decimalsMul = tokenDecimals[_tokenTo];
        }
        return _amount.mul(10 ** decimalsMul).div(10 ** decimalsDiv);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IReferral {
    function codeOwners(bytes32 _code) external view returns (address);

    function ownerCode(address user) external view returns (bytes32);

    function getTraderReferralInfo(
        address _account
    ) external view returns (bytes32, address);

    function setTraderReferralCode(address _account, bytes32 _code) external;

    function getUserParentInfo(
        address owner
    ) external view returns (address parent, uint256 level);

    function getTradeFeeRewardRate(
        address user
    ) external view returns (uint myTransactionReward, uint myReferralReward);

    function govSetCodeOwner(bytes32 _code, address _newAccount) external;

    function updateLPClaimReward(
        address _owner,
        address _parent,
        uint256 _ownerReward,
        uint256 _parentReward
    ) external;

    function updateESLionClaimReward(
        address _owner,
        address _parent,
        uint256 _ownerReward,
        uint256 _parentReward
    ) external;
}