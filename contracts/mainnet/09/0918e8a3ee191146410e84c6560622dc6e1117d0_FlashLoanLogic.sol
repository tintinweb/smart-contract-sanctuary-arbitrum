// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IYToken} from "../../../interfaces/IYToken.sol";
import {IFlashLoanReceiver} from "../../../flashloan/interfaces/IFlashLoanReceiver.sol";
import {IFlashLoanSimpleReceiver} from "../../../flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {IPoolAddressesProvider} from "../../../interfaces/IPoolAddressesProvider.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {BorrowLogic} from "./BorrowLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title FlashLoanLogic library
 *
 * @notice Implements the logic for the flash loans
 */
library FlashLoanLogic {
    using ReserveLogic for DataTypes.ReserveCache;
    using ReserveLogic for DataTypes.ReserveData;
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeCast for uint256;

    // Helper struct for internal variables used in the `executeFlashLoan` function
    struct FlashLoanLocalVars {
        IFlashLoanReceiver receiver;
        uint256 i;
        address currentAsset;
        uint256 currentAmount;
        uint256[] totalPremiums;
        uint256 flashloanPremiumTotal;
        uint256 flashloanPremiumToProtocol;
    }

    /**
     * @notice Implements the flashloan feature that allow users to access liquidity of the pool for one transaction
     * as long as the amount taken plus fee is returned or debt is opened.
     * @dev For authorized flashborrowers the fee is waived
     * @dev At the end of the transaction the pool will pull amount borrowed + fee from the receiver,
     * if the receiver have not approved the pool the transaction will revert.
     * @dev Emits the `FlashLoan()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the flashloan function
     */
    function executeFlashLoan(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.FlashloanParams memory params
    ) external {
        // The usual action flow (cache -> updateState -> validation -> changeState -> updateRates)
        // is altered to (validation -> user payload -> cache -> updateState -> changeState -> updateRates) for flashloans.
        // This is done to protect against reentrance and rate manipulation within the user specified payload.

        ValidationLogic.validateFlashloan(reservesData, params.assets, params.amounts);

        FlashLoanLocalVars memory vars;

        vars.totalPremiums = new uint256[](params.assets.length);

        vars.receiver = IFlashLoanReceiver(params.receiverAddress);
        (vars.flashloanPremiumTotal, vars.flashloanPremiumToProtocol) = params.isAuthorizedFlashBorrower
            ? (0, 0)
            : (params.flashLoanPremiumTotal, params.flashLoanPremiumToProtocol);

        for (vars.i = 0; vars.i < params.assets.length; vars.i++) {
            vars.currentAmount = params.amounts[vars.i];
            vars.totalPremiums[vars.i] =
                !params.createPosition[vars.i] ? vars.currentAmount.percentMul(vars.flashloanPremiumTotal) : 0;
            IYToken(reservesData[params.assets[vars.i]].yTokenAddress).transferUnderlyingTo(
                params.receiverAddress, vars.currentAmount
            );
        }

        require(
            vars.receiver.executeOperation(params.assets, params.amounts, vars.totalPremiums, msg.sender, params.params),
            Errors.INVALID_FLASHLOAN_EXECUTOR_RETURN
        );

        for (vars.i = 0; vars.i < params.assets.length; vars.i++) {
            vars.currentAsset = params.assets[vars.i];
            vars.currentAmount = params.amounts[vars.i];

            if (!params.createPosition[vars.i]) {
                _handleFlashLoanRepayment(
                    reservesData[vars.currentAsset],
                    DataTypes.FlashLoanRepaymentParams({
                        asset: vars.currentAsset,
                        receiverAddress: params.receiverAddress,
                        amount: vars.currentAmount,
                        totalPremium: vars.totalPremiums[vars.i],
                        flashLoanPremiumToProtocol: vars.flashloanPremiumToProtocol,
                        referralCode: params.referralCode
                    })
                );
            } else {
                // If the user chose to not return the funds, the system checks if there is enough collateral and
                // eventually opens a debt position
                BorrowLogic.executeBorrow(
                    reservesData,
                    reservesList,
                    erc1155ReservesData,
                    userConfig,
                    userERC1155Config,
                    DataTypes.ExecuteBorrowParams({
                        asset: vars.currentAsset,
                        user: msg.sender,
                        onBehalfOf: params.onBehalfOf,
                        amount: vars.currentAmount,
                        referralCode: params.referralCode,
                        releaseUnderlying: false,
                        reservesCount: params.reservesCount,
                        oracle: IPoolAddressesProvider(params.addressesProvider).getPriceOracle(),
                        priceOracleSentinel: IPoolAddressesProvider(params.addressesProvider).getPriceOracleSentinel()
                    })
                );
                // no premium is paid when taking on the flashloan as debt
                emit IPool.FlashLoan(
                    params.receiverAddress,
                    msg.sender,
                    vars.currentAsset,
                    vars.currentAmount,
                    true,
                    0,
                    params.referralCode
                );
            }
        }
    }

    /**
     * @notice Implements the simple flashloan feature that allow users to access liquidity of ONE reserve for one
     * transaction as long as the amount taken plus fee is returned.
     * @dev Does not waive fee for approved flashborrowers nor allow taking on debt instead of repaying to save gas
     * @dev At the end of the transaction the pool will pull amount borrowed + fee from the receiver,
     * if the receiver have not approved the pool the transaction will revert.
     * @dev Emits the `FlashLoan()` event
     * @param reserve The state of the flashloaned reserve
     * @param params The additional parameters needed to execute the simple flashloan function
     */
    function executeFlashLoanSimple(
        DataTypes.ReserveData storage reserve,
        DataTypes.FlashloanSimpleParams memory params
    ) external {
        // The usual action flow (cache -> updateState -> validation -> changeState -> updateRates)
        // is altered to (validation -> user payload -> cache -> updateState -> changeState -> updateRates) for flashloans.
        // This is done to protect against reentrance and rate manipulation within the user specified payload.

        ValidationLogic.validateFlashloanSimple(reserve);

        IFlashLoanSimpleReceiver receiver = IFlashLoanSimpleReceiver(params.receiverAddress);
        uint256 totalPremium = params.amount.percentMul(params.flashLoanPremiumTotal);
        IYToken(reserve.yTokenAddress).transferUnderlyingTo(params.receiverAddress, params.amount);

        require(
            receiver.executeOperation(params.asset, params.amount, totalPremium, msg.sender, params.params),
            Errors.INVALID_FLASHLOAN_EXECUTOR_RETURN
        );

        _handleFlashLoanRepayment(
            reserve,
            DataTypes.FlashLoanRepaymentParams({
                asset: params.asset,
                receiverAddress: params.receiverAddress,
                amount: params.amount,
                totalPremium: totalPremium,
                flashLoanPremiumToProtocol: params.flashLoanPremiumToProtocol,
                referralCode: params.referralCode
            })
        );
    }

    /**
     * @notice Handles repayment of flashloaned assets + premium
     * @dev Will pull the amount + premium from the receiver, so must have approved pool
     * @param reserve The state of the flashloaned reserve
     * @param params The additional parameters needed to execute the repayment function
     */
    function _handleFlashLoanRepayment(
        DataTypes.ReserveData storage reserve,
        DataTypes.FlashLoanRepaymentParams memory params
    ) internal {
        uint256 premiumToProtocol = params.totalPremium.percentMul(params.flashLoanPremiumToProtocol);
        uint256 premiumToLP = params.totalPremium - premiumToProtocol;
        uint256 amountPlusPremium = params.amount + params.totalPremium;

        DataTypes.ReserveCache memory reserveCache = reserve.cache();
        reserve.updateState(reserveCache);
        reserveCache.nextLiquidityIndex = reserve.cumulateToLiquidityIndex(
            IERC20(reserveCache.yTokenAddress).totalSupply()
                + uint256(reserve.accruedToTreasury).rayMul(reserveCache.nextLiquidityIndex),
            premiumToLP
        );

        reserve.accruedToTreasury += premiumToProtocol.rayDiv(reserveCache.nextLiquidityIndex).toUint128();

        reserve.updateInterestRates(reserveCache, params.asset, amountPlusPremium, 0);

        IERC20(params.asset).safeTransferFrom(params.receiverAddress, reserveCache.yTokenAddress, amountPlusPremium);

        IYToken(reserveCache.yTokenAddress).handleRepayment(
            params.receiverAddress, params.receiverAddress, amountPlusPremium
        );

        emit IPool.FlashLoan(
            params.receiverAddress,
            msg.sender,
            params.asset,
            params.amount,
            false,
            params.totalPremium,
            params.referralCode
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableYToken} from "./IInitializableYToken.sol";

/**
 * @title IYToken
 *
 * @notice Defines the basic interface for an YToken.
 */
interface IYToken is IERC20, IScaledBalanceToken, IInitializableYToken {
    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The scaled amount being transferred
     * @param index The next liquidity index of the reserve
     */
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @notice Mints `amount` yTokens to `user`
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted yTokens
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(address caller, address onBehalfOf, uint256 amount, uint256 index) external returns (bool);

    /**
     * @notice Burns yTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the yTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The next liquidity index of the reserve
     */
    function burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index) external;

    /**
     * @notice Mints yTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @notice Transfers yTokens in the event of a borrow being liquidated, in case the liquidators reclaims the yToken
     * @param from The address getting liquidated, current owner of the yTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     */
    function transferOnLiquidation(address from, address to, uint256 value) external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param target The recipient of the underlying
     * @param amount The amount getting transferred
     */
    function transferUnderlyingTo(address target, uint256 amount) external;

    /**
     * @notice Handles the underlying received by the yToken after the transfer has been completed.
     * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
     * transfer is concluded. However in the future there may be yTokens that allow for example to stake the underlying
     * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
     * @param user The user executing the repayment
     * @param onBehalfOf The address of the user who will get his debt reduced/removed
     * @param amount The amount getting repaid
     */
    function handleRepayment(address user, address onBehalfOf, uint256 amount) external;

    /**
     * @notice Allow passing a signed message to approve spending
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    /**
     * @notice Returns the address of the underlying asset of this yToken (E.g. WETH for aWETH)
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the address of the YLDR treasury, receiving the fees on this yToken.
     * @return Address of the YLDR treasury
     */
    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Returns the nonce for owner.
     * @param owner The address of the owner
     * @return The nonce of the owner
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../interfaces/IPool.sol";

/**
 * @title IFlashLoanReceiver
 *
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 */
interface IFlashLoanReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed assets
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param assets The addresses of the flash-borrowed assets
     * @param amounts The amounts of the flash-borrowed assets
     * @param premiums The fee of each flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    function POOL() external view returns (IPool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../interfaces/IPool.sol";

/**
 * @title IFlashLoanSimpleReceiver
 *
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 */
interface IFlashLoanSimpleReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bool);

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    function POOL() external view returns (IPool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an YLDR Pool.
 */
interface IPool {
    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the yTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event Supply(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );

    /**
     * @dev Emitted on supplyERC1155()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the yTokens
     * @param tokenId The tokenId supplied
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event SupplyERC1155(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 tokenId,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of yTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     */
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on withdrawERC1155()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the withdrawal
     * @param onBehalfOf The beneficiary of the withdrawal, receiving the yTokens
     * @param tokenId The tokenId withdrawn
     * @param amount The amount withdrawn
     */
    event WithdrawERC1155(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 tokenId, uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useYTokens True if the repayment is done using yTokens, `false` if done with underlying asset directly
     */
    event Repay(
        address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useYTokens
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseERC1155ReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param tokenId The tokenId of token being enabled as collateral
     * @param user The address of the user enabling the usage as collateral
     */
    event ERC1155ReserveUsedAsCollateralEnabled(address indexed reserve, uint256 indexed tokenId, address indexed user);

    /**
     * @dev Emitted on setUserUseERC1155ReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param tokenId The tokenId of token being disabled as collateral
     * @param user The address of the user disabling the usage as collateral
     */
    event ERC1155ReserveUsedAsCollateralDisabled(
        address indexed reserve, uint256 indexed tokenId, address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param openPosition Whether a new borrow position was opened
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     */
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        bool openPosition,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveYToken True if the liquidators wants to receive the collateral yTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveYToken
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param collateralTokenId The tokenId of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveNToken True if the liquidators wants to receive the collateral nTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event ERC1155LiquidationCall(
        address indexed collateralAsset,
        uint256 collateralTokenId,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveNToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted yTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     */
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying yTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the yTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of yTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Supplies an `tokenId` of underlying asset into the reserve, receiving in return overlying nTokens.
     * @param asset The address of the underlying asset to supply
     * @param tokenId The tokenId to be supplied
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the nTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of nTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supplyERC1155(address asset, uint256 tokenId, uint256 amount, address onBehalfOf, uint16 referralCode)
        external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the yTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of yTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     */
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent yTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole yToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Withdraws an `amount` of underlying asset with `tokenId` from the reserve, burning the equivalent nTokens owned
     * @param asset The address of the underlying asset to withdraw
     * @param tokenId The tokenId to be withdrawn
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole nToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdrawERC1155(address asset, uint256 tokenId, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 variable debt tokens
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     */
    function borrow(address asset, uint256 amount, uint16 referralCode, address onBehalfOf) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     */
    function repay(address asset, uint256 amount, address onBehalfOf) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     */
    function repayWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve yTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual yToken dust balance, if the user yToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @return The final amount repaid
     */
    function repayWithYTokens(address asset, uint256 amount) external returns (uint256);

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     */
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveYToken True if the liquidators wants to receive the collateral yTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveYToken
    ) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param collateralTokenId The tokenId of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveNToken True if the liquidators wants to receive the collateral nTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function erc1155LiquidationCall(
        address collateralAsset,
        uint256 collateralTokenId,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveNToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration.
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param createPosition Array of boolean values:
     *   false -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   true -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        bool[] calldata createPosition,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration.
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an yToken and debt token and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param yTokenAddress The address of the yToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     */
    function initReserve(
        address asset,
        address yTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Initializes a reserve, activating it, assigning an nToken and configuration provider
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param nTokenAddress The address of the nToken that will be assigned to the reserve
     * @param configurationProvider The address of the provider of configuration for the reserve
     */
    function initERC1155Reserve(address asset, address nTokenAddress, address configurationProvider) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserve(address asset) external;

    /**
     * @notice Drop a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropERC1155Reserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     */
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;

    /**
     * @notice Updates the address of the configuration provider for a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configurationProvider The address of the new configuration provider
     */
    function setERC1155ReserveConfigurationProvider(address asset, address configurationProvider) external;

    /**
     * @notice Updates the liquidation protocol fee for a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param liquidationProtocolFee New liquidation protocol fee
     */
    function setERC1155ReserveLiquidationProtocolFee(address asset, uint256 liquidationProtocolFee) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     */
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     */
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     */
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the list of ERC1155 reserves used by a user
     * @param user The user address
     * @return The list of ERC1155 reserves used as a collateral by a user
     */
    function getUserUsedERC1155Reserves(address user)
        external
        view
        returns (DataTypes.ERC1155ReserveUsageData[] memory);

    /**
     * @notice Returns the normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
     * "dynamic" variable index based on time, current stored index and virtual rate at the current
     * moment (approx. a borrower would get if opening a position). This means that is always used in
     * combination with variable debt supply/balances.
     * If using this function externally, consider that is possible to have an increasing normalized
     * variable debt that is not equivalent to how the variable debt index would be updated in storage
     * (e.g. only updates with non-zero variable debt supply)
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Returns the state and configuration of the ERC1155 reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getERC1155ReserveData(address asset) external view returns (DataTypes.ERC1155ReserveData memory);

    /**
     * @notice Validates and finalizes an yToken transfer
     * @dev Only callable by the overlying yToken of the `asset`
     * @param asset The address of the underlying asset of the yToken
     * @param from The user from which the yTokens are transferred
     * @param to The user receiving the yTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The yToken balance of the `from` user before the transfer
     * @param balanceToBefore The yToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Validates and finalizes an nToken transfer
     * @dev Only callable by the overlying nToken of the `asset`
     * @param asset The address of the underlying asset of the nToken
     * @param from The user from which the nToken are transferred
     * @param to The user receiving the nToken
     * @param ids The ids of tokens being transferred/withdrawn
     * @param amounts The amounts being transferred/withdrawn
     */
    function finalizeERC1155Transfer(
        address asset,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     */
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
     * - A part is sent to yToken holders as extra, one time accumulated interest
     * - A part is collected by the protocol treasury
     * @dev The total premium is calculated on the total borrowed amount
     * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremiumTotal The total premium, expressed in bps
     * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;

    /**
     * @notice Updates max amount of ERC1155 collaterals user may have.
     * @dev Only callable by the PoolConfigurator contract
     * @param maxERC1155CollateralReservesNumber The new value
     */
    function updateMaxERC1155CollateralReserves(uint256 maxERC1155CollateralReservesNumber) external;

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Returns the maximum number of ERC1155 collateral reserves which can be used by a single user
     * @return The maximum number of ERC1155 collateral reserves supported
     */
    function MAX_ERC1155_COLLATERAL_RESERVES() external view returns (uint256);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of yTokens
     * @param assets The list of reserves for which the minting needs to be executed
     */
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 *
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(bytes32 indexed id, address indexed proxyAddress, address indexed newImplementationAddress);

    /**
     * @notice Returns the id of the YLDR market to which this contract points to.
     * @return The market id
     */
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple YLDR markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     */
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     */
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     */
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     */
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     */
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     */
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveConfiguration} from "./ReserveConfiguration.sol";

/**
 * @title UserConfiguration library
 *
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    uint256 internal constant BORROWING_MASK = 0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 internal constant COLLATERAL_MASK = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

    /**
     * @notice Sets if the user is borrowing the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param borrowing True if the user is borrowing the reserve, false otherwise
     */
    function setBorrowing(DataTypes.UserConfigurationMap storage self, uint256 reserveIndex, bool borrowing) internal {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            uint256 bit = 1 << (reserveIndex << 1);
            if (borrowing) {
                self.data |= bit;
            } else {
                self.data &= ~bit;
            }
        }
    }

    /**
     * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
     */
    function setUsingAsCollateral(
        DataTypes.UserConfigurationMap storage self,
        uint256 reserveIndex,
        bool usingAsCollateral
    ) internal {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            uint256 bit = 1 << ((reserveIndex << 1) + 1);
            if (usingAsCollateral) {
                self.data |= bit;
            } else {
                self.data &= ~bit;
            }
        }
    }

    /**
     * @notice Returns if a user has been using the reserve for borrowing or as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
     */
    function isUsingAsCollateralOrBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
        internal
        pure
        returns (bool)
    {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            return (self.data >> (reserveIndex << 1)) & 3 != 0;
        }
    }

    /**
     * @notice Validate a user has been using the reserve for borrowing
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing, false otherwise
     */
    function isBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
        internal
        pure
        returns (bool)
    {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            return (self.data >> (reserveIndex << 1)) & 1 != 0;
        }
    }

    /**
     * @notice Validate a user has been using the reserve as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve as collateral, false otherwise
     */
    function isUsingAsCollateral(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
        internal
        pure
        returns (bool)
    {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            return (self.data >> ((reserveIndex << 1) + 1)) & 1 != 0;
        }
    }

    /**
     * @notice Checks if a user has been supplying only one reserve as collateral
     * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
     * @param self The configuration object
     * @return True if the user has been supplying as collateral one reserve, false otherwise
     */
    function isUsingAsCollateralOne(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        uint256 collateralData = self.data & COLLATERAL_MASK;
        return collateralData != 0 && (collateralData & (collateralData - 1) == 0);
    }

    /**
     * @notice Checks if a user has been supplying any reserve as collateral
     * @param self The configuration object
     * @return True if the user has been supplying as collateral any reserve, false otherwise
     */
    function isUsingAsCollateralAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        return self.data & COLLATERAL_MASK != 0;
    }

    /**
     * @notice Checks if a user has been borrowing only one asset
     * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
     * @param self The configuration object
     * @return True if the user has been supplying as collateral one reserve, false otherwise
     */
    function isBorrowingOne(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        uint256 borrowingData = self.data & BORROWING_MASK;
        return borrowingData != 0 && (borrowingData & (borrowingData - 1) == 0);
    }

    /**
     * @notice Checks if a user has been borrowing from any reserve
     * @param self The configuration object
     * @return True if the user has been borrowing any reserve, false otherwise
     */
    function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        return self.data & BORROWING_MASK != 0;
    }

    /**
     * @notice Checks if a user has not been using any reserve for borrowing or supply
     * @param self The configuration object
     * @return True if the user has not been borrowing or supplying any reserve, false otherwise
     */
    function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        return self.data == 0;
    }

    /**
     * @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
     * @param self The configuration object
     * @return The index of the first asset flagged in the bitmap once the corresponding mask is applied
     */
    function _getFirstAssetIdByMask(DataTypes.UserConfigurationMap memory self, uint256 mask)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 bitmapData = self.data & mask;
            uint256 firstAssetPosition = bitmapData & ~(bitmapData - 1);
            uint256 id;

            while ((firstAssetPosition >>= 2) != 0) {
                id += 1;
            }
            return id;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 *
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 internal constant LTV_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_BONUS_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 internal constant DECIMALS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FLASHLOAN_ENABLED_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant RESERVE_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROW_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant DEBT_CEILING_MASK = 0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
    uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
    uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
    uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
    uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
    uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

    uint256 internal constant MAX_VALID_LTV = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
    uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
    uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

    uint256 public constant DEBT_CEILING_DECIMALS = 2;
    uint16 public constant MAX_RESERVES_COUNT = 128;

    /**
     * @notice Sets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @param ltv The new ltv
     */
    function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
        require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @notice Gets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @return The loan to value
     */
    function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return self.data & ~LTV_MASK;
    }

    /**
     * @notice Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     */
    function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
        require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

        self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     */
    function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @param bonus The new liquidation bonus
     */
    function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

        self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @return The liquidation bonus
     */
    function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     */
    function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
        require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

        self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     */
    function getDecimals(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     */
    function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
        self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @notice Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     */
    function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @notice Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     */
    function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
        self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @notice Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     */
    function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @notice Sets the paused state of the reserve
     * @param self The reserve configuration
     * @param paused The paused state
     */
    function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
        self.data = (self.data & PAUSED_MASK) | (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the paused state of the reserve
     * @param self The reserve configuration
     * @return The paused state
     */
    function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~PAUSED_MASK) != 0;
    }

    /**
     * @notice Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     */
    function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
        self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     */
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @notice Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     */
    function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
        require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

        self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @notice Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     */
    function getReserveFactor(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @notice Sets the borrow cap of the reserve
     * @param self The reserve configuration
     * @param borrowCap The borrow cap
     */
    function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap) internal pure {
        require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

        self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrow cap of the reserve
     * @param self The reserve configuration
     * @return The borrow cap
     */
    function getBorrowCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the supply cap of the reserve
     * @param self The reserve configuration
     * @param supplyCap The supply cap
     */
    function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap) internal pure {
        require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the supply cap of the reserve
     * @param self The reserve configuration
     * @return The supply cap
     */
    function getSupplyCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation protocol fee of the reserve
     * @param self The reserve configuration
     * @param liquidationProtocolFee The liquidation protocol fee
     */
    function setLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self, uint256 liquidationProtocolFee)
        internal
        pure
    {
        require(liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE, Errors.INVALID_LIQUIDATION_PROTOCOL_FEE);

        self.data = (self.data & LIQUIDATION_PROTOCOL_FEE_MASK)
            | (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation protocol fee
     * @param self The reserve configuration
     * @return The liquidation protocol fee
     */
    function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Sets the flashloanable flag for the reserve
     * @param self The reserve configuration
     * @param flashLoanEnabled True if the asset is flashloanable, false otherwise
     */
    function setFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self, bool flashLoanEnabled) internal pure {
        self.data = (self.data & FLASHLOAN_ENABLED_MASK)
            | (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the flashloanable flag for the reserve
     * @param self The reserve configuration
     * @return The flashloanable flag
     */
    function getFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
    }

    /**
     * @notice Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flag representing active
     * @return The state flag representing frozen
     * @return The state flag representing borrowing enabled
     * @return The state flag representing paused
     */
    function getFlags(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool, bool, bool, bool) {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~PAUSED_MASK) != 0
        );
    }

    /**
     * @notice Gets the configuration parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing ltv
     * @return The state param representing liquidation threshold
     * @return The state param representing liquidation bonus
     * @return The state param representing reserve decimals
     * @return The state param representing reserve factor
     */
    function getParams(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~LTV_MASK,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
            (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @notice Gets the caps parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing borrow cap
     * @return The state param representing supply cap.
     */
    function getCaps(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256, uint256) {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
            (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors library
 *
 * @notice Defines the error messages emitted by the different contracts of the YLDR protocol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "1"; // 'The caller of the function is not a pool admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = "3"; // 'The caller of the function is not a pool or emergency admin'
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = "4"; // 'The caller of the function is not a risk or pool admin'
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = "5"; // 'The caller of the function is not an asset listing or pool admin'
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "7"; // 'Pool addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "8"; // 'Invalid id for the pool addresses provider'
    string public constant NOT_CONTRACT = "9"; // 'Address is not a contract'
    string public constant CALLER_NOT_POOL_CONFIGURATOR = "10"; // 'The caller of the function is not the pool configurator'
    string public constant CALLER_NOT_YTOKEN = "11"; // 'The caller of the function is not an YToken'
    string public constant INVALID_ADDRESSES_PROVIDER = "12"; // 'The address of the pool addresses provider is invalid'
    string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = "13"; // 'Invalid return value of the flashloan executor function'
    string public constant RESERVE_ALREADY_ADDED = "14"; // 'Reserve has already been added to reserve list'
    string public constant NO_MORE_RESERVES_ALLOWED = "15"; // 'Maximum amount of reserves in the pool reached'
    string public constant RESERVE_LIQUIDITY_NOT_ZERO = "18"; // 'The liquidity of the reserve needs to be 0'
    string public constant FLASHLOAN_PREMIUM_INVALID = "19"; // 'Invalid flashloan premium'
    string public constant INVALID_RESERVE_PARAMS = "20"; // 'Invalid risk parameters for the reserve'
    string public constant CALLER_MUST_BE_POOL = "23"; // 'The caller of this function must be a pool'
    string public constant INVALID_MINT_AMOUNT = "24"; // 'Invalid amount to mint'
    string public constant INVALID_BURN_AMOUNT = "25"; // 'Invalid amount to burn'
    string public constant INVALID_AMOUNT = "26"; // 'Amount must be greater than 0'
    string public constant RESERVE_INACTIVE = "27"; // 'Action requires an active reserve'
    string public constant RESERVE_FROZEN = "28"; // 'Action cannot be performed because the reserve is frozen'
    string public constant RESERVE_PAUSED = "29"; // 'Action cannot be performed because the reserve is paused'
    string public constant BORROWING_NOT_ENABLED = "30"; // 'Borrowing is not enabled'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "32"; // 'User cannot withdraw more than the available balance'
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED = "33"; // 'Invalid interest rate mode selected'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "34"; // 'The collateral balance is 0'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "35"; // 'Health factor is lesser than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "36"; // 'There is not enough collateral to cover a new borrow'
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = "37"; // 'Collateral is (mostly) the same currency that is being borrowed'
    string public constant NO_DEBT = "39"; // 'For repayment of debt, the user needs to have debt'
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "40"; // 'To repay on behalf of a user an explicit amount to repay is needed'
    string public constant NO_OUTSTANDING_VARIABLE_DEBT = "42"; // 'User does not have outstanding variable rate debt on this reserve'
    string public constant UNDERLYING_BALANCE_ZERO = "43"; // 'The underlying balance needs to be greater than 0'
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "44"; // 'Interest rate rebalance conditions were not met'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "45"; // 'Health factor is not below the threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "46"; // 'The collateral chosen cannot be liquidated'
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "47"; // 'User did not borrow the specified currency'
    string public constant INCONSISTENT_FLASHLOAN_PARAMS = "49"; // 'Inconsistent flashloan parameters'
    string public constant BORROW_CAP_EXCEEDED = "50"; // 'Borrow cap is exceeded'
    string public constant SUPPLY_CAP_EXCEEDED = "51"; // 'Supply cap is exceeded'
    string public constant DEBT_CEILING_EXCEEDED = "53"; // 'Debt ceiling is exceeded'
    string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = "54"; // 'Claimable rights over underlying not zero (yToken supply or accruedToTreasury)'
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = "56"; // 'Variable debt supply is not zero'
    string public constant LTV_VALIDATION_FAILED = "57"; // 'Ltv validation failed'
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "59"; // 'Price oracle sentinel validation failed'
    string public constant RESERVE_ALREADY_INITIALIZED = "61"; // 'Reserve has already been initialized'
    string public constant LTV_ZERO = "62"; // 'LTV is zero'
    string public constant INVALID_LTV = "63"; // 'Invalid ltv parameter for the reserve'
    string public constant INVALID_LIQ_THRESHOLD = "64"; // 'Invalid liquidity threshold parameter for the reserve'
    string public constant INVALID_LIQ_BONUS = "65"; // 'Invalid liquidity bonus parameter for the reserve'
    string public constant INVALID_DECIMALS = "66"; // 'Invalid decimals parameter of the underlying asset of the reserve'
    string public constant INVALID_RESERVE_FACTOR = "67"; // 'Invalid reserve factor parameter for the reserve'
    string public constant INVALID_BORROW_CAP = "68"; // 'Invalid borrow cap for the reserve'
    string public constant INVALID_SUPPLY_CAP = "69"; // 'Invalid supply cap for the reserve'
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = "70"; // 'Invalid liquidation protocol fee for the reserve'
    string public constant INVALID_DEBT_CEILING = "73"; // 'Invalid debt ceiling for the reserve
    string public constant INVALID_RESERVE_INDEX = "74"; // 'Invalid reserve index'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "75"; // 'ACL admin cannot be set to the zero address'
    string public constant INCONSISTENT_PARAMS_LENGTH = "76"; // 'Array parameters that should be equal length are not'
    string public constant ZERO_ADDRESS_NOT_VALID = "77"; // 'Zero address not valid'
    string public constant INVALID_EXPIRATION = "78"; // 'Invalid expiration'
    string public constant INVALID_SIGNATURE = "79"; // 'Invalid signature'
    string public constant OPERATION_NOT_SUPPORTED = "80"; // 'Operation not supported'
    string public constant DEBT_CEILING_NOT_ZERO = "81"; // 'Debt ceiling is not zero'
    string public constant ASSET_NOT_LISTED = "82"; // 'Asset is not listed'
    string public constant INVALID_OPTIMAL_USAGE_RATIO = "83"; // 'Invalid optimal usage ratio'
    string public constant UNDERLYING_CANNOT_BE_RESCUED = "85"; // 'The underlying asset cannot be rescued'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "86"; // 'Reserve has already been added to reserve list'
    string public constant POOL_ADDRESSES_DO_NOT_MATCH = "87"; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
    string public constant RESERVE_DEBT_NOT_ZERO = "90"; // the total debt of the reserve needs to be 0
    string public constant FLASHLOAN_DISABLED = "91"; // FlashLoaning for this asset is disabled
    string public constant CALLER_NOT_NTOKEN = "92"; // 'The caller of the function is not an NToken'
    string public constant ERC1155_RESERVE_CANNOT_BE_USED_AS_COLLATERAL = "93"; // ERC1155 reserve can only be supplied if it can be enabled as collateral
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 *
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) { revert(0, 0) }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) { revert(0, 0) }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) { b := add(b, 1) }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) { revert(0, 0) }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title PercentageMath library
 *
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     */
    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(or(iszero(percentage), iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     */
    function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(
                iszero(percentage), iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))
            ) { revert(0, 0) }

            result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //yToken address
        address yTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62: siloed borrowing enabled
        //bit 63: flashloaning enabled
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused
        uint256 data;
    }

    struct ERC1155ReserveData {
        address nTokenAddress;
        address configurationProvider;
        uint256 liquidationProtocolFee;
    }

    struct ERC1155ReserveConfiguration {
        bool isActive;
        bool isFrozen;
        bool isPaused;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct ERC1155ReserveUsageData {
        address asset;
        uint256 tokenId;
    }

    struct UserERC1155ConfigurationMap {
        // List of ERC1155 reserves used by user
        ERC1155ReserveUsageData[] usedERC1155Reserves;
        // Mapping matching given asset and tokenId to index in usedERC1155Reserves array + 1
        // Index 0 is used for not used reserves
        mapping(address asset => mapping(uint256 tokenId => uint256 indexPlus1)) usedERC1155ReservesMap;
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address yTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveYToken;
        address priceOracle;
        address priceOracleSentinel;
    }

    struct ExecuteERC1155LiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        uint256 collateralTokenId;
        address debtAsset;
        address user;
        bool receiveNToken;
        address priceOracle;
        address priceOracleSentinel;
        uint256 maxERC1155CollateralReserves;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteSupplyERC1155Params {
        address asset;
        uint256 tokenId;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
        uint256 maxERC1155CollateralReserves;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        bool useYTokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct ExecuteWithdrawERC1155Params {
        address asset;
        uint256 tokenId;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeERC1155TransferParams {
        address asset;
        address from;
        address to;
        uint256[] ids;
        uint256[] amounts;
        uint256 reservesCount;
        address oracle;
        uint256 maxERC1155CollateralReserves;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        bool[] createPosition;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 reservesCount;
        address addressesProvider;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct ValidateERC1155LiquidationCallParams {
        address collateralReserveAddress;
        uint256 collateralReserveTokenId;
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct ValidateHealthFactorParams {
        UserConfigurationMap userConfig;
        address user;
        uint256 reservesCount;
        address oracle;
    }

    struct CalculateInterestRatesParams {
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalVariableDebt;
        uint256 reserveFactor;
        address reserve;
        address yToken;
    }

    struct InitReserveParams {
        address asset;
        address yTokenAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }

    struct InitERC1155ReserveParams {
        address asset;
        address nTokenAddress;
        address configurationProvider;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {IYToken} from "../../../interfaces/IYToken.sol";
import {IPriceOracleSentinel} from "../../../interfaces/IPriceOracleSentinel.sol";
import {IPoolAddressesProvider} from "../../../interfaces/IPoolAddressesProvider.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {UserERC1155Configuration} from "../configuration/UserERC1155Configuration.sol";
import {Errors} from "../helpers/Errors.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IncentivizedERC20} from "../../tokenization/base/IncentivizedERC20.sol";

/**
 * @title ReserveLogic library
 *
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using UserERC1155Configuration for DataTypes.UserERC1155ConfigurationMap;
    using Address for address;

    // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
    // A value of 0.9e4 results in 90%
    uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

    // Minimum health factor allowed under any circumstance
    // A value of 0.95e18 results in 0.95
    uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 0.95e18;

    /**
     * @dev Minimum health factor to consider a user position healthy
     * A value of 1e18 results in 1
     */
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    /**
     * @notice Validates a supply action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be supplied
     */
    function validateSupply(
        DataTypes.ReserveCache memory reserveCache,
        DataTypes.ReserveData storage reserve,
        uint256 amount
    ) internal view {
        require(amount != 0, Errors.INVALID_AMOUNT);

        (bool isActive, bool isFrozen,, bool isPaused) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(!isFrozen, Errors.RESERVE_FROZEN);

        uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();
        require(
            supplyCap == 0
                || (
                    (IYToken(reserveCache.yTokenAddress).scaledTotalSupply() + uint256(reserve.accruedToTreasury)).rayMul(
                        reserveCache.nextLiquidityIndex
                    ) + amount
                ) <= supplyCap * (10 ** reserveCache.reserveConfiguration.getDecimals()),
            Errors.SUPPLY_CAP_EXCEEDED
        );
    }

    /**
     * @notice Validates a supply action.
     * @param reserveConfig The config of the reserve
     * @param amount The amount to be supplied
     */
    function validateSupplyERC1155(
        DataTypes.ERC1155ReserveConfiguration memory reserveConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        address underlying,
        uint256 tokenId,
        uint256 amount,
        uint256 maxERC1155CollateralReserves
    ) internal view {
        require(amount != 0, Errors.INVALID_AMOUNT);

        require(reserveConfig.isActive, Errors.RESERVE_INACTIVE);
        require(!reserveConfig.isPaused, Errors.RESERVE_PAUSED);
        require(!reserveConfig.isFrozen, Errors.RESERVE_FROZEN);

        if (!userERC1155Config.isUsingAsCollateral(underlying, tokenId)) {
            require(
                validateUseERC1155AsCollateral(reserveConfig, userERC1155Config, maxERC1155CollateralReserves),
                Errors.ERC1155_RESERVE_CANNOT_BE_USED_AS_COLLATERAL
            );
        }
    }

    /**
     * @notice Validates a withdraw action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     */
    function validateWithdraw(DataTypes.ReserveCache memory reserveCache, uint256 amount, uint256 userBalance)
        internal
        pure
    {
        require(amount != 0, Errors.INVALID_AMOUNT);
        require(amount <= userBalance, Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE);

        (bool isActive,,, bool isPaused) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a withdrawERC1155 action.
     * @param reserveConfig The config of the reserve
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     */
    function validateWithdrawERC1155(
        DataTypes.ERC1155ReserveConfiguration memory reserveConfig,
        uint256 amount,
        uint256 userBalance
    ) internal pure {
        require(amount != 0, Errors.INVALID_AMOUNT);
        require(amount <= userBalance, Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE);

        require(reserveConfig.isActive, Errors.RESERVE_INACTIVE);
        require(!reserveConfig.isPaused, Errors.RESERVE_PAUSED);
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 collateralNeededInBaseCurrency;
        uint256 userCollateralInBaseCurrency;
        uint256 userDebtInBaseCurrency;
        uint256 availableLiquidity;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 totalSupplyVariableDebt;
        uint256 reserveDecimals;
        uint256 borrowCap;
        uint256 amountInBaseCurrency;
        uint256 assetUnit;
        bool isActive;
        bool isFrozen;
        bool isPaused;
        bool borrowingEnabled;
    }

    /**
     * @notice Validates a borrow action.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional params needed for the validation
     */
    function validateBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.ValidateBorrowParams memory params
    ) internal view {
        require(params.amount != 0, Errors.INVALID_AMOUNT);

        ValidateBorrowLocalVars memory vars;

        (vars.isActive, vars.isFrozen, vars.borrowingEnabled, vars.isPaused) =
            params.reserveCache.reserveConfiguration.getFlags();

        require(vars.isActive, Errors.RESERVE_INACTIVE);
        require(!vars.isPaused, Errors.RESERVE_PAUSED);
        require(!vars.isFrozen, Errors.RESERVE_FROZEN);
        require(vars.borrowingEnabled, Errors.BORROWING_NOT_ENABLED);

        require(
            params.priceOracleSentinel == address(0)
                || IPriceOracleSentinel(params.priceOracleSentinel).isBorrowAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        vars.reserveDecimals = params.reserveCache.reserveConfiguration.getDecimals();
        vars.borrowCap = params.reserveCache.reserveConfiguration.getBorrowCap();
        unchecked {
            vars.assetUnit = 10 ** vars.reserveDecimals;
        }

        if (vars.borrowCap != 0) {
            vars.totalSupplyVariableDebt =
                params.reserveCache.currScaledVariableDebt.rayMul(params.reserveCache.nextVariableBorrowIndex);

            vars.totalDebt = vars.totalSupplyVariableDebt + params.amount;

            unchecked {
                require(vars.totalDebt <= vars.borrowCap * vars.assetUnit, Errors.BORROW_CAP_EXCEEDED);
            }
        }

        (vars.userCollateralInBaseCurrency, vars.userDebtInBaseCurrency, vars.currentLtv,, vars.healthFactor,) =
        GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: params.userConfig,
                reservesCount: params.reservesCount,
                user: params.userAddress,
                oracle: params.oracle
            })
        );

        require(vars.userCollateralInBaseCurrency != 0, Errors.COLLATERAL_BALANCE_IS_ZERO);
        require(vars.currentLtv != 0, Errors.LTV_VALIDATION_FAILED);

        require(
            vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        vars.amountInBaseCurrency = IPriceOracleGetter(params.oracle).getAssetPrice(params.asset) * params.amount;
        unchecked {
            vars.amountInBaseCurrency /= vars.assetUnit;
        }

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        vars.collateralNeededInBaseCurrency =
            (vars.userDebtInBaseCurrency + vars.amountInBaseCurrency).percentDiv(vars.currentLtv); //LTV is calculated in percentage

        require(
            vars.collateralNeededInBaseCurrency <= vars.userCollateralInBaseCurrency,
            Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW
        );
    }

    /**
     * @notice Validates a repay action.
     * @param reserveCache The cached data of the reserve
     * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
     * @param onBehalfOf The address of the user msg.sender is repaying for
     * @param variableDebt The borrow balance of the user
     */
    function validateRepay(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amountSent,
        address onBehalfOf,
        uint256 variableDebt
    ) internal view {
        require(amountSent != 0, Errors.INVALID_AMOUNT);
        require(
            amountSent != type(uint256).max || msg.sender == onBehalfOf, Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
        );

        (bool isActive,,, bool isPaused) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);

        require(variableDebt != 0, Errors.NO_DEBT);
    }

    /**
     * @notice Validates the action of setting an asset as collateral.
     * @param reserveCache The cached data of the reserve
     * @param userBalance The balance of the user
     */
    function validateSetUseReserveAsCollateral(DataTypes.ReserveCache memory reserveCache, uint256 userBalance)
        internal
        pure
    {
        require(userBalance != 0, Errors.UNDERLYING_BALANCE_ZERO);

        (bool isActive,,, bool isPaused) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a flashloan action.
     * @param reservesData The state of all the reserves
     * @param assets The assets being flash-borrowed
     * @param amounts The amounts for each asset being borrowed
     */
    function validateFlashloan(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address[] memory assets,
        uint256[] memory amounts
    ) internal view {
        require(assets.length == amounts.length, Errors.INCONSISTENT_FLASHLOAN_PARAMS);
        for (uint256 i = 0; i < assets.length; i++) {
            validateFlashloanSimple(reservesData[assets[i]]);
        }
    }

    /**
     * @notice Validates a flashloan action.
     * @param reserve The state of the reserve
     */
    function validateFlashloanSimple(DataTypes.ReserveData storage reserve) internal view {
        DataTypes.ReserveConfigurationMap memory configuration = reserve.configuration;
        require(!configuration.getPaused(), Errors.RESERVE_PAUSED);
        require(configuration.getActive(), Errors.RESERVE_INACTIVE);
        require(configuration.getFlashLoanEnabled(), Errors.FLASHLOAN_DISABLED);
    }

    struct ValidateLiquidationCallLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool principalReserveActive;
        bool principalReservePaused;
        bool isCollateralEnabled;
    }

    /**
     * @notice Validates the liquidation action.
     * @param userConfig The user configuration mapping
     * @param collateralReserve The reserve data of the collateral
     * @param params Additional parameters needed for the validation
     */
    function validateLiquidationCall(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateLiquidationCallParams memory params
    ) internal view {
        ValidateLiquidationCallLocalVars memory vars;

        (vars.collateralReserveActive,,, vars.collateralReservePaused) = collateralReserve.configuration.getFlags();

        (vars.principalReserveActive,,, vars.principalReservePaused) =
            params.debtReserveCache.reserveConfiguration.getFlags();

        require(vars.collateralReserveActive && vars.principalReserveActive, Errors.RESERVE_INACTIVE);
        require(!vars.collateralReservePaused && !vars.principalReservePaused, Errors.RESERVE_PAUSED);

        require(
            params.priceOracleSentinel == address(0)
                || params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
                || IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        require(params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD, Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD);

        vars.isCollateralEnabled = collateralReserve.configuration.getLiquidationThreshold() != 0
            && userConfig.isUsingAsCollateral(collateralReserve.id);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(vars.isCollateralEnabled, Errors.COLLATERAL_CANNOT_BE_LIQUIDATED);
        require(params.totalDebt != 0, Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER);
    }

    struct ValidateERC1155LiquidationCallLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool debtReserveActive;
        bool debtReservePaused;
        bool isCollateralEnabled;
    }

    function validateERC1155LiquidationCall(
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.ERC1155ReserveData storage collateralReserve,
        DataTypes.ERC1155ReserveConfiguration memory collateralReserveConfig,
        DataTypes.ValidateERC1155LiquidationCallParams memory params
    ) internal view {
        ValidateERC1155LiquidationCallLocalVars memory vars;

        (vars.debtReserveActive,,, vars.debtReservePaused) = params.debtReserveCache.reserveConfiguration.getFlags();

        require(collateralReserveConfig.isActive && vars.debtReserveActive, Errors.RESERVE_INACTIVE);
        require(!collateralReserveConfig.isPaused && !vars.debtReservePaused, Errors.RESERVE_PAUSED);

        require(
            params.priceOracleSentinel == address(0)
                || params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
                || IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        require(params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD, Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD);

        vars.isCollateralEnabled = collateralReserveConfig.liquidationThreshold != 0
            && userERC1155Config.isUsingAsCollateral(params.collateralReserveAddress, params.collateralReserveTokenId);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(vars.isCollateralEnabled, Errors.COLLATERAL_CANNOT_BE_LIQUIDATED);
        require(params.totalDebt != 0, Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER);
    }

    /**
     * @notice Validates the health factor of a user.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for the validation
     */
    function validateHealthFactor(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.ValidateHealthFactorParams memory params
    ) internal view returns (uint256, bool) {
        (,,,, uint256 healthFactor, bool hasZeroLtvCollateral) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: params.userConfig,
                reservesCount: params.reservesCount,
                user: params.user,
                oracle: params.oracle
            })
        );

        require(
            healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD, Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        return (healthFactor, hasZeroLtvCollateral);
    }

    /**
     * @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param reserveLtv The LTV of asset for which the ltv will be validated
     * @param from The user from which the yTokens are being transferred
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHFAndLtv(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserConfigurationMap memory userConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        uint256 reserveLtv,
        address from,
        uint256 reservesCount,
        address oracle
    ) internal view {
        (, bool hasZeroLtvCollateral) = validateHealthFactor(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.ValidateHealthFactorParams({
                userConfig: userConfig,
                user: from,
                reservesCount: reservesCount,
                oracle: oracle
            })
        );

        require(!hasZeroLtvCollateral || reserveLtv == 0, Errors.LTV_VALIDATION_FAILED);
    }

    /**
     * @notice Validates a transfer action.
     * @param reserve The reserve object
     */
    function validateTransfer(DataTypes.ReserveData storage reserve) internal view {
        require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a ERC1155 transfer action.
     * @param reserveConfig The reserve config
     */
    function validateERC1155Transfer(DataTypes.ERC1155ReserveConfiguration memory reserveConfig) internal pure {
        require(!reserveConfig.isPaused, Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a drop reserve action.
     * @param reservesList The addresses of all the active reserves
     * @param reserve The reserve object
     * @param asset The address of the reserve's underlying asset
     */
    function validateDropReserve(
        mapping(uint256 => address) storage reservesList,
        DataTypes.ReserveData storage reserve,
        address asset
    ) internal view {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(reserve.id != 0 || reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
        require(IERC20(reserve.variableDebtTokenAddress).totalSupply() == 0, Errors.VARIABLE_DEBT_SUPPLY_NOT_ZERO);
        require(
            IERC20(reserve.yTokenAddress).totalSupply() == 0 && reserve.accruedToTreasury == 0,
            Errors.UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO
        );
    }

    /**
     * @notice Validates a drop ERC1155 reserve action.
     * @param reserve The reserve object
     * @param asset The address of the reserve's underlying asset
     */
    function validateDropERC1155Reserve(DataTypes.ERC1155ReserveData storage reserve, address asset) internal view {
        // For non-existent reserve, asset will be zero, so this actually checks if the reserve exists too
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(INToken(reserve.nTokenAddress).totalSupply() == 0, Errors.UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO);
    }

    /**
     * @notice Validates the action of activating the asset as collateral.
     * @dev Only possible if the asset has non-zero LTV
     * @param reserveConfig The reserve configuration
     * @return True if the asset can be activated as collateral, false otherwise
     */
    function validateUseAsCollateral(DataTypes.ReserveConfigurationMap memory reserveConfig)
        internal
        pure
        returns (bool)
    {
        return reserveConfig.getLtv() != 0;
    }

    /**
     * @notice Validates the action of activating the asset as collateral.
     * @dev Only possible if the asset has non-zero LTV
     * @param reserveConfig The reserve configuration
     * @return True if the asset can be activated as collateral, false otherwise
     */
    function validateUseERC1155AsCollateral(
        DataTypes.ERC1155ReserveConfiguration memory reserveConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        uint256 maxERC1155CollateralReserves
    ) internal view returns (bool) {
        if (maxERC1155CollateralReserves == 0) {
            return false;
        }
        if (userERC1155Config.getUsedReservesCount() >= maxERC1155CollateralReserves) {
            return false;
        }
        return reserveConfig.ltv != 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IYToken} from "../../../interfaces/IYToken.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {Helpers} from "../helpers/Helpers.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title BorrowLogic library
 *
 * @notice Implements the base logic for all the actions related to borrowing
 */
library BorrowLogic {
    using ReserveLogic for DataTypes.ReserveCache;
    using ReserveLogic for DataTypes.ReserveData;
    using SafeERC20 for IERC20;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeCast for uint256;

    /**
     * @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
     * YLDR protocol proportionally to their collateralization power. For isolated positions, it also increases the
     * isolated debt.
     * @dev  Emits the `Borrow()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the borrow function
     */
    function executeBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.ExecuteBorrowParams memory params
    ) public {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        ValidationLogic.validateBorrow(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.ValidateBorrowParams({
                reserveCache: reserveCache,
                userConfig: userConfig,
                asset: params.asset,
                userAddress: params.onBehalfOf,
                amount: params.amount,
                reservesCount: params.reservesCount,
                oracle: params.oracle,
                priceOracleSentinel: params.priceOracleSentinel
            })
        );

        bool isFirstBorrowing = false;

        (isFirstBorrowing, reserveCache.nextScaledVariableDebt) = IVariableDebtToken(
            reserveCache.variableDebtTokenAddress
        ).mint(params.user, params.onBehalfOf, params.amount, reserveCache.nextVariableBorrowIndex);

        if (isFirstBorrowing) {
            userConfig.setBorrowing(reserve.id, true);
        }

        reserve.updateInterestRates(reserveCache, params.asset, 0, params.releaseUnderlying ? params.amount : 0);

        if (params.releaseUnderlying) {
            IYToken(reserveCache.yTokenAddress).transferUnderlyingTo(params.user, params.amount);
        }

        emit IPool.Borrow(
            params.asset,
            params.user,
            params.onBehalfOf,
            params.amount,
            reserve.currentVariableBorrowRate,
            params.referralCode
        );
    }

    /**
     * @notice Implements the repay feature. Repaying transfers the underlying back to the yToken and clears the
     * equivalent amount of debt for the user by burning the corresponding debt token. For isolated positions, it also
     * reduces the isolated debt.
     * @dev  Emits the `Repay()` event
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the repay function
     * @return The actual amount being repaid
     */
    function executeRepay(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteRepayParams memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();
        reserve.updateState(reserveCache);

        uint256 variableDebt = Helpers.getUserCurrentDebt(params.onBehalfOf, reserveCache);

        ValidationLogic.validateRepay(reserveCache, params.amount, params.onBehalfOf, variableDebt);

        uint256 paybackAmount = variableDebt;

        // Allows a user to repay with yTokens without leaving dust from interest.
        if (params.useYTokens && params.amount == type(uint256).max) {
            params.amount = IYToken(reserveCache.yTokenAddress).balanceOf(msg.sender);
        }

        if (params.amount < paybackAmount) {
            paybackAmount = params.amount;
        }

        reserveCache.nextScaledVariableDebt = IVariableDebtToken(reserveCache.variableDebtTokenAddress).burn(
            params.onBehalfOf, paybackAmount, reserveCache.nextVariableBorrowIndex
        );

        reserve.updateInterestRates(reserveCache, params.asset, params.useYTokens ? 0 : paybackAmount, 0);

        if (variableDebt == paybackAmount) {
            userConfig.setBorrowing(reserve.id, false);
        }

        if (params.useYTokens) {
            IYToken(reserveCache.yTokenAddress).burn(
                msg.sender, reserveCache.yTokenAddress, paybackAmount, reserveCache.nextLiquidityIndex
            );
        } else {
            IERC20(params.asset).safeTransferFrom(msg.sender, reserveCache.yTokenAddress, paybackAmount);
            IYToken(reserveCache.yTokenAddress).handleRepayment(msg.sender, params.onBehalfOf, paybackAmount);
        }

        emit IPool.Repay(params.asset, params.onBehalfOf, msg.sender, paybackAmount, params.useYTokens);

        return paybackAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPool} from "../../../interfaces/IPool.sol";

/**
 * @title ReserveLogic library
 *
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /**
     * @notice Returns the ongoing normalized income for the reserve.
     * @dev A value of 1e27 means there is no income. As time passes, the income is accrued
     * @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
     * @param reserve The reserve object
     * @return The normalized income, expressed in ray
     */
    function getNormalizedIncome(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == block.timestamp) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.liquidityIndex;
        } else {
            return MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
                reserve.liquidityIndex
            );
        }
    }

    /**
     * @notice Returns the ongoing normalized variable debt for the reserve.
     * @dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
     * @dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
     * @param reserve The reserve object
     * @return The normalized variable debt, expressed in ray
     */
    function getNormalizedDebt(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == block.timestamp) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.variableBorrowIndex;
        } else {
            return MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
                reserve.variableBorrowIndex
            );
        }
    }

    /**
     * @notice Updates the liquidity cumulative index and the variable borrow index.
     * @param reserve The reserve object
     * @param reserveCache The caching layer for the reserve data
     */
    function updateState(DataTypes.ReserveData storage reserve, DataTypes.ReserveCache memory reserveCache) internal {
        // If time didn't pass since last stored timestamp, skip state update
        //solium-disable-next-line
        if (reserve.lastUpdateTimestamp == uint40(block.timestamp)) {
            return;
        }

        _updateIndexes(reserve, reserveCache);
        _accrueToTreasury(reserve, reserveCache);

        //solium-disable-next-line
        reserve.lastUpdateTimestamp = uint40(block.timestamp);
    }

    /**
     * @notice Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example
     * to accumulate the flashloan fee to the reserve, and spread it between all the suppliers.
     * @param reserve The reserve object
     * @param totalLiquidity The total liquidity available in the reserve
     * @param amount The amount to accumulate
     * @return The next liquidity index of the reserve
     */
    function cumulateToLiquidityIndex(DataTypes.ReserveData storage reserve, uint256 totalLiquidity, uint256 amount)
        internal
        returns (uint256)
    {
        //next liquidity index is calculated this way: `((amount / totalLiquidity) + 1) * liquidityIndex`
        //division `amount / totalLiquidity` done in ray for precision
        uint256 result =
            (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) + WadRayMath.RAY).rayMul(reserve.liquidityIndex);
        reserve.liquidityIndex = result.toUint128();
        return result;
    }

    /**
     * @notice Initializes a reserve.
     * @param reserve The reserve object
     * @param yTokenAddress The address of the overlying ytoken contract
     * @param variableDebtTokenAddress The address of the overlying variable debt token contract
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     */
    function init(
        DataTypes.ReserveData storage reserve,
        address yTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress
    ) internal {
        require(reserve.yTokenAddress == address(0), Errors.RESERVE_ALREADY_INITIALIZED);

        reserve.liquidityIndex = uint128(WadRayMath.RAY);
        reserve.variableBorrowIndex = uint128(WadRayMath.RAY);
        reserve.yTokenAddress = yTokenAddress;
        reserve.variableDebtTokenAddress = variableDebtTokenAddress;
        reserve.interestRateStrategyAddress = interestRateStrategyAddress;
    }

    struct UpdateInterestRatesLocalVars {
        uint256 nextLiquidityRate;
        uint256 nextVariableRate;
        uint256 totalVariableDebt;
    }

    /**
     * @notice Updates the reserve current variable borrow rate and the current liquidity rate.
     * @param reserve The reserve reserve to be updated
     * @param reserveCache The caching layer for the reserve data
     * @param reserveAddress The address of the reserve to be updated
     * @param liquidityAdded The amount of liquidity added to the protocol (supply or repay) in the previous action
     * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
     */
    function updateInterestRates(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache,
        address reserveAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) internal {
        UpdateInterestRatesLocalVars memory vars;

        vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(reserveCache.nextVariableBorrowIndex);

        (vars.nextLiquidityRate, vars.nextVariableRate) = IReserveInterestRateStrategy(
            reserve.interestRateStrategyAddress
        ).calculateInterestRates(
            DataTypes.CalculateInterestRatesParams({
                liquidityAdded: liquidityAdded,
                liquidityTaken: liquidityTaken,
                totalVariableDebt: vars.totalVariableDebt,
                reserveFactor: reserveCache.reserveFactor,
                reserve: reserveAddress,
                yToken: reserveCache.yTokenAddress
            })
        );

        reserve.currentLiquidityRate = vars.nextLiquidityRate.toUint128();
        reserve.currentVariableBorrowRate = vars.nextVariableRate.toUint128();

        emit IPool.ReserveDataUpdated(
            reserveAddress,
            vars.nextLiquidityRate,
            vars.nextVariableRate,
            reserveCache.nextLiquidityIndex,
            reserveCache.nextVariableBorrowIndex
        );
    }

    struct AccrueToTreasuryLocalVars {
        uint256 prevTotalVariableDebt;
        uint256 currTotalVariableDebt;
        uint256 totalDebtAccrued;
        uint256 amountToMint;
    }

    /**
     * @notice Mints part of the repaid interest to the reserve treasury as a function of the reserve factor for the
     * specific asset.
     * @param reserve The reserve to be updated
     * @param reserveCache The caching layer for the reserve data
     */
    function _accrueToTreasury(DataTypes.ReserveData storage reserve, DataTypes.ReserveCache memory reserveCache)
        internal
    {
        AccrueToTreasuryLocalVars memory vars;

        if (reserveCache.reserveFactor == 0) {
            return;
        }

        //calculate the total variable debt at moment of the last interaction
        vars.prevTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(reserveCache.currVariableBorrowIndex);

        //calculate the new total variable debt after accumulation of the interest on the index
        vars.currTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(reserveCache.nextVariableBorrowIndex);

        //debt accrued is the sum of the current debt minus the sum of the debt at the last update
        vars.totalDebtAccrued = vars.currTotalVariableDebt - vars.prevTotalVariableDebt;

        vars.amountToMint = vars.totalDebtAccrued.percentMul(reserveCache.reserveFactor);

        if (vars.amountToMint != 0) {
            reserve.accruedToTreasury += vars.amountToMint.rayDiv(reserveCache.nextLiquidityIndex).toUint128();
        }
    }

    /**
     * @notice Updates the reserve indexes and the timestamp of the update.
     * @param reserve The reserve reserve to be updated
     * @param reserveCache The cache layer holding the cached protocol data
     */
    function _updateIndexes(DataTypes.ReserveData storage reserve, DataTypes.ReserveCache memory reserveCache)
        internal
    {
        // Only cumulating on the supply side if there is any income being produced
        // The case of Reserve Factor 100% is not a problem (currentLiquidityRate == 0),
        // as liquidity index should not be updated
        if (reserveCache.currLiquidityRate != 0) {
            uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
                reserveCache.currLiquidityRate, reserveCache.reserveLastUpdateTimestamp
            );
            reserveCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(reserveCache.currLiquidityIndex);
            reserve.liquidityIndex = reserveCache.nextLiquidityIndex.toUint128();
        }

        // Variable borrow index only gets updated if there is any variable debt.
        // reserveCache.currVariableBorrowRate != 0 is not a correct validation,
        // because a positive base variable rate can be stored on
        // reserveCache.currVariableBorrowRate, but the index should not increase
        if (reserveCache.currScaledVariableDebt != 0) {
            uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
                reserveCache.currVariableBorrowRate, reserveCache.reserveLastUpdateTimestamp
            );
            reserveCache.nextVariableBorrowIndex =
                cumulatedVariableBorrowInterest.rayMul(reserveCache.currVariableBorrowIndex);
            reserve.variableBorrowIndex = reserveCache.nextVariableBorrowIndex.toUint128();
        }
    }

    /**
     * @notice Creates a cache object to avoid repeated storage reads and external contract calls when updating state and
     * interest rates.
     * @param reserve The reserve object for which the cache will be filled
     * @return The cache object
     */
    function cache(DataTypes.ReserveData storage reserve) internal view returns (DataTypes.ReserveCache memory) {
        DataTypes.ReserveCache memory reserveCache;

        reserveCache.reserveConfiguration = reserve.configuration;
        reserveCache.reserveFactor = reserveCache.reserveConfiguration.getReserveFactor();
        reserveCache.currLiquidityIndex = reserveCache.nextLiquidityIndex = reserve.liquidityIndex;
        reserveCache.currVariableBorrowIndex = reserveCache.nextVariableBorrowIndex = reserve.variableBorrowIndex;
        reserveCache.currLiquidityRate = reserve.currentLiquidityRate;
        reserveCache.currVariableBorrowRate = reserve.currentVariableBorrowRate;

        reserveCache.yTokenAddress = reserve.yTokenAddress;
        reserveCache.variableDebtTokenAddress = reserve.variableDebtTokenAddress;

        reserveCache.reserveLastUpdateTimestamp = reserve.lastUpdateTimestamp;

        reserveCache.currScaledVariableDebt = reserveCache.nextScaledVariableDebt =
            IVariableDebtToken(reserveCache.variableDebtTokenAddress).scaledTotalSupply();

        return reserveCache;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IScaledBalanceToken
 *
 * @notice Defines the basic interface for a scaled-balance token.
 */
interface IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted tokens
     * @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
     * @param balanceIncrease The increase in scaled-up balance since the last action of 'onBehalfOf'
     * @param index The next liquidity index of the reserve
     */
    event Mint(
        address indexed caller, address indexed onBehalfOf, uint256 value, uint256 balanceIncrease, uint256 index
    );

    /**
     * @dev Emitted after the burn action
     * @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
     * @param from The address from which the tokens will be burned
     * @param target The address that will receive the underlying, if any
     * @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
     * @param balanceIncrease The increase in scaled-up balance since the last action of 'from'
     * @param index The next liquidity index of the reserve
     */
    event Burn(address indexed from, address indexed target, uint256 value, uint256 balanceIncrease, uint256 index);

    /**
     * @notice Returns the scaled balance of the user.
     * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
     * at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     */
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled total supply
     */
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
     * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
     * @return The scaled total supply
     */
    function scaledTotalSupply() external view returns (uint256);

    /**
     * @notice Returns last index interest was accrued to the user's balance
     * @param user The address of the user
     * @return The last index interest was accrued to the user's balance, expressed in ray
     */
    function getPreviousIndex(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPool} from "./IPool.sol";

/**
 * @title IInitializableYToken
 *
 * @notice Interface for the initialize function on YToken
 */
interface IInitializableYToken {
    /**
     * @dev Emitted when an yToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this yToken
     * @param yTokenDecimals The decimals of the underlying
     * @param yTokenName The name of the yToken
     * @param yTokenSymbol The symbol of the yToken
     * @param params A set of encoded parameters for additional initialization
     */
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 yTokenDecimals,
        string yTokenName,
        string yTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes yToken
     * @param initializingPool The pool contract that is initializing this contract
     * @param treasury The address of the YLDR treasury, receiving the fees on this yToken
     * @param underlyingAsset The address of the underlying asset of this yToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param yTokenDecimals The decimals of the yToken, same as the underlying asset's
     * @param yTokenName The name of the yToken
     * @param yTokenSymbol The symbol of the yToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool initializingPool,
        address treasury,
        address underlyingAsset,
        address incentivesController,
        uint8 yTokenDecimals,
        string memory yTokenName,
        string memory yTokenSymbol,
        bytes memory params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC1155Supply} from "./IERC1155Supply.sol";

/**
 * @title INToken
 *
 * @notice Defines the basic interface for an NToken.
 */
interface INToken is IERC1155Supply {
    /**
     * @dev Emitted when an yToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param params A set of encoded parameters for additional initialization
     */
    event Initialized(address indexed underlyingAsset, address indexed pool, address treasury, bytes params);

    /**
     * @notice Initializes the nToken
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this nToken (E.g. WETH for aWETH)
     * @param treasury The address of the treasury
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(address pool, address underlyingAsset, address treasury, bytes memory params) external;

    /**
     * @notice Mints `tokenId` nToken to `onBehalfOf`
     * @param onBehalfOf The address of the user that will receive the minted nToken
     * @param tokenId The tokenId getting minted
     * @param amount The amount getting minted
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(address onBehalfOf, uint256 tokenId, uint256 amount) external returns (bool);

    /**
     * @notice Burns nToken from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param from The address from which the nToken will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param tokenId The tokenId being burned
     * @param amount The amount being burned
     */
    function burn(address from, address receiverOfUnderlying, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Returns the address of the underlying asset of this nToken
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the address of the YLDR treasury, receiving the fees on this nToken.
     * @return Address of the YLDR treasury
     */
    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    /**
     * @notice Transfers nTokens in the event of a borrow being liquidated, in case the liquidators reclaims the nToken
     * @param from The address getting liquidated, current owner of the nTokens
     * @param to The recipient
     * @param tokenId The tokenId of tokens getting transferred
     * @param amount The amount of underlying tokens getting transferred
     * @param data Additional data with no specified format
     */
    function safeTransferFromOnLiquidation(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IReserveInterestRateStrategy
 *
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
    /**
     * @notice Calculates the interest rates depending on the reserve's state and configurations
     * @param params The parameters needed to calculate interest rates
     * @return liquidityRate The liquidity rate expressed in rays
     * @return variableBorrowRate The variable borrow rate expressed in rays
     */
    function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 *
 * @notice Interface for the YLDR price oracle.
 */
interface IPriceOracleGetter {
    /**
     * @notice Returns the base currency address
     * @dev Address 0x0 is reserved for USD as base currency.
     * @return Returns the base currency address.
     */
    function BASE_CURRENCY() external view returns (address);

    /**
     * @notice Returns the base currency unit
     * @dev 1 ether for ETH, 1e8 for USD.
     * @return Returns the base currency unit.
     */
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    /**
     * @notice Returns the asset price in the base currency
     * @param asset The address of the asset
     * @return The price of the asset
     */
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice Returns the ERC1155 asset price in the base currency
     * It returns the price of totalSupply of given tokenId. To calculate partial amount, use price * shares / totalSupply
     * @param asset The address of the asset
     * @param tokenId The tokenId of the asset
     * @return The price of the asset
     */
    function getERC1155AssetPrice(address asset, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IPriceOracleSentinel
 *
 * @notice Defines the basic interface for the PriceOracleSentinel
 */
interface IPriceOracleSentinel {
    /**
     * @dev Emitted after the sequencer oracle is updated
     * @param newSequencerOracle The new sequencer oracle
     */
    event SequencerOracleUpdated(address newSequencerOracle);

    /**
     * @dev Emitted after the grace period is updated
     * @param newGracePeriod The new grace period value
     */
    event GracePeriodUpdated(uint256 newGracePeriod);

    /**
     * @notice Returns the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Returns true if the `borrow` operation is allowed.
     * @dev Operation not allowed when PriceOracle is down or grace period not passed.
     * @return True if the `borrow` operation is allowed, false otherwise.
     */
    function isBorrowAllowed() external view returns (bool);

    /**
     * @notice Returns true if the `liquidation` operation is allowed.
     * @dev Operation not allowed when PriceOracle is down or grace period not passed.
     * @return True if the `liquidation` operation is allowed, false otherwise.
     */
    function isLiquidationAllowed() external view returns (bool);

    /**
     * @notice Updates the address of the sequencer oracle
     * @param newSequencerOracle The address of the new Sequencer Oracle to use
     */
    function setSequencerOracle(address newSequencerOracle) external;

    /**
     * @notice Updates the duration of the grace period
     * @param newGracePeriod The value of the new grace period duration
     */
    function setGracePeriod(uint256 newGracePeriod) external;

    /**
     * @notice Returns the SequencerOracle
     * @return The address of the sequencer oracle contract
     */
    function getSequencerOracle() external view returns (address);

    /**
     * @notice Returns the grace period
     * @return The duration of the grace period
     */
    function getGracePeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveConfiguration} from "./ReserveConfiguration.sol";

/**
 * @title UserConfiguration library
 *
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserERC1155Configuration {
    /**
     * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
     * @param self The configuration object
     * @param asset Address of the ERC1155 asset
     * @param tokenId The id of token enabled
     * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
     */
    function setUsingAsCollateral(
        DataTypes.UserERC1155ConfigurationMap storage self,
        address asset,
        uint256 tokenId,
        bool usingAsCollateral
    ) internal {
        if (usingAsCollateral) {
            self.usedERC1155Reserves.push(DataTypes.ERC1155ReserveUsageData({asset: asset, tokenId: tokenId}));
            self.usedERC1155ReservesMap[asset][tokenId] = self.usedERC1155Reserves.length;
        } else {
            // This will cause underflow for non-existent reserves
            uint256 index = self.usedERC1155ReservesMap[asset][tokenId] - 1;

            delete self.usedERC1155ReservesMap[asset][tokenId];
            uint256 lastIndex = self.usedERC1155Reserves.length - 1;

            if (lastIndex == index) {
                self.usedERC1155Reserves.pop();
                return;
            } else {
                DataTypes.ERC1155ReserveUsageData memory lastReserve = self.usedERC1155Reserves[lastIndex];
                self.usedERC1155Reserves[index] = lastReserve;
                self.usedERC1155Reserves.pop();
                self.usedERC1155ReservesMap[lastReserve.asset][lastReserve.tokenId] = index + 1;
            }
        }
    }

    /**
     * @notice Checks if a user has been supplying any reserve as collateral
     * @param self The configuration object
     * @return True if the user has been supplying as collateral any reserve, false otherwise
     */
    function isUsingAsCollateralAny(DataTypes.UserERC1155ConfigurationMap storage self) internal view returns (bool) {
        return self.usedERC1155Reserves.length > 0;
    }

    /**
     * @notice Checks if a user is using as collateral a specific reserve
     * @param self The configuration object
     * @param asset The address of the reserve
     * @param tokenId The tokenId of reserve
     * @return True if the user is using the reserve as collateral, false otherwise
     */
    function isUsingAsCollateral(DataTypes.UserERC1155ConfigurationMap storage self, address asset, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return self.usedERC1155ReservesMap[asset][tokenId] > 0;
    }

    /**
     * @notice Returns count of the reserves used as collateral by the user
     * @param self The configuration object
     * @return The number of reserves used as collateral
     */
    function getUsedReservesCount(DataTypes.UserERC1155ConfigurationMap storage self) internal view returns (uint256) {
        return self.usedERC1155Reserves.length;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155Supply} from "../../../interfaces/IERC1155Supply.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {ERC1155ReserveLogic} from "./ERC1155ReserveLogic.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {UserERC1155Configuration} from "../configuration/UserERC1155Configuration.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title GenericLogic library
 *
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using UserERC1155Configuration for DataTypes.UserERC1155ConfigurationMap;
    using ERC1155ReserveLogic for DataTypes.ERC1155ReserveData;

    struct CalculateUserAccountDataVars {
        uint256 assetPrice;
        uint256 assetUnit;
        uint256 userBalanceInBaseCurrency;
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 i;
        uint256 healthFactor;
        uint256 totalCollateralInBaseCurrency;
        uint256 totalDebtInBaseCurrency;
        uint256 avgLtv;
        uint256 avgLiquidationThreshold;
        address currentReserveAddress;
        uint256 currentReserveTokenId;
        bool hasZeroLtvCollateral;
        DataTypes.ERC1155ReserveConfiguration currentReserveConfig;
    }

    /**
     * @notice Calculates the user data across the reserves.
     * @dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
     * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for the calculation
     * @return The total collateral of the user in the base currency used by the price feed
     * @return The total debt of the user in the base currency used by the price feed
     * @return The average ltv of the user
     * @return The average liquidation threshold of the user
     * @return The health factor of the user
     * @return True if the ltv is zero, false otherwise
     */
    function calculateUserAccountData(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.CalculateUserAccountDataParams memory params
    ) internal view returns (uint256, uint256, uint256, uint256, uint256, bool) {
        if (params.userConfig.isEmpty() && !userERC1155Config.isUsingAsCollateralAny()) {
            return (0, 0, 0, 0, type(uint256).max, false);
        }

        CalculateUserAccountDataVars memory vars;

        while (vars.i < params.reservesCount) {
            if (!params.userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            vars.currentReserveAddress = reservesList[vars.i];

            if (vars.currentReserveAddress == address(0)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            DataTypes.ReserveData storage currentReserve = reservesData[vars.currentReserveAddress];

            (vars.ltv, vars.liquidationThreshold,, vars.decimals,) = currentReserve.configuration.getParams();

            unchecked {
                vars.assetUnit = 10 ** vars.decimals;
            }

            vars.assetPrice = IPriceOracleGetter(params.oracle).getAssetPrice(vars.currentReserveAddress);

            if (vars.liquidationThreshold != 0 && params.userConfig.isUsingAsCollateral(vars.i)) {
                vars.userBalanceInBaseCurrency =
                    _getUserBalanceInBaseCurrency(params.user, currentReserve, vars.assetPrice, vars.assetUnit);

                vars.totalCollateralInBaseCurrency += vars.userBalanceInBaseCurrency;

                if (vars.ltv != 0) {
                    vars.avgLtv += vars.userBalanceInBaseCurrency * vars.ltv;
                } else {
                    vars.hasZeroLtvCollateral = true;
                }

                vars.avgLiquidationThreshold += vars.userBalanceInBaseCurrency * vars.liquidationThreshold;
            }

            if (params.userConfig.isBorrowing(vars.i)) {
                vars.totalDebtInBaseCurrency +=
                    _getUserDebtInBaseCurrency(params.user, currentReserve, vars.assetPrice, vars.assetUnit);
            }

            unchecked {
                ++vars.i;
            }
        }

        for (vars.i = 0; vars.i < userERC1155Config.usedERC1155Reserves.length; vars.i++) {
            vars.currentReserveAddress = userERC1155Config.usedERC1155Reserves[vars.i].asset;
            vars.currentReserveTokenId = userERC1155Config.usedERC1155Reserves[vars.i].tokenId;

            DataTypes.ERC1155ReserveData storage currentReserve = erc1155ReservesData[vars.currentReserveAddress];
            vars.currentReserveConfig = currentReserve.getConfiguration(vars.currentReserveTokenId);

            vars.assetPrice = IPriceOracleGetter(params.oracle).getERC1155AssetPrice(
                vars.currentReserveAddress, vars.currentReserveTokenId
            );

            vars.liquidationThreshold = vars.currentReserveConfig.liquidationThreshold;
            vars.ltv = vars.currentReserveConfig.ltv;

            if (vars.liquidationThreshold != 0) {
                vars.userBalanceInBaseCurrency = INToken(currentReserve.nTokenAddress).balanceOf(
                    params.user, vars.currentReserveTokenId
                ) * vars.assetPrice / IERC1155Supply(vars.currentReserveAddress).totalSupply(vars.currentReserveTokenId);

                vars.totalCollateralInBaseCurrency += vars.userBalanceInBaseCurrency;

                if (vars.ltv != 0) {
                    vars.avgLtv += vars.userBalanceInBaseCurrency * vars.ltv;
                } else {
                    vars.hasZeroLtvCollateral = true;
                }

                vars.avgLiquidationThreshold += vars.userBalanceInBaseCurrency * vars.liquidationThreshold;
            }
        }

        unchecked {
            vars.avgLtv = vars.totalCollateralInBaseCurrency != 0 ? vars.avgLtv / vars.totalCollateralInBaseCurrency : 0;
            vars.avgLiquidationThreshold = vars.totalCollateralInBaseCurrency != 0
                ? vars.avgLiquidationThreshold / vars.totalCollateralInBaseCurrency
                : 0;
        }

        vars.healthFactor = (vars.totalDebtInBaseCurrency == 0)
            ? type(uint256).max
            : (vars.totalCollateralInBaseCurrency.percentMul(vars.avgLiquidationThreshold)).wadDiv(
                vars.totalDebtInBaseCurrency
            );
        return (
            vars.totalCollateralInBaseCurrency,
            vars.totalDebtInBaseCurrency,
            vars.avgLtv,
            vars.avgLiquidationThreshold,
            vars.healthFactor,
            vars.hasZeroLtvCollateral
        );
    }

    /**
     * @notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
     * and the average Loan To Value
     * @param totalCollateralInBaseCurrency The total collateral in the base currency used by the price feed
     * @param totalDebtInBaseCurrency The total borrow balance in the base currency used by the price feed
     * @param ltv The average loan to value
     * @return The amount available to borrow in the base currency of the used by the price feed
     */
    function calculateAvailableBorrows(
        uint256 totalCollateralInBaseCurrency,
        uint256 totalDebtInBaseCurrency,
        uint256 ltv
    ) internal pure returns (uint256) {
        uint256 availableBorrowsInBaseCurrency = totalCollateralInBaseCurrency.percentMul(ltv);

        if (availableBorrowsInBaseCurrency < totalDebtInBaseCurrency) {
            return 0;
        }

        availableBorrowsInBaseCurrency = availableBorrowsInBaseCurrency - totalDebtInBaseCurrency;
        return availableBorrowsInBaseCurrency;
    }

    /**
     * @notice Calculates total debt of the user in the based currency used to normalize the values of the assets
     * @dev This fetches the `balanceOf` of the variable debt tokens for the user. For gas reasons, the
     * variable debt balance is calculated by fetching `scaledBalancesOf` normalized debt, which is cheaper than
     * fetching `balanceOf`
     * @param user The address of the user
     * @param reserve The data of the reserve for which the total debt of the user is being calculated
     * @param assetPrice The price of the asset for which the total debt of the user is being calculated
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total debt of the user normalized to the base currency
     */
    function _getUserDebtInBaseCurrency(
        address user,
        DataTypes.ReserveData storage reserve,
        uint256 assetPrice,
        uint256 assetUnit
    ) private view returns (uint256) {
        // fetching variable debt
        uint256 userTotalDebt = IScaledBalanceToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
        if (userTotalDebt != 0) {
            userTotalDebt = userTotalDebt.rayMul(reserve.getNormalizedDebt());
        }

        userTotalDebt = assetPrice * userTotalDebt;

        unchecked {
            return userTotalDebt / assetUnit;
        }
    }

    /**
     * @notice Calculates total yToken balance of the user in the based currency used by the price oracle
     * @dev For gas reasons, the yToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
     * is cheaper than fetching `balanceOf`
     * @param user The address of the user
     * @param reserve The data of the reserve for which the total yToken balance of the user is being calculated
     * @param assetPrice The price of the asset for which the total yToken balance of the user is being calculated
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total yToken balance of the user normalized to the base currency of the price oracle
     */
    function _getUserBalanceInBaseCurrency(
        address user,
        DataTypes.ReserveData storage reserve,
        uint256 assetPrice,
        uint256 assetUnit
    ) private view returns (uint256) {
        uint256 normalizedIncome = reserve.getNormalizedIncome();
        uint256 balance =
            (IScaledBalanceToken(reserve.yTokenAddress).scaledBalanceOf(user).rayMul(normalizedIncome)) * assetPrice;

        unchecked {
            return balance / assetUnit;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {IYLDRIncentivesController} from "../../../interfaces/IYLDRIncentivesController.sol";
import {IPoolAddressesProvider} from "../../../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {IACLManager} from "../../../interfaces/IACLManager.sol";

/**
 * @title IncentivizedERC20
 * , inspired by the Openzeppelin ERC20 implementation
 * @notice Basic ERC20 implementation
 */
abstract contract IncentivizedERC20 is Context, IERC20Metadata {
    using WadRayMath for uint256;
    using SafeCast for uint256;

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     */
    modifier onlyPoolAdmin() {
        IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
        require(aclManager.isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
        _;
    }

    /**
     * @dev Only pool can call functions marked by this modifier.
     */
    modifier onlyPool() {
        require(_msgSender() == address(POOL), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    /**
     * @dev UserState - additionalData is a flexible field.
     * YTokens and VariableDebtTokens use this field store the index of the
     * user's last supply/withdrawal/borrow/repayment.
     */
    struct UserState {
        uint128 balance;
        uint128 additionalData;
    }
    // Map of users address and their state data (userAddress => userStateData)

    mapping(address => UserState) internal _userState;

    // Map of allowances (delegator => delegatee => allowanceAmount)
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    IYLDRIncentivesController internal _incentivesController;
    IPoolAddressesProvider internal immutable _addressesProvider;
    IPool public immutable POOL;

    /**
     * @dev Constructor.
     * @param pool The reference to the main Pool contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     */
    constructor(IPool pool, string memory name, string memory symbol, uint8 decimals) {
        _addressesProvider = pool.ADDRESSES_PROVIDER();
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        POOL = pool;
    }

    /// @inheritdoc IERC20Metadata
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20Metadata
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _userState[account].balance;
    }

    /**
     * @notice Returns the address of the Incentives Controller contract
     * @return The address of the Incentives Controller
     */
    function getIncentivesController() external view virtual returns (IYLDRIncentivesController) {
        return _incentivesController;
    }

    /**
     * @notice Sets a new Incentives Controller
     * @param controller the new Incentives controller
     */
    function setIncentivesController(IYLDRIncentivesController controller) external onlyPoolAdmin {
        _incentivesController = controller;
    }

    /// @inheritdoc IERC20
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        uint128 castAmount = amount.toUint128();
        _transfer(_msgSender(), recipient, castAmount);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        uint128 castAmount = amount.toUint128();
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - castAmount);
        _transfer(sender, recipient, castAmount);
        return true;
    }

    /**
     * @notice Increases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     * @return `true`
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @notice Decreases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param subtractedValue The amount being subtracted to the allowance
     * @return `true`
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    /**
     * @notice Transfers tokens between two users and apply incentives if defined.
     * @param sender The source address
     * @param recipient The destination address
     * @param amount The amount getting transferred
     */
    function _transfer(address sender, address recipient, uint128 amount) internal virtual {
        uint128 oldSenderBalance = _userState[sender].balance;
        _userState[sender].balance = oldSenderBalance - amount;
        uint128 oldRecipientBalance = _userState[recipient].balance;
        _userState[recipient].balance = oldRecipientBalance + amount;

        IYLDRIncentivesController incentivesControllerLocal = _incentivesController;
        if (address(incentivesControllerLocal) != address(0)) {
            uint256 currentTotalSupply = _totalSupply;
            incentivesControllerLocal.handleAction(sender, currentTotalSupply, oldSenderBalance);
            if (sender != recipient) {
                incentivesControllerLocal.handleAction(recipient, currentTotalSupply, oldRecipientBalance);
            }
        }
    }

    /**
     * @notice Approve `spender` to use `amount` of `owner`s balance
     * @param owner The address owning the tokens
     * @param spender The address approved for spending
     * @param amount The amount of tokens to approve spending of
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Update the name of the token
     * @param newName The new name for the token
     */
    function _setName(string memory newName) internal {
        _name = newName;
    }

    /**
     * @notice Update the symbol for the token
     * @param newSymbol The new symbol for the token
     */
    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    /**
     * @notice Update the number of decimals for the token
     * @param newDecimals The new number of decimals for the token
     */
    function _setDecimals(uint8 newDecimals) internal {
        _decimals = newDecimals;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";

/**
 * @title IVariableDebtToken
 *
 * @notice Defines the basic interface for a variable debt token.
 */
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
    /**
     * @notice Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return True if the previous balance of the user is 0, false otherwise
     * @return The scaled total debt of the reserve
     */
    function mint(address user, address onBehalfOf, uint256 amount, uint256 index) external returns (bool, uint256);

    /**
     * @notice Burns user variable debt
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the debt will be burned
     * @param amount The amount getting burned
     * @param index The variable debt index of the reserve
     * @return The scaled total debt of the reserve
     */
    function burn(address from, uint256 amount, uint256 index) external returns (uint256);

    /**
     * @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title Helpers library
 *
 */
library Helpers {
    /**
     * @notice Fetches the user current variable debt balance
     * @param user The user address
     * @param reserveCache The reserve cache data object
     * @return The variable debt balance
     */
    function getUserCurrentDebt(address user, DataTypes.ReserveCache memory reserveCache)
        internal
        view
        returns (uint256)
    {
        return IERC20(reserveCache.variableDebtTokenAddress).balanceOf(user);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {WadRayMath} from "./WadRayMath.sol";

/**
 * @title MathUtils library
 *
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     */
    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
        //solium-disable-next-line
        uint256 result = rate * (block.timestamp - uint256(lastUpdateTimestamp));
        unchecked {
            result = result / SECONDS_PER_YEAR;
        }

        return WadRayMath.RAY + result;
    }

    /**
     * @dev Function to calculate the interest using a compounded interest rate formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     *
     *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     *
     * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
     * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
     * error per different time periods
     *
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate compounded during the timeDelta, in ray
     */
    function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp, uint256 currentTimestamp)
        internal
        pure
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

        if (exp == 0) {
            return WadRayMath.RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo = rate.rayMul(rate) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
            basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return WadRayMath.RAY + (rate * exp) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
    }

    /**
     * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
     * @param rate The interest rate (in ray)
     * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
     * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
     */
    function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
        return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
    }
}

pragma solidity ^0.8.20;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Supply is IERC1155 {
    /**
     * @dev Total value of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Total value of tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155ConfigurationProvider} from "../../../interfaces/IERC1155ConfigurationProvider.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title ERC1155ReserveLogic library
 *
 * @notice Implements the logic to update ERC1155 reserves state
 */
library ERC1155ReserveLogic {
    using ERC1155ReserveLogic for DataTypes.ERC1155ReserveData;

    function getConfiguration(DataTypes.ERC1155ReserveData storage erc1155Reserve, uint256 tokenId)
        internal
        view
        returns (DataTypes.ERC1155ReserveConfiguration memory)
    {
        return IERC1155ConfigurationProvider(erc1155Reserve.configurationProvider).getERC1155ReserveConfig(tokenId);
    }

    /**
     * @notice Initializes a reserve.
     * @param reserve The reserve object
     * @param nTokenAddress The address of the overlying ntoken contract
     * @param configurationProvider The address of the configuration provider
     */
    function init(DataTypes.ERC1155ReserveData storage reserve, address nTokenAddress, address configurationProvider)
        internal
    {
        require(reserve.nTokenAddress == address(0), Errors.RESERVE_ALREADY_INITIALIZED);

        reserve.configurationProvider = configurationProvider;
        reserve.nTokenAddress = nTokenAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IYLDRIncentivesController
 *
 * @notice Defines the basic interface for an YLDR Incentives Controller.
 * @dev It only contains one single function, needed as a hook on yToken and debtToken transfers.
 */
interface IYLDRIncentivesController {
    /**
     * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
     * @dev The units of `totalSupply` and `userBalance` should be the same.
     * @param user The address of the user whose asset balance has changed
     * @param totalSupply The total supply of the asset prior to user balance change
     * @param userBalance The previous user balance prior to balance change
     */
    function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IACLManager
 *
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
    /**
     * @notice Returns the contract address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Returns the identifier of the PoolAdmin role
     * @return The id of the PoolAdmin role
     */
    function POOL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the RiskAdmin role
     * @return The id of the RiskAdmin role
     */
    function RISK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the FlashBorrower role
     * @return The id of the FlashBorrower role
     */
    function FLASH_BORROWER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the AssetListingAdmin role
     * @return The id of the AssetListingAdmin role
     */
    function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as PoolAdmin
     * @param admin The address of the new admin
     */
    function addPoolAdmin(address admin) external;

    /**
     * @notice Removes an admin as PoolAdmin
     * @param admin The address of the admin to remove
     */
    function removePoolAdmin(address admin) external;

    /**
     * @notice Returns true if the address is PoolAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is PoolAdmin, false otherwise
     */
    function isPoolAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as RiskAdmin
     * @param admin The address of the new admin
     */
    function addRiskAdmin(address admin) external;

    /**
     * @notice Removes an admin as RiskAdmin
     * @param admin The address of the admin to remove
     */
    function removeRiskAdmin(address admin) external;

    /**
     * @notice Returns true if the address is RiskAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is RiskAdmin, false otherwise
     */
    function isRiskAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new address as FlashBorrower
     * @param borrower The address of the new FlashBorrower
     */
    function addFlashBorrower(address borrower) external;

    /**
     * @notice Removes an address as FlashBorrower
     * @param borrower The address of the FlashBorrower to remove
     */
    function removeFlashBorrower(address borrower) external;

    /**
     * @notice Returns true if the address is FlashBorrower, false otherwise
     * @param borrower The address to check
     * @return True if the given address is FlashBorrower, false otherwise
     */
    function isFlashBorrower(address borrower) external view returns (bool);

    /**
     * @notice Adds a new admin as AssetListingAdmin
     * @param admin The address of the new admin
     */
    function addAssetListingAdmin(address admin) external;

    /**
     * @notice Removes an admin as AssetListingAdmin
     * @param admin The address of the admin to remove
     */
    function removeAssetListingAdmin(address admin) external;

    /**
     * @notice Returns true if the address is AssetListingAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is AssetListingAdmin, false otherwise
     */
    function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPool} from "./IPool.sol";

/**
 * @title IInitializableDebtToken
 *
 * @notice Interface for the initialize function common between debt tokens
 */
interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param incentivesController The address of the incentives controller for this yToken
     * @param debtTokenDecimals The decimals of the debt token
     * @param debtTokenName The name of the debt token
     * @param debtTokenSymbol The symbol of the debt token
     * @param params A set of encoded parameters for additional initialization
     */
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address incentivesController,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the debt token.
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this yToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address underlyingAsset,
        address incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.20;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

interface IERC1155ConfigurationProvider {
    function getERC1155ReserveConfig(uint256 tokenId)
        external
        view
        returns (DataTypes.ERC1155ReserveConfiguration memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}