// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/oracles/IWINROracleRouter.sol";
import "../interfaces/oracles/IPriceFeed.sol";
import "../interfaces/oracles/IChainlinkFlags.sol";

contract WINROracleRouter is Pausable, Ownable, IWINROracleRouter {
	uint256 public constant PRICE_PRECISION = 1e30;
	uint256 public constant ONE_USD = PRICE_PRECISION;
	uint256 public constant CHAINLINK_PRICE_PRECISION = 1e8;
	address private constant FLAG_ARBITRUM_SEQ_OFFLINE =
		address(
			bytes20(
				bytes32(
					uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) -
						1
				)
			)
		);

	address public immutable controllerAddress;
	address public immutable chainlinkFlagAddress;
	IChainlinkFlags public immutable chainlinkFlags;

	// tokenaddress => chainlink price feed address
	mapping(address => address) public priceFeeds;

	mapping(address => IPriceFeed) public priceFeedsInterface;

	// tokenaddress => price decimals of cl return
	mapping(address => uint256) public priceDecimals;

	// tokenaddress => is stablecoin
	mapping(address => bool) public isStableCoin;

	constructor(address _controllerAddress, address _chainlinkFlagAddress) {
		controllerAddress = _controllerAddress;
		chainlinkFlagAddress = _chainlinkFlagAddress;
		chainlinkFlags = IChainlinkFlags(_chainlinkFlagAddress);
		_transferOwnership(_controllerAddress);
	}

	function pauseOracle() external onlyOwner {
		_pause();
	}

	function unpauseOracle() external onlyOwner {
		_unpause();
	}

	function addToken(
		address _token,
		address _priceFeed,
		uint256 _priceDecimals,
		bool _isStableCoin
	) external onlyOwner {
		// check if token is already added
		require(priceFeeds[_token] == address(0), "WINROracleRouter: token exists");

		IPriceFeed priceFeed = IPriceFeed(_priceFeed);

		// check if price feed is valid
		int256 latestAnswer = priceFeed.latestAnswer();
		require(latestAnswer > 0, "WINROracleRouter: invalid price feed");

		// check if latestRound is non zero
		uint80 latestRound = priceFeed.latestRound();
		require(latestRound > 0, "WINROracleRouter: invalid price feed");

		priceFeeds[_token] = _priceFeed;
		priceFeedsInterface[_token] = IPriceFeed(_priceFeed);
		priceDecimals[_token] = _priceDecimals;
		isStableCoin[_token] = _isStableCoin;

		emit TokenAdded(_token, _priceFeed, _priceDecimals, _isStableCoin);
	}

	// add remove token function
	function removeToken(address _token) external onlyOwner {
		require(priceFeeds[_token] != address(0), "WINROracleRouter: token not exists");
		delete priceFeeds[_token];
		delete priceFeedsInterface[_token];
		delete priceDecimals[_token];
		delete isStableCoin[_token];
		emit TokenRemoved(_token);
	}

	function getPriceMax(address _token) external view returns (uint256 price_) {
		_checkChainlinkFlagsAndPausable();
		price_ = _getPriceChainlink(_token);
	}

	function getPriceMin(address _token) external view returns (uint256 price_) {
		_checkChainlinkFlagsAndPausable();
		price_ = _getPriceChainlink(_token);
	}

	function _checkChainlinkFlagsAndPausable() internal view {
		_requireNotPaused();
		require(
			!chainlinkFlags.getFlag(FLAG_ARBITRUM_SEQ_OFFLINE),
			"WINROracleRouter: Arbitrum sequence is offline"
		);
	}

	function _getPriceChainlink(address _token) internal view returns (uint256 priceScaled_) {
		IPriceFeed feed_ = priceFeedsInterface[_token];
		require(address(feed_) != address(0), "WINROracleRouter: token not exists");
		int256 price_ = feed_.latestAnswer();
		require(price_ > 0, "WINROracleRouter: invalid price");
		unchecked {
			priceScaled_ =
				(uint256(price_) * PRICE_PRECISION) /
				CHAINLINK_PRICE_PRECISION;
		}
		if (isStableCoin[_token]) {
			priceScaled_ = priceScaled_ > ONE_USD ? ONE_USD : priceScaled_;
			return priceScaled_;
		} else {
			return priceScaled_;
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity 0.8.19;

interface IWINROracleRouter {
	function getPriceMax(address _token) external view returns (uint256 price_);

	function getPriceMin(address _token) external view returns (uint256);

	event TokenAdded(
		address indexed token,
		address indexed priceFeed,
		uint256 priceDecimals,
		bool isStableCoin
	);

	event TokenRemoved(address indexed token);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPriceFeed {
	function description() external view returns (string memory);

	function aggregator() external view returns (address);

	function latestAnswer() external view returns (int256);

	function latestRound() external view returns (uint80);

	function getRoundData(
		uint80 roundId
	) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IChainlinkFlags {
	function getFlag(address) external view returns (bool);
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