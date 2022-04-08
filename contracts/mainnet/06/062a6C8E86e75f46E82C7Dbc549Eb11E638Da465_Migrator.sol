// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IPairFactory.sol";
import "../libraries/TransferHelper.sol";
import "../utils/Reentrant.sol";

contract Migrator is Reentrant {
    event Migrate(address indexed user, uint256 oldLiquidity, uint256 newLiquidity, uint256 baseAmount);

    IRouter public oldRouter;
    IRouter public newRouter;
    IPairFactory public oldFactory;
    IPairFactory public newFactory;

    constructor(IRouter oldRouter_, IRouter newRouter_) {
        oldRouter = oldRouter_;
        newRouter = newRouter_;
        oldFactory = IPairFactory(oldRouter.pairFactory());
        newFactory = IPairFactory(newRouter.pairFactory());
    }

    function migrate(address baseToken, address quoteToken) external nonReentrant {
        address oldAmm = oldFactory.getAmm(baseToken, quoteToken);
        uint256 oldLiquidity = IERC20(oldAmm).balanceOf(msg.sender);
        require(oldLiquidity > 0, "ZERO_LIQUIDITY");
        TransferHelper.safeTransferFrom(oldAmm, msg.sender, oldAmm, oldLiquidity);
        (uint256 baseAmount, , ) = IAmm(oldAmm).burn(address(this));
        require(baseAmount > 0, "ZERO_BASE_AMOUNT");

        address newAmm = newFactory.getAmm(baseToken, quoteToken);
        TransferHelper.safeTransfer(baseToken, newAmm, baseAmount);
        ( , , uint256 newLiquidity) = IAmm(newAmm).mint(msg.sender);
        emit Migrate(msg.sender, oldLiquidity, newLiquidity, baseAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Swap(address indexed trader, address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed trader, address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteReserveBefore, uint256 quoteReserveAfter, uint256 _baseReserve , uint256 quoteReserveFromInternal,  uint256 quoteReserveFromExternal );
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    // only factory can call this function
    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external;

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function burn(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    // only binding margin can call this function
    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external returns (uint256[2] memory amounts);

    // only binding margin can call this function
    function forceSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external;

    function rebase() external returns (uint256 quoteReserveAfter);

    function collectFee() external returns (bool feeOn);

    function factory() external view returns (address);

    function config() external view returns (address);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function margin() external view returns (address);

    function lastPrice() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function getFeeLiquidity() external view returns (uint256);

    function getTheMaxBurnLiquidity() external view returns (uint256 maxLiquidity);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRouter {
    function config() external view returns (address);
    
    function pairFactory() external view returns (address);

    function pcvTreasury() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address baseToken,
        address quoteToken,
        uint256 baseAmount,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    ) external returns (uint256 quoteAmount, uint256 liquidity);

    function addLiquidityETH(
        address quoteToken,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    )
        external
        payable
        returns (
            uint256 ethAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function removeLiquidity(
        address baseToken,
        address quoteToken,
        uint256 liquidity,
        uint256 baseAmountMin,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 quoteAmount);

    function removeLiquidityETH(
        address quoteToken,
        uint256 liquidity,
        uint256 ethAmountMin,
        uint256 deadline
    ) external returns (uint256 ethAmount, uint256 quoteAmount);

    function deposit(
        address baseToken,
        address quoteToken,
        address holder,
        uint256 amount
    ) external;

    function depositETH(address quoteToken, address holder) external payable;

    function withdraw(
        address baseToken,
        address quoteToken,
        uint256 amount
    ) external;

    function withdrawETH(address quoteToken, uint256 amount) external;

    function openPositionWithWallet(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 marginAmount,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external returns (uint256 baseAmount);

    function openPositionETHWithWallet(
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external payable returns (uint256 baseAmount);

    function openPositionWithMargin(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external returns (uint256 baseAmount);

    function closePosition(
        address baseToken,
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline,
        bool autoWithdraw
    ) external returns (uint256 baseAmount, uint256 withdrawAmount);

    function closePositionETH(
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 withdrawAmount);

    function liquidate(
        address baseToken,
        address quoteToken,
        address trader,
        address to
    ) external returns (uint256 quoteAmount, uint256 baseAmount, uint256 bonus);

    function getReserves(address baseToken, address quoteToken)
        external
        view
        returns (uint256 reserveBase, uint256 reserveQuote);

    function getQuoteAmount(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);

    function getWithdrawable(
        address baseToken,
        address quoteToken,
        address holder
    ) external view returns (uint256 amount);

    function getPosition(
        address baseToken,
        address quoteToken,
        address holder
    )
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPairFactory {
    event NewPair(address indexed baseToken, address indexed quoteToken, address amm, address margin);

    function createPair(address baseToken, address quotoToken) external returns (address amm, address margin);

    function ammFactory() external view returns (address);

    function marginFactory() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
            "TransferHelper::safeApprove: approve failed"
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
            "TransferHelper::safeTransfer: transfer failed"
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
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}