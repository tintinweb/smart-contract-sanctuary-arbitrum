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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "../../interfaces/IStrategy.sol";

interface IDuoMaster {
    function userShares(
        uint256 pidMonopoly,
        address user
    ) external view returns (uint256);

    function totalShares(uint256 pidMonopoly) external view returns (uint256);

    function actionFeeAddress() external view returns (address);

    function performanceFeeAddress() external view returns (address);

    function owner() external view returns (address);

    function add(
        uint256 alloc,
        uint16 depositBP,
        uint16 withdrawBP,
        IERC20 want,
        bool withUpdate,
        bool isWithdrawFee,
        IStrategy strat
    ) external;

    function set(
        uint256 pid,
        uint256 alloc,
        uint16 depositBP,
        uint16 withdrawBP,
        bool withUpdate,
        bool isWithdrawFee
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    // Deposit amount of tokens for 'caller' to address 'to'
    function deposit(
        address caller,
        address to,
        uint256 tokenAmount,
        uint256 shareAmount
    ) external;

    // Transfer tokens from strategy for 'caller' to address 'to'
    function withdraw(
        address caller,
        address to,
        uint256 tokenAmount,
        uint256 shareAmount,
        uint256 withdrawalFeeBP
    ) external;

    function inCaseTokensGetStuck(
        IERC20 token,
        address to,
        uint256 amount
    ) external;

    function setAllowances() external;

    function revokeAllowance(address token, address spender) external;

    function migrate(address newStrategy) external;

    function onMigration() external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 amount
    ) external view returns (address[] memory, uint256[] memory);

    function transferOwnership(address newOwner) external;

    function setPerformanceFeeBips(uint256 newPerformanceFeeBips) external;

    function emergencyWithdraw(
        address caller,
        address to,
        uint256 tokenAmount,
        uint256 shareAmount,
        uint256 withdrawalFeeBP
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../duo/interfaces/IDuoMaster.sol";

contract TimeLock {
    error NotOwnerError();
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint blockTimestamp, uint timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint blockTimestmap, uint timestamp);
    error TimestampExpiredError(uint blockTimestamp, uint expiresAt);
    error TxFailedError();

    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Cancel(bytes32 indexed txId);

    uint public constant MIN_DELAY = 60; // seconds
    uint public constant MAX_DELAY = 86400; // seconds
    uint public constant GRACE_PERIOD = 86400; // seconds

    address public owner;
    // tx id => queued
    mapping(bytes32 => bool) public queued;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwnerError();
        }
        _;
    }

    receive() external payable {}

    function getTxId(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
    }

    /**
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _func Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send. abiCoder.encode(["address", "uint256"], ["0x123...", 123])
     * @param _timestamp Timestamp after which the transaction can be executed.
     */
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner returns (bytes32 txId) {
        txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }
        // ---|------------|---------------|-------
        //  block    block + min     block + max
        if (
            _timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }

        queued[txId] = true;

        emit Queue(txId, _target, _value, _func, _data, _timestamp);
    }

    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }
        // ----|-------------------|-------
        //  timestamp    timestamp + grace period
        if (block.timestamp < _timestamp) {
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(
                block.timestamp,
                _timestamp + GRACE_PERIOD
            );
        }

        queued[txId] = false;

        // prepare data
        bytes memory data;
        if (bytes(_func).length > 0) {
            // data = func selector + _data
            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
        } else {
            // call fallback with data
            data = _data;
        }

        // call target
        (bool ok, bytes memory res) = _target.call{value: _value}(data);
        if (!ok) {
            revert TxFailedError();
        }

        emit Execute(txId, _target, _value, _func, _data, _timestamp);

        return res;
    }

    function cancel(bytes32 _txId) external onlyOwner {
        if (!queued[_txId]) {
            revert NotQueuedError(_txId);
        }

        queued[_txId] = false;

        emit Cancel(_txId);
    }

    // @dev add function can execute directly
    function add(
        IDuoMaster _duoMaster,
        uint256 alloc,
        uint16 depositBP,
        uint16 withdrawBP,
        IERC20 want,
        bool withUpdate,
        bool isWithdrawFee,
        IStrategy strat
    ) external onlyOwner {
        _duoMaster.add(
            alloc,
            depositBP,
            withdrawBP,
            want,
            withUpdate,
            isWithdrawFee,
            strat
        );
    }

    // @dev set function can execute directly
    function set(
        IDuoMaster _duoMaster,
        uint256 pid,
        uint256 alloc,
        uint16 depositBP,
        uint16 withdrawBP,
        bool withUpdate,
        bool isWithdrawFee
    ) external onlyOwner {
        _duoMaster.set(
            pid,
            alloc,
            depositBP,
            withdrawBP,
            withUpdate,
            isWithdrawFee
        );
    }
}