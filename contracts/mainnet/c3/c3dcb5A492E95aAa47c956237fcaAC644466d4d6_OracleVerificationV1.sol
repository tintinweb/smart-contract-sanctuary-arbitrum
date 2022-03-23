// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./interfaces/IOracleVerificationV1.sol";
import "./libs/TimeoutChecker.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract OracleVerificationV1 is IOracleVerificationV1 {
	using SafeMathUpgradeable for uint256;

	uint256 public constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%
	uint256 public constant MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 5e16; // 5%
	uint256 public constant TIMEOUT = 4 hours;

	function verify(RequestVerification memory request) external view override returns (uint256 value) {
		bool isPrimaryOracleBroken = _isRequestBroken(request.primaryResponse);
		bool isSecondaryOracleBroken = _isRequestBroken(request.secondaryResponse);

		bool oraclesSamePrice = _bothOraclesSimilarPrice(
			request.primaryResponse.currentPrice,
			request.secondaryResponse.currentPrice
		);

		if (!isPrimaryOracleBroken) {
			// If Oracle price has changed by > 50% between two consecutive rounds
			if (_oraclePriceChangeAboveMax(request.primaryResponse.currentPrice, request.primaryResponse.lastPrice)) {
				if (isSecondaryOracleBroken) return request.lastGoodPrice;

				return oraclesSamePrice ? request.primaryResponse.currentPrice : request.secondaryResponse.currentPrice;
			}

			return request.primaryResponse.currentPrice;
		} else if (!isSecondaryOracleBroken) {
			if (
				_oraclePriceChangeAboveMax(request.secondaryResponse.currentPrice, request.secondaryResponse.lastPrice)
			) {
				return request.lastGoodPrice;
			}

			return request.secondaryResponse.currentPrice;
		}

		return request.lastGoodPrice;
	}

	function _isRequestBroken(IOracleWrapper.SavedResponse memory response) internal view returns (bool) {
		bool isTimeout = TimeoutChecker.isTimeout(response.lastUpdate, TIMEOUT);
		return isTimeout || response.currentPrice == 0 || response.lastPrice == 0;
	}

	function _oraclePriceChangeAboveMax(uint256 _currentResponse, uint256 _prevResponse)
		internal
		pure
		returns (bool)
	{
		uint256 minPrice = _min(_currentResponse, _prevResponse);
		uint256 maxPrice = _max(_currentResponse, _prevResponse);

		/*
		 * Use the larger price as the denominator:
		 * - If price decreased, the percentage deviation is in relation to the the previous price.
		 * - If price increased, the percentage deviation is in relation to the current price.
		 */
		uint256 percentDeviation = maxPrice.sub(minPrice).mul(1e18).div(maxPrice);

		// Return true if price has more than doubled, or more than halved.
		return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
	}

	function _bothOraclesSimilarPrice(uint256 _primaryOraclePrice, uint256 _secondaryOraclePrice)
		internal
		pure
		returns (bool)
	{
		if (_secondaryOraclePrice == 0 || _primaryOraclePrice == 0) return false;

		// Get the relative price difference between the oracles. Use the lower price as the denominator, i.e. the reference for the calculation.
		uint256 minPrice = _min(_primaryOraclePrice, _secondaryOraclePrice);
		uint256 maxPrice = _max(_primaryOraclePrice, _secondaryOraclePrice);

		uint256 percentPriceDifference = maxPrice.sub(minPrice).mul(1e18).div(minPrice);

		/*
		 * Return true if the relative price difference is <= 3%: if so, we assume both oracles are probably reporting
		 * the honest market price, as it is unlikely that both have been broken/hacked and are still in-sync.
		 */
		return percentPriceDifference <= MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES;
	}

	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}
}

// SPDX-License-Identifier:SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./IOracleWrapper.sol";

interface IOracleVerificationV1 {
	enum Status {
		PrimaryOracleWorking,
		SecondaryOracleWorking,
		BothUntrusted
	}

	struct RequestVerification {
		uint256 lastGoodPrice;
		IOracleWrapper.SavedResponse primaryResponse;
		IOracleWrapper.SavedResponse secondaryResponse;
	}

	function verify(RequestVerification memory request) external view returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

library TimeoutChecker {
	function isTimeout(uint256 timestamp, uint256 timeout) internal view returns (bool) {
		if (block.timestamp < timestamp) return true;
		return block.timestamp - timestamp > timeout;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.11;

interface IOracleWrapper {
	struct SavedResponse {
		uint256 currentPrice;
		uint256 lastPrice;
		uint256 lastUpdate;
	}

	error TokenIsNotRegistered(address _token);
	error ResponseFromOracleIsInvalid(address _token, address _oracle);

	function fetchPrice(address _token) external;

	function retriveSavedResponses(address _token) external returns (SavedResponse memory currentResponse);

	function getLastPrice(address _token) external view returns (uint256);

	function getCurrentPrice(address _token) external view returns (uint256);
}