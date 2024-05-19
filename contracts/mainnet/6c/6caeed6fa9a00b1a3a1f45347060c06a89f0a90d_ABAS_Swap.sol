/**
 *Submitted for verification at Arbiscan.io on 2024-05-18
*/

// File: contracts/ABAS_Swaps/ABAS-Swap-help-main/IERC20.sol


pragma solidity >=0.6.12;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/ABAS_Swaps/ABAS-Swap-help-main/IBentoBoxV1.sol


pragma solidity >=0.6.12;


interface IBentoBoxV1 {
    function toAmount(
        address _token,
        uint256 _share,
        bool _roundUp
    ) external view returns (uint256);

    function withdraw(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deposit(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address cloneAddress);

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function balanceOf(IERC20, address) external view returns (uint256);

    function totals(IERC20) external view returns (uint128 elastic, uint128 base);

    function flashLoan(
        address borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);
}

// File: contracts/ABAS_Swaps/ABAS-Swap-help-main/Ipool.sol



pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @notice Trident pool interface.
interface IPool {
    /// @notice Executes a swap from one token to another.
    /// @dev The input tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function swap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Executes a swap from one token to another with a callback.
    /// @dev This function allows borrowing the output tokens and sending the input tokens in the callback.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function flashSwap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Mints liquidity tokens.
    /// @param data ABI-encoded params that the pool requires.
    /// @return liquidity The amount of liquidity tokens that were minted for the user.
    function mint(bytes calldata data) external returns (uint256 liquidity);

    /// @notice Burns liquidity tokens.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return withdrawnAmounts The amount of various output tokens that were sent to the user.
    function burn(bytes calldata data) external returns (TokenAmount[] memory withdrawnAmounts);

    /// @notice Burns liquidity tokens for a single output token.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return amountOut The amount of output tokens that were sent to the user.
    function burnSingle(bytes calldata data) external returns (uint256 amountOut);

    /// @return A unique identifier for the pool type.
    function poolIdentifier() external pure returns (bytes32);

    /// @return An array of tokens supported by the pool.
    function getAssets() external view returns (address[] memory);
    function getReserves() external view returns (uint112, uint112, uint32);
    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
    function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
    function getAmountIn(bytes calldata data) external view returns (uint256 finalAmountIn);

    /// @dev This event must be emitted on all swaps.
    event Swap(address indexed recipient, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// @dev This struct frames output tokens for burns.
    struct TokenAmount {
        address token;
        uint256 amount;
    }
        function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/ABAS_Swaps/ABAS-Swap-help-main/swap.sol


pragma solidity >=0.8.0;





interface IWETH {
    function withdraw(uint256 amount) external;
    function deposit() payable external;
}




contract ABAS_Swap {
    
  IBentoBoxV1 public constant bentobox = IBentoBoxV1(0x74c764D41B77DBbb4fe771daB1939B00b146894A);
  IPool public constant constant_product_pair = IPool(0x911a89dE0430A5cE3699E57D508f8678Afa1fffc); // ABAS-ETH (1%)
  IPool public constant stable_product_pair = IPool(0xB059CF6320B29780C39817c42aF1a032bf821D90); // USDC-USDT (0.01%)
  IERC20 public constant ETH  = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  IWETH public constant WETH  = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  IERC20 public constant ABAS = IERC20(0x0B549125fbEA37E52Ee05FA388a3A0a7Df792Fa7);
  IERC20 public constant USDT = IERC20(0x94b008aA00579c1307B0EF2c499aD98a8ce58e58);

  constructor(){}
    
  // Example swapping between tokens on a constant-product pool
    function swapToETH(address payable _to, uint AmountOfABAS, uint minAmountOfETH) public {
        
            ABAS.transferFrom(msg.sender, address(this), AmountOfABAS);

            uint ABAS_Balance_is = ABAS.balanceOf(address(this));


            // Transfer the specified amount of ABAS to BentoBox
            ABAS.transfer(address(bentobox), ABAS_Balance_is);
        
            // Deposit the specified amount of ABAS into BentoBox
            bentobox.deposit(ABAS, address(bentobox), address(constant_product_pair), ABAS_Balance_is, 0);
        
            // Encode call data to make the swap
            bytes memory swapData = abi.encode(address(ABAS), address(this), true);
        
        
            // Execute the Swap
            uint amountOut = constant_product_pair.swap(swapData);
        
            // Check minOut to prevent slippage (example of using 0 for minOut has no slippage protection)
            require(amountOut >= minAmountOfETH, "You would not recieve enough tokens for this swap, try again slippage issue");
        
            // Call the withdraw function of the WETH contract
            WETH.withdraw(IERC20(ETH).balanceOf(address(this)));

            (bool sent, ) = _to.call{value: address(this).balance }("");
            require(sent, "Failed to send Ether");
    }

  
  // Example swapping between tokens on a constant-product pool
    function swapToABAS(address payable _to, uint minAmountOfABAS) public payable {
            
            // Call the withdraw function of the WETH contract
            WETH.deposit{value: msg.value}();

            /*
            uint ABAS_Balance_is = ABAS.balanceOf(address(this));
            // Transfer the specified amount of ABAS to BentoBox
            ABAS.transfer(address(bentobox), ABAS_Balance_is);
        
            // Deposit the specified amount of ABAS into BentoBox
            bentobox.deposit(ABAS, address(bentobox), address(constant_product_pair), ABAS_Balance_is, 0);
        
            // Encode call data to make the swap
            bytes memory swapData = abi.encode(address(ABAS), address(this), true);
        
        */
          uint wethBalanceOnContract = IERC20(ETH).balanceOf(address(this));
          // Transfer the specified amount of WETH to BentoBox
            IERC20(ETH).transfer(address(bentobox), wethBalanceOnContract);
        
            // Deposit the specified amount of ABAS into BentoBox
            bentobox.deposit(ETH, address(bentobox), address(constant_product_pair), wethBalanceOnContract, 0);
        
            // Encode call data to make the swap
            bytes memory swapData = abi.encode(address(ETH), address(this), true);

            // Execute the Swap
            uint amountOut = constant_product_pair.swap(swapData);
        
            // Check minOut to prevent slippage (example of using 0 for minOut has no slippage protection)
            require(amountOut >= minAmountOfABAS, "You would not recieve enough tokens for this swap, try again slippage issue");
        
            // Call the transfer to the person intended
            ABAS.transfer(_to, ABAS.balanceOf(address(this)));

    }
	  //Allow ETH to enter
	receive() external payable {

	}


	fallback() external payable {

	}
}