// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { IERC20Metadata, IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { WadRayMath } from "@radiant-v2-core/lending/libraries/math/WadRayMath.sol";
import { PercentageMath } from "@radiant-v2-core/lending/libraries/math/PercentageMath.sol";
import { IOracleRouter } from "./interfaces/IOracleRouter.sol";
import { ILendingPoolAddressesProvider } from "@radiant-v2-core/interfaces/ILendingPoolAddressesProvider.sol";
import { DexSwapStrategy } from "./libraries/swap-strategies/DexSwapStrategy.sol";
import { ILendingPool } from "@radiant-v2-core/interfaces/ILendingPool.sol";
import { IAToken } from "@radiant-v2-core/interfaces/IAToken.sol";
import { Errors } from "./libraries/Errors.sol";

enum SwapStrategies {
    AGGREGATOR
}

struct OutputTokenConfig {
    // 10000 = 100%
    uint256 maximumSlippage;
    // 10000 = 100%
    uint256 percentage;
    address priceOracle;
    IAToken rTokenCore;
}

struct SwapInput {
    uint256 amountIn;
    bytes data;
    address inputToken;
    uint256 minOutput;
    address outputToken;
    SwapStrategies swapStrategy;
}

/// @title RevenueManagement contract
/// @author Radiant
contract RevenueManagement is OwnableUpgradeable, PausableUpgradeable {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    /// @notice MiddleFeeDistribution address (MultiFeeDistribution on mainnet)
    address public mfd;

    /// @notice Core markets lending pool
    address public coreLendingPool;

    /// @notice List of output tokens
    address[] public outputTokens;

    //////////////// <*_*> Storage <*_*> ////////////////
    mapping(address => OutputTokenConfig) public outputTokenConfigs;
    mapping(address => IOracleRouter) public inputTokenOracle;
    mapping(address => bool) public isWhitelisted;

    //////////////// =^..^= Events =^..^= ////////////////
    event SetWhitelisted(address indexed account, bool isWhitelisted);
    event TokensAcquired(address indexed token, uint256 amount);
    event InputTokenAdded(address indexed token, IOracleRouter oracle);
    event InputTokenRemoved(address indexed token);
    event OutputTokensConfigUpdated(uint256 outputTokensLength);

    modifier onlyWhitelisted() {
        if (!isWhitelisted[msg.sender]) revert Errors.NotAuthorized();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializer
     * @param _mfd MiddleFeeDistribution address
     * @param _coreLendingPool Core lending pool address
     */
    function initialize(address _mfd, address _coreLendingPool) external initializer {
        if (_mfd == address(0)) revert Errors.AddressZero();
        if (_coreLendingPool == address(0)) revert Errors.AddressZero();

        mfd = _mfd;
        coreLendingPool = _coreLendingPool;

        __Ownable_init();
        __Pausable_init();
    }

    /**
     * @notice Set state for an address in whitelist
     * @param _account Address
     * @param _isWhitelisted Whitelisted state
     */
    function setWhitelist(address _account, bool _isWhitelisted) external onlyOwner {
        if (_account == address(0)) revert Errors.AddressZero();
        isWhitelisted[_account] = _isWhitelisted;
        emit SetWhitelisted(_account, _isWhitelisted);
    }

    /**
     * @notice Set output tokens configuration
     * @param _outputTokens Output tokens
     * @param _configs Output token configurations
     */
    function setOutputTokensConfig(address[] calldata _outputTokens, OutputTokenConfig[] calldata _configs)
        public
        onlyOwner
    {
        if (_outputTokens.length != _configs.length) {
            revert Errors.OutputTokenConfigLengthMismatch();
        }

        delete outputTokens;

        uint256 sumCheck;
        for (uint256 i = 0; i < _configs.length; i++) {
            outputTokens.push(_outputTokens[i]);
            outputTokenConfigs[_outputTokens[i]] = _configs[i];
            sumCheck += _configs[i].percentage;
        }

        if (sumCheck != 10_000) {
            revert Errors.PercentageMismatch();
        }

        emit OutputTokensConfigUpdated(_outputTokens.length);
    }

    /**
     * @notice Adds an input token
     * @param _inputToken Input token
     * @param _inputTokenOracle Input token configuration
     */
    function addInputToken(address _inputToken, IOracleRouter _inputTokenOracle) external onlyOwner {
        if (_inputToken == address(0)) revert Errors.AddressZero();
        if (address(_inputTokenOracle) == address(0)) revert Errors.AddressZero();
        inputTokenOracle[_inputToken] = _inputTokenOracle;
        emit InputTokenAdded(_inputToken, _inputTokenOracle);
    }

    /**
     * @notice Removes an input token
     * @param _inputToken Input token
     */
    function removeInputToken(address _inputToken) external onlyOwner {
        if (address(inputTokenOracle[_inputToken]) == address(0)) revert Errors.TokenNotPresent();
        delete inputTokenOracle[_inputToken];
        emit InputTokenRemoved(_inputToken);
    }

    /**
     * @notice Check if an input token is configured
     * @param _inputToken Address of the token to check
     */
    function isInputTokenValid(address _inputToken) public view returns (bool) {
        return address(inputTokenOracle[_inputToken]) != address(0);
    }

    /**
     * @notice Unwraps rTokens to the underlying tokens
     * @param _rTokens Addresses of the rTokens to unwrap
     * @param _amounts Amounts of the rTokens to unwrap
     */
    function unwrapRToken(IAToken[] calldata _rTokens, uint256[] calldata _amounts) external onlyWhitelisted {
        if (_rTokens.length != _amounts.length) revert Errors.InputTokenConfigLengthMismatch();

        for (uint256 i = 0; i < _rTokens.length; i++) {
            address underlyingToken = _rTokens[i].UNDERLYING_ASSET_ADDRESS();
            uint256 amountToWithdraw = _amounts[i];

            ILendingPool lendingPool = ILendingPool(_rTokens[i].POOL());
            lendingPool.withdraw(underlyingToken, amountToWithdraw, address(this));
        }
    }

    /**
     * @notice Swap tokens
     * @param swapInput Swap input
     */
    function swapTokens(SwapInput[] calldata swapInput) external whenNotPaused onlyWhitelisted {
        // First compute the total value of the input tokens
        uint256 totalInputValue = computeInputValue(swapInput);

        // Get the initial balance of the output tokens so we can see the actual delta later
        uint256[] memory initialOutputTokenBalances = new uint256[](outputTokens.length);
        for (uint256 i = 0; i < outputTokens.length; i++) {
            initialOutputTokenBalances[i] = IERC20(outputTokens[i]).balanceOf(address(this));
        }

        // Perform the swaps as instructed
        for (uint256 i = 0; i < swapInput.length; i++) {
            if (swapInput[i].swapStrategy == SwapStrategies.AGGREGATOR) {
                DexSwapStrategy.swap(
                    swapInput[i].inputToken, swapInput[i].amountIn, swapInput[i].minOutput, swapInput[i].data
                );
            } else {
                revert Errors.InvalidSwapStrategy();
            }
        }

        // Finally verify that the output tokens are within the expected range
        for (uint256 i = 0; i < outputTokens.length; i++) {
            OutputTokenConfig memory outputTokenConfig = outputTokenConfigs[outputTokens[i]];
            uint256 price = IOracleRouter(outputTokenConfig.priceOracle).getAssetPrice(outputTokens[i]);

            uint8 targetTokenDecimals = IERC20Metadata(outputTokens[i]).decimals();

            uint256 targetValue = totalInputValue.percentMul(outputTokenConfig.percentage);

            uint256 targetTokens = (targetValue * 10 ** targetTokenDecimals) / price;

            uint256 actualTokens = IERC20(outputTokens[i]).balanceOf(address(this)) - initialOutputTokenBalances[i];

            emit TokensAcquired(outputTokens[i], actualTokens);

            uint256 maximumSlippage = outputTokenConfig.maximumSlippage;

            if (
                !(
                    actualTokens >= targetTokens.percentMul(10_000 - maximumSlippage)
                        && actualTokens <= targetTokens.percentMul(10_000 + maximumSlippage)
                )
            ) {
                revert Errors.OutputTokenBalanceOutOfRange();
            }

            _depositToCoreLendingPool(outputTokens[i], actualTokens);
        }
    }

    /**
     * @notice Computes the total value of the input tokens
     * @param swapInput Swap input
     */
    function computeInputValue(SwapInput[] calldata swapInput) public view returns (uint256) {
        uint256 totalInputValue = 0;
        for (uint256 i = 0; i < swapInput.length; i++) {
            uint256 price = inputTokenOracle[swapInput[i].inputToken].getAssetPrice(swapInput[i].inputToken);

            uint256 tokenDecimals = IERC20Metadata(swapInput[i].inputToken).decimals();

            uint256 assetValue = (price * swapInput[i].amountIn) / (10 ** tokenDecimals);

            totalInputValue += assetValue;
        }
        return totalInputValue;
    }

    /**
     * @notice Deposit tokens to the core lending pool then transfer to mfd
     * @param _token Address of the token to deposit
     * @param _amount Amount of the token to deposit
     */
    function _depositToCoreLendingPool(address _token, uint256 _amount) internal {
        ILendingPool lendingPool = ILendingPool(coreLendingPool);
        IERC20(_token).approve(coreLendingPool, _amount);
        lendingPool.deposit(_token, _amount, address(this), 0);
        outputTokenConfigs[_token].rTokenCore.transfer(mfd, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
	uint256 internal constant WAD = 1e18;
	uint256 internal constant halfWAD = WAD / 2;

	uint256 internal constant RAY = 1e27;
	uint256 internal constant halfRAY = RAY / 2;

	uint256 internal constant WAD_RAY_RATIO = 1e9;

	/**
	 * @return One ray, 1e27
	 **/
	function ray() internal pure returns (uint256) {
		return RAY;
	}

	/**
	 * @return One wad, 1e18
	 **/

	function wad() internal pure returns (uint256) {
		return WAD;
	}

	/**
	 * @return Half ray, 1e27/2
	 **/
	function halfRay() internal pure returns (uint256) {
		return halfRAY;
	}

	/**
	 * @return Half ray, 1e18/2
	 **/
	function halfWad() internal pure returns (uint256) {
		return halfWAD;
	}

	/**
	 * @dev Multiplies two wad, rounding half up to the nearest wad
	 * @param a Wad
	 * @param b Wad
	 * @return The result of a*b, in wad
	 **/
	function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0 || b == 0) {
			return 0;
		}

		require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (a * b + halfWAD) / WAD;
	}

	/**
	 * @dev Divides two wad, rounding half up to the nearest wad
	 * @param a Wad
	 * @param b Wad
	 * @return The result of a/b, in wad
	 **/
	function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
		uint256 halfB = b / 2;

		require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (a * WAD + halfB) / b;
	}

	/**
	 * @dev Multiplies two ray, rounding half up to the nearest ray
	 * @param a Ray
	 * @param b Ray
	 * @return The result of a*b, in ray
	 **/
	function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0 || b == 0) {
			return 0;
		}

		require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (a * b + halfRAY) / RAY;
	}

	/**
	 * @dev Divides two ray, rounding half up to the nearest ray
	 * @param a Ray
	 * @param b Ray
	 * @return The result of a/b, in ray
	 **/
	function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
		uint256 halfB = b / 2;

		require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (a * RAY + halfB) / b;
	}

	/**
	 * @dev Casts ray down to wad
	 * @param a Ray
	 * @return a casted to wad, rounded half up to the nearest wad
	 **/
	function rayToWad(uint256 a) internal pure returns (uint256) {
		uint256 halfRatio = WAD_RAY_RATIO / 2;
		uint256 result = halfRatio + a;
		require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

		return result / WAD_RAY_RATIO;
	}

	/**
	 * @dev Converts wad up to ray
	 * @param a Wad
	 * @return a converted in ray
	 **/
	function wadToRay(uint256 a) internal pure returns (uint256) {
		uint256 result = a * WAD_RAY_RATIO;
		require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
		return result;
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
	uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
	uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

	/**
	 * @dev Executes a percentage multiplication
	 * @param value The value of which the percentage needs to be calculated
	 * @param percentage The percentage of the value to be calculated
	 * @return The percentage of value
	 **/
	function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
		if (value == 0 || percentage == 0) {
			return 0;
		}

		require(value <= (type(uint256).max - HALF_PERCENT) / percentage, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
	}

	/**
	 * @dev Executes a percentage division
	 * @param value The value of which the percentage needs to be calculated
	 * @param percentage The percentage of the value to be calculated
	 * @return The value divided the percentage
	 **/
	function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
		require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
		uint256 halfPercentage = percentage / 2;

		require(value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR, Errors.MATH_MULTIPLICATION_OVERFLOW);

		return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@radiant-v2-core/interfaces/IPriceOracleGetter.sol";

interface IOracleRouter is IPriceOracleGetter {
    enum OracleProviderType {
        Chainlink,
        Pyth
    }
    // TODO: Add more oracle providers
    /**
     * @notice Get the underlying price of a kToken asset
     * @param asset to get the underlying price of
     * @return The underlying asset price
     *  Zero means the price is unavailable.
     */

    /// @notice Gets a list of prices from a list of assets addresses
    /// @param assets The list of assets addresses
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    /// @notice Gets the address of the source for an asset address
    /// @param asset The address of the asset
    /// @return address The address of the source
    function getSourceOfAsset(address asset) external view returns (address);

    /// @notice Set the source of an asset
    /// @param _asset The address of the asset
    /// @param _feedAddress The address of the feed
    /// @param _feedId The id of the feed
    /// @param _heartbeat The heartbeat of the feed
    /// @param _oracleType The type of the oracle
    /// @param isFallback True if the feed is a fallback
    function setAssetSource(
        address _asset,
        address _feedAddress,
        bytes32 _feedId,
        uint256 _heartbeat,
        OracleProviderType _oracleType,
        bool isFallback
    ) external;

    /**
     * @notice Updates multiple price feeds on Pyth oracle
     * @param priceUpdateData received from Pyth network and used to update the oracle
     */
    function updateUnderlyingPrices(bytes[] calldata priceUpdateData) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
	event MarketIdSet(string newMarketId);
	event LendingPoolUpdated(address indexed newAddress);
	event ConfigurationAdminUpdated(address indexed newAddress);
	event EmergencyAdminUpdated(address indexed newAddress);
	event LendingPoolConfiguratorUpdated(address indexed newAddress);
	event LendingPoolCollateralManagerUpdated(address indexed newAddress);
	event PriceOracleUpdated(address indexed newAddress);
	event LendingRateOracleUpdated(address indexed newAddress);
	event ProxyCreated(bytes32 id, address indexed newAddress);
	event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

	function getMarketId() external view returns (string memory);

	function setMarketId(string calldata marketId) external;

	function setAddress(bytes32 id, address newAddress) external;

	function setAddressAsProxy(bytes32 id, address impl) external;

	function getAddress(bytes32 id) external view returns (address);

	function getLendingPool() external view returns (address);

	function setLendingPoolImpl(address pool) external;

	function getLendingPoolConfigurator() external view returns (address);

	function setLendingPoolConfiguratorImpl(address configurator) external;

	function getLendingPoolCollateralManager() external view returns (address);

	function setLendingPoolCollateralManager(address manager) external;

	function getPoolAdmin() external view returns (address);

	function setPoolAdmin(address admin) external;

	function getEmergencyAdmin() external view returns (address);

	function setEmergencyAdmin(address admin) external;

	function getPriceOracle() external view returns (address);

	function setPriceOracle(address priceOracle) external;

	function getLendingRateOracle() external view returns (address);

	function setLendingRateOracle(address lendingRateOracle) external;

	function getLiquidationFeeTo() external view returns (address);

	function setLiquidationFeeTo(address liquidationFeeTo) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Errors } from "../Errors.sol";

struct SwapData {
    uint256 value; // amount of gas token that will be paid
    address addressToCall; // address to call and send bytes data to perform the aggregator swap
    address addressToApprove; // address to approve tokens that will be swapped
    bytes data; // bytes that will be passed to the aggregator to perform a swap
}

/// @title DexSwapStrategy library
/// @author Radiant
library DexSwapStrategy {
    using SafeERC20 for IERC20;

    /**
     * @notice Swap function
     * @param _data Data to perform the swap
     */
    function swap(address inputToken, uint256 amountIn, uint256 _minOutput, bytes calldata _data)
        internal
        returns (uint256)
    {
        SwapData memory swapData = bytesToSwapData(_data);

        IERC20(inputToken).forceApprove(swapData.addressToApprove, amountIn);

        uint256 returnAmount;
        (bool success, bytes memory responseData) = swapData.addressToCall.call{ value: swapData.value }(swapData.data);
        if (success) {
            returnAmount = abi.decode(responseData, (uint256));
        } else {
            revert Errors.DexSwapFailed();
        }

        if (returnAmount < _minOutput) {
            revert Errors.ReceivedLessThanMinOutput();
        }
        return returnAmount;
    }

    /**
     * @notice Convert bytes to SwapData
     * @param rawData Raw data
     * @return swapData SwapData
     */
    function bytesToSwapData(bytes memory rawData) internal pure returns (SwapData memory) {
        if (rawData.length < 96) revert Errors.InvalidInputData();

        SwapData memory swapData;
        uint256 value;
        address addressToCall;
        address addressToApprove;
        uint256 dataLength;

        assembly {
            value := mload(add(rawData, 32))
            addressToCall := mload(add(rawData, 64))
            addressToApprove := mload(add(rawData, 96))
            dataLength := mload(add(rawData, 128))
        }

        swapData.value = value;
        swapData.addressToCall = addressToCall;
        swapData.addressToApprove = addressToApprove;

        bytes memory testBytes = new bytes(32);
        for (uint256 i = 0; i < 32;) {
            testBytes[i] = rawData[i + 128];
            unchecked {
                i++;
            }
        }

        swapData.data = new bytes(rawData.length - 160);
        for (uint256 i = 160; i < rawData.length;) {
            swapData.data[i - 160] = rawData[i];
            unchecked {
                i++;
            }
        }

        return swapData;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../lending/libraries/types/DataTypes.sol";

interface ILendingPool {
	/**
	 * @dev Emitted on deposit()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address initiating the deposit
	 * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
	 * @param amount The amount deposited
	 * @param referral The referral code used
	 **/
	event Deposit(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on withdraw()
	 * @param reserve The address of the underlyng asset being withdrawn
	 * @param user The address initiating the withdrawal, owner of aTokens
	 * @param to Address that will receive the underlying
	 * @param amount The amount to be withdrawn
	 **/
	event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

	/**
	 * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
	 * @param reserve The address of the underlying asset being borrowed
	 * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
	 * initiator of the transaction on flashLoan()
	 * @param onBehalfOf The address that will be getting the debt
	 * @param amount The amount borrowed out
	 * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
	 * @param borrowRate The numeric rate at which the user has borrowed
	 * @param referral The referral code used
	 **/
	event Borrow(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 borrowRateMode,
		uint256 borrowRate,
		uint16 indexed referral
	);

	/**
	 * @dev Emitted on repay()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The beneficiary of the repayment, getting his debt reduced
	 * @param repayer The address of the user initiating the repay(), providing the funds
	 * @param amount The amount repaid
	 **/
	event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

	/**
	 * @dev Emitted on swapBorrowRateMode()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user swapping his rate mode
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	event Swap(address indexed reserve, address indexed user, uint256 rateMode);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on setUserUseReserveAsCollateral()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user enabling the usage as collateral
	 **/
	event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on rebalanceStableBorrowRate()
	 * @param reserve The address of the underlying asset of the reserve
	 * @param user The address of the user for which the rebalance has been executed
	 **/
	event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

	/**
	 * @dev Emitted on flashLoan()
	 * @param target The address of the flash loan receiver contract
	 * @param initiator The address initiating the flash loan
	 * @param asset The address of the asset being flash borrowed
	 * @param amount The amount flash borrowed
	 * @param premium The fee flash borrowed
	 * @param referralCode The referral code used
	 **/
	event FlashLoan(
		address indexed target,
		address indexed initiator,
		address indexed asset,
		uint256 amount,
		uint256 premium,
		uint16 referralCode
	);

	/**
	 * @dev Emitted when the pause is triggered.
	 */
	event Paused();

	/**
	 * @dev Emitted when the pause is lifted.
	 */
	event Unpaused();

	/**
	 * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
	 * LendingPoolCollateral manager using a DELEGATECALL
	 * This allows to have the events in the generated ABI for LendingPool.
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
	 * @param liquidator The address of the liquidator
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	event LiquidationCall(
		address indexed collateralAsset,
		address indexed debtAsset,
		address indexed user,
		uint256 debtToCover,
		uint256 liquidatedCollateralAmount,
		address liquidator,
		bool receiveAToken
	);

	/**
	 * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
	 * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
	 * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
	 * gets added to the LendingPool ABI
	 * @param reserve The address of the underlying asset of the reserve
	 * @param liquidityRate The new liquidity rate
	 * @param stableBorrowRate The new stable borrow rate
	 * @param variableBorrowRate The new variable borrow rate
	 * @param liquidityIndex The new liquidity index
	 * @param variableBorrowIndex The new variable borrow index
	 **/
	event ReserveDataUpdated(
		address indexed reserve,
		uint256 liquidityRate,
		uint256 stableBorrowRate,
		uint256 variableBorrowRate,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex
	);

	function initialize(ILendingPoolAddressesProvider provider) external;

	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	function depositWithAutoDLP(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(address asset, uint256 amount, address to) external returns (uint256);

	/**
	 * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
	 * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
	 * corresponding debt token (StableDebtToken or VariableDebtToken)
	 * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
	 *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
	 * @param asset The address of the underlying asset to borrow
	 * @param amount The amount to be borrowed
	 * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
	 * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
	 * if he has been given credit delegation allowance
	 **/
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	/**
	 * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
	 * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
	 * @param asset The address of the borrowed underlying asset previously borrowed
	 * @param amount The amount to repay
	 * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
	 * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
	 * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
	 * user calling the function if he wants to reduce/remove his own debt, or the address of any other
	 * other borrower whose debt should be removed
	 * @return The final amount repaid
	 **/
	function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

	/**
	 * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
	 * @param asset The address of the underlying asset borrowed
	 * @param rateMode The rate mode that the user wants to swap to
	 **/
	function swapBorrowRateMode(address asset, uint256 rateMode) external;

	/**
	 * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
	 * - Users can be rebalanced if the following conditions are satisfied:
	 *     1. Usage ratio is above 95%
	 *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
	 *        borrowed at a stable rate and depositors are not earning enough
	 * @param asset The address of the underlying asset borrowed
	 * @param user The address of the user to be rebalanced
	 **/
	function rebalanceStableBorrowRate(address asset, address user) external;

	/**
	 * @dev Allows depositors to enable/disable a specific deposited asset as collateral
	 * @param asset The address of the underlying asset deposited
	 * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
	 **/
	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

	/**
	 * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
	 * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
	 *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
	 * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
	 * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
	 * @param user The address of the borrower getting liquidated
	 * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
	 * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
	 * to receive the underlying collateral asset directly
	 **/
	function liquidationCall(
		address collateralAsset,
		address debtAsset,
		address user,
		uint256 debtToCover,
		bool receiveAToken
	) external;

	/**
	 * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
	 * as long as the amount taken plus a fee is returned.
	 * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
	 * For further details please visit https://developers.aave.com
	 * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
	 * @param assets The addresses of the assets being flash-borrowed
	 * @param amounts The amounts amounts being flash-borrowed
	 * @param modes Types of the debt to open if the flash loan is not returned:
	 *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
	 *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
	 * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
	 * @param params Variadic packed params to pass to the receiver as extra information
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function flashLoan(
		address receiverAddress,
		address[] calldata assets,
		uint256[] calldata amounts,
		uint256[] calldata modes,
		address onBehalfOf,
		bytes calldata params,
		uint16 referralCode
	) external;

	/**
	 * @dev Returns the user account data across all the reserves
	 * @param user The address of the user
	 * @return totalCollateralETH the total collateral in ETH of the user
	 * @return totalDebtETH the total debt in ETH of the user
	 * @return availableBorrowsETH the borrowing power left of the user
	 * @return currentLiquidationThreshold the liquidation threshold of the user
	 * @return ltv the loan to value of the user
	 * @return healthFactor the current health factor of the user
	 **/
	function getUserAccountData(
		address user
	)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	function initReserve(
		address reserve,
		address aTokenAddress,
		address stableDebtAddress,
		address variableDebtAddress,
		address interestRateStrategyAddress
	) external;

	function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

	function setConfiguration(address reserve, uint256 configuration) external;

	/**
	 * @dev Returns the configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The configuration of the reserve
	 **/
	function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

	/**
	 * @dev Returns the configuration of the user across all the reserves
	 * @param user The user address
	 * @return The configuration of the user
	 **/
	function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

	/**
	 * @dev Returns the normalized income normalized income of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve's normalized income
	 */
	function getReserveNormalizedIncome(address asset) external view returns (uint256);

	/**
	 * @dev Returns the normalized variable debt per unit of asset
	 * @param asset The address of the underlying asset of the reserve
	 * @return The reserve normalized variable debt
	 */
	function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

	function finalizeTransfer(
		address asset,
		address from,
		address to,
		uint256 amount,
		uint256 balanceFromAfter,
		uint256 balanceToBefore
	) external;

	function getReservesList() external view returns (address[] memory);

	function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

	function setPause(bool val) external;

	function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableAToken} from "./IInitializableAToken.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";
import {ILendingPool} from "./ILendingPool.sol";

interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
	/**
	 * @dev Emitted after the mint action
	 * @param from The address performing the mint
	 * @param value The amount being
	 * @param index The new liquidity index of the reserve
	 **/
	event Mint(address indexed from, uint256 value, uint256 index);

	/**
	 * @dev Mints `amount` aTokens to `user`
	 * @param user The address receiving the minted tokens
	 * @param amount The amount of tokens getting minted
	 * @param index The new liquidity index of the reserve
	 * @return `true` if the the previous balance of the user was 0
	 */
	function mint(address user, uint256 amount, uint256 index) external returns (bool);

	/**
	 * @dev Emitted after aTokens are burned
	 * @param from The owner of the aTokens, getting them burned
	 * @param target The address that will receive the underlying
	 * @param value The amount being burned
	 * @param index The new liquidity index of the reserve
	 **/
	event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

	/**
	 * @dev Emitted during the transfer action
	 * @param from The user whose tokens are being transferred
	 * @param to The recipient
	 * @param value The amount being transferred
	 * @param index The new liquidity index of the reserve
	 **/
	event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

	/**
	 * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
	 * @param user The owner of the aTokens, getting them burned
	 * @param receiverOfUnderlying The address that will receive the underlying
	 * @param amount The amount being burned
	 * @param index The new liquidity index of the reserve
	 **/
	function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;

	/**
	 * @dev Mints aTokens to the reserve treasury
	 * @param amount The amount of tokens getting minted
	 * @param index The new liquidity index of the reserve
	 */
	function mintToTreasury(uint256 amount, uint256 index) external;

	/**
	 * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
	 * @param from The address getting liquidated, current owner of the aTokens
	 * @param to The recipient
	 * @param value The amount of tokens getting transferred
	 **/
	function transferOnLiquidation(address from, address to, uint256 value) external;

	/**
	 * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
	 * assets in borrow(), withdraw() and flashLoan()
	 * @param user The recipient of the underlying
	 * @param amount The amount getting transferred
	 * @return The amount transferred
	 **/
	function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

	/**
	 * @dev Invoked to execute actions on the aToken side after a repayment.
	 * @param user The user executing the repayment
	 * @param amount The amount getting repaid
	 **/
	function handleRepayment(address user, uint256 amount) external;

	/**
	 * @dev Updates the treasury address
	 * @param treasury The new treasury address
	 */
	function setTreasuryAddress(address treasury) external;

	/**
	 * @dev Returns the address of the incentives controller contract
	 **/
	function getIncentivesController() external view returns (IAaveIncentivesController);

	/**
	 * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 **/
	function UNDERLYING_ASSET_ADDRESS() external view returns (address);

	/**
	 * @dev Returns the address of the lending pool where this aToken is used
	 **/
	function POOL() external view returns (ILendingPool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Errors {
    // Common errors
    error AddressZero();
    error AmountZero();
    error NotAContract();
    error NotAuthorized();

    // Oracle specific errors
    error NoFeedSet();
    error NoFallbackFeedSet();
    error NoPriceAvailable();
    error PoolDisabled();
    error RoundNotComplete();

    // Oracles General errors
    error InvalidOracleProviderType();
    error InvalidFeed();

    // Riz Registry errors
    error PoolRegisteredAlready();
    error NoAddressProvider();

    // Riz LockZap errors
    error CannotRizZap();
    error InvalidLendingPool();
    error InvalidRatio();
    error InvalidLockLength();
    error SlippageTooHigh();
    error SpecifiedSlippageExceedLimit();
    error InvalidZapETHSource();
    error ReceivedETHOnAlternativeAssetZap();
    error InsufficientETH();
    error EthTransferFailed();
    error SwapFailed(address asset, uint256 amount);
    error WrongRoute(address fromToken, address toToken);

    // Riz Leverager errors
    error ReceiveNotAllowed();
    error FallbackNotAllowed();

    /// @notice Disallow a loop count of 0
    error InvalidLoopCount();

    /// @notice Thrown when deployer sets the margin too high
    error MarginTooHigh();

    // Revenue Management errors
    error OutputTokenConfigLengthMismatch();
    error InputTokenConfigLengthMismatch();
    error IndexOutOfBounds();
    error OutputTokenBalanceOutOfRange();
    error TokenAlreadyAdded();
    error TokenNotPresent();
    error PercentageMismatch();
    error InvalidSwapStrategy();
    error DexSwapFailed();
    error ReceivedLessThanMinOutput();
    error InvalidInputData();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
	//common errors
	string public constant CALLER_NOT_POOL_ADMIN = "33"; // 'The caller must be the pool admin'
	string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small

	//contract specific errors
	string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
	string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve'
	string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
	string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // 'The current liquidity is not enough'
	string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // 'User cannot withdraw more than the available balance'
	string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // 'Transfer cannot be allowed.'
	string public constant VL_BORROWING_NOT_ENABLED = "7"; // 'Borrowing is not enabled'
	string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // 'Invalid interest rate mode selected'
	string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // 'The collateral balance is 0'
	string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "10"; // 'Health factor is lesser than the liquidation threshold'
	string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // 'There is not enough collateral to cover a new borrow'
	string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
	string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
	string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // 'The requested amount is greater than the max loan size in stable rate mode
	string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
	string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // 'To repay on behalf of an user an explicit amount to repay is needed'
	string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // 'User does not have a stable rate loan in progress on this reserve'
	string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // 'User does not have a variable rate loan in progress on this reserve'
	string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // 'The underlying balance needs to be greater than 0'
	string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // 'User deposit is already being used as collateral'
	string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // 'User does not have any stable rate loan for this reserve'
	string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // 'Interest rate rebalance conditions were not met'
	string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // 'Liquidation call failed'
	string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // 'There is not enough liquidity available to borrow'
	string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // 'The requested amount is too small for a FlashLoan.'
	string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // 'The actual balance of the protocol is inconsistent'
	string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // 'The caller of the function is not the lending pool configurator'
	string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
	string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // 'The caller of this function must be a lending pool'
	string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // 'User cannot give allowance to himself'
	string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // 'Transferred amount needs to be greater than zero'
	string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // 'Reserve has already been initialized'
	string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "38"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "39"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // 'The liquidity of the reserve needs to be 0'
	string public constant LPC_INVALID_CONFIGURATION = "75"; // 'Invalid risk parameters for the reserve'
	string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // 'The caller must be the emergency admin'
	string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // 'Provider is not registered'
	string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // 'Health factor is not below the threshold'
	string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // 'The collateral chosen cannot be liquidated'
	string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // 'User did not borrow the specified currency'
	string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn't enough liquidity available to liquidate"
	string public constant LPCM_NO_ERRORS = "46"; // 'No errors'
	string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
	string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
	string public constant MATH_ADDITION_OVERFLOW = "49";
	string public constant MATH_DIVISION_BY_ZERO = "50";
	string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
	string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
	string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
	string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
	string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
	string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
	string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
	string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
	string public constant LP_FAILED_COLLATERAL_SWAP = "60";
	string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
	string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
	string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
	string public constant LP_IS_PAUSED = "64"; // 'Pool is paused'
	string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
	string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
	string public constant RC_INVALID_LTV = "67";
	string public constant RC_INVALID_LIQ_THRESHOLD = "68";
	string public constant RC_INVALID_LIQ_BONUS = "69";
	string public constant RC_INVALID_DECIMALS = "70";
	string public constant RC_INVALID_RESERVE_FACTOR = "71";
	string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
	string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
	string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
	string public constant UL_INVALID_INDEX = "77";
	string public constant LP_NOT_CONTRACT = "78";
	string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
	string public constant SDT_BURN_EXCEEDS_BALANCE = "80";

	enum CollateralManagerErrors {
		NO_ERROR,
		NO_COLLATERAL_AVAILABLE,
		COLLATERAL_CANNOT_BE_LIQUIDATED,
		CURRRENCY_NOT_BORROWED,
		HEALTH_FACTOR_ABOVE_THRESHOLD,
		NOT_ENOUGH_LIQUIDITY,
		NO_ACTIVE_RESERVE,
		HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
		INVALID_EQUAL_ASSETS_TO_SWAP,
		FROZEN_RESERVE
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/

interface IPriceOracleGetter {
	/**
	 * @dev returns the asset price in ETH
	 * @param asset the address of the asset
	 * @return the ETH price of the asset
	 **/
	function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}

	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: Reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}

	struct UserConfigurationMap {
		uint256 data;
	}

	enum InterestRateMode {
		NONE,
		STABLE,
		VARIABLE
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

interface IScaledBalanceToken {
	/**
	 * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
	 * updated stored balance divided by the reserve's liquidity index at the moment of the update
	 * @param user The user whose balance is calculated
	 * @return The scaled balance of the user
	 **/
	function scaledBalanceOf(address user) external view returns (uint256);

	/**
	 * @dev Returns the scaled balance of the user and the scaled total supply.
	 * @param user The address of the user
	 * @return The scaled balance of the user
	 * @return The scaled balance and the scaled total supply
	 **/
	function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

	/**
	 * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
	 * @return The scaled total supply
	 **/
	function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import {ILendingPool} from "./ILendingPool.sol";
import {IAaveIncentivesController} from "./IAaveIncentivesController.sol";

/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 **/
interface IInitializableAToken {
	/**
	 * @dev Emitted when an aToken is initialized
	 * @param underlyingAsset The address of the underlying asset
	 * @param pool The address of the associated lending pool
	 * @param treasury The address of the treasury
	 * @param incentivesController The address of the incentives controller for this aToken
	 * @param aTokenDecimals the decimals of the underlying
	 * @param aTokenName the name of the aToken
	 * @param aTokenSymbol the symbol of the aToken
	 * @param params A set of encoded parameters for additional initialization
	 **/
	event Initialized(
		address indexed underlyingAsset,
		address indexed pool,
		address treasury,
		address incentivesController,
		uint8 aTokenDecimals,
		string aTokenName,
		string aTokenSymbol,
		bytes params
	);

	/**
	 * @dev Initializes the aToken
	 * @param pool The address of the lending pool where this aToken will be used
	 * @param treasury The address of the Aave treasury, receiving the fees on this aToken
	 * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
	 * @param incentivesController The smart contract managing potential incentives distribution
	 * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
	 * @param aTokenName The name of the aToken
	 * @param aTokenSymbol The symbol of the aToken
	 */
	function initialize(
		ILendingPool pool,
		address treasury,
		address underlyingAsset,
		IAaveIncentivesController incentivesController,
		uint8 aTokenDecimals,
		string calldata aTokenName,
		string calldata aTokenSymbol,
		bytes calldata params
	) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
	event RewardsAccrued(address indexed user, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

	event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);

	event ClaimerSet(address indexed user, address indexed claimer);

	/*
	 * @dev Returns the configuration of the distribution for a certain asset
	 * @param asset The address of the reference asset of the distribution
	 * @return The asset index, the emission per second and the last updated timestamp
	 **/
	function getAssetData(address asset) external view returns (uint256, uint256, uint256);

	/**
	 * @dev Whitelists an address to claim the rewards on behalf of another address
	 * @param user The address of the user
	 * @param claimer The address of the claimer
	 */
	function setClaimer(address user, address claimer) external;

	/**
	 * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
	 * @param user The address of the user
	 * @return The claimer address
	 */
	function getClaimer(address user) external view returns (address);

	/**
	 * @dev Configure assets for a certain rewards emission
	 * @param assets The assets to incentivize
	 * @param emissionsPerSecond The emission for each asset
	 */
	function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 **/
	function handleActionBefore(address user) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 * @param userBalance The balance of the user of the asset in the lending pool
	 * @param totalSupply The total supply of the asset in the lending pool
	 **/
	function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

	/**
	 * @dev Returns the total of rewards of an user, already accrued + not yet accrued
	 * @param user The address of the user
	 * @return The rewards
	 **/
	function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

	/**
	 * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
	 * @param amount Amount of rewards to claim
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

	/**
	 * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
	 * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
	 * @param amount Amount of rewards to claim
	 * @param user Address to check and claim rewards
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewardsOnBehalf(
		address[] calldata assets,
		uint256 amount,
		address user,
		address to
	) external returns (uint256);

	/**
	 * @dev returns the unclaimed rewards of the user
	 * @param user the address of the user
	 * @return the unclaimed user rewards
	 */
	function getUserUnclaimedRewards(address user) external view returns (uint256);

	/**
	 * @dev returns the unclaimed rewards of the user
	 * @param user the address of the user
	 * @param asset The asset to incentivize
	 * @return the user index for the asset
	 */
	function getUserAssetData(address user, address asset) external view returns (uint256);

	/**
	 * @dev for backward compatibility with previous implementation of the Incentives controller
	 */
	function REWARD_TOKEN() external view returns (address);

	/**
	 * @dev for backward compatibility with previous implementation of the Incentives controller
	 */
	function PRECISION() external view returns (uint8);

	/**
	 * @dev Gets the distribution end timestamp of the emissions
	 */
	function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}