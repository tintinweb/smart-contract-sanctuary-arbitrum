// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IFeeTierStrate.sol";

import "./utils/Ownable.sol";
import "./utils/Address.sol";
import "./utils/StringUtils.sol";

contract LCPoolUniV2Ledger is Ownable {
  address public v2MasterChef;
  address public pool;
  address public feeStrate;
  string public pendingRewardsFunctionName;

  uint256 private constant MULTIPLIER = 1_0000_0000_0000_0000;

  struct RewardTVLRate {
    uint256 reward;
    uint256 prevReward;
    uint256 tvl;
    uint256 rtr;
    uint256 reInvestIndex;
    bool reInvested;
    uint256 updatedAt;
  }

  struct ReinvestInfo {
    uint256 reward;
    uint256 liquidity;
    uint256 updatedAt;
  }

  struct StakeInfo {
    uint256 amount;   // Staked liquidity
    uint256 debtReward;
    uint256 rtrIndex; // RewardTVLRate index
    uint256 updatedAt;
  }

  // account -> poolId -> basketId -> info basketid=0?lcpool
  mapping (address => mapping (uint256 => mapping (uint256 => StakeInfo))) public userInfo;
  // poolId => info
  mapping (uint256 => RewardTVLRate[]) public poolInfoAll;
  // poolId -> reinvest
  mapping (uint256 => ReinvestInfo[]) public reInvestInfo;

  mapping (address => bool) public managers;
  modifier onlyManager() {
    require(managers[msg.sender], "LC pool ledger: !manager");
    _;
  }

  constructor (
    address _v2MasterChef,
    address _feeStrate,
    string memory _pendingRewardsFunctionName
  ) {
    require(_v2MasterChef != address(0), "LC pool ledger: master chef");
    require(_feeStrate != address(0), "LC pool ledger: feeStrate");

    v2MasterChef = _v2MasterChef;
    feeStrate = _feeStrate;
    pendingRewardsFunctionName = _pendingRewardsFunctionName;
    managers[msg.sender] = true;
  }

  function getLastRewardAmount(uint256 poolId) public view returns(uint256) {
    if (poolInfoAll[poolId].length > 0) {
      return poolInfoAll[poolId][poolInfoAll[poolId].length-1].prevReward;
    }
    return 0;
  }

  function getUserLiquidity(address account, uint256 poolId, uint256 basketId) public view returns(uint256) {
    return userInfo[account][poolId][basketId].amount;
  }

  function updateInfo(address acc, uint256 tId, uint256 bId, uint256 liquidity, uint256 reward, uint256 rewardAfter, uint256 exLp, bool increase) public onlyManager {
    uint256[] memory ivar = new uint256[](6);
    ivar[0] = 0;      // prevTvl
    ivar[1] = 0;      // prevTotalReward
    ivar[2] = reward; // blockReward
    ivar[3] = 0;      // exUserLp
    ivar[4] = 0;      // userReward
    ivar[5] = 0;      // rtr
    if (poolInfoAll[tId].length > 0) {
      RewardTVLRate memory prevRTR = poolInfoAll[tId][poolInfoAll[tId].length-1];
      ivar[0] = prevRTR.tvl;
      ivar[1] = prevRTR.reward;
      ivar[2] = (ivar[2] >= prevRTR.prevReward) ? (ivar[2] - prevRTR.prevReward) : 0;
      ivar[5] = prevRTR.rtr;
    }
    ivar[5] += (ivar[0] > 0 ? ivar[2] * MULTIPLIER / ivar[0] : 0);
    
    (ivar[3], ivar[4]) = getSingleReward(acc, tId, bId, reward, false);

    bool reInvested = false;
    if (exLp > 0) {
      ReinvestInfo memory tmp = ReinvestInfo({
        reward: reward,
        liquidity: exLp,
        updatedAt: block.timestamp
      });
      reInvestInfo[tId].push(tmp);
      reInvested = true;
      ivar[3] += ivar[4] * exLp / reward;
      ivar[0] += exLp;
      userInfo[acc][tId][bId].amount += ivar[3];
      ivar[4] = 0;
    }

    RewardTVLRate memory tmpRTR = RewardTVLRate({
      reward: ivar[1] + ivar[2],
      prevReward: rewardAfter,
      tvl: increase ? ivar[0] + liquidity : (ivar[0] >= liquidity ? ivar[0] - liquidity : 0),
      rtr: ivar[5],
      reInvestIndex: reInvestInfo[tId].length,
      reInvested: reInvested,
      updatedAt: block.timestamp
    });
    poolInfoAll[tId].push(tmpRTR);
    
    if (increase) {
      userInfo[acc][tId][bId].amount += liquidity;
      userInfo[acc][tId][bId].debtReward = ivar[4];
    }
    else {
      if (userInfo[acc][tId][bId].amount >= liquidity) {
        userInfo[acc][tId][bId].amount -= liquidity;
      }
      else {
        userInfo[acc][tId][bId].amount = 0;
      }
      userInfo[acc][tId][bId].debtReward = 0;
    }
    userInfo[acc][tId][bId].rtrIndex = poolInfoAll[tId].length - 1;
    userInfo[acc][tId][bId].updatedAt = block.timestamp;
  }

  function getSingleReward(address acc, uint256 tId, uint256 bId, uint256 currentReward, bool cutfee) public view returns(uint256, uint256) {
    uint256[] memory jvar = new uint256[](7);
    jvar[0] = 0;  // extraLp
    jvar[1] = userInfo[acc][tId][bId].debtReward; // reward
    jvar[2] = userInfo[acc][tId][bId].amount;     // stake[j]
    jvar[3] = 0; // reward for one stage

    if (jvar[2] > 0) {
      uint256 t0 = userInfo[acc][tId][bId].rtrIndex;
      uint256 tn = poolInfoAll[tId].length;
      uint256 index = t0;
      while (index < tn) {
        if (poolInfoAll[tId][index].rtr >= poolInfoAll[tId][t0].rtr) {
          jvar[3] = (jvar[2] + jvar[0]) * (poolInfoAll[tId][index].rtr - poolInfoAll[tId][t0].rtr) / MULTIPLIER;
        }
        else {
          jvar[3] = 0;
        }
        if (poolInfoAll[tId][index].reInvested) {
          jvar[0] += jvar[3] * reInvestInfo[tId][poolInfoAll[tId][index].reInvestIndex-1].liquidity / reInvestInfo[tId][poolInfoAll[tId][index].reInvestIndex-1].reward;
          t0 = index;
          jvar[3] = 0;
        }
        index ++;
      }
      jvar[1] += jvar[3];

      if (poolInfoAll[tId][tn-1].tvl > 0 && currentReward >= poolInfoAll[tId][tn-1].prevReward) {
        jvar[1] = jvar[1] + (jvar[2] + jvar[0]) * (currentReward - poolInfoAll[tId][tn-1].prevReward) / poolInfoAll[tId][tn-1].tvl;
      }
    }

    if (cutfee == false) {
      return (jvar[0], jvar[1]);
    }

    (jvar[4], jvar[5]) = IFeeTierStrate(feeStrate).getTotalFee(bId);
    require(jvar[5] > 0, "LC pool ledger: wrong fee configure");
    jvar[6] = jvar[1] * jvar[4] / jvar[5]; // rewardLc

    if (jvar[6] > 0) {
      uint256[] memory feeIndexs = IFeeTierStrate(feeStrate).getAllTier();
      uint256 len = feeIndexs.length;
      uint256 maxFee = IFeeTierStrate(feeStrate).getMaxFee();
      for (uint256 i=0; i<len; i++) {
        (, ,uint256 fee) = IFeeTierStrate(feeStrate).getTier(feeIndexs[i]);
        uint256 feeAmount = jvar[6] * fee / maxFee;
        if (feeAmount > 0 && jvar[1] >= feeAmount) {
          jvar[1] -= feeAmount;
        }
      }
    }

    return (jvar[0], jvar[1]);
  }

  function getReward(address account, uint256[] memory poolId, uint256[] memory basketIds) public view
    returns(uint256[] memory, uint256[] memory)
  {
    uint256 bLen = basketIds.length;
    uint256 len = poolId.length * bLen;
    uint256[] memory extraLp = new uint256[](len);
    uint256[] memory reward = new uint256[](len);
    for (uint256 x = 0; x < poolId.length; x ++) {
      uint256 currentReward = _rewardsAvailable(poolId[x]);
      if (poolInfoAll[poolId[x]].length > 0) {
        currentReward += poolInfoAll[poolId[x]][poolInfoAll[poolId[x]].length-1].prevReward;
      }
      for (uint256 y = 0; y < bLen; y ++) {
        (extraLp[x*bLen + y], reward[x*bLen + y]) = getSingleReward(account, poolId[x], basketIds[y], currentReward, true);
      }
    }
    return (extraLp, reward);
  }

  function _rewardsAvailable(uint256 poolId) internal view returns (uint256) {
    string memory signature = StringUtils.concat(pendingRewardsFunctionName, "(uint256,address)");
    bytes memory result = Address.functionStaticCall(
      v2MasterChef, 
      abi.encodeWithSignature(
        signature,
        poolId,
        pool
      )
    );  
    return abi.decode(result, (uint256));
  }

  function poolInfoLength(uint256 poolId) public view returns(uint256) {
    return poolInfoAll[poolId].length;
  }

  function reInvestInfoLength(uint256 poolId) public view returns(uint256) {
    return reInvestInfo[poolId].length;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setPool(address _pool) public onlyManager {
    pool = _pool;
    managers[pool] = true;
  }

  function setFeeStrate(address _feeStrate) external onlyManager {
    require(_feeStrate != address(0), "LC pool ledger: Fee Strate");
    feeStrate = _feeStrate;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library StringUtils {
  function concat(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity >=0.8.0 <0.9.0;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity >=0.8.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity >=0.8.0 <0.9.0;

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
      return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IFeeTierStrate {
  function getMaxFee() external view returns(uint256);
  function getDepositFee(uint256 id) external view returns(uint256, uint256);
  function getTotalFee(uint256 id) external view returns(uint256, uint256);
  function getWithdrawFee(uint256 id) external view returns(uint256, uint256);
  function getAllTier() external view returns(uint256[] memory);
  function getTier(uint256 index) external view returns(address, string memory, uint256);
}