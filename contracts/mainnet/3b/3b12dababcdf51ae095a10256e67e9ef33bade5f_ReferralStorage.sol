// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../core/AccessControlBase.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/core/IVaultUtils.sol";
import "../interfaces/core/IWLPManager.sol";
import "../interfaces/referrals/IReferralStorage.sol";

contract ReferralStorage is ReentrancyGuard, Pausable, AccessControlBase, IReferralStorage {
	/*==================== Constants *====================*/
	uint256 private constant MAX_INTERVAL = 7 days;
	// BASIS_POINTS_DIVISOR is a constant representing 100%, used to calculate rates as basis points
	uint256 public constant BASIS_POINTS_DIVISOR = 1e4;
	// Vested WINR rate is 5% for all tiers
	uint256 public vWINRRate = 500;
	uint256 public withdrawInterval = 1 days; // the reward withdraw interval

	IVault public vault; // vault contract address
	IVaultUtils public vaultUtils; // vault utils contract address
	IWLPManager public wlpManager; // vault contract address
	IERC20 public wlp;

	// array with addresses of all tokens fees are collected in
	address[] public allWhitelistedTokens;
	mapping(address => bool) public referrerOnBlacklist;
	mapping(address => uint256) public override referrerTiers; // link between user <> tier
	mapping(uint256 => Tier) public tiers;
	mapping(bytes32 => address) public override codeOwners;
	mapping(address => bytes32) public override playerReferralCodes;
	mapping(address => uint256) public lastWithdrawTime; // to override default value in tier
	mapping(address => mapping(address => uint256)) public withdrawn; // to override default value in tier
	mapping(address => mapping(address => uint256)) public rewards; // to override default value in tier

	constructor(
		address _vaultRegistry,
		address _vaultUtils,
		address _vault,
		address _wlpManager,
		address _timelock
	) AccessControlBase(_vaultRegistry, _timelock) Pausable() {
		vault = IVault(_vault);
		wlpManager = IWLPManager(_wlpManager);
		wlp = IERC20(wlpManager.wlp());
		vaultUtils = IVaultUtils(_vaultUtils);
	}

	/**
	 *
	 * @dev setTier allows the governance to set the WLP and vWINR rates for a given tier
	 * @param _tierId the identifier for the tier being updated
	 * @param _WLPRate the new WLP rate, expressed as a percentage in basis points (1% = 100 basis points)
	 * @dev setTier allows the governance to set the WLP and vWINR rates for a given tier
	 * @dev sets the vWINR rate to default value for all tiers
	 */
	function setTier(uint256 _tierId, uint256 _WLPRate) external override onlyGovernance {
		// require that the WLP rate is not greater than 100%
		require(_WLPRate <= BASIS_POINTS_DIVISOR, "ReferralStorage: invalid WLP Rate");

		// get the current tier object from storage
		Tier memory tier = tiers[_tierId];

		// update the WLP and vWINR rates in the tier object
		tier.WLPRate = _WLPRate;
		tier.vWINRRate = vWINRRate;

		// write the updated tier object back to storage
		tiers[_tierId] = tier;

		// emit an event to notify listeners of the tier update
		emit SetTier(_tierId, _WLPRate, vWINRRate);
	}

	/**
	 *
	 * @param _tierId the identifier for the tier being updated
	 * @param _WLPRate the new WLP rate, expressed as a percentage in basis points (1% = 100 basis points)
	 * @param _vWINRRate the new vWINR rate, expressed as a percentage in basis points (1% = 100 basis points)
	 * @dev updateTier allows the governance to update the WLP and vWINR rates for a given tier
	 */
	function updateTier(
		uint256 _tierId,
		uint256 _WLPRate,
		uint256 _vWINRRate
	) external onlyGovernance {
		// require that the WLP rate is not greater than 100%
		require(_WLPRate <= BASIS_POINTS_DIVISOR, "ReferralStorage: invalid WLP Rate");
		// require that the vWINR rate is not greater than 100%
		require(_vWINRRate <= BASIS_POINTS_DIVISOR, "ReferralStorage: invalid vWINR Rate");

		// get the current tier object from storage
		Tier memory tier = tiers[_tierId];

		// update the WLP and vWINR rates in the tier object
		tier.WLPRate = _WLPRate;
		tier.vWINRRate = _vWINRRate;

		// write the updated tier object back to storage
		tiers[_tierId] = tier;

		// emit an event to notify listeners of the tier update
		emit SetTier(_tierId, _WLPRate, _vWINRRate);
	}

	/**
	 *
	 * @param _vWINRRate the new vWINR rate, expressed as a percentage in basis points (1% = 100 basis points)
	 * @dev updateVestedWINRRate allows the governance to update the default vWINR rate
	 */

	function updateVestedWINRRate(uint256 _vWINRRate) external onlyGovernance {
		// require that the vWINR rate is not greater than 100%
		require(_vWINRRate <= BASIS_POINTS_DIVISOR, "ReferralStorage: invalid vWINR Rate");

		// update the vWINR rate in storage
		vWINRRate = _vWINRRate;

		// emit an event to notify listeners of the vWINR rate update
		emit SetVestedWINRRate(_vWINRRate);
	}

	/**
	 * @param _user address of the user
	 * @param _tierId ID of the tier
	 * @dev setReferrerTier allows the governance to set the tier for a given user
	 */
	function setReferrerTier(address _user, uint256 _tierId) external override onlySupport {
		// set the user's tier in storage
		referrerTiers[_user] = _tierId;

		// emit an event to notify listeners of the user tier update
		emit SetReferrerTier(_user, _tierId);
	}

	/**
	 *
	 * @param _account address of the user
	 * @param _code referral code
	 * @dev setPlayerReferralCode allows the manager role to set the referral code for a given user
	 */
	function setPlayerReferralCode(
		address _account,
		bytes32 _code
	) external override onlySupport {
		_setPlayerReferralCode(_account, _code);
	}

	/**
	 *
	 * @param _code referral code
	 * @dev setPlayerReferralCodeByUser allows the user to set the referral code
	 */
	function setPlayerReferralCodeByUser(bytes32 _code) external {
		require(playerReferralCodes[msg.sender] == bytes32(0), "ReferralStorage: already set");
		_setPlayerReferralCode(msg.sender, _code);
	}

	/**
	 * @dev Sets the referral code for a player's address.
	 * @param _account The address of the player.
	 * @param _code The referral code to set for the player.
	 * @notice This function can only be called internally by the contract.
	 */
	function _setPlayerReferralCode(address _account, bytes32 _code) private {
		// Ensure that the player is not setting their own code.
		require(codeOwners[_code] != _account, "ReferralStorage: can not set own code");
		// Ensure that the code exists.
		require(codeOwners[_code] != address(0), "ReferralStorage: code does not exist");
	
		// Set the player's referral code.
		playerReferralCodes[_account] = _code;
		// Emit an event to log the referral code setting.
		emit SetPlayerReferralCode(_account, _code);
	}

	/**
	 * @dev Registers a referral code.
	 * @param _code The referral code to register.
	 * @notice This function can be called externally.
	 */
	function registerCode(bytes32 _code) external {
		// Ensure that the code is not empty.
		require(_code != bytes32(0), "ReferralStorage: invalid _code");
		// Ensure that the code does not already exist.
		require(codeOwners[_code] == address(0), "ReferralStorage: code already exists");

		// Set the code owner to the message sender.
		codeOwners[_code] = msg.sender;
		// Emit an event to log the code registration.
		emit RegisterCode(msg.sender, _code);
	}


	/**
	 * @dev Allows the governance to set the owner of a referral code.
	 * @param _code The referral code to modify.
	 * @param _newAccount The new owner of the referral code.
	 * @notice This function can be called externally only by the governance address.
	 */
	function govSetCodeOwner(bytes32 _code, address _newAccount) external override onlySupport {
		// Ensure that the code is not empty.
		require(_code != bytes32(0), "ReferralStorage: invalid _code");

		// Set the new account owner for the code.
		codeOwners[_code] = _newAccount;

		// Emit an event to log the code owner change.
		emit GovSetCodeOwner(_code, _newAccount);
	}

	/**
	 * @notice configuration function for
	 * @dev the configured withdraw interval cannot exceed the MAX_INTERVAL
	 * @param _timeInterval uint time interval for withdraw
	 */
	function setWithdrawInterval(uint256 _timeInterval) external onlyGovernance {
		require(_timeInterval <= MAX_INTERVAL, "ReferralStorage: invalid interval");
		withdrawInterval = _timeInterval;
		emit SetWithdrawInterval(_timeInterval);
	}

	/**
	 * @notice Changes the address of the vault contract.
	 * @param vault_ The new address of the vault contract.
	 * @dev This function can only be called by the Timelock governance contract.
	 * @dev The new vault address must not be null.
	 * @dev Emits a `VaultUpdated` event upon successful execution.
	 */
	function setVault(address vault_) public onlyTimelockGovernance {
		// Ensure that the new vault address is not null.
		_checkNotNull(vault_);

		// Update the vault address.
		vault = IVault(vault_);

		// Emit an event to log the update.
		emit VaultUpdated(vault_);
	}

	/**
	 * @notice Changes the address of the VaultUtils contract.
	 * @param vaultUtils_ The new address of the VaultUtils contract.
	 * @dev This function can only be called by the Timelock governance contract.
	 * @dev The new VaultUtils address must not be null.
	 * @dev Emits a `VaultUtilsUpdated` event upon successful execution.
	 */
	function setVaultUtils(address vaultUtils_) public onlyTimelockGovernance {
		// Ensure that the new VaultUtils address is not null.
		_checkNotNull(vaultUtils_);

		// Update the VaultUtils address.
		vaultUtils = IVaultUtils(vaultUtils_);

		// Emit an event to log the update.
		emit VaultUtilsUpdated(vaultUtils_);
	}

	/**
	 * @notice Changes the address of the WLP Manager contract and updates the WLP token contract address.
	 * @param wlpManager_ The new address of the WLP Manager contract.
	 * @dev This function can only be called by the Timelock governance contract.
	 * @dev The new WLP Manager address must not be null.
	 * @dev Updates the WLP token contract address to the new WLP Manager's WLP token contract address.
	 * @dev Emits a `WLPManagerUpdated` event upon successful execution.
	 */
	function setWlpManager(address wlpManager_) public onlyTimelockGovernance {
		// Ensure that the new WLP Manager address is not null.
		_checkNotNull(wlpManager_);

		// Update the WLP Manager address and the WLP token contract address.
		wlpManager = IWLPManager(wlpManager_);
		wlp = IERC20(wlpManager.wlp());

		_checkNotNull(address(wlp));

		// Emit an event to log the update.
		emit WLPManagerUpdated(address(wlpManager_));
	}

	/**
	 * @notice manually adds a tokenaddress to the vault
	 * @param _tokenToAdd address to manually add to the allWhitelistedTokensFeeCollector array
	 */
	function addTokenToWhitelistList(address _tokenToAdd) external onlyTeam {
		allWhitelistedTokens.push(_tokenToAdd);
		emit TokenAddedToWhitelist(_tokenToAdd);
	}

	/**
	 * @notice deletes entire whitelist array
	 * @dev this function should be used before syncWhitelistedTokens is called!
	 */
	function deleteWhitelistTokenList() external onlyTeam {
		delete allWhitelistedTokens;
		emit DeleteAllWhitelistedTokens();
	}

	function addReferrerToBlacklist(address _referrer, bool _setting) external onlySupport {
		referrerOnBlacklist[_referrer] = _setting;
		emit AddReferrerToBlacklist(_referrer, _setting);
	}

	function _referrerOnBlacklist(address _referrer) internal view returns (bool onBlacklist_) {
		onBlacklist_ = referrerOnBlacklist[_referrer];
	}

	/**
	 * @notice internal function that checks if an address is not 0x0
	 */
	function _checkNotNull(address _setAddress) internal pure {
		require(_setAddress != address(0x0), "FeeCollector: Null not allowed");
	}

	/**
	 * @notice calculates what is a percentage portion of a certain input
	 * @param _amountToDistribute amount to charge the fee over
	 * @param _basisPointsPercentage basis point percentage scaled 1e4
	 * @return amount_ amount to distribute
	 */
	function calculateRebate(
		uint256 _amountToDistribute,
		uint256 _basisPointsPercentage
	) public pure returns (uint256 amount_) {
		amount_ = ((_amountToDistribute * _basisPointsPercentage) / BASIS_POINTS_DIVISOR);
	}

	/**
	 * @notice Synchronizes the whitelisted tokens between the vault and the this contract.
	 * @dev This function can only be called by the Manager.
	 * @dev Deletes all tokens in the `allWhitelistedTokens` array and adds the whitelisted tokens retrieved from the vault.
	 * @dev Emits a `SyncTokens` event upon successful execution.
	 */
	function syncWhitelistedTokens() public onlySupport {
		// Clear the `allWhitelistedTokens` array.
		delete allWhitelistedTokens;

		// Get the count of whitelisted tokens in the vault and add them to the `allWhitelistedTokens` array.
		uint256 count_ = vault.allWhitelistedTokensLength();
		for (uint256 i = 0; i < count_; ++i) {
			address token_ = vault.allWhitelistedTokens(i);
			// bool isWhitelisted_ = vault.whitelistedTokens(token_);
			// // if token is not whitelisted, don't add it to the whitelist
			// if (!isWhitelisted_) {
			// 	continue;
			// }
			allWhitelistedTokens.push(token_);
		}

		// Emit an event to log the synchronization.
		emit SyncTokens();
	}

	/**
	 * @notice Returns the referral code and referrer address for a given player.
	 * @param _account The player's address for which to retrieve the referral information.
	 * @return code_ The player's referral code.
	 * @return referrer_ The player's referrer address.
	 * @dev If the referrer is on the blacklist, the referrer address is set to 0x0.
	 */
	function getPlayerReferralInfo(
		address _account
	) public view override returns (bytes32 code_, address referrer_) {
		// Retrieve the player's referral code from the playerReferralCodes mapping.
		code_ = playerReferralCodes[_account];

		// If the player has a referral code, retrieve the referrer address from the codeOwners mapping.
		if (code_ != bytes32(0)) {
			referrer_ = codeOwners[code_];
		}

		// Check if the referrer is on the blacklist, if yes, set the referrer address to 0x0.
		if (_referrerOnBlacklist(referrer_)) {
			referrer_ = address(0);
		}

		// Return the player's referral code and referrer address.
		return (code_, referrer_);
	}

	/**
	 *
	 * @dev Returns the vested WINR rate of the player
	 * @param _account Address of the player
	 * @return uint256 Vested WINR rate of the player
	 * @notice If the player has no referrer, the rate is 0
	 * @notice This function overrides the getPlayerVestedWINRRate function in the IReferralSystem interface
	 */
	function getPlayerVestedWINRRate(address _account) public view override returns (uint256) {
		// Get the referral code of the player's referrer
		bytes32 code_ = playerReferralCodes[_account];
		// If the player has no referrer, return a vested WINR rate of 0
		if (code_ == bytes32(0)) {
			return 0;
		}

		// Return the vested WINR rate of the player's referrer's tier
		return tiers[referrerTiers[codeOwners[code_]]].vWINRRate;
	}

	/**
	 * @notice function that checks if a player has a referrer
	 * @param _player address of the player
	 * @return isReferred_ true if the player has a referrer
	 */
	function isPlayerReferred(address _player) public view returns (bool isReferred_) {
		(, address referrer_) = getPlayerReferralInfo(_player);
		isReferred_ = (referrer_ != address(0));
	}

	/**
	 * @notice function that returns the referrer of a player
	 * @param _player address of the player
	 * @return referrer_ address of the referrer
	 */
	function returnPlayerRefferalAddress(
		address _player
	) public view returns (address referrer_) {
		(, referrer_) = getPlayerReferralInfo(_player);
		return referrer_;
	}

	/**
	 * @notice function that sets the reward for a referrer
	 * @param _player address of the player
	 * @param _token address of the token
	 * @param _amount amount of the token to reward the referrer with (max)
	 */
	function setReward(
		address _player,
		address _token,
		uint256 _amount
	) external onlyProtocol returns (uint256 _reward) {
		address referrer_ = returnPlayerRefferalAddress(_player);

		if (referrer_ != address(0)) {
			// the player has a referrer
			// calculate the rebate for the referrer tier
			uint256 amountRebate_ = calculateRebate(
				_amount,
				tiers[referrerTiers[referrer_]].WLPRate
			);
			// nothing to rebate, return early but emit event
			if (amountRebate_ == 0) {
				emit Reward(referrer_, _player, _token, _amount, 0);
				return 0;
			}

			// add the rebate to the rewards mapping of the referrer
			unchecked {
				rewards[referrer_][_token] += amountRebate_;
			}

			// add the rebate to the referral reserves of the vault (to keep it aside from the wagerFeeReserves)
			IVault(vault).setAsideReferral(_token, amountRebate_);

			emit Reward(referrer_, _player, _token, _amount, amountRebate_);

			return amountRebate_;
		}
		emit NoRewardToSet(_player);
	}

	function removeReward(
    	address _player,
    	address _token,
    	uint256 _amountRebate
	) external onlyProtocol {
    	address referrer_ = returnPlayerRefferalAddress(_player);

    	if (referrer_ != address(0)) {
        	// nothing to rebate, return early
        	if (_amountRebate == 0) {
            	return;
        	}

        	if (rewards[referrer_][_token] >= _amountRebate) {
            	rewards[referrer_][_token] -= _amountRebate;
            	// remove the rebate to the referral reserves of the vault
            	IVault(vault).removeAsideReferral(_token, _amountRebate);

				emit RewardRemoved(referrer_, _player, _token, _amountRebate, true);
        	} else {
				rewards[referrer_][_token] = 0;
				// remove the rebate to the referral reserves of the vault
				IVault(vault).removeAsideReferral(_token, rewards[referrer_][_token]);
				
				emit RewardRemoved(referrer_, _player, _token, rewards[referrer_][_token], false);
			}

    	}
	}

	/**
	 *
	 * @dev Allows a referrer to claim their rewards in the form of WLP tokens.
	 * @dev Referrers cannot be on the blacklist.
	 * @dev Rewards can only be withdrawn once per withdrawInterval.
	 * @dev Calculates the total WLP amount and updates the withdrawn rewards.
	 * @dev Transfers the WLP tokens to the referrer.
	 */
	function claim(uint256[] calldata _minWlps) public whenNotPaused nonReentrant {
		address referrer_ = _msgSender();

		require(!_referrerOnBlacklist(referrer_), "Referrer is blacklisted");

		uint256 lastWithdrawTime_ = lastWithdrawTime[referrer_];
		require(
			block.timestamp >= lastWithdrawTime_ + withdrawInterval,
			"Rewards can only be withdrawn once per withdrawInterval"
		);

		// check: update last withdrawal time
		lastWithdrawTime[referrer_] = block.timestamp;

		// effects: calculate total WLP amount and update withdrawn rewards
		uint256 totalWlpAmount_;
		address[] memory wlTokens_ = allWhitelistedTokens;
		for (uint256 i = 0; i < wlTokens_.length; ++i) {
			address token_ = wlTokens_[i];
			uint256 amount_ = rewards[referrer_][token_] - withdrawn[referrer_][token_];
			withdrawn[referrer_][token_] = rewards[referrer_][token_];

			// interactions: convert token rewards to WLP
			if (amount_ > 0) {
				totalWlpAmount_ += _convertReferralTokensToWLP(token_, amount_, _minWlps[i]);
			}
		}
		// transfer WLP tokens to referrer
		if (totalWlpAmount_ > 0) {
			wlp.transfer(referrer_, totalWlpAmount_);
		}
		emit Claim(referrer_, totalWlpAmount_);
	}

	/**
	 *
	 * @param _referrer address of the referrer
	 * @dev returns the amount of WLP that can be claimed by the referrer
	 * @dev this function is used by the frontend to show the amount of WLP that can be claimed
	 */
	function getPendingWLPRewards(
		address _referrer
	) public view returns (uint256 totalWlpAmount_) {
		address[] memory wlTokens_ = allWhitelistedTokens;

		// Loop through each whitelisted token
		for (uint256 i = 0; i < wlTokens_.length; ++i) {
			// Get the address of the current token
			address token_ = wlTokens_[i];

			// Calculate the amount of the current token that can be claimed by the referrer
			uint256 amount_ = rewards[_referrer][token_] - withdrawn[_referrer][token_];

			// If the referrer can claim some of the current token, calculate the WLP amount
			if (amount_ != 0) {
				// Get the minimum price of the current token from the vault
				uint256 priceIn_ = vault.getMinPrice(token_);

				// Calculate the USDW amount of the current token
				uint256 usdwAmount_ = (amount_ * priceIn_) / 1e30;

				// Convert the USDW amount to the same decimal scale as the current token
				usdwAmount_ =
					(usdwAmount_ * 1e18) /
					(10 ** vault.tokenDecimals(token_));

				uint256 aumInUsdw_ = wlpManager.getAumInUsdw(true);

				// Calculate the WLP amount of the current token without deducting WLP minting fees
				uint256 amountWithFee_ = aumInUsdw_ == 0
					? usdwAmount_
					: ((usdwAmount_ * IERC20(wlp).totalSupply()) / aumInUsdw_);

				// Get the fee basis points for buying USDW with the current token
				uint256 feeBasisPoints_ = vaultUtils.getBuyUsdwFeeBasisPoints(
					token_,
					usdwAmount_
				);

				// Calculate the amount of WLP that can be claimed for the current token
				totalWlpAmount_ +=
					(amountWithFee_ *
						(BASIS_POINTS_DIVISOR - feeBasisPoints_)) /
					BASIS_POINTS_DIVISOR;
			}
		}
		return totalWlpAmount_;
	}

	/**
	 * @notice internal function that deposits tokens and returns amount of wlp
	 * @param _token token address of amount which wants to deposit
	 * @param _amount amount of the token collected (FeeCollector contract)
	 * @return wlpAmount_ amount of the token minted to this by depositing
	 */
	function _convertReferralTokensToWLP(
		address _token,
		uint256 _amount,
		uint256 _minWlp
	) internal returns (uint256 wlpAmount_) {
		uint256 currentWLPBalance_ = wlp.balanceOf(address(this));

		// approve WLPManager to spend the tokens
		IERC20(_token).approve(address(wlpManager), _amount);

		// WLPManager returns amount of WLP minted
		wlpAmount_ = wlpManager.addLiquidity(_token, _amount, 0, _minWlp);

		// note: if we want to check if the mint was successful and the WLP actually sits in this contract, we should do it like this:
		require(
			wlp.balanceOf(address(this)) == currentWLPBalance_ + wlpAmount_,
			"ReferralStorage: WLP mint failed"
		);
	}

	function getReferrerTier(address _referrer) public view returns (Tier memory tier_) {
		// if the referrer is not registered as a referrer, it should return an error
		if (playerReferralCodes[_referrer] == bytes32(0)) {
			revert("ReferralStorage: Referrer not registered");
		}
		tier_ = tiers[referrerTiers[_referrer]];
	}

	/**
	 * @notice governance function to rescue or correct any tokens that end up in this contract by accident
	 * @dev this is a timelocked funciton
	 * @param _tokenAddress address of the token to be transferred out
	 * @param _amount amount of the token to be transferred out
	 * @param _recipient address of the receiver of the token
	 */
	function removeTokenByGoverance(
		address _tokenAddress,
		uint256 _amount,
		address _recipient
	) external onlyTimelockGovernance {
		IERC20(_tokenAddress).transfer(_recipient, _amount);
		emit TokenTransferredByTimelock(_tokenAddress, _recipient, _amount);
	}
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

	modifier onlyEmergency() {
		require(registry.isCallerEmergency(_msgSender()), "Forbidden: Only Emergency");
		_;
	}

	modifier onlySupport() {
		require(registry.isCallerSupport(_msgSender()), "Forbidden: Only Support");
		_;
	}

	modifier onlyTeam() {
		require(registry.isCallerTeam(_msgSender()), "Forbidden: Only Team");
		_;
	}

	modifier onlyProtocol() {
		require(registry.isCallerProtocol(_msgSender()), "Forbidden: Only Protocol");
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

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
	/*==================== Events *====================*/
	event BuyUSDW(
		address account,
		address token,
		uint256 tokenAmount,
		uint256 usdwAmount,
		uint256 feeBasisPoints
	);
	event SellUSDW(
		address account,
		address token,
		uint256 usdwAmount,
		uint256 tokenAmount,
		uint256 feeBasisPoints
	);
	event Swap(
		address account,
		address tokenIn,
		address tokenOut,
		uint256 amountIn,
		uint256 indexed amountOut,
		uint256 indexed amountOutAfterFees,
		uint256 indexed feeBasisPoints
	);
	event DirectPoolDeposit(address token, uint256 amount);
	error TokenBufferViolation(address tokenAddress);
	error PriceZero();

	event PayinWLP(
		// address of the token sent into the vault
		address tokenInAddress,
		// amount payed in (was in escrow)
		uint256 amountPayin
	);

	event PlayerPayout(
		// address the player receiving the tokens (do we need this? i guess it does not matter to who we send tokens for profit/loss calculations?)
		address recipient,
		// address of the token paid to the player
		address tokenOut,
		// net amount sent to the player (this is NOT the net loss, since it includes the payed in tokens, excludes wagerFee and swapFee!)
		uint256 amountPayoutTotal
	);

	event AmountOutNull();

	event WithdrawAllFees(
		address tokenCollected,
		uint256 swapFeesCollected,
		uint256 wagerFeesCollected,
		uint256 referralFeesCollected
	);

	event RebalancingWithdraw(address tokenWithdrawn, uint256 amountWithdrawn);

	event RebalancingDeposit(address tokenDeposit, uint256 amountDeposit);

	event WagerFeeChanged(uint256 newWagerFee);

	event ReferralDistributionReverted(uint256 registeredTooMuch, uint256 maxVaueAllowed);

	/*==================== Operational Functions *====================*/
	function setPayoutHalted(bool _setting) external;

	function isSwapEnabled() external view returns (bool);

	function setVaultUtils(IVaultUtils _vaultUtils) external;

	function setError(uint256 _errorCode, string calldata _error) external;

	function usdw() external view returns (address);

	function feeCollector() external returns (address);

	function hasDynamicFees() external view returns (bool);

	function totalTokenWeights() external view returns (uint256);

	function getTargetUsdwAmount(address _token) external view returns (uint256);

	function inManagerMode() external view returns (bool);

	function isManager(address _account) external view returns (bool);

	function tokenBalances(address _token) external view returns (uint256);

	function setInManagerMode(bool _inManagerMode) external;

	function setManager(address _manager, bool _isManager, bool _isWLPManager) external;

	function setIsSwapEnabled(bool _isSwapEnabled) external;

	function setUsdwAmount(address _token, uint256 _amount) external;

	function setBufferAmount(address _token, uint256 _amount) external;

	function setFees(
		uint256 _taxBasisPoints,
		uint256 _stableTaxBasisPoints,
		uint256 _mintBurnFeeBasisPoints,
		uint256 _swapFeeBasisPoints,
		uint256 _stableSwapFeeBasisPoints,
		uint256 _minimumBurnMintFee,
		bool _hasDynamicFees
	) external;

	function setTokenConfig(
		address _token,
		uint256 _tokenDecimals,
		uint256 _redemptionBps,
		uint256 _maxUsdwAmount,
		bool _isStable
	) external;

	function setPriceFeedRouter(address _priceFeed) external;

	function withdrawAllFees(address _token) external returns (uint256, uint256, uint256);

	function directPoolDeposit(address _token) external;

	function deposit(address _tokenIn, address _receiver, bool _swapLess) external returns (uint256);

	function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);

	function swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) external returns (uint256);

	function tokenToUsdMin(
		address _tokenToPrice,
		uint256 _tokenAmount
	) external view returns (uint256);

	function priceOracleRouter() external view returns (address);

	function taxBasisPoints() external view returns (uint256);

	function stableTaxBasisPoints() external view returns (uint256);

	function mintBurnFeeBasisPoints() external view returns (uint256);

	function swapFeeBasisPoints() external view returns (uint256);

	function stableSwapFeeBasisPoints() external view returns (uint256);

	function minimumBurnMintFee() external view returns (uint256);

	function allWhitelistedTokensLength() external view returns (uint256);

	function allWhitelistedTokens(uint256) external view returns (address);

	function stableTokens(address _token) external view returns (bool);

	function swapFeeReserves(address _token) external view returns (uint256);

	function tokenDecimals(address _token) external view returns (uint256);

	function tokenWeights(address _token) external view returns (uint256);

	function poolAmounts(address _token) external view returns (uint256);

	function bufferAmounts(address _token) external view returns (uint256);

	function usdwAmounts(address _token) external view returns (uint256);

	function maxUsdwAmounts(address _token) external view returns (uint256);

	function getRedemptionAmount(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getMaxPrice(address _token) external view returns (uint256);

	function getMinPrice(address _token) external view returns (uint256);

	function setVaultManagerAddress(address _vaultManagerAddress, bool _setting) external;

	function wagerFeeBasisPoints() external view returns (uint256);

	function setWagerFee(uint256 _wagerFee) external;

	function wagerFeeReserves(address _token) external view returns (uint256);

	function referralReserves(address _token) external view returns (uint256);

	function getReserve() external view returns (uint256);

	function getWlpValue() external view returns (uint256);

	function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);

	function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);

	function usdToToken(
		address _token,
		uint256 _usdAmount,
		uint256 _price
	) external view returns (uint256);

	function returnTotalOutAndIn(
		address token_
	) external view returns (uint256 totalOutAllTime_, uint256 totalInAllTime_);

	function payout(
		address _wagerToken,
		address _escrowAddress,
		uint256 _escrowAmount,
		address _recipient,
		uint256 _totalAmount
	) external;

	function payoutNoEscrow(
		address _wagerAsset,
		address _recipient,
		uint256 _totalAmount
	) external;

	function payin(
		address _inputToken, 
		address _escrowAddress,
		uint256 _escrowAmount) external;

	function setAsideReferral(address _token, uint256 _amount) external;

	function payinWagerFee(
		address _tokenIn
	) external;

	function payinSwapFee(
		address _tokenIn
	) external;

	function payinPoolProfits(
		address _tokenIn
	) external;

	function removeAsideReferral(address _token, uint256 _amountRemoveAside) external;

	function setFeeCollector(address _feeCollector) external;

	function upgradeVault(
		address _newVault,
		address _token,
		uint256 _amount,
		bool _upgrade
	) external;

	function setCircuitBreakerAmount(address _token, uint256 _amount) external;

	function clearTokenConfig(address _token) external;

	function updateTokenBalance(address _token) external;

	function setCircuitBreakerEnabled(bool _setting) external;

	function setPoolBalance(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtils {
	function getBuyUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getSellUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getFeeBasisPoints(
		address _token,
		uint256 _usdwDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVault.sol";

interface IWLPManager {
	function wlp() external view returns (address);

	function usdw() external view returns (address);

	function vault() external view returns (IVault);

	function cooldownDuration() external returns (uint256);

	function getAumInUsdw(bool maximise) external view returns (uint256);

	function lastAddedAt(address _account) external returns (uint256);

	function addLiquidity(
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external returns (uint256);

	function addLiquidityForAccount(
		address _fundingAccount,
		address _account,
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external returns (uint256);

	function removeLiquidity(
		address _tokenOut,
		uint256 _wlpAmount,
		uint256 _minOut,
		address _receiver
	) external returns (uint256);

	function removeLiquidityForAccount(
		address _account,
		address _tokenOut,
		uint256 _wlpAmount,
		uint256 _minOut,
		address _receiver
	) external returns (uint256);

	function setCooldownDuration(uint256 _cooldownDuration) external;

	function getAum(bool _maximise) external view returns (uint256);

	function getPriceWlp(bool _maximise) external view returns (uint256);

	function getPriceWLPInUsdw(bool _maximise) external view returns (uint256);

	function circuitBreakerTrigger(address _token) external;

	function aumDeduction() external view returns (uint256);

	function reserveDeduction() external view returns (uint256);

	function maxPercentageOfWagerFee() external view returns (uint256);

	function addLiquidityFeeCollector(
		address _token,
		uint256 _amount,
		uint256 _minUsdw,
		uint256 _minWlp
	) external returns (uint256 wlpAmount_);

	/*==================== Events *====================*/
	event AddLiquidity(
		address account,
		address token,
		uint256 amount,
		uint256 aumInUsdw,
		uint256 wlpSupply,
		uint256 usdwAmount,
		uint256 mintAmount
	);

	event RemoveLiquidity(
		address account,
		address token,
		uint256 wlpAmount,
		uint256 aumInUsdw,
		uint256 wlpSupply,
		uint256 usdwAmount,
		uint256 amountOut
	);

	event PrivateModeSet(bool inPrivateMode);

	event HandlerEnabling(bool setting);

	event HandlerSet(address handlerAddress, bool isActive);

	event CoolDownDurationSet(uint256 cooldownDuration);

	event AumAdjustmentSet(uint256 aumAddition, uint256 aumDeduction);

	event MaxPercentageOfWagerFeeSet(uint256 maxPercentageOfWagerFee);

	event CircuitBreakerTriggered(
		address forToken,
		bool pausePayoutsOnCB,
		bool pauseSwapOnCB,
		uint256 reserveDeductionOnCB
	);

	event CircuitBreakerPolicy(
		bool pausePayoutsOnCB,
		bool pauseSwapOnCB,
		uint256 reserveDeductionOnCB
	);

	event CircuitBreakerReset(
		bool pausePayoutsOnCB,
		bool pauseSwapOnCB,
		uint256 reserveDeductionOnCB
	);
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
	event Reward(address referrer, address player, address token, uint256 amount, uint256 rebateAmount);
	event RewardRemoved(address referrer, address player, address token, uint256 amount, bool isFully);
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
	event SetVestedWINRRate(uint256 vWINRRate);

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

	function isCallerEmergency(address _account) external view returns (bool);

	function isCallerProtocol(address _account) external view returns (bool);

	function isCallerTeam(address _account) external view returns (bool);

	function isCallerSupport(address _account) external view returns (bool);

	function isProtocolPaused() external view returns (bool);

	function changeGovernanceAddress(address _governanceAddress) external;

	/*==================== Events *====================*/

	event DeadmanSwitchFlipped();
	event GovernanceChange(address newGovernanceAddress);
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