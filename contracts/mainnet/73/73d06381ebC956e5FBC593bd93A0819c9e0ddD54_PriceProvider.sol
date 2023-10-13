// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";

contract ContextUpgradeable is Initializable {
	function __Context_init() internal onlyInitializing {}

	function __Context_init_unchained() internal onlyInitializing {}

	function _msgSender() internal view virtual returns (address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this;
		return msg.data;
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	bool private initialized;

	/**
	 * @dev Indicates that the contract is in the process of being initialized.
	 */
	bool private initializing;

	/**
	 * @dev Modifier to use in the initializer function of a contract.
	 */
	modifier initializer() {
		require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

		bool isTopLevelCall = !initializing;
		if (isTopLevelCall) {
			initializing = true;
			initialized = true;
		}

		_;

		if (isTopLevelCall) {
			initializing = false;
		}
	}

	/// @dev Returns true if and only if the function is running in the constructor
	function isConstructor() private view returns (bool) {
		// extcodesize checks the size of the code stored in an address, and
		// address returns the current address. Since the code is still not
		// deployed when running a constructor, any checks on its code size will
		// yield zero, making it an effective way to detect if a contract is
		// under construction or not.
		uint256 cs;
		//solium-disable-next-line
		assembly {
			cs := extcodesize(address())
		}
		return cs == 0;
	}

	modifier onlyInitializing() {
		require(initializing, "Initializable: contract is not initializing");
		_;
	}

	// Reserved storage space to allow for layout changes in the future.
	uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";

contract OwnableUpgradeable is Initializable, ContextUpgradeable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function __Ownable_init() internal onlyInitializing {
		__Ownable_init_unchained();
	}

	function __Ownable_init_unchained() internal onlyInitializing {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}

	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IBaseOracle {
	function latestAnswer() external view returns (uint256 price);

	function latestAnswerInEth() external view returns (uint256 price);

	function update() external;

	function canUpdate() external view returns (bool);

	function consult() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IChainlinkAdapter {
	function latestAnswer() external view returns (uint256 price);

	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface IEligibilityDataProvider {
	function refresh(address user) external returns (bool currentEligibility);

	function updatePrice() external;

	function requiredEthValue(address user) external view returns (uint256 required);

	function isEligibleForRewards(address _user) external view returns (bool isEligible);

	function lastEligibleTime(address user) external view returns (uint256 lastEligibleTimestamp);

	function lockedUsdValue(address user) external view returns (uint256);

	function requiredUsdValue(address user) external view returns (uint256 required);

	function lastEligibleStatus(address user) external view returns (bool);

	function rewardEligibleAmount(address token) external view returns (uint256);

	function setDqTime(address _user, uint256 _time) external;

	function getDqTime(address _user) external view returns (uint256);

	function autoprune() external returns (uint256 processed);

	function requiredDepositRatio() external view returns (uint256);

	function RATIO_DIVISOR() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolHelper {
	function lpTokenAddr() external view returns (address);

	function zapWETH(uint256 amount) external returns (uint256);

	function zapTokens(uint256 _wethAmt, uint256 _rdntAmt) external returns (uint256);

	function quoteFromToken(uint256 tokenAmount) external view returns (uint256 optimalWETHAmount);

	function quoteWETH(uint256 lpAmount) external view returns (uint256 wethAmount);

	function getLpPrice(uint256 rdntPriceInEth) external view returns (uint256 priceInEth);

	function getReserves() external view returns (uint256 rdnt, uint256 weth, uint256 lpTokenSupply);

	function getPrice() external view returns (uint256 priceInEth);

	function quoteSwap(address _inToken, uint256 _wethAmount) external view returns (uint256 tokenAmount);

	function swapToWeth(address _inToken, uint256 _amount, uint256 _minAmountOut) external;
}

interface IBalancerPoolHelper is IPoolHelper {
	function initializePool(string calldata _tokenName, string calldata _tokenSymbol) external;
}

interface IUniswapPoolHelper is IPoolHelper {
	function initializePool() external;
}

interface ITestPoolHelper is IPoolHelper {
	function sell(uint256 _amount) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import {Initializable} from "../../dependencies/openzeppelin/upgradeability/Initializable.sol";
import {OwnableUpgradeable} from "../../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import {IBaseOracle} from "../../interfaces/IBaseOracle.sol";
import {IPoolHelper} from "../../interfaces/IPoolHelper.sol";
import {IChainlinkAdapter} from "../../interfaces/IChainlinkAdapter.sol";
import {IEligibilityDataProvider} from "../../interfaces/IEligibilityDataProvider.sol";

/// @title PriceProvider Contract
/// @author Radiant
contract PriceProvider is Initializable, OwnableUpgradeable {
	/// @notice Chainlink aggregator for USD price of base token
	/// @custom:oz-renamed-from baseTokenPriceInUsdProxyAggregator
	IChainlinkAdapter public baseAssetChainlinkAdapter;

	/// @notice Pool helper contract - Uniswap/Balancer
	IPoolHelper public poolHelper;

	/// @notice Legacey state variable, kept to preserve storage layout
	IEligibilityDataProvider public eligibilityProvider;

	/// @notice Selected RDNT Oracle
	IBaseOracle public oracle;

	bool public usePool;

	error AddressZero();

	error InvalidOracle();

	/********************** Events ***********************/

	event OracleUpdated(address indexed _newOracle);

	event PoolHelperUpdated(address indexed _poolHelper);

	event AggregatorUpdated(address indexed _baseTokenPriceInUsdProxyAggregator);

	event UsePoolUpdated(bool indexed _usePool);

	/**
	 * @notice Initializer
	 * @param _baseAssetChainlinkAdapter Chainlink aggregator for USD price of base token
	 * @param _poolHelper Pool helper contract - Uniswap/Balancer
	 */
	function initialize(IChainlinkAdapter _baseAssetChainlinkAdapter, IPoolHelper _poolHelper) public initializer {
		if (address(_baseAssetChainlinkAdapter) == (address(0))) revert AddressZero();
		if (address(_poolHelper) == (address(0))) revert AddressZero();
		__Ownable_init();

		poolHelper = _poolHelper;
		baseAssetChainlinkAdapter = IChainlinkAdapter(_baseAssetChainlinkAdapter);
		usePool = true;
	}

	/**
	 * @notice Update oracles.
	 */
	function update() public {
		if (address(oracle) != address(0) && oracle.canUpdate()) {
			oracle.update();
		}
	}

	/**
	 * @notice Returns the latest price in eth.
	 */
	function getTokenPrice() public view returns (uint256 priceInEth) {
		if (usePool) {
			// use sparingly, TWAP/CL otherwise
			priceInEth = poolHelper.getPrice();
		} else {
			priceInEth = oracle.latestAnswerInEth();
		}
	}

	/**
	 * @notice Returns the latest price in USD.
	 */
	function getTokenPriceUsd() public view returns (uint256 price) {
		// use sparingly, TWAP/CL otherwise
		if (usePool) {
			uint256 ethPrice = baseAssetChainlinkAdapter.latestAnswer();
			uint256 priceInEth = poolHelper.getPrice();
			price = (priceInEth * uint256(ethPrice)) / (10 ** 8);
		} else {
			price = oracle.latestAnswer();
		}
	}

	/**
	 * @notice Returns lp token price in ETH.
	 */
	function getLpTokenPrice() public view returns (uint256) {
		// decis 8
		uint256 rdntPriceInEth = getTokenPrice();
		return poolHelper.getLpPrice(rdntPriceInEth);
	}

	/**
	 * @notice Returns lp token price in USD.
	 */
	function getLpTokenPriceUsd() public view returns (uint256 price) {
		// decimals 8
		uint256 lpPriceInEth = getLpTokenPrice();
		// decimals 8
		uint256 ethPrice = baseAssetChainlinkAdapter.latestAnswer();
		price = (lpPriceInEth * uint256(ethPrice)) / (10 ** 8);
	}

	/**
	 * @notice Returns lp token address.
	 */
	function getLpTokenAddress() public view returns (address) {
		return poolHelper.lpTokenAddr();
	}

	/**
	 * @notice Sets new oracle.
	 */
	function setOracle(address _newOracle) external onlyOwner {
		if (_newOracle == address(0)) revert AddressZero();
		oracle = IBaseOracle(_newOracle);
		emit OracleUpdated(_newOracle);
	}

	/**
	 * @notice Sets pool helper contract.
	 */
	function setPoolHelper(address _poolHelper) external onlyOwner {
		poolHelper = IPoolHelper(_poolHelper);
		if (getLpTokenPrice() == 0) revert InvalidOracle();
		emit PoolHelperUpdated(_poolHelper);
	}

	/**
	 * @notice Sets base token price aggregator.
	 */
	function setAggregator(address _baseAssetChainlinkAdapter) external onlyOwner {
		baseAssetChainlinkAdapter = IChainlinkAdapter(_baseAssetChainlinkAdapter);
		if (getLpTokenPriceUsd() == 0) revert InvalidOracle();
		emit AggregatorUpdated(_baseAssetChainlinkAdapter);
	}

	/**
	 * @notice Sets option to use pool.
	 */
	function setUsePool(bool _usePool) external onlyOwner {
		usePool = _usePool;
		emit UsePoolUpdated(_usePool);
	}

	/**
	 * @notice Returns decimals of price.
	 */
	function decimals() public pure returns (uint256) {
		return 8;
	}
}