// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
pragma solidity ^0.8.14;

interface IOracle {
	function fetchPrice() external returns (uint256);
    function getDirectPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Observation {
  uint256 timestamp;
  uint256 reserve0Cumulative;
  uint256 reserve1Cumulative;
}

interface IRamsesPair {
  function observations(uint256 index) external pure returns (Observation memory);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function metadata()
    external
    view
    returns (
      uint256 dec0,
      uint256 dec1,
      uint256 r0,
      uint256 r1,
      bool st,
      address t0,
      address t1
    );

  function claimFees() external returns (uint256, uint256);

  function tokens() external returns (address, address);

  function stable() external view returns (bool);

  function observationLength() external view returns (uint256);

  function lastObservation() external view returns (Observation memory);

  function current(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);

  function currentCumulativePrices()
    external
    view
    returns (
      uint256 reserve0Cumulative,
      uint256 reserve1Cumulative,
      uint256 blockTimestamp
    );

  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function mint(address to) external returns (uint256 liquidity);

  function sync() external;

  function transfer(address dst, uint256 amount) external returns (bool);

  function getReserves()
    external
    view
    returns (
      uint256 _reserve0,
      uint256 _reserve1,
      uint256 _blockTimestampLast
    );

  function getAmountOut(uint256, address) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../Interfaces/IRamsesPair.sol";
import "../Interfaces/IOracle.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract sfrxETHOracle is IOracle, Ownable{

	struct VolatilityStats {
		uint256 lastRate;
		uint256 lastCheckTime;
		uint256 checkFrequency;
	}
	
	mapping(address => VolatilityStats) public assetStats;

	uint256 public maxDeviationAllowance;
	uint256 public maxDeviationForUpdate;

	AggregatorV3Interface public immutable chainlink;
	address public immutable frxETHETH;
	address public immutable weth;
	address public immutable frxETH;
	address public immutable sfrxETH;
	address public keeper;

	// Use to convert a price answer to an 18-digit precision uint
	uint256 public constant TARGET_DECIMAL_1E18 = 1e18;

	constructor(
		address _frxETHWETH,
		address _weth,
		address _frxETH,
		address _sfrxETH,
		address _chainlink
	) {
		require(_frxETHWETH != address(0), "Invalid frxETHETH address");
		require(_weth != address(0), "Invalid weth address");
		require(_chainlink != address(0), "Invalid chainlink address");
		
		weth = _weth;
		frxETH = _frxETH;
		frxETHETH = _frxETHWETH;
		chainlink = AggregatorV3Interface(_chainlink);
		sfrxETH = _sfrxETH;
		keeper = msg.sender;
		maxDeviationAllowance = 3e16; //3%
		maxDeviationForUpdate = 15e15; //1.5%

		assetStats[frxETH].checkFrequency = 3600; // 1 hour
		assetStats[sfrxETH].checkFrequency = 1 days;
	}

	function setKeeper(address _keeper) external onlyOwner {
		require(_keeper != address(0), "Invalid keeper address");
		keeper = _keeper;
	}

	/**
	* @notice Get the token price price for an underlying token address.
	* @return Price denominated in USDC
	*/
	function getDirectPrice() external view returns (uint256) {
		uint256 _WETHUSDPrice = _getChainlinkPrice();
		uint256 _frxETHPrice = priceRamses(weth, IRamsesPair(frxETHETH));
		uint256 _frxETHAnchorPrice = assetStats[frxETH].lastRate;
		uint256 _sfrxRates = assetStats[sfrxETH].lastRate;

		require(_validatePrice(_frxETHPrice, _frxETHAnchorPrice, maxDeviationAllowance), "Price deviation too large");
		require(block.timestamp - assetStats[sfrxETH].lastCheckTime < assetStats[sfrxETH].checkFrequency + 30 * 60
		,"Price record is too old");

		uint256 _frxETHPriceUSD = _WETHUSDPrice * _frxETHPrice / TARGET_DECIMAL_1E18;
		return _frxETHPriceUSD * _sfrxRates / TARGET_DECIMAL_1E18;
	}

	/**
	* @notice Get and Update the token price price for an underlying token address.
	* @return Price denominated in　USDC
	*/
	function fetchPrice() external returns (uint256) {
			
		uint256 _WETHUSDPrice = _getChainlinkPrice();
		uint256 _frxETHPrice = priceRamses(weth, IRamsesPair(frxETHETH));
		uint256 _frxETHAnchorPrice = assetStats[frxETH].lastRate;
		uint256 _sfrxRates = assetStats[sfrxETH].lastRate;

		require(_validatePrice(_frxETHPrice, _frxETHAnchorPrice, maxDeviationAllowance), "Price deviation too large");
	 	require(block.timestamp - assetStats[sfrxETH].lastCheckTime < assetStats[sfrxETH].checkFrequency + 30 * 60
 		,"Price record is too old");

		uint256 _frxETHPriceUSD = _WETHUSDPrice * _frxETHPrice / TARGET_DECIMAL_1E18;
		return _frxETHPriceUSD * _sfrxRates / TARGET_DECIMAL_1E18;

	}

	/**
	* @notice Return true if price update is needed
	* @return true or false
	*/
	function isRateUpdateNeeded (address _token, uint256 _price) external view returns (bool) {
		require(assetStats[_token].checkFrequency > 0, "Invalid token address");
		uint256 _updateTime = assetStats[_token].lastCheckTime +  assetStats[_token].checkFrequency; 
		bool isPriceValid = true;
		if(_token == frxETH){
			isPriceValid = _validatePrice(_price, assetStats[_token].lastRate, maxDeviationForUpdate);
		}
		if(block.timestamp > _updateTime || !isPriceValid ){
			return true;
		} else {
			return false;
		}
	}

	function setDeviationAlloance(uint256 _allowance) external onlyOwner {
		maxDeviationAllowance = _allowance;
	}

	function setDeviationForUpdate(uint256 _deviation) external onlyOwner {
		maxDeviationForUpdate = _deviation;
	}
	
	function setCheckFrequency(address _token, uint256 _frequency) external onlyOwner {
		require(assetStats[_token].checkFrequency > 0, "Invalid token address");
		assetStats[_token].checkFrequency = _frequency;
	}

	function getCheckFrequency(address _token) external view returns (uint256) {
		return assetStats[_token].checkFrequency;
	}
	
	function commitRate(address _token, uint256 _rates, uint256 _time) external {
		require(msg.sender == keeper, "Only keeper can commit rates");
		require(assetStats[_token].checkFrequency > 0, "Invalid token address");
		require(_time > assetStats[_token].lastCheckTime, "Time does not go back");
		require(_time < block.timestamp + 3, "Future time");
		assetStats[_token].lastRate = _rates;
		assetStats[_token].lastCheckTime = _time;
	}

	function getRate(address _token) external view returns (uint256) {
		return assetStats[_token].lastRate;
	}

	/**
	* @dev Fetches the price for a token from Solidly Pair
	*/
	function priceRamses(address _baseToken, IRamsesPair _pair) public view returns (uint256) {

		address _token0 = _pair.token0();
		address _token1 = _pair.token1();
		address _quoteToken;

		_baseToken == _token0 ? _quoteToken = _token1 : _quoteToken = _token0;

		// base token is USD or another token
		uint256 _baseTokensPerQuoteToken = _pair.current(_quoteToken, 10**uint256(IERC20Metadata(_quoteToken).decimals()));
		
		// scale tokenPrice by TARGET_DECIMAL_1E18
		uint256 _baseTokenDecimals = uint256(IERC20Metadata(_baseToken).decimals());
		uint256 _tokenPriceScaled;

		if (_baseTokenDecimals > 18) {
			_tokenPriceScaled = _baseTokensPerQuoteToken / (10**(_baseTokenDecimals - 18));
		} else {
			_tokenPriceScaled = _baseTokensPerQuoteToken * (10**(18 - _baseTokenDecimals));
		}
	
		return _tokenPriceScaled;

	}

	function _validatePrice(uint256 _price, uint256 _anchorPrice, uint256 _maxDeviationRate) internal pure returns (bool) {
		require(_price > 0, "Price is zero");
		uint256 _maxDeviation = _anchorPrice * _maxDeviationRate / TARGET_DECIMAL_1E18;
		if(_price > _anchorPrice){
			uint256 _deviation = _price - _anchorPrice;
			return _deviation <= _maxDeviation;
		} else {
			uint256 _deviation = _anchorPrice - _price;
			return _deviation <= _maxDeviation;
		}
	}

	function _getChainlinkPrice() internal view returns (uint256) {
		(, int256 _priceInt, , uint256 _updatedAt, ) = chainlink.latestRoundData();
		require(_updatedAt > block.timestamp - 24 hours, "Chainlink price outdated");
		return uint256(_priceInt) * TARGET_DECIMAL_1E18 / 1e8;
	}
	
}