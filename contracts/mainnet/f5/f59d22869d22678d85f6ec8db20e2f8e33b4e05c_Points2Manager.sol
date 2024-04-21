// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import {IPoints2Manager} from "./interfaces/IPoints2Manager.sol";
import {Ownable} from "points-periphery_@openzeppelin-contracts/access/Ownable.sol";
import {IChainlinkOracle} from "./external/IChainlinkOracle.sol";
import {IERC20} from "points-periphery_@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IPointsVaultExtension} from "points-periphery_points/interfaces/IPointsVaultExtension.sol";
import {IPoints} from "points-periphery_points/interfaces/IPoints.sol";
import {IButtonswapPair} from "points-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {IButtonswapFactory} from "points-periphery_buttonswap-core/interfaces/IButtonswapFactory/IButtonswapFactory.sol";
import {Math} from "./libraries/Math.sol";

contract Points2Manager is IPoints2Manager, Ownable {
    IPointsVaultExtension public immutable pointsProgram;
    IButtonswapFactory public immutable factory;
    IChainlinkOracle public immutable wethChainlinkOracle;

    address public immutable USDC;
    address public immutable USDT;
    address public immutable WETH;

    constructor(
        address pointsProgram_,
        address factory_,
        address wethChainlinkOracle_,
        address USDC_,
        address USDT_,
        address WETH_
    ) Ownable(msg.sender) {
        pointsProgram = IPointsVaultExtension(pointsProgram_);
        factory = IButtonswapFactory(factory_);
        wethChainlinkOracle = IChainlinkOracle(wethChainlinkOracle_);
        USDC = USDC_;
        USDT = USDT_;
        WETH = WETH_;
    }

    /**
     * @inheritdoc IPoints2Manager
     */
    function setPaused(bool paused_) external onlyOwner {
        pointsProgram.setPaused(paused_);
    }

    /**
     * @inheritdoc IPoints2Manager
     */
    function setAuthorizedBurner(address authorizedBurner_) external onlyOwner {
        pointsProgram.setAuthorizedBurner(authorizedBurner_);
    }

    /**
     * @inheritdoc IPoints2Manager
     */
    function setAddressWhitelist(address account, bool status) external onlyOwner {
        pointsProgram.setAddressWhitelist(account, status);
    }

    function validateToken(address token) public view returns (bool token0Valid, bool token1Valid) {
        IButtonswapPair pair = IButtonswapPair(token);
        // Check that this is a LP token
        if (token != factory.getPair(pair.token0(), pair.token1())) {
            revert InvalidToken(token);
        }
        // Validate that one of the underlying tokens is or USDC/USDT/WETH
        address token0 = pair.token0();
        address token1 = pair.token1();
        token0Valid = (token0 == USDC || token0 == USDT || token0 == WETH);
        token1Valid = (token1 == USDC || token1 == USDT || token1 == WETH);
        if (!token0Valid && !token1Valid) {
            revert InvalidToken(token);
        }
    }

    function convertTo18USD(address token, uint256 value) public view returns (uint256) {
        // If ETH, it uses the oracle to convert into USD with 18 decimals
        if (token == WETH) {
            return (value * uint256(wethChainlinkOracle.latestAnswer())) / 1e8;
        }
        // If USDT/USDC scale into USD with 18 decimals
        return value * 1e12;
    }

    function calculateRate(address pair, bool token0Valid) public view returns (uint96 rate) {
        uint256 movingAveragePrice0 = IButtonswapPair(pair).movingAveragePrice0();

        // Value per token assigns the value of 1 LP token in terms of the validated underlying token
        // Scaled up by 10**18
        uint256 valuePerToken;
        if (token0Valid) {
            valuePerToken = ((1e18) * (2 ** 57)) / Math.sqrt(movingAveragePrice0);
            valuePerToken = convertTo18USD(IButtonswapPair(pair).token0(), valuePerToken);
        } else {
            valuePerToken = (2e18 * Math.sqrt(movingAveragePrice0)) / (2 ** 56);
            valuePerToken = convertTo18USD(IButtonswapPair(pair).token1(), valuePerToken);
        }

        // Divide the value per token by 1 day to get the rate of 1 Point per second
        rate = uint96(valuePerToken / 86400);
    }

    /**
     * @inheritdoc IPoints2Manager
     */
    function setRates(address[] calldata tokens) external {
        uint96[] memory rates = new uint96[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            // Validate the token is an LP token with one of the underlying tokens being USDC/USDT/WETH
            (bool token0Valid,) = validateToken(tokens[i]);
            // Calculate the rate
            uint96 rate = calculateRate(tokens[i], token0Valid);
            rates[i] = rate;
        }

        pointsProgram.setRates(tokens, rates);
    }

    /**
     * @inheritdoc IPoints2Manager
     */
    function updateRates(uint16 startIndex, uint16 endIndex) external {
        address[] memory tokens = new address[](endIndex - startIndex);
        uint96[] memory rates = new uint96[](endIndex - startIndex);

        for (uint256 i = startIndex; i < endIndex; i++) {
            // Fetch token address
            address pair = IPoints(pointsProgram).tokenAt(i);
            // Validate the token is an LP token with one of the underlying tokens being USDC/USDT/WETH
            (bool token0Valid,) = validateToken(pair);
            // Calculate the rate
            uint96 rate = calculateRate(pair, token0Valid);
            // Add to the list
            tokens[i] = pair;
            rates[i] = rate;
        }

        pointsProgram.setRates(tokens, rates);
    }

    /**
     * @inheritdoc IPoints2Manager
     */
    function transferPointsOwnership(address newOwner) external onlyOwner {
        Ownable(address(pointsProgram)).transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import {IPoints2ManagerErrors} from "./IPoints2ManagerErrors.sol";

/**
 * @title IPoints2Manager
 * @notice Interface for managing the open Points Program
 */
interface IPoints2Manager is IPoints2ManagerErrors {
    /**
     * @notice Set the paused state of the contract. Can only be called by the owner
     * @param paused_ The state to set the contract to
     */
    function setPaused(bool paused_) external;

    /**
     * @notice Sets the authorized burner address. Can only be called by the owner
     * @param authorizedBurner_ The address to set the authorized burner to
     */
    function setAuthorizedBurner(address authorizedBurner_) external;

    /**
     * @notice Sets the whitelist status of an address. Can only be called by the owner
     * @param account The address to set the whitelist status for
     * @param status The status to set the whitelist to
     */
    function setAddressWhitelist(address account, bool status) external;

    /**
     * @notice Validates that all the supplied tokens meet the qualifications and sets their rate, can only be called by the owner
     * @param tokens List of tokens to set the rates for
     */
    function setRates(address[] calldata tokens) external;

    /**
     * @notice Iterates through a sublist of the supported tokens in the points-program and updates their rates. Can be called by anyone
     * @param startIndex start index of the supported tokens list
     * @param endIndex end index of the supported tokens list
     */
    function updateRates(uint16 startIndex, uint16 endIndex) external;

    /**
     * @notice points-ownership to a new owner
     * @param newOwner The address of the new owner
     */
    function transferPointsOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IChainlinkOracle {
    /**
     * @notice Reads the current answer from aggregator delegated to.
     * @dev overridden function to add the checkAccess() modifier
     *
     * @dev #[deprecated] Use latestRoundData instead. This does not error if no
     * answer has been reached, it will simply return 0. Either wait to point to
     * an already answered Aggregator or use the recommended latestRoundData
     * instead which includes better verification information.
     */
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import {IPoints} from "./IPoints.sol";
import {IRageQuit} from "../external/IRageQuit.sol";
import {IPointsVaultExtensionEvents} from "./IPointsVaultExtensionEvents.sol";
import {IPointsVaultExtensionErrors} from "./IPointsVaultExtensionErrors.sol";

/**
 * @title IPointsVaultExtension
 * @notice Interface for the vault-extension of the Points contract.
 * @dev Does not support fee-on-transfer or rebasing tokens (in unwrapped form).
 */
interface IPointsVaultExtension is IPoints, IRageQuit, IPointsVaultExtensionEvents, IPointsVaultExtensionErrors {
    /**
     * @notice Get the length of the registered vaultFactory whitelist
     * @return length The length of the vaultFactory whitelist
     */
    function getVaultFactorySetLength() external view returns (uint256 length);

    /**
     * @notice Get the address of the vaultFactory at the corresponding index on the whitelist
     * @param index The index of the vaultFactory
     * @return factory The address of the vaultFactory at the index on the whitelist
     */
    function getVaultFactoryAtIndex(uint256 index) external view returns (address factory);

    /**
     * @notice Validate whether or not the target vault is from a whitelisted factory
     * @param vault The address of the vault in question
     * @return validity Whether the target vault is from a whitelisted factory or not
     */
    function isValidVault(address vault) external view returns (bool validity);

    /**
     * @notice Register a new vaultFactory onto the whitelist. Only callable by owner.
     * @param factory The address of the factory to add.
     */
    function registerVaultFactory(address factory) external;

    /**
     * @notice Remove a vaultFactory from the whitelist. Only callable by owner.
     * @param factory The address of the factory to remove.
     */
    function removeVaultFactory(address factory) external;

    /**
     * @notice Stake tokens from vault into Points contract.
     * @notice Vault must be from whitelisted vaultFactory.
     * @param vault Address of the vault to stake from.
     * @param token The address of the token.
     * @param amount The amount of tokens to deposit.
     * @param permission Permission signature from vault owner.
     */
    function stakeToken(address vault, address token, uint128 amount, bytes calldata permission) external;

    /**
     * @notice Unstake tokens from Points contract and transfer earned points to the vault.
     * @param vault Address of the vault to unstake from.
     * @param token The address of the token.
     * @param amount The amount of tokens to deposit.
     * @param permission Permission signature from vault owner.
     */
    function unstakeToken(address vault, address token, uint128 amount, bytes calldata permission) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import {IERC20} from "points_@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IPointsEvents} from "./IPointsEvents.sol";
import {IPointsErrors} from "./IPointsErrors.sol";

/**
 * @title IPoints
 * @notice Interface for the Points contract.
 * @dev Does not support fee-on-transfer or rebasing tokens (in unwrapped form).
 */
interface IPoints is IERC20, IPointsEvents, IPointsErrors {
    /**
     * @notice Returns true if transfers are paused.
     * @return paused_ True if transfers are paused. False otherwise.
     */
    function paused() external view returns (bool paused_);

    /**
     * @notice Sets the paused status of the transfers.
     * @param paused_ The new paused status.
     */
    function setPaused(bool paused_) external;

    /**
     * @notice Returns the address of the authorized burner.
     * @return authorizedBurner The address of the authorized burner.
     */
    function authorizedBurner() external view returns (address authorizedBurner);

    /**
     * @notice Sets the address of the authorized burner.
     * @param authorizedBurner_ The new address of the authorized burner.
     */
    function setAuthorizedBurner(address authorizedBurner_) external;

    /**
     * @notice Burns the specified amount of tokens from the caller. Only callable by the authorized burner.
     * @param account The address to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice Returns true if the account is whitelisted (able to transfer tokens without restrictions).
     * @param account The address to check.
     * @return whitelisted True if the account is whitelisted. False otherwise.
     */
    function isWhitelisted(address account) external view returns (bool whitelisted);

    /**
     * @notice Updates the whitelist status of the account.
     * @param account The address to update.
     * @param status The new whitelist status.
     */
    function setAddressWhitelist(address account, bool status) external;

    /**
     * @notice Returns the token at the given index in the token list
     * @dev Tokens that have rates set to 0 are still included in the list.
     * @param index The index of the token in the list.
     * @return token The token
     */
    function tokenAt(uint256 index) external view returns (address token);

    /**
     * @notice Returns the number of tokens in the token list.
     * @dev Tokens that have rates set to 0 are still included in the list.
     * @return count The number of tokens in the list.
     */
    function tokenCount() external view returns (uint256 count);

    /**
     * @notice Sets the rates of the tokens. New tokens will be added if they do not already exist.
     * @dev Token addresses and rates are matched by corresponding index in their respective arrays
     * @dev Passing in the same token address multiple times results in only the final value being used.
     * @param tokens The addresses of the tokens.
     * @param rates The rates of the tokens.
     */
    function setRates(address[] calldata tokens, uint96[] calldata rates) external;

    /**
     * @notice Returns the rate of the token and the timestamp of the last update.
     * @param token The address of the token.
     * @return rate The rate of the token.
     * @return timestamp The timestamp of the last rate update or transfer of the token.
     * @return cumulativeRate The cumulative rate snapshot at the timestamp.
     */
    function getRateInfo(address token) external view returns (uint96 rate, uint32 timestamp, uint128 cumulativeRate);

    /**
     * @notice Returns the multiplier thresholds and scalars for the token.
     * @param token The address of the token.
     * @return thresholds The absolute thresholds for the multipliers.
     * @return scalars The absolute scalars for the multipliers.
     */
    function getMultipliers(address token)
        external
        view
        returns (uint128[] memory thresholds, uint128[] memory scalars);

    /**
     * @notice Sets the multiplier thresholds and scalars for the token.
     * @dev To generate the stored absolute thresholds, each iterative threshold is added to the previous one, starting from 0
     * @dev To generate the stored absolute scalars, each iterative scalar is added by the previous one, starting from RATE_DENOMINATOR
     * @param token The address of the token.
     * @param iterativeThresholds The iterative thresholds for the multipliers. Base threshold is 0
     * @param iterativeScalars The iterative scalars for the multipliers. Base multiplier is RATE_DENOMINATOR.
     */
    function setMultipliers(address token, uint128[] calldata iterativeThresholds, uint128[] calldata iterativeScalars)
        external;

    /**
     * @notice Returns the pending balance of the account (points that have yet to be converted)
     * @param account The address of the account.
     * @return pendingBalance The pending balance of the account.
     */
    function pendingBalanceOf(address account) external view returns (uint256 pendingBalance);

    /**
     * @notice Returns the staked amount for a given account and token
     * @param account The address of the account.
     * @param token The address of the token.
     * @return amount The staked amount for the account and token.
     */
    function getTokenStake(address account, address token) external view returns (uint128 amount);

    /**
     * @notice Returns the current multiplier scalar for a given account and token
     * @param account The address of the account.
     * @param token The address of the token.
     * @return rateScalar The current multiplier scalar for the account and token.
     */
    function getTokenMultiplier(address account, address token) external view returns (uint256 rateScalar);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapPairErrors} from "./IButtonswapPairErrors.sol";
import {IButtonswapPairEvents} from "./IButtonswapPairEvents.sol";
import {IButtonswapERC20} from "../IButtonswapERC20/IButtonswapERC20.sol";

interface IButtonswapPair is IButtonswapPairErrors, IButtonswapPairEvents, IButtonswapERC20 {
    /**
     * @notice The smallest value that {IButtonswapERC20-totalSupply} can be.
     * @dev After the first mint the total liquidity (represented by the liquidity token total supply) can never drop below this value.
     *
     * This is to protect against an attack where the attacker mints a very small amount of liquidity, and then donates pool tokens to skew the ratio.
     * This results in future minters receiving no liquidity tokens when they deposit.
     * By enforcing a minimum liquidity value this attack becomes prohibitively expensive to execute.
     * @return MINIMUM_LIQUIDITY The MINIMUM_LIQUIDITY value
     */
    function MINIMUM_LIQUIDITY() external pure returns (uint256 MINIMUM_LIQUIDITY);

    /**
     * @notice The duration for which the moving average is calculated for.
     * @return _movingAverageWindow The value of movingAverageWindow
     */
    function movingAverageWindow() external view returns (uint32 _movingAverageWindow);

    /**
     * @notice Updates the movingAverageWindow parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#movingaveragewindow) for more detail.
     * @param newMovingAverageWindow The new value for movingAverageWindow
     */
    function setMovingAverageWindow(uint32 newMovingAverageWindow) external;

    /**
     * @notice Numerator (over 10_000) of the threshold when price volatility triggers maximum single-sided timelock duration.
     * @return _maxVolatilityBps The value of maxVolatilityBps
     */
    function maxVolatilityBps() external view returns (uint16 _maxVolatilityBps);

    /**
     * @notice Updates the maxVolatilityBps parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxvolatilitybps) for more detail.
     * @param newMaxVolatilityBps The new value for maxVolatilityBps
     */
    function setMaxVolatilityBps(uint16 newMaxVolatilityBps) external;

    /**
     * @notice How long the minimum singled-sided timelock lasts for.
     * @return _minTimelockDuration The value of minTimelockDuration
     */
    function minTimelockDuration() external view returns (uint32 _minTimelockDuration);

    /**
     * @notice Updates the minTimelockDuration parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#mintimelockduration) for more detail.
     * @param newMinTimelockDuration The new value for minTimelockDuration
     */
    function setMinTimelockDuration(uint32 newMinTimelockDuration) external;

    /**
     * @notice How long the maximum singled-sided timelock lasts for.
     * @return _maxTimelockDuration The value of maxTimelockDuration
     */
    function maxTimelockDuration() external view returns (uint32 _maxTimelockDuration);

    /**
     * @notice Updates the maxTimelockDuration parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxtimelockduration) for more detail.
     * @param newMaxTimelockDuration The new value for maxTimelockDuration
     */
    function setMaxTimelockDuration(uint32 newMaxTimelockDuration) external;

    /**
     * @notice Numerator (over 10_000) of the fraction of the pool balance that acts as the maximum limit on how much of the reservoir
     * can be swapped in a given timeframe.
     * @return _maxSwappableReservoirLimitBps The value of maxSwappableReservoirLimitBps
     */
    function maxSwappableReservoirLimitBps() external view returns (uint16 _maxSwappableReservoirLimitBps);

    /**
     * @notice Updates the maxSwappableReservoirLimitBps parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxswappablereservoirlimitbps) for more detail.
     * @param newMaxSwappableReservoirLimitBps The new value for maxSwappableReservoirLimitBps
     */
    function setMaxSwappableReservoirLimitBps(uint16 newMaxSwappableReservoirLimitBps) external;

    /**
     * @notice How much time it takes for the swappable reservoir value to grow from nothing to its maximum value.
     * @return _swappableReservoirGrowthWindow The value of swappableReservoirGrowthWindow
     */
    function swappableReservoirGrowthWindow() external view returns (uint32 _swappableReservoirGrowthWindow);

    /**
     * @notice Updates the swappableReservoirGrowthWindow parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#swappablereservoirgrowthwindow) for more detail.
     * @param newSwappableReservoirGrowthWindow The new value for swappableReservoirGrowthWindow
     */
    function setSwappableReservoirGrowthWindow(uint32 newSwappableReservoirGrowthWindow) external;

    /**
     * @notice The address of the {ButtonswapFactory} instance used to create this Pair.
     * @dev Set to `msg.sender` in the Pair constructor.
     * @return factory The factory address
     */
    function factory() external view returns (address factory);

    /**
     * @notice The address of the first sorted token.
     * @return token0 The token address
     */
    function token0() external view returns (address token0);

    /**
     * @notice The address of the second sorted token.
     * @return token1 The token address
     */
    function token1() external view returns (address token1);

    /**
     * @notice The time-weighted average price of the Pair.
     * The price is of `token0` in terms of `token1`.
     * @dev The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * Consequently this value must be divided by `2^112` to get the actual price.
     *
     * Because of the time weighting, `price0CumulativeLast` must also be divided by the total Pair lifetime to get the average price over that time period.
     * @return price0CumulativeLast The current cumulative `token0` price
     */
    function price0CumulativeLast() external view returns (uint256 price0CumulativeLast);

    /**
     * @notice The time-weighted average price of the Pair.
     * The price is of `token1` in terms of `token0`.
     * @dev The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * Consequently this value must be divided by `2^112` to get the actual price.
     *
     * Because of the time weighting, `price1CumulativeLast` must also be divided by the total Pair lifetime to get the average price over that time period.
     * @return price1CumulativeLast The current cumulative `token1` price
     */
    function price1CumulativeLast() external view returns (uint256 price1CumulativeLast);

    /**
     * @notice The timestamp for when the single-sided timelock concludes.
     * The timelock is initiated based on price volatility of swaps over the last `movingAverageWindow`, and can be
     *   extended by new swaps if they are sufficiently volatile.
     * The timelock protects against attempts to manipulate the price that is used to valuate the reservoir tokens during
     *   single-sided operations.
     * It also guards against general legitimate volatility, as it is preferable to defer single-sided operations until
     *   it is clearer what the market considers the price to be.
     * @return singleSidedTimelockDeadline The current deadline timestamp
     */
    function singleSidedTimelockDeadline() external view returns (uint120 singleSidedTimelockDeadline);

    /**
     * @notice The timestamp by which the amount of reservoir tokens that can be exchanged during a single-sided operation
     *   reaches its maximum value.
     * This maximum value is not necessarily the entirety of the reservoir, instead being calculated as a fraction of the
     *   corresponding token's active liquidity.
     * @return swappableReservoirLimitReachesMaxDeadline The current deadline timestamp
     */
    function swappableReservoirLimitReachesMaxDeadline()
        external
        view
        returns (uint120 swappableReservoirLimitReachesMaxDeadline);

    /**
     * @notice Returns the current limit on the number of reservoir tokens that can be exchanged during a single-sided mint/burn operation.
     * @return swappableReservoirLimit The amount of reservoir token that can be exchanged
     */
    function getSwappableReservoirLimit() external view returns (uint256 swappableReservoirLimit);

    /**
     * @notice Whether the Pair is currently paused
     * @return _isPaused The paused state
     */
    function getIsPaused() external view returns (bool _isPaused);

    /**
     * @notice Updates the pause state.
     * This can only be called by the Factory address.
     * @param isPausedNew The new value for isPaused
     */
    function setIsPaused(bool isPausedNew) external;

    /**
     * @notice Get the current liquidity values.
     * @return _pool0 The active `token0` liquidity
     * @return _pool1 The active `token1` liquidity
     * @return _reservoir0 The inactive `token0` liquidity
     * @return _reservoir1 The inactive `token1` liquidity
     * @return _blockTimestampLast The timestamp of when the price was last updated
     */
    function getLiquidityBalances()
        external
        view
        returns (uint112 _pool0, uint112 _pool1, uint112 _reservoir0, uint112 _reservoir1, uint32 _blockTimestampLast);

    /**
     * @notice The current `movingAveragePrice0` value, based on the current block timestamp.
     * @dev This is the `token0` price, time weighted to prevent manipulation.
     * Refer to [reservoir-valuation.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/reservoir-valuation.md#price-stability) for more detail.
     *
     * The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * It is used to valuate the reservoir tokens that are exchanged during single-sided operations.
     * @return _movingAveragePrice0 The current `movingAveragePrice0` value
     */
    function movingAveragePrice0() external view returns (uint256 _movingAveragePrice0);

    /**
     * @notice Mints new liquidity tokens to `to` based on `amountIn0` of `token0` and `amountIn1  of`token1` deposited.
     * Expects both tokens to be deposited in a ratio that matches the current Pair price.
     * @dev The token deposits are deduced to be the delta between token balance before and after the transfers in order to account for unusual tokens.
     * Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#dual-sided-mint) for more detail.
     * @param amountIn0 The amount of `token0` that should be transferred in from the user
     * @param amountIn1 The amount of `token1` that should be transferred in from the user
     * @param to The account that receives the newly minted liquidity tokens
     * @return liquidityOut THe amount of liquidity tokens minted
     */
    function mint(uint256 amountIn0, uint256 amountIn1, address to) external returns (uint256 liquidityOut);

    /**
     * @notice Mints new liquidity tokens to `to` based on how much `token0` or `token1` has been deposited.
     * The token transferred is the one that the Pair does not have a non-zero inactive liquidity balance for.
     * Expects only one token to be deposited, so that it can be paired with the other token's inactive liquidity.
     * @dev The token deposits are deduced to be the delta between token balance before and after the transfers in order to account for unusual tokens.
     * Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#single-sided-mint) for more detail.
     * @param amountIn The amount of tokens that should be transferred in from the user
     * @param to The account that receives the newly minted liquidity tokens
     * @return liquidityOut THe amount of liquidity tokens minted
     */
    function mintWithReservoir(uint256 amountIn, address to) external returns (uint256 liquidityOut);

    /**
     * @notice Burns `liquidityIn` liquidity tokens to redeem to `to` the corresponding `amountOut0` of `token0` and `amountOut1` of `token1`.
     * @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#dual-sided-burn) for more detail.
     * @param liquidityIn The amount of liquidity tokens to burn
     * @param to The account that receives the redeemed tokens
     * @return amountOut0 The amount of `token0` that the liquidity tokens are redeemed for
     * @return amountOut1 The amount of `token1` that the liquidity tokens are redeemed for
     */
    function burn(uint256 liquidityIn, address to) external returns (uint256 amountOut0, uint256 amountOut1);

    /**
     * @notice Burns `liquidityIn` liquidity tokens to redeem to `to` the corresponding `amountOut0` of `token0` and `amountOut1` of `token1`.
     * Only returns tokens from the non-zero inactive liquidity balance, meaning one of `amountOut0` and `amountOut1` will be zero.
     * @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#single-sided-burn) for more detail.
     * @param liquidityIn The amount of liquidity tokens to burn
     * @param to The account that receives the redeemed tokens
     * @return amountOut0 The amount of `token0` that the liquidity tokens are redeemed for
     * @return amountOut1 The amount of `token1` that the liquidity tokens are redeemed for
     */
    function burnFromReservoir(uint256 liquidityIn, address to)
        external
        returns (uint256 amountOut0, uint256 amountOut1);

    /**
     * @notice Swaps one token for the other, taking `amountIn0` of `token0` and `amountIn1` of `token1` from the sender and sending `amountOut0` of `token0` and `amountOut1` of `token1` to `to`.
     * The price of the swap is determined by maintaining the "K Invariant".
     * A 0.3% fee is collected to distribute between liquidity providers and the protocol.
     * @dev The token deposits are deduced to be the delta between the current Pair contract token balances and the last stored balances.
     * Optional calldata can be passed to `data`, which will be used to confirm the output token transfer with `to` if `to` is a contract that implements the {IButtonswapCallee} interface.
     * Refer to [swap-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/swap-math.md) for more detail.
     * @param amountIn0 The amount of `token0` that the sender sends
     * @param amountIn1 The amount of `token1` that the sender sends
     * @param amountOut0 The amount of `token0` that the recipient receives
     * @param amountOut1 The amount of `token1` that the recipient receives
     * @param to The account that receives the swap output
     */
    function swap(uint256 amountIn0, uint256 amountIn1, uint256 amountOut0, uint256 amountOut1, address to) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapFactoryErrors} from "./IButtonswapFactoryErrors.sol";
import {IButtonswapFactoryEvents} from "./IButtonswapFactoryEvents.sol";

interface IButtonswapFactory is IButtonswapFactoryErrors, IButtonswapFactoryEvents {
    /**
     * @notice Returns the current address for `feeTo`.
     * The owner of this address receives the protocol fee as it is collected over time.
     * @return _feeTo The `feeTo` address
     */
    function feeTo() external view returns (address _feeTo);

    /**
     * @notice Returns the current address for `feeToSetter`.
     * The owner of this address has the power to update both `feeToSetter` and `feeTo`.
     * @return _feeToSetter The `feeToSetter` address
     */
    function feeToSetter() external view returns (address _feeToSetter);

    /**
     * @notice The name of the ERC20 liquidity token.
     * @return _tokenName The `tokenName`
     */
    function tokenName() external view returns (string memory _tokenName);

    /**
     * @notice The symbol of the ERC20 liquidity token.
     * @return _tokenSymbol The `tokenSymbol`
     */
    function tokenSymbol() external view returns (string memory _tokenSymbol);

    /**
     * @notice Returns the current state of restricted creation.
     * If true, then no new pairs, only feeToSetter can create new pairs
     * @return _isCreationRestricted The `isCreationRestricted` state
     */
    function isCreationRestricted() external view returns (bool _isCreationRestricted);

    /**
     * @notice Returns the current address for `isCreationRestrictedSetter`.
     * The owner of this address has the power to update both `isCreationRestrictedSetter` and `isCreationRestricted`.
     * @return _isCreationRestrictedSetter The `isCreationRestrictedSetter` address
     */
    function isCreationRestrictedSetter() external view returns (address _isCreationRestrictedSetter);

    /**
     * @notice Get the (unique) Pair address created for the given combination of `tokenA` and `tokenB`.
     * If the Pair does not exist then zero address is returned.
     * @param tokenA The first unsorted token
     * @param tokenB The second unsorted token
     * @return pair The address of the Pair instance
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Get the Pair address at the given `index`, ordered chronologically.
     * @param index The index to query
     * @return pair The address of the Pair created at the given `index`
     */
    function allPairs(uint256 index) external view returns (address pair);

    /**
     * @notice Get the current total number of Pairs created
     * @return count The total number of Pairs created
     */
    function allPairsLength() external view returns (uint256 count);

    /**
     * @notice Creates a new {ButtonswapPair} instance for the given unsorted tokens `tokenA` and `tokenB`.
     * @dev The tokens are sorted later, but can be provided to this method in either order.
     * @param tokenA The first unsorted token address
     * @param tokenB The second unsorted token address
     * @return pair The address of the new {ButtonswapPair} instance
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Updates the address that receives the protocol fee.
     * This can only be called by the `feeToSetter` address.
     * @param _feeTo The new address
     */
    function setFeeTo(address _feeTo) external;

    /**
     * @notice Updates the address that has the power to set the `feeToSetter` and `feeTo` addresses.
     * This can only be called by the `feeToSetter` address.
     * @param _feeToSetter The new address
     */
    function setFeeToSetter(address _feeToSetter) external;

    /**
     * @notice Updates the state of restricted creation.
     * This can only be called by the `feeToSetter` address.
     * @param _isCreationRestricted The new state
     */
    function setIsCreationRestricted(bool _isCreationRestricted) external;

    /**
     * @notice Updates the address that has the power to set the `isCreationRestrictedSetter` and `isCreationRestricted`.
     * This can only be called by the `isCreationRestrictedSetter` address.
     * @param _isCreationRestrictedSetter The new address
     */
    function setIsCreationRestrictedSetter(address _isCreationRestrictedSetter) external;

    /**
     * @notice Returns the current address for `isPausedSetter`.
     * The owner of this address has the power to update both `isPausedSetter` and call `setIsPaused`.
     * @return _isPausedSetter The `isPausedSetter` address
     */
    function isPausedSetter() external view returns (address _isPausedSetter);

    /**
     * @notice Updates the address that has the power to set the `isPausedSetter` and call `setIsPaused`.
     * This can only be called by the `isPausedSetter` address.
     * @param _isPausedSetter The new address
     */
    function setIsPausedSetter(address _isPausedSetter) external;

    /**
     * @notice Updates the pause state of given Pairs.
     * This can only be called by the `feeToSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param isPausedNew The new pause state
     */
    function setIsPaused(address[] calldata pairs, bool isPausedNew) external;

    /**
     * @notice Returns the current address for `paramSetter`.
     * The owner of this address has the power to update `paramSetter`, default parameters, and current parameters on existing pairs
     * @return _paramSetter The `paramSetter` address
     */
    function paramSetter() external view returns (address _paramSetter);

    /**
     * @notice Updates the address that has the power to set the `paramSetter` and update the default params.
     * This can only be called by the `paramSetter` address.
     * @param _paramSetter The new address
     */
    function setParamSetter(address _paramSetter) external;

    /**
     * @notice Returns the default value of `movingAverageWindow` used for new pairs.
     * @return _defaultMovingAverageWindow The `defaultMovingAverageWindow` value
     */
    function defaultMovingAverageWindow() external view returns (uint32 _defaultMovingAverageWindow);

    /**
     * @notice Returns the default value of `maxVolatilityBps` used for new pairs.
     * @return _defaultMaxVolatilityBps The `defaultMaxVolatilityBps` value
     */
    function defaultMaxVolatilityBps() external view returns (uint16 _defaultMaxVolatilityBps);

    /**
     * @notice Returns the default value of `minTimelockDuration` used for new pairs.
     * @return _defaultMinTimelockDuration The `defaultMinTimelockDuration` value
     */
    function defaultMinTimelockDuration() external view returns (uint32 _defaultMinTimelockDuration);

    /**
     * @notice Returns the default value of `maxTimelockDuration` used for new pairs.
     * @return _defaultMaxTimelockDuration The `defaultMaxTimelockDuration` value
     */
    function defaultMaxTimelockDuration() external view returns (uint32 _defaultMaxTimelockDuration);

    /**
     * @notice Returns the default value of `maxSwappableReservoirLimitBps` used for new pairs.
     * @return _defaultMaxSwappableReservoirLimitBps The `defaultMaxSwappableReservoirLimitBps` value
     */
    function defaultMaxSwappableReservoirLimitBps()
        external
        view
        returns (uint16 _defaultMaxSwappableReservoirLimitBps);

    /**
     * @notice Returns the default value of `swappableReservoirGrowthWindow` used for new pairs.
     * @return _defaultSwappableReservoirGrowthWindow The `defaultSwappableReservoirGrowthWindow` value
     */
    function defaultSwappableReservoirGrowthWindow()
        external
        view
        returns (uint32 _defaultSwappableReservoirGrowthWindow);

    /**
     * @notice Updates the default parameters used for new pairs.
     * This can only be called by the `paramSetter` address.
     * @param newDefaultMovingAverageWindow The new defaultMovingAverageWindow
     * @param newDefaultMaxVolatilityBps The new defaultMaxVolatilityBps
     * @param newDefaultMinTimelockDuration The new defaultMinTimelockDuration
     * @param newDefaultMaxTimelockDuration The new defaultMaxTimelockDuration
     * @param newDefaultMaxSwappableReservoirLimitBps The new defaultMaxSwappableReservoirLimitBps
     * @param newDefaultSwappableReservoirGrowthWindow The new defaultSwappableReservoirGrowthWindow
     */
    function setDefaultParameters(
        uint32 newDefaultMovingAverageWindow,
        uint16 newDefaultMaxVolatilityBps,
        uint32 newDefaultMinTimelockDuration,
        uint32 newDefaultMaxTimelockDuration,
        uint16 newDefaultMaxSwappableReservoirLimitBps,
        uint32 newDefaultSwappableReservoirGrowthWindow
    ) external;

    /**
     * @notice Updates the `movingAverageWindow` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMovingAverageWindow The new `movingAverageWindow` value
     */
    function setMovingAverageWindow(address[] calldata pairs, uint32 newMovingAverageWindow) external;

    /**
     * @notice Updates the `maxVolatilityBps` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxVolatilityBps The new `maxVolatilityBps` value
     */
    function setMaxVolatilityBps(address[] calldata pairs, uint16 newMaxVolatilityBps) external;

    /**
     * @notice Updates the `minTimelockDuration` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMinTimelockDuration The new `minTimelockDuration` value
     */
    function setMinTimelockDuration(address[] calldata pairs, uint32 newMinTimelockDuration) external;

    /**
     * @notice Updates the `maxTimelockDuration` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxTimelockDuration The new `maxTimelockDuration` value
     */
    function setMaxTimelockDuration(address[] calldata pairs, uint32 newMaxTimelockDuration) external;

    /**
     * @notice Updates the `maxSwappableReservoirLimitBps` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxSwappableReservoirLimitBps The new `maxSwappableReservoirLimitBps` value
     */
    function setMaxSwappableReservoirLimitBps(address[] calldata pairs, uint16 newMaxSwappableReservoirLimitBps)
        external;

    /**
     * @notice Updates the `swappableReservoirGrowthWindow` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newSwappableReservoirGrowthWindow The new `swappableReservoirGrowthWindow` value
     */
    function setSwappableReservoirGrowthWindow(address[] calldata pairs, uint32 newSwappableReservoirGrowthWindow)
        external;

    /**
     * @notice Returns the last token pair created and the parameters used.
     * @return token0 The first token address
     * @return token1 The second token address
     * @return movingAverageWindow The moving average window
     * @return maxVolatilityBps The max volatility bps
     * @return minTimelockDuration The minimum time lock duration
     * @return maxTimelockDuration The maximum time lock duration
     * @return maxSwappableReservoirLimitBps The max swappable reservoir limit bps
     * @return swappableReservoirGrowthWindow The swappable reservoir growth window
     */
    function lastCreatedTokensAndParameters()
        external
        returns (
            address token0,
            address token1,
            uint32 movingAverageWindow,
            uint16 maxVolatilityBps,
            uint32 minTimelockDuration,
            uint32 maxTimelockDuration,
            uint16 maxSwappableReservoirLimitBps,
            uint32 swappableReservoirGrowthWindow
        );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// a library for performing various math operations

library Math {
    // Borrowed implementation from solmate
    // https://github.com/transmissions11/solmate/blob/2001af43aedb46fdc2335d2a7714fb2dae7cfcd1/src/utils/FixedPointMathLib.sol#L164
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPoints2ManagerErrors
 * @notice Interface for the errors thrown by the Points2Manager contract.
 */
interface IPoints2ManagerErrors {
    error InvalidToken(address token);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @notice IRageQuit interface
 * @dev Source: https://github.com/ampleforth/token-geyser-v2/blob/c878fd6ba5856d818ff41c54bce59c9413bc93c9/contracts/Geyser.sol#L17-L19
 */
interface IRageQuit {
    /**
     * @notice Exit without claiming reward
     * @dev Should only be callable by the vault directly
     */
    function rageQuit() external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsVaultExtensionEvents
 * @notice Interface for the Events emitted by the PointsVaultExtension contract.
 */
interface IPointsVaultExtensionEvents {
    /**
     * @notice Emitted when tokens are locked in a vault
     * @param vault The address of the vault that tokens were locked in
     * @param token The address of the token that was locked in the vault
     * @param amount The amount of tokens that were locked in the vault
     */
    event TokenVaultLocked(address indexed vault, address indexed token, uint256 amount);
    /**
     * @notice Emitted when tokens are unlocked from a vault
     * @param vault The address of the vault that tokens were unlocked from
     * @param token The address of the token that was unlocked from the vault
     * @param amount The amount of tokens that were unlocked from the vault
     */
    event TokenVaultUnlocked(address indexed vault, address indexed token, uint256 amount);
    /**
     * @notice Emitted when a vaultFactory is registered on the whitelist
     * @param vaultFactory The address of the vaultFactory was registered
     */
    event VaultFactoryRegistered(address indexed vaultFactory);
    /**
     * @notice Emitted when a vaultFactory is removed from the whitelist
     * @param vaultFactory The address of the vaultFactory that was removed
     */
    event VaultFactoryRemoved(address indexed vaultFactory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsVaultExtensionErrors
 * @notice Interface for the Errors emitted by the PointsVaultExtension contract.
 */
interface IPointsVaultExtensionErrors {
    /**
     * @notice Thrown when attempting to register a vaultFactory that has already been registered
     * @param vaultFactory The address of the vaultFactory that was already registered
     */
    error VaultFactoryAlreadyRegistered(address vaultFactory);
    /**
     * @notice Thrown when attempting to remove a vaultFactory that has not been registered
     * @param vaultFactory The address of the vaultFactory that was not already registered
     */
    error VaultFactoryNotRegistered(address vaultFactory);
    /**
     * @notice Thrown when attempting to stake with a vault that is not from a registered vaultFactory;
     * @param vault The address of the vault that was not from a registered vaultFactory
     */
    error InvalidVault(address vault);
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsEvents
 * @notice Interface for the Events emitted by the Points contract.
 */
interface IPointsEvents {
    /**
     * @notice Emitted when the paused status of the transfers is updated.
     * @param paused The new paused status
     */
    event IsPaused(bool paused);
    /**
     * @notice Emitted when the authorized burner is updated.
     * @param authorizedBurner The new authorized burner
     */
    event AuthorizedBurnerUpdated(address authorizedBurner);
    /**
     * @notice Emitted when the whitelist status of an account is updated.
     * @param account The account whose whitelist status was updated
     * @param whitelisted The new whitelist status
     */
    event WhitelistUpdated(address indexed account, bool whitelisted);
    /**
     * @notice Emitted when the rate of a token is updated.
     * @param token The token whose rate is updated
     * @param rate The new rate
     * @param timestamp The timestamp of the update
     */
    event RateUpdated(address indexed token, uint96 rate, uint32 timestamp);
    /**
     * @notice Emitted when points are converted to pending points.
     * @param account The account whose points were converted
     * @param token The staked token that earned the points
     * @param amount The amount of points converted
     */
    event PendingPointsConverted(address indexed account, address indexed token, uint256 amount);
    /**
     * @notice Emitted when multipliers are updated
     * @param token The token whose multipliers were updated
     * @param thresholds The new thresholds
     * @param scalars The new scalars
     */
    event MultipliersUpdated(address indexed token, uint128[] thresholds, uint128[] scalars);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsErrors
 * @notice Interface for the errors thrown by the Points contract.
 */
interface IPointsErrors {
    /**
     * @notice Thrown when attempting to set rates while rates parameter and tokens parameter have different lengths.
     * @param tokensLength The length of the tokens array
     * @param ratesLength The length of the rates array
     */
    error TokenRatesLengthsMismatched(uint256 tokensLength, uint256 ratesLength);
    /**
     * @notice Thrown when attempting to transfer when paused and not whitelisted.
     */
    error TransfersPaused();

    /**
     * @notice Thrown when attempting to burn tokens without being the authorized burner.
     * @param account The account attempting to burn tokens
     */
    error UnauthorizedBurner(address account);

    /**
     * @notice Thrown when attempting to stake an unsupported token.
     * @param token The token that was not supported
     */
    error TokenNotSupported(address token);
    /**
     * @notice Thrown when attempting to unstake more of the token than has been staked.
     * @param tokenBalance The amount of tokens the user had deposited into the contract
     * @param amount The amount of tokens the user was attempting to withdraw
     */
    error InsufficientTokenBalance(uint256 tokenBalance, uint256 amount);
    /**
     * @notice Thrown when attempting to set multipliers with threshold and additionalRate arrays of different lengths.
     * @param thresholdsLength The length of the thresholds array
     * @param additionalRatesLength The length of the additionalRates array
     */
    error MultiplierLengthsMismatched(uint256 thresholdsLength, uint256 additionalRatesLength);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "../IButtonswapERC20/IButtonswapERC20Errors.sol";

interface IButtonswapPairErrors is IButtonswapERC20Errors {
    /**
     * @notice Re-entrancy guard prevented method call
     */
    error Locked();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();

    /**
     * @notice Integer maximums exceeded
     */
    error Overflow();

    /**
     * @notice Initial deposit not yet made
     */
    error Uninitialized();

    /**
     * @notice There was not enough liquidity in the reservoir
     */
    error InsufficientReservoir();

    /**
     * @notice Not enough liquidity was created during mint
     */
    error InsufficientLiquidityMinted();

    /**
     * @notice Not enough funds added to mint new liquidity
     */
    error InsufficientLiquidityAdded();

    /**
     * @notice More liquidity must be burned to be redeemed for non-zero amounts
     */
    error InsufficientLiquidityBurned();

    /**
     * @notice Swap was attempted with zero input
     */
    error InsufficientInputAmount();

    /**
     * @notice Swap was attempted with zero output
     */
    error InsufficientOutputAmount();

    /**
     * @notice Pool doesn't have the liquidity to service the swap
     */
    error InsufficientLiquidity();

    /**
     * @notice The specified "to" address is invalid
     */
    error InvalidRecipient();

    /**
     * @notice The product of pool balances must not change during a swap (save for accounting for fees)
     */
    error KInvariant();

    /**
     * @notice The new price ratio after a swap is invalid (one or more of the price terms are zero)
     */
    error InvalidFinalPrice();

    /**
     * @notice Single sided operations are not executable at this point in time
     */
    error SingleSidedTimelock();

    /**
     * @notice The attempted operation would have swapped reservoir tokens above the current limit
     */
    error SwappableReservoirExceeded();

    /**
     * @notice All operations on the pair other than dual-sided burning are currently paused
     */
    error Paused();
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapERC20Events} from "../IButtonswapERC20/IButtonswapERC20Events.sol";

interface IButtonswapPairEvents is IButtonswapERC20Events {
    /**
     * @notice Emitted when a {IButtonswapPair-mint} is performed.
     * Some `token0` and `token1` are deposited in exchange for liquidity tokens representing a claim on them.
     * @param from The account that supplied the tokens for the mint
     * @param amount0 The amount of `token0` that was deposited
     * @param amount1 The amount of `token1` that was deposited
     * @param amountOut The amount of liquidity tokens that were minted
     * @param to The account that received the tokens from the mint
     */
    event Mint(address indexed from, uint256 amount0, uint256 amount1, uint256 amountOut, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-burn} is performed.
     * Liquidity tokens are redeemed for underlying `token0` and `token1`.
     * @param from The account that supplied the tokens for the burn
     * @param amountIn The amount of liquidity tokens that were burned
     * @param amount0 The amount of `token0` that was received
     * @param amount1 The amount of `token1` that was received
     * @param to The account that received the tokens from the burn
     */
    event Burn(address indexed from, uint256 amountIn, uint256 amount0, uint256 amount1, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-swap} is performed.
     * @param from The account that supplied the tokens for the swap
     * @param amount0In The amount of `token0` that went into the swap
     * @param amount1In The amount of `token1` that went into the swap
     * @param amount0Out The amount of `token0` that came out of the swap
     * @param amount1Out The amount of `token1` that came out of the swap
     * @param to The account that received the tokens from the swap
     */
    event Swap(
        address indexed from,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /**
     * @notice Emitted when the movingAverageWindow parameter for the pair has been updated.
     * @param newMovingAverageWindow The new movingAverageWindow value
     */
    event MovingAverageWindowUpdated(uint32 newMovingAverageWindow);

    /**
     * @notice Emitted when the maxVolatilityBps parameter for the pair has been updated.
     * @param newMaxVolatilityBps The new maxVolatilityBps value
     */
    event MaxVolatilityBpsUpdated(uint16 newMaxVolatilityBps);

    /**
     * @notice Emitted when the minTimelockDuration parameter for the pair has been updated.
     * @param newMinTimelockDuration The new minTimelockDuration value
     */
    event MinTimelockDurationUpdated(uint32 newMinTimelockDuration);

    /**
     * @notice Emitted when the maxTimelockDuration parameter for the pair has been updated.
     * @param newMaxTimelockDuration The new maxTimelockDuration value
     */
    event MaxTimelockDurationUpdated(uint32 newMaxTimelockDuration);

    /**
     * @notice Emitted when the maxSwappableReservoirLimitBps parameter for the pair has been updated.
     * @param newMaxSwappableReservoirLimitBps The new maxSwappableReservoirLimitBps value
     */
    event MaxSwappableReservoirLimitBpsUpdated(uint16 newMaxSwappableReservoirLimitBps);

    /**
     * @notice Emitted when the swappableReservoirGrowthWindow parameter for the pair has been updated.
     * @param newSwappableReservoirGrowthWindow The new swappableReservoirGrowthWindow value
     */
    event SwappableReservoirGrowthWindowUpdated(uint32 newSwappableReservoirGrowthWindow);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "./IButtonswapERC20Errors.sol";
import {IButtonswapERC20Events} from "./IButtonswapERC20Events.sol";

interface IButtonswapERC20 is IButtonswapERC20Errors, IButtonswapERC20Events {
    /**
     * @notice Returns the name of the token.
     * @return _name The token name
     */
    function name() external view returns (string memory _name);

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the name.
     * @return _symbol The token symbol
     */
    function symbol() external view returns (string memory _symbol);

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * @dev This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the contract.
     * @return decimals The number of decimals
     */
    function decimals() external pure returns (uint8 decimals);

    /**
     * @notice Returns the amount of tokens in existence.
     * @return totalSupply The amount of tokens in existence
     */
    function totalSupply() external view returns (uint256 totalSupply);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param owner The account the balance is being checked for
     * @return balance The amount of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}.
     * This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @return allowance The amount of tokens owned by `owner` that the `spender` can transfer
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance);

    /**
     * @notice Sets `value` as the allowance of `spender` over the caller's tokens.
     * @dev IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     * @param spender The account that is granted permission to spend the tokens
     * @param value The amount of tokens that can be spent
     * @return success Whether the operation succeeded
     */
    function approve(address spender, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from the caller's account to `to`.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transfer(address to, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from `from` to `to` using the allowance mechanism.
     * `value` is then deducted from the caller's allowance.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param from The account that is sending the tokens
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return DOMAIN_SEPARATOR The `DOMAIN_SEPARATOR` value
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 DOMAIN_SEPARATOR);

    /**
     * @notice Returns the typehash used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return PERMIT_TYPEHASH The `PERMIT_TYPEHASH` value
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32 PERMIT_TYPEHASH);

    /**
     * @notice Returns the current nonce for `owner`.
     * This value must be included whenever a signature is generated for {permit}.
     * @dev Every successful call to {permit} increases `owner`'s nonce by one.
     * This prevents a signature from being used multiple times.
     * @param owner The account to get the nonce for
     * @return nonce The current nonce for the given `owner`
     */
    function nonces(address owner) external view returns (uint256 nonce);

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval.
     * @dev IMPORTANT: The same issues {approve} has related to transaction ordering also apply here.
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the [relevant EIP section](https://eips.ethereum.org/EIPS/eip-2612#specification).
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @param value The amount of `owner`'s tokens that `spender` can transfer
     * @param deadline The future time after which the permit is no longer valid
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapFactoryErrors {
    /**
     * @notice The given token addresses are the same
     */
    error TokenIdenticalAddress();

    /**
     * @notice The given token address is the zero address
     */
    error TokenZeroAddress();

    /**
     * @notice The given tokens already have a {ButtonswapPair} instance
     */
    error PairExists();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();

    /**
     * @notice There was an attempt to update a parameter to an invalid value
     */
    error InvalidParameter();
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapFactoryEvents {
    /**
     * @notice Emitted when a new Pair is created.
     * @param token0 The first sorted token
     * @param token1 The second sorted token
     * @param pair The address of the new {ButtonswapPair} contract
     * @param count The new total number of Pairs created
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 count);

    /**
     * @notice Emitted when the default parameters for a new pair have been updated.
     * @param paramSetter The address that changed the parameters
     * @param newDefaultMovingAverageWindow The new movingAverageWindow default value
     * @param newDefaultMaxVolatilityBps The new maxVolatilityBps default value
     * @param newDefaultMinTimelockDuration The new minTimelockDuration default value
     * @param newDefaultMaxTimelockDuration The new maxTimelockDuration default value
     * @param newDefaultMaxSwappableReservoirLimitBps The new maxSwappableReservoirLimitBps default value
     * @param newDefaultSwappableReservoirGrowthWindow The new swappableReservoirGrowthWindow default value
     */
    event DefaultParametersUpdated(
        address indexed paramSetter,
        uint32 newDefaultMovingAverageWindow,
        uint16 newDefaultMaxVolatilityBps,
        uint32 newDefaultMinTimelockDuration,
        uint32 newDefaultMaxTimelockDuration,
        uint16 newDefaultMaxSwappableReservoirLimitBps,
        uint32 newDefaultSwappableReservoirGrowthWindow
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapERC20Errors {
    /**
     * @notice Permit deadline was exceeded
     */
    error PermitExpired();

    /**
     * @notice Permit signature invalid
     */
    error PermitInvalidSignature();
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapERC20Events {
    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by a call to {IButtonswapERC20-approve}.
     * `value` is the new allowance.
     * @param owner The account that has granted approval
     * @param spender The account that has been given approval
     * @param value The amount the spender can transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     * @param from The account that sent the tokens
     * @param to The account that received the tokens
     * @param value The amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}