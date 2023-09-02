// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "mgv_src/MgvLib.sol";

/* The purpose of the Oracle contract is to act as a gas price and density
 * oracle for Mangrove. It bridges to an external oracle, and allows
 * a given sender to update the gas price and density which the oracle
 * reports to Mangrove. */
contract MgvOracle is IMgvMonitor {
  event SetGasprice(uint gasPrice);
  event SetDensity(uint density);

  address governance;
  address mutator;

  uint lastReceivedGasPrice;
  uint lastReceivedDensity;

  constructor(address governance_, address initialMutator_, uint initialGasPrice_) {
    governance = governance_;
    mutator = initialMutator_;

    lastReceivedGasPrice = initialGasPrice_;
    /* Set initial density from the MgvOracle to let Mangrove use its internal density by default.

      Mangrove will reject densities from the Monitor that don't fit in 32 bits and use its internal density instead, so setting this contract's density to `type(uint).max` is a way to let Mangrove deal with density on its own. */
    lastReceivedDensity = type(uint).max;
  }

  /* ## `authOnly` check */
  // NOTE: Should use standard auth method, instead of this copy from MgvGovernable

  function authOnly() internal view {
    require(
      msg.sender == governance || msg.sender == address(this) || governance == address(0), "MgvOracle/unauthorized"
    );
  }

  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker) external override {
    // Do nothing
  }

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external override {
    // Do nothing
  }

  function setGovernance(address governance_) external {
    authOnly();

    governance = governance_;
  }

  function setMutator(address mutator_) external {
    authOnly();

    mutator = mutator_;
  }

  function setGasPrice(uint gasPrice) external {
    // governance or mutator are allowed to update the gasprice
    require(msg.sender == governance || msg.sender == mutator, "MgvOracle/unauthorized");

    lastReceivedGasPrice = gasPrice;
    emit SetGasprice(gasPrice);
  }

  function setDensity(uint density) external {
    // governance or mutator are allowed to update the density
    require(msg.sender == governance || msg.sender == mutator, "MgvOracle/unauthorized");

    lastReceivedDensity = density;
    emit SetDensity(density);
  }

  function read(address, /*outbound_tkn*/ address /*inbound_tkn*/ )
    external
    view
    override
    returns (uint gasprice, uint density)
  {
    return (lastReceivedGasPrice, lastReceivedDensity);
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

uint constant ONES = type(uint).max;

struct OfferUnpacked {
  uint prev;
  uint next;
  uint wants;
  uint gives;
}

//some type safety for each struct
type OfferPacked is uint;
using Library for OfferPacked global;

// number of bits in each field
uint constant prev_bits  = 32;
uint constant next_bits  = 32;
uint constant wants_bits = 96;
uint constant gives_bits = 96;

// number of bits before each field
uint constant prev_before  = 0            + 0;
uint constant next_before  = prev_before  + prev_bits;
uint constant wants_before = next_before  + next_bits;
uint constant gives_before = wants_before + wants_bits;

// focus-mask: 1s at field location, 0s elsewhere
uint constant prev_mask_inv  = (ONES << 256 - prev_bits) >> prev_before;
uint constant next_mask_inv  = (ONES << 256 - next_bits) >> next_before;
uint constant wants_mask_inv = (ONES << 256 - wants_bits) >> wants_before;
uint constant gives_mask_inv = (ONES << 256 - gives_bits) >> gives_before;

// cleanup-mask: 0s at field location, 1s elsewhere
uint constant prev_mask  = ~prev_mask_inv;
uint constant next_mask  = ~next_mask_inv;
uint constant wants_mask = ~wants_mask_inv;
uint constant gives_mask = ~gives_mask_inv;

library Library {
  function to_struct(OfferPacked __packed) internal pure returns (OfferUnpacked memory __s) { unchecked {
    __s.prev  = (OfferPacked.unwrap(__packed) & prev_mask_inv) >> (256 - prev_bits - prev_before);
    __s.next  = (OfferPacked.unwrap(__packed) & next_mask_inv) >> (256 - next_bits - next_before);
    __s.wants = (OfferPacked.unwrap(__packed) & wants_mask_inv) >> (256 - wants_bits - wants_before);
    __s.gives = (OfferPacked.unwrap(__packed) & gives_mask_inv) >> (256 - gives_bits - gives_before);
  }}

  function eq(OfferPacked __packed1, OfferPacked __packed2) internal pure returns (bool) { unchecked {
    return OfferPacked.unwrap(__packed1) == OfferPacked.unwrap(__packed2);
  }}

  function unpack(OfferPacked __packed) internal pure returns (uint __prev, uint __next, uint __wants, uint __gives) { unchecked {
    __prev  = (OfferPacked.unwrap(__packed) & prev_mask_inv) >> (256 - prev_bits - prev_before);
    __next  = (OfferPacked.unwrap(__packed) & next_mask_inv) >> (256 - next_bits - next_before);
    __wants = (OfferPacked.unwrap(__packed) & wants_mask_inv) >> (256 - wants_bits - wants_before);
    __gives = (OfferPacked.unwrap(__packed) & gives_mask_inv) >> (256 - gives_bits - gives_before);
  }}

  function prev(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) & prev_mask_inv) >> (256 - prev_bits - prev_before);
  }}

  function prev(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & prev_mask) | (val << (256 - prev_bits)) >> prev_before);
  }}
  
  function next(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) & next_mask_inv) >> (256 - next_bits - next_before);
  }}

  function next(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & next_mask) | (val << (256 - next_bits)) >> next_before);
  }}
  
  function wants(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) & wants_mask_inv) >> (256 - wants_bits - wants_before);
  }}

  function wants(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & wants_mask) | (val << (256 - wants_bits)) >> wants_before);
  }}
  
  function gives(OfferPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferPacked.unwrap(__packed) & gives_mask_inv) >> (256 - gives_bits - gives_before);
  }}

  function gives(OfferPacked __packed,uint val) internal pure returns(OfferPacked) { unchecked {
    return OfferPacked.wrap((OfferPacked.unwrap(__packed) & gives_mask) | (val << (256 - gives_bits)) >> gives_before);
  }}
  
}

function t_of_struct(OfferUnpacked memory __s) pure returns (OfferPacked) { unchecked {
  return pack(__s.prev, __s.next, __s.wants, __s.gives);
}}

function pack(uint __prev, uint __next, uint __wants, uint __gives) pure returns (OfferPacked) { unchecked {
  uint __packed;
  __packed |= (__prev << (256 - prev_bits)) >> prev_before;
  __packed |= (__next << (256 - next_bits)) >> next_before;
  __packed |= (__wants << (256 - wants_bits)) >> wants_before;
  __packed |= (__gives << (256 - gives_bits)) >> gives_before;
  return OfferPacked.wrap(__packed);
}}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

uint constant ONES = type(uint).max;

struct OfferDetailUnpacked {
  address maker;
  uint gasreq;
  uint offer_gasbase;
  uint gasprice;
}

//some type safety for each struct
type OfferDetailPacked is uint;
using Library for OfferDetailPacked global;

// number of bits in each field
uint constant maker_bits         = 160;
uint constant gasreq_bits        = 24;
uint constant offer_gasbase_bits = 24;
uint constant gasprice_bits      = 16;

// number of bits before each field
uint constant maker_before         = 0                    + 0;
uint constant gasreq_before        = maker_before         + maker_bits;
uint constant offer_gasbase_before = gasreq_before        + gasreq_bits;
uint constant gasprice_before      = offer_gasbase_before + offer_gasbase_bits;

// focus-mask: 1s at field location, 0s elsewhere
uint constant maker_mask_inv         = (ONES << 256 - maker_bits) >> maker_before;
uint constant gasreq_mask_inv        = (ONES << 256 - gasreq_bits) >> gasreq_before;
uint constant offer_gasbase_mask_inv = (ONES << 256 - offer_gasbase_bits) >> offer_gasbase_before;
uint constant gasprice_mask_inv      = (ONES << 256 - gasprice_bits) >> gasprice_before;

// cleanup-mask: 0s at field location, 1s elsewhere
uint constant maker_mask         = ~maker_mask_inv;
uint constant gasreq_mask        = ~gasreq_mask_inv;
uint constant offer_gasbase_mask = ~offer_gasbase_mask_inv;
uint constant gasprice_mask      = ~gasprice_mask_inv;

library Library {
  function to_struct(OfferDetailPacked __packed) internal pure returns (OfferDetailUnpacked memory __s) { unchecked {
    __s.maker         = address(uint160((OfferDetailPacked.unwrap(__packed) & maker_mask_inv) >> (256 - maker_bits - maker_before)));
    __s.gasreq        = (OfferDetailPacked.unwrap(__packed) & gasreq_mask_inv) >> (256 - gasreq_bits - gasreq_before);
    __s.offer_gasbase = (OfferDetailPacked.unwrap(__packed) & offer_gasbase_mask_inv) >> (256 - offer_gasbase_bits - offer_gasbase_before);
    __s.gasprice      = (OfferDetailPacked.unwrap(__packed) & gasprice_mask_inv) >> (256 - gasprice_bits - gasprice_before);
  }}

  function eq(OfferDetailPacked __packed1, OfferDetailPacked __packed2) internal pure returns (bool) { unchecked {
    return OfferDetailPacked.unwrap(__packed1) == OfferDetailPacked.unwrap(__packed2);
  }}

  function unpack(OfferDetailPacked __packed) internal pure returns (address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) { unchecked {
    __maker         = address(uint160((OfferDetailPacked.unwrap(__packed) & maker_mask_inv) >> (256 - maker_bits - maker_before)));
    __gasreq        = (OfferDetailPacked.unwrap(__packed) & gasreq_mask_inv) >> (256 - gasreq_bits - gasreq_before);
    __offer_gasbase = (OfferDetailPacked.unwrap(__packed) & offer_gasbase_mask_inv) >> (256 - offer_gasbase_bits - offer_gasbase_before);
    __gasprice      = (OfferDetailPacked.unwrap(__packed) & gasprice_mask_inv) >> (256 - gasprice_bits - gasprice_before);
  }}

  function maker(OfferDetailPacked __packed) internal pure returns(address) { unchecked {
    return address(uint160((OfferDetailPacked.unwrap(__packed) & maker_mask_inv) >> (256 - maker_bits - maker_before)));
  }}

  function maker(OfferDetailPacked __packed,address val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & maker_mask) | (uint(uint160(val)) << (256 - maker_bits)) >> maker_before);
  }}
  
  function gasreq(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) & gasreq_mask_inv) >> (256 - gasreq_bits - gasreq_before);
  }}

  function gasreq(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & gasreq_mask) | (val << (256 - gasreq_bits)) >> gasreq_before);
  }}
  
  function offer_gasbase(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) & offer_gasbase_mask_inv) >> (256 - offer_gasbase_bits - offer_gasbase_before);
  }}

  function offer_gasbase(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & offer_gasbase_mask) | (val << (256 - offer_gasbase_bits)) >> offer_gasbase_before);
  }}
  
  function gasprice(OfferDetailPacked __packed) internal pure returns(uint) { unchecked {
    return (OfferDetailPacked.unwrap(__packed) & gasprice_mask_inv) >> (256 - gasprice_bits - gasprice_before);
  }}

  function gasprice(OfferDetailPacked __packed,uint val) internal pure returns(OfferDetailPacked) { unchecked {
    return OfferDetailPacked.wrap((OfferDetailPacked.unwrap(__packed) & gasprice_mask) | (val << (256 - gasprice_bits)) >> gasprice_before);
  }}
  
}

function t_of_struct(OfferDetailUnpacked memory __s) pure returns (OfferDetailPacked) { unchecked {
  return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
}}

function pack(address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) pure returns (OfferDetailPacked) { unchecked {
  uint __packed;
  __packed |= (uint(uint160(__maker)) << (256 - maker_bits)) >> maker_before;
  __packed |= (__gasreq << (256 - gasreq_bits)) >> gasreq_before;
  __packed |= (__offer_gasbase << (256 - offer_gasbase_bits)) >> offer_gasbase_before;
  __packed |= (__gasprice << (256 - gasprice_bits)) >> gasprice_before;
  return OfferDetailPacked.wrap(__packed);
}}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

uint constant ONES = type(uint).max;

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

// number of bits in each field
uint constant monitor_bits   = 160;
uint constant useOracle_bits = 1;
uint constant notify_bits    = 1;
uint constant gasprice_bits  = 16;
uint constant gasmax_bits    = 24;
uint constant dead_bits      = 1;

// number of bits before each field
uint constant monitor_before   = 0                + 0;
uint constant useOracle_before = monitor_before   + monitor_bits;
uint constant notify_before    = useOracle_before + useOracle_bits;
uint constant gasprice_before  = notify_before    + notify_bits;
uint constant gasmax_before    = gasprice_before  + gasprice_bits;
uint constant dead_before      = gasmax_before    + gasmax_bits;

// focus-mask: 1s at field location, 0s elsewhere
uint constant monitor_mask_inv   = (ONES << 256 - monitor_bits) >> monitor_before;
uint constant useOracle_mask_inv = (ONES << 256 - useOracle_bits) >> useOracle_before;
uint constant notify_mask_inv    = (ONES << 256 - notify_bits) >> notify_before;
uint constant gasprice_mask_inv  = (ONES << 256 - gasprice_bits) >> gasprice_before;
uint constant gasmax_mask_inv    = (ONES << 256 - gasmax_bits) >> gasmax_before;
uint constant dead_mask_inv      = (ONES << 256 - dead_bits) >> dead_before;

// cleanup-mask: 0s at field location, 1s elsewhere
uint constant monitor_mask   = ~monitor_mask_inv;
uint constant useOracle_mask = ~useOracle_mask_inv;
uint constant notify_mask    = ~notify_mask_inv;
uint constant gasprice_mask  = ~gasprice_mask_inv;
uint constant gasmax_mask    = ~gasmax_mask_inv;
uint constant dead_mask      = ~dead_mask_inv;

library Library {
  function to_struct(GlobalPacked __packed) internal pure returns (GlobalUnpacked memory __s) { unchecked {
    __s.monitor   = address(uint160((GlobalPacked.unwrap(__packed) & monitor_mask_inv) >> (256 - monitor_bits - monitor_before)));
    __s.useOracle = ((GlobalPacked.unwrap(__packed) & useOracle_mask_inv) > 0);
    __s.notify    = ((GlobalPacked.unwrap(__packed) & notify_mask_inv) > 0);
    __s.gasprice  = (GlobalPacked.unwrap(__packed) & gasprice_mask_inv) >> (256 - gasprice_bits - gasprice_before);
    __s.gasmax    = (GlobalPacked.unwrap(__packed) & gasmax_mask_inv) >> (256 - gasmax_bits - gasmax_before);
    __s.dead      = ((GlobalPacked.unwrap(__packed) & dead_mask_inv) > 0);
  }}

  function eq(GlobalPacked __packed1, GlobalPacked __packed2) internal pure returns (bool) { unchecked {
    return GlobalPacked.unwrap(__packed1) == GlobalPacked.unwrap(__packed2);
  }}

  function unpack(GlobalPacked __packed) internal pure returns (address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) { unchecked {
    __monitor   = address(uint160((GlobalPacked.unwrap(__packed) & monitor_mask_inv) >> (256 - monitor_bits - monitor_before)));
    __useOracle = ((GlobalPacked.unwrap(__packed) & useOracle_mask_inv) > 0);
    __notify    = ((GlobalPacked.unwrap(__packed) & notify_mask_inv) > 0);
    __gasprice  = (GlobalPacked.unwrap(__packed) & gasprice_mask_inv) >> (256 - gasprice_bits - gasprice_before);
    __gasmax    = (GlobalPacked.unwrap(__packed) & gasmax_mask_inv) >> (256 - gasmax_bits - gasmax_before);
    __dead      = ((GlobalPacked.unwrap(__packed) & dead_mask_inv) > 0);
  }}

  function monitor(GlobalPacked __packed) internal pure returns(address) { unchecked {
    return address(uint160((GlobalPacked.unwrap(__packed) & monitor_mask_inv) >> (256 - monitor_bits - monitor_before)));
  }}

  function monitor(GlobalPacked __packed,address val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & monitor_mask) | (uint(uint160(val)) << (256 - monitor_bits)) >> monitor_before);
  }}
  
  function useOracle(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return ((GlobalPacked.unwrap(__packed) & useOracle_mask_inv) > 0);
  }}

  function useOracle(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & useOracle_mask) | (uint_of_bool(val) << (256 - useOracle_bits)) >> useOracle_before);
  }}
  
  function notify(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return ((GlobalPacked.unwrap(__packed) & notify_mask_inv) > 0);
  }}

  function notify(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & notify_mask) | (uint_of_bool(val) << (256 - notify_bits)) >> notify_before);
  }}
  
  function gasprice(GlobalPacked __packed) internal pure returns(uint) { unchecked {
    return (GlobalPacked.unwrap(__packed) & gasprice_mask_inv) >> (256 - gasprice_bits - gasprice_before);
  }}

  function gasprice(GlobalPacked __packed,uint val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & gasprice_mask) | (val << (256 - gasprice_bits)) >> gasprice_before);
  }}
  
  function gasmax(GlobalPacked __packed) internal pure returns(uint) { unchecked {
    return (GlobalPacked.unwrap(__packed) & gasmax_mask_inv) >> (256 - gasmax_bits - gasmax_before);
  }}

  function gasmax(GlobalPacked __packed,uint val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & gasmax_mask) | (val << (256 - gasmax_bits)) >> gasmax_before);
  }}
  
  function dead(GlobalPacked __packed) internal pure returns(bool) { unchecked {
    return ((GlobalPacked.unwrap(__packed) & dead_mask_inv) > 0);
  }}

  function dead(GlobalPacked __packed,bool val) internal pure returns(GlobalPacked) { unchecked {
    return GlobalPacked.wrap((GlobalPacked.unwrap(__packed) & dead_mask) | (uint_of_bool(val) << (256 - dead_bits)) >> dead_before);
  }}
  
}

function t_of_struct(GlobalUnpacked memory __s) pure returns (GlobalPacked) { unchecked {
  return pack(__s.monitor, __s.useOracle, __s.notify, __s.gasprice, __s.gasmax, __s.dead);
}}

function pack(address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) pure returns (GlobalPacked) { unchecked {
  uint __packed;
  __packed |= (uint(uint160(__monitor)) << (256 - monitor_bits)) >> monitor_before;
  __packed |= (uint_of_bool(__useOracle) << (256 - useOracle_bits)) >> useOracle_before;
  __packed |= (uint_of_bool(__notify) << (256 - notify_bits)) >> notify_before;
  __packed |= (__gasprice << (256 - gasprice_bits)) >> gasprice_before;
  __packed |= (__gasmax << (256 - gasmax_bits)) >> gasmax_before;
  __packed |= (uint_of_bool(__dead) << (256 - dead_bits)) >> dead_before;
  return GlobalPacked.wrap(__packed);
}}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

uint constant ONES = type(uint).max;

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

// number of bits in each field
uint constant active_bits        = 1;
uint constant fee_bits           = 16;
uint constant density_bits       = 112;
uint constant offer_gasbase_bits = 24;
uint constant lock_bits          = 1;
uint constant best_bits          = 32;
uint constant last_bits          = 32;

// number of bits before each field
uint constant active_before        = 0                    + 0;
uint constant fee_before           = active_before        + active_bits;
uint constant density_before       = fee_before           + fee_bits;
uint constant offer_gasbase_before = density_before       + density_bits;
uint constant lock_before          = offer_gasbase_before + offer_gasbase_bits;
uint constant best_before          = lock_before          + lock_bits;
uint constant last_before          = best_before          + best_bits;

// focus-mask: 1s at field location, 0s elsewhere
uint constant active_mask_inv        = (ONES << 256 - active_bits) >> active_before;
uint constant fee_mask_inv           = (ONES << 256 - fee_bits) >> fee_before;
uint constant density_mask_inv       = (ONES << 256 - density_bits) >> density_before;
uint constant offer_gasbase_mask_inv = (ONES << 256 - offer_gasbase_bits) >> offer_gasbase_before;
uint constant lock_mask_inv          = (ONES << 256 - lock_bits) >> lock_before;
uint constant best_mask_inv          = (ONES << 256 - best_bits) >> best_before;
uint constant last_mask_inv          = (ONES << 256 - last_bits) >> last_before;

// cleanup-mask: 0s at field location, 1s elsewhere
uint constant active_mask        = ~active_mask_inv;
uint constant fee_mask           = ~fee_mask_inv;
uint constant density_mask       = ~density_mask_inv;
uint constant offer_gasbase_mask = ~offer_gasbase_mask_inv;
uint constant lock_mask          = ~lock_mask_inv;
uint constant best_mask          = ~best_mask_inv;
uint constant last_mask          = ~last_mask_inv;

library Library {
  function to_struct(LocalPacked __packed) internal pure returns (LocalUnpacked memory __s) { unchecked {
    __s.active        = ((LocalPacked.unwrap(__packed) & active_mask_inv) > 0);
    __s.fee           = (LocalPacked.unwrap(__packed) & fee_mask_inv) >> (256 - fee_bits - fee_before);
    __s.density       = (LocalPacked.unwrap(__packed) & density_mask_inv) >> (256 - density_bits - density_before);
    __s.offer_gasbase = (LocalPacked.unwrap(__packed) & offer_gasbase_mask_inv) >> (256 - offer_gasbase_bits - offer_gasbase_before);
    __s.lock          = ((LocalPacked.unwrap(__packed) & lock_mask_inv) > 0);
    __s.best          = (LocalPacked.unwrap(__packed) & best_mask_inv) >> (256 - best_bits - best_before);
    __s.last          = (LocalPacked.unwrap(__packed) & last_mask_inv) >> (256 - last_bits - last_before);
  }}

  function eq(LocalPacked __packed1, LocalPacked __packed2) internal pure returns (bool) { unchecked {
    return LocalPacked.unwrap(__packed1) == LocalPacked.unwrap(__packed2);
  }}

  function unpack(LocalPacked __packed) internal pure returns (bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) { unchecked {
    __active        = ((LocalPacked.unwrap(__packed) & active_mask_inv) > 0);
    __fee           = (LocalPacked.unwrap(__packed) & fee_mask_inv) >> (256 - fee_bits - fee_before);
    __density       = (LocalPacked.unwrap(__packed) & density_mask_inv) >> (256 - density_bits - density_before);
    __offer_gasbase = (LocalPacked.unwrap(__packed) & offer_gasbase_mask_inv) >> (256 - offer_gasbase_bits - offer_gasbase_before);
    __lock          = ((LocalPacked.unwrap(__packed) & lock_mask_inv) > 0);
    __best          = (LocalPacked.unwrap(__packed) & best_mask_inv) >> (256 - best_bits - best_before);
    __last          = (LocalPacked.unwrap(__packed) & last_mask_inv) >> (256 - last_bits - last_before);
  }}

  function active(LocalPacked __packed) internal pure returns(bool) { unchecked {
    return ((LocalPacked.unwrap(__packed) & active_mask_inv) > 0);
  }}

  function active(LocalPacked __packed,bool val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & active_mask) | (uint_of_bool(val) << (256 - active_bits)) >> active_before);
  }}
  
  function fee(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) & fee_mask_inv) >> (256 - fee_bits - fee_before);
  }}

  function fee(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & fee_mask) | (val << (256 - fee_bits)) >> fee_before);
  }}
  
  function density(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) & density_mask_inv) >> (256 - density_bits - density_before);
  }}

  function density(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & density_mask) | (val << (256 - density_bits)) >> density_before);
  }}
  
  function offer_gasbase(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) & offer_gasbase_mask_inv) >> (256 - offer_gasbase_bits - offer_gasbase_before);
  }}

  function offer_gasbase(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & offer_gasbase_mask) | (val << (256 - offer_gasbase_bits)) >> offer_gasbase_before);
  }}
  
  function lock(LocalPacked __packed) internal pure returns(bool) { unchecked {
    return ((LocalPacked.unwrap(__packed) & lock_mask_inv) > 0);
  }}

  function lock(LocalPacked __packed,bool val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & lock_mask) | (uint_of_bool(val) << (256 - lock_bits)) >> lock_before);
  }}
  
  function best(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) & best_mask_inv) >> (256 - best_bits - best_before);
  }}

  function best(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & best_mask) | (val << (256 - best_bits)) >> best_before);
  }}
  
  function last(LocalPacked __packed) internal pure returns(uint) { unchecked {
    return (LocalPacked.unwrap(__packed) & last_mask_inv) >> (256 - last_bits - last_before);
  }}

  function last(LocalPacked __packed,uint val) internal pure returns(LocalPacked) { unchecked {
    return LocalPacked.wrap((LocalPacked.unwrap(__packed) & last_mask) | (val << (256 - last_bits)) >> last_before);
  }}
  
}

function t_of_struct(LocalUnpacked memory __s) pure returns (LocalPacked) { unchecked {
  return pack(__s.active, __s.fee, __s.density, __s.offer_gasbase, __s.lock, __s.best, __s.last);
}}

function pack(bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) pure returns (LocalPacked) { unchecked {
  uint __packed;
  __packed |= (uint_of_bool(__active) << (256 - active_bits)) >> active_before;
  __packed |= (__fee << (256 - fee_bits)) >> fee_before;
  __packed |= (__density << (256 - density_bits)) >> density_before;
  __packed |= (__offer_gasbase << (256 - offer_gasbase_bits)) >> offer_gasbase_before;
  __packed |= (uint_of_bool(__lock) << (256 - lock_bits)) >> lock_before;
  __packed |= (__best << (256 - best_bits)) >> best_before;
  __packed |= (__last << (256 - last_bits)) >> last_before;
  return LocalPacked.wrap(__packed);
}}