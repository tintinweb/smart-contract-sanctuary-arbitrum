// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGMXRewardRouterV2 {
	function stakeGmx(uint256 _amount) external;

	function unstakeGmx(uint256 _amount) external;

	function handleRewards(
		bool _shouldClaimGmx,
		bool _shouldStakeGmx,
		bool _shouldClaimEsGmx,
		bool _shouldStakeEsGmx,
		bool _shouldStakeMultiplierPoints,
		bool _shouldClaimWeth,
		bool _shouldConvertWethToEth
	) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import { IGMXRewardRouterV2 } from "./interface/IGMXRewardRouterV2.sol";
import { IGMXRewardTracker } from "./interface/IGMXRewardTracker.sol";
import { IVestaGMXStaking } from "./interface/IVestaGMXStaking.sol";
import { TransferHelper } from "./lib/TransferHelper.sol";
import { FullMath } from "./lib/FullMath.sol";

contract VestaGMXStaking is IVestaGMXStaking, OwnableUpgradeable {
	uint256 private constant PRECISION = 1e27;
	bool private reentrancy;

	address public vestaTreasury;
	address public gmxToken;

	IGMXRewardRouterV2 public gmxRewardRouterV2;
	IGMXRewardTracker public feeGmxTrackerRewards;
	address public stakedGmxTracker;

	uint256 public treasuryFee;
	uint256 public rewardShare;

	uint256 public lastBalance;
	uint256 public totalStaked;

	mapping(address => bool) internal operators;
	mapping(address => uint256) internal stakes;
	mapping(address => uint256) internal userShares;

	modifier onlyOperator() {
		if (!operators[msg.sender]) revert CallerIsNotAnOperator(msg.sender);
		_;
	}

	modifier onlyNonZero(uint256 _amount) {
		if (_amount == 0) revert ZeroAmountPassed();
		_;
	}

	modifier onlyActiveAddress(address _addr) {
		if (_addr == address(0)) revert InvalidAddress();
		_;
	}

	modifier onlyContract(address _address) {
		if (_address.code.length == 0) revert InvalidAddress();
		_;
	}

	modifier noReentrancy() {
		if (reentrancy) revert ReentrancyDetected();
		reentrancy = true;
		_;
		reentrancy = false;
	}

	function setUp(
		address _vestaTreasury,
		address _gmxToken,
		address _gmxRewardRouterV2,
		address _stakedGmxTracker,
		address _feeGmxTrackerRewards
	)
		external
		onlyActiveAddress(_vestaTreasury)
		onlyActiveAddress(_gmxToken)
		onlyActiveAddress(_gmxRewardRouterV2)
		onlyActiveAddress(_stakedGmxTracker)
		onlyActiveAddress(_feeGmxTrackerRewards)
		initializer
	{
		__Ownable_init();

		vestaTreasury = _vestaTreasury;
		gmxToken = _gmxToken;
		gmxRewardRouterV2 = IGMXRewardRouterV2(_gmxRewardRouterV2);
		stakedGmxTracker = _stakedGmxTracker;
		feeGmxTrackerRewards = IGMXRewardTracker(_feeGmxTrackerRewards);

		treasuryFee = 2_000; // 20% in BPS

		TransferHelper.safeApprove(gmxToken, stakedGmxTracker, type(uint256).max);
	}

	function stake(address _behalfOf, uint256 _amount)
		external
		override
		onlyOperator
		onlyActiveAddress(_behalfOf)
		onlyNonZero(_amount)
		noReentrancy
	{
		_harvest(_behalfOf);

		TransferHelper.safeTransferFrom(gmxToken, msg.sender, address(this), _amount);

		uint256 userStaked = stakes[_behalfOf] += _amount;

		_gmxStake(_amount);

		userShares[_behalfOf] = FullMath.mulDivRoundingUp(
			userStaked,
			rewardShare,
			PRECISION
		);
	}

	function _gmxStake(uint256 _amount) internal {
		totalStaked += _amount;
		gmxRewardRouterV2.stakeGmx(_amount);

		emit StakingUpdated(totalStaked);
	}

	function claim() external override noReentrancy {
		if (stakes[msg.sender] == 0) revert InsufficientStakeBalance();
		_unstake(msg.sender, 0);
	}

	function unstake(address _behalfOf, uint256 _amount)
		external
		override
		onlyOperator
		noReentrancy
	{
		_unstake(_behalfOf, _amount);
	}

	function _unstake(address _behalfOf, uint256 _amount) internal {
		if (totalStaked < _amount || stakes[_behalfOf] < _amount) {
			revert InsufficientStakeBalance();
		}
		_harvest(_behalfOf);
		uint256 userStaked = stakes[_behalfOf] -= _amount;

		if (_amount != 0) {
			_gmxUnstake(_amount);
			TransferHelper.safeTransfer(gmxToken, msg.sender, _amount);
		}

		userShares[_behalfOf] = FullMath.mulDivRoundingUp(
			userStaked,
			rewardShare,
			PRECISION
		);
	}

	function _gmxUnstake(uint256 _amount) internal {
		uint256 withdrawalAmount = totalStaked < _amount ? totalStaked : _amount;

		totalStaked -= withdrawalAmount;
		gmxRewardRouterV2.unstakeGmx(withdrawalAmount);

		emit StakingUpdated(totalStaked);
	}

	function _harvest(address _behalfOf) internal {
		gmxRewardRouterV2.handleRewards(true, true, true, true, true, true, true);

		if (totalStaked > 0) {
			rewardShare += FullMath.mulDiv(
				address(this).balance - lastBalance,
				PRECISION,
				totalStaked
			);
		}

		uint256 last = userShares[_behalfOf];
		uint256 curr = FullMath.mulDiv(stakes[_behalfOf], rewardShare, PRECISION);

		if (curr > last) {
			bool success;
			uint256 totalReward = curr - last;

			uint256 toTheTreasury = (((totalReward * PRECISION) * treasuryFee) / 10_000) /
				PRECISION;
			uint256 toTheUser = totalReward - toTheTreasury;

			(success, ) = _behalfOf.call{ value: toTheUser }("");
			if (!success) {
				revert ETHTransferFailed(_behalfOf, toTheUser);
			}

			(success, ) = vestaTreasury.call{ value: toTheTreasury }("");
			if (!success) {
				revert ETHTransferFailed(vestaTreasury, toTheTreasury);
			}
		}

		lastBalance = address(this).balance;
	}

	function setOperator(address _address, bool _enabled)
		external
		onlyContract(_address)
		onlyOwner
	{
		operators[_address] = _enabled;
	}

	function setTreasuryFee(uint256 _sharesBPS) external onlyOwner {
		if (_sharesBPS > 10_000) revert BPSHigherThanOneHundred();
		treasuryFee = _sharesBPS;
	}

	function setTreasury(address _newTreasury) external onlyOwner {
		vestaTreasury = _newTreasury;
	}

	function getVaultStake(address _vaultOwner)
		external
		view
		override
		returns (uint256)
	{
		return stakes[_vaultOwner];
	}

	function getVaultOwnerShare(address _vaultOwner)
		external
		view
		override
		returns (uint256)
	{
		return userShares[_vaultOwner];
	}

	function getVaultOwnerClaimable(address _vaultOwner)
		external
		view
		returns (uint256)
	{
		uint256 totalFutureBalance = address(this).balance +
			feeGmxTrackerRewards.claimable(address(this));

		uint256 futureRewardShare = rewardShare;

		if (totalStaked > 0) {
			futureRewardShare += FullMath.mulDiv(
				totalFutureBalance - lastBalance,
				PRECISION,
				totalStaked
			);
		}

		uint256 last = userShares[_vaultOwner];
		uint256 curr = FullMath.mulDiv(
			stakes[_vaultOwner],
			futureRewardShare,
			PRECISION
		);

		if (curr > last) {
			uint256 totalReward = curr - last;
			uint256 toTheTreasury = (((totalReward * PRECISION) * treasuryFee) / 10_000) /
				PRECISION;
			return totalReward - toTheTreasury;
		}

		return 0;
	}

	function isOperator(address _operator) external view override returns (bool) {
		return operators[_operator];
	}

	receive() external payable {
		emit RewardReceived(msg.value);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGMXRewardTracker {
	function claimable(address _wallet) external view returns (uint256);

	function tokensPerInterval() external view returns (uint256);

	function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IVestaGMXStaking {
	error CallerIsNotAnOperator(address _caller);
	error ZeroAmountPassed();
	error InvalidAddress();
	error InsufficientStakeBalance();
	error ETHTransferFailed(address to, uint256 amount);
	error ReentrancyDetected();
	error BPSHigherThanOneHundred();
	error FeeTooHigh();

	event StakingUpdated(uint256 totalStaking);
	event RewardReceived(uint256 reward);

	/**
		Stake: Allow a vault wallet to stake into GMX earning program
		@dev only called by an operator
		@dev `_amount` cannot be zero
		@param _behalfOf Vault Owner address
		@param _amount GMX that should be staked
	 */
	function stake(address _behalfOf, uint256 _amount) external;

	/**
		Unstake: unstake from GMX earning program
		@dev Can only be called by an operator
		@dev _amount can be zero
		@param _behalfOf address of the vault owner
		@param _amount amount you want to unstake
	 */
	function unstake(address _behalfOf, uint256 _amount) external;

	/**
		claim: Allow a vault owner to claim their reward without modifying their vault
	 */
	function claim() external;

	/**
		getVaultStake: returns how much is staked from a vault owner
		@param _vaultOwner the address of the vault owner
		@return stake total token staked
	 */
	function getVaultStake(address _vaultOwner) external view returns (uint256);

	/**
		getVaultOwnerShare: Get the share of 
			the vault owner at the moment s/he interacted with the Staking contract.
		@param _vaultOwner address of the vault owner
		@return _originalShare the vault's share at the moment of the interaction with the contract.
	 */
	function getVaultOwnerShare(address _vaultOwner) external view returns (uint256);

	/**
		getVaultOwnerClaimable: returns how much the vault owner has earns and is pending for claiming
		@dev The returned number isn't an absolute number, it's an estimation.
		@param _vaultOwner the address of the vault owner
		@return claimable An close estimation of rewards reserved to the vault owner
	 */
	function getVaultOwnerClaimable(address _vaultOwner)
		external
		view
		returns (uint256);

	/**
		isOperator: find if a contract is an operator
		@notice An operator can only be a contract. For vesta, the contract will be ActivePool
		@param _operator the address of the contract
		@return status true if it's an operator
	 */
	function isOperator(address _operator) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
	/// @notice Transfers tokens from the targeted address to the given destination
	/// @notice Errors with 'STF' if transfer fails
	/// @param token The contract address of the token to be transferred
	/// @param from The originating address from which the tokens will be transferred
	/// @param to The destination address of the transfer
	/// @param value The amount to be transferred
	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"STF"
		);
	}

	/// @notice Transfers tokens from msg.sender to a recipient
	/// @dev Errors with ST if transfer fails
	/// @param token The contract address of the token which will be transferred
	/// @param to The recipient of the transfer
	/// @param value The value of the transfer
	function safeTransfer(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20.transfer.selector, to, value)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"ST"
		);
	}

	/// @notice Approves the stipulated contract to spend the given allowance in the given token
	/// @dev Errors with 'SA' if transfer fails
	/// @param token The contract address of the token to be approved
	/// @param to The target of the approval
	/// @param value The amount of the given token the target will be allowed to spend
	function safeApprove(
		address token,
		address to,
		uint256 value
	) internal {
		(bool success, bytes memory data) = token.call(
			abi.encodeWithSelector(IERC20.approve.selector, to, value)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"SA"
		);
	}

	/// @notice Transfers ETH to the recipient address
	/// @dev Fails with `STE`
	/// @param to The destination of the transfer
	/// @param value The value to be transferred
	function safeTransferETH(address to, uint256 value) internal {
		(bool success, ) = to.call{ value: value }(new bytes(0));
		require(success, "STE");
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

library FullMath {
	/// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
	function mulDiv(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		unchecked {
			// 512-bit multiply [prod1 prod0] = a * b
			// Compute the product mod 2**256 and mod 2**256 - 1
			// then use the Chinese Remainder Theorem to reconstruct
			// the 512 bit result. The result is stored in two 256
			// variables such that product = prod1 * 2**256 + prod0
			uint256 prod0; // Least significant 256 bits of the product
			uint256 prod1; // Most significant 256 bits of the product
			assembly {
				let mm := mulmod(a, b, not(0))
				prod0 := mul(a, b)
				prod1 := sub(sub(mm, prod0), lt(mm, prod0))
			}

			// Handle non-overflow cases, 256 by 256 division
			if (prod1 == 0) {
				require(denominator > 0);
				assembly {
					result := div(prod0, denominator)
				}
				return result;
			}

			// Make sure the result is less than 2**256.
			// Also prevents denominator == 0
			require(denominator > prod1);

			///////////////////////////////////////////////
			// 512 by 256 division.
			///////////////////////////////////////////////

			// Make division exact by subtracting the remainder from [prod1 prod0]
			// Compute remainder using mulmod
			uint256 remainder;
			assembly {
				remainder := mulmod(a, b, denominator)
			}
			// Subtract 256 bit number from 512 bit number
			assembly {
				prod1 := sub(prod1, gt(remainder, prod0))
				prod0 := sub(prod0, remainder)
			}

			// Factor powers of two out of denominator
			// Compute largest power of two divisor of denominator.
			// Always >= 1.
			uint256 twos = (type(uint256).max - denominator + 1) & denominator;
			// Divide denominator by power of two
			assembly {
				denominator := div(denominator, twos)
			}

			// Divide [prod1 prod0] by the factors of two
			assembly {
				prod0 := div(prod0, twos)
			}
			// Shift in bits from prod1 into prod0. For this we need
			// to flip `twos` such that it is 2**256 / twos.
			// If twos is zero, then it becomes one
			assembly {
				twos := add(div(sub(0, twos), twos), 1)
			}
			prod0 |= prod1 * twos;

			// Invert denominator mod 2**256
			// Now that denominator is an odd number, it has an inverse
			// modulo 2**256 such that denominator * inv = 1 mod 2**256.
			// Compute the inverse by starting with a seed that is correct
			// correct for four bits. That is, denominator * inv = 1 mod 2**4
			uint256 inv = (3 * denominator) ^ 2;
			// Now use Newton-Raphson iteration to improve the precision.
			// Thanks to Hensel's lifting lemma, this also works in modular
			// arithmetic, doubling the correct bits in each step.
			inv *= 2 - denominator * inv; // inverse mod 2**8
			inv *= 2 - denominator * inv; // inverse mod 2**16
			inv *= 2 - denominator * inv; // inverse mod 2**32
			inv *= 2 - denominator * inv; // inverse mod 2**64
			inv *= 2 - denominator * inv; // inverse mod 2**128
			inv *= 2 - denominator * inv; // inverse mod 2**256

			// Because the division is now exact we can divide by multiplying
			// with the modular inverse of denominator. This will give us the
			// correct result modulo 2**256. Since the precoditions guarantee
			// that the outcome is less than 2**256, this is the final result.
			// We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inv;
			return result;
		}
	}

	/// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	function mulDivRoundingUp(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		result = mulDiv(a, b, denominator);
		unchecked {
			if (mulmod(a, b, denominator) > 0) {
				require(result < type(uint256).max);
				result++;
			}
		}
	}
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import { IGMXRewardRouterV2 } from "./interface/IGMXRewardRouterV2.sol";
import { IGMXRewardTracker } from "./interface/IGMXRewardTracker.sol";
import { IVestaGMXStaking } from "./interface/IVestaGMXStaking.sol";
import { TransferHelper, IERC20 } from "./lib/TransferHelper.sol";
import { FullMath } from "./lib/FullMath.sol";
import { IPriceFeedV2 } from "./interface/internal/IPriceFeedV2.sol";

contract VestaGLPStaking is IVestaGMXStaking, OwnableUpgradeable {
	uint256 private constant PRECISION = 1e27;
	bool private reentrancy;

	address public vestaTreasury;
	address public sGLP;

	IGMXRewardRouterV2 public gmxRewardRouterV2;
	IGMXRewardTracker public feeGlpTrackerRewards;

	uint256 public baseTreasuryFee;
	uint256 public rewardShare;

	uint256 public lastBalance;
	uint256 public totalStaked;

	mapping(address => bool) internal operators;
	mapping(address => uint256) internal stakes;
	mapping(address => uint256) internal userShares;

	uint256 constant BPS = 10_000;
	uint256 constant YEARLY = 31_536_000; //86400 * 365

	IGMXRewardTracker public constant fGLP =
		IGMXRewardTracker(0x4e971a87900b931fF39d1Aad67697F49835400b6);

	IPriceFeedV2 public priceFeed;

	modifier onlyOperator() {
		if (!operators[msg.sender]) revert CallerIsNotAnOperator(msg.sender);
		_;
	}

	modifier onlyNonZero(uint256 _amount) {
		if (_amount == 0) revert ZeroAmountPassed();
		_;
	}

	modifier onlyActiveAddress(address _addr) {
		if (_addr == address(0)) revert InvalidAddress();
		_;
	}

	modifier onlyContract(address _address) {
		if (_address.code.length == 0) revert InvalidAddress();
		_;
	}

	modifier noReentrancy() {
		if (reentrancy) revert ReentrancyDetected();
		reentrancy = true;
		_;
		reentrancy = false;
	}

	function setUp(
		address _vestaTreasury,
		address _sGLP,
		address _gmxRewardRouterV2,
		address _feeGlpTrackerRewards
	)
		external
		onlyActiveAddress(_vestaTreasury)
		onlyActiveAddress(_sGLP)
		onlyActiveAddress(_gmxRewardRouterV2)
		onlyActiveAddress(_feeGlpTrackerRewards)
		initializer
	{
		__Ownable_init();

		vestaTreasury = _vestaTreasury;
		sGLP = _sGLP;
		gmxRewardRouterV2 = IGMXRewardRouterV2(_gmxRewardRouterV2);
		feeGlpTrackerRewards = IGMXRewardTracker(_feeGlpTrackerRewards);

		baseTreasuryFee = 2_000; // 20% in BPS
	}

	function stake(address _behalfOf, uint256 _amount)
		external
		override
		onlyOperator
		onlyActiveAddress(_behalfOf)
		onlyNonZero(_amount)
		noReentrancy
	{
		_harvest(_behalfOf);

		TransferHelper.safeTransferFrom(sGLP, msg.sender, address(this), _amount);

		uint256 userStaked = stakes[_behalfOf] += _amount;

		totalStaked += _amount;

		userShares[_behalfOf] = FullMath.mulDivRoundingUp(
			userStaked,
			rewardShare,
			PRECISION
		);

		emit StakingUpdated(totalStaked);
	}

	function claim() external override noReentrancy {
		if (stakes[msg.sender] == 0) revert InsufficientStakeBalance();
		_unstake(msg.sender, 0);
	}

	function unstake(address _behalfOf, uint256 _amount)
		external
		override
		onlyOperator
		noReentrancy
	{
		_unstake(_behalfOf, _amount);
	}

	function _unstake(address _behalfOf, uint256 _amount) internal {
		if (totalStaked < _amount || stakes[_behalfOf] < _amount) {
			revert InsufficientStakeBalance();
		}
		_harvest(_behalfOf);
		uint256 userStaked = stakes[_behalfOf] -= _amount;

		if (_amount != 0) {
			uint256 withdrawalAmount = totalStaked < _amount ? totalStaked : _amount;
			totalStaked -= withdrawalAmount;
			TransferHelper.safeTransfer(sGLP, msg.sender, _amount);
		}

		userShares[_behalfOf] = FullMath.mulDivRoundingUp(
			userStaked,
			rewardShare,
			PRECISION
		);

		emit StakingUpdated(totalStaked);
	}

	function _harvest(address _behalfOf) internal {
		gmxRewardRouterV2.handleRewards(true, true, true, true, true, true, true);

		if (totalStaked > 0) {
			rewardShare += FullMath.mulDiv(
				address(this).balance - lastBalance,
				PRECISION,
				totalStaked
			);
		}

		uint256 last = userShares[_behalfOf];
		uint256 curr = FullMath.mulDiv(stakes[_behalfOf], rewardShare, PRECISION);

		if (curr > last) {
			bool success;
			uint256 totalReward = curr - last;

			uint256 toTheTreasury = (((totalReward * PRECISION) * treasuryFee()) /
				10_000) / PRECISION;
			uint256 toTheUser = totalReward - toTheTreasury;

			(success, ) = _behalfOf.call{ value: toTheUser }("");
			if (!success) {
				revert ETHTransferFailed(_behalfOf, toTheUser);
			}

			(success, ) = vestaTreasury.call{ value: toTheTreasury }("");
			if (!success) {
				revert ETHTransferFailed(vestaTreasury, toTheTreasury);
			}
		}

		lastBalance = address(this).balance;
	}

	function setOperator(address _address, bool _enabled)
		external
		onlyContract(_address)
		onlyOwner
	{
		operators[_address] = _enabled;
	}

	function setPriceFeed(address _priceFeed) external onlyOwner {
		priceFeed = IPriceFeedV2(_priceFeed);
	}

	function setBaseTreasuryFee(uint256 _sharesBPS) external onlyOwner {
		if (_sharesBPS > 2_000) revert FeeTooHigh();

		baseTreasuryFee = _sharesBPS;
	}

	function setTreasury(address _newTreasury) external onlyOwner {
		vestaTreasury = _newTreasury;
	}

	function treasuryFee() public view returns (uint256 apr_) {
		uint256 interval = fGLP.tokensPerInterval();
		uint256 totalSupply = feeGlpTrackerRewards.totalSupply();
		uint256 ethPrice = priceFeed.getExternalPrice(address(0));
		uint256 glpPrice = priceFeed.getExternalPrice(sGLP);

		apr_ = ((YEARLY * interval * ethPrice) * BPS) / (totalSupply * glpPrice);

		return (apr_ <= 2500) ? baseTreasuryFee : BPS - ((baseTreasuryFee * BPS) / apr_);
	}

	function getVaultStake(address _vaultOwner)
		external
		view
		override
		returns (uint256)
	{
		return stakes[_vaultOwner];
	}

	function getVaultOwnerShare(address _vaultOwner)
		external
		view
		override
		returns (uint256)
	{
		return userShares[_vaultOwner];
	}

	function getVaultOwnerClaimable(address _vaultOwner)
		external
		view
		returns (uint256)
	{
		uint256 totalFutureBalance = address(this).balance +
			feeGlpTrackerRewards.claimable(address(this));

		uint256 futureRewardShare = rewardShare;

		if (totalStaked > 0) {
			futureRewardShare += FullMath.mulDiv(
				totalFutureBalance - lastBalance,
				PRECISION,
				totalStaked
			);
		}

		uint256 last = userShares[_vaultOwner];
		uint256 curr = FullMath.mulDiv(
			stakes[_vaultOwner],
			futureRewardShare,
			PRECISION
		);

		if (curr > last) {
			uint256 totalReward = curr - last;
			uint256 toTheTreasury = (((totalReward * PRECISION) * treasuryFee()) /
				10_000) / PRECISION;
			return totalReward - toTheTreasury;
		}

		return 0;
	}

	function isOperator(address _operator) external view override returns (bool) {
		return operators[_operator];
	}

	receive() external payable {
		emit RewardReceived(msg.value);
	}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

interface IPriceFeedV2 {
	/// @notice getExternalPrice gets external oracles price and update the storage value.
	/// @param _token the token you want to price. Needs to be supported by the wrapper.
	/// @return The current price reflected on the external oracle in 1e18 format.
	function getExternalPrice(address _token) external view returns (uint256);
}