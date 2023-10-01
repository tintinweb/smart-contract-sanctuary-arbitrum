// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { SafeTransferLib } from "@solmate/src/utils/SafeTransferLib.sol";
import { ERC20 } from "@solmate/src/tokens/ERC20.sol";

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function estimateFee(uint256 callbackGasLimit) external returns (uint256);

    function clientDeposit(address client) external payable;

    function clientWithdrawTo(address to, uint256 amount) external;

    function getFeeStats(uint256 request) external view returns (uint256[2] memory);

    function clientBalanceOf(address _client) external view returns (uint256 deposit, uint256 reserved);

    function getRequest(uint256 request) external view returns (bytes32 result, bytes32 dataHash, uint256 ethPaid, uint256 ethRefunded, bytes10[2] memory vrfHashes);
}

//  @title DareDropContract
//  @dev A contract that facilitates a game in which players dare and win rewards based on random outcomes.

contract DareDropContract {
    using SafeTransferLib for ERC20;


    //   @dev Emitted when ownership of the contract is transferred.
    //   @param user The previous owner's address.
    //   @param newOwner The new owner's address.

    event OwnershipTransferred(address indexed user, address indexed newOwner);


    //  @dev Emitted when a player attempts a dare.
    //  @param user The player's address.
    //  @param wager The wager amount.

    event DareAttempted(address indexed user, uint256 wager);


    //  @dev Emitted when the result of a dare is determined.
    //  @param player The player's address.
    //  @param id The dare's ID.
    //  @param wager The wager amount.
    //  @param result The dare result (true for success, false for failure).

    event DareResult(address indexed player, uint256 indexed id, uint256 wager, bool indexed result);


    //  @dev Emitted when a game is completed.
    //  @param gameId The game's ID.

    event GameCompleted(uint indexed gameId);


    //  @dev Emitted when a user withdraws funds.
    //  @param user The user's address.
    //  @param amount The withdrawn amount.

    event Withdraw(address indexed user, uint amount);


    //  @dev Emitted when a user claims rewards.
    //  @param user The user's address.
    //  @param rewardAmount The claimed reward amount.

    event RewardsClaimed(address indexed user, uint rewardAmount);


    //  @dev Emitted when the gas limit for callback functions is updated.
    //  @param gasLimit The new gas limit.

    event UpdatedGasLimit(uint gasLimit);


    //  @dev Emitted when a user drops funds into the pool.
    //  @param user The user's address.
    //  @param amount The dropped amount.

    event Drop(address indexed user, uint amount);


    //  @dev Emitted when a refund is processed.
    //  @param player The player's address.
    //  @param refundAmount The refunded amount.
    //  @param id The dare's ID.

    event Refund(address indexed player, uint refundAmount, uint indexed id);


    //  @dev Emitted when the lock status is updated.
    //  @param lockStatus The new lock status (0 for unlocked, 1 for locked).

    event LockStatusUpdated(uint8 indexed lockStatus);

    error NoAvailableRefund();
    error InsufficientFunds();
    error OnlyRandomizer();
    error WrongLockStatusForAction();
    error ReentrantCall();
    error AmountZero();
    error AmountTooSmall();
    error InsufficientVRFFee();
    error NoDropPool();
    error GameIncomplete();
    error OnlyOwner();


    // @dev Struct representing a dare.
    // @param wager The wager amount.
    // @param player The player's address.
    // @param result The dare result (true for success, false for failure).
    // @param seed The random seed used to determine the result.

    struct Dare {
        uint wager;
        address player;
        bool result;
        uint256 seed;
    }

    // Map request ID to Dare
    mapping(uint256 => Dare) public dares;

    // Map user address and game ID to balance
    mapping(address => mapping(uint => uint)) public userBalance;

    // Game ID counter
    uint public gameId = 0;

    //  @dev Struct representing the status of a game.
    //  @param rewards The total rewards in the game.
    //  @param poolBalance The current balance in the pool.
    //  @param isGameComplete Indicates if the game is complete (true or false).

    struct GameStatus {
        uint rewards;
        uint poolBalance;
        bool isGameComplete;
    }

    // Map game ID to GameStatus
    mapping(uint => GameStatus) public games;

    // Map user address to the last callback request
    mapping(address => uint256) public userToLastCallback;

    // Map request ID to the payment value for the dare
    mapping(uint256 => uint256) public darePaymentValue;

    // House cut percentage
    uint8 public houseCut;

    // Drop cut percentage
    uint8 public dropCut;

    // Owner address
    address public owner;

    // Immutable reference to the asset token
    ERC20 public immutable ASSET;

    // Immutable reference to the randomizer contract
    IRandomizer public immutable randomizer;

    constructor(address _randomizer, address _asset) {
        houseCut = 5;
        dropCut = 20;
        ASSET = ERC20(_asset);
        randomizer = IRandomizer(_randomizer);
        owner = msg.sender;
        emit OwnershipTransferred(msg.sender, owner);
    }

    // Gas limit for callback functions
    uint256 callbackGasLimit = 400000;

    //  @dev Updates the gas limit for callback functions.
    //  @param gasLimit The new gas limit.

    function updateCallbackGasLimit(uint gasLimit) external onlyOwner {
        callbackGasLimit = gasLimit;
        emit UpdatedGasLimit(gasLimit);
    }


    //  @dev Sets the house cut percentage.
    //  @param _houseCut The new house cut percentage.

    function setHouseCut(uint8 _houseCut) onlyOwner external {
        houseCut = _houseCut;
    }


    // @dev Sets the drop cut percentage.
    // @param _dropCut The new drop cut percentage.

    function setDropCut(uint8 _dropCut) onlyOwner external {
        dropCut = _dropCut;
    }


    //  @dev Modifier that allows only the owner to access a function.

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    // Reentrancy lock
    uint8 private reentrancyLock = 1;


    // @dev Modifier to guard against reentrant calls.

    modifier reentrancyGuard() {
        if (reentrancyLock != 1) revert ReentrantCall();
        reentrancyLock = 2;
        _;
        reentrancyLock = 1;
    }

    // Lock status
    uint8 public lock = 0;


    // @dev Modifier to check and enforce a specific lock status.
    // @param lockStatus The required lock status (0 for unlocked, 1 for locked).

    modifier requiresLockStatus(uint8 lockStatus) {
        if (lock != lockStatus) revert WrongLockStatusForAction();
        _;
    }



    // @dev Retrieves the balance of the current game's pool.
    // @return The balance of the pool.

    function getPoolBalance() view external returns (uint) {
        return (games[gameId].poolBalance);
    }


    // @dev Retrieves the total rewards in the current game.
    // @return The total rewards in the game.

    function getRewards() view external returns (uint) {
        return (games[gameId].rewards);
    }


    // @dev Deposit funds into the pool. Earn yield proportional to total pool share from failed dare attempts.
    // @param _amount The amount to drop into the pool.

    function drop(uint _amount) external reentrancyGuard requiresLockStatus(0) {
        if (_amount == 0) revert AmountZero();
        ERC20(ASSET).safeTransferFrom(msg.sender, address(this), _amount);
        userBalance[msg.sender][gameId] += _amount;
        games[gameId].poolBalance += _amount;
        emit Drop(msg.sender, _amount);
    }


    //  @dev Places a dare with a specified amount and attempts to win the pool.
    //  @param _amount The amount to wager on the dare.
    //  @notice takes a 25% cut. 20% gratuity to the pool, 5% to fees.

    function dare(uint _amount) external payable reentrancyGuard requiresLockStatus(0) {
        if (msg.value < randomizer.estimateFee(callbackGasLimit)) revert InsufficientVRFFee();
        if (_amount == 0) revert AmountZero();
        if (_amount < 100) revert AmountTooSmall();
        if (games[gameId].poolBalance == 0) revert NoDropPool();

        uint _dropCut = (_amount * dropCut / 100);
        uint _houseCut = (_amount * houseCut / 100);
        _amount -= _houseCut;
        ERC20(ASSET).safeTransferFrom(msg.sender, owner, _houseCut);
        ERC20(ASSET).safeTransferFrom(msg.sender, address(this), _amount);
        games[gameId].rewards += _amount;
        // Disable gameplay while dare result is being fetched.
        lock = 1;
        emit LockStatusUpdated(lock);

        // Deposit fee to VRF
        randomizer.clientDeposit{value: msg.value}(address(this));
        // Request random bytes from VRF
        uint id = IRandomizer(randomizer).request(callbackGasLimit);
        // Pair id with dare, document values
        // Remove dropCut from wager value as gratuity to the drop pool.
        _amount -= _dropCut;
        Dare memory _dare = Dare(_amount, msg.sender, false, 0);
        dares[id] = _dare;
        darePaymentValue[id] = msg.value;
        emit DareAttempted(msg.sender, _amount);
    }


    //  @dev Callback function for the randomizer, processes the result of a dare.
    //  @param _id The dare's ID.
    //  @param _value The random value from the randomizer.

    function randomizerCallback(uint _id, bytes32 _value) external reentrancyGuard {
        if (msg.sender != address(randomizer)) revert OnlyRandomizer();
        Dare memory lastDare = dares[_id];
        uint256 seed = uint256(_value);
        bool isDareSuccess = (seed % games[gameId].poolBalance) < lastDare.wager ? true : false;
        lastDare.seed = seed;
        lastDare.result = isDareSuccess;
        dares[_id] = lastDare;

        // Refund leftover VRF fees
        _refund(lastDare.player);
        userToLastCallback[lastDare.player] = _id;
        emit DareResult(lastDare.player, _id, lastDare.wager, isDareSuccess);
        handleDareResult(isDareSuccess, lastDare.player);
    }


    //  @dev Handles the result of a dare and distributes rewards accordingly.
    //  @param _isDareSuccess The result of the dare (true for success, false for failure).
    //  @param darer The player's address.

    function handleDareResult(bool _isDareSuccess, address darer) private {
        if (_isDareSuccess) {
            // Transfer entire pool to the player that made the dare
            ERC20(ASSET).safeTransfer(darer, games[gameId].poolBalance);
            games[gameId].isGameComplete = true;
            emit GameCompleted(gameId);
            ++gameId;
        }

        // Re-enable deposits
        lock = 0;
        emit LockStatusUpdated(lock);
    }


    //  @dev Allows a user to withdraw funds from their balance.
    //  @param _amount The amount to withdraw.
    //  @notice users can only withdraw from current game. 

    function withdraw(uint _amount) external reentrancyGuard requiresLockStatus(0) {
        uint balance = userBalance[msg.sender][gameId];
        if (_amount == 0) revert AmountZero();
        if (_amount > balance) revert InsufficientFunds();
        ERC20(ASSET).safeTransfer(msg.sender, _amount);
        userBalance[msg.sender][gameId] -= _amount;
        games[gameId].poolBalance -= _amount;
        emit Withdraw(msg.sender, _amount);
    }


    //  @dev Allows a user to claim rewards from a completed game.
    //  @param _gameId The ID of the game from which to claim rewards.
    //  @notice can only claim rewards from games already completed.

    function claimRewards(uint _gameId) external reentrancyGuard {
        uint _userBalance = userBalance[msg.sender][_gameId];
        if (_userBalance == 0) revert AmountZero();
        if (!games[_gameId].isGameComplete) revert GameIncomplete();
        if (games[_gameId].rewards == 0) revert InsufficientFunds();

        // Send rewards to the user
        uint _poolBalance = games[_gameId].poolBalance;
        uint _rewards = games[_gameId].rewards;
        uint _userRewards = _rewards * _userBalance / _poolBalance;
        ERC20(ASSET).safeTransfer(msg.sender, _userRewards);
        games[_gameId].rewards -= _userRewards;
        delete userBalance[msg.sender][_gameId];
        emit RewardsClaimed(msg.sender, _userRewards);
    }


    //  @dev Allows a user to request a refund of excess VRF fees.

    function refund() external reentrancyGuard {
        if (!_refund(msg.sender)) revert NoAvailableRefund();
    }


    //  @dev Internal function to process a refund of excess VRF fees to a player.
    //  @param _player The player's address.
    //  @return A boolean indicating if the refund was successful.

    function _refund(address _player) private returns (bool) {
        uint256 refundableId = userToLastCallback[_player];
        if (refundableId > 0) {
            uint256[2] memory feeStats = randomizer.getFeeStats(refundableId);
            if (darePaymentValue[refundableId] > feeStats[0]) {
                // Refund 90% of the excess deposit to the player
                uint256 refundAmount = darePaymentValue[refundableId] - feeStats[0];
                refundAmount = refundAmount * 9/10;
                (uint256 ethDeposit, uint256 ethReserved) = randomizer.clientBalanceOf(address(this));
                if (refundAmount <= ethDeposit - ethReserved) {
                    // Refund the excess deposit to the player
                    randomizer.clientWithdrawTo(_player, refundAmount);
                    emit Refund(_player, refundAmount, refundableId);
                    return true;
                }
            }
        }
        return false;
    }

    //  @dev Allows the owner to change the lock status for emergency purposes.

    function emergencyChangeLockStatus() external onlyOwner {
        if (lock == 0) lock = 1;
        else if (lock == 1) lock = 0;
    }


    //  @dev Allows the owner to transfer ownership of the contract.
    //  @param newOwner The new owner's address.

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    // @dev Fallback function to receive Ether.

    receive() external payable {
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}