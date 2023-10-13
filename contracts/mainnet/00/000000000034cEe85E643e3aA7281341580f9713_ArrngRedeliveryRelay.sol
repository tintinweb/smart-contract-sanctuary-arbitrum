// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: BUSL-1.1

/**
 *
 * @title ArrngRedeliveryRelay.sol. Contract for relaying redelivery requests.
 *
 * @author arrng https://arrng.io/
 * @author omnus https://omn.us/
 *
 */

import {IArrngRedeliveryRelay} from "./IArrngRedeliveryRelay.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.19;

contract ArrngRedeliveryRelay is IArrngRedeliveryRelay, Ownable {
  // Address of the oracle:
  address payable public oracleAddress;

  /**
   *
   * @dev constructor
   *
   */
  constructor() {
    _transferOwnership(tx.origin);
    oracleAddress = payable(0x9Ca9af4E49DdB2A220369f1ad4B460043c9005EF);
  }

  /**
   *
   * @dev setOracleAddress: set a new oracle address
   *
   * @param oracle_: the new oracle address
   *
   */
  function setOracleAddress(address payable oracle_) external onlyOwner {
    require(oracle_ != address(0), "Oracle address cannot be address(0)");
    oracleAddress = oracle_;
    emit OracleAddressSet(oracle_);
  }

  /**
   *
   * @dev requestRedelivery: request redelivery of rng. Note that this will
   * ONLY succeed if the original delivery was not sucessful (e.g. when
   * requested with insufficient native token for gas).
   *
   * The use of this method will have the following outcomes:
   * - Original delivery was SUCCESS: no redelivery, excess native token refunded to the
   * provided refund address
   * - There was no original delivery (request ID not found): no redelivery,
   * excess native token refunded to the provided refund address
   * - There was a request and it failed: redelivery of rng as per original
   * request IF there is sufficient native token on this call. Otherwise, refund
   * of excess native token.
   *
   * requestRedelivery is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the msg.sender for this call.
   *
   * @param arrngRequestId_: the Id of the original request
   *
   */
  function requestRedelivery(uint256 arrngRequestId_) external payable {
    requestRedelivery(arrngRequestId_, msg.sender);
  }

  /**
   *
   * @dev requestRedelivery: request redelivery of rng. Note that this will
   * ONLY succeed if the original delivery was not sucessful (e.g. when
   * requested with insufficient native token for gas).
   *
   * The use of this method will have the following outcomes:
   * - Original delivery was SUCCESS: no redelivery, excess native token refunded to the
   * provided refund address
   * - There was no original delivery (request ID not found): no redelivery,
   * excess native token refunded to the provided refund address
   * - There was a request and it failed: redelivery of rng as per original
   * request IF there is sufficient native token on this call. Otherwise, refund
   * of excess native token.
   *
   * requestRedelivery is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param arrngRequestId_: the Id of the original request
   * @param refundAddress_: the address for refund of ununsed native token
   *
   */
  function requestRedelivery(
    uint256 arrngRequestId_,
    address refundAddress_
  ) public payable {
    _requestRedelivery(arrngRequestId_, msg.sender, msg.value, refundAddress_);
  }

  /**
   *
   * @dev _requestRedelivery: request redelivery of rng. Note that this will
   * ONLY succeed if the original delivery was not sucessful (e.g. when
   * requested with insufficient native token for gas).
   *
   * The use of this method will have the following outcomes:
   * - Original delivery was SUCCESS: no redelivery, excess native token refunded to the
   * provided refund address
   * - There was no original delivery (request ID not found): no redelivery,
   * excess native token refunded to the provided refund address
   * - There was a request and it failed: redelivery of rng as per original
   * request IF there is sufficient native token on this call. Otherwise, refund
   * of excess native token.
   *
   * @param arrngRequestId_: the Id of the original request
   * @param caller_: the msg.sender that has made this call
   * @param payment_: the msg.value sent with the call
   * @param refundAddress_: the address for refund of ununsed native token
   *
   */
  function _requestRedelivery(
    uint256 arrngRequestId_,
    address caller_,
    uint256 payment_,
    address refundAddress_
  ) internal {
    // Forward funds to the oracle:
    (bool success, ) = oracleAddress.call{value: payment_}("");
    require(success, "Error requesting redelivery");

    // Request redelivery:
    emit ArrngRedeliveryRequest(
      uint64(arrngRequestId_),
      caller_,
      uint96(payment_),
      refundAddress_
    );
  }
}

// SPDX-License-Identifier: MIT

/**
 *
 * @title IArrngRedeliveryRelay.sol. Interface for relaying redelivery requests.
 *
 * @author arrng https://arrng.io/
 * @author omnus https://omn.us/
 *
 */

pragma solidity 0.8.19;

interface IArrngRedeliveryRelay {
  event ArrngRedeliveryRequest(
    uint64 requestId,
    address caller,
    uint96 value,
    address refundAddress
  );

  event OracleAddressSet(address oracle);

  /**
   *
   * @dev setOracleAddress: set a new oracle address
   *
   * @param oracle_: the new oracle address
   *
   */
  function setOracleAddress(address payable oracle_) external;

  /**
   *
   * @dev requestRedelivery: request redelivery of rng. Note that this will
   * ONLY succeed if the original delivery was not sucessful (e.g. when
   * requested with insufficient native token for gas).
   *
   * The use of this method will have the following outcomes:
   * - Original delivery was SUCCESS: no redelivery, excess native token refunded to the
   * provided refund address
   * - There was no original delivery (request ID not found): no redelivery,
   * excess ETH refunded to the provided refund address
   * - There was a request and it failed: redelivery of rng as per original
   * request IF there is sufficient native token on this call. Otherwise, refund
   * of excess native token.
   *
   * requestRedelivery is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param arrngRequestId_: the Id of the original request
   *
   */
  function requestRedelivery(uint256 arrngRequestId_) external payable;

  /**
   *
   * @dev requestRedelivery: request redelivery of rng. Note that this will
   * ONLY succeed if the original delivery was not sucessful (e.g. when
   * requested with insufficient native token for gas).
   *
   * The use of this method will have the following outcomes:
   * - Original delivery was SUCCESS: no redelivery, excess native token refunded to the
   * provided refund address
   * - There was no original delivery (request ID not found): no redelivery,
   * excess ETH refunded to the provided refund address
   * - There was a request and it failed: redelivery of rng as per original
   * request IF there is sufficient native token on this call. Otherwise, refund
   * of excess native token.
   *
   * requestRedelivery is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param arrngRequestId_: the Id of the original request
   * @param refundAddress_: the address for refund of ununsed native token
   *
   */
  function requestRedelivery(
    uint256 arrngRequestId_,
    address refundAddress_
  ) external payable;
}