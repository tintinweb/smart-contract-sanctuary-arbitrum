// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

/**
 * @title ExecutorAware abstract contract
 * @notice The ExecutorAware contract allows contracts on a receiving chain to execute calls from an origin chain.
 *         These calls are sent by the `CrossChainRelayer` contract which live on the origin chain.
 *         The `CrossChainExecutor` contract on the receiving chain executes these calls
 *         and then forward them to an ExecutorAware contract on the receiving chain.
 * @dev This contract implements EIP-2771 (https://eips.ethereum.org/EIPS/eip-2771)
 *      to ensure that calls are sent by a trusted `CrossChainExecutor` contract.
 */
abstract contract ExecutorAware {
  /* ============ Variables ============ */

  /// @notice Address of the trusted executor contract.
  address public immutable trustedExecutor;

  /* ============ Constructor ============ */

  /**
   * @notice ExecutorAware constructor.
   * @param _executor Address of the `CrossChainExecutor` contract
   */
  constructor(address _executor) {
    require(_executor != address(0), "executor-not-zero-address");
    trustedExecutor = _executor;
  }

  /* ============ External Functions ============ */

  /**
   * @notice Check which executor this contract trust.
   * @param _executor Address to check
   */
  function isTrustedExecutor(address _executor) public view returns (bool) {
    return _executor == trustedExecutor;
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Retrieve signer address from call data.
   * @return _signer Address of the signer
   */
  function _msgSender() internal view returns (address payable _signer) {
    _signer = payable(msg.sender);

    if (msg.data.length >= 20 && isTrustedExecutor(_signer)) {
      assembly {
        _signer := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }
  }

  /**
   * @notice Retrieve nonce from call data.
   * @return _callDataNonce Nonce uniquely identifying the message that was executed
   */
  function _nonce() internal pure returns (uint256 _callDataNonce) {
    _callDataNonce;

    if (msg.data.length >= 52) {
      assembly {
        _callDataNonce := calldataload(sub(calldatasize(), 52))
      }
    }
  }
}

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "../../src/abstract/ExecutorAware.sol";

contract Greeter is ExecutorAware {
  string public greeting;

  event SetGreeting(
    string greeting,
    uint256 nonce, // nonce of the message that was executed
    address l1Sender, // _msgSender() is the address who called `relayCalls` on the origin chain
    address l2Sender // CrossChainExecutor contract
  );

  constructor(address _executor, string memory _greeting) ExecutorAware(_executor) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    require(isTrustedExecutor(msg.sender), "Greeter/sender-not-executor");

    greeting = _greeting;
    emit SetGreeting(_greeting, _nonce(), _msgSender(), msg.sender);
  }
}