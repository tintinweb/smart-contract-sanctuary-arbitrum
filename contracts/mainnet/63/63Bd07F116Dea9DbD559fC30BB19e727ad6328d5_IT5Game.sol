// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

interface ICamelotRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;
}

contract IT5Game is Ownable {
    ICamelotRouter public uniswapV2Router;
    IERC20 public IT5Token;
    address public taxReceiver;
    uint256 public taxPercentage;
    uint256 public denominator = 10_000;
    uint256 public clickFee = 0.0025 ether;

    uint256 public round = 1;
    uint256 public mulp = 2;

    struct WinnerInfo {
        address winner;
        uint256 amount;
    }

    mapping(uint256 => address[]) public contributors;
    mapping(uint256 => WinnerInfo) public winners;

    constructor(address _it5Token) {
        address router_ = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
        ICamelotRouter _uniswapV2Router = ICamelotRouter(router_);
        uniswapV2Router = _uniswapV2Router;
        IT5Token = IERC20(_it5Token);
        IT5Token.approve(router_, type(uint256).max);
        taxReceiver = address(msg.sender);

        taxPercentage = 1_000;
        clickFee = 0.002 ether;
        round = 1;
    }

    receive() external payable {}

    function sendNative(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        } else {
            IERC20 ERC20token = IERC20(token);
            uint256 balance = ERC20token.balanceOf(address(this));
            ERC20token.transfer(msg.sender, balance);
        }
    }

    function updateTaxReceiver(address _taxReceiver) external onlyOwner {
        require(
            _taxReceiver != address(taxReceiver),
            "The taxReceiver already has that address"
        );
        taxReceiver = _taxReceiver;
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "The router already has that address"
        );
        uniswapV2Router = ICamelotRouter(newAddress);
    }

    function updateIT5Token(address _IT5Token) external onlyOwner {
        require(
            _IT5Token != address(IT5Token),
            "The IT5Token already has that address"
        );
        IT5Token = IERC20(_IT5Token);
    }

    function updateClickFee(uint256 _fee) external onlyOwner {
        clickFee = _fee;
    }

    function getCurrentContributor() public view returns (address[] memory) {
        return contributors[round];
    }

    function getContributorByRound(
        uint256 _round
    ) public view returns (address[] memory) {
        return contributors[_round];
    }

    function getWinnerByRound(
        uint256 _round
    ) public view returns (WinnerInfo memory) {
        return winners[_round];
    }

    function click() external payable {
        require(msg.value >= clickFee, "invalid fee");

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(IT5Token);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: clickFee
        }(0, path, address(this), taxReceiver, block.timestamp + 1 minutes);
        contributors[round].push(msg.sender);

        if (contributors[round].length >= round * mulp) {
            address randomWinner = random(contributors[round]);
            uint256 balance = IT5Token.balanceOf(address(this));
            uint256 amountTax = (balance * taxPercentage) / denominator;
            uint256 amountWin = balance - amountTax;
            IT5Token.transfer(randomWinner, amountWin);
            IT5Token.transfer(taxReceiver, amountTax);
            WinnerInfo memory wininfo = WinnerInfo(randomWinner, amountWin);
            winners[round] = wininfo;
            round = round + 1;
        }
    }

    function random(address[] memory _myArray) internal view returns (address) {
        if (_myArray.length == 0) {
            return address(0);
        }
        uint a = _myArray.length;
        uint b = _myArray.length;
        for (uint i = 0; i < b; i++) {
            uint randNumber = (uint(
                keccak256(abi.encodePacked(block.timestamp, _myArray[i]))
            ) % a) + 1;
            address interim = _myArray[randNumber - 1];
            _myArray[randNumber - 1] = _myArray[a - 1];
            _myArray[a - 1] = interim;
            a = a - 1;
        }
        address[] memory result;
        result = _myArray;
        return result[0];
    }
}