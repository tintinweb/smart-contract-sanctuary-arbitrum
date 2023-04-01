/**
 *Submitted for verification at Arbiscan on 2023-03-31
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
    address public treasury;
    address public router;
    address public owner;
    address USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    uint256 multiplier = 9950; // 99.40%
    uint256 public profit = 0; // Amount of profit (in USDC) from doing an arbitrage
    uint256 public requiredTokens = 0; // Amount of tokens (minimum) required for the most profit
    uint256 public minimumTokensOut = 0;
    address[] tokenPath; // The path of tokens that will be utilized for arbitrage
    mapping(address => bool) approvedTokens; // List of all the tokens that have been approved (token approval for transfers).
    address[] arbPairs;
    mapping(address => address[2]) arbTokens; // pair, and then tokens associated that are up for arbitrage.

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
    event NoArbitrage();
    event LowBalanceArbitrage(uint256, uint256);
    event OwnershipTransferred(address);
    event TreasuryUpdated(address);
    event SetMultiplier(uint256);

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function setMultiplier(uint256 _multiplier) external onlyOwner {
        require(multiplier != _multiplier, "Multiplier already set to that");
        require(_multiplier >= 0, "Multiplier cannot be zero");
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

    function generateApproval(address _token) internal {
        // Used to approve all the tokens our platform has for transfer by the router from this contract
        approvedTokens[_token] = true;
        IERC20(_token).approve(router, 1000000000000000000000000);
    }

    function recoverToken(address _token) external onlyOwner {
        require(_token != address(0), "Cannot be zero address");
        require(IERC20(_token).balanceOf(address(this)) > 0, "Nothing to transfer");
        IERC20(_token).transfer(treasury, IERC20(_token).balanceOf(address(this)));
    }

    function updateList(address _pairAddress) external onlyOwner {
        arbPairs.push(_pairAddress);
        arbTokens[_pairAddress] = [IArbDexPair(_pairAddress).token0(), IArbDexPair(_pairAddress).token1()];
    }

    function computeProfit(uint256 amountIn) internal {
        // Going to add 1 USDC to see if we can make a higher profit (requires us to recompute output of the path via Router)
        uint256 newAmountIn = amountIn + (10 * (10 ** 6));
        if (newAmountIn > IERC20(USDC).balanceOf(treasury)) {return;}
        uint256[] memory newAmounts =  IArbiDexRouter(router).getAmountsOut(newAmountIn, tokenPath);
        // Expected amount out has to be recomputed since we called the Router again, remembering that 0.6% of our starting tokens come back to us.
        uint256 newExpectedAmount = (newAmountIn * multiplier)/10000;

        if (newAmounts[newAmounts.length-1] > newExpectedAmount && (newAmounts[newAmounts.length-1] - newExpectedAmount) > profit) {
            // Profit was higher than previous profit, so let's update profit amount and token amounts and then do all of it over again
            minimumTokensOut = newAmounts[newAmounts.length-1];
            profit = newAmounts[newAmounts.length-1] - newExpectedAmount;
            requiredTokens = newAmountIn;
            // Delete these variables and arrays that way we save on gas
            delete newExpectedAmount;
            delete newAmounts;
            computeProfit(newAmountIn);
        }
    }

    function conductArbitrage(address tokenA, address tokenB) internal {
        // Returns the amount of profit, or the amount of USDC we get out subtracted by the amount we started by (profit).
        // We take into account the fact that 0.2% of every swap goes back to the multisig, and remember to account for those swap fees during this calculation.

        if (!approvedTokens[tokenA]) {
            generateApproval(tokenA);
        }
        if (!approvedTokens[tokenB]) {
            generateApproval(tokenB);
        }
        if (tokenA == USDC || tokenB == USDC) {return;}

        // Amount we start with multiplied by decimals 6 (USDC)
        uint256 amountIn = 10 * (10 ** 6);

        // Since we starting a new check, lets reset all of our variables
        profit = 0;
        requiredTokens = 0;
        minimumTokensOut = 0;

        address[] memory path1 = new address[](4);
        address[] memory path2 = new address[](4);
        path1[0] = USDC; path1[1] = tokenA; path1[2] = tokenB; path1[3] = USDC;
        path2[0] = USDC; path2[1] = tokenB; path2[2] = tokenA; path2[3] = USDC;

        uint256[] memory amounts1 = IArbiDexRouter(router).getAmountsOut(amountIn, path1);
        uint256[] memory amounts2 = IArbiDexRouter(router).getAmountsOut(amountIn, path2);
        uint256 expectedAmount = (amountIn * multiplier)/10000;

        if (amounts1[amounts1.length-1] > expectedAmount && amounts1[amounts1.length-1] > amounts2[amounts2.length-1]) {
            // Profitable on first path, compute the precise amount of tokens we can use to maximize profits
            delete amounts2;

            tokenPath = path1;
            profit = amounts1[amounts1.length-1] - expectedAmount;

            // We don't need the expectedAmount or amounts1 variable anymore, so let's delete it and save gas
            delete expectedAmount;
            delete amounts1;

            // We no longer need the path1 or path2 variables, lets delete them to save gas
            delete path1;
            delete path2;
            
            computeProfit(amountIn);
        } else if (amounts2[amounts2.length-1] > expectedAmount && amounts2[amounts2.length-1] > amounts1[amounts1.length-1]) {
            // Profitable on second path, compute the precise amount of tokens we can use to maximize profits
            delete amounts1;

            tokenPath = path2;
            profit = amounts2[amounts2.length-1] - expectedAmount;

            // We don't need the expectedAmount or amounts2 variable anymore, so let's delete it and save gas
            delete expectedAmount;
            delete amounts2;

            // We no longer need the path1 or path2 variables, lets delete them to save gas
            delete path1;
            delete path2;
            
            computeProfit(amountIn);
        }

        if (profit > 0) {
            // If the required tokens to do arbitrage is less than or equal to how many USDC we have, let's do the swap (as long as their is some profit to be made)

            IERC20(USDC).transferFrom(treasury, address(this), requiredTokens);
            IArbiDexRouter(router).swapExactTokensForTokens(requiredTokens, minimumTokensOut, tokenPath, treasury, (block.timestamp + 120));
            emit NormalArbitrage(requiredTokens, minimumTokensOut);
        } else {
            emit NoArbitrage();
        }
    }

    function tryArbitrage() external {
        for (uint256 i = 0; i < arbPairs.length; i++) {
            conductArbitrage(arbTokens[arbPairs[i]][0], arbTokens[arbPairs[i]][1]);
        }
    }
}