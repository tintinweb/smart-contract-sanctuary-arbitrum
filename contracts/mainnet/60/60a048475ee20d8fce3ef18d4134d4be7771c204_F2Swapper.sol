/**
 *Submitted for verification at Arbiscan on 2022-08-02
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org
pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// File @uniswap/v2-periphery/contracts/interfaces/[email protected]
interface IUniswapV2Router01 {
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
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/interfaces/IFujiAdmin.sol





interface IFujiAdmin {
  // FujiAdmin Events

  /**
   * @dev Log change of flasher address
   */
  event FlasherChanged(address newFlasher);
  /**
   * @dev Log change of fliquidator address
   */
  event FliquidatorChanged(address newFliquidator);
  /**
   * @dev Log change of treasury address
   */
  event TreasuryChanged(address newTreasury);
  /**
   * @dev Log change of controller address
   */
  event ControllerChanged(address newController);
  /**
   * @dev Log change of vault harvester address
   */
  event VaultHarvesterChanged(address newHarvester);
  /**
   * @dev Log change of swapper address
   */
  event SwapperChanged(address newSwapper);
  /**
   * @dev Log change of vault address permission
   */
  event VaultPermitChanged(address vaultAddress, bool newPermit);

  function validVault(address _vaultAddr) external view returns (bool);

  function getFlasher() external view returns (address);

  function getFliquidator() external view returns (address);

  function getController() external view returns (address);

  function getTreasury() external view returns (address payable);

  function getVaultHarvester() external view returns (address);

  function getSwapper() external view returns (address);
}


// File contracts/interfaces/ISwapper.sol
interface ISwapper {
  struct Transaction {
    address to;
    bytes data;
    uint256 value;
  }

  function getSwapTransaction(
    address assetFrom,
    address assetTo,
    uint256 amount
  ) external returns (Transaction memory transaction);
}


// File contracts/F2Swapper.sol
/**
 * @dev Contract to support Harvesting function in {FujiVault}
 */

contract F2Swapper is ISwapper {
  address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public immutable wNative;
  address public immutable router;

  /**
  * @dev Sets the wNative and router addresses
  */
  constructor(address _wNative, address _router) {
    wNative = _wNative;
    router = _router;
  }

  /**
   * @dev Returns data structure to perform a swap transaction.
   * Function is called by FujiVault to harvest farmed tokens at baselayer protocols
   * @param assetFrom: asset type to be swapped.
   * @param assetTo: desired asset after swap transaction.
   * @param amount: amount of assetFrom to be swapped.
   * Requirements:
   * - Should return transaction data to swap all farmed token to vault's collateral type.
   */
  function getSwapTransaction(
    address assetFrom,
    address assetTo,
    uint256 amount
  ) external view override returns (Transaction memory transaction) {
    require(assetFrom != assetTo, "invalid request");

    if (assetFrom == NATIVE && assetTo == wNative) {
      transaction.to = wNative;
      transaction.value = amount;
      transaction.data = abi.encodeWithSelector(IWETH.deposit.selector);
    } else if (assetFrom == wNative && assetTo == NATIVE) {
      transaction.to = wNative;
      transaction.data = abi.encodeWithSelector(IWETH.withdraw.selector, amount);
    } else if (assetFrom == NATIVE) {
      transaction.to = router;
      address[] memory path = new address[](2);
      path[0] = wNative;
      path[1] = assetTo;
      transaction.value = amount;
      transaction.data = abi.encodeWithSelector(
        IUniswapV2Router01.swapExactETHForTokens.selector,
        0,
        path,
        msg.sender,
        type(uint256).max
      );
    } else if (assetTo == NATIVE) {
      transaction.to = router;
      address[] memory path = new address[](2);
      path[0] = assetFrom;
      path[1] = wNative;
      transaction.data = abi.encodeWithSelector(
        IUniswapV2Router01.swapExactTokensForETH.selector,
        amount,
        0,
        path,
        msg.sender,
        type(uint256).max
      );
    } else if (assetFrom == wNative || assetTo == wNative) {
      transaction.to = router;
      address[] memory path = new address[](2);
      path[0] = assetFrom;
      path[1] = assetTo;
      transaction.data = abi.encodeWithSelector(
        IUniswapV2Router01.swapExactTokensForTokens.selector,
        amount,
        0,
        path,
        msg.sender,
        type(uint256).max
      );
    } else {
      transaction.to = router;
      address[] memory path = new address[](3);
      path[0] = assetFrom;
      path[1] = wNative;
      path[2] = assetTo;
      transaction.data = abi.encodeWithSelector(
        IUniswapV2Router01.swapExactTokensForTokens.selector,
        amount,
        0,
        path,
        msg.sender,
        type(uint256).max
      );
    }
  }
}