// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICryptoFactory {
    function get_coins(address _pool) external view returns (address[2] memory);

    function get_coin_indices(address _pool, address _from, address _to) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICryptoRegistry {
    function get_coin_indices(address _pool, address _from, address _to) external view returns (uint256, uint256);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_n_coins(address _pool) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRegistry {
    function get_coin_indices(address _pool, address _from, address _to) external view returns (int128, int128, bool);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_n_coins(address _pool) external view returns (uint256[2] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INativeRouter {
    struct WidgetFee {
        address signer;
        address feeRecipient;
        uint256 feeRate;
    }

    struct ExactInputParams {
        bytes orders;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        WidgetFee widgetFee;
        bytes widgetFeeSignature;
        bytes[] fallbackSwapDataArray;
    }

    function exactInputSingle(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Interaction {
    bytes32 interactionTypeAndAddress;
    uint256 inputToken;
    uint256 outputToken;
    uint256 specifiedAmount;
    bytes32 metadata;
}

interface IOcean {
    function doInteraction(
        Interaction calldata interaction
    ) external returns (uint256 burnId, uint256 burnAmount, uint256 mintId, uint256 mintAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISolidlyV3Factory {
    function getPool(address tokenA, address tokenB, int24 tickSpacing) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISolidlyV3Pool {
    function token0() external view returns (address);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "../interfaces/IWETH.sol";

error AssetNotReceived();

library LibAsset {
    using LibAsset for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalance(address self) internal view returns (uint256) {
        return self.isNative() ? address(this).balance : IERC20(self).balanceOf(address(this));
    }

    function transferFrom(address self, address from, address to, uint256 amount) internal {
        SafeERC20.safeTransferFrom(IERC20(self), from, to, amount);
    }

    function transfer(address self, address recipient, uint256 amount) internal {
        if (self.isNative()) {
            Address.sendValue(payable(recipient), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(self), recipient, amount);
        }
    }

    function approve(address self, address spender, uint256 amount) internal {
        SafeERC20.forceApprove(IERC20(self), spender, amount);
    }

    function deposit(address self, address weth, uint256 amount) internal {
        if (self.isNative()) {
            if (msg.value < amount) {
                revert AssetNotReceived();
            }
            IWETH(weth).deposit{value: amount}();
        } else {
            self.transferFrom(msg.sender, address(this), amount);
        }
    }

    function withdraw(address self, address weth, address to, uint256 amount) internal {
        if (self.isNative()) {
            IWETH(weth).withdraw(amount);
        }
        self.transfer(payable(to), amount);
    }

    function getDecimals(address self) internal view returns (uint8 tokenDecimals) {
        tokenDecimals = 18;

        if (!self.isNative()) {
            (, bytes memory queriedDecimals) = self.staticcall(abi.encodeWithSignature("decimals()"));
            tokenDecimals = abi.decode(queriedDecimals, (uint8));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error AddressOutOfBounds();

library LibBytes {
    using LibBytes for bytes;

    function toAddress(bytes memory self, uint256 start) internal pure returns (address) {
        if (self.length < start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := mload(add(add(self, 20), start))
        }

        return tempAddress;
    }

    function slice(
        bytes memory self,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        require(length + 31 >= length, "slice_overflow");
        require(self.length >= start + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, length)

                for {
                    let cc := add(add(add(self, lengthmod), mul(0x20, iszero(lengthmod))), start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function concat(bytes memory self, bytes memory postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(self)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(self, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(add(add(end, iszero(add(length, mload(self)))), 31), not(31)))
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct CurveSettings {
    address mainRegistry;
    address cryptoRegistry;
    address cryptoFactory;
}

struct Amm {
    uint8 protocolId;
    bytes4 selector;
    address addr;
}

struct AppStorage {
    address weth;
    address magpieAggregatorAddress;
    mapping(uint16 => Amm) amms;
    CurveSettings curveSettings;
}

library LibMagpieRouter {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AppStorage, LibMagpieRouter} from "../libraries/LibMagpieRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {ICryptoFactory} from "../interfaces/curve/ICryptoFactory.sol";
import {ICryptoRegistry} from "../interfaces/curve/ICryptoRegistry.sol";
import {IRegistry} from "../interfaces/curve/IRegistry.sol";
import {Hop} from "./LibHop.sol";

error InvalidProtocol();
error InvalidAddLiquidityCall();
error InvalidRemoveLiquidityCall();
error InvalidTokenIndex();

library LibCurveLp {
    using LibAsset for address;

    function getTokenIndex2(address tokenAddress, address[2] memory tokenAddresses) internal pure returns (uint256) {
        uint256 l = tokenAddresses.length;
        for (uint256 i = 0; i < l; ) {
            if (tokenAddresses[i] == tokenAddress) {
                return i;
            }

            unchecked {
                i++;
            }
        }

        revert InvalidTokenIndex();
    }

    function getTokenIndex8(address tokenAddress, address[8] memory tokenAddresses) internal pure returns (uint256) {
        uint256 l = tokenAddresses.length;
        for (uint256 i = 0; i < l; ) {
            if (tokenAddresses[i] == tokenAddress) {
                return i;
            }

            unchecked {
                i++;
            }
        }

        revert InvalidTokenIndex();
    }

    function addLiquidity(uint256 tokenCount, uint256 tokenIndex, address poolAddress, uint256 amountIn) internal {
        bytes memory signature;

        if (tokenCount == 2) {
            uint256[2] memory amountIns = [uint256(0), uint256(0)];
            amountIns[tokenIndex] = amountIn;
            signature = abi.encodeWithSignature("add_liquidity(uint256[2],uint256)", amountIns, 0);
        } else if (tokenCount == 3) {
            uint256[3] memory amountIns = [uint256(0), uint256(0), uint256(0)];
            amountIns[tokenIndex] = amountIn;
            signature = abi.encodeWithSignature("add_liquidity(uint256[3],uint256)", amountIns, 0);
        } else if (tokenCount == 4) {
            uint256[4] memory amountIns = [uint256(0), uint256(0), uint256(0), uint256(0)];
            amountIns[tokenIndex] = amountIn;
            signature = abi.encodeWithSignature("add_liquidity(uint256[4],uint256)", amountIns, 0);
        } else if (tokenCount == 5) {
            uint256[5] memory amountIns = [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
            amountIns[tokenIndex] = amountIn;
            signature = abi.encodeWithSignature("add_liquidity(uint256[5],uint256)", amountIns, 0);
        } else if (tokenCount == 6) {
            uint256[6] memory amountIns = [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
            amountIns[tokenIndex] = amountIn;
            signature = abi.encodeWithSignature("add_liquidity(uint256[6],uint256)", amountIns, 0);
        } else if (tokenCount == 7) {
            uint256[7] memory amountIns = [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ];
            amountIns[tokenIndex] = amountIn;
            signature = abi.encodeWithSignature("add_liquidity(uint256[7],uint256)", amountIns, 0);
        } else if (tokenCount == 8) {
            uint256[8] memory amountIns = [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ];
            amountIns[tokenIndex] = amountIn;
            signature = abi.encodeWithSignature("add_liquidity(uint256[8],uint256)", amountIns, 0);
        }

        (bool success, ) = poolAddress.call(signature);
        if (!success) {
            revert InvalidAddLiquidityCall();
        }
    }

    function removeLiquidityMain(uint256 tokenIndex, address poolAddress, uint256 amountIn) internal {
        (bool success, ) = poolAddress.call(
            abi.encodeWithSignature(
                "remove_liquidity_one_coin(uint256,int128,uint256)",
                amountIn,
                int128(int256(tokenIndex)),
                0
            )
        );
        if (!success) {
            revert InvalidRemoveLiquidityCall();
        }
    }

    function removeLiquidityCrypto(uint256 tokenIndex, address poolAddress, uint256 amountIn) internal {
        (bool success, ) = poolAddress.call(
            abi.encodeWithSignature("remove_liquidity_one_coin(uint256,uint256,uint256)", amountIn, tokenIndex, 0)
        );
        if (!success) {
            revert InvalidRemoveLiquidityCall();
        }
    }

    function swapCrypto(
        address poolAddress,
        uint256 amountIn,
        address tokenAddress,
        bool isDeposit
    ) internal returns (bool) {
        AppStorage storage s = LibMagpieRouter.getStorage();

        uint256 tokenCount = ICryptoRegistry(s.curveSettings.cryptoRegistry).get_n_coins(poolAddress);

        if (s.curveSettings.cryptoRegistry != address(0) && tokenCount > 1) {
            uint256 tokenIndex = getTokenIndex8(
                tokenAddress,
                ICryptoRegistry(s.curveSettings.cryptoRegistry).get_coins(poolAddress)
            );
            if (isDeposit) {
                addLiquidity(tokenCount, tokenIndex, poolAddress, amountIn);
            } else {
                removeLiquidityCrypto(tokenIndex, poolAddress, amountIn);
            }

            return true;
        }

        return false;
    }

    function swapFactory(
        address poolAddress,
        uint256 amountIn,
        address tokenAddress,
        bool isDeposit
    ) internal returns (bool) {
        AppStorage storage s = LibMagpieRouter.getStorage();

        uint256 tokenCount = 2;

        if (s.curveSettings.cryptoFactory != address(0)) {
            uint256 tokenIndex = getTokenIndex2(
                tokenAddress,
                ICryptoFactory(s.curveSettings.cryptoFactory).get_coins(poolAddress)
            );

            if (isDeposit) {
                addLiquidity(tokenCount, tokenIndex, poolAddress, amountIn);
            } else {
                removeLiquidityCrypto(tokenIndex, poolAddress, amountIn);
            }

            return true;
        }

        return false;
    }

    function swapMain(
        address poolAddress,
        uint256 amountIn,
        address tokenAddress,
        bool isDeposit
    ) internal returns (bool) {
        AppStorage storage s = LibMagpieRouter.getStorage();

        uint256 tokenCount = IRegistry(s.curveSettings.mainRegistry).get_n_coins(poolAddress)[0];

        if (tokenCount > 1) {
            uint256 tokenIndex = getTokenIndex8(
                tokenAddress,
                IRegistry(s.curveSettings.mainRegistry).get_coins(poolAddress)
            );

            if (isDeposit) {
                addLiquidity(tokenCount, tokenIndex, poolAddress, amountIn);
            } else {
                removeLiquidityMain(tokenIndex, poolAddress, amountIn);
            }

            return true;
        }

        return false;
    }

    function swapCurveLp(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            bytes memory poolData = h.poolDataList[i];
            uint8 operation;
            address poolAddress;
            assembly {
                operation := shr(248, mload(add(poolData, 32)))
                poolAddress := shr(96, mload(add(poolData, 33)))
            }
            uint256 amountIn = i == 0 ? h.amountIn : amountOut;
            address fromAddress = h.path[i];
            address toAddress = h.path[i + 1];
            bool isDeposit = operation == 1;
            address tokenAddress = isDeposit ? fromAddress : toAddress;

            if (isDeposit) {
                fromAddress.approve(poolAddress, amountIn);
            }

            if (!swapCrypto(poolAddress, amountIn, tokenAddress, isDeposit)) {
                if (!swapMain(poolAddress, amountIn, tokenAddress, isDeposit)) {
                    if (!swapFactory(poolAddress, amountIn, tokenAddress, isDeposit)) {
                        revert InvalidProtocol();
                    }
                }
            }

            amountOut = toAddress.getBalance();

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AppStorage, LibMagpieRouter} from "../libraries/LibMagpieRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";

struct Hop {
    address addr;
    uint256 amountIn;
    address recipient;
    bytes[] poolDataList;
    address[] path;
}

struct HopParams {
    uint16 ammId;
    uint256 amountIn;
    bytes[] poolDataList;
    address[] path;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {INativeRouter} from "../interfaces/native/INativeRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {Hop} from "./LibHop.sol";

error NativeInvalidAssetAddress();

library LibNative {
    using LibAsset for address;
    using LibBytes for bytes;

    function swapNative(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            bytes memory poolData = h.poolDataList[i];
            INativeRouter.ExactInputParams memory params;
            INativeRouter.WidgetFee memory widgetFee;

            address fromAssetAddress;
            address toAssetAddress;

            params.orders = poolData.slice(0, 329);
            assembly {
                fromAssetAddress := shr(96, mload(add(poolData, 144)))
                toAssetAddress := shr(96, mload(add(poolData, 124)))
                mstore(widgetFee, shr(96, mload(add(poolData, 361))))
                mstore(add(widgetFee, 32), shr(96, mload(add(poolData, 381))))
                mstore(add(widgetFee, 64), mload(add(poolData, 401)))
            }

            if (fromAssetAddress != h.path[i] || toAssetAddress != h.path[i + 1]) {
                revert NativeInvalidAssetAddress();
            }

            params.recipient = address(this);
            params.amountIn = i == 0 ? h.amountIn : amountOut;
            params.amountOutMinimum = 0;
            params.widgetFee = widgetFee;
            params.widgetFeeSignature = poolData.slice(401, 65);

            h.path[i].approve(h.addr, params.amountIn);

            amountOut = INativeRouter(h.addr).exactInputSingle(params);

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Interaction, IOcean} from "../interfaces/shell/IOcean.sol";
import {Hop} from "./LibHop.sol";
import {LibAsset} from "../libraries/LibAsset.sol";

enum Operation {
    Deposit,
    Withdraw,
    Wrap,
    Unwrap
}

library LibShell {
    using LibAsset for address;

    function swapShell(Hop memory h) internal returns (uint256 amountOut) {
        uint256 pl = h.path.length;

        for (uint256 i = 0; i < pl - 1; i++) {
            bytes memory poolData = h.poolDataList[i];
            uint256 amountIn = i == 0 ? h.amountIn : amountOut;

            uint8 operation;
            address poolAddress;
            uint256 tokenXId;
            uint256 tokenYId;

            assembly {
                tokenXId := mload(add(poolData, 32))
                tokenYId := mload(add(poolData, 64))
                poolAddress := shr(96, mload(add(poolData, 96)))
                operation := shr(248, mload(add(poolData, 116)))
            }

            if (tokenXId == 0) {
                h.path[i].approve(h.addr, amountIn);
            }

            uint256 inputToken = tokenXId == 0 ? uint256(uint160(h.path[i])) : tokenXId;
            uint256 outputToken = tokenYId == 0 ? uint256(uint160(h.path[i + 1])) : tokenYId;

            bytes32 interactionTypeAndAddress;
            if (operation == uint8(Operation.Deposit)) {
                interactionTypeAndAddress = bytes32(abi.encodePacked(hex"060000000000000000000000", poolAddress));
            } else if (operation == uint8(Operation.Withdraw)) {
                interactionTypeAndAddress = bytes32(abi.encodePacked(hex"070000000000000000000000", poolAddress));
            } else if (operation == uint8(Operation.Wrap)) {
                interactionTypeAndAddress = bytes32(abi.encodePacked(hex"000000000000000000000000", h.path[i]));
                inputToken = 0;
                outputToken = 0;
            } else if (operation == uint8(Operation.Unwrap)) {
                interactionTypeAndAddress = bytes32(abi.encodePacked(hex"010000000000000000000000", h.path[i + 1]));
                inputToken = 0;
                outputToken = 0;
            }

            Interaction memory interaction = Interaction({
                interactionTypeAndAddress: interactionTypeAndAddress,
                inputToken: inputToken,
                outputToken: outputToken,
                specifiedAmount: amountIn,
                metadata: bytes32(0)
            });

            (, , , amountOut) = IOcean(h.addr).doInteraction(interaction);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISolidlyV3Pool} from "../interfaces/solidly/ISolidlyV3Pool.sol";
import {ISolidlyV3Factory} from "../interfaces/solidly/ISolidlyV3Factory.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibSolidlyV3 {
    using LibAsset for address;

    function swapSolidlyV3(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            bytes memory poolData = h.poolDataList[i];
            uint256 amountIn = i == 0 ? h.amountIn : amountOut;
            int24 tickSpacing;
            assembly {
                tickSpacing := shr(232, mload(add(poolData, 32)))
            }

            address poolAddress = ISolidlyV3Factory(h.addr).getPool(h.path[i], h.path[i + 1], tickSpacing);

            address token0Address = ISolidlyV3Pool(poolAddress).token0();
            bool zeroForOne = h.path[i] == token0Address;

            (int256 amount0, int256 amount1) = ISolidlyV3Pool(poolAddress).swap(
                address(this),
                zeroForOne,
                int256(amountIn),
                0
            );

            amountOut = zeroForOne ? uint256(-amount1) : uint256(-amount0);

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AppStorage} from "../../libraries/LibMagpieRouter.sol";
import {IRouter2} from "../interfaces/IRouter2.sol";
import {Hop} from "../LibHop.sol";
import {LibCurveLp} from "../LibCurveLp.sol";
import {LibShell} from "../LibShell.sol";
import {LibNative} from "../LibNative.sol";
import {LibSolidlyV3} from "../LibSolidlyV3.sol";

contract Router2Facet is IRouter2 {
    AppStorage internal s;

    function swapCurveLp(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibCurveLp.swapCurveLp(h);
    }

    function swapShell(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibShell.swapShell(h);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function swapNative(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibNative.swapNative(h);
    }

    function swapSolidlyV3(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibSolidlyV3.swapSolidlyV3(h);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Hop} from "../LibHop.sol";

interface IRouter2 {
    function swapCurveLp(Hop calldata h) external payable returns (uint256 amountOut);

    function swapShell(Hop calldata h) external payable returns (uint256 amountOut);

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function swapNative(Hop calldata h) external payable returns (uint256 amountOut);

    function swapSolidlyV3(Hop calldata h) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}