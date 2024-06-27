// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EraOfExplorersStake is Ownable {
    struct PoolData {
        uint256 stakeTime; // stake time seconds
        uint256 yieldRate; // apy X100
        uint256 refundRate; // early exit return rate X100
        uint256 halfRate; // yield half rate
    }

    struct StakeData {
        address owner; // account address
        uint256 stakeId; // stake id
        uint256 poolId; // poolId
        uint256 amount; // EST stake amount
        uint256 startTime; // stake start timestamp
        uint256 releaseTime; // release timestamp
    }

    event SetPool(uint256 poolId, uint256 stakeTime, uint256 yieldRate, uint256 refundRate, uint256 halfRate);
    event Stake(address account, uint256 poolId, uint256 stakeId, uint256 estAmount, uint256 releaseTime);
    event Unstake(
        address account,
        uint256 poolId,
        uint256 stakeId,
        uint256 stakeAmount,
        uint256 estAmount,
        uint256 eoeAmount
    );

    IERC20 public estToken; // stake token
    IERC20 public eoeToken; // yield token
    uint256 private _lastStakeId = 1;
    uint256 public constant MIN_AMOUNT = 100000 * 1e8;
    uint256 public constant DAYS_SECONDS = 86400;
    uint256 public yearSeconds = DAYS_SECONDS * 365; // 365days

    // poolId => PoolData
    mapping(uint256 => PoolData) public pools;

    // address => stakeId list
    mapping(address => uint256[]) private _stakeIds;
    // stakeId => StakeData
    mapping(uint256 => StakeData) public stakes;

    constructor(address _initOwner, address _estToken, address _eoeToken) Ownable(_initOwner) {
        require(_estToken != address(0), "invalid EST token");
        require(_eoeToken != address(0), "invalid EOE token");

        estToken = IERC20(_estToken);
        eoeToken = IERC20(_eoeToken);
    }

    function setEstToken(address _estToken) external onlyOwner {
        require(_estToken != address(0), "invalid EST token");
        estToken = IERC20(_estToken);
    }

    function setEoeToken(address _eoeToken) external onlyOwner {
        require(_eoeToken != address(0), "invalid EOE token");
        eoeToken = IERC20(_eoeToken);
    }

    function setPool(
        uint256 _poolId,
        uint256 _stakeTime,
        uint256 _yieldRate,
        uint256 _refundRate,
        uint256 _halfRate
    ) external onlyOwner {
        require(_poolId == 30 || _poolId == 90 || _poolId == 180, "invalid poolId");
        require(_stakeTime > 0, "invalid stakeTime");
        require(_yieldRate > 0 && _yieldRate <= 10000, "invalid yieldRate");
        require(_refundRate > 0 && _refundRate <= 10000, "invalid refundRate");
        require(_halfRate > 0 && _halfRate <= 100, "invalid refundRate");

        pools[_poolId] = PoolData({
            stakeTime: _stakeTime,
            yieldRate: _yieldRate,
            refundRate: _refundRate,
            halfRate: _halfRate
        });

        emit SetPool(_poolId, _stakeTime, _yieldRate, _refundRate, _halfRate);
    }

    function stake(uint256 _poolId, uint256 _amount) external {
        require(_poolId == 30 || _poolId == 90 || _poolId == 180, "invalid poolId");
        PoolData memory _pool = pools[_poolId];
        require(_pool.yieldRate > 0, "invalid stakePool");
        require(_amount >= MIN_AMOUNT, "invalid amount");

        uint256 _balance = estToken.balanceOf(msg.sender);
        require(_balance >= _amount, "EST Token insufficient balance");

        bool ok = estToken.transferFrom(msg.sender, address(this), _amount);
        require(ok, "EST Token transfer failed");

        uint256 _stakeId = _lastStakeId++;
        _stakeIds[msg.sender].push(_stakeId);
        uint256 _releaseTime = block.timestamp + _pool.stakeTime;
        stakes[_stakeId] = StakeData({
            owner: msg.sender,
            stakeId: _stakeId,
            poolId: _poolId,
            amount: _amount,
            startTime: block.timestamp,
            releaseTime: _releaseTime
        });

        emit Stake(msg.sender, _poolId, _stakeId, _amount, _releaseTime);
    }

    function unstake(uint256 _stakeId) external {
        require(_stakeId > 0, "invalid stakeId");
        StakeData storage _stake = stakes[_stakeId];
        require(_stake.amount > 0, "invalid stakes");
        require(_stake.owner == msg.sender, "invalid owner");
        uint256 _poolId = _stake.poolId;

        PoolData memory _pool = pools[_stake.poolId];
        require(_pool.yieldRate > 0, "invalid pool");

        uint256 _stakeAmount = _stake.amount;
        uint256 _estAmount;
        uint256 _yieldAmt;

        if (block.timestamp < _stake.releaseTime) {
            uint256 _pastTime = block.timestamp - _stake.startTime;
            _yieldAmt = (_stakeAmount * _pool.yieldRate * _pastTime) / yearSeconds / 100;
            _yieldAmt = _yieldAmt / _pool.halfRate;
            _estAmount = (_stakeAmount * _pool.refundRate) / 100;
        } else {
            _yieldAmt = (_stakeAmount * _pool.yieldRate * _pool.stakeTime) / yearSeconds / 100;
            _estAmount = _stakeAmount;
        }

        uint256[] storage stakeIds_ = _stakeIds[msg.sender];
        for (uint256 i = 0; i < stakeIds_.length - 1; i++) {
            if (stakeIds_[i] == _stakeId) {
                stakeIds_[i] = stakeIds_[stakeIds_.length - 1];
            }
        }
        stakeIds_.pop();

        delete stakes[_stakeId];

        require(_estAmount > 0, "EST Amount is zero");
        bool ok = estToken.transfer(msg.sender, _estAmount);
        require(ok, "EST Token transfer failed");

        if (_yieldAmt > 0) {
            eoeToken.transfer(msg.sender, _yieldAmt);
        }

        emit Unstake(msg.sender, _poolId, _stakeId, _stakeAmount, _estAmount, _yieldAmt);
    }

    function getStakeIds(address _owner) public view returns (uint256[] memory) {
        uint256[] memory stakeIds_ = _stakeIds[_owner];
        return stakeIds_;
    }

    function getStakeDates(address _owner) external view returns (StakeData[] memory) {
        uint256[] memory stakeIds_ = getStakeIds(_owner);
        StakeData[] memory _stakeDatas = new StakeData[](stakeIds_.length);
        for (uint256 i = 0; i < stakeIds_.length; i++) {
            StakeData memory _stakeData = stakes[stakeIds_[i]];
            _stakeDatas[i] = _stakeData;
        }
        return _stakeDatas;
    }

    function withdraw(address _contAddr) external onlyOwner {
        require(_contAddr != address(0), "invalid contract address");
        if (_contAddr == address(1)) {
            uint256 _balance = address(this).balance;
            require(_balance > 0, "insufficient amount");
            payable(msg.sender).transfer(_balance);
        } else {
            IERC20 _erc20 = IERC20(_contAddr);
            uint256 _balance = _erc20.balanceOf(address(this));
            require(_balance > 0, "insufficient amount");
            _erc20.transfer(msg.sender, _balance);
        }
    }

    receive() external payable {}

    fallback() external payable {}
}