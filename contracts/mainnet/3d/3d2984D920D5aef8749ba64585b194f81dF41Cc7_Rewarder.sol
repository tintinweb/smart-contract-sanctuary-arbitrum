/**
 *Submitted for verification at Arbiscan on 2023-06-12
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File boring-solidity/contracts/interfaces/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File boring-solidity/contracts/libraries/[email protected]

pragma solidity 0.6.12;

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_SYMBOL)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_NAME)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_DECIMALS)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to)
        internal
        view
        returns (uint256 amount)
    {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_BALANCE_OF, to)
        );
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: Transfer failed"
        );
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: TransferFrom failed"
        );
    }
}

// File contracts/Masterchef/IRewarder.sol

pragma solidity ^0.6.12;

interface IRewarder {
    using BoringERC20 for IERC20;

    function onArrayReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 arrayAmount,
        uint256 newLpAmount
    ) external;

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 arrayAmount
    ) external view returns (IERC20[] memory, uint256[] memory);
}

// File boring-solidity/contracts/libraries/[email protected]

pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// File boring-solidity/contracts/[email protected]

pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(
                newOwner != address(0) || renounce,
                "Ownable: zero address"
            );

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(
            msg.sender == _pendingOwner,
            "Ownable: caller != pending owner"
        );

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File contracts/Masterchef/Rewarder.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IMasterChef {
    function lpToken(uint256 pid) external view returns (IERC20 _lpToken);
}

contract Rewarder is IRewarder, BoringOwnable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    IERC20 public rewardToken;

    /// @notice Info of each Rewarder user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of Reward Token entitled to the user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice Info of the rewarder pool
    struct PoolInfo {
        uint128 accToken1PerShare;
        uint64 lastRewardBlock;
    }

    /// @notice Mapping to track the rewarder pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    /// @notice Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public rewardPerBlock;
    IERC20 public masterLpToken;
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    address public immutable MASTERCHEF;

    event LogOnReward(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardBlock,
        uint256 lpSupply,
        uint256 accToken1PerShare
    );
    event LogRewardPerBlock(uint256 rewardPerBlock);
    event LogSetReward(IERC20 indexed rewardToken);
    event LogSetMasterLP(IERC20 indexed masterLpToken);
    event LogInit(
        IERC20 indexed rewardToken,
        address owner,
        uint256 rewardPerBlock,
        IERC20 indexed masterLpToken
    );

    constructor(
        address _MASTERCHEF,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        IERC20 _masterLpToken
    ) public {
        require(_rewardToken != IERC20(0), "Rewarder: bad token");
        require(_masterLpToken != IERC20(0), "Rewarder: bad master lp");
        MASTERCHEF = _MASTERCHEF;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        masterLpToken = _masterLpToken;
        owner = msg.sender;
        LogInit(rewardToken, msg.sender, rewardPerBlock, masterLpToken);
    }

    /// @notice Set the master lp token
    /// @dev `_masterLpToken` is the lp on which this rewarder will give rewards
    function setMasterLpToken(IERC20 _masterLpToken) public onlyOwner {
        masterLpToken = _masterLpToken;
        require(masterLpToken != IERC20(0), "Rewarder: bad token");
        emit LogSetMasterLP(masterLpToken);
    }

    /// @notice Set the rewarder token.
    /// @param _rewardToken The token to use for rewards.
    function setRewardToken(IERC20 _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
        require(rewardToken != IERC20(0), "Rewarder: bad token");
        emit LogSetReward(rewardToken);
    }

    function onArrayReward(
        uint256 pid,
        address _user,
        address to,
        uint256,
        uint256 lpTokenAmount
    ) external override onlyMC {
        require(IMasterChef(MASTERCHEF).lpToken(pid) == masterLpToken);

        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][_user];
        uint256 pending;
        if (user.amount > 0) {
            pending = (user.amount.mul(pool.accToken1PerShare) /
                ACC_TOKEN_PRECISION).sub(user.rewardDebt);
            rewardToken.safeTransfer(to, pending);
        }
        user.amount = lpTokenAmount;
        user.rewardDebt =
            lpTokenAmount.mul(pool.accToken1PerShare) /
            ACC_TOKEN_PRECISION;
        emit LogOnReward(_user, pid, pending, to);
    }

    function pendingTokens(
        uint256 pid,
        address user,
        uint256
    )
        external
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingToken(pid, user);
        return (_rewardTokens, _rewardAmounts);
    }

    function rewardRates() external view returns (uint256[] memory) {
        uint256[] memory _rewardRates = new uint256[](1);
        _rewardRates[0] = rewardPerBlock;
        return (_rewardRates);
    }

    /// @notice Sets the array per block to be distributed. Can only be called by the owner.
    /// @param _rewardPerBlock The amount of Array to be distributed per block.
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit LogRewardPerBlock(_rewardPerBlock);
    }

    modifier onlyMC() {
        require(msg.sender == MASTERCHEF, "Only MC can call this function.");
        _;
    }

    /// @notice View function to see pending Token
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending ARRAY reward for a given user.
    function pendingToken(uint256 _pid, address _user)
        public
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accToken1PerShare = pool.accToken1PerShare;
        uint256 lpSupply = IMasterChef(MASTERCHEF).lpToken(_pid).balanceOf(
            MASTERCHEF
        );
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number.sub(pool.lastRewardBlock);
            uint256 arrayReward = blocks.mul(rewardPerBlock);
            accToken1PerShare = accToken1PerShare.add(
                arrayReward.mul(ACC_TOKEN_PRECISION) / lpSupply
            );
        }
        pending = (user.amount.mul(accToken1PerShare) / ACC_TOKEN_PRECISION)
            .sub(user.rewardDebt);
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = IMasterChef(MASTERCHEF).lpToken(pid).balanceOf(
                MASTERCHEF
            );

            if (lpSupply > 0) {
                uint256 time = block.number.sub(pool.lastRewardBlock);
                uint256 arrayReward = time.mul(rewardPerBlock);
                pool.accToken1PerShare = pool.accToken1PerShare.add(
                    (arrayReward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128()
                );
            }
            pool.lastRewardBlock = block.number.to64();
            poolInfo[pid] = pool;
            emit LogUpdatePool(
                pid,
                pool.lastRewardBlock,
                lpSupply,
                pool.accToken1PerShare
            );
        }
    }

    /**
     * When tokens are sent to the sale by mistake: withdraw the specified token.
     */
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "Withdrawable: amount should be greater than zero");
        IERC20(token).safeTransfer(owner, amount);
    }
}