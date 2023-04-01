// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IConduitController {
  function getConduitCodeHashes()
    external
    view
    returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

interface IConduit {
  enum ConduitItemType {
    NATIVE, // Unused
    ERC20,
    ERC721,
    ERC1155
  }

  struct ConduitTransfer {
    ConduitItemType itemType;
    address token;
    address from;
    address to;
    uint256 identifier;
    uint256 amount;
  }

  function execute(ConduitTransfer[] calldata transfers) external returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IReservoirV6_0_1 {
  struct ExecutionInfo {
    address module;
    bytes data;
    uint256 value;
  }

  function execute(ExecutionInfo[] calldata executionInfos) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IConduit, IConduitController} from "../interfaces/IConduit.sol";
import {IReservoirV6_0_1} from "../interfaces/IReservoirV6_0_1.sol";

// Forked from:
// https://github.com/ProjectOpenSea/seaport/blob/b13939729001cb12f715d7b73422aafeca0bcd0d/contracts/helpers/TransferHelper.sol
contract ReservoirApprovalProxy is ReentrancyGuard {
  // --- Structs ---

  struct TransferHelperItem {
    IConduit.ConduitItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
  }

  struct TransferHelperItemsWithRecipient {
    TransferHelperItem[] items;
    address recipient;
  }

  // --- Errors ---

  error ConduitExecutionFailed();
  error InvalidRecipient();

  // --- Fields ---

  IConduitController internal immutable _CONDUIT_CONTROLLER;
  bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;
  bytes32 internal immutable _CONDUIT_RUNTIME_CODE_HASH;

  IReservoirV6_0_1 internal immutable _ROUTER;

  // --- Constructor ---

  constructor(address conduitController, address router) {
    IConduitController controller = IConduitController(conduitController);
    (_CONDUIT_CREATION_CODE_HASH, _CONDUIT_RUNTIME_CODE_HASH) = controller.getConduitCodeHashes();

    _CONDUIT_CONTROLLER = controller;
    _ROUTER = IReservoirV6_0_1(router);
  }

  // --- Public methods ---

  function bulkTransferWithExecute(
    TransferHelperItemsWithRecipient[] calldata transfers,
    IReservoirV6_0_1.ExecutionInfo[] calldata executionInfos,
    bytes32 conduitKey
  ) external nonReentrant {
    uint256 numTransfers = transfers.length;

    address conduit = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              bytes1(0xff),
              address(_CONDUIT_CONTROLLER),
              conduitKey,
              _CONDUIT_CREATION_CODE_HASH
            )
          )
        )
      )
    );

    uint256 sumOfItemsAcrossAllTransfers;
    unchecked {
      for (uint256 i = 0; i < numTransfers; ++i) {
        TransferHelperItemsWithRecipient calldata transfer = transfers[i];
        sumOfItemsAcrossAllTransfers += transfer.items.length;
      }
    }

    IConduit.ConduitTransfer[] memory conduitTransfers = new IConduit.ConduitTransfer[](
      sumOfItemsAcrossAllTransfers
    );

    uint256 itemIndex;
    unchecked {
      for (uint256 i = 0; i < numTransfers; ++i) {
        TransferHelperItemsWithRecipient calldata transfer = transfers[i];
        TransferHelperItem[] calldata transferItems = transfer.items;

        _checkRecipientIsNotZeroAddress(transfer.recipient);

        uint256 numItemsInTransfer = transferItems.length;
        for (uint256 j = 0; j < numItemsInTransfer; ++j) {
          TransferHelperItem calldata item = transferItems[j];
          conduitTransfers[itemIndex] = IConduit.ConduitTransfer(
            item.itemType,
            item.token,
            msg.sender,
            transfer.recipient,
            item.identifier,
            item.amount
          );

          ++itemIndex;
        }
      }
    }

    bytes4 conduitMagicValue = IConduit(conduit).execute(conduitTransfers);
    if (conduitMagicValue != IConduit.execute.selector) {
      revert ConduitExecutionFailed();
    }

    _ROUTER.execute(executionInfos);
  }

  function _checkRecipientIsNotZeroAddress(address recipient) internal pure {
    if (recipient == address(0x0)) {
      revert InvalidRecipient();
    }
  }
}