// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IPositionRouterCallbackReceiver {
    function isContract() external view returns(bool);
    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IRouter {
    function executePositionsBeforeDealGlp(
        uint256 _amount,
        bytes[] calldata _params,
        bool _isWithdraw
    ) external payable;

    function confirmAndBuy(uint256 _wantAmount, address _recipient) external returns (uint256);

    function confirmAndSell(uint256 _glpAmount, address _recipient) external returns (uint256);

    function firstCallback(bool _isIncrease, bytes32 _requestKey) external;

    function secondCallback(bool _isIncrease, bytes32 _requestKey) external;

    function failCallback(bool _isIncrease) external;

    function getDepositParams(uint256 _amount) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IStrategyVault {
    function totalAssets() external view returns (uint256);

    function feeReserves() external view returns (uint256);

    function handleBuy(uint256 _amount) external payable returns (uint256);

    function handleSell(uint256 _amount, address _recipient) external payable;

    function harvest() external;

    function confirm() external;

    function confirmCallback() external;

    function totalValue() external view returns (uint256);

    function executePositions(bytes4[] calldata _selectors, bytes[] calldata _params) external payable;

    function confirmAndDealGlp(bytes4 _selector, bytes calldata _param) external;

    function executeDecreasePositions(bytes[] calldata _params) external payable;

    function executeIncreasePositions(bytes[] calldata _params) external payable;

    function buyNeuGlp(uint256 _amountIn) external returns (uint256);

    function sellNeuGlp(uint256 _glpAmount, address _recipient) external returns (uint256);

    function settle(uint256 _amount, address _recipient) external;
    
    function exited() external view returns(bool);

    function usdToTokenMax(address _token, uint256 _usdAmount, bool _isCeil) external returns (uint256);

    function decreaseShortPositionsWithCallback(
        uint256 _wbtcCollateralDelta,
        uint256 _wbtcSizeDelta,
        uint256 _wethCollateralDelta,
        uint256 _wethSizeDelta,
        bool _shouldRepayWbtc,
        bool _shouldRepayWeth,
        address _recipient,
        address _callbackTarget
    ) external payable returns(bytes32, bytes32);

    function increaseShortPositionsWithCallback(
        uint256 _wbtcAmountIn,
        uint256 _wbtcSizeDelta,
        uint256 _wethAmountIn,
        uint256 _wethSizeDelta,
        address _callbackTarget
    ) external payable returns (bytes32, bytes32);

    function instantRepayFundingFee(address _indexToken, address _callbackTarget) external payable;

    function buyGlp(uint256 _amount) external returns (uint256);

    function sellGlp(uint256 _amount, address _recipient) external returns (uint256);

    function transferFailedAmount(uint256 _wantAmount, uint256 _glpAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import {IPositionRouterCallbackReceiver} from "./interfaces/IPositionRouterCallbackReceiver.sol";
import {IStrategyVault} from "./interfaces/IStrategyVault.sol";
import {IRouter} from "./interfaces/IRouter.sol";    

contract RepayCallbackTarget is IPositionRouterCallbackReceiver {
    address public immutable router;
    address public immutable positionRouter;

    event GmxPositionCallback(address keeper, bytes32 positionKey, bool isExecuted, bool isIncrease);

    modifier onlyPositionRouter() {
        _onlyPositionRouter();
        _;
    }

    constructor(address _router, address _positionRouter) {
        router = _router;
        positionRouter = _positionRouter;
    }

    function isContract() external pure returns (bool) {
        return true;
    }

    function gmxPositionCallback(bytes32 _requestKey, bool _isExecuted, bool _isIncrease) external onlyPositionRouter {
        if(!_isExecuted) {
            _failFallback(_isIncrease);
        }

        emit GmxPositionCallback(msg.sender, _requestKey, _isExecuted, _isIncrease);
    }

    function _failFallback(bool _isIncrease) internal {
        IRouter(router).failCallback(_isIncrease);
    }

    function getRequestKey(address _account, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }

    function _onlyPositionRouter() internal {
        require(msg.sender == positionRouter, "invalid positionRouter");
    }
}