/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IPancakeRouter {

    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface ISweepHelperFeature {

    struct SwpHelpParam {
        address erc20Token;
        uint256 amountIn;
        uint24 fee;
    }

    struct SwpRateInfo {
        address token;
        uint256 tokenOutAmount;
    }

    struct SwpHelpInfo {
        address erc20Token;
        uint256 balance;
        uint256 allowance;
        uint8 decimals;
        SwpRateInfo[] rates;
    }

    function getSwpHelpInfos(
        address account,
        address operator,
        SwpHelpParam[] calldata params
    ) external returns (SwpHelpInfo[] memory infos);

    struct SwpHelpInfoEx {
        address erc20Token;
        uint256 balance;
        uint8 decimals;
        uint256[] allowances;
        SwpRateInfo[] rates;
    }

    function getSwpHelpInfosEx(
        address account,
        address[] calldata operators,
        SwpHelpParam[] calldata params
    ) external returns (SwpHelpInfoEx[] memory infos);

    struct SwpAssetInfo {
        address account;
        uint8 itemType;
        address token;
        uint256 tokenId;
    }

    function getAssetsBalance(SwpAssetInfo[] calldata assets) external view returns (uint256[] memory);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IUniswapQuoter {

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../libs/LibAssetHelper.sol";
import "./ISweepHelperFeature.sol";
import "./IPancakeRouter.sol";
import "./IUniswapQuoter.sol";


contract SweepHelperFeature is ISweepHelperFeature, LibAssetHelper {

    address public immutable WETH;
    IPancakeRouter public immutable PancakeRouter;
    IUniswapQuoter public immutable UniswapQuoter;

    constructor(address weth, IPancakeRouter pancakeRouter, IUniswapQuoter uniswapQuoter) {
        WETH = weth;
        PancakeRouter = pancakeRouter;
        UniswapQuoter = uniswapQuoter;
    }

    function getSwpHelpInfos(
        address account,
        address operator,
        SwpHelpParam[] calldata params
    ) external override returns (SwpHelpInfo[] memory infos) {
        address[] memory path = new address[](2);

        infos = new SwpHelpInfo[](params.length);
        for (uint256 i; i < params.length; i++) {
            address erc20Token = params[i].erc20Token;

            infos[i].erc20Token = erc20Token;
            infos[i].balance = _erc20BalanceOf(erc20Token, account);
            infos[i].allowance = _erc20Allowance(erc20Token, account, operator);
            infos[i].decimals = _erc20Decimals(erc20Token);
            uint256 amountIn = 10 ** infos[i].decimals;

            SwpRateInfo[] memory rates = new SwpRateInfo[](params.length);
            for (uint256 j; j < params.length; j++) {
                address token = params[j].erc20Token;
                rates[j].token = token;
                if (
                    token == erc20Token ||
                    token == address(0) && erc20Token == WETH ||
                    token == WETH && erc20Token == address(0)
                ) {
                    rates[j].tokenOutAmount = amountIn;
                    continue;
                }

                address tokenA = erc20Token == address(0) ? WETH : erc20Token;
                address tokenB = token == address(0) ? WETH : token;
                if (address(PancakeRouter) != address(0)) {
                    path[0] = tokenA;
                    path[1] = tokenB;
                    rates[j].tokenOutAmount = getAmountsOut(amountIn, path);
                } else if (address(UniswapQuoter) != address(0)) {
                    rates[j].tokenOutAmount = quoteExactInputSingle(tokenA, tokenB, params[i].fee, amountIn);
                }
            }
            infos[i].rates = rates;
        }
        return infos;
    }

    function getSwpHelpInfosEx(
        address account,
        address[] calldata operators,
        SwpHelpParam[] calldata params
    ) external override returns (SwpHelpInfoEx[] memory infos) {
        address[] memory path = new address[](2);
        infos = new SwpHelpInfoEx[](params.length);
        for (uint256 i; i < params.length; i++) {
            address erc20Token = params[i].erc20Token;

            infos[i].erc20Token = erc20Token;
            infos[i].balance = _erc20BalanceOf(erc20Token, account);

            uint256[] memory allowances = new uint256[](operators.length);
            for (uint256 j; j < operators.length; j++) {
                allowances[j] = _erc20Allowance(erc20Token, account, operators[j]);
            }

            infos[i].allowances = allowances;
            infos[i].decimals = _erc20Decimals(erc20Token);
            uint256 amountIn = 10 ** infos[i].decimals;

            SwpRateInfo[] memory rates = new SwpRateInfo[](params.length);
            for (uint256 j; j < params.length; j++) {
                address token = params[j].erc20Token;
                rates[j].token = token;
                if (
                    token == erc20Token ||
                    token == address(0) && erc20Token == WETH ||
                    token == WETH && erc20Token == address(0)
                ) {
                    rates[j].tokenOutAmount = amountIn;
                    continue;
                }

                address tokenA = erc20Token == address(0) ? WETH : erc20Token;
                address tokenB = token == address(0) ? WETH : token;
                if (address(PancakeRouter) != address(0)) {
                    path[0] = tokenA;
                    path[1] = tokenB;
                    rates[j].tokenOutAmount = getAmountsOut(amountIn, path);
                } else if (address(UniswapQuoter) != address(0)) {
                    rates[j].tokenOutAmount = quoteExactInputSingle(tokenA, tokenB, params[i].fee, amountIn);
                }
            }
            infos[i].rates = rates;
        }
        return infos;
    }

    function getAssetsBalance(SwpAssetInfo[] calldata assets) external view override returns (uint256[] memory) {
        uint256[] memory infos = new uint256[](assets.length);
        for (uint256 i; i < assets.length; i++) {
            address account = assets[i].account;
            address token = assets[i].token;
            uint256 tokenId = assets[i].tokenId;
            uint8 itemType = assets[i].itemType;

            if (itemType == 0) {
                infos[i] = (_erc721OwnerOf(token, tokenId) == account) ? 1 : 0;
                continue;
            }

            if (itemType == 1) {
                infos[i] = _erc1155BalanceOf(token, account, tokenId);
                continue;
            }

            if (itemType == 2) {
                infos[i] = _erc20BalanceOf(token, account);
            }
        }
        return infos;
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256 amount) {
        try PancakeRouter.getAmountsOut(amountIn, path) returns (uint256[] memory _amounts) {
            amount = _amounts[1];
        } catch {
        }
        return amount;
    }

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        try UniswapQuoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            0
        ) returns (uint256 _amountOut) {
            amountOut = _amountOut;
        } catch {
        }
        return amountOut;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


abstract contract LibAssetHelper {

    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant ERC404_APPROVAL = 1 << 126;

    function _isApprovedForAll(
        address token,
        bool isERC721,
        address owner,
        address operator
    ) internal view returns(uint256 approval) {
        (approval, ) = _isApprovedForAllV2(token, isERC721, owner, operator);
    }

    function _isApprovedForAllV2(
        address token,
        bool isERC721,
        address owner,
        address operator
    ) internal view returns(uint256 approval, bool isERC404) {
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return (0, false);
        }

        bool isApprovedForAll;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `isApprovedForAll(address,address)`
            mstore(ptr, 0xe985e9c500000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), owner)
            mstore(add(ptr, 0x24), operator)

            if staticcall(gas(), token, ptr, 0x44, ptr, 0x20) {
                if gt(mload(ptr), 0) {
                    isApprovedForAll := 1
                }
            }
        }
        if (isApprovedForAll) {
            return (1, false);
        }
//        if (isERC721) {
//            if (_erc20Decimals(token) == 0) {
//                return (0, false);
//            }
//            (uint256 allowance, bool success) = _erc20AllowanceV2(token, owner, operator);
//            approval = allowance > ERC404_APPROVAL ? 1 : 0;
//            isERC404 = success;
//            return (approval, isERC404);
//        } else {
//            return (0, false);
//        }
        return (0, false);
    }

    function _erc721OwnerOf(
        address token, uint256 tokenId
    ) internal view returns (address owner) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `ownerOf(uint256)`
            mstore(ptr, 0x6352211e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), tokenId)

            if staticcall(gas(), token, ptr, 0x24, ptr, 0x20) {
                if lt(mload(ptr), shl(160, 1)) {
                    owner := mload(ptr)
                }
            }
        }
        return owner;
    }

    function _erc721GetApproved(
        address token, uint256 tokenId
    ) internal view returns (address operator) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `getApproved(uint256)`
            mstore(ptr, 0x081812fc00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), tokenId)

            if staticcall(gas(), token, ptr, 0x24, ptr, 0x20) {
                if lt(mload(ptr), shl(160, 1)) {
                    operator := mload(ptr)
                }
            }
        }
        return operator;
    }

    function _erc1155BalanceOf(
        address token,
        address account,
        uint256 tokenId
    ) internal view returns (uint256 _balance) {
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `balanceOf(address,uint256)`
            mstore(ptr, 0x00fdd58e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), account)
            mstore(add(ptr, 0x24), tokenId)

            if staticcall(gas(), token, ptr, 0x44, ptr, 0x20) {
                _balance := mload(ptr)
            }
        }
        return _balance;
    }

    function _erc20BalanceOf(
        address token, address account
    ) internal view returns (uint256 _balance) {
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return account.balance;
        }
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `balanceOf(address)`
            mstore(ptr, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), account)

            if staticcall(gas(), token, ptr, 0x24, ptr, 0x20) {
                _balance := mload(ptr)
            }
        }
        return _balance;
    }

    function _erc20Allowance(
        address token,
        address owner,
        address spender
    ) internal view returns (uint256 allowance) {
        (allowance, ) = _erc20AllowanceV2(token, owner, spender);
    }

    function _erc20AllowanceV2(
        address token,
        address owner,
        address spender
    ) internal view returns (uint256 allowance, bool callSuccess) {
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return (type(uint256).max, false);
        }
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `allowance(address,address)`
            mstore(ptr, 0xdd62ed3e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), owner)
            mstore(add(ptr, 0x24), spender)

            if staticcall(gas(), token, ptr, 0x44, ptr, 0x20) {
                allowance := mload(ptr)
                callSuccess := 1
            }
        }
        return (allowance, callSuccess);
    }

    function _erc20Decimals(address token) internal view returns (uint8 decimals) {
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return 18;
        }
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for `decimals()`
            mstore(ptr, 0x313ce56700000000000000000000000000000000000000000000000000000000)

            if staticcall(gas(), token, ptr, 0x4, ptr, 0x20) {
                if lt(mload(ptr), 48) {
                    decimals := mload(ptr)
                }
            }
        }
        return decimals;
    }
}