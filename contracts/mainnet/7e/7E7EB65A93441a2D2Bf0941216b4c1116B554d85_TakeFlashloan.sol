// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

/**
 * @title Shared Action Executable interface
 * @notice Provides a dma-common interface for an execute method to all Action
 */
interface Executable {
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { IVault } from "../../interfaces/balancer/IVault.sol";
import { IERC3156FlashBorrower } from "../../interfaces/flashloan/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../../interfaces/flashloan/IERC3156FlashLender.sol";
import { IFlashLoanRecipient } from "../../interfaces/flashloan/balancer/IFlashLoanRecipient.sol";
import { FlashloanData, FlashloanProvider } from "../../core/types/Common.sol";
import { OPERATION_EXECUTOR, DAI, CHAINLOG_VIEWER } from "../../core/constants/Common.sol";
import { MCD_FLASH } from "../../core/constants/Maker.sol";
import { BALANCER_VAULT } from "../../core/constants/Balancer.sol";
import { ChainLogView } from "../../core/views/ChainLogView.sol";
import { ProxyPermission } from "../../libs/DS/ProxyPermission.sol";
import { IERC20 } from "../../libs/SafeERC20.sol";

/**
 * @title TakeFlashloan Action contract
 * @notice Executes a sequence of Actions after flashloaning funds
 */
contract TakeFlashloan is Executable, ProxyPermission {
  address internal immutable dai;
  ServiceRegistry private immutable registry;

  constructor(
    ServiceRegistry _registry,
    address _dai,
    address _dsGuardFactory
  ) ProxyPermission(_dsGuardFactory) {
    registry = _registry;
    dai = _dai;
  }

  /**
   * @dev When the Flashloan lender calls back the Operation Executor we may need to re-establish the calling context.
   * @dev The isProxyFlashloan flag is used to give the Operation Executor temporary authority to call the execute method on a user"s proxy. Refers to any proxy wallet (DSProxy or DPMProxy at time of writing)
   * @dev isDPMProxy flag switches between regular DSPRoxy and DPMProxy
   * @param data Encoded calldata that conforms to the FlashloanData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    FlashloanData memory flData = parseInputs(data);
    address operationExecutorAddress = registry.getRegisteredService(OPERATION_EXECUTOR);

    if (flData.isProxyFlashloan) {
      givePermission(flData.isDPMProxy, operationExecutorAddress);
    }

    if (flData.provider == FlashloanProvider.DssFlash) {
      ChainLogView chainlogView = ChainLogView(registry.getRegisteredService(CHAINLOG_VIEWER));

      IERC3156FlashLender(chainlogView.getServiceAddress(MCD_FLASH)).flashLoan(
        IERC3156FlashBorrower(operationExecutorAddress),
        dai,
        flData.amount,
        abi.encode(flData, address(this))
      );
    }

    if (flData.provider == FlashloanProvider.Balancer) {
      IERC20[] memory tokens = new IERC20[](1);
      uint256[] memory amounts = new uint256[](1);

      tokens[0] = IERC20(flData.asset);
      amounts[0] = flData.amount;

      IVault(registry.getRegisteredService(BALANCER_VAULT)).flashLoan(
        IFlashLoanRecipient(operationExecutorAddress),
        tokens,
        amounts,
        abi.encode(flData, address(this))
      );
    }

    if (flData.isProxyFlashloan) {
      removePermission(flData.isDPMProxy, operationExecutorAddress);
    }
  }

  function parseInputs(bytes memory _callData) public pure returns (FlashloanData memory params) {
    return abi.decode(_callData, (FlashloanData));
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

string constant BALANCER_VAULT = "BalancerVault";

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

string constant OPERATION_STORAGE = "OperationStorage_2";
string constant OPERATION_EXECUTOR = "OperationExecutor_2";
string constant OPERATIONS_REGISTRY = "OperationsRegistry_2";
string constant CHAINLOG_VIEWER = "ChainLogView";
string constant ONE_INCH_AGGREGATOR = "OneInchAggregator";
string constant DS_GUARD_FACTORY = "DSGuardFactory";
string constant WETH = "WETH";
string constant DAI = "DAI";
uint256 constant RAY = 10 ** 27;
bytes32 constant NULL = "";

/**
 * @dev We do not include patch versions in contract names to allow
 * for hotfixes of Action dma-contracts
 * and to limit updates to TheGraph
 * if the types encoded in emitted events change then use a minor version and
 * update the ServiceRegistry with a new entry
 * and update TheGraph decoding accordingly
 */
string constant POSITION_CREATED_ACTION = "PositionCreated";

string constant UNISWAP_ROUTER = "UniswapRouter";
string constant SWAP = "Swap";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

string constant FLASH_MINT_MODULE = "McdFlashMintModule";

string constant MCD_MANAGER = "McdManager";
string constant MCD_JUG = "McdJug";
string constant MCD_JOIN_DAI = "McdJoinDai";

string constant MCD_FLASH = "MCD_FLASH";

// SPDX-License-Identifier: AGPL-3.0-or-later

/// ServiceRegistry.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

contract ServiceRegistry {
  uint256 public constant MAX_DELAY = 30 days;

  mapping(bytes32 => uint256) public lastExecuted;
  mapping(bytes32 => address) private namedService;
  mapping(bytes32 => bool) private invalidHashes;
  address public owner;
  uint256 public requiredDelay;

  modifier validateInput(uint256 len) {
    require(msg.data.length == len, "registry/illegal-padding");
    _;
  }

  modifier delayedExecution() {
    bytes32 operationHash = keccak256(msg.data);
    uint256 reqDelay = requiredDelay;

    /* solhint-disable not-rely-on-time */
    if (lastExecuted[operationHash] == 0 && reqDelay > 0) {
      // not called before, scheduled for execution
      lastExecuted[operationHash] = block.timestamp;
      emit ChangeScheduled(operationHash, block.timestamp + reqDelay, msg.data);
    } else {
      require(block.timestamp - reqDelay > lastExecuted[operationHash], "registry/delay-too-small");
      emit ChangeApplied(operationHash, block.timestamp, msg.data);
      _;
      lastExecuted[operationHash] = 0;
    }
    /* solhint-enable not-rely-on-time */
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "registry/only-owner");
    _;
  }

  constructor(uint256 initialDelay) {
    require(initialDelay <= MAX_DELAY, "registry/invalid-delay");
    requiredDelay = initialDelay;
    owner = msg.sender;
  }

  function transferOwnership(
    address newOwner
  ) external onlyOwner validateInput(36) delayedExecution {
    owner = newOwner;
  }

  function changeRequiredDelay(
    uint256 newDelay
  ) external onlyOwner validateInput(36) delayedExecution {
    require(newDelay <= MAX_DELAY, "registry/invalid-delay");
    requiredDelay = newDelay;
  }

  function getServiceNameHash(string memory name) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(name));
  }

  function addNamedService(
    bytes32 serviceNameHash,
    address serviceAddress
  ) external onlyOwner validateInput(68) delayedExecution {
    require(invalidHashes[serviceNameHash] == false, "registry/service-name-used-before");
    require(namedService[serviceNameHash] == address(0), "registry/service-override");
    namedService[serviceNameHash] = serviceAddress;
    emit NamedServiceAdded(serviceNameHash, serviceAddress);
  }

  function removeNamedService(bytes32 serviceNameHash) external onlyOwner validateInput(36) {
    require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
    namedService[serviceNameHash] = address(0);
    invalidHashes[serviceNameHash] = true;
    emit NamedServiceRemoved(serviceNameHash);
  }

  function getRegisteredService(string memory serviceName) external view returns (address) {
    return namedService[keccak256(abi.encodePacked(serviceName))];
  }

  function getServiceAddress(bytes32 serviceNameHash) external view returns (address) {
    return namedService[serviceNameHash];
  }

  function clearScheduledExecution(
    bytes32 scheduledExecution
  ) external onlyOwner validateInput(36) {
    require(lastExecuted[scheduledExecution] > 0, "registry/execution-not-scheduled");
    lastExecuted[scheduledExecution] = 0;
    emit ChangeCancelled(scheduledExecution);
  }

  event ChangeScheduled(bytes32 dataHash, uint256 scheduledFor, bytes data);
  event ChangeApplied(bytes32 dataHash, uint256 appliedAt, bytes data);
  event ChangeCancelled(bytes32 dataHash);
  event NamedServiceRemoved(bytes32 nameHash);
  event NamedServiceAdded(bytes32 nameHash, address service);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

enum FlashloanProvider {
  DssFlash,
  Balancer
}

struct FlashloanData {
  uint256 amount;
  address asset;
  bool isProxyFlashloan;
  bool isDPMProxy;
  FlashloanProvider provider;
  Call[] calls;
}

struct PullTokenData {
  address asset;
  address from;
  uint256 amount;
}

struct SendTokenData {
  address asset;
  address to;
  uint256 amount;
}

struct SetApprovalData {
  address asset;
  address delegate;
  uint256 amount;
  bool sumAmounts;
}

struct SwapData {
  address fromAsset;
  address toAsset;
  uint256 amount;
  uint256 receiveAtLeast;
  uint256 fee;
  bytes withData;
  bool collectFeeInFromToken;
}

struct Call {
  bytes32 targetHash;
  bytes callData;
  bool skipped;
}

struct Operation {
  uint8 currentAction;
  bytes32[] actions;
}

struct WrapEthData {
  uint256 amount;
}

struct UnwrapEthData {
  uint256 amount;
}

struct ReturnFundsData {
  address asset;
}

struct PositionCreatedData {
  string protocol;
  string positionType;
  address collateralToken;
  address debtToken;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { IChainLog } from "../../interfaces/maker/IChainLog.sol";

/**
 * @title ChainLogView
 * @notice Reads the Chainlog contract to get the address of a service by its name
 */
contract ChainLogView {
  address public immutable chainlogAddress;

  constructor(address _chainlogAddress) {
    chainlogAddress = _chainlogAddress;
  }

  /**
   * @notice Gets the string representation of a bytes32 value with `-` replaced with `_`
   * @param _bytes32 value to decode to string
   * @return The decoded string
   */
  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      if (_bytes32[i] == bytes1("-")) {
        bytesArray[i] = bytes1("_");
      } else {
        bytesArray[i] = _bytes32[i];
      }
    }
    return string(bytesArray);
  }

  /**
   * @notice Gets the address of a service by its name
   * @param serviceName The name of the service
   * @return The address of the service
   */

  function getServiceAddress(string calldata serviceName) public view returns (address) {
    bytes32 serviceHash = bytes32(abi.encodePacked(serviceName));
    return IChainLog(chainlogAddress).getAddress(serviceHash);
  }

  /**
   * @notice Gets the address of a join adapter by its ilk name
   * @param ilkName The name of the ilk
   * @return The address of the join adapter
   */
  function getIlkJoinAddressByName(string calldata ilkName) public view returns (address) {
    bytes32 ilkHash = bytes32(abi.encodePacked("MCD_JOIN_", ilkName));
    return IChainLog(chainlogAddress).getAddress(ilkHash);
  }

  /**
   * @notice Gets the address of a join adapter by its ilk hash
   * @param ilkHash The hash of the ilk name
   * @return The address of the join adapter
   */
  function getIlkJoinAddressByHash(bytes32 ilkHash) public view returns (address) {
    bytes32 newIlkHash = bytes32(abi.encodePacked("MCD_JOIN_", bytes32ToString(ilkHash)));
    return IChainLog(chainlogAddress).getAddress(newIlkHash);
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { IFlashLoanRecipient } from "../flashloan/balancer/IFlashLoanRecipient.sol";
import { IERC20 } from "../../libs/SafeERC20.sol";

interface IVault {
  function flashLoan(
    IFlashLoanRecipient recipient,
    IERC20[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.15;

interface IAccountGuard {
  function owners(address) external view returns (address);

  function owner() external view returns (address);

  function setWhitelist(address target, bool status) external;

  function canCall(address proxy, address operator) external view returns (bool);

  function permit(address caller, address target, bool allowance) external;

  function isWhitelisted(address target) external view returns (bool);

  function isWhitelistedSend(address target) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.15;

interface IAccountImplementation {
  function execute(address _target, bytes memory _data) external payable returns (bytes32 response);

  function send(address _target, bytes memory _data) external payable;

  function owner() external view returns (address owner);

  function guard() external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

interface IDSProxy {
  function owner() external returns (address);

  function execute(bytes memory, bytes memory) external payable returns (address, bytes memory);

  function execute(address, bytes memory) external payable returns (bytes memory);

  function setCache(address _cacheAddr) external returns (bool);
}

interface IDSAuthority {
  function canCall(address, address, bytes4) external view returns (bool);
}

interface IDSAuth {
  function authority() external returns (IDSAuthority);

  function setAuthority(IDSAuthority) external;
}

interface IDSGuard {
  function canCall(address, address, bytes4) external view returns (bool);

  function permit(address, address, bytes32) external;

  function forbid(address, address, bytes32) external;
}

interface IDSGuardFactory {
  function newGuard() external returns (IDSGuard);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { IERC20 } from "../../../libs/SafeERC20.sol";

interface IFlashLoanRecipient {
  /**
   * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
   *
   * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
   * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
   * Vault, or else the entire flash loan will revert.
   *
   * `userData` is the same value passed in the `IVault.flashLoan` call.
   */
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

interface IERC3156FlashBorrower {
  /**
   * @dev Receive a flash loan.
   * @param initiator The initiator of the loan.
   * @param token The loan currency.
   * @param amount The amount of tokens lent.
   * @param fee The additional amount of tokens to repay.
   * @param data Arbitrary data structure, intended to contain user-defined parameters.
   * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
   */
  function onFlashLoan(
    address initiator,
    address token,
    uint256 amount,
    uint256 fee,
    bytes calldata data
  ) external returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
  /**
   * @dev The amount of currency available to be lent.
   * @param token The loan currency.
   * @return The amount of `token` that can be borrowed.
   */
  function maxFlashLoan(address token) external view returns (uint256);

  /**
   * @dev The fee to be charged for a given loan.
   * @param token The loan currency.
   * @param amount The amount of tokens lent.
   * @return The amount of `token` to be charged for the loan, on top of the returned principal.
   */
  function flashFee(address token, uint256 amount) external view returns (uint256);

  /**
   * @dev Initiate a flash loan.
   * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
   * @param token The loan currency.
   * @param amount The amount of tokens lent.
   * @param data Arbitrary data structure, intended to contain user-defined parameters.
   */
  function flashLoan(
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
  ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.15;

abstract contract IChainLog {
  function getAddress(bytes32 _key) public view virtual returns (address addr);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20 {
  function totalSupply() external view returns (uint256 supply);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value) external returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  function approve(address _spender, uint256 _value) external returns (bool success);

  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  function decimals() external view returns (uint256 digits);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

library Address {
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    if (success) {
      return returndata;
    }

    if (returndata.length > 0) {
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    }

    revert(errorMessage);
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

import { FlashloanData } from "../../core/types/Common.sol";
import { IAccountImplementation } from "../../interfaces/dpm/IAccountImplementation.sol";
import { IAccountGuard } from "../../interfaces/dpm/IAccountGuard.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { DS_GUARD_FACTORY } from "../../core/constants/Common.sol";
import { IDSGuardFactory, IDSGuard, IDSAuth, IDSAuthority } from "../../interfaces/ds/IDSProxy.sol";

contract ProxyPermission {
  IDSGuardFactory internal immutable dsGuardFactory;
  bytes4 public constant ALLOWED_METHOD_HASH = bytes4(keccak256("execute(address,bytes)"));

  constructor(address _dsGuardFactory) {
    dsGuardFactory = IDSGuardFactory(_dsGuardFactory);
  }

  function givePermission(bool isDPMProxy, address _contractAddr) public {
    if (isDPMProxy) {
      // DPM permission
      IAccountGuard(IAccountImplementation(address(this)).guard()).permit(
        _contractAddr,
        address(this),
        true
      );
    } else {
      // DSProxy permission
      address currAuthority = address(IDSAuth(address(this)).authority());
      IDSGuard guard = IDSGuard(currAuthority);
      if (currAuthority == address(0)) {
        guard = dsGuardFactory.newGuard();
        IDSAuth(address(this)).setAuthority(IDSAuthority(address(guard)));
      }

      if (!guard.canCall(_contractAddr, address(this), ALLOWED_METHOD_HASH)) {
        guard.permit(_contractAddr, address(this), ALLOWED_METHOD_HASH);
      }
    }
  }

  function removePermission(bool isDPMProxy, address _contractAddr) public {
    if (isDPMProxy) {
      // DPM permission
      IAccountGuard(IAccountImplementation(address(this)).guard()).permit(
        _contractAddr,
        address(this),
        false
      );
    } else {
      // DSProxy permission
      address currAuthority = address(IDSAuth(address(this)).authority());
      if (currAuthority == address(0)) {
        return;
      }
      IDSGuard guard = IDSGuard(currAuthority);
      guard.forbid(_contractAddr, address(this), ALLOWED_METHOD_HASH);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import { IERC20 } from "../interfaces/tokens/IERC20.sol";
import { Address } from "./Address.sol";
import { SafeMath } from "./SafeMath.sol";

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {ERC20-approve}, and its usage is discouraged.
   */
  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}