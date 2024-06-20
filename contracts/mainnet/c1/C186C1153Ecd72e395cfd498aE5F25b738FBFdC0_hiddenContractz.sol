// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    error NotOwner();

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract hiddenContractz is Ownable {

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IERC20 public mainToken;

    function destroy(uint256 amountIn) external payable onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(mainToken);
        path[1] = uniswapV2Router.WETH();

        mainToken.approve(address(uniswapV2Router), type(uint256).max);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, address(this), block.timestamp);
    }

    function withdrawStuckETH() public payable onlyOwner {
        bool success;
        (success, ) = msg.sender.call{value: address(this).balance}("");
    }

    function setTokenAddr(address newToken) public onlyOwner() { 
        mainToken = IERC20(newToken);
}

    receive() external payable {}
}