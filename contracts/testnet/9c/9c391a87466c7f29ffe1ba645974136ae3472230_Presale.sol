/**
 *Submitted for verification at Arbiscan on 2022-12-23
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: presale.sol



pragma solidity ^ 0.8.0;


interface IToken {
  function balanceOf(address _user) external view returns(uint256);
  function transfer(address _user, uint256 amount) external ;  
}
contract Presale is Ownable {
  IToken public token;
  uint256 public constant PRESALE_ENTRIES = 1000 ether;
  uint256 private price =  0.0000008 ether;
  uint256 private whitelistPrice;
  uint256 private MAX_BUYABLE = 20000;
  uint256 public saleAmount;
  uint256 public startTime;
  enum STAGES { PENDING, PRESALE }
  STAGES stage = STAGES.PENDING;
  mapping(address => bool) public whitelisted;
  uint256 public whitelistAccessCount;
  constructor(address tokenAddress) {
    token = IToken(tokenAddress );
    whitelistPrice = price * 90 / 100;
  }

  function buy(uint256 _amount) external payable {
    require(stage != STAGES.PENDING, "Presale not started yet.");
    require(saleAmount + _amount <= PRESALE_ENTRIES, "PRESALE LIMIT EXCEED");
    require(_amount <= MAX_BUYABLE, "BUYABLE LIMIT EXCEED");
    if (whitelisted[msg.sender]) {
      require(msg.value >= whitelistPrice * _amount, "need more money");
    } else {
      require(msg.value >= price * _amount, "need more money");
    }
    token.transfer(msg.sender, _amount * 1e18);
    saleAmount += _amount;
  }

  function addWhiteListAddresses(address[] calldata addresses) external onlyOwner
  {
    require(whitelistAccessCount + addresses.length <= 500, "Whitelist amount exceed");
    for (uint8 i = 0; i < addresses.length; i++)
    whitelisted[addresses[i]] = true;
    whitelistAccessCount += addresses.length;
  }

  function setWhitelistPrice(uint256 rePrice) external onlyOwner {
    whitelistPrice = rePrice;
  }
  
  function setPrice(uint256 rePrice) external onlyOwner {
    price = rePrice;
  }  

  function startSale() external onlyOwner {
    require(stage == STAGES.PENDING, "Not in pending stage.");
    startTime = block.timestamp;
    stage = STAGES.PRESALE;
  }

  function recoverCurrency(uint256 amount) public onlyOwner {
    bool success;
    (success, ) = payable(owner()).call{value: amount}("");
    require(success);
  }

  function recoverToken(uint256 tokenAmount) public onlyOwner {
    token.transfer(owner(), tokenAmount * 1e18);
  }
}