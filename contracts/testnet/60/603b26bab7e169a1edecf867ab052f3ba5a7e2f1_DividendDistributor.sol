//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IDividendDistributor.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import './IDexRouter.sol';

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
 
    address _token;
 
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
 
    // TODO change me USDC
    IERC20 ARB = IERC20(0x4F53e1645135bB0C4e3Ea1B8c1cE839664570DDC);
    // IERC20 ARB = IERC20(0x98E69a51613A70A8bbda9094ff24Adf0BfA09E1d);
    address WETH;
    IDexRouter router;
 
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
 
    mapping (address => Share) public shares;
 
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
 
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);
 
    uint256 currentIndex;
 
    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }
 
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
 
    constructor () {
        router = IDexRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        _token = msg.sender;
        // WETH = router.WETH();
        WETH = 0xd00EAb9dB18B6Ebc486d56470143B916109C4969;
        // WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    }
 
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }
 
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
 
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
 
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
 
    function deposit() external payable override onlyToken {
        uint256 balanceBefore = ARB.balanceOf(address(this));
 
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(ARB);
 
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
 
        uint256 amount = ARB.balanceOf(address(this)).sub(balanceBefore);
 
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
 
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
 
        if(shareholderCount == 0) { return; }
 
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
 
        uint256 iterations = 0;
 
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
 
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
 
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
 
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }
 
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
 
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            ARB.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
 
    function claimDividend() external {
        distributeDividend(msg.sender);
    }
 
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
 
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
 
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
 
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
 
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }
 
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
 
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDexRouter {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
 
/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}