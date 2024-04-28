/**
 *Submitted for verification at Arbiscan.io on 2024-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface IKeepersRegistry {
    function addFunds(uint256 id, uint96 amount) external;
}

interface IPegSwap {
    function swap(uint256 amount, address fromToken, address toToken) external;

    function getSwapAmount(
        address fromToken,
        address toToken,
        uint256 amount
    ) external view returns (uint256 amountOut);
}

contract MaxGasManagerV1 {
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);

    IERC20 public usdc;
    IERC20 public link;
    IERC20 public weth;
    IERC20 public wrappedLink;
    ISwapRouter02 public swapRouter02;
    IKeepersRegistry public keepersRegistry;
    IPegSwap public pegSwap;

    uint24 public poolFeeIn;
    uint24 public poolFeeOut;
    uint256 public linkSwapped;
    uint256 public usdcSwapped;

    bool public useWrappedLink;
    address public owner;
    address public multisig;

    constructor(address _swapRouter, address _pegSwap) {
        swapRouter02 = ISwapRouter02(_swapRouter);
        pegSwap = IPegSwap(_pegSwap);
        owner = msg.sender;
        multisig = msg.sender;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == owner || msg.sender == multisig,
            "Caller is not an admin"
        );
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisig, "Caller is not the multisig");
        _;
    }

    function setPegSwapAddress(address _newPegSwap) external onlyAdmin {
        require(_newPegSwap != address(0), "PegSwap address cannot be zero");
        pegSwap = IPegSwap(_newPegSwap);
    }

    function setMultisig(address _multisig) external onlyMultisig {
        require(_multisig != address(0), "Multisig cannot be the zero address");
        multisig = _multisig;
    }

    function setTokenAddresses(
        address _usdc,
        address _link,
        address _weth,
        address _wrappedLink
    ) external onlyAdmin {
        usdc = IERC20(_usdc);
        link = IERC20(_link);
        weth = IERC20(_weth);
        wrappedLink = IERC20(_wrappedLink);
    }

    function setRegistryAddress(address _keepersRegistry) external onlyAdmin {
        keepersRegistry = IKeepersRegistry(_keepersRegistry);
    }

    function setPoolFees(
        uint24 _poolFeeIn,
        uint24 _poolFeeOut
    ) external onlyAdmin {
        poolFeeIn = _poolFeeIn;
        poolFeeOut = _poolFeeOut;
    }

    function setUseWrappedLink(bool _useWrappedLink) external onlyAdmin {
        useWrappedLink = _useWrappedLink;
    }

    function _swapUSDCToWETH() external onlyAdmin returns (uint256 amountOut) {
        uint256 usdcBalance = usdc.balanceOf(address(this));
        require(usdcBalance > 0, "Insufficient USDC in contract");

        usdc.approve(address(swapRouter02), usdcBalance);

        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02
            .ExactInputSingleParams({
                tokenIn: address(usdc),
                tokenOut: address(weth),
                fee: poolFeeIn,
                recipient: address(this),
                amountIn: usdcBalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter02.exactInputSingle(params);
        usdc.approve(address(swapRouter02), 0);
        usdcSwapped += usdcBalance;
        return amountOut;
    }

    function swapWETHToLINK() external onlyAdmin returns (uint256 amountOut) {
        uint256 wethBalance = weth.balanceOf(address(this));
        require(wethBalance > 0, "Insufficient WETH in contract");

        weth.approve(address(swapRouter02), wethBalance);

        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02
            .ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(link),
                fee: poolFeeOut,
                recipient: address(this),
                amountIn: wethBalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter02.exactInputSingle(params);
        weth.approve(address(swapRouter02), 0);
        linkSwapped += amountOut;
        return amountOut;
    }

    function sendLink(address recipient, uint256 amount) external onlyAdmin {
        require(link.balanceOf(address(this)) >= amount, "Not enough LINK");
        link.transfer(recipient, amount);
    }

    function fundUpkeep(uint256 upkeepId, uint96 amount) external onlyAdmin {
        require(link.balanceOf(address(this)) >= amount, "Not enough LINK");
        link.approve(address(keepersRegistry), amount);
        keepersRegistry.addFunds(upkeepId, amount);
    }

    function sendWrappedLink(
        address recipient,
        uint256 amount
    ) external onlyAdmin {
        require(link.balanceOf(address(this)) >= amount, "Not enough LINK");
        require(useWrappedLink, "Do you need wrapped Link?");
        link.approve(address(pegSwap), amount);
        pegSwap.swap(amount, address(link), address(wrappedLink));
        link.approve(address(pegSwap), 0);
        wrappedLink.transfer(recipient, amount);
    }

    function fundUpkeepWrappedLink(
        uint256 upkeepId,
        uint96 amount
    ) external onlyAdmin {
        require(link.balanceOf(address(this)) >= amount, "Not enough LINK");
        require(useWrappedLink, "Do you need wrapped Link?");
        link.approve(address(pegSwap), amount);
        pegSwap.swap(amount, address(link), address(wrappedLink));
        link.approve(address(pegSwap), 0);
        wrappedLink.approve(address(keepersRegistry), amount);
        keepersRegistry.addFunds(upkeepId, amount);
        wrappedLink.approve(address(keepersRegistry), 0);
    }

    function withdraw(address _beneficiary) external onlyMultisig {
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        (bool sent, ) = _beneficiary.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    function withdrawToken(
        address _beneficiary,
        address _token
    ) external onlyMultisig {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        IERC20(_token).transfer(_beneficiary, amount);
    }
}