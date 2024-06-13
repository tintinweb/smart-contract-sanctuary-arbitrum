pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: FRAKTAL-PROTOCOl
pragma solidity 0.8.24;

import {IWETH} from '../shared/interfaces/IWETH.sol';
import {LibDiamond} from "../shared/libraries/LibDiamond.sol";


struct AppStore {
  string VERSION;
  IWETH WETH;
}

library LibAppStore {
  function store () internal pure returns(AppStore storage appStore) {
    assembly {
      appStore.slot := 0
    }
  }

  function setWETH (IWETH weth) internal {
    store().WETH = weth;
  }
  function getVERSION () internal view returns(string memory version) {
    version = store().VERSION;
  }
  function storageId () internal pure returns (bytes32 id) {
    return keccak256(abi.encode(LibDiamond.id()));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
pragma abicoder v2;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {AppStore} from "../../AppStore.sol";
import {
    SwapParams,
    ExchangeInfo,
    IExchangeHelper,
    ExchangeContractType,
    ExchangeContract,
    ExchangeType,
    PoolInfo
} from "../../interfaces/IExchangeHelper.sol";
import {LibExchangeHelper} from "./LibExchangeHelper.sol";
import {LibExchangeContractHelper} from "./LibExchangeContractHelper.sol";
import {LibExchangePoolHelper} from "./LibExchangePoolHelper.sol";
import { LibSwapHelper } from "./LibSwapHelper.sol";

contract ExchangeHelper is IExchangeHelper {
    AppStore internal s;

    function totalExcahnges() external view returns (uint48 count) {
        count = LibExchangeHelper.totalExcahnges();
    }

    function hasExchange(
        string memory exchange
    ) external view returns (bool hasEx) {
        hasEx = LibExchangeHelper.hasExchange(exchange);
    }

    function addExchange(
        string memory name
    ) external {
        LibExchangeHelper.addExchange(name);
    }

    function getExchange(
        uint48 _id
    ) external view returns (ExchangeInfo memory info) {
        info = LibExchangeHelper.getExchange(_id);
    }

    function getExchangeId(
        string memory name
    ) external view returns (bytes32 id) {
        id = LibExchangeHelper.getExchangeId(name);
    }

    function swap(
        SwapParams memory params
    ) external returns (uint amount_) {
        amount_ = LibSwapHelper.swap(params);
    }

    function hasPool(address poolAddress) external view returns (bool _has) {
        _has = LibExchangePoolHelper.hasPool(poolAddress);
    }

    function addPool(uint48 exchangeContractId, address poolAddress) external {
        LibExchangePoolHelper.addPool(exchangeContractId, poolAddress);
    }

    function getPool(uint48 _id) external view returns (PoolInfo memory info) {
        info = LibExchangePoolHelper.getPool(_id);
    }

    function totalPools () external view returns(uint48 total) {
        total = LibExchangePoolHelper.totalPools();
    }

    function hasExchangeContract(
        address _contract
    ) external view override returns (bool _hasContract) {
        _hasContract = LibExchangeContractHelper.hasExchangeContract(_contract);
    }

    function addExchangeContract(
        uint48 exchangeId,
        address contractAddress,
        ExchangeContractType contractType,
        string memory name
    ) external  {
        LibExchangeContractHelper.addExchangeContract(exchangeId, contractAddress, contractType, name);
    }

    function getExchangeContract(
        uint48 _id
    ) external view override returns (ExchangeContract memory info) {
       info =  LibExchangeContractHelper.getExchangeContract(_id);
    }

    function getExchangeContractId(
        address _contract
    ) external view override returns (uint48 id) {
        id = LibExchangeContractHelper.getExchangeContractId(_contract);
    }

    function totalExchangeContracts () external view returns(uint48 total) {
        total = LibExchangeContractHelper.totalExchangeContracts();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
pragma abicoder v2;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {AppStore} from "../../AppStore.sol";

import {
    ExchangeType,
    ExchangeInfo,
    SwapParams,
    ExchangeContractType,
    ExchangeContract,
    PoolInfo
} from "../../interfaces/IExchangeHelper.sol";

struct ExchangeContractsHelperStorage {
    mapping(address => bool) insertedContracts;
    uint48 contractsCount;
    mapping(uint48 => address) contracts;
    mapping(address => ExchangeContract) contractsInfo;
}

library LibExchangeContractHelper {
    bytes32 constant EXCHANGE_CONTRACT_STORAGE_POSITION = keccak256("fraktal-protocol.exchange-contracts-helper.storage");

    function diamondStorage () internal pure returns(ExchangeContractsHelperStorage storage ds) {
        bytes32 position = EXCHANGE_CONTRACT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function hasExchangeContract (address _contract) internal view returns(bool _hasContract) {
        return diamondStorage().insertedContracts[_contract];
    }
    function addExchangeContract (uint48 exchangeId, address contractAddress, ExchangeContractType contractType, string memory name) internal {
        ExchangeContractsHelperStorage storage ds = diamondStorage();
        require(!hasExchangeContract(contractAddress), "EC_0");
        ds.contracts[ds.contractsCount] = contractAddress;
        ds.insertedContracts[contractAddress] = true;
        ds.contractsInfo[contractAddress] = ExchangeContract({
            name: name,
            exchangeId: exchangeId,
            contractAddress: contractAddress,
            contractId: ds.contractsCount,
            contractType: contractType
        });
        ds.contractsCount++;
    }
    function getExchangeContract (uint48 _id) internal view returns(ExchangeContract memory info) {
        address contractAddress = diamondStorage().contracts[_id];
        info = diamondStorage().contractsInfo[contractAddress];

    }
    function getExchangeContractId (address _contract) internal view returns(uint48 id) {
        id = diamondStorage().contractsInfo[_contract].contractId;
    }
    function totalExchangeContracts () internal view returns (uint48 total) {
        total = diamondStorage().contractsCount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
pragma abicoder v2;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {AppStore} from "../../AppStore.sol";
import {
    ExchangeType,
    ExchangeInfo,
    SwapParams,
    ExchangeContractType,
    ExchangeContract,
    PoolInfo
} from "../../interfaces/IExchangeHelper.sol";

struct ExchangeHelperStorage {
    mapping(string => bool) includedExchange;
    mapping(uint48 => string) exchanges;
    uint48 exchangesCount;
    mapping(string => ExchangeInfo) exchangesInfo;
}

library LibExchangeHelper {
    bytes32 constant EXCHANGE_STORAGE_POSITION = keccak256("fraktal-protocol.exchange-helper.storage");

    function diamondStorage () internal pure returns(ExchangeHelperStorage storage ds) {
        bytes32 position = EXCHANGE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function totalExcahnges () internal view returns (uint48 count) {
        count = diamondStorage().exchangesCount;
    }

    function hasExchange (string memory exchange) internal view returns(bool hasEx) {
        hasEx = diamondStorage().includedExchange[exchange];
    }

    function addExchange (string memory name) internal {
        ExchangeHelperStorage storage ds = diamondStorage();

        require(!hasExchange(name), 'EX_ADD_HAS');
        ds.includedExchange[name] = true;
        ds.exchanges[ds.exchangesCount] = name;
        ds.exchangesInfo[name] = ExchangeInfo({name: name, exchangeId: keccak256(abi.encode(ds.exchangesCount))});
        ds.exchangesCount++;
    }

    function getExchange (uint48 _id) internal view returns (ExchangeInfo memory info) {
        ExchangeHelperStorage storage ds = diamondStorage();
        string memory exchange = diamondStorage().exchanges[_id];
        info = ds.exchangesInfo[exchange];
    }

    function getExchangeId (string memory name)  internal view returns(bytes32 id) {
        ExchangeHelperStorage storage ds = diamondStorage();
        id = ds.exchangesInfo[name].exchangeId;
    }

    function getAllExchanges () internal view returns (ExchangeInfo[] memory info) {
        ExchangeHelperStorage storage ds = diamondStorage();
        uint48 i;
        uint48 len = ds.exchangesCount;

        info = new ExchangeInfo[](len);

        for (i; i < len; i++) {
            string memory exchange = diamondStorage().exchanges[i];
            info[i] = ds.exchangesInfo[exchange];
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
pragma abicoder v2;

import {PoolInfo} from "../../interfaces/IExchangeHelper.sol";

struct ExchangePoolHelperStorage {
    mapping(address => bool) insertedPools;
    mapping(uint48 => address) pools;
    uint48 poolsCount;
    mapping(address => PoolInfo) poolsInfo;
}

library LibExchangePoolHelper {
    bytes32 constant EXCHANGE_POOL_STORAGE_POSITION = keccak256("fraktal-protocol.exchange-pool-helper.storage");

    function diamondStorage () internal pure returns(ExchangePoolHelperStorage storage ds) {
        bytes32 position = EXCHANGE_POOL_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function hasPool (address poolAddress) internal view returns (bool _has) {
        _has = diamondStorage().insertedPools[poolAddress];
    }
    function addPool (uint48 exchangeContractId, address poolAddress) internal {
        ExchangePoolHelperStorage storage ds = diamondStorage();
        
        require(!hasPool(poolAddress), 'EX_PL_ADD');
        uint48 poolId = ds.poolsCount;
        ds.insertedPools[poolAddress] = true;
        ds.pools[poolId] = poolAddress;
        ds.poolsInfo[poolAddress] = PoolInfo({poolId: poolId, exchangeContractId: exchangeContractId });
        ds.poolsCount++;

    }
    function getPool (uint48 _id) internal view returns(PoolInfo memory info) {
        ExchangePoolHelperStorage storage ds = diamondStorage();

        if (_id >= ds.poolsCount) return info;

        address poolAddress = ds.pools[_id];
        info = ds.poolsInfo[poolAddress];

    }
    function totalPools () internal view returns (uint48 total) {
        total = diamondStorage().poolsCount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
pragma abicoder v2;

import {SwapParams, ExchangeType} from "../../interfaces/IExchangeHelper.sol";
import {IWETH} from "../../../shared/interfaces/IWETH.sol";
import {LibUniswapV2, UniswapV2SwapParams} from "./vendor/Uniswap/UniswapV2.sol";
import {LibUniswapV3, UniswapV3SwapParams} from "./vendor/Uniswap/UniswapV3.sol";

library LibSwapHelper {
    function swap (SwapParams memory swapParams) internal returns (uint _amount) {
        if (swapParams.exchangeType == ExchangeType.UNISWAP_V2) {
            (uint8 isExactIn, address router) = abi.decode(swapParams.swapData, (uint8, address));
            UniswapV2SwapParams memory params = UniswapV2SwapParams(
                isExactIn,
                router,
                swapParams.tokenIn,
                swapParams.tokenOut,
                swapParams.recipient,
                swapParams.amountIn,
                swapParams.amountOut
            );
            _amount = LibUniswapV2.swap(params);
        } else if (swapParams.exchangeType == ExchangeType.UNISWAP_V3) {
            (uint8 isExactIn, address router, uint160 sqrtPriceX96, uint24 fee) = abi.decode(swapParams.swapData, (uint8, address, uint160, uint24));

            UniswapV3SwapParams memory params = UniswapV3SwapParams(
                isExactIn,
                router,
                swapParams.tokenIn,
                swapParams.tokenOut,
                swapParams.recipient,
                fee,
                sqrtPriceX96,
                swapParams.amountIn,
                swapParams.amountOut
            );
            _amount = LibUniswapV3.swap(params);
        }
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
pragma abicoder v2;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

struct UniswapV2SwapParams {
    uint8 isExactIn;
    address router;
    address tokenIn;
    address tokenOut;
    address recipient;
    uint amountIn;
    uint amountOut;
}


library LibUniswapV2 {
    function swap (
        UniswapV2SwapParams memory params
    ) internal returns (uint _amount) {

        address[] memory path = new address[](2);
        path[0] = params.tokenIn;
        path[1] = params.tokenOut;
        uint deadline = block.timestamp + 15;
        address to = params.recipient;

        if (params.isExactIn > 0) {
            uint[] memory amounts = IUniswapV2Router02(params.router).swapExactTokensForTokens(
                params.amountIn,
                params.amountOut,
                path,
                to,
                deadline
            );
            _amount = amounts[1];
        } else {
            uint[] memory amounts = IUniswapV2Router02(params.router).swapTokensForExactTokens(
                params.amountIn,
                params.amountOut,
                path,
                to,
                deadline
            );
            _amount = amounts[0];

        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
pragma abicoder v2;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

struct UniswapV3SwapParams {
    uint8 isExactIn;
    address router;
    address tokenIn;
    address tokenOut;
    address recipient;
    uint24 fee;
    uint160 sqrtPriceX96;
    uint amountIn;
    uint amountOut;

}
library LibUniswapV3 {
    function swap (UniswapV3SwapParams memory swapParams) internal returns(uint amount) {
        uint deadline = block.timestamp + 15;

        if (swapParams.isExactIn > 0) {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
                swapParams.tokenIn,
                swapParams.tokenOut,
                swapParams.fee,
                swapParams.recipient,
                deadline,
                swapParams.amountIn,
                swapParams.amountOut,
                swapParams.sqrtPriceX96
            );
            amount = ISwapRouter(swapParams.router).exactInputSingle(params);
        } else {
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
                swapParams.tokenIn,
                swapParams.tokenOut,
                swapParams.fee,
                swapParams.recipient,
                deadline,
                swapParams.amountOut,
                swapParams.amountIn,
                swapParams.sqrtPriceX96
            );
            amount = ISwapRouter(swapParams.router).exactOutputSingle{ value: msg.value }(params);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
pragma abicoder v2;

enum ExchangeType {
    UNISWAP_V2, UNISWAP_V3, ALGEBRA_V1
}
enum ExchangeContractType {
    UNISWAP_V2_FACTORY,
    UNISWAP_V2_ROUTER_02,
    UNISWAP_V3_FACTORY,
    UNISWAP_V3_SWAP_ROUTER,
    UNISWAP_V3_SWAP_ROUTER_02,
    UNISWAP_V3_UNIVERSAL_ROUTER,
    UNISWAP_V3_QUOTER,
    UNISWAP_V3_QUOTER_V2,
    UNISWAP_V3_MULTICALL,
    ALGEBRA_V1_FACTORY,
    ALGEBRA_V1_ROUTER
}

struct SwapParams {
    ExchangeType exchangeType;
    address recipient;
    address tokenIn;
    address tokenOut;
    uint amountIn;
    uint amountOut;
    bytes swapData;
}
struct ExchangeInfo {
    bytes32 exchangeId;
    string name;

}
struct ExchangeUris {
    uint exchangeId;
    mapping(uint => string) infoUris;
    uint infoUrisCount;
    mapping(string => bool) insertedUrls;
}

struct ExchangeContract {
    ExchangeContractType contractType;
    address contractAddress;
    uint48  contractId;
    uint48 exchangeId;
    string name;
}

struct PoolInfo {
    uint48 exchangeContractId;
    uint48 poolId;
}

struct PoolInfoResult {
    uint48 poolId;
    uint48 token0Id;
    uint48 token1Id;
    uint reserve0;
    uint reserve1;
    uint160 sqrtPriceX96;
}

interface IExchangeContractHelper {
    function hasExchangeContract (address _contract) external view returns(bool _hasContract);
    function addExchangeContract (uint48 exchangeId, address contractAddress, ExchangeContractType contractType, string memory name) external;
    function getExchangeContract (uint48 _id) external view returns(ExchangeContract memory info);
    function getExchangeContractId (address _contract) external view returns(uint48 id);
    function totalExchangeContracts () external view returns(uint48 total);

}

interface IExchangePoolHelper {
    function hasPool (address poolAddress) external view returns (bool _has);
    function addPool (uint48 exchangeContractId, address poolAddress) external;
    function getPool (uint48 _id) external view returns(PoolInfo memory info);
    function totalPools () external view returns(uint48 total);
}

interface IExchangeHelper is IExchangeContractHelper, IExchangePoolHelper {
    function hasExchange(
        string memory exchange
    ) external view returns(bool);
    function addExchange(
        string memory name
    ) external;
    function getExchange(
        uint48 _id
    ) external view returns (ExchangeInfo memory info);
    function totalExcahnges () external view returns (uint48 count);
    function getExchangeId(
        string memory name
    ) external view returns (bytes32 id);

}

interface ISwapHelper {
    function swap (SwapParams memory SwapParams) external returns (uint _amount);
}

interface ILiquidityHelper {
    function addLiquidity () external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity 0.8.24;

/******************************************************************************\
* Author: Kryptokajun <[email protected]> (https://twitter.com/kryptokajun1)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
    // OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

    pragma solidity ^0.8.0;

    interface IERC20Events {
        /**
         * @dev Emitted when `value` tokens are moved from one account (`from`) to
         * another (`to`).
         *
         * Note that `value` may be zero.
         */
        event Transfer(address indexed from, address indexed to, uint256 value);

        /**
         * @dev Emitted when the allowance of a `spender` for an `owner` is set by
         * a call to {approve}. `value` is the new allowance.
         */
        event Approval(address indexed owner, address indexed spender, uint256 value);

    }
    /**
     * @dev Interface of the ERC20 standard as defined in the EIP.
     */
    interface IERC20 {

        /**
         * @dev Returns the amount of tokens in existence.
         */
        function totalSupply() external view returns (uint256);

        /**
         * @dev Returns the amount of tokens owned by `account`.
         */
        function balanceOf(address account) external view returns (uint256);

        /**
         * @dev Moves `amount` tokens from the caller's account to `to`.
         *
         * Returns a boolean value indicating whether the operation succeeded.
         *
         * Emits a {Transfer} event.
         */
        function transfer(address to, uint256 amount) external returns (bool);

        /**
         * @dev Returns the remaining number of tokens that `spender` will be
         * allowed to spend on behalf of `owner` through {transferFrom}. This is
         * zero by default.
         *
         * This value changes when {approve} or {transferFrom} are called.
         */
        function allowance(address owner, address spender) external view returns (uint256);

        /**
         * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
         *
         * Returns a boolean value indicating whether the operation succeeded.
         *
         * IMPORTANT: Beware that changing an allowance with this method brings the risk
         * that someone may use both the old and the new allowance by unfortunate
         * transaction ordering. One possible solution to mitigate this race
         * condition is to first reduce the spender's allowance to 0 and set the
         * desired value afterwards:
         * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
         *
         * Emits an {Approval} event.
         */
        function approve(address spender, uint256 amount) external returns (bool);

        /**
         * @dev Moves `amount` tokens from `from` to `to` using the
         * allowance mechanism. `amount` is then deducted from the caller's
         * allowance.
         *
         * Returns a boolean value indicating whether the operation succeeded.
         *
         * Emits a {Transfer} event.
         */
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
    }

    interface IERC20BaseModifiers {
        // modifier onlyMinter() {}
        // modifier onlyBurner() {}
        function _isERC20BaseInitialized() external view returns (bool);
    }

    interface IERC20Meta is IERC20 {
        function name() external view returns (string memory);
        function symbol() external view returns (string memory);
        function decimals () external view returns (uint8);

    }

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from './IERC20.sol';

interface IWETH is IERC20 {
  function deposit() external payable;
  function transfer(address to, uint256 value) external returns (bool);
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: COPPER-PROTOCOL
pragma solidity 0.8.24;


/******************************************************************************\
* Author: Kryptokajun <[email protected]> (https://twitter.com/kryptokajun1)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// import "hardhat/console.sol";

// import "hardhat/console.sol";
// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard
struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
}

struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
}

struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
}
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("fraktal-protocol.fraktal-bot-diamond.standard.diamond.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        // console.log(msg.sender, diamondStorage().contractOwner);
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

            // console.log("OLD:", oldFacetAddress);
            // console.logBytes4(selector);
            // console.log("selectorIndex", selectorIndex);
            // console.log("NEW:", _facetAddress);
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    // console.logBytes(error);
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
    function id () internal pure returns (bytes32 _id) {
        _id = keccak256(abi.encode(DIAMOND_STORAGE_POSITION, DIAMOND_STORAGE_POSITION));
    }
}