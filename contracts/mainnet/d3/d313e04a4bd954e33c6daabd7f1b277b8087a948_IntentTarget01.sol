// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

struct Call {
  address targetContract;
  bytes data;
}

abstract contract IntentBase { }

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
 *    IntentTarget01.sol :: 0xd313e04a4bd954e33c6daabd7f1b277b8087a948
 *    etherscan.io verified 2023-12-01
 */ 
import "./IntentBase.sol";
import "./Libraries/ProxyReentrancyGuard.sol";

error BadIntentIndex();
error UnsignedCallRequired();

/// @param segmentTarget Contract address where segment functions will be executed
/// @param intents Array of allowed intents
/// @param beforeCalls Array of segment calls to execute before intent execution
/// @param afterCalls Array of segment calls to execute after intent execution
struct Declaration {
  address segmentTarget;
  Intent[] intents;
  bytes[] beforeCalls;
  bytes[] afterCalls;
}

struct Intent {
  Segment[] segments;
}

struct Segment {
  bytes data;
  bool requiresUnsignedCall;
}

struct UnsignedData {
  uint8 intentIndex;
  bytes[] calls;
}

contract IntentTarget01 is IntentBase, ProxyReentrancyGuard {

  /// @dev Execute a signed declaration of intents
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param declaration Declaration of intents signed by owner [signed]
  /// @param unsignedData Unsigned calldata [unsigned]
  function execute(
    Declaration calldata declaration,
    UnsignedData calldata unsignedData
  ) external nonReentrant {
    if (unsignedData.intentIndex >= declaration.intents.length) {
      revert BadIntentIndex();
    }

    _delegateCallsWithRevert(declaration.segmentTarget, declaration.beforeCalls);

    uint8 nextUnsignedCall = 0;
    for (uint8 i = 0; i < declaration.intents[unsignedData.intentIndex].segments.length; i++) {
      Segment calldata segment = declaration.intents[unsignedData.intentIndex].segments[i];
      bytes memory segmentCallData;
      if (segment.requiresUnsignedCall) {
        if (nextUnsignedCall >= unsignedData.calls.length) {
          revert UnsignedCallRequired();
        }

        bytes memory signedData = segment.data;

        // change length of signedData to ignore the last bytes32
        assembly {
          mstore(add(signedData, 0x0), sub(mload(signedData), 0x20))
        }

        // concat signed and unsigned call bytes
        segmentCallData = bytes.concat(signedData, unsignedData.calls[nextUnsignedCall]);
        nextUnsignedCall++;
      } else {
        segmentCallData = segment.data;
      }
      _delegateCallWithRevert(Call({
        targetContract: declaration.segmentTarget,
        data: segmentCallData
      }));
    }

    _delegateCallsWithRevert(declaration.segmentTarget, declaration.afterCalls);
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