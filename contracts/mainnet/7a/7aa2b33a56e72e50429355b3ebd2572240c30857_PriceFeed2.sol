/**
 *Submitted for verification at Arbiscan on 2023-07-07
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/pricefeed.sol


pragma solidity ^0.8.0;



contract PriceFeed2 is Ownable {
   AggregatorV3Interface public wstETHfeed = AggregatorV3Interface(0xb523AE262D20A936BC152e6023996e46FDC2A95D);
   AggregatorV3Interface public rETHfeed = AggregatorV3Interface(0xF3272CAfe65b190e76caAF483db13424a3e23dD2);

   uint256 public SfrxETHPrice;
   address public bridge;
   uint256 public lastUpdate = block.timestamp;

   mapping(uint =>  function () view returns (uint256)) funcMap;

   constructor() {
        funcMap[0] = getRETHprice;
        funcMap[1] =  getWstETHprice;
        funcMap[2] =  getSfrxETHprice;
   }

   function getLatestPrice(AggregatorV3Interface feed) public view returns (int) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = feed.latestRoundData();
    return price;
    }

    function getRETHprice() public view returns (uint256) {
        return uint256(getLatestPrice(rETHfeed));
    }

    function getWstETHprice() public view returns (uint256) {
        return uint256(getLatestPrice(wstETHfeed));
    }

    function updateBridge(address _bridge) external onlyOwner  {
        bridge = _bridge;

    }

    
    function getSfrxETHprice() public view returns (uint256) {
        return SfrxETHPrice;
    }

    function setSfrxETHprice(uint256 price) public returns (uint256) {
        require(msg.sender == bridge, "not bridge");
        if (SfrxETHPrice > 1e18) {
            require((price - SfrxETHPrice) <= 1e16, "increase too much");
            require((price >= 1e18), "higher than 1");
            require((block.timestamp - lastUpdate) >= 5 minutes, "update too soon");
            lastUpdate = block.timestamp;
        }
        SfrxETHPrice = price;
        return SfrxETHPrice;
    }

    function getPrice(uint id) public view returns (uint256) {
        return funcMap[id]();
    }
}