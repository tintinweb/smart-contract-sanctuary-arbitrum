// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {IMangrove} from "mgv_src/IMangrove.sol";
import {Forwarder, MangroveOffer} from "mgv_src/strategies/offer_forwarder/abstract/Forwarder.sol";
import {IOrderLogic} from "mgv_src/strategies/interfaces/IOrderLogic.sol";
import {SimpleRouter} from "mgv_src/strategies/routers/SimpleRouter.sol";
import {TransferLib} from "mgv_src/strategies/utils/TransferLib.sol";
import {MgvLib, IERC20} from "mgv_src/MgvLib.sol";

///@title MangroveOrder. A periphery contract to Mangrove protocol that implements "Good till cancelled" (GTC) orders as well as "Fill or kill" (FOK) orders.
///@notice A GTC order is a buy (sell) limit order complemented by a bid (ask) limit order, called a resting order, that occurs when the buy (sell) order was partially filled.
/// If the GTC is for some amount $a_goal$ at a price $p$, and the corresponding limit order was partially filled for $a_now < a_goal$,
/// the resting order should be posted for an amount $a_later = a_goal - a_now$ at price $p$.
///@notice A FOK order is simply a buy or sell limit order that is either completely filled or cancelled. No resting order is posted.
///@dev requiring no partial fill *and* a resting order is interpreted here as an instruction to revert if the resting order fails to be posted (e.g., if below density).

contract MangroveOrder is Forwarder, IOrderLogic {
  ///@notice `expiring[outbound_tkn][inbound_tkn][offerId]` gives timestamp beyond which `offerId` on the `(outbound_tkn, inbound_tkn)` offer list should renege on trade.
  ///@notice if the order tx is included after the expiry date, it reverts.
  ///@dev 0 means no expiry.
  mapping(IERC20 => mapping(IERC20 => mapping(uint => uint))) public expiring;

  ///@notice MangroveOrder is a Forwarder logic with a simple router.
  ///@param mgv The mangrove contract on which this logic will run taker and maker orders.
  ///@param deployer The address of the admin of `this` at the end of deployment
  ///@param gasreq The gas required for `this` to execute `makerExecute` and `makerPosthook` when called by mangrove for a resting order.
  constructor(IMangrove mgv, address deployer, uint gasreq) Forwarder(mgv, new SimpleRouter(), gasreq) {
    // adding `this` contract to authorized makers of the router before setting admin rights of the router to deployer
    router().bind(address(this));
    router().setAdmin(deployer);
    // if `msg.sender` is not `deployer`, setting admin of `this` to `deployer`.
    // `deployer` will thus be able to call `activate` on `this` to enable trading on particular assets.
    if (msg.sender != deployer) {
      setAdmin(deployer);
    }
  }

  ///@notice The expiry of the offer has been set
  ///@param outbound_tkn the outbound token of the offer list.
  ///@param inbound_tkn the inbound token of the offer list.
  ///@param offerId the Mangrove offer id.
  ///@param date in seconds since unix epoch
  event SetExpiry(address indexed outbound_tkn, address indexed inbound_tkn, uint offerId, uint date);

  ///@inheritdoc IOrderLogic
  ///@dev We also allow Mangrove to call this so that it can part of an offer logic.
  function setExpiry(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId, uint date)
    public
    mgvOrOwner(outbound_tkn, inbound_tkn, offerId)
  {
    expiring[outbound_tkn][inbound_tkn][offerId] = date;
    emit SetExpiry(address(outbound_tkn), address(inbound_tkn), offerId, date);
  }

  ///@notice updates an offer on Mangrove
  ///@dev this can be used to update price of the resting order
  ///@param outbound_tkn outbound token of the offer list
  ///@param inbound_tkn inbound token of the offer list
  ///@param wants new amount of `inbound_tkn` offer owner wants
  ///@param gives new amount of `outbound_tkn` offer owner gives
  ///@param pivotId pivot for the new rank of the offer
  ///@param offerId the id of the offer to be updated
  function updateOffer(IERC20 outbound_tkn, IERC20 inbound_tkn, uint wants, uint gives, uint pivotId, uint offerId)
    external
    payable
    onlyOwner(outbound_tkn, inbound_tkn, offerId)
  {
    OfferArgs memory args;

    // funds to compute new gasprice is msg.value. Will use old gasprice if no funds are given
    args.fund = msg.value; // if inside a hook (Mangrove is `msg.sender`) this will be 0
    args.outbound_tkn = outbound_tkn;
    args.inbound_tkn = inbound_tkn;
    args.wants = wants;
    args.gives = gives;
    args.gasreq = offerGasreq();
    args.pivotId = pivotId;
    args.noRevert = false; // will throw if Mangrove reverts
    _updateOffer(args, offerId);
  }

  ///@notice Retracts an offer from an Offer List of Mangrove.
  ///@param outbound_tkn the outbound token of the offer list.
  ///@param inbound_tkn the inbound token of the offer list.
  ///@param offerId the identifier of the offer in the (`outbound_tkn`,`inbound_tkn`) offer list
  ///@param deprovision if set to `true` if offer owner wishes to redeem the offer's provision.
  ///@return freeWei the amount of native tokens (in WEI) that have been retrieved by retracting the offer.
  ///@dev An offer that is retracted without `deprovision` is retracted from the offer list, but still has its provisions locked by Mangrove.
  ///@dev Calling this function, with the `deprovision` flag, on an offer that is already retracted must be used to retrieve the locked provisions.
  function retractOffer(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId, bool deprovision)
    public
    mgvOrOwner(outbound_tkn, inbound_tkn, offerId)
    returns (uint freeWei)
  {
    return _retractOffer(outbound_tkn, inbound_tkn, offerId, deprovision);
  }

  ///Checks the current timestamps and reneges on trade (by reverting) if the offer has expired.
  ///@inheritdoc MangroveOffer
  function __lastLook__(MgvLib.SingleOrder calldata order) internal virtual override returns (bytes32) {
    uint exp = expiring[IERC20(order.outbound_tkn)][IERC20(order.inbound_tkn)][order.offerId];
    require(exp == 0 || block.timestamp <= exp, "mgvOrder/expired");
    return super.__lastLook__(order);
  }

  ///@notice compares a taker order with a market order result and checks whether the order was entirely filled
  ///@param tko the taker order
  ///@param res the market order result
  ///@return true if the order was entirely filled, false otherwise.
  function checkCompleteness(TakerOrder calldata tko, TakerOrderResult memory res) internal pure returns (bool) {
    // The order can be incomplete if the price becomes too high or the end of the book is reached.
    if (tko.fillWants) {
      // when fillWants is true, the market order stops when `takerWants` units of `outbound_tkn` have been obtained (minus potential fees);
      return res.takerGot + res.fee >= tko.takerWants;
    } else {
      // otherwise, the market order stops when `takerGives` units of `inbound_tkn` have been sold.
      return res.takerGave >= tko.takerGives;
    }
  }

  ///@inheritdoc IOrderLogic
  function take(TakerOrder calldata tko) external payable returns (TakerOrderResult memory res) {
    // Checking whether order is expired
    require(tko.expiryDate == 0 || block.timestamp <= tko.expiryDate, "mgvOrder/expired");

    // Notations:
    // NAT_USER: initial value of `msg.sender.balance` (native balance of user)
    // OUT/IN_USER: initial value of `tko.[out|in]bound_tkn.balanceOf(reserve(msg.sender))` (user's reserve balance of tokens)
    // NAT_THIS: initial value of `address(this).balance` (native balance of `this`)
    // OUT/IN_THIS: initial value of `tko.[out|in]bound_tkn.balanceOf(address(this))` (`this` balance of tokens)

    // PRE:
    // * User balances: (NAT_USER -`msg.value`, OUT_USER, IN_USER)
    // * `this` balances: (NAT_THIS +`msg.value`, OUT_THIS, IN_THIS)

    // Pulling funds from `msg.sender`'s reserve
    uint pulled = router().pull(tko.inbound_tkn, msg.sender, tko.takerGives, true);
    require(pulled == tko.takerGives, "mgvOrder/transferInFail");

    // POST:
    // * (NAT_USER-`msg.value`, OUT_USER, IN_USER-`tko.takerGives`)
    // * (NAT_THIS+`msg.value`, OUT_THIS, IN_THIS+`tko.takerGives`)

    (res.takerGot, res.takerGave, res.bounty, res.fee) = MGV.marketOrder({
      outbound_tkn: address(tko.outbound_tkn),
      inbound_tkn: address(tko.inbound_tkn),
      takerWants: tko.takerWants,
      takerGives: tko.takerGives,
      fillWants: tko.fillWants
    });

    // POST:
    // * (NAT_USER-`msg.value`, OUT_USER, IN_USER-`tko.takerGives`)
    // * (NAT_THIS+`msg.value`+`res.bounty`, OUT_THIS+`res.takerGot`, IN_THIS+`tko.takerGives`-`res.takerGave`)

    bool isComplete = checkCompleteness(tko, res);
    // when `!restingOrder` this implements FOK. When `restingOrder` the `postRestingOrder` function reverts if resting order fails to be posted and `fillOrKill`.
    // therefore we require `fillOrKill => (isComplete \/ restingOrder)`
    require(!tko.fillOrKill || isComplete || tko.restingOrder, "mgvOrder/partialFill");

    // sending inbound tokens to `msg.sender`'s reserve and sending back remaining outbound tokens
    if (res.takerGot > 0) {
      require(router().push(tko.outbound_tkn, msg.sender, res.takerGot) == res.takerGot, "mgvOrder/pushFailed");
    }
    uint inboundLeft = tko.takerGives - res.takerGave;
    if (inboundLeft > 0) {
      require(router().push(tko.inbound_tkn, msg.sender, inboundLeft) == inboundLeft, "mgvOrder/pushFailed");
    }
    // POST:
    // * (NAT_USER-`msg.value`, OUT_USER+`res.takerGot`, IN_USER-`res.takerGave`)
    // * (NAT_THIS+`msg.value`+`res.bounty`, OUT_THIS, IN_THIS)

    ///@dev collected bounty compensates gas consumption for the failed offer, but could be lower than the cost of an additional native token transfer
    /// instead of sending the bounty back to `msg.sender` we recycle it into the resting order's provision (so `msg.sender` can retrieve it when deprovisioning).
    /// corner case: if the bounty is large enough, this will make posting of the resting order fail because of `gasprice` overflow.
    /// The funds will then be sent back to `msg.sender` (see below).
    uint fund = msg.value + res.bounty;

    if ( // resting order is:
      tko.restingOrder // required
        && !isComplete // needed
    ) {
      // When posting a resting order `msg.sender` becomes a maker.
      // For maker orders, outbound tokens are what makers send. Here `msg.sender` sends `tko.inbound_tkn`.
      // The offer list on which this contract must post `msg.sender`'s resting order is thus `(tko.inbound_tkn, tko.outbound_tkn)`
      // the call below will fill the memory data `res`.
      fund =
        postRestingOrder({tko: tko, outbound_tkn: tko.inbound_tkn, inbound_tkn: tko.outbound_tkn, res: res, fund: fund});
      // POST (case `postRestingOrder` succeeded):
      // * (NAT_USER-`msg.value`, OUT_USER+`res.takerGot`, IN_USER-`res.takerGave`)
      // * (NAT_THIS, OUT_THIS, IN_THIS)
      // * `fund == 0`
      // * `ownerData[tko.inbound_tkn][tko.outbound_tkn][res.offerId].owner == msg.sender`.
      // * Mangrove emitted an `OfferWrite` log whose `maker` field is `address(this)` and `offerId` is `res.offerId`.

      // POST (case `postRestingOrder` failed):
      // * (NAT_USER-`msg.value`, OUT_USER+`res.takerGot`, IN_USER-`res.takerGave`)
      // * (NAT_THIS+`msg.value`+`res.bounty`, OUT_THIS, IN_THIS)
      // * `fund == msg.value + res.bounty`.
      // * `res.offerId == 0`
    }

    if (fund > 0) {
      // NB this calls gives reentrancy power to callee, but OK since:
      // 1. callee is `msg.sender` so no griefing risk of making this call fail for out of gas
      // 2. w.r.t reentrancy for profit:
      // * from POST above a reentrant call would entail either:
      //   - `fund == 0` (no additional funds transferred)
      //   - or `fund == msg.value + res.bounty` with `msg.value` being from reentrant call and `res.bounty` from a second resting order.
      // Thus no additional fund can be redeemed by caller using reentrancy.
      (bool noRevert,) = msg.sender.call{value: fund}("");
      require(noRevert, "mgvOrder/refundFail");
    }
    // POST (case `postRestingOrder` succeeded)
    // * (NAT_USER, OUT_USER+`res.takerGot`, IN_USER-`res.takerGave`)
    // * (NAT_THIS, OUT_THIS, IN_THIS)
    // POST (else)
    // * (NAT_USER+`res.bounty`, OUT_USER+`res.takerGot`, IN_USER-`res.takerGave`)
    // * (NAT_THIS, OUT_THIS, IN_THIS)
    logOrderData(tko, res);
    return res;
  }

  ///@notice logs `OrderSummary`
  ///@param tko the arguments in memory of the taker order
  ///@param res the result of the taker order.
  ///@dev this function avoids loading too many variables on the stack
  function logOrderData(TakerOrder memory tko, TakerOrderResult memory res) internal {
    emit OrderSummary({
      mangrove: MGV,
      outbound_tkn: tko.outbound_tkn,
      inbound_tkn: tko.inbound_tkn,
      taker: msg.sender,
      fillOrKill: tko.fillOrKill,
      takerWants: tko.takerWants,
      takerGives: tko.takerGives,
      fillWants: tko.fillWants,
      restingOrder: tko.restingOrder,
      expiryDate: tko.expiryDate,
      takerGot: res.takerGot,
      takerGave: res.takerGave,
      bounty: res.bounty,
      fee: res.fee,
      restingOrderId: res.offerId
    });
  }

  ///@notice posts a maker order on the (`outbound_tkn`, `inbound_tkn`) offer list.
  ///@param tko the arguments in memory of the taker order
  ///@param outbound_tkn the outbound token of the offer to post
  ///@param inbound_tkn the inbound token of the offer to post
  ///@param fund amount of WEIs used to cover for the offer bounty (covered gasprice is derived from `fund`).
  ///@param res the result of the taker order.
  ///@return refund the amount to refund to the taker of the fund.
  ///@dev entailed price that should be preserved for the maker order are:
  /// * `tko.takerGives/tko.takerWants` for buy orders (i.e `fillWants==true`)
  /// * `tko.takerWants/tko.takerGives` for sell orders (i.e `fillWants==false`)
  function postRestingOrder(
    TakerOrder calldata tko,
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    TakerOrderResult memory res,
    uint fund
  ) internal returns (uint refund) {
    uint residualWants;
    uint residualGives;
    if (tko.fillWants) {
      // partialFill => tko.takerWants > res.takerGot + res.fee
      residualWants = tko.takerWants - (res.takerGot + res.fee);
      // adapting residualGives to match initial price
      residualGives = (residualWants * tko.takerGives) / tko.takerWants;
    } else {
      // partialFill => tko.takerGives > res.takerGave
      residualGives = tko.takerGives - res.takerGave;
      // adapting residualGives to match initial price
      residualWants = (residualGives * tko.takerWants) / tko.takerGives;
    }
    (res.offerId,) = _newOffer(
      OfferArgs({
        outbound_tkn: outbound_tkn,
        inbound_tkn: inbound_tkn,
        wants: residualWants,
        gives: residualGives,
        gasreq: offerGasreq(), // using default gasreq of the strat
        gasprice: 0, // ignored
        pivotId: tko.pivotId,
        fund: fund,
        noRevert: true // returns 0 when MGV reverts
      }),
      msg.sender
    );
    if (res.offerId == 0) {
      // either:
      // - residualGives is below current density
      // - `fund` is too low and would yield a gasprice that is lower than Mangrove's
      // - `fund` is too high and would yield a gasprice overflow
      // - offer list is not active (Mangrove is not dead otherwise market order would have reverted)
      // reverting when partial fill is not an option
      require(!tko.fillOrKill, "mgvOrder/partialFill");
      // `fund` is no longer needed so sending it back to `msg.sender`
      refund = fund;
    } else {
      // offer was successfully posted
      // `fund` was used and we leave `refund` at 0.

      // setting expiry date for the resting order
      if (tko.expiryDate > 0) {
        setExpiry(outbound_tkn, inbound_tkn, res.offerId, tko.expiryDate);
      }
      // if one wants to maintain an inverse mapping owner => offerIds
      __logOwnershipRelation__({
        owner: msg.sender,
        outbound_tkn: outbound_tkn,
        inbound_tkn: inbound_tkn,
        offerId: res.offerId
      });
    }
  }

  /**
   * @notice This is invoked for each new offer created for resting orders, e.g., to maintain an inverse mapping from owner to offers.
   * @param owner the owner of the new offer
   * @param outbound_tkn the outbound token used to identify the order book
   * @param inbound_tkn the inbound token used to identify the order book
   * @param offerId the id of the new offer
   */
  function __logOwnershipRelation__(address owner, IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId)
    internal
    virtual
  {
    owner; //ssh
    outbound_tkn; //ssh
    inbound_tkn; //ssh
    offerId; //ssh
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

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {MangroveOffer} from "mgv_src/strategies/MangroveOffer.sol";
import {IForwarder} from "mgv_src/strategies/interfaces/IForwarder.sol";
import {AbstractRouter} from "mgv_src/strategies/routers/AbstractRouter.sol";
import {IOfferLogic} from "mgv_src/strategies/interfaces/IOfferLogic.sol";
import {MgvLib, IERC20, MgvStructs} from "mgv_src/MgvLib.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";

///@title Class for maker contracts that forward offer makers instructions to Mangrove in a permissionless fashion.
///@notice Each offer posted via this contract are managed by their offer maker, not by this contract's admin.
///@notice This class implements IForwarder, which contains specific Forwarder logic functions in additions to IOfferLogic interface.

abstract contract Forwarder is IForwarder, MangroveOffer {
  ///@notice approx of amount of gas units required to complete `__posthookFallback__` when evaluating penalty.
  uint constant GAS_APPROX = 2000;

  ///@notice data associated to each offer published on Mangrove by this contract.
  ///@param owner address of the account that can manage (update or retract) the offer
  ///@param weiBalance fraction of `this` balance on Mangrove that is assigned to `owner`.
  ///@dev `OwnerData` packs into one word.
  struct OwnerData {
    address owner;
    uint96 weiBalance;
  }

  ///@notice Owner data mapping.
  ///@dev mapping is outbound_tkn -> inbound_tkn -> offerId -> OwnerData
  ///@dev 'ownerData[out][in][offerId].owner == maker` if `maker` is offer owner of `offerId` in the `(out, in)` offer list.
  mapping(IERC20 => mapping(IERC20 => mapping(uint => OwnerData))) internal ownerData;

  ///@notice modifier to enforce function caller to be offer owner
  modifier onlyOwner(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId) {
    require(ownerData[outbound_tkn][inbound_tkn][offerId].owner == msg.sender, "AccessControlled/Invalid");
    _;
  }

  ///@notice modifier to enforce function caller to be offer owner or MGV (for use in the offer logic)
  modifier mgvOrOwner(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId) {
    if (msg.sender != address(MGV)) {
      require(ownerData[outbound_tkn][inbound_tkn][offerId].owner == msg.sender, "AccessControlled/Invalid");
    }
    _;
  }

  ///@notice Forwarder constructor
  ///@param mgv the deployed Mangrove contract on which this contract will post offers.
  ///@param router the router that this contract will use to pull/push liquidity from offer maker's reserve. This must not be `NO_ROUTER`.
  ///@param gasreq Gas requirement when posting offers via this strategy, excluding router requirement.
  constructor(IMangrove mgv, AbstractRouter router, uint gasreq) MangroveOffer(mgv, gasreq) {
    require(router != NO_ROUTER, "Forwarder logics must have a router");
    setRouter(router);
  }

  ///@inheritdoc IForwarder
  function offerOwners(IERC20 outbound_tkn, IERC20 inbound_tkn, uint[] calldata offerIds)
    public
    view
    override
    returns (address[] memory offerOwners_)
  {
    offerOwners_ = new address[](offerIds.length);
    for (uint i = 0; i < offerIds.length; ++i) {
      offerOwners_[i] = ownerOf(outbound_tkn, inbound_tkn, offerIds[i]);
    }
  }

  /// @notice grants managing (update/retract) rights on a particular offer.
  /// @param outbound_tkn the outbound token coordinate of the offer list.
  /// @param inbound_tkn the inbound token coordinate of the offer list.
  /// @param offerId the offer identifier in the offer list.
  /// @param owner the address of the offer maker.
  /// @param leftover the fraction of `msg.value` that is not locked in the offer provision due to rounding error (see `_newOffer`).
  function addOwner(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId, address owner, uint leftover) internal {
    ownerData[outbound_tkn][inbound_tkn][offerId] = OwnerData({owner: owner, weiBalance: uint96(leftover)});
    emit NewOwnedOffer(MGV, outbound_tkn, inbound_tkn, offerId, owner);
  }

  /// @notice computes the maximum `gasprice` that can be covered by the amount of provision given in argument.
  /// @param gasreq the gas required by the offer
  /// @param provision the amount of native token one wishes to use, to provision the offer on Mangrove.
  /// @param offerGasbase Mangrove's offer_gasbase.
  /// @return gasprice the gas price that is covered by `provision` - `leftover`.
  /// @return leftover the sub amount of `provision` that is not used to provision the offer.
  /// @dev the returned gasprice is slightly lower than the real gasprice that the provision can cover because of the rounding error due to division
  function deriveGasprice(uint gasreq, uint provision, uint offerGasbase)
    internal
    pure
    returns (uint gasprice, uint leftover)
  {
    unchecked {
      uint num = (offerGasbase + gasreq) * 10 ** 9;
      // pre-check to avoid underflow since 0 is interpreted as "use Mangrove's gasprice"
      require(provision >= num, "mgv/insufficientProvision");
      // Gasprice is eventually a uint16, so too much provision would yield a gasprice overflow
      // Reverting here with a clearer reason
      require(provision < type(uint16).max * num, "Forwarder/provisionTooHigh");
      gasprice = provision / num;

      // computing amount of native tokens that are not going to be locked on Mangrove
      // this amount should still be recoverable by offer maker when retracting the offer
      leftover = provision - (gasprice * 10 ** 9 * (offerGasbase + gasreq));
    }
  }

  /// @inheritdoc IForwarder
  function ownerOf(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId) public view override returns (address owner) {
    owner = ownerData[outbound_tkn][inbound_tkn][offerId].owner;
    require(owner != address(0), "Forwarder/unknownOffer");
  }

  /// @notice Derives the gas price for the new offer and verifies it against the global configuration.
  /// @param args function's arguments in memory
  /// @return gasprice the gas price that is covered by `provision` - `leftover`.
  /// @return leftover the sub amount of `provision` that is not used to provision the offer.
  /// @dev the returned gasprice is slightly lower than the real gasprice that the provision can cover because of the rounding error due to division
  function deriveAndCheckGasprice(OfferArgs memory args) internal view returns (uint gasprice, uint leftover) {
    (MgvStructs.GlobalPacked global, MgvStructs.LocalPacked local) =
      MGV.config(address(args.outbound_tkn), address(args.inbound_tkn));
    // computing max `gasprice` such that `offData.fund` covers `offData.gasreq` at `gasprice`
    (gasprice, leftover) = deriveGasprice(args.gasreq, args.fund, local.offer_gasbase());
    // mangrove will take max(`mko.gasprice`, `global.gasprice`)
    // if `mko.gasprice < global.gasprice` Mangrove will use available provision of this contract to provision the offer
    // this would potentially take native tokens that have been released after some offer managed by this contract have failed
    // so one needs to make sure here that only provision of this call will be used to provision the offer on mangrove
    require(gasprice >= global.gasprice(), "mgv/insufficientProvision");
  }

  /// @notice Inserts a new offer on a Mangrove Offer List.
  /// @dev If inside a hook, one should call `_newOffer` to create a new offer and not directly `MGV.newOffer` to make sure one is correctly dealing with:
  /// * offer ownership
  /// * offer provisions and gasprice
  /// @param args function's arguments in memory
  /// @param owner the address of the offer owner
  /// @return offerId the identifier of the new offer on the offer list. Can be 0 if posting was rejected by Mangrove and `args.noRevert` is `true`.
  /// @return status the status of the new offer on Mangrove if the call has not reverted. It may be NEW_OFFER_SUCCESS or Mangrove's revert reason if `args.noRevert` was set to true.
  /// Forwarder logic does not manage user funds on Mangrove, as a consequence:
  /// An offer maker's redeemable provisions on Mangrove is just the sum $S_locked(maker)$ of locked provision in all live offers it owns
  /// plus the sum $S_free(maker)$ of `weiBalance`'s in all dead offers it owns (see `OwnerData.weiBalance`).
  /// Notice $\sum_i S_free(maker_i)$ <= MGV.balanceOf(address(this))`.
  /// Any fund of an offer maker on Mangrove that is either not locked on Mangrove or stored in the `OwnerData` free wei's is thus not recoverable by the offer maker (although it is admin recoverable).
  /// Therefore we need to make sure that all `msg.value` is either used to provision the offer at `gasprice` or stored in the offer data under `weiBalance`.
  /// To do so, we do not let offer maker fix a gasprice. Rather we derive the gasprice based on `msg.value`.
  /// Because of rounding errors in `deriveGasprice` a small amount of WEIs will accumulate in mangrove's balance of `this` contract
  /// We assign this leftover to the corresponding `weiBalance` of `OwnerData`.
  function _newOffer(OfferArgs memory args, address owner) internal returns (uint offerId, bytes32 status) {
    // convention for default gasreq value
    (uint gasprice, uint leftover) = deriveAndCheckGasprice(args);

    // the call below cannot revert for lack of provision (by design)
    // it may still revert if `offData.fund` yields a gasprice that is too high (mangrove's gasprice is uint16)
    // or if `offData.gives` is below density (dust)
    try MGV.newOffer{value: args.fund}(
      address(args.outbound_tkn), address(args.inbound_tkn), args.wants, args.gives, args.gasreq, gasprice, args.pivotId
    ) returns (uint offerId_) {
      // assign `offerId_` to caller
      addOwner(args.outbound_tkn, args.inbound_tkn, offerId_, owner, leftover);
      offerId = offerId_;
      status = NEW_OFFER_SUCCESS;
    } catch Error(string memory reason) {
      /// letting revert bubble up unless `noRevert` is positioned.
      require(args.noRevert, reason);
      status = bytes32(bytes(reason));
    }
  }

  ///@notice Internal `updateOffer`, using arguments and variables on memory to avoid stack too deep.
  ///@return reason is either REPOST_SUCCESS or Mangrove's revert reason if update was rejected by Mangrove and `args.noRevert` is `true`.
  struct UpdateOfferVars {
    uint leftover;
    MgvStructs.GlobalPacked global;
    MgvStructs.LocalPacked local;
    MgvStructs.OfferDetailPacked offerDetail;
  }

  ///@inheritdoc MangroveOffer
  function _updateOffer(OfferArgs memory args, uint offerId) internal override returns (bytes32) {
    unchecked {
      UpdateOfferVars memory vars;
      (vars.global, vars.local) = MGV.config(address(args.outbound_tkn), address(args.inbound_tkn));
      vars.offerDetail = MGV.offerDetails(address(args.outbound_tkn), address(args.inbound_tkn), offerId);

      uint old_gasreq = vars.offerDetail.gasreq();
      // re-deriving gasprice only if necessary
      if (
        args.fund > 0 // user adds more provision
          || args.gasreq != old_gasreq // offer's `gasreq` is modified
          || vars.offerDetail.offer_gasbase() != vars.local.offer_gasbase() // governance has updated `offer_gasbase`
      ) {
        // adding current locked provision to funds (0 if offer is deprovisioned)
        uint locked_funds = vars.offerDetail.gasprice() * 10 ** 9 * (old_gasreq + vars.offerDetail.offer_gasbase());
        // note that if `args.gasreq < old_gasreq` then offer gasprice will increase (even if `args.fund == 0`) to match the incurred excess of locked provision
        (args.gasprice, vars.leftover) =
          deriveGasprice(args.gasreq, args.fund + locked_funds, vars.local.offer_gasbase());

        // leftover can be safely cast to uint96 since it's a rounding error
        // adding `leftover` to potential previous value since it was not included in args.fund
        ownerData[args.outbound_tkn][args.inbound_tkn][offerId].weiBalance += uint96(vars.leftover);
      } else {
        // no funds are added so we keep old gasprice
        args.gasprice = vars.offerDetail.gasprice();
      }
      // if `args.fund` is too low, offer gasprice might be below mangrove's gasprice
      // Mangrove will then take its own gasprice for the offer and would possibly tap into `this` contract's balance to cover for the missing provision
      require(args.gasprice >= vars.global.gasprice(), "mgv/insufficientProvision");
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
        return REPOST_SUCCESS;
      } catch Error(string memory reason) {
        require(args.noRevert, reason);
        return bytes32(bytes(reason));
      }
    }
  }

  ///@inheritdoc IOfferLogic
  function provisionOf(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId)
    external
    view
    override
    returns (uint provision)
  {
    provision = _provisionOf(outbound_tkn, inbound_tkn, offerId);
    unchecked {
      provision += ownerData[outbound_tkn][inbound_tkn][offerId].weiBalance;
    }
  }

  ///@notice Retracts an offer from an Offer List of Mangrove.
  ///@param outbound_tkn the outbound token of the offer list.
  ///@param inbound_tkn the inbound token of the offer list.
  ///@param offerId the identifier of the offer in the (`outbound_tkn`,`inbound_tkn`) offer list
  ///@param deprovision if set to `true` if offer owner wishes to redeem the offer's provision.
  ///@return freeWei the amount of native tokens (in WEI) that have been retrieved by retracting the offer.
  ///@dev An offer that is retracted without `deprovision` is retracted from the offer list, but still has its provisions locked by Mangrove.
  ///@dev Calling this function, with the `deprovision` flag, on an offer that is already retracted must be used to retrieve the locked provisions.
  function _retractOffer(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId, bool deprovision)
    internal
    returns (uint freeWei)
  {
    OwnerData storage od = ownerData[outbound_tkn][inbound_tkn][offerId];
    freeWei = deprovision ? od.weiBalance : 0; // (a)
    freeWei += MGV.retractOffer(address(outbound_tkn), address(inbound_tkn), offerId, deprovision); // (b)
    if (freeWei > 0) {
      // pulling free wei from Mangrove to `this`
      require(MGV.withdraw(freeWei), "Forwarder/withdrawFail");
      // resetting pending returned provision
      od.weiBalance = 0;
      // Griefing issue: the call below could occur nested inside a call to `makerExecute` originating from Mangrove, so `owner` could make the current trade fail.
      // Here we are safe because callee is offer owner and has no incentive to make current trade fail or waste gas.
      // w.r.t reentrancy:
      // * `od.weiBalance` is set to 0 (storage write) prior to this call, so a reentrant call to `retractOffer` would give `freeWei = 0` at (a)
      // * further call to `MGV.retractOffer` will yield no more WEIs so `freeWei += 0` at (b)
      // * (a /\ b) imply that the above call to `MGV.withdraw` will be done with `freeWei == 0`.
      // * `retractOffer` is the only function that allows non admin users to withdraw WEIs from Mangrove.
      (bool noRevert,) = od.owner.call{value: freeWei}("");
      require(noRevert, "mgvOffer/weiTransferFail");
    }
  }

  ///@dev put received inbound tokens on offer maker's reserve during `makerExecute`
  /// if nothing is done at that stage then it could still be done during `makerPosthook`.
  /// However one would then need to pay attention to the following fact:
  /// if `order.inbound_tkn` is not pushed to reserve during `makerExecute`, in the posthook of this offer execution, the `order.inbound_tkn` balance of this contract would then contain
  /// the sum of all payments of offers managed by `this` that are in a better position in the offer list (because posthook is called in the call stack order).
  /// here we maintain an invariant that `this` balance is empty (both for `order.inbound_tkn` and `order.outbound_tkn`) at the end of `makerExecute`.
  ///@inheritdoc MangroveOffer
  function __put__(uint amount, MgvLib.SingleOrder calldata order) internal virtual override returns (uint) {
    IERC20 outTkn = IERC20(order.outbound_tkn);
    IERC20 inTkn = IERC20(order.inbound_tkn);
    address owner = ownerOf(outTkn, inTkn, order.offerId);
    uint pushed = router().push(inTkn, owner, amount);
    return amount - pushed;
  }

  ///@dev get outbound tokens from offer owner reserve
  ///@inheritdoc MangroveOffer
  function __get__(uint amount, MgvLib.SingleOrder calldata order) internal virtual override returns (uint) {
    IERC20 outTkn = IERC20(order.outbound_tkn);
    IERC20 inTkn = IERC20(order.inbound_tkn);
    address owner = ownerOf(outTkn, inTkn, order.offerId);
    // telling router one is requiring `amount` of `outTkn` for `owner`.
    // because `pull` is strict, `pulled <= amount` (cannot be greater)
    // we do not check local balance here because multi user contracts do not keep more balance than what has been pulled
    uint pulled = router().pull(outTkn, owner, amount, true);
    return amount - pulled; // this will make trade fail if `amount != pulled`
  }

  ///@dev if offer failed to execute, Mangrove retracts and deprovisions it after the posthook call.
  /// As a consequence if this hook is reached, `this` balance on Mangrove *will* increase, after the posthook,
  /// of some amount $n$ of native tokens. We evaluate here an underapproximation $~n$ in order to credit the offer maker in a pull based manner:
  /// failed offer owner can retrieve $~n$ by calling `retractOffer` on the failed offer.
  /// because $~n<n$ a small amount of WEIs will accumulate on the balance of `this` on Mangrove over time.
  /// Note that these WEIs are not burnt since they can be admin retrieved using `withdrawFromMangrove`.
  /// @inheritdoc MangroveOffer
  function __handleResidualProvision__(MgvLib.SingleOrder calldata order) internal virtual override {
    mapping(uint => OwnerData) storage semiBookOwnerData =
      ownerData[IERC20(order.outbound_tkn)][IERC20(order.inbound_tkn)];
    // NB if several offers of `this` contract have failed during the market order, the balance of this contract on Mangrove will contain cumulated free provision

    // computing an under approximation of returned provision because of this offer's failure
    uint gasreq = order.offerDetail.gasreq();
    uint provision = 10 ** 9 * order.offerDetail.gasprice() * (gasreq + order.offerDetail.offer_gasbase());

    // gasUsed estimate to complete posthook and penalize this offer is ~1750 (empirical estimate)
    uint gasprice = order.global.gasprice() * 10 ** 9;
    uint approxGasConsumption = gasreq + GAS_APPROX + order.local.offer_gasbase();
    uint approxBounty = (approxGasConsumption - gasleft()) * gasprice;
    uint approxReturnedProvision = approxBounty >= provision ? 0 : provision - approxBounty;

    // storing the portion of this contract's balance on Mangrove that should be attributed back to the failing offer's owner
    // those free WEIs can be retrieved by offer owner, by calling `retractOffer` with the `deprovision` flag.
    semiBookOwnerData[order.offerId].weiBalance += uint96(approxReturnedProvision);
  }

  ///@inheritdoc MangroveOffer
  ///@notice verifies that msg.sender is an allowed reserve id to trade tokens with this contract
  function __checkList__(IERC20 token) internal view virtual override {
    super.__checkList__(token);
    AbstractRouter router_ = router();
    router_.checkList(token, msg.sender);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity >=0.8.10;

import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/MgvLib.sol";

///@title Interface for resting orders functionality.
interface IOrderLogic {
  ///@notice Information for creating a market order with a GTC or FOK semantics.
  ///@param outbound_tkn outbound token used to identify the order book
  ///@param inbound_tkn the inbound token used to identify the order book
  ///@param fillOrKill true to revert if market order cannot be filled and resting order failed or is not enabled; otherwise, false
  ///@param takerWants desired total amount of `outbound_tkn`
  ///@param takerGives available total amount of `inbound_tkn`
  ///@param fillWants if true (buying), the market order stops when `takerWants` units of `outbound_tkn` have been obtained (fee included); otherwise (selling), the market order stops when `takerGives` units of `inbound_tkn` have been sold.
  ///@param restingOrder whether the complement of the partial fill (if any) should be posted as a resting limit order.
  ///@param pivotId in case a resting order is required, the best pivot estimation of its position in the offer list (if the market order led to a non empty partial fill, then `pivotId` should be 0 unless the order book is crossed).
  ///@param expiryDate timestamp (expressed in seconds since unix epoch) beyond which the order is no longer valid, 0 means forever
  struct TakerOrder {
    IERC20 outbound_tkn;
    IERC20 inbound_tkn;
    bool fillOrKill;
    uint takerWants;
    uint takerGives;
    bool fillWants;
    bool restingOrder;
    uint pivotId;
    uint expiryDate;
  }

  ///@notice Result of an order from the takers side.
  ///@param takerGot How much the taker got
  ///@param takerGave How much the taker gave
  ///@param bounty How much bounty was givin to the taker
  ///@param fee The fee paid by the taker
  ///@param offerId The id of the offer that was taken
  struct TakerOrderResult {
    uint takerGot;
    uint takerGave;
    uint bounty;
    uint fee;
    uint offerId;
  }

  ///@notice Information about the order.
  ///@param mangrove The Mangrove contract on which the offer was posted
  ///@param outbound_tkn The outbound token of the order.
  ///@param inbound_tkn The inbound token of the order.
  ///@param taker The address of the taker
  ///@param fillOrKill The fillOrKill that take was called with
  ///@param takerWants How much the taker wanted
  ///@param takerGives How much the taker would give
  ///@param fillWants If true, the market order stopped when `takerWants` units of `outbound_tkn` had been obtained; otherwise, the market order stopped when `takerGives` units of `inbound_tkn` had been sold.
  ///@param restingOrder The restingOrder boolean take was called with
  ///@param expiryDate The expiry date take was called with
  ///@param takerGot How much the taker got
  ///@param takerGave How much the taker gave
  ///@param bounty How much bounty was given
  ///@param fee How much fee was paid for the order
  ///@param restingOrderId If a restingOrder was posted, then this holds the offerId for the restingOrder
  event OrderSummary(
    IMangrove mangrove,
    IERC20 indexed outbound_tkn,
    IERC20 indexed inbound_tkn,
    address indexed taker,
    bool fillOrKill,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    bool restingOrder,
    uint expiryDate,
    uint takerGot,
    uint takerGave,
    uint bounty,
    uint fee,
    uint restingOrderId
  );

  ///@notice Timestamp beyond which the given `offerId` should renege on trade.
  ///@param outbound_tkn The outbound token of the order.
  ///@param inbound_tkn The inbound token of the order.
  ///@param offerId The id of the offer to query for expiry for.
  ///@return res The timestamp beyond which `offerId` on the `(outbound_tkn, inbound_tkn)` offer list should renege on trade. 0 means no expiry.
  function expiring(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId) external returns (uint);

  ///@notice Updates the expiry date for a specific offer.
  ///@param outbound_tkn The outbound token of the order.
  ///@param inbound_tkn The inbound token of the order.
  ///@param offerId The offer id whose expiry date is to be set.
  ///@param date in seconds since unix epoch
  ///@dev If new date is in the past of the current block's timestamp, offer will renege on trade.
  function setExpiry(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId, uint date) external;

  ///@notice Implements "Fill or kill" or "Good till cancelled" orders on a given offer list.
  ///@param tko the arguments in memory of the taker order
  ///@return res the result of the taker order. If `offerId==0`, no resting order was posted on `msg.sender`'s behalf.
  function take(TakerOrder memory tko) external payable returns (TakerOrderResult memory res);
}

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity ^0.8.10;

import {IERC20} from "mgv_src/MgvLib.sol";
import {TransferLib} from "mgv_src/strategies/utils/TransferLib.sol";
import {AbstractRouter} from "./AbstractRouter.sol";

///@title `SimpleRouter` instances pull (push) liquidity directly from (to) the an offer owner's account
///@dev Maker contracts using this router must make sure that the reserve approves the router for all asset that will be pulled (outbound tokens)
/// Thus a maker contract using a vault that is not an EOA must make sure this vault has approval capacities.
contract SimpleRouter is
  AbstractRouter(70_000) // fails for < 70K with Direct strat
{
  /// @notice transfers an amount of tokens from the reserve to the maker.
  /// @param token Token to be transferred
  /// @param owner The account from which the tokens will be transferred.
  /// @param amount The amount of tokens to be transferred
  /// @param strict wether the caller maker contract wishes to pull at most `amount` tokens of owner.
  /// @return pulled The amount pulled if successful (will be equal to `amount`); otherwise, 0.
  /// @dev requires approval from `owner` for `this` to transfer `token`.
  function __pull__(IERC20 token, address owner, uint amount, bool strict)
    internal
    virtual
    override
    returns (uint pulled)
  {
    // if not strict, pulling all available tokens from reserve
    amount = strict ? amount : token.balanceOf(owner);
    if (TransferLib.transferTokenFrom(token, owner, msg.sender, amount)) {
      return amount;
    } else {
      return 0;
    }
  }

  /// @notice transfers an amount of tokens from the maker to the reserve.
  /// @inheritdoc AbstractRouter
  function __push__(IERC20 token, address owner, uint amount) internal virtual override returns (uint) {
    bool success = TransferLib.transferTokenFrom(token, msg.sender, owner, amount);
    return success ? amount : 0;
  }

  ///@inheritdoc AbstractRouter
  function balanceOfReserve(IERC20 token, address owner) public view override returns (uint) {
    return token.balanceOf(owner);
  }

  ///@notice router-dependent implementation of the `checkList` function
  ///@notice verifies all required approval involving `this` router (either as a spender or owner)
  ///@dev `checkList` returns normally if all needed approval are strictly positive. It reverts otherwise with a reason.
  ///@param token is the asset whose approval must be checked
  ///@param owner the account that requires asset pulling/pushing
  function __checkList__(IERC20 token, address owner) internal view virtual override {
    // verifying that `this` router can withdraw tokens from owner (required for `withdrawToken` and `pull`)
    require(token.allowance(owner, address(this)) > 0, "SimpleRouter/NotApprovedByOwner");
  }
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

// SPDX-License-Identifier:	BSD-2-Clause
pragma solidity >=0.8.10;

import {IMangrove} from "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/MgvLib.sol";

///@title IForwarder
///@notice Interface for contracts that manage liquidity on Mangrove on behalf of multiple offer makers
interface IForwarder {
  ///@notice Logging new offer owner
  ///@param mangrove Mangrove contract on which the offer is posted
  ///@param outbound_tkn the outbound token of the offer list.
  ///@param inbound_tkn the inbound token of the offer list.
  ///@param offerId the Mangrove offer id.
  ///@param owner the offer maker that can manage the offer.
  event NewOwnedOffer(
    IMangrove mangrove, IERC20 indexed outbound_tkn, IERC20 indexed inbound_tkn, uint indexed offerId, address owner
  );

  /// @notice view on offer owners.
  /// @param outbound_tkn the outbound token of the offer list.
  /// @param inbound_tkn the inbound token of the offer list.
  /// @param offerIds an array of offer identifiers on the offer list.
  /// @return offer_owners an array of the same length where the address at position i is the owner of `offerIds[i]`
  /// @dev if `offerIds[i]==address(0)` if and only if this offer has no owner.
  function offerOwners(IERC20 outbound_tkn, IERC20 inbound_tkn, uint[] calldata offerIds)
    external
    view
    returns (address[] memory offer_owners);

  /// @notice view on an offer owner.
  /// @param outbound_tkn the outbound token of the offer list.
  /// @param inbound_tkn the inbound token of the offer list.
  /// @param offerId the offer identifier on the offer list.
  /// @return owner the offer maker that can manage the offer.
  /// @dev `ownerOf(in,out,id)` is equivalent to `offerOwners(in, out, [id])` but more gas efficient.
  function ownerOf(IERC20 outbound_tkn, IERC20 inbound_tkn, uint offerId) external view returns (address owner);
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