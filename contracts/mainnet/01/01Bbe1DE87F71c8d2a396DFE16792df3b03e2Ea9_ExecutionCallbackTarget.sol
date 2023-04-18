// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import {IPositionRouterCallbackReceiver} from "./interfaces/IPositionRouterCallbackReceiver.sol";
import {IRouter} from "./interfaces/IRouter.sol";
    

contract ExecutionCallbackTarget is IPositionRouterCallbackReceiver {
    enum PositionExecutionStatus { NONE, PARTIAL}

    address public immutable router;
    address public immutable positionRouter;

    PositionExecutionStatus public status;

    event GmxPositionCallback(address keeper, bytes32 requestKey, bool isExecuted, bool isIncrease);

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
        if(_isExecuted) {
            _successCallback(_isIncrease, _requestKey);
        } else {
            _failFallback(_isIncrease);
        }

        emit GmxPositionCallback(msg.sender, _requestKey, _isExecuted, _isIncrease);
    }

    function getRequestKey(address _account, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }

    function _successCallback(bool _isIncrease, bytes32 _requestKey) internal {
        if (status == PositionExecutionStatus.NONE) {
            status = PositionExecutionStatus.PARTIAL;
            IRouter(router).firstCallback(_isIncrease, _requestKey);
        } else if (status == PositionExecutionStatus.PARTIAL) {
            status = PositionExecutionStatus.NONE;
            IRouter(router).secondCallback(_isIncrease, _requestKey);
        }
    }

    function _failFallback(bool _isIncrease) internal {
        if (status == PositionExecutionStatus.PARTIAL) {
            status = PositionExecutionStatus.NONE;
        }
        IRouter(router).failCallback(_isIncrease);
    }

    function _onlyPositionRouter() internal {
        require(msg.sender == positionRouter, "invalid positionRouter");
    }
}

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