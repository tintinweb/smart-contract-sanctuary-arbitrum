// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool success);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

import "./IWETH.sol";
import "./IWormhole.sol";

interface ITokenBridge {
    struct Transfer {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        uint256 fee;
    }

    struct TransferWithPayload {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        bytes32 fromAddress;
        bytes payload;
    }

    struct AssetMeta {
        uint8 payloadID;
        bytes32 tokenAddress;
        uint16 tokenChain;
        uint8 decimals;
        bytes32 symbol;
        bytes32 name;
    }

    struct RegisterChain {
        bytes32 module;
        uint8 action;
        uint16 chainId;

        uint16 emitterChainID;
        bytes32 emitterAddress;
    }

     struct UpgradeContract {
        bytes32 module;
        uint8 action;
        uint16 chainId;

        bytes32 newContract;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    event TransferRedeemed(uint16 indexed emitterChainId, bytes32 indexed emitterAddress, uint64 indexed sequence);

    function _parseTransferCommon(bytes memory encoded) external pure returns (Transfer memory transfer);

    function attestToken(address tokenAddress, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETHWithPayload(uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable returns (uint64 sequence);

    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function transferTokensWithPayload(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable returns (uint64 sequence);

    function updateWrapped(bytes memory encodedVm) external returns (address token);

    function createWrapped(bytes memory encodedVm) external returns (address token);

    function completeTransferWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransferAndUnwrapETHWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransfer(bytes memory encodedVm) external;

    function completeTransferAndUnwrapETH(bytes memory encodedVm) external;

    function encodeAssetMeta(AssetMeta memory meta) external pure returns (bytes memory encoded);

    function encodeTransfer(Transfer memory transfer) external pure returns (bytes memory encoded);

    function encodeTransferWithPayload(TransferWithPayload memory transfer) external pure returns (bytes memory encoded);

    function parsePayloadID(bytes memory encoded) external pure returns (uint8 payloadID);

    function parseAssetMeta(bytes memory encoded) external pure returns (AssetMeta memory meta);

    function parseTransfer(bytes memory encoded) external pure returns (Transfer memory transfer);

    function parseTransferWithPayload(bytes memory encoded) external pure returns (TransferWithPayload memory transfer);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function isTransferCompleted(bytes32 hash) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function evmChainId() external view returns (uint256);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) external view returns (address);

    function bridgeContracts(uint16 chainId_) external view returns (bytes32);

    function tokenImplementation() external view returns (address);

    function WETH() external view returns (IWETH);

    function outstandingBridged(address token) external view returns (uint256);

    function isWrappedAsset(address token) external view returns (bool);

    function finality() external view returns (uint8);

    function implementation() external view returns (address);

    function initialize() external;

    function registerChain(bytes memory encodedVM) external;

    function upgrade(bytes memory encodedVM) external;

    function submitRecoverChainId(bytes memory encodedVM) external;

    function parseRegisterChain(bytes memory encoded) external pure returns (RegisterChain memory chain);

    function parseUpgrade(bytes memory encoded) external pure returns (UpgradeContract memory chain);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

interface IWormhole {
  struct GuardianSet {
    address[] keys;
    uint32 expirationTime;
  }

  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint8 guardianIndex;
  }

  /**
  struct Signature {
    uint8 index;
    bytes signature;
    string name;
  }
   */

  struct VM {
    uint8 version;
    uint32 timestamp;
    uint32 nonce;
    uint16 emitterChainId;
    bytes32 emitterAddress;
    uint64 sequence;
    uint8 consistencyLevel;
    bytes payload;
    uint32 guardianSetIndex;
    Signature[] signatures;
    bytes32 hash;
  }

  struct ContractUpgrade {
    bytes32 module;
    uint8 action;
    uint16 chain;
    address newContract;
  }

  struct GuardianSetUpgrade {
    bytes32 module;
    uint8 action;
    uint16 chain;
    GuardianSet newGuardianSet;
    uint32 newGuardianSetIndex;
  }

  struct SetMessageFee {
    bytes32 module;
    uint8 action;
    uint16 chain;
    uint256 messageFee;
  }

  struct TransferFees {
    bytes32 module;
    uint8 action;
    uint16 chain;
    uint256 amount;
    bytes32 recipient;
  }

  struct RecoverChainId {
    bytes32 module;
    uint8 action;
    uint256 evmChainId;
    uint16 newChainId;
  }

  event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
  event ContractUpgraded(address indexed oldContract, address indexed newContract);
  event GuardianSetAdded(uint32 indexed index);

  function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel) external payable returns (uint64 sequence);

  function testSigs() external returns (Signature[] memory signatures);

  function test8() external returns (uint8 test);

  function testBytes() external returns (bytes memory payload);

  function testBigKahuna() external returns (VM memory vm);

  function initialize() external;

  function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

  function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

  function verifySignatures(
    bytes32 hash,
    Signature[] memory signatures,
    GuardianSet memory guardianSet
  ) external pure returns (bool valid, string memory reason);

  function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

  function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

  function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

  function getCurrentGuardianSetIndex() external view returns (uint32);

  function getGuardianSetExpiry() external view returns (uint32);

  function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

  function isInitialized(address impl) external view returns (bool);

  function chainId() external view returns (uint16);

  function isFork() external view returns (bool);

  function governanceChainId() external view returns (uint16);

  function governanceContract() external view returns (bytes32);

  function messageFee() external view returns (uint256);

  function evmChainId() external view returns (uint256);

  function nextSequence(address emitter) external view returns (uint64);

  function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

  function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

  function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

  function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

  function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

  function submitContractUpgrade(bytes memory _vm) external;

  function submitSetMessageFee(bytes memory _vm) external;

  function submitNewGuardianSet(bytes memory _vm) external;

  function submitTransferFees(bytes memory _vm) external;

  function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

import "./PorticoStructs.sol";
import "./ITokenBridge.sol";
import "./IWormhole.sol";
import "./IERC20.sol";
import "./IWETH.sol";

//uniswap
import "./uniswap/TickMath.sol";
import "./uniswap/ISwapRouter02.sol";
import "./uniswap/IV3Pool.sol";
import "./uniswap/PoolAddress.sol";

using PorticoFlagSetAccess for PorticoFlagSet;

contract PorticoBase {
  using PorticoFlagSetAccess for PorticoFlagSet;

  ISwapRouter02 public immutable ROUTERV3;
  ITokenBridge public immutable TOKENBRIDGE;
  IWETH public immutable WETH;

  IWormhole public immutable wormhole;

  uint16 public immutable wormholeChainId;

  constructor(ISwapRouter02 _routerV3, ITokenBridge _bridge, IWETH _weth) {
    ROUTERV3 = _routerV3;
    TOKENBRIDGE = _bridge;
    wormhole = _bridge.wormhole();
    WETH = _weth;
    wormholeChainId = wormhole.chainId();
  }

  receive() external payable {}

  function version() external pure returns (uint32) {
    return 1;
  }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function padAddress(address addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
  }

  function unpadAddress(bytes32 whFormatAddress) internal pure returns (address) {
    return address(uint160(uint256(whFormatAddress)));
  }

  function isContract(address _addr) private view returns (bool value) {
    uint32 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }

  function calcMinAmount(
    uint256 amountIn,
    uint16 maxSlippage,
    address tokenIn,
    address tokenOut,
    uint24 fee
  ) internal view returns (uint256 minAmoutReceived) {
    //10000 bips == 100% slippage is allowed
    uint16 MAX_BIPS = 10000;
    if (maxSlippage >= MAX_BIPS || maxSlippage == 0) {
      return 0;
    }

    //compute pool
    PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(tokenIn, tokenOut, fee);
    IV3Pool pool = IV3Pool(PoolAddress.computeAddress(ROUTERV3.factory(), key));

    if (!isContract(address(pool))) {
      return 0;
    }

    //get exchange rate
    uint256 exchangeRate = getExchangeRate(sqrtPrice(pool));

    //invert exchange rate if needed
    if (tokenIn != key.token0) {
      exchangeRate = divide(1e18, exchangeRate, 18);
    }

    //compute expected amount received with no slippage
    uint256 expectedAmount = (amountIn * exchangeRate) / 1e18;

    maxSlippage = MAX_BIPS - maxSlippage;

    minAmoutReceived = (expectedAmount * maxSlippage) / MAX_BIPS;
  }

  ///@return exchangeRate == (sqrtPriceX96 / 2**96) ** 2
  function getExchangeRate(uint160 sqrtPriceX96) internal pure returns (uint256 exchangeRate) {
    return (divide(uint256(sqrtPriceX96), (2 ** 96), 18) ** 2) / 1e18;
  }

  ///@notice floating point division at @param factor scale
  function divide(uint256 numerator, uint256 denominator, uint256 factor) internal pure returns (uint256 result) {
    uint256 q = (numerator / denominator) * 10 ** factor;
    uint256 r = ((numerator * 10 ** factor) / denominator) % 10 ** factor;

    return q + r;
  }

  function sqrtPrice(IV3Pool pool) internal view returns (uint160) {
    //get current tick via slot0
    try pool.slot0() returns (
      uint160 sqrtPriceX96,
      int24 /*tick*/,
      uint16 /*observationIndex*/,
      uint16 /*observationCardinality*/,
      uint16 /*observationCardinalityNext*/,
      uint8 /*feeProtocol*/,
      bool /*unlocked*/
    ) {
      return sqrtPriceX96;
    } catch {
      return 0;
    }
  }
}

abstract contract PorticoStart is PorticoBase {
  function _start_v3swap(PorticoStructs.TradeParameters memory params, uint256 actualAmount) internal returns (uint256 amount) {
    require(params.startTokenAddress.approve(address(ROUTERV3), params.startTokenAddress.balanceOf(address(this))), "Approve fail");

    uint256 minAmountOut = calcMinAmount(
      uint256(params.amountSpecified),
      uint16(params.flags.maxSlippageFinish()),
      address(params.startTokenAddress),
      address(params.canonAssetAddress),
      params.flags.feeTierStart()
    );

    //no deadline
    ROUTERV3.exactInputSingle(
      ISwapRouter02.ExactInputSingleParams(
        address(params.startTokenAddress), // tokenIn
        address(params.canonAssetAddress), //tokenOut
        params.flags.feeTierStart(), //fee
        address(this), //recipient
        actualAmount, //amountIn
        minAmountOut, //minAmountReceived
        0
      )
    );
    amount = params.canonAssetAddress.balanceOf(address(this));
  }

  event PorticoSwapStart(uint64 indexed sequence, uint16 indexed chainId);

  function start(
    PorticoStructs.TradeParameters memory params
  ) public payable returns (address emitterAddress, uint16 chainId, uint64 sequence) {
    // always check for native wrapping logic
    if (address(params.startTokenAddress) == address(WETH) && params.flags.shouldWrapNative()) {
      // if we are wrapping a token, we call deposit for the user, assuming we have been send what we need.
      WETH.deposit{ value: uint256(params.amountSpecified) }();
    } else {
      // otherwise, just get the token we need to do the swap (if we are swapping, or just the token itself)
      require(params.startTokenAddress.transferFrom(_msgSender(), address(this), uint256(params.amountSpecified)), "transfer fail");
    }

    //Because wormhole rounds to 1e8, some dust may exist from previous txs
    //we use balanceOf to lump this in with future txs
    uint256 amount = params.startTokenAddress.balanceOf(address(this));

    //ensure we received enough
    require(amount >= uint256(params.amountSpecified), "transfer insufficient");

    // if the start token is the canon token, we don't need to swap
    if (params.startTokenAddress != params.canonAssetAddress) {
      // do the swap, and amount is now the amount that we received from the swap
      amount = _start_v3swap(params, amount);
    }

    // allow the token bridge to do its token bridge things
    IERC20(params.canonAssetAddress).approve(address(TOKENBRIDGE), amount);

    // now we need to produce the payload we are sending
    PorticoStructs.DecodedVAA memory decodedVAA = PorticoStructs.DecodedVAA(
      params.flags,
      params.finalTokenAddress,
      params.recipientAddress,
      amount,
      params.relayerFee
    );

    sequence = TOKENBRIDGE.transferTokensWithPayload{ value: wormhole.messageFee() }(
      address(params.canonAssetAddress),
      amount,
      params.flags.recipientChain(),
      padAddress(params.recipientPorticoAddress),
      params.flags.bridgeNonce(),
      abi.encode(decodedVAA)
    );
    chainId = wormholeChainId;
    emitterAddress = address(TOKENBRIDGE);
    emit PorticoSwapStart(sequence, chainId);
  }
}

abstract contract PorticoFinish is PorticoBase {
  event PorticoSwapFinish(bool swapCompleted, PorticoStructs.DecodedVAA data);

  // receiveMessageAndSwap is the entrypoint for finishing the swap
  function receiveMessageAndSwap(bytes calldata encodedTransferMessage) external payable {
    // start by calling _completeTransfer, submitting the VAA to the token bridge
    (PorticoStructs.DecodedVAA memory message, PorticoStructs.BridgeInfo memory bridgeInfo) = _completeTransfer(encodedTransferMessage);
    // we modify the message to set the relayerFee to 0 if the msgSender is the fee recipient.
    bridgeInfo.relayerFeeAmount = (_msgSender() == message.recipientAddress) ? 0 : message.relayerFee;

    //now process
    bool swapCompleted = finish(message, bridgeInfo);
    // simply emit the raw data bytes. it should be trivial to parse.
    emit PorticoSwapFinish(swapCompleted, message);
  }

  // _completeTransfer takes the vaa for a payload3 token transfer, redeems it with the token bridge, and returns the decoded vaa payload
  function _completeTransfer(
    bytes calldata encodedTransferMessage
  ) internal returns (PorticoStructs.DecodedVAA memory message, PorticoStructs.BridgeInfo memory bridgeInfo) {
    /**
     * Call `completeTransferWithPayload` on the token bridge. This
     * method acts as a reentrancy protection since it does not allow
     * transfers to be redeemed more than once.
     */
    bytes memory transferPayload = TOKENBRIDGE.completeTransferWithPayload(encodedTransferMessage);

    // parse the wormhole message payload into the `TransferWithPayload` struct, a payload3 token transfer
    ITokenBridge.TransferWithPayload memory transfer = TOKENBRIDGE.parseTransferWithPayload(transferPayload);

    // decode the payload3 we originally sent into the decodedVAA struct.
    message = abi.decode(transfer.payload, (PorticoStructs.DecodedVAA));


    // get the address for the token on this address.
    bridgeInfo.tokenReceived = IERC20(
      transfer.tokenChain == wormholeChainId
        ? unpadAddress(transfer.tokenAddress)
        : TOKENBRIDGE.wrappedAsset(transfer.tokenChain, transfer.tokenAddress)
    );
    // put the transfer amount into amountReceived, knowing we may need to change it in a sec
    bridgeInfo.amountReceived = transfer.amount;

    // if there are more than 8 decimals, we need to denormalize. wormhole token bridge truncates tokens of more than 8 decimals to 8 decimals.
    uint8 decimals = bridgeInfo.tokenReceived.decimals();
    if (decimals > 8) {
      bridgeInfo.amountReceived *= uint256(10) ** (decimals - 8);
    }

    // ensure that the to address is this address
    require(unpadAddress(transfer.to) == address(this) && transfer.toChain == wormholeChainId, "Token was not sent to this address");
  }

  ///@notice determines we need to swap and/or unwrap, does those things if needed, and sends tokens to user & pays relayer fee
  function finish(
    PorticoStructs.DecodedVAA memory params,
    PorticoStructs.BridgeInfo memory bridgeInfo
  ) internal returns (bool swapCompleted) {
    // see if the unwrap flag is set, and that the finalTokenAddress is the address we have set on deploy as our native weth9 address
    bool shouldUnwrap = params.flags.shouldUnwrapNative() && address(params.finalTokenAddress) == address(WETH);
    if ((params.finalTokenAddress) == bridgeInfo.tokenReceived) {
      // this means that we don't need to do a swap, aka, we received the canon asset.
      payOut(shouldUnwrap, params.finalTokenAddress, params.recipientAddress, bridgeInfo.relayerFeeAmount);
      return false;
    }
    //if we are here, if means we need to do the swap, resulting aset is sent to this address
    swapCompleted = _finish_v3swap(params, bridgeInfo);
    //if swap fails, relayer and user have already been paid in canon asset, so we are done
    if (!swapCompleted) {
      return swapCompleted;
    }
    // we must call payout if the swap was completed
    payOut(shouldUnwrap, params.finalTokenAddress, params.recipientAddress, bridgeInfo.relayerFeeAmount);
  }

  // if swap fails, we don't pay fees to the relayer
  // the reason is because that typically, the swap fails because of bad market conditions
  // in this case, it is in the best interest of the mev/relayer to NOT relay this message until conditions are good
  // the user of course, who if they self relay, does not pay a fee, does not have this problem, so they can force this if they wish
  // swap failed - return canon asset to recipient
  // it will return true if the swap was completed, indicating that funds need to be sent from this contract to the recipient
  function _finish_v3swap(
    PorticoStructs.DecodedVAA memory params,
    PorticoStructs.BridgeInfo memory bridgeInfo
  ) internal returns (bool swapCompleted) {
    bridgeInfo.tokenReceived.approve(address(ROUTERV3), bridgeInfo.amountReceived);

    uint256 minAmountOut = calcMinAmount(
      bridgeInfo.amountReceived,
      uint16(params.flags.maxSlippageFinish()),
      address(bridgeInfo.tokenReceived),
      address(params.finalTokenAddress),
      params.flags.feeTierFinish()
    );


    // set swap options with user params
    //no deadline
    ISwapRouter02.ExactInputSingleParams memory swapParams = ISwapRouter02.ExactInputSingleParams({
      tokenIn: address(bridgeInfo.tokenReceived),
      tokenOut: address(params.finalTokenAddress),
      fee: params.flags.feeTierFinish(),
      recipient: address(this), // we need to receive the token in order to correctly split the fee. tragic.
      amountIn: bridgeInfo.amountReceived,
      amountOutMinimum: minAmountOut,
      sqrtPriceLimitX96: 0 //sqrtPriceLimit
    });

    // try to do the swap
    try ROUTERV3.exactInputSingle(swapParams) {
      swapCompleted = true;
    } catch /**Error(string memory e) */ {
      // if the swap fails, we just transfer the amount we received from the token bridge to the recipientAddress.
      // we also mark swapCompleted to be false, so that we don't try to payout to the recipient
      bridgeInfo.tokenReceived.transfer(params.recipientAddress, bridgeInfo.amountReceived);
      swapCompleted = false;
    }
  }

  ///@notice pay out to user and relayer
  ///@notice this should always be called UNLESS swap fails, in which case payouts happen there
  function payOut(bool unwrap, IERC20 finalToken, address recipient, uint256 relayerFeeAmount) internal {
    //square up balances with what we actually have, don't trust reporting from the bridge
    //user gets total - relayer fee
    uint256 finalUserAmount = finalToken.balanceOf(address(this)) - relayerFeeAmount;

    if (unwrap) {
      WETH.withdraw(IERC20(address(WETH)).balanceOf(address(this)));
      //send to user
      if (finalUserAmount > 0) {
        (bool sentToUser, ) = recipient.call{ value: finalUserAmount }("");
        require(sentToUser, "Failed to send Ether");
      }
      if (relayerFeeAmount > 0) {
        //pay relayer fee
        (bool sentToRelayer, ) = _msgSender().call{ value: relayerFeeAmount }("");
        require(sentToRelayer, "Failed to send Ether");
      }
    } else {
      //pay recipient
      if (finalUserAmount > 0) {
        require(finalToken.transfer(recipient, finalUserAmount), "STF");
      }
      if (relayerFeeAmount > 0) {
        //pay relayer
        require(finalToken.transfer(_msgSender(), relayerFeeAmount), "STF");
      }
    }
  }
}

contract Portico is PorticoFinish, PorticoStart {
  constructor(ISwapRouter02 _routerV3, ITokenBridge _bridge, IWETH _weth) PorticoBase(_routerV3, _bridge, _weth) {}
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.9;

import "./IERC20.sol";

type PorticoFlagSet is bytes32;

library PorticoFlagSetAccess {
  // the portico uses one word (32 bytes) to represent a large amount of variables

  // bytes 0-1 is the recipient chain
  function recipientChain(PorticoFlagSet flagset) internal pure returns (uint16 ans) {
    assembly {
      ans := add(byte(0, flagset), shl(8, byte(1, flagset)))
    }
  }

  // bytes 2-5 is the bridge nonce
  function bridgeNonce(PorticoFlagSet flagset) internal pure returns (uint32 ans) {
    assembly {
      ans := add(add(add(byte(2, flagset), shl(8, byte(3, flagset))), shl(16, byte(4, flagset))), shl(24, byte(5, flagset)))
    }
  }

  // bytes 6,7,8 is the fee tier for start path
  function feeTierStart(PorticoFlagSet flagset) internal pure returns (uint24 ans) {
    assembly {
      ans := add(add(byte(6, flagset), shl(8, byte(7, flagset))), shl(16, byte(8, flagset)))
    }
  }

  // bytes 9,10,11 is the fee tier for finish path
  function feeTierFinish(PorticoFlagSet flagset) internal pure returns (uint24 ans) {
    assembly {
      ans := add(add(byte(9, flagset), shl(8, byte(10, flagset))), shl(16, byte(11, flagset)))
    }
  }

  // bytes 12,13 is the max slippage for the start path
  // in BPS - 100 = 1% slippage.
  function maxSlippageStart(PorticoFlagSet flagset) internal pure returns (int16 ans) {
    assembly {
      ans := add(byte(12, flagset), shl(8, byte(13, flagset)))
    }
  }

  // bytes 14,15 is the max slippage for the start path
  // in BPS - 100 = 1% slippage.
  function maxSlippageFinish(PorticoFlagSet flagset) internal pure returns (int16 ans) {
    assembly {
      ans := add(byte(14, flagset), shl(8, byte(15, flagset)))
    }
  }

  // shouldWrapNative is the first bit of the byte 31
  function shouldWrapNative(PorticoFlagSet flagset) internal pure returns (bool) {
    bytes32 fs = PorticoFlagSet.unwrap(flagset);
    return uint8(fs[31]) & (1 << 0) > 0;
  }

  // shouldUnwrapNative is the second bit of byte 31
  function shouldUnwrapNative(PorticoFlagSet flagset) internal pure returns (bool) {
    bytes32 fs = PorticoFlagSet.unwrap(flagset);
    return uint8(fs[31]) & (1 << 1) > 0;
  }
}

library PorticoStructs {
  //16 + 32 + 24 + 24 + 16 + 16 + 8 + 8 == 144
  struct packedData {
    uint16 recipientChain;
    uint32 bridgeNonce;
    uint24 startFee;
    uint24 endFee;
    int16 slipStart;
    int16 slipEnd;
    bool wrap;
    bool unwrap;
  }

  //https://github.com/wormhole-foundation/wormhole-solidity-sdk/blob/main/src/WormholeRelayerSDK.sol#L177
  //https://docs.wormhole.com/wormhole/quick-start/tutorials/hello-token#receiving-a-token
  struct TokenReceived {
    bytes32 tokenHomeAddress;
    uint16 tokenHomeChain;
    IERC20 tokenAddress;
    uint256 amount;
  }

  //268,090 - to beat
  struct TradeParameters {
    PorticoFlagSet flags;
    IERC20 startTokenAddress;
    IERC20 canonAssetAddress;
    IERC20 finalTokenAddress;
    // address of the recipient on the recipientChain
    address recipientAddress;
    // address of the portico on the recipient chain
    address recipientPorticoAddress;
    // the amount of the token that the person wishes to transfer
    uint256 amountSpecified;
    uint256 relayerFee; // the amount of tokens of the recipient to give to the relayer
  }
  //268,041 158,788
  struct DecodedVAA {
    PorticoFlagSet flags;
    IERC20 finalTokenAddress;
    // the person to receive the token
    address recipientAddress;
    // the x asset amount expected to  be received
    uint256 canonAssetAmount;
    uint256 relayerFee;
  }

  struct BridgeInfo {
    IERC20 tokenReceived;
    uint256 amountReceived;
    uint256 relayerFeeAmount;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter02 {
  function factory() external view returns (address);

  //frusturatingly, there is no deadline in this set of params
  //used on SwapRouter02 on Base chain
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface IV3Pool {
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function fee() external view returns (uint24);

  function slot0()
    external
    view
    returns (
      uint160 sqrtPriceX96,
      int24 tick,
      uint16 observationIndex,
      uint16 observationCardinality,
      uint16 observationCardinalityNext,
      uint8 feeProtocol,
      bool unlocked
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
  bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

  /// @notice The identifying key of the pool
  struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
  }

  /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
  /// @param tokenA The first token of a pool, unsorted
  /// @param tokenB The second token of a pool, unsorted
  /// @param fee The fee level of the pool
  /// @return Poolkey The pool details with ordered token0 and token1 assignments
  function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory) {
    if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
    return PoolKey({ token0: tokenA, token1: tokenB, fee: fee });
  }

  /// @notice Deterministically computes the pool address given the factory and PoolKey
  /// @param factory The Uniswap V3 factory contract address
  /// @param key The PoolKey
  /// @return pool The contract address of the V3 pool
  function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
    require(key.token0 < key.token1);
    pool = address(
      uint160(
        uint256(keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encode(key.token0, key.token1, key.fee)), POOL_INIT_CODE_HASH)))
      )
    );
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}