/**
 *Submitted for verification at Arbiscan.io on 2024-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract $Cripbot {
    address public admin;
    IERC20 public token;
    IUniswapV2Pair public uniswapPair;
    uint256 public tokensSold;
    // uint256 public saleEnd;
    uint256 public totalTokensForSale;

    event TokensPurchased(address indexed buyer, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor(
        address _admin,
        address _token,
        address _uniswapPair,
        uint256 _totalTokensForSale
    ) {
        //  uint256 _saleDuration
        admin = _admin; // msg.sender;
        token = IERC20(_token);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        totalTokensForSale = _totalTokensForSale;
        //  saleEnd = block.timestamp + _saleDuration;
    }

    function getTokenPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = uniswapPair.getReserves();
        address token0 = uniswapPair.token0();
        address token1 = uniswapPair.token1();

        if (token0 == address(token)) {
            // Price in terms of the other token in the pair (token1)
            require(reserve0 > 0, "Insufficient liquidity for token0");
            require(reserve1 > 0, "Insufficient liquidity for token1");
            return (uint256(reserve1) * 1e18) / uint256(reserve0);
        } else if (token1 == address(token)) {
            // Price in terms of the other token in the pair (token0)
            require(reserve1 > 0, "Insufficient liquidity for token1");
            require(reserve0 > 0, "Insufficient liquidity for token0");
            return (uint256(reserve0) * 1e18) / uint256(reserve1);
        } else {
            revert("Token not found in Uniswap pair");
        }
    }

    function buyTokens() external payable {
        //   require(block.timestamp < saleEnd, "Sale has ended");
        uint256 tokenPrice = getTokenPrice();
        uint256 tokensToBuy = (msg.value * 1e18) / tokenPrice;
        require(
            tokensSold + tokensToBuy <= totalTokensForSale,
            "Not enough tokens left for sale"
        );

        // Transfer received ETH to the seller (admin)
        payable(admin).transfer(msg.value);

        tokensSold += tokensToBuy;
        token.transfer(msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, tokensToBuy);
    }

    function buyTokensByETH(uint256 tokenAmount) external payable {
        uint256 tokenPrice = getTokenPrice();
        uint256 requiredETH = (tokenAmount * tokenPrice) / 1e18;
        require(msg.value >= requiredETH, "Insufficient ETH sent");
        require(
            tokensSold + tokenAmount <= totalTokensForSale,
            "Not enough tokens left for sale"
        );

        // Transfer received ETH to the seller (admin)
        payable(admin).transfer(msg.value);

        tokensSold += tokenAmount;
        token.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount);

        // Refund excess ETH if any
        if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value - requiredETH);
        }
    }

    /* function endSale() external onlyAdmin {
        require(block.timestamp >= saleEnd, "Sale not yet ended");
        token.transfer(admin, token.balanceOf(address(this)));
        payable(admin).transfer(address(this).balance);
    }
 */
    function withdrawFunds() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    function withdrawUnsoldTokens() external onlyAdmin {
        //  require(block.timestamp >= saleEnd, "Sale not yet ended");
        token.transfer(admin, token.balanceOf(address(this)));
    }
}