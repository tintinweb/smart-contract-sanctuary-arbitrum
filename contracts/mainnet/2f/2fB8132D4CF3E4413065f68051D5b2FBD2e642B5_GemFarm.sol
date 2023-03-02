/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'e0');
        (bool success,) = recipient.call{value : amount}('');
        require(success, 'e1');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'e0');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'e0');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'e0');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'e0');
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, 'e0');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'e1');
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: not owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

interface CakeToken {
    function mint(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract GemFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accCakePerShare;
        uint256 staking_stock_length;
        uint256 multiple;
        bool if_invite_reward;
        bool pool_status;
    }

    CakeToken public cake;
    PoolInfo[] public poolInfo;

    address public devAddress;
    uint256 public cakePerBlock;
    uint256 public stakingFee = 0;
    uint256 public withdrawFee = 0;
    uint256 public inviteFee = 0;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => mapping(address => uint256)) public first_staking_time;
    mapping(uint256 => mapping(address => uint256)) public last_staking_time;
    mapping(address => address) public invitor;
    mapping(address => bool) public is_invitor;
    mapping(uint256 => mapping(address => uint256)) public pending_list;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() {
        devAddress = _msgSender();
        startBlock = block.number + (10 * 365 * 24 * 60 * 60);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add( 
        IERC20 _lpToken, 
        uint256 _allocPoint,
        uint256 _multiple,
        uint256 _staking_stock_length, 
        bool _if_invite_reward,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                multiple: _multiple,
                lastRewardBlock: lastRewardBlock,
                accCakePerShare: 0,
                staking_stock_length: _staking_stock_length,
                if_invite_reward: _if_invite_reward,
                pool_status: true
            })
        );
    }

    function set(
        uint256 _pid, 
        uint256 _allocPoint, 
        uint256 _multiple,
        uint256 _staking_stock_length, 
        bool _if_invite_reward,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].multiple = _multiple;
        poolInfo[_pid].staking_stock_length = _staking_stock_length;
        poolInfo[_pid].if_invite_reward = _if_invite_reward;
    }

    function getMultiplier(uint256 _from, uint256 _to, uint256 _poolMultiple) public pure returns (uint256) {
        return (_to - _from) * _poolMultiple;
    }

    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, pool.multiple);
            uint256 cakeReward = multiplier * cakePerBlock * pool.allocPoint / totalAllocPoint;
            accCakePerShare = accCakePerShare + (cakeReward * 1e12 / lpSupply);
        }
        uint256 reward = user.amount * accCakePerShare / 1e12 - user.rewardDebt + pending_list[_pid][_user];
        if (pool.if_invite_reward) {
            uint256 fee = reward * inviteFee / 100;
            return reward - fee;
        }
        return reward;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, pool.multiple);
        uint256 cakeReward = multiplier * cakePerBlock * pool.allocPoint / totalAllocPoint;
        if (cakeReward > 0) {
            cake.mint(address(this), cakeReward);
        }

        pool.accCakePerShare = pool.accCakePerShare + (cakeReward * 1e12 / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount, address _invitor) public nonReentrant {
        require(poolInfo[_pid].pool_status, 'not open');

        address account = _msgSender();
        if (first_staking_time[_pid][account] == 0) {
            first_staking_time[_pid][account] = block.timestamp;
        }
        if (invitor[account] == address(0) && _invitor != address(0) && _invitor != account && !is_invitor[account]) {
            invitor[account] = _invitor;
            is_invitor[_invitor] = true;
        }
        last_staking_time[_pid][account] = block.timestamp;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][account];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accCakePerShare / 1e12 - user.rewardDebt;
            if (pending > 0) {
                pending_list[_pid][account] = pending_list[_pid][account] + pending;
            }
        }
        if (_amount > 0) {
            uint256 fee = _amount * stakingFee / 100;
            uint256 left = _amount - fee;
            if (fee > 0) {
                pool.lpToken.safeTransferFrom(account, devAddress, fee);
            }
            pool.lpToken.safeTransferFrom(account, address(this), left);
            user.amount = user.amount + left;
        }
        user.rewardDebt = user.amount * pool.accCakePerShare / 1e12;
        emit Deposit(account, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        address account = _msgSender();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][account];
        require(user.amount >= _amount, "no more");
        updatePool(_pid);

        uint256 pending = user.amount * pool.accCakePerShare / 1e12 - user.rewardDebt;
        if (pending > 0) {
            pending_list[_pid][account] = pending_list[_pid][account] + pending;
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            uint256 fee = _amount * withdrawFee / 100;
            uint256 left = _amount - fee;
            if (fee > 0) {
                pool.lpToken.safeTransfer(devAddress, fee);
            }
            pool.lpToken.safeTransfer(account, left);
        }
        user.rewardDebt = user.amount * pool.accCakePerShare / 1e12;
        emit Withdraw(account, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        address account = _msgSender();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][account];
        require(user.amount > 0, "no deposit");

        uint256 fee = user.amount * withdrawFee / 100;
        uint256 left = user.amount - fee;
        if (fee > 0) {
            pool.lpToken.safeTransfer(devAddress, fee);
        }
        pool.lpToken.safeTransfer(account, left);
        user.amount = 0;
        user.rewardDebt = 0;
        pending_list[_pid][account] = 0;
        emit EmergencyWithdraw(account, _pid, left);
    }

    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        return
            block.number >= startBlock &&
            block.timestamp > last_staking_time[_pid][_user] + poolInfo[_pid].staking_stock_length;
    }

    function harvest(uint256 _pid) public nonReentrant isHuman {
        address account = _msgSender();
        require(canHarvest(_pid, account), 'time limit');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][account];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accCakePerShare / 1e12 - user.rewardDebt;
            if (pending > 0) {
                pending_list[_pid][account] = pending_list[_pid][account] + pending;
            }
        }
        user.rewardDebt = user.amount * pool.accCakePerShare / 1e12;


        uint256 reward = pending_list[_pid][account];
        require(reward > 0, 'no rewards');

        pending_list[_pid][account] = 0;
        if (pool.if_invite_reward) {
            uint256 fee = reward * inviteFee / 100;
            if (fee > 0) {
                if (invitor[account] == address(0)) {
                    safeCakeTransfer(devAddress, fee);
                } else {
                    safeCakeTransfer(invitor[account], fee);
                }
            }
            reward = reward - fee;
            safeCakeTransfer(account, reward);
        } else {
            safeCakeTransfer(account, reward);
        }
        emit Harvest(account, _pid, reward);
    }

    function safeCakeTransfer(address _to, uint256 _amount) internal {
        uint256 cakeBal = cake.balanceOf(address(this));
        if (_amount > cakeBal) {
            cake.transfer(_to, cakeBal);
        } else {
            cake.transfer(_to, _amount);
        }
    }

    function startFarming() public onlyOwner {
        require(block.number < startBlock, "farm started already");

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid].lastRewardBlock = block.number;
        }

        startBlock = block.number;
    }

    function setPoolState(uint256 _pid, bool _state) public onlyOwner {
        poolInfo[_pid].pool_status = _state;
    }

    function setFees(uint256 _stakingFee, uint256 _withdrawFee, uint256 _inviteFee) public onlyOwner {
        require(_stakingFee < 50 && _withdrawFee < 50 && _inviteFee < 50, 'too high');
        stakingFee = _stakingFee;
        withdrawFee = _withdrawFee;
        inviteFee = _inviteFee;
    }

    function setCake(CakeToken _cake, uint256 _cakePerBlock) public onlyOwner {
        cake = _cake;
        cakePerBlock = _cakePerBlock;
    }

    function setdev(address _devaddr) public {
        require(_msgSender() == devAddress || _msgSender() == owner(), "cannot");
        devAddress = _devaddr;
    }
}