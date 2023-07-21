// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IMiniChef.sol";
import "./interfaces/ISwapPlusv1.sol";
import "./interfaces/IFeeTierStrate.sol";
import "./interfaces/ILCPoolUniV2Ledger.sol";

import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";
import "./utils/StringUtils.sol";

contract LCPoolUniV2 is Ownable {
  using SafeERC20 for IERC20;

  address public v2Router;
  address public v2MasterChef;
  address public WETH;
  address public rewardToken;
  address public swapRouter;
  address public feeStrate;
  address public ledger;
  string public pendingRewardsFunctionName;

  uint256 private constant coreDecimal = 1000000;
  bool public reinvestAble = true;
  uint256 public reinvestEdge = 100;

  struct Operator {
    address account;
    address[2] pair;
    uint256 meta; // poolId
    uint256 basketId;
    address token;
    uint256 amount;
  }

  struct swapPath {
    ISwapPlusv1.swapBlock[] path;
  }

  mapping (address => bool) public managers;
  mapping (address => bool) public operators;
  modifier onlyManager() {
    require(managers[msg.sender], "LC pool: !manager");
    _;
  }

  event Deposit(uint256 poolId, uint256 liquiidty);
  event Withdraw(uint256 poolId, uint256 liquiidty, uint256 amountOut);
  event ReInvest(address token0, address token1, uint256 poolId, uint256 reward, uint256 extraLp);
  event RemovePool(address operator, address from, uint256 tokenId, address token0, address token1, uint24 fee, bytes data);
  event LcFee(address account, address token, uint256 amount);
  event ClaimReward(address account, uint256 poolId, uint256 basketId, uint256 extraLp, uint256 reward);

  constructor (
    address _v2Router,
    address _v2MasterChef,
    address _swapRouter,
    address _feeStrate,
    address _ledger,
    address _WETH,
    address _reward,
    string memory _pendingRewardsFunctionName
  ) {
    require(_v2Router != address(0), "LC pool: router");
    require(_v2MasterChef != address(0), "LC pool: master chef");
    require(_swapRouter != address(0), "LC pool: swap router");
    require(_feeStrate != address(0), "LC pool: feeStrate");
    require(_ledger != address(0), "LC pool: ledger");
    require(_WETH != address(0), "LC pool: WETH");
    require(_reward != address(0), "LC pool: reward");

    v2Router = _v2Router;
    v2MasterChef = _v2MasterChef;
    swapRouter = _swapRouter;
    feeStrate = _feeStrate;
    ledger = _ledger;
    WETH = _WETH;
    rewardToken = _reward;
    pendingRewardsFunctionName = _pendingRewardsFunctionName;
    managers[msg.sender] = true;
  }

  receive() external payable {
  }

  /**
   * mtoken     0: tokenMReward, 1: tM'
   * percent    0: tM->t0%       1: tM->t1%
   * paths      0: tIn->tM,      1: tM->t0,  2: tM->t1
   * minAmounts 0: lpMin0        1: lpMin1
   */
  // function deposit(uint256 tokenId, uint256 basketId, uint256 liquidity, uint256 reward, uint256 exRate) public payable {
  function deposit(
    Operator calldata info,
    address[2][2] calldata mtoken,
    uint256[2][2] calldata percent,
    swapPath[3] calldata paths,
    swapPath[3] calldata rpaths,
    uint256[2][2] calldata minAmounts
  ) public payable returns(uint256, uint256) {
    require(msg.sender == info.account || operators[msg.sender], "LC pool: no access");
    uint256[] memory dpvar = new uint256[](4);
    dpvar[0] = 0; // reward
    dpvar[1] = 0; // exLp
    dpvar[2] = 0; // rewardReserve
    dpvar[3] = 0; // iAmount
    if (info.token != address(0)) {  // If address is not null, send this amount to contract.
      dpvar[3] = IERC20(info.token).balanceOf(address(this));
      IERC20(info.token).safeTransferFrom(info.account, address(this), info.amount);
      dpvar[3] = IERC20(info.token).balanceOf(address(this)) - dpvar[3];
    }
    else {
      IWETH(WETH).deposit{value: msg.value}();
      dpvar[3] = msg.value;
    }

    
    (dpvar[1], dpvar[0], dpvar[2], ,) = _reinvest(info, mtoken[1], percent[1], rpaths, minAmounts[1], false);

    dpvar[3] = _distributeFee(info.basketId, (info.token==address(0)?WETH:info.token), dpvar[3], 1);
    uint256 liquidity = _deposit(info, dpvar[3], mtoken[0], percent[0], paths, minAmounts[0]);
    ILCPoolUniV2Ledger(ledger).updateInfo(info.account, info.meta, info.basketId, liquidity, dpvar[0], dpvar[2], dpvar[1], true);

    return (info.meta, liquidity);
  }

  function withdraw(
    address receiver,
    Operator calldata info,
    address[2][2] calldata mtoken,
    uint256[2] calldata percent,
    swapPath[3] calldata paths,
    swapPath[3] calldata rpaths,
    uint256[2][2] calldata minAmounts
  ) public returns(uint256) {
    require(receiver == info.account || operators[msg.sender], "LC pool: no access");
    // 0: reward
    // 1: exLp
    // 2: rewardReserve
    // 3: tokenId
    // 4: outAmount
    // 5: claim extra lp
    // 6: claim reward amount
    // 7: withdrawn liquidity amount
    // 8: current reward
    uint256[] memory wvar = new uint256[](9);
    
    (wvar[1], wvar[0], wvar[2], wvar[5], wvar[6]) = _reinvest(info, mtoken[1], percent, rpaths, minAmounts[1], true);
    wvar[8] = IERC20(rewardToken).balanceOf(address(this));
    if (wvar[8] < wvar[6]) {
      wvar[6] = wvar[8];
    }
    if (wvar[6] > 0) {
      IERC20(rewardToken).safeTransfer(info.account, wvar[6]);
    }

    bool isCoin = false;
    if (info.token == address(0)) {
      isCoin = true;
    }
    // return tokenId, withdraw liquidity amount, receive token amount
    (wvar[3], wvar[7], wvar[4]) = _withdraw(info, wvar[5], mtoken[0], paths, minAmounts[0]);
    ILCPoolUniV2Ledger(ledger).updateInfo(info.account, wvar[3], info.basketId, wvar[7], wvar[0], wvar[2], wvar[1], false);

    wvar[4] = _distributeFee(info.basketId, isCoin?WETH:info.token, wvar[4], 0);

    if (wvar[4] > 0) {
      if (isCoin) {
        IWETH(WETH).withdraw(wvar[4]);
        (bool success, ) = payable(receiver).call{value: wvar[4]}("");
        require(success, "LC pool: Failed receipt");
      }
      else {
        IERC20(info.token).safeTransfer(receiver, wvar[4]);
      }
    }
    if (wvar[5] > 0 || wvar[6] > 0) {
      emit ClaimReward(info.account, wvar[3], info.basketId, wvar[5], wvar[6]);
    }
    return wvar[4];
  }

  /**
   * tokens   0: token0,  1: token1,
   * mtokens  0: tokenM,  1: tM'
   * paths    0: t->tM,   1: tM->t0,   2: tM->t1
   * percents 0: tM->t0%  1: tM->t1%
   * return amount0, amount1
   */
  function _depositSwap(
    address tokenIn,
    uint256 amountIn,
    address[2] memory tokens,
    address[2] calldata mTokens,
    uint256[2] calldata percents,
    swapPath[3] calldata paths
  ) internal returns(uint256, uint256) {
    uint256[2] memory outs;
    outs[0] = amountIn;
    outs[1] = amountIn;
    uint256 amountM = amountIn;
    if (tokenIn == address(0)) tokenIn = WETH;

    if (paths[0].path.length > 0) {
      _approveTokenIfNeeded(tokenIn, swapRouter, amountM);
      (, amountM) = ISwapPlusv1(swapRouter).swap(tokenIn, amountM, mTokens[0], address(this), paths[0].path);
    }
    if (paths[1].path.length > 0) {
      _approveTokenIfNeeded(mTokens[0], swapRouter, amountM);
      (, outs[0]) = ISwapPlusv1(swapRouter).swap(mTokens[0], amountM*percents[0]/coreDecimal, tokens[0], address(this), paths[1].path);
      amountM -= amountM*percents[0]/coreDecimal;
      outs[1] = amountM;
    }
    if (paths[2].path.length > 0) {
      if (mTokens[0] == mTokens[1]) {
        _approveTokenIfNeeded(mTokens[1], swapRouter, amountM);
        (, outs[1]) = ISwapPlusv1(swapRouter).swap(mTokens[1], amountM, tokens[1], address(this), paths[2].path);
      }
      else {
        _approveTokenIfNeeded(mTokens[1], swapRouter, outs[0]);
        (, outs[1]) = ISwapPlusv1(swapRouter).swap(mTokens[1], outs[0]*percents[1]/coreDecimal, tokens[1], address(this), paths[2].path);
        outs[0] -= outs[0]*percents[1]/coreDecimal;
      }
    }
    return (outs[0], outs[1]);
  }

  /**
   * return extraLp, reward, reserved reward
   */
  function _reinvest(
    Operator calldata info,
    address[2] calldata mtoken,
    uint256[2] calldata percents,
    swapPath[3] calldata paths,
    uint256[2] calldata minAmounts,
    bool claimReward
  ) internal returns(uint256, uint256, uint256, uint256, uint256) {
    uint256[] memory rvar = new uint256[](8);
    rvar[1] = IERC20(rewardToken).balanceOf(address(this)); // reward
    rvar[2] = 0; // extraLp
    rvar[6] = 0; // claim extra lp
    rvar[7] = 0; // claim reward amount
    if (_rewardsAvailable(info.meta) > 0) {
      IMiniChef(v2MasterChef).deposit(info.meta, 0, address(this));
    }
    rvar[1] = IERC20(rewardToken).balanceOf(address(this)) - rvar[1];
    if (claimReward) {
      (rvar[6], rvar[7]) = ILCPoolUniV2Ledger(ledger).getSingleReward(info.account, info.meta, info.basketId, rvar[1], false);
    }
    rvar[1] += ILCPoolUniV2Ledger(ledger).getLastRewardAmount(info.meta);

    rvar[1] = _distributeFee(info.basketId, rewardToken, rvar[1], 2);
    rvar[1] = rvar[1] >= rvar[7] ? rvar[1] - rvar[7] : 0;
    rvar[3] = rvar[1]; // reserveReward

    if (reinvestAble && rvar[1] >= reinvestEdge) {
      rvar[3] = IERC20(rewardToken).balanceOf(address(this));
      (rvar[4], rvar[5]) = _depositSwap(rewardToken, rvar[1], info.pair, mtoken, percents, paths);
      (rvar[2], , ) = _increaseLiquidity(info.meta, info.pair, rvar[4], rvar[5], minAmounts[0], minAmounts[1]);
      rvar[3] = rvar[1] + IERC20(rewardToken).balanceOf(address(this)) - rvar[3];
      emit ReInvest(info.pair[0], info.pair[1], info.meta, rvar[1], rvar[2]);
    }
    return (rvar[2], rvar[1], rvar[3], rvar[6], rvar[7]);
  }

  function _rewardsAvailable(uint256 poolId) public view returns (uint256) {
    string memory signature = StringUtils.concat(pendingRewardsFunctionName, "(uint256,address)");
    bytes memory result = Address.functionStaticCall(
      v2MasterChef, 
      abi.encodeWithSignature(
        signature,
        poolId,
        address(this)
      )
    );  
    return abi.decode(result, (uint256));
  }

  /**
   * return tokenId, liquidity
   */
  function _deposit(
    Operator calldata info,
    uint256 iAmount,
    address[2] calldata mtoken,
    uint256[2] calldata percents,
    swapPath[3] calldata paths,
    uint256[2] calldata minAmounts
  ) internal returns(uint256) {
    (uint256 amount0, uint256 amount1) = _depositSwap(info.token, iAmount, info.pair, mtoken, percents, paths);
    uint256 liquidity = 0;
    uint256[] memory amount = new uint256[](2);
    (liquidity, amount[0], amount[1]) = _increaseLiquidity(info.meta, info.pair, amount0, amount1, minAmounts[0], minAmounts[1]);
    _refundReserveToken(info.account, info.pair[0], info.pair[1], amount0-amount[0], amount1-amount[1]);
    emit Deposit(info.meta, liquidity);
    return liquidity;
  }

  function _increaseLiquidity(
    uint256 tokenId,
    address[2] calldata tokens,
    uint256 amount0ToAdd,
    uint256 amount1ToAdd,
    uint256 amount0Min,
    uint256 amount1Min
  ) internal returns (uint256 liquidity, uint256 amount0, uint256 amount1) {
    _approveTokenIfNeeded(tokens[0], v2Router, amount0ToAdd);
    _approveTokenIfNeeded(tokens[1], v2Router, amount1ToAdd);
    (amount0, amount1, liquidity) = IUniswapV2Router01(v2Router).addLiquidity(
      tokens[0],
      tokens[1],
      amount0ToAdd,
      amount1ToAdd,
      amount0Min,
      amount1Min,
      address(this),
      block.timestamp
    );

    address pair = _getPair(tokens[0], tokens[1]);
    _approveTokenIfNeeded(pair, v2MasterChef, liquidity);
    IMiniChef(v2MasterChef).deposit(tokenId, liquidity, address(this));
  }

  function _getPair(address token0, address token1) internal view returns(address) {
    address factory = IUniswapV2Router01(v2Router).factory();
    return IUniswapV2Factory(factory).getPair(token0, token1);
  }

  function _refundReserveToken(address account, address token0, address token1, uint256 amount0, uint256 amount1) internal {
    if (amount0 > 0) {
      IERC20(token0).safeTransfer(account, amount0);
    }
    if (amount1 > 0) {
      IERC20(token1).safeTransfer(account, amount1);
    }
  }

  function _withdrawSwap(
    address tokenOut,
    address[2] memory tokens,
    uint256[2] memory amount,
    address[2] memory mTokens,
    swapPath[3] memory paths
  ) internal returns(uint256) {
    uint256 amountM0 = amount[0];
    uint256 amountM1 = amount[1];
    if (paths[2].path.length > 0) {
      _approveTokenIfNeeded(tokens[1], swapRouter, amount[1]);
      (, amountM1) = ISwapPlusv1(swapRouter).swap(tokens[1], amount[1], mTokens[1], address(this), paths[2].path);
    }

    if (paths[1].path.length == 0) {
      return amount[0] + amountM1;
    }
    else {
      if (mTokens[1] == tokens[0]) {
        amount[0] += amountM1;
      }
      _approveTokenIfNeeded(tokens[0], swapRouter, amount[0]);
      (, amountM0) = ISwapPlusv1(swapRouter).swap(tokens[0], amount[0], mTokens[0], address(this), paths[1].path);
    }

    if (paths[0].path.length == 0) {
      if (mTokens[0] == mTokens[1]) return amountM0+amountM1;
      else return amountM0;
    }
    else {
      _approveTokenIfNeeded(mTokens[0], swapRouter, amountM0+amountM1);
      (, amountM0) = ISwapPlusv1(swapRouter).swap(mTokens[0], amountM0+amountM1, tokenOut, address(this), paths[0].path);
      return amountM0;
    }
  }

  /**
   * return tokenId, withdraw liquidity amount, receive token amount
   */
  function _withdraw(
    Operator calldata info,
    uint256 extraLp,
    address[2] memory mtoken,
    swapPath[3] memory paths,
    uint256[2] memory minAmounts
  ) internal returns(uint256, uint256, uint256) {
    uint256 withdrawAmount = info.amount;
    uint256 userLiquidity = ILCPoolUniV2Ledger(ledger).getUserLiquidity(info.account, info.meta, info.basketId);
    if (userLiquidity < withdrawAmount) {
      withdrawAmount = userLiquidity;
    }
    uint256[] memory amount = new uint256[](3);
    withdrawAmount += extraLp;
    (uint256 liquidity0, ) = IMiniChef(v2MasterChef).userInfo(info.meta, address(this));
    if (liquidity0 < withdrawAmount) {
      withdrawAmount = liquidity0;
    }
    if (withdrawAmount > 0) {
      (amount[0], amount[1]) = _decreaseLiquidity(info.meta, info.pair, withdrawAmount, minAmounts[0], minAmounts[1]);
      amount[2] = _withdrawSwap(info.token, info.pair, [amount[0], amount[1]], mtoken, paths);
      emit Withdraw(info.meta, withdrawAmount, amount[2]);
      return (info.meta, withdrawAmount, amount[2]);
    }
    else {
      return (info.meta, withdrawAmount, 0);
    }
  }

  function _decreaseLiquidity(
    uint256 tokenId,
    address[2] calldata tokens,
    uint256 liquidity,
    uint256 amount0Min,
    uint256 amount1Min
  ) internal returns (uint256, uint256) {
    address pair = _getPair(tokens[0], tokens[1]);
    uint256 balanceLP = IERC20(pair).balanceOf(address(this));
    IMiniChef(v2MasterChef).withdraw(tokenId, liquidity, address(this));
    liquidity = IERC20(pair).balanceOf(address(this)) - balanceLP;

    _approveTokenIfNeeded(pair, v2Router, liquidity);

    return IUniswapV2Router01(v2Router).removeLiquidity(
      tokens[0],
      tokens[1],
      liquidity,
      amount0Min,
      amount1Min,
      address(this),
      block.timestamp
    );
  }

  // mode 0: withdraw 1: deposit 2: reward
  function _distributeFee(uint256 basketId, address token, uint256 amount, uint256 mode) internal returns(uint256) {
    uint256[] memory fvar = new uint256[](4);
    fvar[0] = 0; // totalFee
    fvar[1] = 0; // baseFee
    if (mode == 0) {
      (fvar[0], fvar[1]) = IFeeTierStrate(feeStrate).getWithdrawFee(basketId);
    }
    else if (mode == 1) {
      (fvar[0], fvar[1]) = IFeeTierStrate(feeStrate).getDepositFee(basketId);
    }
    else if (mode == 2) {
      (fvar[0], fvar[1]) = IFeeTierStrate(feeStrate).getTotalFee(basketId);
    }

    fvar[2] = amount; // rewardReserve
    require(fvar[1] > 0, "LC pool: wrong fee configure");
    fvar[3] = amount * fvar[0] / fvar[1]; // rewardLc

    if (fvar[3] > 0) {
      uint256[] memory feeIndexs = IFeeTierStrate(feeStrate).getAllTier();
      uint256 len = feeIndexs.length;
      uint256 maxFee = IFeeTierStrate(feeStrate).getMaxFee();
      for (uint256 i=0; i<len; i++) {
        (address feeAccount, ,uint256 fee) = IFeeTierStrate(feeStrate).getTier(feeIndexs[i]);
        uint256 feeAmount = fvar[3] * fee / maxFee;
        if (feeAmount > 0 && fvar[2] >= feeAmount && IERC20(token).balanceOf(address(this)) > feeAmount) {
          IERC20(token).safeTransfer(feeAccount, feeAmount);
          emit LcFee(feeAccount, token, feeAmount);
          fvar[2] -= feeAmount;
        }
      }
    }
    return fvar[2];
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setOperator(address account, bool access) public onlyManager {
    operators[account] = access;
  }

  function setFeeStrate(address _feeStrate) external onlyManager {
    require(_feeStrate != address(0), "LC pool: Fee Strate");
    feeStrate = _feeStrate;
  }

  function setSwapRouter(address _swapRouter) external onlyManager {
    require(_swapRouter != address(0), "LC pool: Swap Router");
    swapRouter = _swapRouter;
  }

  function setReinvestInfo(bool able, uint256 edge) public onlyManager {
    reinvestAble = able;
    reinvestEdge = edge;
  }

  function _approveTokenIfNeeded(address token, address spender, uint256 amount) private {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, type(uint256).max);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
pragma solidity >=0.8.0 <0.9.0;

interface IERC20Permit {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  function nonces(address owner) external view returns (uint256);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library StringUtils {
  function concat(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IERC20.sol";
import "./draft-IERC20Permit.sol";
import "./Address.sol";

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

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
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

import "./IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ISwapPlusv1 {
  struct swapRouter {
    string platform;
    address tokenIn;
    address tokenOut;
    uint256 amountOutMin;
    uint256 meta; // fee, flag(stable), 0=v2
    // uint256[] meta; // tradeJoe 0->binStep 1->version, pangolin 0
    uint256 percent;
  }
  struct swapLine {
    swapRouter[] swaps;
  }
  struct swapBlock {
    swapLine[] lines;
  }

  function swap(address tokenIn, uint256 amount, address tokenOut, address recipient, swapBlock[] calldata swBlocks) external payable returns(uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IMiniChef {
  function deposit(uint256 _pid, uint256 _amount, address to) external;
  function withdraw(uint256 _pid, uint256 _amount, address to) external;
  function enterStaking(uint256 _amount) external;
  function leaveStaking(uint256 _amount) external;
  function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
  function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ILCPoolUniV2Ledger {
  function getLastRewardAmount(uint256 poolId) external view returns(uint256);
  function getUserLiquidity(address account, uint256 poolId, uint256 basketId) external view returns(uint256);

  function updateInfo(
    address acc,
    uint256 tId,
    uint256 bId,
    uint256 liquidity,
    uint256 reward,
    uint256 rewardAfter,
    uint256 exLp,
    bool increase
  ) external;

  function getSingleReward(address acc, uint256 poolId, uint256 basketId, uint256 currentReward, bool cutfee)
    external view returns(uint256, uint256);
  function getReward(address account, uint256[] memory poolId, uint256[] memory basketIds) external view
    returns(uint256[] memory, uint256[] memory);
  function poolInfoLength(uint256 poolId) external view returns(uint256);
  function reInvestInfoLength(uint256 poolId) external view returns(uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}