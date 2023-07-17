// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseReceiverPortal} from '../../src/contracts/interfaces/IBaseReceiverPortal.sol';

contract MockDestination is IBaseReceiverPortal {
  address public immutable CROSS_CHAIN_CONTROLLER;

  event TestWorked(address indexed originSender, uint256 indexed originChainId, bytes message);

  constructor(address crossChainController) {
    CROSS_CHAIN_CONTROLLER = crossChainController;
  }

  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory message
  ) external {
    require(msg.sender == CROSS_CHAIN_CONTROLLER, 'CALLER_NOT_CROSS_CHAIN_CONTROLLER');
    emit TestWorked(originSender, originChainId, message);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseReceiverPortal
 * @author BGD Labs
 * @notice interface defining the method that needs to be implemented by all receiving portals, as its the one that
           will be called when a received message gets confirmed
 */
interface IBaseReceiverPortal {
  /**
   * @notice method called by CrossChainController when a message has been confirmed
   * @param originSender address of the sender of the bridged message
   * @param originChainId id of the chain where the message originated
   * @param message bytes bridged containing the desired information
   */
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory message
  ) external;
}