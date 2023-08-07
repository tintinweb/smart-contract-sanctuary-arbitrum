// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IInscription.sol";
import "./interfaces/IInscriptionFactory.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IWETH.sol";
import "./libs/TransferHelper.sol";
import "./libs/PriceFormat.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "./interfaces/ICustomizedVesting.sol";

// This contract will be created while deploying
// The liquidity can not be removed
contract InitialFairOffering {
    int24 private constant MIN_TICK = -887272; // add liquidity with full range
    int24 private constant MAX_TICK = -MIN_TICK; // add liquidity with full range
    int24 public constant TICK_SPACING = 60; // Tick space is 60
    uint24 public constant UNISWAP_FEE = 3000;

    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IUniswapV3Factory public uniswapV3Factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IWETH public weth;

    IInscriptionFactory public inscriptionFactory;

    bool public liquidityAdded = false;

    struct MintData {
        uint128 ethAmount; // eth payed by user(deduce commission)
        uint128 tokenAmount; // token minted by user
        uint128 tokenLiquidity; // token liquidity saved in this contract
    }

    mapping(address => MintData) public mintData;

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }
    mapping(uint => Deposit) public deposits; // uint - tokenId of liquidity NFT
    mapping(uint => uint) public tokenIds;
    uint public tokenIdCount;
    uint public totalBackToDeployAmount;
    uint public totalRefundedAmount;

    struct Position {
        uint96 nonce;
        address operator;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        uint256 tokenId;
    }

    struct Pool {
        address pool;
        address token0;
        address token1;
        uint uintRate;
        uint160 sqrtPriceX96;
    }
    Pool public poolData;

    IInscriptionFactory.Token public token;

    event MintDeposit(
        address token,
        uint128 ethAmount,
        uint128 tokenAmount,
        uint128 tokenLiquidity
    );
    event Refund(
        address sender,
        uint128 etherAmount,
        uint128 senderToken,
        uint128 liquidityToken,
        uint16 refundFee
    );

    // This contract can be only created by InscriptionFactory contract
    constructor(address _inscriptionFactory, address _weth) {
        inscriptionFactory = IInscriptionFactory(_inscriptionFactory);
        weth = IWETH(_weth);
    }

    receive() external payable {
        // Change all received ETH to WETH
        if (msg.sender != address(weth))
            TransferHelper.safeTransferETH(address(weth), msg.value);
    }

    function initialize(IInscriptionFactory.Token memory _token) public {
        // Check if the deployer has sent the liquidity ferc20 tokens
        require(
            address(inscriptionFactory) == msg.sender,
            "Only inscription factory allowed"
        );
        require(_token.inscriptionId > 0, "token data wrong");
        token = _token;
        _initializePool(address(weth), _token.addr);
    }

    function _initializePool(
        address _weth,
        address _token
    )
        private
        returns (
            address _token0,
            address _token1,
            uint _uintRate,
            uint160 _sqrtPriceX96,
            address _pool
        )
    {
        _token0 = _token;
        _token1 = _weth;

        _uintRate = PriceFormat.getInitialRate(
            token.crowdFundingRate,
            token.liquidityEtherPercent,
            token.liquidityTokenPercent,
            token.limitPerMint
        ); // weth quantity per token
        require(_uintRate > 0, "uint rate zero");

        if (_token < _weth) {
            _sqrtPriceX96 = PriceFormat.priceToSqrtPriceX96(
                int(_uintRate),
                TICK_SPACING
            );
        } else {
            _token0 = _weth;
            _token1 = _token;
            _uintRate = 10 ** 36 / _uintRate; // token quantity per weth
            _sqrtPriceX96 = PriceFormat.priceToSqrtPriceX96(
                int(_uintRate),
                TICK_SPACING
            );
        }
        _pool = nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            _token0,
            _token1,
            UNISWAP_FEE,
            _sqrtPriceX96
        );
        poolData = Pool(_pool, _token0, _token1, _uintRate, _sqrtPriceX96);
    }

    function addLiquidity(uint16 slippage) public {
        require(slippage >= 0 && slippage <= 10000, "slippage error");
        require(
            IInscription(token.addr).totalRollups() >= token.maxRollups,
            "mint not finished"
        );
        require(
            uniswapV3Factory.getPool(address(weth), token.addr, UNISWAP_FEE) >
                address(0x0),
            "Pool not exist, create pool in uniswapV3 manually"
        );
        require(token.liquidityEtherPercent > 0, "no liquidity add");
        uint256 totalTokenLiquidity = IInscription(token.addr).balanceOf(
            address(this)
        );
        require(totalTokenLiquidity > 0, "no token in fto contract");
        uint256 balanceOfWeth = IWETH(weth).balanceOf(address(this));
        require(balanceOfWeth > 0, "no eth in fto contract");

        // Send ether back to deployer, the eth liquidity is based on the balance of this contract. So, anyone can send eth to this contract
        uint256 backToDeployAmount = (balanceOfWeth *
            (10000 - token.liquidityEtherPercent)) / 10000;
        uint256 maxBackToDeployAmount = (token.maxRollups *
            (10000 - inscriptionFactory.fundingCommission()) *
            token.crowdFundingRate *
            (10000 - token.liquidityEtherPercent)) / 100000000;

        uint256 sum = totalBackToDeployAmount + backToDeployAmount;

        if (sum <= maxBackToDeployAmount) {
            weth.withdraw(backToDeployAmount); // Change WETH to ETH
            TransferHelper.safeTransferETH(token.deployer, backToDeployAmount);
            totalBackToDeployAmount += backToDeployAmount;
        } else {
            backToDeployAmount = 0;
        }

        liquidityAdded = true; // allow the transferring of token

        _mintNewPosition(
            balanceOfWeth - backToDeployAmount,
            totalTokenLiquidity, // ferc20 token amount
            MIN_TICK,
            MAX_TICK,
            slippage
        );
    }

    function refund() public {
        require(mintData[msg.sender].ethAmount > 0, "you have not mint");
        require(
            IInscription(token.addr).totalRollups() < token.maxRollups,
            "mint has finished"
        );

        if (
            token.isVesting &&
            token.customizedVestingContractAddress != address(0x0)
        ) {
            // standard fto mode
            ICustomizedVesting(token.customizedVestingContractAddress)
                .removeAllocation(msg.sender, mintData[msg.sender].tokenAmount);
        } else {
            // not fto mode
            // check balance and allowance of tokens, if the balance or allowance is smaller than the what he/she get while do mint, the refund fail
            require(
                IInscription(token.addr).balanceOf(msg.sender) >=
                    mintData[msg.sender].tokenAmount,
                "Your balance token not enough"
            );
            require(
                IInscription(token.addr).allowance(msg.sender, address(this)) >=
                    mintData[msg.sender].tokenAmount,
                "Your allowance not enough"
            );

            // Burn the tokens from msg.sender
            IInscription(token.addr).burnFrom(
                msg.sender,
                mintData[msg.sender].tokenAmount
            );
        }

        // Burn the token liquidity in this contract
        uint128 refundToken = (mintData[msg.sender].tokenLiquidity *
            token.refundFee) / 10000;
        IInscription(token.addr).burn(
            address(this),
            mintData[msg.sender].tokenLiquidity - refundToken
        );

        // Refund Ether
        uint128 refundEth = (mintData[msg.sender].ethAmount * token.refundFee) /
            10000;
        weth.withdraw(mintData[msg.sender].ethAmount - refundEth); // Change WETH to ETH
        TransferHelper.safeTransferETH(
            msg.sender,
            mintData[msg.sender].ethAmount - refundEth
        ); // Send balance to donator

        totalRefundedAmount =
            totalRefundedAmount +
            mintData[msg.sender].tokenAmount +
            mintData[msg.sender].tokenLiquidity -
            refundToken;

        emit Refund(
            msg.sender,
            mintData[msg.sender].ethAmount - refundEth,
            mintData[msg.sender].tokenAmount,
            mintData[msg.sender].tokenLiquidity - refundToken,
            token.refundFee
        );

        mintData[msg.sender].tokenAmount = 0;
        mintData[msg.sender].tokenLiquidity = 0;
        mintData[msg.sender].ethAmount = 0;
    }

    function positions(
        uint128 pageNo,
        uint128 pageSize
    ) public view returns (Position[] memory _positions) {
        require(pageNo > 0 && pageSize > 0, "pageNo and size can not be zero");
        Position[] memory filtered = new Position[](tokenIdCount);
        uint128 count = 0;
        for (uint128 i = 0; i < tokenIdCount; i++) {
            (
                uint96 nonce,
                address operator,
                address token0,
                address token1,
                uint24 fee,
                int24 tickLower,
                int24 tickUpper,
                uint128 liquidity,
                uint256 feeGrowthInside0LastX128,
                uint256 feeGrowthInside1LastX128,
                uint128 tokensOwed0,
                uint128 tokensOwed1
            ) = nonfungiblePositionManager.positions(tokenIds[i]);
            if (liquidity == 0) continue;
            filtered[count] = Position(
                nonce,
                operator,
                token0,
                token1,
                fee,
                tickLower,
                tickUpper,
                liquidity,
                feeGrowthInside0LastX128,
                feeGrowthInside1LastX128,
                tokensOwed0,
                tokensOwed1,
                tokenIds[i]
            );
            count++;
        }

        uint128 startIndex = (pageNo - 1) * pageSize;
        if (startIndex > count) return new Position[](0);

        _positions = new Position[](pageSize);
        uint128 index;
        for (uint128 i = 0; i < filtered.length; i++) {
            if (i >= startIndex && i < startIndex + pageSize) {
                _positions[index] = filtered[i];
                index++;
            } else continue;
        }
    }

    // Call from Inscription::mint only
    function setMintData(
        address _addr,
        uint128 _ethAmount,
        uint128 _tokenAmount,
        uint128 _tokenLiquidity
    ) public {
        require(msg.sender == token.addr, "Only call from inscription allowed");
        require(
            _ethAmount > 0 &&
                _tokenAmount > 0 &&
                _tokenLiquidity > 0 &&
                _addr > address(0x0),
            "setEtherLiquidity wrong params"
        );

        mintData[_addr].ethAmount = mintData[_addr].ethAmount + _ethAmount;
        mintData[_addr].tokenAmount =
            mintData[_addr].tokenAmount +
            _tokenAmount;
        mintData[_addr].tokenLiquidity =
            mintData[_addr].tokenLiquidity +
            _tokenLiquidity;

        emit MintDeposit(msg.sender, _ethAmount, _tokenAmount, _tokenLiquidity);
    }

    function collectFee(
        uint256 _tokenId
    ) public returns (uint256 amount0, uint256 amount1) {
        // Collect
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function _mintNewPosition(
        uint amount0ToAdd,
        uint amount1ToAdd,
        int24 lowerTick,
        int24 upperTick,
        uint16 slippage
    )
        private
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1)
    {
        // If weth < ferc20, set token0/amount0 is weth and token1/amount1 is ferc20
        // Otherwise, set token0/amount0 is ferc20, and token1/amount1 is weth
        address _token0;
        address _token1;
        uint _amount0;
        uint _amount1;
        int24 _lowerTick;
        int24 _upperTick;
        if (address(weth) > token.addr) {
            _token0 = token.addr;
            _token1 = address(weth);
            _amount0 = amount1ToAdd;
            _amount1 = amount0ToAdd;
            _lowerTick = lowerTick;
            _upperTick = upperTick;
        } else {
            _token0 = address(weth);
            _token1 = token.addr;
            _amount0 = amount0ToAdd;
            _amount1 = amount1ToAdd;
            _lowerTick = -upperTick;
            _upperTick = -lowerTick;
        }

        // Approve the position manager
        TransferHelper.safeApprove(
            _token0,
            address(nonfungiblePositionManager),
            _amount0
        );
        TransferHelper.safeApprove(
            _token1,
            address(nonfungiblePositionManager),
            _amount1
        );

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager
            .MintParams({
                token0: _token0,
                token1: _token1,
                fee: UNISWAP_FEE,
                tickLower: (lowerTick / TICK_SPACING) * TICK_SPACING, // full range
                tickUpper: (upperTick / TICK_SPACING) * TICK_SPACING,
                amount0Desired: _amount0,
                amount1Desired: _amount1,
                amount0Min: (_amount0 * (10000 - slippage)) / 10000, // slipage
                amount1Min: (_amount1 * (10000 - slippage)) / 10000,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        _createDeposit(msg.sender, tokenId);

        if (amount0 < _amount0) {
            TransferHelper.safeApprove(
                _token0,
                address(nonfungiblePositionManager),
                0
            );
        }

        if (amount1 < _amount1) {
            TransferHelper.safeApprove(
                _token1,
                address(nonfungiblePositionManager),
                0
            );
        }
    }

    function _createDeposit(address _operator, uint _tokenId) private {
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(_tokenId);

        if (deposits[_tokenId].owner == address(0x0)) {
            tokenIds[tokenIdCount] = _tokenId;
            tokenIdCount++;
        }

        deposits[_tokenId] = Deposit({
            owner: _operator,
            liquidity: liquidity,
            token0: token0,
            token1: token1
        });
    }

    // function onERC721Received(
    //     address operator,
    //     address from,
    //     uint tokenId,
    //     bytes calldata
    // ) public returns (bytes4) {
    //     _createDeposit(operator, tokenId);
    //     return IERC721Receiver.onERC721Received.selector;
    // }

    // Add liquidity with lower/upper tick
    // function addLiquidity(
    //     uint16 ratio,            // The ratio of balance of eths and tokens will be added to liquidity pool
    //     int24 lowerTick,
    //     int24 upperTick,
    //     uint16 slippage
    // ) public {
    //     require(ratio > 0 && ratio <= 10000, "ratio error");
    //     require(slippage >= 0 && slippage <= 10000, "slippage error");
    //     require(IInscription(token.addr).balanceOf(msg.sender) >= token.minBalanceToManagerLiquidity, "Balance not enough to add liquidity");
    //     require(IInscription(token.addr).totalRollups() >= token.maxRollups, "mint not finished");
    //     require(uniswapV3Factory.getPool(address(weth), token.addr, UNISWAP_FEE) > address(0x0), "Pool not exist, create pool in uniswapV3 manually");
    //     require(token.liquidityEtherPercent > 0, "no liquidity add");
    //     uint256 totalTokenLiquidity = IInscription(token.addr).balanceOf(address(this));
    //     require(totalTokenLiquidity > 0, "no token in fto");
    //     uint256 balanceOfWeth = IWETH(weth).balanceOf(address(this));
    //     require(balanceOfWeth > 0, "no eth in fto");

    //     // Send ether back to deployer, the eth liquidity is based on the balance of this contract. So, anyone can send eth to this contract
    //     uint256 backToDeployAmount = balanceOfWeth * (10000 - token.liquidityEtherPercent) * ratio / 100000000;
    //     uint256 maxBackToDeployAmount = token.maxRollups * (10000 - inscriptionFactory.fundingCommission()) * token.crowdFundingRate * (10000 - token.liquidityEtherPercent) / 100000000;

    //     uint256 sum = totalBackToDeployAmount + backToDeployAmount;

    //     if(sum <= maxBackToDeployAmount) {
    //         weth.withdraw(backToDeployAmount);  // Change WETH to ETH
    //         TransferHelper.safeTransferETH(token.deployer, backToDeployAmount);
    //         totalBackToDeployAmount += backToDeployAmount;
    //     } else {
    //         backToDeployAmount = 0;
    //     }

    //     _mintNewPosition(
    //         balanceOfWeth * ratio / 10000 - backToDeployAmount,
    //         totalTokenLiquidity * ratio / 10000,  // ferc20 token amount
    //         lowerTick == 0 ? MIN_TICK : lowerTick,
    //         upperTick == 0 ? MAX_TICK : upperTick,
    //         slippage
    //     );
    // }

    // function decreaseLiquidity(
    //     uint tokenId
    // ) public returns (uint amount0, uint amount1) {
    //     require(IInscription(token.addr).totalRollups() >= token.maxRollups, "mint not finished");
    //     require(IInscription(token.addr).balanceOf(msg.sender) >= token.minBalanceToManagerLiquidity, "Balance not enough to decrease liquidity");
    //     uint128 decreaseLiquidityAmount = deposits[tokenId].liquidity;

    //     INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
    //         tokenId: tokenId,
    //         liquidity: decreaseLiquidityAmount,
    //         amount0Min: 0,
    //         amount1Min: 0,
    //         deadline: block.timestamp
    //     });

    //     (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);

    //     // Collect
    //     INonfungiblePositionManager.CollectParams memory params2 = INonfungiblePositionManager.CollectParams({
    //         tokenId: tokenId,
    //         recipient: address(this),
    //         amount0Max: type(uint128).max,
    //         amount1Max: type(uint128).max
    //     });

    //     (amount0, amount1) = nonfungiblePositionManager.collect(params2);

    //     deposits[tokenId].liquidity = 0;
    // }

    // function setMinBalanceToManagerLiquidity(uint128 _minBalanceToManagerLiquidity) public {
    //     require(msg.sender == token.deployer, "Call must be deployer");
    //     token.minBalanceToManagerLiquidity = _minBalanceToManagerLiquidity;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomizedCondition {
    function getStatus(address _tokenAddress, address _sender) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomizedVesting {
    function addAllocation(address recipient, uint amount) external;
    function removeAllocation(address recipient, uint amount) external;
    function claim() external;
    function available(address address_) external view returns (uint);
    function released(address address_) external view returns (uint);
    function outstanding(address address_) external view returns (uint);
    function setTokenAddress(address _tokenAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ICustomizedCondition.sol";
import "./ICustomizedVesting.sol";

interface IInscription {
    struct FERC20 {
        uint128 cap;                                            // Max amount
        uint128 limitPerMint;                                   // Limitaion of each mint

        address onlyContractAddress;                            // Only addresses that hold these assets can mint
        uint32  maxMintSize;                                    // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
        uint64  inscriptionId;                                  // Inscription Id
        
        uint128 onlyMinQuantity;                                // Only addresses that the quantity of assets hold more than this amount can mint
        uint128 crowdFundingRate;                               // rate of crowdfunding

        address whitelist;                                      // whitelist contract
        uint40  freezeTime;                                     // The frozen time (interval) between two mints is a fixed number of seconds. You can mint, but you will need to pay an additional mint fee, and this fee will be double for each mint.
        uint16  fundingCommission;                              // commission rate of fund raising, 1000 means 10%
        uint16  liquidityTokenPercent;
        bool    isIFOMode;                                      // receiving fee of crowdfunding

        address payable inscriptionFactory;                     // Inscription factory contract address
        uint128 baseFee;                                        // base fee of the second mint after frozen interval. The first mint after frozen time is free.

        address payable ifoContractAddress;                     // Initial fair offering contract
        uint96  maxRollups;                                     // Max rollups

        ICustomizedCondition customizedConditionContractAddress;// Customized condition for mint
        ICustomizedVesting customizedVestingContractAddress;    // Customized vesting contract
    }

    function mint(address _to) payable external;
    function getFerc20Data() external view returns(FERC20 memory);
    function balanceOf(address owner) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function totalRollups() external view returns(uint256);
    function burn(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInscriptionFactory {
    struct Token {
        uint128         cap;                                // Hard cap of token
        uint128         limitPerMint;                       // Limitation per mint

        address         onlyContractAddress;
        uint32          maxMintSize;                        // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
        uint64          inscriptionId;                      // Inscription id

        uint128         onlyMinQuantity;
        uint128         crowdFundingRate;
				
        address         addr;                               // Contract address of inscribed token
        uint40          freezeTime;
        uint40          timestamp;                          // Inscribe timestamp
        uint16          liquidityTokenPercent;              // 10000 is 100%

        address         ifoContractAddress;                 // Initial fair offerting contract
        uint16          refundFee;                          // To avoid the refund attack, deploy sets this fee rate
        uint40          startTime;
        uint40          duration;

        address         customizedConditionContractAddress; // Customized condition for mint
        uint96          maxRollups;                         // max rollups

        address         deployer;                           // Deployer
        string          tick;                               // same as symbol in ERC20, max 5 chars, 10 bytes(80)
        uint16          liquidityEtherPercent;
        
        string          name;                               // full name of token, max 16 chars, 32 bytes(256)

        address         customizedVestingContractAddress;   // Customized contract for token vesting
        bool            isIFOMode;                          // is ifo mode
        bool            isWhitelist;                        // is whitelst condition
        bool            isVesting;
        bool            isVoted;
        
        string          logoUrl;                            // logo url, ifpfs cid, 64 chars, 128 bytes, 4 slots, ex.QmPK1s3pNYLi9ERiq3BDxKa4XosgWwFRQUydHUtz4YgpqB
    }

    function deploy(
        string memory _name,
        string memory _tick,
        uint256 _cap,
        uint256 _limitPerMint,
        uint256 _maxMintSize, // The max lots of each mint
        uint256 _freezeTime, // Freeze seconds between two mint, during this freezing period, the mint fee will be increased
        address _onlyContractAddress, // Only the holder of this asset can mint, optional
        uint256 _onlyMinQuantity, // The min quantity of asset for mint, optional
        uint256 _crowdFundingRate,
        address _crowdFundingAddress
    ) external returns (address _inscriptionAddress);

    function updateStockTick(string memory _tick, bool _status) external;

    function transferOwnership(address newOwner) external;

    function getIncriptionIdByAddress(address _addr) external view returns(uint256);

    function getIncriptionByAddress(address _addr) external view returns(Token memory tokens, uint256 totalSupplies, uint256 totalRollups);

    function fundingCommission() external view returns(uint16);

    function isExisting(string memory _tick) external view returns(bool);

    function isLiquidityAdded(address _addr) external view returns(bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    function positions(
        uint256 tokenId
    ) external view returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "./IERC20.sol";

interface IWETH {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function totalSupply() external view returns(uint);
    function deposit() external payable;
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Logarithm {
    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) public pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last digit, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x, int256 scale, int256 halfScale) public pure returns (int256 result) {
        require(x > 0);
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= scale) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = mostSignificantBit(uint256(x / scale));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * scale;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == scale) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(halfScale); delta > 0; delta >>= 1) {
                y = (y * y) / scale;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * scale) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.9.0;

import "./TickMath.sol";
import "./Logarithm.sol";

library PriceFormat {
    function getInitialRate(
        uint128 _crowdFundingRate,
        uint16  _etherToLiquidityPercent,
        uint16  _tokenToLiquidityPercent,
        uint128 _limitPerMint
    ) internal pure returns(uint) {
        // return _crowdFundingRate * _etherToLiquidityPercent * (10000 - _tokenToLiquidityPercent) * 10**14 / _tokenToLiquidityPercent / _limitPerMint;
        // To avoid the result is zero, the params must satisfy the following condition:
        // _crowdFundingRate * 10**18 > _limitPerMint
        uint128 precision = 10**12;
        return (_crowdFundingRate / precision) * _etherToLiquidityPercent * (10000 - _tokenToLiquidityPercent) * 10**14 / _tokenToLiquidityPercent / (_limitPerMint / precision);
    }

    function tickToSqrtPriceX96(int24 _tick) internal pure returns(uint160) {
        return TickMath.getSqrtRatioAtTick(_tick);
    }

    function priceToTick(int256 _price, int24 _tickSpace) internal pure returns(int24) {
        // math.log(10**18,2) * 10**18 = 59794705707972520000
        // math.log(1.0001,2) * 10**18 = 144262291094538
        return round((Logarithm.log2(_price * 1e18, 1e18, 5e17) - 59794705707972520000 ), (int(144262291094538) * _tickSpace)) * _tickSpace;
    }

    function priceToSqrtPriceX96(int256 _price, int24 _tickSpace) internal pure returns(uint160) {
        return tickToSqrtPriceX96(priceToTick(_price, _tickSpace));
    }

    function round(int256 _a, int256 _b) internal pure returns(int24) {
        return int24(10000 * _a / _b % 10000 > 10000 / 2 ? _a / _b + 1 : _a / _b);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.9.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        // uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        int256 absTick = tick < 0 ? int256(-int256(tick)) : int256(int256(tick));
        require(absTick <= int256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}