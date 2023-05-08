/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IUniswapRouter{
    function WETH() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IReferral{
    function setReferrer(address _user, address _referrer) external;
    function getReferrer(address _user) external view returns (address);
}

interface IBurnable {
    function burn(uint256 amount) external;
}

contract XarbFinanceGenesisRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // SushiSwap Router to be used for buyback
    IUniswapRouter public constant router = IUniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    uint256 public constant MAX_UINT256 = ~uint256(0);

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. XARB to distribute.
        uint256 lastRewardTime; // Last time that XARB distribution occurs.
        uint256 accXarbPerShare; // Accumulated XARB per share, times 1e18. See below.
        bool isStarted; // if lastRewardBlock has passed
        uint256 depositFeeBP; // deposit fee 0% ~ 2%
        bool isLPtoken; // if token is lp token
    }

    IERC20 public xarb;
    IReferral public referral;
    address public treasuryFund;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when XARB mining starts.
    uint256 public poolStartTime;

    // The time when XARB mining ends.
    uint256 public poolEndTime;

    // MAINNET
    uint256 public xarbPerSecond = 0.0462963 ether; // 20000 XARB / (5 * 24h * 60min * 60s)
    uint256 public runningTime = 5 days; // 5 days
    uint256 public constant TOTAL_REWARDS = 20000 ether;
    // END MAINNET

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event ReferrerReward(address indexed token, address sender, address referrer, uint256 amount);

    constructor(
        address _xarb,
        uint256 _poolStartTime,
        address _initializer
    ) {
        require(block.timestamp < _poolStartTime, "late");
        if (_xarb != address(0)) xarb = IERC20(_xarb);
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        operator = _initializer;
        treasuryFund = _initializer;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "XarbGenesisPool: caller is not the operator");
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "XarbGenesisPool: existing pool?");
        }
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFeeBP,
        bool _isLPtoken
    ) public onlyOperator {
        require(_depositFeeBP <= 200, "add: deposit fee can not exceed 2%");
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accXarbPerShare : 0,
            isStarted : _isStarted,
            depositFeeBP: _depositFeeBP,
            isLPtoken: _isLPtoken
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
        _token.approve(address(router), MAX_UINT256);
    }

    // Update the given pool's XARB allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFeeBP) public onlyOperator {
        require(_depositFeeBP <= 200, "add: deposit fee can not exceed 2%");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(xarbPerSecond);
            return poolEndTime.sub(_fromTime).mul(xarbPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(xarbPerSecond);
            return _toTime.sub(_fromTime).mul(xarbPerSecond);
        }
    }

    // View function to see pending XARB on frontend.
    function pendingXARB(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accXarbPerShare = pool.accXarbPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _xarbReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accXarbPerShare = accXarbPerShare.add(_xarbReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accXarbPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _xarbReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accXarbPerShare = pool.accXarbPerShare.add(_xarbReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    function feeDistribute(
        PoolInfo memory _pool,
        uint256 _feeAmount,
        address _sender,
        address _referrer
    ) internal {
        uint256 feeToReferrer = _feeAmount.div(4); // 0.5% max
        if (feeToReferrer > 0) {
            address referrer = referral.getReferrer(_sender);
            if (referrer == address(0)) {
                if (_referrer != address(0)) {
                    referral.setReferrer(_sender, _referrer);
                    _pool.token.safeTransfer(_referrer, feeToReferrer);
                    emit ReferrerReward(address(_pool.token), _sender, _referrer, feeToReferrer);
                } else {
                    _pool.token.safeTransfer(treasuryFund, feeToReferrer);
                }
            } else {
                _pool.token.safeTransfer(referrer, feeToReferrer);
                emit ReferrerReward(address(_pool.token), _sender, referrer, feeToReferrer);
            }
        }

        uint256 feeToBuyBack = _feeAmount.div(4); // 0.5% max
        if (feeToBuyBack > 0) {
            if (_pool.isLPtoken) {
                _pool.token.safeTransfer(treasuryFund, feeToBuyBack);
            } else {
                address[] memory path;
                if (address(_pool.token) == router.WETH()) {
                    path = new address[](2);
                    path[0] = address(_pool.token);
                    path[1] = address(xarb);
                } else {
                    path = new address[](3);
                    path[0] = address(_pool.token);
                    path[1] = router.WETH();
                    path[2] = address(xarb);
                }
                uint256 balanceBefore = xarb.balanceOf(address(this));
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    feeToBuyBack,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                uint256 amountToBurn = xarb.balanceOf(address(this)).sub(balanceBefore);
                IBurnable(address(xarb)).burn(amountToBurn);
            }
        }

        uint256 feeToTreasuryFund = _feeAmount.sub(feeToReferrer).sub(feeToBuyBack);
        if (feeToTreasuryFund > 0) {
            _pool.token.safeTransfer(treasuryFund, feeToTreasuryFund);
        }
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accXarbPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeXarbTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);

            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                feeDistribute(pool, depositFee, _sender, _referrer);
                user.amount = user.amount.sub(depositFee);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accXarbPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accXarbPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeXarbTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accXarbPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe XARB transfer function, just in case if rounding error causes pool to not have enough XARBs.
    function safeXarbTransfer(address _to, uint256 _amount) internal {
        uint256 _xarbBalance = xarb.balanceOf(address(this));
        if (_xarbBalance > 0) {
            if (_amount > _xarbBalance) {
                xarb.safeTransfer(_to, _xarbBalance);
            } else {
                xarb.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setReferral(address _referral) external onlyOperator {
        referral = IReferral(_referral);
    }

    function setTreasuryFund(address _treasuryFund) public{
        require(msg.sender == treasuryFund, "setTreasuryFund: FORBIDDEN");
        require(_treasuryFund != address(0), "setTreasuryFund: ZERO");
        treasuryFund = _treasuryFund;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (XARB or lps) if less than 90 days after pool ends
            require(_token != xarb, "xarb");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }
}