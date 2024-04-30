/**
 *Submitted for verification at Arbiscan.io on 2024-04-30
*/

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/examples/KreskoMarketStatusOracle.sol

pragma solidity ^0.8.13;

contract KreskoMarketStatusOracle is Ownable {
    error NotAllowed(address who);
    error InvalidInput();
    error InvalidTicker(bytes32 ticker);
    error InvalidExchange(bytes32 exchange);

    // Mapping of the allowed addresses
    mapping(address => bool) public allowed;
    
    // Mapping of the tickers and exchanges
    // Ticker in bytes32 formart (as represented in Kresko Protocol i.e. bytes32("SPY")) => bytes32("NASDAQ") 
    mapping(bytes32 => bytes32) public exchanges; 
    // Exchange => 1 for closed, 2 for open
    mapping(bytes32 => uint256) public status;

    modifier onlyAllowed() {
        if(!allowed[msg.sender]) {
            revert NotAllowed(msg.sender);
        }
        _;
    }
    
    event StatusSet(bytes32[] indexed exchanges, bool[] status);
    event AllowedSet(address indexed who, bool allowed);
    event TickersSet(bytes32[] indexed tickers, bytes32[] indexed exchanges);

    /// @notice Deploy the contract with the tickers and exchanges
    /// @dev Tickers and exchanges are set to false by default
    /// @param _tickers The bytes32 tickers to track. ex: AAPL => bytes32("AAPL")
    /// @param _exchanges The bytes32 exchanges to be track. ex: NASDAQ => bytes32("NASDAQ")
    /// @param _owner The owner of the contract
    /// @param _gelato The gelato address
    constructor(bytes32[] memory _tickers, bytes32[] memory _exchanges, address _owner, address _gelato) {
        allowed[_owner] = true;
        allowed[_gelato] = true;
        _setStatus(_exchanges, new bool[](_exchanges.length));
        _setTickers(_tickers, _exchanges);
        _transferOwnership(_owner);
    }


    /// @notice Gelato function, Set the status of the exchanges
    /// @dev Only the owner or gelato can call this function
    /// @param _exchanges The exchanges to set the status. ex: bytes32("NASDAQ")
    /// @param _status The status of the exchanges. true for open, false for closed
    function setStatus(bytes32[] calldata _exchanges, bool[] calldata _status) external onlyAllowed {
        _setStatus(_exchanges, _status);
    }

    // Admin functions
    
    /// @notice Set the allowed status of an address
    /// @dev Only the owner can call this function
    /// @param _who The address to set the allowed status
    /// @param _allowed The allowed status
    function setAllowed(address _who, bool _allowed) external onlyOwner { 
        allowed[_who] = _allowed;
        emit AllowedSet(_who, _allowed);
    }

    /// @notice Set the tickers and exchanges
    /// @dev Only the owner can call this function
    /// @param _tickers The hashed tickers to track. ex: AAPL => bytes32("AAPL")
    /// @param _exchanges The hashed exchanges to be track. ex: NASDAQ => bytes32("NASDAQ")
    function setTickers(bytes32[] memory _tickers, bytes32[] memory _exchanges) external onlyOwner {
        _setTickers(_tickers, _exchanges);
    }

    function _setStatus(bytes32[] memory _exchanges, bool[] memory _status) internal {
        uint256 length = _exchanges.length;
        if(length != _status.length) revert InvalidInput();

        for(uint256 i; i < length;) {
            status[_exchanges[i]] = _status[i] == true ? 2 : 1;
            unchecked {
                ++i;
            }
        }
        emit StatusSet(_exchanges, _status);
    }

    function _setTickers(bytes32[] memory _tickers, bytes32[] memory _exchanges) internal {
        uint256 length = _tickers.length;
        if(length != _exchanges.length) revert InvalidInput();
        
        for(uint256 i; i < length;) {
            exchanges[_tickers[i]] = _exchanges[i];
            unchecked {
                ++i;
            }
        }
        emit TickersSet(_tickers, _exchanges);
    }
    
    
    // View functions

    /// @notice Get the status of the exchange
    /// @param exchange The exchange to get the status (ex bytes32("NASDAQ"))
    /// @return The status of the exchange
    function getExchangeStatus(bytes32 exchange) public view returns(bool) {
        uint256 currentStatus = status[exchange];
        if(currentStatus == 0) revert InvalidExchange(exchange);
        return currentStatus == 2;
    }

    /// @notice Get the exchange of the ticker
    /// @param ticker The ticker to get the exchange
    /// @return The exchange of the ticker (hashed ex keccak256("NASDAQ"))
    function getTickerExchange(bytes32 ticker) external view returns(bytes32) {
        bytes32 exchange = exchanges[ticker];
        if(exchange == 0x0) revert InvalidTicker(ticker);
        return exchange;
    }

    /// @notice Get the status of the ticker
    /// @param ticker The ticker to get the status (ex AAPL)
    /// @return The status of the ticker
    function getTickerStatus(bytes32 ticker) public view returns(bool) {
        bytes32 exchange = exchanges[ticker];
        if(exchange == 0x0) revert InvalidTicker(ticker);
        return status[exchange] == 2;
    }

    /// @notice Get the status of the exchanges
    /// @param _exchanges The exchanges to get the status
    /// @return The status of the exchanges
    function getExchangeStatuses(bytes32[] calldata _exchanges) external view returns(bool[] memory) {
        uint256 length = _exchanges.length;
        bool[] memory statuses = new bool[](length);
        for(uint256 i; i < length;) {
            statuses[i] = getExchangeStatus(_exchanges[i]);
            unchecked {
                ++i;
            }
        }
        return statuses;
    }

    /// @notice Get the status of the tickers
    /// @param _tickers The tickers to get the status
    /// @return The status of the tickers
    function getTickerStatuses(bytes32[] memory _tickers) external view returns(bool[] memory) {
        uint256 length = _tickers.length;
        bool[] memory statuses = new bool[](length);
        for(uint256 i; i < length;) {
            statuses[i] = getTickerStatus(_tickers[i]);
            unchecked {
                ++i;
            }
        }
        return statuses;
    }
}