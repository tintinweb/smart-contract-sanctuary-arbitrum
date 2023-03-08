/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract AstroPresale {
    address public immutable owner;
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    mapping(address => uint256) public amountPurchased;
    mapping(address => bool) public whitelisted;
    uint256 public immutable maxPerWallet = 3 ether;
    uint256 public immutable minPerWallet = 0.1 ether;
    uint256 public immutable presalePrice = 145000 * 1e18;
    uint256 public totalPurchased = 0;
    uint256 public presaleMax;

    address public immutable ASTRO;
    address public immutable CAMELOT_ROUTER = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
    bool public isWhitelistEnabled = true;

    constructor(uint256 _startTime, address _ASTRO, uint256 _max) {
        owner = msg.sender;
        startTime = _startTime;
        endTime = _startTime + 1 days;
        ASTRO = _ASTRO;
        presaleMax = _max;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function buyPresale() external payable {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Not active");
        require(msg.sender == tx.origin, "No contracts");
        require(msg.value > 0, "Zero amount");
        require(isWhitelistEnabled == false || whitelisted[msg.sender] == true, "Only Whitelisted addresses can purchase at this time.");
        require(amountPurchased[msg.sender] + msg.value <= maxPerWallet, "Over wallet limit");
        require(amountPurchased[msg.sender] + msg.value >= minPerWallet, "Under wallet limit");
        require(totalPurchased + msg.value <= presaleMax, "Amount over limit");
        amountPurchased[msg.sender] += msg.value;
        totalPurchased += msg.value;
    }

    function whitelistAddresses(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
    }

    function removeAddressesFromWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = false;
        }
    }

    function toggleWhitelist() external onlyOwner {
        isWhitelistEnabled = !isWhitelistEnabled;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelisted[_address];
    }
    function claim() external {
        require(block.timestamp > endTime + 1 hours, "Not claimable");
        require(amountPurchased[msg.sender] > 0, "No amount claimable");
        uint256 amount = amountPurchased[msg.sender] * presalePrice / 1e18;
        amountPurchased[msg.sender] = 0;
        IERC20(ASTRO).transfer(msg.sender, amount);
    }

    function setMax(uint256 _max) external onlyOwner {
        presaleMax = _max;
    }

    function addLiquidity() external onlyOwner {
        require(block.timestamp > endTime, "Not finished");
        IERC20(ASTRO).approve(CAMELOT_ROUTER, type(uint256).max);
        uint256 totalAmount = address(this).balance;
        (bool success,) = owner.call{value: totalAmount * 15 / 100}("");
        require(success);
        uint256 ethAmount = totalAmount - (totalAmount * 15 / 100);
        uint256 tokenAmount = (ethAmount * presalePrice / 1e18) * 70 / 100;
        IUniswapV2Router02(CAMELOT_ROUTER).addLiquidityETH{value: ethAmount}(
            ASTRO,
            tokenAmount,
            1,
            1,
            0x000000000000000000000000000000000000dEaD,
            type(uint256).max
        );
    }

}