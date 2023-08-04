// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPriceOracle {
    function exchangePrice(
        address _token
    ) external view returns (uint256 price, uint8 decimals);

    function exchangeRate(
        address token
    ) external view returns (uint256 exchangeRate);

    function getValueOf(
        address tokenIn,
        address quote,
        uint256 amountIn
    ) external view returns (uint256 value);
}

abstract contract PriceOracle is IPriceOracle, Ownable {
    mapping(address => address) internal priceFeed;
    mapping(address => uint256) internal decimals;
    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    function setPriceFeed(
        address token,
        address aggregator
    ) external onlyOwner {
        require(aggregator != address(0), "Invalid aggregator address");
        priceFeed[token] = aggregator;
    }

    function exchangePrice(
        address token
    ) public view virtual override returns (uint256 price, uint8 decimals);

    function exchangeRate(
        address token
    ) external view virtual override returns (uint256 price) {
        price = getValueOf(NATIVE_TOKEN, token, 1 ether);
        require(price != 0, "Price Oracle: Price is 0");
    }

    function getValueOf(
        address tokenIn,
        address quote,
        uint256 amountIn
    ) public view virtual override returns (uint256 value) {
        (uint256 priceIn, uint8 decimalsIn) = exchangePrice(tokenIn);
        (uint256 priceQuote, uint8 decimalsQuote) = exchangePrice(quote);

        if (
            decimalsIn + tokenDecimals(tokenIn) >
            decimalsQuote + tokenDecimals(quote)
        ) {
            value =
                (amountIn * priceIn) /
                (priceQuote *
                    10 **
                        (decimalsIn +
                            tokenDecimals(tokenIn) -
                            (tokenDecimals(quote) + decimalsQuote)));
        } else {
            value =
                ((amountIn * priceIn) *
                    10 **
                        (decimalsQuote +
                            tokenDecimals(quote) -
                            (tokenDecimals(tokenIn) + decimalsIn))) /
                priceQuote;
        }
    }

    function tokenDecimals(address _token) public view returns (uint256) {
        return
            decimals[_token] == 0
                ? IERC20Metadata(_token).decimals()
                : decimals[_token];
    }

    function setDecimals(address _token, uint256 _decimals) external onlyOwner {
        decimals[_token] = _decimals;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../interfaces/IPriceOracle.sol";

contract ChainlinkOracleAdapter is PriceOracle {
    constructor(address _owner) PriceOracle(_owner) {}

    uint256 public immutable DEFAULT_TIMEOUT = 1 days;
    mapping(address => uint256) public timeouts;

    function exchangePrice(
        address token
    ) public view virtual override returns (uint256 price, uint8 decimals) {
        AggregatorV3Interface tokenPriceFeed = AggregatorV3Interface(
            priceFeed[token]
        );
        require(
            tokenPriceFeed != AggregatorV3Interface(address(0)),
            "tokenPriceFeed is not setted"
        );
        (
            ,
            /* uint80 roundID */ int256 _price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            uint256 timeStamp,

        ) = tokenPriceFeed.latestRoundData();

        require(
            timeStamp + getTimeout(token) > block.timestamp,
            "price is outdated"
        );
        //  price -> uint256
        require(_price >= 0, "price is negative");
        price = uint256(_price);
        decimals = tokenPriceFeed.decimals();
    }

    function setTimeout(address token, uint256 timeout) public onlyOwner {
        timeouts[token] = timeout;
    }

    function getTimeout(address token) public view returns (uint256) {
        uint256 timeout = timeouts[token];
        return timeout == 0 ? DEFAULT_TIMEOUT : timeout;
    }
}