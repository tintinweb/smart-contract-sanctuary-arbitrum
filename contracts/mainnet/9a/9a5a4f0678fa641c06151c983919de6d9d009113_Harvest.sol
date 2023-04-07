/**
 *Submitted for verification at Arbiscan on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IArbiDexRouter {
    function getAmountsOut(
        uint amountIn, 
        address[] memory path
    ) external view returns (
        uint[] memory amounts
    );
    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (
        uint[] memory amounts
    );
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (
        uint amountA, 
        uint amountB
    );
}

interface IArbDexPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract Harvest {
    // Address of the treasury, where tokens are sent once harvesting and swapping has been completed
    address public treasury;

    // Address of the router to complete swap calls, and obtain amountOut given a path
    address immutable public router;

    // Current owner of the contract (admin)
    address public owner;

    // Address of the USDC token
    address immutable USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    struct Pair {
        address pairAddress;
        address[2] tokens;
    }

    struct Indice {
        uint256 index;
        bool exists;
    }

    // The pairs that we are breaking and swapping
    Pair[] public harvestPairs;

    // Used to store the index of a pair in the harvestPairs array
    mapping(address => Indice) public harvestPairIndices;

    constructor(
        address _router,
        address _treasury
    ) {
        treasury = _treasury;
        router = _router;
        owner = msg.sender;
    }

    event Harvest();
    event OwnershipTransferred(address);
    event TreasuryUpdated(address);

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != owner, "Operations: Owner is already set to that address");
        require(_newOwner != address(0), "Operations: Cannot be zero address");
        owner = _newOwner;
        emit OwnershipTransferred(_newOwner);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != treasury, "Operations: Treasury is already set to that address");
        require(_treasury != address(0), "Operations: Cannot be zero address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function recoverToken(address _token) external onlyOwner {
        require(_token != address(0), "Operations: Cannot be zero address");
        IERC20(_token).transfer(treasury, IERC20(_token).balanceOf(address(this)));
    }

    function addPair(address _pairAddress) external onlyOwner {
        harvestPairs.push(Pair(_pairAddress, [IArbDexPair(_pairAddress).token0(), IArbDexPair(_pairAddress).token1()]));
    
        harvestPairIndices[_pairAddress].index = harvestPairs.length - 1;
        harvestPairIndices[_pairAddress].exists = true;
    }

    function removePair(address _pairAddress) external onlyOwner {
        require(harvestPairIndices[_pairAddress].exists == true, "Operations: Invalid pair address provided");
        uint256 index = harvestPairIndices[_pairAddress].index;
        harvestPairs[index] = harvestPairs[harvestPairs.length - 1];
        harvestPairIndices[harvestPairs[harvestPairs.length - 1].pairAddress].index = index;
        harvestPairs.pop();
        delete harvestPairIndices[_pairAddress];
    }

    function conductHarvest(address pairAddress, address tokenA, address tokenB) internal {
        if (IERC20(pairAddress).balanceOf(treasury) > 0) {
            // Lets transfer the lp pair token to this contract
            IERC20(pairAddress).transferFrom(treasury, address(this), IERC20(pairAddress).balanceOf(treasury));
            uint256 lpBalance = IERC20(pairAddress).balanceOf(address(this));

            // Lets' check if the router has the allowance to 'spend' the lp pair tokens
            if (lpBalance > IERC20(pairAddress).allowance(address(this), router)) {
                IERC20(pairAddress).approve(router, type(uint256).max);
            }

            // Lets' go ahead and break the LP pair and get the individual tokens
            IArbiDexRouter(router).removeLiquidity(tokenA, tokenB, lpBalance, 10, 10, address(this), block.timestamp);

            // Now that we broke the LP pair, lets' see how much of each token we have
            uint256 tokenABalance = IERC20(tokenA).balanceOf(address(this));
            uint256 tokenBBalance = IERC20(tokenB).balanceOf(address(this));

            // Token path utilized for swapping from tokenA or tokenB to USDC
            address[] memory tokenPath;
            tokenPath = new address[](2);

            // Lets' go ahead and calculate the tokenA amount out and do that swap
            tokenPath[0] = tokenA; tokenPath[1] = USDC;
            uint256[] memory tokenAAmounts = IArbiDexRouter(router).getAmountsOut(tokenABalance, tokenPath);
            uint256 tokenAExpectedAmountOut = (tokenAAmounts[tokenAAmounts.length-1] * 90)/100;
            IArbiDexRouter(router).swapExactTokensForTokens(tokenABalance, tokenAExpectedAmountOut, tokenPath, treasury, block.timestamp);

            // Lets' go ahead and calculate the tokenB amount out and do that swap
            tokenPath[0] = tokenB;
            uint256[] memory tokenBAmounts = IArbiDexRouter(router).getAmountsOut(tokenBBalance, tokenPath);
            uint256 tokenBExpectedAmountOut = (tokenBAmounts[tokenBAmounts.length-1] * 90)/100;
            IArbiDexRouter(router).swapExactTokensForTokens(tokenBBalance, tokenBExpectedAmountOut, tokenPath, treasury, block.timestamp);

            emit Harvest();
        }
    }

    function tryHarvest() external {
        for (uint256 i = 0; i < harvestPairs.length; i++) {
            conductHarvest(harvestPairs[i].pairAddress, harvestPairs[i].tokens[0], harvestPairs[i].tokens[1]);
        }
    }
}