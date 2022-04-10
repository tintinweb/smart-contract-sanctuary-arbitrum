// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Token.sol";

error FeeError(uint256 realAmount, uint256 fee);
error EqualError(uint256 noEqual);
error SendError(address sender);

contract VVoidTokenTransfer is Ownable {

  uint256 public txFee = 0.005 ether;

  event SendNotification(address sender);
  event SendERC20Notification(address sender);

  constructor() {}

  modifier checkFee {
    if(msg.value != txFee) revert FeeError(msg.value, txFee);
    _;
  }

  /**
    发送 ETH
   */
  function send(address[] calldata receivers, uint256[] calldata amounts) public payable {
    if (receivers.length != amounts.length){
      revert EqualError(receivers.length);
    }

    uint256 realAmount = msg.value;
    uint256 sendAmount = 0;

    for (uint i = 0; i < amounts.length; i++) {
      sendAmount += amounts[i];
    }
    sendAmount += txFee;
    if ((realAmount - sendAmount) != 0){
      revert FeeError(realAmount, txFee);
    }

    for (uint i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      uint256 amount = amounts[i];
      (bool sendStatus, ) = receiver.call{value: amount}("");
      if (!sendStatus) {
        revert SendError(receiver);
      }
    }
    emit SendNotification(msg.sender);
  }

  /**
    发送 ERC20
   */
  function sendERC20(address tokenAddress, address[] calldata receivers, uint256[] calldata amounts) public payable checkFee{
    ERC20Token token = ERC20Token(tokenAddress);
    
    for (uint i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      uint256 amount = amounts[i];
      token.transferFrom(msg.sender, receiver, amount);
    }

    emit SendERC20Notification(msg.sender);
  }

  /**
    修改 owner 权限
   */
  function changedOwner(address newOwner) public onlyOwner{
    transferOwnership(newOwner);
  }

  /**
    修改手续费
   */
  function changedTxFee(uint256 newTxFee) public onlyOwner{
    txFee = newTxFee;
  }

  /**
    取款
   */
  function withdraw() public onlyOwner {
    address _owner = owner();
    uint256 amount = address(this).balance;
    (bool sendStatus, ) = _owner.call{value: amount}("");
    if (!sendStatus){
      revert SendError(_owner);
    }
  }

  receive() external payable {}
  fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

// https://eips.ethereum.org/EIPS/eip-20

interface ERC20Token {
  function name() external view returns (string calldata);
  function symbol() external view returns (string calldata);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function transfer(address _to, uint256 _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function approve(address _spender, uint256 _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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