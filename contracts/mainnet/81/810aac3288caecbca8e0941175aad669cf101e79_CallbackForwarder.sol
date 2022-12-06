//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import {IInsuredLongsStrategy} from "./interfaces/IInsuredLongsStrategy.sol";

import {Ownable} from "../../helpers/Ownable.sol";

contract CallbackForwarder is Ownable {
    struct CallbackParams {
        bytes32 key;
        bool isExecuted;
    }

    mapping(address => bool) public validCallbackCallers;
    mapping(uint256 => CallbackParams) public gmxPendingCallbacks;
    mapping(uint256 => uint256) public pendingIncreaseOrders;
    uint256 public gmxPendingCallbacksStartIndex;
    uint256 public gmxPendingCallbacksEndIndex;
    uint256 public pendingIncreaseOrdersStartIndex;
    uint256 public pendingIncreaseOrdersEndIndex;

    event ForwardGmxPositionCallback(bytes32 positionKey, bool isExecuted);
    event PendingCallbackCreated(bytes32 positionKey, bool isExecuted);
    event CreatedIncreaseOrder(uint256 _positionId);
    event ExecutedIncreaseOrder(uint256 _positionId);
    event CallbackCallerSet(address _caller, bool _set);

    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external {
        require(validCallbackCallers[msg.sender], "Forbidden");
        gmxPendingCallbacks[gmxPendingCallbacksEndIndex] = CallbackParams(
            positionKey,
            isExecuted
        );
        unchecked {
            ++gmxPendingCallbacksEndIndex;
        }

        emit PendingCallbackCreated(positionKey, isExecuted);
    }

    function createIncreaseOrder(uint256 _positionId) external {
        require(validCallbackCallers[msg.sender], "Forbidden");
        pendingIncreaseOrders[pendingIncreaseOrdersEndIndex] = _positionId;
        unchecked {
            ++pendingIncreaseOrdersEndIndex;
        }
        emit CreatedIncreaseOrder(_positionId);
    }

    function forwardGmxPositionCallback(
        address _strategy,
        uint256 _startIndex,
        uint256 _endIndex
    ) external {
        require(validCallbackCallers[msg.sender], "Forbidden");

        CallbackParams memory params;
        while (_startIndex != _endIndex) {
            params = gmxPendingCallbacks[_startIndex];
            try
                IInsuredLongsStrategy(_strategy).gmxPositionCallback(
                    params.key,
                    params.isExecuted,
                    true
                )
            {} catch {}
            unchecked {
                ++_startIndex;
            }
            emit ForwardGmxPositionCallback(params.key, params.isExecuted);
        }

        gmxPendingCallbacksStartIndex = _startIndex;
    }

    function executeIncreaseOrders(
        address _strategy,
        uint256 _startIndex,
        uint256 _endIndex
    ) external payable {
        require(validCallbackCallers[msg.sender], "Forbidden");

        uint256 orders = _endIndex - _startIndex;

        uint256 positionId;
        while (_startIndex != _endIndex) {
            positionId = pendingIncreaseOrders[_startIndex];
            try
                IInsuredLongsStrategy(_strategy)
                    .createIncreaseManagedPositionOrder{
                    value: msg.value / orders
                }(positionId)
            {} catch {}
            unchecked {
                ++_startIndex;
            }
            emit ExecutedIncreaseOrder(positionId);
        }

        pendingIncreaseOrdersStartIndex = _startIndex;
    }

    function setCallbackCaller(address _address, bool _set) external onlyOwner {
        validCallbackCallers[_address] = _set;
        emit CallbackCallerSet(_address, _set);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IInsuredLongsStrategy {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external payable;

    function positionsCount() external view returns (uint256);

    function getStrategyPosition(
        uint256 _positionId
    )
        external
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            address,
            bool,
            ActionState
        );

    function isManagedPositionDecreasable(
        uint256 _positionId
    ) external view returns (bool isDecreasable);

    function isManagedPositionLiquidatable(
        uint256 _positionId
    ) external view returns (bool isLiquidatable);

    function createExitStrategyOrder(
        uint256 _positionId,
        bool exitLongPosition
    ) external payable;

    function createIncreaseManagedPositionOrder(
        uint256 _positionId
    ) external payable;

    function emergencyStrategyExit(uint256 _positionId) external;

    event AtlanticPoolWhitelisted(
        address _poolAddress,
        address _quoteToken,
        address _indexToken,
        uint256 _expiry,
        uint256 _tickSizeMultiplier
    );
    event UseStrategy(uint256 _positionId);
    event StrategyPositionEnabled(uint256 _positionId);
    event ManagedPositionIncreaseOrderSuccess(uint256 _positionId);
    event ManagedPositionExitStrategy(uint256 _positionId);
    event CreateExitStrategyOrder(uint256 _positionId);
    event ReuseStrategy(uint256 _positionId);
    event EmergencyStrategyExit(uint256 _positionId);
    event LiquidationCollateralMultiplierBpsSet(uint256 _multiplierBps);
    event KeepCollateralEnabled(uint256 _positionId);
    event FeeWithdrawn(address _token, uint256 _amount);
    event UseDiscountForFeesSet(bool _setAs);

    error InsuredLongsStrategyError(uint256 _errorCode);

    enum ActionState {
        None, // 0
        Settled, // 1
        Active, // 2
        IncreasePending, // 3
        Increased, // 4
        EnablePending, // 5
        ExitPending // 6
    }

    struct StrategyPosition {
        uint256 expiry;
        uint256 atlanticsPurchaseId;
        address indexToken;
        address collateralToken;
        address user;
        bool keepCollateral;
        ActionState state;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    error NotOwner();
    error ZeroAddress();

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        if (owner() != msg.sender) {
            revert NotOwner();
        }
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
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }
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