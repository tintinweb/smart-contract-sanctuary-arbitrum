// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
// Modified to use unstructured storage for proxy/implementation pattern

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ProxyReentrancyGuard` will make the {nonReentrant} modifier
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
abstract contract ProxyReentrancyGuard {
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

    // uint256 representation of keccak("reentrancy_guard_status")
    uint256 private constant _STATUS_PTR = 111692000423667832297373040361148959237193225730820145803586364568851768547719;

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
        require(_status() != _ENTERED, "ProxyReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _setStatus(_ENTERED);
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _setStatus(_NOT_ENTERED);
    }

    function _setStatus(uint256 status) private {
        assembly { sstore(_STATUS_PTR, status) }
    }

    function _status() internal view returns (uint256 status) {
        assembly { status := sload(_STATUS_PTR) }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

struct Call {
  address targetContract;
  bytes data;
}

abstract contract StrategyBase { }

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;


/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    StrategyTarget01.sol :: 0x1c39d1a4d571ac3c1f944e57268452ebc2a62afe
 *    etherscan.io verified 2023-11-30
 */ 
import "./StrategyBase.sol";
import "./Libraries/ProxyReentrancyGuard.sol";

error BadOrderIndex();
error UnsignedCallRequired();

/// @param primitiveTarget Contract address where primitive functions will be executed
/// @param orders Array of allowed orders
/// @param beforeCalls Array of primitive calls to execute before order execution
/// @param afterCalls Array of primitive calls to execute after order execution
struct Strategy {
  address primitiveTarget;
  Order[] orders;
  bytes[] beforeCalls;
  bytes[] afterCalls;
}

struct Order {
  Primitive[] primitives;
}

struct Primitive {
  bytes data;
  bool requiresUnsignedCall;
}

struct UnsignedData {
  uint8 orderIndex;
  bytes[] calls;
}

contract StrategyTarget01 is StrategyBase, ProxyReentrancyGuard {

  /// @dev Execute an order within a signed array of orders
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param strategy Strategy signed by owner [signed]
  /// @param unsignedData Unsigned calldata [unsigned]
  function execute(
    Strategy calldata strategy,
    UnsignedData calldata unsignedData
  ) external nonReentrant {
    if (unsignedData.orderIndex >= strategy.orders.length) {
      revert BadOrderIndex();
    }

    _delegateCallsWithRevert(strategy.primitiveTarget, strategy.beforeCalls);

    uint8 nextUnsignedCall = 0;
    for (uint8 i = 0; i < strategy.orders[unsignedData.orderIndex].primitives.length; i++) {
      Primitive calldata primitive = strategy.orders[unsignedData.orderIndex].primitives[i];
      bytes memory primitiveCallData;
      if (primitive.requiresUnsignedCall) {
        if (nextUnsignedCall >= unsignedData.calls.length) {
          revert UnsignedCallRequired();
        }

        bytes memory signedData = primitive.data;

        // change length of signedData to ignore the last bytes32
        assembly {
          mstore(add(signedData, 0x0), sub(mload(signedData), 0x20))
        }

        // concat signed and unsigned call bytes
        primitiveCallData = bytes.concat(signedData, unsignedData.calls[nextUnsignedCall]);
        nextUnsignedCall++;
      } else {
        primitiveCallData = primitive.data;
      }
      _delegateCallWithRevert(Call({
        targetContract: strategy.primitiveTarget,
        data: primitiveCallData
      }));
    }

    _delegateCallsWithRevert(strategy.primitiveTarget, strategy.afterCalls);
  }

  function _delegateCallsWithRevert (address targetContract, bytes[] calldata calls) internal {
    for (uint8 i = 0; i < calls.length; i++) {
      _delegateCallWithRevert(Call({
        targetContract: targetContract,
        data: calls[i]
      }));
    }
  }

  function _delegateCallWithRevert (Call memory call) internal {
    address targetContract = call.targetContract;
    bytes memory data = call.data;
    assembly {
      let result := delegatecall(gas(), targetContract, add(data, 0x20), mload(data), 0, 0)
      if eq(result, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }
}