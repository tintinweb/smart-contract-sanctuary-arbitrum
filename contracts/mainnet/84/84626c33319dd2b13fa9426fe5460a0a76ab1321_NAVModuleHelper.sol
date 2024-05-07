/**
 *Submitted for verification at Arbiscan.io on 2024-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISwapRouter02 {
  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  function exactInput(
    ExactInputParams calldata params
  ) external payable returns (uint256 amountOut);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  function exactOutput(
    ExactOutputParams calldata params
  ) external payable returns (uint256 amountIn);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 amount) external;
}

interface IPrice {
  function read() external view returns (uint256);
}

interface INAVModule {
  function getExpectedReserveRedeemQuantity(
    address _setToken,
    address _reserveAsset,
    uint256 _setTokenQuantity
  ) external view returns (uint256);

  function redeem(
    address _setToken,
    address _reserveAsset,
    uint256 _setTokenQuantity,
    uint256 _minReserveReceiveQuantity,
    address _to
  ) external;
}

contract ReEntrancyGuard {
  bool internal locked;

  modifier noReentrant() {
    require(!locked, "No re-entrancy");
    locked = true;
    _;
    locked = false;
  }
}

contract NAVModuleHelper is ReEntrancyGuard {
  address public deployer;

  address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
  address public constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
  address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

  address public constant usdcOracle = 0x3Cb237015231AC57d2Ca1b5208dfAb34ced4Ff84;
  address public constant wstethOracle = 0x1750e0Ffd47a38C120B6c640Fb6BC14fdb02F9E8;

  address public constant NAVMODULE = 0x821f634C0E86A8060b401566196b44b45b56d21a;
  address public constant SETTOKEN = 0xcDe266F62149A36943A6041c9F7a6B14165dc50f;

  constructor() {
    deployer = msg.sender;
  }

  function priceUSDC() public view returns (uint256) {
    return IPrice(usdcOracle).read();
  }

  function priceWSTETH() public view returns (uint256) {
    return IPrice(wstethOracle).read();
  }

  function USDCtoUSD(uint256 amount) public view returns (uint256) {
    uint256 amountUsdcWei = amount * 1e12; // usdc use 6 decimals. convert to 18 decimals
    return (amountUsdcWei * priceUSDC()) / 1e18;
  }

  function WSTETHtoUSD(uint256 amount) public view returns (uint256) {
    uint256 amountWstethWei = amount; // wsteth already 18 decimals
    return (amountWstethWei * priceWSTETH()) / 1e18;
  }

  function calcExpectedRedeemResult(
    uint256 amount
  ) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    uint256 usdcValue = USDCtoUSD(IERC20(USDC).balanceOf(SETTOKEN)); // usdc locked in settoken in usd (18 digit)
    uint256 wstethValue = WSTETHtoUSD(IERC20(WSTETH).balanceOf(SETTOKEN)); // wsteth locked in settoken in usd (18 digit)

    // amount is amount SETTOKEN will be redeemed
    uint256 amount1; // redeem to usdc
    uint256 amount2; // redeem to wsteth
    if (usdcValue < 1e18) {
      amount1 = 0;
      amount2 = amount;
    } else if (wstethValue < 1e18) {
      amount1 = amount;
      amount2 = 0;
    } else {
      amount1 = (amount * usdcValue) / (usdcValue + wstethValue);
      amount2 = amount - amount1;
    }

    // redeem amount1 SETTOKEN to usdc and send to user
    // redeem amount2 SETTOKEN to wsteth, swap to usdc and send to user

    uint256 expectedUSDC = INAVModule(NAVMODULE).getExpectedReserveRedeemQuantity(
      SETTOKEN,
      USDC,
      amount1
    );
    uint256 expectedWSTETH = INAVModule(NAVMODULE).getExpectedReserveRedeemQuantity(
      SETTOKEN,
      WSTETH,
      amount2
    );

    return (usdcValue, wstethValue, amount1, amount2, expectedUSDC, expectedWSTETH);
  }

  function shouldRedeemV2(uint256 amount) public view returns (uint256, uint256, bool) {
    uint256 usdcLocked = IERC20(USDC).balanceOf(SETTOKEN);
    uint256 usdcExpected = INAVModule(NAVMODULE).getExpectedReserveRedeemQuantity(
      SETTOKEN,
      USDC,
      amount
    );
    bool yes = usdcExpected > usdcLocked;
    return (usdcLocked, usdcExpected, yes);
  }

  function redeemV2(
    uint256 amount,
    address[] calldata _path,
    uint24[] calldata _fees,
    uint256 minAmountOut
  ) public noReentrant returns (uint256, uint256) {
    IERC20(SETTOKEN).transferFrom(msg.sender, address(this), amount);
    IERC20(SETTOKEN).approve(NAVMODULE, amount);

    (
      ,
      ,
      uint256 amount1,
      uint256 amount2,
      uint256 expectedUSDC,
      uint256 expectedWSTETH
    ) = calcExpectedRedeemResult(amount);

    if (amount1 > 0)
      INAVModule(NAVMODULE).redeem(SETTOKEN, USDC, amount1, expectedUSDC, address(this));

    if (amount2 > 0)
      INAVModule(NAVMODULE).redeem(SETTOKEN, WSTETH, amount2, expectedWSTETH, address(this));

    uint256 wstethToSwap = IERC20(WSTETH).balanceOf(address(this));
    if (wstethToSwap > 0) swapAndTransfer(wstethToSwap, _path, _fees, minAmountOut, address(this));

    uint256 usdcToTransfer = IERC20(USDC).balanceOf(address(this));
    if (usdcToTransfer > 0) IERC20(USDC).transfer(msg.sender, usdcToTransfer);

    return (wstethToSwap, usdcToTransfer);
  }

  function swapAndTransfer(
    uint256 amountIn,
    address[] calldata _path,
    uint24[] calldata _fees,
    uint256 minAmountOut,
    address recipient
  ) private {
    IERC20(WSTETH).approve(ROUTER, amountIn);
    bytes memory path = generatePath(_path, _fees);

    ISwapRouter02.ExactInputParams memory params = ISwapRouter02.ExactInputParams({
      path: path,
      recipient: recipient,
      amountIn: amountIn,
      amountOutMinimum: minAmountOut
    });

    ISwapRouter02(ROUTER).exactInput(params);
  }

  function generatePath(
    address[] calldata _path,
    uint24[] calldata _fees
  ) public pure returns (bytes memory) {
    bytes memory data = "";
    for (uint256 i = 0; i < _path.length - 1; i++) {
      data = abi.encodePacked(data, _path[i], _fees[i]);
    }

    // Last encode has no fee associated with it since _fees.length == _path.length - 1
    data = abi.encodePacked(data, _path[_path.length - 1]);
    return data;
  }

  function withdrawAll(address token) public {
    require(msg.sender == deployer, "access denied");
    IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
  }
}