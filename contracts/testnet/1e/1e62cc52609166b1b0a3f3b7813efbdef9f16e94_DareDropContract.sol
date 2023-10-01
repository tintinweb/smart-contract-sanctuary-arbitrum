// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns(uint256);
    function estimateFee(uint256 callbackGasLimit) external returns (uint256);
    function clientDeposit(address client) external payable;
    function clientWithdrawTo(address to, uint256 amount) external;
    function getFeeStats(uint256 request) external view returns(uint256[2] memory);
    function clientBalanceOf(address _client) external view returns (uint256 deposit, uint256 reserved);
    function getRequest(uint256 request) external view returns (bytes32 result, bytes32 dataHash, uint256 ethPaid, uint256 ethRefunded, bytes10[2] memory vrfHashes);
}

contract DareDropContract {
    using SafeTransferLib for ERC20;
    //events
    //
    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event DareAttempted(address indexed user, uint wager);
    event DareResult(address indexed player, uint256 indexed id, uint256 wager, bool indexed result);
    event GameCompleted(uint indexed gameId);
    event Withdraw(address indexed user, uint amount);
    event RewardsClaimed(address indexed user, uint rewardAmount);
    event UpdatedGasLimit(uint gasLimit);
    event Drop(address indexed user, uint amount);
    event Refund(address indexed player, uint refundAmount, uint indexed id);
    event LockStatusUpdated(uint8 indexed lockStatus);

    //errors
    //
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

    struct Dare {
        uint wager;
        address player;
        bool result;
        uint256 seed;
    }
    //id (returned by vrf) => Dare
    mapping(uint256 => Dare) public dares;

    //user => gameId => balance
    mapping(address => mapping(uint => uint)) public userBalance;

    //initialized at 0, increments by one each game.
    uint public gameId = 0;

    struct GameStatus {
        uint rewards;
        uint poolBalance;
        bool isGameComplete;
    }
    //gameId => GameStatus
    mapping(uint => GameStatus) public games;

    //used for vrf refunds on proceeding dares for given user.
    mapping(address => uint256) public userToLastCallback;
    mapping(uint256 => uint256) public darePaymentValue;
    uint8 public houseCut;
    uint8 public dropCut;
    address public owner;
    ERC20 public immutable ASSET; 
    IRandomizer public immutable randomizer;
    constructor(address _randomizer, address _asset) {
        houseCut = 5;
        dropCut = 20;
        ASSET = ERC20(_asset);
        randomizer = IRandomizer(_randomizer);
        owner = msg.sender;
        emit OwnershipTransferred(msg.sender, owner);
    }
    uint256 callbackGasLimit = 200000;
    function updateCallbackGasLimit(uint gasLimit) external onlyOwner {
        callbackGasLimit = gasLimit;
        emit UpdatedGasLimit(gasLimit);
    }
    function setHouseCut(uint8 _houseCut) onlyOwner external {
        houseCut = _houseCut;

    }
    function setDropCut(uint8 _dropCut) onlyOwner external {
        dropCut = _dropCut;

    }
    //@todo refactor from function modifier to in-function revert OnlyOwner() error.
    modifier onlyOwner() {
        if(msg.sender != owner) revert OnlyOwner();
        _;
    }
    uint8 private reentrancyLock = 1;
    modifier reentrancyGuard() {
        if (reentrancyLock != 1) revert ReentrantCall(); 
        reentrancyLock = 2;
        _;
        reentrancyLock = 1;
    }
    uint8 public lock = 0;
    //@todo refactor from function modifier to in-function revert WrongLockStatusForAction() error.
    modifier requiresLockStatus(uint8 lockStatus) {
        if (lock != lockStatus) revert WrongLockStatusForAction();
        _;
    }
    receive() external payable {
    }

    function getPoolBalance() view external returns(uint) {
        return(games[gameId].poolBalance);

    }
    function getRewards() view external returns(uint) {
        return(games[gameId].rewards);

    }
    //"drop" funds into pool
    //receieve cut proportional to pool share of every brave soul that decides to dare.
    function drop(uint _amount) external reentrancyGuard  requiresLockStatus(0)  {
        if (_amount == 0) revert AmountZero();
        ERC20(ASSET).safeTransferFrom(msg.sender, address(this), _amount);
        userBalance[msg.sender][gameId]  += _amount;
        games[gameId].poolBalance += _amount;
        emit Drop(msg.sender, _amount);
    }
    function dare(uint _amount) external payable reentrancyGuard  requiresLockStatus(0) {
        if (msg.value < randomizer.estimateFee(callbackGasLimit)) revert InsufficientVRFFee();
        if (_amount == 0) revert AmountZero();
        if (_amount < 100) revert  AmountTooSmall();
        if (games[gameId].poolBalance == 0) revert NoDropPool();
        uint _dropCut = (_amount * dropCut/100);
        uint _houseCut = (_amount * houseCut/100);
        _amount -= _houseCut;
        ERC20(ASSET).safeTransferFrom(msg.sender, owner, _houseCut);
        ERC20(ASSET).safeTransferFrom(msg.sender, address(this), _amount);
        games[gameId].rewards += _amount;
        ////disable gameplay while dare result is being fetched.
        //lock further drops dares until result is determined for current dare
        lock = 1;
        emit LockStatusUpdated(lock);
        //VRF price offset to user calling dare function (included in frontend calculation via estimateFee)
        //
        //deposit fee to VRF
        randomizer.clientDeposit{value: msg.value}(address(this));
        //request random bytes from VRF
        uint id = IRandomizer(randomizer).request(callbackGasLimit);
        //pair id with dare, document values
        //remove dropCut from wager value as gratuity to the drop pool.
        _amount -= _dropCut;
        Dare memory _dare = Dare(_amount, msg.sender, false, 0);
        dares[id] = _dare;
        darePaymentValue[id] = msg.value;
        emit DareAttempted(msg.sender, _amount);
    }
    function randomizerCallback(uint _id, bytes32 _value) external reentrancyGuard  {
        if (msg.sender != address(randomizer)) revert OnlyRandomizer();
        Dare memory lastDare = dares[_id];
        uint256 seed = uint256(_value);
        bool isDareSuccess =  (seed % games[gameId].poolBalance) < lastDare.wager ? true : false;
        lastDare.seed = seed;
        lastDare.result = isDareSuccess;
        dares[_id] = lastDare;
        //refund leftover vrf fees
        _refund(lastDare.player);
        userToLastCallback[lastDare.player] = _id;
        emit DareResult(lastDare.player, _id, lastDare.wager, isDareSuccess);
        handleDareResult(isDareSuccess, lastDare.player);
    }
    function handleDareResult(bool _isDareSuccess, address darer) private {
        if (_isDareSuccess) {
            //transfer entire pool to player that made the dare 
            ERC20(ASSET).safeTransfer(darer, games[gameId].poolBalance);
            games[gameId].isGameComplete = true;
            emit GameCompleted(gameId);
            ++gameId;
        }
        //re-enable deposits 
        lock = 0;
        emit LockStatusUpdated(lock);
    }
    function withdraw(uint _amount) external reentrancyGuard  requiresLockStatus(0) {
        uint balance = userBalance[msg.sender][gameId];
        if (_amount == 0) revert AmountZero();
        if (_amount > balance) revert InsufficientFunds();
        ERC20(ASSET).safeTransfer(msg.sender, _amount);
        userBalance[msg.sender][gameId] -= _amount;
        games[gameId].poolBalance -= _amount;
        emit Withdraw(msg.sender, _amount);
    }
    function claimRewards(uint _gameId) external reentrancyGuard {
        uint _userBalance = userBalance[msg.sender][_gameId];
        if (_userBalance == 0) revert AmountZero();
        if (!games[_gameId].isGameComplete) revert GameIncomplete();
        if (games[_gameId].rewards == 0) revert InsufficientFunds();
        // send rewards to user
        uint _poolBalance = games[_gameId].poolBalance;
        uint _rewards = games[_gameId].rewards;
        uint _userRewards = _rewards*_userBalance/_poolBalance;
        ERC20(ASSET).safeTransfer(msg.sender, _userRewards);
        games[_gameId].rewards -= _userRewards;
        delete userBalance[msg.sender][_gameId];
        //@TODO update event params to include game id
        emit RewardsClaimed(msg.sender, _userRewards);
    }
    function refund() external reentrancyGuard {
        if (!_refund(msg.sender)) revert NoAvailableRefund();
    }
    function _refund(address _player) private returns (bool) {
        uint256 refundableId = userToLastCallback[_player];
        if (refundableId > 0) {
            uint256[2] memory feeStats = randomizer.getFeeStats(refundableId);
            if (darePaymentValue[refundableId] > feeStats[0]) {
                //refund 90%, keep rest as buffer

                uint256 refundAmount = darePaymentValue[refundableId] - feeStats[0];
                refundAmount = refundAmount * 9/10;
                (uint256 ethDeposit, uint256 ethReserved) = randomizer.clientBalanceOf(address(this));
                if (refundAmount <= ethDeposit - ethReserved) {
                    //refund excess deposit to the player
                    randomizer.clientWithdrawTo(_player, refundAmount);
                    emit Refund(_player, refundAmount, refundableId);
                    return true;
                }
            }
        }
        return false;
    }

    function emergencyChangeLockStatus() external onlyOwner {
        if (lock == 0) lock = 1;
        else if (lock == 1) lock = 0;
    }
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

}