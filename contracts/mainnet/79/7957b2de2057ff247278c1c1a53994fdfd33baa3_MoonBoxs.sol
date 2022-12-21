/**
 *Submitted for verification at Arbiscan on 2022-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface UniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

//https://docs.uniswap.org/protocol/reference/core/interfaces/IUniswapV3Factory
interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

//https://docs.chain.link/docs/get-the-latest-price/
interface ChainLink {
    function latestAnswer() external view returns (uint256);
}

interface IAavePool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);
}

interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address guy, uint wad) external returns (bool);
}

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TF"
        );
    }
}

// Stone.eth's MoonBox V3.0
// MoonBox，lock your eth and wait till it moons.
// 3.0 Breaking Features
// 1. Deposit your $ETH on Moonbox to earn APR from AAVE.
// 2. Borrow $BTC from AAVE.
// 3. Swap ETH/BTC On Uniswap as you pleased.
contract MoonBox {
    address public owner;
    uint256 public openTime;
    uint256 public expectationPrice;
    uint256 public Slippage;

    event CreateBox(
        uint256 timeOfBurial,
        uint256 openTime,
        uint256 expectationPrice
    );

    event AddEtherToBox(uint256 time, uint256 etherAmount);

    event OpenBox(uint256 time, uint256 etherAmount);

    //Set The Chainlink Feed Registry  https://arbiscan.io/address/0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612#code
    ChainLink chainLinkOracle =
        ChainLink(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    //Set Uniswap V3 Factory as backup when Chainlink is not properly working. https://etherscan.io/address/0x1F98431c8aD98523631AE4a59f267346ea31F984
    IUniswapV3Factory uniFactory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    address aavePoolAddress = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    address wethAddress = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address usdcAddress = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address wbtcAddress = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    /// @dev mint a
    /// @param price Your expecting price, priced in dollars.
    /// @param time The time your can open this box. Even if the price didn't meet expectations.
    constructor(address user, uint256 price, uint256 time) {
        require(time <= 2238854400, "MoonBox: The setting time for the MoonBox must be earlier than December 12, 2040.");
        owner = user;
        openTime = time;
        expectationPrice = price * 1e6;
        emit CreateBox(block.timestamp, openTime, expectationPrice);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "MoonBox: You are not the owner.");
        _;
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2 ** 255);
        z = int256(y);
    }

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @dev add ETH and change to WETH.
    function addEtherToBox() external payable onlyOwner {
        IERC20Minimal(wethAddress).deposit{value: msg.value}();
        emit AddEtherToBox(block.timestamp, msg.value);
    }

    /// @dev Exchange ETH/BTC via uniswap.
    /// @param etherToBtc This parameter is true if ETH being exchanged to BTC, or BTC to ETH.
    /// @param amountIn The number of tokens to be swapped.
    /// @param feeType The fee tier of the pool, used to determine the correct pool contract in which to execute the swap.
    function justSwap(
        bool etherToBtc,
        uint256 amountIn,
        uint24 feeType
    ) public onlyOwner {
        address pool = uniFactory.getPool(wbtcAddress, wethAddress, feeType);
        UniswapV3Pool uniPool = UniswapV3Pool(pool);
        address token1 = uniPool.token1();

        if (token1 == wethAddress) {
            uint256 price;
            if (!etherToBtc) {
                price =
                    (getETHPriceByUniswap(wbtcAddress, feeType) *
                        (1000 + Slippage)) /
                    1000;
            } else {
                price =
                    (getETHPriceByUniswap(wbtcAddress, feeType) *
                        (1000 - Slippage)) /
                    1000;
            }
            uint160 sqrtPriceLimitX96 = uint160(
                sqrt((uint256(1 ether) / price) * (2 ** 192))
            );

            uniPool.swap(
                address(this),
                !etherToBtc,
                toInt256(amountIn),
                sqrtPriceLimitX96,
                abi.encode(feeType)
            );
        } else {
            uint256 price;
            if (etherToBtc) {
                price =
                    (getETHPriceByUniswap(wbtcAddress, feeType) *
                        (1000 + Slippage)) /
                    1000;
            } else {
                price =
                    (getETHPriceByUniswap(wbtcAddress, feeType) *
                        (1000 - Slippage)) /
                    1000;
            }

            uint160 sqrtPriceLimitX96 = uint160(
                sqrt((price * (2 ** 192)) / uint256(1 ether))
            );
            uniPool.swap(
                address(this),
                etherToBtc,
                toInt256(amountIn),
                sqrtPriceLimitX96,
                abi.encode(feeType)
            );
        }
    }

    ///https://docs.uniswap.org/contracts/v3/reference/core/interfaces/callback/IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        address pool = uniFactory.getPool(
            wbtcAddress,
            wethAddress,
            abi.decode(data, (uint24))
        );
        require(msg.sender == pool);
        if (amount0Delta > 0) {
            TransferHelper.safeTransfer(
                UniswapV3Pool(pool).token0(),
                pool,
                uint256(amount0Delta)
            );
        } else if (amount1Delta > 0) {
            TransferHelper.safeTransfer(
                UniswapV3Pool(pool).token1(),
                pool,
                uint256(amount1Delta)
            );
        } else {
            // if both are not gt 0, both must be 0.
            assert(amount0Delta == 0 && amount1Delta == 0);
        }
    }

    /// @dev Supply ETH to Aave.
    /// @param amount The number of ETH to supply.
    function supplyEtherToAave(uint256 amount) external onlyOwner {
        IERC20Minimal(wethAddress).approve(aavePoolAddress, 0);
        IERC20Minimal(wethAddress).approve(aavePoolAddress, amount);
        IAavePool(aavePoolAddress).supply(
            wethAddress,
            amount,
            address(this),
            0
        );
    }

    /// @dev Borrow BTC and swap to ETH.
    /// @param amount The number of BTC to borrow.
    /// @param feeType The fee tier of the BTC/ETH pool, used to determine the correct pool contract in which to execute the swap.
    function borrowBtcAndSwapToEther(
        uint256 amount,
        uint24 feeType
    ) external onlyOwner {
        IAavePool(aavePoolAddress).borrow(
            wbtcAddress,
            amount,
            2,
            0,
            address(this)
        );
        justSwap(false, amount, feeType);
    }

    /// @dev Repay BTC.
    /// @param amount The number of BTC to be repaid.
    function repayBtc(uint256 amount) external onlyOwner {
        IERC20Minimal(wbtcAddress).approve(aavePoolAddress, 0);
        IERC20Minimal(wbtcAddress).approve(aavePoolAddress, amount);
        IAavePool(aavePoolAddress).repay(wbtcAddress, amount, 2, address(this));
    }

    /// @dev Withdraw ETH.
    function withdrawEtherFromAave(uint256 amount) external onlyOwner {
        IAavePool(aavePoolAddress).withdraw(wethAddress, amount, address(this));
    }

    /// @dev call this function to withdraw ETH when a MoonBox is overdue.
    function openBoxWhenTimeout() external onlyOwner {
        require(
            block.timestamp > openTime,
            "MoonBox: It's not time to open it yet."
        );
        _withdraw();
    }

    /// @dev call this function to withdraw ETH when the ETH/USDC price on Uniswap is higher than a MoonBox's expectationPrice.
    function openBoxWhenUSDCPriceExceed(uint24 fee) external onlyOwner {
        require(
            expectationPrice <= getETHPriceByUniswap(usdcAddress, fee),
            "MoonBox: Price has not met your expectation."
        );
        _withdraw();
    }

    /// @dev call this function to withdraw ETH when the ETH/USDT price on Uniswap is higher than a MoonBox's expectationPrice.
    function openBoxWhenUSDTPriceExceed(uint24 fee) external onlyOwner {
        require(
            expectationPrice <=
                getETHPriceByUniswap(
                    0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
                    fee
                ),
            "MoonBox: Price has not met your expectation."
        );
        _withdraw();
    }

    /// @dev call this function to determine the ETH/USD price on ChainLink and whether withdraw the ETH when Uniswap is abnormal.
    function openBoxByChainLink() external onlyOwner {
        require(
            expectationPrice <= getETHUSDPriceByChainLink(),
            "MoonBox: Price has not met your expectation."
        );
        _withdraw();
    }

    /// @dev return ETH to box holder based on tokenId and reset ether amount to 0.
    function _withdraw() private {
        uint256 amount = getBalance(wethAddress);
        IERC20Minimal(wethAddress).withdraw(amount);
        payable(owner).transfer(amount);

        emit OpenBox(block.timestamp, amount);
    }

    /// @dev This function can be called at the end of the time to retrieve the token, if there were to be an airdrop or an external contract modification that prevents it from being called.
    function withdrawWindfall(address tokenAddress) external onlyOwner {
        require(
            block.timestamp > openTime,
            "MoonBox: It's not time to open it yet."
        );
        uint256 amount = getBalance(tokenAddress);
        TransferHelper.safeTransfer(tokenAddress, owner, amount);
    }

    /// @dev Set the maximum Slippage allowed for swap
    function setSlippage(uint256 slip) external onlyOwner {
        Slippage = slip;
    }

    receive() external payable {}

    function getBalance(address token) public view returns (uint256) {
        return IERC20Minimal(token).balanceOf(address(this));
    }

    function getETHPriceByUniswap(
        address token,
        uint24 fee
    ) public view returns (uint256) {
        address pool = uniFactory.getPool(wethAddress, token, fee);
        UniswapV3Pool uniPool = UniswapV3Pool(pool);
        (uint160 sqrtPrice, , , , , , ) = uniPool.slot0();
        if (uniPool.token1() == wethAddress) {
            return 1 ether / ((uint256(sqrtPrice) ** 2) / (2 ** 192));
        } else {
            return ((uint256(sqrtPrice) ** 2) * 1 ether) / (2 ** 192);
        }
    }

    ///https://docs.chain.link/docs/feed-registry/
    function getETHUSDPriceByChainLink() public view returns (uint256) {
        return chainLinkOracle.latestAnswer() / 100;
    }
}

contract MoonBoxs {
    event CreatNewContract(address indexed owner, address contractAddr);

    constructor(uint256 price, uint256 time) {
        MoonBox box = new MoonBox(msg.sender, price, time);
        emit CreatNewContract(msg.sender, address(box));
    }

    function creatNewContract(uint256 price, uint256 time) external {
        MoonBox box = new MoonBox(msg.sender, price, time);
        emit CreatNewContract(msg.sender, address(box));
    }
}