// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

enum FundState {
    Closed,
    Opened
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelayedExecutor {
    event TxRequested(address indexed _sender, uint256 indexed _id, uint256 date, address indexed _destination, bytes _message);
    event TxExecuted(address indexed _sender, uint256 indexed _id);
    event TxCancelled(address indexed _sender, uint256 indexed _id);

    struct Transaction {
        uint256 date;
        bytes message;
        address destination;
        address sender;
    }

    function transactions(uint256 id) external view returns (uint256 _date, bytes memory _message, address _destination, address _sender);
    function delay() external view returns (uint256);
    function minDelay() external view returns (uint256);
    function setDelay(uint256 _delay) external;
    function requestTx(address _destination, bytes calldata _message) external returns (uint256 _id);
    function executeTx(uint256 _id) external;
    function cancelTx(uint256 _id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./FundState.sol";

interface ITrade {
    /**
    * Events
    */
    event SwapSuccess(address tokenA, address tokenB, uint256 amountIn, uint256 amountOut);
    event ManagerAdded(address newManager);
    event ManagerRemoved(address manager);

    event AaveSupply(address asset, uint256 amount);
    event AaveWithdraw(address asset, uint256 amount);
    event AaveBorrowEvent(address asset, uint256 amount);
    event AaveRepayEvent(address asset, uint256 amount);
    event AaveSetCollateralEvent(address asset);

    event GmxIncreasePosition(address tokenFrom, address indexToken, uint256 tokenFromAmount, uint256 usdDelta);
    event GmxDecreasePosition(address collateralAsset, address indexToken, uint256 collateralAmount, uint256 usdDelta);
    
    event WhitelistMaskUpdated(bytes _newMask);
    event AllowedServicesUpdated(uint256 _newMask);
    /**
    * Public
    */
    function swap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        bytes memory payload
    ) external returns(uint256);

    function multiSwap(
        bytes[] calldata data
    ) external;

    function gmxIncreasePosition(
        address tokenFrom,
        address indexToken,
        uint256 collateralAmount,
        uint256 usdDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee
    ) external payable;

    function gmxDecreasePosition(
        address collateralToken,
        address indexToken,
        address receiveToken,
        uint256 collateralDelta,
        uint256 usdDelta,
        bool isLong,
        uint256 acceptablePrice, // usd amount [1e6]
        uint256 executionFee
    ) external payable;

    function aaveSupply(address _asset, uint256 _amount) external;
    function aaveWithdraw(address _asset, uint256 _amount) external;
    function setCollateralAsset(address collateralAsset) external;
    function setTradingScope(bytes memory whitelistMask, uint256 serviceMask) external;
    function setAaveReferralCode(uint16 refCode) external;
    function setGmxRefCode(bytes32 _gmxRefCode) external;
    function setState(FundState newState) external;
    function chargeDebt() external;
    function isManager(address _address) external view returns (bool);
    function whitelistMask() external view returns (bytes memory);
    function servicesEnabled() external view returns (bool[] memory);
    /**
    * Auth
    */
    function transferToFeeder(uint256 amount) external;

    function setManager(address manager, bool enable) external;

    function initialize(
        address _manager,
        bytes calldata _whitelistMask,
        uint256 serviceMask,
        uint256 fundId
    ) external;
    /**
    * View
    */
    function usdtAmount() external view returns(uint256);
    function debt() external view returns(uint256);

    function getAavePositionSizes(address[] calldata _assets) external view
        returns (uint256[] memory assetPositions);

    function getAssetsSizes(address[] calldata assets) external view returns(uint256[] memory);

    function status() external view returns(FundState);

    function fundId() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITradeParamsUpdater {
    function nearestUpdate(address _destination) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./../utils/TryCall.sol";
import "../interfaces/IDelayedExecutor.sol";

abstract contract DelayedExecutor is IDelayedExecutor, Ownable {
    mapping(uint256 => Transaction) public transactions;
    uint256 public delay;
    uint256 public minDelay;

    constructor(uint256 _delay, uint256 _minDelay) {
        delay = _delay;
        minDelay = _minDelay;
        require(_delay >= minDelay, "DE/DS"); // delay too small
    }

    function setDelay(uint256 _delay) external onlyOwner {
        require(_delay >= minDelay, "DE/DS"); // delay too small
        delay = _delay;
    }
    
    function requestTx(address _destination, bytes calldata _message) public virtual returns (uint256 _id) {
        _authorizeTx(_destination, _message);
        uint256 executionDate = block.timestamp + delay;
        _id = uint256(keccak256(abi.encode(msg.sender, _destination, _message, executionDate)));
        transactions[_id] = Transaction(executionDate, _message, _destination, msg.sender);
        emit TxRequested(msg.sender, _id, executionDate, _destination, _message);
    }

    function executeTx(uint256 _id) public virtual {
        Transaction memory transaction = transactions[_id];
        require(transaction.date > 0, "DE/TXNF"); // transaction not found
        _authorizeTx(transaction.destination, transaction.message);
        require(transaction.date <= block.timestamp, "DE/DNP"); // delay not passed
        emit TxExecuted(msg.sender, _id);
        delete transactions[_id];
        TryCall.call(transaction.destination, transaction.message);
    }

    function cancelTx(uint256 _id) public virtual {
        _authorizeTx(transactions[_id].destination, transactions[_id].message);
        emit TxCancelled(transactions[_id].sender, _id);
        delete transactions[_id];
    }

    function _authorizeTx(address _destination, bytes memory message) internal virtual;
}

contract DummyDelayedExecutor is DelayedExecutor {
    constructor(uint256 _delay, uint256 _minDelay) DelayedExecutor(_delay, _minDelay) {}

    function _authorizeTx(address _destination, bytes memory message) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DelayedExecutor.sol";
import "../interfaces/ITrade.sol";
import "../interfaces/ITradeParamsUpdater.sol";

contract TradeParamsUpdater is ITradeParamsUpdater, DelayedExecutor {
    mapping(address => uint256) public lastTxs;

    constructor(uint256 _updatePeriod, uint256 _minDelay) DelayedExecutor(_updatePeriod, _minDelay) {}

    function requestTx(address _destination, bytes calldata _message) public override returns (uint256 _id) {
        if (lastTxs[_destination] != 0) {
            _cancelTx(lastTxs[_destination]);
        }
        uint256 _id = super.requestTx(_destination, _message);
        lastTxs[_destination] = _id;
    }

    function cancelTx(uint256 _id) public override {
        _cancelTx(_id);
    }

    function executeTx(uint256 _id) public override {
        address destination = transactions[_id].destination;
        super.executeTx(_id);
        delete lastTxs[destination];
    }

    function nearestUpdate(address _destination) external view returns (uint256) {
        return transactions[lastTxs[_destination]].date;
    }

    function _cancelTx(uint256 _id) private {
        address destination = transactions[_id].destination;
        super.cancelTx(_id);
        delete lastTxs[destination];
    }

    function _authorizeTx(address _destination, bytes memory message) internal override {
        require(ITrade(_destination).isManager(msg.sender), "TPU/AD"); // access denied
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TryCall {
    function call(address _destination, bytes memory _message) internal {
        (bool success, bytes memory _returnData) = _destination.call(_message);
        if (success) {
            return;
        }
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) revert('Transaction reverted silently');

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}