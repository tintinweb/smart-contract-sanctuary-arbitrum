// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ConnextHandler
 *
 * @author Fujidao Labs
 *
 * @notice Handles failed transactions from Connext and keeps custody of
 * the transferred funds.
 */

import {ConnextRouter} from "./ConnextRouter.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {IVault} from "../interfaces/IVault.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ConnextHandler {
  /**
   * @dev Contains the information of a failed transaction.
   */
  struct FailedTxn {
    bytes32 transferId;
    uint256 amount;
    address asset;
    address originSender;
    uint32 originDomain;
    IRouter.Action[] actions;
    bytes[] args;
    uint128 nonce;
    bool executed;
  }

  /**
   * @dev Emitted when a failed transaction is recorded.
   *
   * @param transferId  unique id of the cross-chain txn
   * @param amount transferred
   * @param asset being transferred
   * @param originSender of the cross-chain txn
   * @param originDomain of the cross-chain txn
   * @param actions to be called in xBundle
   * @param args to be called for each action in xBundle
   * @param nonce of failed txn
   */
  event FailedTxnRecorded(
    bytes32 indexed transferId,
    uint256 amount,
    address asset,
    address originSender,
    uint32 originDomain,
    IRouter.Action[] actions,
    bytes[] args,
    uint128 nonce
  );

  /**
   * @dev Emitted when a failed transaction gets retried.
   *
   * @param transferId the unique identifier of the cross-chain txn
   * @param success boolean
   * @param oldArgs of the failed transaction
   * @param newArgs attemped in execution
   */
  event FailedTxnExecuted(
    bytes32 indexed transferId,
    IRouter.Action[] oldActions,
    IRouter.Action[] newActions,
    bytes[] oldArgs,
    bytes[] newArgs,
    uint128 nonce,
    bool indexed success
  );

  /// @dev Custom errors
  error ConnextHandler__callerNotConnextRouter();
  error ConnextHandler__executeFailed_emptyTxn();
  error ConnextHandler__executeFailed_tranferAlreadyExecuted(bytes32 transferId, uint128 nonce);

  bytes32 private constant ZERO_BYTES32 =
    0x0000000000000000000000000000000000000000000000000000000000000000;

  ConnextRouter public immutable connextRouter;

  /**
   * @dev Maps a failed transferId -> nonce -> calldata
   * Multiple failed attempts are registered with nonce
   */
  mapping(bytes32 => mapping(uint256 => FailedTxn)) private _failedTxns;

  modifier onlyConnextRouter() {
    if (msg.sender != address(connextRouter)) {
      revert ConnextHandler__callerNotConnextRouter();
    }
    _;
  }

  /// @dev Modifier that checks `msg.sender` is an allowed called in {ConnextRouter}.
  modifier onlyAllowedCaller() {
    if (!connextRouter.isAllowedCaller(msg.sender)) {
      revert ConnextHandler__callerNotConnextRouter();
    }
    _;
  }

  /**
   * @notice Constructor that initialized
   */
  constructor(address connextRouter_) {
    connextRouter = ConnextRouter(payable(connextRouter_));
  }

  /**
   * @notice Returns the struct of failed transaction by `transferId`.
   *
   * @param transferId the unique identifier of the cross-chain txn
   * @param nonce attempt of failed tx
   */
  function getFailedTxn(bytes32 transferId, uint128 nonce) public view returns (FailedTxn memory) {
    return _failedTxns[transferId][nonce];
  }

  function getFailedTxnNextNonce(bytes32 transferId) public view returns (uint128 next) {
    next = 0;
    for (uint256 i; i < type(uint8).max;) {
      if (!isTransferIdRecorded(transferId, uint128(i))) {
        next = uint128(i);
        break;
      }
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Returns the true if the failed transaction is already recorded.
   *
   * @param transferId the unique identifier of the cross-chain txn
   */
  function isTransferIdRecorded(bytes32 transferId, uint128 nonce) public view returns (bool) {
    FailedTxn memory ftxn = _failedTxns[transferId][nonce];
    if (ftxn.transferId != ZERO_BYTES32 && ftxn.originDomain != 0) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @notice Records a failed {ConnextRouter-xReceive} call.
   *
   * @param transferId the unique identifier of the cross-chain txn
   * @param amount the amount of transferring asset, after slippage, the recipient address receives
   * @param asset the asset being transferred
   * @param originSender the address of the contract or EOA that called xcall on the origin chain
   * @param originDomain the origin domain identifier according Connext nomenclature
   * @param actions that should be executed in {BaseRouter-internalBundle}
   * @param args for the actions
   *
   * @dev At this point of execution {ConnextRouter} sent all balance of `asset` to this contract.
   * It has already been verified that `amount` of `asset` is >= to balance sent.
   * This function does not need to emit an event since {ConnextRouter} already emit
   * a failed `XReceived` event.
   */
  function recordFailed(
    bytes32 transferId,
    uint256 amount,
    address asset,
    address originSender,
    uint32 originDomain,
    IRouter.Action[] memory actions,
    bytes[] memory args
  )
    external
    onlyConnextRouter
  {
    uint128 nextNonce = getFailedTxnNextNonce(transferId);
    _failedTxns[transferId][nextNonce] = FailedTxn(
      transferId, amount, asset, originSender, originDomain, actions, args, nextNonce, false
    );

    emit FailedTxnRecorded(
      transferId, amount, asset, originSender, originDomain, actions, args, nextNonce
    );
  }

  /**
   * @notice Executes a failed transaction with update `args`
   *
   * @param transferId the unique identifier of the cross-chain txn
   * @param nonce of the failed attempt to execute
   * @param actions  that will replace actions of failed txn
   * @param args taht will replace args of failed txn
   *
   * @dev Requirements:
   * - Must only be called by an allowed caller in {ConnextRouter}.
   * - Must clear the txn from `_failedTxns` mapping if execution succeeds.
   * - Must replace `sender` in `args` for value tranfer type actions (Deposit-Payback-Swap}.
   */
  function executeFailedWithUpdatedArgs(
    bytes32 transferId,
    uint128 nonce,
    IRouter.Action[] memory actions,
    bytes[] memory args
  )
    external
    onlyAllowedCaller
  {
    FailedTxn memory txn = _failedTxns[transferId][nonce];

    if (txn.transferId == ZERO_BYTES32 || txn.originDomain == 0) {
      revert ConnextHandler__executeFailed_emptyTxn();
    } else if (txn.executed) {
      revert ConnextHandler__executeFailed_tranferAlreadyExecuted(transferId, nonce);
    }

    IERC20(txn.asset).approve(address(connextRouter), txn.amount);

    try connextRouter.xBundle(actions, args) {
      txn.executed = true;
      _failedTxns[transferId][nonce] = txn;
      emit FailedTxnExecuted(transferId, txn.actions, actions, txn.args, args, nonce, true);
    } catch {
      emit FailedTxnExecuted(transferId, txn.actions, actions, txn.args, args, nonce, false);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ConnextRouter
 *
 * @author Fujidao Labs
 *
 * @notice A Router implementing Connext specific bridging logic.
 */

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IConnext, IXReceiver} from "../interfaces/connext/IConnext.sol";
import {ConnextHandler} from "./ConnextHandler.sol";
import {BaseRouter} from "../abstracts/BaseRouter.sol";
import {IWETH9} from "../abstracts/WETH9.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IVaultPermissions} from "../interfaces/IVaultPermissions.sol";
import {IChief} from "../interfaces/IChief.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {IFlasher} from "../interfaces/IFlasher.sol";
import {LibBytes} from "../libraries/LibBytes.sol";

contract ConnextRouter is BaseRouter, IXReceiver {
  /**
   * @dev Emitted when a new destination router gets added.
   *
   * @param router the router on another chain
   * @param domain the destination domain identifier according Connext nomenclature
   */
  event NewRouterAdded(address indexed router, uint256 indexed domain);

  /**
   * @dev Emitted when Connext `xCall` is invoked.
   *
   * @param transferId the unique identifier of the crosschain transfer
   * @param caller the account that called the function
   * @param receiver the router on destDomain
   * @param destDomain the destination domain identifier according Connext nomenclature
   * @param asset the asset being transferred
   * @param amount the amount of transferring asset the recipient address receives
   * @param callData the calldata sent to destination router that will get decoded and executed
   */
  event XCalled(
    bytes32 indexed transferId,
    address indexed caller,
    address indexed receiver,
    uint256 destDomain,
    address asset,
    uint256 amount,
    bytes callData
  );

  /**
   * @dev Emitted when the router receives a cross-chain call.
   *
   * @param transferId the unique identifier of the crosschain transfer
   * @param originDomain the origin domain identifier according Connext nomenclature
   * @param success whether or not the xBundle call succeeds
   * @param asset the asset being transferred
   * @param amount the amount of transferring asset the recipient address receives
   * @param callData the calldata that will get decoded and executed
   */
  event XReceived(
    bytes32 indexed transferId,
    uint256 indexed originDomain,
    bool success,
    address asset,
    uint256 amount,
    bytes callData
  );

  /// @dev Custom Errors
  error ConnextRouter__setRouter_invalidInput();
  error ConnextRouter__xReceive_notReceivedAssetBalance();
  error ConnextRouter__xReceive_notAllowedCaller();
  error ConnextRouter__xReceiver_noValueTransferUseXbundle();
  error ConnnextRouter__xBundleConnext_notSelfCalled();

  /// @dev The connext contract on the origin domain.
  IConnext public immutable connext;

  ConnextHandler public immutable handler;

  /**
   * @notice A mapping of a domain of another chain and a deployed router there.
   *
   * @dev For the list of domains supported by Connext,
   * plz check: https://docs.connext.network/resources/deployments
   */
  mapping(uint256 => address) public routerByDomain;

  modifier onlySelf() {
    if (msg.sender != address(this)) {
      revert ConnnextRouter__xBundleConnext_notSelfCalled();
    }
    _;
  }

  constructor(IWETH9 weth, IConnext connext_, IChief chief) BaseRouter(weth, chief) {
    connext = connext_;
    handler = new ConnextHandler(address(this));
    _allowCaller(msg.sender, true);
  }

  /*////////////////////////////////////
        Connext specific functions
  ////////////////////////////////////*/

  /**
   * @notice Called by Connext on the destination chain.
   *
   * @param transferId the unique identifier of the crosschain transfer
   * @param amount the amount of transferring asset, after slippage, the recipient address receives
   * @param asset the asset being transferred
   * @param originSender the address of the contract or EOA that called xcall on the origin chain
   * @param originDomain the origin domain identifier according Connext nomenclature
   * @param callData the calldata that will get decoded and executed, see "Requirements"
   *
   * @dev It does not perform authentication of the calling address. As a result of that,
   * all txns go through Connext's fast path.
   * If `xBundle` fails internally, this contract will send the received funds to {ConnextHandler}.
   *
   * Requirements:
   * - `calldata` parameter must be encoded with the following structure:
   *     > abi.encode(Action[] actions, bytes[] args)
   * - actions: array of serialized actions to execute from available enum {IRouter.Action}.
   * - args: array of encoded arguments according to each action. See {BaseRouter-internalBundle}.
   */
  function xReceive(
    bytes32 transferId,
    uint256 amount,
    address asset,
    address originSender,
    uint32 originDomain,
    bytes memory callData
  )
    external
    returns (bytes memory)
  {
    (Action[] memory actions, bytes[] memory args) = abi.decode(callData, (Action[], bytes[]));

    uint256 balance;
    uint256 beforeSlipped;
    if (amount > 0) {
      // Ensure that at this entry point expected `asset` `amount` is received.
      balance = IERC20(asset).balanceOf(address(this));
      if (balance < amount) {
        revert ConnextRouter__xReceive_notReceivedAssetBalance();
      } else {
        _tempTokenToCheck = Snapshot(asset, balance - amount);
      }

      /**
       * @dev Due to the AMM nature of Connext, there could be some slippage
       * incurred on the amount that this contract receives after bridging.
       * There is also a routing fee of 0.05% of the bridged amount.
       * The slippage can't be calculated upfront so that's why we need to
       * replace `amount` in the encoded args for the first action if
       * the action is Deposit, or Payback.
       */
      (args[0], beforeSlipped) = _accountForSlippage(amount, actions[0], args[0]);
    }

    /**
     * @dev Connext will keep the custody of the bridged amount if the call
     * to `xReceive` fails. That's why we need to ensure the funds are not stuck at Connext.
     * Therefore we try/catch instead of directly calling _bundleInternal(...).
     */
    try this.xBundleConnext(actions, args, beforeSlipped) {
      emit XReceived(transferId, originDomain, true, asset, amount, callData);
    } catch {
      if (balance > 0) {
        SafeERC20.safeTransfer(IERC20(asset), address(handler), balance);
        handler.recordFailed(transferId, amount, asset, originSender, originDomain, actions, args);
      }

      // Ensure clear storage for token balance checks.
      delete _tempTokenToCheck;
      emit XReceived(transferId, originDomain, false, asset, amount, callData);
    }

    return "";
  }

  /**
   * @notice Function selector created to allow try-catch procedure in Connext message data
   * passing.Including argument for `beforeSlipepd` not available in {BaseRouter-xBundle}.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   * @param beforeSlipped amount passed by the origin cross-chain router operation
   *
   * @dev Requirements:
   * - Must only be called within the context of this same contract.
   */
  function xBundleConnext(
    Action[] calldata actions,
    bytes[] calldata args,
    uint256 beforeSlipped
  )
    external
    payable
    onlySelf
  {
    _bundleInternal(actions, args, beforeSlipped);
  }

  /**
   * @dev Decodes and replaces "amount" argument in args with `receivedAmount`
   * in Deposit, or Payback.
   *
   * Refer to:
   * https://github.com/Fujicracy/fuji-v2/issues/253#issuecomment-1385995095
   */
  function _accountForSlippage(
    uint256 receivedAmount,
    Action action,
    bytes memory args
  )
    internal
    pure
    returns (bytes memory newArgs, uint256 beforeSlipped)
  {
    newArgs = args;

    // Check first action type and replace with slippage-amount.
    if (action == Action.Deposit || action == Action.Payback) {
      // For Deposit or Payback.
      (IVault vault, uint256 amount, address receiver, address sender) =
        abi.decode(args, (IVault, uint256, address, address));

      if (amount != receivedAmount) {
        beforeSlipped = amount;
        newArgs = abi.encode(vault, receivedAmount, receiver, sender);
      }
    } else if (action == Action.WithdrawETH) {
      // For WithdrawETH
      (uint256 amount, address receiver) = abi.decode(args, (uint256, address));
      if (amount != receivedAmount) {
        beforeSlipped = amount;
        newArgs = abi.encode(receivedAmount, receiver);
      }
    }
  }

  /// @inheritdoc BaseRouter
  function _crossTransfer(
    bytes memory params,
    address beneficiary
  )
    internal
    override
    returns (address)
  {
    (
      uint256 destDomain,
      uint256 slippage,
      address asset,
      uint256 amount,
      address receiver,
      address sender
    ) = abi.decode(params, (uint256, uint256, address, uint256, address, address));

    address beneficiary_ = _checkBeneficiary(beneficiary, receiver);

    _safePullTokenFrom(asset, sender, amount);
    _safeApprove(asset, address(connext), amount);

    bytes32 transferId = connext.xcall(
      // _destination: Domain ID of the destination chain
      uint32(destDomain),
      // _to: address of the target contract
      receiver,
      // _asset: address of the token contract
      asset,
      // _delegate: address that has rights to update the original slippage tolerance
      // by calling Connext's forceUpdateSlippage function
      beneficiary_,
      // _amount: amount of tokens to transfer
      amount,
      // _slippage: can be anything between 0-10000 becaus
      // the maximum amount of slippage the user will accept in BPS, 30 == 0.3%
      slippage,
      // _callData: empty because we're only sending funds
      ""
    );
    emit XCalled(transferId, msg.sender, receiver, destDomain, asset, amount, "");

    return beneficiary_;
  }

  /// @inheritdoc BaseRouter
  function _crossTransferWithCalldata(
    bytes memory params,
    address beneficiary
  )
    internal
    override
    returns (address beneficiary_)
  {
    (
      uint256 destDomain,
      uint256 slippage,
      address asset,
      uint256 amount,
      address sender,
      bytes memory callData
    ) = abi.decode(params, (uint256, uint256, address, uint256, address, bytes));

    (Action[] memory actions, bytes[] memory args,) =
      abi.decode(callData, (Action[], bytes[], uint256));

    beneficiary_ = _checkBeneficiary(beneficiary, _getBeneficiaryFromCalldata(actions, args));

    _safePullTokenFrom(asset, sender, amount);
    _safeApprove(asset, address(connext), amount);

    bytes32 transferId = connext.xcall(
      // _destination: Domain ID of the destination chain
      uint32(destDomain),
      // _to: address of the target contract
      routerByDomain[destDomain],
      // _asset: address of the token contract
      asset,
      // _delegate: address that can revert or forceLocal on destination
      beneficiary_,
      // _amount: amount of tokens to transfer
      amount,
      // _slippage: can be anything between 0-10000 becaus
      // the maximum amount of slippage the user will accept in BPS, 30 == 0.3%
      slippage,
      // _callData: the encoded calldata to send
      callData
    );

    emit XCalled(
      transferId, msg.sender, routerByDomain[destDomain], destDomain, asset, amount, callData
    );

    return beneficiary_;
  }

  /**
   * @dev Returns who is the first receiver of value in `callData`
   * Requirements:
   * - Must revert if "swap" is first action
   *
   * @param actions to execute in {BaseRouter-xBundle}
   * @param args to execute in {BaseRouter-xBundle}
   */
  function _getBeneficiaryFromCalldata(
    Action[] memory actions,
    bytes[] memory args
  )
    internal
    view
    override
    returns (address beneficiary_)
  {
    if (actions[0] == Action.Deposit || actions[0] == Action.Payback) {
      // For Deposit or Payback.
      (,, address receiver,) = abi.decode(args[0], (IVault, uint256, address, address));
      beneficiary_ = receiver;
    } else if (actions[0] == Action.Withdraw || actions[0] == Action.Borrow) {
      // For Withdraw or Borrow
      (,,, address owner) = abi.decode(args[0], (IVault, uint256, address, address));
      beneficiary_ = owner;
    } else if (actions[0] == Action.WithdrawETH) {
      // For WithdrawEth
      (, address receiver) = abi.decode(args[0], (uint256, address));
      beneficiary_ = receiver;
    } else if (actions[0] == Action.PermitBorrow || actions[0] == Action.PermitWithdraw) {
      (, address owner,,,,,,) = abi.decode(
        args[0], (IVaultPermissions, address, address, uint256, uint256, uint8, bytes32, bytes32)
      );
      beneficiary_ = owner;
    } else if (actions[0] == Action.Flashloan) {
      (,,,, bytes memory requestorCalldata) =
        abi.decode(args[0], (IFlasher, address, uint256, address, bytes));

      (Action[] memory newActions, bytes[] memory newArgs) = abi.decode(
        LibBytes.slice(requestorCalldata, 4, requestorCalldata.length - 4), (Action[], bytes[])
      );

      beneficiary_ = _getBeneficiaryFromCalldata(newActions, newArgs);
    } else if (actions[0] == Action.XTransfer) {
      (,,,, address receiver,) =
        abi.decode(args[0], (uint256, uint256, address, uint256, address, address));
      beneficiary_ = receiver;
    } else if (actions[0] == Action.XTransferWithCall) {
      (,,,, bytes memory callData) =
        abi.decode(args[0], (uint256, uint256, address, uint256, bytes));

      (Action[] memory actions_, bytes[] memory args_,) =
        abi.decode(callData, (Action[], bytes[], uint256));

      beneficiary_ = _getBeneficiaryFromCalldata(actions_, args_);
    } else if (actions[0] == Action.DepositETH) {
      /// @dev There is no beneficiary in depositETH, therefore we do a recurssion with i = 1
      uint256 len = actions.length;

      Action[] memory chopActions = new Action[](len -1);
      bytes[] memory chopArgs = new bytes[](len -1);

      for (uint256 i = 1; i < len;) {
        chopActions[i - 1] = actions[i];
        chopArgs[i - 1] = args[i];
        unchecked {
          ++i;
        }
      }
      beneficiary_ = _getBeneficiaryFromCalldata(chopActions, chopArgs);
    } else if (actions[0] == Action.Swap) {
      /// @dev swap cannot be actions[0].
      revert BaseRouter__bundleInternal_swapNotFirstAction();
    }
  }

  /**
   * @notice Anyone can call this function on the origin domain to increase the relayer fee for a transfer.
   *
   * @param transferId the unique identifier of the crosschain transaction
   */
  function bumpTransfer(bytes32 transferId) external payable {
    connext.bumpTransfer{value: msg.value}(transferId);
  }

  /**
   * @notice Registers an address of this contract deployed on another chain.
   *
   * @param domain unique identifier of a chain as defined in
   * https://docs.connext.network/resources/deployments
   * @param router address of a router deployed on the chain defined by its domain
   *
   * @dev The mapping domain -> router is used in `xReceive` to verify the origin sender.
   * Requirements:
   *  - Must be restricted to timelock.
   *  - `router` must be a non-zero address.
   */
  function setRouter(uint256 domain, address router) external onlyTimelock {
    if (router == address(0)) {
      revert ConnextRouter__setRouter_invalidInput();
    }
    routerByDomain[domain] = router;

    emit NewRouterAdded(router, domain);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title Router Interface
 *
 * @author Fujidao Labs
 *
 * @notice Define the interface for router operations.
 */

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

interface IRouter {
  /// @dev List of actions allowed to be executed by the router.
  enum Action {
    Deposit,
    Withdraw,
    Borrow,
    Payback,
    Flashloan,
    Swap,
    PermitWithdraw,
    PermitBorrow,
    XTransfer,
    XTransferWithCall,
    DepositETH,
    WithdrawETH
  }

  /**
   * @notice An entry-point function that executes encoded commands along with provided inputs.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   */
  function xBundle(Action[] memory actions, bytes[] memory args) external payable;

  /**
   * @notice Sweeps accidental ERC-20 transfers to this contract or stuck funds due to failed
   * cross-chain calls (cf. ConnextRouter).
   *
   * @param token the address of the ERC-20 token to sweep
   * @param receiver the address that will receive the swept funds
   */
  function sweepToken(ERC20 token, address receiver) external;

  /**
   * @notice Sweeps accidental ETH transfers to this contract.
   *
   * @param receiver the address that will receive the swept funds
   */
  function sweepETH(address receiver) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IVault
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface for vaults extending from IERC4326.
 */

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {ILendingProvider} from "./ILendingProvider.sol";
import {IFujiOracle} from "./IFujiOracle.sol";

interface IVault is IERC4626 {
  /**
   * @dev Emit when borrow action occurs.
   *
   * @param sender who calls {IVault-borrow}
   * @param receiver of the borrowed 'debt' amount
   * @param owner who will incur the debt
   * @param debt amount
   * @param shares amount of 'debtShares' received
   */
  event Borrow(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 debt,
    uint256 shares
  );

  /**
   * @dev Emit when payback action occurs.
   *
   * @param sender address who calls {IVault-payback}
   * @param owner address whose debt will be reduced
   * @param debt amount
   * @param shares amound of 'debtShares' burned
   */
  event Payback(address indexed sender, address indexed owner, uint256 debt, uint256 shares);

  /**
   * @dev Emit when the vault is initialized
   *
   * @param initializer of this vault
   *
   */
  event VaultInitialized(address initializer);

  /**
   * @dev Emit when the oracle address is changed.
   *
   * @param newOracle the new oracle address
   */
  event OracleChanged(IFujiOracle newOracle);

  /**
   * @dev Emit when the available providers for the vault change.
   *
   * @param newProviders the new providers available
   */
  event ProvidersChanged(ILendingProvider[] newProviders);

  /**
   * @dev Emit when the active provider is changed.
   *
   * @param newActiveProvider the new active provider
   */
  event ActiveProviderChanged(ILendingProvider newActiveProvider);

  /**
   * @dev Emit when the vault is rebalanced.
   *
   * @param assets amount to be rebalanced
   * @param debt amount to be rebalanced
   * @param from provider
   * @param to provider
   */
  event VaultRebalance(uint256 assets, uint256 debt, address indexed from, address indexed to);

  /**
   * @dev Emit when the max LTV is changed.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   *
   * @param newMaxLtv the new max LTV
   */
  event MaxLtvChanged(uint256 newMaxLtv);

  /**
   * @dev Emit when the liquidation ratio is changed.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   *
   * @param newLiqRatio the new liquidation ratio
   */
  event LiqRatioChanged(uint256 newLiqRatio);

  /**
   * @dev Emit when the minumum amount is changed.
   *
   * @param newMinAmount the new minimum amount
   */
  event MinAmountChanged(uint256 newMinAmount);

  /**
   * @dev Emit when the deposit cap is changed.
   *
   * @param newDepositCap the new deposit cap of this vault
   */
  event DepositCapChanged(uint256 newDepositCap);

  /*///////////////////////////
    Asset management functions
  //////////////////////////*/

  /**
   * @notice Returns the amount of assets owned by `owner`.
   *
   * @param owner to check balance
   *
   * @dev This method avoids having to do external conversions from shares to
   * assets, since {IERC4626-balanceOf} returns shares.
   */
  function balanceOfAsset(address owner) external view returns (uint256 assets);

  /*///////////////////////////
    Debt management functions
  //////////////////////////*/

  /**
   * @notice Returns the decimals for 'debtAsset' of this vault.
   *
   * @dev Requirements:
   * - Must match the 'debtAsset' decimals in ERC20 token.
   * - Must return zero in a {YieldVault}.
   */
  function debtDecimals() external view returns (uint8);

  /**
   * @notice Returns the address of the underlying token used as debt in functions
   * `borrow()`, and `payback()`. Based on {IERC4626-asset}.
   *
   * @dev Requirements:
   * - Must be an ERC-20 token contract.
   * - Must not revert.
   * - Must return zero in a {YieldVault}.
   */
  function debtAsset() external view returns (address);

  /**
   * @notice Returns the amount of debt owned by `owner`.
   *
   * @param owner to check balance
   */
  function balanceOfDebt(address owner) external view returns (uint256 debt);

  /**
   * @notice Returns the amount of `debtShares` owned by `owner`.
   *
   * @param owner to check balance
   */
  function balanceOfDebtShares(address owner) external view returns (uint256 debtShares);

  /**
   * @notice Returns the total amount of the underlying debt asset
   * that is “managed” by this vault. Based on {IERC4626-totalAssets}.
   *
   * @dev Requirements:
   * - Must account for any compounding occuring from yield or interest accrual.
   * - Must be inclusive of any fees that are charged against assets in the Vault.
   * - Must not revert.
   * - Must return zero in a {YieldVault}.
   */
  function totalDebt() external view returns (uint256);

  /**
   * @notice Returns the amount of shares this vault would exchange for the amount
   * of debt assets provided. Based on {IERC4626-convertToShares}.
   *
   * @param debt to convert into `debtShares`
   *
   * @dev Requirements:
   * - Must not be inclusive of any fees that are charged against assets in the Vault.
   * - Must not show any variations depending on the caller.
   * - Must not reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - Must not revert.
   *
   * NOTE: This calculation MAY not reflect the “per-user” price-per-share, and instead Must reflect the
   * “average-user’s” price-per-share, meaning what the average user Must expect to see when exchanging to and
   * from.
   */
  function convertDebtToShares(uint256 debt) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of debt assets that this vault would exchange for the amount
   * of shares provided. Based on {IERC4626-convertToAssets}.
   *
   * @param shares amount to convert into `debt`
   *
   * @dev Requirements:
   * - Must not be inclusive of any fees that are charged against assets in the Vault.
   * - Must not show any variations depending on the caller.
   * - Must not reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - Must not revert.
   *
   * NOTE: This calculation MAY not reflect the “per-user” price-per-share, and instead must reflect the
   * “average-user’s” price-per-share, meaning what the average user Must expect to see when exchanging to and
   * from.
   */
  function convertToDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @notice Returns the maximum amount of the debt asset that can be borrowed for the `owner`,
   * through a borrow call.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must return a limited value if receiver is subject to some borrow limit.
   * - Must return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be borrowed.
   * - Must not revert.
   */
  function maxBorrow(address owner) external view returns (uint256 debt);

  /**
   * @notice Returns the maximum amount of debt that can be payback by the `borrower`.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function maxPayback(address owner) external view returns (uint256 debt);

  /**
   * @notice Returns the maximum amount of debt shares that can be "minted-for-borrowing" by the `borrower`.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function maxMintDebt(address owner) external view returns (uint256 shares);

  /**
   * @notice Returns the maximum amount of debt shares that can be "burned-for-payback" by the `borrower`.
   *
   * @param owner to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function maxBurnDebt(address owner) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of `debtShares` that borrowing `debt` amount will generate.
   *
   * @param debt amount to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function previewBorrow(uint256 debt) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of debt that borrowing `debtShares` amount will generate.
   *
   * @param shares of debt to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function previewMintDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @notice Returns the amount of `debtShares` that will be burned by paying back
   * `debt` amount.
   *
   * @param debt to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function previewPayback(uint256 debt) external view returns (uint256 shares);

  /**
   * @notice Returns the amount of debt asset that will be pulled from user, if `debtShares` are
   * burned to payback.
   *
   * @param debt to check
   *
   * @dev Requirements:
   * - Must not revert.
   */
  function previewBurnDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @notice Perform a borrow action. Function inspired on {IERC4626-deposit}.
   *
   * @param debt amount
   * @param receiver of the `debt` amount
   * @param owner who will incur the `debt` amount
   *
   * * @dev Mints debtShares to owner by taking a loan of exact amount of underlying tokens.
   * Requirements:
   * - Must emit the Borrow event.
   * - Must revert if owner does not own sufficient collateral to back debt.
   * - Must revert if caller is not owner or permissioned operator to act on owner behalf.
   */
  function borrow(uint256 debt, address receiver, address owner) external returns (uint256 shares);

  /**
   * @notice Perform a borrow action by minting `debtShares`.
   *
   * @param shares of debt to mint
   * @param receiver of the borrowed amount
   * @param owner who will incur the `debt` and whom `debtShares` will be accounted
   *
   * * @dev Mints `debtShares` to `owner`.
   * Requirements:
   * - Must emit the Borrow event.
   * - Must revert if owner does not own sufficient collateral to back debt.
   * - Must revert if caller is not owner or permissioned operator to act on owner behalf.
   */
  function mintDebt(
    uint256 shares,
    address receiver,
    address owner
  )
    external
    returns (uint256 debt);

  /**
   * @notice Burns `debtShares` to `receiver` by paying back loan with exact amount of underlying tokens.
   *
   * @param debt amount to payback
   * @param receiver to whom debt amount is being paid back
   *
   * @dev Implementations will require pre-erc20-approval of the underlying debt token.
   * Requirements:
   * - Must emit a Payback event.
   */
  function payback(uint256 debt, address receiver) external returns (uint256 shares);

  /**
   * @notice Burns `debtShares` to `owner` by paying back loan by specifying debt shares.
   *
   * @param shares of debt to payback
   * @param owner to whom debt amount is being paid back
   *
   * @dev Implementations will require pre-erc20-approval of the underlying debt token.
   * Requirements:
   * - Must emit a Payback event.
   */
  function burnDebt(uint256 shares, address owner) external returns (uint256 debt);

  /*///////////////////
    General functions
  ///////////////////*/

  /**
   * @notice Returns the active provider of this vault.
   */
  function getProviders() external view returns (ILendingProvider[] memory);
  /**
   * @notice Returns the active provider of this vault.
   */
  function activeProvider() external view returns (ILendingProvider);

  /*/////////////////////////
     Rebalancing Function
  ////////////////////////*/

  /**
   * @notice Performs rebalancing of vault by moving funds across providers.
   *
   * @param assets amount of this vault to be rebalanced
   * @param debt amount of this vault to be rebalanced (Note: pass zero if this is a {YieldVault})
   * @param from provider
   * @param to provider
   * @param fee expected from rebalancing operation
   * @param setToAsActiveProvider boolean
   *
   * @dev Requirements:
   * - Must check providers `from` and `to` are valid.
   * - Must be called from a {RebalancerManager} contract that makes all proper checks.
   * - Must revert if caller is not an approved rebalancer.
   * - Must emit the VaultRebalance event.
   * - Must check `fee` is a reasonable amount.
   */
  function rebalance(
    uint256 assets,
    uint256 debt,
    ILendingProvider from,
    ILendingProvider to,
    uint256 fee,
    bool setToAsActiveProvider
  )
    external
    returns (bool);

  /*/////////////////////////
     Liquidation Functions
  /////////////////////////*/

  /**
   * @notice Returns the current health factor of 'owner'.
   *
   * @param owner to get health factor
   *
   * @dev Requirements:
   * - Must return type(uint254).max when 'owner' has no debt.
   * - Must revert in {YieldVault}.
   *
   * 'healthFactor' is scaled up by 1e18. A value below 1e18 means 'owner' is eligable for liquidation.
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme.
   */
  function getHealthFactor(address owner) external returns (uint256 healthFactor);

  /**
   * @notice Returns the liquidation close factor based on 'owner's' health factor.
   *
   * @param owner of debt position
   *
   * @dev Requirements:
   * - Must return zero if `owner` is not liquidatable.
   * - Must revert in {YieldVault}.
   */
  function getLiquidationFactor(address owner) external returns (uint256 liquidationFactor);

  /**
   * @notice Performs liquidation of an unhealthy position, meaning a 'healthFactor' below 100.
   *
   * @param owner to be liquidated
   * @param receiver of the collateral shares of liquidation
   *
   * @dev Requirements:
   * - Must revert if caller is not an approved liquidator.
   * - Must revert if 'owner' is not liquidatable.
   * - Must emit the Liquidation event.
   * - Must liquidate 50% of 'owner' debt when: 100 >= 'healthFactor' > 95.
   * - Must liquidate 100% of 'owner' debt when: 95 > 'healthFactor'.
   * - Must revert in {YieldVault}.
   *
   * WARNING! It is liquidator's responsability to check if liquidation is profitable.
   */
  function liquidate(address owner, address receiver) external returns (uint256 gainedShares);

  /*/////////////////////
     Setter functions 
  ////////////////////*/

  /**
   * @notice Sets the lists of providers of this vault.
   *
   * @param providers address array
   *
   * @dev Requirements:
   * - Must not contain zero addresses.
   */
  function setProviders(ILendingProvider[] memory providers) external;

  /**
   * @notice Sets the active provider for this vault.
   *
   * @param activeProvider address
   *
   * @dev Requirements:
   * - Must be a provider previously set by `setProviders()`.
   * - Must be called from a timelock contract.
   *
   * WARNING! Changing active provider without a `rebalance()` call
   * can result in denial of service for vault users.
   */
  function setActiveProvider(ILendingProvider activeProvider) external;

  /**
   * @notice Sets the minimum amount for: `deposit()`, `mint()` and borrow()`.
   *
   * @param amount to be as minimum.
   */
  function setMinAmount(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ISwapper
 *
 * @author Fujidao Labs
 *
 * @notice  Defines the interface for routers to perform token swaps with DEX protocols.
 *
 * @dev Implementation inheriting this interface should be permisionless.
 */

interface ISwapper {
  /**
   * @notice Swap tokens at exchange.
   *
   * @param assetIn address of the ERC-20 token to swap from
   * @param assetOut address of the ERC-20 token to swap to
   * @param amountIn that will be pulled from msg.sender
   * @param amountOut of `assetOut` expected after the swap
   * @param receiver of the `amountOut` tokens
   * @param sweeper who receives the leftovers `assetIn` tokens after swap
   * @param minSweepOut  amount of `assetIn` leftover expected after swap
   *
   * @dev Slippage is controlled through `minSweepOut`. If `minSweepOut` is 0,
   * the slippage check gets skipped.
   */
  function swap(
    address assetIn,
    address assetOut,
    uint256 amountIn,
    uint256 amountOut,
    address receiver,
    address sweeper,
    uint256 minSweepOut
  )
    external;

  /**
   * @notice Estimate the amount of `assetIn` required for `swap()`.
   *
   * @param assetIn address of the ERC-20 token to swap from
   * @param assetOut address of the ERC-20 token to swap to
   * @param amountOut expected amount of `assetOut` after the swap
   */
  function getAmountIn(
    address assetIn,
    address assetOut,
    uint256 amountOut
  )
    external
    view
    returns (uint256 amountIn);

  /**
   * @notice Estimate the amount of `assetOut` received after swap
   *
   * @param assetIn address of the ERC-20 token to swap from
   * @param assetOut address of the ERC-20 token to swap to
   * @param amountIn of `assetIn` to perform swap
   */
  function getAmountOut(
    address assetIn,
    address assetOut,
    uint256 amountIn
  )
    external
    view
    returns (uint256 amountOut);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IConnext
 *
 * @author Fujidao Labs
 *
 * @notice Defines the common interfaces and data types used
 * to interact with Connext Amarok.
 */

/**
 * @notice These are the parameters that will remain constant between the
 * two chains. They are supplied on `xcall` and should be asserted on `execute`
 * @property to - The account that receives funds, in the event of a crosschain call,
 * will receive funds if the call fails.
 *
 * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
 * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
 * @param canonicalDomain - The canonical domain of the asset you are bridging
 * @param to - The address you are sending funds (and potentially data) to
 * @param delegate - An address who can execute txs on behalf of `to`, in addition to allowing relayers
 * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
 * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
 * @param slippage - Slippage user is willing to accept from original amount in expressed in BPS (i.e. if
 * a user takes 1% slippage, this is expressed as 1_000)
 * @param originSender - The msg.sender of the xcall
 * @param bridgedAmt - The amount sent over the bridge (after potential AMM on xcall)
 * @param normalizedIn - The amount sent to `xcall`, normalized to 18 decimals
 * @param nonce - The nonce on the origin domain used to ensure the transferIds are unique
 * @param canonicalId - The unique identifier of the canonical token corresponding to bridge assets
 */
struct TransferInfo {
  uint32 originDomain;
  uint32 destinationDomain;
  uint32 canonicalDomain;
  address to;
  address delegate;
  bool receiveLocal;
  bytes callData;
  uint256 slippage;
  address originSender;
  uint256 bridgedAmt;
  uint256 normalizedIn;
  uint256 nonce;
  bytes32 canonicalId;
}

/**
 * @notice
 * @param params - The TransferInfo. These are consistent across sending and receiving chains.
 * @param routers - The routers who you are sending the funds on behalf of.
 * @param routerSignatures - Signatures belonging to the routers indicating permission to use funds
 * for the signed transfer ID.
 * @param sequencer - The sequencer who assigned the router path to this transfer.
 * @param sequencerSignature - Signature produced by the sequencer for path assignment accountability
 * for the path that was signed.
 */
struct ExecuteArgs {
  TransferInfo params;
  address[] routers;
  bytes[] routerSignatures;
  address sequencer;
  bytes sequencerSignature;
}

interface IConnext {
  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  )
    external
    payable
    returns (bytes32);

  function execute(ExecuteArgs calldata _args)
    external
    returns (bool success, bytes memory returnData);

  function bumpTransfer(bytes32 transferId) external payable;

  function forceUpdateSlippage(TransferInfo calldata _params, uint256 _slippage) external;
}

interface IXReceiver {
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  )
    external
    returns (bytes memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title BaseRouter
 *
 * @author Fujidao Labs
 *
 * @notice Abstract contract to be inherited by all routers.
 */

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IChief} from "../interfaces/IChief.sol";
import {IFlasher} from "../interfaces/IFlasher.sol";
import {IVaultPermissions} from "../interfaces/IVaultPermissions.sol";
import {SystemAccessControl} from "../access/SystemAccessControl.sol";
import {IWETH9} from "../abstracts/WETH9.sol";
import {LibBytes} from "../libraries/LibBytes.sol";

abstract contract BaseRouter is SystemAccessControl, IRouter {
  /**
   * @dev Contains an address of an ERC-20 and the balance the router holds
   * at a given moment of the transaction (ref. `_tokensToCheck`).
   */
  struct Snapshot {
    address token;
    uint256 balance;
  }

  /**
   * @dev Struct used internally containing the arguments of a IRouter.Action.Permit* to store
   * and pass in memory and avoid "stack too deep" errors.
   */
  struct PermitArgs {
    IVaultPermissions vault;
    address owner;
    address receiver;
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @dev Emitted when `caller` is updated according to `allowed` boolean
   * to perform cross-chain calls.
   *
   * @param caller permitted for cross-chain calls
   * @param allowed boolean state
   */
  event AllowCaller(address caller, bool allowed);

  /// @dev Custom Errors
  error BaseRouter__bundleInternal_swapNotFirstAction();
  error BaseRouter__bundleInternal_paramsMismatch();
  error BaseRouter__bundleInternal_flashloanInvalidRequestor();
  error BaseRouter__bundleInternal_noBalanceChange();
  error BaseRouter__bundleInternal_insufficientETH();
  error BaseRouter__bundleInternal_notBeneficiary();
  error BaseRouter__checkVaultInput_notActiveVault();
  error BaseRouter__bundleInternal_notAllowedSwapper();
  error BaseRouter__bundleInternal_notAllowedFlasher();
  error BaseRouter__handlePermit_notPermitAction();
  error BaseRouter__safeTransferETH_transferFailed();
  error BaseRouter__receive_senderNotWETH();
  error BaseRouter__fallback_notAllowed();
  error BaseRouter__allowCaller_zeroAddress();
  error BaseRouter__allowCaller_noAllowChange();
  error BaseRouter__bundleInternal_insufficientFlashloanBalance();

  IWETH9 public immutable WETH9;

  bytes32 private constant ZERO_BYTES32 =
    0x0000000000000000000000000000000000000000000000000000000000000000;

  /// @dev Apply it on entry cross-chain calls functions as required.
  mapping(address => bool) public isAllowedCaller;

  /**
   * @dev Stores token balances of this contract at a given moment.
   * It's used to pass tokens to check from parent contract this contract.
   */
  Snapshot internal _tempTokenToCheck;

  /**
   * @notice Constructor of a new {BaseRouter}.
   *
   * @param weth wrapped native token of this chain
   * @param chief contract
   */
  constructor(IWETH9 weth, IChief chief) payable SystemAccessControl(address(chief)) {
    WETH9 = weth;
  }

  /// @inheritdoc IRouter
  function xBundle(Action[] calldata actions, bytes[] calldata args) external payable override {
    _bundleInternal(actions, args, 0);
  }

  /**
   * @notice Marks a specific caller as allowed/disallowed to call certain functions.
   *
   * @param caller address to allow/disallow
   * @param allowed 'true' to allow, 'false' to disallow
   *
   * @dev The authorization is to be implemented on the bridge-specific contract.
   */
  function allowCaller(address caller, bool allowed) external onlyTimelock {
    _allowCaller(caller, allowed);
  }

  /// @inheritdoc IRouter
  function sweepToken(ERC20 token, address receiver) external onlyHouseKeeper {
    SafeERC20.safeTransfer(token, receiver, token.balanceOf(address(this)));
  }

  /// @inheritdoc IRouter
  function sweepETH(address receiver) external onlyHouseKeeper {
    _safeTransferETH(receiver, address(this).balance);
  }

  /**
   * @dev Executes a bundle of actions.
   * Requirements:
   * - Must not leave any balance in this contract after all actions.
   * - Must call `_checkNoBalanceChange()` after all `actions` are executed.
   * - Must call `_addTokenToList()` in `actions` that involve tokens.
   * - Must clear `_beneficiary` from storage after all `actions` are executed.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   * @param beforeSlipped amount passed by the origin cross-chain router operation
   */
  function _bundleInternal(
    Action[] memory actions,
    bytes[] memory args,
    uint256 beforeSlipped
  )
    internal
  {
    uint256 len = actions.length;
    if (len != args.length) {
      revert BaseRouter__bundleInternal_paramsMismatch();
    }

    /**
     * @dev Operations in the bundle should "benefit" or be executed
     * on behalf of this account. These are receivers on DEPOSIT and PAYBACK
     * or owners on WITHDRAW and BORROW.
     */
    address beneficiary;

    /**
     * @dev Hash generated during execution of "_bundleInternal()" that should
     * match the signed permit.
     * This argument is used in {VaultPermissions-PermitWithdraw} and
     * {VaultPermissions-PermitBorrow}
     */
    bytes32 actionArgsHash;

    /**
     * @dev Stores token balances of this contract at a given moment.
     * It's used to ensure there're no changes in balances at the
     * end of a transaction.
     */
    Snapshot[] memory tokensToCheck = new Snapshot[](10);

    /// @dev Add token to check from parent calls.
    if (_tempTokenToCheck.token != address(0)) {
      tokensToCheck[0] = _tempTokenToCheck;
    }

    uint256 nativeBalance = address(this).balance - msg.value;

    for (uint256 i; i < len;) {
      Action action = actions[i];
      if (action == Action.Deposit) {
        // DEPOSIT
        (IVault vault, uint256 amount, address receiver, address sender) =
          abi.decode(args[i], (IVault, uint256, address, address));

        _checkVaultInput(address(vault));

        address token = vault.asset();
        beneficiary = _checkBeneficiary(beneficiary, receiver);
        tokensToCheck = _addTokenToList(token, tokensToCheck);
        _safePullTokenFrom(token, sender, amount);
        _safeApprove(token, address(vault), amount);

        vault.deposit(amount, receiver);
      } else if (action == Action.Withdraw) {
        // WITHDRAW
        (IVault vault, uint256 amount, address receiver, address owner) =
          abi.decode(args[i], (IVault, uint256, address, address));

        _checkVaultInput(address(vault));

        beneficiary = _checkBeneficiary(beneficiary, owner);
        tokensToCheck = _addTokenToList(vault.asset(), tokensToCheck);

        vault.withdraw(amount, receiver, owner);
      } else if (action == Action.Borrow) {
        // BORROW
        (IVault vault, uint256 amount, address receiver, address owner) =
          abi.decode(args[i], (IVault, uint256, address, address));

        _checkVaultInput(address(vault));

        beneficiary = _checkBeneficiary(beneficiary, owner);
        tokensToCheck = _addTokenToList(vault.debtAsset(), tokensToCheck);

        vault.borrow(amount, receiver, owner);
      } else if (action == Action.Payback) {
        // PAYBACK
        (IVault vault, uint256 amount, address receiver, address sender) =
          abi.decode(args[i], (IVault, uint256, address, address));

        _checkVaultInput(address(vault));

        address token = vault.debtAsset();
        beneficiary = _checkBeneficiary(beneficiary, receiver);
        tokensToCheck = _addTokenToList(token, tokensToCheck);
        _safePullTokenFrom(token, sender, amount);
        _safeApprove(token, address(vault), amount);

        vault.payback(amount, receiver);
      } else if (action == Action.PermitWithdraw) {
        // PERMIT WITHDRAW
        if (actionArgsHash == ZERO_BYTES32) {
          actionArgsHash = _getActionArgsHash(actions, args, beforeSlipped);
        }

        // Scoped code in new private function to avoid "Stack too deep"
        address owner_ = _handlePermitAction(action, args[i], actionArgsHash);
        beneficiary = _checkBeneficiary(beneficiary, owner_);
      } else if (action == Action.PermitBorrow) {
        // PERMIT BORROW
        if (actionArgsHash == ZERO_BYTES32) {
          actionArgsHash = _getActionArgsHash(actions, args, beforeSlipped);
        }

        // Scoped code in new private function to avoid "Stack too deep"
        address owner_ = _handlePermitAction(action, args[i], actionArgsHash);
        beneficiary = _checkBeneficiary(beneficiary, owner_);
      } else if (action == Action.XTransfer) {
        // SIMPLE BRIDGE TRANSFER

        beneficiary = _crossTransfer(args[i], beneficiary);
      } else if (action == Action.XTransferWithCall) {
        // BRIDGE WITH CALLDATA

        beneficiary = _crossTransferWithCalldata(args[i], beneficiary);
      } else if (action == Action.Swap) {
        // SWAP

        if (i == 0) {
          /// @dev swap cannot be actions[0].
          revert BaseRouter__bundleInternal_swapNotFirstAction();
        }

        (beneficiary, tokensToCheck) = _handleSwapAction(args[i], beneficiary, tokensToCheck);
      } else if (action == Action.Flashloan) {
        // FLASHLOAN

        // Decode params.
        (
          IFlasher flasher,
          address asset,
          uint256 flashAmount,
          address requestor,
          bytes memory requestorCalldata
        ) = abi.decode(args[i], (IFlasher, address, uint256, address, bytes));

        if (!chief.allowedFlasher(address(flasher))) {
          revert BaseRouter__bundleInternal_notAllowedFlasher();
        }
        if (requestor != address(this)) {
          revert BaseRouter__bundleInternal_flashloanInvalidRequestor();
        }
        tokensToCheck = _addTokenToList(asset, tokensToCheck);

        (Action[] memory innerActions, bytes[] memory innerArgs) = abi.decode(
          LibBytes.slice(requestorCalldata, 4, requestorCalldata.length - 4), (Action[], bytes[])
        );

        beneficiary = _getBeneficiaryFromCalldata(innerActions, innerArgs);

        // Call Flasher.
        flasher.initiateFlashloan(asset, flashAmount, requestor, requestorCalldata);
      } else if (action == Action.DepositETH) {
        uint256 amount = abi.decode(args[i], (uint256));

        if (amount != msg.value) {
          revert BaseRouter__bundleInternal_insufficientETH();
        }
        tokensToCheck = _addTokenToList(address(WETH9), tokensToCheck);

        WETH9.deposit{value: msg.value}();
      } else if (action == Action.WithdrawETH) {
        (uint256 amount, address receiver) = abi.decode(args[i], (uint256, address));
        beneficiary = _checkBeneficiary(beneficiary, receiver);
        tokensToCheck = _addTokenToList(address(WETH9), tokensToCheck);

        WETH9.withdraw(amount);

        _safeTransferETH(receiver, amount);
      }
      unchecked {
        ++i;
      }
    }
    _checkNoBalanceChange(tokensToCheck, nativeBalance);
  }

  /**
   * @dev Handles both permit actions logic flow.
   * This function was required to avoid "stack too deep" error in `_bundleInternal()`.
   *
   * @param action either IRouter.Action.PermitWithdraw (6), or IRouter.Action.PermitBorrow (7)
   * @param arg of the ongoing action
   * @param actionArgsHash_ created previously withing `_bundleInternal()` to be used in permit check
   */
  function _handlePermitAction(
    IRouter.Action action,
    bytes memory arg,
    bytes32 actionArgsHash_
  )
    private
    returns (address)
  {
    PermitArgs memory permitArgs;
    {
      (
        permitArgs.vault,
        permitArgs.owner,
        permitArgs.receiver,
        permitArgs.amount,
        permitArgs.deadline,
        permitArgs.v,
        permitArgs.r,
        permitArgs.s
      ) = abi.decode(
        arg, (IVaultPermissions, address, address, uint256, uint256, uint8, bytes32, bytes32)
      );
    }

    _checkVaultInput(address(permitArgs.vault));

    if (action == IRouter.Action.PermitWithdraw) {
      permitArgs.vault.permitWithdraw(
        permitArgs.owner,
        permitArgs.receiver,
        permitArgs.amount,
        permitArgs.deadline,
        actionArgsHash_,
        permitArgs.v,
        permitArgs.r,
        permitArgs.s
      );
    } else if (action == IRouter.Action.PermitBorrow) {
      permitArgs.vault.permitBorrow(
        permitArgs.owner,
        permitArgs.receiver,
        permitArgs.amount,
        permitArgs.deadline,
        actionArgsHash_,
        permitArgs.v,
        permitArgs.r,
        permitArgs.s
      );
    } else {
      revert BaseRouter__handlePermit_notPermitAction();
    }

    return permitArgs.owner;
  }

  /**
   * @dev Returns the `zeroPermitEncodedArgs` which is required to create
   * the `actionArgsHash` used during permit signature
   *
   * @param vault that will execute action
   * @param owner owner of the assets
   * @param receiver of the assets after action
   * @param amount of assets being permitted in action
   */
  function _getZeroPermitEncodedArgs(
    IVaultPermissions vault,
    address owner,
    address receiver,
    uint256 amount
  )
    private
    pure
    returns (bytes memory)
  {
    return abi.encode(vault, owner, receiver, amount, 0, 0, ZERO_BYTES32, ZERO_BYTES32);
  }

  /**
   * @dev Returns the `actionsArgsHash` required in
   * {VaultPermissions-permitWithdraw} or {VaultPermissions-permitBorrow}.
   * Requirements:
   * - Must replace arguments in IRouter.Action.PermitWithdraw for "zeroPermit".
   * - Must replace arguments in IRouter.Action.PermitBorrow for "zeroPermit".
   * - Must replace `beforeSlipped` amount in cross-chain txs that had slippage.
   *
   *
   * @param actions being executed in this `_bundleInternal`
   * @param args provided in `_bundleInternal`
   * @param beforeSlipped amount passed by the origin cross-chain router operation
   */
  function _getActionArgsHash(
    IRouter.Action[] memory actions,
    bytes[] memory args,
    uint256 beforeSlipped
  )
    private
    pure
    returns (bytes32)
  {
    uint256 len = actions.length;

    /**
     * @dev We intend to ONLY modify the new bytes array.
     * "memory" in solidity persists within internal calls.
     */
    bytes[] memory modArgs = new bytes[](len);
    for (uint256 i; i < len; i++) {
      modArgs[i] = args[i];
      if (
        i == 0 && beforeSlipped != 0
          && (actions[i] == IRouter.Action.Deposit || actions[i] == IRouter.Action.Payback)
      ) {
        /**
         * @dev Replace slippage values in the first ( i==0 ) "value" transfer
         * action in the destination chain (deposit or to payback).
         * If `beforeSlipped` == 0, it means there was no slippage in the attempted cross-chain tx
         * or the tx is single chain; thereore, not requiring any replacement.
         * Then, if beforeSlipped != 0 and beforeSlipped != slippedAmount, function should replace
         * to obtain the "original" intended transfer value signed in `actionArgsHash`.
         */
        (IVault vault, uint256 slippedAmount, address receiver, address sender) =
          abi.decode(modArgs[i], (IVault, uint256, address, address));
        if (beforeSlipped != slippedAmount) {
          modArgs[i] = abi.encode(vault, beforeSlipped, receiver, sender);
        }
      }
      if (actions[i] == IRouter.Action.PermitWithdraw || actions[i] == IRouter.Action.PermitBorrow)
      {
        // Need to replace permit `args` at `index` with the `zeroPermitArg`.
        (IVaultPermissions vault, address owner, address receiver, uint256 amount,,,,) = abi.decode(
          modArgs[i],
          (IVaultPermissions, address, address, uint256, uint256, uint8, bytes32, bytes32)
        );
        modArgs[i] = _getZeroPermitEncodedArgs(vault, owner, receiver, amount);
      }
    }
    return keccak256(abi.encode(actions, modArgs));
  }

  /**
   * @dev Handles swap actions logic flow.
   * This function was required to avoid "stack too deep" error in `_bundleInternal()`.
   * Requirements:
   * - Must return updated "beneficiary" and "tokensToCheck".
   *
   * @param arg of the ongoing action
   * @param beneficiary_ passed through `_bundleInternal()`
   * @param tokensToCheck_ passed through `_bundleInternal()`
   */
  function _handleSwapAction(
    bytes memory arg,
    address beneficiary_,
    Snapshot[] memory tokensToCheck_
  )
    internal
    returns (address, Snapshot[] memory)
  {
    (
      ISwapper swapper,
      address assetIn,
      address assetOut,
      uint256 amountIn,
      uint256 amountOut,
      address receiver,
      address sweeper,
      uint256 minSweepOut
    ) = abi.decode(arg, (ISwapper, address, address, uint256, uint256, address, address, uint256));

    if (!chief.allowedSwapper(address(swapper))) {
      revert BaseRouter__bundleInternal_notAllowedSwapper();
    }

    tokensToCheck_ = _addTokenToList(assetIn, tokensToCheck_);
    tokensToCheck_ = _addTokenToList(assetOut, tokensToCheck_);
    _safeApprove(assetIn, address(swapper), amountIn);

    if (receiver != address(this) && !chief.allowedFlasher(receiver)) {
      beneficiary_ = _checkBeneficiary(beneficiary_, receiver);
    }

    if (sweeper != address(this)) {
      beneficiary_ = _checkBeneficiary(beneficiary_, sweeper);
    }

    swapper.swap(assetIn, assetOut, amountIn, amountOut, receiver, sweeper, minSweepOut);
    return (beneficiary_, tokensToCheck_);
  }

  /**
   * @dev Helper function to transfer ETH.
   *
   * @param receiver address to receive the ETH
   * @param amount amount to be transferred
   */
  function _safeTransferETH(address receiver, uint256 amount) internal {
    (bool success,) = receiver.call{value: amount}(new bytes(0));
    if (!success) {
      revert BaseRouter__safeTransferETH_transferFailed();
    }
  }

  /**
   * @dev Helper function to pull ERC-20 token from a sender address after some checks.
   * The checks are needed because when we bundle multiple actions
   * it can happen the router already holds the assets in question;
   * for. example when we withdraw from a vault and deposit to another one.
   *
   * @param token ERC-20 token address
   * @param sender address to pull tokens from
   * @param amount amount of tokens to be pulled
   */
  function _safePullTokenFrom(address token, address sender, uint256 amount) internal {
    if (sender != address(this) && sender == msg.sender) {
      SafeERC20.safeTransferFrom(ERC20(token), sender, address(this), amount);
    }
  }

  /**
   * @dev Helper function to approve ERC-20 transfers.
   *
   * @param token ERC-20 address to approve
   * @param to address to approve as a spender
   * @param amount amount to be approved
   */
  function _safeApprove(address token, address to, uint256 amount) internal {
    SafeERC20.safeApprove(ERC20(token), to, amount);
  }

  /**
   * @dev Check `allowCaller()` above.
   *
   * @param caller address to allow/disallow
   * @param allowed 'true' to allow, 'false' to disallow
   */
  function _allowCaller(address caller, bool allowed) internal {
    if (caller == address(0)) {
      revert BaseRouter__allowCaller_zeroAddress();
    }
    if (isAllowedCaller[caller] == allowed) {
      revert BaseRouter__allowCaller_noAllowChange();
    }
    isAllowedCaller[caller] = allowed;
    emit AllowCaller(caller, allowed);
  }

  /**
   * @dev Function to be implemented on the bridge-specific contract
   * used to transfer funds WITHOUT calldata to a destination chain.
   */
  function _crossTransfer(bytes memory, address beneficiary) internal virtual returns (address);

  /**
   * @dev Function to be implemented on the bridge-specific contract
   * used to transfer funds WITH calldata to a destination chain.
   */
  function _crossTransferWithCalldata(
    bytes memory,
    address beneficiary
  )
    internal
    virtual
    returns (address);

  /**
   * @dev Returns "true" and on what `index` if token has already
   * been added to `tokenList`.
   *
   * @param token address of ERC-20 to check
   * @param tokenList to check
   */
  function _isInTokenList(
    address token,
    Snapshot[] memory tokenList
  )
    private
    pure
    returns (bool value, uint256 index)
  {
    uint256 len = tokenList.length;
    for (uint256 i; i < len;) {
      if (token == tokenList[i].token) {
        value = true;
        index = i;
        break;
      }
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Adds a token and balance to a Snapshot and returns it.
   * Requirements:
   * - Must check if token has already been added.
   *
   * @param token address of ERC-20 to be pushed
   * @param tokenList to add token
   */
  function _addTokenToList(
    address token,
    Snapshot[] memory tokenList
  )
    private
    view
    returns (Snapshot[] memory)
  {
    (bool isInList, uint256 index) = _isInTokenList(token, tokenList);
    if (!isInList) {
      uint256 position = index == 0 ? index : index + 1;
      tokenList[position] = Snapshot(token, IERC20(token).balanceOf(address(this)));
    }
    return tokenList;
  }

  /**
   * @dev Checks that `erc20-balanceOf` of `_tokensToCheck` haven't change for this address.
   * Requirements:
   * - Must be called in `_bundleInternal()` at the end of all executed `actions`.
   * - Must clear `_tokensToCheck` from storage at the end of checks.
   *
   * @param tokensToCheck array of 'Snapshot' elements
   * @param nativeBalance the stored balance of ETH
   */
  function _checkNoBalanceChange(
    Snapshot[] memory tokensToCheck,
    uint256 nativeBalance
  )
    private
    view
  {
    uint256 len = tokensToCheck.length;
    for (uint256 i; i < len;) {
      if (tokensToCheck[i].token != address(0)) {
        uint256 previousBalance = tokensToCheck[i].balance;
        uint256 currentBalance = IERC20(tokensToCheck[i].token).balanceOf(address(this));

        if (currentBalance != previousBalance) {
          revert BaseRouter__bundleInternal_noBalanceChange();
        }
      }
      unchecked {
        ++i;
      }
    }

    // Check at the end the native balance.
    if (nativeBalance != address(this).balance) {
      revert BaseRouter__bundleInternal_noBalanceChange();
    }
  }

  /**
   * @dev When bundling multiple actions assure that we act for a single beneficiary;
   * receivers on DEPOSIT and PAYBACK and owners on WITHDRAW and BORROW
   * must be the same user
   *
   * @param user address to verify is the beneficiary
   */
  function _checkBeneficiary(address beneficiary, address user) internal pure returns (address) {
    if (beneficiary == address(0)) {
      return user;
    } else if (beneficiary != user) {
      revert BaseRouter__bundleInternal_notBeneficiary();
    } else {
      return user;
    }
  }

  /**
   * @dev Extracts the beneficiary from a set of actions and args.
   * Requirements:
   * - Must be implemented in child contract, and added to `_crossTransfer` and
   * `crossTansferWithCalldata` when applicable.
   *
   * @param actions an array of actions that will be executed in a row
   * @param args an array of encoded inputs needed to execute each action
   */
  function _getBeneficiaryFromCalldata(
    Action[] memory actions,
    bytes[] memory args
  )
    internal
    view
    virtual
    returns (address beneficiary_);

  function _checkVaultInput(address vault_) internal view {
    if (!chief.isVaultActive(vault_)) {
      revert BaseRouter__checkVaultInput_notActiveVault();
    }
  }

  /**
   * @dev Only WETH contract is allowed to transfer ETH to this address.
   * Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    if (msg.sender != address(WETH9)) {
      revert BaseRouter__receive_senderNotWETH();
    }
  }

  /**
   * @dev Revert fallback calls.
   */
  fallback() external payable {
    revert BaseRouter__fallback_notAllowed();
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IWETH9
 *
 * @author Unknown
 *
 * @notice Abstract contract of add-on functions of a
 * typical ERC20 wrapped native token.
 */

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

abstract contract IWETH9 is ERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable virtual;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IVaultPermissions
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface for a vault extended with
 * signed permit operations for `withdraw()` and `borrow()` allowance.
 */

interface IVaultPermissions {
  /**
   * @dev Emitted when `asset` withdraw allowance is set.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance given
   */
  event WithdrawApproval(address indexed owner, address operator, address receiver, uint256 amount);

  /**
   * @dev Emitted when `debtAsset` borrow allowance is set.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance given
   */
  event BorrowApproval(address indexed owner, address operator, address receiver, uint256 amount);

  /// @dev Based on {IERC20Permit-DOMAIN_SEPARATOR}.
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external returns (bytes32);

  /**
   * @notice Returns the current amount of withdraw allowance from `owner` to `receiver` that
   * can be executed by `operator`. This is similar to {IERC20-allowance} for BaseVault assets,
   * instead of token-shares.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   *
   * @dev Requirements:
   * - Must replace {IERC4626-allowance} in a vault implementation.
   */
  function withdrawAllowance(
    address owner,
    address operator,
    address receiver
  )
    external
    view
    returns (uint256);

  /**
   * @notice Returns the current amount of borrow allowance from `owner` to `receiver` that
   * can be executed by `operator`. This is similar to {IERC20-allowance} for
   * BaseVault-debtAsset.
   *
   * @param owner who provides allowance
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   */
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    external
    view
    returns (uint256);

  /**
   * @dev Atomically increases the `withdrawAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-increaseAllowance} for assets.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to increase withdraw allowance
   *
   * @dev Requirements:
   * - Must emit a {WithdrawApproval} event indicating the updated withdraw allowance.
   * - Must check `operator` and `receiver are not zero address.
   */
  function increaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically decreases the `withdrawAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-decreaseAllowance} for assets.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to decrease withdraw allowance
   *
   * @dev Requirements:
   * - Must emit a {WithdrawApproval} event indicating the updated withdraw allowance.
   * - Must check `operator` and `receiver` are not zero address.
   * - Must check `operator` and `receiver` have `borrowAllowance` of at least `byAmount`.
   *
   */
  function decreaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically increases the `borrowAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-increaseAllowance}
   * for `debtAsset`.
   *
   * @param operator address who can execute the use of the allowance
   * @param receiver address who can spend the allowance
   * @param byAmount to increase borrow allowance
   *
   * @dev Requirements:
   * - Must emit a {BorrowApproval} event indicating the updated borrow allowance.
   * - Must check `operator` and `receiver` are not zero address.
   */
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically decrease the `borrowAllowance` granted to `receiver` and
   * executable by `operator` by the caller. Based on OZ {ERC20-decreaseAllowance}
   * for `debtAsset`.
   *
   * @param operator who can execute the use of the allowance
   * @param receiver who can spend the allowance
   * @param byAmount to decrease borrow allowance
   *
   * Requirements:
   * - Must emit a {BorrowApproval} event indicating the updated borrow allowance.
   * - Must check `operator` and `receiver` are not the zero address.
   * - Must check `operator` and `receiver` have `borrowAllowance` of at least `byAmount`.
   */
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @notice Returns the curent used nonces for permits of `owner`.
   * Based on OZ {IERC20Permit-nonces}.
   *
   * @param owner address to check nonces
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @notice Sets `amount` as the `withdrawAllowance` of `receiver` executable by
   * caller over `owner`'s tokens, given the `owner`'s signed approval.
   * Inspired by {IERC20Permit-permit} for assets.
   *
   * @param owner providing allowance
   * @param receiver who can spend the allowance
   * @param amount of allowance
   * @param deadline timestamp limit for the execution of signed permit
   * @param actionArgsHash keccak256 of the abi.encoded(args,actions) to be performed in {BaseRouter._internalBundle}
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must check `deadline` is a timestamp in the future.
   * - Must check `receiver` is a non-zero address.
   * - Must check that `v`, `r` and `s` are valid `secp256k1` signature for `owner`
   *   over EIP712-formatted function arguments.
   * - Must check the signature used `owner`'s current nonce (see {nonces}).
   * - Must emits an {AssetsApproval} event.
   */
  function permitWithdraw(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    bytes32 actionArgsHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;

  /**
   * @notice Sets `amount` as the `borrowAllowance` of `receiver` executable by caller over
   * `owner`'s borrowing powwer, given the `owner`'s signed approval.
   * Inspired by {IERC20Permit-permit} for debt.
   *
   * @param owner address providing allowance
   * @param receiver address who can spend the allowance
   * @param amount of allowance
   * @param deadline timestamp limit for the execution of signed permit
   * @param actionArgsHash keccak256 of the abi.encoded(args,actions) to be performed in {BaseRouter._internalBundle}
   * @param v signature value
   * @param r signature value
   * @param s signature value
   *
   * @dev Requirements:
   * - Must emit a {BorrowApproval} event.
   * - Must be implemented in a {BorrowingVault}.
   * - Must check `deadline` is a timestamp in the future.
   * - Must check `receiver` is a non-zero address.
   * - Must check that `v`, `r` and `s` are valid `secp256k1` signature for `owner`.
   *   over EIP712-formatted function arguments.
   * - Must check the signature used `owner`'s current nonce (see {nonces}).
   */
  function permitBorrow(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    bytes32 actionArgsHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IChief
 *
 * @author Fujidao Labs
 *
 * @notice Defines interface for {Chief} access control operations.
 */

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IChief is IAccessControl {
  /// @notice Returns the timelock address of the FujiV2 system.
  function timelock() external view returns (address);

  /// @notice Returns the address mapper contract address of the FujiV2 system.
  function addrMapper() external view returns (address);

  /**
   * @notice Returns true if `vault` is active.
   *
   * @param vault to check status
   */
  function isVaultActive(address vault) external view returns (bool);

  /**
   * @notice Returns true if `flasher` is an allowed {IFlasher}.
   *
   * @param flasher address to check
   */
  function allowedFlasher(address flasher) external view returns (bool);

  /**
   * @notice Returns true if `swapper` is an allowed {ISwapper}.
   *
   * @param swapper address to check
   */
  function allowedSwapper(address swapper) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFlasher
 * @author Fujidao Labs
 * @notice Defines the interface for all flashloan providers.
 */

interface IFlasher {
  /**
   * @notice Initiates a flashloan a this provider.
   * @param asset address to be flashloaned.
   * @param amount of `asset` to be flashloaned.
   * @param requestor address to which flashloan will be facilitated.
   * @param requestorCalldata encoded args with selector that will be OPCODE-CALL'ed to `requestor`.
   * @dev To encode `params` see examples:
   * • solidity:
   *   > abi.encodeWithSelector(contract.transferFrom.selector, from, to, amount);
   * • ethersJS:
   *   > contract.interface.encodeFunctionData("transferFrom", [from, to, amount]);
   * • foundry cast:
   *   > cast calldata "transferFrom(address,address,uint256)" from, to, amount
   *
   * Requirements:
   * - MUST implement `_checkAndSetEntryPoint()`
   */
  function initiateFlashloan(
    address asset,
    uint256 amount,
    address requestor,
    bytes memory requestorCalldata
  )
    external;

  /**
   * @notice Returns the address from which flashloan for `asset` is sourced.
   * @param asset intended to be flashloaned.
   * @dev Override at flashloan provider implementation as required.
   * Some protocol implementations source flashloans from different contracts
   * depending on `asset`.
   */
  function getFlashloanSourceAddr(address asset) external view returns (address callAddr);

  /**
   * @notice Returns the expected flashloan fee for `amount`
   * of this flashloan provider.
   * @param asset to be flashloaned
   * @param amount of flashloan
   */
  function computeFlashloanFee(address asset, uint256 amount) external view returns (uint256 fee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/*
 * @title LibBytes

 * @author Gonçalo Sá <[email protected]>
 *
 * @notice Utility library for ethereum contracts written in Solidity.
 * The library lets you concatenate, slice and type cast bytes arrays 
 * both in memory and storage. Taken from:
 * https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol.
 */
library LibBytes {
  function concat(
    bytes memory _preBytes,
    bytes memory _postBytes
  )
    internal
    pure
    returns (bytes memory)
  {
    bytes memory tempBytes;

    assembly {
      /**
       * @dev Get a location of some free memory and store it in tempBytes as
       * Solidity does for memory variables.
       */
      tempBytes := mload(0x40)

      /**
       * @dev Store the length of the first bytes array at the beginning of
       * the memory for tempBytes.
       */
      let length := mload(_preBytes)
      mstore(tempBytes, length)

      /**
       * @dev Maintain a memory counter for the current write location in the
       * temp bytes array by adding the 32 bytes for the array length to
       * the starting location.
       */
      let mc := add(tempBytes, 0x20)
      // Stop copying when the memory counter reaches the length of the first bytes array.
      let end := add(mc, length)

      for {
        // Initialize a copy counter to the start of the _preBytes data, 32 bytes into its memory.
        let cc := add(_preBytes, 0x20)
      } lt(mc, end) {
        // Increase both counters by 32 bytes each iteration.
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        // Write the _preBytes data into the tempBytes memory 32 bytes at a time.
        mstore(mc, mload(cc))
      }

      /**
       * @dev Add the length of _postBytes to the current length of tempBytes
       * and store it as the new length in the first 32 bytes of the
       * tempBytes memory.
       */
      length := mload(_postBytes)
      mstore(tempBytes, add(length, mload(tempBytes)))

      // Move the memory counter back from a multiple of 0x20 to the  actual end of the _preBytes data.
      mc := end
      // Stop copying when the memory counter reaches the new combined length of the arrays.
      end := add(mc, length)

      for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } { mstore(mc, mload(cc)) }

      /**
       * @dev Update the free-memory pointer by padding our last write location
       * to 32 bytes: add 31 bytes to the end of tempBytes to move to the
       * next 32 byte block, then round down to the nearest multiple of
       * 32. If the sum of the length of the two arrays is zero then add
       * one before rounding down to leave a blank 32 bytes (the length block with 0).
       */
      mstore(
        0x40,
        and(
          add(add(end, iszero(add(length, mload(_preBytes)))), 31),
          // Round down to the nearest 32 bytes.
          not(31)
        )
      )
    }

    return tempBytes;
  }

  function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
    assembly {
      /**
       * @dev Read the first 32 bytes of _preBytes storage, which is the length
       * of the array. (We don't need to use the offset into the slot
       * because arrays use the entire slot.)
       */
      let fslot := sload(_preBytes.slot)
      /**
       * @dev Arrays of 31 bytes or less have an even value in their slot,
       * while longer arrays have an odd value. The actual length is
       * the slot divided by two for odd values, and the lowest order
       * byte divided by two for even values.
       * If the slot is even, bitwise and the slot with 255 and divide by
       * two to get the length. If the slot is odd, bitwise and the slot
       * with -1 and divide by two.
       */
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)
      let newlength := add(slength, mlength)

      /**
       * @dev // slength can contain both the length and contents of the array
       * if length < 32 bytes so let's prepare for that
       * v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
       */
      switch add(lt(slength, 32), lt(newlength, 32))
      case 2 {
        /**
         * @dev Since the new array still fits in the slot, we just need to
         * update the contents of the slot.
         * uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
         */
        sstore(
          _preBytes.slot,
          // All the modifications to the slot are inside this next block
          add(
            // we can just add to the slot contents because the bytes we want to change are the LSBs
            fslot,
            add(
              mul(
                div(
                  // load the bytes from memory.
                  mload(add(_postBytes, 0x20)),
                  // Zero all bytes to the right.
                  exp(0x100, sub(32, mlength))
                ),
                // Now shift left the number of bytes to leave space for the length in the slot.
                exp(0x100, sub(32, newlength))
              ),
              // Increase length by the double of the memory bytes length.
              mul(mlength, 2)
            )
          )
        )
      }
      case 1 {
        /**
         * @dev The stored value fits in the slot, but the combined value
         * will exceed it. Get the keccak hash to get the contents of the array.
         */
        mstore(0x0, _preBytes.slot)
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // Save new length.
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        /**
         * @dev The contents of the _postBytes array start 32 bytes into
         * the structure. Our first read should obtain the `submod`
         * bytes that can fit into the unused space in the last word
         * of the stored array. To get this, we read 32 bytes starting
         * from `submod`, so the data we read overlaps with the array
         * contents by `submod` bytes. Masking the lowest-order
         * `submod` bytes allows us to add that value directly to the
         * stored value.
         */
        let submod := sub(32, slength)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(
          sc,
          add(
            and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
            and(mload(mc), mask)
          )
        )

        for {
          mc := add(mc, 0x20)
          sc := add(sc, 1)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } { sstore(sc, mload(mc)) }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
      default {
        // Get the keccak hash to get the contents of the array.
        mstore(0x0, _preBytes.slot)
        // Start copying to the last used word of the stored array.
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // Save new length.
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        // Copy over the first `submod` bytes of the new data as in case 1 above.
        let slengthmod := mod(slength, 32)
        let mlengthmod := mod(mlength, 32)
        let submod := sub(32, slengthmod)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(sc, add(sload(sc), and(mload(mc), mask)))

        for {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } { sstore(sc, mload(mc)) }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
    }
  }

  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  )
    internal
    pure
    returns (bytes memory)
  {
    require(_length + 31 >= _length, "slice_overflow");
    require(_bytes.length >= _start + _length, "slice_outOfBounds");

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as Solidity does for memory variables.
        tempBytes := mload(0x40)

        /**
         * @dev The first word of the slice result is potentially a partial
         * word read from the original array. To read it, we calculate
         * the length of that partial word and start copying that many
         * bytes into the array. The first word we copy will start with
         * data we don't care about, but the last `lengthmod` bytes will
         * land at the beginning of the contents of the new array. When
         * we're done copying, we overwrite the full first word with
         * the actual length of the slice.
         */
        let lengthmod := and(_length, 31)

        /**
         * @dev The multiplication in the next line is necessary
         * because when slicing multiples of 32 bytes (lengthmod == 0)
         * the following copy loop was copying the origin's length
         * and then ending prematurely not copying everything it should.
         */
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } { mstore(mc, mload(cc)) }

        mstore(tempBytes, _length)

        // Update free-memory pointer allocating the array padded to 32 bytes like the compiler does now.
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      // If we want a zero-length slice let's just return a zero-length array.
      default {
        tempBytes := mload(0x40)
        // Zero out the 32 bytes slice we are about to return we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
    require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
    uint8 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x1), _start))
    }

    return tempUint;
  }

  function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
    require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
    uint16 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x2), _start))
    }

    return tempUint;
  }

  function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
    require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
    uint32 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x4), _start))
    }

    return tempUint;
  }

  function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
    require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
    uint64 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x8), _start))
    }

    return tempUint;
  }

  function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
    require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
    uint96 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0xc), _start))
    }

    return tempUint;
  }

  function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
    require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
    uint128 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x10), _start))
    }

    return tempUint;
  }

  function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
    require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }

  function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
    require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
    bytes32 tempBytes32;

    assembly {
      tempBytes32 := mload(add(add(_bytes, 0x20), _start))
    }

    return tempBytes32;
  }

  function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
    bool success = true;

    assembly {
      let length := mload(_preBytes)

      // If lengths don't match the arrays are not equal
      switch eq(length, mload(_postBytes))
      case 1 {
        /**
         * @dev cb is a circuit breaker in the for loop since there's
         * no said feature for inline assembly loops
         * cb = 1 - don't breaker
         * cb = 0 - break
         */
        let cb := 1

        let mc := add(_preBytes, 0x20)
        let end := add(mc, length)

        for { let cc := add(_postBytes, 0x20) }
        // The next line is the loop condition: while(uint256(mc < end) + cb == 2).
        eq(add(lt(mc, end), cb), 2) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          // If any of these checks fails then arrays are not equal.
          if iszero(eq(mload(mc), mload(cc))) {
            // Unsuccess:
            success := 0
            cb := 0
          }
        }
      }
      default {
        // Unsuccess:
        success := 0
      }
    }

    return success;
  }

  function equalStorage(
    bytes storage _preBytes,
    bytes memory _postBytes
  )
    internal
    view
    returns (bool)
  {
    bool success = true;

    assembly {
      // We know _preBytes_offset is 0.
      let fslot := sload(_preBytes.slot)
      // Decode the length of the stored array like in concatStorage().
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)

      // If lengths don't match the arrays are not equal.
      switch eq(slength, mlength)
      case 1 {
        /**
         * @dev Slength can contain both the length and contents of the array
         * if length < 32 bytes so let's prepare for that
         * v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
         */
        if iszero(iszero(slength)) {
          switch lt(slength, 32)
          case 1 {
            // Blank the last byte which is the length.
            fslot := mul(div(fslot, 0x100), 0x100)

            if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
              // Unsuccess:
              success := 0
            }
          }
          default {
            /**
             * @dev cb is a circuit breaker in the for loop since there's
             * no said feature for inline assembly loops
             * cb = 1 - don't breaker
             * cb = 0 - break
             */
            let cb := 1

            // Get the keccak hash to get the contents of the array.
            mstore(0x0, _preBytes.slot)
            let sc := keccak256(0x0, 0x20)

            let mc := add(_postBytes, 0x20)
            let end := add(mc, mlength)

            // The next line is the loop condition: while(uint256(mc < end) + cb == 2)
            for {} eq(add(lt(mc, end), cb), 2) {
              sc := add(sc, 1)
              mc := add(mc, 0x20)
            } {
              if iszero(eq(sload(sc), mload(mc))) {
                // Unsuccess:
                success := 0
                cb := 0
              }
            }
          }
        }
      }
      default {
        // Unsuccess:
        success := 0
      }
    }

    return success;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IVault} from "./IVault.sol";

/**
 * @title ILendingProvider
 *
 * @author Fujidao Labs
 *
 * @notice  Defines the interface for core engine to perform operations at lending providers.
 *
 * @dev Functions are intended to be called in the context of a Vault via delegateCall,
 * except indicated.
 */

interface ILendingProvider {
  function providerName() external view returns (string memory);
  /**
   * @notice Returns the operator address that requires ERC20-approval for vault operations.
   *
   * @param keyAsset address to inquiry operator
   * @param asset address of the calling vault
   * @param debtAsset address of the calling vault. Note: if {YieldVault} this will be address(0).
   *
   * @dev Provider implementations may or not require all 3 inputs.
   */
  function approvedOperator(
    address keyAsset,
    address asset,
    address debtAsset
  )
    external
    view
    returns (address operator);

  /**
   * @notice Performs deposit operation at lending provider on behalf vault.
   *
   * @param amount amount to deposit
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function deposit(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs borrow operation at lending provider on behalf vault.
   *
   * @param amount amount to borrow
   * @param vault IVault calling this function
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function borrow(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf vault.
   * @param amount amount to withdraw
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function withdraw(uint256 amount, IVault vault) external returns (bool success);

  /**
   *
   * @notice Performs payback operation at lending provider on behalf vault.
   *
   * @param amount amount to payback
   * @param vault IVault calling this function.
   *
   * @dev Requirements:
   * - This function should be delegate called in the context of a `vault`.
   * - Check there is erc20-approval to `approvedOperator` by the `vault` prior to call.
   */
  function payback(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getDepositBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns BORROW balance of 'user' at lending provider.
   *
   * @param user address whom balance is needed
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * @dev Requirements:
   * - Must not require Vault context.
   */
  function getBorrowBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getDepositRateFor(IVault vault) external view returns (uint256 rate);

  /**
   * @notice Returns the latest BORROW annual percent rate (APR) at lending provider.
   *
   * @param vault IVault required by some specific providers with multi-markets, otherwise pass address(0)
   *
   * @dev Requirements:
   * - Must return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - Must not require Vault context.
   */
  function getBorrowRateFor(IVault vault) external view returns (uint256 rate);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFujiOracle
 *
 * @author Fujidao Labs
 *
 * @notice Defines the interface of the {FujiOracle}.
 */

interface IFujiOracle {
  /**
   * @dev Emit when a change in price feed address is done for an `asset`.
   *
   * @param asset address
   * @param newPriceFeedAddress that returns USD price from Chainlink
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  /**
   * @notice Returns the exchange rate between two assets, with price oracle given in
   * specified `decimals`.
   *
   * @param currencyAsset to be used, zero-address for USD
   * @param commodityAsset to be used, zero-address for USD
   * @param decimals  of the desired price output
   *
   * @dev Price format is defined as: (amount of currencyAsset per unit of commodityAsset Exchange Rate).
   * Requirements:
   * - Must check that both `currencyAsset` and `commodityAsset` are set in
   *   usdPriceFeeds, otherwise return zero.
   */
  function getPriceOf(
    address currencyAsset,
    address commodityAsset,
    uint8 decimals
  )
    external
    view
    returns (uint256);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title SystemAccessControl
 *
 * @author Fujidao Labs
 *
 * @notice Abstract contract that should be inherited by contract implementations that
 * call the {Chief} contract for access control checks.
 */

import {IChief} from "../interfaces/IChief.sol";
import {CoreRoles} from "./CoreRoles.sol";

contract SystemAccessControl is CoreRoles {
  /// @dev Custom Errors
  error SystemAccessControl__hasRole_missingRole(address caller, bytes32 role);
  error SystemAccessControl__onlyTimelock_callerIsNotTimelock();
  error SystemAccessControl__onlyHouseKeeper_notHouseKeeper();

  IChief public immutable chief;

  /**
   * @dev Modifier that checks `caller` has `role`.
   */
  modifier hasRole(address caller, bytes32 role) {
    if (!chief.hasRole(role, caller)) {
      revert SystemAccessControl__hasRole_missingRole(caller, role);
    }
    _;
  }

  /**
   * @dev Modifier that checks `msg.sender` has HOUSE_KEEPER_ROLE.
   */
  modifier onlyHouseKeeper() {
    if (!chief.hasRole(HOUSE_KEEPER_ROLE, msg.sender)) {
      revert SystemAccessControl__onlyHouseKeeper_notHouseKeeper();
    }
    _;
  }

  /**
   * @dev Modifier that checks `msg.sender` is the defined `timelock` in {Chief}
   * contract.
   */
  modifier onlyTimelock() {
    if (msg.sender != chief.timelock()) {
      revert SystemAccessControl__onlyTimelock_callerIsNotTimelock();
    }
    _;
  }

  /**
   * @notice Abstract constructor of a new {SystemAccessControl}.
   *
   * @param chief_ address
   *
   * @dev Requirements:
   * - Must pass non-zero {Chief} address, that could be checked at child contract.
   */
  constructor(address chief_) {
    chief = IChief(chief_);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
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
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
pragma solidity 0.8.15;

/**
 * @title CoreRoles
 *
 * @author Fujidao Labs
 *
 * @notice System definition of roles used across FujiV2 contracts.
 */

contract CoreRoles {
  bytes32 public constant HOUSE_KEEPER_ROLE = keccak256("HOUSE_KEEPER_ROLE");

  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
}