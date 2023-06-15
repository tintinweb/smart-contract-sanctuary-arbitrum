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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../library/math/SafeMath.sol";
import "../library/token/ERC20/IERC20.sol";
import "../library/token/ERC20/utils/SafeERC20.sol";
import "../library/utils/Address.sol";
import "../library/utils/ReentrancyGuard.sol";
import "./interfaces/IFeeLP.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IRouter.sol";
import "../referrals/interfaces/IReferral.sol";

contract Router is IRouter, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    struct IncreasePositionRequest {
        address account;
        address inToken;
        address indexToken;
        uint256 collateralDelta;
        uint256 amountIn;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 insuranceLevel;
        uint256 executionFee;
        uint256 feeLPAmount;
        uint256 blockTime;
    }
    struct DecreasePositionRequest {
        address account;
        address inToken;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 insuranceLevel;
        uint256 minOut;
        uint256 executionFee;
        uint256 feeLPAmount;
        uint256 blockTime;
    }

    address public gov;
    bool public isInitialized = false;
    // wrapped BNB / ETH
    address public weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public LP;
    address public FeeLP;
    address public vault;

    uint256 public minExecutionFee;

    uint256 public minTimeDelayKeeper;
    uint256 public minTimeDelayPublic;
    uint256 public maxTimeDelay;

    bytes32[] public increasePositionRequestKeys;
    bytes32[] public decreasePositionRequestKeys;

    uint256 public override increasePositionRequestKeysStart;
    uint256 public override decreasePositionRequestKeysStart;

    mapping(address => bool) public isPositionKeeper;

    mapping(address => uint256) public increasePositionsIndex;
    mapping(bytes32 => IncreasePositionRequest) public increasePositionRequests;

    mapping(address => uint256) public decreasePositionsIndex;
    mapping(bytes32 => DecreasePositionRequest) public decreasePositionRequests;

    address public referral;

    uint256[50] private _gap;
    // Event
    event Swap(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    event CreateIncreasePosition(
        address indexed account,
        address inToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 insuranceLevel,
        uint256 executionFee,
        uint256 index,
        uint256 feeLPAmount,
        uint256 blockTime
    );

    event ExecuteIncreasePosition(
        address indexed account,
        address inToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 amountIn,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 insuranceLevel,
        uint256 executionFee,
        uint256 timeGap
    );

    event CancelIncreasePosition(
        address indexed account,
        address inToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 amountIn,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 insuranceLevel,
        uint256 executionFee,
        uint256 timeGap,
        uint256 feeLPAmount
    );

    event CreateDecreasePosition(
        address indexed account,
        address inToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 insuranceLevel,
        uint256 minOut,
        uint256 executionFee,
        uint256 index,
        uint256 feeLPAmount,
        uint256 blockTime
    );

    event ExecuteDecreasePosition(
        address indexed account,
        address inToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 insuranceLevel,
        uint256 minOut,
        uint256 executionFee,
        uint256 timeGap
    );

    event CancelDecreasePosition(
        address indexed account,
        address inToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 insuranceLevel,
        uint256 minOut,
        uint256 executionFee,
        uint256 timeGap,
        uint256 feeLPAmount
    );

    event SetPositionKeeper(address indexed account, bool isActive);
    event SetMinExecutionFee(uint256 minExecutionFee);
    event SetDelayValues(
        uint256 minTimeDelayKeeper,
        uint256 minTimeDelayPublic,
        uint256 maxTimeDelay
    );
    event SetRequestKeysStartValues(
        uint256 increasePositionRequestKeysStart,
        uint256 decreasePositionRequestKeysStart
    );

    modifier onlyGov() {
        require(msg.sender == gov, "Router: forbidden");
        _;
    }
    modifier onlyPositionKeeper() {
        require(isPositionKeeper[msg.sender], "403");
        _;
    }
    event Initialize(
        address _vault,
        address _LP,
        address _weth,
        uint256 _minExecutionFee
    );

    function initialize(
        address _vault,
        address _LP,
        address _weth,
        address _FeeLP,
        address _referral,
        uint256 _minExecutionFee,
        uint256 _minTimeDelayKeeper,
        uint256 _minTimeDelayPublic,
        uint256 _maxTimeDelay
    ) external {
        require(!isInitialized, "Router: already initialized");
        isInitialized = true;
        gov = msg.sender;

        vault = _vault;
        LP = _LP;
        weth = _weth;
        FeeLP = _FeeLP;
        referral= _referral;
        minExecutionFee = _minExecutionFee;

        minTimeDelayKeeper = _minTimeDelayKeeper;
        minTimeDelayPublic = _minTimeDelayPublic;
        maxTimeDelay = _maxTimeDelay;

        IERC20(LP).safeApprove(vault, type(uint256).max);

        emit Initialize(_vault, _LP, _weth, _minExecutionFee);
    }

    receive() external payable {
        require(msg.sender == weth, "Router: receive invalid sender");
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setPositionKeeper(address _addr, bool active) external onlyGov {
        isPositionKeeper[_addr] = active;
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;
        emit SetMinExecutionFee(_minExecutionFee);
    }

    function setRequestKeysStartValues(
        uint256 _increasePositionRequestKeysStart,
        uint256 _decreasePositionRequestKeysStart
    ) external onlyGov {
        increasePositionRequestKeysStart = _increasePositionRequestKeysStart;
        decreasePositionRequestKeysStart = _decreasePositionRequestKeysStart;

        emit SetRequestKeysStartValues(
            _increasePositionRequestKeysStart,
            _decreasePositionRequestKeysStart
        );
    }

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
    ) external payable nonReentrant returns (bytes32) {
        require(_executionFee >= minExecutionFee, "fee");
        require(msg.value == _executionFee, "val");

        _transferInETH();
        _setTraderReferralCode(_referralCode);

        IncreasePositionRequest memory p = IncreasePositionRequest(
            msg.sender,
            _inToken,
            _indexToken,
            _collateralDelta,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _insuranceLevel,
            _executionFee,
            0,
            block.timestamp
        );

        {
            //transfer in here first
            //if _sizeDelta is 0,no fee,no insurance
            if (p.sizeDelta > 0) {
                require(
                    p.sizeDelta <=
                        _collateralDelta.mul(IVault(vault).maxLeverage()).div(
                            2*IVault(vault).BASIS_POINTS_DIVISOR()
                        ),
                    "Router: leverage invalid"
                );
                //add insurance
                p.amountIn = p.amountIn.add(
                    p
                        .amountIn
                        .mul(IVault(vault).insuranceLevel(_insuranceLevel))
                        .div(IVault(vault).BASIS_POINTS_DIVISOR())
                );
                //add fee
                {
                    uint256 fee = IVault(vault).getPositionFee(_sizeDelta);
                    if (IFeeLP(FeeLP).balanceOf(msg.sender) >= fee) {
                        IFeeLP(FeeLP).lock(
                            msg.sender,
                            address(this),
                            fee,
                            true
                        );
                        p.feeLPAmount = fee;
                    } else {
                        p.amountIn = p.amountIn.add(fee);
                    }
                }
            }
            IERC20(_inToken).safeTransferFrom(
                msg.sender,
                address(this),
                p.amountIn
            );
        }

        return _createIncreasePosition(p);
    }

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
    ) external payable nonReentrant returns (bytes32) {
        require(_executionFee >= minExecutionFee, "fee");
        require(
            msg.value == _executionFee,
            "Router: insufficient execution fee"
        );

        uint256 feeLPAmount;
        if (_sizeDelta > 0) {
            require(
                _collateralDelta > 0,
                "Router: sizeDelta not zero, collateralDelta zero"
            );
            uint256 fee = IVault(vault).getPositionFee(_sizeDelta);
            if (IFeeLP(FeeLP).balanceOf(msg.sender) >= fee) {
                IFeeLP(FeeLP).lock(msg.sender, address(this), fee, false);
                feeLPAmount = fee;
            }
        }
        _transferInETH();
        return
            _createDecreasePosition(
                msg.sender,
                _inToken,
                _indexToken,
                _collateralDelta,
                _sizeDelta,
                _isLong,
                _acceptablePrice,
                _insuranceLevel,
                _minOut,
                _executionFee,
                feeLPAmount
            );
    }

    function _createDecreasePosition(
        address _account,
        address _inToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _insuranceLevel,
        uint256 _minOut,
        uint256 _executionFee,
        uint256 _feeLPAmount
    ) internal returns (bytes32) {
        DecreasePositionRequest memory request = DecreasePositionRequest(
            _account,
            _inToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _insuranceLevel,
            _minOut,
            _executionFee,
            _feeLPAmount,
            block.timestamp
        );
        {
            (uint256 index, bytes32 requestKey) = _storeDecreasePositionRequest(
                request
            );
            emit CreateDecreasePosition(
                request.account,
                request.inToken,
                request.indexToken,
                request.collateralDelta,
                request.sizeDelta,
                request.isLong,
                request.acceptablePrice,
                request.insuranceLevel,
                request.minOut,
                request.executionFee,
                index,
                request.feeLPAmount,
                block.timestamp
            );
            return requestKey;
        }
    }

    function _createIncreasePosition(
        IncreasePositionRequest memory p
    ) internal returns (bytes32 requestKey) {
        {
            uint256 index;
            (index, requestKey) = _storeIncreasePositionRequest(p);

            emit CreateIncreasePosition(
                p.account,
                p.inToken,
                p.indexToken,
                p.collateralDelta,
                p.sizeDelta,
                p.isLong,
                p.acceptablePrice,
                p.insuranceLevel,
                p.executionFee,
                index,
                p.feeLPAmount,
                block.timestamp
            );
        }
    }

    function _storeIncreasePositionRequest(
        IncreasePositionRequest memory _request
    ) internal returns (uint256, bytes32) {
        address account = _request.account;
        uint256 index = increasePositionsIndex[account].add(1);
        increasePositionsIndex[account] = index;
        bytes32 key = getRequestKey(account, index);

        increasePositionRequests[key] = _request;
        increasePositionRequestKeys.push(key);

        return (index, key);
    }

    function _storeDecreasePositionRequest(
        DecreasePositionRequest memory _request
    ) internal returns (uint256, bytes32) {
        address account = _request.account;
        uint256 index = decreasePositionsIndex[account].add(1);
        decreasePositionsIndex[account] = index;
        bytes32 key = getRequestKey(account, index);

        decreasePositionRequests[key] = _request;
        decreasePositionRequestKeys.push(key);

        return (index, key);
    }

    function executeIncreasePositions(
        uint256 _endIndex,
        address payable _executionFeeReceiver
    ) external override onlyPositionKeeper {
        uint256 index = increasePositionRequestKeysStart;
        uint256 length = increasePositionRequestKeys.length;

        if (index >= length) {
            return;
        }

        if (_endIndex > length) {
            _endIndex = length;
        }

        while (index < _endIndex) {
            bytes32 key = increasePositionRequestKeys[index];
            // bool suc = this.executeIncreasePosition(key, _executionFeeReceiver);
            // require(suc, "executeIncreasePosition");
            try
                this.executeIncreasePosition(key, _executionFeeReceiver)
            returns (bool _wasExecuted) {
                if (!_wasExecuted) {
                    break;
                }
            } catch {
                try
                    this.cancelIncreasePosition(key, _executionFeeReceiver)
                returns (bool _wasCancelled) {
                    if (!_wasCancelled) {
                        break;
                    }
                } catch {}
            }

            delete increasePositionRequestKeys[index];
            index++;
        }

        increasePositionRequestKeysStart = index;
    }

    function executeDecreasePositions(
        uint256 _endIndex,
        address payable _executionFeeReceiver
    ) external override onlyPositionKeeper {
        uint256 index = decreasePositionRequestKeysStart;
        uint256 length = decreasePositionRequestKeys.length;

        if (index >= length) {
            return;
        }

        if (_endIndex > length) {
            _endIndex = length;
        }

        while (index < _endIndex) {
            bytes32 key = decreasePositionRequestKeys[index];
            // bool suc = this.executeDecreasePosition(key, _executionFeeReceiver);
            // require(suc, "executeDecreasePosition fail");
            try
                this.executeDecreasePosition(key, _executionFeeReceiver)
            returns (bool _wasExecuted) {
                if (!_wasExecuted) {
                    break;
                }
            } catch {
                try
                    this.cancelDecreasePosition(key, _executionFeeReceiver)
                returns (bool _wasCancelled) {
                    if (!_wasCancelled) {
                        break;
                    }
                } catch {}
            }

            delete decreasePositionRequestKeys[index];
            index++;
        }

        decreasePositionRequestKeysStart = index;
    }

    function executeIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) public nonReentrant returns (bool) {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        if (request.account == address(0)) {
            return true;
        }

        bool shouldExecute = _validateExecution(
            request.blockTime,
            request.account
        );
        if (!shouldExecute) {
            return false;
        }

        if (
            request.sizeDelta > 0 &&
            request.feeLPAmount >=
            IVault(vault).getPositionFee(request.sizeDelta)
        ) {
            IFeeLP(FeeLP).burnLocked(
                request.account,
                address(this),
                request.feeLPAmount,
                true
            );
        }

        if (request.amountIn > 0) {
            IERC20(request.inToken).safeTransfer(vault, request.amountIn);
        }
        delete increasePositionRequests[_key];
        IVault(vault).increasePosition(
            request.account,
            request.indexToken,
            request.sizeDelta,
            request.collateralDelta,
            request.isLong,
            request.insuranceLevel,
            request.feeLPAmount
        );

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        emit ExecuteIncreasePosition(
            request.account,
            request.inToken,
            request.indexToken,
            request.collateralDelta,
            request.amountIn,
            request.sizeDelta,
            request.isLong,
            request.acceptablePrice,
            request.insuranceLevel,
            request.executionFee,
            block.timestamp.sub(request.blockTime)
        );
        return true;
    }

    function executeDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) public nonReentrant returns (bool) {
        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        if (request.account == address(0)) {
            return true;
        }

        bool shouldExecute = _validateExecution(
            request.blockTime,
            request.account
        );
        if (!shouldExecute) {
            return false;
        }

        if (
            request.sizeDelta > 0 &&
            request.feeLPAmount >=
            IVault(vault).getPositionFee(request.sizeDelta)
        ) {
            IFeeLP(FeeLP).burnLocked(
                request.account,
                address(this),
                request.feeLPAmount,
                false
            );
        }

        delete decreasePositionRequests[_key];
        (, uint256 outLp) = IVault(vault).decreasePosition(
            request.account,
            request.indexToken,
            request.sizeDelta,
            request.collateralDelta,
            request.isLong,
            request.account, //request.receiver,
            request.insuranceLevel,
            request.feeLPAmount
        );
        require(outLp >= request.minOut, "Router: min out");

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        emit ExecuteDecreasePosition(
            request.account,
            request.inToken,
            request.indexToken,
            request.collateralDelta,
            request.sizeDelta,
            request.isLong,
            request.acceptablePrice,
            request.insuranceLevel,
            request.minOut,
            request.executionFee,
            block.timestamp.sub(request.blockTime)
        );

        return true;
    }

    function cancelIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) public nonReentrant returns (bool) {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        if (request.account == address(0)) {
            return true;
        }

        bool shouldCancel = _validateCancellation(
            request.blockTime,
            request.account
        );
        if (!shouldCancel) {
            return false;
        }

        delete increasePositionRequests[_key];

        if (request.feeLPAmount > 0) {
            //request.sizeDelta > 0 &&
            IFeeLP(FeeLP).unlock(
                request.account,
                address(this),
                request.feeLPAmount,
                true
            );
        }
        IERC20(request.inToken).safeTransfer(request.account, request.amountIn);

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        emit CancelIncreasePosition(
            request.account,
            request.inToken,
            request.indexToken,
            request.collateralDelta,
            request.amountIn,
            request.sizeDelta,
            request.isLong,
            request.acceptablePrice,
            request.insuranceLevel,
            request.executionFee,
            block.timestamp.sub(request.blockTime),
            request.feeLPAmount
        );

        return true;
    }

    function cancelDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) public nonReentrant returns (bool) {
        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        if (request.account == address(0)) {
            return true;
        }

        bool shouldCancel = _validateCancellation(
            request.blockTime,
            request.account
        );
        if (!shouldCancel) {
            return false;
        }
        if (request.feeLPAmount > 0) {
            //request.sizeDelta > 0 &&
            IFeeLP(FeeLP).unlock(
                request.account,
                address(this),
                request.feeLPAmount,
                false
            );
        }
        delete decreasePositionRequests[_key];

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        emit CancelDecreasePosition(
            request.account,
            request.inToken,
            request.indexToken,
            request.collateralDelta,
            request.sizeDelta,
            request.isLong,
            request.acceptablePrice,
            request.insuranceLevel,
            request.minOut,
            request.executionFee,
            block.timestamp.sub(request.blockTime),
            request.feeLPAmount
        );

        return true;
    }

    function _setTraderReferralCode(bytes32 _referralCode) private {
        if (_referralCode != bytes32(0) && referral != address(0)) {
            IReferral(referral).setTraderReferralCode(
                msg.sender,
                _referralCode
            );
        }
    }

    function _sender() private view returns (address) {
        return msg.sender;
    }

    function _transferInETH() private {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }

    function _transferOutETH(
        uint256 _amountOut,
        address payable _receiver
    ) private {
        IWETH(weth).withdraw(_amountOut);
        _receiver.sendValue(_amountOut);
    }

    function _transferOutETHWithGasLimitIgnoreFail(
        uint256 _amountOut,
        address payable _receiver
    ) internal {
        IWETH(weth).withdraw(_amountOut);
        _receiver.send(_amountOut);
    }

    function setTokenVault(
        address _weth,
        address _LP,
        address _vault
    ) external onlyGov {
        weth = _weth;
        LP = _LP;
        vault = _vault;

        IERC20(LP).approve(vault, type(uint256).max);
    }

    function setDelayValues(
        uint256 _minTimeDelayKeeper,
        uint256 _minTimeDelayPublic,
        uint256 _maxTimeDelay
    ) external onlyGov {
        minTimeDelayKeeper = _minTimeDelayKeeper;
        minTimeDelayPublic = _minTimeDelayPublic;
        maxTimeDelay = _maxTimeDelay;
        emit SetDelayValues(
            _minTimeDelayKeeper,
            _minTimeDelayPublic,
            _maxTimeDelay
        );
    }

    function setReferral(address _referral) external onlyGov {
        referral = _referral;
    }

    function _validateExecution(
        uint256 _positionBlockTime,
        address _account
    ) internal view returns (bool) {
        require(
            _positionBlockTime.add(maxTimeDelay) >= block.timestamp,
            "Router: expired"
        );

        bool isKeeperCall = msg.sender == address(this) ||
            isPositionKeeper[msg.sender];

        if (isKeeperCall) {
            return
                _positionBlockTime.add(minTimeDelayKeeper) <= block.timestamp;
        } else {
            require(
                msg.sender == _account,
                "Router: _validateExecution invalid"
            );
        }

        require(
            _positionBlockTime.add(minTimeDelayPublic) <= block.timestamp,
            "Router: delay"
        );

        return true;
    }

    function _validateCancellation(
        uint256 _positionBlockTime,
        address _account
    ) internal view returns (bool) {
        bool isKeeperCall = msg.sender == address(this) ||
            isPositionKeeper[msg.sender];

        if (isKeeperCall) {
            return
                _positionBlockTime.add(minTimeDelayKeeper) <= block.timestamp;
        }

        require(
            msg.sender == _account,
            "Router: _validateCancellation invalid"
        );

        require(
            _positionBlockTime.add(minTimeDelayPublic) <= block.timestamp,
            "delay"
        );

        return true;
    }

    function getRequestQueueLengths()
        external
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (
            increasePositionRequestKeysStart,
            increasePositionRequestKeys.length,
            decreasePositionRequestKeysStart,
            decreasePositionRequestKeys.length
        );
    }

    function getRequestKey(
        address _account,
        uint256 _index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
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

pragma solidity ^0.8.17;

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
     * by making the `nonReentrant` function external, and make it call a
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