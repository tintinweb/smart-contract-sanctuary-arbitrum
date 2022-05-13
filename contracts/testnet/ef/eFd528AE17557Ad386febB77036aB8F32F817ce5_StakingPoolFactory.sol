// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import "./interface/IStakingPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./ERC20StakingPool.sol";

/// Modified version of https://github.com/ZeframLou/playpen/blob/main/src/StakingPoolFactory.sol
contract StakingPoolFactory is Ownable {
    using ClonesWithImmutableArgs for address;
    event CreateERC20StakingPool(address indexed stakingPool);

    function createERC20StakingPool(
        address erc20StakingPoolImpl,
        address rewardToken,
        address stakeToken,
        uint64 secondDuration
    ) external onlyOwner returns (address stakingPool) {
        bytes memory data = abi.encodePacked(rewardToken, stakeToken, secondDuration);

        stakingPool = Create2.deploy(0, keccak256(abi.encode(rewardToken, stakeToken)), type(ERC20StakingPool).creationCode);
        IStakingPool(stakingPool).initialize(msg.sender);

        emit CreateERC20StakingPool(stakingPool);
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x43 + extraLength;
            uint256 runSize = creationSize - 11;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (11 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 61 runtime  | PUSH2 runtime (r)     | r 0                     | –
                mstore(
                    ptr,
                    0x3d61000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x02), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0b
                // 80          | DUP1                  | r r 0                   | –
                // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
                // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
                // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
                // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
                // f3          | RETURN                | 0                       | [0-2d]: runtime code
                mstore(
                    add(ptr, 0x04),
                    0x80600b3d3981f300000000000000000000000000000000000000000000000000
                )

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME
                // -------------------------------------------------------------------------------------------------------------

                // 36          | CALLDATASIZE          | cds                     | –
                // 3d          | RETURNDATASIZE        | 0 cds                   | –
                // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
                // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
                // 61          | PUSH2 extra           | extra                   | [0, cds] = calldata
                mstore(
                    add(ptr, 0x0b),
                    0x363d3d3761000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x10), shl(240, extraLength))

                // 60 0x38     | PUSH1 0x38            | 0x38 extra              | [0, cds] = calldata // 0x38 (56) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x38 extra          | [0, cds] = calldata
                // 39          | CODECOPY              | _                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
                // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0         | [0, cds] = calldata
                mstore(
                    add(ptr, 0x12),
                    0x603836393d3d3d36610000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
                // f4          | DELEGATECALL          | success 0               | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
                // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
                // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
                // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
                // 90          | SWAP1                 | 0 success               | [0, rds] = return data
                // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
                // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
                // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
                // fd          | REVERT                | –                       | [0, rds] = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
                // f3          | RETURN                | –                       | [0, rds] = return data

                mstore(
                    add(ptr, 0x34),
                    0x5af43d82803e903d91603657fd5bf30000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x43;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
}

pragma solidity ^0.8.11;

interface IStakingPool {
    error Error_ZeroOwner();
    error Error_AlreadyInitialized();
    error Error_NotRewardDistributor();
    error Error_AmountTooLarge();

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    function initialize(address _owner) external;
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

import "./interface/IStakingPool.sol";

import {Clone} from "clones-with-immutable-args/Clone.sol";
import {FullMath} from "./lib/FullMath.sol";
import "./lib/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


///Modified version of https://github.com/ZeframLou/playpen/blob/main/src/ERC20StakingPool.sol
contract ERC20StakingPool is Ownable, Clone, IStakingPool{
    uint256 internal constant PRECISION = 1e30;

    uint64 public lastUpdateTime;
    uint64 public periodFinish;

    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;

    mapping(address => bool) public isRewardDistributor;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    function rewardToken() public pure returns (address rewardToken_) {
        return _getArgAddress(0);
    }

    function stakeToken() public pure returns (address stakeToken_) {
        return _getArgAddress(0x14);
    }

    function DURATION() public pure returns (uint64 DURATION_) {
        return _getArgUint64(0x28);
    }


    function initialize(address initialOwner) external override {
        if (owner() != address(0)) {
            revert Error_AlreadyInitialized();
        }
        if (initialOwner == address(0)) {
            revert Error_ZeroOwner();
        }

        _transferOwnership(initialOwner);
    }


    function stake(uint256 amount) external {
        if (amount == 0) return;

        uint256 accountBalance = balanceOf[msg.sender];
        uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
        uint256 totalSupply_ = totalSupply;
        uint256 rewardPerToken_ = _rewardPerToken(
            totalSupply_,
            lastTimeRewardApplicable_,
            rewardRate
        );

        rewardPerTokenStored = rewardPerToken_;
        lastUpdateTime = lastTimeRewardApplicable_;
        rewards[msg.sender] = _earned(
            msg.sender,
            accountBalance,
            rewardPerToken_,
            rewards[msg.sender]
        );
        userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

        totalSupply = totalSupply_ + amount;
        balanceOf[msg.sender] = accountBalance + amount;

        TransferHelper.safeTransferFrom(stakeToken(), msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) return;

        uint256 accountBalance = balanceOf[msg.sender];
        uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
        uint256 totalSupply_ = totalSupply;
        uint256 rewardPerToken_ = _rewardPerToken(
            totalSupply_,
            lastTimeRewardApplicable_,
            rewardRate
        );

        rewardPerTokenStored = rewardPerToken_;
        lastUpdateTime = lastTimeRewardApplicable_;
        rewards[msg.sender] = _earned(
            msg.sender,
            accountBalance,
            rewardPerToken_,
            rewards[msg.sender]
        );
        userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

        balanceOf[msg.sender] = accountBalance - amount;

        // total supply has 1:1 relationship with staked amounts
        // so can't ever underflow
        unchecked {
            totalSupply = totalSupply_ - amount;
        }

        TransferHelper.safeTransfer(stakeToken(), msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        uint256 accountBalance = balanceOf[msg.sender];

        uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
        uint256 totalSupply_ = totalSupply;
        uint256 rewardPerToken_ = _rewardPerToken(
            totalSupply_,
            lastTimeRewardApplicable_,
            rewardRate
        );

        uint256 reward = _earned(
            msg.sender,
            accountBalance,
            rewardPerToken_,
            rewards[msg.sender]
        );
        if (reward > 0) {
            rewards[msg.sender] = 0;
        }

        rewardPerTokenStored = rewardPerToken_;
        lastUpdateTime = lastTimeRewardApplicable_;
        userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

        balanceOf[msg.sender] = 0;

        // total supply has 1:1 relationship with staked amounts
        // so can't ever underflow
        unchecked {
            totalSupply = totalSupply_ - accountBalance;
        }

        TransferHelper.safeTransfer(stakeToken(), msg.sender, accountBalance);
        emit Withdrawn(msg.sender, accountBalance);

        if (reward > 0) {
            TransferHelper.safeTransfer(rewardToken(), msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function getReward() external {
        uint256 accountBalance = balanceOf[msg.sender];
        uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
        uint256 totalSupply_ = totalSupply;
        uint256 rewardPerToken_ = _rewardPerToken(
            totalSupply_,
            lastTimeRewardApplicable_,
            rewardRate
        );

        uint256 reward = _earned(
            msg.sender,
            accountBalance,
            rewardPerToken_,
            rewards[msg.sender]
        );

        rewardPerTokenStored = rewardPerToken_;
        lastUpdateTime = lastTimeRewardApplicable_;
        userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

        if (reward > 0) {
            rewards[msg.sender] = 0;

            TransferHelper.safeTransfer(rewardToken(), msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function lastTimeRewardApplicable() public view returns (uint64) {
        return
            block.timestamp < periodFinish
                ? uint64(block.timestamp)
                : periodFinish;
    }

    function rewardPerToken() external view returns (uint256) {
        return
            _rewardPerToken(
                totalSupply,
                lastTimeRewardApplicable(),
                rewardRate
            );
    }


    function earned(address account) external view returns (uint256) {
        return
            _earned(
                account,
                balanceOf[account],
                _rewardPerToken(
                    totalSupply,
                    lastTimeRewardApplicable(),
                    rewardRate
                ),
                rewards[account]
            );
    }


    /// @notice Lets a reward distributor start a new reward period. The reward tokens must have already
    /// been transferred to this contract before calling this function. If it is called
    /// when a reward period is still active, a new reward period will begin from the time
    /// of calling this function, using the leftover rewards from the old reward period plus
    /// the newly sent rewards as the reward.
    /// @dev If the reward amount will cause an overflow when computing rewardPerToken, then
    /// this function will revert.
    /// @param reward The amount of reward tokens to use in the new reward period.
    function notifyRewardAmount(uint256 reward) external {
        if (reward == 0) return;

        if (!isRewardDistributor[msg.sender]) {
            revert Error_NotRewardDistributor();
        }


        uint256 rewardRate_ = rewardRate;
        uint64 periodFinish_ = periodFinish;
        uint64 lastTimeRewardApplicable_ = block.timestamp < periodFinish_
            ? uint64(block.timestamp)
            : periodFinish_;
        uint64 DURATION_ = DURATION();
        uint256 totalSupply_ = totalSupply;

        rewardPerTokenStored = _rewardPerToken(
            totalSupply_,
            lastTimeRewardApplicable_,
            rewardRate_
        );
        lastUpdateTime = lastTimeRewardApplicable_;

        uint256 newRewardRate;
        if (block.timestamp >= periodFinish_) {
            newRewardRate = reward / DURATION_;
        } else {
            uint256 remaining = periodFinish_ - block.timestamp;
            uint256 leftover = remaining * rewardRate_;
            newRewardRate = (reward + leftover) / DURATION_;
        }
        
        if (newRewardRate >= ((type(uint256).max / PRECISION) / DURATION_)) {
            revert Error_AmountTooLarge();
        }

        rewardRate = newRewardRate;
        lastUpdateTime = uint64(block.timestamp);
        periodFinish = uint64(block.timestamp + DURATION_);

        emit RewardAdded(reward);
    }

    function setRewardDistributor(
        address rewardDistributor,
        bool isRewardDistributor_
    ) external onlyOwner {
        isRewardDistributor[rewardDistributor] = isRewardDistributor_;
    }

    function _earned(
        address account,
        uint256 accountBalance,
        uint256 rewardPerToken_,
        uint256 accountRewards
    ) internal view returns (uint256) {
        return
            FullMath.mulDiv(
                accountBalance,
                rewardPerToken_ - userRewardPerTokenPaid[account],
                PRECISION
            ) + accountRewards;
    }

    function _rewardPerToken(
        uint256 totalSupply_,
        uint256 lastTimeRewardApplicable_,
        uint256 rewardRate_
    ) internal view returns (uint256) {
        if (totalSupply_ == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            FullMath.mulDiv(
                (lastTimeRewardApplicable_ - lastUpdateTime) * PRECISION,
                rewardRate_,
                totalSupply_
            );
    }

    function _getImmutableVariablesOffset()
        internal
        pure
        returns (uint256 offset)
    {
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
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

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
	/// @notice Transfers tokens from the targeted address to the given destination
	/// @notice Errors with 'STF' if transfer fails
	/// @param token The contract address of the token to be transferred
	/// @param from The originating address from which the tokens will be transferred
	/// @param to The destination address of the transfer
	/// @param value The amount to be transferred
	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(
				IERC20.transferFrom.selector,
				from,
				to,
				value
			)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"STF"
		);
	}

	/// @notice Transfers tokens from msg.sender to a recipient
	/// @dev Errors with ST if transfer fails
	/// @param token The contract address of the token which will be transferred
	/// @param to The recipient of the transfer
	/// @param value The value of the transfer
	function safeTransfer(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(
				IERC20.transfer.selector,
				to,
				value
			)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"ST"
		);
	}

	/// @notice Approves the stipulated contract to spend the given allowance in the given token
	/// @dev Errors with 'SA' if transfer fails
	/// @param token The contract address of the token to be approved
	/// @param to The target of the approval
	/// @param value The amount of the given token the target will be allowed to spend
	function safeApprove(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20.approve.selector, to, value)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"SA"
		);
	}

	/// @notice Transfers ETH to the recipient address
	/// @dev Fails with `STE`
	/// @param to The destination of the transfer
	/// @param value The value to be transferred
	function safeTransferETH(address to, uint256 value) internal {
		(bool success, ) = to.call{ value: value }(new bytes(0));
		require(success, "STE");
	}
}

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