// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* 

      _____________________________________
     |                                     |
     |                  The                |
     |               ARBIDUDES             |
     |             Dutch Auction           |
     |      https://www.arbidudes.xyz/     |
     |          Twitter: @ArbiDudes        |
     |_____________________________________|


//////////////////////////////////////////////////
/////////////@@@@@@@@@@@//////////////////////////
/////////@@@@@@@@@@@@@@@@@////////////////////////
///////@@@@@@@@@@@@@@@@@@@@@//////////////////////
/////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////
/////@@[email protected]@@@@@/...................//////@@///
/////@@[email protected]@/...................//////@@///
/////@@[email protected]@@@[email protected]@@@.....//////@@///
/////&&[email protected]@@@[email protected]@@@.....//////&&///
/////@@[email protected]@@@[email protected]@@@.....//////@@///
/////@@..****...................*****..//////@@///
/////@@[email protected]@@@@@@@@@@@@@@@@@@@@.......//////@@///
/////@&................................//////@&///
/////@@[email protected]@@@@@/...................//////@@///
/////@@..............................////////@@///
/////@@..............................////////@@///
/////&&...........................///////////&&///
///////@&//.....................///////////@@/////
/////////@@////////,......///////////////@@///////
///////////@@@@......./////////////////@&@@///////

*/

interface IArbiDudesGenOne {
  function getCurrentTokenId() external view returns (uint256);

  function setPublicPrice(uint256 newPrice) external;

  function setChangeNamePrice(uint256 newPrice) external;

  function setChatPrice(uint256 newPrice) external;

  function setMaxGiveawayTokenId(uint256 _newMaxToken) external;

  function pause() external;

  function unpause() external;

  function setBaseURI(string memory newBaseURI) external;

  function ownerClaimMultiple(uint256 amount, address to) external;

  function ownerWithdraw() external;

  function renounceOwnership() external;

  function transferOwnership(address newOwner) external;
}

contract ArbiDudesDutchAuction is Pausable, Ownable, ReentrancyGuard {
  IArbiDudesGenOne public dudesContract;

  uint256 private _auctionStartedAt;
  uint256 private _auctionMaxPrice;
  uint256 private _maxMintAmount = 20;
  bool private _isAuctionMode;
  mapping(uint256 => bool) private allowedAuctionMaxPrices;

  uint256 public minDudesMintableMultiple;
  uint256 public mintableMultiplePrice;
  uint256 public mintableMultiplePriceStart; // When mintable multiple is allowed

  event AuctionEnded(uint256 indexed tokenId, address indexed owner);
  event AuctionPaused(uint256 indexed tokenId);
  event AuctionUnpaused(uint256 indexed tokenId);
  event ModeAuctionOn();
  event ModeClassicOn();

  constructor(IArbiDudesGenOne arbiDudes) {
    setDudesContract(arbiDudes);
    setMinDudesMintableMultiple(5);
    setMintableMultiplePrice(50000000000000000); //0.05 ETH
    setMintableMultiplePriceStart(70000000000000000); //0.07 ETH
    _isAuctionMode = true;

    // Auction max prices
    allowedAuctionMaxPrices[2000000000000000000] = true;
    allowedAuctionMaxPrices[1000000000000000000] = true;
    allowedAuctionMaxPrices[500000000000000000] = true;
    allowedAuctionMaxPrices[100000000000000000] = true;
    allowedAuctionMaxPrices[50000000000000000] = true;
    allowedAuctionMaxPrices[20000000000000000] = true;
    allowedAuctionMaxPrices[15000000000000000] = true;
    allowedAuctionMaxPrices[10000000000000000] = true;
    allowedAuctionMaxPrices[0] = true;

    setAuctionMaxPrice(2000000000000000000); //2 ETH
    _auctionStartedAt = block.timestamp;
  }

  function setDudesContract(IArbiDudesGenOne arbiDudes) public onlyOwner {
    dudesContract = arbiDudes;
  }

  function getCurrentTokenId() public view returns (uint256) {
    return dudesContract.getCurrentTokenId();
  }

  function getAuctionStartedAt() public view returns (uint256) {
    return _auctionStartedAt;
  }

  function setDudesPublicPrice(uint256 newPrice) public onlyOwner {
    dudesContract.setPublicPrice(newPrice);
  }

  function setDudesChangeNamePrice(uint256 newPrice) public onlyOwner {
    dudesContract.setChangeNamePrice(newPrice);
  }

  function setDudesChatPrice(uint256 newPrice) public onlyOwner {
    dudesContract.setChatPrice(newPrice);
  }

  function setDudesMaxGiveawayTokenId(uint256 _newMaxToken) public onlyOwner {
    dudesContract.setMaxGiveawayTokenId(_newMaxToken);
  }

  function ownerDudesWithdraw() external onlyOwner {
    dudesContract.ownerWithdraw();
  }

  function dudesPause() public onlyOwner {
    dudesContract.pause();
  }

  function dudesUnpause() public onlyOwner {
    dudesContract.unpause();
  }

  function setDudesBaseURI(string memory newBaseURI) public onlyOwner {
    dudesContract.setBaseURI(newBaseURI);
  }

  function dudesRenounceOwnership() public virtual onlyOwner {
    dudesContract.renounceOwnership();
  }

  function dudesTransferOwnership(address newOwner) public virtual onlyOwner {
    dudesContract.transferOwnership(newOwner);
  }

  // Allow the owner to claim any amount of NFTs and direct them to another address.
  function dudesOwnerClaimMultiple(uint256 amount, address to)
    public
    nonReentrant
    onlyOwner
  {
    dudesContract.ownerClaimMultiple(amount, to);
  }

  // Dutch auction

  function auctionMode(bool auctionOn) public onlyOwner {
    require(auctionOn != _isAuctionMode, "This mode is currently active");

    _isAuctionMode = auctionOn;

    if (auctionOn) {
      // Turn On Auction - Stop Classic mode
      setMinDudesMintableMultiple(5);
      setMintableMultiplePrice(50000000000000000); // 0'05ETH
      setMintableMultiplePriceStart(70000000000000000); // 0'07ETH
      unpause();
      emit ModeAuctionOn();
    } else {
      // Turn off Auction - Start Classic mode
      pause();
      setMinDudesMintableMultiple(1);
      setMintableMultiplePrice(50000000000000000); // 0'05ETH
      setMintableMultiplePriceStart(0);
      emit ModeClassicOn();
    }
  }

  function setMinDudesMintableMultiple(uint256 minDudes) public onlyOwner {
    minDudesMintableMultiple = minDudes;
  }

  function setAuctionMaxPrice(uint256 maxPrice) public onlyOwner {
    require(allowedAuctionMaxPrices[maxPrice], "The price set is not allowed");
    _auctionMaxPrice = maxPrice;
  }

  function setMintableMultiplePrice(uint256 mulPrice) public onlyOwner {
    mintableMultiplePrice = mulPrice;
  }

  function setMintableMultiplePriceStart(uint256 mulPrice) public onlyOwner {
    mintableMultiplePriceStart = mulPrice;
  }

  function mint(uint256 _tokenId) public payable whenNotPaused nonReentrant {
    uint256 currentTokenId = getCurrentTokenId();
    require(_tokenId == currentTokenId, "Id already minted or wrong");
    require(msg.value >= mintPrice(), "Price not met");

    handleMint(1, _msgSender());
  }

  function mintMultiple(uint256 _num) public payable nonReentrant {
    require(minDudesMintableMultiple > 0, "Mint multiple not allowed");
    require(_num >= minDudesMintableMultiple, "Minimum tokens not met");
    require(_num <= _maxMintAmount, "You can mint a max of 20 dudes");
    require(
      msg.value >= mintableMultiplePrice * _num,
      "Ether sent is not enough"
    );

    // Mint auction price must match this price
    if (mintableMultiplePriceStart > 0) {
      require(
        mintPrice() <= mintableMultiplePriceStart,
        "The auction did not reach the target price yet"
      );
    }

    handleMint(_num, _msgSender());
  }

  function handleMint(uint256 num, address to) private {
    dudesContract.ownerClaimMultiple(num, to);
    if (_isAuctionMode) {
      emit AuctionEnded(getCurrentTokenId() - 1, to);
      handleRestartAuction();
    }
  }

  function handleRestartAuction() private {
    _auctionStartedAt = block.timestamp;
  }

  function secondsSinceAuctionStart() public view returns (uint256) {
    return (block.timestamp - _auctionStartedAt);
  }

  function mintPrice() public view returns (uint256) {
    return mintPriceSince(secondsSinceAuctionStart(), _auctionMaxPrice);
  }

  function offsetTimeForMaxPrice(uint256 maxPrice)
    private
    pure
    returns (uint256)
  {
    if (maxPrice == 2000000000000000000) return 0;
    if (maxPrice == 1000000000000000000) return 300;
    if (maxPrice == 500000000000000000) return 600;
    if (maxPrice == 100000000000000000) return 900;
    if (maxPrice == 50000000000000000) return 1200;
    if (maxPrice == 20000000000000000) return 2100;
    if (maxPrice == 15000000000000000) return 2400;
    if (maxPrice == 10000000000000000) return 3000;
    if (maxPrice == 0) return 3600;

    return 0;
  }

  function upper(uint256 num, uint256 bound) private pure returns (uint256) {
    if (num > bound) return bound;
    return num;
  }

  function safeSub(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) return a - b;
    return 0;
  }

  function mintPriceSince(uint256 secondsAuction, uint256 maxPrice)
    public
    pure
    returns (uint256)
  {
    uint256 exponent = 5;
    uint256 offsetTime = offsetTimeForMaxPrice(maxPrice);

    if (secondsAuction < safeSub(300, offsetTime)) {
      // 1h - 55m // first 5 min - from 2 to 1
      return
        upper(
          (2 * 10**exponent - ((secondsAuction * 10**exponent) / 300)) *
            10**(18 - exponent),
          2000000000000000000
        );
    }

    if (secondsAuction < safeSub(600, offsetTime)) {
      // 55m - 50m // from 1 to 0,5
      // y = b + mx
      // price = 1.5 - (0.5/300)secondsAuction
      return
        upper(
          ((15 * 10**exponent) - ((secondsAuction * 5 * 10**exponent) / 300)) *
            10**(18 - exponent - 1),
          1000000000000000000
        );
    }

    if (secondsAuction < safeSub(900, offsetTime)) {
      // 50m - 45m // from 0,5 to 0,1
      // price = 1,3 - (4/300)secondsAuction

      return
        upper(
          ((13 * 10**exponent) -
            ((secondsAuction * 40 * 10**exponent) / 3000)) *
            10**(18 - exponent - 1),
          500000000000000000
        );
    }

    if (secondsAuction < safeSub(1200, offsetTime)) {
      // 45m - 40m // from 0,1 to 0,05
      // price = 0,25 - (0,05/300)secondsAuction
      return
        upper(
          ((25 * 10**(exponent - 1)) -
            ((secondsAuction * 5 * 10**(exponent - 1)) / 300)) *
            10**(18 - exponent - 1),
          100000000000000000
        );
    }

    if (secondsAuction < safeSub(2100, offsetTime)) {
      // 40m - 25m // from 0,05 to 0,02
      // price = 0,09 - (0,01/300)secondsAuction
      return
        upper(
          ((9 * 10**(exponent - 2)) -
            ((secondsAuction * 10**(exponent - 2)) / 300)) *
            10**(18 - exponent),
          50000000000000000
        );
    }

    if (secondsAuction < safeSub(2400, offsetTime)) {
      // 25m - 20m // from 0,02 to 0'015
      // price = 0,055 - (0,005/300)secondsAuction
      return
        upper(
          ((55 * 10**(exponent - 2)) -
            ((secondsAuction * 5 * 10**(exponent - 2)) / 300)) *
            10**(18 - exponent - 1),
          20000000000000000
        );
    }

    if (secondsAuction < safeSub(3000, offsetTime)) {
      // 20m - 10m // from 0,015 to 0,01
      // price = 0,035 - (0,005/600)secondsAuction
      return
        upper(
          ((35 * 10**(exponent - 2)) -
            ((secondsAuction * 5 * 10**(exponent - 2)) / 600)) *
            10**(18 - exponent - 1),
          15000000000000000
        );
    }

    if (secondsAuction < safeSub(3600, offsetTime)) {
      // 10m - 0m // from 0,01 to 0
      // price = 0,06 - (0,001/600)secondsAuction
      return
        upper(
          ((6 * 10**(exponent - 2)) -
            ((secondsAuction * 1 * 10**(exponent - 2)) / 600)) *
            10**(18 - exponent),
          10000000000000000
        );
    }

    return 0; // after 1h
  }

  function ownerWithdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function pause() public onlyOwner {
    _pause();
    emit AuctionPaused(getCurrentTokenId());
  }

  function unpause() public onlyOwner {
    _unpause();
    handleRestartAuction();
    emit AuctionUnpaused(getCurrentTokenId());
  }

  receive() external payable {
    //
  }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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