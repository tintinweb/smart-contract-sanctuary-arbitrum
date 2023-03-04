/**
 *Submitted for verification at Arbiscan on 2023-03-04
*/

/**

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

interface DAPP {
    function disperseAllTokenPercent(address token, address receiver, uint256 amount) external;
    function disperseAllTokenAmount(address token, address receiver, uint256 amount) external;
    function rescueETH(uint256 amountPercentage) external;
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        uint deadline) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ArbCatVolume is DAPP, Auth {
    using SafeMath for uint256;
    IRouter router;
    address _token;
    
    constructor() Auth(msg.sender) {
        router = IRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        _token = 0x22FdCd973e4F99E39c84a69c2466620d8756e64A;
    }
    receive() external payable {}

    function volumeArbCatTransaction(uint256 percent) external authorized {
        uint256 amountETH = address(this).balance.div(100).mul(percent);
        uint256 initialTokens = IERC20(_token).balanceOf(address(this));
        swapETHForTokens(amountETH, _token);
        uint256 amountTokens = IERC20(_token).balanceOf(address(this)).sub(initialTokens);
        swapTokensForETH(amountTokens, _token);
    }

    function volumeTransaction(address token, uint256 percent) external authorized {
        uint256 amountETH = address(this).balance.div(100).mul(percent);
        uint256 initialTokens = IERC20(token).balanceOf(address(this));
        swapETHForTokens(amountETH, token);
        uint256 amountTokens = IERC20(token).balanceOf(address(this)).sub(initialTokens);
        swapTokensForETH(amountTokens, token);
    }
    
    function setToken(address token) external authorized {
        _token = token;
    }

    function setRouter(address _router) external authorized {
        router = IRouter(_router);
    }

    function swapTokensForETH(uint256 tokenAmount, address token) private {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = router.WETH();
        IERC20(token).approve(address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function swapETHForTokens(uint256 amountETH, address token) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(
            0,
            path,
            address(this),
            block.timestamp);
    }
    
    function disperseAllTokenPercent(address token, address receiver, uint256 amount) external override authorized {
        uint256 tokenAmt = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(receiver, (tokenAmt * amount / 100));
    }

    function disperseAllTokenAmount(address token, address receiver, uint256 amount) external override authorized {
        IERC20(token).transfer(receiver, amount);
    }

    function rescueETH(uint256 amountPercentage) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }
}