/**
 *Submitted for verification at Arbiscan on 2023-04-10
*/

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}




pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
////import "./SafeMath.sol";
interface IAggregator {
    /// A structure returned whenever someone requests for standard reference data.
    // struct ReferenceData {
    //     uint256 rate; // base/quote exchange rate, multiplied by 1e18.
    //     uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
    //     uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    // }

    // /// Returns the price data for the given base/quote pair. Revert if not available.
    // function getReferenceData(string calldata _base, string calldata _quote)
    //     external
    //     view
    //     returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    // function getReferenceDataBulk(string[] calldata _bases, string[] calldata _quotes)
    //     external
    //     view
    //     returns (ReferenceData[] memory);


  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,       //decimals 1e8
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


contract MockOracleAnchoredView {
	using SafeMath for uint;
	string constant public quote = "USD";

	mapping(string => OracleTokenConfig) CTokenConfigs;
	mapping(address => string) cTokenSymbol;
	mapping(string => int256) prices;

	struct OracleTokenConfig {
		IAggregator aggregator;
    	address cToken;
    	address underlying;
    	string  symbol;
    	int256  baseUnit;
	}
	constructor(OracleTokenConfig[] memory configs) public {
		for(uint i = 0; i < configs.length; i++){
			OracleTokenConfig memory config = configs[i];
			require(config.baseUnit > 0, "baseUnit must be greater than zero");
			CTokenConfigs[config.symbol] = config;
			cTokenSymbol[config.cToken] = config.symbol;
		}
	}  

	function price(string calldata symbol) external view returns (int256) {
		return priceInternal(symbol);
    }

	function priceInternal(string memory symbol) internal view returns (int256) {
		require(CTokenConfigs[symbol].cToken != address(0),"config not found");
		if (prices[symbol] > 0) {
			return prices[symbol];
		} 
		// IStdReference.ReferenceData memory data =  ref.getReferenceData(symbol, quote);
		// require(data.rate > 0,"price can not be 0");
		// return int256(data.rate.div(1e10));
		(,int256 answer,,,) = CTokenConfigs[symbol].aggregator.latestRoundData();
	  return answer;

		
    }

	function getUnderlyingPrice(address cToken) external view returns (int256) {
		string memory symbol = cTokenSymbol[cToken];
		OracleTokenConfig memory config = CTokenConfigs[symbol];
		int256 rate = priceInternal(symbol);
		return int256div(int256mul(1e28,rate),config.baseUnit);
    }

	function setPrice(string calldata symbol,int256 price) external returns(int256){
		require(CTokenConfigs[symbol].cToken != address(0),"config not found");
		prices[symbol] = price;
	}


	function int256mul(int256 a, int256 b) internal pure returns (int256) {
   
        if (a == 0) {
            return 0;
        }

        int256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function int256div(int256 a, int256 b) internal pure returns (int256) {
        return int256div(a, b, "SafeMath: division by zero");
    }

    function int256div(int256 a, int256 b, string memory errorMessage) internal pure returns (int256) {

        require(b > 0, errorMessage);
        int256 c = a / b;
       

        return c;
    }


}