// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TowerPool.sol";

contract TowerPoolFactory is Ownable {
    mapping(address => address) public towerPools; // token => TowerPool
    mapping(address => address) public tokenForTowerPool; // TowerPool => token
    mapping(address => bool) public isTowerPool;
    address[] public allTowerPools;

    event TowerPoolCreated(
        address indexed towerPool,
        address creator,
        address indexed token
    );
    event Deposit(
        address indexed token,
        address indexed towerPool,
        uint256 amount
    );
    event Withdraw(
        address indexed token,
        address indexed towerPool,
        uint256 amount
    );
    event NotifyReward(
        address indexed sender,
        address indexed reward,
        uint256 amount
    );
    
    function emitDeposit(
        address account,
        uint256 amount
    ) external {
        require(isTowerPool[msg.sender]);
        emit Deposit(account, msg.sender, amount);
    }

    function emitWithdraw(
        address account,
        uint256 amount
    ) external {
        require(isTowerPool[msg.sender]);
        emit Withdraw(account, msg.sender, amount);
    }

    function allTowerPoolsLength() external view returns (uint256) {
        return allTowerPools.length;
    }

    function createTowerPool(address _stake, address[] memory _allowedRewardTokens)
        external
        onlyOwner
        returns (address towerPool)
    {
        require(
            towerPools[_stake] == address(0),
            "TowerPoolFactory: POOL_EXISTS"
        );
        bytes memory bytecode = type(TowerPool).creationCode;
        assembly {
            towerPool := create2(0, add(bytecode, 32), mload(bytecode), _stake)
        }
        TowerPool(towerPool)._initialize(
            _stake,
            _allowedRewardTokens
        );
        towerPools[_stake] = towerPool;
        tokenForTowerPool[towerPool] = _stake;
        isTowerPool[towerPool] = true;
        allTowerPools.push(towerPool);
        emit TowerPoolCreated(towerPool, msg.sender, _stake);
    }

    function claimRewards(
        address[] memory _towerPools,
        address[][] memory _tokens
    ) external {
        for (uint256 i = 0; i < _towerPools.length; i++) {
            TowerPool(_towerPools[i]).getReward(msg.sender, _tokens[i]);
        }
    }
    
    function whitelistTowerPoolRewards(
        address[] calldata _towerPools,
        address[] calldata _rewards
    ) external onlyOwner {
        uint len = _towerPools.length;
        for (uint i; i < len; ++i) {
            TowerPool(_towerPools[i]).whitelistNotifiedRewards(_rewards[i]);
        }
    }

    function removeTowerPoolRewards(
        address[] calldata _towerPools,
        address[] calldata _rewards
    ) external onlyOwner {
        uint len = _towerPools.length;
        for (uint i; i < len; ++i) {
            TowerPool(_towerPools[i]).removeRewardWhitelist(_rewards[i]);
        }
    }

    struct TowerPoolInfo {
      address towerPool;
      address tokenForTowerPool;
      TowerPool.RewardInfo[] rewardInfoList;
      uint256 totalSupply;
      uint256 accountBalance;
      uint256[] earnedList;
    }

    function getInfoForAllTowerPools(address account) external view returns (TowerPoolInfo[] memory towerPoolInfoList) {
        uint256 len = allTowerPools.length;
        towerPoolInfoList = new TowerPoolInfo[](len);

        for (uint256 i = 0; i < len; i++) {
            address towerPoolAddress = allTowerPools[i];
            TowerPool towerPool = TowerPool(towerPoolAddress);
            towerPoolInfoList[i].totalSupply = towerPool.totalSupply();
            towerPoolInfoList[i].accountBalance = towerPool.balanceOf(account);
            towerPoolInfoList[i].towerPool = towerPoolAddress;
            towerPoolInfoList[i].tokenForTowerPool = towerPool.stake();
            towerPoolInfoList[i].rewardInfoList = towerPool.getRewardInfoList();
            towerPoolInfoList[i].earnedList = towerPool.earned(account);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IERC20.sol";

interface ITowerPoolFactory {
    function emitDeposit(address account, uint256 amount) external;

    function emitWithdraw(address account, uint256 amount) external;
}

// TowerPools are used for rewards, they emit reward tokens over 7 days for staked tokens
contract TowerPool {
    address public stake; // the token that needs to be staked for rewards
    address public factory; // the TowerPoolFactory

    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal constant PRECISION = 10 ** 18;

    mapping(address => uint256) public pendingRewardRate;
    mapping(address => bool) public isStarted;
    mapping(address => uint256) public rewardRate;
    mapping(address => uint256) public periodFinish;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewardPerTokenStored;
    mapping(address => mapping(address => uint256)) public storedRewardsPerUser;

    mapping(address => mapping(address => uint256))
        public userRewardPerTokenStored;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address[] public rewards;
    mapping(address => bool) public isReward;

    uint256 internal _unlocked;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed from, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );

    struct RewardInfo {
      address towerPool;
      address rewardTokenAddress;
      string rewardTokenSymbol;
      uint256 rewardTokenDecimals;
      uint256 periodFinish;
      uint256 rewardRate;
      uint256 lastUpdateTime;
      uint256 rewardPerTokenStored;
      uint256 pendingReward;
      uint256 reinvestBounty;
      bool isStarted;
    }

    function _initialize(
        address _stake,
        address[] memory _allowedRewardTokens
    ) external {
        require(factory == address(0), "TowerPool: FACTORY_ALREADY_SET");
        factory = msg.sender;
        stake = _stake;

        for (uint256 i; i < _allowedRewardTokens.length; ++i) {
            if (_allowedRewardTokens[i] != address(0)) {
                rewards.push(_allowedRewardTokens[i]);
                isReward[_allowedRewardTokens[i]] = true;
            }
        }

        _unlocked = 1;
    }

    // simple re-entrancy check
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function rewardsListLength() external view returns (uint256) {
        return rewards.length;
    }

    // returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable(
        address token
    ) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish[token]);
    }

    function earned(address account) external view returns (uint256[] memory earnedList) {
        uint256 len = rewards.length;
        earnedList = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            earnedList[i] = earned(rewards[i], account);
        }
    }

    function earned(
        address token,
        address account
    ) public view returns (uint256) {
        return
            (balanceOf[account] *
                (rewardPerToken(token) -
                    userRewardPerTokenStored[account][token])) /
            PRECISION +
            storedRewardsPerUser[account][token];
    }

    // Only the tokens you claim will get updated.
    function getReward(address account, address[] memory tokens) public lock {
        require(msg.sender == account || msg.sender == factory);

        // update all user rewards regardless of tokens they are claiming
        address[] memory _rewards = rewards;
        uint256 len = _rewards.length;
        for (uint256 i; i < len; ++i) {
            if (isReward[_rewards[i]]) {
                if (!isStarted[_rewards[i]]) {
                    initializeRewardsDistribution(_rewards[i]);
                }
                updateRewardPerToken(_rewards[i], account);
            }
        }
        // transfer only the rewards they are claiming
        len = tokens.length;
        for (uint256 i; i < len; ++i){
            uint256 _reward = storedRewardsPerUser[account][tokens[i]];
            if (_reward > 0) {
                storedRewardsPerUser[account][tokens[i]] = 0;
                _safeTransfer(tokens[i], account, _reward);
                emit ClaimRewards(account, tokens[i], _reward);
            }        
        }
    }

    function rewardPerToken(address token) public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored[token];
        }
        return
            rewardPerTokenStored[token] +
            (((lastTimeRewardApplicable(token) -
                Math.min(lastUpdateTime[token], periodFinish[token])) *
                rewardRate[token] *
                PRECISION) / totalSupply);
    }

    function depositAll() external {
        deposit(IERC20(stake).balanceOf(msg.sender));
    }

    function deposit(uint256 amount) public lock {
        require(amount > 0);

        address[] memory _rewards = rewards;
        uint256 len = _rewards.length;

        for (uint256 i; i < len; ++i) {
            if (!isStarted[_rewards[i]]) {
                initializeRewardsDistribution(_rewards[i]);
            }
            updateRewardPerToken(_rewards[i], msg.sender);
        }

        _safeTransferFrom(stake, msg.sender, address(this), amount);
        totalSupply += amount;
        balanceOf[msg.sender] += amount;

        ITowerPoolFactory(factory).emitDeposit(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function withdrawAll() external {
        withdraw(balanceOf[msg.sender]);
    }

    function withdraw(uint256 amount) public lock {
        require(amount > 0);

        address[] memory _rewards = rewards;
        uint256 len = _rewards.length;

        for (uint256 i; i < len; ++i) {
            updateRewardPerToken(_rewards[i], msg.sender);
        }

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        _safeTransfer(stake, msg.sender, amount);

        ITowerPoolFactory(factory).emitWithdraw(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function left(address token) external view returns (uint256) {
        if (block.timestamp >= periodFinish[token]) return 0;
        uint256 _remaining = periodFinish[token] - block.timestamp;
        return _remaining * rewardRate[token];
    }

    // @dev rewardRate and periodFinish is set on first deposit if totalSupply == 0 or first interaction after whitelisting.
    function notifyRewardAmount(address token, uint256 amount) external lock {
        require(token != stake);
        require(amount > 0);
        rewardPerTokenStored[token] = rewardPerToken(token);
        
        // Check actual amount transferred for compatibility with fee on transfer tokens.
        uint balanceBefore = IERC20(token).balanceOf(address(this));
        _safeTransferFrom(token, msg.sender, address(this), amount);
        uint balanceAfter = IERC20(token).balanceOf(address(this));
        amount = balanceAfter - balanceBefore;
        uint _rewardRate = amount / DURATION;

        if (isStarted[token]) {
            if (block.timestamp >= periodFinish[token]) {
                rewardRate[token] = _rewardRate;
            } else {
                uint256 _remaining = periodFinish[token] - block.timestamp;
                uint256 _left = _remaining * rewardRate[token];
                require(amount > _left);
                rewardRate[token] = (amount + _left) / DURATION;
            }
            periodFinish[token] = block.timestamp + DURATION;
            lastUpdateTime[token] = block.timestamp;
        } else {
            if (pendingRewardRate[token] > 0) {
                uint256 _left = DURATION * pendingRewardRate[token];
                pendingRewardRate[token] = (amount + _left) / DURATION;
            } else {
                pendingRewardRate[token] = _rewardRate;
            }
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(
            rewardRate[token] <= balance / DURATION,
            "Provided reward too high"
        );
        if (!isStarted[token]) {
            require(
                pendingRewardRate[token] <= balance / DURATION,
                "Provided reward too high"
            );
        }

        emit NotifyReward(msg.sender, token, amount);
    }

    function initializeRewardsDistribution(address token) internal {
        isStarted[token] = true;
        rewardRate[token] = pendingRewardRate[token];
        lastUpdateTime[token] = block.timestamp;
        periodFinish[token] = block.timestamp + DURATION;
        pendingRewardRate[token] = 0;
    }

    function whitelistNotifiedRewards(address token) external {
        require(msg.sender == factory);
        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }
        if (!isStarted[token] && totalSupply > 0) {
            initializeRewardsDistribution(token);
        }
    }

    function getRewardTokenIndex(address token) public view returns (uint256) {
        address[] memory _rewards = rewards;
        uint256 len = _rewards.length;

        for (uint256 i; i < len; ++i) {
            if (_rewards[i] == token) {
                return i;
            }
        }
        return 0;
    }

    function removeRewardWhitelist(address token) external {
        require(msg.sender == factory);
        if (!isReward[token]) {
            return;
        }
        isReward[token] = false;
        uint256 idx = getRewardTokenIndex(token);
        uint256 len = rewards.length;
        for (uint256 i = idx; i < len - 1; ++i) {
            rewards[i] = rewards[i + 1];
        }
        rewards.pop();
    }

    function poke(address account) external {
        // Update reward rates and user rewards
        for (uint256 i; i < rewards.length; ++i) {
            updateRewardPerToken(rewards[i], account);
        }
    }

    function updateRewardPerToken(address token, address account) internal {
        rewardPerTokenStored[token] = rewardPerToken(token);
        lastUpdateTime[token] = lastTimeRewardApplicable(token);
        storedRewardsPerUser[account][token] = earned(token, account);
        userRewardPerTokenStored[account][token] = rewardPerTokenStored[token];
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function removeExtraRewardToken(
        uint256 index,
        uint256 duplicateIndex
    ) external onlyFactoryOwner {
        require(index < duplicateIndex);
        require(rewards[index] == rewards[duplicateIndex]);

        uint len = rewards.length;
        for (uint i = duplicateIndex; i < len - 1; ++i) {
            rewards[i] = rewards[i + 1];
        }
        rewards.pop();
    }

    function getRewardInfoList() external view returns (RewardInfo[] memory rewardInfoList) {
        uint256 len = rewards.length;
        rewardInfoList = new RewardInfo[](len);

        for (uint256 i = 0; i < len; i++) {
            address rewardToken = rewards[i];
            RewardInfo memory rewardInfo = rewardInfoList[i];
            rewardInfo.towerPool = address(this);
            rewardInfo.rewardTokenAddress = rewardToken;
            rewardInfo.rewardTokenSymbol = IERC20(rewardToken).symbol();
            rewardInfo.rewardTokenDecimals = IERC20(rewardToken).decimals();
            rewardInfo.isStarted = isStarted[rewardToken];
            rewardInfo.rewardRate = rewardRate[rewardToken];
            rewardInfo.lastUpdateTime = lastUpdateTime[rewardToken];
            rewardInfo.periodFinish = periodFinish[rewardToken];
            rewardInfo.rewardPerTokenStored = rewardPerTokenStored[rewardToken];
        }
    }

    modifier onlyFactoryOwner() {
        require(Ownable(factory).owner() == msg.sender, "NOT_AUTHORIZED");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}