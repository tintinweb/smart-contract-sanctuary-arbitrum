// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOrderBook {
    function getSwapOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeSwapOrder(address, uint256, address payable) external;

    function executeDecreaseOrder(address, uint256, address payable) external;

    function executeIncreaseOrder(address, uint256, address payable) external;

    function createDecreaseOrderForUser(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function createIncreaseOrderForUser(
        address _account,
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPositionRouter {
    function increasePositionRequestKeysStart() external returns (uint256);

    function decreasePositionRequestKeysStart() external returns (uint256);

    function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

    function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

    function createIncreasePositionForUser(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        bool _wrap
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./interfaces/IPositionRouter.sol";
import "./interfaces/IOrderBook.sol";
import "../libraries/utils/ReentrancyGuard.sol";

/**
 * @title PositionCreator
 * @notice This contract is responsible for making complex sets of orders and positions in a single transaction.
 */

contract PositionCreator is ReentrancyGuard {
    address public orderBook;
    address public positionRouter;

    address public admin;
    address public pendingAdmin;

    uint8 public constant INCREASE_POSITION = 0;
    uint8 public constant INCREASE_ORDER = 1;
    uint8 public constant DECREASE_ORDER = 2;

    constructor(address _orderBook, address _positionRouter) public {
        admin = msg.sender;
        orderBook = _orderBook;
        positionRouter = _positionRouter;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "PositionCreator: forbidden");
        _;
    }

    function setOrderBook(address _orderBook) external onlyAdmin {
        orderBook = _orderBook;
    }

    function setPositionRouter(address _positionRouter) external onlyAdmin {
        positionRouter = _positionRouter;
    }

    function setPendingAdmin(address _pendingAdmin) external onlyAdmin {
        pendingAdmin = _pendingAdmin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "PositionCreator: forbidden");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function executeMultiple(
        uint8[] memory _actions,
        bytes[] memory _args,
        uint256[] memory _msgValues
    ) external payable nonReentrant {
        require(
            _actions.length == _args.length && _actions.length == _msgValues.length,
            "PositionCreator: invalid array lengths"
        );

        for (uint256 i = 0; i < _actions.length; i++) {
            if (_actions[i] == INCREASE_POSITION) {
                _createIncreasePosition(_args[i], _msgValues[i]);
            } else if (_actions[i] == INCREASE_ORDER) {
                _createIncreaseOrder(_args[i], _msgValues[i]);
            } else if (_actions[i] == DECREASE_ORDER) {
                _createDecreaseOrder(_args[i], _msgValues[i]);
            } else {
                revert("PositionCreator: invalid action");
            }
        }
    }

    function _createIncreasePosition(bytes memory _args, uint256 _msgValue) internal {
        (
            address[] memory _path,
            address _indexToken,
            uint256 _amountIn,
            uint256 _minOut,
            uint256 _sizeDelta,
            bool _isLong,
            uint256 _acceptablePrice,
            uint256 _executionFee,
            bytes32 _referralCode,
            bool _wrap
        ) = abi.decode(_args, (address[], address, uint256, uint256, uint256, bool, uint256, uint256, bytes32, bool));
        IPositionRouter(positionRouter).createIncreasePositionForUser{value: _msgValue}(
            msg.sender,
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            _referralCode,
            _wrap
        );
    }

    function _createIncreaseOrder(bytes memory _args, uint256 _msgValue) internal {
        (
            address[] memory _path,
            uint256 _amountIn,
            address _indexToken,
            uint256 _minOut,
            uint256 _sizeDelta,
            address _collateralToken,
            bool _isLong,
            uint256 _triggerPrice,
            bool _triggerAboveThreshold,
            uint256 _executionFee,
            bool _shouldWrap
        ) = abi.decode(
                _args,
                (address[], uint256, address, uint256, uint256, address, bool, uint256, bool, uint256, bool)
            );
        IOrderBook(orderBook).createIncreaseOrderForUser{value: _msgValue}(
            msg.sender,
            _path,
            _amountIn,
            _indexToken,
            _minOut,
            _sizeDelta,
            _collateralToken,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _shouldWrap
        );
    }

    function _createDecreaseOrder(bytes memory _args, uint256 _msgValue) internal {
        (
            address _indexToken,
            uint256 _sizeDelta,
            address _collateralToken,
            uint256 _collateralDelta,
            bool _isLong,
            uint256 _triggerPrice,
            bool _triggerAboveThreshold
        ) = abi.decode(_args, (address, uint256, address, uint256, bool, uint256, bool));
        IOrderBook(orderBook).createDecreaseOrderForUser{value: _msgValue}(
            msg.sender,
            _indexToken,
            _sizeDelta,
            _collateralToken,
            _collateralDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
contract ReentrancyGuard {
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

    constructor() internal {
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