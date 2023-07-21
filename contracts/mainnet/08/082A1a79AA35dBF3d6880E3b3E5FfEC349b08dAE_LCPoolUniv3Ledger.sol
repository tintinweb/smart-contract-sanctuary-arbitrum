// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IFeeTierStrate.sol";

import "./utils/Ownable.sol";

contract LCPoolUniv3Ledger is Ownable {
  address public feeStrate;

  uint256 private constant MULTIPLIER = 1_0000_0000_0000_0000;

  // token0 -> token1 -> fee -> nftId
  mapping (address => mapping(address => mapping(uint24 => uint256))) public poolToNftId;

  uint256 public tvl;
  uint256 public rtr0;
  uint256 public rtr1;

  struct StakeInfo {
    uint256 amount;   // Staked liquidity
    uint256 rtr0;
    uint256 rtr1;
    uint256 updatedAt;
  }

  // account -> nftid -> basketId -> info basketid=0?lcpool
  mapping (address => mapping (uint256 => mapping (uint256 => StakeInfo))) public userInfo;

  mapping (address => bool) public managers;
  modifier onlyManager() {
    require(managers[msg.sender], "LC pool ledger: !manager");
    _;
  }

  constructor (
    address _feeStrate
  ) {
    require(_feeStrate != address(0), "LC pool ledger: feeStrate");

    feeStrate = _feeStrate;
    managers[msg.sender] = true;
  }

  function setPoolToNftId(address token0, address token1, uint24 fee, uint256 id) public onlyManager {
    poolToNftId[token0][token1][fee] = id;
  }

  function getUserLiquidity(address account, uint256 tokenId, uint256 basketId) public view returns(uint256) {
    return userInfo[account][tokenId][basketId].amount;
  }

  function updateInfo(address acc, uint256 tId, uint256 bId, uint256 liquidity, uint256 reward0, uint256 reward1, bool increase) public onlyManager returns(uint256, uint256) {
    (uint256 pendingReward0, uint256 pendingReward1) = _getSingleReward(acc, tId, bId, 0, 0, false);

    rtr0 += (tvl > 0 ? reward0 * MULTIPLIER / tvl : 0);
    rtr1 += (tvl > 0 ? reward1 * MULTIPLIER / tvl : 0);
    tvl = increase ? tvl + liquidity : (tvl >= liquidity ? tvl - liquidity : 0);
    
    if (increase) {
      userInfo[acc][tId][bId].amount += liquidity;
    }
    else {
      if (userInfo[acc][tId][bId].amount >= liquidity) {
        userInfo[acc][tId][bId].amount -= liquidity;
      }
      else {
        userInfo[acc][tId][bId].amount = 0;
      }
    }
    userInfo[acc][tId][bId].rtr0 = rtr0;
    userInfo[acc][tId][bId].rtr1 = rtr1;
    userInfo[acc][tId][bId].updatedAt = block.timestamp;
    return (pendingReward0, pendingReward1);
  }

  function _getSingleReward(address acc, uint256 tId, uint256 bId, uint256 reward0, uint256 reward1, bool cutfee) internal view returns(uint256, uint256) {
    uint256[] memory jvar = new uint256[](7);
    jvar[0] = 0;  // reward0
    jvar[1] = 0;  // reward1
    jvar[2] = userInfo[acc][tId][bId].amount;

    uint256 userRtr0 = userInfo[acc][tId][bId].rtr0;
    uint256 userRtr1 = userInfo[acc][tId][bId].rtr1;

    if (jvar[2] > 0) {
      uint256 vrtr0 = rtr0;
      uint256 vrtr1 = rtr1;

      if (reward0 > 0) {
        vrtr0 += (tvl > 0 ? reward0 * MULTIPLIER / tvl : 0);
      }
      if (reward1 > 0) {
        vrtr1 += (tvl > 0 ? reward1 * MULTIPLIER / tvl : 0);
      }

      jvar[0] = (vrtr0 >= userRtr0) ? (vrtr0 - userRtr0) * jvar[2] / MULTIPLIER : 0;
      jvar[1] = (vrtr1 >= userRtr1) ? (vrtr1 - userRtr1) * jvar[2] / MULTIPLIER : 0;
    }
    else {
      return (jvar[0], jvar[1]);
    }

    if (cutfee == false) {
      return (jvar[0], jvar[1]);
    }

    (jvar[4], jvar[5]) = IFeeTierStrate(feeStrate).getTotalFee(bId);
    require(jvar[5] > 0, "LC pool ledger: wrong fee configure");
    jvar[3] = jvar[0] * jvar[4] / jvar[5]; // rewardLc0
    jvar[6] = jvar[1] * jvar[4] / jvar[5]; // rewardLc1

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
    if (jvar[3] > 0) {
      uint256[] memory feeIndexs = IFeeTierStrate(feeStrate).getAllTier();
      uint256 len = feeIndexs.length;
      uint256 maxFee = IFeeTierStrate(feeStrate).getMaxFee();
      for (uint256 i=0; i<len; i++) {
        (, ,uint256 fee) = IFeeTierStrate(feeStrate).getTier(feeIndexs[i]);
        uint256 feeAmount = jvar[3] * fee / maxFee;
        if (feeAmount > 0 && jvar[0] >= feeAmount) {
          jvar[0] -= feeAmount;
        }
      }
    }

    return (jvar[0], jvar[1]);
  }

  function getReward(address account, uint256[] memory tokenId, uint256[] memory basketIds, uint256[] memory rewards) public view
    returns(uint256[] memory, uint256[] memory)
  {
    uint256 bLen = basketIds.length;
    uint256 len = tokenId.length * bLen;
    uint256[] memory extraLp = new uint256[](len);
    uint256[] memory reward = new uint256[](len);
    for (uint256 x = 0; x < tokenId.length; x ++) {
      for (uint256 y = 0; y < bLen; y ++) {
        (extraLp[x*bLen + y], reward[x*bLen + y]) = _getSingleReward(account, tokenId[x], basketIds[y], rewards[0], rewards[1], true);
      }
    }
    return (extraLp, reward);
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setFeeStrate(address _feeStrate) external onlyManager {
    require(_feeStrate != address(0), "LC pool ledger: Fee Strate");
    feeStrate = _feeStrate;
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
pragma solidity >=0.8.0 <0.9.0;

interface IFeeTierStrate {
  function getMaxFee() external view returns(uint256);
  function getDepositFee(uint256 id) external view returns(uint256, uint256);
  function getTotalFee(uint256 id) external view returns(uint256, uint256);
  function getWithdrawFee(uint256 id) external view returns(uint256, uint256);
  function getAllTier() external view returns(uint256[] memory);
  function getTier(uint256 index) external view returns(address, string memory, uint256);
}