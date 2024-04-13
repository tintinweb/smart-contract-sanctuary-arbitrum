// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMarginForUpgradeable } from "./OnlyDolomiteMarginForUpgradeable.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   OnlyDolomiteMargin
 * @author  Dolomite
 *
 * @notice  Inheritable contract that restricts the calling of certain functions to `DolomiteMargin`, the owner of
 *          `DolomiteMargin` or a `DolomiteMargin` global operator
 */
abstract contract OnlyDolomiteMargin is OnlyDolomiteMarginForUpgradeable {

    // ============ Constants ============

    bytes32 private constant _FILE = "OnlyDolomiteMargin";

    // ============ Storage ============

    IDolomiteMargin private immutable _DOLOMITE_MARGIN; // solhint-disable-line var-name-mixedcase

    // ============ Constructor ============

    constructor (address _dolomiteMargin) {
        _DOLOMITE_MARGIN = IDolomiteMargin(_dolomiteMargin);
    }

    // ============ Functions ============

    function DOLOMITE_MARGIN() public override view returns (IDolomiteMargin) {
        return _DOLOMITE_MARGIN;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { ProxyContractHelpers } from "./ProxyContractHelpers.sol";
import { IOnlyDolomiteMargin } from "../interfaces/IOnlyDolomiteMargin.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { Require } from "../protocol/lib/Require.sol";


/**
 * @title   OnlyDolomiteMarginForUpgradeable
 * @author  Dolomite
 *
 * @notice  Inheritable contract that restricts the calling of certain functions to `DolomiteMargin`, the owner of
 *          `DolomiteMargin` or a `DolomiteMargin` global operator
 */
abstract contract OnlyDolomiteMarginForUpgradeable is IOnlyDolomiteMargin, ProxyContractHelpers {

    // ============ Constants ============

    bytes32 private constant _FILE = "OnlyDolomiteMargin";
    bytes32 private constant _DOLOMITE_MARGIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.dolomiteMargin")) - 1);

    // ============ Modifiers ============

    modifier onlyDolomiteMargin(address _from) {
        Require.that(
            _from == address(DOLOMITE_MARGIN()),
            _FILE,
            "Only Dolomite can call function",
            _from
        );
        _;
    }

    modifier onlyDolomiteMarginOwner(address _from) {
        Require.that(
            _from == DOLOMITE_MARGIN().owner(),
            _FILE,
            "Caller is not owner of Dolomite",
            _from
        );
        _;
    }

    modifier onlyDolomiteMarginGlobalOperator(address _from) {
        Require.that(
            DOLOMITE_MARGIN().getIsGlobalOperator(_from),
            _FILE,
            "Caller is not a global operator",
            _from
        );
        _;
    }

    // ============ Functions ============

    function DOLOMITE_MARGIN() public virtual view returns (IDolomiteMargin) {
        return IDolomiteMargin(_getAddress(_DOLOMITE_MARGIN_SLOT));
    }

    function _setDolomiteMarginViaSlot(address _dolomiteMargin) internal {
        _setAddress(_DOLOMITE_MARGIN_SLOT, _dolomiteMargin);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   ProxyContractHelpers
 * @author  Dolomite
 *
 * @notice  Helper functions for upgradeable proxy contracts to use
 */
abstract contract ProxyContractHelpers {

    // ================ Internal Functions ==================

    function _callImplementation(address _implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _setAddress(bytes32 slot, address _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function _setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function _getAddress(bytes32 slot) internal view returns (address value) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }

    function _getUint256(bytes32 slot) internal view returns (uint256 value) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IAuthorizationBase
 * @author  Dolomite
 *
 * @notice  Interface for allowing only trusted callers to invoke functions that use the `requireIsCallerAuthorized`
 *          modifier.
 */
interface IAuthorizationBase {

    function setIsCallerAuthorized(address _caller, bool _isAuthorized) external;

    function isCallerAuthorized(address _caller) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { AccountBalanceLib } from "../lib/AccountBalanceLib.sol";


/**
 * @title   IBorrowPositionProxyV1
 * @author  Dolomite
 *
 * @notice  Interface for allowing the transfer of assets between account numbers. Emits an event to allow for easy
 *          indexing of a subgraph for getting active borrow positions.
 */
interface IBorrowPositionProxyV1 {

    // ========================= Events =========================

    event BorrowPositionOpen(address indexed _borrower, uint256 indexed _borrowAccountNumber);

    // ========================= Functions =========================

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be sourcing the deposit
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing
     * @param  _collateralMarketId  The ID of the market being deposited
     * @param  _amountWei           The amount, in Wei, to deposit
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function openBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  This method can only be called once the user's debt has been reduced to zero. Sends all
     *          `_collateralMarketIds` from `_borrowAccountNumber` to `_toAccountNumber`.
     *
     * @param  _borrowAccountNumber The index from which `msg.sender` collateral will be withdrawn
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing leftover collateral
     * @param  _collateralMarketIds The IDs of the markets being withdrawn, to close the position
     */
    function closeBorrowPosition(
        uint256 _borrowAccountNumber,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be withdrawing assets
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _amountWei           The amount, in Wei, to transfer
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function transferBetweenAccounts(
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     *
     * @param  _fromAccountNumber   The index from which `msg.sender` will be depositing assets
     * @param  _borrowAccountNumber The index of the borrow position for that will receive the deposited assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_borrowAccountNumber`, or both accounts
     *                              can go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function repayAllForBorrowPosition(
        uint256 _fromAccountNumber,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IAuthorizationBase } from "./IAuthorizationBase.sol";
import { IBorrowPositionProxyV1 } from "./IBorrowPositionProxyV1.sol";
import { AccountBalanceLib } from "../lib/AccountBalanceLib.sol";


/**
 * @title   IBorrowPositionProxyV2
 * @author  Dolomite
 *
 * @notice  Interface for allowing only trusted callers to invoke borrow related functions for transferring funds
 *          between account owners.
 */
interface IBorrowPositionProxyV2 is IAuthorizationBase, IBorrowPositionProxyV1 {

    // ========================= Functions =========================

    /**
     *
     * @param  _fromAccountOwner    The account from which the user will be sourcing the deposit
     * @param  _fromAccountNumber   The index from which `_toAccountOwner` will be sourcing the deposit
     * @param  _toAccountOwner      The account into which `_fromAccountOwner` will be depositing
     * @param  _toAccountNumber     The index into which `_fromAccountOwner` will be depositing
     * @param  _collateralMarketId  The ID of the market being deposited
     * @param  _amountWei           The amount, in Wei, to deposit
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function openBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _collateralMarketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     * @notice  This method can only be called once the user's debt has been reduced to zero. Sends all
     *          `_collateralMarketIds` from `_borrowAccountNumber` to `_toAccountNumber`.
     *
     * @param  _borrowAccountOwner  The account from which collateral will be withdrawn
     * @param  _borrowAccountNumber The index from which `msg.sender` collateral will be withdrawn
     * @param  _toAccountOwner      The account into which `_borrowAccountOwner` will be depositing leftover collateral
     * @param  _toAccountNumber     The index into which `_borrowAccountOwner` will be depositing leftover collateral
     * @param  _collateralMarketIds The IDs of the markets being withdrawn, to close the position
     */
    function closeBorrowPositionWithDifferentAccounts(
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256[] calldata _collateralMarketIds
    ) external;

    /**
     *
     * @param  _fromAccountOwner    The account from which assets will be withdrawn
     * @param  _fromAccountNumber   The index from which `msg.sender` will be withdrawing assets
     * @param  _toAccountOwner      The account to which assets will be deposited
     * @param  _toAccountNumber     The index into which `msg.sender` will be depositing assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _amountWei           The amount, in Wei, to transfer
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_toAccountNumber`, or both accounts can
     *                              go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function transferBetweenAccountsWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;

    /**
     *
     * @param  _fromAccountOwner    The account from which assets will be withdrawn for repayment
     * @param  _fromAccountNumber   The index from which `msg.sender` will be depositing assets
     * @param  _borrowAccountOwner  The account of the borrow position that will receive the deposited assets
     * @param  _borrowAccountNumber The index of the borrow position for that will receive the deposited assets
     * @param  _marketId            The ID of the market being transferred
     * @param  _balanceCheckFlag    Flag used to check if `_fromAccountNumber`, `_borrowAccountNumber`, or both accounts
     *                              can go negative after the transfer settles. Setting the flag to
     *                              `AccountBalanceLib.BalanceCheckFlag.None=3` results in neither account being
     *                              checked.
     */
    function repayAllForBorrowPositionWithDifferentAccounts(
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _borrowAccountOwner,
        uint256 _borrowAccountNumber,
        uint256 _marketId,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IEventEmitterRegistry } from "./IEventEmitterRegistry.sol";
import { IExpiry } from "./IExpiry.sol";
import { IGenericTraderProxyV1 } from "./IGenericTraderProxyV1.sol";
import { ILiquidatorAssetRegistry } from "./ILiquidatorAssetRegistry.sol";
import { IDolomitePriceOracle } from "../protocol/interfaces/IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteRegistry
 * @author  Dolomite
 *
 * @notice  A registry contract for storing all of the addresses that can interact with Umami's Delta Neutral vaults
 */
interface IDolomiteRegistry {

    // ========================================================
    // ======================== Events ========================
    // ========================================================

    event GenericTraderProxySet(address indexed _genericTraderProxy);
    event ExpirySet(address indexed _expiry);
    event SlippageToleranceForPauseSentinelSet(uint256 _slippageTolerance);
    event LiquidatorAssetRegistrySet(address indexed _liquidatorAssetRegistry);
    event EventEmitterSet(address indexed _eventEmitter);
    event ChainlinkPriceOracleSet(address indexed _chainlinkPriceOracle);
    event RedstonePriceOracleSet(address indexed _redstonePriceOracle);
    event OracleAggregatorSet(address indexed _oracleAggregator);

    // ========================================================
    // =================== Admin Functions ====================
    // ========================================================

    /**
     *
     * @param  _genericTraderProxy  The new address of the generic trader proxy
     */
    function ownerSetGenericTraderProxy(address _genericTraderProxy) external;

    /**
     *
     * @param  _expiry  The new address of the expiry contract
     */
    function ownerSetExpiry(address _expiry) external;

    /**
     *
     * @param  _slippageToleranceForPauseSentinel   The slippage tolerance (using 1e18 as the base) for zaps when pauses
     *                                              are enabled
     */
    function ownerSetSlippageToleranceForPauseSentinel(uint256 _slippageToleranceForPauseSentinel) external;

    /**
     *
     * @param  _liquidatorRegistry  The new address of the liquidator registry
     */
    function ownerSetLiquidatorAssetRegistry(address _liquidatorRegistry) external;

    /**
     *
     * @param  _eventEmitter  The new address of the event emitter
     */
    function ownerSetEventEmitter(address _eventEmitter) external;

    /**
     *
     * @param  _chainlinkPriceOracle    The new address of the Chainlink price oracle that's compatible with
     *                                  DolomiteMargin.
     */
    function ownerSetChainlinkPriceOracle(address _chainlinkPriceOracle) external;

    /**
     *
     * @param  _redstonePriceOracle    The new address of the Redstone price oracle that's compatible with
     *                                  DolomiteMargin.
     */
    function ownerSetRedstonePriceOracle(address _redstonePriceOracle) external;

    /**
     *
     * @param  _oracleAggregator    The new address of the oracle aggregator that's compatible with
     *                              DolomiteMargin.
     */
    function ownerSetOracleAggregator(address _oracleAggregator) external;

    // ========================================================
    // =================== Getter Functions ===================
    // ========================================================

    /**
     * @return  The address of the generic trader proxy for making zaps
     */
    function genericTraderProxy() external view returns (IGenericTraderProxyV1);

    /**
     * @return  The address of the expiry contract
     */
    function expiry() external view returns (IExpiry);

    /**
     * @return  The slippage tolerance (using 1e18 as the base) for zaps when pauses are enabled
     */
    function slippageToleranceForPauseSentinel() external view returns (uint256);

    /**
     * @return  The address of the liquidator asset registry contract
     */
    function liquidatorAssetRegistry() external view returns (ILiquidatorAssetRegistry);

    /**
     * @return The address of the emitter contract that can emit certain events for indexing
     */
    function eventEmitter() external view returns (IEventEmitterRegistry);

    /**
     * @return The address of the Chainlink price oracle that's compatible with DolomiteMargin
     */
    function chainlinkPriceOracle() external view returns (IDolomitePriceOracle);

    /**
     * @return The address of the Redstone price oracle that's compatible with DolomiteMargin
     */
    function redstonePriceOracle() external view returns (IDolomitePriceOracle);

    /**
     * @return The address of the oracle aggregator that's compatible with DolomiteMargin
     */
    function oracleAggregator() external view returns (IDolomitePriceOracle);

    /**
     * @return The base (denominator) for the slippage tolerance variable. Always 1e18.
     */
    function slippageToleranceForPauseSentinelBase() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IGenericTraderBase } from "./IGenericTraderBase.sol";
import { IUpgradeableAsyncIsolationModeUnwrapperTrader } from "../isolation-mode/interfaces/IUpgradeableAsyncIsolationModeUnwrapperTrader.sol"; // solhint-disable-line max-line-length
import { IUpgradeableAsyncIsolationModeWrapperTrader } from "../isolation-mode/interfaces/IUpgradeableAsyncIsolationModeWrapperTrader.sol"; // solhint-disable-line max-line-length
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";


/**
 * @title   IEventEmitterRegistry
 * @author  Dolomite
 *
 * Interface for a a singleton event emission contract, which makes tracking events easier for the Subgraph.
 */
interface IEventEmitterRegistry {

    // ================================================
    // ==================== Structs ===================
    // ================================================

    struct BalanceUpdate {
        IDolomiteStructs.Wei deltaWei;
        IDolomiteStructs.Par newPar;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    /**
     * @notice This is emitted when a zap is executed
     *
     * @param  accountOwner     The address of the account that executed the zap
     * @param  accountNumber    The sub account of the address that executed the zap
     * @param  marketIdsPath    The path of market IDs that was executed
     * @param  tradersPath      The path of traders that was executed
     */
    event ZapExecuted(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256[] marketIdsPath,
        IGenericTraderBase.TraderParam[] tradersPath
    );

    /**
     * @notice This is emitted when a borrow position is initially opened
     *
     * @param  borrower             The address of the account that opened the position
     * @param  borrowAccountNumber  The account number of the account that opened the position
     */
    event BorrowPositionOpen(
        address indexed borrower,
        uint256 indexed borrowAccountNumber
    );

    /**
     * @notice This is emitted when a margin position is initially opened
     *
     * @param  accountOwner         The address of the account that opened the position
     * @param  accountNumber        The account number of the account that opened the position
     * @param  inputToken           The token that was sold to purchase the collateral. This should be the owed token
     * @param  outputToken          The token that was purchased with the debt. This should be the held token
     * @param  depositToken         The token that was deposited as collateral. This should be the held token
     * @param  inputBalanceUpdate   The amount of inputToken that was sold to purchase the outputToken
     * @param  outputBalanceUpdate  The amount of outputToken that was purchased with the inputToken
     * @param  marginDepositUpdate  The amount of depositToken that was deposited as collateral
     */
    event MarginPositionOpen(
        address indexed accountOwner,
        uint256 indexed accountNumber,
        address inputToken,
        address outputToken,
        address depositToken,
        BalanceUpdate inputBalanceUpdate,
        BalanceUpdate outputBalanceUpdate,
        BalanceUpdate marginDepositUpdate
    );

    /**
     * @notice This is emitted when a margin position is (partially) closed
     *
     * @param  accountOwner             The address of the account that opened the position
     * @param  accountNumber            The account number of the account that opened the position
     * @param  inputToken               The token that was sold to purchase the debt. This should be the held token
     * @param  outputToken              The token that was purchased with the collateral. This should be the owed token
     * @param  withdrawalToken          The token that was withdrawn as collateral. This should be the held token
     * @param  inputBalanceUpdate       The amount of inputToken that was sold to purchase the outputToken
     * @param  outputBalanceUpdate      The amount of outputToken that was purchased with the inputToken
     * @param  marginWithdrawalUpdate   The amount of withdrawalToken that was deposited as collateral
     */
    event MarginPositionClose(
        address indexed accountOwner,
        uint256 indexed accountNumber,
        address inputToken,
        address outputToken,
        address withdrawalToken,
        BalanceUpdate inputBalanceUpdate,
        BalanceUpdate outputBalanceUpdate,
        BalanceUpdate marginWithdrawalUpdate
    );

    event AsyncDepositCreated(
        bytes32 indexed key,
        address indexed token,
        IUpgradeableAsyncIsolationModeWrapperTrader.DepositInfo deposit
    );

    event AsyncDepositOutputAmountUpdated(
        bytes32 indexed key,
        address indexed token,
        uint256 outputAmount
    );

    event AsyncDepositExecuted(bytes32 indexed key, address indexed token);

    event AsyncDepositFailed(bytes32 indexed key, address indexed token, string reason);

    event AsyncDepositCancelled(bytes32 indexed key, address indexed token);

    event AsyncDepositCancelledFailed(bytes32 indexed key, address indexed token, string reason);

    event AsyncWithdrawalCreated(
        bytes32 indexed key,
        address indexed token,
        IUpgradeableAsyncIsolationModeUnwrapperTrader.WithdrawalInfo withdrawal
    );

    event AsyncWithdrawalOutputAmountUpdated(
        bytes32 indexed key,
        address indexed token,
        uint256 outputAmount
    );

    event AsyncWithdrawalExecuted(bytes32 indexed key, address indexed token);

    event AsyncWithdrawalFailed(bytes32 indexed key, address indexed token, string reason);

    event AsyncWithdrawalCancelled(bytes32 indexed key, address indexed token);

    event RewardClaimed(
        address indexed distributor,
        address indexed user,
        uint256 epoch,
        uint256 amount
    );

    // ================================================
    // ================== Functions ===================
    // ================================================

    /**
     * @notice Emits a ZapExecuted event
     *
     * @param  _accountOwner    The address of the account that executed the zap
     * @param  _accountNumber   The sub account of the address that executed the zap
     * @param  _marketIdsPath   The path of market IDs that was executed
     * @param  _tradersPath     The path of traders that was executed
     */
    function emitZapExecuted(
        address _accountOwner,
        uint256 _accountNumber,
        uint256[] calldata _marketIdsPath,
        IGenericTraderBase.TraderParam[] calldata _tradersPath
    )
    external;

    /**
     * @notice Emits a MarginPositionOpen event
     *
     * @param  _accountOwner         The address of the account that opened the position
     * @param  _accountNumber        The account number of the account that opened the position
     */
    function emitBorrowPositionOpen(
        address _accountOwner,
        uint256 _accountNumber
    )
    external;

    /**
     * @notice Emits a MarginPositionOpen event
     *
     * @param  _accountOwner         The address of the account that opened the position
     * @param  _accountNumber        The account number of the account that opened the position
     * @param  _inputToken           The token that was sold to purchase the collateral. This should be the owed token
     * @param  _outputToken          The token that was purchased with the debt. This should be the held token
     * @param  _depositToken         The token that was deposited as collateral. This should be the held token
     * @param  _inputBalanceUpdate   The amount of inputToken that was sold to purchase the outputToken
     * @param  _outputBalanceUpdate  The amount of outputToken that was purchased with the inputToken
     * @param  _marginDepositUpdate  The amount of depositToken that was deposited as collateral
     */
    function emitMarginPositionOpen(
        address _accountOwner,
        uint256 _accountNumber,
        address _inputToken,
        address _outputToken,
        address _depositToken,
        BalanceUpdate calldata _inputBalanceUpdate,
        BalanceUpdate calldata _outputBalanceUpdate,
        BalanceUpdate calldata _marginDepositUpdate
    )
    external;

    /**
     * @notice Emits a MarginPositionClose event
     *
     * @param  _accountOwner            The address of the account that opened the position
     * @param  _accountNumber           The account number of the account that opened the position
     * @param  _inputToken              The token that was sold to purchase the debt. This should be the held token
     * @param  _outputToken             The token that was purchased with the collateral. This should be the owed token
     * @param  _withdrawalToken         The token that was withdrawn as collateral. This should be the held token
     * @param  _inputBalanceUpdate      The amount of inputToken that was sold to purchase the outputToken
     * @param  _outputBalanceUpdate     The amount of outputToken that was purchased with the inputToken
     * @param  _marginWithdrawalUpdate  The amount of withdrawalToken that was deposited as collateral
     */
    function emitMarginPositionClose(
        address _accountOwner,
        uint256 _accountNumber,
        address _inputToken,
        address _outputToken,
        address _withdrawalToken,
        BalanceUpdate calldata _inputBalanceUpdate,
        BalanceUpdate calldata _outputBalanceUpdate,
        BalanceUpdate calldata _marginWithdrawalUpdate
    )
    external;

    function emitAsyncDepositCreated(
        bytes32 _key,
        address _token,
        IUpgradeableAsyncIsolationModeWrapperTrader.DepositInfo calldata _deposit
    ) external;

    function emitAsyncDepositOutputAmountUpdated(
        bytes32 _key,
        address _token,
        uint256 _outputAmount
    ) external;

    function emitAsyncDepositExecuted(bytes32 _key, address _token) external;

    function emitAsyncDepositFailed(bytes32 _key, address _token, string calldata _reason) external;

    function emitAsyncDepositCancelled(bytes32 _key, address _token) external;

    function emitAsyncDepositCancelledFailed(bytes32 _key, address _token, string calldata _reason) external;

    function emitAsyncWithdrawalCreated(
        bytes32 _key,
        address _token,
        IUpgradeableAsyncIsolationModeUnwrapperTrader.WithdrawalInfo calldata _withdrawal
    ) external;

    function emitAsyncWithdrawalOutputAmountUpdated(
        bytes32 _key,
        address _token,
        uint256 _outputAmount
    ) external;

    function emitAsyncWithdrawalExecuted(bytes32 _key, address _token) external;

    function emitAsyncWithdrawalFailed(bytes32 _key, address _token, string calldata _reason) external;

    function emitAsyncWithdrawalCancelled(bytes32 _key, address _token) external;

    function emitRewardClaimed(address user, uint256 _epoch, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IExpiry
 * @author  Dolomite
 *
 * @notice  Interface for getting, setting, and executing the expiry of a position.
 */
interface IExpiry {

    // ============ Enums ============

    enum CallFunctionType {
        SetExpiry,
        SetApproval
    }

    // ============ Structs ============

    struct SetExpiryArg {
        IDolomiteMargin.AccountInfo account;
        uint256 marketId;
        uint32 timeDelta;
        bool forceUpdate;
    }

    struct SetApprovalArg {
        address sender;
        uint32 minTimeDelta;
    }

    function getSpreadAdjustedPrices(
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
    external
    view
    returns (IDolomiteMargin.MonetaryPrice memory heldPrice, IDolomiteMargin.MonetaryPrice memory owedPriceAdj);

    function getExpiry(
        IDolomiteMargin.AccountInfo calldata account,
        uint256 marketId
    )
    external
    view
    returns (uint32);

    function g_expiryRampTime() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IGenericTraderBase
 * @author  Dolomite
 *
 * @notice  Base contract structs/params for a generic trader contract.
 */
interface IGenericTraderBase {

    // ============ Enums ============

    enum TraderType {
        /// @dev    The trade will be conducted using external liquidity, using an `ActionType.Sell` or `ActionType.Buy`
        ///         action.
        ExternalLiquidity,
        /// @dev    The trade will be conducted using internal liquidity, using an `ActionType.Trade` action.
        InternalLiquidity,
        /// @dev    The trade will be conducted using external liquidity using an `ActionType.Sell` or `ActionType.Buy`
        ///         action. If this TradeType is used, the trader must be validated using
        ///         the `IIsolationModeToken#isTokenConverterTrusted` function on the IsolationMode token.
        IsolationModeUnwrapper,
        /// @dev    The trade will be conducted using external liquidity using an `ActionType.Sell` or `ActionType.Buy`
        ///         action. If this TradeType is used, the trader must be validated using
        ///         the `IIsolationModeToken#isTokenConverterTrusted` function on the IsolationMode token.
        IsolationModeWrapper
    }

    // ============ Structs ============

    struct TraderParam {
        /// @dev The type of trade to conduct
        TraderType traderType;
        /// @dev    The index into the `_makerAccounts` array of the maker account to trade with. Should be set to 0 if
        ///         the traderType is not `TraderType.InternalLiquidity`.
        uint256 makerAccountIndex;
        /// @dev The address of IAutoTrader or IExchangeWrapper that will be used to conduct the trade.
        address trader;
        /// @dev The data that will be passed through to the trader contract.
        bytes tradeData;
    }

    struct GenericTraderProxyCache {
        IDolomiteMargin dolomiteMargin;
        /// @dev    True if the user is making a margin deposit, false if they are withdrawing. False if the variable is
        ///         unused too.
        bool isMarginDeposit;
        /// @dev    The other account number that is not `_traderAccountNumber`. Only used for TransferCollateralParams.
        uint256 otherAccountNumber;
        /// @dev    The index into the account array at which traders start.
        uint256 traderAccountStartIndex;
        /// @dev    The cursor for the looping through the operation's actions.
        uint256 actionsCursor;
        /// @dev    The balance of `inputMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei inputBalanceWeiBeforeOperate;
        /// @dev    The balance of `outputMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei outputBalanceWeiBeforeOperate;
        /// @dev    The balance of `transferMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei transferBalanceWeiBeforeOperate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { IGenericTraderBase } from "./IGenericTraderBase.sol";
import { AccountBalanceLib } from "../lib/AccountBalanceLib.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";



/**
 * @title   IGenericTraderProxyV1
 * @author  Dolomite
 *
 * Trader proxy interface for trading assets using any trader from msg.sender
 */
interface IGenericTraderProxyV1 is IGenericTraderBase {

    // ============ Structs ============

    enum EventEmissionType {
        None,
        BorrowPosition,
        MarginPosition
    }

    struct TransferAmount {
        /// @dev The market ID to transfer
        uint256 marketId;
        /// @dev Note, setting to uint(-1) will transfer all of the user's balance.
        uint256 amountWei;
    }

    struct TransferCollateralParam {
        /// @dev The account number from which collateral will be transferred.
        uint256 fromAccountNumber;
        /// @dev The account number to which collateral will be transferred.
        uint256 toAccountNumber;
        /// @dev The transfers to execute after all of the trades.
        TransferAmount[] transferAmounts;
    }

    struct ExpiryParam {
        /// @dev The market ID whose expiry will be updated.
        uint256 marketId;
        /// @dev The new expiry time delta for the market. Setting this to `0` will reset the expiration.
        uint32 expiryTimeDelta;
    }

    struct UserConfig {
        /// @dev The timestamp at which the zap request fails
        uint256 deadline;
        /// @dev    Setting this to `BalanceCheckFlag.Both` or `BalanceCheckFlag.From` will check the
        ///         `_tradeAccountNumber` is not negative after the trade for the input market (_marketIdsPath[0]).
        ///         Setting this to `BalanceCheckFlag.Both` or `BalanceCheckFlag.To` will check the
        ///         `_transferAccountNumber` is not negative after the trade for any of the transfers in
        ///         `TransferCollateralParam.transferAmounts`.
        AccountBalanceLib.BalanceCheckFlag balanceCheckFlag;
        EventEmissionType eventType;
    }

    // ============ Functions ============

    /**
     * @dev     Swaps an exact amount of input for a minimum amount of output.
     *
     * @param  _tradeAccountNumber          The account number to use for msg.sender's trade
     * @param  _marketIdsPath               The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param  _inputAmountWei              The input amount (in wei) to use for the initial trade action. Setting this
     *                                      value to `uint(-1)` will use the user's full balance.
     * @param  _minOutputAmountWei          The minimum output amount expected to be received by the user.
     * @param  _tradersPath                 The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1`.
     * @param  _makerAccounts               The accounts that will be used for the maker side of the trades involving
     *                                      `TraderType.InternalLiquidity`.
     * @param  _userConfig                  The user configuration for the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.From` will check that the user's `_tradeAccountNumber`
     *                                      is non-negative after the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.To` has no effect.
     */
    function swapExactInputForOutput(
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        UserConfig calldata _userConfig
    )
    external;

    /**
     * @dev     The same function as `swapExactInputForOutput`, but allows the caller to transfer collateral and modify
     *          the position's expiration in the same transaction.
     *
     * @param  _tradeAccountNumber          The account number to use for msg.sender's trade
     * @param  _marketIdsPath               The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param  _inputAmountWei              The input amount (in wei) to use for the initial trade action. Setting this
     *                                      value to `uint(-1)` will use the user's full balance.
     * @param  _minOutputAmountWei          The minimum output amount expected to be received by the user.
     * @param  _tradersPath                 The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1`.
     * @param  _makerAccounts               The accounts that will be used for the maker side of the trades involving
                                            `TraderType.InternalLiquidity`.
     * @param  _transferCollateralParams    The parameters for transferring collateral in/out of the
     *                                      `_tradeAccountNumber` once the trades settle. One of
     *                                      `_params.fromAccountNumber` or `_params.toAccountNumber` must be equal to
     *                                      `_tradeAccountNumber`.
     * @param  _expiryParams                The parameters for modifying the expiration of the debt in the position.
     * @param  _userConfig                  The user configuration for the trade. Setting the `balanceCheckFlag` to
     *                                      `BalanceCheckFlag.From` will check that the user's balance for inputMarket
     *                                      for `_tradeAccountNumber` is non-negative after the trade. Setting the
     *                                      `balanceCheckFlag` to `BalanceCheckFlag.To` will check that the user's
     *                                      balance for each `transferMarket` for `transferAccountNumber` is
     *                                      non-negative after.
     */
    function swapExactInputForOutputAndModifyPosition(
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256 _inputAmountWei,
        uint256 _minOutputAmountWei,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        TransferCollateralParam calldata _transferCollateralParams,
        ExpiryParam calldata _expiryParams,
        UserConfig calldata _userConfig
    )
    external;

    function ownerSetEventEmitterRegistry(
        address _eventEmitterRegistry
    ) external;

    function EXPIRY() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

/**
 * @title   ILiquidatorAssetRegistry
 * @author  Dolomite
 *
 * Interface for a registry that tracks which assets can be liquidated and by each contract
 */
interface ILiquidatorAssetRegistry {

    /**
     *
     * @param  _marketId    The market ID of the asset
     * @param  _liquidator  The address of the liquidator to add
     */
    function ownerAddLiquidatorToAssetWhitelist(
        uint256 _marketId,
        address _liquidator
    )
    external;

    /**
     *
     * @param  _marketId    The market ID of the asset
     * @param  _liquidator  The address of the liquidator to remove
     */
    function ownerRemoveLiquidatorFromAssetWhitelist(
        uint256 _marketId,
        address _liquidator
    )
    external;

    /**
     *
     * @param  _marketId    The market ID of the asset to check
     * @return              An array of whitelisted liquidators for the asset. An empty array is returned if any
     *                      liquidator can be used for this asset
     */
    function getLiquidatorsForAsset(
        uint256 _marketId
    )
    external view returns (address[] memory);

    /**
     *
     * @param  _marketId    The market ID of the asset to check
     * @param  _liquidator  The address of the liquidator to check
     * @return              True if the liquidator is whitelisted for the asset, false otherwise. Returns true if there
     *                      are no whitelisted liquidators for the asset. Should ALWAYS have at least ONE whitelisted
     *                      liquidator for IsolationMode assets.
     */
    function isAssetWhitelistedForLiquidation(
        uint256 _marketId,
        address _liquidator
    )
    external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IOnlyDolomiteMargin
 * @author  Dolomite
 *
 * @notice  This interface is for contracts that need to add modifiers for only DolomiteMargin / Owner caller.
 */
interface IOnlyDolomiteMargin {

    function DOLOMITE_MARGIN() external view returns (IDolomiteMargin);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteMarginExchangeWrapper } from "../../protocol/interfaces/IDolomiteMarginExchangeWrapper.sol";


/**
 * @title   IIsolationModeUnwrapperTraderV2
 * @author  Dolomite
 *
 * V2 Interface for a contract that can convert an isolation mode token into an underlying component token.
 */
interface IIsolationModeUnwrapperTraderV2 is IDolomiteMarginExchangeWrapper {

    struct CreateActionsForUnwrappingParams {
        /// @dev    The index of the account (according the Accounts[] array) that is performing the sell.
        uint256 primaryAccountId;
        /// @dev    The index of the account (according the Accounts[] array) that is being liquidated. This is set to
        ///         `_primaryAccountId` if a liquidation is not occurring.
        uint256 otherAccountId;
        /// @dev    The address of the owner of the account that is performing the sell.
        address primaryAccountOwner;
        /// @dev    The account number of the owner of the account that is performing the sell.
        uint256 primaryAccountNumber;
        /// @dev    The address of the owner of the account that is being liquidated. This is set to
        ///         `_primaryAccountOwner` if a liquidation is not occurring.
        address otherAccountOwner;
        /// @dev    The account number of the owner of the account that is being liquidated. This is set to
        ///         `_primaryAccountNumber` if a liquidation is not occurring.
        uint256 otherAccountNumber;
        /// @dev    The market that is being outputted by the unwrapping.
        uint256 outputMarket;
        /// @dev    The market that is being unwrapped, should be equal to `token()`.
        uint256 inputMarket;
        /// @dev    The min amount of `_outputMarket` that must be outputted by the unwrapping.
        uint256 minOutputAmount;
        /// @dev    The amount of the `_inputMarket` that the _primaryAccountId must sell.
        uint256 inputAmount;
        /// @dev    The calldata to pass through to any external sales that occur.
        bytes orderData;
    }

    /**
     * @return The isolation mode token that this contract can unwrap (the input token).
     */
    function token() external view returns (address);

    /**
     * @return True if the `_outputToken` is a valid output token for this contract, to be unwrapped by `token()`.
     */
    function isValidOutputToken(address _outputToken) external view returns (bool);

    /**
     * @notice  Creates the necessary actions for selling the `_inputMarket` into `_outputMarket`. Note, the
     *          `_inputMarket` should be equal to `token()` and `_outputMarket` should be validated to be a correct
     *           market that can be transformed into `token()`.
     *
     * @param  _params  The parameters for creating the actions for unwrapping.
     * @return          The actions that will be executed to unwrap the `_inputMarket` into `_outputMarket`.
     */
    function createActionsForUnwrapping(
        CreateActionsForUnwrappingParams calldata _params
    )
        external
        view
        returns (IDolomiteMargin.ActionArgs[] memory);

    /**
     * @return  The number of actions used to unwrap the isolation mode token.
     */
    function actionsLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IBorrowPositionProxyV2 } from "../../interfaces/IBorrowPositionProxyV2.sol";
import { IOnlyDolomiteMargin } from "../../interfaces/IOnlyDolomiteMargin.sol";


/**
 * @title   IIsolationModeVaultFactory
 * @author  Dolomite
 *
 * @notice A wrapper contract around a certain token to offer isolation mode features for DolomiteMargin.
 */
interface IIsolationModeVaultFactory is IOnlyDolomiteMargin {

    // =================================================
    // ==================== Structs ====================
    // =================================================

    struct QueuedTransfer {
        address from;
        address to;
        uint256 amount;
        address vault;
        bool isExecuted;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    event UserVaultImplementationSet(
        address indexed previousUserVaultImplementation,
        address indexed newUserVaultImplementation
    );

    event TokenConverterSet(address indexed tokenConverter, bool isTrusted);

    event VaultCreated(address indexed account, address vault);

    event Initialized();

    event TransferQueued(
        uint256 indexed transferCursor,
        address from,
        address to,
        uint256 amountWei,
        address vault
    );

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    /**
     * @notice  Initializes this contract's variables that are dependent on this token being added to DolomiteMargin.
     */
    function ownerInitialize(address[] calldata _tokenConverters) external;

    /**
     *
     * @param  _userVaultImplementation  The address of the new vault implementation contract
     */
    function ownerSetUserVaultImplementation(address _userVaultImplementation) external;

    /**
     * @notice  A token converter is used to convert this underlying token into a Dolomite-compatible one for deposit
     *          or withdrawal
     *
     * @param  _tokenConverter   The address of the token converter contract to set whether or not it's trusted for
     *                          executing transfers to/from vaults
     * @param  _isTrusted        True if the token converter is trusted, false otherwise
     */
    function ownerSetIsTokenConverterTrusted(address _tokenConverter, bool _isTrusted) external;

    // ======================================================
    // ================== User Functions ===================
    // ======================================================

    /**
     * @notice  Creates the vault for `_account`
     *
     * @param  _account  The account owner to create the vault for
     */
    function createVault(address _account) external returns (address);

    /**
     * @notice  Creates the vault for `msg.sender`
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _amountWei        The amount of tokens to deposit
     */
    function createVaultAndDepositIntoDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    ) external returns (address);

    /**
     * @notice  Deposits a token into the vault owner's account at `_toAccountNumber`. This function can only be called
     *          by a user's vault contract. Reverts if `_marketId` is set to the market ID of this vault.
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _marketId         The market ID of the token to deposit
     * @param  _amountWei        The amount of tokens to deposit
     */
    function depositOtherTokenIntoDolomiteMarginForVaultOwner(
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  Enqueues a transfer into Dolomite Margin from the vault. Assumes msg.sender is a trusted token
     *          converter, else reverts. Reverts if `_vault` is not a valid vault contract.
     *
     * @param  _vault        The address of the vault that the token converter is interacting with
     * @param  _amountWei    The amount of tokens to transfer into Dolomite Margin
     */
    function enqueueTransferIntoDolomiteMargin(
        address _vault,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  Enqueues a transfer from Dolomite Margin to the token converter. Assumes msg.sender is a trusted token
     *          converter, else reverts. Reverts if `_vault` is not a valid vault contract.
     *
     * @param  _vault        The address of the vault that the token converter is interacting with
     * @param  _amountWei    The amount of tokens to transfer from Dolomite Margin to the token converter
     */
    function enqueueTransferFromDolomiteMargin(
        address _vault,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  This function should only be called by a user's vault contract
     *
     * @param  _toAccountNumber  The account number of the account to which the tokens will be deposited
     * @param  _amountWei        The amount of tokens to deposit
     */
    function depositIntoDolomiteMargin(
        uint256 _toAccountNumber,
        uint256 _amountWei
    )
    external;

    /**
     * @notice  This function should only be called by a user's vault contract
     *
     * @param  _fromAccountNumber    The account number of the account from which the tokens will be withdrawn
     * @param  _amountWei            The amount of tokens to withdraw
     */
    function withdrawFromDolomiteMargin(
        uint256 _fromAccountNumber,
        uint256 _amountWei
    )
    external;

    // ============================================
    // ================= Constants ================
    // ============================================

    /**
     * @return The address of the token that this vault wraps around
     */
    function UNDERLYING_TOKEN() external view returns (address);

    /**
     * @return  The address of the BorrowPositionProxyV2 contract
     */
    function BORROW_POSITION_PROXY() external view returns (IBorrowPositionProxyV2);

    // =================================================
    // ================= View Functions ================
    // =================================================

    /**
     * @return  The market ID of this token contract according to DolomiteMargin. This value is initializes in the
     *          #initialize function
     */
    function marketId() external view returns (uint256);

    /**
     * @return  This function should always return `true`. It's used by The Graph to index this contract as a Wrapper.
     */
    function isIsolationAsset() external view returns (bool);

    /**
     *
     * @param  _transferCursor   The cursor used to key into the mapping of queued transfers
     * @return The transfer enqueued in the mapping at the cursor's position
     */
    function getQueuedTransferByCursor(uint256 _transferCursor) external view returns (QueuedTransfer memory);

    /**
     * @return  The market IDs of the assets that can be borrowed in a position with this wrapped asset. An empty array
     *          indicates that any non-isolation mode asset can be borrowed against it.
     */
    function allowableDebtMarketIds() external view returns (uint256[] memory);

    /**
     * @return  The market IDs of the assets that can be used as collateral in a position with this wrapped asset. An
     *          empty array indicates that any non-isolation mode asset can be borrowed against it. To indicate that no
     *          assets can be used as collateral, return an array with a single element containing #marketId().
     */
    function allowableCollateralMarketIds() external view returns (uint256[] memory);

    /**
     * @return  The address of the current vault implementation contract
     */
    function userVaultImplementation() external view returns (address);

    /**
     *
     * @param  _account  The account owner to get the vault for
     * @return  _vault   The address of the vault created for `_account`. Returns address(0) if no vault has been
     *                   created yet for this account.
     */
    function getVaultByAccount(address _account) external view returns (address _vault);

    /**
     * @notice  Same as `getVaultByAccount`, but always returns the user's non-zero vault address.
     */
    function calculateVaultByAccount(address _account) external view returns (address _vault);

    /**
     *
     * @param  _vault    The vault that's used by an account for depositing/withdrawing
     * @return  _account The address of the account that owns the `_vault`
     */
    function getAccountByVault(address _vault) external view returns (address _account);

    /**
     * @notice  A token converter is used to convert this underlying token into a Dolomite-compatible one for deposit
     *          or withdrawal
     * @return  True if the token converter is currently in-use by this contract.
     */
    function isTokenConverterTrusted(address _tokenConverter) external view returns (bool);

    function getProxyVaultInitCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteMarginExchangeWrapper } from "../../protocol/interfaces/IDolomiteMarginExchangeWrapper.sol";


/**
 * @title   IIsolationModeWrapperTraderV2
 * @author  Dolomite
 *
 * Interface for a contract that can convert a token into an isolation mode token.
 */
interface IIsolationModeWrapperTraderV2 is IDolomiteMarginExchangeWrapper {

    struct CreateActionsForWrappingParams {
        /// @dev    The index of the account (according the Accounts[] array) that is performing the sell.
        uint256 primaryAccountId;
        /// @dev    The index of the account (according the Accounts[] array) that is being liquidated. This is set to
        ///         `_primaryAccountId` if a liquidation is not occurring.
        uint256 otherAccountId;
        /// @dev    The address of the owner of the account that is performing the sell.
        address primaryAccountOwner;
        /// @dev    The account number of the owner of the account that is performing the sell.
        uint256 primaryAccountNumber;
        /// @dev    The address of the owner of the account that is being liquidated. This is set to
        ///         `_primaryAccountOwner` if a liquidation is not occurring.
        address otherAccountOwner;
        /// @dev    The account number of the owner of the account that is being liquidated. This is set to
        ///         `_primaryAccountNumber` if a liquidation is not occurring.
        uint256 otherAccountNumber;
        /// @dev    The market that is being outputted by the wrapping, should be equal to `token().
        uint256 outputMarket;
        /// @dev    The market that is being used to wrap into `token()`.
        uint256 inputMarket;
        /// @dev    The min amount of `_outputMarket` that must be outputted by the wrapping.
        uint256 minOutputAmount;
        /// @dev    The amount of the `_inputMarket` that the _primaryAccountId must sell.
        uint256 inputAmount;
        /// @dev    The calldata to pass through to any external sales that occur.
        bytes orderData;
    }

    /**
     * @return The isolation mode token that this contract can wrap (the output token)
     */
    function token() external view returns (address);

    /**
     * @return True if the `_inputToken` is a valid input token for this contract, to be wrapped into `token()`
     */
    function isValidInputToken(address _inputToken) external view returns (bool);

    /**
     * @notice  Creates the necessary actions for selling the `_inputMarket` into `_outputMarket`. Note, the
     *          `_outputMarket` should be equal to `token()` and `_inputMarket` should be validated to be a correct
     *           market that can be transformed into `token()`.
     *
     * @param  _params  The parameters for creating the actions for wrapping.
     * @return          The actions that will be executed to unwrap the `_inputMarket` into `_outputMarket`.
     */
    function createActionsForWrapping(
        CreateActionsForWrappingParams calldata _params
    )
        external
        view
        returns (IDolomiteMargin.ActionArgs[] memory);

    /**
     * @return  The number of Actions used to wrap a valid input token into the this wrapper's Isolation Mode token.
     */
    function actionsLength() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeUnwrapperTraderV2 } from "./IIsolationModeUnwrapperTraderV2.sol";
import { IIsolationModeVaultFactory } from "./IIsolationModeVaultFactory.sol";
import { IOnlyDolomiteMargin } from "../../interfaces/IOnlyDolomiteMargin.sol";


/**
 * @title   IUpgradeableAsyncIsolationModeUnwrapperTrader
 * @author  Dolomite
 *
 * Interface for an upgradeable contract that can convert an isolation mode token into another token.
 */
interface IUpgradeableAsyncIsolationModeUnwrapperTrader is IIsolationModeUnwrapperTraderV2, IOnlyDolomiteMargin {

    // ================================================
    // ==================== Structs ===================
    // ================================================

    struct WithdrawalInfo {
        bytes32 key;
        address vault;
        uint256 accountNumber;
        /// @dev The amount of FACTORY tokens that is being sold
        uint256 inputAmount;
        address outputToken;
        /// @dev initially 0 until the withdrawal is executed
        uint256 outputAmount;
        bool isRetryable;
        bool isLiquidation;
        bytes extraData;
    }

    struct State {
        uint256 actionsLength;
        uint256 reentrancyGuard;
        address vaultFactory;
        address handlerRegistry;
        mapping(bytes32 => WithdrawalInfo) withdrawalInfo;
    }

    // ================================================
    // ===================== Enums ====================
    // ================================================

    enum TradeType {
        FromWithdrawal,
        FromDeposit,
        NoOp
    }

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    /**
     * Notifies the unwrapper that it'll be entered for a trade from the unwrapper. This allows it to modify the action
     * length
     */
    function handleCallbackFromWrapperBefore() external;

    /**
     * Reverts any changes made in `handleCallbackFromWrapperBefore`. Can only be called by a corresponding Wrapper
     * trader.
     */
    function handleCallbackFromWrapperAfter() external;

    /**
     * Transfers underlying tokens from the vault (msg.sender) to this contract to initiate a redemption.
     */
    function vaultInitiateUnwrapping(
        uint256 _tradeAccountNumber,
        uint256 _inputAmount,
        address _outputToken,
        uint256 _minOutputAmount,
        bool _isLiquidation,
        bytes calldata _extraData
    ) external payable;

    /**
     *
     * @param  _key The key of the withdrawal that should be cancelled
     */
    function initiateCancelWithdrawal(bytes32 _key) external;

    function getWithdrawalInfo(bytes32 _key) external view returns (WithdrawalInfo memory);

    function VAULT_FACTORY() external view returns (IIsolationModeVaultFactory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IIsolationModeVaultFactory } from "./IIsolationModeVaultFactory.sol";
import { IIsolationModeWrapperTraderV2 } from "./IIsolationModeWrapperTraderV2.sol";
import { IOnlyDolomiteMargin } from "../../interfaces/IOnlyDolomiteMargin.sol";


/**
 * @title   IUpgradeableAsyncIsolationModeWrapperTrader
 * @author  Dolomite
 *
 * Interface for an upgradeable contract that can convert a token into an isolation mode token.
 */
interface IUpgradeableAsyncIsolationModeWrapperTrader is IIsolationModeWrapperTraderV2, IOnlyDolomiteMargin {

    // ================================================
    // ==================== Structs ===================
    // ================================================

    struct State {
        mapping(bytes32 => DepositInfo) depositInfo;
        address vaultFactory;
        address handlerRegistry;
    }

    struct DepositInfo {
        bytes32 key;
        address vault;
        uint256 accountNumber;
        address inputToken;
        uint256 inputAmount;
        uint256 outputAmount;
        bool isRetryable;
    }

    // ===================================================
    // ==================== Functions ====================
    // ===================================================

    /**
     * This should be called by the vault to initiate a cancellation for a deposit.
     *
     * @param  _key The key of the deposit that should be cancelled
     */
    function initiateCancelDeposit(bytes32 _key) external;

    function setDepositInfoAndReducePendingAmountFromUnwrapper(
        bytes32 _key,
        uint256 _outputAmountDeltaWei,
        DepositInfo calldata _depositInfo
    ) external;

    function getDepositInfo(bytes32 _key) external view returns (DepositInfo memory);

    function VAULT_FACTORY() external view returns (IIsolationModeVaultFactory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { AccountBalanceLib } from "./AccountBalanceLib.sol";
import { ChainHelperLib } from "./ChainHelperLib.sol";
import { IExpiry } from "../interfaces/IExpiry.sol";
import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "../protocol/lib/Require.sol";


/**
 * @title   AccountActionLib
 * @author  Dolomite
 *
 * @notice  Library contract that makes specific actions easy to call
 */
library AccountActionLib {

    // ============ Constants ============

    bytes32 private constant _FILE = "AccountActionLib";

    uint256 private constant _ALL = type(uint256).max;

    // ===================================================================
    // ========================= Write Functions =========================
    // ===================================================================

    function deposit(
        IDolomiteMargin _dolomiteMargin,
        address _accountOwner,
        address _fromAccount,
        uint256 _toAccountNumber,
        uint256 _marketId,
        IDolomiteMargin.AssetAmount memory _amount
    ) internal {
        IDolomiteStructs.AccountInfo[] memory accounts = new IDolomiteStructs.AccountInfo[](1);
        accounts[0] = IDolomiteStructs.AccountInfo({
            owner: _accountOwner,
            number: _toAccountNumber
        });

        IDolomiteStructs.ActionArgs[] memory actions = new IDolomiteStructs.ActionArgs[](1);
        actions[0] = encodeDepositAction(
            /* _accountId = */ 0,
            _marketId,
            _amount,
            _fromAccount
        );

        _dolomiteMargin.operate(accounts, actions);
    }

    /**
     *  Withdraws `_marketId` from `_fromAccount` to `_toAccount`
     */
    function withdraw(
        IDolomiteMargin _dolomiteMargin,
        address _accountOwner,
        uint256 _fromAccountNumber,
        address _toAccount,
        uint256 _marketId,
        IDolomiteStructs.AssetAmount memory _amount,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) internal {
        IDolomiteStructs.AccountInfo[] memory accounts = new IDolomiteStructs.AccountInfo[](1);
        accounts[0] = IDolomiteStructs.AccountInfo({
            owner: _accountOwner,
            number: _fromAccountNumber
        });

        IDolomiteStructs.ActionArgs[] memory actions = new IDolomiteStructs.ActionArgs[](1);
        actions[0] = encodeWithdrawalAction(
            /* _accountId = */ 0,
            _marketId,
            _amount,
            _toAccount
        );

        _dolomiteMargin.operate(accounts, actions);

        if (
            _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.From
        ) {
            AccountBalanceLib.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                accounts[0].owner,
                _fromAccountNumber,
                _marketId
            );
        }
    }

    /**
     * Transfers `_marketId` from `_fromAccount` to `_toAccount`
     */
    function transfer(
        IDolomiteMargin _dolomiteMargin,
        address _fromAccountOwner,
        uint256 _fromAccountNumber,
        address _toAccountOwner,
        uint256 _toAccountNumber,
        uint256 _marketId,
        IDolomiteStructs.AssetDenomination _amountDenomination,
        uint256 _amount,
        AccountBalanceLib.BalanceCheckFlag _balanceCheckFlag
    ) internal {
        IDolomiteStructs.AccountInfo[] memory accounts = new IDolomiteStructs.AccountInfo[](2);
        accounts[0] = IDolomiteStructs.AccountInfo({
            owner: _fromAccountOwner,
            number: _fromAccountNumber
        });
        accounts[1] = IDolomiteStructs.AccountInfo({
            owner: _toAccountOwner,
            number: _toAccountNumber
        });

        IDolomiteStructs.ActionArgs[] memory actions = new IDolomiteStructs.ActionArgs[](1);
        actions[0] = encodeTransferAction(
            /* _fromAccountId = */ 0,
            /* _toAccountId = */ 1,
            _marketId,
            _amountDenomination,
            _amount
        );

        _dolomiteMargin.operate(accounts, actions);

        if (
            _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.From
        ) {
            AccountBalanceLib.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                _fromAccountOwner,
                _fromAccountNumber,
                _marketId
            );
        }

        if (
            _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.Both
            || _balanceCheckFlag == AccountBalanceLib.BalanceCheckFlag.To
        ) {
            AccountBalanceLib.verifyBalanceIsNonNegative(
                _dolomiteMargin,
                _toAccountOwner,
                _toAccountNumber,
                _marketId
            );
        }
    }

    // ===============================================================
    // ========================= Pure Functions ======================
    // ===============================================================

    function all() internal pure returns (uint256) {
        return _ALL;
    }

    function encodeCallAction(
        uint256 _accountId,
        address _callee,
        bytes memory _callData
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType : IDolomiteStructs.ActionType.Call,
            accountId : _accountId,
            amount : IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: 0
            }),
            primaryMarketId : 0,
            secondaryMarketId : 0,
            otherAddress : _callee,
            otherAccountId : 0,
            data : _callData
        });
    }

    function encodeDepositAction(
        uint256 _accountId,
        uint256 _marketId,
        IDolomiteStructs.AssetAmount memory _amount,
        address _fromAccount
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Deposit,
            accountId: _accountId,
            amount: _amount,
            primaryMarketId: _marketId,
            secondaryMarketId: 0,
            otherAddress: _fromAccount,
            otherAccountId: 0,
            data: bytes("")
        });
    }

    function encodeExpirationAction(
        IDolomiteStructs.AccountInfo memory _account,
        uint256 _accountId,
        uint256 _owedMarketId,
        address _expiry,
        uint256 _expiryTimeDelta
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        Require.that(
            _expiryTimeDelta == uint32(_expiryTimeDelta),
            _FILE,
            "Invalid expiry time delta"
        );

        IExpiry.SetExpiryArg[] memory expiryArgs = new IExpiry.SetExpiryArg[](1);
        expiryArgs[0] = IExpiry.SetExpiryArg({
            account : _account,
            marketId : _owedMarketId,
            timeDelta : uint32(_expiryTimeDelta),
            forceUpdate : true
        });

        return encodeCallAction(
            _accountId,
            _expiry,
            abi.encode(IExpiry.CallFunctionType.SetExpiry, expiryArgs)
        );
    }

    function encodeExpiryLiquidateAction(
        uint256 _solidAccountId,
        uint256 _liquidAccountId,
        uint256 _owedMarketId,
        uint256 _heldMarketId,
        address _expiryProxy,
        uint32 _expiry,
        bool _flipMarkets
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Trade,
            accountId: _solidAccountId,
            amount: IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Target,
                value: 0
            }),
            primaryMarketId: !_flipMarkets ? _owedMarketId : _heldMarketId,
            secondaryMarketId: !_flipMarkets ? _heldMarketId : _owedMarketId,
            otherAddress: _expiryProxy,
            otherAccountId: _liquidAccountId,
            data: abi.encode(_owedMarketId, _expiry)
        });
    }

    function encodeLiquidateAction(
        uint256 _solidAccountId,
        uint256 _liquidAccountId,
        uint256 _owedMarketId,
        uint256 _heldMarketId,
        uint256 _owedWeiToLiquidate
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Liquidate,
            accountId: _solidAccountId,
            amount: IDolomiteStructs.AssetAmount({
                sign: true,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _owedWeiToLiquidate
            }),
            primaryMarketId: _owedMarketId,
            secondaryMarketId: _heldMarketId,
            otherAddress: address(0),
            otherAccountId: _liquidAccountId,
            data: new bytes(0)
        });
    }

    function encodeExternalSellActionWithTarget(
        uint256 _fromAccountId,
        uint256 _primaryMarketId,
        uint256 _secondaryMarketId,
        address _trader,
        uint256 _targetAmountWei,
        uint256 _amountOutMinWei,
        bytes memory _orderData
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
    IDolomiteStructs.AssetAmount memory assetAmount;
        assetAmount = IDolomiteStructs.AssetAmount({
            sign: true,
            denomination: IDolomiteStructs.AssetDenomination.Wei,
            ref: IDolomiteStructs.AssetReference.Target,
            value: _targetAmountWei
        });

        return IDolomiteStructs.ActionArgs({
            actionType : IDolomiteStructs.ActionType.Sell,
            accountId : _fromAccountId,
            amount : assetAmount,
            primaryMarketId : _primaryMarketId,
            secondaryMarketId : _secondaryMarketId,
            otherAddress : _trader,
            otherAccountId : 0,
            data : abi.encode(_amountOutMinWei, _orderData)
        });
    }

    function encodeExternalSellAction(
        uint256 _fromAccountId,
        uint256 _primaryMarketId,
        uint256 _secondaryMarketId,
        address _trader,
        uint256 _amountInWei,
        uint256 _amountOutMinWei,
        bytes memory _orderData
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        IDolomiteStructs.AssetAmount memory assetAmount;
        if (_amountInWei == _ALL) {
            assetAmount = IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Target,
                value: 0
            });
        } else {
            assetAmount = IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amountInWei
            });
        }

        return IDolomiteStructs.ActionArgs({
            actionType : IDolomiteStructs.ActionType.Sell,
            accountId : _fromAccountId,
            amount : assetAmount,
            primaryMarketId : _primaryMarketId,
            secondaryMarketId : _secondaryMarketId,
            otherAddress : _trader,
            otherAccountId : 0,
            data : abi.encode(_amountOutMinWei, _orderData)
        });
    }

    function encodeInternalTradeAction(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        uint256 _primaryMarketId,
        uint256 _secondaryMarketId,
        address _traderAddress,
        uint256 _amountInWei,
        uint256 _chainId,
        bool _calculateAmountWithMakerAccount,
        bytes memory _orderData
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Trade,
            accountId: _fromAccountId,
            amount: IDolomiteStructs.AssetAmount({
                sign: true,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amountInWei
            }),
            primaryMarketId: _primaryMarketId,
            secondaryMarketId: _secondaryMarketId,
            otherAddress: _traderAddress,
            otherAccountId: _toAccountId,
            data: ChainHelperLib.isArbitrum(_chainId)
                ? _orderData
                : abi.encode(_calculateAmountWithMakerAccount, _orderData)
        });
    }

    function encodeTransferAction(
        uint256 _fromAccountId,
        uint256 _toAccountId,
        uint256 _marketId,
        IDolomiteStructs.AssetDenomination _amountDenomination,
        uint256 _amount
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        IDolomiteStructs.AssetAmount memory assetAmount;
        if (_amount == _ALL) {
            assetAmount = IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: _amountDenomination,
                ref: IDolomiteStructs.AssetReference.Target,
                value: 0
            });
        } else {
            assetAmount = IDolomiteStructs.AssetAmount({
                sign: false,
                denomination: _amountDenomination,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amount
            });
        }
        return IDolomiteStructs.ActionArgs({
            actionType : IDolomiteStructs.ActionType.Transfer,
            accountId : _fromAccountId,
            amount : assetAmount,
            primaryMarketId : _marketId,
            secondaryMarketId : 0,
            otherAddress : address(0),
            otherAccountId : _toAccountId,
            data : bytes("")
        });
    }

    function encodeWithdrawalAction(
        uint256 _accountId,
        uint256 _marketId,
        IDolomiteStructs.AssetAmount memory _amount,
        address _toAccount
    ) internal pure returns (IDolomiteStructs.ActionArgs memory) {
        return IDolomiteStructs.ActionArgs({
            actionType: IDolomiteStructs.ActionType.Withdraw,
            accountId: _accountId,
            amount: _amount,
            primaryMarketId: _marketId,
            secondaryMarketId: 0,
            otherAddress: _toAccount,
            otherAccountId: 0,
            data: bytes("")
        });
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "../protocol/interfaces/IDolomiteStructs.sol";

import { Require } from "../protocol/lib/Require.sol";
import { TypesLib } from "../protocol/lib/TypesLib.sol";


/**
 * @title   AccountBalanceLib
 * @author  Dolomite
 *
 * @notice  Library contract that checks a user's balance after transaction to be non-negative
 */
library AccountBalanceLib {
    using TypesLib for IDolomiteStructs.Par;

    // ============ Types ============

    /// Checks that either BOTH, FROM, or TO accounts all have non-negative balances
    enum BalanceCheckFlag {
        Both,
        From,
        To,
        None
    }

    // ============ Constants ============

    bytes32 private constant _FILE = "AccountBalanceLib";

    // ============ Functions ============

    /**
     *  Checks that the account's balance is non-negative. Reverts if the check fails
     */
    function verifyBalanceIsNonNegative(
        IDolomiteMargin dolomiteMargin,
        address _accountOwner,
        uint256 _accountNumber,
        uint256 _marketId
    ) internal view {
        IDolomiteStructs.AccountInfo memory account = IDolomiteStructs.AccountInfo({
            owner: _accountOwner,
            number: _accountNumber
        });
        IDolomiteStructs.Par memory par = dolomiteMargin.getAccountPar(account, _marketId);
        Require.that(
            par.isPositive() || par.isZero(),
            _FILE,
            "account cannot go negative",
            _accountOwner,
            _accountNumber,
            _marketId
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   ChainHelperLib
 * @author  Dolomite
 *
 * @notice  Library contract that discovers which chain we're on
 */
library ChainHelperLib {

    // ============ Constants ============

    bytes32 private constant _FILE = "ChainHelperLib";
    uint256 private constant _ARBITRUM_ONE = 42161;
    uint256 private constant _ARBITRUM_SEPOLIA = 421614;

    // ============ Functions ============

    function isArbitrum(uint256 chainId) internal pure returns (bool) {
        return chainId == _ARBITRUM_ONE || chainId == _ARBITRUM_SEPOLIA;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteAccountRiskOverrideSetter
 * @author  Dolomite
 *
 * @notice  Interface that can be implemented by any contract that needs to implement risk overrides for an account.
 */
interface IDolomiteAccountRiskOverrideSetter {

    /**
     * @notice  Gets the risk overrides for a given account owner.
     *
     * @param  _accountOwner               The owner of the account whose risk override should be retrieved.
     * @return  marginRatioOverride         The margin ratio override for this account.
     * @return  liquidationSpreadOverride   The liquidation spread override for this account.
     */
    function getAccountRiskOverride(
        address _accountOwner
    )
    external
    view
    returns
    (
        IDolomiteStructs.Decimal memory marginRatioOverride,
        IDolomiteStructs.Decimal memory liquidationSpreadOverride
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteInterestSetter
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that for an interest setter that can be used to determine the interest
 *          rate of a market.
 */
interface IDolomiteInterestSetter {

    // ============ Enum ============

    enum InterestSetterType {
        None,
        Linear,
        DoubleExponential,
        Other
    }

    // ============ Structs ============

    struct InterestRate {
        uint256 value;
    }

    // ============ Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
    external
    view
    returns (InterestRate memory);

    function interestSetterType() external pure returns (InterestSetterType);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteMarginAdmin } from "./IDolomiteMarginAdmin.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteMargin
 * @author  Dolomite
 *
 * @notice  The interface for interacting with the main entry-point to DolomiteMargin
 */
interface IDolomiteMargin is IDolomiteMarginAdmin {

    // ==================================================
    // ================= Write Functions ================
    // ==================================================

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        OperatorArg[] calldata args
    ) external;

    // ==================================================
    // ================= Read Functions ================
    // ==================================================

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return the maximum amount of the market that can be supplied on Dolomite. Always 0 or positive.
     *
     * @param  marketId  The market to query
     * @return           The max amount of the market that can be supplied
     */
    function getMarketMaxWei(
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (MonetaryPrice memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (TotalPar memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IDolomitePriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Return true if this market can be removed and its ID can be recycled and reused
     *
     * @param  marketId  The market to query
     * @return           True if the market is recyclable
     */
    function getMarketIsRecyclable(
        uint256 marketId
    ) external view returns (bool);

    /**
     * Gets the recyclable markets, up to `n` length. If `n` is greater than the length of the list, 0's are returned
     * for the empty slots.
     *
     * @param  n    The number of markets to get, bounded by the linked list being smaller than `n`
     * @return      The list of recyclable markets, in the same order held by the linked list
     */
    function getRecyclableMarkets(
        uint256 n
    ) external view returns (uint[] memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (Market memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        Market memory,
        InterestIndex memory,
        MonetaryPrice memory,
        IDolomiteInterestSetter.InterestRate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        AccountInfo calldata account
    ) external view returns (AccountStatus);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the marketId for an account's market with a non-zero balance at the given index
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketWithBalanceAtIndex(
        AccountInfo calldata account,
        uint256 index
    ) external view returns (uint256);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithDebt(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        AccountInfo calldata account
    ) external view returns (uint[] memory, address[] memory, Par[] memory, Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    /**
     * Checks if the autoTrader can only be called invoked by a global operator
     *
     * @param  autoTrader    The trader that should be checked for special call privileges.
     */
    function getIsAutoTraderSpecial(address autoTrader) external view returns (bool);

    /**
     * @return The address that owns the DolomiteMargin protocol
     */
    function owner() external view returns (address);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (MonetaryValue memory);

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() external view returns (RiskParams memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (RiskLimits memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";
import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteMarginAdmin
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that can be called by the owner of DolomiteMargin.
 */
interface IDolomiteMarginAdmin is IDolomiteStructs {

    // ============ Token Functions ============

    /**
     * Withdraw an ERC20 token for which there is an associated market. Only excess tokens can be withdrawn. The number
     * of excess tokens is calculated by taking the current number of tokens held in DolomiteMargin, adding the number
     * of tokens owed to DolomiteMargin by borrowers, and subtracting the number of tokens owed to suppliers by
     * DolomiteMargin.
     */
    function ownerWithdrawExcessTokens(
        uint256 marketId,
        address recipient
    )
    external
    returns (uint256);

    /**
     * Withdraw an ERC20 token for which there is no associated market.
     */
    function ownerWithdrawUnsupportedTokens(
        address token,
        address recipient
    )
    external
    returns (uint256);

    // ============ Market Functions ============

    /**
     * Sets the number of non-zero balances an account may have within the same `accountIndex`. This ensures a user
     * cannot DOS the system by filling their account with non-zero balances (which linearly increases gas costs when
     * checking collateralization) and disallowing themselves to close the position, because the number of gas units
     * needed to process their transaction exceed the block's gas limit. In turn, this would  prevent the user from also
     * being liquidated, causing the all of the capital to be "stuck" in the position.
     *
     * Lowering this number does not "freeze" user accounts that have more than the new limit of balances, because this
     * variable is enforced by checking the users number of non-zero balances against the max or if it sizes down before
     * each transaction finishes.
     */
    function ownerSetAccountMaxNumberOfMarketsWithBalances(
        uint256 accountMaxNumberOfMarketsWithBalances
    )
    external;

    /**
     * Add a new market to DolomiteMargin. Must be for a previously-unsupported ERC20 token.
     */
    function ownerAddMarket(
        address token,
        IDolomitePriceOracle priceOracle,
        IDolomiteInterestSetter interestSetter,
        Decimal calldata marginPremium,
        Decimal calldata spreadPremium,
        uint256 maxWei,
        bool isClosing,
        bool isRecyclable
    )
    external;

    /**
     * Removes a market from DolomiteMargin, sends any remaining tokens in this contract to `salvager` and invokes the
     * recyclable callback
     */
    function ownerRemoveMarkets(
        uint[] calldata marketIds,
        address salvager
    )
    external;

    /**
     * Set (or unset) the status of a market to "closing". The borrowedValue of a market cannot increase while its
     * status is "closing".
     */
    function ownerSetIsClosing(
        uint256 marketId,
        bool isClosing
    )
    external;

    /**
     * Set the price oracle for a market.
     */
    function ownerSetPriceOracle(
        uint256 marketId,
        IDolomitePriceOracle priceOracle
    )
    external;

    /**
     * Set the interest-setter for a market.
     */
    function ownerSetInterestSetter(
        uint256 marketId,
        IDolomiteInterestSetter interestSetter
    )
    external;

    /**
     * Set a premium on the minimum margin-ratio for a market. This makes it so that any positions that include this
     * market require a higher collateralization to avoid being liquidated.
     */
    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal calldata marginPremium
    )
    external;

    function ownerSetMaxWei(
        uint256 marketId,
        uint256 maxWei
    )
    external;

    /**
     * Set a premium on the liquidation spread for a market. This makes it so that any liquidations that include this
     * market have a higher spread than the global default.
     */
    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal calldata spreadPremium
    )
    external;

    // ============ Risk Functions ============

    /**
     * Set the global minimum margin-ratio that every position must maintain to prevent being liquidated.
     */
    function ownerSetMarginRatio(
        Decimal calldata ratio
    )
    external;

    /**
     * Set the global liquidation spread. This is the spread between oracle prices that incentivizes the liquidation of
     * risky positions.
     */
    function ownerSetLiquidationSpread(
        Decimal calldata spread
    )
    external;

    /**
     * Set the global earnings-rate variable that determines what percentage of the interest paid by borrowers gets
     * passed-on to suppliers.
     */
    function ownerSetEarningsRate(
        Decimal calldata earningsRate
    )
    external;

    /**
     * Set the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     */
    function ownerSetMinBorrowedValue(
        MonetaryValue calldata minBorrowedValue
    )
    external;

    // ============ Global Operator Functions ============

    /**
     * Approve (or disapprove) an address that is permissioned to be an operator for all accounts in DolomiteMargin.
     * Intended only to approve smart-contracts.
     */
    function ownerSetGlobalOperator(
        address operator,
        bool approved
    )
    external;

    /**
     * Approve (or disapprove) an auto trader that can only be called by a global operator. IE for expirations
     */
    function ownerSetAutoTraderSpecial(
        address autoTrader,
        bool special
    )
    external;
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteMarginExchangeWrapper
 * @author  dYdX
 *
 * @notice  Interface that Exchange Wrappers for DolomiteMargin must implement in order to trade ERC20 tokens with
 *          external protocols.
 */
interface IDolomiteMarginExchangeWrapper {

    // ============ Public Functions ============

    /**
     * Exchange some amount of inputToken for outputToken.
     *
     * @param  _tradeOriginator Address of the initiator of the trade (however, this value cannot always be trusted as
     *                          it is set at the discretion of the msg.sender)
     * @param  _receiver        Address to set allowance on once the trade has completed
     * @param  _outputToken     The token to receive (target asset; IE path[path.length - 1])
     * @param  _inputToken      The token to pay (originator asset; IE path[0])
     * @param  _inputAmount     Amount of `inputToken` being paid to this wrapper
     * @param  _orderData       Arbitrary bytes data for any information to pass to the exchange
     * @return                  The amount of outputToken to be received by DolomiteMargin
     */
    function exchange(
        address _tradeOriginator,
        address _receiver,
        address _outputToken,
        address _inputToken,
        uint256 _inputAmount,
        bytes calldata _orderData
    )
    external
    returns (uint256);

    /**
     * Get amount of `inputToken` required to buy a certain amount of `outputToken` for a given trade.
     * Should match the `inputToken` amount used in exchangeForAmount. If the order cannot provide
     * exactly `_desiredOutputToken`, then it must return the price to buy the minimum amount greater
     * than `_desiredOutputToken`
     *
     * @param  _inputToken          The token to pay to this contract (originator asset; IE path[0])
     * @param  _outputToken         The token to receive by DolomiteMargin (target asset; IE path[path.length - 1])
     * @param  _desiredInputAmount  Amount of `_inputToken` requested
     * @param  _orderData           Arbitrary bytes data for any information to pass to the exchange
     * @return                      Amount of `_inputToken` the needed to complete the exchange
     */
    function getExchangeCost(
        address _inputToken,
        address _outputToken,
        uint256 _desiredInputAmount,
        bytes calldata _orderData
    )
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteOracleSentinel
 * @author  Dolomite
 *
 * Interface that Dolomite pings to check if the Blockchain or L2 is alive, if liquidations should be processed, and if
 * markets should are in size-down only mode.
 */
interface IDolomiteOracleSentinel {

    // ============ Events ============

    event GracePeriodSet(
        uint256 gracePeriod
    );

    // ============ Functions ============

    /**
     * @dev Allows the owner to set the grace period duration, which specifies how long the system will disallow
     *      liquidations after sequencer is back online. Only callable by the owner.
     *
     * @param  _gracePeriod  The new duration of the grace period
     */
    function ownerSetGracePeriod(
        uint256 _gracePeriod
    )
    external;

    /**
     * @return True if new borrows should be allowed, false otherwise
     */
    function isBorrowAllowed() external view returns (bool);

    /**
     * @return True if liquidations should be allowed, false otherwise
     */
    function isLiquidationAllowed() external view returns (bool);

    /**
     * @return  The duration between when the feed comes back online and when the system will allow liquidations to be
     *          processed normally
     */
    function gracePeriod() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomitePriceOracle
 * @author  Dolomite
 *
 * @notice  Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
interface IDolomitePriceOracle {

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^(36 - decimals).
     *                So a USD-stable coin with 6 decimal places would return `price * 10^30`.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
    external
    view
    returns (IDolomiteStructs.MonetaryPrice memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteAccountRiskOverrideSetter } from "./IDolomiteAccountRiskOverrideSetter.sol";
import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteOracleSentinel } from "./IDolomiteOracleSentinel.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteStructs
 * @author  Dolomite
 *
 * @notice  This interface defines the structs used by DolomiteMargin
 */
interface IDolomiteStructs {

    // ========================= Enums =========================

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    // ========================= Structs =========================

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    /**
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum AccountStatus {
        Normal,
        Liquid,
        Vapor
    }

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Decimal {
        uint256 value;
    }

    struct InterestIndex {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    struct Market {
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        TotalPar totalPar;

        // Interest index of the market
        InterestIndex index;

        // Contract address of the price oracle for this market
        IDolomitePriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IDolomiteInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal spreadPremium;

        // The maximum amount that can be held by the external. This allows the external to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Wei maxWei;
    }

    struct MarketV2 {
        // Contract address of the associated ERC20 token
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Total aggregated supply and borrow amount of the entire market
        TotalPar totalPar;

        // Interest index of the market
        InterestIndex index;

        // Contract address of the price oracle for this market
        IDolomitePriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IDolomiteInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal liquidationSpreadPremium;

        // The maximum amount that can be held by the protocol. This allows the protocol to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Wei maxSupplyWei;

        // The maximum amount that can be borrowed by the protocol. This allows the protocol to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be greater than 0.
        Wei maxBorrowWei;

        // The percentage of interest paid that is passed along from borrowers to suppliers. Setting this to 0 will
        // default to RiskParams.earningsRate.
        Decimal earningsRateOverride;
    }

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct MonetaryPrice {
        uint256 value;
    }

    struct MonetaryValue {
        uint256 value;
    }

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    struct Par {
        bool sign;
        uint128 value;
    }

    struct RiskLimits {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    struct RiskLimitsV2 {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 liquidationSpreadPremiumMax;
        // The highest that the borrow interest rate can ever be. If the rate returned is ever higher, the rate is
        // capped at this value instead of reverting. The goal is to keep Dolomite operational under all circumstances
        // instead of inadvertently DOS'ing the protocol.
        uint96 interestRateMax;
        // The highest that the minBorrowedValue can be. This is the minimum amount of value that must be borrowed.
        // Typically a value of $100 (100 * 1e18) is more than sufficient.
        uint128 minBorrowedValueMax;
    }

    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        MonetaryValue minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParamsV2 {
        // Required ratio of over-collateralization
        Decimal marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        MonetaryValue minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;

        // The oracle sentinel used to disable borrowing/liquidations if the sequencer goes down
        IDolomiteOracleSentinel oracleSentinel;

        // The gas limit used for making callbacks via `IExternalCallback::onInternalBalanceChange` to smart contract
        // wallets. Setting to 0 will effectively disable callbacks; setting it super large is not desired since it
        // could lead to DOS attacks on the protocol; however, hard coding a max value isn't preferred since some chains
        // can calculate gas usage differently (like ArbGas before Arbitrum rolled out nitro)
        uint256 callbackGasLimit;

        // Certain addresses are allowed to borrow with different LTV requirements. When an account's risk is overrode,
        // the global risk parameters are ignored and the account's risk parameters are used instead.
        mapping(address => IDolomiteAccountRiskOverrideSetter) accountRiskOverrideSetterMap;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct TotalWei {
        uint128 borrow;
        uint128 supply;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title   IWETH
 * @author  Dolomite
 *
 * @notice  An interface for the WETH contract for wrapping and tokenizing ETH.
 */
interface IWETH is IERC20 {

    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Require } from "./Require.sol";


/**
 * @title   DolomiteMarginMath
 * @author  dYdX
 *
 * @notice  Library for non-standard Math functions
 */
library DolomiteMarginMath {

    // ============ Constants ============

    bytes32 internal constant _FILE = "DolomiteMarginMath";

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        return target * numerator / denominator;
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.1 rounds to 102
     * instead of 101.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            return 0;
        }
        return (((target * numerator) - 1) / denominator) + 1;
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.5 rounds to 102
     * instead of 101.
     */
    function getPartialRoundHalfUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            return 0;
        }
        return (((target * numerator) + (denominator / 2)) / denominator);
    }

    function to128(
        uint256 number
    )
    internal
    pure
    returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint128",
            number
        );
        return result;
    }

    function to96(
        uint256 number
    )
    internal
    pure
    returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint96",
            number
        );
        return result;
    }

    function to32(
        uint256 number
    )
    internal
    pure
    returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            _FILE,
            "Unsafe cast to uint32",
            number
        );
        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   Require
 * @author  dYdX
 *
 * @notice  Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 private constant _ASCII_ZERO = 48; // '0'
    uint256 private constant _ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 private constant _ASCII_LOWER_EX = 120; // 'x'
    bytes2 private constant _COLON = 0x3a20; // ': '
    bytes2 private constant _COMMA = 0x2c20; // ', '
    bytes2 private constant _LPAREN = 0x203c; // ' <'
    bytes1 private constant _RPAREN = 0x3e; // '>'
    uint256 private constant _FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason)
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    internal
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solhint-disable-next-line no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringifyFunctionSelector(
        bytes4 input
    )
    internal
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(bytes32(input) >> 224);

        // bytes4 are "0x" followed by 4 bytes of data which take up 2 characters each
        bytes memory result = new bytes(10);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 4; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[9 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[8 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // take last decimal digit
            bstr[i] = bytes1(uint8(_ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function _stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(uint160(input));

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _char(
        uint256 input
    )
    private
    pure
    returns (bytes1)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return bytes1(uint8(input + _ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return bytes1(uint8(input + _ASCII_RELATIVE_ZERO));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { DolomiteMarginMath } from "./DolomiteMarginMath.sol";
import { IDolomiteStructs } from "../interfaces/IDolomiteStructs.sol";


/**
 * @title   TypesLib
 * @author  dYdX
 *
 * @notice  Library for interacting with the basic structs used in DolomiteMargin
 */
library TypesLib {
    using DolomiteMarginMath for uint256;

    // ============ Par (Principal Amount) ============

    function zeroPar()
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return IDolomiteStructs.Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        IDolomiteStructs.Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = a.value + b.value;
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = a.value - b.value;
            } else {
                result.sign = b.sign;
                result.value = b.value - a.value;
            }
        }
        return result;
    }

    function equals(
        IDolomiteStructs.Par memory a,
        IDolomiteStructs.Par memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (IDolomiteStructs.Par memory)
    {
        return IDolomiteStructs.Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }

    function isLessThanZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value > 0 && !a.sign;
    }

    function isGreaterThanOrEqualToZero(
        IDolomiteStructs.Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return isZero(a) || a.sign;
    }

    // ============ Wei (Token Amount) ============

    function zeroWei()
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return IDolomiteStructs.Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        IDolomiteStructs.Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = a.value + b.value;
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = a.value - b.value;
            } else {
                result.sign = b.sign;
                result.value = b.value - a.value;
            }
        }
        return result;
    }

    function equals(
        IDolomiteStructs.Wei memory a,
        IDolomiteStructs.Wei memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (IDolomiteStructs.Wei memory)
    {
        return IDolomiteStructs.Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        IDolomiteStructs.Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/helpers/OnlyDolomiteMargin.sol";
import { IDolomiteRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteRegistry.sol";
import { AccountActionLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountActionLib.sol";
import { AccountBalanceLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountBalanceLib.sol";
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { TypesLib } from "@dolomite-exchange/modules-base/contracts/protocol/lib/TypesLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IEmitter } from "./interfaces/IEmitter.sol";
import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";


/**
 * @title   Emitter
 * @author  Dolomite
 *
 * An implementation of the IEmitter interface that grants users oARB rewards for staking assets
 * WARNING: THIS CODE HAS NOT BEEN THOROUGHLY TESTED AND IS NOT PRODUCTION READY
 */
contract Emitter is OnlyDolomiteMargin, IEmitter {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using TypesLib for IDolomiteStructs.Par;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "Emitter";
    uint256 private constant _DEFAULT_ACCOUNT_NUMBER = 0;
    uint256 private constant _SCALE = 1e18;

    // ===================================================
    // ==================== State Variables ====================
    // ===================================================

    IDolomiteRegistry public immutable DOLOMITE_REGISTRY; // solhint-disable-line

    EnumerableSet.UintSet private _pools;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => PoolInfo) public poolInfo;

    IERC20Mintable public oARB;
    uint256 public oARBPerSecond;
    uint256 public totalAllocPoint;
    uint256 public startTime;

    // ==================================================================
    // ======================= Constructor =======================
    // ==================================================================

    constructor(
        address _dolomiteMargin,
        address _dolomiteRegistry,
        address _oARB,
        uint256 _oARBPerSecond,
        uint256 _startTime
    ) OnlyDolomiteMargin(_dolomiteMargin) {
        DOLOMITE_REGISTRY = IDolomiteRegistry(_dolomiteRegistry);
        oARB = IERC20Mintable(_oARB);
        oARBPerSecond = _oARBPerSecond;
        startTime = _startTime;
    }

    // ==================================================================
    // ======================= External Functions =======================
    // ==================================================================

    function deposit(
        uint256 _fromAccountNumber,
        uint256 _marketId,
        uint256 _amountWei
    ) external {
        PoolInfo storage pool = poolInfo[_marketId];
        UserInfo storage user = userInfo[_marketId][msg.sender];
        IDolomiteStructs.AccountInfo memory info = IDolomiteStructs.AccountInfo({
             owner: address(this),
             number: uint256(uint160(msg.sender))
        });

        Require.that(
            _pools.contains(_marketId),
            _FILE,
            "Pool not initialized"
        );
        Require.that(
            _amountWei > 0,
            _FILE,
            "Invalid amount"
        );

        updatePool(_marketId);
        // Reset reward debt in the case of new campaign
        if (user.lastUpdateTime < startTime) {
            user.rewardDebt = 0;
        }

        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accOARBPerShare / _SCALE - user.rewardDebt;
            oARB.mint(pending);
            IERC20(address(oARB)).safeTransfer(msg.sender, pending);
        }

        IDolomiteStructs.Par memory beforeAccountPar = DOLOMITE_MARGIN().getAccountPar(info, _marketId);
        _transfer(
            /* _fromAccount = */ msg.sender,
            /* _fromAccountNumber = */ _fromAccountNumber,
            /* _toAccount = */ address(this),
            /* _toAccountNumber = */ uint256(uint160(msg.sender)),
            /* _marketId = */ _marketId,
            /* _amountWei */ _amountWei
        );
        IDolomiteStructs.Par memory changeAccountPar =
            DOLOMITE_MARGIN().getAccountPar(info, _marketId).sub(beforeAccountPar);
        assert(changeAccountPar.sign);

        pool.totalPar += changeAccountPar.value;
        user.amount += changeAccountPar.value;
        user.rewardDebt = user.amount * pool.accOARBPerShare / _SCALE;
        user.lastUpdateTime = block.timestamp;

        emit Deposit(msg.sender, _marketId, _amountWei);
    }

    function withdraw(
        uint256 _marketId,
        uint256 _amountWei
    ) external {
        PoolInfo storage pool = poolInfo[_marketId];
        UserInfo storage user = userInfo[_marketId][msg.sender];
        IDolomiteStructs.AccountInfo memory info = IDolomiteStructs.AccountInfo({
            owner: address(this),
            number: uint256(uint160(msg.sender))
        });

        Require.that(
            _pools.contains(_marketId),
            _FILE,
            "Pool not initialized"
        );

        uint256 withdrawalAmount;
        if (_amountWei == type(uint256).max) {
            withdrawalAmount = (DOLOMITE_MARGIN().getAccountWei(info, _marketId)).value;
        }
        else {
            Require.that(
                (DOLOMITE_MARGIN().getAccountWei(info, _marketId)).value >= _amountWei,
                _FILE,
                "Insufficient balance"
            );
            withdrawalAmount = _amountWei;
        }


        updatePool(_marketId);
        if (user.lastUpdateTime < startTime) {
            user.rewardDebt = 0;
        }

        uint256 pending = user.amount * pool.accOARBPerShare / _SCALE - user.rewardDebt;
        oARB.mint(pending);
        IERC20(address(oARB)).safeTransfer(msg.sender, pending);

        // We calculate the change in par value based on the transfer of the wei amount
        if(withdrawalAmount > 0) {
            IDolomiteStructs.Par memory beforeAccountPar = DOLOMITE_MARGIN().getAccountPar(info, _marketId);
            _transfer(
                /* _fromAccount = */ address(this),
                /* _fromAccountNumber = */ uint256(uint160(msg.sender)),
                /* _toAccount = */ msg.sender,
                /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
                /* _marketId = */ _marketId,
                /* _amountWei */ withdrawalAmount
            );
            IDolomiteStructs.Par memory changeAccountPar =
                beforeAccountPar.sub(DOLOMITE_MARGIN().getAccountPar(info, _marketId));
            assert(changeAccountPar.sign);

            user.amount = user.amount - changeAccountPar.value;
            pool.totalPar -= changeAccountPar.value;
        }

        user.rewardDebt = user.amount * pool.accOARBPerShare / _SCALE;
        user.lastUpdateTime = block.timestamp;
        emit Withdraw(msg.sender, _marketId, withdrawalAmount);
    }

    function emergencyWithdraw(uint256 _marketId) external {
        PoolInfo storage pool = poolInfo[_marketId];
        UserInfo storage user = userInfo[_marketId][msg.sender];
        IDolomiteStructs.AccountInfo memory info = IDolomiteStructs.AccountInfo({
            owner: address(this),
            number: uint256(uint160(msg.sender))
        });

        uint256 amountWei = (DOLOMITE_MARGIN().getAccountWei(info, _marketId)).value;
        Require.that(
            amountWei > 0,
            _FILE,
            "Insufficient balance"
        );
        user.amount = 0;
        user.rewardDebt = 0;
        user.lastUpdateTime = 0;

        IDolomiteStructs.Par memory beforeAccountPar = DOLOMITE_MARGIN().getAccountPar(info, _marketId);
        _transfer(
            /* _fromAccount = */ address(this),
            /* _fromAccountNumber = */ uint256(uint160(msg.sender)),
            /* _toAccount = */ msg.sender,
            /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
            /* _marketId = */ _marketId,
            /* _amountWei */ amountWei
        );
        IDolomiteStructs.Par memory changeAccountPar =
            beforeAccountPar.sub(DOLOMITE_MARGIN().getAccountPar(info, _marketId));
        assert(changeAccountPar.sign);

        pool.totalPar -= changeAccountPar.value;
        emit EmergencyWithdraw(msg.sender, _marketId, amountWei);
    }

    function massUpdatePools() public {
        uint256 len = _pools.length();
        for (uint256 i; i < len; i++) {
            updatePool(_pools.at(i));
        }
    }

    function updatePool(uint256 _marketId) public {
        PoolInfo storage pool = poolInfo[_marketId];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        uint256 supply = pool.totalPar;
        if (supply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 reward = oARBPerSecond * pool.allocPoint * (block.timestamp - pool.lastRewardTime) / totalAllocPoint;
        pool.accOARBPerShare = pool.accOARBPerShare + reward * _SCALE / supply;
        pool.lastRewardTime = block.timestamp;
    }

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    function ownerAddPool( // solhint-disable-line ordering
        uint256 _marketId,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            !_pools.contains(_marketId),
            _FILE,
            "Pool already exists"
        );
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo[_marketId] =
            PoolInfo({
                marketId: _marketId,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accOARBPerShare: 0,
                totalPar: 0
            });
        _pools.add(_marketId);
    }

    function ownerSetPool(
        uint256 _marketId,
        uint256 _allocPoint
    ) external onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            _pools.contains(_marketId),
            _FILE,
            "Pool not initialized"
        );
        totalAllocPoint += _allocPoint - poolInfo[_marketId].allocPoint;
        poolInfo[_marketId].allocPoint = _allocPoint;
    }

    function ownerCreateNewCampaign(
        uint256 _startTime,
        IERC20Mintable _oARB
    ) external onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            _startTime >= block.timestamp,
            _FILE,
            "Invalid startTime"
        );
        startTime = _startTime;
        oARB = _oARB;

        uint256 len = _pools.length();
        for (uint256 i; i < len; i++) {
            poolInfo[_pools.at(i)].lastRewardTime = startTime;
            poolInfo[_pools.at(i)].accOARBPerShare = 0;
        }
    }

    function ownerSetOARBPerSecond(
        uint256 _oARBPerSecond
    ) external onlyDolomiteMarginOwner(msg.sender) {
        massUpdatePools();
        oARBPerSecond = _oARBPerSecond;
    }

    // ==================================================================
    // ======================= Internal Functions =======================
    // ==================================================================

    function _transfer(
        address _fromAccount,
        uint256 _fromAccountNumber,
        address _toAccount,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amount
    ) internal {
        AccountActionLib.transfer(
            DOLOMITE_MARGIN(),
            _fromAccount,
            _fromAccountNumber,
            _toAccount,
            _toAccountNumber,
            _marketId,
            IDolomiteStructs.AssetDenomination.Wei,
            _amount,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/helpers/OnlyDolomiteMargin.sol";
import { IDolomiteRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteRegistry.sol";
import { AccountActionLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountActionLib.sol";
import { AccountBalanceLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountBalanceLib.sol";
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { TypesLib } from "@dolomite-exchange/modules-base/contracts/protocol/lib/TypesLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IEmitterMultipleRewardTokens } from "./interfaces/IEmitterMultipleRewardTokens.sol";
import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";
import { IStorageVault } from "./interfaces/IStorageVault.sol";


/**
 * @title   EmitterMultipleRewardTokens
 * @author  Dolomite
 *
 * An implementation of the IEmitterMultipleREwardTokens interface
 * that grants users oARB rewards for staking assets
 * WARNING: THIS CODE HAS NOT BEEN THOROUGHLY TESTED AND IS NOT PRODUCTION READY
 */
contract EmitterMultipleRewardTokens is OnlyDolomiteMargin, IEmitterMultipleRewardTokens {
    using SafeERC20 for IERC20Mintable;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using TypesLib for IDolomiteStructs.Par;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "Emitter";
    uint256 private constant _DEFAULT_ACCOUNT_NUMBER = 0;
    uint256 private constant _SCALE = 1e18;

    // ===================================================
    // ==================== State Variables ====================
    // ===================================================

    IDolomiteRegistry public immutable DOLOMITE_REGISTRY; // solhint-disable-line

    EnumerableSet.UintSet private _pools;
    EnumerableSet.AddressSet private _rewardTokens;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => PoolInfo) public poolInfo;
    mapping(address => RewardToken) public rewardTokenInfo;

    uint256 public rewardTokenPerSecond;
    uint256 public totalAllocPoint;
    uint256 public startTime;

    // ==================================================================
    // ======================= Constructor =======================
    // ==================================================================

    constructor(
        address _dolomiteMargin,
        address _dolomiteRegistry,
        uint256 _rewardTokenPerSecond,
        uint256 _startTime
    ) OnlyDolomiteMargin(_dolomiteMargin) {
        DOLOMITE_REGISTRY = IDolomiteRegistry(_dolomiteRegistry);
        rewardTokenPerSecond = _rewardTokenPerSecond;
        startTime = _startTime;
    }

    // ==================================================================
    // ======================= External Functions =======================
    // ==================================================================

    function deposit(
        uint256 _fromAccountNumber,
        uint256 _marketId,
        uint256 _amountWei
    ) external {
        PoolInfo storage pool = poolInfo[_marketId];
        UserInfo storage user = userInfo[_marketId][msg.sender];
        IDolomiteStructs.AccountInfo memory info = IDolomiteStructs.AccountInfo({
             owner: address(this),
             number: uint256(uint160(msg.sender))
        });

        Require.that(
            _pools.contains(_marketId),
            _FILE,
            "Pool not initialized"
        );
        Require.that(
            _amountWei > 0,
            _FILE,
            "Invalid amount"
        );

        // Transfer _amountWei to this contract
        IDolomiteStructs.Par memory beforeAccountPar = DOLOMITE_MARGIN().getAccountPar(info, _marketId);
        _transfer(
            /* _fromAccount = */ msg.sender,
            /* _fromAccountNumber = */ _fromAccountNumber,
            /* _toAccount = */ address(this),
            /* _toAccountNumber = */ uint256(uint160(msg.sender)),
            /* _marketId = */ _marketId,
            /* _amountWei */ _amountWei
        );
        IDolomiteStructs.Par memory changeAccountPar =
            DOLOMITE_MARGIN().getAccountPar(info, _marketId).sub(beforeAccountPar);
        assert(changeAccountPar.sign);

        uint256 cachedAmount = user.amount;
        updatePool(_marketId);
        pool.totalPar += changeAccountPar.value;
        user.amount += changeAccountPar.value;

        uint256 len = _rewardTokens.length();
        if (cachedAmount > 0) {
            for (uint256 i; i < len; i++) {
                RewardToken memory rewardToken = rewardTokenInfo[_rewardTokens.at(i)];
                uint256 pending =
                    (cachedAmount * pool.accRewardTokenPerShares[rewardToken.token] / _SCALE)
                        - user.rewardDebts[rewardToken.token];
                user.rewardDebts[rewardToken.token] =
                    user.amount * pool.accRewardTokenPerShares[rewardToken.token] / _SCALE;

                IStorageVault(rewardToken.tokenStorageVault).pullTokensFromVault(pending);
                IERC20(rewardToken.token).transfer(msg.sender, pending);
            }
        }

        emit Deposit(msg.sender, _marketId, _amountWei);
    }

    function withdraw(
        uint256 _marketId,
        uint256 _amountWei
    ) external {
        PoolInfo storage pool = poolInfo[_marketId];
        UserInfo storage user = userInfo[_marketId][msg.sender];
        IDolomiteStructs.AccountInfo memory info = IDolomiteStructs.AccountInfo({
            owner: address(this),
            number: uint256(uint160(msg.sender))
        });

        Require.that(
            _pools.contains(_marketId),
            _FILE,
            "Pool not initialized"
        );

        uint256 withdrawalAmount;
        if (_amountWei == type(uint256).max) {
            withdrawalAmount = (DOLOMITE_MARGIN().getAccountWei(info, _marketId)).value;
        }
        else {
            Require.that(
                (DOLOMITE_MARGIN().getAccountWei(info, _marketId)).value >= _amountWei,
                _FILE,
                "Insufficient balance"
            );
            withdrawalAmount = _amountWei;
        }

        // We calculate the change in par value based on the transfer of the wei amount
        updatePool(_marketId);

        uint256 cachedAmount = user.amount;
        if(withdrawalAmount > 0) {
            IDolomiteStructs.Par memory beforeAccountPar = DOLOMITE_MARGIN().getAccountPar(info, _marketId);
            _transfer(
                /* _fromAccount = */ address(this),
                /* _fromAccountNumber = */ uint256(uint160(msg.sender)),
                /* _toAccount = */ msg.sender,
                /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
                /* _marketId = */ _marketId,
                /* _amountWei */ withdrawalAmount
            );
            IDolomiteStructs.Par memory changeAccountPar =
                beforeAccountPar.sub(DOLOMITE_MARGIN().getAccountPar(info, _marketId));
            assert(changeAccountPar.sign);

            user.amount = user.amount - changeAccountPar.value;
            pool.totalPar -= changeAccountPar.value;
        }

        uint256 len = _rewardTokens.length();
        if (cachedAmount > 0) {
            for (uint256 i; i < len; i++) {
                RewardToken memory rewardToken = rewardTokenInfo[_rewardTokens.at(i)];
                uint256 pending =
                    (cachedAmount * pool.accRewardTokenPerShares[rewardToken.token] / _SCALE)
                        - user.rewardDebts[rewardToken.token];
                user.rewardDebts[rewardToken.token] =
                    user.amount * pool.accRewardTokenPerShares[rewardToken.token] / _SCALE;

                IStorageVault(rewardToken.tokenStorageVault).pullTokensFromVault(pending);
                IERC20(rewardToken.token).transfer(msg.sender, pending);
            }
        }

        emit Withdraw(msg.sender, _marketId, withdrawalAmount);
    }

    function emergencyWithdraw(uint256 _marketId) external {
        PoolInfo storage pool = poolInfo[_marketId];
        UserInfo storage user = userInfo[_marketId][msg.sender];
        IDolomiteStructs.AccountInfo memory info = IDolomiteStructs.AccountInfo({
            owner: address(this),
            number: uint256(uint160(msg.sender))
        });

        uint256 amountWei = (DOLOMITE_MARGIN().getAccountWei(info, _marketId)).value;
        Require.that(
            amountWei > 0,
            _FILE,
            "Insufficient balance"
        );

        user.amount = 0;
        uint256 len = _rewardTokens.length();
        for (uint256 i; i < len; i++) {
            RewardToken memory rewardToken = rewardTokenInfo[_rewardTokens.at(i)];
            user.rewardDebts[rewardToken.token] = 0;
        }

        IDolomiteStructs.Par memory beforeAccountPar = DOLOMITE_MARGIN().getAccountPar(info, _marketId);
        _transfer(
            /* _fromAccount = */ address(this),
            /* _fromAccountNumber = */ uint256(uint160(msg.sender)),
            /* _toAccount = */ msg.sender,
            /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
            /* _marketId = */ _marketId,
            /* _amountWei */ amountWei
        );
        IDolomiteStructs.Par memory changeAccountPar =
            beforeAccountPar.sub(DOLOMITE_MARGIN().getAccountPar(info, _marketId));
        assert(changeAccountPar.sign);

        pool.totalPar -= changeAccountPar.value;
        emit EmergencyWithdraw(msg.sender, _marketId, amountWei);
    }

    function massUpdatePools() public {
        uint256 len = _pools.length();
        for (uint256 i; i < len; i++) {
            updatePool(_pools.at(i));
        }
    }

    function updatePool(uint256 _marketId) public {
        PoolInfo storage pool = poolInfo[_marketId];
        uint256 supply = pool.totalPar;

        uint256 len = _rewardTokens.length();
        for (uint256 i; i < len; i++) {
            RewardToken memory rewardToken = rewardTokenInfo[_rewardTokens.at(i)];

            if (block.timestamp <= pool.lastRewardTimes[rewardToken.token]) {
                return;
            }

            if(supply == 0) {
                pool.lastRewardTimes[rewardToken.token] = block.timestamp;
                return;
            }

            if (rewardToken.isAccruing) {
                uint256 reward =
                    rewardTokenPerSecond * pool.allocPoint * (block.timestamp - pool.lastRewardTimes[rewardToken.token])
                        / totalAllocPoint;
                pool.accRewardTokenPerShares[rewardToken.token]
                    = pool.accRewardTokenPerShares[rewardToken.token] + (reward * _SCALE / supply);
                pool.lastRewardTimes[rewardToken.token] = block.timestamp;
            }
        }
    }

    function userRewardDebt( // solhint-disable-line ordering
        uint256 _marketId,
        address _user,
        address _rewardToken
    )
    external
    view
    returns (uint256) {
        return userInfo[_marketId][_user].rewardDebts[_rewardToken];
    }

    function poolLastRewardTime(uint256 _marketId, address _rewardToken)
    external
    view
    returns (uint256) {
        return poolInfo[_marketId].lastRewardTimes[_rewardToken];
    }

    function poolAccRewardTokenPerShares(uint256 _marketId, address _rewardToken)
    external
    view
    returns (uint256) {
        return poolInfo[_marketId].accRewardTokenPerShares[_rewardToken];
    }

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    function ownerAddRewardToken(
        address _token,
        address _tokenStorageVault,
        bool _isAccruing
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            !_rewardTokens.contains(_token),
            _FILE,
            "Reward token already exists"
        );

        rewardTokenInfo[_token] = RewardToken({
            token: _token,
            tokenStorageVault: _tokenStorageVault,
            isAccruing: _isAccruing
        });
        _rewardTokens.add(_token);
        _updateLastRewardTimesForRewardToken(_token);
    }

    function ownerEnableRewardToken(
        address _token
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            _rewardTokens.contains(_token),
            _FILE,
            "Reward token does not exist"
        );

        RewardToken storage rewardToken = rewardTokenInfo[_token];
        rewardToken.isAccruing = true;
        _updateLastRewardTimesForRewardToken(_token);
    }

    function ownerDisableRewardToken(
        address _token
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            _rewardTokens.contains(_token),
            _FILE,
            "Reward token does not exist"
        );
        massUpdatePools();
        RewardToken storage rewardToken = rewardTokenInfo[_token];
        rewardToken.isAccruing = false;
    }

    function ownerRemoveRewardToken(
        address _token
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            _rewardTokens.contains(_token),
            _FILE,
            "Reward token does not exist"
        );
        delete rewardTokenInfo[_token];
        _rewardTokens.remove(_token);
    }

    function ownerAddPool(
        uint256 _marketId,
        uint256 _allocPoint,
        bool _withUpdate
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            !_pools.contains(_marketId),
            _FILE,
            "Pool already exists"
        );
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;

        PoolInfo storage pool = poolInfo[_marketId];
        pool.marketId = _marketId;
        pool.allocPoint = _allocPoint;

        uint256 len = _rewardTokens.length();
        for (uint256 i; i < len; i++) {
            RewardToken memory rewardToken = rewardTokenInfo[_rewardTokens.at(i)];
            pool.lastRewardTimes[rewardToken.token] = lastRewardTime;
        }
        _pools.add(_marketId);
    }

    function ownerSetPool(
        uint256 _marketId,
        uint256 _allocPoint
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        Require.that(
            _pools.contains(_marketId),
            _FILE,
            "Pool not initialized"
        );
        totalAllocPoint += _allocPoint - poolInfo[_marketId].allocPoint;
        poolInfo[_marketId].allocPoint = _allocPoint;
    }

    function ownerSetRewardTokenPerSecond(
        uint256 _rewardTokenPerSecond
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        massUpdatePools();
        rewardTokenPerSecond = _rewardTokenPerSecond;
    }

    // ==================================================================
    // ======================= Internal Functions =======================
    // ==================================================================

    function _transfer(
        address _fromAccount,
        uint256 _fromAccountNumber,
        address _toAccount,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amount
    ) internal {
        AccountActionLib.transfer(
            DOLOMITE_MARGIN(),
            _fromAccount,
            _fromAccountNumber,
            _toAccount,
            _toAccountNumber,
            _marketId,
            IDolomiteStructs.AssetDenomination.Wei,
            _amount,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function _updateLastRewardTimesForRewardToken(
        address _rewardToken
    ) internal {
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;

        uint256 len = _pools.length();
        for (uint256 i; i < len; i++) {
            PoolInfo storage pool = poolInfo[_pools.at(i)];
            pool.lastRewardTimes[_rewardToken] = lastRewardTime;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20Mintable } from "./IERC20Mintable.sol";


/**
 * @title   IEmitter
 * @author  Dolomite
 *
 * Interface for an emitter that is inspired by MasterChef to reward oARB tokens
 */
interface IEmitter {

    // =================================================
    // ==================== Structs ====================
    // =================================================

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastUpdateTime;
    }

    struct PoolInfo {
        uint256 marketId;
        uint256 totalPar;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accOARBPerShare;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    event Deposit(address indexed user, uint256 indexed marketId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed marketId, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed marketId, uint256 amount);

    // ======================================================
    // ================== User Functions ===================
    // ======================================================

    /**
     * @notice  Deposit tokens to Emitter for oARB allocation
     *
     * @param  _fromAccountNumber   The account number to tranfer funds from
     * @param  _marketId            The market id of the token to deposit
     * @param  _amountWei           The amount wei of the token to deposit
     */
    function deposit(uint256 _fromAccountNumber, uint256 _marketId, uint256 _amountWei) external;

    /**
     * @notice  Withdraws tokens from the Emitter contract
     *
     * @param  _marketId        The market id of the token to deposit
     * @param  _amountWei       The amount of the token to withdraw
     */
    function withdraw(uint256 _marketId, uint256 _amountWei) external;

    /**
     * @notice  Emergency withdraws tokens from the Emitter contract
     *          WARNING: This will forfeit all vesting progress
     *
     * @param  _marketId        The market id of the token to deposit
     */
    function emergencyWithdraw(uint256 _marketId) external;

    /**
     * @notice  Update reward variables of all pools to be up-to-date
     *
     */
    function massUpdatePools() external;

    /**
     * @notice  Update reward variables of the given pool to be up-to-date
     *
     * @param  _marketId    The market id of the pool to update
     */
    function updatePool(uint256 _marketId) external;

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    /**
     * @notice  Adds a new market id to the pool. Can only be called by the owner.
     *
     * @param  _marketId    The id of the position that is fully vested
     * @param  _allocPoint  The id of the position that is fully vested
     */
    function ownerAddPool(uint256 _marketId, uint256 _allocPoint, bool _withUpdate) external;

    /**
     * @notice  Update the given market id's allocation point. Can only be called by the owner
     *
     * @param  _marketId    The id of the position that is fully vested
     * @param  _allocPoint  The id of the position that is fully vested
     */
    function ownerSetPool(uint256 _marketId, uint256 _allocPoint) external;

    /**
     * @notice  Resets all reward progress and starts a new reward campaign
     *
     * @param  _startTime   The startTime of the new campaign
     * @param  _oARB        The new oARB token
     */
    function ownerCreateNewCampaign(uint256 _startTime, IERC20Mintable _oARB) external;

    /**
     * @notice  Updates the oARBPerSecond
     *
     * @param  _oARBPerSecond   The new oARBPerSecond value
     */
    function ownerSetOARBPerSecond(uint256 _oARBPerSecond) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;



/**
 * @title   IEmitterMultipleRewardTokens
 * @author  Dolomite
 *
 * Interface for an emitter that is inspired by MasterChef to reward oARB tokens
 */
interface IEmitterMultipleRewardTokens {

    // =================================================
    // ==================== Structs ====================
    // =================================================

    struct UserInfo {
        uint256 amount;
        mapping(address => uint256) rewardDebts;
    }

    struct PoolInfo {
        uint256 marketId;
        uint256 totalPar;
        uint256 allocPoint;
        mapping(address => uint256) lastRewardTimes;
        mapping(address => uint256) accRewardTokenPerShares;
    }

    struct RewardToken {
        address token;
        address tokenStorageVault;
        bool isAccruing;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    event Deposit(address indexed user, uint256 indexed marketId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed marketId, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed marketId, uint256 amount);

    // ======================================================
    // ================== User Functions ===================
    // ======================================================

    /**
     * @notice  Deposit tokens to Emitter for oARB allocation
     *
     * @param  _fromAccountNumber   The account number to tranfer funds from
     * @param  _marketId            The market id of the token to deposit
     * @param  _amountWei           The amount wei of the token to deposit
     */
    function deposit(uint256 _fromAccountNumber, uint256 _marketId, uint256 _amountWei) external;

    /**
     * @notice  Withdraws tokens from the Emitter contract
     *
     * @param  _marketId        The market id of the token to deposit
     * @param  _amountWei       The amount of the token to withdraw
     */
    function withdraw(uint256 _marketId, uint256 _amountWei) external;

    /**
     * @notice  Emergency withdraws tokens from the Emitter contract
     *          WARNING: This will forfeit all vesting progress
     *
     * @param  _marketId        The market id of the token to deposit
     */
    function emergencyWithdraw(uint256 _marketId) external;

    /**
     * @notice  Update reward variables of all pools to be up-to-date
     *
     */
    function massUpdatePools() external;

    /**
     * @notice  Update reward variables of the given pool to be up-to-date
     *
     * @param  _marketId    The market id of the pool to update
     */
    function updatePool(uint256 _marketId) external;

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    /**
     * @notice  Adds a new market id to the pool. Can only be called by the owner.
     *
     * @param  _marketId    The id of the position that is fully vested
     * @param  _allocPoint  The id of the position that is fully vested
     */
    function ownerAddPool(uint256 _marketId, uint256 _allocPoint, bool _withUpdate) external;

    /**
     * @notice  Update the given market id's allocation point. Can only be called by the owner
     *
     * @param  _marketId    The id of the position that is fully vested
     * @param  _allocPoint  The id of the position that is fully vested
     */
    function ownerSetPool(uint256 _marketId, uint256 _allocPoint) external;

    /**
     * @notice  Updates the rewardTokenPerSecond
     *
     * @param  _rewardTokenPerSecond    The new rewardTokenPerSecond value
     */
    function ownerSetRewardTokenPerSecond(uint256 _rewardTokenPerSecond) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IERC20Mintable
 * @author  Dolomite
 *
 * @notice  Interface for mintable and burnable tokens
 */
interface IERC20Mintable {

    // ======================================================
    // ================== External Functions ================
    // ======================================================

    /**
     * @notice  Mints the provided amount of tokens. Can only be called by dolomite global operator
     *
     * @param  _amount  The amount of tokens to mint
     */
    function mint(uint256 _amount) external;

    /**
     * @notice  Burns the provided amount of tokens. Can only be called by dolomite global operator
     *
     * @param  _amount  The amount of tokens to burn
     */
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20Mintable } from "./IERC20Mintable.sol";


/**
 * @title   IRewardsDistributor
 * @author  Dolomite
 *
 * @notice  Interface for token rewards distributor
 */
interface IRewardsDistributor {

    // ======================================================
    // ======================== Structs =====================
    // ======================================================

    struct ClaimInfo {
        uint256 epoch;
        uint256 amount;
        bytes32[] proof;
    }

    // ======================================================
    // ======================== Events ======================
    // ======================================================

    event HandlerSet(address indexed handler, bool isHandler);

    event MerkleRootSet(uint256 epoch, bytes32 merkleRoot);

    event TokenSet(IERC20Mintable token);

    // ======================================================
    // ================== External Functions ================
    // ======================================================

    function ownerSetHandler(address _handler, bool _isHandler) external;

    function ownerSetMerkleRoot(uint256 _epoch, bytes32 _merkleRoot) external;

    function handlerSetMerkleRoot(uint256 _epoch, bytes32 _merkleRoot) external;

    function ownerSetToken(IERC20Mintable _token) external;

    /**
     *
     * @param  _claimInfo  Array of ClaimInfo structs used to claim token for the given user
     */
    function claim(ClaimInfo[] calldata _claimInfo) external;

    /**
     *
     * @param  _from    The address tp check if it is a handler
     * @return          True if the address is a handler, false otherwise
     */
    function isHandler(address _from) external view returns (bool);

    /**
     *
     * @param  _epoch   Epoch to get the merkle root for
     * @return          Merkle root for the given epoch
     */
    function getMerkleRootByEpoch(uint256 _epoch) external view returns (bytes32);

    /**
     *
     * @param  _user    User to get the claim status for
     * @param  _epoch   Epoch to get the claim status for
     * @return          True if the user has claimed for the given epoch, false otherwise
     */
    function getClaimStatusByUserAndEpoch(address _user, uint256 _epoch) external view returns (bool);

    function token() external view returns (IERC20Mintable);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IStorageVault
 * @author  Dolomite
 *
 * @notice  Interface for oARB token
 */
interface IStorageVault {

    // ======================================================
    // ================== External Functions ================
    // ======================================================

    function pullTokensFromVault(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IERC20Mintable } from "./IERC20Mintable.sol";


/**
 * @title   IVesterV1
 * @author  Dolomite
 *
 * Interface for a vesting contract that offers users a discount on ARB tokens
 * if they vest ARB and oARB for a length of time
 */
interface IVesterV1 {

    // =================================================
    // ==================== Structs ====================
    // =================================================

    struct VestingPosition {
        address creator;
        uint256 id;
        uint256 startTime;
        uint256 duration;
        uint256 amount;
    }

    struct BaseUriStorage {
        string baseUri;
    }

    // ================================================
    // ==================== Events ====================
    // ================================================

    event VestingStarted(address indexed owner, uint256 duration, uint256 amount, uint256 vestingId);
    event PositionClosed(address indexed owner, uint256 vestingId, uint256 ethCostPaid);
    event PositionForceClosed(address indexed owner, uint256 vestingId, uint256 arbTax);
    event EmergencyWithdraw(address indexed owner, uint256 vestingId, uint256 arbTax);
    event VestingActiveSet(bool vestingActive);
    event OARBSet(address oARB);
    event ClosePositionWindowSet(uint256 closePositionWindow);
    event EmergencyWithdrawTaxSet(uint256 emergencyWithdrawTax);
    event ForceClosePositionTaxSet(uint256 forceClosePositionTax);
    event PromisedTokensSet(uint256 promisedTokensSet);
    event VestingPositionCreated(VestingPosition vestingPosition);
    event VestingPositionCleared(uint256 id);
    event BaseURISet(string baseURI);

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    /**
     * @notice Allows the owner to withdraw ARB from the contract, potentially bypassing any reserved amounts
     *
     * @param  _to                              The address to send the ARB to
     * @param  _amount                          The amount of ARB to send
     * @param  _shouldBypassAvailableAmounts    True if the available balance should be checked first, false otherwise.
     *                                          Bypassing should only be used under emergency scenarios in which the
     *                                          owner needs to pull all of the funds
     */
    function ownerWithdrawToken(
        address _to,
        uint256 _amount,
        bool _shouldBypassAvailableAmounts
    ) external;

    /**
     * @notice  Sets isVestingActive. Callable by Dolomite Margin owner
     *
     * @param  _isVestingActive   True if creating new vests is allowed, or false to disable it
     */
    function ownerSetIsVestingActive(bool _isVestingActive) external;

    /**
     * @notice  Sets the close position window. Callable by Dolomite Margin owner
     *
     * @param  _closePositionWindow Close position window in seconds
     */
    function ownerSetClosePositionWindow(uint256 _closePositionWindow) external;

    /**
     * @notice  Sets the emergency withdraw tax. Callable by Dolomite Margin owner
     * @dev     This must be an integer between 0 and 10_000
     *
     * @param  _emergencyWithdrawTax    Emergency withdraw tax amount
     */
    function ownerSetEmergencyWithdrawTax(uint256 _emergencyWithdrawTax) external;

    /**
     * @notice  Sets the force close position tax. Callable by Dolomite Margin owner
     * @dev     This must be an integer between 0 and 10_000
     *
     * @param  _forceClosePositionTax`  Force close position tax amount
     */
    function ownerSetForceClosePositionTax(uint256 _forceClosePositionTax) external;

    /**
     * @notice  Sets the base URI for the NFT's metadata. Callable by Dolomite Margin owner
     *
     * @param  _baseUri The URI that will be used for getting the NFT's image
     */
    function ownerSetBaseURI(string memory _baseUri) external;

    // ======================================================
    // ================== User Functions ====================
    // ======================================================

    /**
     *
     * @param  _data encoded bytes data that resolves to (address oARB, string _baseUri)
     */
    function initialize(bytes calldata _data) external;

    /**
     * @notice  Transfers ARB and oARB from user's dolomite balance to the contract and begins vesting
     * @dev     Duration must be 1 week, 2 weeks, 3 weeks, or 4 weeks in seconds
     *
     * @param  _fromAccountNumber   The account number to transfer ARB and oARB from
     * @param  _duration            The vesting duration
     * @param  _amount              The amount to vest
     */
    function vest(uint256 _fromAccountNumber, uint256 _duration, uint256 _amount) external returns (uint256);

    /**
     * @notice  Burns the vested oARB tokens and sends vested and newly purchased ARB to user's dolomite balance
     *
     * @param  _id                  The id of the position that is fully vested
     * @param  _fromAccountNumber   The account number from which payment will be made
     * @param  _toAccountNumber     The account number to which the ARB will be sent
     * @param  _maxPaymentAmount    The maximum amount of ETH to pay for the position
     */
    function closePositionAndBuyTokens(
        uint256 _id,
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _maxPaymentAmount
    ) external;

    /**
     * @notice  Burns the vested oARB tokens and sends vested ARB back to position owner's dolomite balance
     *
     * @param  _id  The id of the position that is expired
     */
    function forceClosePosition(uint256 _id) external;

    /**
     * @notice  Emergency withdraws oARB tokens and ARB tokens back to users account
     *          WARNING: This cancels all vesting progress
     *
     * @param  _id  The id of the position to emergency withdraw
     */
    function emergencyWithdraw(uint256 _id) external;

    // =================================================
    // ================= View Functions ================
    // =================================================

    /**
     * @return The amount of tokens available for vesting. Vesting tokens is reserved by pairing with oToken.
     */
    function availableTokens() external view returns (uint256);

    /**
     * @return The amount of ARB tokens committed to active oARB vesting positions
     */
    function promisedTokens() external view returns (uint256);

    /**
     *  @return The oToken token contract address
     */
    function oToken() external view returns (IERC20Mintable);

    /**
     * @return The duration in seconds that users may execute the matured positions before it becomes force-closed
     */
    function closePositionWindow() external view returns (uint256);

    /**
     * @return The tax rate the user incurs when a position is force closed after the `closePositionWindow`. Measured in
     *          basis points (10_000 = 100%).
     */
    function forceClosePositionTax() external view returns (uint256);

    /**
     * @return  The tax rate the user incurs when they emergency exit/withdraw from a position. Measured in basis points
     *          (10_000 = 100%).
     */
    function emergencyWithdrawTax() external view returns (uint256);

    /**
     * @return  True if vesting is active, false otherwise
     */
    function isVestingActive() external view returns (bool);

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function baseURI() external view returns (string memory);

    /**
     *
     * @param  _id  The id of the position to get
     * @return      The vesting position
     */
    function vestingPositions(uint256 _id) external pure returns (VestingPosition memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IVesterV1 } from "./IVesterV1.sol";


/**
 * @title   IVesterV2
 * @author  Dolomite
 *
 * Interface for a vesting contract that offers users a discount on ARB tokens
 * if they vest ARB and oARB for a length of time
 */
interface IVesterV2 is IVesterV1 {

    // ================================================
    // ==================== Events ====================
    // ================================================

    event PositionDurationExtended(uint256 indexed vestingId, uint256 newDuration);
    event LevelRequestInitiated(address user, uint256 requestId);
    event LevelRequestFinalized(address user, uint256 requestId, uint256 level);
    event LevelRequestFeeSet(uint256 levelRequestFee);
    event LevelExpirationWindowSet(uint256 levelExpirationWindow);
    event LevelBoostThresholdSet(uint8 levelBoostThreshold);
    event HandlerSet(address handler, bool isHandler);

    // ================================================
    // ================== Functions ===================
    // ================================================

    /**
     *
     * @param  _levelExpirationWindow The new amount of time that a level is valid before it can be considered expired
     */
    function ownerSetLevelExpirationWindow(uint256 _levelExpirationWindow) external;

    /**
     *
     * @param  _levelRequestFee The new fee that must be sent by the user to initiate a level request update
     */
    function ownerSetLevelRequestFee(uint256 _levelRequestFee) external;

    /**
     *
     * @param  _levelBoostThreshold The new level at which the user is eligible to accelerate their vesting
     */
    function ownerSetLevelBoostThreshold(uint8 _levelBoostThreshold) external;

    /**
     *
     * @param  _handler     The address of the handler to set
     * @param  _isHandler   Whether or not the address is a handler
     */
    function ownerSetHandler(address _handler, bool _isHandler) external;

    /**
     *
     * @param  _nftId    The ID of the position to extend the duration for
     * @param  _duration The new duration to set for the position
     */
    function extendDurationForPosition(uint256 _nftId, uint256 _duration) external;

    /**
     *
     * Initiates a request for `_user` to have their level updated. This will emit a `LevelRequestInitiated` event
     */
    function initiateLevelRequest(address _user) external payable;

    /**
     *
     * Finalizes a level request for `_user` with `_level`. This will emit a `LevelRequestFinalized` event
     *
     * @param  _requestId   The ID of the requests to finalize or 0 for no ID and to force update a user's level.
     * @param  _user        The user whose level should be updated
     * @param  _level       The level to set for the user
     */
    function handlerUpdateLevel(uint256 _requestId, address _user, uint256 _level) external;

    /**
     * Allows the handler to withdraw all ETH in this contract to a designated address
     *
     * @param  _to  The recipient of the ETH in this contract
     */
    function handlerWithdrawETH(address payable _to) external;

    /**
     * @return  The amount of time that a level is valid before it can be considered expired
     */
    function levelExpirationWindow() external view returns (uint256);

    /**
     *
     * @param  _user    The user whose level should be retrieved
     * @return The level of the user
     */
    function getLevelByUser(address _user) external view returns (uint256);

    /**
     *
     * @param  _user    The user whose level should be retrieved
     * @return The level of the user or 0 if the user's level is expired
     */
    function getEffectiveLevelByUser(address _user) external view returns (uint256);

    /**
     *
     * @param  _user    The user whose level request ID should be retrieved
     * @return The current level request being fulfilled or 0 for none
     */
    function getLevelRequestByUser(address _user) external view returns (uint256);

    /**
     *
     * @param  _user    The user whose expiration timestamp for their level should be retrieved
     * @return The timestamp at which the user's level expires or 0 if there is no expiration
     */
    function getLevelExpirationTimestampByUser(address _user) external view returns (uint256);

    /**
     *
     * @param  _handler The handler to check
     * @return Whether or not the address is a handler
     */
    function isHandler(address _handler) external view returns (bool);

    /**
     *
     * @return The last ID from a V1 position that was grandfathered into the old vesting regime.
     */
    function grandfatheredIdCutoff() external view returns (uint256);

    /**
     *
     * @return The amount of ETH required to initiate a level update request
     */
    function levelRequestFee() external view returns (uint256);

    /**
     *
     * @return The level at which the user can boost the speed of their vesting by 50%.
     */
    function levelBoostThreshold() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/helpers/OnlyDolomiteMargin.sol";
import { IDolomiteRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteRegistry.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";
import { IRewardsDistributor } from "./interfaces/IRewardsDistributor.sol";


/**
 * @title   RewardsDistributor
 * @author  Dolomite
 *
 * Rewards Distributor contract for token tokens
 */
contract RewardsDistributor is OnlyDolomiteMargin, IRewardsDistributor {
    using SafeERC20 for IERC20;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "RewardsDistributor";

    // ===================================================
    // ==================== State Variables ==============
    // ===================================================

    IDolomiteRegistry public immutable DOLOMITE_REGISTRY; // solhint -disable-line mixed-case

    IERC20Mintable public override token;

    mapping(address => bool) private _handlerMap;
    mapping(uint256 => bytes32) private _epochToMerkleRootMap;
    mapping(address => mapping(uint256 => bool)) private _userToEpochToClaimStatusMap;

    // ===========================================================
    // ======================= Constructor =======================
    // ===========================================================

    modifier onlyHandler(address _from) {
        Require.that(
            _handlerMap[_from],
            _FILE,
            "Only handler can call",
            _from
        );
        _;
    }

    // ===========================================================
    // ======================= Constructor =======================
    // ===========================================================

    constructor(
        address _dolomiteMargin,
        IERC20Mintable _token,
        address[] memory _initialHandlers,
        address _dolomiteRegistry
    ) OnlyDolomiteMargin(_dolomiteMargin) {
        token = _token;

        for (uint256 i; i < _initialHandlers.length; ++i) {
            _ownerSetHandler(_initialHandlers[i], /* _isHandler = */ true);
        }

        DOLOMITE_REGISTRY = IDolomiteRegistry(_dolomiteRegistry);
    }

    // ======================================================
    // ================== Admin Functions ===================
    // ======================================================

    function ownerSetHandler(address _handler, bool _isHandler) external onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetHandler(_handler, _isHandler);
    }

    function ownerSetMerkleRoot(uint256 _epoch, bytes32 _merkleRoot) external onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetMerkleRoot(_epoch, _merkleRoot);
    }

    function handlerSetMerkleRoot(uint256 _epoch, bytes32 _merkleRoot) external onlyHandler(msg.sender) {
        _ownerSetMerkleRoot(_epoch, _merkleRoot);
    }

    function ownerSetToken(IERC20Mintable _token) external onlyDolomiteMarginOwner(msg.sender) {
        token = _token;
        emit TokenSet(_token);
    }

    // ==============================================================
    // ======================= User Functions =======================
    // ==============================================================

    function claim(ClaimInfo[] calldata _claimInfo) external {
        uint256 len = _claimInfo.length;
        Require.that(
            len > 0,
            _FILE,
            "Invalid claim infos"
        );

        uint256 claimAmount = 0;
        for (uint256 i; i < len; ++i) {
            Require.that(
                _verifyMerkleProof(_claimInfo[i]),
                _FILE,
                "Invalid merkle proof"
            );
            Require.that(
                !_userToEpochToClaimStatusMap[msg.sender][_claimInfo[i].epoch],
                _FILE,
                "Already claimed"
            );

            _userToEpochToClaimStatusMap[msg.sender][_claimInfo[i].epoch] = true;
            claimAmount += _claimInfo[i].amount;
            DOLOMITE_REGISTRY.eventEmitter().emitRewardClaimed(
                msg.sender,
                _claimInfo[i].epoch,
                _claimInfo[i].amount
            );
        }

        token.mint(claimAmount);
        IERC20(address(token)).safeTransfer(msg.sender, claimAmount);
    }

    // ==============================================================
    // ======================= View Functions =======================
    // ==============================================================

    function isHandler(address _from) external view returns (bool) {
        return _handlerMap[_from];
    }

    function getMerkleRootByEpoch(uint256 _epoch) external view returns (bytes32) {
        return _epochToMerkleRootMap[_epoch];
    }

    function getClaimStatusByUserAndEpoch(address _user, uint256 _epoch) external view returns (bool) {
        return _userToEpochToClaimStatusMap[_user][_epoch];
    }

    // ==================================================================
    // ======================= Internal Functions =======================
    // ==================================================================

    function _ownerSetHandler(address _handler, bool _isHandler) internal {
        _handlerMap[_handler] = _isHandler;
        emit HandlerSet(_handler, _isHandler);
    }

    function _ownerSetMerkleRoot(uint256 _epoch, bytes32 _merkleRoot) internal {
        _epochToMerkleRootMap[_epoch] = _merkleRoot;
        emit MerkleRootSet(_epoch, _merkleRoot);
    }

    function _verifyMerkleProof(ClaimInfo calldata _claimInfo) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encode(msg.sender, _claimInfo.amount));
        return MerkleProof.verifyCalldata(_claimInfo.proof, _epochToMerkleRootMap[_claimInfo.epoch], leaf);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IWETH } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IWETH.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { VesterImplementationV1 } from "../VesterImplementationV1.sol";


/**
 * @title   TestVesterImplementationV1
 * @author  Dolomite
 *
 * @notice  Test implementation for exposing areas for coverage testing
 */
contract TestVesterImplementationV1 is VesterImplementationV1 {

    constructor(
        address _dolomiteMargin,
        address _dolomiteRegistry,
        IWETH _weth,
        IERC20 _arb
    ) VesterImplementationV1(
        _dolomiteMargin,
        _dolomiteRegistry,
        _weth,
        _arb
    ) {} // solhint-disable-line

    function callClosePositionAndBuyTokensAndTriggerReentrancy(
        uint256 _id,
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _maxPaymentAmount
    ) external payable nonReentrant {
        // solhint-disable-next-line avoid-low-level-calls
        (bool isSuccessful, bytes memory result) = address(this).delegatecall(
            abi.encodeWithSelector(
                this.closePositionAndBuyTokens.selector,
                _id,
                _fromAccountNumber,
                _toAccountNumber,
                _maxPaymentAmount
            )
        );
        if (!isSuccessful) {
            if (result.length < 68) {
                revert("No reversion message!");
            } else {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    result := add(result, 0x04) // Slice the sighash.
                }
            }
            (string memory errorMessage) = abi.decode(result, (string));
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IWETH } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IWETH.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { VesterImplementationV2 } from "../VesterImplementationV2.sol";


/**
 * @title   TestVesterImplementationV2
 * @author  Dolomite
 *
 * @notice  Test implementation for exposing areas for coverage testing
 */
contract TestVesterImplementationV2 is VesterImplementationV2 {

    constructor(
        address _dolomiteMargin,
        address _dolomiteRegistry,
        IWETH _weth,
        IERC20 _arb
    ) VesterImplementationV2(
        _dolomiteMargin,
        _dolomiteRegistry,
        _weth,
        _arb
    ) {} // solhint-disable-line

    function callClosePositionAndBuyTokensAndTriggerReentrancy(
        uint256 _id,
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _maxPaymentAmount
    ) external payable nonReentrant {
        // solhint-disable-next-line avoid-low-level-calls
        (bool isSuccessful, bytes memory result) = address(this).delegatecall(
            abi.encodeWithSelector(
                this.closePositionAndBuyTokens.selector,
                _id,
                _fromAccountNumber,
                _toAccountNumber,
                _maxPaymentAmount
            )
        );
        if (!isSuccessful) {
            if (result.length < 68) {
                revert("No reversion message!");
            } else {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    result := add(result, 0x04) // Slice the sighash.
                }
            }
            (string memory errorMessage) = abi.decode(result, (string));
            revert(errorMessage);
        }
    }

    function nextNftId() external view returns (uint256) {
        return _nextNftId();
    }

    function nextRequestId() external view returns (uint256) {
        return _nextRequestId();
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { VesterImplementationV2 } from "./VesterImplementationV2.sol";


/**
 * @title   VesterImplementationLibForV2
 * @author  Dolomite
 *
 * A library contract for reducing code size of the VesterImplementationV2 contract.
 */
library VesterImplementationLibForV2 {

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "VesterImplementationLibForV2";
    uint256 private constant _MIN_VESTING_DURATION = 1 weeks;
    uint256 private constant _MAX_VESTING_DURATION = 40 weeks;
    uint256 private constant _GRANDFATHERED_UPGRADED_MIN_DURATION = 8 weeks;
    uint256 private constant _OLD_MAX_VESTING_DURATION = 4 weeks;

    // ======================================================
    // ======================= Events =======================
    // ======================================================

    event PositionDurationExtended(uint256 indexed vestingId, uint256 newDuration);

    // ==================================================================
    // ======================= External Functions =======================
    // ==================================================================

    function extendDurationForPosition(
        VesterImplementationV2 _implementation,
        VesterImplementationV2.VestingPosition storage _vestingPosition,
        uint256 _nftId,
        uint256 _duration
    )
        public
    {
        address positionOwner = _implementation.ownerOf(_nftId);
        Require.that(
            positionOwner == msg.sender,
            _FILE,
            "Invalid position owner"
        );
        Require.that(
            _duration <= _MAX_VESTING_DURATION && _duration % _MIN_VESTING_DURATION == 0,
            _FILE,
            "Invalid duration"
        );
        Require.that(
            _vestingPosition.duration < _duration,
            _FILE,
            "Duration must be extended"
        );

        _vestingPosition.duration = _duration;
        emit PositionDurationExtended(_nftId, _duration);
    }

    function calculateEffectiveRate(
        VesterImplementationV2 _implementation,
        uint256 _duration,
        uint256 _nftId
    ) public view returns (uint256) {
        if (_nftId <= _implementation.grandfatheredIdCutoff() && _duration < _GRANDFATHERED_UPGRADED_MIN_DURATION) {
            if (_duration == 1 weeks) {
                return 9_750;
            } else if (_duration == 2 weeks) {
                return 9_500;
            } else if (_duration == 3 weeks) {
                return 9_000;
            } else {
                assert(_duration == 4 weeks);
                return 8_000;
            }
        } else {
            uint256 numberOfWeeks = _duration / _MIN_VESTING_DURATION;
            return 10_000 - (250 * numberOfWeeks);
        }
    }

    function minVestingDuration() public pure returns (uint256) {
        return _MIN_VESTING_DURATION;
    }

    function maxVestingDuration() public pure returns (uint256) {
        return _MAX_VESTING_DURATION;
    }

    function grandfatheredUpgradedMinVestingDuration() public pure returns (uint256) {
        return _GRANDFATHERED_UPGRADED_MIN_DURATION;
    }

    function oldMaxVestingDuration() public pure returns (uint256) {
        return _OLD_MAX_VESTING_DURATION;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/helpers/OnlyDolomiteMargin.sol";
import { ProxyContractHelpers } from "@dolomite-exchange/modules-base/contracts/helpers/ProxyContractHelpers.sol";
import { IDolomiteRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteRegistry.sol";
import { AccountActionLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountActionLib.sol";
import { AccountBalanceLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountBalanceLib.sol";
import { IDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";
import { IWETH } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IWETH.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { ERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol"; // solhint-disable-line max-line-length
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";
import { IVesterV1 } from "./interfaces/IVesterV1.sol";


/**
 * @title   VesterImplementationV1
 * @author  Dolomite
 *
 * An implementation of the IVesterV1 interface that allows users to buy ARB at a discount if they vest ARB and oARB for
 * a certain amount of time
 */
contract VesterImplementationV1 is
    ProxyContractHelpers,
    OnlyDolomiteMargin,
    ReentrancyGuard,
    ERC721EnumerableUpgradeable,
    IVesterV1
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Mintable;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "VesterImplementationV1";
    uint256 private constant _DEFAULT_ACCOUNT_NUMBER = 0;
    uint256 private constant _BASE = 10_000;

    uint256 private constant _MIN_DURATION = 1 weeks;
    uint256 private constant _MAX_DURATION = 4 weeks;

    bytes32 private constant _NEXT_ID_SLOT = bytes32(uint256(keccak256("eip1967.proxy.nextId")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _VESTING_POSITIONS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.vestingPositions")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _PROMISED_ARB_TOKENS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.promisedTokens")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _OARB_SLOT = bytes32(uint256(keccak256("eip1967.proxy.oarb")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _CLOSE_POSITION_WINDOW_SLOT = bytes32(uint256(keccak256("eip1967.proxy.closePositionWindow")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _FORCE_CLOSE_POSITION_TAX_SLOT = bytes32(uint256(keccak256("eip1967.proxy.forceClosePositionTax")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _EMERGENCY_WITHDRAW_TAX_SLOT = bytes32(uint256(keccak256("eip1967.proxy.emergencyWithdrawTax")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _IS_VESTING_ACTIVE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.isVestingActive")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _BASE_URI_SLOT = bytes32(uint256(keccak256("eip1967.proxy.baseURI")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _VERSION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.version")) - 1); // solhint-disable-line max-line-length

    // =========================================================
    // ==================== State Variables ====================
    // =========================================================

    IDolomiteRegistry public immutable DOLOMITE_REGISTRY; // solhint-disable-line
    IWETH public immutable WETH; // solhint-disable-line
    uint256 public immutable WETH_MARKET_ID; // solhint-disable-line
    IERC20 public immutable ARB; // solhint-disable-line
    uint256 public immutable ARB_MARKET_ID; // solhint-disable-line

    // =========================================================
    // ======================= Modifiers =======================
    // =========================================================

    modifier requireVestingActive() {
        Require.that(
            isVestingActive(),
            _FILE,
            "Vesting not active"
        );
        _;
    }

    // ===========================================================
    // ======================= Initializer =======================
    // ===========================================================

    constructor(
        address _dolomiteMargin,
        address _dolomiteRegistry,
        IWETH _weth,
        IERC20 _arb
    ) OnlyDolomiteMargin(_dolomiteMargin) {
        DOLOMITE_REGISTRY = IDolomiteRegistry(_dolomiteRegistry);
        WETH = _weth;
        WETH_MARKET_ID = DOLOMITE_MARGIN().getMarketIdByTokenAddress(address(_weth));
        ARB = _arb;
        ARB_MARKET_ID = DOLOMITE_MARGIN().getMarketIdByTokenAddress(address(_arb));
    }

    function initialize(
        bytes calldata _data
    )
        external
        initializer
    {
        (address _oARB, string memory _baseUri) = abi.decode(_data, (address, string));
        _ownerSetIsVestingActive(true);
        _ownerSetOARB(_oARB);
        _ownerSetClosePositionWindow(1 weeks);
        _ownerSetForceClosePositionTax(500); // 5%
        _ownerSetEmergencyWithdrawTax(0); // 0%
        _ownerSetBaseURI(_baseUri);
        __ERC721_init("Dolomite oARB Vesting", "voARB");
    }

    // ==================================================================
    // ======================= External Functions =======================
    // ==================================================================

    function vest(
        uint256 _fromAccountNumber,
        uint256 _duration,
        uint256 _amount
    )
        external
        requireVestingActive
        returns (uint256)
    {
        Require.that(
            ARB.balanceOf(address(this)) >= _amount + promisedTokens(),
            _FILE,
            "Not enough ARB tokens available"
        );
        Require.that(
            _duration >= _MIN_DURATION && _duration <= _MAX_DURATION && _duration % _MIN_DURATION == 0,
            _FILE,
            "Invalid duration"
        );

        // Create vesting position NFT
        uint256 nftId = _nextId() + 1;
        _setNextId(nftId);

        _createVestingPosition(
            VestingPosition({
                creator: msg.sender,
                id: nftId,
                startTime: block.timestamp,
                duration: _duration,
                amount: _amount
            })
        );
        _setPromisedTokens(promisedTokens() + _amount);

        _mint(msg.sender, nftId);
        // Transfer amounts in to hash of id and msg.sender
        IERC20(address(oToken())).safeTransferFrom(msg.sender, address(this), _amount);
        _transfer(
            /* fromAccount = */ msg.sender,
            /* fromAccountNumber = */ _fromAccountNumber,
            /* toAccount = */ address(this),
            /* toAccountNumber = */ uint256(keccak256(abi.encodePacked(msg.sender, nftId))),
            /* marketId */ ARB_MARKET_ID,
            /* amount */ _amount
        );

        emit VestingStarted(msg.sender, _duration, _amount, nftId);
        return nftId;
    }

    function closePositionAndBuyTokens(
        uint256 _id,
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _maxPaymentAmount
    )
    external
    nonReentrant {
        VestingPosition memory position = _getVestingPositionSlot(_id);
        uint256 accountNumber = uint256(keccak256(abi.encodePacked(position.creator, _id)));
        address positionOwner = ownerOf(_id);
        Require.that(
            positionOwner == msg.sender,
            _FILE,
            "Invalid position owner"
        );
        Require.that(
            block.timestamp > position.startTime + position.duration,
            _FILE,
            "Position not vested"
        );
        Require.that(
            block.timestamp <= position.startTime + position.duration + closePositionWindow(),
            _FILE,
            "Position expired"
        );

        _closePosition(position);

        // Burn oARB and deposit ARB tokens back into dolomite
        oToken().burn(position.amount);
        _transfer(
            /* fromAccount = */ address(this),
            /* fromAccountNumber = */ accountNumber,
            /* toAccount = */ positionOwner,
            /* toAccountNumber = */ _toAccountNumber,
            /* marketId */ ARB_MARKET_ID,
            /* amount */ type(uint256).max
        );

        // Calculate price
        uint256 discount = _calculateDiscount(position.duration);
        uint256 wethPrice = DOLOMITE_MARGIN().getMarketPrice(WETH_MARKET_ID).value;
        uint256 arbPriceAdj = DOLOMITE_MARGIN().getMarketPrice(ARB_MARKET_ID).value * discount / _BASE;

        uint256 cost = position.amount * arbPriceAdj / wethPrice;
        Require.that(
            cost <= _maxPaymentAmount,
            _FILE,
            "Cost exceeds max payment amount"
        );

        _transfer(
            /* fromAccount = */ msg.sender,
            /* fromAccountNumber = */ _fromAccountNumber,
            /* toAccount = */ DOLOMITE_MARGIN().owner(),
            /* toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
            /* marketId */ WETH_MARKET_ID,
            /* amount */ cost
        );

        // Deposit purchased ARB tokens into dolomite, clear vesting position, and refund
        _depositARBIntoDolomite(positionOwner, _toAccountNumber, position.amount);

        emit PositionClosed(positionOwner, _id, cost);
    }

    function forceClosePosition(
        uint256 _id
    )
    external
    onlyDolomiteMarginGlobalOperator(msg.sender) {
        VestingPosition memory position = _getVestingPositionSlot(_id);
        uint256 accountNumber = uint256(keccak256(abi.encodePacked(position.creator, _id)));
        address positionOwner = ownerOf(_id);
        Require.that(
            block.timestamp > position.startTime + position.duration + closePositionWindow(),
            _FILE,
            "Position not expired"
        );

        _closePosition(position);

        // Burn oARB and transfer ARB tokens back to user"s dolomite account minus tax amount
        uint256 arbTax = position.amount * forceClosePositionTax() / _BASE;
        oToken().burn(position.amount);
        if (arbTax > 0) {
            _transfer(
                /* _fromAccount = */ address(this),
                /* _fromAccountNumber = */ accountNumber,
                /* _toAccount = */ DOLOMITE_MARGIN().owner(),
                /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
                /* _marketId = */ ARB_MARKET_ID,
                /* _amountWei */ arbTax
            );
        }

        _transfer(
            /* _fromAccount = */ address(this),
            /* _fromAccountNumber = */ accountNumber,
            /* _toAccount = */ positionOwner,
            /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
            /* _marketId = */ ARB_MARKET_ID,
            /* _amountWei */ type(uint256).max
        );

        emit PositionForceClosed(positionOwner, _id, arbTax);
    }

    // WARNING: This will forfeit all vesting progress and burn any locked oARB
    function emergencyWithdraw(uint256 _id) external {
        VestingPosition memory position = _getVestingPositionSlot(_id);
        uint256 accountNumber = uint256(keccak256(abi.encodePacked(position.creator, _id)));
        address owner = ownerOf(_id);
        Require.that(
            owner == msg.sender,
            _FILE,
            "Invalid position owner"
        );

        // Transfer arb back to the user and burn ARB
        oToken().burn(position.amount);
        uint256 arbTax = position.amount * emergencyWithdrawTax() / _BASE;
        if (arbTax > 0) {
            _transfer(
                /* _fromAccount = */ address(this),
                /* _fromAccountNumber = */ accountNumber,
                /* _toAccount = */ DOLOMITE_MARGIN().owner(),
                /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
                /* _marketId = */ ARB_MARKET_ID,
                /* _amountWei */ arbTax
            );
        }

        _transfer(
            /* _fromAccount = */ address(this),
            /* _fromAccountNumber = */ accountNumber,
            /* _toAccount = */ owner,
            /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
            /* _marketId = */ ARB_MARKET_ID,
            /* _amountWei */ type(uint256).max
        );

        _closePosition(position);

        emit EmergencyWithdraw(owner, _id, arbTax);
    }

    // ==================================================================
    // ======================= Admin Functions ==========================
    // ==================================================================

    function ownerWithdrawToken(
        address _to,
        uint256 _amount,
        bool _shouldBypassAvailableAmounts
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        if (!_shouldBypassAvailableAmounts) {
            Require.that(
                _amount <= availableTokens(),
                _FILE,
                "Insufficient available tokens"
            );
        }
        ARB.safeTransfer(_to, _amount);
    }

    function ownerSetIsVestingActive(
        bool _isVestingActive
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetIsVestingActive(_isVestingActive);
    }

    function ownerSetOARB(
        address _oARB
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetOARB(_oARB);
    }

    function ownerSetClosePositionWindow(
        uint256 _closePositionWindow
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetClosePositionWindow(_closePositionWindow);
    }

    function ownerSetEmergencyWithdrawTax(
        uint256 _emergencyWithdrawTax
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetEmergencyWithdrawTax(_emergencyWithdrawTax);
    }

    function ownerSetForceClosePositionTax(
        uint256 _forceClosePositionTax
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetForceClosePositionTax(_forceClosePositionTax);
    }

    function ownerSetBaseURI(
        string memory _baseUri
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetBaseURI(_baseUri);
    }

    // ==================================================================
    // ======================= View Functions ===========================
    // ==================================================================

    function availableTokens() public view returns (uint256) {
        return ARB.balanceOf(address(this)) - promisedTokens();
    }

    function promisedTokens() public view returns (uint256) {
        return _getUint256(_PROMISED_ARB_TOKENS_SLOT);
    }

    function oToken() public view returns (IERC20Mintable) {
        return IERC20Mintable(_getAddress(_OARB_SLOT));
    }

    function closePositionWindow() public view returns (uint256) {
        return _getUint256(_CLOSE_POSITION_WINDOW_SLOT);
    }

    function forceClosePositionTax() public view returns (uint256) {
        return _getUint256(_FORCE_CLOSE_POSITION_TAX_SLOT);
    }

    function emergencyWithdrawTax() public view returns (uint256) {
        return _getUint256(_EMERGENCY_WITHDRAW_TAX_SLOT);
    }

    function isVestingActive() public view returns (bool) {
        return _getUint256(_IS_VESTING_ACTIVE_SLOT) == 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);
        return baseURI();
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function vestingPositions(uint256 _id) public pure returns (VestingPosition memory) {
        return _getVestingPositionSlot(_id);
    }

    // ==================================================================
    // ======================= Internal Functions =======================
    // ==================================================================

    function _ownerSetIsVestingActive(
        bool _isVestingActive
    )
    internal {
        _setUint256(_IS_VESTING_ACTIVE_SLOT, _isVestingActive ? 1 : 0);
        emit VestingActiveSet(_isVestingActive);
    }

    function _ownerSetOARB(address _oARB) internal {
        Require.that(
            promisedTokens() == 0,
            _FILE,
            "Outstanding vesting positions"
        );
        _setAddress(_OARB_SLOT, _oARB);
        emit OARBSet(_oARB);
    }

    function _ownerSetClosePositionWindow(uint256 _closePositionWindow) internal {
        Require.that(
            _closePositionWindow >= _MIN_DURATION,
            _FILE,
            "Invalid close position window"
        );
        _setUint256(_CLOSE_POSITION_WINDOW_SLOT, _closePositionWindow);
        emit ClosePositionWindowSet(_closePositionWindow);
    }

    function _ownerSetForceClosePositionTax(uint256 _forceClosePositionTax) internal {
        Require.that(
            _forceClosePositionTax >= 0 && _forceClosePositionTax < _BASE,
            _FILE,
            "Invalid force close position tax"
        );
        _setUint256(_FORCE_CLOSE_POSITION_TAX_SLOT, _forceClosePositionTax);
        emit ForceClosePositionTaxSet(_forceClosePositionTax);
    }

    function _ownerSetEmergencyWithdrawTax(
        uint256 _emergencyWithdrawTax
    )
    internal {
        Require.that(
            _emergencyWithdrawTax >= 0 && _emergencyWithdrawTax < _BASE,
            _FILE,
            "Invalid emergency withdrawal tax"
        );
        _setUint256(_EMERGENCY_WITHDRAW_TAX_SLOT, _emergencyWithdrawTax);
        emit EmergencyWithdrawTaxSet(_emergencyWithdrawTax);
    }

    function _ownerSetBaseURI(string memory _baseUri) internal {
        bytes32 slot = _BASE_URI_SLOT;
        BaseUriStorage storage baseUriStorage;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            baseUriStorage.slot := slot
        }
        baseUriStorage.baseUri = _baseUri;
        emit BaseURISet(_baseUri);
    }

    function _closePosition(VestingPosition memory _position) internal {
        _setPromisedTokens(promisedTokens() - _position.amount);
        _burn(_position.id);
        _clearVestingPosition(_position.id);
    }

    function _transfer(
        address _fromAccount,
        uint256 _fromAccountNumber,
        address _toAccount,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amount
    ) internal {
        uint256 amountToTransfer = _amount;
        if (_amount == type(uint256).max) {
            IDolomiteStructs.AccountInfo memory fromAccountInfo = IDolomiteStructs.AccountInfo({
                owner: _fromAccount,
                number: _fromAccountNumber
            });
            amountToTransfer = DOLOMITE_MARGIN().getAccountWei(fromAccountInfo, _marketId).value;
        }
        AccountActionLib.transfer(
            DOLOMITE_MARGIN(),
            _fromAccount,
            _fromAccountNumber,
            _toAccount,
            _toAccountNumber,
            _marketId,
            IDolomiteStructs.AssetDenomination.Wei,
            amountToTransfer,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function _depositARBIntoDolomite(
        address _account,
        uint256 _toAccountNumber,
        uint256 _amount
    ) internal {
        IDolomiteMargin dolomiteMargin = DOLOMITE_MARGIN();
        IERC20 arb = IERC20(DOLOMITE_MARGIN().getMarketTokenAddress(ARB_MARKET_ID));
        arb.safeApprove(address(dolomiteMargin), _amount);
        AccountActionLib.deposit(
            dolomiteMargin,
            _account,
            /* _fromAccount = */ address(this),
            _toAccountNumber,
            ARB_MARKET_ID,
            IDolomiteStructs.AssetAmount({
                sign: true,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amount
            })
        );
    }

    function _createVestingPosition(VestingPosition memory _vestingPosition) internal {
        VestingPosition storage vestingPosition = _getVestingPositionSlot(_vestingPosition.id);
        vestingPosition.creator = _vestingPosition.creator;
        vestingPosition.id = _vestingPosition.id;
        vestingPosition.startTime = _vestingPosition.startTime;
        vestingPosition.duration = _vestingPosition.duration;
        vestingPosition.amount = _vestingPosition.amount;
        emit VestingPositionCreated(_vestingPosition);
    }

    function _setPromisedTokens(uint256 _promisedTokens) internal {
        _setUint256(_PROMISED_ARB_TOKENS_SLOT, _promisedTokens);
        emit PromisedTokensSet(_promisedTokens);
    }

    function _clearVestingPosition(uint256 _id) internal {
        VestingPosition storage vestingPosition = _getVestingPositionSlot(_id);
        vestingPosition.creator = address(0);
        vestingPosition.id = 0;
        vestingPosition.startTime = 0;
        vestingPosition.duration = 0;
        vestingPosition.amount = 0;
        emit VestingPositionCleared(_id);
    }

    function _setNextId(uint256 _id) internal {
        _setUint256(_NEXT_ID_SLOT, _id);
    }

    function _baseURI() internal view override returns (string memory) {
        bytes32 slot = _BASE_URI_SLOT;
        BaseUriStorage storage baseUriStorage;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            baseUriStorage.slot := slot
        }
        return baseUriStorage.baseUri;
    }

    function _nextId() internal view returns (uint256) {
        return _getUint256(_NEXT_ID_SLOT);
    }

    function _getVestingPositionSlot(uint256 _id) internal pure returns (VestingPosition storage vestingPosition) {
        bytes32 slot = keccak256(abi.encodePacked(_VESTING_POSITIONS_SLOT, _id));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            vestingPosition.slot := slot
        }
    }

    function _calculateDiscount(uint256 _duration) internal pure returns (uint256) {
        if (_duration == 1 weeks) {
            return 9_750;
        } else if (_duration == 2 weeks) {
            return 9_500;
        } else if (_duration == 3 weeks) {
            return 9_000;
        } else {
            assert(_duration == 4 weeks);
            return 8_000;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { OnlyDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/helpers/OnlyDolomiteMargin.sol";
import { ProxyContractHelpers } from "@dolomite-exchange/modules-base/contracts/helpers/ProxyContractHelpers.sol";
import { IDolomiteRegistry } from "@dolomite-exchange/modules-base/contracts/interfaces/IDolomiteRegistry.sol";
import { AccountActionLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountActionLib.sol";
import { AccountBalanceLib } from "@dolomite-exchange/modules-base/contracts/lib/AccountBalanceLib.sol";
import { IDolomiteMargin } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteMargin.sol";
import { IDolomiteStructs } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IDolomiteStructs.sol";
import { IWETH } from "@dolomite-exchange/modules-base/contracts/protocol/interfaces/IWETH.sol";
import { Require } from "@dolomite-exchange/modules-base/contracts/protocol/lib/Require.sol";
import { ERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol"; // solhint-disable-line max-line-length
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { VesterImplementationLibForV2 } from "./VesterImplementationLibForV2.sol";
import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";
import { IVesterV2 } from "./interfaces/IVesterV2.sol";


/**
 * @title   VesterImplementationV2
 * @author  Dolomite
 *
 * An implementation of the IVesterV2 interface that allows users to buy ARB at a discount if they vest oARB for a
 * certain amount of time
 */
contract VesterImplementationV2 is
    ProxyContractHelpers,
    OnlyDolomiteMargin,
    ReentrancyGuard,
    ERC721EnumerableUpgradeable,
    IVesterV2
{
    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Mintable;
    using VesterImplementationLibForV2 for VesterImplementationV2;

    // ===================================================
    // ==================== Constants ====================
    // ===================================================

    bytes32 private constant _FILE = "VesterImplementationV2";
    uint256 private constant _DEFAULT_ACCOUNT_NUMBER = 0;
    uint256 private constant _BASE = 10_000;

    bytes32 private constant _NEXT_ID_SLOT = bytes32(uint256(keccak256("eip1967.proxy.nextId")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _VESTING_POSITIONS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.vestingPositions")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _PROMISED_TOKENS_SLOT = bytes32(uint256(keccak256("eip1967.proxy.promisedTokens")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _TOKEN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.token")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _CLOSE_POSITION_WINDOW_SLOT = bytes32(uint256(keccak256("eip1967.proxy.closePositionWindow")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _FORCE_CLOSE_POSITION_TAX_SLOT = bytes32(uint256(keccak256("eip1967.proxy.forceClosePositionTax")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _EMERGENCY_WITHDRAW_TAX_SLOT = bytes32(uint256(keccak256("eip1967.proxy.emergencyWithdrawTax")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _IS_VESTING_ACTIVE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.isVestingActive")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _BASE_URI_SLOT = bytes32(uint256(keccak256("eip1967.proxy.baseURI")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _GRANDFATHERED_ID_CUTOFF_SLOT = bytes32(uint256(keccak256("eip1967.proxy.grandfatheredIdCutoff")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _NEXT_REQUEST_ID_SLOT = bytes32(uint256(keccak256("eip1967.proxy.nextRequestId")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _IS_HANDLER_SLOT = bytes32(uint256(keccak256("eip1967.proxy.isHandler")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _LEVEL_EXPIRATION_WINDOW_SLOT = bytes32(uint256(keccak256("eip1967.proxy.levelExpirationWindow")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _LEVEL_BY_USER_SLOT = bytes32(uint256(keccak256("eip1967.proxy.levelByUser")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _LEVEL_REQUEST_BY_USER_SLOT = bytes32(uint256(keccak256("eip1967.proxy.levelRequestByUser")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _LEVEL_EXPIRATION_TIMESTAMP_BY_USER_SLOT = bytes32(uint256(keccak256("eip1967.proxy.levelExpirationTimestampByUser")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _LEVEL_REQUEST_FEE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.levelRequestFee")) - 1); // solhint-disable-line max-line-length
    bytes32 private constant _LEVEL_BOOST_THRESHOLD_SLOT = bytes32(uint256(keccak256("eip1967.proxy.levelBoostThreshold")) - 1); // solhint-disable-line max-line-length

    // =========================================================
    // ==================== State Variables ====================
    // =========================================================

    IDolomiteRegistry public immutable DOLOMITE_REGISTRY; // solhint-disable-line
    IWETH public immutable WETH; // solhint-disable-line
    uint256 public immutable WETH_MARKET_ID; // solhint-disable-line
    IERC20 public immutable ARB; // solhint-disable-line
    uint256 public immutable ARB_MARKET_ID; // solhint-disable-line

    uint256 private immutable _MIN_VESTING_DURATION; // solhint-disable-line
    uint256 private immutable _MAX_VESTING_DURATION; // solhint-disable-line
    uint256 private immutable _OLD_MAX_VESTING_DURATION; // solhint-disable-line

    // =========================================================
    // ======================= Modifiers =======================
    // =========================================================

    modifier requireVestingActive() {
        _validateIsVestingActive();
        _;
    }

    modifier requireIsHandler(address _from) {
        _validateIsHandler(msg.sender);
        _;
    }

    // ===========================================================
    // ======================= Initializer =======================
    // ===========================================================

    constructor(
        address _dolomiteMargin,
        address _dolomiteRegistry,
        IWETH _weth,
        IERC20 _arb
    ) OnlyDolomiteMargin(_dolomiteMargin) {
        DOLOMITE_REGISTRY = IDolomiteRegistry(_dolomiteRegistry);
        WETH = _weth;
        WETH_MARKET_ID = DOLOMITE_MARGIN().getMarketIdByTokenAddress(address(_weth));
        ARB = _arb;
        ARB_MARKET_ID = DOLOMITE_MARGIN().getMarketIdByTokenAddress(address(_arb));

        _MIN_VESTING_DURATION = VesterImplementationLibForV2.minVestingDuration();
        _MAX_VESTING_DURATION = VesterImplementationLibForV2.maxVestingDuration();
        _OLD_MAX_VESTING_DURATION = VesterImplementationLibForV2.oldMaxVestingDuration();
    }

    function initialize(
        bytes calldata _data
    )
        external
        reinitializer(/* version = */ 2)
    {
        address _initialHandler = abi.decode(_data, (address));
        _setUint256(_GRANDFATHERED_ID_CUTOFF_SLOT, _nextNftId());
        _ownerSetLevelExpirationWindow(/* _levelExpirationWindow = */ 4 weeks);
        _ownerSetLevelRequestFee(/* _fee = */ 0.0003 ether);
        _ownerSetHandler(_initialHandler, /* _isHandler = */ true);
        _ownerSetLevelBoostThreshold(/* _level = */ 4);
    }

    // ==================================================================
    // ======================= External Functions =======================
    // ==================================================================

    function vest(
        uint256 _fromAccountNumber,
        uint256 _duration,
        uint256 _amount
    )
        external
        requireVestingActive
        returns (uint256)
    {
        Require.that(
            ARB.balanceOf(address(this)) >= _amount + promisedTokens(),
            _FILE,
            "Not enough ARB tokens available"
        );
        Require.that(
            _duration >= _MIN_VESTING_DURATION
                && _duration <= _MAX_VESTING_DURATION
                && _duration % _MIN_VESTING_DURATION == 0,
            _FILE,
            "Invalid duration"
        );

        // Create vesting position NFT
        uint256 nftId = _nextNftId() + 1;
        _setNextNftId(nftId);

        _createVestingPosition(
            VestingPosition({
                creator: msg.sender,
                id: nftId,
                startTime: block.timestamp,
                duration: _duration,
                amount: _amount
            })
        );
        _setPromisedTokens(promisedTokens() + _amount);

        _mint(msg.sender, nftId);
        IERC20(address(oToken())).safeTransferFrom(msg.sender, address(this), _amount);
        // Transfer amounts in to hash of id and msg.sender
        _transfer(
            /* fromAccount = */ msg.sender,
            /* fromAccountNumber = */ _fromAccountNumber,
            /* toAccount = */ address(this),
            /* toAccountNumber = */ uint256(keccak256(abi.encodePacked(msg.sender, nftId))),
            /* marketId */ ARB_MARKET_ID,
            /* amount */ _amount
        );

        emit VestingStarted(msg.sender, _duration, _amount, nftId);
        return nftId;
    }

    function extendDurationForPosition(uint256 _nftId, uint256 _duration) external {
        this.extendDurationForPosition(
            /* _vestingPosition = */ _getVestingPositionSlot(_nftId),
            _nftId,
            _duration
        );
    }

    function closePositionAndBuyTokens(
        uint256 _nftId,
        uint256 _fromAccountNumber,
        uint256 _toAccountNumber,
        uint256 _maxPaymentAmount
    )
    external
    nonReentrant {
        VestingPosition memory position = _getVestingPositionSlot(_nftId);
        uint256 accountNumber = _getAccountNumberByPosition(position);
        address positionOwner = ownerOf(_nftId);
        Require.that(
            positionOwner == msg.sender,
            _FILE,
            "Invalid position owner"
        );
        uint256 level = getEffectiveLevelByUser(positionOwner);
        Require.that(
            block.timestamp > position.startTime + _calculateEffectiveDuration(position.duration, level),
            _FILE,
            "Position not vested"
        );

        _closePosition(position);

        // Burn oARB and deposit ARB tokens back into dolomite
        oToken().burn(position.amount);
        _transfer(
            /* fromAccount = */ address(this),
            /* fromAccountNumber = */ accountNumber,
            /* toAccount = */ positionOwner,
            /* toAccountNumber = */ _toAccountNumber,
            /* marketId */ ARB_MARKET_ID,
            /* amount */ type(uint256).max
        );

        // Calculate price
        uint256 effectiveRate = this.calculateEffectiveRate(position.duration, _nftId);
        uint256 wethPrice = DOLOMITE_MARGIN().getMarketPrice(WETH_MARKET_ID).value;
        uint256 arbPriceAdj = DOLOMITE_MARGIN().getMarketPrice(ARB_MARKET_ID).value * effectiveRate / _BASE;

        uint256 cost = position.amount * arbPriceAdj / wethPrice;
        Require.that(
            cost <= _maxPaymentAmount,
            _FILE,
            "Cost exceeds max payment amount"
        );

        _transfer(
            /* fromAccount = */ positionOwner,
            /* fromAccountNumber = */ _fromAccountNumber,
            /* toAccount = */ DOLOMITE_MARGIN().owner(),
            /* toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
            /* marketId */ WETH_MARKET_ID,
            /* amount */ cost
        );

        // Deposit purchased ARB tokens into dolomite, clear vesting position, and refund
        _depositARBIntoDolomite(positionOwner, _toAccountNumber, position.amount);

        emit PositionClosed(positionOwner, _nftId, cost);
    }

    function forceClosePosition(
        uint256 _nftId
    )
    external
    onlyDolomiteMarginGlobalOperator(msg.sender) {
        VestingPosition memory position = _getVestingPositionSlot(_nftId);
        uint256 accountNumber = _getAccountNumberByPosition(position);
        address positionOwner = ownerOf(_nftId);
        Require.that(
            block.timestamp > position.startTime + position.duration + closePositionWindow(),
            _FILE,
            "Position not expired"
        );

        _closePosition(position);

        // Burn oARB and transfer ARB tokens back to user"s dolomite account minus tax amount
        uint256 arbTax = position.amount * forceClosePositionTax() / _BASE;
        oToken().burn(position.amount);
        if (arbTax > 0) {
            _transfer(
                /* _fromAccount = */ address(this),
                /* _fromAccountNumber = */ accountNumber,
                /* _toAccount = */ DOLOMITE_MARGIN().owner(),
                /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
                /* _marketId = */ ARB_MARKET_ID,
                /* _amountWei */ arbTax
            );
        }

        _transfer(
            /* _fromAccount = */ address(this),
            /* _fromAccountNumber = */ accountNumber,
            /* _toAccount = */ positionOwner,
            /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
            /* _marketId = */ ARB_MARKET_ID,
            /* _amountWei */ type(uint256).max
        );

        emit PositionForceClosed(positionOwner, _nftId, arbTax);
    }

    // WARNING: This will forfeit all vesting progress and burn any locked oARB
    function emergencyWithdraw(uint256 _nftId) external {
        VestingPosition memory position = _getVestingPositionSlot(_nftId);
        uint256 accountNumber = _getAccountNumberByPosition(position);
        address owner = ownerOf(_nftId);
        Require.that(
            owner == msg.sender,
            _FILE,
            "Invalid position owner"
        );

        // Transfer arb back to the user and burn ARB
        oToken().burn(position.amount);
        uint256 arbTax = position.amount * emergencyWithdrawTax() / _BASE;
        if (arbTax > 0) {
            _transfer(
                /* _fromAccount = */ address(this),
                /* _fromAccountNumber = */ accountNumber,
                /* _toAccount = */ DOLOMITE_MARGIN().owner(),
                /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
                /* _marketId = */ ARB_MARKET_ID,
                /* _amountWei */ arbTax
            );
        }

        _transfer(
            /* _fromAccount = */ address(this),
            /* _fromAccountNumber = */ accountNumber,
            /* _toAccount = */ owner,
            /* _toAccountNumber = */ _DEFAULT_ACCOUNT_NUMBER,
            /* _marketId = */ ARB_MARKET_ID,
            /* _amountWei */ type(uint256).max
        );

        _closePosition(position);

        emit EmergencyWithdraw(owner, _nftId, arbTax);
    }

    function initiateLevelRequest(address _user) external payable {
        Require.that(
            msg.value == levelRequestFee(),
            _FILE,
            "Invalid fee"
        );
        Require.that(
            getLevelRequestByUser(_user) == 0,
            _FILE,
            "Request already initiated"
        );

        uint256 requestId = _nextRequestId() + 1;
        _setLevelRequestByUser(_user, requestId);

        _setNextRequestId(requestId);
        emit LevelRequestInitiated(_user, requestId);
    }

    // ==================================================================
    // ======================= Admin Functions ==========================
    // ==================================================================

    function ownerWithdrawToken(
        address _to,
        uint256 _amount,
        bool _shouldBypassAvailableAmounts
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        if (!_shouldBypassAvailableAmounts) {
            Require.that(
                _amount <= availableTokens(),
                _FILE,
                "Insufficient available tokens"
            );
        }
        ARB.safeTransfer(_to, _amount);
    }

    function ownerSetIsVestingActive(
        bool _isVestingActive
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetIsVestingActive(_isVestingActive);
    }

    function ownerSetClosePositionWindow(
        uint256 _closePositionWindow
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetClosePositionWindow(_closePositionWindow);
    }

    function ownerSetEmergencyWithdrawTax(
        uint256 _emergencyWithdrawTax
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetEmergencyWithdrawTax(_emergencyWithdrawTax);
    }

    function ownerSetForceClosePositionTax(
        uint256 _forceClosePositionTax
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetForceClosePositionTax(_forceClosePositionTax);
    }

    function ownerSetBaseURI(
        string memory _baseUri
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetBaseURI(_baseUri);
    }

    function ownerSetLevelExpirationWindow(
        uint256 _levelExpirationWindow
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetLevelExpirationWindow(_levelExpirationWindow);
    }

    function ownerSetLevelRequestFee(
        uint256 _fee
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetLevelRequestFee(_fee);
    }

    function ownerSetLevelBoostThreshold(
        uint8 _levelBoostThreshold
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetLevelBoostThreshold(_levelBoostThreshold);
    }

    function ownerSetHandler(
        address _handler,
        bool _isHandler
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetHandler(_handler, _isHandler);
    }

    // ==================================================================
    // ======================== Handler Functions =======================
    // ==================================================================

    function handlerUpdateLevel(
        uint256 _requestId,
        address _user,
        uint256 _level
    )
        external
        requireIsHandler(msg.sender)
    {
        Require.that(
            _requestId == 0 || _requestId == getLevelRequestByUser(_user),
            _FILE,
            "Invalid request ID"
        );

        _setLevelRequestByUser(_user, /* _requestId = */ 0);
        _setLevelByUser(_user, _level);
        _setLevelExpirationTimestampByUser(_user, block.timestamp + levelExpirationWindow());
        emit LevelRequestFinalized(_user, _requestId, _level);
    }

    function handlerWithdrawETH(
        address payable _to
    )
        external
        requireIsHandler(msg.sender)
    {
        _to.sendValue(address(this).balance);
    }

    // ==================================================================
    // ======================= View Functions ===========================
    // ==================================================================

    function availableTokens() public view returns (uint256) {
        return ARB.balanceOf(address(this)) - promisedTokens();
    }

    function promisedTokens() public view returns (uint256) {
        return _getUint256(_PROMISED_TOKENS_SLOT);
    }

    function oToken() public view returns (IERC20Mintable) {
        return IERC20Mintable(_getAddress(_TOKEN_SLOT));
    }

    function closePositionWindow() public view returns (uint256) {
        return _getUint256(_CLOSE_POSITION_WINDOW_SLOT);
    }

    function forceClosePositionTax() public view returns (uint256) {
        return _getUint256(_FORCE_CLOSE_POSITION_TAX_SLOT);
    }

    function emergencyWithdrawTax() public view returns (uint256) {
        return _getUint256(_EMERGENCY_WITHDRAW_TAX_SLOT);
    }

    function isVestingActive() public view returns (bool) {
        return _getUint256(_IS_VESTING_ACTIVE_SLOT) == 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);
        return baseURI();
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function levelRequestFee() public view returns (uint256) {
        return _getUint256(_LEVEL_REQUEST_FEE_SLOT);
    }

    function levelBoostThreshold() public view returns (uint8) {
        return uint8(_getUint256(_LEVEL_BOOST_THRESHOLD_SLOT));
    }

    function grandfatheredIdCutoff() public view returns (uint256) {
        return _getUint256(_GRANDFATHERED_ID_CUTOFF_SLOT);
    }

    function levelExpirationWindow() public view returns (uint256) {
        return _getUint256(_LEVEL_EXPIRATION_WINDOW_SLOT);
    }

    function getLevelByUser(address _user) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(_LEVEL_BY_USER_SLOT, _user));
        return _getUint256(slot);
    }

    function getEffectiveLevelByUser(address _user) public view returns (uint256) {
        uint256 expirationTimestamp = getLevelExpirationTimestampByUser(_user);
        if (expirationTimestamp == 0 || block.timestamp > expirationTimestamp) {
            // If there's no expiration timestamp or if it's expired, return 0
            return 0;
        }

        return getLevelByUser(_user);
    }

    function getLevelRequestByUser(address _user) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(_LEVEL_REQUEST_BY_USER_SLOT, _user));
        return _getUint256(slot);
    }

    function getLevelExpirationTimestampByUser(address _user) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(_LEVEL_EXPIRATION_TIMESTAMP_BY_USER_SLOT, _user));
        return _getUint256(slot);
    }

    function isHandler(address _handler) public view returns (bool) {
        bytes32 slot = keccak256(abi.encodePacked(_IS_HANDLER_SLOT, _handler));
        return _getUint256(slot) == 1;
    }

    function vestingPositions(uint256 _nftId) public pure returns (VestingPosition memory) {
        return _getVestingPositionSlot(_nftId);
    }

    // ==================================================================
    // ======================= Internal Functions =======================
    // ==================================================================

    function _ownerSetIsVestingActive(
        bool _isVestingActive
    )
    internal {
        _setUint256(_IS_VESTING_ACTIVE_SLOT, _isVestingActive ? 1 : 0);
        emit VestingActiveSet(_isVestingActive);
    }

    function _ownerSetClosePositionWindow(uint256 _closePositionWindow) internal {
        Require.that(
            _closePositionWindow >= _MIN_VESTING_DURATION,
            _FILE,
            "Invalid close position window"
        );
        _setUint256(_CLOSE_POSITION_WINDOW_SLOT, _closePositionWindow);
        emit ClosePositionWindowSet(_closePositionWindow);
    }

    function _ownerSetForceClosePositionTax(uint256 _forceClosePositionTax) internal {
        Require.that(
            _forceClosePositionTax >= 0 && _forceClosePositionTax < _BASE,
            _FILE,
            "Invalid force close position tax"
        );
        _setUint256(_FORCE_CLOSE_POSITION_TAX_SLOT, _forceClosePositionTax);
        emit ForceClosePositionTaxSet(_forceClosePositionTax);
    }

    function _ownerSetEmergencyWithdrawTax(
        uint256 _emergencyWithdrawTax
    )
    internal {
        Require.that(
            _emergencyWithdrawTax >= 0 && _emergencyWithdrawTax < _BASE,
            _FILE,
            "Invalid emergency withdrawal tax"
        );
        _setUint256(_EMERGENCY_WITHDRAW_TAX_SLOT, _emergencyWithdrawTax);
        emit EmergencyWithdrawTaxSet(_emergencyWithdrawTax);
    }

    function _ownerSetBaseURI(string memory _baseUri) internal {
        bytes32 slot = _BASE_URI_SLOT;
        BaseUriStorage storage baseUriStorage;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            baseUriStorage.slot := slot
        }
        baseUriStorage.baseUri = _baseUri;
        emit BaseURISet(_baseUri);
    }

    function _ownerSetLevelExpirationWindow(uint256 _levelExpirationWindow) internal {
        Require.that(
            _levelExpirationWindow >= _MIN_VESTING_DURATION,
            _FILE,
            "Invalid level expiration window"
        );
        _setUint256(_LEVEL_EXPIRATION_WINDOW_SLOT, _levelExpirationWindow);
        emit LevelExpirationWindowSet(_levelExpirationWindow);
    }

    function _ownerSetLevelRequestFee(uint256 _fee) internal {
        Require.that(
            _fee < 0.1 ether,
            _FILE,
            "Level request fee too large"
        );
        _setUint256(_LEVEL_REQUEST_FEE_SLOT, _fee);
        emit LevelRequestFeeSet(_fee);
    }

    function _ownerSetLevelBoostThreshold(uint8 _levelBoostThreshold) internal {
        _setUint256(_LEVEL_BOOST_THRESHOLD_SLOT, _levelBoostThreshold);
        emit LevelBoostThresholdSet(_levelBoostThreshold);
    }

    function _ownerSetHandler(address _handler, bool _isHandler) internal {
        bytes32 slot = keccak256(abi.encodePacked(_IS_HANDLER_SLOT, _handler));
        _setUint256(slot, _isHandler ? 1 : 0);
        emit HandlerSet(_handler, _isHandler);
    }

    function _closePosition(VestingPosition memory _position) internal {
        _setPromisedTokens(promisedTokens() - _position.amount);
        _burn(_position.id);
        _clearVestingPosition(_position.id);
    }

    function _transfer(
        address _fromAccount,
        uint256 _fromAccountNumber,
        address _toAccount,
        uint256 _toAccountNumber,
        uint256 _marketId,
        uint256 _amount
    ) internal {
        uint256 amountToTransfer = _amount;
        if (_amount == type(uint256).max) {
            IDolomiteStructs.AccountInfo memory fromAccountInfo = IDolomiteStructs.AccountInfo({
                owner: _fromAccount,
                number: _fromAccountNumber
            });
            amountToTransfer = DOLOMITE_MARGIN().getAccountWei(fromAccountInfo, _marketId).value;
        }
        AccountActionLib.transfer(
            DOLOMITE_MARGIN(),
            _fromAccount,
            _fromAccountNumber,
            _toAccount,
            _toAccountNumber,
            _marketId,
            IDolomiteStructs.AssetDenomination.Wei,
            amountToTransfer,
            AccountBalanceLib.BalanceCheckFlag.Both
        );
    }

    function _depositARBIntoDolomite(
        address _account,
        uint256 _toAccountNumber,
        uint256 _amount
    ) internal {
        IDolomiteMargin dolomiteMargin = DOLOMITE_MARGIN();
        ARB.safeApprove(address(dolomiteMargin), _amount);
        AccountActionLib.deposit(
            dolomiteMargin,
            _account,
            /* _fromAccount = */ address(this),
            _toAccountNumber,
            ARB_MARKET_ID,
            IDolomiteStructs.AssetAmount({
                sign: true,
                denomination: IDolomiteStructs.AssetDenomination.Wei,
                ref: IDolomiteStructs.AssetReference.Delta,
                value: _amount
            })
        );
    }

    function _createVestingPosition(VestingPosition memory _vestingPosition) internal {
        VestingPosition storage vestingPosition = _getVestingPositionSlot(_vestingPosition.id);
        vestingPosition.creator = _vestingPosition.creator;
        vestingPosition.id = _vestingPosition.id;
        vestingPosition.startTime = _vestingPosition.startTime;
        vestingPosition.duration = _vestingPosition.duration;
        vestingPosition.amount = _vestingPosition.amount;
        emit VestingPositionCreated(_vestingPosition);
    }

    function _setPromisedTokens(uint256 _promisedTokens) internal {
        _setUint256(_PROMISED_TOKENS_SLOT, _promisedTokens);
        emit PromisedTokensSet(_promisedTokens);
    }

    function _clearVestingPosition(uint256 _nftId) internal {
        VestingPosition storage vestingPosition = _getVestingPositionSlot(_nftId);
        vestingPosition.creator = address(0);
        vestingPosition.id = 0;
        vestingPosition.startTime = 0;
        vestingPosition.duration = 0;
        vestingPosition.amount = 0;
        emit VestingPositionCleared(_nftId);
    }

    function _setNextNftId(uint256 _nftId) internal {
        _setUint256(_NEXT_ID_SLOT, _nftId);
    }

    function _setNextRequestId(uint256 _requestId) internal {
        _setUint256(_NEXT_REQUEST_ID_SLOT, _requestId);
    }

    function _setLevelByUser(address _user, uint256 _level) internal {
        bytes32 slot = keccak256(abi.encodePacked(_LEVEL_BY_USER_SLOT, _user));
        _setUint256(slot, _level);
    }

    function _setLevelRequestByUser(address _user, uint256 _requestId) internal {
        bytes32 slot = keccak256(abi.encodePacked(_LEVEL_REQUEST_BY_USER_SLOT, _user));
        _setUint256(slot, _requestId);
    }

    function _setLevelExpirationTimestampByUser(address _user, uint256 _expirationTimestamp) internal {
        bytes32 slot = keccak256(abi.encodePacked(_LEVEL_EXPIRATION_TIMESTAMP_BY_USER_SLOT, _user));
        _setUint256(slot, _expirationTimestamp);
    }

    function _baseURI() internal view override returns (string memory) {
        bytes32 slot = _BASE_URI_SLOT;
        BaseUriStorage storage baseUriStorage;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            baseUriStorage.slot := slot
        }
        return baseUriStorage.baseUri;
    }

    function _nextNftId() internal view returns (uint256) {
        return _getUint256(_NEXT_ID_SLOT);
    }

    function _nextRequestId() internal view returns (uint256) {
        return _getUint256(_NEXT_REQUEST_ID_SLOT);
    }

    function _validateIsVestingActive() internal view {
        Require.that(
            isVestingActive(),
            _FILE,
            "Vesting not active"
        );
    }

    function _validateIsHandler(address _from) internal view {
        Require.that(
            isHandler(_from),
            _FILE,
            "Invalid handler",
            _from
        );
    }

    function _calculateEffectiveDuration(uint256 _duration, uint256 _level) internal view returns (uint256) {
        if (_level >= levelBoostThreshold()) {
            // A 50% increase in speed is the same thing as multiplying the value by 2/3
            return _duration * 2 / 3;
        } else {
            return _duration;
        }
    }

    function _getVestingPositionSlot(uint256 _nftId) internal pure returns (VestingPosition storage vestingPosition) {
        bytes32 slot = keccak256(abi.encodePacked(_VESTING_POSITIONS_SLOT, _nftId));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            vestingPosition.slot := slot
        }
    }

    function _getAccountNumberByPosition(VestingPosition memory _position) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_position.creator, _position.id)));
    }
}