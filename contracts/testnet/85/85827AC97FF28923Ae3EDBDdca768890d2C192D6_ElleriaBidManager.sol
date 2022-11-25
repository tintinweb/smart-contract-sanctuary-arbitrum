pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISignature.sol";
import "./interfaces/IElleriumTokenERC20.sol";
import "./interfaces/IEllerianHero.sol";

/** 
 * Tales of Elleria
*/
contract ElleriaBidManager is Ownable, ReentrancyGuard {

  struct Bid {
      address owner;
      uint256 elmBalance;
      uint256 usdcBalance;
      uint256 elmBidPrice;
      uint256 remainingBidQuantity;
      bool isRefunded;
  }

  // X $ELM + 50 USDC. Not possible to increase unless all bids refunded and contract migrated. 
  // If USDC cost is altered (reduced to increase $ELM burn), all remaining bids will be automatically refunded.
  uint256 public usdcCostInWEI = 50000000000000000000; 
  uint256 public bidCounter;

  address private signerAddr;
  address private safeAddr;
  ISignature private signatureAbi;

  IERC20 private elleriumAbi;
  IERC20 private usdcAbi;

  mapping(uint256 => Bid) private bids;

  // Mint cycles
  IEllerianHero private minterAbi;
  uint256 public auctionId = 0;
  uint256 public currentCycleMax = 200;
  uint256 public currentCycleLeft = 200;

  modifier onlyIfBidValid(uint256 _bidId) {
      require(_bidId < bidCounter);
      require(bids[_bidId].isRefunded == false);
      require(bids[_bidId].remainingBidQuantity > 0);
      _;
  }

  function SetAddresses(address _signatureAddr, address _signerAddr, address _elmAddr, address _usdcAddr, address _safeAddr, address _minterAddr) external onlyOwner {
    signerAddr = _signerAddr;
    safeAddr = _safeAddr;

    signatureAbi = ISignature(_signatureAddr);
    elleriumAbi = IERC20(_elmAddr);
    usdcAbi = IERC20(_usdcAddr);
    minterAbi = IEllerianHero(_minterAddr);
  }

  function ResetAuctionCycle(uint256 _max, uint256 _auctionId) external onlyOwner {
    currentCycleMax = _max;
    currentCycleLeft = currentCycleMax;
    auctionId = _auctionId;

    emit CycleReset(auctionId, currentCycleMax);
  }

  function ReduceUsdcCost(uint256 _usdcCostInWEI) external onlyOwner {
    require (_usdcCostInWEI < usdcCostInWEI, "AuctionBridge: can only reduce USDC cost");

    uint256 difference = usdcCostInWEI - _usdcCostInWEI;
    usdcCostInWEI = _usdcCostInWEI;

    // Might fail if too many bids, migrate instead.
    for (uint256 i = 0; i < bidCounter; i += 1) {
      if (bids[i].remainingBidQuantity > 0) {
        uint256 refundAmount = (difference * bids[i].remainingBidQuantity);
        bids[i].usdcBalance = bids[i].usdcBalance - refundAmount;
        usdcAbi.transfer(bids[i].owner, refundAmount);
        emit BidUpdated(bids[i].owner, bids[i].elmBalance, bids[i].usdcBalance, bids[i].remainingBidQuantity, i);
      }
    }
  }

  function OwnerRefundAllBid() external onlyOwner {
    for (uint256 i = 0; i < bidCounter; i += 1) {
      if (bids[i].isRefunded == false && bids[i].remainingBidQuantity > 0) {
      refundBid(i);
      }
    }
  }

  function OwnerRefundBid(uint256 _bidId) external onlyOwner onlyIfBidValid(_bidId) {
    refundBid(_bidId);
  }

  function ConsumeBid(uint256 _bidId, uint256 quantity, uint256 _variant) external onlyOwner onlyIfBidValid(_bidId) {
    require(quantity < currentCycleLeft, "AuctionBridge: not enough heroes left");
    currentCycleLeft -= quantity;

    uint256 elmPrice = bids[_bidId].elmBidPrice * quantity;
    uint256 usdcPrice = usdcCostInWEI * quantity;

    require(quantity <= bids[_bidId].remainingBidQuantity, "AuctionBridge: quantity exceed");
    require(elmPrice <= bids[_bidId].elmBalance, "AuctionBridge: insufficient elm");
    require(usdcPrice <= bids[_bidId].usdcBalance, "AuctionBridge: insufficient usdc");

    emit BidConsumed(bids[_bidId].owner, elmPrice, usdcPrice, quantity, _bidId, auctionId);

    elleriumAbi.transfer(safeAddr, elmPrice);
    usdcAbi.transfer(safeAddr, usdcPrice);

    bids[_bidId].elmBalance = bids[_bidId].elmBalance - elmPrice;
    bids[_bidId].usdcBalance = bids[_bidId].usdcBalance - usdcPrice;
    bids[_bidId].remainingBidQuantity = bids[_bidId].remainingBidQuantity - quantity;

    minterAbi.mintUsingToken(bids[_bidId].owner, quantity, _variant);
  }

  function GetBid(uint256 _bidId) external view returns (Bid memory) {
    return bids[_bidId];
  }

  function CreateBid(uint256 _elmAmountInWEI, uint256 quantity) external nonReentrant {
    require(quantity > 0, "AuctionBridge: Invalid quantity");

    elleriumAbi.transferFrom(msg.sender, address(this), _elmAmountInWEI * quantity);
    usdcAbi.transferFrom(msg.sender, address(this), usdcCostInWEI * quantity);

    bids[bidCounter] = Bid(
      msg.sender,
      _elmAmountInWEI * quantity,
      usdcCostInWEI * quantity,
      _elmAmountInWEI,
      quantity,
      false
    );

    emit BidUpdated(msg.sender, _elmAmountInWEI * quantity, usdcCostInWEI * quantity, quantity, bidCounter++);
  }

 function SupplementBid(uint256 _bidId, uint256 _newElmBidPrice) external nonReentrant onlyIfBidValid(_bidId) {
    require(bids[_bidId].owner == msg.sender, "AuctionBridge: you are not owner");
    require(bids[_bidId].elmBidPrice < _newElmBidPrice, "AuctionBridge: bids can only be raised");

    uint256 valueDifference = (_newElmBidPrice - bids[_bidId].elmBidPrice) * bids[_bidId].remainingBidQuantity;
    elleriumAbi.transferFrom(msg.sender, address(this), valueDifference);
  
    bids[_bidId].elmBalance = bids[_bidId].elmBalance + valueDifference;
    bids[_bidId].elmBidPrice = _newElmBidPrice;

    emit BidUpdated(
      msg.sender, 
      bids[_bidId].elmBalance, 
      bids[_bidId].usdcBalance, 
      bids[_bidId].remainingBidQuantity, 
      _bidId
      );
  }

  function RefundBid(bytes memory _signature, uint256 _time, uint256 _bidId) external nonReentrant onlyIfBidValid(_bidId) {
    require(msg.sender == bids[_bidId].owner, "AuctionBridge: cannot refund for others");
    require((block.timestamp - _time < 600), "AuctionBridge: signature expired");
    require(
      signatureAbi.verify(signerAddr, msg.sender, _time, "cancel bid", _bidId, _signature),
      "AuctionBridge: invalid signature"
    );

    refundBid(_bidId);
  }

  function refundBid(uint256 _bidId) internal {
    emit BidCancelled(bids[_bidId].owner, bids[_bidId].elmBalance, bids[_bidId].usdcBalance, bids[_bidId].remainingBidQuantity, _bidId);
  
    elleriumAbi.transfer(bids[_bidId].owner, bids[_bidId].elmBalance);
    usdcAbi.transfer(bids[_bidId].owner, bids[_bidId].usdcBalance);
    
    bids[_bidId].elmBalance = 0;
    bids[_bidId].usdcBalance = 0;
    bids[_bidId].isRefunded = true;
    bids[_bidId].remainingBidQuantity = 0;
  }

  // Events
  event BidUpdated(address indexed owner, uint256 elmValue, uint256 usdcValue, uint256 quantity, uint256 bidId);
  event BidCancelled(address indexed owner, uint256 elmValue, uint256 usdcValue, uint256 quantity, uint256 bidId);
  event BidConsumed(address indexed owner, uint256 elmValue, uint256 usdcValue, uint256 quantity, uint256 bidId, uint256 auctionId);
  event CycleReset(uint256 auctionId, uint256 quantity);
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for the signature verifier.
contract ISignature {
    function verify( address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) public pure returns (bool) { }
    function bigVerify( address _signer, address _to, uint256[] memory _data, bytes memory signature ) public pure returns (bool) {}
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for $ELLERIUM.
contract IElleriumTokenERC20 {
    function mint(address _recipient, uint256 _amount) public {}
    function SetBlacklistedAddress(address[] memory _addresses, bool _blacklisted) public {}
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

// Interface for Elleria's Heroes.
contract IEllerianHero {

  function safeTransferFrom (address _from, address _to, uint256 _tokenId) public {}
  function safeTransferFrom (address _from, address _to, uint256 _tokenId, bytes memory _data) public {}

  function mintUsingToken(address _recipient, uint256 _amount, uint256 _variant) public {}

  function burn (uint256 _tokenId, bool _isBurnt) public {}

  function ownerOf(uint256 tokenId) external view returns (address owner) {}
  function isApprovedForAll(address owner, address operator) external view returns (bool) {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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