// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {MangroveOffer} from "mgv_src/strategies/MangroveOffer.sol";
import {MgvLib} from "mgv_src/MgvLib.sol";
import {AbstractRouter, AavePooledRouter} from "mgv_src/strategies/routers/integrations/AavePooledRouter.sol";
import {IATokenIsh} from "mgv_src/strategies/vendor/aave/v3/IATokenIsh.sol";
import {GeometricKandel} from "./abstract/GeometricKandel.sol";
import {AbstractKandel} from "./abstract/AbstractKandel.sol";
import {OfferType} from "./abstract/TradesBaseQuotePair.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/IERC20.sol";

///@title A Kandel strat with geometric price progression which stores funds on AAVE to generate yield.
contract AaveKandel is GeometricKandel {
  ///@notice Indication that this is first puller (returned from __lastLook__) so posthook should deposit liquidity on AAVE
  bytes32 internal constant IS_FIRST_PULLER = "IS_FIRST_PULLER";

  ///@notice Constructor
  ///@param mgv The Mangrove deployment.
  ///@param base Address of the base token of the market Kandel will act on
  ///@param quote Address of the quote token of the market Kandel will act on
  ///@param gasreq the gasreq to use for offers
  ///@param gasprice the gasprice to use for offers
  ///@param reserveId identifier of this contract's reserve when using a router.
  constructor(IMangrove mgv, IERC20 base, IERC20 quote, uint gasreq, uint gasprice, address reserveId)
    GeometricKandel(mgv, base, quote, gasreq, gasprice, reserveId)
  {
    // one makes sure it is not possible to deploy an AAVE kandel on aTokens
    // allowing Kandel to deposit aUSDC for instance would conflict with other Kandel instances bound to the same router
    // and trading on USDC.
    // The code below verifies that neither base nor quote are official AAVE overlyings.
    bool isOverlying;
    try IATokenIsh(address(base)).UNDERLYING_ASSET_ADDRESS() returns (address) {
      isOverlying = true;
    } catch {}
    try IATokenIsh(address(quote)).UNDERLYING_ASSET_ADDRESS() returns (address) {
      isOverlying = true;
    } catch {}
    require(!isOverlying, "AaveKandel/cannotTradeAToken");
  }

  ///@notice returns the router as an Aave router
  ///@return The aave router.
  function pooledRouter() private view returns (AavePooledRouter) {
    AbstractRouter router_ = router();
    require(router_ != NO_ROUTER, "AaveKandel/uninitialized");
    return AavePooledRouter(address(router_));
  }

  ///@notice Sets the AaveRouter as router and activates router for base and quote
  ///@param router_ the Aave router to use.
  function initialize(AavePooledRouter router_) external onlyAdmin {
    setRouter(router_);
    // calls below will fail if router's admin has not bound router to `this`. We call __activate__ instead of activate just to save gas.
    __activate__(BASE);
    __activate__(QUOTE);
    setGasreq(offerGasreq());
  }

  ///@inheritdoc AbstractKandel
  function depositFunds(uint baseAmount, uint quoteAmount) public override {
    // transfer funds from caller to this
    super.depositFunds(baseAmount, quoteAmount);
    // push funds on the router (and supply on AAVE)
    pooledRouter().pushAndSupply(BASE, baseAmount, QUOTE, quoteAmount, RESERVE_ID);
  }

  ///@inheritdoc AbstractKandel
  function withdrawFunds(uint baseAmount, uint quoteAmount, address recipient) public override onlyAdmin {
    if (baseAmount != 0) {
      pooledRouter().withdraw(BASE, RESERVE_ID, baseAmount);
    }
    if (quoteAmount != 0) {
      pooledRouter().withdraw(QUOTE, RESERVE_ID, quoteAmount);
    }
    super.withdrawFunds(baseAmount, quoteAmount, recipient);
  }

  ///@notice returns the amount of the router's balance that belong to this contract for the token offered for the offer type.
  ///@inheritdoc AbstractKandel
  function reserveBalance(OfferType ba) public view override returns (uint balance) {
    IERC20 token = outboundOfOfferType(ba);
    return pooledRouter().balanceOfReserve(token, RESERVE_ID) + super.reserveBalance(ba);
  }

  /// @notice Verifies, prior to pulling funds from the router, whether pull will be fetching funds on AAVE
  /// @inheritdoc MangroveOffer
  function __lastLook__(MgvLib.SingleOrder calldata order) internal override returns (bytes32) {
    bytes32 makerData = super.__lastLook__(order);
    return (IERC20(order.outbound_tkn).balanceOf(address(router())) < order.wants) ? IS_FIRST_PULLER : makerData;
  }

  ///@notice overrides and replaces Direct's posthook in order to push and supply on AAVE with a single call when offer logic is the first to pull funds from AAVE
  ///@inheritdoc MangroveOffer
  function __posthookSuccess__(MgvLib.SingleOrder calldata order, bytes32 makerData)
    internal
    override
    returns (bytes32 repostStatus)
  {
    // handle dual offer posting
    transportSuccessfulOrder(order);

    // handles pushing back liquidity to the router
    if (makerData == IS_FIRST_PULLER) {
      // if first puller, then router should deposit liquidity on AAVE
      pooledRouter().pushAndSupply(
        BASE, BASE.balanceOf(address(this)), QUOTE, QUOTE.balanceOf(address(this)), RESERVE_ID
      );
      // reposting offer residual if any - but do not call super, since Direct will flush tokens unnecessarily
      repostStatus = MangroveOffer.__posthookSuccess__(order, makerData);
    } else {
      // reposting offer residual if any - call super to let flush tokens to router
      repostStatus = super.__posthookSuccess__(order, makerData);
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {AccessControlled} from "mgv_src/strategies/utils/AccessControlled.sol";
import {IOfferLogic} from "mgv_src/strategies/interfaces/IOfferLogic.sol";
import {MgvLib, IERC20, MgvStructs} from "mgv_src/MgvLib.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {AbstractRouter} from "mgv_src/strategies/routers/AbstractRouter.sol";
import {TransferLib} from "mgv_src/strategies/utils/TransferLib.sol";

/// @title This contract is the basic building block for Mangrove strats.
/// @notice It contains the mandatory interface expected by Mangrove (`IOfferLogic` is `IMaker`) and enforces additional functions implementations (via `IOfferLogic`).
/// @dev Naming scheme:
/// `f() public`: can be used, as is, in all descendants of `this` contract
/// `_f() internal`: descendant of this contract should provide a public wrapper for this function, with necessary guards.
/// `__f__() virtual internal`: descendant of this contract should override this function to specialize it to the needs of the strat.

abstract contract MangroveOffer is AccessControlled, IOfferLogic {
  ///@notice Gas requirement when posting offers via this strategy, excluding router requirement.
  uint public immutable OFFER_GASREQ;
  ///@notice The Mangrove deployment that is allowed to call `this` for trade execution and posthook.
  IMangrove public immutable MGV;
  ///@notice constant for no router
  AbstractRouter public constant NO_ROUTER = AbstractRouter(address(0));
  ///@notice The router to use for this strategy.
  AbstractRouter private __router;

  ///@notice The offer was successfully reposted.
  bytes32 internal constant REPOST_SUCCESS = "offer/updated";
  ///@notice New offer successfully created.
  bytes32 internal constant NEW_OFFER_SUCCESS = "offer/created";
  ///@notice The offer was completely filled.
  bytes32 internal constant COMPLETE_FILL = "offer/filled";

  /**
   * @notice The Mangrove deployment that is allowed to call `this` for trade execution and posthook.
   *   @param mgv The Mangrove deployment.
   */
  event Mgv(IMangrove mgv);

  ///@notice Mandatory function to allow `this` to receive native tokens from Mangrove after a call to `MGV.withdraw(...,deprovision:true)`
  ///@dev override this function if `this` contract needs to handle local accounting of user funds.
  receive() external payable virtual {}

  /**
   * @notice `MangroveOffer`'s constructor
   * @param mgv The Mangrove deployment that is allowed to call `this` for trade execution and posthook.
   * @param gasreq Gas requirement when posting offers via this strategy, excluding router requirement.
   */
  constructor(IMangrove mgv, uint gasreq) AccessControlled(msg.sender) {
    require(uint24(gasreq) == gasreq, "mgvOffer/gasreqOverflow");
    MGV = mgv;
    OFFER_GASREQ = gasreq;
    emit Mgv(mgv);
  }

  /// @inheritdoc IOfferLogic
  function router() public view override returns (AbstractRouter) {
    return __router;
  }

  /// @inheritdoc IOfferLogic
  function offerGasreq() public view returns (uint) {
    AbstractRouter router_ = router();
    if (router_ != NO_ROUTER) {
      return OFFER_GASREQ + router_.routerGasreq();
    } else {
      return OFFER_GASREQ;
    }
  }

  ///*****************************
  /// Mandatory callback functions
  ///*****************************

  ///@notice `makerExecute` is the callback function to execute all offers that were posted on Mangrove by `this` contract.
  ///@param order a data structure that recapitulates the taker order and the offer as it was posted on mangrove
  ///@return ret a bytes32 word to pass information (if needed) to the posthook
  ///@dev it may not be overriden although it can be customized using `__lastLook__`, `__put__` and `__get__` hooks.
  /// NB #1: if `makerExecute` reverts, the offer will be considered to be refusing the trade.
  /// NB #2: `makerExecute` may return a `bytes32` word to pass information to posthook w/o using storage reads/writes.
  /// NB #3: Reneging on trade will have the following effects:
  /// * Offer is removed from the Order Book
  /// * Offer bounty will be withdrawn from offer provision and sent to the offer taker. The remaining provision will be credited to the maker account on Mangrove
  function makerExecute(MgvLib.SingleOrder calldata order)
    external
    override
    onlyCaller(address(MGV))
    returns (bytes32 ret)
  {
    // Invoke hook that implements a last look check during execution - it may renege on trade by reverting.
    ret = __lastLook__(order);
    // Invoke hook to put the inbound token, which are brought by the taker, into a specific reserve.
    require(__put__(order.gives, order) == 0, "mgvOffer/abort/putFailed");
    // Invoke hook to fetch the outbound token, which are promised to the taker, from a specific reserve.
    require(__get__(order.wants, order) == 0, "mgvOffer/abort/getFailed");
  }

  /// @notice `makerPosthook` is the callback function that is called by Mangrove *after* the offer execution.
  /// @notice reverting during its execution will not renege on trade. Revert reason (casted to 32 bytes) is then logged by Mangrove in event `PosthookFail`.
  /// @param order a data structure that recapitulates the taker order and the offer as it was posted on mangrove
  /// @param result a data structure that gathers information about trade execution
  /// @dev It cannot be overridden but can be customized via the hooks `__posthookSuccess__` and `__posthookFallback__` (see below).
  function makerPosthook(MgvLib.SingleOrder calldata order, MgvLib.OrderResult calldata result)
    external
    override
    onlyCaller(address(MGV))
  {
    if (result.mgvData == "mgv/tradeSuccess") {
      __posthookSuccess__(order, result.makerData);
    } else {
      // logging what went wrong during `makerExecute`
      emit LogIncident(
        MGV, IERC20(order.outbound_tkn), IERC20(order.inbound_tkn), order.offerId, result.makerData, result.mgvData
      );
      // calling strat specific todos in case of failure
      __posthookFallback__(order, result);
      __handleResidualProvision__(order);
    }
  }

  ///@notice takes care of status for reposting residual offer in case of a partial fill and logging of potential issues.
  ///@param order a recap of the taker order
  ///@param makerData generated during `makerExecute` so as to log it if necessary
  ///@param repostStatus from the posthook that handles residual reposting
  function logRepostStatus(MgvLib.SingleOrder calldata order, bytes32 makerData, bytes32 repostStatus) internal {
    // reposting below density is not considered an incident in order to allow the contract not to check density before posting residual
    if (
      repostStatus == COMPLETE_FILL || repostStatus == REPOST_SUCCESS || repostStatus == "mgv/writeOffer/density/tooLow"
    ) {
      return;
    } else {
      // Offer failed to repost for bad reason, logging the incident
      emit LogIncident(
        MGV, IERC20(order.outbound_tkn), IERC20(order.inbound_tkn), order.offerId, makerData, repostStatus
      );
    }
  }

  /// @inheritdoc IOfferLogic
  function setRouter(AbstractRouter router_) public override onlyAdmin {
    __router = router_;
    emit SetRouter(router_);
  }

  /// @inheritdoc IOfferLogic
  function approve(IERC20 token, address spender, uint amount) public override onlyAdmin returns (bool) {
    require(TransferLib.approveToken(token, spender, amount), "mgvOffer/approve/failed");
    return true;
  }

  /// @inheritdoc IOfferLogic
  function activate(IERC20[] calldata tokens) external override onlyAdmin {
    for (uint i = 0; i < tokens.length; ++i) {
      __activate__(tokens[i]);
    }
  }

  ///@notice verifies that Mangrove is allowed to pull tokens from this contract.
  ///@inheritdoc IOfferLogic
  function checkList(IERC20[] calldata tokens) external view override {
    for (uint i = 0; i < tokens.length; ++i) {
      __checkList__(tokens[i]);
    }
  }

  ///@notice override conservatively to define strat-specific additional activation steps.
  ///@param token the ERC20 one wishes this contract to trade on.
  ///@custom:hook overrides of this hook should be conservative and call `super.__activate__(token)`
  function __activate__(IERC20 token) internal virtual {
    AbstractRouter router_ = router();
    // all strat require `this` to approve Mangrove for pulling `token` at the end of `makerExecute`
    require(TransferLib.approveToken(token, address(MGV), type(uint).max), "mgvOffer/approveMangrove/Fail");
    if (router_ != NO_ROUTER) {
      // allowing router to pull `token` from this contract (for the `push` function of the router)
      require(TransferLib.approveToken(token, address(router_), type(uint).max), "mgvOffer/approveRouterFail");
      // letting router performs additional necessary approvals (if any)
      // this will only work if `this` is an authorized maker of the router (i.e. `router.bind(address(this))` has been called by router's admin).
      router_.activate(token);
    }
  }

  ///@notice verifies that Mangrove is allowed to pull tokens from this contract and other strat specific verifications.
  ///@param token a token that is traded by this contract
  ///@custom:hook overrides of this hook should be conservative and call `super.__checkList__(token)`
  function __checkList__(IERC20 token) internal view virtual {
    require(token.allowance(address(this), address(MGV)) > 0, "mgvOffer/LogicMustApproveMangrove");
  }

  /// @inheritdoc IOfferLogic
  function withdrawFromMangrove(uint amount, address payable receiver) public onlyAdmin {
    if (amount == type(uint).max) {
      amount = MGV.balanceOf(address(this));
    }
    // the require below is necessary if the `receive()` function is overriden
    require(MGV.withdraw(amount), "mgvOffer/withdrawFail");
    (bool noRevert,) = receiver.call{value: amount}("");
    // if `receiver` is actually not payable
    require(noRevert, "mgvOffer/weiTransferFail");
  }

  ///@notice Hook that implements where the inbound token, which are brought by the Offer Taker, should go during Taker Order's execution.
  ///@param amount of `inbound` tokens that are on `this` contract's balance and still need to be deposited somewhere
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  ///@return missingPut (<=`amount`) is the amount of `inbound` tokens whose deposit location has not been decided (possibly because of a failure) during this function execution
  ///@dev if the last nested call to `__put__` returns a non zero value, trade execution will revert
  ///@custom:hook overrides of this hook should be conservative and call `super.__put__(missing, order)`
  function __put__(uint amount, MgvLib.SingleOrder calldata order) internal virtual returns (uint missingPut);

  ///@notice Hook that implements where the outbound token, which are promised to the taker, should be fetched from, during Taker Order's execution.
  ///@param amount of `outbound` tokens that still needs to be brought to the balance of `this` contract when entering this function
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  ///@return missingGet (<=`amount`), which is the amount of `outbound` tokens still need to be fetched at the end of this function
  ///@dev if the last nested call to `__get__` returns a non zero value, trade execution will revert
  ///@custom:hook overrides of this hook should be conservative and call `super.__get__(missing, order)`
  function __get__(uint amount, MgvLib.SingleOrder calldata order) internal virtual returns (uint missingGet);

  /// @notice Hook that implements a last look check during Taker Order's execution.
  /// @param order is a recall of the taker order that is at the origin of the current trade.
  /// @return data is a message that will be passed to posthook provided `makerExecute` does not revert.
  /// @dev __lastLook__ should revert if trade is to be reneged on. If not, returned `bytes32` are passed to `makerPosthook` in the `makerData` field.
  /// @custom:hook overrides of this hook should be conservative and call `super.__lastLook__(order)`.
  function __lastLook__(MgvLib.SingleOrder calldata order) internal virtual returns (bytes32 data) {
    order; //shh
    data = bytes32(0);
  }

  ///@notice Post-hook that implements fallback behavior when Taker Order's execution failed unexpectedly.
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  ///@param result contains information about trade.
  ///@return data contains verdict and reason about the executed trade.
  ///@dev `result.mgvData` is Mangrove's verdict about trade success
  ///@dev `result.makerData` either contains the first 32 bytes of revert reason if `makerExecute` reverted or the returned `bytes32`.
  /// @custom:hook overrides of this hook should be conservative and call `super.__posthookFallback__(order, result)`
  function __posthookFallback__(MgvLib.SingleOrder calldata order, MgvLib.OrderResult calldata result)
    internal
    virtual
    returns (bytes32 data)
  {
    order;
    result;
    data = bytes32(0);
  }

  ///@notice Given the current taker order that (partially) consumes an offer, this hook is used to declare how much `order.inbound_tkn` the offer wants after it is reposted.
  ///@param order is a recall of the taker order that is being treated.
  ///@return newWants the new volume of `inbound_tkn` the offer will ask for on Mangrove
  ///@dev default is to require the original amount of tokens minus those that have been given by the taker during trade execution.
  function __residualWants__(MgvLib.SingleOrder calldata order) internal virtual returns (uint newWants) {
    newWants = order.offer.wants() - order.gives;
  }

  ///@notice Given the current taker order that (partially) consumes an offer, this hook is used to declare how much `order.outbound_tkn` the offer gives after it is reposted.
  ///@param order is a recall of the taker order that is being treated.
  ///@return newGives the new volume of `outbound_tkn` the offer will give if fully taken.
  ///@dev default is to require the original amount of tokens minus those that have been sent to the taker during trade execution.
  function __residualGives__(MgvLib.SingleOrder calldata order) internal virtual returns (uint newGives) {
    return order.offer.gives() - order.wants;
  }

  ///@notice Hook that defines what needs to be done to the part of an offer provision that was added to the balance of `this` on Mangrove after an offer has failed.
  ///@param order is a recall of the taker order that failed
  function __handleResidualProvision__(MgvLib.SingleOrder calldata order) internal virtual {
    order; // we leave the provision on Mangrove
  }

  ///@notice Post-hook that implements default behavior when Taker Order's execution succeeded.
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  ///@param makerData is the returned value of the `__lastLook__` hook, triggered during trade execution. The special value `"lastLook/retract"` should be treated as an instruction not to repost the offer on the book.
  ///@return data can be:
  /// * `COMPLETE_FILL` when offer was completely filled
  /// * returned data of `_updateOffer` signalling the status of the reposting attempt.
  /// @custom:hook overrides of this hook should be conservative and call `super.__posthookSuccess__(order, maker_data)`
  function __posthookSuccess__(MgvLib.SingleOrder calldata order, bytes32 makerData)
    internal
    virtual
    returns (bytes32 data)
  {
    // now trying to repost residual
    uint new_gives = __residualGives__(order);
    uint new_wants = __residualWants__(order);
    // Density check at each repost would be too gas costly.
    // We only treat the special case of `gives==0` or `wants==0` (total fill).
    // Offer below the density will cause Mangrove to throw so we encapsulate the call to `updateOffer` in order not to revert posthook for posting at dust level.
    if (new_gives == 0 || new_wants == 0) {
      return COMPLETE_FILL;
    }
    data = _updateOffer(
      OfferArgs({
        outbound_tkn: IERC20(order.outbound_tkn),
        inbound_tkn: IERC20(order.inbound_tkn),
        wants: new_wants,
        gives: new_gives,
        gasreq: order.offerDetail.gasreq(),
        gasprice: order.offerDetail.gasprice(),
        pivotId: order.offer.next(), // using next as pivot since this offer is off the book
        noRevert: true,
        fund: 0
      }),
      order.offerId
    );
    // logs if anything went wrong
    logRepostStatus(order, makerData, data);
  }

  ///@notice Updates the offer specified by `offerId` on Mangrove with the parameters in `args`.
  ///@param args A memory struct containing the offer parameters to update.
  ///@param offerId An unsigned integer representing the identifier of the offer to be updated.
  ///@return status a `bytes32` value representing either `REPOST_SUCCESS` if the update is successful, or an error message if an error occurs and `OfferArgs.noRevert` is `true`. If `OfferArgs.noRevert` is `false`, the function reverts with the error message as the reason.
  function _updateOffer(OfferArgs memory args, uint offerId) internal virtual returns (bytes32);

  ///@notice computes the provision that can be redeemed if deprovisioning a certain offer
  ///@param outbound_tkn the outbound token of the offer list
  ///@param inbound_tkn the inbound token of the offer list
  ///@param offerId the id of the offer
  ///@return provision the provision that can be redeemed
  function _provisionOf(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId) internal view returns (uint provision) {
    MgvStructs.OfferDetailPacked offerDetail = MGV.offerDetails(address(outbound_tkn), address(inbound_tkn), offerId);
    unchecked {
      provision = offerDetail.gasprice() * 10 ** 9 * (offerDetail.offer_gasbase() + offerDetail.gasreq());
    }
  }
}

// SPDX-License-Identifier: Unlicense

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;

import "./preprocessed/MgvStructs.post.sol" as MgvStructs;
import {IERC20} from "./IERC20.sol";

/* # Structs
The structs defined in `structs.js` have their counterpart as solidity structs that are easy to manipulate for outside contracts / callers of view functions. */

library MgvLib {
  /*
   Some miscellaneous data types useful to `Mangrove` and external contracts */
  //+clear+

  /* `SingleOrder` holds data about an order-offer match in a struct. Used by `marketOrder` and `internalSnipes` (and some of their nested functions) to avoid stack too deep errors. */
  struct SingleOrder {
    address outbound_tkn;
    address inbound_tkn;
    uint offerId;
    MgvStructs.OfferPacked offer;
    /* `wants`/`gives` mutate over execution. Initially the `wants`/`gives` from the taker's pov, then actual `wants`/`gives` adjusted by offer's price and volume. */
    uint wants;
    uint gives;
    /* `offerDetail` is only populated when necessary. */
    MgvStructs.OfferDetailPacked offerDetail;
    MgvStructs.GlobalPacked global;
    MgvStructs.LocalPacked local;
  }

  /* <a id="MgvLib/OrderResult"></a> `OrderResult` holds additional data for the maker and is given to them _after_ they fulfilled an offer. It gives them their own returned data from the previous call, and an `mgvData` specifying whether Mangrove encountered an error. */

  struct OrderResult {
    /* `makerdata` holds a message that was either returned by the maker or passed as revert message at the end of the trade execution*/
    bytes32 makerData;
    /* `mgvData` is an [internal Mangrove status code](#MgvOfferTaking/statusCodes) code. */
    bytes32 mgvData;
  }
}

/* # Events
The events emitted for use by bots are listed here: */
contract HasMgvEvents {
  /* * Emitted at the creation of the new Mangrove contract on the pair (`inbound_tkn`, `outbound_tkn`)*/
  event NewMgv();

  /* Mangrove adds or removes wei from `maker`'s account */
  /* * Credit event occurs when an offer is removed from Mangrove or when the `fund` function is called*/
  event Credit(address indexed maker, uint amount);
  /* * Debit event occurs when an offer is posted or when the `withdraw` function is called */
  event Debit(address indexed maker, uint amount);

  /* * Mangrove reconfiguration */
  event SetActive(address indexed outbound_tkn, address indexed inbound_tkn, bool value);
  event SetFee(address indexed outbound_tkn, address indexed inbound_tkn, uint value);
  event SetGasbase(address indexed outbound_tkn, address indexed inbound_tkn, uint offer_gasbase);
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetUseOracle(bool value);
  event SetNotify(bool value);
  event SetGasmax(uint value);
  event SetDensity(address indexed outbound_tkn, address indexed inbound_tkn, uint value);
  event SetGasprice(uint value);

  /* Market order execution */
  event OrderStart();
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address indexed taker,
    uint takerGot,
    uint takerGave,
    uint penalty,
    uint feePaid
  );

  /* * Offer execution */
  event OfferSuccess(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives
  );

  /* Log information when a trade execution reverts or returns a non empty bytes32 word */
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives,
    // `mgvData` may only be `"mgv/makerRevert"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"`
    bytes32 mgvData
  );

  /* Log information when a posthook reverts */
  event PosthookFail(address indexed outbound_tkn, address indexed inbound_tkn, uint offerId, bytes32 posthookData);

  /* * After `permit` and `approve` */
  event Approval(address indexed outbound_tkn, address indexed inbound_tkn, address owner, address spender, uint value);

  /* * Mangrove closure */
  event Kill();

  /* * An offer was created or updated.
  A few words about why we include a `prev` field, and why we don't include a
  `next` field: in theory clients should need neither `prev` nor a `next` field.
  They could just 1. Read the order book state at a given block `b`.  2. On
  every event, update a local copy of the orderbook.  But in practice, we do not
  want to force clients to keep a copy of the *entire* orderbook. There may be a
  long tail of spam. Now if they only start with the first $N$ offers and
  receive a new offer that goes to the end of the book, they cannot tell if
  there are missing offers between the new offer and the end of the local copy
  of the book.
  
  So we add a prev pointer so clients with only a prefix of the book can receive
  out-of-prefix offers and know what to do with them. The `next` pointer is an
  optimization useful in Solidity (we traverse fewer memory locations) but
  useless in client code.
  */
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );

  /* * `offerId` was present and is now removed from the book. */
  event OfferRetract(address indexed outbound_tkn, address indexed inbound_tkn, uint id, bool deprovision);
}

/* # IMaker interface */
interface IMaker {
  /* Called upon offer execution. 
  - If the call throws, Mangrove will not try to transfer funds and the first 32 bytes of revert reason are passed to `makerPosthook` as `makerData`
  - If the call returns normally, returndata is passed to `makerPosthook` as `makerData` and Mangrove will attempt to transfer the funds.
  */
  function makerExecute(MgvLib.SingleOrder calldata order) external returns (bytes32);

  /* Called after all offers of an order have been executed. Posthook of the last executed order is called first and full reentrancy into Mangrove is enabled at this time. `order` recalls key arguments of the order that was processed and `result` recalls important information for updating the current offer. (see [above](#MgvLib/OrderResult))*/
  function makerPosthook(MgvLib.SingleOrder calldata order, MgvLib.OrderResult calldata result) external;
}

/* # ITaker interface */
interface ITaker {
  /* Inverted mangrove only: call to taker after loans went through */
  function takerTrade(
    address outbound_tkn,
    address inbound_tkn,
    // total amount of outbound_tkn token that was flashloaned to the taker
    uint totalGot,
    // total amount of inbound_tkn token that should be made available
    uint totalGives
  ) external;
}

/* # Monitor interface
If enabled, the monitor receives notification after each offer execution and is read for each pair's `gasprice` and `density`. */
interface IMgvMonitor {
  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker) external;

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external;

  function read(address outbound_tkn, address inbound_tkn) external view returns (uint gasprice, uint density);
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {AbstractRouter} from "../AbstractRouter.sol";
import {TransferLib} from "mgv_src/strategies/utils/TransferLib.sol";
import {HasAaveBalanceMemoizer} from "./HasAaveBalanceMemoizer.sol";
import {IERC20} from "mgv_src/IERC20.sol";

///@title Router acting as a liquidity reserve on AAVE for multiple depositors (possibly coming from different maker contracts).
///@notice maker contracts deposit/withdraw their user(s) fund(s) on this router, which maintains an accounting of shares attributed to each depositor
///@dev deposit is made via `pushAndSupply`, and withdraw is made via `pull` with `strict=true`.
///@dev this router ensures an optimal gas cost complexity when the following strategy is used:
/// * on the offer logic side:
///    * in `makerExecute`, check whether logic is the first caller to the router. This is done by checking whether the balance of outbound tokens of the router is below the required amount. If so the logic should return a special bytes32 (say `"firstCaller"`) to makerPosthook.
///    * in `__put__`  the logic stores incoming liquidity on the strat balance
///    * in `__get__` the logic pulls liquidity from the router in a non strict manner
///    * in __posthookSuccess|Fallback__ the logic pushes both inbound and outbound tokens to the router. If message from makerExecute is `"firstCaller"`, the logic additionally asks the router to supply all its outbound and inbound tokens to AAVE. This can be done is a single step by calling `pushAndSupply`
/// * on the router side:
///    * `__pull__`  checks whether local balance of token is below required amount. If so it pulls all its funds from AAVE (this includes funds that do not belong to the owner of the calling contract) and sends to caller all the owner's reserve (according to the shares attributed to the owner - except in case of liquidity sharing where only requested amount is transferred). This router then decreases owner's shares accordingly. (note that if AAVE has no liquidity crisis, then the owner's shares will be temporarily 0)
///    * `__push__` transfers the requested amount of tokens from the calling maker contract and increases owner's shares, but does not supply on AAVE

contract AavePooledRouter is HasAaveBalanceMemoizer, AbstractRouter {
  ///@notice the manager which controls which pools are allowed.
  address public aaveManager;

  ///@notice The `aaveManager` has been set.
  ///@param manager the new manager.
  event SetAaveManager(address manager);

  ///@notice An error occurred during deposit to AAVE.
  ///@param token the deposited token.
  ///@param maker the maker contract that was calling `pushAndSupply`.
  ///@param reserveId the reserve identifier that was calling `pushAndSupply`.
  ///@param aaveReason the reason from AAVE.
  event AaveIncident(IERC20 indexed token, address indexed maker, address indexed reserveId, bytes32 aaveReason);

  ///@notice the total shares for each token, i.e. the total shares one would need to possess in order to claim the entire pool of tokens.
  mapping(IERC20 => uint) internal _totalShares;

  ///@notice the number of shares for a reserve for a token, i.e. the shares of this router that are attributed to a particular reserve.
  mapping(IERC20 => mapping(address => uint)) internal _sharesOf;

  ///@notice offset for initial shares to be minted
  ///@dev this amount must be big enough to avoid minting 0 shares via "donation"
  /// see https://github.com/code-423n4/2022-09-y2k-finance-findings/issues/449
  /// mitigation proposed here: https://ethereum-magicians.org/t/address-eip-4626-inflation-attacks-with-virtual-shares-and-assets/12677

  uint public constant OFFSET = 19;
  ///@notice initial shares to be minted
  uint internal constant INIT_MINT = 10 ** OFFSET;

  /// OVERFLOW analysis w.r.t offset choice:
  /// worst case is:
  /// 1. Alice, the first minter deposits 1 wei. She gets `10**OFFSET` shares for this.
  /// 2. Alice deposits `amount` into the pool. She gets `10**OFFSET * amount / (amount + 1)` additional shares.
  /// 3. Alice computes her balance. Total shares of the pool is the total share of Alice  ~ `amount * 10**OFFSET` and the pool has ~ `amount` tokens
  ///  so Alice's balance is ~ `(amount * amount * 10**OFFSET) / 10**OFFSET * amount`. This overflows if `amount * amount * 10**OFFSET` overflows.
  ///  Suppose that amount is `2**x`. One must verify that x + x + log2(10) * OFFSET < 256
  ///  This imposes x < (256 - log2(10) * OFFSET) / 2
  /// with OFFSET = 19 we get x < 101 so no overflow is guaranteed for a user balance that can hold on a `uint96`.

  ///@notice contract's constructor
  ///@param addressesProvider address of AAVE's address provider
  ///@param overhead is the amount of gas that is required for this router to be able to perform a `pull` and a `push`.
  constructor(address addressesProvider, uint overhead)
    HasAaveBalanceMemoizer(addressesProvider)
    AbstractRouter(overhead)
  {
    setAaveManager(msg.sender);
  }

  ///@notice returns the shares of this router that are attributed to a particular reserve
  ///@param token the address of the asset
  ///@param reserveId the reserve identifier
  ///@return shares the amount of shares attributed to `reserveId`.
  ///@dev `sharesOf(token,id)/totalShares(token)` represent the portion of this contract's balance of `token`s that the `reserveId` can claim
  function sharesOf(IERC20 token, address reserveId) public view returns (uint shares) {
    shares = _sharesOf[token][reserveId];
  }

  ///@notice returns the total shares one would need to possess in order to claim the entire pool of tokens
  ///@param token the address of the asset
  ///@return total the total amount of shares
  function totalShares(IERC20 token) public view returns (uint total) {
    total = _totalShares[token];
  }

  ///@notice theoretically available funds to this router either in overlying or in tokens (part of it may not be redeemable from AAVE)
  ///@param token the asset whose balance is required
  ///@return balance of the asset
  ///@dev this function relies on the AAVE promise that aToken are in one-to-one correspondence with claimable underlying and use the same decimals
  function totalBalance(IERC20 token) external view returns (uint balance) {
    BalanceMemoizer memory memoizer;
    return _totalBalance(token, memoizer);
  }

  ///@notice `totalBalance` with memoization of balance queries
  ///@param token the asset whose balance is required
  ///@param memoizer the memoizer
  ///@return balance of the asset
  function _totalBalance(IERC20 token, BalanceMemoizer memory memoizer) internal view returns (uint balance) {
    balance = balanceOf(token, memoizer) + balanceOfOverlying(token, memoizer);
  }

  ///@notice computes available funds (modulo available liquidity on AAVE) for a given reserve
  ///@param token the asset one wants to know the balance of
  ///@param reserveId the identifier of the reserve whose balance is queried
  ///@return available funds for the reserve
  function balanceOfReserve(IERC20 token, address reserveId) public view override returns (uint) {
    BalanceMemoizer memory memoizer;
    return _balanceOfReserve(token, reserveId, memoizer);
  }

  ///@notice `balanceOfReserve` with memoization of balance queries
  ///@param token the asset one wants to know the balance of
  ///@param reserveId the identifier of the reserve whose balance is queried
  ///@return balance available funds for the reserve
  ///@param memoizer the memoizer
  function _balanceOfReserve(IERC20 token, address reserveId, BalanceMemoizer memory memoizer)
    internal
    view
    returns (uint balance)
  {
    uint totalShares_ = totalShares(token);
    balance = totalShares_ == 0 ? 0 : sharesOf(token, reserveId) * _totalBalance(token, memoizer) / totalShares_;
  }

  ///@notice computes how many shares an amount of tokens represents
  ///@param token the address of the asset
  ///@param amount of tokens
  ///@param memoizer the memoizer
  ///@return shares the shares that correspond to amount
  function _sharesOfAmount(IERC20 token, uint amount, BalanceMemoizer memory memoizer)
    internal
    view
    returns (uint shares)
  {
    uint totalShares_ = totalShares(token);
    shares = totalShares_ == 0 ? INIT_MINT : totalShares_ * amount / _totalBalance(token, memoizer);
  }

  ///@notice mints a certain quantity of shares for a given asset and assigns them to a reserve
  ///@param token the address of the asset
  ///@param reserveId the address of the reserve who will be assigned new shares
  ///@param amount the amount of assets added to the reserve
  ///@param memoizer the memoizer
  function _mintShares(IERC20 token, address reserveId, uint amount, BalanceMemoizer memory memoizer) internal {
    // computing how many shares should be minted for reserve
    uint sharesToMint = _sharesOfAmount(token, amount, memoizer);
    _sharesOf[token][reserveId] += sharesToMint;
    _totalShares[token] += sharesToMint;
  }

  ///@notice burns a certain quantity of reserve's shares for a given asset
  ///@param token the address of the asset
  ///@param reserveId the address of the reserve who will have shares burnt
  ///@param amount the amount of assets withdrawn from reserve
  ///@param memoizer the memoizer
  ///@dev if one is trying to burn shares from a pool that doesn't have any, the call to `_sharesOfAmount` will return `INIT_MINT`
  ///@dev and thus this contract will throw with "AavePooledRouter/insufficientFunds", even if one is trying to burn 0 shares.
  function _burnShares(IERC20 token, address reserveId, uint amount, BalanceMemoizer memory memoizer) internal {
    // computing how many shares should be minted for maker contract
    uint sharesToBurn = _sharesOfAmount(token, amount, memoizer);
    uint ownerShares = _sharesOf[token][reserveId];
    require(sharesToBurn <= ownerShares, "AavePooledRouter/insufficientFunds");
    // no underflow due to require above
    _sharesOf[token][reserveId] = ownerShares - sharesToBurn;
    // no underflow since _totalShares is the sum of all shares including ownerShares, and the above require.
    _totalShares[token] -= sharesToBurn;
  }

  ///@notice Deposit funds on this router from the calling maker contract
  ///@dev no transfer to AAVE is done at that moment.
  ///@inheritdoc AbstractRouter
  function __push__(IERC20 token, address reserveId, uint amount) internal override returns (uint) {
    BalanceMemoizer memory memoizer;
    _mintShares(token, reserveId, amount, memoizer);
    // Transfer must occur *after* state updating _mintShares above
    require(TransferLib.transferTokenFrom(token, msg.sender, address(this), amount), "AavePooledRouter/pushFailed");
    return amount;
  }

  ///@notice deposit router-local balance of an asset on the AAVE pool
  ///@param token the address of the asset
  ///@param noRevert does not revert if supplies throws
  ///@return reason for revert from Aave.
  function flushBuffer(IERC20 token, bool noRevert) public boundOrAdmin returns (bytes32 reason) {
    return _supply(token, token.balanceOf(address(this)), address(this), noRevert);
  }

  ///@notice pushes each given token from the calling maker contract to this router, then supplies the whole router-local balance to AAVE
  ///@param token0 the first token to deposit
  ///@param amount0 the amount of `token0` to deposit
  ///@param token1 the second token to deposit
  ///@param amount1 the amount of `token1` to deposit
  ///@param reserveId the reserve whose shares should be increased
  ///@return pushed0 the amount of token0 that were successfully pushed
  ///@return pushed1 the amount of token1 that were successfully pushed
  ///@dev an offer logic should call this instead of `flush` when it is the last posthook to be executed
  ///@dev this can be determined by checking during __lastLook__ whether the logic will trigger a withdraw from AAVE (this is the case if router's balance of token is empty)
  ///@dev this call be performed even for tokens with 0 amount for the offer logic, since the logic can be the first in a chain and router needs to flush all
  ///@dev this function is also to be used when user deposits funds on the maker contract
  function pushAndSupply(IERC20 token0, uint amount0, IERC20 token1, uint amount1, address reserveId)
    external
    onlyBound
    returns (uint pushed0, uint pushed1)
  {
    // Push will fail for amount of 0, but since this function is only called for the first maker contract in a chain
    // it needs to also flush tokens with a contract-local 0 amount.
    if (amount0 > 0) {
      pushed0 = __push__(token0, reserveId, amount0);
    }
    if (amount1 > 0) {
      pushed1 = __push__(token1, reserveId, amount1);
    }
    // if AAVE refuses deposit, funds are stored in `this` balance (with no yield)
    // this may happen because max supply of `token` has been reached, or because `token` is not listed on AAVE (`overlying(token)` returns `IERC20(address(0))`)
    bytes32 aaveData = flushBuffer(token0, true);
    if (aaveData != bytes32(0)) {
      emit AaveIncident(token0, msg.sender, reserveId, aaveData);
    }
    aaveData = flushBuffer(token1, true);
    if (aaveData != bytes32(0)) {
      emit AaveIncident(token1, msg.sender, reserveId, aaveData);
    }
  }

  ///@inheritdoc AbstractRouter
  ///@dev outside a market order (i.e if `__pull__` is not called during offer logic's execution) the `token` balance of this router should be empty.
  /// This may not be the case when a "donation" occurred to this contract or if the maker posthook failed to push funds back to AAVE
  /// If the donation is large enough to cover the pull request we use the donation funds
  function __pull__(IERC20 token, address reserveId, uint amount, bool strict) internal override returns (uint) {
    // The amount to redeem from AAVE
    uint toRedeem;
    // The amount to transfer to the calling maker contract
    uint amount_;
    BalanceMemoizer memory memoizer;
    // The local buffer of token to transfer in case funds have already been redeemed or due to a donation.
    uint buffer = balanceOf(token, memoizer);
    uint reserveBalance = _balanceOfReserve(token, reserveId, memoizer);
    if (buffer < amount) {
      // this pull is the first of the market order (that requires funds from AAVE) so we redeem all the reserve from AAVE
      // note in theory we should check buffer == 0 but donation may have occurred.
      // This check forces donation to be at least the amount of outbound tokens promised by caller to avoid griefing (depositing a small donation to make offer fail).
      toRedeem = balanceOfOverlying(token, memoizer);
      amount_ = strict ? amount : reserveBalance;
    } else {
      // since buffer >= amount, this call is not the first pull of the market order (unless a big donation occurred) and we do not withdraw from AAVE
      // we take all we can from the buffer (possibly less than amount_ computed above)
      // toRedeem = 0
      amount_ = strict ? amount : (buffer > reserveBalance ? reserveBalance : buffer);
    }
    redeemAndTransfer(token, reserveId, amount_, toRedeem, memoizer);
    return amount_;
  }

  ///@notice redeems some funds from AAVE pool and transfer some amount to msg.sender.
  ///@param token the asset to transfer
  ///@param reserveId the shares on which funds are being drawn
  ///@param amountToTransfer final amount of asset to transfer
  ///@param amountToRedeem funds that need to be pulled from AAVE for final transfer to succeed
  ///@param memoizer the memoizer
  function redeemAndTransfer(
    IERC20 token,
    address reserveId,
    uint amountToTransfer,
    uint amountToRedeem,
    BalanceMemoizer memory memoizer
  ) internal {
    _burnShares(token, reserveId, amountToTransfer, memoizer);
    // redeem does not change amount of shares. We do this after burning to avoid redeeming on AAVE if caller doesn't have the required funds.
    if (amountToRedeem > 0) {
      // this call will throw if AAVE has a liquidity crisis
      _redeem(token, amountToRedeem, address(this));
    }
    // Transferring funds to the maker contract, at this point we must revert if things go wrong because shares have been burnt on the premise that `amount_` will be transferred.
    require(TransferLib.transferToken(token, msg.sender, amountToTransfer), "AavePooledRouter/withdrawFailed");
  }

  ///@notice withdraw funds from the pool on behalf of some reserve id
  ///@param token the asset to withdraw
  ///@param reserveId the identifier of the share holder
  ///@param amount the amount to withdraw. Use type(uint).max to require withdrawal of the total balance of the caller
  function withdraw(IERC20 token, address reserveId, uint amount) external onlyBound {
    BalanceMemoizer memory memoizer;
    if (amount == type(uint).max) {
      amount = _balanceOfReserve(token, reserveId, memoizer);
    }
    uint buffer = balanceOf(token, memoizer);
    uint toRedeem = buffer > amount ? 0 : amount - buffer;
    redeemAndTransfer(token, reserveId, amount, toRedeem, memoizer);
  }

  ///@inheritdoc AbstractRouter
  function __checkList__(IERC20 token, address reserveId) internal view override {
    // any reserveId passes the checklist since this router does not pull or push liquidity to it (but unknown reserveId will have 0 shares)
    reserveId;
    // we check that `token` is listed on AAVE
    require(checkAsset(token), "AavePooledRouter/tokenNotLendableOnAave");
    require( // required to supply or withdraw token on pool
    token.allowance(address(this), address(POOL)) > 0, "AavePooledRouter/hasNotApprovedPool");
  }

  ///@inheritdoc AbstractRouter
  function __activate__(IERC20 token) internal virtual override {
    _approveLender(token, type(uint).max);
  }

  ///@notice revokes pool approval for a certain asset. This router will no longer be able to deposit on AAVE Pool
  ///@param token the address of the asset whose approval must be revoked.
  function revokeLenderApproval(IERC20 token) external onlyCaller(aaveManager) {
    _approveLender(token, 0);
  }

  ///@notice prevents AAVE from using a certain asset as collateral for lending
  ///@param token the asset address
  function exitMarket(IERC20 token) external onlyCaller(aaveManager) {
    _exitMarket(token);
  }

  ///@notice re-allows AAVE to use certain assets as collateral for lending
  ///@dev market is automatically entered at first deposit
  ///@param tokens the asset addresses
  function enterMarket(IERC20[] calldata tokens) external onlyCaller(aaveManager) {
    _enterMarkets(tokens);
  }

  ///@notice allows AAVE manager to claim the rewards attributed to this router by AAVE
  ///@param assets the list of overlyings (aToken, debtToken) whose rewards should be claimed
  ///@dev if some rewards are eligible they are sent to `aaveManager`
  ///@return rewardList the addresses of the claimed rewards
  ///@return claimedAmounts the amount of claimed rewards
  function claimRewards(address[] calldata assets)
    external
    onlyCaller(aaveManager)
    returns (address[] memory rewardList, uint[] memory claimedAmounts)
  {
    return _claimRewards(assets, msg.sender);
  }

  ///@notice sets a new AAVE manager
  ///@param aaveManager_ the new address of the AAVE manager
  ///@dev if any reward is active for pure lenders, `aaveManager` will be able to claim them
  function setAaveManager(address aaveManager_) public {
    require(msg.sender == admin() || msg.sender == aaveManager, "AccessControlled/Invalid");
    require(aaveManager_ != address(0), "AavePooledReserve/0xAaveManager");
    aaveManager = aaveManager_;
    emit SetAaveManager(aaveManager_);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "mgv_src/MgvLib.sol";
/**
 * @title IAToken - ish
 * @author Aave
 * @notice Defines the basic interface for an AToken.
 */

interface IATokenIsh is IERC20 {
  /**
   * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @return The address of the underlying asset
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @notice Returns the address of the Aave treasury, receiving the fees on this aToken.
   * @return Address of the Aave treasury
   */
  function RESERVE_TREASURY_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {MgvLib, MgvStructs} from "mgv_src/MgvLib.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/IERC20.sol";
import {OfferType} from "./TradesBaseQuotePair.sol";
import {CoreKandel} from "./CoreKandel.sol";
import {AbstractKandel} from "./AbstractKandel.sol";

///@title Adds a geometric price progression to a `CoreKandel` strat without storing prices for individual price points.
abstract contract GeometricKandel is CoreKandel {
  ///@notice `compoundRateBase`, and `compoundRateQuote` have PRECISION decimals, and ditto for GeometricKandel's `ratio`.
  ///@notice setting PRECISION higher than 5 will produce overflow in limit cases for GeometricKandel.
  uint public constant PRECISION = 5;

  ///@notice the parameters for Geometric Kandel have been set.
  ///@param spread in amount of price slots to jump for posting dual offer
  ///@param ratio of price progression
  event SetGeometricParams(uint spread, uint ratio);

  ///@notice Geometric Kandel parameters
  ///@param gasprice the gasprice to use for offers
  ///@param gasreq the gasreq to use for offers
  ///@param ratio of price progression (`2**16 > ratio >= 10**PRECISION`) expressed with `PRECISION` decimals, so geometric ratio is `ratio/10**PRECISION`
  ///@param compoundRateBase percentage of the spread that is to be compounded for base, expressed with `PRECISION` decimals (`compoundRateBase <= 10**PRECISION`). Real compound rate for base is `compoundRateBase/10**PRECISION`
  ///@param compoundRateQuote percentage of the spread that is to be compounded for quote, expressed with `PRECISION` decimals (`compoundRateQuote <= 10**PRECISION`). Real compound rate for quote is `compoundRateQuote/10**PRECISION`
  ///@param spread in amount of price slots to jump for posting dual offer. Must be less than or equal to 8.
  ///@param pricePoints the number of price points for the Kandel instance.
  struct Params {
    uint16 gasprice;
    uint24 gasreq;
    uint24 ratio; // max ratio is 2*10**5
    uint24 compoundRateBase; // max compoundRate is 10**5
    uint24 compoundRateQuote;
    uint8 spread;
    uint8 pricePoints;
  }

  ///@notice Storage of the parameters for the strat.
  Params public params;

  ///@notice Constructor
  ///@param mgv The Mangrove deployment.
  ///@param base Address of the base token of the market Kandel will act on
  ///@param quote Address of the quote token of the market Kandel will act on
  ///@param gasreq the gasreq to use for offers
  ///@param gasprice the gasprice to use for offers
  ///@param reserveId identifier of this contract's reserve when using a router.
  constructor(IMangrove mgv, IERC20 base, IERC20 quote, uint gasreq, uint gasprice, address reserveId)
    CoreKandel(mgv, base, quote, gasreq, reserveId)
  {
    setGasprice(gasprice);
  }

  /// @inheritdoc AbstractKandel
  function setGasprice(uint gasprice) public override onlyAdmin {
    uint16 gasprice_ = uint16(gasprice);
    require(gasprice_ == gasprice, "Kandel/gaspriceTooHigh");
    params.gasprice = gasprice_;
    emit SetGasprice(gasprice_);
  }

  /// @inheritdoc AbstractKandel
  function setGasreq(uint gasreq) public override onlyAdmin {
    uint24 gasreq_ = uint24(gasreq);
    require(gasreq_ == gasreq, "Kandel/gasreqTooHigh");
    params.gasreq = gasreq_;
    emit SetGasreq(gasreq_);
  }

  /// @notice Updates the params to new values.
  /// @param newParams the new params to set.
  function setParams(Params calldata newParams) internal {
    Params memory oldParams = params;

    if (oldParams.pricePoints != newParams.pricePoints) {
      setLength(newParams.pricePoints);
      params.pricePoints = newParams.pricePoints;
    }

    bool geometricChanged = false;
    if (oldParams.ratio != newParams.ratio) {
      require(newParams.ratio >= 10 ** PRECISION && newParams.ratio <= 2 * 10 ** PRECISION, "Kandel/invalidRatio");
      params.ratio = newParams.ratio;
      geometricChanged = true;
    }
    if (oldParams.spread != newParams.spread) {
      require(newParams.spread > 0 && newParams.spread <= 8, "Kandel/invalidSpread");
      params.spread = newParams.spread;
      geometricChanged = true;
    }

    if (geometricChanged) {
      emit SetGeometricParams(newParams.spread, newParams.ratio);
    }

    if (newParams.gasprice != 0 && newParams.gasprice != oldParams.gasprice) {
      setGasprice(newParams.gasprice);
    }

    if (newParams.gasreq != 0 && newParams.gasreq != oldParams.gasreq) {
      setGasreq(newParams.gasreq);
    }

    if (
      oldParams.compoundRateBase != newParams.compoundRateBase
        || oldParams.compoundRateQuote != newParams.compoundRateQuote
    ) {
      setCompoundRates(newParams.compoundRateBase, newParams.compoundRateQuote);
    }
  }

  /// @inheritdoc AbstractKandel
  function setCompoundRates(uint compoundRateBase, uint compoundRateQuote) public override onlyAdmin {
    require(compoundRateBase <= 10 ** PRECISION, "Kandel/invalidCompoundRateBase");
    require(compoundRateQuote <= 10 ** PRECISION, "Kandel/invalidCompoundRateQuote");
    emit SetCompoundRates(compoundRateBase, compoundRateQuote);
    params.compoundRateBase = uint24(compoundRateBase);
    params.compoundRateQuote = uint24(compoundRateQuote);
  }

  /// @notice Gets the compound rate for the given offer type.
  /// @param baDual the dual offer type.
  /// @param memoryParams the Kandel params.
  /// @return compoundRate to use for the gives of the offer type. Asks give base so this would be the `compoundRateBase`, and vice versa.
  function compoundRateForDual(OfferType baDual, Params memory memoryParams) private pure returns (uint compoundRate) {
    compoundRate = uint(baDual == OfferType.Ask ? memoryParams.compoundRateBase : memoryParams.compoundRateQuote);
  }

  ///@notice publishes bids/asks for the distribution in the `indices`. Caller should follow the desired distribution in `baseDist` and `quoteDist`.
  ///@param distribution the distribution of base and quote for Kandel indices
  ///@param pivotIds the pivot to be used for the offer
  ///@param firstAskIndex the (inclusive) index after which offer should be an ask.
  ///@param parameters the parameters for Kandel. Only changed parameters will cause updates. Set `gasreq` and `gasprice` to 0 to keep existing values.
  ///@param baseAmount base amount to deposit
  ///@param quoteAmount quote amount to deposit
  ///@dev This function is used at initialization and can fund with provision for the offers.
  ///@dev Use `populateChunk` to split up initialization or re-initialization with same parameters, as this function will emit.
  ///@dev If this function is invoked with different ratio, pricePoints, spread, then first retract all offers.
  ///@dev msg.value must be enough to provision all posted offers (for chunked initialization only one call needs to send native tokens).
  function populate(
    Distribution calldata distribution,
    uint[] calldata pivotIds,
    uint firstAskIndex,
    Params calldata parameters,
    uint baseAmount,
    uint quoteAmount
  ) external payable onlyAdmin {
    if (msg.value > 0) {
      MGV.fund{value: msg.value}();
    }
    setParams(parameters);

    depositFunds(baseAmount, quoteAmount);

    populateChunkInternal(distribution, pivotIds, firstAskIndex);
  }

  ///@notice Publishes bids/asks for the distribution in the `indices`. Caller should follow the desired distribution in `baseDist` and `quoteDist`.
  ///@dev internal version does not check onlyAdmin
  ///@param distribution the distribution of base and quote for Kandel indices
  ///@param pivotIds the pivot to be used for the offer
  ///@param firstAskIndex the (inclusive) index after which offer should be an ask.
  function populateChunkInternal(Distribution calldata distribution, uint[] calldata pivotIds, uint firstAskIndex)
    internal
  {
    populateChunk(distribution, pivotIds, firstAskIndex, params.gasreq, params.gasprice);
  }

  ///@notice Publishes bids/asks for the distribution in the `indices`. Caller should follow the desired distribution in `baseDist` and `quoteDist`.
  ///@notice This function is used publicly after `populate` to reinitialize some indices or if multiple transactions are needed to split initialization due to gas cost.
  ///@notice This function is not payable, use `populate` to fund along with populate.
  ///@param distribution the distribution of base and quote for Kandel indices.
  ///@param pivotIds the pivot to be used for the offer.
  ///@param firstAskIndex the (inclusive) index after which offer should be an ask.
  function populateChunk(Distribution calldata distribution, uint[] calldata pivotIds, uint firstAskIndex)
    external
    onlyAdmin
  {
    populateChunk(distribution, pivotIds, firstAskIndex, params.gasreq, params.gasprice);
  }

  ///@notice calculates the wants and gives for the dual offer according to the geometric price distribution.
  ///@param baDual the dual offer type.
  ///@param dualOfferGives the dual offer's current gives (can be 0)
  ///@param order a recap of the taker order (order.offer is the executed offer)
  ///@param memoryParams the Kandel params (possibly with modified spread due to boundary condition)
  ///@return wants the new wants for the dual offer
  ///@return gives the new gives for the dual offer
  ///@dev Define the (maker) price of the order as `p_order := order.offer.wants() / order.offer.gives()` (what the offer originally wants by what the offer originally gives).
  /// the (maker) price of the dual order must be `p_dual := p_order / ratio^spread` at which one should buy back at least what was sold.
  /// thus `min_offer_wants := order.wants` at price `p_dual`
  /// with `min_offer_gives / min_offer_wants = p_dual` we derive `min_offer_gives = order.gives/ratio^spread`.
  /// Now at maximal compounding, maker wants to give all what taker gave. That is `max_offer_gives := order.gives`
  /// So with compound rate we have:
  /// `offer_gives := min_offer_gives + (max_offer_gives - min_offer_gives) * compoundRate`.
  /// and we derive the formula:
  /// `offer_gives = order.gives * ( 1/ratio^spread + (1 - 1/ratio^spread) * compoundRate)`
  /// which we use in the code below where we also account for existing gives of the dual offer.
  function dualWantsGivesOfOffer(
    OfferType baDual,
    uint dualOfferGives,
    MgvLib.SingleOrder calldata order,
    Params memory memoryParams
  ) internal pure returns (uint wants, uint gives) {
    // computing gives/wants for dual offer
    // we verify we cannot overflow if PRECISION = 5
    // spread:8
    uint spread = uint(memoryParams.spread);
    // compoundRate <= 10**PRECISION hence compoundRate:PRECISION*log2(10)
    uint compoundRate = compoundRateForDual(baDual, memoryParams);
    // params.ratio <= 2*10**PRECISION, spread:8, r: 8 * (PRECISION*log2(10) + 1)
    uint r = uint(memoryParams.ratio) ** spread;
    uint p = 10 ** PRECISION;
    // order.gives:96
    // p ~ compoundRate : log2(10) * PRECISION
    // p ** spread : 8 * log2(10) * PRECISION
    // (p - compoundRate) * p ** spread : 9 * log2(10) * PRECISION (=150 for PRECISION = 5)
    // compoundRate * r : PRECISION*log2(10) + 8 * (PRECISION*log2(10) + 1) (=157 for PRECISION = 5)
    // 157 + 96 < 256
    gives = (order.gives * ((p - compoundRate) * p ** spread + compoundRate * r)) / (r * p);

    // adding to gives what the offer was already giving so gives could be greater than 2**96
    // gives:97
    gives += dualOfferGives;
    if (uint96(gives) != gives) {
      // this should not be reached under normal circumstances unless strat is posting on top of an existing offer with an abnormal volume
      // to prevent gives to be too high, we let the surplus be pending
      gives = type(uint96).max;
    }
    // adjusting wants to price:
    // gives * r : 237 so offerGives must be < 2**19 to completely avoid overflow.
    // Since offerGives is high when gives * r is, we check whether the full precision can be used and only if not then we use less precision.
    uint givesR = gives * r;
    uint offerGives = order.offer.gives();
    if (uint160(givesR) == givesR || offerGives < 2 ** 19) {
      // using max precision
      wants = (offerGives * givesR) / (order.offer.wants() * (p ** spread));
    } else {
      // we divide `gives*r` by `order.offer.wants()` with max precision so that the resulting `givesR:160` in order to make sure it can be multiplied by `offerGives`
      givesR = (givesR * 2 ** 19) / order.offer.wants();
      wants = (offerGives * givesR) / (p ** spread);
      // we correct for the added precision above
      wants /= 2 ** 19;
    }
    // wants is higher than offerGives
    // this may cause wants to be higher than 2**96 allowed by Mangrove (for instance if one needs many quotes to buy sell base tokens)
    // so we adjust the price so as to want an amount of tokens that mangrove will accept.
    if (uint96(wants) != wants) {
      gives = (type(uint96).max * gives) / wants;
      wants = type(uint96).max;
    }
  }

  ///@notice returns the destination index to transport received liquidity to - a better (for Kandel) price index for the offer type.
  ///@param ba the offer type to transport to
  ///@param index the price index one is willing to improve
  ///@param step the number of price steps improvements
  ///@param pricePoints the number of price points
  ///@return better destination index
  ///@return spread the size of the price jump, which is `step` if the index boundaries were not reached
  function transportDestination(OfferType ba, uint index, uint step, uint pricePoints)
    internal
    pure
    returns (uint better, uint8 spread)
  {
    if (ba == OfferType.Ask) {
      better = index + step;
      if (better >= pricePoints) {
        better = pricePoints - 1;
        spread = uint8(better - index);
      } else {
        spread = uint8(step);
      }
    } else {
      if (index >= step) {
        better = index - step;
        spread = uint8(step);
      } else {
        // else better = 0
        spread = uint8(index - better);
      }
    }
  }

  ///@inheritdoc CoreKandel
  function transportLogic(OfferType ba, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (OfferType baDual, uint dualOfferId, uint dualIndex, OfferArgs memory args)
  {
    uint index = indexOfOfferId(ba, order.offerId);
    Params memory memoryParams = params;
    baDual = dual(ba);

    // because of boundaries, actual spread might be lower than the one loaded in memoryParams
    // this would result populating a price index at a wrong price (too high for an Ask and too low for a Bid)
    (dualIndex, memoryParams.spread) =
      transportDestination(baDual, index, memoryParams.spread, memoryParams.pricePoints);

    dualOfferId = offerIdOfIndex(baDual, dualIndex);
    (IERC20 outbound, IERC20 inbound) = tokenPairOfOfferType(baDual);
    args.outbound_tkn = outbound;
    args.inbound_tkn = inbound;
    MgvStructs.OfferPacked dualOffer = MGV.offers(address(outbound), address(inbound), dualOfferId);

    // computing gives/wants for dual offer
    // At least: gives = order.gives/ratio and wants is then order.wants
    // At most: gives = order.gives and wants is adapted to match the price
    (args.wants, args.gives) = dualWantsGivesOfOffer(baDual, dualOffer.gives(), order, memoryParams);

    // args.fund = 0; the offers are already provisioned
    // posthook should not fail if unable to post offers, we capture the error as incidents
    args.noRevert = true;
    args.gasprice = memoryParams.gasprice;
    args.gasreq = memoryParams.gasreq;
    args.pivotId = dualOffer.gives() > 0 ? dualOffer.next() : 0;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {IERC20} from "mgv_src/IERC20.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {OfferType} from "./TradesBaseQuotePair.sol";

///@title Core external functions and events for Kandel strats.
abstract contract AbstractKandel {
  ///@notice the compound rates have been set to `compoundRateBase` and `compoundRateQuote` which will take effect for future compounding.
  ///@param compoundRateBase the compound rate for base.
  ///@param compoundRateQuote the compound rate for quote.
  event SetCompoundRates(uint compoundRateBase, uint compoundRateQuote);

  ///@notice the gasprice has been set.
  ///@param value the gasprice for offers.
  event SetGasprice(uint value);

  ///@notice the gasreq has been set.
  ///@param value the gasreq (including router's gasreq) for offers
  event SetGasreq(uint value);

  ///@notice the Kandel instance is credited of `amount` by its owner.
  ///@param token the asset.
  ///@param amount the amount.
  event Credit(IERC20 indexed token, uint amount);

  ///@notice the Kandel instance is debited of `amount` by its owner.
  ///@param token the asset.
  ///@param amount the amount.
  event Debit(IERC20 indexed token, uint amount);

  ///@notice the amount of liquidity that is available for the strat but not offered by the given offer type.
  ///@param ba the offer type.
  ///@return the amount of pending liquidity. Will be negative if more is offered than is available on the reserve balance.
  ///@dev Pending could be withdrawn or invested by increasing offered volume.
  function pending(OfferType ba) external view virtual returns (int);

  ///@notice the total balance available for the strat of the offered token for the given offer type.
  ///@param ba the offer type.
  ///@return balance the balance of the token.
  function reserveBalance(OfferType ba) public view virtual returns (uint balance);

  ///@notice deposits funds to be available for being offered. Will increase `pending`.
  ///@param baseAmount the amount of base tokens to deposit.
  ///@param quoteAmount the amount of quote tokens to deposit.
  function depositFunds(uint baseAmount, uint quoteAmount) public virtual;

  ///@notice withdraws the amounts of the given tokens to the recipient.
  ///@param baseAmount the amount of base tokens to withdraw.
  ///@param quoteAmount the amount of quote tokens to withdraw.
  ///@param recipient the recipient of the funds.
  ///@dev it is up to the caller to make sure there are still enough funds for live offers.
  function withdrawFunds(uint baseAmount, uint quoteAmount, address recipient) public virtual;

  ///@notice set the compound rates. It will take effect for future compounding.
  ///@param compoundRateBase the compound rate for base.
  ///@param compoundRateQuote the compound rate for quote.
  ///@dev For low compound rates Kandel can end up with everything as pending and nothing offered.
  ///@dev To avoid this, then for equal compound rates `C` then $C >= 1/(sqrt(ratio^spread)+1)$.
  ///@dev With one rate being 0 and the other 1 the amount earned from the spread will accumulate as pending
  ///@dev for the token at 0 compounding and the offered volume will stay roughly static (modulo rounding).
  function setCompoundRates(uint compoundRateBase, uint compoundRateQuote) public virtual;

  ///@notice sets the gasprice for offers
  ///@param gasprice the gasprice.
  function setGasprice(uint gasprice) public virtual;

  ///@notice sets the gasreq (including router's gasreq) for offers
  ///@param gasreq the gasreq.
  function setGasreq(uint gasreq) public virtual;
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {MgvLib} from "mgv_src/MgvLib.sol";
import {IERC20} from "mgv_src/IERC20.sol";

///@title a bid or an ask.
enum OfferType {
  Bid,
  Ask
}

///@title Interface contract for strats needing offer type to token pair mapping.
abstract contract IHasTokenPairOfOfferType {
  ///@notice turns an offer type into an (outbound, inbound) pair identifying an offer list.
  ///@param ba whether one wishes to access the offer lists where asks or bids are posted.
  ///@return pair the token pair
  function tokenPairOfOfferType(OfferType ba) internal view virtual returns (IERC20, IERC20 pair);

  ///@notice returns the offer type of the offer list whose outbound token is given in the argument.
  ///@param outbound_tkn the outbound token of the offer list.
  ///@return ba the offer type
  function offerTypeOfOutbound(IERC20 outbound_tkn) internal view virtual returns (OfferType ba);

  ///@notice returns the outbound token for the offer type
  ///@param ba the offer type
  ///@return token the outbound token
  function outboundOfOfferType(OfferType ba) internal view virtual returns (IERC20 token);
}

///@title Adds basic base/quote trading pair for bids and asks and couples it to Mangrove's gives, wants, outbound, inbound terminology.
///@dev Implements the IHasTokenPairOfOfferType interface contract.
abstract contract TradesBaseQuotePair is IHasTokenPairOfOfferType {
  ///@notice base of the market Kandel is making
  IERC20 public immutable BASE;
  ///@notice quote of the market Kandel is making
  IERC20 public immutable QUOTE;

  ///@notice The traded pair
  ///@param base of the market Kandel is making
  ///@param quote of the market Kandel is making
  event Pair(IERC20 base, IERC20 quote);

  ///@notice Constructor
  ///@param base Address of the base token of the market Kandel will act on
  ///@param quote Address of the quote token of the market Kandel will act on
  constructor(IERC20 base, IERC20 quote) {
    BASE = base;
    QUOTE = quote;
    emit Pair(base, quote);
  }

  ///@inheritdoc IHasTokenPairOfOfferType
  function tokenPairOfOfferType(OfferType ba) internal view override returns (IERC20, IERC20) {
    return ba == OfferType.Bid ? (QUOTE, BASE) : (BASE, QUOTE);
  }

  ///@inheritdoc IHasTokenPairOfOfferType
  function offerTypeOfOutbound(IERC20 outbound_tkn) internal view override returns (OfferType) {
    return outbound_tkn == BASE ? OfferType.Ask : OfferType.Bid;
  }

  ///@inheritdoc IHasTokenPairOfOfferType
  function outboundOfOfferType(OfferType ba) internal view override returns (IERC20 token) {
    token = ba == OfferType.Ask ? BASE : QUOTE;
  }

  ///@notice returns the dual offer type
  ///@param ba whether the offer is an ask or a bid
  ///@return baDual is the dual offer type (ask for bid and conversely)
  function dual(OfferType ba) internal pure returns (OfferType baDual) {
    return OfferType((uint(ba) + 1) % 2);
  }
}

// SPDX-License-Identifier: Unlicense
// This file was manually adapted from a file generated by abi-to-sol. It must
// be kept up-to-date with the actual Mangrove interface. Fully automatic
// generation is not yet possible due to user-generated types in the external
// interface lost in the abi generation.

pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

import {MgvLib, MgvStructs, IMaker} from "./MgvLib.sol";

interface IMangrove {
  event Approval(address indexed outbound_tkn, address indexed inbound_tkn, address owner, address spender, uint value);
  event Credit(address indexed maker, uint amount);
  event Debit(address indexed maker, uint amount);
  event Kill();
  event NewMgv();
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    address taker,
    uint takerWants,
    uint takerGives,
    bytes32 mgvData
  );
  event OfferRetract(address indexed outbound_tkn, address indexed inbound_tkn, uint id, bool deprovision);
  event OfferSuccess(
    address indexed outbound_tkn, address indexed inbound_tkn, uint id, address taker, uint takerWants, uint takerGives
  );
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address indexed taker,
    uint takerGot,
    uint takerGave,
    uint penalty,
    uint feePaid
  );
  event OrderStart();
  event PosthookFail(address indexed outbound_tkn, address indexed inbound_tkn, uint offerId, bytes32 posthookData);
  event SetActive(address indexed outbound_tkn, address indexed inbound_tkn, bool value);
  event SetDensity(address indexed outbound_tkn, address indexed inbound_tkn, uint value);
  event SetFee(address indexed outbound_tkn, address indexed inbound_tkn, uint value);
  event SetGasbase(address indexed outbound_tkn, address indexed inbound_tkn, uint offer_gasbase);
  event SetGasmax(uint value);
  event SetGasprice(uint value);
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetNotify(bool value);
  event SetUseOracle(bool value);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function withdrawERC20(address tokenAddress, uint value) external;
  function activate(address outbound_tkn, address inbound_tkn, uint fee, uint density, uint offer_gasbase) external;

  function allowances(address, address, address, address) external view returns (uint);

  function approve(address outbound_tkn, address inbound_tkn, address spender, uint value) external returns (bool);

  function balanceOf(address) external view returns (uint);

  function best(address outbound_tkn, address inbound_tkn) external view returns (uint);

  function config(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (MgvStructs.GlobalPacked, MgvStructs.LocalPacked);

  function configInfo(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (MgvStructs.GlobalUnpacked memory global, MgvStructs.LocalUnpacked memory local);

  function deactivate(address outbound_tkn, address inbound_tkn) external;

  function flashloan(MgvLib.SingleOrder memory sor, address taker) external returns (uint gasused, bytes32 makerData);

  function fund(address maker) external payable;

  function fund() external payable;

  function governance() external view returns (address);

  function isLive(MgvStructs.OfferPacked offer) external pure returns (bool);

  function kill() external;

  function locked(address outbound_tkn, address inbound_tkn) external view returns (bool);

  function marketOrder(address outbound_tkn, address inbound_tkn, uint takerWants, uint takerGives, bool fillWants)
    external
    returns (uint takerGot, uint takerGave, uint bounty, uint fee);

  function marketOrderFor(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  ) external returns (uint takerGot, uint takerGave, uint bounty, uint fee);

  function newOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) external payable returns (uint);

  function nonces(address) external view returns (uint);

  function offerDetails(address, address, uint) external view returns (MgvStructs.OfferDetailPacked);

  function offerInfo(address outbound_tkn, address inbound_tkn, uint offerId)
    external
    view
    returns (MgvStructs.OfferUnpacked memory offer, MgvStructs.OfferDetailUnpacked memory offerDetail);

  function offers(address, address, uint) external view returns (MgvStructs.OfferPacked);

  function permit(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function retractOffer(address outbound_tkn, address inbound_tkn, uint offerId, bool deprovision)
    external
    returns (uint provision);

  function setDensity(address outbound_tkn, address inbound_tkn, uint density) external;

  function setFee(address outbound_tkn, address inbound_tkn, uint fee) external;

  function setGasbase(address outbound_tkn, address inbound_tkn, uint offer_gasbase) external;

  function setGasmax(uint gasmax) external;

  function setGasprice(uint gasprice) external;

  function setGovernance(address governanceAddress) external;

  function setMonitor(address monitor) external;

  function setNotify(bool notify) external;

  function setUseOracle(bool useOracle) external;

  function snipes(address outbound_tkn, address inbound_tkn, uint[4][] memory targets, bool fillWants)
    external
    returns (uint successes, uint takerGot, uint takerGave, uint bounty, uint fee);

  function snipesFor(address outbound_tkn, address inbound_tkn, uint[4][] memory targets, bool fillWants, address taker)
    external
    returns (uint successes, uint takerGot, uint takerGave, uint bounty, uint fee);

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable;

  function withdraw(uint amount) external returns (bool noRevert);

  receive() external payable;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  function symbol() external view returns (string memory);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  function decimals() external view returns (uint8);

  function name() external view returns (string memory);
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

/// @title This contract is used to restrict access to privileged functions of inheriting contracts through modifiers.
/// @notice The contract stores an admin address which is checked against `msg.sender` in the `onlyAdmin` modifier.
/// @notice Additionally, a specific `msg.sender` can be verified with the `onlyCaller` modifier.
contract AccessControlled {
  /**
   * @notice logs new `admin` of `this`
   * @param admin The new admin.
   */
  event SetAdmin(address admin);
  /**
   * @notice The admin address.
   */

  address internal _admin;

  /**
   * @notice `AccessControlled`'s constructor
   * @param admin_ The address of the admin that can access privileged functions and also allowed to change the admin. Cannot be `address(0)`.
   */
  constructor(address admin_) {
    require(admin_ != address(0), "AccessControlled/0xAdmin");
    _admin = admin_;
  }

  /**
   * @notice This modifier verifies that `msg.sender` is the admin.
   */
  modifier onlyAdmin() {
    require(msg.sender == _admin, "AccessControlled/Invalid");
    _;
  }

  /**
   * @notice This modifier verifies that `msg.sender` is the caller.
   * @param caller The address of the caller that can access the modified function.
   */
  modifier onlyCaller(address caller) {
    require(msg.sender == caller, "AccessControlled/Invalid");
    _;
  }

  /**
   * @notice This modifier verifies that `msg.sender` is either caller or the admin
   * @param caller The address of a caller that can access the modified function.
   */
  modifier adminOrCaller(address caller) {
    // test _admin second to save a storage read when possible
    require(msg.sender == caller || msg.sender == _admin, "AccessControlled/Invalid");
    _;
  }

  /**
   * @notice Retrieves the current admin.
   * @return current admin.
   */
  function admin() public view returns (address current) {
    return _admin;
  }

  /**
   * @notice This sets the admin. Only the current admin can change the admin.
   * @param admin_ The new admin. Cannot be `address(0)`.
   */
  function setAdmin(address admin_) public onlyAdmin {
    require(admin_ != address(0), "AccessControlled/0xAdmin");
    _admin = admin_;
    emit SetAdmin(admin_);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity >=0.8.10;

import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20, IMaker} from "mgv_src/MgvLib.sol";
import {AbstractRouter} from "mgv_src/strategies/routers/AbstractRouter.sol";

///@title IOfferLogic interface for offer management
///@notice It is an IMaker for Mangrove.

interface IOfferLogic is IMaker {
  ///@notice Log incident (during post trade execution)
  ///@param mangrove The mangrove deployment.
  ///@param outbound_tkn the outbound token of the offer list.
  ///@param inbound_tkn the inbound token of the offer list.
  ///@param offerId the Mangrove offer id.
  ///@param makerData from the maker.
  ///@param mgvData from Mangrove.
  event LogIncident(
    IMangrove mangrove,
    IERC20 indexed outbound_tkn,
    IERC20 indexed inbound_tkn,
    uint indexed offerId,
    bytes32 makerData,
    bytes32 mgvData
  );

  ///@notice Logging change of router address
  ///@param router the new router address
  event SetRouter(AbstractRouter router);

  ///@notice Actual gas requirement when posting offers via this strategy. Returned value may change if this contract's router is updated.
  ///@return total gas cost including router specific costs (if any).
  function offerGasreq() external view returns (uint total);

  ///@notice sets a new router to pull outbound tokens from contract's reserve to `this` and push inbound tokens to reserve.
  ///@param router_ the new router contract that this contract should use. Use `NO_ROUTER` for no router.
  ///@dev new router needs to be approved by `this` to push funds to reserve (see `activate` function). It also needs to be approved by reserve to pull from it.
  function setRouter(AbstractRouter router_) external;

  ///@notice Approves a spender to transfer a certain amount of tokens on behalf of `this`.
  ///@param token the ERC20 token contract
  ///@param spender the approved spender
  ///@param amount the spending amount
  ///@return result of token approval.
  ///@dev admin may use this function to revoke specific approvals of `this` that are set after a call to `activate`.
  function approve(IERC20 token, address spender, uint amount) external returns (bool);

  ///@notice computes the amount of native tokens that can be redeemed when deprovisioning a given offer.
  ///@param outbound_tkn the outbound token of the offer list
  ///@param inbound_tkn the inbound token of the offer list
  ///@param offerId the identifier of the offer in the offer list
  ///@return provision the amount of native tokens that can be redeemed when deprovisioning the offer
  function provisionOf(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId) external view returns (uint provision);

  ///@notice verifies that this contract's current state is ready to be used to post offers on Mangrove
  ///@param tokens the list of tokens that are traded by this contract
  ///@dev throws with a reason if something (e.g. an approval) is missing.
  function checkList(IERC20[] calldata tokens) external view;

  /// @notice performs the required approvals so as to allow `this` to interact with Mangrove on a set of assets.
  /// @param tokens the ERC20 `this` will approve to be able to trade on Mangrove's corresponding markets.
  function activate(IERC20[] calldata tokens) external;

  ///@notice withdraws native tokens from `this` balance on Mangrove.
  ///@param amount the amount of WEI one wishes to withdraw.
  ///@param receiver the address of the receiver of the funds.
  ///@dev Since a call is made to the `receiver`, this function is subject to reentrancy.
  function withdrawFromMangrove(uint amount, address payable receiver) external;

  ///@notice Memory allocation for `_new/updateOffer`'s arguments.
  ///@param outbound_tkn outbound token of the offer list.
  ///@param inbound_tkn inbound token of the offer list.
  ///@param wants the amount of inbound tokens the maker wants for a complete fill.
  ///@param gives the amount of outbound tokens the maker gives for a complete fill.
  ///@param gasreq the amount of gas units that are required to execute the trade
  ///@param gasprice the gasprice used to compute offer's provision (use 0 to use Mangrove's gasprice)
  ///@param pivotId a best pivot estimate for cheap offer insertion in the offer list.
  ///@param fund WEIs in `this` contract's balance that are used to provision the offer.
  ///@param noRevert is set to true if calling function does not wish `_newOffer` to revert on error.
  ///@param owner the offer maker managing the offer.
  ///@dev `owner` is required in `Forwarder` logics, when `_newOffer` or `_updateOffer` in called in a hook (`msg.sender==MGV`).
  struct OfferArgs {
    IERC20 outbound_tkn;
    IERC20 inbound_tkn;
    uint wants;
    uint gives;
    uint gasreq;
    uint gasprice;
    uint pivotId;
    uint fund;
    bool noRevert;
  }

  /// @notice Contract's router getter.
  /// @return the router.
  /// @dev if contract has a no router, function returns `NO_ROUTER`.
  function router() external view returns (AbstractRouter);

  /// @notice Contract's Mangrove getter
  /// @return the Mangrove contract.
  function MGV() external view returns (IMangrove);
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {AccessControlled} from "mgv_src/strategies/utils/AccessControlled.sol";
import {IERC20} from "mgv_src/MgvLib.sol";

/// @title AbstractRouter
/// @notice Partial implementation and requirements for liquidity routers.

abstract contract AbstractRouter is AccessControlled {
  ///@notice the amount of gas that is required for this router to be able to perform a `pull` and a `push`.
  uint24 internal immutable ROUTER_GASREQ;
  ///@notice the bound maker contracts which are allowed to call this router.
  mapping(address => bool) internal boundMakerContracts;

  ///@notice This modifier verifies that `msg.sender` an allowed caller of this router.
  modifier onlyBound() {
    require(isBound(msg.sender), "AccessControlled/Invalid");
    _;
  }

  ///@notice This modifier verifies that `msg.sender` is the admin or an allowed caller of this router.
  modifier boundOrAdmin() {
    require(msg.sender == admin() || isBound(msg.sender), "AccessControlled/Invalid");
    _;
  }

  ///@notice logging bound maker contract
  ///@param maker the maker address
  event MakerBind(address indexed maker);

  ///@notice logging unbound maker contract
  ///@param maker the maker address
  event MakerUnbind(address indexed maker);

  ///@notice constructor for abstract routers.
  ///@param routerGasreq_ is the amount of gas that is required for this router to be able to perform a `pull` and a `push`.
  constructor(uint routerGasreq_) AccessControlled(msg.sender) {
    require(uint24(routerGasreq_) == routerGasreq_, "Router/gasreqTooHigh");
    ROUTER_GASREQ = uint24(routerGasreq_);
  }

  ///@notice getter for the `makers: addr => bool` mapping
  ///@param mkr the address of a maker contract
  ///@return true if `mkr` is authorized to call this router.
  function isBound(address mkr) public view returns (bool) {
    return boundMakerContracts[mkr];
  }

  ///@notice view for gas overhead of this router.
  ///@return overhead the added (overapproximated) gas cost of `push` and `pull`.
  function routerGasreq() public view returns (uint overhead) {
    return ROUTER_GASREQ;
  }

  ///@notice pulls liquidity from the reserve and sends it to the calling maker contract.
  ///@param token is the ERC20 managing the pulled asset
  ///@param reserveId identifies the fund owner (router implementation dependent).
  ///@param amount of `token` the maker contract wishes to pull from its reserve
  ///@param strict when the calling maker contract accepts to receive more funds from reserve than required (this may happen for gas optimization)
  ///@return pulled the amount that was successfully pulled.
  function pull(IERC20 token, address reserveId, uint amount, bool strict) external onlyBound returns (uint pulled) {
    if (strict && amount == 0) {
      return 0;
    }
    pulled = __pull__({token: token, reserveId: reserveId, amount: amount, strict: strict});
  }

  ///@notice router-dependent implementation of the `pull` function
  ///@param token Token to be transferred
  ///@param reserveId determines the location of the reserve (router implementation dependent).
  ///@param amount The amount of tokens to be transferred
  ///@param strict wether the caller maker contract wishes to pull at most `amount` tokens of owner.
  ///@return pulled The amount pulled if successful; otherwise, 0.
  function __pull__(IERC20 token, address reserveId, uint amount, bool strict) internal virtual returns (uint);

  ///@notice pushes assets from calling's maker contract to a reserve
  ///@param token is the asset the maker is pushing
  ///@param reserveId determines the location of the reserve (router implementation dependent).
  ///@param amount is the amount of asset that should be transferred from the calling maker contract
  ///@return pushed fraction of `amount` that was successfully pushed to reserve.
  function push(IERC20 token, address reserveId, uint amount) external onlyBound returns (uint pushed) {
    if (amount == 0) {
      return 0;
    }
    pushed = __push__({token: token, reserveId: reserveId, amount: amount});
  }

  ///@notice router-dependent implementation of the `push` function
  ///@param token Token to be transferred
  ///@param reserveId determines the location of the reserve (router implementation dependent).
  ///@param amount The amount of tokens to be transferred
  ///@return pushed The amount pushed if successful; otherwise, 0.
  function __push__(IERC20 token, address reserveId, uint amount) internal virtual returns (uint pushed);

  ///@notice iterative `push` for the whole balance in a single call
  ///@param tokens to flush
  ///@param reserveId determines the location of the reserve (router implementation dependent).
  function flush(IERC20[] calldata tokens, address reserveId) external onlyBound {
    for (uint i = 0; i < tokens.length; ++i) {
      uint amount = tokens[i].balanceOf(msg.sender);
      if (amount > 0) {
        require(__push__(tokens[i], reserveId, amount) == amount, "router/pushFailed");
      }
    }
  }

  ///@notice adds a maker contract address to the allowed makers of this router
  ///@dev this function is callable by router's admin to bootstrap, but later on an allowed maker contract can add another address
  ///@param makerContract the maker contract address
  function bind(address makerContract) public onlyAdmin {
    boundMakerContracts[makerContract] = true;
    emit MakerBind(makerContract);
  }

  ///@notice removes a maker contract address from the allowed makers of this router
  ///@param makerContract the maker contract address
  function _unbind(address makerContract) internal {
    boundMakerContracts[makerContract] = false;
    emit MakerUnbind(makerContract);
  }

  ///@notice removes `msg.sender` from the allowed makers of this router
  function unbind() external onlyBound {
    _unbind(msg.sender);
  }

  ///@notice removes a makerContract from the allowed makers of this router
  ///@param makerContract the maker contract address
  function unbind(address makerContract) external onlyAdmin {
    _unbind(makerContract);
  }

  ///@notice allows a makerContract to verify it is ready to use `this` router for a particular reserve
  ///@dev `checkList` returns normally if all needed approval are strictly positive. It reverts otherwise with a reason.
  ///@param token is the asset (and possibly its overlyings) whose approval must be checked
  ///@param reserveId of the tokens that are being pulled
  function checkList(IERC20 token, address reserveId) external view {
    require(isBound(msg.sender), "Router/callerIsNotBoundToRouter");
    // checking maker contract has approved this for token transfer (in order to push to reserve)
    require(token.allowance(msg.sender, address(this)) > 0, "Router/NotApprovedByMakerContract");
    // pulling on behalf of `reserveId` might require a special approval (e.g if `reserveId` is some account on a protocol).
    __checkList__(token, reserveId);
  }

  ///@notice router-dependent additional checks
  ///@param token is the asset (and possibly its overlyings) whose approval must be checked
  ///@param reserveId of the tokens that are being pulled
  function __checkList__(IERC20 token, address reserveId) internal view virtual;

  ///@notice performs necessary approval to activate router function on a particular asset
  ///@param token the asset one wishes to use the router for
  function activate(IERC20 token) external boundOrAdmin {
    __activate__(token);
  }

  ///@notice router-dependent implementation of the `activate` function
  ///@param token the asset one wishes to use the router for
  function __activate__(IERC20 token) internal virtual {
    token; //ssh
  }

  ///@notice Balance of a reserve
  ///@param token the asset one wishes to know the balance of
  ///@param reserveId the identifier of the reserve
  ///@return the balance of the reserve
  function balanceOfReserve(IERC20 token, address reserveId) public view virtual returns (uint);
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {IERC20} from "mgv_src/MgvLib.sol";

///@title This library helps with safely interacting with ERC20 tokens
///@notice Transferring 0 or to self will be skipped.
///@notice ERC20 tokens returning bool instead of reverting are handled.
library TransferLib {
  ///@notice This transfer amount of token to recipient address
  ///@param token Token to be transferred
  ///@param recipient Address of the recipient the tokens will be transferred to
  ///@param amount The amount of tokens to be transferred
  ///@return true if transfer was successful; otherwise, false.
  function transferToken(IERC20 token, address recipient, uint amount) internal returns (bool) {
    if (amount == 0) {
      return true;
    }
    if (recipient == address(this)) {
      return token.balanceOf(recipient) >= amount;
    }
    return _transferToken(token, recipient, amount);
  }

  ///@notice This transfer amount of token to recipient address
  ///@param token Token to be transferred
  ///@param recipient Address of the recipient the tokens will be transferred to
  ///@param amount The amount of tokens to be transferred
  ///@return true if transfer was successful; otherwise, false.
  function _transferToken(IERC20 token, address recipient, uint amount) private returns (bool) {
    // This low level call will not revert but instead return success=false if callee reverts, so we
    // verify that it does not revert by checking success, but we also have to check
    // the returned data if any since some ERC20 tokens to not strictly follow the standard of reverting
    // but instead return false.
    (bool success, bytes memory data) =
      address(token).call(abi.encodeWithSelector(token.transfer.selector, recipient, amount));
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }

  ///@notice This transfer amount of token to recipient address from spender address
  ///@param token Token to be transferred
  ///@param spender Address of the spender, where the tokens will be transferred from
  ///@param recipient Address of the recipient, where the tokens will be transferred to
  ///@param amount The amount of tokens to be transferred
  ///@return true if transfer was successful; otherwise, false.
  function transferTokenFrom(IERC20 token, address spender, address recipient, uint amount) internal returns (bool) {
    if (amount == 0) {
      return true;
    }
    if (spender == recipient) {
      return token.balanceOf(spender) >= amount;
    }
    // optimization to avoid requiring contract to approve itself
    if (spender == address(this)) {
      return _transferToken(token, recipient, amount);
    }
    return _transferTokenFrom(token, spender, recipient, amount);
  }

  ///@notice This transfer amount of token to recipient address from spender address
  ///@param token Token to be transferred
  ///@param spender Address of the spender, where the tokens will be transferred from
  ///@param recipient Address of the recipient, where the tokens will be transferred to
  ///@param amount The amount of tokens to be transferred
  ///@return true if transfer was successful; otherwise, false.
  function _transferTokenFrom(IERC20 token, address spender, address recipient, uint amount) private returns (bool) {
    // This low level call will not revert but instead return success=false if callee reverts, so we
    // verify that it does not revert by checking success, but we also have to check
    // the returned data if there since some ERC20 tokens to not strictly follow the standard of reverting
    // but instead return false.
    (bool success, bytes memory data) =
      address(token).call(abi.encodeWithSelector(token.transferFrom.selector, spender, recipient, amount));
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }

  ///@notice ERC20 approval, handling non standard approvals that do not return a value
  ///@param token the ERC20
  ///@param spender the address whose allowance is to be given
  ///@param amount of the allowance
  ///@return true if approval was successful; otherwise, false.
  function _approveToken(IERC20 token, address spender, uint amount) private returns (bool) {
    // This low level call will not revert but instead return success=false if callee reverts, so we
    // verify that it does not revert by checking success, but we also have to check
    // the returned data if any since some ERC20 tokens to not strictly follow the standard of reverting
    // but instead return false.
    (bool success, bytes memory data) =
      address(token).call(abi.encodeWithSelector(token.approve.selector, spender, amount));
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }

  ///@notice ERC20 approval, handling non standard approvals that do not return a value
  ///@param token the ERC20
  ///@param spender the address whose allowance is to be given
  ///@param amount of the allowance
  ///@return true if approval was successful; otherwise, false.
  function approveToken(IERC20 token, address spender, uint amount) internal returns (bool) {
    return _approveToken(token, spender, amount);
  }
}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

// Note: can't do Type.Unpacked because typechain mixes up multiple 'Unpacked' structs under different namespaces. So for consistency we don't do Type.Packed either. We do TypeUnpacked and TypePacked.

import {OfferPacked, OfferUnpacked} from "./MgvOffer.post.sol";
import "./MgvOffer.post.sol" as Offer;
import {OfferDetailPacked, OfferDetailUnpacked} from "./MgvOfferDetail.post.sol";
import "./MgvOfferDetail.post.sol" as OfferDetail;
import {GlobalPacked, GlobalUnpacked} from "./MgvGlobal.post.sol";
import "./MgvGlobal.post.sol" as Global;
import {LocalPacked, LocalUnpacked} from "./MgvLocal.post.sol";
import "./MgvLocal.post.sol" as Local;

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {IERC20} from "mgv_src/IERC20.sol";
import {AaveV3Lender} from "mgv_src/strategies/integrations/AaveV3Lender.sol";

///@title Memoizes values for AAVE to reduce gas cost and simplify code flow.
///@dev the memoizer works in the context of a single token and therefore should not be used across multiple tokens.
contract HasAaveBalanceMemoizer is AaveV3Lender {
  ///@param balanceOf the owner's balance of the token
  ///@param balanceOfMemoized whether the `balanceOf` has been memoized.
  ///@param balanceOfOverlying the balance of the overlying.
  ///@param balanceOfOverlyingMemoized whether the `balanceOfOverlying` has been memoized.
  ///@param overlying the overlying
  ///@param overlyingMemoized whether the `overlying` has been memoized.
  struct BalanceMemoizer {
    uint balanceOf;
    bool balanceOfMemoized;
    uint balanceOfOverlying;
    bool balanceOfOverlyingMemoized;
    IERC20 overlying;
    bool overlyingMemoized;
  }

  ///@notice contract's constructor
  ///@param addressesProvider address of AAVE's address provider
  constructor(address addressesProvider) AaveV3Lender(addressesProvider) {}

  ///@notice Gets the overlying for the token.
  ///@param token the token.
  ///@param memoizer the memoizer.
  ///@return overlying for the token.
  function overlying(IERC20 token, BalanceMemoizer memory memoizer) internal view returns (IERC20) {
    if (memoizer.overlyingMemoized) {
      return memoizer.overlying;
    } else {
      memoizer.overlyingMemoized = true;
      memoizer.overlying = overlying(token);
      return memoizer.overlying;
    }
  }

  ///@notice Gets the balance for the overlying of the token, or 0 if there is no overlying.
  ///@param token the token.
  ///@param memoizer the memoizer.
  ///@return balance of the overlying, or 0 if there is no overlying.
  function balanceOfOverlying(IERC20 token, BalanceMemoizer memory memoizer) internal view returns (uint) {
    if (memoizer.balanceOfOverlyingMemoized) {
      return memoizer.balanceOfOverlying;
    } else {
      memoizer.balanceOfOverlyingMemoized = true;
      IERC20 aToken = overlying(token, memoizer);
      if (aToken == IERC20(address(0))) {
        memoizer.balanceOfOverlying = 0;
      } else {
        memoizer.balanceOfOverlying = aToken.balanceOf(address(this));
      }
      return memoizer.balanceOfOverlying;
    }
  }

  ///@notice Gets the balance of the token
  ///@param token the token.
  ///@param memoizer the memoizer.
  ///@return balance of the token.
  function balanceOf(IERC20 token, BalanceMemoizer memory memoizer) internal view returns (uint) {
    if (memoizer.balanceOfMemoized) {
      return memoizer.balanceOf;
    } else {
      memoizer.balanceOfMemoized = true;
      memoizer.balanceOf = token.balanceOf(address(this));
      return memoizer.balanceOf;
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {MgvLib} from "mgv_src/MgvLib.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/IERC20.sol";
import {OfferType} from "./TradesBaseQuotePair.sol";
import {DirectWithBidsAndAsksDistribution} from "./DirectWithBidsAndAsksDistribution.sol";
import {TradesBaseQuotePair} from "./TradesBaseQuotePair.sol";
import {AbstractKandel} from "./AbstractKandel.sol";
import {TransferLib} from "mgv_src/strategies/utils/TransferLib.sol";

///@title the core of Kandel strategies which creates or updates a dual offer whenever an offer is taken.
///@notice `CoreKandel` is agnostic to the chosen price distribution.
abstract contract CoreKandel is DirectWithBidsAndAsksDistribution, TradesBaseQuotePair, AbstractKandel {
  ///@notice Constructor
  ///@param mgv The Mangrove deployment.
  ///@param base Address of the base token of the market Kandel will act on
  ///@param quote Address of the quote token of the market Kandel will act on
  ///@param gasreq the gasreq to use for offers
  ///@param reserveId identifier of this contract's reserve when using a router.
  constructor(IMangrove mgv, IERC20 base, IERC20 quote, uint gasreq, address reserveId)
    TradesBaseQuotePair(base, quote)
    DirectWithBidsAndAsksDistribution(mgv, gasreq, reserveId)
  {}

  ///@inheritdoc AbstractKandel
  function reserveBalance(OfferType ba) public view virtual override returns (uint balance) {
    IERC20 token = outboundOfOfferType(ba);
    return token.balanceOf(address(this));
  }

  ///@notice takes care of status for populating dual and logging of potential issues.
  ///@param offerId the Mangrove offer id (or 0 if newOffer failed).
  ///@param args the arguments of the offer.
  ///@param populateStatus the status returned from the populateIndex function.
  function logPopulateStatus(uint offerId, OfferArgs memory args, bytes32 populateStatus) internal {
    if (
      populateStatus == REPOST_SUCCESS || populateStatus == NEW_OFFER_SUCCESS
        || populateStatus == "mgv/writeOffer/density/tooLow" || populateStatus == LOW_VOLUME
    ) {
      // Low density will mean some amount is not posted and will be available for withdrawal or later posting via populate.
      return;
    }
    if (offerId != 0) {
      emit LogIncident(MGV, args.outbound_tkn, args.inbound_tkn, offerId, "Kandel/updateOfferFailed", populateStatus);
    } else {
      emit LogIncident(MGV, args.outbound_tkn, args.inbound_tkn, 0, "Kandel/newOfferFailed", populateStatus);
    }
  }

  ///@notice update or create dual offer according to transport logic
  ///@param order is a recall of the taker order that is at the origin of the current trade.
  function transportSuccessfulOrder(MgvLib.SingleOrder calldata order) internal {
    OfferType ba = offerTypeOfOutbound(IERC20(order.outbound_tkn));

    // adds any unpublished liquidity to pending[Base/Quote]
    // preparing arguments for the dual offer
    (OfferType baDual, uint offerId, uint index, OfferArgs memory args) = transportLogic(ba, order);
    bytes32 populateStatus = populateIndex(baDual, offerId, index, args);
    logPopulateStatus(offerId, args, populateStatus);
  }

  ///@notice transport logic followed by Kandel
  ///@param ba whether the offer that was executed is a bid or an ask
  ///@param order a recap of the taker order (order.offer is the executed offer)
  ///@return baDual the type of dual offer that will re-invest inbound liquidity
  ///@return offerId the offer id of the dual offer
  ///@return index the index of the dual offer
  ///@return args the argument for `populateIndex` specifying gives and wants
  function transportLogic(OfferType ba, MgvLib.SingleOrder calldata order)
    internal
    virtual
    returns (OfferType baDual, uint offerId, uint index, OfferArgs memory args);

  /// @notice gets pending liquidity for base (ask) or quote (bid). Will be negative if funds are not enough to cover all offer's promises.
  /// @param ba offer type.
  /// @return the pending amount
  /// @dev Gas costly function, better suited for off chain calls.
  function pending(OfferType ba) external view override returns (int) {
    return int(reserveBalance(ba)) - int(offeredVolume(ba));
  }

  ///@notice Deposits funds to the contract's reserve
  ///@param baseAmount the amount of base tokens to deposit.
  ///@param quoteAmount the amount of quote tokens to deposit.
  function depositFunds(uint baseAmount, uint quoteAmount) public virtual override {
    require(TransferLib.transferTokenFrom(BASE, msg.sender, address(this), baseAmount), "Kandel/baseTransferFail");
    emit Credit(BASE, baseAmount);
    require(TransferLib.transferTokenFrom(QUOTE, msg.sender, address(this), quoteAmount), "Kandel/quoteTransferFail");
    emit Credit(QUOTE, quoteAmount);
  }

  ///@notice withdraws funds from the contract's reserve
  ///@param baseAmount the amount of base tokens to withdraw. Use type(uint).max to denote the entire reserve balance.
  ///@param quoteAmount the amount of quote tokens to withdraw. Use type(uint).max to denote the entire reserve balance.
  ///@param recipient the address to which the withdrawn funds should be sent to.
  function withdrawFunds(uint baseAmount, uint quoteAmount, address recipient) public virtual override onlyAdmin {
    if (baseAmount == type(uint).max) {
      baseAmount = BASE.balanceOf(address(this));
    }
    if (quoteAmount == type(uint).max) {
      quoteAmount = QUOTE.balanceOf(address(this));
    }
    require(TransferLib.transferToken(BASE, recipient, baseAmount), "Kandel/baseTransferFail");
    emit Debit(BASE, baseAmount);
    require(TransferLib.transferToken(QUOTE, recipient, quoteAmount), "Kandel/quoteTransferFail");
    emit Debit(QUOTE, quoteAmount);
  }

  ///@notice Retracts offers, withdraws funds, and withdraws free wei from Mangrove.
  ///@param from retract offers starting from this index.
  ///@param to retract offers until this index.
  ///@param baseAmount the amount of base tokens to withdraw. Use type(uint).max to denote the entire reserve balance.
  ///@param quoteAmount the amount of quote tokens to withdraw. Use type(uint).max to denote the entire reserve balance.
  ///@param freeWei the amount of wei to withdraw from Mangrove. Use type(uint).max to withdraw entire available balance.
  ///@param recipient the recipient of the funds.
  function retractAndWithdraw(
    uint from,
    uint to,
    uint baseAmount,
    uint quoteAmount,
    uint freeWei,
    address payable recipient
  ) external onlyAdmin {
    retractOffers(from, to);
    withdrawFunds(baseAmount, quoteAmount, recipient);
    withdrawFromMangrove(freeWei, recipient);
  }
}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

struct OfferUnpacked {
  uint prev;
  uint next;
  uint wants;
  uint gives;
}

//some type safety for each struct
type OfferPacked is uint;
using Library for OfferPacked global;

uint constant prev_bits  = 32;
uint constant next_bits  = 32;
uint constant wants_bits = 96;
uint constant gives_bits = 96;

uint constant prev_before  = 0;
uint constant next_before  = prev_before  + prev_bits ;
uint constant wants_before = next_before  + next_bits ;
uint constant gives_before = wants_before + wants_bits;

uint constant prev_mask  = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant next_mask  = 0xffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant wants_mask = 0xffffffffffffffff000000000000000000000000ffffffffffffffffffffffff;
uint constant gives_mask = 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000;

library Library {
  function to_struct(OfferPacked __packed) internal pure returns (OfferUnpacked memory __s) { unchecked {
    __s.prev = (OfferPacked.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __s.next = (OfferPacked.unwrap(__packed) << next_before) >> (256-next_bits);
    __s.wants = (OfferPacked.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __s.gives = (OfferPacked.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function eq(OfferPacked __packed1, OfferPacked __packed2) internal pure returns (bool) { unchecked {
    return OfferPacked.unwrap(__packed1) == OfferPacked.unwrap(__packed2);
  }}

  function unpack(OfferPacked __packed) internal pure returns (uint __prev, uint __next, uint __wants, uint __gives) { unchecked {
    __prev = (OfferPacked.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __next = (OfferPacked.unwrap(__packed) << next_before) >> (256-next_bits);
    __wants = (OfferPacked.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __gives = (OfferPacked.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function prev(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) << prev_before) >> (256-prev_bits);
  }}
  function prev(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & prev_mask)
                                | ((val << (256-prev_bits) >> prev_before)));
  }}
  function next(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) << next_before) >> (256-next_bits);
  }}
  function next(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & next_mask)
                                | ((val << (256-next_bits) >> next_before)));
  }}
  function wants(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) << wants_before) >> (256-wants_bits);
  }}
  function wants(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & wants_mask)
                                | ((val << (256-wants_bits) >> wants_before)));
  }}
  function gives(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}
  function gives(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & gives_mask)
                                | ((val << (256-gives_bits) >> gives_before)));
  }}
}

function t_of_struct(OfferUnpacked memory __s) pure returns (OfferPacked) { unchecked {
  return pack(__s.prev, __s.next, __s.wants, __s.gives);
}}

function pack(uint __prev, uint __next, uint __wants, uint __gives) pure returns (OfferPacked) { unchecked {
  return OfferPacked.wrap(((((0
                              | ((__prev << (256-prev_bits)) >> prev_before))
                              | ((__next << (256-next_bits)) >> next_before))
                              | ((__wants << (256-wants_bits)) >> wants_before))
                              | ((__gives << (256-gives_bits)) >> gives_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

struct OfferDetailUnpacked {
  address maker;
  uint gasreq;
  uint offer_gasbase;
  uint gasprice;
}

//some type safety for each struct
type OfferDetailPacked is uint;
using Library for OfferDetailPacked global;

uint constant maker_bits         = 160;
uint constant gasreq_bits        = 24;
uint constant offer_gasbase_bits = 24;
uint constant gasprice_bits      = 16;

uint constant maker_before         = 0;
uint constant gasreq_before        = maker_before         + maker_bits        ;
uint constant offer_gasbase_before = gasreq_before        + gasreq_bits       ;
uint constant gasprice_before      = offer_gasbase_before + offer_gasbase_bits;

uint constant maker_mask         = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
uint constant gasreq_mask        = 0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
uint constant gasprice_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff;

library Library {
  function to_struct(OfferDetailPacked __packed) internal pure returns (OfferDetailUnpacked memory __s) { unchecked {
    __s.maker = address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __s.gasreq = (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __s.offer_gasbase = (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.gasprice = (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function eq(OfferDetailPacked __packed1, OfferDetailPacked __packed2) internal pure returns (bool) { unchecked {
    return OfferDetailPacked.unwrap(__packed1) == OfferDetailPacked.unwrap(__packed2);
  }}

  function unpack(OfferDetailPacked __packed) internal pure returns (address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) { unchecked {
    __maker = address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __gasreq = (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __offer_gasbase = (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __gasprice = (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function maker(OfferDetailPacked __packed) internal pure returns(address) { unchecked {
    return address(uint160((OfferDetailPacked.unwrap(__packed) << maker_before) >> (256-maker_bits)));
  }}
  function maker(OfferDetailPacked __packed,address val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & maker_mask)
                                | ((uint(uint160(val)) << (256-maker_bits) >> maker_before)));
  }}
  function gasreq(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
  }}
  function gasreq(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & gasreq_mask)
                                | ((val << (256-gasreq_bits) >> gasreq_before)));
  }}
  function offer_gasbase(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & offer_gasbase_mask)
                                | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function gasprice(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & gasprice_mask)
                                | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
}

function t_of_struct(OfferDetailUnpacked memory __s) pure returns (OfferDetailPacked) { unchecked {
  return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
}}

function pack(address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) pure returns (OfferDetailPacked) { unchecked {
  return OfferDetailPacked.wrap(((((0
                              | ((uint(uint160(__maker)) << (256-maker_bits)) >> maker_before))
                              | ((__gasreq << (256-gasreq_bits)) >> gasreq_before))
                              | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                              | ((__gasprice << (256-gasprice_bits)) >> gasprice_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

struct GlobalUnpacked {
  address monitor;
  bool useOracle;
  bool notify;
  uint gasprice;
  uint gasmax;
  bool dead;
}

//some type safety for each struct
type GlobalPacked is uint;
using Library for GlobalPacked global;

uint constant monitor_bits   = 160;
uint constant useOracle_bits = 8;
uint constant notify_bits    = 8;
uint constant gasprice_bits  = 16;
uint constant gasmax_bits    = 24;
uint constant dead_bits      = 8;

uint constant monitor_before   = 0;
uint constant useOracle_before = monitor_before   + monitor_bits  ;
uint constant notify_before    = useOracle_before + useOracle_bits;
uint constant gasprice_before  = notify_before    + notify_bits   ;
uint constant gasmax_before    = gasprice_before  + gasprice_bits ;
uint constant dead_before      = gasmax_before    + gasmax_bits   ;

uint constant monitor_mask   = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
uint constant useOracle_mask = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
uint constant notify_mask    = 0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff;
uint constant gasprice_mask  = 0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff;
uint constant gasmax_mask    = 0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff;
uint constant dead_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff;

library Library {
  function to_struct(GlobalPacked __packed) internal pure returns (GlobalUnpacked memory __s) { unchecked {
    __s.monitor = address(uint160((GlobalPacked.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __s.useOracle = (((GlobalPacked.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __s.notify = (((GlobalPacked.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __s.gasprice = (GlobalPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __s.gasmax = (GlobalPacked.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __s.dead = (((GlobalPacked.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function eq(GlobalPacked __packed1, GlobalPacked __packed2) internal pure returns (bool) { unchecked {
    return GlobalPacked.unwrap(__packed1) == GlobalPacked.unwrap(__packed2);
  }}

  function unpack(GlobalPacked __packed) internal pure returns (address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) { unchecked {
    __monitor = address(uint160((GlobalPacked.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __useOracle = (((GlobalPacked.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __notify = (((GlobalPacked.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __gasprice = (GlobalPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __gasmax = (GlobalPacked.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __dead = (((GlobalPacked.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function monitor(GlobalPacked __packed) internal pure returns(address) { unchecked {
    return address(uint160((GlobalPacked.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
  }}
  function monitor(GlobalPacked __packed,address val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & monitor_mask)
                                | ((uint(uint160(val)) << (256-monitor_bits) >> monitor_before)));
  }}
  function useOracle(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return (((GlobalPacked.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
  }}
  function useOracle(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & useOracle_mask)
                                | ((uint_of_bool(val) << (256-useOracle_bits) >> useOracle_before)));
  }}
  function notify(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return (((GlobalPacked.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
  }}
  function notify(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & notify_mask)
                                | ((uint_of_bool(val) << (256-notify_bits) >> notify_before)));
  }}
  function gasprice(GlobalPacked __packed) internal pure returns(uint) { unchecked {
    return (GlobalPacked.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(GlobalPacked __packed,uint val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & gasprice_mask)
                                | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
  function gasmax(GlobalPacked __packed) internal pure returns(uint) { unchecked {
    return (GlobalPacked.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
  }}
  function gasmax(GlobalPacked __packed,uint val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & gasmax_mask)
                                | ((val << (256-gasmax_bits) >> gasmax_before)));
  }}
  function dead(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return (((GlobalPacked.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}
  function dead(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & dead_mask)
                                | ((uint_of_bool(val) << (256-dead_bits) >> dead_before)));
  }}
}

function t_of_struct(GlobalUnpacked memory __s) pure returns (GlobalPacked) { unchecked {
  return pack(__s.monitor, __s.useOracle, __s.notify, __s.gasprice, __s.gasmax, __s.dead);
}}

function pack(address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) pure returns (GlobalPacked) { unchecked {
  return GlobalPacked.wrap(((((((0
                              | ((uint(uint160(__monitor)) << (256-monitor_bits)) >> monitor_before))
                              | ((uint_of_bool(__useOracle) << (256-useOracle_bits)) >> useOracle_before))
                              | ((uint_of_bool(__notify) << (256-notify_bits)) >> notify_before))
                              | ((__gasprice << (256-gasprice_bits)) >> gasprice_before))
                              | ((__gasmax << (256-gasmax_bits)) >> gasmax_before))
                              | ((uint_of_bool(__dead) << (256-dead_bits)) >> dead_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// fields are of the form [name,bits,type]

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

struct LocalUnpacked {
  bool active;
  uint fee;
  uint density;
  uint offer_gasbase;
  bool lock;
  uint best;
  uint last;
}

//some type safety for each struct
type LocalPacked is uint;
using Library for LocalPacked global;

uint constant active_bits        = 8;
uint constant fee_bits           = 16;
uint constant density_bits       = 112;
uint constant offer_gasbase_bits = 24;
uint constant lock_bits          = 8;
uint constant best_bits          = 32;
uint constant last_bits          = 32;

uint constant active_before        = 0;
uint constant fee_before           = active_before        + active_bits       ;
uint constant density_before       = fee_before           + fee_bits          ;
uint constant offer_gasbase_before = density_before       + density_bits      ;
uint constant lock_before          = offer_gasbase_before + offer_gasbase_bits;
uint constant best_before          = lock_before          + lock_bits         ;
uint constant last_before          = best_before          + best_bits         ;

uint constant active_mask        = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant fee_mask           = 0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant density_mask       = 0xffffff0000000000000000000000000000ffffffffffffffffffffffffffffff;
uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
uint constant lock_mask          = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
uint constant best_mask          = 0xffffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffff;
uint constant last_mask          = 0xffffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffff;

library Library {
  function to_struct(LocalPacked __packed) internal pure returns (LocalUnpacked memory __s) { unchecked {
    __s.active = (((LocalPacked.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __s.fee = (LocalPacked.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __s.density = (LocalPacked.unwrap(__packed) << density_before) >> (256-density_bits);
    __s.offer_gasbase = (LocalPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.lock = (((LocalPacked.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __s.best = (LocalPacked.unwrap(__packed) << best_before) >> (256-best_bits);
    __s.last = (LocalPacked.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function eq(LocalPacked __packed1, LocalPacked __packed2) internal pure returns (bool) { unchecked {
    return LocalPacked.unwrap(__packed1) == LocalPacked.unwrap(__packed2);
  }}

  function unpack(LocalPacked __packed) internal pure returns (bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) { unchecked {
    __active = (((LocalPacked.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __fee = (LocalPacked.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __density = (LocalPacked.unwrap(__packed) << density_before) >> (256-density_bits);
    __offer_gasbase = (LocalPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __lock = (((LocalPacked.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __best = (LocalPacked.unwrap(__packed) << best_before) >> (256-best_bits);
    __last = (LocalPacked.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function active(LocalPacked __packed) internal pure returns(bool) { unchecked {
    return (((LocalPacked.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
  }}
  function active(LocalPacked __packed,bool val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & active_mask)
                                | ((uint_of_bool(val) << (256-active_bits) >> active_before)));
  }}
  function fee(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << fee_before) >> (256-fee_bits);
  }}
  function fee(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & fee_mask)
                                | ((val << (256-fee_bits) >> fee_before)));
  }}
  function density(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << density_before) >> (256-density_bits);
  }}
  function density(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & density_mask)
                                | ((val << (256-density_bits) >> density_before)));
  }}
  function offer_gasbase(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & offer_gasbase_mask)
                                | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function lock(LocalPacked __packed) internal pure returns(bool) { unchecked {
    return (((LocalPacked.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
  }}
  function lock(LocalPacked __packed,bool val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & lock_mask)
                                | ((uint_of_bool(val) << (256-lock_bits) >> lock_before)));
  }}
  function best(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << best_before) >> (256-best_bits);
  }}
  function best(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & best_mask)
                                | ((val << (256-best_bits) >> best_before)));
  }}
  function last(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) << last_before) >> (256-last_bits);
  }}
  function last(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & last_mask)
                                | ((val << (256-last_bits) >> last_before)));
  }}
}

function t_of_struct(LocalUnpacked memory __s) pure returns (LocalPacked) { unchecked {
  return pack(__s.active, __s.fee, __s.density, __s.offer_gasbase, __s.lock, __s.best, __s.last);
}}

function pack(bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) pure returns (LocalPacked) { unchecked {
  return LocalPacked.wrap((((((((0
                              | ((uint_of_bool(__active) << (256-active_bits)) >> active_before))
                              | ((__fee << (256-fee_bits)) >> fee_before))
                              | ((__density << (256-density_bits)) >> density_before))
                              | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                              | ((uint_of_bool(__lock) << (256-lock_bits)) >> lock_before))
                              | ((__best << (256-best_bits)) >> best_before))
                              | ((__last << (256-last_bits)) >> last_before)));
}}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {IPool} from "../vendor/aave/v3/IPool.sol";
import {IPoolAddressesProvider} from "../vendor/aave/v3/IPoolAddressesProvider.sol";
import {IRewardsControllerIsh} from "../vendor/aave/v3/IRewardsControllerIsh.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/MgvLib.sol";
import {TransferLib} from "mgv_src/strategies/utils/TransferLib.sol";

/// @title This contract provides a collection of lending capabilities with AAVE-v3 to whichever contract inherits it
contract AaveV3Lender {
  ///@notice The AAVE pool retrieved from the pool provider.
  IPool public immutable POOL;
  ///@notice The AAVE pool address provider.
  IPoolAddressesProvider public immutable ADDRESS_PROVIDER;

  /// @notice contract's constructor
  /// @param addressesProvider address of AAVE's address provider
  constructor(address addressesProvider) {
    ADDRESS_PROVIDER = IPoolAddressesProvider(addressesProvider);

    address lendingPool = IPoolAddressesProvider(addressesProvider).getPool();
    require(lendingPool != address(0), "AaveV3Lender/0xPool");

    POOL = IPool(lendingPool);
  }

  /// @notice allows this contract to approve the POOL to transfer some underlying asset on its behalf
  /// @dev this is a necessary step prior to supplying tokens to the POOL or to repay a debt
  /// @param token the underlying asset for which approval is required
  /// @param amount the approval amount
  function _approveLender(IERC20 token, uint amount) internal {
    TransferLib.approveToken(token, address(POOL), amount);
  }

  /// @notice prevents the POOL from using some underlying as collateral
  /// @dev this call will revert if removing the asset from collateral would put the account into a liquidation state
  /// @param underlying the token one wishes to remove collateral
  function _exitMarket(IERC20 underlying) internal {
    POOL.setUserUseReserveAsCollateral(address(underlying), false);
  }

  /// @notice allows the POOL to use some underlying tokens as collateral
  /// @dev when supplying a token for the first time, it is automatically set as possible collateral so there is no need to call this function for it.
  /// @param underlyings the token one wishes to add as collateral
  function _enterMarkets(IERC20[] calldata underlyings) internal {
    for (uint i = 0; i < underlyings.length; ++i) {
      POOL.setUserUseReserveAsCollateral(address(underlyings[i]), true);
    }
  }

  /// @notice convenience function to obtain the overlying of a given asset
  /// @param asset the underlying asset
  /// @return aToken the overlying asset
  function overlying(IERC20 asset) public view returns (IERC20 aToken) {
    aToken = IERC20(POOL.getReserveData(address(asset)).aTokenAddress);
  }

  ///@notice redeems funds from the pool
  ///@param token the asset one is trying to redeem
  ///@param amount of assets one wishes to redeem
  ///@param to is the address where the redeemed assets should be transferred
  ///@return redeemed the amount of asset that were transferred to `to`
  function _redeem(IERC20 token, uint amount, address to) internal returns (uint redeemed) {
    redeemed = (amount == 0) ? 0 : POOL.withdraw(address(token), amount, to);
  }

  ///@notice supplies funds to the pool
  ///@param token the asset one is supplying
  ///@param amount of assets to be transferred to the pool
  ///@param onBehalf address of the account whose collateral is being supplied to and which will receive the overlying
  ///@param noRevert does not revert if supplies throws
  ///@return reason for revert from Aave.
  function _supply(IERC20 token, uint amount, address onBehalf, bool noRevert) internal returns (bytes32) {
    if (amount == 0) {
      return bytes32(0);
    } else {
      try POOL.supply(address(token), amount, onBehalf, 0) {
        return bytes32(0);
      } catch Error(string memory reason) {
        require(noRevert, reason);
        return bytes32(bytes(reason));
      } catch {
        require(noRevert, "noReason");
        return "noReason";
      }
    }
  }

  ///@notice rewards claiming.
  ///@param assets list of overlying for which one is claiming awards
  ///@param to whom the rewards should be sent
  ///@return rewardsList the address of assets that have been claimed
  ///@return claimedAmounts the amount of assets that have been claimed
  function _claimRewards(address[] calldata assets, address to)
    internal
    returns (address[] memory rewardsList, uint[] memory claimedAmounts)
  {
    IRewardsControllerIsh rewardsController =
      IRewardsControllerIsh(ADDRESS_PROVIDER.getAddress(keccak256("INCENTIVES_CONTROLLER")));
    (rewardsList, claimedAmounts) = rewardsController.claimAllRewards(assets, to);
  }

  ///@notice verifies whether an asset can be supplied on pool
  ///@param asset the asset one wants to lend
  ///@return true if the asset can be supplied on pool
  function checkAsset(IERC20 asset) public view returns (bool) {
    IERC20 aToken = overlying(asset);
    return address(aToken) != address(0);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {Direct} from "mgv_src/strategies/offer_maker/abstract/Direct.sol";
import {IERC20} from "mgv_src/IERC20.sol";
import {OfferType} from "./TradesBaseQuotePair.sol";
import {HasIndexedBidsAndAsks} from "./HasIndexedBidsAndAsks.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";

///@title `Direct` strat with an indexed collection of bids and asks which can be populated according to a desired base and quote distribution for gives and wants.
abstract contract DirectWithBidsAndAsksDistribution is Direct, HasIndexedBidsAndAsks {
  ///@notice The offer has too low volume to be posted.
  bytes32 internal constant LOW_VOLUME = "Kandel/volumeTooLow";

  ///@notice logs the start of a call to populate
  event PopulateStart();
  ///@notice logs the end of a call to populate
  event PopulateEnd();

  ///@notice logs the start of a call to retractOffers
  event RetractStart();
  ///@notice logs the end of a call to retractOffers
  event RetractEnd();

  ///@notice Constructor
  ///@param mgv The Mangrove deployment.
  ///@param gasreq the gasreq to use for offers
  ///@param reserveId identifier of this contract's reserve when using a router.
  constructor(IMangrove mgv, uint gasreq, address reserveId)
    Direct(mgv, NO_ROUTER, gasreq, reserveId)
    HasIndexedBidsAndAsks(mgv)
  {}

  ///@param indices the indices to populate, in ascending order
  ///@param baseDist base distribution for the indices (the `wants` for bids and the `gives` for asks)
  ///@param quoteDist the distribution of quote for the indices (the `gives` for bids and the `wants` for asks)
  struct Distribution {
    uint[] indices;
    uint[] baseDist;
    uint[] quoteDist;
  }

  ///@notice Publishes bids/asks for the distribution in the `indices`. Caller should follow the desired distribution in `baseDist` and `quoteDist`.
  ///@param distribution the distribution of base and quote for indices.
  ///@param pivotIds the pivots to be used for the offers.
  ///@param firstAskIndex the (inclusive) index after which offer should be an ask.
  ///@param gasreq the amount of gas units that are required to execute the trade.
  ///@param gasprice the gasprice used to compute offer's provision.
  function populateChunk(
    Distribution calldata distribution,
    uint[] calldata pivotIds,
    uint firstAskIndex,
    uint gasreq,
    uint gasprice
  ) internal {
    emit PopulateStart();
    uint[] calldata indices = distribution.indices;
    uint[] calldata quoteDist = distribution.quoteDist;
    uint[] calldata baseDist = distribution.baseDist;

    uint i;

    OfferArgs memory args;
    // args.fund = 0; offers are already funded
    // args.noRevert = false; we want revert in case of failure

    (args.outbound_tkn, args.inbound_tkn) = tokenPairOfOfferType(OfferType.Bid);
    for (; i < indices.length; ++i) {
      uint index = indices[i];
      if (index >= firstAskIndex) {
        break;
      }
      args.wants = baseDist[i];
      args.gives = quoteDist[i];
      args.gasreq = gasreq;
      args.gasprice = gasprice;
      args.pivotId = pivotIds[i];

      populateIndex(OfferType.Bid, offerIdOfIndex(OfferType.Bid, index), index, args);
    }

    (args.outbound_tkn, args.inbound_tkn) = (args.inbound_tkn, args.outbound_tkn);

    for (; i < indices.length; ++i) {
      uint index = indices[i];
      args.wants = quoteDist[i];
      args.gives = baseDist[i];
      args.gasreq = gasreq;
      args.gasprice = gasprice;
      args.pivotId = pivotIds[i];

      populateIndex(OfferType.Ask, offerIdOfIndex(OfferType.Ask, index), index, args);
    }
    emit PopulateEnd();
  }

  ///@notice publishes (by either creating or updating) a bid/ask at a given price index.
  ///@param ba whether the offer is a bid or an ask.
  ///@param offerId the Mangrove offer id (0 for a new offer).
  ///@param index the price index.
  ///@param args the argument of the offer.
  ///@return result the result from Mangrove or Direct (an error if `args.noRevert` is `true`).
  function populateIndex(OfferType ba, uint offerId, uint index, OfferArgs memory args)
    internal
    returns (bytes32 result)
  {
    // if offer does not exist on mangrove yet
    if (offerId == 0) {
      // and offer should exist
      if (args.gives > 0 && args.wants > 0) {
        // create it
        (offerId, result) = _newOffer(args);
        if (offerId != 0) {
          setIndexMapping(ba, index, offerId);
        }
      } else {
        // else offerId && gives are 0 and the offer is left not posted
        result = LOW_VOLUME;
      }
    }
    // else offer exists
    else {
      // but the offer should be dead since gives is 0
      if (args.gives == 0 || args.wants == 0) {
        // This may happen in the following cases:
        // * `gives == 0` may not come from `DualWantsGivesOfOffer` computation, but `wants==0` might.
        // * `gives == 0` may happen from populate in case of re-population where the offers in the spread are then retracted by setting gives to 0.
        _retractOffer(args.outbound_tkn, args.inbound_tkn, offerId, false);
        result = LOW_VOLUME;
      } else {
        // so the offer exists and it should, we simply update it with potentially new volume
        result = _updateOffer(args, offerId);
      }
    }
  }

  ///@notice retracts and deprovisions offers of the distribution interval `[from, to[`.
  ///@param from the start index.
  ///@param to the end index.
  ///@dev use in conjunction of `withdrawFromMangrove` if the user wishes to redeem the available WEIs.
  function retractOffers(uint from, uint to) public onlyAdmin {
    emit RetractStart();
    (IERC20 outbound_tknAsk, IERC20 inbound_tknAsk) = tokenPairOfOfferType(OfferType.Ask);
    (IERC20 outbound_tknBid, IERC20 inbound_tknBid) = (inbound_tknAsk, outbound_tknAsk);
    for (uint index = from; index < to; ++index) {
      // These offerIds could be recycled in a new populate
      uint offerId = offerIdOfIndex(OfferType.Ask, index);
      if (offerId != 0) {
        _retractOffer(outbound_tknAsk, inbound_tknAsk, offerId, true);
      }
      offerId = offerIdOfIndex(OfferType.Bid, index);
      if (offerId != 0) {
        _retractOffer(outbound_tknBid, inbound_tknBid, offerId, true);
      }
    }
    emit RetractEnd();
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   **/
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   **/
  event BackUnbacked(
    address indexed reserve,
    address indexed backer,
    uint amount,
    uint fee
  );

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(
    address indexed reserve,
    address indexed user,
    address indexed to,
    uint amount
  );

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint amount,
    DataTypes.InterestRateMode interestRateMode,
    uint borrowRate,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint amount,
    DataTypes.InterestRateMode interestRateMode,
    uint premium,
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
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint debtToCover,
    uint liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint liquidityRate,
    uint stableBorrowRate,
    uint variableBorrowRate,
    uint liquidityIndex,
    uint variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
  event MintedToTreasury(address indexed reserve, uint amountMinted);

  /**
   * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function mintUnbacked(
    address asset,
    uint amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
  function backUnbacked(
    address asset,
    uint amount,
    uint fee
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
  function supplyWithPermit(
    address asset,
    uint amount,
    address onBehalfOf,
    uint16 referralCode,
    uint deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint amount,
    address to
  ) external returns (uint);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint amount,
    uint interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint amount,
    uint interestRateMode,
    address onBehalfOf
  ) external returns (uint);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
  function repayWithPermit(
    address asset,
    uint amount,
    uint interestRateMode,
    address onBehalfOf,
    uint deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
  function repayWithATokens(
    address asset,
    uint amount,
    uint interestRateMode
  ) external returns (uint);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  function swapBorrowRateMode(address asset, uint interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint[] calldata amounts,
    uint[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint amount,
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
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint totalCollateralBase,
      uint totalDebtBase,
      uint availableBorrowsBase,
      uint currentLiquidationThreshold,
      uint ltv,
      uint healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(
    address asset,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    returns (uint);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    returns (uint);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint amount,
    uint balanceFromBefore,
    uint balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   **/
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(
    uint8 id,
    DataTypes.EModeCategory memory config
  ) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id)
    external
    view
    returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint);

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
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint amount
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

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
  event PriceOracleSentinelUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(
    bytes32 indexed id,
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
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
  function setAddressAsProxy(bytes32 id, address newImplementationAddress)
    external;

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
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
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
   **/
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
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/**
 * @title adapted from IRewardsController (AAVE V3 periphery contracts)
 * @author Aave
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IRewardsControllerIsh {
  /**
   * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint amount,
    address to,
    address reward
  ) external returns (uint);

  /**
   * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
   * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint amount,
    address user,
    address to,
    address reward
  ) external returns (uint);

  /**
   * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsToSelf(
    address[] calldata assets,
    uint amount,
    address reward
  ) external returns (uint);

  /**
   * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
   **/
  function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint[] memory claimedAmounts);

  /**
   * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  )
    external
    returns (address[] memory rewardsList, uint[] memory claimedAmounts);

  /**
   * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsToSelf(address[] calldata assets)
    external
    returns (address[] memory rewardsList, uint[] memory claimedAmounts);
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {MangroveOffer, IMangrove, AbstractRouter} from "mgv_src/strategies/MangroveOffer.sol";
import {MgvLib, IERC20, MgvStructs} from "mgv_src/MgvLib.sol";
import {TransferLib} from "mgv_src/strategies/utils/TransferLib.sol";
import {IOfferLogic} from "mgv_src/strategies/interfaces/IOfferLogic.sol";

///@title `Direct` strats is an extension of MangroveOffer that allows contract's admin to manage offers on Mangrove.
abstract contract Direct is MangroveOffer {
  ///@notice `reserveId` is set in the constructor
  ///@param reserveId identifier of this contract's reserve when using a router.
  event SetReserveId(address indexed reserveId);

  ///@notice identifier of this contract's reserve when using a router
  ///@dev RESERVE_ID==address(0) will pass address(this) to the router for the id field.
  ///@dev two contracts using the same RESERVE_ID will share funds, therefore strat builder must make sure this contract is allowed to pull into the given reserve Id.
  ///@dev a safe value for `RESERVE_ID` is `address(this)` in which case the funds will never be shared with another maker contract.
  address public immutable RESERVE_ID;

  ///@notice `Direct`'s constructor.
  ///@param mgv The Mangrove deployment that is allowed to call `this` for trade execution and posthook.
  ///@param router_ the router that this contract will use to pull/push liquidity from offer maker's reserve. This can be `NO_ROUTER`.
  ///@param gasreq Gas requirement when posting offers via this strategy, excluding router requirement.
  ///@param reserveId identifier of this contract's reserve when using a router.
  constructor(IMangrove mgv, AbstractRouter router_, uint gasreq, address reserveId) MangroveOffer(mgv, gasreq) {
    if (router_ != NO_ROUTER) {
      setRouter(router_);
    }
    address reserveId_ = reserveId == address(0) ? address(this) : reserveId;
    RESERVE_ID = reserveId_;
    emit SetReserveId(reserveId_);
  }

  /// @notice Inserts a new offer in Mangrove Offer List.
  /// @param args Function arguments stored in memory.
  /// @return offerId Identifier of the newly created offer. Returns 0 if offer creation was rejected by Mangrove and `args.noRevert` is set to `true`.
  /// @return status NEW_OFFER_SUCCESS if the offer was successfully posted on Mangrove. Returns Mangrove's revert reason otherwise.
  function _newOffer(OfferArgs memory args) internal returns (uint offerId, bytes32 status) {
    try MGV.newOffer{value: args.fund}(
      address(args.outbound_tkn),
      address(args.inbound_tkn),
      args.wants,
      args.gives,
      args.gasreq,
      args.gasprice,
      args.pivotId
    ) returns (uint offerId_) {
      offerId = offerId_;
      status = NEW_OFFER_SUCCESS;
    } catch Error(string memory reason) {
      require(args.noRevert, reason);
      status = bytes32(bytes(reason));
    }
  }

  ///@inheritdoc MangroveOffer
  function _updateOffer(OfferArgs memory args, uint offerId) internal override returns (bytes32 status) {
    try MGV.updateOffer{value: args.fund}(
      address(args.outbound_tkn),
      address(args.inbound_tkn),
      args.wants,
      args.gives,
      args.gasreq,
      args.gasprice,
      args.pivotId,
      offerId
    ) {
      status = REPOST_SUCCESS;
    } catch Error(string memory reason) {
      require(args.noRevert, reason);
      status = bytes32(bytes(reason));
    }
  }

  ///@notice Retracts an offer from an Offer List of Mangrove.
  ///@param outbound_tkn the outbound token of the offer list.
  ///@param inbound_tkn the inbound token of the offer list.
  ///@param offerId the identifier of the offer in the (`outbound_tkn`,`inbound_tkn`) offer list
  ///@param deprovision if set to `true` if offer admin wishes to redeem the offer's provision.
  ///@return freeWei the amount of native tokens (in WEI) that have been retrieved by retracting the offer.
  ///@dev An offer that is retracted without `deprovision` is retracted from the offer list, but still has its provisions locked by Mangrove.
  ///@dev Calling this function, with the `deprovision` flag, on an offer that is already retracted must be used to retrieve the locked provisions.
  function _retractOffer(
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) internal returns (uint freeWei) {
    freeWei = MGV.retractOffer(address(outbound_tkn), address(inbound_tkn), offerId, deprovision);
  }

  ///@inheritdoc IOfferLogic
  function provisionOf(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId)
    external
    view
    override
    returns (uint provision)
  {
    provision = _provisionOf(outbound_tkn, inbound_tkn, offerId);
  }

  ///@notice direct contract do not need to do anything specific with incoming funds during trade
  ///@dev one should override this function if one wishes to leverage taker's fund during trade execution
  ///@inheritdoc MangroveOffer
  function __put__(uint, MgvLib.SingleOrder calldata) internal virtual override returns (uint) {
    return 0;
  }

  ///@notice `__get__` hook for `Direct` is to ask the router to pull liquidity from `reserveId` if strat is using a router
  /// otherwise the function simply returns what's missing in the local balance
  ///@inheritdoc MangroveOffer
  function __get__(uint amount, MgvLib.SingleOrder calldata order) internal virtual override returns (uint) {
    uint amount_ = IERC20(order.outbound_tkn).balanceOf(address(this));
    if (amount_ >= amount) {
      return 0;
    }
    amount_ = amount - amount_;
    AbstractRouter router_ = router();
    if (router_ == NO_ROUTER) {
      return amount_;
    } else {
      // if RESERVE_ID is potentially shared by other contracts we are forced to pull in a strict fashion (otherwise another contract sharing funds that would be called in the same market order will fail to deliver)
      uint pulled = router_.pull(IERC20(order.outbound_tkn), RESERVE_ID, amount_, RESERVE_ID != address(this));
      return pulled >= amount_ ? 0 : amount_ - pulled;
    }
  }

  ///@notice Direct posthook flushes outbound and inbound token back to the router (if any)
  ///@inheritdoc MangroveOffer
  function __posthookSuccess__(MgvLib.SingleOrder calldata order, bytes32 makerData)
    internal
    virtual
    override
    returns (bytes32)
  {
    AbstractRouter router_ = router();
    if (router_ != NO_ROUTER) {
      IERC20[] memory tokens = new IERC20[](2);
      tokens[0] = IERC20(order.outbound_tkn); // flushing outbound tokens if this contract pulled more liquidity than required during `makerExecute`
      tokens[1] = IERC20(order.inbound_tkn); // flushing liquidity brought by taker
      router_.flush(tokens, RESERVE_ID);
    }
    // reposting offer residual if any
    return super.__posthookSuccess__(order, makerData);
  }

  ///@notice if strat has a router, verifies that the router is ready to pull/push on behalf of reserve id
  ///@inheritdoc MangroveOffer
  function __checkList__(IERC20 token) internal view virtual override {
    super.__checkList__(token);
    if (router() != NO_ROUTER) {
      router().checkList(token, RESERVE_ID);
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {MgvStructs} from "mgv_src/MgvLib.sol";
import {IHasTokenPairOfOfferType, OfferType} from "./TradesBaseQuotePair.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/IERC20.sol";

///@title Adds a [0..length] index <--> offerId map to a strat.
///@dev utilizes the `IHasTokenPairOfOfferType` contract.
abstract contract HasIndexedBidsAndAsks is IHasTokenPairOfOfferType {
  ///@notice The Mangrove deployment.
  IMangrove private immutable MGV;

  ///@notice the length of the index has been set.
  ///@param value the length.
  event SetLength(uint value);

  ///@notice a new offer of type `ba` with `offerId` was created at price `index`
  ///@param ba the offer type
  ///@param index the index
  ///@param offerId the Mangrove offer id.
  event SetIndexMapping(OfferType indexed ba, uint index, uint offerId);

  ///@notice Constructor
  ///@param mgv The Mangrove deployment.
  constructor(IMangrove mgv) {
    MGV = mgv;
  }

  ///@notice the length of the map.
  uint internal length;

  ///@notice Mangrove's offer id of an ask at a given index.
  mapping(uint => uint) private askOfferIdOfIndex;
  ///@notice Mangrove's offer id of a bid at a given index.
  mapping(uint => uint) private bidOfferIdOfIndex;

  ///@notice An inverse mapping of askOfferIdOfIndex. E.g., indexOfAskOfferId[42] is the index in askOfferIdOfIndex at which ask of id #42 on Mangrove is stored.
  mapping(uint => uint) private indexOfAskOfferId;

  ///@notice An inverse mapping of bidOfferIdOfIndex. E.g., indexOfBidOfferId[42] is the index in bidOfferIdOfIndex at which bid of id #42 on Mangrove is stored.
  mapping(uint => uint) private indexOfBidOfferId;

  ///@notice maps index of offers to offer id on Mangrove.
  ///@param ba the offer type
  ///@param index the index
  ///@return offerId the Mangrove offer id.
  function offerIdOfIndex(OfferType ba, uint index) public view returns (uint offerId) {
    return ba == OfferType.Ask ? askOfferIdOfIndex[index] : bidOfferIdOfIndex[index];
  }

  ///@notice Maps an offer type and Mangrove offer id to index.
  ///@param ba the offer type
  ///@param offerId the Mangrove offer id.
  ///@return index the index.
  function indexOfOfferId(OfferType ba, uint offerId) public view returns (uint index) {
    return ba == OfferType.Ask ? indexOfAskOfferId[offerId] : indexOfBidOfferId[offerId];
  }

  ///@notice Sets the Mangrove offer id for an index and vice versa.
  ///@param ba the offer type
  ///@param index the index
  ///@param offerId the Mangrove offer id.
  function setIndexMapping(OfferType ba, uint index, uint offerId) internal {
    if (ba == OfferType.Ask) {
      indexOfAskOfferId[offerId] = index;
      askOfferIdOfIndex[index] = offerId;
    } else {
      indexOfBidOfferId[offerId] = index;
      bidOfferIdOfIndex[index] = offerId;
    }
    emit SetIndexMapping(ba, index, offerId);
  }

  ///@notice sets the length of the map.
  ///@param length_ the new length.
  function setLength(uint length_) internal {
    length = length_;
    emit SetLength(length);
  }

  ///@notice gets the Mangrove offer at the given index for the offer type.
  ///@param ba the offer type.
  ///@param index the index.
  ///@return offer the Mangrove offer.
  function getOffer(OfferType ba, uint index) public view returns (MgvStructs.OfferPacked offer) {
    uint offerId = offerIdOfIndex(ba, index);
    (IERC20 outbound, IERC20 inbound) = tokenPairOfOfferType(ba);
    offer = MGV.offers(address(outbound), address(inbound), offerId);
  }

  /// @notice gets the total gives of all offers of the offer type.
  /// @param ba offer type.
  /// @return volume the total gives of all offers of the offer type.
  /// @dev function is very gas costly, for external calls only.
  function offeredVolume(OfferType ba) public view returns (uint volume) {
    for (uint index = 0; index < length; ++index) {
      MgvStructs.OfferPacked offer = getOffer(ba, index);
      volume += offer.gives();
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

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
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
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
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint currScaledVariableDebt;
    uint nextScaledVariableDebt;
    uint currPrincipalStableDebt;
    uint currAvgStableBorrowRate;
    uint currTotalStableDebt;
    uint nextAvgStableBorrowRate;
    uint nextTotalStableDebt;
    uint currLiquidityIndex;
    uint nextLiquidityIndex;
    uint currVariableBorrowIndex;
    uint nextVariableBorrowIndex;
    uint currLiquidityRate;
    uint currVariableBorrowRate;
    uint reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint reservesCount;
    uint debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint maxStableRateBorrowSizePercent;
    uint reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint amount;
    address to;
    uint reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint amount;
    uint balanceFromBefore;
    uint balanceToBefore;
    uint reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint[] amounts;
    uint[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint flashLoanPremiumToProtocol;
    uint flashLoanPremiumTotal;
    uint maxStableRateBorrowSizePercent;
    uint reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint amount;
    bytes params;
    uint16 referralCode;
    uint flashLoanPremiumToProtocol;
    uint flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint amount;
    uint totalPremium;
    uint flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint amount;
    InterestRateMode interestRateMode;
    uint maxStableLoanPercent;
    uint reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint totalDebt;
    uint healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint unbacked;
    uint liquidityAdded;
    uint liquidityTaken;
    uint totalStableDebt;
    uint totalVariableDebt;
    uint averageStableBorrowRate;
    uint reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}