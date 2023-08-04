/**
 *Submitted for verification at Arbiscan on 2023-08-04
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
interface RewardsPool {
    function mint(uint256 amount, IERC20 token, address recipient) external;
}

contract DBYield is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }    
    struct PoolInfo {
        string name;
        IERC20 lpToken;
    }

    RewardsPool internal rewardsPool = RewardsPool(0xb6B72F2a5FF537C0F0B21580B2BD644325411094);
    IERC20 internal DBC = IERC20(0x745f63CA36E0cfDFAc4bf0AFe07120dC7e1E0042);
    IERC20 internal WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    uint256 internal minCap = 100000000000000000;
    uint256 internal maxCap = 2500000000000000000;
    uint256 internal rewardsPerSecond = 0;
    uint256 internal nextUpdate = 0;

    uint256 internal totalRewards = 0;
    uint256 internal accPerShare = 0;
    uint256 internal lastTimestamp = 0;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    mapping(address => UserInfo) internal userInfo;

    constructor() {
        _updateValues();
    }

    /* ---------- ReadFunctions ---------- */
    function getMinCap() public view returns(uint256) {
        return minCap;
    }
    function getMaxCap() public view returns(uint256) {
        return maxCap;
    }
    function getRewardsPerSecond() public view returns(uint256) {
        return rewardsPerSecond;
    }
    function getAccPerShare() public view returns(uint256) {
        return accPerShare;
    }
    function getLastTimestamp() public view returns(uint256) {
        return lastTimestamp;
    }
    function getUser(address _account) public view returns(UserInfo memory) {
        return userInfo[_account];
    }
    function getPool() public view returns(PoolInfo memory) {
        return PoolInfo("DBC", DBC);
    }
    function getTvl() public view returns(uint256) {
        return DBC.balanceOf(address(this));
    }

    /* ---------- WriteFunctions ---------- */
    function depositOnBehalf(uint256 _amount, address _account) onlyOwner public {
        _deposit(_amount, _account, msg.sender);
    }
    function withdrawOnBehalf(uint256 _amount, address _account) onlyOwner public {
        _withdraw(_amount, _account);
    }
    function emergencyWithdrawOnBehalf(address _account) onlyOwner public {
        _emergencyWithdraw(_account);
    }
    function setMinCap(uint256 _minCap) onlyOwner public {
        minCap = _minCap;
    }
    function setMaxCap(uint256 _maxCap) onlyOwner public {
        maxCap = _maxCap;
    }
    function forceUpdate() onlyOwner public {
        _updateValues();
    }
    function updateRewardsPool(RewardsPool _rewardsPool) onlyOwner public {
        rewardsPool = _rewardsPool;
    }

    /* ---------- InternalFunctions ---------- */
    function _updateValues() internal {
        uint256 lpSupply = DBC.balanceOf(address(this));
        if (lpSupply == 0) {
            lastTimestamp = block.timestamp;
        } else {
            uint256 secs = block.timestamp.sub(lastTimestamp);
            uint256 reward = secs.mul(rewardsPerSecond);
            totalRewards = totalRewards.add(reward);
            accPerShare = accPerShare.add(reward.mul(1e18).div(lpSupply));
            lastTimestamp = block.timestamp;
        }

        if (block.timestamp >= nextUpdate) {
            uint256 rewardsBalance = WETH.balanceOf(address(rewardsPool)).sub(totalRewards);
            if (rewardsBalance > maxCap) {
                rewardsPerSecond = maxCap.div(30).div(86400);
            } else if (rewardsBalance > minCap) {
                rewardsPerSecond = rewardsBalance.div(30).div(86400);
            } else {
                rewardsPerSecond = 0;
            }
            nextUpdate = block.timestamp + (86400 * 7);
        }
    }
    function _deposit(uint256 _amount, address _account, address _payee) internal {
        require(rewardsPerSecond > 0, "depositing disabled due to 0 rewards");
        UserInfo storage user = userInfo[_account];
        _updateValues();
        require(_amount > 0, "amount must be larger than 0");
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                totalRewards = totalRewards.sub(pending);
                rewardsPool.mint(pending, WETH, _account);
            }
        }
        require(DBC.balanceOf(_payee) >= _amount, "balance to low");
        require(DBC.allowance(_payee, address(this)) >= _amount, "amount not approved");
        DBC.transferFrom(_payee, address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accPerShare).div(1e18);
        emit Deposit(_account, _amount);
    }  
    function _withdraw(uint256 _amount, address _account) internal {
        UserInfo storage user = userInfo[_account];
        _updateValues();
        require(user.amount >= _amount, "amount is larger than staked balance");
        uint256 pending = user.amount.mul(accPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            totalRewards = totalRewards.sub(pending);
            rewardsPool.mint(pending, WETH, _account);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            DBC.transfer(_account, _amount);
        }
        user.rewardDebt = user.amount.mul(accPerShare).div(1e18);
        emit Withdraw(_account, _amount);
    }
    function _emergencyWithdraw(address _account) internal {
        UserInfo storage user = userInfo[_account];
        DBC.transfer(_account, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(_account,user.amount);
    }

    /* ---------- StakingFunctions ---------- */
    function deposit(uint256 _amount) public {
        _deposit(_amount, msg.sender, msg.sender);
    }
    function withdraw(uint256 _amount) public {
        _withdraw(_amount, msg.sender);
    }
    function emergencyWithdraw() public {
        _emergencyWithdraw(msg.sender);
    }
    function pendingRewards(address _account) public view returns (uint256) {
        UserInfo memory user = userInfo[_account];
        uint256 pendingAccPerShare = accPerShare;
        uint256 lpSupply = DBC.balanceOf(address(this));
        if (block.timestamp > lastTimestamp && lpSupply != 0) {
            uint256 secs = block.timestamp.sub(lastTimestamp);
            uint256 reward = secs.mul(rewardsPerSecond);
            pendingAccPerShare = pendingAccPerShare.add(reward.mul(1e18).div(lpSupply));
        }
        return user.amount.mul(pendingAccPerShare).div(1e18).sub(user.rewardDebt);
    }
}