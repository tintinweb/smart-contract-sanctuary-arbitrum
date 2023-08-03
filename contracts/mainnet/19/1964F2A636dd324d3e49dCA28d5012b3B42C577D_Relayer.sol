// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @dev Authorized interface
 */
interface IAuthorized {
    /**
     * @dev Sender `who` is not allowed to call `what` with `how`
     */
    error AuthSenderNotAllowed(address who, bytes4 what, uint256[] how);

    /**
     * @dev Tells the address of the authorizer reference
     */
    function authorizer() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import '@mimic-fi/v3-authorizer/contracts/interfaces/IAuthorized.sol';

/**
 * @dev Smart Vault interface
 */
interface ISmartVault is IAuthorized {
    /**
     * @dev The smart vault is paused
     */
    error SmartVaultPaused();

    /**
     * @dev The smart vault is unpaused
     */
    error SmartVaultUnpaused();

    /**
     * @dev The token is zero
     */
    error SmartVaultTokenZero();

    /**
     * @dev The amount is zero
     */
    error SmartVaultAmountZero();

    /**
     * @dev The recipient is zero
     */
    error SmartVaultRecipientZero();

    /**
     * @dev The connector is deprecated
     */
    error SmartVaultConnectorDeprecated(address connector);

    /**
     * @dev The connector is not registered
     */
    error SmartVaultConnectorNotRegistered(address connector);

    /**
     * @dev The connector is not stateless
     */
    error SmartVaultConnectorNotStateless(address connector);

    /**
     * @dev The connector ID is zero
     */
    error SmartVaultBalanceConnectorIdZero();

    /**
     * @dev The balance connector's balance is lower than the requested amount to be deducted
     */
    error SmartVaultBalanceConnectorInsufficientBalance(bytes32 id, address token, uint256 balance, uint256 amount);

    /**
     * @dev The smart vault's native token balance is lower than the requested amount to be deducted
     */
    error SmartVaultInsufficientNativeTokenBalance(uint256 balance, uint256 amount);

    /**
     * @dev Emitted every time a smart vault is paused
     */
    event Paused();

    /**
     * @dev Emitted every time a smart vault is unpaused
     */
    event Unpaused();

    /**
     * @dev Emitted every time the price oracle is set
     */
    event PriceOracleSet(address indexed priceOracle);

    /**
     * @dev Emitted every time a connector check is overridden
     */
    event ConnectorCheckOverridden(address indexed connector, bool ignored);

    /**
     * @dev Emitted every time a balance connector is updated
     */
    event BalanceConnectorUpdated(bytes32 indexed id, address indexed token, uint256 amount, bool added);

    /**
     * @dev Emitted every time `execute` is called
     */
    event Executed(address indexed connector, bytes data, bytes result);

    /**
     * @dev Emitted every time `call` is called
     */
    event Called(address indexed target, bytes data, uint256 value, bytes result);

    /**
     * @dev Emitted every time `wrap` is called
     */
    event Wrapped(uint256 amount);

    /**
     * @dev Emitted every time `unwrap` is called
     */
    event Unwrapped(uint256 amount);

    /**
     * @dev Emitted every time `collect` is called
     */
    event Collected(address indexed token, address indexed from, uint256 amount);

    /**
     * @dev Emitted every time `withdraw` is called
     */
    event Withdrawn(address indexed token, address indexed recipient, uint256 amount, uint256 fee);

    /**
     * @dev Tells if the smart vault is paused or not
     */
    function isPaused() external view returns (bool);

    /**
     * @dev Tells the address of the price oracle
     */
    function priceOracle() external view returns (address);

    /**
     * @dev Tells the address of the Mimic's registry
     */
    function registry() external view returns (address);

    /**
     * @dev Tells the address of the Mimic's fee controller
     */
    function feeController() external view returns (address);

    /**
     * @dev Tells the address of the wrapped native token
     */
    function wrappedNativeToken() external view returns (address);

    /**
     * @dev Tells if a connector check is ignored
     * @param connector Address of the connector being queried
     */
    function isConnectorCheckIgnored(address connector) external view returns (bool);

    /**
     * @dev Tells the balance to a balance connector for a token
     * @param id Balance connector identifier
     * @param token Address of the token querying the balance connector for
     */
    function getBalanceConnector(bytes32 id, address token) external view returns (uint256);

    /**
     * @dev Tells whether someone has any permission over the smart vault
     */
    function hasPermissions(address who) external view returns (bool);

    /**
     * @dev Pauses a smart vault
     */
    function pause() external;

    /**
     * @dev Unpauses a smart vault
     */
    function unpause() external;

    /**
     * @dev Sets the price oracle
     * @param newPriceOracle Address of the new price oracle to be set
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @dev Overrides connector checks
     * @param connector Address of the connector to override its check
     * @param ignored Whether the connector check should be ignored
     */
    function overrideConnectorCheck(address connector, bool ignored) external;

    /**
     * @dev Updates a balance connector
     * @param id Balance connector identifier to be updated
     * @param token Address of the token to update the balance connector for
     * @param amount Amount to be updated to the balance connector
     * @param add Whether the balance connector should be increased or decreased
     */
    function updateBalanceConnector(bytes32 id, address token, uint256 amount, bool add) external;

    /**
     * @dev Executes a connector inside of the Smart Vault context
     * @param connector Address of the connector that will be executed
     * @param data Call data to be used for the delegate-call
     * @return result Call response if it was successful, otherwise it reverts
     */
    function execute(address connector, bytes memory data) external returns (bytes memory result);

    /**
     * @dev Executes an arbitrary call from the Smart Vault
     * @param target Address where the call will be sent
     * @param data Call data to be used for the call
     * @param value Value in wei that will be attached to the call
     * @return result Call response if it was successful, otherwise it reverts
     */
    function call(address target, bytes memory data, uint256 value) external returns (bytes memory result);

    /**
     * @dev Wrap an amount of native tokens to the wrapped ERC20 version of it
     * @param amount Amount of native tokens to be wrapped
     */
    function wrap(uint256 amount) external;

    /**
     * @dev Unwrap an amount of wrapped native tokens
     * @param amount Amount of wrapped native tokens to unwrapped
     */
    function unwrap(uint256 amount) external;

    /**
     * @dev Collect tokens from an external account to the Smart Vault
     * @param token Address of the token to be collected
     * @param from Address where the tokens will be transferred from
     * @param amount Amount of tokens to be transferred
     */
    function collect(address token, address from, uint256 amount) external;

    /**
     * @dev Withdraw tokens to an external account
     * @param token Address of the token to be withdrawn
     * @param recipient Address where the tokens will be transferred to
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(address token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import '@mimic-fi/v3-authorizer/contracts/interfaces/IAuthorized.sol';

/**
 * @dev Base task interface
 */
interface IBaseTask is IAuthorized {
    // Execution type serves for relayers in order to distinguish how each task must be executed
    // solhint-disable-next-line func-name-mixedcase
    function EXECUTION_TYPE() external view returns (bytes32);

    /**
     * @dev The balance connectors are the same
     */
    error TaskSameBalanceConnectors(bytes32 connectorId);

    /**
     * @dev The smart vault's price oracle is not set
     */
    error TaskSmartVaultPriceOracleNotSet(address smartVault);

    /**
     * @dev Emitted every time a task is executed
     */
    event Executed();

    /**
     * @dev Emitted every time the balance connectors are set
     */
    event BalanceConnectorsSet(bytes32 indexed previous, bytes32 indexed next);

    /**
     * @dev Tells the address of the Smart Vault tied to it, it cannot be changed
     */
    function smartVault() external view returns (address);

    /**
     * @dev Tells the balance connector id of the previous task in the workflow
     */
    function previousBalanceConnectorId() external view returns (bytes32);

    /**
     * @dev Tells the balance connector id of the next task in the workflow
     */
    function nextBalanceConnectorId() external view returns (bytes32);

    /**
     * @dev Tells the address from where the token amounts to execute this task are fetched.
     * This address must the the Smart Vault in case the previous balance connector is set.
     */
    function getTokensSource() external view returns (address);

    /**
     * @dev Tells the amount a task should use for a token
     * @param token Address of the token being queried
     */
    function getTaskAmount(address token) external view returns (uint256);

    /**
     * @dev Sets the balance connector IDs
     * @param previous Balance connector id of the previous task in the workflow
     * @param next Balance connector id of the next task in the workflow
     */
    function setBalanceConnectors(bytes32 previous, bytes32 next) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './IBaseTask.sol';

/**
 * @dev Gas limited task interface
 */
interface IGasLimitedTask is IBaseTask {
    /**
     * @dev The tx initial gas cache has not been initialized
     */
    error TaskGasNotInitialized();

    /**
     * @dev The gas price used is greater than the limit
     */
    error TaskGasPriceLimitExceeded(uint256 gasPrice, uint256 gasPriceLimit);

    /**
     * @dev The priority fee used is greater than the priority fee limit
     */
    error TaskPriorityFeeLimitExceeded(uint256 priorityFee, uint256 priorityFeeLimit);

    /**
     * @dev The transaction cost is greater than the transaction cost limit
     */
    error TaskTxCostLimitExceeded(uint256 txCost, uint256 txCostLimit);

    /**
     * @dev The transaction cost percentage is greater than the transaction cost limit percentage
     */
    error TaskTxCostLimitPctExceeded(uint256 txCostPct, uint256 txCostLimitPct);

    /**
     * @dev The new transaction cost limit percentage is greater than one
     */
    error TaskTxCostLimitPctAboveOne();

    /**
     * @dev Emitted every time the gas price limit is set
     */
    event GasPriceLimitSet(uint256 gasPriceLimit);

    /**
     * @dev Emitted every time the priority fee limit is set
     */
    event PriorityFeeLimitSet(uint256 priorityFeeLimit);

    /**
     * @dev Emitted every time the transaction cost limit is set
     */
    event TxCostLimitSet(uint256 txCostLimit);

    /**
     * @dev Emitted every time the transaction cost limit percentage is set
     */
    event TxCostLimitPctSet(uint256 txCostLimitPct);

    /**
     * @dev Tells the gas price limit
     */
    function gasPriceLimit() external view returns (uint256);

    /**
     * @dev Tells the priority fee limit
     */
    function priorityFeeLimit() external view returns (uint256);

    /**
     * @dev Tells the transaction cost limit
     */
    function txCostLimit() external view returns (uint256);

    /**
     * @dev Tells the transaction cost limit percentage
     */
    function txCostLimitPct() external view returns (uint256);

    /**
     * @dev Sets the gas price limit
     * @param newGasPriceLimit New gas price limit to be set
     */
    function setGasPriceLimit(uint256 newGasPriceLimit) external;

    /**
     * @dev Sets the priority fee limit
     * @param newPriorityFeeLimit New priority fee limit to be set
     */
    function setPriorityFeeLimit(uint256 newPriorityFeeLimit) external;

    /**
     * @dev Sets the transaction cost limit
     * @param newTxCostLimit New transaction cost limit to be set
     */
    function setTxCostLimit(uint256 newTxCostLimit) external;

    /**
     * @dev Sets the transaction cost limit percentage
     * @param newTxCostLimitPct New transaction cost limit percentage to be set
     */
    function setTxCostLimitPct(uint256 newTxCostLimitPct) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './IBaseTask.sol';

/**
 * @dev Time-locked task interface
 */
interface ITimeLockedTask is IBaseTask {
    /**
     * @dev The time-lock has not expired
     */
    error TaskTimeLockNotExpired(uint256 expiration, uint256 currentTimestamp);

    /**
     * @dev The execution period has expired
     */
    error TaskTimeLockWaitNextPeriod(uint256 offset, uint256 executionPeriod);

    /**
     * @dev The execution period is greater than the time-lock delay
     */
    error TaskExecutionPeriodGtDelay(uint256 executionPeriod, uint256 delay);

    /**
     * @dev Emitted every time a new time-lock delay is set
     */
    event TimeLockDelaySet(uint256 delay);

    /**
     * @dev Emitted every time a new expiration timestamp is set
     */
    event TimeLockExpirationSet(uint256 expiration);

    /**
     * @dev Emitted every time a new execution period is set
     */
    event TimeLockExecutionPeriodSet(uint256 period);

    /**
     * @dev Tells the time-lock delay in seconds
     */
    function timeLockDelay() external view returns (uint256);

    /**
     * @dev Tells the time-lock expiration timestamp
     */
    function timeLockExpiration() external view returns (uint256);

    /**
     * @dev Tells the time-lock execution period
     */
    function timeLockExecutionPeriod() external view returns (uint256);

    /**
     * @dev Sets the time-lock delay
     * @param delay New delay to be set
     */
    function setTimeLockDelay(uint256 delay) external;

    /**
     * @dev Sets the time-lock expiration timestamp
     * @param expiration New expiration timestamp to be set
     */
    function setTimeLockExpiration(uint256 expiration) external;

    /**
     * @dev Sets the time-lock execution period
     * @param period New execution period to be set
     */
    function setTimeLockExecutionPeriod(uint256 period) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './IBaseTask.sol';

/**
 * @dev Token indexed task interface
 */
interface ITokenIndexedTask is IBaseTask {
    /**
     * @dev Acceptance list types: either deny-list to express "all except" or allow-list to express "only"
     */
    enum TokensAcceptanceType {
        DenyList,
        AllowList
    }

    /**
     * @dev The acceptance token is zero
     */
    error TaskAcceptanceTokenZero();

    /**
     * @dev The tokens acceptance input length mismatch
     */
    error TaskAcceptanceInputLengthMismatch();

    /**
     * @dev The token is not allowed
     */
    error TaskTokenNotAllowed(address token);

    /**
     * @dev Emitted every time a tokens acceptance type is set
     */
    event TokensAcceptanceTypeSet(TokensAcceptanceType acceptanceType);

    /**
     * @dev Emitted every time a token is added or removed from the acceptance list
     */
    event TokensAcceptanceListSet(address indexed token, bool added);

    /**
     * @dev Tells the acceptance type of the config
     */
    function tokensAcceptanceType() external view returns (TokensAcceptanceType);

    /**
     * @dev Sets the tokens acceptance type of the task
     * @param newTokensAcceptanceType New token acceptance type to be set
     */
    function setTokensAcceptanceType(TokensAcceptanceType newTokensAcceptanceType) external;

    /**
     * @dev Updates the list of tokens of the tokens acceptance list
     * @param tokens List of tokens to be updated from the acceptance list
     * @param added Whether each of the given tokens should be added or removed from the list
     */
    function setTokensAcceptanceList(address[] memory tokens, bool[] memory added) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General External License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General External License for more details.

// You should have received a copy of the GNU General External License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './IBaseTask.sol';

/**
 * @dev Token threshold task interface
 */
interface ITokenThresholdTask is IBaseTask {
    /**
     * @dev Threshold defined by a token address and min/max values
     */
    struct Threshold {
        address token;
        uint256 min;
        uint256 max;
    }

    /**
     * @dev The token threshold token is zero
     */
    error TaskThresholdTokenZero();

    /**
     * @dev The token threshold to be set is invalid
     */
    error TaskInvalidThresholdInput(address token, uint256 min, uint256 max);

    /**
     * @dev The token threshold has not been met
     */
    error TaskTokenThresholdNotMet(address token, uint256 amount, uint256 min, uint256 max);

    /**
     * @dev Emitted every time a default threshold is set
     */
    event DefaultTokenThresholdSet(address token, uint256 min, uint256 max);

    /**
     * @dev Emitted every time a token threshold is set
     */
    event CustomTokenThresholdSet(address indexed token, address thresholdToken, uint256 min, uint256 max);

    /**
     * @dev Tells the default token threshold
     */
    function defaultTokenThreshold() external view returns (Threshold memory);

    /**
     * @dev Tells the custom threshold defined for a specific token
     * @param token Address of the token being queried
     */
    function customTokenThreshold(address token) external view returns (Threshold memory);

    /**
     * @dev Tells the threshold that should be used for a token
     * @param token Address of the token being queried
     */
    function getTokenThreshold(address token) external view returns (Threshold memory);

    /**
     * @dev Sets a new default threshold config
     * @param thresholdToken New threshold token to be set
     * @param thresholdMin New threshold minimum to be set
     * @param thresholdMax New threshold maximum to be set
     */
    function setDefaultTokenThreshold(address thresholdToken, uint256 thresholdMin, uint256 thresholdMax) external;

    /**
     * @dev Sets a custom token threshold
     * @param token Address of the token to set a custom threshold
     * @param thresholdToken New custom threshold token to be set
     * @param thresholdMin New custom threshold minimum to be set
     * @param thresholdMax New custom threshold maximum to be set
     */
    function setCustomTokenThreshold(address token, address thresholdToken, uint256 thresholdMin, uint256 thresholdMax)
        external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './IBaseTask.sol';

/**
 * @dev Volume limited task interface
 */
interface IVolumeLimitedTask is IBaseTask {
    /**
     * @dev Volume limit config
     * @param token Address to measure the volume limit
     */
    struct VolumeLimit {
        address token;
        uint256 amount;
        uint256 accrued;
        uint256 period;
        uint256 nextResetTime;
    }

    /**
     * @dev The volume limit token is zero
     */
    error TaskVolumeLimitTokenZero();

    /**
     * @dev The volume limit to be set is invalid
     */
    error TaskInvalidVolumeLimitInput(address token, uint256 amount, uint256 period);

    /**
     * @dev The volume limit has been exceeded
     */
    error TaskVolumeLimitExceeded(address token, uint256 limit, uint256 volume);

    /**
     * @dev Emitted every time a default volume limit is set
     */
    event DefaultVolumeLimitSet(address indexed token, uint256 amount, uint256 period);

    /**
     * @dev Emitted every time a custom volume limit is set
     */
    event CustomVolumeLimitSet(address indexed token, address indexed limitToken, uint256 amount, uint256 period);

    /**
     * @dev Tells the default volume limit set
     */
    function defaultVolumeLimit() external view returns (VolumeLimit memory);

    /**
     * @dev Tells the custom volume limit set for a specific token
     * @param token Address of the token being queried
     */
    function customVolumeLimit(address token) external view returns (VolumeLimit memory);

    /**
     * @dev Tells the volume limit that should be used for a token
     * @param token Address of the token being queried
     */
    function getVolumeLimit(address token) external view returns (VolumeLimit memory);

    /**
     * @dev Sets a the default volume limit config
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setDefaultVolumeLimit(address limitToken, uint256 limitAmount, uint256 limitPeriod) external;

    /**
     * @dev Sets a custom volume limit
     * @param token Address of the token to set a custom volume limit for
     * @param limitToken Address of the token to measure the volume limit
     * @param limitAmount Amount of tokens to be applied for the volume limit
     * @param limitPeriod Frequency to Amount of tokens to be applied for the volume limit
     */
    function setCustomVolumeLimit(address token, address limitToken, uint256 limitAmount, uint256 limitPeriod) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import './base/IBaseTask.sol';
import './base/IGasLimitedTask.sol';
import './base/ITimeLockedTask.sol';
import './base/ITokenIndexedTask.sol';
import './base/ITokenThresholdTask.sol';
import './base/IVolumeLimitedTask.sol';

// solhint-disable no-empty-blocks

/**
 * @dev Task interface
 */
interface ITask is
    IBaseTask,
    IGasLimitedTask,
    ITimeLockedTask,
    ITokenIndexedTask,
    ITokenThresholdTask,
    IVolumeLimitedTask
{

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @dev Relayer interface
 */
interface IRelayer {
    /**
     * @dev The token is zero
     */
    error RelayerTokenZero();

    /**
     * @dev The amount is zero
     */
    error RelayerAmountZero();

    /**
     * @dev The collector is zero
     */
    error RelayerCollectorZero();

    /**
     * @dev The recipient is zero
     */
    error RelayerRecipientZero();

    /**
     * @dev The executor is zero
     */
    error RelayerExecutorZero();

    /**
     * @dev Relayer no task given to execute
     */
    error RelayerNoTaskGiven();

    /**
     * @dev Relayer input length mismatch
     */
    error RelayerInputLengthMismatch();

    /**
     * @dev The sender is not allowed
     */
    error RelayerExecutorNotAllowed(address sender);

    /**
     * @dev Trying to execute tasks from different smart vaults
     */
    error RelayerMultipleTaskSmartVaults(address task, address taskSmartVault, address expectedSmartVault);

    /**
     * @dev The task to execute does not have permissions on the associated smart vault
     */
    error RelayerTaskDoesNotHavePermissions(address task, address smartVault);

    /**
     * @dev The smart vault balance plus the available quota are lower than the amount to pay the relayer
     */
    error RelayerPaymentInsufficientBalance(address smartVault, uint256 balance, uint256 quota, uint256 amount);

    /**
     * @dev It failed to send amount minus quota to the smart vault's collector
     */
    error RelayerPaymentFailed(address smartVault, uint256 amount, uint256 quota);

    /**
     * @dev The smart vault balance is lower than the amount to withdraw
     */
    error RelayerWithdrawInsufficientBalance(address sender, uint256 balance, uint256 amount);

    /**
     * @dev It failed to send the amount to the sender
     */
    error RelayerWithdrawFailed(address sender, uint256 amount);

    /**
     * @dev The value sent and the amount differ
     */
    error RelayerValueDoesNotMatchAmount(uint256 value, uint256 amount);

    /**
     * @dev Emitted every time an executor is configured
     */
    event ExecutorSet(address indexed executor, bool allowed);

    /**
     * @dev Emitted every time the default collector is set
     */
    event DefaultCollectorSet(address indexed collector);

    /**
     * @dev Emitted every time a collector is set for a smart vault
     */
    event SmartVaultCollectorSet(address indexed smartVault, address indexed collector);

    /**
     * @dev Emitted every time a smart vault's maximum quota is set
     */
    event SmartVaultMaxQuotaSet(address indexed smartVault, uint256 maxQuota);

    /**
     * @dev Emitted every time a smart vault's task is executed
     */
    event TaskExecuted(
        address indexed smartVault,
        address indexed task,
        bytes data,
        bool success,
        bytes result,
        uint256 gas
    );

    /**
     * @dev Emitted every time some native tokens are deposited for the smart vault's balance
     */
    event Deposited(address indexed smartVault, uint256 amount);

    /**
     * @dev Emitted every time some native tokens are withdrawn from the smart vault's balance
     */
    event Withdrawn(address indexed smartVault, uint256 amount);

    /**
     * @dev Emitted every time some ERC20 tokens are withdrawn from the relayer to an external account
     */
    event FundsRescued(address indexed token, address indexed recipient, uint256 amount);

    /**
     * @dev Emitted every time a smart vault's quota is paid
     */
    event QuotaPaid(address indexed smartVault, uint256 amount);

    /**
     * @dev Emitted every time a smart vault pays for transaction gas to the relayer
     */
    event GasPaid(address indexed smartVault, uint256 amount, uint256 quota);

    /**
     * @dev Tells the default collector address
     */
    function defaultCollector() external view returns (address);

    /**
     * @dev Tells whether an executor is allowed
     * @param executor Address of the executor being queried
     */
    function isExecutorAllowed(address executor) external view returns (bool);

    /**
     * @dev Tells the smart vault available balance to relay transactions
     * @param smartVault Address of the smart vault being queried
     */
    function getSmartVaultBalance(address smartVault) external view returns (uint256);

    /**
     * @dev Tells the custom collector address set for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function getSmartVaultCollector(address smartVault) external view returns (address);

    /**
     * @dev Tells the smart vault maximum quota to be used
     * @param smartVault Address of the smart vault being queried
     */
    function getSmartVaultMaxQuota(address smartVault) external view returns (uint256);

    /**
     * @dev Tells the smart vault used quota
     * @param smartVault Address of the smart vault being queried
     */
    function getSmartVaultUsedQuota(address smartVault) external view returns (uint256);

    /**
     * @dev Tells the collector address applicable for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function getApplicableCollector(address smartVault) external view returns (address);

    /**
     * @dev Configures an external executor
     * @param executor Address of the executor to be set
     * @param allowed Whether the given executor should be allowed or not
     */
    function setExecutor(address executor, bool allowed) external;

    /**
     * @dev Sets the default collector
     * @param collector Address of the new default collector to be set
     */
    function setDefaultCollector(address collector) external;

    /**
     * @dev Sets a custom collector for a smart vault
     * @param smartVault Address of smart vault to set a collector for
     * @param collector Address of the collector to be set for the given smart vault
     */
    function setSmartVaultCollector(address smartVault, address collector) external;

    /**
     * @dev Sets a maximum quota for a smart vault
     * @param smartVault Address of smart vault to set a maximum quota for
     * @param maxQuota Maximum quota to be set for the given smart vault
     */
    function setSmartVaultMaxQuota(address smartVault, uint256 maxQuota) external;

    /**
     * @dev Deposits native tokens for a given smart vault
     * @param smartVault Address of smart vault to deposit balance for
     * @param amount Amount of native tokens to be deposited, must match msg.value
     */
    function deposit(address smartVault, uint256 amount) external payable;

    /**
     * @dev Withdraws native tokens from a given smart vault
     * @param amount Amount of native tokens to be withdrawn
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev Executes a list of tasks
     * @param tasks Addresses of the tasks to execute
     * @param data List of calldata to execute each of the given tasks
     * @param continueIfFailed Whether the execution should fail in case one of the tasks fail
     */
    function execute(address[] memory tasks, bytes[] memory data, bool continueIfFailed) external;

    /**
     * @dev Withdraw ERC20 tokens to an external account. To be used in case of accidental token transfers.
     * @param token Address of the token to be withdrawn
     * @param recipient Address where the tokens will be transferred to
     * @param amount Amount of tokens to withdraw
     */
    function rescueFunds(address token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@mimic-fi/v3-smart-vault/contracts/interfaces/ISmartVault.sol';
import '@mimic-fi/v3-tasks/contracts/interfaces/ITask.sol';

import './interfaces/IRelayer.sol';

/**
 * @title Relayer
 * @dev Relayer used to execute relayed tasks
 */
contract Relayer is IRelayer, Ownable {
    using SafeERC20 for IERC20;

    // Gas amount charged to cover base costs
    uint256 public constant BASE_GAS = 70e3;

    // Default collector address
    address public override defaultCollector;

    // List of allowed executors
    mapping (address => bool) public override isExecutorAllowed;

    // List of native token balances per smart vault
    mapping (address => uint256) public override getSmartVaultBalance;

    // List of custom collector address per smart vault
    mapping (address => address) public override getSmartVaultCollector;

    // List of maximum quota to be used per smart vault
    mapping (address => uint256) public override getSmartVaultMaxQuota;

    // List of used quota per smart vault
    mapping (address => uint256) public override getSmartVaultUsedQuota;

    /**
     * @dev Creates a new Relayer contract
     * @param executor Address of the executor that will be allowed to call the relayer
     * @param collector Address of the default collector to be set
     * @param owner Address that will own the fee collector
     */
    constructor(address executor, address collector, address owner) {
        _setExecutor(executor, true);
        _setDefaultCollector(collector);
        _transferOwnership(owner);
    }

    /**
     * @dev Tells the collector address applicable for a smart vault
     * @param smartVault Address of the smart vault being queried
     */
    function getApplicableCollector(address smartVault) public view override returns (address) {
        address customCollector = getSmartVaultCollector[smartVault];
        return customCollector != address(0) ? customCollector : defaultCollector;
    }

    /**
     * @dev Configures an external executor
     * @param executor Address of the executor to be set
     * @param allowed Whether the given executor should be allowed or not
     */
    function setExecutor(address executor, bool allowed) external override onlyOwner {
        _setExecutor(executor, allowed);
    }

    /**
     * @dev Sets the default collector
     * @param collector Address of the new default collector to be set
     */
    function setDefaultCollector(address collector) external override onlyOwner {
        _setDefaultCollector(collector);
    }

    /**
     * @dev Sets a custom collector for a smart vault
     * @param smartVault Address of smart vault to set a collector for
     * @param collector Address of the collector to be set for the given smart vault
     */
    function setSmartVaultCollector(address smartVault, address collector) external override onlyOwner {
        if (collector == address(0)) revert RelayerCollectorZero();
        getSmartVaultCollector[smartVault] = collector;
        emit SmartVaultCollectorSet(smartVault, collector);
    }

    /**
     * @dev Sets a maximum quota for a smart vault
     * @param smartVault Address of smart vault to set a maximum quota for
     * @param maxQuota Maximum quota to be set for the given smart vault
     */
    function setSmartVaultMaxQuota(address smartVault, uint256 maxQuota) external override onlyOwner {
        getSmartVaultMaxQuota[smartVault] = maxQuota;
        emit SmartVaultMaxQuotaSet(smartVault, maxQuota);
    }

    /**
     * @dev Deposits native tokens for a given smart vault. First, it will pay part of the quota if any.
     * @param smartVault Address of smart vault to deposit balance for
     * @param amount Amount of native tokens to be deposited, must match msg.value
     */
    function deposit(address smartVault, uint256 amount) external payable override {
        if (msg.value != amount) revert RelayerValueDoesNotMatchAmount(msg.value, amount);
        uint256 amountPaid = _payQuota(smartVault, amount);
        uint256 toDeposit = amount - amountPaid;
        getSmartVaultBalance[smartVault] += toDeposit;
        emit Deposited(smartVault, toDeposit);
    }

    /**
     * @dev Withdraws native tokens from the sender
     * @param amount Amount of native tokens to be withdrawn
     */
    function withdraw(uint256 amount) external override {
        uint256 balance = getSmartVaultBalance[msg.sender];
        if (amount > balance) revert RelayerWithdrawInsufficientBalance(msg.sender, balance, amount);

        getSmartVaultBalance[msg.sender] = balance - amount;
        emit Withdrawn(msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{ value: amount }('');
        if (!success) revert RelayerWithdrawFailed(msg.sender, amount);
    }

    /**
     * @dev Executes a list of tasks
     * @param tasks Addresses of the tasks to execute
     * @param data List of calldata to execute each of the given tasks
     * @param continueIfFailed Whether the execution should fail in case one of the tasks fail
     */
    function execute(address[] memory tasks, bytes[] memory data, bool continueIfFailed) external override {
        if (!isExecutorAllowed[msg.sender]) revert RelayerExecutorNotAllowed(msg.sender);
        if (tasks.length == 0) revert RelayerNoTaskGiven();
        if (tasks.length != data.length) revert RelayerInputLengthMismatch();

        uint256 totalGasUsed = BASE_GAS;
        address smartVault = ITask(tasks[0]).smartVault();
        for (uint256 i = 0; i < tasks.length; i++) {
            uint256 initialGas = gasleft();
            address task = tasks[i];

            address taskSmartVault = ITask(task).smartVault();
            if (taskSmartVault != smartVault) revert RelayerMultipleTaskSmartVaults(task, taskSmartVault, smartVault);

            bool hasPermissions = ISmartVault(smartVault).hasPermissions(task);
            if (!hasPermissions) revert RelayerTaskDoesNotHavePermissions(task, smartVault);

            // solhint-disable-next-line avoid-low-level-calls
            (bool taskSuccess, bytes memory result) = task.call(data[i]);
            uint256 gasUsed = initialGas - gasleft();
            totalGasUsed += gasUsed;
            emit TaskExecuted(smartVault, task, data[i], taskSuccess, result, gasUsed);
            if (!taskSuccess && !continueIfFailed) break;
        }

        // solhint-disable-next-line avoid-low-level-calls
        uint256 totalGasCost = totalGasUsed * tx.gasprice;
        _payTransactionGasToRelayer(smartVault, totalGasCost);
    }

    /**
     * @dev Withdraw ERC20 tokens to an external account. To be used in case of accidental token transfers.
     * @param token Address of the token to be withdrawn
     * @param recipient Address where the tokens will be transferred to
     * @param amount Amount of tokens to withdraw
     */
    function rescueFunds(address token, address recipient, uint256 amount) external override onlyOwner {
        if (token == address(0)) revert RelayerTokenZero();
        if (recipient == address(0)) revert RelayerRecipientZero();
        if (amount == 0) revert RelayerAmountZero();

        IERC20(token).safeTransfer(recipient, amount);
        emit FundsRescued(token, recipient, amount);
    }

    /**
     * @dev Configures an external executor
     * @param executor Address of the executor to be set
     * @param allowed Whether the given executor should be allowed or not
     */
    function _setExecutor(address executor, bool allowed) internal {
        if (executor == address(0)) revert RelayerExecutorZero();
        isExecutorAllowed[executor] = allowed;
        emit ExecutorSet(executor, allowed);
    }

    /**
     * @dev Sets the default collector
     * @param collector Default fee collector to be set
     */
    function _setDefaultCollector(address collector) internal {
        if (collector == address(0)) revert RelayerCollectorZero();
        defaultCollector = collector;
        emit DefaultCollectorSet(collector);
    }

    /**
     * @dev Pays transaction gas to the relayer withdrawing native tokens from a given smart vault
     * @param smartVault Address of smart vault to withdraw balance of
     * @param amount Amount of native tokens to be withdrawn
     */
    function _payTransactionGasToRelayer(address smartVault, uint256 amount) internal {
        uint256 balance = getSmartVaultBalance[smartVault];
        uint256 maxQuota = getSmartVaultMaxQuota[smartVault];
        uint256 usedQuota = getSmartVaultUsedQuota[smartVault];
        uint256 availableQuota = usedQuota >= maxQuota ? 0 : (maxQuota - usedQuota);
        bool hasEnoughBalance = amount <= balance + availableQuota;
        if (!hasEnoughBalance) revert RelayerPaymentInsufficientBalance(smartVault, balance, availableQuota, amount);

        uint256 quota;
        if (balance >= amount) {
            getSmartVaultBalance[smartVault] = balance - amount;
        } else {
            quota = amount - balance;
            getSmartVaultBalance[smartVault] = 0;
            getSmartVaultUsedQuota[smartVault] = usedQuota + quota;
        }

        (bool paySuccess, ) = getApplicableCollector(smartVault).call{ value: amount - quota }('');
        if (!paySuccess) revert RelayerPaymentFailed(smartVault, amount, quota);
        emit GasPaid(smartVault, amount, quota);
    }

    /**
     * @dev Pays part of the quota for a given smart vault, if applicable
     * @param smartVault Address of smart vault to pay quota for
     * @param toDeposit Amount of native tokens to be deposited for the smart vault
     * @return quotaPaid Amount of native tokens used to pay the quota
     */
    function _payQuota(address smartVault, uint256 toDeposit) internal returns (uint256 quotaPaid) {
        uint256 usedQuota = getSmartVaultUsedQuota[smartVault];
        if (usedQuota == 0) return 0;

        if (toDeposit > usedQuota) {
            getSmartVaultUsedQuota[smartVault] = 0;
            quotaPaid = usedQuota;
        } else {
            getSmartVaultUsedQuota[smartVault] = usedQuota - toDeposit;
            quotaPaid = toDeposit;
        }

        emit QuotaPaid(smartVault, quotaPaid);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TaskMock {
    event Succeeded();

    address public smartVault;

    constructor(address _smartVault) {
        smartVault = _smartVault;
    }

    function succeed() external returns (uint256) {
        emit Succeeded();
        return 1;
    }

    function fail() external pure {
        revert('TASK_FAILED');
    }
}