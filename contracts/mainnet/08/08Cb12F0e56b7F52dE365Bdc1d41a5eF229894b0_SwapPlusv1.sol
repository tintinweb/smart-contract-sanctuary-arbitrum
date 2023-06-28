// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IWETH.sol";
import "./interfaces/ISwapRouter02.sol";
import "./interfaces/IUniswapV2.sol";

import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";

contract SwapPlusv1 is Ownable {
  using SafeERC20 for IERC20;

  struct swapRouter {
    string platform;
    address tokenIn;
    address tokenOut;
    uint256 amountOutMin;
    uint256 meta; // fee, flag(stable), 0=v2
    uint256 percent;
  }
  struct swapLine {
    swapRouter[] swaps;
  }
  struct swapBlock {
    swapLine[] lines;
  }

  address public WETH;
  address public treasury;
  uint256 public swapFee = 3000;
  uint256 public managerDecimal = 1000000;
  mapping (address => bool) public noFeeWallets;
  mapping (address => bool) public managers;

  mapping(string => address) public routers;

  event SwapPlus(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountUsed, uint256 amountOut);

  constructor(
    address _WETH,
    address _treasury
  ) {
    routers["UniswapV3"] = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    routers["UniswapV2"] = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    routers["Sushiswap"] = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    WETH = _WETH;
    treasury = _treasury;
    managers[msg.sender] = true;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "LC swap+: !manager");
    _;
  }

  receive() external payable {
  }

  function swap(address tokenIn, uint256 amount, address tokenOut, address recipient, swapBlock[] calldata swBlocks) public payable returns(uint256, uint256) {
    if (tokenIn != address(0)) {
      IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amount);
    }
    uint256 usedAmount = amount;
    if (noFeeWallets[msg.sender] == false) {
      usedAmount = _cutFee(tokenIn, usedAmount);
    }

    if (tokenIn == address(0)) {
      IWETH(WETH).deposit{value: usedAmount}();
    }

    uint256 blockLen = swBlocks.length;
    uint256 inAmount = usedAmount;
    uint256 outAmount = 0;
    for (uint256 x=0; x<blockLen; x++) {
      uint256 lineLen = swBlocks[x].lines.length;
      outAmount = 0;
      for (uint256 y=0; y<lineLen; y++) {
        outAmount += _swap(swBlocks[x].lines[y], inAmount);
      }
      inAmount = outAmount;
    }

    if (tokenOut == address(0)) {
      IWETH(WETH).withdraw(outAmount);
      (bool success, ) = payable(recipient).call{value: outAmount}("");
      require(success, "LC swap+: Failed receipt");
    }
    else {
      IERC20(tokenOut).safeTransfer(recipient, outAmount);
    }

    emit SwapPlus(tokenIn, tokenOut, amount, usedAmount, outAmount);

    return (usedAmount, outAmount);
  }

  function _swap(swapLine memory line, uint256 amount) internal returns(uint256) {
    uint256 swLen = line.swaps.length;
    uint256 inAmount = amount;
    uint256 outAmount = 0;
    for (uint256 x=0; x<swLen; x++) {
      _approveTokenIfNeeded(line.swaps[x].tokenIn, routers[line.swaps[x].platform], inAmount);
      if (_compareStrings(line.swaps[x].platform, "UniswapV3")) {
        ISwapRouter02.ExactInputSingleParams memory pm = ISwapRouter02.ExactInputSingleParams({
          tokenIn: line.swaps[x].tokenIn,
          tokenOut: line.swaps[x].tokenOut,
          fee: uint24(line.swaps[x].meta),
          recipient: address(this),
          amountIn: inAmount * line.swaps[x].percent / managerDecimal,
          amountOutMinimum: line.swaps[x].amountOutMin,
          sqrtPriceLimitX96: 0
        });
        outAmount = ISwapRouter02(routers["UniswapV3"]).exactInputSingle{value:0}(pm);
      }
      else if (_compareStrings(line.swaps[x].platform, "UniswapV2")) {
        address[] memory path = new address[](2);
        path[0] = line.swaps[x].tokenIn;
        path[1] = line.swaps[x].tokenOut;
        outAmount = ISwapRouter02(routers["UniswapV2"]).swapExactTokensForTokens{value:0}(
          inAmount * line.swaps[x].percent / managerDecimal, line.swaps[x].amountOutMin, path, address(this)
        );
      }
      else if (routers[line.swaps[x].platform] != address(0)) {
        address[] memory path = new address[](2);
        path[0] = line.swaps[x].tokenIn;
        path[1] = line.swaps[x].tokenOut;
        uint256[] memory amounts = IUniswapV2(routers[line.swaps[x].platform]).swapExactTokensForTokens(
          inAmount * line.swaps[x].percent / managerDecimal,
          line.swaps[x].amountOutMin,
          path,
          address(this),
          block.timestamp
        );
        outAmount = amounts[amounts.length - 1];
      }
      inAmount = outAmount;
    }
    return outAmount;
  }

  function _cutFee(address token, uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * swapFee / managerDecimal;
      if (fee > 0) {
        if (token == address(0)) {
          (bool success, ) = payable(treasury).call{value: fee}("");
          require(success, "LC swap+: Failed cut fee");
        }
        else {
          IERC20(token).safeTransfer(treasury, fee);
        }
      }
      return _amount - fee;
    }
    return 0;
  }

  function _approveTokenIfNeeded(address token, address spender, uint256 amount) private {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).approve(spender, type(uint256).max);
    }
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setNoFeeWallets(address account, bool access) public onlyManager {
    noFeeWallets[account] = access;
  }

  function setSwapFee(uint256 _swapFee) public onlyManager {
    swapFee = _swapFee;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }

  function addUniv2Router(string memory _platform, address _router) public onlyManager {
    routers[_platform] = _router;
  }

  function withdraw(address token, uint256 amount) public onlyManager {
    if (token == address(0)) {
      if (amount > address(this).balance) {
        amount = address(this).balance;
      }
      if (amount > 0) {
        (bool success1, ) = msg.sender.call{value: amount}("");
        require(success1, "LC swap+: Failed revoke");
      }
    }
    else {
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (amount > balance) {
        amount = balance;
      }
      if (amount > 0) {
        IERC20(token).safeTransfer(msg.sender, amount);
      }
    }
  }

  function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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

interface IUniswapV2 {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ISwapRouter02 {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountOut);
  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountIn);

  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }
  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }
  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }
  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
  }
  function exactInputSingle(ExactInputSingleParams memory params)
    external
    payable
    returns (uint256 amountOut);
  function exactInput(ExactInputParams memory params) external payable returns (uint256 amountOut);
  function exactOutputSingle(ExactOutputSingleParams calldata params)
    external
    payable
    returns (uint256 amountIn);
  function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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