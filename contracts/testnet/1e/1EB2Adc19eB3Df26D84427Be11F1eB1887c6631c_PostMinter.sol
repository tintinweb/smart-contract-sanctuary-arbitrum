// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/** 
@title Extended Ownable contract with managers functionality
@author Tempe Techie
*/
abstract contract OwnableWithManagers is Ownable {
  address[] public managers; // array of managers
  mapping (address => bool) public isManager; // mapping of managers

  // MODIFIERS
  modifier onlyManagerOrOwner() {
    require(isManager[msg.sender] || msg.sender == owner(), "OwnableWithManagers: caller is not a manager or owner");
    _;
  }

  // EVENTS
  event ManagerAdd(address indexed owner_, address indexed manager_);
  event ManagerRemove(address indexed owner_, address indexed manager_);

  // READ
  function getManagers() external view returns (address[] memory) {
    return managers;
  }

  function getManagersLength() external view returns (uint256) {
    return managers.length;
  }

  // MANAGER
  
  function removeYourselfAsManager() external onlyManagerOrOwner {
    address manager_ = msg.sender;

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

  // OWNER

  function addManager(address manager_) external onlyOwner {
    require(!isManager[manager_], "OwnableWithManagers: manager already added");
    isManager[manager_] = true;
    managers.push(manager_);
    emit ManagerAdd(msg.sender, manager_);
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { OwnableWithManagers } from "../access/OwnableWithManagers.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPostNft {

  function getPostPrice (string memory _postId, address _author) external view returns (uint256);

  function owner() external view returns(address);

  function mint(
    string memory _postId, 
    address _author, 
    address _nftReceiver, 
    string memory _textPreview,
    string memory _image,
    uint256 _quantity
  ) external returns(uint256);

}

interface IPostStats {
  function addMintedPostId(address _user, uint256 _postId) external;
  function addMintedWei(address _user, uint256 _wei) external;
  function addWeiEarnedByAuthorPerPostId(uint256 _postId, uint256 _wei) external;
}

/**
@title PostMinter
@notice This contract allows users to mint Post NFTs and paying with ETH.
@dev Use this contract when CHAT token is NOT deployed yet.
*/
contract PostMinter is OwnableWithManagers, ReentrancyGuard {
  address public daoAddress;
  address public devAddress;
  address public devFeeUpdaterAddress;
  address public immutable postAddress;
  address public statsAddress;

  bool public statsEnabled = false;
  bool public paused = false;

  uint256 public constant MAX_BPS = 10_000;
  uint256 public daoFee; // share of each domain purchase (in bips) that goes to the DAO/community
  uint256 public devFee; // share of each domain purchase (in bips) that goes to the developer
  uint256 public referrerFee; // share of each domain purchase (in bips) that goes to the referrer

  // CONSTRUCTOR
  constructor(
    address _daoAddress,
    address _devAddress,
    address _postAddress,
    uint256 _daoFee,
    uint256 _devFee,
    uint256 _referrerFee
  ) {
    daoAddress = _daoAddress;
    devAddress = _devAddress;
    devFeeUpdaterAddress = _devAddress;
    postAddress = _postAddress;

    daoFee = _daoFee;
    devFee = _devFee;
    referrerFee = _referrerFee;
  }

  // WRITE

  function mint(
    string memory _postId, 
    address _author, 
    address _nftReceiver, 
    address _referrer,
    string memory _textPreview,
    string memory _image,
    uint256 _quantity
  ) external nonReentrant payable returns(uint256 tokenId) {
    require(!paused, "Minting paused");

    // find price
    uint256 price = IPostNft(postAddress).getPostPrice(_postId, _author) * _quantity;

    require(msg.value >= price, "Value below price");

    // send a referrer fee
    if (referrerFee > 0 && _referrer != address(0)) {
      uint256 referrerPayment = (price * referrerFee) / MAX_BPS;
      (bool sentReferrerFee, ) = payable(_referrer).call{value: referrerPayment}("");
      require(sentReferrerFee, "Failed to send referrer fee");
    }

    // send a dev fee
    if (devFee > 0 && devAddress != address(0)) {
      uint256 devPayment = (price * devFee) / MAX_BPS;
      (bool sentDevFee, ) = payable(devAddress).call{value: devPayment}("");
      require(sentDevFee, "Failed to send dev fee");
    }

    // send a dao fee
    if (daoFee > 0 && daoAddress != address(0)) {
      uint256 daoFeePayment = (price * daoFee) / MAX_BPS;
      (bool sentDaoFee, ) = payable(daoAddress).call{value: daoFeePayment}("");
      require(sentDaoFee, "Failed to send dao fee");
    }

    // send the rest to post author
    (bool sent, ) = payable(_author).call{value: address(this).balance}("");
    require(sent, "Failed to send payment to the post author");

    // mint the post as NFT
    tokenId = IPostNft(postAddress).mint(_postId, _author, _nftReceiver, _textPreview, _image, _quantity);

    // store some stats in the stats contract
    if (statsEnabled && statsAddress != address(0)) {
      // feel free to comment out the stats that you don't need to track
      IPostStats(statsAddress).addMintedWei(_nftReceiver, price);

      // exclude fees from the price
      price = price - ((price * referrerFee) / MAX_BPS) - ((price * devFee) / MAX_BPS) - ((price * daoFee) / MAX_BPS);
      IPostStats(statsAddress).addWeiEarnedByAuthorPerPostId(tokenId, price);
      
      IPostStats(statsAddress).addMintedPostId(_nftReceiver, tokenId);
    }
  }

  // OWNER

  // change dao fee
  function changeDaoFee(uint256 _daoFee) external onlyManagerOrOwner {
    require(_daoFee <= MAX_BPS, "Fee cannot be more than 100%");
    daoFee = _daoFee;
  }

  // change stats address
  function changeStatsAddress(address _statsAddress) external onlyManagerOrOwner {
    statsAddress = _statsAddress;
  }

  // change referrer fee
  function changeReferrerFee(uint256 _referrerFee) external onlyManagerOrOwner {
    require(_referrerFee <= 2000, "Fee cannot be more than 20%");
    referrerFee = _referrerFee;
  }

  /// @notice Recover any ERC-20 token mistakenly sent to this contract address
  function recoverERC20(address tokenAddress_, uint256 tokenAmount_, address recipient_) external onlyManagerOrOwner {
    IERC20(tokenAddress_).transfer(recipient_, tokenAmount_);
  }

  function toggleStatsEnabled() external onlyManagerOrOwner {
    statsEnabled = !statsEnabled;
  }

  function togglePaused() external onlyManagerOrOwner {
    paused = !paused;
  }

  /// @notice Withdraw native coins from contract
  function withdraw() external onlyManagerOrOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Failed to withdraw native coins from contract");
  }

  // OTHER WRITE METHODS

  /// @notice This changes the DAO address in the minter contract
  function changeDaoAddress(address _daoAddress) external {
    require(_msgSender() == daoAddress, "Sender is not the DAO");
    daoAddress = _daoAddress;
  }

  /// @notice This changes the developer's address in the minter contract
  function changeDevAddress(address _devAddress) external {
    require(_msgSender() == devAddress, "Sender is not the developer");
    devAddress = _devAddress;
  }

  /// @notice This changes the dev fee updater's address in the minter contract
  function changeDevFeeUpdaterAddress(address _devFeeUpdaterAddress) external {
    require(_msgSender() == devFeeUpdaterAddress, "Sender is not the dev fee updater");
    devFeeUpdaterAddress = _devFeeUpdaterAddress;
  }

  // change dev fee (only dev fee updater can change it)
  function changeDevFee(uint256 _devFee) external {
    require(_msgSender() == devFeeUpdaterAddress, "Sender is not the dev fee updater");
    require(_devFee <= 2000, "Fee cannot be more than 20%");
    devFee = _devFee;
  }

  // RECEIVE & FALLBACK
  receive() external payable {}
  fallback() external payable {}
 
}