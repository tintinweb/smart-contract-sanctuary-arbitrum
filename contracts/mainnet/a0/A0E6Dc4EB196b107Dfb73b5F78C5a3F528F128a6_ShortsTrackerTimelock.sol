// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAdmin {
    function admin() external view returns (address);

    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IShortsTracker {
    function isGlobalShortDataReady() external view returns (bool);

    function globalShortAveragePrices(address _token)
        external
        view
        returns (uint256);

    function getNextGlobalShortData(
        address _account,
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        bool _isIncrease
    ) external view returns (uint256, uint256);

    function updateGlobalShortData(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) external;

    function setIsGlobalShortDataReady(bool value) external;

    function setInitData(
        address[] calldata _tokens,
        uint256[] calldata _averagePrices
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/interfaces/IShortsTracker.sol";
import "../access/interfaces/IAdmin.sol";

contract ShortsTrackerTimelock is IAdmin {
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_BUFFER = 5 days;

    mapping(bytes32 => uint256) public pendingActions;

    address public admin;
    uint256 public buffer;

    mapping(address => bool) public isHandler;
    mapping(address => uint256) public lastUpdated;
    uint256 public averagePriceUpdateDelay;
    uint256 public maxAveragePriceChange;

    event GlobalShortAveragePriceUpdated(
        address indexed token,
        uint256 oldAveragePrice,
        uint256 newAveragePrice
    );

    event SignalSetGov(address target, address gov);
    event SetGov(address target, address gov);

    event SignalSetAdmin(address admin);
    event SetAdmin(address admin);

    event SetHandler(address indexed handler, bool isHandler);

    event SignalSetMaxAveragePriceChange(uint256 maxAveragePriceChange);
    event SetMaxAveragePriceChange(uint256 maxAveragePriceChange);

    event SignalSetAveragePriceUpdateDelay(uint256 averagePriceUpdateDelay);
    event SetAveragePriceUpdateDelay(uint256 averagePriceUpdateDelay);

    event SignalSetIsGlobalShortDataReady(
        address target,
        bool isGlobalShortDataReady
    );
    event SetIsGlobalShortDataReady(
        address target,
        bool isGlobalShortDataReady
    );

    event SignalPendingAction(bytes32 action);
    event ClearAction(bytes32 action);

    constructor(
        address _admin,
        uint256 _buffer,
        uint256 _averagePriceUpdateDelay,
        uint256 _maxAveragePriceChange
    ) {
        admin = _admin;
        buffer = _buffer;
        averagePriceUpdateDelay = _averagePriceUpdateDelay;
        maxAveragePriceChange = _maxAveragePriceChange;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "ShortsTrackerTimelock: admin forbidden");
        _;
    }

    modifier onlyHandler() {
        require(
            isHandler[msg.sender] || msg.sender == admin,
            "ShortsTrackerTimelock: handler forbidden"
        );
        _;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "ShortsTrackerTimelock: invalid buffer");
        require(
            _buffer > buffer,
            "ShortsTrackerTimelock: buffer cannot be decreased"
        );
        buffer = _buffer;
    }

    function signalSetAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "ShortsTrackerTimelock: invalid admin");

        bytes32 action = keccak256(abi.encodePacked("setAdmin", _admin));
        _setPendingAction(action);

        emit SignalSetAdmin(_admin);
    }

    function setAdmin(address _admin) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _admin));
        _validateAction(action);
        _clearAction(action);

        admin = _admin;

        emit SetAdmin(_admin);
    }

    function setHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;

        emit SetHandler(_handler, _isActive);
    }

    function signalSetGov(address _shortsTracker, address _gov)
        external
        onlyAdmin
    {
        require(_gov != address(0), "ShortsTrackerTimelock: invalid owner");

        bytes32 action = keccak256(
            abi.encodePacked("transferOwnership", _shortsTracker, _gov)
        );
        _setPendingAction(action);

        emit SignalSetGov(_shortsTracker, _gov);
    }

    function transferOwnership(address _shortsTracker, address _gov)
        external
        onlyAdmin
    {
        bytes32 action = keccak256(
            abi.encodePacked("transferOwnership", _shortsTracker, _gov)
        );
        _validateAction(action);
        _clearAction(action);

        Ownable(_shortsTracker).transferOwnership(_gov);

        emit SetGov(_shortsTracker, _gov);
    }

    function signalSetAveragePriceUpdateDelay(uint256 _averagePriceUpdateDelay)
        external
        onlyAdmin
    {
        bytes32 action = keccak256(
            abi.encodePacked(
                "setAveragePriceUpdateDelay",
                _averagePriceUpdateDelay
            )
        );
        _setPendingAction(action);

        emit SignalSetAveragePriceUpdateDelay(_averagePriceUpdateDelay);
    }

    function setAveragePriceUpdateDelay(uint256 _averagePriceUpdateDelay)
        external
        onlyAdmin
    {
        bytes32 action = keccak256(
            abi.encodePacked(
                "setAveragePriceUpdateDelay",
                _averagePriceUpdateDelay
            )
        );
        _validateAction(action);
        _clearAction(action);

        averagePriceUpdateDelay = _averagePriceUpdateDelay;

        emit SetAveragePriceUpdateDelay(_averagePriceUpdateDelay);
    }

    function signalSetMaxAveragePriceChange(uint256 _maxAveragePriceChange)
        external
        onlyAdmin
    {
        bytes32 action = keccak256(
            abi.encodePacked("setMaxAveragePriceChange", _maxAveragePriceChange)
        );
        _setPendingAction(action);

        emit SignalSetMaxAveragePriceChange(_maxAveragePriceChange);
    }

    function setMaxAveragePriceChange(uint256 _maxAveragePriceChange)
        external
        onlyAdmin
    {
        bytes32 action = keccak256(
            abi.encodePacked("setMaxAveragePriceChange", _maxAveragePriceChange)
        );
        _validateAction(action);
        _clearAction(action);

        maxAveragePriceChange = _maxAveragePriceChange;

        emit SetMaxAveragePriceChange(_maxAveragePriceChange);
    }

    function signalSetIsGlobalShortDataReady(
        IShortsTracker _shortsTracker,
        bool _value
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked(
                "setIsGlobalShortDataReady",
                address(_shortsTracker),
                _value
            )
        );
        _setPendingAction(action);

        emit SignalSetIsGlobalShortDataReady(address(_shortsTracker), _value);
    }

    function setIsGlobalShortDataReady(
        IShortsTracker _shortsTracker,
        bool _value
    ) external onlyAdmin {
        bytes32 action = keccak256(
            abi.encodePacked(
                "setIsGlobalShortDataReady",
                address(_shortsTracker),
                _value
            )
        );
        _validateAction(action);
        _clearAction(action);

        _shortsTracker.setIsGlobalShortDataReady(_value);

        emit SetIsGlobalShortDataReady(address(_shortsTracker), _value);
    }

    function disableIsGlobalShortDataReady(IShortsTracker _shortsTracker)
        external
        onlyAdmin
    {
        _shortsTracker.setIsGlobalShortDataReady(false);

        emit SetIsGlobalShortDataReady(address(_shortsTracker), false);
    }

    function setGlobalShortAveragePrices(
        IShortsTracker _shortsTracker,
        address[] calldata _tokens,
        uint256[] calldata _averagePrices
    ) external onlyHandler {
        _shortsTracker.setIsGlobalShortDataReady(false);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 oldAveragePrice = _shortsTracker.globalShortAveragePrices(
                token
            );
            uint256 newAveragePrice = _averagePrices[i];
            uint256 diff = newAveragePrice > oldAveragePrice
                ? newAveragePrice - oldAveragePrice
                : oldAveragePrice - newAveragePrice;
            require(
                (diff * BASIS_POINTS_DIVISOR) / oldAveragePrice <
                    maxAveragePriceChange,
                "ShortsTrackerTimelock: too big change"
            );

            require(
                block.timestamp >= lastUpdated[token] + averagePriceUpdateDelay,
                "ShortsTrackerTimelock: too early"
            );
            lastUpdated[token] = block.timestamp;

            emit GlobalShortAveragePriceUpdated(
                token,
                oldAveragePrice,
                newAveragePrice
            );
        }

        _shortsTracker.setInitData(_tokens, _averagePrices);
    }

    function _setPendingAction(bytes32 _action) private {
        require(
            pendingActions[_action] == 0,
            "ShortsTrackerTimelock: action already signalled"
        );
        pendingActions[_action] = block.timestamp + buffer;
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(
            pendingActions[_action] != 0,
            "ShortsTrackerTimelock: action not signalled"
        );
        require(
            pendingActions[_action] <= block.timestamp,
            "ShortsTrackerTimelock: action time not yet passed"
        );
    }

    function _clearAction(bytes32 _action) private {
        require(
            pendingActions[_action] != 0,
            "ShortsTrackerTimelock: invalid _action"
        );
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}