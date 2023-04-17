/**
 *Submitted for verification at Arbiscan on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IArbiDexRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IArbDexPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract Arbitrage {
    // Address of the treasury, where tokens are sent once arbitrage has been completed
    address public treasury;

    // Address of the router to complete swap calls, and obtain amountOut given a path
    address immutable public router;

    // Current owner of the contract (admin)
    address public owner;

    // Address of the USDC token
    address immutable USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    // Multiplier used when calculating if arbitrage is profitable (default is 9940 which is 99.40% returned)
    uint256 multiplier = 9940;
    
    // Profit variable utilized in looping to store the most profit receivable from doing arbitrage. The value is in USDC.
    uint256 profit;

    // The required amount of input tokens, in this case USDC, that is utilized for arbitrage
    uint256 requiredTokens;

    // The minimum amount of tokens out to complete the arbitrage swap
    uint256 minimumTokensOut;

    // The current iteration of computeProfit()
    uint256 computeProfitCalls = 0;

    // The limit of how many times computeProfit() can be called, to help save on gas or allow for more profitable arbitrage opportunities
    uint256 public computeProfitCallsLimit = 0;

    // Current token path we are utilizing during arbitrage
    address[] tokenPath;

    struct Pair {
        address pairAddress;
        address[2] tokens;
    }

    struct Indice {
        uint256 index;
        bool exists;
    }

    // The pairs that we are utilizing or looking for an opportunity to arbitrage
    Pair[] public arbPairs;

    // Used to store the index of a pair in the arbPairs array
    mapping(address => Indice) public arbPairIndices;

    constructor(
        address _router,
        address _treasury
    ) {
        treasury = _treasury;
        router = _router;
        owner = msg.sender;
        generateApproval(USDC);
    }

    event NormalArbitrage(uint256, uint256);
    event OwnershipTransferred(address);
    event TreasuryUpdated(address);
    event SetMultiplier(uint256);

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function setMultiplier(uint256 _multiplier) external onlyOwner {
        require(multiplier != _multiplier, "Multiplier already set to that");
        require(_multiplier >= 9900, "Multiplier cannot be zero");
        require(_multiplier <= 10000, "Multiplier too high");
        multiplier = _multiplier;
        emit SetMultiplier(_multiplier);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != owner, "Owner is already set to that address");
        require(_newOwner != address(0), "Cannot be zero address");
        owner = _newOwner;
        emit OwnershipTransferred(_newOwner);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != treasury, "Treasury is already set to that address");
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function generateApproval(address _token) public {
        // Used to approve all the tokens our platform has for transfer by the router from this contract
        IERC20(_token).approve(router, type(uint256).max);
    }

    function recoverToken(address _token) external onlyOwner {
        require(_token != address(0), "Cannot be zero address");
        IERC20(_token).transfer(treasury, IERC20(_token).balanceOf(address(this)));
    }

    function addPair(address _pairAddress) external onlyOwner {
        arbPairs.push(Pair(_pairAddress, [IArbDexPair(_pairAddress).token0(), IArbDexPair(_pairAddress).token1()]));
    
        arbPairIndices[_pairAddress].index = arbPairs.length - 1;
        arbPairIndices[_pairAddress].exists = true;
    }

    function setProfitCallsLimit(uint256 _amount) external onlyOwner {
        computeProfitCallsLimit = _amount;
    }

    function removePair(address _pairAddress) external onlyOwner {
        require(arbPairIndices[_pairAddress].exists == true, "Operations: Invalid pair address provided");
        uint256 index = arbPairIndices[_pairAddress].index;
        arbPairs[index] = arbPairs[arbPairs.length - 1];
        arbPairIndices[arbPairs[arbPairs.length - 1].pairAddress].index = index;
        arbPairs.pop();
        delete arbPairIndices[_pairAddress];
    }

    function computeProfit(uint256 amountIn) internal {
        // Check to see if we've already reached the maximum profit calls allowed
        if (computeProfitCalls >= computeProfitCallsLimit) {return;}    

        // Increment the computeProfitCalls state variable to keep track of the current iteration
        computeProfitCalls += 1;

        // Going to add 10 USDC (saves gas instead of using a smaller number) to see if we can make a higher profit (requires us to recompute output of the path via Router)
        uint256 newAmountIn = amountIn + (10 * (10 ** 6));

        if (newAmountIn > IERC20(USDC).balanceOf(treasury)) {return;}

        uint256[] memory newAmounts = IArbiDexRouter(router).getAmountsOut(newAmountIn, tokenPath);
        // Expected amount out has to be recomputed since we called the Router again, remembering that 0.6% of our starting tokens come back to us.
        uint256 newExpectedAmount = (newAmountIn * multiplier)/10000;

        if (newAmounts[newAmounts.length-1] > newExpectedAmount && (newAmounts[newAmounts.length-1] - newExpectedAmount) > profit) {
            // Profit was higher than previous profit, so let's update profit amount and token amounts and then do all of it over again
            minimumTokensOut = newAmounts[newAmounts.length-1];
            profit = newAmounts[newAmounts.length-1] - newExpectedAmount;
            requiredTokens = newAmountIn;
            computeProfit(newAmountIn);
        }
    }

    function conductArbitrage(address tokenA, address tokenB) internal {
        // Returns the amount of profit, or the amount of USDC we get out subtracted by the amount we started by (profit).
        // We take into account the fact that 0.2% of every swap goes back to the multisig, and remember to account for those swap fees during this calculation.

        if (tokenA == USDC || tokenB == USDC) {return;}

        // Amount we start with multiplied by decimals 6 (USDC)
        uint256 amountIn = 10 * (10 ** 6);
         if (amountIn > IERC20(USDC).balanceOf(treasury)) {return;}

        // Since we starting a new check, lets reset all of our variables
        profit = 0;
        requiredTokens = 0;
        minimumTokensOut = 0;
        computeProfitCalls = 0;

        address[] memory path1 = new address[](4);
        address[] memory path2 = new address[](4);
        path1[0] = USDC; path1[1] = tokenA; path1[2] = tokenB; path1[3] = USDC;
        path2[0] = USDC; path2[1] = tokenB; path2[2] = tokenA; path2[3] = USDC;

        uint256[] memory amounts1 = IArbiDexRouter(router).getAmountsOut(amountIn, path1);
        uint256[] memory amounts2 = IArbiDexRouter(router).getAmountsOut(amountIn, path2);
        uint256 expectedAmount = (amountIn * multiplier)/10000;
        
        requiredTokens = amountIn;

        if (amounts1[amounts1.length-1] > expectedAmount && amounts1[amounts1.length-1] >= amounts2[amounts2.length-1]) {
            // Profitable on first path, compute the precise amount of tokens we can use to maximize profits

            tokenPath = path1;
            minimumTokensOut = amounts1[amounts1.length-1];
            profit = amounts1[amounts1.length-1] - expectedAmount;
            
            computeProfit(amountIn);
        } else if (amounts2[amounts2.length-1] > expectedAmount && amounts2[amounts2.length-1] > amounts1[amounts1.length-1]) {
            // Profitable on second path, compute the precise amount of tokens we can use to maximize profits

            tokenPath = path2;
            minimumTokensOut = amounts2[amounts2.length-1];
            profit = amounts2[amounts2.length-1] - expectedAmount;
            
            computeProfit(amountIn);
        }

        if (profit > 0) {
            IERC20(USDC).transferFrom(treasury, address(this), requiredTokens);
            IArbiDexRouter(router).swapExactTokensForTokens(requiredTokens, minimumTokensOut, tokenPath, treasury, block.timestamp);
            emit NormalArbitrage(requiredTokens, minimumTokensOut);
        }
    }

    function tryArbitrage() external {
        for (uint256 i = 0; i < arbPairs.length; i++) {
            conductArbitrage(arbPairs[i].tokens[0], arbPairs[i].tokens[1]);
        }
    }
}