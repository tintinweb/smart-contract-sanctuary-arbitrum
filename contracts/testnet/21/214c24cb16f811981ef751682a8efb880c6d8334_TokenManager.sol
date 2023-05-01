// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "../interfaces/core/ITokenManager.sol";
import "../interfaces/tokens/IWINR.sol";
import "./AccessControlBase.sol";
import "../interfaces/strategies/IMiningStrategy.sol";
import "../interfaces/strategies/IFeeStrategy.sol";
import "../interfaces/stakings/IWINRStaking.sol";
import "../interfaces/referrals/IReferralStorage.sol";
import "../tokens/wlp/interfaces/IBasicFDT.sol";

contract TokenManager is AccessControlBase, ReentrancyGuard {
	using SafeERC20 for IWINR;
	using SafeERC20 for IERC20;

	event Converted(address indexed account, uint256 amount);
	event StrategiesSet(
		IMiningStrategy indexed miningStrategyAddress,
		IFeeStrategy indexed feeStrategyAddress
	);
	event VaultManagerSet(address indexed vaultManagerAddress);
	event TokensSet(IWINR indexed WINR, IWINR indexed vWINRAddress);
	event WINRStakingSet(IWINRStaking indexed WINRStakingAddress);
	event ReferralStorageSet(IReferralStorage indexed referralStorageAddress);
	/*==================================================== State Variables =============================================================*/
	/// @notice WINR address
	IWINR public immutable WINR;
	/// @notice vWINR address
	IWINR public immutable vWINR;
	/// @notice WLP address
	IBasicFDT public immutable WLP;
	/// @notice WINR staking address
	IWINRStaking public WINRStaking;
	/// @notice referral storage contract
	IReferralStorage public referralStorage;
	/// @notice vault manager address
	address public vaultManager;
	/// @notice mining strategy address
	IMiningStrategy public miningStrategy;
	/// @notice fee strategy address
	IFeeStrategy public feeStrategy;
	/// @notice total minted Vested WINR by games
	uint256 public mintedByGames;
	/// @notice max mint amount by games
	uint256 public immutable MAX_MINT;
	/// @notice total coverted amount (WINR => vWINR)
	uint256 public totalConverted;
	/// @notice stores transferable WINR amount
	uint256 public sendableAmount;
	/// @notice accumulative Vested WINR fee amount
	uint256 public accumFee;
	/// @notice divider for minting vested WINR fee
	uint256 public mintDivider;
	/// @notice referral Basis points
	uint256 private constant BASIS_POINTS = 10000;

	/*==================================================== Constructor =============================================================*/
	constructor(
		IWINR _WINR,
		IWINR _vWINR,
		IBasicFDT _WLP,
		uint256 _maxMint,
		address _vaultRegistry,
		address _timelock
	) AccessControlBase(_vaultRegistry, _timelock) {
		WINR = _WINR;
		vWINR = _vWINR;
		WLP = _WLP;
		MAX_MINT = _maxMint;
		mintDivider = 4;
	}

	/*==================================================== Functions =============================================================*/
	/**
	 *
	 * @param  _miningStrategy mining strategy address
	 * @param _feeStrategy fee strategy address
	 * @notice function to set mining and fee strategies
	 */
	function setStrategies(
		IMiningStrategy _miningStrategy,
		IFeeStrategy _feeStrategy
	) external onlyGovernance {
		miningStrategy = _miningStrategy;
		feeStrategy = _feeStrategy;

		emit StrategiesSet(miningStrategy, feeStrategy);
	}

	/**
	 *
	 * @param _vaultManager vault manager address
	 * @notice function to set vault manager
	 */
	function setVaultManager(address _vaultManager) external onlyGovernance {
		vaultManager = _vaultManager;

		emit VaultManagerSet(vaultManager);
	}

	/**
	 *
	 * @param _WINRStaking WINR staking address
	 * @notice function to set WINR Staking address
	 * @notice grants WINR_STAKING_ROLE to the address
	 */
	function setWINRStaking(IWINRStaking _WINRStaking) external onlyGovernance {
		require(address(_WINRStaking) != address(0), "address can not be zero");
		WINRStaking = _WINRStaking;
		emit WINRStakingSet(WINRStaking);
	}

	function setReferralStorage(IReferralStorage _referralStorage) external onlyGovernance {
		referralStorage = _referralStorage;

		emit ReferralStorageSet(referralStorage);
	}

	/**
	 *
	 * @param _mintDivider new divider for minting Vested WINR on gameCall
	 */
	function setMintDivider(uint256 _mintDivider) external onlyGovernance {
		mintDivider = _mintDivider;
	}

	/*==================================================== WINR Staking Functions =============================================================*/
	/**
	 *
	 * @param _from adress of the sender
	 * @param _amount amount of Vested WINR to take
	 * @notice function to transfer Vested WINR from sender to Token Manager
	 */
	function takeVestedWINR(address _from, uint256 _amount) external nonReentrant onlyManager {
		vWINR.safeTransferFrom(_from, address(this), _amount);
	}

	/**
	 *
	 * @param _from adress of the sender
	 * @param _amount amount of WINR to take
	 * @notice function to transfer WINR from sender to Token Manager
	 */
	function takeWINR(address _from, uint256 _amount) external nonReentrant onlyManager {
		WINR.safeTransferFrom(_from, address(this), _amount);
	}

	/**
	 *
	 * @param _to adress of the receiver
	 * @param _amount amount of Vested WINR to send
	 * @notice function to transfer Vested WINR from Token Manager to receiver
	 */
	function sendVestedWINR(address _to, uint256 _amount) external nonReentrant onlyManager {
		vWINR.safeTransfer(_to, _amount);
	}

	/**
	 *
	 * @param _to adress of the receiver
	 * @param _amount amount of WINR to send
	 * @notice function to transfer WINR from Token Manager to receiver
	 */
	function sendWINR(address _to, uint256 _amount) external nonReentrant onlyManager {
		_sendWINR(_to, _amount);
	}

	/**
	 *
	 * @param _to adress of the receiver
	 * @param _amount amount of WINR to mint
	 * @notice function to mint WINR to receiver
	 */
	function mintWINR(address _to, uint256 _amount) external nonReentrant onlyManager {
		_mintWINR(_to, _amount);
	}

	/**
	 *
	 * @param _amount amount of Vested WINR to burn
	 * @notice function to burn Vested WINR from Token Manager
	 */
	function burnVestedWINR(uint256 _amount) external nonReentrant onlyManager {
		vWINR.burn(_amount);
	}

	/**
	 *
	 * @param _amount amount of WINR to burn
	 * @notice function to burn WINR from Token Manager
	 */
	function burnWINR(uint256 _amount) external nonReentrant onlyManager {
		WINR.burn(_amount);
	}

	/**
	 *
	 * @param _to WINIR receiver address
	 * @param _amount amount of WINR
	 * @notice this function transfers WINR to receiver
	 * @notice if the sendable amount is insufficient it mints WINR
	 */
	function mintOrTransferByPool(
		address _to,
		uint256 _amount
	) external nonReentrant onlyManager {
		if (sendableAmount >= _amount) {
			sendableAmount -= _amount;
			_sendWINR(_to, _amount);
		} else {
			_mintWINR(_to, _amount);
		}
	}

	/**
	 *
	 * @param _to WLP receiver address (claim on WINR Staking)
	 * @param _amount amount of WLP
	 * @notice funtion to transfer WLP from Token Manager to receiver
	 */
	function sendWLP(address _to, uint256 _amount) external nonReentrant onlyManager {
		IERC20(WLP).safeTransfer(_to, _amount);
	}

	/**
	 *
	 * @param _to address of receiver
	 * @param _amount amount of WINR
	 * @notice internal function to mint WINR
	 */
	function _mintWINR(address _to, uint256 _amount) internal {
		WINR.mint(_to, _amount);
	}

	/**
	 *
	 * @param _to address of receiver
	 * @param _amount amount of WINR
	 * @notice internal function to transfer WINR
	 */
	function _sendWINR(address _to, uint256 _amount) internal {
		WINR.safeTransfer(_to, _amount);
	}

	/**
	 * @notice function to share fees with WINR Staking
	 * @dev only callable by FEE_COLLECTOR_ROLE
	 * @param amount amount of WINR to share
	 */
	function share(uint256 amount) external nonReentrant onlyManager {
		WINRStaking.share(amount);
	}

	/*==================================================== Conversion =============================================================*/
	/**
	 *
	 * @param _amount amount of WINR to convert
	 * @notice function to convert WINR to Vested WINR
	 * @notice takes WINR, mints equivalent amount of Vested WINR
	 */
	function convertToken(uint256 _amount) external nonReentrant {
		// Transfer WINR from sender to Token Manager
		WINR.safeTransferFrom(msg.sender, address(this), _amount);
		// Mint equivalent amount of Vested WINR
		vWINR.mint(msg.sender, _amount);
		// Update total converted amount
		totalConverted += _amount;
		// Update sendable amount
		sendableAmount += _amount;

		emit Converted(msg.sender, _amount);
	}

	/*==================================================== Game Functions =============================================================*/
	/**
	 *
	 * @param _input  address of the input token (weth, dai, wbtc)
	 * @param _amount amount of the input token
	 * @param _recipient Vested WINR receiver
	 * @notice function to mint Vested WINR
	 * @notice only games can mint with this function by Vault Manager
	 * @notice stores all minted amount in mintedByGames variable
	 * @notice can not mint more than MAX_MINT
	 */
	function mintVestedWINR(
		address _input,
		uint256 _amount,
		address _recipient
	) external nonReentrant onlyManager returns(uint256 _mintAmount){
		//mint with mining strategy
		uint256 _feeAmount = feeStrategy.calculate(_input, _amount);
		_mintAmount = miningStrategy.calculate(_feeAmount, mintedByGames);
		// get referral rate
		uint256 _vWINRRate = referralStorage.getPlayerVestedWINRRate(_recipient);
		// add vested WINR rate to mint amount
		if (_vWINRRate > 0) {
			_mintAmount += (_mintAmount * _vWINRRate) / BASIS_POINTS;
		}
		// mint Vested WINR
		if (mintedByGames + _mintAmount <= MAX_MINT) {
			vWINR.mint(_recipient, _mintAmount);
			accumFee += _mintAmount / mintDivider;
			mintedByGames += _mintAmount;
		}
	}

	/**
	 * @notice function to mint Vested WINR
	 * @notice mint amount comes from minted by games( check mintVestedWINR function)
	 */
	function mintFee() external nonReentrant onlyManager {
		vWINR.mint(address(WLP), accumFee);
		WLP.updateFundsReceived_VWINR();
		accumFee = 0;
	}

	/**
	 *
	 * @param _input address of the input token
	 * @param _amount amount of the input token
	 * @notice function to increase volume on mining strategy
	 * @notice games can increase volume by Vault Manager
	 */
	function increaseVolume(address _input, uint256 _amount) external nonReentrant onlyManager {
		miningStrategy.increaseVolume(_input, _amount, mintedByGames);
	}

	/**
	 *
	 * @param _input address of the input token
	 * @param _amount amount of the input token
	 * @notice function to decrease volume on mining strategy
	 * @notice games can decrease volume by Vault Manager
	 */
	function decreaseVolume(address _input, uint256 _amount) external nonReentrant onlyManager {
		miningStrategy.decreaseVolume(_input, _amount, mintedByGames);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenManager {
	function takeVestedWINR(address _from, uint256 _amount) external;

	function takeWINR(address _from, uint256 _amount) external;

	function sendVestedWINR(address _to, uint256 _amount) external;

	function sendWINR(address _to, uint256 _amount) external;

	function burnVestedWINR(uint256 _amount) external;

	function burnWINR(uint256 _amount) external;

	function mintWINR(address _to, uint256 _amount) external;

	function sendWLP(address _to, uint256 _amount) external;

	function mintOrTransferByPool(address _to, uint256 _amount) external;

	function mintVestedWINR(address _input, uint256 _amount, address _recipient) external returns(uint256 _mintAmount);

	function mintedByGames() external returns (uint256);

	function MAX_MINT() external returns (uint256);

	function share(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWINR is IERC20 {
	function mint(address account, uint256 amount) external returns (uint256, uint256);

	function burn(uint256 amount) external;

	function MAX_SUPPLY() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/core/IVaultAccessControlRegistry.sol";

pragma solidity 0.8.19;

contract AccessControlBase is Context {
	IVaultAccessControlRegistry public immutable registry;
	address public immutable timelockAddressImmutable;

	constructor(address _vaultRegistry, address _timelock) {
		registry = IVaultAccessControlRegistry(_vaultRegistry);
		timelockAddressImmutable = _timelock;
	}

	/*==================== Managed in VaultAccessControlRegistry *====================*/

	modifier onlyGovernance() {
		require(registry.isCallerGovernance(_msgSender()), "Forbidden: Only Governance");
		_;
	}

	modifier onlyManager() {
		require(registry.isCallerManager(_msgSender()), "Forbidden: Only Manager");
		_;
	}

	modifier onlyEmergency() {
		require(registry.isCallerEmergency(_msgSender()), "Forbidden: Only Emergency");
		_;
	}

	modifier protocolNotPaused() {
		require(!registry.isProtocolPaused(), "Forbidden: Protocol Paused");
		_;
	}

	/*==================== Managed in WINRTimelock *====================*/

	modifier onlyTimelockGovernance() {
		address timelockActive_;
		if (!registry.timelockActivated()) {
			// the flip is not switched yet, so this means that the governance address can still pass the onlyTimelockGoverance modifier
			timelockActive_ = registry.governanceAddress();
		} else {
			// the flip is switched, the immutable timelock is now locked in as the only adddress that can pass this modifier (and nothing can undo that)
			timelockActive_ = timelockAddressImmutable;
		}
		require(_msgSender() == timelockActive_, "Forbidden: Only TimelockGovernance");
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMiningStrategy {
	function calculate(
		uint256 _amount,
		uint256 _mintedByGames
	) external returns (uint256 amount_);

	function increaseVolume(address _input, uint256 _amount, uint256 _mintedByGames) external;

	function decreaseVolume(address _input, uint256 _amount, uint256 _mintedByGames) external;

	function currentMultiplier() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFeeStrategy {
	function calculate(address _token, uint256 _amount) external returns (uint256 amount_);

	function currentMultiplier() external view returns (int256);

	function computeDollarValue(
		address _token,
		uint256 _amount
	) external view returns (uint256 _dollarValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWINRStaking {
	function share(uint256 amount) external;

	struct StakeDividend {
		uint256 amount;
		uint256 profitDebt;
		uint256 weight;
		uint128 depositTime;
	}

	struct StakeVesting {
		uint256 amount; // The amount of tokens being staked
		uint256 weight; // The weight of the stake, used for calculating rewards
		uint256 vestingDuration; // The duration of the vesting period in seconds
		uint256 profitDebt; // The amount of profit earned by the stake, used for calculating rewards
		uint256 startTime; // The timestamp at which the stake was created
		uint256 accTokenFirstDay; // The accumulated  WINR tokens earned on the first day of the stake
		uint256 accTokenPerDay; // The rate at which WINR tokens are accumulated per day
		bool withdrawn; // Indicates whether the stake has been withdrawn or not
		bool cancelled; // Indicates whether the stake has been cancelled or not
	}

	struct Period {
		uint256 duration;
		uint256 minDuration;
		uint256 claimDuration;
		uint256 minPercent;
	}

	struct WeightMultipliers {
		uint256 winr;
		uint256 vWinr;
		uint256 vWinrVesting;
	}

	/*==================================================== Events =============================================================*/

	event Donation(address indexed player, uint amount);
	event Share(uint256 amount, uint256 totalDeposit);
	event DepositVesting(
		address indexed user,
		uint256 index,
		uint256 startTime,
		uint256 endTime,
		uint256 amount,
		uint256 profitDebt,
		bool isVested,
		bool isVesting
	);

	event DepositDividend(
		address indexed user,
		uint256 amount,
		uint256 profitDebt,
		bool isVested
	);
	event Withdraw(
		address indexed user,
		uint256 withdrawTime,
		uint256 index,
		uint256 amount,
		uint256 redeem,
		uint256 vestedBurn
	);
	event WithdrawBatch(
		address indexed user,
		uint256 withdrawTime,
		uint256[] indexes,
		uint256 amount,
		uint256 redeem,
		uint256 vestedBurn
	);

	event Unstake(
		address indexed user,
		uint256 unstakeTime,
		uint256 amount,
		uint256 burnedAmount,
		bool isVested
	);
	event Cancel(
		address indexed user,
		uint256 cancelTime,
		uint256 index,
		uint256 burnedAmount,
		uint256 sentAmount
	);
	event ClaimVesting(address indexed user, uint256 reward, uint256 index);
	event ClaimVestingBatch(address indexed user, uint256 reward, uint256[] indexes);
	event ClaimDividend(address indexed user, uint256 reward, bool isVested);
	event ClaimDividendBatch(address indexed user, uint256 reward);
	event WeightMultipliersUpdate(WeightMultipliers _weightMultipliers);
	event UnstakeBurnPercentageUpdate(uint256 _unstakeBurnPercentage);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IReferralStorage {
	struct Tier {
		uint256 WLPRate; // e.g. 2400 for 24%
		uint256 vWINRRate; // 5000 for 50%
	}
	event SetWithdrawInterval(uint256 timeInterval);
	event SetHandler(address handler, bool isActive);
	event SetPlayerReferralCode(address account, bytes32 code);
	event SetTier(uint256 tierId, uint256 WLPRate, uint256 vWINRRate);
	event SetReferrerTier(address referrer, uint256 tierId);
	event RegisterCode(address account, bytes32 code);
	event SetCodeOwner(address account, address newAccount, bytes32 code);
	event GovSetCodeOwner(bytes32 code, address newAccount);
	event Claim(address referrer, uint256 wlpAmount);
	event Reward(address referrer, address player, address token, uint256 amount);
	event RewardRemoved(address referrer, address player, address token, uint256 amount);
	event VaultUpdated(address vault);
	event VaultUtilsUpdated(address vaultUtils);
	event WLPManagerUpdated(address wlpManager);
	event SyncTokens();
	event TokenTransferredByTimelock(address token, address recipient, uint256 amount);
	event DeleteAllWhitelistedTokens();
	event TokenAddedToWhitelist(address addedTokenAddress);
	event AddReferrerToBlacklist(address referrer, bool setting);
	event ReferrerBlacklisted(address referrer);
	event NoRewardToSet(address player);

	function codeOwners(bytes32 _code) external view returns (address);

	function playerReferralCodes(address _account) external view returns (bytes32);

	function referrerTiers(address _account) external view returns (uint256);

	function getPlayerReferralInfo(address _account) external view returns (bytes32, address);

	function setPlayerReferralCode(address _account, bytes32 _code) external;

	function setTier(uint256 _tierId, uint256 _WLPRate) external;

	function setReferrerTier(address _referrer, uint256 _tierId) external;

	function govSetCodeOwner(bytes32 _code, address _newAccount) external;

	function getReferrerTier(address _referrer) external view returns (Tier memory tier_);

	function getPlayerVestedWINRRate(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBaseFDT.sol";

interface IBasicFDT is IBaseFDT, IERC20 {
	event PointsPerShareUpdated_WLP(uint256);

	event PointsCorrectionUpdated_WLP(address indexed, int256);

	event PointsPerShareUpdated_VWINR(uint256);

	event PointsCorrectionUpdated_VWINR(address indexed, int256);

	function withdrawnFundsOf_WLP(address) external view returns (uint256);

	function accumulativeFundsOf_WLP(address) external view returns (uint256);

	function withdrawnFundsOf_VWINR(address) external view returns (uint256);

	function accumulativeFundsOf_VWINR(address) external view returns (uint256);

	function updateFundsReceived_WLP() external;

	function updateFundsReceived_VWINR() external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

import "@openzeppelin/contracts/access/IAccessControl.sol";

pragma solidity >=0.6.0 <0.9.0;

interface IVaultAccessControlRegistry is IAccessControl {
	function timelockActivated() external view returns (bool);

	function governanceAddress() external view returns (address);

	function pauseProtocol() external;

	function unpauseProtocol() external;

	function isCallerGovernance(address _account) external view returns (bool);

	function isCallerManager(address _account) external view returns (bool);

	function isCallerEmergency(address _account) external view returns (bool);

	function isProtocolPaused() external view returns (bool);

	function changeGovernanceAddress(address _governanceAddress) external;

	/*==================== Events *====================*/

	event DeadmanSwitchFlipped();
	event GovernanceChange(address newGovernanceAddress);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IBaseFDT {
	/**
        @dev    Returns the total amount of funds a given address is able to withdraw currently.
        @param  owner Address of FDT holder.
        @return A uint256 representing the available funds for a given account.
    */
	function withdrawableFundsOf_WLP(address owner) external view returns (uint256);

	function withdrawableFundsOf_VWINR(address owner) external view returns (uint256);

	/**
        @dev Withdraws all available funds for a FDT holder.
    */
	function withdrawFunds_WLP() external;

	function withdrawFunds_VWINR() external;

	function withdrawFunds() external;

	/**
        @dev   This event emits when new funds are distributed.
        @param by               The address of the sender that distributed funds.
        @param fundsDistributed_WLP The amount of funds received for distribution.
    */
	event FundsDistributed_WLP(address indexed by, uint256 fundsDistributed_WLP);

	event FundsDistributed_VWINR(address indexed by, uint256 fundsDistributed_VWINR);

	/**
        @dev   This event emits when distributed funds are withdrawn by a token holder.
        @param by             The address of the receiver of funds.
        @param fundsWithdrawn_WLP The amount of funds that were withdrawn.
        @param totalWithdrawn_WLP The total amount of funds that were withdrawn.
    */
	event FundsWithdrawn_WLP(
		address indexed by,
		uint256 fundsWithdrawn_WLP,
		uint256 totalWithdrawn_WLP
	);

	event FundsWithdrawn_VWINR(
		address indexed by,
		uint256 fundsWithdrawn_VWINR,
		uint256 totalWithdrawn_VWINR
	);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}