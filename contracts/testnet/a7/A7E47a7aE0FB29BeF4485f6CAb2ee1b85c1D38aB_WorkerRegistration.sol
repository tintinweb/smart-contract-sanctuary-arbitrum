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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract WorkerRegistration {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 public constant BOND_AMOUNT = 100000 * 10**18;
    // uint256 public constant EPOCH_LENGTH = 20700; // approximately 72 hours in blocks
    // uint256 public constant LOCK_PERIOD = EPOCH_LENGTH;


    IERC20 public tSQD;
    uint128 public immutable epochLength;
    uint128 public immutable lockPeriod;

    Counters.Counter private workerIdTracker;

    struct Worker {
        address creator;
        bytes peerId;
        uint256 bond;
        // the worker is registered at the start
        // of the next epoch, after register() is called
        uint128 registeredAt;
        // the worker is de-registered at the start of
        // the next epoch, after deregister() is called
        uint128 deregisteredAt;
    }

    mapping(uint256 => Worker) public workers;
    mapping(address creator => mapping(bytes peerId => uint256 id)) public workerIds;
    uint256[] public activeWorkerIds;

    event WorkerRegistered(uint256 indexed workerId, bytes indexed peerId, address indexed registrar, uint256 registeredAt);
    event WorkerDeregistered(uint256 indexed workerId, address indexed account, uint256 deregistedAt);
    event WorkerWithdrawn(uint256 indexed workerId, address indexed account);

    constructor(IERC20 _tSQD, uint128 _epochLengthBlocks) {
        tSQD = _tSQD;
        epochLength = _epochLengthBlocks;
        lockPeriod = _epochLengthBlocks;
    }

    function register(bytes calldata peerId) external {
        require(peerId.length <= 64, "Peer ID too large");
        require(workerIds[msg.sender][peerId] == 0, "Worker already registered");

        workerIdTracker.increment();
        uint256 workerId = workerIdTracker.current();

        workers[workerId] = Worker({
            creator: msg.sender,
            peerId: peerId,
            bond: BOND_AMOUNT,
            registeredAt: nextEpoch(),
            deregisteredAt: 0
        });

        workerIds[msg.sender][peerId] = workerId;
        activeWorkerIds.push(workerId);

        tSQD.transferFrom(msg.sender, address(this), BOND_AMOUNT);
        emit WorkerRegistered(workerId, peerId, msg.sender, workers[workerId].registeredAt);
    }

    function deregister(bytes calldata peerId) external {
        uint256 workerId = workerIds[msg.sender][peerId];
        require(workerId != 0, "Worker not registered");
        require(isWorkerActive(workers[workerId]), "Worker not active");

        workers[workerId].deregisteredAt = nextEpoch();

        // Remove the workerId from the activeWorkerIds array
        for (uint256 i = 0; i < activeWorkerIds.length; i++) {
            if (activeWorkerIds[i] == workerId) {
                activeWorkerIds[i] = activeWorkerIds[activeWorkerIds.length - 1];
                activeWorkerIds.pop();
                break;
            }
        }

        emit WorkerDeregistered(workerId, msg.sender, workers[workerId].deregisteredAt);
    }

    function withdraw(bytes calldata peerId) external {
        uint256 workerId = workerIds[msg.sender][peerId];
        require(workerId != 0, "Worker not registered");
        Worker storage worker = workers[workerId];
        require(!isWorkerActive(worker), "Worker is active");
        require(block.number >= worker.deregisteredAt + lockPeriod, "Worker is locked");

        uint256 bond = worker.bond;
        delete workers[workerId];
        delete workerIds[msg.sender][peerId];

        tSQD.transfer(msg.sender, bond);

        emit WorkerWithdrawn(workerId, msg.sender);
    }

    function nextEpoch() internal view returns (uint128) {
        return (uint128(block.number) / epochLength + 1) * epochLength;
    }

    function getActiveWorkers() external view returns (Worker[] memory) {
        Worker[] memory activeWorkers = new Worker[](getActiveWorkerCount());

        uint256 activeIndex = 0;
        for (uint256 i = 0; i < activeWorkerIds.length; i++) {
            uint256 workerId = activeWorkerIds[i];
            Worker storage worker = workers[workerId];
            if (isWorkerActive(worker)) {
                activeWorkers[activeIndex] = worker;
                activeIndex++;
            }
        }

        return activeWorkers;
    }

    function isWorkerActive(Worker storage worker) internal view returns (bool) {
        return worker.registeredAt <= block.number && (worker.deregisteredAt == 0 || worker.deregisteredAt >= block.number);
    }

    function getActiveWorkerCount() public view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < activeWorkerIds.length; i++) {
            uint256 workerId = activeWorkerIds[i];
            Worker storage worker = workers[workerId];
            if (isWorkerActive(worker)) {
                activeCount++;
            }
        }
        return activeCount;
    }

    function getWorkerByIndex(uint256 index) external view returns (Worker memory) {
        require(index < activeWorkerIds.length, "Index out of bounds");
        uint256 workerId = activeWorkerIds[index];
        return workers[workerId];
    }

    function getAllWorkersCount() external view returns (uint256) {
        return activeWorkerIds.length;
    }
}