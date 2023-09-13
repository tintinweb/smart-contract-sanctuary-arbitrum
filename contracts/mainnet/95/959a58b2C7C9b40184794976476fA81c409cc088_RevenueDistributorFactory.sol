// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./RevenueDistributor.sol";

/// @title RevenueDistributor factory
/// @author Tempe Techie
/// @notice Factory that creates new RevenueDistributor contracts
contract RevenueDistributorFactory {
  uint256 private constant ID_MAX_LENGTH = 30;

  // mapping(uniqueID => RevenueDistributor contract address) to easily find a RevenueDistributor contract address
  mapping (string => address) private distributorAddressById; 

  // EVENTS
  event RevenueDistributorLaunch(address indexed contractOwner_, string uniqueId_, address indexed contractAddress_);

  // READ

  function getDistributorAddressById(string memory uniqueId_) external view returns(address) {
    return distributorAddressById[uniqueId_];
  }

  function isUniqueIdAvailable(string memory uniqueId_) public view returns(bool) {
    return distributorAddressById[uniqueId_] == address(0);
  }

  // WRITE

  function create(string calldata uniqueId_) external returns(address) {
    require(bytes(uniqueId_).length <= ID_MAX_LENGTH, "Unique ID is too long");
    require(isUniqueIdAvailable(uniqueId_), "Unique ID is not available");

    bytes32 saltedHash = keccak256(abi.encodePacked(msg.sender, block.timestamp, uniqueId_));
    RevenueDistributor distributor = new RevenueDistributor{salt: saltedHash}();

    distributorAddressById[uniqueId_] = address(distributor);

    distributor.transferOwnership(msg.sender);

    emit RevenueDistributorLaunch(msg.sender, uniqueId_, address(distributor));

    return address(distributor);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
  function transfer(address to, uint256 amount) external returns (bool);
}

/// @title RevenueDistributor
/// @author Tempe Techie
/// @notice Automatically distribute revenue to multiple recipients
contract RevenueDistributor is Ownable, ReentrancyGuard {
  uint256 private constant LABEL_MAX_LENGTH = 30;

  struct Recipient {
    address addr;
    string label;
    uint256 percentage; // 100% = 1 ether
  }

  Recipient[] public recipients; // array of Recipient structs

  address[] public managers; // array of managers
  mapping (address => bool) public isManager; // mapping of managers

  // MODIFIERS
  modifier onlyManager() {
    require(isManager[msg.sender] || msg.sender == owner(), "RevenueDistributor: caller is not a manager");
    _;
  }

  // EVENTS
  event ManagerAdd(address indexed owner_, address indexed manager_);
  event ManagerRemove(address indexed owner_, address indexed manager_);
  event RecipientAdd(address indexed adder_, address indexed recipient_, string label_, uint256 percentage_);
  event RecipientRemove(address indexed remover_, address indexed recipient_);
  event RecipientRemoveAll(address indexed remover_);
  event RecipientUpdate(address indexed updater_, address indexed recipient_, address newAddr_, string label_, uint256 percentage_);
  event WithdrawEth(address indexed owner_, uint256 amount_);

  // READ

  function getManagers() external view returns (address[] memory) {
    return managers;
  }

  function getRecipient(address recipient_) external view returns (Recipient memory) {
    uint256 length = recipients.length;

    for (uint256 i = 0; i < length;) {
      if (recipients[i].addr == recipient_) {
        return recipients[i];
      }

      unchecked {
        i++;
      }
    }

    revert("RevenueDistributor: recipient not found");
  }

  function getRecipients() external view returns (Recipient[] memory) {
    return recipients;
  }

  function getRecipientsLength() external view returns (uint256) {
    return recipients.length;
  }

  function isRecipient(address addr_) external view returns (bool) {
    uint256 length = recipients.length;

    for (uint256 i = 0; i < length;) {
      if (recipients[i].addr == addr_) {
        return true;
      }

      unchecked {
        i++;
      }
    }

    return false;
  }

  // MANAGER

  function addRecipient(address addr_, string calldata label_, uint256 percentage_) external onlyManager {
    require(bytes(label_).length < LABEL_MAX_LENGTH, "RevenueDistributor: label too long");

    uint256 percentageTotal;
    uint256 length = recipients.length;

    for (uint256 i = 0; i < length;) {
      require(recipients[i].addr != addr_, "RevenueDistributor: recipient already in the list");

      percentageTotal += recipients[i].percentage;

      unchecked {
        i++;
      }
    }

    require(percentageTotal + percentage_ <= 1 ether, "RevenueDistributor: percentage total must be less than or equal to 100%");

    recipients.push(Recipient(addr_, label_, percentage_));
    emit RecipientAdd(msg.sender, addr_, label_, percentage_);
  }

  function removeAllRecipients() external onlyManager {
    delete recipients;
    emit RecipientRemoveAll(msg.sender);
  }

  function removeLastRecipient() external onlyManager {
    emit RecipientRemove(msg.sender, recipients[recipients.length - 1].addr);
    recipients.pop();
  }

  function removeRecipientByAddress(address recipient_) external onlyManager {
    uint256 length = recipients.length;

    for (uint256 i = 0; i < length;) {
      if (recipients[i].addr == recipient_) {
        recipients[i] = recipients[length - 1];
        recipients.pop();
        emit RecipientRemove(msg.sender, recipient_);
        return;
      }

      unchecked {
        i++;
      }
    }
  }

  function removeRecipientByIndex(uint256 index_) external onlyManager {
    emit RecipientRemove(msg.sender, recipients[index_].addr);
    recipients[index_] = recipients[recipients.length - 1];
    recipients.pop();
  }

  function updateRecipientByAddress(
    address recipient_, 
    address newAddr_, 
    string calldata label_, 
    uint256 newPercentage_
  ) external onlyManager {
    require(bytes(label_).length < LABEL_MAX_LENGTH, "RevenueDistributor: label too long");

    uint256 percentageTotal;
    uint256 length = recipients.length;

    for (uint256 i = 0; i < length;) {
      if (recipients[i].addr == recipient_) {
        recipients[i].addr = newAddr_;
        recipients[i].label = label_;
        recipients[i].percentage = newPercentage_;
        percentageTotal += newPercentage_;
        emit RecipientUpdate(msg.sender, recipient_, newAddr_, label_, newPercentage_);
      } else {
        percentageTotal += recipients[i].percentage;
      }

      unchecked {
        i++;
      }
    }

    require(percentageTotal <= 1 ether, "RevenueDistributor: percentage total must be less than or equal to 100%");
  }

  function updateRecipientByIndex(
    uint256 index_, 
    address newAddr_, 
    string calldata label_, 
    uint256 newPercentage_
  ) external onlyManager {
    require(bytes(label_).length < LABEL_MAX_LENGTH, "RevenueDistributor: label too long");

    uint256 percentageTotal;
    uint256 length = recipients.length;

    for (uint256 i = 0; i < length;) {
      if (i == index_) {
        emit RecipientUpdate(msg.sender, recipients[i].addr, newAddr_, label_, newPercentage_);
        recipients[i].addr = newAddr_;
        recipients[i].label = label_;
        recipients[i].percentage = newPercentage_;
        percentageTotal += newPercentage_;
        
      } else {
        percentageTotal += recipients[i].percentage;
      }

      unchecked {
        i++;
      }
    }

    require(percentageTotal <= 1 ether, "RevenueDistributor: percentage total must be less than or equal to 100%");
  }

  // OWNER

  function addManager(address manager_) external onlyOwner {
    require(!isManager[manager_], "RevenueDistributor: manager already added");
    isManager[manager_] = true;
    managers.push(manager_);
    emit ManagerAdd(msg.sender, manager_);
  }

  /// @notice Recover any ERC-20 token mistakenly sent to this contract address
  function recoverERC20(address tokenAddress_, uint256 tokenAmount_, address recipient_) external onlyOwner {
    IERC20(tokenAddress_).transfer(recipient_, tokenAmount_);
  }

  function removeManagerByAddress(address manager_) external onlyOwner {
    isManager[manager_] = false;
    uint256 length = managers.length;

    for (uint256 i = 0; i < length;) {
      if (managers[i] == manager_) {
        managers[i] = managers[length - 1];
        managers.pop();
        emit ManagerRemove(msg.sender, manager_);
        return;
      }

      unchecked {
        i++;
      }
    }
  }

  function removeManagerByIndex(uint256 index_) external onlyOwner {
    emit ManagerRemove(msg.sender, managers[index_]);
    isManager[managers[index_]] = false;
    managers[index_] = managers[managers.length - 1];
    managers.pop();
  }

  /// @dev Manual withdrawal in case there's an excess of ETH in the contract
  function withdrawEth() external onlyOwner {
    emit WithdrawEth(msg.sender, address(this).balance);
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success, "RevenueDistributor: transfer failed");
  }

  // INTERNAL
  
  function _distribute(uint256 value_) internal nonReentrant {
    uint256 length = recipients.length;
    
    for (uint256 i = 0; i < length;) {
      address recipient = recipients[i].addr;

      if (recipient != address(0)) {
        uint256 percentage = recipients[i].percentage;
        uint256 amount = (value_ * percentage) / 1 ether;

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "RevenueDistributor: transfer failed");
      }

      unchecked {
        i++;
      }
    }
  }

  // RECEIVE
  receive() external payable {
    _distribute(msg.value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0-rc.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0-rc.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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